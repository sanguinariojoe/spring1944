-- Please check that this file is included just from synced gadget

-- Small hack LUA 5.1 -> 5.2
if unpack == nil then
    unpack = table.unpack
end

-- This better in ai table? (to can discard outdated leaders)
_dispatching = {}
_classname_classification = {
    RifleInf = "assault",
    SMGInf = "assault",
    LMGInf = "assault",
    HMGInf = "assault",
    LightMortarInf = "assault",
    FlameInf = "assault",
    ATLauncherInf = "assault",
    ATGrenadeInf = "assault",
    ATRifleInf = "assault",
    Tankette = "assault",
    AssaultBoat = "assault",
    ScoutCar = "scout",
    Vehicle = "scout",
    Tankette = "scout",
    SniperInf = "longRange",
    MedMortarInf = "longRange",
    InfantryGun = "longRange",
    ArmouredCar = "longRange",
    HeavyArmouredCar = "longRange",
    MobileAA = "longRange",
    ArmouredCarAA = "longRange",
    Tank = "longRange",
    LightTank = "longRange",
    MediumTank = "longRange",
    HeavyTank = "longRange",
    AssaultGun = "longRange",
    TankDestroyer = "longRange",
    SPArty = "longRange",
    Boat = "longRange",
    BoatMother = "longRange",
    ArmedBoat = "longRange",
    HalfTrack = "supply",
    InfantryLandingCraft = "supply",
    TankLandingCraft = "supply",
}

function ai._RemoveCommands(unitID)
    local nCmds = Spring.GetUnitCommands(unitID, 0)
    if nCmds == nil or nCmds == 0 then
        return
    end
    local cmds = Spring.GetUnitCommands(unitID, nCmds)
    for i, cmd in ipairs(cmds) do
        Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cmd.tag}, {})
    end
end

function ai._ComputeFormation(assault, scouts, longRanges, n)
    local t = {-n[2], n[1]}

    local los = 0.0

    -- First row of assault units
    local td = 30.0
    local a = {}
    for i,u in ipairs(assault) do
        local sign = 2 * math.fmod(i, 2) - 1
        local x = td * math.floor((i - 1) / 2) * sign
        local z = 0.0
        table.insert(a, {x * t[1] + z * n[1], x * t[2] + z * n[2]})
        local ulos = Spring.GetUnitSensorRadius(u, "los")
        if ulos > los then
            los = ulos
        end
    end

    -- A bit behind them, a row of scouts units
    local td = 90.0
    local s = {}
    for i,u in ipairs(scouts) do
        local sign = 2 * math.fmod(i, 2) - 1
        local x = td * math.floor((i - 1) / 2) * sign
        local z = -10.0
        table.insert(s, {x * t[1] + z * n[1], x * t[2] + z * n[2]})
        local ulos = Spring.GetUnitSensorRadius(u, "los")
        if ulos + z > los then
            los = ulos + z
        end
    end

    -- The longRange units should be placed as far as possible
    local td = 90.0
    local l = {}
    for i,u in ipairs(longRanges) do
        local sign = 2 * math.fmod(i, 2) - 1
        local x = td * math.floor((i - 1) / 2) * sign
        -- Theoretically, we don't need to check if weapon range required is
        -- valid (not nil)
        local z = los - Spring.GetUnitWeaponState(u, 1, "range")
        table.insert(l, {x * t[1] + z * n[1], x * t[2] + z * n[2]})
    end

    return a, s, l
end

function ai._SetSpeedUnit(unitID, speed)
    local nCmds = Spring.GetUnitCommands(unitID, 0)
    if nCmds == nil or nCmds == 0 then
        -- Is the unit already in the target??
        return
    end
    -- Check if the last command is already a velocity config one
    local cmds = Spring.GetUnitCommands(unitID, nCmds)
    if nCmds == 2 and cmds[nCmds].id ~= CMD.SET_WANTED_MAX_SPEED then
        -- Unit is forming
        return
    end
    if cmds[nCmds].id == CMD.SET_WANTED_MAX_SPEED then
        Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cmds[nCmds].tag}, {})
    end
    -- Ask to set the velocity
    Spring.GiveOrderToUnit(unitID,
        CMD.INSERT,
        {-1, CMD.SET_WANTED_MAX_SPEED, CMD.OPT_CTRL, speed},
        {"alt"}
    )

