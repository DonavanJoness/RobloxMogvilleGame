--!strict
-- All economy, roster and probability tuning lives here. Colors are RGB hex strings.
local Config = {}
local Catalog = require(script.Parent.CharacterCatalog)
local Visuals = require(script.Parent.CharacterVisuals)
local PortraitRegistry = require(script.Parent.MoggerPortraitRegistry)

Config.Game = {
	Title = "MOGVILLE: Roll to Ascend",
	StartingCoins = 150,
	RollCost = 50,
	MultiRoll = 10,
	BaseSlots = 3,
	MaxSlots = 10,
	InventoryLimit = 300,
	PetInventoryLimit = 50,
	AutoSaveSeconds = 60,
	OfflineCapSeconds = 4 * 60 * 60,
	OfflineRate = 0.25,
	MaxPlayers = 12,
	StarterCharacter = "young_rookie",
	RarePity = 20,
	MythicPity = 100,
	MaxCurrency = 1e15,
	LuckPerUpgrade = 0.10,
	FriendLuck = 0.05,
	MaxFriends = 4,
	MaxLuck = 10,
	MaxPetSlots = 3,
	MaxPetBonus = 1,
}

Config.Rarities = {
	{ id = "Common", name = "Common", weight = 55, color = "DCE3F3" },
	{ id = "Uncommon", name = "Uncommon", weight = 25, color = "71E4AB" },
	{ id = "Rare", name = "Rare", weight = 12, color = "55B8FF" },
	{ id = "Mythic", name = "Mythic", weight = 5, color = "C58AFF" },
	{ id = "Divine", name = "Divine", weight = 2.5, color = "FFD66B" },
	{ id = "Ascended", name = "Ascended", weight = 0.5, color = "FF83CA" },
}

Config.Characters = {
	young_rookie = { name = "Young Rookie", rarity = "Common", income = 2, attack = 12, defense = 4, health = 70, speed = 14, ability = "Strong Jaw", color = "8A9EFF", weight = 2 },
	fresh_fade = { name = "Fresh Fade", rarity = "Common", income = 3, attack = 11, defense = 5, health = 75, speed = 16, ability = "Spotlight", color = "82E5CD", weight = 1 },
	pose_apprentice = { name = "Pose Apprentice", rarity = "Common", income = 2.5, attack = 10, defense = 7, health = 80, speed = 10, ability = "Perfect Pose", color = "F5A5CA", weight = 1 },
	jawline_junior = { name = "Jawline Junior", rarity = "Uncommon", income = 7, attack = 20, defense = 8, health = 105, speed = 17, ability = "Strong Jaw", color = "6FD9A6", weight = 1 },
	gym_bro = { name = "Gym Bro", rarity = "Uncommon", income = 9, attack = 23, defense = 9, health = 115, speed = 12, ability = "Intimidate", color = "FFAD74", weight = 1 },
	runway_rookie = { name = "Runway Rookie", rarity = "Rare", income = 20, attack = 32, defense = 13, health = 145, speed = 26, ability = "Spotlight", color = "76BAFF", weight = 1 },
	chiseled_champion = { name = "Chiseled Champion", rarity = "Rare", income = 23, attack = 28, defense = 21, health = 170, speed = 17, ability = "Perfect Pose", color = "6AD6F1", weight = 1 },
	golden_chad = { name = "Golden Chad", rarity = "Mythic", income = 65, attack = 48, defense = 21, health = 205, speed = 25, ability = "Spotlight", color = "FFD46A", weight = 1 },
	mog_king = { name = "Mog King", rarity = "Mythic", income = 75, attack = 55, defense = 22, health = 215, speed = 23, ability = "Intimidate", color = "C098FF", weight = 1 },
	divine_icon = { name = "Divine Icon", rarity = "Divine", income = 180, attack = 76, defense = 34, health = 290, speed = 34, ability = "Final Form", color = "FFE5A6", weight = 1 },
	celestial_stylist = { name = "Celestial Stylist", rarity = "Divine", income = 165, attack = 66, defense = 39, health = 305, speed = 36, ability = "Perfect Pose", color = "B1ECFF", weight = 1 },
	apex_mogger = { name = "Apex Mogger", rarity = "Ascended", income = 500, attack = 110, defense = 48, health = 410, speed = 45, ability = "Final Form", color = "FF8BD9", weight = 1 },
}

-- Stable characterId is a collectible FORM; identity, form and mutation are separate.
-- Existing IDs/stats are retained so version-1 saves remain valid.
local characters: any = Config.Characters
for id, metadata in Catalog.Existing do
	if characters[id] then
		for key, value in metadata do characters[id][key] = value end
	end
