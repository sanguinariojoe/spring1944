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
                config.teams[1].teamID = teamID
            else
                config.teams[ia_index].teamID = teamID
                ia_index = ia_index + 1
            end
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
	end
end

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z)
	return true
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
	setmetatable(gadget, {
		__index = function() error("Attempt to read undeclared global variable", 2) end,
		__newindex = function() error("Attempt to write undeclared global variable", 2) end,
	})
	SetupCmdChangeAIDebugVerbosity()
end

function gadget:GamePreload()
	-- This is executed BEFORE headquarters / commander is spawned
	Log("gadget:GamePreload")
	-- Check the map
    if config.map and config.map ~= Game.mapName then
        error_msg = "Please, select the following map: " .. config.map
        return
    end
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
                config.teams[1].teamID = teamID
            else
                if Spring.GetTeamLuaAI(teamID) ~= gadget:GetInfo().name then
                    error_msg = string.format("Team %d should be controlled by ", i - gaia) .. gadget:GetInfo().name
                    return
                end
                config.teams[ia_index].teamID = teamID
                ia_index = ia_index + 1
            end
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
	end
end

--------------------------------------------------------------------------------
--
--  Game call-ins
--

function gadget:TeamDied(teamID)
	if team[teamID] then
		team[teamID] = nil
		Log("removed team ", teamID)
	end
end

--------------------------------------------------------------------------------
--
--  Unit call-ins
--

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
end

function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
end

-- This may be called by engine from inside Spring.GiveOrderToUnit (e.g. if unit limit is reached)
function gadget:UnitIdle(unitID, unitDefID, unitTeam)
end

end


-- Set up LUA AI framework.
callInList = {
	"GamePreload",
	--"GameStart",
	"GameFrame",
	"TeamDied",
	"UnitCreated",
	"UnitFinished",
	"UnitDestroyed",
	"UnitTaken",
	"UnitGiven",
	"UnitIdle",
}
return include("LuaRules/Gadgets/campaign/framework.lua")
