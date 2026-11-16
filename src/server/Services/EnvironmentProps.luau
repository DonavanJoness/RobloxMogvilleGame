-- Composite architecture and street furniture. Local frames follow one convention:
--   +Y up, local +Z is the FRONT (the side people approach from), +X runs along the facade.
-- Frames passed in are at ground level, centered on the object footprint.
local Kit = require(script.Parent.EnvironmentKit)

local P = Kit.P
local M = Enum.Material
local Props = {}

-- Interior floor height shared by every building so props can sit exactly on it.
Props.FLOOR = 0.6

local function at(frame: CFrame, x: number, y: number, z: number): CFrame
	return frame * CFrame.new(x, y, z)
end

-- A CFrame at `position` whose LookVector points along `direction` (used for signs).
function Props.facing(position: Vector3, direction: Vector3): CFrame
	return CFrame.lookAt(position, position + direction)
end

------------------------------------------------------------------------------------------
-- Vegetation and street furniture
------------------------------------------------------------------------------------------
function Props.tree(kit: any, parent: Instance, position: Vector3, scale: number?, kind: string?)
	local s = scale or 1
	kit:cylinder(parent, "PlanterRing", 7.2 * s, 1.1 * s, position + Vector3.new(0, 0.55 * s, 0), P.stone, M.Slate, { collide = true })
	kit:cylinder(parent, "PlanterSoil", 6.2 * s, 0.2 * s, position + Vector3.new(0, 1.15 * s, 0), P.soil, M.Ground, { cast = false })
	kit:cylinder(parent, "TreeTrunk", 1.2 * s, 6.4 * s, position + Vector3.new(0, 4.1 * s, 0), P.woodDark, M.Wood, { cast = false })
	local tint, tint2 = P.leaf, P.leaf2
	if kind == "blossom" then tint, tint2 = P.pink, P.blush end
	local blobs = {
		{ 0, 9.4, 0, 6.4, tint }, { -2.2, 8.2, 0.6, 4.6, tint2 }, { 2.3, 8.4, -0.5, 4.8, tint2 },
		{ 0.4, 11.4, 0.2, 4.4, tint2 }, { 0.2, 7.9, 2.3, 4.0, tint },
	}
	for _, b in blobs do
		kit:ball(parent, "Canopy", b[4] * s, position + Vector3.new(b[1] * s, b[2] * s, b[3] * s), b[5], M.Grass, { cast = false })
	end
end

function Props.lamp(kit: any, parent: Instance, position: Vector3, tint: Color3?)
	local glow = tint or P.gold
	kit:cylinder(parent, "LampBase", 1.8, 0.9, position + Vector3.new(0, 0.45, 0), P.charcoal, M.Metal, { collide = true })
	kit:cylinder(parent, "LampPole", 0.5, 8.4, position + Vector3.new(0, 5.1, 0), P.charcoal, M.Metal, { cast = false })
	kit:cylinder(parent, "LampCollar", 1.1, 0.4, position + Vector3.new(0, 8.4, 0), P.brass, M.Metal, { cast = false })
	local globe = kit:ball(parent, "LampGlobe", 1.9, position + Vector3.new(0, 9.5, 0), glow, M.Neon, { cast = false })
	kit:cylinder(parent, "LampCap", 1.5, 0.35, position + Vector3.new(0, 10.6, 0), P.charcoal, M.Metal, { cast = false })
	kit:light(globe, glow, 18)
end

function Props.bench(kit: any, parent: Instance, frame: CFrame)
	for i = 0, 2 do
		kit:block(parent, "BenchSlat", Vector3.new(7.4, 0.28, 0.72), at(frame, 0, 1.75, -0.8 + i * 0.82), P.wood, M.WoodPlanks, { collide = true, cast = false })
	end
	for i = 0, 1 do
		kit:block(parent, "BenchBack", Vector3.new(7.4, 0.5, 0.2), at(frame, 0, 2.7 + i * 0.7, 1.45) * CFrame.Angles(-0.12, 0, 0), P.wood, M.WoodPlanks, { cast = false })
	end
	for _, x in { -3.4, 3.4 } do
		kit:block(parent, "BenchLeg", Vector3.new(0.4, 1.7, 2.8), at(frame, x, 0.85, 0.3), P.charcoal, M.Metal, { cast = false })
		kit:block(parent, "BenchArm", Vector3.new(0.4, 0.3, 2.6), at(frame, x, 2.5, 0.2), P.brass, M.Metal, { cast = false })
	end
