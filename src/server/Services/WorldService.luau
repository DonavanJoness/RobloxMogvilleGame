-- Procedural scenery and presentation. Currency, ownership, and equipment live in services.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Rules = require(ReplicatedStorage.Shared:WaitForChild("Rules"))

local EnvironmentBuilder = require(script.Parent.EnvironmentBuilder)
local CharacterVisuals = require(ReplicatedStorage.Shared:WaitForChild("CharacterVisuals"))
local Appearance = require(script.Parent.CharacterAppearanceService).new()
local DistrictConfiguration = require(ReplicatedStorage.Shared:WaitForChild("DistrictConfiguration"))

local WorldService = {}
WorldService.__index = WorldService

local PALETTE = {
	ground = Color3.fromRGB(25, 19, 43),
	floor = Color3.fromRGB(46, 34, 69),
	panel = Color3.fromRGB(63, 46, 92),
	white = Color3.fromRGB(244, 241, 255),
	muted = Color3.fromRGB(182, 174, 209),
	cyan = Color3.fromRGB(68, 224, 244),
	gold = Color3.fromRGB(255, 206, 84),
	purple = Color3.fromRGB(172, 105, 255),
}

local function color(hex, fallback)
	if type(hex) == "string" then
		local clean = hex:gsub("#", "")
		local ok, result = pcall(Color3.fromHex, clean)
		if ok then
			return result
		end
	end
	return fallback or PALETTE.cyan
end

local function part(parent, name, size, position, tint, material, collidable)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Anchored = true
	item.CanCollide = collidable ~= false
	item.CanTouch = false
	item.CastShadow = collidable ~= false
	item.Color = tint
	item.Material = material or Enum.Material.SmoothPlastic
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function label(parent, adornee, text, offset, width, height, tint, maxDistance)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Adornee = adornee
	billboard.Size = UDim2.fromOffset(width or 240, height or 70)
	billboard.StudsOffsetWorldSpace = offset or Vector3.new(0, 5, 0)
	billboard.MaxDistance = maxDistance or 105
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.Parent = parent
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundColor3 = PALETTE.ground
	textLabel.BackgroundTransparency = 0.15
	textLabel.TextColor3 = tint or PALETTE.white
	textLabel.TextStrokeTransparency = 0.75
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 18
	textLabel.TextWrapped = true
	textLabel.Text = text
	textLabel.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = textLabel
	return textLabel
end

local function prompt(host, action, objectText, ownerUserId)
	local item = Instance.new("ProximityPrompt")
	item.Name = "Open" .. action
	item.ActionText = "Open " .. action
	item.ObjectText = objectText
	item.MaxActivationDistance = 12
	item.HoldDuration = 0
	item.RequiresLineOfSight = false
	item.KeyboardKeyCode = Enum.KeyCode.E
	item:SetAttribute("Action", action)
	if ownerUserId then
		item:SetAttribute("OwnerUserId", ownerUserId)
	end
	item.Parent = host
	return item
end

local function number(value)
	for _, unit in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if value >= unit[1] then
			return string.format("%.1f%s", value / unit[1], unit[2])
		end
	end
	return string.format("%.0f", value)
end

local function animated(item, tag, attributes)
	for key, value in attributes or {} do item:SetAttribute(key, value) end
	CollectionService:AddTag(item, tag)
	return item
end

local function rarityColor(rarity)
	for index, definition in ipairs(Config.Rarities) do
		if definition.id == rarity then return color(definition.color), index end
	end
	return PALETTE.white, 1
end

