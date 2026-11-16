-- Builds one collector plot: marble yard, round display pedestals, hedge boundary, a gate
-- arch carrying the owner sign, and flower beds. Returns the table WorldService stores per
-- plot (same fields as before), so ownership, rendering and release logic are unchanged.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Kit = require(script.Parent.EnvironmentKit)
local Props = require(script.Parent.EnvironmentProps)

local P, M, L = Kit.P, Enum.Material, Kit.Layer
local PlotBuilder = {}

PlotBuilder.FloorTop = L.plaza -- 0.40: above every street layer so plots never z-fight with paths
PlotBuilder.StandTop = L.plaza + 0.8

local MUTED = Color3.fromRGB(182, 174, 209)
local PANEL = Color3.fromRGB(63, 46, 92)

local function prompt(host: BasePart, action: string, objectText: string, ownerUserId: number?): ProximityPrompt
	host.CanQuery = true
	local item = Instance.new("ProximityPrompt")
	item.Name = "Open" .. action
	item.ActionText = "Open " .. action
	item.ObjectText = objectText
	item.MaxActivationDistance = 12
	item.HoldDuration = 0
	item.RequiresLineOfSight = false
	item.KeyboardKeyCode = Enum.KeyCode.E
	item:SetAttribute("Action", action)
	if ownerUserId then item:SetAttribute("OwnerUserId", ownerUserId) end
	item.Parent = host
	return item
end

local function standLabel(host: Instance, text: string): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Adornee = host :: any
	billboard.Size = UDim2.fromOffset(125, 28)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.4, 0)
	billboard.MaxDistance = 38
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.Parent = host
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundColor3 = Color3.fromRGB(25, 19, 43)
	textLabel.BackgroundTransparency = 0.15
	textLabel.TextColor3 = MUTED
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

-- Sign mounted on the gate lintel, facing the walkway. Returns the TextLabel WorldService edits.
local function ownerSign(kit: any, parent: Instance, position: Vector3, direction: Vector3, text: string): TextLabel
	local panel = kit:block(parent, "OwnerSign", Vector3.new(17, 4.2, 0.6), Props.facing(position, direction), P.deep, M.Metal, { query = true })
	kit:block(parent, "OwnerSignTrim", Vector3.new(17.4, 0.3, 0.8), Props.facing(position + Vector3.new(0, 2.25, 0), direction), P.gold, M.Neon, { cast = false })
	local gui = Instance.new("SurfaceGui")
	gui.Name = "OwnerSignFace"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 36
	gui.LightInfluence = 0
	gui.Brightness = 1.3
	gui.MaxDistance = 110
	gui.Adornee = panel
	gui.Parent = panel
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.fromScale(0.96, 0.9)
	textLabel.Position = UDim2.fromScale(0.02, 0.05)
	textLabel.TextScaled = true
	textLabel.TextWrapped = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextColor3 = P.white
	textLabel.Text = text
	textLabel.Parent = gui
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 64
	limit.Parent = textLabel
	return textLabel
end

