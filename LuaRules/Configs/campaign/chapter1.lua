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

gadget.mission = {
    [1] = {
        events = {  -- Ensure they are sorted in time
            [1] = {0, [[MessageToPlayer("Commander, welcome to Spring-1944!")]]}
        }

        success = {
            condition = {"delay", 1},
            message = "Commander, welcome to Spring-1944!",
        },
        fail = {
            condition = {"teamDied", 1},
            message = "Commander, you are out of control!",
        }
    }
}
