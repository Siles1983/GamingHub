--[[
    Gaming Hub
    UI/Minesweeper_SettingsPanel.lua
    Version: 1.0.0 (Multilanguage via Language.lua)

    Alle sichtbaren Strings kommen aus GamingHub.GetLocaleTable("MINESWEEPER").
]]

local PAD     = 10
local BOX_PAD = 8
local BOX_H   = 260

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

local function AddLines(parent, lines)
    local prev = nil
    for _, entry in ipairs(lines) do
        local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if prev then
            fs:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, entry.gap or -2)
        else
            fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        end
        fs:SetText(entry.text)
        fs:SetTextColor(entry.r or 0.85, entry.g or 0.80, entry.b or 0.65)
        fs:SetJustifyH("LEFT")
        if entry.w then fs:SetWidth(entry.w) end
        prev = fs
    end
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

local function BuildMinesweeperSettingsPanel(parent)
    local S = GamingHub.MS_Settings
    if not S then return end
    local settings = S:GetAll()

    local L = GamingHub.GetLocaleTable("MINESWEEPER")

    local totalW = parent:GetWidth() - (BOX_PAD * 3)
    if totalW <= 0 then totalW = 580 end
    local halfW  = math.floor(totalW / 2)
    local startY = PAD

    -- ── BOX A: ANLEITUNG ────────────────────────────────────
    local boxA, cA = CreateBox(parent, L["box_guide"], BOX_PAD, startY, halfW, BOX_H)

    local ICON_SIZE = 20
    local iconRows = {
        {
            icon  = "Interface\\Icons\\INV_Misc_Gear_01",
            tint  = { 0.65, 0.65, 0.65 },
            title = L["guide_hidden_title"],
            text  = L["guide_hidden_text"],
        },
        {
            icon  = "Interface\\Icons\\Ability_TownWatch",
            tint  = { 1, 0.7, 0.2 },
            title = L["guide_flag_title"],
            text  = L["guide_flag_text"],
        },
        {
            icon  = "Interface\\Icons\\INV_Misc_Bomb_03",
            tint  = { 1, 0.3, 0.3 },
            title = L["guide_mine_title"],
            text  = L["guide_mine_text"],
        },
    }

    local prevFrame = nil
    for _, row in ipairs(iconRows) do
        local rowFrame = CreateFrame("Frame", nil, cA)
        rowFrame:SetHeight(44)
        if prevFrame then
            rowFrame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, -6)
        else
            rowFrame:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, 0)
        end
        rowFrame:SetPoint("RIGHT", cA, "RIGHT", 0, 0)

        local iconF = CreateFrame("Frame", nil, rowFrame)
        iconF:SetSize(ICON_SIZE, ICON_SIZE)
        iconF:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 0, -2)
        local tex = iconF:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(iconF)
        tex:SetTexture(row.icon)
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        tex:SetVertexColor(row.tint[1], row.tint[2], row.tint[3])

        local fs = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", ICON_SIZE + 6, 0)
        fs:SetPoint("RIGHT", rowFrame, "RIGHT", 0, 0)
        fs:SetText(row.title .. "\n" .. row.text)
        fs:SetTextColor(0.85, 0.80, 0.65)
        fs:SetJustifyH("LEFT")

        prevFrame = rowFrame
    end

    -- Zahlenlegende
    local numFrame = CreateFrame("Frame", nil, cA)
    numFrame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, -10)
    numFrame:SetPoint("RIGHT", cA, "RIGHT", 0, 0)
    numFrame:SetHeight(20)

    local numTitle = numFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    numTitle:SetPoint("TOPLEFT", numFrame, "TOPLEFT", 0, 0)
    numTitle:SetText(L["guide_numbers"])
    numTitle:SetTextColor(0.85, 0.80, 0.65)

    local numColors = {
        {n=1, r=0.26,g=0.26,b=1.00}, {n=2, r=0.13,g=0.67,b=0.13},
        {n=3, r=1.00,g=0.20,b=0.20}, {n=4, r=0.00,g=0.00,b=0.55},
        {n=5, r=0.55,g=0.00,b=0.00}, {n=6, r=0.00,g=0.55,b=0.55},
        {n=7, r=0.40,g=0.40,b=0.40}, {n=8, r=0.65,g=0.65,b=0.65},
    }

    local numRow = CreateFrame("Frame", nil, cA)
    numRow:SetPoint("TOPLEFT", numFrame, "BOTTOMLEFT", 0, -4)
    numRow:SetHeight(20)
    numRow:SetPoint("RIGHT", cA, "RIGHT", 0, 0)

    for i, col in ipairs(numColors) do
        local nfs = numRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nfs:SetPoint("LEFT", numRow, "LEFT", (i-1)*22, 0)
        nfs:SetText(tostring(col.n))
        nfs:SetTextColor(col.r, col.g, col.b)
        nfs:SetFont(nfs:GetFont(), 14, "OUTLINE")
    end

    -- ── BOX B: SCHWIERIGKEIT & SOUNDS ───────────────────────
    local boxB, cB = CreateBox(parent, L["box_diff_sounds"],
        BOX_PAD + halfW + BOX_PAD, startY, halfW, BOX_H)

    AddLines(cB, {
        { text = L["info_easy_title"] .. "   " .. L["info_easy_sub"]   },
        { text = L["info_easy_text"]  },
        { text = " ", gap = -1 },
        { text = L["info_normal_title"] .. " " .. L["info_normal_sub"] },
        { text = L["info_normal_text"] },
        { text = " ", gap = -1 },
        { text = L["info_hard_title"] .. "   " .. L["info_hard_sub"]   },
        { text = L["info_hard_text"]  },
        { text = " ", gap = -1 },
        { text = L["info_tip"] },
    })

    local cbMain = CreateCheckbox(cB, L["sound_enabled"], 0, 130)
    cbMain:SetChecked(settings.soundEnabled)

    local soundItems = {
        { key = "soundOnReveal",  label = L["sound_reveal"]  },
        { key = "soundOnFlag",    label = L["sound_flag"]    },
        { key = "soundOnExplode", label = L["sound_explode"] },
        { key = "soundOnWin",     label = L["sound_win"]     },
    }
    local subCBs = {}
    for i, item in ipairs(soundItems) do
        local cb = CreateCheckbox(cB, item.label, 0, 130 + i*28)
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

    -- ── RESET ─────────────────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetBtn:SetSize(180, 26)
    resetBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -BOX_PAD, BOX_PAD)
    resetBtn:SetText(L["btn_reset"])
    resetBtn:SetScript("OnClick", function()
        S:Reset()
        for _, child in ipairs({ parent:GetChildren() }) do child:Hide() end
        BuildMinesweeperSettingsPanel(parent)
    end)

    -- ── RESPONSIVE ────────────────────────────────────────────
    parent:SetScript("OnSizeChanged", function(self, w, _)
        local avail = w - (BOX_PAD * 3)
        local hw    = math.floor(avail / 2)
        boxA:SetWidth(hw)
        boxB:SetWidth(hw)
        boxB:ClearAllPoints()
        boxB:SetPoint("TOPLEFT", parent, "TOPLEFT", BOX_PAD + hw + BOX_PAD, -startY)
    end)
end

GamingHub.SettingsPanel           = GamingHub.SettingsPanel or {}
GamingHub.SettingsPanel._builders = GamingHub.SettingsPanel._builders or {}
GamingHub.SettingsPanel._builders["MINESWEEPER"] = BuildMinesweeperSettingsPanel