end

-- Stone planter with shrubs and a few flowers. `blooms` is a list of colors.
function Props.planter(kit: any, parent: Instance, frame: CFrame, width: number, depth: number, blooms: { Color3 }?)
	kit:block(parent, "PlanterBox", Vector3.new(width, 1.6, depth), at(frame, 0, 0.8, 0), P.stone, M.Slate, { collide = true })
	kit:block(parent, "PlanterCap", Vector3.new(width + 0.5, 0.25, depth + 0.5), at(frame, 0, 1.7, 0), P.marble, M.Marble, { cast = false })
	kit:block(parent, "PlanterSoil", Vector3.new(width - 0.6, 0.2, depth - 0.6), at(frame, 0, 1.82, 0), P.soil, M.Ground, { cast = false })
	local count = math.max(2, math.floor(width / 3.2))
	for i = 1, count do
		local x = -width / 2 + (i - 0.5) * (width / count)
		kit:ball(parent, "Shrub", math.min(depth, 3.0), at(frame, x, 2.4, 0), if i % 2 == 0 then P.leaf else P.leaf2, M.Grass, { cast = false })
		local bloom = if blooms and #blooms > 0 then blooms[(i - 1) % #blooms + 1] else P.pink
		kit:ball(parent, "Flower", 0.8, at(frame, x + 0.4, 3.4, 0.3), bloom, M.Neon, { cast = false })
	end
end

function Props.bollard(kit: any, parent: Instance, position: Vector3, tint: Color3?)
	kit:cylinder(parent, "Bollard", 0.9, 2.6, position + Vector3.new(0, 1.3, 0), P.charcoal, M.Metal, { collide = true, cast = false })
	kit:cylinder(parent, "BollardBand", 0.98, 0.18, position + Vector3.new(0, 2.2, 0), tint or P.gold, M.Neon, { cast = false })
end

-- Clipped hedge wall along local X with a rounded top.
function Props.hedge(kit: any, parent: Instance, frame: CFrame, length: number, height: number?, depth: number?)
	local h, d = height or 2.6, depth or 2.4
	kit:block(parent, "Hedge", Vector3.new(length, h, d), at(frame, 0, h / 2, 0), P.leaf, M.Grass, { collide = true })
	kit:cylinder(parent, "HedgeTop", d, length, at(frame, 0, h, 0), P.leaf2, M.Grass, { horizontal = true, cast = false })
end

function Props.banner(kit: any, parent: Instance, frame: CFrame, color: Color3, accent: Color3?)
	kit:cylinder(parent, "BannerPole", 0.4, 12, at(frame, 0, 6, 0), P.charcoal, M.Metal, { collide = true, cast = false })
	kit:block(parent, "BannerArm", Vector3.new(3.4, 0.3, 0.3), at(frame, 1.7, 11.6, 0), P.brass, M.Metal, { cast = false })
	kit:block(parent, "BannerCloth", Vector3.new(2.6, 7, 0.16), at(frame, 1.9, 7.9, 0.05), color, M.Fabric, { cast = false })
	kit:block(parent, "BannerHem", Vector3.new(2.6, 0.4, 0.2), at(frame, 1.9, 4.5, 0.05), accent or P.gold, M.Neon, { cast = false })
	kit:block(parent, "BannerEmblem", Vector3.new(1.2, 1.2, 0.22), at(frame, 1.9, 8.6, 0.05) * CFrame.Angles(0, 0, math.pi / 4), accent or P.gold, M.Neon, { cast = false })
end

------------------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------------------
-- Round column: plinth, fluted-look shaft (two stacked cylinders), gold ring, capital + abacus.
function Props.column(kit: any, parent: Instance, frame: CFrame, height: number, diameter: number, tint: Color3?, trim: Color3?)
	local t, g = tint or P.marble, trim or P.gold
	kit:block(parent, "ColumnPlinth", Vector3.new(diameter * 1.7, 0.9, diameter * 1.7), at(frame, 0, 0.45, 0), P.stone, M.Granite, { collide = true })
	kit:cylinder(parent, "ColumnShaft", diameter, height - 2.6, at(frame, 0, 0.9 + (height - 2.6) / 2, 0), t, M.Marble, { collide = true })
	kit:cylinder(parent, "ColumnRing", diameter * 1.18, 0.35, at(frame, 0, 1.6, 0), g, M.Metal, { cast = false })
	kit:cylinder(parent, "ColumnCapital", diameter * 1.45, 0.8, at(frame, 0, height - 1.3, 0), t, M.Marble, { cast = false })
	kit:block(parent, "ColumnAbacus", Vector3.new(diameter * 1.9, 0.5, diameter * 1.9), at(frame, 0, height - 0.65, 0), g, M.Metal, { cast = false })
