--[[
    Gaming Hub
    Games/Sudoku/Renderer.lua
    Version: 1.0.0

    Layout:
      ┌────────────────────────────────────────┐
      │  [Statistik: Züge / Fehler]            │
      │                                        │
      │   ┌─────── 9×9 Sudoku-Grid ───────┐   │
      │   │  3×3 Blöcke schachbrettartig  │   │
      │   └───────────────────────────────┘   │
      │                                        │
      │  [Easy] [Normal] [Hard]                │
      │  [Beenden]          [Neues Puzzle]     │
      └────────────────────────────────────────┘

    Zell-Farben:
      Feste Zahl (fixed):   Gold/Weiß, dunkelgrauer Hintergrund
      Spieler-Zahl (ok):    Hellblau
      Spieler-Zahl (error): Rot
      Highlight (gleiche #): Gelb-transparent
      Ausgewählt:           Hellgrün-transparent

    3×3-Block-Hintergründe (schachbrettartig):
      Ungerade Blöcke (1,3,5,7,9): 0.10, 0.10, 0.10, 1
      Gerade Blöcke  (2,4,6,8):    0.00, 0.00, 0.00, 1

    Popup:
      3×3-Grid mit 1-9 + X-Button (oben rechts)
      Erscheint direkt über/neben der angeklickten Zelle
]]

local GamingHub = _G.GamingHub
GamingHub.SDK_Renderer = {}
local R = GamingHub.SDK_Renderer

-- ============================================================
-- Farben
-- ============================================================
-- Block-Hintergründe
local BLOCK_ODD    = { 0.10, 0.10, 0.10, 1 }
local BLOCK_EVEN   = { 0.00, 0.00, 0.00, 1 }

-- Zell-Zustände (NormalTexture-Farbe)
local CLR_FIXED    = { 0.14, 0.13, 0.18, 1 }  -- Feste Zahl: sehr dunkel
local CLR_EMPTY    = { 0.12, 0.14, 0.20, 1 }  -- Leer: dunkelblau
local CLR_PLAYER   = { 0.10, 0.18, 0.28, 1 }  -- Spieler-Zahl: blaugrau
local CLR_ERROR    = { 0.30, 0.06, 0.06, 1 }  -- Fehler: dunkelrot
local CLR_HIGHLIGHT= { 0.35, 0.32, 0.04, 1 }  -- Gleiche Zahl: goldgelb
local CLR_SELECTED = { 0.08, 0.32, 0.12, 1 }  -- Ausgewählt: grün

-- Text-Farben
local TXT_FIXED    = { 1.00, 0.82, 0.00, 1 }  -- Gold
local TXT_PLAYER   = { 0.50, 0.80, 1.00, 1 }  -- Hellblau
local TXT_ERROR    = { 1.00, 0.30, 0.30, 1 }  -- Rot

-- Gitter-Separator-Farben
local SEP_THIN     = { 0.25, 0.28, 0.35, 1 }  -- Dünne Linie (Zell-Rand)
local SEP_THICK    = { 0.70, 0.60, 0.35, 1 }  -- Dicke Linie (Block-Rand, Gold)

-- ============================================================
-- Konstanten
-- ============================================================
local CELL_SIZE    = 38   -- Pixel pro Zelle (verkleinert damit Buttons nicht überlagert werden)
local THIN_GAP     = 1    -- Dünne Linie zwischen Zellen (px)
local THICK_GAP    = 3    -- Dicke Linie zwischen 3×3-Blöcken (px)
local GRID_TOP_PAD = 10   -- Abstand oben
local GRID_SIDE_PAD= 20   -- Seitenrand

-- Berechne Pixel-Offset einer Zelle (r oder c, 1-basiert)
-- 3 Zellen pro Block, Blöcke durch THICK_GAP getrennt
local function cellOffset(idx)
    local block = math.floor((idx-1)/3)  -- 0, 1, 2
    local pos   = (idx-1) * CELL_SIZE
                + (idx-1) * THIN_GAP
                + block    * (THICK_GAP - THIN_GAP)  -- dicke Linien ersetzen dünne
    return pos
end

-- Gesamtbreite/Höhe des Grids in Pixeln
local GRID_PX = cellOffset(9) + CELL_SIZE  -- = 9*48 + 8*1 + 2*(3-1) = 432+8+4 = 444

-- ============================================================
-- State
-- ============================================================
R.frame          = nil
R.state          = "IDLE"
R.selectedDiff   = nil

R.cells          = {}      -- cells[r][c] = { frame, bg, label }
R.blockFrames    = {}      -- Hintergrund-Frames für 9 Blöcke
R.separators     = {}      -- Separator-Frames (Block-Linien)

R.popup          = nil     -- Zahlen-Popup
R.popupOpen      = false
R.popupTargetR   = nil
R.popupTargetC   = nil

R.diffBtns       = {}
R.diffContainer  = nil
R.exitButton     = nil
R.newGameButton  = nil
R.statsFS        = nil
R.hintFS         = nil
R.overlay        = nil

-- ============================================================
-- Init
-- ============================================================

function R:Init()
    self:CreateMainFrame()
    self:CreateGrid()
    self:CreatePopup()
    self:CreateDiffButtons()
    self:CreateBottomButtons()
    self:CreateOverlay()
    self:EnterIdleState()

    local Engine = GamingHub.Engine
    Engine:On("SDK_GAME_STARTED",  function(s) R:OnGameStarted(s)  end)
    Engine:On("SDK_CELL_SELECTED", function(s) R:OnCellSelected(s) end)
    Engine:On("SDK_BOARD_UPDATED", function(s) R:OnBoardUpdated(s) end)
    Engine:On("SDK_CELL_CLEARED",  function(s) R:OnBoardUpdated(s) end)
    Engine:On("SDK_GAME_COMPLETE", function(s) R:OnGameComplete(s) end)
    Engine:On("SDK_GAME_STOPPED",  function()  R:EnterIdleState()  end)
end

-- ============================================================
-- Main Frame
-- ============================================================

function R:CreateMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end

    local f = CreateFrame("Frame", "GamingHub_SDK_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    self.frame = f
    if _G.GamingHub then _G.GamingHub._sdkContainer = f end
end

-- ============================================================
-- Grid aufbauen
-- Einmalig beim Init – Farben werden per Render gesetzt
-- ============================================================

function R:CreateGrid()
    if #self.cells > 0 then return end
    local parent = self.frame

    -- ── Äußerer Grid-Container ──────────────────────────────
    local gridHolder = CreateFrame("Frame", nil, parent)
    gridHolder:SetSize(GRID_PX + THICK_GAP*2, GRID_PX + THICK_GAP*2)
    gridHolder:SetPoint("TOP", parent, "TOP", 0, -GRID_TOP_PAD)
    self.gridHolder = gridHolder

    -- Äußerer Rahmen (Gold)
    local outerBG = gridHolder:CreateTexture(nil, "BACKGROUND")
    outerBG:SetTexture("Interface\\Buttons\\WHITE8X8")
    outerBG:SetAllPoints(gridHolder)
    outerBG:SetVertexColor(SEP_THICK[1], SEP_THICK[2], SEP_THICK[3], 1)

    -- ── 9 Block-Hintergrund-Frames ──────────────────────────
    for block = 1, 9 do
        local br = math.floor((block-1)/3)  -- Blockzeile 0-2
        local bc = (block-1) % 3            -- Blockspalte 0-2
        local bx = bc * (CELL_SIZE*3 + THIN_GAP*2 + THICK_GAP) + THICK_GAP
        local by = br * (CELL_SIZE*3 + THIN_GAP*2 + THICK_GAP) + THICK_GAP

        local bf = CreateFrame("Frame", nil, gridHolder)
        bf:SetSize(CELL_SIZE*3 + THIN_GAP*2, CELL_SIZE*3 + THIN_GAP*2)
        bf:SetPoint("TOPLEFT", gridHolder, "TOPLEFT", bx, -by)

        local bbg = bf:CreateTexture(nil, "BACKGROUND")
        bbg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bbg:SetAllPoints(bf)
        local col = (block % 2 == 1) and BLOCK_ODD or BLOCK_EVEN
        bbg:SetVertexColor(col[1], col[2], col[3], 1)
        self.blockFrames[block] = bf
    end

    -- ── 81 Zell-Buttons ─────────────────────────────────────
    for r = 1, 9 do
        self.cells[r] = {}
        for c = 1, 9 do
            local px = cellOffset(c) + THICK_GAP
            local py = cellOffset(r) + THICK_GAP

            local tf = CreateFrame("Button", nil, gridHolder)
            tf:SetSize(CELL_SIZE, CELL_SIZE)
            tf:SetPoint("TOPLEFT", gridHolder, "TOPLEFT", px, -py)
            tf:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
            tf:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            tf:EnableMouse(true)

            -- Hintergrundfarbe
            local bg = tf:GetNormalTexture()
            bg:SetVertexColor(CLR_EMPTY[1], CLR_EMPTY[2], CLR_EMPTY[3], 1)

            -- Highlight-Overlay (eigenes Frame über dem Button)
            local hlFrame = CreateFrame("Frame", nil, tf)
            hlFrame:SetAllPoints(tf)
            hlFrame:EnableMouse(false)
            hlFrame:Hide()
            -- FrameLevel explizit setzen: UNTER dem Label (das auf OVERLAY von tf liegt)
            -- tf hat FrameLevel X, hlFrame erbt X+1 → liegt über tf's OVERLAY-Texten!
            -- Lösung: hlFrame auf gleiches Level wie tf setzen
            hlFrame:SetFrameLevel(tf:GetFrameLevel())
            local hlTex = hlFrame:CreateTexture(nil, "OVERLAY")  -- OVERLAY mit Alpha
            hlTex:SetTexture("Interface\\Buttons\\WHITE8X8")
            hlTex:SetAllPoints(hlFrame)
            hlTex:SetVertexColor(CLR_HIGHLIGHT[1], CLR_HIGHLIGHT[2], CLR_HIGHLIGHT[3], 0.45)

            -- Zahlen-Label – auf höherem FrameLevel via OVERLAY+1 Sublevel
            local lbl = tf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            lbl:SetAllPoints(tf)
            lbl:SetJustifyH("CENTER")
            lbl:SetJustifyV("MIDDLE")
            lbl:SetText("")

            local cr, cc = r, c
            tf:SetScript("OnClick", function(_, btn)
                if btn == "RightButton" then
                    R:ClosePopup()
                    GamingHub.SDK_Engine:HandleCellRightClick(cr, cc)
                else
                    if R.popupOpen and R.popupTargetR == cr and R.popupTargetC == cc then
                        R:ClosePopup()
                    else
                        GamingHub.SDK_Engine:HandleCellClick(cr, cc)
                    end
                end
            end)

            self.cells[r][c] = {
                frame   = tf,
                bg      = bg,
                label   = lbl,
                hlFrame = hlFrame,
                hlTex   = hlTex,
            }
        end
    end
end

-- ============================================================
-- Popup erstellen (3×3 Zahlen-Grid + X zum Schließen)
-- ============================================================

function R:CreatePopup()
    if self.popup then return end

    local PBTN = 36   -- Popup-Button-Größe
    local PGAP = 2    -- Popup-Gap
    local PW   = 3 * PBTN + 2 * PGAP + 8
    local PH   = 3 * PBTN + 2 * PGAP + 8

    local pop = CreateFrame("Frame", "GamingHub_SDK_Popup", self.frame, "BackdropTemplate")
    pop:SetSize(PW, PH)
    pop:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileEdge = true, edgeSize = 12,
        insets = { left=3, right=3, top=3, bottom=3 },
    })
    pop:SetBackdropColor(0.05, 0.05, 0.10, 0.97)
    pop:SetBackdropBorderColor(0.90, 0.75, 0.30, 1)
    pop:SetFrameStrata("DIALOG")
    pop:SetFrameLevel(100)
    pop:Hide()
    pop:EnableMouse(true)

    -- 9 Zahlen-Buttons (1-9)
    local nums = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
    pop.numBtns = {}
    for i, num in ipairs(nums) do
        local row = math.floor((i-1)/3)
        local col = (i-1) % 3
        local btn = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
        btn:SetSize(PBTN, PBTN)
        btn:SetPoint("TOPLEFT", pop, "TOPLEFT",
            4 + col*(PBTN+PGAP),
            -(4 + row*(PBTN+PGAP)))
        btn:SetText(tostring(num))
        btn:GetFontString():SetFont(
            btn:GetFontString():GetFont(), 16, "OUTLINE")
        local n = num
        btn:SetScript("OnClick", function()
            R:ClosePopup()
            GamingHub.SDK_Engine:HandleNumberInput(n)
        end)
        pop.numBtns[i] = btn
    end

    self.popup = pop
