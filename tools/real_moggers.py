#!/usr/bin/env python3
"""Build the disabled research registry; only audited authentic photo records can enable it."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def lua(value):
    if value is None: return "nil"
    if value is True: return "true"
    if value is False: return "false"
    if isinstance(value, str): return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)): return str(value)
    if isinstance(value, dict): return "{ " + ", ".join(f"[{lua(k)}] = {lua(v)}" for k, v in value.items()) + " }"
    if isinstance(value, list): return "{ " + ", ".join(lua(v) for v in value) + " }"
    raise ValueError("Unsupported registry value")


def generate():
    catalog = json.loads((ROOT / "assets/references/research-catalog.json").read_text())
    manifest = json.loads((ROOT / "assets/characters/manifest.json").read_text())
    photos = {e["characterId"]: e for e in manifest["portraits"]}
    ledger_path = ROOT / "assets/references/real-form-ledger.json"
    ledger = json.loads(ledger_path.read_text()) if ledger_path.exists() else {"forms": []}
    known = {row["id"]: row for row in ledger["forms"]}
    candidates = {row["candidateId"]: row for row in catalog["candidates"]}
    for row in known.values():
        candidates.setdefault(row["identityId"], {"candidateId": row["identityId"], "displayName": row["displayName"], "suggestedGameplay": row["tuning"], "sourceURL": None})
    entries = {}
    for candidate in candidates.values():
        variants = {"Classic": None}
        for row in known.values():
            if row["identityId"] == candidate["candidateId"]: variants[row["variant"]] = None
        for record in photos.values():
            if record.get("identityId") == candidate["candidateId"]:
                variants[record["variant"]] = record
        for variant, selected_photo in variants.items():
            key = "real_" + candidate["candidateId"] + "_" + variant.lower()
            tuning = candidate.get("suggestedGameplay") or {"rarity": "Rare", "income": 20, "attack": 32}
            entry = {
                "displayName": candidate["displayName"], "identityId": candidate["candidateId"],
                "variant": variant, "referenceType": "RealPerson", "imageStatus": "LicenseVerificationPending",
                "portraitAssetId": 0, "requestedEnabled": False, "obtainable": False,
                "identityVerified": False, "authenticPhotograph": False, "adultEraVerified": False,
                "copyrightPermission": False, "commercialUseAllowed": False, "likenessPermission": "missing",
                "sourceURL": candidate.get("sourceURL"), "creator": None, "license": None,
                "copyrightEvidence": None, "likenessEvidence": None, "uploadEvidence": None, "uploadStatus": "not-uploaded",
                "rarity": tuning["rarity"], "income": tuning["income"], "attack": tuning["attack"],
                "defense": 15, "health": 150, "speed": 20, "ability": "Spotlight", "weight": 1,
                "modelKey": "mogger_" + candidate["candidateId"], "notes": "Identity/photo/rights require verification; no real portrait supplied.",
            }
            photo = selected_photo
            if photo:
                from portraits import approved
                approved(photo)
                for field in ("identityVerified", "authenticPhotograph", "adultEraVerified", "copyrightPermission", "commercialUseAllowed", "likenessPermission", "sourceURL", "creator", "license", "copyrightEvidence", "likenessEvidence", "uploadEvidence", "uploadStatus"):
                    entry[field] = photo.get(field)
                entry["portraitAssetId"] = photo.get("robloxAssetId", 0)
                entry["imageStatus"] = "Approved" if entry["portraitAssetId"] else "Unavailable"
                entry["requestedEnabled"] = photo.get("requestedEnabled") is True
                entry["modelKey"] = photo.get("modelKey") or entry["modelKey"]
            entries[key] = entry
            known[key] = {"id": key, "identityId": entry["identityId"], "displayName": entry["displayName"], "variant": entry["variant"], "tuning": tuning}
    ledger_path.write_text(json.dumps({"schemaVersion": 1, "note": "Stable form IDs are retained after photo withdrawal to protect owned instances.", "forms": list(known.values())}, indent=2) + "\n")
    target = ROOT / "src/shared/RealMoggers.luau"
    target.write_text('--!strict\n-- Generated verified-photo gate data. Proposed references are not approved identities.\nreturn ' + lua(entries) + '\n')
    print(f"Prepared {len(entries)} real-person reference records; no automatic photo upload or identity approval.")


if __name__ == "__main__": generate()
