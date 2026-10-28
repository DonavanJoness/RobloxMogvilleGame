# Character art, forms and approval workflow

## Delivered assets

`assets/characters/manifest.json` contains **24 approved original geometric placeholders**, one per playable form. Their 512×512 PNGs live in `placeholders/` (sources) and `roblox/` (prepared outputs); they depict fictional shapes, not research candidates. `processed-manifest.json` records hashes and dimensions. **No portrait has been uploaded to Roblox**, so every generated asset mapping is zero. The game currently displays its richer procedural UI/world portraits until actual image assets are registered.

Research is separate: `assets/references/research-catalog.json` and `.md` hold **25 provisional named candidates plus two unresolved requested labels**. Identity/source verification was blocked by the environment's proxy. Proposed URLs are explicitly unfetched leads, not citations supporting verified identities or image rights. All photographer, license and likeness fields remain unresolved; zero real-person portraits are production-approved. Per-candidate metadata directories contain no photographs.

The real-person catalog must never be copied wholesale into the playable roster. “Kaysh” and “Post-Surgery Hexum” have no verified identity mapping. No medical claim, adult-era photo, looksmaxxing affiliation or creator account is inferred from an ambiguous label.

## Identity, form and mutation

`CharacterCatalog.luau` defines original identities and forms. A stable `characterId` identifies one collectible form; `identityId` groups that identity's forms. The twelve original IDs and all their numerical stats remain unchanged. New Young/Classic/Prime/Ascended forms have their own rarity and stats. Golden/Diamond/etc. remain independent mutation results and are never substituted for a form.

Version-1 profiles remain compatible: saving/loading rederives `identityId` and `form` from the authoritative stable ID rather than trusting old/client-provided metadata. New acquisitions include those fields explicitly. Disabling a form removes it from new gacha odds while preserving existing ownership, income and display usage. `mutationEligible=false` forces Normal for that form and renormalizes correctly. Individual odds continue to include each form and mutation.

## Local preparation

```bash
python3 -m pip install -r tools/requirements-assets.txt
python3 tools/portraits.py
```

The preparation command validates approval records, normalizes approved local PNG/JPEG images to square 512×512 RGB PNGs, preserves source bytes, strips metadata from outputs, records hashes, and generates `src/shared/PortraitAssets.luau`. It performs **no network downloads and no Roblox uploads**. `--create-placeholders` creates missing original geometric icon sources without replacing existing artwork or owner manifest entries.

For a new approved source, add an entry with a stable playable `characterId` and:

- `sourceFile` and `outputFile` under `assets/characters/`, with different paths;
- `creator`, exact `license`, `copyrightPermission=true`, `approvalStatus="approved"`;
- `projectOriginal=false` for third-party material, with `sourceURL`, `copyrightEvidence`, `commercialUseAllowed=true`, and required `attribution`;
- `containsRealPerson=true` for a recognizable person, plus separate `likenessPermission="granted"` and `likenessEvidence` for the intended game use;
- `robloxAssetId=0` and `uploadStatus="not-uploaded"` until the owner has actually uploaded it.

Permission fields are owner-supplied review records; this script does not adjudicate legal rights or independently validate an uploaded asset. Unapproved images belong outside production assets. Do not mark an online/social photo approved because it is publicly visible. Image copyright permission and permission to use a recognizable person as a game character are separate questions.

## Upload into your Roblox experience

1. Review each image and its rights/attribution record, including platform suitability. For approved photographs choose an adult-era portrait of the verified adult public figure.
2. In your private test experience, open Roblox Studio's **Asset Manager** and import the prepared files from `assets/characters/roblox/` using the image import/bulk-import action available in your Studio version. Creator Dashboard's image/decal upload workflow is another owner-controlled option. No authenticated Roblox upload capability was provided to this task.
3. Wait for upload/moderation completion. Ensure the asset is usable by the account/group that owns the experience.
4. Copy the **image/content asset ID usable by an ImageLabel** from the uploaded image entry. If uploading as a Decal, use its image content/Texture ID rather than assuming a wrapper ID is the display image. Test `rbxassetid://<actual ID>` in an ImageLabel in Studio.
5. Enter that actual numeric ID in the matching manifest entry; set `uploadStatus="uploaded"` and record the owner upload page or other successful-upload evidence in `uploadEvidence`. IDs in documentation/tests are never production assignments.
6. Run `python3 tools/portraits.py`, the tests, and `python3 tools/build.py`. The generated `PortraitAssets` mapping is consumed by `CharacterVisuals.get(characterId)` for reveals, inventory, inspections, battles and plot cards.
7. Test with two clients and on mobile. Confirm visibility, crop, credits, moderation/access failures and fallbacks before release.

Roblox UI cannot read arbitrary local PNGs or website image URLs at runtime. If an ID is zero, malformed, unavailable or fails loading, the original procedural portrait remains visible; gameplay stays enabled. Imported images are visual data only and never grant character ownership or stats.

## Resume the source research

The draft adds only `en.wikipedia.org`, `commons.wikimedia.org`, `upload.wikimedia.org`, `www.wikidata.org`, `models.com`, and `knowyourmeme.com`, preserving the existing package-manager preset. Draft saving does not apply or publish networking. Review/save the network changes in environment settings and publish the updated environment when ready.

After access is applied:

```bash
python3 tools/research_candidates.py --candidate henry_cavill
# Then select further candidate IDs for a bounded, rate-limited metadata audit.
```

The helper respects robots checks, inherited proxy/TLS and one-request-per-second throttling, records API identity/image-license evidence, and stops on denied/unavailable shared hosts. It never downloads photos or automatically approves candidates, ages, licenses or likenesses. Review evidence manually and update the catalog accurately. A page image may be absent, group-based, unsuitable, copyrighted or subject to likeness restrictions even when a Commons record exists.
