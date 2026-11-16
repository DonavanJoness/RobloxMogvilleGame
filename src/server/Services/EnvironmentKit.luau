-- Budgeted construction primitives shared by every district builder.
-- Everything here is anchored static scenery: decoration never collides or is raycast-able
-- unless a caller explicitly asks, which keeps physics and query cost low on mobile.
local CollectionService = game:GetService("CollectionService")

local Kit = {}
Kit.__index = Kit

-- One palette for the whole city so districts read as one intentional design.
Kit.P = {
	cream = Color3.fromRGB(238, 231, 216), stone = Color3.fromRGB(206, 200, 190), marble = Color3.fromRGB(240, 238, 246),
	slate = Color3.fromRGB(104, 108, 126), charcoal = Color3.fromRGB(44, 46, 58), steel = Color3.fromRGB(92, 98, 116),
	indigo = Color3.fromRGB(54, 40, 100), deep = Color3.fromRGB(32, 26, 62), purple = Color3.fromRGB(116, 65, 205),
	violet = Color3.fromRGB(160, 120, 235), gold = Color3.fromRGB(255, 204, 87), brass = Color3.fromRGB(214, 164, 64),
	cyan = Color3.fromRGB(84, 224, 237), teal = Color3.fromRGB(46, 172, 176), pink = Color3.fromRGB(246, 129, 201),
	blush = Color3.fromRGB(250, 205, 224), red = Color3.fromRGB(226, 78, 92), orange = Color3.fromRGB(255, 150, 72),
	green = Color3.fromRGB(91, 180, 120), leaf = Color3.fromRGB(70, 148, 96), leaf2 = Color3.fromRGB(104, 178, 110),
	grass = Color3.fromRGB(112, 172, 106), wood = Color3.fromRGB(156, 110, 72), woodDark = Color3.fromRGB(100, 68, 46),
	brick = Color3.fromRGB(178, 94, 74), brickDark = Color3.fromRGB(132, 66, 54), glass = Color3.fromRGB(150, 208, 238),
	white = Color3.fromRGB(246, 245, 250), soil = Color3.fromRGB(88, 64, 48),
}

-- Static layer heights: crossing paths sit at different heights so no two slabs share a
-- coplanar top face (that z-fights and shows mismatched material textures).
Kit.Layer = { ground = 0, promenade = 0.10, inlay = 0.16, cross = 0.22, collector = 0.28, passage = 0.34, plaza = 0.40, plazaTrim = 0.46, plazaInlay = 0.52 }

function Kit.new(root: Instance, limits: any)
	return setmetatable({
		root = root, limits = limits,
		metrics = { parts = 0, lights = 0, emitters = 0, signs = 0 },
	}, Kit)
end

