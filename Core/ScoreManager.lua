--[[
    Gaming Hub
    ScoreManager.lua
    Version: 0.1.0 (Core Skeleton)
]]

local GamingHub = _G.GamingHub
GamingHub.ScoreManager = {}

local SM = GamingHub.ScoreManager

function SM:Init()
    if not GamingHubDB.scores then
        GamingHubDB.scores = {}
    end
end

function SM:Update(gameId, result)
    if not GamingHubDB.scores[gameId] then
        GamingHubDB.scores[gameId] = { wins = 0, losses = 0, draws = 0 }
    end

    if result == "WIN" then
        GamingHubDB.scores[gameId].wins = GamingHubDB.scores[gameId].wins + 1
    elseif result == "LOSS" then
        GamingHubDB.scores[gameId].losses = GamingHubDB.scores[gameId].losses + 1
    elseif result == "DRAW" then
        GamingHubDB.scores[gameId].draws = GamingHubDB.scores[gameId].draws + 1
    end
end
function SM:EnsureGameEntry(gameId)
    if not GamingHubDB.scores[gameId] then
        GamingHubDB.scores[gameId] = { wins = 0, losses = 0, draws = 0 }
    end
end