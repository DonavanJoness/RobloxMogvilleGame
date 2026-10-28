# MOGVILLE: Roll to Ascend

An original Roblox collection simulator built with Luau and Rojo. The game creates its luxury city, character models, pets and interface procedurally. It requires no Toolbox models, uploaded artwork, paid assets, runtime packages or credentials to play in Studio memory mode.

**City and portrait update:** 24 original collectible forms, public character inspection, portrait-ready reveals/inventory/battles/plot cards, a fountain plaza, gacha hall, circular arena, gym, shops, ascension deck and decorated collector plots. [City details](docs/CITY_UPGRADE.md) · [Portrait/import guide](docs/PORTRAIT_PIPELINE.md) · [Provisional research catalog](assets/references/research-catalog.md).

**Research status:** live source requests were denied by the network policy. The catalog has 25 provisional candidates plus two unresolved labels; **zero verified identities, licensed real-person portraits or cleared likenesses**. All remain disabled research entries. The 24 local approved PNGs are original geometric placeholders; Roblox upload IDs remain zero, and the game uses procedural portrait fallbacks.

**Status:** the core gameplay is implemented and the Rojo place builds. Automated logic and mocked service tests run on Linux. **Roblox Studio acceptance is pending**: this environment cannot run Studio, verify the appearance on devices, or demonstrate a real leave/rejoin DataStore session. Do not treat this as a production-tested release.

## Open and play

Download the ready-to-open game from GitHub:

