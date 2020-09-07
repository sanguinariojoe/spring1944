--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
    return {
        name         = "1944 Console",
        desc         = "Console for Spring 1944",
        author       = "Jose Luis Cercos-Pita",
        date         = "2020-08-28",
        license      = "GNU GPL, v2 or later",
        layer        = 50,
        experimental = false,
        enabled      = true,
    }
end

local myName, transmitMagic, voiceMagic, transmitLobbyMagic, MessageProcessor = include("chat_preprocess.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local IMAGE_DIRNAME = LUAUI_DIRNAME .. "Images/ComWin/"
local SOUNDS = {
    ally = "sounds/talk.wav",
    label = "sounds/talk.wav",
}
local MAX_STORED_MESSAGES = 100
local CHAT_COLOR = {1, 1, 0.6, 1}
local GLYPHS = {
    flag = '\204\134',
    muted = '\204\138',
    unmuted = '\204\139',
}
local SENDTO = 'all'  -- It may take 'all', 'allies' and 'spectators' values

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local chat_win, chat_stack, chat_scroll
local main_win, main_log, main_players
local main_sendto, main_msg, main_send, main_cancel
local playerName, allyTeamId
local muted = {}
local teamColors = {}
local allies = {}
local specs = {}
local sent_history = {}
local sent_history_index = 1

--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------

local function OnSwitchMute(self)
    local name = self.playername
    local glyph
    if muted[name] then
        muted[name] = nil
        glyph = GLYPHS["unmuted"]
    else
        muted[name] = true
        glyph = GLYPHS["muted"]
    end
    self:SetCaption(name .. " " .. glyph)
end

local function __playerButton(name, color)
    local glyph = GLYPHS["unmuted"]
    if muted[name] then
        glyph = GLYPHS["muted"]
    end
    return Chili.Button:New {
        x = 0,
        y = 0,
        right = 0,
        height = 32,
        caption = name .. " " .. glyph,
        OnClick = { OnSwitchMute, },
        parent = main_win,
        playername = name,
        font = {
            color = color,
        },
    }
end

local function setupPlayers(playerID)
    local stack
    if playerID then
        local name, active, spec, teamId, allyTeamId = Spring.GetPlayerInfo(playerID)
        --lobby: grey chat, spec: white chat, player: color chat
        teamColors[name] = (spec and {1,1,1,1}) or {Spring.GetTeamColor(teamId)}
        for _, stack in ipairs(main_players.children) do
            for j = 2,#stack.children do
                if stack.children[j].playername == name then
                    stack.children[j]:Dispose()
                end
            end
        end
        stack = main_players.children[2]
        specs[name] = nil
        allies[name] = nil
        if spec then
            stack = main_players.children[3]
            specs[name] = playerID
        elseif Spring.ArePlayersAllied(Spring.GetMyPlayerID(), playerID) then
            stack = main_players.children[1]
            allies[name] = playerID
        end
        stack:AddChild(__playerButton(name, teamColors[name]))
    else
        for _, stack in ipairs(main_players.children) do
            for j = 2,#stack.children do
                stack.children[j]:Dispose()
            end
        end
        local players = Spring.GetPlayerList()
        for i, id in ipairs(players) do
            local name, active, spec, teamId, allyTeamId = Spring.GetPlayerInfo(id)
            teamColors[name] = (spec and {1,1,1,1}) or {Spring.GetTeamColor(teamId)}
            stack = main_players.children[2]
            if spec then
                stack = main_players.children[3]
                specs[name] = id
            elseif Spring.ArePlayersAllied(Spring.GetMyPlayerID(), id) then
                stack = main_players.children[1]
                allies[name] = id
            end
            stack:AddChild(__playerButton(name, teamColors[name]))
        end
    end
end

local function PlaySound(id, condition)
    if condition ~= nil and not condition then
        return
    end
    local file = SOUNDS[id]
    if file then
        Spring.PlaySoundFile(file, 1, 'ui')
    end
end

local function MessageIsChatInfo(msg)
    return string.find(msg.argument,'Speed set to') or
           string.find(msg.argument,'following') or
           string.find(msg.argument,'Connection attempted') or
           string.find(msg.argument,'exited') or 
           string.find(msg.argument,'is no more') or 
           string.find(msg.argument,'paused the game') or
           string.find(msg.argument,'Sync error for') or
           string.find(msg.argument,'Cheating is') or
           string.find(msg.argument,'resigned') or
           string.find(msg.argument,'Buildings set') or
           (string.find(msg.argument,'left the game') and string.find(msg.argument,'Player'))
           -- S44 specific stuff: never hide air raid warnings
           or string.find(msg.argument,'aircraft spotted')
end

local function isChat(msg)
    return msg.msgtype ~= 'other' or MessageIsChatInfo(msg)
end

local function isPoint(msg)
    return msg.msgtype == "point" or msg.msgtype == "label"
end

local function __escape_lua_pattern(s)
    local matches =
    {
        ["^"] = "%^";
        ["$"] = "%$";
        ["("] = "%(";
        [")"] = "%)";
        ["%"] = "%%";
        ["."] = "%.";
        ["["] = "%[";
        ["]"] = "%]";
        ["*"] = "%*";
        ["+"] = "%+";
        ["-"] = "%-";
        ["?"] = "%?";
        ["\0"] = "%z";
    }

    return (s:gsub(".", matches))
end

local function __color2str(color)
    local txt = "\\255"
    for i = 1,3 do 
        txt = txt .. "\\" .. tostring(math.floor(color[i] * 255))
    end
    local func, err = loadstring( "return \"" .. txt .. "\"" )
    if (not func) then
        return ''
    end
    return func()
end

local function formatMessage(msg)
    if msg.playername then
        local out = msg.text
        local playerName = __escape_lua_pattern(msg.playername)
        out = out:gsub( '^<' .. playerName ..'> ', '' )
        out = out:gsub( '^%[' .. playerName ..'%] ', '' )
        msg.playername2 = playerName
        msg.textFormatted = __color2str(chat_win.font.color) .. out
        msg.source2 = __color2str(teamColors[msg.playername]) .. playerName
    else
        msg.textFormatted = msg.text
        msg.source2 = ''
    end
end

local function removeToMaxLines()
    while #chat_stack.children > MAX_STORED_MESSAGES do
        if chat_stack.children[1] then
            chat_stack.children[1]:Dispose()
        end
    end
end

local function AddControlToFadeTracker(control, fadeType)
    control.life = decayTime
    control.fadeType = fadeType or ''
    killTracker[control_id] = control
    control_id = control_id + 1
end

local function AddMessage(msg)
    if (not WG.Chili) then
        return
    end

    local messageText = msg.textFormatted
    if msg.source2 ~= '' then
        messageText = msg.source2 .. ": " .. messageText
    end

    local messageTextBox = WG.Chili.TextBox:New{
        width = '100%',
        align = "left",
        valign = "ascender",
        lineSpacing = 1,
        padding = { 2,2,2,2 },
        text = messageText,
        fontShadow=false,
        autoHeight=true,
        font = {
            outlineWidth  = 3,
            outlineWeight = 10,
            outline       = true,
        }
    }

    local control = messageTextBox
    if msg.point then
        messageTextBox:SetPos(30, nil, nil, nil)
        local flagButton = WG.Chili.Button:New{
            caption=GLYPHS.flag,
            x = 0;
            --y=0;
            width = 30,
            --height = 18,
            height = '100%',
            backgroundColor = {1,1,1,1},
            padding = {2,2,2,2},
            OnClick = {function(self, x, y, mouse)
                local alt,ctrl, meta,shift = Spring.GetModKeyState()
                if (shift or ctrl or meta or alt) or ( mouse ~= 1 ) then
                    return false
                end
                Spring.SetCameraTarget(msg.point.x, msg.point.y, msg.point.z, 1)
            end}
        }
        control = WG.Chili.Panel:New{
            --columns=2,
            width = '100%',
            orientation = "horizontal",
            padding = {0,0,0,0},
            margin = {0,0,0,0},
            --itemPadding = {5,5,5,5};
            --backgroundColor = {0,0,0,0.5};
            backgroundColor = {0,0,0,0};
            autosize = true,
            resizeItems = false,
            centerItems = false,
            children = {flagButton, messageTextBox},        
        }
    end

    chat_stack:AddChild(control, false)
    chat_stack:UpdateClientArea()
end

function AddConsoleMessage(msg)
    if not isChat(msg) then
        return
    end
    formatMessage(msg)
    if muted[msg.playername2] then
        return
    end
    AddMessage(msg)

    if (msg.msgtype == "player_to_allies") then
        PlaySound("ally")
    elseif msg.msgtype == "label" then
        PlaySound("label")
    end

    removeToMaxLines()
end

function ShowWin()
    -- Hide the default chat window
    chat_win:Hide()
    -- Transfer the chat stack to the main window
    chat_stack:SetParent(nil)
    if main_log == nil then
        -- Properly build the scroll panel for the chat now, so hereinafter we
        -- can safely transfer the chat_stack parenting between main_log and
        -- chat_stack scroll panels
        main_log = Chili.ScrollPanel:New{
            --margin = {5,5,5,5},
            padding = {1, 1, 1, 1},
            x = 0,
            y = 0,
            width = '70%',
            bottom = 37,
            verticalSmartScroll = true,
            ignoreMouseWheel = false,
            verticalScrollbar = true,
            horizontalScrollbar = false,
            parent = main_win,
            children = {chat_stack},
            BorderTileImage = IMAGE_DIRNAME .. "empty.png",
            BackgroundTileImage = IMAGE_DIRNAME .. "empty.png",
            TileImage = IMAGE_DIRNAME .. "empty.png",
        }
    end
    chat_stack:SetParent(main_log)
    main_sendto:Select(SENDTO)
    sent_history_index = #sent_history + 1
    main_msg:SetText("")
    Chili.Screen0:FocusControl(main_msg)

    -- Show the main window
    main_win:Show()
end

function HideWin()
    -- Hide the main window
    main_win:Hide()
    -- Transfer the chat stack to the default chat window
    chat_stack:SetParent(chat_scroll)
    -- Show the default chat window
    chat_win:Show()
end

function OnCancel()
    main_msg:SetText("")
    HideWin()
end

function OnSend()
    local msg = main_msg.text
    if msg == "" then
        OnCancel()
        return
    end

    sent_history[#sent_history + 1] = msg
    SENDTO = main_sendto.caption
    if SENDTO == 'all' then
        Spring.SendCommands("say " .. msg)
    elseif SENDTO == 'allies' then
        for name, id in pairs(allies) do
            Spring.SendCommands("WByNum " .. tostring(id) .. " " .. msg)
        end
    elseif SENDTO == 'spectators' then
        for name, id in pairs(specs) do
            Spring.SendCommands("WByNum " .. tostring(id) .. " " .. msg)
        end
    else
        Spring.Log("Chat", LOG.ERROR, "Unknown group '" .. SENDTO .. "'")
    end
    OnCancel()
end

function OnChat()
    if main_win.visible then
        OnSend()
    else
        ShowWin()
    end
end

function OnChatSwitchAlly()
    SENDTO = 'allies'
    main_sendto:Select(SENDTO)
end

function OnChatSwitchSpec()
    SENDTO = 'spectators'
    main_sendto:Select(SENDTO)
end

local function OnChatInputKey(self, key, mods, isRepeat, label, unicode, ...)
    local msg
    if Spring.GetKeyCode("up") == key then
        sent_history_index = sent_history_index - 1
        if sent_history_index < 0 then
            sent_history_index = 0
        end
        msg = sent_history[sent_history_index]
        if msg == nil then
            msg = ""
        end
    elseif Spring.GetKeyCode("down") == key then
        sent_history_index = sent_history_index + 1
        if sent_history_index > #sent_history + 1 then
            sent_history_index = #sent_history + 1
        end
        msg = sent_history[sent_history_index]
        if msg == nil then
            msg = ""
        end
    end

    if msg ~= nil then
        main_msg:SetText(msg)
    end
end

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------

function widget:Initialize()
    if (not WG.Chili) then
        widgetHandler:RemoveWidget()
        return
    end

    Chili = WG.Chili
    local viewSizeX, viewSizeY = Spring.GetViewGeometry()
    playerName, _, _, _, allyTeamId = Spring.GetPlayerInfo(Spring.GetMyPlayerID())

    -- Chat window (anchored at bottom-right of the screen)
    -------------------------------------------------------
    chat_win = Chili.Window:New{
        parent = Chili.Screen0,
        x = "40%",
        y = "80%",
        width = "60%",
        height = "20%",
        draggable = false,
        resizable = false,
        padding = {0, 0, 0, 0},
        TileImage = IMAGE_DIRNAME .. "empty.png",
    }

    chat_scroll = Chili.ScrollPanel:New{
        --margin = {5,5,5,5},
        padding = {1, 1, 1, 1},
        x = 0,
        y = 0,
        width = '100%',
        height = '100%',
        verticalSmartScroll = true,
        ignoreMouseWheel = true,
        verticalScrollbar = false,
        horizontalScrollbar = false,
        parent = chat_win,
        BorderTileImage = IMAGE_DIRNAME .. "empty.png",
        BackgroundTileImage = IMAGE_DIRNAME .. "empty.png",
        TileImage = IMAGE_DIRNAME .. "empty.png",
    }

    chat_stack = Chili.StackPanel:New{
        margin = { 0, 0, 0, 0 },
        padding = { 0, 0, 0, 0 },
        x = 0,
        y = 0,
        right = 5,
        height = 10,
        resizeItems = false,
        itemPadding  = { 1, 1, 1, 1 },
        itemMargin  = {0, 0, 0, 0},
        autosize = true,
        preserveChildrenOrder = true,
        parent = chat_scroll,  
    }

    -- This spacer grants chats is always scrolled down
    WG.Chili.Panel:New{
        width = '100%',
        height = 500,
        backgroundColor = {0,0,0,0},
        parent = chat_stack,
    }

    Spring.SendCommands({"console 0"})

    -- Players window:
    --  * Send new chat messages
    --  * Visit the whole chat log
    --  * Mute/unmute players
    ------------------------------
    main_win = Chili.Window:New{
        parent = Chili.Screen0,
        x = "20%",
        y = "20%",
        width = "60%",
        height = "60%",
        draggable = false,
        resizable = false,
    }
    -- We can not create the scroll panel for the chat stack yet.
    -- For some reason, chili is not able to conveniently set the chat_stack
    -- parent if we do that now.
    -- see ShowWin()
    main_log = nil

    main_sendto = Chili.ComboBox:New{
        x = "0%",
        bottom = "0%",
        width = 128,
        height = 32,
        items = {"all", "allies", "spectators"},
        parent = main_win,
    }

    main_msg = Chili.EditBox:New {
        x = 133,
        bottom = '0%',
        width = main_win.width - 133 * 3 - 20,
        height = 32,
        text = "",
        parent = main_win,
        OnKeyPress = { OnChatInputKey },
    }

    main_send = Chili.Button:New {
        right = 133,
        bottom = '0%',
        width = 128,
        height = 32,
        caption = "Send",
        OnClick = { OnSend, },
        parent = main_win,
    }

    main_cancel = Chili.Button:New {
        right = 0,
        bottom = '0%',
        width = 128,
        height = 32,
        caption = "Cancel",
        OnClick = { OnCancel, },
        parent = main_win,
    }

    local main_players_scroll = Chili.ScrollPanel:New{
        padding = {1, 1, 1, 1},
        right = "0%",
        y = 0,
        width = '30%',
        bottom = 37,
        verticalSmartScroll = true,
        ignoreMouseWheel = false,
        verticalScrollbar = true,
        horizontalScrollbar = true,
        parent = main_win,
    }

    main_players = Chili.StackPanel:New{
        margin = { 0, 0, 0, 0 },
        padding = { 0, 0, 0, 0 },
        x = 0,
        y = 0,
        right = 5,
        height = 10,
        resizeItems = false,
        itemPadding  = { 1, 1, 1, 1 },
        itemMargin  = {0, 0, 0, 0},
        autosize = true,
        preserveChildrenOrder = true,
        parent = main_players_scroll,
    }

    local allies_stack = Chili.StackPanel:New{
        margin = { 0, 0, 0, 0 },
        padding = { 0, 0, 0, 0 },
        x = 0,
        y = 0,
        right = 5,
        height = 10,
        resizeItems = false,
        itemPadding  = { 1, 1, 1, 1 },
        itemMargin  = {0, 0, 0, 0},
        autosize = true,
        preserveChildrenOrder = true,
        parent = main_players,
        children = {Chili.Label:New{
            x = 0,
            y = 0,
            width = "100%",
            height = "100%",
            caption = "Allies",
        }},
    }
    local enemies_stack = Chili.StackPanel:New{
        margin = { 0, 0, 0, 0 },
        padding = { 0, 0, 0, 0 },
        x = 0,
        y = 0,
        right = 5,
        height = 10,
        resizeItems = false,
        itemPadding  = { 1, 1, 1, 1 },
        itemMargin  = {0, 0, 0, 0},
        autosize = true,
        preserveChildrenOrder = true,
        parent = main_players,
        children = {Chili.Label:New{
            x = 0,
            y = 0,
            width = "100%",
            height = "100%",
            caption = "Enemies",
        }},
    }
    local specs_stack = Chili.StackPanel:New{
        margin = { 0, 0, 0, 0 },
        padding = { 0, 0, 0, 0 },
        x = 0,
        y = 0,
        right = 5,
        height = 10,
        resizeItems = false,
        itemPadding  = { 1, 1, 1, 1 },
        itemMargin  = {0, 0, 0, 0},
        autosize = true,
        preserveChildrenOrder = true,
        parent = main_players,
        children = {Chili.Label:New{
            x = 0,
            y = 0,
            width = "100%",
            height = "100%",
            caption = "Spectators",
        }},
    }

    main_win:Hide()

    Spring.SendCommands("unbind any+enter chat")
    widgetHandler:AddAction("s44chat", OnChat)
    Spring.SendCommands("bind any+enter s44chat")
    Spring.SendCommands({"unbindkeyset alt+ctrl+a"})
    widgetHandler:AddAction("s44chatswitchally", OnChatSwitchAlly)
    Spring.SendCommands({"bind alt+ctrl+a s44chatswitchally"})
    Spring.SendCommands({"unbindkeyset alt+ctrl+s"})
    widgetHandler:AddAction("s44chatswitchspec", OnChatSwitchSpec)
    Spring.SendCommands({"bind alt+ctrl+s s44chatswitchspec"})
end

function widget:AddConsoleLine(msg, priority)
    if StringStarts(msg, "Error: Invalid command received") or StringStarts(msg, "Error: Dropped command ") then
        return
    elseif StringStarts(msg, transmitLobbyMagic) then -- sending to the lobby
        return -- ignore
    elseif StringStarts(msg, transmitMagic) then -- receiving from the lobby
        return -- ignore??
    end

    local newMsg = { text = msg, priority = priority }
    MessageProcessor:ProcessConsoleLine(newMsg) --chat_preprocess.lua

    -- if newMsg.msgtype == 'other' then
    --     return
    -- end
    if isPoint(newMsg) then
        -- Points are handled by MapDrawCmd callin
        return
    end

    AddConsoleMessage(newMsg)
end

function widget:MapDrawCmd(playerId, cmdType, px, py, pz, caption)
    if (cmdType ~= 'point') then
        return
    end

    local name, _, spec, teamId, allyTeamId = Spring.GetPlayerInfo(playerId)
    if muted[name] then
        return
    end
    AddConsoleMessage({
        msgtype = ((caption:len() > 0) and 'label' or 'point'),
        playername = name,
        text = caption,
        argument = caption,
        priority = 0, -- just in case ... probably useless
        point = { x = px, y = py, z = pz }
    })
end

function widget:GameStart()
    setupPlayers()
end

function widget:PlayerChanged(playerID)
    setupPlayers(playerID)
end

function widget:Shutdown()
    if (chat_win) then
        chat_win:Dispose()
    end
    Spring.SendCommands({"console 1"})

    widgetHandler:RemoveAction("s44chat")
    Spring.SendCommands({"unbind any+enter s44chat"})
    -- Spring.SendCommands({"bind any+enter chat"})
    widgetHandler:RemoveAction("s44chatswitchally")
    Spring.SendCommands({"unbind alt+ctrl+a s44chatswitchally"})
    Spring.SendCommands({"bind alt+ctrl+a chatswitchally"})
    widgetHandler:RemoveAction("s44chatswitchspec")
    Spring.SendCommands({"unbind alt+ctrl+s s44chatswitchspec"})
    Spring.SendCommands({"bind alt+ctrl+s chatswitchspec"})
end