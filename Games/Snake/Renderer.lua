--[[
    Gaming Hub – Snake
    Games/Snake/Renderer.lua

    Layout:
    ┌──────────────────────────────────────────────┐
    │ Score: 0    Highscore: 0    [Thema]          │  ← StatusBar
    │ ┌──────────────────────────────────────────┐ │
    │ │                                          │ │
    │ │          Spielfeld (zentriert)           │ │
    │ │                                          │ │
    │ └──────────────────────────────────────────┘ │
    │  [Easy] [Normal] [Hard]                       │  ← DiffButtons
    │  [Beenden]                   [Neues Spiel]    │  ← BottomButtons
    └──────────────────────────────────────────────┘

    Architektur:
    - Jede Zelle ist ein Frame in einem 2D-Array self.cells[r][c]
    - OnTick() aktualisiert nur geänderte Zellen (Kopf, altes Schwanzende, Futter)
    - Kein vollständiges Redraw jedes Tick
    - Tastatureingabe via SetScript("OnKeyDown") auf self.keyFrame (unsichtbares Frame)
]]

local GamingHub = _G.GamingHub
GamingHub.SNK_Renderer = {}
local R = GamingHub.SNK_Renderer

R.frame         = nil
R.state         = "IDLE"
R.gridHolder    = nil
R.cells         = {}       -- cells[r][c] = Frame
R.diffBtns      = {}
R.diffContainer = nil
R.exitButton    = nil
R.newGameButton = nil
R.statusFS      = nil
R.scoreFS       = nil
R.highscoreFS   = nil
R.hintFS        = nil
R.overlay       = nil
R.keyFrame      = nil      -- unsichtbares Frame für KeyDown-Events
R._currentDiff  = nil
R._currentTheme = nil
R._lastBoard    = nil

-- ============================================================
-- Hilfsfunktion: Textur auf Zelle setzen
-- ============================================================
local function SetCellTexture(cell, icon, r, g, b)
    if not cell or not cell.tex then return end
    if icon then
        cell.tex:SetTexture(icon)
        cell.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        cell.tex:SetVertexColor(r or 1, g or 1, b or 1)
        cell.tex:Show()
    else
        cell.tex:Hide()
    end
end

local function ClearCell(cell)
    if not cell then return end
    if cell.tex then cell.tex:Hide() end
    if cell.bg  then cell.bg:SetVertexColor(0.08, 0.08, 0.10, 1) end
end

-- ============================================================
-- Init
-- ============================================================
function R:Init()
    self:CreateMainFrame()
    self:CreateStatusBar()
    self:CreateDiffButtons()
    self:CreateBottomButtons()
    self:CreateKeyFrame()
    self:CreateOverlay()
    self:EnterIdleState()

    local Eng = GamingHub.Engine
    Eng:On("SNK_GAME_STARTED", function(b)        R:OnGameStarted(b)        end)
    Eng:On("SNK_GAME_STOPPED", function()          R:EnterIdleState()        end)
end

