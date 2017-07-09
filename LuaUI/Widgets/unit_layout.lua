-- util_layout.lua

-- Saves and loads unit positions into a file

function widget:GetInfo ()
    return {
        name = "Unit Layout",
        desc = "Saves and loads unit positions into/from a file",
        author = "Code_Man",
        date = "18/10/2015",
        license = "MIT X11",
        layer = 1,
        enabled = true,
    }
end

include("LuaUI/Widgets/unit_layout/api.lua")

function LoadUnitsChatAction(cmd, optLine)
    if not Spring.IsCheatingEnabled() then
        Spring.Echo("Load units require cheats enabled")
        return false
    end

    local filename = Game.gameShortName .. "_layout_" .. Game.mapName .. ".lua"
    local teamID = Spring.GetGaiaTeamID()

    words = {}
    for word in optLine:gmatch("%w+") do
        table.insert(words, word)
    end
    for i = 1,#words,2 do
        if words[i] == 'filename' then
            filename = words[i + 1]
        elseif words[i] == 'teamID' then
            teamID = tonumber(words[i + 1])
        end
    end
  
    return LoadUnitsUnsynced(filename, teamID)
end

function SaveUnitsChatAction(cmd, optLine)
    local filename = Game.gameShortName .. "_layout_" .. Game.mapName .. ".lua"
    local teamID = Spring.GetMyTeamID()
    
    words = {}
    for word in optLine:gmatch("%S+") do
        table.insert(words, word)
    end
    for i = 1,#words,2 do
        if words[i] == 'filename' then
            filename = words[i + 1]
        elseif words[i] == 'teamID' then
            teamID = tonumber(words[i + 1])
        end
    end

    Spring.Echo("SaveUnits", filename, teamID)
    return SaveUnitsUnsynced(filename, teamID)
end

function widget:Initialize()
    -- /layoutload [filename path] [teamID val]
    widgetHandler:AddAction("layoutload", LoadUnitsChatAction)
    -- /layoutsave [filename path] [teamID val]
    widgetHandler:AddAction("layoutsave", SaveUnitsChatAction)
end
