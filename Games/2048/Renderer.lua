--[[
    Gaming Hub
    Games/2048/Renderer.lua
    Version: 1.0.0

    UI für 2048:
      - 4×4 Kachel-Grid, dynamisch skaliert
      - Tastatureingabe: WASD + Pfeiltasten
      - Kachelfarben nach WoW-Farbpalette pro Wert
      - Score + Best Score Anzeige oben
      - Merge-Flash: kurze Aufhellung beim Zusammenführen
      - Spawn-Fade: neue Kachel blendet ein
      - Game Over / Win Overlay mit Optionen (Weiterspielen / Neu)
      - Beenden-Button

    Tastatur-Implementierung:
      WoW lässt Tastatureingaben auf Frames nur über
      frame:SetScript("OnKeyDown") + SetPropagateKeyboardInput(false) zu.
      Der Container-Frame muss EnableKeyboard(true) haben.
]]

local GamingHub = _G.GamingHub
GamingHub.TDG_Renderer = {}
local Renderer = GamingHub.TDG_Renderer

-- ============================================================
-- Kachelfarben (r, g, b) nach Wert
-- Farbverlauf von grau → orange → rot → lila → gold
-- ============================================================

-- ============================================================
-- Farb-Themen
-- Jedes Theme definiert: boardBg, slotBg, und Kachelfarben pro Wert.
-- boardBg  = Fugen-Farbe
-- slotBg   = leere Slot-Farbe
-- tiles    = { [wert] = { bg={r,g,b}, fg={r,g,b} } }
-- ============================================================

