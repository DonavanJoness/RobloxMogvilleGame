#!/usr/bin/env python3
"""Local, permission-gated portrait preparation. Never downloads or uploads images."""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets/characters/manifest.json"
ID = re.compile(r"^[a-z][a-z0-9_]{0,79}$")


def within_assets(relative: str) -> Path:
    path = (ROOT / relative).resolve()
    if not path.is_relative_to((ROOT / "assets/characters").resolve()):
        raise ValueError("Portrait paths must stay within assets/characters")
    return path


def approved(entry: dict) -> None:
    if not ID.fullmatch(entry.get("characterId", "")):
        raise ValueError("Invalid characterId")
    if entry.get("approvalStatus") != "approved" or entry.get("copyrightPermission") is not True:
        raise ValueError("Portrait requires explicit copyright and project approval")
    if not entry.get("creator") or not entry.get("license"):
        raise ValueError("Creator and license documentation required")
    if entry.get("containsRealPerson") is not False:
        if entry.get("likenessPermission") != "granted" or not entry.get("likenessEvidence"):
            raise ValueError("Recognizable-person game use requires separate documented likeness approval")
    if not entry.get("projectOriginal"):
        if not entry.get("sourceURL") or not entry.get("copyrightEvidence") or entry.get("commercialUseAllowed") is not True:
            raise ValueError("Third-party assets need source, commercial-use and copyright evidence")
        if not entry.get("attribution"):
            raise ValueError("Third-party assets need an attribution/credit line")
    asset_id = entry.get("robloxAssetId", 0)
    if type(asset_id) is not int or not 0 <= asset_id <= 9007199254740991:
        raise ValueError("Roblox asset ID must be zero or an actual positive integer")
    if asset_id and (entry.get("uploadStatus") != "uploaded" or not entry.get("uploadEvidence")):
        raise ValueError("Nonzero asset IDs require a recorded successful owner upload")


def normalize(entry: dict) -> dict:
    from PIL import Image, ImageOps
    approved(entry)
    source = within_assets(entry["sourceFile"])
    output = within_assets(entry["outputFile"])
    if source == output:
        raise ValueError("Processed outputs must not replace source files")
    if source.suffix.lower() not in (".png", ".jpg", ".jpeg"):
        raise ValueError("Only local PNG/JPEG images are supported")
    if source.stat().st_size > 10 * 1024 * 1024:
        raise ValueError("Portrait exceeds 10MiB input limit")
    with Image.open(source) as image:
        if image.width * image.height > 25_000_000:
            raise ValueError("Portrait exceeds pixel limit")
        image = ImageOps.exif_transpose(image).convert("RGB")
        image = ImageOps.fit(image, (512, 512), method=Image.Resampling.LANCZOS)
        output.parent.mkdir(parents=True, exist_ok=True)
        image.save(output, "PNG", optimize=True)  # Metadata removed; source retained unchanged.
    return {"characterId": entry["characterId"], "outputFile": entry["outputFile"],
            "sha256": hashlib.sha256(output.read_bytes()).hexdigest(), "dimensions": [512, 512],
            "robloxAssetId": entry.get("robloxAssetId", 0)}


