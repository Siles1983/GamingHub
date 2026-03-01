--[[
    Gaming Hub
    Games/Battleship/Settings.lua
    Version: 1.0.0

    Namespace: GamingHub.BS_Settings
    DB-Key:    "Battleship"
]]

local GamingHub = _G.GamingHub
GamingHub.BS_Settings = {}
local S = GamingHub.BS_Settings

S.Defaults = {
    gridSize     = 10,       -- 8 | 10 | 12
    aiDifficulty = "easy",   -- "easy" | "normal" | "hard"
    soundEnabled = true,
    soundOnWin   = true,
    soundOnLoss  = true,
    soundOnHit   = true,
    soundOnSunk  = true,
}

local DB_KEY = "Battleship"

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
        db["soundOnWin"]  = false
        db["soundOnLoss"] = false
        db["soundOnHit"]  = false
        db["soundOnSunk"] = false
    end
    if (changedKey == "soundOnWin" or changedKey == "soundOnLoss" or
        changedKey == "soundOnHit" or changedKey == "soundOnSunk")
        and db[changedKey] == true then
        db["soundEnabled"] = true
    end
end
