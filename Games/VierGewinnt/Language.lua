--[[
    Gaming Hub
    Games/VierGewinnt/Language.lua
    Version: 1.0.0

    Alle lokalisierbaren Strings fuer Vier Gewinnt.
    Zugriff: local L = GamingHub.GetLocaleTable("CONNECT4")
]]

-- ============================================================
-- DEUTSCH (deDE)
-- ============================================================
GamingHub.RegisterLocale("CONNECT4", "deDE", {

    -- Settings-Panel: Box-Titel
    box_symbols     = "Symbole",
    box_background  = "Hintergrund",
    box_sounds      = "Sounds",

    -- Symbole
    sym_auto        = "Automatisch erkennen (Fraktion)",
    sym_set_label   = "Symbol-Set:",
    sym_standard    = "Standard (●/●)",
    sym_faction     = "Fraktions-Wappen",
    sym_player_label= "Mein Symbol:",
    sym_alliance    = "Allianz-Wappen",
    sym_horde       = "Horde-Wappen",
    sym_hint        = "|cff888888Im Standard-Modus: Spieler = Gelb, KI = Rot. Wappen werden rund dargestellt.|r",

    -- Hintergrund
    bg_type_label   = "Hintergrund-Typ:",
    bg_neutral      = "Neutral (Standard)",
    bg_faction      = "Fraktion",
    bg_class        = "Klasse",
    bg_race         = "Rasse",
    bg_auto         = "Automatisch erkennen",
    bg_faction_label= "Fraktion:",
    bg_class_label  = "Klasse:",
    bg_race_label   = "Rasse:",

    -- Klassen
    class_warrior   = "Krieger",
    class_paladin   = "Paladin",
    class_hunter    = "Jäger",
    class_rogue     = "Schurke",
    class_priest    = "Priester",
    class_shaman    = "Schamane",
    class_mage      = "Magier",
    class_warlock   = "Hexenmeister",
    class_monk      = "Mönch",
    class_druid     = "Druide",
    class_dh        = "Dämonenjäger",
    class_dk        = "Todesritter",
    class_evoker    = "Rufer",

    -- Völker
    race_human      = "Mensch",
    race_dwarf      = "Zwerg",
    race_nightelf   = "Nachtelf",
    race_gnome      = "Gnom",
    race_draenei    = "Draenei",
    race_worgen     = "Worgen",
    race_pandaren_a = "Pandaren (A)",
    race_orc        = "Ork",
    race_undead     = "Untoter",
    race_tauren     = "Tauren",
    race_troll      = "Troll",
    race_bloodelf   = "Blutelf",
    race_goblin     = "Goblin",
    race_pandaren_h = "Pandaren (H)",
    race_dracthyr   = "Dracthyr",

    -- Sounds
    sound_enabled   = "Sounds aktiviert",
    sound_win       = "Sieg",
    sound_loss      = "Niederlage",
    sound_draw      = "Unentschieden",
    sound_hint      = "|cff888888Sounds werden nur abgespielt wenn dein Spiel-Sound aktiv ist.|r",

    -- Reset
    btn_reset       = "Auf Standard zurücksetzen",

    -- Spielfeld / Renderer
    btn_exit        = "Beenden",
    result_win      = "Du gewinnst!",
    result_loss     = "Du verlierst!",
    result_draw     = "Unentschieden!",

    -- Größen-Auswahl
    mode_small      = "Klein (5×4)",
    mode_normal     = "Normal (7×6)",
    mode_large      = "Groß (9×7)",

    -- Schwierigkeit
    diff_easy       = "Classic",
    diff_normal     = "Pro",
    diff_hard       = "Insane",
})

-- ============================================================
-- ENGLISCH (enUS) – Fallback
-- ============================================================
GamingHub.RegisterLocale("CONNECT4", "enUS", {

    -- Settings-Panel: Box-Titel
    box_symbols     = "Symbols",
    box_background  = "Background",
    box_sounds      = "Sounds",

    -- Symbole
    sym_auto        = "Auto-detect (Faction)",
    sym_set_label   = "Symbol set:",
    sym_standard    = "Standard (●/●)",
    sym_faction     = "Faction crests",
    sym_player_label= "My symbol:",
    sym_alliance    = "Alliance crest",
    sym_horde       = "Horde crest",
    sym_hint        = "|cff888888Standard mode: Player = Yellow, AI = Red. Crests are shown as circles.|r",

    -- Hintergrund
    bg_type_label   = "Background type:",
    bg_neutral      = "Neutral (default)",
    bg_faction      = "Faction",
    bg_class        = "Class",
    bg_race         = "Race",
    bg_auto         = "Auto-detect",
    bg_faction_label= "Faction:",
    bg_class_label  = "Class:",
    bg_race_label   = "Race:",

    -- Classes
    class_warrior   = "Warrior",
    class_paladin   = "Paladin",
    class_hunter    = "Hunter",
    class_rogue     = "Rogue",
    class_priest    = "Priest",
    class_shaman    = "Shaman",
    class_mage      = "Mage",
    class_warlock   = "Warlock",
    class_monk      = "Monk",
    class_druid     = "Druid",
    class_dh        = "Demon Hunter",
    class_dk        = "Death Knight",
    class_evoker    = "Evoker",

    -- Races
    race_human      = "Human",
    race_dwarf      = "Dwarf",
    race_nightelf   = "Night Elf",
    race_gnome      = "Gnome",
    race_draenei    = "Draenei",
    race_worgen     = "Worgen",
    race_pandaren_a = "Pandaren (A)",
    race_orc        = "Orc",
    race_undead     = "Undead",
    race_tauren     = "Tauren",
    race_troll      = "Troll",
    race_bloodelf   = "Blood Elf",
    race_goblin     = "Goblin",
    race_pandaren_h = "Pandaren (H)",
    race_dracthyr   = "Dracthyr",

    -- Sounds
    sound_enabled   = "Sounds enabled",
    sound_win       = "Victory",
    sound_loss      = "Defeat",
    sound_draw      = "Draw",
    sound_hint      = "|cff888888Sounds only play if your in-game sound is active.|r",

    -- Reset
    btn_reset       = "Reset to defaults",

    -- Spielfeld / Renderer
    btn_exit        = "Exit",
    result_win      = "You win!",
    result_loss     = "You lose!",
    result_draw     = "Draw!",

    -- Größen-Auswahl
    mode_small      = "Small (5×4)",
    mode_normal     = "Normal (7×6)",
    mode_large      = "Large (9×7)",

    -- Schwierigkeit
    diff_easy       = "Classic",
    diff_normal     = "Pro",
    diff_hard       = "Insane",
})