end

-- Solid stair block rising toward local -Z (into the building). Frame = bottom of the front edge.
function Props.stairs(kit: any, parent: Instance, frame: CFrame, width: number, steps: number, rise: number, run: number, tint: Color3?, material: Enum.Material?)
	for i = 1, steps do
		kit:block(parent, "Step", Vector3.new(width, i * rise, run), at(frame, 0, i * rise / 2, -(i - 0.5) * run), tint or P.marble, material or M.Marble, { collide = true })
	end
end

-- Tilted striped awning projecting from a wall. Frame = wall face at the awning's top edge.
function Props.awning(kit: any, parent: Instance, frame: CFrame, width: number, projection: number, colorA: Color3, colorB: Color3)
	local stripes = math.max(3, math.floor(width / 2.4))
	local sw = width / stripes
	local tilt = math.rad(24)
	for i = 1, stripes do
		local x = -width / 2 + (i - 0.5) * sw
		kit:block(parent, "AwningStripe", Vector3.new(sw, 0.25, projection), frame * CFrame.new(x, 0, projection / 2) * CFrame.Angles(tilt, 0, 0), if i % 2 == 0 then colorA else colorB, M.Fabric, { cast = false })
	end
	kit:block(parent, "AwningValance", Vector3.new(width, 0.7, 0.2), frame * CFrame.new(0, -projection * math.sin(tilt) - 0.3, projection * math.cos(tilt)), colorA, M.Fabric, { cast = false })
end

-- Wall along local X with real openings. openings: { { x, w, y0, y1, glass, trim } }
-- Walls and glass collide so nobody walks through a window; doorways are plain gaps.
function Props.wall(kit: any, parent: Instance, name: string, frame: CFrame, length: number, height: number, thickness: number, openings: { any }, color: Color3, material: Enum.Material, glassTint: Color3?)
	table.sort(openings, function(a, b) return a.x < b.x end)
	local function strip(x0: number, x1: number, y0: number, y1: number, label: string)
		if x1 - x0 < 0.05 or y1 - y0 < 0.05 then return end
		kit:block(parent, name .. label, Vector3.new(x1 - x0, y1 - y0, thickness), at(frame, (x0 + x1) / 2, (y0 + y1) / 2, 0), color, material, { collide = true })
	end
	local cursor = -length / 2
	for _, o in openings do
		local x0, x1 = o.x - o.w / 2, o.x + o.w / 2
		strip(cursor, x0, 0, height, "Pier")
		strip(x0, x1, 0, o.y0, "Sill")
		strip(x0, x1, o.y1, height, "Header")
		if o.glass then
			kit:block(parent, name .. "Glass", Vector3.new(o.w, o.y1 - o.y0, 0.22), at(frame, o.x, (o.y0 + o.y1) / 2, 0), glassTint or P.glass, M.Glass,
				{ collide = true, transparency = 0.5, reflectance = 0.12, cast = false })
			if o.w > 6 then
				kit:block(parent, name .. "Mullion", Vector3.new(0.3, o.y1 - o.y0, 0.4), at(frame, o.x, (o.y0 + o.y1) / 2, 0.05), o.trim or P.charcoal, M.Metal, { cast = false })
			end
		end
		if o.trim then
			-- Projecting sill ledge and lintel cap make each opening read as a framed window/door.
			if o.y0 > 0 then
				kit:block(parent, name .. "SillLedge", Vector3.new(o.w + 1.0, 0.35, thickness + 0.8), at(frame, o.x, o.y0 - 0.05, 0.4), o.trim, M.Marble, { cast = false })
			end
			kit:block(parent, name .. "Lintel", Vector3.new(o.w + 1.0, 0.5, thickness + 0.8), at(frame, o.x, o.y1 + 0.2, 0.4), o.trim, M.Marble, { cast = false })
		end
		cursor = x1
	end
	strip(cursor, length / 2, 0, height, "Pier")
end

