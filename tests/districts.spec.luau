local Districts = require("../src/shared/DistrictConfiguration")

return function(test)
	test("district slots are unique and do not pretend local templates were imported", function()
		assert(#Districts.Districts == 8)
		local ids, keys = {}, {}
		for _, district in Districts.Districts do
			assert(not ids[district.id] and not keys[district.assetKey])
			ids[district.id] = true; keys[district.assetKey] = true
			assert(district.width > 0 and district.depth > 0)
			assert(district.assetId == nil and district.uploaded == nil)
		end
		assert(Districts.Reference.status == "OwnerSuppliedNotVisuallyVerified")
	end)
	test("twelve collector plots have nonoverlapping footprints and stable paired topology", function()
		local plots = {}
		for index = 1, 12 do
			local plot = Districts.plot(index)
			assert(plot.side == (if index % 2 == 1 then -1 else 1))
			assert(math.abs(plot.entranceX) < plot.width / 2)
			for _, previous in plots do
				assert(math.abs(plot.x - previous.x) >= (plot.width + previous.width) / 2
					or math.abs(plot.z - previous.z) >= (plot.depth + previous.depth) / 2)
			end
			table.insert(plots, plot)
		end
	end)
	test("plot configuration overrides preserve stable owner-index ordering", function()
		local first = Districts.plot(1, { PlotColumnsX = 200, PlotRowSpacing = 70 })
		local second = Districts.plot(2, { PlotColumnsX = 200, PlotRowSpacing = 70 })
		local third = Districts.plot(3, { PlotColumnsX = 200, PlotRowSpacing = 70 })
		assert(first.x == -200 and second.x == 200 and first.z == second.z)
		assert(third.x == first.x and third.z - first.z == 70)
	end)
	test("spawn points toward the spin hall with the old plaza fountain behind it", function()
		local spawn = Districts.Spawn
		assert(spawn.targetZ < spawn.z)
		assert(spawn.z < -3 - 27 / 2)
		assert(spawn.x == spawn.targetX and spawn.targetX == 0)
		assert(spawn.y > 0)
	end)
	test("role and resident anchor configuration is finite and within city bounds", function()
		for _, id in { "gacha_master", "gym_trainer", "fashion_icon", "battle_champion", "ascension_guardian", "resident_courier", "resident_collector", "resident_gardener" } do
			local anchor = Districts.NPCPositions[id]
			assert(anchor and anchor.x == anchor.x and anchor.z == anchor.z)
			assert(math.abs(anchor.x) < 270 and anchor.z > -345 and anchor.z < 255)
		end
	end)
end
