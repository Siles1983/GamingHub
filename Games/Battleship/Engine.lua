--[[
    Gaming Hub
    Games/Battleship/Engine.lua
    Version: 1.0.0

    Events (BS_ Prefix):
      BS_GAME_STARTED(state)
      BS_PLACEMENT_UPDATED(state)   – nach jedem platzierten Schiff
      BS_BATTLE_STARTED(state)      – alle Schiffe platziert, Kampf beginnt
      BS_SHOT_FIRED(state)          – nach Spieler-Schuss (inkl. KI-Antwort)
      BS_GAME_OVER(result)
      BS_GAME_STOPPED
]]

local GamingHub = _G.GamingHub
GamingHub.BS_Engine = {}
local E = GamingHub.BS_Engine

E.activeGame = nil

-- ============================================================
-- Sound
-- ============================================================

local function PlayGameSound(event)
    local S = GamingHub.BS_Settings
    if not S or not S:Get("soundEnabled") then return end
    if event == "WIN"  and S:Get("soundOnWin")  then PlaySound(888, "SFX") end
    if event == "LOSS" and S:Get("soundOnLoss") then PlaySound(847, "SFX") end
    if event == "HIT"  and S:Get("soundOnHit")  then PlaySound(15282, "SFX") end  -- Canonball hit
    if event == "SUNK" and S:Get("soundOnSunk") then PlaySound(8959,  "SFX") end  -- Explosion
end

-- ============================================================
-- StartGame
-- ============================================================

function E:StartGame(config)
    local gameClass = GamingHub.BS_Game
    if not gameClass then
        print("GamingHub: BS_Game nicht registriert.")
        return
    end

    local S   = GamingHub.BS_Settings
    local cfg = {
        size         = (config and config.size)         or (S and S:Get("gridSize"))     or 10,
        aiDifficulty = (config and config.aiDifficulty) or (S and S:Get("aiDifficulty")) or "easy",
    }

    local instance = gameClass:New()
    instance:Init(cfg)
    self.activeGame = instance

    GamingHub.Engine:Emit("BS_GAME_STARTED", instance:GetBoardState())
end

-- ============================================================
-- HandlePlacement – Spieler klickt Feld in Placement-Phase
-- ============================================================

function E:HandlePlacement(r, c)
    if not self.activeGame then return end

    local success = self.activeGame:PlaceShip(r, c)
    if not success then return end

    local state = self.activeGame:GetBoardState()

    if state.phase == "BATTLE" then
        GamingHub.Engine:Emit("BS_BATTLE_STARTED", state)
    else
        GamingHub.Engine:Emit("BS_PLACEMENT_UPDATED", state)
    end
end

-- ============================================================
-- HandleRandomPlacement
-- ============================================================

function E:HandleRandomPlacement()
    if not self.activeGame then return end

    self.activeGame:PlaceAllRandom()

    local state = self.activeGame:GetBoardState()
    GamingHub.Engine:Emit("BS_BATTLE_STARTED", state)
end

-- ============================================================
-- ToggleOrientation – R-Taste
-- ============================================================

function E:ToggleOrientation()
    if not self.activeGame then return end
    self.activeGame:ToggleOrientation()
    GamingHub.Engine:Emit("BS_PLACEMENT_UPDATED", self.activeGame:GetBoardState())
end

-- ============================================================
-- HandleShot – Spieler schießt auf KI-Board
-- ============================================================

function E:HandleShot(r, c)
    if not self.activeGame then return end

    local before = self.activeGame:GetBoardState()
    if before.phase ~= "BATTLE" or before.gameOver then return end

    self.activeGame:HandleShot(r, c)

    local state = self.activeGame:GetBoardState()
    if not state.lastShot then return  end  -- already_shot oder invalid

    -- Sound für Spieler-Schuss
    local shotResult = state.lastShot.result
    if shotResult == "SUNK" then
        PlayGameSound("SUNK")
    elseif shotResult == "HIT" then
        PlayGameSound("HIT")
    end

    GamingHub.Engine:Emit("BS_SHOT_FIRED", state)

    if state.gameOver then
        PlayGameSound(state.result)
        GamingHub.Engine:Emit("BS_GAME_OVER", state.result)
    end
end

-- ============================================================
-- StopGame
-- ============================================================

function E:StopGame()
    if not self.activeGame then return end
    self.activeGame = nil
    GamingHub.Engine:Emit("BS_GAME_STOPPED")
end
