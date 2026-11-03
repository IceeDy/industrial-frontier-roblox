--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Production = require(ReplicatedStorage.Shared.Production)
local Recipes = require(ReplicatedStorage.Shared.Definitions.Recipes)
local Ledger = require(ReplicatedStorage.Shared.TransactionLedger)
local Buildings = require(ReplicatedStorage.Shared.Definitions.Buildings)

local ProductionService = {}
ProductionService.__index = ProductionService

function ProductionService.new(economyService, buildingService)
	return setmetatable({ economy = economyService, buildings = buildingService, ledger = economyService.ledger }, ProductionService)
end

function ProductionService:run(transactionId, recipeId, cycles, actorId, buildingId)
	local key = tostring(actorId or "system") .. ":production:" .. transactionId
	local previous = Ledger.get(self.ledger, key)
	if previous then return previous.ok, previous.result end
	local recipe = Recipes[recipeId]
	local ok, result
	if not recipe then
		ok, result = false, "unknown_recipe"
	elseif buildingId then
		local building = self.buildings:getById(buildingId)
		local definition = building and Buildings[building.buildingId]
		if not building then
			ok, result = false, "unknown_building"
		elseif definition.recipeId ~= recipeId then
			ok, result = false, "recipe_not_supported"
		elseif type(cycles) == "number" and cycles >= 1 and cycles % 1 == 0 then
			local outgoing, stored = 0, 0
			for _, amount in pairs(recipe.outputs) do outgoing += amount * cycles end
			for _, amount in pairs(building.inventory.items) do stored += amount end
			if stored + outgoing > definition.inputCapacity + definition.outputCapacity then
				ok, result = false, "facility_capacity"
			else
				ok, result = Production.run(building.inventory, recipe, cycles)
			end
		else
			ok, result = false, "invalid_cycles"
		end
	else
		ok, result = false, "building_required"
	end
	Ledger.record(self.ledger, key, { ok = ok, result = result })
	return ok, result
end

return ProductionService
