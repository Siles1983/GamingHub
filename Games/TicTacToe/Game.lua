--[[
    Gaming Hub
    TicTacToe Game.lua
    Version: 0.2.1 (Draw Detection Fix)
]]

local GamingHub = _G.GamingHub
local BaseGame = GamingHub.BaseGame

-- ==========================================
-- Class Definition (inherits from BaseGame)
-- ==========================================

local TicTacToeGame = setmetatable({}, BaseGame)
TicTacToeGame.__index = TicTacToeGame

GamingHub.TicTacToeGame = TicTacToeGame

-- ==========================================
-- Game Definition
-- ==========================================

TicTacToeGame.Definition = {
    id = "TICTACTOE",
    displayName = "Tic Tac Toe",


}

-- ==========================================
-- Constructor
-- ==========================================

function TicTacToeGame:New()
    local obj = BaseGame.New(self)
    return obj
end

-- ==========================================
-- Init
-- ==========================================

function TicTacToeGame:Init(config)

    self.config = config or {}
    self.logic = GamingHub.TicTacToeLogic
    self.ai = GamingHub.TicTacToeAI

    self.currentPlayer = 1
    self.gameOver = false
    self.result = nil
    self.winningLine = nil

    self.board = self.logic:CreateBoard(
        self.config.boardSize or 3,
        self.config.winLength or 3
    )
end

-- ==========================================
-- Reset
-- ==========================================

function TicTacToeGame:Reset()
    self:Init(self.config)
end

-- ==========================================
-- HandleMove
-- ==========================================

function TicTacToeGame:HandleMove(x, y)

    if self.gameOver then return end

    -- PLAYER MOVE
    local success = self.logic:ApplyMove(self.board, x, y, self.currentPlayer)
    if not success then return end

    -- CHECK RESULT
    local result, line = self.logic:CheckWin(
        self.board,
        x,
        y,
        self.currentPlayer
    )

    if result == "WIN" then
        self.gameOver = true
        self.result = "WIN"
        self.winningLine = line
        return
    elseif result == "DRAW" then
        self.gameOver = true
        self.result = "DRAW"
        return
    end

    -- SWITCH TO AI
    self.currentPlayer = 2

    -- =========================
    -- AI TURN
    -- =========================

    local aiMove = self.ai:GetBestMove(
        self.board,
        self.currentPlayer,
        self.config.aiDifficulty
    )

    if aiMove then
        self.logic:ApplyMove(self.board, aiMove.x, aiMove.y, self.currentPlayer)

        local aiResult, aiLine = self.logic:CheckWin(
            self.board,
            aiMove.x,
            aiMove.y,
            self.currentPlayer
        )

        if aiResult == "WIN" then
            self.gameOver = true
            self.result = "LOSS"
            self.winningLine = aiLine
            return
        elseif aiResult == "DRAW" then
            self.gameOver = true
            self.result = "DRAW"
            return
        end
    end

    -- BACK TO PLAYER
    self.currentPlayer = 1
end

-- ==========================================
-- GetBoardState
-- ==========================================

function TicTacToeGame:GetBoardState()

    return {
        size = self.board.size,
        cells = self.board.cells,
        gameOver = self.gameOver,
        result = self.result,
        winningLine = self.winningLine
    }
end

-- ==========================================
-- Register Game
-- ==========================================

if GamingHub.Engine and GamingHub.Engine.RegisterGame then
    GamingHub.Engine:RegisterGame("TICTACTOE", TicTacToeGame)
end

-- [GAMEHUB_REGISTERED]
GamingHub.RegisterGame({
    id        = "TICTACTOE",
    label     = "Tic Tac Toe",
    renderer  = "Renderer",
    engine    = "Engine",
    container = "_tttContainer",
})
