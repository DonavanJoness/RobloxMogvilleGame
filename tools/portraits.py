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
    if entry.get("referenceType") != "RealPerson" or entry.get("authenticPhotograph") is not True:
        raise ValueError("Only authentic photographs of the referenced real person are accepted")
    if entry.get("identityVerified") is not True or entry.get("adultEraVerified") is not True:
        raise ValueError("Identity and adult-era portrait verification required")
    if not ID.fullmatch(entry.get("characterId", "")):
        raise ValueError("Invalid characterId")
    identity_id = entry.get("identityId", "")
    variant = entry.get("variant", "")
    if not ID.fullmatch(identity_id) or variant not in ("Young", "Classic", "Prime", "Ascended"):
        raise ValueError("Verified identity and supported photographed variant required")
    if entry["characterId"] != f"real_{identity_id}_{variant.lower()}":
        raise ValueError("Portrait ID must match its referenced identity and variant")
    if entry.get("approvalStatus") != "approved" or entry.get("copyrightPermission") is not True:
        raise ValueError("Portrait requires explicit copyright and project approval")
    if not entry.get("creator") or not entry.get("license"):
        raise ValueError("Creator and license documentation required")
    if entry.get("containsRealPerson") is not True:
        raise ValueError("Portrait must be an authentic photo of its named real-person reference")
    if entry.get("containsRealPerson") is True:
        if entry.get("likenessPermission") != "granted" or not entry.get("likenessEvidence"):
            raise ValueError("Recognizable-person game use requires separate documented likeness approval")
    if not entry.get("sourceURL") or not entry.get("copyrightEvidence") or entry.get("commercialUseAllowed") is not True:
        raise ValueError("Photos need source, commercial-use and copyright evidence")
    if not entry.get("attribution"):
        raise ValueError("Photos need an attribution/credit line")
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
    raise ValueError("V3 forbids generated human portrait substitutes. Supply an approved authentic photograph.")


def prepare():
    manifest = json.loads(MANIFEST.read_text())
    catalog = json.loads((ROOT / "assets/references/research-catalog.json").read_text())
    known_identities = {row["candidateId"] for row in catalog["candidates"]}
    seen, output_paths, processed, mapping = set(), set(), [], {}
    for entry in manifest["portraits"]:
        if entry.get("identityId") not in known_identities:
            raise ValueError("Add and verify the exact reference in the research catalog before processing its photograph")
        if entry["characterId"] in seen: raise ValueError("Duplicate portrait characterId")
        seen.add(entry["characterId"])
        output = within_assets(entry["outputFile"])
        if output in output_paths: raise ValueError("Duplicate portrait output path")
        output_paths.add(output)
        # NeedsApproval references never enter the production manifest or get processed.
        processed.append(normalize(entry))
        mapping[entry["characterId"]] = entry.get("robloxAssetId", 0)
    (ROOT / "assets/characters/processed-manifest.json").write_text(json.dumps({"portraits": processed}, indent=2) + "\n")
    lua = '--!strict\n-- Generated approved authentic-photo IDs. Missing = explicit unresolved panel, never a substitute face.\nreturn {\n'
    for character_id, asset_id in sorted(mapping.items()): lua += f'\t{character_id} = {asset_id},\n'
    (ROOT / "src/shared/PortraitAssets.luau").write_text(lua + '}\n')
    print(f"Prepared {len(processed)} approved authentic photos; {sum(bool(n) for n in mapping.values())} recorded Roblox uploads.")
    from real_moggers import generate
    generate()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--create-placeholders", action="store_true")
    args = parser.parse_args()
    if args.create_placeholders: create_placeholders()
    prepare()
