--[[
    Gaming Hub
    Games/VierGewinnt/Renderer.lua
    Version: 1.0.0

    Unterschiede zu Core/Renderer.lua (TicTacToe):
      - Spielfeld ist cols × rows, NICHT quadratisch
      - Klick auf eine Spalte (nicht auf eine Zelle) → HandlePlayerMove(col)
      - Hover-Highlight zeigt die gesamte Spalte in der der Stein fallen würde
      - "Drop"-Animation: Stein erscheint oben und faded in der Zielzelle ein
      - Gewinnen-Linie: selbe Linie-Logik, aber col/row statt x/y
      - Modus-Auswahl: Klein (5×4), Normal (7×6), Groß (9×7)

    Sound und SymbolResolver: VierGewinnt-spezifisch
    Dieser Renderer ist komplett unabhängig von Core/Renderer.lua.
]]

local GamingHub = _G.GamingHub
GamingHub.VierGewinntRenderer = {}

local Renderer = GamingHub.VierGewinntRenderer

-- SoundKitIDs (verifiziert, identisch zu TicTacToe)
local SOUND_WIN  = 888
local SOUND_DRAW = 8959
local SOUND_LOSS = 847

-- ============================================================
-- State
-- ============================================================

Renderer.frame            = nil
Renderer.overlay          = nil
Renderer.exitButton       = nil

Renderer.cellButtons      = {}   -- [row][col] = Button
Renderer.colHitFrames     = {}   -- [col] = unsichtbarer Klick-Frame pro Spalte

Renderer.boardCols        = 7
Renderer.boardRows        = 6
Renderer.cellW            = 0
Renderer.cellH            = 0
Renderer.boardOffsetX     = 0
Renderer.boardOffsetY     = 0

Renderer.state            = "IDLE"
Renderer.lastResult       = nil

Renderer.modeContainer    = nil
Renderer.diffContainer    = nil
Renderer.modeBtns         = {}
Renderer.diffBtns         = {}
Renderer.selectedMode     = nil
Renderer.selectedDiff     = nil

Renderer.winLineFrame     = nil
Renderer.winLineTexture   = nil

-- ============================================================
-- Sound
-- ============================================================

local function PlayGameSound(result)
    local S = GamingHub.VierGewinntSettings
    if not S or not S:Get("soundEnabled") then return end

    if result == "WIN"  and S:Get("soundOnWin")  then PlaySound(SOUND_WIN,  "SFX") end
    if result == "DRAW" and S:Get("soundOnDraw") then PlaySound(SOUND_DRAW, "SFX") end
    if result == "LOSS" and S:Get("soundOnLoss") then PlaySound(SOUND_LOSS, "SFX") end
end

-- ============================================================
-- Symbol anwenden (identisch zu TicTacToe ApplySymbol)
-- btn.disc  = Textur (runder Stein)
-- btn.atlTex = Textur für Fraktions-Wappen (SPRITE-Modus)
-- btn.text  = FontString (TEXT-Modus, Fallback)
-- ============================================================

local function ApplySymbol(btn, symbolDef)
    if not symbolDef then
        btn.disc:SetColorTexture(0.1, 0.1, 0.1, 1)
        btn.text:SetText("")
        if btn.atlTex then btn.atlTex:Hide() end
        return
    end

    if symbolDef.mode == "TEXT" then
        -- Stein-Farbe direkt auf die disc-Textur setzen
        btn.disc:SetColorTexture(symbolDef.r or 1, symbolDef.g or 1, symbolDef.b or 1, 1)
        btn.text:SetText("")
        if btn.atlTex then btn.atlTex:Hide() end

    elseif symbolDef.mode == "SPRITE" then
        -- Fraktions-Wappen: disc neutral lassen, Wappen darüber
        btn.disc:SetColorTexture(0.25, 0.25, 0.25, 1)
        btn.text:SetText("")
        if btn.atlTex then
            btn.atlTex:SetTexture(symbolDef.path)
            btn.atlTex:SetTexCoord(
                symbolDef.left, symbolDef.right,
                symbolDef.top,  symbolDef.bottom
            )
            btn.atlTex:Show()
        end
    end
end

-- ============================================================
-- Init
-- ============================================================

