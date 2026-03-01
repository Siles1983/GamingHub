--[[
    Gaming Hub – BlockDrop (intern: Tetris)
    UI/Tetris_SettingsPanel.lua
    Version: 1.0.0 (Multilanguage via Language.lua)
    WICHTIG: Niemals "Tetris" im UI-Text verwenden!
]]

local BOX_PAD = 8
local PAD     = 10

local function CreateBox(parent, title, x, y, w, h)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileEdge = true, tileSize = 16, edgeSize = 16,
        insets = { left=4, right=4, top=4, bottom=4 },
    })
    box:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    box:SetBackdropBorderColor(0.80, 0.65, 0.20, 1)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    box:SetSize(w, h)
    local lbl = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", box, "TOPLEFT", 10, -8)
    lbl:SetText("|cffffff00" .. title .. "|r")
    local div = box:CreateTexture(nil, "ARTWORK")
    div:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Divider")
    div:SetPoint("TOPLEFT",  box, "TOPLEFT",  4, -22)
    div:SetPoint("TOPRIGHT", box, "TOPRIGHT", -4, -22)
    div:SetHeight(8); div:SetHorizTile(true)
    local c = CreateFrame("Frame", nil, box)
    c:SetPoint("TOPLEFT",     box, "TOPLEFT",      10, -32)
    c:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -10,   6)
    return box, c
end

local function CreateCheckbox(parent, label, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(22, 22)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    cb.text:SetText(label)
    return cb
end

local function BuildTetrisSettingsPanel(parent)
    local S = GamingHub.TET_Settings
    local T = GamingHub.TET_Themes
    if not S then return end
    if not T then return end

    local L = GamingHub.GetLocaleTable("TETRIS")

    local totalW  = parent:GetWidth() - (BOX_PAD * 3)
    if totalW <= 0 then totalW = 580 end
    local leftW   = math.floor(totalW * 0.60)
    local rightW  = totalW - leftW
    local topBoxH = 170
    local startY  = PAD

    -- ── BOX A: THEMA & VORSCHAU ──────────────────────────────
    local boxA, cA = CreateBox(parent, L["box_theme"], BOX_PAD, startY, leftW, topBoxH)

    local TYPES = {"I","O","T","L","J","S","Z"}
    local previewBg   = {}
    local previewIcon = {}

    local function BuildPreview(themeID)
        local theme = T:Get(themeID or S:Get("theme"))
        for _, pt in ipairs(TYPES) do
            local entry = theme[pt] or {r=0.5, g=0.5, b=0.5}
            local pbg  = previewBg[pt]
            local pico = previewIcon[pt]
            if pbg then
                pbg:SetBackdropColor(entry.r * 0.80, entry.g * 0.80, entry.b * 0.80, 1)
            end
            if pico then
                if entry.atlas then
                    local info = C_Texture and C_Texture.GetAtlasInfo
                        and C_Texture.GetAtlasInfo(entry.atlas)
                    if info and info.file then
                        pico:SetTexture(info.file)
                        pico:SetTexCoord(info.leftTexCoord, info.rightTexCoord,
                                         info.topTexCoord,  info.bottomTexCoord)
                        pico:SetVertexColor(1, 1, 1, 1)
                        pico:Show()
                    else
                        pico:Hide()
                    end
                elseif entry.icon then
                    pico:SetTexture(entry.icon)
                    pico:SetTexCoord(0, 1, 0, 1)
                    pico:SetVertexColor(1, 1, 1, 1)
                    pico:Show()
                else
                    pico:Hide()
                end
            end
        end
    end

    -- Dropdown
    local dd = CreateFrame("Button", "TET_ThemeDrop", cA, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", cA, "TOPLEFT", -10, 0)
    UIDropDownMenu_SetWidth(dd, leftW - 50)

    local function getCurLabel()
        local cur = S:Get("theme") or "CLASSIC"
        for _, e in ipairs(T.LIST) do
            if e.id == cur then return e.label end
        end
        return "Klassisch"
    end
    UIDropDownMenu_SetText(dd, getCurLabel())
    UIDropDownMenu_Initialize(dd, function(_, level)
        for _, e in ipairs(T.LIST) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = e.label
            info.value   = e.id
            info.checked = (S:Get("theme") == e.id)
            info.func    = function()
                S:Set("theme", e.id)
                UIDropDownMenu_SetSelectedValue(dd, e.id)
                UIDropDownMenu_SetText(dd, e.label)
                BuildPreview(e.id)
                local R = GamingHub.TET_Renderer
                if R and R.RefreshTheme then R:RefreshTheme() end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Vorschau-Felder (7 Block-Typen)
    for i, ptype in ipairs(TYPES) do
        local f = CreateFrame("Frame", nil, cA, "BackdropTemplate")
        f:SetSize(28, 28)
        f:SetPoint("TOPLEFT", cA, "TOPLEFT", (i-1)*34, -38)
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", tile=false})
        f:SetBackdropColor(0.5, 0.5, 0.5, 1)
        previewBg[ptype] = f

        local ico = f:CreateTexture(nil, "ARTWORK")
        ico:SetAllPoints(f)
        ico:Hide()
        previewIcon[ptype] = ico

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("CENTER")
        lbl:SetText(ptype)
        lbl:SetTextColor(0, 0, 0, 1)
    end

    local hint = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", cA, "TOPLEFT", 0, -74)
    hint:SetText(L["hint_blocks"])

    BuildPreview(S:Get("theme"))

    -- ── BOX B: SOUND ─────────────────────────────────────────
    local boxB, cB = CreateBox(parent, L["box_sounds"],
        BOX_PAD + leftW + BOX_PAD, startY, rightW, topBoxH)

    local cbSound = CreateCheckbox(cB, L["sound_enabled"], 0, 0)
    cbSound:SetChecked(S:Get("sound") ~= false)
    cbSound:SetScript("OnClick", function(self)
        S:Set("sound", self:GetChecked())
    end)

    local sndInfo = cB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sndInfo:SetPoint("TOPLEFT", cB, "TOPLEFT", 2, -32)
    sndInfo:SetJustifyH("LEFT")
    sndInfo:SetText(L["sound_info"])

    -- ── BOX C: SPIELANLEITUNG ────────────────────────────────
    local fullW  = leftW + rightW + BOX_PAD
    local guideH = 195
    local boxC, cC = CreateBox(parent, L["box_guide"],
        BOX_PAD, startY + topBoxH + BOX_PAD, fullW, guideH)

    local GUIDE = {
        L["guide_controls"],
        L["guide_keys"],
        L["guide_drop"],
        L["guide_empty"],
        L["guide_scoring"],
        L["guide_score1"],
        L["guide_score2"],
        L["guide_mult"],
        L["guide_empty2"],
        L["guide_levelup"],
        L["guide_highscore"],
        L["guide_sizes"],
    }

    local prev = nil
    for _, line in ipairs(GUIDE) do
        local fs = cC:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if prev then
            fs:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -2)
        else
            fs:SetPoint("TOPLEFT", cC, "TOPLEFT", 0, 0)
        end
        fs:SetText(line)
        fs:SetTextColor(0.85, 0.80, 0.65)
        fs:SetJustifyH("LEFT")
        fs:SetPoint("RIGHT", cC, "RIGHT", 0, 0)
        prev = fs
    end
end

GamingHub.SettingsPanel = GamingHub.SettingsPanel or {}
GamingHub.SettingsPanel._builders = GamingHub.SettingsPanel._builders or {}
GamingHub.SettingsPanel._builders["TETRIS"] = BuildTetrisSettingsPanel
