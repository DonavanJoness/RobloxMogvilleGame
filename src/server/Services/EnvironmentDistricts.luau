-- Shopping street, gym, boutique, Mog-Off stadium and social gardens.
-- Every building is authored separately (palette, materials, roof landmark, interior) so
-- the street reads as different businesses rather than one recolored box.
local Kit = require(script.Parent.EnvironmentKit)
local Props = require(script.Parent.EnvironmentProps)

local P, M, L = Kit.P, Enum.Material, Kit.Layer
local Districts = {}

-- The stadium sits between the z=66 and z=171 streets so it never blocks them.
Districts.ArenaZ = 118
Districts.ArenaRadius = 44

local function at(frame: CFrame, x: number, y: number, z: number): CFrame
	return frame * CFrame.new(x, y, z)
end

-- Billboard-style roof landmark: backing panel with decoration supplied by the caller.
local function roofBoard(kit: any, parent: Instance, frame: CFrame, height: number, z: number, width: number, tall: number, backing: Color3): CFrame
	local base = at(frame, 0, height + 2.5 + tall / 2, z)
	kit:block(parent, "RoofBoard", Vector3.new(width, tall, 0.6), base, backing, M.Metal, { cast = false })
	kit:block(parent, "RoofBoardFoot", Vector3.new(width * 0.7, 0.8, 1.6), at(frame, 0, height + 2.9, z), P.charcoal, M.Metal, { cast = false })
	return base * CFrame.new(0, 0, 0.6)
end

------------------------------------------------------------------------------------------
-- East side: Pet Parlor, Style Exchange, Luck Lounge. Fronts face the promenade (west).
------------------------------------------------------------------------------------------
local function petParlor(kit: any, folder: Instance)
	local F = CFrame.new(83, 0, -70) * CFrame.Angles(0, -math.pi / 2, 0)
	local W, D, H = 45, 47, 16
	local model = Props.building(kit, folder, {
		name = "PetParlor", frame = F, width = W, depth = D, height = H,
		wall = { color = P.blush, material = M.Concrete }, trim = P.white, accent = P.cyan, cap = P.pink,
		floor = { color = P.cream, material = M.WoodPlanks }, sideWindows = 2, backWindows = 2, awning = { P.pink, P.white },
	})
	Props.mountSign(kit, model, F, "PetShopFacade", "THE PET PARLOR\nGUARANTEED PETS · EARNED COINS", 0, H - 2.6, D / 2 + 0.45, 36, 4.6, P.cyan)

	-- Roof landmark: neon paw print.
	local face = roofBoard(kit, model, F, H, 0, 15, 11, P.deep)
	kit:ball(model, "PawPad", 5.2, face * CFrame.new(0, -2.0, 0.3), P.pink, M.Neon, { cast = false })
	for _, toe in { { -4.6, 1.8 }, { -1.7, 4.0 }, { 1.7, 4.0 }, { 4.6, 1.8 } } do
		kit:ball(model, "PawToe", 2.4, face * CFrame.new(toe[1], toe[2], 0.3), P.pink, M.Neon, { cast = false })
	end

	-- Interior: three pet showcases, adoption desk, product shelving.
	for index, tint in { P.pink, P.gold, P.cyan } do
		local x = -12 + (index - 1) * 12
		kit:cylinder(model, "PetShowcase", 8, 1.3, at(F, x, Props.FLOOR + 0.66, -6), P.white, M.Marble, { collide = true })
		kit:cylinder(model, "ShowcaseRing", 8.6, 0.25, at(F, x, Props.FLOOR + 0.2, -6), tint, M.Neon, { cast = false })
		local pet = kit:ball(model, "PetPreview", 3.5, at(F, x, Props.FLOOR + 4.1, -6), tint, M.SmoothPlastic, { cast = false })
		kit:tag(pet, 0.2, 0.25)
		for _, side in { -1, 1 } do
			kit:ball(model, "PetEar", 1.1, at(F, x + side * 1.1, Props.FLOOR + 6.0, -6), tint, M.SmoothPlastic, { cast = false })
		end
	end
	local desk = at(F, 0, 0, -17)
	Props.counter(kit, model, at(desk, 0, Props.FLOOR, 0), 16, P.pink, P.marble)
	local host = Props.counterSign(kit, model, desk, "PetAdoptionTerminal", "ADOPTION DESK\nGuaranteed pets · earned Coins", 0, 0, 14, 3.4, P.pink)
	kit:prompt(host, "Pets", "Guaranteed pet collection")
	for _, x in { -15, 15 } do
		Props.shelf(kit, model, at(F, x, Props.FLOOR, -21), 11, 9, { P.pink, P.cyan, P.gold, P.white })
	end
	for _, x in { -9.5, 9.5 } do
		Props.planter(kit, folder, at(F, x, 0, D / 2 + 3.2), 6, 3, { P.pink, P.white })
	end
