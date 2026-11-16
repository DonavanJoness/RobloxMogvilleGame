local Decoder = require("../src/shared/PhotoBase64")
return function(test)
	test("embedded photo decoder preserves zero, padded and arbitrary RGBA bytes", function()
		for _, row in { { "", "" }, { "Zg==", "f" }, { "Zm8=", "fo" }, { "Zm9v", "foo" }, { "AP8QIA==", string.char(0, 255, 16, 32) } } do
			local result, problem = Decoder.decode(row[1], #row[2])
			assert(result and not problem)
			assert(buffer.tostring(result) == row[2])
		end
	end)
	test("embedded photo decoder rejects corrupt padding, characters and byte counts", function()
		for _, row in { { "Zg==", 2 }, { "Zg?=", 2 }, { "Z===", 1 }, { "Zg==AAAA", 4 }, { "Zh==", 1 }, { "Zm9=", 2 }, { "Zm8=", 3 }, { "ZgAA", 1 }, { "Zm9v", -1 }, { "", 4 * 1024 * 1024 + 1 }, { "", 0.5 } } do
			local result, problem = Decoder.decode(row[1], row[2])
			assert(not result and problem)
		end
	end)
end