-- Evenly spaced windows either side of a central doorway.
function Props.storefrontOpenings(width: number, height: number, doorWidth: number, doorHeight: number, windowWidth: number, trim: Color3?): { any }
	local list = { { x = 0, w = doorWidth, y0 = 0, y1 = doorHeight, glass = false, trim = trim } }
	local pitch = windowWidth + 3.2
	local start = doorWidth / 2 + 3.2 + windowWidth / 2
	local x = start
	while x + windowWidth / 2 <= width / 2 - 2.6 do
		for _, sign in { -1, 1 } do
			table.insert(list, { x = sign * x, w = windowWidth, y0 = 3.2, y1 = math.min(height - 5, doorHeight + 0.5), glass = true, trim = trim })
		end
		x += pitch
	end
	return list
end

-- A full building shell. spec fields:
--   name, frame (ground center, front = +Z), width, depth, height,
--   wall = {color, material}, trim (Color3), accent (neon Color3), floor = {color, material},
--   door = {w, h}, windowWidth, sideWindows (count per side), roof = "flat"|"dome",
--   awning = {a, b} or nil, plinth (Color3)
-- Returns the Model.
function Props.building(kit: any, parent: Instance, spec: any): Model
	local model = kit:model(parent, spec.name)
	model:SetAttribute("Architecture", "ProceduralShell")
	local w, d, h = spec.width, spec.depth, spec.height
	local frame: CFrame = spec.frame
	local wall = spec.wall or { color = P.cream, material = M.Concrete }
	local trim = spec.trim or P.marble
	local accent = spec.accent or P.cyan
	local floor = spec.floor or { color = P.marble, material = M.Marble }
	local t = 1.2
	local door = spec.door or { w = 11, h = 9.5 }

	-- One floor slab spans the whole footprint (walls stand on it); the plinth is a thin rim.
	kit:block(model, "InteriorFloor", Vector3.new(w, Props.FLOOR, d), at(frame, 0, Props.FLOOR / 2, 0), floor.color, floor.material, { collide = true })
	local rim = spec.plinth or P.stone
	for _, strip in { { w + 1.6, 0.8, 0, d / 2 + 0.4 }, { w + 1.6, 0.8, 0, -d / 2 - 0.4 } } do
		kit:block(model, "PlinthRim", Vector3.new(strip[1], Props.FLOOR, strip[2]), at(frame, strip[3], Props.FLOOR / 2, strip[4]), rim, M.Granite, { collide = true })
	end
	for _, sx in { -1, 1 } do
		kit:block(model, "PlinthRim", Vector3.new(0.8, Props.FLOOR, d), at(frame, sx * (w / 2 + 0.4), Props.FLOOR / 2, 0), rim, M.Granite, { collide = true })
	end

	-- Four walls
	local frontOpenings = spec.frontOpenings or Props.storefrontOpenings(w, h, door.w, door.h, spec.windowWidth or 7, trim)
	Props.wall(kit, model, "Front", at(frame, 0, Props.FLOOR, d / 2 - t / 2), w, h - Props.FLOOR, t, frontOpenings, wall.color, wall.material, spec.glass)
	local back = {}
	for i = 1, (spec.backWindows or 0) do
		table.insert(back, { x = -w / 2 + i * w / ((spec.backWindows or 0) + 1), w = 6, y0 = 4, y1 = h - 4, glass = true, trim = trim })
	end
	Props.wall(kit, model, "Back", at(frame, 0, Props.FLOOR, -d / 2 + t / 2) * CFrame.Angles(0, math.pi, 0), w, h - Props.FLOOR, t, back, wall.color, wall.material, spec.glass)
	for _, side in { -1, 1 } do
		local openings = {}
		local n = spec.sideWindows or 0
		for i = 1, n do
			table.insert(openings, { x = -d / 2 + i * d / (n + 1), w = 6, y0 = 4, y1 = h - 4, glass = true, trim = trim })
		end
		Props.wall(kit, model, "Side", at(frame, side * (w / 2 - t / 2), Props.FLOOR, 0) * CFrame.Angles(0, side * math.pi / 2, 0), d, h - Props.FLOOR, t, openings, wall.color, wall.material, spec.glass)
	end

	-- Corner pilasters, cornice, roof slab, parapet
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			kit:block(model, "Pilaster", Vector3.new(2.6, h, 2.6), at(frame, sx * (w / 2 - 0.4), h / 2 + 0.3, sz * (d / 2 - 0.4)), trim, M.Marble, { collide = true })
			kit:block(model, "PilasterCap", Vector3.new(3.2, 0.5, 3.2), at(frame, sx * (w / 2 - 0.4), h + 0.55, sz * (d / 2 - 0.4)), spec.cap or P.gold, M.Metal, { cast = false })
		end
	end
	kit:block(model, "Cornice", Vector3.new(w + 2.4, 0.8, d + 2.4), at(frame, 0, h + 0.2, 0), trim, M.Marble, { collide = true })
	kit:block(model, "CorniceNeon", Vector3.new(w + 2.6, 0.22, d + 2.6), at(frame, 0, h - 0.35, 0), accent, M.Neon, { cast = false })
	kit:block(model, "Roof", Vector3.new(w, 0.8, d), at(frame, 0, h + 0.7, 0), P.slate, M.Concrete, { collide = true })
	local px = {
		{ 0, d / 2 - 0.4, w, 0.8 }, { 0, -d / 2 + 0.4, w, 0.8 },
	}
	for _, p in px do
		kit:block(model, "Parapet", Vector3.new(p[3], 1.4, p[4]), at(frame, p[1], h + 1.8, p[2]), trim, M.Marble, { collide = true, cast = false })
	end
	for _, sx in { -1, 1 } do
		kit:block(model, "Parapet", Vector3.new(0.8, 1.4, d - 1.6), at(frame, sx * (w / 2 - 0.4), h + 1.8, 0), trim, M.Marble, { collide = true, cast = false })
	end
	if spec.roof == "dome" then
		local radius = spec.domeRadius or math.min(w, d) * 0.3
		kit:cylinder(model, "DomeDrum", radius * 2.1, 2.4, at(frame, 0, h + 2.1, 0), trim, M.Marble, { collide = true })
		kit:ball(model, "Dome", radius * 2, at(frame, 0, h + 3.2, 0), spec.domeColor or P.gold, M.Metal, { cast = false, reflectance = 0.15 })
		kit:cylinder(model, "DomeSpire", 0.5, 4.5, at(frame, 0, h + 3.2 + radius + 1.8, 0), P.gold, M.Metal, { cast = false })
		local star = kit:ball(model, "DomeStar", 1.6, at(frame, 0, h + 3.2 + radius + 4.3, 0), accent, M.Neon, { cast = false })
		kit:tag(star, 0.6, 0.35)
	end

	if spec.awning then
		local range = spec.awning
		for _, o in frontOpenings do
			if o.glass then
				Props.awning(kit, model, at(frame, o.x, o.y1 + 1.2, d / 2 + 0.2), o.w + 0.6, 3.4, range[1], range[2])
			end
		end
	end
	return model