end

local function styleExchange(kit: any, folder: Instance)
	local F = CFrame.new(83, 0, 12) * CFrame.Angles(0, -math.pi / 2, 0)
	local W, D, H = 44, 47, 17
	local model = Props.building(kit, folder, {
		name = "StyleExchange", frame = F, width = W, depth = D, height = H,
		wall = { color = P.charcoal, material = M.Concrete }, trim = P.white, accent = P.gold, cap = P.gold,
		floor = { color = P.charcoal, material = M.Marble }, plinth = P.slate, sideWindows = 1, backWindows = 2,
		glass = Color3.fromRGB(170, 160, 210),
	})
	Props.mountSign(kit, model, F, "StyleShopFacade", "THE STYLE EXCHANGE\nPREMIUM SHOWROOM · NOT FOR SALE", 0, H - 2.7, D / 2 + 0.45, 36, 4.8, P.gold)
	local face = roofBoard(kit, model, F, H, 0, 18, 9, P.deep)
	kit:block(model, "RoofCrest", Vector3.new(11, 11, 0.5), face * CFrame.new(0, 0, 0.35) * CFrame.Angles(0, 0, math.pi / 4), P.gold, M.Neon, { cast = false })
	kit:block(model, "RoofCrestCore", Vector3.new(6.6, 6.6, 0.55), face * CFrame.new(0, 0, 0.4) * CFrame.Angles(0, 0, math.pi / 4), P.deep, M.Metal, { cast = false })

	-- Interior: runway, three showcases, mirrors and clothing racks.
	kit:block(model, "RunwayCarpet", Vector3.new(8, 0.12, 34), at(F, 0, Props.FLOOR + 0.06, -2), P.purple, M.Fabric, { collide = true })
	for _, x in { -4.1, 4.1 } do
		kit:block(model, "RunwayTrim", Vector3.new(0.3, 0.16, 34), at(F, x, Props.FLOOR + 0.09, -2), P.gold, M.Neon, { cast = false })
	end
	for index, tint in { P.gold, P.purple, P.cyan } do
		local x = -13 + (index - 1) * 13
		local shelf = kit:block(model, "CosmeticShowcase", Vector3.new(9, 1.5, 7), at(F, x, Props.FLOOR + 0.76, -14), P.white, M.Marble, { collide = true })
		kit:block(model, "ShowcaseGlass", Vector3.new(8.4, 7, 6.4), at(F, x, Props.FLOOR + 4.86, -14), P.glass, M.Glass, { transparency = 0.75, cast = false })
		local gem = kit:block(model, "FutureCosmetic", Vector3.new(2.5, 2.5, 2.5), at(F, x, Props.FLOOR + 4.7, -14) * CFrame.Angles(0, 0, math.pi / 4), tint, M.Neon, { cast = false })
		kit:tag(gem, 0.3, 0.3)
		kit:prompt(shelf, "Shop", "VIP · Cosmetics · Boosts: unavailable")
	end
	Props.mountSign(kit, model, F, "PremiumNotice", "DISPLAY ONLY\nNo product IDs configured. Free progression stays complete.", 0, 7.2, -21.6, 30, 3.6, P.white)
	for _, side in { -1, 1 } do
		kit:block(model, "StyleMirror", Vector3.new(0.3, 8, 12), at(F, side * (W / 2 - 1.6), 5.2, 4), P.glass, M.Glass, { reflectance = 0.5, transparency = 0.2, cast = false })
		kit:block(model, "MirrorFrame", Vector3.new(0.5, 8.6, 12.6), at(F, side * (W / 2 - 1.5), 5.2, 4), P.gold, M.Metal, { cast = false })
		kit:cylinder(model, "RackPole", 0.3, 6.5, at(F, side * 15, Props.FLOOR + 3.25, 12), P.brass, M.Metal, { cast = false })
		kit:block(model, "RackBar", Vector3.new(0.3, 0.3, 9), at(F, side * 15, Props.FLOOR + 6.3, 12), P.brass, M.Metal, { cast = false })
		for i = 1, 5 do
			kit:block(model, "Garment", Vector3.new(0.5, 3, 1.1), at(F, side * 15, Props.FLOOR + 4.7, 8.6 + i * 1.4), if i % 2 == 0 then P.purple else P.pink, M.Fabric, { cast = false })
		end
	end
	for _, x in { -9.5, 9.5 } do
		Props.planter(kit, folder, at(F, x, 0, D / 2 + 3.2), 6, 3, { P.gold, P.white })
	end
end

