-- The runner rewrites Roblox sibling requires into filesystem requires in a temp directory.
local Config = require("../src/shared/Config")
local Rules = require("../src/shared/Rules")

return function(test)
	local uidNumber = 0
	local function uid()
		uidNumber += 1
		return "test-" .. tostring(uidNumber)
	end
	local function fresh() return Rules.newProfile(uid, 1000) end
	local function close(actual, expected)
		assert(math.abs(actual - expected) < 1e-9, tostring(actual) .. " differs from " .. tostring(expected))
	end
	test("base probabilities and mutations normalize to one", function()
		local p, total, rarityTotals = fresh(), 0, {}
		for _, outcome in Rules.odds(p) do
			assert(outcome.probability > 0)
			total += outcome.probability
			rarityTotals[outcome.rarity] = (rarityTotals[outcome.rarity] or 0) + outcome.probability
		end
		close(total, 1)
		for _, rarity in Config.Rarities do close(rarityTotals[rarity.id], rarity.weight / 100) end
	end)
	test("luck shifts probability toward higher tiers and stays normalized", function()
		local p, total, boostedAscended = fresh(), 0, 0
		p.upgrades.luck = 5
		close(Rules.luck(p), 1.5)
		for _, outcome in Rules.odds(p) do
			total += outcome.probability
			if outcome.rarity == "Ascended" then boostedAscended += outcome.probability end
		end
		close(total, 1)
		assert(boostedAscended > 0.005)
	end)
	test("rare and mythic pity filter the exact next draw", function()
		local p = fresh()
		p.pity.rare = 19
		for _, outcome in Rules.odds(p) do assert(outcome.rarity ~= "Common" and outcome.rarity ~= "Uncommon") end
		p.pity.mythic = 99
		for _, outcome in Rules.odds(p) do assert(outcome.rarity == "Mythic" or outcome.rarity == "Divine" or outcome.rarity == "Ascended") end
	end)
	test("pity updates inside a multi-roll and always triggers by its target", function()
		local p = fresh()
		p.coins = 100000
		local highestRareGap, rareGap, mythicGap = 0, 0, 0
		for _ = 1, 200 do
			local result = Rules.roll(p, 1, function() return 0.999999999 end, uid, 1000)
			assert(result.ok)
			local rarity = Config.Characters[result.rewards[1].characterId].rarity
			rareGap += 1; mythicGap += 1
			if rarity ~= "Common" and rarity ~= "Uncommon" then highestRareGap = math.max(highestRareGap, rareGap); rareGap = 0 end
			if rarity == "Mythic" or rarity == "Divine" or rarity == "Ascended" then assert(mythicGap <= 100); mythicGap = 0 end
			assert(rareGap < 20 and mythicGap < 100)
		end
		assert(highestRareGap <= 20)
	end)
	test("unaffordable and full-inventory rolls are atomic", function()
		local p = fresh()
		p.coins = 499
		local originalUid, coins = p.characters[1].uid, p.coins
		local result = Rules.roll(p, 10, function() error("must not call RNG") end, uid, 1000)
		assert(not result.ok and p.coins == coins and #p.characters == 1 and p.stats.rolls == 0)
		assert(p.characters[1].uid == originalUid)
		p.coins = 100000
		for _ = 2, Config.Game.InventoryLimit do table.insert(p.characters, { uid = uid(), characterId = "young_rookie", mutation = "Normal", level = 1, acquiredAt = 1000 }) end
		result = Rules.roll(p, 1, function() error("must not call RNG") end, uid, 1000)
		assert(not result.ok and p.coins == 100000 and #p.characters == Config.Game.InventoryLimit)
	end)
	test("invalid counts and invalid RNG never spend currency", function()
		local p = fresh()
		p.coins = 1000
		for _, count in { -1, 0, 2, 1.5, math.huge, 0 / 0 } do assert(not Rules.roll(p, count, math.random, uid, 1000).ok) end
		local ok = pcall(function() Rules.roll(p, 10, function() return 0 / 0 end, uid, 1000) end)
		assert(not ok and p.coins == 1000 and #p.characters == 1 and p.stats.rolls == 0)
	end)
	test("income counts only placed owned characters once, with additive pets", function()
		local p = fresh()
		close(Rules.income(p), 0)
		p.placed = { p.characters[1].uid, p.characters[1].uid, "not-owned" }
		close(Rules.income(p), 2)
		p.characters[1].mutation = "Golden"
		close(Rules.income(p), 4)
		p.pets = { { uid = uid(), petId = "lucky_cat" }, { uid = uid(), petId = "golden_duck" } }
		p.equippedPets = { p.pets[1].uid, p.pets[2].uid }
		close(Rules.income(p), 5)
	end)
	test("multi-roll adds ten independently identified instances", function()
		local p = fresh()
		p.coins = 1000
		local result = Rules.roll(p, 10, function() return 0.5 end, uid, 1000)
		assert(result.ok and #result.rewards == 10 and #p.characters == 11 and p.coins == 500 and p.stats.rolls == 10)
		local seen = {}
		for _, instance in p.characters do assert(not seen[instance.uid]); seen[instance.uid] = true end
	end)
	test("a broken ID provider cannot duplicate rewards or partially charge", function()
		local p = fresh()
		p.coins = 1000
		local existing = p.characters[1].uid
		local ok = pcall(function()
			Rules.roll(p, 10, function() return 0.5 end, function() return existing end, 1000)
		end)
		assert(not ok and p.coins == 1000 and #p.characters == 1 and p.stats.rolls == 0)
	end)
	test("multi-roll applies pity separately to each reward", function()
		local p = fresh()
		p.coins = 1000; p.pity.rare = 18
		local result = Rules.roll(p, 10, function() return 0.999999999 end, uid, 1000)
		assert(result.ok)
		local first = Config.Characters[result.rewards[1].characterId].rarity
		local second = Config.Characters[result.rewards[2].characterId].rarity
		assert(first == "Common" or first == "Uncommon")
		assert(second ~= "Common" and second ~= "Uncommon")
		assert(p.pity.rare == 8)
	end)
	test("profile serialization round-trip preserves progress and valid references", function()
		local p = fresh()
		p.coins = 942; p.placed = { p.characters[1].uid }; p.upgrades.luck = 3
		p.settings.reducedMotion = true; p.quests.claimed.roll_5 = true; p.stats.pveWins = 4
		local restored = Rules.sanitize(p, uid, 2000)
		assert(restored.coins == 942 and restored.characters[1].uid == p.characters[1].uid)
		assert(restored.placed[1] == p.placed[1] and restored.team[1] == p.team[1])
		assert(restored.upgrades.luck == 3 and restored.settings.reducedMotion and restored.quests.claimed.roll_5 and restored.stats.pveWins == 4)
	end)
	test("sanitization removes bad references, NaN, duplicate ids and unsupported fields", function()
		local p = fresh()
		p.coins = 0 / 0
		p.characters[2] = table.clone(p.characters[1])
		p.placed = { p.characters[1].uid, p.characters[1].uid, "bogus" }
		p.team = { "bogus" }
		p.upgrades.slots = math.huge
		p.settings.sound = "yes"
		p.unknown = "do not serialize"
		local restored = Rules.sanitize(p, uid, 2000)
		assert(restored.coins == Config.Game.StartingCoins and restored.upgrades.slots == 0 and restored.settings.sound == true)
		assert(#restored.characters == 2 and restored.characters[1].uid ~= restored.characters[2].uid)
		assert(#restored.placed == 1 and #restored.team == 1 and restored.unknown == nil)
	end)
	test("sanitized data contains only finite JSON-compatible values", function()
		local p = Rules.sanitize(fresh(), uid, 2000)
		local seen = {}
		local function walk(value)
			local kind = type(value)
			assert(kind == "table" or kind == "number" or kind == "boolean" or kind == "string")
			if kind == "number" then assert(value == value and math.abs(value) < math.huge) end
			if kind == "table" then
				assert(not seen[value], "No cycles or shared mutable containers")
				seen[value] = true
				for key, item in value do
					assert(type(key) == "string" or (type(key) == "number" and key >= 1 and key % 1 == 0))
					walk(item)
				end
			end
		end
		walk(p)
	end)
end
