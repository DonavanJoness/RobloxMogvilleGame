--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Rules"))
local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(script.Parent.Theme)

local GachaController = {}
GachaController.__index = GachaController

function GachaController.new(gui: ScreenGui)
	return setmetatable({ gui = gui, generation = 0, overlay = nil }, GachaController)
end

function GachaController:show(rewards: { any }, settings: any)
	self.generation += 1
	local generation = self.generation
	if self.overlay then
		self.overlay:Destroy()
	end
	local overlay = Theme.make("Frame", {
		Name = "CharacterReveal",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.colors.background,
		BackgroundTransparency = 0.04,
		ZIndex = 20,
		Active = true,
	}, self.gui)
	self.overlay = overlay
	local content = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0.88, 0),
		BackgroundTransparency = 1,
		ZIndex = 21,
	}, overlay)
	Theme.make("UISizeConstraint", { MaxSize = Vector2.new(700, 780) }, content)
	local heading = Theme.label(content, "THE SPOTLIGHT IS YOURS", 25, Theme.colors.gold)
	heading.Size = UDim2.new(1, 0, 0, 42)
	heading.Font = Enum.Font.GothamBlack
	heading.TextXAlignment = Enum.TextXAlignment.Center
	local status = Theme.label(content, "Revealing your Moggers…", 15)
	status.Position = UDim2.fromOffset(0, 44)
	status.TextXAlignment = Enum.TextXAlignment.Center
	local scroll = Theme.make("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 82),
		Size = UDim2.new(1, 0, 1, -146),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = Theme.colors.purple,
	}, content)
	Theme.padding(scroll, 4)
	Theme.list(scroll, 12)
	local done = false
	local skip = false
	local continueButton = Theme.button(content, "Skip animation", function()
		if done then
			self.generation += 1
			overlay:Destroy()
			self.overlay = nil
		else
			skip = true
		end
	end, Theme.colors.cyan)
	continueButton.Position = UDim2.new(0, 0, 1, -48)
	task.spawn(function()
		for index, instance in rewards do
			if self.generation ~= generation then
				return
			end
			local stats = Rules.characterStats(instance)
			local accent = Theme.hex(stats.color)
			local tier = 1
			for rank, rarity in Config.Rarities do
				if rarity.id == stats.rarity then tier = rank end
			end
			local card = Theme.card(scroll, accent)
			card.LayoutOrder = index
			if tier >= 4 then
				Theme.stroke(card, accent, 0.05).Thickness = if tier == 6 then 3 else 2
			end
			if tier == 6 then
				Theme.make("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(97, 238, 255)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(209, 132, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 222, 135)),
					}), Rotation = 30,
				}, card)
			end
			local row = Theme.make("Frame", { Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1 }, card)
			Theme.portrait(row, accent, 66)
			local name = Theme.label(row, stats.name, 20, accent)
			name.Position = UDim2.fromOffset(80, 2)
			name.Size = UDim2.new(1, -80, 0, 32)
			local detail = Theme.label(row, tostring(stats.rarity) .. " · " .. tostring(stats.mutation), 14)
			detail.Position = UDim2.fromOffset(80, 34)
			detail.Size = UDim2.new(1, -80, 0, 28)
			Theme.paragraph(card, "+" .. Theme.number(stats.income) .. " coins/sec   •   " .. Theme.number(stats.attack) .. " power")
			if not (settings.reducedMotion or settings.autoSkip or skip) then
				local scale = Theme.make("UIScale", { Scale = if tier >= 4 then 0.78 else 0.88 }, card)
				TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				if settings.sound then
					local sound = Theme.make("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.12 + tier * 0.025, PlaybackSpeed = 0.85 + tier * 0.1 }, overlay)
					sound:Play()
					Debris:AddItem(sound, 2)
				end
				task.wait(if stats.rarity == "Ascended" then 0.75 else 0.2)
			end
		end
		if self.generation == generation then
			done = true
			continueButton.Text = "Continue collecting"
			status.Text = tostring(#rewards) .. " Mogger" .. (if #rewards == 1 then "" else "s") .. " added to your inventory"
		end
	end)
end

return GachaController
