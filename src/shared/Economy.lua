--!strict
local Economy = {}

function Economy.quote(basePrice, supply, demand)
	assert(basePrice > 0 and supply >= 0 and demand >= 0, "invalid market values")
	local pressure = (demand + 1) / (supply + 1)
	return math.max(1, math.floor(basePrice * math.clamp(pressure, 0.25, 4) + 0.5))
end

function Economy.cost(unitPrice, quantity)
	assert(unitPrice > 0 and quantity >= 1 and quantity % 1 == 0, "invalid order")
	return unitPrice * quantity
end

return Economy