end


function ai._SetSpeedFormation(assault, scouts, longRanges, n,
                               assault_r, scout_r, long_r,
                               ref_speed)
    local ref_uint = assault[1] or scouts[1]
    local rx, ry, rz = Spring.GetUnitPosition(ref_uint)
    for i,u in ipairs(assault) do
        local x, y, z = Spring.GetUnitPosition(u)
        local dx, dz = (x - rx) - assault_r[i][1], (z - rz) - assault_r[i][2]
        local dn = dx * n[1] + dz * n[2]
        if math.abs(dn) < 100.0 then
            ai._SetSpeedUnit(u, ref_speed)
        elseif dn < 0.0 then
            -- The unit should catch up the rest of the squad
            ai._SetSpeedUnit(u, Spring.GetUnitMoveTypeData(u).maxSpeed)
        else
            -- The unit should wait for the rest of the squad
            ai._SetSpeedUnit(u, ref_speed * 100.0 / dn)
        end
    end
    for i,u in ipairs(scouts) do
        local x, y, z = Spring.GetUnitPosition(u)
        local dx, dz = (x - rx) - scout_r[i][1], (z - rz) - scout_r[i][2]
        local dn = dx * n[1] + dz * n[2]
        if math.abs(dn) < 100.0 then
            ai._SetSpeedUnit(u, ref_speed)
        elseif dn < 0.0 then
            -- The unit should catch up the rest of the squad
            ai._SetSpeedUnit(u, Spring.GetUnitMoveTypeData(u).maxSpeed)
        else
            -- The unit should wait for the rest of the squad
            ai._SetSpeedUnit(u, ref_speed * 100.0 / dn)
        end
    end
    for i,u in ipairs(longRanges) do
        local x, y, z = Spring.GetUnitPosition(u)
        local dx, dz = (x - rx) - long_r[i][1], (z - rz) - long_r[i][2]
        local dn = dx * n[1] + dz * n[2]
        if math.abs(dn) < 100.0 then
            ai._SetSpeedUnit(u, ref_speed)
        elseif dn < 0.0 then
            -- The unit should catch up the rest of the squad
            ai._SetSpeedUnit(u, Spring.GetUnitMoveTypeData(u).maxSpeed)
        else
            -- The unit should wait for the rest of the squad
            ai._SetSpeedUnit(u, ref_speed * 100.0 / dn)
        end
    end
end