local function luckLounge(kit: any, folder: Instance)
	local F = CFrame.new(83, 0, 96) * CFrame.Angles(0, -math.pi / 2, 0)
	local W, D, H = 44, 44, 15
	local model = Props.building(kit, folder, {
		name = "LuckLounge", frame = F, width = W, depth = D, height = H,
		wall = { color = Color3.fromRGB(34, 96, 78), material = M.Concrete }, trim = P.cream, accent = P.gold, cap = P.gold,
		floor = { color = Color3.fromRGB(28, 70, 60), material = M.Marble }, sideWindows = 2, backWindows = 1, awning = { P.green, P.gold },
	})
	Props.mountSign(kit, model, F, "LuckLoungeFacade", "THE LUCK LOUNGE\nLUCK TRAINING · EARNED COINS ONLY", 0, H - 2.6, D / 2 + 0.45, 36, 4.6, P.gold)
	local face = roofBoard(kit, model, F, H, 0, 13, 11, P.deep)
	for _, c in { { -2.6, 2.4 }, { 2.6, 2.4 }, { -2.6, -2.6 }, { 2.6, -2.6 } } do
		kit:ball(model, "CloverLeaf", 5, face * CFrame.new(c[1], c[2] + 1.2, 0.3), P.green, M.Neon, { cast = false })
	end
	kit:block(model, "CloverStem", Vector3.new(0.7, 4, 0.5), face * CFrame.new(1.2, -4.2, 0.3) * CFrame.Angles(0, 0, 0.35), P.green, M.Neon, { cast = false })

	-- Interior: a golden clover fountain, a counter with the real Luck-upgrade prompt.
	kit:cylinder(model, "CloverBasin", 12, 1.2, at(F, 0, Props.FLOOR + 0.6, -4), P.gold, M.Metal, { collide = true })
	kit:cylinder(model, "CloverWater", 10.4, 0.2, at(F, 0, Props.FLOOR + 1.25, -4), P.cyan, M.Glass, { transparency = 0.35, cast = false })
	for index, c in { { -1.6, 1.6 }, { 1.6, 1.6 }, { -1.6, -1.6 }, { 1.6, -1.6 } } do
		local leaf = kit:ball(model, "ClubLeaf", 3.2, at(F, c[1], Props.FLOOR + 3.9, -4 + c[2]), P.green, M.Neon, { cast = false })
		kit:tag(leaf, nil, 0.25, 1 + index * 0.1)
	end
	local desk = at(F, 0, 0, -17)
	Props.counter(kit, model, at(desk, 0, Props.FLOOR, 0), 18, P.woodDark, P.marble)
	local host = Props.counterSign(kit, model, desk, "LuckDesk", "LUCK DESK\nTrain Luck in Upgrades", 0, 0, 14, 3.4, P.gold)
	kit:prompt(host, "Upgrades", "Luck training and upgrades")
	for _, x in { -15, 15 } do
		Props.shelf(kit, model, at(F, x, Props.FLOOR, -20), 10, 9, { P.green, P.gold, P.white, P.cyan })
	end
end

------------------------------------------------------------------------------------------
-- West side: Glow-Up gym and Mogger Boutique. Fronts face the promenade (east).
------------------------------------------------------------------------------------------
local function benchPress(kit: any, parent: Instance, frame: CFrame, x: number, z: number)
	local f = at(frame, x, Props.FLOOR, z)
	kit:block(parent, "WorkoutMat", Vector3.new(8, 0.14, 12), at(f, 0, 0.07, 0), P.purple, M.Fabric, { cast = false })
	kit:block(parent, "BenchPad", Vector3.new(2.4, 1.0, 6.4), at(f, 0, 1.7, 0.4), P.charcoal, M.Leather, { collide = true })
	kit:block(parent, "BenchFrame", Vector3.new(1.0, 1.2, 5.6), at(f, 0, 0.8, 0.4), P.steel, M.Metal, { cast = false })
	for _, side in { -1, 1 } do
		kit:block(parent, "RackUpright", Vector3.new(0.6, 5.4, 0.6), at(f, side * 3, 2.7, -3), P.charcoal, M.Metal, { collide = true })
		kit:cylinder(parent, "BarbellPlate", 2.8, 0.7, at(f, side * 3.6, 4.6, -3), P.charcoal, M.Metal, { horizontal = true, cast = false })
		kit:cylinder(parent, "BarbellPlateRim", 3.0, 0.2, at(f, side * 4.1, 4.6, -3), P.red, M.Metal, { horizontal = true, cast = false })
	end
	kit:cylinder(parent, "Barbell", 0.3, 9, at(f, 0, 4.6, -3), P.gold, M.Metal, { horizontal = true, cast = false })
