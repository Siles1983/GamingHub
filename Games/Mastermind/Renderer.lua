--[[
    Gaming Hub – Mastermind: Azeroth Edition
    Games/Mastermind/Renderer.lua  v2.0

    FIXES v2:
    - Adaptives Layout: alles wird aus verfügbarem Panel-Raum berechnet
    - Pegs: Anzahl = codeLength (nicht fix 4), Layout ceil(codeLen/2) × 2
    - Runde Icons: SetTexCoord(0.08,0.92,0.08,0.92) + Circular Mask via
      Interface\CHARACTERFRAME\TempPortraitAlphaMask
    - Palette passt sich Panelbreite an (Symbole nie > Panel)
    - Settings: Vorschau-Label über den Icons (kein Überlappen)
]]

local GamingHub = _G.GamingHub
GamingHub.MM_Renderer = {}
local R = GamingHub.MM_Renderer

-- Runde Maske – Standard WoW circular alpha mask
local MASK_TEX = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

-- State
R.frame           = nil
R.state           = "IDLE"
R.selectedDiff    = nil
R.selectedTheme   = nil
R.selectedSlot    = 1
R.attemptRows     = {}
R.inputSlots      = {}
R.paletteButtons  = {}
R.submitButton    = nil
R.boardHolder     = nil
R.diffContainer   = nil
R.diffBtns        = {}
R.dupCheckbox     = nil
R.codeLenDropdown = nil
R.exitButton      = nil
R.newGameButton   = nil
R.statusFS        = nil
R.themeFS         = nil
R.overlay         = nil
R.hintFS          = nil
R.divLine         = nil

