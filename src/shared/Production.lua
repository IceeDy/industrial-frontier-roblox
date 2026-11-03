--!strict
local Production = {}

function Production.canRun(inventory, recipe)
	for id, amount in pairs(recipe.inputs) do
		if (inventory.items[id] or 0) < amount then return false end
	end
	return true
end

function Production.run(inventory, recipe, cycles)
	cycles = cycles or 1
	if type(cycles) ~= "number" or cycles < 1 or cycles > 100 or cycles % 1 ~= 0 then return false, "invalid_cycles" end
	local inputs, outputs = {}, {}
	for id, amount in pairs(recipe.inputs) do inputs[id] = amount * cycles end
	for id, amount in pairs(recipe.outputs) do outputs[id] = amount * cycles end
	for id, amount in pairs(inputs) do if (inventory.items[id] or 0) < amount then return false, "insufficient_inputs" end end
	for id, amount in pairs(inputs) do inventory.items[id] = inventory.items[id] - amount end
	for id, amount in pairs(outputs) do inventory.items[id] = (inventory.items[id] or 0) + amount end
	return true, outputs
end

return Production
