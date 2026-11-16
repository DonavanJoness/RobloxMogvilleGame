--!strict
-- Template-first appearance. Priority order:
--   1. an approved imported R15 template (AssetLoadingService), if one exists;
--   2. for ORIGINAL fictional characters and NPCs only, a procedural stand-in built from a native
--      R15 rig plus a data-driven look (RigFactory + LookApplier), always labelled
--      AppearanceStatus = "ProceduralStandIn";
--   3. otherwise a reason string, so the caller can show an honest card/kiosk.
-- A real person NEVER receives a stand-in: no likeness is invented for anyone.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local NPCConfiguration = require(ReplicatedStorage.Shared.NPCConfiguration)
local CharacterLooks = require(ReplicatedStorage.Shared.CharacterLooks)
local CharacterVisuals = require(ReplicatedStorage.Shared.CharacterVisuals)
local LookApplier = require(ReplicatedStorage.Shared.LookApplier)
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

-- Plot displays use a smaller decor budget than NPCs: 120 figures can share one server.
CharacterAppearanceService.DisplayDecorParts = 12

function CharacterAppearanceService.new(loader: any?, rigs: any?)
	return setmetatable({ loader = loader or AssetLoadingService.new(), rigs = rigs }, CharacterAppearanceService)
end

-- Put the rig's feet exactly on the floor contact point. `floor` is a CFrame whose position is
-- the point under the feet and whose rotation is the facing. Measured from the model's own
-- bounds, so it is correct for any rig height/scale (the old fixed offset floated rigs ~1 stud).
function CharacterAppearanceService.placeOnFloor(model: Model, floor: CFrame)
	model:PivotTo(floor)
	-- A rig whose bounds cannot be measured stays where the pivot put it rather than erroring.
	local ok, boundsCFrame, boundsSize = pcall(function() return model:GetBoundingBox() end)
	if not ok or not boundsCFrame or not boundsSize then return end
	local bottom = boundsCFrame.Position.Y - boundsSize.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, floor.Position.Y - bottom, 0))
end

local function finalize(model: Model, moving: boolean?, status: string)
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	model.PrimaryPart = root
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid.AutoRotate = moving == true
	if moving ~= true then
		-- Display rigs never walk: skip the Humanoid state machine (120 of them can share a server).
		pcall(function() humanoid.EvaluateStateMachine = false end)
	end
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			-- Decor parts (hair, gear) stay unanchored so their welds follow the rig; the root anchor
			-- holds the whole assembly. Displays never collide; moving residents keep body collision.
			item.Anchored = false
			if not moving or item:FindFirstAncestorOfClass("Accessory") or string.sub(item.Name, 1, 5) == "Look_" then
				item.CanCollide = false
			end
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
	model:SetAttribute("AppearanceStatus", status)
end

function CharacterAppearanceService:createRig(modelKey: string, parent: Instance, floor: CFrame, moving: boolean?): (Model?, string?)
	local model, reason = self.loader:clone(modelKey, parent, floor)
	if not model then return nil, reason or "Approved model template has not been imported." end
	local valid, problem = CharacterAppearanceService.validateRig(model)
	if not valid then model:Destroy(); return nil, problem end
	finalize(model, moving, "ApprovedTemplate")
	CharacterAppearanceService.placeOnFloor(model, floor)
	return model
end

-- Procedural stand-in for an original fictional character or NPC. `look` comes from
-- CharacterLooks. The rig must pass the same validator as an imported template.
function CharacterAppearanceService:createStandIn(look: any, parent: Instance, floor: CFrame, moving: boolean?, maxDecor: number?): (Model?, string?)
	if not self.rigs then return nil, "Procedural rigs are not available in this server." end
	local ok, why = CharacterLooks.validate(look)
	if not ok then return nil, "Invalid look: " .. tostring(why) end
	local model, reason = self.rigs:clone(look.build)
	if not model then return nil, reason end
	model.Name = "Figure"
	LookApplier.apply(model, look, { maxDecor = maxDecor })
	local valid, problem = CharacterAppearanceService.validateRig(model)
	if not valid then model:Destroy(); return nil, problem end
	finalize(model, moving, "ProceduralStandIn")
	model.Parent = parent
	CharacterAppearanceService.placeOnFloor(model, floor)
	return model
end

function CharacterAppearanceService:createDisplay(characterId: string, parent: Instance, floor: CFrame): (Model?, string?)
	local definition = Config.Characters[characterId]
	if not definition then return nil, "Unknown collectible character ID." end
	local key = definition.modelKey or ("mogger_" .. characterId)
	local model, reason = self:createRig(key, parent, floor, false)
	if not model then
		local visual = CharacterVisuals.get(characterId)
		-- Only original fictional characters may use a stand-in. Real people never do.
		if visual.referenceType == "LegacyFictional" then
			local look = CharacterLooks.forCharacter(definition.identityId, definition.form)
			if look then
				local standIn, standReason = self:createStandIn(look, parent, floor, false, CharacterAppearanceService.DisplayDecorParts)
				if standIn then
					model, reason = standIn, nil
				else
					reason = standReason or reason
				end
			end
		end
	end
	if model then
		model:SetAttribute("CharacterId", characterId)
		model:SetAttribute("IdentityId", definition.identityId)
		model:SetAttribute("Form", definition.form)
	end
	return model, reason
end

return CharacterAppearanceService
