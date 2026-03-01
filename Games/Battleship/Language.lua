--[[
    Gaming Hub
    Games/Battleship/Language.lua
    Version: 1.0.0

    Alle lokalisierbaren Strings fuer Schiffe versenken.
    Zugriff: local L = GamingHub.GetLocaleTable("BATTLESHIP")

    WICHTIG: Schiffsnamen werden in Logic.lua ueber L[] referenziert,
    da sie im BoardState und im Placement-Hint sichtbar sind.
]]

-- ============================================================
-- DEUTSCH (deDE)
-- ============================================================
GamingHub.RegisterLocale("BATTLESHIP", "deDE", {

    -- Schiffsnamen (in Logic.lua referenziert)
    ship_fortress   = "Fliegende Festung",
    ship_galleon    = "Kriegsgaleere",
    ship_zeppelin   = "Zeppelin",
    ship_gunboat    = "Kanonenboot",

    -- Größen-Auswahl (Renderer)
    size_8          = "8×8",
    size_10         = "10×10",
    size_12         = "12×12",

    -- Schwierigkeit (Renderer)
    diff_easy       = "Classic",
    diff_normal     = "Pro",
    diff_hard       = "Insane",

    -- Buttons (Renderer)
    btn_exit        = "Beenden",
    btn_random      = "Zufällig platzieren",
    btn_new_game    = "Neues Spiel",

    -- Hints (Renderer)
    hint_start      = "|cffaaaaaa Wähle eine Feldgröße, dann die Schwierigkeit.|r",
    hint_diff       = "|cffaaaaaa Jetzt Schwierigkeit wählen.|r",
    hint_battle     = "|cffaaaaaa Klicke auf das Gegnerfeld (rechts) um zu schießen.|r",

    -- Grid-Labels (Renderer)
    label_player    = "|cffffd700Dein Feld|r",
    label_enemy     = "|cffffd700Gegner|r",

    -- Placement-Hint (Renderer)
    placement_place = "|cffffff00Platziere:|r %s  (Länge %d)  |cffaaaaaa[R = Drehen]|r",
    placement_done  = "|cffaaaaaa Alle Schiffe platziert. Klicke auf Gegner-Grid.|r",

    -- Game Over Overlay (Renderer)
    result_win      = "|cffffd700Sieg!|r",
    result_win_sub  = "Du hast alle feindlichen Schiffe versenkt!",
    result_loss     = "Niederlage!",
    result_loss_sub = "Deine Flotte wurde vernichtet.",

    -- Settings-Panel: Box-Titel
    box_difficulty  = "KI-Schwierigkeit",
    box_sounds      = "Sounds",

    -- Settings-Panel: KI-Info
    info_classic_title = "|cffffd700Classic:|r",
    info_classic_text  = "Schießt zufällig auf unbeschossene Felder.",
    info_pro_title     = "|cffffd700Pro:|r",
    info_pro_text1     = "Sucht mit Schachbrett-Muster (Hunt).",
    info_pro_text2     = "Nach einem Treffer werden benachbarte",
    info_pro_text3     = "Felder systematisch abgearbeitet (Target).",
    info_insane_title  = "|cffffd700Insane:|r",
    info_insane_text1  = "Berechnet für jedes Feld eine",
    info_insane_text2  = "Wahrscheinlichkeit basierend auf den noch",
    info_insane_text3  = "nicht versenkten Schiffen. Schießt immer",
    info_insane_text4  = "auf das wahrscheinlichste Feld.",
    hint_diff_panel    = "|cff888888Schwierigkeit wird direkt im Spielfeld gewählt.|r",

    -- Settings-Panel: Sounds
    sound_enabled   = "Sounds aktiviert",
    sound_hit       = "Treffer",
    sound_sunk      = "Versenkung",
    sound_win       = "Sieg",
    sound_loss      = "Niederlage",
    sound_hint      = "|cff888888Sounds werden nur abgespielt wenn\ndein Spiel-Sound aktiv ist.|r",

    -- Reset
    btn_reset       = "Auf Standard zurücksetzen",
})

-- ============================================================
-- ENGLISCH (enUS) – Fallback
-- ============================================================
GamingHub.RegisterLocale("BATTLESHIP", "enUS", {

    -- Ship names
    ship_fortress   = "Flying Fortress",
    ship_galleon    = "War Galleon",
    ship_zeppelin   = "Zeppelin",
    ship_gunboat    = "Gunboat",

    -- Size selection
    size_8          = "8×8",
    size_10         = "10×10",
    size_12         = "12×12",

    -- Difficulty
    diff_easy       = "Classic",
    diff_normal     = "Pro",
    diff_hard       = "Insane",

    -- Buttons
    btn_exit        = "Exit",
    btn_random      = "Random placement",
    btn_new_game    = "New Game",

    -- Hints
    hint_start      = "|cffaaaaaa Choose a grid size, then a difficulty.|r",
    hint_diff       = "|cffaaaaaa Now choose a difficulty.|r",
    hint_battle     = "|cffaaaaaa Click the enemy grid (right) to fire.|r",

    -- Grid labels
    label_player    = "|cffffd700Your Board|r",
    label_enemy     = "|cffffd700Enemy|r",

    -- Placement hint
    placement_place = "|cffffff00Place:|r %s  (Length %d)  |cffaaaaaa[R = Rotate]|r",
    placement_done  = "|cffaaaaaa All ships placed. Click the enemy grid.|r",

    -- Game Over
    result_win      = "|cffffd700Victory!|r",
    result_win_sub  = "You sank all enemy ships!",
    result_loss     = "Defeat!",
    result_loss_sub = "Your fleet was destroyed.",

    -- Settings boxes
    box_difficulty  = "AI Difficulty",
    box_sounds      = "Sounds",

    -- AI info
    info_classic_title = "|cffffd700Classic:|r",
    info_classic_text  = "Fires randomly at unshot cells.",
    info_pro_title     = "|cffffd700Pro:|r",
    info_pro_text1     = "Hunts using a checkerboard pattern.",
    info_pro_text2     = "After a hit, systematically works through",
    info_pro_text3     = "adjacent cells until the ship is sunk.",
    info_insane_title  = "|cffffd700Insane:|r",
    info_insane_text1  = "Calculates the probability for every cell",
    info_insane_text2  = "based on remaining ship sizes.",
    info_insane_text3  = "Always fires at the highest-probability",
    info_insane_text4  = "cell.",
    hint_diff_panel    = "|cff888888Difficulty is chosen directly in the game area.|r",

    -- Sounds
    sound_enabled   = "Sounds enabled",
    sound_hit       = "Hit",
    sound_sunk      = "Sunk",
    sound_win       = "Victory",
    sound_loss      = "Defeat",
    sound_hint      = "|cff888888Sounds only play if your in-game sound is active.|r",

    -- Reset
    btn_reset       = "Reset to defaults",
})
