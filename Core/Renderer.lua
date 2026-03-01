--[[
    Gaming Hub
    Renderer.lua
    Version: 1.4.0 (Symbol-System + Sounds)

    Änderungen gegenüber 1.3.0:
      - UpdateBoard: Symbole werden über TicTacToeSymbolResolver bestimmt
        → TEXT-Modus: FontString mit Farbe (X / O)
        → ATLAS-Modus: SetAtlas() auf einer Textur im Button
      - RenderBoard: Jede Zelle bekommt zusätzlich eine Atlas-Textur (symbol.atlas)
        die je nach Modus gezeigt oder versteckt wird
      - ShowGameOver: PlaySound() für WIN / LOSS / DRAW
        (nur wenn TicTacToeSettings soundEnabled = true)
]]

local GamingHub = _G.GamingHub
GamingHub.Renderer = {}

local Renderer = GamingHub.Renderer

Renderer.buttons           = {}
Renderer.frame             = nil
Renderer.overlay           = nil

Renderer.boardSizeContainer  = nil
Renderer.difficultyContainer = nil
Renderer.exitButton          = nil

Renderer.boardSize           = 3
Renderer.selectedBoardSize   = nil
Renderer.selectedDifficulty  = nil

Renderer.boardSizeButtons    = {}
Renderer.difficultyButtons   = {}

Renderer.winLineTexture      = nil
Renderer.winLineFrame        = nil

Renderer.boardPixelSize      = 0
Renderer.boardStartX         = 0
Renderer.boardStartY         = 0

Renderer.state               = "IDLE"
Renderer.lastResult          = nil

-- ============================================================
-- Sound-Definitionen
-- Die originalen IDs (569593 etc.) sind FileDataIDs → PlaySoundFile()
-- Für PlaySound() werden SoundKitIDs benötigt:
--   LEVELUP      SoundKitID: 888
--   RaidWarning  SoundKitID: 8959
--   igQuestFailed FileDataID: 567459 → PlaySoundFile()
-- ============================================================

-- SoundKitIDs – verifiziert auf wowhead.com (alle aktuell in 12.0.1):
--   LEVELUP       = 888   → /run PlaySound(888)
--   RaidWarning   = 8959  → /run PlaySound(8959)
--   igQuestFailed = 847   → /run PlaySound(847)
local SOUND_WIN  = 888   -- SoundKitID: LEVELUP
local SOUND_DRAW = 8959  -- SoundKitID: RaidWarning
local SOUND_LOSS = 847   -- SoundKitID: igQuestFailed

-- ============================================================
-- INTERNE: Sound abspielen wenn in Settings aktiv
-- ============================================================

local function PlayGameSound(result)
    local S = GamingHub.TicTacToeSettings
    if not S then return end
    if not S:Get("soundEnabled") then return end

    if result == "WIN" and S:Get("soundOnWin") then
        PlaySound(SOUND_WIN, "SFX")
    elseif result == "DRAW" and S:Get("soundOnDraw") then
        PlaySound(SOUND_DRAW, "SFX")
    elseif result == "LOSS" and S:Get("soundOnLoss") then
        PlaySound(SOUND_LOSS, "SFX")
    end
end

-- ============================================================
-- INTERNE: Symbol auf einen Button anwenden
-- btn.text    = FontString (TEXT-Modus)
-- btn.atlTex  = Textur     (ATLAS-Modus)
-- symbolDef   = { mode, text?, r?, g?, b?, atlas? }
-- ============================================================

local function ApplySymbol(btn, symbolDef)
    if not symbolDef then
        btn.text:SetText("")
        btn.atlTex:Hide()
        return
    end

    if symbolDef.mode == "TEXT" then
        btn.atlTex:Hide()
        btn.text:SetText(symbolDef.text or "")
        btn.text:SetTextColor(
            symbolDef.r or 1,
            symbolDef.g or 1,
            symbolDef.b or 1,
            1
        )

    elseif symbolDef.mode == "SPRITE" then
        -- Sprite-Ausschnitt aus einer Textur via SetTexCoord
        -- Genutzt für Fraktions-Wappen aus UI-CharacterCreate-Factions.blp
        btn.text:SetText("")
        btn.atlTex:SetTexture(symbolDef.path)
        btn.atlTex:SetTexCoord(
            symbolDef.left,
            symbolDef.right,
            symbolDef.top,
            symbolDef.bottom
        )
        btn.atlTex:Show()

    else
        btn.text:SetText("")
        btn.atlTex:Hide()
    end
