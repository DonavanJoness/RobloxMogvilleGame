--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local UIController = require(script.Parent.Controllers.UIController)

local network = ReplicatedStorage:WaitForChild("Network")
local request = network:WaitForChild("Request") :: RemoteFunction
local stateEvent = network:WaitForChild("State") :: RemoteEvent
local noticeEvent = network:WaitForChild("Notice") :: RemoteEvent
local economyEvent = network:WaitForChild("Economy") :: RemoteEvent

local ui = UIController.new(function(action: string, payload: any)
	return request:InvokeServer(action, payload)
end)

stateEvent.OnClientEvent:Connect(function(state)
	ui:update(state)
end)
economyEvent.OnClientEvent:Connect(function(delta)
	ui:updateEconomy(delta)
end)
noticeEvent.OnClientEvent:Connect(function(message)
	ui:toast(tostring(message))
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	local owner = prompt:GetAttribute("OwnerUserId")
	if owner and owner ~= Players.LocalPlayer.UserId then
		ui:toast("That display belongs to another collector.")
		return
	end
	local action = prompt:GetAttribute("Action")
	if type(action) == "string" then
		ui:show(action)
	end
end)

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
