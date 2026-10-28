-- One local animation loop. Server parts remain static; motion never replicates per frame.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local WorldEffectsController = {}
WorldEffectsController.__index = WorldEffectsController
local TAGS = { "MogvilleSpin", "MogvilleBob", "MogvilleParticles", "MogvilleLight" }

local function position(instance)
	if instance:IsA("BasePart") then return instance.Position end
	local host = instance.Parent
	if host and host:IsA("Attachment") then return host.WorldPosition end
	if host and host:IsA("BasePart") then return host.Position end
	return nil
end

function WorldEffectsController.new()
	local self = setmetatable({
		settings = {}, tracked = {}, connections = {}, time = 0, cullClock = 0,
		visible = {}, alive = true, world = Config.World or {},
		originalShadows = Lighting.GlobalShadows,
		postEffects = {},
	}, WorldEffectsController)
	local function add(instance)
		local entry = self.tracked[instance]
		if not entry then
			entry = { instance = instance, visible = false }
			if instance:IsA("BasePart") then entry.base = instance.CFrame end
			self.tracked[instance] = entry
		end
	end
	local function remove(instance)
		if not instance.Parent then self.tracked[instance] = nil; return end
		for _, tag in ipairs(TAGS) do
			if CollectionService:HasTag(instance, tag) then return end
		end
		self.tracked[instance] = nil
	end
	for _, tag in ipairs(TAGS) do
		for _, instance in ipairs(CollectionService:GetTagged(tag)) do add(instance) end
		table.insert(self.connections, CollectionService:GetInstanceAddedSignal(tag):Connect(add))
		table.insert(self.connections, CollectionService:GetInstanceRemovedSignal(tag):Connect(remove))
	end
	table.insert(self.connections, RunService.RenderStepped:Connect(function(dt) self:_step(dt) end))
	return self
end

function WorldEffectsController:setSettings(settings)
	self.settings = settings or {}
	local low = self.settings.lowEffects == true
	for _, name in ipairs({ "MogvilleBloom", "MogvilleSunRays" }) do
		local effect = Lighting:FindFirstChild(name)
		if effect and effect:IsA("PostEffect") then
			if self.postEffects[effect] == nil then self.postEffects[effect] = effect.Enabled end
			effect.Enabled = not low and self.postEffects[effect]
		end
	end
	Lighting.GlobalShadows = if low then false else self.originalShadows
	self.cullClock = 1 -- Apply a quality change on the next frame.
end

function WorldEffectsController:celebrate(rarity)
	if self.settings.lowEffects or self.settings.reducedMotion or not self.alive then return false end
	if os.clock() - (self.lastCelebration or -math.huge) < 0.75 then return false end
	local tier, tint = 0, nil
	for index, definition in ipairs(Config.Rarities) do
		if definition.id == rarity then tier, tint = index, Color3.fromHex(definition.color); break end
	end
	if tier < 3 then return false end
	local camera = Workspace.CurrentCamera
	if not camera then return false end
	local core, nearest = nil, 80
	for _, candidate in ipairs(CollectionService:GetTagged("MogvilleGachaCore")) do
		if candidate:IsA("BasePart") then
			local distance = (candidate.Position - camera.CFrame.Position).Magnitude
			if distance < nearest then core, nearest = candidate, distance end
		end
	end
	if not core then return false end
	self.lastCelebration = os.clock()
	local pulse = Instance.new("Part")
	pulse.Name = "LocalRarityPulse"
	pulse.Shape = Enum.PartType.Ball
	pulse.Size = core.Size * 1.2
	pulse.CFrame = core.CFrame
	pulse.Color = tint
	pulse.Material = Enum.Material.Neon
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.CanTouch = false
	pulse.CanQuery = false
	pulse.CastShadow = false
	pulse.Transparency = 0.65
	pulse.Parent = Workspace
	local light = Instance.new("PointLight")
	light.Color = tint
	light.Brightness = 1
	light.Range = 18
	light.Shadows = false
	light.Parent = pulse
	TweenService:Create(pulse, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = core.Size * (tier >= 5 and 2.5 or 2), Transparency = 1,
	}):Play()
	TweenService:Create(light, TweenInfo.new(0.75), { Brightness = 0 }):Play()
	if self.settings.sound ~= false then
		local sound = Instance.new("Sound")
		sound.Name = "LocalRarityChime"
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.18
		sound.PlaybackSpeed = 0.9 + tier * 0.1
		sound.RollOffMaxDistance = 45
		sound.Parent = pulse
		sound:Play()
	end
	Debris:AddItem(pulse, 0.8)
	return true
