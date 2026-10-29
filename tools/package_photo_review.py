#!/usr/bin/env python3
"""Package source-reviewed original photographs and their credits; never enable game assets."""
import hashlib
import html
import json
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
REFERENCES = ROOT / "assets/references"
BLOCKERS = {
    "clavicular": "Public alias corroborated; no adult-era photo with documented reuse rights selected.",
    "ernest_khalimov": "GigaChad project copyright permission missing; iconic edited artwork is not an unaltered portrait.",
    "kaysh_unresolved": "Exact public identity/profile and authorized photograph needed.",
    "post_surgery_hexum_unresolved": "Exact requested person/variant and authorized reference photo remain unresolved.",
    "chad_jaw_unresolved": "Exact public identity/profile and authorized photograph needed.",
    "mathias_lauridsen": "Biography found; no licensed photo located in the checked public sources.",
    "garrett_neff": "Biography found; no licensed photo located in the checked public sources.",
    "kit_butler": "Checked biography/category URLs returned 404; exact source or authorized photo needed.",
    "clement_chabernaud": "Biography found; no licensed photo located in the checked public sources.",
}


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def eligible(record):
    """Only explicitly reviewed, licensed, unchanged adult-photo files enter the archive."""
    if not record.get("downloadedFile"):
        return False
    if record.get("redistributionReview", {}).get("status") != "OpenLicenseSourceReviewed":
        return False
    if record.get("visualReview", {}).get("reviewed") is not True:
        raise ValueError("Source-reviewed photo requires visual review: " + record["candidateId"])
    if record.get("adultEraConservativeCheck") is not True:
        raise ValueError("Adult-era date not established: " + record["candidateId"])
    license_url = record.get("selectedLicense", {}).get("url", "")
    if not re.fullmatch(r"https?://creativecommons\.org/(licenses/(by|by-sa)/[\d.]+/?|publicdomain/zero/1\.0/?)", license_url):
        raise ValueError("Unsupported review license: " + record["candidateId"])
    source = (ROOT / record["downloadedFile"]).resolve()
    if not source.is_relative_to((REFERENCES / "photo-review").resolve()):
        raise ValueError("Photo outside review folder")
    if hashlib.sha256(source.read_bytes()).hexdigest() != record.get("sha256"):
        raise ValueError("Photo changed after source review: " + record["candidateId"])
    if record.get("gameEnabled") is not False or record.get("robloxAssetId") != 0:
        raise ValueError("Review records must remain separate from production")
    return True


