function gadget:GetInfo()
	return {
		name = "CAMPAIGN",
		desc = "Campaign gadget",
		author = "Jose Luis Cercos-Pita",
		date = "2017-07-7",
		license = "GNU General Public License v3",
  		layer = -1,
		enabled = true,
	}
end

include("LuaRules/Gadgets/campaign/ai.lua")
local error_msg = nil

if (gadgetHandler:IsSyncedCode()) then

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  SYNCED
--

function gadget:GamePreload()
    local ia_index = 2
    for _, t in ipairs(Spring.GetTeamList()) do
        local teamID, _, _, isAI = Spring.GetTeamInfo(t)
        local gaiaTeamID = Spring.GetGaiaTeamID()
        if teamID ~= gaiaTeamID then
            if not isAI then
                Spring.Echo("config.teams[1]", teamID)
                config.teams[1].teamID = teamID
            else
                Spring.Echo("config.teams", ia_index, teamID)
                config.teams[ia_index].teamID = teamID
                ia_index = ia_index + 1
            end
        end
    end
    -- Set the factions
    for _, t in ipairs(config.teams) do
        if t.faction then
            Spring.SetTeamRulesParam(t.teamID, "side", t.faction, {allied=true, public=false}) -- visible to allies only, set visible to all on GameStart
        end
    end    
end

function gadget:GameFrame(f)
    if error_msg then
        -- Something went wrong, the bot may not continue working
        Warning(error_msg)
        return
    end

	if f == 1 then
        -- Eventually correct the allies
        for _, ti in ipairs(config.teams) do
            for _, tj in ipairs(config.teams) do
                Spring.SetAlly(ti.teamID, tj.teamID, ti.ally == tj.ally)
            end
        end
        -- Setup the initial units
        for _, t in ipairs(config.teams) do
            if t.units then
                -- Get the default units (already created)
                local units = Spring.GetTeamUnits(t.teamID)
                -- Spawn the requested ones
                for _, u in ipairs(t.units) do
                    if u.pos then
                        x, y, z = u.pos[1], u.pos[2], u.pos[3]
                    else
                        x, y, z = Spring.GetTeamStartPosition(t.teamID)
                    end
                    Spring.CreateUnit(u.unit, x, y, z, u.facing, t.teamID)
                end
                -- Remove them
                for _, u in ipairs(units) do
                    Spring.DestroyUnit(u, false, true)
                end
            end
        end
    else
	end

    ai.Update()
end

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z)
	return true
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
    ai.UnitCreated(unitID, unitDefID, unitTeam, builderID)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    ai.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    ai.UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
end

function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    ai.UnitTaken(unitID, unitDefID, unitTeam, newTeam)
end

else

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  UNSYNCED
--

--constants
local MY_PLAYER_ID = Spring.GetMyPlayerID()

-- include code
-- include("LuaRules/Gadgets/craig/buildsite.lua")

-- locals
local BOT_Debug_Mode = 1 -- Must be 0 or 1
local team = {}
local mainPlayer = nil
local allyTeamID = nil

--------------------------------------------------------------------------------

local function ChangeAIDebugVerbosity(cmd,line,words,player)
	local lvl = tonumber(words[1])
	if lvl then
		BOT_Debug_Mode = lvl
		Spring.Echo("CAMPAIGN: debug verbosity set to " .. BOT_Debug_Mode)
	else
		if BOT_Debug_Mode > 0 then
			BOT_Debug_Mode = 0
		else
			BOT_Debug_Mode = 1
		end
		Spring.Echo("CAMPAIGN: debug verbosity toggled to " .. BOT_Debug_Mode)
	end
	return true
end

local function SetupCmdChangeAIDebugVerbosity()
	local cmd,func,help
	cmd  = "craig"
	func = ChangeAIDebugVerbosity
	help = " [0|1]: make CAMPAIGN shut up or fill your infolog"
	gadgetHandler:AddChatAction(cmd,func,help)
	--Script.AddActionFallback(cmd .. ' ',help)
end

function gadget.Log(...)
	if BOT_Debug_Mode > 0 then
		Spring.Echo("CAMPAIGN: " .. table.concat{...})
	end
end

-- This is for log messages which can not be turned off (e.g. while loading.)
function gadget.Warning(...)
	Spring.Echo("CAMPAIGN: " .. table.concat{...})
end

local current_mission = nil

function gadget.Success()
    if current_mission.finish then
        GameOver({allyTeamID})
        current_mission = nil
    else
        LoadMission()
    end
end

