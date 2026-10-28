--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Rules = require(ReplicatedStorage.Shared.Rules)

local EconomyService = {}
EconomyService.__index = EconomyService

local MAX_COINS = Config.Game.MaxCurrency or 1e15
local DEFAULT_UPGRADES = {
	slots = { baseCost = 500, costGrowth = 2, maxLevel = Config.Game.MaxSlots - Config.Game.BaseSlots },
	luck = { baseCost = 250, costGrowth = 1.75, maxLevel = 20 },
	petSlots = { baseCost = 5000, costGrowth = 4, maxLevel = 2 },
}

local function finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function definition(kind: string): any
	if not DEFAULT_UPGRADES[kind] then
		return nil
	end
	local configured = Config.Upgrades and Config.Upgrades[kind]
	return configured or DEFAULT_UPGRADES[kind]
end

local function costFor(profile: any, kind: string): number?
	local upgrade = definition(kind)
	if not upgrade then
		return nil
	end
	local level = profile.upgrades[kind] or 0
	local maxLevel = upgrade.maxLevel or DEFAULT_UPGRADES[kind].maxLevel
	if kind == "slots" then
		maxLevel = math.min(maxLevel, Config.Game.MaxSlots - Config.Game.BaseSlots)
	elseif kind == "petSlots" then
		maxLevel = math.min(maxLevel, 2)
	end
	if level >= maxLevel then
		return nil
	end
	local baseCost = upgrade.baseCost or DEFAULT_UPGRADES[kind].baseCost
	local growth = upgrade.costGrowth or DEFAULT_UPGRADES[kind].costGrowth
	local cost = math.ceil(baseCost * growth ^ level)
	if not finite(cost) or cost <= 0 or cost > MAX_COINS then
		return nil
	end
	return cost
end

function EconomyService.new(data: any)
	return setmetatable({ data = data }, EconomyService)
end

function EconomyService:income(player: Player): number
	local profile = self.data:get(player)
	if not profile then
		return 0
	end
	local income = Rules.income(profile)
	return if finite(income) then math.clamp(income, 0, MAX_COINS) else 0
end

function EconomyService:tick(dt: number)
	if not finite(dt) or dt <= 0 then
		return
	end
	-- A single central tick processes all placed Moggers. Bound a delayed tick
	-- so scheduler stalls cannot produce an arbitrarily large payout.
	local elapsed = math.min(dt, 5)
	for player, profile in self.data.profiles do
		if self.data:get(player) == profile then
			local income = self:income(player)
			local earned = math.min(MAX_COINS - profile.coins, income * elapsed)
			if earned > 0 then
				profile.coins += earned
				profile.stats.totalEarned = math.min(MAX_COINS, profile.stats.totalEarned + earned)
			end
			profile.stats.peakIncome = math.max(profile.stats.peakIncome or 0, income)
		end
	end
end

function EconomyService:upgradeCosts(profile: any): { [string]: number }
	local costs = {}
	for kind in DEFAULT_UPGRADES do
		local cost = costFor(profile, kind)
		if cost then
			costs[kind] = cost
		end
	end
	return costs
end

function EconomyService:upgrade(player: Player, kind: any): (boolean, string?)
	local profile = self.data:get(player)
	if not profile then
		return false, "Your profile is not ready."
	end
	if type(kind) ~= "string" or not definition(kind) then
		return false, "Unknown upgrade."
	end
	local cost = costFor(profile, kind)
	if not cost then
		return false, "This upgrade is already at its maximum level."
	end
	if profile.coins < cost then
		return false, "Earn more Coins to purchase this upgrade."
	end
	-- All validation and mutations are synchronous; concurrent remote requests
	-- cannot both spend the same balance across a yield.
	profile.coins -= cost
	profile.upgrades[kind] = (profile.upgrades[kind] or 0) + 1
	return true
end

return EconomyService