end

-- ============================================================
-- Init
-- ============================================================

function Renderer:Init()
    self:CreateMainFrame()
    self:CreateOverlay()
    self:CreateBoardSizeContainer()
    self:CreateDifficultyContainer()
    self:CreateExitButton()

    self:EnterIdleState()

    local Engine = GamingHub.Engine

    Engine:On("GAME_STARTED", function(board)
        Renderer.state = "PLAYING"
        Renderer:HideModeSelection()
        Renderer:RenderBoard(board)
    end)

    Engine:On("BOARD_UPDATED", function()
        Renderer:UpdateBoard()
    end)

    Engine:On("GAME_OVER", function(result)
        Renderer:ShowGameOver(result)
    end)

    Engine:On("WIN_LINE", function(line)
        Renderer:HighlightWinningLine(line)
    end)

    Engine:On("GAME_STOPPED", function()
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
        -- Eigener Sub-Frame damit TicTacToe und andere Spiele
        -- sich nicht gegenseitig überschneiden.
        local container = CreateFrame("Frame", "GamingHub_TTT_Container", gamesPanel)
        container:SetAllPoints(gamesPanel)
        container:Hide()  -- wird nur gezeigt wenn TicTacToe aktiv
        self.frame = container
        -- Referenz für UI-Routing
        if _G.GamingHub then
            _G.GamingHub._tttContainer = container
        end
    end
end

-- ============================================================
-- Board Size Selection
-- ============================================================

function Renderer:CreateBoardSizeContainer()

    if self.boardSizeContainer then return end

    local container = CreateFrame("Frame", nil, self.frame)
    container:SetPoint("BOTTOM", self.frame, "BOTTOM", 80, 35)
    container:SetSize(500, 30)

    self.boardSizeContainer = container

    local sizes   = {3, 4, 5}
    local spacing = 20
    local width   = 100

    for i, size in ipairs(sizes) do
        local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
        btn:SetSize(width, 28)
        btn:SetPoint("LEFT", container, "LEFT", (i-1)*(width+spacing), 0)
        btn:SetText(size.."x"..size)
        btn:SetScript("OnClick", function()
            Renderer:SetBoardSize(size, btn)
        end)
        table.insert(self.boardSizeButtons, btn)
    end
end

function Renderer:SetBoardSize(size, clicked)
    self.selectedBoardSize = size
    for _, btn in ipairs(self.boardSizeButtons) do btn:UnlockHighlight() end
    clicked:LockHighlight()
    self.difficultyContainer:SetAlpha(1)
    for _, btn in ipairs(self.difficultyButtons) do btn:Enable() end
end

-- ============================================================
-- Difficulty Selection
-- ============================================================

function Renderer:CreateDifficultyContainer()

    if self.difficultyContainer then return end

    local container = CreateFrame("Frame", nil, self.frame)
    container:SetPoint("BOTTOM", self.frame, "BOTTOM", 80, 5)
    container:SetSize(500, 30)

    self.difficultyContainer = container
    container:SetAlpha(0.4)

    local diffs = {
        { label="Classic", value="easy"   },
        { label="Pro",     value="normal" },
        { label="Insane",  value="hard"   },
    }

    local spacing = 20
    local width   = 100

    for i, diff in ipairs(diffs) do
        local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
        btn:SetSize(width, 28)
        btn:SetPoint("LEFT", container, "LEFT", (i-1)*(width+spacing), 0)
        btn:SetText(diff.label)
        btn:Disable()
        btn:SetScript("OnClick", function()
            Renderer:SetDifficulty(diff.value, btn)
        end)
        table.insert(self.difficultyButtons, btn)
    end
end

function Renderer:SetDifficulty(value, clicked)
    if not self.selectedBoardSize then return end
    self.selectedDifficulty = value
    for _, btn in ipairs(self.difficultyButtons) do btn:UnlockHighlight() end
    clicked:LockHighlight()
    GamingHub.Engine:StartGame("TICTACTOE", {
        boardSize    = self.selectedBoardSize,
        winLength    = self.selectedBoardSize,
        aiDifficulty = self.selectedDifficulty,
    })
end

-- ============================================================
-- Mode Visibility
-- ============================================================

function Renderer:HideModeSelection()
    if self.boardSizeContainer  then self.boardSizeContainer:Hide()  end
    if self.difficultyContainer then self.difficultyContainer:Hide() end
end

function Renderer:ShowModeSelection()
    if self.boardSizeContainer  then self.boardSizeContainer:Show()  end
    if self.difficultyContainer then self.difficultyContainer:Show() end
end

-- ============================================================
-- State Handling
-- ============================================================

function Renderer:ClearWinningLine()
    if self.winLineTexture then
        if self.winLineTexture.pulseAnim then
            self.winLineTexture.pulseAnim:Stop()
        end
        self.winLineTexture:Hide()
    end
end

function Renderer:EnterIdleState()
    self.state              = "IDLE"
    self.selectedBoardSize  = nil
    self.selectedDifficulty = nil

    if self.overlay then self.overlay:Hide() end
    self:ClearWinningLine()

    for _, btn in ipairs(self.buttons) do btn:Hide() end

    for _, btn in ipairs(self.boardSizeButtons) do
        btn:UnlockHighlight()
    end

    for _, btn in ipairs(self.difficultyButtons) do
        btn:UnlockHighlight()
        btn:Disable()
    end

    self.difficultyContainer:SetAlpha(0.4)
    self:ShowModeSelection()

    if self.exitButton then self.exitButton:Hide() end
end

-- ============================================================
-- Exit Button
-- ============================================================

function Renderer:CreateExitButton()
    if self.exitButton then return end

    local btn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    btn:SetSize(100, 28)
    btn:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 20, 5)
    btn:SetText("Beenden")
    btn:SetScript("OnClick", function()
        GamingHub.Engine:StopGame()
    end)
    btn:Hide()
    self.exitButton = btn
