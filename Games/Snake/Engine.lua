--[[
    Gaming Hub – Snake
    Games/Snake/Engine.lua

    Events (SNK_ Prefix):
      SNK_GAME_STARTED(board)
      SNK_GAME_WON(board, isNewHighscore)
      SNK_GAME_LOST(board, isNewHighscore)
      SNK_GAME_STOPPED()

    Renderer wird für zeitkritische Darstellung direkt aufgerufen.
    C_Timer.After → Ticker-Loop.
    Tastatur-Input via KeyDown-Hook auf dem Game-Frame.
]]

local GamingHub = _G.GamingHub
GamingHub.SNK_Engine = {}
local E = GamingHub.SNK_Engine

E.activeGame = nil
E._running   = false
E._tickRate  = 0.18

-- ============================================================
-- Sound
-- ============================================================
local function PlaySNK(event)
    local S = GamingHub.SNK_Settings
    if not S or not S:Get("soundEnabled") then return end
    if event == "eat" and S:Get("soundOnEat") then
        PlaySound(SOUNDKIT.IG_QUEST_ABANDON or 847, "SFX")
    elseif event == "die" and S:Get("soundOnDie") then
        PlaySound(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT or 847, "SFX")
    elseif event == "start" and S:Get("soundOnStart") then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 774, "SFX")
    end
end

-- ============================================================
-- StartGame
-- ============================================================
function E:StartGame(config)
    self:StopGame()

    local S   = GamingHub.SNK_Settings
    local T   = GamingHub.SNK_Themes
    local cfg = {
        difficulty = (config and config.difficulty) or S:Get("difficulty"),
        theme      = (config and config.theme)      or S:Get("theme"),
    }

    local board    = GamingHub.SNK_Logic:NewBoard(cfg)
    local diff     = T:GetDiff(cfg.difficulty)
    self.activeGame = { board = board }
    self._running   = true
    self._tickRate  = diff.tickRate

    PlaySNK("start")
    GamingHub.Engine:Emit("SNK_GAME_STARTED", board)

    -- Tick-Loop starten
    self:ScheduleTick()
end

-- ============================================================
-- ScheduleTick – plant den nächsten Tick
-- ============================================================
function E:ScheduleTick()
    if not self._running then return end
    C_Timer.After(self._tickRate, function()
        if not self._running then return end
        self:DoTick()
    end)
end

-- ============================================================
-- DoTick – einen Spielschritt
-- ============================================================
function E:DoTick()
    if not self.activeGame or not self._running then return end
    local board  = self.activeGame.board
    local R      = GamingHub.SNK_Renderer

    -- Schwanz merken BEVOR Logic den Tick macht
    if R then
        local snake = board.snake
        if snake[#snake] then
            R._lastTail = { r=snake[#snake].r, c=snake[#snake].c }
        end
    end

    local result = GamingHub.SNK_Logic:Tick(board)

    if R then R:OnTick(board, result) end

    if result == "ate" then
        PlaySNK("eat")
        self:ScheduleTick()
    elseif result == "moved" then
        self:ScheduleTick()
    elseif result == "died" then
        PlaySNK("die")
        self._running = false
        local S = GamingHub.SNK_Settings
        local isNew = S:SetHighscore(board.difficulty, board.score)
        if R then R:OnGameLost(board, isNew) end
        GamingHub.Engine:Emit("SNK_GAME_LOST", board, isNew)
    elseif result == "won" then
        self._running = false
        local S = GamingHub.SNK_Settings
        local isNew = S:SetHighscore(board.difficulty, board.score)
        if R then R:OnGameWon(board, isNew) end
        GamingHub.Engine:Emit("SNK_GAME_WON", board, isNew)
    end
end

-- ============================================================
-- HandleKey – Richtungseingabe
-- ============================================================
function E:HandleKey(key)
    if not self.activeGame or not self._running then return end
    local board = self.activeGame.board
    local L     = GamingHub.SNK_Logic
    if     key == "W" or key == "UP"    then L:QueueDir(board, -1,  0)
    elseif key == "S" or key == "DOWN"  then L:QueueDir(board,  1,  0)
    elseif key == "A" or key == "LEFT"  then L:QueueDir(board,  0, -1)
    elseif key == "D" or key == "RIGHT" then L:QueueDir(board,  0,  1)
    end
end

-- ============================================================
-- StopGame
-- ============================================================
function E:StopGame()
    self._running   = false
    self.activeGame = nil
    GamingHub.Engine:Emit("SNK_GAME_STOPPED")
    local R = GamingHub.SNK_Renderer
    if R and R.EnterIdleState then R:EnterIdleState() end
end
