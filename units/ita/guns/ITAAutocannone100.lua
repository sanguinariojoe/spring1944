local ITAAutocannone100 = Truck:New(SPArty):New{
	name				= "Autocannone da 100/17",
	buildCostMetal		= 3750,
	maxDamage			= 650,
	trackOffset			= 5,
	trackWidth			= 19,

	weapons = {
		[1] = {
			name				= "Obice100mmL17HE",
		},
	},
	customParams = {
		maxammo				= 8,
		weaponcost			= 25,
		maxvelocitykmh		= 45,
	},
}

return lowerkeys({
	["ITAAutocannone100"] = ITAAutocannone100,
})
