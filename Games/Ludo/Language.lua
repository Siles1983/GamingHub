--[[
    Gaming Hub
    Games/Ludo/Language.lua
    Version: 1.0.0

    Alle lokalisierbaren Strings fuer Ludo (Mensch aergere dich nicht).
    Zugriff: local L = GamingHub.GetLocaleTable("LUDO")
]]

-- ============================================================
-- DEUTSCH (deDE)
-- ============================================================
GamingHub.RegisterLocale("LUDO", "deDE", {

    -- Buttons (Renderer)
    btn_exit        = "Beenden",
    btn_new_game    = "Neues Spiel",
    btn_new_game_ov = "▶ Neues Spiel",

    -- Hint (Renderer)
    hint_start      = "|cffaaaaaa Einstellungen wählen und Neues Spiel starten.\n\nKlicke auf den Würfel in der Mitte um zu würfeln,\ndann auf deine Figur um sie zu ziehen.|r",

    -- Status-Links (Renderer) – Du (Spieler)
    status_human    = "|cff%02x%02x%02xDu (%s)|r  %d/4",

    -- Status-Rechts (Renderer) – KI + Zuganzeige
    status_ai       = "|cff%02x%02x%02xKI (%s)|r  %d/4  %s",
    status_roll     = "|cff00ff00▶ Dein Zug – Würfeln!|r",
    status_pick     = "|cffffff00Figur wählen|r",
    status_ai_think = "|cffaaaaaa KI denkt...|r",
    status_no_move  = "|cffff8800Kein Zug möglich!|r",

    -- Overlay: Sieg (Renderer)
    result_win_title = "|cffffd700🏆 Sieg! Für den Ruhm!|r",
    result_win_sub   = "|cff00ff00Du hast alle Figuren ins Ziel gebracht!|r",

    -- Overlay: Niederlage (Renderer)
    result_loss_title = "|cffff4444Niederlage!|r",
    result_loss_sub   = "|cffaaaaaa Die KI hat alle Figuren ins Ziel gebracht.|r",

    -- Settings-Panel: Box-Titel
    box_options     = "Spiel-Optionen",
    box_sounds      = "Sounds",
    box_guide       = "Spielanleitung",

    -- Settings-Panel: Dropdowns
    label_theme     = "Thema:",
    label_color     = "Deine Farbe:",
    color_blue      = "Blau (Spieler 1)",
    color_red       = "Rot (Spieler 2)",
    label_preview   = "|cffaaaaaa Vorschau (Du / KI):|r",
    preview_you     = "|cffaaaaaaSpielaer|r",
    preview_ai      = "|cffaaaaaaKI|r",
    preview_you_fmt = "|cff%02x%02x%02xDu (%s)|r",
    preview_ai_fmt  = "|cff%02x%02x%02xKI (%s)|r",

    -- Settings-Panel: Start-Button
    btn_start       = "▶ Spiel starten",

    -- Settings-Panel: Sounds
    sound_enabled   = "Sounds aktiviert",
    sound_roll      = "Würfeln",
    sound_move      = "Figur ziehen",
    sound_capture   = "Schlagen",
    sound_home      = "Einlaufen",
    sound_win       = "Sieg",

    -- Settings-Panel: Spielanleitung
    guide_goal      = "|cffffff00Ziel:|r Bringe alle 4 Figuren ins Zielfeld in der Mitte.",
    guide_dice      = "|cffffff00Würfeln:|r Klicke auf den Würfel-Button in der Mitte des Bretts.",
    guide_six       = "|cffffff006 würfeln:|r Figur aus der Basis rausstellen + nochmals würfeln.",
    guide_move      = "|cffffff00Figur ziehen:|r Gültige Figuren leuchten gelb – klicke sie an.",
    guide_capture   = "|cffffff00Schlagen:|r Landest du auf einem Gegner, kommt er zurück in die Basis.",
    guide_safe      = "|cffffff00Sicher:|r Das eigene Startfeld (Eingangsfeld) ist nicht schlagbar.",
    guide_ai        = "|cffffff00KI:|r Schlägt bevorzugt Figuren, sonst wird die vorderste Figur gezogen.",
    guide_hint      = "|cffaaaaaa Farbe & Thema in den Einstellungen wählbar. KI erhält die andere Farbe.|r",

    -- Reset
    btn_reset       = "Einstellungen zurücksetzen",
})

-- ============================================================
-- ENGLISCH (enUS) – Fallback
-- ============================================================
GamingHub.RegisterLocale("LUDO", "enUS", {

    -- Buttons
    btn_exit        = "Exit",
    btn_new_game    = "New Game",
    btn_new_game_ov = "▶ New Game",

    -- Hint
    hint_start      = "|cffaaaaaa Choose settings and start a New Game.\n\nClick the dice button in the center to roll,\nthen click your piece to move it.|r",

    -- Status
    status_human    = "|cff%02x%02x%02xYou (%s)|r  %d/4",
    status_ai       = "|cff%02x%02x%02xAI (%s)|r  %d/4  %s",
    status_roll     = "|cff00ff00▶ Your turn – Roll!|r",
    status_pick     = "|cffffff00Choose a piece|r",
    status_ai_think = "|cffaaaaaa AI thinking...|r",
    status_no_move  = "|cffff8800No move possible!|r",

    -- Overlay
    result_win_title  = "|cffffd700🏆 Victory! For the glory!|r",
    result_win_sub    = "|cff00ff00You moved all pieces to the goal!|r",
    result_loss_title = "|cffff4444Defeat!|r",
    result_loss_sub   = "|cffaaaaaa The AI moved all pieces to the goal.|r",

    -- Settings boxes
    box_options     = "Game Options",
    box_sounds      = "Sounds",
    box_guide       = "How to Play",

    -- Dropdowns
    label_theme     = "Theme:",
    label_color     = "Your color:",
    color_blue      = "Blue (Player 1)",
    color_red       = "Red (Player 2)",
    label_preview   = "|cffaaaaaa Preview (You / AI):|r",
    preview_you     = "|cffaaaaaaPlayer|r",
    preview_ai      = "|cffaaaaaaAI|r",
    preview_you_fmt = "|cff%02x%02x%02xYou (%s)|r",
    preview_ai_fmt  = "|cff%02x%02x%02xAI (%s)|r",

    -- Start button
    btn_start       = "▶ Start Game",

    -- Sounds
    sound_enabled   = "Sounds enabled",
    sound_roll      = "Roll dice",
    sound_move      = "Move piece",
    sound_capture   = "Capture",
    sound_home      = "Reach home",
    sound_win       = "Victory",

    -- Guide
    guide_goal      = "|cffffff00Goal:|r Move all 4 of your pieces to the center goal.",
    guide_dice      = "|cffffff00Dice:|r Click the dice button in the center of the board.",
    guide_six       = "|cffffff00Roll 6:|r Place a piece from base onto the board + roll again.",
    guide_move      = "|cffffff00Move:|r Valid pieces glow yellow – click one to move it.",
    guide_capture   = "|cffffff00Capture:|r Land on an opponent's piece to send it back to base.",
    guide_safe      = "|cffffff00Safe:|r Your own start field (entry square) cannot be captured.",
    guide_ai        = "|cffffff00AI:|r Prefers to capture pieces, otherwise advances the leading piece.",
    guide_hint      = "|cffaaaaaa Color & theme selectable in settings. AI gets the other color.|r",

    -- Reset
    btn_reset       = "Reset settings",
})