def create_placeholders():
    """Draw original geometric icons, never representations of research candidates."""
    from PIL import Image, ImageDraw
    # Parse the project-owned declarative roster via a Luau export so Config is authoritative.
    import subprocess
    import tempfile
    from test import binary
    modules = {}
    def module(path):
        name = path.stem
        if name in modules: return name
        modules[name] = ""
        text = path.read_text()
        def dependency(match):
            return 'load(' + json.dumps(module(path.parent / (match.group(1) + '.luau'))) + ')'
        text = re.sub(r'require\(script.Parent.(\w+)\)', dependency, text)
        modules[name] = text
        return name
    module(ROOT / "src/shared/Config.luau")
    code = 'local factories,cache={},{}\nlocal function load(k) if cache[k] then return cache[k] end cache[k]=factories[k]() return cache[k] end\n'
    for name, source in modules.items(): code += f'factories[{json.dumps(name)}]=function()\n{source}\nend\n'
    code += 'for id,c in load("Config").Characters do print(id .. "|" .. c.color .. "|" .. c.form) end\n'
    with tempfile.TemporaryDirectory() as tmp:
        script = Path(tmp) / "roster.luau"
        script.write_text(code)
        lines = subprocess.check_output([binary("luau"), str(script)], text=True).splitlines()
    entries = []
    for line in sorted(lines):
        character_id, color, form = line.split("|")
        rgb = tuple(int(color[i:i + 2], 16) for i in (0, 2, 4))
        image = Image.new("RGB", (512, 512), (23, 22, 46))
        draw = ImageDraw.Draw(image)
        for y in range(512):
            t = y / 511
            draw.line((0, y, 511, y), fill=tuple(int(c * (0.25 + 0.3 * (1-t))) for c in rgb))
        draw.rounded_rectangle((18, 18, 494, 494), 48, outline=rgb, width=8)
        draw.ellipse((68, 52, 444, 428), fill=(32, 29, 57), outline=rgb, width=4)
        draw.rounded_rectangle((113, 310, 399, 510), 55, fill=rgb)
        draw.rounded_rectangle((166, 112, 346, 334), 32, fill=(239, 207, 172))
        draw.rounded_rectangle((155, 96, 356, 156), 18, fill=(32, 25, 52))
        draw.rectangle((191, 201, 220, 215), fill=(28, 24, 41))
        draw.rectangle((291, 201, 320, 215), fill=(28, 24, 41))
        draw.line((222, 278, 291, 278), fill=(138, 80, 94), width=7)
        # Form-specific geometry: same original identity silhouette, separate collectibles.
        if form in ("Prime", "Ascended"):
            draw.polygon([(164, 113), (154, 65), (216, 91), (256, 44), (296, 91), (358, 65), (348, 113)], fill=(255, 212, 116))
        if form == "Ascended":
            for x, y in ((80, 120), (422, 150), (390, 370), (105, 355)):
                draw.polygon([(x, y-20), (x+8, y-8), (x+20, y), (x+8, y+8), (x, y+20), (x-8, y+8), (x-20, y), (x-8, y-8)], fill=(255, 229, 154))
        source_file = f"assets/characters/placeholders/{character_id}.png"
        target = within_assets(source_file)
        target.parent.mkdir(parents=True, exist_ok=True)
        # Preserve later owner-provided artwork; this command creates missing placeholders only.
        if not target.exists(): image.save(target, "PNG", optimize=True)
        entries.append({"characterId": character_id, "sourceFile": source_file,
            "outputFile": f"assets/characters/roblox/{character_id}.png", "creator": "MOGVILLE procedural placeholder generator",
            "license": "Original project artwork; no third-party source material", "projectOriginal": True,
            "copyrightPermission": True, "containsRealPerson": False, "likenessPermission": "not-applicable-original",
            "approvalStatus": "approved", "commercialUseAllowed": True, "sourceURL": None,
            "attribution": "Original geometric placeholder, not a real-person portrait", "robloxAssetId": 0,
            "uploadStatus": "not-uploaded", "uploadEvidence": None})
    if MANIFEST.exists():
        current = json.loads(MANIFEST.read_text())
        saved = {e["characterId"]: e for e in current["portraits"]}
        for entry in entries: saved.setdefault(entry["characterId"], entry)
        current["portraits"] = list(saved.values())
    else:
        current = {"schemaVersion": 1, "portraitSize": [512, 512], "portraits": entries}
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(json.dumps(current, indent=2) + "\n")


def prepare():
    manifest = json.loads(MANIFEST.read_text())
    seen, output_paths, processed, mapping = set(), set(), [], {}
    for entry in manifest["portraits"]:
        if entry["characterId"] in seen: raise ValueError("Duplicate portrait characterId")
        seen.add(entry["characterId"])
        output = within_assets(entry["outputFile"])
        if output in output_paths: raise ValueError("Duplicate portrait output path")
        output_paths.add(output)
        # NeedsApproval references never enter the production manifest or get processed.
        processed.append(normalize(entry))
        mapping[entry["characterId"]] = entry.get("robloxAssetId", 0)
    (ROOT / "assets/characters/processed-manifest.json").write_text(json.dumps({"portraits": processed}, indent=2) + "\n")
    lua = '--!strict\n-- Generated by tools/portraits.py. Zero = procedural fallback, not an uploaded ID.\nreturn {\n'
    for character_id, asset_id in sorted(mapping.items()): lua += f'\t{character_id} = {asset_id},\n'
    (ROOT / "src/shared/PortraitAssets.luau").write_text(lua + '}\n')
    print(f"Prepared {len(processed)} approved 512x512 PNGs; {sum(bool(n) for n in mapping.values())} recorded Roblox uploads.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--create-placeholders", action="store_true")
    args = parser.parse_args()
    if args.create_placeholders: create_placeholders()
    prepare()
