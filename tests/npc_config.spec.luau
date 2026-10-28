local NPCs = require("../src/shared/NPCConfiguration")
local Manifest = require("../src/shared/AssetManifest")
local Districts = require("../src/shared/DistrictConfiguration")

return function(test)
	test("NPC roles have distinct template keys and explicit unimported appearance briefs", function()
		local count, residents, keys, outfits, hair = 0, 0, {}, {}, {}
		for id, definition in NPCs.Characters do
			count += 1
			if definition.resident then residents += 1 end
			assert(not keys[definition.modelKey], "NPC template keys must be unique")
			keys[definition.modelKey] = true
			assert(not outfits[definition.appearance.outfit] and not hair[definition.appearance.hair])
			outfits[definition.appearance.outfit], hair[definition.appearance.hair] = true, true
			assert(#definition.appearance.accessories > 10 and #definition.appearance.silhouette > 10)
			assert(definition.assetStatus == "TemplateRequired")
			assert(definition.animations.idle == 0 and definition.animations.walk == 0)
			assert(Districts.NPCPositions[id], "Every NPC needs an authored location")
		end
		assert(count == 8 and residents == 3 and residents <= NPCs.MaxActiveResidents)
	end)
	test("NPC dialogues route only to real existing gameplay menus", function()
		local menus = { Roll=true,Inventory=true,Team=true,Battle=true,Upgrades=true,Quests=true,Shop=true,Pets=true,Settings=true }
		for _, definition in NPCs.Characters do
			assert(#definition.dialogue > 80 and #definition.actions > 0)
			for _, action in definition.actions do assert(menus[action.menu] and #action.label > 0) end
		end
	end)
	test("NPC template keys match missing approved-R15 asset requirements", function()
		for _, definition in NPCs.Characters do
			local requirement = Manifest[definition.modelKey]
			assert(requirement, "Missing NPC asset import slot: " .. definition.modelKey)
			assert(requirement.requireR15 == true)
			assert(requirement.status ~= "Approved", "This delivery has no imported NPC model asset")
		end
	end)
	test("residents use short bounded authored waypoint segments", function()
		for _, definition in NPCs.Characters do
			if not definition.resident then continue end
			assert(#definition.waypoints >= 2 and #definition.waypoints <= 8)
			for i, waypoint in definition.waypoints do
				local nextPoint = definition.waypoints[i % #definition.waypoints + 1]
				local squared = 0
				for axis = 1, 3 do squared += (waypoint[axis] - nextPoint[axis]) ^ 2 end
				assert(squared <= NPCs.MaxWaypointDistance ^ 2)
			end
		end
	end)
end