-- ============================================================
-- CreateMainFrame
-- ============================================================
function R:CreateMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end
    local f = CreateFrame("Frame", "GamingHub_SNK_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    self.frame = f
    if _G.GamingHub then _G.GamingHub._snkContainer = f end
end

-- ============================================================
-- CreateKeyFrame – fängt WASD + Pfeiltasten ab
-- ============================================================
function R:CreateKeyFrame()
    if self.keyFrame then return end
    local kf = CreateFrame("Frame", nil, self.frame)
    kf:SetAllPoints(self.frame)
    kf:SetPropagateKeyboardInput(false)
    kf:EnableKeyboard(true)
    kf:SetScript("OnKeyDown", function(_, key)
        local mapped = {
            w="W", a="A", s="S", d="D",
            W="W", A="A", S="S", D="D",
            UP="UP", DOWN="DOWN", LEFT="LEFT", RIGHT="RIGHT",
        }
        local k = mapped[key]
        if k then GamingHub.SNK_Engine:HandleKey(k) end
    end)
    kf:Hide()
    self.keyFrame = kf
end

-- ============================================================
-- BuildGrid – erstellt das Zellen-Array
-- ============================================================
function R:BuildGrid(board)
    self:ClearGrid()

    local T       = GamingHub.SNK_Themes
    local diff    = T:GetDiff(board.difficulty)
    local g       = diff.gridSize
    local cs      = diff.cellSize   -- Zellgröße in Pixel
    local gap     = 1               -- 1px Lücke zwischen Zellen
    local totalPx = g * cs + (g-1) * gap

    local panelW  = self.frame:GetWidth()  or 580
    local panelH  = self.frame:GetHeight() or 700
    -- Zentrieren: oben 28px StatusBar, unten 46px Diff + 46px Buttons
    local reservedH = 28 + 46 + 46
    local availH    = panelH - reservedH

    local offX = math.floor((panelW - totalPx) / 2)
    local offY = 28 + math.floor((availH - totalPx) / 2)

    local holder = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    holder:SetPoint("TOPLEFT", self.frame, "TOPLEFT", offX, -offY)
    holder:SetSize(totalPx, totalPx)
    -- Hintergrundfarbe für das gesamte Grid
    holder:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 2,
        insets = { left=2, right=2, top=2, bottom=2 },
    })
    holder:SetBackdropColor(0.05, 0.06, 0.05, 1)
    holder:SetBackdropBorderColor(0.25, 0.35, 0.20, 1)
    self.gridHolder = holder

    self.cells = {}
    for row = 1, g do
        self.cells[row] = {}
        for col = 1, g do
            local cx = (col-1) * (cs + gap)
            local cy = (row-1) * (cs + gap)

            local cell = CreateFrame("Frame", nil, holder)
            cell:SetSize(cs, cs)
            cell:SetPoint("TOPLEFT", holder, "TOPLEFT", cx, -cy)

            -- Hintergrund der Zelle
            local bg = cell:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetVertexColor(0.08, 0.08, 0.10, 1)
            cell.bg = bg

            -- Icon-Textur (initial versteckt)
            local tex = cell:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:Hide()
            cell.tex = tex

            self.cells[row][col] = cell
        end
    end

    -- Initiales Rendering: Schlange + Futter zeichnen
    self:RenderFull(board)
end

-- ============================================================
-- RenderFull – komplett neu zeichnen (nach Spielstart)
-- ============================================================
function R:RenderFull(board)
    local T     = GamingHub.SNK_Themes
    local theme = T:GetTheme(board.theme)
    local g     = board.gridSize

    -- Alle Zellen leeren
    for r = 1, g do
        for c = 1, g do
            ClearCell(self.cells[r] and self.cells[r][c])
        end
    end

    -- Schlange zeichnen
    for i, seg in ipairs(board.snake) do
        local cell = self.cells[seg.r] and self.cells[seg.r][seg.c]
        if cell then
            if i == 1 then
                -- Kopf
                local h = theme.head
                SetCellTexture(cell, h.icon, h.color[1], h.color[2], h.color[3])
                cell.bg:SetVertexColor(h.color[1]*0.3, h.color[2]*0.3, h.color[3]*0.3, 1)
            else
                -- Körper
                local b = theme.body
                SetCellTexture(cell, b.icon, b.color[1], b.color[2], b.color[3])
                cell.bg:SetVertexColor(b.color[1]*0.15, b.color[2]*0.15, b.color[3]*0.15, 1)
            end
        end
    end

    -- Futter zeichnen
    if board.food then
        local fc = self.cells[board.food.r] and self.cells[board.food.r][board.food.c]
        if fc then
            local f = theme.food
            SetCellTexture(fc, f.icon, f.color[1], f.color[2], f.color[3])
            fc.bg:SetVertexColor(f.color[1]*0.2, f.color[2]*0.2, f.color[3]*0.2, 1)
        end
    end
end

