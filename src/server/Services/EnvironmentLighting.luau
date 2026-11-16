-- Global lighting, atmosphere and post-processing. Kept apart from geometry so quality
-- tiers can be tuned (or replaced by an artist-authored Lighting setup) without touching
-- the city layout. Every post-effect is named "Mogville*" so the client's low-effects mode
-- can find and soften it.
local Lighting = game:GetService("Lighting")

local EnvironmentLighting = {}

local function ensure(className: string, name: string): any
	local existing = Lighting:FindFirstChild(name)
	if existing and existing.ClassName == className then return existing end
	if existing then existing:Destroy() end
	local item = Instance.new(className)
	item.Name = name
	item.Parent = Lighting
	return item
end

function EnvironmentLighting.apply()
	-- Warm late-morning sun: long soft shadows give the facades depth without going dark.
	Lighting.ClockTime = 15.2
	Lighting.GeographicLatitude = 28
	Lighting.Brightness = 2.7
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.35
	Lighting.Ambient = Color3.fromRGB(138, 132, 168)
	Lighting.OutdoorAmbient = Color3.fromRGB(168, 174, 198)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 244, 226)
	Lighting.ColorShift_Bottom = Color3.fromRGB(150, 140, 190)
	Lighting.EnvironmentDiffuseScale = 0.85
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.ExposureCompensation = 0.1
	Lighting.FogStart = 520
	Lighting.FogEnd = 1700
	Lighting.FogColor = Color3.fromRGB(198, 214, 238)

	local atmosphere = ensure("Atmosphere", "MogvilleAtmosphere")
	atmosphere.Density = 0.24
	atmosphere.Offset = 0.22
	atmosphere.Haze = 1.1
	atmosphere.Glare = 0.25
	atmosphere.Color = Color3.fromRGB(205, 222, 255)
	atmosphere.Decay = Color3.fromRGB(255, 190, 160)

	-- Restrained bloom: neon trim and signage glow, white marble does not blow out.
	local bloom = ensure("BloomEffect", "MogvilleBloom")
	bloom.Intensity = 0.28
	bloom.Size = 22
	bloom.Threshold = 1.15

	local correction = ensure("ColorCorrectionEffect", "MogvilleColor")
	correction.Saturation = 0.16
	correction.Contrast = 0.06
	correction.Brightness = 0.0
	correction.TintColor = Color3.fromRGB(255, 250, 244)

	local rays = ensure("SunRaysEffect", "MogvilleSunRays")
	rays.Intensity = 0.05
	rays.Spread = 0.85
end

return EnvironmentLighting
