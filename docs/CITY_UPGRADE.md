# Luxury-city visual upgrade

The working economy, persistence, inventory, quests and PvE services are retained. `EnvironmentBuilder` handles static city scenery; `WorldService` retains plot assignment, display rendering, pet cleanup and respawn behavior. `WorldEffectsController` performs local-only decorative animation in one loop, with distance culling and configurable budgets.

## Areas

- A bright marble/purple spawn plaza with a central original statue, fountain sculpture, welcome arch, benches, planters, lamps and directional signs.
- A northern gacha hall with a neon machine, floating previews, rarity markers, an odds prompt and an open approach.
- Twelve residences with ten well-spaced stands each, owner/income signage, rarity-dependent pedestals and portrait holo cards.
- A circular Mog-Off arena with an entrance, spectators' benches, battle NPC/prompt, stage markers and scoreboard signage. Combat remains the authoritative menu-driven PvE system.
- A gym with stylized weight equipment, mirrors and a trainer opening existing upgrades; no new unimplemented training rewards are promised.
- Pet/gameplay shops and a clearly separate premium storefront that remains unavailable for purchases.
- A luxury ascension deck reached by a walkable ramp, a monument, gold showcases and an existing ascension-menu interaction. It is an explorable district, not a newly enforced progression gate.

World prompts use existing menus and server actions. Click or interact with a Mogger's card to inspect its publicly displayed stats; only owned UIDs can be equipped. Higher forms have distinct colors/crowns/accessories, while mutations remain a separate visual/stat layer.

## Effects and mobile

`Config.World` holds static-part, light, particle, animation and distance limits. Animated decorative parts are anchored and noncolliding so client-local motion cannot move authoritative gameplay geometry. The client caps nearby animations, lights and emitters, culls at intervals rather than sorting every frame, and avoids per-character income loops.

Settings provides **Low effects** and **Reduced motion**. Low effects disables decorative motion/particles/local lights and lowers selected local postprocessing/shadows. Reduced motion suppresses reveal scaling/sparkles and world motion/particles. Built-in sound is separately muteable. Device performance and final lighting still require Studio testing; a headless object/count test cannot measure frame rate or prove collision/physics behavior.

## Studio acceptance

Open the new place and test the established join/place/earn/roll/equip/save/rejoin loop first. Walk every major route, the gacha side passages, arena entrance, ascension ramp and each plot entrance. Confirm player collisions, readable signs, no trapped spawn, character/pet cleanup and unobstructed mobile controls. Test all 12 plots with ten units and compare default versus low-effects modes. Verify actual uploaded portraits and failure fallback once IDs are supplied. The cloud build does not provide rendered Studio screenshots or establish live multiplayer performance.