function ai.AdvanceToTarget(leader, squad, target)
    if leader == nil or target == nil then
        return
    end
    local tx, ty, tz = Spring.GetUnitPosition(target)
    local x, y, z = Spring.GetUnitPosition(leader)
    local units = {}
    for _,u in ipairs(squad) do
        local udef = UnitDefs[Spring.GetUnitDefID(u)]
        if Spring.ValidUnitID(u) and not Spring.GetUnitIsDead(u) and udef ~= nil then
            -- For some reason, when a unit is dead the squad is not correctly
            -- sanitized, so better checking twice
            table.insert(units, 1, u)
        end
    end
    table.insert(units, 1, leader)

    -- Classify the units
    local assault = {}      -- Close combat units
    local scouts = {}       -- Scouting units, just to get enemies in LOS
    local longRanges = {}   -- They should keep as far as possible
    local suppliers = {}    -- They should guard units asking for ammo
    local ref_speed = 0.8   -- No idea why 0.8, but it's not related with Spring.GetUnitMoveTypeData(u).maxSpeed
    for _,u in ipairs(units) do
        local udef = UnitDefs[Spring.GetUnitDefID(u)]
        local class_string = _classname_classification[udef.customParams.classname]
        if class_string ~= nil and udef.customParams.supplyRange ~= nil then
            -- Some half trucks have Vehicle classes
            class_string = "supply"
        end
        if class_string == "assault" then
            table.insert(assault, 1, u)
        elseif class_string == "scout" then
            table.insert(scouts, 1, u)
        elseif class_string == "longRange" then
            table.insert(longRanges, 1, u)
        elseif class_string == "supply" then
            table.insert(suppliers, 1, u)
        end
    end

    -- Ask suppliers to refill ammo of units
    local supplier_index = 1
    for _,u in ipairs(units) do
        if supplier_index > #suppliers then
            break
        end
        local maxammo = UnitDefs[Spring.GetUnitDefID(u)].customParams.maxammo
        local ammo = Spring.GetUnitRulesParam(u, 'ammo')
        if maxammo ~= nil and ammo ~= nil then
            maxammo = math.floor(maxammo)
            ammo = math.floor(ammo)
            if maxammo > 0 and ammo < maxammo then
                -- Ask for a supplier
                -- ai._RemoveCommands(suppliers[supplier_index])
                Spring.GiveOrderToUnit(suppliers[supplier_index], CMD.GUARD, {u}, {})
                supplier_index = supplier_index + 1
            end
        end
    end

    while supplier_index <= #suppliers do
        -- Assign the suppliers without commands to guard the leader
        local nCmds = Spring.GetUnitCommands(suppliers[supplier_index], 0)
        if nCmds ~= nil and nCmds == 0 then
            -- ai._RemoveCommands(suppliers[supplier_index])
            Spring.GiveOrderToUnit(suppliers[supplier_index], CMD.GUARD, {leader}, {})
        end
        supplier_index = supplier_index + 1
    end

    if assault[1] == nil and scouts[1] == nil then
        -- Let's try to assign the units to a different squad
        new_leader = ai._GetBestLeader(leader)
        if new_leader ~= nil then
            ai.leaders[leader] = nil
            ai.targets[leader] = nil
            for _,u in ipairs(units) do
                ai.units[u] = new_leader
                table.insert(ai.leaders[new_leader], u)
            end
        end
        return
    end

    local dx, dy, dz = tx - x, ty - y, tz - z
    local d = math.sqrt(dx * dx + dz * dz)
    local a_r, s_r, l_r = ai._ComputeFormation(assault, scouts, longRanges,
                                               {dx / d, dz / d})

    -- Check if the squad is already dispatching a command
    local cmd = _dispatching[leader]
    if cmd ~= target then
        -- Ask first the assault and scout units to take positions, and then to
        -- advance to the enemy
        for i,u in ipairs(assault) do
            -- ai._RemoveCommands(u)
            local px, pz = x + a_r[i][1], z + a_r[i][2]
            local py = Spring.GetGroundHeight(px, pz)
            Spring.GiveOrderToUnit(u, CMD.FIGHT, {px, py, pz}, {})
            local px, pz = tx + a_r[i][1], tz + a_r[i][2]
            local py = Spring.GetGroundHeight(px, pz)
            Spring.GiveOrderToUnit(u,
                CMD.INSERT,
                {-1, CMD.FIGHT, CMD.OPT_SHIFT + CMD.OPT_CTRL, px, py, pz},
                {"alt"})
        end
        for i,u in ipairs(scouts) do
            -- ai._RemoveCommands(u)
            local px, pz = x + s_r[i][1], z + s_r[i][2]
            local py = Spring.GetGroundHeight(px, pz)
            Spring.GiveOrderToUnit(u, CMD.FIGHT, {px, py, pz}, {})
            local px, pz = tx + s_r[i][1], tz + s_r[i][2]
            local py = Spring.GetGroundHeight(px, pz)
            Spring.GiveOrderToUnit(u,
                CMD.INSERT,
                {-1, CMD.FIGHT, CMD.OPT_SHIFT + CMD.OPT_CTRL, px, py, pz},
                {"alt"})
        end
        -- Regarding the long range units, they could directly advance to the
        -- designated possition
        for i,u in ipairs(longRanges) do
            -- ai._RemoveCommands(u)
            local px, pz = tx + l_r[i][1], tz + l_r[i][2]
            local py = Spring.GetGroundHeight(px, pz)
            Spring.GiveOrderToUnit(u, CMD.FIGHT, {px, py, pz}, {"ctrl"})
        end        

        -- Mark the target as dispatching to the squad
        _dispatching[leader] = target
    end

    -- Set the speed of the units
    ai._SetSpeedFormation(assault, scouts, longRanges, {dx / d, dz / d},
                          a_r, s_r, l_r, ref_speed)
end
