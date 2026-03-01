--[[
    Gaming Hub – Mensch ärgere dich nicht (Ludo)
    Games/Ludo/Renderer.lua

    Layout:
    ┌──────────────────────────────────────────────────┐
    │ [Spieler-Info links]   [Spieler-Info rechts]     │  ← StatusBar
    │ ┌──────────────────────────────────────────────┐ │
    │ │   11x11 Grid (zentriert)                     │ │
    │ │   Würfel-Button im Center-Feld (61)          │ │
    │ └──────────────────────────────────────────────┘ │
    │ [Beenden]                         [Neues Spiel]  │
    └──────────────────────────────────────────────────┘

    Grid-Felder:
    - UNSICHTBAR: Felder die weder Pfad, Basis noch Home sind → SetAlpha(0)
    - HAUPTPFAD:  neutrale Stein-Textur (pathTex)
    - BASIS:      Spieler-Farbe + Basis-Textur
    - ZIELGERADE: Spieler-Farbe
    - ZENTRUM:    Würfel-Button (Feld 61)

    Figuren werden ALS TEXTUREN auf den Feld-Frames gezeichnet,
    nicht als eigene Frames, um Frame-Limit zu vermeiden.
]]

local GamingHub = _G.GamingHub
GamingHub.LUDO_Renderer = {}
local R = GamingHub.LUDO_Renderer

R.frame          = nil
R.state          = "IDLE"
R.cells          = {}       -- cells[gridIdx] = Frame
R.diceBtn        = nil
R.exitButton     = nil
R.newGameButton  = nil
R.hintFS         = nil
R.overlay        = nil
R.statusLeft     = nil
R.statusRight    = nil
R.gridHolder     = nil
R._currentTheme  = nil
R._currentColor  = nil
R._game          = nil
R._validMoveIdxs = {}   -- pieceIdx → true (für Highlight)

-- Zellgröße: 11x11 in ~500px Panel → ~42px pro Zelle
local CELL_SIZE = 42
local CELL_GAP  = 1

-- ============================================================
-- Init
-- ============================================================
function R:Init()
    self:CreateMainFrame()
    self:CreateStatusBar()
    self:CreateBottomButtons()
    self:CreateOverlay()
    self:EnterIdleState()

    local Eng = GamingHub.Engine
    Eng:On("LUDO_GAME_STARTED",  function(g)         R:OnGameStarted(g)           end)
    Eng:On("LUDO_GAME_STOPPED",  function()           R:EnterIdleState()           end)
    Eng:On("LUDO_DICE_ROLLED",   function(g,v)        R:OnDiceRolled(g,v)          end)
    Eng:On("LUDO_NO_MOVE",       function(g)          R:OnNoMove(g)                end)
    Eng:On("LUDO_TURN_CHANGED",  function(g)          R:OnTurnChanged(g)           end)
end

