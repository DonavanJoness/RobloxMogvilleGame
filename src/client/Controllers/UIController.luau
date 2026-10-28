-- UI is generated locally; all ownership, prices, rewards and combat are validated by the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Rules = require(ReplicatedStorage.Shared.Rules)
local Theme = require(script.Parent.Theme)
local GachaController = require(script.Parent.GachaController)

local UIController = {}
UIController.__index = UIController

local function contains(list, value)
	return table.find(list or {}, value) ~= nil
end

local function rarityColor(rarity)
	for _, definition in Config.Rarities do
		if definition.id == rarity then
			return Theme.hex(definition.color)
		end
	end
	return Theme.colors.purple
end

local function rarityIndex(rarity)
	for i, definition in Config.Rarities do
		if definition.id == rarity then return i end
	end
	return 0
end

local function empty(parent, text)
	local card = Theme.card(parent)
	Theme.paragraph(card, text)
end

local function rowButtons(parent, definitions)
	local row = Theme.make("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, parent)
	local count = #definitions
	for i, definition in definitions do
		local button = Theme.button(row, definition[1], definition[2], definition[3])
		button.Size = UDim2.new(1 / count, -((count - 1) * 6 / count), 1, 0)
		button.Position = UDim2.new((i - 1) / count, (i - 1) * 6 / count, 0, 0)
	end
	return row
end

function UIController.new(request)
	local self = setmetatable({ request = request, state = nil, menu = "Home", pending = false, search = "", sort = "Rarity", signature = "", toastVersion = 0 }, UIController)
	self.gui = Theme.make("ScreenGui", {
		Name = "MogvilleUI", ResetOnSpawn = false, IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
	self.gacha = GachaController.new(self.gui)
	self:build()
	return self
end

function UIController:build()
	local hud = Theme.make("Frame", {
		Name = "HUD", Size = UDim2.new(1, 0, 0, 114), BackgroundColor3 = Theme.colors.background,
		BackgroundTransparency = 0.08, BorderSizePixel = 0,
	}, self.gui)
	self.hud = hud
	Theme.stroke(hud, Theme.colors.purple)
	local title = Theme.label(hud, string.upper(Config.Game.Title), 18, Theme.colors.gold)
	title.Position = UDim2.new(0.04, 0, 0, 6)
	title.Size = UDim2.new(0.92, 0, 0, 26)
	title.Font = Enum.Font.GothamBlack
	self.title = title
	self.subtitle = Theme.label(hud, "Loading your collection…", 12)
	self.subtitle.Position = UDim2.new(0.04, 0, 0, 34)
	self.subtitle.Size = UDim2.new(0.92, 0, 0, 20)
	self.statLabels = {}
	self.statCaptions = {}
	self.statFrames = {}
	for index, heading in { "COINS", "PER SECOND", "LUCK" } do
		local stat = Theme.make("Frame", {
			Position = UDim2.new(0.04 + (index - 1) * 0.31, 0, 0, 60),
			Size = UDim2.new(0.3, 0, 0, 46), BackgroundColor3 = Theme.colors.panel, BorderSizePixel = 0,
		}, hud)
		Theme.corner(stat, 10)
		local value = Theme.label(stat, "—", 18, if index == 1 then Theme.colors.gold else Theme.colors.cyan)
		value.Size = UDim2.new(1, -12, 0, 26)
		value.Position = UDim2.fromOffset(8, 1)
		value.Font = Enum.Font.GothamBold
		local caption = Theme.label(stat, heading, 10, Theme.colors.muted)
		caption.Size = UDim2.new(1, -12, 0, 16)
		caption.Position = UDim2.fromOffset(8, 26)
		self.statLabels[index] = value
		self.statCaptions[index] = caption
		self.statFrames[index] = stat
	end
	local nav = Theme.make("ScrollingFrame", {
		Name = "Navigation", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = Theme.colors.background, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.colors.purple,
	}, self.gui)
	Theme.padding(nav, 8)
	Theme.list(nav, 8, true)
	for index, menu in { "Roll", "Inventory", "Team", "Battle", "Pets", "Upgrades", "Quests", "Shop", "Settings", "Home" } do
		local button = Theme.button(nav, menu, function() self:show(menu) end, if menu == "Roll" then Theme.colors.gold else Theme.colors.cyan)
		button.Size = UDim2.fromOffset(if menu == "Inventory" or menu == "Upgrades" then 100 else 82, 46)
		button.LayoutOrder = index
	end
	self.panel = Theme.make("Frame", {
		Name = "Menu", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 126),
		Size = UDim2.new(0.94, 0, 1, -204), BackgroundColor3 = Theme.colors.panel,
		BorderSizePixel = 0, ClipsDescendants = true,
	}, self.gui)
	Theme.make("UISizeConstraint", { MaxSize = Vector2.new(900, 900) }, self.panel)
	Theme.corner(self.panel, 16)
	Theme.stroke(self.panel)
	self.heading = Theme.label(self.panel, "WELCOME TO MOGVILLE", 22, Theme.colors.text)
	self.heading.Position = UDim2.fromOffset(16, 10)
	self.heading.Size = UDim2.new(1, -80, 0, 42)
	self.heading.Font = Enum.Font.GothamBlack
	local close = Theme.button(self.panel, "×", function() self.panel.Visible = false end, Theme.colors.card)
	close.TextColor3 = Theme.colors.text
	close.Size = UDim2.fromOffset(44, 44)
	close.Position = UDim2.new(1, -54, 0, 8)
	self.toolbar = Theme.make("Frame", { Name = "Toolbar", Position = UDim2.fromOffset(14, 60), Size = UDim2.new(1, -28, 0, 48), BackgroundTransparency = 1, Visible = false }, self.panel)
	self.body = Theme.make("ScrollingFrame", {
		Name = "Content", Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 1, -76),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.colors.purple,
	}, self.panel)
	Theme.padding(self.body, 3)
	Theme.list(self.body, 12)
	self.toastLabel = Theme.make("TextLabel", {
		Name = "Notice", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -78),
		Size = UDim2.new(0.9, 0, 0, 60), BackgroundColor3 = Theme.colors.background,
		TextColor3 = Theme.colors.text, TextSize = 16, Font = Enum.Font.GothamBold,
		TextWrapped = true, Visible = false, ZIndex = 15,
	}, self.gui)
	Theme.corner(self.toastLabel)
	Theme.stroke(self.toastLabel, Theme.colors.cyan, 0.15)
	Theme.padding(self.toastLabel, 10)
	self.gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:layout() end)
	self:layout()
	self:render()
