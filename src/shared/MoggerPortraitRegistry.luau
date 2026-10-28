--!strict
-- Real people are obtainable only after identity, authentic photo, rights and upload checks.
local Entries: any = require(script.Parent.RealMoggers)
local Registry = {}

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

function Registry.get(id: any): any
	local entry = if type(id) == "string" then Entries[id] else nil
	if not entry then return nil end
	local result = table.clone(entry)
	result.id = id
	result.obtainable = Registry.isReady(entry) and entry.requestedEnabled == true
	return result
end

function Registry.all(): { any }
	local result = {}
	for id in Entries do
		local entry = Registry.get(id)
		entry.obtainable = Registry.isReady(entry) and entry.requestedEnabled == true
		table.insert(result, entry)
	end
	table.sort(result, function(a, b) return a.displayName < b.displayName end)
	return result
end

return Registry
