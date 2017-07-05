-- Please check that this file is included just from synced gadget

-- This better in ai table? (to can discard outdated leaders)
local _dispatching = {}

local _iconType_classification = {
    default = nil,
    rifle = "assault",
    paratrooper = "assault",
    assault = "assault",
    antitank = "assault",
    mortar = "longRange",
    sniper = "longRange",
    officer = nil,
    engineer = nil,
    advancedengineer = nil,
    engineervehicle = nil,
    lightmg = "assault",
    bar = "assault",
    flame = "assault",
    aaartillery = nil,
    atartillery = nil,
    aahalftrack = "longRange",
    aacar = "longRange",
    aatruck = nil,
    attruck = nil,
    fgtruck = nil,
    armoredcar = "longRange",
    artillery = nil,
    bomber = nil,
    fighter = nil,
    fighterbomber = nil,

    gerhq = nil,
    ushq = nil,
    gbrhq = nil,
    halftrack = "supply",
    heavytank = "longRange",
    medtank = "longRange",
    lighttank = "longRange",
    jeep = "scout",
    recon = "scout",
    selfprop = "longRange",
    sparty = "longRange",
    stockpile = nil,
    rockettruck = "longRange",
    truck = nil,
    ptruck = nil,
    truck_factory = nil,
    truck_barracks = nil,
    htruck = nil,
    rtruck = nil,
    ammo = nil,
    ammo2 = nil,
    factory = nil,
    usflag = nil,
    gbrflag = nil,
    gerflag = nil,
    mines = nil,
    rusflag = nil,
    commissar = "scout",
    partisan = "assault",
    commando = "assault",
    rubber = "assault",
    lttrans = nil,
    raft    = nil,
    rusptrd = nil,
    barracks = nil,
    radar = nil,
    flag = nil,
    shack = nil,
    shipyard = nil,
    hshipyard = nil,
    destroyer = "longRange",
    torpboat = "assault",
    gunboat = "longRange",
    artyboat = "longRange",
    turret = nil,
    landingship = "assault",
    transportship = nil,
    transportplane = nil,
    flametank = "assault",
    itahq = nil,
    itasolo = "assault",
    itascopedsolo = "assault",
    jpnhq = nil,
    swehq = nil,
    hunhq = nil,
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
    local td = 10.0
    local a = {}
    for i,u in ipairs(assault) do
        local sign = 2 * math.fmod(i, 2) - 1
        local x = td * floor((i - 1) / 2) * sign
        local z = 0.0
        table.insert(a, {x * t[1] + z * n[1], x * t[2] + z * n[2]})
        local ulos = Spring.GetUnitSensorRadius(u, "los")
        if ulos > los then
            los = ulos
        end
    end

    -- A bit behind them, a row of scouts units
    local td = 30.0
    local s = {}
    for i,u in ipairs(scouts) do
        local sign = 2 * math.fmod(i, 2) - 1
        local x = td * floor((i - 1) / 2) * sign
        local z = -10.0
        table.insert(s, {x * t[1] + z * n[1], x * t[2] + z * n[2]})
        local ulos = Spring.GetUnitSensorRadius(u, "los")
        if ulos + z > los then
            los = ulos + z
        end
    end

    -- The longRange units should be placed as far as possible
    local td = 30.0
    local l = {}
    for i,u in ipairs(longRanges) do
        local sign = 2 * math.fmod(i, 2) - 1
        local x = td * floor((i - 1) / 2) * sign
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
    if cmds[nCmds].id == CMD.SET_WANTED_MAX_SPEED then
        Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cmds[nCmds].tag}, {})
    end
    -- Ask to set the velocity
    Spring.GiveOrderToUnit(unitID,
        CMD.INSERT,
        {-1, CMD.SET_WANTED_MAX_SPEED, {CMD.OPT_SHIFT, CMD.OPT_CTRL}, {speed}},
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
            ai._SetSpeedUnit(u, Spring.GetUnitDefID(u).maxvelocity)
        else
            -- The unit should wait for the rest of the squad
            ai._SetSpeedUnit(u, ref_speed * 100.0 / dn)
        end
    end
end

function ai.AdvanceToTarget(leader, squad, target)
    local tx, ty, tz = Spring.GetUnitPosition(target)
    local x, y, z = Spring.GetUnitPosition(leader)
    local units = {table.unpack(squad)}
    table.insert(units, 1, leader)

    -- Classify the units
    local assault = {}      -- Close combat units
    local scouts = {}       -- Scouting units, just to get enemies in LOS
    local longRanges = {}   -- They should keep as far as possible
    local suppliers = {}    -- They should guard units asking for ammo
    local ref_speed = nil
    for _,u in ipairs(units) do
        local udef = Spring.GetUnitDefID(u)
        local class_string = _iconType_classification[UnitDefs[udef].iconType]
        local unit_speed = 0.0
        if class_string == "assault" then
            table.insert(assault, 1, u)
            unit_speed = udef.maxvelocity
        elseif class_string == "scouts" then
            table.insert(scouts, 1, u)
            unit_speed = udef.maxvelocity
        elseif class_string == "longRange" then
            table.insert(longRanges, 1, u)
            unit_speed = udef.maxvelocity
        elseif class_string == "supply" then
            table.insert(suppliers, 1, u)
            unit_speed = udef.maxvelocity
        end
        if ref_speed == nil or unit_speed < ref_speed then
            ref_speed = unit_speed
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
            maxammo = floor(maxammo)
            ammo = floor(ammo)
            if floor(maxammo) > 0 and floor(ammo) < floor(maxammo) then
                -- Ask for a supplier
                -- ai._RemoveCommands(suppliers[supplier_index])
                Spring.GiveOrderToUnit(suppliers[supplier_index], CMD.GUARD, {u}, {})
                supplier_index = supplier_index + 1
            end
        end
    end

    while supplier_index <= #suppliers then
        -- Assign the suppliers without commands to guard the leader
        local nCmds = Spring.GetUnitCommands(suppliers[supplier_index], 0)
        if nCmds ~= nil and nCmds == 0 then
            -- ai._RemoveCommands(suppliers[supplier_index])
            Spring.GiveOrderToUnit(suppliers[supplier_index], CMD.GUARD, {leader}, {})
        end
        supplier_index = supplier_index + 1
    end

    
    if not #assault and not #scouts then
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
                {-1, CMD.FIGHT, {CMD.OPT_SHIFT, CMD.OPT_CTRL}, {px, py, pz}},
                {"alt"}
            )
        end
        for i,u in ipairs(scouts) do
            -- ai._RemoveCommands(u)
            local px, pz = x + a_s[i][1], z + a_s[i][2]
            local py = Spring.GetGroundHeight(px, pz)
            Spring.GiveOrderToUnit(u, CMD.FIGHT, {px, py, pz}, {})
            local px, pz = tx + a_s[i][1], tz + a_s[i][2]
            local py = Spring.GetGroundHeight(px, pz)
            Spring.GiveOrderToUnit(u,
                CMD.INSERT,
                {-1, CMD.FIGHT, {CMD.OPT_SHIFT, CMD.OPT_CTRL}, {px, py, pz}},
                {"alt"}
            )
        end
        -- Regarding the long range units, they could directly advance to the
        -- designated possition
        for i,u in ipairs(longRanges) do
            -- ai._RemoveCommands(u)
            local px, pz = tx + a_r[i][1], tz + a_r[i][2]
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