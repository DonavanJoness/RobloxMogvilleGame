#!/usr/bin/env python3
"""Collect identity/image-license evidence from official Wikimedia APIs.

This helper never downloads portraits, approves likeness rights, assigns ages,
or changes candidate approval states. Keep the inherited HTTPS proxy and CA trust.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import time
import urllib.error
import urllib.parse
import urllib.request
import urllib.robotparser


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets/references/research-catalog.json"
USER_AGENT = "MogvilleReferenceAudit/1.0 (manual development research; metadata only)"
API_HOSTS = {"en.wikipedia.org", "commons.wikimedia.org"}


class EvidenceError(RuntimeError):
    pass


class Client:
    """One request per second, HTTPS verification and robots checks enabled."""

    def __init__(self) -> None:
        self.last_request = 0.0
        self.robots: dict[str, urllib.robotparser.RobotFileParser] = {}

    def _read(self, url: str) -> str:
        parsed = urllib.parse.urlsplit(url)
        if parsed.scheme != "https" or parsed.hostname not in API_HOSTS:
            raise EvidenceError("Unexpected API destination; request refused")
        remaining = 1.0 - (time.monotonic() - self.last_request)
        if remaining > 0:
            time.sleep(remaining)
        self.last_request = time.monotonic()
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        # urllib retains the inherited proxy and verified system TLS context.
        # A denied host is not retried through another host or transport.
        with urllib.request.urlopen(request, timeout=20) as response:
            if urllib.parse.urlsplit(response.url).hostname not in API_HOSTS:
                raise EvidenceError("Unexpected redirect destination")
            body = response.read(2_000_001)
            if len(body) > 2_000_000:
                raise EvidenceError("Metadata response exceeded size limit")
            return body.decode("utf-8")

    def query(self, host: str, parameters: dict[str, str]) -> tuple[str, dict]:
        parameters = {
            "action": "query", "format": "json", "formatversion": "2",
            "maxlag": "5", **parameters,
        }
        url = "https://" + host + "/w/api.php?" + urllib.parse.urlencode(parameters)
        if host not in self.robots:
            robots_url = "https://" + host + "/robots.txt"
            parser = urllib.robotparser.RobotFileParser(robots_url)
            parser.parse(self._read(robots_url).splitlines())
            self.robots[host] = parser
        parser = self.robots[host]
        if not parser.can_fetch(USER_AGENT, url):
            raise EvidenceError(f"robots.txt disallows this API URL on {host}")
        crawl_delay = parser.crawl_delay(USER_AGENT) or parser.crawl_delay("*")
        if crawl_delay:
            remaining = crawl_delay - (time.monotonic() - self.last_request)
            if remaining > 0:
                time.sleep(remaining)
        result = json.loads(self._read(url))
        if "error" in result:
            code = result["error"].get("code", "unknown")
            raise EvidenceError(f"MediaWiki API error {code}; request was not retried")
        return url, result


def collect(client: Client, candidate: dict) -> dict:
    result = {
        "schemaVersion": 1,
        "candidateId": candidate["candidateId"],
        "observedAtUTC": datetime.now(timezone.utc).isoformat(),
        "status": "Incomplete",
        "identityApproved": False,
        "adultStatusApproved": False,
        "commercialRightsApproved": False,
        "likenessApproved": False,
        "portraitDownloaded": False,
        "sources": [],
        "notes": [
            "API responses are source evidence for manual review, not approval.",
            "An image copyright license does not establish game likeness permission.",
            "No medical history, looksmaxxing affiliation or adult-era photo is inferred.",
        ],
    }
    title = candidate.get("encyclopediaTitle")
    if not title:
        result["status"] = "ManualIdentitySourceRequired"
        return result
    try:
        url, response = client.query("en.wikipedia.org", {
            "titles": title,
            "redirects": "1",
            "prop": "extracts|pageimages|info",
            "inprop": "url",
            "exintro": "1", "explaintext": "1",
            "piprop": "name|original",
        })
        pages = response.get("query", {}).get("pages", [])
        result["sources"].append({"apiURL": url, "response": response})
        if len(pages) != 1 or pages[0].get("missing"):
            result["status"] = "IdentityPageMissing"
            return result
        page = pages[0]
        result["identityReference"] = {
            "title": page.get("title"),
            "url": page.get("fullurl"),
            "intro": page.get("extract"),
        }
        file_name = page.get("pageimage")
        if not file_name:
            result["status"] = "IdentityEvidenceOnlyNoImage"
            return result
        url, response = client.query("commons.wikimedia.org", {
            "titles": "File:" + file_name,
            "prop": "imageinfo",
            "iiprop": "url|user|extmetadata",
            "iilimit": "1",
        })
        result["sources"].append({"apiURL": url, "response": response})
        pages = response.get("query", {}).get("pages", [])
        images = pages[0].get("imageinfo", []) if len(pages) == 1 else []
        if not images:
            result["status"] = "IdentityEvidenceOnlyNoCommonsImage"
            return result
        image = images[0]
        metadata = image.get("extmetadata", {})

        def field(name: str) -> str | None:
            return metadata.get(name, {}).get("value")

        result["imageReference"] = {
            "filename": file_name,
            "descriptionURL": image.get("descriptionurl"),
            "imageURLForReferenceOnly": image.get("url"),
            "uploaderNotNecessarilyPhotographer": image.get("user"),
            "artistMetadataHTML": field("Artist"),
            "creditMetadataHTML": field("Credit"),
            "licenseShortName": field("LicenseShortName"),
            "licenseURL": field("LicenseUrl"),
            "usageTerms": field("UsageTerms"),
            "attributionRequired": field("AttributionRequired"),
            "restrictions": field("Restrictions"),
            "permissionMetadataHTML": field("Permission"),
        }
        result["status"] = "EvidenceCollectedNeedsManualReview"
    except (urllib.error.URLError, TimeoutError, OSError, ValueError, EvidenceError) as error:
        result["status"] = "SourceAccessFailed"
        result["error"] = str(error)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate", action="append", dest="candidate_ids",
                        help="Candidate ID; repeat to collect several. Default: all named records.")
    parser.add_argument("--refresh", action="store_true",
                        help="Replace an existing evidence file; catalog approvals are never changed.")
    args = parser.parse_args()
    catalog = json.loads(CATALOG.read_text())
    candidates = catalog["candidates"]
    known_ids = {item["candidateId"] for item in candidates}
    if args.candidate_ids and set(args.candidate_ids) - known_ids:
        parser.error("Unknown candidate ID")
    selected = [item for item in candidates if (
        item["candidateId"] in args.candidate_ids if args.candidate_ids
        else item.get("candidateType") != "UnresolvedRequestedAlias"
    )]
    client = Client()
    failed = False
    for candidate in selected:
        candidate_id = candidate["candidateId"]
        if not re.fullmatch(r"[a-z0-9_]+", candidate_id):
            parser.error("Invalid candidate ID")
        output = ROOT / "assets/references/evidence" / (candidate_id + ".json")
        if output.exists() and not args.refresh:
            print(f"{candidate_id}: evidence exists; use --refresh to replace")
            failed = True
            continue
        evidence = collect(client, candidate)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n")
        print(f"{candidate_id}: {evidence['status']}")
        if evidence["status"] != "EvidenceCollectedNeedsManualReview":
            failed = True
        if evidence["status"] == "SourceAccessFailed":
            # A denied or unavailable shared host blocks the same following
            # calls. Stop rather than repeatedly making unchanged requests.
            break
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
