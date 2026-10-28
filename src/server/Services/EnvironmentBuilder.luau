-- Original collector-city layout preview. Approved architecture templates are
-- mounted at the declared slots by AssetLoadingService, never downloaded here.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DistrictConfiguration = require(ReplicatedStorage.Shared.DistrictConfiguration)

local EnvironmentBuilder = {}

local C = {
	white = Color3.fromRGB(242, 241, 247),
	marble = Color3.fromRGB(218, 220, 234),
	purple = Color3.fromRGB(116, 65, 205),
	dark = Color3.fromRGB(34, 30, 48),
	gold = Color3.fromRGB(255, 204, 87),
	cyan = Color3.fromRGB(84, 224, 237),
	green = Color3.fromRGB(91, 180, 120),
	grass = Color3.fromRGB(146, 191, 153),
	pink = Color3.fromRGB(246, 129, 201),
	glass = Color3.fromRGB(158, 211, 237),
}

function EnvironmentBuilder.build(root, config)
	local settings = config.World or {}
	local limits = {
		parts = settings.MaxStaticParts or settings.maxStaticParts or 1800,
		-- Reserve half the generation budget for owned-character presentations.
		lights = math.floor((settings.MaxLights or settings.maxLights or 24) / 2),
		emitters = math.floor((settings.MaxParticleEmitters or settings.maxParticleEmitters or 24) / 2),
	}
	local metrics = { parts = 0, lights = 0, emitters = 0 }
	local function district(name)
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = root
		return folder
	end
	local function part(parent, name, size, position, tint, material, collide)
		assert(metrics.parts < limits.parts, "Mogville static geometry exceeded World.MaxStaticParts")
		metrics.parts += 1
		local item = Instance.new("Part")
		item.Name = name
		item.Size = size
		item.CFrame = if typeof(position) == "CFrame" then position else CFrame.new(position)
		item.Color = tint or C.white
		item.Material = material or Enum.Material.SmoothPlastic
		item.Anchored = true
		item.CanCollide = collide == true
		item.CanTouch = false
		item.TopSurface = Enum.SurfaceType.Smooth
		item.BottomSurface = Enum.SurfaceType.Smooth
		item.Parent = parent
		return item
	end
	local function cylinder(parent, name, diameter, height, position, tint, material, collide)
		local item = part(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2), tint, material, collide)
		item.Shape = Enum.PartType.Cylinder
		return item
	end
	local function ball(parent, name, size, position, tint, material)
		local item = part(parent, name, Vector3.new(size, size, size), position, tint, material, false)
		item.Shape = Enum.PartType.Ball
		return item
	end
	local function tag(item, spin, bob)
		if spin then
			item:SetAttribute("SpinSpeed", spin)
			CollectionService:AddTag(item, "MogvilleSpin")
		end
		if bob then
			item:SetAttribute("BobAmplitude", bob)
			item:SetAttribute("BobSpeed", 1.2)
			CollectionService:AddTag(item, "MogvilleBob")
		end
	end
	local function label(host, text, width, height, tint, distance)
		local gui = Instance.new("BillboardGui")
		gui.Name = "DistrictSign"
		gui.Adornee = host
		gui.Size = UDim2.fromOffset(width or 300, height or 70)
		gui.MaxDistance = distance or 110
		gui.AlwaysOnTop = false
		gui.LightInfluence = 0
		gui.Parent = host
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.fromScale(1, 1)
		textLabel.BackgroundTransparency = 1
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextSize = 19
		textLabel.TextWrapped = true
		textLabel.TextColor3 = tint or C.white
		textLabel.TextStrokeTransparency = 0.4
		textLabel.Text = text
		textLabel.Parent = gui
		return gui
	end
	local function sign(parent, name, text, position, width, height, tint)
		local host = part(parent, name, Vector3.new(width or 18, height or 4, 0.6), position, C.dark, nil, false)
		part(parent, name .. "GoldTrim", Vector3.new((width or 18) + 0.4, 0.2, 0.8), host.Position + Vector3.new(0, (height or 4) / 2, 0), tint or C.gold, Enum.Material.Neon)
		label(host, text, math.clamp((width or 18) * 15, 220, 420), math.clamp((height or 4) * 16, 60, 105), tint, 135)
		return host
	end
	local function prompt(host, action, text)
		local item = Instance.new("ProximityPrompt")
		item.ActionText = if action == "Roll" then "Open Gacha · Earned Coins" else "Open " .. action
		item.ObjectText = text
		item.MaxActivationDistance = 13
		item.HoldDuration = 0
		item.RequiresLineOfSight = false
		item:SetAttribute("Action", action)
		item.Parent = host
		return item
	end
	local function light(host, tint, range)
		if metrics.lights >= limits.lights then return end
		metrics.lights += 1
		local item = Instance.new("PointLight")
		item.Color = tint
		item.Range = range or 15
		item.Brightness = 1.2
		item.Shadows = false
		item.Enabled = false -- WorldEffectsController enables only nearby budgeted lights.
		item.Parent = host
		CollectionService:AddTag(item, "MogvilleLight")
	end
	local function sparkles(host, tint)
		if metrics.emitters >= limits.emitters then return end
		metrics.emitters += 1
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "CitySparkles"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(tint)
		emitter.LightEmission = 0.6
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Rate = 4
		emitter:SetAttribute("MaxParticles", 12)
		emitter.Lifetime = NumberRange.new(1, 2)
		emitter.Speed = NumberRange.new(1, 2)
		emitter.SpreadAngle = Vector2.new(25, 25)
		emitter.Enabled = false
		emitter.Parent = host
		CollectionService:AddTag(emitter, "MogvilleParticles")
	end
	local function tree(parent, position, scale)
		local size = scale or 1
		part(parent, "Planter", Vector3.new(7, 1.6, 7) * size, position + Vector3.new(0, 0.8 * size, 0), C.white, Enum.Material.Marble, true)
		cylinder(parent, "TreeTrunk", 1.3 * size, 6 * size, position + Vector3.new(0, 4.5 * size, 0), Color3.fromRGB(132, 101, 80), nil, false)
		for _, offset in ipairs({ Vector3.new(-1.4, 7, 0), Vector3.new(1.4, 7, 0), Vector3.new(0, 9, 0) }) do
			ball(parent, "SculptedCanopy", 5 * size, position + offset * size, C.green)
		end
	end
	local function bench(parent, position, angle)
		local frame = CFrame.new(position) * CFrame.Angles(0, angle or 0, 0)
		part(parent, "BenchSeat", Vector3.new(8, 0.5, 2.5), frame * CFrame.new(0, 1.6, 0), C.purple, nil, true)
		part(parent, "BenchBack", Vector3.new(8, 2, 0.4), frame * CFrame.new(0, 2.7, 1.2), C.purple, nil, true)
		for _, x in ipairs({ -3, 3 }) do
			part(parent, "BenchLeg", Vector3.new(0.5, 1.5, 1.8), frame * CFrame.new(x, 0.75, 0), C.gold, Enum.Material.Metal, false)
		end
	end
	local function lamp(parent, position, tint)
		part(parent, "LampColumn", Vector3.new(0.7, 8, 0.7), position + Vector3.new(0, 4, 0), C.dark, Enum.Material.Metal)
		local globe = ball(parent, "LampGlobe", 1.8, position + Vector3.new(0, 8.4, 0), tint or C.gold, Enum.Material.Neon)
		light(globe, tint or C.gold, 16)
	end
	local function building(parent, name, origin, size, accent)
		local model = Instance.new("Model")
		model.Name = name
		model:SetAttribute("PresentationStatus", "ArchitectureLayoutPreview")
		model.Parent = parent
		part(model, "MarbleFloor", Vector3.new(size.X, 0.6, size.Z), origin + Vector3.new(0, 0.3, 0), C.white, Enum.Material.Marble, true)
		-- The open front spans the entire facade: there are no invisible door collisions.
		part(model, "BackWall", Vector3.new(size.X, size.Y, 1), origin + Vector3.new(0, size.Y / 2, -size.Z / 2), accent, nil, true)
		for _, x in ipairs({ -size.X / 2, size.X / 2 }) do
			part(model, "SideWall", Vector3.new(1, size.Y, size.Z), origin + Vector3.new(x, size.Y / 2, 0), accent, nil, true)
			part(model, "FrontColumn", Vector3.new(2.4, size.Y + 1, 2.4), origin + Vector3.new(x, size.Y / 2, size.Z / 2), C.white, Enum.Material.Marble, true)
			part(model, "ColumnAccent", Vector3.new(0.4, size.Y - 2, 2.7), origin + Vector3.new(x, size.Y / 2, size.Z / 2), C.gold, Enum.Material.Metal)
		end
		part(model, "RoofCrown", Vector3.new(size.X + 5, 1.4, size.Z + 4), origin + Vector3.new(0, size.Y + 0.7, 0), C.white, Enum.Material.Marble, true)
		part(model, "FacadeRibbon", Vector3.new(size.X + 5, 0.45, 1), origin + Vector3.new(0, size.Y + 1.7, size.Z / 2 + 1.5), accent, Enum.Material.Neon)
		for x = -size.X / 2 + 6, size.X / 2 - 6, 10 do
			local glass = part(model, "BackWindow", Vector3.new(6, size.Y * 0.45, 0.2), origin + Vector3.new(x, size.Y * 0.6, -size.Z / 2 + 0.6), C.glass, Enum.Material.Glass)
			glass.Transparency = 0.3
		end
		return model
	end

	-- Daylight keeps faces, walkways and controls readable; bloom is restrained.
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.5
	Lighting.GlobalShadows = true
	Lighting.Ambient = Color3.fromRGB(151, 143, 177)
	Lighting.OutdoorAmbient = Color3.fromRGB(175, 180, 197)
	Lighting.EnvironmentDiffuseScale = 0.8
	Lighting.EnvironmentSpecularScale = 0.7
	Lighting.FogStart = 450
	Lighting.FogEnd = 1400
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "MogvilleAtmosphere"
	atmosphere.Density = 0.2
	atmosphere.Offset = 0.2
	atmosphere.Haze = 0.8
	atmosphere.Glare = 0.1
	atmosphere.Color = Color3.fromRGB(212, 226, 255)
	atmosphere.Decay = Color3.fromRGB(160, 166, 187)
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "MogvilleBloom"
	bloom.Intensity = 0.12
	bloom.Size = 18
	bloom.Threshold = 1.25
	bloom.Parent = Lighting
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "MogvilleColor"
	correction.Saturation = 0.1
	correction.Contrast = 0.03
	correction.Brightness = 0.01
	correction.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Name = "MogvilleSunRays"
	rays.Intensity = 0.025
	rays.Spread = 0.8
	rays.Parent = Lighting

	local assetSlots = {}
	local slots = district("DistrictAssetSlots")
	for _, definition in ipairs(DistrictConfiguration.Districts) do
		local slot = Instance.new("Model")
		slot.Name = definition.id
		slot.WorldPivot = CFrame.new(definition.x, definition.y, definition.z)
		slot:SetAttribute("AssetKey", definition.assetKey)
		slot:SetAttribute("TargetFolder", definition.folder)
		slot:SetAttribute("FootprintWidth", definition.width)
		slot:SetAttribute("FootprintDepth", definition.depth)
		slot:SetAttribute("AssetStatus", "ApprovedTemplateRequired")
		slot.Parent = slots
		assetSlots[definition.assetKey] = slot
	end
	local roads = district("CityPaths")
	part(roads, "LandscapedFoundation", Vector3.new(540, 4, 600), Vector3.new(0, -2, -45), C.grass, Enum.Material.Grass, true)
	part(roads, "RoyalPromenade", Vector3.new(30, 0.3, 420), Vector3.new(0, 0.05, -25), C.white, Enum.Material.Marble, true)
	part(roads, "PlazaSquare", Vector3.new(106, 0.4, 83), Vector3.new(0, 0.2, 0), C.marble, Enum.Material.Marble, true)
	for _, x in ipairs({ -128, 128 }) do
		part(roads, "CollectorsWalk", Vector3.new(17, 0.3, 365), Vector3.new(x, 0.05, -3), C.white, Enum.Material.Marble, true)
		for row = 0, 5 do
			local z = -150 + row * 60
			local side = if x < 0 then -1 else 1
			part(roads, "PlotEntrancePath", Vector3.new(22, 0.3, 9), Vector3.new(side * 141, 0.1, z), C.marble, Enum.Material.Marble, true)
		end
	end
	for _, z in ipairs({ -160, -26, 66, 171 }) do
		part(roads, "CrossCityPath", Vector3.new(265, 0.25, 13), Vector3.new(0, 0.04, z), C.white, Enum.Material.Marble, true)
	end
	for _, x in ipairs({ -53, 53 }) do
		part(roads, "GachaSidePassage", Vector3.new(13, 0.3, 103), Vector3.new(x, 0.07, -114), C.marble, Enum.Material.Marble, true)
	end
	for _, x in ipairs({ -16, 16 }) do
		part(roads, "PromenadeGoldInlay", Vector3.new(0.3, 0.1, 400), Vector3.new(x, 0.3, -25), C.gold, Enum.Material.Metal)
	end
	for _, x in ipairs({ -113, 113 }) do
		for _, z in ipairs({ -147, -86, -25, 36, 97, 158 }) do
			tree(roads, Vector3.new(x, 0, z), 0.8)
		end
	end
	for _, x in ipairs({ -250, 250 }) do
		for _, z in ipairs({ -195, -115, -35, 45, 125, 205 }) do
			tree(roads, Vector3.new(x, 0, z), 1.3)
		end
	end

	local plaza = district("WelcomePlaza")
	for _, x in ipairs({ -23, 23 }) do
		part(plaza, "WelcomeColumn", Vector3.new(3, 16, 3), Vector3.new(x, 8, 34), C.purple, Enum.Material.Marble, true)
		part(plaza, "ColumnFoot", Vector3.new(5, 1, 5), Vector3.new(x, 0.5, 34), C.gold, Enum.Material.Metal, true)
	end
	sign(plaza, "WelcomeArch", "WELCOME TO MOGVILLE\nROLL · COLLECT · ASCEND", Vector3.new(0, 16, 34), 45, 5.5, C.gold)
	cylinder(plaza, "FountainBasin", 27, 1.2, Vector3.new(0, 0.9, -3), C.white, Enum.Material.Marble, true)
	cylinder(plaza, "FountainGoldRim", 26, 0.25, Vector3.new(0, 1.6, -3), C.gold, Enum.Material.Metal)
	local water = cylinder(plaza, "GlowingWater", 23, 0.35, Vector3.new(0, 1.8, -3), C.cyan, Enum.Material.Glass)
	water.Transparency = 0.25
	cylinder(plaza, "StatuePlinth", 7, 3.8, Vector3.new(0, 3, -3), C.purple, Enum.Material.Marble, true)
	local statue = Instance.new("Model")
	statue.Name = "OriginalChampionStatue"
	statue.Parent = plaza
	part(statue, "Torso", Vector3.new(4.2, 5.2, 2.4), Vector3.new(0, 9.5, -3), C.gold, Enum.Material.Metal)
	ball(statue, "Head", 3.6, Vector3.new(0, 14, -3), C.gold, Enum.Material.Metal)
	for _, side in ipairs({ -1, 1 }) do
		part(statue, "Leg", Vector3.new(1.6, 3.5, 1.9), Vector3.new(side, 5.9, -3), C.gold, Enum.Material.Metal)
		part(statue, "TriumphantArm", Vector3.new(1.4, 5, 1.8), CFrame.new(side * 3.6, 11.6, -3) * CFrame.Angles(0, 0, side * -0.7), C.gold, Enum.Material.Metal)
	end
	local crown = ball(statue, "CrownStar", 2.3, Vector3.new(0, 18, -3), C.gold, Enum.Material.Neon)
	tag(crown, 0.5, 0.4)
	sparkles(crown, C.gold)
	for i = 1, 6 do
		local angle = i * math.pi / 3
		local position = Vector3.new(math.cos(angle) * 8.5, 3.4, -3 + math.sin(angle) * 8.5)
		local jet = part(plaza, "FountainJet", Vector3.new(0.3, 2.9, 0.3), position, C.cyan, Enum.Material.Neon)
		jet.Transparency = 0.35
		local droplet = ball(plaza, "FountainDroplet", 0.7, position + Vector3.new(0, 2.4, 0), C.white, Enum.Material.Neon)
		tag(droplet, nil, 0.45)
	end
	for _, x in ipairs({ -37, 37 }) do
		bench(plaza, Vector3.new(x, 0.4, -6), if x < 0 then math.pi / 2 else -math.pi / 2)
		tree(plaza, Vector3.new(x, 0, 17), 1)
		tree(plaza, Vector3.new(x, 0, -29), 1)
		lamp(plaza, Vector3.new(x, 0, 30), C.gold)
	end
	sign(plaza, "NorthDirections", "NORTH  ↑  GACHA HALL\nASCENSION via the side passages", Vector3.new(27, 5, -35), 20, 4, C.cyan)
	sign(plaza, "SouthDirections", "SOUTH  ↓  MOG-OFF ARENA\nEAST → PETS & STYLE  ·  WEST → GYM", Vector3.new(-27, 5, 23), 20, 4, C.gold)
	local tutorial = sign(plaza, "TutorialKiosk", "FIRST MINUTE\nPlace starter → Earn Coins → Roll → Collect", Vector3.new(38, 4.5, 4), 17, 4.5, C.purple)
	prompt(tutorial, "Inventory", "Start earning on your plot")
	local questHost = sign(plaza, "QuestKiosk", "THE DAILY SPOTLIGHT\nPlay naturally. Claim earned rewards.", Vector3.new(-38, 4.5, 4), 17, 4.5, C.gold)
	prompt(questHost, "Quests", "Gameplay quests")
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MogvilleSpawn"
	spawn.Size = Vector3.new(9, 0.25, 9)
	local spawnLayout = DistrictConfiguration.Spawn
	spawn.CFrame = CFrame.lookAt(Vector3.new(spawnLayout.x, 0.55, spawnLayout.z), Vector3.new(spawnLayout.targetX, 0.55, spawnLayout.targetZ))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = C.purple
	spawn.Material = Enum.Material.Marble
	spawn.Parent = plaza
	metrics.parts += 1

	local gachaDistrict = district("GachaHall")
	local hall = building(gachaDistrict, "AscensionEngineHall", Vector3.new(0, 0, -108), Vector3.new(76, 20, 64), C.purple)
	sign(hall, "GachaFacade", "THE ASCENSION ENGINE\nSINGLE & 10× ROLLS · EARNED COINS ONLY", Vector3.new(0, 19, -74), 64, 5, C.gold)
	part(hall, "PurpleRunway", Vector3.new(16, 0.12, 53), Vector3.new(0, 0.67, -103), C.purple, Enum.Material.Fabric)
	for _, x in ipairs({ -9, 9 }) do
		part(hall, "RunwayTrim", Vector3.new(0.3, 0.15, 53), Vector3.new(x, 0.72, -103), C.gold, Enum.Material.Neon)
	end
	cylinder(hall, "MachineBase", 19, 1.5, Vector3.new(0, 1.3, -119), C.gold, Enum.Material.Metal, true)
	local core = part(hall, "RollMachine", Vector3.new(9, 8, 7), Vector3.new(0, 6, -119), C.dark, Enum.Material.Metal, true)
	part(hall, "MachineWindow", Vector3.new(7.5, 5, 0.3), Vector3.new(0, 6.5, -115.3), C.cyan, Enum.Material.Neon)
	local luckyOrb = ball(hall, "LuckyCore", 6, Vector3.new(0, 13, -119), C.gold, Enum.Material.Neon)
	CollectionService:AddTag(luckyOrb, "MogvilleGachaCore")
	tag(luckyOrb, 0.5, 0.55)
	light(luckyOrb, C.gold, 20)
	sparkles(luckyOrb, C.gold)
	prompt(core, "Roll", "Roll Machine · numerical odds in menu")
	sign(hall, "LuckDisclosure", "LUCK AMPLIFIES RARITY WEIGHTS\nYour exact boosted odds & pity appear in Roll", Vector3.new(-22, 7, -124), 20, 5, C.cyan)
	local weights, totalWeight = {}, 0
	for _, rarity in ipairs(config.Rarities) do totalWeight += rarity.weight end
	for _, rarity in ipairs(config.Rarities) do
		table.insert(weights, string.format("%.3g", rarity.weight / math.max(totalWeight, 1) * 100))
	end
	sign(hall, "OddsDisclosure", "BASE WEIGHTS  " .. table.concat(weights, " / ") .. "%\nBefore eligibility, luck & pity · exact odds in Roll", Vector3.new(22, 7, -124), 20, 5, C.gold)
	for i, rarity in ipairs(config.Rarities) do
		local tint = Color3.fromHex(rarity.color)
		local x = -30 + (i - 1) * 12
		local gem = part(hall, "RarityPreview_" .. rarity.id, Vector3.new(2.3, 2.3, 2.3), CFrame.new(x, 13, -96) * CFrame.Angles(0, 0, math.pi / 4), tint, Enum.Material.Neon)
		tag(gem, 0.4 + i * 0.04, 0.25)
		local caption = part(hall, "RarityCaption", Vector3.new(0.2, 0.2, 0.2), Vector3.new(x, 10.5, -96), tint)
		caption.Transparency = 1
		label(caption, rarity.name, 110, 28, tint, 72)
	end
	for _, x in ipairs({ -29, 29 }) do
		for _, z in ipairs({ -89, -110 }) do
			cylinder(hall, "HologramPedestal", 5, 0.9, Vector3.new(x, 1.1, z), C.gold, Enum.Material.Metal)
			local silhouette = ball(hall, "FloatingCollectionPreview", 3, Vector3.new(x, 4.7, z), C.cyan, Enum.Material.Neon)
			silhouette.Transparency = 0.35
			tag(silhouette, 0.25, 0.4)
		end
	end

	local arena = district("MogOffArena")
	part(arena, "ArenaEntranceRamp", Vector3.new(19, 0.3, math.sqrt(8 * 8 + 1.4 * 1.4)), CFrame.new(0, 0.7, 72) * CFrame.Angles(-math.atan2(1.4, 8), 0, 0), C.marble, Enum.Material.Marble, true)
	cylinder(arena, "CircularCombatStage", 74, 1, Vector3.new(0, 0.55, 111), C.dark, Enum.Material.Marble, true)
	cylinder(arena, "StageGoldRing", 72, 0.15, Vector3.new(0, 1.15, 111), C.gold, Enum.Material.Neon)
	cylinder(arena, "FightingFloor", 66, 0.2, Vector3.new(0, 1.3, 111), C.purple, Enum.Material.Marble, true)
	for _, x in ipairs({ -18, 18 }) do
		cylinder(arena, "CharacterSpawnMarker", 13, 0.2, Vector3.new(x, 1.5, 111), if x < 0 then C.cyan else C.pink, Enum.Material.Neon)
	end
	for row = 1, 3 do
		for column = -3, 3 do
			local angle = math.rad(35 + (column + 3) * 18)
			local radius = 40 + row * 4
			local position = Vector3.new(math.cos(angle) * radius, 0, 111 + math.sin(angle) * radius)
			local frame = CFrame.lookAt(position, Vector3.new(0, 0, 111))
			part(arena, "SpectatorTerrace", Vector3.new(10, row * 1.4, 4), frame * CFrame.new(0, row * 0.7, 0), C.marble, Enum.Material.Marble, true)
			part(arena, "SpectatorSeat", Vector3.new(7, 0.5, 2.4), frame * CFrame.new(0, row * 1.4 + 0.3, 0), C.purple, nil, true)
		end
	end
	for _, x in ipairs({ -15, 15 }) do
		part(arena, "EntranceColumn", Vector3.new(3, 14, 3), Vector3.new(x, 7, 68), C.dark, Enum.Material.Metal, true)
		local lightBar = part(arena, "EntranceLight", Vector3.new(0.5, 11, 0.5), Vector3.new(x, 7, 66.2), C.cyan, Enum.Material.Neon)
		light(lightBar, C.cyan)
	end
	sign(arena, "ArenaEntrance", "MOG-OFF ARENA\nPVE CHALLENGES · KEEP YOUR MOGGERS", Vector3.new(0, 14, 68), 34, 5, C.gold)
	sign(arena, "ArenaScoreboard", "ARENA SCOREBOARD\nYour battle result and turn log appear in Battle\nServer wins: see the player list", Vector3.new(0, 13, 153), 38, 6, C.cyan)
	for _, x in ipairs({ -49, 49 }) do
		lamp(arena, Vector3.new(x, 0, 102), C.cyan)
		local trophy = ball(arena, "VictoryBeacon", 2.5, Vector3.new(x, 12, 102), C.gold, Enum.Material.Neon)
		tag(trophy, 0.35, 0.3)
		sparkles(trophy, C.gold)
	end

	local gymDistrict = district("GlowUpGym")
	local gym = building(gymDistrict, "GlowUpGymClub", Vector3.new(-83, 0, -70), Vector3.new(47, 15, 45), C.cyan)
	sign(gym, "GymFacade", "GLOW-UP ATHLETIC CLUB\nGAMEPLAY UPGRADES · NO ROBUX REQUIRED", Vector3.new(-83, 15, -46), 44, 5, C.purple)
	local mirror = part(gym, "MirrorWall", Vector3.new(35, 7, 0.3), Vector3.new(-83, 7, -91.6), C.glass, Enum.Material.Glass)
	mirror.Reflectance = 0.45
	for _, x in ipairs({ -97, -84, -71 }) do
		part(gym, "WorkoutMat", Vector3.new(8, 0.15, 12), Vector3.new(x, 0.75, -77), C.purple, Enum.Material.Fabric)
		part(gym, "BenchPressSeat", Vector3.new(2.5, 1, 7), Vector3.new(x, 2, -77), C.dark, nil, true)
		for _, side in ipairs({ -1, 1 }) do
			part(gym, "WeightRack", Vector3.new(0.6, 5, 0.6), Vector3.new(x + side * 3, 3, -80), C.dark, Enum.Material.Metal)
			local weight = cylinder(gym, "BarbellWeight", 2.8, 0.9, Vector3.new(x + side * 2.5, 5.3, -80), C.dark, Enum.Material.Metal)
			weight.CFrame = CFrame.new(weight.Position) * CFrame.Angles(0, 0, 0)
		end
		local bar = part(gym, "Barbell", Vector3.new(7, 0.3, 0.3), Vector3.new(x, 5.3, -80), C.gold, Enum.Material.Metal)
		tag(bar, nil, 0.15)
	end
	for _, x in ipairs({ -97, -85 }) do
		part(gym, "TreadmillBase", Vector3.new(5, 0.8, 8), Vector3.new(x, 1, -57), C.dark, nil, true)
		part(gym, "TreadmillBelt", Vector3.new(3.7, 0.2, 6), Vector3.new(x, 1.5, -57), C.purple)
		part(gym, "TreadmillConsole", Vector3.new(4, 0.5, 1.2), Vector3.new(x, 4.5, -60), C.cyan, Enum.Material.Neon)
	end
	local upgradeHost = sign(gym, "GameplayUpgradeTerminal", "TRAINING DESK\nExisting luck, pet and display upgrades", Vector3.new(-67, 4.5, -56), 13, 4, C.cyan)
	prompt(upgradeHost, "Upgrades", "Gameplay upgrades")

	local shops = district("LuxuryShopStreet")
	local petShop = building(shops, "PetParlor", Vector3.new(83, 0, -70), Vector3.new(47, 15, 45), C.pink)
	sign(petShop, "PetShopFacade", "THE PET PARLOR\nGUARANTEED PETS · EARNED COINS", Vector3.new(83, 15, -46), 44, 5, C.cyan)
	for index, tint in ipairs({ C.pink, C.gold, C.cyan }) do
		local x = 69 + (index - 1) * 14
		cylinder(petShop, "PetShowcase", 8, 1.3, Vector3.new(x, 1.1, -77), C.white, Enum.Material.Marble, true)
		local pet = ball(petShop, "PetPreview", 3.5, Vector3.new(x, 4.5, -77), tint)
		tag(pet, 0.2, 0.25)
		for _, side in ipairs({ -1, 1 }) do
			ball(petShop, "PetEar", 1, Vector3.new(x + side, 6, -77), tint)
		end
	end
	local petHost = sign(petShop, "PetAdoptionTerminal", "ADOPTION DESK\nGuaranteed pets · earned Coins", Vector3.new(82, 4.5, -55), 15, 4, C.pink)
	prompt(petHost, "Pets", "Guaranteed pet collection")
	local style = building(shops, "StyleExchange", Vector3.new(83, 0, 12), Vector3.new(47, 15, 44), C.purple)
	sign(style, "StyleShopFacade", "THE STYLE EXCHANGE\nPREMIUM SHOWROOM · NOT FOR SALE", Vector3.new(83, 15, 35), 44, 5, C.gold)
	for index, tint in ipairs({ C.gold, C.purple, C.cyan }) do
		local x = 69 + (index - 1) * 14
		local shelf = part(style, "CosmeticShowcase", Vector3.new(9, 1.5, 7), Vector3.new(x, 1.3, 5), C.white, Enum.Material.Marble, true)
		local gem = part(style, "FutureCosmetic", Vector3.new(2.5, 2.5, 2.5), CFrame.new(x, 5, 5) * CFrame.Angles(0, 0, math.pi / 4), tint, Enum.Material.Neon)
		tag(gem, 0.3, 0.3)
		prompt(shelf, "Shop", "VIP · Cosmetics · Boosts: unavailable")
	end
	sign(style, "PremiumNotice", "DISPLAY ONLY\nNo product IDs configured. Free progression stays complete.", Vector3.new(83, 6, -7), 33, 4, C.white)
	for _, position in ipairs({ Vector3.new(53, 0, -41), Vector3.new(113, 0, -41), Vector3.new(53, 0, 40), Vector3.new(113, 0, 40) }) do
		lamp(shops, position, C.gold)
	end

	local ascension = district("AscensionHeights")
	part(ascension, "ElevatedMarbleTerrace", Vector3.new(104, 3, 70), Vector3.new(0, 10.5, -244), C.white, Enum.Material.Marble, true)
	part(ascension, "TerraceGoldFoundation", Vector3.new(109, 2, 75), Vector3.new(0, 8, -244), C.gold, Enum.Material.Metal, true)
	-- A 13.5-degree ramp: wide enough for touch controls, with no jump requirement.
	local ramp = part(ascension, "AccessibleAscensionRamp", Vector3.new(22, 0.7, math.sqrt(50 * 50 + 12 * 12)), CFrame.new(0, 6, -185) * CFrame.Angles(math.atan2(12, 50), 0, 0), C.white, Enum.Material.Marble, true)
	ramp:SetAttribute("Rise", 12)
	ramp:SetAttribute("Run", 50)
	for _, x in ipairs({ -11.5, 11.5 }) do
		part(ascension, "RampGoldEdge", Vector3.new(0.35, 0.25, math.sqrt(50 * 50 + 12 * 12)), CFrame.new(x, 6.5, -185) * CFrame.Angles(math.atan2(12, 50), 0, 0), C.gold, Enum.Material.Neon)
	end
	for _, x in ipairs({ -49, 49 }) do
		part(ascension, "TerraceBalustrade", Vector3.new(1.5, 3, 66), Vector3.new(x, 13.5, -244), C.purple, Enum.Material.Marble, true)
	end
	cylinder(ascension, "AscensionPlinth", 25, 2, Vector3.new(0, 13, -246), C.purple, Enum.Material.Marble, true)
	for _, x in ipairs({ -9, 9 }) do
		part(ascension, "MonumentSpire", Vector3.new(3, 24, 3), Vector3.new(x, 25, -246), C.gold, Enum.Material.Metal)
	end
	local ascensionCrystal = part(ascension, "AscensionCrystal", Vector3.new(7, 10, 7), CFrame.new(0, 25, -246) * CFrame.Angles(0, 0, math.pi / 4), C.cyan, Enum.Material.Neon)
	tag(ascensionCrystal, 0.18, 0.65)
	light(ascensionCrystal, C.cyan, 28)
	sparkles(ascensionCrystal, C.gold)
	sign(ascension, "AscensionMonumentSign", "ASCENSION HEIGHTS\nA HIGHER STANDARD, EARNED THROUGH PLAY", Vector3.new(0, 17, -220), 43, 5, C.gold)
	local progress = sign(ascension, "AscensionProgressKiosk", "YOUR NEXT RANK\nCheck collection, income and victories in Upgrades", Vector3.new(0, 15, -259), 36, 4, C.cyan)
	prompt(progress, "Upgrades", "Ascension milestones")
	for _, x in ipairs({ -34, 34 }) do
		tree(ascension, Vector3.new(x, 12, -226), 1)
		cylinder(ascension, "EliteShowcaseStand", 11, 1.3, Vector3.new(x, 12.8, -253), C.gold, Enum.Material.Metal, true)
		local trophy = ball(ascension, "EliteCollectionSymbol", 4, Vector3.new(x, 17, -253), C.purple, Enum.Material.Neon)
		tag(trophy, 0.3, 0.4)
	end

	-- A short branch from the collector promenade, away from the spin sightline.
	local park = district("ParkSocial")
	part(park, "GardenWalk", Vector3.new(58, 0.25, 62), Vector3.new(-83, 0.08, 60), C.marble, Enum.Material.Concrete, true)
	cylinder(park, "GardenPondRim", 23, 0.7, Vector3.new(-83, 0.55, 42), C.white, Enum.Material.Marble, true)
	local pond = cylinder(park, "GardenPond", 20, 0.15, Vector3.new(-83, 0.97, 42), C.cyan, Enum.Material.Glass)
	pond.Transparency = 0.3
	for _, x in ipairs({ -104, -62 }) do
		tree(park, Vector3.new(x, 0, 35), 0.9)
		tree(park, Vector3.new(x, 0, 85), 0.9)
		bench(park, Vector3.new(x, 0.3, 76), if x < -83 then math.pi / 2 else -math.pi / 2)
	end
	sign(park, "SocialGardenSign", "SOCIAL GARDENS\nMeet friends between rolls", Vector3.new(-83, 5, 86), 29, 4.5, C.green)
	local gardenGoals = sign(park, "GardenGoals", "YOUR NEXT COLLECTION GOAL\nClaim verified gameplay rewards in Quests", Vector3.new(-62, 4.5, 53), 15, 4, C.gold)
	prompt(gardenGoals, "Quests", "Collection goals")
	local arenaHost = sign(arena, "BattleTerminal", "ENTER A MOG-OFF\nChoose a PvE opponent", Vector3.new(26, 4.5, 72), 15, 4, C.cyan)
	prompt(arenaHost, "Battle", "PvE Mog-Offs")
	local previewNotice = sign(plaza, "VisualAssetStatus", "V3 LAYOUT PREVIEW\nApproved architecture and NPC templates are pending", Vector3.new(33, 4.5, -49), 24, 4, C.white)
	previewNotice:SetAttribute("Purpose", "Honest asset-dependent release status")
	root:SetAttribute("StaticPartCount", metrics.parts)
	root:SetAttribute("StaticLightCount", metrics.lights)
	root:SetAttribute("StaticEmitterCount", metrics.emitters)
	root:SetAttribute("Design", "Original card collector promenade · direct spin sightline")
	root:SetAttribute("PresentationStatus", "LayoutPreviewApprovedArchitecturePending")
	root:SetAttribute("LayoutReferenceStatus", DistrictConfiguration.Reference.status)
	return {
		spawnCFrame = CFrame.lookAt(Vector3.new(spawnLayout.x, spawnLayout.y, spawnLayout.z), Vector3.new(spawnLayout.targetX, spawnLayout.targetY, spawnLayout.targetZ)),
		metrics = metrics, assetSlots = assetSlots, npcPositions = DistrictConfiguration.NPCPositions,
	}
end

return EnvironmentBuilder
