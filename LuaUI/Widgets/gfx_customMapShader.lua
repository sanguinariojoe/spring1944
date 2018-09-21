function widget:GetInfo()
   return {
      name      = "s44MapShader",
      desc      = "Spring:1944 map shader",
      author    = "jlcercos",
      date      = "11/06/2018",
      license   = "GPLv3",
      layer     = 0,
      enabled   = false,
   }
end


local glCreateShader        = gl.CreateShader
local glGetShaderLog        = gl.GetShaderLog
local glGetMapRendering     = gl.GetMapRendering
local glGetWaterRendering   = gl.GetWaterRendering
local glGetSun              = gl.GetSun
local glGetMatrixData       = gl.GetMatrixData
local glGetShadowMapParams  = gl.GetShadowMapParams
local glTextureInfo         = gl.TextureInfo
local glGetUniformLocation  = gl.GetUniformLocation
local glUniform             = gl.Uniform
local glUniformInt          = gl.UniformInt
local glUniformArray        = gl.UniformArray
local glUniformMatrix       = gl.UniformMatrix
local glTexture             = gl.Texture
local glUseShader           = gl.UseShader
local glGetActiveUniforms   = gl.GetActiveUniforms
local SetMapShader      = Spring.SetMapShader
local HaveShadows       = Spring.HaveShadows
local GetCameraPosition = Spring.GetCameraPosition
local GetMapDrawMode    = Spring.GetMapDrawMode
local GetGroundExtremes = Spring.GetGroundExtremes
local GetMapOptions     = Spring.GetMapOptions


CustomMapShaders = {
    forward = {
        vertex_src = nil,
        fragment_src = nil,
        shader = nil,
        uniforms = {},
        textures = {},
        sunchanged = false
    },
    deferred = {
        vertex_src = nil,
        fragment_src = nil,
        shader = nil,
        uniforms = {},
        textures = {},
        sunchanged = false
    }
}

function log2(n)
    return math.log(n) / math.log(2)
end

function nextPowerOf2(n)
    pos = math.ceil(log2(n))
    return math.pow(2, pos)
end

SQUARE_SIZE = 8
MAPX = Game.mapSizeX
MAPZ = Game.mapSizeZ
PWR2MAPX = nextPowerOf2(MAPX / SQUARE_SIZE) * SQUARE_SIZE
PWR2MAPZ = nextPowerOf2(MAPZ / SQUARE_SIZE) * SQUARE_SIZE
MAX_TEXTURE_UNITS = 32

Uniform = {}
Uniform.__index = Uniform

function Uniform:init(name, shader, value, setter, t)
    local uniform = {}
    setmetatable(uniform,Uniform)
    uniform.name = name
    uniform.shader = shader
    if shader then
        uniform.loc = glGetUniformLocation(shader, name)
    else
        uniform.loc = -1
    end
    uniform.value = value
    uniform.setter = setter
    uniform.type = t or 2  -- float by default. Used just in gl.UniformArray
    return uniform
end

function Uniform:getShader()
    return self.loc
end

function Uniform:setShader(shader)
    self.shader = shader
end

function Uniform:getLoc()
    return self.loc
end

function Uniform:setLoc(loc)
    self.loc = loc
end

function Uniform:getValue()
    return self.value
end

function Uniform:setValue(value)
    self.value = value
end

