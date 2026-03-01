--[[
    Gaming Hub
    Games/Minesweeper/Renderer.lua
    Version: 1.0.0

    Goblin-Edition Minesweeper

    Zell-Zustände:
      Verdeckt  → Zahnrad-Icon  (INV_Misc_Gear_01), mittleres Grau
      Flagge    → Warnschild    (Ability_TownWatch), orange Hintergrund
      Mine      → Goblin-Bombe  (INV_Misc_Bomb_03), roter Hintergrund
      Aufgedeckt leer  → heller Hintergrund, kein Icon
      Aufgedeckt Zahl  → heller Hintergrund, farbige Zahl

    Zahlenfarben (klassisch):
      1 → Blau      #4444ff
      2 → Grün      #22aa22
      3 → Rot       #ff3333
      4 → Dunkelblau #000088
      5 → Maroon    #880000
      6 → Türkis    #008888
      7 → Schwarz   #222222
      8 → Grau      #888888

    Schachbrettmuster:
      (r+c) gerade  → dunkel  { 0.18, 0.18, 0.18 }
      (r+c) ungerade → etwas heller { 0.24, 0.24, 0.24 }
    Aufgedeckt:
      (r+c) gerade  → { 0.62, 0.58, 0.48 }
      (r+c) ungerade→ { 0.72, 0.68, 0.56 }

    Dynamische Zellgröße:
      Verfügbare Höhe ≈ 460px (Content minus Header/Buttons/Statuszeile)
      easy   9×9  → ~44px
      normal 12×12 → ~34px
      hard   16×16 → ~26px
]]

local GamingHub = _G.GamingHub
GamingHub.MS_Renderer = {}
local R = GamingHub.MS_Renderer

-- ============================================================
-- Icons
-- ============================================================
local ICON_HIDDEN = "Interface\\Icons\\INV_Misc_Gear_01"
local ICON_FLAG   = "Interface\\Icons\\Ability_TownWatch"
local ICON_MINE   = "Interface\\Icons\\INV_Misc_Bomb_03"

-- ============================================================
-- Zahlenfarben (r, g, b)
-- ============================================================
local NUMBER_COLORS = {
    [1] = { 0.26, 0.26, 1.00 },
    [2] = { 0.13, 0.67, 0.13 },
    [3] = { 1.00, 0.20, 0.20 },
    [4] = { 0.00, 0.00, 0.55 },
    [5] = { 0.55, 0.00, 0.00 },
    [6] = { 0.00, 0.55, 0.55 },
    [7] = { 0.13, 0.13, 0.13 },
    [8] = { 0.55, 0.55, 0.55 },
}

-- ============================================================
-- Hintergrundfarben
-- ============================================================
local function getCellColors(isEven)
    if isEven then
        return
            { 0.18, 0.18, 0.18, 1 },  -- verdeckt
            { 0.62, 0.58, 0.48, 1 }   -- aufgedeckt
    else
        return
            { 0.24, 0.24, 0.24, 1 },
            { 0.72, 0.68, 0.56, 1 }
    end
end

local CLR_FLAG    = { 0.70, 0.40, 0.05, 1 }
local CLR_MINE    = { 0.70, 0.08, 0.08, 1 }
local CLR_MINE_HIT= { 1.00, 0.10, 0.10, 1 }  -- die angeklickte Mine

-- ============================================================
-- Zellgröße je Schwierigkeit
-- ============================================================
local CELL_SIZES = { easy = 44, normal = 34, hard = 26 }
local MIN_ICON_SIZE = 16

-- ============================================================
-- State
-- ============================================================
R.frame         = nil
R.state         = "IDLE"
R.selectedDiff  = nil

R.cells         = {}      -- cells[r][c] = { frame, bg, iconFrame, iconTex, label }
R.boardHolder   = nil
R.currentSize   = 0

R.diffBtns      = {}
R.diffContainer = nil
R.exitButton    = nil
R.newGameButton = nil
R.statusFS      = nil
R.mineCountFS   = nil
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
    Engine:On("MS_GAME_STARTED",   function(s)    R:OnGameStarted(s)     end)
    Engine:On("MS_CELL_REVEALED",  function(s)    R:OnBoardUpdated(s)    end)
    Engine:On("MS_FLAG_TOGGLED",   function(s)    R:OnBoardUpdated(s)    end)
    Engine:On("MS_GAME_WON",       function(s)    R:OnGameWon(s)         end)
    Engine:On("MS_GAME_LOST",      function(s)    R:OnGameLost(s)        end)
    Engine:On("MS_GAME_STOPPED",   function()     R:EnterIdleState()     end)