-- ============================================================
-- Runde Textur-Hilfsfunktion
-- Erstellt eine Textur mit kreisförmigem Clip via Mask
-- ============================================================
local function MakeRoundIcon(parent, size, layer)
    layer = layer or "ARTWORK"

    -- Icon-Textur
    local tex = parent:CreateTexture(nil, layer)
    tex:SetSize(size, size)
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Runde Maske via CreateMaskTexture (Retail + Midnight)
    -- Fallback: falls API nicht verfügbar, kein Crash
    local maskTex = nil
    if parent.CreateMaskTexture then
        maskTex = parent:CreateMaskTexture()
        maskTex:SetTexture(MASK_TEX, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        maskTex:SetSize(size, size)
        tex:AddMaskTexture(maskTex)
    end

    return tex, maskTex
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

    local Engine = GamingHub.Engine
    Engine:On("MM_GAME_STARTED", function(s) R:OnGameStarted(s) end)
    Engine:On("MM_GAME_WON",     function(s) R:OnGameWon(s)     end)
    Engine:On("MM_GAME_LOST",    function(s) R:OnGameLost(s)    end)
    Engine:On("MM_GAME_STOPPED", function()  R:EnterIdleState() end)
end

-- ============================================================
-- Main Frame
-- ============================================================
function R:CreateMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end
    local f = CreateFrame("Frame", "GamingHub_MM_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    self.frame = f
    if _G.GamingHub then _G.GamingHub._mmContainer = f end
end

-- ============================================================
-- ComputeLayout – berechnet alle Größen aus Panelgröße
-- Gibt eine layout-Tabelle zurück
-- ============================================================
function R:ComputeLayout(codeLen, maxAttempts)
    local panelW = self.frame:GetWidth()  or 580
    local panelH = self.frame:GetHeight() or 700

    -- Reservierte Höhe: Statuszeile (28) + DiffButtons+Controls (62) + BottomButtons (36) + Padding (20)
    local reservedH = 28 + 62 + 36 + 20

    -- Palette-Zeile (46px) + Eingabezeile + Trennlinie (2px) + Padding
    local inputZoneH = 52 + 2 + 8   -- Eingabe + Prüfen-Button-Höhe
    local palZoneH   = 50

    local availH = panelH - reservedH - inputZoneH - palZoneH
    if availH < 100 then availH = 100 end

    -- Slot-Größe aus verfügbarer Höhe ableiten
    local slotSize = math.floor(availH / maxAttempts) - 4
    slotSize = math.max(22, math.min(slotSize, 44))  -- min 22, max 44

    local slotGap = math.max(2, math.floor(slotSize * 0.08))
    local rowH    = slotSize + slotGap

    -- Peg-Größe: abhängig von rowH
    local pegCols  = math.ceil(codeLen / 2)   -- Spalten im Peg-Grid
    local pegRows  = 2                          -- immer 2 Zeilen
    local pegSize  = math.max(8, math.floor((rowH - slotGap) / pegRows) - 2)
    local pegGap   = 2

    -- Maximal verfügbare Breite (Padding von 8px je Seite)
    local maxW = panelW - 16

    -- Pegs-Bereich: feste Breite basierend auf codeLen
    local pegsW = pegCols * pegSize + (pegCols - 1) * pegGap + 4

    -- Verfügbare Breite für Slots (nach Pegs + Abstand)
    local slotsMaxW = maxW - pegsW - 14
    -- SlotSize aus Breite begrenzen falls nötig
    local slotSizeByW = math.floor((slotsMaxW - (codeLen-1) * slotGap) / codeLen)
    if slotSizeByW < slotSize then
        slotSize = math.max(20, slotSizeByW)
        slotGap  = math.max(2, math.floor(slotSize * 0.08))
        rowH     = slotSize + slotGap
    end

    local slotsW = codeLen * slotSize + (codeLen - 1) * slotGap
    local rowW   = slotsW + 14 + pegsW

    -- Palette: 6 Symbole gleichmäßig auf Panel-Breite verteilen
    local palMax  = 6
    local palSize = math.max(24, math.floor((maxW - (palMax-1)*8) / palMax))
    palSize = math.min(palSize, 44)
    -- Gesamtbreite der Palette berechnen für Zentrierung
    local palTotalW = palMax * palSize + (palMax-1) * 8
    local palGap  = 8  -- fixer Gap zwischen Palette-Buttons

    -- Board horizontal zentriert
    local boardOffX = math.floor((panelW - rowW) / 2)
    if boardOffX < 8 then boardOffX = 8 end

    return {
        slotSize   = slotSize,
        slotGap    = slotGap,
        rowH       = rowH,
        pegSize    = pegSize,
        pegGap     = pegGap,
        pegCols    = pegCols,
        pegRows    = pegRows,
        slotsW     = slotsW,
        pegsW      = pegsW,
        rowW       = rowW,
        palSize    = palSize,
        palGap     = palGap,
        palTotalW  = palTotalW,
        boardOffX  = boardOffX,
        boardH     = maxAttempts * rowH,
        availH     = availH,
        panelW     = panelW,
    }
end

-- ============================================================
-- BuildBoard
-- ============================================================
function R:BuildBoard(state)
    self:ClearBoard()

    local codeLen    = state.codeLength
    local maxAttempts= state.maxAttempts
    local T          = GamingHub.MM_Themes
    local L          = self:ComputeLayout(codeLen, maxAttempts)

    -- Holder
    local holder = CreateFrame("Frame", nil, self.frame)
    holder:SetPoint("TOPLEFT", self.frame, "TOPLEFT", L.boardOffX, -28)
    holder:SetSize(L.rowW + 10, L.boardH + L.rowH + L.palSize + 20)
    self.boardHolder = holder
    self._layout     = L   -- für UpdateInputRow etc.

    -- Versuchszeilen
    self.attemptRows = {}
    for i = 1, maxAttempts do
        local rowY = (i - 1) * L.rowH
        local row  = self:CreateAttemptRow(holder, codeLen, L, rowY)
        self:RenderAttemptRowEmpty(row, codeLen)
        self.attemptRows[i] = row
    end

    -- Trennlinie
    local div = holder:CreateTexture(nil, "ARTWORK")
    div:SetTexture("Interface\\Buttons\\WHITE8X8")
    div:SetPoint("TOPLEFT",  holder, "TOPLEFT",  0,  -(L.boardH + 2))
    div:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0,  -(L.boardH + 2))
    div:SetHeight(1)
    div:SetVertexColor(0.7, 0.6, 0.25, 0.9)
    self.divLine = div

    -- Eingabezeile: temporäre Platzhalter – werden nach _inputFrame-Erstellung gesetzt
    -- (Slots werden in der Palette-Sektion ans _inputFrame gehängt, nach holder)
    self.inputSlots   = {}
    self.selectedSlot = 1
    -- Slots werden weiter unten im _inputFrame-Block erstellt
    if self.submitButton then self.submitButton:Hide(); self.submitButton = nil end

    -- Palette: direkt ans self.frame (nicht holder!), so passt sie immer
    self.paletteButtons = {}
    local symbols    = T:GetTheme(state.theme).symbols
    local palFrame   = CreateFrame("Frame", nil, self.frame)
    palFrame:SetPoint("BOTTOMLEFT",  self.frame, "BOTTOMLEFT",  8, 76)
    palFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 76)
    palFrame:SetHeight(L.palSize + 4)
    self._palFrame = palFrame

    -- Palette gleichmäßig zentriert auf Panel-Breite verteilen
    local nSym = #symbols
    local palStartX = math.floor((L.panelW - 16 - L.palTotalW) / 2)
    if palStartX < 0 then palStartX = 0 end
    for i, sym in ipairs(symbols) do
        local btn = CreateFrame("Button", nil, palFrame, "BackdropTemplate")
        btn:SetSize(L.palSize, L.palSize)
        local bx = palStartX + (i-1) * (L.palSize + L.palGap)
        btn:SetPoint("LEFT", palFrame, "LEFT", bx, 0)
        btn:SetBackdrop({
            bgFile   = "Interface\Buttons\WHITE8X8",
            edgeFile = "Interface\Tooltips\UI-Tooltip-Border",
            tile = false, edgeSize = 2,
            insets = { left=2, right=2, top=2, bottom=2 },
        })
        btn:SetBackdropColor(0.05, 0.05, 0.08, 1)
        btn:SetBackdropBorderColor(sym.color[1]*0.55, sym.color[2]*0.55, sym.color[3]*0.55, 1)

        local iconTex, maskTex = MakeRoundIcon(btn, L.palSize - 8, "ARTWORK")
        iconTex:SetPoint("CENTER")
        if maskTex then maskTex:SetPoint("CENTER") end
        iconTex:SetTexture(sym.icon)
        iconTex:SetVertexColor(sym.color[1], sym.color[2], sym.color[3])
        iconTex:Show()
        if maskTex then maskTex:Show() end

        local symLocal = sym
        local symIdxLocal = i
        btn:SetScript("OnEnter", function()
            btn:SetBackdropBorderColor(symLocal.color[1], symLocal.color[2], symLocal.color[3], 1)
            GameTooltip:SetOwner(btn, "ANCHOR_TOP")
            GameTooltip:SetText(symLocal.name, symLocal.color[1], symLocal.color[2], symLocal.color[3])
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropBorderColor(symLocal.color[1]*0.55, symLocal.color[2]*0.55, symLocal.color[3]*0.55, 1)
            GameTooltip:Hide()
        end)
        btn:SetScript("OnClick", function()
            local slot = R.selectedSlot or 1
            GamingHub.MM_Engine:HandleSetSlot(slot, symIdxLocal)
            R:AdvanceToNextEmptySlot()
        end)
        self.paletteButtons[i] = btn
    end

    -- Eingabe + Prüfen-Button Frame (über Palette)
    local inputBottomY = 76 + L.palSize + 8
    self._inputFrame = CreateFrame("Frame", nil, self.frame)
    self._inputFrame:SetPoint("BOTTOMLEFT",  self.frame, "BOTTOMLEFT",  8, inputBottomY)
    self._inputFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, inputBottomY)
    self._inputFrame:SetHeight(L.slotSize + 4)

    -- Trennlinie oben
    local div2 = self._inputFrame:CreateTexture(nil, "ARTWORK")
    div2:SetTexture("Interface\Buttons\WHITE8X8")
    div2:SetPoint("TOPLEFT",  self._inputFrame, "TOPLEFT",  0, 2)
    div2:SetPoint("TOPRIGHT", self._inputFrame, "TOPRIGHT", 0, 2)
    div2:SetHeight(1)
    div2:SetVertexColor(0.7, 0.6, 0.25, 0.9)

    -- Gesamtbreite der Eingabegruppe berechnen (Slots + Gap + Prüfen-Button)
    local submitW    = 70
    local submitGap  = 8
    local slotsRowW  = codeLen * L.slotSize + (codeLen - 1) * L.slotGap
    local totalInputW = slotsRowW + submitGap + submitW
    -- Startoffset so dass die gesamte Gruppe zentriert ist
    local inputGroupX = math.floor(((L.panelW - 16) - totalInputW) / 2)
    if inputGroupX < 0 then inputGroupX = 0 end

    -- Eingabe-Slots
    for i = 1, codeLen do
        local sx   = inputGroupX + (i-1) * (L.slotSize + L.slotGap)
        local slot = self:CreateInputSlot(self._inputFrame, i, L, sx, 2)
        self.inputSlots[i] = slot
    end

    -- Prüfen-Button rechts neben den Slots, zentriert mit der Gruppe
    local sub = CreateFrame("Button", nil, self._inputFrame, "UIPanelButtonTemplate")
    sub:SetSize(submitW, 28)
    sub:SetPoint("LEFT", self._inputFrame, "LEFT", inputGroupX + slotsRowW + submitGap, 0)
    sub:SetText(GamingHub.GetLocaleTable("MASTERMIND")["btn_submit"])
    sub:SetScript("OnClick", function() GamingHub.MM_Engine:HandleSubmit() end)
    self.submitButton = sub

    self:HighlightInputSlot(1)
