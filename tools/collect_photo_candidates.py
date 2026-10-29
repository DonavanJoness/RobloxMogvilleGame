#!/usr/bin/env python3
"""Audit permitted public HTML, then stage openly licensed adult portraits for review.

No MediaWiki APIs (robots-disallowed), login, proxy bypass, Roblox upload or game enablement.
"""
import argparse
from datetime import date, datetime, timezone
import fcntl
import hashlib
import json
from pathlib import Path
import re
import sys
import time
import urllib.parse
import urllib.request
import urllib.robotparser

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".tools/research-libs"))
from bs4 import BeautifulSoup

UA = "MogvillePhotoResearch/1.0 (public source and license audit)"
CACHE = ROOT / ".tools/photo-research-cache"
OUTPUT = ROOT / "assets/references/live-research"
HOSTS = {"en.wikipedia.org", "commons.wikimedia.org", "upload.wikimedia.org", "thumb.wikimedia.org"}


class PublicReader:
    def __init__(self): self.robots = {}

    def _request(self, url, limit):
        host = urllib.parse.urlsplit(url).hostname
        CACHE.mkdir(parents=True, exist_ok=True)
        key = hashlib.sha256(url.encode()).hexdigest()
        target = CACHE / key
        if target.exists(): return target.read_bytes()
        # Shared across processes: never exceed one fresh request/second to a host.
        with (CACHE / (host + ".lock")).open("a+") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            lock.seek(0)
            previous = float(lock.read() or "0")
            time.sleep(max(0, 1 - (time.time() - previous)))
            lock.seek(0); lock.truncate(); lock.write(str(time.time())); lock.flush()
            request = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(request, timeout=25) as response:
                final = urllib.parse.urlsplit(response.url)
                if final.scheme != "https" or final.hostname not in HOSTS:
                    raise ValueError("Unexpected redirect destination")
                body = response.read(limit + 1)
                if len(body) > limit: raise ValueError("Response exceeds review size limit")
            target.write_bytes(body)
        return body

    def read(self, url, image=False):
        parsed = urllib.parse.urlsplit(url)
        if parsed.scheme != "https" or parsed.hostname not in HOSTS:
            raise ValueError("Unapproved research destination")
        if parsed.hostname not in self.robots:
            robots_url = "https://" + parsed.hostname + "/robots.txt"
            parser = urllib.robotparser.RobotFileParser(robots_url)
            parser.parse(self._request(robots_url, 2000000).decode().splitlines())
            self.robots[parsed.hostname] = parser
        if not self.robots[parsed.hostname].can_fetch(UA, url):
            raise ValueError("robots.txt does not permit this path")
        return self._request(url, 20 * 1024 * 1024 if image else 5 * 1024 * 1024)


def field(soup, identity):
    node = soup.find(id=identity)
    if not node: return None
    cell = node.find_next_sibling("td")
    return (cell or node.parent).get_text(" ", strip=True)[:2500]


def earliest_year(value):
    match = re.search(r"\b(19\d{2}|20\d{2})\b", value or "")
    return int(match.group()) if match else None


