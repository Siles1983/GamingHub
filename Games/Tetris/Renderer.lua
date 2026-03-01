-- BlockDrop – Games/Tetris/Renderer.lua

local GamingHub = _G.GamingHub
GamingHub.TET_Renderer = {}
local R = GamingHub.TET_Renderer

R.frame   = nil
R.state   = "IDLE"

R._gridFrame    = nil
R._cells        = {}   -- [row][col] = texture
R._sidePanel    = nil
R._nextFrame    = nil
R._nextCells    = {}
R._scoreFS      = nil
R._levelFS      = nil
R._linesFS      = nil
R._highFS       = nil
R._hintFS       = nil
R._diffContainer= nil
R._diffBtns     = {}
R._exitBtn      = nil
R._pauseBtn     = nil
R._pauseOverlay = nil
R._gameOverPanel= nil
R._cellSize     = 24
R._sidePanelBuilt = false
R._builtDiff    = nil

-- ============================================================
-- Init
-- ============================================================
function R:Init()
    self._E = GamingHub.TET_Engine
    self._S = GamingHub.TET_Settings
    self._L = GamingHub.TET_Logic
    self._T = GamingHub.TET_Themes
    if self._E and self._E.Init then self._E:Init() end
    self:_createMainFrame()
end

-- ============================================================
-- _createMainFrame
-- ============================================================
function R:_createMainFrame()
    if self.frame then return end
    local gamesPanel = _G.GamingHubUI and _G.GamingHubUI.GetGamesPanel
        and _G.GamingHubUI.GetGamesPanel()
    if not gamesPanel then return end

    local f = CreateFrame("Frame", "GamingHub_TET_Container", gamesPanel)
    f:SetAllPoints(gamesPanel)
    f:Hide()
    self.frame = f
    if _G.GamingHub then _G.GamingHub._tetContainer = f end

    self:_createDiffButtons()
    self:_createBottomButtons()
end

-- ============================================================
-- Diff-Buttons
-- ============================================================
local function GetDiffs()
    local L = GamingHub.GetLocaleTable("TETRIS")
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
            local S = GamingHub.TET_Settings
            local E = GamingHub.TET_Engine
            if S then S:Set("difficulty", val) end
            R:_refreshDiffHighlight(i)
            if E then E:StartGame() end
        end)
        self._diffBtns[i] = btn
    end
end

function R:_refreshDiffHighlight(activeIdx)
    for i, b in ipairs(self._diffBtns) do
        b:UnlockHighlight()
        if i == activeIdx then b:LockHighlight() end
    end
end

-- ============================================================
-- Bottom-Buttons (Beenden / Pause)
-- ============================================================
function R:_createBottomButtons()
    if self._exitBtn then return end

    local exit = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    exit:SetSize(90, 26)
    exit:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 10)
    exit:SetText(GamingHub.GetLocaleTable("TETRIS")["btn_exit"])
    exit:SetScript("OnClick", function()
        local E = GamingHub.TET_Engine
        if E then E:StopGame() end
        R:EnterIdleState()
    end)
    exit:Hide()
    self._exitBtn = exit

    local pause = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    pause:SetSize(90, 26)
    pause:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 10)
    pause:SetText(GamingHub.GetLocaleTable("TETRIS")["btn_pause"])
    pause:SetScript("OnClick", function()
        local E = GamingHub.TET_Engine
        if E then E:TogglePause() end
    end)
    pause:Hide()
    self._pauseBtn = pause
end

