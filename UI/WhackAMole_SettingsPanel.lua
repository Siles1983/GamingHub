-- Whack-a-Mole – UI/WhackAMole_SettingsPanel.lua
-- Version: 1.0.0 (Multilanguage via Language.lua)

local function BuildWhackAMoleSettingsPanel(parent)
    local S = GamingHub.WAM_Settings
    if not S then return end

    local L = GamingHub.GetLocaleTable("WHACKAMOLE")

    local function MakeBox(title, yOffset, height)
        local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        box:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true, tileEdge=true, tileSize=16, edgeSize=16,
            insets={left=4,right=4,top=4,bottom=4},
        })
        box:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
        box:SetBackdropBorderColor(0.80, 0.65, 0.20, 1)
        box:SetPoint("TOPLEFT",  parent, "TOPLEFT",   10,  yOffset)
        box:SetPoint("TOPRIGHT", parent, "TOPRIGHT",  -10, yOffset)
        box:SetHeight(height)
        local lbl = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", box, "TOPLEFT", 10, -8)
        lbl:SetText("|cffffff00" .. title .. "|r")
        return box
    end

    local y = -10

    -- ── BOX A: MAULWURF-VORSCHAU ─────────────────────────────
    local boxA = MakeBox(L["box_preview"], y, 120)

    local MOLE_ICONS = GamingHub.WAM_Logic and GamingHub.WAM_Logic.MOLE_ICONS or {}
    local BOMB_ICON  = GamingHub.WAM_Logic and GamingHub.WAM_Logic.BOMB_ICON  or ""

    for i, icon in ipairs(MOLE_ICONS) do
        local f = CreateFrame("Frame", nil, boxA)
        f:SetSize(30, 30)
        f:SetPoint("TOPLEFT", boxA, "TOPLEFT", 10 + (i-1)*36, -30)
        local tex = f:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(f)
        tex:SetTexture(icon)
    end

    local bombF = CreateFrame("Frame", nil, boxA)
    bombF:SetSize(30, 30)
    bombF:SetPoint("TOPLEFT", boxA, "TOPLEFT", 10, -68)
    local bombTex = bombF:CreateTexture(nil, "ARTWORK")
    bombTex:SetAllPoints(bombF)
    bombTex:SetTexture(BOMB_ICON)

    local bombLbl = boxA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bombLbl:SetPoint("LEFT", bombF, "RIGHT", 6, 0)
    bombLbl:SetText(L["bomb_hint"])

    y = y - 130

    -- ── BOX B: SOUND ─────────────────────────────────────────
    local boxB = MakeBox(L["box_sounds"], y, 70)

    local cb = CreateFrame("CheckButton", nil, boxB, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", boxB, "TOPLEFT", 6, -28)
    cb:SetChecked(S:Get("sound") ~= false)
    cb.text:SetText(L["sound_enabled"])
    cb:SetScript("OnClick", function(self)
        S:Set("sound", self:GetChecked())
    end)

    y = y - 80

    -- ── BOX C: SPIELANLEITUNG ────────────────────────────────
    local boxC = MakeBox(L["box_guide"], y, 175)

    local guideLines = {
        L["guide_goal"],
        L["guide_click"],
        L["guide_points"],
        L["guide_bomb"],
        L["guide_diff"],
        L["guide_missed"],
        L["guide_highscore"],
        L["guide_timer"],
    }
    for i, line in ipairs(guideLines) do
        local fs = boxC:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", boxC, "TOPLEFT", 10, -28 - (i-1)*17)
        fs:SetText(line)
        fs:SetJustifyH("LEFT")
    end
end

GamingHub.SettingsPanel = GamingHub.SettingsPanel or {}
GamingHub.SettingsPanel._builders = GamingHub.SettingsPanel._builders or {}
GamingHub.SettingsPanel._builders["WHACKAMOLE"] = BuildWhackAMoleSettingsPanel