-- ============================================================
-- CreateMainFrame
-- ============================================================
function R:CreateMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end
    local f = CreateFrame("Frame", "GamingHub_LUDO_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    self.frame = f
    if _G.GamingHub then _G.GamingHub._ludoContainer = f end
end

-- ============================================================
-- BuildBoard – erstellt das 11x11 Grid
-- ============================================================
function R:BuildBoard(game)
    self:ClearBoard()

    local board  = GamingHub.LUDO_Board
    local themes = GamingHub.LUDO_Themes
    local theme  = themes:GetTheme(game.theme)

    local totalPx = 11 * CELL_SIZE + 10 * CELL_GAP
    local panelW  = self.frame:GetWidth()  or 620
    local panelH  = self.frame:GetHeight() or 700
    local offX    = math.floor((panelW - totalPx) / 2)
    local offY    = 32  -- unterhalb StatusBar

    local holder = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    holder:SetPoint("TOPLEFT", self.frame, "TOPLEFT", offX, -offY)
    holder:SetSize(totalPx, totalPx)
    holder:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 2,
        insets = { left=2, right=2, top=2, bottom=2 },
    })
    holder:SetBackdropColor(0.03, 0.03, 0.05, 1)
    holder:SetBackdropBorderColor(0.40, 0.35, 0.20, 1)
    self.gridHolder = holder

    -- Welche Felder gehören wozu?
    local pathSet   = {}
    local homeSet   = {}   -- homeSet[gridIdx] = playerColorIdx
    local baseSet   = {}   -- baseSet[gridIdx] = playerColorIdx

    for _, idx in ipairs(board.MAIN_PATH)     do pathSet[idx] = true end
    for pID, path in ipairs(board.HOME_PATH)  do
        for _, idx in ipairs(path) do homeSet[idx] = pID end
    end
    for pID, base in ipairs(board.BASE_FIELDS) do
        for _, idx in ipairs(base) do baseSet[idx] = pID end
    end

    self.cells = {}

    for gridIdx = 1, 121 do
        local row = math.floor((gridIdx-1) / 11)  -- 0-basiert
        local col = (gridIdx-1) % 11               -- 0-basiert
        local cx  = col * (CELL_SIZE + CELL_GAP)
        local cy  = row * (CELL_SIZE + CELL_GAP)

        local cell = CreateFrame("Button", nil, holder, "BackdropTemplate")
        cell:SetSize(CELL_SIZE, CELL_SIZE)
        cell:SetPoint("TOPLEFT", holder, "TOPLEFT", cx, -cy)
        cell:EnableMouse(false)

        -- Hintergrund
        local bg = cell:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.03, 0.03, 0.05, 1)
        cell.bg = bg

        -- Icon-Textur
        local tex = cell:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        tex:Hide()
        cell.tex = tex

        -- Figur-Overlay (für Spielfiguren)
        local figTex = cell:CreateTexture(nil, "OVERLAY")
        figTex:SetPoint("TOPLEFT", cell, "TOPLEFT", 4, -4)
        figTex:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -4, 4)
        figTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        figTex:Hide()
        cell.figTex = figTex

        -- Highlight-Border (für gültige Züge)
        local hl = cell:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetTexture("Interface\\Buttons\\WHITE8X8")
        hl:SetVertexColor(1, 1, 0.3, 0.45)
        hl:Hide()
        cell.hl = hl

        -- Feld-Typ setzen
        if gridIdx == board.CENTER_FIELD then
            -- Zentrum: Würfel
            bg:SetVertexColor(0.15, 0.15, 0.20, 1)
            cell.tex:SetTexture(theme.dice[1])
            cell.tex:Show()
            cell.isCenter = true
            cell:EnableMouse(true)
            cell:SetScript("OnClick", function()
                GamingHub.LUDO_Engine:HandleRollClick()
            end)
            self.diceBtn = cell

        elseif pathSet[gridIdx] then
            -- Hauptpfad
            bg:SetVertexColor(0.18, 0.16, 0.12, 1)
            cell.tex:SetTexture(theme.pathTex)
            cell.tex:SetVertexColor(0.65, 0.60, 0.50)
            cell.tex:Show()
            cell.isPath = true

        elseif homeSet[gridIdx] then
            -- Zielgerade
            local pID     = homeSet[gridIdx]
            local clr     = theme.colors[pID]
            bg:SetVertexColor(clr[1]*0.25, clr[2]*0.25, clr[3]*0.25, 1)
            cell.tex:SetTexture(theme.homeTex)
            cell.tex:SetVertexColor(clr[1]*0.7, clr[2]*0.7, clr[3]*0.7)
            cell.tex:Show()
            cell.isHome    = true
            cell.playerID  = pID

        elseif baseSet[gridIdx] then
            -- Basis
            local pID     = baseSet[gridIdx]
            local clr     = theme.colors[pID]
            bg:SetVertexColor(clr[1]*0.15, clr[2]*0.15, clr[3]*0.15, 1)
            cell.tex:SetTexture(theme.baseTex)
            cell.tex:SetVertexColor(clr[1]*0.5, clr[2]*0.5, clr[3]*0.5)
            cell.tex:Show()
            cell.isBase   = true
            cell.playerID = pID

        else
            -- Inaktives Feld: unsichtbar
            cell:SetAlpha(0)
            cell:EnableMouse(false)
            cell.isInactive = true
        end

        self.cells[gridIdx] = cell
    end

    -- Figuren initial zeichnen
    self:RenderAllPieces(game)
