--[[
    Gaming Hub
    BaseGame.lua
    Version: 1.0.0 (Game Base Class)
]]

local GamingHub = _G.GamingHub
GamingHub.BaseGame = {}

local BaseGame = GamingHub.BaseGame
BaseGame.__index = BaseGame

-- ==========================================
-- Constructor
-- ==========================================

function BaseGame:New()
    local obj = setmetatable({}, self)
    obj.isGame = true
    return obj
end

-- ==========================================
-- Virtual Methods (Override Required)
-- ==========================================

function BaseGame:Init(config)
    error("Game must implement :Init(config)")
end

function BaseGame:GetBoardState()
    error("Game must implement :GetBoardState()")
end

function BaseGame:HandleMove(x, y)
    error("Game must implement :HandleMove(x, y)")
end

function BaseGame:Reset()
    error("Game must implement :Reset()")
end