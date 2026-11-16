--!strict
-- Look recipes for ORIGINAL fictional characters and NPCs. Each recipe follows the written
-- design in CharacterCatalog / NPCConfiguration (outfit, hair, accessories, silhouette).
--
-- Real people are intentionally NOT handled here: no recipe may be created for a RealPerson
-- entry. Their presentation stays a photo card until an authentic, cleared portrait exists.
local LookCatalog = require(script.Parent.LookCatalog)
local PoseLibrary = require(script.Parent.PoseLibrary)

local CharacterLooks = {}

export type Outfit = {
	top: string?, sleeve: string?, forearm: string?, hand: string?, hips: string?,
	upperLeg: string?, lowerLeg: string?, foot: string?, material: string?,
}
export type Look = {
	id: string, build: string, scale: number, pose: string,
	palette: { [string]: string }, hair: string, outfit: Outfit, gear: { string },
}

-- Colors may be a palette key ("primary") or a literal "RRGGBB".
local function L(id: string, build: string, scale: number, pose: string, palette: { [string]: string }, hair: string, outfit: Outfit, gear: { string }): Look
	return { id = id, build = build, scale = scale, pose = pose, palette = palette, hair = hair, outfit = outfit, gear = gear }
end

local Identities: { [string]: Look } = {
	rookie = L("rookie", "average", 1.0, "relaxed",
		{ skin = "EBC09A", hair = "3A2A1E", primary = "7A4DFF", secondary = "5A36C8", accent = "FFD84A", trim = "FFD84A", dark = "2A2350" },
		"squarecut", { top = "primary", sleeve = "primary", hips = "2E3A66", upperLeg = "2E3A66", lowerLeg = "2E3A66", foot = "light" },
		{ "hood", "lightningpin" }),
	fade = L("fade", "average", 1.0, "hips",
		{ skin = "A8714A", hair = "17140F", primary = "62D9A4", secondary = "2E7D68", accent = "FFFFFF", trim = "E8F7F0", dark = "1E3B33" },
		"geoflat", { top = "primary", sleeve = "primary", hips = "3C4458", upperLeg = "3C4458", lowerLeg = "3C4458", foot = "light" },
		{ "zipstripe", "wristbands" }),
	pose = L("pose", "slim", 1.0, "starpose",
		{ skin = "F7D6B8", hair = "5A2D4A", primary = "F27DB8", secondary = "C94C92", accent = "FFE066", trim = "FFE066", dark = "4A1F3A" },
		"bob", { top = "primary", sleeve = "primary", hips = "primary", upperLeg = "primary", lowerLeg = "primary", foot = "trim" },
		{ "starbadge" }),
	jawline = L("jawline", "athletic", 1.0, "hips",
		{ skin = "D9A27A", hair = "5A3A22", primary = "C9B38C", secondary = "7A5C3A", accent = "4FA36B", trim = "D9B25F", dark = "3B2E22" },
		"spiky", { top = "primary", sleeve = "primary", hips = "5A4632", upperLeg = "5A4632", lowerLeg = "5A4632", foot = "dark" },
		{ "scarf", "bigchin", "belt" }),
	gym = L("gym", "athletic", 1.04, "flex",
		{ skin = "A8714A", hair = "1C1510", primary = "FF8A2B", secondary = "E36A10", accent = "F4F4F4", trim = "FFFFFF", dark = "3A2410" },
		"closecrop", { top = "primary", sleeve = "primary", hips = "primary", upperLeg = "primary", lowerLeg = "primary", foot = "light" },
		{ "headband", "foamcuffs", "zipstripe" }),
	runway = L("runway", "tall", 1.0, "stride",
		{ skin = "8A5A3A", hair = "1B1B2B", primary = "2D4FD0", secondary = "3E6BFF", accent = "FFD36F", trim = "FFD36F", dark = "10142B" },
		"pompadour", { top = "F4F1EA", sleeve = "F4F1EA", hips = "1B1B2B", upperLeg = "1B1B2B", lowerLeg = "1B1B2B", foot = "trim" },
		{ "cape", "starbrooch" }),
	champion = L("champion", "athletic", 1.04, "guard",
		{ skin = "C68863", hair = "1A1A22", primary = "35C8D8", secondary = "1E7C8A", accent = "FFFFFF", trim = "E8F7FF", dark = "0F3B42" },
		"bald", { top = "secondary", sleeve = "secondary", hand = "secondary", hips = "secondary", upperLeg = "secondary", lowerLeg = "secondary", foot = "dark" },
		{ "helmet", "armorchest", "shoulderpads", "gauntlets" }),
	gold = L("gold", "average", 1.0, "present",
		{ skin = "EBC09A", hair = "3A2A1E", primary = "F2C14E", secondary = "C99A2A", accent = "FF8A2B", trim = "FFE9A8", dark = "2A2A33" },
		"pompadour", { top = "primary", sleeve = "primary", hips = "primary", upperLeg = "primary", lowerLeg = "primary", foot = "dark" },
		{ "lapels", "sunburstie", "squareshades" }),
	royalty = L("royalty", "tall", 1.0, "hips",
		{ skin = "D9A27A", hair = "2A1E3A", primary = "3A2670", secondary = "8B5CF6", accent = "7FE8FF", trim = "FFD36F", dark = "2A1E4A" },
		"windswept", { top = "primary", sleeve = "primary", hips = "dark", upperLeg = "dark", lowerLeg = "dark", foot = "trim" },
		{ "cape", "crowndiamond", "medallion" }),
	icon = L("icon", "tall", 1.0, "relaxed",
		{ skin = "E6B48A", hair = "D9A441", primary = "F4ECD8", secondary = "E8C06A", accent = "FFE9A8", trim = "FFD36F", dark = "8A6A2A" },
		"bob", { top = "primary", sleeve = "primary", hips = "primary", upperLeg = "primary", lowerLeg = "primary", foot = "trim" },
		{ "coat", "halo", "medallion" }),
	stylist = L("stylist", "slim", 1.0, "present",
		{ skin = "EBC09A", hair = "BFE6FF", primary = "8FD3FF", secondary = "5AA7E8", accent = "BFF3FF", trim = "FFFFFF", dark = "3A5FA0" },
		"bob", { top = "DFF3FF", sleeve = "primary", hips = "primary", upperLeg = "dark", lowerLeg = "dark", foot = "light" },
		{ "ribbons", "geoglasses", "earcuff" }),
	apex = L("apex", "athletic", 1.04, "flex",
		{ skin = "C68863", hair = "1A1230", primary = "FF5FD2", secondary = "7A4DFF", accent = "7FE8FF", trim = "FFD36F", dark = "2B1B4A" },
		"prism", { top = "dark", sleeve = "dark", hips = "dark", upperLeg = "dark", lowerLeg = "dark", foot = "primary" },
		{ "shoulderpads", "starpads", "medallion" }),
}

