#!/usr/bin/env python3
"""Embed source-reviewed photographs as RGBA data for an owner-authorized Studio preview.

This never creates faces, uploads Roblox assets, or claims a subject/model release.
Original photographs are preserved; framing and technical resizing are documented.
"""
import base64
import hashlib
import json
from pathlib import Path
import sys

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
EDGE = 256


def prepare():
    crop_file = ROOT / "assets/references/face-crops.json"
    crops = json.loads(crop_file.read_text())
    if "crops" in crops:
        crops = crops["crops"]
    review_root = ROOT / "assets/references/live-research"
    output = ROOT / "assets/characters/studio-preview"
    output.mkdir(parents=True, exist_ok=True)
    rows, manifest = {}, []
    for identity_id, crop in sorted(crops.items()):
        source_record = review_root / (identity_id + ".json")
        record = json.loads(source_record.read_text())
        if record.get("redistributionReview", {}).get("status") != "OpenLicenseSourceReviewed":
            raise ValueError("Unreviewed copyright source: " + identity_id)
        if record.get("visualReview", {}).get("reviewed") is not True or record.get("adultEraConservativeCheck") is not True:
            raise ValueError("Source/date/visual review incomplete: " + identity_id)
        source = (ROOT / record["downloadedFile"]).resolve()
        if not source.is_relative_to((ROOT / "assets/references/photo-review").resolve()):
            raise ValueError("Photo outside reviewed sources")
        if hashlib.sha256(source.read_bytes()).hexdigest() != record["sha256"]:
            raise ValueError("Reviewed source bytes changed: " + identity_id)
        license_record = record.get("selectedLicense", {})
        if not all((record.get("attribution"), record.get("fileDescriptionURL"), license_record.get("name"), license_record.get("url"))):
            raise ValueError("Photo-specific source, attribution and license required")
        box = crop["box"]
        if len(box) != 4 or not (0 <= box[0] < box[2] <= 1 and 0 <= box[1] < box[3] <= 1):
            raise ValueError("Invalid normalized face framing")
        with Image.open(source) as original:
            photo = ImageOps.exif_transpose(original).convert("RGBA")
            bounds = tuple(round(value * (photo.width if index % 2 == 0 else photo.height)) for index, value in enumerate(box))
            framed = photo.crop(bounds)
            if min(framed.size) < 32:
                raise ValueError("Selected face region too small: " + identity_id)
            image = ImageOps.pad(framed, (EDGE, EDGE), Image.Resampling.LANCZOS, color=(15, 19, 30, 255))
            rgba = image.tobytes()
            image_path = output / (identity_id + ".png")
            image.save(image_path, "PNG", optimize=True)
        if len(rgba) != EDGE * EDGE * 4:
            raise ValueError("RGBA byte count mismatch")
        attribution = record["attribution"] + " MOGVILLE preview change: cropped to documented head framing, proportionally resized with dark margins to 256×256, and encoded as RGBA; original source retained."
        rows[identity_id] = {
            "identityId": identity_id, "variant": "Classic", "displayName": record["displayName"],
            "width": EDGE, "height": EDGE, "rgbaBase64": base64.b64encode(rgba).decode("ascii"),
            "sourceVerified": True, "adultEraVerified": True, "ownerAuthorized": True,
            "attribution": attribution, "sourceURL": record["fileDescriptionURL"],
            "license": license_record["name"], "licenseURL": license_record["url"],
            "rgbaSHA256": hashlib.sha256(rgba).hexdigest(),
        }
        match = record.get("requestedReferenceMapping") or record.get("referenceSelection")
        if match:
            rows[identity_id]["requestedReferenceNote"] = match.get("note") or match.get("explanation", "")
        manifest.append({
            "identityId": identity_id, "displayName": record["displayName"],
            "sourceFile": record["downloadedFile"], "sourceSHA256": record["sha256"],
            "cropBoxNormalized": box, "cropBoundsPixels": list(bounds),
            "outputFile": image_path.relative_to(ROOT).as_posix(),
            "outputSHA256": hashlib.sha256(image_path.read_bytes()).hexdigest(),
            "rgbaSHA256": rows[identity_id]["rgbaSHA256"], "dimensions": [EDGE, EDGE],
            "attribution": attribution, "sourceURL": record["fileDescriptionURL"],
            "license": license_record["name"], "licenseURL": license_record["url"],
            "sourceEvidence": source_record.relative_to(ROOT).as_posix(),
            "studioPreviewOnly": True, "robloxAssetId": 0, "thirdPartyLikenessRelease": "NotEstablished",
            "requestedReferenceMatch": match,
        })
    lines = ["--!strict", "-- Authentic source photographs. Owner-authorized Studio preview, not Roblox uploads or model-release records.", "return {"]
    for identity_id, row in rows.items():
        entries = ", ".join("[" + json.dumps(key) + "] = " + json.dumps(value, ensure_ascii=False) for key, value in row.items())
        # JSON scalar literals used here are also valid Luau scalar literals.
        lines.append("[" + json.dumps(identity_id) + "] = { " + entries + " },")
    lines.append("}\n")
    (ROOT / "src/shared/EmbeddedPhotoCatalog.luau").write_text("\n".join(lines))
    data = {"schemaVersion": 1, "scope": "Owner-authorized local Studio face preview; no production rights/upload approval inferred.",
            "ownerAuthorization": "Project owner explicitly requested actual face-photo integration and granted project permission in this chat on 2026-11-16. This is not represented as a release from the depicted people.",
            "portraits": manifest}
    (ROOT / "assets/references/embedded-photo-manifest.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    credits = "# Embedded face-photo preview credits\n\nSource files retain their individual photo licenses. These previews are adaptations under those same licenses. No endorsement or model release is implied. Original source files and copyright evidence are retained.\n\n"
    for row in manifest:
        credits += "## " + row["displayName"] + "\n\n" + row["attribution"] + "\n\n"
    (output / "CREDITS.md").write_text(credits.rstrip() + "\n")
    print(f"Embedded {len(rows)} authentic photographs as client-readable RGBA; zero Roblox uploads.")


if __name__ == "__main__":
    prepare()
