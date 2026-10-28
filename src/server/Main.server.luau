--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)
local Rules = require(ReplicatedStorage.Shared.Rules)
local Services = script.Parent.Services
local Data = require(Services.PlayerDataService).new()
local Characters = require(Services.CharacterService).new(Data)
local Economy = require(Services.EconomyService).new(Data)
local Progression = require(Services.ProgressionService).new(Data)
local Battle = require(Services.BattleService).new(Data)
local Social = require(Services.SocialBonusService).new()
local Gacha = require(Services.GachaService).new(Data, Social)
local World = require(Services.WorldService).new()
local Shop = require(Services.ShopService).new()
local Boards = require(Services.LeaderboardService)
local GuardModule = require(Services.NetworkGuard)
local Guard = GuardModule.new()

World:build()
local network = Instance.new("Folder")
network.Name = "Network"
network.Parent = ReplicatedStorage
local function remote(class, name)
	local instance = Instance.new(class)
	instance.Name = name
	instance.Parent = network
	return instance
end
local Request = remote("RemoteFunction", "Request")
local State = remote("RemoteEvent", "State")
local Notice = remote("RemoteEvent", "Notice")
local EconomyEvent = remote("RemoteEvent", "Economy")
local lastLuck = {}

local function snapshot(player)
	local profile = Data:get(player)
	if not profile then return nil end
	local boost = Social:getServerLuck()
	lastLuck[player] = Rules.luck(profile, Social:get(player), boost.bonus)
	return {
		profile = profile, income = Rules.income(profile),
		luck = Rules.luck(profile, Social:get(player), boost.bonus),
		odds = Rules.odds(profile, Social:get(player), boost.bonus),
		friends = Social:get(player), serverLuck = boost,
		upgradeCosts = Economy:upgradeCosts(profile), battle = Battle:get(player),
		quests = Progression:quests(profile), rank = Progression:rank(profile),
		persistenceMode = Data.mode,
		policy = "Coins are earned through gameplay. Paid luck and paid random rewards are disabled.",
	}
end

local function publish(player, render)
	local profile = Data:get(player)
	if not profile or player.Parent ~= Players then return end
	if render then World:render(player, profile) end
	Boards.update(player, profile)
	State:FireClient(player, snapshot(player))
end

local handlers = {
	Equip = function(p, d) return Characters:equip(p, d.uid) end,
	Unequip = function(p, d) return Characters:unequip(p, d.uid) end,
	SetTeam = function(p, d) return Characters:setTeam(p, d.uids) end,
	Upgrade = function(p, d) return Economy:upgrade(p, d.kind) end,
	BuyPet = function(p, d) return Progression:buyPet(p, d.petId) end,
	EquipPet = function(p, d) return Progression:equipPet(p, d.uid) end,
	UnequipPet = function(p, d) return Progression:unequipPet(p, d.uid) end,
	ClaimQuest = function(p, d)
		local success, problem = Progression:claimQuest(p, d.id)
		if success and d.id == "first_win" then
			local activated = Social:activateEarnedBoost(p)
			if activated then
				task.defer(function()
					for _, recipient in Players:GetPlayers() do
						Notice:FireClient(recipient, p.DisplayName .. " earned a 10-minute +25% server luck event!")
						publish(recipient, false)
					end
				end)
			end
		end
		return success, problem
	end,
	Ascend = function(p) return Progression:ascend(p) end,
	StartBattle = function(p, d) return Battle:start(p, d.difficulty) end,
	BattleAction = function(p, d) return Battle:act(p, d.kind, d.index) end,
	LeaveBattle = function(p) return Battle:leave(p) end,
	Purchase = function(p, d) return Shop:purchase(p, d.name) end,
	Settings = function(p, d)
		local profile = Data:get(p)
		for _, key in { "reducedMotion", "sound", "autoSkip" } do
			if type(d[key]) == "boolean" then profile.settings[key] = d[key] end
		end
		return true
	end,
}
local needsRender = { Equip = true, Unequip = true, Upgrade = true, BuyPet = true, EquipPet = true, UnequipPet = true, Ascend = true }
local busy = {}
Request.OnServerInvoke = function(player, action, payload)
	if type(action) ~= "string" or #action > 32
		or (not handlers[action] and action ~= "GetState" and action ~= "Roll" and action ~= "ShopCatalog") then
		return { ok = false, error = "Unknown action." }
	end
	if not Guard:allow(player, action) then
		return { ok = false, error = "Please wait a moment before trying again." }
	end
	payload = payload or {}
	if not GuardModule.validPayload(payload) then return { ok = false, error = "Invalid request." } end
	if not Data:get(player) then return { ok = false, error = "Your data is still loading. Please wait." } end
	if busy[player] then return { ok = false, error = "Your previous action is still processing." } end
	busy[player] = true
	local ok, response = xpcall(function()
		if action == "GetState" then return { ok = true, state = snapshot(player) } end
		if action == "ShopCatalog" then return { ok = true, catalog = Shop:catalog() } end
		if action == "Roll" then
			local result = Gacha:roll(player, payload.count)
			if result.ok then result.state = snapshot(player) end
			return result
		end
		local handler = handlers[action]
		if not handler then return { ok = false, error = "Unknown action." } end
		local success, problem = handler(player, payload)
		if not success then return { ok = false, error = problem or "Action unavailable." } end
		publish(player, needsRender[action])
		return { ok = true, state = snapshot(player) }
	end, debug.traceback)
	busy[player] = nil
	if not ok then
		warn("Mogville action failed: " .. tostring(response))
		return { ok = false, error = "That action could not finish. Please try again." }
	end
	return response
