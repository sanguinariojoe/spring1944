local HUN_31M_105mm = HInfGun:New{
	name					= "105mm 31M Tábori Ágyú",
	corpse					= "hun31m_105mm_destroyed",
	buildCostMetal			= 3200,

	transportCapacity		= 4,
	transportMass			= 200,

	collisionVolumeType		= "box",
	collisionVolumeScales	= {16.0, 10.0, 4.0},
	collisionVolumeOffsets	= {0.0, 7.0, 2.0},

	weapons = {
		[1] = { -- HE
			name				= "m31_105mmHE",
		},
		[2] = { -- Smoke
			name				= "m31_105mmSmoke",
		},
	},
	customParams = {
		normaltex			= "unittextures/HUN31M_105mm_normals.png",
	},
}

local HUN_31M_105mm_Stationary = HGun:New{
	name					= "Deployed 105mm 31M Tábori Ágyú",
	corpse					= "hun31m_105mm_destroyed",

	weapons = {
		[1] = { -- HE
			name				= "m31_105mmHE",
		},
		[2] = { -- Smoke
			name				= "m31_105mmSmoke",
		},
	},
	customParams = {
		normaltex			= "unittextures/HUN31M_105mm_normals.png",
	},
}

return lowerkeys({
	["HUN31M_105mm"] = HUN_31M_105mm,
	["HUN31M_105mm_Stationary"] = HUN_31M_105mm_Stationary,
})
