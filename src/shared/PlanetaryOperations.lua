--!strict
local Inventory = require("./Inventory")
local Economy = require("./Economy")

local Operations = {}

local function validQuantity(quantity)
	return type(quantity) == "number" and quantity >= 1 and quantity % 1 == 0 and quantity <= 1000000
end

function Operations.transfer(sourceInventory, destinationInventory, resourceId, quantity, route)
	if type(route) ~= "table" or route.enabled ~= true or type(route.capacityPerRun) ~= "number" then
		return false, "invalid_route"
	end
	if type(resourceId) ~= "string" or not validQuantity(quantity) then return false, "invalid_cargo" end
	if sourceInventory == destinationInventory then return false, "same_endpoint" end
	if quantity > route.capacityPerRun then return false, "route_capacity" end
	if type(route.storageCapacity) == "number" then
		local stored = 0
		for _, amount in pairs(destinationInventory.items) do stored += amount end
		if stored + quantity > route.storageCapacity then return false, "destination_capacity" end
	end
	if not Inventory.canConsume(sourceInventory, { [resourceId] = quantity }) then return false, "insufficient_cargo" end
	Inventory.consume(sourceInventory, { [resourceId] = quantity })
	Inventory.add(destinationInventory, { [resourceId] = quantity })
	return true, { resourceId = resourceId, quantity = quantity }
end

function Operations.export(inventory, market, resourceId, quantity, exportMultiplier)
	if type(resourceId) ~= "string" or not validQuantity(quantity) then return false, "invalid_order" end
	if type(market) ~= "table" or type(market.basePrice) ~= "number" or type(market.supply) ~= "number" or type(market.demand) ~= "number" then
		return false, "market_unavailable"
	end
	exportMultiplier = exportMultiplier or 1
	if type(exportMultiplier) ~= "number" or exportMultiplier <= 0 or exportMultiplier > 10 then return false, "invalid_market_modifier" end
	if not Inventory.canConsume(inventory, { [resourceId] = quantity }) then return false, "insufficient_cargo" end
	local unitPrice = math.max(1, math.floor(Economy.quote(market.basePrice, market.supply, market.demand) * exportMultiplier))
	local total = unitPrice * quantity
	Inventory.consume(inventory, { [resourceId] = quantity })
	Inventory.add(inventory, { Credits = total })
	market.supply += quantity
	return true, { resourceId = resourceId, quantity = quantity, unitPrice = unitPrice, total = total }
end

return Operations
