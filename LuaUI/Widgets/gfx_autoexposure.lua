function widget:GetInfo()
    return {
        name      = "Automatic exposure adjustment",
        version   = 1.0,
        desc      = "Automatic exposure adjustment",
        author    = "Sanguinario_Joe",
        date      = "Sep. 2018",
        license   = "GPL",
        layer     = math.huge - 1,
        enabled   = false
    }
end

-----------------------------------------------------------------
-- Engine Functions
-----------------------------------------------------------------

local glCopyToTexture        = gl.CopyToTexture
local glCreateShader         = gl.CreateShader
local glCreateTexture        = gl.CreateTexture
local glDeleteShader         = gl.DeleteShader
local glDeleteTexture        = gl.DeleteTexture
local glGetShaderLog         = gl.GetShaderLog
local glTexture              = gl.Texture
local glTexRect              = gl.TexRect
local glRenderToTexture      = gl.RenderToTexture
local glUseShader            = gl.UseShader
local glGetUniformLocation   = gl.GetUniformLocation
local glUniform              = gl.Uniform
local GL_COLOR_BUFFER_BIT    = GL.COLOR_BUFFER_BIT
local GL_NEAREST             = GL.NEAREST

local glTexCoord = gl.TexCoord
local glVertex = gl.Vertex
local glColor = gl.Color
local glRect = gl.Rect
local glBeginEnd = gl.BeginEnd
local GL_QUADS = GL.QUADS
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text
local glCallList = gl.CallList
local glCreateList = gl.CreateList
local glDeleteList = gl.DeleteList

-----------------------------------------------------------------


-----------------------------------------------------------------
-- Global Vars
-----------------------------------------------------------------

local vsx = nil    -- current viewport width
local vsy = nil    -- current viewport height
local colorTex = nil
local exposureTex, exposureTex_prev = nil, nil
local initialized = false

local initShader, copyShader = nil, nil
local weightShader, downsampleShader, exposureShader, applyShader = nil, nil, nil, nil
local weightScaleLoc, downsampleSizelLoc, exposureSpeedLoc = nil, nil, nil
local samples = {}
local sizes = {}

function log2(n)
    return math.log(n) / math.log(2)
end

function prevPowerOf2(n)
    pos = math.floor(log2(n))
    return math.pow(2, pos)
end

-----------------------------------------------------------------

function destroy()
    destroyTextures()
    destroyShaders()
    initialized = false
end

function destroyTextures()
    if glDeleteTexture then
        glDeleteTexture(colorTex or "")
        glDeleteTexture(exposureTex or "")
        glDeleteTexture(exposureTex_prev or "")
        for _, tex in ipairs(samples) do
            glDeleteTexture(tex or "")
        end
    end
    colorTex = nil
    exposureTex = nil
    exposureTex_prev = nil
    samples = {}
    sizes = {}
end

function destroyShaders()
    if glDeleteShader then
        if initShader then
            glDeleteShader(initShader)
        end
        if copyShader then
            glDeleteShader(copyShader)
        end
        if weightShader then
            glDeleteShader(weightShader)
        end
        if downsampleShader then
            glDeleteShader(downsampleShader)
        end
        if exposureShader then
            glDeleteShader(exposureShader)
        end
        if applyShader then
            glDeleteShader(applyShader)
        end
    end
    initShader = nil
    copyShader = nil
    weightShader = nil
    downsampleShader = nil
    exposureShader = nil
    applyShader = nil
end

function widget:ViewResize(x, y)
    vsx, vsy = gl.GetViewSizes()

    destroyTextures()

    -- Input scene texture
    colorTex = gl.CreateTexture(vsx, vsy, {
        border = false,
        min_filter = GL.NEAREST,
        mag_filter = GL.NEAREST,
    })
    if not colorTex then
        Spring.Log("Auto-exposure", "error",
                   "Failed to create RTT texture")
        destroy()
        widgetHandler:RemoveWidget()
        return
    end

    -- Compute the first exposure sample texture size, as the minimum square
    -- with a power of 2 size, which can be fitted in the image
    s = prevPowerOf2(math.min(vsx, vsy))
    -- Now create the set of downsampled textures
    i = 1
    while s >= 1 do
        samples[i] = glCreateTexture(s, s, {
            fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
            wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
        })
        sizes[i] = s
        if not samples[i] then
            Spring.Log("Auto-exposure", "error",
                       "Failed to create " .. tostring(s) .. "x" .. tostring(s) " brighness sample")
            destroy()
            widgetHandler:RemoveWidget()
            return
        end
        s = s / 2
        i = i + 1
    end
    -- Create a last texture to save the exposure for dynamic evolution
    exposureTex = glCreateTexture(1, 1, {
        fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
    })
    exposureTex_prev = glCreateTexture(1, 1, {
        fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
    })
    if not exposureTex or not exposureTex_prev then
        Spring.Log("Auto-exposure", "error",
                    "Failed to create exposure storage textures")
        destroy()
        widgetHandler:RemoveWidget()
        return
    end
end