local THEMES = {

    CLASSIC = {
        name    = "Classic (Orange)",
        boardBg = {0.44, 0.40, 0.36},
        slotBg  = {0.58, 0.53, 0.49},
        tiles   = {
            [2]    = { bg={0.93, 0.89, 0.85}, fg={0.47, 0.43, 0.40} },
            [4]    = { bg={0.93, 0.88, 0.78}, fg={0.47, 0.43, 0.40} },
            [8]    = { bg={0.95, 0.69, 0.47}, fg={1.00, 0.97, 0.92} },
            [16]   = { bg={0.96, 0.58, 0.39}, fg={1.00, 0.97, 0.92} },
            [32]   = { bg={0.96, 0.49, 0.37}, fg={1.00, 0.97, 0.92} },
            [64]   = { bg={0.96, 0.37, 0.23}, fg={1.00, 0.97, 0.92} },
            [128]  = { bg={0.93, 0.81, 0.45}, fg={1.00, 0.97, 0.92} },
            [256]  = { bg={0.93, 0.80, 0.38}, fg={1.00, 0.97, 0.92} },
            [512]  = { bg={0.93, 0.78, 0.31}, fg={1.00, 0.97, 0.92} },
            [1024] = { bg={0.93, 0.77, 0.25}, fg={1.00, 0.97, 0.92} },
            [2048] = { bg={1.00, 0.84, 0.00}, fg={1.00, 1.00, 1.00} },
            [4096] = { bg={1.00, 0.92, 0.50}, fg={1.00, 1.00, 1.00} },
        },
    },

    HORDE = {
        name    = "Horde (Rot/Gold)",
        boardBg = {0.25, 0.08, 0.08},
        slotBg  = {0.35, 0.12, 0.12},
        tiles   = {
            [2]    = { bg={0.55, 0.18, 0.18}, fg={1.00, 0.90, 0.80} },
            [4]    = { bg={0.65, 0.22, 0.22}, fg={1.00, 0.90, 0.80} },
            [8]    = { bg={0.78, 0.28, 0.18}, fg={1.00, 0.95, 0.85} },
            [16]   = { bg={0.88, 0.32, 0.18}, fg={1.00, 0.95, 0.85} },
            [32]   = { bg={0.90, 0.35, 0.10}, fg={1.00, 0.95, 0.85} },
            [64]   = { bg={0.95, 0.38, 0.05}, fg={1.00, 0.95, 0.85} },
            [128]  = { bg={0.85, 0.65, 0.10}, fg={0.20, 0.08, 0.08} },
            [256]  = { bg={0.90, 0.72, 0.10}, fg={0.20, 0.08, 0.08} },
            [512]  = { bg={0.95, 0.78, 0.12}, fg={0.20, 0.08, 0.08} },
            [1024] = { bg={0.98, 0.84, 0.15}, fg={0.20, 0.08, 0.08} },
            [2048] = { bg={1.00, 0.92, 0.20}, fg={0.20, 0.08, 0.08} },
            [4096] = { bg={1.00, 0.96, 0.40}, fg={0.10, 0.04, 0.04} },
        },
    },

    ALLIANCE = {
        name    = "Allianz (Blau/Silber)",
        boardBg = {0.10, 0.15, 0.30},
        slotBg  = {0.15, 0.22, 0.42},
        tiles   = {
            [2]    = { bg={0.60, 0.70, 0.90}, fg={0.10, 0.15, 0.35} },
            [4]    = { bg={0.50, 0.62, 0.88}, fg={0.10, 0.15, 0.35} },
            [8]    = { bg={0.35, 0.50, 0.88}, fg={1.00, 1.00, 1.00} },
            [16]   = { bg={0.28, 0.42, 0.85}, fg={1.00, 1.00, 1.00} },
            [32]   = { bg={0.22, 0.35, 0.82}, fg={1.00, 1.00, 1.00} },
            [64]   = { bg={0.18, 0.28, 0.78}, fg={1.00, 1.00, 1.00} },
            [128]  = { bg={0.70, 0.78, 0.85}, fg={0.10, 0.15, 0.30} },
            [256]  = { bg={0.78, 0.84, 0.90}, fg={0.10, 0.15, 0.30} },
            [512]  = { bg={0.85, 0.90, 0.95}, fg={0.10, 0.15, 0.30} },
            [1024] = { bg={0.90, 0.94, 0.98}, fg={0.10, 0.15, 0.30} },
            [2048] = { bg={1.00, 0.96, 0.70}, fg={0.10, 0.15, 0.30} },
            [4096] = { bg={1.00, 0.98, 0.80}, fg={0.05, 0.10, 0.20} },
        },
    },

    NIGHTELF = {
        name    = "Nachtelf (Lila/Grün)",
        boardBg = {0.08, 0.05, 0.18},
        slotBg  = {0.14, 0.08, 0.28},
        tiles   = {
            [2]    = { bg={0.35, 0.20, 0.55}, fg={0.90, 0.80, 1.00} },
            [4]    = { bg={0.42, 0.25, 0.65}, fg={0.90, 0.80, 1.00} },
            [8]    = { bg={0.20, 0.55, 0.35}, fg={0.90, 1.00, 0.90} },
            [16]   = { bg={0.18, 0.62, 0.38}, fg={0.90, 1.00, 0.90} },
            [32]   = { bg={0.55, 0.20, 0.65}, fg={1.00, 0.90, 1.00} },
            [64]   = { bg={0.65, 0.15, 0.75}, fg={1.00, 0.90, 1.00} },
            [128]  = { bg={0.20, 0.75, 0.45}, fg={0.05, 0.15, 0.10} },
            [256]  = { bg={0.25, 0.82, 0.50}, fg={0.05, 0.15, 0.10} },
            [512]  = { bg={0.78, 0.35, 0.90}, fg={1.00, 0.95, 1.00} },
            [1024] = { bg={0.85, 0.42, 0.95}, fg={1.00, 0.95, 1.00} },
            [2048] = { bg={0.55, 0.95, 0.65}, fg={0.05, 0.20, 0.10} },
            [4096] = { bg={0.70, 1.00, 0.78}, fg={0.05, 0.20, 0.10} },
        },
    },

    GOBLIN = {
        name    = "Goblin (Grün/Gelb)",
        boardBg = {0.08, 0.18, 0.05},
        slotBg  = {0.12, 0.26, 0.08},
        tiles   = {
            [2]    = { bg={0.38, 0.62, 0.22}, fg={0.05, 0.15, 0.05} },
            [4]    = { bg={0.44, 0.70, 0.25}, fg={0.05, 0.15, 0.05} },
            [8]    = { bg={0.55, 0.78, 0.10}, fg={0.05, 0.15, 0.05} },
            [16]   = { bg={0.65, 0.85, 0.10}, fg={0.05, 0.15, 0.05} },
            [32]   = { bg={0.78, 0.88, 0.08}, fg={0.05, 0.15, 0.05} },
            [64]   = { bg={0.88, 0.90, 0.05}, fg={0.05, 0.15, 0.05} },
            [128]  = { bg={0.95, 0.85, 0.10}, fg={0.05, 0.15, 0.05} },
            [256]  = { bg={0.98, 0.78, 0.08}, fg={0.05, 0.10, 0.05} },
            [512]  = { bg={1.00, 0.70, 0.05}, fg={0.05, 0.10, 0.05} },
            [1024] = { bg={1.00, 0.60, 0.02}, fg={0.05, 0.10, 0.05} },
            [2048] = { bg={1.00, 0.92, 0.00}, fg={0.05, 0.10, 0.05} },
            [4096] = { bg={1.00, 0.96, 0.30}, fg={0.03, 0.08, 0.03} },
        },
    },
}

