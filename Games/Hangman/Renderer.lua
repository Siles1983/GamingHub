-- Hangman Renderer.lua
-- Dark Portal / Runenkreis Theme

GamingHub = GamingHub or {}
GamingHub.HGM_Renderer = {}
local R = GamingHub.HGM_Renderer

local Engine   = GamingHub.HGM_Engine
local Settings = GamingHub.HGM_Settings

local RUNE_ICONS = {
    "Interface\\Icons\\INV_Misc_Rune_01",
    "Interface\\Icons\\INV_Misc_Rune_02",
    "Interface\\Icons\\INV_Misc_Rune_03",
    "Interface\\Icons\\INV_Misc_Rune_04",
    "Interface\\Icons\\INV_Misc_Rune_05",
    "Interface\\Icons\\INV_Misc_Rune_06",
    "Interface\\Icons\\INV_Misc_Rune_07",
    "Interface\\Icons\\INV_Misc_Rune_08",
    "Interface\\Icons\\Spell_Shadow_RaiseDead",
    "Interface\\Icons\\Spell_Deathknight_ClassSymbol",
}

local RUNE_COLOR_START = {r=0.3, g=0.0, b=0.5}
local RUNE_COLOR_END   = {r=1.0, g=0.1, b=0.0}

local KEYBOARD_ROWS = {
    {"Q","W","E","R","T","Y","U","I","O","P"},
    {"A","S","D","F","G","H","J","K","L"},
    {"Z","X","C","V","B","N","M"},
}
local BTN_SIZE = 28
local BTN_GAP  = 3

