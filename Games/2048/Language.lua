--[[
    Gaming Hub
    Games/2048/Language.lua
    Version: 1.0.0

    Alle lokalisierbaren Strings fuer 2048.
    Zugriff: local L = GamingHub.GetLocaleTable("2048")
]]

-- ============================================================
-- DEUTSCH (deDE)
-- ============================================================
GamingHub.RegisterLocale("2048", "deDE", {

    -- Score-Bar
    score_label     = "PUNKTE",
    best_label      = "BESTPUNKTE",

    -- Größen-Auswahl (Spielfeld-Buttons)
    size_small      = "Klein  (3×3)",
    size_normal     = "Normal (4×4)",
    size_large      = "Groß   (5×5)",

    -- Buttons
    btn_exit        = "Beenden",
    btn_new_game    = "Neues Spiel",

    -- Starthinweis
    hint_start      = "|cffaaaaaa Wähle eine Brett-Größe um zu starten.\nSteuerung: WASD oder Pfeiltasten|r",

    -- Game Over
    go_title        = "Spiel vorbei!",
    go_score        = "Punkte: ",

    -- Settings-Panel: Box-Titel
    box_theme       = "Farb-Thema",
    box_sounds      = "Sounds",

    -- Settings-Panel: Thema
    theme_label     = "Thema:",
    theme_preview   = "Vorschau:",
    theme_hint      = "|cff888888Wirkt ab dem nächsten Spiel.|r",

    -- Theme-Namen (identisch in DE/EN – Eigennamen)
    theme_classic   = "Classic (Orange)",
    theme_horde     = "Horde (Rot/Gold)",
    theme_alliance  = "Allianz (Blau/Silber)",
    theme_nightelf  = "Nachtelf (Lila/Grün)",
    theme_goblin    = "Goblin (Grün/Gelb)",

    -- Settings-Panel: Sounds
    sound_enabled   = "Sounds aktiviert",
    sound_loss      = "Niederlage",
    sound_hint      = "|cff888888Sounds werden nur abgespielt wenn\ndein Spiel-Sound aktiv ist.|r",

    -- Reset
    btn_reset       = "Auf Standard zurücksetzen",
})

-- ============================================================
-- ENGLISCH (enUS) – Fallback
-- ============================================================
GamingHub.RegisterLocale("2048", "enUS", {

    -- Score-Bar
    score_label     = "SCORE",
    best_label      = "BEST",

    -- Größen-Auswahl
    size_small      = "Small  (3×3)",
    size_normal     = "Normal (4×4)",
    size_large      = "Large  (5×5)",

    -- Buttons
    btn_exit        = "Exit",
    btn_new_game    = "New Game",

    -- Starthinweis
    hint_start      = "|cffaaaaaa Choose a board size to start.\nControls: WASD or arrow keys|r",

    -- Game Over
    go_title        = "Game Over!",
    go_score        = "Score: ",

    -- Settings-Panel: Box-Titel
    box_theme       = "Color Theme",
    box_sounds      = "Sounds",

    -- Settings-Panel: Thema
    theme_label     = "Theme:",
    theme_preview   = "Preview:",
    theme_hint      = "|cff888888Takes effect from the next game.|r",

    -- Theme-Namen
    theme_classic   = "Classic (Orange)",
    theme_horde     = "Horde (Red/Gold)",
    theme_alliance  = "Alliance (Blue/Silver)",
    theme_nightelf  = "Night Elf (Purple/Green)",
    theme_goblin    = "Goblin (Green/Yellow)",

    -- Settings-Panel: Sounds
    sound_enabled   = "Sounds enabled",
    sound_loss      = "Defeat",
    sound_hint      = "|cff888888Sounds only play if your in-game sound is active.|r",

    -- Reset
    btn_reset       = "Reset to defaults",
})