end

-- ============================================================
-- Popup öffnen / schließen
-- ============================================================

function R:OpenPopup(r, c)
    local cd = self.cells[r] and self.cells[r][c]
    if not cd then return end

    self.popupOpen    = true
    self.popupTargetR = r
    self.popupTargetC = c

    -- Position: versuche rechts der Zelle, fallback links
    local pop   = self.popup
    local frame = cd.frame
    pop:ClearAllPoints()

    -- Rechts von der Zelle
    local gx, gy = frame:GetRight(), frame:GetTop()
    -- Prüfen ob Platz rechts vorhanden (grob: falls gridHolder nah am rechten Rand)
    pop:SetPoint("TOPLEFT", frame, "TOPRIGHT", 4, 0)

    pop:Show()
    pop:Raise()
end

function R:ClosePopup()
    self.popupOpen    = false
    self.popupTargetR = nil
    self.popupTargetC = nil
    if self.popup then self.popup:Hide() end
end

-- ============================================================
-- Schwierigkeits-Buttons
-- ============================================================

local function GetDiffs()
    local L = GamingHub.GetLocaleTable("SUDOKU")
    return {
        { label = L["diff_easy"],   value = "easy"   },
        { label = L["diff_normal"], value = "normal" },
        { label = L["diff_hard"],   value = "hard"   },
    }
