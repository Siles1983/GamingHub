--[[
    Gaming Hub – Simon Says
    UI/SimonSays_SettingsPanel.lua
    Version: 1.0.0 (Multilanguage via Language.lua)

    Alle sichtbaren Strings kommen aus GamingHub.GetLocaleTable("SIMONSAYS").
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

local function BuildSimonSaysSettingsPanel(parent)
    local S = GamingHub.SS_Settings
    local T = GamingHub.SS_Themes
    if not S then return end
    local settings = S:GetAll()

    local L = GamingHub.GetLocaleTable("SIMONSAYS")

    local totalW  = parent:GetWidth() - (BOX_PAD * 3)
    if totalW <= 0 then totalW = 580 end
    local leftW   = math.floor(totalW * 0.58)
    local rightW  = totalW - leftW
    local topBoxH = 200
    local startY  = PAD

    -- ── BOX A: THEMA & DARSTELLUNG ───────────────────────────
    local boxA, cA = CreateBox(parent, L["box_theme"], BOX_PAD, startY, leftW, topBoxH)

    local previewTexs = {}

    local function UpdateThemePreview()
        local syms = T:GetSymbolsForDiff(S:Get("theme"), "easy")
        for i = 1, 4 do
            local sym = syms[i]
            if sym and previewTexs[i] then
                if sym.isAtlas then
                    local info = C_Texture.GetAtlasInfo(sym.atlas)
                    if info and info.file then
                        previewTexs[i]:SetTexture(info.file)
                        previewTexs[i]:SetTexCoord(
                            info.leftTexCoord, info.rightTexCoord,
                            info.topTexCoord,  info.bottomTexCoord)
                        previewTexs[i]:SetVertexColor(1, 1, 1)
                    else
                        previewTexs[i]:SetTexture("Interface\\Buttons\\WHITE8X8")
                        previewTexs[i]:SetVertexColor(sym.color[1], sym.color[2], sym.color[3])
                    end
                else
                    previewTexs[i]:SetTexture(sym.icon)
                    previewTexs[i]:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                    previewTexs[i]:SetVertexColor(sym.color[1], sym.color[2], sym.color[3])
                end
            end
        end
    end

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
            if GamingHub.SS_Renderer then GamingHub.SS_Renderer._currentTheme = key end
            UpdateThemePreview()
        end
    )

    local prevLbl = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevLbl:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, -100)
    prevLbl:SetText(L["label_preview"])
    prevLbl:SetTextColor(0.75, 0.70, 0.55)

    local iconY    = 118
    local iconSize = 32
    local iconGap  = 6
    for i = 1, 4 do
        local bx = (i-1) * (iconSize + iconGap)
        local border = cA:CreateTexture(nil, "BACKGROUND")
        border:SetTexture("Interface\\Buttons\\WHITE8X8")
        border:SetPoint("TOPLEFT", cA, "TOPLEFT", bx, -iconY)
        border:SetSize(iconSize, iconSize)
        border:SetVertexColor(0.30, 0.26, 0.14, 1)
        local tex = cA:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", cA, "TOPLEFT", bx + 2, -(iconY + 2))
        tex:SetSize(iconSize - 4, iconSize - 4)
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        previewTexs[i] = tex
    end

    UpdateThemePreview()

    -- ── BOX B: SOUNDS ────────────────────────────────────────
    local boxB, cB = CreateBox(parent, L["box_sounds"],
        BOX_PAD + leftW + BOX_PAD, startY, rightW, topBoxH)

    local cbMain = CreateCheckbox(cB, L["sound_enabled"], 0, 0)
    cbMain:SetChecked(settings.soundEnabled)

    local soundItems = {
        { key = "soundOnFlash", label = L["sound_flash"] },
        { key = "soundOnInput", label = L["sound_input"] },
        { key = "soundOnWin",   label = L["sound_win"]   },
        { key = "soundOnLose",  label = L["sound_lose"]  },
    }
    local subCBs = {}
    for i, item in ipairs(soundItems) do
        local cb = CreateCheckbox(cB, item.label, 0, i*26)
        cb:SetChecked(settings[item.key])
        cb._key = item.key
        subCBs[#subCBs+1] = cb
    end

    local function RefreshSubs(enabled)
        for _, cb in ipairs(subCBs) do
            cb:SetAlpha(enabled and 1 or 0.4)
            cb:SetEnabled(enabled)
        end
    end
    RefreshSubs(settings.soundEnabled)

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
        BOX_PAD, startY + topBoxH + BOX_PAD, fullW, 140)

    local guideLines = {
        L["guide_goal"],
        L["guide_flow"],
        L["guide_diff"],
        L["guide_seq"],
        L["guide_fail"],
        L["guide_tip"],
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
        BuildSimonSaysSettingsPanel(parent)
    end)
end

GamingHub.SettingsPanel           = GamingHub.SettingsPanel or {}
GamingHub.SettingsPanel._builders = GamingHub.SettingsPanel._builders or {}
GamingHub.SettingsPanel._builders["SIMONSAYS"] = BuildSimonSaysSettingsPanel