end

-- ============================================================
-- Main Frame
-- ============================================================
function R:CreateMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end

    local f = CreateFrame("Frame", "GamingHub_MS_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    self.frame = f
    if _G.GamingHub then _G.GamingHub._msContainer = f end
end

-- ============================================================
-- Board aufbauen (wird bei jedem neuen Spiel neu erstellt)
-- ============================================================
function R:BuildBoard(size, difficulty)
    -- Alte Zellen aufräumen
    self:ClearBoard()

    self.currentSize = size
    local cellSize   = CELL_SIZES[difficulty] or 34
    local boardPx    = cellSize * size
    local parent     = self.frame

    -- Holder zentrieren
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(boardPx + 2, boardPx + 2)
    holder:SetPoint("TOP", parent, "TOP", 0, -36)

    -- Goldfarbener Rahmen
    local outerBG = holder:CreateTexture(nil, "BACKGROUND")
    outerBG:SetTexture("Interface\\Buttons\\WHITE8X8")
    outerBG:SetAllPoints(holder)
    outerBG:SetVertexColor(0.70, 0.60, 0.20, 1)
    self.boardHolder = holder

    -- Icon-Größe: etwas kleiner als Zelle, mindestens MIN_ICON_SIZE
    local iconSize = math.max(MIN_ICON_SIZE, cellSize - 6)

    for r = 1, size do
        self.cells[r] = {}
        for c = 1, size do
            local px = 1 + (c-1) * cellSize
            local py = 1 + (r-1) * cellSize

            local tf = CreateFrame("Button", nil, holder)
            tf:SetSize(cellSize, cellSize)
            tf:SetPoint("TOPLEFT", holder, "TOPLEFT", px, -py)
            tf:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
            tf:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            tf:EnableMouse(true)

            local bg = tf:GetNormalTexture()
            local isEven = (r + c) % 2 == 0
            local hiddenCol = isEven and { 0.18, 0.18, 0.18 } or { 0.24, 0.24, 0.24 }
            bg:SetVertexColor(hiddenCol[1], hiddenCol[2], hiddenCol[3], 1)

            -- Icon-Frame (über NormalTexture)
            local iconFrame = CreateFrame("Frame", nil, tf)
            iconFrame:SetSize(iconSize, iconSize)
            iconFrame:SetPoint("CENTER", tf, "CENTER", 0, 0)
            iconFrame:SetFrameLevel(tf:GetFrameLevel() + 2)
            iconFrame:EnableMouse(false)

            local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
            iconTex:SetAllPoints(iconFrame)
            iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            iconTex:SetTexture(ICON_HIDDEN)
            iconTex:Show()

            -- Zahlen-Label
            local fontSize = math.max(10, cellSize - 16)
            local lbl = tf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetAllPoints(tf)
            lbl:SetJustifyH("CENTER")
            lbl:SetJustifyV("MIDDLE")
            lbl:SetFont(lbl:GetFont(), fontSize, "OUTLINE")
            lbl:SetText("")

            local cr, cc = r, c
            tf:SetScript("OnClick", function(_, btn)
                if btn == "RightButton" then
                    GamingHub.MS_Engine:HandleFlag(cr, cc)
                else
                    GamingHub.MS_Engine:HandleReveal(cr, cc)
                end
            end)

            self.cells[r][c] = {
                frame     = tf,
                bg        = bg,
                iconFrame = iconFrame,
                iconTex   = iconTex,
                label     = lbl,
                isEven    = isEven,
            }
        end
    end
end

-- ============================================================
-- ClearBoard – alle Zell-Frames entfernen
-- ============================================================
function R:ClearBoard()
    for r = 1, self.currentSize do
        if self.cells[r] then
            for c = 1, self.currentSize do
                local cd = self.cells[r][c]
                if cd and cd.frame then
                    cd.frame:Hide()
                    cd.frame:SetParent(nil)
                end
            end
        end
    end
    self.cells = {}

    if self.boardHolder then
        self.boardHolder:Hide()
        self.boardHolder:SetParent(nil)
        self.boardHolder = nil
    end
    self.currentSize = 0
end

-- ============================================================
-- RenderCell – einzelne Zelle rendern
-- ============================================================
function R:RenderCell(r, c, cell)
    local cd = self.cells[r] and self.cells[r][c]
    if not cd then return end

    local isEven = cd.isEven

    if not cell.revealed then
        -- Verdeckt
        if cell.flagged then
            -- Flagge
            cd.bg:SetVertexColor(CLR_FLAG[1], CLR_FLAG[2], CLR_FLAG[3], 1)
            cd.iconTex:SetTexture(ICON_FLAG)
            cd.iconTex:SetVertexColor(1, 1, 1, 1)
            cd.iconTex:Show()
            cd.label:SetText("")
        else
            -- Normal verdeckt: Zahnrad
            local col = isEven and { 0.18, 0.18, 0.18 } or { 0.24, 0.24, 0.24 }
            cd.bg:SetVertexColor(col[1], col[2], col[3], 1)
            cd.iconTex:SetTexture(ICON_HIDDEN)
            cd.iconTex:SetVertexColor(0.65, 0.65, 0.65, 1)
            cd.iconTex:Show()
            cd.label:SetText("")
        end
    else
        -- Aufgedeckt
        if cell.isMine then
            -- Mine!
            cd.bg:SetVertexColor(CLR_MINE[1], CLR_MINE[2], CLR_MINE[3], 1)
            cd.iconTex:SetTexture(ICON_MINE)
            cd.iconTex:SetVertexColor(1, 1, 1, 1)
            cd.iconTex:Show()
            cd.label:SetText("")
        else
            -- Sicheres Feld
            local col = isEven and { 0.62, 0.58, 0.48 } or { 0.72, 0.68, 0.56 }
            cd.bg:SetVertexColor(col[1], col[2], col[3], 1)
            cd.iconTex:Hide()

            if cell.neighbors > 0 then
                local nc = NUMBER_COLORS[cell.neighbors] or { 0, 0, 0 }
                cd.label:SetText(tostring(cell.neighbors))
                cd.label:SetTextColor(nc[1], nc[2], nc[3], 1)
            else
                cd.label:SetText("")
            end
        end
    end
end

-- ============================================================
-- RenderAll – kompletter Board-Render
-- ============================================================
function R:RenderAll(state)
    for r = 1, state.size do
        for c = 1, state.size do
            self:RenderCell(r, c, state.cells[r][c])
        end
    end
    self:UpdateStatusBar(state)
end

-- ============================================================
-- UpdateStatusBar
-- ============================================================
function R:UpdateStatusBar(state)
    if self.mineCountFS then
        local remaining = state.remaining or (state.mineCount - state.flagCount)
        local icon = "|T" .. ICON_MINE .. ":14:14:0:0|t"
        local flagIcon = "|T" .. ICON_FLAG .. ":14:14:0:0|t"
        self.mineCountFS:SetText(string.format(
            GamingHub.GetLocaleTable("MINESWEEPER")["status_mines"],
            icon, remaining, flagIcon, state.flagCount
        ))
    end
end

-- ============================================================
-- Status-Bar erstellen
-- ============================================================
function R:CreateStatusBar()
    if self.mineCountFS then return end
    local f = self.frame

    self.mineCountFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.mineCountFS:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    self.mineCountFS:SetJustifyH("RIGHT")
    self.mineCountFS:Hide()
end

-- ============================================================
-- Schwierigkeits-Buttons
-- ============================================================
local function GetDiffs()
    local L = GamingHub.GetLocaleTable("MINESWEEPER")
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
    c:SetSize(420, 30)
    self.diffContainer = c

    local DIFFS = GetDiffs()
    local W = 110; local SP = 14
    local total = #DIFFS * W + (#DIFFS-1)*SP
    local startX = -math.floor(total/2)

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
    local S = GamingHub.MS_Settings
    if S then S:Set("difficulty", value) end
    for _, b in ipairs(self.diffBtns) do b:UnlockHighlight() end
    clicked:LockHighlight()
    GamingHub.MS_Engine:StartGame({ difficulty = value })
end

-- ============================================================
-- Untere Buttons
-- ============================================================
function R:CreateBottomButtons()
    if self.exitButton then return end

    local exit = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    exit:SetSize(100, 28)
    exit:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 6)
    exit:SetText(GamingHub.GetLocaleTable("MINESWEEPER")["btn_exit"])
    exit:SetScript("OnClick", function() GamingHub.MS_Engine:StopGame() end)
    exit:Hide()
    self.exitButton = exit

    local newGame = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    newGame:SetSize(120, 28)
    newGame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 6)
    newGame:SetText(GamingHub.GetLocaleTable("MINESWEEPER")["btn_new_game"])
    newGame:SetScript("OnClick", function()
        if R.selectedDiff then
            GamingHub.MS_Engine:StartGame({ difficulty = R.selectedDiff })
        end
    end)
    newGame:Hide()
    self.newGameButton = newGame
