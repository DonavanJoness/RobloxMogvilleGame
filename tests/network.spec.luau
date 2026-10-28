local Guard = require("../src/server/Services/NetworkGuard")
return function(test)
	test("network rate limits bursts, per-action cooldowns and refills", function()
		local now, player = 0, {}
		local guard = Guard.new(function() return now end)
		assert(guard:allow(player, "Roll"))
		assert(not guard:allow(player, "Roll"))
		now = 0.81
		assert(guard:allow(player, "Roll"))
		for i = 1, 30 do guard:allow(player, "action" .. i) end
		assert(not guard:allow(player, "Equip"))
		now += 4
		assert(guard:allow(player, "Equip"))
		guard:remove(player)
		assert(guard.buckets[player] == nil)
	end)
	test("network rejects oversized, nested and non-finite inputs", function()
		assert(Guard.validPayload({count=10}))
		assert(Guard.validPayload({uids={"owned-1", "owned-2"}}))
		for _, value in { {count=0/0}, {count=math.huge}, {uid=string.rep("x",101)},
			{profile={coins=999}}, {uids={"a","b","c","d"}}, {[1]="bad"} } do
			assert(not Guard.validPayload(value))
		end
	end)
	test("rate-limit metadata cannot collide with an action name", function()
		local guard = Guard.new(function() return 100 end)
		local player = {}
		assert(guard:allow(player, "global"))
		assert(not guard:allow(player, "global"))
		assert(type(guard.buckets[player].global) == "table")
	end)
end
