--[[
    Gaming Hub – Mensch ärgere dich nicht (Ludo)
    Games/Ludo/Logic.lua

    Pure Spiellogik. Kein UI, kein State außer dem übergebenen Game-Objekt.

    Game-Objekt:
    {
        players     table    [1..2] → PlayerState
        current     number   aktiver Spieler-ID (1 oder 2)
        humanID     number   welcher Spieler = Mensch
        aiID        number   welcher Spieler = KI
        dice        number   letzter Würfelwert (0 = noch nicht gewürfelt)
        rolled      bool     ob dieser Zug schon gewürfelt wurde
        sixCount    number   Anzahl aufeinanderfolgender Sechsen (max 3)
        phase       string   "roll"|"move"|"gameover"
        winner      number   Spieler-ID des Gewinners (0 = keiner)
    }

    PlayerState:
    {
        id          number   1 oder 2
        colorIdx    number   1=Blau, 2=Rot (Themen-Index)
        pieces      table    [1..4] → PieceState
    }

    PieceState:
    {
        relPos      number   0=Basis, 1-40=Hauptpfad, 41-44=Zielgerade, 45=Zuhause(fertig)
        gridIdx     number   aktueller Grid-Index (für Renderer)
        finished    bool
    }
]]

local GamingHub = _G.GamingHub
GamingHub.LUDO_Logic = {}
local L = GamingHub.LUDO_Logic

local B = nil  -- wird lazy geladen

local function GetBoard()
    if not B then B = GamingHub.LUDO_Board end
    return B
end

-- ============================================================
-- NewGame
-- ============================================================
function L:NewGame(config)
    local board = GetBoard()
    local humanColor = config.humanColor or 1
    local aiColor    = (humanColor == 1) and 2 or 1

    local function MakePlayer(id, colorIdx)
        local pieces = {}
        local baseFields = board.BASE_FIELDS[colorIdx]
        for i = 1, 4 do
            pieces[i] = {
                relPos   = 0,
                gridIdx  = baseFields[i],
                finished = false,
            }
        end
        return {
            id       = id,
            colorIdx = colorIdx,
            pieces   = pieces,
        }
    end

    local game = {
        players  = {
            [1] = MakePlayer(1, humanColor),
            [2] = MakePlayer(2, aiColor),
        },
        current  = 1,    -- Mensch beginnt
        humanID  = 1,
        aiID     = 2,
        dice     = 0,
        rolled   = false,
        sixCount = 0,
        phase    = "roll",
        winner   = 0,
    }
    return game
end

-- ============================================================
-- RollDice – würfelt, gibt Wert zurück
-- ============================================================
function L:RollDice(game)
    if game.rolled then return game.dice end
    local val    = math.random(1, 6)
    game.dice    = val
    game.rolled  = true
    game.phase   = "move"
    return val
end

