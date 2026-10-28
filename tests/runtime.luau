-- Deterministic service doubles for the standalone Luau runner. These model
-- UpdateAsync cancellation/retry semantics, not Roblox networking or scheduling.
local Runtime = {}

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in value do result[key] = copy(item) end
	return result
end
Runtime.copy = copy

local Store = {}
Store.__index = Store

function Store:seed(key, value)
	self.records[key] = copy(value)
end

function Store:snapshot(key)
	return copy(self.records[key])
end

function Store:failNext(count)
	self.failures = count
end

-- Discard the first callback result, then retry it against a competing write.
function Store:raceNext(value)
	self.race = { value = copy(value) }
end

function Store:UpdateAsync(key, transform)
	self.calls += 1
	if self.failures > 0 then
		self.failures -= 1
		error("simulated DataStore outage")
	end
	if self.onUpdate then
		local hook = self.onUpdate
		self.onUpdate = nil
		hook(key)
	end
	self.transforms += 1
	local candidate = transform(copy(self.records[key]))
	if self.race then
		local race = self.race
		self.race = nil
		self.records[key] = copy(race.value)
		self.transforms += 1
		candidate = transform(copy(self.records[key]))
	end
	if candidate == nil then
		self.cancellations += 1
		return nil
	end
	self.records[key] = copy(candidate)
	self.writes += 1
	return copy(candidate)
end

local Players = {}
local DataStoreService = {}
function DataStoreService:GetDataStore(name)
	table.insert(Runtime.storeRequests, name)
	return Runtime.store(name)
end

local HttpService = {}
function HttpService:GenerateGUID(_braces)
	Runtime.uid += 1
	return "mock-guid-" .. tostring(Runtime.uid)
end

local RunService = {}
function RunService:IsStudio() return Runtime.studio end

Runtime.workspace = {}
function Runtime.workspace:GetAttribute(name) return Runtime.attributes[name] end
function Runtime.workspace:SetAttribute(name, value) Runtime.attributes[name] = value end

local services = {
	Players = Players,
	DataStoreService = DataStoreService,
	HttpService = HttpService,
	RunService = RunService,
	ReplicatedStorage = { Shared = { Config = "Config", Rules = "Rules" } },
}
Runtime.game = { JobId = "mock-job" }
function Runtime.game:GetService(name)
	assert(services[name], "Unsupported mocked Roblox service: " .. tostring(name))
	return services[name]
end

Runtime.task = {
	wait = function(seconds)
		table.insert(Runtime.waits, seconds)
		return seconds
	end,
	spawn = function(callback, ...) return callback(...) end,
	defer = function(callback, ...) return callback(...) end,
}

function Runtime.warn(message) table.insert(Runtime.warnings, message) end

function Runtime.store(name)
	name = name or "MogvilleProfiles_v1"
	if not Runtime.stores[name] then
		Runtime.stores[name] = setmetatable({
			records = {}, calls = 0, writes = 0, transforms = 0,
			cancellations = 0, failures = 0,
		}, Store)
	end
	return Runtime.stores[name]
end

function Runtime.player(userId)
	local player = { UserId = userId or 123, Parent = Players, kicks = {} }
	function player:Kick(message) table.insert(self.kicks, message) end
	return player
end

function Runtime.reset(options)
	options = options or {}
	Runtime.studio = options.studio == true
	Runtime.attributes = { MogvilleStudioPersistence = options.studioPersistence }
	Runtime.stores = {}
	Runtime.storeRequests = {}
	Runtime.waits = {}
	Runtime.warnings = {}
	Runtime.uid = 0
end

Runtime.reset()
return Runtime
