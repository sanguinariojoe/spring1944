-- Author: Jose Luis Cercos-Pita
-- License: GNU General Public License v3

gadget.config = {
    map = "1944_Cooper_Hill_v3",
    teams = {
        [1] = { -- Player
            ally = 0,
            units = { -- Leave empty to use the default ones
                [1] = {unit = "us_platoon_rifle",
                       pos = {900, 0, 1500},
                       facing = "east",
                },
            },
        },
        [2] = {
            ally = 1,
            units = { -- Leave empty to use the default ones
                [1] = {unit = "gerpanzeriii",
                       pos = {3200, 0, 1500},
                       facing = "west",
                },
            },
        },
    }    
}
