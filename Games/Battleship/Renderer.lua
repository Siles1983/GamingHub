--[[
    Gaming Hub
    Games/Battleship/Renderer.lua
    Version: 1.1.0

    Fixes gegenüber 1.0.0:
      - Grid-Größenberechnung komplett überarbeitet (passt in Content-Bereich)
      - ClearGrids speichert und versteckt ALLE erzeugten Frames (inkl. Labels)
      - Schwierigkeit-Auswahl NACH Größen-Button (zweistufig wie VierGewinnt)
      - SelectSize startet KEIN Spiel, schaltet nur Diff-Buttons frei
      - SelectDiff startet das Spiel
      - OnGameStarted rendert bereits das leere Spielerboard
      - Schiffe nach Placement korrekt sichtbar
      - lastShot nil-Prüfung in Engine verhindert false-positive Update
]]

local GamingHub = _G.GamingHub
GamingHub.BS_Renderer = {}
local R = GamingHub.BS_Renderer

-- ============================================================
-- Konstanten
-- ============================================================

local CELL_COLOR       = { 0.15, 0.18, 0.25, 1    }
local SHIP_COLOR       = { 0.55, 0.45, 0.30, 1    }
local HIT_COLOR        = { 0.85, 0.15, 0.10, 1    }
local MISS_COLOR       = { 0.25, 0.45, 0.65, 1    }
local SUNK_COLOR       = { 0.25, 0.22, 0.20, 1    }
local GHOST_OK_COLOR   = { 0.20, 0.80, 0.20, 0.45 }
local GHOST_BAD_COLOR  = { 0.85, 0.15, 0.10, 0.45 }
local LABEL_COLOR      = { 0.80, 0.75, 0.60, 1    }

-- ============================================================
-- State
-- ============================================================

R.frame           = nil
R.state           = "IDLE"
R.selectedSize    = nil   -- nil = noch nicht gewählt
R.selectedDiff    = nil   -- nil = noch nicht gewählt
R.sizeContainer   = nil
R.diffContainer   = nil
R.sizeBtns        = {}
R.diffBtns        = {}
R.exitButton      = nil
R.randomBtn       = nil
R.keyFrame        = nil

R.grids           = { {}, {} }
R.gridFrames      = { nil, nil }
R.gridLabels      = {}   -- alle erzeugten Label-FontStrings (müssen bei ClearGrids versteckt werden)
R.cellSize        = 0

R.ghostCells      = {}
R.hoverR          = nil
R.hoverC          = nil

R.overlay         = nil

-- ============================================================
-- Init
-- ============================================================

function R:Init()
    self:CreateMainFrame()
    self:CreateSizeButtons()
    self:CreateDiffButtons()
    self:CreateExitButton()
    self:CreateRandomButton()
    self:CreateOverlay()
    self:CreateKeyFrame()
    self:EnterIdleState()

    local Engine = GamingHub.Engine

    Engine:On("BS_GAME_STARTED",      function(state)  R:OnGameStarted(state)   end)
    Engine:On("BS_PLACEMENT_UPDATED", function(state)  R:OnPlacementUpdated(state) end)
    Engine:On("BS_BATTLE_STARTED",    function(state)  R:OnBattleStarted(state) end)
    Engine:On("BS_SHOT_FIRED",        function(state)  R:OnShotFired(state)     end)
    Engine:On("BS_GAME_OVER",         function(result) R:OnGameOver(result)     end)
    Engine:On("BS_GAME_STOPPED",      function()       R:EnterIdleState()       end)
end

-- ============================================================
-- Main Frame
-- ============================================================

function R:CreateMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end

    local container = CreateFrame("Frame", "GamingHub_BS_Container", gamesPanel)
    container:SetAllPoints(gamesPanel)
    container:Hide()
    self.frame = container
    if _G.GamingHub then _G.GamingHub._bsContainer = container end
end

-- ============================================================
-- Größen-Buttons
-- FIX: SelectSize startet KEIN Spiel mehr, schaltet nur Diff frei
-- ============================================================

local function GetSizes()
    local L = GamingHub.GetLocaleTable("BATTLESHIP")
    return {
        { label = L["size_8"],  size = 8  },
        { label = L["size_10"], size = 10 },
        { label = L["size_12"], size = 12 },
    }
