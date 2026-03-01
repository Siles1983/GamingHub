-- Whack-a-Mole – Games/WhackAMole/Settings.lua

GamingHub = GamingHub or {}
GamingHub.WAM_Settings = {}
local S = GamingHub.WAM_Settings

local DEFAULTS = { sound = true }

function S:Get(key)
    if not GamingHubDB or not GamingHubDB.WhackAMole then return DEFAULTS[key] end
    local v = GamingHubDB.WhackAMole[key]
    if v == nil then return DEFAULTS[key] end
    return v
end

function S:Set(key, value)
    GamingHubDB = GamingHubDB or {}
    GamingHubDB.WhackAMole = GamingHubDB.WhackAMole or {}
    GamingHubDB.WhackAMole[key] = value
end

function S:_getCharKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

function S:GetHighscores(difficulty)
    GamingHubDB = GamingHubDB or {}
    GamingHubDB.WhackAMole = GamingHubDB.WhackAMole or {}
    GamingHubDB.WhackAMole.Highscores = GamingHubDB.WhackAMole.Highscores or {}
    local ck = self:_getCharKey()
    GamingHubDB.WhackAMole.Highscores[ck] = GamingHubDB.WhackAMole.Highscores[ck] or {}
    GamingHubDB.WhackAMole.Highscores[ck][difficulty] = GamingHubDB.WhackAMole.Highscores[ck][difficulty] or {}
    return GamingHubDB.WhackAMole.Highscores[ck][difficulty]
end

function S:SubmitScore(difficulty, score, missed)
    local list = self:GetHighscores(difficulty)
    table.insert(list, { score = score, missed = missed })
    table.sort(list, function(a, b) return a.score > b.score end)
    while #list > 5 do table.remove(list, 6) end
end

function S:GetTopScore(difficulty)
    local list = self:GetHighscores(difficulty)
    if list and list[1] then return list[1].score end
    return 0
end
