--[[
    Gaming Hub
    Games/VierGewinnt/Game.lua
    Version: 1.0.0

    Unterschiede zu TicTacToe/Game.lua:
      - HandleMove(col) → nur Spalte, Zeile wird durch Schwerkraft bestimmt
      - Config:
          cols        – Spalten (z.B. 7)
          rows        – Zeilen (z.B. 6)
          aiDifficulty – "easy" / "normal" / "hard"
      - GetBoardState() gibt cols + rows statt size zurück
      - lastMove = { col, row } für den Renderer (Animationshinweis)
]]

local GamingHub = _G.GamingHub
local BaseGame  = GamingHub.BaseGame

local VierGewinntGame = setmetatable({}, BaseGame)
VierGewinntGame.__index = VierGewinntGame

GamingHub.VierGewinntGame = VierGewinntGame

-- ============================================================
-- Game Definition
-- ============================================================

VierGewinntGame.Definition = {
    id          = "VIERGEWINNT",
    displayName = "Vier Gewinnt",
}

-- ============================================================
-- Constructor
-- ============================================================

function VierGewinntGame:New()
    return BaseGame.New(self)
end

-- ============================================================
-- Init
-- ============================================================

function VierGewinntGame:Init(config)
    self.config  = config or {}
    self.logic   = GamingHub.VierGewinntLogic
    self.ai      = GamingHub.VierGewinntAI

    self.currentPlayer = 1
    self.gameOver      = false
    self.result        = nil
    self.winningLine   = nil
    self.lastMove      = nil  -- { col, row } – letzter gesetzter Stein

    -- Standard: 7×6 (klassisches Vier Gewinnt)
    local cols = self.config.cols or 7
    local rows = self.config.rows or 6

    self.board = self.logic:CreateBoard(cols, rows)
end

-- ============================================================
-- Reset
-- ============================================================

function VierGewinntGame:Reset()
    self:Init(self.config)
end

-- ============================================================
-- HandleMove
-- col: Zielspalte (1-basiert), vom Renderer übergeben
-- ============================================================

function VierGewinntGame:HandleMove(col)
    if self.gameOver then return end

    -- ── Spieler-Zug ──
    local row = self.logic:ApplyMove(self.board, col, self.currentPlayer)
    if not row then return end  -- Spalte voll

    self.lastMove = { col = col, row = row }

    -- Gewinn-Prüfung
    local result, line = self.logic:CheckWin(self.board, col, row, self.currentPlayer)

    if result == "WIN" then
        self.gameOver    = true
        self.result      = "WIN"
        self.winningLine = line
        return
    end

    if self.logic:IsBoardFull(self.board) then
        self.gameOver = true
        self.result   = "DRAW"
        return
    end

    -- ── KI-Zug ──
    self.currentPlayer = 2

    local aiCol = self.ai:GetBestMove(self.board, self.currentPlayer, self.config.aiDifficulty)

    if aiCol then
        local aiRow = self.logic:ApplyMove(self.board, aiCol, self.currentPlayer)

        if aiRow then
            self.lastMove = { col = aiCol, row = aiRow }

            local aiResult, aiLine = self.logic:CheckWin(
                self.board, aiCol, aiRow, self.currentPlayer
            )

            if aiResult == "WIN" then
                self.gameOver    = true
                self.result      = "LOSS"
                self.winningLine = aiLine
                return
            end

            if self.logic:IsBoardFull(self.board) then
                self.gameOver = true
                self.result   = "DRAW"
                return
            end
        end
    end

    -- Zurück zum Spieler
    self.currentPlayer = 1
end

-- ============================================================
-- GetBoardState
-- ============================================================

function VierGewinntGame:GetBoardState()
    return {
        cols        = self.board.cols,
        rows        = self.board.rows,
        cells       = self.board.cells,
        gameOver    = self.gameOver,
        result      = self.result,
        winningLine = self.winningLine,
        lastMove    = self.lastMove,
    }
end

-- ============================================================
-- Register
-- ============================================================

if GamingHub.Engine and GamingHub.Engine.RegisterGame then
    GamingHub.Engine:RegisterGame("VIERGEWINNT", VierGewinntGame)
end