end

function R:CreateSizeButtons()
    if self.sizeContainer then return end
    local c = CreateFrame("Frame", nil, self.frame)
    c:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 36)
    c:SetSize(500, 30)
    self.sizeContainer = c

    local SIZES = GetSizes()
    local W = 110; local SP = 14
    local totalW = #SIZES * W + (#SIZES-1)*SP
    local startX = -math.floor(totalW/2)

    for i, s in ipairs(SIZES) do
        local btn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        btn:SetSize(W, 28)
        btn:SetPoint("LEFT", c, "CENTER", startX + (i-1)*(W+SP), 0)
        btn:SetText(s.label)
        btn:SetScript("OnClick", function() R:SelectSize(s.size, btn) end)
        table.insert(self.sizeBtns, btn)
    end
end

function R:SelectSize(size, clicked)
    self.selectedSize = size
    local S = GamingHub.BS_Settings
    if S then S:Set("gridSize", size) end

    -- Highlight Größen-Button
    for _, b in ipairs(self.sizeBtns) do b:UnlockHighlight() end
    clicked:LockHighlight()

    -- Schwierigkeits-Buttons freischalten (wie VierGewinnt)
    if self.diffContainer then
        self.diffContainer:SetAlpha(1)
        for _, b in ipairs(self.diffBtns) do
            b:Enable()
        end
    end
    -- Hint aktualisieren
    if self.hintFS then
        self.hintFS:SetText(GamingHub.GetLocaleTable("BATTLESHIP")["hint_diff"])
        self.hintFS:Show()
    end
end

-- ============================================================
-- Schwierigkeits-Buttons
-- FIX: SelectDiff startet das Spiel (nicht SelectSize)
-- ============================================================

local function GetDiffs()
    local L = GamingHub.GetLocaleTable("BATTLESHIP")
    return {
        { label = L["diff_easy"],   value = "easy"   },
        { label = L["diff_normal"], value = "normal" },
        { label = L["diff_hard"],   value = "hard"   },
    }
end

function R:CreateDiffButtons()
    if self.diffContainer then return end
    local c = CreateFrame("Frame", nil, self.frame)
    c:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 6)
    c:SetSize(500, 30)
    c:SetAlpha(0.4)
    self.diffContainer = c

    local DIFFS = GetDiffs()
    local W = 100; local SP = 16
    local totalW = #DIFFS * W + (#DIFFS-1)*SP
    local startX = -math.floor(totalW/2)

    for i, d in ipairs(DIFFS) do
        local btn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        btn:SetSize(W, 28)
        btn:SetPoint("LEFT", c, "CENTER", startX + (i-1)*(W+SP), 0)
        btn:SetText(d.label)
        btn:Disable()
        btn:SetScript("OnClick", function() R:SelectDiff(d.value, btn) end)
        table.insert(self.diffBtns, btn)
    end
end

function R:SelectDiff(value, clicked)
    if not self.selectedSize then return end  -- Größe muss zuerst gewählt sein
    self.selectedDiff = value
    local S = GamingHub.BS_Settings
    if S then S:Set("aiDifficulty", value) end

    for _, b in ipairs(self.diffBtns) do b:UnlockHighlight() end
    clicked:LockHighlight()

    -- Jetzt erst Spiel starten
    GamingHub.BS_Engine:StartGame({
        size         = self.selectedSize,
        aiDifficulty = self.selectedDiff,
    })
end

-- ============================================================
-- Exit / Random Buttons
-- ============================================================

function R:CreateExitButton()
    if self.exitButton then return end
    local btn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    btn:SetSize(100, 28)
    btn:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 6)
    btn:SetText(GamingHub.GetLocaleTable("BATTLESHIP")["btn_exit"])
    btn:SetScript("OnClick", function() GamingHub.BS_Engine:StopGame() end)
    btn:Hide()
    self.exitButton = btn
end

function R:CreateRandomButton()
    if self.randomBtn then return end
    local btn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    btn:SetSize(140, 28)
    btn:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 6)
    btn:SetText(GamingHub.GetLocaleTable("BATTLESHIP")["btn_random"])
    btn:SetScript("OnClick", function() GamingHub.BS_Engine:HandleRandomPlacement() end)
    btn:Hide()
    self.randomBtn = btn