end

function R:CreateDiffButtons()
    if self.diffContainer then return end
    local c = CreateFrame("Frame", nil, self.frame)
    c:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 36)
    c:SetSize(400, 30)
    self.diffContainer = c

    local DIFFS = GetDiffs()
    local W = 100; local SP = 14
    local totalW = #DIFFS * W + (#DIFFS-1)*SP
    local startX = -math.floor(totalW/2)

    for i, d in ipairs(DIFFS) do
        local btn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        btn:SetSize(W, 28)
        btn:SetPoint("LEFT", c, "CENTER", startX + (i-1)*(W+SP), 0)
        btn:SetText(d.label)
        btn:SetScript("OnClick", function()
            R:SelectDiff(d.value, btn)
        end)
        self.diffBtns[i] = btn
    end
end

function R:SelectDiff(value, clicked)
    self.selectedDiff = value
    local S = GamingHub.SDK_Settings
    if S then S:Set("difficulty", value) end
    for _, b in ipairs(self.diffBtns) do b:UnlockHighlight() end
    clicked:LockHighlight()
    R:ClosePopup()
    GamingHub.SDK_Engine:StartGame({ difficulty = value })
end

-- ============================================================
-- Untere Buttons
-- ============================================================

function R:CreateBottomButtons()
    if self.exitButton then return end

    local exit = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    exit:SetSize(100, 28)
    exit:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 6)
    exit:SetText(GamingHub.GetLocaleTable("SUDOKU")["btn_exit"])
    exit:SetScript("OnClick", function()
        R:ClosePopup()
        GamingHub.SDK_Engine:StopGame()
    end)
    exit:Hide()
    self.exitButton = exit

    local newGame = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    newGame:SetSize(120, 28)
    newGame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 6)
    newGame:SetText(GamingHub.GetLocaleTable("SUDOKU")["btn_new_puzzle"])
    newGame:SetScript("OnClick", function()
        R:ClosePopup()
        if R.selectedDiff then
            GamingHub.SDK_Engine:StartGame({ difficulty = R.selectedDiff })
        end
    end)
    newGame:Hide()
    self.newGameButton = newGame
