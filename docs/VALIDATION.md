# Validation evidence — 2026-10-28

**Historical V2 evidence.** Current V3 results and unfulfilled visual-asset criteria are in [V3_STATUS.md](V3_STATUS.md). The V2 original face PNGs below have been retired; no authentic photo or high-quality 3D asset has been imported in V3.

The following checks ran in the Linux cloud environment against this delivery:

| Check | Observed result |
| --- | --- |
| Official pinned tool installation | Rojo 7.5.1 and Luau 0.690 installed with TLS and pinned archive SHA-256 checks |
| `python3 tools/test.py` | **72 passed, 0 failed**, across seven suites |
| Python portrait tests | **8 passed**, covering approval, likeness, IDs, paths and actual PNG outputs |
| Luau compilation | All **34** game/test Luau files compiled |
| `python3 tools/build.py` | Rojo built `build/Mogville.rbxlx`; source ZIP integrity check passed |
| Place XML/content inspection | Valid XML; all **24** game source scripts embedded: one server Script, one LocalScript, 22 ModuleScripts |
| World construction smoke | Actual generation modules under stubs passed: 12 plots, 120 stands, cache/release/reuse, full 120-unit / 36-pet load; baseline 934 parts, full 3,250 parts, 24 lights and 24 emitters |
| Source research | Four source hosts denied by proxy HTTP 403; 25 candidate leads and two unresolved labels remain unverified/disabled; no third-party images fetched |
| Portrait preparation | 24 original 512×512 PNG placeholders prepared; hashes recorded; **zero Roblox uploads or assigned IDs** |
| Source review | Cross-reviewed service contracts, odds refresh, ownership/cost checks, battle timeout propagation, disabled premium defaults and documented scope |

No automated test failure remains. The production-service tests run actual modules with explicit Roblox API mocks. They do not execute Roblox physics, rendering, remote transport, MarketplaceService or actual distributed DataStores.

World construction stubs do not validate Roblox property names, rendering or rotated collision geometry. Their CFrames preserve translation only. Part/light counts and schematic route arithmetic are useful construction checks, not live device performance or proof that players can traverse the map.

**Not executed:** Roblox Studio play, two-client play, visual/device tests, live DataStore save/rejoin/shutdown and public-server performance. Studio is unavailable on this Linux host. Phase 1 acceptance remains **pending** until the full checklist in TESTING.md passes in Studio/published private testing.

**Not enabled:** consent-based PvP, global limited stock, global ordered leaderboards, daily quests, evolution/XP and developer-product fulfillment. No claim is made that stock-reservation or receipt-idempotency tests passed. Product IDs remain zero and paid luck is disabled.

The cloud environment's reusable `install_script` and `start_skill` were saved as a configuration draft. This is separate from publishing the cloud snapshot or publishing the Roblox experience; neither publication was performed by this task.
