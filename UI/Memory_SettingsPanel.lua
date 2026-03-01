--[[
    Gaming Hub
    UI/Memory_SettingsPanel.lua
    Version: 1.1.0 (Multilanguage via Language.lua)

    Alle sichtbaren Strings kommen aus GamingHub.GetLocaleTable("MEMORY").
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
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    lbl:SetText(label)
    lbl:SetTextColor(0.90, 0.85, 0.70)
    return cb
end

local function CreateSimpleDropdown(parent, x, y, w, label, options, getCurrentVal, onChange)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    lbl:SetText(label)
    lbl:SetTextColor(0.90, 0.85, 0.70)

    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, -(y + 14))
    UIDropDownMenu_SetWidth(dd, w)

    local function initDD(self, level)
        for _, opt in ipairs(options) do
            local info   = UIDropDownMenu_CreateInfo()
            info.text    = opt.label
            info.value   = opt.key
            info.checked = (opt.key == getCurrentVal())
            info.func    = function()
                UIDropDownMenu_SetSelectedValue(dd, opt.key)
                UIDropDownMenu_SetText(dd, opt.label)
                onChange(opt.key)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(dd, initDD)

    local cur = getCurrentVal()
    for _, opt in ipairs(options) do
        if opt.key == cur then
            UIDropDownMenu_SetSelectedValue(dd, opt.key)
            UIDropDownMenu_SetText(dd, opt.label)
            break
        end
    end

    return dd
end

local function CreateIconPreview(parent, x, y, size)
    local border = parent:CreateTexture(nil, "BACKGROUND")
    border:SetTexture("Interface\\Buttons\\WHITE8X8")
    border:SetPoint("TOPLEFT",     parent, "TOPLEFT", x,        -y)
    border:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x+size,   -(y+size))
    border:SetVertexColor(0.5, 0.45, 0.3, 1)

    local tex = parent:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT",     parent, "TOPLEFT", x+2,      -(y+2))
    tex:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x+size-2, -(y+size-2))
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    return tex
end

local DECK_PREVIEW_ICONS = {
    classes = {
        "Interface\\Icons\\Ability_Warrior_Charge",
        "Interface\\Icons\\Ability_Rogue_Stealth",
        "Interface\\Icons\\Spell_Fire_FlameBolt",
        "Interface\\Icons\\Spell_Frost_FrostBolt02",
        "Interface\\Icons\\Spell_Holy_Heal",
        "Interface\\Icons\\Spell_Shadow_DeathCoil",
    },
    items = {
        "Interface\\Icons\\INV_Potion_54",
        "Interface\\Icons\\INV_Misc_Key_04",
        "Interface\\Icons\\INV_Misc_Book_09",
        "Interface\\Icons\\Trade_Engineering",
        "Interface\\Icons\\INV_Misc_Gem_Ruby_02",
        "Interface\\Icons\\INV_Scroll_08",
    },
    mounts = {
        "Interface\\Icons\\Ability_Mount_RidingHorse",
        "Interface\\Icons\\Ability_Mount_GriffonMount",
        "Interface\\Icons\\INV_Sword_39",
        "Interface\\Icons\\INV_Axe_09",
        "Interface\\Icons\\INV_Shield_06",
        "Interface\\Icons\\INV_Misc_Gem_01",
    },
}

