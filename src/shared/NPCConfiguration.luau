--!strict
-- Appearance briefs are requirements for approved R15 templates, not claims that
-- models or animations have been imported. No Roblox asset IDs are invented.
local NPCConfiguration = {}

NPCConfiguration.MaxActiveResidents = 3
NPCConfiguration.MaxRigParts = 96
NPCConfiguration.WaypointInterval = 0.5
NPCConfiguration.MaxWaypointDistance = 48
NPCConfiguration.WaypointTimeout = 12

NPCConfiguration.Characters = {
	gacha_master = {
		name = "Aurelio Flash", role = "Gacha Master", modelKey = "npc_gacha_master",
		position = { -23, 1, -111 }, yaw = 20, accent = "FFD36F", resident = false,
		appearance = { body = "Tailored R15 proportions", outfit = "Original ivory tuxedo with violet satin lapels", hair = "Swept sculpted pompadour", accessories = "Gold star brooch, stacked bracelets, pocket watch", expression = "Confident welcoming smile", silhouette = "Asymmetric long tuxedo tails" },
		animations = { idle = 0, walk = 0 }, assetStatus = "TemplateRequired",
		dialogue = "Welcome to the card floor. Spend gameplay Coins to spin; every result is selected on the server. Rarity and individual odds are shown before your next spin. Luck changes normalized rarity weights, while pity guarantees Rare+ and Mythic+ progress. Real-person cards stay unavailable until their authentic photos and permissions are approved.",
		actions = { { label = "Open card spins and exact odds", menu = "Roll" }, { label = "View my collection", menu = "Inventory" } },
	},
	gym_trainer = {
		name = "Coach Tempo", role = "Gym Trainer", modelKey = "npc_gym_trainer",
		position = { -67, 1, -56 }, yaw = -20, accent = "72E8D1", resident = false,
		appearance = { body = "Broad athletic R15 proportions", outfit = "Original teal technical tracksuit with charcoal panels", hair = "Textured close crop", accessories = "Headphones, whistle, towel and wrist wraps", expression = "Focused encouraging grin", silhouette = "Broad shoulders and a shoulder-draped towel" },
		animations = { idle = 0, walk = 0 }, assetStatus = "TemplateRequired",
		dialogue = "Consistency builds a collection. Upgrade display slots to place more owned cards and earn more Coins. Luck training changes your next-spin odds. Beginner quests reward real gameplay progress. Dedicated strength training is not available yet, so I will not sell an upgrade that does nothing.",
		actions = { { label = "Train luck and expand displays", menu = "Upgrades" }, { label = "Check beginner quests", menu = "Quests" } },
	},
	fashion_icon = {
		name = "Sable Silhouette", role = "Fashion Icon", modelKey = "npc_fashion_icon",
		position = { 83, 1, 28 }, yaw = -30, accent = "E8A5FF", resident = false,
		appearance = { body = "Tall original R15 silhouette", outfit = "Original black-and-lilac layered coat with sculptural collar", hair = "Angular lavender bob", accessories = "Geometric glasses, silver ear cuff, small shoulder bag", expression = "Playful raised brow", silhouette = "Wide collar, cropped sleeve and asymmetric coat hem" },
		animations = { idle = 0, walk = 0 }, assetStatus = "TemplateRequired",
		dialogue = "A strong card should read at a glance: authentic photo, clear name, rarity, form and mutation. This showroom explains future cosmetics; paid products and appearance upgrades are not configured yet. Your display inventory and free settings are available now.",
		actions = { { label = "Visit the clearly labelled showroom", menu = "Shop" }, { label = "Inspect my collection", menu = "Inventory" }, { label = "Adjust free visual settings", menu = "Settings" } },
	},
	battle_champion = {
		name = "Captain Vantage", role = "Battle Champion", modelKey = "npc_battle_champion",
		position = { 26, 1, 72 }, yaw = -25, accent = "86BCFF", resident = false,
		appearance = { body = "Balanced combat-ready R15 proportions", outfit = "Original navy arena armor over a white technical uniform", hair = "Short windswept silver hair", accessories = "One shoulder mantle, champion medallion, fitted gloves", expression = "Determined friendly expression", silhouette = "One high armored shoulder and a short cape" },
		animations = { idle = 0, walk = 0 }, assetStatus = "TemplateRequired",
		dialogue = "A Mog-Off uses up to three owned cards. Pick a team separately from your passive-income display. Speed sets attack priority; specials have cooldowns, defending softens damage, and reserves can switch. Winning PvE grants server-calculated rewards. Losing never removes your collection.",
		actions = { { label = "Enter a PvE Mog-Off", menu = "Battle" }, { label = "Build my battle team", menu = "Team" }, { label = "Check battle quests", menu = "Quests" } },
	},
	ascension_guardian = {
		name = "Warden Solstice", role = "Ascension Guardian", modelKey = "npc_ascension_guardian",
		position = { 0, 12, -229 }, yaw = 0, accent = "FFE5AA", resident = false,
		appearance = { body = "Tall dignified R15 proportions", outfit = "Original white-and-gold plated ceremonial armor", hair = "Long dark braided crown", accessories = "Segmented gold mantle, ring crest and angular gauntlets", expression = "Calm watchful expression", silhouette = "Crescent mantle, long tabard and halo-like crest" },
		animations = { idle = 0, walk = 0 }, assetStatus = "TemplateRequired",
		dialogue = "Ascension is earned through collection, placed income, PvE victories and gameplay Coins. Check the exact next-rank requirements before spending anything. An eligible ascension grants a title and another display slot without deleting your owned cards. This district is currently explorable; a separate locked-area progression system is not claimed.",
		actions = { { label = "Review and attempt ascension", menu = "Upgrades" }, { label = "Check collection progress", menu = "Inventory" } },
	},
	resident_courier = {
		name = "Pip Parcel", role = "City Courier", modelKey = "npc_resident_courier",
		position = { -26, 1, 30 }, yaw = 0, accent = "FFB18A", resident = true,
		appearance = { body = "Compact R15 proportions", outfit = "Original coral delivery jacket with cream trousers", hair = "Curly hair under a tilted cap", accessories = "Parcel satchel and fingerless gloves", expression = "Cheerful open smile", silhouette = "Oversized square satchel" },
		animations = { idle = 0, walk = 0 }, assetStatus = "TemplateRequired",
		waypoints = { { -26, 1, 30 }, { -25, 1, 12 }, { -24, 1, -15 }, { -26, 1, 5 } },
		dialogue = "My route connects the plaza's useful stops. You can display and battle with the same owned card; those assignments are separate.",
		actions = { { label = "Open my collection", menu = "Inventory" } },
	},
	resident_collector = {
		name = "Mira Mint", role = "Card Collector", modelKey = "npc_resident_collector",
		position = { 26, 1, 30 }, yaw = 0, accent = "9EE5B4", resident = true,
		appearance = { body = "Relaxed R15 proportions", outfit = "Original sage oversized cardigan and dark pleated trousers", hair = "Dark double-bun hairstyle", accessories = "Card binder, round glasses and green sneakers", expression = "Curious friendly expression", silhouette = "Large binder held close to the chest" },
		animations = { idle = 0, walk = 0 }, assetStatus = "TemplateRequired",
		waypoints = { { 26, 1, 30 }, { 25, 1, 12 }, { 24, 1, -12 }, { 26, 1, 8 } },
		dialogue = "I check the next-spin odds before every pack. A ten-spin advances pity after each result, so later spins can have different odds.",
		actions = { { label = "Read exact spin odds", menu = "Roll" } },
	},
	resident_gardener = {
		name = "Fern Lane", role = "Park Steward", modelKey = "npc_resident_gardener",
		position = { -21, 1, 46 }, yaw = 0, accent = "A4DDA4", resident = true,
		appearance = { body = "Comfortable R15 proportions", outfit = "Original green work overalls and a cream rolled-sleeve shirt", hair = "Chestnut braid", accessories = "Leaf-pin sunhat, pruning pouch and boots", expression = "Warm contented smile", silhouette = "Wide sunhat and utility pouch" },
		animations = { idle = 0, walk = 0 }, assetStatus = "TemplateRequired",
		waypoints = { { -21, 1, 46 }, { -10, 1, 47 }, { 10, 1, 47 }, { 21, 1, 46 } },
		dialogue = "Take a break and keep your display earning while you play. Low effects and reduced motion are free settings, and the game never bypasses Roblox idle behavior.",
		actions = { { label = "Open visual accessibility settings", menu = "Settings" } },
	},
}

return NPCConfiguration
