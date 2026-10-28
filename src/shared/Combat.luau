--!strict
-- Deterministic combat kernel. Only the server supplies teams or calls step.
local Combat = {}

function Combat.unit(stats: any, bonus: number?): any
	local multiplier = 1 + math.clamp(bonus or 0, 0, 1)
	return {
		uid = stats.uid, name = stats.name, ability = stats.ability,
		characterId = stats.characterId, identityId = stats.identityId, form = stats.form,
		portraitAssetId = stats.portraitAssetId, mutation = stats.mutation,
		hp = math.ceil(stats.health * multiplier), maxHp = math.ceil(stats.health * multiplier),
		attack = math.ceil(stats.attack * multiplier), defense = math.ceil(stats.defense * multiplier),
		speed = stats.speed, specialCooldown = 0, guarding = false,
	}
end

local function living(side: any): boolean
	if side.units[side.active] and side.units[side.active].hp > 0 then return true end
	for index, unit in side.units do
		if unit.hp > 0 then side.active = index; return true end
	end
	return false
end

local function log(battle: any, message: string)
	table.insert(battle.log, message)
	if #battle.log > 12 then table.remove(battle.log, 1) end
	battle.message = message
end

local function endCheck(battle: any): boolean
	local playerAlive, enemyAlive = living(battle.player), living(battle.enemy)
	if not playerAlive or not enemyAlive then
		battle.finished = true
		battle.winner = if playerAlive then "player" else "enemy"
		log(battle, if playerAlive then "Victory! Your team wins the Mog-Off." else "Defeat. Your Moggers are safe; improve your team and try again.")
		return true
	end
	return false
end

function Combat.damage(attacker: any, defender: any, multiplier: number): number
	local reduction = if defender.guarding then 0.45 else 1
	return math.max(1, math.floor((attacker.attack * multiplier - defender.defense * 0.55) * reduction))
end

local function strike(battle: any, attacker: any, defender: any, kind: string)
	if attacker.hp <= 0 then return end
	if kind == "defend" then
		attacker.guarding = true
		attacker.hp = math.min(attacker.maxHp, attacker.hp + math.ceil(attacker.maxHp * 0.06))
		log(battle, attacker.name .. " defends and recovers a little health.")
		return
	end
	local multiplier = 1
	if kind == "special" then
		attacker.specialCooldown = 3
		local ability = attacker.ability
		multiplier = 1.6
		if ability == "Strong Jaw" then multiplier = 1.9
		elseif ability == "Final Form" then multiplier = 2.3
		elseif ability == "Perfect Pose" then
			multiplier = 1.2
			attacker.guarding = true
			attacker.hp = math.min(attacker.maxHp, attacker.hp + math.ceil(attacker.maxHp * 0.15))
		elseif ability == "Spotlight" then
			multiplier = 1.65
			attacker.hp = math.min(attacker.maxHp, attacker.hp + math.ceil(attacker.maxHp * 0.08))
		elseif ability == "Intimidate" then
			-- One-round attack suppression; restored after this round.
			defender.weakened = true
		end
	end
	if attacker.weakened then multiplier *= 0.7 end
	local damage = Combat.damage(attacker, defender, multiplier)
	defender.hp = math.max(0, defender.hp - damage)
	log(battle, attacker.name .. " uses " .. (if kind == "special" then attacker.ability else "Basic Attack") .. " for " .. tostring(damage) .. " damage.")
	if defender.hp == 0 then log(battle, defender.name .. " is out!") end
end

-- Returns false without mutation for every invalid action.
function Combat.step(battle: any, kind: any, index: any): (boolean, string?)
	if battle.finished then return false, "This Mog-Off is finished." end
	if kind ~= "attack" and kind ~= "special" and kind ~= "defend" and kind ~= "switch" then
		return false, "Choose Attack, Special, Defend, or Switch."
	end
	local selected = battle.player.units[battle.player.active]
	if not selected or selected.hp <= 0 then return false, "No active Mogger." end
	if kind == "special" and selected.specialCooldown > 0 then return false, "Your special ability is cooling down." end
	if kind == "switch" then
		if type(index) ~= "number" or index ~= math.floor(index) or index == battle.player.active
			or not battle.player.units[index] or battle.player.units[index].hp <= 0 then
			return false, "Choose a living reserve Mogger."
		end
	end
	-- Cooldowns tick only after a valid action; reserve cooldowns recover too.
	for _, side in { battle.player, battle.enemy } do
		for _, unit in side.units do
			unit.guarding = false; unit.weakened = false
			unit.specialCooldown = math.max(0, unit.specialCooldown - 1)
		end
	end
	local enemy = battle.enemy.units[battle.enemy.active]
	local enemyKind = if enemy.specialCooldown == 0 and battle.turn % 3 == 0 then "special" else "attack"
	if kind == "switch" then
		battle.player.active = index
		selected = battle.player.units[index]
		log(battle, "Switched to " .. selected.name .. ".")
		strike(battle, enemy, selected, enemyKind)
	elseif kind == "defend" then
		-- Guard is established before any attack regardless of speed.
		strike(battle, selected, enemy, kind)
		strike(battle, enemy, selected, enemyKind)
	elseif selected.speed >= enemy.speed then
		strike(battle, selected, enemy, kind)
		if enemy.hp > 0 then strike(battle, enemy, selected, enemyKind) end
	else
		strike(battle, enemy, selected, enemyKind)
		if selected.hp > 0 then strike(battle, selected, enemy, kind) end
	end
	battle.turn += 1
	if not endCheck(battle) and battle.turn > 150 then
		battle.finished = true; battle.winner = "enemy"
		log(battle, "The arena time limit was reached. No Moggers were lost.")
	end
	return true
end

return Combat
