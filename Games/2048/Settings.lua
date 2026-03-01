--[[
    Gaming Hub
    Games/2048/Settings.lua
    Version: 1.1.0

    Namespace: GamingHub.TDG_Settings
    DB-Key:    "2048"

    Einstellungen:
      Sound:  soundEnabled, soundOnLoss
      Thema:  colorTheme  ("CLASSIC"|"HORDE"|"ALLIANCE"|"NIGHTELF"|"GOBLIN")
      Brett:  boardSize   (3|4|5) – gespeichert vom Spielfeld-Button
]]

local GamingHub = _G.GamingHub
GamingHub.TDG_Settings = {}
local S = GamingHub.TDG_Settings

-- ============================================================
-- Defaults
-- ============================================================

S.Defaults = {
    -- Sound
    soundEnabled = true,
    soundOnLoss  = true,

    -- Thema
    colorTheme   = "CLASSIC",

    -- Brett-Größe (gespeichert für Buttons-Wiederherstellung, nicht Dropdown)
    boardSize    = 4,
}

local DB_KEY = "2048"

local function EnsureDB()
    if not _G.GamingHubDB then _G.GamingHubDB = {} end
    if not _G.GamingHubDB[DB_KEY] then _G.GamingHubDB[DB_KEY] = {} end
    return _G.GamingHubDB[DB_KEY]
end

function S:Get(key)
    local db = EnsureDB()
    if db[key] ~= nil then return db[key] end
    return self.Defaults[key]
end

function S:Set(key, value)
    EnsureDB()[key] = value
    self:_EnforceRules(key)
end

function S:Reset()
    local db = EnsureDB()
    for k in pairs(self.Defaults) do db[k] = nil end
end

function S:GetAll()
    local result = {}
    for k in pairs(self.Defaults) do result[k] = self:Get(k) end
    return result
end

function S:_EnforceRules(changedKey)
    local db = EnsureDB()
    if changedKey == "soundEnabled" and db["soundEnabled"] == false then
        db["soundOnLoss"] = false
    end
    if changedKey == "soundOnLoss" and db["soundOnLoss"] == true then
        db["soundEnabled"] = true
    end
end