end

-- ============================================================
-- CreateAttemptRow
-- Pegs: codeLen Pegs in 2 Reihen à ceil(codeLen/2) Spalten
-- ============================================================
function R:CreateAttemptRow(parent, codeLen, L, offsetY)
    local slots = {}
    local pegs  = {}

    -- Slots (rund)
    for i = 1, codeLen do
        local sx = (i-1) * (L.slotSize + L.slotGap)

        local slotFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        slotFrame:SetSize(L.slotSize, L.slotSize)
        slotFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", sx, -(offsetY + 1))
        slotFrame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 1,
            insets = { left=1, right=1, top=1, bottom=1 },
        })
        slotFrame:SetBackdropColor(0.10, 0.10, 0.13, 1)
        slotFrame:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)

        local iconTex, maskTex = MakeRoundIcon(slotFrame, L.slotSize - 6, "ARTWORK")
        iconTex:SetPoint("CENTER")
        if maskTex then maskTex:SetPoint("CENTER") end
        iconTex:Hide()
        if maskTex then maskTex:Hide() end
        slotFrame.icon     = iconTex
        slotFrame.maskTex  = maskTex
        slots[i] = slotFrame
    end

    -- Pegs: codeLen Stück in 2 Reihen
    local pegBaseX = codeLen * (L.slotSize + L.slotGap) + 8
    local pegIdx   = 0
    for pr = 1, L.pegRows do
        for pc = 1, L.pegCols do
            pegIdx = pegIdx + 1
            if pegIdx <= codeLen then
                local px = pegBaseX + (pc-1) * (L.pegSize + L.pegGap)
                local py = offsetY + 2 + (pr-1) * (L.pegSize + L.pegGap)

                local peg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
                peg:SetSize(L.pegSize, L.pegSize)
                peg:SetPoint("TOPLEFT", parent, "TOPLEFT", px, -py)
                peg:SetBackdrop({
                    bgFile   = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = false, edgeSize = 1,
                    insets = { left=1, right=1, top=1, bottom=1 },
                })
                peg:SetBackdropColor(0.13, 0.13, 0.16, 1)
                peg:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)

                local pegTex, pegMaskTex = MakeRoundIcon(peg, L.pegSize - 3, "ARTWORK")
                pegTex:SetPoint("CENTER")
                if pegMaskTex then pegMaskTex:SetPoint("CENTER") end
                pegTex:Hide()
                if pegMaskTex then pegMaskTex:Hide() end
                peg.icon    = pegTex
                peg.maskTex = pegMaskTex
                pegs[pegIdx] = peg
            end
        end
    end

    return { slots = slots, pegs = pegs, pegCount = codeLen }
