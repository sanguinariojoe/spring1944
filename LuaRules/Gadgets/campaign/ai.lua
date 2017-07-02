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
    units = {},
    -- List of all the leaders, and their squads
    leaders = {},
    -- Leader to become updated
    leader = nil,
    -- List of targets per leader. see campaign/ai_targets.lua
    targets = {},
}

include("LuaRules/Gadgets/campaign/ai_targets.lua")

-- Callins
-- =======
function ai.UnitCreated(unitID, unitDefID, unitTeam, builderID)
    ai.AddTargeteable(unitID)
end

function ai.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    -- Remove the AI control
    ai.RemoveUnit(unitID)
    -- And ask the leaders to forget this target
    ai.RemoveTargeteable(unitID)
end

function ai.UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    -- When a unit is given, the AI should forget it. Otherwise, the unit would
    -- remain controlled even if it is given to a human controlled team.
    -- Hence, the campaign developer is responsible of eventually reassigning
    -- the unit to the AI
    ai.UnitDestroyed(unitID, unitDefID, unitTeam, nil, nil, nil)
end

-- Callouts
-- ========
function ai.RelevateLeader(unitID)
    if ai.leaders[unitID] == nil then
        return
    end

    if #ai.leaders[unitID] > 0 then
        local squad = ai.leaders[unitID]
        local l = ai.squad[i]
        table.remove(ai.squad, 1)
        ai.leaders[l] = ai.squad
    end
    ai.leaders[unitID] = nil
    ai.targets[unitID] = nil
end

function ai.RemoveUnit(unitID)
    -- Eventually relevate him as leader
    ai.RelevateLeader(unitID)
    -- And remove the unit for the handled ones
    if ai.units[unitID] then
        ai.units[unitID] = nil
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
        if ai.leaders[l] ~= nil and #ai.leaders[l] < MAX_SQUAD_SIZE then
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
    if not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID) or units[unitID] then
        return
    end

    -- Assign the unit to an squad, or create a new one
    local unit_leader = ai._GetBestLeader(unitID)
    if unit_leader == nil then
        -- The unit should become a leader
        ai.leaders[unitID] = {}
        ai.units[unitID] = unitID
        return        
    end

    units[unitID] = unit_leader
    table.insert(leaders[unit_leader], unitID)
end

function ai._UpdateSquad(leader, squad)
    -- Check if it has already a target
    ai.UpdateTarget(leader)
    -- Advance to the target in formation
    -- {id = CMD.FIGHT,tag = 7,options = {alt = false,ctrl = true,internal = false,coded = 64,right = false,meta = false,shift = false,},params = {1321.21387,45.1745605,1144.25256,},}
    -- {id = CMD.SET_WANTED_MAX_SPEED,tag = 8,options = {alt = false,ctrl = true,internal = false,coded = 64,right = false,meta = false,shift = false,},params = {0.80000001,},}
end

function ai.Update()
    if next(ai.leaders, ai.leader) == nil then
        return
    end
    local leader, squad = next(ai.leaders, ai.leader)
    ai._UpdateSquad(leader, squad)
end
