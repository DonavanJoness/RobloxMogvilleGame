-- Production progression/battle services against explicit Roblox service doubles.
local Runtime = require("./runtime")
local Config = require("../src/shared/Config")
local Rules = require("../src/shared/Rules")
local ProgressionService = require("../src/server/Services/ProgressionService")
local BattleService = require("../src/server/Services/BattleService")
local SocialBonusService = require("../src/server/Services/SocialBonusService")

local function fresh()
	Runtime.reset({ studio = true })
	local player = Runtime.player()
	local function uid() return Runtime.game:GetService("HttpService"):GenerateGUID(false) end
	local profile = Rules.newProfile(uid, os.time())
	local data = { profiles = { [player] = profile } }
	function data:get(who) return self.profiles[who] end
	return player, profile, data, uid
end

local function add(profile, id, uid)
	local instance = { uid = uid, characterId = id, mutation = "Normal", level = 1, acquiredAt = os.time() }
	table.insert(profile.characters, instance)
	return instance
end

return function(test)
	test("pet purchases validate costs and never charge failed requests", function()
		local player, profile, data = fresh()
		local service = ProgressionService.new(data)
		profile.coins = 2000
		local before = profile.coins
		assert(not service:buyPet(player, "fake_pet"))
		assert(profile.coins == before and #profile.pets == 0)
		assert(service:buyPet(player, "lucky_cat"))
		assert(profile.coins == before - Config.Pets.lucky_cat.cost)
		assert(#profile.pets == 1 and #profile.equippedPets == 1)
		profile.coins = 0
		assert(not service:buyPet(player, "lucky_cat"))
		assert(profile.coins == 0 and #profile.pets == 1)
	end)
	test("pet acquisition and persistence share the same inventory cap", function()
		local player, profile, data, uid = fresh()
		profile.coins = 1000000
		local service = ProgressionService.new(data)
		for _ = 1, Config.Game.PetInventoryLimit do assert(service:buyPet(player, "lucky_cat")) end
		local balance = profile.coins
		assert(not service:buyPet(player, "lucky_cat"))
		assert(profile.coins == balance)
		local saved = Rules.sanitize(Runtime.copy(profile), uid, os.time())
		assert(#saved.pets == Config.Game.PetInventoryLimit)
		local seen = {}
		for _, pet in saved.pets do assert(not seen[pet.uid]); seen[pet.uid] = true end
	end)
	test("pet equipment enforces ownership duplicate protection and slot upgrades", function()
		local player, profile, data = fresh()
		profile.coins = 10000
		local service = ProgressionService.new(data)
		for _ = 1, 3 do assert(service:buyPet(player, "lucky_cat")) end
		assert(not service:equipPet(player, "forged-uid"))
		assert(not service:equipPet(player, profile.pets[1].uid))
		assert(not service:equipPet(player, profile.pets[2].uid))
		profile.upgrades.petSlots = 2
		assert(service:equipPet(player, profile.pets[2].uid))
		assert(service:equipPet(player, profile.pets[3].uid))
		assert(#profile.equippedPets == 3)
		assert(service:unequipPet(player, profile.pets[2].uid))
		assert(not service:unequipPet(player, profile.pets[2].uid))
	end)
	test("quest rewards require server progress and can only be claimed once", function()
		local player, profile, data, uid = fresh()
		local service = ProgressionService.new(data)
		local balance = profile.coins
		assert(not service:claimQuest(player, "first_placement"))
		assert(not service:claimQuest(player, { id = "first_placement", progress = 100 }))
		assert(profile.coins == balance)
		table.insert(profile.placed, profile.characters[1].uid)
		assert(service:claimQuest(player, "first_placement"))
		local rewarded = profile.coins
		assert(rewarded > balance and not service:claimQuest(player, "first_placement"))
		assert(profile.coins == rewarded)
		local restored = Rules.sanitize(Runtime.copy(profile), uid, os.time())
		assert(restored.quests.claimed.first_placement)
	end)
	test("only a successful first-win quest claim can trigger a trusted event", function()
		local player, profile, data = fresh()
		local service, social = ProgressionService.new(data), SocialBonusService.new()
		assert(not service:claimQuest(player, "first_win"))
		assert(social:getServerLuck().bonus == 0)
		profile.stats.pveWins = 1
		assert(service:claimQuest(player, "first_win"))
		assert(social:activateEarnedBoost(player))
		local boost = social:getServerLuck()
		assert(boost.bonus == 0.25 and boost.expiresAt > os.time())
		assert(not service:claimQuest(player, "first_win"))
		assert(not social:activateEarnedBoost(player))
		assert(social:getServerLuck().expiresAt == boost.expiresAt)
	end)
	test("ascension requires every milestone and grants one bounded display slot", function()
		local player, profile, data = fresh()
		local service = ProgressionService.new(data)
		profile.coins = 1000
		local balance = profile.coins
		assert(not service:ascend(player))
		assert(profile.coins == balance and profile.ascension == 0)
		local gym = add(profile, "gym_bro", "gym")
		local runway = add(profile, "runway_rookie", "runway")
		profile.placed = { profile.characters[1].uid, gym.uid, runway.uid }
		profile.stats.pveWins = 1
		assert(service:ascend(player))
		assert(profile.ascension == 1 and profile.upgrades.slots == 1)
		assert(profile.coins == balance - Config.Progression[2].cost)
		local rank = service:rank(profile)
		assert(rank.name == Config.Progression[2].name and rank.next.name == Config.Progression[3].name)
	end)
	test("battle victory grants Coins and win progress exactly once", function()
		local player, profile, data = fresh()
		local apex = add(profile, "apex_mogger", "apex")
		profile.team = { apex.uid }
		local service = BattleService.new(data)
		assert(service:start(player, 1))
		local state = service:get(player)
		assert(state.player.units[1].name == Config.Characters.apex_mogger.name)
		local balance, reward = profile.coins, state.reward
		assert(service:act(player, "attack"))
		assert(state.finished and state.winner == "player")
		assert(profile.coins == balance + reward and profile.stats.pveWins == 1)
		assert(not service:act(player, "attack"))
		assert(profile.coins == balance + reward and profile.stats.pveWins == 1)
	end)
	test("battle starts validate unlocks and enforce a start cooldown", function()
		local player, profile, data = fresh()
		local service = BattleService.new(data)
		assert(not service:start(player, 2))
		assert(not service:start(player, 0 / 0))
		assert(profile.stats.battles == 0)
		assert(service:start(player, 1))
		assert(not service:start(player, 1))
		assert(service:leave(player))
		assert(not service:start(player, 1))
		assert(profile.stats.battles == 1)
	end)
	test("idle battle timeout reports changed players once and grants no rewards", function()
		local player, profile, data = fresh()
		local service = BattleService.new(data)
		assert(service:start(player, 1))
		local balance = profile.coins
		local state = service:get(player)
		local changed = service:tick(state.lastActionAt + 120)
		assert(#changed == 1 and changed[1] == player)
		assert(state.finished and state.winner == "enemy")
		assert(#service:tick(state.lastActionAt + 121) == 0)
		assert(profile.coins == balance and profile.stats.pveWins == 0)
	end)
	test("friend bonuses include only verified friends still in this server", function()
		local player = fresh()
		local second, third = Runtime.player(456), Runtime.player(789)
		local players = Runtime.game:GetService("Players")
		local previous = players.GetPlayers
		local present = { player, second, third }
		function players:GetPlayers() return present end
		function player:IsFriendsWith(userId)
			if userId == third.UserId then error("simulated friendship lookup failure") end
			return userId == second.UserId
		end
		local service = SocialBonusService.new()
		service:refresh(player)
		assert(service:get(player) == 1)
		present = { player, third }
		assert(service:get(player) == 0)
		players.GetPlayers = previous
	end)
end
