--[[
    Gaming Hub
    Games/Memory/Renderer.lua
    Version: 2.0.0  – Rebuild nach Mini Games Collection Referenz

    Kern-Erkenntnis aus MemoryPairs.lua:
    - Karten als "Button + BackdropTemplate" (nicht WHITE8X8 NormalTexture)
    - Icon direkt als card.icon (CreateTexture ARTWORK) – Show/Hide
    - Rückseite als card.backText (FontString "?") – Show/Hide
    - UpdateUI() SOFORT im OnClick, BEVOR CheckForMatch
    - Kein Event-Timing-Problem möglich da State-Lesen direkt aus gameState
    - Interface\Icons\ Präfix exakt wie im Referenz-Addon
]]

local GamingHub = _G.GamingHub
GamingHub.MEM_Renderer = {}
local R = GamingHub.MEM_Renderer

-- Farben
local CLR_HIDDEN   = { 0.20, 0.30, 0.50, 1 }   -- Blau (wie Referenz)
local CLR_FLIPPED  = { 0.80, 0.80, 0.80, 1 }   -- Hellgrau
local CLR_MATCHED  = { 0.15, 0.50, 0.15, 1 }   -- Grün (wie Referenz)
local CLR_MISMATCH = { 0.60, 0.15, 0.15, 1 }   -- Rot
local CLR_HOVER    = { 0.30, 0.40, 0.60, 1 }

-- Zellgrößen
local CELL_SIZES = { easy = 78, normal = 60, hard = 48 }

R.frame         = nil
R.state         = "IDLE"
R.selectedDiff  = nil
R.selectedTheme = nil
R.cards         = {}      -- R.cards[idx] = card-Frame mit .icon, .backText
R.boardHolder   = nil
R.diffBtns      = {}
R.diffContainer = nil
R.timerCheckbox = nil
R.exitButton    = nil
R.newGameButton = nil
R.timerFS       = nil
R.movesFS       = nil
R.themeFS       = nil
R.hintFS        = nil
R.overlay       = nil

-- ============================================================
-- Init
-- ============================================================
function R:Init()
    self:CreateMainFrame()
    self:CreateDiffButtons()
    self:CreateBottomButtons()
    self:CreateStatusBar()
    self:CreateOverlay()
    self:EnterIdleState()

    local Engine = GamingHub.Engine
    Engine:On("MEM_GAME_STARTED",  function(s)       R:OnGameStarted(s)    end)
    Engine:On("MEM_TIMER_TICK",    function(s)       R:OnTimerTick(s)      end)
    Engine:On("MEM_GAME_WON",      function(s)       R:OnGameWon(s)        end)
    Engine:On("MEM_GAME_LOST",     function(s)       R:OnGameLost(s)       end)
    Engine:On("MEM_GAME_STOPPED",  function()        R:EnterIdleState()    end)
    -- Flip/Match/Mismatch/Reset werden NICHT mehr über Events gehandhabt.
    -- UpdateBoard() wird direkt aus HandleFlip im Engine aufgerufen.
end

