-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

-- Slightly based on the Kernel Panic AI by KDR_11k (David Becker) and zwzsg.
-- Thanks to lurker for providing hints on how to make the AI run unsynced.

-- In-game, type /luarules craig in the console to toggle the ai debug messages

function gadget:GetInfo()
	return {
		name = "Campaign - Chapter I",
		desc = "Learn the infantry basics (Map:1944_Cooper_Hill_v3)",
		author = "Jose Luis Cercos-Pita",
		date = "2017-05-31",
		license = "GNU General Public License v3",
  		layer = -1,
		enabled = true
	}
end


local hasBot = false
for _, t in ipairs(Spring.GetTeamList()) do
    local teamID, _, _, isAI = Spring.GetTeamInfo(t)
    if isAI and Spring.GetTeamLuaAI(teamID) == gadget:GetInfo().name then
        hasBot = true
    end
end
if hasBot then
    include("LuaRules/Configs/campaign/chapter1.lua")
    include("LuaRules/Gadgets/campaign/campaign_api.lua")
end
