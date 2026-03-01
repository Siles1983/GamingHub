-- Whack-a-Mole – Games/WhackAMole/Renderer.lua

local GamingHub = _G.GamingHub
GamingHub.WAM_Renderer = {}
local R = GamingHub.WAM_Renderer

R.frame       = nil
R.state       = "IDLE"
R._gridFrame  = nil
R._holes      = {}   -- [r][c] = { frame, icon, border }
R._hud        = {}
R._diffContainer  = nil
R._diffBtns       = {}
R._hintFS         = nil
R._gameOverPanel  = nil
R._builtGrid      = nil

-- ============================================================
-- Init
-- ============================================================
function R:Init()
    self:_createMainFrame()
end

function R:_createMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end

    local f = CreateFrame("Frame", "GamingHub_WAM_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    self.frame = f
    if _G.GamingHub then _G.GamingHub._wamContainer = f end

    self:_createDiffButtons()
end

-- ============================================================
-- Diff-Buttons
-- ============================================================
local function GetDiffs()
    local L = GamingHub.GetLocaleTable("WHACKAMOLE")
    return {
        { label = L["diff_easy"],   value = "EASY"   },
        { label = L["diff_normal"], value = "NORMAL" },
        { label = L["diff_hard"],   value = "HARD"   },
    }
end

function R:_createDiffButtons()
    if self._diffContainer then return end
    local c = CreateFrame("Frame", nil, self.frame)
    c:SetPoint("BOTTOMLEFT",  self.frame, "BOTTOMLEFT",  8, 46)
    c:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 46)
    c:SetHeight(28)
    self._diffContainer = c

    local W=80; local SP=8
    local DIFFS = GetDiffs()
    local total = #DIFFS * W + (#DIFFS-1)*SP
    local startOff = -math.floor(total/2)

    for i, d in ipairs(DIFFS) do
        local btn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        btn:SetSize(W, 26)
        btn:SetPoint("CENTER", c, "CENTER", startOff + (i-1)*(W+SP) + math.floor(W/2), 0)
        btn:SetText(d.label)
        local val = d.value
        btn:SetScript("OnClick", function()
            R:_highlightDiff(i)
            local E = GamingHub.WAM_Engine
            if E then E:StartGame(val) end
        end)
        self._diffBtns[i] = btn
    end
end

function R:_highlightDiff(idx)
    for i, b in ipairs(self._diffBtns) do
        b:UnlockHighlight()
        if i == idx then b:LockHighlight() end
    end
end

-- ============================================================
-- EnterIdleState
-- ============================================================
function R:EnterIdleState()
    self.state = "IDLE"
    if self._gridFrame    then self._gridFrame:Hide()    end
    if self._gameOverPanel then self._gameOverPanel:Hide() end
    if self._diffContainer then self._diffContainer:Show() end
    if self._exitBtn      then self._exitBtn:Hide()      end
    -- HUD verstecken
    for _, fs in pairs(self._hud) do
        if fs and fs.Hide then fs:Hide() end
    end

    if not self._hintFS then
        self._hintFS = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self._hintFS:SetPoint("CENTER", self.frame, "CENTER", 0, 40)
        self._hintFS:SetText(GamingHub.GetLocaleTable("WHACKAMOLE")["hint_start"])
        self._hintFS:SetJustifyH("CENTER")
    end
    self._hintFS:Show()
end

-- ============================================================
-- EnterPlayState
-- ============================================================
function R:EnterPlayState(board)
    self.state = "PLAYING"
    if self._hintFS        then self._hintFS:Hide()        end
    if self._diffContainer then self._diffContainer:Hide() end
    if self._gameOverPanel then self._gameOverPanel:Hide() end

    self:_buildGrid(board)
    self:_buildHUD(board)

    if self._gridFrame then self._gridFrame:Show() end
    self:UpdateHUD(board)
end