local function portraitBoard(model, characterId, position, tint)
	local board = part(model, "PortraitCard", Vector3.new(4, 5.3, 0.15), position, PALETTE.ground, nil, false)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "CharacterPortrait"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 70
	gui.LightInfluence = 0
	gui.MaxDistance = 65
	gui.Parent = board
	local background = Instance.new("Frame")
	background.BackgroundColor3 = tint
	background.Size = UDim2.fromScale(1, 1)
	background.BorderSizePixel = 0
	background.Parent = gui
	local status = Instance.new("TextLabel")
	status.Name = "PhotoStatus"
	status.Size = UDim2.fromScale(0.9, 0.9)
	status.Position = UDim2.fromScale(0.05, 0.05)
	status.BackgroundTransparency = 1
	status.TextColor3 = PALETTE.white
	status.TextScaled = true
	status.TextWrapped = true
	status.Font = Enum.Font.GothamBold
	local visual = CharacterVisuals.get(characterId)
	status.Text = if visual.referenceType == "RealPerson" then "AUTHENTIC PHOTO REQUIRED" else "LEGACY TEST CARD\nPHOTO NOT SUPPLIED"
	status.Parent = background
	if visual.authenticPortraitReady and visual.portraitAssetId > 0 then
		local image = Instance.new("ImageLabel")
		image.Name = "ApprovedPortrait"
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(1, 1)
		image.ScaleType = Enum.ScaleType.Crop
		image.Image = "rbxassetid://" .. string.format("%.0f", visual.portraitAssetId)
		image.ZIndex = 3
		image.Parent = background
	end
	return board
end

local function displayEffects(model, host, tint, tier)
	local world = Config.World or {}
	if tier >= 3 and #CollectionService:GetTagged("MogvilleLight") < (world.MaxLights or 24) then
		local light = Instance.new("PointLight")
		light.Color = tint
		light.Brightness = 0.6
		light.Range = 12
		light.Shadows = false
		light.Enabled = false
		light.Parent = host
		CollectionService:AddTag(light, "MogvilleLight")
	end
	if tier >= 4 and #CollectionService:GetTagged("MogvilleParticles") < (world.MaxParticleEmitters or 24) then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "PrestigeSparkles"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(tint)
		emitter.LightEmission = 0.55
		emitter.Rate = math.min(world.MaxParticlesPerEmitter or 5, 3)
		emitter.Lifetime = NumberRange.new(0.8, 1.5)
		emitter.Speed = NumberRange.new(0.5, 1.2)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
		emitter.Enabled = false
		emitter.Parent = host
		CollectionService:AddTag(emitter, "MogvilleParticles")
	end
end

local function mogger(parent, instance, standPosition, ownerUserId)
	local stats = Rules.characterStats(instance)
	local tint, tier = rarityColor(stats.rarity)
	local visual = CharacterVisuals.get(instance.characterId)
	local model = Instance.new("Model")
	model.Name = instance.uid
	model.Parent = parent
	for key, value in { CharacterUID = instance.uid, CharacterId = instance.characterId,
		IdentityId = visual.identityId, Form = visual.form, Mutation = instance.mutation,
		Level = instance.level, OwnerUserId = ownerUserId } do model:SetAttribute(key, value) end
	local anchor = part(model, "DisplayAnchor", Vector3.new(0.2, 0.2, 0.2), standPosition + Vector3.new(0, 2.7, 0), tint, nil, false)
	anchor.Transparency = 1
	model.PrimaryPart = anchor
	local imported, reason = Appearance:createDisplay(instance.characterId, model, CFrame.new(standPosition + Vector3.new(0, 4.4, 0)))
	model:SetAttribute("ModelStatus", if imported then "ApprovedTemplate" else "ModelRequired")
	if reason then model:SetAttribute("AssetBlocker", reason) end
	-- Missing art is explicit. No block mannequin or invented human face is substituted.
	local cardX = if imported then 3.5 else 0
	local card = portraitBoard(model, instance.characterId, standPosition + Vector3.new(cardX, 3.6, 0.2), tint)
	local inspect = prompt(card, "Inspect", stats.name, ownerUserId)
	inspect.ActionText = "Inspect card"
	inspect.MaxActivationDistance = 10
	for key, value in { CharacterUID = instance.uid, CharacterId = instance.characterId, Mutation = instance.mutation, Level = instance.level } do inspect:SetAttribute(key, value) end
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 18
	click.Parent = card
	CollectionService:AddTag(click, "MogvilleInspect")
	label(model, anchor, string.upper(stats.name) .. " · " .. visual.form .. "\n" .. stats.rarity .. " · " .. number(stats.income) .. " Coins/sec\n" .. instance.mutation .. (if imported then "" else " · MODEL REQUIRED"), Vector3.new(0, 3.8, 0), 240, 82, tint, 65)
	displayEffects(model, anchor, tint, tier)
	return model
