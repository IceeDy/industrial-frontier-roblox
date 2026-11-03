--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Definitions = require(ReplicatedStorage.Shared.Remotes)
local EconomyService = require(script.Services.EconomyService)
local ProductionService = require(script.Services.ProductionService)
local BuildingService = require(script.Services.BuildingService)
local LogisticsService = require(script.Services.LogisticsService)
local Planets = require(ReplicatedStorage.Shared.Definitions.Planets)
local RateLimiter = require(script.Services.RateLimiter)

local remoteRoot = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remoteRoot.Name = "Remotes"
remoteRoot.Parent = ReplicatedStorage

local remotes = {}
for name, definition in pairs(Definitions) do
	local remote = remoteRoot:FindFirstChild(name)
	if not remote then remote = Instance.new(definition.className); remote.Name = name; remote.Parent = remoteRoot end
	assert(remote.ClassName == definition.className, "remote class mismatch: " .. name)
	remotes[name] = remote
end

local economy = EconomyService.new()
local building = BuildingService.new(economy)
local production = ProductionService.new(economy, building)
local logistics = LogisticsService.new(building, economy.ledger, economy.companyInventory)
local limiter = RateLimiter.new()
local function validId(value)
	return type(value) == "string" and #value >= 8 and #value <= 80 and value:match("^[%w%-_]+$") ~= nil
end

remotes.RequestSnapshot.OnServerInvoke = function(player)
	if not limiter:allow(player.UserId, "snapshot", 2, 1) then return { ok = false, code = "rate_limited" } end
	return { ok = true, inventory = table.clone(economy.companyInventory.items), buildings = building:getSnapshot(), routes = logistics:getSnapshot(), planets = Planets }
end

remotes.SubmitAction.OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" or not validId(payload.transactionId) then return end
	if not limiter:allow(player.UserId, "action", 5, 1) then return end
	if payload.action == "buy" then
		local result = economy:buy(payload.transactionId, payload.resourceId, payload.quantity, player.UserId)
		remotes.SnapshotUpdated:FireAllClients({ kind = "transaction", result = result })
	elseif payload.action == "export" then
		local result = economy:export(payload.transactionId, payload.resourceId, payload.quantity, player.UserId)
		remotes.SnapshotUpdated:FireAllClients({ kind = "export", result = result })
	elseif payload.action == "produce" and type(payload.recipeId) == "string" then
		local ok, result = production:run(payload.transactionId, payload.recipeId, payload.cycles, player.UserId, payload.buildingId)
		remotes.SnapshotUpdated:FireAllClients({ kind = "production", ok = ok, result = result })
	elseif payload.action == "build" and type(payload.buildingId) == "string" and type(payload.position) == "table" then
		local ok, result = building:place(payload.transactionId, payload.buildingId, payload.planetId, payload.position, player.UserId)
		remotes.SnapshotUpdated:FireAllClients({ kind = "building", ok = ok, result = result })
	elseif payload.action == "connect_route" then
		local ok, result = logistics:connect(payload.transactionId, payload.sourceId, payload.destinationId, payload.resourceId, player.UserId)
		remotes.SnapshotUpdated:FireAllClients({ kind = "route", ok = ok, result = result })
	elseif payload.action == "transfer" then
		local ok, result = logistics:transfer(payload.transactionId, payload.routeId, payload.quantity, player.UserId)
		remotes.SnapshotUpdated:FireAllClients({ kind = "transfer", ok = ok, result = result })
	end
end)

Players.PlayerAdded:Connect(function(player)
	remotes.SnapshotUpdated:FireClient(player, { kind = "snapshot", inventory = table.clone(economy.companyInventory.items), buildings = building:getSnapshot(), routes = logistics:getSnapshot(), planets = Planets })
end)