CharacterLooks.Identities = Identities

-- Form modifiers. Each addGear entry carries its own `unless` list: the extra is skipped when the
-- base look already has an equivalent (a crowned royal needs no halo but still gains the aura).
CharacterLooks.Forms = {
	Young = { scale = 0.86, pose = "wave", addGear = {} },
	Classic = { scale = 1.0, addGear = {} },
	Prime = { scale = 1.06, addGear = {
		{ name = "shoulderpads", unless = { "shoulderpads", "armorchest", "segmantle", "mantle", "cape" } },
	} },
	Ascended = { scale = 1.12, pose = "victory", addGear = {
		{ name = "halo", unless = { "halo", "crowndiamond" } },
		{ name = "aura", unless = { "aura" } },
	} },
}

local NPCs: { [string]: Look } = {
	gacha_master = L("gacha_master", "average", 1.0, "present",
		{ skin = "C68863", hair = "20140C", primary = "F6F1E4", secondary = "7A3FD0", accent = "FFD36F", trim = "FFD36F", dark = "1B1B2B" },
		"pompadour", { top = "primary", sleeve = "primary", hips = "primary", upperLeg = "dark", lowerLeg = "dark", foot = "dark" },
		{ "lapels", "brooch", "pocketwatch", "wristbands" }),
	gym_trainer = L("gym_trainer", "athletic", 1.08, "hips",
		{ skin = "8A5A3A", hair = "120D0A", primary = "2FBFA8", secondary = "353B45", accent = "72E8D1", trim = "FFFFFF", dark = "20232B" },
		"closecrop", { top = "primary", sleeve = "primary", hips = "secondary", upperLeg = "primary", lowerLeg = "primary", foot = "light" },
		{ "headphones", "whistle", "towel", "wraps", "zipstripe" }),
	fashion_icon = L("fashion_icon", "tall", 1.04, "lean",
		{ skin = "F7D6B8", hair = "B79CFF", primary = "1E1B2A", secondary = "C9A5FF", accent = "E8A5FF", trim = "D8D8E8", dark = "14121C" },
		"bob", { top = "primary", sleeve = "primary", hips = "primary", upperLeg = "dark", lowerLeg = "dark", foot = "secondary" },
		{ "coat", "geoglasses", "earcuff", "satchel" }),
	battle_champion = L("battle_champion", "athletic", 1.06, "salute",
		{ skin = "A8714A", hair = "D8DCE6", primary = "1F3A7A", secondary = "E8EEF8", accent = "86BCFF", trim = "FFD36F", dark = "10204A" },
		"windswept", { top = "secondary", sleeve = "secondary", hand = "primary", hips = "primary", upperLeg = "secondary", lowerLeg = "secondary", foot = "primary" },
		{ "armorchest", "mantle", "medallion" }),
	ascension_guardian = L("ascension_guardian", "tall", 1.15, "guard",
		{ skin = "6B4429", hair = "15100E", primary = "F4F0E4", secondary = "F4F0E4", accent = "FFE5AA", trim = "FFD36F", dark = "6A5A2A" },
		"braidcrown", { top = "primary", sleeve = "primary", hand = "trim", hips = "trim", upperLeg = "primary", lowerLeg = "primary", foot = "trim", material = "Metal" },
		{ "armorchest", "segmantle", "gauntlets", "belt" }),
	resident_courier = L("resident_courier", "compact", 0.95, "wave",
		{ skin = "D9A27A", hair = "4A2C1A", primary = "FF8E6B", secondary = "7A4A32", accent = "FFE0A8", trim = "FFD36F", dark = "2A2A33" },
		"curlycap", { top = "primary", sleeve = "primary", hand = "3A2E2A", hips = "light", upperLeg = "light", lowerLeg = "light", foot = "5A3A2A" },
		{ "satchel" }),
	resident_collector = L("resident_collector", "average", 1.0, "guard",
		{ skin = "EBC09A", hair = "1B1420", primary = "A9C9A0", secondary = "6F8F6A", accent = "9EE5B4", trim = "FFFFFF", dark = "2C2E3A" },
		"doublebun", { top = "light", sleeve = "primary", hips = "dark", upperLeg = "dark", lowerLeg = "dark", foot = "green" },
		{ "cardigan", "binder", "roundglasses" }),
	resident_gardener = L("resident_gardener", "average", 1.0, "hips",
		{ skin = "A8714A", hair = "6B3F22", primary = "4F9A5B", secondary = "F1EDE4", accent = "FFE0A8", trim = "FFFFFF", dark = "4A3322" },
		"braidsun", { top = "secondary", sleeve = "secondary", hips = "primary", upperLeg = "primary", lowerLeg = "primary", foot = "dark" },
		{ "overalls", "pouch" }),
}

