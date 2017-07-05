-- Please check that this file is included just from synced gadget

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
        Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cmd.tag}, {"ctrl"})
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

function ai.AdvanceToTarget(leader, squad, target)
    local tx, ty, tz = Spring.GetUnitPosition(target)
    local x, y, z = Spring.GetUnitPosition(leader)
    local units = {table.unpack(squad)}
    table.insert(units, 1, leader)

    -- Classify the units
    local assault = {}      -- Close combat units
    local scouts = {}       -- Scouting units, just to get enemies in LOS
    local longRanges = {}    -- They should keep as far as possible
    local suppliers = {}
    for _,u in ipairs(units) do
        local udef = Spring.GetUnitDefID(u)
        local class_string = _iconType_classification[UnitDefs[udef].iconType]
        if class_string == "assault" then
            table.insert(assault, 1, u)
        elseif class_string == "scouts" then
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
            maxammo = floor(maxammo)
            ammo = floor(ammo)
            if floor(maxammo) > 0 and floor(ammo) < floor(maxammo) then
                -- Ask for a supplier
                ai._RemoveCommands(suppliers[supplier_index])
                Spring.GiveOrderToUnit(suppliers[supplier_index], CMD.GUARD, {u}, {})
                supplier_index = supplier_index + 1
            end
        end
    end

    while supplier_index <= #suppliers then
        -- Assign the suppliers without commands to guard the leader
        local nCmds = Spring.GetUnitCommands(suppliers[supplier_index], 0)
        if nCmds ~= nil and nCmds == 0 then
            ai._RemoveCommands(suppliers[supplier_index])
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
    local a_r, s_r, l_r = ai._ComputeFormation(assault, scouts, longRanges, {dx / d, dz / d})

    -- Check if the squad is already dispatching a command
    local cmd = _dispatching[leader]
    if cmd ~= nil and (cmd == target) then
        -- Check the speed of the units
        return
    end

    -- Ask the assault and scout units to go to the formation
    _dispatching[leader] = target
end