end

function UIController:layout()
	-- A shorter HUD leaves more scrolling room on phones rotated into landscape.
	local compact = self.gui.AbsoluteSize.Y < 480
	local panelTop = if compact then 88 else 126
	self.hud.Size = UDim2.new(1, 0, 0, if compact then 80 else 114)
	self.subtitle.Visible = not compact
	self.title.TextSize = if compact then 16 else 18
	self.title.Position = UDim2.new(0.04, 0, 0, if compact then 2 else 6)
	for index, frame in self.statFrames do
		frame.Position = UDim2.new(0.04 + (index - 1) * 0.31, 0, 0, if compact then 28 else 60)
	end
	self.panel.Position = UDim2.new(0.5, 0, 0, panelTop)
	self.panel.Size = UDim2.new(0.94, 0, 1, -(panelTop + 78))
end

function UIController:toast(message, isError)
	self.toastVersion += 1
	local version = self.toastVersion
	self.toastLabel.Text = tostring(message)
	self.toastLabel.TextColor3 = if isError then Theme.colors.red else Theme.colors.text
	self.toastLabel.Visible = true
	task.delay(4, function()
		if self.toastVersion == version then self.toastLabel.Visible = false end
	end)
end

function UIController:act(action, payload)
	if self.pending then
		self:toast("One moment — your previous action is still processing.")
		return
	end
	self.pending = true
	task.spawn(function()
		local success, result = pcall(self.request, action, payload or {})
		self.pending = false
		if not success or type(result) ~= "table" then
			self:toast("Connection interrupted. Please try again.", true)
			return
		end
		if result.state then self:update(result.state) end
		if not result.ok then
			self:toast(result.error or "That action is unavailable.", true)
			return
		end
		if result.message then self:toast(result.message) end
		if result.rewards and #result.rewards > 0 then
			self.gacha:show(result.rewards, if self.state then self.state.profile.settings else {})
		end
	end)
end