CharacterLooks.NPCs = NPCs

local function has(list: { string }, name: string): boolean
	return table.find(list, name) ~= nil
end

-- Resolve the look for a fictional collectible identity at a given form. Returns nil for
-- unknown identities so callers can fall back to the panel/kiosk presentation.
function CharacterLooks.forCharacter(identityId: string, form: string?): Look?
	local base = CharacterLooks.Identities[identityId]
	if not base then return nil end
	local modifier = CharacterLooks.Forms[form or "Classic"] or CharacterLooks.Forms.Classic
	local gear = table.clone(base.gear)
	for _, extra in modifier.addGear do
		local blocked = false
		for _, existing in extra.unless do
			if has(gear, existing) then blocked = true end
		end
		if not blocked then table.insert(gear, extra.name) end
	end
	local result = table.clone(base)
	result.id = identityId .. ":" .. (form or "Classic")
	result.scale = base.scale * modifier.scale
	result.pose = modifier.pose or base.pose
	result.gear = gear
	return result
end

function CharacterLooks.forNPC(npcId: string): Look?
	return CharacterLooks.NPCs[npcId]
end

local function validColor(value: string?): boolean
	if value == nil then return true end
	return LookCatalog.DefaultPalette[value] ~= nil or string.match(value, "^%x%x%x%x%x%x$") ~= nil
end

-- Structural validation: every referenced hair/gear/pose/build/color must exist.
function CharacterLooks.validate(look: Look): (boolean, string?)
	if not LookCatalog.Builds[look.build] then return false, "unknown build " .. look.build end
	if LookCatalog.Hair[look.hair] == nil then return false, "unknown hair " .. look.hair end
	if not PoseLibrary.has(look.pose) then return false, "unknown pose " .. look.pose end
	for _, name in look.gear do
		if LookCatalog.Gear[name] == nil then return false, "unknown gear " .. name end
	end
	for key, value in look.palette do
		if LookCatalog.DefaultPalette[key] == nil then return false, "unknown palette key " .. key end
		if not validColor(value) then return false, "bad color " .. value end
	end
	for key, value in look.outfit :: any do
		if key ~= "material" and not validColor(value) then return false, "bad outfit color " .. tostring(value) end
	end
	if look.scale < 0.5 or look.scale > 1.6 then return false, "scale out of range" end
	return true, nil
end

function CharacterLooks.allBuilds(): { string }
	local seen, list = {}, {}
	local function note(look: Look)
		if not seen[look.build] then seen[look.build] = true; table.insert(list, look.build) end
	end
	for _, look in CharacterLooks.Identities do note(look) end
	for _, look in CharacterLooks.NPCs do note(look) end
	table.sort(list)
	return list
end

return CharacterLooks
