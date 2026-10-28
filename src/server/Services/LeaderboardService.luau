--!strict
-- Server-calculated in-server player-list boards; no per-tick DataStore writes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.Rules)
local LeaderboardService = {}

function LeaderboardService.update(player, profile)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
	end
	local stats = {
		Earned = math.floor(profile.stats.totalEarned),
		PeakIncome = math.floor(profile.stats.peakIncome),
		MogOffWins = profile.stats.pveWins,
		Collection = Rules.collectionCount(profile),
		Ascension = profile.ascension,
	}
	for name, value in stats do
		local counter = folder:FindFirstChild(name)
		if not counter then counter = Instance.new("NumberValue"); counter.Name = name; counter.Parent = folder end
		counter.Value = value
	end
end

return LeaderboardService
