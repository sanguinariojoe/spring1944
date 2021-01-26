local GERSdKfz10 = ArmouredCarAA:New{
	name				= "SdKfz 10/5",
	buildCostMetal		= 1275,
	maxDamage			= 499,
	trackOffset			= 10,
	trackWidth			= 19,

	weapons = {
		[1] = {
			name				= "flak3820mmaa",
		},
	},
	customParams = {
		armour = {
			base = {
				front = {
					thickness		= 11,
					slope			= 17,
				},
				rear = {
					thickness		= 0,
				},
				side = {
					thickness 		= 0,
				},
				top = {
					thickness		= 0,
				},
			},
			turret = {
				front = {
					thickness		= 7,
					slope			= 28,
				},
				rear = {
					thickness		= 0,
				},
				side = {
					thickness 		= 0,
				},
				top = {
					thickness		= 0,
				},
			},
		},
		maxammo				= 25,
		maxvelocitykmh		= 75,

		normaltex			= "unittextures/GERSdkfz10a_normals.png",
	}
}

return lowerkeys({
	["GERSdKfz10"] = GERSdKfz10,
})
