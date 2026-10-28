--!strict
-- Spatial composition is independent from the final imported architecture.
-- The linked reference was supplied by the owner; its actual game layout has
-- not been inspected in Studio here. These are MOGVILLE's original placements.
local DistrictConfiguration = {}

DistrictConfiguration.Reference = {
	url = "https://www.roblox.com/games/94164742020505/Build-a-Soccer-Team",
	status = "OwnerSuppliedNotVisuallyVerified",
	interpretation = "Card collection promenade, central spin sightline, surrounding collector plots",
}

DistrictConfiguration.LayoutName = "Collector Promenade"
DistrictConfiguration.Spawn = { x = 0, y = 5, z = -47, targetX = 0, targetY = 6, targetZ = -119 }
DistrictConfiguration.PlotLayout = {
	columnX = 190, rowSpacing = 60, firstZ = -150,
	width = 88, depth = 54, entranceInset = 38,
}

DistrictConfiguration.Districts = {
	{ id = "central_plaza", folder = "WelcomePlaza", name = "Central Plaza", assetKey = "district_central_plaza", x = 0, y = 0, z = 0, width = 106, depth = 83 },
	{ id = "gacha_hall", folder = "GachaHall", name = "Spin Hall", assetKey = "district_gacha_hall", x = 0, y = 0, z = -108, width = 76, depth = 64 },
	{ id = "display_neighborhood", folder = "CollectorResidences", name = "Collector Neighborhood", assetKey = "district_display_neighborhood", x = 0, y = 0, z = 0, width = 480, depth = 354 },
	{ id = "shopping", folder = "LuxuryShopStreet", name = "Shopping Street", assetKey = "district_shopping", x = 83, y = 0, z = -28, width = 47, depth = 126 },
	{ id = "gym", folder = "GlowUpGym", name = "Training Club", assetKey = "district_gym", x = -83, y = 0, z = -70, width = 47, depth = 45 },
	{ id = "arena", folder = "MogOffArena", name = "Mog-Off Stadium", assetKey = "district_arena", x = 0, y = 0, z = 111, width = 112, depth = 106 },
	{ id = "ascension", folder = "AscensionHeights", name = "Ascension Heights", assetKey = "district_ascension", x = 0, y = 12, z = -244, width = 104, depth = 70 },
	{ id = "park", folder = "ParkSocial", name = "Social Gardens", assetKey = "district_park", x = -83, y = 0, z = 60, width = 58, depth = 62 },
}

-- Empty models are safe pivots for reviewed local templates, not asset IDs.
-- NPCInteractionService owns model creation and honest unavailable-art kiosks.
DistrictConfiguration.NPCPositions = {
	gacha_master = { x = -23, y = 1, z = -111, yaw = 0 },
	gym_trainer = { x = -67, y = 1, z = -56, yaw = 0 },
	fashion_icon = { x = 83, y = 1, z = 28, yaw = 0 },
	battle_champion = { x = 26, y = 1, z = 72, yaw = 0 },
	ascension_guardian = { x = 0, y = 12, z = -229, yaw = 0 },
	resident_gardener = { x = -94, y = 0.7, z = 63, yaw = 0 },
	resident_courier = { x = 45, y = 0.7, z = -30, yaw = 0 },
	resident_collector = { x = 69, y = 0.7, z = 35, yaw = 0 },
}

function DistrictConfiguration.plot(index: number, world: any?): any
	assert(index >= 1 and index % 1 == 0, "Plot index must be a positive integer")
	local settings = world or {}
	local layout = DistrictConfiguration.PlotLayout
	local side = if index % 2 == 1 then -1 else 1
	return {
		x = side * (settings.PlotColumnsX or layout.columnX), y = 0,
		z = layout.firstZ + math.floor((index - 1) / 2) * (settings.PlotRowSpacing or layout.rowSpacing),
		width = layout.width, depth = layout.depth, side = side,
		entranceX = -side * layout.entranceInset,
	}
end

return DistrictConfiguration
