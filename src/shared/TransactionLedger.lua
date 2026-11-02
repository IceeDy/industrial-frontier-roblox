--!strict
local Ledger = {}

function Ledger.new(maxEntries)
	return { results = {}, order = {}, maxEntries = maxEntries or 500 }
end

function Ledger.get(ledger, transactionId)
	return ledger.results[transactionId]
end

function Ledger.record(ledger, transactionId, result)
	assert(type(transactionId) == "string" and #transactionId >= 8 and #transactionId <= 128, "invalid transaction id")
	if ledger.results[transactionId] ~= nil then return false, ledger.results[transactionId] end
	ledger.results[transactionId] = result
	table.insert(ledger.order, transactionId)
	while #ledger.order > ledger.maxEntries do
		local expired = table.remove(ledger.order, 1)
		ledger.results[expired] = nil
	end
	return true, result
end

return Ledger