-- ============================================================
-- OnTick – nur geänderte Zellen aktualisieren
-- ============================================================
function R:OnTick(board, result)
    local T     = GamingHub.SNK_Themes
    local theme = T:GetTheme(board.theme)

    -- Kopf (Segment [1]) immer aktualisieren
    local head = board.snake[1]
    local hCell = self.cells[head.r] and self.cells[head.r][head.c]
    if hCell then
        local h = theme.head
        SetCellTexture(hCell, h.icon, h.color[1], h.color[2], h.color[3])
        hCell.bg:SetVertexColor(h.color[1]*0.3, h.color[2]*0.3, h.color[3]*0.3, 1)
    end

    -- Segment [2] wurde zum Körper (war vorher Kopf)
    if board.snake[2] then
        local seg2 = board.snake[2]
        local s2Cell = self.cells[seg2.r] and self.cells[seg2.r][seg2.c]
        if s2Cell then
            local b = theme.body
            SetCellTexture(s2Cell, b.icon, b.color[1], b.color[2], b.color[3])
            s2Cell.bg:SetVertexColor(b.color[1]*0.15, b.color[2]*0.15, b.color[3]*0.15, 1)
        end
    end

    if result == "ate" then
        -- Futter wurde gefressen: neues Futter zeichnen
        if board.food then
            local fc = self.cells[board.food.r] and self.cells[board.food.r][board.food.c]
            if fc then
                local f = theme.food
                SetCellTexture(fc, f.icon, f.color[1], f.color[2], f.color[3])
                fc.bg:SetVertexColor(f.color[1]*0.2, f.color[2]*0.2, f.color[3]*0.2, 1)
            end
        end
    elseif result == "moved" then
        -- Schwanzende (letzte Position vor dem Tick) leeren
        -- Die Logik hat den Schwanz schon entfernt, wir brauchen
        -- die alte Schwanzposition. Da Logic.Tick Schwanz entfernt hat,
        -- ist die alte Position nicht mehr in board.snake. Wir nutzen
        -- _lastTail den wir vorher speichern.
        if self._lastTail then
            local lt = self._lastTail
            local ltCell = self.cells[lt.r] and self.cells[lt.r][lt.c]
            -- Nur leeren wenn nicht gerade Kopf/Körper oder Futter drauf
            if ltCell then
                local isSnake = false
                for _, seg in ipairs(board.snake) do
                    if seg.r == lt.r and seg.c == lt.c then isSnake = true; break end
                end
                local isFood = board.food and board.food.r == lt.r and board.food.c == lt.c
                if not isSnake and not isFood then
                    ClearCell(ltCell)
                end
            end
        end
    end

    -- Score aktualisieren
    self:UpdateScore(board)
end