end

local function petModel(parent, definition, index, rootPart)
	local model = Instance.new("Model")
	model.Name = definition.name
	model.Parent = parent
	local offset = CFrame.new(3.5 + (index - 1) * 2.4, 0, 2)
	local body = part(model, "PetBody", Vector3.new(1.8, 1.5, 1.8), Vector3.zero, color(definition.color, PALETTE.gold), nil, false)
	model.PrimaryPart = body
	local pieces = { body }
	for _, side in ipairs({ -1, 1 }) do
		table.insert(pieces, part(model, "Ear", Vector3.new(0.5, 0.75, 0.6), Vector3.new(side * 0.6, 1, 0), body.Color, nil, false))
		table.insert(pieces, part(model, "Eye", Vector3.new(0.16, 0.2, 0.08), Vector3.new(side * 0.4, 0.15, -0.93), PALETTE.ground, nil, false))
	end
	for _, piece in ipairs(pieces) do
		local localFrame = piece.CFrame
		piece.CFrame = rootPart.CFrame * offset * localFrame
		piece.Anchored = false
		piece.Massless = true
		piece.CanQuery = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rootPart
		weld.Part1 = piece
		weld.Parent = piece
	end
	label(model, body, definition.name, Vector3.new(0, 1.6, 0), 140, 30, PALETTE.white, 50)
	return model
end

function WorldService.new()
	return setmetatable({ root = nil, plots = {}, assignments = {}, connections = {} }, WorldService)
end

