"""Binary source replacement and additions preserve unrelated place data."""
import importlib.util
from pathlib import Path
import struct
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("patch_place", ROOT / "tools/patch_place.py")
patcher = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = patcher
spec.loader.exec_module(patcher)


def fixture():
    c, s, refs = patcher.encoded_chunk, patcher.encoded_string, patcher.encode_referents
    header = patcher.MAGIC + b"\0\0" + struct.pack("<II", 2, 3) + b"RESERVED"
    def chunk(tag, data):
        return c(tag, data, compression="none", reserved=23)
    def inst(class_id, name, values):
        return chunk(b"INST", struct.pack("<I", class_id) + s(name) + b"\0" + struct.pack("<I", len(values)) + refs(values))
    def prop(class_id, name, values):
        return chunk(b"PROP", struct.pack("<I", class_id) + s(name) + b"\x01" + b"".join(s(v) for v in values))
    return b"".join([header, chunk(b"META", b"opaque metadata"),
        inst(8, "Folder", [5]), inst(12, "ModuleScript", [18, 22]),
        prop(8, "Name", ["Shared"]), prop(12, "Name", ["Existing", "Untouched"]),
        prop(12, "Source", ["return 1", "return 2"]),
        chunk(b"TEST", b"unknown property/chunk retained\0\xff"),
        chunk(b"PRNT", b"\0" + struct.pack("<I", 3) + refs([5, 18, 22]) + refs([-1, 5, 5])),
        chunk(b"END\0", b"</roblox>")])


class PlacePatchTests(unittest.TestCase):
    def test_noop_retains_every_original_byte(self):
        original = fixture()
        self.assertEqual(patcher.patch_bytes(original, {}, [], compression="none"), original)
        self.assertEqual(patcher.patch_bytes(original, {"Existing": "return 1"}, [], compression="none"), original)

    def test_replacement_preserves_other_sources_instances_unknown_chunks_and_refs(self):
        original = patcher.Place(fixture())
        output = patcher.Place(patcher.patch_bytes(fixture(), {"Shared/Existing": "return 'photo source'"}, compression="none"))
        self.assertEqual(output.script_sources(), {"Shared/Existing": "return 'photo source'", "Shared/Untouched": "return 2"})
        self.assertEqual(original.parent_pairs, output.parent_pairs)
        self.assertEqual(original.instances, output.instances)
        self.assertEqual(original.header, output.header)
        for before, after in zip(original.chunks, output.chunks):
            if before.payload != after.payload:
                self.assertEqual(before.tag, b"PROP")
                self.assertIn(b"Source", before.payload)
            else:
                self.assertEqual(before.raw, after.raw)

    def test_new_module_and_client_script_get_fresh_refs_and_valid_parents(self):
        output = patcher.Place(patcher.patch_bytes(fixture(), {"Existing": "return 10"}, [
            {"name": "Pixels", "source": "return {}", "parentPath": "Shared"},
            {"name": "Display", "class": "LocalScript", "source": "print('loaded')", "parentName": "Shared"},
            {"name": "ChildPixels", "source": "return 'bytes'", "parentName": "Pixels"},
        ], compression="none"))
        self.assertEqual(len(output.classes), 4)
        self.assertEqual(len(output.instances), 6)
        self.assertEqual(output.find("Pixels").referent, 23)
        self.assertEqual(output.find("Shared/Pixels/ChildPixels").parent, 23)
        self.assertEqual(output.find("Display").class_name, "LocalScript")
        self.assertEqual(output.parent_pairs[:3], patcher.Place(fixture()).parent_pairs)
        self.assertEqual(output.script_sources()["Shared/Untouched"], "return 2")

    def test_rejects_bad_selectors_non_scripts_and_duplicate_siblings(self):
        for replacements, additions in [
            ({"Missing": "return 0"}, []), ({"Shared": "return 0"}, []),
            ({}, [{"name": "Existing", "source": "return 0", "parentName": "Shared"}]),
            ({}, [{"name": "Pixels", "source": "return 0", "parentName": "Missing"}]),
        ]:
            with self.subTest(replacements=replacements, additions=additions), self.assertRaises(ValueError):
                patcher.patch_bytes(fixture(), replacements, additions, compression="none")

    def test_does_not_overwrite_the_original(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.rbxl"
            path.write_bytes(fixture())
            with self.assertRaises(ValueError):
                patcher.patch(path, path, {"Existing": "return 3"}, compression="none")
            target = Path(directory) / "result.rbxl"
            patcher.patch(path, target, {"Existing": "return 3"}, compression="none")
            self.assertEqual(path.read_bytes(), fixture())
            self.assertEqual(patcher.Place.read(target).script_sources()["Shared/Existing"], "return 3")

    def test_signed_interleaved_referents_roundtrip(self):
        values = [0, 2, -1, 2000, 2001, 5, 2147483647, 0]
        self.assertEqual(patcher.decode_referents(patcher.encode_referents(values), len(values)), values)

    def test_zstandard_chunks_and_rojo_lz4_blocks_decode_without_code_execution(self):
        try:
            import zstandard
        except ImportError:
            self.skipTest("Studio Zstandard support requires the optional zstandard package")
        original = patcher.Place(fixture())
        compressed = original.header + b"".join(patcher.encoded_chunk(c.tag, c.payload, reserved=c.reserved)
                                                for c in original.chunks)
        self.assertEqual(patcher.Place(compressed).script_sources(), original.script_sources())
        self.assertEqual(patcher.decompress_lz4(b"\x50hello", 5), b"hello")
        self.assertEqual(patcher.decompress_lz4(b"\x32abc\x03\x00", 9), b"abcabcabc")
        for data, size in [(b"\x32abc\0\0", 9), (b"\x50hi", 5), (b"\x50hello", 2)]:
            with self.subTest(data=data, size=size), self.assertRaises(ValueError):
                patcher.decompress_lz4(data, size)

    def test_header_mismatches_and_truncation_are_rejected(self):
        corrupt = bytearray(fixture())
        struct.pack_into("<I", corrupt, 20, 99)
        with self.assertRaises(ValueError):
            patcher.Place(bytes(corrupt))
        with self.assertRaises(ValueError):
            patcher.Place(fixture()[:-3])


if __name__ == "__main__":
    unittest.main()
