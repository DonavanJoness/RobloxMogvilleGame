--!strict
local Players = game:GetService("Players")

local SocialBonusService = {}
SocialBonusService.__index = SocialBonusService

function SocialBonusService.new()
	return setmetatable({ friends = {}, refreshing = {}, serverLuck = { bonus = 0, expiresAt = 0 } }, SocialBonusService)
end

function SocialBonusService:refresh(player: Player)
	if self.refreshing[player] then return end
	self.refreshing[player] = true
	local verified = {}
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(function() return player:IsFriendsWith(other.UserId) end)
			if ok and isFriend and other.Parent == Players then verified[other.UserId] = true end
		end
	end
	if player.Parent == Players then self.friends[player] = verified end
	self.refreshing[player] = nil
end

function SocialBonusService:get(player: Player): number
	local count = 0
	for _, other in Players:GetPlayers() do
		if (self.friends[player] or {})[other.UserId] then count += 1 end
	end
	return math.min(4, count)
end

function SocialBonusService:getServerLuck(): any
	if self.serverLuck.expiresAt <= os.time() then self.serverLuck = { bonus = 0, expiresAt = 0 } end
	return { bonus = self.serverLuck.bonus, expiresAt = self.serverLuck.expiresAt }
end

-- Only trusted server gameplay may call this; never exposed as a direct remote.
-- A qualifying gameplay event grants one bounded event, without stacking duration.
function SocialBonusService:activateEarnedBoost(_player: Player): (boolean, string?)
	if self:getServerLuck().bonus > 0 then return false, "A server luck event is already active." end
	self.serverLuck = { bonus = 0.25, expiresAt = os.time() + 600 }
	return true
end

function SocialBonusService:remove(player: Player)
	self.friends[player] = nil
	self.refreshing[player] = nil
end

return SocialBonusService
