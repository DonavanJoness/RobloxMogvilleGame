--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Shared.Config)
local Rules = require(ReplicatedStorage.Shared.Rules)

local ProgressionService = {}
ProgressionService.__index = ProgressionService

local QUESTS = {
	{ id = "first_placement", title = "Place your first Mogger", target = 1, reward = 75, progress = function(p) return #p.placed end },
	{ id = "roll_five", title = "Roll 5 Moggers", target = 5, reward = 250, progress = function(p) return p.stats.rolls end },
	{ id = "full_plot", title = "Display 3 Moggers", target = 3, reward = 200, progress = function(p) return #p.placed end },
	{ id = "earn_thousand", title = "Earn 1,000 Coins", target = 1000, reward = 300, progress = function(p) return p.stats.totalEarned end },
	{ id = "first_win", title = "Win a Mog-Off", target = 1, reward = 250, progress = function(p) return p.stats.pveWins end },
	{ id = "expand_plot", title = "Upgrade your plot", target = 1, reward = 350, progress = function(p) return p.upgrades.slots end },
	{ id = "collection", title = "Collect 7 unique Moggers", target = 7, reward = 1000, progress = function(p) return Rules.collectionCount(p) end },
}

local function award(profile: any, amount: number)
	local earned = math.min(Config.Game.MaxCurrency - profile.coins, amount)
	profile.coins += earned
	profile.stats.totalEarned = math.min(Config.Game.MaxCurrency, profile.stats.totalEarned + earned)
end

local function slots(profile: any): number
	return math.min(Config.Game.MaxPetSlots, 1 + profile.upgrades.petSlots)
end

function ProgressionService.new(data: any)
	return setmetatable({ data = data }, ProgressionService)
end

function ProgressionService:quests(profile: any): { any }
	local result = {}
	for _, quest in QUESTS do
		table.insert(result, { id = quest.id, title = quest.title, target = quest.target, reward = quest.reward,
			progress = math.min(quest.target, quest.progress(profile)), claimed = profile.quests.claimed[quest.id] == true })
	end
	return result
end

function ProgressionService:claimQuest(player: Player, id: any): (boolean, string?)
	local profile = self.data:get(player)
	if not profile then return false, "Your profile is not ready." end
	if type(id) ~= "string" then return false, "Unknown quest." end
	for _, quest in QUESTS do
		if quest.id == id then
			if profile.quests.claimed[id] then return false, "Reward already claimed." end
			if quest.progress(profile) < quest.target then return false, "Finish this quest first." end
			profile.quests.claimed[id] = true
			award(profile, quest.reward)
			return true
		end
	end
	return false, "Unknown quest."
end

function ProgressionService:buyPet(player: Player, petId: any): (boolean, string?)
	local profile = self.data:get(player)
	if not profile then return false, "Your profile is not ready." end
	local definition = if type(petId) == "string" then Config.Pets[petId] else nil
	if not definition then return false, "Unknown pet." end
	if #profile.pets >= Config.Game.PetInventoryLimit then
		return false, "Your pet collection is full (" .. tostring(Config.Game.PetInventoryLimit) .. ")."
	end
	if profile.coins < definition.cost then return false, "Earn more Coins for this pet." end
	profile.coins -= definition.cost
	local uid = HttpService:GenerateGUID(false)
	table.insert(profile.pets, { uid = uid, petId = petId })
	if #profile.equippedPets < slots(profile) then table.insert(profile.equippedPets, uid) end
	return true
end

function ProgressionService:equipPet(player: Player, uid: any): (boolean, string?)
	local profile = self.data:get(player)
	if not profile then return false, "Your profile is not ready." end
	if type(uid) ~= "string" then return false, "Choose one of your pets." end
	if table.find(profile.equippedPets, uid) then return false, "This pet is already equipped." end
	if #profile.equippedPets >= slots(profile) then return false, "Unequip a pet or unlock another pet slot." end
	for _, pet in profile.pets do
		if pet.uid == uid then table.insert(profile.equippedPets, uid); return true end
	end
	return false, "You do not own that pet."
end

function ProgressionService:unequipPet(player: Player, uid: any): (boolean, string?)
	local profile = self.data:get(player)
	if not profile then return false, "Your profile is not ready." end
	local index = if type(uid) == "string" then table.find(profile.equippedPets, uid) else nil
	if not index then return false, "This pet is not equipped." end
	table.remove(profile.equippedPets, index)
	return true
end

function ProgressionService:rank(profile: any): any
	local index = math.clamp(profile.ascension + 1, 1, #Config.Progression)
	local current, nextRank = Config.Progression[index], Config.Progression[index + 1]
	return {
		name = current.name, color = current.color,
		next = nextRank,
		progress = { income = Rules.income(profile), unique = Rules.collectionCount(profile), wins = profile.stats.pveWins },
	}
end

function ProgressionService:ascend(player: Player): (boolean, string?)
	local profile = self.data:get(player)
	if not profile then return false, "Your profile is not ready." end
	local nextRank = Config.Progression[profile.ascension + 2]
	if not nextRank then return false, "You are already an Ascended Mogger!" end
	if Rules.income(profile) < nextRank.income or Rules.collectionCount(profile) < nextRank.unique
		or profile.stats.pveWins < nextRank.wins then
		return false, string.format("Requires %.0f Coins/sec, %d unique Moggers and %d PvE wins.", nextRank.income, nextRank.unique, nextRank.wins)
	end
	if profile.coins < nextRank.cost then return false, "Ascension costs " .. tostring(nextRank.cost) .. " earned Coins." end
	profile.coins -= nextRank.cost
	profile.ascension += 1
	profile.upgrades.slots = math.min(Config.Game.MaxSlots - Config.Game.BaseSlots, profile.upgrades.slots + 1)
	return true
end

return ProgressionService