end

local function gym(kit: any, folder: Instance)
	local F = CFrame.new(-83, 0, -70) * CFrame.Angles(0, math.pi / 2, 0)
	local W, D, H = 45, 47, 16
	local model = Props.building(kit, folder, {
		name = "GlowUpGymClub", frame = F, width = W, depth = D, height = H,
		wall = { color = P.brick, material = M.Brick }, trim = P.stone, accent = P.teal, cap = P.steel,
		floor = { color = P.charcoal, material = M.Slate }, plinth = P.slate, sideWindows = 2, backWindows = 1,
		door = { w = 12, h = 10 }, windowWidth = 8,
	})
	Props.mountSign(kit, model, F, "GymFacade", "GLOW-UP ATHLETIC CLUB\nGAMEPLAY UPGRADES · NO ROBUX REQUIRED", 0, H - 2.6, D / 2 + 0.45, 38, 4.8, P.teal)
	-- Roof landmark: a giant neon dumbbell.
	local face = roofBoard(kit, model, F, H, 0, 15, 9, P.deep)
	kit:cylinder(model, "DumbbellBar", 1.2, 12, face * CFrame.new(0, 0, 0.5), P.steel, M.Metal, { horizontal = true, cast = false })
	for _, side in { -1, 1 } do
		kit:cylinder(model, "DumbbellPlate", 6.4, 1.4, face * CFrame.new(side * 5.2, 0, 0.5), P.teal, M.Neon, { horizontal = true, cast = false })
		kit:cylinder(model, "DumbbellPlateSmall", 4.4, 1.4, face * CFrame.new(side * 7.0, 0, 0.5), P.teal, M.Neon, { horizontal = true, cast = false })
	end

	for _, x in { -13, 0, 13 } do benchPress(kit, model, F, x, -12) end
	for _, x in { -14, 14 } do
		local f = at(F, x, Props.FLOOR, 8)
		kit:block(model, "TreadmillBase", Vector3.new(4.4, 0.8, 8.4), at(f, 0, 0.6, 0), P.charcoal, M.Metal, { collide = true })
		kit:block(model, "TreadmillBelt", Vector3.new(3.4, 0.15, 7), at(f, 0, 1.05, 0.2), P.slate, M.Fabric, { cast = false })
		kit:block(model, "TreadmillMast", Vector3.new(0.5, 4.2, 0.5), at(f, 0, 3.2, -3.4), P.steel, M.Metal, { cast = false })
		kit:block(model, "TreadmillConsole", Vector3.new(3.6, 0.6, 1.2), at(f, 0, 5.2, -3.3) * CFrame.Angles(-0.4, 0, 0), P.teal, M.Neon, { cast = false })
	end
	-- Dumbbell rack
	kit:block(model, "DumbbellRackFrame", Vector3.new(11, 3.4, 1.6), at(F, -14, Props.FLOOR + 1.7, -21.6), P.charcoal, M.Metal, { collide = true })
	for i = 1, 6 do
		kit:cylinder(model, "Dumbbell", 1.0, 1.6, at(F, -18 + i * 1.7, Props.FLOOR + 3.7, -21.6), if i % 2 == 0 then P.red else P.teal, M.Metal, { horizontal = true, cast = false })
	end
	-- Lockers
	for i = 1, 6 do
		local x = 6 + i * 2.6
		kit:block(model, "Locker", Vector3.new(2.4, 7, 2.2), at(F, x, Props.FLOOR + 3.5, -21.2), if i % 2 == 0 then P.teal else P.steel, M.Metal, { collide = true })
		kit:block(model, "LockerVent", Vector3.new(1.6, 0.3, 0.1), at(F, x, Props.FLOOR + 6.0, -20.05), P.charcoal, M.Metal, { cast = false })
	end
	-- Mirror wall and punching bag
	kit:block(model, "MirrorWall", Vector3.new(30, 8, 0.3), at(F, 0, 6, -22.3), P.glass, M.Glass, { reflectance = 0.45, transparency = 0.25, cast = false })
	kit:cylinder(model, "BagChain", 0.15, 3, at(F, 18, 11.5, -2), P.steel, M.Metal, { cast = false })
	kit:cylinder(model, "PunchingBag", 2.4, 6, at(F, 18, 7.6, -2), P.red, M.Leather, { cast = false })
	-- Real upgrade prompt: the training desk beside the coach.
	local deskFrame = at(F, 7, 0, 17)
	local desk = Props.counter(kit, model, at(deskFrame, 0, Props.FLOOR, 0), 12, P.steel, P.charcoal)
	desk:SetAttribute("Role", "TrainingDesk")
	local host = Props.counterSign(kit, model, deskFrame, "GameplayUpgradeTerminal", "TRAINING DESK\nExisting luck, pet and display upgrades", 0, 0, 11, 3.4, P.teal)
	kit:prompt(host, "Upgrades", "Gameplay upgrades")
	for _, x in { -10, 10 } do
		Props.planter(kit, folder, at(F, x, 0, D / 2 + 3.2), 6, 3, { P.orange, P.white })
	end