-- ============================================================
-- Main Frame
-- ============================================================
function R:CreateMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end
    local f = CreateFrame("Frame", "GamingHub_MEM_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    self.frame = f
    if _G.GamingHub then _G.GamingHub._memContainer = f end
end

-- ============================================================
-- BuildBoard – nach Referenz-Muster
-- Karte = Button + BackdropTemplate
--   card.icon     = Textur (ARTWORK), zunächst Hidden
--   card.backText = FontString "?", zunächst Shown
-- ============================================================
function R:BuildBoard(state)
    self:ClearBoard()

    local grid     = state.grid
    local cellSize = CELL_SIZES[state.difficulty] or 60
    local gap      = 4
    local total    = cellSize * grid + gap * (grid - 1)

    local holder = CreateFrame("Frame", nil, self.frame)
    holder:SetSize(total, total)
    holder:SetPoint("TOP", self.frame, "TOP", 0, -36)
    self.boardHolder = holder

    -- Kartenrückseite Icon bestimmen
    local SR       = GamingHub.MEM_SymbolResolver
    local S        = GamingHub.MEM_Settings
    local backData = SR:GetCardBack(S:GetAll())

    for idx = 1, state.totalCards do
        local row = math.floor((idx-1) / grid)
        local col = (idx-1) % grid
        local px  = col * (cellSize + gap)
        local py  = row * (cellSize + gap)

        -- Karte als Button mit BackdropTemplate (wie Referenz-Addon)
        local card = CreateFrame("Button", nil, holder, "BackdropTemplate")
        card:SetSize(cellSize - 2, cellSize - 2)
        card:SetPoint("TOPLEFT", holder, "TOPLEFT", px + 1, -(py + 1))
        card:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = false,
            edgeSize = 2,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        card:SetBackdropColor(CLR_HIDDEN[1], CLR_HIDDEN[2], CLR_HIDDEN[3], CLR_HIDDEN[4])
        card:SetBackdropBorderColor(0.4, 0.4, 0.6, 1)

        -- Icon (Vorderseite) – beginnt versteckt
        local iconTex = card:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(cellSize - 14, cellSize - 14)
        iconTex:SetPoint("CENTER")
        iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        iconTex:Hide()
        card.icon = iconTex

        -- Rückseiten-Darstellung: Fraktions-Icon oder "?" Text
        -- Wir nutzen das Fraktions-Icon als Rückseite (wie SettingsPanel konfigurierbar)
        local backIcon = card:CreateTexture(nil, "ARTWORK")
        backIcon:SetSize(cellSize - 14, cellSize - 14)
        backIcon:SetPoint("CENTER")
        backIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        backIcon:SetTexture(backData.icon)
        backIcon:SetVertexColor(backData.tint[1], backData.tint[2], backData.tint[3], 1)
        backIcon:Show()
        card.backIcon = backIcon

        -- Klick-Handler: State direkt ändern + sofort rendern (kein Event-Delay)
        local captureIdx = idx
        card:SetScript("OnClick", function()
            GamingHub.MEM_Engine:HandleFlip(captureIdx)
        end)

        -- Hover
        card:SetScript("OnEnter", function()
            local board = GamingHub.MEM_Engine.activeGame and GamingHub.MEM_Engine.activeGame.board
            local cardData = board and board.cards[captureIdx]
            if cardData and cardData.state == "HIDDEN" then
                card:SetBackdropColor(CLR_HOVER[1], CLR_HOVER[2], CLR_HOVER[3], 1)
            end
        end)
        card:SetScript("OnLeave", function()
            local board = GamingHub.MEM_Engine.activeGame and GamingHub.MEM_Engine.activeGame.board
            local cardData = board and board.cards[captureIdx]
            if cardData and cardData.state == "HIDDEN" then
                card:SetBackdropColor(CLR_HIDDEN[1], CLR_HIDDEN[2], CLR_HIDDEN[3], 1)
            end
        end)

        self.cards[idx] = card
    end
end

-- ============================================================
-- ClearBoard
-- ============================================================
function R:ClearBoard()
    for idx = 1, #self.cards do
        local card = self.cards[idx]
        if card then card:Hide(); card:SetParent(nil) end
    end
    self.cards = {}
    if self.boardHolder then
        self.boardHolder:Hide()
        self.boardHolder:SetParent(nil)
        self.boardHolder = nil
    end
end

-- ============================================================
-- UpdateBoard – direkt nach jedem Flip aufgerufen (wie UpdateUI im Referenz-Addon)
-- Liest den aktuellen State direkt aus dem Live-Board (kein Snapshot nötig)
-- ============================================================
function R:UpdateBoard()
    local game = GamingHub.MEM_Engine.activeGame
    if not game then return end
    local board = game.board

    for idx = 1, board.totalCards do
        local card     = self.cards[idx]
        local cardData = board.cards[idx]
        if card and cardData then
            if cardData.state == "MATCHED" then
                card:SetBackdropColor(CLR_MATCHED[1], CLR_MATCHED[2], CLR_MATCHED[3], 1)
                card:SetBackdropBorderColor(0.2, 0.7, 0.2, 1)
                card.icon:SetTexture("Interface\\Icons\\" .. cardData.icon)
                card.icon:Show()
                card.backIcon:Hide()

            elseif cardData.state == "FLIPPED" then
                card:SetBackdropColor(CLR_FLIPPED[1], CLR_FLIPPED[2], CLR_FLIPPED[3], 1)
                card:SetBackdropBorderColor(0.9, 0.8, 0.4, 1)
                card.icon:SetTexture("Interface\\Icons\\" .. cardData.icon)
                card.icon:Show()
                card.backIcon:Hide()

            else -- HIDDEN
                card:SetBackdropColor(CLR_HIDDEN[1], CLR_HIDDEN[2], CLR_HIDDEN[3], 1)
                card:SetBackdropBorderColor(0.4, 0.4, 0.6, 1)
                card.icon:Hide()
                card.backIcon:Show()
            end
        end
    end

    -- Status-Bar aktualisieren
    self:UpdateStatusBar(board)
end

-- ============================================================
-- Mismatch-Flash: kurz rot, dann zurückdrehen (nach Referenz: C_Timer.After(1))
-- Wird direkt aus Engine aufgerufen
-- ============================================================
function R:FlashMismatch(i1, i2)
    local c1 = self.cards[i1]
    local c2 = self.cards[i2]
    if c1 then c1:SetBackdropColor(CLR_MISMATCH[1], CLR_MISMATCH[2], CLR_MISMATCH[3], 1) end
    if c2 then c2:SetBackdropColor(CLR_MISMATCH[1], CLR_MISMATCH[2], CLR_MISMATCH[3], 1) end
end

-- ============================================================
-- Status Bar
-- ============================================================
function R:CreateStatusBar()
    if self.timerFS then return end
    local f = self.frame

    self.timerFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.timerFS:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    self.timerFS:SetJustifyH("RIGHT")
    self.timerFS:Hide()

    self.movesFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.movesFS:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -32)
    self.movesFS:SetJustifyH("RIGHT")
    self.movesFS:Hide()

    self.themeFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.themeFS:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
    self.themeFS:SetJustifyH("LEFT")
    self.themeFS:Hide()
