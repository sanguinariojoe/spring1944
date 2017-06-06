-- Author: Jose Luis Cercos-Pita
-- License: GNU General Public License v3

gadget.config = {
    map = "1944_Cooper_Hill_v3",
    teams = {
        [1] = { -- Player
            ally = 0,
            faction = "us",
            units = { -- Leave empty to use the default ones
                [1] = {unit = "usbarracks",
                       pos = {2050, 206, 150},
                       facing = "s",
                },
                [2] = {unit = "usstorage",
                       pos = {1600, 205, 125},
                       facing = "s",
                },
            },
        },
        [2] = {
            ally = 1,
            faction = "ger",
            units = { -- Leave empty to use the default ones
                [1] = {unit = "gerpanzeriii",
                       pos = {3200, 0, 1500},
                       facing = "west",
                },
            },
        },
    },
    sun = { -- SetSunDirection seems to don't work
        dir = {1.0, 0.4, 0.1},
        -- Dawn
        -- ambient = {0.5, 0.3, 0.15},
        -- diffuse = {0.7, 0.4, 0.2},
        -- specular = {0.1, 0.05, 0.025},
        -- Day
        ambient = {0.5, 0.5, 0.5},
        diffuse = {0.7, 0.65, 0.65},
        specular = {0.1, 0.1, 0.1},
        -- Night
        -- ambient = {0.3, 0.3, 0.6},
        -- diffuse = {0.25, 0.25, 0.5},
        -- specular = {0.0, 0.0, 0.0},
    },
}

gadget.missions = {
    -- Learn how to select units
    -- =========================
    [1] = {
        events = {  -- Ensure they are sorted in time
            {0, [[_G["barracks"] = FilterUnitsByName(Spring.GetTeamUnits(Spring.GetMyTeamID()), "usbarracks")[1] ]]},
            {0, [[_G["storage"] = FilterUnitsByName(Spring.GetTeamUnits(Spring.GetMyTeamID()), "usstorage")[1] ]]},
            {0, [[for _, flag in ipairs(FilterUnitsByName(Spring.GetAllUnits(), "flag")) do
                      local x, y, z = Spring.GetUnitPosition(flag)
                      if x < 2500 then
                          SyncedFunction("Spring.TransferUnit", {flag, Spring.GetMyTeamID()})
                      end
                  end
                ]]},
            {1, [[MessageToPlayer("Welcome again commander!")]]},
            {10, [[MessageToPlayer("We have been working hard to get ready the barracks and the storage")]]},
            {10, [[Spring.SetCameraTarget(1800, 205, 135, 2)]]},
            {300, [[MessageToPlayer("We have not all the day!")
                    Fail()]]},
        },

        triggers = {
            {[[#Spring.GetTeamUnits(Spring.GetMyTeamID()) == 0]],
             [[MessageToPlayer("Commander, you are out of control!")
               Fail()]],
             once = true
            },
            {[[#Spring.GetTeamUnits(Spring.GetMyTeamID()) == Spring.GetSelectedUnitsCount()]],
             [[MessageToPlayer("Well done commander")
               Success()]],
             once = true
            },
        },
        callins = {
            {"UnitDestroyed",
             [[if params.unitID == _G["barracks"] or params.unitID == _G["storage"] then
                   MessageToPlayer("Commander, you are relegated!")
                   Fail()
               end]],
             once = true
            }
        }
    },
}
