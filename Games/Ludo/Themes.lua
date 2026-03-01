--[[
    Gaming Hub – Mensch ärgere dich nicht (Ludo)
    Games/Ludo/Themes.lua

    3 Themen:
      classic    – Fraktionskrieg (Allianz/Horde/Smaragd/Licht)
      shadowlands– Schattenlande (düstere Knochen-Ästhetik)
      goblin     – Goblin-Casino (Edelsteine/Gold)

    Jedes Thema definiert:
      name        – Anzeigename
      pathTex     – Textur für neutrale Wegfelder
      homeTex     – Textur für Zielgerade (wird mit Spielerfarbe getönt)
      baseTex     – Textur für Basis-Felder (getönt)
      diceTex[1-6]– Würfel-Icons
      pieces[1-4] – Icon pro Spieler-Farbe (Blau/Rot/Grün/Gelb)
      colors[1-4] – RGB-Farbe pro Spieler
]]

local GamingHub = _G.GamingHub
GamingHub.LUDO_Themes = {}
local T = GamingHub.LUDO_Themes

-- Würfel-Icons: INV_Misc_Dice_01–06 (WotLK verified)
local DICE = {
    "Interface\\Icons\\INV_Misc_Dice_01",
    "Interface\\Icons\\INV_Misc_Dice_02",
    "Interface\\Icons\\INV_Misc_Dice_03",
    "Interface\\Icons\\INV_Misc_Dice_04",
    "Interface\\Icons\\INV_Misc_Dice_05",
    "Interface\\Icons\\INV_Misc_Dice_06",
}

T.THEMES = {
    -- ──────────────────────────────────────────────────────────
    -- 1. Klassischer Fraktionskrieg (Standard)
    -- ──────────────────────────────────────────────────────────
    classic = {
        name    = "Fraktionskrieg",
        pathTex = "Interface\\Icons\\INV_Stone_04",
        homeTex = "Interface\\Icons\\INV_Stone_04",
        baseTex = "Interface\\Icons\\INV_Stone_04",
        dice    = DICE,
        pieces  = {
            [1] = "Interface\\Icons\\INV_BannerPVP_02",          -- Blau: Allianz-Banner
            [2] = "Interface\\Icons\\INV_BannerPVP_01",          -- Rot:  Horde-Banner
            [3] = "Interface\\Icons\\Spell_Nature_HealingTouch", -- Grün: Smaragdgrüner Traum
            [4] = "Interface\\Icons\\Spell_Holy_HolyBolt",       -- Gelb: Das Licht
        },
        colors  = {
            [1] = { 0.2, 0.5, 1.0 },   -- Blau
            [2] = { 1.0, 0.2, 0.2 },   -- Rot
            [3] = { 0.2, 0.9, 0.2 },   -- Grün
            [4] = { 1.0, 0.85, 0.1 },  -- Gelb
        },
    },

    -- ──────────────────────────────────────────────────────────
    -- 2. Schattenlande / Eiskrone (Düster)
    -- ──────────────────────────────────────────────────────────
    shadowlands = {
        name    = "Schattenlande",
        pathTex = "Interface\\Icons\\INV_Misc_Bone_01",
        homeTex = "Interface\\Icons\\INV_Misc_Bone_01",
        baseTex = "Interface\\Icons\\INV_Misc_Bone_01",
        dice    = DICE,
        pieces  = {
            [1] = "Interface\\Icons\\Spell_DeathKnight_BloodBoil",   -- Blau: Blut-DK (dunkelrot/blau)
            [2] = "Interface\\Icons\\Spell_Shadow_ShadowBolt",        -- Rot:  Schattenblitz
            [3] = "Interface\\Icons\\Spell_Frost_FrostBolt02",        -- Grün: Frostblitz (kalt/türkis)
            [4] = "Interface\\Icons\\Spell_Holy_EqualizeRuneSpeed",   -- Gelb: Heilig-Rune
        },
        colors  = {
            [1] = { 0.5, 0.1, 0.2 },   -- Dunkelrot
            [2] = { 0.4, 0.1, 0.7 },   -- Lila
            [3] = { 0.2, 0.7, 0.9 },   -- Eisblau
            [4] = { 0.9, 0.85, 0.6 },  -- Gold/Weiß
        },
    },

    -- ──────────────────────────────────────────────────────────
    -- 3. Goblin-Casino / Beutebucht (Bunt)
    -- ──────────────────────────────────────────────────────────
    goblin = {
        name    = "Goblin-Casino",
        pathTex = "Interface\\Icons\\INV_Misc_Coin_01",
        homeTex = "Interface\\Icons\\INV_Misc_Coin_01",
        baseTex = "Interface\\Icons\\INV_Misc_Coin_01",
        dice    = DICE,
        pieces  = {
            [1] = "Interface\\Icons\\inv_misc_gem_sapphire_02",       -- Blau: Saphir
            [2] = "Interface\\Icons\\inv_misc_gem_ruby_02",           -- Rot:  Rubin
            [3] = "Interface\\Icons\\inv_misc_gem_emerald_02",        -- Grün: Smaragd
            [4] = "Interface\\Icons\\inv_misc_gem_topaz_01",          -- Gelb: Topas
        },
        colors  = {
            [1] = { 0.2, 0.4, 1.0 },   -- Saphirblau
            [2] = { 1.0, 0.15, 0.15 }, -- Rubinrot
            [3] = { 0.1, 0.85, 0.3 },  -- Smaragdgrün
            [4] = { 1.0, 0.75, 0.0 },  -- Topasgelb
        },
    },
}

-- ============================================================
-- Hilfsfunktionen
-- ============================================================
function T:GetTheme(key)
    return self.THEMES[key] or self.THEMES.classic
end

function T:GetThemeList()
    return {
        { key="classic",     name=self.THEMES.classic.name     },
        { key="shadowlands", name=self.THEMES.shadowlands.name },
        { key="goblin",      name=self.THEMES.goblin.name      },
    }
end
