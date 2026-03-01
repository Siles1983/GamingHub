--[[
    Gaming Hub
    UI/2048_SettingsPanel.lua
    Version: 1.1.0 (Multilanguage via Language.lua)

    Alle sichtbaren Strings kommen aus GamingHub.GetLocaleTable("2048").
]]

local PAD     = 10
local BOX_PAD = 8
local BOX_H   = 200

local function CreateBox(parent, title, x, y, w, h)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    box:SetSize(w, h)
    box:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileEdge = true,
        tileSize = 16,   edgeSize = 16,
        insets   = { left=4, right=4, top=4, bottom=4 },
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
    div:SetHeight(8)
    div:SetHorizTile(true)

    local content = CreateFrame("Frame", nil, box)
    content:SetPoint("TOPLEFT",     box, "TOPLEFT",     PAD, -32)
    content:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -PAD,  PAD)
    return box, content
end

local function CreateCheckbox(parent, label, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    lbl:SetText(label)
    lbl:SetTextColor(0.90, 0.85, 0.70)
    cb.label = lbl
    return cb
end

-- ============================================================
-- Farb-Vorschau Tabellen
-- ============================================================

local PREVIEW_COLORS = {
    CLASSIC  = {
        bg = { {0.93,0.89,0.85},{0.95,0.69,0.47},{0.96,0.49,0.37},{0.93,0.81,0.45},{1.00,0.84,0.00} },
        fg = { {0.47,0.43,0.40},{1,1,1},          {1,1,1},          {1,1,1},          {1,1,1}           },
    },
    HORDE    = {
        bg = { {0.55,0.18,0.18},{0.78,0.28,0.18},{0.90,0.35,0.10},{0.85,0.65,0.10},{1.00,0.92,0.20} },
        fg = { {1,0.9,0.8},     {1,1,1},          {1,1,1},          {0.2,0.08,0.08},{0.2,0.08,0.08}  },
    },
    ALLIANCE = {
        bg = { {0.60,0.70,0.90},{0.35,0.50,0.88},{0.22,0.35,0.82},{0.70,0.78,0.85},{1.00,0.96,0.70} },
        fg = { {0.1,0.15,0.35}, {1,1,1},          {1,1,1},          {0.1,0.15,0.3}, {0.1,0.15,0.3}   },
    },
    NIGHTELF = {
        bg = { {0.35,0.20,0.55},{0.20,0.55,0.35},{0.55,0.20,0.65},{0.20,0.75,0.45},{0.55,0.95,0.65} },
        fg = { {0.9,0.8,1},     {0.9,1,0.9},      {1,0.9,1},        {0.05,0.15,0.1},{0.05,0.2,0.1}   },
    },
    GOBLIN   = {
        bg = { {0.38,0.62,0.22},{0.55,0.78,0.10},{0.78,0.88,0.08},{0.95,0.85,0.10},{1.00,0.92,0.00} },
        fg = { {0.05,0.15,0.05},{0.05,0.15,0.05},{0.05,0.15,0.05},{0.05,0.15,0.05},{0.05,0.15,0.05} },
    },
}
local SWATCH_VALUES = { 2, 8, 32, 128, 2048 }

-- ============================================================
-- Panel-Builder
-- ============================================================

local function Build2048SettingsPanel(parent)

    local S = GamingHub.TDG_Settings
    if not S then return end
    local settings = S:GetAll()

    local L = GamingHub.GetLocaleTable("2048")

    local totalW = parent:GetWidth() - (BOX_PAD * 3)
    if totalW <= 0 then totalW = 580 end
    local halfW  = math.floor(totalW / 2)
    local startY = PAD

    -- ── BOX A: FARB-THEMA ────────────────────────────────────
    local boxA, cA = CreateBox(parent, L["box_theme"], BOX_PAD, startY, halfW, BOX_H)

    local themeLbl = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    themeLbl:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, 0)
    themeLbl:SetText(L["theme_label"])
    themeLbl:SetTextColor(0.80, 0.75, 0.60)

    local ddTheme = CreateFrame("Frame", nil, cA, "UIDropDownMenuTemplate")
    ddTheme:SetPoint("TOPLEFT", cA, "TOPLEFT", -16, -16)
    UIDropDownMenu_SetWidth(ddTheme, halfW - 60)

    local THEME_ITEMS = {
        { label = L["theme_classic"],  value = "CLASSIC"  },
        { label = L["theme_horde"],    value = "HORDE"    },
        { label = L["theme_alliance"], value = "ALLIANCE" },
        { label = L["theme_nightelf"], value = "NIGHTELF" },
        { label = L["theme_goblin"],   value = "GOBLIN"   },
    }

    local previewLabel = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewLabel:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, -66)
    previewLabel:SetText(L["theme_preview"])
    previewLabel:SetTextColor(0.80, 0.75, 0.60)

    local swatches = {}
    for i, val in ipairs(SWATCH_VALUES) do
        local sf = CreateFrame("Frame", nil, cA)
        sf:SetSize(32, 32)
        sf:SetPoint("TOPLEFT", cA, "TOPLEFT", (i-1)*38, -84)
        local bg = sf:CreateTexture(nil, "ARTWORK")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(sf)
        sf.bg = bg
        local lbl = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("CENTER")
        lbl:SetText(tostring(val))
        sf.lbl  = lbl
        sf.val  = val
        swatches[i] = sf
    end

    local function RefreshPreview(themeID)
        local p = PREVIEW_COLORS[themeID] or PREVIEW_COLORS.CLASSIC
        for i, sf in ipairs(swatches) do
            local c = p.bg[i] or {0.5,0.5,0.5}
            local f = p.fg[i] or {1,1,1}
            sf.bg:SetVertexColor(c[1], c[2], c[3], 1)
            sf.lbl:SetTextColor(f[1], f[2], f[3])
        end
    end

    UIDropDownMenu_Initialize(ddTheme, function(self, level)
        for _, item in ipairs(THEME_ITEMS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = item.label
            info.value   = item.value
            info.func    = function(btn)
                UIDropDownMenu_SetSelectedValue(ddTheme, btn.value)
                S:Set("colorTheme", btn.value)
                RefreshPreview(btn.value)
            end
            info.checked = false
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(ddTheme, settings.colorTheme)
    RefreshPreview(settings.colorTheme)

    local hintA = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintA:SetPoint("BOTTOMLEFT", cA, "BOTTOMLEFT", 0, 4)
    hintA:SetText(L["theme_hint"])

    -- ── BOX B: SOUNDS ────────────────────────────────────────
    local boxB, cB = CreateBox(parent, L["box_sounds"],
        BOX_PAD + halfW + BOX_PAD, startY, halfW, BOX_H)

    local cbMain = CreateCheckbox(cB, L["sound_enabled"], 0, 0)
    cbMain:SetChecked(settings.soundEnabled)

    local cbLoss = CreateCheckbox(cB, L["sound_loss"], 0, 34)
    cbLoss:SetChecked(settings.soundOnLoss)

    local function RefreshSubSounds(enabled)
        cbLoss:SetAlpha(enabled and 1 or 0.4)
        cbLoss:SetEnabled(enabled)
    end
    RefreshSubSounds(settings.soundEnabled)

    cbMain:SetScript("OnClick", function(self)
        local v = self:GetChecked()
        S:Set("soundEnabled", v)
        if not v then cbLoss:SetChecked(false) end
        RefreshSubSounds(v)
    end)
    cbLoss:SetScript("OnClick", function(self)
        S:Set("soundOnLoss", self:GetChecked())
        if self:GetChecked() then cbMain:SetChecked(true) end
    end)

    local hintB = cB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintB:SetPoint("BOTTOMLEFT", cB, "BOTTOMLEFT", 0, 4)
    hintB:SetText(L["sound_hint"])

    -- ── RESET-BUTTON ─────────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetBtn:SetSize(180, 26)
    resetBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -BOX_PAD, BOX_PAD)
    resetBtn:SetText(L["btn_reset"])
    resetBtn:SetScript("OnClick", function()
        S:Reset()
        for _, child in ipairs({ parent:GetChildren() }) do child:Hide() end
        Build2048SettingsPanel(parent)
    end)

    -- ── RESPONSIVE ───────────────────────────────────────────
    parent:SetScript("OnSizeChanged", function(self, w, _)
        local avail = w - (BOX_PAD * 3)
        local hw    = math.floor(avail / 2)
        boxA:SetWidth(hw)
        boxB:SetWidth(hw)
        boxB:ClearAllPoints()
        boxB:SetPoint("TOPLEFT", parent, "TOPLEFT", BOX_PAD + hw + BOX_PAD, -startY)
    end)
end

-- ============================================================
-- REGISTRIERUNG
-- ============================================================

GamingHub.SettingsPanel = GamingHub.SettingsPanel or {}

if GamingHub.SettingsPanel.RegisterBuilder then
    GamingHub.SettingsPanel.RegisterBuilder("2048", Build2048SettingsPanel)
else
    GamingHub.SettingsPanel._builders = GamingHub.SettingsPanel._builders or {}
    GamingHub.SettingsPanel._builders["2048"] = Build2048SettingsPanel
end
