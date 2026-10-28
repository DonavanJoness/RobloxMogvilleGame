--!strict
-- Pure token bucket: no remote can choose currency, outcomes, stats or another player.
local NetworkGuard = {}
NetworkGuard.__index = NetworkGuard

function NetworkGuard.new(clock)
	return setmetatable({ buckets = {}, clock = clock or os.clock }, NetworkGuard)
end

function NetworkGuard:allow(player, action)
	local now = self.clock()
	local buckets = self.buckets[player]
	if not buckets then buckets = { actions = {} }; self.buckets[player] = buckets end
	local global = buckets.global or { tokens = 16, at = now }
	buckets.global = global
	global.tokens = math.min(16, global.tokens + math.max(0, now - global.at) * 5)
	global.at = now
	if global.tokens < 1 then return false end
	global.tokens -= 1
	local delay = if action == "Roll" then 0.8 elseif action == "GetState" then 1 else 0.15
	local previous = buckets.actions[action]
	if previous and now - previous < delay then return false end
	buckets.actions[action] = now
	return true
end

function NetworkGuard:remove(player) self.buckets[player] = nil end

function NetworkGuard.validPayload(payload)
	if type(payload) ~= "table" then return false end
	local count = 0
	for key, value in payload do
		count += 1
		if count > 12 or type(key) ~= "string" or #key > 32 then return false end
		local kind = type(value)
		if kind == "string" then
			if #value > 100 then return false end
		elseif kind == "number" then
			if value ~= value or math.abs(value) > 1e9 then return false end
		elseif kind == "table" then
			-- Only the battle-team UID list is permitted to be nested.
			if key ~= "uids" or #value > 3 then return false end
			local nested = 0
			for index, uid in value do
				nested += 1
				if nested > 3 or type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > 3
					or type(uid) ~= "string" or #uid > 100 then return false end
			end
		elseif kind ~= "boolean" then return false end
	end
	return true
end

return NetworkGuard
