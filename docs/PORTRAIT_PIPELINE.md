# V3 authentic-photo pipeline

V3 no longer generates or ships fictional human portrait substitutes. The original V2 face PNGs have been retired. `assets/characters/manifest.json` currently has **zero approved photographs**, and the game displays neutral unresolved panels. Legacy fictional IDs remain a labelled test collection only; no legacy image override can be presented as a real-person photo.

## Runtime data

- `MoggerPortraitRegistry` enforces identity, authentic adult-era photography, copyright/commercial-use/likeness records and actual upload status before making a real-person card obtainable.
- `RealMoggers` is generated from the provisional research catalog and approved manifest records. Its 28 current entries are pending; the three ambiguous aliases remain unresolved. All current asset IDs are zero.
- `CharacterVisuals` provides the same metadata to card UI, reveals, inspection, battle and plot displays. Positive IDs without the required approval fields cannot display as real photographs.
- Stable character form IDs, base identities and mutations remain separate. Multiple photographed Young/Classic/Prime/Ascended variants can be registered independently. An Ascended frame is a UI effect around an authentic image, not an invented photograph.

## Register an approved photograph

First verify the public adult person's identity and exact adult-era photograph, and record the photographer/license, commercial game use, attribution and applicable likeness permission. Add the exact identity to the research catalog. Do not guess Kaysh, Hexum or Chad Jaw from an ambiguous label.

Add an entry to `assets/characters/manifest.json` with:

| Field | Required record |
| --- | --- |
| `characterId` | `real_<identityId>_<variant in lowercase>` |
| `identityId`, `variant` | Exact verified catalog ID; Young, Classic, Prime or Ascended |
| `referenceType`, `containsRealPerson` | `RealPerson`, `true` |
| `identityVerified`, `authenticPhotograph`, `adultEraVerified` | Explicit reviewed `true` records |
| `sourceFile`, `outputFile` | Distinct PNG/JPEG source and PNG output paths inside `assets/characters/` |
| `creator`, `license`, `sourceURL`, `attribution` | Exact original-photo source and credit requirements |
| `approvalStatus`, `copyrightPermission`, `commercialUseAllowed` | `approved`, `true`, `true`, with `copyrightEvidence` |
| `likenessPermission`, `likenessEvidence` | `granted` and documented authorization for the intended use |
| `robloxAssetId`, `uploadStatus`, `uploadEvidence` | Initially zero / not-uploaded; actual owner upload record required later |
| `requestedEnabled` | `true` only after the owner is ready to enable the fully cleared form |
| `modelKey` | Optional per-form reviewed R15 template key; no fabricated model ID |

These declarations are owner review records; the script cannot establish legal permission or verify an online upload. Never mark a photo cleared just because it is publicly visible or available through Commons.

## Prepare and upload

```bash
python3 -m pip install -r tools/requirements-assets.txt
python3 tools/portraits.py
```

This validates local records, preserves the source, prepares consistent 512×512 RGB PNGs, removes output metadata, records hashes, and generates portrait/real-roster mappings. It never downloads or uploads images. `--create-placeholders` explicitly refuses to create replacement faces.

Import cleared outputs through your own Studio Asset Manager or Creator Dashboard. Wait for moderation and test the actual image/content ID in an ImageLabel. For a Decal, do not assume the wrapper ID is the image content ID. Record the actual ID and successful upload evidence in the manifest, regenerate, test and build. No Roblox upload credentials or tools were provided here, and no upload was performed.

A missing or failed image remains a neutral PHOTO NOT SUPPLIED panel. Gameplay test IDs are not renamed to real people, and real-person eligibility stays closed until all gates pass.

## Research access

The saved draft preserves earlier research hosts and adds `www.roblox.com` and `create.roblox.com` for the supplied reference/Creator Store. Review/save those environment settings and publish the updated environment to apply them. This task did not publish the environment. After access works, `tools/research_candidates.py` can collect rate-limited official Wikimedia metadata for manual review; it never grants approval or downloads portraits automatically.
