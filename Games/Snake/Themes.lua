--[[
    Gaming Hub – Snake
    Games/Snake/Themes.lua

    Icon-Überprüfung:
    - Ability_Mount_Worm          → in WotLK als "ability_mount_worm" vorhanden
    - Ability_Hunter_SerpentSting → korrekt in WotLK
    - inv_misc_food_65            → WotLK Rohes Fleisch, korrekt
    - inv_misc_statue_02          → WotLK korrekt
    - spell_nature_poisoncleansingtotem → WotLK korrekt
    - spell_nature_lightningshield      → WotLK korrekt
    - inv_misc_gear_01            → WotLK korrekt
    - inv_misc_enggizmos_03       → WotLK korrekt
    - inv_misc_nut_01             → WotLK korrekt

    WICHTIG: Icon-Groß/Kleinschreibung wird vom Client ignoriert,
    aber der Pfad muss EXAKT stimmen. Alle hier klein geschrieben
    da WotLK-Clients case-insensitive für Icons sind.
]]

local GamingHub = _G.GamingHub
GamingHub.SNK_Themes = {}
local T = GamingHub.SNK_Themes

T.THEMES = {
    -- ──────────────────────────────────────────────────────────
    -- 1. Hungrige Jormungar (WotLK/Nordend)
    -- ──────────────────────────────────────────────────────────
    jormungar = {
        name = "Hungrige Jormungar",
        head = {
            icon  = "Interface\\Icons\\Ability_Hunter_SerpentSting",
            color = {0.5, 0.85, 0.2},
        },
        body = {
            icon  = "Interface\\Icons\\Spell_Nature_Poison",
            color = {0.3, 0.65, 0.15},
        },
        food = {
            icon  = "Interface\\Icons\\inv_misc_food_65",
            color = {0.9, 0.5, 0.2},
        },
        eatSound = "earth",
        dieSound = "roar",
    },

    -- ──────────────────────────────────────────────────────────
    -- 2. Gierige Schlange von Sethraliss (Vol'dun)
    -- ──────────────────────────────────────────────────────────
    sethraliss = {
        name = "Schlange von Sethraliss",
        head = {
            icon  = "Interface\\Icons\\inv_misc_statue_02",
            color = {0.85, 0.9, 0.2},
        },
        body = {
            icon  = "Interface\\Icons\\Spell_Nature_NullifyDisease",
            color = {0.2, 0.85, 0.35},
        },
        food = {
            icon  = "Interface\\Icons\\Spell_Nature_LightningShield",
            color = {1.0, 0.9, 0.2},
        },
        eatSound = "hiss",
        dieSound = "roar",
    },

    -- ──────────────────────────────────────────────────────────
    -- 3. Mecha-Snake 2.0 (Gnomeregan)
    -- ──────────────────────────────────────────────────────────
    mechasnake = {
        name = "Mecha-Snake 2.0",
        head = {
            icon  = "Interface\\Icons\\inv_misc_gear_01",
            color = {0.85, 0.75, 0.3},
        },
        body = {
            icon  = "Interface\\Icons\\inv_misc_enggizmos_03",
            color = {0.6, 0.6, 0.7},
        },
        food = {
            icon  = "Interface\\Icons\\inv_misc_nut_01",
            color = {0.9, 0.8, 0.4},
        },
        eatSound = "click",
        dieSound = "explode",
    },
}

-- ============================================================
-- Schwierigkeits-Konfiguration
-- Score-Multiplikator: Easy×1, Normal×2, Hard×4
-- ============================================================
T.DIFFICULTY = {
    easy = {
        label      = "Easy",
        gridSize   = 20,
        cellSize   = 20,
        tickRate   = 0.18,
        multiplier = 1,
    },
    normal = {
        label      = "Normal",
        gridSize   = 16,
        cellSize   = 25,
        tickRate   = 0.12,
        multiplier = 2,
    },
    hard = {
        label      = "Hard",
        gridSize   = 10,
        cellSize   = 40,
        tickRate   = 0.07,
        multiplier = 4,
    },
}

-- ============================================================
-- Hilfsfunktionen
-- ============================================================
function T:GetTheme(key)
    return self.THEMES[key] or self.THEMES.jormungar
end

function T:GetDiff(diffKey)
    return self.DIFFICULTY[diffKey] or self.DIFFICULTY.easy
end

function T:GetThemeList()
    return {
        { key="jormungar",  name=self.THEMES.jormungar.name  },
        { key="sethraliss", name=self.THEMES.sethraliss.name },
        { key="mechasnake", name=self.THEMES.mechasnake.name },
    }
end
