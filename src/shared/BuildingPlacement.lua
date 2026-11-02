--!strict
local Placement = {}

Placement.GRID_SIZE = 16
Placement.WORLD_LIMIT = 512
Placement.MAX_BUILDINGS = 50

function Placement.validate(position, count)
	if type(position) ~= "table" or type(position.x) ~= "number" or type(position.z) ~= "number" then
		return false, "invalid_position"
	end
	if position.x ~= position.x or position.z ~= position.z or math.abs(position.x) > Placement.WORLD_LIMIT or math.abs(position.z) > Placement.WORLD_LIMIT then
		return false, "outside_build_area"
	end
	if position.x % Placement.GRID_SIZE ~= 0 or position.z % Placement.GRID_SIZE ~= 0 then
		return false, "off_grid"
	end
	if type(count) ~= "number" or count < 0 or count % 1 ~= 0 or count >= Placement.MAX_BUILDINGS then
		return false, "building_limit"
	end
	return true
end

return Placement
