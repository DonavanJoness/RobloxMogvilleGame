"""Offline source-license and download boundaries for staged photo research."""
import hashlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("photo_research", ROOT / "tools/collect_photo_candidates.py")
research = importlib.util.module_from_spec(spec)
spec.loader.exec_module(research)

BIO_URL = "https://en.wikipedia.org/wiki/Test_Subject"
FILE_URL = "https://commons.wikimedia.org/wiki/File:Test_portrait.jpg"
IMAGE_URL = "https://upload.wikimedia.org/test-portrait.jpg"
CANDIDATE = {"candidateId": "test_subject", "displayName": "Synthetic Test Subject", "encyclopediaTitle": "Test Subject"}


class FakeReader:
    def __init__(self, photo, birth="1990-06-15", image=None):
        self.requests = []
        self.pages = {
            BIO_URL: f'<title>Test Subject</title><table class="infobox"><tr><td>'
                f'<span class="bday">{birth}</span>'
                '<img data-file-height="500" resource="./File:Test_portrait.jpg"></td></tr></table>'.encode(),
            FILE_URL: photo.encode(),
            IMAGE_URL: image,
        }

    def read(self, url, image=False):
        self.requests.append((url, image))
        if url not in self.pages or self.pages[url] is None:
            raise AssertionError(f"Unexpected offline request: {url}")
        return self.pages[url]


def photo_html(license_url="https://creativecommons.org/licenses/by-sa/4.0/", author="Synthetic Photographer", date="2020-06-15", template=True):
    license_markup = '<div class="licensetpl"><span class="licensetpl_short">CC test</span>' \
        f'<span class="licensetpl_link">{license_url}</span></div>' if template else ""
    return f'''<table>
        <tr><td id="fileinfotpl_desc">Description</td><td>Synthetic portrait fixture</td></tr>
        <tr><td id="fileinfotpl_aut">Author</td><td>{author}</td></tr>
        <tr><td id="fileinfotpl_date">Date</td><td>{date}</td></tr>
        <tr><td id="fileinfotpl_src">Source</td><td>Offline test fixture</td></tr>
        </table>{license_markup}
        <div class="fullImageLink"><a href="{IMAGE_URL}">Original image</a></div>
        <footer>Page text: <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0</a></footer>'''


class PhotoResearchTests(unittest.TestCase):
    def test_page_footer_license_never_establishes_photo_rights(self):
        reader = FakeReader(photo_html(template=False))
        result = research.collect(reader, CANDIDATE, download=True)
        self.assertEqual(result["licenses"], [])
        self.assertEqual(result["copyrightStatus"], "Unresolved")
        self.assertIsNone(result["downloadedFile"])
        self.assertNotIn((IMAGE_URL, True), reader.requests)

    def test_noncommercial_no_derivatives_and_missing_credit_block_download(self):
        for license_url, author in (
            ("https://creativecommons.org/licenses/by-nc/4.0/", "Photographer"),
            ("https://creativecommons.org/licenses/by-nd/4.0/", "Photographer"),
            ("https://creativecommons.org/licenses/by-nc-sa/4.0/", "Photographer"),
            ("https://creativecommons.org/licenses/by/4.0/", ""),
        ):
            with self.subTest(license_url=license_url, author=author):
                reader = FakeReader(photo_html(license_url=license_url, author=author))
                result = research.collect(reader, CANDIDATE, download=True)
                self.assertEqual(result["copyrightStatus"], "Unresolved")
                self.assertIsNone(result["downloadedFile"])
                self.assertNotIn((IMAGE_URL, True), reader.requests)

    def test_minor_or_undated_photo_never_reaches_image_download(self):
        for photo_date in ("2007-06-15", "2008-12-31", "Unknown"):
            with self.subTest(photo_date=photo_date):
                reader = FakeReader(photo_html(date=photo_date))
                result = research.collect(reader, CANDIDATE, download=True)
                self.assertFalse(result["adultEraConservativeCheck"])
                self.assertIsNone(result["downloadedFile"])
                self.assertNotIn((IMAGE_URL, True), reader.requests)

    def test_licensed_image_retains_exact_bytes_and_remains_disabled(self):
        buffer = io.BytesIO()
        # Synthetic color pixels exist only in a temporary test directory.
        Image.new("RGB", (240, 320), (12, 34, 56)).save(buffer, format="JPEG", comment=b"preserve source bytes")
        source_bytes = buffer.getvalue()
        for license_url in (
            "https://creativecommons.org/licenses/by/4.0/",
            "https://creativecommons.org/licenses/by-sa/2.0/",
            "https://creativecommons.org/publicdomain/zero/1.0/",
        ):
            with self.subTest(license_url=license_url), tempfile.TemporaryDirectory() as directory:
                reader = FakeReader(photo_html(license_url=license_url), image=source_bytes)
                with patch.object(research, "ROOT", Path(directory)):
                    result = research.collect(reader, CANDIDATE, download=True)
                self.assertEqual(result["photoStatus"], "DownloadedForCopyrightAndVisualReviewOnly")
                self.assertEqual((Path(directory) / result["downloadedFile"]).read_bytes(), source_bytes)
                self.assertEqual(result["sha256"], hashlib.sha256(source_bytes).hexdigest())
                self.assertEqual(result["dimensions"], [240, 320])
                self.assertEqual(result["selectedLicense"]["url"], license_url)
                self.assertFalse(result["gameEnabled"])
                self.assertEqual(result["robloxAssetId"], 0)
                self.assertEqual(result["likenessStatus"], "NotClearedForGame")


if __name__ == "__main__":
    unittest.main()
