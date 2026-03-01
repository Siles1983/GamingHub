--[[
    Gaming Hub – Mastermind: Azeroth Edition
    Games/Mastermind/Settings.lua
]]

local GamingHub = _G.GamingHub
GamingHub.MM_Settings = {}
local S = GamingHub.MM_Settings

local DEFAULTS = {
    difficulty   = "normal",
    theme        = "gems",
    codeLength   = 4,
    duplicates   = true,
    soundEnabled = true,
    soundOnPlace = true,
    soundOnSubmit= true,
    soundOnWin   = true,
    soundOnLose  = true,
}

function S:Get(key)
    if GamingHubDB and GamingHubDB.Mastermind and GamingHubDB.Mastermind[key] ~= nil then
        return GamingHubDB.Mastermind[key]
    end
    return DEFAULTS[key]
end

function S:Set(key, value)
    if not GamingHubDB then GamingHubDB = {} end
    if not GamingHubDB.Mastermind then GamingHubDB.Mastermind = {} end
    GamingHubDB.Mastermind[key] = value
end

function S:GetAll()
    local t = {}
    for k, v in pairs(DEFAULTS) do t[k] = self:Get(k) end
    return t
end

function S:Reset()
    if GamingHubDB then GamingHubDB.Mastermind = {} end
end
