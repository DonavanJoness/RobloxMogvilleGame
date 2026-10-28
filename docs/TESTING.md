# Validation and Studio acceptance

## Automated checks

Run from the repository root:

```bash
python3 tools/test.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/world_smoke.py
.tools/bin/rojo build default.project.json --output build/Mogville.rbxlx
```

The runner compiles all source/test Luau and executes nonzero test suites against the actual modules. Temporary bundling rewrites static Roblox requires only; it does not substitute implementations. `tests/runtime.luau` supplies explicit service mocks, controllable UpdateAsync errors/conflicts, players and task scheduling.

- Rules: normalized base and boosted probabilities, pity eligibility/reset/ten-pull sequencing, capacity/currency atomicity, invalid random/UID rollback, income and additive pets, serialization sanitization.
- Character/economy/persistence services: ownership, duplicate/sparse team payloads, slot upgrades, delayed ticks, caps, atomic leases, conflicts, load/save failure protection, leaving during a load/save, offline caps and Studio isolation.
- Combat/progression: speed, defense, ability cooldown, reserves, invalid/terminal actions, exact-once PvE rewards, quest claims, pet purchases/slots, ascension, verified friends and bounded server events.
- Network: token-bucket bursts/refill and malformed/nonfinite/nested payloads.

Passing mocks does not establish Roblox API correctness, live distributed behavior or rendered usability. Compilation is a syntax check, not a complete Roblox type analysis.

The separate world smoke runs actual generation/plot modules with lightweight construction stubs and verifies hierarchy, ownership, stand layout, character/pet counts, effect budgets, caching and release/reuse. Its CFrame stub retains translation only: layout checks are schematic arithmetic, not rotated collision or physics checks. Python tests cover asset approval gates, separate likeness evidence, ID validation, safe paths, source-preserving PNG normalization, manifest dimensions and disabled research records.

## Phase 1 gate — not yet executed in Studio

Use a private test experience. Record observed results instead of marking these done from source inspection.

| Step | Required observation |
| --- | --- |
| Join with a fresh distinct user | One Common starter, 150 Coins, zero income before placement, one owned plot |
| Display the starter | Original model and readable overhead name/rarity/mutation/income appear; income becomes 2/sec |
| Wait at least 5 seconds | Server Coins increase by elapsed server income; client cannot set the balance |
| Roll once | Costs 50; one result with a new UID; inventory, rarity, mutation and stats agree |
| Roll ten | Costs 500; ten distinct UIDs; individual draws advance pity; insufficient balance changes nothing |
| Equip/remove duplicates | Each duplicate UID is independent; only placed units generate income; slot limit enforced |
| Leave and rejoin with persistence enabled | Coins, instances, display/team assignment, pets, pity, upgrades/settings remain |
| Shutdown/restart | Final saves release leases; no blank profile overwrites failures |

Phase 1 is complete only after this entire loop passes in Studio/published testing.

## Multiplayer and security

Use Studio **Test → Start Server** with at least two clients and distinct test user IDs. Set maximum public server size to 12.

1. Confirm unique plot owners, visible remote-player displays, and correct respawn placement. Test all 12 plots before raising the cap.
2. Attempt another player's UID with Equip/Unequip/SetTeam; verify no ownership, income or placement change.
3. Send malformed payloads, fractional/negative roll counts, invalid pet IDs, oversized teams and rapid bursts. Verify safe errors and bounded request processing.
4. Test simultaneous affordable actions on one balance; verify total deductions/rewards agree with server state.
5. Verify friends bonus only for confirmed, currently present friends. Departing friends must lose their contribution. API failure must not grant luck.
6. Complete the first-win quest and claim once. Observe one ten-minute server event, nonstacking behavior and correct displayed numerical odds on every client, including expiration.
7. Test active battle timeout, switch/death/cooldowns, defeat with zero award, and repeated terminal actions with no duplicate reward.

## Real DataStore checks

Follow README persistence setup. Use a disposable test universe and avoid editing stored records manually in a live release.

- Disable API access and confirm memory mode remains playable by default. With persistence explicitly enabled, loading failure must refuse the session; it must not write defaults.
- Test reconnect after graceful leave and after an interrupted server. Live session conflicts should refuse a second writer until the first releases or its 180-second lease expires.
- Observe autosaves and DataStore budgets in Studio/server output. Failure must retain the previous valid record.
- Rejoin after offline time: 25% of saved equipped income for at most four hours. Rejoining repeatedly must not re-credit the same offline period.
- Check a newer unsupported schema refuses to load rather than overwriting.
- Verify Studio test data and published-server data are in separate store names.

## Presentation and performance

- Test phone portrait/landscape, tablet and PC through Studio's device emulator. Swipe the bottom navigation, search inventory, scroll all panels and tap each action. Target 44+ pixel controls; inspect clipping, safe areas and keyboard overlap.
- Inspect reduced motion, free skip/quick reveals, mute, rarity colors and Ascended reveal. Built-in audio playback requires Studio verification.
- Fill a server and display ten characters per player. Inspect frame/server timings, overhead clutter, network traffic and pet weld behavior. Income should use one centralized tick, not one loop per Mogger.
- Confirm plots recycle after leave, character/pet models clean up, and respawning cannot duplicate pets.

## Release limits

PvP, daily quests, new training/area-gating rewards, global limited-stock grants, global leaderboards and developer-product receipt fulfillment are not enabled in this release. The city now includes explorable gym and luxury scenery. Real-person candidates remain unverified/disabled; actual portrait uploads are pending. See CITY_UPGRADE.md and PORTRAIT_PIPELINE.md for their acceptance steps. Keep product IDs at zero and premium items off sale. Before enabling future transactional systems, test atomicity, durable idempotency, failure recovery and current policy requirements.
