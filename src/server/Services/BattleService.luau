--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Rules = require(ReplicatedStorage.Shared.Rules)
local Config = require(ReplicatedStorage.Shared.Config)
local Combat = require(ReplicatedStorage.Shared.Combat)

local BattleService = {}
BattleService.__index = BattleService

local OPPONENTS = {
	{ name = "Square Sparring Partner", health = 55, attack = 9, defense = 3, speed = 9, ability = "Strong Jaw", reward = 90, wins = 0 },
	{ name = "District Defender", health = 160, attack = 27, defense = 14, speed = 20, ability = "Perfect Pose", reward = 350, wins = 3 },
	{ name = "Boulevard Champion", health = 320, attack = 60, defense = 30, speed = 31, ability = "Final Form", reward = 1000, wins = 10 },
}

function BattleService.new(data: any)
	return setmetatable({ data = data, battles = {}, nextStart = {} }, BattleService)
end

function BattleService:get(player: Player): any
	return self.battles[player]
end

function BattleService:start(player: Player, difficulty: any): (boolean, string?)
	local profile = self.data:get(player)
	if not profile then return false, "Your profile is not ready." end
	if type(difficulty) ~= "number" or difficulty ~= math.floor(difficulty) or not OPPONENTS[difficulty] then
		return false, "Choose difficulty 1, 2, or 3."
	end
	local existing = self.battles[player]
	if existing and not existing.finished then return false, "Finish or leave your current Mog-Off first." end
	if os.clock() < (self.nextStart[player] or 0) then return false, "The arena is resting. Try again in a few seconds." end
	local enemyDefinition = OPPONENTS[difficulty]
	if profile.stats.pveWins < enemyDefinition.wins then
		return false, "This opponent unlocks after " .. tostring(enemyDefinition.wins) .. " PvE wins."
	end
	local owned, units = {}, {}
	for _, instance in profile.characters do owned[instance.uid] = instance end
	local bonus = Rules.petBonuses(profile).power
	for _, uid in profile.team do
		if owned[uid] and #units < 3 then table.insert(units, Combat.unit(Rules.characterStats(owned[uid]), bonus)) end
	end
	if #units == 0 and profile.characters[1] then table.insert(units, Combat.unit(Rules.characterStats(profile.characters[1]), bonus)) end
	if #units == 0 then return false, "Collect a Mogger before entering the arena." end
	local enemy = Combat.unit({
		uid = "npc", name = enemyDefinition.name, health = enemyDefinition.health,
		attack = enemyDefinition.attack, defense = enemyDefinition.defense, speed = enemyDefinition.speed,
		ability = enemyDefinition.ability,
	}, 0)
	self.battles[player] = {
		id = HttpService:GenerateGUID(false), turn = 1, finished = false,
		message = "Choose an action. Each action advances one round.", log = {},
		player = { active = 1, units = units }, enemy = { active = 1, units = { enemy } },
		reward = enemyDefinition.reward, difficulty = difficulty, lastActionAt = os.time(),
	}
	self.nextStart[player] = os.clock() + 20
	profile.stats.battles += 1
	return true
end

function BattleService:act(player: Player, kind: any, index: any): (boolean, string?)
	local profile, battle = self.data:get(player), self.battles[player]
	if not profile or not battle then return false, "Enter a Mog-Off first." end
	local ok, err = Combat.step(battle, kind, index)
	if not ok then return false, err end
	battle.lastActionAt = os.time()
	if battle.finished and battle.winner == "player" and not battle.rewardGranted then
		-- Award in the same non-yielding critical section as the terminal action.
		battle.rewardGranted = true
		local earned = math.min(Config.Game.MaxCurrency - profile.coins, battle.reward)
		profile.coins += earned
		profile.stats.totalEarned = math.min(Config.Game.MaxCurrency, profile.stats.totalEarned + earned)
		profile.stats.pveWins += 1
	end
	return true
end

function BattleService:leave(player: Player): (boolean, string?)
	local battle = self.battles[player]
	if not battle then return false, "You are not in a Mog-Off." end
	self.battles[player] = nil
	return true
end

function BattleService:tick(now: number)
	local changed = {}
	for player, battle in self.battles do
		if not battle.finished and now - battle.lastActionAt >= 120 then
			battle.finished = true; battle.winner = "enemy"
			battle.message = "The Mog-Off ended after two minutes without an action. No Moggers were lost."
			table.insert(battle.log, battle.message)
			table.insert(changed, player)
		end
	end
	return changed
end

function BattleService:remove(player: Player)
	self.battles[player] = nil
	self.nextStart[player] = nil
end

return BattleService
