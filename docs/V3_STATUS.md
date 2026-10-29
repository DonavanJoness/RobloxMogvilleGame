# MOGVILLE V3 — card-layout preview and asset acceptance

**V3 is not visually acceptance-complete.** This delivery implements the card UI, layout changes and reviewed-asset integration. Fifteen real photo files now have reviewed source/license/date evidence in a separate [photo review pack](../assets/references/photo-review/README.md); thirteen requested references remain unresolved. No production photo approvals, Roblox uploads, detailed custom rigs or imported architectural models have been completed. The world explicitly labels its remaining architecture as a layout preview.

The owner supplied [Build a Soccer Team](https://www.roblox.com/games/94164742020505/Build-a-Soccer-Team) as the layout reference. Its public page was initially blocked and became accessible after the owner applied updated environment settings. No game screenshots or live game were inspected. The current arrangement is MOGVILLE's original interpretation of a card-collector promenade; it is not a verified match of that game's layout, and none of its proprietary art or models was copied.

## What changed

- Desktop HUD with left navigation, a prominent bottom-center Spin control, collectible-card grids and sealed-card roulette. Mobile keeps adaptive navigation and scroll sheets. Roulette settles only on a reward already awarded by the server; skip and reduced motion remain free.
- All generated face illustrations removed from the UI and world card displays. The 48 V2 source/output face PNGs and their production assignments were retired. Missing photos show explicit neutral status panels.
- A centralized `MoggerPortraitRegistry` and generated `RealMoggers` database with 28 pending references: 25 provisional names plus unresolved Kaysh, Post-Surgery Hexum and Chad Jaw labels. No identity, photographer, license or asset ID is invented.
- Real-person obtainability requires an authentic adult-era photo of the verified person, source/creator/license records, commercial-use and applicable likeness permission, and a recorded successful Roblox image upload. A numeric ID alone never enables a card.
- Known real-form IDs are retained in a ledger even after photo withdrawal, so owned instances and assignments survive. Existing fictional collectible IDs are clearly labeled **legacy test cards** so rolling, ownership, income, teams and existing version-one saves remain testable. They are not presented as recognizable real people. They have no generated human portrait substitutes. The intended real-person production banner is not ready.
- Removed the old block display mannequins and generic decorative NPC figures. Reviewed R15 display/NPC templates can now be loaded. Missing display rigs are explicitly marked **MODEL REQUIRED**; five main NPC roles and three residents use informative kiosks until custom models are imported.
- NPCs have distinct names, authored appearance requirements, dialogue and real menu interactions. Approved residents use short bounded routes only after both approved idle and walk tracks load. There are no fabricated animation IDs or walking dummies.
- Spawn faces the Spin Hall, collector plots retain their stable assignment topology, and eight districts have explicit reviewed-model import pivots. Removed the unrelated cube skyline and added a connected social garden.
- Imported local models are cloned privately, stripped of executable code/remotes/package dependencies, checked for budgets and rig structure, optionally normalized, and only then parented into the live world. R15 validation checks all sixteen body parts and a connected Motor6D body graph.

## Asset acceptance table

| Requirement | Actual delivery status |
| --- | --- |
| Source-reviewed photo files | **15** in a separate review pack; **13** references unresolved; **0** approved production photos |
| Enabled real-person cards | **0**; all pending and unobtainable |
| Roblox image uploads | **0**; no upload credentials or tooling configured |
| Imported premade 3D models/material packs | **0**; public access now works, but no approved assets imported |
| Approved customized NPC rigs / animations | **0**; eight specific templates remain required |
| New layout/UI implementation | Implemented; not visually inspected in Studio |
| Detailed final architecture | **Incomplete**; eight import slots and original layout preview only |
| Existing gameplay logic | Preserved and covered by automated checks; real Studio loop still pending |

Historical source audit and initially blocked URLs: [V3_ASSET_AUDIT.md](V3_ASSET_AUDIT.md). Current photo sources and precise blockers: [research catalog](../assets/references/research-catalog.md). More geometry or a lower part count is not evidence that the art is production quality.

## Get authentic cards working

1. Public research access is now working after the owner applied the environment settings. Review the collected photo pack and the remaining per-person source blockers. This research did not publish another environment or Roblox experience.
2. Resolve the identity and adult-era photograph for each candidate. Ambiguous aliases stay unresolved. Confirm the exact photo's photographer, license, commercial/derivative use, attribution and applicable likeness authorization.
3. Add approved local photographs to `assets/characters/manifest.json`. Use `referenceType="RealPerson"`, `authenticPhotograph=true`, `identityVerified=true`, `adultEraVerified=true`, `containsRealPerson=true`, the rights/evidence fields, and canonical IDs such as `real_<verified_identity_id>_classic`. Variants Young/Classic/Prime/Ascended each need an authentic authorized photo record; an Ascended border does not fabricate a new photograph.
4. Run `python3 tools/portraits.py` to prepare 512×512 outputs. This command never downloads photos or uploads assets and refuses fictional substitute faces. It refreshes `PortraitAssets` and `RealMoggers` from the reviewed records.
5. Import the images through your own Roblox Studio Asset Manager/Creator Dashboard, wait for moderation, test their image/content IDs, and record the actual ID, `uploadStatus="uploaded"` and `uploadEvidence` in the manifest. Set `requestedEnabled=true` only when ready. Regenerate the mappings, build and test in your private experience.

The permission flags are owner review records, not independent proof that a source license or an upload is valid. A successful record validation never means this agent performed an upload. See [PORTRAIT_PIPELINE.md](PORTRAIT_PIPELINE.md) for all fields.

## Import the actual models

1. Obtain properly licensed high-quality R15 rigs and district models using the source/appearance requirements in `AssetManifest`, `NPCConfiguration`, and `assets/references/v3-asset-shortlist.json`. Review the file in a private test experience without running Toolbox scripts.
2. Export sanitized `.rbxm`/`.rbxmx` models into `assets/models/approved/`, or place them under `ServerStorage.ApprovedAssets` in Studio. If using Rojo, keep source files authoritative and stop syncing before making Studio-only template changes.
3. Give each Model the exact `templateName` from its manifest key. Fill its source URL, creator, exact license, commercial permission evidence and quality review. Set `status="Approved"` and `qualityApproved=true` only after review. No model ID or remote `LoadAsset` call is needed for local templates.
4. For an NPC/display, supply a customized R15 Humanoid rig with all required body parts, connected Motor6Ds, intended accessories and reviewed collision/ground placement. Set only real owner-usable animation IDs and their approval evidence. Do not call a blank default dummy a finished custom NPC.
5. Inspect the actual rig/model appearance, scale, orientation and geometry in Studio. Template pivots/footprints must fit the corresponding district. Remove or replace the identified preview scenery deliberately; the loader does not certify that arbitrary imported geometry leaves routes walkable.
6. Verify every menu prompt, role dialogue, resident route, character display, collision and cleanup behavior before making the experience public.

The loader's stripping and structural checks are defense in depth, not a full malware scanner or visual-quality evaluator. No imported model is executed as trusted code.

## Validation performed

Photo-research follow-up: **20 Python tests passed**, including source-specific license selection, adult-date gating, source-byte preservation, review-pack integrity and continued production separation. The pack contains 15 source-reviewed photos; gallery paths, credits, hashes, held-file exclusion and deterministic ZIP reproduction were checked. Gameplay code and the downloadable place were unchanged by this follow-up.

The earlier V3 implementation was validated as follows:

- 98 Luau tests passed; all 48 current Luau game/test files compiled.
- 10 Python tests passed for authentic-photo/permission/ID/path/normalization gates and retired placeholder rejection.
- Actual world builders under explicit construction stubs passed: twelve unique plots, 120 stands, card ownership/inspection, full capacity, cached rendering, cleanup/reuse, eight architecture slots and eight missing NPC-template records. Baseline preview: 851 parts; full card/pet load: 1,367 parts. These counts are budgets, not a quality claim.
- Rojo built both Studio place formats; binary/ZIP contents verified.
- Not performed: Roblox Studio screenshots, reference-game layout comparison, image moderation/display, imported-model visual inspection, actual physics/animations/multiplayer/save-rejoin/device performance. Studio is unavailable in this Linux environment.

Open the rebuilt private test place to assess the changed UI/layout. The non-negotiable real-portrait and high-quality-asset criteria remain blocked until the required assets, permissions and Studio verification exist.
