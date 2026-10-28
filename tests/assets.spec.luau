local Runtime = require("./asset-runtime")
local Loader = require("../src/server/Services/AssetLoadingService")
local Appearance = require("../src/server/Services/CharacterAppearanceService")
local NPCs = require("../src/shared/NPCConfiguration")

local function approved(patch)
	local entry = {
		status = "Approved", qualityApproved = true, commercialUseAllowed = true,
		templateName = "Reviewed", sourceURL = "https://example.org/test-fixture",
		creator = "Synthetic fixture author", license = "Synthetic fixture permission",
		permissionEvidence = "Test record, never production authorization", maxParts = 96,
		requireR15 = false, normalizedSize = 0,
	}
	for key, value in patch or {} do entry[key] = value end
	return entry
end

local function fixture(entry, model)
	Runtime.reset()
	model = model or Runtime.rig("Reviewed")
	model.Name = "Reviewed"
	model.Parent = Runtime.storage
	return Loader.new({ test_asset = entry or approved() }, Runtime.storage), model
end

return function(test)
	test("asset imports refuse missing permissions, quality review and source records", function()
		for _, patch in {
			{ status = "Missing" }, { qualityApproved = false }, { commercialUseAllowed = false },
			{ sourceURL = "" }, { creator = "" }, { license = "" }, { permissionEvidence = "" },
		} do
			local loader, template = fixture(approved(patch))
			local model, reason = loader:clone("test_asset", Runtime.world, {})
			assert(model == nil and type(reason) == "string")
			assert(not template.Destroyed and #Runtime.world:GetChildren() == 0)
		end
	end)

	test("unknown asset keys and absent or non-model templates cannot spawn", function()
		local loader = fixture()
		assert(loader:clone("not_configured", Runtime.world) == nil)
		assert(loader:clone({}, Runtime.world) == nil)
		Runtime.storage:FindFirstChild("Reviewed"):Destroy()
		assert(loader:clone("test_asset", Runtime.world) == nil)
		Runtime.add(Runtime.storage, "Folder", "Reviewed")
		assert(loader:clone("test_asset", Runtime.world) == nil)
		assert(#Runtime.world:GetChildren() == 0)
	end)

	test("untrusted executable, remote and dependency objects are removed before live parenting", function()
		local model = Runtime.rig("Reviewed")
		local forbidden = { "Script", "LocalScript", "ModuleScript", "RemoteEvent", "UnreliableRemoteEvent",
			"RemoteFunction", "BindableEvent", "BindableFunction", "PackageLink", "ObjectValue" }
		for _, className in forbidden do Runtime.add(model, className, "Unsafe" .. className) end
		local loader, original = fixture(approved(), model)
		local spawned, reason = loader:clone("test_asset", Runtime.world, { position = "reviewed-pivot" })
		assert(spawned and reason == nil and spawned ~= original)
		assert(spawned:GetAttribute("RemovedUntrustedObjects") == #forbidden)
		assert(spawned:GetAttribute("SourceReviewed") == true and spawned:GetAttribute("AssetKey") == "test_asset")
		local classes = spawned:classCounts()
		for _, className in forbidden do assert(classes[className] == nil); assert(original:classCounts()[className] == 1) end
		local liveParents = 0
		for _, event in Runtime.parenting do
			if event.parent == Runtime.world then
				liveParents += 1
				for _, className in forbidden do assert(event.classes[className] == nil, "Unsafe child parented into live world") end
			end
		end
		assert(liveParents == 1 and original.Parent == Runtime.storage and original:GetAttribute("SourceReviewed") == nil)
		for _, item in spawned:GetDescendants() do if item:IsA("BasePart") then assert(item.Anchored and item.CanTouch == false) end end
	end)

	test("empty and over-budget imported models are rejected without publishing a clone", function()
		local loader = fixture(approved(), Runtime.object("Model", "Empty"))
		assert(loader:clone("test_asset", Runtime.world) == nil and #Runtime.world:GetChildren() == 0)
		loader = fixture(approved({ maxParts = 2 }))
		assert(loader:clone("test_asset", Runtime.world) == nil and #Runtime.world:GetChildren() == 0)
	end)

	test("nonarchivable templates fail closed rather than throwing an invocation error", function()
		local loader, original = fixture()
		original.Archivable = false
		local success, model, reason = pcall(function() return loader:clone("test_asset", Runtime.world) end)
		assert(success and model == nil and type(reason) == "string")
		assert(original.Parent == Runtime.storage and #Runtime.world:GetChildren() == 0)
	end)

	test("reviewed normalization and pivot apply to the clone while leaving source scale intact", function()
		local loader, original = fixture(approved({ normalizedSize = 12 }))
		local pivot = { marker = "target" }
		local spawned = loader:clone("test_asset", Runtime.world, pivot)
		assert(spawned:GetScale() == 1.5 and original:GetScale() == 1)
		assert(spawned._pivot == pivot and original._pivot == nil)
		loader, original = fixture(approved({ normalizedSize = 12 }))
		original._bounds = { X = 0, Y = 0, Z = 0 }
		assert(loader:clone("test_asset", Runtime.world) == nil and #Runtime.world:GetChildren() == 0)
	end)

	test("R15 requirements reject an R6 rig or missing root before importing", function()
		local rig = Runtime.rig()
		rig:FindFirstChildOfClass("Humanoid").RigType = Runtime.Enum.HumanoidRigType.R6
		local loader = fixture(approved({ requireR15 = true }), rig)
		assert(loader:clone("test_asset", Runtime.world) == nil)
		rig = Runtime.rig(); rig:FindFirstChild("HumanoidRootPart"):Destroy()
		loader = fixture(approved({ requireR15 = true }), rig)
		assert(loader:clone("test_asset", Runtime.world) == nil)
		assert(#Runtime.world:GetChildren() == 0)
	end)

	test("character templates require all sixteen body parts, articulated joints and a bounded rig", function()
		local rig = Runtime.rig()
		assert(Appearance.validateRig(rig))
		rig:FindFirstChild("LeftHand"):Destroy()
		assert(not Appearance.validateRig(rig))
		rig = Runtime.rig(); rig:FindFirstChild("Joint15"):Destroy()
		assert(not Appearance.validateRig(rig))
		rig = Runtime.rig()
		for index = 1, NPCs.MaxRigParts do Runtime.add(rig, "Part", "Excess" .. index) end
		assert(not Appearance.validateRig(rig))
		assert(not Appearance.validateRig(Runtime.object("Folder", "NotARig")))
	end)

	test("an approved display uses a rig with stationary root and no collision", function()
		local loader = fixture(approved({ requireR15 = true }))
		local service = Appearance.new(loader)
		local rig, reason = service:createRig("test_asset", Runtime.world, {}, false)
		assert(rig and reason == nil and rig.PrimaryPart == rig:FindFirstChild("HumanoidRootPart"))
		assert(rig.PrimaryPart.Anchored == true and rig:GetAttribute("AppearanceStatus") == "ApprovedTemplate")
		for _, item in rig:GetDescendants() do if item:IsA("BasePart") then assert(item.CanCollide == false and item.CanTouch == false) end end
	end)

	test("joint counts cannot hide a disconnected body or external Motor6D reference", function()
		local rig = Runtime.rig()
		rig:FindFirstChild("Joint3").Part1 = rig:FindFirstChild("LowerTorso")
		assert(not Appearance.validateRig(rig), "Head is disconnected even though all15 motors exist")
		rig = Runtime.rig()
		rig:FindFirstChild("Joint3").Part1 = Runtime.object("MeshPart", "ExternalHead")
		assert(not Appearance.validateRig(rig), "An external reference cannot stand in for the rig's head")
	end)

	test("appearance rejection destroys incomplete rigs rather than substituting a dummy", function()
		local rig = Runtime.rig(); rig:FindFirstChild("Joint15"):Destroy()
		local loader = fixture(approved({ requireR15 = true }), rig)
		local spawned, reason = Appearance.new(loader):createRig("test_asset", Runtime.world, {}, false)
		assert(spawned == nil and type(reason) == "string" and #Runtime.world:GetChildren() == 0)
	end)

	test("NPC configurations describe five unique roles and three residents with no fabricated animation IDs", function()
		local roles, residents, keys, names = 0, 0, {}, {}
		for _, definition in NPCs.Characters do
			assert(not keys[definition.modelKey] and not names[definition.name])
			keys[definition.modelKey], names[definition.name] = true, true
			assert(type(definition.appearance.outfit) == "string" and #definition.appearance.outfit > 10)
			assert(type(definition.appearance.hair) == "string" and #definition.dialogue > 50 and #definition.actions > 0)
			assert(definition.animations.idle == 0 and definition.animations.walk == 0)
			if definition.resident then residents += 1; assert(#definition.waypoints >= 2) else roles += 1 end
		end
		assert(roles == 5 and residents == 3 and NPCs.MaxActiveResidents == 3)
	end)
end