-- ============================================================
-- GetValidMoves – gibt Liste der bewegbaren Figuren zurück
-- Jeder Eintrag: { pieceIdx=n, steps=x }
-- ============================================================
function L:GetValidMoves(game)
    local board   = GetBoard()
    local player  = game.players[game.current]
    local dice    = game.dice
    local moves   = {}

    for i, piece in ipairs(player.pieces) do
        if not piece.finished then
            if piece.relPos == 0 then
                -- In der Basis: nur raus wenn 6 gewürfelt
                if dice == 6 then
                    moves[#moves+1] = { pieceIdx=i, steps=0, action="enter" }
                end
            else
                -- Auf dem Pfad: kann bewegen wenn nicht überschießt
                local newRel = piece.relPos + dice
                if newRel <= 44 then
                    moves[#moves+1] = { pieceIdx=i, steps=dice, action="move" }
                end
            end
        end
    end
    return moves
end

-- ============================================================
-- ApplyMove – führt einen Zug aus
-- Gibt Ergebnis zurück: "moved"|"captured"|"entered"|"finished"|"win"
-- ============================================================
function L:ApplyMove(game, pieceIdx)
    local board   = GetBoard()
    local player  = game.players[game.current]
    local piece   = player.pieces[pieceIdx]
    local dice    = game.dice
    local result  = "moved"

    if piece.relPos == 0 then
        -- Figur raus: auf Einstiegsfeld
        piece.relPos = 1
        piece.gridIdx = board:GetGridIndex(player.colorIdx, 1)
        result = "entered"
    else
        -- Figur bewegen
        piece.relPos = piece.relPos + dice
        piece.gridIdx = board:GetGridIndex(player.colorIdx, piece.relPos)

        if piece.relPos >= 44 then
            piece.relPos  = 45
            piece.finished = true
            piece.gridIdx  = nil
            result = "finished"
        end
    end

    -- Schlag-Prüfung: nur auf Hauptpfad (relPos 1-40)
    if result == "moved" or result == "entered" then
        if piece.relPos <= 40 then
            local captureResult = self:CheckCapture(game, player, piece)
            if captureResult then result = "captured" end
        end
    end

    -- Gewinner prüfen
    if self:CheckWin(game, game.current) then
        game.winner = game.current
        game.phase  = "gameover"
        return "win"
    end

    return result
end

-- ============================================================
-- CheckCapture – prüft ob eine gegnerische Figur geschlagen wird
-- ============================================================
function L:CheckCapture(game, movingPlayer, movedPiece)
    local board = GetBoard()
    -- Sicher-Felder können nicht geschlagen werden
    if board.SAFE_FIELDS[movedPiece.gridIdx] then return false end

    local opponent = game.players[(game.current == 1) and 2 or 1]
    for _, oppPiece in ipairs(opponent.pieces) do
        if not oppPiece.finished and oppPiece.relPos > 0
                and oppPiece.relPos <= 40
                and oppPiece.gridIdx == movedPiece.gridIdx then
            -- Schlagen: Figur zurück in die Basis
            local baseFields = board.BASE_FIELDS[opponent.colorIdx]
            -- Finde freies Basis-Feld
            local usedBases  = {}
            for _, op2 in ipairs(opponent.pieces) do
                if op2.relPos == 0 then
                    usedBases[op2.gridIdx] = true
                end
            end
            for _, bf in ipairs(baseFields) do
                if not usedBases[bf] then
                    oppPiece.relPos  = 0
                    oppPiece.gridIdx = bf
                    break
                end
            end
            return true
        end
    end
    return false
end

-- ============================================================
-- CheckWin
-- ============================================================
function L:CheckWin(game, playerID)
    local player = game.players[playerID]
    for _, piece in ipairs(player.pieces) do
        if not piece.finished then return false end
    end
    return true
end

-- ============================================================
-- NextTurn – wechselt zum nächsten Spieler
-- Bei 6: selber Spieler nochmal (außer bei 3× hintereinander)
-- ============================================================
function L:NextTurn(game, lastResult)
    local got6 = (game.dice == 6)
    local finished = (lastResult == "finished")

    if got6 and game.sixCount < 2 then
        -- Nochmal würfeln
        game.sixCount = game.sixCount + 1
    else
        -- Spieler wechseln
        game.sixCount = 0
        game.current  = (game.current == 1) and 2 or 1
    end

    game.dice   = 0
    game.rolled = false
    game.phase  = "roll"
end

-- ============================================================
-- HasAnyMove – gibt false wenn Spieler gar keinen Zug hat
-- (z.B. nur Figuren in Basis aber keine 6 gewürfelt)
-- ============================================================
function L:HasAnyMove(game)
    return #self:GetValidMoves(game) > 0
end

-- ============================================================
-- AI: PickBestMove – optimale Figur auswählen
-- Priorität: 1) Schlagen, 2) Fertigstellen, 3) Einsetzen,
--            4) Weiteste-vorne Figur
-- ============================================================
function L:AIPickMove(game)
    local moves   = self:GetValidMoves(game)
    if #moves == 0 then return nil end

    local board    = GetBoard()
    local player   = game.players[game.current]
    local opponent = game.players[(game.current == 1) and 2 or 1]

    -- Kandidaten auswerten
    local best = nil
    local bestScore = -999

    for _, move in ipairs(moves) do
        local piece  = player.pieces[move.pieceIdx]
        local score  = 0

        if move.action == "enter" then
            score = 10
        else
            local newRel = piece.relPos + game.dice
            -- Fertigstellen
            if newRel >= 44 then
                score = 100
            else
                local newGrid = board:GetGridIndex(player.colorIdx, newRel)
                -- Schlagen möglich?
                if newRel <= 40 and not board.SAFE_FIELDS[newGrid] then
                    for _, op in ipairs(opponent.pieces) do
                        if not op.finished and op.relPos > 0
                                and op.relPos <= 40
                                and op.gridIdx == newGrid then
                            score = score + 50
                        end
                    end
                end
                -- Bevorzuge Figur die am weitesten vorne ist
                score = score + newRel
            end
        end

        if score > bestScore then
            bestScore = score
            best      = move
        end
    end

    return best
end
