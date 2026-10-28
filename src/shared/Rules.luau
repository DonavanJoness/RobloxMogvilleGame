--!strict
-- Deterministic game rules, deliberately independent of Roblox services.
local Config: any = require(script.Parent.Config)
local Rules = {}

local rarityIndex = {}
local mutationById = {}
local characterIds = {}
for index, rarity in Config.Rarities do rarityIndex[rarity.id] = index end
for _, mutation in Config.Mutations do mutationById[mutation.id] = mutation end
for id in Config.Characters do table.insert(characterIds, id) end
table.sort(characterIds)

local function finite(value: any, fallback: number, minimum: number, maximum: number): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return fallback end
	return math.clamp(value, minimum, maximum)
end

local function integer(value: any, fallback: number, minimum: number, maximum: number): number
	return math.floor(finite(value, fallback, minimum, maximum))
end

local function validUid(value: any): boolean
	return type(value) == "string" and #value > 0 and #value <= 100
end

local function uniqueUid(factory: () -> string, seen: { [string]: boolean }): string
	for _ = 1, 20 do
		local uid = factory()
		if validUid(uid) and not seen[uid] then seen[uid] = true; return uid end
	end
	error("Unique ID provider did not produce a fresh ID")
end

local function safeTable(value: any): any
	return if type(value) == "table" then value else {}
end

local function referenceList(raw: any, owned: { [string]: boolean }, maximum: number): { string }
	local result, seen = {}, {}
	for _, uid in safeTable(raw) do
		if #result >= maximum then break end
		if validUid(uid) and owned[uid] and not seen[uid] then
			seen[uid] = true
			table.insert(result, uid)
		end
	end
	return result
end

function Rules.newProfile(newUid: () -> string, now: number): any
	local definition = Config.Characters[Config.Game.StarterCharacter]
	local starter = { uid = newUid(), characterId = Config.Game.StarterCharacter,
		identityId = definition.identityId, form = definition.form, mutation = "Normal", level = 1, acquiredAt = now }
	return {
		schemaVersion = 1, coins = Config.Game.StartingCoins,
		characters = { starter }, placed = {}, team = { starter.uid },
		pets = {}, equippedPets = {}, upgrades = { slots = 0, luck = 0, petSlots = 0 },
		pity = { rare = 0, mythic = 0 },
		stats = { rolls = 0, totalEarned = 0, pveWins = 0, battles = 0, peakIncome = 0 },
		quests = { claimed = {} }, ascension = 0,
		settings = { reducedMotion = false, sound = true, autoSkip = false, lowEffects = false },
		lastSeen = now,
	}
end

