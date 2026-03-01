--[[
    Gaming Hub – Simon Says: Oger-Runen Edition
    Games/SimonSays/Themes.lua

    Icon-Recherche-Ergebnisse:
    - inv_misc_rune_01 bis 11: seit Classic/WotLK verfügbar ✓
    - inv_misc_rune_12+: erst ab MoP/Legion → WotLK-Alternativen für Hard
    - spell_nature_rejuvenation, wispsplode, thunderclap, stormreach: WotLK ✓
    - UI-HUD-Specialization-*: erst ab MoP/WoD → Klassen-Spell-Icons als Ersatz
    - UI-RaidTargetingIcon_1-8: Atlas, braucht C_Texture.GetAtlasInfo + SetTexCoord
    - readycheck-waiting, UI-WorldMarker1-8: Atlas

    Symbole mit isAtlas=true werden im Renderer per C_Texture.GetAtlasInfo gerendert.
]]

local GamingHub = _G.GamingHub
GamingHub.SS_Themes = {}
local T = GamingHub.SS_Themes

T.THEMES = {

    -- ──────────────────────────────────────────────────────────
    -- 1. Oger-Magi Runen
    -- inv_misc_rune_01–11 sind in WotLK vorhanden.
    -- 12–16 erst ab MoP → WotLK DK-Runen-Icons als Ersatz für Hard
    -- ──────────────────────────────────────────────────────────
    runes = {
        name = "Oger-Magi Runen",
        symbols = {
            -- Easy (1-4)
            { name="Rune I",    icon="Interface\\Icons\\inv_misc_rune_01", color={0.9,0.7,1.0} },
            { name="Rune II",   icon="Interface\\Icons\\inv_misc_rune_02", color={1.0,0.5,0.1} },
            { name="Rune III",  icon="Interface\\Icons\\inv_misc_rune_03", color={0.3,0.8,1.0} },
            { name="Rune IV",   icon="Interface\\Icons\\inv_misc_rune_04", color={0.2,1.0,0.3} },
            -- Normal (5-9)
            { name="Rune V",    icon="Interface\\Icons\\inv_misc_rune_05", color={0.7,0.1,1.0} },
            { name="Rune VI",   icon="Interface\\Icons\\inv_misc_rune_06", color={1.0,1.0,0.3} },
            { name="Rune VII",  icon="Interface\\Icons\\inv_misc_rune_07", color={1.0,0.9,0.1} },
            { name="Rune VIII", icon="Interface\\Icons\\inv_misc_rune_08", color={1.0,0.4,0.4} },
            { name="Rune IX",   icon="Interface\\Icons\\inv_misc_rune_09", color={0.2,0.6,1.0} },
            -- Hard (10-16): rune_10+11 verfügbar, dann DK-Rune-Alternativen
            { name="Rune X",    icon="Interface\\Icons\\inv_misc_rune_10", color={0.9,0.5,1.0} },
            { name="Rune XI",   icon="Interface\\Icons\\inv_misc_rune_11", color={0.5,0.9,1.0} },
            -- rune_12+ nicht in WotLK → bewährte Rune-ähnliche Icons
            { name="Blut-Rune", icon="Interface\\Icons\\spell_deathknight_runetap",          color={0.9,0.1,0.1} },
            { name="Frost-Rune",icon="Interface\\Icons\\spell_deathknight_icytouch",          color={0.4,0.8,1.0} },
            { name="Tod-Rune",  icon="Interface\\Icons\\spell_deathknight_deathcoil",         color={0.5,0.0,0.8} },
            { name="Chaos-Rune",icon="Interface\\Icons\\spell_shadow_shadowform",             color={0.7,0.2,1.0} },
            { name="Arkan-Rune",icon="Interface\\Icons\\spell_arcane_arcane01",               color={0.6,0.4,1.0} },
        },
    },

    -- ──────────────────────────────────────────────────────────
    -- 2. Raid-Marker (E-Sport/Training)
    -- Atlas-Texturen: isAtlas=true → Renderer nutzt C_Texture.GetAtlasInfo
    -- ──────────────────────────────────────────────────────────
    raidmarker = {
        name = "Raid-Marker",
        symbols = {
            -- Easy (1-4)
            { name="Stern",      atlas="UI-RaidTargetingIcon_1", color={1.0,0.95,0.1}, isAtlas=true },
            { name="Kreis",      atlas="UI-RaidTargetingIcon_2", color={1.0,0.5,0.0},  isAtlas=true },
            { name="Diamant",    atlas="UI-RaidTargetingIcon_3", color={0.8,0.2,1.0},  isAtlas=true },
            { name="Dreieck",    atlas="UI-RaidTargetingIcon_4", color={0.2,0.9,0.2},  isAtlas=true },
            -- Normal (5-9)
            { name="Mond",       atlas="UI-RaidTargetingIcon_5", color={0.4,0.6,1.0},  isAtlas=true },
            { name="Quadrat",    atlas="UI-RaidTargetingIcon_6", color={0.6,0.4,1.0},  isAtlas=true },
            { name="Kreuz",      atlas="UI-RaidTargetingIcon_7", color={1.0,0.2,0.2},  isAtlas=true },
            { name="Totenkopf",  atlas="UI-RaidTargetingIcon_8", color={0.7,0.7,0.7},  isAtlas=true },
            { name="Warten",     atlas="readycheck-waiting",      color={0.8,0.8,0.5},  isAtlas=true },
            -- Hard (10-16): Weltmarker-Atlas
            { name="Weltm. 1",   atlas="UI-WorldMarker1",  color={1.0,0.9,0.2},  isAtlas=true },
            { name="Weltm. 2",   atlas="UI-WorldMarker2",  color={1.0,0.5,0.1},  isAtlas=true },
            { name="Weltm. 3",   atlas="UI-WorldMarker3",  color={0.3,0.8,1.0},  isAtlas=true },
            { name="Weltm. 4",   atlas="UI-WorldMarker4",  color={0.2,0.9,0.2},  isAtlas=true },
            { name="Weltm. 5",   atlas="UI-WorldMarker5",  color={0.8,0.3,1.0},  isAtlas=true },
            { name="Weltm. 6",   atlas="UI-WorldMarker6",  color={1.0,0.2,0.2},  isAtlas=true },
            { name="Weltm. 7",   atlas="UI-WorldMarker7",  color={0.6,0.6,0.6},  isAtlas=true },
            { name="Weltm. 8",   atlas="UI-WorldMarker8",  color={0.5,0.8,0.5},  isAtlas=true },
        },
    },

    -- ──────────────────────────────────────────────────────────
    -- 3. Elementare Mächte (Natur/Schamanisch)
    -- Alle Icons in WotLK verifiziert
    -- ──────────────────────────────────────────────────────────
    elements = {
        name = "Elementare Mächte",
        symbols = {
            -- Easy (1-4): Feuer, Frost, Erde, Luft
            { name="Feuer",     icon="Interface\\Icons\\spell_fire_fire",              color={1.0,0.3,0.0} },
            { name="Frost",     icon="Interface\\Icons\\spell_frost_frost",            color={0.3,0.7,1.0} },
            { name="Erde",      icon="Interface\\Icons\\spell_nature_earthquake",      color={0.8,0.6,0.2} },
            { name="Luft",      icon="Interface\\Icons\\spell_nature_cyclone",         color={0.7,0.9,1.0} },
            -- Normal (5-9)
            { name="Blitz",     icon="Interface\\Icons\\spell_nature_lightning",       color={1.0,0.9,0.1} },
            { name="Lava",      icon="Interface\\Icons\\spell_fire_lava",              color={1.0,0.5,0.1} },
            { name="Natur",     icon="Interface\\Icons\\spell_nature_rejuvenation",    color={0.2,0.9,0.2} },
            { name="Eis",       icon="Interface\\Icons\\spell_frost_iceclaws",         color={0.5,0.85,1.0} },
            { name="Geist",     icon="Interface\\Icons\\spell_nature_spiritspirit",    color={0.8,0.7,1.0} },
            -- Hard (10-16): weitere WotLK-Natur/Element-Icons
            { name="Sturm",     icon="Interface\\Icons\\spell_nature_stormreach",      color={0.6,0.8,1.0} },
            { name="Knall",     icon="Interface\\Icons\\spell_nature_wispsplode",      color={0.9,1.0,0.5} },
            { name="Donner",    icon="Interface\\Icons\\spell_nature_thunderclap",     color={0.7,0.7,1.0} },
            { name="Eis-Schock",icon="Interface\\Icons\\spell_frost_frostshock",       color={0.3,0.6,1.0} },
            { name="Lava-Burst",icon="Interface\\Icons\\spell_shaman_lavaburst",       color={1.0,0.4,0.0} },
            { name="Kette",     icon="Interface\\Icons\\spell_nature_chainlightning",  color={0.9,0.9,0.3} },
            { name="Totem",     icon="Interface\\Icons\\spell_nature_stoneskintotem",  color={0.6,0.5,0.3} },
        },
    },

    -- ──────────────────────────────────────────────────────────
    -- 4. Licht & Leere (Midnight-Stil)
    -- UI-HUD-Specialization-* Atlas (Thema des Nutzers)
    -- Einige Spec-Atlasse sind möglicherweise erst ab MoP vorhanden.
    -- isAtlas=true → Renderer nutzt C_Texture.GetAtlasInfo
    -- ──────────────────────────────────────────────────────────
    lightandshadow = {
        name = "Licht & Leere",
        symbols = {
            -- Easy (1-4)
            { name="Heilig-Paladin",    atlas="UI-HUD-Specialization-Paladin-Holy",        color={1.0,0.9,0.3}, isAtlas=true },
            { name="Schatten-Priester", atlas="UI-HUD-Specialization-Priest-Shadow",       color={0.6,0.0,0.9}, isAtlas=true },
            { name="Gleichgewicht",     atlas="UI-HUD-Specialization-Druid-Balance",       color={0.5,0.5,1.0}, isAtlas=true },
            { name="Arkan-Magier",      atlas="UI-HUD-Specialization-Mage-Arcane",         color={0.8,0.4,1.0}, isAtlas=true },
            -- Normal (5-9)
            { name="Heilig-Priester",   atlas="UI-HUD-Specialization-Priest-Holy",         color={1.0,1.0,0.7}, isAtlas=true },
            { name="Heimsuchung",       atlas="UI-HUD-Specialization-Warlock-Affliction",  color={0.4,0.8,0.3}, isAtlas=true },
            { name="Frost-Magier",      atlas="UI-HUD-Specialization-Mage-Frost",          color={0.4,0.7,1.0}, isAtlas=true },
            { name="Feuer-Magier",      atlas="UI-HUD-Specialization-Mage-Fire",           color={1.0,0.4,0.1}, isAtlas=true },
            { name="Disziplin",         atlas="UI-HUD-Specialization-Priest-Discipline",   color={0.9,0.7,1.0}, isAtlas=true },
            -- Hard (10-16)
            { name="Vergeltung",        atlas="UI-HUD-Specialization-Paladin-Retribution", color={1.0,0.6,0.1}, isAtlas=true },
            { name="Zerstörung",        atlas="UI-HUD-Specialization-Warlock-Destruction", color={0.9,0.2,0.2}, isAtlas=true },
            { name="Blut-DK",           atlas="UI-HUD-Specialization-DeathKnight-Blood",   color={0.8,0.1,0.1}, isAtlas=true },
            { name="Frost-DK",          atlas="UI-HUD-Specialization-DeathKnight-Frost",   color={0.5,0.8,1.0}, isAtlas=true },
            { name="Unheilig-DK",       atlas="UI-HUD-Specialization-DeathKnight-Unholy",  color={0.3,0.7,0.2}, isAtlas=true },
            { name="Wiederherst.",      atlas="UI-HUD-Specialization-Druid-Restoration",   color={0.2,0.9,0.4}, isAtlas=true },
            { name="Schutz-Paladin",    atlas="UI-HUD-Specialization-Paladin-Protection",  color={0.6,0.7,1.0}, isAtlas=true },
        },
    },
}