-- ============================================================
-- _buildGrid
-- ============================================================
function R:_buildGrid(board)
    local g  = board.gridSize
    local cs = 100   -- Zellgroesse

    local panelW = self.frame:GetWidth()
    local panelH = self.frame:GetHeight()
    if not panelW or panelW < 10 then panelW = 700 end
    if not panelH or panelH < 10 then panelH = 580 end
    local gridW  = g * cs
    local gridH  = g * cs
    local gridX  = math.floor((panelW - gridW) / 2)
    local gridY  = -math.floor((panelH - gridH - 60) / 2) - 20

    if self._builtGrid ~= g then
        if self._gridFrame then
            self._gridFrame:Hide()
            for _, ch in pairs({self._gridFrame:GetChildren()}) do ch:Hide() end
        else
            -- BackdropTemplate fuer neutralen Hintergrund
            self._gridFrame = CreateFrame("Frame", "GamingHub_WAM_Grid", self.frame, "BackdropTemplate")
            self._gridFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                tile   = false,
            })
            self._gridFrame:SetBackdropColor(0.12, 0.09, 0.06, 1)
        end
        self._holes = {}
        self._builtGrid = g
    end

    self._gridFrame:SetSize(gridW + 8, gridH + 8)
    self._gridFrame:ClearAllPoints()
    self._gridFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", gridX - 4, gridY + 4)

    for r = 1, g do
        if not self._holes[r] then self._holes[r] = {} end
        for c = 1, g do
            if self._holes[r][c] then
                self._holes[r][c].frame:Show()
                self._holes[r][c].icon:Hide()
                -- Farbe zuruecksetzen via BackdropBorderColor
                self._holes[r][c].frame:SetBackdropBorderColor(0.35, 0.25, 0.10, 1)
            else
                local hole = CreateFrame("Button", nil, self._gridFrame, "BackdropTemplate")
                hole:SetSize(cs - 6, cs - 6)
                hole:SetPoint("TOPLEFT", self._gridFrame, "TOPLEFT",
                    (c-1)*cs + 7, -((r-1)*cs) - 7)
                -- Nur WHITE8X8 als edgeFile – kein Tooltip-Border-Atlas (erzeugt gruene Linien)
                hole:SetBackdrop({
                    bgFile   = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    tile=false, edgeSize=2,
                    insets={left=2,right=2,top=2,bottom=2},
                })
                hole:SetBackdropColor(0.20, 0.14, 0.08, 1)
                hole:SetBackdropBorderColor(0.35, 0.25, 0.10, 1)

                -- Dunkles Oval (Loch-Andeutung)
                local oval = hole:CreateTexture(nil, "BACKGROUND")
                oval:SetTexture("Interface\\Buttons\\WHITE8X8")
                oval:SetSize(cs - 24, math.floor((cs-24)*0.55))
                oval:SetPoint("BOTTOM", hole, "BOTTOM", 0, 8)
                oval:SetVertexColor(0.08, 0.05, 0.02, 1)

                -- Icon-Textur
                local icon = hole:CreateTexture(nil, "ARTWORK")
                icon:SetSize(cs - 22, cs - 22)
                icon:SetPoint("CENTER", hole, "CENTER", 0, 4)
                icon:Hide()

                -- Hover
                hole:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.28, 0.20, 0.10, 1)
                end)
                hole:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0.20, 0.14, 0.08, 1)
                end)

                local lr, lc = r, c
                hole:SetScript("OnClick", function()
                    local E = GamingHub.WAM_Engine
                    if E then E:OnMoleClick(lr, lc) end
                end)

                -- Kein separater border-Eintrag – BackdropBorderColor uebernimmt Farbmarkierung
                self._holes[r][c] = { frame=hole, icon=icon }
            end
        end
    end
