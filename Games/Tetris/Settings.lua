-- BlockDrop – Games/Tetris/Settings.lua

GamingHub = GamingHub or {}
GamingHub.TET_Settings = {}
local S = GamingHub.TET_Settings

local DEFAULTS = {
    difficulty = "NORMAL",
    theme      = "CLASSIC",
    sound      = true,
}

function S:Get(key)
    if not GamingHubDB or not GamingHubDB.Tetris then return DEFAULTS[key] end
    local v = GamingHubDB.Tetris[key]
    if v == nil then return DEFAULTS[key] end
    return v
end

function S:Set(key, value)
    GamingHubDB = GamingHubDB or {}
    GamingHubDB.Tetris = GamingHubDB.Tetris or {}
    GamingHubDB.Tetris[key] = value
end

-- ============================================================
-- Highscore: Top 5 pro Schwierigkeit, pro Charakter
-- ============================================================
function S:_getCharKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

function S:GetHighscores(difficulty)
    GamingHubDB = GamingHubDB or {}
    GamingHubDB.Tetris = GamingHubDB.Tetris or {}
    GamingHubDB.Tetris.Highscores = GamingHubDB.Tetris.Highscores or {}
    local ck = self:_getCharKey()
    GamingHubDB.Tetris.Highscores[ck] = GamingHubDB.Tetris.Highscores[ck] or {}
    GamingHubDB.Tetris.Highscores[ck][difficulty] = GamingHubDB.Tetris.Highscores[ck][difficulty] or {}
    return GamingHubDB.Tetris.Highscores[ck][difficulty]
end

function S:SubmitScore(difficulty, score, lines)
    local list = self:GetHighscores(difficulty)
    table.insert(list, { score = score, lines = lines })
    table.sort(list, function(a, b) return a.score > b.score end)
    while #list > 5 do table.remove(list, 6) end
end

function S:GetTopScore(difficulty)
    local list = self:GetHighscores(difficulty)
    if list and list[1] then return list[1].score end
    return 0
end
