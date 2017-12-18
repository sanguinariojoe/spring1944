
-- main.lua

-- Spam main file

config = include ("LuaRules/Configs/spam_config.lua")

local lifetime, ai_list = {}, {}
local randomness_factor = 16 -- Must be an integer and larger than zero
local multiplier = 1.0

local function GetInstance (team)
    for _, i in ipairs (ai_list) do
        if i.team == team then
            return i
        end
    end
    return nil
end

local function GetSpamTeams ()
    local l = {}
    for _, i in ipairs (ai_list) do
        table.insert (l, i.team)
    end
    return l
end

local function GetHq (team)
    local instance = GetInstance (team)
    if instance ~= nil then
        return instance.hq
    end
    return nil
end

local function CalcUnitLongevity (unitDefID)
    if UnitDefs[unitDefID].speed ~= 0 then
        return math.ceil ((Game.mapSizeX + Game.mapSizeZ) / UnitDefs[unitDefID].speed * 100)
    end
    return nil
end

local function MakeInstance (team)
    local instance = {}
    instance.team = team
    instance.ally = 0
    instance.unitCount = 0
    instance.hq = 0
    instance.build_list = {}
    instance.health_coeff = 1.0
    instance.enemies = {}
    for _, team in ipairs (Spring.GetTeamList ()) do
        if not Spring.AreTeamsAllied (team, instance.team) and team ~= Spring.GetGaiaTeamID () then
            table.insert (instance.enemies, team)
        end
    end
    if #instance.enemies == 0 then
        Spring.SetAlly (team, team, false) -- :)
        instance.current_enemy = team
    else
        instance.current_enemy = instance.enemies[math.random (#instance.enemies)]
    end
    instance.current_target = nil
    local x, y, z = Spring.GetTeamStartPosition (instance.current_enemy)
    instance.vector1 = {x, y ,z}
    instance.vector2 = {x, y ,z}
    instance.lastVector = false
    instance.current_squad = {}
    instance.current_squad_size = 0
    return instance
end

local function ApplyUnitBonus (unitID, hpBonus, losBonus)
    Spring.SetUnitMaxHealth (unitID, select (2, Spring.GetUnitHealth (unitID)) * hpBonus) -- Don't set health because it starts at building
    Spring.SetUnitSensorRadius (unitID, "los", losBonus * Spring.GetUnitSensorRadius (unitID, "los") * losBonus)
    Spring.SetUnitSensorRadius (unitID, "radar", Spring.GetUnitSensorRadius (unitID, "radar") * losBonus)
    Spring.SetUnitSensorRadius (unitID, "radarJammer", Spring.GetUnitSensorRadius (unitID, "radarJammer") * losBonus)
end

local function SetTarget (teamID, target)
    local instance = GetInstance (teamID)
    if instance == nil then
        return
    end
    local x, y, z
    if type (target) == "number" then
        if target <= #Spring.GetTeamList () and not Spring.AreTeamsAllied (teamID, target) then
            x, y, z = Spring.GetTeamStartPosition (target)
            instance.current_enemy = target
            local x, y, z = Spring.GetTeamStartPosition (instance.current_enemy)
            for _, unit in ipairs (Spring.GetTeamUnits (instance.team)) do
                Spring.GiveOrderToUnit (unit, CMD.FIGHT, {x, y, z}, {})
                Spring.GiveOrderToUnit (unit, CMD.MOVE, {x, y, z}, {"shift"}) -- For units that cannot fight
            end
        end
    elseif type (target) == "table" and #target == 3 then
        x = target[1]
        y = Spring.GetGroundHeight (x, z)
        z = target[3]
        instance.current_enemy = nil
    else
        target = nil
    end
    if target ~= nil then
        Spring.GiveOrderToUnit (instance.hq, CMD.FIGHT, {x, y, z}, {})
        Spring.GiveOrderToUnit (instance.hq, CMD.MOVE, {x, y, z}, {"shift"}) -- For units that cannot fight
    end
end

local function MakeRandomBuildOrder (build_list)
    local new_list = {}
    for _, i in ipairs (build_list) do
        for j = 0, i[2] do
            table.insert (new_list, i[1])
        end
    end
    for i = 1, #new_list + 1 do
        local x = math.random (#new_list) + 1
        if new_list[i] ~= new_list[x] and math.random (math.round (math.abs (x - i) / #new_list * randomness_factor) + 1) == 1 then
            local t = new_list[i]
            new_list[i] = new_list[x]
            new_list[x] = t
        end
    end
    return new_list
end

local function StartSpam (team)
    local instance = GetInstance (team)
    if instance == nil then
        return nil
    end
    for _, unit in ipairs (MakeRandomBuildOrder (config.build_order)) do
        Spring.GiveOrderToUnit (instance.hq, -(UnitDefNames[unit].id), {}, {"shift"})
    end
end

local function SpawnSpam (team)
    local instance = GetInstance (team)
    if instance == nil then
        return nil
    end
    local x, y, z = Spring.GetTeamStartPosition (team)
    local rot = 0
    local hq = Spring.CreateUnit ("spam_hq", x, y, z, rot, team) -- Create hq first and then remove all other units to not kill the team
    Spring.LevelHeightMap ((x - 4) / 16, (z - 4) / 16, (x + 4) / 16, (z + 4) / 16, y)
    --if select (Spring.GetTeamStartPosition (instance.team), 1) <= )
    instance.hq = hq
    for _, unit in ipairs (Spring.GetTeamUnits (team)) do -- Spawn hq first so game ending doesnt trigger
        if unit ~= hq then
            Spring.DestroyUnit (unit, false, true)
        end
    end
    Spring.SetTeamRulesParam (team, "commander", "{{" .. "-1, " .. tostring (hq) .. "}}", {public = true}) -- Galactic conquest specific needed setting
    if config.hq_metal_income ~= nil then
        Spring.SetUnitResourcing (hq, "umm", config.metal_income * multiplier)
    end
    if config.hq_energy_income ~= nil then
        Spring.SetUnitResourcing (hq, "ume", config.energy_income * multiplier)
    end
    if config.metal_storage then
	Spring.SetTeamResource (team, "ms", config.metal_storage)
	Spring.SetTeamResource (team, "m", config.metal_storage)
    end
    if config.energy_storage then
	Spring.SetTeamResource (team, "es", config.energy_storage)
	Spring.SetTeamResource (team, "e", config.energy_storage)
    end
    if config.hq_build_speed ~= nil then
        Spring.SetUnitBuildSpeed (hq, config.hq_build_speed * multiplier)
    end
    if config.hq_los ~= nil then
        Spring.SetUnitSensorRadius (hq, "los", config.hq_los * multiplier)
    end
    if config.hq_hp ~= nil then
        Spring.SetUnitMaxHealth (hq, config.hq_hp * multiplier)
        Spring.SetUnitHealth (hq, config.hq_hp * multiplier)
    end
    x, y, z = Spring.GetTeamStartPosition (instance.current_enemy)
    Spring.GiveOrderToUnit (hq, CMD.REPEAT, {1}, {}) -- Remove this when factories can idle in spring
    GG.Delay.DelayCall (function (t) StartSpam (t) end, {team}, config.wait * Game.gameSpeed * multiplier)
    return hq
end

function gadget:Initialize ()
    for _, t in ipairs (Spring.GetTeamList ()) do
        local isAI = select (4, Spring.GetTeamInfo (t))
        if isAI and Spring.GetTeamLuaAI (t) == gadget:GetInfo ().name then
            table.insert (ai_list, MakeInstance (t))
        end
    end
    if #ai_list == 0 then
        gadgetHandler:RemoveGadget ()
        return
    end
    local build_order = config.build_order
    for index, unit in ipairs (build_order) do
        if UnitDefNames[unit[1]] == nil then
            Spring.Echo ("Invalid unitdef name " .. unit[1] .. " specified in spam build order")
            for i = index, #build_order do
                build_order[i] = build_order[i + 1]
            end
        end
    end
    if #build_order == 0 then
        for _, instance in ipairs (ai_list) do
            Spring.KillTeam (instance.team)
        end
        Spring.Echo ("Empty spam build list, quitting check LuaRules/Configs/spam_config.lua.")
        gadgetHandler:RemoveGadget ()
        return
    end
    config.build_order = build_order
    Spring.Echo ("SPAM loaded for: " .. Game.gameName)
    for _, instance in ipairs (ai_list) do
        GG.Delay.DelayCall (function (i) SpawnSpam (i) end, {instance.team}, 1) -- Because in the first frame units need to be spawned by default gadget
    end
    for _, p in ipairs (Spring.GetPlayerList ()) do
        GG.Delay.DelayCall (Spring.SendMessageToPlayer, {p, config.warning}, config.wait * Game.gameSpeed * multiplier)
    end
end

function gadget:UnitCreated (unitID, unitDefID, unitTeam, builderID)
    local instance = GetInstance (unitTeam)
    if instance ~= nil then
        x, y, z = Spring.GetTeamStartPosition (instance.current_enemy)
        Spring.GiveOrderToUnit (unitID, CMD.FIRE_STATE, {2}, {"shift"})
        Spring.GiveOrderToUnit (unitID, CMD.MOVE_STATE, {2}, {"shift"})
        Spring.GiveOrderToUnit (unitID, CMD.FIGHT, {x, y, z}, {"shift"})
        Spring.GiveOrderToUnit (unitID, CMD.MOVE, {x, y, z}, {"shift"}) -- For units that cannot fight
        --Spring.SetUnitMaxHealth (unitID, maxHealth + instance.health_coeff)
        if instance.unitCount + 1 == max_units and instance.unitCount < max_units then -- Units may be created by gadgets thus check for extra
            Spring.GiveOrderToUnit (instance.hq, CMD.WAIT, {}, {})
            for _, player in ipairs (Spring.GetPlayerList ()) do
                Spring.SendMessageToPlayer (player, "Go forth my minions!")
            end
        end
        if unitID ~= instance.hq and instance.hq ~= 0 then --
            instance.unitCount = instance.unitCount + 1
            ApplyUnitBonus (unitID, config.unit_hp_multiplier * multiplier, config.unit_los_multiplier * multiplier)
        end
    end
end

function gadget:UnitFinished (unitID, unitDefID, unitTeam)
    local instance = GetInstance (unitTeam)
    if instance ~= nil then
        if unitID ~= instance.hq and instance.hq ~= 0 then --
            local l = CalcUnitLongevity (unitDefID)
            GG.Delay.DelayCall (Spring.DestroyUnit, {unitID, false}, l)
        end
    end
end

function gadget:UnitFromFactory (unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
    local instance = GetInstance (unitTeam)
    if instance ~= nil then
        --Spring.GiveOrderToUnit (unitID, CMD.WAIT, {}, {}) -- This callin is broken in 104 it blocks factory
        table.insert (instance.current_squad, unitID)
        instance.current_squad_size = instance.current_squad_size + UnitDefs[unitDefID].metalCost
        if instance.current_squad_size >= 5000 then
            for _, i in ipairs (instance.current_squad) do
                --Spring.GiveOrderToUnit (i, CMD.WAIT, {}, {})
            end
            instance.current_squad = {}
            instance.current_squad_size = 0
        end
    end
end

function gadget:UnitDamaged (unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam) 
    local instance = GetInstance (unitTeam)
    if instance ~= nil then
        if unitID == instance.hq and attackerTeam ~= nil and attackerTeam >= 0 and not Spring.AreTeamsAllied (unitTeam, attackerTeam) and attackerTeam ~= Spring.GetGaiaTeamID () then
            local x, y, z = Spring.GetTeamStartPosition (unitTeam)
            local units = Spring.GetUnitsInSphere (x, y, z, 256, unitTeam)
            --local x2, y2, z2 = Spring.GetTeamStartPosition (instance.current_enemy)
            Spring.GiveOrderToUnitArray (units, CMD.INSERT, {0, CMD.ATTACK, 0, attackerID}, {"alt"})
            --Spring.GiveOrderToUnitArray (units, CMD.INSERT, {0, CMD.FIGHT, CMD.OPT_SHIFT, x2, y2, z2}, {"alt"})
        end
    end
end

function gadget:UnitDestroyed (unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    local instance = GetInstance (unitTeam)
    if instance ~= nil then
        if unitID == instance.hq then
            for _, p in ipairs (Spring.GetPlayerList ()) do
                Spring.SendMessageToPlayer (p, "I'll see you in hell!")
            end
            Spring.KillTeam (unitTeam)
        else
            instance.health_coeff = instance.health_coeff + 0.1
            if instance.unitCount == max_units then
                Spring.GiveOrderToUnit (instance.hq, CMD.WAIT, {}, {})
            end
            instance.unitCount = instance.unitCount - 1
        end
    else
        if math.random (10) == 0 then
            for _, p in ipairs (Spring.GetPlayerList ()) do
                Spring.SendMessageToPlayer (p, "Die!")
            end
        end
    end
end

function gadget:UnitEnteredLos (unitID, unitTeam, allyTeam, unitDefID)
    for _, team in pairs (Spring.GetTeamList (allyTeam)) do
        local instance = GetInstance (team)
        if instance ~= nil then
           if unitTeam == instance.current_enemy then
               local x, y, z = Spring.GetUnitPosition (unitID)
           end
        end
    end
end

function gadget:UnitIdle (unitID, unitDefID, unitTeam)
    local instance = GetInstance (unitTeam)
    if instance ~= nil then
        if unitID == instance.hq then
            local maxHealth = select (2, Spring.GetUnitHealth (unitID))
            local metal, _, energy, _ = Spring.GetUnitResources (unitID)
            Spring.SetUnitResourcing (unitID, "umm", config.metal * config.hq_bonus_multiplier)
            Spring.SetUnitResourcing (unitID, "ume", config.energy * config.hq_bonus_multiplier)
            Spring.SetUnitBuildSpeed (unitID, Spring.GetUnitCurrentBuildPower (unitID) * config.hq_bonus_multiplier)
            Spring.SetUnitMaxHealth (unitID, maxHealth * config.hq_bonus_multiplier)
            Spring.SetUnitSensorRadius (unitID, "los", Spring.GetUnitSensorRadius (unitID, "los") * config.hq_bonus_multiplier)
            Spring.SetUnitSensorRadius (unitID, "radar", Spring.GetUnitSensorRadius (unitID, "radar") * config.hq_bonus_multiplier)
            Spring.SetUnitSensorRadius (unitID, "radarJammer", Spring.GetUnitSensorRadius (unitID, "radarJammer") * config.hq_bonus_multiplier)
            for i = 1, 4 do
                Spring.SetUnitWeaponState (unitID, i, "range", Spring.GetUnitMaxRange (unitID) * config.hq_bonus_multiplier)
            end
            Spring.SetUnitMaxRange (unitID, Spring.GetUnitMaxRange (unitID) * config.hq_bonus_multiplier)
            for _, unit in ipairs (make_random_build_order (build_order)) do
                GG.Delay.DelayCall (Spring.GiveOrderToUnit, {unitID, -(UnitDefNames[unit].id), {}, {"shift"}}, 1)
            end
            for _, p in ipairs (Spring.GetPlayerList ()) do
                Spring.SendMessageToPlayer (p, "Huahahhahahahhaaaa! Try and take me now!")
            end
        else
            GG.Delay.DelayCall (Spring.GiveOrderToUnit, {unitID, CMD.ATTACK, {Spring.GetUnitNearestEnemy (unitID)}, {}}, 1)
        end
    end
end

function gadget:TeamDied (team)
    local newlist = {}
    for _, instance in ipairs (ai_list) do
        if instance.team ~= team then
            table.insert (newlist, instance)
        end
    end
    ai_list = newlist
    for _, instance in ipairs (ai_list) do
        instance.enemies = {}
        for _, teamX in ipairs (Spring.GetTeamList ()) do
            local dead = select (3, Spring.GetTeamInfo (teamX))
            if not Spring.AreTeamsAllied (teamX, instance.team) and teamX ~= Spring.GetGaiaTeamID () and not dead and teamX ~= team then
                table.insert (instance.enemies, teamX)
            end
        end
        if #instance.enemies == 0 then -- Let the bots kill one another after game is over :p
            Spring.SetAlly (instance.team, team, false)
            instance.enemies[1] = instance.team
        end
        SetTarget (instance.team, instance.enemies[math.random (#instance.enemies)])
    end
end

GG.Spam = {GetTeams = GetSpamTeams,
           GetHq = GetHq,
           MakeInstance = MakeInstance,
           Spawn = SpawnSpam,
           SetTarget = SetTarget}
