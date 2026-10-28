--!strict
-- Sanitizes a private clone BEFORE parenting it into the live world.
-- Templates in ServerStorage never execute here. Runtime asset-ID insertion is not supported.
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Manifest: any = require(ReplicatedStorage.Shared.AssetManifest)
local Loader = {}
Loader.__index = Loader
local forbidden = {
	Script = true, LocalScript = true, ModuleScript = true, RemoteEvent = true,
	UnreliableRemoteEvent = true, RemoteFunction = true, BindableEvent = true,
	BindableFunction = true, PackageLink = true, ObjectValue = true,
}

function Loader.new(manifest: any?, storage: any?)
	return setmetatable({ manifest = manifest or Manifest, storage = storage or ServerStorage:FindFirstChild("ApprovedAssets") }, Loader)
end

function Loader:clone(key: any, parent: Instance, pivot: CFrame?): (Model?, string?)
	if type(key) ~= "string" then return nil, "Invalid asset key." end
	local entry = self.manifest[key]
	if not entry or entry.status ~= "Approved" or entry.qualityApproved ~= true
		or entry.commercialUseAllowed ~= true or type(entry.sourceURL) ~= "string" or entry.sourceURL == ""
		or type(entry.license) ~= "string" or entry.license == ""
		or type(entry.creator) ~= "string" or entry.creator == ""
		or type(entry.permissionEvidence) ~= "string" or entry.permissionEvidence == "" then
		return nil, "Approved model and source/quality review required: " .. key
	end
	local template = self.storage and self.storage:FindFirstChild(entry.templateName)
	if not template or not template:IsA("Model") then return nil, "Imported model template missing: " .. key end
	local cloned, copy = pcall(function() return template:Clone() end)
	if not cloned or not copy then return nil, "Model template could not be cloned: " .. key end
	local ok, result = pcall(function()
		local removed, partCount = 0, 0
		for _, item in copy:GetDescendants() do
			if forbidden[item.ClassName] or item:IsA("BaseScript") then
				item:Destroy(); removed += 1
			elseif item:IsA("BasePart") then
				partCount += 1
				item.CanTouch = false
				if not entry.requireR15 then item.Anchored = true end
			end
		end
		assert(partCount > 0 and partCount <= math.clamp(entry.maxParts or 150, 1, 2000), "Imported part budget exceeded or model empty")
		local humanoid = copy:FindFirstChildOfClass("Humanoid")
		if entry.requireR15 then
			assert(humanoid and humanoid.RigType == Enum.HumanoidRigType.R15, "Expected a verified R15 rig")
			assert(copy:FindFirstChild("HumanoidRootPart"), "R15 rig lacks root part")
		end
		-- Scale only to an explicitly reviewed target; scripts never guess an asset's scale.
		if type(entry.normalizedSize) == "number" and entry.normalizedSize > 0 then
			local _, size = copy:GetBoundingBox()
			local largest = math.max(size.X, size.Y, size.Z)
			assert(largest > 0, "Imported bounds are empty")
			copy:ScaleTo(copy:GetScale() * entry.normalizedSize / largest)
		end
		if pivot then copy:PivotTo(pivot) end
		copy:SetAttribute("AssetKey", key)
		copy:SetAttribute("SourceReviewed", true)
		copy:SetAttribute("RemovedUntrustedObjects", removed)
		copy.Parent = parent
		return copy
	end)
	if not ok then copy:Destroy(); return nil, "Imported asset rejected: " .. tostring(result) end
	return result, nil
end

return Loader
