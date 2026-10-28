--!strict
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
	return setmetatable({ gui = gui, generation = 0, overlay = nil }, GachaController)
end

function GachaController:show(rewards: { any }, settings: any)
	self.generation += 1
	local generation = self.generation
	if self.overlay then self.overlay:Destroy() end
	local overlay = Theme.make("Frame", {
		Name = "CharacterReveal", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.colors.background, BackgroundTransparency = 0.015,
		ZIndex = 20, Active = true,
	}, self.gui)
	self.overlay = overlay
	Theme.make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(121, 86, 179), Color3.fromRGB(30, 29, 63)), Rotation = 40 }, overlay)
	local content = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0.92, 0), BackgroundTransparency = 1, ZIndex = 21,
	}, overlay)
	Theme.make("UISizeConstraint", { MaxSize = Vector2.new(720, 850) }, content)
	local heading = Theme.label(content, "THE SPOTLIGHT IS YOURS", 26, Theme.colors.gold)
	heading.Size = UDim2.new(1, 0, 0, 40)
	heading.Font = Enum.Font.GothamBlack
	heading.TextXAlignment = Enum.TextXAlignment.Center
	heading.TextScaled = true
	Theme.make("UITextSizeConstraint", { MinTextSize = 16, MaxTextSize = 26 }, heading)
	local status = Theme.label(content, "Your next legend is stepping into the light…", 14)
	status.Position = UDim2.fromOffset(0, 43)
	status.Size = UDim2.new(1, 0, 0, 28)
	status.TextXAlignment = Enum.TextXAlignment.Center
	local scroll = Theme.make("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 1, -142),
		BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5,
		ScrollBarImageColor3 = Theme.colors.purple,
	}, content)
	Theme.padding(scroll, 4)
	Theme.list(scroll, 16)
	local effects = Theme.make("Frame", { Name = "RevealSparkles", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 25, ClipsDescendants = true }, overlay)
	local tweens: { Tween } = {}
	local scales: { UIScale } = {}
	local done, skip = false, false
	local function stopEffects()
		for _, tween in tweens do tween:Cancel() end
		for _, scale in scales do if scale.Parent then scale.Scale = 1 end end
		effects:ClearAllChildren()
	end
	local continueButton = Theme.button(content, "Skip reveal animation", function()
		if done then
			self.generation += 1
			stopEffects()
			overlay:Destroy()
			self.overlay = nil
		else
			skip = true
			stopEffects()
		end
	end, Theme.colors.cyan)
	continueButton.Position = UDim2.new(0, 0, 1, -48)
	local function sparkles(tier: number, color: Color3)
		if tier < 3 or settings.reducedMotion or settings.lowEffects or settings.autoSkip or skip then return end
		effects:ClearAllChildren() -- One bounded burst at a time, including ten-pull reveals.
		local count = if tier >= 5 then 24 else 12
		for index = 1, count do
			local angle = (index / count) * math.pi * 2
			local spark = Theme.make("Frame", {
				Size = UDim2.fromOffset(if tier == 6 then 9 else 6, if tier == 6 then 9 else 6),
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45),
				Rotation = 45, BackgroundColor3 = if tier == 6 then Color3.fromHSV(index / count, 0.5, 1) else color,
				BorderSizePixel = 0,
			}, effects)
			local tween = TweenService:Create(spark, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.5 + math.cos(angle) * 0.45, 0.45 + math.sin(angle) * 0.4),
				BackgroundTransparency = 1, Rotation = 180,
			})
			table.insert(tweens, tween)
			tween:Play()
			Debris:AddItem(spark, 1)
		end
	end
	task.spawn(function()
		for index, instance in rewards do
			if self.generation ~= generation then return end
			local stats = Rules.characterStats(instance)
			local visual = CharacterVisuals.get(instance.characterId)
			local accent = Theme.hex(stats.color)
			local tier = 1
			for rank, rarity in Config.Rarities do if rarity.id == stats.rarity then tier = rank end end
			local card = Theme.card(scroll, accent)
			card.LayoutOrder = index
			Theme.badge(card, string.upper(stats.rarity) .. "  /  " .. tostring(visual.form or "Standard") .. " FORM", accent)
			local hero = Theme.make("Frame", { Size = UDim2.new(1, 0, 0, if #rewards == 1 then 216 else 156), BackgroundTransparency = 1 }, card)
			local edge = if #rewards == 1 then 204 else 148
			local portrait = Theme.portrait(hero, accent, edge, instance.characterId)
			portrait.AnchorPoint = Vector2.new(0.5, 0)
			portrait.Position = UDim2.fromScale(0.5, 0)
			local name = Theme.label(card, string.upper(stats.name), 23, accent)
			name.Size = UDim2.new(1, 0, 0, 0)
			name.AutomaticSize = Enum.AutomaticSize.Y
			name.TextXAlignment = Enum.TextXAlignment.Center
			name.Font = Enum.Font.GothamBlack
			local detail = Theme.paragraph(card, tostring(stats.mutation) .. " MUTATION  ·  Level " .. tostring(instance.level or 1), Theme.colors.text)
			detail.TextXAlignment = Enum.TextXAlignment.Center
			Theme.badge(card, "+" .. Theme.number(stats.income) .. " COINS / SEC   •   " .. Theme.number(stats.attack) .. " POWER", Theme.colors.gold)
			Theme.paragraph(card, "HP " .. Theme.number(stats.health) .. " · Defense " .. Theme.number(stats.defense) .. " · Speed " .. Theme.number(stats.speed), Theme.colors.text)
			if #rewards == 1 then Theme.paragraph(card, visual.description or "A new original legend joins your collection.") end
			if tier >= 4 then Theme.stroke(card, accent, 0.05).Thickness = if tier == 6 then 3 else 2 end
			if tier == 6 then
				local gradient = card:FindFirstChildOfClass("UIGradient")
				if gradient then gradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(102, 231, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(223, 150, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 224, 145)) }) end
			end
			if settings.sound and not (settings.autoSkip or skip) then
				local sound = Theme.make("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.12 + tier * 0.025, PlaybackSpeed = 0.85 + tier * 0.1 }, overlay)
				sound:Play()
				Debris:AddItem(sound, 2)
			end
			if not (settings.reducedMotion or settings.autoSkip or skip) then
				local scale = Theme.make("UIScale", { Scale = if tier >= 4 then 0.78 else 0.9 }, portrait)
				table.insert(scales, scale)
				local tween = TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
				table.insert(tweens, tween)
				tween:Play()
				sparkles(tier, accent)
				task.wait(if tier >= 5 then 0.7 else 0.2)
			end
		end
		if self.generation == generation then
			done = true
			continueButton.Text = "Continue collecting"
			status.Text = tostring(#rewards) .. " Mogger" .. (if #rewards == 1 then "" else "s") .. " secured · Open Inventory to inspect or display"
		end
	end)
end

return GachaController