-- ============================================================
-- Schwierigkeits-Konfiguration
-- ============================================================
T.DIFFICULTY = {
    easy   = { grid = 2, startLen = 3, label = "Easy",   maxSpeed = 0.4 },
    normal = { grid = 3, startLen = 3, label = "Normal", maxSpeed = 0.3 },
    hard   = { grid = 4, startLen = 3, label = "Hard",   maxSpeed = 0.2 },
}

-- ============================================================
-- Hilfsfunktionen
-- ============================================================
function T:GetTheme(key)
    return self.THEMES[key] or self.THEMES.runes
end

function T:GetSymbolsForDiff(themeKey, diffKey)
    local theme  = self:GetTheme(themeKey)
    local diff   = self.DIFFICULTY[diffKey] or self.DIFFICULTY.easy
    local count  = diff.grid * diff.grid
    local result = {}
    for i = 1, count do
        result[i] = theme.symbols[i] or theme.symbols[#theme.symbols]
    end
    return result
end

function T:GetDiff(diffKey)
    return self.DIFFICULTY[diffKey] or self.DIFFICULTY.easy
end

function T:GetThemeList()
    return {
        { key="runes",          name=self.THEMES.runes.name          },
        { key="raidmarker",     name=self.THEMES.raidmarker.name     },
        { key="elements",       name=self.THEMES.elements.name       },
        { key="lightandshadow", name=self.THEMES.lightandshadow.name },
    }
end