function UIController:show(menu)
	self.menu = menu
	self.panel.Visible = true
	self.signature = ""
	self.heading.Text = string.upper(if menu == "Roll" then "THE SPOTLIGHT" else menu)
	self.toolbar:ClearAllChildren()
	local inventory = menu == "Inventory" or menu == "Team"
	self.toolbar.Visible = inventory
	self.body.Position = UDim2.fromOffset(14, if inventory then 116 else 62)
	self.body.Size = UDim2.new(1, -28, 1, if inventory then -130 else -76)
	if inventory then
		local search = Theme.make("TextBox", {
			Size = UDim2.new(0.64, -4, 1, 0), BackgroundColor3 = Theme.colors.card,
			BorderSizePixel = 0, PlaceholderText = "Search Moggers…", Text = self.search,
			TextColor3 = Theme.colors.text, PlaceholderColor3 = Theme.colors.muted,
			TextSize = 15, Font = Enum.Font.Gotham, ClearTextOnFocus = false,
		}, self.toolbar)
		Theme.corner(search, 10)
		Theme.padding(search, 8)
		search:GetPropertyChangedSignal("Text"):Connect(function()
			self.search = search.Text
			self:render()
		end)
		local sortButton
		sortButton = Theme.button(self.toolbar, self.sort .. " ↓", function()
			local options = { "Rarity", "Income", "Power" }
			self.sort = options[(table.find(options, self.sort) or 1) % #options + 1]
			sortButton.Text = self.sort .. " ↓"
			self:render()
		end, Theme.colors.cyan)
		sortButton.Position = UDim2.new(0.64, 4, 0, 0)
		sortButton.Size = UDim2.new(0.36, -4, 1, 0)
	end
	self.body.CanvasPosition = Vector2.zero
	self:render()
	-- Refresh server-derived goals/odds when opening a panel after idle income.
	if self.state and not self.pending then self:act("GetState") end
end

function UIController:updateHUD()
	local state = self.state
	if not state then return end
	self.statLabels[1].Text = Theme.number(state.profile.coins)
	self.statLabels[2].Text = "+" .. Theme.number(state.income)
	self.statLabels[3].Text = string.format("%.2fx", state.luck or 1)
	local profile = state.profile
	local rank = state.rank
	local rankName = if type(rank) == "table" then rank.name else tostring(rank or "Beginner")
	self.subtitle.Text = string.format("%s  •  Displays %d/%d  •  Pity %d/20 · %d/100", rankName, #(profile.placed or {}), math.min(Config.Game.MaxSlots, Config.Game.BaseSlots + (profile.upgrades.slots or 0)), profile.pity.rare, profile.pity.mythic)
	self:updateBoostDisplay()
end

function UIController:updateBoostDisplay()
	if not self.state then return end
	local boost = self.state.serverLuck or {}
	local remaining = math.max(0, math.ceil((boost.expiresAt or 0) - workspace:GetServerTimeNow()))
	local active = remaining > 0 and (boost.bonus or 0) > 0
	local countdown = string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60)
	self.statCaptions[3].Text = if active then "BOOST " .. countdown else "LUCK"
	self.statCaptions[3].TextColor3 = if active then Theme.colors.gold else Theme.colors.muted
	if self.serverLuckLabel and self.serverLuckLabel.Parent then
		self.serverLuckLabel.Text = if active then "Server luck +" .. string.format("%.0f%%", boost.bonus * 100) .. " · " .. countdown .. " remaining" else "No server luck event is active."
	end
end

function UIController:update(state)
	if type(state) ~= "table" or type(state.profile) ~= "table" then return end
	self.state = state
	self:updateHUD()
	if self.panel.Visible then
		local signature = HttpService:JSONEncode({ self.menu, state.profile.characters, state.profile.placed, state.profile.team, state.profile.pets, state.profile.equippedPets, state.profile.upgrades, state.profile.settings, state.profile.ascension, state.profile.pity, state.odds, state.battle, state.quests })
		if signature ~= self.signature then
			self.signature = signature
			self:render()
		end
	end
end

function UIController:updateEconomy(delta)
	if not self.state or type(delta) ~= "table" then return end
	for _, key in { "coins", "pity", "stats" } do
		if delta[key] ~= nil then self.state.profile[key] = delta[key] end
	end
	for _, key in { "income", "luck", "serverLuck" } do
		if delta[key] ~= nil then self.state[key] = delta[key] end
	end
	self:updateHUD()
	if delta.quests then
		local changed = HttpService:JSONEncode(delta.quests) ~= HttpService:JSONEncode(self.state.quests or {})
		self.state.quests = delta.quests
		if changed and self.panel.Visible and self.menu == "Quests" then self:render() end
	end
end

function UIController:render()
	for _, child in self.body:GetChildren() do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	if not self.state then
		empty(self.body, "Connecting to Mogville… Your progress loads before gameplay begins.")
		return
	end
	local render = self["render" .. self.menu]
	if render then render(self) else self:renderHome() end
end

function UIController:renderHome()
	local card = Theme.card(self.body, Theme.colors.gold)
	Theme.label(card, "YOUR GLOW-UP STARTS HERE", 20, Theme.colors.gold)
	Theme.paragraph(card, "Your first Common Mogger is waiting in Inventory. Display it on your plot to start earning coins, then roll for your next star.")
	Theme.button(card, "1 · Place your starter", function() self:show("Inventory") end, Theme.colors.cyan)
	Theme.button(card, "2 · Roll a new Mogger", function() self:show("Roll") end, Theme.colors.gold)
	Theme.button(card, "3 · Build a battle team", function() self:show("Team") end)
	local guide = Theme.card(self.body)
	Theme.label(guide, "A LITTLE LUCK. A LOT OF STYLE.", 17)
	Theme.paragraph(guide, "Displayed characters earn coins while you play. Battle teams are separate: your favorite Mogger can earn income and fight. Pets, upgrades, quests and ascension grow your collection without Robux.")
	Theme.paragraph(guide, "Close this panel to explore Starter Square. Walk up to the glowing stations or use the navigation bar. Swipe the bar sideways on a phone.")
	Theme.paragraph(guide, "Higher rarity and mutation improve fictional character stats. These are never ratings of real players.")
	if self.state.persistenceMode and string.find(string.lower(self.state.persistenceMode), "memory", 1, true) then
		Theme.paragraph(guide, "Save mode: " .. tostring(self.state.persistenceMode) .. ". Studio memory sessions are temporary; use the documented isolated DataStore test mode to verify rejoining.", Theme.colors.gold)
	end
end

function UIController:renderRoll()
	local state = self.state
	local banner = Theme.card(self.body, Theme.colors.gold)
	Theme.label(banner, "STARTER SQUARE · ALL-STARS", 20, Theme.colors.gold)
	Theme.paragraph(banner, "Original Moggers. Six rarities. One next step toward Ascension.")
	rowButtons(banner, {
		{ "Roll · " .. Theme.number(Config.Game.RollCost), function() self:act("Roll", { count = 1 }) end, Theme.colors.gold },
		{ "10× · " .. Theme.number(Config.Game.RollCost * 10), function() self:act("Roll", { count = 10 }) end, Theme.colors.cyan },
	})
	Theme.paragraph(banner, "Gameplay coins only. A 10× roll costs ten single rolls; pity and odds update after each result. All rewards are selected on the server.")
	local odds = Theme.card(self.body, Theme.colors.cyan)
	Theme.label(odds, "YOUR NEXT ROLL · EXACT ODDS", 18, Theme.colors.cyan)
	local totals = {}
	for _, outcome in state.odds or {} do totals[outcome.rarity] = (totals[outcome.rarity] or 0) + outcome.probability end
	for _, rarity in Config.Rarities do
		Theme.label(odds, string.format("%s   %.6f%%", rarity.name or rarity.id, (totals[rarity.id] or 0) * 100), 16, Theme.hex(rarity.color))
	end
	Theme.paragraph(odds, string.format("Luck %.2fx · Rare+ guarantee: %d/20 · Mythic+ guarantee: %d/100", state.luck or 1, state.profile.pity.rare, state.profile.pity.mythic))
	Theme.paragraph(odds, "+50% Luck means a 1.5× luck factor: each successive rarity gets a stronger weight before all probabilities are normalized. Pity filters your next eligible outcomes. Percentages shown are rounded.")
	Theme.button(odds, "View every character + mutation outcome", function() self:show("Odds") end)
	self.serverLuckLabel = Theme.paragraph(odds, "", Theme.colors.green)
	self:updateBoostDisplay()
end

function UIController:renderOdds()
	local intro = Theme.card(self.body, Theme.colors.cyan)
	Theme.label(intro, "INDIVIDUAL OUTCOME DISCLOSURE", 18, Theme.colors.cyan)
	Theme.paragraph(intro, "Each percentage combines character and mutation probability for your very next roll. The server recalculates after every pull; 10× rolls may have different odds on later pulls. Values are rounded to six decimal places.")
	Theme.button(intro, "Back to the Spotlight", function() self:show("Roll") end, Theme.colors.gold)
	local outcomes = table.clone(self.state.odds or {})
	table.sort(outcomes, function(a, b)
		if a.rarity ~= b.rarity then return rarityIndex(a.rarity) > rarityIndex(b.rarity) end
		if a.characterId ~= b.characterId then return a.characterId < b.characterId end
		return a.probability > b.probability
	end)
	for _, outcome in outcomes do
		local definition = Config.Characters[outcome.characterId]
		local card = Theme.card(self.body, rarityColor(outcome.rarity))
		Theme.paragraph(card, string.format("%s · %s · %s\n%.6f%%", if definition then definition.name else outcome.characterId, outcome.rarity, outcome.mutation, outcome.probability * 100), Theme.colors.text)
	end
end

function UIController:inventoryCards(teamMode)
	local profile = self.state.profile
	local header = Theme.card(self.body, Theme.colors.cyan)
	Theme.label(header, if teamMode then "MOG-OFF LINEUP · " .. tostring(#profile.team) .. "/3" else "YOUR COLLECTION · " .. tostring(#profile.characters), 18, Theme.colors.cyan)
	Theme.paragraph(header, if teamMode then "Tap Add to team on up to three characters. Reserves can switch in during a Mog-Off. Display assignments stay independent." else "Display Moggers to earn coins. Sort, search or inspect the stats below. Duplicate characters have their own unique ownership IDs.")
	local characters = table.clone(profile.characters)
	table.sort(characters, function(a, b)
		local sa, sb = Rules.characterStats(a), Rules.characterStats(b)
		local va = if self.sort == "Income" then sa.income elseif self.sort == "Power" then sa.attack else rarityIndex(sa.rarity)
		local vb = if self.sort == "Income" then sb.income elseif self.sort == "Power" then sb.attack else rarityIndex(sb.rarity)
		return if va == vb then a.uid < b.uid else va > vb
	end)
	local found = 0
	for _, instance in characters do
		local stats = Rules.characterStats(instance)
		if not string.find(string.lower(stats.name), string.lower(self.search), 1, true) then continue end
		found += 1
		local accent = rarityColor(stats.rarity)
		local card = Theme.card(self.body, accent)
		local row = Theme.make("Frame", { Size = UDim2.new(1, 0, 0, 68), BackgroundTransparency = 1 }, card)
		Theme.portrait(row, Theme.hex(stats.color), 60)
		local name = Theme.label(row, stats.name, 18, accent)
		name.Position = UDim2.fromOffset(72, 0)
		name.Size = UDim2.new(1, -72, 0, 36)
		local detail = Theme.label(row, tostring(stats.rarity) .. " · " .. tostring(stats.mutation), 13)
		detail.Position = UDim2.fromOffset(72, 36)
		detail.Size = UDim2.new(1, -72, 0, 28)
		Theme.paragraph(card, string.format("%s coins/sec  •  %s power\nHP %s · Defense %s · Speed %s\nAbility: %s", Theme.number(stats.income), Theme.number(stats.attack), Theme.number(stats.health), Theme.number(stats.defense), Theme.number(stats.speed), tostring(stats.ability)))
		local displayed = contains(profile.placed, instance.uid)
		local teamed = contains(profile.team, instance.uid)
		if teamMode then
			Theme.button(card, if teamed then "Remove from team" else "Add to team", function()
				local uids = table.clone(self.state.profile.team)
				local index = table.find(uids, instance.uid)
				if index then table.remove(uids, index) else table.insert(uids, instance.uid) end
				self:act("SetTeam", { uids = uids })
			end, if teamed then Theme.colors.card else Theme.colors.cyan)
		else
			Theme.button(card, if displayed then "Remove from display" else "Display on my plot", function()
				self:act(if displayed then "Unequip" else "Equip", { uid = instance.uid })
			end, if displayed then Theme.colors.gold else Theme.colors.cyan)
		end
		Theme.paragraph(card, (if displayed then "● Earning on your plot   " else "") .. (if teamed then "● Battle team" else ""), Theme.colors.green)
	end
	if found == 0 then empty(self.body, "No Moggers match that search.") end
end

function UIController:renderInventory() self:inventoryCards(false) end
function UIController:renderTeam() self:inventoryCards(true) end

function UIController:renderUpgrades()
	local profile = self.state.profile
	local entries = {
		{ "slots", "BIGGER SPOTLIGHT", "Display one more Mogger for passive income.", Config.Game.BaseSlots + profile.upgrades.slots },
		{ "luck", "LUCK TRAINING", "Improve your luck factor through earned progression.", profile.upgrades.luck },
		{ "petSlots", "MORE LITTLE LEGENDS", "Equip one additional pet, up to three.", 1 + profile.upgrades.petSlots },
	}
	for _, entry in entries do
		local card = Theme.card(self.body, Theme.colors.gold)
		Theme.label(card, entry[2], 18, Theme.colors.gold)
		Theme.paragraph(card, entry[3] .. " Current: " .. tostring(entry[4]))
		local cost = (self.state.upgradeCosts or {})[entry[1]]
		if type(cost) == "number" and cost > 0 then
			Theme.button(card, "Upgrade · " .. Theme.number(cost) .. " coins", function() self:act("Upgrade", { kind = entry[1] }) end, Theme.colors.cyan)
		else Theme.paragraph(card, "Maximum level reached", Theme.colors.green) end
	end
	local rank = Theme.card(self.body, Theme.colors.purple)
	Theme.label(rank, "THE ROAD TO ASCENSION", 19, Theme.colors.gold)
	local current = self.state.rank or {}
	Theme.paragraph(rank, "Current title: " .. tostring(current.name or "Beginner"))
	if current.next then
		local nextRank = current.next
		if type(nextRank) == "table" then
			Theme.paragraph(rank, "Next: " .. tostring(nextRank.name or "New rank"))
			Theme.paragraph(rank, string.format("Requires %s coins/sec, %s unique Moggers, %s PvE wins and %s coins.", Theme.number(nextRank.income), Theme.number(nextRank.unique), Theme.number(nextRank.wins), Theme.number(nextRank.cost)))
		else Theme.paragraph(rank, "Next: " .. tostring(nextRank)) end
	end
	Theme.paragraph(rank, "Ascension is earned progression. Check eligibility without spending Robux.")
	Theme.button(rank, "Ascend when eligible", function() self:act("Ascend") end)
end

function UIController:renderPets()
	local profile = self.state.profile
	local header = Theme.card(self.body, Theme.colors.cyan)
	Theme.label(header, "SMALL FRIENDS. BIG ENERGY.", 19, Theme.colors.cyan)
	Theme.paragraph(header, "Equipped pets add their bonuses together. Earn extra equip slots through upgrades; no unlimited multiplying. Current equipped: " .. tostring(#profile.equippedPets) .. "/" .. tostring(1 + profile.upgrades.petSlots))
	for _, instance in profile.pets do
		local definition = Config.Pets[instance.petId]
		if not definition then continue end
		local card = Theme.card(self.body, Theme.hex(definition.color))
		Theme.label(card, definition.name, 19)
		Theme.paragraph(card, string.format("Income +%.0f%% · Luck +%.0f%% · Battle +%.0f%%", (definition.incomeBonus or 0) * 100, (definition.luckBonus or 0) * 100, (definition.powerBonus or 0) * 100))
		local equipped = contains(profile.equippedPets, instance.uid)
		Theme.button(card, if equipped then "Unequip pet" else "Equip pet", function() self:act(if equipped then "UnequipPet" else "EquipPet", { uid = instance.uid }) end, if equipped then Theme.colors.gold else Theme.colors.cyan)
	end
	local ids = {}
	for id in Config.Pets do table.insert(ids, id) end
	table.sort(ids, function(a, b) return Config.Pets[a].cost < Config.Pets[b].cost end)
	for _, id in ids do
		local pet = Config.Pets[id]
		local card = Theme.card(self.body, Theme.hex(pet.color))
		Theme.label(card, pet.name .. " · Guaranteed", 18)
		Theme.paragraph(card, string.format("Income +%.0f%% · Luck +%.0f%% · Battle +%.0f%%", (pet.incomeBonus or 0) * 100, (pet.luckBonus or 0) * 100, (pet.powerBonus or 0) * 100))
		Theme.button(card, "Adopt · " .. Theme.number(pet.cost) .. " coins", function() self:act("BuyPet", { petId = id }) end, Theme.colors.cyan)
	end
end

function UIController:renderQuests()
	local quests = self.state.quests or {}
	if #quests == 0 then empty(self.body, "Your goals are loading. Keep collecting, displaying and battling.") end
	for _, quest in quests do
		local card = Theme.card(self.body, if quest.claimed then Theme.colors.green else Theme.colors.gold)
		Theme.label(card, quest.title, 18)
		Theme.paragraph(card, string.format("%s / %s · Reward %s coins", Theme.number(math.min(quest.progress, quest.target)), Theme.number(quest.target), Theme.number(quest.reward)))
		local bar = Theme.make("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = Theme.colors.background, BorderSizePixel = 0 }, card)
		Theme.corner(bar, 5)
		local fill = Theme.make("Frame", { Size = UDim2.new(math.clamp(quest.progress / math.max(1, quest.target), 0, 1), 0, 1, 0), BackgroundColor3 = Theme.colors.cyan, BorderSizePixel = 0 }, bar)
		Theme.corner(fill, 5)
		if quest.claimed then Theme.paragraph(card, "Claimed — nice work!", Theme.colors.green)
		else Theme.button(card, if quest.progress >= quest.target then "Claim reward" else "Check progress", function() self:act("ClaimQuest", { id = quest.id }) end, Theme.colors.gold) end
	end
end

local function combatSide(parent, side, heading, color)
	local card = Theme.card(parent, color)
	Theme.label(card, heading, 16, color)
	local unit = side and side.units and side.units[side.active]
	if not unit then Theme.paragraph(card, "No active Mogger"); return end
	Theme.label(card, unit.name, 21)
	Theme.paragraph(card, string.format("HP %.0f / %.0f  ·  Power %.0f\nDefense %.0f · Speed %.0f", unit.hp, unit.maxHp, unit.attack, unit.defense, unit.speed))
	local bar = Theme.make("Frame", { Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = Theme.colors.background, BorderSizePixel = 0 }, card)
	Theme.corner(bar, 5)
	local fill = Theme.make("Frame", { Size = UDim2.new(math.clamp(unit.hp / math.max(1, unit.maxHp), 0, 1), 0, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0 }, bar)
	Theme.corner(fill, 5)
end

function UIController:renderBattle()
	local battle = self.state.battle
	if not battle then
		local card = Theme.card(self.body, Theme.colors.gold)
		Theme.label(card, "MOG-OFF · STARTER ARENA", 20, Theme.colors.gold)
		Theme.paragraph(card, "Choose a team of up to three Moggers, then challenge an NPC. Speed sets action order. Defend to soften a hit, use specials, or switch to a reserve. Losing never removes your characters.")
		Theme.button(card, "Choose my team", function() self:show("Team") end, Theme.colors.cyan)
		for difficulty, name in { "Rookie · Difficulty 1", "Challenger · Difficulty 2", "Champion · Difficulty 3" } do
			Theme.button(card, name, function() self:act("StartBattle", { difficulty = difficulty }) end, if difficulty == 1 then Theme.colors.gold else Theme.colors.purple)
		end
		Theme.paragraph(card, "PvE is available in this build. Consent-based PvP is planned for a later phase.")
		return
	end
	local title = Theme.card(self.body, Theme.colors.gold)
	Theme.label(title, if battle.finished then "MOG-OFF RESULTS" else "MOG-OFF · TURN " .. tostring(battle.turn), 20, Theme.colors.gold)
	if battle.message then Theme.paragraph(title, battle.message) end
	if battle.finished then
		Theme.paragraph(title, "Result: " .. tostring(battle.winner or "Finished"), Theme.colors.cyan)
		if battle.winner == "player" and battle.rewardGranted and battle.reward then
			Theme.paragraph(title, "Earned: " .. Theme.number(if type(battle.reward) == "table" then battle.reward.coins else battle.reward) .. " coins")
		else
			Theme.paragraph(title, "No coins awarded for this result.")
		end
	end
	combatSide(self.body, battle.player, "YOUR ACTIVE MOGGER", Theme.colors.cyan)
	combatSide(self.body, battle.enemy, "NPC OPPONENT", Theme.colors.red)
	if not battle.finished then
		local actions = Theme.card(self.body)
		rowButtons(actions, {
			{ "Attack", function() self:act("BattleAction", { kind = "attack" }) end, Theme.colors.cyan },
			{ "Defend", function() self:act("BattleAction", { kind = "defend" }) end, Theme.colors.gold },
		})
		local active = battle.player and battle.player.units[battle.player.active]
		Theme.button(actions, "Special" .. (if active and (active.specialCooldown or 0) > 0 then " · cooldown " .. tostring(active.specialCooldown) else " · ready"), function() self:act("BattleAction", { kind = "special" }) end)
		for index, unit in battle.player.units do
			if index ~= battle.player.active and unit.hp > 0 then
				Theme.button(actions, "Switch → " .. unit.name, function() self:act("BattleAction", { kind = "switch", index = index }) end, Theme.colors.cyan)
			end
		end
	end
	local log = Theme.card(self.body)
	Theme.label(log, "ARENA LOG", 16, Theme.colors.muted)
	for i = math.max(1, #(battle.log or {}) - 7), #(battle.log or {}) do
		Theme.paragraph(log, battle.log[i])
	end
	Theme.button(log, if battle.finished then "Return to arena" else "Forfeit Mog-Off", function() self:act("LeaveBattle") end, Theme.colors.card)
end

function UIController:renderShop()
	local card = Theme.card(self.body, Theme.colors.gold)
	Theme.label(card, "THE STYLE EXCHANGE", 20, Theme.colors.gold)
	Theme.paragraph(card, "All core progression is free. Gacha coins are earned through gameplay and cannot be bought with Robux.")
	Theme.button(card, "Guaranteed pets · Gameplay coins", function() self:show("Pets") end, Theme.colors.cyan)
	Theme.button(card, "Plot & luck upgrades · Gameplay coins", function() self:show("Upgrades") end)
	for _, entry in {
		{ "VIP", "VIP cosmetics and eligible benefits are planned. Paid luck is disabled." },
		{ "BOOSTS", "Paid server boosts are disabled. Any future random-reward modifiers require eligibility checks and updated odds." },
		{ "COSMETICS", "Original name tags, trails and plot decorations are planned." },
		{ "OTHER", "Auto-skip pass is not for sale. Manual skip and reduced motion are free." },
	} do
		local item = Theme.card(self.body)
		Theme.label(item, entry[1] .. " · NOT FOR SALE", 17, Theme.colors.muted)
		Theme.paragraph(item, entry[2])
	end
	Theme.paragraph(card, self.state.policy or "No Robux products are configured in this build.")
end

function UIController:renderSettings()
	local profile = self.state.profile
	local card = Theme.card(self.body, Theme.colors.cyan)
	Theme.label(card, "MAKE YOURSELF COMFORTABLE", 19, Theme.colors.cyan)
	for _, setting in {
		{ "reducedMotion", "Reduced motion", "Reveals show immediately without scaling animations." },
		{ "sound", "Reveal sounds", "Toggle the short built-in reveal sound." },
		{ "autoSkip", "Quick reveals", "Show all results immediately. This free preference never changes your rewards or server cooldown." },
	} do
		Theme.paragraph(card, setting[3])
		Theme.button(card, setting[2] .. ": " .. (if profile.settings[setting[1]] then "ON" else "OFF"), function()
			self:act("Settings", { [setting[1]] = not self.state.profile.settings[setting[1]] })
		end, if profile.settings[setting[1]] then Theme.colors.cyan else Theme.colors.purple)
	end
	local info = Theme.card(self.body)
	Theme.label(info, "YOUR PROGRESS", 18)
	Theme.paragraph(info, "Save mode: " .. tostring(self.state.persistenceMode or "loading") .. ". Server-managed autosaves protect live progress. Studio memory sessions are temporary; use isolated DataStore testing to check rejoining.")
	Theme.paragraph(info, "Offline earnings are capped. Mogville does not bypass Roblox idle-session behavior.")
end

return UIController
