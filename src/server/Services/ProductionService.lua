--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Production = require(ReplicatedStorage.Shared.Production)
local Recipes = require(ReplicatedStorage.Shared.Definitions.Recipes)
local Ledger = require(ReplicatedStorage.Shared.TransactionLedger)

local ProductionService = {}
ProductionService.__index = ProductionService

function ProductionService.new(economyService)
	return setmetatable({ economy = economyService, ledger = economyService.ledger }, ProductionService)
end

function ProductionService:run(transactionId, recipeId, cycles, actorId)
	local key = tostring(actorId or "system") .. ":" .. transactionId
	local previous = Ledger.get(self.ledger, key)
	if previous then return previous.ok, previous.result end
	local recipe = Recipes[recipeId]
	local ok, result
	if not recipe then ok, result = false, "unknown_recipe"
	else ok, result = Production.run(self.economy.companyInventory, recipe, cycles) end
	Ledger.record(self.ledger, key, { ok = ok, result = result })
	return ok, result
end

return ProductionService
