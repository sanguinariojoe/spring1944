--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "GameOver Window",
    desc      = "Alternative game over window for the campaign",
    author    = "Jose Luis Cercos-Pita",
    date      = "2017-07-19",
    license   = "GNU GPL, v2 or later",
    layer     = 100,
    enabled   = true,
  }
end

local glTexCoord = gl.TexCoord
local glVertex = gl.Vertex
local glColor = gl.Color
local glRect = gl.Rect
local glTexture = gl.Texture
local glTexRect = gl.TexRect
local glDepthTest = gl.DepthTest
local glBeginEnd = gl.BeginEnd
local GL_QUADS = GL.QUADS
local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text
local glCallList = gl.CallList
local glCreateList = gl.CreateList
local glDeleteList = gl.DeleteList

local fadePeriod  = 3.0
local fadeTimer   = fadePeriod
local gameEnded   = false
local endMsg      = "Game Over"
local endMsgColor = {1, 1, 1}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--callins

local function FadeOut()
	gameEnded = true
	fadeTimer = fadePeriod
end

function widget:Initialize()
	-- Just if the non-default menu is used (like in the campaign)
	if not Spring.GetMenuName or Spring.GetMenuName() == "" then
		widgetHandler:RemoveWidget()
		return
	end

	Spring.SendCommands("endgraph 0")

	if Spring.IsGameOver() then
		endMsg = "Game aborted!"
		endMsgColor = {1, 0, 0}
		FadeOut()
	end
end

function widget:GameOver(winners)
	FadeOut()
end

function widget:Update(dt)
	if not gameEnded then
		return
	end
	fadeTimer = fadeTimer - dt
	if fadeTimer <= 0 then
		Spring.Reload("")                           -- Ask to unload the game
		-- Spring.SendCommands("quit","quitforce")  -- Quit to system
		return
	end
end

function widget:DrawScreen()
	if not gameEnded then
		return
	end

	local w, h = Spring.GetWindowGeometry()
	local alpha = 1.0 - fadeTimer / fadePeriod

	-- Positioning
	glPushMatrix()
	glTranslate(0, 0, 0)
	-- Draw
	glColor(0, 0, 0, alpha)
	glTexture(false)
	glTexRect(0, 0, w, h)
	local fontsize = 64
	glColor(endMsgColor[1], endMsgColor[2], endMsgColor[3], alpha)
	glText(endMsg, w / 2, h / 2, fontsize, 'cv')

	glPopMatrix()
end
