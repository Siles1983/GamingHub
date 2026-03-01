--[[
    Gaming Hub – Mensch ärgere dich nicht (Ludo)
    Games/Ludo/Engine.lua

    Events (LUDO_ Prefix):
      LUDO_GAME_STARTED(game)
      LUDO_DICE_ROLLED(game, value)
      LUDO_PIECE_MOVED(game, playerID, pieceIdx, result)
      LUDO_TURN_CHANGED(game)
      LUDO_NO_MOVE(game)           – Spieler hat keinen gültigen Zug
      LUDO_GAME_WON(game, winnerID)
      LUDO_GAME_STOPPED()

    Renderer direkt aufrufen für zeitkritische Updates.
    Events nur für Zustandsübergänge.
]]

local GamingHub = _G.GamingHub
GamingHub.LUDO_Engine = {}
local E = GamingHub.LUDO_Engine

E.activeGame  = nil
E._running    = false
E.AI_DELAY    = 1.2   -- Sekunden bevor KI würfelt
E.AI_MOVE_DELAY = 0.8 -- Sekunden bevor KI Figur bewegt

-- ============================================================
-- Sound
-- ============================================================
local function PlayLudo(event)
    local S = GamingHub.LUDO_Settings
    if not S or not S:Get("soundEnabled") then return end
    if event == "roll"    and S:Get("soundOnRoll")    then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 774, "SFX")
    elseif event == "move" and S:Get("soundOnMove") then
        PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN or 847, "SFX")
    elseif event == "capture" and S:Get("soundOnCapture") then
        PlaySound(SOUNDKIT.IG_QUEST_ABANDON or 847, "SFX")
    elseif event == "home" and S:Get("soundOnHome") then
        PlaySound(SOUNDKIT.UI_ACHIEVEMENT_TOAST_SPARK or 888, "SFX")
    elseif event == "win" and S:Get("soundOnWin") then
        PlaySound(SOUNDKIT.UI_GARRISON_MISSION_COMPLETE or 888, "SFX")
    end
end

-- ============================================================
-- StartGame
-- ============================================================
function E:StartGame(config)
    self:StopGame()

    local S   = GamingHub.LUDO_Settings
    local cfg = {
        humanColor = (config and config.humanColor) or S:Get("playerColor"),
        theme      = (config and config.theme)      or S:Get("theme"),
    }

    local game    = GamingHub.LUDO_Logic:NewGame(cfg)
    game.theme    = cfg.theme
    self.activeGame = game
    self._running   = true

    local R = GamingHub.LUDO_Renderer
    if R then R:OnGameStarted(game) end
    GamingHub.Engine:Emit("LUDO_GAME_STARTED", game)

    -- Spieler 1 = Mensch, beginnt → warten auf Würfel-Click
    self:StartTurn(game)
end

-- ============================================================
-- StartTurn – beginnt einen neuen Zug
-- ============================================================
function E:StartTurn(game)
    if not self._running then return end
    local R = GamingHub.LUDO_Renderer

    if R then R:OnTurnStart(game) end
    GamingHub.Engine:Emit("LUDO_TURN_CHANGED", game)

    if game.current == game.aiID then
        -- KI-Zug: nach Verzögerung automatisch würfeln
        C_Timer.After(self.AI_DELAY, function()
            if not self._running then return end
            self:DoRoll(game)
        end)
    end
    -- Human-Zug: warten auf HandleRollClick()
end

-- ============================================================
-- HandleRollClick – menschlicher Spieler klickt Würfel
-- ============================================================
function E:HandleRollClick()
    local game = self.activeGame
    if not game or not self._running then return end
    if game.phase ~= "roll" then return end
    if game.current ~= game.humanID then return end
    self:DoRoll(game)
end

-- ============================================================
-- DoRoll – würfelt und reagiert
-- ============================================================
function E:DoRoll(game)
    if not self._running then return end
    local L   = GamingHub.LUDO_Logic
    local R   = GamingHub.LUDO_Renderer
    local val = L:RollDice(game)

    PlayLudo("roll")
    if R then R:OnDiceRolled(game, val) end
    GamingHub.Engine:Emit("LUDO_DICE_ROLLED", game, val)

    -- Prüfen ob Züge möglich
    local moves = L:GetValidMoves(game)
    if #moves == 0 then
        -- Kein Zug möglich
        if R then R:OnNoMove(game) end
        GamingHub.Engine:Emit("LUDO_NO_MOVE", game)
        C_Timer.After(1.0, function()
            if not self._running then return end
            L:NextTurn(game, "nomove")
            self:StartTurn(game)
        end)
        return
    end

    -- KI: automatisch besten Zug wählen
    if game.current == game.aiID then
        C_Timer.After(self.AI_MOVE_DELAY, function()
            if not self._running then return end
            local best = L:AIPickMove(game)
            if best then
                self:DoMove(game, best.pieceIdx)
            end
        end)
    end
    -- Mensch: warten auf HandlePieceClick()
end

-- ============================================================
-- HandlePieceClick – menschlicher Spieler klickt eine Figur
-- ============================================================
function E:HandlePieceClick(pieceIdx)
    local game = self.activeGame
    if not game or not self._running then return end
    if game.phase ~= "move" then return end
    if game.current ~= game.humanID then return end

    -- Prüfen ob diese Figur ziehbar ist
    local L     = GamingHub.LUDO_Logic
    local moves = L:GetValidMoves(game)
    local valid = false
    for _, m in ipairs(moves) do
        if m.pieceIdx == pieceIdx then valid = true; break end
    end
    if not valid then return end

    self:DoMove(game, pieceIdx)
end

-- ============================================================
-- DoMove – führt Zug aus
-- ============================================================
function E:DoMove(game, pieceIdx)
    if not self._running then return end
    local L      = GamingHub.LUDO_Logic
    local R      = GamingHub.LUDO_Renderer
    local result = L:ApplyMove(game, pieceIdx)

    -- Sound
    if result == "captured" then PlayLudo("capture")
    elseif result == "finished" then PlayLudo("home")
    elseif result == "win" then PlayLudo("win")
    else PlayLudo("move") end

    if R then R:OnPieceMoved(game, game.current, pieceIdx, result) end
    GamingHub.Engine:Emit("LUDO_PIECE_MOVED", game, game.current, pieceIdx, result)

    if result == "win" then
        if R then R:OnGameWon(game, game.winner) end
        GamingHub.Engine:Emit("LUDO_GAME_WON", game, game.winner)
        return
    end

    -- Nächster Zug
    C_Timer.After(0.5, function()
        if not self._running then return end
        L:NextTurn(game, result)
        self:StartTurn(game)
    end)
end

-- ============================================================
-- StopGame
-- ============================================================
function E:StopGame()
    self._running   = false
    self.activeGame = nil
    GamingHub.Engine:Emit("LUDO_GAME_STOPPED")
end
