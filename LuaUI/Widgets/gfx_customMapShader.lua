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

local glCreateShader = gl.CreateShader
local glGetShaderLog = gl.GetShaderLog
local glGetUniformLocation = gl.GetUniformLocation
local glUseShader = gl.UseShader
local glGetMatrixData = gl.GetMatrixData
local glUniform = gl.Uniform
local glUniformMatrix = gl.UniformMatrix
local glGetSun = gl.GetSun
local glGetAtmosphere = gl.GetAtmosphere
local glGetMapRendering = gl.GetMapRendering
local SetMapShader = Spring.SetMapShader
local GetCameraPosition = Spring.GetCameraPosition

local shader
local cameraPosID, lightDirID, fogParamsID, clipPlaneID, viewMatID, viewMatInvID
local viewProjMatID

function widget:Initialize()
    if not Script.IsEngineMinVersion or not Script.IsEngineMinVersion(104,0,1) then
        Spring.Log("Map shader", "error",
                   "spring >= 104.0.1 is required")
        widgetHandler:RemoveWidget()
        return        
    end

    shader = glCreateShader({
        vertex = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL4.X\\MapShaderVert.glsl", VFS.ZIP),
        fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL4.X\\MapShaderFrag.glsl", VFS.ZIP),
        uniformInt = {},
    })
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
    local x, y, z

    glUseShader(shader)

    if not cameraPosID then
        cameraPosID = glGetUniformLocation(shader, "cameraPos")
        lightDirID = glGetUniformLocation(shader, "lightDir")
        fogParamsID = glGetUniformLocation(shader, "fogParams")
        clipPlaneID = glGetUniformLocation(shader, "clipPlane")
        viewMatID = glGetUniformLocation(shader, "viewMat")
        viewMatInvID = glGetUniformLocation(shader, "viewMatInv")
        viewProjMatID = glGetUniformLocation(shader, "viewProjMat")
    end

    x, y, z = GetCameraPosition()
    glUniform(cameraPosID, x, y, z)
    x, y, z = glGetSun()
    glUniform(lightDirID, x, y, z, 0.0)
    glUniform(fogParamsID, glGetAtmosphere("fogStart"),
                           glGetAtmosphere("fogEnd"),
                           GetViewRange())
    glUniform(clipPlaneID, 0.0, 0.0, 0.0, 0.0)
    glUniformMatrix(viewMatID, "view")
    glUniformMatrix(viewMatInvID, "viewinverse")
    glUniformMatrix(viewProjMatID, "viewprojection")
    
    glUseShader(0)
end

function widget:DrawWorldReflection()
    local x, y, z, w

    glUseShader(shader)

    if not clipPlaneID then
        clipPlaneID = glGetUniformLocation(shader, "clipPlane")
    end

    glUniform(clipPlaneID, 0.0,  1.0, 0.0, 5.0)
    
    glUseShader(0)
end

function widget:DrawWorldRefraction()
    local x, y, z, w

    glUseShader(shader)

    if not clipPlaneID then
        clipPlaneID = glGetUniformLocation(shader, "clipPlane")
    end

    glUniform(clipPlaneID, 0.0, -1.0, 0.0, 5.0)
    
    
    glUseShader(0)
end
