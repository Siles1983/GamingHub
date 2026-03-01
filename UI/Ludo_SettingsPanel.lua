--[[
    Gaming Hub – Ludo (Mensch ärgere dich nicht)
    UI/Ludo_SettingsPanel.lua
    Version: 1.0.0 (Multilanguage via Language.lua)
]]

local PAD     = 10
local BOX_PAD = 8

local function CreateBox(parent, title, x, y, w, h)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    box:SetSize(w, h)
    box:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileEdge = true, tileSize = 16, edgeSize = 16,
        insets = { left=4, right=4, top=4, bottom=4 },
    })
    box:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
    box:SetBackdropBorderColor(0.90, 0.75, 0.30, 1)
    local titleFS = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFS:SetPoint("TOPLEFT", box, "TOPLEFT", PAD, -7)
    titleFS:SetText("|cffffd700" .. title .. "|r")
    local div = box:CreateTexture(nil, "ARTWORK")
    div:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Divider")
    div:SetPoint("TOPLEFT",  box, "TOPLEFT",  4, -22)
    div:SetPoint("TOPRIGHT", box, "TOPRIGHT", -4, -22)
    div:SetHeight(8); div:SetHorizTile(true)
    local content = CreateFrame("Frame", nil, box)
    content:SetPoint("TOPLEFT",     box, "TOPLEFT",     PAD, -32)
    content:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -PAD, PAD)
    return box, content
end

local function CreateCheckbox(parent, label, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(22, 22)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    lbl:SetText(label)
    lbl:SetTextColor(0.90, 0.85, 0.70)
    return cb
end

local function CreateSimpleDropdown(parent, x, y, w, label, options, getCurrent, onChange)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    lbl:SetText(label)
    lbl:SetTextColor(0.90, 0.85, 0.70)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, -(y + 14))
    UIDropDownMenu_SetWidth(dd, w)
    local function init(self, level)
        for _, opt in ipairs(options) do
            local info   = UIDropDownMenu_CreateInfo()
            info.text    = opt.label
            info.value   = opt.key
            info.checked = (opt.key == getCurrent())
            info.func    = function()
                UIDropDownMenu_SetSelectedValue(dd, opt.key)
                UIDropDownMenu_SetText(dd, opt.label)
                onChange(opt.key)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(dd, init)
    local cur = getCurrent()
    for _, opt in ipairs(options) do
        if opt.key == cur then
            UIDropDownMenu_SetSelectedValue(dd, opt.key)
            UIDropDownMenu_SetText(dd, opt.label)
            break
        end
    end
    return dd
end

local UpdateLudoPreview  -- forward declaration

