--[[
    Gaming Hub
    Games/Minesweeper/Engine.lua
    Version: 1.0.0

    Events (MS_ Prefix):
      MS_GAME_STARTED(state)
      MS_CELL_REVEALED(state, result)   – "empty"|"number"
      MS_FLAG_TOGGLED(state, result)    – "flagged"|"unflagged"
      MS_GAME_WON(state)
      MS_GAME_LOST(state)
      MS_GAME_STOPPED
]]

local GamingHub = _G.GamingHub
GamingHub.MS_Engine = {}
local E = GamingHub.MS_Engine

E.activeGame = nil

-- ============================================================
-- Sounds
-- ============================================================
local function PlayGameSound(event)
    local S = GamingHub.MS_Settings
    if not S or not S:Get("soundEnabled") then return end

    if event == "reveal" and S:Get("soundOnReveal") then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
    elseif event == "flag" and S:Get("soundOnFlag") then
        PlaySound(SOUNDKIT.PUT_DOWN_WOOD_TYPE_1 or 3175, "SFX")
    elseif event == "explode" and S:Get("soundOnExplode") then
        -- Goblin-Explosion: mehrere Fallbacks
        local explosionSound = SOUNDKIT.IG_SPELL_GOBLIN_BOMB_EXPLOSION
            or SOUNDKIT.MONSTER_UNIT_CANISTERS_EXPLODE_SMALL
            or 3789
        PlaySound(explosionSound, "SFX")
    elseif event == "win" and S:Get("soundOnWin") then
        PlaySound(SOUNDKIT.UI_GARRISON_MISSION_COMPLETE or 888, "SFX")
    end
end

-- ============================================================
-- StartGame
-- ============================================================
function E:StartGame(config)
    local S   = GamingHub.MS_Settings
    local cfg = {
        difficulty = (config and config.difficulty)
            or (S and S:Get("difficulty"))
            or "easy",
    }

    local instance = GamingHub.MS_Game:New()
    instance:Init(cfg)
    self.activeGame = instance

    GamingHub.Engine:Emit("MS_GAME_STARTED", instance:GetBoardState())
end

-- ============================================================
-- HandleReveal – Linksklick
-- ============================================================
function E:HandleReveal(r, c)
    if not self.activeGame then return end

    local result = self.activeGame:RevealCell(r, c)
    local state  = self.activeGame:GetBoardState()

    if result == "mine" then
        PlayGameSound("explode")
        GamingHub.Engine:Emit("MS_GAME_LOST", state)
    elseif result == "won" then
        PlayGameSound("win")
        GamingHub.Engine:Emit("MS_GAME_WON", state)
    elseif result == "empty" or result == "number" then
        PlayGameSound("reveal")
        GamingHub.Engine:Emit("MS_CELL_REVEALED", state, result)
    end
    -- "already_revealed", "flagged", "game_over" → nichts
end

-- ============================================================
-- HandleFlag – Rechtsklick
-- ============================================================
function E:HandleFlag(r, c)
    if not self.activeGame then return end

    local result = self.activeGame:ToggleFlag(r, c)
    local state  = self.activeGame:GetBoardState()

    if result == "flagged" or result == "unflagged" then
        PlayGameSound("flag")
        GamingHub.Engine:Emit("MS_FLAG_TOGGLED", state, result)
    end
end

-- ============================================================
-- StopGame
-- ============================================================
function E:StopGame()
    self.activeGame = nil
    GamingHub.Engine:Emit("MS_GAME_STOPPED")
end
