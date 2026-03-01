--[[
    Gaming Hub
    Engine.lua
    Version: 1.0.0 (Event-Driven Generic Engine)
]]

local GamingHub = _G.GamingHub
GamingHub.Engine = {}

local Engine = GamingHub.Engine

Engine.listeners = {}
Engine.games = {}
Engine.activeGame = nil

-- ==========================================
-- Init
-- ==========================================

function Engine:Init()

    local seed = GetServerTime()
    if _G.math and _G.math.randomseed then
        _G.math.randomseed(seed)
    end

    print("GamingHub Engine Ready.")
end

-- ==========================================
-- Event System
-- ==========================================

function Engine:On(event, callback)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end
    table.insert(self.listeners[event], callback)
end

function Engine:Emit(event, data)
    if not self.listeners[event] then return end
    for _, cb in ipairs(self.listeners[event]) do
        cb(data)
    end
end

-- ==========================================
-- Game Registry
-- ==========================================

function Engine:RegisterGame(id, gameClass)
    self.games[id] = gameClass
end

-- ==========================================
-- Start Generic Game
-- ==========================================

function Engine:StartGame(id, config)

    local gameClass = self.games[id]
    if not gameClass then
        print("GamingHub: Game not registered ->", id)
        return
    end

    local instance = gameClass:New()
    instance:Init(config or {})

    self.activeGame = instance

    self:Emit("GAME_STARTED", instance:GetBoardState())
end

-- ==========================================
-- Handle Player Move
-- ==========================================

function Engine:HandlePlayerMove(x, y)

    if not self.activeGame then return end

    self.activeGame:HandleMove(x, y)

    local board = self.activeGame:GetBoardState()

    self:Emit("BOARD_UPDATED", board)

    if board.gameOver then
        self:Emit("GAME_OVER", board.result)

        if board.winningLine then
            self:Emit("WIN_LINE", board.winningLine)
        end
    end
end

-- ==========================================
-- Get Game Definition
-- ==========================================

function Engine:GetGameDefinition(id)
    local gameClass = self.games[id]
    if not gameClass or not gameClass.Definition then
        return nil
    end
    return gameClass.Definition
end

-- ==========================================
-- Stop Game (Return to Idle)
-- ==========================================

function Engine:StopGame()

    if not self.activeGame then
        return
    end

    self.activeGame = nil

    if self.StateMachine then
        self.StateMachine:SetState("IDLE")
    end

    self:Emit("GAME_STOPPED")

    print("Game Stopped. Back to Idle.")
end