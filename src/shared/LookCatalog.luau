--!strict
-- Original stylized hair and gear, expressed as primitive specs. No asset IDs, no meshes.
--
-- Spec fields:  p  = body part to attach to        s  = "Block" | "Ball" | "Cylinder"
--               size = {x,y,z} (Cylinder: {diameter, length, _})   at = {x,y,z}   rot = degrees
--               c  = palette key or "RRGGBB"      m  = Enum.Material name      t = transparency
-- Units:  for p == "Head" every size/offset is in HEAD UNITS (the smallest head dimension, so
-- a (2,1,1) collision box and a 1.2 cube both get proportionate hair); for every other part
-- sizes/offsets are fractions of that part's own Size per axis. Front is -Z, back is +Z.
local LookCatalog = {}

export type Prim = {
	p: string, s: string, size: { number }, at: { number }?, rot: { number }?,
	c: string?, m: string?, t: number?,
}

LookCatalog.Builds = {
	-- Native Roblox avatar scales (ranges are the standard avatar limits so nothing is clamped).
	average = { height = 1.0, width = 0.92, depth = 0.9, head = 1.0, bodyType = 0, proportion = 0 },
	athletic = { height = 1.02, width = 1.0, depth = 1.0, head = 0.96, bodyType = 0.25, proportion = 0 },
	slim = { height = 1.0, width = 0.78, depth = 0.78, head = 1.0, bodyType = 0, proportion = 0.4 },
	tall = { height = 1.05, width = 0.86, depth = 0.85, head = 0.97, bodyType = 0, proportion = 0.6 },
	compact = { height = 0.9, width = 0.9, depth = 0.9, head = 1.0, bodyType = 0, proportion = 0 },
}

LookCatalog.Skin = {
	"F7D6B8", "EBC09A", "D9A27A", "C68863", "A8714A", "8A5A3A", "6B4429", "4E3321",
}

