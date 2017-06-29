local RUST60 = Tankette:New{
	name				= "T-60/M41",
	buildCostMetal		= 1250,
	maxDamage			= 640,
	trackOffset			= 5,
	trackWidth			= 18,

	weapons = {
		[1] = {
			name				= "TNSh20mmAP",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[2] = {
			name				= "TNSh20mmHE",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[3] = {
			name				= "DT",
		},
		[4] = {
			name				= ".50calproof",
		},
	},
	customParams = {
		armor_front			= 31,
		armor_rear			= 28,
		armor_side			= 18,
		armor_top			= 10,
		maxammo				= 36,
		maxvelocitykmh		= 44,
		killvoicecategory_hardveh	= "RUS/Tank/RUS_TANK_TANKKILL",
		killvoicephasecount		= 3,
		normaltex			= "unittextures/RUST60_normals.dds",
	},
}

return lowerkeys({
	["RUST60"] = RUST60,
})
