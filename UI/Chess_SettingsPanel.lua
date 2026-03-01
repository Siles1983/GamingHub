--[[
    Gaming Hub
    UI/Chess_SettingsPanel.lua
    Version: 1.0.0 (Multilanguage via Language.lua)

    Alle sichtbaren Strings kommen aus GamingHub.GetLocaleTable("CHESS").
]]

local PAD     = 10
local BOX_PAD = 8
local BOX_H   = 280

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

-- Icon-Definitionen (keine Strings – nur Pfade und Tints)
local PIECE_ICONS = {
    { iconW = "Interface\\Icons\\INV_Helmet_01",           iconB = "Interface\\Icons\\INV_Helmet_02",       nameKey = "piece_king",   descKey = "piece_king_desc"   },
    { iconW = "Interface\\Icons\\INV_Jewelry_Ring_05",     iconB = "Interface\\Icons\\INV_Jewelry_Ring_01", nameKey = "piece_queen",  descKey = "piece_queen_desc"  },
    { iconW = "Interface\\Icons\\Ability_Repair",          iconB = "Interface\\Icons\\INV_Stone_15",        nameKey = "piece_rook",   descKey = "piece_rook_desc"   },
    { iconW = "Interface\\Icons\\Ability_Mount_RidingHorse",iconB = "Interface\\Icons\\Ability_Mount_Raptor",nameKey = "piece_knight", descKey = "piece_knight_desc" },
    { iconW = "Interface\\Icons\\INV_Shield_06",           iconB = "Interface\\Icons\\INV_Shield_05",       nameKey = "piece_pawn",   descKey = "piece_pawn_desc"   },
}

local function BuildChessSettingsPanel(parent)
    local S = GamingHub.Chess_Settings
    if not S then return end
    local settings = S:GetAll()

    local L = GamingHub.GetLocaleTable("CHESS")

    local totalW = parent:GetWidth() - (BOX_PAD * 3)
    if totalW <= 0 then totalW = 580 end
    local halfW  = math.floor(totalW / 2)
    local startY = PAD

    -- ── BOX A: FIGUREN-LEGENDE ───────────────────────────────
    local boxA, cA = CreateBox(parent, L["box_legend"], BOX_PAD, startY, halfW, BOX_H)

    local ICON_SIZE = 28
    local ROW_H     = 52

    for i, entry in ipairs(PIECE_ICONS) do
        local yOff = (i-1) * ROW_H

        -- Allianz-Icon (blau)
        local iconWFrame = CreateFrame("Frame", nil, cA)
        iconWFrame:SetSize(ICON_SIZE, ICON_SIZE)
        iconWFrame:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, -yOff)
        local iconW = iconWFrame:CreateTexture(nil, "ARTWORK")
        iconW:SetAllPoints(iconWFrame)
        iconW:SetTexture(entry.iconW)
        iconW:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        iconW:SetVertexColor(0.55, 0.70, 1.00)

        -- Horde-Icon (rot)
        local iconBFrame = CreateFrame("Frame", nil, cA)
        iconBFrame:SetSize(ICON_SIZE, ICON_SIZE)
        iconBFrame:SetPoint("TOPLEFT", cA, "TOPLEFT", ICON_SIZE + 4, -yOff)
        local iconB = iconBFrame:CreateTexture(nil, "ARTWORK")
        iconB:SetAllPoints(iconBFrame)
        iconB:SetTexture(entry.iconB)
        iconB:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        iconB:SetVertexColor(1.00, 0.35, 0.35)

        -- Name
        local nameFS = cA:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameFS:SetPoint("TOPLEFT", cA, "TOPLEFT", ICON_SIZE*2 + 10, -yOff)
        nameFS:SetText("|cffffff00" .. L[entry.nameKey] .. "|r")

        -- Beschreibung
        local descFS = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descFS:SetPoint("TOPLEFT", cA, "TOPLEFT", ICON_SIZE*2 + 10, -(yOff + 16))
        descFS:SetWidth(halfW - ICON_SIZE*2 - 20)
        descFS:SetText(L[entry.descKey])
        descFS:SetTextColor(0.80, 0.75, 0.60)
        descFS:SetJustifyH("LEFT")
    end

    -- ── BOX B: KI-INFO + SOUNDS ──────────────────────────────
    local boxB, cB = CreateBox(parent, L["box_ki_sounds"],
        BOX_PAD + halfW + BOX_PAD, startY, halfW, BOX_H)

    local kiLines = {
        L["info_classic_title"],
        L["info_classic_text"],
        L["info_classic_text2"],
        " ",
        L["info_pro_title"],
        L["info_pro_text1"],
        L["info_pro_text2"],
        " ",
        L["info_insane_title"],
        L["info_insane_text1"],
        L["info_insane_text2"],
        " ",
        L["info_diff_hint"],
    }

    local prevFS = nil
    for _, line in ipairs(kiLines) do
        local fs = cB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if prevFS then
            fs:SetPoint("TOPLEFT", prevFS, "BOTTOMLEFT", 0, -2)
        else
            fs:SetPoint("TOPLEFT", cB, "TOPLEFT", 0, 0)
        end
        fs:SetText(line)
        fs:SetTextColor(0.85, 0.80, 0.65)
        fs:SetJustifyH("LEFT")
        prevFS = fs
    end

    -- Sound-Checkbox
    local cbSound = CreateFrame("CheckButton", nil, cB, "UICheckButtonTemplate")
    cbSound:SetSize(24, 24)
    cbSound:SetPoint("BOTTOMLEFT", cB, "BOTTOMLEFT", 0, 30)
    cbSound:SetChecked(settings.soundEnabled)
    local lblSound = cB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblSound:SetPoint("LEFT", cbSound, "RIGHT", 4, 0)
    lblSound:SetText(L["sound_enabled"])
    lblSound:SetTextColor(0.90, 0.85, 0.70)
    cbSound:SetScript("OnClick", function(self)
        S:Set("soundEnabled", self:GetChecked())
    end)

    local hint = cB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("BOTTOMLEFT", cB, "BOTTOMLEFT", 0, 6)
    hint:SetText(L["sound_hint"])
    hint:SetJustifyH("LEFT")

    -- ── RESET ─────────────────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetBtn:SetSize(180, 26)
    resetBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -BOX_PAD, BOX_PAD)
    resetBtn:SetText(L["btn_reset"])
    resetBtn:SetScript("OnClick", function()
        S:Reset()
        for _, child in ipairs({ parent:GetChildren() }) do child:Hide() end
        BuildChessSettingsPanel(parent)
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
GamingHub.SettingsPanel._builders["CHESS"] = BuildChessSettingsPanel
