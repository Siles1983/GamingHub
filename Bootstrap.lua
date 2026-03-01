--[[
    Gaming Hub
    Bootstrap.lua
    Version: 0.1.1 (gameSettings Migration)
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

-- ==========================================
-- Spiel-Registry
-- Jedes Spiel registriert sich selbst via:
--   GamingHub.RegisterGame({
--       id        = "TETRIS",          -- catID, muss eindeutig sein
--       label     = "BlockDrop",       -- Anzeigename in der Sidebar
--       renderer  = "TET_Renderer",    -- GamingHub[renderer]-Key
--       engine    = "TET_Engine",      -- GamingHub[engine]-Key (optional)
--       container = "_tetContainer",   -- GamingHub[container]-Key
--   })
-- ==========================================

GamingHub._gameRegistry = {}

function GamingHub.RegisterGame(info)
    if not info or not info.id then return end
    table.insert(GamingHub._gameRegistry, info)
end

-- ==========================================
-- Locale Framework
-- ==========================================
-- Erkennung: deDE = Deutsch, alles andere = Englisch (Fallback)
-- Verwendung in jedem Spiel:
--   local L = GamingHub.GetLocaleTable("TICTACTOE")
--   someFrame:SetText(L["btn_new_game"])
--
-- Jedes Spiel registriert Strings via Language.lua:
--   GamingHub.RegisterLocale("TICTACTOE", "deDE", { ... })
--   GamingHub.RegisterLocale("TICTACTOE", "enUS", { ... })
-- ==========================================

GamingHub._locales = {}   -- [gameID][locale] = stringTable

-- Sprache einmalig beim Addon-Load ermitteln
local _clientLocale = GetLocale and GetLocale() or "enUS"
GamingHub.ActiveLocale = (_clientLocale == "deDE") and "deDE" or "enUS"

-- Strings fuer ein Spiel + Sprache registrieren
function GamingHub.RegisterLocale(gameID, locale, strings)
    GamingHub._locales[gameID] = GamingHub._locales[gameID] or {}
    GamingHub._locales[gameID][locale] = strings
end

-- Locale-Tabelle fuer ein Spiel abrufen.
-- Aktive Sprache zuerst; fehlende Keys fallen auf enUS zurueck.
-- Fehlende Keys in enUS geben "[key]" als Platzhalter zurueck.
function GamingHub.GetLocaleTable(gameID)
    local locales = GamingHub._locales[gameID]
    if not locales then
        return setmetatable({}, {
            __index = function(_, k) return "[" .. tostring(k) .. "]" end
        })
    end
    local active   = locales[GamingHub.ActiveLocale] or {}
    local fallback = locales["enUS"] or {}
    return setmetatable(active, {
        __index = function(_, k)
            return fallback[k] or ("[" .. tostring(k) .. "]")
        end
    })
end

-- ==========================================
-- Database Setup
-- ==========================================

function GamingHub:InitializeDatabase()
    if not GamingHubDB then
        GamingHubDB = {
            version      = "0.1.1",
            scores       = {},
            settings     = {
                soundEnabled      = true,
                animationsEnabled = true,
            },
            gameSettings = {},   -- Pro-Spiel-Einstellungen
        }
    end

    -- Migration: ältere DB-Versionen haben gameSettings noch nicht
    if not GamingHubDB.gameSettings then
        GamingHubDB.gameSettings = {}
    end
end
