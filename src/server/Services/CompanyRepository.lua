--!strict
local Repository = {}
Repository.__index = Repository

function Repository.new(adapter)
	return setmetatable({ adapter = adapter }, Repository)
end

function Repository:save(companyId, inventory, revision)
	assert(type(companyId) == "string" and companyId:match("^[%w_-]+$") and #companyId <= 40, "invalid company id")
	assert(type(revision) == "number" and revision >= 1 and revision % 1 == 0, "invalid revision")
	return self.adapter:update("company_" .. companyId, function(previous)
		previous = previous or { schemaVersion = 1, revision = 0, inventory = {} }
		if previous.schemaVersion ~= 1 or revision <= previous.revision then return previous end
		return { schemaVersion = 1, revision = revision, inventory = table.clone(inventory) }
	end)
end

return Repository