-- ============================================================
-- Init
-- ============================================================
function R:Init()
    if self._initialized then return end
    self._initialized = true

    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end

    local f = CreateFrame("Frame", "GamingHub_HGM_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    if _G.GamingHub then _G.GamingHub._hangmanContainer = f end

    local parent = f
    local W = parent:GetWidth()
    if not W or W < 10 then W = 700 end
    local H = parent:GetHeight()
    if not H or H < 10 then H = 540 end

    -- --------------------------------------------------------
    -- LINKE HÄLFTE: Runenkreis (vollständig zentriert)
    -- --------------------------------------------------------
    local leftW = math.floor(W * 0.42)

    local leftPanel = CreateFrame("Frame", nil, parent)
    leftPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    leftPanel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 40)
    leftPanel:SetWidth(leftW)
    self._leftPanel = leftPanel

    -- Titel (zentriert)
    local portalTitle = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    portalTitle:SetPoint("TOP", leftPanel, "TOP", 0, -12)
    portalTitle:SetText(GamingHub.GetLocaleTable("HANGMAN")["portal_title"])
    portalTitle:SetFont("Fonts\\MORPHEUS.TTF", 15, "OUTLINE")
    portalTitle:SetJustifyH("CENTER")
    self._portalTitle = portalTitle

    -- Fehler-Label (zentriert unter Titel)
    local errorLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    errorLabel:SetPoint("TOP", portalTitle, "BOTTOM", 0, -5)
    errorLabel:SetText("Beschwörungsfehler: 0 / 6")
    errorLabel:SetTextColor(0.8, 0.6, 0.2)
    errorLabel:SetJustifyH("CENTER")
    self._errorLabel = errorLabel

    -- Runenkreis (zentriert in leftPanel, unterhalb Titel/Fehler)
    local circleR = math.min(leftW * 0.9, (H - 120) * 0.5) * 0.40
    self._runeFrames = {}
    for i = 1, 10 do
        local angle = ((i - 1) / 10) * (2 * math.pi) - math.pi / 2
        local px    = math.floor(math.cos(angle) * circleR)
        local py    = math.floor(math.sin(angle) * circleR)

        local runeFrame = CreateFrame("Frame", nil, leftPanel, "BackdropTemplate")
        runeFrame:SetSize(44, 44)
        runeFrame:SetPoint("CENTER", leftPanel, "CENTER", px, py - 15)
        runeFrame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = { left=1, right=1, top=1, bottom=1 },
        })
        runeFrame:SetBackdropColor(0.05, 0.0, 0.1, 0.9)
        runeFrame:SetBackdropBorderColor(0.3, 0.0, 0.5, 0.6)

        -- Nur die Icon-Textur, KEIN zusätzliches Layer
        local runeTex = runeFrame:CreateTexture(nil, "ARTWORK")
        runeTex:SetPoint("TOPLEFT",     runeFrame, "TOPLEFT",     2, -2)
        runeTex:SetPoint("BOTTOMRIGHT", runeFrame, "BOTTOMRIGHT", -2,  2)
        runeTex:SetTexture(RUNE_ICONS[i] or RUNE_ICONS[1])
        runeTex:SetAlpha(0.0)
        runeFrame._tex = runeTex

        runeFrame:Hide()
        self._runeFrames[i] = runeFrame
    end

    -- Portal-Kern (zentriert)
    local coreFrame = CreateFrame("Frame", nil, leftPanel, "BackdropTemplate")
    coreFrame:SetSize(56, 56)
    coreFrame:SetPoint("CENTER", leftPanel, "CENTER", 0, -15)
    coreFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 2,
        insets = { left=2, right=2, top=2, bottom=2 },
    })
    coreFrame:SetBackdropColor(0.1, 0.0, 0.2, 0.95)
    coreFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8)

    -- EINE Textur für den Kern, kein zweites Layer
    local coreTex = coreFrame:CreateTexture(nil, "ARTWORK")
    coreTex:SetPoint("TOPLEFT",     coreFrame, "TOPLEFT",     3, -3)
    coreTex:SetPoint("BOTTOMRIGHT", coreFrame, "BOTTOMRIGHT", -3,  3)
    coreTex:SetTexture("Interface\\Icons\\Spell_Shadow_SummonVoidWalker")
    coreTex:SetAlpha(0.7)
    self._coreFrame = coreFrame
    self._coreTex   = coreTex

    -- Victory-Overlay (separat, nur bei Gewinn eingeblendet)
    local victoryTex = coreFrame:CreateTexture(nil, "OVERLAY")
    victoryTex:SetAllPoints(coreTex)
    victoryTex:SetTexture("Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend")
    victoryTex:SetAlpha(0.0)
    self._victoryTex = victoryTex

    -- --------------------------------------------------------
    -- RECHTE HÄLFTE: Kategorie/Schwierigkeit, Wort, Hinweis,
    --                Fehlversuche, Tastatur
    -- --------------------------------------------------------
    local rightX = leftW
    local rightW = W - rightX - 10
    local rightPanel = CreateFrame("Frame", nil, parent)
    rightPanel:SetPoint("TOPLEFT",    parent, "TOPLEFT",    rightX, 0)
    rightPanel:SetPoint("BOTTOMRIGHT",parent, "BOTTOMRIGHT", 0, 40)
    self._rightPanel = rightPanel

    -- ── Dropdowns (vor Spielbeginn sichtbar) ──
    local dropContainer = CreateFrame("Frame", nil, rightPanel)
    dropContainer:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", 0, 0)
    dropContainer:SetSize(rightW, 60)
    self._dropContainer = dropContainer

    -- Kategorie-Dropdown
    local catLabel = dropContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    catLabel:SetPoint("BOTTOMLEFT", dropContainer, "BOTTOMLEFT", 14, 38)
    catLabel:SetText(GamingHub.GetLocaleTable("HANGMAN")["label_category"])
    catLabel:SetTextColor(0.8, 0.7, 1.0)

    local catDD = CreateFrame("Frame", "HGM_CatDD_Game", dropContainer, "UIDropDownMenuTemplate")
    catDD:SetPoint("BOTTOMLEFT", dropContainer, "BOTTOMLEFT", 0, 10)
    UIDropDownMenu_SetWidth(catDD, 140)

    local function UpdateCategory(catID, catLabel)
        Settings:Set("category", catID)
        UIDropDownMenu_SetSelectedValue(catDD, catID)
        UIDropDownMenu_SetText(catDD, catLabel)
    end
    UIDropDownMenu_Initialize(catDD, function(self2, level)
        local cats = GamingHub.HGM_Logic:GetCategories()
        for _, cat in ipairs(cats) do
            local info = UIDropDownMenu_CreateInfo()
            info.text  = cat.label; info.value = cat.id
            info.func  = function() UpdateCategory(cat.id, cat.label) end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    local savedCatID = Settings:Get("category")
    UIDropDownMenu_SetSelectedValue(catDD, savedCatID)
    -- Label fuer gespeicherte catID nachschlagen
    local savedCatLabel = savedCatID
    local _cats = GamingHub.HGM_Logic:GetCategories()
    for _, c in ipairs(_cats) do
        if c.id == savedCatID then savedCatLabel = c.label; break end
    end
    UIDropDownMenu_SetText(catDD, savedCatLabel)
    self._catDD = catDD

    -- Schwierigkeit-Dropdown
    local _L = GamingHub.GetLocaleTable("HANGMAN")
    local DIFFICULTIES = {
        { key="Easy",   label=_L["diff_easy"]   },
        { key="Normal", label=_L["diff_normal"]  },
        { key="Hard",   label=_L["diff_hard"]    },
    }
    local diffLabel = dropContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    diffLabel:SetPoint("BOTTOMLEFT", dropContainer, "BOTTOMLEFT", 170, 38)
    diffLabel:SetText(GamingHub.GetLocaleTable("HANGMAN")["label_diff"])
    diffLabel:SetTextColor(0.8, 0.7, 1.0)

    local diffDD = CreateFrame("Frame", "HGM_DiffDD_Game", dropContainer, "UIDropDownMenuTemplate")
    diffDD:SetPoint("BOTTOMLEFT", dropContainer, "BOTTOMLEFT", 158, 10)
    UIDropDownMenu_SetWidth(diffDD, 130)

    local function UpdateDiff(key, lbl)
        Settings:Set("difficulty", key)
        UIDropDownMenu_SetSelectedValue(diffDD, key)
        UIDropDownMenu_SetText(diffDD, lbl)
    end
    UIDropDownMenu_Initialize(diffDD, function(self2, level)
        for _, d in ipairs(DIFFICULTIES) do
            local info = UIDropDownMenu_CreateInfo()
            info.text  = d.label; info.value = d.key
            info.func  = function() UpdateDiff(d.key, d.label) end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    local savedDiff = Settings:Get("difficulty")
    local savedDiffLabel = "Normal (6)"
    for _, d in ipairs(DIFFICULTIES) do
        if d.key == savedDiff then savedDiffLabel = d.label; break end
    end
    UIDropDownMenu_SetSelectedValue(diffDD, savedDiff)
    UIDropDownMenu_SetText(diffDD, savedDiffLabel)
    self._diffDD = diffDD

    -- ── Spielbereich (bei Spielbeginn sichtbar) ──
    local gameArea = CreateFrame("Frame", nil, rightPanel)
    gameArea:SetPoint("TOPLEFT",    rightPanel, "TOPLEFT",    0,  0)
    gameArea:SetPoint("BOTTOMRIGHT",rightPanel, "BOTTOMRIGHT",0, 60)
    gameArea:Hide()  -- erst bei Spielbeginn sichtbar
    self._gameArea = gameArea

    -- Kategorie-Anzeige im Spielfeld
    local catDisplay = gameArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    catDisplay:SetPoint("TOPLEFT", gameArea, "TOPLEFT", 0, -12)
    catDisplay:SetTextColor(0.6, 0.8, 1.0)
    catDisplay:SetText("Kategorie: –")
    self._catDisplay = catDisplay

    -- Wort-Display (zentriert)
    local wordDisplay = gameArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    wordDisplay:SetPoint("TOP", catDisplay, "BOTTOM", 0, -8)
    wordDisplay:SetWidth(rightW - 10)
    wordDisplay:SetFont("Fonts\\MORPHEUS.TTF", 22, "OUTLINE")
    wordDisplay:SetTextColor(0.95, 0.85, 0.4)
    wordDisplay:SetText("")
    wordDisplay:SetJustifyH("CENTER")
    self._wordDisplay = wordDisplay

    -- Trennlinie
    local sep = gameArea:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  wordDisplay, "BOTTOMLEFT",  0, -8)
    sep:SetPoint("TOPRIGHT", wordDisplay, "BOTTOMRIGHT", 0, -8)
    sep:SetTexture("Interface\\Buttons\\WHITE8X8")
    sep:SetVertexColor(0.4, 0.2, 0.7, 0.6)

    -- Hinweis-Box
    local hintBox = CreateFrame("Frame", nil, gameArea, "BackdropTemplate")
    hintBox:SetPoint("TOPLEFT",  sep, "BOTTOMLEFT",  0, -8)
    hintBox:SetPoint("TOPRIGHT", sep, "BOTTOMRIGHT", 0, -8)
    hintBox:SetHeight(52)
    hintBox:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left=1, right=1, top=1, bottom=1 },
    })
    hintBox:SetBackdropColor(0.08, 0.04, 0.15, 0.9)
    hintBox:SetBackdropBorderColor(0.5, 0.3, 0.8, 0.5)

    local hintIcon = hintBox:CreateTexture(nil, "ARTWORK")
    hintIcon:SetSize(24, 24)
    hintIcon:SetPoint("TOPLEFT", hintBox, "TOPLEFT", 6, -6)
    hintIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_02")

    local hintTitle = hintBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintTitle:SetPoint("TOPLEFT", hintBox, "TOPLEFT", 36, -8)
    hintTitle:SetText(GamingHub.GetLocaleTable("HANGMAN")["hint_label"])

    local hintText = hintBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintText:SetPoint("TOPLEFT",  hintTitle, "BOTTOMLEFT", 0, -2)
    hintText:SetPoint("TOPRIGHT", hintBox,   "TOPRIGHT",  -6, -8)
    hintText:SetJustifyH("LEFT")
    hintText:SetWordWrap(true)
    hintText:SetTextColor(0.85, 0.75, 0.95)
    self._hintText = hintText

    -- ── Tastatur (zentriert in rightW) ──
    local kbTotalH = #KEYBOARD_ROWS * (BTN_SIZE + BTN_GAP)
    local kbAnchor = CreateFrame("Frame", nil, gameArea)
    kbAnchor:SetPoint("BOTTOM", gameArea, "BOTTOM", 0, 4)
    kbAnchor:SetSize(rightW, kbTotalH + 4)
    self._kbAnchor = kbAnchor

    self._letterBtns = {}
    for row = 1, #KEYBOARD_ROWS do
        local letters  = KEYBOARD_ROWS[row]
        local rowWidth = #letters * BTN_SIZE + (#letters - 1) * BTN_GAP
        local startX   = math.floor((rightW - rowWidth) / 2)
        for col = 1, #letters do
            local letter = letters[col]
            local bx = startX + (col - 1) * (BTN_SIZE + BTN_GAP)
            local by = -(row - 1) * (BTN_SIZE + BTN_GAP)

            local btn = CreateFrame("Button", nil, kbAnchor, "BackdropTemplate")
            btn:SetSize(BTN_SIZE, BTN_SIZE)
            btn:SetPoint("TOPLEFT", kbAnchor, "TOPLEFT", bx, by)
            btn:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false, edgeSize = 1,
                insets = { left=1, right=1, top=1, bottom=1 },
            })
            btn:SetBackdropColor(0.12, 0.06, 0.22, 0.95)
            btn:SetBackdropBorderColor(0.5, 0.3, 0.8, 0.7)

            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetAllPoints()
            lbl:SetText(letter)
            lbl:SetTextColor(0.9, 0.8, 1.0)
            btn._label = lbl

            local cap = letter
            btn:SetScript("OnClick", function() Engine:GuessLetter(cap) end)
            btn:SetScript("OnEnter", function(s) if not s._used then s:SetBackdropBorderColor(0.8, 0.5, 1.0, 1.0) end end)
            btn:SetScript("OnLeave", function(s) if not s._used then s:SetBackdropBorderColor(0.5, 0.3, 0.8, 0.7) end end)
            self._letterBtns[letter] = btn
        end
    end

    -- Fehlversuche (zentriert über Tastatur)
    local wrongHeader = gameArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    wrongHeader:SetPoint("BOTTOM", kbAnchor, "TOP", 0, 6)
    wrongHeader:SetWidth(rightW)
    wrongHeader:SetJustifyH("CENTER")
    wrongHeader:SetText("")
    self._wrongHeader = wrongHeader

    local wrongText = gameArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    wrongText:SetPoint("BOTTOM", wrongHeader, "TOP", 0, 2)
    wrongText:SetWidth(rightW)
    wrongText:SetJustifyH("CENTER")
    wrongText:SetTextColor(1.0, 0.3, 0.3)
    wrongText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    wrongText:SetText("")
    self._wrongText = wrongText

    -- ── Keyboard-Input Frame ──
    local keyFrame = CreateFrame("Frame", nil, parent)
    keyFrame:SetAllPoints(parent)
    keyFrame:EnableKeyboard(false)
    keyFrame:SetPropagateKeyboardInput(false)
    keyFrame:SetScript("OnKeyDown", function(_, key)
        if #key == 1 then
            local upper = string.upper(key)
            if upper:match("[A-Z]") then Engine:GuessLetter(upper) end
        end
    end)
    self._keyFrame = keyFrame

    -- ── Bottom Buttons ──
    local exitBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    exitBtn:SetSize(100, 28)
    exitBtn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 8, 8)
    exitBtn:SetText(GamingHub.GetLocaleTable("HANGMAN")["btn_exit"])
    exitBtn:SetScript("OnClick", function()
        R._goPanel:Hide()
        Engine:StopGame()
    end)
    exitBtn:Hide()
    self._exitBtn = exitBtn

    local startBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    startBtn:SetSize(140, 28)
    startBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
    startBtn:SetText(GamingHub.GetLocaleTable("HANGMAN")["btn_new_puzzle"])
    startBtn:SetScript("OnClick", function() Engine:StartGame() end)
    self._startBtn = startBtn

    -- ── GameOver-Panel ──
    local goPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    goPanel:SetSize(360, 200)
    goPanel:SetPoint("CENTER", parent, "CENTER", 0, 0)
    goPanel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 16,
        insets = { left=4, right=4, top=4, bottom=4 },
    })
    goPanel:SetBackdropColor(0.05, 0.02, 0.12, 0.97)
    goPanel:SetBackdropBorderColor(0.7, 0.3, 1.0, 1.0)
    goPanel:SetFrameStrata("HIGH")
    goPanel:Hide()
    self._goPanel = goPanel

    local goTitle = goPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    goTitle:SetPoint("TOP", goPanel, "TOP", 0, -18)
    goTitle:SetFont("Fonts\\MORPHEUS.TTF", 20, "OUTLINE")
    self._goTitle = goTitle

    local goWord = goPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goWord:SetPoint("TOP", goTitle, "BOTTOM", 0, -10)
    goWord:SetTextColor(0.95, 0.85, 0.4)
    self._goWord = goWord

    local goStats = goPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    goStats:SetPoint("TOP", goWord, "BOTTOM", 0, -8)
    goStats:SetTextColor(0.7, 0.7, 0.7)
    self._goStats = goStats

    local goAgain = CreateFrame("Button", nil, goPanel, "UIPanelButtonTemplate")
    goAgain:SetSize(130, 28)
    goAgain:SetPoint("BOTTOM", goPanel, "BOTTOM", -75, 18)
    goAgain:SetText(GamingHub.GetLocaleTable("HANGMAN")["btn_retry"])
    goAgain:SetScript("OnClick", function() goPanel:Hide(); Engine:StartGame() end)

    local goMenu = CreateFrame("Button", nil, goPanel, "UIPanelButtonTemplate")
    goMenu:SetSize(130, 28)
    goMenu:SetPoint("BOTTOM", goPanel, "BOTTOM", 75, 18)
    goMenu:SetText(GamingHub.GetLocaleTable("HANGMAN")["btn_menu"])
    goMenu:SetScript("OnClick", function() goPanel:Hide(); Engine:StopGame() end)

    self:EnterIdleState()
