"""Permission gates and deterministic PNG preparation; no network or Roblox upload."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("portraits", ROOT / "tools/portraits.py")
portraits = importlib.util.module_from_spec(spec)
spec.loader.exec_module(portraits)


class PortraitTests(unittest.TestCase):
    def setUp(self):
        # Synthetic records are confined to unit tests; no test ID or pixels enter production assets.
        self.entry = {"characterId": "real_test_person_classic", "identityId": "test_person", "variant": "Classic",
            "referenceType": "RealPerson", "authenticPhotograph": True, "identityVerified": True,
            "adultEraVerified": True, "approvalStatus": "approved", "copyrightPermission": True,
            "creator": "Synthetic test photographer", "license": "Synthetic test record",
            "containsRealPerson": True, "likenessPermission": "granted", "likenessEvidence": "Synthetic test record",
            "projectOriginal": False, "sourceURL": "https://example.org/test", "copyrightEvidence": "Synthetic test record",
            "commercialUseAllowed": True, "attribution": "Synthetic test credit", "robloxAssetId": 0,
            "uploadStatus": "not-uploaded", "uploadEvidence": None}

    def test_no_generated_human_placeholders_or_unapproved_real_photos_ship(self):
        data = json.loads(portraits.MANIFEST.read_text())
        for entry in data["portraits"]: portraits.approved(entry)
        self.assertEqual(list((ROOT / "assets/characters").glob("placeholders/*.png")), [])
        outputs = {(ROOT / entry["outputFile"]).resolve() for entry in data["portraits"]}
        for image in (ROOT / "assets/characters").glob("roblox/*.png"):
            self.assertIn(image.resolve(), outputs)
        with self.assertRaises(ValueError): portraits.create_placeholders()

    def test_fake_or_unverified_faces_never_pass_an_authentic_photo_gate(self):
        for field, value in [("referenceType", "LegacyFictional"), ("authenticPhotograph", False),
                             ("identityVerified", False), ("adultEraVerified", False),
                             ("containsRealPerson", False), ("identityId", "wrong_person"), ("variant", "Imaginary")]:
            with self.subTest(field=field), self.assertRaises(ValueError):
                portraits.approved({**self.entry, field: value})

    def test_missing_approval_or_copyright_never_passes(self):
        for field, value in [("approvalStatus", "NeedsApproval"), ("copyrightPermission", False),
                             ("creator", ""), ("license", "")]:
            with self.subTest(field=field), self.assertRaises(ValueError):
                portraits.approved({**self.entry, field: value})

    def test_photo_license_does_not_grant_recognizable_likeness(self):
        for status in (None, "unknown", "not-applicable-original"):
            with self.subTest(status=status), self.assertRaises(ValueError):
                portraits.approved({**self.entry, "containsRealPerson": True, "likenessPermission": status})

    def test_third_party_requires_documented_commercial_rights_and_credits(self):
        entry = {**self.entry, "projectOriginal": False, "sourceURL": ""}
        with self.assertRaises(ValueError): portraits.approved(entry)
        entry.update(sourceURL="https://example.org/approved-source", copyrightEvidence="Owner supplied license record", attribution="Credit: example photographer")
        portraits.approved(entry)
        for field, value in [("commercialUseAllowed", False), ("commercialUseAllowed", "false"),
                             ("copyrightEvidence", ""), ("sourceURL", ""), ("attribution", "")]:
            with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                portraits.approved({**entry, field: value})

    def test_asset_ids_require_integer_and_owner_upload_record(self):
        for value in ("123", -1, 1.5, True, float("nan"), 9007199254740992):
            with self.subTest(value=value), self.assertRaises(ValueError):
                portraits.approved({**self.entry, "robloxAssetId": value})
        with self.assertRaises(ValueError): portraits.approved({**self.entry, "robloxAssetId": 123})
        # Synthetic ID tests validation only; it is never emitted to the real mapping.
        portraits.approved({**self.entry, "robloxAssetId": 123, "uploadStatus": "uploaded", "uploadEvidence": "synthetic test record"})

    def test_path_traversal_cannot_read_outside_character_assets(self):
        for value in ("/etc/passwd", "assets/characters/../../../README.md", "assets/references/research-catalog.json"):
            with self.subTest(value=value), self.assertRaises(ValueError): portraits.within_assets(value)

    def test_normalization_keeps_source_and_produces_square_rgb_png(self):
        from PIL import Image
        with tempfile.TemporaryDirectory(dir=ROOT / "assets/characters") as directory:
            directory = Path(directory)
            source = directory / "source.jpg"
            Image.new("RGB", (800, 600), (120, 80, 180)).save(source)
            original = source.read_bytes()
            entry = {**self.entry, "sourceFile": source.relative_to(ROOT).as_posix(), "outputFile": (directory / "portrait.png").relative_to(ROOT).as_posix()}
            result = portraits.normalize(entry)
            self.assertEqual(source.read_bytes(), original)
            self.assertEqual(result["dimensions"], [512, 512])
            with Image.open(directory / "portrait.png") as image:
                self.assertEqual(image.size, (512, 512)); self.assertEqual(image.mode, "RGB")
            with self.assertRaises(ValueError): portraits.normalize({**entry, "outputFile": entry["sourceFile"]})

    def test_blocked_research_candidates_are_never_enabled(self):
        data = json.loads((ROOT / "assets/references/research-catalog.json").read_text())
        self.assertGreaterEqual(data["namedCandidates"], 20)
        for candidate in data["candidates"]:
            if candidate["portraitStatus"] != "Approved":
                self.assertIs(candidate["enabled"], False)

    def test_withdrawing_photo_records_retains_registered_variant_ids(self):
        registry_spec = importlib.util.spec_from_file_location("test_real_registry_generator", ROOT / "tools/real_moggers.py")
        registry = importlib.util.module_from_spec(registry_spec)
        registry_spec.loader.exec_module(registry)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for sub in ("assets/references", "assets/characters", "src/shared"): (root / sub).mkdir(parents=True)
            reference = {"candidateId": "test_person", "displayName": "Synthetic Test Reference", "suggestedGameplay": {"rarity": "Rare", "income": 20, "attack": 32}, "sourceURL": None}
            (root / "assets/references/research-catalog.json").write_text(json.dumps({"candidates": [reference]}))
            photo = {**self.entry, "variant": "Prime", "characterId": "real_test_person_prime"}
            manifest = root / "assets/characters/manifest.json"
            manifest.write_text(json.dumps({"portraits": [photo]}))
            with patch.object(registry, "ROOT", root), patch.dict(sys.modules, {"portraits": portraits}):
                registry.generate()
                manifest.write_text(json.dumps({"portraits": []}))
                registry.generate()
            ledger = json.loads((root / "assets/references/real-form-ledger.json").read_text())
            self.assertEqual({row["id"] for row in ledger["forms"]}, {"real_test_person_classic", "real_test_person_prime"})


if __name__ == "__main__": unittest.main()
