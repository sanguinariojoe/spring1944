if (not gadgetHandler:IsSyncedCode()) then
    ai = {}

    function ai.AddUnit(unitID)
        SyncedFunction("ai.AddUnit", {unitID})
    end

    function ai.RemoveUnit(unitID)
        SyncedFunction("ai.RemoveUnit", {unitID})
    end

    -- Only synced
    return nil
end

local LEADER_RADIUS = 512
local MAX_SQUAD_SIZE = 15

ai = {
    -- List of all the units managed by the ai, and their leader (leaders are
    -- included, and reference to themselves)
    units = {}
    -- List of all the leaders, and their squads
    leaders = {}
    -- Leader to become updated
    leader_index = 1
    -- List of targets, and their priority
    targets = {}
}


function ai.RelevateLeader(unitID)
    if leaders[unitID] ~= nil then
        return
    end

    if #leaders[unitID] > 0 then
        local squad = leaders[unitID]
        local l = squad[i]
        table.remove(squad, 1)
        leaders[l] = squad
    end
    leaders[unitID] = nil
end

function ai.RemoveUnit(unitID)
    -- Eventually relevate him as leader
    RelevateLeader(unitID)
    -- And remove the unit for the handled ones
    if units[unitID] then
        units[unitID] = nil
    end
end

function ai._GetBestLeader(unitID)
    local teamID = Spring.GetUnitTeam(unitID)
    local x, y, z = Spring.GetUnitPosition(unitID)
    leader_candidates = Spring.GetUnitsInCylinder(x, z, LEADER_RADIUS, teamID)
    if not #leader_candidates then
        return nil
    end
    -- Get the closest leader with an available slot
    l_unit = nil
    l_score = 0.0
    for _,l in ipairs(leader_candidates) do
        if leaders[l] ~= nil and #leaders[l] < MAX_SQUAD_SIZE then
            local lx, ly, lz = Spring.GetUnitPosition(l)
            local dx, dy, dz = x - lx, y - ly, z - lz
            local score = 1.0 / (dx * dx + dy * dy + dz * dz)
            if score > l_score then
                l_unit = l
                l_score = score
            end
        end
    end
    return l_unit  -- which is nil if no valid leaders where found
end

function ai.AddUnit(unitID)
    if not Spring.ValidUnitID(unitID) or units[unitID] then
        return
    end

    -- Assign the unit to an squad, or create a new one
    local unit_leader = _GetBestLeader(unitID)
    if unit_leader == nil then
        -- The unit should become a leader
        leaders[unitID] = {}
        units[unitID] = unitID
        return        
    end

    units[unitID] = unit_leader
    table.insert(leaders[unit_leader], unitID)
end