-- ============================================================
-- EnterIdleState
-- ============================================================
function R:EnterIdleState()
    self.state = "IDLE"
    if self._gridFrame   then self._gridFrame:Hide()   end
    if self._sidePanel   then self._sidePanel:Hide()   end
    if self._exitBtn     then self._exitBtn:Hide()     end
    if self._pauseBtn    then self._pauseBtn:Hide()    end
    if self._gameOverPanel then self._gameOverPanel:Hide() end
    if self._pauseOverlay  then self._pauseOverlay:Hide()  end
    if self._diffContainer then self._diffContainer:Show() end

    -- Aktuellen Difficulty-Button highlighten
    local S = GamingHub.TET_Settings
    local cur = S and S:Get("difficulty") or "NORMAL"
    for i, b in ipairs(self._diffBtns) do
        b:UnlockHighlight()
        local DIFFS_REF = GetDiffs()
        if DIFFS_REF[i] and DIFFS_REF[i].value == cur then b:LockHighlight() end
    end

    if not self._hintFS then
        self._hintFS = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self._hintFS:SetPoint("CENTER", self.frame, "CENTER", 0, 40)
        self._hintFS:SetText(GamingHub.GetLocaleTable("TETRIS")["hint_start"])
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
    if self._pauseOverlay  then self._pauseOverlay:Hide()  end

    self:_buildPlayLayout(board)
    if self._gridFrame  then self._gridFrame:Show()  end
    if self._sidePanel  then self._sidePanel:Show()  end
    if self._exitBtn    then self._exitBtn:Show()    end
    if self._pauseBtn   then self._pauseBtn:Show()   end
end

-- ============================================================
-- _buildPlayLayout
-- ============================================================
function R:_buildPlayLayout(board)
    local cols = board.cols
    local rows = board.rows

    local panelW = self.frame:GetWidth()
    local panelH = self.frame:GetHeight()
    if not panelW or panelW < 10 then panelW = 620 end
    if not panelH or panelH < 10 then panelH = 580 end

    local sidePanelW = 155
    local sidePad    = 14
    local topPad     = 42
    local botPad     = 44

    local availW = panelW - sidePanelW - sidePad - 16
    local availH = panelH - topPad - botPad
    local csW    = math.floor(availW / cols)
    local csH    = math.floor(availH / rows)
    local cs     = math.max(math.min(csW, csH, 28), 12)
    self._cellSize = cs

    local gridW  = cols * cs
    local gridH  = rows * cs

    -- Grid + SidePanel gemeinsam horizontal zentrieren
    local totalW   = gridW + 4 + sidePad + sidePanelW
    local gridOffX = math.floor((panelW - totalW) / 2)
    if gridOffX < 8 then gridOffX = 8 end

    -- Vertikal zentrieren zwischen topPad und botPad
    local gridOffY = -math.floor((panelH - topPad - botPad - gridH) / 2) - topPad
    if gridOffY > -topPad then gridOffY = -topPad end

    -- Grid-Frame
    if not self._gridFrame then
        self._gridFrame = CreateFrame("Frame", "GamingHub_TET_Grid", self.frame, "BackdropTemplate")
        self._gridFrame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile=false, edgeSize=2,
            insets={left=2,right=2,top=2,bottom=2},
        })
        self._gridFrame:SetBackdropColor(0.05, 0.05, 0.07, 0.97)
        self._gridFrame:SetBackdropBorderColor(0.50, 0.42, 0.18, 1)

        -- Rechtsklick auf Spielfeld = Rotieren (kein Sound = kein Loop-Bug)
        self._gridFrame:EnableMouse(true)
        self._gridFrame:SetScript("OnMouseDown", function(_, btn)
            if btn ~= "RightButton" then return end
            local E2 = GamingHub.TET_Engine
            if not E2 or E2.state ~= "PLAYING" then return end
            local L2 = GamingHub.TET_Logic
            if L2 then L2:Rotate(E2._board) end
            R:UpdatePiece(E2._board)
        end)
    end
    self._gridFrame:SetSize(gridW+4, gridH+4)
    self._gridFrame:ClearAllPoints()
    self._gridFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", gridOffX, gridOffY)

    -- Zellen neu bauen wenn Schwierigkeit oder Zellgroesse geaendert
    if self._builtDiff ~= board.difficulty or self._builtCS ~= cs then
        self._cells = {}
        for _, child in pairs({self._gridFrame:GetChildren()}) do child:Hide() end
        self._builtDiff = board.difficulty
        self._builtCS   = cs
    end

    for r = 1, rows do
        if not self._cells[r] then self._cells[r] = {} end
        for c = 1, cols do
            local px = (c-1)*cs + 2
            local py = -((r-1)*cs) - 2
            if not self._cells[r][c] then
                local cell = CreateFrame("Frame", nil, self._gridFrame, "BackdropTemplate")
                cell:SetSize(cs-1, cs-1)
                cell:SetPoint("TOPLEFT", self._gridFrame, "TOPLEFT", px, py)
                cell:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", tile=false })
                cell:SetBackdropColor(0.10, 0.10, 0.14, 1)

                -- Icon-Textur (fuer Reagents/Raidmarker-Theme)
                local icon = cell:CreateTexture(nil, "ARTWORK")
                icon:SetAllPoints(cell)
                icon:Hide()
                cell.icon = icon

                -- Ghost-Textur
                local ghost = cell:CreateTexture(nil, "OVERLAY")
                ghost:SetAllPoints(cell)
                ghost:SetTexture("Interface\\Buttons\\WHITE8X8")
                ghost:SetVertexColor(1, 1, 1, 0)
                ghost:Hide()
                cell.ghost = ghost

                self._cells[r][c] = cell
            else
                local cell = self._cells[r][c]
                cell:SetSize(cs-1, cs-1)
                cell:SetPoint("TOPLEFT", self._gridFrame, "TOPLEFT", px, py)
                cell:Show()
            end
        end
    end

    -- Side-Panel
    local sideX = gridOffX + gridW + 4 + sidePad
    if not self._sidePanel then
        self._sidePanel = CreateFrame("Frame", nil, self.frame)
    end
    self._sidePanel:ClearAllPoints()
    self._sidePanel:SetPoint("TOPLEFT",     self.frame, "TOPLEFT",     sideX, gridOffY)
    self._sidePanel:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8,    botPad)
    self:_buildSidePanel(board)
