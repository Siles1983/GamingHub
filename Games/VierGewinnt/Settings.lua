--[[
    Gaming Hub
    Games/VierGewinnt/Settings.lua
    Version: 1.0.0

    Identische Struktur wie TicTacToe/Settings.lua.
    Namespace: GamingHub.VierGewinntSettings
    SavedVariable-Key: "VierGewinnt"
]]

local GamingHub = _G.GamingHub
GamingHub.VierGewinntSettings = {}

local S = GamingHub.VierGewinntSettings

-- ============================================================
-- Defaults
-- ============================================================

S.Defaults = {
    -- Symbole
    symbolMode       = "STANDARD",  -- "STANDARD" | "FACTION"
    symbolAutoDetect = false,
    player1Symbol    = "",           -- "ALLIANCE" | "HORDE" | ""

    -- Hintergrund
    backgroundMode   = "NEUTRAL",   -- "NEUTRAL" | "FACTION" | "CLASS" | "RACE"
    backgroundFactionAuto = true,
    backgroundFaction     = "",
    backgroundClassAuto   = true,
    backgroundClass       = "",
    backgroundRaceAuto    = true,
    backgroundRace        = "",

    -- Sound
    soundEnabled = true,
    soundOnWin   = true,
    soundOnLoss  = true,
    soundOnDraw  = true,
}

-- ============================================================
-- DB-Zugriff
-- ============================================================

local DB_KEY = "VierGewinnt"

local function EnsureDB()
    if not _G.GamingHubDB then
        _G.GamingHubDB = {}
    end
    if not _G.GamingHubDB[DB_KEY] then
        _G.GamingHubDB[DB_KEY] = {}
    end
    return _G.GamingHubDB[DB_KEY]
end

-- ============================================================
-- PUBLIC API: Get / Set / Reset
-- ============================================================

function S:Get(key)
    local db = EnsureDB()
    if db[key] ~= nil then
        return db[key]
    end
    return self.Defaults[key]
end

function S:Set(key, value)
    local db = EnsureDB()
    db[key]  = value
    self:_EnforceRules(key)
end

function S:Reset()
    local db = EnsureDB()
    for k, _ in pairs(self.Defaults) do
        db[k] = nil
    end
end

function S:GetAll()
    local result = {}
    for k, _ in pairs(self.Defaults) do
        result[k] = self:Get(k)
    end
    return result
end

-- ============================================================
-- AUSSCHLUSS-REGELN (identisch zu TicTacToe)
-- ============================================================

function S:_EnforceRules(changedKey)
    local db = EnsureDB()

    -- Auto-Flags löschen manuellen Wert
    if changedKey == "backgroundFactionAuto" and db["backgroundFactionAuto"] == true then
        db["backgroundFaction"] = ""
    end
    if changedKey == "backgroundClassAuto" and db["backgroundClassAuto"] == true then
        db["backgroundClass"] = ""
    end
    if changedKey == "backgroundRaceAuto" and db["backgroundRaceAuto"] == true then
        db["backgroundRace"] = ""
    end

    -- backgroundMode NEUTRAL → alles zurücksetzen
    if changedKey == "backgroundMode" and db["backgroundMode"] == "NEUTRAL" then
        db["backgroundFactionAuto"] = true
        db["backgroundFaction"]     = ""
        db["backgroundClassAuto"]   = true
        db["backgroundClass"]       = ""
        db["backgroundRaceAuto"]    = true
        db["backgroundRace"]        = ""
    end

    -- symbolAutoDetect → symbolMode auf FACTION setzen
    if changedKey == "symbolAutoDetect" and db["symbolAutoDetect"] == true then
        db["symbolMode"]    = "FACTION"
        db["player1Symbol"] = ""
    end

    -- Sounds: Master aus → alle Einzel-Sounds aus
    if changedKey == "soundEnabled" and db["soundEnabled"] == false then
        db["soundOnWin"]  = false
        db["soundOnLoss"] = false
        db["soundOnDraw"] = false
    end

    -- Einzel-Sound ein → Master muss an sein
    if (changedKey == "soundOnWin" or changedKey == "soundOnLoss" or changedKey == "soundOnDraw")
        and db[changedKey] == true then
        db["soundEnabled"] = true
    end
end