local Hair: { [string]: { Prim } } = {
	closecrop = { { p = "Head", s = "Block", size = { 1.06, 0.30, 1.06 }, at = { 0, 0.50, 0.02 }, c = "hair" } },
	flattop = {
		{ p = "Head", s = "Block", size = { 1.08, 0.62, 1.08 }, at = { 0, 0.64, 0.02 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 1.12, 0.12, 1.1 }, at = { 0, 0.34, 0.05 }, c = "hair" },
	},
	squarecut = { { p = "Head", s = "Block", size = { 1.12, 0.72, 1.12 }, at = { 0, 0.62, 0.02 }, c = "hair" } },
	geoflat = {
		{ p = "Head", s = "Block", size = { 1.06, 0.3, 1.06 }, at = { 0, 0.5, 0.02 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.96, 0.46, 0.96 }, at = { 0, 0.86, 0 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 1.1, 0.22, 1.0 }, at = { 0, 0.28, 0.04 }, c = "dark" },
	},
	pompadour = {
		{ p = "Head", s = "Block", size = { 1.08, 0.38, 1.08 }, at = { 0, 0.52, 0.02 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.96, 0.52, 0.62 }, at = { 0, 0.84, -0.2 }, rot = { -22, 0, 0 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.1, 0.42, 0.9 }, at = { 0.55, 0.18, 0.05 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.1, 0.42, 0.9 }, at = { -0.55, 0.18, 0.05 }, c = "hair" },
	},
	spiky = {
		{ p = "Head", s = "Block", size = { 1.08, 0.34, 1.08 }, at = { 0, 0.52, 0.02 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.26, 0.62, 0.26 }, at = { 0.32, 0.92, 0 }, rot = { 0, 0, -14 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.26, 0.74, 0.26 }, at = { 0, 1.0, -0.1 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.26, 0.62, 0.26 }, at = { -0.32, 0.92, 0 }, rot = { 0, 0, 14 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.26, 0.5, 0.26 }, at = { 0, 0.88, 0.3 }, rot = { 14, 0, 0 }, c = "hair" },
	},
	bob = {
		{ p = "Head", s = "Block", size = { 1.12, 0.42, 1.12 }, at = { 0, 0.52, 0.02 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.2, 0.95, 1.0 }, at = { 0.58, -0.02, 0.04 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.2, 0.95, 1.0 }, at = { -0.58, -0.02, 0.04 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 1.1, 0.95, 0.2 }, at = { 0, -0.02, 0.58 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 1.0, 0.2, 0.16 }, at = { 0, 0.4, -0.54 }, rot = { 0, 0, 5 }, c = "hair" },
	},
	doublebun = {
		{ p = "Head", s = "Block", size = { 1.08, 0.36, 1.08 }, at = { 0, 0.5, 0.02 }, c = "hair" },
		{ p = "Head", s = "Ball", size = { 0.5, 0.5, 0.5 }, at = { 0.38, 0.86, 0.05 }, c = "hair" },
		{ p = "Head", s = "Ball", size = { 0.5, 0.5, 0.5 }, at = { -0.38, 0.86, 0.05 }, c = "hair" },
	},
	braidcrown = {
		{ p = "Head", s = "Block", size = { 1.1, 0.4, 1.1 }, at = { 0, 0.52, 0.02 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 1.16, 0.14, 1.16 }, at = { 0, 0.72, 0.02 }, c = "trim", m = "Metal" },
		{ p = "Head", s = "Ball", size = { 0.36, 0.36, 0.36 }, at = { 0, -0.1, 0.62 }, c = "hair" },
		{ p = "Head", s = "Ball", size = { 0.34, 0.34, 0.34 }, at = { 0, -0.46, 0.66 }, c = "hair" },
		{ p = "Head", s = "Ball", size = { 0.32, 0.32, 0.32 }, at = { 0, -0.8, 0.7 }, c = "hair" },
		{ p = "Head", s = "Ball", size = { 0.28, 0.28, 0.28 }, at = { 0, -1.1, 0.72 }, c = "hair" },
	},
	curlycap = {
		{ p = "Head", s = "Ball", size = { 0.36, 0.36, 0.36 }, at = { 0.5, 0.3, 0.2 }, c = "hair" },
		{ p = "Head", s = "Ball", size = { 0.36, 0.36, 0.36 }, at = { -0.5, 0.3, 0.2 }, c = "hair" },
		{ p = "Head", s = "Ball", size = { 0.34, 0.34, 0.34 }, at = { 0.3, 0.1, 0.55 }, c = "hair" },
		{ p = "Head", s = "Ball", size = { 0.34, 0.34, 0.34 }, at = { -0.3, 0.1, 0.55 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 1.16, 0.3, 1.16 }, at = { 0, 0.58, 0 }, rot = { 0, 0, 6 }, c = "primary", m = "Fabric" },
		{ p = "Head", s = "Block", size = { 0.9, 0.08, 0.5 }, at = { 0.1, 0.44, -0.64 }, rot = { -6, 0, 6 }, c = "primary", m = "Fabric" },
	},
	braidsun = {
		{ p = "Head", s = "Ball", size = { 0.34, 0.34, 0.34 }, at = { 0, -0.1, 0.6 }, c = "hair" },
		{ p = "Head", s = "Ball", size = { 0.32, 0.32, 0.32 }, at = { 0, -0.44, 0.64 }, c = "hair" },
		{ p = "Head", s = "Ball", size = { 0.3, 0.3, 0.3 }, at = { 0, -0.76, 0.66 }, c = "hair" },
		{ p = "Head", s = "Cylinder", size = { 2.3, 0.08, 0 }, at = { 0, 0.56, 0 }, c = "light", m = "Fabric" },
		{ p = "Head", s = "Cylinder", size = { 1.1, 0.46, 0 }, at = { 0, 0.82, 0 }, c = "light", m = "Fabric" },
		{ p = "Head", s = "Cylinder", size = { 1.14, 0.1, 0 }, at = { 0, 0.66, 0 }, c = "accent", m = "Fabric" },
		{ p = "Head", s = "Block", size = { 0.2, 0.34, 0.06 }, at = { 0.5, 0.68, -0.56 }, rot = { 0, 0, -20 }, c = "green", m = "Neon" },
	},
	windswept = {
		{ p = "Head", s = "Block", size = { 1.08, 0.36, 1.08 }, at = { 0, 0.52, 0.02 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.9, 0.3, 0.7 }, at = { 0, 0.78, 0.2 }, rot = { 20, 0, 0 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.5, 0.22, 0.5 }, at = { 0.3, 0.74, 0 }, rot = { 0, 0, -18 }, c = "hair" },
	},
	prism = {
		{ p = "Head", s = "Block", size = { 1.08, 0.3, 1.08 }, at = { 0, 0.5, 0.02 }, c = "hair" },
		{ p = "Head", s = "Block", size = { 0.2, 0.9, 0.2 }, at = { 0, 0.98, -0.1 }, c = "accent", m = "Neon" },
		{ p = "Head", s = "Block", size = { 0.18, 0.66, 0.18 }, at = { 0.32, 0.86, 0 }, rot = { 0, 0, -22 }, c = "trim", m = "Neon" },
		{ p = "Head", s = "Block", size = { 0.18, 0.66, 0.18 }, at = { -0.32, 0.86, 0 }, rot = { 0, 0, 22 }, c = "trim", m = "Neon" },
	},
	bald = {},
}
LookCatalog.Hair = Hair

