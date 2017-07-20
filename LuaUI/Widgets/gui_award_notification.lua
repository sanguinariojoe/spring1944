--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Campaign award notifier",
    desc      = "A window to notify an award",
    author    = "Jose Luis Cercos-Pita",
    date      = "2017/7/20",
    license   = "GNU GPL, v2 or later",
    layer     = 0, 
    enabled   = true  --  loaded by default?
  }
end

local Chili
local ChiliFX
local Label
local Window
local EditBox
local TextBox
local Image
local Control
local mainWindow
local fadePeriod = 1
local showPeriod = 5
local showTimer = 0

function AwardNotification(key, img, description)
	_G["new_award_notification"] = {key=key,
	                                img=img,
	                                description=description}
end

function SetupWindow(key, img, description)
	-- Setup the notification window
	mainWindow.children = {}
	local imgWin = Image:New{
		--parent = screen0,
		name  = 'imgWin',
		x = 0,
		y = 0,
		width = 64,
		height = 64,
		keepAspect = true,
		file = "LuaMenu/configs/campaign/s44/awards/" .. img,
		parent = mainWindow,
		padding = {0, 0, 0, 0},
	}
	--[[
	local description = TextBox:New {
		x = 74,
		y = 0,
		right = 0,
		height = 64,
		text = key,
		parent = mainWindow,
		fontSize = 12,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}
	--]]
	local description = EditBox:New {
		x = 74,
		y = 0,
		right = 0,
		height = 64,
		text = description,
		align = "center",
		valign = "center",
		fontSize = 24,
		parent = mainWindow,
		editable = false,
		selectable = false,
		multiline = true,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}
	--]]
	-- Show the window (if not already shown)
	if not mainWindow.visible then
		ShowWindow()
	end
	showTimer = showPeriod + 2 * fadePeriod
end

function HideWindow()
	if not ChiliFX:IsEnabled() then
		mainWindow:Hide()
		return
	end
	ChiliFX:AddFadeEffect({
		obj = mainWindow,
		time = fadePeriod,
		endValue = 0,
		startValue = 1,
		after = function()
			mainWindow:Hide()
		end
	})
end

function ShowWindow()
	mainWindow:Show()
	if not ChiliFX:IsEnabled() then
		return
	end
	ChiliFX:AddFadeEffect({
		obj = mainWindow,
		time = fadePeriod,
		endValue = 1,
		startValue = 0,
	})
end

function widget:Initialize()
	_G["new_award_notification"] = nil
	-- Just if the non-default menu is used (like in the campaign)
	if not Spring.GetMenuName or Spring.GetMenuName() == "" then
		widgetHandler:RemoveWidget()
		return
	end

	if not WG.Chili or not WG.ChiliFX then
		Spring.Log("Campaign award notifier", LOG.ERROR, "Chili not loaded")
		widgetHandler:RemoveWidget()
		return
	end
	Chili = WG.Chili
	Label = Chili.Label
	Window = Chili.Window
	EditBox = Chili.EditBox
	TextBox = Chili.TextBox
	Image = Chili.Image
	Control = Chili.Control
	screen0 = Chili.Screen0

	ChiliFX = WG.ChiliFX
	ChiliFX:Enable()

	-- Create and hide the notification window
	mainWindow = Window:New{
		--parent = screen0,
		name  = 'awardNotification';
		x = "15%";
		y = "50%",
		width = "70%";
		height = 84;
		classname = "main_window_small",
		dockable = false;
		draggable = false,
		resizable = false,
		padding = {10, 10, 10, 10},
		parent = screen0,
	}
	mainWindow:Hide()

	-- Retgister a global function to control it
	widgetHandler:RegisterGlobal("AwardNotification", AwardNotification)
end


function widget:Update(dt)
	if _G["new_award_notification"] ~= nil then
		local data = _G["new_award_notification"]
		SetupWindow(data.key, data.img, data.description)
		_G["new_award_notification"] = nil
	end

	if not mainWindow.visible then
		return
	end

	showTimer = showTimer - dt
	if showTimer <= fadePeriod then
		HideWindow()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
