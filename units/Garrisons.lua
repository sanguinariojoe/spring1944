local HouseMansion_garrison = Garrison:New{
    name              = "Mansion (Garrison)",
    description       = "Large Garrison for infantry",
    objectName        = "GEN/HouseMansion_garrison.dae",
    footprintX        = 10,  -- 1 footprint unit = 16 elmo
    footprintZ        = 9,  -- 1 footprint unit = 16 elmo
    buildCostMetal    = 10000,
    maxDamage         = 5000,
    transportCapacity = 40,
    transportMass     = 2000,
    customParams = {
        mod       = true,
        normaltex = "unittextures/FeaturesHouseMansion_normals.png",
    },
}

return lowerkeys({
    ["Garrison_HouseMansion"] = HouseMansion_garrison,
})