end

local function joined(player)
	local ok, err = pcall(function()
		local profile, problem = Data:load(player)
		if not profile then if player.Parent == Players then player:Kick(problem or "Your data could not load safely.") end; return end
		local assigned, plotError = World:assign(player)
		if not assigned then Data:remove(player); player:Kick(plotError or "This server is full. Please try another server."); return end
		publish(player, true)
		if profile.offlineEarned and profile.offlineEarned > 0 then
			Notice:FireClient(player, "Welcome back! Your display earned " .. math.floor(profile.offlineEarned) .. " offline Coins.")
		end
		task.spawn(function() Shop:load(player) end)
		task.spawn(function() Social:refresh(player); publish(player, false) end)
	end)
	if not ok then
		warn("Mogville join failed: " .. tostring(err))
		World:release(player)
		Data:remove(player)
		if player.Parent == Players then player:Kick("The server could not safely start your session. Please rejoin.") end
	end
end

Players.PlayerAdded:Connect(joined)
for _, player in Players:GetPlayers() do task.spawn(joined, player) end
Players.PlayerRemoving:Connect(function(player)
	World:release(player); Battle:remove(player); Social:remove(player); Shop:remove(player); Guard:remove(player)
	busy[player] = nil
	lastLuck[player] = nil
	Data:remove(player)
end)

-- Central income and lightweight HUD updates; inventory is sent only when changed.
local incomeClock, hudClock, boardClock = 0, 0, 0
RunService.Heartbeat:Connect(function(dt)
	incomeClock += dt; hudClock += dt; boardClock += dt
	if incomeClock >= 1 then
		Economy:tick(incomeClock); incomeClock = 0
		for _, player in Battle:tick(os.time()) do publish(player, false) end
	end
	if hudClock >= 2 then
		hudClock = 0
		for player in Data.profiles do
			local profile = Data:get(player)
			if profile then
				local boost = Social:getServerLuck()
				local luck = Rules.luck(profile, Social:get(player), boost.bonus)
				-- Expired events and departing friends must immediately change disclosed odds.
				if lastLuck[player] ~= luck then publish(player, false) end
				EconomyEvent:FireClient(player, { coins = profile.coins, income = Rules.income(profile),
					luck = luck, pity = profile.pity,
					stats = profile.stats, serverLuck = boost, quests = Progression:quests(profile) })
			end
		end
	end
	if boardClock >= 10 then
		boardClock = 0
		for player, profile in Data.profiles do if Data:get(player) then Boards.update(player, profile) end end
	end
end)
task.spawn(function()
	while true do
		task.wait(Config.Game.AutoSaveSeconds)
		for player in Data.profiles do
			task.spawn(function() Data:save(player) end)
			task.spawn(function() Social:refresh(player); publish(player, false) end)
		end
	end
end)
game:BindToClose(function() Data:close() end)
