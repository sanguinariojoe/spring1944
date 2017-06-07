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
    -- Machine guns
    -- ============
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
            {0, [[SwitchUnitCommand(_G["barracks"], "ushqengineer", false)]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "us_platoon_rifle", false)]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "us_platoon_assault", false)]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "us_platoon_at", false)]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "us_platoon_sniper", false)]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "us_platoon_flame", false)]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "us_platoon_mortar", false)]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "us_platoon_infgun", false)]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "usgmctruck", false)]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "uspontoontruck", false)]]},
            {0, [[SwitchUnitCommand(_G["storage"], "  Upgrade  ", false)]]},
            {1, [[MessageToPlayer("Welcome again commander!")]]},
            {10, [[MessageToPlayer("We have been working hard to get ready the barracks and the storage")]]},
            {10, [[Spring.SetCameraTarget(1800, 205, 135, 2)]]},
            {10, [[MessageToPlayer("The barracks can be used to produce infantry.")]]},
            {20, [[DrawMarker(2050, 206, 150, "Select me and order a machine gun platoon")]]},
            {20, [[MessageToPlayer("We can start producing some machine guns to defend the hill.")]]},
            {300, [[MessageToPlayer("We have not all the day!")
                    Fail()]]},
        },

        callins = {
            {"UnitDestroyed",
             [[if params.unitID == _G["barracks"] or params.unitID == _G["storage"] then
                   MessageToPlayer("Commander, you are relegated!")
                   Fail()
               end]],
             once = true
            },
            {"UnitCreated",
             [[if UnitDefs[params.unitDefID].name == "us_platoon_mg" then
                    MessageToPlayer("Great Commander!")
                    Success()
               end]],
             once = true
            }
        }
    },
    [2] = {
        events = {  -- Ensure they are sorted in time
            {0, [[SwitchUnitCommand(_G["barracks"], "us_platoon_mg", false)]]},
            {0, [[EraseMarker(2050, 206, 150)]]},
            {0, [[MessageToPlayer("I'll tell you about the machine gunners while they are produced")]]},
            {10, [[MessageToPlayer("Machine guns have supressing enemy infantry feature. That means that enemy soldiers under machine gun fire will be blocked by fear, not even returning fire")]]},
            {20, [[MessageToPlayer("Machine gunners may work in 2 ways: Like the usual infantry you already known, or deploying an entrechment")]]},
            {20, [[MessageToPlayer("The latter will block your unit movement, but in return the strengh and range will be significantly increased")]]},
            {30, [[MessageToPlayer("Wait until your new squad is produced...")]]},
        },

        callins = {
            {"UnitDestroyed",
             [[if params.unitID == _G["barracks"] or params.unitID == _G["storage"] then
                   MessageToPlayer("Commander, you are relegated!")
                   Fail()
               end]],
             once = true
            },
            {"UnitFinished",
             [[if UnitDefs[params.unitDefID].name == "us_platoon_mg" then
                   MessageToPlayer("Your new squad is ready!")
                   Success()
               end]],
             once = true
            }
        }
    },
    [3] = {
        events = {  -- Ensure they are sorted in time
            -- Remove all the pending commands of the barracks (edge case)
            {0, [[local facCmds = Spring.GetFactoryCommands(_G["barracks"])
                  local pendingUnits = false
                  if facCmds then
                      for i, cmd in ipairs(facCmds) do
                          if cmd.id < 0 then
                              SyncedFunction("Spring.GiveOrderToUnit", {_G["barracks"], CMD.REMOVE, {cmd.tag}, {"ctrl"}})
                              pendingUnits = true
                          end
                      end
                  end
                  if pendingUnits then
                      MessageToPlayer("Commander, I removed the extra machine gun squads")
                  end]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "us_platoon_mg", false)]]},
            {1, [[MessageToPlayer("We are deploying some machine gun nests to form a line along the hill")]]},
            {10, [[DrawMarker(2440, 148, 410, "Move a machine gunner here")]]},
            {10, [[DrawMarker(2260, 285, 1310, "Move a machine gunner here")]]},
            {10, [[DrawMarker(2490, 188, 2135, "Move a machine gunner here")]]},
            {10, [[MessageToPlayer("To do that, we should first ask the machine gunners to take positions")]]},
            {300, [[MessageToPlayer("We have not all the day!")
                    Fail()]]},
        },
        triggers = {
            {[[#Spring.GetUnitsInCylinder(2440, 410, 20) > 0 and #Spring.GetUnitsInCylinder(2260, 1310, 20) > 0 and #Spring.GetUnitsInCylinder(2490, 2135, 20) > 0]],
             [[local positions = {{2440, 410}, {2260, 1310}, {2490, 2135}}
               local success = 0
               for _, pos in ipairs(positions) do
                   local units = Spring.GetUnitsInCylinder(pos[1], pos[2], 20)
                   for _, unit in ipairs(units) do
                       if UnitDefs[Spring.GetUnitDefID(unit)].name == "usmg" then
                           success = success + 1
                       end
                   end
               end
               if success == 3 then
                   MessageToPlayer("Excellent!")
                   Success()
               end]],
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
            },
        }
    },
    [4] = {
        events = {  -- Ensure they are sorted in time
            {0, [[EraseMarker(2440, 148, 410)]]},
            {0, [[EraseMarker(2260, 285, 1310)]]},
            {0, [[EraseMarker(2490, 188, 2135)]]},
            {1, [[DrawLine(2440, 148, 410, 2795, 45, 850)]]},
            {1, [[DrawLine(2440, 148, 410, 2875, 45, 5)]]},
            {1, [[DrawLine(2260, 285, 1310, 2570, 67, 780)]]},
            {1, [[DrawLine(2260, 285, 1310, 2705, 97, 1635)]]},
            {1, [[DrawLine(2490, 188, 2135, 2875, 45, 1665)]]},
            {1, [[DrawLine(2490, 188, 2135, 2940, 45, 2520)]]},
            {1, [[DrawMarker(2440, 148, 410, "Press deploy, aim at front and left click")]]},
            {1, [[DrawMarker(2260, 285, 1310, "Press deploy, aim at front and left click")]]},
            {1, [[DrawMarker(2490, 188, 2135, "Press deploy, aim at front and left click")]]},
            {1, [[MessageToPlayer("Now you can use the deploy command to make entrechments")]]},
            {300, [[MessageToPlayer("We have not all the day!")
                    Fail()]]},
        },
        triggers = {
            {[[#FilterUnitsByName(Spring.GetTeamUnits(Spring.GetMyTeamID()), "usmg_sandbag") == 3]],
             [[MessageToPlayer("Fantastic job commander!")
               local positions = {{2440, 410}, {2260, 1310}, {2490, 2135}}
               local success = 0
               local units
               for _, pos in ipairs(positions) do
                   units = Spring.GetUnitsInCylinder(pos[1], pos[2], 20)
                   for _, unit in ipairs(units) do
                       if UnitDefs[Spring.GetUnitDefID(unit)].name == "usmg_sandbag" then
                           success = success + 1
                       end
                   end
               end
               if success ~= 3 then
                   MessageToPlayer("Commander, deploy the machine guns at their designed positions!")
                   Fail()
               else
                   -- Check the machine guns are well oriented
                   units = FilterUnitsByName(Spring.GetTeamUnits(Spring.GetMyTeamID()), "usmg_sandbag")
                   for _, unit in ipairs(units) do
                       local _, yaw, _ = Spring.GetUnitRotation(unit)
                       if yaw < 0.0 then
                           yaw = yaw + 2 * math.pi
                       end
                       if yaw < math.rad(270 - 15) or yaw > math.rad(270 - 15) then
                           success = success - 1
                           -- Disabled the undeployment command
                           SwitchUnitCommand(unit, "Deploy", false)
                       end
                   end
                   if success ~= 0 then
                       MessageToPlayer("Commander, aim the machine guns to the front!")
                       Fail()
                   else
                       MessageToPlayer("Great job, commander!")
                       Success()
                   end
               end]],
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
            },
        }
    },
    -- Building queue
    -- ==============
    [5] = {
        events = {  -- Ensure they are sorted in time
            {0, [[_G["barracks"] = FilterUnitsByName(Spring.GetTeamUnits(Spring.GetMyTeamID()), "usbarracks")[1] ]]},
            {0, [[_G["storage"] = FilterUnitsByName(Spring.GetTeamUnits(Spring.GetMyTeamID()), "usstorage")[1] ]]},
            {0, [[EraseMarker(2440, 148, 410)]]},
            {0, [[EraseMarker(2795, 45, 850)]]},
            {0, [[EraseMarker(2875, 45, 5)]]},
            {0, [[EraseMarker(2260, 285, 1310)]]},
            {0, [[EraseMarker(2570, 67, 780)]]},
            {0, [[EraseMarker(2705, 97, 1635)]]},
            {0, [[EraseMarker(2490, 188, 2135)]]},
            {0, [[EraseMarker(2875, 45, 1665)]]},
            {0, [[EraseMarker(2940, 45, 2520)]]},
            {0, [[SwitchUnitCommand(_G["barracks"], "us_platoon_rifle", true)]]},
            {1, [[MessageToPlayer("Your machine guns are a good way to keep the enemy away, however, without infantry support they would be easily overruned")]]},
            {8, [[DrawMarker(2050, 206, 150, "Select me and order 3 rifle squads")]]},
            {8, [[MessageToPlayer("Commander, build 3 squads to support your machine guns")]]},
            {8, [[MessageToPlayer("You can do it clicking 3 times on the squad icon")]]},
            {300, [[MessageToPlayer("We have not all the day!")
                    Fail()]]},
        },
        triggers = {
            {[[Spring.GetFactoryCommands(_G["barracks"])]],
             [[local facCmds = Spring.GetFactoryCommands(_G["barracks"])
               local nUnits = 0
               if facCmds then
                   for i, cmd in ipairs(facCmds) do
                       if cmd.id < 0 then
                           nUnits = nUnits + 1
                       end
                   end
               end
               if nUnits >= 3 then
                   SwitchUnitCommand(_G["barracks"], "us_platoon_rifle", false)
                   MessageToPlayer("Excellent, commander!")
                   Success()
               end]],
             once = false
            },
        },
        callins = {
            {"UnitDestroyed",
             [[if params.unitID == _G["barracks"] or params.unitID == _G["storage"] then
                   MessageToPlayer("Commander, you are relegated!")
                   Fail()
               end]],
             once = true
            },
            {"UnitFinished",
             [[if UnitDefs[params.unitDefID].name == "us_platoon_rifle" then
                   MessageToPlayer("What are you waiting to enqueue the other squads?")
                   MessageToPlayer("We'll find another commander able to fulfill the orders!")
                   Fail()
               end]],
             once = false
            },
        }
    },
    [6] = {
        events = {  -- Ensure they are sorted in time
            {0, [[EraseMarker(2050, 206, 150)]]},
            {1, [[MessageToPlayer("You probably want to distribute your soldiers along a front line")]]},
            {1, [[DrawLine(2600, 150, 230, 2450, 150, 425)]]},
            {1, [[DrawLine(2330, 150, 730, 2360, 150, 980)]]},
            {1, [[DrawLine(2415, 205, 1300, 2450, 205, 1610)]]},
            {1, [[DrawLine(2435, 220, 1935, 2530, 220, 2270)]]},
            {1, [[DrawLine(2580, 170, 2560, 2500, 170, 2840)]]},
            {300, [[MessageToPlayer("We have not all the day!")
                    Fail()]]},
        },
        callins = {
            {"UnitDestroyed",
             [[if params.unitID == _G["barracks"] or params.unitID == _G["storage"] then
                   MessageToPlayer("Commander, you are relegated!")
                   Fail()
               end]],
             once = true
            },
            {"UnitFinished",
             [[if #FilterUnitsByName(Spring.GetTeamUnits(Spring.GetMyTeamID()), "usrifle") == 8 * 3 then
                   MessageToPlayer("Squads ready!")
                   Success()
               end]],
             once = false
            }
        },
    },
    -- Mortars
    -- =======
    [7] = {
        events = {  -- Ensure they are sorted in time
            {0, [[local facCmds = Spring.GetFactoryCommands(_G["barracks"])
                  local pendingUnits = false
                  if facCmds then
                      for i, cmd in ipairs(facCmds) do
                          if cmd.id < 0 then
                              SyncedFunction("Spring.GiveOrderToUnit", {_G["barracks"], CMD.REMOVE, {cmd.tag}, {"ctrl"}})
                              pendingUnits = true
                          end
                      end
                  end
                  if pendingUnits then
                      MessageToPlayer("Commander, I removed the extra squad orders")
                  end]]},
        },
    },
}