end

-- ============================================================
-- _buildSidePanel – Score/Level/Reihen/Bestzeit + Next-Preview
-- Guard: Labels nur einmal erstellen
-- ============================================================
function R:_buildSidePanel(board)
    local sp = self._sidePanel
    if not sp then return end

    -- Next-Vorschau-Label
    if not self._nextLabelFS then
        self._nextLabelFS = sp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self._nextLabelFS:SetPoint("TOPLEFT", sp, "TOPLEFT", 0, 0)
        self._nextLabelFS:SetText(GamingHub.GetLocaleTable("TETRIS")["label_next"])
    end

    -- Next-Frame
    local ncs = 18
    self._nextCS = ncs
    if not self._nextFrame then
        self._nextFrame = CreateFrame("Frame", nil, sp, "BackdropTemplate")
        self._nextFrame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile=false, edgeSize=2,
            insets={left=2,right=2,top=2,bottom=2},
        })
        self._nextFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.97)
        self._nextFrame:SetBackdropBorderColor(0.50, 0.42, 0.18, 1)
        self._nextFrame:SetSize(5*ncs+4, 5*ncs+4)
        self._nextFrame:SetPoint("TOPLEFT", sp, "TOPLEFT", 0, -18)
    end

    -- Next-Zellen immer neu (klein, schnell)
    self._nextCells = {}
    for _, child in pairs({self._nextFrame:GetChildren()}) do child:Hide() end
    for nr = 1, 5 do
        self._nextCells[nr] = {}
        for nc = 1, 5 do
            local f = CreateFrame("Frame", nil, self._nextFrame)
            f:SetSize(ncs-1, ncs-1)
            f:SetPoint("TOPLEFT", self._nextFrame, "TOPLEFT",
                (nc-1)*ncs + 2, -((nr-1)*ncs) - 2)
            local tex = f:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints(f)
            tex:Hide()
            f:Show()
            self._nextCells[nr][nc] = tex
        end
    end

    -- Score-Labels: nur einmal
    if self._sidePanelBuilt then return end
    self._sidePanelBuilt = true

    local previewH = 5*ncs + 4 + 8
    local ly = -(18 + previewH)

    local function mk(txt, y)
        local fs = sp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", sp, "TOPLEFT", 0, y)
        fs:SetText(txt)
        return fs
    end
    local function mv(y)
        local fs = sp:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("TOPLEFT", sp, "TOPLEFT", 0, y)
        fs:SetText("0")
        return fs
    end

    local _LSP = GamingHub.GetLocaleTable("TETRIS")
    mk(_LSP["label_score"],  ly);       self._scoreFS = mv(ly - 16)
    mk(_LSP["label_level"],  ly - 36);  self._levelFS = mv(ly - 52)
    mk(_LSP["label_lines"],  ly - 72);  self._linesFS = mv(ly - 88)
    mk(_LSP["label_best"],   ly - 108); self._highFS  = mv(ly - 124)
