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
local disabledGarrisons = {}  -- disabledGarrisons[unitID] = true/nil

function SpawnGarrison(x, z)
    local unitID = Spring.CreateUnit(UNITNAME, x, 0, z, 0, Spring.GetGaiaTeamID())
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitAlwaysVisible(unitID, true)
end

function gadget:Initialize()
    local modOptions = Spring.GetModOptions()
    if modOptions.garrison then
        local x = MAP_WIDTH * modOptions.garrisonx / 100
        local z = MAP_HEIGHT * modOptions.garrisony / 100
        SpawnGarrison(x, z)
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
    if n % (30 * 3) == 0 then -- check every 3 seconds, TODO: too slow? SlowUpdate (16f)?
        for unitID, disabled in pairs(disabledGarrisons) do
            if disabled then
                local health, maxHealth = Spring.GetUnitHealth(unitID)
                if health / maxHealth > HEALTH_RESTORE_LEVEL then
                    Spring.SetUnitNeutral(unitID, false)
                    local env = Spring.UnitScript.GetScriptEnv(unitID)
                    Spring.UnitScript.CallAsUnit(unitID, env.Disabled, false)
                end
            end
        end
    end
end

else -- UNSYNCED

end