end

-- ============================================================
-- Overlay
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
-- Render Board
-- Erstellt alle Zell-Buttons mit FontString (Text) UND
-- Atlas-Textur (Wappen). Immer beide vorbereiten –
-- ApplySymbol() entscheidet beim Update welcher aktiv ist.
-- ============================================================

function Renderer:RenderBoard(board)
    self:ClearWinningLine()

    self.boardSize = board.size
    self.state     = "PLAYING"

    if self.overlay    then self.overlay:Hide()    end
    if self.exitButton then self.exitButton:Show() end

    for _, btn in ipairs(self.buttons) do btn:Hide() end
    self.buttons = {}

    local parent   = self.frame
    local width    = parent:GetWidth()
    local height   = parent:GetHeight()

    local usableSize = math.min(width, height) * 0.75
    local cellSize   = usableSize / self.boardSize

    self.boardPixelSize = cellSize * self.boardSize
    self.boardStartX    = (width  - self.boardPixelSize) / 2
    self.boardStartY    = (height - self.boardPixelSize) / 2

    for y = 1, self.boardSize do
        for x = 1, self.boardSize do

            local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
            btn:SetSize(cellSize - 4, cellSize - 4)
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT",
                self.boardStartX + (x-1) * cellSize,
                -(self.boardStartY + (y-1) * cellSize))

            btn:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
            btn:SetBackdropColor(0.15, 0.15, 0.15, 1)

            btn:SetScript("OnClick", function()
                GamingHub.Engine:HandlePlayerMove(x, y)
            end)

            -- FontString für TEXT-Modus
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            text:SetPoint("CENTER")
            btn.text = text

            -- Textur für ATLAS-Modus (Fraktions-Wappen)
            -- Padding damit das Wappen nicht ganz an den Rand geht
            local atlasPad = math.floor(cellSize * 0.12)
            local atlTex   = btn:CreateTexture(nil, "ARTWORK")
            atlTex:SetPoint("TOPLEFT",     btn, "TOPLEFT",     atlasPad, -atlasPad)
            atlTex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -atlasPad, atlasPad)
            atlTex:Hide()
            btn.atlTex = atlTex

            table.insert(self.buttons, btn)
        end
    end

    self:UpdateBoard()
