--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local requestSnapshot = remotes:WaitForChild("RequestSnapshot")
local submitAction = remotes:WaitForChild("SubmitAction")
local snapshotUpdated = remotes:WaitForChild("SnapshotUpdated")
local buildings = require(ReplicatedStorage.Shared.Definitions.Buildings)

local palette = {
	background = Color3.fromRGB(19, 25, 31),
	panel = Color3.fromRGB(31, 41, 49),
	button = Color3.fromRGB(48, 66, 76),
	accent = Color3.fromRGB(68, 158, 156),
	text = Color3.fromRGB(235, 239, 235),
	muted = Color3.fromRGB(167, 181, 184),
}

local gui = Instance.new("ScreenGui")
gui.Name = "PlanetNavigation"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local window = Instance.new("Frame")
window.Name = "OperationsWindow"
window.AnchorPoint = Vector2.new(0, 0.5)
window.Position = UDim2.new(0, 20, 0.5, 0)
window.Size = UDim2.new(0, 430, 0, 540)
window.BackgroundColor3 = palette.background
window.BorderSizePixel = 0
window.Parent = gui

local function makeLabel(parent, text, position, size, color, fontSize)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = color or palette.text
	label.TextSize = fontSize or 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local title = makeLabel(window, "FRONTIER OPERATIONS", UDim2.new(0, 18, 0, 12), UDim2.new(1, -36, 0, 28), palette.text, 18)
title.Font = Enum.Font.GothamBold
local planetBar = Instance.new("Frame")
planetBar.Position = UDim2.new(0, 14, 0, 48)
planetBar.Size = UDim2.new(1, -28, 0, 42)
planetBar.BackgroundTransparency = 1
planetBar.Parent = window

local tabBar = Instance.new("Frame")
tabBar.Position = UDim2.new(0, 14, 0, 96)
tabBar.Size = UDim2.new(1, -28, 0, 36)
tabBar.BackgroundTransparency = 1
tabBar.Parent = window

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.new(0, 14, 0, 140)
content.Size = UDim2.new(1, -28, 1, -154)
content.BackgroundColor3 = palette.panel
content.BorderSizePixel = 0
content.ScrollBarThickness = 6
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.Parent = window

local state = { snapshot = nil, planetId = nil, tab = "Overview", sourceId = "company_inventory", destinationId = nil, routeId = nil, notice = "Connecting to the company network..." }
local redraw

local function makeButton(parent, text, position, size, callback, color)
	local button = Instance.new("TextButton")
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color or palette.button
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = palette.text
	button.TextSize = 13
	button.TextWrapped = true
	button.Parent = parent
	button.Activated:Connect(callback)
	return button
end

local function makeInput(parent, placeholder, position, size, initial)
	local input = Instance.new("TextBox")
	input.Position = position
	input.Size = size
	input.BackgroundColor3 = palette.background
	input.BorderSizePixel = 0
	input.ClearTextOnFocus = false
	input.Font = Enum.Font.Gotham
	input.PlaceholderText = placeholder
	input.Text = initial or ""
	input.TextColor3 = palette.text
	input.PlaceholderColor3 = palette.muted
	input.TextSize = 14
	input.Parent = parent
	return input
end

local function send(action, fields)
	local payload = fields or {}
	payload.action = action
	payload.transactionId = HttpService:GenerateGUID(false)
	submitAction:FireServer(payload)
	state.notice = "Order sent to server..."
	if redraw then redraw() end
end

local function refresh()
	local ok, result = pcall(function() return requestSnapshot:InvokeServer() end)
	if ok and result and result.ok then
		state.snapshot = result
		if not state.planetId then
			local ids = {}
			for id in pairs(result.planets or {}) do table.insert(ids, id) end
			table.sort(ids)
			state.planetId = ids[1]
		end
		state.notice = "Company data synchronized."
	else
		state.notice = "Could not load the company snapshot."
	end
	if redraw then redraw() end
