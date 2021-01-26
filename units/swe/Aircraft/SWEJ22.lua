local SWE_J22 = Fighter:New{
	name				= "FFVS J 22B",
	description			= "Interceptor",
	buildCostMetal		= 1125,
	maxDamage			= 283.5,
		
	maxAcc				= 0.790,
	maxAileron			= 0.0055,
	maxBank				= 1,
	maxElevator			= 0.0043,
	maxPitch			= 1,
	maxRudder			= 0.0035,
	maxVelocity			= 23,
	
	customParams = {
		enginesound			= "yakb-",
		enginesoundnr		= 20,
		normaltex			= "unittextures/SWEJ22_normals.png",
	},

	weapons = {
		[1] = {
			name				= "m2browningamg",
			maxAngleDif			= 10,
		},
		[2] = {
			name				= "m2browningamg",
			maxAngleDif			= 10,
			slaveTo				= 2,
		},	
		[3] = {
			name				= "m2browningamg",
			maxAngleDif			= 10,
			slaveTo				= 2,
		},
		[4] = {
			name				= "m2browningamg",
			maxAngleDif			= 10,
			slaveTo				= 2,
		},
	},
}


return lowerkeys({
	["SWEJ22"] = SWE_J22,
})