local Gear: { [string]: { Prim } } = {
	-- ----- head
	headband = { { p = "Head", s = "Block", size = { 1.12, 0.16, 1.12 }, at = { 0, 0.2, 0 }, c = "accent", m = "Fabric" } },
	headphones = {
		{ p = "Head", s = "Cylinder", size = { 0.56, 0.22, 0 }, at = { 0.64, 0, 0 }, rot = { 0, 0, 90 }, c = "dark" },
		{ p = "Head", s = "Cylinder", size = { 0.56, 0.22, 0 }, at = { -0.64, 0, 0 }, rot = { 0, 0, 90 }, c = "dark" },
		{ p = "Head", s = "Block", size = { 1.34, 0.1, 0.12 }, at = { 0, 0.66, 0 }, c = "dark" },
		{ p = "Head", s = "Cylinder", size = { 0.62, 0.05, 0 }, at = { 0.76, 0, 0 }, rot = { 0, 0, 90 }, c = "accent", m = "Neon" },
		{ p = "Head", s = "Cylinder", size = { 0.62, 0.05, 0 }, at = { -0.76, 0, 0 }, rot = { 0, 0, 90 }, c = "accent", m = "Neon" },
	},
	squareshades = {
		{ p = "Head", s = "Block", size = { 1.12, 0.3, 0.1 }, at = { 0, 0.08, -0.56 }, c = "dark" },
		{ p = "Head", s = "Block", size = { 1.16, 0.06, 0.12 }, at = { 0, 0.24, -0.56 }, c = "trim", m = "Metal" },
		{ p = "Head", s = "Block", size = { 0.14, 0.1, 0.1 }, at = { 0, 0.1, -0.57 }, c = "trim", m = "Metal" },
	},
	roundglasses = {
		{ p = "Head", s = "Ball", size = { 0.36, 0.36, 0.08 }, at = { 0.26, 0.06, -0.57 }, c = "accent", m = "Glass", t = 0.4 },
		{ p = "Head", s = "Ball", size = { 0.36, 0.36, 0.08 }, at = { -0.26, 0.06, -0.57 }, c = "accent", m = "Glass", t = 0.4 },
		{ p = "Head", s = "Block", size = { 0.16, 0.05, 0.06 }, at = { 0, 0.1, -0.58 }, c = "trim", m = "Metal" },
	},
	geoglasses = {
		{ p = "Head", s = "Block", size = { 0.5, 0.22, 0.08 }, at = { 0.28, 0.08, -0.57 }, rot = { 0, 0, -10 }, c = "dark" },
		{ p = "Head", s = "Block", size = { 0.5, 0.22, 0.08 }, at = { -0.28, 0.08, -0.57 }, rot = { 0, 0, 10 }, c = "dark" },
		{ p = "Head", s = "Block", size = { 0.12, 0.06, 0.06 }, at = { 0, 0.1, -0.58 }, c = "trim", m = "Metal" },
	},
	earcuff = { { p = "Head", s = "Block", size = { 0.08, 0.24, 0.14 }, at = { 0.58, 0, 0 }, c = "light", m = "Metal" } },
	crowndiamond = {
		{ p = "Head", s = "Block", size = { 0.36, 0.36, 0.36 }, at = { 0, 1.36, 0 }, rot = { 45, 0, 45 }, c = "accent", m = "Neon" },
		{ p = "Head", s = "Block", size = { 0.24, 0.24, 0.24 }, at = { 0.58, 1.12, 0 }, rot = { 45, 0, 45 }, c = "trim", m = "Neon" },
		{ p = "Head", s = "Block", size = { 0.24, 0.24, 0.24 }, at = { -0.58, 1.12, 0 }, rot = { 45, 0, 45 }, c = "trim", m = "Neon" },
	},
	halo = {
		{ p = "Head", s = "Ball", size = { 0.2, 0.2, 0.2 }, at = { 0.8, 1.22, 0 }, c = "trim", m = "Neon" },
		{ p = "Head", s = "Ball", size = { 0.2, 0.2, 0.2 }, at = { 0.4, 1.22, 0.69 }, c = "trim", m = "Neon" },
		{ p = "Head", s = "Ball", size = { 0.2, 0.2, 0.2 }, at = { -0.4, 1.22, 0.69 }, c = "trim", m = "Neon" },
		{ p = "Head", s = "Ball", size = { 0.2, 0.2, 0.2 }, at = { -0.8, 1.22, 0 }, c = "trim", m = "Neon" },
		{ p = "Head", s = "Ball", size = { 0.2, 0.2, 0.2 }, at = { -0.4, 1.22, -0.69 }, c = "trim", m = "Neon" },
		{ p = "Head", s = "Ball", size = { 0.2, 0.2, 0.2 }, at = { 0.4, 1.22, -0.69 }, c = "trim", m = "Neon" },
	},
	helmet = {
		{ p = "Head", s = "Block", size = { 1.2, 0.5, 1.2 }, at = { 0, 0.44, 0 }, c = "primary", m = "Metal" },
		{ p = "Head", s = "Block", size = { 0.14, 0.5, 0.9 }, at = { 0, 0.8, 0 }, c = "trim", m = "Metal" },
		{ p = "Head", s = "Block", size = { 0.1, 0.46, 0.5 }, at = { 0.62, 0.1, 0 }, c = "primary", m = "Metal" },
		{ p = "Head", s = "Block", size = { 0.1, 0.46, 0.5 }, at = { -0.62, 0.1, 0 }, c = "primary", m = "Metal" },
	},
	bigchin = { { p = "Head", s = "Block", size = { 0.9, 0.3, 0.5 }, at = { 0, -0.5, -0.32 }, c = "skin" } },
	-- ----- torso (fractions of UpperTorso size)
	scarf = {
		{ p = "UpperTorso", s = "Block", size = { 0.62, 0.22, 1.1 }, at = { 0, 0.5, 0 }, c = "accent", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 0.18, 0.8, 0.1 }, at = { 0.22, 0.08, -0.56 }, c = "accent", m = "Fabric" },
	},
	lightningpin = {
		{ p = "UpperTorso", s = "Block", size = { 0.07, 0.24, 0.05 }, at = { 0.3, 0.3, -0.52 }, rot = { 0, 0, 20 }, c = "trim", m = "Neon" },
		{ p = "UpperTorso", s = "Block", size = { 0.06, 0.16, 0.05 }, at = { 0.26, 0.12, -0.52 }, rot = { 0, 0, -20 }, c = "trim", m = "Neon" },
	},
	starbadge = {
		{ p = "UpperTorso", s = "Block", size = { 0.14, 0.2, 0.05 }, at = { 0.3, 0.3, -0.52 }, c = "trim", m = "Neon" },
		{ p = "UpperTorso", s = "Block", size = { 0.14, 0.2, 0.05 }, at = { 0.3, 0.3, -0.52 }, rot = { 0, 0, 45 }, c = "trim", m = "Neon" },
	},
	starbrooch = {
		{ p = "UpperTorso", s = "Block", size = { 0.26, 0.36, 0.06 }, at = { -0.26, 0.2, -0.53 }, c = "trim", m = "Neon" },
		{ p = "UpperTorso", s = "Block", size = { 0.26, 0.36, 0.06 }, at = { -0.26, 0.2, -0.53 }, rot = { 0, 0, 45 }, c = "trim", m = "Neon" },
	},
	hood = {
		{ p = "UpperTorso", s = "Block", size = { 0.82, 0.3, 0.5 }, at = { 0, 0.5, 0.42 }, c = "primary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 0.05, 0.36, 0.05 }, at = { 0.12, 0.2, -0.53 }, c = "light" },
		{ p = "UpperTorso", s = "Block", size = { 0.05, 0.36, 0.05 }, at = { -0.12, 0.2, -0.53 }, c = "light" },
	},
	zipstripe = { { p = "UpperTorso", s = "Block", size = { 0.05, 0.96, 0.05 }, at = { 0, 0, -0.52 }, c = "dark", m = "Metal" } },
	sunburstie = {
		{ p = "UpperTorso", s = "Block", size = { 0.14, 0.74, 0.05 }, at = { 0, -0.05, -0.52 }, c = "accent", m = "Neon" },
		{ p = "UpperTorso", s = "Block", size = { 0.18, 0.12, 0.07 }, at = { 0, 0.4, -0.52 }, c = "accent", m = "Neon" },
	},
	lapels = {
		{ p = "UpperTorso", s = "Block", size = { 0.26, 0.74, 0.07 }, at = { 0.26, 0.12, -0.52 }, rot = { 0, 0, -16 }, c = "secondary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 0.26, 0.74, 0.07 }, at = { -0.26, 0.12, -0.52 }, rot = { 0, 0, 16 }, c = "secondary", m = "Fabric" },
	},
	brooch = { { p = "UpperTorso", s = "Ball", size = { 0.18, 0.18, 0.09 }, at = { 0.38, 0.28, -0.54 }, c = "trim", m = "Metal" } },
	pocketwatch = {
		{ p = "UpperTorso", s = "Block", size = { 0.28, 0.03, 0.04 }, at = { 0.22, -0.05, -0.54 }, rot = { 0, 0, -20 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Ball", size = { 0.14, 0.14, 0.07 }, at = { 0.04, -0.14, -0.54 }, c = "trim", m = "Metal" },
	},
	medallion = {
		{ p = "UpperTorso", s = "Ball", size = { 0.24, 0.24, 0.1 }, at = { 0, 0.1, -0.54 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 0.03, 0.5, 0.03 }, at = { 0.18, 0.3, -0.52 }, rot = { 0, 0, -28 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 0.03, 0.5, 0.03 }, at = { -0.18, 0.3, -0.52 }, rot = { 0, 0, 28 }, c = "trim", m = "Metal" },
	},
	shoulderpads = {
		{ p = "UpperTorso", s = "Block", size = { 0.6, 0.28, 1.2 }, at = { 0.82, 0.52, 0 }, c = "primary", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 0.6, 0.28, 1.2 }, at = { -0.82, 0.52, 0 }, c = "primary", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 0.64, 0.07, 1.24 }, at = { 0.82, 0.38, 0 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 0.64, 0.07, 1.24 }, at = { -0.82, 0.38, 0 }, c = "trim", m = "Metal" },
	},
	starpads = {
		{ p = "UpperTorso", s = "Ball", size = { 0.26, 0.26, 0.26 }, at = { 0.82, 0.76, 0 }, c = "accent", m = "Neon" },
		{ p = "UpperTorso", s = "Ball", size = { 0.26, 0.26, 0.26 }, at = { -0.82, 0.76, 0 }, c = "accent", m = "Neon" },
	},
	cape = {
		{ p = "UpperTorso", s = "Block", size = { 1.02, 1.7, 0.1 }, at = { 0, -0.28, 0.62 }, rot = { 6, 0, 0 }, c = "secondary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 1.1, 0.2, 1.1 }, at = { 0, 0.52, 0 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 1.04, 0.1, 0.12 }, at = { 0, -1.12, 0.74 }, rot = { 6, 0, 0 }, c = "trim", m = "Metal" },
	},
	mantle = {
		{ p = "UpperTorso", s = "Block", size = { 0.62, 0.26, 1.2 }, at = { 0.8, 0.52, 0 }, c = "secondary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 0.5, 1.1, 0.1 }, at = { 0.8, -0.05, 0.58 }, c = "secondary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 0.64, 0.06, 1.22 }, at = { 0.8, 0.4, 0 }, c = "trim", m = "Metal" },
	},
	segmantle = {
		{ p = "UpperTorso", s = "Block", size = { 0.66, 0.16, 1.1 }, at = { 0.82, 0.58, 0 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 0.58, 0.16, 1.0 }, at = { 0.86, 0.42, 0 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 0.66, 0.16, 1.1 }, at = { -0.82, 0.58, 0 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 0.58, 0.16, 1.0 }, at = { -0.86, 0.42, 0 }, c = "trim", m = "Metal" },
	},
	ribbons = {
		{ p = "UpperTorso", s = "Block", size = { 0.07, 1.4, 0.34 }, at = { 0.95, 0.1, 0 }, rot = { 0, 0, -12 }, c = "accent", m = "Neon", t = 0.2 },
		{ p = "UpperTorso", s = "Block", size = { 0.07, 1.4, 0.34 }, at = { -0.95, 0.1, 0 }, rot = { 0, 0, 12 }, c = "accent", m = "Neon", t = 0.2 },
		{ p = "UpperTorso", s = "Block", size = { 0.07, 1.0, 0.34 }, at = { 0.8, -0.4, 0.8 }, rot = { 20, 0, -8 }, c = "trim", m = "Neon", t = 0.2 },
		{ p = "UpperTorso", s = "Block", size = { 0.07, 1.0, 0.34 }, at = { -0.8, -0.4, 0.8 }, rot = { 20, 0, 8 }, c = "trim", m = "Neon", t = 0.2 },
	},
	armorchest = {
		{ p = "UpperTorso", s = "Block", size = { 1.12, 0.82, 1.2 }, at = { 0, 0.08, 0 }, c = "primary", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 1.14, 0.08, 1.22 }, at = { 0, 0.38, 0 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 1.14, 0.08, 1.22 }, at = { 0, -0.26, 0 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Ball", size = { 0.28, 0.28, 0.1 }, at = { 0, 0.1, -0.62 }, c = "accent", m = "Neon" },
	},
	coat = {
		{ p = "UpperTorso", s = "Block", size = { 1.1, 1.02, 1.18 }, at = { 0, 0, 0 }, c = "primary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 0.3, 0.96, 0.06 }, at = { 0, 0, -0.6 }, c = "secondary", m = "Fabric" },
		{ p = "LowerTorso", s = "Block", size = { 1.14, 5.2, 1.22 }, at = { 0, -1.0, 0 }, c = "primary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 0.3, 0.6, 0.18 }, at = { 0.4, 0.58, -0.1 }, rot = { 0, 0, -24 }, c = "primary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 0.3, 0.6, 0.18 }, at = { -0.4, 0.58, -0.1 }, rot = { 0, 0, 24 }, c = "primary", m = "Fabric" },
	},
	cardigan = {
		{ p = "UpperTorso", s = "Block", size = { 1.1, 1.0, 1.16 }, at = { 0, 0, 0 }, c = "primary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 1.12, 0.14, 1.18 }, at = { 0, -0.46, 0 }, c = "secondary", m = "Fabric" },
	},
	overalls = {
		{ p = "UpperTorso", s = "Block", size = { 0.9, 0.7, 0.08 }, at = { 0, -0.1, -0.54 }, c = "primary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 0.16, 0.9, 0.08 }, at = { 0.32, 0.26, -0.52 }, c = "primary", m = "Fabric" },
		{ p = "UpperTorso", s = "Block", size = { 0.16, 0.9, 0.08 }, at = { -0.32, 0.26, -0.52 }, c = "primary", m = "Fabric" },
	},
	satchel = {
		{ p = "UpperTorso", s = "Block", size = { 0.1, 1.9, 0.1 }, at = { 0, 0, -0.54 }, rot = { 0, 0, 35 }, c = "dark", m = "Leather" },
		{ p = "UpperTorso", s = "Block", size = { 0.56, 0.5, 0.3 }, at = { -0.8, -0.85, -0.2 }, c = "secondary", m = "Leather" },
	},
	binder = {
		{ p = "UpperTorso", s = "Block", size = { 0.96, 1.1, 0.16 }, at = { 0, -0.1, -0.66 }, c = "secondary", m = "Leather" },
		{ p = "UpperTorso", s = "Block", size = { 0.2, 0.2, 0.18 }, at = { 0, -0.1, -0.7 }, c = "trim", m = "Metal" },
		{ p = "UpperTorso", s = "Block", size = { 0.9, 1.0, 0.1 }, at = { 0, -0.1, -0.58 }, c = "light" },
	},
	towel = { { p = "UpperTorso", s = "Block", size = { 0.5, 1.0, 1.1 }, at = { -0.82, 0.2, 0 }, c = "light", m = "Fabric" } },
	whistle = { { p = "UpperTorso", s = "Block", size = { 0.24, 0.12, 0.14 }, at = { 0.1, 0.05, -0.58 }, c = "trim", m = "Metal" } },
	pouch = { { p = "LowerTorso", s = "Block", size = { 0.6, 1.7, 0.5 }, at = { 0.72, -0.7, -0.5 }, c = "dark", m = "Leather" } },
	belt = { { p = "LowerTorso", s = "Block", size = { 1.04, 0.9, 1.1 }, at = { 0, 0.1, 0 }, c = "trim", m = "Metal" } },
	-- ----- arms
	wristbands = {
		{ p = "LeftLowerArm", s = "Block", size = { 1.14, 0.26, 1.14 }, at = { 0, -0.25, 0 }, c = "accent", m = "Fabric" },
		{ p = "RightLowerArm", s = "Block", size = { 1.14, 0.26, 1.14 }, at = { 0, -0.25, 0 }, c = "accent", m = "Fabric" },
	},
	foamcuffs = {
		{ p = "LeftLowerArm", s = "Block", size = { 1.36, 0.46, 1.36 }, at = { 0, -0.28, 0 }, c = "accent", m = "Fabric" },
		{ p = "RightLowerArm", s = "Block", size = { 1.36, 0.46, 1.36 }, at = { 0, -0.28, 0 }, c = "accent", m = "Fabric" },
	},
	wraps = {
		{ p = "LeftLowerArm", s = "Block", size = { 1.12, 0.5, 1.12 }, at = { 0, -0.3, 0 }, c = "light", m = "Fabric" },
		{ p = "RightLowerArm", s = "Block", size = { 1.12, 0.5, 1.12 }, at = { 0, -0.3, 0 }, c = "light", m = "Fabric" },
	},
	gauntlets = {
		{ p = "LeftLowerArm", s = "Block", size = { 1.22, 0.62, 1.22 }, at = { 0, -0.12, 0 }, c = "trim", m = "Metal" },
		{ p = "RightLowerArm", s = "Block", size = { 1.22, 0.62, 1.22 }, at = { 0, -0.12, 0 }, c = "trim", m = "Metal" },
		{ p = "LeftLowerArm", s = "Block", size = { 0.2, 0.34, 0.5 }, at = { -0.62, -0.1, 0 }, rot = { 0, 0, 20 }, c = "trim", m = "Metal" },
		{ p = "RightLowerArm", s = "Block", size = { 0.2, 0.34, 0.5 }, at = { 0.62, -0.1, 0 }, rot = { 0, 0, -20 }, c = "trim", m = "Metal" },
	},
	-- ----- ambient glow for Ascended forms
	aura = {
		{ p = "UpperTorso", s = "Ball", size = { 0.2, 0.2, 0.2 }, at = { 1.5, 0.7, 0.6 }, c = "accent", m = "Neon", t = 0.15 },
		{ p = "UpperTorso", s = "Ball", size = { 0.16, 0.16, 0.16 }, at = { -1.4, 0.2, 0.9 }, c = "trim", m = "Neon", t = 0.15 },
		{ p = "UpperTorso", s = "Ball", size = { 0.18, 0.18, 0.18 }, at = { 1.2, -0.8, -0.8 }, c = "trim", m = "Neon", t = 0.15 },
	},
}
LookCatalog.Gear = Gear

-- Hex ("RRGGBB") of palette fallbacks used when a look omits a key.
LookCatalog.DefaultPalette = {
	skin = "D9A27A", hair = "2B2118", primary = "5B6C8F", secondary = "394466", accent = "74E0F2",
	trim = "FFD36F", dark = "262633", light = "F1EDE4", green = "6DCB86",
}

return LookCatalog
