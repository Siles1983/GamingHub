-- BlockDrop – Games/Tetris/Logic.lua
-- Reine Spiellogik: Board, Pieces, Rotation, Kollision, Line-Clear

GamingHub = GamingHub or {}
GamingHub.TET_Logic = {}
local L = GamingHub.TET_Logic

-- ============================================================
-- Schwierigkeiten
-- ============================================================
L.DIFFICULTY = {
    EASY   = { cols=12, rows=22, startInterval=0.9,  label="Easy"   },
    NORMAL = { cols=10, rows=20, startInterval=0.65, label="Normal" },
    HARD   = { cols=8,  rows=18, startInterval=0.40, label="Hard"   },
}

-- ============================================================
-- Piece-Definitionen (Rotationen als 2D-Arrays)
-- ============================================================
local PIECES = {
    I = {
        shapes = {
            {{0,0,0,0},{1,1,1,1},{0,0,0,0},{0,0,0,0}},
            {{0,0,1,0},{0,0,1,0},{0,0,1,0},{0,0,1,0}},
        },
        type = "I",
    },
    O = {
        shapes = {
            {{1,1},{1,1}},
        },
        type = "O",
    },
    T = {
        shapes = {
            {{0,1,0},{1,1,1},{0,0,0}},
            {{0,1,0},{0,1,1},{0,1,0}},
            {{0,0,0},{1,1,1},{0,1,0}},
            {{0,1,0},{1,1,0},{0,1,0}},
        },
        type = "T",
    },
    L = {
        shapes = {
            {{0,0,1},{1,1,1},{0,0,0}},
            {{0,1,0},{0,1,0},{0,1,1}},
            {{0,0,0},{1,1,1},{1,0,0}},
            {{1,1,0},{0,1,0},{0,1,0}},
        },
        type = "L",
    },
    J = {
        shapes = {
            {{1,0,0},{1,1,1},{0,0,0}},
            {{0,1,1},{0,1,0},{0,1,0}},
            {{0,0,0},{1,1,1},{0,0,1}},
            {{0,1,0},{0,1,0},{1,1,0}},
        },
        type = "J",
    },
    S = {
        shapes = {
            {{0,1,1},{1,1,0},{0,0,0}},
            {{0,1,0},{0,1,1},{0,0,1}},
        },
        type = "S",
    },
    Z = {
        shapes = {
            {{1,1,0},{0,1,1},{0,0,0}},
            {{0,0,1},{0,1,1},{0,1,0}},
        },
        type = "Z",
    },
}

local PIECE_TYPES = {"I","O","T","L","J","S","Z"}

-- ============================================================
-- Board erstellen
-- ============================================================
function L:NewBoard(difficulty)
    local cfg = self.DIFFICULTY[difficulty] or self.DIFFICULTY.NORMAL
    local board = {
        difficulty  = difficulty,
        cols        = cfg.cols,
        rows        = cfg.rows,
        interval    = cfg.startInterval,
        level       = 0,
        score       = 0,
        lines       = 0,
        gameActive  = false,
        cells       = {},   -- [row][col] = pieceType or nil
        piece       = nil,
        nextPiece   = nil,
    }
    for r = 1, cfg.rows do
        board.cells[r] = {}
        for c = 1, cfg.cols do
            board.cells[r][c] = nil
        end
    end
    return board
end

