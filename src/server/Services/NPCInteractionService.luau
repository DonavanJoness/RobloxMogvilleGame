--!strict
-- Approved, customized R15 templates only. An unavailable asset is represented
-- by an honest information kiosk, never a generic dummy passed off as final art.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCConfiguration = require(ReplicatedStorage.Shared.NPCConfiguration)
local DistrictConfiguration = require(ReplicatedStorage.Shared.DistrictConfiguration)
local CharacterAppearanceService = require(script.Parent.CharacterAppearanceService)

local NPCInteractionService = {}
NPCInteractionService.__index = NPCInteractionService

local function positionFor(id: string, definition: any): Vector3
	local configured = DistrictConfiguration.NPCPositions and DistrictConfiguration.NPCPositions[id]
	local value = configured or definition.position
	if typeof(value) == "Vector3" then return value end
	if type(value) == "table" and value.position then value = value.position end
	if type(value) == "table" and value.x then return Vector3.new(value.x, value.y, value.z) end
	return Vector3.new(value[1], value[2], value[3])
end

local function information(parent: Instance, anchor: BasePart, definition: any, available: boolean)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NPCIdentity"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(270, 84)
	gui.StudsOffsetWorldSpace = Vector3.new(0, if available then 4.5 else 3.7, 0)
	gui.MaxDistance = 65
	gui.LightInfluence = 0
	gui.Parent = parent
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(23, 19, 40)
	text.BackgroundTransparency = 0.12
	text.TextColor3 = Color3.fromHex(definition.accent)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 15
	text.TextWrapped = true
	text.Text = definition.name .. "\n" .. definition.role .. (if available then "" else "\nNPC MODEL REQUIRED · ROLE KIOSK")
	text.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = text
end

local function prompt(anchor: BasePart, id: string, definition: any)
	local item = Instance.new("ProximityPrompt")
	item.Name = "SpeakTo" .. id
	item.ActionText = "Talk · " .. definition.role
	item.ObjectText = definition.name
	item.MaxActivationDistance = 10
	item.RequiresLineOfSight = false
	item.HoldDuration = 0
	item:SetAttribute("Action", "NPCDialogue")
	item:SetAttribute("NPCId", id)
	item.Parent = anchor
end

local function validAnimation(value: any): boolean
	return type(value) == "number" and value > 0 and value % 1 == 0 and value <= 9007199254740991
end

local function loadAnimations(humanoid: Humanoid, definition: any): { [string]: AnimationTrack }
	local result = {}
	-- Owner-supplied positive IDs alone are insufficient: imported animation
	-- rights and successful uploads must be recorded explicitly too.
	if definition.animationsApproved ~= true or type(definition.animationEvidence) ~= "string" or definition.animationEvidence == "" then return result end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then animator = Instance.new("Animator"); animator.Parent = humanoid end
	for _, slot in { "idle", "walk" } do
		local assetId = (definition.animations or {})[slot]
		if validAnimation(assetId) then
			local animation = Instance.new("Animation")
			animation.Name = "ApprovedNPC" .. slot
			animation.AnimationId = "rbxassetid://" .. string.format("%.0f", assetId)
			local ok, track = pcall(function() return (animator :: Animator):LoadAnimation(animation) end)
			animation:Destroy()
			if ok then
				track.Looped = true
				track.Priority = if slot == "walk" then Enum.AnimationPriority.Movement else Enum.AnimationPriority.Idle
				result[slot] = track
			end
		end
	end
	return result
end

local function play(entry: any, slot: string)
	if entry.animationSlot == slot then return end
	for _, track in entry.tracks do track:Stop(0.2) end
	local track = entry.tracks[slot]
	if track then track:Play(0.2) end
	entry.animationSlot = slot
end

function NPCInteractionService.new(loader: any?)
	return setmetatable({ appearance = CharacterAppearanceService.new(loader), entries = {}, folder = nil,
		elapsed = 0, clock = 0, built = false }, NPCInteractionService)
end

