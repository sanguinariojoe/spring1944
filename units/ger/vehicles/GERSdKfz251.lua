local GERSdKfz251 = HalfTrack:New{
	name					= "SdKfz 251/1 Halftrack",
	buildCostMetal			= 1100,
	maxDamage				= 850,
	trackOffset				= 10,
	trackWidth				= 15,
	transportCapacity		= 10,
	
	weapons = {
		[1] = {
			name					= "MG34",
			maxAngleDif				= 90,
		},
		[2] = {
			name					= "MG34",
			maxAngleDif			= 180,
			mainDir				= [[0 0 -1]],
		},
	},
	
	customParams = {
		armour = {
			base = {
				front = {
					thickness		= 9,
					slope			= 18,
				},
				rear = {
					thickness		= 9,
					slope			= -30,
				},
				side = {
					thickness 		= 10,
					slope			= 35,
				},
				top = {
					thickness		= 0,
				},
			},
		},

		maxvelocitykmh		= 52.5,
		normaltex			= "unittextures/GERSdkfz251_normals.png",
	},
	
}

return lowerkeys({
	["GERSdKfz251"] = GERSdKfz251,
})
