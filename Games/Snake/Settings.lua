--[[
    Gaming Hub – Snake
    Games/Snake/Settings.lua
]]

local GamingHub = _G.GamingHub
GamingHub.SNK_Settings = {}
local S = GamingHub.SNK_Settings

S.Defaults = {
    difficulty      = "easy",
    theme           = "jormungar",
    soundEnabled    = true,
    soundOnEat      = true,
    soundOnDie      = true,
    soundOnStart    = true,
    -- Highscores pro Schwierigkeit
    highscoreEasy   = 0,
    highscoreNormal = 0,
    highscoreHard   = 0,
}

local DB_KEY = "Snake"

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

function S:Set(key, value) EnsureDB()[key] = value end

function S:GetHighscore(diff)
    local key = "highscore" .. (diff:sub(1,1):upper() .. diff:sub(2))
    return self:Get(key)
end

function S:SetHighscore(diff, score)
    local key = "highscore" .. (diff:sub(1,1):upper() .. diff:sub(2))
    if score > self:GetHighscore(diff) then
        self:Set(key, score)
        return true  -- neuer Rekord
    end
    return false
end

function S:Reset()
    local db = EnsureDB()
    -- Nur Settings zurücksetzen, Highscores behalten
    db.difficulty   = nil
    db.theme        = nil
    db.soundEnabled = nil
    db.soundOnEat   = nil
    db.soundOnDie   = nil
    db.soundOnStart = nil
end

function S:GetAll()
    local r = {}
    for k in pairs(self.Defaults) do r[k] = self:Get(k) end
    return r
end