local function GetActiveTheme()
    local S = _G.GamingHub and _G.GamingHub.TDG_Settings
    local id = (S and S:Get("colorTheme")) or "CLASSIC"
    return THEMES[id] or THEMES.CLASSIC
end

local function GetTileColor(value)
    local theme = GetActiveTheme()
    return theme.tiles[value]
        or { bg={0.50, 0.20, 0.60}, fg={1,1,1} }  -- >4096: Fallback lila
end

-- ============================================================
-- State
-- ============================================================

Renderer.selectedSize    = 4    -- zuletzt gewählte Brett-Größe
Renderer.sizeContainer   = nil
Renderer.sizeBtns        = {}

Renderer.frame       = nil
Renderer.overlay     = nil
Renderer.exitButton  = nil
Renderer.tiles       = {}   -- [row][col] = { frame, bgTex, label }
Renderer.scoreFS     = nil
Renderer.bestFS      = nil
Renderer.keyFrame    = nil
Renderer.state       = "IDLE"
Renderer.boardSize   = 4
Renderer.cellPx      = 0
Renderer.offsetX     = 0
Renderer.offsetY     = 0

-- ============================================================
-- Init
-- ============================================================

function Renderer:Init()
    self:CreateMainFrame()
    self:CreateScoreBar()
    self:CreateSizeButtons()
    self:CreateExitButton()
    self:CreateOverlay()
    self:CreateKeyFrame()
    self:EnterIdleState()

    local Engine = GamingHub.Engine

    Engine:On("TDG_GAME_STARTED", function(state)
        Renderer.state = "PLAYING"
        Renderer:RenderBoard(state)
        Renderer:UpdateScore(state)
        if Renderer.overlay then Renderer.overlay:Hide() end
        if Renderer.keyFrame then Renderer.keyFrame:EnableKeyboard(true) end
    end)

    Engine:On("TDG_BOARD_UPDATED", function(state)
        Renderer:UpdateBoard(state)
        Renderer:UpdateScore(state)
    end)

    Engine:On("TDG_GAME_OVER", function()
        Renderer:ShowGameOverOverlay()
        if Renderer.keyFrame then Renderer.keyFrame:EnableKeyboard(false) end
    end)

    Engine:On("TDG_GAME_STOPPED", function()
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
        local container  = CreateFrame("Frame", "GamingHub_2048_Container", gamesPanel)
        container:SetAllPoints(gamesPanel)
        container:Hide()
        self.frame = container
        if _G.GamingHub then
            _G.GamingHub._2048Container = container
        end
    end
end

-- ============================================================
-- Score Bar (oben im Frame)
-- ============================================================

function Renderer:CreateScoreBar()
    if self.scoreFS then return end
    local parent = self.frame

    local function MakeBox(anchorPoint, offsetX)
        local box = CreateFrame("Frame", nil, parent)
        box:SetSize(120, 44)
        box:SetPoint(anchorPoint, parent, "TOP", offsetX, -10)

        local bg = box:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(box)
        bg:SetVertexColor(0.44, 0.40, 0.36, 1)

        return box
    end

    -- Score Box (links von Mitte)
    local scoreBox = MakeBox("TOPRIGHT", -4)

    local scoreLbl = scoreBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scoreLbl:SetPoint("TOP", scoreBox, "TOP", 0, -6)
    scoreLbl:SetText(GamingHub.GetLocaleTable("2048")["score_label"])
    scoreLbl:SetTextColor(0.85, 0.80, 0.75)

    local scoreVal = scoreBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    scoreVal:SetPoint("CENTER", scoreBox, "CENTER", 0, -4)
    scoreVal:SetText("0")
    scoreVal:SetTextColor(1, 1, 1)
    self.scoreFS = scoreVal

    -- Best Box (rechts von Mitte)
    local bestBox = MakeBox("TOPLEFT", 4)

    local bestLbl = bestBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bestLbl:SetPoint("TOP", bestBox, "TOP", 0, -6)
    bestLbl:SetText(GamingHub.GetLocaleTable("2048")["best_label"])
    bestLbl:SetTextColor(0.85, 0.80, 0.75)

    local bestVal = bestBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bestVal:SetPoint("CENTER", bestBox, "CENTER", 0, -4)
    bestVal:SetText("0")
    bestVal:SetTextColor(1, 0.84, 0)
    self.bestFS = bestVal
end

-- ============================================================
-- Größen-Auswahl (Brett-Größe direkt im Spielfeld, wie VierGewinnt)
-- ============================================================

local function GetSizes()
    local L = GamingHub.GetLocaleTable("2048")
    return {
        { label = L["size_small"],  size = 3 },
        { label = L["size_normal"], size = 4 },
        { label = L["size_large"],  size = 5 },
    }
end

function Renderer:CreateSizeButtons()
    if self.sizeContainer then return end

    local container = CreateFrame("Frame", nil, self.frame)
    container:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 8)
    container:SetSize(500, 30)
    self.sizeContainer = container

    local W       = 130
    local spacing = 14
    local SIZES   = GetSizes()
    local totalW  = #SIZES * W + (#SIZES - 1) * spacing
    local startX  = -math.floor(totalW / 2)

    for i, mode in ipairs(SIZES) do
        local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
        btn:SetSize(W, 28)
        btn:SetPoint("LEFT", container, "CENTER", startX + (i-1)*(W+spacing), 0)
        btn:SetText(mode.label)
        btn:SetScript("OnClick", function()
            Renderer:SelectSize(mode.size, btn)
        end)
        table.insert(self.sizeBtns, btn)
    end
