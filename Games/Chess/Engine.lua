--[[
    Gaming Hub
    Games/Chess/Engine.lua
    Version: 1.0.0

    Events (CHE_ Prefix):
      CHE_GAME_STARTED(state)
      CHE_PIECE_SELECTED(state)     – Figur ausgewählt, Felder grün
      CHE_PIECE_DESELECTED(state)   – Auswahl aufgehoben
      CHE_MOVE_MADE(state, result)  – Zug ausgeführt
      CHE_AI_MOVE(state, result)    – KI-Zug ausgeführt
      CHE_GAME_OVER(state)          – Schachmatt / Patt / Aufgabe
      CHE_GAME_STOPPED
]]

local GamingHub = _G.GamingHub
GamingHub.Chess_Engine = {}
local E = GamingHub.Chess_Engine

E.activeGame    = nil
E.aiPending     = false   -- verhindert doppelte KI-Züge

-- ============================================================
-- Sound
-- ============================================================

local SOUNDS = {
    move     = 1115,
    capture  = 8959,
    check    = 847,
    win      = 888,
    loss     = 847,
}

local function PlayGameSound(event)
    local S = GamingHub.Chess_Settings
    if not S or not S:Get("soundEnabled") then return end
    local id = SOUNDS[event]
    if id then PlaySound(id, "SFX") end
end

-- ============================================================
-- StartGame
-- ============================================================

function E:StartGame(config)
    self.aiPending = false
    local S   = GamingHub.Chess_Settings
    local cfg = {
        difficulty = (config and config.difficulty)
            or (S and S:Get("difficulty"))
            or "easy",
    }

    local instance = GamingHub.Chess_Game:New()
    instance:Init(cfg)
    self.activeGame = instance

    GamingHub.Engine:Emit("CHE_GAME_STARTED", instance:GetBoardState())
end

-- ============================================================
-- HandleCellClick – Spieler klickt ein Feld
-- ============================================================

function E:HandleCellClick(r, c)
    if not self.activeGame then return end
    if self.aiPending then return end  -- KI ist am Zug

    local game  = self.activeGame
    local state = game:GetBoardState()

    if state.phase ~= "PLAYING" then return end

    -- Hat der Spieler bereits eine Figur ausgewählt?
    if state.selected then
        -- Versuche Zug
        local result = game:MoveSelected(r, c)
        local newState = game:GetBoardState()

        if result == "moved" or result == "captured" or result == "check" then
            PlayGameSound(result == "captured" and "capture" or "move")
            GamingHub.Engine:Emit("CHE_MOVE_MADE", newState, result)
            -- KI-Zug verzögert starten
            self:ScheduleAIMove()

        elseif result == "checkmate" or result == "stalemate" then
            PlayGameSound("win")
            GamingHub.Engine:Emit("CHE_MOVE_MADE", newState, result)
            GamingHub.Engine:Emit("CHE_GAME_OVER", newState)

        elseif result == "selected" then
            -- Andere eigene Figur ausgewählt
            GamingHub.Engine:Emit("CHE_PIECE_SELECTED", newState)

        else
            -- Ungültig → Auswahl aufheben
            GamingHub.Engine:Emit("CHE_PIECE_DESELECTED", newState)
        end
    else
        -- Figur auswählen
        local result = game:SelectPiece(r, c)
        local newState = game:GetBoardState()

        if result == "selected" then
            GamingHub.Engine:Emit("CHE_PIECE_SELECTED", newState)
        elseif result == "deselected" then
            GamingHub.Engine:Emit("CHE_PIECE_DESELECTED", newState)
        end
        -- "invalid" → nichts emittieren
    end
end

-- ============================================================
-- ScheduleAIMove – KI-Zug mit kurzer Verzögerung (0.4s)
-- ============================================================

function E:ScheduleAIMove()
    if not self.activeGame then return end
    if self.aiPending then return end
    self.aiPending = true

    C_Timer.After(0.4, function()
        if not self.activeGame then
            self.aiPending = false
            return
        end
        local result   = self.activeGame:DoAIMove()
        self.aiPending = false
        local newState = self.activeGame:GetBoardState()

        if result == "checkmate" or result == "stalemate" then
            PlayGameSound("loss")
            GamingHub.Engine:Emit("CHE_AI_MOVE", newState, result)
            GamingHub.Engine:Emit("CHE_GAME_OVER", newState)
        elseif result == "check" then
            PlayGameSound("check")
            GamingHub.Engine:Emit("CHE_AI_MOVE", newState, result)
        elseif result == "captured" then
            PlayGameSound("capture")
            GamingHub.Engine:Emit("CHE_AI_MOVE", newState, result)
        else
            PlayGameSound("move")
            GamingHub.Engine:Emit("CHE_AI_MOVE", newState, result)
        end
    end)
end

-- ============================================================
-- Resign
-- ============================================================

function E:HandleResign()
    if not self.activeGame then return end
    self.aiPending = false
    self.activeGame:Resign()
    local state = self.activeGame:GetBoardState()
    GamingHub.Engine:Emit("CHE_GAME_OVER", state)
end

-- ============================================================
-- StopGame
-- ============================================================

function E:StopGame()
    self.aiPending  = false
    self.activeGame = nil
    GamingHub.Engine:Emit("CHE_GAME_STOPPED")
end
