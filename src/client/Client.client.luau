--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UIController = require(script.Parent.Controllers.UIController)
local WorldEffectsController = require(script.Parent.Controllers.WorldEffectsController)

local network = ReplicatedStorage:WaitForChild("Network")
local request = network:WaitForChild("Request") :: RemoteFunction
local stateEvent = network:WaitForChild("State") :: RemoteEvent
local noticeEvent = network:WaitForChild("Notice") :: RemoteEvent
local economyEvent = network:WaitForChild("Economy") :: RemoteEvent

local worldEffects = WorldEffectsController.new()
local ui = UIController.new(function(action: string, payload: any)
	return request:InvokeServer(action, payload)
end, worldEffects)

stateEvent.OnClientEvent:Connect(function(state)
	ui:update(state)
end)
economyEvent.OnClientEvent:Connect(function(delta)
	ui:updateEconomy(delta)
end)
noticeEvent.OnClientEvent:Connect(function(message)
	ui:toast(tostring(message))
end)

local function inspectAttributes(source: Instance)
	local model = source:FindFirstAncestorOfClass("Model")
	local function attribute(name: string): any
		local own = source:GetAttribute(name)
		return if own ~= nil then own else (if model then model:GetAttribute(name) else nil)
	end
	ui:inspect(attribute("CharacterUID"), {
		characterId = attribute("CharacterId"), mutation = attribute("Mutation"), level = attribute("Level"),
	})
end

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	local action = prompt:GetAttribute("Action")
	if action == "Inspect" then inspectAttributes(prompt); return end
	local owner = prompt:GetAttribute("OwnerUserId")
	if owner and owner ~= Players.LocalPlayer.UserId then
		ui:toast("That display belongs to another collector.")
		return
	end
	if type(action) == "string" then
		ui:show(action)
	end
end)

local connected: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function connectInspection(instance: Instance)
	if connected[instance] or not instance:IsA("ClickDetector") then return end
	connected[instance] = true
	instance.MouseClick:Connect(function() inspectAttributes(instance) end)
end
for _, instance in CollectionService:GetTagged("MogvilleInspect") do connectInspection(instance) end
CollectionService:GetInstanceAddedSignal("MogvilleInspect"):Connect(connectInspection)

task.spawn(function()
	-- A newly connected client can reach the server before its profile finishes loading.
	for attempt = 1, 20 do
		local ok, response = pcall(function() return request:InvokeServer("GetState", {}) end)
		if ok and type(response) == "table" and response.ok and response.state then
			ui:update(response.state)
			return
		end
		task.wait(1)
	end
	ui:toast("Your profile is still loading. Rejoin if the server cannot restore it.", true)
end)
