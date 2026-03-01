-- Core/ThemeRegistry.lua

GamingHub = GamingHub or {}
GamingHub.ThemeRegistry = GamingHub.ThemeRegistry or {}

local Registry = GamingHub.ThemeRegistry

Registry._themes = {}

function Registry:Register(themeTable)
    -- Validierung
    -- ID prüfen
    -- Duplikate prüfen
    -- Speichern
end

function Registry:GetRaw(id)
    return self._themes[id]
end

function Registry:Exists(id)
    return self._themes[id] ~= nil
end

function Registry:GetAllIDs()
    -- IDs sammeln
end