end

-- ============================================================
-- Hilfsfunktionen
-- ============================================================
function R:_resetKeyboard()
    if not self._letterBtns then return end
    for _, btn in pairs(self._letterBtns) do
        btn._used = false
        btn:SetBackdropColor(0.12, 0.06, 0.22, 0.95)
        btn:SetBackdropBorderColor(0.5, 0.3, 0.8, 0.7)
        btn._label:SetTextColor(0.9, 0.8, 1.0)
        btn:Enable()
    end
end

function R:_resetRunes(maxSlots)
    if not self._runeFrames then return end
    maxSlots = maxSlots or 6
    for i = 1, 10 do
        local rf = self._runeFrames[i]
        if i <= maxSlots then
            rf:Show()
            rf._tex:SetAlpha(0.0)
            rf._tex:SetVertexColor(1, 1, 1)
            rf:SetBackdropBorderColor(0.3, 0.0, 0.5, 0.5)
            rf:SetBackdropColor(0.05, 0.0, 0.1, 0.9)
        else
            rf:Hide()
        end
    end
    if self._coreFrame then
        self._coreFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8)
        self._coreFrame:SetBackdropColor(0.1, 0.0, 0.2, 0.95)
    end
    if self._coreTex    then self._coreTex:SetAlpha(0.7) end
    if self._victoryTex then self._victoryTex:SetAlpha(0.0) end
