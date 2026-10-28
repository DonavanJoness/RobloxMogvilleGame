--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Rules = require(ReplicatedStorage.Shared.Rules)

local GachaService = {}
GachaService.__index = GachaService

function GachaService.new(data, social)
	return setmetatable({ data = data, social = social, random = Random.new() }, GachaService)
end

function GachaService:roll(player, count)
	local profile = self.data:get(player)
	if not profile then return { ok = false, error = "Your data is not ready." } end
	local boost = self.social:getServerLuck()
	return Rules.roll(profile, count, function() return self.random:NextNumber() end,
		function() return HttpService:GenerateGUID(false) end, os.time(), self.social:get(player), boost.bonus)
end

return GachaService
