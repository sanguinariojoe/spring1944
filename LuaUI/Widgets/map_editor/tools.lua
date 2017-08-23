--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local container

subwidget = {
	name = "tools",
	main_window = nil,
	height = 128 + 3,
	shown = false,
}

function subwidget.init(root)
	subwidget.main_window = root

	container = WG.Chili.Control:New{
		x=3,
		y=32,
		right=3,
		bottom=3,
		resizable = false,
		draggable = false,
		padding = customPadding or {0, 0, 0, 0},
	}

	local heightmap = WG.Chili.Button:New{
		parent = container,
		caption = "Heightmap",
		x = 0,
		y = 1,
		right = 0,
		height = 30,
		padding = { 1,1,1,1 },
		tooltip = 'Heightmap tools',
		OnClick = {},
	}
	local diffusemap = WG.Chili.Button:New{
		parent = container,
		caption = "Ground texture",
		x = 0,
		y = 33,
		right = 0,
		height = 30,
		padding = { 1,1,1,1 },
		tooltip = 'Ground diffuse texture tools',
		OnClick = {},
	}
	local features = WG.Chili.Button:New{
		parent = container,
		caption = "Place features",
		x = 0,
		y = 65,
		right = 0,
		height = 30,
		padding = { 1,1,1,1 },
		tooltip = 'Add features',
		OnClick = {},
	}
end

function subwidget.show()
	if subwidget.shown then
		return
	end
	subwidget.shown = true
	subwidget.main_window:SetPos(subwidget.main_window.x,
		                         subwidget.main_window.y,
		                         subwidget.main_window.width,
								 subwidget.height)
	subwidget.main_window:AddChild(container)
end

function subwidget.hide()
	if not subwidget.shown then
		return
	end
	subwidget.shown = false
	subwidget.main_window:SetPos(subwidget.main_window.x,
		                         subwidget.main_window.y,
		                         subwidget.main_window.width,
								 32)
	subwidget.main_window:RemoveChild(container)
end

return subwidget