end

-- ============================================================
-- RenderAllPieces – zeichnet alle Figuren neu
-- ============================================================
function R:RenderAllPieces(game)
    if not game then return end
    local themes = GamingHub.LUDO_Themes
    local theme  = themes:GetTheme(game.theme)

    -- Erst alle Figur-Texturen löschen
    for _, cell in pairs(self.cells) do
        if cell.figTex then cell.figTex:Hide() end
    end

    -- Figuren zeichnen
    for _, player in pairs(game.players) do
        local clr      = theme.colors[player.colorIdx]
        local pieceIcon = theme.pieces[player.colorIdx]

        for _, piece in ipairs(player.pieces) do
            if not piece.finished and piece.gridIdx then
                local cell = self.cells[piece.gridIdx]
                if cell and cell.figTex then
                    cell.figTex:SetTexture(pieceIcon)
                    cell.figTex:SetVertexColor(clr[1], clr[2], clr[3])
                    cell.figTex:Show()
                end
            end
        end
    end
end

-- ============================================================
-- ShowValidMoveHighlights – zeigt welche Figuren ziehbar sind
-- ============================================================
function R:ShowValidMoveHighlights(game)
    self:ClearHighlights()
    if not game then return end
    local L     = GamingHub.LUDO_Logic
    local moves = L:GetValidMoves(game)
    local player = game.players[game.current]

    for _, move in ipairs(moves) do
        local piece = player.pieces[move.pieceIdx]
        if piece.gridIdx then
            local cell = self.cells[piece.gridIdx]
            if cell and cell.hl then
                cell.hl:Show()
                cell:EnableMouse(true)
                local idx = move.pieceIdx
                cell:SetScript("OnClick", function()
                    GamingHub.LUDO_Engine:HandlePieceClick(idx)
                end)
            end
        end
    end
end

function R:ClearHighlights()
    for _, cell in pairs(self.cells) do
        if cell.hl then cell.hl:Hide() end
        if not cell.isCenter then
            cell:SetScript("OnClick", nil)
            if not cell.isPath and not cell.isBase and not cell.isHome then
                cell:EnableMouse(false)
            end
        end
    end
end

-- ============================================================
-- Dice-Animation – lässt den Würfel kurz animieren
-- ============================================================
function R:AnimateDice(theme, finalVal, callback)
    local diceBtn = self.diceBtn
    if not diceBtn then if callback then callback() end; return end

    local frames = 8
    local delay  = 0.06
    local step   = 0

    local function NextFrame()
        if not self._running then return end
        step = step + 1
        local faceIdx = ((step-1) % 6) + 1
        diceBtn.tex:SetTexture(theme.dice[faceIdx])
        if step < frames then
            C_Timer.After(delay, NextFrame)
        else
            diceBtn.tex:SetTexture(theme.dice[finalVal])
            if callback then callback() end
        end
    end
    C_Timer.After(0, NextFrame)
end

-- ============================================================
-- Event-Handler (direkte Aufrufe vom Engine + Event-System)
-- ============================================================
function R:OnGameStarted(game)
    self.state    = "PLAYING"
    self._game    = game
    self._running = true
    if self.overlay     then self.overlay:Hide()      end
    if self.hintFS      then self.hintFS:Hide()       end
    if self.exitButton  then self.exitButton:Show()   end
    if self.newGameButton then self.newGameButton:Show() end
    self:BuildBoard(game)
    self:UpdateStatus(game)
end

function R:OnDiceRolled(game, val)
    local themes = GamingHub.LUDO_Themes
    local theme  = themes:GetTheme(game.theme)
    self:AnimateDice(theme, val, function()
        self:UpdateStatus(game)
        -- Wenn Mensch am Zug: Highlights zeigen
        if game.current == game.humanID and game.phase == "move" then
            self:ShowValidMoveHighlights(game)
        end
    end)