function gadget.Fail()
    local enemies = {}
    for _, t in ipairs(Spring.GetTeamList()) do
        local teamID, _, _, _, _, alliesID = Spring.GetTeamInfo(t)
        if alliesID ~= allyTeamID then
            local shouldAdd = true
            for _, e in ipairs(enemies) do
                if e == alliesID then
                    shouldAdd = false
                    break
                end
            end
            if shouldAdd then
                enemies[#enemies + 1] = alliesID
            end
        end
    end
    GameOver(enemies)
    current_mission = nil
end

function gadget.LoadMission()
    -- Load the mission
    if current_mission == nil then
        current_mission = missions[1]
        current_mission.id = 1
    else
        local id = current_mission.id + 1
        current_mission = missions[id]
        current_mission.id = id
    end
    -- Check if it is the last mission
    current_mission.finish = current_mission.id == #missions
    -- Reinit the timer and event
    current_mission.timer = Spring.GetTimer()
    current_mission.event_id = 1
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in routines
--

-- Execution order:
--  gadget:Initialize
--  gadget:GamePreload
--  gadget:UnitCreated (for each HQ / comm)
--  gadget:GameStart

function gadget:Initialize()
	Log("gadget:Initialize")
    --[[
	setmetatable(gadget, {
		__index = function() error("Attempt to read undeclared global variable", 2) end,
		__newindex = function() error("Attempt to write undeclared global variable", 2) end,
	})
    --]]
	SetupCmdChangeAIDebugVerbosity()
end

function gadget:GamePreload()
	-- This is executed BEFORE headquarters / commander is spawned
	Log("gadget:GamePreload")
    -- Setup the teams
    if #config.teams ~= #Spring.GetTeamList() - 1 then
        error_msg = string.format("Got %d teams, but %d are required", #Spring.GetTeamList(), #config.teams)
        return
    end
    local ia_index = 2
    for _, t in ipairs(Spring.GetTeamList()) do
        local teamID, _, _, isAI = Spring.GetTeamInfo(t)
        local gaiaTeamID = Spring.GetGaiaTeamID()
        if teamID ~= gaiaTeamID then
            if not isAI then
                Spring.Echo("config.teams[1]", teamID)
                config.teams[1].teamID = teamID
            else
                if Spring.GetTeamLuaAI(teamID) ~= "Campaign empty bot" then
                    error_msg = string.format("Team %d should be controlled by Campaign empty bot", ia_index - gaia)
                    return
                end
                Spring.Echo("config.teams", ia_index, teamID)
                config.teams[ia_index].teamID = teamID
                ia_index = ia_index + 1
            end
        end
    end
    -- Get player data
	local myTeamID = Spring.GetMyTeamID()
	for _,t in ipairs(Spring.GetTeamList()) do
	    local teamID, leader, _, isAI = Spring.GetTeamInfo(t)
        if not isAI then
            mainPlayer = leader
        end
        if not isAI and teamID == myTeamID then
            allyTeamID = Spring.GetMyAllyTeamID()
	    end
    end
end

function gadget:GameFrame(f)
    if error_msg then
        -- Something went wrong, the bot may not continue working
        Warning(error_msg)
        return
    end

    if f == 1 then
        -- This is executed AFTER headquarters / commander is spawned
        Log("gadget:GameFrame 1")
        -- Load the mission (just if we are the player instance)
        if current_mission == nil then
            -- For some reason it is calling each function twice
            LoadMission()
        end
    end

    if current_mission then
        -- Launch delay based events
        AfterDelay()
        -- Check triggered events
        Triggers()
    end
end

--------------------------------------------------------------------------------
--
--  Events
--


function gadget.DrawMarker(x, y, z, msg)
    Spring.MarkerAddPoint(x, y, z, msg)
end

function gadget.EraseMarker(x, y, z)
    Spring.MarkerErasePosition(x, y, z)
end

function gadget.DrawLine(x0, y0, z0, x1, y1, z1)
    Spring.MarkerAddLine(x0, y0, z0, x1, y1, z1)
end

function gadget.MessageToPlayer(msg)
    Spring.Echo(msg)
end

function gadget.CreateUnit(unitName, x, y, z, facing, teamID)
    SyncedFunction("Spring.CreateUnit", {unitName, x, y, z, facing, config.teams[teamID].teamID})
end

function gadget.SwitchUnitCommand(unitID, cmdName, enabled)
    local cmds = Spring.GetUnitCmdDescs(unitID)
    for _,cmd in ipairs(cmds) do
        if cmd.name == cmdName then
            local cmdDescID = Spring.FindUnitCmdDesc(unitID, cmd.id)
            SyncedFunction("Spring.EditUnitCmdDesc", {unitID, cmdDescID, {disabled = not enabled}})
            break
        end
    end
end

function gadget.GetUnitCmdDesc(unitID, cmdID)
    -- Notice the difference with Spring.GetUnitCmdDescs
    local cmds = Spring.GetUnitCmdDescs(unitID)
    for _,cmd in ipairs(cmds) do
        if cmd.id == cmdID then
            return cmd
        end
    end
    return nil
end

function gadget.AfterDelay()
    local event_id = current_mission.event_id
    if not current_mission.events or event_id > #current_mission.events then
        return
    end
    local delay = Spring.DiffTimers(Spring.GetTimer(), current_mission.timer)
    local event_delay = current_mission.events[event_id][1]
    if delay >= event_delay then
        local command = loadstring(current_mission.events[event_id][2])
        command()
        current_mission.event_id = event_id + 1
    end
end

function EvalTrigger(trigger)
    local command = loadstring("value = " .. trigger)
    command()
    return value
end

function AreUnitsInPosition(units, x, y, z, radius)
    for _, u in ipairs(units) do
        xu, yu, zu = Spring.GetUnitPosition(u)
        dx, dy, dz = xu - x, yu - y, zu - z
        if dx * dx + dz * dz > radius * radius then
            return false
        end
    end
    return true
end

function IsAreaCleared(x, y, z, radius)
    for _, t in ipairs(Spring.GetTeamList()) do
        local teamID, _, _, _, _, alliesID = Spring.GetTeamInfo(t)
        if alliesID ~= allyTeamID then
            if #Spring.GetUnitsInCylinder(x, z, radius, teamID) > 0 then
                return false
            end
        end
    end
    return true
end

function IsFlagCaptured(x, y, z)
    local radius = 100
    local units = Spring.GetUnitsInCylinder(x, z, radius, Spring.GetMyTeamID())
    for _, u in ipairs(units) do
        local unitDefID = Spring.GetUnitDefID(u)
        if UnitDefs[unitDefID].name == "flag" then
            return true
        end
    end
    return false
end

function FilterUnitsByName(units, unitName)
    local filtered = {}
    for _, u in ipairs(units) do
        local unitDefID = Spring.GetUnitDefID(u)
        if UnitDefs[unitDefID].name == unitName then
            filtered[#filtered + 1] = u
        end
    end
    return filtered
end

function gadget.Triggers()
    if not current_mission or not current_mission.triggers then
        return
    end
    for i, t in ipairs(current_mission.triggers) do
        -- Check if it should be triggered (LUA enforce us to store the command
        -- result in an helper variable)
        if EvalTrigger(t[1]) then
            command = loadstring(t[2])
            -- Remove the trigger if it should not be executed again
            if current_mission and t.once then
                table.remove(current_mission.triggers, i)
            end
            -- Excute the command
            command()
            -- Just one triggered event per frame
            return
        end
    end
end

--------------------------------------------------------------------------------
--
--  Game call-ins
--

function gadget:TeamDied(teamID)
end

--------------------------------------------------------------------------------
--
--  Unit call-ins
--

function gadget.CallIn(callInName, params)
    if not current_mission or not current_mission.callins then
        return
    end
    for i, c in ipairs(current_mission.callins) do
        -- Check if it should be triggered
        if callInName == c[1] then
            command = loadstring(c[2])
            -- Remove the trigger if it should not be executed again
            if current_mission and c.once then
                table.remove(current_mission.callins, i)
            end
            -- Excute the command
            local locals = {}
            for k,v in pairs(gadget) do
                -- Shallow copy of gadget
                locals[k] = v
            end
            -- Add the params
            locals["params"] = params
            setfenv(command, setmetatable(locals, { __index = _G })) 
            command()
        end
    end    
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
    CallIn("UnitCreated", {unitID=unitID, unitDefID=unitDefID, unitTeam=unitTeam, builderID=builderID})
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
    CallIn("UnitFinished", {unitID=unitID, unitDefID=unitDefID, unitTeam=unitTeam})
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
    CallIn("UnitDamaged", {unitID=unitID, unitDefID=unitDefID, unitTeam=unitTeam, damage=damage, paralyzer=paralyzer, weaponDefID=weaponDefID, projectileID=projectileID, attackerID=attackerID, attackerDefID=attackerDefID, attackerTeam=attackerTeam})
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    CallIn("UnitDestroyed", {unitID=unitID, unitDefID=unitDefID, unitTeam=unitTeam, attackerID=attackerID, attackerDefID=attackerDefID, attackerTeam=attackerTeam})
end

function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    CallIn("UnitTaken", {unitID=unitID, unitDefID=unitDefID, unitTeam=unitTeam, newTeam=newTeam})
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    CallIn("UnitGiven", {unitID=unitID, unitDefID=unitDefID, unitTeam=unitTeam, oldTeam=oldTeam})
end

-- This may be called by engine from inside Spring.GiveOrderToUnit (e.g. if unit limit is reached)
function gadget:UnitIdle(unitID, unitDefID, unitTeam)
    CallIn("UnitIdle", {unitID=unitID, unitDefID=unitDefID, unitTeam=unitTeam})
end

end


-- Set up LUA AI framework.
callInList = {
	"GamePreload",
	--"GameStart",
	"GameFrame",
	"TeamDied",
	"UnitCreated",
	"UnitDamaged",
	"UnitFinished",
	"UnitDestroyed",
	"UnitTaken",
	"UnitGiven",
	"UnitIdle",
}
return include("LuaRules/Gadgets/campaign/framework.lua")