local function BuildMemorySettingsPanel(parent)
    local S      = GamingHub.MEM_Settings
    local SR     = GamingHub.MEM_SymbolResolver
    local Logic  = GamingHub.MEM_Logic
    if not S then return end
    local settings = S:GetAll()

    local L = GamingHub.GetLocaleTable("MEMORY")

    local totalW  = parent:GetWidth() - (BOX_PAD * 3)
    if totalW <= 0 then totalW = 580 end
    local leftW   = math.floor(totalW * 0.55)
    local rightW  = totalW - leftW
    local topBoxH = 240
    local startY  = PAD

    -- ── BOX A: THEMA & DARSTELLUNG ───────────────────────────
    local boxA, cA = CreateBox(parent, L["box_theme"], BOX_PAD, startY, leftW, topBoxH)

    local deckList = Logic:GetDeckList()
    local deckOpts = {}
    for _, d in ipairs(deckList) do
        deckOpts[#deckOpts+1] = { key = d.key, label = d.name }
    end

    -- Vorschau-Texturen (vor Dropdown deklariert)
    local backPreviewTex  = CreateIconPreview(cA, 0, 122, 36)
    local themePreviewTexs = {}
    for i = 1, 6 do
        themePreviewTexs[i] = CreateIconPreview(cA, (i-1)*28, 170, 24)
    end

    local function UpdateBackPreview()
        local backData = SR:GetCardBack(S:GetAll())
        backPreviewTex:SetTexture(backData.icon)
        backPreviewTex:SetVertexColor(backData.tint[1], backData.tint[2],
            backData.tint[3], backData.tint[4])
    end

    local function UpdateThemePreview()
        local deck = DECK_PREVIEW_ICONS[S:Get("theme")] or DECK_PREVIEW_ICONS.classes
        for i, tex in ipairs(themePreviewTexs) do
            tex:SetTexture(deck[i] or "Interface\\Icons\\INV_Misc_QuestionMark")
            tex:SetVertexColor(1, 1, 1, 1)
        end
    end

    CreateSimpleDropdown(cA, 0, 0, leftW - PAD*2 - 24, L["label_theme_deck"],
        deckOpts,
        function() return S:Get("theme") end,
        function(key)
            S:Set("theme", key)
            if GamingHub.MEM_Renderer then GamingHub.MEM_Renderer.selectedTheme = key end
            UpdateThemePreview()
        end
    )

    local backModes = SR:GetModeList()
    local backOpts  = {}
    for _, m in ipairs(backModes) do
        backOpts[#backOpts+1] = { key = m.key, label = m.label }
    end
    CreateSimpleDropdown(cA, 0, 56, leftW - PAD*2 - 24, L["label_card_back"],
        backOpts,
        function() return S:Get("cardBackMode") end,
        function(key)
            S:Set("cardBackMode", key)
            UpdateBackPreview()
        end
    )

    local backLbl = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    backLbl:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, -108)
    backLbl:SetText(L["label_back_prev"])
    backLbl:SetTextColor(0.75, 0.70, 0.55)

    local themeLbl = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    themeLbl:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, -156)
    themeLbl:SetText(L["label_theme_prev"])
    themeLbl:SetTextColor(0.75, 0.70, 0.55)

    UpdateBackPreview()
    UpdateThemePreview()

    -- ── BOX B: SOUNDS ────────────────────────────────────────
    local boxB, cB = CreateBox(parent, L["box_sounds"],
        BOX_PAD + leftW + BOX_PAD, startY, rightW, topBoxH)

    local cbMain = CreateCheckbox(cB, L["sound_enabled"], 0, 0)
    cbMain:SetChecked(settings.soundEnabled)

    local soundItems = {
        { key = "soundOnFlip",     label = L["sound_flip"]     },
        { key = "soundOnMatch",    label = L["sound_match"]    },
        { key = "soundOnMismatch", label = L["sound_mismatch"] },
        { key = "soundOnWin",      label = L["sound_win"]      },
        { key = "soundOnLose",     label = L["sound_lose"]     },
    }
    local subCBs = {}
    for i, item in ipairs(soundItems) do
        local cb = CreateCheckbox(cB, item.label, 0, i*28)
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
    local fullW    = leftW + rightW + BOX_PAD
    local explBoxH = 120
    local boxC, cC = CreateBox(parent, L["box_guide"],
        BOX_PAD, startY + topBoxH + BOX_PAD, fullW, explBoxH)

    local guideLines = {
        L["guide_goal"],
        L["guide_click"],
        L["guide_match"],
        L["guide_miss"],
        L["guide_timer"],
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
    resetBtn:SetSize(180, 26)
    resetBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -BOX_PAD, BOX_PAD)
    resetBtn:SetText(L["btn_reset"])
    resetBtn:SetScript("OnClick", function()
        S:Reset()
        for _, child in ipairs({ parent:GetChildren() }) do child:Hide() end
        BuildMemorySettingsPanel(parent)
    end)
end

GamingHub.SettingsPanel           = GamingHub.SettingsPanel or {}
GamingHub.SettingsPanel._builders = GamingHub.SettingsPanel._builders or {}
GamingHub.SettingsPanel._builders["MEMORY"] = BuildMemorySettingsPanel
