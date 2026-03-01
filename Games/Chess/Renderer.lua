--[[
    Gaming Hub
    Games/Chess/Renderer.lua
    Version: 1.0.0

    Layout:
      ┌─────────────────────────────────────────────┐
      │  [Geschlagene weiße Figuren] oben           │
      │  [Status: Zug X / Schach / KI denkt...]     │
      │                                             │
      │   ┌─── 6×6 Schachbrett ──────────────────┐ │
      │   │  Spalten-Label: a-f                   │ │
      │   │  Zeilen-Label:  6-1                   │ │
      │   └───────────────────────────────────────┘ │
      │                                             │
      │  [Geschlagene schwarze Figuren] unten       │
      │  [Classic][Pro][Insane]                     │
      │  [Beenden]              [Aufgeben]          │
      └─────────────────────────────────────────────┘

    Figuren-Icons (WoW-Pfade):
      Weiß (Allianz, bläulicher Tint 0.5,0.7,1.0):
        König   – INV_Helmet_01
        Dame    – INV_Jewelry_Ring_05
        Turm    – Ability_Repair
        Springer– Ability_Mount_RidingHorse
        Bauer   – INV_Shield_06

      Schwarz (Horde, rötlicher Tint 1.0,0.3,0.3):
        König   – INV_Helmet_02
        Dame    – INV_Jewelry_Ring_01
        Turm    – INV_Stone_15
        Springer– Ability_Mount_Raptor
        Bauer   – INV_Shield_05

    Schachbrett-Muster:
      (r+c) gerade → Hellfeld  { 0.55, 0.50, 0.40 }
      (r+c) ungerade → Dunkelfeld { 0.20, 0.17, 0.13 }

    Highlights:
      Ausgewählte Figur → Gold   { 0.9, 0.75, 0.1 }
      Legale Züge       → Grün   { 0.1, 0.7, 0.2 }
      Letzter Zug       → Blau   { 0.2, 0.4, 0.8 }
      König im Schach   → Rot    { 0.8, 0.1, 0.1 }
]]

local GamingHub = _G.GamingHub
GamingHub.Chess_Renderer = {}
local R = GamingHub.Chess_Renderer

-- ============================================================
-- Icon-Tabelle
-- ============================================================
local ICONS = {
    white = {
        KING   = "Interface\\Icons\\INV_Helmet_01",
        QUEEN  = "Interface\\Icons\\INV_Jewelry_Ring_05",
        ROOK   = "Interface\\Icons\\Ability_Repair",
        KNIGHT = "Interface\\Icons\\Ability_Mount_RidingHorse",
        PAWN   = "Interface\\Icons\\INV_Shield_06",
    },
    black = {
        KING   = "Interface\\Icons\\INV_Helmet_02",
        QUEEN  = "Interface\\Icons\\INV_Jewelry_Ring_01",
        ROOK   = "Interface\\Icons\\INV_Stone_15",
        KNIGHT = "Interface\\Icons\\Ability_Mount_Raptor",
        PAWN   = "Interface\\Icons\\INV_Shield_05",
    },
}

-- Figurennamen (lokalisiert)
local function GetPieceNames()
    local L = GamingHub.GetLocaleTable("CHESS")
    return {
        KING   = L["piece_king"],
        QUEEN  = L["piece_queen"],
        ROOK   = L["piece_rook"],
        KNIGHT = L["piece_knight"],
        PAWN   = L["piece_pawn"],
    }
end

-- Tint-Farben
local TINT_WHITE = { 0.55, 0.70, 1.00 }
local TINT_BLACK = { 1.00, 0.35, 0.35 }

-- ============================================================
-- Brett-Farben
-- ============================================================
local LIGHT_FIELD   = { 0.55, 0.50, 0.40, 1 }
local DARK_FIELD    = { 0.20, 0.17, 0.13, 1 }
local CLR_SELECTED  = { 0.90, 0.75, 0.10, 1 }
local CLR_LEGAL     = { 0.10, 0.65, 0.20, 1 }
local CLR_LASTMOVE  = { 0.20, 0.40, 0.80, 1 }
local CLR_CHECK     = { 0.80, 0.10, 0.10, 1 }

-- ============================================================
-- Konstanten
-- ============================================================
local CELL_SIZE  = 66    -- px pro Feld
local LABEL_W    = 18    -- Zeilen-Label links
local BOARD_PX   = CELL_SIZE * 6

-- ============================================================
-- State
-- ============================================================
R.frame         = nil
R.state         = "IDLE"
R.selectedDiff  = nil

