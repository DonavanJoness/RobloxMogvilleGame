# MOGVILLE — real faces in the uploaded place

This download embeds **18 authentic photo previews inside the `.rbxl`**, using client-created Roblox `EditableImage` objects. It preserves the owner's newer uploaded world and character scripts. Separate image imports and fabricated asset IDs are not used.

## Open the game

1. Open `Mogville-real-faces.rbxl` in Roblox Studio on Windows or macOS.
2. Press **Play**. The uploaded game generates its world at runtime.
3. A new Studio profile starts with Jon Kortajarena. Open Inventory, display the card on your plot, and Spin for more photo-backed cards.
4. Open **Real Moggers** for the photo collection and credits.

If Roblox reports an image API permission error, enable **Allow Mesh / Image APIs** under the experience's **Settings → Security**, then restart Play. The actual checkbox is controlled by Roblox and cannot be changed in this Linux workspace. No credentials need to be pasted into chat.

**This is a Studio-only photo gameplay preview.** Publishing this file does not automatically enable this preview in live servers. Production photo approval/upload gates remain unchanged. No Roblox image uploads, moderation approvals or third-party model releases were performed or invented.

## Included faces

Clavicular; Francisco Lachowski; Henry Cavill; Jordan Barrett; David Gandy; Sean O'Pry; Lucky Blue Smith; Jon Kortajarena; Marlon Teixeira; Tyson Beckford; Marcus Schenkenberg; Noah Mills; Simon Nessman; Andrés Velencoso; Baptiste Giabiconi; River Viiperi; Jon-Erik Hexum; Chad Michael Murray.

The owner authorized closest documented name/reference selections for ambiguous labels:

- **“Post-Surgery Hexum” → Jon-Erik Hexum.** The actual actor's photo is labelled Jon-Erik Hexum. No surgery claim or claim that this matches the inaccessible Instagram post is made.
- **“Chad Jaw” → Chad Michael Murray.** This is a closest-name selection, not a claim that Chad Jaw is his alias or that he is a person in the supplied BBC article.

Source dates establish adult-era photographs. Known source crops, retouches and video stills are recorded. Preview processing selects a head crop, resizes proportionally, adds dark margins where needed, and encodes the existing photo pixels. It does not generate a face or invent a photographic variant. Mutations use the same authentic image with game UI styling.

## Ten requested references still unresolved

| Reference | Actual remaining issue |
| --- | --- |
| Ernest Khalimov / GigaChad | The photographic art project's image reuse permission was not established. |
| David Agbodji | Public model source found; no image-specific reusable photo license located. |
| Alton Mason | Candidate screenshot still has an unresolved external-license review warning. |
| Pietro Boselli | Public model source found; no image-specific reusable photo license located. |
| Alex Lundqvist | Public model source found; no image-specific reusable photo license located. |
| Mathias Lauridsen | Public model source found; no image-specific reusable photo license located. |
| Garrett Neff | Public model source found; no image-specific reusable photo license located. |
| Kit Butler | Public model source found; no image-specific reusable photo license located. |
| Clément Chabernaud | Public model source found; no image-specific reusable photo license located. |
| Kaysh | No sufficiently specific public identity/photo reference was established. |

These entries are unavailable and appear as names/source notes only. They receive no placeholder portrait or another person's face under their name. Their old IDs remain registered for save compatibility. New Studio rolls select only the source-backed photo collection. Existing owned legacy IDs, balance, assignments and teams are retained.

The 28 original requested references are represented by 18 source-backed faces (including two disclosed name matches) and ten unresolved references. Two canonical IDs were added for the name matches; original ambiguous IDs remain registered, resulting in 30 internal reference IDs.

## Sources and implementation

- `assets/references/embedded-photo-manifest.json`: each source hash, head crop, output hash, license, credit and actual reference selection.
- `assets/characters/studio-preview/CREDITS.md`: credits for cropped previews. Source photos retain their individual licenses; adaptations retain the appropriate CC or Free Art License.
- `assets/references/live-research/november-followup.*`: fresh research, exact source URLs and limitations. Instagram and prohibited search routes were not bypassed.
- `assets/place-source/Mogville-user-upload.rbxl`: unchanged original upload used as the build base.
- `tools/embed_real_faces.py`: regenerates the embedded RGBA catalog from reviewed originals and framing records.
- `tools/build.py`: patches source and adds photo modules in the uploaded binary, retaining all original instances and unknown modern Studio properties.

Each client reconstructs and caches one 256×256 image per identity. UI and world-card labels reuse the images. Object-backed image content does not replicate from the server, so world images are assigned on each client. Missing API access or allocation failures show an explicit actionable message; they do not replace a face.

The preserved upload contains 111 original instances and 43 scripts. Three photo modules are added. Automated tests check decoding, pixel hashes, Studio/public behavior, binary changes, payout/pity rules and legacy saves. These are Linux tests with explicit Roblox engine doubles. Actual Studio graphics, image allocation on devices, physics and multiplayer appearance have not been visually tested here.

Validation for this delivery: **102 Luau tests passed**, **33 Python tests passed**, and **62 Luau files compiled**. The actual uploaded district/world builders passed the construction smoke check: baseline 3,043 parts (city 2,395), full twelve-player card/pet fallback 3,559 parts, 32 lights and 28 emitters within the uploaded configuration's limits. This check does not emulate native rigs, physics or EditableImage rendering. The downloadable binary was read back to verify all 18 pixel payloads, all 111 original instances, their parents, and untouched non-source property chunks.
