--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name         = "Chili Map Editor",
		desc         = "v1.0 Chili Map Editor.",
		author       = "Jose Luis Cercos-Pita",
		date         = "2017-08-23",
		license      = "GNU GPL, v2 or later",
		layer        = 50,
		experimental = true,
		enabled      = false,
	}
end

local window_editor
local winTitle
local minimizedButton, minimizedButtonImage
local moveButton, moveButtonImage

tools_win = include("LuaUI/Widgets/map_editor/tools.lua")
local active_win = tools_win

local collapsed = false
local function SwapCollapsed()
	if collapsed then
		minimizedButtonImage.file = 'LuaUI/Images/arrowhead.png'
		active_win.show()
		minimizedButtonImage:Invalidate()
	else
		minimizedButtonImage.file = 'LuaUI/Images/arrowhead_flipped.png'
		active_win.hide()
		minimizedButtonImage:Invalidate()
	end
	collapsed = not collapsed
end

local draggingPos = nil
local function StartDragging(self, x, y)
	draggingPos = {x, y}
	return true
end
local function Drag(self, x, y)
	if not draggingPos then
		return false
	end
	window_editor:SetPos(window_editor.x + x - draggingPos[1],
	                     window_editor.y + y - draggingPos[2])
	return true
end
local function StopDragging(self, x, y)
	draggingPos = nil
	return true
end


function widget:Update(s)
end


function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
    if not Spring.IsCheatingEnabled() then
        Spring.Echo("Map editor require cheats enabled")
		widgetHandler:RemoveWidget()
		return
    end

	local wh = widgetHandler
	screen0 = WG.Chili.Screen0
	local win_button_inputsize = 25

	window_editor = WG.Chili.Window:New{
		parent = screen0,
		margin = { 0, 0, 0, 0 },
		padding = { 0, 0, 0, 0 },
		dockable = true,
		name = "MapEditorTools",
		x = "40%",
		y = "40%",
		right  = "40%",
		height = 32,
		draggable = false,
		resizable = false,
		minimizable = false,
		parentWidgetName = widget:GetInfo().name,
	}

	winTitle = WG.Chili.Label:New{
		parent=window_editor,
		caption = "Map Editor",
		x = 6,
		y = 6,
		rigth = 3 + 2 * win_button_inputsize,
		align = "center",
		fontsize = 14,
		padding = { 2, 2, 2, 2 },
		fontShadow=false,
		autoHeight=true,
		font = {
			-- outlineWidth = 3,
			-- outlineWeight = 10,
			-- outline = true,
			color = {1,1,1,1},
		}
	}

	minimizedButtonImage = WG.Chili.Image:New {
		width = win_button_inputsize - 2,
		height = win_button_inputsize - 2,
		keepAspect = true,
		--color = {0.7,0.7,0.7,0.4},
		file = 'LuaUI/Images/arrowhead.png',
	}
	minimizedButton = WG.Chili.Button:New{
		parent=window_editor,
		right=3,
		y=3,
		width = win_button_inputsize,
		height = win_button_inputsize,
		padding = { 1,1,1,1 },
		backgroundColor = {1,1,1,1},
		caption = '',
		tooltip = 'Collapse/expand the tools widget.',
		OnClick = {SwapCollapsed},
		children={minimizedButtonImage},
	}

	moveButtonImage = WG.Chili.Image:New {
		width = win_button_inputsize - 2,
		height = win_button_inputsize - 2,
		keepAspect = true,
		--color = {0.7,0.7,0.7,0.4},
		file = 'LuaUI/Images/move.png',
	}
	moveButton = WG.Chili.Button:New{
		parent=window_editor,
		right=3 + win_button_inputsize,
		y=3,
		width = win_button_inputsize,
		height = win_button_inputsize,
		padding = { 1,1,1,1 },
		backgroundColor = {1,1,1,1},
		caption = '',
		tooltip = 'Move the chat widget',
		OnMouseDown = {StartDragging},
		OnMouseMove = {Drag},
		OnMouseUp = {StopDragging},
		children={ moveButtonImage },
	}
    
	tools_win.init(window_editor)
	tools_win.show()
end

-----------------------------------------------------------------------

function widget:Shutdown()
	if (window_editor) then
		window_editor:Dispose()
	end
end