end

-- ============================================================
-- Key Frame (R = rotieren während Placement)
-- ============================================================

function R:CreateKeyFrame()
    if self.keyFrame then return end
    local kf = CreateFrame("Frame", "GamingHub_BS_KeyFrame", self.frame)
    kf:SetAllPoints(self.frame)
    kf:EnableKeyboard(false)
    kf:SetPropagateKeyboardInput(false)
    kf:SetScript("OnKeyDown", function(_, key)
        if key == "R" or key == "r" then
            kf:SetPropagateKeyboardInput(false)
            GamingHub.BS_Engine:ToggleOrientation()
            if R.hoverR and R.hoverC then
                local state = GamingHub.BS_Engine.activeGame
                    and GamingHub.BS_Engine.activeGame:GetBoardState()
                if state then R:UpdateGhost(state) end
            end
        else
            kf:SetPropagateKeyboardInput(true)
        end
    end)
    self.keyFrame = kf
end

-- ============================================================
-- Overlay
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
    title:SetPoint("CENTER", ov, "CENTER", 0, 30)
    ov.title = title

    local sub = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -8)
    ov.sub = sub

    local restartBtn = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
    restartBtn:SetSize(140, 28)
    restartBtn:SetPoint("TOP", sub, "BOTTOM", 0, -16)
    restartBtn:SetText(GamingHub.GetLocaleTable("BATTLESHIP")["btn_new_game"])
    restartBtn:SetScript("OnClick", function()
        ov:Hide()
        if R.selectedSize and R.selectedDiff then
            GamingHub.BS_Engine:StartGame({
                size         = R.selectedSize,
                aiDifficulty = R.selectedDiff,
            })
        end
    end)
    ov.restartBtn = restartBtn
    self.overlay = ov
end

-- ============================================================
-- Idle State
-- ============================================================

function R:EnterIdleState()
    self.state = "IDLE"
    self:ClearGrids()
    if self.overlay    then self.overlay:Hide()    end
    if self.exitButton then self.exitButton:Hide() end
    if self.randomBtn  then self.randomBtn:Hide()  end
    if self.keyFrame   then self.keyFrame:EnableKeyboard(false) end

    -- Diff-Buttons deaktivieren, Highlights zurücksetzen
    if self.diffContainer then
        self.diffContainer:SetAlpha(0.4)
        for _, b in ipairs(self.diffBtns) do
            b:Disable(); b:UnlockHighlight()
        end
    end

    -- Größen-Button Highlight wiederherstellen
    for i, b in ipairs(self.sizeBtns) do
        b:UnlockHighlight()
        local SIZES_REF = GetSizes()
        if SIZES_REF[i] and SIZES_REF[i].size == self.selectedSize then
            b:LockHighlight()
        end
    end

    if self.sizeContainer then self.sizeContainer:Show() end
    if self.diffContainer  then self.diffContainer:Show() end

    if not self.hintFS then
        local h = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetPoint("CENTER", self.frame, "CENTER", 0, 20)
        h:SetText(GamingHub.GetLocaleTable("BATTLESHIP")["hint_start"])
        h:SetJustifyH("CENTER")
        self.hintFS = h
    end
    self.hintFS:Show()
end

-- ============================================================
-- Grid erstellen
-- FIX: Größenberechnung komplett überarbeitet
--   - Zellgröße dynamisch aus verfügbarem Platz berechnet
--   - Buttons unten (70px) und Header oben (30px) berücksichtigt
--   - Beide Grids passen immer in den Content-Bereich
-- ============================================================