function Uniform:bind()
    if self.loc == -1 then
        return
    end
    if self.setter == glUniformArray then
        if (type(self.value) ~= "table") then
            Spring.Log("Map shader", "error",
                       "gl.UniformArray requires a table to set '" .. self.name .. "'")
            return
        end
        self.setter(self.loc, self.type, self.value)
    elseif self.setter == glUniformMatrix then
        if (type(self.value) ~= "table") or (#self.value ~= 16) then
            Spring.Log("Map shader", "error",
                       "gl.UniformMatrix requires 16 numbers to set '" .. self.name .. "'")
            return
        end
        self.setter(self.loc,
                    self.value[ 1], self.value[ 2], self.value[ 3], self.value[ 4],
                    self.value[ 5], self.value[ 6], self.value[ 7], self.value[ 8],
                    self.value[ 9], self.value[10], self.value[11], self.value[12],
                    self.value[13], self.value[14], self.value[15], self.value[16])
    else
        if (type(self.value) == "table") then
            if (#self.value == 1) then
                self.setter(self.loc, self.value[1])
            elseif (#self.value == 2) then
                self.setter(self.loc, self.value[1], self.value[2])
            elseif (#self.value == 3) then
                self.setter(self.loc, self.value[1], self.value[2], self.value[3])
            elseif (#self.value == 4) then
                self.setter(self.loc, self.value[1], self.value[2], self.value[3], self.value[4])
            else
                Spring.Log("Map shader", "error",
                           "gl.Uniform/gl.UniformInt requires a table of 1-4 numbers to set '" .. self.name .. "'")                
            end
        else
            self.setter(self.loc, self.value)
        end
    end
end


function glHasTexture(texid)
    local texinfo = glTextureInfo(texid)
    if (texinfo == nil) or (texinfo.xsize == 0) or (texinfo.ysize == 0) then
        return false
    end
    return true
end

function glGetMapShaderFlag(flag)
    if flag == "SMF_VOID_WATER" then
        return glGetMapRendering("voidWater")
    elseif flag == "SMF_VOID_GROUND" then
        return glGetMapRendering("voidGround")
    elseif flag == "SMF_SPECULAR_LIGHTING" then
        return glHasTexture("$ssmf_specular")
    elseif flag == "SMF_DETAIL_TEXTURE_SPLATTING" then
        return glHasTexture("$ssmf_splat_distr") and glHasTexture("$ssmf_splat_detail")
    elseif flag == "SMF_DETAIL_NORMAL_TEXTURE_SPLATTING" then
        return glHasTexture("$ssmf_splat_distr") and glHasTexture("$ssmf_splat_normals")
    elseif flag == "SMF_DETAIL_NORMAL_DIFFUSE_ALPHA" then
        return false  -- Let's ignore this for the time being
    elseif flag == "SMF_WATER_ABSORPTION" then
        if glGetMapRendering("voidWater") then
            return false
        end
        _, _, y = GetGroundExtremes()
        return y < 0
    elseif flag == "SMF_SKY_REFLECTIONS" then
        return glHasTexture("$sky_reflection")
    elseif flag == "SMF_BLEND_NORMALS" then
        return glHasTexture("$ssmf_normals")
    elseif flag == "SMF_LIGHT_EMISSION" then
        return glHasTexture("$ssmf_emission")
    elseif flag == "SMF_PARALLAX_MAPPING" then
        return glHasTexture("$ssmf_parallax")
    elseif flag == "HAVE_SHADOWS" then
        return HaveShadows()
    elseif flag == "HAVE_INFOTEX" then
        return (GetMapDrawMode() ~= nil) and (GetMapDrawMode() ~= "normal")
    else
        Spring.Log("Map shader", "error",
                    "Unknown map default flag '" .. flag .. "'!")
    end
end

function glGetMapShaderFlags(flags)
    values = {}
    for i, flag in ipairs(flags) do
        values[i] = glGetMapShaderFlag(flag)
    end
    return values
end

function glGetMapShaderUniformValue(name)
    if name == "mapSizePO2" then
        return {PWR2MAPX, PWR2MAPZ}
    elseif name == "mapSize" then
        return {MAPX, MAPZ}
    elseif name == "cameraPos" then
        x, y, z = GetCameraPosition()
        return {x, y, z}
    elseif name == "lightDir" then
        x, y, z = glGetSun("pos")
        return {x, y, z, 1}
    elseif name == "groundAmbientColor" then
        x, y, z = glGetSun("ambient")
        return {x, y, z}
    elseif name == "groundDiffuseColor" then
        x, y, z = glGetSun("diffuse")
        return {x, y, z}
    elseif name == "groundSpecularColor" then
        x, y, z = glGetSun("specular")
        return {x, y, z}
    elseif name == "groundSpecularExponent" then
        return glGetSun("specularExponent")
    elseif name == "groundShadowDensity" then
        return glGetSun("shadowDensity")
    elseif name == "shadowMat" then
         m0,  m1,  m2,  m3,
         m4,  m5,  m6,  m7,
         m8,  m9, m10, m11,
        m12, m13, m14, m15 = glGetMatrixData("shadow")
        return { m0,  m1,  m2,  m3,
                 m4,  m5,  m6,  m7,
                 m8,  m9, m10, m11,
                m12, m13, m14, m15}
    elseif name == "shadowParams" then
        x, y, z, w = glGetShadowMapParams()
        return {x, y, z, w}
    elseif name == "waterMinColor" then
        x, y, z = glGetWaterRendering("minColor")
        return {x, y, z}
    elseif name == "waterBaseColor" then
        x, y, z = glGetWaterRendering("baseColor")
        return {x, y, z}
    elseif name == "waterAbsorbColor" then
        x, y, z = glGetWaterRendering("absorb")
        return {x, y, z}
    elseif name == "splatTexScales" then
        x, y, z, w = glGetMapRendering("splatTexScales")
        return {x, y, z, w}
    elseif name == "splatTexMults" then
        x, y, z, w = glGetMapRendering("splatTexMults")
        return {x, y, z, w}
    elseif name == "infoTexIntensityMul" then
        local mode = GetMapDrawMode()
        if mode == "metal" then
            return 2.0
        else
            return 1.0
        end
    elseif name == "normalTexGen" then
        local texinfo = glTextureInfo("$normals")
        x = (texinfo.xsize - 1) * SQUARE_SIZE
        z = (texinfo.ysize - 1) * SQUARE_SIZE
        return {1.0 / x, 1.0 / z}
    elseif name == "specularTexGen" then
        return {1.0 / MAPX, 1.0 / MAPZ}
    elseif name == "infoTexGen" then
        return {1.0 / PWR2MAPX, 1.0 / PWR2MAPZ}
    elseif name == "mapHeights" then
        _, _, z, w = GetGroundExtremes()
        return {z, w}
    end
    return nil
end

function glGetMapShaderUniform(name, shader)
    local value = glGetMapShaderUniformValue(name)
    if value == nil then
        return nil
    end
    local setter
    if name == "shadowMat" then
        setter = glUniformMatrix
    else
        setter = glUniform
    end
    return Uniform:init(name, shader, value, setter)
end

function glGetMapShaderUniforms(names, shader)
    local x, y, z, w
    uniforms = {}
    for _, name in pairs(names) do
        uniforms[name] = glGetMapShaderUniform(name, shader)
    end
    return uniforms
end


local _plugins = {
    PBR_INCLUDE = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\pbr.inc.glsl", VFS.ZIP),
}

local function InsertPlugin(str)
  return (_plugins and _plugins[str]) or ""
end

function CompileShader(deferred)
    -- Original shaders
    local vertex = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\MapShaderVert.glsl", VFS.ZIP)
    local fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\MapShaderFrag.glsl", VFS.ZIP)
    -- Shader definitions and uniforms (we initialize all the uniforms locs as 0)
    local definitions = {
        "#version 130",
        "#define NOSPRING",
    }
    if deferred then
        definitions[#definitions + 1] = "#define DEFERRED_MODE"
    end
    -- Bind the textures far away from the slots used by spring, to avoid
    -- further collisions. Bear in mind that we are not never unbinding the
    -- textures
    textures = {-- diffuseTex = {0, "$map_gbuffer_difftex"}, -- Already binded
                detailTex = {2, "$detail"},
                -- shadowTex = {MAX_TEXTURE_UNITS - 15, "$shadow"},
                normalsTex = {MAX_TEXTURE_UNITS - 14, "$normals"},
                -- specularTex = {MAX_TEXTURE_UNITS - 13, "$ssmf_specular"},
                -- splatDetailTex = {MAX_TEXTURE_UNITS - 12, "$ssmf_splat_detail"},
                -- splatDistrTex = {MAX_TEXTURE_UNITS - 11, "$ssmf_splat_distr"},
                -- skyReflectTex = {MAX_TEXTURE_UNITS - 10, "$map_reflection"},
                -- skyReflectModTex = {MAX_TEXTURE_UNITS - 9, "$sky_reflection"},
                -- blendNormalsTex = {MAX_TEXTURE_UNITS - 8, "$ssmf_normals"},
                -- lightEmissionTex = {MAX_TEXTURE_UNITS - 7, "$ssmf_emission"},
                -- parallaxHeightTex = {MAX_TEXTURE_UNITS - 6, "$ssmf_parallax"},
                -- infoTex = {MAX_TEXTURE_UNITS - 5, "$info"},
                -- splatDetailNormalTex1 = {MAX_TEXTURE_UNITS - 4, "$ssmf_splat_normals:0"},
                -- splatDetailNormalTex2 = {MAX_TEXTURE_UNITS - 3, "$ssmf_splat_normals:1"},
                -- splatDetailNormalTex3 = {MAX_TEXTURE_UNITS - 2, "$ssmf_splat_normals:2"},
                -- splatDetailNormalTex4 = {MAX_TEXTURE_UNITS - 1, "$ssmf_splat_normals:3"},
    }
    if glGetMapShaderFlag("SMF_VOID_WATER") then
        definitions[#definitions + 1] = "#define SMF_VOID_WATER"
    end
    if glGetMapShaderFlag("SMF_VOID_GROUND") then
        definitions[#definitions + 1] = "#define SMF_VOID_GROUND"
    end
    if glGetMapShaderFlag("SMF_SPECULAR_LIGHTING") then
        definitions[#definitions + 1] = "#define SMF_SPECULAR_LIGHTING"
        textures["specularTex"] = {MAX_TEXTURE_UNITS - 13, "$ssmf_specular"}
    end
    if glGetMapShaderFlag("SMF_DETAIL_TEXTURE_SPLATTING") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_TEXTURE_SPLATTING"
        if not glGetMapShaderFlag("SMF_DETAIL_NORMAL_TEXTURE_SPLATTING") then
            textures["splatDetailTex"] = {MAX_TEXTURE_UNITS - 12, "$ssmf_splat_detail"}
            textures["splatDistrTex"] = {MAX_TEXTURE_UNITS - 11, "$ssmf_splat_distr"}
        end
    end
    if glGetMapShaderFlag("SMF_DETAIL_NORMAL_TEXTURE_SPLATTING") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_NORMAL_TEXTURE_SPLATTING"
        textures["splatDistrTex"] = {MAX_TEXTURE_UNITS - 11, "$ssmf_splat_distr"}
        textures["splatDetailNormalTex1"] = {MAX_TEXTURE_UNITS - 4, "$ssmf_splat_normals:0"}
        textures["splatDetailNormalTex2"] = {MAX_TEXTURE_UNITS - 3, "$ssmf_splat_normals:1"}
        textures["splatDetailNormalTex3"] = {MAX_TEXTURE_UNITS - 2, "$ssmf_splat_normals:2"}
        textures["splatDetailNormalTex4"] = {MAX_TEXTURE_UNITS - 1, "$ssmf_splat_normals:3"}
    end
    if glGetMapShaderFlag("SMF_DETAIL_NORMAL_DIFFUSE_ALPHA") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_NORMAL_DIFFUSE_ALPHA"
    end
    if glGetMapShaderFlag("SMF_WATER_ABSORPTION") then
        definitions[#definitions + 1] = "#define SMF_WATER_ABSORPTION"
    end
    if glGetMapShaderFlag("SMF_SKY_REFLECTIONS") then
        definitions[#definitions + 1] = "#define SMF_SKY_REFLECTIONS"
        textures["skyReflectTex"] = {MAX_TEXTURE_UNITS - 10, "$map_reflection"}
        textures["skyReflectModTex"] = {MAX_TEXTURE_UNITS - 9, "$sky_reflection"}
    end
    if glGetMapShaderFlag("SMF_BLEND_NORMALS") then
        definitions[#definitions + 1] = "#define SMF_BLEND_NORMALS"
        textures["blendNormalsTex"] = {MAX_TEXTURE_UNITS - 8, "$ssmf_normals"}
    end
    if glGetMapShaderFlag("SMF_LIGHT_EMISSION") then
        definitions[#definitions + 1] = "#define SMF_LIGHT_EMISSION"
        textures["lightEmissionTex"] = {MAX_TEXTURE_UNITS - 7, "$ssmf_emission"}
    end
    if glGetMapShaderFlag("SMF_PARALLAX_MAPPING") then
        definitions[#definitions + 1] = "#define SMF_PARALLAX_MAPPING"
        textures["parallaxHeightTex"] = {MAX_TEXTURE_UNITS - 6, "$ssmf_parallax"}
    end
    if glGetMapShaderFlag("HAVE_SHADOWS") then
        definitions[#definitions + 1] = "#define HAVE_SHADOWS"
        textures["shadowTex"] = {MAX_TEXTURE_UNITS - 15, "$shadow"}
    end
    if glGetMapShaderFlag("HAVE_INFOTEX") then
        definitions[#definitions + 1] = "#define HAVE_INFOTEX"
        textures["infoTex"] = {MAX_TEXTURE_UNITS - 5, "$info"}
    end
    -- definitions[#definitions + 1] = "#define BASE_DYNAMIC_MAP_LIGHT " .. tostring(glGetMapRendering("baseDynamicMapLight"))
    -- definitions[#definitions + 1] = "#define MAX_DYNAMIC_MAP_LIGHTS " .. tostring(glGetMapRendering("maxDynamicMapLight"))
    definitions = table.concat(definitions, "\n")
    fragment = definitions .. "\n" .. fragment
    fragment = fragment:gsub("%%%%([%a_]+)%%%%", InsertPlugin);    

    local old_vertex, old_fragment
    if deferred then
        old_vertex = CustomMapShaders.deferred.vertex_src
        old_fragment = CustomMapShaders.deferred.fragment_src
    else
        old_vertex = CustomMapShaders.forward.vertex_src
        old_fragment = CustomMapShaders.forward.fragment_src
    end
    if (old_vertex == vertex) and (old_fragment == fragment) then
        return false
    end

    Spring.Echo("--- Map Vertex shader ---------------------------------------")
    Spring.Echo(vertex)
    Spring.Echo("--------------------------------------- Map Vertex shader ---")
    Spring.Echo("--- Map Fragment shader -------------------------------------")
    Spring.Echo(fragment)
    Spring.Echo("------------------------------------- Map Fragment shader ---")

    -- Create the shader
    local mapopts = GetMapOptions()
    local metallic_base = tonumber(mapopts["metallic"] or "0.0")
    local newshader = glCreateShader({
        vertex = vertex,
        fragment = fragment,
        uniformInt = {diffuseTex = 0,
                      detailTex = 2,
                      shadowTex = MAX_TEXTURE_UNITS - 15,
                      normalsTex = MAX_TEXTURE_UNITS - 14,
                      specularTex = MAX_TEXTURE_UNITS - 13,
                      splatDetailTex = MAX_TEXTURE_UNITS - 12,
                      splatDistrTex = MAX_TEXTURE_UNITS - 11,
                      skyReflectTex = MAX_TEXTURE_UNITS - 10,
                      skyReflectModTex = MAX_TEXTURE_UNITS - 9,
                      blendNormalsTex = MAX_TEXTURE_UNITS - 8,
                      lightEmissionTex = MAX_TEXTURE_UNITS - 7,
                      parallaxHeightTex = MAX_TEXTURE_UNITS - 6,
                      infoTex = MAX_TEXTURE_UNITS - 5,
                      splatDetailNormalTex1 = MAX_TEXTURE_UNITS - 4,
                      splatDetailNormalTex2 = MAX_TEXTURE_UNITS - 3,
                      splatDetailNormalTex3 = MAX_TEXTURE_UNITS - 2,
                      splatDetailNormalTex4 = MAX_TEXTURE_UNITS - 1,
                      brdfLUT = MAX_TEXTURE_UNITS - 16,
        },
        uniformFloat = {metallic_base = metallic_base,
        }
    })
    if not newshader then
        Spring.Log("Map shader", "error",
                   "Failed to create map shader!")
        Spring.Echo(glGetShaderLog())
        return false
    end

    -- Initialize the default uniforms
    local active_uniforms = glGetActiveUniforms(newshader)
    local names = {}
    for i, active_uniform in ipairs(active_uniforms) do
        names[i] = active_uniform.name
    end
    local uniforms = glGetMapShaderUniforms(names, newshader)
    glUseShader(newshader)
        for _, uniform in pairs(uniforms) do
            uniform:bind()
        end
    glUseShader(0)
    
    if deferred then
        CustomMapShaders.deferred.vertex_src = vertex
        CustomMapShaders.deferred.fragment_src = fragment
        CustomMapShaders.deferred.shader = newshader
        CustomMapShaders.deferred.uniforms = uniforms
        CustomMapShaders.deferred.textures = textures
    else
        CustomMapShaders.forward.vertex_src = vertex
        CustomMapShaders.forward.fragment_src = fragment
        CustomMapShaders.forward.shader = newshader
        CustomMapShaders.forward.uniforms = uniforms
        CustomMapShaders.forward.textures = textures
    end

    return true
end

function widget:Initialize()
    if not glGetMapRendering then
        Spring.Log("Map shader", "error",
                   "Invalid engine version!")
        widgetHandler:RemoveWidget()
        return
    end
end

function widget:Shutdown()
    SetMapShader(0, 0)
end

function setDefaultUniforms(uniforms)
    for name, uniform in pairs(uniforms) do
        uniform:setValue(glGetMapShaderUniformValue(name))
        uniform:bind()
    end
end

function setDefaultTextures(textures)
    for _, texture in pairs(textures) do
        glTexture(texture[1], texture[2])
    end
end

function unsetDefaultTextures(textures)
    for _, texture in pairs(textures) do
        glTexture(texture[1], false)
    end
end

function widget:DrawGenesis()
    local newshader
    newshader = CompileShader()
    newshader = CompileShader(true) or newshader
    if not newshader then
        return
    end

    SetMapShader(CustomMapShaders.forward.shader,
                 CustomMapShaders.deferred.shader)
end

FRAME_DEFAULT_UNIFORMS = {"mapHeights",
                          "cameraPos",
                          "shadowMat",
                          "shadowParams",
                          "infoTexIntensityMul"}
SUNCHANGED_DEFAULT_UNIFORMS = {"lightDir",
                               "groundShadowDensity",
                               "groundAmbientColor",
                               "groundDiffuseColor",
                               "groundSpecularColor"}

function widget:DrawGroundPreForward()
    local uniforms = {}
    for _, name in pairs(FRAME_DEFAULT_UNIFORMS) do
        uniforms[name] = CustomMapShaders.forward.uniforms[name]
    end
    if CustomMapShaders.forward.sunchanged then
        for _, name in pairs(SUNCHANGED_DEFAULT_UNIFORMS) do
            uniforms[name] = CustomMapShaders.forward.uniforms[name]
        end
        CustomMapShaders.forward.sunchanged = false
    end
    setDefaultUniforms(uniforms)
    setDefaultTextures(CustomMapShaders.forward.textures)
    -- PBR requires a last texture
    glTexture(MAX_TEXTURE_UNITS - 16, 'unittextures/brdfLUT.png')
end

function widget:DrawGroundPreDeferred()
    local uniforms = {}
    for _, name in pairs(FRAME_DEFAULT_UNIFORMS) do
        uniforms[name] = CustomMapShaders.deferred.uniforms[name]
    end
    if CustomMapShaders.deferred.sunchanged then
        for _, name in pairs(SUNCHANGED_DEFAULT_UNIFORMS) do
            uniforms[name] = CustomMapShaders.deferred.uniforms[name]
        end
        CustomMapShaders.deferred.sunchanged = false
    end
    setDefaultUniforms(uniforms)
    setDefaultTextures(CustomMapShaders.deferred.textures)
end

function widget:SunChanged()
    CustomMapShaders.forward.sunchanged = true
    CustomMapShaders.deferred.sunchanged = true
end