function NPCInteractionService:build(parent: Instance)
	if self.built then return self.folder end
	self.built = true
	local folder = Instance.new("Folder")
	folder.Name = "MogvilleNPCs"
	folder.Parent = parent
	self.folder = folder
	local ids = {}
	for id in NPCConfiguration.Characters do table.insert(ids, id) end
	table.sort(ids)
	local residentCount = 0
	for _, id in ids do
		local definition = NPCConfiguration.Characters[id]
		local point = positionFor(id, definition)
		local moving = definition.resident and residentCount < NPCConfiguration.MaxActiveResidents
		local model, problem = self.appearance:createRig(definition.modelKey, folder,
			CFrame.new(point) * CFrame.Angles(0, math.rad(definition.yaw or 0), 0), moving)
		if model then
			model.Name = definition.name
			model:SetAttribute("NPCId", id)
			model:SetAttribute("Role", definition.role)
			local tracks = loadAnimations(model:FindFirstChildOfClass("Humanoid") :: Humanoid, definition)
			model:SetAttribute("AnimationsReady", tracks.idle ~= nil and (not moving or tracks.walk ~= nil))
			local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
			local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
			-- Do not make an imported resident glide through the city while its
			-- required idle/walk uploads are missing or fail to load.
			if moving and (not tracks.idle or not tracks.walk) then
				moving = false
				root.Anchored = true
				humanoid.AutoRotate = false
			end
			prompt(root, id, definition)
			information(model, root, definition, true)
			local authored = Vector3.new(definition.position[1], definition.position[2], definition.position[3])
			local translatedWaypoints = {}
			for _, waypoint in definition.waypoints or {} do
				table.insert(translatedWaypoints, Vector3.new(waypoint[1], waypoint[2], waypoint[3]) + point - authored)
			end
			local entry = { id = id, definition = definition, model = model, root = root, waypoints = translatedWaypoints,
				humanoid = humanoid, tracks = tracks, moving = moving,
				waypoint = 1, nextAt = self.clock + 3, startedAt = 0, target = nil }
			play(entry, "idle")
			table.insert(self.entries, entry)
			if moving then residentCount += 1 end
		else
			-- A compact non-character information surface keeps existing menus
			-- usable while making the missing model requirement explicit.
			local kiosk = Instance.new("Part")
			kiosk.Name = "RoleKiosk_" .. id
			kiosk.Size = Vector3.new(2.6, 2.6, 0.5)
			kiosk.CFrame = CFrame.new(point + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, math.rad(definition.yaw or 0), 0)
			kiosk.Anchored = true
			kiosk.CanCollide = false
			kiosk.CanTouch = false
			kiosk.Color = Color3.fromHex(definition.accent)
			kiosk.Material = Enum.Material.Metal
			kiosk:SetAttribute("NPCId", id)
			kiosk:SetAttribute("AppearanceStatus", "TemplateRequired")
			kiosk:SetAttribute("AssetBlocker", problem or "Approved R15 template missing")
			kiosk.Parent = folder
			prompt(kiosk, id, definition)
			information(kiosk, kiosk, definition, false)
		end
	end
	folder:SetAttribute("ApprovedNPCCount", #self.entries)
	folder:SetAttribute("ConfiguredNPCCount", #ids)
	folder:SetAttribute("ResidentCount", residentCount)
	return folder
end

function NPCInteractionService:tick(dt: number)
	if type(dt) ~= "number" or dt ~= dt or dt <= 0 then return end
	self.clock += math.min(dt, 5)
	self.elapsed += dt
	if self.elapsed < NPCConfiguration.WaypointInterval then return end
	self.elapsed = 0
	for _, entry in self.entries do
		if not entry.moving or not entry.model.Parent or not entry.root.Parent then continue end
		local waypoints = entry.waypoints
		if #waypoints < 2 then continue end
		if entry.target then
			local arrived = (entry.root.Position - entry.target).Magnitude <= 3
			local timedOut = self.clock - entry.startedAt >= NPCConfiguration.WaypointTimeout
			if arrived or timedOut then
				entry.humanoid:MoveTo(entry.root.Position)
				entry.target = nil
				entry.waypoint = entry.waypoint % #waypoints + 1
				entry.nextAt = self.clock + 2 + entry.waypoint % 3
				play(entry, "idle")
			end
		elseif self.clock >= entry.nextAt then
			local target = waypoints[entry.waypoint]
			-- Hand-authored routes only, bounded distance and no continuous
			-- PathfindingService calls. Missing access is left for Studio testing.
			if (entry.root.Position - target).Magnitude <= NPCConfiguration.MaxWaypointDistance then
				entry.target = target
				entry.startedAt = self.clock
				entry.humanoid:MoveTo(target)
				play(entry, "walk")
			else
				entry.waypoint = entry.waypoint % #waypoints + 1
				entry.nextAt = self.clock + 3
			end
		end
	end
end

function NPCInteractionService:destroy()
	for _, entry in self.entries do
		for _, track in entry.tracks do track:Stop(); track:Destroy() end
	end
	self.entries = {}
	if self.folder then self.folder:Destroy(); self.folder = nil end
	self.built = false
end

return NPCInteractionService
