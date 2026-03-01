-- UI/Hangman_SettingsPanel.lua
-- Version: 1.0.0 (Multilanguage via Language.lua)
-- Layout: [Klang] [Statistiken] | [Spielanleitung volle Breite]

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
    div:SetPoint("TOPLEFT",  box, "TOPLEFT",   4, -22)
    div:SetPoint("TOPRIGHT", box, "TOPRIGHT", -4, -22)
    div:SetHeight(8); div:SetHorizTile(true)
    local content = CreateFrame("Frame", nil, box)
    content:SetPoint("TOPLEFT",     box, "TOPLEFT",     PAD, -32)
    content:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -PAD, PAD)
    return box, content
end

local function BuildHangmanSettingsPanel(parent)
    local Settings = GamingHub.HGM_Settings
    if not Settings then return end

    local L = GamingHub.GetLocaleTable("HANGMAN")

    local totalW = parent:GetWidth() - (BOX_PAD * 2)
    if not totalW or totalW <= 0 then totalW = 580 end

    local halfW   = math.floor(totalW * 0.5)
    local topBoxH = 110
    local startY  = BOX_PAD

    -- ── BOX LINKS: KLANG ─────────────────────────────────────
    local boxA, cA = CreateBox(parent, L["box_sounds"],
        BOX_PAD, startY, halfW - BOX_PAD, topBoxH)

    local cbSound = CreateFrame("CheckButton", nil, cA, "UICheckButtonTemplate")
    cbSound:SetSize(24, 24)
    cbSound:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, 0)
    local cbSoundLabel = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cbSoundLabel:SetPoint("LEFT", cbSound, "RIGHT", 4, 0)
    cbSoundLabel:SetText(L["sound_enabled"])
    cbSoundLabel:SetTextColor(0.90, 0.85, 0.70)
    cbSound:SetChecked(Settings:Get("sound"))
    cbSound:SetScript("OnClick", function(self2)
        Settings:Set("sound", self2:GetChecked())
    end)

    -- ── BOX RECHTS: STATISTIKEN ──────────────────────────────
    local boxB, cB = CreateBox(parent, L["box_stats"],
        BOX_PAD + halfW, startY, halfW - BOX_PAD, topBoxH)

    local winsText = cB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    winsText:SetPoint("TOPLEFT", cB, "TOPLEFT", 0, 0)
    winsText:SetText(string.format(L["stats_wins"], Settings:Get("wins")))
    winsText:SetTextColor(0.90, 0.85, 0.70)

    local lossText = cB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lossText:SetPoint("TOPLEFT", winsText, "BOTTOMLEFT", 0, -8)
    lossText:SetText(string.format(L["stats_losses"], Settings:Get("losses")))
    lossText:SetTextColor(0.90, 0.85, 0.70)

    local resetBtn = CreateFrame("Button", nil, boxB, "UIPanelButtonTemplate")
    resetBtn:SetSize(110, 22)
    resetBtn:SetPoint("BOTTOMRIGHT", boxB, "BOTTOMRIGHT", -8, 8)
    resetBtn:SetText(L["btn_reset_stats"])
    resetBtn:SetScript("OnClick", function()
        Settings:Set("wins",   0)
        Settings:Set("losses", 0)
        local _L2 = GamingHub.GetLocaleTable("HANGMAN")
        winsText:SetText(string.format(_L2["stats_wins"],   0))
        lossText:SetText(string.format(_L2["stats_losses"], 0))
    end)

    -- ── BOX UNTEN: SPIELANLEITUNG (volle Breite) ─────────────
    local fullW     = totalW - BOX_PAD
    local guideBoxH = 130
    local boxC, cC  = CreateBox(parent, L["box_guide"],
        BOX_PAD, startY + topBoxH + BOX_PAD, fullW, guideBoxH)

    local guideLines = {
        L["guide_goal"],
        L["guide_input"],
        L["guide_error"],
        L["guide_lose"],
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
        fs:SetPoint("RIGHT", cC, "RIGHT", 0, 0)
        fs:SetText(line)
        fs:SetTextColor(0.85, 0.80, 0.65)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(true)
        prev = fs
    end
end

GamingHub.SettingsPanel           = GamingHub.SettingsPanel or {}
GamingHub.SettingsPanel._builders = GamingHub.SettingsPanel._builders or {}
GamingHub.SettingsPanel._builders["HANGMAN"] = BuildHangmanSettingsPanel