function R:BuildGrids(size)
    self:ClearGrids()

    local parent  = self.frame

    -- GetWidth/GetHeight liefern in WoW 0 wenn das Frame noch nicht gerendert wurde.
    -- Daher: feste Dimensionen aus dem bekannten Content-Panel-Layout verwenden.
    -- Content-Breite: 860 (MainW) - 22 (linker Rand) - (196+8+22) (CatPanel) - 22 (rechter Rand) = 590
    -- Content-Höhe:  640 (MainH) - 40 (Header) - 32 (Tabs) - 16 (Padding) = 552
    local W = parent:GetWidth()
    local H = parent:GetHeight()
    if W < 100 then W = 590 end   -- Fallback wenn GetWidth() noch 0 zurückgibt
    if H < 100 then H = 480 end

    -- Verfügbarer Bereich: oben 30px Hint, unten 80px für Buttons, 20px Seitenränder
    local availH  = H - 30 - 80
    local availW  = (W - 40 - 20) / 2

    -- Zellgröße: kleinstes aus beiden Achsen, auf 2px abgerundet
    local cellF   = math.min(availW / size, availH / size)
    local cell    = math.max(14, math.floor(cellF / 2) * 2)  -- min 14, gerade Zahl
    local boardPx = cell * size

    -- Beide Grids zentriert anordnen
    local totalGridW = boardPx * 2 + 20  -- 20px Abstand zwischen Grids
    local offXBase   = math.floor((W - totalGridW) / 2)
    local offYBase   = 30  -- Platz für Hint oben

    self.cellSize = cell

    for side = 1, 2 do
        self.grids[side] = {}
        local offX = offXBase + (side-1) * (boardPx + 20)

        -- Grid-Rahmen (1px Border-Farbe)
        local gf = CreateFrame("Frame", nil, parent)
        gf:SetSize(boardPx + 2, boardPx + 2)
        gf:SetPoint("TOPLEFT", parent, "TOPLEFT", offX - 1, -(offYBase - 1))
        local gbg = gf:CreateTexture(nil, "BACKGROUND")
        gbg:SetTexture("Interface\\Buttons\\WHITE8X8")
        gbg:SetAllPoints(gf)
        gbg:SetVertexColor(0.08, 0.09, 0.12, 1)  -- Sehr dunkel = sichtbare Gitterlinien
        self.gridFrames[side] = gf

        -- Beschriftung (wird in gridLabels gespeichert für ClearGrids)
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("BOTTOM", gf, "TOP", 0, 4)
        local _L = GamingHub.GetLocaleTable("BATTLESHIP")
        label:SetText(side == 1 and _L["label_player"] or _L["label_enemy"])
        label:SetTextColor(LABEL_COLOR[1], LABEL_COLOR[2], LABEL_COLOR[3])
        table.insert(self.gridLabels, label)

        -- Zellen
        for r = 1, size do
            self.grids[side][r] = {}
            for c = 1, size do
                local px = offX + (c-1) * cell
                local py = offYBase + (r-1) * cell

                local tf = CreateFrame("Button", nil, parent)
                tf:SetSize(cell - 1, cell - 1)
                tf:SetPoint("TOPLEFT", parent, "TOPLEFT", px, -py)
                tf:EnableMouse(true)

                -- NormalTexture als Hintergrund (garantiert sichtbar bei Buttons)
                tf:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
                local bg = tf:GetNormalTexture()
                bg:SetVertexColor(CELL_COLOR[1], CELL_COLOR[2], CELL_COLOR[3], CELL_COLOR[4])

                local marker = tf:CreateTexture(nil, "ARTWORK")
                marker:SetAllPoints(tf)
                marker:Hide()

                -- Ghost als eigenes Frame über dem Button (NormalTexture überdecken)
                local ghostFrame = CreateFrame("Frame", nil, tf)
                ghostFrame:SetAllPoints(tf)
                ghostFrame:Hide()
                local ghost = ghostFrame:CreateTexture(nil, "BACKGROUND")
                ghost:SetTexture("Interface\\Buttons\\WHITE8X8")
                ghost:SetAllPoints(ghostFrame)
                ghost:SetVertexColor(0, 0, 0, 0)

                local cell_data = {
                    frame      = tf,
                    bg         = bg,
                    marker     = marker,
                    ghost      = ghost,
                    ghostFrame = ghostFrame,
                    r          = r,
                    c          = c,
                    side       = side,
                }
                self.grids[side][r][c] = cell_data

                local cr, cc, cs = r, c, side
                tf:SetScript("OnClick", function(_, button)
                    if button == "RightButton" and R.state == "PLACEMENT" then
                        -- Rechtsklick = Rotation
                        GamingHub.BS_Engine:ToggleOrientation()
                        if R.hoverR and R.hoverC then
                            local st = GamingHub.BS_Engine.activeGame
                                and GamingHub.BS_Engine.activeGame:GetBoardState()
                            if st then R:UpdateGhost(st) end
                        end
                    else
                        R:OnCellClick(cs, cr, cc)
                    end
                end)
                tf:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                tf:SetScript("OnEnter", function()
                    if cs == 1 and R.state == "PLACEMENT" then
                        R.hoverR = cr
                        R.hoverC = cc
                        local state = GamingHub.BS_Engine.activeGame
                            and GamingHub.BS_Engine.activeGame:GetBoardState()
                        if state then R:UpdateGhost(state) end
                    end
                end)
                tf:SetScript("OnLeave", function()
                    if cs == 1 and R.state == "PLACEMENT" then
                        R:ClearGhost()
                    end
                end)
            end
        end
    end
