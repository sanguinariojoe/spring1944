local HUN40MNimrod = ArmouredCarAA:New{
	name				= "40.M Nimrod",
	corpse				= "HUN40MNimrod_Burning",
	buildCostMetal			= 1912,
	maxDamage			= 1050,
	movementClass		= "TANK_Light",
	trackOffset			= 10,
	trackWidth			= 16,

	weapons = {
		[3] = { -- AA
			name				= "bofors40mmaa",
		},
		[2] = { -- HE
			name				= "bofors40mmhe",
		},
		[1] = { -- AP
			name				= "bofors40mmap",
		},
	},
	customParams = {
		hasturnbutton		= true,
		damageGroup		= "lightTanks",
		armour = {
			base = {
				front = {
					thickness		= 12,
					slope			= 60,
				},
				rear = {
					thickness		= 12,
					slope			= -33,
				},
				side = {
					thickness 		= 13,
					slope			= -15,
				},
				top = {
					thickness		= 6,
				},
			},
			turret = {
				front = {
					thickness		= 10,
					slope			= 24,
				},
				rear = {
					thickness		= 10,
					slope			= 24,
				},
				side = {
					thickness 		= 10,
					slope			= 24,
				},
				top = {
					thickness		= 0,
				},
			},
		},
		piecehitvols		= {
			turret = {
				scale = {1, 0.35, 1}, -- radio mast
				offset = {0, -1.5, 0},
			},
		},
		maxammo				= 19,
		maxvelocitykmh		= 50,
		weapontoggle		= "priorityAPHE",
		nomoveandfire		= true,
		normaltex			= "unittextures/HUN40MNimrod_normals.png",
	}
}

local HUN43MLehel = HalfTrack:New{
	name					= "43.M Lehel",
	buildCostMetal			= 900,
	corpse				= "HUN43MLehel_Abandoned",
	maxDamage				= 1020,
	trackOffset				= 10,
	trackWidth				= 15,
	transportCapacity		= 8,
	
	customParams = {
		armour = {
			base = {
				front = {
					thickness		= 12,
					slope			= 60,
				},
				rear = {
					thickness		= 12,
					slope			= -33,
				},
				side = {
					thickness 		= 13,
					slope			= -15,
				},
				top = {
					thickness		= 6,
				},
			},
			super = {
				front = {
					thickness		= 20,
					slope			= 27,
				},
				rear = {
					thickness		= 10,
					slope			= 23,
				},
				side = {
					thickness 		= 10,
					slope			= 25,
				},
				top = {
					thickness		= 0,
				},
			},
		},
		maxvelocitykmh			= 50,
		normaltex			= "unittextures/HUN43MLehel_normals.png",
	},
}

return lowerkeys({
	["HUN40MNimrod"] = HUN40MNimrod,
	["HUN43MLehel"] = HUN43MLehel,
})
