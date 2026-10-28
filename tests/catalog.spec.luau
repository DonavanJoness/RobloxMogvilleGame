local Config = require("../src/shared/Config")
local Catalog = require("../src/shared/CharacterCatalog")
local Visuals = require("../src/shared/CharacterVisuals")
local PortraitAssets = require("../src/shared/PortraitAssets")

return function(test)
	test("all original IDs remain present and enriched without stat changes", function()
		local originals = {
			young_rookie = { 2, 12, 4, 70, 14 }, fresh_fade = { 3, 11, 5, 75, 16 },
			pose_apprentice = { 2.5, 10, 7, 80, 10 }, jawline_junior = { 7, 20, 8, 105, 17 },
			gym_bro = { 9, 23, 9, 115, 12 }, runway_rookie = { 20, 32, 13, 145, 26 },
			chiseled_champion = { 23, 28, 21, 170, 17 }, golden_chad = { 65, 48, 21, 205, 25 },
			mog_king = { 75, 55, 22, 215, 23 }, divine_icon = { 180, 76, 34, 290, 34 },
			celestial_stylist = { 165, 66, 39, 305, 36 }, apex_mogger = { 500, 110, 48, 410, 45 },
		}
		local originalCount = 0
		for id, stats in originals do
			originalCount += 1
			local definition = Config.Characters[id]
			assert(definition and Catalog.Existing[id], id .. " lost its stable save key")
			assert(definition.income == stats[1] and definition.attack == stats[2] and definition.defense == stats[3]
				and definition.health == stats[4] and definition.speed == stats[5], id .. " changed original balance")
			assert(definition.identityId == Catalog.Existing[id].identityId and definition.form == Catalog.Existing[id].form)
		end
		assert(originalCount == 12)
	end)

	test("catalog provides twelve added playable forms and four complete identity lines", function()
		local addedCount, total = 0, 0
		local identities = {}
		for id, definition in Catalog.Added do
			addedCount += 1
			assert(Config.Characters[id], id .. " is missing from the playable roster")
			assert(definition.enabled == true and definition.mutationEligible == true)
			assert(type(definition.income) == "number" and definition.income > 0)
			assert(definition.weight > 0 and definition.portraitAssetId == 0)
		end
		for id, definition in Config.Characters do
			if definition.referenceType == "RealPerson" then continue end
			total += 1
			assert(Catalog.Identities[definition.identityId], id .. " has no original identity")
			assert(Catalog.Forms[definition.form], id .. " has an unknown form")
			assert(type(definition.description) == "string" and #definition.description > 10)
			identities[definition.identityId] = identities[definition.identityId] or {}
			assert(not identities[definition.identityId][definition.form], "Duplicate identity/form pair for " .. id)
			identities[definition.identityId][definition.form] = true
		end
		assert(addedCount >= 12 and total >= 24)
		for _, identityId in { "rookie", "runway", "royalty", "gym" } do
			for _, form in { "Young", "Classic", "Prime", "Ascended" } do assert(identities[identityId][form]) end
		end
	end)

	test("character identity, form, rarity and mutation remain separate dimensions", function()
		local rookie = Config.Characters.young_rookie
		local prime = Config.Characters.rookie_prime
		assert(rookie.identityId == prime.identityId and rookie.form ~= prime.form)
		assert(rookie.rarity == "Common" and prime.rarity == "Rare")
		for id, definition in Config.Characters do
			if definition.referenceType == "RealPerson" then continue end
			assert(definition.mutation == nil, id .. " hardcodes an instance mutation")
			assert(definition.mutationEligible == true)
		end
		assert(Config.Characters.gym_ascended.form == "Ascended" and Config.Characters.gym_ascended.rarity == "Divine")
	end)

	test("portrait lookup covers every form and returns safe unknown fallbacks", function()
		for id, definition in Config.Characters do
			local visual = Visuals.get(id)
			assert(visual.identityId == definition.identityId and visual.form == definition.form)
			assert(visual.enabled == definition.enabled)
			assert(type(visual.description) == "string" and #visual.description > 0)
			assert(visual.portraitAssetId == 0 or Visuals.validAssetId(visual.portraitAssetId))
		end
		for _, id in { "missing_character", "", 123, false, {} } do
			local fallback = Visuals.get(id)
			assert(fallback.portraitAssetId == 0 and fallback.identityId == "unknown" and fallback.enabled == false)
			assert(fallback.mutationEligible == false)
		end
	end)

	test("portrait IDs reject URLs, nonintegers, negatives and nonfinite numbers", function()
		assert(Visuals.validAssetId(123456789))
		for _, bad in { 0, -1, 1.5, 0 / 0, math.huge, -math.huge, 9007199254740992, "123", "rbxassetid://123", {}, false } do
			assert(not Visuals.validAssetId(bad))
		end
	end)

	test("legacy portrait overrides cannot masquerade as approved real-person photos", function()
		local original = PortraitAssets.young_rookie
		PortraitAssets.young_rookie = -123
		local bad = Visuals.get("young_rookie")
		PortraitAssets.young_rookie = 123456789
		local valid = Visuals.get("young_rookie")
		PortraitAssets.young_rookie = original
		assert(bad.portraitAssetId == 0 and valid.portraitAssetId == 0)
		assert(valid.authenticPortraitReady == false and valid.referenceType == "LegacyFictional")
		assert(bad.identityId == valid.identityId and bad.form == valid.form)
	end)
end