end

-- ============================================================
-- ClearGrids
-- FIX: Labels werden jetzt ebenfalls versteckt
-- ============================================================

function R:ClearGrids()
    -- Alle Zell-Frames verstecken
    for side = 1, 2 do
        for r = 1, #(self.grids[side] or {}) do
            for c = 1, #(self.grids[side][r] or {}) do
                local cd = self.grids[side][r][c]
                if cd and cd.frame then cd.frame:Hide() end
            end
        end
        self.grids[side] = {}
        if self.gridFrames[side] then
            self.gridFrames[side]:Hide()
            self.gridFrames[side] = nil
        end
    end

    -- Grid-Labels verstecken (FIX: vorher nie aufgeräumt)
    for _, lbl in ipairs(self.gridLabels) do
        if lbl then lbl:Hide() end
    end
    self.gridLabels = {}

    self:ClearGhost()
end

-- ============================================================
-- Zelle färben
-- ============================================================

function R:ColorCell(side, r, c, color, alpha)
    local cd = self.grids[side] and self.grids[side][r] and self.grids[side][r][c]
    if not cd then return end
    cd.bg:SetVertexColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

-- ============================================================
-- Marker setzen
-- FIX: ReadyCheck-NotReady für Treffer-X, kein Marker-Hide bei SUNK
-- ============================================================

function R:SetMarker(side, r, c, markerType)
    local cd = self.grids[side] and self.grids[side][r] and self.grids[side][r][c]
    if not cd then return end

    if markerType == "HIT" then
        -- Rotes X (Interface\RaidFrame\ReadyCheck-NotReady ist verifizierter WoW-Pfad)
        cd.marker:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        cd.marker:SetVertexColor(1, 1, 1, 1)
        cd.marker:ClearAllPoints()
        local s = math.floor(cd.frame:GetWidth() * 0.75)
        cd.marker:SetSize(s, s)
        cd.marker:SetPoint("CENTER")
        cd.marker:Show()
        cd.bg:SetVertexColor(HIT_COLOR[1], HIT_COLOR[2], HIT_COLOR[3], 0.7)

    elseif markerType == "MISS" then
        -- Kleiner blauer Punkt
        cd.marker:SetTexture("Interface\\Buttons\\WHITE8X8")
        cd.marker:SetVertexColor(0.55, 0.75, 0.90, 0.9)
        cd.marker:ClearAllPoints()
        local s = math.floor(cd.frame:GetWidth() * 0.35)
        cd.marker:SetSize(s, s)
        cd.marker:SetPoint("CENTER")
        cd.marker:Show()
        cd.bg:SetVertexColor(MISS_COLOR[1], MISS_COLOR[2], MISS_COLOR[3], MISS_COLOR[4])

    elseif markerType == "SUNK" then
        -- FIX: Schiff bleibt sichtbar (dunkelgrau), schwaches X bleibt sichtbar
        cd.bg:SetVertexColor(SUNK_COLOR[1], SUNK_COLOR[2], SUNK_COLOR[3], 1)
        cd.marker:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        cd.marker:SetVertexColor(1, 0.5, 0.5, 0.55)
        cd.marker:ClearAllPoints()
        local s = math.floor(cd.frame:GetWidth() * 0.6)
        cd.marker:SetSize(s, s)
        cd.marker:SetPoint("CENTER")
        cd.marker:Show()
    end
end

-- ============================================================
-- Ghost-Vorschau
-- ============================================================

function R:ClearGhost()
    for _, cd in ipairs(self.ghostCells) do
        if cd and cd.ghostFrame then
            cd.ghostFrame:Hide()
            cd.ghost:SetVertexColor(0, 0, 0, 0)
        end
    end
    self.ghostCells = {}
