--!strict
-- Owner-imported assets only. No ID below is fabricated and no remote models are loaded.
local entries: any = {}
local Catalog: any = require(script.Parent.CharacterCatalog)
local RealMoggers: any = require(script.Parent.RealMoggers)
for _, key in { "district_central_plaza", "district_gacha_hall", "district_display_neighborhood", "district_shopping",
	"district_gym", "district_arena", "district_ascension", "district_park",
	"npc_gacha_master", "npc_gym_trainer", "npc_fashion_icon", "npc_battle_champion",
	"npc_ascension_guardian", "npc_resident_courier", "npc_resident_gardener", "npc_resident_collector" } do
	entries[key] = {
		status = "Missing", templateName = key, sourceURL = "", creator = "", license = "",
		commercialUseAllowed = false, permissionEvidence = "", qualityApproved = false,
		maxParts = if string.sub(key, 1, 4) == "npc_" then 150 else 800,
		requireR15 = string.sub(key, 1, 4) == "npc_", normalizedSize = 0,
	}
end
for _, group in { Catalog.Existing, Catalog.Added } do
	for id in group do
		local key = "mogger_" .. id
		entries[key] = { status = "Missing", templateName = key, sourceURL = "", creator = "", license = "",
			commercialUseAllowed = false, permissionEvidence = "", qualityApproved = false,
			maxParts = 96, requireR15 = true, normalizedSize = 0 }
	end
end
for _, entry in RealMoggers do
	if not entries[entry.modelKey] then
		entries[entry.modelKey] = { status = "Missing", templateName = entry.modelKey, sourceURL = "", creator = "", license = "",
			commercialUseAllowed = false, permissionEvidence = "", qualityApproved = false,
			maxParts = 96, requireR15 = true, normalizedSize = 0 }
	end
end
return entries
