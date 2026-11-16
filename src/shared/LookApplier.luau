--!strict
-- Applies a CharacterLooks.Look to an R15 rig. Works identically on server and client.
-- Everything is measured from the rig's own part sizes, so it adapts to any R15 proportions.
-- Decor parts are unanchored, massless, non-colliding and welded to a body part, so they
-- follow the rig whether it is posed on an anchored root or driven by a Humanoid.
local LookCatalog = require(script.Parent.LookCatalog)
local PoseLibrary = require(script.Parent.PoseLibrary)

local LookApplier = {}

LookApplier.MaxDecorParts = 16

local R15 = {
	"Head", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local STRIP = { "BodyColors", "Shirt", "Pants", "ShirtGraphic", "CharacterMesh", "Accessory", "Hat" }

local function materialNamed(name: string?): Enum.Material
	if name == nil then return Enum.Material.SmoothPlastic end
	local ok, value = pcall(function() return (Enum.Material :: any)[name] end)
	if ok and value then return value :: Enum.Material end
	return Enum.Material.SmoothPlastic
end

local function colorOf(look: any, key: string?): Color3
	local value = key or "primary"
	local hex = look.palette[value] or LookCatalog.DefaultPalette[value] or value
	return Color3.fromHex(hex)
end

-- Body part -> outfit key. Missing keys fall back to sensible neighbors.
local function outfitKey(look: any, partName: string): string
	local o = look.outfit
	if partName == "Head" then return "skin" end
	if partName == "UpperTorso" then return o.top or "primary" end
	if partName == "LowerTorso" then return o.hips or o.top or "primary" end
	if string.find(partName, "UpperArm") then return o.sleeve or "skin" end
	if string.find(partName, "LowerArm") then return o.forearm or o.sleeve or "skin" end
	if string.find(partName, "Hand") then return o.hand or "skin" end
	if string.find(partName, "UpperLeg") then return o.upperLeg or "dark" end
	if string.find(partName, "LowerLeg") then return o.lowerLeg or o.upperLeg or "dark" end
	return o.foot or "dark"
end

local function paintBody(model: Model, look: any)
	local cloth = materialNamed(look.outfit.material or "Fabric")
	for _, name in R15 do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			local key = outfitKey(look, name)
			part.Color = colorOf(look, key)
			part.Material = if key == "skin" then Enum.Material.SmoothPlastic elseif string.find(name, "Foot") then Enum.Material.Leather else cloth
		end
	end
end

local function unitOf(part: BasePart, region: string): Vector3
	if region == "Head" then
		local size = part.Size
		local unit = math.min(size.X, size.Y, size.Z)
		return Vector3.new(unit, unit, unit)
	end
	return part.Size
end

local function decorate(model: Model, spec: any, look: any, label: string, index: number): Part?
	local anchor = model:FindFirstChild(spec.p)
	if not anchor or not anchor:IsA("BasePart") then return nil end
	local u = unitOf(anchor, spec.p)
	local at = spec.at or { 0, 0, 0 }
	local rot = spec.rot or { 0, 0, 0 }
	local frame = anchor.CFrame * CFrame.new(at[1] * u.X, at[2] * u.Y, at[3] * u.Z)
		* CFrame.Angles(math.rad(rot[1]), math.rad(rot[2]), math.rad(rot[3]))
	local item = Instance.new("Part")
	item.Name = string.format("Look_%s_%d", label, index)
	if spec.s == "Cylinder" then
		local diameter, length = spec.size[1] * u.X, spec.size[2] * u.Y
		item.Shape = Enum.PartType.Cylinder
		item.Size = Vector3.new(length, diameter, diameter)
		frame = frame * CFrame.Angles(0, 0, math.pi / 2) -- Roblox cylinders run along X; stand them up.
	elseif spec.s == "Ball" then
		item.Shape = Enum.PartType.Ball
		item.Size = Vector3.new(spec.size[1] * u.X, spec.size[2] * u.Y, spec.size[3] * u.Z)
	else
		item.Size = Vector3.new(spec.size[1] * u.X, spec.size[2] * u.Y, spec.size[3] * u.Z)
	end
	item.CFrame = frame
	item.Color = colorOf(look, spec.c)
	item.Material = materialNamed(spec.m)
	item.Transparency = spec.t or 0
	item.Anchored = false
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.CastShadow = false
	item.Massless = true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Name = "LookWeld"
	weld.Part0 = anchor
	weld.Part1 = item
	weld.Parent = item
	return item
end

-- Returns { decorParts, truncated, missing }. `missing` counts specs whose body part was absent.
function LookApplier.apply(model: Model, look: any, options: { maxDecor: number? }?): { decorParts: number, truncated: boolean, missing: number }
	for _, className in STRIP do
		for _, child in model:GetChildren() do
			if child.ClassName == className then child:Destroy() end
		end
	end
	paintBody(model, look)

	local budget = (options and options.maxDecor) or LookApplier.MaxDecorParts
	local built, missing, truncated = 0, 0, false
	local function place(specs: { any }, label: string)
		for index, spec in specs do
			if built >= budget then truncated = true; return end
			if decorate(model, spec, look, label, index) then built += 1 else missing += 1 end
		end
	end
	local hair = LookCatalog.Hair[look.hair]
	if hair then place(hair, "Hair") end
	for _, gearName in look.gear do
		local gear = LookCatalog.Gear[gearName]
		if gear then place(gear, gearName) end
	end

	PoseLibrary.apply(model, look.pose)
	if look.scale ~= 1 then model:ScaleTo(look.scale) end

	model:SetAttribute("LookId", look.id)
	model:SetAttribute("AppearanceStatus", "ProceduralStandIn")
	model:SetAttribute("DecorParts", built)
	return { decorParts = built, truncated = truncated, missing = missing }
end

return LookApplier
