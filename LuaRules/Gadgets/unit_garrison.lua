function gadget:GetInfo()
  return {
    name      = "Garrisons Helper",
    desc      = "Does stuffs for Garrisons",
    author    = "Sanguinario_Joe (Jose Luis Cercos-Pita)",
    date      = "15/3/2018",
    license   = "GNU GPL v2",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end


if (gadgetHandler:IsSyncedCode()) then -- SYNCED

-- Constants
local MIN_HEALTH = 1 -- No fewer HP than this
local HEALTH_RESTORE_LEVEL = 0.5 -- What % of maxHP to restore garrison function
local UNITNAME = "garrison_housemansion"
local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ

-- Garrisons tracking
local garrisons = {}          -- garrisons[1] = unitID
local disabledGarrisons = {}  -- disabledGarrisons[unitID] = true/nil

function SpawnGarrison(x, z)
    local unitID = Spring.CreateUnit(UNITNAME, x, 0, z, 0, Spring.GetGaiaTeamID())
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitAlwaysVisible(unitID, true)
end

function gadget:GameStart()
    local modOptions = Spring.GetModOptions()
    if modOptions.garrison then
        local x = MAP_WIDTH * modOptions.garrisonx / 100
        local z = MAP_HEIGHT * modOptions.garrisony / 100
        SpawnGarrison(x, z)
    end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
    local ud = UnitDefs[unitDefID]
    local cp = ud.customParams
    if cp.garrison then
        garrisons[#garrisons + 1] = unitID
    end
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
    local udef = UnitDefs[unitDefID]
    if not udef.customParams.garrison then
        return
    end

    local health = Spring.GetUnitHealth(unitID)
    if health - damage < MIN_HEALTH then
        local newDamage = health - MIN_HEALTH
        Spring.SetUnitNeutral(unitID, true)
        local env = Spring.UnitScript.GetScriptEnv(unitID)
        Spring.UnitScript.CallAsUnit(unitID, env.Disabled, true)
        disabledGarrisons[unitID] = true
        return newDamage
    end
    return damage
end

function gadget:GameFrame(n)
    if n % (30 * 3) == 5 then -- check every 3 seconds, TODO: too slow? SlowUpdate (16f)?
        for unitID, disabled in pairs(disabledGarrisons) do
            if disabled then
                local health, maxHealth = Spring.GetUnitHealth(unitID)
                if health / maxHealth > HEALTH_RESTORE_LEVEL then
                    Spring.SetUnitNeutral(unitID, false)
                    local env = Spring.UnitScript.GetScriptEnv(unitID)
                    Spring.UnitScript.CallAsUnit(unitID, env.Disabled, false)
                    disabledGarrisons[unitID] = nil
                end
            end
        end

        for _, unitID in ipairs(garrisons) do
            -- The Garrison belongs, in the first place, to the faction with
            -- loaded units inside (blocking the capture)
            local paxs = Spring.GetUnitIsTransporting(unitID)
            if not paxs or #paxs == 0 then
                -- OK, the building is free, so it will belongs to the faction
                -- with more capturing units close to it
                local x, y, z = Spring.GetUnitPosition(unitID)
                local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
                local cp = ud.customParams
                local unitsAtFlag = Spring.GetUnitsInCylinder(x, z, cp.capradius)
                local teamID = Spring.GetGaiaTeamID()
                local capRates = {teamID = 0.000001}
                for _, visitor in ipairs(unitsAtFlag) do
                    local ud = UnitDefs[Spring.GetUnitDefID(visitor)]
                    local capRate = ud.customParams.flagcaprate or 0
                    local tid = Spring.GetUnitTeam(visitor)
                    capRates[tid] = (capRates[tid] or 0) + capRate
                    if capRates[tid] > capRates[teamID] then
                        -- tid team has now more cap points than teamID
                        teamID = tid
                    end
                end
                -- Give the building to the faction with more forces around it
                Spring.TransferUnit(unitID, teamID, false)
            end
        end
    end
end

else -- UNSYNCED

end


