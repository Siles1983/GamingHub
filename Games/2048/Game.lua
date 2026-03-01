--[[
    Gaming Hub
    Games/2048/Game.lua
    Version: 1.1.0

    - Kein Gegner, kein KI-Zug
    - HandleMove(direction) → "UP"|"DOWN"|"LEFT"|"RIGHT"
    - result: "LOSS" (keine Züge mehr) – keine Sieg-Bedingung
    - Score wird im Game-State mitgeführt
    - bestScore persistent in GamingHubDB
]]

local GamingHub = _G.GamingHub
local BaseGame  = GamingHub.BaseGame

local TDG_Game = setmetatable({}, BaseGame)
TDG_Game.__index = TDG_Game

GamingHub.TDG_Game = TDG_Game

TDG_Game.Definition = {
    id          = "2048",
    displayName = "2048",
}

-- ============================================================
-- Constructor
-- ============================================================

function TDG_Game:New()
    return BaseGame.New(self)
end

-- ============================================================
-- Init
-- ============================================================

function TDG_Game:Init(config)
    self.config    = config or {}
    self.logic     = GamingHub.TDG_Logic
    self.gameOver  = false
    self.result    = nil
    self.lastSpawn = nil

    local size    = self.config.size or 4
    self.board    = self.logic:CreateBoard(size)

    self.logic:SpawnTile(self.board)
    self.logic:SpawnTile(self.board)

    self.bestScore = self:_LoadBestScore()
end

-- ============================================================
-- Reset
-- ============================================================

function TDG_Game:Reset()
    self:Init(self.config)
end

-- ============================================================
-- HandleMove
-- direction: "UP" | "DOWN" | "LEFT" | "RIGHT"
-- ============================================================

function TDG_Game:HandleMove(direction)
    if self.gameOver then return end

    local moved, _ = self.logic:Slide(self.board, direction)
    if not moved then return end

    local r, c, v = self.logic:SpawnTile(self.board)
    self.lastSpawn = r and { row = r, col = c, value = v } or nil

    if self.board.score > self.bestScore then
        self.bestScore = self.board.score
        self:_SaveBestScore(self.bestScore)
    end

    if not self.logic:HasMoves(self.board) then
        self.gameOver = true
        self.result   = "LOSS"
    end
end

-- ============================================================
-- GetBoardState
-- ============================================================

function TDG_Game:GetBoardState()
    return {
        size      = self.board.size,
        cells     = self.board.cells,
        merged    = self.board.merged,
        score     = self.board.score,
        bestScore = self.bestScore,
        gameOver  = self.gameOver,
        result    = self.result,
        lastSpawn = self.lastSpawn,
    }
end

-- ============================================================
-- Best Score Persistenz
-- ============================================================

local DB_KEY = "2048_BestScore"

function TDG_Game:_LoadBestScore()
    if _G.GamingHubDB and _G.GamingHubDB[DB_KEY] then
        return _G.GamingHubDB[DB_KEY]
    end
    return 0
end

function TDG_Game:_SaveBestScore(score)
    if not _G.GamingHubDB then _G.GamingHubDB = {} end
    _G.GamingHubDB[DB_KEY] = score
end
