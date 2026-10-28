local Registry = require("../src/shared/MoggerPortraitRegistry")
local Entries = require("../src/shared/RealMoggers")
local Visuals = require("../src/shared/CharacterVisuals")
local Rules = require("../src/shared/Rules")
local Config = require("../src/shared/Config")
return function(test)
	test("real-person availability always follows approved authentic photo and upload readiness", function()
		local entries = Registry.all()
		assert(#entries >= 25)
		local profile = Rules.newProfile(function() return "starter" end, 100)
		for _, row in entries do
			local ready = Registry.isReady(row)
			assert(row.referenceType == "RealPerson")
			assert(Visuals.get(row.id).authenticPortraitReady == ready)
			assert(Config.Characters[row.id] and Config.Characters[row.id].enabled == row.obtainable)
			if not ready then
				assert(not row.obtainable)
				for _, outcome in Rules.odds(profile) do assert(outcome.characterId ~= row.id) end
			end
		end
	end)
	test("a valid numeric asset ID alone never clears photo and identity permissions", function()
		local entry = {referenceType="RealPerson",identityVerified=false,authenticPhotograph=false}
		entry.portraitAssetId = 123456789 -- Synthetic unit-test value; never a production assignment.
		entry.imageStatus = "Approved"
		assert(not Registry.isReady(entry))
	end)
	test("each authenticity, adult-era, copyright, likeness and upload requirement is mandatory", function()
		local ready = {
			referenceType = "RealPerson", imageStatus = "Approved", portraitAssetId = 123,
			identityVerified = true, authenticPhotograph = true, adultEraVerified = true,
			copyrightPermission = true, commercialUseAllowed = true, likenessPermission = "granted",
			sourceURL = "https://example.org/test", creator = "Synthetic test", license = "Test record",
			copyrightEvidence = "Test record", likenessEvidence = "Test record", uploadEvidence = "Test record", uploadStatus = "uploaded",
		}
		assert(Registry.isReady(ready))
		for key in ready do
			local missing = table.clone(ready); missing[key] = nil
			assert(not Registry.isReady(missing), key .. " was incorrectly optional")
		end
	end)
	test("stored obtainable flags cannot bypass the centralized registry gate", function()
		local row = Registry.all()[1]
		local original, requested = Entries[row.id].obtainable, Entries[row.id].requestedEnabled
		Entries[row.id].obtainable = true
		Entries[row.id].requestedEnabled = false
		local actual = Registry.get(row.id)
		Entries[row.id].obtainable = original
		Entries[row.id].requestedEnabled = requested
		assert(not actual.obtainable)
		assert(Registry.get("nonexistent") == nil)
	end)
	test("withdrawing a real card from rolls preserves its owned instance and assignments", function()
		local row = Registry.all()[1]
		local profile = Rules.newProfile(function() return "old_starter" end, 100)
		profile.characters = {{uid="owned_real", characterId=row.id, mutation="Normal", level=1, acquiredAt=100}}
		profile.placed = {"owned_real"}; profile.team = {"owned_real"}; profile.coins = 321
		local previouslyEnabled = Config.Characters[row.id].enabled
		Config.Characters[row.id].enabled = false
		local ok, restored = pcall(Rules.sanitize, profile, function() return "unused_new_uid" end, 200)
		Config.Characters[row.id].enabled = previouslyEnabled
		assert(ok, tostring(restored))
		assert(restored.coins == 321 and restored.characters[1].uid == "owned_real")
		assert(restored.characters[1].characterId == row.id and restored.placed[1] == "owned_real" and restored.team[1] == "owned_real")
		assert(Rules.income(restored) > 0)
	end)
end
