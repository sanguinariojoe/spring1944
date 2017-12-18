
-- spam_config.lua

-- s44 spam configuration file

return {
    max_units = 100, -- Maximum amount of units a ai instance will have at once
    wait = 600, -- Time before the ai begins its attack
    metal_storage = 10000, -- Metal storage
    energy_storage = 10000, -- Energy storage
    metal_income = 25, -- Its nominal metal income
    energy_income = 25, -- Its nominal energy income
    hq_build_speed = 250, --
    hq_hp = 250000, -- Initial health of the spam hq
    hq_bonus_multiplier = 2, --
    hq_los = 512,
    hq_range = 1024, -- Range of all 4 lasers
    hq_damage = 100, -- Damage for each of the 4 lasers with beamtime 0.25 and reload time 1.0
    unit_hp_multiplier = 0.25,
    unit_los_multiplier = 0.25,
    warning = "Ready or not here they come!",

    build_order = {{"gbrrifle", 116}, -- First entry is the unit name to be produced and the later is the likelyhood of it spawning
                   {"rusppsh", 88},
                   {"germg42", 67},
                   {"usbazooka", 43},
                   {"gbrstaghound", 86},
                   {"usflamethrower", 59},
                   {"gersdkfz250", 79},
                   {"gerpuma", 71},
                   {"jpnhago", 62},
                   {"rusvalentine", 56},
                   {"gbrcommando", 45},
                   {"itasemovente90", 39},
                   {"uslvta4", 35},
                   {"usm7priest", 29},
                   {"swestrvm41", 25},
                   {"hunhetzer", 16},
                   {"rusisu152", 9},
                   {"usm4a3105sherman", 12},
                   {"rust3485", 3},
                   {"gertigerii", 1},
    }
}