-- topology: DistrictConfiguration.plot(...) result. Returns the per-plot record.
function PlotBuilder.build(kit: any, plotsFolder: Instance, index: number, topology: any, accent: Color3): any
	local side = topology.side
	local origin = Vector3.new(topology.x, topology.y, topology.z)
	local floorTop = PlotBuilder.FloorTop
	local inward = Vector3.new(-side, 0, 0) -- toward the collector walk
	local plot = Instance.new("Model")
	plot.Name = string.format("Residence_%02d", index)
	plot:SetAttribute("PlotIndex", index)
	plot:SetAttribute("AssetSlotKey", "plot_residence")
	plot:SetAttribute("PresentationStatus", "ProceduralStandInArchitecture")
	plot.Parent = plotsFolder

	kit:block(plot, "MarbleFloor", Vector3.new(88, 0.6, 54), origin + Vector3.new(0, floorTop - 0.3, 0), Color3.fromRGB(221, 225, 240), M.Marble, { collide = true })
	local borders = {}
	for _, z in { -26, 26 } do
		table.insert(borders, kit:block(plot, "GoldInlay", Vector3.new(88, 0.15, 0.35), origin + Vector3.new(0, floorTop + 0.075, z), P.gold, M.Metal, { cast = false }))
	end
	for _, x in { -43.5, 43.5 } do
		table.insert(borders, kit:block(plot, "ResidenceEdge", Vector3.new(0.4, 0.15, 52), origin + Vector3.new(x, floorTop + 0.075, 0), accent, M.Neon, { cast = false }))
	end
	kit:block(plot, "EntryCarpet", Vector3.new(88, 0.08, 7), origin + Vector3.new(0, floorTop + 0.04, 0), Color3.fromRGB(46, 34, 69), M.Fabric, { cast = false })

	-- Hedge boundary: outer end and both long sides; the inner side keeps a 16-stud gate.
	local innerX = topology.x - side * 44.8
	local outerX = topology.x + side * 45.2
	kit:block(plot, "HedgeOuter", Vector3.new(2.4, 2.6, 58.4), Vector3.new(outerX, floorTop + 1.3, topology.z), P.leaf, M.Grass, { collide = true })
	for _, z in { -28.4, 28.4 } do
		kit:block(plot, "HedgeSide", Vector3.new(92.8, 2.6, 2.4), Vector3.new(topology.x + side * 0.2, floorTop + 1.3, topology.z + z), P.leaf, M.Grass, { collide = true })
	end
	for _, z in { -18.2, 18.2 } do
		kit:block(plot, "HedgeGate", Vector3.new(2.4, 2.6, 21.6), Vector3.new(innerX, floorTop + 1.3, topology.z + z), P.leaf2, M.Grass, { collide = true })
	end
	-- Gate arch carrying the owner sign (readable from the walkway)
	for _, z in { -9.4, 9.4 } do
		local x = innerX
		kit:block(plot, "GatePillar", Vector3.new(2.6, 9.6, 2.6), Vector3.new(x, floorTop + 4.8, topology.z + z), P.marble, M.Marble, { collide = true })
		kit:block(plot, "GatePillarCap", Vector3.new(3.2, 0.5, 3.2), Vector3.new(x, floorTop + 9.85, topology.z + z), P.gold, M.Metal, { cast = false })
		kit:ball(plot, "GateLantern", 1.7, Vector3.new(x, floorTop + 11, topology.z + z), accent, M.Neon, { cast = false })
	end
	kit:block(plot, "GateLintel", Vector3.new(2.4, 1.2, 22), Vector3.new(innerX, floorTop + 10.9, topology.z), P.marble, M.Marble, { cast = false })
	local signText = ownerSign(kit, plot, Vector3.new(innerX + inward.X * 1.4, floorTop + 13.4, topology.z), inward, string.format("RESIDENCE %02d · AVAILABLE", index))
	-- Flower beds along the inner corners
	for _, z in { -23.5, 23.5 } do
		Props.planter(kit, plot, CFrame.new(topology.x - side * 33, floorTop, topology.z + z), 8, 3, { P.pink, P.gold, P.cyan })
	end

	local upgrades = Instance.new("Folder")
	upgrades.Name = "PrestigeDetails"
	upgrades.Parent = plot
	local display, pets = Instance.new("Folder"), Instance.new("Folder")
	display.Name, pets.Name = "Moggers", "Pets"
	display.Parent, pets.Parent = plot, plot

	-- Round pedestals. Position is the pedestal CENTER (top face = position.Y + 0.4).
	local stands = {}
	for slot = 1, Config.Game.MaxSlots do
		local slotPosition = origin + Vector3.new(-34 + ((slot - 1) % 5) * 17, floorTop + 0.4, math.floor((slot - 1) / 5) * 26 - 13)
		local stand = kit:cylinder(plot, "Stand" .. slot, 9.6, 0.8, slotPosition, PANEL, M.Marble, { collide = true })
		local rim = kit:cylinder(plot, "StandRim" .. slot, 11, 0.2, Vector3.new(slotPosition.X, floorTop + 0.1, slotPosition.Z), accent, M.Neon, { cast = false })
		local open = prompt(stand, "Inventory", "Display stand " .. slot, 0)
		open.Enabled = false
		local caption = standLabel(stand, "LOCKED")
		table.insert(stands, { part = stand, rim = rim, prompt = open, position = slotPosition, caption = caption })
	end

	local entrance = origin + Vector3.new(-side * 38, 4, 0)
	return {
		model = plot, index = index, origin = origin, accent = accent, stands = stands, signText = signText,
		display = display, pets = pets, upgrades = upgrades, borders = borders, owner = nil,
		floorTop = floorTop, spawnCFrame = CFrame.lookAt(entrance, origin + Vector3.new(0, 4, 0)),
	}
end

return PlotBuilder