def build():
    catalog_path = REFERENCES / "research-catalog.json"
    catalog = json.loads(catalog_path.read_text())
    identity_path = REFERENCES / "live-research/requested-identities.json"
    aliases = {r["candidateId"]: r for r in json.loads(identity_path.read_text())["records"]}
    records, photos = [], []
    for candidate in catalog["candidates"]:
        key = candidate["candidateId"]
        path = REFERENCES / "live-research" / (key + ".json")
        record = json.loads(path.read_text()) if path.exists() else aliases.get(key)
        if not record:
            raise ValueError("Missing research result: " + key)
        ready = eligible(record)
        if ready:
            photos.append(record)
        evidence = path.relative_to(ROOT).as_posix() if path.exists() else identity_path.relative_to(ROOT).as_posix()
        source_rows = record.get("sources", [])
        sources = [r if isinstance(r, str) else r["url"] for r in source_rows
                   if isinstance(r, str) or r.get("httpStatus") == 200]
        blocker = BLOCKERS.get(key, record.get("blocker"))
        if not ready and not blocker:
            blocker = "; ".join(record.get("notes", [])) or record.get("photoStatus", "Source review incomplete")
        row = {
            "candidateId": key, "displayName": candidate["displayName"],
            "reviewPhotoFile": record.get("downloadedFile") if ready else None,
            "status": "SourceReviewedPhotoCollected" if ready else record.get("photoStatus", "Unavailable"),
            "blocker": None if ready else blocker, "evidence": evidence,
            "sources": sources, "gameEnabled": False, "robloxAssetId": 0,
        }
        records.append(row)
        candidate.update({
            "sourceURLStatus": "FetchedForSourceReview" if sources else "CheckedNoMatchingSourceLocated",
            "verifiedSourceURLs": sources,
            "identityStatus": record.get("identityStatus", "Unresolved"),
            "adultStatus": "AdultEraSourceDatesReviewed" if ready else "NoApprovedAdultPortrait",
            "researchStatus": row["status"], "sourceAccess": "PublicHTMLResearchPerformed",
            "evidenceRef": evidence, "photographer": record.get("photographer"),
            "license": record.get("selectedLicense", {}).get("name"),
            "licenseURL": record.get("selectedLicense", {}).get("url"),
            "commercialRights": "Source license permits commercial copyright reuse subject to its conditions; game-likeness rights remain unresolved." if ready else None,
            "likenessStatus": "NeedsApproval", "portraitStatus": "ReviewOnlyNotGameApproved" if ready else row["status"],
            "portraitFile": None, "reviewPhotoFile": row["reviewPhotoFile"], "enabled": False,
        })
        if sources and candidate.get("sourceURL") not in sources:
            candidate["sourceURL"] = sources[0]
        candidate["notes"] = [n for n in candidate.get("notes", []) if not n.startswith("Source content was not retrieved.")]
        metadata = ROOT / "assets/characters" / key / "metadata.json"
        if metadata.exists():
            data = json.loads(metadata.read_text())
            for field in ("sourceURL", "sourceURLStatus", "photographer", "license", "commercialRights", "likenessStatus", "portraitFile", "notes", "enabled"):
                data[field] = candidate.get(field)
            data.update(status="ReviewOnlyNotGameApproved" if ready else row["status"], reviewPhotoFile=row["reviewPhotoFile"], reviewEvidence=evidence)
            dump(metadata, data)

    catalog.update(status="SourceResearchCompletedWithUnresolvedReferences", licensedPortraits=len(photos),
                   reviewedPhotoFiles=len(photos), productionPortraits=0, clearedGameLikenesses=0,
                   productionUseAllowed=False, sourceAccessEvidence="assets/references/live-research/README.md")
    catalog["countDefinitions"] = {"licensedPortraits": "Original review photos with an image-specific open copyright license and reviewed source; not game approval.",
                                   "verifiedCandidates": "Production-verified identities; remains zero until full production clearance."}
    dump(catalog_path, catalog)
    manifest = {"schemaVersion": 1, "scope": "Source-reviewed photographs for owner review; no game upload or enablement.",
                "requestedReferences": len(records), "includedPhotoFiles": len(photos),
                "unresolvedReferences": len(records) - len(photos), "productionApproved": 0,
                "records": records}
    dump(REFERENCES / "photo-review-manifest.json", manifest)

    intro = f"""# MOGVILLE authentic-photo review pack

This pack contains **{len(photos)} original photo files** for {len(records)} requested references. The other **{len(records) - len(photos)} references remain unresolved**; see the table below. Photographs are collected for review, with each file's source, author, exact copyright license and date evidence. No generated faces or substitute identities are included.

The selected source files are unchanged by MOGVILLE. Some are upstream crops, retouches or video stills; each evidence record documents known changes and quality limits. Source captions identify the subject; visual review checks framing and quality, without biometric identity matching. These records document the sources' license claims, not an independent legal warranty.

Keep `CREDITS.md` with the photos. Credit each photographer and source, link the specified license, and state any later changes. For BY-SA images, adaptations must follow the indicated ShareAlike license. These licenses do not imply endorsement or provide a blanket publicity/model release. Third-party images retain their individual licenses.

**Game status:** zero Roblox uploads and zero newly enabled characters. Applicable likeness authorization, platform upload/moderation and in-game display checks remain. This archive is separate from `assets/characters/manifest.json`; collecting it does not clear or enable a game card.

## Results

| Requested reference | Included review photo | Remaining issue |
| --- | --- | --- |
"""
    table = []
    for row in records:
        issue = "Game-likeness review and actual Roblox upload remain" if row["reviewPhotoFile"] else row["blocker"]
        table.append(f'| {row["displayName"]} | {Path(row["reviewPhotoFile"]).name if row["reviewPhotoFile"] else "—"} | {(issue or "Unresolved").replace(chr(10), " ").replace("|", ";")} |')
    readme = intro + "\n".join(table) + "\n\nIndividual evidence is in `live-research/`; machine-readable results are in `photo-review-manifest.json`.\n"
    (REFERENCES / "research-catalog.md").write_text(readme)
    (REFERENCES / "photo-review/README.md").write_text(readme)
    credits = "# Photo credits and license notices\n\nRetain this file with redistributed photographs. No endorsement by the depicted people or photographers is claimed. The archive retains each source file unchanged by MOGVILLE. Known upstream changes are described below.\n\n"
    for record in photos:
        visual = record["visualReview"]
        credits += f'## {record["displayName"]} — {Path(record["downloadedFile"]).name}\n\n{record["attribution"]}\n\n'
        credits += f'Photo date: {record.get("photoDate")}. Source dimensions: {record.get("dimensions")}. SHA-256: `{record["sha256"]}`.\n\n'
        credits += record["selectedLicense"].get("terms", "") + "\n\n"
        credits += "Review: " + " ".join(value for value in (visual.get("findings"), visual.get("upstreamChanges")) if value) + "\n\n"
    (REFERENCES / "photo-review/CREDITS.md").write_text(credits.rstrip() + "\n")
    cards = []
    for record in photos:
        esc = html.escape
        cards.append(f'<article><img src="{esc(Path(record["downloadedFile"]).name)}" alt="Source-labelled photograph: {esc(record["displayName"])}" loading="lazy">'
                     f'<h2>{esc(record["displayName"])}</h2><p>{esc(record["photographer"])}</p>'
                     f'<p><a href="{esc(record["fileDescriptionURL"])}">Original source</a> · '
                     f'<a href="{esc(record["selectedLicense"]["url"])}">{esc(record["selectedLicense"]["name"])}</a></p>'
                     f'<p>{esc(record["visualReview"].get("findings", ""))}</p></article>')
    gallery = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">' \
              '<title>MOGVILLE photo review</title><style>body{font:16px system-ui;margin:2rem;background:#101522;color:#eee}' \
              'a{color:#a8d8ff}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:1rem}' \
              'article{padding:1rem;background:#20283a;border-radius:12px}img{width:100%;height:340px;object-fit:contain}' \
              'h2{font-size:1.2rem}p{line-height:1.5}</style><h1>MOGVILLE photo review</h1>' \
              f'<p>{len(photos)} source-reviewed originals. Read <a href="README.md">results and remaining blockers</a> and '
    gallery += '<a href="CREDITS.md">required credits</a>. No Roblox uploads or game enablements.</p><main>' + ''.join(cards) + '</main></html>\n'
    (REFERENCES / "photo-review/index.html").write_text(gallery)
    archive_path = ROOT / "downloads/Mogville-photo-review.zip"
    paths = [REFERENCES / "photo-review-manifest.json", *sorted((REFERENCES / "live-research").glob("*.json")),
             *sorted((REFERENCES / "live-research").glob("*.md"))]
    with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as archive:
        def add(path, name, content=None):
            info = zipfile.ZipInfo(name, (2026, 10, 28, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes() if content is None else content.encode())
        for name in ("README.md", "CREDITS.md", "index.html"):
            content = readme.replace('`live-research/`', '`evidence/live-research/`').replace('`photo-review-manifest.json`', '`evidence/photo-review-manifest.json`') if name == "README.md" else None
            add(REFERENCES / "photo-review" / name, name, content)
        for record in photos:
            add(ROOT / record["downloadedFile"], Path(record["downloadedFile"]).name)
        for path in paths:
            content = None
            if path == REFERENCES / "live-research/README.md":
                content = path.read_text().replace('(../research-catalog.md)', '(../../README.md)').replace('(../photo-review/CREDITS.md)', '(../../CREDITS.md)')
            add(path, "evidence/" + path.relative_to(REFERENCES).as_posix(), content)
    print(f"Packaged {len(photos)} unchanged source-reviewed photos; {len(records)-len(photos)} unresolved references; zero production enablements.")


if __name__ == "__main__":
    build()
