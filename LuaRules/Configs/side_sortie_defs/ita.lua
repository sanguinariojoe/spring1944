local itaSorties = {
	ita_sortie_recon = {
		members = {
			"itaro37",
		},
		delay = 15,
		name = "Recon Sortie",
		description = "1 x Ro.37",
		buildCostMetal = 1000,
		buildPic = "itaro37.png",
	},
	ita_sortie_attack = {
		members = {
			"itamc200",
			"itamc200",
		},
		weight = 1,
		delay = 30,
		name = "Ground-Attack Sortie",
		description = "2 x Macchi C 200 armed with anti-tank Bomblets",
		buildCostMetal = 4500,
		buildPic = "itamc200.png",
	},
	ita_sortie_light_attack = {
		members = {
			"itafiatcr42",
			"itafiatcr42",
		},
		weight = 1,
		delay = 30,
		name = "Light Ground-Attack Sortie",
		description = "2 x Fiat Cr.42 armed with anti-personel Bomblets",
		buildCostMetal = 2800,
		buildPic = "itafiatcr42.png",
	},
	ita_sortie_fighter = {
		members = {
			"itareggiane2005",
			"itareggiane2005",
			"itareggiane2005",
			"itareggiane2005",
		},
		weight = 1,
		delay = 30,
		name = "Air Superiority Fighter Sortie",
		description = "4 x Reggiane Re.2005",
		buildCostMetal = 4400,
		buildPic = "itareggiane2005.png",
	},
	ita_sortie_interceptor = {
		members = {
			"itamc202",
			"itamc202",
			"itamc202",
			"itamc202",
		},
		weight = 1,
		delay = 15,
		name = "Interceptor Sortie",
		description = "4 x MC.202",
		buildCostMetal = 3800,
		buildPic = "ITAMC202.png",
	},
	ita_sortie_fighter_bomber = {
		members = {
			"itamc205",
			"itamc205",
		},
		delay = 45,
		weight = 1,
		name = "Fighter-Bomber Sortie",
		description = "2 x MC.205",
		buildCostMetal = 6750,
		buildPic = "itamc205.png",
	},
}

return itaSorties
