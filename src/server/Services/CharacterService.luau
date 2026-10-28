--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local CharacterService = {}
CharacterService.__index = CharacterService

local function validUid(uid: any): boolean
	return type(uid) == "string" and #uid > 0 and #uid <= 100
end

local function owns(profile: any, uid: string): boolean
	for _, character in profile.characters do
		if character.uid == uid then
			return true
		end
	end
	return false
end

function CharacterService.new(data: any)
	return setmetatable({ data = data }, CharacterService)
end

function CharacterService:equip(player: Player, uid: any): (boolean, string?)
	local profile = self.data:get(player)
	if not profile then
		return false, "Your profile is not ready."
	end
	if not validUid(uid) or not owns(profile, uid) then
		return false, "Choose a Mogger you own."
	end
	if table.find(profile.placed, uid) then
		return false, "This Mogger is already on display."
	end
	local slots = math.min(Config.Game.MaxSlots, Config.Game.BaseSlots + profile.upgrades.slots)
	if #profile.placed >= slots then
		return false, "Your display is full. Remove a Mogger or upgrade your plot."
	end
	table.insert(profile.placed, uid)
	return true
end

function CharacterService:unequip(player: Player, uid: any): (boolean, string?)
	local profile = self.data:get(player)
	if not profile then
		return false, "Your profile is not ready."
	end
	if not validUid(uid) or not owns(profile, uid) then
		return false, "Choose a Mogger you own."
	end
	local index = table.find(profile.placed, uid)
	if not index then
		return false, "This Mogger is not on display."
	end
	table.remove(profile.placed, index)
	return true
end

function CharacterService:setTeam(player: Player, uids: any): (boolean, string?)
	local profile = self.data:get(player)
	if not profile then
		return false, "Your profile is not ready."
	end
	if type(uids) ~= "table" then
		return false, "Choose up to three owned Moggers."
	end
	-- Count every entry rather than trusting Lua's length operator on sparse or
	-- dictionary-shaped remote payloads. No state changes occur until validation.
	local count = 0
	for key in uids do
		count += 1
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > 3 then
			return false, "A team must contain up to three Moggers."
		end
	end
	if count > 3 then
		return false, "A team can have at most three Moggers."
	end
	local selected = {}
	local seen: { [string]: boolean } = {}
	for index = 1, count do
		local uid = uids[index]
		if not validUid(uid) or seen[uid] or not owns(profile, uid) then
			return false, "Team members must be different Moggers you own."
		end
		seen[uid] = true
		table.insert(selected, uid)
	end
	profile.team = selected
	return true
end

return CharacterService