R.cells         = {}      -- cells[r][c] = { frame, bg, iconTex, hlFrame, hlTex }
R.boardHolder   = nil

R.diffBtns      = {}
R.diffContainer = nil
R.exitButton    = nil
R.resignButton  = nil
R.statusFS      = nil
R.hintFS        = nil
R.overlay       = nil
R.captureBarTop = nil     -- geschlagene schwarze Figuren (Spieler hat geschlagen)
R.captureBarBot = nil     -- geschlagene weiße Figuren (KI hat geschlagen)

-- ============================================================
-- Init
-- ============================================================

function R:Init()
    self:CreateMainFrame()
    self:CreateBoard()
    self:CreateDiffButtons()
    self:CreateBottomButtons()
    self:CreateStatusText()
    self:CreateCaptureBars()
    self:CreateOverlay()
    self:EnterIdleState()

    local Engine = GamingHub.Engine
    Engine:On("CHE_GAME_STARTED",    function(s)    R:OnGameStarted(s)        end)
    Engine:On("CHE_PIECE_SELECTED",  function(s)    R:OnPieceSelected(s)      end)
    Engine:On("CHE_PIECE_DESELECTED",function(s)    R:OnBoardUpdated(s)       end)
    Engine:On("CHE_MOVE_MADE",       function(s, r) R:OnMoveMade(s, r)        end)
    Engine:On("CHE_AI_MOVE",         function(s, r) R:OnAIMove(s, r)          end)
    Engine:On("CHE_GAME_OVER",       function(s)    R:OnGameOver(s)           end)
    Engine:On("CHE_GAME_STOPPED",    function()     R:EnterIdleState()        end)
end

-- ============================================================
-- Main Frame
-- ============================================================

function R:CreateMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end

    local f = CreateFrame("Frame", "GamingHub_CHE_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    self.frame = f
    if _G.GamingHub then _G.GamingHub._cheContainer = f end
end

-- ============================================================
-- Schachbrett aufbauen
-- ============================================================

function R:CreateBoard()
    if self.boardHolder then return end
    local parent = self.frame

    -- Äußerer Rahmen
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(LABEL_W + BOARD_PX + 2, BOARD_PX + LABEL_W + 2)
    holder:SetPoint("TOP", parent, "TOP", 0, -38)

    -- Gold-Rahmen
    local outerBG = holder:CreateTexture(nil, "BACKGROUND")
    outerBG:SetTexture("Interface\\Buttons\\WHITE8X8")
    outerBG:SetAllPoints(holder)
    outerBG:SetVertexColor(0.70, 0.60, 0.35, 1)
    self.boardHolder = holder

    -- Spalten-Labels (a-f) unten
    local colLabels = { "a","b","c","d","e","f" }
    for c = 1, 6 do
        local lbl = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetSize(CELL_SIZE, LABEL_W)
        lbl:SetPoint("TOPLEFT", holder, "TOPLEFT",
            LABEL_W + (c-1)*CELL_SIZE + 1,
            -(BOARD_PX + 2))
        lbl:SetText(colLabels[c])
        lbl:SetJustifyH("CENTER")
        lbl:SetTextColor(0.80, 0.72, 0.50)
    end

    -- Zeilen-Labels (6-1) links
    for r = 1, 6 do
        local lbl = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetSize(LABEL_W, CELL_SIZE)
        lbl:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -((r-1)*CELL_SIZE + 1))
        lbl:SetText(tostring(7 - r))
        lbl:SetJustifyH("CENTER")
        lbl:SetJustifyV("MIDDLE")
        lbl:SetTextColor(0.80, 0.72, 0.50)
    end

    -- 36 Felder
    for r = 1, 6 do
        self.cells[r] = {}
        for c = 1, 6 do
            local px = LABEL_W + (c-1)*CELL_SIZE + 1
            local py = (r-1)*CELL_SIZE + 1

            local tf = CreateFrame("Button", nil, holder)
            tf:SetSize(CELL_SIZE, CELL_SIZE)
            tf:SetPoint("TOPLEFT", holder, "TOPLEFT", px, -py)
            tf:EnableMouse(true)
            tf:SetNormalTexture("Interface\\Buttons\\WHITE8X8")

            local bg = tf:GetNormalTexture()
            local isLight = (r + c) % 2 == 0
            local fc = isLight and LIGHT_FIELD or DARK_FIELD
            bg:SetVertexColor(fc[1], fc[2], fc[3], 1)

            -- Highlight-Frame (über bg, unter Icon)
            local hlFrame = CreateFrame("Frame", nil, tf)
            hlFrame:SetAllPoints(tf)
            hlFrame:SetFrameLevel(tf:GetFrameLevel())
            hlFrame:EnableMouse(false)
            hlFrame:Hide()
            local hlTex = hlFrame:CreateTexture(nil, "OVERLAY")
            hlTex:SetTexture("Interface\\Buttons\\WHITE8X8")
            hlTex:SetAllPoints(hlFrame)
            hlTex:SetVertexColor(0, 0, 0, 0)

            -- Figur-Icon (über Highlight)
            local iconFrame = CreateFrame("Frame", nil, tf)
            iconFrame:SetPoint("CENTER", tf, "CENTER", 0, 0)
            iconFrame:SetSize(CELL_SIZE - 8, CELL_SIZE - 8)
            iconFrame:SetFrameLevel(tf:GetFrameLevel() + 2)
            iconFrame:EnableMouse(false)
            local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
            iconTex:SetAllPoints(iconFrame)
            iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)  -- Icon-Rand abschneiden
            iconTex:Hide()

            -- Click-Handler
            local cr, cc = r, c
            tf:SetScript("OnClick", function()
                GamingHub.Chess_Engine:HandleCellClick(cr, cc)
            end)

            -- Hover: Koordinaten anzeigen
            tf:SetScript("OnEnter", function()
                if R.state == "PLAYING" then
                    local p = GamingHub.Chess_Engine.activeGame
                        and GamingHub.Chess_Engine.activeGame:GetBoardState()
                    if p and p.board and p.board[cr][cc] then
                        local piece = p.board[cr][cc]
                        GameTooltip:SetOwner(tf, "ANCHOR_RIGHT")
                        GameTooltip:SetText(
                            (piece.color == "white" and "|cff8888ff" or "|cffff4444") ..
                            GetPieceNames()[piece.type] .. "|r"
                        )
                        GameTooltip:Show()
                    end
                end
            end)
            tf:SetScript("OnLeave", function() GameTooltip:Hide() end)

            self.cells[r][c] = {
                frame    = tf,
                bg       = bg,
                hlFrame  = hlFrame,
                hlTex    = hlTex,
                iconFrame= iconFrame,
                iconTex  = iconTex,
                isLight  = isLight,
            }
        end
    end
