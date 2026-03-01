--[[
    Gaming Hub
    UI/VierGewinnt_SettingsPanel.lua
    Version: 1.1.0 (Multilanguage via Language.lua)

    Alle sichtbaren Strings kommen aus GamingHub.GetLocaleTable("CONNECT4").
]]

local PAD        = 10
local BOX_PAD    = 8
local BOX_H_ROW1 = 210
local BOX_H_ROW2 = 130

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

local function CreateDropdown(parent, labelText, x, y, width, items, onSelect)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    lbl:SetText(labelText)
    lbl:SetTextColor(0.80, 0.75, 0.60)

    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, -(y + 16))
    UIDropDownMenu_SetWidth(dd, width)

    UIDropDownMenu_Initialize(dd, function(self, level)
        for _, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = item.label
            info.value   = item.value
            info.func    = function(btn)
                UIDropDownMenu_SetSelectedValue(dd, btn.value)
                onSelect(btn.value)
            end
            info.checked = false
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    return dd, lbl
end

-- ============================================================
-- PANEL-BUILDER
-- ============================================================

local function BuildVierGewinntSettingsPanel(parent)

    local S = GamingHub.VierGewinntSettings
    if not S then return end
    local settings = S:GetAll()

    local L = GamingHub.GetLocaleTable("CONNECT4")

    local totalW = parent:GetWidth() - (BOX_PAD * 3)
    if totalW <= 0 then totalW = 580 end
    local halfW  = math.floor(totalW / 2)
    local fullW  = totalW
    local startY = PAD

    -- ── BOX A: SYMBOLE ──────────────────────────────────────
    local boxA, cA = CreateBox(parent, L["box_symbols"], BOX_PAD, startY, halfW, BOX_H_ROW1)

    local cbSymAuto = CreateCheckbox(cA, L["sym_auto"], 0, 0)
    cbSymAuto:SetChecked(settings.symbolAutoDetect)

    local ddSymPlayer, ddSymMode

    ddSymPlayer = CreateDropdown(cA,
        L["sym_player_label"],
        0, 90,
        halfW - 60,
        {
            { label = L["sym_alliance"], value = "ALLIANCE" },
            { label = L["sym_horde"],   value = "HORDE"    },
        },
        function(value) S:Set("player1Symbol", value) end
    )
    UIDropDownMenu_SetSelectedValue(ddSymPlayer,
        (settings.player1Symbol ~= "" and settings.player1Symbol) or "ALLIANCE")

    ddSymMode = CreateDropdown(cA,
        L["sym_set_label"],
        0, 32,
        halfW - 60,
        {
            { label = L["sym_standard"], value = "STANDARD" },
            { label = L["sym_faction"],  value = "FACTION"  },
        },
        function(value)
            S:Set("symbolMode", value)
            local isFaction = (value == "FACTION")
            ddSymPlayer:SetAlpha(isFaction and 1 or 0.4)
            if isFaction then UIDropDownMenu_EnableDropDown(ddSymPlayer)
            else              UIDropDownMenu_DisableDropDown(ddSymPlayer) end
        end
    )
    UIDropDownMenu_SetSelectedValue(ddSymMode, settings.symbolMode)

    if settings.symbolAutoDetect then
        ddSymMode:SetAlpha(0.4);   UIDropDownMenu_DisableDropDown(ddSymMode)
        ddSymPlayer:SetAlpha(0.4); UIDropDownMenu_DisableDropDown(ddSymPlayer)
    elseif settings.symbolMode ~= "FACTION" then
        ddSymPlayer:SetAlpha(0.4); UIDropDownMenu_DisableDropDown(ddSymPlayer)
    end

    cbSymAuto:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        S:Set("symbolAutoDetect", checked)
        if checked then UIDropDownMenu_SetSelectedValue(ddSymMode, "FACTION") end
        local enabled = not checked
        ddSymMode:SetAlpha(enabled and 1 or 0.4)
        ddSymPlayer:SetAlpha(enabled and 1 or 0.4)
        if enabled then
            UIDropDownMenu_EnableDropDown(ddSymMode)
            UIDropDownMenu_EnableDropDown(ddSymPlayer)
        else
            UIDropDownMenu_DisableDropDown(ddSymMode)
            UIDropDownMenu_DisableDropDown(ddSymPlayer)
        end
    end)

    local hintA = cA:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintA:SetPoint("BOTTOMLEFT",  cA, "BOTTOMLEFT",  0, 4)
    hintA:SetPoint("BOTTOMRIGHT", cA, "BOTTOMRIGHT", 0, 4)
    hintA:SetText(L["sym_hint"])
    hintA:SetJustifyH("LEFT")

    -- ── BOX B: HINTERGRUND ───────────────────────────────────
    local boxB, cB = CreateBox(parent, L["box_background"],
        BOX_PAD + halfW + BOX_PAD, startY, halfW, BOX_H_ROW1)

    local bgFactionRow = CreateFrame("Frame", nil, cB)
    bgFactionRow:SetPoint("TOPLEFT",  cB, "TOPLEFT",  0, -58)
    bgFactionRow:SetPoint("TOPRIGHT", cB, "TOPRIGHT", 0, -58)
    bgFactionRow:SetHeight(80)

    local bgClassRow = CreateFrame("Frame", nil, cB)
    bgClassRow:SetPoint("TOPLEFT",  cB, "TOPLEFT",  0, -58)
    bgClassRow:SetPoint("TOPRIGHT", cB, "TOPRIGHT", 0, -58)
    bgClassRow:SetHeight(80)

    local bgRaceRow = CreateFrame("Frame", nil, cB)
    bgRaceRow:SetPoint("TOPLEFT",  cB, "TOPLEFT",  0, -58)
    bgRaceRow:SetPoint("TOPRIGHT", cB, "TOPRIGHT", 0, -58)
    bgRaceRow:SetHeight(80)

    local ddBgMode = CreateDropdown(cB,
        L["bg_type_label"],
        0, 0,
        halfW - 60,
        {
            { label = L["bg_neutral"], value = "NEUTRAL" },
            { label = L["bg_faction"], value = "FACTION" },
            { label = L["bg_class"],   value = "CLASS"   },
            { label = L["bg_race"],    value = "RACE"    },
        },
        function(value)
            S:Set("backgroundMode", value)
            bgFactionRow:SetShown(value == "FACTION")
            bgClassRow:SetShown(value  == "CLASS")
            bgRaceRow:SetShown(value   == "RACE")
        end
    )
    UIDropDownMenu_SetSelectedValue(ddBgMode, settings.backgroundMode)

    -- Sub-Zeile: Fraktion
    local cbBgFactionAuto = CreateCheckbox(bgFactionRow, L["bg_auto"], 0, 0)
    cbBgFactionAuto:SetChecked(settings.backgroundFactionAuto)

    local ddBgFaction = CreateDropdown(bgFactionRow,
        L["bg_faction_label"],
        0, 28, halfW - 60,
        {
            { label = L["sym_alliance"], value = "ALLIANCE" },
            { label = L["sym_horde"],   value = "HORDE"    },
        },
        function(value) S:Set("backgroundFaction", value) end
    )
    UIDropDownMenu_SetSelectedValue(ddBgFaction,
        (settings.backgroundFaction ~= "" and settings.backgroundFaction) or "ALLIANCE")
    if settings.backgroundFactionAuto then
        ddBgFaction:SetAlpha(0.4); UIDropDownMenu_DisableDropDown(ddBgFaction)
    end
    cbBgFactionAuto:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        S:Set("backgroundFactionAuto", checked)
        if checked then ddBgFaction:SetAlpha(0.4); UIDropDownMenu_DisableDropDown(ddBgFaction)
        else            ddBgFaction:SetAlpha(1);   UIDropDownMenu_EnableDropDown(ddBgFaction) end
    end)

    -- Sub-Zeile: Klasse
    local cbBgClassAuto = CreateCheckbox(bgClassRow, L["bg_auto"], 0, 0)
    cbBgClassAuto:SetChecked(settings.backgroundClassAuto)

    local ddBgClass = CreateDropdown(bgClassRow,
        L["bg_class_label"],
        0, 28, halfW - 60,
        {
            { label = L["class_warrior"], value = "WARRIOR"     },
            { label = L["class_paladin"], value = "PALADIN"     },
            { label = L["class_hunter"],  value = "HUNTER"      },
            { label = L["class_rogue"],   value = "ROGUE"       },
            { label = L["class_priest"],  value = "PRIEST"      },
            { label = L["class_shaman"],  value = "SHAMAN"      },
            { label = L["class_mage"],    value = "MAGE"        },
            { label = L["class_warlock"], value = "WARLOCK"     },
            { label = L["class_monk"],    value = "MONK"        },
            { label = L["class_druid"],   value = "DRUID"       },
            { label = L["class_dh"],      value = "DEMONHUNTER" },
            { label = L["class_dk"],      value = "DEATHKNIGHT" },
            { label = L["class_evoker"],  value = "EVOKER"      },
        },
        function(value) S:Set("backgroundClass", value) end
    )
    local currentClass = (settings.backgroundClass ~= "" and settings.backgroundClass)
        or select(2, UnitClass("player")) or "WARRIOR"
    UIDropDownMenu_SetSelectedValue(ddBgClass, currentClass)
    if settings.backgroundClassAuto then
        ddBgClass:SetAlpha(0.4); UIDropDownMenu_DisableDropDown(ddBgClass)
    end
    cbBgClassAuto:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        S:Set("backgroundClassAuto", checked)
        if checked then ddBgClass:SetAlpha(0.4); UIDropDownMenu_DisableDropDown(ddBgClass)
        else            ddBgClass:SetAlpha(1);   UIDropDownMenu_EnableDropDown(ddBgClass) end
    end)

    -- Sub-Zeile: Rasse
    local cbBgRaceAuto = CreateCheckbox(bgRaceRow, L["bg_auto"], 0, 0)
    cbBgRaceAuto:SetChecked(settings.backgroundRaceAuto)

    local ddBgRace = CreateDropdown(bgRaceRow,
        L["bg_race_label"],
        0, 28, halfW - 60,
        {
            { label = L["race_human"],      value = "HUMAN"      },
            { label = L["race_dwarf"],      value = "DWARF"      },
            { label = L["race_nightelf"],   value = "NIGHTELF"   },
            { label = L["race_gnome"],      value = "GNOME"      },
            { label = L["race_draenei"],    value = "DRAENEI"    },
            { label = L["race_worgen"],     value = "WORGEN"     },
            { label = L["race_pandaren_a"], value = "PANDAREN_A" },
            { label = L["race_orc"],        value = "ORC"        },
            { label = L["race_undead"],     value = "UNDEAD"     },
            { label = L["race_tauren"],     value = "TAUREN"     },
            { label = L["race_troll"],      value = "TROLL"      },
            { label = L["race_bloodelf"],   value = "BLOODELF"   },
            { label = L["race_goblin"],     value = "GOBLIN"     },
            { label = L["race_pandaren_h"], value = "PANDAREN_H" },
            { label = L["race_dracthyr"],   value = "DRACTHYR"   },
        },
        function(value) S:Set("backgroundRace", value) end
    )
    local currentRace = (settings.backgroundRace ~= "" and settings.backgroundRace)
        or UnitRace("player") or "HUMAN"
    UIDropDownMenu_SetSelectedValue(ddBgRace, currentRace)
    if settings.backgroundRaceAuto then
        ddBgRace:SetAlpha(0.4); UIDropDownMenu_DisableDropDown(ddBgRace)
    end
    cbBgRaceAuto:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        S:Set("backgroundRaceAuto", checked)
        if checked then ddBgRace:SetAlpha(0.4); UIDropDownMenu_DisableDropDown(ddBgRace)
        else            ddBgRace:SetAlpha(1);   UIDropDownMenu_EnableDropDown(ddBgRace) end
    end)

    bgFactionRow:SetShown(settings.backgroundMode == "FACTION")
    bgClassRow:SetShown(settings.backgroundMode   == "CLASS")
    bgRaceRow:SetShown(settings.backgroundMode    == "RACE")

    -- ── BOX C: SOUNDS (volle Breite) ────────────────────────
    local row2Y  = startY + BOX_H_ROW1 + BOX_PAD
    local boxC, cC = CreateBox(parent, L["box_sounds"], BOX_PAD, row2Y, fullW, BOX_H_ROW2)

    local cbSoundMain = CreateCheckbox(cC, L["sound_enabled"], 0, 0)
    cbSoundMain:SetChecked(settings.soundEnabled)

    local cbWin  = CreateCheckbox(cC, L["sound_win"],  0,   30)
    local cbLoss = CreateCheckbox(cC, L["sound_loss"], 130, 30)
    local cbDraw = CreateCheckbox(cC, L["sound_draw"], 270, 30)

    cbWin:SetChecked(settings.soundOnWin)
    cbLoss:SetChecked(settings.soundOnLoss)
    cbDraw:SetChecked(settings.soundOnDraw)

    local function RefreshSoundSubState(enabled)
        local alpha = enabled and 1 or 0.4
        cbWin:SetAlpha(alpha);  cbWin:SetEnabled(enabled)
        cbLoss:SetAlpha(alpha); cbLoss:SetEnabled(enabled)
        cbDraw:SetAlpha(alpha); cbDraw:SetEnabled(enabled)
    end
    RefreshSoundSubState(settings.soundEnabled)

    cbSoundMain:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        S:Set("soundEnabled", checked)
        if not checked then
            cbWin:SetChecked(false); cbLoss:SetChecked(false); cbDraw:SetChecked(false)
        end
        RefreshSoundSubState(checked)
    end)
    cbWin:SetScript("OnClick",  function(self) S:Set("soundOnWin",  self:GetChecked()); if self:GetChecked() then cbSoundMain:SetChecked(true) end end)
    cbLoss:SetScript("OnClick", function(self) S:Set("soundOnLoss", self:GetChecked()); if self:GetChecked() then cbSoundMain:SetChecked(true) end end)
    cbDraw:SetScript("OnClick", function(self) S:Set("soundOnDraw", self:GetChecked()); if self:GetChecked() then cbSoundMain:SetChecked(true) end end)

    local hintC = cC:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintC:SetPoint("BOTTOMLEFT",  cC, "BOTTOMLEFT",  0, 4)
    hintC:SetPoint("BOTTOMRIGHT", cC, "BOTTOMRIGHT", 0, 4)
    hintC:SetText(L["sound_hint"])
    hintC:SetJustifyH("LEFT")

    -- ── RESET-BUTTON ─────────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetBtn:SetSize(180, 26)
    resetBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -BOX_PAD, BOX_PAD)
    resetBtn:SetText(L["btn_reset"])
    resetBtn:SetScript("OnClick", function()
        S:Reset()
        parent:Hide()
        for _, child in ipairs({ parent:GetChildren() }) do child:Hide() end
        BuildVierGewinntSettingsPanel(parent)
        parent:Show()
    end)

    -- ── RESPONSIVE ───────────────────────────────────────────
    parent:SetScript("OnSizeChanged", function(self, w, _)
        local avail = w - (BOX_PAD * 3)
        local hw    = math.floor(avail / 2)
        boxA:SetWidth(hw)
        boxB:SetWidth(hw)
        boxB:ClearAllPoints()
        boxB:SetPoint("TOPLEFT", parent, "TOPLEFT", BOX_PAD + hw + BOX_PAD, -startY)
        boxC:SetWidth(avail)
    end)
end

-- ============================================================
-- REGISTRIERUNG
-- ============================================================

GamingHub.SettingsPanel = GamingHub.SettingsPanel or {}

if GamingHub.SettingsPanel.RegisterBuilder then
    GamingHub.SettingsPanel.RegisterBuilder("CONNECT4", BuildVierGewinntSettingsPanel)
else
    GamingHub.SettingsPanel._builders = GamingHub.SettingsPanel._builders or {}
    GamingHub.SettingsPanel._builders["CONNECT4"] = BuildVierGewinntSettingsPanel
end
