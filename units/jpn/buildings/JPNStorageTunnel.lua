local JPN_StorageTunnel = Storage:New{
	name					= "Storage & Supply Tunnel",
	description				= "General Logistics & Ammunition Stockpile, also provides logistics income",
	energyMake				= 2.3,
	customParams = {
		normaltex			= "unittextures/JPNStorage_normals.png",
	},
}

return lowerkeys({
	["JPNStorageTunnel"] = JPN_StorageTunnel,
})