-- ============================================================
-- _lastTail Tracking: Engine ruft uns pro Tick auf, aber wir
-- müssen den alten Schwanz vor dem Tick kennen.
-- Lösung: Renderer speichert ihn vor jedem Tick selbst.
-- ============================================================
function R:PreTick(board)
    local snake = board.snake
    self._lastTail = snake[#snake] and { r=snake[#snake].r, c=snake[#snake].c }
end

-- ============================================================
-- ClearGrid
-- ============================================================
function R:ClearGrid()
    self.cells   = {}
    self._lastBoard = nil
    self._lastTail  = nil
    if self.gridHolder then
        self.gridHolder:Hide()
        self.gridHolder:SetParent(nil)
        self.gridHolder = nil
    end
end

-- ============================================================
-- CreateStatusBar
-- ============================================================
function R:CreateStatusBar()
    if self.scoreFS then return end
    local f = self.frame

    -- Score: oben links
    self.scoreFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.scoreFS:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
    self.scoreFS:Hide()

    -- Highscore: oben rechts (über dem Spielfeld)
    self.highscoreFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.highscoreFS:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    self.highscoreFS:SetJustifyH("RIGHT")
    self.highscoreFS:Hide()

    -- Thema: zweite Zeile links
    self.statusFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.statusFS:SetPoint("TOPLEFT", self.scoreFS, "BOTTOMLEFT", 0, -2)
    self.statusFS:Hide()
end

function R:UpdateScore(board)
    if self.scoreFS then
        self.scoreFS:SetText(string.format(
            GamingHub.GetLocaleTable("SNAKE")["status_score"], board.score))
        self.scoreFS:Show()
    end
    if self.highscoreFS then
        local hs = GamingHub.SNK_Settings:GetHighscore(board.difficulty)
        self.highscoreFS:SetText(string.format(
            GamingHub.GetLocaleTable("SNAKE")["status_best"], hs))
        self.highscoreFS:Show()
    end
    if self.statusFS then
        local T     = GamingHub.SNK_Themes
        local tName = T:GetTheme(board.theme).name
        self.statusFS:SetText("|cff888888" .. tName .. "|r")
        self.statusFS:Show()
    end
end

-- ============================================================
-- CreateDiffButtons
-- ============================================================
local function GetDiffs()
    local L = GamingHub.GetLocaleTable("SNAKE")
    return {
        { label = L["diff_easy"],   value = "easy"   },
        { label = L["diff_normal"], value = "normal" },
        { label = L["diff_hard"],   value = "hard"   },
    }
end

function R:CreateDiffButtons()
    if self.diffContainer then return end
    local c = CreateFrame("Frame", nil, self.frame)
    c:SetPoint("BOTTOMLEFT",  self.frame, "BOTTOMLEFT",  8, 46)
    c:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 46)
    c:SetHeight(28)
    self.diffContainer = c

    local W = 76; local SP = 6
    local DIFFS = GetDiffs()
    local totalBtnW = #DIFFS * W + (#DIFFS-1) * SP
    local startOff  = -math.floor(totalBtnW / 2)
    for i, d in ipairs(DIFFS) do
        local btn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        btn:SetSize(W, 26)
        btn:SetPoint("CENTER", c, "CENTER",
            startOff + (i-1)*(W+SP) + math.floor(W/2), 0)
        btn:SetText(d.label)
        btn:SetScript("OnClick", function()
            GamingHub.SNK_Settings:Set("difficulty", d.value)
            self._currentDiff = d.value
            self:RefreshDiffHighlight(btn)
            self:StartNewGame()
        end)
        self.diffBtns[i] = btn
    end
end

function R:RefreshDiffHighlight(clicked)
    for _, b in ipairs(self.diffBtns) do b:UnlockHighlight() end
    if clicked then clicked:LockHighlight() end
end

-- ============================================================
-- CreateBottomButtons
-- ============================================================
function R:CreateBottomButtons()
    if self.exitButton then return end
    local exit = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    exit:SetSize(90, 26)
    exit:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 10)
    exit:SetText(GamingHub.GetLocaleTable("SNAKE")["btn_exit"])
    exit:SetScript("OnClick", function() GamingHub.SNK_Engine:StopGame() end)
    exit:Hide()
    self.exitButton = exit

    local ng = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    ng:SetSize(110, 26)
    ng:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 10)
    ng:SetText(GamingHub.GetLocaleTable("SNAKE")["btn_new_game"])
    ng:SetScript("OnClick", function() R:StartNewGame() end)
    ng:Hide()
    self.newGameButton = ng
end

-- ============================================================
-- StartNewGame
-- ============================================================
function R:StartNewGame()
    local S = GamingHub.SNK_Settings
    GamingHub.SNK_Engine:StartGame({
        difficulty = self._currentDiff  or S:Get("difficulty"),
        theme      = self._currentTheme or S:Get("theme"),
    })
end

-- ============================================================
-- Game-Event-Handler
-- ============================================================
function R:OnGameStarted(board)
    self.state = "PLAYING"
    if self.overlay      then self.overlay:Hide()       end
    if self.hintFS       then self.hintFS:Hide()        end
    if self.exitButton   then self.exitButton:Show()    end
    if self.newGameButton then self.newGameButton:Show() end
    if self.keyFrame     then self.keyFrame:Show()      end
    self:BuildGrid(board)
    self:UpdateScore(board)