end

function R:OnTurnStart(game)
    self:ClearHighlights()
    self:UpdateStatus(game)
    -- Würfel zurücksetzen
    if self.diceBtn then
        local themes = GamingHub.LUDO_Themes
        local theme  = themes:GetTheme(game.theme)
        self.diceBtn.tex:SetTexture(theme.dice[1])
    end
    -- Würfel anklickbar wenn Mensch dran
    if self.diceBtn then
        self.diceBtn:EnableMouse(game.current == game.humanID)
        self.diceBtn:SetAlpha(game.current == game.humanID and 1.0 or 0.5)
    end
end

function R:OnTurnChanged(game)
    self:OnTurnStart(game)
end

function R:OnPieceMoved(game, playerID, pieceIdx, result)
    self:ClearHighlights()
    self:RenderAllPieces(game)
    self:UpdateStatus(game)
end

function R:OnNoMove(game)
    self:UpdateStatus(game, GamingHub.GetLocaleTable("LUDO")["status_no_move"])
end

function R:OnGameWon(game, winnerID)
    self.state    = "GAMEOVER"
    self._running = false
    self:ClearHighlights()
    self:RenderAllPieces(game)
    self:ShowOverlay(game, winnerID)
end

-- ============================================================
-- CreateStatusBar
-- ============================================================
function R:CreateStatusBar()
    if self.statusLeft then return end
    local f = self.frame

    self.statusLeft = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.statusLeft:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -10)
    self.statusLeft:Hide()

    self.statusRight = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.statusRight:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -10)
    self.statusRight:SetJustifyH("RIGHT")
    self.statusRight:Hide()
end

function R:UpdateStatus(game, extraMsg)
    if not game then return end
    local themes    = GamingHub.LUDO_Themes
    local theme     = themes:GetTheme(game.theme)
    local board     = GamingHub.LUDO_Board
    local humanP    = game.players[game.humanID]
    local aiP       = game.players[game.aiID]
    local humanClr  = theme.colors[humanP.colorIdx]
    local aiClr     = theme.colors[aiP.colorIdx]
    local hName     = board.PLAYER_NAMES[humanP.colorIdx]
    local aName     = board.PLAYER_NAMES[aiP.colorIdx]

    -- Zähle fertige Figuren
    local function countDone(p)
        local n = 0
        for _, pc in ipairs(p.pieces) do if pc.finished then n=n+1 end end
        return n
    end

    local hDone = countDone(humanP)
    local aDone = countDone(aiP)

    if self.statusLeft then
        self.statusLeft:SetText(string.format(
            GamingHub.GetLocaleTable("LUDO")["status_human"],
            humanClr[1]*255, humanClr[2]*255, humanClr[3]*255,
            hName, hDone))
        self.statusLeft:Show()
    end

    if self.statusRight then
        local turnStr
        if extraMsg then
            turnStr = extraMsg
        elseif game.current == game.humanID then
            if game.phase == "roll" then
                turnStr = GamingHub.GetLocaleTable("LUDO")["status_roll"]
            else
                turnStr = GamingHub.GetLocaleTable("LUDO")["status_pick"]
            end
        else
            turnStr = GamingHub.GetLocaleTable("LUDO")["status_ai_think"]
        end
        self.statusRight:SetText(string.format(
            GamingHub.GetLocaleTable("LUDO")["status_ai"],
            aiClr[1]*255, aiClr[2]*255, aiClr[3]*255,
            aName, aDone, turnStr))
        self.statusRight:Show()
    end
end

-- ============================================================
-- CreateBottomButtons
-- ============================================================
function R:CreateBottomButtons()
    if self.exitButton then return end
    local exit = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    exit:SetSize(90, 26)
    exit:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 10)
    exit:SetText(GamingHub.GetLocaleTable("LUDO")["btn_exit"])
    exit:SetScript("OnClick", function() GamingHub.LUDO_Engine:StopGame() end)
    exit:Hide()
    self.exitButton = exit

    local ng = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    ng:SetSize(110, 26)
    ng:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 10)
    ng:SetText(GamingHub.GetLocaleTable("LUDO")["btn_new_game"])
    ng:SetScript("OnClick", function() R:StartNewGame() end)
    ng:Hide()
    self.newGameButton = ng
