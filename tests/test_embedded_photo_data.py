"""Verify actual bundled photographs, credits and lossless RGBA payload integrity."""
import base64
import hashlib
import json
from pathlib import Path
import re
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


class EmbeddedPhotoDataTests(unittest.TestCase):
    def test_each_embedded_payload_matches_its_credited_photo_output(self):
        manifest = json.loads((ROOT / "assets/references/embedded-photo-manifest.json").read_text())
        module = (ROOT / "src/shared/EmbeddedPhotoCatalog.luau").read_text()
        records = {}
        for identity, fields in re.findall(r'^\["([a-z_]+)"\] = \{ (.*) \},$', module, re.M):
            fields = re.sub(r'\["([A-Za-z0-9_]+)"\] = ', r'"\1": ', fields)
            records[identity] = json.loads("{" + fields + "}")
        self.assertGreaterEqual(len(records), 15)
        self.assertEqual(set(records), {row["identityId"] for row in manifest["portraits"]})
        for row in manifest["portraits"]:
            with self.subTest(identity=row["identityId"]):
                record = records[row["identityId"]]
                raw = base64.b64decode(record["rgbaBase64"], validate=True)
                self.assertEqual(len(raw), record["width"] * record["height"] * 4)
                self.assertEqual(hashlib.sha256(raw).hexdigest(), row["rgbaSHA256"])
                output = ROOT / row["outputFile"]
                self.assertEqual(hashlib.sha256(output.read_bytes()).hexdigest(), row["outputSHA256"])
                with Image.open(output) as photo:
                    self.assertEqual(photo.size, (256, 256))
                    self.assertEqual(photo.convert("RGBA").tobytes(), raw)
                self.assertEqual(hashlib.sha256((ROOT / row["sourceFile"]).read_bytes()).hexdigest(), row["sourceSHA256"])
                self.assertTrue(record["sourceVerified"])
                self.assertTrue(record["adultEraVerified"])
                self.assertTrue(record["ownerAuthorized"])
                self.assertEqual(record["sourceURL"], row["sourceURL"])
                self.assertEqual(record["attribution"], row["attribution"])
                self.assertIn(record["licenseURL"], record["attribution"])

    def test_preview_does_not_invent_upload_or_third_party_release_records(self):
        manifest = json.loads((ROOT / "assets/references/embedded-photo-manifest.json").read_text())
        for row in manifest["portraits"]:
            self.assertIs(row["studioPreviewOnly"], True)
            self.assertEqual(row["robloxAssetId"], 0)
            self.assertEqual(row["thirdPartyLikenessRelease"], "NotEstablished")
        production = json.loads((ROOT / "assets/characters/manifest.json").read_text())
        self.assertEqual(production["portraits"], [])


if __name__ == "__main__":
    unittest.main()
