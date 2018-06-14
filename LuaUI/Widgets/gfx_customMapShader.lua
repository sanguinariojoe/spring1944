function widget:GetInfo()
   return {
      name      = "s44MapShader",
      desc      = "Spring:1944 map shader",
      author    = "jlcercos",
      date      = "11/06/2018",
      license   = "GPLv3",
      layer     = 0,
      enabled   = true,
   }
end

local glCreateShader       = gl.CreateShader
local glGetShaderLog       = gl.GetShaderLog
local glGetUniformLocation = gl.GetUniformLocation
local glUseShader          = gl.UseShader
local glGetMatrixData      = gl.GetMatrixData
local glUniform            = gl.Uniform
local glUniformMatrix      = gl.UniformMatrix
local glTexture            = gl.Texture
local glGetSun             = gl.GetSun
local glGetAtmosphere      = gl.GetAtmosphere
local glGetMapRendering    = gl.GetMapRendering      -- >= 104.0
local glGetWaterRendering  = gl.GetWaterRendering  -- >= 104.0
local SetMapShader      = Spring.SetMapShader
local GetCameraPosition = Spring.GetCameraPosition
local HaveShadows       = Spring.HaveShadows
local GetMapDrawMode    = Spring.GetMapDrawMode

local shader
local cameraPosID, lightDirID
local mapSizePO2ID, mapSizeID, groundAmbientColorID, groundDiffuseColorID
local groundSpecularColorID, groundSpecularExponentID, groundShadowDensityID
local waterMinColorID, waterBaseColorID, waterAbsorbColorID
local splatTexScalesID, splatTexMultsID, infoTexIntensityMulID
local normalTexGenID, specularTexGenID, infoTexGenID


local GRID_SIZE = Game.squareSize
local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ
local MAP_WIDTHPO2 = math.ceil(math.log(MAP_WIDTH / GRID_SIZE)) ^ 2 * GRID_SIZE
local MAP_HEIGHTPO2 = math.ceil(math.log(MAP_HEIGHT / GRID_SIZE)) ^ 2 * GRID_SIZE


local function readMapInfo()
    local paths = {
        "mapinfo.lua",
        "maphelper/mapinfo.lua",
    }
    for _, v in ipairs(paths) do
        if VFS.FileExists(v) then
            return VFS.Include(v)
        end
    end

    return nil
end
local MAP_INFO = nil -- readMapInfo()  -- Quite unsafe