function Renderer:Init()
    self:CreateMainFrame()
    self:CreateOverlay()
    self:CreateModeContainer()
    self:CreateDiffContainer()
    self:CreateExitButton()
    self:EnterIdleState()

    local Engine = GamingHub.Engine

    Engine:On("VG_GAME_STARTED", function(board)
        Renderer.state = "PLAYING"
        Renderer:HideModeSelection()
        Renderer:RenderBoard(board)
    end)

    Engine:On("VG_BOARD_UPDATED", function()
        Renderer:UpdateBoard()
    end)

    Engine:On("VG_GAME_OVER", function(result)
        Renderer:ShowGameOver(result)
    end)

    Engine:On("VG_WIN_LINE", function(line)
        Renderer:HighlightWinningLine(line)
    end)

    Engine:On("VG_GAME_STOPPED", function()
        Renderer:EnterIdleState()
    end)
end

-- ============================================================
-- Frame
-- ============================================================

function Renderer:CreateMainFrame()
    if self.frame then return end
    if _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel then
        local gamesPanel = _G.GamingHubUI.GetGamesPanel()
        -- Eigener Sub-Frame damit Vier Gewinnt und andere Spiele
        -- sich nicht gegenseitig überschneiden.
        local container = CreateFrame("Frame", "GamingHub_VG_Container", gamesPanel)
        container:SetAllPoints(gamesPanel)
        container:Hide()  -- wird nur gezeigt wenn Vier Gewinnt aktiv
        self.frame = container
        -- Referenz für UI-Routing
        if _G.GamingHub then
            _G.GamingHub._vgContainer = container
        end
    end
end

-- ============================================================
-- Modus-Auswahl (Brett-Größe)
-- ============================================================

local function GetModes()
    local L = GamingHub.GetLocaleTable("CONNECT4")
    return {
        { label = L["mode_small"],  cols = 5, rows = 4 },
        { label = L["mode_normal"], cols = 7, rows = 6 },
        { label = L["mode_large"],  cols = 9, rows = 7 },
    }
end

function Renderer:CreateModeContainer()
    if self.modeContainer then return end

    local container = CreateFrame("Frame", nil, self.frame)
    container:SetPoint("BOTTOM", self.frame, "BOTTOM", 80, 35)
    container:SetSize(500, 30)
    self.modeContainer = container

    local W = 130
    local spacing = 14

    local MODES = GetModes()
    for i, mode in ipairs(MODES) do
        local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
        btn:SetSize(W, 28)
        btn:SetPoint("LEFT", container, "LEFT", (i-1)*(W+spacing), 0)
        btn:SetText(mode.label)
        btn:SetScript("OnClick", function()
            Renderer:SetMode(mode, btn)
        end)
        table.insert(self.modeBtns, btn)
    end
end

function Renderer:SetMode(mode, clicked)
    self.selectedMode = mode
    for _, btn in ipairs(self.modeBtns) do btn:UnlockHighlight() end
    clicked:LockHighlight()
    -- Schwierigkeits-Auswahl freischalten
    self.diffContainer:SetAlpha(1)
    for _, btn in ipairs(self.diffBtns) do btn:Enable() end
end

-- ============================================================
-- Schwierigkeits-Auswahl
-- ============================================================

local function GetDiffs()
    local L = GamingHub.GetLocaleTable("CONNECT4")
    return {
        { label = L["diff_easy"],   value = "easy"   },
        { label = L["diff_normal"], value = "normal" },
        { label = L["diff_hard"],   value = "hard"   },
    }
end

function Renderer:CreateDiffContainer()
    if self.diffContainer then return end

    local container = CreateFrame("Frame", nil, self.frame)
    container:SetPoint("BOTTOM", self.frame, "BOTTOM", 80, 5)
    container:SetSize(500, 30)
    container:SetAlpha(0.4)
    self.diffContainer = container

    local W = 100
    local spacing = 20

    local DIFFS = GetDiffs()
    for i, diff in ipairs(DIFFS) do
        local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
        btn:SetSize(W, 28)
        btn:SetPoint("LEFT", container, "LEFT", (i-1)*(W+spacing), 0)
        btn:SetText(diff.label)
        btn:Disable()
        btn:SetScript("OnClick", function()
            Renderer:SetDiff(diff.value, btn)
        end)
        table.insert(self.diffBtns, btn)
    end
