local StuartBase = LightTank:New{
	maxDamage			= 1520,
	acceleration		= 0.054,
	trackOffset			= 5,
	trackWidth			= 18,
	trackType			= "USStuart",
	
	customParams = {
		armour = {
			base = {
				front = {
					thickness		= 29,
					slope			= 50,
				},
				rear = {
					thickness		= 25,
					slope			= -2,
				},
				side = {
					thickness 		= 29,
				},
				top = {
					thickness		= 13,
				},
			},
		},

		maxvelocitykmh		= 58,
	},
}	

local USM5Stuart = StuartBase:New{
	name				= "M5A1 Stuart",
	buildCostMetal		= 1725,

	weapons = {
		[1] = {
			name				= "M637mmAP",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[2] = {
			name				= "M637mmCanister",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[3] = {
			name				= "M637mmHE",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[4] = {
			name				= "M1919A4Browning",
		},
		[5] = {
			name				= "M2BrowningAA",
		},
		[6] = {
			name				= ".50calproof",
		},
	},
	customParams = {
		armour = {
			turret = {
				front = {
					thickness		= 44, -- not mantlet
					slope			= 13,
				},
				rear = {
					thickness		= 32,
					slope			= 2,
				},
				side = {
					thickness 		= 32,
					slope			= 1,
				},
				top = {
					thickness		= 13,
				},
			},
		},
		maxammo				= 27,
		weapontoggle		= false,
		turretturnspeed		= 25.7, -- 14s for 360
		normaltex			= "unittextures/USM5Stuart_normals.dds",
	},
}

local USM8Scott = StuartBase:New(AssaultGun):New{
	name				= "M8 Scott GMC",
	buildCostMetal		= 1785,
	
	weapons = {
		[1] = {
			name				= "M875mmHE",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[2] = {
			name				= "M2BrowningAA",
		},
		[3] = {
			name				= ".50calproof",
		},
	},
	customParams = {
		armour = {
			turret = {
				front = {
					thickness		= 38,
					slope			= 19,
				},
				rear = {
					thickness		= 25,
					slope			= 2,
				},
				side = {
					thickness 		= 25,
					slope			= 20,
				},
				top = {
					thickness		= 0,
				},
			},
		},
		maxammo				= 9,
		weapontoggle		= false,
		turretturnspeed		= 12, -- manual
		normaltex			= "unittextures/USM8Scott_normals.dds",
	},
}

return lowerkeys({
	["USM5Stuart"] = USM5Stuart,
	["USM8Scott"] = USM8Scott,
})
