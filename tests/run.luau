local Inventory = require("../src/shared/Inventory")
local Production = require("../src/shared/Production")
local Economy = require("../src/shared/Economy")
local Ledger = require("../src/shared/TransactionLedger")
local Placement = require("../src/shared/BuildingPlacement")
local Operations = require("../src/shared/PlanetaryOperations")

local passed = 0
local function test(name, fn)
	local ok, err = pcall(fn)
	if not ok then error("FAIL " .. name .. ": " .. tostring(err)) end
	passed += 1
	print("PASS " .. name)
end
local function equal(actual, expected)
	assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

test("inventory consumption is atomic on insufficient funds", function()
	local inv = Inventory.new({ Credits = 10 })
	local ok = Inventory.consume(inv, { Credits = 11 })
	equal(ok, false); equal(Inventory.get(inv, "Credits"), 10)
end)

test("production consumes exact recipe inputs and creates outputs", function()
	local inv = Inventory.new({ IronOre = 9 })
	local ok = Production.run(inv, { inputs = { IronOre = 3 }, outputs = { IronIngot = 2 } }, 3)
	equal(ok, true); equal(Inventory.get(inv, "IronOre"), 0); equal(Inventory.get(inv, "IronIngot"), 6)
end)

test("production rejects shortages without partial mutation", function()
	local inv = Inventory.new({ IronOre = 2 })
	local ok = Production.run(inv, { inputs = { IronOre = 3 }, outputs = { IronIngot = 2 } }, 1)
	equal(ok, false); equal(Inventory.get(inv, "IronOre"), 2); equal(Inventory.get(inv, "IronIngot"), 0)
end)

test("production limits requested cycles to a safe bounded batch", function()
	local inv = Inventory.new({ IronOre = 100000 })
	local ok, code = Production.run(inv, { inputs = { IronOre = 1 }, outputs = { IronIngot = 1 } }, 101)
	equal(ok, false); equal(code, "invalid_cycles"); equal(Inventory.get(inv, "IronOre"), 100000)
end)

test("market price responds to demand and remains bounded", function()
	local high = Economy.quote(10, 0, 100)
	local low = Economy.quote(10, 100, 0)
	assert(high > low); equal(low, 3); equal(high, 40)
end)

test("transaction ledger returns an existing result for duplicate ids", function()
	local ledger = Ledger.new(10)
	local first = Ledger.record(ledger, "transaction-0001", { ok = true, total = 25 })
	local inserted, duplicate = Ledger.record(ledger, "transaction-0001", { ok = true, total = 99 })
	equal(first, true); equal(inserted, false); equal(duplicate.total, 25)
end)

test("building placement accepts snapped coordinates within the shared build area", function()
	local ok = Placement.validate({ x = 32, z = -16 }, 0)
	equal(ok, true)
end)

test("building placement rejects off-grid and out-of-bounds coordinates", function()
	local offGrid, offGridCode = Placement.validate({ x = 3, z = 0 }, 0)
	local outside, outsideCode = Placement.validate({ x = 528, z = 0 }, 0)
	equal(offGrid, false); equal(offGridCode, "off_grid")
	equal(outside, false); equal(outsideCode, "outside_build_area")
end)

test("building placement enforces a company building cap", function()
	local ok, code = Placement.validate({ x = 0, z = 0 }, Placement.MAX_BUILDINGS)
	equal(ok, false); equal(code, "building_limit")
end)

test("planetary logistics transfer cargo only within route capacity", function()
	local source = Inventory.new({ IronOre = 20 })
	local destination = Inventory.new({})
	local ok = Operations.transfer(source, destination, "IronOre", 12, { enabled = true, capacityPerRun = 12 })
	equal(ok, true); equal(Inventory.get(source, "IronOre"), 8); equal(Inventory.get(destination, "IronOre"), 12)
end)

test("planetary logistics reject oversized transfers without losing cargo", function()
	local source = Inventory.new({ IronOre = 20 })
	local destination = Inventory.new({})
	local ok, code = Operations.transfer(source, destination, "IronOre", 13, { enabled = true, capacityPerRun = 12 })
	equal(ok, false); equal(code, "route_capacity"); equal(Inventory.get(source, "IronOre"), 20)
end)

test("planetary logistics enforce receiving facility storage capacity", function()
	local source = Inventory.new({ IronOre = 20 })
	local destination = Inventory.new({ IronOre = 10 })
	local ok, code = Operations.transfer(source, destination, "IronOre", 3, { enabled = true, capacityPerRun = 12, storageCapacity = 12 })
	equal(ok, false); equal(code, "destination_capacity"); equal(Inventory.get(source, "IronOre"), 20)
end)

test("exports convert products to shared credits and increase market supply", function()
	local inventory = Inventory.new({ Steel = 5, Credits = 10 })
	local market = { basePrice = 10, supply = 10, demand = 100 }
	local ok, result = Operations.export(inventory, market, "Steel", 2, 1)
	equal(ok, true); equal(result.total, result.unitPrice * 2)
	equal(Inventory.get(inventory, "Steel"), 3); equal(Inventory.get(inventory, "Credits"), 10 + result.total)
	equal(market.supply, 12)
end)

test("failed exports do not mutate cargo or market", function()
	local inventory = Inventory.new({ Steel = 1, Credits = 10 })
	local market = { basePrice = 10, supply = 10, demand = 100 }
	local ok = Operations.export(inventory, market, "Steel", 2, 1)
	equal(ok, false); equal(Inventory.get(inventory, "Steel"), 1); equal(market.supply, 10)
end)

print(string.format("%d tests passed", passed))
