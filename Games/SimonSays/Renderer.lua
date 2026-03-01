--[[
    Gaming Hub – Simon Says: Oger-Runen Edition
    Games/SimonSays/Renderer.lua

    Layout:
    ┌──────────────────────────────┐
    │ Thema (links)  Runde (rechts)│  ← StatusBar
    │                              │
    │    ┌───┬───┐                 │
    │    │ 1 │ 2 │   (2x2 Easy)   │  ← Grid (zentriert)
    │    ├───┼───┤                 │
    │    │ 3 │ 4 │                 │
    │    └───┴───┘                 │
    │                              │
    │  [Easy] [Normal] [Hard]      │  ← DiffButtons (zentriert)
    │  [Beenden]        [Neu]      │  ← BottomButtons
    └──────────────────────────────┘

    Architektur: Engine ruft Renderer direkt, Events nur für Zustandsübergänge.
]]

local GamingHub = _G.GamingHub
GamingHub.SS_Renderer = {}
local R = GamingHub.SS_Renderer

R.frame        = nil
R.state        = "IDLE"
R.boardHolder  = nil
R.symbolBtns   = {}      -- [symIdx] = Frame (Button mit Icon)
R.diffBtns     = {}
R.diffContainer= nil
R.exitButton   = nil
R.newGameButton= nil
R.statusFS     = nil
R.themeFS      = nil
R.hintFS       = nil
R.overlay      = nil
R._layout      = nil
R._currentDiff = nil
R._currentTheme= nil

-- ============================================================
-- HILFSFUNKTION: Textur setzen – unterstützt Interface\Icons\ und Atlas
-- ============================================================
local MASK_TEX = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

-- Setzt eine Textur auf einem Frame-Kind.
-- sym.isAtlas=true  → C_Texture.GetAtlasInfo + SetTexture + SetTexCoord
-- sym.isAtlas=false → SetTexture(sym.icon) direkt
local function ApplySymbolTexture(tex, sym)
    if sym.isAtlas then
        local info = C_Texture.GetAtlasInfo(sym.atlas)
        if info and info.file then
            tex:SetTexture(info.file)
            tex:SetTexCoord(info.leftTexCoord, info.rightTexCoord,
                            info.topTexCoord,  info.bottomTexCoord)
        else
            -- Fallback: Symbol-Farbe als einfarbige Fläche
            tex:SetTexture("Interface\\Buttons\\WHITE8X8")
            tex:SetVertexColor(sym.color[1], sym.color[2], sym.color[3])
        end
    else
        tex:SetTexture(sym.icon)
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        tex:SetVertexColor(sym.color[1], sym.color[2], sym.color[3])
    end
end