end

function R:UpdateStatusBar(board)
    if self.timerFS then
        if board.timerActive and board.timerLeft then
            local m = math.floor(board.timerLeft / 60)
            local s = board.timerLeft % 60
            local _LT = GamingHub.GetLocaleTable("MEMORY")
            local color = board.timerLeft <= 30 and _LT["timer_color_warn"] or _LT["timer_color_ok"]
            self.timerFS:SetText(string.format("%s⏱ %d:%02d|r", color, m, s))
            self.timerFS:Show()
        else
            self.timerFS:Hide()
        end
    end
    if self.movesFS then
        local _LM = GamingHub.GetLocaleTable("MEMORY")
        self.movesFS:SetText(string.format(
            _LM["stats_moves_pairs"],
            board.moves or 0, board.matchedPairs or 0, board.pairs or 0))
        self.movesFS:Show()
    end
    if self.themeFS then
        self.themeFS:SetText("|cffffd700" .. (board.themeName or "") .. "|r")
        self.themeFS:Show()
    end
end

-- ============================================================
-- Diff-Buttons + Timer-Checkbox
-- ============================================================
local function GetDiffs()
    local L = GamingHub.GetLocaleTable("MEMORY")
    return {
        { label = L["diff_easy"],   value = "easy"   },
        { label = L["diff_normal"], value = "normal" },
        { label = L["diff_hard"],   value = "hard"   },
    }