end

function Renderer:SelectSize(size, clicked)
    self.selectedSize = size
    -- Einstellung persistieren
    local S = GamingHub.TDG_Settings
    if S then S:Set("boardSize", size) end
    -- Button-Highlight
    for _, btn in ipairs(self.sizeBtns) do btn:UnlockHighlight() end
    clicked:LockHighlight()
    -- Spiel sofort starten
    GamingHub.TDG_Engine:StartGame({ size = size })
end

-- ============================================================
-- Exit Button
-- ============================================================

function Renderer:CreateExitButton()
    if self.exitButton then return end
    local btn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    btn:SetSize(100, 28)
    btn:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 20, 5)
    btn:SetText(GamingHub.GetLocaleTable("2048")["btn_exit"])
    btn:SetScript("OnClick", function()
        GamingHub.TDG_Engine:StopGame()
    end)
    btn:Hide()
    self.exitButton = btn
end

-- ============================================================
-- Overlay (Game Over / Win)
-- ============================================================

function Renderer:CreateOverlay()
    if self.overlay then return end

    local overlay = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    overlay:SetAllPoints(self.frame)
    overlay:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
    overlay:SetBackdropColor(0, 0, 0, 0.72)
    overlay:EnableMouse(false)
    overlay:Hide()

    local titleFS = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    titleFS:SetPoint("CENTER", overlay, "CENTER", 0, 40)
    overlay.titleFS = titleFS

    local subFS = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subFS:SetPoint("TOP", titleFS, "BOTTOM", 0, -8)
    overlay.subFS = subFS

    -- Neu starten-Button (nutzt gespeicherte Größe)
    local restartBtn = CreateFrame("Button", nil, overlay, "UIPanelButtonTemplate")
    restartBtn:SetSize(140, 28)
    restartBtn:SetPoint("TOP", overlay.subFS, "BOTTOM", 0, -16)
    overlay.restartBtn = restartBtn
    restartBtn:SetText(GamingHub.GetLocaleTable("2048")["btn_new_game"])
    restartBtn:SetScript("OnClick", function()
        overlay:Hide()
        -- Gleiche Größe wie zuletzt gespielt
        GamingHub.TDG_Engine:StartGame({ size = Renderer.selectedSize or 4 })
    end)

    self.overlay = overlay
