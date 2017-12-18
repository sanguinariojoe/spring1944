
-- s44_spam_assist.lua

--

function gadget:GetInfo ()
    return {
        name      = "S44 Spam assist",
        desc      = "Enables certain s44 specific things for spammer ai.",
        author    = "Code_Man",
        date      = "18/12/2017",
        license   = "MIT X11",
        layer     = 1,
        enabled   = true
    }
end

if (not gadgetHandler:IsSyncedCode ()) then
    return false
end

function gadget:Initialize ()
    for _, t in ipairs (Spring.GetTeamList ()) do
        local isAI = select (4, Spring.GetTeamInfo (t))
        if isAI and Spring.GetTeamLuaAI (t) == "Spammer" then
            GG.S44_Spawn.SetSpawnFunc(t, function(t) return end)
        end
    end
end
