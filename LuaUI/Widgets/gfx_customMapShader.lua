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
local glGetMapRendering     = gl.GetMapRendering      -- >= 104.0
local glGetMapShaderUniform = gl.GetMapShaderUniform  -- >= 104.0.1
local glGetUniformLocation  = gl.GetUniformLocation
local glUniform             = gl.Uniform
local glUniformInt          = gl.UniformInt
local glUniformArray        = gl.UniformArray
local glUniformMatrix       = gl.UniformMatrix
local glTexture             = gl.Texture
local glUseShader           = gl.UseShader
local SetMapShader      = Spring.SetMapShader
local HaveShadows       = Spring.HaveShadows


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
                diffuseTex = Uniform:init("diffuseTex", glUniformInt),
                normalsTex = Uniform:init("normalsTex", glUniformInt),
                detailTex = Uniform:init("detailTex", glUniformInt),
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
                normalsTex = "$ssmf_normals",
                detailTex = "$detail",
    }
    if glGetMapRendering("voidWater") then
        definitions[#definitions + 1] = "#define SMF_VOID_WATER"
    end
    if glGetMapRendering("voidGround") then
        definitions[#definitions + 1] = "#define SMF_VOID_GROUND"
    end
    if glGetMapRendering("specularLighting") then
        definitions[#definitions + 1] = "#define SMF_SPECULAR_LIGHTING"
        uniforms["specularTex"] = Uniform:init("specularTex", glUniformInt)
        textures["specularTex"] = "$ssmf_specular"
    end
    if glGetMapRendering("splatDetailTexture") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_TEXTURE_SPLATTING"
        if not glGetMapRendering("splatDetailNormalTexture") then
            uniforms["splatDetailTex"] = Uniform:init("splatDetailTex", glUniformInt)
            uniforms["splatDistrTex"] = Uniform:init("splatDistrTex", glUniformInt)
            uniforms["splatTexMults"] = Uniform:init("splatTexMults", glUniform)
            uniforms["splatTexScales"] = Uniform:init("splatTexScales", glUniform)
            textures["splatDetailTex"] = "$ssmf_splat_detail"
            textures["splatDistrTex"] = "$ssmf_splat_distr"
        end
    end
    if glGetMapRendering("splatDetailNormalTexture") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_NORMAL_TEXTURE_SPLATTING"
        uniforms["splatDetailNormalTex1"] = Uniform:init("splatDetailNormalTex1", glUniformInt)
        uniforms["splatDetailNormalTex2"] = Uniform:init("splatDetailNormalTex2", glUniformInt)
        uniforms["splatDetailNormalTex3"] = Uniform:init("splatDetailNormalTex3", glUniformInt)
        uniforms["splatDetailNormalTex4"] = Uniform:init("splatDetailNormalTex4", glUniformInt)
        uniforms["splatDistrTex"] = Uniform:init("splatDistrTex", glUniformInt)
        uniforms["splatTexMults"] = Uniform:init("splatTexMults", glUniform)
        uniforms["splatTexScales"] = Uniform:init("splatTexScales", glUniform)
        textures["splatDetailNormalTex1"] = "$ssmf_splat_normals:0"
        textures["splatDetailNormalTex2"] = "$ssmf_splat_normals:1"
        textures["splatDetailNormalTex3"] = "$ssmf_splat_normals:2"
        textures["splatDetailNormalTex4"] = "$ssmf_splat_normals:3"
        textures["splatDistrTex"] = "$ssmf_splat_distr"
    end
    if glGetMapRendering("splatDetailNormalDiffuseAlpha") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_NORMAL_DIFFUSE_ALPHA"
    end
    if glGetMapRendering("waterAbsortion") then
        definitions[#definitions + 1] = "#define SMF_WATER_ABSORPTION"
        uniforms["waterMinColor"] = Uniform:init("waterMinColor", glUniform)
        uniforms["waterBaseColor"] = Uniform:init("waterBaseColor", glUniform)
        uniforms["waterAbsorbColor"] = Uniform:init("waterAbsorbColor", glUniform)
    end
    if glGetMapRendering("skyReflection") then
        definitions[#definitions + 1] = "#define SMF_SKY_REFLECTIONS"
        uniforms["skyReflectTex"] = Uniform:init("skyReflectTex", glUniformInt)
        uniforms["skyReflectModTex"] = Uniform:init("skyReflectModTex", glUniformInt)
        textures["skyReflectTex"] = "$map_reflection"
        textures["skyReflectModTex"] = "$sky_reflection"
    end
    if glGetMapRendering("blendNormals") then
        definitions[#definitions + 1] = "#define SMF_BLEND_NORMALS"
        uniforms["blendNormalsTex"] = Uniform:init("blendNormalsTex", glUniformInt)
        textures["blendNormalsTex"] = "$ssmf_normals"
    end
    if glGetMapRendering("lightEmission") then
        definitions[#definitions + 1] = "#define SMF_LIGHT_EMISSION"
        uniforms["lightEmissionTex"] = Uniform:init("lightEmissionTex", glUniformInt)
        textures["lightEmissionTex"] = "$ssmf_emission"
    end
    if glGetMapRendering("parallaxMapping") then
        definitions[#definitions + 1] = "#define SMF_PARALLAX_MAPPING"
        uniforms["parallaxHeightTex"] = Uniform:init("parallaxHeightTex", glUniformInt)
        textures["parallaxHeightTex"] = "$ssmf_parallax"
    end
    if glGetMapRendering("haveShadows") then
        definitions[#definitions + 1] = "#define HAVE_SHADOWS"
        uniforms["shadowTex"] = Uniform:init("shadowTex", glUniformInt)
        uniforms["shadowMat"] = Uniform:init("shadowMat", glUniformMatrix)
        uniforms["shadowParams"] = Uniform:init("shadowParams", glUniform)
        textures["shadowTex"] = "$shadow"
    end
    if glGetMapRendering("haveInfoTex") then
        definitions[#definitions + 1] = "#define HAVE_INFOTEX"
        uniforms["infoTex"] = Uniform:init("infoTex", glUniformInt)
        uniforms["infoTexIntensityMul"] = Uniform:init("infoTexIntensityMul", glUniform)
        uniforms["infoTexGen"] = Uniform:init("infoTexGen", glUniform)
        textures["infoTex"] = "$info"
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
        local index = uniforms[name]:getValue()
        if index then
            glTexture(index, texture)
        end
    end
end

function unsetDefaultTextures(uniforms, textures)
    for name, _ in pairs(textures) do
        local index = uniforms[name]:getValue()
        glTexture(index, false)
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