end

-- ============================================================
-- CreateInputSlot (rund, Button)
-- ============================================================
function R:CreateInputSlot(parent, slotIdx, L, offsetX, offsetY)
    local slot = CreateFrame("Button", nil, parent, "BackdropTemplate")
    slot:SetSize(L.slotSize, L.slotSize)
    slot:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, -offsetY)
    slot:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 2,
        insets = { left=2, right=2, top=2, bottom=2 },
    })
    slot:SetBackdropColor(0.15, 0.18, 0.30, 1)
    slot:SetBackdropBorderColor(0.30, 0.35, 0.60, 1)
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local iconTex, maskTex = MakeRoundIcon(slot, L.slotSize - 8, "ARTWORK")
    iconTex:SetPoint("CENTER")
    if maskTex then maskTex:SetPoint("CENTER") end
    iconTex:Hide()
    if maskTex then maskTex:Hide() end
    slot.icon    = iconTex
    slot.maskTex = maskTex

    slot:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            GamingHub.MM_Engine:HandleClearSlot(slotIdx)
        end
        R:HighlightInputSlot(slotIdx)
    end)
    slot:SetScript("OnEnter", function()
        if slotIdx ~= R.selectedSlot then
            slot:SetBackdropBorderColor(0.60, 0.65, 0.90, 1)
        end
    end)
    slot:SetScript("OnLeave", function()
        if slotIdx ~= R.selectedSlot then
            local hasIcon = slot.icon and slot.icon:IsShown()
            slot:SetBackdropBorderColor(hasIcon and 0.45 or 0.30, hasIcon and 0.40 or 0.35, hasIcon and 0.20 or 0.60, 1)
        end
    end)
    return slot
end

