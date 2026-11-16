--!strict
-- Supplies native Roblox R15 rigs for ORIGINAL fictional characters and NPCs.
--
-- It uses Players:CreateHumanoidModelFromDescription with an EMPTY HumanoidDescription (only
-- body proportions set), so it needs no asset IDs, downloads no third-party content, and never
-- produces a real person's likeness. One template is created per body build at startup and
-- cloned afterwards, so building a plot never yields.
--
-- This cannot be exercised outside Roblox. If the call fails or returns something that is not an
-- R15 Model, the factory records the reason and reports "not ready"; callers then fall back to the
-- honest kiosk / card presentation instead of fabricating a rig.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local LookCatalog = require(ReplicatedStorage.Shared.LookCatalog)

local RigFactory = {}
RigFactory.__index = RigFactory

local FORBIDDEN = { "Script", "LocalScript", "ModuleScript", "ForceField", "Fire", "Smoke", "Sparkles", "Animate" }

function RigFactory.new(players: any?)
	return setmetatable({ players = players or Players, templates = {}, failures = {}, folder = nil }, RigFactory)
end

local function describe(build: any): HumanoidDescription
	local description = Instance.new("HumanoidDescription")
	description.HeightScale = build.height
	description.WidthScale = build.width
	description.DepthScale = build.depth
	description.HeadScale = build.head
	description.BodyTypeScale = build.bodyType
	description.ProportionScale = build.proportion
	return description
end

local function sanitize(model: Instance)
	for _, item in model:GetDescendants() do
		for _, className in FORBIDDEN do
			if item.ClassName == className or item.Name == "Animate" then
				item:Destroy()
				break
			end
		end
	end
end

-- Creates a template for every requested build in parallel (the engine call yields) and waits
-- for all of them or for the deadline. Returns how many requested builds are ready.
function RigFactory:prepare(builds: { string }, deadlineSeconds: number?): number
	if not self.folder then
		local folder = Instance.new("Folder")
		folder.Name = "MogvilleRigTemplates"
		folder.Parent = ServerStorage
		self.folder = folder
	end
	local deadline = os.clock() + (deadlineSeconds or 20)
	local pending = 0
	for _, key in builds do
		local build = LookCatalog.Builds[key]
		if self.templates[key] == nil and build ~= nil then
			pending += 1
			task.spawn(function()
				local ok, result = pcall(function()
					return self.players:CreateHumanoidModelFromDescription(describe(build), Enum.HumanoidRigType.R15)
				end)
				if ok and typeof(result) == "Instance" and result:IsA("Model") then
					sanitize(result)
					result.Name = "RigTemplate_" .. key
					result.Parent = self.folder
					self.templates[key] = result
				else
					self.failures[key] = tostring(result)
				end
				pending -= 1
			end)
		end
	end
	while pending > 0 and os.clock() < deadline do
		task.wait(0.05)
	end
	local ready = 0
	for _, key in builds do
		if self.templates[key] then ready += 1 end
	end
	return ready
end

function RigFactory:isReady(build: string): boolean
	return self.templates[build] ~= nil
end

function RigFactory:clone(build: string): (Model?, string?)
	local template = self.templates[build]
	if not template then
		return nil, self.failures[build] or ("No R15 template was prepared for build '" .. build .. "'.")
	end
	local ok, copy = pcall(function() return template:Clone() end)
	if not ok or not copy then return nil, "R15 template could not be cloned." end
	return copy :: Model, nil
end

function RigFactory:readyCount(): number
	local count = 0
	for _ in self.templates do count += 1 end
	return count
end

return RigFactory
