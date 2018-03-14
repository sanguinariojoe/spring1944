unitDefID = Spring.GetUnitDefID(unitID)
unitDef = UnitDefs[unitDefID]


-- Pieces
local base = piece("base")
local function findPieces(input, name)
    local pieceMap = Spring.GetUnitPieceMap(unitID)
    --{ "piecename1" = pieceNum1, ... , "piecenameN" = pieceNumN }
    for pieceName, pieceNum in pairs(pieceMap) do
        local index = pieceName:find(name)
        if index then
            -- add a condition for unnumbered child which would be the first and only
            local num = tonumber(pieceName:sub(index + string.len(name), -1)) or 1
            input[num] = piece(pieceName)
        end
    end
end
 
local links = {}
findPieces(links, "link")

-- Occupied positions
passengers = {}

function script.Create()
    -- Disable all the collision volumes, except the ones named with the prefix
    -- 'block' (without quotes). That way, we can let the base object (and
    -- others) take only a visual role
    local pieceMap = Spring.GetUnitPieceMap(unitID)
    for pieceName, pieceNum in pairs(pieceMap) do
        local p = piece(pieceName)
        local sx, sy, sz, ox, oy, oz, vtype, ttype, paxis =
            Spring.GetUnitPieceCollisionVolumeData(unitID, p)
        local index = pieceName:find("block")
        Spring.Echo("    ", index)
        if index == 1 then
            Spring.Echo(sx, sy, sz, ox, oy, oz)
            -- Shrink the object to avoid shielding passengers
            sx = math.max(1, sx - 16)
            sy = math.max(1, sy - 16)
            sz = math.max(1, sz - 16)
            Spring.SetUnitPieceCollisionVolumeData(unitID, p, true,
                sx, sy, sz, ox, oy, oz, vtype, paxis)            
        else
            Spring.SetUnitPieceCollisionVolumeData(unitID, p, false,
                sx, sy, sz, ox, oy, oz, vtype, paxis)
        end
    end
end

function script.TransportPickup(passengerID)
    for _, link in pairs(links) do
        if passengers[link] == nil then
            passengers[link] = passengerID
            Spring.UnitScript.AttachUnit(link, passengerID)
            Spring.SetUnitNoSelect(passengerID, true)
            break
        end
    end
end

function script.TransportDrop (passengerID, x, y, z )
    for _, link in pairs(links) do
        if passengers[link] == passengerID then
            passengers[link] = nil
            break
        end
    end
    Spring.UnitScript.DropUnit(passengerID)
end