end

function R:CreateDiffButtons()
    if self.diffContainer then return end
    local c = CreateFrame("Frame", nil, self.frame)
    c:SetPoint("BOTTOM", self.frame, "BOTTOM", -30, 36)
    c:SetSize(360, 30)
    self.diffContainer = c

    local DIFFS = GetDiffs()
    local W = 90; local SP = 10
    local startX = -math.floor((#DIFFS * W + (#DIFFS-1)*SP) / 2)
    for i, d in ipairs(DIFFS) do
        local btn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        btn:SetSize(W, 28)
        btn:SetPoint("LEFT", c, "CENTER", startX + (i-1)*(W+SP), 0)
        btn:SetText(d.label)
        btn:SetScript("OnClick", function() R:SelectDiff(d.value, btn) end)
        self.diffBtns[i] = btn
    end

    local cb = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("LEFT", c, "RIGHT", 16, 2)
    local S = GamingHub.MEM_Settings
    cb:SetChecked(S and S:Get("timerActive") or false)
    local cbLbl = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cbLbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cbLbl:SetText(GamingHub.GetLocaleTable("MEMORY")["timer_label"])
    cbLbl:SetTextColor(0.90, 0.85, 0.70)
    cb:SetScript("OnClick", function(self)
        if S then S:Set("timerActive", self:GetChecked()) end
    end)
    self.timerCheckbox = cb
end

function R:SelectDiff(value, clicked)
    self.selectedDiff = value
    local S = GamingHub.MEM_Settings
    if S then S:Set("difficulty", value) end
    for _, b in ipairs(self.diffBtns) do b:UnlockHighlight() end
    clicked:LockHighlight()
    GamingHub.MEM_Engine:StartGame({
        difficulty  = value,
        theme       = self.selectedTheme or (S and S:Get("theme")) or "classes",
        timerActive = self.timerCheckbox and self.timerCheckbox:GetChecked() or false,
    })
end

-- ============================================================
-- Bottom Buttons
-- ============================================================
function R:CreateBottomButtons()
    if self.exitButton then return end
    local exit = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    exit:SetSize(100, 28)
    exit:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 6)
    exit:SetText(GamingHub.GetLocaleTable("MEMORY")["btn_exit"])
    exit:SetScript("OnClick", function() GamingHub.MEM_Engine:StopGame() end)
    exit:Hide()
    self.exitButton = exit

    local newGame = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    newGame:SetSize(120, 28)
    newGame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 6)
    newGame:SetText(GamingHub.GetLocaleTable("MEMORY")["btn_new_game"])
    newGame:SetScript("OnClick", function()
        local S = GamingHub.MEM_Settings
        GamingHub.MEM_Engine:StartGame({
            difficulty  = R.selectedDiff or "easy",
            theme       = R.selectedTheme or (S and S:Get("theme")) or "classes",
            timerActive = R.timerCheckbox and R.timerCheckbox:GetChecked() or false,
        })
    end)
    newGame:Hide()
    self.newGameButton = newGame
end

-- ============================================================
-- Overlay
-- ============================================================
function R:CreateOverlay()
    if self.overlay then return end
    local ov = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    ov:SetAllPoints(self.frame)
    ov:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
    ov:SetBackdropColor(0, 0, 0, 0.82)
    ov:SetFrameLevel(self.frame:GetFrameLevel() + 50)
    ov:EnableMouse(true)
    ov:Hide()

    local title = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("CENTER", ov, "CENTER", 0, 50)
    ov.title = title

    local sub = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -14)
    sub:SetJustifyH("CENTER")
    ov.sub = sub

    local restartBtn = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
    restartBtn:SetSize(160, 30)
    restartBtn:SetPoint("TOP", sub, "BOTTOM", 0, -20)
    restartBtn:SetText(GamingHub.GetLocaleTable("MEMORY")["btn_new_game_ov"])
    restartBtn:SetScript("OnClick", function()
        ov:Hide()
        local S = GamingHub.MEM_Settings
        GamingHub.MEM_Engine:StartGame({
            difficulty  = R.selectedDiff or "easy",
            theme       = R.selectedTheme or (S and S:Get("theme")) or "classes",
            timerActive = R.timerCheckbox and R.timerCheckbox:GetChecked() or false,
        })
    end)
    self.overlay = ov