local function MakeRoundIcon(parent, size, layer)
    layer = layer or "ARTWORK"
    local tex = parent:CreateTexture(nil, layer)
    tex:SetSize(size, size)
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if parent.CreateMaskTexture then
        local mask = parent:CreateMaskTexture()
        mask:SetTexture(MASK_TEX, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetSize(size, size)
        tex:AddMaskTexture(mask)
        return tex, mask
    end
    return tex, nil
end

-- ============================================================
-- Init
-- ============================================================
function R:Init()
    self:CreateMainFrame()
    self:CreateStatusBar()
    self:CreateDiffButtons()
    self:CreateBottomButtons()
    self:CreateOverlay()
    self:EnterIdleState()

    local Eng = GamingHub.Engine
    Eng:On("SS_GAME_STARTED",   function(b)    R:OnGameStarted(b)  end)
    Eng:On("SS_GAME_STOPPED",   function()     R:EnterIdleState()  end)
end

-- ============================================================
-- CreateMainFrame
-- ============================================================
function R:CreateMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end
    local f = CreateFrame("Frame", "GamingHub_SS_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    self.frame = f
    if _G.GamingHub then _G.GamingHub._ssContainer = f end
end

-- ============================================================
-- ComputeLayout – Grid-Größen aus Panelgröße
-- ============================================================
function R:ComputeLayout(gridSize)
    local panelW = self.frame:GetWidth()  or 580
    local panelH = self.frame:GetHeight() or 700

    -- Reservierte Höhe: Status(28) + DiffButtons(40) + BottomButtons(46) + Padding(20)
    local reservedH = 28 + 40 + 46 + 20
    local availH    = panelH - reservedH
    local availW    = panelW - 32   -- 16px Padding je Seite

    -- Zellgröße: minimum von verfügbarer Höhe und Breite
    local gap      = 8
    local cellByH  = math.floor((availH - (gridSize-1)*gap) / gridSize)
    local cellByW  = math.floor((availW - (gridSize-1)*gap) / gridSize)
    local cellSize = math.min(cellByH, cellByW)
    cellSize = math.max(60, math.min(cellSize, 140))

    local totalW = gridSize * cellSize + (gridSize-1) * gap
    local totalH = gridSize * cellSize + (gridSize-1) * gap

    local offX = math.floor((panelW - totalW) / 2)
    local offY = math.floor((availH - totalH) / 2) + 28  -- unterhalb StatusBar

    return {
        cellSize = cellSize,
        gap      = gap,
        totalW   = totalW,
        totalH   = totalH,
        offX     = offX,
        offY     = offY,
        gridSize = gridSize,
        panelW   = panelW,
    }
end

-- ============================================================
-- BuildGrid – erstellt das Symbolfeld
-- ============================================================
function R:BuildGrid(board)
    self:ClearGrid()

    local T       = GamingHub.SS_Themes
    local symbols = T:GetSymbolsForDiff(board.theme, board.difficulty)
    local L       = self:ComputeLayout(board.grid)
    self._layout  = L

    local holder = CreateFrame("Frame", nil, self.frame)
    holder:SetPoint("TOPLEFT", self.frame, "TOPLEFT", L.offX, -L.offY)
    holder:SetSize(L.totalW, L.totalH)
    self.boardHolder = holder

    self.symbolBtns = {}

    for idx, sym in ipairs(symbols) do
        local row = math.floor((idx-1) / L.gridSize)
        local col = (idx-1) % L.gridSize

        local bx = col * (L.cellSize + L.gap)
        local by = row * (L.cellSize + L.gap)

        local btn = CreateFrame("Button", nil, holder, "BackdropTemplate")
        btn:SetSize(L.cellSize, L.cellSize)
        btn:SetPoint("TOPLEFT", holder, "TOPLEFT", bx, -by)
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 3,
            insets = { left=3, right=3, top=3, bottom=3 },
        })
        btn:SetBackdropColor(
            sym.color[1]*0.12,
            sym.color[2]*0.12,
            sym.color[3]*0.12, 1)
        btn:SetBackdropBorderColor(
            sym.color[1]*0.40,
            sym.color[2]*0.40,
            sym.color[3]*0.40, 1)

        -- Icon (rund)
        local iconSize = L.cellSize - 16
        local iconTex, maskTex = MakeRoundIcon(btn, iconSize, "ARTWORK")
        iconTex:SetPoint("CENTER")
        if maskTex then maskTex:SetPoint("CENTER") end
        ApplySymbolTexture(iconTex, sym)
        -- Gedimmter Start-Zustand
        if sym.isAtlas then
            iconTex:SetAlpha(0.55)
        else
            iconTex:SetVertexColor(sym.color[1]*0.6, sym.color[2]*0.6, sym.color[3]*0.6)
        end
        iconTex:Show()
        if maskTex then maskTex:Show() end

        -- Tooltip
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(btn, "ANCHOR_TOP")
            GameTooltip:SetText(sym.name, sym.color[1], sym.color[2], sym.color[3])
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Klick-Handler
        local idxLocal = idx
        btn:SetScript("OnClick", function()
            GamingHub.SS_Engine:HandleInput(idxLocal)
        end)

        -- Referenzen für Flash
        btn.sym      = sym
        btn.iconTex  = iconTex
        btn.maskTex  = maskTex
        btn._glow    = false

        self.symbolBtns[idx] = btn
    end
end

