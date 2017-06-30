-- Please check that this file is included just from synced gadget
-- The info regarding targets is stored at table ai.targets, where each leader
-- has an entry with his target.
-- Leaders will try to accomplish the target until it becomes impossible.

local _flags = nil
local _targeteables = {}
local _targeteable_names = {
    "flag" = 0.5,
    "buoy" = 0.5,
    "*barracks*" = 1.0,
    "*tankyard*" = 2.0,
    "*yard*" = 1.0,
    "*engineer*" = 2.0,
    "*engvehicle*" = 3.0,
    "*hq*" = 1.5,
}

function ai.AddTargeteable(unitID)
    local uname = UnitDefs[Spring.GetUnitDefID(unitID)].name
    for tname,tval in ipairs(_targeteable_names) do
        if name = string.match(uname, tname) then
            _targeteables[unitID] = tval
            break
        end
    end
end

function ai.RemoveTargeteable(unitID)
    _targeteables[unitID] = nil
end


function ai.GiveUpTarget(unitID)
    targets[unitID] = nil
end

function ai.AssignTarget(unitID)
    -- This function is computing a new target, just in case a target has not
    -- been selected yet. It is not overwriting targets, to do that, please
    -- call before to GiveUpTarget
    if leaders[unitID] == nil or targets[unitID] ~= nil then
        return
    end

    -- Parse the list of potential targets. The targets would be classified
    -- depending on their priority and distance
    
end

function ai.UpdateTarget(unitID)
    if leaders[unitID] == nil then
        if targets[unitID] ~= nil then
            -- This is not a leader, so why a target?
            targets[unitID] = nil
        end
        return
    end
    -- Check the target

    -- Try to eventually add a target
    ai.AssignTarget(unitID)
end
