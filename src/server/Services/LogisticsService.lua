--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Buildings = require(ReplicatedStorage.Shared.Definitions.Buildings)
local Resources = require(ReplicatedStorage.Shared.Definitions.Resources)
local Operations = require(ReplicatedStorage.Shared.PlanetaryOperations)
local Ledger = require(ReplicatedStorage.Shared.TransactionLedger)

local LogisticsService = {}
LogisticsService.__index = LogisticsService

function LogisticsService.new(buildingService, ledger, companyInventory)
	return setmetatable({ buildings = buildingService, ledger = ledger, companyInventory = companyInventory, routes = {} }, LogisticsService)
end

function LogisticsService:getSnapshot()
	local result = {}
	for index, route in ipairs(self.routes) do
		result[index] = table.clone(route)
	end
	return result
end

function LogisticsService:connect(transactionId, sourceId, destinationId, resourceId, actorId)
	local key = tostring(actorId or "system") .. ":route:" .. transactionId
	local previous = Ledger.get(self.ledger, key)
	if previous then return previous.ok, previous.result end
	local sourceBuilding = if sourceId == "company_inventory" then nil else self.buildings:getById(sourceId)
	local destinationBuilding = if destinationId == "company_inventory" then nil else self.buildings:getById(destinationId)
	local source = if sourceId == "company_inventory" then { id = sourceId, planetId = destinationBuilding and destinationBuilding.planetId, inventory = self.companyInventory } else sourceBuilding
	local destination = if destinationId == "company_inventory" then { id = destinationId, planetId = sourceBuilding and sourceBuilding.planetId, inventory = self.companyInventory } else destinationBuilding
	local sourceDefinition = if sourceId == "company_inventory" then { outputCapacity = math.huge } else source and Buildings[source.buildingId]
	local destinationDefinition = if destinationId == "company_inventory" then { inputCapacity = math.huge } else destination and Buildings[destination.buildingId]
	local result
	if not source or not destination or sourceId == destinationId then
		result = { ok = false, code = "invalid_endpoints" }
	elseif source.planetId ~= destination.planetId then
		result = { ok = false, code = "cross_planet_route" }
	elseif type(resourceId) ~= "string" or not Resources[resourceId] then
		result = { ok = false, code = "unknown_resource" }
	else
		local capacity = math.min(sourceDefinition.outputCapacity or 0, destinationDefinition.inputCapacity or 0)
		if capacity < 1 then
			result = { ok = false, code = "incompatible_facilities" }
		else
			local route = { id = tostring(actorId or "system") .. "_" .. transactionId, sourceId = sourceId, destinationId = destinationId, planetId = source.planetId, resourceId = resourceId, capacityPerRun = capacity, storageCapacity = if destinationId == "company_inventory" then nil else destinationDefinition.inputCapacity, enabled = true }
			table.insert(self.routes, route)
			result = { ok = true, route = table.clone(route) }
		end
	end
	Ledger.record(self.ledger, key, { ok = result.ok, result = result })
	return result.ok, result
end

function LogisticsService:transfer(transactionId, routeId, quantity, actorId)
	local key = tostring(actorId or "system") .. ":transfer:" .. transactionId
	local previous = Ledger.get(self.ledger, key)
	if previous then return previous.ok, previous.result end
	local route
	for _, candidate in ipairs(self.routes) do
		if candidate.id == routeId then route = candidate; break end
	end
	local result
	if not route then
		result = { ok = false, code = "unknown_route" }
	else
		local sourceBuilding = if route.sourceId == "company_inventory" then nil else self.buildings:getById(route.sourceId)
		local destinationBuilding = if route.destinationId == "company_inventory" then nil else self.buildings:getById(route.destinationId)
		local source = if route.sourceId == "company_inventory" then { inventory = self.companyInventory } else sourceBuilding
		local destination = if route.destinationId == "company_inventory" then { inventory = self.companyInventory } else destinationBuilding
		local ok, transferResult = Operations.transfer(source.inventory, destination.inventory, route.resourceId, quantity, route)
		result = if ok then { ok = true, transfer = transferResult, routeId = routeId } else { ok = false, code = transferResult }
	end
	Ledger.record(self.ledger, key, { ok = result.ok, result = result })
	return result.ok, result
end

return LogisticsService