end

------------------------------------------------------------------------------------------
-- Statues
------------------------------------------------------------------------------------------
-- Triumphant stylized hero (original design, not a real person). Frame = top of the plinth.
function Props.hero(kit: any, parent: Instance, frame: CFrame, scale: number, tint: Color3, glow: Color3): Model
	local model = kit:model(parent, "HeroStatue")
	local s = scale
	local function b(name: string, size: Vector3, x: number, y: number, z: number, color: Color3?, material: Enum.Material?)
		return kit:block(model, name, size * s, at(frame, x * s, y * s, z * s), color or tint, material or M.Metal, { cast = false, reflectance = 0.12 })
	end
	for _, side in { -1, 1 } do
		b("Boot", Vector3.new(2.1, 0.9, 2.8), side * 1.2, 0.45, -0.3, P.brass)
		b("Leg", Vector3.new(1.9, 4.6, 2.0), side * 1.2, 3.2, 0, tint)
		b("Shoulder", Vector3.new(2.4, 2.4, 2.4), side * 3.4, 9.7, 0, P.brass)
		local arm = at(frame, side * 3.5 * s, 9.9 * s, 0) * CFrame.Angles(0, 0, -side * math.rad(38))
		kit:block(model, "Arm", Vector3.new(1.7, 4.6, 1.8) * s, arm * CFrame.new(0, 2.3 * s, 0), tint, M.Metal, { cast = false, reflectance = 0.12 })
		kit:ball(model, "Fist", 2.0 * s, arm * CFrame.new(0, 5.0 * s, 0), P.brass, M.Metal, { cast = false })
	end
	b("Belt", Vector3.new(4.8, 0.9, 2.5), 0, 5.8, 0, P.brass)
	b("Waist", Vector3.new(4.2, 2.0, 2.4), 0, 6.9, 0)
	b("Chest", Vector3.new(6.0, 3.4, 3.0), 0, 9.1, 0)
	b("ChestEmblem", Vector3.new(1.5, 1.5, 0.3), 0, 9.3, -1.6, glow, M.Neon)
	b("Neck", Vector3.new(1.4, 1.0, 1.4), 0, 11.1, 0)
	local head = kit:ball(model, "Head", 3.4 * s, at(frame, 0, 12.9 * s, 0), tint, M.Metal, { cast = false, reflectance = 0.12 })
	b("Hair", Vector3.new(3.2, 1.3, 3.2), 0, 14.5, 0.1, P.brass)
	local crown = kit:ball(model, "CrownStar", 2.2 * s, at(frame, 0, 18.4 * s, 0), glow, M.Neon, { cast = false })
	kit:tag(crown, 0.5, 0.4)
	kit:sparkles(crown, glow)
	model.PrimaryPart = head
	return model
