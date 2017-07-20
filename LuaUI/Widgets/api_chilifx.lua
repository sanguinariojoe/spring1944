function widget:GetInfo()
return {
    name      = "ChiliFX",
    desc      = "Chili Effects library",
    author    = "gajop",
    date      = "in the future",
    license   = "GPL-v2",
    layer     = -999,
    enabled   = true,
    api       = true,
    hidden    = true,
}
end

LCS = loadstring(VFS.LoadFile("LuaUI/Widgets/lcs/LCS.lua"))
LCS = LCS()

CHILILFX_DIR = "LuaUI/Widgets/chilifx/"

function widget:Initialize()
    if not WG.Chili then
        Spring.Log("ChiliFX", LOG.ERROR, "Missing chiliui.")
        widgetHandler:RemoveWidget(widget)
        return
    end

    ChiliFX = VFS.Include(CHILILFX_DIR .. "core.lua", nil)

    WG.ChiliFX = ChiliFX()
end

function widget:Shutdown()
    WG.ChiliFX = nil
end
