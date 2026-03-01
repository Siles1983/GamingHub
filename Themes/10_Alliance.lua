--[[
    Gaming Hub
    Bootstrap.lua
    Version: 0.1.0 (Initial Skeleton)
]]

local ADDON_NAME = ...
local GamingHub = {}
_G.GamingHub = GamingHub

local frame = CreateFrame("Frame")

-- ==========================================
-- Event Handling
-- ==========================================

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            GamingHub:OnAddonLoaded()
        end
    elseif event == "PLAYER_LOGIN" then
        GamingHub:OnPlayerLogin()
    end
end)

-- ==========================================
-- Initialization
-- ==========================================

function GamingHub:OnAddonLoaded()
    self:InitializeDatabase()
end

function GamingHub:OnPlayerLogin()
    if self.Engine and self.Engine.Init then
        self.Engine:Init()
    end
end

-- ==========================================
-- Database Setup
-- ==========================================

function GamingHub:InitializeDatabase()
    if not GamingHubDB then
        GamingHubDB = {
            version = "0.1.0",
            scores = {},
            settings = {
                soundEnabled = true,
                animationsEnabled = true
            }
        }
    end
end