--!strict
-- Strict, bounded decoding of the exact embedded RGBA source bytes. No network access.
local PhotoBase64 = {}
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local values: { [number]: number } = {}
for index = 1, #alphabet do values[string.byte(alphabet, index)] = index - 1 end

function PhotoBase64.decode(encoded: any, expectedBytes: any): (buffer?, string?)
	if type(encoded) ~= "string" or type(expectedBytes) ~= "number"
		or expectedBytes % 1 ~= 0 or expectedBytes < 0 or expectedBytes > 4 * 1024 * 1024 then
		return nil, "Invalid photo byte count"
	end
	if #encoded ~= math.ceil(expectedBytes / 3) * 4 then return nil, "Photo byte length mismatch" end
	local output = buffer.create(expectedBytes)
	local cursor = 0
	for index = 1, #encoded, 4 do
		local a, b = values[string.byte(encoded, index)], values[string.byte(encoded, index + 1)]
		local third, fourth = string.byte(encoded, index + 2), string.byte(encoded, index + 3)
		local c, d = values[third], values[fourth]
		local last = index + 3 == #encoded
		if a == nil or b == nil then return nil, "Invalid photo base64" end
		if third == 61 then
			if not last or fourth ~= 61 or expectedBytes % 3 ~= 1 or b % 16 ~= 0 then
				return nil, "Invalid photo padding"
			end
			c, d = 0, 0
		elseif fourth == 61 then
			if c == nil or not last or expectedBytes % 3 ~= 2 or c % 4 ~= 0 then
				return nil, "Invalid photo padding"
			end
			d = 0
		elseif c == nil or d == nil or (last and expectedBytes % 3 ~= 0) then
			return nil, "Invalid photo base64"
		end
		local number = a * 262144 + b * 4096 + (c :: number) * 64 + (d :: number)
		if cursor < expectedBytes then buffer.writeu8(output, cursor, math.floor(number / 65536)); cursor += 1 end
		if cursor < expectedBytes then buffer.writeu8(output, cursor, math.floor(number / 256) % 256); cursor += 1 end
		if cursor < expectedBytes then buffer.writeu8(output, cursor, number % 256); cursor += 1 end
	end
	return output, nil
end

return PhotoBase64