-- ============================================================
-- CreatePaletteButton (rund)
-- ============================================================
function R:CreatePaletteButton(parent, symIdx, sym, L, offsetX, offsetY)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(L.palSize, L.palSize)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, -offsetY)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 2,
        insets = { left=2, right=2, top=2, bottom=2 },
    })
    btn:SetBackdropColor(0.05, 0.05, 0.08, 1)
    btn:SetBackdropBorderColor(sym.color[1]*0.55, sym.color[2]*0.55, sym.color[3]*0.55, 1)

    local iconTex, maskTex = MakeRoundIcon(btn, L.palSize - 8, "ARTWORK")
    iconTex:SetPoint("CENTER")
    if maskTex then maskTex:SetPoint("CENTER") end
    iconTex:SetTexture(sym.icon)
    iconTex:SetVertexColor(sym.color[1], sym.color[2], sym.color[3])
    iconTex:Show()
    if maskTex then maskTex:Show() end

    btn:SetScript("OnEnter", function()
        btn:SetBackdropBorderColor(sym.color[1], sym.color[2], sym.color[3], 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText(sym.name, sym.color[1], sym.color[2], sym.color[3])
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropBorderColor(sym.color[1]*0.55, sym.color[2]*0.55, sym.color[3]*0.55, 1)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function()
        local slot = R.selectedSlot or 1
        GamingHub.MM_Engine:HandleSetSlot(slot, symIdx)
        R:AdvanceToNextEmptySlot()
    end)
    return btn
end

-- ============================================================
-- HighlightInputSlot
-- ============================================================
function R:HighlightInputSlot(idx)
    self.selectedSlot = idx
    for i, slot in ipairs(self.inputSlots) do
        if i == idx then
            slot:SetBackdropBorderColor(1.0, 0.85, 0.0, 1)
            slot:SetBackdropColor(0.20, 0.22, 0.38, 1)
        else
            local hasIcon = slot.icon and slot.icon:IsShown()
            if hasIcon then
                slot:SetBackdropBorderColor(0.50, 0.45, 0.20, 1)
                slot:SetBackdropColor(0.12, 0.14, 0.22, 1)
            else
                slot:SetBackdropBorderColor(0.30, 0.35, 0.60, 1)
                slot:SetBackdropColor(0.15, 0.18, 0.30, 1)
            end
        end
    end
end

-- ============================================================
-- AdvanceToNextEmptySlot
-- ============================================================
function R:AdvanceToNextEmptySlot()
    local board = GamingHub.MM_Engine.activeGame and GamingHub.MM_Engine.activeGame.board
    if not board then return end
    for i = self.selectedSlot + 1, board.codeLength do
        if not board.currentGuess[i] or board.currentGuess[i] == 0 then
            self:HighlightInputSlot(i); return
        end
    end
    for i = 1, self.selectedSlot do
        if not board.currentGuess[i] or board.currentGuess[i] == 0 then
            self:HighlightInputSlot(i); return
        end
    end
end

-- ============================================================
-- UpdateInputRow
-- ============================================================
function R:UpdateInputRow()
    local board = GamingHub.MM_Engine.activeGame and GamingHub.MM_Engine.activeGame.board
    if not board then return end
    local T = GamingHub.MM_Themes
    for i = 1, board.codeLength do
        local slot   = self.inputSlots[i]
        local symIdx = board.currentGuess[i] or 0
        if slot then
            if symIdx > 0 then
                local sym = T:GetSymbol(board.theme, symIdx)
                if sym then
                    slot.icon:SetTexture(sym.icon)
                    slot.icon:SetVertexColor(sym.color[1], sym.color[2], sym.color[3])
                    slot.icon:Show()
                    if slot.maskTex then slot.maskTex:Show() end
                end
            else
                slot.icon:Hide()
                if slot.maskTex then slot.maskTex:Hide() end
            end
        end
    end
    self:HighlightInputSlot(self.selectedSlot)
end

-- ============================================================
-- UpdateBoard
-- ============================================================
function R:UpdateBoard()
    local board = GamingHub.MM_Engine.activeGame and GamingHub.MM_Engine.activeGame.board
    if not board then return end

    for i, attempt in ipairs(board.attempts) do
        local row = self.attemptRows[i]
        if row then self:RenderAttemptRow(row, attempt, board.theme, board.codeLength) end
    end
    for i = #board.attempts + 1, board.maxAttempts do
        local row = self.attemptRows[i]
        if row then self:RenderAttemptRowEmpty(row, board.codeLength) end
    end

    self.selectedSlot = 1
    self:UpdateInputRow()
    self:HighlightInputSlot(1)
    self:UpdateStatus(board)
end

-- ============================================================
-- RenderAttemptRow
-- ============================================================
function R:RenderAttemptRow(row, attempt, themeKey, codeLen)
    local T    = GamingHub.MM_Themes
    local PEGS = GamingHub.MM_Themes.PEGS

    for i = 1, codeLen do
        local slot   = row.slots[i]
        local symIdx = attempt.guess[i]
        if slot and symIdx then
            local sym = T:GetSymbol(themeKey, symIdx)
            if sym then
                slot.icon:SetTexture(sym.icon)
                slot.icon:SetVertexColor(sym.color[1], sym.color[2], sym.color[3])
                slot.icon:Show()
                if slot.maskTex then slot.maskTex:Show() end
                slot:SetBackdropColor(0.16, 0.14, 0.10, 1)
                slot:SetBackdropBorderColor(sym.color[1]*0.5, sym.color[2]*0.5, sym.color[3]*0.5, 1)
            end
        end
    end

    -- Pegs: exact (Diamant) zuerst, dann partial (Perle)
    local pegIdx = 0
    for _ = 1, attempt.exact do
        pegIdx = pegIdx + 1
        local peg = row.pegs[pegIdx]
        if peg then
            peg.icon:SetTexture(PEGS.exact.icon)
            peg.icon:SetVertexColor(1.0, 1.0, 1.0)
            peg.icon:Show()
            if peg.maskTex then peg.maskTex:Show() end
            peg:SetBackdropBorderColor(0.85, 0.85, 0.6, 1)
        end
    end
    for _ = 1, attempt.partial do
        pegIdx = pegIdx + 1
        local peg = row.pegs[pegIdx]
        if peg then
            peg.icon:SetTexture(PEGS.partial.icon)
            peg.icon:SetVertexColor(0.6, 0.6, 0.6)
            peg.icon:Show()
            if peg.maskTex then peg.maskTex:Show() end
            peg:SetBackdropBorderColor(0.4, 0.4, 0.42, 1)
        end
    end
    -- Leere Pegs ausblenden
    for j = pegIdx + 1, row.pegCount do
        local peg = row.pegs[j]
        if peg then
            peg.icon:Hide()
            peg:SetBackdropColor(0.10, 0.10, 0.13, 1)
            peg:SetBackdropBorderColor(0.22, 0.22, 0.25, 1)
        end
    end
end

-- ============================================================
-- RenderAttemptRowEmpty
-- ============================================================
function R:RenderAttemptRowEmpty(row, codeLen)
    for i = 1, codeLen do
        local slot = row.slots[i]
        if slot then
            slot.icon:Hide()
            slot:SetBackdropColor(0.10, 0.10, 0.13, 1)
            slot:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
        end
    end
    for j = 1, (row.pegCount or 4) do
        local peg = row.pegs[j]
        if peg then
            peg.icon:Hide()
            peg:SetBackdropColor(0.10, 0.10, 0.13, 1)
            peg:SetBackdropBorderColor(0.20, 0.20, 0.23, 1)
        end
    end
end

-- ============================================================
-- FlashIncomplete
-- ============================================================
function R:FlashIncomplete()
    local board = GamingHub.MM_Engine.activeGame and GamingHub.MM_Engine.activeGame.board
    if not board then return end
    for i = 1, board.codeLength do
        local slot   = self.inputSlots[i]
        local symIdx = board.currentGuess[i] or 0
        if slot and symIdx == 0 then
            slot:SetBackdropBorderColor(1, 0.1, 0.1, 1)
        end
    end
    C_Timer.After(0.4, function() R:HighlightInputSlot(R.selectedSlot) end)
end

-- ============================================================
-- ClearBoard
-- ============================================================
function R:ClearBoard()
    self.attemptRows    = {}
    self.inputSlots     = {}
    self.paletteButtons = {}
    self._layout        = nil
    if self.submitButton then self.submitButton:Hide(); self.submitButton = nil end
    if self.divLine      then self.divLine:Hide(); self.divLine = nil end
    if self._palFrame    then self._palFrame:Hide(); self._palFrame:SetParent(nil); self._palFrame = nil end
    if self._inputFrame  then self._inputFrame:Hide(); self._inputFrame:SetParent(nil); self._inputFrame = nil end
    if self.boardHolder  then
        self.boardHolder:Hide()
        self.boardHolder:SetParent(nil)
        self.boardHolder = nil
    end
end

-- ============================================================
-- Status Bar
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

function R:UpdateStatus(board)
    if self.themeFS then
        self.themeFS:SetText("|cffffd700" .. (board.themeName or "") .. "|r")
        self.themeFS:Show()
    end
    if self.statusFS then
        local n     = #board.attempts
        local color = (board.maxAttempts - n) <= 2 and "|cffff4444" or "|cffffff00"
        self.statusFS:SetText(string.format(GamingHub.GetLocaleTable("MASTERMIND")["status_attempts"], color, n, board.maxAttempts))
        self.statusFS:Show()
    end
end

-- ============================================================
-- Diff-Buttons + Code-Länge + Duplikate
-- ============================================================
local function GetDiffs()
    local L = GamingHub.GetLocaleTable("MASTERMIND")
    return {
        { label = L["diff_easy"],   value = "easy"   },
        { label = L["diff_normal"], value = "normal" },
        { label = L["diff_hard"],   value = "hard"   },
    }
end
local DIFFS = {}  -- wird bei Bedarf via GetDiffs() befüllt
local CODE_LENGTHS= { 3, 4, 5, 6 }

function R:CreateDiffButtons()
    if self.diffContainer then return end

    -- Container am unteren Rand
    local c = CreateFrame("Frame", nil, self.frame)
    c:SetPoint("BOTTOMLEFT",  self.frame, "BOTTOMLEFT",  8,  40)
    c:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 40)
    c:SetHeight(28)
    self.diffContainer = c

    local W = 76; local SP = 6
    -- Buttons zentriert im Container via relativer Positionierung zum CENTER
    DIFFS = GetDiffs()
    local totalBtnW = #DIFFS * W + (#DIFFS - 1) * SP
    local startOff  = -math.floor(totalBtnW / 2)  -- Offset des ersten Button-Zentrums
    for i, d in ipairs(DIFFS) do
        local btn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        btn:SetSize(W, 26)
        local cx = startOff + (i-1)*(W+SP)
        btn:SetPoint("CENTER", c, "CENTER", cx + math.floor(W/2), 0)
        btn:SetText(d.label)
        btn:SetScript("OnClick", function() R:SelectDiff(d.value, btn) end)
        self.diffBtns[i] = btn
    end

    -- Duplikate Checkbox
    local S  = GamingHub.MM_Settings
    local cb = CreateFrame("CheckButton", nil, c, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb:SetPoint("RIGHT", c, "RIGHT", -90, 0)
    cb:SetChecked(S:Get("duplicates"))
    local cbLbl = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cbLbl:SetPoint("RIGHT", cb, "LEFT", -2, 0)
    cbLbl:SetText(GamingHub.GetLocaleTable("MASTERMIND")["dup_label"])
    cb:SetScript("OnClick", function(self) S:Set("duplicates", self:GetChecked()) end)
    self.dupCheckbox = cb

    -- Code-Länge Label + Dropdown
    local lenLbl = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lenLbl:SetPoint("RIGHT", c, "RIGHT", -16, 10)
    lenLbl:SetText(GamingHub.GetLocaleTable("MASTERMIND")["code_label"])

    local lenDD = CreateFrame("Frame", nil, self.frame, "UIDropDownMenuTemplate")
    lenDD:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 16, 34)
    UIDropDownMenu_SetWidth(lenDD, 40)

    local function initDD(self, level)
        for _, v in ipairs(CODE_LENGTHS) do
            local info   = UIDropDownMenu_CreateInfo()
            info.text    = tostring(v)
            info.value   = v
            info.checked = (v == S:Get("codeLength"))
            info.func    = function()
                UIDropDownMenu_SetSelectedValue(lenDD, v)
                UIDropDownMenu_SetText(lenDD, tostring(v))
                S:Set("codeLength", v)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(lenDD, initDD)
    local cur = S:Get("codeLength")
    UIDropDownMenu_SetSelectedValue(lenDD, cur)
    UIDropDownMenu_SetText(lenDD, tostring(cur))
    self.codeLenDropdown = lenDD