end

local function boutique(kit: any, folder: Instance)
	local F = CFrame.new(-83, 0, 5) * CFrame.Angles(0, math.pi / 2, 0)
	local W, D, H = 40, 40, 14
	local model = Props.building(kit, folder, {
		name = "MoggerBoutique", frame = F, width = W, depth = D, height = H,
		wall = { color = P.cream, material = M.Concrete }, trim = P.white, accent = P.pink, cap = P.brass,
		floor = { color = P.blush, material = M.Marble }, sideWindows = 1, backWindows = 1, awning = { P.charcoal, P.cream },
	})
	Props.mountSign(kit, model, F, "BoutiqueFacade", "MOGGER BOUTIQUE\nYOUR COLLECTION · DISPLAY STYLING", 0, H - 2.4, D / 2 + 0.45, 32, 4.4, P.pink)
	-- Dress forms on plinths.
	for index, tint in { P.pink, P.gold, P.cyan } do
		local x = -11 + (index - 1) * 11
		kit:cylinder(model, "FormPlinth", 5, 1.1, at(F, x, Props.FLOOR + 0.55, -8), P.white, M.Marble, { collide = true })
		kit:cylinder(model, "FormTorso", 2.6, 4.2, at(F, x, Props.FLOOR + 3.2, -8), tint, M.Fabric, { cast = false })
		kit:cylinder(model, "FormNeck", 0.8, 0.8, at(F, x, Props.FLOOR + 5.7, -8), P.stone, M.SmoothPlastic, { cast = false })
		kit:ball(model, "FormHead", 1.5, at(F, x, Props.FLOOR + 6.7, -8), P.stone, M.SmoothPlastic, { cast = false })
	end
	local desk = at(F, 0, 0, -15)
	Props.counter(kit, model, at(desk, 0, Props.FLOOR, 0), 14, P.woodDark, P.marble)
	local host = Props.counterSign(kit, model, desk, "CollectionDesk", "YOUR COLLECTION\nBrowse every Mogger you own", 0, 0, 12, 3.4, P.pink)
	kit:prompt(host, "Inventory", "Your collection")
	for _, x in { -14, 14 } do
		Props.shelf(kit, model, at(F, x, Props.FLOOR, -18), 9, 9, { P.pink, P.gold, P.white, P.charcoal })
	end
	for _, x in { -9, 9 } do
		Props.planter(kit, folder, at(F, x, 0, D / 2 + 3.2), 6, 3, { P.pink, P.gold })
	end
end

function Districts.shops(kit: any, folder: Instance)
	petParlor(kit, folder)
	styleExchange(kit, folder)
	luckLounge(kit, folder)
	-- Street furniture along the shop frontage (clear of the east-west streets).
	for _, z in { -90, -46, -8, 34, 76, 116 } do
		Props.lamp(kit, folder, Vector3.new(56.5, 0, z), P.gold)
	end
	for _, z in { -70, 12, 96 } do
		Props.bench(kit, folder, CFrame.new(56, 0, z) * CFrame.Angles(0, -math.pi / 2, 0))
	end
end

function Districts.westSide(kit: any, gymFolder: Instance, boutiqueFolder: Instance)
	gym(kit, gymFolder)
	boutique(kit, boutiqueFolder)
	for _, z in { -90, -46, -8, 24 } do
		Props.lamp(kit, gymFolder, Vector3.new(-56.5, 0, z), P.gold)
	end
	for _, z in { -70, 5 } do
		Props.bench(kit, gymFolder, CFrame.new(-56, 0, z) * CFrame.Angles(0, math.pi / 2, 0))
	end
end

------------------------------------------------------------------------------------------
-- Mog-Off stadium
------------------------------------------------------------------------------------------
-- Angular distance from north (-Z) in radians; a = atan2(dz, dx), north is a = -pi/2.
local function fromNorth(a: number): number
	return math.abs(((a + math.pi / 2 + math.pi) % (2 * math.pi)) - math.pi)
end

local function ring(kit: any, parent: Instance, name: string, center: Vector3, radius: number, count: number, y: number, height: number, thick: number, color: Color3, material: Enum.Material, opts: any?, gap: number?, alt: Color3?)
	local chord = 2 * radius * math.sin(math.pi / count) * 1.05
	for i = 0, count - 1 do
		local a = 2 * math.pi * i / count
		if gap and fromNorth(a) < gap then continue end
		local pos = Vector3.new(center.X + math.cos(a) * radius, y + height / 2, center.Z + math.sin(a) * radius)
		local frame = CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))
		kit:block(parent, name, Vector3.new(chord, height, thick), frame, if alt and i % 2 == 1 then alt else color, material, opts)
	end