-- Sanitizes data only after a successful load. A failed load must never call this as a default save.
function Rules.sanitize(raw: any, newUid: () -> string, now: number): any
	if type(raw) ~= "table" then return Rules.newProfile(newUid, now) end
	local profile = Rules.newProfile(newUid, now)
	profile.coins = finite(raw.coins, Config.Game.StartingCoins, 0, Config.Game.MaxCurrency)
	local upgrades = safeTable(raw.upgrades)
	profile.upgrades.slots = integer(upgrades.slots, 0, 0, Config.Game.MaxSlots - Config.Game.BaseSlots)
	profile.upgrades.luck = integer(upgrades.luck, 0, 0, Config.Upgrades.luck.maxLevel)
	profile.upgrades.petSlots = integer(upgrades.petSlots, 0, 0, Config.Game.MaxPetSlots - 1)
	local seen, owned, petsOwned = {}, {}, {}
	profile.characters = {}
	for _, instance in safeTable(raw.characters) do
		if #profile.characters >= Config.Game.InventoryLimit then break end
		if type(instance) == "table" and Config.Characters[instance.characterId] then
			local uid = instance.uid
			if not validUid(uid) or seen[uid] then uid = uniqueUid(newUid, seen) else seen[uid] = true end
			local item = {
				uid = uid, characterId = instance.characterId,
				identityId = Config.Characters[instance.characterId].identityId,
				form = Config.Characters[instance.characterId].form,
				mutation = if mutationById[instance.mutation] then instance.mutation else "Normal",
				level = integer(instance.level, 1, 1, 100),
				acquiredAt = integer(instance.acquiredAt, now, 0, now),
			}
			table.insert(profile.characters, item)
			owned[uid] = true
		end
	end
	if #profile.characters == 0 then
		local starter = Rules.newProfile(newUid, now).characters[1]
		table.insert(profile.characters, starter)
		owned[starter.uid] = true
		seen[starter.uid] = true
	end
	profile.placed = referenceList(raw.placed, owned, Config.Game.BaseSlots + profile.upgrades.slots)
	profile.team = referenceList(raw.team, owned, 3)
	if #profile.team == 0 then profile.team = { profile.characters[1].uid } end
	profile.pets = {}
	for _, instance in safeTable(raw.pets) do
		if #profile.pets >= Config.Game.PetInventoryLimit then break end
		if type(instance) == "table" and Config.Pets[instance.petId] then
			local uid = instance.uid
			if not validUid(uid) or seen[uid] then uid = uniqueUid(newUid, seen) else seen[uid] = true end
			table.insert(profile.pets, { uid = uid, petId = instance.petId })
			petsOwned[uid] = true
		end
	end
	profile.equippedPets = referenceList(raw.equippedPets, petsOwned, 1 + profile.upgrades.petSlots)
	local pity = safeTable(raw.pity)
	profile.pity.rare = integer(pity.rare, 0, 0, Config.Game.RarePity - 1)
	profile.pity.mythic = integer(pity.mythic, 0, 0, Config.Game.MythicPity - 1)
	local stats = safeTable(raw.stats)
	for key in profile.stats do profile.stats[key] = finite(stats[key], 0, 0, Config.Game.MaxCurrency) end
	profile.ascension = integer(raw.ascension, 0, 0, #Config.Progression - 1)
	profile.lastSeen = integer(raw.lastSeen, now, 0, now)
	local settings = safeTable(raw.settings)
	for key, default in profile.settings do
		profile.settings[key] = if type(settings[key]) == "boolean" then settings[key] else default
	end
	local claimed = safeTable(safeTable(raw.quests).claimed)
	for key, value in claimed do
		if type(key) == "string" and #key <= 80 and value == true then profile.quests.claimed[key] = true end
	end
	return profile
end

function Rules.characterStats(instance: any): any
	local definition = Config.Characters[instance.characterId]
	assert(definition, "Unknown character")
	local mutation = mutationById[instance.mutation] or mutationById.Normal
	local growth = 1 + (math.clamp(instance.level or 1, 1, 100) - 1) * 0.1
	return {
		uid = instance.uid, characterId = instance.characterId,
		identityId = definition.identityId, form = definition.form,
		description = definition.description, portraitAssetId = definition.portraitAssetId,
		enabled = definition.enabled ~= false,
		name = definition.name, rarity = definition.rarity, mutation = mutation.id,
		income = definition.income * mutation.income * growth,
		attack = math.floor(definition.attack * mutation.power * growth),
		defense = math.floor(definition.defense * mutation.power * growth),
		health = math.floor(definition.health * mutation.power * growth),
		speed = definition.speed, ability = definition.ability,
		color = if mutation.id == "Normal" then definition.color else mutation.color,
	}
end

function Rules.petBonuses(profile: any): { income: number, luck: number, power: number }
	local equipped = {}
	for _, uid in profile.equippedPets do equipped[uid] = true end
	local bonuses = { income = 0, luck = 0, power = 0 }
	for _, pet in profile.pets do
		local definition = Config.Pets[pet.petId]
		if equipped[pet.uid] and definition then
			bonuses.income += definition.incomeBonus
			bonuses.luck += definition.luckBonus
			bonuses.power += definition.powerBonus
		end
	end
	bonuses.income = math.min(bonuses.income, Config.Game.MaxPetBonus)
	bonuses.luck = math.min(bonuses.luck, Config.Game.MaxPetBonus)
	bonuses.power = math.min(bonuses.power, Config.Game.MaxPetBonus)
	return bonuses
end

function Rules.income(profile: any): number
	local placed, seen = {}, {}
	for _, uid in profile.placed do placed[uid] = true end
	local income = 0
	for _, instance in profile.characters do
		if placed[instance.uid] and not seen[instance.uid] then
			seen[instance.uid] = true
			income += Rules.characterStats(instance).income
		end
	end
	return income * (1 + Rules.petBonuses(profile).income)
end

function Rules.luck(profile: any, friendCount: number?, serverLuck: number?): number
	return math.clamp(1 + profile.upgrades.luck * Config.Game.LuckPerUpgrade
		+ Rules.petBonuses(profile).luck
		+ math.clamp(friendCount or 0, 0, Config.Game.MaxFriends) * Config.Game.FriendLuck
		+ math.clamp(serverLuck or 0, 0, 2), 1, Config.Game.MaxLuck)
end

-- +50% luck means L=1.5: tier i's base weight is multiplied by L^(i-1).
-- We normalize eligible weights AFTER applying pity; mutation odds remain independent.
function Rules.odds(profile: any, friendCount: number?, serverLuck: number?): { any }
	local minimumTier = 1
	if profile.pity.rare >= Config.Game.RarePity - 1 then minimumTier = 3 end
	if profile.pity.mythic >= Config.Game.MythicPity - 1 then minimumTier = 4 end
	local luck = Rules.luck(profile, friendCount, serverLuck)
	local tierWeights, tierTotal, individualTotals = {}, 0, {}
	for _, id in characterIds do
		local character = Config.Characters[id]
		if character.enabled ~= false and not character.limited then
			individualTotals[character.rarity] = (individualTotals[character.rarity] or 0) + character.weight
		end
	end
	for index, rarity in Config.Rarities do
		local weight = if index >= minimumTier and (individualTotals[rarity.id] or 0) > 0 then rarity.weight * luck ^ (index - 1) else 0
		tierWeights[rarity.id] = weight
		tierTotal += weight
	end
	assert(tierTotal > 0, "No eligible gacha outcomes")
	local mutationTotal = 0
	for _, mutation in Config.Mutations do mutationTotal += mutation.weight end
	assert(mutationTotal > 0, "No eligible mutations")
	local outcomes = {}
	for _, id in characterIds do
		local character = Config.Characters[id]
		if character.enabled ~= false and not character.limited and tierWeights[character.rarity] > 0 then
			for _, mutation in Config.Mutations do
				if (character.mutationEligible == false and mutation.id == "Normal")
					or (character.mutationEligible ~= false and mutation.weight > 0) then
					table.insert(outcomes, {
						characterId = id, rarity = character.rarity, mutation = mutation.id,
						probability = tierWeights[character.rarity] / tierTotal
							* character.weight / individualTotals[character.rarity]
							* (if character.mutationEligible == false then 1 else mutation.weight / mutationTotal),
					})
				end
			end
		end
	end
	return outcomes
end

function Rules.roll(profile: any, count: number, rng: () -> number, newUid: () -> string, now: number, friendCount: number?, serverLuck: number?): any
	if count ~= 1 and count ~= Config.Game.MultiRoll then return { ok = false, error = "Choose a single roll or 10 rolls." } end
	if #profile.characters + count > Config.Game.InventoryLimit then return { ok = false, error = "Your Mogger inventory is full." } end
	local cost = Config.Game.RollCost * count
	if profile.coins < cost then return { ok = false, error = "Not enough Coins." } end
	-- Build a transaction in a copy so a bad RNG or ID provider cannot partially charge a multi-roll.
	local working: any = table.clone(profile)
	working.pity = table.clone(profile.pity)
	local rewards, seen = {}, {}
	for _, instance in profile.characters do seen[instance.uid] = true end
	for _, pet in profile.pets do seen[pet.uid] = true end
	for _ = 1, count do
		local outcomes = Rules.odds(working, friendCount, serverLuck)
		local draw = rng()
		assert(type(draw) == "number" and draw == draw and draw >= 0 and draw < 1, "RNG must return a number in [0, 1)")
		local cumulative, selected = 0, outcomes[#outcomes]
		for _, outcome in outcomes do
			cumulative += outcome.probability
			if draw < cumulative then selected = outcome; break end
		end
		local definition = Config.Characters[selected.characterId]
		local reward = { uid = uniqueUid(newUid, seen), characterId = selected.characterId,
			identityId = definition.identityId, form = definition.form,
			mutation = selected.mutation, level = 1, acquiredAt = now }
		table.insert(rewards, reward)
		local tier = rarityIndex[selected.rarity]
		working.pity.rare = if tier >= 3 then 0 else working.pity.rare + 1
		working.pity.mythic = if tier >= 4 then 0 else working.pity.mythic + 1
	end
	profile.coins -= cost
	profile.pity = working.pity
	profile.stats.rolls += count
	for _, reward in rewards do table.insert(profile.characters, reward) end
	return { ok = true, rewards = rewards }
end

function Rules.collectionCount(profile: any): number
	local seen, count = {}, 0
	for _, instance in profile.characters do
		if not seen[instance.characterId] then seen[instance.characterId] = true; count += 1 end
	end
	return count
end

return Rules