-- ============================================================
-- FlashSymbol – leuchtet Symbol auf (an/aus)
-- Direktaufruf vom Engine (zeitkritisch, kein Event-Umweg)
-- ============================================================
function R:FlashSymbol(symIdx, on)
    local btn = self.symbolBtns[symIdx]
    if not btn then return end
    local sym = btn.sym

    if on then
        btn:SetBackdropColor(
            sym.color[1]*0.55,
            sym.color[2]*0.55,
            sym.color[3]*0.55, 1)
        btn:SetBackdropBorderColor(
            sym.color[1],
            sym.color[2],
            sym.color[3], 1)
        -- Atlas-Icons: kein VertexColor → Alpha-Kontrast nutzen
        if sym.isAtlas then
            btn.iconTex:SetAlpha(1.0)
        else
            btn.iconTex:SetVertexColor(sym.color[1], sym.color[2], sym.color[3])
        end
    else
        btn:SetBackdropColor(
            sym.color[1]*0.12,
            sym.color[2]*0.12,
            sym.color[3]*0.12, 1)
        btn:SetBackdropBorderColor(
            sym.color[1]*0.40,
            sym.color[2]*0.40,
            sym.color[3]*0.40, 1)
        if sym.isAtlas then
            btn.iconTex:SetAlpha(0.55)
        else
            btn.iconTex:SetVertexColor(sym.color[1]*0.6, sym.color[2]*0.6, sym.color[3]*0.6)
        end
    end
end

-- ============================================================
-- SetButtonsEnabled – Eingabe sperren/freigeben
-- ============================================================
function R:SetButtonsEnabled(enabled)
    for _, btn in ipairs(self.symbolBtns) do
        btn:SetEnabled(enabled)
        btn:SetAlpha(enabled and 1.0 or 0.75)
    end
end

-- ============================================================
-- Event-Handler (direkte Aufrufe vom Engine)
-- ============================================================
function R:OnGameStarted(board)
    self.state = "PLAYING"
    if self.overlay      then self.overlay:Hide()      end
    if self.hintFS       then self.hintFS:Hide()       end
    if self.exitButton   then self.exitButton:Show()   end
    if self.newGameButton then self.newGameButton:Show() end
    self:BuildGrid(board)
    self:SetButtonsEnabled(false)
    self:UpdateStatus(board)
end

function R:OnNewRound(board)
    self:SetButtonsEnabled(false)
    self:UpdateStatus(board)
    -- Kurzer visueller Hinweis: alle Buttons kurz aufhellen
    for _, btn in ipairs(self.symbolBtns) do
        local sym = btn.sym
        btn:SetBackdropBorderColor(
            sym.color[1]*0.65,
            sym.color[2]*0.65,
            sym.color[3]*0.65, 1)
    end
    C_Timer.After(0.3, function()
        for _, b in ipairs(self.symbolBtns) do
            local s = b.sym
            b:SetBackdropBorderColor(s.color[1]*0.40, s.color[2]*0.40, s.color[3]*0.40, 1)
        end
    end)
end

function R:OnSequenceDone(board)
    self:SetButtonsEnabled(true)
    if self.statusFS then
        self.statusFS:SetText(GamingHub.GetLocaleTable("SIMONSAYS")["status_your_turn"])
    end
end

function R:OnInputCorrect(board)
    -- kein extra visuelles Feedback nötig, FlashSymbol macht es schon
end

function R:OnRoundComplete(board)
    self:SetButtonsEnabled(false)
    if self.statusFS then
        self.statusFS:SetText(string.format(GamingHub.GetLocaleTable("SIMONSAYS")["status_round_ok"], board.round))
    end
end

function R:OnGameLost(board)
    self.state = "LOST"
    self:SetButtonsEnabled(false)
    -- Alle Symbole kurz rot aufleuchten
    for _, btn in ipairs(self.symbolBtns) do
        btn:SetBackdropBorderColor(1, 0.1, 0.1, 1)
        btn:SetBackdropColor(0.3, 0.02, 0.02, 1)
    end
    C_Timer.After(0.8, function()
        self:ShowOverlay(false, board)
    end)
end

-- ============================================================
-- UpdateStatus
-- ============================================================
function R:UpdateStatus(board)
    if self.themeFS then
        local T    = GamingHub.SS_Themes
        local tName = T:GetTheme(board.theme).name
        self.themeFS:SetText("|cffffd700" .. tName .. "|r")
        self.themeFS:Show()
    end
    if self.statusFS then
        if board.round == 0 then
            self.statusFS:SetText(GamingHub.GetLocaleTable("SIMONSAYS")["status_ready"])
        else
            self.statusFS:SetText(string.format(GamingHub.GetLocaleTable("SIMONSAYS")["status_round"], board.round))
        end
        self.statusFS:Show()
    end
