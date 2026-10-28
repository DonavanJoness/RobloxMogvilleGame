--!strict
local Theme = {}

Theme.colors = {
	background = Color3.fromRGB(15, 11, 32),
	panel = Color3.fromRGB(28, 22, 51),
	card = Color3.fromRGB(42, 33, 70),
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
		TextColor3 = if color == Theme.colors.card then Theme.colors.text else Theme.colors.background,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true,
		Selectable = true,
	}, parent)
	Theme.corner(button, 10)
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

function Theme.portrait(parent: Instance, color: Color3, size: number?): Frame
	local edge = size or 66
	local portrait = Theme.make("Frame", {
		Size = UDim2.fromOffset(edge, edge),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, parent)
	Theme.corner(portrait, 16)
	Theme.make("UIGradient", {
		Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.3), color:Lerp(Theme.colors.background, 0.45)),
		Rotation = 45,
	}, portrait)
	local face = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(0.54, 0.6),
		BackgroundColor3 = Color3.fromRGB(246, 212, 171),
		BorderSizePixel = 0,
	}, portrait)
	Theme.corner(face, 7)
	for _, x in { 0.26, 0.67 } do
		local eye = Theme.make("Frame", {
			Position = UDim2.fromScale(x, 0.37),
			Size = UDim2.fromScale(0.13, 0.08),
			BackgroundColor3 = Theme.colors.background,
			BorderSizePixel = 0,
		}, face)
		Theme.corner(eye, 3)
	end
	Theme.make("Frame", {
		Position = UDim2.fromScale(0.3, 0.7),
		Size = UDim2.fromScale(0.4, 0.045),
		BackgroundColor3 = Color3.fromRGB(136, 76, 97),
		BorderSizePixel = 0,
	}, face)
	return portrait
end

return Theme