end
for id, definition in Catalog.Added do
	assert(Config.Characters[id] == nil, "Catalog cannot replace a saved character ID")
	characters[id] = table.clone(definition)
end
for id, definition in Config.Characters do
	local visual = Visuals.get(id)
	local entry: any = definition
	entry.portraitAssetId = visual.portraitAssetId
	entry.enabled = visual.enabled
	entry.mutationEligible = visual.mutationEligible
	entry.modelKey = visual.modelKey
	entry.referenceType = visual.referenceType
end

Config.World = {
	MaxStaticParts = 1800, MaxLights = 24, MaxParticleEmitters = 24,
	MaxVisibleAnimations = 48, EffectDistance = 140, ReducedEffectDistance = 70,
	MaxParticlesPerEmitter = 5, PlotColumnsX = 190, PlotRowSpacing = 60,
}

Config.RealMoggers = {}
local realMoggers: any = Config.RealMoggers
for _, entry in PortraitRegistry.all() do
	realMoggers[entry.id] = entry
	-- Keep known form IDs even while disabled: withdrawing a photo must not delete ownership.
	characters[entry.id] = {
			name = entry.displayName, rarity = entry.rarity, income = entry.income,
			attack = entry.attack, defense = entry.defense, health = entry.health,
			speed = entry.speed, ability = entry.ability, color = "FFD66B", weight = entry.weight,
			identityId = entry.identityId, form = entry.variant, description = entry.notes,
			portraitAssetId = entry.portraitAssetId, enabled = entry.obtainable, mutationEligible = true,
			referenceType = "RealPerson", modelKey = entry.modelKey,
	}
end

-- Mutation weights total 100. Mutation rolls are independent of rarity and luck.
Config.Mutations = {
	{ id = "Normal", name = "Normal", weight = 93, income = 1, power = 1, color = "DCE3F3" },
	{ id = "Golden", name = "Golden", weight = 5, income = 2, power = 1.2, color = "FFD66B" },
	{ id = "Diamond", name = "Diamond", weight = 1.5, income = 3, power = 1.4, color = "7EF2FF" },
	{ id = "Legendary", name = "Legendary", weight = 0.45, income = 5, power = 1.7, color = "C58AFF" },
	{ id = "Apex", name = "Apex", weight = 0.05, income = 10, power = 2, color = "FF83CA" },
}

-- Pet bonuses add together, then cap at MaxPetBonus; they never multiply each other.
Config.Pets = {
	lucky_cat = { name = "Lucky Cat", cost = 500, incomeBonus = 0.05, luckBonus = 0.10, powerBonus = 0, color = "CAB4FF" },
	mini_gym_bro = { name = "Mini Gym Bro", cost = 1200, incomeBonus = 0.10, luckBonus = 0, powerBonus = 0.10, color = "FFAD74" },
	golden_duck = { name = "Golden Duck", cost = 3500, incomeBonus = 0.20, luckBonus = 0.10, powerBonus = 0, color = "FFD66B" },
	diamond_dog = { name = "Diamond Dog", cost = 9000, incomeBonus = 0.15, luckBonus = 0.20, powerBonus = 0.10, color = "7EF2FF" },
	crowned_dragon = { name = "Crowned Dragon", cost = 25000, incomeBonus = 0.25, luckBonus = 0.25, powerBonus = 0.15, color = "FF83CA" },
}

Config.Upgrades = {
	slots = { baseCost = 500, costGrowth = 2, maxLevel = 7 },
	luck = { baseCost = 250, costGrowth = 1.75, maxLevel = 20 },
	petSlots = { baseCost = 5000, costGrowth = 4, maxLevel = 2 },
}

Config.Progression = {
	{ name = "Beginner", income = 0, unique = 0, wins = 0, cost = 0, color = "DCE3F3" },
	{ name = "Rising Mogger", income = 15, unique = 3, wins = 1, cost = 500, color = "71E4AB" },
	{ name = "Elite Mogger", income = 50, unique = 5, wins = 3, cost = 2500, color = "55B8FF" },
	{ name = "Legendary Mogger", income = 120, unique = 7, wins = 7, cost = 10000, color = "C58AFF" },
	{ name = "Divine Mogger", income = 250, unique = 9, wins = 12, cost = 30000, color = "FFD66B" },
	{ name = "Ascended Mogger", income = 500, unique = 10, wins = 20, cost = 100000, color = "FF83CA" },
}

Config.Shop = {
	-- IDs remain zero until the owner configures real products. Paid luck is disabled.
	GamePasses = { VIP = 0, AutoSkip = 0 },
	DeveloperProducts = {},
	PaidLuckEnabled = false,
}

return Config
