--[[
    Gaming Hub
    Games/2048/Engine.lua
    Version: 1.1.0

    Events (TDG_ Prefix):
      TDG_GAME_STARTED(boardState)
      TDG_BOARD_UPDATED(boardState)
      TDG_GAME_OVER(result)   – "LOSS" (keine Züge mehr)
      TDG_GAME_STOPPED

    Keine Sieg-Bedingung. Kein TDG_GAME_WON.
]]

local GamingHub = _G.GamingHub
GamingHub.TDG_Engine = {}
local E = GamingHub.TDG_Engine

E.activeGame = nil

-- ============================================================
-- Sound
-- ============================================================

local function PlayGameSound(event)
    local S = GamingHub.TDG_Settings
    if not S or not S:Get("soundEnabled") then return end
    if event == "LOSS" and S:Get("soundOnLoss") then PlaySound(847, "SFX") end
end

-- ============================================================
-- StartGame
-- ============================================================

function E:StartGame(config)
    local gameClass = GamingHub.TDG_Game
    if not gameClass then
        print("GamingHub: TDG_Game nicht registriert.")
        return
    end

    local S   = GamingHub.TDG_Settings
    local cfg = {
        size = (config and config.size) or (S and S:Get("boardSize")) or 4,
    }

    local instance = gameClass:New()
    instance:Init(cfg)
    self.activeGame = instance

    GamingHub.Engine:Emit("TDG_GAME_STARTED", instance:GetBoardState())
end

-- ============================================================
-- HandlePlayerMove
-- direction: "UP" | "DOWN" | "LEFT" | "RIGHT"
-- ============================================================

function E:HandlePlayerMove(direction)
    if not self.activeGame then return end

    self.activeGame:HandleMove(direction)

    local state = self.activeGame:GetBoardState()

    GamingHub.Engine:Emit("TDG_BOARD_UPDATED", state)

    if state.gameOver then
        GamingHub.Engine:Emit("TDG_GAME_OVER", state.result)
        PlayGameSound("LOSS")
    end
end

-- ============================================================
-- StopGame
-- ============================================================

function E:StopGame()
    if not self.activeGame then return end
    self.activeGame = nil
    GamingHub.Engine:Emit("TDG_GAME_STOPPED")
end
