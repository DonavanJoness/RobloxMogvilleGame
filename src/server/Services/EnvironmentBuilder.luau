-- Procedural city. This is an original, code-authored stand-in for artist-made architecture:
-- it is built from budgeted primitives (see EnvironmentKit) and is clearly marked as such
-- through attributes. Approved imported templates are still mounted into the declared
-- asset slots by AssetLoadingService and take priority; nothing here downloads assets.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local DistrictConfiguration = require(ReplicatedStorage.Shared.DistrictConfiguration)
local Kit = require(script.Parent.EnvironmentKit)
local Props = require(script.Parent.EnvironmentProps)
local Districts = require(script.Parent.EnvironmentDistricts)
local EnvironmentLighting = require(script.Parent.EnvironmentLighting)

local P, M, L = Kit.P, Enum.Material, Kit.Layer
local EnvironmentBuilder = {}

local function at(frame: CFrame, x: number, y: number, z: number): CFrame
	return frame * CFrame.new(x, y, z)
end

-- Flat disc whose top sits at topY.
local function disc(kit: any, parent: Instance, name: string, diameter: number, topY: number, thick: number, x: number, z: number, color: Color3, material: Enum.Material, opts: any?): Part
	return kit:cylinder(parent, name, diameter, thick, Vector3.new(x, topY - thick / 2, z), color, material, opts)
end

------------------------------------------------------------------------------------------
-- Ground, streets, boundary and scenery
------------------------------------------------------------------------------------------
local function buildGround(kit: any, folder: Instance)
	kit:block(folder, "LandscapedFoundation", Vector3.new(540, 4, 600), Vector3.new(0, -2, -45), P.grass, M.Grass, { collide = true })

	-- Boulevard: marble centre, granite flanks, gold inlay (inlay sits under the cross streets).
	kit:slab(folder, "PromenadeCenter", 14, 420, 0, -25, L.promenade, 0.3, P.cream, M.Marble)
	for _, side in { -1, 1 } do
		kit:slab(folder, "PromenadeFlank", 8, 420, side * 11, -25, L.promenade, 0.3, P.stone, M.Granite)
		kit:slab(folder, "PromenadeGoldInlay", 0.5, 420, side * 7.25, -25, L.inlay, 0.1, P.gold, M.Metal, {})
	end
	-- Cross streets, collector walks, plot entrances and hall passages each own a layer height.
	for _, z in { -160, -26, 66, 171 } do
		kit:slab(folder, "CrossCityPath", 265, 13, 0, z, L.cross, 0.25, P.stone, M.Cobblestone)
	end
	for _, x in { -128, 128 } do
		kit:slab(folder, "CollectorsWalk", 17, 365, x, -3, L.collector, 0.3, P.cream, M.Granite)
		kit:slab(folder, "CollectorsInlay", 1.2, 365, x, -3, L.collector + 0.07, 0.1, P.gold, M.Metal, {})
		local side = if x < 0 then -1 else 1
		for row = 0, 5 do
			kit:slab(folder, "PlotEntrancePath", 22, 9, side * 141, -150 + row * 60, L.passage, 0.3, P.marble, M.Marble)
		end
	end
	for _, x in { -53, 53 } do
		kit:slab(folder, "GachaSidePassage", 13, 103, x, -114, L.passage, 0.3, P.cream, M.Marble)
	end

	-- Perimeter: stone wall with clipped hedge so nobody walks off the foundation into the void.
	local edges = {
		{ 4, 600, -268, -45 }, { 4, 600, 268, -45 }, { 540, 4, 0, -343 }, { 540, 4, 0, 253 },
	}
	for _, e in edges do
		kit:block(folder, "BoundaryWall", Vector3.new(e[1], 7, e[2]), Vector3.new(e[3], 3.5, e[4]), P.stone, M.Slate, { collide = true })
		kit:block(folder, "BoundaryHedge", Vector3.new(e[1] + 1, 2.4, e[2] + 1), Vector3.new(e[3], 8.2, e[4]), P.leaf, M.Grass, { collide = true, cast = false })
	end
	for _, c in { { -268, -343 }, { 268, -343 }, { -268, 253 }, { 268, 253 } } do
		kit:cylinder(folder, "CornerTower", 9, 18, Vector3.new(c[1], 9, c[2]), P.cream, M.Marble, { collide = true })
		kit:cylinder(folder, "CornerTowerBand", 9.8, 1, Vector3.new(c[1], 14, c[2]), P.gold, M.Metal, { cast = false })
		kit:ball(folder, "CornerTowerDome", 9.4, Vector3.new(c[1], 18.4, c[2]), P.indigo, M.Metal, { cast = false })
		local star = kit:ball(folder, "CornerTowerStar", 1.8, Vector3.new(c[1], 24, c[2]), P.cyan, M.Neon, { cast = false })
		kit:tag(star, 0.5, 0.3)
	end

	-- Distant hills beyond the boundary give the island a horizon (visual only, no collision).
	for i = 0, 15 do
		local a = 2 * math.pi * i / 16
		local d = 110 + (i * 37 % 70)
		local reach = d * 0.5
		local x = math.cos(a) * (270 + reach * 1.5 + 140)
		local z = -45 + math.sin(a) * (300 + reach * 1.5 + 140)
		kit:ball(folder, "DistantHill", d, Vector3.new(x, -d * 0.32, z), if i % 3 == 0 then P.leaf else P.leaf2, M.Grass, { cast = false })
	end

	-- Promenade, collector-walk and plot-side lighting; trees line both collector walks.
	for _, z in { -215, -195, -50, 52, 180 } do
		for _, side in { -1, 1 } do Props.lamp(kit, folder, Vector3.new(side * 17.5, 0, z), P.gold) end
	end
	for _, x in { -113, 113 } do
		for _, z in { -147, -86, -25, 36, 97, 158 } do
			Props.tree(kit, folder, Vector3.new(x, 0, z), 0.8, if z % 2 == 0 then "round" else "blossom")
		end
	end
	for _, x in { -122, 122 } do
		for _, z in { -120, -60, 0, 60, 120 } do
			Props.lamp(kit, folder, Vector3.new(x, 0, z), P.cyan)
		end
	end
