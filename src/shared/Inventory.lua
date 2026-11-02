--!strict
local Inventory = {}

function Inventory.new(initial)
	local items = {}
	for resourceId, amount in pairs(initial or {}) do
		assert(type(amount) == "number" and amount >= 0 and amount % 1 == 0, "invalid initial amount")
		items[resourceId] = amount
	end
	return { items = items }
end

function Inventory.get(inventory, resourceId)
	return inventory.items[resourceId] or 0
end

function Inventory.canConsume(inventory, costs)
	for id, amount in pairs(costs) do
		if type(amount) ~= "number" or amount <= 0 or amount % 1 ~= 0 or Inventory.get(inventory, id) < amount then
			return false
		end
	end
	return true
end

function Inventory.consume(inventory, costs)
	if not Inventory.canConsume(inventory, costs) then return false, "insufficient_resources" end
	for id, amount in pairs(costs) do inventory.items[id] = Inventory.get(inventory, id) - amount end
	return true
end

function Inventory.add(inventory, gains)
	for id, amount in pairs(gains) do
		if type(amount) ~= "number" or amount <= 0 or amount % 1 ~= 0 then return false, "invalid_amount" end
	end
	for id, amount in pairs(gains) do inventory.items[id] = Inventory.get(inventory, id) + amount end
	return true
end

return Inventory
