local Inventory = require("../src/shared/Inventory")
local Production = require("../src/shared/Production")
local Economy = require("../src/shared/Economy")
local Ledger = require("../src/shared/TransactionLedger")

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

print(string.format("%d tests passed", passed))