end

-- ============================================================
-- Overlay (Sieg / Niederlage)
-- ============================================================
function R:CreateOverlay()
    if self.overlay then return end
    local ov = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    ov:SetAllPoints(self.frame)
    ov:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
    ov:SetBackdropColor(0, 0, 0, 0.78)
    ov:EnableMouse(false)
    ov:Hide()

    local title = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("CENTER", ov, "CENTER", 0, 40)
    ov.title = title

    local sub = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -10)
    sub:SetJustifyH("CENTER")
    ov.sub = sub

    local restartBtn = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
    restartBtn:SetSize(140, 28)
    restartBtn:SetPoint("TOP", sub, "BOTTOM", 0, -16)
    restartBtn:SetText(GamingHub.GetLocaleTable("MINESWEEPER")["btn_new_game"])
    restartBtn:SetScript("OnClick", function()
        ov:Hide()
        if R.selectedDiff then
            GamingHub.MS_Engine:StartGame({ difficulty = R.selectedDiff })
        end
    end)
    self.overlay = ov
end

-- ============================================================
-- Explosion-Effekt: alle Minen kurz rot aufleuchten lassen
-- ============================================================
function R:PlayExplosionEffect(state)
    if not state.minePositions then return end

    -- Sofort alle Minen rot färben
    for _, pos in ipairs(state.minePositions) do
        local cd = self.cells[pos.r] and self.cells[pos.r][pos.c]
        if cd then
            cd.bg:SetVertexColor(CLR_MINE_HIT[1], CLR_MINE_HIT[2], CLR_MINE_HIT[3], 1)
            cd.iconTex:SetTexture(ICON_MINE)
            cd.iconTex:SetVertexColor(1, 1, 1, 1)
            cd.iconTex:Show()
            cd.label:SetText("")
        end
    end

    -- Nach 0.3s auf normale Mine-Farbe zurück
    C_Timer.After(0.3, function()
        for _, pos in ipairs(state.minePositions or {}) do
            local cd = self.cells[pos.r] and self.cells[pos.r][pos.c]
            if cd then
                cd.bg:SetVertexColor(CLR_MINE[1], CLR_MINE[2], CLR_MINE[3], 1)
            end
        end
    end)
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
    if self.mineCountFS   then self.mineCountFS:Hide()   end

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
        self.hintFS:SetText(GamingHub.GetLocaleTable("MINESWEEPER")["hint_start"])
        self.hintFS:SetJustifyH("CENTER")
    end
    self.hintFS:Show()
