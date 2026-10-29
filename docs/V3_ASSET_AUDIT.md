# V3 asset and reference audit — 2026-10-28

This is the historical V3 implementation audit. Public source access now works, and 15 photo files have since been collected in a separate [review pack](../assets/references/photo-review/README.md), with 13 references unresolved. The network failures below describe the earlier attempts. No game photo uploads, production approvals or model imports have been added by the research follow-up.

## What was inspected

The V2 repository has 24 original collectible forms. Its portrait manifest records 24 original geometric placeholders and **zero real-person photographs or Roblox image uploads**. The previous research catalog contains 25 provisional named leads; Kaysh, Post-Surgery Hexum and the newly requested Chad Jaw label remain unresolved. None is a verified identity/photo/permission record. Original placeholder PNGs are project artwork, not photographs of these people and not acceptable substitutes for their portraits.

V2's `WorldService` and `EnvironmentBuilder` construct their own Part-based characters and architecture. No authored external R15 rig, Creator Store building, custom PBR material set or uploaded animation was recorded in that version. The older Part-based figures and face illustrations therefore cannot be counted as satisfying V3's model/portrait quality requirements.

The machine-readable audit and import shortlist is [v3-asset-shortlist.json](../assets/references/v3-asset-shortlist.json). It distinguishes proposed research leads, actual access attempts, selected assets, permissions, upload status and implementation slots. It contains no invented asset IDs, photographer names or licenses.

## Reference experience