local function BuildLudoSettingsPanel(parent)
    local S     = GamingHub.LUDO_Settings
    local T     = GamingHub.LUDO_Themes
    local board = GamingHub.LUDO_Board
    if not S or not T or not board then return end

    local L = GamingHub.GetLocaleTable("LUDO")

    local totalW  = parent:GetWidth() - (BOX_PAD * 3)
    if totalW <= 0 then totalW = 580 end
    local leftW   = math.floor(totalW * 0.55)
    local rightW  = totalW - leftW
    local topBoxH = 210
    local startY  = PAD

    -- ── BOX A: SPIEL-OPTIONEN ────────────────────────────────
    local boxA, cA = CreateBox(parent, L["box_options"], BOX_PAD, startY, leftW, topBoxH)

    -- Thema-Dropdown
    local themeList = T:GetThemeList()
    local themeOpts = {}
    for _, t in ipairs(themeList) do
        themeOpts[#themeOpts+1] = { key=t.key, label=t.name }
    end
    CreateSimpleDropdown(cA, 0, 0, leftW - PAD*2 - 24, L["label_theme"],
        themeOpts,
        function() return S:Get("theme") end,
        function(key)
            S:Set("theme", key)
            if GamingHub.LUDO_Renderer then
                GamingHub.LUDO_Renderer._currentTheme = key
            end
            UpdateLudoPreview(cA, S, T, board)
        end
    )

    -- Spieler-Farbe Dropdown
    local colorOpts = {
        { key=1, label=L["color_blue"] },
        { key=2, label=L["color_red"]  },
    }
    CreateSimpleDropdown(cA, 0, 60, leftW - PAD*2 - 24, L["label_color"],
        colorOpts,
        function() return S:Get("playerColor") end,
        function(key)
            S:Set("playerColor", key)
            if GamingHub.LUDO_Renderer then
                GamingHub.LUDO_Renderer._currentColor = key
            end
            UpdateLudoPreview(cA, S, T, board)
        end
    )

    -- Vorschau: Spieler & KI Icons
    local prevY = 130
    local prevLbl = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevLbl:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, -prevY)
    prevLbl:SetText(L["label_preview"])

    local ICON_SIZE = 32
    local ICON_GAP  = 8
    local playerIcon1 = cA:CreateTexture(nil, "ARTWORK")
    playerIcon1:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, -(prevY + 18))
    playerIcon1:SetSize(ICON_SIZE, ICON_SIZE)
    playerIcon1:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    cA.playerIcon1 = playerIcon1

    local playerLabel1 = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerLabel1:SetPoint("TOP", playerIcon1, "BOTTOM", 0, -2)
    playerLabel1:SetText(L["preview_you"])
    cA.playerLabel1 = playerLabel1

    local playerIcon2 = cA:CreateTexture(nil, "ARTWORK")
    playerIcon2:SetPoint("TOPLEFT", playerIcon1, "TOPRIGHT", ICON_GAP + 20, 0)
    playerIcon2:SetSize(ICON_SIZE, ICON_SIZE)
    playerIcon2:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    cA.playerIcon2 = playerIcon2

    local playerLabel2 = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerLabel2:SetPoint("TOP", playerIcon2, "BOTTOM", 0, -2)
    playerLabel2:SetText(L["preview_ai"])
    cA.playerLabel2 = playerLabel2

    -- Start-Button
    local startBtn = CreateFrame("Button", nil, cA, "UIPanelButtonTemplate")
    startBtn:SetSize(160, 26)
    startBtn:SetPoint("BOTTOMLEFT", cA, "BOTTOMLEFT", 0, 0)
    startBtn:SetText(L["btn_start"])
    startBtn:SetScript("OnClick", function()
        if GamingHub.LUDO_Renderer then
            GamingHub.LUDO_Renderer:StartNewGame()
        end
    end)

    -- Vorschau-Funktion (nach Elementen definiert, forward declaration oben)
    function UpdateLudoPreview(content, settings, themes, boardRef)
        local theme    = themes:GetTheme(settings:Get("theme"))
        local humanClr = settings:Get("playerColor")
        local aiClr    = (humanClr == 1) and 2 or 1
        local _L       = GamingHub.GetLocaleTable("LUDO")

        if content.playerIcon1 then
            content.playerIcon1:SetTexture(theme.pieces[humanClr])
            local c = theme.colors[humanClr]
            content.playerIcon1:SetVertexColor(c[1], c[2], c[3])
        end
        if content.playerLabel1 then
            local c = theme.colors[humanClr]
            content.playerLabel1:SetText(string.format(
                _L["preview_you_fmt"],
                c[1]*255, c[2]*255, c[3]*255,
                boardRef.PLAYER_NAMES[humanClr]))
        end
        if content.playerIcon2 then
            content.playerIcon2:SetTexture(theme.pieces[aiClr])
            local c = theme.colors[aiClr]
            content.playerIcon2:SetVertexColor(c[1], c[2], c[3])
        end
        if content.playerLabel2 then
            local c = theme.colors[aiClr]
            content.playerLabel2:SetText(string.format(
                _L["preview_ai_fmt"],
                c[1]*255, c[2]*255, c[3]*255,
                boardRef.PLAYER_NAMES[aiClr]))
        end
    end

    UpdateLudoPreview(cA, S, T, board)

    -- ── BOX B: SOUNDS ────────────────────────────────────────
    local boxB, cB = CreateBox(parent, L["box_sounds"],
        BOX_PAD + leftW + BOX_PAD, startY, rightW, topBoxH)

    local cbMain = CreateCheckbox(cB, L["sound_enabled"], 0, 0)
    cbMain:SetChecked(S:Get("soundEnabled"))

    local soundItems = {
        { key = "soundOnRoll",    label = L["sound_roll"]    },
        { key = "soundOnMove",    label = L["sound_move"]    },
        { key = "soundOnCapture", label = L["sound_capture"] },
        { key = "soundOnHome",    label = L["sound_home"]    },
        { key = "soundOnWin",     label = L["sound_win"]     },
    }
    local subCBs = {}
    for i, item in ipairs(soundItems) do
        local cb = CreateCheckbox(cB, item.label, 0, i*26)
        cb:SetChecked(S:Get(item.key))
        cb._key = item.key
        subCBs[#subCBs+1] = cb
    end

    local function RefreshSubs(enabled)
        for _, cb in ipairs(subCBs) do
            cb:SetAlpha(enabled and 1 or 0.4)
            cb:SetEnabled(enabled)
        end
    end
    RefreshSubs(S:Get("soundEnabled"))

    cbMain:SetScript("OnClick", function(self)
        local v = self:GetChecked()
        S:Set("soundEnabled", v)
        if not v then for _, cb in ipairs(subCBs) do cb:SetChecked(false) end end
        RefreshSubs(v)
    end)
    for _, cb in ipairs(subCBs) do
        cb:SetScript("OnClick", function(self)
            S:Set(self._key, self:GetChecked())
            if self:GetChecked() then cbMain:SetChecked(true) end
        end)
    end

    -- ── BOX C: SPIELANLEITUNG ────────────────────────────────
    local fullW  = leftW + rightW + BOX_PAD
    local boxC, cC = CreateBox(parent, L["box_guide"],
        BOX_PAD, startY + topBoxH + BOX_PAD, fullW, 185)

    local guideLines = {
        L["guide_goal"],
        L["guide_dice"],
        L["guide_six"],
        L["guide_move"],
        L["guide_capture"],
        L["guide_safe"],
        L["guide_ai"],
        L["guide_hint"],
    }
    local prev = nil
    for _, line in ipairs(guideLines) do
        local fs = cC:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if prev then
            fs:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -3)
        else
            fs:SetPoint("TOPLEFT", cC, "TOPLEFT", 0, 0)
        end
        fs:SetText(line)
        fs:SetTextColor(0.85, 0.80, 0.65)
        fs:SetJustifyH("LEFT")
        fs:SetPoint("RIGHT", cC, "RIGHT", 0, 0)
        prev = fs
    end

    -- ── RESET ─────────────────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetBtn:SetSize(180, 24)
    resetBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -BOX_PAD, BOX_PAD)
    resetBtn:SetText(L["btn_reset"])
    resetBtn:SetScript("OnClick", function()
        S:Reset()
        for _, child in ipairs({ parent:GetChildren() }) do child:Hide() end
        BuildLudoSettingsPanel(parent)
    end)
end

GamingHub.SettingsPanel           = GamingHub.SettingsPanel or {}
GamingHub.SettingsPanel._builders = GamingHub.SettingsPanel._builders or {}
GamingHub.SettingsPanel._builders["LUDO"] = BuildLudoSettingsPanel