- **[Mogville-place.zip](https://github.com/DonavanJoness/RobloxMogvilleGame/raw/refs/heads/main/downloads/Mogville-place.zip)** — extract it, then open `Mogville.rbxl` in Studio.
- **[Mogville.rbxl](https://github.com/DonavanJoness/RobloxMogvilleGame/raw/refs/heads/main/downloads/Mogville.rbxl)** — the same place without ZIP packaging.

If your browser shows the GitHub file page, select **Download raw file**. Sign into the GitHub account with repository access if prompted. The editable project is also available through GitHub's **Code → Download ZIP** button.

The prepared environment contains `build/Mogville.rbxlx` and a clean `build/Mogville-source.zip` export. Download the place file, open it in **Roblox Studio** on Windows or macOS, and press **Play**. The map and interface appear when the server starts; an empty edit-mode workspace is expected. The source archive contains the complete editable Rojo project without Git metadata, local tools or generated outputs.

1. Open **Inventory** and select **Display on my plot** for your starter.
2. Close the menu to see the character and overhead label on your assigned plot.
3. Watch Coins increase. Open **Roll** for a single or ten-pull.
4. Equip the new character, or remove an older display if the three starting stands are full.
5. Claim beginner quests, buy luck/plot upgrades and guaranteed pets with earned Coins.
6. Select up to three separate battle-team members and enter a **Mog-Off**.
7. Ascend after meeting the collection, income, PvE and Coin requirements shown under **Upgrades**.

Coins are not sold for Robux. Studio starts in **temporary memory mode**, clearly indicated in Home and Settings. Use the separate persistence test below before expecting progress to survive Stop.

## Build from source

### Linux cloud environment

Prerequisites: Bash, Python 3, `curl`, `unzip`, `sha256sum`; the provided environment already has these.

```bash
cd /workspace/RobloxMogvilleGame
bash tools/install.sh
```

This installs **Rojo 7.5.1** and **Luau 0.690** to ignored `.tools/bin`, checks pinned SHA-256 values for the official release archives, installs the pinned Pillow asset-processing tool, prepares approved local portraits, compiles every source/test script, runs Luau and Python tests, and builds both `.rbxlx` and `.rbxl` places plus the ZIP/source downloads. TLS verification remains enabled. Existing source images and owner manifest assignments are preserved; generated mappings/outputs are refreshed.

After installation:

```bash
python3 tools/test.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/world_smoke.py
python3 tools/build.py
```

The tests use actual production modules bundled without translating their logic. Roblox service tests use explicit mocks. Mock DataStores do not prove real service behavior.

### Windows / macOS Studio development

Install the official [Rojo CLI and Studio plugin](https://rojo.space/docs/v7/getting-started/installation/) using version 7.5.1 for this project. Clone or download this repository to your local machine.

```text
rojo build default.project.json --output Mogville.rbxlx
rojo serve default.project.json
```

Open the built place, or open a new baseplate and connect the Rojo plugin to the local serve process (default port **34872**). The source must be on the same reachable development machine as the plugin; a cloud loopback server is not a public Studio endpoint. Build/download is the simplest cloud workflow. Stop play before syncing structural changes. Keep source files authoritative; edits made only inside Studio are not automatically written back by Rojo.

## Persistence testing

1. Publish a **private test experience** that you control. Do not use a production universe for the first test.
2. In Studio, open **Game Settings → Security** and enable **Studio Access to API Services** for that test experience.
3. In edit mode, select Workspace and set its boolean attribute **`MogvilleStudioPersistence`** to `true`. If Rojo sync is active, set the corresponding attribute in `default.project.json` for your test checkout, or disconnect sync before changing the Studio attribute.
4. Start Play. Settings should report **Persistent**, rather than Studio memory.
5. Place, earn, roll, equip, change your team/settings, then Stop and wait for shutdown saving. Play again and verify all progress.
6. Run the two-client and failure checks in [docs/TESTING.md](docs/TESTING.md).

Studio persistence uses **`MogvilleStudioProfiles_v1`**; published servers use **`MogvilleProfiles_v1`**. These are separate DataStores in the experience. Test multiple clients with distinct user IDs; concurrent sessions sharing a user ID intentionally conflict. Failed loads never fall back to a blank save. A competing session or unsupported schema refuses play to protect data. Session leases expire after 180 seconds; autosaves renew every 60 seconds. Offline income is credited during atomic lease acquisition, at 25% for at most four hours.

The saved profile contains Coins, unique Mogger instances, displays, independent battle team, pets, upgrades, pity, ascension, quests, statistics, settings and last-seen time. Local active battles and server events are transient. Roblox game-pass ownership is rechecked through MarketplaceService rather than trusted from client/profile claims.

## Project layout

```text
default.project.json          Rojo DataModel mapping
src/shared/Config.luau        Title, roster, rarities, mutations, pets, prices, ranks, product IDs
src/shared/CharacterCatalog.luau Original identities and separately collectible forms
src/shared/CharacterVisuals.luau  Validated portrait mapping and metadata lookup
src/shared/Rules.luau         Profiles, income, exact odds, luck, pity, atomic roll operations
src/shared/Combat.luau        Deterministic turn-based combat kernel
src/server/Main.server.luau   Service composition, validated remotes, centralized ticks
src/server/Services/          Persistence, gacha, placement, economy, world, PvE, social, shop
src/client/Client.client.luau Transport and station prompts
src/client/Controllers/       UI theme, menus, reveals and accessibility
tests/                       Pure rules and mocked production-service tests
tools/                       Pinned tool install and test runner
docs/TESTING.md               Studio acceptance and release checklist
docs/ARCHITECTURE.md          Design and remaining phase scope
assets/characters/           Approved original placeholders, manifest, normalized PNGs
assets/references/           Provisional research and documented access failures
```

UI is generated under PlayerGui by a LocalScript, and the map under Workspace by WorldService. Shared configuration lives in ReplicatedStorage. Server-only authoritative operations live in ServerScriptService. The Network folder is created on startup; clients wait for it before making requests.

## Balance and add content

Edit **`src/shared/Config.luau`**:

- `Game.Title` changes the title in the map and HUD.
- `Characters` is keyed by stable form IDs. `CharacterCatalog` supplies original identity/form descriptions and twelve new forms; legacy definitions keep their IDs and stats. Add new definitions there with known rarity, positive selection weight, stats, supported ability, color, identity and form. Do not rename saved IDs without a migration. `enabled=false` excludes new rolls while retaining owned units; `mutationEligible=false` forces Normal. `PortraitAssets` is generated from the approved asset manifest. WorldService generates form-themed mannequins automatically.
- `Rarities` defines centralized base weights: 55 / 25 / 12 / 5 / 2.5 / 0.5. They are normalized over eligible rarities. Every character within a rarity has its own selection weight.
- `Mutations` defines an independent weighted roll and income/power multipliers. The current five probabilities total 100%.
- `Upgrades`, `Pets`, `Progression`, inventory limits and offline caps are editable. Preserve existing IDs and schema compatibility when publishing updates.

**Luck is a factor, not added percentage points.** A 1.5× factor (+50% luck) changes rarity-tier weight to `baseWeight × 1.5^(tierIndex - 1)`, then normalizes. Earned upgrades, pets, verified in-server friends and earned server events add to the factor with configured caps. Mutations remain independent. On the 20th draw without Rare+, lower tiers are excluded; on the 100th without Mythic+, only Mythic+ is eligible. Pity changes after each draw, including inside ten-pulls. The UI discloses current next-draw rarity and individual character+mutation percentages (rounded to six decimal places).

Pet income/luck/power bonuses add and cap; they do not multiply without bounds. Buying a pet guarantees the selected pet. A successful first-win quest claim can start a bounded ten-minute +25% server luck event; events do not stack. Ascension grants a title and one additional display slot without resetting ownership. The gym and luxury deck are now explorable scenery with existing menu interactions; new training rewards and progression gates are not implemented.

## Robux configuration

`Config.Shop` centralizes IDs, initially **zero**. The in-game premium catalog is intentionally marked **not for sale**. PolicyService checks fail closed; **paid luck stays disabled**, even if an ID is entered. Basic skip, quick reveals and reduced motion are free.

ShopService contains server-side ownership verification and a prompt path for configured game passes, but premium benefits/catalog presentation are not release-complete. Do not list a pass for sale until its described cosmetic/convenience benefit and UI are implemented and tested. Set real owner-supplied IDs in `Config.Shop.GamePasses` only during that separate integration. Developer products are **not enabled**: the receipt handler returns `NotProcessedYet`, never acknowledges an unfulfilled receipt. Durable idempotent receipt grants must be implemented and tested before adding products. No client purchase-success message grants an entitlement.

## Publishing

Build/open the place, complete the Studio acceptance checklist, then use **File → Publish to Roblox** into your own test experience. In Creator Dashboard configure the intended devices and **maximum server size of 12** (plots are configurable, but this initial world has 12). Verify published-server DataStore access and two-player behavior before making it public. Upload approved art/audio or products only when ready; none are required by the current procedural build.

Before public release, add a data migration/backup policy, observe live save budgets and latency, and recheck current Roblox purchase policies if enabling any paid random-reward modifier. Do not enable global limited stock or developer products without their transactional systems and acceptance tests.

## Delivered scope and limits

- Implemented: the existing starter/plots/economy/gacha/saving/PvE/progression loop, expanded to 24 original forms, portrait-ready UI and inspection, a detailed luxury city, decorated plots, bounded client-local effects, low-effects mode, and an approval-gated local image pipeline.
- Automated: rules, affordability/ownership/ID consistency, combat and real service code under mocks; Luau compilation and Rojo build.
- **Still requires Studio:** the full Phase 1 acceptance loop including rejoining, actual multiplayer, real DataStores, device layout/input, sounds, physics and visual performance.
- Later/manual work: unblock and complete live candidate/image research; obtain copyright and applicable likeness approvals; upload approved portraits and supply actual IDs; Studio/device verification; consent-based PvP, global stock/boards, premium fulfillment, daily quests and XP/evolution (forms are already separate collectibles).

No limited-stock or receipt-idempotency test is claimed: those gameplay systems are intentionally not enabled. The Phase 1 acceptance gate remains open until the Studio loop is demonstrated.
