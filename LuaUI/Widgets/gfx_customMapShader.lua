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
local SetMapShader      = Spring.SetMapShader
local HaveShadows       = Spring.HaveShadows
local GetCameraPosition = Spring.GetCameraPosition
local GetMapDrawMode    = Spring.GetMapDrawMode
local GetGroundExtremes = Spring.GetGroundExtremes


CustomMapShaders = {
    forward = {
        vertex_src = nil,
        fragment_src = nil,
        shader = nil,
        uniforms = {},
        textures = {}
    },
    deferred = {
        vertex_src = nil,
        fragment_src = nil,
        shader = nil,
        uniforms = {},
        textures = {}
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


Uniform = {}
Uniform.__index = Uniform

function Uniform:init(name, setter, t)
    local uniform = {}
    setmetatable(uniform,Uniform)
    uniform.name = name
    uniform.loc = -1
    uniform.value = nil
    uniform.setter = setter
    uniform.type = t or 2  -- float by default
    return uniform
end

function Uniform:getLoc()
    return self.loc
end

function Uniform:setLoc(loc)
    --[[
    if self.loc == loc then
        return
    end
    --]]
    self.loc = loc
end

function Uniform:getValue()
    return self.value
end

function Uniform:setValue(value)
    --[[
    if self.value == value then
        return
    end
    --]]
    if self.loc == -1 then
        return
    end
    if self.setter == glUniformArray then
        if (type(value) ~= "table") then
            Spring.Log("Map shader", "error",
                       "gl.UniformArray requires a table to set '" .. self.name .. "'")
            return
        end
        self.setter(self.loc, self.type, value)
    elseif self.setter == glUniformMatrix then
        if (type(value) ~= "table") or (#value ~= 16) then
            Spring.Log("Map shader", "error",
                       "gl.UniformMatrix requires 16 numbers to set '" .. self.name .. "'")
            return
        end
        self.setter(self.loc,
                    value[ 1], value[ 2], value[ 3], value[ 4],
                    value[ 5], value[ 6], value[ 7], value[ 8],
                    value[ 9], value[10], value[11], value[12],
                    value[13], value[14], value[15], value[16])
    else
        if (type(value) == "table") then
            if (#value == 1) then
                self.setter(self.loc, value[1])
            elseif (#value == 2) then
                self.setter(self.loc, value[1], value[2])
            elseif (#value == 3) then
                self.setter(self.loc, value[1], value[2], value[3])
            elseif (#value == 4) then
                self.setter(self.loc, value[1], value[2], value[3], value[4])
            else
                Spring.Log("Map shader", "error",
                           "gl.Uniform/gl.UniformInt requires a table of 1-4 numbers to set '" .. self.name .. "'")                
            end
        else
            self.setter(self.loc, value)
        end
    end
    self.value = value
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

function glGetMapShaderUniform(uniforms)
    local x, y, z, w
    values = {}
    for i, name in ipairs(uniforms) do
        if name == "mapSizePO2" then
            values[i] = {PWR2MAPX, PWR2MAPZ}
        elseif name == "mapSize" then
            values[i] = {MAPX, MAPZ}
        elseif name == "cameraPos" then
            values[i] = GetCameraPosition()
        elseif name == "lightDir" then
            x, y, z = glGetSun("pos")
            values[i] = {x, y, z, 0}
        elseif name == "groundAmbientColor" then
            x, y, z = glGetSun("ambient")
            values[i] = {x, y, z}
        elseif name == "groundDiffuseColor" then
            x, y, z = glGetSun("diffuse")
            values[i] = {x, y, z}
        elseif name == "groundSpecularColor" then
            x, y, z = glGetSun("specular")
            values[i] = {x, y, z}
        elseif name == "groundSpecularExponent" then
            values[i] = glGetSun("specularExponent")
        elseif name == "groundShadowDensity" then
            values[i] = glGetSun("shadowDensity")
        elseif name == "shadowMat" then
             m0,  m1,  m2,  m3,
             m4,  m5,  m6,  m7,
             m8,  m9, m10, m11,
            m12, m13, m14, m15 = glGetMatrixData("shadow")
            values[i] = { m0,  m1,  m2,  m3,
                          m4,  m5,  m6,  m7,
                          m8,  m9, m10, m11,
                         m12, m13, m14, m15}
        elseif name == "shadowParams" then
            x, y, z, w = glGetShadowMapParams()
            values[i] = {x, y, z, w}
        elseif name == "waterMinColor" then
            x, y, z = glGetWaterRendering("minColor")
            values[i] = {x, y, z}
        elseif name == "waterBaseColor" then
            x, y, z = glGetWaterRendering("baseColor")
            values[i] = {x, y, z}
        elseif name == "waterAbsorbColor" then
            x, y, z = glGetWaterRendering("absorb")
            values[i] = {x, y, z}
        elseif name == "splatTexScales" then
            x, y, z, w = glGetMapRendering("splatTexScales")
            values[i] = {x, y, z, w}
        elseif name == "splatTexMults" then
            x, y, z, w = glGetMapRendering("splatTexMults")
            values[i] = {x, y, z, w}
        elseif name == "infoTexIntensityMul" then
            local mode = GetMapDrawMode()
            if mode == "metal" then
                values[i] = 2.0
            else
                values[i] = {1.0}
            end
        elseif name == "normalTexGen" then
            if glGetMapShaderFlag("SMF_BLEND_NORMALS") then
                local texinfo = glTextureInfo("$ssmf_normals")
                x = (texinfo.xsize - 1) / SQUARE_SIZE
                z = (texinfo.ysize - 1) / SQUARE_SIZE
                values[i] = {1.0 / x, 1.0 / z}
            else
                -- Warning here??
                values[i] = {0, 0}
            end
        elseif name == "specularTexGen" then
            values[i] = {1.0 / MAPX, 1.0 / MAPZ}
        elseif name == "infoTexGen" then
            values[i] = {1.0 / PWR2MAPX, 1.0 / PWR2MAPX}
        elseif name == "mapHeights" then
            _, _, z, w = GetGroundExtremes()
            values[i] = {z, w}
        else
            Spring.Log("Map shader", "error",
                       "Unknown map default uniform '" .. name .. "'!")
        end
    end
    return values
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
    uniforms = {-- texSquare = Uniform:init("texSquare", glUniformInt),
                cameraPos = Uniform:init("cameraPos", glUniform),
                lightDir = Uniform:init("lightDir", glUniform),
                normalTexGen = Uniform:init("normalTexGen", glUniform),
                specularTexGen = Uniform:init("specularTexGen", glUniform),
                groundAmbientColor = Uniform:init("groundAmbientColor", glUniform),
                groundDiffuseColor = Uniform:init("groundDiffuseColor", glUniform),
                groundSpecularColor = Uniform:init("groundSpecularColor", glUniform),
                groundSpecularExponent = Uniform:init("groundSpecularExponent", glUniform),
                groundShadowDensity = Uniform:init("groundShadowDensity", glUniform),
                mapHeights = Uniform:init("mapHeights", glUniform),
    }
    textures = {-- diffuseTex = "$map_gbuffer_difftex",
                detailTex = {2, "$detail"},
                normalsTex = {5, "$ssmf_normals"},
    }
    if glGetMapShaderFlag("SMF_VOID_WATER") then
        definitions[#definitions + 1] = "#define SMF_VOID_WATER"
    end
    if glGetMapShaderFlag("SMF_VOID_GROUND") then
        definitions[#definitions + 1] = "#define SMF_VOID_GROUND"
    end
    if glGetMapShaderFlag("SMF_SPECULAR_LIGHTING") then
        definitions[#definitions + 1] = "#define SMF_SPECULAR_LIGHTING"
        textures["specularTex"] = {6, "$ssmf_specular"}
    end
    if glGetMapShaderFlag("SMF_DETAIL_TEXTURE_SPLATTING") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_TEXTURE_SPLATTING"
        if not glGetMapShaderFlag("SMF_DETAIL_NORMAL_TEXTURE_SPLATTING") then
            uniforms["splatTexMults"] = Uniform:init("splatTexMults", glUniform)
            uniforms["splatTexScales"] = Uniform:init("splatTexScales", glUniform)
            textures["splatDetailTex"] = {7, "$ssmf_splat_detail"}
            textures["splatDistrTex"] = {8, "$ssmf_splat_distr"}
        end
    end
    if glGetMapShaderFlag("SMF_DETAIL_NORMAL_TEXTURE_SPLATTING") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_NORMAL_TEXTURE_SPLATTING"
        uniforms["splatTexMults"] = Uniform:init("splatTexMults", glUniform)
        uniforms["splatTexScales"] = Uniform:init("splatTexScales", glUniform)
        textures["splatDistrTex"] = {8, "$ssmf_splat_distr"}
        textures["splatDetailNormalTex1"] = {15, "$ssmf_splat_normals:0"}
        textures["splatDetailNormalTex2"] = {16, "$ssmf_splat_normals:1"}
        textures["splatDetailNormalTex3"] = {17, "$ssmf_splat_normals:2"}
        textures["splatDetailNormalTex4"] = {18, "$ssmf_splat_normals:3"}
    end
    if glGetMapShaderFlag("SMF_DETAIL_NORMAL_DIFFUSE_ALPHA") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_NORMAL_DIFFUSE_ALPHA"
    end
    if glGetMapShaderFlag("SMF_WATER_ABSORPTION") then
        definitions[#definitions + 1] = "#define SMF_WATER_ABSORPTION"
        uniforms["waterMinColor"] = Uniform:init("waterMinColor", glUniform)
        uniforms["waterBaseColor"] = Uniform:init("waterBaseColor", glUniform)
        uniforms["waterAbsorbColor"] = Uniform:init("waterAbsorbColor", glUniform)
    end
    if glGetMapShaderFlag("SMF_SKY_REFLECTIONS") then
        definitions[#definitions + 1] = "#define SMF_SKY_REFLECTIONS"
        textures["skyReflectTex"] = {9, "$map_reflection"}
        textures["skyReflectModTex"] = {10, "$sky_reflection"}
    end
    if glGetMapShaderFlag("SMF_BLEND_NORMALS") then
        definitions[#definitions + 1] = "#define SMF_BLEND_NORMALS"
        textures["blendNormalsTex"] = {11, "$ssmf_normals"}
    end
    if glGetMapShaderFlag("SMF_LIGHT_EMISSION") then
        definitions[#definitions + 1] = "#define SMF_LIGHT_EMISSION"
        textures["lightEmissionTex"] = {12, "$ssmf_emission"}
    end
    if glGetMapShaderFlag("SMF_PARALLAX_MAPPING") then
        definitions[#definitions + 1] = "#define SMF_PARALLAX_MAPPING"
        textures["parallaxHeightTex"] = {13, "$ssmf_parallax"}
    end
    if glGetMapShaderFlag("HAVE_SHADOWS") then
        definitions[#definitions + 1] = "#define HAVE_SHADOWS"
        uniforms["shadowMat"] = Uniform:init("shadowMat", glUniformMatrix)
        uniforms["shadowParams"] = Uniform:init("shadowParams", glUniform)
        textures["shadowTex"] = {4, "$shadow"}
    end
    if glGetMapShaderFlag("HAVE_INFOTEX") then
        definitions[#definitions + 1] = "#define HAVE_INFOTEX"
        uniforms["infoTexIntensityMul"] = Uniform:init("infoTexIntensityMul", glUniform)
        uniforms["infoTexGen"] = Uniform:init("infoTexGen", glUniform)
        textures["infoTex"] = {14, "$info"}
    end
    -- definitions[#definitions + 1] = "#define BASE_DYNAMIC_MAP_LIGHT " .. tostring(glGetMapRendering("baseDynamicMapLight"))
    -- definitions[#definitions + 1] = "#define MAX_DYNAMIC_MAP_LIGHTS " .. tostring(glGetMapRendering("maxDynamicMapLight"))
    definitions = table.concat(definitions, "\n")
    fragment = definitions .. "\n" .. fragment

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
    local newshader = glCreateShader({
        vertex = vertex,
        fragment = fragment,
        uniformInt = {diffuseTex = 0,
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
        }
    })
    if not newshader then
        Spring.Log("Map shader", "error",
                   "Failed to create map shader!")
        Spring.Echo(glGetShaderLog())
        return false
    end

    -- Get the locations
    for name, uniform in pairs(uniforms) do
        local loc = glGetUniformLocation(newshader, name)
        if (loc == nil) or (loc == -1) then
            Spring.Log("Map shader", "warning",
                   "Uniform '" .. name .. "' is not present in the map shader")
        end
        uniform:setLoc(loc)
    end
    
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
    if not glGetMapRendering or not glGetMapShaderUniform then
        Spring.Log("Map shader", "error",
                   "Invalid engine version!")
        widgetHandler:RemoveWidget()
        return
    end

    local success
    success = CompileShader()
    success = CompileShader(true) and success
    if not success then
        widgetHandler:RemoveWidget()
        return
    end

    SetMapShader(CustomMapShaders.forward.shader,
                 CustomMapShaders.deferred.shader)
end

function widget:Shutdown()
    SetMapShader(0, 0)
end

function setDefaultUniformsAndTextures(uniforms, textures)
    local names = {}
    for name, _ in pairs(uniforms) do
        names[#names + 1] = name
    end
    local values = glGetMapShaderUniform(names)
    for i,name in ipairs(names) do
        if values[i] ~= nil then
            uniforms[name]:setValue(values[i])
        end
    end

    for name, texture in pairs(textures) do
        glTexture(texture[1], texture[2])
    end
end

function unsetDefaultTextures(uniforms, textures)
    for name, _ in pairs(textures) do
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

function widget:DrawGroundPreForward()
    setDefaultUniformsAndTextures(CustomMapShaders.forward.uniforms,
                                  CustomMapShaders.forward.textures)
end

function widget:DrawGroundPreDeferred()
    setDefaultUniformsAndTextures(CustomMapShaders.deferred.uniforms,
                                  CustomMapShaders.deferred.textures)
end
