-- Executes production services with explicit Roblox service doubles. Passing
-- these checks does not establish Studio, DataStore API, or multiplayer health.
local Runtime = require("./runtime")
local Config = require("../src/shared/Config")
local Rules = require("../src/shared/Rules")
local PlayerDataService = require("../src/server/Services/PlayerDataService")
local CharacterService = require("../src/server/Services/CharacterService")
local EconomyService = require("../src/server/Services/EconomyService")

local function profileAt(timestamp)
	return Rules.newProfile(function()
		return Runtime.game:GetService("HttpService"):GenerateGUID(false)
	end, timestamp or os.time())
end

local function memoryPlayer()
	Runtime.reset({ studio = true })
	local player = Runtime.player()
	local data = PlayerDataService.new()
	local profile = assert(data:load(player))
	return player, data, profile
end

local function addCharacters(profile, count)
	for index = 1, count do
		table.insert(profile.characters, {
			uid = "owned-" .. tostring(index), characterId = "young_rookie",
			mutation = "Normal", level = 1, acquiredAt = os.time(),
		})
	end
end

return function(test)
	local function check(name, callback)
		test(name, function()
			Runtime.reset()
			callback()
		end)
	end

	check("new persistent profiles acquire a lease and save/reload their progress", function()
		local player, store = Runtime.player(), Runtime.store()
		local data = PlayerDataService.new()
		local profile = assert(data:load(player))
		assert(not data.memoryOnly and profile.coins == Config.Game.StartingCoins)
		assert(store.writes == 1 and store:snapshot("Player_123").session.id == data.sessions[player])
		profile.coins = 987
		profile.settings.reducedMotion = true
		assert(data:save(player, true) and data:get(player) == nil)
		assert(store:snapshot("Player_123").session == nil)
		local restored = assert(PlayerDataService.new():load(player))
		assert(restored.coins == 987 and restored.settings.reducedMotion)
		assert(restored.characters[1].uid == profile.characters[1].uid)
	end)

	check("a failed profile load retries with backoff and never writes a replacement", function()
		local player, store = Runtime.player(), Runtime.store()
		local old = profileAt()
		old.coins = 4321
		store:seed("Player_123", { data = old })
		store:failNext(3)
		local data = PlayerDataService.new()
		local profile, message = data:load(player)
		assert(profile == nil and type(message) == "string" and data:get(player) == nil)
		assert(store.calls == 3 and store.writes == 0 and store:snapshot("Player_123").data.coins == 4321)
		assert(#Runtime.waits == 2 and Runtime.waits[1] == 1 and Runtime.waits[2] == 2)
		assert(not data:save(player))
	end)

	check("transient load failure recovers without recreating existing progress", function()
		local store, player = Runtime.store(), Runtime.player()
		local old = profileAt()
		old.coins = 2048
		store:seed("Player_123", { data = old })
		store:failNext(2)
		local restored = assert(PlayerDataService.new():load(player))
		assert(restored.coins == 2048 and restored.characters[1].uid == old.characters[1].uid)
		assert(store.calls == 3 and store.writes == 1)
	end)

	check("unsupported and future profiles remain untouched", function()
		for _, record in { "legacy-format", { data = "bad" }, { data = { schemaVersion = 2, coins = 999 } } } do
			Runtime.reset()
			local store = Runtime.store()
			store:seed("Player_123", record)
			local loaded, reason = PlayerDataService.new():load(Runtime.player())
			assert(loaded == nil and type(reason) == "string")
			assert(store.writes == 0 and store.cancellations == 1)
			local retained = store:snapshot("Player_123")
			assert(type(retained) == type(record))
			if type(record) == "table" then
				if type(record.data) == "table" then assert(retained.data.schemaVersion == 2 and retained.data.coins == 999)
				else assert(retained.data == record.data) end
			else assert(retained == record) end
		end
	end)

	check("another server's live lease blocks a second writer", function()
		local store = Runtime.store()
		store:seed("Player_123", { data = profileAt(), session = { id = "other-server", expiresAt = os.time() + 180 } })
		local data = PlayerDataService.new()
		local loaded, reason = data:load(Runtime.player())
		assert(loaded == nil and string.find(reason, "another server"))
		assert(store.writes == 0 and store:snapshot("Player_123").session.id == "other-server")
	end)

	check("UpdateAsync load conflicts cannot overwrite a competing live lease", function()
		local store = Runtime.store()
		local winning = profileAt()
		winning.coins = 7654
		store:raceNext({ data = winning, session = { id = "winner", expiresAt = os.time() + 180 } })
		assert(PlayerDataService.new():load(Runtime.player()) == nil)
		assert(store.transforms == 2 and store.writes == 0)
		assert(store:snapshot("Player_123").data.coins == 7654 and store:snapshot("Player_123").session.id == "winner")
	end)

	check("expired leases may be acquired and offline income is capped atomically", function()
		local player, store = Runtime.player(), Runtime.store()
		local old = profileAt(os.time() - Config.Game.OfflineCapSeconds * 2)
		old.coins = 100
		old.placed = { old.characters[1].uid }
		store:seed("Player_123", { data = old, session = { id = "expired", expiresAt = os.time() - 1 } })
		local data = PlayerDataService.new()
		local loaded = assert(data:load(player))
		local expected = Rules.income(old) * Config.Game.OfflineCapSeconds * Config.Game.OfflineRate
		assert(loaded.offlineEarned == expected and loaded.coins == 100 + expected)
		local retained = store:snapshot("Player_123")
		assert(retained.data.coins == loaded.coins and retained.data.stats.totalEarned == expected)
		assert(retained.data.lastSeen >= os.time() - 1 and retained.session.id == data.sessions[player])
		-- Simulate a crash: expire the lease without saving the in-memory profile.
		retained.session.expiresAt = os.time() - 1
		store:seed("Player_123", retained)
		local resumed = assert(PlayerDataService.new():load(player))
		assert(resumed.offlineEarned < Rules.income(old) * 2)
		assert(resumed.coins < loaded.coins + Rules.income(old) * 2)
	end)

	check("offline credits respect the currency ceiling and ignore future timestamps", function()
		local store, old = Runtime.store(), profileAt(os.time() - Config.Game.OfflineCapSeconds * 2)
		old.coins = Config.Game.MaxCurrency - 1
		old.placed = { old.characters[1].uid }
		store:seed("Player_123", { data = old })
		local loaded = assert(PlayerDataService.new():load(Runtime.player()))
		assert(loaded.offlineEarned == 1 and loaded.coins == Config.Game.MaxCurrency)
		old.lastSeen = os.time() + 86400
		old.coins = 100
		store:seed("Player_456", { data = old })
		local future = assert(PlayerDataService.new():load(Runtime.player(456)))
		assert(future.coins == 100 and future.offlineEarned == 0)
	end)

	check("failed autosaves preserve stored progress and a later retry saves", function()
		local player, store, data = Runtime.player(), Runtime.store(), PlayerDataService.new()
		local profile = assert(data:load(player))
		profile.coins = 9988
		store:failNext(3)
		assert(not data:save(player))
		assert(store:snapshot("Player_123").data.coins == Config.Game.StartingCoins)
		assert(data:get(player) == profile and #Runtime.warnings > 0)
		assert(data:save(player) and store:snapshot("Player_123").data.coins == 9988)
	end)

	check("save conflicts drop the lost session and retain the winning record", function()
		local player, store, data = Runtime.player(), Runtime.store(), PlayerDataService.new()
		local profile = assert(data:load(player))
		profile.coins = 9999
		local winning = profileAt()
		winning.coins = 777
		store:raceNext({ data = winning, session = { id = "new-owner", expiresAt = os.time() + 180 } })
		assert(not data:save(player))
		assert(data:get(player) == nil and data.sessions[player] == nil and #player.kicks == 1)
		assert(store:snapshot("Player_123").data.coins == 777 and store:snapshot("Player_123").session.id == "new-owner")
	end)

	check("lease expiry prevents further reads and awards", function()
		local player, data = Runtime.player(), PlayerDataService.new()
		assert(data:load(player))
		data.expires[player] = os.time() - 1
		assert(data:get(player) == nil and data.profiles[player] == nil)
		assert(#player.kicks == 1 and EconomyService.new(data):income(player) == 0)
	end)

	check("a player leaving during load releases the newly acquired lease", function()
		local store, player, data = Runtime.store(), Runtime.player(), PlayerDataService.new()
		store.onUpdate = function() player.Parent = nil; data:remove(player) end
		local loaded, reason = data:load(player)
		assert(loaded == nil and string.find(reason, "left"))
		assert(store:snapshot("Player_123").session == nil and data.profiles[player] == nil)
		assert(data.loading[player] == nil and data.sessions[player] == nil)
	end)

	check("a departure during an autosave queues a final lease release", function()
		local store, player, data = Runtime.store(), Runtime.player(), PlayerDataService.new()
		local profile = assert(data:load(player))
		profile.coins = 5566
		store.onUpdate = function() data:remove(player) end
		assert(data:save(player))
		assert(store:snapshot("Player_123").session == nil)
		assert(store:snapshot("Player_123").data.coins == 5566 and data.profiles[player] == nil)
	end)

	check("Studio memory mode never requests a DataStore and discards prior progress", function()
		Runtime.reset({ studio = true })
		local player, data = Runtime.player(), PlayerDataService.new()
		local loaded = assert(data:load(player))
		assert(data.memoryOnly and #Runtime.storeRequests == 0)
		loaded.coins = 999
		assert(data:save(player, true))
		local fresh = assert(PlayerDataService.new():load(player))
		assert(fresh.coins == Config.Game.StartingCoins and fresh.characters[1].uid ~= loaded.characters[1].uid)
	end)

	check("Studio persistence uses an isolated namespace while live servers always persist", function()
		Runtime.reset({ studio = true, studioPersistence = true })
		local studio = PlayerDataService.new()
		assert(not studio.memoryOnly and studio.store == Runtime.store("MogvilleStudioProfiles_v1"))
		assert(studio:load(Runtime.player()))
		assert(Runtime.store("MogvilleProfiles_v1").calls == 0)
		Runtime.reset({ studio = false, studioPersistence = false })
		local live = PlayerDataService.new()
		assert(not live.memoryOnly and live.store == Runtime.store("MogvilleProfiles_v1"))
	end)

	check("display placement requires ownership, rejects duplicates and enforces purchased slots", function()
		local player, data, profile = memoryPlayer()
		local characters = CharacterService.new(data)
		addCharacters(profile, Config.Game.MaxSlots + 1)
		for _, bad in { false, 0, "", string.rep("x", 101), "not-owned" } do assert(not characters:equip(player, bad)) end
		for index = 1, Config.Game.BaseSlots do assert(characters:equip(player, profile.characters[index].uid)) end
		assert(not characters:equip(player, profile.characters[1].uid))
		assert(not characters:equip(player, profile.characters[Config.Game.BaseSlots + 1].uid))
		profile.upgrades.slots = Config.Game.MaxSlots - Config.Game.BaseSlots
		for index = Config.Game.BaseSlots + 1, Config.Game.MaxSlots do assert(characters:equip(player, profile.characters[index].uid)) end
		assert(#profile.placed == Config.Game.MaxSlots and not characters:equip(player, profile.characters[Config.Game.MaxSlots + 1].uid))
		assert(characters:unequip(player, profile.characters[1].uid))
		assert(not characters:unequip(player, profile.characters[1].uid))
		assert(characters:equip(player, profile.characters[Config.Game.MaxSlots + 1].uid))
	end)

	check("team selection validates the complete payload before changing the team", function()
		local player, data, profile = memoryPlayer()
		local characters = CharacterService.new(data)
		addCharacters(profile, 3)
		local a, b, c, d = profile.characters[1].uid, profile.characters[2].uid, profile.characters[3].uid, profile.characters[4].uid
		assert(characters:setTeam(player, { a, b, c }))
		local original = profile.team
		for _, payload in { false, { a, a }, { a, "not-owned" }, { a, b, c, d }, { [1] = a, [3] = c }, { [0] = a }, { [1] = a, extra = b } } do
			assert(not characters:setTeam(player, payload) and profile.team == original)
		end
		assert(characters:setTeam(player, { b }) and #profile.team == 1 and profile.team[1] == b)
	end)

	check("income ticks award only placed owned units with bounded elapsed time", function()
		local player, data, profile = memoryPlayer()
		local economy = EconomyService.new(data)
		local start = profile.coins
		economy:tick(1)
		assert(profile.coins == start and economy:income(player) == 0)
		profile.placed = { profile.characters[1].uid, profile.characters[1].uid, "not-owned" }
		assert(economy:income(player) == 2)
		economy:tick(1000)
		assert(profile.coins == start + 10 and profile.stats.totalEarned == 10 and profile.stats.peakIncome == 2)
		for _, dt in { 0, -1, math.huge, -math.huge, 0 / 0, "1" } do economy:tick(dt) end
		assert(profile.coins == start + 10 and profile.stats.totalEarned == 10)
		economy:tick(0.5)
		assert(profile.coins == start + 11 and profile.stats.totalEarned == 11)
	end)

	check("income totals stop at the configured currency ceiling", function()
		local player, data, profile = memoryPlayer()
		local economy = EconomyService.new(data)
		profile.placed = { profile.characters[1].uid }
		profile.coins = Config.Game.MaxCurrency - 1
		profile.stats.totalEarned = Config.Game.MaxCurrency - 0.5
		economy:tick(5)
		assert(profile.coins == Config.Game.MaxCurrency and profile.stats.totalEarned == Config.Game.MaxCurrency)
		economy:tick(5)
		assert(profile.coins == Config.Game.MaxCurrency and economy:income(player) == 2)
	end)

	check("upgrade purchases charge one exact cost and reject invalid, unaffordable or capped requests", function()
		local player, data, profile = memoryPlayer()
		local economy = EconomyService.new(data)
		local cost = economy:upgradeCosts(profile).slots
		assert(cost == Config.Upgrades.slots.baseCost)
		assert(not economy:upgrade(player, "slots") and profile.coins == Config.Game.StartingCoins and profile.upgrades.slots == 0)
		profile.coins = cost
		assert(economy:upgrade(player, "slots") and profile.coins == 0 and profile.upgrades.slots == 1)
		assert(not economy:upgrade(player, "slots") and profile.upgrades.slots == 1)
		for _, kind in { false, 1, {}, "unknown" } do assert(not economy:upgrade(player, kind)) end
		profile.coins = Config.Game.MaxCurrency
		profile.upgrades.slots = Config.Game.MaxSlots - Config.Game.BaseSlots
		local balance = profile.coins
		assert(not economy:upgrade(player, "slots") and economy:upgradeCosts(profile).slots == nil and profile.coins == balance)
	end)

	check("unloaded and departing profiles cannot place, upgrade or receive income", function()
		local player, data, profile = memoryPlayer()
		local characters, economy = CharacterService.new(data), EconomyService.new(data)
		profile.placed = { profile.characters[1].uid }
		local balance = profile.coins
		data.leaving[player] = true
		assert(not characters:equip(player, profile.characters[1].uid))
		assert(not characters:unequip(player, profile.characters[1].uid))
		assert(not characters:setTeam(player, {}))
		assert(not economy:upgrade(player, "luck") and economy:income(player) == 0)
		economy:tick(1)
		assert(profile.coins == balance)
	end)
end
