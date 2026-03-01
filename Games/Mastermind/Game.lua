--[[
    Gaming Hub – Mastermind: Azeroth Edition
    Games/Mastermind/Game.lua
    Dünner Wrapper um Logic. Hält das Board als self.board.
]]

local GamingHub = _G.GamingHub
GamingHub.MM_Game = {}
local G = GamingHub.MM_Game

function G:New()
    local obj = setmetatable({}, { __index = G })
    obj.board = nil
    return obj
end

function G:Init(config)
    local L      = GamingHub.MM_Logic
    local T      = GamingHub.MM_Themes
    local theme  = T:GetTheme(config.theme)
    local cfg = {
        difficulty   = config.difficulty,
        codeLength   = config.codeLength,
        duplicates   = config.duplicates,
        theme        = config.theme,
        themeName    = theme.name,
        symbolCount  = T:GetSymbolCount(config.theme),
    }
    self.board = L:NewBoard(cfg)
end

function G:SetSlot(slotIdx, symbolIdx)
    return GamingHub.MM_Logic:SetSlot(self.board, slotIdx, symbolIdx)
end

function G:ClearSlot(slotIdx)
    return GamingHub.MM_Logic:ClearSlot(self.board, slotIdx)
end

function G:IsGuessComplete()
    return GamingHub.MM_Logic:IsGuessComplete(self.board)
end

function G:SubmitGuess()
    return GamingHub.MM_Logic:SubmitGuess(self.board)
end

function G:GetBoardState()
    return GamingHub.MM_Logic:GetBoardState(self.board)
end
