local Combat = require("../src/shared/Combat")

local function unit(overrides)
	local stats = { uid = "test", name = "Test", health = 100, attack = 20, defense = 5, speed = 10, ability = "Strong Jaw" }
	for key, value in overrides or {} do stats[key] = value end
	return Combat.unit(stats, 0)
end

local function battle(playerUnits, enemyUnits)
	return { id = "test", turn = 1, finished = false, message = "", log = {},
		player = { active = 1, units = playerUnits or { unit({}) } },
		enemy = { active = 1, units = enemyUnits or { unit({}) } } }
end

return function(test)
	test("invalid battle actions do not advance the turn", function()
		local state = battle()
		assert(not Combat.step(state, "win", nil))
		assert(not Combat.step(state, "switch", -1))
		assert(not Combat.step(state, "switch", 1))
		assert(state.turn == 1 and state.enemy.units[1].hp == 100)
	end)
	test("speed priority can prevent a defeated enemy attacking", function()
		local state = battle({ unit({ attack = 200, speed = 30 }) }, { unit({ speed = 10 }) })
		assert(Combat.step(state, "attack"))
		assert(state.finished and state.winner == "player")
		assert(state.player.units[1].hp == 100)
	end)
	test("special cooldown rejects repeated special and recovers through turns", function()
		local state = battle({ unit({ attack = 1, health = 1000 }) }, { unit({ attack = 1, health = 1000 }) })
		assert(Combat.step(state, "special"))
		assert(not Combat.step(state, "special"))
		for _ = 1, 3 do assert(Combat.step(state, "attack")) end
		assert(Combat.step(state, "special"))
	end)
	test("defend reduces incoming damage", function()
		local normal, defended = battle(), battle()
		assert(Combat.step(normal, "attack"))
		assert(Combat.step(defended, "defend"))
		assert(defended.player.units[1].hp > normal.player.units[1].hp)
	end)
	test("switching consumes a turn and targets the reserve", function()
		local state = battle({ unit({ uid = "a" }), unit({ uid = "b" }) })
		assert(Combat.step(state, "switch", 2))
		assert(state.player.active == 2 and state.player.units[1].hp == 100 and state.player.units[2].hp < 100)
	end)
	test("fallen active units automatically switch to living reserves", function()
		local state = battle({ unit({ health = 1, speed = 1 }), unit({}) }, { unit({ attack = 200, speed = 30 }) })
		assert(Combat.step(state, "attack"))
		assert(state.player.active == 2 and not state.finished)
	end)
	test("finished battles cannot be advanced or re-awarded", function()
		local state = battle({ unit({ attack = 200, speed = 30 }) })
		assert(Combat.step(state, "attack"))
		local turn = state.turn
		assert(not Combat.step(state, "attack"))
		assert(state.turn == turn)
	end)
	test("pet battle bonuses cap at double base stats", function()
		local fighter = Combat.unit({ uid = "x", name = "x", health = 100, attack = 20, defense = 10, speed = 5, ability = "Spotlight" }, 100)
		assert(fighter.maxHp == 200 and fighter.attack == 40 and fighter.defense == 20)
	end)
end
