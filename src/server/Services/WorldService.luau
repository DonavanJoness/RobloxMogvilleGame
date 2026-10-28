-- Procedural scenery and presentation. Currency, ownership, and equipment live in services.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Rules = require(ReplicatedStorage.Shared:WaitForChild("Rules"))

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
		local ok, result = pcall(Color3.fromHex, hex:gsub("#", ""))
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

local function mogger(parent, instance, standPosition)
	local stats = Rules.characterStats(instance)
	local tint = color(stats.color)
	local model = Instance.new("Model")
	model.Name = instance.uid
	model:SetAttribute("CharacterUID", instance.uid)
	model.Parent = parent
	local base = standPosition + Vector3.new(0, 0.85, 0)
	local torso = part(model, "Jacket", Vector3.new(2.6, 2.4, 1.4), base + Vector3.new(0, 2.6, 0), tint, nil, false)
	model.PrimaryPart = torso
	part(model, "Head", Vector3.new(2, 1.7, 1.6), base + Vector3.new(0, 4.65, 0), Color3.fromRGB(235, 196, 151), nil, false)
	part(model, "Hair", Vector3.new(2.12, 0.4, 1.7), base + Vector3.new(0, 5.55, 0), PALETTE.ground, nil, false)
	for _, side in ipairs({ -1, 1 }) do
		part(model, "Arm", Vector3.new(0.7, 2.4, 1.2), base + Vector3.new(side * 1.75, 2.6, 0), tint, nil, false)
		part(model, "Leg", Vector3.new(0.95, 1.55, 1.2), base + Vector3.new(side * 0.65, 0.7, 0), PALETTE.ground, nil, false)
		part(model, "Eye", Vector3.new(0.27, 0.16, 0.08), base + Vector3.new(side * 0.43, 4.8, -0.83), PALETTE.ground, nil, false)
	end
	part(model, "Smile", Vector3.new(0.6, 0.1, 0.08), base + Vector3.new(0, 4.25, -0.83), PALETTE.ground, nil, false)
	local mutationTint = tint
	for _, mutation in ipairs(Config.Mutations) do
		if mutation.id == instance.mutation then
			mutationTint = color(mutation.color, tint)
			break
		end
	end
	part(model, "Crest", Vector3.new(0.75, 0.75, 0.14), base + Vector3.new(0, 2.85, -0.78), mutationTint, Enum.Material.Neon, false)
	if stats.rarity == "Mythic" or stats.rarity == "Divine" or stats.rarity == "Ascended" then
		for i = -1, 1 do
			part(model, "Crown", Vector3.new(0.4, 0.55 + (i == 0 and 0.3 or 0), 0.45), base + Vector3.new(i * 0.65, 5.95, 0), PALETTE.gold, Enum.Material.Neon, false)
		end
	end
	label(model, torso,
		string.upper(stats.name) .. "\n" .. string.upper(stats.rarity) .. "  ·  " .. number(stats.income) .. " Coins/sec\n" .. tostring(instance.mutation) .. " mutation",
		Vector3.new(0, 5.3, 0), 220, 82, tint, 72)
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
	if self.root and self.root.Parent then
		return self.root
	end
	local folder = Instance.new("Folder")
	folder.Name = "MogvilleWorld"
	folder:SetAttribute("GeneratedBy", "Mogville")
	folder.Parent = Workspace
	self.root = folder
	Lighting.ClockTime = 16
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(115, 101, 145)
	Lighting.OutdoorAmbient = Color3.fromRGB(125, 125, 155)
	part(folder, "Foundation", Vector3.new(390, 3, 390), Vector3.new(0, -2, 0), PALETTE.ground)
	part(folder, "StarterSquare", Vector3.new(94, 0.5, 350), Vector3.new(0, -0.2, 0), PALETTE.floor)
	for _, x in ipairs({ -46, 46 }) do
		part(folder, "PromenadeLight", Vector3.new(0.5, 0.2, 345), Vector3.new(x, 0.15, 0), PALETTE.cyan, Enum.Material.Neon, false)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MogvilleSpawn"
	spawn.Size = Vector3.new(14, 0.6, 14)
	spawn.Position = Vector3.new(0, 0.4, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = PALETTE.purple
	spawn.Material = Enum.Material.Neon
	spawn.Parent = folder
	label(spawn, spawn, Config.Game.Title .. "\nSTARTER SQUARE", Vector3.new(0, 12, 0), 390, 80, PALETTE.gold, 160)
	local tutorial = part(folder, "Welcome", Vector3.new(10, 7, 1), Vector3.new(0, 4, 19), PALETTE.panel)
	label(tutorial, tutorial, "YOUR FIRST MINUTE\n1. Open Inventory and place your starter\n2. Earn Coins each second\n3. Roll, collect, and build your team!", Vector3.new(0, 0, -0.8), 360, 105, PALETTE.white, 75)
	local stations = {
		{ "Roll", "THE ASCENSION ENGINE\nEarned Coins only · Odds in menu", Vector3.new(0, 0, -48), PALETTE.gold },
		{ "Pets", "PET PARLOR\nLittle friends. Big potential.", Vector3.new(-30, 0, -38), PALETTE.cyan },
		{ "Upgrades", "GLOW-UP LAB\nUpgrade luck and display slots", Vector3.new(30, 0, -38), PALETTE.purple },
		{ "Shop", "STYLE STUDIO\nOptional future premium items", Vector3.new(-30, 0, 39), PALETTE.gold },
		{ "Quests", "THE DAILY SPOTLIGHT\nClaim rewards for playing", Vector3.new(30, 0, 39), PALETTE.cyan },
		{ "Battle", "MOG-OFF ARENA\nBuild a team and challenge an NPC", Vector3.new(0, 0, 80), PALETTE.purple },
	}
	for _, station in ipairs(stations) do
		local position, tint = station[3], station[4]
		part(folder, station[1] .. "Stage", Vector3.new(19, 0.8, 17), position + Vector3.new(0, 0.3, 0), PALETTE.panel)
		local pillar = part(folder, station[1] .. "Terminal", Vector3.new(5, 5, 4), position + Vector3.new(0, 3, 0), tint, Enum.Material.Neon)
		local orb = part(folder, station[1] .. "Orb", Vector3.new(3.5, 3.5, 3.5), position + Vector3.new(0, 7.8, 0), tint, Enum.Material.Neon, false)
		orb.Shape = Enum.PartType.Ball
		label(pillar, pillar, station[2], Vector3.new(0, 8, 0), 255, 65, tint, 95)
		prompt(pillar, station[1], station[1] .. " Station")
	end
	local arena = part(folder, "Arena", Vector3.new(55, 0.7, 31), Vector3.new(0, 0.3, 112), PALETTE.panel)
	for _, x in ipairs({ -16, 16 }) do
		local disc = part(folder, "ArenaPad", Vector3.new(13, 0.25, 13), Vector3.new(x, 0.85, 112), x < 0 and PALETTE.cyan or PALETTE.purple, Enum.Material.Neon, false)
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = Vector3.new(0.25, 13, 13)
		disc.Orientation = Vector3.new(0, 0, 90)
	end
	arena:SetAttribute("Purpose", "Mog-Off presentation")
	local portal = part(folder, "FutureDistricts", Vector3.new(26, 12, 3), Vector3.new(0, 6, -137), PALETTE.panel)
	label(portal, portal, "BEYOND STARTER SQUARE\nGlow-Up District · Elite Boulevard\nFuture world expansion", Vector3.new(0, 3, 0), 330, 95, PALETTE.purple, 120)
	for index = 1, Config.Game.MaxPlayers do
		local side = index % 2 == 1 and -1 or 1
		local row = math.floor((index - 1) / 2)
		local origin = Vector3.new(side * 104, 0, -140 + row * 56)
		local plot = Instance.new("Model")
		plot.Name = "Plot" .. index
		plot.Parent = folder
		part(plot, "Floor", Vector3.new(76, 0.6, 47), origin, PALETTE.floor)
		part(plot, "Boundary", Vector3.new(77, 0.25, 48), origin - Vector3.new(0, 0.4, 0), PALETTE.purple, Enum.Material.Neon, false)
		local sign = part(plot, "OwnerSign", Vector3.new(6, 3, 1), origin + Vector3.new(0, 3, -24), PALETTE.panel)
		local signText = label(sign, sign, "AVAILABLE PLOT", Vector3.new(0, 3, 0), 285, 70, PALETTE.white, 100)
		local display = Instance.new("Folder")
		display.Name = "Moggers"
		display.Parent = plot
		local pets = Instance.new("Folder")
		pets.Name = "Pets"
		pets.Parent = plot
		local stands = {}
		for slot = 1, Config.Game.MaxSlots do
			local slotPosition = origin + Vector3.new(-28 + ((slot - 1) % 5) * 14, 0.7, math.floor((slot - 1) / 5) * 18 - 7)
			local stand = part(plot, "Stand" .. slot, Vector3.new(8, 0.8, 8), slotPosition, PALETTE.panel)
			local open = prompt(stand, "Inventory", "Display stand " .. slot, 0)
			open.Enabled = false
			table.insert(stands, { part = stand, prompt = open, position = slotPosition })
		end
		self.plots[index] = {
			model = plot, origin = origin, stands = stands, signText = signText,
			display = display, pets = pets, owner = nil,
			spawnCFrame = CFrame.new(origin + Vector3.new(0, 4, 21), origin + Vector3.new(0, 4, 0)),
		}
	end
	-- Local server board is intentionally labelled; no fake global totals are displayed.
	local board = part(folder, "LeaderboardBoard", Vector3.new(10, 8, 1), Vector3.new(0, 4.5, 145), PALETTE.panel)
	label(board, board, "MOGVILLE LEADERS\nSee the player list for server Coins,\nIncome, Wins, Collection, and Rank", Vector3.new(0, 1.5, 0), 340, 95, PALETTE.gold, 100)
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
				character:PivotTo(available.spawnCFrame)
				self:_renderPets(player, available)
			end
		end)
	end
	self.connections[player] = player.CharacterAdded:Connect(onCharacter)
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
	local limit = math.min(Config.Game.MaxSlots, Config.Game.BaseSlots + profile.upgrades.slots)
	for slot, stand in ipairs(plot.stands) do
		local unlocked = slot <= limit
		stand.part.Color = unlocked and PALETTE.cyan or PALETTE.panel
		stand.part.Material = unlocked and Enum.Material.Neon or Enum.Material.SmoothPlastic
		stand.prompt.Enabled = unlocked
		stand.prompt.ObjectText = unlocked and ("Your display stand " .. slot) or "Locked stand"
		local character = byUid[profile.placed[slot]]
		if character and unlocked then
			mogger(plot.display, character, stand.position)
		end
	end
	self:_renderPets(player, plot)
end

function WorldService:release(player)
	local connection = self.connections[player]
	if connection then
		connection:Disconnect()
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
	plot.signText.Text = "AVAILABLE PLOT"
	for _, stand in ipairs(plot.stands) do
		stand.prompt.Enabled = false
		stand.prompt:SetAttribute("OwnerUserId", 0)
		stand.part.Color = PALETTE.panel
		stand.part.Material = Enum.Material.SmoothPlastic
	end
end

return WorldService