end

function R:UpdateGhost(state)
    self:ClearGhost()
    if not self.hoverR or not self.hoverC then return end
    if not state.currentShip then return end

    local ship  = state.currentShip
    local horiz = state.placementHoriz
    local valid = GamingHub.BS_Logic:IsValidPlacement(
        state.playerBoard, self.hoverR, self.hoverC, ship.length, horiz
    )
    local color = valid and GHOST_OK_COLOR or GHOST_BAD_COLOR

    for i = 0, ship.length - 1 do
        local tr = self.hoverR + (horiz and 0 or i)
        local tc = self.hoverC + (horiz and i or 0)
        local cd = self.grids[1] and self.grids[1][tr] and self.grids[1][tr][tc]
        if cd then
            cd.ghost:SetVertexColor(color[1], color[2], color[3], color[4])
            cd.ghostFrame:Show()
            table.insert(self.ghostCells, cd)  -- cd speichern, nicht nur ghost
        end
    end
end

-- ============================================================
-- Board rendern
-- ============================================================

function R:RenderPlayerBoard(state)
    local board = state.playerBoard
    for r = 1, board.size do
        for c = 1, board.size do
            local shipID = board.cells[r][c]
            local cd = self.grids[1] and self.grids[1][r] and self.grids[1][r][c]
            if cd then
                -- Ghost-Frame immer verstecken beim Rendern
                if cd.ghostFrame then cd.ghostFrame:Hide() end
                cd.ghost:SetVertexColor(0, 0, 0, 0)

                -- Grundfarbe setzen
                if shipID and shipID ~= 0 then
                    -- Schiff: warm braun/beige
                    cd.bg:SetVertexColor(SHIP_COLOR[1], SHIP_COLOR[2], SHIP_COLOR[3], 1)
                    cd.frame:SetAlpha(1)
                else
                    cd.bg:SetVertexColor(CELL_COLOR[1], CELL_COLOR[2], CELL_COLOR[3], 1)
                end

                -- Marker zurücksetzen
                cd.marker:Hide()

                -- Treffer/Miss-Marker setzen
                if board.hits[r][c] then
                    if shipID ~= 0 then
                        local ship = board.ships[shipID]
                        self:SetMarker(1, r, c, ship and ship.sunk and "SUNK" or "HIT")
                    else
                        self:SetMarker(1, r, c, "MISS")
                    end
                end
            end
        end
    end
end

function R:RenderAiBoard(state)
    local board = state.aiBoard
    for r = 1, board.size do
        for c = 1, board.size do
            local shipID = board.cells[r][c]
            local wasHit = board.hits[r][c]
            -- Marker zuerst verstecken
            local cd = self.grids[2] and self.grids[2][r] and self.grids[2][r][c]
            if cd then cd.marker:Hide() end

            if wasHit then
                if shipID ~= 0 then
                    local ship = board.ships[shipID]
                    if ship and ship.sunk then
                        -- FIX: Versenktes Schiff – SUNK_COLOR zeigen, Marker bleibt
                        self:ColorCell(2, r, c, SUNK_COLOR)
                        self:SetMarker(2, r, c, "SUNK")
                    else
                        -- Treffer, noch nicht versenkt
                        self:ColorCell(2, r, c, CELL_COLOR)
                        self:SetMarker(2, r, c, "HIT")
                    end
                else
                    -- Verfehlt
                    self:ColorCell(2, r, c, CELL_COLOR)
                    self:SetMarker(2, r, c, "MISS")
                end
            else
                -- Unberührt
                self:ColorCell(2, r, c, CELL_COLOR)
            end
        end
    end
end

-- ============================================================
-- Placement-Hint
-- ============================================================

function R:UpdatePlacementHint(state)
    if not self.placementHintFS then
        local h = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetPoint("TOP", self.frame, "TOP", 0, -8)
        h:SetJustifyH("CENTER")
        self.placementHintFS = h
    end
    local _LP = GamingHub.GetLocaleTable("BATTLESHIP")
    if state.currentShip then
        self.placementHintFS:SetText(
            string.format(_LP["placement_place"],
                state.currentShip.name, state.currentShip.length)
        )
    else
        self.placementHintFS:SetText(_LP["placement_done"])
    end
    self.placementHintFS:Show()
