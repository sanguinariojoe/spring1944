local StrvM42Base = {
	maxDamage			= 2250,
	trackOffset			= 5,
	trackWidth			= 20,


	customParams = {
		armor_front			= 64,
		armor_rear			= 23,
		armor_side			= 30,
		armor_top			= 9,

	},
}

local SWEStrvM42 = MediumTank:New(StrvM42Base):New{
	name				= "Stridsvagn m/42",
	buildCostMetal		= 2400,
	weapons = {
		[1] = {
			name				= "SWE75mmL34AP",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[2] = {
			name				= "SWE75mmL34HE",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[3] = { -- coax 1
			name				= "ksp_m1939",
		},
		[4] = { -- coax 2
			name				= "ksp_m1939",
		},
		[5] = { -- back turret
			name				= "ksp_m1939",
		},
		[6] = { -- hull
			name				= "ksp_m1939",
			maxAngleDif			= 50,
		},
		[7] = {
			name				= ".50calproof",
		},
	},
	customParams = {
		maxammo				= 15,
		maxvelocitykmh		= 42,
	},
}

local SWEBBVM42 = EngineerVehicle:New(MediumTank):New(StrvM42Base):New{
	name				= "B�rgningsbandvagn m/42",
	category			= "HARDVEH", -- don't trigger mines
}

return lowerkeys({
	["SWEStrvM42"] = SWEStrvM42,
	["SWEBBVM42"] = SWEBBVM42,
})