end

------------------------------------------------------------------------------------------
-- Central plaza
------------------------------------------------------------------------------------------
local function buildPlaza(kit: any, folder: Instance): SpawnLocation
	kit:slab(folder, "PlazaSquare", 106, 83, 0, 0, L.plaza, 0.3, P.cream, M.Marble)
	for _, e in { { 106, 3, 0, -40 }, { 106, 3, 0, 40 }, { 3, 83, -51.5, 0 }, { 3, 83, 51.5, 0 } } do
		kit:slab(folder, "PlazaBorder", e[1], e[2], e[3], e[4], L.plazaTrim, 0.2, P.stone, M.Granite)
	end

	-- Fountain: gold-ringed apron, polygonal basin, central pedestal carrying the hero statue.
	local fx, fz = 0, -3
	disc(kit, folder, "FountainGoldRing", 47, L.plazaInlay, 0.12, fx, fz, P.gold, M.Metal)
	disc(kit, folder, "FountainApron", 45.2, L.plazaInlay + 0.06, 0.12, fx, fz, P.stone, M.Granite, { collide = true })
	disc(kit, folder, "FountainFloor", 27, L.plazaInlay + 0.12, 0.1, fx, fz, P.cream, M.Marble, { collide = true })
	local rimY = L.plazaInlay + 0.12
	local center = Vector3.new(fx, 0, fz)
	Districts.ring(kit, folder, "FountainBasin", center, 13.6, 22, rimY, 2.4, 1.8, P.marble, M.Marble, { collide = true }, nil, P.cream)
	Districts.ring(kit, folder, "FountainBasinGold", center, 13.6, 22, rimY + 2.4, 0.3, 2.1, P.gold, M.Metal, { cast = false })
	kit:cylinder(folder, "FountainWater", 26.2, 1.5, Vector3.new(fx, rimY + 0.85, fz), P.cyan, M.Glass, { transparency = 0.42, reflectance = 0.1, cast = false })
	kit:cylinder(folder, "PedestalLower", 10, 3.6, Vector3.new(fx, rimY + 1.8, fz), P.marble, M.Marble, { collide = true })
	kit:cylinder(folder, "PedestalGoldBand", 10.6, 0.5, Vector3.new(fx, rimY + 3.5, fz), P.gold, M.Metal, { cast = false })
	kit:cylinder(folder, "PedestalUpper", 7, 3.2, Vector3.new(fx, rimY + 5.3, fz), P.purple, M.Marble, { collide = true })
	kit:cylinder(folder, "PedestalCap", 7.8, 0.5, Vector3.new(fx, rimY + 7.15, fz), P.gold, M.Metal, { collide = true })
	local statue = Props.hero(kit, folder, CFrame.new(fx, rimY + 7.4, fz), 0.8, P.gold, P.cyan)
	statue:SetAttribute("Design", "Original stylized hero, not a real person")
	for index = 0, 5 do
		local a = math.pi / 3 * index + math.pi / 6
		local x, z = fx + math.cos(a) * 8.4, fz + math.sin(a) * 8.4
		kit:cylinder(folder, "JetNozzle", 1.0, 1.0, Vector3.new(x, rimY + 1.9, z), P.gold, M.Metal, { cast = false })
		local arc = kit:cylinder(folder, "JetStream", 0.4, 3.6, Vector3.new(x, rimY + 4.2, z), P.cyan, M.Neon, { transparency = 0.45, cast = false })
		if index % 2 == 0 then kit:spray(arc, nil, 13) end
	end

	-- Seating, planting and lighting around the fountain
	for _, p in { { -30, -16, math.pi / 2 }, { 30, -16, -math.pi / 2 }, { -30, 10, math.pi / 2 }, { 30, 10, -math.pi / 2 } } do
		Props.bench(kit, folder, CFrame.new(p[1], L.plazaTrim, p[2]) * CFrame.Angles(0, p[3], 0))
	end
	for _, p in { { -22, -33 }, { 22, -33 }, { -22, 27 }, { 22, 27 } } do
		Props.planter(kit, folder, CFrame.new(p[1], L.plazaTrim, p[2]), 9, 3.2, { P.pink, P.gold, P.cyan, P.orange })
	end
	for _, p in { { -45, -31 }, { 45, -31 }, { -45, 29 }, { 45, 29 }, { -45, -3 }, { 45, -3 } } do
		Props.tree(kit, folder, Vector3.new(p[1], L.plazaTrim, p[2]), 0.92, if p[2] == -3 then "blossom" else "round")
	end
	for _, p in { { -50, -38 }, { 50, -38 }, { -50, 38 }, { 50, 38 }, { -26, 38 }, { 26, 38 }, { -26, -38 }, { 26, -38 } } do
		Props.lamp(kit, folder, Vector3.new(p[1], L.plazaTrim, p[2]), P.gold)
	end
	for _, p in { { -50, -18, math.pi / 2 }, { 50, -18, -math.pi / 2 }, { -50, 18, math.pi / 2 }, { 50, 18, -math.pi / 2 } } do
		Props.banner(kit, folder, CFrame.new(p[1], L.plazaTrim, p[2]) * CFrame.Angles(0, p[3], 0), P.indigo, P.gold)
	end
	for _, x in { -17, -12, 12, 17 } do
		Props.bollard(kit, folder, Vector3.new(x, L.plazaTrim, -39), P.cyan)
	end

	-- Information kiosks (real prompts) and wayfinding
	local tutorial = Props.kiosk(kit, folder, CFrame.new(40, L.plazaTrim, 2) * CFrame.Angles(0, -math.pi / 2, 0), "TutorialKiosk", "FIRST MINUTE\nPlace starter → Earn Coins → Roll → Collect", 17, 4.2, P.purple)
	kit:prompt(tutorial, "Inventory", "Start earning on your plot")
	local quests = Props.kiosk(kit, folder, CFrame.new(-40, L.plazaTrim, 2) * CFrame.Angles(0, math.pi / 2, 0), "QuestKiosk", "THE DAILY SPOTLIGHT\nPlay naturally. Claim earned rewards.", 17, 4.2, P.gold)
	kit:prompt(quests, "Quests", "Gameplay quests")
	Props.kiosk(kit, folder, CFrame.new(27, L.plazaTrim, -35.5), "NorthDirections", "NORTH  ↑  SPIN HALL\nASCENSION via the side passages", 20, 3.8, P.cyan)
	Props.kiosk(kit, folder, CFrame.new(-27, L.plazaTrim, 24) * CFrame.Angles(0, math.pi, 0), "SouthDirections", "SOUTH  ↓  MOG-OFF ARENA\nEAST → SHOPS  ·  WEST → GYM & GARDENS", 20, 3.8, P.gold)

	-- Welcome arch on the south edge: readable from the arena road and from inside the plaza.
	for _, x in { -22, 22 } do
		kit:block(folder, "ArchPier", Vector3.new(5, 19, 5), Vector3.new(x, L.plazaTrim + 9.5, 34), P.marble, M.Marble, { collide = true })
		kit:block(folder, "ArchPierBase", Vector3.new(6.6, 1.4, 6.6), Vector3.new(x, L.plazaTrim + 0.7, 34), P.stone, M.Granite, { collide = true })
		kit:block(folder, "ArchPierCap", Vector3.new(6.4, 0.9, 6.4), Vector3.new(x, L.plazaTrim + 19.4, 34), P.gold, M.Metal, { cast = false })
		kit:block(folder, "ArchPierNeon", Vector3.new(0.5, 15, 0.5), Vector3.new(x + (if x < 0 then 2.7 else -2.7), L.plazaTrim + 9.5, 31.4), P.cyan, M.Neon, { cast = false })
	end
	kit:block(folder, "ArchLintel", Vector3.new(50, 3.4, 5.6), Vector3.new(0, L.plazaTrim + 21.4, 34), P.indigo, M.Metal, { collide = true })
	kit:block(folder, "ArchLintelNeon", Vector3.new(50.4, 0.3, 5.9), Vector3.new(0, L.plazaTrim + 19.8, 34), P.gold, M.Neon, { cast = false })
	local archTop = L.plazaTrim + 23.1
	Props.mountSign(kit, folder, CFrame.new(0, archTop, 34), "WelcomeSignSouth", "WELCOME TO MOGVILLE\nROLL TO ASCEND", 0, 3.4, 2.9, 40, 6.6, P.gold)
	Props.mountSign(kit, folder, CFrame.new(0, archTop, 34) * CFrame.Angles(0, math.pi, 0), "WelcomeSignNorth", "MOGVILLE\nTHE COLLECTORS' PROMENADE", 0, 3.4, 2.9, 40, 6.6, P.cyan)
	for _, x in { -10, 10 } do
		kit:block(folder, "ArchPost", Vector3.new(0.8, 3.4, 0.8), Vector3.new(x, archTop + 1.7, 34), P.charcoal, M.Metal, { cast = false })
	end

	-- Spawn dais on the promenade, looking straight up the boulevard at the spin hall.
	local layout = DistrictConfiguration.Spawn
	disc(kit, folder, "SpawnGoldRing", 14.4, 0.3, 0.1, layout.x, layout.z, P.gold, M.Metal)
	disc(kit, folder, "SpawnDais", 13, 0.38, 0.14, layout.x, layout.z, P.marble, M.Marble, { collide = true })
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MogvilleSpawn"
	spawn.Size = Vector3.new(8, 0.2, 8)
	spawn.CFrame = CFrame.lookAt(Vector3.new(layout.x, 0.48, layout.z), Vector3.new(layout.targetX, 0.48, layout.targetZ))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = P.purple
	spawn.Material = M.Marble
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = folder
	kit.metrics.parts += 1
	return spawn