end

function R:StartNewGame()
    local S = GamingHub.LUDO_Settings
    GamingHub.LUDO_Engine:StartGame({
        humanColor = self._currentColor or S:Get("playerColor"),
        theme      = self._currentTheme or S:Get("theme"),
    })
end

-- ============================================================
-- CreateOverlay
-- ============================================================
function R:CreateOverlay()
    if self.overlay then return end
    local ov = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    ov:SetAllPoints(self.frame)
    ov:SetBackdrop({ bgFile="Interface/Buttons/WHITE8x8" })
    ov:SetBackdropColor(0, 0, 0, 0.84)
    ov:SetFrameLevel(self.frame:GetFrameLevel() + 50)
    ov:EnableMouse(true)
    ov:Hide()

    local title = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("CENTER", ov, "CENTER", 0, 60)
    ov.title = title

    local sub = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -12)
    sub:SetJustifyH("CENTER")
    ov.sub = sub

    local btn = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
    btn:SetSize(160, 28)
    btn:SetPoint("TOP", sub, "BOTTOM", 0, -20)
    btn:SetText(GamingHub.GetLocaleTable("LUDO")["btn_new_game_ov"])
    btn:SetScript("OnClick", function() ov:Hide(); R:StartNewGame() end)
    self.overlay = ov
end

function R:ShowOverlay(game, winnerID)
    local ov = self.overlay
    if not ov then return end
    local board  = GamingHub.LUDO_Board
    local themes = GamingHub.LUDO_Themes
    local theme  = themes:GetTheme(game.theme)
    local winner = game.players[game.humanID].colorIdx == winnerID and game.players[game.humanID]
        or game.players[game.aiID]
    local isHuman = (winnerID == game.humanID)

    if isHuman then
        local _LW = GamingHub.GetLocaleTable("LUDO")
        ov.title:SetText(_LW["result_win_title"])
        ov.sub:SetText(_LW["result_win_sub"])
    else
        local clr  = theme.colors[game.players[game.aiID].colorIdx]
        local _LL = GamingHub.GetLocaleTable("LUDO")
        ov.title:SetText(_LL["result_loss_title"])
        ov.sub:SetText(_LL["result_loss_sub"])
    end
    ov:SetAlpha(0); ov:Show()
    UIFrameFadeIn(ov, 0.5, 0, 0.88)
end

-- ============================================================
-- ClearBoard
-- ============================================================
function R:ClearBoard()
    self.cells    = {}
    self.diceBtn  = nil
    self._running = false
    if self.gridHolder then
        self.gridHolder:Hide()
        self.gridHolder:SetParent(nil)
        self.gridHolder = nil
    end
end

-- ============================================================
-- EnterIdleState
-- ============================================================
function R:EnterIdleState()
    self.state    = "IDLE"
    self._running = false
    self:ClearBoard()
    if self.overlay       then self.overlay:Hide()       end
    if self.exitButton    then self.exitButton:Hide()    end
    if self.newGameButton then self.newGameButton:Hide() end
    if self.statusLeft    then self.statusLeft:Hide()    end
    if self.statusRight   then self.statusRight:Hide()   end

    if not self.hintFS then
        self.hintFS = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.hintFS:SetPoint("CENTER", self.frame, "CENTER", 0, 40)
        self.hintFS:SetText(GamingHub.GetLocaleTable("LUDO")["hint_start"])
        self.hintFS:SetJustifyH("CENTER")
    end

    if not self.newGameButton then return end
    self.newGameButton:Show()
    self.hintFS:Show()
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "LUDO",
    label     = "Ludo",
    renderer  = "LUDO_Renderer",
    engine    = "LUDO_Engine",
    container = "_ludoContainer",
})
