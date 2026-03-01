--[[
    Gaming Hub
    Games/Memory/Engine.lua
    Version: 2.0.0 – Nach Referenz-Addon Muster

    Kernprinzip aus MemoryPairs.lua:
      OnClick → grid[i][j].flipped = true → UpdateUI() → CheckForMatch()

    Unser Äquivalent:
      HandleFlip → FlipCard() → Renderer:UpdateBoard() → CheckMatch mit Delay
]]

local GamingHub = _G.GamingHub
GamingHub.MEM_Engine = {}
local E = GamingHub.MEM_Engine

E.activeGame  = nil
E.timerHandle = nil

local function PlayGameSound(event)
    local S = GamingHub.MEM_Settings
    if not S or not S:Get("soundEnabled") then return end
    if event == "flip"     and S:Get("soundOnFlip")     then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 774, "SFX") end
    if event == "match"    and S:Get("soundOnMatch")    then PlaySound(SOUNDKIT.UI_ACHIEVEMENT_TOAST_SPARK or 888, "SFX") end
    if event == "mismatch" and S:Get("soundOnMismatch") then PlaySound(SOUNDKIT.IG_QUEST_ABANDON or 847, "SFX") end
    if event == "win"      and S:Get("soundOnWin")      then PlaySound(SOUNDKIT.UI_GARRISON_MISSION_COMPLETE or 888, "SFX") end
    if event == "lose"     and S:Get("soundOnLose")     then PlaySound(SOUNDKIT.IG_QUEST_ABANDON or 847, "SFX") end
end

function E:StartGame(config)
    self:StopTimer()
    local S   = GamingHub.MEM_Settings
    local cfg = {
        difficulty  = (config and config.difficulty) or (S and S:Get("difficulty")) or "easy",
        theme       = (config and config.theme)       or (S and S:Get("theme"))      or "classes",
        timerActive = (config and config.timerActive ~= nil) and config.timerActive
                      or (S and S:Get("timerActive")) or false,
    }
    local instance = GamingHub.MEM_Game:New()
    instance:Init(cfg)
    self.activeGame = instance
    GamingHub.Engine:Emit("MEM_GAME_STARTED", instance:GetBoardState())
    if cfg.timerActive then self:StartTimer() end
end

-- ============================================================
-- HandleFlip – direkt nach Referenz-Muster
--   1. Guard-Checks
--   2. FlipCard()
--   3. Renderer:UpdateBoard() – SOFORT, synchron
--   4. Bei 2 Karten: mit Delay CheckMatch
-- ============================================================
function E:HandleFlip(idx)
    if not self.activeGame then return end
    if self.activeGame:IsBlocked() then return end

    local result = self.activeGame:FlipCard(idx)
    if result ~= "flipped" then return end

    PlayGameSound("flip")

    -- SOFORTIGES Update des Renderers (wie UpdateUI() im Referenz-Addon)
    -- Direkt synchron, kein Event, kein Delay – garantiertes Rendering
    local Renderer = GamingHub.MEM_Renderer
    if Renderer then Renderer:UpdateBoard() end

    -- Zweite Karte? → blockieren, dann prüfen
    local board = self.activeGame.board
    if #board.flippedIdx == 2 then
        local i1, i2 = board.flippedIdx[1], board.flippedIdx[2]
        self.activeGame:SetBlocked(true)

        -- Delay damit Spieler beide Karten sieht (wie C_Timer.After(1) im Referenz-Addon)
        C_Timer.After(0.8, function()
            if not self.activeGame then return end

            local matchResult = self.activeGame:CheckMatch()

            if matchResult == "match" then
                PlayGameSound("match")
                self.activeGame:SetBlocked(false)
                if Renderer then Renderer:UpdateBoard() end

                local board2 = self.activeGame.board
                if board2.phase == "WON" then
                    self:StopTimer()
                    PlayGameSound("win")
                    GamingHub.Engine:Emit("MEM_GAME_WON", self.activeGame:GetBoardState())
                end

            else -- no_match
                -- Roter Flash
                if Renderer then Renderer:FlashMismatch(i1, i2) end

                C_Timer.After(0.6, function()
                    if not self.activeGame then return end
                    self.activeGame:ResetFlipped()
                    PlayGameSound("mismatch")
                    self.activeGame:SetBlocked(false)
                    if Renderer then Renderer:UpdateBoard() end
                end)
            end
        end)
    end
end

function E:StartTimer()
    self:StopTimer()
    local function tick()
        if not self.activeGame then return end
        local result = self.activeGame:TickTimer(1)
        local state  = self.activeGame:GetBoardState()
        GamingHub.Engine:Emit("MEM_TIMER_TICK", state)
        if result == "expired" then
            self:StopTimer()
            PlayGameSound("lose")
            GamingHub.Engine:Emit("MEM_GAME_LOST", state)
        else
            self.timerHandle = C_Timer.After(1, tick)
        end
    end
    self.timerHandle = C_Timer.After(1, tick)
end

function E:StopTimer()
    self.timerHandle = nil
end

function E:StopGame()
    self:StopTimer()
    self.activeGame = nil
    GamingHub.Engine:Emit("MEM_GAME_STOPPED")
end