The owner supplied [Build a Soccer Team](https://www.roblox.com/games/94164742020505/Build-a-Soccer-Team), place ID `94164742020505`, after describing the desired layout as “Spin a Soccer Card.” This exact URL is the reference for the request. **Its gameplay layout has not been visually inspected here.** The title relationship is not independently verified, and a provided link alone does not establish the layout or grant reuse of the game's map, UI or assets.

The current original layout brief is a readable card-collector promenade: spawn faces the spin hall, collector plots flank shared walkways, and signs connect surrounding activity districts. It is an interpretation pending an accessible reference or owner-provided screenshots, not a claim to have reproduced the reference experience.

## Actual source-access results

The current runtime reports an enforced restricted policy with package-manager destinations and no custom research hosts. These read-only HTTPS requests used the inherited proxy and TLS verification through approved shell execution on **2026-10-28 at 6:11 p.m. EDT (22:11 UTC)**:

| Purpose | Exact destination | Observed result |
| --- | --- | --- |
| Owner's reference game | `https://www.roblox.com/games/94164742020505/Build-a-Soccer-Team` | Proxy tunnel `403 Forbidden`; no page content |
| Creator Store model catalog | `https://create.roblox.com/store/models` | Proxy tunnel `403 Forbidden`; no catalog content |
| Commons photo/license research | `https://commons.wikimedia.org/wiki/Main_Page` | Proxy tunnel `403 Forbidden`; no page content |

These failures establish blocked access, not the absence of useful models or licensed images. No blocked request was retried through an unrelated mirror, alternate proxy or direct route. No photograph or external model was downloaded. Prior Wikipedia, Models.com and Know Your Meme denials remain recorded in `assets/references/source-access.json`.

Required additional destinations for these exact operations are `www.roblox.com`, `create.roblox.com` and `commons.wikimedia.org`. The earlier research draft also includes `en.wikipedia.org`, `upload.wikimedia.org`, `www.wikidata.org`, `models.com` and `knowyourmeme.com`. A saved draft does not apply network changes. Further asset/CDN destinations should be added only when an approved source/import operation establishes the exact host; no wildcard Roblox access is assumed.

## Portrait acceptance gates

No authentic real-person portrait has been verified or integrated by this audit. Every requested real-person entry remains unobtainable until all applicable records exist:

1. Exact public identity and an appropriate adult-era source photograph, including accurate name/variant association. “Young” must not become an excuse to select a minor's image.
2. The photograph's original source, creator/photographer, exact license, commercial-game/derivative-use permission and required attribution.
3. Separate applicable likeness/publicity approval for the recognizable-person collectible. A Commons copyright license does not automatically establish it.
4. A successful owner-authorized Roblox image upload, moderation/access completion and actual usable image/content asset ID.
5. Studio inspection of cropping, correct identity, display access and failure behavior.

Until then, a real-person catalog card must show an unresolved-photo status with no synthetic or unrelated face. The working original gameplay collection can be retained as explicitly labelled legacy/test content; it must not be relabelled as real people. Changing a display name or adding a nonzero number does not clear a photo.

## Model selection and integration shortlist

The following are **required asset slots and art briefs**, not claimed selected/imported Creator Store assets. `selectedAssetURL`, creator, license and numeric asset ID remain empty in the JSON because source access failed.

| Template key | Required authored appearance |
| --- | --- |
| `npc_gacha_master` | Distinct luxury outfit, sculpted hair, gold accessories, expressive idle |
| `npc_gym_trainer` | Distinct athletic silhouette, gym outfit/accessories, energetic idle |
| `npc_fashion_icon` | Original layered fashion outfit, asymmetrical hair/accessories, runway pose |
| `npc_battle_champion` | Distinct combat outfit/armor, dramatic silhouette, battle-ready stance |
| `npc_ascension_guardian` | Elaborate original guardian silhouette, approved effects and idle |
| `npc_resident_courier` | Courier outfit/satchel and bounded delivery route |
| `npc_resident_collector` | Collector outfit/memorabilia and bounded collection-focused route |
| `npc_resident_gardener` | Gardener outfit/tools and bounded garden activity |
| `display_<stable characterId>` | Per-form approved R15 appearance, or an explicitly configured approved `modelKey` |

The NPC framework expects genuine R15 templates with the standard body/root parts and Motor6D joints, bounded part counts, and no automatic dependency execution. Animation slots remain zero until an owner supplies approved uploads. A generic recolored dummy or a missing-model interaction kiosk is not a completed NPC asset.

Architecture slots are `district_central_plaza`, `district_gacha_hall`, `district_display_neighborhood`, `district_shopping`, `district_gym`, `district_arena`, `district_ascension` and `district_park`. `DistrictConfiguration` provides reserved pivots and footprints. Built-in material enums are not evidence that high-quality PBR texture assets or MaterialVariants were imported.

## Manual import and quality procedure

Once access and suitable assets are available:

1. Select an actual source asset and record its author, stable source URL, permitted use and attribution. Check restrictions against commercial use, redistribution, modification and platform ownership.
2. Import it into a disposable Studio test place. Inspect the entire descendant hierarchy before running Play. Reject or remove executable scripts, dynamic dependency loaders, remotes and unrelated content; do not run Toolbox code to discover what it does.
3. Review mesh/texture access, rig joints, collision, scale, orientation, accessory attachments, animation ownership and part/triangle budgets. Normalize the pivot to the intended spawn/display anchor.
4. Add the reviewed local Model to `ServerStorage.ApprovedAssets`, using the configured template name, and complete the local manifest approval record expected by the importer. Do not populate external IDs or approval fields with guessed values.
5. Import approved animations and material maps separately; record actual IDs and usage permissions. Zero IDs remain disabled.
6. Check each named NPC, collectible display and district from the intended player sightlines in Studio. Test interaction, animation, grounding, touch, collisions and multiplayer/device performance.
7. Only then mark the corresponding asset and visual acceptance criteria complete. Count-based construction checks and successful Rojo builds cannot prove professional visual quality.

## Remaining blockers

- The reference game, Creator Store and photograph-license sources remain network-blocked.
- Zero real-person photographs, external rigs, authored architecture templates, custom PBR sets or uploaded animations were obtained by this audit.
- Model/photo permissions and actual Roblox uploads remain owner prerequisites.
- Roblox Studio rendering, physics, rig/animation behavior and performance are unavailable on this Linux host.

The V3 implementation may improve integration, presentation and navigation while these prerequisites are missing. It must keep these asset-dependent acceptance requirements open rather than call placeholders final artwork.
