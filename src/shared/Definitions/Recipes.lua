--!strict
return {
	SmeltIron = {
		inputs = { IronOre = 3 }, outputs = { IronIngot = 2 }, durationSeconds = 10,
	},
	MakeSteel = {
		inputs = { IronIngot = 2 }, outputs = { Steel = 1 }, durationSeconds = 15,
	},
}