function WorldService:build()
	if self.root and self.root.Parent then return self.root end
	local folder = Instance.new("Folder")
	folder.Name = "MogvilleWorld"
	folder:SetAttribute("GeneratedBy", "Mogville")
	folder.Parent = Workspace
	self.root = folder
	self.cityInfo = EnvironmentBuilder.build(folder, Config)
	local world = Config.World or {}
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "CollectorResidences"
	plotsFolder.Parent = folder
	for index = 1, Config.Game.MaxPlayers do
		local topology = DistrictConfiguration.plot(index, world)
		local side = topology.side
		local origin = Vector3.new(topology.x, topology.y, topology.z)
		local accent = Color3.fromHSV((index - 1) / Config.Game.MaxPlayers, 0.36, 0.95)
		local plot = Instance.new("Model")
		plot.Name = string.format("Residence_%02d", index)
		plot:SetAttribute("PlotIndex", index)
		plot:SetAttribute("AssetSlotKey", "plot_residence")
		plot:SetAttribute("PresentationStatus", "PlotLayoutPreview")
		plot.Parent = plotsFolder
		part(plot, "MarbleFloor", Vector3.new(88, 0.6, 54), origin, Color3.fromRGB(221, 225, 240), Enum.Material.Marble)
		local borders = {}
		for _, z in ipairs({ -26, 26 }) do
			table.insert(borders, part(plot, "GoldInlay", Vector3.new(88, 0.15, 0.35), origin + Vector3.new(0, 0.4, z), PALETTE.gold, Enum.Material.Metal, false))
		end
		for _, x in ipairs({ -43.5, 43.5 }) do
			table.insert(borders, part(plot, "ResidenceEdge", Vector3.new(0.4, 0.15, 52), origin + Vector3.new(x, 0.4, 0), accent, Enum.Material.Neon, false))
		end
		part(plot, "EntryCarpet", Vector3.new(88, 0.08, 7), origin + Vector3.new(0, 0.36, 0), PALETTE.floor, Enum.Material.Fabric, false)
		part(plot, "ConnectionPath", Vector3.new(37, 0.4, 9), Vector3.new(side * 126, -0.1, origin.Z), Color3.fromRGB(220, 221, 234), Enum.Material.Concrete)
		local sign = part(plot, "OwnerSign", Vector3.new(13, 4, 0.8), origin + Vector3.new(0, 3, -28), PALETTE.panel, nil, false)
		local signText = label(sign, sign, string.format("RESIDENCE %02d · AVAILABLE", index), Vector3.new(0, 1, 0), 300, 78, PALETTE.white, 100)
		part(plot, "SignCap", Vector3.new(13.8, 0.3, 1.1), origin + Vector3.new(0, 5.2, -28), PALETTE.gold, Enum.Material.Metal, false)
		local upgrades = Instance.new("Folder")
		upgrades.Name = "PrestigeDetails"
		upgrades.Parent = plot
		local display, pets = Instance.new("Folder"), Instance.new("Folder")
		display.Name, pets.Name = "Moggers", "Pets"
		display.Parent, pets.Parent = plot, plot
		local stands = {}
		for slot = 1, Config.Game.MaxSlots do
			local slotPosition = origin + Vector3.new(-34 + ((slot - 1) % 5) * 17, 0.8, math.floor((slot - 1) / 5) * 26 - 13)
			local stand = part(plot, "Stand" .. slot, Vector3.new(10, 0.8, 10), slotPosition, PALETTE.panel, Enum.Material.Marble)
			local rim = part(plot, "StandRim" .. slot, Vector3.new(10.5, 0.15, 10.5), slotPosition + Vector3.new(0, 0.5, 0), accent, Enum.Material.Neon, false)
			local open = prompt(stand, "Inventory", "Display stand " .. slot, 0)
			open.Enabled = false
			local caption = label(stand, stand, "LOCKED", Vector3.new(0, 1.2, 0), 125, 28, PALETTE.muted, 38)
			table.insert(stands, { part = stand, rim = rim, prompt = open, position = slotPosition, caption = caption })
		end
		local entrance = origin + Vector3.new(-side * 38, 4, 0)
		self.plots[index] = {
			model = plot, index = index, origin = origin, accent = accent, stands = stands, signText = signText,
			display = display, pets = pets, upgrades = upgrades, borders = borders, owner = nil,
			spawnCFrame = CFrame.new(entrance, origin + Vector3.new(0, 4, 0)),
		}
	end
	folder:SetAttribute("PlotCount", #self.plots)
	folder:SetAttribute("StandCount", #self.plots * Config.Game.MaxSlots)
	return folder
end

function WorldService:getPlot(player)
	return self.assignments[player]
end

function WorldService:_renderPets(player, plot)
	plot.pets:ClearAllChildren()
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not plot.profile then
		return
	end
	local byUid = {}
	for _, pet in ipairs(plot.profile.pets) do
		byUid[pet.uid] = pet
	end
	for index, uid in ipairs(plot.profile.equippedPets) do
		local pet = byUid[uid]
		local definition = pet and Config.Pets[pet.petId]
		if definition then
			petModel(plot.pets, definition, index, rootPart)
		end
	end
end

function WorldService:assign(player)
	if self.assignments[player] then
		return true
	end
	if not self.root then
		self:build()
	end
	local available
	for _, plot in ipairs(self.plots) do
		if not plot.owner then
			available = plot
			break
		end
	end
	if not available then
		return false, "All plots are occupied. Please join another server."
	end
	available.owner = player
	available.model:SetAttribute("OwnerUserId", player.UserId)
	available.signText.Text = string.upper(player.DisplayName) .. "'S PLOT\nPlace a Mogger from Inventory"
	self.assignments[player] = available
	for slot, stand in ipairs(available.stands) do
		stand.prompt:SetAttribute("OwnerUserId", player.UserId)
		stand.prompt.Enabled = slot <= Config.Game.BaseSlots
	end
	local function onCharacter(character)
		task.spawn(function()
			local rootPart = character:WaitForChild("HumanoidRootPart", 10)
			if rootPart and self.assignments[player] == available and player.Character == character then
				-- Start facing the spin hall; ownership is already allocated and the
				-- personal display stays reachable along the shared promenade.
				character:PivotTo(self.cityInfo.spawnCFrame or available.spawnCFrame)
				self:_renderPets(player, available)
			end
		end)
	end
	self.connections[player] = {
		player.CharacterAdded:Connect(onCharacter),
		player.CharacterRemoving:Connect(function() available.pets:ClearAllChildren() end),
	}
	if player.Character then
		onCharacter(player.Character)
	end
	return true
end

function WorldService:render(player, profile)
	local plot = self.assignments[player]
	if not plot then
		return
	end
	plot.profile = profile
	local byUid = {}
	for _, character in ipairs(profile.characters) do
		byUid[character.uid] = character
	end
	local signature = { tostring(profile.upgrades.slots), tostring(profile.upgrades.luck), tostring(profile.ascension) }
	for _, uid in ipairs(profile.placed) do
		local character = byUid[uid]
		if character then
			table.insert(signature, uid .. ":" .. character.level .. ":" .. character.mutation)
		end
	end
	for _, uid in ipairs(profile.equippedPets) do
		table.insert(signature, uid)
	end
	local key = table.concat(signature, "|")
	plot.signText.Text = string.upper(player.DisplayName) .. "'S PLOT\n" .. number(Rules.income(profile)) .. " Coins/sec  ·  " .. #profile.placed .. "/" .. math.min(Config.Game.MaxSlots, Config.Game.BaseSlots + profile.upgrades.slots) .. " stands"
	if plot.signature == key then
		return
	end
	plot.signature = key
	plot.display:ClearAllChildren()
	plot.upgrades:ClearAllChildren()
	local prestige = math.min(5, math.floor(profile.upgrades.slots / 2) + profile.ascension)
	if prestige > 0 then
		for _, x in ipairs({ -42, 42 }) do
			for _, z in ipairs({ -24, 24 }) do
				local height = 2 + prestige * 0.5
				part(plot.upgrades, "PrestigeColumn", Vector3.new(1.2, height, 1.2), plot.origin + Vector3.new(x, 0.3 + height / 2, z), PALETTE.gold, Enum.Material.Metal, false)
				part(plot.upgrades, "ColumnGem", Vector3.new(1.5, 1.5, 1.5), plot.origin + Vector3.new(x, height + 1, z), plot.accent, Enum.Material.Neon, false)
			end
		end
	end
	for _, border in ipairs(plot.borders) do border.Color = prestige >= 3 and PALETTE.gold or plot.accent end
	local limit = math.min(Config.Game.MaxSlots, Config.Game.BaseSlots + profile.upgrades.slots)
	for slot, stand in ipairs(plot.stands) do
		local unlocked = slot <= limit
		stand.part.Color = unlocked and Color3.fromRGB(234, 233, 245) or PALETTE.panel
		stand.part.Material = unlocked and Enum.Material.Marble or Enum.Material.SmoothPlastic
		stand.rim.Color = unlocked and plot.accent or PALETTE.muted
		stand.rim.Transparency = unlocked and 0 or 0.65
		stand.caption.Text = unlocked and ("STAND " .. slot) or "LOCKED"
		stand.caption.Visible = profile.placed[slot] == nil
		stand.prompt.Enabled = unlocked
		stand.prompt.ObjectText = unlocked and ("Your display stand " .. slot) or "Locked stand"
		local character = byUid[profile.placed[slot]]
		if character and unlocked then
			mogger(plot.display, character, stand.position, player.UserId)
		end
	end
	self:_renderPets(player, plot)
end

function WorldService:release(player)
	local connections = self.connections[player]
	if connections then
		for _, connection in ipairs(connections) do connection:Disconnect() end
		self.connections[player] = nil
	end
	local plot = self.assignments[player]
	if not plot then
		return
	end
	self.assignments[player] = nil
	plot.owner, plot.profile, plot.signature = nil, nil, nil
	plot.model:SetAttribute("OwnerUserId", nil)
	plot.display:ClearAllChildren()
	plot.pets:ClearAllChildren()
	plot.upgrades:ClearAllChildren()
	plot.signText.Text = string.format("RESIDENCE %02d · AVAILABLE", plot.index)
	for _, stand in ipairs(plot.stands) do
		stand.prompt.Enabled = false
		stand.prompt:SetAttribute("OwnerUserId", 0)
		stand.part.Color = PALETTE.panel
		stand.part.Material = Enum.Material.SmoothPlastic
		stand.rim.Color = PALETTE.muted
		stand.rim.Transparency = 0.65
		stand.caption.Text = "LOCKED"
		stand.caption.Visible = true
	end
end

return WorldService
