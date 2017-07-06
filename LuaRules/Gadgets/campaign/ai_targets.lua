-- Please check that this file is included just from synced gadget
-- The info regarding targets is stored at table ai.targets, where each leader
-- has an entry with his target.
-- Leaders will try to accomplish the target until it becomes impossible.

_targeteables = {}
_targeteable_names = {
    flag = 0.5,
    buoy = 0.5,
    barracks = 1.0,
    tankyard = 2.0,
    yard = 1.0,
    engineer = 2.0,
    engvehicle = 4.0,
    hq = 1.5,
}

function ai.AddTargeteable(unitID)
    local uname = UnitDefs[Spring.GetUnitDefID(unitID)].name
    for tname,tval in pairs(_targeteable_names) do
        if string.find(uname, tname) ~= nil then
            _targeteables[unitID] = tval
            break
        end
    end
end

function ai.RemoveTargeteable(unitID)
    _targeteables[unitID] = nil
end


function ai.GiveUpTarget(unitID)
    ai.targets[unitID] = nil
end

function ai.AssignTarget(unitID)
    -- This function is computing a new target, just in case a target has not
    -- been selected yet. It is not overwriting targets, to do that, please
    -- call before to GiveUpTarget
    if ai.leaders[unitID] == nil or ai.targets[unitID] ~= nil then
        return
    end

    -- Parse the list of potential targets. The targets would be classified
    -- depending on their priority and distance
    local score = 0.0
    local allyID = Spring.GetUnitAllyTeam(unitID)
    local x, y, z = Spring.GetUnitPosition(unitID)
    local unitDefID = Spring.GetUnitDefID(unitID)
    for t,p in pairs(_targeteables) do
        -- Check if we may reach the target. To do so, we obviously should avoid
        -- testing for blocking objects
        local tx, ty, tz = Spring.GetUnitPosition(t)
        if Spring.TestMoveOrder(unitDefID, x, y, z, tx, ty, tz, true, false, true) then
            local dx, dy, dz = tx - x, ty - y, tz - z
            local d2 = dx * dx + dz * dz
            local d = math.sqrt(d2)
            local tscore
            if allyID == Spring.GetUnitAllyTeam(t) then
                -- Ally unit, should we defend him?
                tscore = 0.0
            else
                -- Enemy unit, let's attack
                tscore = p / d
            end
            if tscore > score then
                ai.targets[unitID] = t
                score = tscore
            end
        end
    end
end

function ai.UpdateTarget(unitID)
    if ai.leaders[unitID] == nil then
        if ai.targets[unitID] ~= nil then
            -- He is not a leader, so why a target?
            ai.targets[unitID] = nil
        end
        return
    end
    -- Check the target
    local target = ai.targets[unitID]
    if not Spring.ValidUnitID(target) or Spring.GetUnitIsDead(target) then
        ai.GiveUpTarget(unitID)
    elseif Spring.GetUnitAllyTeam(unitID) == Spring.GetUnitAllyTeam(target) then
        -- Captured target
        ai.GiveUpTarget(unitID)
    end
    -- Try to eventually add a target (just in case it has been removed)
    ai.AssignTarget(unitID)
end