end

-- ============================================================
-- Statistik-Anzeige
-- ============================================================

function R:CreateOrUpdateStats(state)
    if not self.statsFS then
        self.statsFS = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.statsFS:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -8, -8)
        self.statsFS:SetJustifyH("RIGHT")
    end
    self.statsFS:SetText(string.format(
        GamingHub.GetLocaleTable("SUDOKU")["stats_text"],
        state.moves or 0, state.mistakes or 0
    ))
    self.statsFS:Show()
end

-- ============================================================
-- Overlay (Sieg)
-- ============================================================

function R:CreateOverlay()
    if self.overlay then return end
    local ov = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    ov:SetAllPoints(self.frame)
    ov:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
    ov:SetBackdropColor(0, 0, 0, 0.72)
    ov:EnableMouse(false)
    ov:Hide()

    local title = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("CENTER", ov, "CENTER", 0, 40)
    title:SetText(GamingHub.GetLocaleTable("SUDOKU")["result_title"])
    ov.title = title

    local sub = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -10)
    sub:SetJustifyH("CENTER")
    ov.sub = sub

    local restartBtn = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
    restartBtn:SetSize(140, 28)
    restartBtn:SetPoint("TOP", sub, "BOTTOM", 0, -16)
    restartBtn:SetText(GamingHub.GetLocaleTable("SUDOKU")["btn_new_puzzle"])
    restartBtn:SetScript("OnClick", function()
        ov:Hide()
        if R.selectedDiff then
            GamingHub.SDK_Engine:StartGame({ difficulty = R.selectedDiff })
        end
    end)
    self.overlay = ov