end

function WorldEffectsController:_cull()
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local low = self.settings.lowEffects == true
	local reducedMotion = self.settings.reducedMotion == true
	local distance = if low then (self.world.ReducedEffectDistance or 70) else (self.world.EffectDistance or 140)
	local maxAnimated = if low or reducedMotion then 0 else (self.world.MaxVisibleAnimations or 48)
	local maxParticles = if low or reducedMotion then 0 else (self.world.MaxVisibleParticleEmitters or 12)
	local maxLights = if low then 0 else (self.world.MaxVisibleLights or 12)
	local candidates = {}
	for instance, entry in self.tracked do
		if not instance.Parent then
			self.tracked[instance] = nil
		else
			local worldPosition = position(instance)
			local range = if worldPosition then (worldPosition - camera.CFrame.Position).Magnitude else math.huge
			entry.inRange = range < distance
			entry.range = range
			table.insert(candidates, entry)
		end
	end
	table.sort(candidates, function(a, b) return a.range < b.range end)
	local animations, particles, lights = 0, 0, 0
	self.visible = {}
	for _, entry in ipairs(candidates) do
		local instance = entry.instance
		if instance:IsA("BasePart") and entry.base then
			local animated = entry.inRange and animations < maxAnimated
			entry.visible = animated
			if animated then
				animations += 1
				table.insert(self.visible, entry)
			else
				instance.CFrame = entry.base
			end
		elseif instance:IsA("ParticleEmitter") then
			local enabled = entry.inRange and particles < maxParticles
			if enabled then particles += 1 end
			instance.Enabled = enabled
			if not enabled then instance:Clear() end
		elseif instance:IsA("Light") then
			local enabled = entry.inRange and lights < maxLights
			if enabled then lights += 1 end
			instance.Enabled = enabled
		end
	end
end

function WorldEffectsController:_step(dt)
	if not self.alive then return end
	self.time += math.min(dt, 0.1)
	self.cullClock += dt
	if self.cullClock >= 0.25 then self.cullClock = 0; self:_cull() end
	for _, entry in ipairs(self.visible) do
		local instance = entry.instance
		if not instance.Parent then continue end
		local bob, rotation = 0, 0
		if CollectionService:HasTag(instance, "MogvilleBob") then
			bob = math.sin(self.time * (instance:GetAttribute("BobSpeed") or 1.4) + (instance:GetAttribute("EffectPhase") or 0)) * (instance:GetAttribute("BobAmplitude") or 0.3)
		end
		if CollectionService:HasTag(instance, "MogvilleSpin") then
			rotation = self.time * (instance:GetAttribute("SpinSpeed") or 0.5)
		end
		instance.CFrame = entry.base * CFrame.new(0, bob, 0) * CFrame.Angles(0, rotation, 0)
	end
end

function WorldEffectsController:destroy()
	self.alive = false
	Lighting.GlobalShadows = self.originalShadows
	for effect, enabled in self.postEffects do if effect.Parent then effect.Enabled = enabled end end
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	for instance, entry in self.tracked do
		if instance.Parent then
			if entry.base then instance.CFrame = entry.base
			elseif instance:IsA("ParticleEmitter") or instance:IsA("Light") then instance.Enabled = false end
		end
	end
	table.clear(self.tracked)
	table.clear(self.visible)
end

return WorldEffectsController