end

-- ============================================================
-- Idle-State
-- ============================================================
function R:EnterIdleState()
    if self._keyFrame    then self._keyFrame:EnableKeyboard(false) end
    if self._goPanel     then self._goPanel:Hide() end
    if self._exitBtn     then self._exitBtn:Hide() end
    if self._gameArea    then self._gameArea:Hide() end
    if self._dropContainer then self._dropContainer:Show() end

    if self._errorLabel  then self._errorLabel:SetText(GamingHub.GetLocaleTable("HANGMAN")["error_idle"]) end
    self:_resetKeyboard()
    self:_resetRunes(Settings and Settings:GetMaxErrors() or 6)
end

-- ============================================================
-- Board rendern
-- ============================================================
function R:RenderBoard(board)
    if not board then return end
    if self._keyFrame    then self._keyFrame:EnableKeyboard(true) end
    if self._exitBtn     then self._exitBtn:Show() end
    if self._gameArea    then self._gameArea:Show() end
    if self._dropContainer then self._dropContainer:Hide() end

    if self._catDisplay then
        self._catDisplay:SetText(string.format(GamingHub.GetLocaleTable("HANGMAN")["cat_display"], board.category or "?"))
    end

    if self._wordDisplay then
        self._wordDisplay:SetText(GamingHub.HGM_Logic:GetDisplayWord(board))
    end

    if self._hintText then
        self._hintText:SetText(board.hint or "")
    end

    local maxErr = board.maxErrors
    local errors = board.errors
    if self._errorLabel then
        local col = errors == 0 and "|cff44ff44" or
                    (errors >= maxErr - 1 and "|cffff2222" or "|cffff8822")
        self._errorLabel:SetText(
            string.format(GamingHub.GetLocaleTable("HANGMAN")["error_label"], col, errors, maxErr))
    end

    -- Runen
    for i = 1, 10 do
        local rf = self._runeFrames[i]
        if i <= maxErr then
            rf:Show()
            if i <= errors then
                local t = errors > 1 and ((i-1)/(errors-1)) or 1
                local r2 = RUNE_COLOR_START.r + (RUNE_COLOR_END.r - RUNE_COLOR_START.r) * t
                local g2 = RUNE_COLOR_START.g + (RUNE_COLOR_END.g - RUNE_COLOR_START.g) * t
                local b2 = RUNE_COLOR_START.b + (RUNE_COLOR_END.b - RUNE_COLOR_START.b) * t
                rf._tex:SetAlpha(0.95)
                rf._tex:SetVertexColor(r2, g2, b2)
                rf:SetBackdropBorderColor(r2, g2, b2, 1.0)
                rf:SetBackdropColor(r2*0.2, g2*0.2, b2*0.2, 0.95)
            else
                rf._tex:SetAlpha(0.0)
                rf._tex:SetVertexColor(1, 1, 1)
                rf:SetBackdropBorderColor(0.3, 0.0, 0.5, 0.5)
                rf:SetBackdropColor(0.05, 0.0, 0.1, 0.9)
            end
        else
            rf:Hide()
        end
    end

    -- Portal-Kern
    if self._coreFrame then
        local danger = maxErr > 0 and (errors / maxErr) or 0
        self._coreFrame:SetBackdropBorderColor(0.4 + danger*0.6, 0.1, 1.0 - danger*0.7, 0.9)
        self._coreFrame:SetBackdropColor(0.1 + danger*0.4, 0.0, 0.3 - danger*0.25, 0.95)
    end

    -- Falsche Buchstaben
    if self._wrongText then
        local wrong = GamingHub.HGM_Logic:GetWrongLetters(board)
        if #wrong > 0 then
            if self._wrongHeader then self._wrongHeader:SetText(GamingHub.GetLocaleTable("HANGMAN")["wrong_header"]) end
            self._wrongText:SetText(table.concat(wrong, "  "))
        else
            if self._wrongHeader then self._wrongHeader:SetText("") end
            self._wrongText:SetText("")
        end
    end

    -- Buchstaben-Buttons
    if self._letterBtns then
        for letter, btn in pairs(self._letterBtns) do
            if board.guessed[letter] and not btn._used then
                btn._used = true
                btn:Disable()
                local inWord = false
                for i = 1, #board.word do
                    if board.word:sub(i,i) == letter then inWord = true; break end
                end
                if inWord then
                    btn:SetBackdropColor(0.0, 0.25, 0.05, 0.9)
                    btn:SetBackdropBorderColor(0.2, 0.8, 0.3, 0.9)
                    btn._label:SetTextColor(0.4, 1.0, 0.5)
                else
                    btn:SetBackdropColor(0.25, 0.03, 0.03, 0.9)
                    btn:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.9)
                    btn._label:SetTextColor(1.0, 0.3, 0.3)
                end
            end
        end
    end