end

------------------------------------------------------------------------------------------
-- Spin hall (gacha)
------------------------------------------------------------------------------------------
local function buildHall(kit: any, folder: Instance, config: any)
	local F = CFrame.new(0, 0, -108)
	local W, D, H = 76, 64, 26
	local frontOpenings = {
		{ x = 0, w = 24, y0 = 0, y1 = 16, glass = false, trim = P.gold },
		{ x = -19, w = 9, y0 = 3, y1 = 18, glass = true, trim = P.marble },
		{ x = 19, w = 9, y0 = 3, y1 = 18, glass = true, trim = P.marble },
		{ x = -30, w = 6, y0 = 3, y1 = 18, glass = true, trim = P.marble },
		{ x = 30, w = 6, y0 = 3, y1 = 18, glass = true, trim = P.marble },
	}
	local model = Props.building(kit, folder, {
		name = "AscensionEngineHall", frame = F, width = W, depth = D, height = H,
		wall = { color = P.cream, material = M.Marble }, trim = P.marble, accent = P.purple, cap = P.gold,
		floor = { color = P.marble, material = M.Marble }, plinth = P.stone, frontOpenings = frontOpenings,
		sideWindows = 3, backWindows = 3, roof = "dome", domeRadius = 11, domeColor = P.gold,
	})

	-- Portico: raised terrace, stairs, four columns, entablature.
	local front = D / 2
	kit:block(model, "PorticoTerrace", Vector3.new(60, 0.9, 13.2), at(F, 0, 0.45, front + 7.4), P.stone, M.Granite, { collide = true })
	Props.stairs(kit, model, at(F, 0, 0, front + 14 + 4.8), 40, 3, 0.3, 1.6, P.marble, M.Marble)
	for _, x in { -22, -8, 8, 22 } do
		Props.column(kit, model, at(F, x, 0.9, front + 9), 20, 2.8, P.white, P.gold)
	end
	kit:block(model, "PorticoEntablature", Vector3.new(56, 1.6, 12), at(F, 0, 21.7, front + 6.6), P.marble, M.Marble, { collide = true })
	kit:block(model, "PorticoGoldBand", Vector3.new(56.4, 0.4, 12.4), at(F, 0, 20.8, front + 6.6), P.gold, M.Metal, { cast = false })
	kit:block(model, "PorticoNeon", Vector3.new(56.2, 0.25, 0.3), at(F, 0, 20.4, front + 12.7), P.purple, M.Neon, { cast = false })
	Props.mountSign(kit, model, F, "GachaFacade", "THE ASCENSION ENGINE\nSINGLE & 10× ROLLS · EARNED COINS ONLY", 0, 24.4, front + 0.45, 46, 5.2, P.gold)
	for _, x in { -34, 34 } do
		Props.banner(kit, model, at(F, x, 0.9, front + 6), P.indigo, P.gold)
		Props.planter(kit, model, at(F, x * 0.78, 0.9, front + 11), 6, 3, { P.pink, P.gold })
	end

	-- Glowing floor: runway carpet leading into a lit medallion beneath the machine.
	local mz = -11
	local fl = Props.FLOOR
	kit:block(model, "PurpleRunway", Vector3.new(14, 0.12, 27), at(F, 0, fl + 0.06, 14.5), P.purple, M.Fabric, { collide = true })
	for _, x in { -7.2, 7.2 } do
		kit:block(model, "RunwayTrim", Vector3.new(0.4, 0.14, 27), at(F, x, fl + 0.08, 14.5), P.gold, M.Neon, { cast = false })
	end
	disc(kit, model, "MedallionGold", 36, fl + 0.06, 0.1, 0, -108 + mz, P.gold, M.Metal)
	disc(kit, model, "MedallionDark", 33, fl + 0.12, 0.1, 0, -108 + mz, P.deep, M.Marble, { collide = true })
	disc(kit, model, "MedallionGlow", 25, fl + 0.18, 0.1, 0, -108 + mz, P.cyan, M.Neon)
	disc(kit, model, "MedallionInner", 23, fl + 0.24, 0.1, 0, -108 + mz, P.marble, M.Marble, { collide = true })

	-- The machine: base, cabinet (prompt host), glass capsule dome with a spinning core.
	kit:cylinder(model, "MachineBase", 17, 2.4, at(F, 0, fl + 1.2, mz).Position, P.gold, M.Metal, { collide = true })
	kit:cylinder(model, "MachineSkirt", 19, 0.8, at(F, 0, fl + 0.4, mz).Position, P.purple, M.Metal, { collide = true })
	local core = kit:cylinder(model, "RollMachine", 11, 8, at(F, 0, 6.0, mz).Position, P.deep, M.Metal, { collide = true })
	kit:cylinder(model, "MachineWindow", 11.4, 3, at(F, 0, 7, mz).Position, P.cyan, M.Neon, { cast = false })
	kit:cylinder(model, "MachineCollar", 12.4, 0.6, at(F, 0, 10.2, mz).Position, P.gold, M.Metal, { cast = false })
	kit:ball(model, "CapsuleDome", 13, at(F, 0, 16, mz).Position, P.glass, M.Glass, { transparency = 0.6, reflectance = 0.2, cast = false })
	local orb = kit:ball(model, "LuckyCore", 6, at(F, 0, 16, mz).Position, P.gold, M.Neon, { cast = false })
	CollectionService:AddTag(orb, "MogvilleGachaCore")
	kit:tag(orb, 0.5, 0.55)
	kit:light(orb, P.gold, 24)
	kit:sparkles(orb, P.gold)
	kit:cylinder(model, "MachineCrown", 5, 0.8, at(F, 0, 22.6, mz).Position, P.gold, M.Metal, { cast = false })
	kit:cylinder(model, "MachineSpire", 0.5, 4, at(F, 0, 25.2, mz).Position, P.gold, M.Metal, { cast = false })
	kit:block(model, "CoinChute", Vector3.new(3.4, 1.6, 2), at(F, 0, 3.6, mz + 5.4).Position, P.gold, M.Metal, { cast = false })
	for index, rarity in config.Rarities do
		local a = 2 * math.pi * (index - 1) / #config.Rarities
		local capsule = kit:ball(model, "CapsuleMarker", 2.2, at(F, math.cos(a) * 7.4, 12.2, mz + math.sin(a) * 7.4).Position, Color3.fromHex(rarity.color), M.Neon, { cast = false })
		kit:tag(capsule, nil, 0.3, 0.8 + index * 0.15)
	end
	kit:prompt(core, "Roll", "Roll Machine · numerical odds in menu")

	-- Rarity wall: six lit screens with a spinning gem under each.
	local n = #config.Rarities
	for index, rarity in config.Rarities do
		local tint = Color3.fromHex(rarity.color)
		local x = -30 + (index - 1) * (60 / math.max(n - 1, 1))
		Props.mountSign(kit, model, F, "RarityScreen", rarity.name, x, 18, -D / 2 + 1.6, 9, 3.6, tint)
		kit:block(model, "RarityPlinth", Vector3.new(2.6, 7, 2.6), at(F, x, fl + 3.5, -D / 2 + 4), P.marble, M.Marble, { collide = true })
		kit:block(model, "RarityPlinthCap", Vector3.new(3.4, 0.5, 3.4), at(F, x, fl + 7.2, -D / 2 + 4), tint, M.Neon, { cast = false })
		local gem = kit:block(model, "RarityPreview_" .. rarity.id, Vector3.new(2.3, 2.3, 2.3), at(F, x, fl + 10.1, -D / 2 + 4) * CFrame.Angles(0, 0, math.pi / 4), tint, M.Neon, { cast = false })
		kit:tag(gem, 0.4 + index * 0.04, 0.25)
	end
	local weights, total = {}, 0
	for _, rarity in config.Rarities do total += rarity.weight end
	for _, rarity in config.Rarities do
		table.insert(weights, string.format("%.3g", rarity.weight / math.max(total, 1) * 100))
	end
	Props.mountSign(kit, model, F, "LuckDisclosure", "LUCK AMPLIFIES RARITY WEIGHTS\nYour exact boosted odds & pity appear in Roll", -(W / 2 - 1.5), 9, -4, 20, 5, P.cyan, { dir = Vector3.new(1, 0, 0) })
	Props.mountSign(kit, model, F, "OddsDisclosure", "BASE WEIGHTS  " .. table.concat(weights, " / ") .. "%\nBefore eligibility, luck & pity · exact odds in Roll", W / 2 - 1.5, 9, -4, 20, 5, P.gold, { dir = Vector3.new(-1, 0, 0) })

	-- Interior architecture: columns, chandelier, ceiling neon, display cases, holo pedestals.
	for _, x in { -26, 26 } do
		for _, z in { -6, -24 } do
			Props.column(kit, model, at(F, x, fl, z), 25.4, 2.8, P.white, P.gold)
		end
	end
	kit:cylinder(model, "ChandelierRing", 18, 0.5, at(F, 0, 22, mz).Position, P.gold, M.Metal, { cast = false })
	kit:cylinder(model, "ChandelierGlow", 15, 0.2, at(F, 0, 21.7, mz).Position, P.cyan, M.Neon, { cast = false })
	for _, x in { -18, 18 } do
		kit:block(model, "CeilingNeon", Vector3.new(0.6, 0.3, 54), at(F, x, H - 0.1, 0), if x < 0 then P.cyan else P.pink, M.Neon, { cast = false })
	end
	for _, x in { -29, 29 } do
		for _, z in { 12, -8 } do
			kit:cylinder(model, "HologramPedestal", 5, 0.9, at(F, x, fl + 0.45, z).Position, P.gold, M.Metal, { collide = true })
			kit:cylinder(model, "HologramRing", 5.6, 0.2, at(F, x, fl + 0.95, z).Position, P.cyan, M.Neon, { cast = false })
			local preview = kit:ball(model, "FloatingCollectionPreview", 3, at(F, x, fl + 4.4, z).Position, P.cyan, M.Neon, { transparency = 0.35, cast = false })
			kit:tag(preview, 0.25, 0.4)
		end
	end
	for _, x in { -33, 33 } do
		kit:block(model, "DisplayCaseBase", Vector3.new(4, 1.4, 8), at(F, x, fl + 0.7, 22), P.charcoal, M.Marble, { collide = true })
		kit:block(model, "DisplayCaseGlass", Vector3.new(3.6, 6, 7.6), at(F, x, fl + 4.4, 22), P.glass, M.Glass, { transparency = 0.7, collide = true, cast = false })
		kit:block(model, "DisplayCaseCap", Vector3.new(4.2, 0.5, 8.2), at(F, x, fl + 7.7, 22), P.gold, M.Metal, { cast = false })
		local trophy = kit:ball(model, "DisplayCaseTrophy", 2.2, at(F, x, fl + 3.9, 22).Position, P.gold, M.Metal, { cast = false })
		kit:tag(trophy, 0.5, 0.2)
	end
