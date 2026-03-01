--[[
    Gaming Hub – Mastermind: Azeroth Edition
    Games/Mastermind/Engine.lua

    Events (MM_ Prefix):
      MM_GAME_STARTED(state)
      MM_SLOT_SET(state, slotIdx)        – Symbol in Slot gesetzt
      MM_SLOT_CLEARED(state, slotIdx)    – Slot geleert
      MM_GUESS_SUBMITTED(state, result)  – Versuch geprüft: result = "won"|"lost"|"continue"
      MM_GAME_WON(state)
      MM_GAME_LOST(state)
      MM_GAME_STOPPED
]]

local GamingHub = _G.GamingHub
GamingHub.MM_Engine = {}
local E = GamingHub.MM_Engine

E.activeGame = nil

-- ============================================================
-- Sounds
-- ============================================================
local function PlayGameSound(event)
    local S = GamingHub.MM_Settings
    if not S or not S:Get("soundEnabled") then return end
    if event == "place"  and S:Get("soundOnPlace")  then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 774, "SFX") end
    if event == "submit" and S:Get("soundOnSubmit") then PlaySound(SOUNDKIT.IG_ABILITY_ICONUPDATE or 857, "SFX") end
    if event == "win"    and S:Get("soundOnWin")    then PlaySound(SOUNDKIT.UI_GARRISON_MISSION_COMPLETE or 888, "SFX") end
    if event == "lose"   and S:Get("soundOnLose")   then PlaySound(SOUNDKIT.IG_QUEST_ABANDON or 847, "SFX") end
end

-- ============================================================
-- StartGame
-- ============================================================
function E:StartGame(config)
    local S   = GamingHub.MM_Settings
    local cfg = {
        difficulty  = (config and config.difficulty)  or S:Get("difficulty"),
        theme       = (config and config.theme)        or S:Get("theme"),
        codeLength  = (config and config.codeLength)   or S:Get("codeLength"),
        duplicates  = (config and config.duplicates ~= nil) and config.duplicates or S:Get("duplicates"),
    }
    local instance = GamingHub.MM_Game:New()
    instance:Init(cfg)
    self.activeGame = instance
    GamingHub.Engine:Emit("MM_GAME_STARTED", instance:GetBoardState())
end

-- ============================================================
-- HandleSetSlot – Spieler klickt Symbol für Slot
-- ============================================================
function E:HandleSetSlot(slotIdx, symbolIdx)
    if not self.activeGame then return end
    local result = self.activeGame:SetSlot(slotIdx, symbolIdx)
    if result == "ok" then
        PlayGameSound("place")
        -- Direkt Renderer updaten (wie Memory-Muster)
        local R = GamingHub.MM_Renderer
        if R then R:UpdateInputRow() end
    end
end

-- ============================================================
-- HandleClearSlot – Rechtsklick auf Slot leert ihn
-- ============================================================
function E:HandleClearSlot(slotIdx)
    if not self.activeGame then return end
    self.activeGame:ClearSlot(slotIdx)
    local R = GamingHub.MM_Renderer
    if R then R:UpdateInputRow() end
end

-- ============================================================
-- HandleSubmit – "Prüfen"-Button
-- ============================================================
function E:HandleSubmit()
    if not self.activeGame then return end
    if not self.activeGame:IsGuessComplete() then
        -- Visuelles Feedback: unvollständige Slots blinken lassen
        local R = GamingHub.MM_Renderer
        if R then R:FlashIncomplete() end
        return
    end

    PlayGameSound("submit")
    local result = self.activeGame:SubmitGuess()
    local state  = self.activeGame:GetBoardState()

    -- Renderer sofort updaten
    local R = GamingHub.MM_Renderer
    if R then R:UpdateBoard() end

    if result == "won" then
        PlayGameSound("win")
        GamingHub.Engine:Emit("MM_GAME_WON", state)
    elseif result == "lost" then
        PlayGameSound("lose")
        GamingHub.Engine:Emit("MM_GAME_LOST", state)
    end
    -- "continue": Renderer zeigt neue leere Eingabezeile
end

-- ============================================================
-- StopGame
-- ============================================================
function E:StopGame()
    self.activeGame = nil
    GamingHub.Engine:Emit("MM_GAME_STOPPED")
end
