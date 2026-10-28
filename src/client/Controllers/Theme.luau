--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterVisuals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CharacterVisuals"))
local RunService = game:GetService("RunService")
local Theme = {}
local motionSettings = {}
local animatedBorders = setmetatable({}, { __mode = "k" })
local borderClock = 0

function Theme.setMotionSettings(settings) motionSettings = settings or {} end

-- One bounded local loop for visible rarity frames, never a loop per inventory card.
RunService.RenderStepped:Connect(function(dt)
	borderClock += dt
	if borderClock < 1 / 20 then return end
	borderClock = 0
	local count, now = 0, os.clock()
	for stroke, entry in animatedBorders do
		local host = stroke.Parent
		if not host then animatedBorders[stroke] = nil; continue end
		local camera = workspace.CurrentCamera
		local visible, ancestor = true, host
		if camera and host:IsA("GuiObject") then
			local position, size, viewport = host.AbsolutePosition, host.AbsoluteSize, camera.ViewportSize
			visible = position.X + size.X >= 0 and position.Y + size.Y >= 0 and position.X <= viewport.X and position.Y <= viewport.Y
		end
		while visible and ancestor do
			if ancestor:IsA("GuiObject") and not ancestor.Visible then visible = false; break end
			ancestor = ancestor.Parent
		end
		if not visible or count >= 24 or motionSettings.lowEffects or motionSettings.reducedMotion then
			stroke.Color = entry.color; stroke.Transparency = 0.08
		else
			count += 1
			stroke.Color = if entry.prismatic then Color3.fromHSV((now * 0.12) % 1, 0.5, 1) else entry.color
			stroke.Transparency = 0.08 + 0.22 * (0.5 + 0.5 * math.sin(now * 2.1 + entry.phase))
		end
	end
end)

Theme.colors = {
	background = Color3.fromRGB(12, 9, 28),
	panel = Color3.fromRGB(25, 18, 49),
	card = Color3.fromRGB(43, 30, 75),
	text = Color3.fromRGB(246, 241, 255),
	muted = Color3.fromRGB(188, 177, 214),
	cyan = Color3.fromRGB(83, 226, 243),
	gold = Color3.fromRGB(255, 209, 105),
	purple = Color3.fromRGB(168, 112, 255),
	green = Color3.fromRGB(115, 236, 162),
	red = Color3.fromRGB(255, 134, 150),
}

function Theme.make(className: string, properties: { [string]: any }?, parent: Instance?): any
	local object = Instance.new(className)
	for key, value in properties or {} do
		(object :: any)[key] = value
	end
	object.Parent = parent
	return object
end

function Theme.corner(parent: Instance, radius: number?)
	return Theme.make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, parent)
end

function Theme.stroke(parent: Instance, color: Color3?, transparency: number?)
	return Theme.make("UIStroke", {
		Color = color or Theme.colors.purple,
		Transparency = transparency or 0.65,
		Thickness = 1,
	}, parent)
end

function Theme.padding(parent: Instance, value: number)
	Theme.make("UIPadding", {
		PaddingTop = UDim.new(0, value),
		PaddingBottom = UDim.new(0, value),
		PaddingLeft = UDim.new(0, value),
		PaddingRight = UDim.new(0, value),
	}, parent)
end

function Theme.list(parent: Instance, gap: number?, horizontal: boolean?)
	return Theme.make("UIListLayout", {
		Padding = UDim.new(0, gap or 10),
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, parent)
end

function Theme.label(parent: Instance, text: string, size: number?, color: Color3?): TextLabel
	return Theme.make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		Text = text,
		TextSize = size or 16,
		TextColor3 = color or Theme.colors.text,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
	}, parent)
end

function Theme.paragraph(parent: Instance, text: string, color: Color3?): TextLabel
	local label = Theme.label(parent, text, 15, color or Theme.colors.muted)
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	return label
end