end

function Renderer:SetDiff(value, clicked)
    if not self.selectedMode then return end
    self.selectedDiff = value
    for _, btn in ipairs(self.diffBtns) do btn:UnlockHighlight() end
    clicked:LockHighlight()

    -- Spiel starten – VierGewinntEngine wrapper
    GamingHub.VierGewinntEngine:StartGame({
        cols         = self.selectedMode.cols,
        rows         = self.selectedMode.rows,
        aiDifficulty = self.selectedDiff,
    })
end

-- ============================================================
-- Idle / Show / Hide
-- ============================================================

function Renderer:EnterIdleState()
    self.state = "IDLE"
    self:ClearBoard()
    self:ClearWinningLine()

    for _, btn in ipairs(self.modeBtns) do btn:UnlockHighlight() end
    for _, btn in ipairs(self.diffBtns) do
        btn:UnlockHighlight()
        btn:Disable()
    end
    self.diffContainer:SetAlpha(0.4)
    self:ShowModeSelection()

    if self.exitButton then self.exitButton:Hide() end
end

function Renderer:ShowModeSelection()
    if self.modeContainer then self.modeContainer:Show() end
    if self.diffContainer  then self.diffContainer:Show()  end
end

function Renderer:HideModeSelection()
    if self.modeContainer then self.modeContainer:Hide() end
    if self.diffContainer  then self.diffContainer:Hide()  end
end

-- ============================================================
-- Exit Button
-- ============================================================

function Renderer:CreateExitButton()
    if self.exitButton then return end

    local btn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    btn:SetSize(100, 28)
    btn:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 20, 5)
    btn:SetText(GamingHub.GetLocaleTable("CONNECT4")["btn_exit"])
    btn:SetScript("OnClick", function()
        GamingHub.VierGewinntEngine:StopGame()
    end)
    btn:Hide()
    self.exitButton = btn
end

-- ============================================================
-- Overlay (Game Over)
-- ============================================================

function Renderer:CreateOverlay()
    if self.overlay then return end

    local overlay = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    local parent  = self.frame:GetParent()

    overlay:ClearAllPoints()
    overlay:SetPoint("TOPLEFT",     parent, "TOPLEFT",     3, -3)
    overlay:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -3, 3)
    overlay:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
    overlay:SetBackdropColor(0, 0, 0, 0.7)
    overlay:EnableMouse(false)
    overlay:Hide()

    local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    text:SetPoint("CENTER")
    overlay.text = text

    self.overlay = overlay
end

-- ============================================================
-- Board rendern
-- Erstellt cellButtons[row][col] und colHitFrames[col].
-- ============================================================

function Renderer:ClearBoard()
    -- Bestehende Buttons entfernen
    for row = 1, #self.cellButtons do
        for col = 1, #(self.cellButtons[row] or {}) do
            local btn = self.cellButtons[row][col]
            if btn then btn:Hide() end
        end
    end
    self.cellButtons = {}

    for col = 1, #self.colHitFrames do
        if self.colHitFrames[col] then
            self.colHitFrames[col]:Hide()
        end
    end
    self.colHitFrames = {}
end

