local GERPuma = HeavyArmouredCar:New{
	name				= "Sd.Kfz. 234/2 Puma",
	acceleration		= 0.043,
	brakeRate			= 0.11,
	buildCostMetal		= 1700,
	maxDamage			= 1174,
	trackOffset			= 10,
	trackWidth			= 13,
	turnRate			= 405,

	weapons = {
		[1] = {
			name				= "kwk50mml60ap",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[2] = {
			name				= "kwk50mml60he",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[3] = {
			name				= "MG34",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[4] = {
			name				= ".30calproof",
		},
	},
	customParams = {
		armor_front			= 37,
		armor_rear			= 11,
		armor_side			= 10,
		armor_top			= 8,
		maxammo				= 10,
		weaponcost			= 10,
		weaponswithammo		= 2,
		reversemult			= 0.75,
		maxvelocitykmh		= 80,
	}
}

return lowerkeys({
	["GERPuma"] = GERPuma,
})