end

-- ============================================================
-- Idle State
-- ============================================================

function R:EnterIdleState()
    self.state = "IDLE"
    R:ClosePopup()
    if self.overlay    then self.overlay:Hide()    end
    if self.exitButton then self.exitButton:Hide() end
    if self.newGameButton then self.newGameButton:Hide() end
    if self.statsFS    then self.statsFS:Hide()    end

    -- Grid leeren
    for r = 1, 9 do
        for c = 1, 9 do
            local cd = self.cells[r] and self.cells[r][c]
            if cd then
                cd.bg:SetVertexColor(CLR_EMPTY[1], CLR_EMPTY[2], CLR_EMPTY[3], 1)
                cd.label:SetText("")
                cd.hlFrame:Hide()
                cd.frame:Enable()
            end
        end
    end

    -- Diff-Buttons Highlight
    for i, b in ipairs(self.diffBtns) do
        b:UnlockHighlight()
        local DIFFS_REF = GetDiffs()
        if DIFFS_REF[i] and DIFFS_REF[i].value == self.selectedDiff then
            b:LockHighlight()
        end
    end

    if not self.hintFS then
        self.hintFS = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.hintFS:SetPoint("CENTER", self.frame, "CENTER", 0, 20)
        self.hintFS:SetText(GamingHub.GetLocaleTable("SUDOKU")["hint_start"])
        self.hintFS:SetJustifyH("CENTER")
    end
    self.hintFS:Show()
end

-- ============================================================
-- RenderBoard – vollständiger Board-Render
-- ============================================================

