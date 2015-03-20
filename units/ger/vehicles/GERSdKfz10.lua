local GERSdKfz10 = TruckAA:New{
	name				= "SdKfz 10/5",
	acceleration		= 0.067,
	brakeRate			= 0.195,
	buildCostMetal		= 1275,
	maxDamage			= 499,
	trackOffset			= 10,
	trackWidth			= 19,
	turnRate			= 405,

	weapons = {
		[1] = {
			name				= "flak3820mmaa",
		},
	},
	customParams = {
		armor_front			= 11,
		armor_rear			= 0,
		armor_side			= 0,
		armor_top			= 0,
		maxammo				= 25,
		weaponcost			= 2,
		weaponswithammo		= 1,
		maxvelocitykmh		= 75,
	}
}

return lowerkeys({
	["GERSdKfz10"] = GERSdKfz10,
})
