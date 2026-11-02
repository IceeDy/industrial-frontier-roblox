--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Ledger = require(ReplicatedStorage.Shared.TransactionLedger)
local Resources = require(ReplicatedStorage.Shared.Definitions.Resources)

local EconomyService = {}
EconomyService.__index = EconomyService

function EconomyService.new()
	return setmetatable({
		companyInventory = Inventory.new({ IronOre = 120, Credits = 5000 }),
		market = { IronOre = { supply = 500, demand = 400 }, IronIngot = { supply = 100, demand = 180 }, Steel = { supply = 50, demand = 120 } },
		ledger = Ledger.new(1000),
	}, EconomyService)
end

function EconomyService:buy(transactionId, resourceId, quantity, actorId)
	transactionId = tostring(actorId or "system") .. ":" .. transactionId
	local previous = Ledger.get(self.ledger, transactionId)
	if previous then return previous end
	local resource, quote = Resources[resourceId], self.market[resourceId]
	if not resource or not quote or type(quantity) ~= "number" or quantity < 1 or quantity > 1000 or quantity % 1 ~= 0 then
		local result = { ok = false, code = "invalid_order" }
		Ledger.record(self.ledger, transactionId, result)
		return result
	end
	local price = Economy.quote(resource.basePrice, quote.supply, quote.demand)
	local total = Economy.cost(price, quantity)
	if not Inventory.canConsume(self.companyInventory, { Credits = total }) then
		local result = { ok = false, code = "insufficient_funds" }
		Ledger.record(self.ledger, transactionId, result)
		return result
	end
	Inventory.consume(self.companyInventory, { Credits = total })
	Inventory.add(self.companyInventory, { [resourceId] = quantity })
	quote.supply = math.max(0, quote.supply - quantity)
	local result = { ok = true, unitPrice = price, total = total, balance = Inventory.get(self.companyInventory, "Credits") }
	Ledger.record(self.ledger, transactionId, result)
	return result
end

return EconomyService