end

-- ============================================================
-- _paintCell: Zelle einfaerben + Icon/Atlas rendern
-- ============================================================
function R:_paintCell(cell, entry, alpha)
    if not cell or not entry then return end
    alpha = alpha or 1.0
    local cr, cg, cb = (entry.r or 0.5), (entry.g or 0.5), (entry.b or 0.5)
    cell:SetBackdropColor(cr * 0.80 * alpha, cg * 0.80 * alpha, cb * 0.80 * alpha, 1)
    if cell.icon then
        if entry.atlas then
            local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(entry.atlas)
            if info and info.file then
                cell.icon:SetTexture(info.file)
                cell.icon:SetTexCoord(info.leftTexCoord, info.rightTexCoord,
                                      info.topTexCoord,  info.bottomTexCoord)
                cell.icon:SetVertexColor(1, 1, 1, alpha)
                cell.icon:Show()
                return
            end
        end
        if entry.icon then
            cell.icon:SetTexture(entry.icon)
            cell.icon:SetTexCoord(0, 1, 0, 1)
            cell.icon:SetVertexColor(1, 1, 1, alpha)
            cell.icon:Show()
            return
        end
        cell.icon:Hide()
    end
end

function R:_clearCell(cell)
    if not cell then return end
    cell:SetBackdropColor(0.10, 0.10, 0.14, 1)
    if cell.icon  then cell.icon:Hide()  end
    if cell.ghost then cell.ghost:Hide() end
end

-- ============================================================
-- FullRedraw
-- ============================================================
function R:FullRedraw(board)
    local T = GamingHub.TET_Themes
    local S = GamingHub.TET_Settings
    local theme = T and T:Get(S and S:Get("theme") or "CLASSIC") or {}

    for r = 1, board.rows do
        for c = 1, board.cols do
            local cell = self._cells[r] and self._cells[r][c]
            if cell then
                local typ = board.cells[r][c]
                if typ and theme[typ] then
                    self:_paintCell(cell, theme[typ])
                else
                    self:_clearCell(cell)
                end
            end
        end
    end

    self:UpdatePiece(board)
    self:_updateScorePanel(board)
    self:_updateNextPanel(board)
end

-- ============================================================
-- UpdatePiece – aktives Piece + Ghost zeichnen
-- ============================================================
function R:UpdatePiece(board)
    if not board or not board.piece then return end

    local T = GamingHub.TET_Themes
    local S = GamingHub.TET_Settings
    local theme = T and T:Get(S and S:Get("theme") or "CLASSIC") or {}
    local L     = GamingHub.TET_Logic
    local p     = board.piece
    local entry = theme[p.type] or {r=0.5, g=0.5, b=0.5}

    -- Board-Zustand wiederherstellen
    for row = 1, board.rows do
        for col = 1, board.cols do
            local cell = self._cells[row] and self._cells[row][col]
            if cell then
                local typ = board.cells[row][col]
                if typ and theme[typ] then
                    self:_paintCell(cell, theme[typ])
                else
                    self:_clearCell(cell)
                end
            end
        end
    end

    -- Ghost
    if L then
        local ghostRow = L:GetGhostRow(board)
        local shape    = L:GetShape(p)
        for pr = 1, #shape do
            for pc = 1, #shape[pr] do
                if shape[pr][pc] == 1 then
                    local br = ghostRow + pr - 1
                    local bc = p.col   + pc - 1
                    local cell = self._cells[br] and self._cells[br][bc]
                    if cell and not board.cells[br][bc] then
                        if cell.ghost then
                            cell.ghost:SetVertexColor(entry.r, entry.g, entry.b, 0.20)
                            cell.ghost:Show()
                        end
                    end
                end
            end
        end
    end

    -- Aktives Piece
    local shape = L and L:GetShape(p) or {}
    for pr = 1, #shape do
        for pc = 1, #shape[pr] do
            if shape[pr][pc] == 1 then
                local br = p.row + pr - 1
                local bc = p.col + pc - 1
                local cell = self._cells[br] and self._cells[br][bc]
                if cell then
                    self:_paintCell(cell, entry)
                    if cell.ghost then cell.ghost:Hide() end
                end
            end
        end
    end

    self:_updateScorePanel(board)
    self:_updateNextPanel(board)