end

function R:SelectDiff(value, clicked)
    self.selectedDiff = value
    GamingHub.MM_Settings:Set("difficulty", value)
    for _, b in ipairs(self.diffBtns) do b:UnlockHighlight() end
    clicked:LockHighlight()
    self:StartNewGame()
end

function R:StartNewGame()
    local S = GamingHub.MM_Settings
    GamingHub.MM_Engine:StartGame({
        difficulty = self.selectedDiff or S:Get("difficulty"),
        theme      = self.selectedTheme or S:Get("theme"),
        codeLength = S:Get("codeLength"),
        duplicates = self.dupCheckbox and self.dupCheckbox:GetChecked() or S:Get("duplicates"),
    })
end

-- ============================================================
-- Bottom Buttons
-- ============================================================
function R:CreateBottomButtons()
    if self.exitButton then return end
    local exit = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    exit:SetSize(90, 26)
    exit:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 10)
    exit:SetText(GamingHub.GetLocaleTable("MASTERMIND")["btn_exit"])
    exit:SetScript("OnClick", function() GamingHub.MM_Engine:StopGame() end)
    exit:Hide()
    self.exitButton = exit

    local ng = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    ng:SetSize(110, 26)
    ng:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 10)
    ng:SetText(GamingHub.GetLocaleTable("MASTERMIND")["btn_new_game"])
    ng:SetScript("OnClick", function() R:StartNewGame() end)
    ng:Hide()
    self.newGameButton = ng
