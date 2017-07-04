-- Please check that this file is included just from synced gadget
-- The info regarding targets is stored at table ai.targets, where each leader
-- has an entry with his target.
-- Leaders will try to accomplish the target until it becomes impossible.

local _iconType_classification = {
    default = nil,
    rifle = "assault",
	paratrooper = "assault",
	assault = "assault",
	antitank = "assault",
	mortar = "longRange",
	sniper = "longRange",
	officer = nil,
	engineer = nil,
	advancedengineer = nil,
	engineervehicle = nil,
	lightmg = "assault",
	bar = "assault",
	flame = "assault",
	aaartillery = nil,
	atartillery = nil,
	aahalftrack = "longRange",
	aacar = "longRange",
	aatruck = nil,
	attruck = nil,
	fgtruck = nil,
	armoredcar = "longRange",
	artillery = nil,
	bomber = nil,
	fighter = nil,
	fighterbomber = nil,

	gerhq = nil,
	ushq = nil,
	gbrhq = nil,
	halftrack = "supply",
	heavytank = "longRange",
	medtank = "longRange",
	lighttank = "longRange",
	jeep = "scout",
	recon = "scout",
	selfprop = "longRange",
	sparty = "longRange",
	stockpile = "supply",
	rockettruck = "longRange",
	truck = "supply",
	ptruck = nil,
	truck_factory = nil,
	truck_barracks = nil,
	htruck = nil,
	rtruck = nil,
	ammo = "supply",
	ammo2 = "supply",
	factory = nil,
	usflag = nil,
	gbrflag = nil,
	gerflag = nil,
	mines = nil,
	rusflag = nil,
	commissar = "scout",
	partisan = "assault",
	commando = "assault",
	rubber = "assault",
	lttrans = nil,
	raft	= nil,
	rusptrd = nil,
	barracks = nil,
	radar = nil,
	flag = nil,
	shack = nil,
	shipyard = nil,
	hshipyard = nil,
	destroyer = "longRange",
	torpboat = "assault",
	gunboat = "longRange",
	artyboat = "longRange",
	turret = nil,
	landingship = "assault",
	transportship = nil,
	transportplane = nil,
	flametank = "assault",
	itahq = nil,
	itasolo = "assault",
	itascopedsolo = "assault",
	jpnhq = nil,
	swehq = nil,
	hunhq = nil,
}

function ai.AdvanceToTarget(leader, squad, target)
    local tx, ty, tz = Spring.GetUnitPosition(target)
    local units = {table.unpack(squad)}
    table.insert(units, 1, leader)
    -- Classify the units
    local assault = {}      -- Close combat units
    local scouts = {}       -- Scouting units, just to get enemies in LOS
    local binocs = {}       -- Special unit
    local longRange = {}    -- They should keep as far as possible
    local supply = {}
    for _,u in ipairs(units) do
        local udef = Spring.GetUnitDefID(u)
        local class_string = _iconType_classification[UnitDefs[udef].iconType]
        if class_string == "assault" then
            table.insert(assault, 1, u)
        elseif class_string == "scouts" then
            table.insert(scouts, 1, u)
        elseif class_string == "binocs" then
            table.insert(binocs, 1, u)
        elseif class_string == "longRange" then
            table.insert(longRange, 1, u)
        elseif class_string == "supply" then
            table.insert(supply, 1, u)
        end
    end
end
