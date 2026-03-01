--[[
    Gaming Hub – Simon Says
    Games/SimonSays/Engine.lua

    Events (SS_ Prefix):
      SS_GAME_STARTED(board)
      SS_SEQUENCE_SHOW(board, seqStep)   – welcher Schritt gerade leuchtet (1-basiert)
      SS_SEQUENCE_DONE(board)            – Sequenz fertig, Spieler ist dran
      SS_INPUT_CORRECT(board)            – Spieler hat richtig geklickt
      SS_INPUT_WRONG(board, symIdx)      – falsches Symbol
      SS_ROUND_COMPLETE(board)           – Runde geschafft → nächste startet
      SS_GAME_STOPPED()

    Renderer direkt aufrufen für zeitkritische Darstellung (Glow/Flash).
    Events nur für Zustandsübergänge.
]]

local GamingHub = _G.GamingHub
GamingHub.SS_Engine = {}
local E = GamingHub.SS_Engine

E.activeGame  = nil
E._timers     = {}   -- aktive C_Timer-Handles (zum Abbrechen)
E._inputBlock = false

-- ============================================================
-- Sound
-- ============================================================
local function PlaySS(event)
    local S = GamingHub.SS_Settings
    if not S or not S:Get("soundEnabled") then return end
    -- Nur Fallback-IDs nutzen die sicher in WotLK/Midnight existieren
    if event == "flash" and S:Get("soundOnFlash") then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 774, "SFX")
    elseif event == "input" and S:Get("soundOnInput") then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 774, "SFX")
    elseif event == "win" and S:Get("soundOnWin") then
        PlaySound(SOUNDKIT.UI_GARRISON_MISSION_COMPLETE or 888, "SFX")
    elseif event == "lose" and S:Get("soundOnLose") then
        PlaySound(SOUNDKIT.IG_QUEST_ABANDON or 847, "SFX")
    end
end

-- ============================================================
-- CancelTimers – bricht alle laufenden Sequenz-Timer ab
-- ============================================================
function E:CancelTimers()
    -- C_Timer.After-Handles können nicht direkt gecancelt werden in WotLK-API
    -- Wir nutzen ein Flag: _running. Callbacks prüfen es.
    self._running = false
end

-- ============================================================
-- StartGame
-- ============================================================
function E:StartGame(config)
    self:CancelTimers()
    self._inputBlock = true

    local S = GamingHub.SS_Settings
    local cfg = {
        difficulty = (config and config.difficulty) or S:Get("difficulty"),
        theme      = (config and config.theme)      or S:Get("theme"),
    }

    local board    = GamingHub.SS_Logic:NewBoard(cfg)
    self.activeGame = { board = board }
    self._running   = true

    GamingHub.Engine:Emit("SS_GAME_STARTED", board)

    -- Kurze Pause, dann erste Runde starten
    C_Timer.After(0.6, function()
        if not self._running then return end
        self:StartNextRound()
    end)
end

-- ============================================================
-- StartNextRound – verlängert Sequenz, spielt sie ab
-- ============================================================
function E:StartNextRound()
    if not self.activeGame or not self._running then return end
    self._inputBlock = true

    local board = self.activeGame.board
    GamingHub.SS_Logic:NextRound(board)

    -- Renderer informieren (Runde aktualisieren)
    local R = GamingHub.SS_Renderer
    if R then R:OnNewRound(board) end

    -- Sequenz schrittweise abspielen
    self:PlaySequence(board, 1)
end

-- ============================================================
-- PlaySequence – rekursive Sequenz-Anzeige
-- ============================================================
function E:PlaySequence(board, step)
    if not self._running then return end
    if step > board.round then
        -- Alle Schritte gezeigt → Spieler ist dran
        GamingHub.SS_Logic:SetInputPhase(board)
        self._inputBlock = false
        local R = GamingHub.SS_Renderer
        if R then R:OnSequenceDone(board) end
        GamingHub.Engine:Emit("SS_SEQUENCE_DONE", board)
        return
    end

    local symIdx  = board.sequence[step]
    local flashOn = board.speed * 0.55   -- Zeit AN
    local flashOff= board.speed * 0.45  -- Zeit AUS (Pause zwischen Symbolen)

    -- Symbol aufleuchten lassen
    local R = GamingHub.SS_Renderer
    if R then R:FlashSymbol(symIdx, true) end
    GamingHub.Engine:Emit("SS_SEQUENCE_SHOW", board, step)
    PlaySS("flash")

    C_Timer.After(flashOn, function()
        if not self._running then return end
        -- Symbol ausschalten
        if R then R:FlashSymbol(symIdx, false) end

        C_Timer.After(flashOff, function()
            if not self._running then return end
            -- Nächster Schritt
            self:PlaySequence(board, step + 1)
        end)
    end)
end

-- ============================================================
-- HandleInput – Spieler klickt auf Symbol
-- ============================================================
function E:HandleInput(symIdx)
    if not self.activeGame or self._inputBlock then return end
    local board = self.activeGame.board

    local R = GamingHub.SS_Renderer

    -- Kurzes Aufleuchten als Feedback
    if R then R:FlashSymbol(symIdx, true) end
    C_Timer.After(0.18, function()
        if R then R:FlashSymbol(symIdx, false) end
    end)

    local result = GamingHub.SS_Logic:HandleInput(board, symIdx)

    if result == "wrong" then
        PlaySS("lose")
        self._inputBlock = true
        self._running    = false
        if R then R:OnGameLost(board) end
        GamingHub.Engine:Emit("SS_INPUT_WRONG", board, symIdx)

    elseif result == "correct" then
        PlaySS("input")
        if R then R:OnInputCorrect(board) end
        GamingHub.Engine:Emit("SS_INPUT_CORRECT", board)

    elseif result == "round_complete" then
        PlaySS("win")
        self._inputBlock = true
        if R then R:OnRoundComplete(board) end
        GamingHub.Engine:Emit("SS_ROUND_COMPLETE", board)
        -- Kurze Pause, dann nächste Runde
        C_Timer.After(1.2, function()
            if not self._running then return end
            self:StartNextRound()
        end)
    end
end

-- ============================================================
-- StopGame
-- ============================================================
function E:StopGame()
    self:CancelTimers()
    self.activeGame  = nil
    self._inputBlock = true
    GamingHub.Engine:Emit("SS_GAME_STOPPED")
end