end

-- ============================================================
-- Update Board
-- Fragt SymbolResolver nach den aktuellen Symboldefinitionen
-- und wendet sie auf jeden belegten Button an.
-- ============================================================

function Renderer:UpdateBoard()

    local board = GamingHub.Engine.activeGame
        and GamingHub.Engine.activeGame:GetBoardState()
    if not board then return end

    -- Symbole einmal pro Update-Zyklus auflösen (nicht pro Zelle)
    local symbols = { player1 = nil, player2 = nil }
    if GamingHub.TicTacToeSymbolResolver then
        symbols = GamingHub.TicTacToeSymbolResolver:Resolve()
    else
        -- Fallback: kein Resolver geladen → X / O
        symbols.player1 = { mode="TEXT", text="X", r=0.20, g=0.60, b=1.00 }
        symbols.player2 = { mode="TEXT", text="O", r=1.00, g=0.25, b=0.25 }
    end

    local index = 1

    for y = 1, board.size do
        for x = 1, board.size do

            local value = board.cells[y][x]
            local btn   = self.buttons[index]

            if value == 1 then
                ApplySymbol(btn, symbols.player1)
            elseif value == 2 then
                ApplySymbol(btn, symbols.player2)
            else
                -- Leere Zelle: beide zurücksetzen
                btn.text:SetText("")
                btn.atlTex:Hide()
            end

            index = index + 1
        end
    end
end

-- ============================================================
-- Game Over
-- ============================================================

function Renderer:ShowGameOver(result)

    self.state      = "GAMEOVER"
    self.lastResult = result

    if result == "WIN" then
        self.overlay.text:SetText("You Win!")
    elseif result == "LOSS" then
        self.overlay.text:SetText("You Lose!")
    else
        self.overlay.text:SetText("Draw!")
    end

    for _, btn in ipairs(self.buttons) do btn:Disable() end

    self.overlay:SetAlpha(0)
    self.overlay:Show()
    UIFrameFadeIn(self.overlay, 0.3, 0, 0.7)

    self:ShowModeSelection()

    -- Sound abspielen (prüft intern ob aktiviert)
    PlayGameSound(result)
end

-- ============================================================
-- Winning Line
-- ============================================================

function Renderer:HighlightWinningLine(line)

    if not line or #line < 2 then return end

    local cellSize = self.boardPixelSize / self.boardSize

    local p1 = line[1]
    local p2 = line[#line]

    local startX = self.boardStartX + (p1.x - 0.5) * cellSize
    local startY = self.boardStartY + (p1.y - 0.5) * cellSize
    local endX   = self.boardStartX + (p2.x - 0.5) * cellSize
    local endY   = self.boardStartY + (p2.y - 0.5) * cellSize

    local dx     = endX - startX
    local dy     = startY - endY
    local length = math.sqrt(dx*dx + dy*dy)
    local centerX = (startX + endX) / 2
    local centerY = (startY + endY) / 2
    local angle   = math.atan2(dy, dx)

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

    tex:SetSize(length, 6)
    tex:SetPoint("CENTER", self.frame, "TOPLEFT", centerX, -centerY)
    tex:SetRotation(angle)
    tex:SetAlpha(1)
    tex:Show()

    local pulse = tex:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")

    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(0.4)
    fade:SetToAlpha(1)
    fade:SetDuration(0.5)
    fade:SetSmoothing("IN_OUT")

    tex.pulseAnim = pulse
    pulse:Play()
end