end

-- ============================================================
-- Schwierigkeits-Buttons
-- ============================================================

local function GetDiffs()
    local L = GamingHub.GetLocaleTable("CHESS")
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
    local S = GamingHub.Chess_Settings
    if S then S:Set("difficulty", value) end
    for _, b in ipairs(self.diffBtns) do b:UnlockHighlight() end
    clicked:LockHighlight()
    GamingHub.Chess_Engine:StartGame({ difficulty = value })
end

-- ============================================================
-- Untere Buttons
-- ============================================================

function R:CreateBottomButtons()
    if self.exitButton then return end

    local exit = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    exit:SetSize(100, 28)
    exit:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 6)
    exit:SetText(GamingHub.GetLocaleTable("CHESS")["btn_exit"])
    exit:SetScript("OnClick", function()
        GamingHub.Chess_Engine:StopGame()
    end)
    exit:Hide()
    self.exitButton = exit

    local resign = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    resign:SetSize(120, 28)
    resign:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 6)
    resign:SetText(GamingHub.GetLocaleTable("CHESS")["btn_resign"])
    resign:SetScript("OnClick", function()
        GamingHub.Chess_Engine:HandleResign()
    end)
    resign:Hide()
    self.resignButton = resign
end

-- ============================================================
-- Status-Text
-- ============================================================

function R:CreateStatusText()
    if self.statusFS then return end
    self.statusFS = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.statusFS:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -8, -8)
    self.statusFS:SetJustifyH("RIGHT")
    self.statusFS:Hide()
end

function R:UpdateStatus(state, extra)
    if not self.statusFS then return end
    local txt
    local _LS = GamingHub.GetLocaleTable("CHESS")
    if extra == "checkmate" then
        txt = _LS["status_checkmate"]
    elseif extra == "stalemate" then
        txt = _LS["status_stalemate"]
    elseif extra == "check" then
        txt = _LS["status_check"]
    elseif state.turn == "black" then
        txt = _LS["status_ai_turn"]
    else
        local move = state.moveCount or 0
        txt = string.format(_LS["status_move"], move + 1)
    end
    self.statusFS:SetText(txt)
    self.statusFS:Show()
end