end

-- ============================================================
-- ClearGrid
-- ============================================================
function R:ClearGrid()
    self.symbolBtns = {}
    self._layout    = nil
    if self.boardHolder then
        self.boardHolder:Hide()
        self.boardHolder:SetParent(nil)
        self.boardHolder = nil
    end
end

-- ============================================================
-- CreateStatusBar
-- ============================================================
function R:CreateStatusBar()
    if self.statusFS then return end
    local f = self.frame

    self.themeFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.themeFS:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
    self.themeFS:Hide()

    self.statusFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.statusFS:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    self.statusFS:SetJustifyH("RIGHT")
    self.statusFS:Hide()
end

-- ============================================================
-- CreateDiffButtons
-- ============================================================
local function GetDiffs()
    local L = GamingHub.GetLocaleTable("SIMONSAYS")
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
    local totalBtnW = #DIFFS * W + (#DIFFS - 1) * SP
    local startOff  = -math.floor(totalBtnW / 2)
    for i, d in ipairs(DIFFS) do
        local btn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        btn:SetSize(W, 26)
        local cx = startOff + (i-1)*(W+SP)
        btn:SetPoint("CENTER", c, "CENTER", cx + math.floor(W/2), 0)
        btn:SetText(d.label)
        btn:SetScript("OnClick", function()
            GamingHub.SS_Settings:Set("difficulty", d.value)
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
    exit:SetText(GamingHub.GetLocaleTable("SIMONSAYS")["btn_exit"])
    exit:SetScript("OnClick", function() GamingHub.SS_Engine:StopGame() end)
    exit:Hide()
    self.exitButton = exit

    local ng = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    ng:SetSize(110, 26)
    ng:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 10)
    ng:SetText(GamingHub.GetLocaleTable("SIMONSAYS")["btn_new_game"])
    ng:SetScript("OnClick", function() R:StartNewGame() end)
    ng:Hide()
    self.newGameButton = ng
end

-- ============================================================
-- StartNewGame
-- ============================================================
function R:StartNewGame()
    local S = GamingHub.SS_Settings
    GamingHub.SS_Engine:StartGame({
        difficulty = self._currentDiff or S:Get("difficulty"),
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
    ov:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
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
    btn:SetText(GamingHub.GetLocaleTable("SIMONSAYS")["btn_new_game_ov"])
    btn:SetScript("OnClick", function() ov:Hide(); R:StartNewGame() end)

    self.overlay = ov
end

function R:ShowOverlay(won, board)
    local ov = self.overlay
    if not ov then return end
    if won then
        local _LW = GamingHub.GetLocaleTable("SIMONSAYS")
        ov.title:SetText(_LW["result_win_title"])
        ov.sub:SetText(string.format(_LW["result_win_sub"], board.round))
    else
        local _LL = GamingHub.GetLocaleTable("SIMONSAYS")
        ov.title:SetText(_LL["result_loss_title"])
        ov.sub:SetText(string.format(_LL["result_loss_sub"], board.round))
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
    if self.statusFS      then self.statusFS:Hide()      end
    if self.themeFS       then self.themeFS:Hide()       end

    -- Diff-Buttons: aktuelle Schwierigkeit highlighten
    local S = GamingHub.SS_Settings
    local cur = S and S:Get("difficulty") or "easy"
    for i, b in ipairs(self.diffBtns) do
        b:UnlockHighlight()
        local DIFFS_REF = GetDiffs()
        if DIFFS_REF[i] and DIFFS_REF[i].value == cur then b:LockHighlight() end
    end

    if not self.hintFS then
        self.hintFS = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.hintFS:SetPoint("CENTER", self.frame, "CENTER", 0, 40)
        self.hintFS:SetText(GamingHub.GetLocaleTable("SIMONSAYS")["hint_start"])
        self.hintFS:SetJustifyH("CENTER")
    end
    self.hintFS:Show()
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "SIMONSAYS",
    label     = "Simon Says",
    renderer  = "SS_Renderer",
    engine    = "SS_Engine",
    container = "_ssContainer",
})
