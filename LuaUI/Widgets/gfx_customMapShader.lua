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

local srcs = {vertex=nil, fragment=nil}
local srcsDeferred = {vertex=nil, fragment=nil}
local shader, shaderDeferred
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


local function CompileShader(deferred, forced)
    forced = forced or false

    -- Original shaders
    local vertex = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\MapShaderVert.glsl", VFS.ZIP)
    local fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\MapShaderFrag.glsl", VFS.ZIP)
    -- Shader definitions
    local definitions = {
        "#version 130",
        "#define NOSPRING",
        -- "#define HAVE_INFOTEX",  -- We define it, and modify infoTexIntensityMul accordingly
    }
    if deferred then
        definitions[#definitions + 1] = "#define DEFERRED_MODE"
    end
    if glGetMapRendering and glGetMapRendering("voidWater") then
        definitions[#definitions + 1] = "#define SMF_VOID_WATER"
    end
    if glGetMapRendering and glGetMapRendering("voidGround") then
        definitions[#definitions + 1] = "#define SMF_VOID_GROUND"
    end
    if glGetMapRendering and glGetMapRendering("specularLighting") then
        definitions[#definitions + 1] = "#define SMF_SPECULAR_LIGHTING"
    end
    if glGetMapRendering and glGetMapRendering("splatDetailTexture") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_TEXTURE_SPLATTING"
    end
    if glGetMapRendering and glGetMapRendering("splatDetailNormalTexture") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_NORMAL_TEXTURE_SPLATTING"
    end
    if glGetMapRendering and glGetMapRendering("splatDetailNormalDiffuseAlpha") then
        definitions[#definitions + 1] = "#define SMF_DETAIL_NORMAL_DIFFUSE_ALPHA"
    end
    if glGetMapRendering and glGetMapRendering("waterAbsortion") then
        definitions[#definitions + 1] = "#define SMF_WATER_ABSORPTION"
    end
    if glGetMapRendering and glGetMapRendering("skyReflection") then
        definitions[#definitions + 1] = "#define SMF_SKY_REFLECTIONS"
    end
    if glGetMapRendering and glGetMapRendering("blendNormals") then
        definitions[#definitions + 1] = "#define SMF_BLEND_NORMALS"
    end
    if glGetMapRendering and glGetMapRendering("lightEmission") then
        definitions[#definitions + 1] = "#define SMF_LIGHT_EMISSION"
    end
    if glGetMapRendering and glGetMapRendering("parallaxMapping") then
        definitions[#definitions + 1] = "#define SMF_PARALLAX_MAPPING"
    end
    -- if glGetMapRendering then
    --     definitions[#definitions + 1] = "#define BASE_DYNAMIC_MAP_LIGHT " .. tostring(glGetMapRendering("baseDynamicMapLight"))
    -- end
    -- if glGetMapRendering then
    --     definitions[#definitions + 1] = "#define MAX_DYNAMIC_MAP_LIGHTS " .. tostring(glGetMapRendering("maxDynamicMapLight"))
    -- end
    if HaveShadows() then
        definitions[#definitions + 1] = "#define HAVE_SHADOWS"
    end
    definitions = table.concat(definitions, "\n")
    fragment = definitions .. "\n" .. fragment

    local src
    if deferred then
        src = srcsDeferred
    else
        src = srcs
    end
    if (not forced) and (src.vertex == vertex) and (src.fragment == fragment) then
        return shader
    end
    src.vertex = vertex
    src.fragment = fragment
    if deferred then
        srcsDeferred = src
    else
        srcs = src
    end

    Spring.Echo("--- Map Vertex shader ---------------------------------------")
    Spring.Echo(vertex)
    Spring.Echo("--------------------------------------- Map Vertex shader ---")
    Spring.Echo("--- Map Fragment shader -------------------------------------")
    Spring.Echo(fragment)
    Spring.Echo("------------------------------------- Map Fragment shader ---")

    -- Create the shader
    local shader = glCreateShader({
        vertex = vertex,
        fragment = fragment,
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
    shaderDeferred = CompileShader(true)
    if not shaderDeferred then
        Spring.Log("Map shader", "error",
                   "Failed to create map shader (Deferred mode)!")
        Spring.Echo(gl.GetShaderLog())
        widgetHandler:RemoveWidget()
        return
    end

    SetMapShader(shader, shaderDeferred, true)
end

function widget:Shutdown()
    SetMapShader(0, 0)
end

function widget:DrawWorld()
    local newshader = CompileShader()
    if not newshader then
        Spring.Log("Map shader", "error",
                   "Failed to create map shader!")
        Spring.Echo(gl.GetShaderLog())
        return
    end
    shader = newshader
    local newshader = CompileShader()
    if not newshader then
        Spring.Log("Map shader", "error",
                   "Failed to create map shader (Deferred mode)!")
        Spring.Echo(gl.GetShaderLog())
        return
    end
    shaderDeferred = newshader
    SetMapShader(shader, shaderDeferred, true)    
end
