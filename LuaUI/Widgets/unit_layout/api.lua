-- util_layout/api.lua
-- AUTHOR: Code_Man
-- LICENSE: MIT X11

function LoadUnits(file, teamID)
    if not VFS.FileExists(file) then
        Spring.Echo("Layout file " .. file .. " not loadable")
        local gaiaTeamID = Spring.GetGaiaTeamID()
        local myTeamID = Spring.GetMyTeamID()
        Spring.Echo("Valid teams:")
        for _,t in ipairs(Spring.GetTeamList()) do
            if t == gaiaTeamID then
                Spring.Echo(t, "(Gaia)")
            elseif t == myTeamID then
                Spring.Echo(t, "(Player)")                
            else
                Spring.Echo(t)                
            end
        end
        return false
    end
    if Spring.GetTeamInfo(teamID) == nil then
        Spring.Echo("Invalid teamID")
        return false
    end

    local units = include(file)
    for _, unit in ipairs(units) do
        local u = Spring.CreateUnit(unit[1],
                                    unit[2], unit[3], unit[4],
                                    0, teamID)
        Spring.SetUnitRotation(u, 0, unit[5], 0)
    end
    return true
end

function LoadUnitsUnsynced(file, teamID)
    Spring.Echo("LoadUnitsUnsynced", file, teamID)
    if not VFS.FileExists(file) then
        Spring.Echo("Layout file " .. file .. " not loadable")
        return false
    end
    if Spring.GetTeamInfo(teamID) == nil then
        Spring.Echo("Invalid teamID")
        local gaiaTeamID = Spring.GetGaiaTeamID()
        local myTeamID = Spring.GetMyTeamID()
        Spring.Echo("Valid teams:")
        for _,t in ipairs(Spring.GetTeamList()) do
            if t == gaiaTeamID then
                Spring.Echo(t, "(Gaia)")
            elseif t == myTeamID then
                Spring.Echo(t, "(Player)")                
            else
                Spring.Echo(t)                
            end
        end
        return false
    end

    local units = include(file)
    for _, unit in ipairs(units) do
        -- Unfortunately, orientation is not supported
        Spring.SendCommands("give 1 " .. unit[1] .. " " .. teamID
                     .. " @" .. unit[2] .. "," .. unit[3] .. "," .. unit[4])
    end
    return true
end

function SaveUnits(file, teamID)
    if Spring.GetTeamInfo(teamID) == nil then
        Spring.Echo("Invalid teamID")
        local gaiaTeamID = Spring.GetGaiaTeamID()
        local myTeamID = Spring.GetMyTeamID()
        Spring.Echo("Valid teams:")
        for _,t in ipairs(Spring.GetTeamList()) do
            if t == gaiaTeamID then
                Spring.Echo(t, "(Gaia)")
            elseif t == myTeamID then
                Spring.Echo(t, "(Player)")                
            else
                Spring.Echo(t)                
            end
        end
        return false
    end
    local handle = io.open(file, "w")
    handle.write(handle, "return {\n")
    for _, unit in ipairs (Spring.GetTeamUnits(teamID)) do
        local x, y, z = Spring.GetUnitPosition (unit)
        handle.write(handle, "{"
            .. "'" .. UnitDefs[Spring.GetUnitDefID(unit)].name .. "'"
            .. ", " .. tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z)
            .. ", " .. tostring(Spring.GetUnitHeading(unit))
            .. "},\n")
    end
    handle.write(handle, "}")
    handle.close(handle)
    return true
end

function SaveUnitsUnsynced(file, teamID)
    return SaveUnits(file, teamID)
end
