#!/usr/bin/env python3
"""Patch script sources in an existing binary Roblox place without running its code.

Unknown chunks/properties and untouched chunks retain their original bytes. New
scripts use fresh class IDs/referents; existing object references never change.
Reading Studio Zstandard chunks requires the ``zstandard`` Python package.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import struct
import tempfile
from typing import Any

MAGIC = b"<roblox!\x89\xff\r\n\x1a\n"
SCRIPTS = {"ModuleScript", "LocalScript", "Script"}
MAX_CHUNK = 512 * 1024 * 1024


def u32(data: bytes, offset: int = 0) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def string(data: bytes, offset: int) -> tuple[bytes, int]:
    size = u32(data, offset)
    end = offset + 4 + size
    if end > len(data):
        raise ValueError("Truncated binary string")
    return data[offset + 4:end], end


def encoded_string(value: str | bytes) -> bytes:
    raw = value.encode("utf-8") if isinstance(value, str) else value
    return struct.pack("<I", len(raw)) + raw


def decode_referents(data: bytes, count: int) -> list[int]:
    if len(data) != count * 4:
        raise ValueError("Invalid referent array size")
    result, current = [], 0
    for i in range(count):
        value = (data[i] << 24) | (data[count + i] << 16) | (data[2 * count + i] << 8) | data[3 * count + i]
        current += (value >> 1) ^ -(value & 1)
        result.append(current)
    return result


def encode_referents(values: list[int]) -> bytes:
    encoded, previous = [], 0
    for value in values:
        delta = value - previous
        if not -(2**31) <= delta < 2**31:
            raise ValueError("Referent delta exceeds signed 32-bit range")
        encoded.append(((delta << 1) ^ (delta >> 31)) & 0xFFFFFFFF)
        previous = value
    return bytes((value >> shift) & 255 for shift in (24, 16, 8, 0) for value in encoded)


def decompress_lz4(raw: bytes, expected: int) -> bytes:
    """Decode the raw LZ4 blocks used by Rojo; no native dependency needed."""
    output, offset = bytearray(), 0

    def extended(length: int) -> int:
        nonlocal offset
        if length == 15:
            while True:
                if offset >= len(raw):
                    raise ValueError("Truncated LZ4 length")
                extra = raw[offset]
                offset += 1
                length += extra
                if extra != 255:
                    break
        return length

    while offset < len(raw):
        token = raw[offset]
        offset += 1
        literals = extended(token >> 4)
        if offset + literals > len(raw) or len(output) + literals > expected:
            raise ValueError("Invalid LZ4 literal length")
        output.extend(raw[offset:offset + literals])
        offset += literals
        if offset == len(raw):
            break
        if offset + 2 > len(raw):
            raise ValueError("Truncated LZ4 offset")
        distance = int.from_bytes(raw[offset:offset + 2], "little")
        offset += 2
        length = extended(token & 15) + 4
        if distance == 0 or distance > len(output) or len(output) + length > expected:
            raise ValueError("Invalid LZ4 match")
        for _ in range(length):
            output.append(output[-distance])
    if len(output) != expected:
        raise ValueError("LZ4 decompressed size mismatch")
    return bytes(output)


@dataclass
class Chunk:
    tag: bytes
    payload: bytes
    raw: bytes
    reserved: int = 0


@dataclass
class ClassInfo:
    class_id: int
    name: str
    referents: list[int]


@dataclass
class Instance:
    referent: int
    class_id: int
    class_name: str
    name: str = ""
    parent: int = -1


def encoded_chunk(tag: bytes, payload: bytes, *, compression: str = "zstd", reserved: int = 0) -> bytes:
    if compression == "zstd":
        import zstandard
        packed = zstandard.ZstdCompressor(level=6).compress(payload)
        return struct.pack("<4sIII", tag, len(packed), len(payload), reserved) + packed
    if compression != "none":
        raise ValueError("Compression must be zstd or none")
    return struct.pack("<4sIII", tag, 0, len(payload), reserved) + payload


class Place:
    def __init__(self, data: bytes):
        if len(data) < 32 or data[:14] != MAGIC or data[14:16] != b"\0\0":
            raise ValueError("Expected a version-zero binary Roblox place/model")
        self.header = data[:32]
        self.chunks: list[Chunk] = []
        self.classes: dict[int, ClassInfo] = {}
        self.instances: dict[int, Instance] = {}
        self.properties: dict[tuple[int, str], tuple[int, int, bytes]] = {}
        self.parent_pairs: list[tuple[int, int]] = []
        self.parent_chunk: int | None = None
        offset = 32
        while offset < len(data):
            start = offset
            if offset + 16 > len(data):
                raise ValueError("Truncated chunk header")
            tag, packed_size, size, reserved = struct.unpack_from("<4sIII", data, offset)
            offset += 16
            if size > MAX_CHUNK or offset + (packed_size or size) > len(data):
                raise ValueError("Chunk size is invalid or exceeds limit")
            raw = data[offset:offset + (packed_size or size)]
            offset += packed_size or size
            if packed_size and raw.startswith(b"\x28\xb5\x2f\xfd"):
                import zstandard
                payload = zstandard.ZstdDecompressor().decompress(raw, max_output_size=size)
            else:
                payload = decompress_lz4(raw, size) if packed_size else raw
            if len(payload) != size:
                raise ValueError("Chunk decompressed size mismatch")
            self.chunks.append(Chunk(tag, payload, data[start:offset], reserved))
        if not self.chunks or self.chunks[-1].tag != b"END\0":
            raise ValueError("Binary place is missing its final END chunk")
        for index, chunk in enumerate(self.chunks):
            payload = chunk.payload
            if chunk.tag == b"INST":
                class_id = u32(payload)
                name, pos = string(payload, 4)
                if class_id in self.classes or pos + 5 > len(payload):
                    raise ValueError("Duplicate or malformed INST class")
                service, count = payload[pos], u32(payload, pos + 1)
                pos += 5
                if count > MAX_CHUNK // 4 or pos + 4 * count + (count if service else 0) != len(payload):
                    raise ValueError("Malformed INST referents/service flags")
                refs = decode_referents(payload[pos:pos + 4 * count], count)
                class_name = name.decode("utf-8")
                self.classes[class_id] = ClassInfo(class_id, class_name, refs)
                for ref in refs:
                    if ref < 0 or ref in self.instances:
                        raise ValueError("Invalid or duplicate instance referent")
                    self.instances[ref] = Instance(ref, class_id, class_name)
            elif chunk.tag == b"PROP":
                class_id = u32(payload)
                name, pos = string(payload, 4)
                if pos >= len(payload):
                    raise ValueError("Malformed PROP")
                key = (class_id, name.decode("utf-8"))
                if key in self.properties:
                    raise ValueError("Duplicate property group")
                self.properties[key] = (index, payload[pos], payload[pos + 1:])
            elif chunk.tag == b"PRNT":
                if self.parent_chunk is not None or not payload or payload[0] != 0:
                    raise ValueError("Expected one version-zero PRNT chunk")
                count = u32(payload, 1)
                if len(payload) != 5 + count * 8:
                    raise ValueError("Malformed PRNT arrays")
                refs = decode_referents(payload[5:5 + count * 4], count)
                parents = decode_referents(payload[5 + count * 4:], count)
                self.parent_pairs = list(zip(refs, parents))
                self.parent_chunk = index
        if u32(self.header, 16) != len(self.classes) or u32(self.header, 20) != len(self.instances):
            raise ValueError("Header instance/class counts do not match chunks")
        for class_id, info in self.classes.items():
            names = self.string_property(class_id, "Name")
            if names is not None:
                for ref, name in zip(info.referents, names):
                    self.instances[ref].name = name.decode("utf-8")
        seen = set()
        for ref, parent in self.parent_pairs:
            if ref not in self.instances or (parent != -1 and parent not in self.instances) or ref in seen:
                raise ValueError("Invalid or duplicate PRNT record")
            self.instances[ref].parent = parent
            seen.add(ref)

    @classmethod
    def read(cls, path: str | Path) -> Place:
        return cls(Path(path).read_bytes())

    def string_property(self, class_id: int, name: str) -> list[bytes] | None:
        prop = self.properties.get((class_id, name))
        if prop is None:
            return None
        _, datatype, raw = prop
        if datatype != 1:
            raise ValueError(f"Unsupported {name} property type: {datatype}")
        values, pos = [], 0
        for _ in self.classes[class_id].referents:
            value, pos = string(raw, pos)
            values.append(value)
        if pos != len(raw):
            raise ValueError("Unexpected bytes following string property")
        return values

    def path(self, referent: int) -> str:
        result, seen = [], set()
        while referent != -1:
            if referent in seen:
                raise ValueError("Cycle in instance parents")
            seen.add(referent)
            item = self.instances[referent]
            result.append(item.name)
            referent = item.parent
        return "/".join(reversed(result))

    def find(self, selector: str) -> Instance:
        matches = [item for item in self.instances.values() if item.name == selector]
        if len(matches) != 1:
            normalized = selector.removeprefix("game.").replace(".", "/").strip("/")
            matches = [item for item in self.instances.values() if self.path(item.referent) == normalized]
        if len(matches) != 1:
            raise ValueError(f"Instance selector must identify exactly one object: {selector!r}")
        return matches[0]

    def script_sources(self) -> dict[str, str]:
        result = {}
        for class_id, info in self.classes.items():
            if info.name not in SCRIPTS:
                continue
            sources = self.string_property(class_id, "Source")
            if sources is None:
                continue
            for ref, source in zip(info.referents, sources):
                result[self.path(ref)] = source.decode("utf-8")
        return result


def patch_bytes(data: bytes, replacements: dict[str, str], additions: list[dict[str, Any]] | None = None,
                *, compression: str = "zstd") -> bytes:
    place = Place(data)
    if not replacements and not additions:
        return data
    rewritten: dict[int, bytes] = {}
    replacement_groups: dict[int, dict[int, bytes]] = {}
    for selector, source in replacements.items():
        item = place.find(selector)
        if item.class_name not in SCRIPTS or not isinstance(source, str):
            raise ValueError("Replacements must target script instances and contain string sources")
        group = replacement_groups.setdefault(item.class_id, {})
        if item.referent in group:
            raise ValueError("The same script was selected more than once")
        group[item.referent] = source.encode("utf-8")
    for class_id, changes in replacement_groups.items():
        sources = place.string_property(class_id, "Source")
        if sources is None:
            raise ValueError("Selected script group has no serialized Source property")
        info = place.classes[class_id]
        values = [changes.get(ref, source) for ref, source in zip(info.referents, sources)]
        if values != sources:
            index = place.properties[(class_id, "Source")][0]
            payload = struct.pack("<I", class_id) + encoded_string("Source") + b"\x01" + b"".join(map(encoded_string, values))
            rewritten[index] = encoded_chunk(b"PROP", payload, compression=compression, reserved=place.chunks[index].reserved)

    new_inst, new_props, new_parents = [], [], []
    groups: dict[str, list[tuple[int, str, str]]] = {}
    next_ref = max(place.instances, default=-1) + 1
    for addition in additions or []:
        name, class_name, source = addition["name"], addition.get("class", "ModuleScript"), addition["source"]
        if class_name not in SCRIPTS or not isinstance(source, str) or not isinstance(name, str) or not name or "/" in name:
            raise ValueError("New scripts require a valid name, script class and string source")
        parent = place.find(addition.get("parentPath") or addition.get("parentName") or addition.get("parent", ""))
        if any(item.parent == parent.referent and item.name == name for item in place.instances.values()):
            raise ValueError("Addition would duplicate an existing sibling name")
        if next_ref >= 2**31:
            raise ValueError("No free signed 32-bit referents")
        groups.setdefault(class_name, []).append((next_ref, name, source))
        new_parents.append((next_ref, parent.referent))
        # Later additions may select this instance as parent by its unique name/path.
        place.instances[next_ref] = Instance(next_ref, -1, class_name, name, parent.referent)
        next_ref += 1
    next_class = max(place.classes, default=-1) + 1
    for class_name, rows in groups.items():
        refs = [row[0] for row in rows]
        payload = struct.pack("<I", next_class) + encoded_string(class_name) + b"\0" + struct.pack("<I", len(refs)) + encode_referents(refs)
        new_inst.append(encoded_chunk(b"INST", payload, compression=compression))
        for name, values in (("Name", [row[1] for row in rows]), ("Source", [row[2] for row in rows])):
            payload = struct.pack("<I", next_class) + encoded_string(name) + b"\x01" + b"".join(map(encoded_string, values))
            new_props.append(encoded_chunk(b"PROP", payload, compression=compression))
        next_class += 1
    if new_parents:
        if place.parent_chunk is None:
            raise ValueError("Cannot add scripts without a PRNT chunk")
        pairs = place.parent_pairs + new_parents
        payload = b"\0" + struct.pack("<I", len(pairs)) + encode_referents([ref for ref, _ in pairs]) + encode_referents([parent for _, parent in pairs])
        rewritten[place.parent_chunk] = encoded_chunk(b"PRNT", payload, compression=compression, reserved=place.chunks[place.parent_chunk].reserved)
    header = bytearray(place.header)
    struct.pack_into("<II", header, 16, len(place.classes) + len(groups), u32(place.header, 20) + len(new_parents))
    inst_end = max((i for i, chunk in enumerate(place.chunks) if chunk.tag == b"INST"), default=-1) + 1
    result = bytearray(header)
    for index, chunk in enumerate(place.chunks):
        if index == inst_end:
            result.extend(b"".join(new_inst))
        if index == place.parent_chunk:
            result.extend(b"".join(new_props))
        result.extend(rewritten.get(index, chunk.raw))
    output = bytes(result)
    verified = Place(output)
    if len(verified.instances) != u32(place.header, 20) + len(new_parents):
        raise ValueError("Patched place failed instance verification")
    return output


def patch(input_path: str | Path, output_path: str | Path, replacements: dict[str, str],
          additions: list[dict[str, Any]] | None = None, *, compression: str = "zstd") -> None:
    source, target = Path(input_path), Path(output_path)
    if source.resolve() == target.resolve():
        raise ValueError("Output must be separate from the original uploaded place")
    result = patch_bytes(source.read_bytes(), replacements, additions, compression=compression)
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=target.parent, prefix=".place-patch-", delete=False) as temporary:
        temporary.write(result)
        temporary_path = Path(temporary.name)
    temporary_path.replace(target)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--replacements", type=Path, help="JSON mapping unique script names or exact paths to source strings")
    parser.add_argument("--additions", type=Path, help="JSON array of name/class/source/parentPath or parentName records")
    parser.add_argument("--inspect", action="store_true", help="Print instance paths/classes and script sizes without executing code")
    parser.add_argument("--compression", choices=("zstd", "none"), default="zstd")
    args = parser.parse_args()
    if args.inspect:
        place = Place.read(args.input)
        sources = place.script_sources()
        print(json.dumps({"classes": len(place.classes), "instances": len(place.instances),
                          "scripts": {path: len(source.encode()) for path, source in sources.items()}}, indent=2))
        return
    if args.output is None:
        parser.error("--output is required when patching")
    replacements = json.loads(args.replacements.read_text()) if args.replacements else {}
    additions = json.loads(args.additions.read_text()) if args.additions else []
    patch(args.input, args.output, replacements, additions, compression=args.compression)
    print(f"Patched {len(replacements)} script selections and added {len(additions)} scripts into {args.output}; original retained.")


if __name__ == "__main__":
    main()
