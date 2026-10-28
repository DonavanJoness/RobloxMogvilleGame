# Validation evidence — 2026-10-28

The following checks ran in the Linux cloud environment against this delivery:

| Check | Observed result |
| --- | --- |
| Official pinned tool installation | Rojo 7.5.1 and Luau 0.690 installed with TLS and pinned archive SHA-256 checks |
| `python3 tools/test.py` | **55 passed, 0 failed**, across five suites |
| Luau compilation | All **25** game/test Luau files compiled |
| `python3 tools/build.py` | Rojo built `build/Mogville.rbxlx`; source ZIP integrity check passed |
| Place XML/content inspection | Valid XML; all **19** game source scripts embedded: one server Script, one LocalScript, 17 ModuleScripts |
| Rojo synchronization service | Started on loopback; API reported MOGVILLE / version 7.5.1; instance-read endpoint returned 32 instances; test process then stopped |
| Source review | Cross-reviewed service contracts, odds refresh, ownership/cost checks, battle timeout propagation, disabled premium defaults and documented scope |

No automated test failure remains. The production-service tests run actual modules with explicit Roblox API mocks. They do not execute Roblox physics, rendering, remote transport, MarketplaceService or actual distributed DataStores.

**Not executed:** Roblox Studio play, two-client play, visual/device tests, live DataStore save/rejoin/shutdown and public-server performance. Studio is unavailable on this Linux host. Phase 1 acceptance remains **pending** until the full checklist in TESTING.md passes in Studio/published private testing.

**Not enabled:** consent-based PvP, global limited stock, global ordered leaderboards, daily quests, evolution/XP and developer-product fulfillment. No claim is made that stock-reservation or receipt-idempotency tests passed. Product IDs remain zero and paid luck is disabled.

The cloud environment's reusable `install_script` and `start_skill` were saved as a configuration draft. This is separate from publishing the cloud snapshot or publishing the Roblox experience; neither publication was performed by this task.
