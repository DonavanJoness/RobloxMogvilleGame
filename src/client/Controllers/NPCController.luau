--!strict
-- NPC dialogue opens existing gameplay menus only. It never grants rewards,
-- changes stats or treats an unavailable template/animation as finished art.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local NPCConfiguration = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NPCConfiguration"))
local Theme = require(script.Parent.Theme)

local NPCController = {}
NPCController.__index = NPCController
local MENUS = { Roll = true, Inventory = true, Team = true, Battle = true, Upgrades = true,
	Quests = true, Shop = true, Pets = true, Settings = true }

function NPCController.new(openMenu: (string) -> ())
	local self = setmetatable({ openMenu = openMenu, generation = 0 }, NPCController)
	self.gui = Theme.make("ScreenGui", {
		Name = "MogvilleNPCDialogue", ResetOnSpawn = false, IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 30,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
	self.connection = ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("Action") == "NPCDialogue" then
			self:show(prompt:GetAttribute("NPCId"), prompt.Parent)
		end
	end)
	return self
end

function NPCController:close()
	self.generation += 1
	self.gui:ClearAllChildren()
end

function NPCController:show(id: any, anchor: Instance?)
	if type(id) ~= "string" then return end
	local definition = NPCConfiguration.Characters[id]
	if not definition then return end
	self:close()
	local overlay = Theme.make("Frame", {
		Name = "DialogueOverlay", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.colors.background, BackgroundTransparency = 0.25, Active = true,
	}, self.gui)
	local panel = Theme.make("Frame", {
		Name = "DialoguePanel", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.92, 0.85),
		BackgroundColor3 = Theme.colors.panel, BorderSizePixel = 0,
	}, overlay)
	Theme.make("UISizeConstraint", { MaxSize = Vector2.new(620, 690) }, panel)
	Theme.corner(panel, 18)
	local accent = Theme.hex(definition.accent)
	Theme.stroke(panel, accent, 0.12).Thickness = 2
	local heading = Theme.label(panel, definition.name, 25, accent)
	heading.Size = UDim2.new(1, -78, 0, 38)
	heading.Position = UDim2.fromOffset(18, 12)
	heading.Font = Enum.Font.GothamBlack
	local role = Theme.label(panel, definition.role, 14)
	role.Position = UDim2.fromOffset(18, 49)
	role.Size = UDim2.new(1, -36, 0, 24)
	local close = Theme.button(panel, "×", function() self:close() end, Theme.colors.card)
	close.Position = UDim2.new(1, -57, 0, 12)
	close.Size = UDim2.fromOffset(44, 44)
	local scroll = Theme.make("ScrollingFrame", {
		Name = "DialogueContent", Position = UDim2.fromOffset(18, 84), Size = UDim2.new(1, -36, 1, -100),
		BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4,
		ScrollBarImageColor3 = accent,
	}, panel)
	Theme.padding(scroll, 3)
	Theme.list(scroll, 13)
	local card = Theme.card(scroll, accent)
	Theme.paragraph(card, definition.dialogue, Theme.colors.text)
	local model = anchor and anchor:FindFirstAncestorOfClass("Model")
	local available = model and model:GetAttribute("AppearanceStatus") == "ApprovedTemplate"
	if not available then
		Theme.paragraph(card, "Character artwork is not imported yet. This role kiosk keeps the real menu interactions usable; it is not the finished NPC model.", Theme.colors.gold)
	elseif model:GetAttribute("AnimationsReady") ~= true then
		Theme.paragraph(card, "This approved character template is present; its custom animation assets are still pending.", Theme.colors.gold)
	end
	for _, action in definition.actions do
		if MENUS[action.menu] then
			Theme.button(scroll, action.label, function()
				self:close()
				self.openMenu(action.menu)
			end, accent)
		end
	end
	Theme.button(scroll, "Continue exploring", function() self:close() end, Theme.colors.card)
end

function NPCController:destroy()
	if self.connection then self.connection:Disconnect(); self.connection = nil end
	self.gui:Destroy()
end

return NPCController