function R:RenderBoard(state)
    local grid    = state.grid
    local fixed   = state.fixed
    local errors  = state.errors
    local selR    = state.selected and state.selected.r
    local selC    = state.selected and state.selected.c
    local hlNum   = state.highlightNum

    -- Highlight-Zellen berechnen
    local hlCells = {}
    if hlNum and hlNum ~= 0 then
        local cells = GamingHub.SDK_Logic:GetHighlightCells(grid, hlNum)
        for _, pos in ipairs(cells) do
            hlCells[pos.r .. "_" .. pos.c] = true
        end
    end

    for r = 1, 9 do
        for c = 1, 9 do
            local cd  = self.cells[r][c]
            local num = grid[r][c]
            local isFixed   = fixed[r][c]
            local isError   = errors[r][c]
            local isSelected= (r == selR and c == selC)
            local isHL      = hlCells[r .. "_" .. c]

            -- ── Hintergrundfarbe ────────────────────────────
            local bgCol
            if isSelected then
                bgCol = CLR_SELECTED
            elseif isError then
                bgCol = CLR_ERROR
            elseif isFixed then
                bgCol = CLR_FIXED
            elseif num ~= 0 then
                bgCol = CLR_PLAYER
            else
                bgCol = CLR_EMPTY
            end
            cd.bg:SetVertexColor(bgCol[1], bgCol[2], bgCol[3], 1)

            -- ── Highlight-Overlay ───────────────────────────
            if isHL and not isSelected then
                cd.hlFrame:Show()
            else
                cd.hlFrame:Hide()
            end

            -- ── Zahl und Farbe ──────────────────────────────
            if num ~= 0 then
                cd.label:SetText(tostring(num))
                if isFixed then
                    cd.label:SetTextColor(TXT_FIXED[1], TXT_FIXED[2], TXT_FIXED[3], 1)
                    cd.label:SetFont(cd.label:GetFont(), 20, "OUTLINE")
                elseif isError then
                    cd.label:SetTextColor(TXT_ERROR[1], TXT_ERROR[2], TXT_ERROR[3], 1)
                    cd.label:SetFont(cd.label:GetFont(), 20, "")
                else
                    cd.label:SetTextColor(TXT_PLAYER[1], TXT_PLAYER[2], TXT_PLAYER[3], 1)
                    cd.label:SetFont(cd.label:GetFont(), 20, "")
                end
            else
                cd.label:SetText("")
            end

            -- ── Fixed Cells: Klick deaktivieren ────────────
            if isFixed then
                cd.frame:Disable()
            else
                cd.frame:Enable()
            end
        end
    end
end

-- ============================================================
-- Event-Handler
-- ============================================================

function R:OnGameStarted(state)
    self.state = "PLAYING"
    R:ClosePopup()
    if self.overlay  then self.overlay:Hide()   end
    if self.hintFS   then self.hintFS:Hide()    end
    if self.exitButton    then self.exitButton:Show()    end
    if self.newGameButton then self.newGameButton:Show() end

    self:RenderBoard(state)
    self:CreateOrUpdateStats(state)
end

function R:OnCellSelected(state)
    self:RenderBoard(state)
    -- Popup öffnen
    if state.selected then
        self:OpenPopup(state.selected.r, state.selected.c)
    end
end

function R:OnBoardUpdated(state)
    R:ClosePopup()
    self:RenderBoard(state)
    self:CreateOrUpdateStats(state)
end

function R:OnGameComplete(state)
    self.state = "COMPLETE"
    R:ClosePopup()
    self:RenderBoard(state)
    self:CreateOrUpdateStats(state)

    local ov = self.overlay
    if not ov then return end

    ov.sub:SetText(string.format(
        GamingHub.GetLocaleTable("SUDOKU")["result_sub"],
        state.moves or 0,
        state.mistakes or 0,
        state.difficulty or "?"
    ))
    ov:SetAlpha(0)
    ov:Show()
    UIFrameFadeIn(ov, 0.5, 0, 0.85)
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "SUDOKU",
    label     = "Sudoku",
    renderer  = "SDK_Renderer",
    engine    = "SDK_Engine",
    container = "_sdkContainer",
})