end

-- ============================================================
-- KeyFrame – fängt WASD + Pfeiltasten ab
-- ============================================================

function Renderer:CreateKeyFrame()
    if self.keyFrame then return end

    local kf = CreateFrame("Frame", "GamingHub_2048_KeyFrame", self.frame)
    kf:SetAllPoints(self.frame)
    kf:EnableKeyboard(false)  -- erst aktivieren wenn Spiel läuft
    kf:SetPropagateKeyboardInput(false)

    local keyMap = {
        ["W"]      = "UP",
        ["S"]      = "DOWN",
        ["A"]      = "LEFT",
        ["D"]      = "RIGHT",
        ["UP"]     = "UP",
        ["DOWN"]   = "DOWN",
        ["LEFT"]   = "LEFT",
        ["RIGHT"]  = "RIGHT",
    }

    kf:SetScript("OnKeyDown", function(self_kf, key)
        local dir = keyMap[key]
        if dir then
            kf:SetPropagateKeyboardInput(false)
            GamingHub.TDG_Engine:HandlePlayerMove(dir)
        else
            kf:SetPropagateKeyboardInput(true)
        end
    end)

    self.keyFrame = kf
end

-- ============================================================
-- Idle State
-- ============================================================

function Renderer:EnterIdleState()
    self.state = "IDLE"

    -- Kacheln verstecken
    for r = 1, #self.tiles do
        for c = 1, #(self.tiles[r] or {}) do
            local t = self.tiles[r][c]
            if t and t.frame then t.frame:Hide() end
        end
    end
    self.tiles = {}

    -- Leere Slot-Texturen verstecken und Liste leeren
    for r = 1, #(self.emptySlots or {}) do
        for c = 1, #(self.emptySlots[r] or {}) do
            if self.emptySlots[r][c] then self.emptySlots[r][c]:Hide() end
        end
    end
    self.emptySlots = {}

    -- Board-BG verstecken
    if self.boardBg then self.boardBg:Hide() end

    -- Score zurücksetzen
    if self.scoreFS then self.scoreFS:SetText("0") end

    -- Overlay verstecken
    if self.overlay then self.overlay:Hide() end

    -- Tastatur aus
    if self.keyFrame then self.keyFrame:EnableKeyboard(false) end

    -- Exit-Button verstecken, Größen-Buttons zeigen
    if self.exitButton    then self.exitButton:Hide() end
    if self.sizeContainer then self.sizeContainer:Show() end

    -- Highlight des zuletzt gewählten Größen-Buttons wiederherstellen
    for i, btn in ipairs(self.sizeBtns) do
        btn:UnlockHighlight()
        local SIZES_REF = GetSizes()
        if SIZES_REF[i] and SIZES_REF[i].size == self.selectedSize then
            btn:LockHighlight()
        end
    end

    -- Starthinweis
    if not self.hintFS then
        local hint = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hint:SetPoint("CENTER", self.frame, "CENTER", 0, 10)
        hint:SetText(GamingHub.GetLocaleTable("2048")["hint_start"])
        hint:SetJustifyH("CENTER")
        self.hintFS = hint
    end
    self.hintFS:Show()
