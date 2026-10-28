--!strict
-- Template-first appearance. Missing/unsafe rigs return a reason; they are never
-- silently replaced by a recolored dummy or an invented real-person likeness.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local NPCConfiguration = require(ReplicatedStorage.Shared.NPCConfiguration)
local AssetLoadingService = require(script.Parent.AssetLoadingService)

local CharacterAppearanceService = {}
CharacterAppearanceService.__index = CharacterAppearanceService
local REQUIRED_PARTS = {
	"HumanoidRootPart", "Head", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

function CharacterAppearanceService.validateRig(model: any): (boolean, string?)
	if not model or not model:IsA("Model") then return false, "An approved R15 Model template is required." end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return false, "The approved character template must contain an R15 Humanoid."
	end
	local body, graph = {}, {}
	for _, name in REQUIRED_PARTS do
		local bodyPart = model:FindFirstChild(name)
		if not bodyPart or not bodyPart:IsA("BasePart") then return false, "R15 template is missing " .. name .. "." end
		body[bodyPart] = true
		graph[bodyPart] = {}
	end
	local parts, motors = 0, 0
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then parts += 1 end
		if item:IsA("Motor6D") then
			motors += 1
			if body[item.Part0] and body[item.Part1] then
				table.insert(graph[item.Part0], item.Part1)
				table.insert(graph[item.Part1], item.Part0)
			end
		end
	end
	if parts > NPCConfiguration.MaxRigParts then return false, "Character template exceeds its BasePart budget." end
	if motors < 15 then return false, "R15 template needs its complete articulated Motor6D rig." end
	local visited, stack, count = {}, { model:FindFirstChild("HumanoidRootPart") }, 0
	while #stack > 0 do
		local current = table.remove(stack)
		if not visited[current] then
			visited[current] = true; count += 1
			for _, nextPart in graph[current] do table.insert(stack, nextPart) end
		end
	end
	if count ~= #REQUIRED_PARTS then return false, "R15 Motor6D body connections are incomplete." end
	return true
end

function CharacterAppearanceService.new(loader: any?)
	return setmetatable({ loader = loader or AssetLoadingService.new() }, CharacterAppearanceService)
end

function CharacterAppearanceService:createRig(modelKey: string, parent: Instance, pivot: CFrame, moving: boolean?): (Model?, string?)
	local model, reason = self.loader:clone(modelKey, parent, pivot)
	if not model then return nil, reason or "Approved model template has not been imported." end
	local valid, problem = CharacterAppearanceService.validateRig(model)
	if not valid then model:Destroy(); return nil, problem end
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	model.PrimaryPart = root
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid.AutoRotate = moving == true
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = false
			-- Retain the imported rig's body collision design for moving residents;
			-- displays have no physical collision and accessories never collide.
			if not moving or item:FindFirstAncestorOfClass("Accessory") then item.CanCollide = false end
			item.CanTouch = false
		end
	end
	root.Anchored = moving ~= true
	if moving then
		-- Approved moving rigs retain their authored body collisions for floor
		-- support. Actual ground contact and route behavior require Studio tests.
		root.CanCollide = false
		humanoid.WalkSpeed = 5
		pcall(function() root:SetNetworkOwner(nil) end)
	end
	model:SetAttribute("AppearanceStatus", "ApprovedTemplate")
	return model
end

function CharacterAppearanceService:createDisplay(characterId: string, parent: Instance, pivot: CFrame): (Model?, string?)
	local definition = Config.Characters[characterId]
	if not definition then return nil, "Unknown collectible character ID." end
	local key = definition.modelKey or ("mogger_" .. characterId)
	local model, reason = self:createRig(key, parent, pivot, false)
	if model then
		model:SetAttribute("CharacterId", characterId)
		model:SetAttribute("IdentityId", definition.identityId)
		model:SetAttribute("Form", definition.form)
	end
	return model, reason
end

return CharacterAppearanceService