end

-- ============================================================
-- Overlay
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
    title:SetPoint("CENTER", ov, "CENTER", 0, 70)
    ov.title = title

    local sub = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -12)
    sub:SetJustifyH("CENTER")
    ov.sub = sub

    ov.codeHolder = CreateFrame("Frame", nil, ov)
    ov.codeHolder:SetSize(300, 54)
    ov.codeHolder:SetPoint("TOP", sub, "BOTTOM", 0, -10)

    local btn = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
    btn:SetSize(150, 28)
    btn:SetPoint("TOP", ov.codeHolder, "BOTTOM", 0, -14)
    btn:SetText(GamingHub.GetLocaleTable("MASTERMIND")["btn_new_game_ov"])
    btn:SetScript("OnClick", function() ov:Hide(); R:StartNewGame() end)
    self.overlay = ov
end

function R:ShowOverlay(won, state)
    local ov = self.overlay
    if not ov then return end
    if won then
        local _LW = GamingHub.GetLocaleTable("MASTERMIND")
        ov.title:SetText(_LW["result_win_title"])
        ov.sub:SetText(string.format(_LW["result_win_sub"], state.attemptCount, state.maxAttempts))
    else
        local _LL = GamingHub.GetLocaleTable("MASTERMIND")
        ov.title:SetText(_LL["result_loss_title"])
        ov.sub:SetText(_LL["result_loss_sub"])
        self:RenderSecretCode(ov.codeHolder, state)
    end
    ov:SetAlpha(0); ov:Show()
    UIFrameFadeIn(ov, 0.5, 0, 0.88)
