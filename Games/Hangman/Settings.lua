-- Hangman Settings.lua
-- Persistenz via GamingHubDB.Hangman

GamingHub = GamingHub or {}
GamingHub.HGM_Settings = {}
local S = GamingHub.HGM_Settings

local DEFAULTS = {
    category   = "all",
    difficulty = "Normal",   -- Easy / Normal / Hard
    sound      = true,
    wins       = 0,
    losses     = 0,
}

function S:Get(key)
    if not GamingHubDB or not GamingHubDB.Hangman then
        return DEFAULTS[key]
    end
    local v = GamingHubDB.Hangman[key]
    if v == nil then return DEFAULTS[key] end
    return v
end

function S:Set(key, value)
    if not GamingHubDB then return end
    GamingHubDB.Hangman = GamingHubDB.Hangman or {}
    GamingHubDB.Hangman[key] = value
end

function S:IncrWins()
    S:Set("wins", S:Get("wins") + 1)
end

function S:IncrLosses()
    S:Set("losses", S:Get("losses") + 1)
end

function S:GetMaxErrors()
    local diff = S:Get("difficulty")
    if diff == "Easy"   then return 8 end
    if diff == "Hard"   then return 4 end
    return 6  -- Normal
end
