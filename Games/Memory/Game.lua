--[[
    Gaming Hub
    Games/Memory/Game.lua
    Version: 1.0.0
]]

local GamingHub = _G.GamingHub
local BaseGame  = GamingHub.BaseGame

local MemGame = setmetatable({}, BaseGame)
MemGame.__index = MemGame
GamingHub.MEM_Game = MemGame

function MemGame:New()
    return BaseGame.New(self)
end

function MemGame:Init(config)
    self.config     = config or {}
    self.logic      = GamingHub.MEM_Logic
    self.difficulty = self.config.difficulty  or "easy"
    self.theme      = self.config.theme       or "classes"
    self.timerActive= self.config.timerActive or false
    self.board      = self.logic:NewGame({
        difficulty  = self.difficulty,
        theme       = self.theme,
        timerActive = self.timerActive,
    })
end

function MemGame:FlipCard(idx)
    return self.logic:FlipCard(self.board, idx)
end

function MemGame:CheckMatch()
    return self.logic:CheckMatch(self.board)
end

function MemGame:ResetFlipped()
    return self.logic:ResetFlipped(self.board)
end

function MemGame:SetBlocked(v)
    self.board.blocked = v
end

function MemGame:IsBlocked()
    return self.board.blocked == true
end

function MemGame:TickTimer(dt)
    return self.logic:TickTimer(self.board, dt)
end

function MemGame:GetBoardState()
    return self.logic:GetBoardState(self.board)
end

function MemGame:Reset()
    self:Init(self.config)
end
