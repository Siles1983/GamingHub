--[[
    Gaming Hub
    Games/Chess/Settings.lua
    Version: 1.0.0
]]

local GamingHub = _G.GamingHub
GamingHub.Chess_Settings = {}
local S = GamingHub.Chess_Settings

S.Defaults = {
    difficulty    = "easy",
    soundEnabled  = true,
}

local DB_KEY = "Chess"

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
