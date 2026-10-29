"""Offline integrity boundaries for the source-photo review archive."""
import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("photo_pack", ROOT / "tools/package_photo_review.py")
photo_pack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(photo_pack)


class PhotoPackTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.references = self.root / "assets/references"
        self.source = self.references / "photo-review/test_subject.jpg"
        self.source.parent.mkdir(parents=True)
        self.source.write_bytes(b"exact source bytes; eligibility does not decode images")
        self.record = {
            "candidateId": "test_subject", "downloadedFile": self.source.relative_to(self.root).as_posix(),
            "redistributionReview": {"status": "OpenLicenseSourceReviewed"},
            "visualReview": {"reviewed": True}, "adultEraConservativeCheck": True,
            "selectedLicense": {"url": "https://creativecommons.org/licenses/by-sa/4.0/"},
            "sha256": hashlib.sha256(self.source.read_bytes()).hexdigest(),
            "gameEnabled": False, "robloxAssetId": 0,
        }
        root_patch = patch.object(photo_pack, "ROOT", self.root)
        references_patch = patch.object(photo_pack, "REFERENCES", self.references)
        root_patch.start()
        references_patch.start()
        self.addCleanup(root_patch.stop)
        self.addCleanup(references_patch.stop)

    def test_reviewed_unchanged_source_is_eligible(self):
        self.assertTrue(photo_pack.eligible(self.record))

    def test_source_modification_after_review_is_rejected(self):
        self.source.write_bytes(b"changed source")
        with self.assertRaisesRegex(ValueError, "changed after source review"):
            photo_pack.eligible(self.record)

    def test_missing_visual_review_is_rejected(self):
        del self.record["visualReview"]
        with self.assertRaisesRegex(ValueError, "requires visual review"):
            photo_pack.eligible(self.record)

    def test_outside_review_tree_is_rejected_even_when_hash_matches(self):
        outside = self.root / "outside.jpg"
        outside.write_bytes(self.source.read_bytes())
        self.record["downloadedFile"] = outside.relative_to(self.root).as_posix()
        with self.assertRaisesRegex(ValueError, "outside review folder"):
            photo_pack.eligible(self.record)

    def test_hold_is_excluded(self):
        self.record["redistributionReview"]["status"] = "Hold"
        self.assertFalse(photo_pack.eligible(self.record))

    def test_review_never_allows_production_enablement_or_uploaded_id(self):
        for change in ({"gameEnabled": True}, {"robloxAssetId": 123}):
            with self.subTest(change=change), self.assertRaisesRegex(ValueError, "separate from production"):
                photo_pack.eligible({**self.record, **change})


if __name__ == "__main__":
    unittest.main()