function Renderer:RenderBoard(board)
    self:ClearBoard()
    self:ClearWinningLine()

    self.boardCols = board.cols
    self.boardRows = board.rows
    self.state     = "PLAYING"

    if self.overlay    then self.overlay:Hide()    end
    if self.exitButton then self.exitButton:Show() end

    local parent = self.frame
    local W      = parent:GetWidth()
    local H      = parent:GetHeight()

    -- Nutzbarer Bereich: 80% Breite, 75% Höhe
    local usableW = W * 0.80
    local usableH = H * 0.75

    -- Zellgröße: begrenzt durch beide Achsen damit Zellen quadratisch bleiben
    local cellByW = usableW / board.cols
    local cellByH = usableH / board.rows
    local cell    = math.min(cellByW, cellByH)

    self.cellW = cell
    self.cellH = cell

    local boardW = cell * board.cols
    local boardH = cell * board.rows

    self.boardOffsetX = (W - boardW) / 2
    self.boardOffsetY = (H - boardH) / 2

    -- ── Zell-Buttons (Steine) ──
    for row = 1, board.rows do
        self.cellButtons[row] = {}

        for col = 1, board.cols do
            local btn = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            btn:SetSize(cell - 4, cell - 4)
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT",
                self.boardOffsetX + (col-1) * cell + 2,
                -(self.boardOffsetY + (row-1) * cell + 2))

            -- Hintergrund (Spielfeld-Slot)
            btn:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
            btn:SetBackdropColor(0.05, 0.05, 0.20, 1)

            -- Runder Stein: Textur mit CircleMask wenn verfügbar
            local disc = btn:CreateTexture(nil, "ARTWORK")
            local pad  = math.floor(cell * 0.08)
            disc:SetPoint("TOPLEFT",     btn, "TOPLEFT",     pad, -pad)
            disc:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -pad, pad)
            disc:SetColorTexture(0.1, 0.1, 0.1, 1)  -- leer = dunkel
            btn.disc = disc

            -- Optional: runde Maske (nur wenn API verfügbar)
            if disc.AddMaskTexture then
                local mask = btn:CreateMaskTexture(nil, "ARTWORK")
                mask:SetAllPoints(disc)
                mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                disc:AddMaskTexture(mask)
            end

            -- FontString (Fallback, selten sichtbar)
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            text:SetPoint("CENTER")
            btn.text = text

            -- Atlas-Textur für SPRITE-Modus (Fraktions-Wappen)
            -- Bekommt dieselbe runde Maske wie disc damit Wappen als Kreis erscheinen
            local atlTex = btn:CreateTexture(nil, "OVERLAY")
            atlTex:SetPoint("TOPLEFT",     btn, "TOPLEFT",     pad, -pad)
            atlTex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -pad, pad)
            atlTex:Hide()
            if atlTex.AddMaskTexture then
                local atlMask = btn:CreateMaskTexture(nil, "OVERLAY")
                atlMask:SetAllPoints(atlTex)
                atlMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
                    "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                atlTex:AddMaskTexture(atlMask)
            end
            btn.atlTex = atlTex

            self.cellButtons[row][col] = btn
        end
    end

    -- ── Spalten-Klick-Frames ──
    -- Unsichtbare, hohe Frames über jeder Spalte für Klick + Hover
    for col = 1, board.cols do
        local hit = CreateFrame("Button", nil, parent)
        hit:SetSize(cell, board.rows * cell)
        hit:SetPoint("TOPLEFT", parent, "TOPLEFT",
            self.boardOffsetX + (col-1) * cell,
            -(self.boardOffsetY))

        hit:SetScript("OnClick", function()
            GamingHub.VierGewinntEngine:HandlePlayerMove(col)
        end)

        -- Hover: Spalte aufhellen
        hit:SetScript("OnEnter", function()
            Renderer:HighlightColumn(col, true)
        end)
        hit:SetScript("OnLeave", function()
            Renderer:HighlightColumn(col, false)
        end)

        self.colHitFrames[col] = hit
    end

    self:UpdateBoard()
end

-- ============================================================
-- Spalten-Highlight beim Hover
-- ============================================================

function Renderer:HighlightColumn(col, on)
    for row = 1, self.boardRows do
        local btn = self.cellButtons[row] and self.cellButtons[row][col]
        if btn then
            if on then
                btn:SetBackdropColor(0.15, 0.15, 0.40, 1)
            else
                btn:SetBackdropColor(0.05, 0.05, 0.20, 1)
            end
        end
    end
end

-- ============================================================
-- Board aktualisieren
-- ============================================================

