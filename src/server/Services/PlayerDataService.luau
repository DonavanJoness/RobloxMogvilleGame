--!strict
-- No client can load, save, choose a key, or supply profile data. UpdateAsync
-- leases prevent two live servers from awarding against the same profile.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Rules = require(ReplicatedStorage.Shared.Rules)

local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService

local LEASE_SECONDS = 180
local MAX_ATTEMPTS = 3
local MAX_COINS = Config.Game.MaxCurrency or 1e15
local PERSISTED_FIELDS = {
	"schemaVersion", "coins", "characters", "placed", "team", "pets", "equippedPets",
	"upgrades", "pity", "stats", "quests", "ascension", "settings", "lastSeen",
}

local function newUid(): string
	return HttpService:GenerateGUID(false)
end

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in value do
		result[key] = copy(item)
	end
	return result
end

local function payload(profile: any, now: number): any
	local result = {}
	for _, field in PERSISTED_FIELDS do
		result[field] = copy(profile[field])
	end
	result.lastSeen = now
	return result
end

local function retry(operation: () -> any): (boolean, any)
	local lastError: any = nil
	for attempt = 1, MAX_ATTEMPTS do
		local success, result = pcall(operation)
		if success then
			return true, result
		end
		lastError = result
		if attempt < MAX_ATTEMPTS then
			task.wait(2 ^ (attempt - 1))
		end
	end
	return false, lastError
end

function PlayerDataService.new()
	-- Studio progress is intentionally disposable unless a developer explicitly
	-- enables persistence before Play. Published servers always use DataStores.
	local memoryOnly = RunService:IsStudio() and workspace:GetAttribute("MogvilleStudioPersistence") ~= true
	return setmetatable({
		profiles = {},
		sessions = {},
		expires = {},
		saving = {},
		loading = {},
		leaving = {},
		pendingRelease = {},
		closing = false,
		memoryOnly = memoryOnly,
		mode = if memoryOnly then "Studio memory (not saved)" else "Persistent",
		-- A separate namespace prevents Studio save tests from touching live data.
		store = if memoryOnly then nil else DataStoreService:GetDataStore(
			if RunService:IsStudio() then "MogvilleStudioProfiles_v1" else "MogvilleProfiles_v1"
		),
	}, PlayerDataService)
end

function PlayerDataService:_forget(player: Player)
	self.profiles[player] = nil
	self.sessions[player] = nil
	self.expires[player] = nil
	self.pendingRelease[player] = nil
	self.leaving[player] = nil
end

function PlayerDataService:_loseSession(player: Player)
	self:_forget(player)
	if player.Parent == Players then
		task.defer(function()
			player:Kick("Your save session expired or moved to another server. Please rejoin to protect your progress.")
		end)
	end
end

function PlayerDataService:get(player: Player): any
	if self.closing or self.leaving[player] then
		return nil
	end
	if not self.memoryOnly and self.expires[player] and os.time() >= self.expires[player] then
		self:_loseSession(player)
		return nil
	end
	return self.profiles[player]
end

