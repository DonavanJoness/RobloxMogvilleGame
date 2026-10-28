--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterVisuals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CharacterVisuals"))
local Theme = {}

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

-- Only approved Roblox asset IDs are accepted. Unset or inaccessible images keep
-- a distinctive procedural illustration visible; browser URLs are never used.
function Theme.portrait(parent: Instance, color: Color3, size: number?, characterId: string?): Frame
	local edge = size or 66
	local visual = CharacterVisuals.get(characterId)
	local portrait = Theme.make("Frame", {
		Name = "CharacterPortrait",
		Size = UDim2.fromOffset(edge, edge),
		BackgroundColor3 = color:Lerp(Theme.colors.background, 0.45),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, parent)
	Theme.corner(portrait, math.min(20, edge * 0.18))
	Theme.stroke(portrait, color, 0.1).Thickness = 2
	Theme.make("UIGradient", {
		Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.5), color:Lerp(Theme.colors.background, 0.6)),
		Rotation = 45,
	}, portrait)
	local fallback = Theme.make("Frame", { Name = "OriginalIllustration", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, portrait)
	local seed = 17
	for index = 1, #(visual.identityId or characterId or "rookie") do
		seed = (seed * 31 + string.byte(visual.identityId or characterId or "rookie", index)) % 9973
	end
	for index = 1, 3 do
		local stripe = Theme.make("Frame", {
			Size = UDim2.fromScale(0.08, 1.5), Position = UDim2.fromScale(0.1 + index * 0.3, -0.2),
			Rotation = 24, BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.5), BackgroundTransparency = 0.8, BorderSizePixel = 0,
		}, fallback)
		stripe.ZIndex = 1
	end
	local shoulders = Theme.make("Frame", { Position = UDim2.fromScale(0.12, 0.7), Size = UDim2.fromScale(0.76, 0.5), BackgroundColor3 = color:Lerp(Theme.colors.background, 0.4), BorderSizePixel = 0 }, fallback)
	Theme.corner(shoulders, edge * 0.2)
	local skin = Color3.fromRGB(246 - seed % 45, 210 - seed % 60, 170 - seed % 55)
	local face = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.44),
		Size = UDim2.fromScale(0.5 + (seed % 5) * 0.01, 0.59),
		BackgroundColor3 = skin,
		BorderSizePixel = 0,
	}, fallback)
	Theme.corner(face, edge * 0.11)
	Theme.make("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(214, 195, 182)), Rotation = 45 }, face)
	local hairColor = Color3.fromHSV((seed % 100) / 100, 0.35, 0.12 + (seed % 3) * 0.16)
	local hair = Theme.make("Frame", { Position = UDim2.fromScale(-0.03, -0.08), Size = UDim2.fromScale(1.06, 0.27 + (seed % 3) * 0.03), BackgroundColor3 = hairColor, BorderSizePixel = 0, Rotation = if seed % 2 == 0 then -5 else 3 }, face)
	Theme.corner(hair, edge * 0.055)
	for _, x in { 0.26, 0.67 } do
		local eye = Theme.make("Frame", {
			Position = UDim2.fromScale(x, 0.37),
			Size = UDim2.fromScale(if seed % 3 == 0 then 0.23 else 0.12, if seed % 3 == 0 then 0.15 else 0.065),
			BackgroundColor3 = Theme.colors.background,
			BorderSizePixel = 0,
		}, face)
		Theme.corner(eye, edge * 0.025)
		Theme.make("Frame", { Position = UDim2.fromScale(x - 0.02, 0.28), Size = UDim2.fromScale(0.18, 0.045), BackgroundColor3 = hairColor, BorderSizePixel = 0, Rotation = if x < 0.5 then -8 else 8 }, face)
	end
	Theme.make("Frame", {
		Position = UDim2.fromScale(0.3, 0.74),
		Size = UDim2.fromScale(0.4, 0.035),
		BackgroundColor3 = Color3.fromRGB(136, 76, 97),
		BorderSizePixel = 0,
	}, face)
	if visual.form == "Apex" or visual.form == "Ascended" or seed % 5 == 0 then
		for index = 1, 3 do
			Theme.make("Frame", { Position = UDim2.fromScale(0.22 + index * 0.12, 0.055), Size = UDim2.fromScale(0.12, if index == 2 then 0.17 else 0.12), Rotation = 45, BackgroundColor3 = Theme.colors.gold, BorderSizePixel = 0 }, fallback)
		end
	end
	local assetId = visual.portraitAssetId
	if CharacterVisuals.validAssetId(assetId) then
		local image = Theme.make("ImageLabel", { Name = "ApprovedPortrait", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://" .. string.format("%.0f", assetId), ScaleType = Enum.ScaleType.Crop, Visible = false, ZIndex = 3 }, portrait)
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
			-- A failed moderation/network load deliberately leaves the original art.
			if image.Parent and not image.IsLoaded then image:Destroy() end
		end)
	end
	return portrait
end

return Theme
