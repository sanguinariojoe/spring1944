local ChiHaBase = LightTank:New{
	maxDamage			= 1580,
	trackOffset			= 5,
	trackWidth			= 14,
	
	customParams = {
		armour = {
			base = {
				front = {
					thickness		= 25,
					slope			= 31,
				},
				rear = {
					thickness		= 20,
					slope			= 25,
				},
				side = {
					thickness 		= 25,
					slope			= 40,
				},
				top = {
					thickness		= 11,
				},
			},
			turret = {
				front = {
					thickness		= 32,
					slope			= 12,
				},
				rear = {
					thickness		= 25,
					slope			= 12,
				},
				side = {
					thickness 		= 25,
					slope			= 10,
				},
				top = {
					thickness		= 11,
				},
			},
		},
		maxvelocitykmh		= 38,
		exhaust_fx_name			= "diesel_exhaust",

	},
}
	
local JPNChiHa = ChiHaBase:New{
	name				= "Type 97 Chi-Ha",
	buildCostMetal		= 1600,
	
	weapons = {
		[1] = {
			name				= "Type9757mmAP",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[2] = {
			name				= "Type9757mmHE",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[3] = { -- bow MG
			name				= "Type97MG",
            maxAngleDif			= 50,
		},
		[4] = { -- rear turret MG
			name				= "Type97MG",
            mainDir				= [[0 16 -1]],
            maxAngleDif			= 210,
		},
		[5] = {
			name				= ".50calproof",
		},
	},
	
	customParams = {
		maxammo				= 20,
		normaltex			= "unittextures/JPNChiHa_normals.png",
	},
}	

local JPNChiHa120mm = ChiHaBase:New{
	name				= "Type 97 Chi-Ha",
	description			= "Close Support Tank",
	buildCostMetal		= 2650,
	
	weapons = {
		[1] = {
			name				= "Short120mmHE",
			mainDir				= [[0 16 1]],
			maxAngleDif			= 210,
		},
		[2] = { -- bow MG
			name				= "Type97MG",
		},
		[3] = {
			name				= ".50calproof",
		},
	},
	
	customParams = {
		maxammo				= 5,
		normaltex			= "unittextures/JPNChiHa120mm_normals.png",
	},
}

local JPNShinhotoChiHa = JPNChiHa:New{ -- just change the gun
	name				= "Type 97 Shinhoto Chi-Ha",
	description			= "Upgunned Medium Tank",
	buildCostMetal		= 1750,
	
	weapons = {
		[1] = {
			name				= "Type147mmAP",
		},
		[2] = {
			name				= "Type147mmHE",
		},
	},
	
	customParams = {
		armour = {
			turret = {
				front = {
					thickness		= 32,
					slope			= 9,
				},
				rear = {
					slope			= 0,
				},
			},
		},
		maxammo				= 15,
		normaltex			= "unittextures/JPNShinhotoChiHa_normals.png",
	},
}	

return lowerkeys({
	["JPNChiHa"] = JPNChiHa,
	["JPNChiHa120mm"] = JPNChiHa120mm,
	["JPNShinhotoChiHa"] = JPNShinhotoChiHa,
})
