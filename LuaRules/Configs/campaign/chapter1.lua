-- Author: Jose Luis Cercos-Pita
-- License: GNU General Public License v3

gadget.config = {
    map = "1944_Cooper_Hill_v3",
    teams = {
        [1] = { -- Player
            ally = 0,
            faction = "us",
            units = { -- Leave empty to use the default ones
                [1] = {unit = "us_platoon_rifle",
                       pos = {900, 0, 1500},
                       facing = "east",
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
        ambient = {0.5, 0.3, 0.15},
        diffuse = {0.7, 0.4, 0.2},
        specular = {0.1, 0.05, 0.025},
        -- Day
        -- ambient = {0.5, 0.5, 0.5},
        -- diffuse = {0.7, 0.65, 0.65},
        -- specular = {0.1, 0.1, 0.1},
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
            {1, [[MessageToPlayer("Commander, welcome to Spring-1944!")]]},
            {10, [[MessageToPlayer("Your squad is ready...")]]},
            {10, [[MessageToPlayer("I'll teach you how to handle the infantry")]]},
            {20, [[MessageToPlayer("Infantry is the basic unit of Spring-1944. Even the most powerful war machines may become useless without infantry support. On top of that, only infantry can capture flags!")]]},
            {30, [[MessageToPlayer("Let's try to capture a flag!")]]},
            {30, [[MessageToPlayer("First you should select your units...")]]},
            {40, [[MessageToPlayer("Use the mouse wheel to zoom in over your squad...")]]},
            {40, [[DrawMarker(900, 45, 1500, "zoom in here")]]},
            {49, [[EraseMarker(900, 45, 1500)]]},
            {50, [[DrawMarker(833, 45, 1441, "Left click here...")]]},
            {50, [[DrawMarker(945, 45, 1560, "drag here and release")]]},
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
    },
    -- Learn how to move units
    -- =======================
    [2] = {
        events = {  -- Ensure they are sorted in time
            {0, [[EraseMarker(833, 45, 1441)]]},
            {0, [[EraseMarker(945, 45, 1560)]]},
            {1, [[MessageToPlayer("Now ask your squad to move")]]},
            {1, [[DrawMarker(780, 45, 1300, "Right click here")]]},
            {300, [[MessageToPlayer("We have not all the day!")
                    Fail()]]},
        },

        triggers = {
            {[[#Spring.GetTeamUnits(Spring.GetMyTeamID()) == 0]],
             [[MessageToPlayer("Commander, you are out of control!")
               Fail()]],
             once = true
            },
            {[[AreUnitsInPosition(Spring.GetTeamUnits(Spring.GetMyTeamID()), 780, 45, 1300, 50)]],
             [[MessageToPlayer("Excellent!")
               Success()]],
             once = true
            },
            {[[IsFlagCaptured(740, 47, 1250)]],
             [[MessageToPlayer("Excellent!")
               Success()]],
             once = true
            },
        },
    },
    [3] = {
        events = {  -- Ensure they are sorted in time
            {0, [[CreateUnit("GERRifle", 2152, 299, 1435, "west", 2)]]},
            {0, [[CreateUnit("GERRifle", 2157, 299, 1460, "west", 2)]]},
            {0, [[CreateUnit("GERMP40", 2148, 299, 1447, "west", 2)]]},
            {0, [[EraseMarker(780, 45, 1300)]]},
            {0, [[MessageToPlayer("Now you have captured the flag.")]]},
            {0, [[MessageToPlayer("The flags boost your command points (the gray bar) at a rate show at top of the flag.")]]},
            {10, [[MessageToPlayer("The command points income is not constant. As much time you keep the control of a flag, more command points income you'll get!")]]},
            {20, [[MessageToPlayer("So let's capture another flag!")]]},
            {20, [[MessageToPlayer("However, sticking your soldiers together make them excesivelly vulnerable to explosive weapons")]]},
            {30, [[MessageToPlayer("This time ask your soldiers to form a line")]]},
            {30, [[DrawMarker(570, 45, 1820, "Right click here...")]]},
            {30, [[DrawMarker(930, 45, 1900, "drag here and release")]]},
            {30, [[DrawLine(570, 45, 1820, 930, 45, 1900)]]},
        },

        triggers = {
            {[[#Spring.GetTeamUnits(Spring.GetMyTeamID()) == 0]],
             [[MessageToPlayer("Commander, you are out of control!")
               Fail()]],
             once = true
            },
            {[[not AreUnitsInPosition(Spring.GetTeamUnits(Spring.GetMyTeamID()), 900, 0, 1500, 1000)]],
             [[MessageToPlayer("Desertions will not be tolerated!")
               Fail()]],
             once = true
            },
            {[[IsFlagCaptured(720, 45, 1940)]],
             [[MessageToPlayer("Great work commander!")
               Success()]],
             once = true
            },
        },
    },
    -- The fight command
    -- =================
    [4] = {
        events = {  -- Ensure they are sorted in time
            {0, [[EraseMarker(570, 45, 1820)]]},
            {0, [[EraseMarker(930, 45, 1900)]]},
            {1, [[MessageToPlayer("Asking your troops to move in this way can be quite useful.")]]},
            {1, [[MessageToPlayer("However, they'll try to reach the objetive even if enemies are sighted")]]},
            {10, [[MessageToPlayer("In order to ask your troops to stop, in case there are enemies in firing range, you can use the fight command.")]]},
            {20, [[MessageToPlayer("We have orders to take the hill!")]]},
            {30, [[DrawMarker(2130, 299, 1300, "Press 'f', then left click here...")]]},
            {30, [[DrawMarker(2190, 299, 1600, "drag here and release")]]},
            {30, [[DrawLine(2130, 299, 1305, 2195, 299, 1605)]]},
        },

        triggers = {
            {[[#Spring.GetTeamUnits(Spring.GetMyTeamID()) == 0]],
             [[MessageToPlayer("All your men are dead!")
               Fail()]],
             once = true
            },
            {[[IsAreaCleared(2160, 299, 1450, 150)]],
             [[MessageToPlayer("Easy work!")
               Success()]],
             once = true
            },
        },

        callins = {
            {"UnitDamaged",
             [[MessageToPlayer("Contact!")
               local x, y, z = Spring.GetUnitPosition(params.unitID)
               Spring.SetCameraTarget(x, y, z, 2)]],
             once = true
            }
        }
    },
    [1] = {
        events = {  -- Ensure they are sorted in time
            {0, [[EraseMarker(2130, 299, 1300)]]},
            {0, [[EraseMarker(2190, 299, 1600)]]},
            {1, [[MessageToPlayer("Probably you have noticed that soldiers under enemy fire has started crawling.")]]},
            {1, [[MessageToPlayer("That increase their strengh, but significantly decrease their speed")]]},
            {10, [[MessageToPlayer("You may also noticed that enemy troops were blocked by fear when our BAR machine guns started firing.")]]},
            {10, [[MessageToPlayer("Troops under heavy fire will become suppresed, not moving or answering fire neither.")]]},
            {20, [[CreateUnit("us_platoon_at", 2160, 299, 1450, "east", 1)]]},
            {20, [[CreateUnit("usobserv", 2260, 294, 1430, "east", 1)]]},
            {21, [[MessageToPlayer("Reinforcements have arrived!")]]},
            {22, [[_G["enemytankID"] = Spring.GetUnitsInCylinder(3200, 1500, 10)[1] ]]},
        },

        triggers = {
            {[[#Spring.GetTeamUnits(Spring.GetMyTeamID()) == 0]],
             [[MessageToPlayer("Commander, you are out of control!")
               Fail()]],
             once = true
            },
            {[[_G["enemytankID"] ~= nil]],
             [[Success()]],
             once = true
            },
        },
    },
    -- Binoculars
    -- ==========
    [2] = {
        events = {  -- Ensure they are sorted in time
            {5, [[Spring.SetCameraTarget(2260, 294, 1430, 2)]]},
            {5, [[MessageToPlayer("Among your new soldiers, you have a spotter")]]},
            {5, [[MessageToPlayer("Select him")]]},
            {6, [[DrawMarker(2260, 294, 1430, "Left click here")]]},
        },

        triggers = {
            {[[#Spring.GetTeamUnits(Spring.GetMyTeamID()) == 0]],
             [[MessageToPlayer("Commander, you are out of control!")
               Fail()]],
             once = true
            },
            {[[#FilterUnitsByName(Spring.GetSelectedUnits(), "usobserv") == 1]],
             [[Success()]],
             once = true
            },
        },
    },
    [3] = {
        events = {  -- Ensure they are sorted in time
            {0, [[EraseMarker(2260, 294, 1430)]]},
            {0, [[MessageToPlayer("He looks transparent because he cannot be detected by the enemy forces until he gets too close")]]},
            {10, [[MessageToPlayer("Hence, spotter can sneak everywhere!")]]},
            {10, [[MessageToPlayer("However, in this state spotters are almost blind, detecting enemy troops just in a very sort range.")]]},
            {20, [[MessageToPlayer("So let's use the binoculars to spot the other side of the hill.")]]},
            {20, [[MessageToPlayer("To do that you can use the attack command...")]]},
            {20, [[DrawMarker(3200, 0, 1450, "Press A, then left click here")]]},
        },

        triggers = {
            {[[#Spring.GetTeamUnits(Spring.GetMyTeamID()) == 0]],
             [[MessageToPlayer("Commander, you are out of control!")
               Fail()]],
             once = true
            },
            {[[Spring.IsUnitInLos(_G["enemytankID"], Spring.GetMyAllyTeamID())]],
             [[Success()]],
             once = true
            },
        },
    },
    -- Queuing commands
    -- ================
    [4] = {
        events = {  -- Ensure they are sorted in time
            {0, [[EraseMarker(3200, 0, 1450)]]},
            {1, [[MessageToPlayer("Watch out! The enemy has a tank")]]},
            {10, [[MessageToPlayer("The tank seems to be alone... Probably they are waiting for reinforcements")]]},
            {10, [[MessageToPlayer("We should get that tank right now!")]]},
            {20, [[Spring.SetCameraTarget(2160, 299, 1450, 2)]]},
            {20, [[MessageToPlayer("Fortunatelly you have some anti-tank equiped soldiers.")]]},
            {20, [[MessageToPlayer("You can select soldiers by its type...")]]},
            {20, [[DrawMarker(2160, 299, 1450, "Double click over an anti-tank soldier")]]},
        },

        triggers = {
            {[[#Spring.GetTeamUnits(Spring.GetMyTeamID()) == 0]],
             [[MessageToPlayer("Commander, you are out of control!")
               Fail()]],
             once = true
            },
            {[[#FilterUnitsByName(Spring.GetSelectedUnits(), "usbazooka") == 3]],
             [[Success()]],
             once = true
            },
        },
    },

    

}