end

-- ============================================================
-- GameOver
-- ============================================================
function R:ShowGameOver(won, board)
    if self._keyFrame then self._keyFrame:EnableKeyboard(false) end

    local wins   = Settings:Get("wins")
    local losses = Settings:Get("losses")

    if won then
        local _LGO = GamingHub.GetLocaleTable("HANGMAN")
        self._goTitle:SetText(_LGO["go_win_title"])
        if self._victoryTex then self._victoryTex:SetAlpha(0.9) end
    else
        local _LGO = GamingHub.GetLocaleTable("HANGMAN")
        self._goTitle:SetText(_LGO["go_loss_title"])
        if self._wordDisplay then self._wordDisplay:SetText(board.word) end
        for i = 1, board.maxErrors do
            local rf = self._runeFrames[i]
            if rf then
                rf._tex:SetAlpha(0.95)
                rf._tex:SetVertexColor(1.0, 0.1, 0.0)
                rf:SetBackdropBorderColor(1.0, 0.1, 0.0, 1.0)
                rf:SetBackdropColor(0.3, 0.0, 0.0, 0.95)
            end
        end
        if self._coreFrame then
            self._coreFrame:SetBackdropBorderColor(1.0, 0.1, 0.0, 1.0)
            self._coreFrame:SetBackdropColor(0.4, 0.0, 0.0, 0.95)
        end
    end

    self._goWord:SetText(string.format(GamingHub.GetLocaleTable("HANGMAN")["go_word"],
        (won and "88ff88" or "ff8844"), board.word))
    self._goStats:SetText(
        string.format(GamingHub.GetLocaleTable("HANGMAN")["go_stats"], wins, losses))
    self._goPanel:Show()
end

-- ============================================================
-- Plugin-Registrierung
-- ============================================================
GamingHub.RegisterGame({
    id        = "HANGMAN",
    label     = "Hangman",
    renderer  = "HGM_Renderer",
    engine    = "HGM_Engine",
    container = "_hangmanContainer",
})
