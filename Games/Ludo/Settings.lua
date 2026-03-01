--[[
    Gaming Hub – Mensch ärgere dich nicht (Ludo)
    Games/Ludo/Settings.lua
]]

local GamingHub = _G.GamingHub
GamingHub.LUDO_Settings = {}
local S = GamingHub.LUDO_Settings

S.Defaults = {
    theme           = "classic",
    playerColor     = 1,      -- 1=Blau, 2=Rot (Spieler-Farbe, KI bekommt die andere)
    soundEnabled    = true,
    soundOnRoll     = true,
    soundOnMove     = true,
    soundOnCapture  = true,
    soundOnHome     = true,
    soundOnWin      = true,
}

local DB_KEY = "Ludo"

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

function S:Reset()
    local db = EnsureDB()
    for k in pairs(self.Defaults) do db[k] = nil end
end

function S:GetAll()
    local r = {}
    for k in pairs(self.Defaults) do r[k] = self:Get(k) end
    return r
end
