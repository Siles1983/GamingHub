--[[
    Gaming Hub
    Games/Minesweeper/Game.lua
    Version: 1.0.0
]]

local GamingHub = _G.GamingHub
local BaseGame  = GamingHub.BaseGame

local MSGame = setmetatable({}, BaseGame)
MSGame.__index = MSGame
GamingHub.MS_Game = MSGame

function MSGame:New()
    return BaseGame.New(self)
end

function MSGame:Init(config)
    self.config     = config or {}
    self.logic      = GamingHub.MS_Logic
    self.difficulty = self.config.difficulty or "easy"
    self.board      = self.logic:NewBoard(self.difficulty)
end

function MSGame:RevealCell(r, c)
    if self.board.phase ~= "PLAYING" then return "game_over" end
    return self.logic:RevealCell(self.board, r, c)
end

function MSGame:ToggleFlag(r, c)
    if self.board.phase ~= "PLAYING" then return "game_over" end
    return self.logic:ToggleFlag(self.board, r, c)
end

function MSGame:GetBoardState()
    return self.logic:GetBoardState(self.board)
end

function MSGame:Reset()
    self:Init(self.config)
end