end

------------------------------------------------------------------------------------------
-- Ascension Heights
------------------------------------------------------------------------------------------
local function buildAscension(kit: any, folder: Instance)
	local top = 12
	kit:block(folder, "TerraceStoneBase", Vector3.new(114, 2, 80), Vector3.new(0, 6, -244), P.stone, M.Granite, { collide = true })
	kit:block(folder, "TerraceGoldFoundation", Vector3.new(109, 2, 75), Vector3.new(0, 8, -244), P.gold, M.Metal, { collide = true })
	kit:block(folder, "ElevatedMarbleTerrace", Vector3.new(104, 3, 70), Vector3.new(0, 10.5, -244), P.white, M.Marble, { collide = true })
	-- Inlaid compass on the terrace
	disc(kit, folder, "TerraceMedallionGold", 40, top + 0.06, 0.1, 0, -246, P.gold, M.Metal)
	disc(kit, folder, "TerraceMedallion", 37, top + 0.12, 0.1, 0, -246, P.violet, M.Marble)

	-- Accessible ramp (13.5° - wide enough for touch controls, no jump needed)
	local length = math.sqrt(50 * 50 + 12 * 12)
	local tilt = math.atan2(12, 50)
	local ramp = kit:block(folder, "AccessibleAscensionRamp", Vector3.new(22, 0.7, length), CFrame.new(0, 6, -185) * CFrame.Angles(tilt, 0, 0), P.white, M.Marble, { collide = true })
	ramp:SetAttribute("Rise", 12)
	ramp:SetAttribute("Run", 50)
	for _, x in { -11.2, 11.2 } do
		kit:block(folder, "RampGoldEdge", Vector3.new(0.35, 0.25, length), CFrame.new(x, 6.5, -185) * CFrame.Angles(tilt, 0, 0), P.gold, M.Neon, { cast = false })
		kit:block(folder, "RampWall", Vector3.new(1.4, 2.6, length), CFrame.new(x * 1.12, 7.3, -185) * CFrame.Angles(tilt, 0, 0), P.cream, M.Marble, { collide = true })
	end

	-- Gate at the foot of the ramp
	for _, x in { -15, 15 } do
		kit:block(folder, "GatePylon", Vector3.new(3.4, 16, 3.4), Vector3.new(x, 8, -165), P.white, M.Marble, { collide = true })
		kit:block(folder, "GatePylonBand", Vector3.new(4.2, 0.8, 4.2), Vector3.new(x, 14.5, -165), P.gold, M.Metal, { cast = false })
		local flame = kit:ball(folder, "GateFlame", 2.4, Vector3.new(x, 17.4, -165), P.orange, M.Neon, { cast = false })
		kit:tag(flame, nil, 0.25)
		kit:sparkles(flame, P.orange)
	end
	kit:block(folder, "GateLintel", Vector3.new(33.4, 2.6, 3.8), Vector3.new(0, 15.4, -165), P.white, M.Marble, { collide = true })
	kit:block(folder, "GateLintelGold", Vector3.new(34, 0.5, 4.2), Vector3.new(0, 14, -165), P.gold, M.Metal, { cast = false })
	Props.mountSign(kit, folder, CFrame.new(0, 17, -165), "AscensionMonumentSign", "ASCENSION HEIGHTS\nA HIGHER STANDARD, EARNED THROUGH PLAY", 0, 3.4, 2.1, 34, 5, P.gold)

	-- Terrace balustrade with posts
	for _, x in { -50.5, 50.5 } do
		kit:block(folder, "TerraceRail", Vector3.new(1.2, 1.2, 68), Vector3.new(x, top + 2.8, -244), P.cream, M.Marble, { collide = true })
		kit:block(folder, "TerraceBalustrade", Vector3.new(1.6, 2.6, 68), Vector3.new(x, top + 1.3, -244), P.purple, M.Marble, { collide = true })
	end
	kit:block(folder, "TerraceBackRail", Vector3.new(102, 1.2, 1.2), Vector3.new(0, top + 2.8, -278), P.cream, M.Marble, { collide = true })
	kit:block(folder, "TerraceBackWall", Vector3.new(102, 2.6, 1.6), Vector3.new(0, top + 1.3, -278), P.purple, M.Marble, { collide = true })
	for _, x in { -50.5, 50.5 } do
		for _, z in { -276, -262, -248, -234, -220 } do
			kit:cylinder(folder, "BalustradePost", 1.6, 3.6, Vector3.new(x, top + 1.8, z), P.white, M.Marble, { cast = false })
		end
	end
	for _, side in { -1, 1 } do
		kit:block(folder, "TerraceFrontRail", Vector3.new(38, 2.6, 1.6), Vector3.new(side * 33, top + 1.3, -210.4), P.purple, M.Marble, { collide = true })
	end

	-- Colonnade and entablature along both sides
	for _, x in { -42, 42 } do
		for _, z in { -228, -238, -248, -258, -268 } do
			Props.column(kit, folder, CFrame.new(x, top, z), 18, 2.8, P.white, P.gold)
		end
		kit:block(folder, "ColonnadeBeam", Vector3.new(3.6, 1.8, 46), Vector3.new(x, top + 18.9, -248), P.white, M.Marble, { cast = false })
		kit:block(folder, "ColonnadeGold", Vector3.new(3.9, 0.4, 46.4), Vector3.new(x, top + 17.9, -248), P.gold, M.Metal, { cast = false })
	end

	-- Monument: stepped plinth, spires, orbiting rings and the spinning crystal
	disc(kit, folder, "MonumentStepLow", 31, top + 0.9, 0.9, 0, -246, P.stone, M.Granite, { collide = true })
	kit:cylinder(folder, "AscensionPlinth", 25, 2, Vector3.new(0, top + 1.9, -246), P.purple, M.Marble, { collide = true })
	kit:cylinder(folder, "AscensionPlinthGold", 26, 0.4, Vector3.new(0, top + 2.9, -246), P.gold, M.Metal, { cast = false })
	for _, x in { -9, 9 } do
		kit:block(folder, "MonumentSpire", Vector3.new(3, 24, 3), Vector3.new(x, 25, -246), P.gold, M.Metal, { cast = false })
		kit:block(folder, "MonumentSpireTip", Vector3.new(2.2, 2.2, 2.2), CFrame.new(x, 37.6, -246) * CFrame.Angles(0, 0, math.pi / 4), P.cyan, M.Neon, { cast = false })
	end
	local crystal = kit:block(folder, "AscensionCrystal", Vector3.new(7, 10, 7), CFrame.new(0, 25, -246) * CFrame.Angles(0, 0, math.pi / 4), P.cyan, M.Neon, { cast = false })
	kit:tag(crystal, 0.18, 0.65)
	kit:light(crystal, P.cyan, 30)
	kit:sparkles(crystal, P.gold)
	for index, y in { 21, 29 } do
		local ringPart = kit:cylinder(folder, "OrbitRing", 17 - index * 2, 0.3, Vector3.new(0, y, -246), P.gold, M.Neon, { transparency = 0.2, cast = false })
		kit:tag(ringPart, 0.3 + index * 0.1, 0.4)
	end

	-- Giant guardian statues (original design) flanking the approach
	for _, x in { -30, 30 } do
		kit:block(folder, "StatuePlinth", Vector3.new(11, 3, 11), Vector3.new(x, top + 1.5, -224), P.white, M.Marble, { collide = true })
		kit:block(folder, "StatuePlinthGold", Vector3.new(11.8, 0.6, 11.8), Vector3.new(x, top + 3.3, -224), P.gold, M.Metal, { cast = false })
		Props.hero(kit, folder, CFrame.new(x, top + 3.6, -224) * CFrame.Angles(0, math.pi, 0), 1.15, P.white, if x < 0 then P.cyan else P.gold)
	end

	-- Portal frame at the north end: decorative gate, honestly labelled, with a real info prompt.
	local pcx, pcy, pcz = 0, top + 15.5, -274
	for step = 1, 3 do
		kit:block(folder, "PortalStep", Vector3.new(26 - step * 2, 0.5, 4), Vector3.new(0, top + step * 0.5 - 0.25, -271 + (3 - step) * 0.6), P.white, M.Marble, { collide = true })
	end
	local segments = 22
	local radius = 11
	for i = 0, segments - 1 do
		local a = 2 * math.pi * i / segments
		kit:block(folder, "PortalFrame", Vector3.new(2 * radius * math.sin(math.pi / segments) * 1.1, 2.2, 2), CFrame.new(pcx + math.cos(a) * radius, pcy + math.sin(a) * radius, pcz) * CFrame.Angles(0, 0, a + math.pi / 2), if i % 2 == 0 then P.gold else P.white, if i % 2 == 0 then M.Metal else M.Marble, { cast = false })
	end
	local surface = kit:cylinder(folder, "PortalSurface", 19.5, 0.3, CFrame.new(pcx, pcy, pcz) * CFrame.Angles(0, math.pi / 2, 0), P.violet, M.Neon, { horizontal = true, transparency = 0.45, cast = false })
	kit:tag(surface, nil, 0.2)
	kit:sparkles(surface, P.violet)
	local progress = Props.kiosk(kit, folder, CFrame.new(0, top, -259), "AscensionProgressKiosk", "YOUR NEXT RANK\nCheck collection, income and victories in Upgrades", 30, 3.8, P.cyan)
	kit:prompt(progress, "Upgrades", "Ascension milestones")

	-- Floating ornaments, braziers and elite showcase stands
	for i = 0, 7 do
		local a = 2 * math.pi * i / 8
		local gem = kit:block(folder, "FloatingCrystal", Vector3.new(3, 5, 3), CFrame.new(math.cos(a) * 32, 30 + (i % 3) * 3, -246 + math.sin(a) * 22) * CFrame.Angles(0, 0, math.pi / 4), if i % 2 == 0 then P.cyan else P.gold, M.Neon, { cast = false })
		kit:tag(gem, 0.3 + (i % 4) * 0.1, 0.5, 0.8 + i * 0.12)
	end
	for _, x in { -34, 34 } do
		Props.tree(kit, folder, Vector3.new(x, top, -208), 0.95, "blossom")
		kit:cylinder(folder, "EliteShowcaseStand", 11, 1.3, Vector3.new(x, top + 0.65, -253), P.gold, M.Metal, { collide = true })
		kit:cylinder(folder, "EliteShowcaseRing", 11.8, 0.2, Vector3.new(x, top + 1.3, -253), P.cyan, M.Neon, { cast = false })
		local trophy = kit:ball(folder, "EliteCollectionSymbol", 4, Vector3.new(x, top + 5.2, -253), P.purple, M.Neon, { cast = false })
		kit:tag(trophy, 0.3, 0.4)
	end
	for _, x in { -12, 12 } do
		Props.lamp(kit, folder, Vector3.new(x, top, -213), P.gold)
	end