local function CompileShader()
    -- Original shaders
    local vertex = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\MapShaderVert.glsl", VFS.ZIP)
    local fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\MapShaderFrag.glsl", VFS.ZIP)
    -- Shader definitions
    local definitions = {
        "#version 130",
        -- "#define SMF_SPECULAR_LIGHTING",
        -- "#define SMF_DETAIL_TEXTURE_SPLATTING",
        -- "#define SMF_DETAIL_NORMAL_TEXTURE_SPLATTING",
        -- "#define SMF_DETAIL_NORMAL_DIFFUSE_ALPHA",
        -- "#define SMF_WATER_ABSORPTION",
        -- "#define SMF_SKY_REFLECTIONS",
        "#define SMF_BLEND_NORMALS",
        -- "#define SMF_LIGHT_EMISSION",
        "#define HAVE_INFOTEX",  -- We define it, and modify infoTexIntensityMul accordingly
    }
    if MAP_INFO and MAP_INFO.resources and MAP_INFO.resources.parallaxheighttex then
        definitions[#definitions + 1] = "#define SMF_PARALLAX_MAPPING"
    end
    if glGetMapRendering and glGetMapRendering("voidWater") then
        definitions[#definitions + 1] = "#define SMF_VOID_WATER"
    end
    if glGetMapRendering and glGetMapRendering("voidGround") then
        definitions[#definitions + 1] = "#define SMF_VOID_GROUND"
    end
    if HaveShadows() then
        -- definitions[#definitions + 1] = "#define HAVE_SHADOWS"
    end
    definitions = table.concat(definitions, "\n")
    fragment = definitions .. "\n" .. fragment

    -- Create the shader
    local shader = glCreateShader({
        vertex = vertex,
        fragment = fragment,
        uniformInt = {
            diffuseTex = 0,
            detailTex = 2,
            shadowTex = 4,
            normalsTex = 5,
            specularTex = 6,
            splatDetailTex = 7,
            splatDistrTex = 8,
            skyReflectTex = 9,
            skyReflectModTex = 10,
            blendNormalsTex = 11,
            lightEmissionTex = 12,
            parallaxHeightTex = 13,
            infoTex = 14,
            splatDetailNormalTex1 = 15,
            splatDetailNormalTex2 = 16,
            splatDetailNormalTex3 = 17,
            splatDetailNormalTex4 = 18,
        },
    })
    return shader
end

function widget:Initialize()
    shader = CompileShader()
    if not shader then
        Spring.Log("Map shader", "error",
                   "Failed to create map shader!")
        Spring.Echo(gl.GetShaderLog())
        widgetHandler:RemoveWidget()
        return
    end

    SetMapShader(shader, 0)
end

function widget:Shutdown()
    SetMapShader(0, 0)
end

local function GetViewRange()
    local m22 = glGetMatrixData(GL.PROJECTION, 10)
    local m32 = glGetMatrixData(GL.PROJECTION, 14)
    local near = (2.0 * m32) / (2.0 * m22 - 2.0)
    local far = ((m22 - 1.0) * near) / (m22 + 1.0)
    return far
end

function widget:DrawWorld()
    local x, y, z, w

    glUseShader(shader)

    if not cameraPosID then
        cameraPosID = glGetUniformLocation(shader, "cameraPos")
        lightDirID = glGetUniformLocation(shader, "lightDir")
        mapSizePO2ID = glGetUniformLocation(shader, "mapSizePO2")
        mapSizeID = glGetUniformLocation(shader, "mapSize")
        normalTexGenID = glGetUniformLocation(shader, "normalTexGen")
        specularTexGenID = glGetUniformLocation(shader, "specularTexGen")
        infoTexGenID = glGetUniformLocation(shader, "infoTexGen")
        groundAmbientColorID = glGetUniformLocation(shader, "groundAmbientColor")
        groundDiffuseColorID = glGetUniformLocation(shader, "groundDiffuseColor")
        groundSpecularColorID = glGetUniformLocation(shader, "groundSpecularColor")
        groundSpecularExponentID = glGetUniformLocation(shader, "groundSpecularExponent")
        groundShadowDensityID = glGetUniformLocation(shader, "groundShadowDensity")
        waterMinColorID = glGetUniformLocation(shader, "waterMinColor")
        waterBaseColorID = glGetUniformLocation(shader, "waterBaseColor")
        waterAbsorbColorID = glGetUniformLocation(shader, "waterAbsorbColor")
        splatTexScalesID = glGetUniformLocation(shader, "splatTexScales")
        splatTexMultsID = glGetUniformLocation(shader, "splatTexMults")
        infoTexIntensityMulID = glGetUniformLocation(shader, "infoTexIntensityMul")
    end

    x, y, z = GetCameraPosition()
    glUniform(cameraPosID, x, y, z)
    x, y, z = glGetSun()
    glUniform(lightDirID, x, y, z, 0.0)
    glUniform(mapSizePO2ID, MAP_WIDTHPO2 * 1.0, MAP_HEIGHTPO2 * 1.0)
    glUniform(mapSizeID, MAP_WIDTH * 1.0, MAP_HEIGHT * 1.0)
    glUniform(normalTexGenID, 1.0 / MAP_WIDTHPO2, 1.0 / MAP_HEIGHTPO2)
    glUniform(specularTexGenID, 1.0 / MAP_WIDTH, 1.0 / MAP_HEIGHT)
    glUniform(infoTexGenID, 1.0 / MAP_WIDTHPO2, 1.0 / MAP_HEIGHTPO2)
    x, y, z = glGetSun("diffuse")
    glUniform(groundAmbientColorID, x, y, z)
    x, y, z = glGetSun("ambient")
    glUniform(groundDiffuseColorID, x, y, z)
    x, y, z = glGetSun("specular")
    glUniform(groundSpecularColorID, x, y, z)
    local groundSpecularExponent = 100.0
    glUniform(groundSpecularExponentID, groundSpecularExponent)
    glUniform(groundShadowDensityID, glGetSun("shadowDensity"))
    if glGetWaterRendering then
        x, y, z = glGetWaterRendering("minColor")
        glUniform(waterMinColorID, x, y, z)
        x, y, z = glGetWaterRendering("baseColor")
        glUniform(waterBaseColorID, x, y, z)
        x, y, z = glGetWaterRendering("absorb")
        glUniform(waterAbsorbColorID, x, y, z)
    else
        -- We use the default colors...
        x, y, z = 0.1, 0.1, 0.3
        if MAP_INFO and MAP_INFO.water and MAP_INFO.water.mincolor then
            x = MAP_INFO.water.mincolor[1]
            y = MAP_INFO.water.mincolor[2]
            z = MAP_INFO.water.mincolor[3]
        end
        glUniform(waterMinColorID, x, y, z)
        x, y, z = 0.4, 0.6, 0.8
        if MAP_INFO and MAP_INFO.water and MAP_INFO.water.basecolor then
            x = MAP_INFO.water.basecolor[1]
            y = MAP_INFO.water.basecolor[2]
            z = MAP_INFO.water.basecolor[3]
        end
        glUniform(waterBaseColorID, x, y, z)
        x, y, z = 0.004, 0.004, 0.002
        if MAP_INFO and MAP_INFO.water and MAP_INFO.water.absorb then
            x = MAP_INFO.water.absorb[1]
            y = MAP_INFO.water.absorb[2]
            z = MAP_INFO.water.absorb[3]
        end
        glUniform(waterAbsorbColorID, x, y, z)
    end
    if glGetMapRendering then
        x, y, z, w = glGetMapRendering("splatTexScales")
        glUniform(splatTexScalesID, x, y, z, w)
        x, y, z, w = glGetMapRendering("splatTexMults")
        glUniform(splatTexMultsID, x, y, z, w)
    else
        x, y, z, w = 0.02, 0.02, 0.02, 0.02
        if MAP_INFO and MAP_INFO.splats and MAP_INFO.splats.texscales then
            x = MAP_INFO.splats.texscales[1]
            y = MAP_INFO.splats.texscales[2]
            z = MAP_INFO.splats.texscales[3]
            z = MAP_INFO.splats.texscales[4]
        end
        glUniform(splatTexScalesID, x, y, z, w)
        x, y, z, w = 1.0, 1.0, 1.0, 1.0
        if MAP_INFO and MAP_INFO.splats and MAP_INFO.splats.texmults then
            x = MAP_INFO.splats.texmults[1]
            y = MAP_INFO.splats.texmults[2]
            z = MAP_INFO.splats.texmults[3]
            z = MAP_INFO.splats.texmults[4]
        end
        glUniform(splatTexMultsID, x, y, z, w)
    end

    if GetMapDrawMode() == "normal" then
        glUniform(infoTexIntensityMulID, 1.0)
    else
        glUniform(infoTexIntensityMulID, 1.0)
    end
    -- Spring.GetMapDrawMode

    glUseShader(0)
end

local function SetTextures()
    glTexture(0, "$shading")
    glTexture(2, "$detail")
    glTexture(4, "$shadow")
    glTexture(5, "$normals")
    glTexture(6, "$ssmf_specular")
    glTexture(7, "$ssmf_splat_detail")
    glTexture(8, "$ssmf_splat_distr")
    glTexture(9, "$map_reflection")
    glTexture(10, "$sky_reflection")
    glTexture(11, "$ssmf_normals")
    glTexture(12, "$ssmf_emission")
    if MAP_INFO and MAP_INFO.resources.parallaxheighttex then
        glTexture(13, "$ssmf_parallax")
    end
    glTexture(14, "$info")
    glTexture(15, "$ssmf_splat_normals:0")
    glTexture(16, "$ssmf_splat_normals:1")
    glTexture(17, "$ssmf_splat_normals:2")
    glTexture(18, "$ssmf_splat_normals:3")
end

function widget:DrawGroundPreForward()
    SetTextures()
end

function widget:DrawGroundPreDeferred()
    SetTextures()
end

local function UnsetTextures()
    glTexture(0, false)
    glTexture(2, false)
    for i=4,18 do
        glTexture(i, false)
    end
end

function widget:DrawGroundPostDeferred()
    UnsetTextures()
end