-- ============================================================
-- Piece erstellen
-- ============================================================
function L:NewPiece(board)
    local typeKey = PIECE_TYPES[math.random(#PIECE_TYPES)]
    local def     = PIECES[typeKey]
    return {
        type     = typeKey,
        rotation = 1,
        shapes   = def.shapes,
        row      = 1,
        col      = math.floor((board.cols - #def.shapes[1][1]) / 2) + 1,
    }
end

function L:GetShape(piece)
    return piece.shapes[piece.rotation]
end

-- ============================================================
-- Kollisionsprüfung
-- ============================================================
function L:_fits(board, piece, dr, dc, rot)
    local r = rot or piece.rotation
    local shape = piece.shapes[r]
    for pr = 1, #shape do
        for pc = 1, #shape[pr] do
            if shape[pr][pc] == 1 then
                local br = piece.row + pr - 1 + dr
                local bc = piece.col + pc - 1 + dc
                if br < 1 or br > board.rows then return false end
                if bc < 1 or bc > board.cols then return false end
                if board.cells[br][bc] then return false end
            end
        end
    end
    return true
end

-- ============================================================
-- Bewegungen
-- ============================================================
function L:MoveLeft(board)
    if self:_fits(board, board.piece, 0, -1) then
        board.piece.col = board.piece.col - 1
        return true
    end
    return false
end

function L:MoveRight(board)
    if self:_fits(board, board.piece, 0, 1) then
        board.piece.col = board.piece.col + 1
        return true
    end
    return false
end

function L:Rotate(board)
    local p        = board.piece
    local maxRot   = #p.shapes
    local nextRot  = (p.rotation % maxRot) + 1
    -- Wall-kick: versuche normal, dann +1, -1 Spalte
    for _, dc in ipairs({0, 1, -1, 2, -2}) do
        if self:_fits(board, p, 0, dc, nextRot) then
            p.rotation = nextRot
            p.col      = p.col + dc
            return true
        end
    end
    return false
end

-- Tick: Piece eine Zeile nach unten
-- Gibt true zurück wenn bewegt, false wenn gelandet
function L:Tick(board, piece)
    if self:_fits(board, piece, 1, 0) then
        piece.row = piece.row + 1
        return true
    end
    return false
end

-- Harddrop: sofort nach unten
function L:HardDrop(board)
    local p = board.piece
    while self:_fits(board, p, 1, 0) do
        p.row = p.row + 1
    end
end

-- Ghost-Position berechnen
function L:GetGhostRow(board)
    local p    = board.piece
    local ghostRow = p.row
    while true do
        local dr = ghostRow - p.row + 1
        if self:_fits(board, p, dr, 0) then
            ghostRow = ghostRow + 1
        else
            break
        end
    end
    return ghostRow
end

-- ============================================================
-- Piece einrasten
-- ============================================================
function L:LockPiece(board, piece)
    local shape = self:GetShape(piece)
    for pr = 1, #shape do
        for pc = 1, #shape[pr] do
            if shape[pr][pc] == 1 then
                local br = piece.row + pr - 1
                local bc = piece.col + pc - 1
                if br >= 1 and br <= board.rows and bc >= 1 and bc <= board.cols then
                    board.cells[br][bc] = piece.type
                end
            end
        end
    end
end

-- ============================================================
-- Linien löschen
-- ============================================================
function L:ClearLines(board)
    local cleared = 0
    local r = board.rows
    while r >= 1 do
        local full = true
        for c = 1, board.cols do
            if not board.cells[r][c] then full = false; break end
        end
        if full then
            table.remove(board.cells, r)
            local newRow = {}
            for c = 1, board.cols do newRow[c] = nil end
            table.insert(board.cells, 1, newRow)
            cleared = cleared + 1
            -- r bleibt gleich (neue Zeile von oben)
        else
            r = r - 1
        end
    end
    return cleared
end

-- ============================================================
-- Score & Level
-- ============================================================
local LINE_SCORES = {40, 100, 300, 1200}
local DIFF_FACTOR = { EASY=1.0, NORMAL=1.5, HARD=2.5 }

function L:AddScore(board, linesCleared)
    if linesCleared > 0 then
        local base   = LINE_SCORES[linesCleared] or 1200
        local factor = DIFF_FACTOR[board.difficulty] or 1.0
        local pts    = math.floor(base * (board.level + 1) * factor)
        board.score  = board.score + pts
        board.lines  = board.lines + linesCleared
        board.level  = math.floor(board.lines / 10)
    end
end

function L:GetTickInterval(level)
    -- Spec: Level 0=1.0s, 5=0.5s, 10=0.25s, 15+=0.10s
    if level <= 0  then return 1.00 end
    if level <= 5  then return 1.00 - (level / 5) * 0.50 end
    if level <= 10 then return 0.50 - ((level - 5) / 5) * 0.25 end
    if level <= 15 then return 0.25 - ((level - 10) / 5) * 0.15 end
    return 0.10
end

-- ============================================================
-- Game-Over-Check
-- ============================================================
function L:CheckGameOver(board, piece)
    return not self:_fits(board, piece, 0, 0)
end
