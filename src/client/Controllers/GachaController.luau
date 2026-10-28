--!strict
-- The server has awarded every result before this presentation starts.
-- Sealed backs are decoration, never fake client-generated rewards or odds.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Rules"))
local Config = require(ReplicatedStorage.Shared.Config)
local CharacterVisuals = require(ReplicatedStorage.Shared.CharacterVisuals)
local Theme = require(script.Parent.Theme)

local GachaController = {}
GachaController.__index = GachaController

function GachaController.new(gui: ScreenGui)
	return setmetatable({ gui = gui, generation = 0, overlay = nil, activeTweens = {} }, GachaController)
end

function GachaController:show(rewards: { any }, settings: any)
	if #rewards == 0 then return end
	self.generation += 1
	local generation = self.generation
	for _, tween in self.activeTweens do tween:Cancel() end
	self.activeTweens = {}
	if self.overlay then self.overlay:Destroy() end
	local overlay = Theme.make("Frame", {
		Name = "CardSpinReveal", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.colors.background, BackgroundTransparency = 0.035,
		ZIndex = 20, Active = true,
	}, self.gui)
	self.overlay = overlay
	Theme.make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(116, 79, 162), Color3.fromRGB(19, 23, 42)), Rotation = 45 }, overlay)
	local content = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.95, 0, 0.94, 0), BackgroundTransparency = 1, ZIndex = 21,
	}, overlay)
	Theme.make("UISizeConstraint", { MaxSize = Vector2.new(940, 900) }, content)
	local heading = Theme.label(content, "CARD SPIN", 28, Theme.colors.gold)
	heading.Size = UDim2.new(1, 0, 0, 40)
	heading.TextXAlignment = Enum.TextXAlignment.Center
	heading.Font = Enum.Font.GothamBlack
	local status = Theme.label(content, "Results are already selected securely on the server", 13)
	status.Position = UDim2.fromOffset(0, 42)
	status.Size = UDim2.new(1, 0, 0, 32)
	status.TextXAlignment = Enum.TextXAlignment.Center
	local scroll = Theme.make("ScrollingFrame", {
		Name = "AwardedCards", Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 1, -146),
		BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.colors.purple,
	}, content)
	Theme.padding(scroll, 6)
	Theme.list(scroll, 14)
	local done, skip = false, settings.reducedMotion or settings.autoSkip
	local button = Theme.button(content, "SKIP PRESENTATION", function()
		if done then
			self.generation += 1
			for _, tween in self.activeTweens do tween:Cancel() end
			self.activeTweens = {}
			overlay:Destroy(); self.overlay = nil
		else skip = true end
	end, Theme.colors.gold)
	button.Position = UDim2.new(0, 0, 1, -52)
	button.Size = UDim2.new(1, 0, 0, 50)
	local function alive(): boolean return generation == self.generation and overlay.Parent ~= nil end
	local function spinStrip()
		if skip then return end
		local viewport = Theme.make("Frame", {
			Name = "CardRoulette", Size = UDim2.new(1, 0, 0, 238), BackgroundColor3 = Theme.colors.panel,
			BorderSizePixel = 0, ClipsDescendants = true,
		}, scroll)
		Theme.corner(viewport, 12)
		Theme.stroke(viewport, Theme.colors.gold, 0.3)
		local strip = Theme.make("Frame", { Name = "SealedCardTrack", Size = UDim2.fromOffset(13 * 174, 218), Position = UDim2.new(0.5, 0, 0, 10), BackgroundTransparency = 1 }, viewport)
		local resultSlot = 10
		for slot = 1, 13 do
			local holder = Theme.make("Frame", { Size = UDim2.fromOffset(156, 218), Position = UDim2.fromOffset((slot - 1) * 174, 0), BackgroundTransparency = 1 }, strip)
			if slot == resultSlot then
				local instance = rewards[1]
				local stats = Rules.characterStats(instance)
				local accent = Theme.hex(stats.color)
				local card = Theme.collectibleCard(holder, stats, CharacterVisuals.get(instance.characterId), accent)
				card.Size = UDim2.fromOffset(260, 346)
				Theme.make("UIScale", { Scale = 0.6 }, card)
			else
				local back = Theme.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.colors.card, BorderSizePixel = 0 }, holder)
				Theme.corner(back, 12)
				Theme.stroke(back, Theme.colors.purple, 0.3).Thickness = 2
				Theme.make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(245, 240, 255), Color3.fromRGB(98, 77, 144)), Rotation = 35 }, back)
				local crest = Theme.label(back, "M", 60, Theme.colors.gold)
				crest.Size = UDim2.fromScale(1, 0.65); crest.Position = UDim2.fromScale(0, 0.12)
				crest.TextXAlignment = Enum.TextXAlignment.Center; crest.Font = Enum.Font.GothamBlack
				local sealed = Theme.label(back, "SEALED CARD", 11, Theme.colors.muted)
				sealed.Position = UDim2.fromScale(0.05, 0.77); sealed.Size = UDim2.fromScale(0.9, 0.15)
				sealed.TextXAlignment = Enum.TextXAlignment.Center
			end
		end
		local pointer = Theme.label(viewport, "▼", 24, Theme.colors.gold)
		pointer.Position = UDim2.new(0.5, -14, 0, -1); pointer.Size = UDim2.fromOffset(28, 28); pointer.ZIndex = 5
		local target = UDim2.new(0.5, -((resultSlot - 1) * 174 + 78), 0, 10)
		local tween = TweenService:Create(strip, TweenInfo.new(1.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = target })
		table.insert(self.activeTweens, tween); tween:Play()
		local deadline = os.clock() + 1.85
		while alive() and not skip and os.clock() < deadline do task.wait(0.03) end
		tween:Cancel()
		if not alive() then return end
		strip.Position = target
		if not skip then task.wait(0.2) end
		if alive() then viewport:Destroy() end
	end
	task.spawn(function()
		spinStrip()
		if not alive() then return end
		local width = math.max(220, scroll.AbsoluteSize.X - 16)
		local columns = if #rewards == 1 then 1 else math.clamp(math.floor((width + 12) / 232), 1, 3)
		local row = nil
		for index, instance in rewards do
			if not alive() then return end
			local column = (index - 1) % columns
			if column == 0 then row = Theme.make("Frame", { Size = UDim2.new(1, -4, 0, 390), BackgroundTransparency = 1 }, scroll) end
			local holder = Theme.make("Frame", { Size = UDim2.new(1 / columns, -12 * (columns - 1) / columns, 1, 0), Position = UDim2.new(column / columns, column * 12 / columns, 0, 0), BackgroundTransparency = 1 }, row)
			if #rewards == 1 then
				holder.AnchorPoint = Vector2.new(0.5, 0); holder.Position = UDim2.fromScale(0.5, 0)
				holder.Size = UDim2.new(1, 0, 1, 0)
				Theme.make("UISizeConstraint", { MaxSize = Vector2.new(330, 390) }, holder)
			end
			local stats = Rules.characterStats(instance)
			local accent = Theme.hex(stats.color)
			local tier = 1
			for rank, rarity in Config.Rarities do if rarity.id == stats.rarity then tier = rank; break end end
			local card = Theme.collectibleCard(holder, stats, CharacterVisuals.get(instance.characterId), accent)
			local statsLine = Theme.label(holder, "HP " .. Theme.number(stats.health) .. "  ·  DEF " .. Theme.number(stats.defense) .. "  ·  SPD " .. Theme.number(stats.speed), 12, Theme.colors.muted)
			statsLine.Position = UDim2.fromOffset(4, 350); statsLine.Size = UDim2.new(1, -8, 0, 36)
			statsLine.TextXAlignment = Enum.TextXAlignment.Center
			if settings.sound and not skip then
				local sound = Theme.make("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.12 + tier * 0.025, PlaybackSpeed = 0.85 + tier * 0.1 }, overlay)
				sound:Play(); Debris:AddItem(sound, 2)
			end
			if not skip and not settings.lowEffects then
				local scale = Theme.make("UIScale", { Scale = 0.92 }, card)
				local tween = TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
				table.insert(self.activeTweens, tween); tween:Play()
			end
		end
		if alive() then
			done = true; button.Text = "CONTINUE COLLECTING"
			heading.Text = if #rewards == 1 then "CARD ADDED" else tostring(#rewards) .. " CARDS ADDED"
			status.Text = "Owned rewards are in Inventory. Photo placeholders remain clearly unresolved."
		end
	end)
end

return GachaController
