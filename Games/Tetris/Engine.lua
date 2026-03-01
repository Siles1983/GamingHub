-- BlockDrop – Games/Tetris/Engine.lua

GamingHub = GamingHub or {}
GamingHub.TET_Engine = {}
local E  = GamingHub.TET_Engine

E.state        = "IDLE"
E._board       = nil
E._timer       = nil
E._keyFrame    = nil

local L, R, S, CE

function E:Init()
    L  = GamingHub.TET_Logic
    R  = GamingHub.TET_Renderer
    S  = GamingHub.TET_Settings
    CE = GamingHub.Engine
end

-- ============================================================
-- KeyFrame
-- ============================================================
function E:_setupKeyFrame()
    if self._keyFrame then return end
    local parent = R and R.frame or UIParent
    local kf = CreateFrame("Frame", nil, parent)
    kf:SetAllPoints(parent)
    kf:EnableKeyboard(false)
    kf:SetPropagateKeyboardInput(false)
    kf:SetScript("OnKeyDown", function(_, key)
        if E.state ~= "PLAYING" then return end
        local b = E._board
        if key == "A" or key == "LEFT" then
            L:MoveLeft(b); R:UpdatePiece(b)
        elseif key == "D" or key == "RIGHT" then
            L:MoveRight(b); R:UpdatePiece(b)
        elseif key == "W" or key == "UP" then
            L:Rotate(b); R:UpdatePiece(b)
        elseif key == "S" or key == "DOWN" then
            if L:Tick(b, b.piece) then
                R:UpdatePiece(b)
            end
        elseif key == "SPACE" then
            L:HardDrop(b)
            R:UpdatePiece(b)
            if S:Get("sound") then PlaySound(1115) end
        end
    end)
    -- Kein OnMouseDown auf keyFrame – wuerde Buttons blockieren.
    -- Rechtsklick-Rotation wird im _gridFrame des Renderers abgefangen.
    self._keyFrame = kf
end

function E:EnableKeys(enable)
    if self._keyFrame then
        self._keyFrame:EnableKeyboard(enable)
    end
end

-- ============================================================
-- StartGame
-- ============================================================
function E:StartGame()
    if self.state == "PLAYING" then return end
    self:_setupKeyFrame()

    local diff = S:Get("difficulty")
    self._board = L:NewBoard(diff)
    local b = self._board

    b.nextPiece = L:NewPiece(b)
    self:_spawnNext()

    self.state = "PLAYING"
    self:EnableKeys(true)

    R:EnterPlayState(b)
    R:FullRedraw(b)

    self:_startTick()

    if CE then CE:Emit("TET_GAME_STARTED", {}) end
end

-- ============================================================
-- StopGame
-- ============================================================
function E:StopGame()
    self:_stopTick()
    self:EnableKeys(false)
    self.state = "IDLE"
    self._board = nil
end

-- ============================================================
-- Pause
-- ============================================================
function E:TogglePause()
    if self.state == "PLAYING" then
        self:_stopTick()
        self:EnableKeys(false)
        self.state = "PAUSED"
        R:ShowPause()
    elseif self.state == "PAUSED" then
        self:_startTick()
        self:EnableKeys(true)
        self.state = "PLAYING"
        R:HidePause()
    end
end

-- ============================================================
-- _spawnNext
-- ============================================================
function E:_spawnNext()
    local b = self._board
    b.piece     = b.nextPiece
    b.nextPiece = L:NewPiece(b)
    if L:CheckGameOver(b, b.piece) then
        self:_gameOver()
    end
end

-- ============================================================
-- Tick-Timer
-- ============================================================
function E:_startTick()
    self:_stopTick()
    local interval = L:GetTickInterval(self._board and self._board.level or 0)
    self._timer = C_Timer.NewTicker(interval, function()
        if E.state ~= "PLAYING" then return end
        E:_tick()
    end)
end

function E:_stopTick()
    if self._timer then
        self._timer:Cancel()
        self._timer = nil
    end
end

-- ============================================================
-- Gravity-Tick
-- ============================================================
function E:_tick()
    local b = self._board
    if not b or not b.piece then return end

    local landed = not L:Tick(b, b.piece)

    if landed then
        L:LockPiece(b, b.piece)
        local cleared = L:ClearLines(b)
        local oldLevel = b.level
        L:AddScore(b, cleared)

        -- Sound: NUR PlaySound(ID) ohne Channel-Parameter
        if cleared > 0 and S:Get("sound") then
            if cleared == 4 then
                PlaySound(1115)   -- BlockDrop! (4 Reihen)
            else
                PlaySound(1117)   -- Line-Clear
            end
        end

        if b.level ~= oldLevel then
            self:_startTick()
            if CE then CE:Emit("TET_LEVEL_UP", { level = b.level }) end
        end

        if cleared > 0 and CE then
            CE:Emit("TET_LINES_CLEARED", { lines = cleared, score = b.score })
        end

        self:_spawnNext()
        R:FullRedraw(b)
    else
        R:UpdatePiece(b)
    end
end

-- ============================================================
-- GameOver
-- ============================================================
function E:_gameOver()
    self:_stopTick()
    self:EnableKeys(false)
    self.state = "GAMEOVER"

    local b = self._board
    if not b then return end

    S:SubmitScore(b.difficulty, b.score, b.lines)

    if S:Get("sound") then PlaySound(847) end

    R:ShowGameOver(b)

    if CE then CE:Emit("TET_GAME_OVER", { score = b.score }) end
end
