--!strict
-- Paid random rewards are deliberately unavailable. Free gacha uses earned Coins.
-- Only configured, deterministic cosmetic/convenience passes may be purchased.
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local ShopService = {}
ShopService.__index = ShopService

function ShopService.new()
	local self = setmetatable({ players = {}, passes = {} }, ShopService)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then return end
		-- The server event only triggers a fresh ownership check, never a client grant.
		for name, id in Config.Shop.GamePasses do
			if id > 0 and id == passId then self:refresh(player, name, id) end
		end
	end)
	-- No developer products are sold in this release; unknown receipts stay pending.
	-- Do not acknowledge an unfulfilled purchase. Add receipt+grant atomicity before enabling any.
	MarketplaceService.ProcessReceipt = function(_receipt)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return self
end

function ShopService:refresh(player, name, id)
	local ok, owned = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
	if not self.players[player] then return end
	if ok and owned then
		self.players[player].entitlements[name] = true
		player:SetAttribute("Mogville" .. name, true)
	end
end

function ShopService:load(player)
	self.players[player] = { entitlements = {}, paidRandomAllowed = false }
	-- Failure remains fail-closed. No paid luck is ever included in Rules.luck.
	local ok, policy = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	if not self.players[player] then return end
	self.players[player].paidRandomAllowed = ok and policy.ArePaidRandomItemsRestricted == false
	for name, id in Config.Shop.GamePasses do
		if type(id) == "number" and id > 0 then self:refresh(player, name, id) end
	end
end

function ShopService:catalog()
	local result = {}
	for name, id in Config.Shop.GamePasses do
		if type(id) == "number" and id > 0 then
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, Enum.InfoType.GamePass)
			if ok and info.IsForSale and type(info.PriceInRobux) == "number" then
				table.insert(result, { name = name, id = id, price = info.PriceInRobux,
					benefit = if name == "VIP" then "Cosmetic VIP title only; no paid luck." else "Automatically skip reveals; manual skip is free." })
			end
		end
	end
	return result
end

function ShopService:purchase(player, name)
	if type(name) ~= "string" then return false, "Unknown pass." end
	local id = Config.Shop.GamePasses[name]
	if type(id) ~= "number" or id <= 0 then return false, "Robux purchases are not configured yet." end
	if name ~= "VIP" and name ~= "AutoSkip" then return false, "This pass is unavailable." end
	local ok = pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, id)
	return ok, if ok then nil else "The purchase prompt is unavailable. Please try again later."
end

function ShopService:remove(player) self.players[player] = nil end
return ShopService