-- ============================================================
-- Capture Bars (geschlagene Figuren)
-- ============================================================

function R:CreateCaptureBars()
    if self.captureBarTop then return end
    -- Oben: geschlagene Horde-Figuren (Spieler hat geschlagen)
    local top = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    top:SetPoint("TOPLEFT", self.boardHolder, "TOPRIGHT", 10, 0)
    top:SetWidth(80)
    top:SetJustifyH("LEFT")
    top:SetJustifyV("TOP")
    top:SetText("")
    self.captureBarTop = top

    -- Unten: geschlagene Allianz-Figuren (KI hat geschlagen)
    local bot = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bot:SetPoint("BOTTOMLEFT", self.boardHolder, "BOTTOMRIGHT", 10, 0)
    bot:SetWidth(80)
    bot:SetJustifyH("LEFT")
    bot:SetJustifyV("BOTTOM")
    bot:SetText("")
    self.captureBarBot = bot
end

function R:UpdateCaptureBars(state)
    if not self.captureBarTop then return end

    local function listToStr(pieces, color)
        if #pieces == 0 then return "" end
        local tint = color == "black" and "|cffff8888" or "|cff8888ff"
        local names = {}
        for _, p in ipairs(pieces) do
            names[#names+1] = tint .. (GetPieceNames()[p.type] or p.type) .. "|r"
        end
        return table.concat(names, "\n")
    end

    local _LC = GamingHub.GetLocaleTable("CHESS")
    self.captureBarTop:SetText(_LC["capture_taken"] .. "\n" .. listToStr(state.capturedByWhite or {}, "black"))
    self.captureBarBot:SetText(_LC["capture_lost"] .. "\n" .. listToStr(state.capturedByBlack or {}, "white"))
end

-- ============================================================
-- Overlay (Spielende)
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
    restartBtn:SetText(GamingHub.GetLocaleTable("CHESS")["btn_new_game"])
    restartBtn:SetScript("OnClick", function()
        ov:Hide()
        if R.selectedDiff then
            GamingHub.Chess_Engine:StartGame({ difficulty = R.selectedDiff })
        end
    end)
    self.overlay = ov
end

-- ============================================================
-- Idle State
-- ============================================================

function R:EnterIdleState()
    self.state = "IDLE"
    if self.overlay     then self.overlay:Hide()      end
    if self.exitButton  then self.exitButton:Hide()   end
    if self.resignButton then self.resignButton:Hide() end
    if self.statusFS    then self.statusFS:Hide()     end

    -- Board leeren
    for r = 1, 6 do
        for c = 1, 6 do
            local cd = self.cells[r] and self.cells[r][c]
            if cd then
                cd.iconTex:Hide()
                cd.hlFrame:Hide()
                local fc = cd.isLight and LIGHT_FIELD or DARK_FIELD
                cd.bg:SetVertexColor(fc[1], fc[2], fc[3], 1)
            end
        end
    end

    -- Diff-Buttons
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
        self.hintFS:SetText(GamingHub.GetLocaleTable("CHESS")["hint_start"])
        self.hintFS:SetJustifyH("CENTER")
    end
    self.hintFS:Show()
end

-- ============================================================
-- RenderBoard – vollständiger Board-Render
-- ============================================================

function R:RenderBoard(state)
    local board      = state.board
    local selected   = state.selected
    local legalMoves = state.legalMoves or {}
    local lastMove   = state.lastMove
    local inCheck    = state.inCheck

    -- Legale Ziel-Felder als Set
    local legalSet = {}
    for _, m in ipairs(legalMoves) do
        legalSet[m.toR .. "_" .. m.toC] = true
    end

    -- König im Schach?
    local checkKingR, checkKingC
    if inCheck then
        for r = 1, 6 do
            for c = 1, 6 do
                local p = board[r][c]
                if p and p.type == "KING" and p.color == "white" then
                    checkKingR, checkKingC = r, c
                end
            end
        end
    end

    for r = 1, 6 do
        for c = 1, 6 do
            local cd    = self.cells[r][c]
            local piece = board[r][c]
            local key   = r .. "_" .. c

            -- ── Hintergrundfarbe ────────────────────────────
            local bgCol
            if selected and r == selected.r and c == selected.c then
                bgCol = CLR_SELECTED
            elseif legalSet[key] then
                bgCol = CLR_LEGAL
            elseif lastMove and
               ((r == lastMove.fromR and c == lastMove.fromC) or
                (r == lastMove.toR   and c == lastMove.toC)) then
                bgCol = CLR_LASTMOVE
            elseif checkKingR and r == checkKingR and c == checkKingC then
                bgCol = CLR_CHECK
            else
                bgCol = cd.isLight and LIGHT_FIELD or DARK_FIELD
            end
            cd.bg:SetVertexColor(bgCol[1], bgCol[2], bgCol[3], 1)

            -- ── Highlight-Overlay für legale Züge ───────────
            if legalSet[key] then
                -- Zeige Punkt in der Mitte wenn leer, Ring wenn Figur drauf
                cd.hlFrame:Show()
                if piece then
                    -- Gegnerische Figur: roter Rahmen-Tint
                    cd.hlTex:SetVertexColor(0.8, 0.2, 0.2, 0.5)
                else
                    -- Leer: grüner Punkt
                    cd.hlTex:SetVertexColor(0.1, 0.8, 0.2, 0.6)
                end
            else
                cd.hlFrame:Hide()
                cd.hlTex:SetVertexColor(0, 0, 0, 0)
            end

            -- ── Figur-Icon ──────────────────────────────────
            if piece then
                local iconPath = ICONS[piece.color] and ICONS[piece.color][piece.type]
                if iconPath then
                    cd.iconTex:SetTexture(iconPath)
                    local tint = piece.color == "white" and TINT_WHITE or TINT_BLACK
                    cd.iconTex:SetVertexColor(tint[1], tint[2], tint[3], 1)
                    cd.iconTex:Show()
                else
                    cd.iconTex:Hide()
                end
            else
                cd.iconTex:Hide()
            end
        end
    end
end

-- ============================================================
-- Event-Handler
-- ============================================================

function R:OnGameStarted(state)
    self.state = "PLAYING"
    if self.overlay    then self.overlay:Hide()     end
    if self.hintFS     then self.hintFS:Hide()      end
    if self.exitButton then self.exitButton:Show()  end
    if self.resignButton then self.resignButton:Show() end

    self:RenderBoard(state)
    self:UpdateStatus(state)
    self:UpdateCaptureBars(state)
end

function R:OnPieceSelected(state)
    self:RenderBoard(state)
    -- Pulsiere ausgewähltes Feld kurz
    local sel = state.selected
    if sel then
        local cd = self.cells[sel.r] and self.cells[sel.r][sel.c]
        if cd then
            cd.frame:SetAlpha(0.7)
            UIFrameFadeIn(cd.frame, 0.15, 0.7, 1)
        end
    end
end

function R:OnBoardUpdated(state)
    self:RenderBoard(state)
    self:UpdateStatus(state)
end

function R:OnMoveMade(state, result)
    self:RenderBoard(state)
    self:UpdateStatus(state, result)
    self:UpdateCaptureBars(state)
end

function R:OnAIMove(state, result)
    self:RenderBoard(state)
    self:UpdateStatus(state, result)
    self:UpdateCaptureBars(state)

    -- Flash auf KI-Zug
    if state.lastMove then
        local m  = state.lastMove
        local cd = self.cells[m.toR] and self.cells[m.toR][m.toC]
        if cd then
            cd.frame:SetAlpha(0.4)
            UIFrameFadeIn(cd.frame, 0.3, 0.4, 1)
        end
    end
end

function R:OnGameOver(state)
    self.state = "GAMEOVER"
    self:RenderBoard(state)
    self:UpdateCaptureBars(state)
    if self.resignButton then self.resignButton:Hide() end

    local ov = self.overlay
    if not ov then return end

    local _LO = GamingHub.GetLocaleTable("CHESS")
    if state.result == "white_wins" then
        ov.title:SetText(_LO["result_win"])
        ov.title:SetTextColor(1, 0.84, 0)
        ov.sub:SetText(_LO["result_win_sub"] .. (state.moveCount or 0))
    elseif state.result == "black_wins" then
        ov.title:SetText(_LO["result_loss"])
        ov.title:SetTextColor(1, 0.3, 0.3)
        ov.sub:SetText(_LO["result_loss_sub"] .. (state.moveCount or 0))
    else
        ov.title:SetText(_LO["result_draw"])
        ov.title:SetTextColor(0.8, 0.8, 0.8)
        ov.sub:SetText(_LO["result_draw_sub"])
    end

    ov:SetAlpha(0)
    ov:Show()
    UIFrameFadeIn(ov, 0.5, 0, 0.85)
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "CHESS",
    label     = "Mini-Schach",
    renderer  = "Chess_Renderer",
    engine    = "Chess_Engine",
    container = "_cheContainer",
})
