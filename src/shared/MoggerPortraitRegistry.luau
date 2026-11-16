--!strict
-- Production approval and a private Studio photo preview are separate states.
local Entries: any = require(script.Parent.RealMoggers)
local EmbeddedPhotos: any = require(script.Parent.EmbeddedPhotoCatalog)
local Registry = {}

local function isStudio(): boolean
	-- Headless verification and published servers must fail closed.
	local ok, studio = pcall(function() return game:GetService("RunService"):IsStudio() end)
	return ok and studio == true
end

local function nonempty(value: any): boolean
	return type(value) == "string" and #value > 0
end

function Registry.validAssetId(value: any): boolean
	return type(value) == "number" and value == value and value > 0
		and value <= 9007199254740991 and value % 1 == 0
end

function Registry.isReady(entry: any): boolean
	if type(entry) ~= "table" then return false end
	return entry.referenceType == "RealPerson" and entry.imageStatus == "Approved"
		and Registry.validAssetId(entry.portraitAssetId)
		and entry.identityVerified == true and entry.authenticPhotograph == true
		and entry.adultEraVerified == true and entry.copyrightPermission == true
		and entry.commercialUseAllowed == true and entry.likenessPermission == "granted"
		and type(entry.sourceURL) == "string" and #entry.sourceURL > 0
		and type(entry.creator) == "string" and #entry.creator > 0
		and type(entry.license) == "string" and #entry.license > 0
		and type(entry.copyrightEvidence) == "string" and #entry.copyrightEvidence > 0
		and type(entry.likenessEvidence) == "string" and #entry.likenessEvidence > 0
		and type(entry.uploadEvidence) == "string" and #entry.uploadEvidence > 0
		and entry.uploadStatus == "uploaded"
end

-- The injected boolean makes the source-record policy independently testable;
-- obtainability always supplies the actual RunService Studio state below.
function Registry.previewRecordReady(entry: any, photo: any, studio: any): boolean
	if studio ~= true or type(entry) ~= "table" or type(photo) ~= "table" then return false end
	local width, height = photo.width, photo.height
	if type(width) ~= "number" or type(height) ~= "number"
		or width % 1 ~= 0 or height % 1 ~= 0 or width < 1 or height < 1
		or width > 1024 or height > 1024 then return false end
	local expectedLength = math.ceil(width * height * 4 / 3) * 4
	local encoded = photo.rgbaBase64
	if type(encoded) ~= "string" or #encoded ~= expectedLength
		or string.find(encoded, "[^A-Za-z0-9+/=]") then return false end
	local padding = (3 - (width * height * 4) % 3) % 3
	if string.find(string.sub(encoded, 1, #encoded - padding), "=", 1, true)
		or (padding > 0 and string.sub(encoded, -padding) ~= string.rep("=", padding)) then return false end
	return entry.referenceType == "RealPerson" and nonempty(entry.identityId)
		and entry.variant == "Classic" and photo.variant == entry.variant
		and photo.identityId == entry.identityId
		and photo.sourceVerified == true and photo.adultEraVerified == true
		and photo.ownerAuthorized == true
		and nonempty(photo.displayName) and nonempty(photo.attribution)
		and nonempty(photo.sourceURL) and nonempty(photo.licenseURL)
end

function Registry.isPreviewReady(entry: any): boolean
	if type(entry) ~= "table" or type(entry.identityId) ~= "string" then return false end
	return Registry.previewRecordReady(entry, EmbeddedPhotos[entry.identityId], isStudio())
end

function Registry.hasStudioPreviews(): boolean
	if not isStudio() then return false end
	for _, entry in Entries do
		if Registry.isPreviewReady(entry) then return true end
	end
	return false
end

function Registry.get(id: any): any
	local entry = if type(id) == "string" then Entries[id] else nil
	if not entry then return nil end
	local result = table.clone(entry)
	result.id = id
	local preview = Registry.isPreviewReady(entry)
	local production = Registry.isReady(entry)
	result.obtainable = (production and entry.requestedEnabled == true) or preview
	result.previewOnly = preview and not production
	result.embeddedIdentityId = if preview then entry.identityId else nil
	if preview then
		local photo = EmbeddedPhotos[entry.identityId]
		if not production then result.imageStatus = "StudioEmbeddedPhotoPreview" end
		result.photoAttribution = photo.attribution
		result.photoSourceURL = photo.sourceURL
		result.photoLicenseURL = photo.licenseURL
	end
	return result
end

function Registry.all(): { any }
	local result = {}
	for id in Entries do
		local entry = Registry.get(id)
		table.insert(result, entry)
	end
	table.sort(result, function(a, b) return a.displayName < b.displayName end)
	return result
end

return Registry
