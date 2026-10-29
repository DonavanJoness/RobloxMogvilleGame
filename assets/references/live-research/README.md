# Authentic-photo source research

Public HTML access now works. These records supersede the earlier network-blocked research status in `../source-access.json`, which remains a historical audit. The environment's network access was applied by the owner; this work did not publish an environment or a Roblox experience.

The source collector respects each site's robots rules and uses inherited HTTPS proxy/TLS settings. Wikimedia `/w/api.php` is disallowed for this bot; research used permitted biography, category and individual file HTML. Successful pages, dated adult-era photo evidence, file-specific licenses, exact original hashes and visual framing reviews are recorded per person. A page footer's license is never used as an image license.

See [results and blockers](../research-catalog.md), the [manifest](../photo-review-manifest.json), and [photo credits](../photo-review/CREDITS.md). `requested-identities.json` contains the separate research for the five requested aliases/project references. A failed exact URL is a limited negative result, not proof that no person or photograph exists.

The remaining model-photo lookups were also limited by Commons robots rules: `Special:Search` and `Special:MediaSearch` are disallowed for this bot. Those search pages were not fetched and no alternate route was used. Unresolved records include the exact lookup limits; they do not claim that all possible licensed sources were exhausted.

Source review found and corrected a David Gandy crop/original license mismatch and replaced a visibly patched Baptiste Giabiconi source with another licensed photograph. An Alton Mason screenshot's external-source license had not been reviewed by Commons; it is excluded. Held bytes and full-page caches remain in ignored `.tools/` and are not part of the delivery.

Reproduce research only when needed:

```bash
python3 -m pip install -r tools/requirements-assets.txt -r tools/requirements-research.txt
python3 tools/collect_photo_candidates.py --candidate henry_cavill --download-review
```

The collector overwrites the selected person's previous record and requires a new manual source and visual review. It does not automatically detect every conflicting license, permission warning or upstream edit; inspect the file history and original source. Only after those checks, record `visualReview.reviewed=true` and `redistributionReview.status="OpenLicenseSourceReviewed"`. Otherwise hold the photo outside the deliverable.

```bash
python3 tools/package_photo_review.py
```

Packaging validates the reviewed bytes and writes a deterministic ZIP with images, a local HTML gallery, individual credits and evidence. It updates research metadata only. There are zero approved production photo records, zero Roblox uploads, and zero new character enablements. Copyright-source evidence does not establish endorsement or a blanket likeness release.
