--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Buildings = require(ReplicatedStorage.Shared.Definitions.Buildings)
local Planets = require(ReplicatedStorage.Shared.Definitions.Planets)
local Placement = require(ReplicatedStorage.Shared.BuildingPlacement)
local Ledger = require(ReplicatedStorage.Shared.TransactionLedger)

local BuildingService = {}
BuildingService.__index = BuildingService

function BuildingService.new(economyService)
	return setmetatable({ economy = economyService, ledger = economyService.ledger, placed = {} }, BuildingService)
end

function BuildingService:getSnapshot()
	local snapshot = {}
	for index, building in ipairs(self.placed) do
		snapshot[index] = {
			id = building.id,
			buildingId = building.buildingId,
			planetId = building.planetId,
			position = { x = building.position.x, z = building.position.z },
			inventory = table.clone(building.inventory.items),
			actorId = building.actorId,
		}
	end
	return snapshot
end

function BuildingService:getById(buildingId)
	for _, building in ipairs(self.placed) do
		if building.id == buildingId then return building end
	end
	return nil
end

function BuildingService:place(transactionId, buildingId, planetId, position, actorId)
	local ledgerKey = tostring(actorId or "system") .. ":build:" .. transactionId
	local previous = Ledger.get(self.ledger, ledgerKey)
	if previous then return previous.ok, previous.result end

	local definition = Buildings[buildingId]
	local ok, code
	if not definition then
		ok, code = false, "unknown_building"
	elseif type(planetId) ~= "string" or not Planets[planetId] then
		ok, code = false, "unknown_planet"
	else
		ok, code = Placement.validate(position, #self.placed)
	end
	if not ok then
		local result = { ok = false, code = code }
		Ledger.record(self.ledger, ledgerKey, { ok = false, result = result })
		return false, result
	end
	if not Inventory.canConsume(self.economy.companyInventory, definition.buildCost) then
		local result = { ok = false, code = "insufficient_resources" }
		Ledger.record(self.ledger, ledgerKey, { ok = false, result = result })
		return false, result
	end

	for _, building in ipairs(self.placed) do
		if building.planetId == planetId and building.position.x == position.x and building.position.z == position.z then
			local result = { ok = false, code = "occupied" }
			Ledger.record(self.ledger, ledgerKey, { ok = false, result = result })
			return false, result
		end
	end
	Inventory.consume(self.economy.companyInventory, definition.buildCost)
	local record = { id = tostring(actorId or "system") .. "_" .. transactionId, buildingId = buildingId, planetId = planetId, position = { x = position.x, z = position.z }, inventory = Inventory.new(), actorId = actorId }
	table.insert(self.placed, record)
	local result = { ok = true, building = record, balance = Inventory.get(self.economy.companyInventory, "Credits") }
	Ledger.record(self.ledger, ledgerKey, { ok = true, result = result })
	return true, result
end

return BuildingService
