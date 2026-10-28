-- Save compatibility and reward metadata checks use the real gameplay modules.
local Config = require("../src/shared/Config")
local Catalog = require("../src/shared/CharacterCatalog")
local Rules = require("../src/shared/Rules")
local Combat = require("../src/shared/Combat")

local function close(actual, expected)
	assert(math.abs(actual - expected) < 1e-9, tostring(actual) .. " differs from " .. tostring(expected))
end

-- Always restore mutable configuration, including when an assertion fails.
local function withFields(patches, callback)
	local originals = {}
	for _, patch in patches do
		for key, value in patch.values do
			table.insert(originals, { target = patch.target, key = key, value = patch.target[key] })
			patch.target[key] = value
		end
	end
	local ok, problem = pcall(callback)
	for index = #originals, 1, -1 do
		local previous = originals[index]
		previous.target[previous.key] = previous.value
	end
	if not ok then error(problem, 0) end
end

local function mass(outcomes, characterId, mutation)
	local total = 0
	for _, outcome in outcomes do
		if (not characterId or outcome.characterId == characterId) and (not mutation or outcome.mutation == mutation) then
			total += outcome.probability
		end
	end
	return total
end

local function midpoint(outcomes, characterId, mutation)
	local cumulative = 0
	for _, outcome in outcomes do
		if outcome.characterId == characterId and outcome.mutation == mutation then
			return cumulative + outcome.probability / 2
		end
		cumulative += outcome.probability
	end
	error("Requested reward is not eligible: " .. characterId .. "/" .. mutation)
end