end

function R:OnGameLost(board, isNewHighscore)
    self.state = "LOST"
    if self.keyFrame then self.keyFrame:Hide() end
    self:ShowOverlay(false, board, isNewHighscore)
end

function R:OnGameWon(board, isNewHighscore)
    self.state = "WON"
    if self.keyFrame then self.keyFrame:Hide() end
    self:ShowOverlay(true, board, isNewHighscore)
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
    title:SetPoint("CENTER", ov, "CENTER", 0, 70)
    ov.title = title

    local sub = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -10)
    sub:SetJustifyH("CENTER")
    ov.sub = sub

    local sub2 = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub2:SetPoint("TOP", sub, "BOTTOM", 0, -6)
    sub2:SetJustifyH("CENTER")
    ov.sub2 = sub2

    local btn = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
    btn:SetSize(160, 28)
    btn:SetPoint("TOP", sub2, "BOTTOM", 0, -16)
    btn:SetText(GamingHub.GetLocaleTable("SNAKE")["btn_new_game_ov"])
    btn:SetScript("OnClick", function() ov:Hide(); R:StartNewGame() end)
    self.overlay = ov
end

function R:ShowOverlay(won, board, isNewHighscore)
    local ov = self.overlay
    if not ov then return end
    if won then
        local _LW = GamingHub.GetLocaleTable("SNAKE")
        ov.title:SetText(_LW["result_win_title"])
    else
        local _LL = GamingHub.GetLocaleTable("SNAKE")
        ov.title:SetText(_LL["result_loss_title"])
    end
    local T   = GamingHub.SNK_Themes
    local diff = T:GetDiff(board.difficulty)
    local _LS = GamingHub.GetLocaleTable("SNAKE")
    ov.sub:SetText(string.format(_LS["result_sub"], board.score, #board.snake))
    if isNewHighscore then
        ov.sub2:SetText(GamingHub.GetLocaleTable("SNAKE")["result_new_hs"])
    else
        local hs = GamingHub.SNK_Settings:GetHighscore(board.difficulty)
        ov.sub2:SetText(string.format(GamingHub.GetLocaleTable("SNAKE")["result_hs"], hs))
    end
    ov:SetAlpha(0); ov:Show()
    UIFrameFadeIn(ov, 0.5, 0, 0.88)
end

-- ============================================================
-- EnterIdleState
-- ============================================================
function R:EnterIdleState()
    self.state = "IDLE"
    self:ClearGrid()
    if self.overlay       then self.overlay:Hide()       end
    if self.exitButton    then self.exitButton:Hide()    end
    if self.newGameButton then self.newGameButton:Hide() end
    if self.scoreFS       then self.scoreFS:Hide()       end
    if self.highscoreFS   then self.highscoreFS:Hide()   end
    if self.statusFS      then self.statusFS:Hide()      end
    if self.keyFrame      then self.keyFrame:Hide()      end

    local S   = GamingHub.SNK_Settings
    local cur = S and S:Get("difficulty") or "easy"
    for i, b in ipairs(self.diffBtns) do
        b:UnlockHighlight()
        local DIFFS_REF = GetDiffs()
        if DIFFS_REF[i] and DIFFS_REF[i].value == cur then b:LockHighlight() end
    end

    if not self.hintFS then
        self.hintFS = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.hintFS:SetPoint("CENTER", self.frame, "CENTER", 0, 40)
        self.hintFS:SetText(GamingHub.GetLocaleTable("SNAKE")["hint_start"])
        self.hintFS:SetJustifyH("CENTER")
    end
    self.hintFS:Show()
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "SNAKE",
    label     = "Snake",
    renderer  = "SNK_Renderer",
    engine    = "SNK_Engine",
    container = "_snkContainer",
})
