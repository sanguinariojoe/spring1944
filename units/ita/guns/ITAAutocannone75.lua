local ITAAutocannone75 = Truck:New(AssaultGun):New{
	name				= "Autocannone da 75/27",
	description			= "Gun Truck",
	buildCostMetal		= 1403,
	maxDamage			= 270,
	trackOffset			= 5,
	trackWidth			= 19,

	weapons = {
		[1] = {
			name				= "ansaldo75mml27he",
			maxAngleDif			= 30,
		},
	},
	customParams = {
		maxammo				= 5,
		maxvelocitykmh		= 38,
		nomoveandfire		= true,
		normaltex			= "unittextures/ITAAutocannone75_normals.png",
	},
}

return lowerkeys({
	["ITAAutocannone75"] = ITAAutocannone75,
})