return function(test)
	local nextId = 0
	local function uid()
		nextId += 1
		return "visual-rules-" .. tostring(nextId)
	end
	local function fresh() return Rules.newProfile(uid, 1000) end

	test("metadata configuration patches are restored even after a failing assertion", function()
		local character = Config.Characters.young_rookie
		local previous = character.enabled
		local ok = pcall(function()
			withFields({ { target = character, values = { enabled = false, temporaryTestField = true } } }, function()
				assert(character.enabled == false and character.temporaryTestField == true)
				error("intentional restoration probe")
			end)
		end)
		assert(not ok and character.enabled == previous and character.temporaryTestField == nil)
	end)

	test("legacy schema-one instances gain catalog metadata without losing ownership or progress", function()
		local legacy = fresh()
		legacy.characters = {}
		local ids = {}
		for id in Catalog.Existing do table.insert(ids, id) end
		table.sort(ids)
		for index, id in ids do
			table.insert(legacy.characters, {
				uid = "legacy-" .. id, characterId = id, mutation = if index % 2 == 0 then "Golden" else "Normal",
				level = 2, acquiredAt = 800,
			})
		end
		legacy.coins = 12345
		legacy.placed = { legacy.characters[1].uid, legacy.characters[2].uid, legacy.characters[3].uid }
		legacy.team = { legacy.characters[4].uid, legacy.characters[5].uid }
		legacy.pity = { rare = 7, mythic = 65 }
		legacy.upgrades.luck = 3
		legacy.stats.rolls = 43
		legacy.quests.claimed.roll_5 = true
		legacy.settings.lowEffects = nil -- This option did not exist in the old schema.
		local restored = Rules.sanitize(legacy, uid, 2000)
		assert(restored.schemaVersion == 1 and #restored.characters == 12 and restored.coins == legacy.coins)
		for index, saved in legacy.characters do
			local actual, expected = restored.characters[index], Config.Characters[saved.characterId]
			assert(actual.uid == saved.uid and actual.characterId == saved.characterId)
			assert(actual.identityId == expected.identityId and actual.form == expected.form)
			assert(actual.mutation == saved.mutation and actual.level == 2 and actual.acquiredAt == 800)
		end
		for index, placed in legacy.placed do assert(restored.placed[index] == placed) end
		for index, member in legacy.team do assert(restored.team[index] == member) end
		assert(restored.pity.rare == 7 and restored.pity.mythic == 65 and restored.upgrades.luck == 3)
		assert(restored.stats.rolls == 43 and restored.quests.claimed.roll_5 and restored.settings.lowEffects == false)
	end)

	test("saved identity and form are rederived rather than trusted or used to rebind a character", function()
		local profile = fresh()
		profile.characters = { {
			uid = "owned-prime", characterId = "rookie_prime", identityId = "royalty", form = "Ascended",
			mutation = "Diamond", level = 4, acquiredAt = 900,
		} }
		profile.placed, profile.team = { "owned-prime" }, { "owned-prime" }
		local restored = Rules.sanitize(profile, uid, 2000)
		local actual, definition = restored.characters[1], Config.Characters.rookie_prime
		assert(actual.uid == "owned-prime" and actual.characterId == "rookie_prime")
		assert(actual.identityId == definition.identityId and actual.form == definition.form)
		assert(actual.mutation == "Diamond" and actual.level == 4)
		assert(restored.placed[1] == "owned-prime" and restored.team[1] == "owned-prime")
		local stats = Rules.characterStats(profile.characters[1])
		assert(stats.identityId == definition.identityId and stats.form == definition.form)
		assert(stats.characterId == "rookie_prime" and stats.rarity == definition.rarity)
	end)

	test("new starter instances include their catalog identity and form", function()
		local starter = fresh().characters[1]
		local definition = Config.Characters[Config.Game.StarterCharacter]
		assert(starter.characterId == Config.Game.StarterCharacter and starter.identityId == definition.identityId)
		assert(starter.form == definition.form and starter.mutation == "Normal")
	end)

	test("every eligible outcome awards matching identity and form with an independent mutation", function()
		local outcomes = Rules.odds(fresh())
		local checked = 0
		for _, expected in outcomes do
			local profile = fresh()
			local draw = midpoint(outcomes, expected.characterId, expected.mutation)
			local result = Rules.roll(profile, 1, function() return draw end, uid, 1000)
			assert(result.ok and #result.rewards == 1)
			local reward = result.rewards[1]
			local definition = Config.Characters[expected.characterId]
			assert(reward.characterId == expected.characterId and reward.mutation == expected.mutation)
			assert(reward.identityId == definition.identityId and reward.form == definition.form)
			assert(profile.characters[2] == reward and reward.uid ~= profile.characters[1].uid)
			local stats = Rules.characterStats(reward)
			assert(stats.rarity == expected.rarity and stats.form == definition.form and stats.mutation == expected.mutation)
			checked += 1
		end
		assert(checked >= 24 * #Config.Mutations)
	end)

	test("disabling a candidate removes its odds while preserving owned copies and normalized rarity odds", function()
		local profile = fresh()
		profile.characters[2] = { uid = "disabled-owned", characterId = "rookie_prime", mutation = "Golden", level = 1, acquiredAt = 900 }
		profile.placed = { "disabled-owned" }
		local priorIncome = Rules.income(profile)
		withFields({ { target = Config.Characters.rookie_prime, values = { enabled = false } } }, function()
			local outcomes = Rules.odds(profile)
			close(mass(outcomes), 1)
			close(mass(outcomes, "rookie_prime"), 0)
			local rareTotal = 0
			for _, outcome in outcomes do if outcome.rarity == "Rare" then rareTotal += outcome.probability end end
			close(rareTotal, 0.12)
			local restored = Rules.sanitize(profile, uid, 2000)
			assert(#restored.characters == 2 and restored.characters[2].uid == "disabled-owned")
			assert(restored.characters[2].identityId == Config.Characters.rookie_prime.identityId)
			close(Rules.income(restored), priorIncome)
		end)
	end)

	test("an entirely disabled rarity redistributes eligible probability without breaking pity", function()
		local patches = {}
		for _, definition in Config.Characters do
			if definition.rarity == "Rare" then table.insert(patches, { target = definition, values = { enabled = false } }) end
		end
		withFields(patches, function()
			local profile = fresh()
			for _, pity in { 0, Config.Game.RarePity - 1 } do
				profile.pity.rare = pity
				local outcomes = Rules.odds(profile)
				close(mass(outcomes), 1)
				for _, outcome in outcomes do
					assert(outcome.rarity ~= "Rare")
					if pity > 0 then assert(outcome.rarity ~= "Common" and outcome.rarity ~= "Uncommon") end
				end
			end
		end)
	end)

	test("mutation-ineligible forms receive Normal with conditional probability one", function()
		local baseline = mass(Rules.odds(fresh()), "rookie_prime")
		withFields({ { target = Config.Characters.rookie_prime, values = { mutationEligible = false } } }, function()
			local profile = fresh()
			local outcomes = Rules.odds(profile)
			close(mass(outcomes), 1)
			close(mass(outcomes, "rookie_prime", "Normal"), baseline)
			local rows = 0
			for _, outcome in outcomes do
				if outcome.characterId == "rookie_prime" then rows += 1; assert(outcome.mutation == "Normal") end
			end
			assert(rows == 1)
			local draw = midpoint(outcomes, "rookie_prime", "Normal")
			local result = Rules.roll(profile, 1, function() return draw end, uid, 1000)
			assert(result.ok and result.rewards[1].characterId == "rookie_prime" and result.rewards[1].mutation == "Normal")
		end)
	end)

	test("a mutation-ineligible form remains Normal even when Normal has zero random mutation weight", function()
		local normal
		for _, mutation in Config.Mutations do if mutation.id == "Normal" then normal = mutation end end
		assert(normal)
		local baseline = mass(Rules.odds(fresh()), "rookie_prime")
		withFields({
			{ target = Config.Characters.rookie_prime, values = { mutationEligible = false } },
			{ target = normal, values = { weight = 0 } },
		}, function()
			local outcomes = Rules.odds(fresh())
			close(mass(outcomes), 1)
			close(mass(outcomes, "rookie_prime", "Normal"), baseline)
			for _, outcome in outcomes do
				if outcome.characterId ~= "rookie_prime" then assert(outcome.mutation ~= "Normal") end
			end
		end)
	end)

	test("low-effects settings round-trip and old or malformed values use a boolean default", function()
		local profile = fresh()
		assert(profile.settings.lowEffects == false)
		profile.settings.lowEffects = true
		profile.settings.reducedMotion = true
		local restored = Rules.sanitize(profile, uid, 2000)
		assert(restored.settings.lowEffects == true and restored.settings.reducedMotion == true)
		for _, invalid in { "true", 1, {}, false } do
			profile.settings.lowEffects = invalid
			assert(Rules.sanitize(profile, uid, 2000).settings.lowEffects == false)
		end
		profile.settings.lowEffects = nil
		assert(Rules.sanitize(profile, uid, 2000).settings.lowEffects == false)
	end)

	test("combat units retain stable portrait identity, form and mutation from character stats", function()
		for id, definition in Config.Characters do
			local stats = Rules.characterStats({ uid = "combat-" .. id, characterId = id, mutation = "Diamond", level = 1 })
			stats.portraitAssetId = 123456789
			local fighter = Combat.unit(stats, 0.2)
			assert(fighter.uid == stats.uid and fighter.characterId == id)
			assert(fighter.identityId == definition.identityId and fighter.form == definition.form)
			assert(fighter.portraitAssetId == 123456789 and fighter.mutation == "Diamond")
			assert(fighter.name == stats.name and fighter.ability == stats.ability and fighter.hp == fighter.maxHp)
			assert(fighter.attack == math.ceil(stats.attack * 1.2))
		end
	end)
end