end

-- ============================================================
-- RenderBoard – erstellt alle Kachel-Frames
-- ============================================================

function Renderer:RenderBoard(state)
    -- Hint + Größen-Buttons verstecken
    if self.hintFS        then self.hintFS:Hide()        end
    if self.sizeContainer then self.sizeContainer:Hide() end

    -- Alte Kacheln aufräumen
    for r = 1, #self.tiles do
        for c = 1, #(self.tiles[r] or {}) do
            local t = self.tiles[r][c]
            if t and t.frame then t.frame:Hide() end
        end
    end
    self.tiles = {}

    -- GRID-BUG-FIX: Alte Slot-Texturen vollständig verstecken und Liste leeren.
    -- Bei Größenwechsel (z.B. 5×5 → 3×3) würden sonst überzählige Slots
    -- sichtbar bleiben und das neue Grid falsch erscheinen lassen.
    for r = 1, #(self.emptySlots or {}) do
        for c = 1, #(self.emptySlots[r] or {}) do
            if self.emptySlots[r][c] then
                self.emptySlots[r][c]:Hide()
            end
        end
    end
    self.emptySlots = {}

    if self.exitButton then self.exitButton:Show() end

    local parent = self.frame
    local W      = parent:GetWidth()
    local H      = parent:GetHeight()

    local size    = state.size
    local GAP     = 10   -- breitere Fugen für sichtbares Grid
    local usable  = math.min(W * 0.72, H * 0.68)
    local cell    = math.floor((usable - GAP * (size + 1)) / size)
    local boardPx = cell * size + GAP * (size + 1)

    self.boardSize = size
    self.cellPx    = cell
    self.offsetX   = math.floor((W - boardPx) / 2)
    self.offsetY   = math.floor((H - boardPx) / 2) + 20

    -- ── Board-Hintergrund (Theme-Fugenfarbe) ──
    local theme = GetActiveTheme()
    if not self.boardBg then
        self.boardBg = parent:CreateTexture(nil, "BACKGROUND", nil, 0)
        self.boardBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    end
    self.boardBg:ClearAllPoints()
    self.boardBg:SetPoint("TOPLEFT", parent, "TOPLEFT",
        self.offsetX, -self.offsetY)
    self.boardBg:SetSize(boardPx, boardPx)
    self.boardBg:SetVertexColor(theme.boardBg[1], theme.boardBg[2], theme.boardBg[3], 1)
    self.boardBg:Show()

    -- ── Leere Slot-Texturen (Theme-Slot-Farbe) ──
    if not self.emptySlots then self.emptySlots = {} end
    for r = 1, size do
        self.emptySlots[r] = self.emptySlots[r] or {}
        for c = 1, size do
            if not self.emptySlots[r][c] then
                local tex = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
                tex:SetTexture("Interface\\Buttons\\WHITE8X8")
                self.emptySlots[r][c] = tex
            end
            local px2 = self.offsetX + GAP + (c-1) * (cell + GAP)
            local py2 = self.offsetY + GAP + (r-1) * (cell + GAP)
            self.emptySlots[r][c]:ClearAllPoints()
            self.emptySlots[r][c]:SetPoint("TOPLEFT", parent, "TOPLEFT", px2, -py2)
            self.emptySlots[r][c]:SetSize(cell, cell)
            self.emptySlots[r][c]:SetVertexColor(theme.slotBg[1], theme.slotBg[2], theme.slotBg[3], 1)
            self.emptySlots[r][c]:Show()
        end
    end

    -- ── Kachel-Frames (ein Frame pro Zelle, Textur + Label) ──
    for r = 1, size do
        self.tiles[r] = {}
        for c = 1, size do
            local px = self.offsetX + GAP + (c-1) * (cell + GAP)
            local py = self.offsetY + GAP + (r-1) * (cell + GAP)

            -- Container-Frame (kein Backdrop – nur für Z-Order und Clipping)
            local tf = CreateFrame("Frame", nil, parent)
            tf:SetSize(cell, cell)
            tf:SetPoint("TOPLEFT", parent, "TOPLEFT", px, -py)

            -- Farb-Textur (ARTWORK, über Slot-BG)
            local bgTex = tf:CreateTexture(nil, "ARTWORK")
            bgTex:SetTexture("Interface\\Buttons\\WHITE8X8")
            bgTex:SetAllPoints(tf)
            bgTex:SetVertexColor(0, 0, 0, 0)   -- Start: unsichtbar

            -- Wert-Label (OVERLAY)
            local lbl = tf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            lbl:SetPoint("CENTER")
            lbl:SetJustifyH("CENTER")

            self.tiles[r][c] = { frame = tf, bgTex = bgTex, label = lbl }
        end
    end

    self:UpdateBoard(state)