end
Districts.ring = ring

function Districts.arena(kit: any, folder: Instance)
	local cz, R = Districts.ArenaZ, Districts.ArenaRadius
	local center = Vector3.new(0, 0, cz)
	-- Floor, stage, fighting surface
	kit:cylinder(folder, "ArenaFloor", R * 2, 0.5, Vector3.new(0, 0.25, cz), P.slate, M.Granite, { collide = true })
	kit:cylinder(folder, "CircularCombatStage", 52, 1.0, Vector3.new(0, 1.0, cz), P.charcoal, M.Marble, { collide = true })
	kit:cylinder(folder, "StageGoldRing", 54, 0.2, Vector3.new(0, 1.25, cz), P.gold, M.Neon)
	kit:cylinder(folder, "FightingFloor", 48, 0.4, Vector3.new(0, 1.5, cz), P.purple, M.Marble, { collide = true })
	kit:cylinder(folder, "CenterEmblemGold", 12, 0.1, Vector3.new(0, 1.76, cz), P.gold, M.Neon)
	kit:cylinder(folder, "CenterEmblem", 9, 0.12, Vector3.new(0, 1.84, cz), P.deep, M.Marble)
	for _, x in { -14, 14 } do
		kit:cylinder(folder, "CharacterSpawnMarker", 11, 0.12, Vector3.new(x, 1.76, cz), if x < 0 then P.cyan else P.pink, M.Neon)
	end
	local rampTilt = math.atan2(1.0, 7)
	kit:block(folder, "ArenaEntranceRamp", Vector3.new(14, 0.5, math.sqrt(49 + 1)), CFrame.new(0, 0.75, cz - 29.5) * CFrame.Angles(-rampTilt, 0, 0), P.marble, M.Marble, { collide = true })

	-- Seating bowl: three stepped tiers with an aisle on the entrance axis.
	local tiers = { { 31, 1.9, P.purple, P.indigo }, { 35, 3.6, P.indigo, P.purple }, { 39, 5.3, P.purple, P.indigo } }
	for _, tier in tiers do
		ring(kit, folder, "SpectatorTier", center, tier[1], 26, 0.5, tier[2], 4, tier[3], M.SmoothPlastic, { collide = true }, math.rad(11), tier[4])
		ring(kit, folder, "TierLip", center, tier[1] - 2.1, 26, 0.5 + tier[2] - 0.12, 0.12, 0.3, P.gold, M.Neon, { cast = false }, math.rad(11))
	end
	-- Outer wall, roof canopy and glowing band
	ring(kit, folder, "StadiumWall", center, R, 30, 0.5, 15, 2.4, P.cream, M.Concrete, { collide = true }, math.rad(13), P.stone)
	ring(kit, folder, "StadiumGlowBand", center, R + 1.3, 30, 11, 0.5, 0.25, P.cyan, M.Neon, { cast = false }, math.rad(13))
	local chord = 2 * (R - 4) * math.sin(math.pi / 30) * 1.05
	for i = 0, 29 do
		local a = 2 * math.pi * i / 30
		if fromNorth(a) >= math.rad(13) then
			local pos = Vector3.new(math.cos(a) * (R - 4.2), 16.4, cz + math.sin(a) * (R - 4.2))
			local frame = CFrame.lookAt(pos, Vector3.new(0, pos.Y, cz)) * CFrame.Angles(-math.rad(12), 0, 0)
			kit:block(folder, "RoofCanopy", Vector3.new(chord, 0.7, 9), frame, if i % 2 == 0 then P.indigo else P.purple, M.Metal, { cast = false })
		end
	end

	-- Grand gate on the north axis
	for _, x in { -17, 17 } do
		kit:block(folder, "EntranceColumn", Vector3.new(4.4, 22, 4.4), Vector3.new(x, 11.5, cz - R - 1), P.charcoal, M.Metal, { collide = true })
		kit:block(folder, "EntranceColumnCap", Vector3.new(5.6, 1, 5.6), Vector3.new(x, 23, cz - R - 1), P.gold, M.Metal, { cast = false })
		local bar = kit:block(folder, "EntranceLight", Vector3.new(0.5, 17, 0.5), Vector3.new(x, 11, cz - R - 3.4), P.cyan, M.Neon, { cast = false })
		kit:light(bar, P.cyan, 20)
	end
	kit:block(folder, "GateLintel", Vector3.new(40, 3.6, 5.4), Vector3.new(0, 20.6, cz - R - 1), P.charcoal, M.Metal, { collide = true })
	kit:block(folder, "GateLintelNeon", Vector3.new(40.4, 0.3, 5.7), Vector3.new(0, 18.7, cz - R - 1), P.gold, M.Neon, { cast = false })
	Props.mountSign(kit, folder, CFrame.new(0, 0, cz - R - 1) * CFrame.Angles(0, math.pi, 0), "ArenaEntrance", "MOG-OFF ARENA\nPVE CHALLENGES · KEEP YOUR MOGGERS", 0, 26, 3, 36, 5.6, P.gold)
	for _, x in { -34, 34 } do
		Props.banner(kit, folder, CFrame.new(x, 0, cz - R - 2) * CFrame.Angles(0, math.pi, 0), P.indigo, P.cyan)
	end
	-- Scoreboard on the south inner wall, facing the stage.
	local boardPos = Vector3.new(0, 11.5, cz + R - 2.0)
	kit:sign(folder, "ArenaScoreboard", "ARENA SCOREBOARD\nYour battle result and turn log appear in Battle\nServer wins: see the player list", Props.facing(boardPos, Vector3.new(0, 0, -1)), 38, 7.4, P.cyan)
	-- Floodlight towers outside the wall
	for index, angle in { 45, 135, 225, 315 } do
		local a = math.rad(angle)
		local pos = Vector3.new(math.cos(a) * (R + 7), 0, cz + math.sin(a) * (R + 7))
		kit:cylinder(folder, "FloodPole", 1.4, 28, pos + Vector3.new(0, 14, 0), P.steel, M.Metal, { collide = true })
		local head = kit:block(folder, "FloodHead", Vector3.new(8, 3.6, 1), CFrame.lookAt(pos + Vector3.new(0, 28.5, 0), Vector3.new(0, 20, cz)), P.white, M.Neon, { cast = false })
		if index > 2 then kit:light(head, P.white, 30, 1.0) end
	end
	-- Victory beacons flanking the approach
	for _, x in { -32, 32 } do
		kit:cylinder(folder, "BeaconPylon", 3, 9, Vector3.new(x, 4.5, 79), P.charcoal, M.Metal, { collide = true })
		kit:cylinder(folder, "BeaconRing", 4, 0.5, Vector3.new(x, 9.2, 79), P.gold, M.Neon)
		local beacon = kit:ball(folder, "VictoryBeacon", 3, Vector3.new(x, 12, 79), P.gold, M.Neon, { cast = false })
		kit:tag(beacon, 0.35, 0.3)
		kit:sparkles(beacon, P.gold)
	end
	-- Prompt terminal on the street in front of the gate
	local host = Props.kiosk(kit, folder, CFrame.new(22, 0.22, 69) * CFrame.Angles(0, math.pi, 0), "BattleTerminal", "ENTER A MOG-OFF\nChoose a PvE opponent", 14, 3.8, P.cyan)
	kit:prompt(host, "Battle", "PvE Mog-Offs")