end

-- ============================================================
-- _updateScorePanel
-- ============================================================
function R:_updateScorePanel(board)
    if not board then return end
    local S = GamingHub.TET_Settings
    if self._scoreFS then self._scoreFS:SetText(tostring(board.score or 0)) end
    if self._levelFS then self._levelFS:SetText(tostring(board.level or 0)) end
    if self._linesFS then self._linesFS:SetText(tostring(board.lines or 0)) end
    if self._highFS and S then
        self._highFS:SetText(tostring(S:GetTopScore(S:Get("difficulty")) or 0))
    end
end

-- ============================================================
-- _updateNextPanel
-- ============================================================
function R:_updateNextPanel(board)
    if not board or not board.nextPiece then return end
    if not self._nextCells then return end

    local T = GamingHub.TET_Themes
    local S = GamingHub.TET_Settings
    local theme = T and T:Get(S and S:Get("theme") or "CLASSIC") or {}
    local L     = GamingHub.TET_Logic
    local np    = board.nextPiece
    local entry = theme[np.type] or {r=0.5, g=0.5, b=0.5}

    for nr = 1, 5 do
        for nc = 1, 5 do
            local tex = self._nextCells[nr] and self._nextCells[nr][nc]
            if tex then tex:Hide() end
        end
    end

    local shape = L and L:GetShape(np) or {}
    if #shape == 0 then return end
    local offR = math.floor((5 - #shape) / 2) + 1
    local offC = math.floor((5 - (#shape[1] or 0)) / 2) + 1

    for pr = 1, #shape do
        for pc = 1, #shape[pr] do
            if shape[pr][pc] == 1 then
                local nr = pr + offR - 1
                local nc = pc + offC - 1
                local tex = self._nextCells[nr] and self._nextCells[nr][nc]
                if tex then
                    if entry.atlas then
                        local info = C_Texture and C_Texture.GetAtlasInfo
                            and C_Texture.GetAtlasInfo(entry.atlas)
                        if info and info.file then
                            tex:SetTexture(info.file)
                            tex:SetTexCoord(info.leftTexCoord, info.rightTexCoord,
                                            info.topTexCoord,  info.bottomTexCoord)
                            tex:SetVertexColor(1, 1, 1, 1)
                            tex:Show()
                        else
                            tex:SetTexture("Interface\\Buttons\\WHITE8X8")
                            tex:SetTexCoord(0, 1, 0, 1)
                            tex:SetVertexColor(entry.r, entry.g, entry.b, 1)
                            tex:Show()
                        end
                    elseif entry.icon then
                        tex:SetTexture(entry.icon)
                        tex:SetTexCoord(0, 1, 0, 1)
                        tex:SetVertexColor(1, 1, 1, 1)
                        tex:Show()
                    else
                        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
                        tex:SetTexCoord(0, 1, 0, 1)
                        tex:SetVertexColor(entry.r, entry.g, entry.b, 1)
                        tex:Show()
                    end
                end
            end
        end
    end
end

-- ============================================================
-- Pause-Overlay
-- ============================================================
function R:ShowPause()
    if not self._pauseOverlay then
        local ov = CreateFrame("Frame", nil, self._gridFrame, "BackdropTemplate")
        ov:SetAllPoints(self._gridFrame)
        ov:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        ov:SetBackdropColor(0, 0, 0, 0.72)
        local fs = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        fs:SetPoint("CENTER")
        fs:SetText(GamingHub.GetLocaleTable("TETRIS")["pause_text"])
        self._pauseOverlay = ov
    end
    if self._pauseBtn then self._pauseBtn:SetText(GamingHub.GetLocaleTable("TETRIS")["btn_resume"]) end
    self._pauseOverlay:Show()
end

function R:HidePause()
    if self._pauseOverlay then self._pauseOverlay:Hide() end
    if self._pauseBtn then self._pauseBtn:SetText(GamingHub.GetLocaleTable("TETRIS")["btn_pause"]) end
end

-- ============================================================
-- Game-Over-Panel
-- ============================================================
function R:ShowGameOver(board)
    if not self._gameOverPanel then
        local ov = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
        ov:SetSize(260, 180)
        ov:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
        ov:SetFrameStrata("HIGH")
        ov:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true, tileEdge=true, tileSize=16, edgeSize=16,
            insets={left=4,right=4,top=4,bottom=4},
        })
        ov:SetBackdropColor(0.05, 0.05, 0.08, 0.96)
        ov:SetBackdropBorderColor(0.90, 0.75, 0.30, 1)

        local title = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", ov, "TOP", 0, -14)
        title:SetText(GamingHub.GetLocaleTable("TETRIS")["gameover_title"])

        local scoreFS = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        scoreFS:SetPoint("TOP", title, "BOTTOM", 0, -10)
        self._goScoreFS = scoreFS

        local linesFS = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        linesFS:SetPoint("TOP", scoreFS, "BOTTOM", 0, -6)
        self._goLinesFS = linesFS

        local bestFS = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bestFS:SetPoint("TOP", linesFS, "BOTTOM", 0, -6)
        self._goBestFS = bestFS

        local retry = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
        retry:SetSize(105, 26)
        retry:SetText(GamingHub.GetLocaleTable("TETRIS")["btn_retry"])
        retry:SetPoint("BOTTOMLEFT", ov, "BOTTOMLEFT", 14, 14)
        retry:SetScript("OnClick", function()
            ov:Hide()
            local E = GamingHub.TET_Engine
            if E then E:StartGame() end
        end)

        local menu = CreateFrame("Button", nil, ov, "UIPanelButtonTemplate")
        menu:SetSize(105, 26)
        menu:SetText(GamingHub.GetLocaleTable("TETRIS")["btn_menu"])
        menu:SetPoint("BOTTOMRIGHT", ov, "BOTTOMRIGHT", -14, 14)
        menu:SetScript("OnClick", function()
            local E = GamingHub.TET_Engine
            if E then E:StopGame() end
            R:EnterIdleState()
        end)

        self._gameOverPanel = ov
    end

    local S = GamingHub.TET_Settings
    local _LGO = GamingHub.GetLocaleTable("TETRIS")
    if self._goScoreFS then self._goScoreFS:SetText(_LGO["gameover_score"] .. (board.score or 0)) end
    if self._goLinesFS then self._goLinesFS:SetText(_LGO["gameover_lines"] .. (board.lines or 0)) end
    if self._goBestFS and S then
        self._goBestFS:SetText(_LGO["gameover_best"] .. (S:GetTopScore(board.difficulty) or 0))
    end

    if self._exitBtn  then self._exitBtn:Hide()  end
    if self._pauseBtn then self._pauseBtn:Hide() end
    self._gameOverPanel:Show()
end

-- ============================================================
-- RefreshTheme (vom Settings-Panel aufrufbar)
-- ============================================================
function R:RefreshTheme()
    local E = GamingHub.TET_Engine
    if E and E.state == "PLAYING" and E._board then
        self:FullRedraw(E._board)
    end
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "TETRIS",
    label     = "BlockDrop",
    renderer  = "TET_Renderer",
    engine    = "TET_Engine",
    container = "_tetContainer",
})