function Kit:folder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function Kit:model(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

-- opts: collide, query, cast, transparency, reflectance, shape
function Kit:block(parent: Instance, name: string, size: Vector3, where: any, color: Color3, material: Enum.Material?, opts: any?): Part
	assert(self.metrics.parts < self.limits.parts, "Mogville static geometry exceeded World.MaxStaticParts")
	self.metrics.parts += 1
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = if typeof(where) == "CFrame" then where else CFrame.new(where)
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.Anchored = true
	local solid = opts ~= nil and opts.collide == true
	item.CanCollide = solid
	item.CanTouch = false
	item.CanQuery = solid or (opts ~= nil and opts.query == true)
	item.CastShadow = if opts ~= nil and opts.cast ~= nil then opts.cast else true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	if opts ~= nil then
		if opts.transparency then item.Transparency = opts.transparency end
		if opts.reflectance then item.Reflectance = opts.reflectance end
		if opts.shape then item.Shape = opts.shape end
	end
	item.Parent = parent
	return item
end

-- Vertical cylinder by default (Roblox cylinders run along local X, so rotate onto Y).
function Kit:cylinder(parent: Instance, name: string, diameter: number, height: number, where: any, color: Color3, material: Enum.Material?, opts: any?): Part
	local frame = if typeof(where) == "CFrame" then where else CFrame.new(where)
	local horizontal = opts ~= nil and opts.horizontal == true
	local item = self:block(parent, name, Vector3.new(height, diameter, diameter),
		if horizontal then frame else frame * CFrame.Angles(0, 0, math.pi / 2), color, material, opts)
	item.Shape = Enum.PartType.Cylinder
	return item
end

function Kit:ball(parent: Instance, name: string, diameter: number, where: any, color: Color3, material: Enum.Material?, opts: any?): Part
	local item = self:block(parent, name, Vector3.new(diameter, diameter, diameter), where, color, material, opts)
	item.Shape = Enum.PartType.Ball
	return item
end

-- Slab whose TOP face sits exactly at topY (callers pass layer heights, never raw centers).
function Kit:slab(parent: Instance, name: string, width: number, depth: number, centerX: number, centerZ: number, topY: number, thickness: number, color: Color3, material: Enum.Material?, opts: any?): Part
	return self:block(parent, name, Vector3.new(width, thickness, depth), Vector3.new(centerX, topY - thickness / 2, centerZ), color, material, opts or { collide = true })
end

function Kit:tag(item: Instance, spin: number?, bob: number?, speed: number?)
	if spin then
		item:SetAttribute("SpinSpeed", spin)
		CollectionService:AddTag(item, "MogvilleSpin")
	end
	if bob then
		item:SetAttribute("BobAmplitude", bob)
		item:SetAttribute("BobSpeed", speed or 1.2)
		CollectionService:AddTag(item, "MogvilleBob")
	end
end

-- Real signage: text is painted on the sign face (SurfaceGui), not a floating HUD billboard.
-- `where` must be a CFrame whose LookVector points at the people who should read the sign.
function Kit:sign(parent: Instance, name: string, text: string, where: CFrame, width: number, height: number, tint: Color3, opts: any?): Part
	local P = Kit.P
	local backing = if opts and opts.backing then opts.backing else P.deep
	local panel = self:block(parent, name, Vector3.new(width, height, 0.5), where, backing, Enum.Material.Metal, { query = true })
	for _, edge in { { 0, height / 2, width + 0.4, 0.28 }, { 0, -height / 2, width + 0.4, 0.28 } } do
		self:block(parent, name .. "Trim", Vector3.new(edge[3], edge[4], 0.7), where * CFrame.new(edge[1], edge[2], -0.05), tint, Enum.Material.Neon, { cast = false })
	end
	self.metrics.signs += 1
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignFace"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 36
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.MaxDistance = if opts and opts.distance then opts.distance else 150
	gui.Adornee = panel
	gui.Parent = panel
	local title, subtitle = string.match(text, "^(.-)\n(.*)$")
	local function line(textValue: string, y: number, h: number, color: Color3, font: Enum.Font)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.Position = UDim2.fromScale(0.5, y)
		label.Size = UDim2.fromScale(0.94, h)
		label.TextScaled = true
		label.TextWrapped = true
		label.Font = font
		label.TextColor3 = color
		label.Text = textValue
		label.Parent = gui
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = 120
		limit.Parent = label
	end
	if title then
		line(title, 0.06, 0.52, tint, Enum.Font.GothamBlack)
		line(subtitle, 0.60, 0.34, P.white, Enum.Font.GothamMedium)
	else
		line(text, 0.12, 0.76, tint, Enum.Font.GothamBlack)
	end
	return panel
end

function Kit:label(host: Instance, text: string, width: number?, height: number?, tint: Color3?, distance: number?): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "DistrictLabel"
	gui.Adornee = host :: any
	gui.Size = UDim2.fromOffset(width or 240, height or 44)
	gui.MaxDistance = distance or 90
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Parent = host
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 18
	textLabel.TextWrapped = true
	textLabel.TextColor3 = tint or Kit.P.white
	textLabel.TextStrokeTransparency = 0.45
	textLabel.Text = text
	textLabel.Parent = gui
	return gui
end

function Kit:prompt(host: BasePart, action: string, text: string): ProximityPrompt
	host.CanQuery = true
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

-- Lights start disabled; WorldEffectsController enables only the nearest budgeted few.
function Kit:light(host: Instance, tint: Color3, range: number?, brightness: number?)
	if self.metrics.lights >= self.limits.lights then return end
	self.metrics.lights += 1
	local item = Instance.new("PointLight")
	item.Color = tint
	item.Range = range or 16
	item.Brightness = brightness or 1.2
	item.Shadows = false
	item.Enabled = false
	item.Parent = host
	CollectionService:AddTag(item, "MogvilleLight")
end

function Kit:sparkles(host: Instance, tint: Color3, rate: number?)
	if self.metrics.emitters >= self.limits.emitters then return end
	self.metrics.emitters += 1
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "CitySparkles"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(tint)
	emitter.LightEmission = 0.6
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.28), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Rate = rate or 4
	emitter:SetAttribute("MaxParticles", 12)
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(1, 2)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.Enabled = false
	emitter.Parent = host
	CollectionService:AddTag(emitter, "MogvilleParticles")
end

-- Upward water spray for fountains. Purely client-rendered; no per-frame replication.
function Kit:spray(host: Instance, tint: Color3?, speed: number?)
	if self.metrics.emitters >= self.limits.emitters then return end
	self.metrics.emitters += 1
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "FountainSpray"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(tint or Color3.fromRGB(190, 236, 255))
	emitter.LightEmission = 0.35
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.1) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	emitter.Rate = 10
	emitter:SetAttribute("MaxParticles", 20)
	emitter.Lifetime = NumberRange.new(1.2, 1.8)
	emitter.Speed = NumberRange.new((speed or 14) * 0.8, speed or 14)
	emitter.Acceleration = Vector3.new(0, -22, 0)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.SpreadAngle = Vector2.new(10, 10)
	emitter.Enabled = false
	emitter.Parent = host
	CollectionService:AddTag(emitter, "MogvilleParticles")
end

return Kit
