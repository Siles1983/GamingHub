--[[
    Gaming Hub
    UI/Battleship_SettingsPanel.lua
    Version: 1.0.0 (Multilanguage via Language.lua)

    Alle sichtbaren Strings kommen aus GamingHub.GetLocaleTable("BATTLESHIP").
]]

local PAD     = 10
local BOX_PAD = 8
local BOX_H   = 230

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
    div:SetHeight(8); div:SetHorizTile(true)

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
    return cb
end

-- ============================================================
-- Panel-Builder
-- ============================================================

local function BuildBattleshipSettingsPanel(parent)

    local S = GamingHub.BS_Settings
    if not S then return end
    local settings = S:GetAll()

    local L = GamingHub.GetLocaleTable("BATTLESHIP")

    local totalW = parent:GetWidth() - (BOX_PAD * 3)
    if totalW <= 0 then totalW = 580 end
    local halfW  = math.floor(totalW / 2)
    local startY = PAD

    -- ── BOX A: KI-SCHWIERIGKEIT ──────────────────────────────
    local boxA, cA = CreateBox(parent, L["box_difficulty"], BOX_PAD, startY, halfW, BOX_H)

    local infoLines = {
        L["info_classic_title"],
        L["info_classic_text"],
        " ",
        L["info_pro_title"],
        L["info_pro_text1"],
        L["info_pro_text2"],
        L["info_pro_text3"],
        " ",
        L["info_insane_title"],
        L["info_insane_text1"],
        L["info_insane_text2"],
        L["info_insane_text3"],
        L["info_insane_text4"],
    }

    local prevFS = nil
    for _, line in ipairs(infoLines) do
        local fs = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if prevFS then
            fs:SetPoint("TOPLEFT", prevFS, "BOTTOMLEFT", 0, -2)
        else
            fs:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, 0)
        end
        fs:SetText(line)
        fs:SetTextColor(0.85, 0.80, 0.65)
        fs:SetJustifyH("LEFT")
        prevFS = fs
    end

    local hintA = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintA:SetPoint("BOTTOMLEFT", cA, "BOTTOMLEFT", 0, 4)
    hintA:SetText(L["hint_diff_panel"])
    hintA:SetJustifyH("LEFT")

    -- ── BOX B: SOUNDS ────────────────────────────────────────
    local boxB, cB = CreateBox(parent, L["box_sounds"],
        BOX_PAD + halfW + BOX_PAD, startY, halfW, BOX_H)

    local cbMain = CreateCheckbox(cB, L["sound_enabled"], 0, 0)
    cbMain:SetChecked(settings.soundEnabled)

    local soundItems = {
        { key = "soundOnHit",  label = L["sound_hit"]  },
        { key = "soundOnSunk", label = L["sound_sunk"] },
        { key = "soundOnWin",  label = L["sound_win"]  },
        { key = "soundOnLoss", label = L["sound_loss"] },
    }

    local subCBs = {}
    for i, item in ipairs(soundItems) do
        local cb = CreateCheckbox(cB, item.label, 0, 28 + (i-1)*28)
        cb:SetChecked(settings[item.key])
        cb._key = item.key
        table.insert(subCBs, cb)
    end

    local function RefreshSubSounds(enabled)
        for _, cb in ipairs(subCBs) do
            cb:SetAlpha(enabled and 1 or 0.4)
            cb:SetEnabled(enabled)
        end
    end
    RefreshSubSounds(settings.soundEnabled)

    cbMain:SetScript("OnClick", function(self)
        local v = self:GetChecked()
        S:Set("soundEnabled", v)
        if not v then
            for _, cb in ipairs(subCBs) do cb:SetChecked(false) end
        end
        RefreshSubSounds(v)
    end)

    for _, cb in ipairs(subCBs) do
        cb:SetScript("OnClick", function(self)
            S:Set(self._key, self:GetChecked())
            if self:GetChecked() then cbMain:SetChecked(true) end
        end)
    end

    local hintB = cB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintB:SetPoint("BOTTOMLEFT", cB, "BOTTOMLEFT", 0, 4)
    hintB:SetText(L["sound_hint"])
    hintB:SetJustifyH("LEFT")

    -- ── RESET ────────────────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetBtn:SetSize(180, 26)
    resetBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -BOX_PAD, BOX_PAD)
    resetBtn:SetText(L["btn_reset"])
    resetBtn:SetScript("OnClick", function()
        S:Reset()
        for _, child in ipairs({ parent:GetChildren() }) do child:Hide() end
        BuildBattleshipSettingsPanel(parent)
    end)

    -- ── RESPONSIVE ───────────────────────────────────────────
    parent:SetScript("OnSizeChanged", function(self, w, _)
        local avail = w - (BOX_PAD * 3)
        local hw    = math.floor(avail / 2)
        boxA:SetWidth(hw); boxA:SetHeight(BOX_H)
        boxB:SetWidth(hw); boxB:SetHeight(BOX_H)
        boxB:ClearAllPoints()
        boxB:SetPoint("TOPLEFT", parent, "TOPLEFT", BOX_PAD + hw + BOX_PAD, -startY)
    end)
end

-- ============================================================
-- REGISTRIERUNG
-- ============================================================

GamingHub.SettingsPanel = GamingHub.SettingsPanel or {}

if GamingHub.SettingsPanel.RegisterBuilder then
    GamingHub.SettingsPanel.RegisterBuilder("BATTLESHIP", BuildBattleshipSettingsPanel)
else
    GamingHub.SettingsPanel._builders = GamingHub.SettingsPanel._builders or {}
    GamingHub.SettingsPanel._builders["BATTLESHIP"] = BuildBattleshipSettingsPanel
end
