--!strict
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Adapter = {}
Adapter.__index = Adapter

function Adapter.new(storeName, options)
	options = options or {}
	local prefix = options.keyPrefix or "dev_v1_"
	assert(not RunService:IsStudio() or options.allowStudio == true, "DataStore disabled in Studio unless explicitly enabled for a test universe")
	local ok, store = pcall(function() return DataStoreService:GetDataStore(storeName) end)
	assert(ok and store, "DataStore unavailable")
	return setmetatable({ store = store, prefix = prefix, maxAttempts = options.maxAttempts or 3 }, Adapter)
end

function Adapter:update(key, transform)
	assert(type(key) == "string" and #key <= 50, "invalid key")
	local attempt, lastError = 0, nil
	while attempt < self.maxAttempts do
		attempt += 1
		local ok, result = pcall(function()
			return self.store:UpdateAsync(self.prefix .. key, transform)
		end)
		if ok then return true, result end
		lastError = result
		task.wait(math.min(0.25 * (2 ^ (attempt - 1)), 2))
	end
	return false, lastError
end

return Adapter