function Theme.button(parent: Instance, text: string, callback: () -> (), color: Color3?): TextButton
	local button = Theme.make("TextButton", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = color or Theme.colors.purple,
		BorderSizePixel = 0,
		Text = text,
		TextSize = 15,
		TextWrapped = true,
		TextScaled = true,
		TextColor3 = if color == Theme.colors.card then Theme.colors.text else Theme.colors.background,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true,
		Selectable = true,
	}, parent)
	Theme.corner(button, 10)
	Theme.make("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 15 }, button)
	Theme.stroke(button, (color or Theme.colors.purple):Lerp(Color3.new(1, 1, 1), 0.25), 0.2)
	Theme.make("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(210, 212, 234)), Rotation = 90 }, button)
	button.Activated:Connect(callback)
	return button
end

function Theme.card(parent: Instance, accent: Color3?): Frame
	local frame = Theme.make("Frame", {
		Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.colors.card,
		BorderSizePixel = 0,
	}, parent)
	Theme.corner(frame)
	Theme.stroke(frame, accent)
	Theme.make("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(203, 193, 224)), Rotation = 105 }, frame)
	Theme.padding(frame, 14)
	Theme.list(frame, 7)
	return frame
end

function Theme.hex(value: any): Color3
	if type(value) ~= "string" then
		return Theme.colors.purple
	end
	local cleaned = value:gsub("#", "")
	local ok, color = pcall(Color3.fromHex, cleaned)
	return if ok then color else Theme.colors.purple
end

function Theme.number(value: number?): string
	local n = value or 0
	local suffixes = { "", "K", "M", "B", "T", "Qa" }
	local tier = 1
	while math.abs(n) >= 1000 and tier < #suffixes do
		n /= 1000
		tier += 1
	end
	if tier == 1 then
		return string.format("%.0f", n)
	end
	return string.format(if n >= 100 then "%.0f%s" else "%.1f%s", n, suffixes[tier])
end

function Theme.badge(parent: Instance, text: string, color: Color3?): Frame
	local frame = Theme.make("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = (color or Theme.colors.purple):Lerp(Theme.colors.background, 0.75), BorderSizePixel = 0 }, parent)
	Theme.corner(frame, 8)
	Theme.stroke(frame, color, 0.4)
	local label = Theme.label(frame, text, 12, color or Theme.colors.text)
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.fromOffset(8, 0)
	label.Font = Enum.Font.GothamBold
	return frame
end

function Theme.meter(parent: Instance, caption: string, fraction: number, color: Color3?): Frame
	local holder = Theme.make("Frame", { Size = UDim2.new(1, 0, 0, 47), BackgroundTransparency = 1 }, parent)
	Theme.label(holder, caption, 13, color or Theme.colors.cyan)
	local track = Theme.make("Frame", { Position = UDim2.fromOffset(0, 31), Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = Theme.colors.background, BorderSizePixel = 0 }, holder)
	Theme.corner(track, 6)
	local fill = Theme.make("Frame", { Name = "Fill", Size = UDim2.new(math.clamp(fraction, 0, 1), 0, 1, 0), BackgroundColor3 = color or Theme.colors.cyan, BorderSizePixel = 0 }, track)
	Theme.corner(fill, 6)
	return holder
end

-- Missing rights or photos stay unresolved. Never draw a substitute human face.
function Theme.portrait(parent: Instance, color: Color3, size: number?, characterId: string?): Frame
	local edge = size or 66
	local visual = CharacterVisuals.get(characterId)
	local portrait = Theme.make("Frame", {
		Name = "CharacterPortrait", Size = UDim2.fromOffset(edge, edge),
		BackgroundColor3 = color:Lerp(Theme.colors.background, 0.86), BorderSizePixel = 0,
		ClipsDescendants = true,
	}, parent)
	Theme.corner(portrait, 10)
	Theme.stroke(portrait, color, 0.25).Thickness = 2
	Theme.make("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(112, 118, 152)), Rotation = 35 }, portrait)
	local fallback = Theme.make("Frame", { Name = "UnresolvedPhoto", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, portrait)
	local icon = Theme.label(fallback, "▧", math.clamp(edge * 0.25, 20, 55), color)
	icon.Size = UDim2.fromScale(1, 0.35)
	icon.Position = UDim2.fromScale(0, 0.16)
	icon.TextXAlignment = Enum.TextXAlignment.Center
	local missing = Theme.label(fallback, "PHOTO NOT SUPPLIED", math.clamp(edge * 0.065, 9, 15), Theme.colors.text)
	missing.Position = UDim2.fromScale(0.07, 0.52)
	missing.Size = UDim2.fromScale(0.86, 0.2)
	missing.TextXAlignment = Enum.TextXAlignment.Center
	missing.TextScaled = true
	Theme.make("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 15 }, missing)
	local status = Theme.label(fallback, if visual.referenceType == "RealPerson" then "PERMISSION / UPLOAD PENDING" else "LEGACY TEST CARD", math.clamp(edge * 0.045, 8, 11), Theme.colors.muted)
	status.Position = UDim2.fromScale(0.07, 0.73)
	status.Size = UDim2.fromScale(0.86, 0.17)
	status.TextXAlignment = Enum.TextXAlignment.Center
	status.TextScaled = true
	Theme.make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 11 }, status)
	local assetId = visual.portraitAssetId
	if visual.referenceType == "RealPerson" and visual.authenticPortraitReady == true and CharacterVisuals.validAssetId(assetId) then
		local image = Theme.make("ImageLabel", { Name = "VerifiedAuthenticPhoto", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://" .. string.format("%.0f", assetId), ScaleType = Enum.ScaleType.Crop, Visible = false, ZIndex = 3 }, portrait)
		local connection: RBXScriptConnection?
		local function loaded()
			if image.Parent and image.IsLoaded then
				image.Visible = true
				fallback.Visible = false
				if connection then connection:Disconnect() end
			end
		end
		connection = image:GetPropertyChangedSignal("IsLoaded"):Connect(loaded)
		loaded()
		task.delay(12, function()
			if connection then connection:Disconnect() end
			if image.Parent and not image.IsLoaded then image:Destroy() end
		end)
	end
	return portrait
end

function Theme.rarityBorder(parent: Instance, accent: Color3, rarity: string)
	local stroke = Theme.stroke(parent, accent, 0.08)
	stroke.Thickness = if rarity == "Ascended" then 3 else 2
	if rarity == "Rare" or rarity == "Mythic" or rarity == "Divine" or rarity == "Ascended" then
		animatedBorders[stroke] = { color = accent, prismatic = rarity == "Ascended", phase = #parent.Name * 0.6 }
	end
	return stroke
end

-- A consistent portrait-first card. Parent controls its final size for grids/reveals.
function Theme.collectibleCard(parent: Instance, stats: any, visual: any, accent: Color3): Frame
	local frame = Theme.make("Frame", { Name = "CollectibleCard", Size = UDim2.new(1, 0, 0, 346), BackgroundColor3 = Theme.colors.panel, BorderSizePixel = 0, ClipsDescendants = true }, parent)
	Theme.corner(frame, 13)
	Theme.rarityBorder(frame, accent, stats.rarity)
	Theme.make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(246, 246, 255), Color3.fromRGB(129, 137, 171)), Rotation = 100 }, frame)
	local rarity = Theme.label(frame, string.upper(stats.rarity), 12, accent)
	rarity.Font = Enum.Font.GothamBlack
	rarity.Position = UDim2.fromOffset(12, 7)
	rarity.Size = UDim2.new(0.62, 0, 0, 21)
	local power = Theme.label(frame, tostring(math.floor(stats.attack or 0)) .. " ATK", 12, Theme.colors.gold)
	power.Position = UDim2.new(0.62, 0, 0, 7)
	power.Size = UDim2.new(0.38, -12, 0, 21)
	power.TextXAlignment = Enum.TextXAlignment.Right
	local image = Theme.portrait(frame, accent, 190, stats.characterId)
	image.Position = UDim2.fromOffset(10, 34)
	image.Size = UDim2.new(1, -20, 0, 204)
	local name = Theme.label(frame, stats.name or "UNRESOLVED", 19, Theme.colors.text)
	name.Position = UDim2.fromOffset(12, 244)
	name.Size = UDim2.new(1, -24, 0, 46)
	name.Font = Enum.Font.GothamBlack
	name.TextScaled = true
	Theme.make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 20 }, name)
	local variant = Theme.label(frame, tostring(visual.form or visual.variant or "Classic") .. "  /  " .. tostring(stats.mutation or "Normal"), 11, accent)
	variant.Position = UDim2.fromOffset(12, 290)
	variant.Size = UDim2.new(1, -24, 0, 20)
	local income = Theme.label(frame, "+" .. Theme.number(stats.income) .. " COINS / SEC", 13, Theme.colors.gold)
	income.Position = UDim2.fromOffset(12, 314)
	income.Size = UDim2.new(1, -24, 0, 24)
	income.Font = Enum.Font.GothamBold
	return frame
end

return Theme