function PlayerDataService:load(player: Player): (any, string?)
	if self.closing or self.loading[player] or self.profiles[player] then
		return nil, "This profile is already loading or the server is closing."
	end
	self.loading[player] = true
	local now = os.time()
	local sessionId = game.JobId .. ":" .. newUid()
	local profile: any = nil
	local expiresAt = now + LEASE_SECONDS
	local failure: string? = nil
	if self.memoryOnly then
		profile = Rules.newProfile(newUid, now)
	else
		local success, record = retry(function()
			return self.store:UpdateAsync("Player_" .. player.UserId, function(old: any)
				local timestamp = os.time()
				if old ~= nil and (type(old) ~= "table" or type(old.data) ~= "table") then
					failure = "Saved profile data has an unsupported format. It has not been replaced."
					return nil
				end
				if old and type(old.data.schemaVersion) == "number" and old.data.schemaVersion > 1 then
					failure = "This profile was saved by a newer game version. Please join a newer server."
					return nil
				end
				local previousSession = old and old.session
				if type(previousSession) == "table" and previousSession.id ~= sessionId
					and type(previousSession.expiresAt) == "number" and previousSession.expiresAt > timestamp then
					failure = "Your progress is open in another server. Wait a moment and rejoin."
					return nil
				end
				local loaded = if old then Rules.sanitize(old.data, newUid, timestamp) else Rules.newProfile(newUid, timestamp)
				-- Credit offline earnings in the same atomic write which takes the
				-- lease. A server crash before the first autosave cannot claim them twice.
				local elapsed = math.clamp(timestamp - (loaded.lastSeen or timestamp), 0, Config.Game.OfflineCapSeconds)
				local offline = math.min(MAX_COINS - loaded.coins, Rules.income(loaded) * elapsed * Config.Game.OfflineRate)
				loaded.coins += math.max(0, offline)
				loaded.stats.totalEarned = math.min(MAX_COINS, loaded.stats.totalEarned + math.max(0, offline))
				expiresAt = timestamp + LEASE_SECONDS
				-- This field is a safe informational value in the envelope, never
				-- used to award again, and omitted from future saved payloads.
				return { data = payload(loaded, timestamp), session = { id = sessionId, expiresAt = expiresAt }, offlineEarned = offline }
			end)
		end)
		if not success then
			failure = "Your progress could not be loaded. Please rejoin; no replacement profile was saved."
		elseif type(record) == "table" and type(record.session) == "table" and record.session.id == sessionId then
			profile = record.data
			profile.offlineEarned = math.max(0, record.offlineEarned or 0)
		else
			failure = failure or "Your profile is unavailable. Please rejoin in a moment."
		end
	end
	self.loading[player] = nil
	if not profile then
		return nil, failure
	end
	self.profiles[player] = profile
	self.sessions[player] = sessionId
	self.expires[player] = expiresAt
	-- PlayerRemoving can fire while UpdateAsync is yielding. Release that lease
	-- rather than retaining a profile which no active player can autosave.
	if player.Parent ~= Players or self.closing then
		self:remove(player)
		return nil, "The player left before loading finished."
	end
	return profile
end

function PlayerDataService:save(player: Player, release: boolean?): boolean
	if self.saving[player] then
		if release then
			self.pendingRelease[player] = true
		end
		return false
	end
	local profile = self.profiles[player]
	local sessionId = self.sessions[player]
	if not profile or not sessionId then
		return false
	end
	if self.memoryOnly then
		profile.lastSeen = os.time()
		if release then
			self:_forget(player)
		end
		return true
	end
	self.saving[player] = true
	local snapshot = payload(profile, os.time())
	local lostSession = false
	local savedExpiration = 0
	local success, record = retry(function()
		return self.store:UpdateAsync("Player_" .. player.UserId, function(current: any)
			if type(current) ~= "table" or type(current.session) ~= "table" or current.session.id ~= sessionId then
				lostSession = true
				return nil
			end
			savedExpiration = os.time() + LEASE_SECONDS
			return {
				data = snapshot,
				session = if release then nil else { id = sessionId, expiresAt = savedExpiration },
			}
		end)
	end)
	self.saving[player] = nil
	local saved = success and type(record) == "table" and not lostSession
	if lostSession then
		self:_loseSession(player)
		return false
	end
	if saved then
		profile.lastSeen = snapshot.lastSeen
		self.expires[player] = savedExpiration
	elseif not release then
		warn("Mogville: profile save failed for user " .. player.UserId .. "; existing saved data retained.")
		if os.time() >= (self.expires[player] or 0) then
			self:_loseSession(player)
			return false
		end
	end
	if release then
		if not saved then
			warn("Mogville: final save failed for user " .. player.UserId .. ". Session lease will expire safely.")
		end
		self:_forget(player)
	elseif self.pendingRelease[player] then
		self.pendingRelease[player] = nil
		return self:save(player, true)
	end
	return saved
end

function PlayerDataService:remove(player: Player)
	self.leaving[player] = true
	if self.profiles[player] then
		self:save(player, true)
	elseif not self.loading[player] then
		self:_forget(player)
	end
end

function PlayerDataService:close()
	self.closing = true
	for player in self.profiles do
		task.spawn(function()
			self:remove(player)
		end)
	end
	local deadline = os.clock() + 25
	repeat
		if next(self.profiles) == nil and next(self.loading) == nil then
			break
		end
		task.wait(0.1)
	until os.clock() >= deadline
end

return PlayerDataService