end

-- Mount a sign using a building-local position. opts.dir = local facing (default +Z, the front).
function Props.mountSign(kit: any, parent: Instance, frame: CFrame, name: string, text: string, x: number, y: number, z: number, width: number, height: number, tint: Color3, opts: any?): Part
	local dir = (opts and opts.dir) or Vector3.new(0, 0, 1)
	local position = frame * Vector3.new(x, y, z)
	return kit:sign(parent, name, text, Props.facing(position, frame:VectorToWorldSpace(dir)), width, height, tint, opts)
end

-- Sales/reception counter. Returns the counter top so callers can mount signs and prompts.
function Props.counter(kit: any, parent: Instance, frame: CFrame, width: number, body: Color3, top: Color3): Part
	kit:block(parent, "CounterBody", Vector3.new(width, 3.4, 3), at(frame, 0, 1.7, 0), body, M.Wood, { collide = true })
	kit:block(parent, "CounterKick", Vector3.new(width + 0.2, 0.4, 3.2), at(frame, 0, 0.2, 0), P.charcoal, M.Metal, { cast = false })
	return kit:block(parent, "CounterTop", Vector3.new(width + 0.8, 0.35, 3.8), at(frame, 0, 3.55, 0), top, M.Marble, { collide = true })
end

-- Vertical shelving unit with evenly spaced colored boxes (storefront dressing).
function Props.shelf(kit: any, parent: Instance, frame: CFrame, width: number, height: number, colors: { Color3 })
	kit:block(parent, "ShelfBack", Vector3.new(width, height, 0.4), at(frame, 0, height / 2, -0.9), P.woodDark, M.Wood, { collide = true })
	for level = 1, 3 do
		local y = level * height / 3.4
		kit:block(parent, "ShelfBoard", Vector3.new(width, 0.3, 2.2), at(frame, 0, y, 0), P.wood, M.WoodPlanks, { cast = false })
		for i = 1, 4 do
			kit:block(parent, "ShelfItem", Vector3.new(1.6, 1.3, 1.3), at(frame, -width / 2 + (i - 0.5) * width / 4, y + 0.8, 0), colors[(level + i) % #colors + 1], M.SmoothPlastic, { cast = false })
		end
	end
end

-- Free-standing information/prompt kiosk: two posts carrying a sign. Frame = ground, front +Z.
function Props.kiosk(kit: any, parent: Instance, frame: CFrame, name: string, text: string, width: number, height: number, tint: Color3, opts: any?): Part
	local top = 3.0 + height
	for _, side in { -1, 1 } do
		kit:cylinder(parent, name .. "Post", 0.6, top, at(frame, side * (width / 2 - 0.6), top / 2, -0.5), P.charcoal, M.Metal, { collide = true, cast = false })
		kit:cylinder(parent, name .. "Foot", 1.5, 0.5, at(frame, side * (width / 2 - 0.6), 0.25, -0.5), P.brass, M.Metal, { cast = false })
	end
	return Props.mountSign(kit, parent, frame, name, text, 0, 3.0 + height / 2, 0, width, height, tint, opts)
end

-- Sign that stands on a counter top (two brass feet), so it never floats. Returns the sign panel.
function Props.counterSign(kit: any, parent: Instance, frame: CFrame, name: string, text: string, x: number, z: number, width: number, height: number, tint: Color3, opts: any?): Part
	local base = Props.FLOOR + 3.73
	for _, side in { -1, 1 } do
		kit:block(parent, name .. "Foot", Vector3.new(0.5, 0.6, 0.8), at(frame, x + side * (width / 2 - 1), base + 0.3, z - 0.1), P.brass, M.Metal, { cast = false })
	end
	return Props.mountSign(kit, parent, frame, name, text, x, base + 0.6 + height / 2, z, width, height, tint, opts)
end

return Props