function widget:Initialize()
    if (glCreateShader == nil) then
        Spring.Log("Auto-exposure", "error",
                   "removing widget, no shader support")
        widgetHandler:RemoveWidget()
        return
    end

    -- Exposure initialization
    -- =======================
    initShader = initShader or glCreateShader({
        fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\AutoexposureInitFrag.glsl", VFS.ZIP),
    })
    if not initShader then
        Spring.Log("Auto-exposure", "error",
                   "Failed to create exposure texture initialization shader!")
        Spring.Echo(gl.GetShaderLog())
        destroy()
        widgetHandler:RemoveWidget()
        return
    end

    -- Exposure backup
    -- ===============
    copyShader = copyShader or glCreateShader({
        fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\AutoexposureCopyFrag.glsl", VFS.ZIP),
        uniformInt = {tex = 0},
    })
    if not copyShader then
        Spring.Log("Auto-exposure", "error",
                   "Failed to create exposure texture backup shader!")
        Spring.Echo(gl.GetShaderLog())
        destroy()
        widgetHandler:RemoveWidget()
        return
    end

    -- Weighted brightness
    -- ===================
    weightShader = weightShader or glCreateShader({
        fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\AutoexposureWeightsFrag.glsl", VFS.ZIP),
        uniformInt = {scene = 0,
                      weights = 1},
    })
    if not weightShader then
        Spring.Log("Auto-exposure", "error",
                   "Failed to create weighted brighness shader!")
        Spring.Echo(gl.GetShaderLog())
        destroy()
        widgetHandler:RemoveWidget()
        return
    end

    weightScaleLoc = gl.GetUniformLocation(weightShader, "scale")

    -- Brighness downsampling
    -- ======================
    downsampleShader = downsampleShader or glCreateShader({
        fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\AutoexposureDownSampleFrag.glsl", VFS.ZIP),
        uniformInt = {sample = 0},
    })
    if not downsampleShader then
        Spring.Log("Auto-exposure", "error",
                   "Failed to create downsampling shader!")
        Spring.Echo(gl.GetShaderLog())
        destroy()
        widgetHandler:RemoveWidget()
        return
    end

    downsampleSizelLoc = gl.GetUniformLocation(downsampleShader, "sizeinv")    

    -- Dynamic exposure computation
    -- ============================
    exposureShader = exposureShader or glCreateShader({
        fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\AutoexposureComputeFrag.glsl", VFS.ZIP),
        uniformInt = {brighness = 0,
                      prevExposure = 1},
    })
    if not exposureShader then
        Spring.Log("Auto-exposure", "error",
                   "Failed to create exposure computation shader!")
        Spring.Echo(gl.GetShaderLog())
        destroy()
        widgetHandler:RemoveWidget()
        return
    end

    exposureSpeedLoc = gl.GetUniformLocation(exposureShader, "changeRate")

    -- Auto exposure application
    -- =========================
    applyShader = applyShader or glCreateShader({
        fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\AutoexposureApplyFrag.glsl", VFS.ZIP),
        uniformInt = {scene = 0,
                      exposure = 1},
    })
    if not applyShader then
        Spring.Log("Auto-exposure", "error",
                   "Failed to create exposure application shader!")
        Spring.Echo(gl.GetShaderLog())
        destroy()
        widgetHandler:RemoveWidget()
        return
    end

    -- Generate the textures
    -- =====================
    widget:ViewResize()
end

function widget:Shutdown()
    destroy()
end

function widget:DrawScreenEffects()
    -- Get the color rendered image
    glCopyToTexture(colorTex, 0, 0, 0, 0, vsx, vsy)

    if not initialized then
        initialized = true
        glUseShader(initShader)
            glRenderToTexture(exposureTex_prev, glTexRect, -1, 1, 1, -1)
        glUseShader(0)        
    end
    
    -- Weighted brighness
    glUseShader(weightShader)
        glUniform(weightScaleLoc, sizes[1] / vsx, sizes[1] / vsy)
        glTexture(0, colorTex)
        glTexture(1, "LuaUI\\Widgets\\Shaders\\CenterWeighted.png")

        glRenderToTexture(samples[1], glTexRect, -1, 1, 1, -1)
        -- glTexRect(0, 0, sizes[1], sizes[1], false, true)

        glTexture(1, false)
        glTexture(0, false)
    glUseShader(0)

    -- Downsample
    for i = 2, #samples do
        glUseShader(downsampleShader)
            glUniform(downsampleSizelLoc, 1.0 / sizes[i - 1])
            glTexture(0, samples[i - 1])

            glRenderToTexture(samples[i], glTexRect, -1, 1, 1, -1)
            -- glTexRect(0, 0, sizes[i], sizes[i], false, true)

            glTexture(0, false)
        glUseShader(0)
    end

    -- Compute the new value of exposure
    glUseShader(exposureShader)
        glUniform(exposureSpeedLoc, 0.1)
        glTexture(0, samples[#samples])
        glTexture(1, exposureTex_prev)

        glRenderToTexture(exposureTex, glTexRect, -1, 1, 1, -1)
        -- glTexRect(0, 0, 100, 100, false, true)

        glTexture(1, false)
        glTexture(0, false)
    glUseShader(0)
    
    -- Apply autoexposure
    glUseShader(applyShader)
        glTexture(0, colorTex)
        glTexture(1, exposureTex)

        glTexRect(0, 0, vsx, vsy, false, true)

        glTexture(1, false)
        glTexture(0, false)
    glUseShader(0)

    -- Save exposure for the next frame
    glUseShader(copyShader)
        glTexture(0, exposureTex_prev)
        glRenderToTexture(exposureTex, glTexRect, -1, 1, 1, -1)
    glUseShader(0)
end
