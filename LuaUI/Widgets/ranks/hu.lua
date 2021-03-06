local Drawer = VFS.Include("LuaUI/Widgets/ranks/utilities/drawing.lua", nil, VFS.RAW_FIRST)
local IMAGE_DIRNAME = LUAUI_DIRNAME .. "Images/Ranks/"

----------------------------------------------------------------
--speedups
----------------------------------------------------------------
local sin, cos, tan = math.sin, math.cos, math.tan
local sqrt = math.sqrt
local rad = math.rad

local glColor = gl.Color
local glTexture = gl.Texture
local glTexRect = gl.TexRect

----------------------------------------------------------------
--gl lists
----------------------------------------------------------------
local color = {1, 1, 0.25}
local highlightColor = {1, 1, 0.5}

local function Kozkatona()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNKozkatona.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Orvezeto()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNOrvezeto.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Tizedes()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNTizedes.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Szakaszvezeto()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNSzakaszvezeto.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Ormester()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNOrmester.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Torzsormester()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNTorzsormester.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Fotorzsormester()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNFotorzsormester.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Zaszlos()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNZaszlos.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Torzszaszlos()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNTorzszaszlos.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Fotorzszaszlos()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNFotorzszaszlos.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Hadnagy()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNHadnagy.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Fohadnagy()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNFohadnagy.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Szazados()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNSzazados.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Ornagy()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNOrnagy.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Alezredes()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNAlezredes.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Ezredes()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNEzredes.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Dandartabornok()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNDandartabornok.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Vezerornagy()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNVezerornagy.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Altabornagy()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNAltabornagy.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

local function Vezerezredes()
    glColor(1, 1, 1, 1)
    glTexture(IMAGE_DIRNAME .. "HUNVezerezredes.png")
    glTexRect(-2, -2, 2, 2)
    glTexture(false)
end

return {
    name = "hu",
    lists = {
        -- OR-1
        {0.1, 0, Kozkatona},
        -- OR-2
        {0.2, 0, Orvezeto},
        -- OR-3
        {0.3, 0, Tizedes},
        -- OR-4
        {0.5, 0, Szakaszvezeto},
        -- OR-5
        {0.75, 0, Ormester},
        -- OR-6
        {1.0, 0, Torzsormester},
        -- OR-7
        {1.25, 0, Fotorzsormester},
        -- OR-8
        {1.5, 0, Zaszlos},
        {1.75, 0, Torzszaszlos},
        -- OR-9
        {2.0, 0, Fotorzszaszlos},
        -- OF-1
        {2.5, 0, Hadnagy},
        {3.0, 0, Fohadnagy},
        -- OF-2
        {3.5, 0, Szazados},
        -- OF-3
        {5.0, 0, Ornagy},
        -- OF-4
        {8.0, 0, Alezredes},
        -- OF-5
        {12.0, 0, Ezredes},
        -- OF-6
        {20.0, 0, Dandartabornok},
        -- OF-7
        {25.0, 0, Vezerornagy},
        -- OF-8
        {30.0, 0, Altabornagy},
        -- OF-9
        {50.0, 0, Vezerezredes},
    },
}