end

function R:RenderSecretCode(holder, state)
    for _, child in ipairs({ holder:GetChildren() }) do child:Hide() end
    local T      = GamingHub.MM_Themes
    local sz     = 40
    local gap    = 4
    local len    = state.codeLength
    local totalW = len * sz + (len-1)*gap
    for i = 1, len do
        local symIdx = state.secretCode[i]
        local sym    = T:GetSymbol(state.theme, symIdx)
        if sym then
            local sf = CreateFrame("Frame", nil, holder, "BackdropTemplate")
            sf:SetSize(sz, sz)
            sf:SetPoint("LEFT", holder, "LEFT", (i-1)*(sz+gap) + (holder:GetWidth()-totalW)/2, 0)
            sf:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=false, edgeSize=2, insets={left=2,right=2,top=2,bottom=2} })
            sf:SetBackdropColor(0.08, 0.08, 0.10, 1)
            sf:SetBackdropBorderColor(sym.color[1]*0.7, sym.color[2]*0.7, sym.color[3]*0.7, 1)
            local tex, maskTex = MakeRoundIcon(sf, sz - 8, "ARTWORK")
            if maskTex then tex:SetPoint("CENTER"); maskTex:SetPoint("CENTER") end
            tex:SetTexture(sym.icon)
            tex:SetVertexColor(sym.color[1], sym.color[2], sym.color[3])
            if maskTex then maskTex:Show() end
        end
    end
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
    if self.statusFS      then self.statusFS:Hide()      end
    if self.themeFS       then self.themeFS:Hide()       end
    for i, b in ipairs(self.diffBtns) do
        b:UnlockHighlight()
        local DIFFS_REF = GetDiffs()
        if DIFFS_REF[i] and DIFFS_REF[i].value == self.selectedDiff then b:LockHighlight() end
    end
    if not self.hintFS then
        self.hintFS = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.hintFS:SetPoint("CENTER", self.frame, "CENTER", 0, 40)
        self.hintFS:SetText(GamingHub.GetLocaleTable("MASTERMIND")["hint_start"])
        self.hintFS:SetJustifyH("CENTER")
    end
    self.hintFS:Show()
end

-- ============================================================
-- Event Handler
-- ============================================================
function R:OnGameStarted(state)
    self.state         = "PLAYING"
    self.selectedDiff  = state.difficulty
    self.selectedTheme = state.theme
    if self.overlay       then self.overlay:Hide()       end
    if self.hintFS        then self.hintFS:Hide()        end
    if self.exitButton    then self.exitButton:Show()    end
    if self.newGameButton then self.newGameButton:Show() end
    self:BuildBoard(state)
    self:UpdateStatus(GamingHub.MM_Engine.activeGame.board)
end

function R:OnGameWon(state)
    self.state = "WON"
    self:ShowOverlay(true, state)
end

function R:OnGameLost(state)
    self.state = "LOST"
    self:UpdateBoard()
    self:ShowOverlay(false, state)
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "MASTERMIND",
    label     = "Mastermind",
    renderer  = "MM_Renderer",
    engine    = "MM_Engine",
    container = "_mmContainer",
})