end

------------------------------------------------------------------------------------------
-- Entry point
------------------------------------------------------------------------------------------
function EnvironmentBuilder.build(root: Instance, config: any)
	local settings = config.World or {}
	local limits = {
		parts = settings.MaxStaticParts or settings.maxStaticParts or 3400,
		-- Reserve half of the generation budget for owned-character presentations.
		lights = math.floor((settings.MaxLights or settings.maxLights or 32) / 2),
		emitters = math.floor((settings.MaxParticleEmitters or settings.maxParticleEmitters or 28) / 2),
	}
	local kit = Kit.new(root, limits)
	EnvironmentLighting.apply()

	-- Slots for approved imported architecture (AssetLoadingService mounts them here).
	local assetSlots = {}
	local slots = kit:folder(root, "DistrictAssetSlots")
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

	-- Per-district accounting so the budget is a design decision, not a surprise.
	local cost = {}
	local function measure(name: string, build: () -> ())
		local before = kit.metrics.parts
		build()
		cost[name] = kit.metrics.parts - before
		root:SetAttribute("Parts_" .. name, cost[name])
	end
	measure("CityPaths", function() buildGround(kit, kit:folder(root, "CityPaths")) end)
	measure("WelcomePlaza", function() buildPlaza(kit, kit:folder(root, "WelcomePlaza")) end)
	measure("GachaHall", function() buildHall(kit, kit:folder(root, "GachaHall"), config) end)
	measure("LuxuryShopStreet", function() Districts.shops(kit, kit:folder(root, "LuxuryShopStreet")) end)
	measure("GymAndBoutique", function() Districts.westSide(kit, kit:folder(root, "GlowUpGym"), kit:folder(root, "MoggerBoutique")) end)
	measure("MogOffArena", function() Districts.arena(kit, kit:folder(root, "MogOffArena")) end)
	measure("AscensionHeights", function() buildAscension(kit, kit:folder(root, "AscensionHeights")) end)
	measure("ParkSocial", function() Districts.park(kit, kit:folder(root, "ParkSocial")) end)

	-- Developer-only status board (never shown to live players).
	local showStatus = settings.ShowAssetStatusSign
	if showStatus == nil then showStatus = RunService:IsStudio() end
	if showStatus then
		local board = Props.kiosk(kit, root:FindFirstChild("WelcomePlaza") :: Instance, CFrame.new(33, L.plazaTrim, -46) * CFrame.Angles(0, math.pi, 0), "VisualAssetStatus", "STUDIO ONLY · PROCEDURAL STAND-IN ART\nSwap in approved templates via AssetManifest", 24, 4, P.white)
		board:SetAttribute("Purpose", "Developer-only asset status; hidden outside Studio")
	end

	local layout = DistrictConfiguration.Spawn
	root:SetAttribute("StaticPartCount", kit.metrics.parts)
	root:SetAttribute("StaticLightCount", kit.metrics.lights)
	root:SetAttribute("StaticEmitterCount", kit.metrics.emitters)
	root:SetAttribute("StaticSignCount", kit.metrics.signs)
	root:SetAttribute("Design", "Original card collector promenade · direct spin sightline")
	root:SetAttribute("PresentationStatus", "ProceduralStandInArchitecture")
	root:SetAttribute("ArtDirection", "Indigo, gold and cyan on warm marble; one palette across all districts")
	root:SetAttribute("LayoutReferenceStatus", DistrictConfiguration.Reference.status)
	local metrics = kit.metrics
	metrics.cost = cost
	return {
		spawnCFrame = CFrame.lookAt(Vector3.new(layout.x, layout.y, layout.z), Vector3.new(layout.targetX, layout.targetY, layout.targetZ)),
		metrics = metrics, assetSlots = assetSlots, npcPositions = DistrictConfiguration.NPCPositions,
	}
end

return EnvironmentBuilder
