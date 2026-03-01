--[[
    Gaming Hub
    Games/VierGewinnt/Engine.lua
    Version: 1.0.0

    Schlanker Engine-Wrapper speziell für Vier Gewinnt.
    Emittet eigene Events mit VG_-Prefix damit TicTacToe-Renderer
    nicht versehentlich auf VierGewinnt-Events reagiert.

    Events:
      VG_GAME_STARTED(boardState)
      VG_BOARD_UPDATED
      VG_GAME_OVER(result)
      VG_WIN_LINE(line)
      VG_GAME_STOPPED
]]

local GamingHub = _G.GamingHub
GamingHub.VierGewinntEngine = {}

local VGE = GamingHub.VierGewinntEngine

VGE.activeGame = nil

-- ============================================================
-- StartGame
-- ============================================================

function VGE:StartGame(config)
    local gameClass = GamingHub.VierGewinntGame
    if not gameClass then
        print("GamingHub: VierGewinntGame nicht registriert.")
        return
    end

    local instance = gameClass:New()
    instance:Init(config or {})

    self.activeGame = instance

    GamingHub.Engine:Emit("VG_GAME_STARTED", instance:GetBoardState())
end

-- ============================================================
-- HandlePlayerMove
-- col: Zielspalte (1-basiert)
-- ============================================================

function VGE:HandlePlayerMove(col)
    if not self.activeGame then return end

    self.activeGame:HandleMove(col)

    local board = self.activeGame:GetBoardState()

    GamingHub.Engine:Emit("VG_BOARD_UPDATED", board)

    if board.gameOver then
        GamingHub.Engine:Emit("VG_GAME_OVER", board.result)

        if board.winningLine then
            GamingHub.Engine:Emit("VG_WIN_LINE", board.winningLine)
        end
    end
end

-- ============================================================
-- StopGame
-- ============================================================

function VGE:StopGame()
    if not self.activeGame then return end

    self.activeGame = nil

    GamingHub.Engine:Emit("VG_GAME_STOPPED")

    print("Vier Gewinnt: Spiel beendet.")
end