def collect(reader, candidate, download=False):
    result = {"candidateId": candidate["candidateId"], "displayName": candidate["displayName"],
        "observedAtUTC": datetime.now(timezone.utc).isoformat(), "identityStatus": "Unverified",
        "photoStatus": "Unavailable", "copyrightStatus": "Unresolved", "likenessStatus": "NotClearedForGame",
        "robloxAssetId": 0, "gameEnabled": False, "sources": [], "downloadedFile": None}
    title = candidate.get("encyclopediaTitle")
    if not title:
        result["blocker"] = "Exact public identity source needs manual verification."
        return result
    url = "https://en.wikipedia.org/wiki/" + urllib.parse.quote(title.replace(" ", "_"), safe="_()'")
    try:
        soup = BeautifulSoup(reader.read(url), "html.parser")
        result["sources"].append(url)
        result["identityPageTitle"] = soup.title.get_text(" ", strip=True) if soup.title else ""
        info = soup.select_one(".infobox")
        if not info:
            result["blocker"] = "No usable biographical infobox found; identity requires manual review."
            return result
        born = info.select_one(".bday")
        result["birthDate"] = born.get_text(strip=True) if born else None
        result["identityExcerpt"] = info.get_text(" ", strip=True)[:700]
        result["identityStatus"] = "PublicBiographyLocatedNeedsSourceReview"
        images = [im for im in info.select("img") if im.get("data-file-type") != "drawing" and int(im.get("data-file-height", 1)) >= 200]
        if not images:
            result["blocker"] = "No portrait image in the public biography infobox."
            return result
        image = images[0]
        resource = image.get("resource") or (image.find_parent("a") or {}).get("href", "")
        resource = urllib.parse.unquote(resource)
        if "File:" not in resource: raise ValueError("Image file source is unresolved")
        filename = resource.split("File:", 1)[1].split("#")[0]
        source = "https://commons.wikimedia.org/wiki/" + urllib.parse.quote("File:" + filename, safe=":_()'")
        photo = BeautifulSoup(reader.read(source), "html.parser")
        result["sources"].append(source)
        result["fileDescriptionURL"] = source
        result["filename"] = filename
        result["description"] = field(photo, "fileinfotpl_desc")
        result["photographer"] = field(photo, "fileinfotpl_aut")
        result["photoDate"] = field(photo, "fileinfotpl_date")
        result["originalSource"] = field(photo, "fileinfotpl_src")
        licenses = []
        for template in photo.select(".licensetpl"):
            label, link = template.select_one(".licensetpl_short"), template.select_one(".licensetpl_link")
            if label and link:
                license_url = link.get_text(" ", strip=True)
                licenses.append({"name": label.get_text(" ", strip=True), "url": license_url,
                    "terms": template.get_text(" ", strip=True)[:1800]})
        result["licenses"] = licenses
        eligible = next((lic for lic in licenses if re.fullmatch(r"https?://creativecommons\.org/(licenses/(by|by-sa)/[\d.]+/?|publicdomain/zero/1\.0/?)", lic["url"])), None)
        if not eligible or not result["photographer"]:
            result["blocker"] = "A specific commercial-redistribution photo license and photographer were not established."
            return result
        result["copyrightStatus"] = "OpenLicenseLocatedNeedsReview"
        result["selectedLicense"] = eligible
        result["attribution"] = f'{filename} — {result["photographer"]}; {eligible["name"]}; {source}; {eligible["url"]}. Original file retained; no changes by MOGVILLE.'
        birth_year = earliest_year(result["birthDate"])
        photo_year = earliest_year(result["photoDate"])
        result["adultEraConservativeCheck"] = bool(birth_year and photo_year and photo_year - birth_year - 1 >= 18)
        original = photo.select_one(".fullImageLink a[href]")
        if not original: raise ValueError("No original image link found")
        image_url = urllib.parse.urljoin(source, original["href"])
        result["imageURL"] = image_url
        if not result["adultEraConservativeCheck"]:
            result["blocker"] = "Adult-era photograph needs date/age review; no download performed."
            return result
        result["photoStatus"] = "OpenLicenseAdultCandidateNeedsVisualReview"
        if download:
            raw = reader.read(image_url, image=True)
            from PIL import Image
            import io
            with Image.open(io.BytesIO(raw)) as im:
                result["dimensions"] = list(im.size)
                extension = ".jpg" if im.format == "JPEG" else ".png" if im.format == "PNG" else None
                if not extension: raise ValueError("Unsupported portrait file format")
                if min(im.size) < 200: raise ValueError("Portrait too small for review")
            target = ROOT / "assets/references/photo-review" / (candidate["candidateId"] + extension)
            target.parent.mkdir(parents=True, exist_ok=True); target.write_bytes(raw)
            result["downloadedFile"] = target.relative_to(ROOT).as_posix()
            result["sha256"] = hashlib.sha256(raw).hexdigest()
            result["photoStatus"] = "DownloadedForCopyrightAndVisualReviewOnly"
    except Exception as error:
        result["blocker"] = type(error).__name__ + ": " + str(error)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate", action="append")
    parser.add_argument("--download-review", action="store_true")
    args = parser.parse_args()
    catalog = json.loads((ROOT / "assets/references/research-catalog.json").read_text())
    selected = [r for r in catalog["candidates"] if not args.candidate or r["candidateId"] in args.candidate]
    OUTPUT.mkdir(parents=True, exist_ok=True)
    reader = PublicReader()
    for candidate in selected:
        record = collect(reader, candidate, args.download_review)
        (OUTPUT / (candidate["candidateId"] + ".json")).write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n")
        print(candidate["candidateId"], record["photoStatus"], record.get("blocker", ""), flush=True)


if __name__ == "__main__": main()