end
function R:_buildHUD(board)
    local function mkLabel(txt, x, y)
        local fs = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, y)
        fs:SetText(txt)
        return fs
    end
    local function mkValue(x, y)
        local fs = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, y)
        fs:SetText("0")
        return fs
    end

    if not self._hud.scoreLabel then
        local _L = GamingHub.GetLocaleTable("WHACKAMOLE")
        self._hud.scoreLabel  = mkLabel(_L["hud_score"],    12, -8)
        self._hud.scoreFS     = mkValue(70, -8)
        self._hud.timerLabel  = mkLabel(_L["hud_time"],    140, -8)
        self._hud.timerFS     = mkValue(195, -8)
        self._hud.missedLabel = mkLabel(_L["hud_missed"], 270, -8)
        self._hud.missedFS    = mkValue(350, -8)
        -- Punkt 4: "Bestzeit" -> "Highscore"
        self._hud.bestLabel   = mkLabel(_L["hud_highscore"], 420, -8)
        self._hud.bestFS      = mkValue(510, -8)
    end

    -- Punkt 1: Beenden-Button (wie Memory: BOTTOMLEFT, 8px vom Rand)
    if not self._exitBtn then
        local btn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
        btn:SetSize(100, 28)
        btn:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 6)
        btn:SetText(GamingHub.GetLocaleTable("WHACKAMOLE")["btn_exit"])
        btn:SetScript("OnClick", function()
            local E = GamingHub.WAM_Engine
            if E then E:StopGame() end
            R:EnterIdleState()
        end)
        self._exitBtn = btn
    end
    self._exitBtn:Show()

    for _, v in pairs(self._hud) do if v and v.Show then v:Show() end end
end

-- ============================================================
-- UpdateHUD
-- ============================================================
function R:UpdateHUD(board)
    if not board then return end
    local S = GamingHub.WAM_Settings

    if self._hud.scoreFS  then self._hud.scoreFS:SetText(tostring(board.score or 0)) end
    if self._hud.missedFS then self._hud.missedFS:SetText(tostring(board.missed or 0)) end
    if self._hud.bestFS and S then
        self._hud.bestFS:SetText(tostring(S:GetTopScore(board.difficulty) or 0))
    end

    if self._hud.timerFS then
        local t = board.timeLeft or 0
        if t <= 5 then
            self._hud.timerFS:SetTextColor(1, 0.1, 0.1, 1)
        elseif t <= 10 then
            self._hud.timerFS:SetTextColor(1, 0.6, 0, 1)
        else
            self._hud.timerFS:SetTextColor(1, 1, 1, 1)
        end
        self._hud.timerFS:SetText(tostring(t))
    end
end

-- ============================================================
-- ShowMole / HideMole
-- ============================================================
function R:ShowMole(r, c, icon, isBomb)
    local h = self._holes[r] and self._holes[r][c]
    if not h then return end

    h.icon:SetTexture(icon)
    h.icon:Show()

    if isBomb then
        h.frame:SetBackdropBorderColor(1, 0.15, 0.15, 1)
    else
        h.frame:SetBackdropBorderColor(0.15, 0.85, 0.15, 1)
    end
end

function R:HideMole(r, c)
    local h = self._holes[r] and self._holes[r][c]
    if not h then return end
    h.icon:Hide()
    h.frame:SetBackdropBorderColor(0.35, 0.25, 0.10, 1)
end

-- ============================================================
-- Hit-Effekt
-- ============================================================
function R:ShowHitEffect(r, c, text)
    local h = self._holes[r] and self._holes[r][c]
    if not h then return end

    local fx = h.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fx:SetPoint("CENTER", h.frame, "CENTER", 0, 10)
    fx:SetText("|cff00ff00" .. (text or "+10") .. "|r")
    fx:Show()

    C_Timer.After(0.5, function()
        if fx then fx:Hide() end
    end)
end

-- ============================================================
-- Boom-Effekt
-- ============================================================
function R:ShowBoomEffect(r, c)
    local h = self._holes[r] and self._holes[r][c]
    if not h then return end

    h.frame:SetBackdropColor(0.60, 0.05, 0.05, 1)

    local fx = h.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fx:SetPoint("CENTER", h.frame, "CENTER", 0, 10)
    fx:SetText(GamingHub.GetLocaleTable("WHACKAMOLE")["boom_text"])
    fx:Show()

    C_Timer.After(0.7, function()
        if fx then fx:Hide() end
        if h and h.frame then h.frame:SetBackdropColor(0.20, 0.14, 0.08, 1) end
    end)