end

-- ============================================================
-- UpdateBoard – Kacheln aktualisieren + Merge-Flash
-- ============================================================

function Renderer:UpdateBoard(state)
    local size = state.size

    for r = 1, size do
        for c = 1, size do
            local tile = self.tiles[r] and self.tiles[r][c]
            if tile then
                local val    = state.cells[r][c]
                local colors = GetTileColor(val)

                if val == 0 then
                    -- Leer: Kachel-Textur unsichtbar → Slot-BG darunter sichtbar
                    tile.bgTex:SetVertexColor(0, 0, 0, 0)
                    tile.label:SetText("")
                else
                    tile.bgTex:SetVertexColor(
                        colors.bg[1], colors.bg[2], colors.bg[3], 1)
                    tile.label:SetText(tostring(val))
                    tile.label:SetTextColor(
                        colors.fg[1], colors.fg[2], colors.fg[3])

                    -- Merge-Flash: kurze Aufhellung auf Weiß
                    if state.merged and state.merged[r][c] then
                        tile.bgTex:SetVertexColor(1, 1, 1, 1)
                        C_Timer.After(0.12, function()
                            if tile and tile.bgTex then
                                tile.bgTex:SetVertexColor(
                                    colors.bg[1], colors.bg[2], colors.bg[3], 1)
                            end
                        end)
                    end
                end

                tile.frame:Show()
            end
        end
    end

    -- Spawn-Fade: neue Kachel blendet ein
    if state.lastSpawn then
        local sp   = state.lastSpawn
        local tile = self.tiles[sp.row] and self.tiles[sp.row][sp.col]
        if tile then
            tile.frame:SetAlpha(0)
            UIFrameFadeIn(tile.frame, 0.20, 0, 1)
        end
    end
end

-- ============================================================
-- Score Update
-- ============================================================

function Renderer:UpdateScore(state)
    if self.scoreFS then
        self.scoreFS:SetText(tostring(state.score or 0))
    end
    if self.bestFS then
        self.bestFS:SetText(tostring(state.bestScore or 0))
    end
end

-- ============================================================
-- Game Over Overlay
-- ============================================================

function Renderer:ShowGameOverOverlay()
    if not self.overlay then return end
    self.state = "GAMEOVER"

    local state = GamingHub.TDG_Engine.activeGame
        and GamingHub.TDG_Engine.activeGame:GetBoardState()

    local L2048 = GamingHub.GetLocaleTable("2048")
    self.overlay.titleFS:SetText(L2048["go_title"])
    self.overlay.titleFS:SetTextColor(1, 0.3, 0.3)
    self.overlay.subFS:SetText(L2048["go_score"] .. (state and state.score or 0))
    self.overlay.subFS:SetTextColor(1, 1, 1)

    self.overlay.restartBtn:ClearAllPoints()
    self.overlay.restartBtn:SetPoint("TOP", self.overlay.subFS, "BOTTOM", 0, -16)

    self.overlay:SetAlpha(0)
    self.overlay:Show()
    UIFrameFadeIn(self.overlay, 0.4, 0, 0.72)
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "2048",
    label     = "2048",
    renderer  = "TDG_Renderer",
    engine    = "TDG_Engine",
    container = "_2048Container",
})