end

-- ============================================================
-- Event-Handler
-- ============================================================

function R:OnGameStarted(state)
    self.state = "PLACEMENT"
    if self.hintFS then self.hintFS:Hide() end
    if self.overlay then self.overlay:Hide() end

    self:BuildGrids(state.size)

    -- FIX: Spielerboard sofort rendern (zeigt leeres blaues Grid)
    self:RenderPlayerBoard(state)

    if self.exitButton then self.exitButton:Show()  end
    if self.randomBtn  then self.randomBtn:Show()   end
    if self.keyFrame   then self.keyFrame:EnableKeyboard(true) end

    -- Diff-Buttons während Spiel deaktivieren
    if self.diffContainer then
        self.diffContainer:SetAlpha(0.4)
        for _, b in ipairs(self.diffBtns) do b:Disable() end
    end

    self:UpdatePlacementHint(state)
end

function R:OnPlacementUpdated(state)
    -- FIX: Schiffe nach Placement sichtbar
    self:RenderPlayerBoard(state)
    self:ClearGhost()
    self:UpdatePlacementHint(state)
end

function R:OnBattleStarted(state)
    self.state = "BATTLE"
    if self.randomBtn then self.randomBtn:Hide() end

    self:RenderPlayerBoard(state)
    self:RenderAiBoard(state)

    if not self.battleHintFS then
        local h = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetPoint("TOP", self.frame, "TOP", 0, -8)
        h:SetJustifyH("CENTER")
        self.battleHintFS = h
    end
    self.battleHintFS:SetText(GamingHub.GetLocaleTable("BATTLESHIP")["hint_battle"])
    self.battleHintFS:Show()

    if self.placementHintFS then self.placementHintFS:Hide() end
end

function R:OnShotFired(state)
    self:RenderPlayerBoard(state)
    self:RenderAiBoard(state)

    -- Flash auf letztem KI-Schuss
    if state.lastAiShot then
        local s  = state.lastAiShot
        local cd = self.grids[1] and self.grids[1][s.r] and self.grids[1][s.r][s.c]
        if cd then
            cd.frame:SetAlpha(0)
            UIFrameFadeIn(cd.frame, 0.25, 0, 1)
        end
    end
end

function R:OnGameOver(result)
    self.state = "GAMEOVER"

    -- Alle KI-Schiffe aufdecken
    local game = GamingHub.BS_Engine.activeGame
    if game then
        local state = game:GetBoardState()
        for _, ship in pairs(state.aiBoard.ships) do
            for _, cell in ipairs(ship.cells) do
                if not state.aiBoard.hits[cell.r][cell.c] then
                    self:ColorCell(2, cell.r, cell.c,
                        ship.sunk and SUNK_COLOR or SHIP_COLOR)
                end
            end
        end
    end

    if self.keyFrame then self.keyFrame:EnableKeyboard(false) end

    local ov = self.overlay
    if not ov then return end

    if result == "WIN" then
        local _LO = GamingHub.GetLocaleTable("BATTLESHIP")
        ov.title:SetText(_LO["result_win"])
        ov.title:SetTextColor(1, 0.84, 0)
        ov.sub:SetText(_LO["result_win_sub"])
    else
        local _LO2 = GamingHub.GetLocaleTable("BATTLESHIP")
        ov.title:SetText(_LO2["result_loss"])
        ov.title:SetTextColor(1, 0.3, 0.3)
        ov.sub:SetText(_LO2["result_loss_sub"])
    end

    ov:SetAlpha(0)
    ov:Show()
    UIFrameFadeIn(ov, 0.4, 0, 0.72)
end

-- ============================================================
-- Cell Click
-- ============================================================

function R:OnCellClick(side, r, c)
    if self.state == "PLACEMENT" and side == 1 then
        GamingHub.BS_Engine:HandlePlacement(r, c)
    elseif self.state == "BATTLE" and side == 2 then
        GamingHub.BS_Engine:HandleShot(r, c)
    end
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "BATTLESHIP",
    label     = "Schiffe versenken",
    renderer  = "BS_Renderer",
    engine    = "BS_Engine",
    container = "_bsContainer",
})