function Renderer:UpdateBoard()
    local game = GamingHub.VierGewinntEngine
        and GamingHub.VierGewinntEngine.activeGame
    if not game then return end

    local board   = game:GetBoardState()
    local symbols = { player1 = nil, player2 = nil }

    if GamingHub.VierGewinntSymbolResolver then
        symbols = GamingHub.VierGewinntSymbolResolver:Resolve()
    else
        symbols.player1 = { mode="TEXT", text="●", r=1.00, g=0.85, b=0.00 }
        symbols.player2 = { mode="TEXT", text="●", r=1.00, g=0.15, b=0.15 }
    end

    for row = 1, board.rows do
        for col = 1, board.cols do
            local btn   = self.cellButtons[row] and self.cellButtons[row][col]
            local value = board.cells[row][col]
            if btn then
                if value == 1 then
                    ApplySymbol(btn, symbols.player1)
                elseif value == 2 then
                    ApplySymbol(btn, symbols.player2)
                else
                    -- Leere Zelle
                    btn.disc:SetColorTexture(0.1, 0.1, 0.1, 1)
                    btn.text:SetText("")
                    if btn.atlTex then btn.atlTex:Hide() end
                end
            end
        end
    end
end

-- ============================================================
-- Game Over
-- ============================================================

function Renderer:ShowGameOver(result)
    self.state      = "GAMEOVER"
    self.lastResult = result

    local L = GamingHub.GetLocaleTable("CONNECT4")
    if result == "WIN" then
        self.overlay.text:SetText(L["result_win"])
    elseif result == "LOSS" then
        self.overlay.text:SetText(L["result_loss"])
    else
        self.overlay.text:SetText(L["result_draw"])
    end

    -- Spalten-Klick deaktivieren
    for col = 1, #self.colHitFrames do
        if self.colHitFrames[col] then
            self.colHitFrames[col]:Disable()
        end
    end

    self.overlay:SetAlpha(0)
    self.overlay:Show()
    UIFrameFadeIn(self.overlay, 0.3, 0, 0.7)

    self:ShowModeSelection()
    PlayGameSound(result)
end

-- ============================================================
-- Winning Line
-- Nutzt col/row statt x/y → Pixel-Position berechnen
-- ============================================================

function Renderer:ClearWinningLine()
    if self.winLineTexture then
        if self.winLineTexture.pulseAnim then
            self.winLineTexture.pulseAnim:Stop()
        end
        self.winLineTexture:Hide()
    end
end

function Renderer:HighlightWinningLine(line)
    if not line or #line < 2 then return end

    local cell = self.cellW  -- Zellen sind quadratisch

    -- Mitte des ersten und letzten Steins (in Pixel relativ zu TOPLEFT des Frames)
    local p1 = line[1]
    local p2 = line[#line]

    -- Pixel-Mitte einer Zelle: offset + (index - 0.5) * cell
    local x1 = self.boardOffsetX + (p1.col - 0.5) * cell
    local y1 = self.boardOffsetY + (p1.row - 0.5) * cell
    local x2 = self.boardOffsetX + (p2.col - 0.5) * cell
    local y2 = self.boardOffsetY + (p2.row - 0.5) * cell

    local dx     = x2 - x1
    local dy     = y1 - y2  -- WoW Y-Achse ist invertiert
    local length = math.sqrt(dx*dx + dy*dy)
    local cx     = (x1 + x2) / 2
    local cy     = (y1 + y2) / 2
    local angle  = math.atan2(dy, dx)

    if not self.winLineFrame then
        local frame = CreateFrame("Frame", nil, self.frame)
        frame:SetAllPoints(self.frame)
        frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel(self.frame:GetFrameLevel() + 150)
        self.winLineFrame = frame

        local tex = frame:CreateTexture(nil, "OVERLAY")
        self.winLineTexture = tex
    end

    local tex = self.winLineTexture

    if tex.pulseAnim then tex.pulseAnim:Stop() end

    if self.lastResult == "LOSS" then
        tex:SetColorTexture(1, 0, 0, 0.9)
    else
        tex:SetColorTexture(0, 1, 0, 0.9)
    end

    tex:SetSize(length, 8)
    tex:SetPoint("CENTER", self.frame, "TOPLEFT", cx, -cy)
    tex:SetRotation(angle)
    tex:SetAlpha(1)
    tex:Show()

    -- Pulse-Animation
    local pulse = tex:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(0.35)
    fade:SetToAlpha(1)
    fade:SetDuration(0.5)
    fade:SetSmoothing("IN_OUT")
    tex.pulseAnim = pulse
    pulse:Play()
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "CONNECT4",
    label     = "Vier Gewinnt",
    renderer  = "VierGewinntRenderer",
    engine    = "VierGewinntEngine",
    container = "_vgContainer",
})