end

-- ============================================================
-- GameOver-Panel
-- ============================================================
function R:ShowGameOver(board, hitBomb)
    -- Beenden-Button waehrend GameOver verstecken
    if self._exitBtn then self._exitBtn:Hide() end

    if not self._gameOverPanel then
        local ov = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
        ov:SetSize(280, 200)
        ov:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
        ov:SetFrameStrata("HIGH")
        ov:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true, tileEdge=true, tileSize=16, edgeSize=16,
            insets={left=4,right=4,top=4,bottom=4},
        })
        ov:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
        ov:SetBackdropBorderColor(0.90, 0.75, 0.30, 1)

        local title = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", ov, "TOP", 0, -14)
        self._goTitle = title

        local reasonFS = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        reasonFS:SetPoint("TOP", title, "BOTTOM", 0, -6)
        self._goReason = reasonFS

        local scoreFS = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        scoreFS:SetPoint("TOP", reasonFS, "BOTTOM", 0, -6)
        self._goScore = scoreFS

        local missFS = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        missFS:SetPoint("TOP", scoreFS, "BOTTOM", 0, -4)
        self._goMiss = missFS

        -- Punkt 4: "Bestzeit" -> "Highscore"
        local bestFS = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bestFS:SetPoint("TOP", missFS, "BOTTOM", 0, -4)
        self._goBest = bestFS

        -- Punkt 5: Nochmal-Button speichert Difficulty nicht in Closure,
        -- sondern liest sie zur Klick-Zeit aus dem aktuellen Board-State
        local retry = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
        retry:SetSize(110, 26)
        retry:SetText(GamingHub.GetLocaleTable("WHACKAMOLE")["btn_retry"])
        retry:SetPoint("BOTTOMLEFT", ov, "BOTTOMLEFT", 14, 14)
        retry:SetScript("OnClick", function()
            ov:Hide()
            local E = GamingHub.WAM_Engine
            -- Difficulty aus dem zuletzt gespeicherten Board lesen
            local diff = R._lastDifficulty or "EASY"
            if E then E:StartGame(diff) end
        end)

        local menu = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
        menu:SetSize(110, 26)
        menu:SetText(GamingHub.GetLocaleTable("WHACKAMOLE")["btn_menu"])
        menu:SetPoint("BOTTOMRIGHT", ov, "BOTTOMRIGHT", -14, 14)
        menu:SetScript("OnClick", function()
            local E = GamingHub.WAM_Engine
            if E then E:StopGame() end
            R:EnterIdleState()
        end)

        self._gameOverPanel = ov
    end

    -- Difficulty fuer Nochmal-Button merken (immer aktuell)
    R._lastDifficulty = board.difficulty

    local S = GamingHub.WAM_Settings
    if self._goTitle then
        local _LGO = GamingHub.GetLocaleTable("WHACKAMOLE")
        self._goTitle:SetText(hitBomb and _LGO["go_title_bomb"] or _LGO["go_title_time"])
    end
    if self._goReason then
        self._goReason:SetText(hitBomb and _LGO["go_reason_bomb"] or "")
    end
    if self._goScore then
        self._goScore:SetText(_LGO["go_score"] .. (board.score or 0))
    end
    if self._goMiss then
        self._goMiss:SetText(_LGO["go_missed"] .. (board.missed or 0))
    end
    if self._goBest and S then
        -- Punkt 4: Label "Highscore" statt "Bestzeit"
        self._goBest:SetText(_LGO["go_highscore"] .. (S:GetTopScore(board.difficulty) or 0))
    end

    if self._gridFrame then self._gridFrame:Hide() end
    self._gameOverPanel:Show()
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "WHACKAMOLE",
    label     = "Whack-a-Mole",
    renderer  = "WAM_Renderer",
    engine    = "WAM_Engine",
    container = "_wamContainer",
})