end

-- ============================================================
-- Event-Handler
-- ============================================================
function R:OnGameStarted(state)
    self.state = "PLAYING"
    if self.overlay  then self.overlay:Hide()   end
    if self.hintFS   then self.hintFS:Hide()    end
    if self.exitButton    then self.exitButton:Show()    end
    if self.newGameButton then self.newGameButton:Show() end
    if self.mineCountFS   then self.mineCountFS:Show()  end

    -- Neues Board aufbauen
    self:BuildBoard(state.size, state.difficulty)
    self:RenderAll(state)
end

function R:OnBoardUpdated(state)
    self:RenderAll(state)
end

function R:OnGameWon(state)
    self.state = "WON"
    self:RenderAll(state)

    local ov = self.overlay
    if not ov then return end
    local _LW = GamingHub.GetLocaleTable("MINESWEEPER")
    ov.title:SetText(_LW["result_win_title"])
    ov.title:SetTextColor(1, 0.84, 0)
    ov.sub:SetText(string.format(_LW["result_win_sub"],
        state.mineCount, state.difficulty:upper(), state.revealCount))
    ov:SetAlpha(0)
    ov:Show()
    UIFrameFadeIn(ov, 0.6, 0, 0.88)
end

function R:OnGameLost(state)
    self.state = "LOST"

    -- Zuerst Explosion-Effekt
    self:PlayExplosionEffect(state)

    -- Dann kurz warten und Overlay zeigen
    C_Timer.After(0.5, function()
        self:RenderAll(state)
        local ov = self.overlay
        if not ov then return end
        local _LL = GamingHub.GetLocaleTable("MINESWEEPER")
        ov.title:SetText(_LL["result_loss_title"])
        ov.title:SetTextColor(1, 0.2, 0.2)
        ov.sub:SetText(string.format(_LL["result_loss_sub"],
            state.revealCount, state.size * state.size - state.mineCount))
        ov:SetAlpha(0)
        ov:Show()
        UIFrameFadeIn(ov, 0.4, 0, 0.88)
    end)
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "MINESWEEPER",
    label     = "Minesweeper",
    renderer  = "MS_Renderer",
    engine    = "MS_Engine",
    container = "_msContainer",
})