end

local function drawPlanetButtons()
	planetBar:ClearAllChildren()
	local planets = state.snapshot and state.snapshot.planets or {}
	local ids = {}
	for id in pairs(planets) do table.insert(ids, id) end
	table.sort(ids, function(a, b) return planets[a].displayName < planets[b].displayName end)
	local barWidth = math.max(400, planetBar.AbsoluteSize.X)
	local width = #ids > 0 and math.floor((barWidth - (#ids - 1) * 6) / #ids) or 120
	for index, id in ipairs(ids) do
		local selected = state.planetId == id
		makeButton(planetBar, planets[id].displayName, UDim2.new(0, (index - 1) * (width + 6), 0, 0), UDim2.new(0, width, 1, 0), function()
			state.planetId = id
			redraw()
		end, selected and palette.accent or palette.button)
	end
end

local function drawTabs()
	tabBar:ClearAllChildren()
	local tabs = { "Overview", "Build", "Production", "Logistics", "Trade" }
	local width = math.floor((math.max(400, tabBar.AbsoluteSize.X) - 18) / #tabs)
	for index, tab in ipairs(tabs) do
		makeButton(tabBar, tab, UDim2.new(0, (index - 1) * (width + 6), 0, 0), UDim2.new(0, width, 1, 0), function()
			state.tab = tab
			redraw()
		end, state.tab == tab and palette.accent or palette.button)
	end
end

redraw = function()
	drawPlanetButtons()
	drawTabs()
	content:ClearAllChildren()
	local y = 12
	local function line(text, height, color, size)
		makeLabel(content, text, UDim2.new(0, 14, 0, y), UDim2.new(1, -28, 0, height), color, size)
		y += height + 7
	end
	local function actionButton(text, callback, height)
		local buttonHeight = height or 36
		makeButton(content, text, UDim2.new(0, 14, 0, y), UDim2.new(1, -28, 0, buttonHeight), callback)
		y += buttonHeight + 7
	end
	local snapshot = state.snapshot
	local planets = snapshot and snapshot.planets or {}
	local planet = state.planetId and planets[state.planetId]
	if not snapshot then
		line(state.notice, 50, palette.muted, 14)
		content.CanvasSize = UDim2.new(0, 0, 0, y)
		return
	end
	if not planet then
		line("No planetary data is available.", 42, palette.muted, 14)
		content.CanvasSize = UDim2.new(0, 0, 0, y)
		return
	end
	line(planet.displayName .. "  |  " .. planet.biome, 30, palette.text, 18)
	line(planet.description, 42, palette.muted, 13)
	if state.tab == "Overview" then
		line("Shared inventory", 24, palette.text, 15)
		for resourceId, amount in pairs(snapshot.inventory or {}) do line(resourceId .. "     " .. tostring(amount), 22, palette.muted, 13) end
		line("Facilities on this planet", 24, palette.text, 15)
		local count = 0
		for _, building in ipairs(snapshot.buildings or {}) do
			if building.planetId == state.planetId then
				count += 1
				line(building.buildingId .. "  ·  " .. building.id, 28, palette.muted, 12)
			end
		end
		if count == 0 then line("No facilities yet.", 24, palette.muted, 13) end
		line("Active logistics links: " .. tostring(#(snapshot.routes or {})), 24, palette.muted, 13)
	elseif state.tab == "Build" then
		line("Choose a facility to place on " .. planet.displayName .. ".", 38, palette.muted, 13)
		for buildingId, definition in pairs(buildings) do
			local costs = {}
			for resourceId, amount in pairs(definition.buildCost) do table.insert(costs, tostring(amount) .. " " .. resourceId) end
			table.sort(costs)
			actionButton(definition.displayName .. "  ·  " .. table.concat(costs, ", "), function()
				local count = 0
				for _, building in ipairs(snapshot.buildings or {}) do if building.planetId == state.planetId then count += 1 end end
				local x = (count % 12) * 16
				local z = math.floor(count / 12) * 16
				send("build", { buildingId = buildingId, planetId = state.planetId, position = { x = x, z = z } })
			end)
		end
	elseif state.tab == "Production" then
		line("Run a recipe at one of this planet's facilities.", 38, palette.muted, 13)
		for _, building in ipairs(snapshot.buildings or {}) do
			local definition = buildings[building.buildingId]
			if building.planetId == state.planetId and definition and definition.recipeId then
				actionButton(definition.displayName .. "  ·  " .. definition.recipeId, function()
					send("produce", { buildingId = building.id, recipeId = definition.recipeId, cycles = 1 })
				end)
			end
		end
	elseif state.tab == "Logistics" then
		line("Route endpoints", 24, palette.text, 15)
		line("Source: " .. tostring(state.sourceId), 24, palette.muted, 13)
		line("Destination: " .. tostring(state.destinationId or "select a facility"), 24, palette.muted, 13)
		actionButton("Use shared company inventory as source", function() state.sourceId = "company_inventory"; redraw() end)
		for _, building in ipairs(snapshot.buildings or {}) do
			if building.planetId == state.planetId then
				actionButton("Select " .. building.buildingId .. " as source", function() state.sourceId = building.id; redraw() end)
				actionButton("Select " .. building.buildingId .. " as destination", function() state.destinationId = building.id; redraw() end)
			end
		end
		actionButton("Use shared company inventory as destination", function() state.destinationId = "company_inventory"; redraw() end)
		local resource = makeInput(content, "Resource ID, e.g. IronOre", UDim2.new(0, 14, 0, y), UDim2.new(1, -28, 0, 34), "IronOre")
		y += 41
		actionButton("Create route", function()
			if state.destinationId then send("connect_route", { sourceId = state.sourceId, destinationId = state.destinationId, resourceId = resource.Text }) end
		end)
		for _, route in ipairs(snapshot.routes or {}) do
			if route.planetId == state.planetId then
				actionButton((route.resourceId or "cargo") .. " route  ·  " .. route.sourceId .. " → " .. route.destinationId, function() state.routeId = route.id; redraw() end)
			end
		end
		line("Selected route: " .. tostring(state.routeId or "none"), 24, palette.muted, 12)
		local quantity = makeInput(content, "Quantity", UDim2.new(0, 14, 0, y), UDim2.new(1, -28, 0, 34), "10")
		y += 41
		actionButton("Transfer cargo on selected route", function()
			if state.routeId then send("transfer", { routeId = state.routeId, quantity = tonumber(quantity.Text) }) end
		end)
	else
		line("Shared market", 24, palette.text, 15)
		for resourceId, amount in pairs(snapshot.inventory or {}) do
			if resourceId ~= "Credits" and amount > 0 then
				actionButton("Export " .. resourceId .. "  ·  available " .. tostring(amount), function()
					send("export", { resourceId = resourceId, quantity = math.min(amount, 10) })
				end)
			end
		end
		line("Exports sell from the shared company inventory.", 34, palette.muted, 12)
	end
	line(state.notice, 30, palette.muted, 12)
	content.CanvasSize = UDim2.new(0, 0, 0, y + 12)
end

snapshotUpdated.OnClientEvent:Connect(function(message)
	if type(message) == "table" and message.kind ~= "snapshot" then
		local result = message.result
		if type(result) == "table" and result.ok ~= nil then
			state.notice = result.ok and "Server accepted the operation." or ("Server rejected it: " .. tostring(result.code or "unknown error"))
		elseif message.ok ~= nil then
			state.notice = message.ok and "Server accepted the operation." or ("Server rejected it: " .. tostring(result or "unknown error"))
		else
			state.notice = "Server returned an update."
		end
		redraw()
		task.delay(0.7, refresh)
	end
end)

task.defer(refresh)