end

------------------------------------------------------------------------------------------
-- Social gardens
------------------------------------------------------------------------------------------
function Districts.park(kit: any, folder: Instance)
	local cx, cz = -83, 60
	kit:slab(folder, "GardenWalkEW", 58, 6, cx, 57, L.passage, 0.3, P.cream, M.Cobblestone)
	kit:slab(folder, "GardenWalkNS", 6, 36, cx, 73, L.plaza, 0.3, P.cream, M.Cobblestone)
	-- Pond with stone rim, lily pads and a quiet central jet
	local pond = Vector3.new(cx, 0, 40)
	ring(kit, folder, "PondRim", pond, 11.2, 18, 0, 1.6, 1.6, P.stone, M.Slate, { collide = true }, nil, P.slate)
	kit:cylinder(folder, "PondBed", 21, 0.6, pond + Vector3.new(0, 0.3, 0), P.soil, M.Ground, { cast = false })
	kit:cylinder(folder, "GardenPond", 20.4, 0.2, pond + Vector3.new(0, 1.0, 0), P.cyan, M.Glass, { transparency = 0.3, cast = false })
	for _, pad in { { -4, -3 }, { 3, -5 }, { 5, 3 }, { -3, 5 } } do
		kit:cylinder(folder, "LilyPad", 2.4, 0.08, pond + Vector3.new(pad[1], 1.14, pad[2]), P.leaf2, M.Grass, { cast = false })
	end
	local jet = kit:cylinder(folder, "PondJet", 1.2, 2, pond + Vector3.new(0, 1.6, 0), P.stone, M.Slate, { cast = false })
	kit:spray(jet, nil, 9)
	for _, rock in { { 12.5, 2, 2.6 }, { -11.8, -5, 2.0 }, { 3, -12.6, 2.2 } } do
		kit:ball(folder, "PondRock", rock[3], pond + Vector3.new(rock[1], 0.4, rock[2]), P.slate, M.Slate, { cast = false })
	end
	-- Gazebo: gathering space with benches
	local gaz = Vector3.new(cx, 0, 80)
	kit:cylinder(folder, "GazeboFloor", 16, 0.6, gaz + Vector3.new(0, 0.3, 0), P.wood, M.WoodPlanks, { collide = true })
	for i = 0, 5 do
		local a = math.pi / 3 * i
		kit:cylinder(folder, "GazeboPost", 0.9, 9, gaz + Vector3.new(math.cos(a) * 6.6, 5.1, math.sin(a) * 6.6), P.white, M.Wood, { collide = true, cast = false })
	end
	kit:cylinder(folder, "GazeboRoofRing", 17.6, 0.8, gaz + Vector3.new(0, 9.9, 0), P.white, M.Wood, { cast = false })
	kit:cylinder(folder, "GazeboRoofMid", 12.4, 1.2, gaz + Vector3.new(0, 10.9, 0), P.teal, M.Metal, { cast = false })
	kit:cylinder(folder, "GazeboRoofTop", 6, 1.2, gaz + Vector3.new(0, 12.1, 0), P.teal, M.Metal, { cast = false })
	kit:cylinder(folder, "GazeboSpire", 0.5, 3, gaz + Vector3.new(0, 14.2, 0), P.gold, M.Metal, { cast = false })
	Props.bench(kit, folder, CFrame.new(gaz.X, 0.6, gaz.Z + 3.4) * CFrame.Angles(0, math.pi, 0))
	Props.bench(kit, folder, CFrame.new(gaz.X, 0.6, gaz.Z - 3.4))
	-- Picnic tables: social interaction points
	for _, spot in { Vector3.new(-100, 0, 76), Vector3.new(-66, 0, 76) } do
		kit:block(folder, "PicnicTable", Vector3.new(7, 0.35, 3.4), spot + Vector3.new(0, 2.6, 0), P.wood, M.WoodPlanks, { collide = true })
		for _, dz in { -2.6, 2.6 } do
			kit:block(folder, "PicnicBench", Vector3.new(7, 0.3, 1.2), spot + Vector3.new(0, 1.6, dz), P.wood, M.WoodPlanks, { collide = true, cast = false })
		end
		for _, dx in { -2.6, 2.6 } do
			kit:block(folder, "PicnicLeg", Vector3.new(0.4, 2.6, 6.8), spot + Vector3.new(dx, 1.3, 0), P.woodDark, M.Wood, { cast = false })
		end
	end
	-- Planting
	for _, spot in { { -106, 33, "round" }, { -60, 33, "round" }, { -106, 88, "round" }, { -60, 88, "round" }, { -108, 58, "blossom" }, { -58, 50, "blossom" }, { -97, 46, "blossom" }, { -69, 70, "round" } } do
		Props.tree(kit, folder, Vector3.new(spot[1], 0, spot[2]), 0.95, spot[3])
	end
	for _, bed in { { -95, 52 }, { -71, 52 }, { -95, 66 }, { -71, 66 } } do
		Props.planter(kit, folder, CFrame.new(bed[1], 0, bed[2]), 8, 3.2, { P.pink, P.gold, P.orange, P.cyan })
	end
	for _, b in { { -97, 54.4, math.pi }, { -69, 54.4, math.pi }, { -97, 59.6, 0 }, { -69, 59.6, 0 } } do
		Props.bench(kit, folder, CFrame.new(b[1], 0.3, b[2]) * CFrame.Angles(0, b[3], 0))
	end
	for _, lampPos in { { -110, 57 }, { -56, 57 }, { -110, 90 }, { -56, 90 } } do
		Props.lamp(kit, folder, Vector3.new(lampPos[1], 0, lampPos[2]), P.gold)
	end
	Props.kiosk(kit, folder, CFrame.new(cx, 0, 91.5) * CFrame.Angles(0, math.pi, 0), "SocialGardenSign", "SOCIAL GARDENS\nMeet friends between rolls", 22, 4.2, P.green)
	local goals = Props.kiosk(kit, folder, CFrame.new(-56.5, L.passage, 54) * CFrame.Angles(0, math.pi / 2, 0), "GardenGoals", "YOUR NEXT COLLECTION GOAL\nClaim verified gameplay rewards in Quests", 15, 3.8, P.gold)
	kit:prompt(goals, "Quests", "Collection goals")
end

return Districts
