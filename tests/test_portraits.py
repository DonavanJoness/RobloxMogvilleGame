"""Permission gates and deterministic PNG preparation; no network or Roblox upload."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("portraits", ROOT / "tools/portraits.py")
portraits = importlib.util.module_from_spec(spec)
spec.loader.exec_module(portraits)


class PortraitTests(unittest.TestCase):
    def setUp(self):
        self.entry = copy.deepcopy(json.loads(portraits.MANIFEST.read_text())["portraits"][0])

    def test_approved_original_placeholders_have_zero_upload_ids(self):
        data = json.loads(portraits.MANIFEST.read_text())
        self.assertEqual(len(data["portraits"]), 24)
        from PIL import Image
        for entry in data["portraits"]:
            portraits.approved(entry)
            self.assertFalse(entry["containsRealPerson"])
            self.assertEqual(entry["robloxAssetId"], 0)
            with Image.open(ROOT / entry["outputFile"]) as image:
                self.assertEqual(image.size, (512, 512))
                self.assertEqual(image.format, "PNG")

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
        entry = {**self.entry, "projectOriginal": False}
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
        self.assertEqual(data["verifiedCandidates"], 0)
        for candidate in data["candidates"]:
            self.assertIs(candidate["enabled"], False)
            self.assertEqual(candidate["portraitStatus"], "NeedsApproval")
            self.assertIsNone(candidate["portraitFile"])


if __name__ == "__main__": unittest.main()