end

-- ============================================================
-- Idle State
-- ============================================================
function R:EnterIdleState()
    self.state = "IDLE"
    self:ClearBoard()
    if self.overlay       then self.overlay:Hide()       end
    if self.exitButton    then self.exitButton:Hide()    end
    if self.newGameButton then self.newGameButton:Hide() end
    if self.timerFS       then self.timerFS:Hide()       end
    if self.movesFS       then self.movesFS:Hide()       end
    if self.themeFS       then self.themeFS:Hide()       end
    for i, b in ipairs(self.diffBtns) do
        b:UnlockHighlight()
        local DIFFS_REF = GetDiffs()
        if DIFFS_REF[i] and DIFFS_REF[i].value == self.selectedDiff then b:LockHighlight() end
    end
    if not self.hintFS then
        self.hintFS = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.hintFS:SetPoint("CENTER", self.frame, "CENTER", 0, 20)
        self.hintFS:SetText(GamingHub.GetLocaleTable("MEMORY")["hint_start"])
        self.hintFS:SetJustifyH("CENTER")
    end
    self.hintFS:Show()
end

-- ============================================================
-- Event Handler (nur noch Start/Timer/Won/Lost)
-- ============================================================
function R:OnGameStarted(state)
    self.state        = "PLAYING"
    self.selectedDiff = state.difficulty
    self.selectedTheme= state.theme
    if self.overlay       then self.overlay:Hide()       end
    if self.hintFS        then self.hintFS:Hide()        end
    if self.exitButton    then self.exitButton:Show()    end
    if self.newGameButton then self.newGameButton:Show() end
    self:BuildBoard(state)
    self:UpdateBoard()
end

function R:OnTimerTick(state)
    if GamingHub.MEM_Engine.activeGame then
        self:UpdateStatusBar(GamingHub.MEM_Engine.activeGame.board)
    end
end

function R:OnGameWon(state)
    self.state = "WON"
    self:UpdateBoard()
    local ov = self.overlay
    if not ov then return end
    local _LW = GamingHub.GetLocaleTable("MEMORY")
    ov.title:SetText(_LW["result_win_title"])
    ov.title:SetTextColor(1, 0.84, 0)
    local timeStr = ""
    if state.timerActive and state.timerLeft then
        local m = math.floor(state.timerLeft / 60)
        local s = state.timerLeft % 60
        timeStr = string.format(_LW["result_win_time"], m, s)
    end
    ov.sub:SetText(string.format(_LW["result_win_sub"], state.moves, state.pairs) .. timeStr)
    ov:SetAlpha(0); ov:Show()
    UIFrameFadeIn(ov, 0.5, 0, 0.88)
end

function R:OnGameLost(state)
    self.state = "LOST"
    local ov = self.overlay
    if not ov then return end
    local _LL = GamingHub.GetLocaleTable("MEMORY")
    ov.title:SetText(_LL["result_lose_title"])
    ov.title:SetTextColor(1, 0.3, 0.3)
    ov.sub:SetText(string.format(_LL["result_lose_sub"],
        state.matchedPairs, state.pairs, state.moves))
    ov:SetAlpha(0); ov:Show()
    UIFrameFadeIn(ov, 0.5, 0, 0.88)
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "MEMORY",
    label     = "Memory",
    renderer  = "MEM_Renderer",
    engine    = "MEM_Engine",
    container = "_memContainer",
})
