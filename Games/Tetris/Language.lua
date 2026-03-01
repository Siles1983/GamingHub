--[[
    Gaming Hub
    Games/Tetris/Language.lua
    Version: 1.0.0

    Alle lokalisierbaren Strings fuer BlockDrop (intern: Tetris).
    Zugriff: local L = GamingHub.GetLocaleTable("TETRIS")
    WICHTIG: "Tetris" darf NICHT im UI erscheinen – immer "BlockDrop" verwenden!
]]

-- ============================================================
-- DEUTSCH (deDE)
-- ============================================================
GamingHub.RegisterLocale("TETRIS", "deDE", {

    -- Schwierigkeits-Buttons (Renderer)
    diff_easy       = "Easy",
    diff_normal     = "Normal",
    diff_hard       = "Hard",

    -- Buttons (Renderer)
    btn_exit        = "Beenden",
    btn_pause       = "Pause",
    btn_resume      = "Weiter",

    -- Hint (Renderer)
    hint_start      = "|cffaaaaaa Wähle eine Schwierigkeit um zu starten.|r",

    -- Side-Panel Labels (Renderer)
    label_next      = "|cffffff00Nächster:|r",
    label_score     = "|cffffff00Score:|r",
    label_level     = "|cffffff00Level:|r",
    label_lines     = "|cffffff00Reihen:|r",
    label_best      = "|cffffff00Bestzeit:|r",

    -- Pause-Overlay (Renderer)
    pause_text      = "|cffffff00PAUSE|r",

    -- Game-Over-Panel (Renderer)
    gameover_title  = "|cffFF4444Game Over|r",
    gameover_score  = "Score: ",
    gameover_lines  = "Reihen: ",
    gameover_best   = "Bestzeit: ",
    btn_retry       = "Nochmal!",
    btn_menu        = "Menü",

    -- Settings-Panel: Box-Titel
    box_theme       = "Thema & Vorschau",
    box_sounds      = "Sound",
    box_guide       = "Spielanleitung",

    -- Settings-Panel: Vorschau-Hint
    hint_blocks     = "|cffaaaaaa7 Block-Typen – I O T L J S Z|r",

    -- Settings-Panel: Sounds
    sound_enabled   = "Soundeffekte aktiv",
    sound_info      = "|cffaaaaaa" ..
        "Linie: Klang\n" ..
        "4 Reihen: Fanfare\n" ..
        "Rotation: Klick\n" ..
        "Game Over: Ton|r",

    -- Settings-Panel: Spielanleitung
    guide_controls  = "|cffffff00Steuerung:|r",
    guide_keys      = "  W / ↑ / Rechtsklick  →  Block rotieren     |    A / ←  →  Links     |    D / →  →  Rechts",
    guide_drop      = "  S / ↓  →  Softdrop (langsam fallen)         |    Leertaste  →  Harddrop (sofort landen)",
    guide_empty     = "",
    guide_scoring   = "|cffffff00Punktesystem:|r",
    guide_score1    = "  1 Reihe = 40 × (Level+1)    |    2 Reihen = 100 × (Level+1)",
    guide_score2    = "  3 Reihen = 300 × (Level+1)  |    4 Reihen = 1200 × (Level+1)  ← BlockDrop!",
    guide_mult      = "  Easy ×1.0  |  Normal ×1.5  |  Hard ×2.5",
    guide_empty2    = "",
    guide_levelup   = "|cffffff00Level-Up:|r  Alle 10 gelöschten Reihen. Blöcke fallen schneller!",
    guide_highscore = "|cffffff00Highscore:|r  Top 5 pro Schwierigkeit, wird pro Charakter gespeichert.",
    guide_sizes     = "  Easy: 12×22  |  Normal: 10×20  |  Hard: 8×18",
})

-- ============================================================
-- ENGLISCH (enUS) – Fallback
-- ============================================================
GamingHub.RegisterLocale("TETRIS", "enUS", {

    -- Difficulty buttons
    diff_easy       = "Easy",
    diff_normal     = "Normal",
    diff_hard       = "Hard",

    -- Buttons
    btn_exit        = "Exit",
    btn_pause       = "Pause",
    btn_resume      = "Resume",

    -- Hint
    hint_start      = "|cffaaaaaa Choose a difficulty to start.|r",

    -- Side-Panel Labels
    label_next      = "|cffffff00Next:|r",
    label_score     = "|cffffff00Score:|r",
    label_level     = "|cffffff00Level:|r",
    label_lines     = "|cffffff00Lines:|r",
    label_best      = "|cffffff00Best:|r",

    -- Pause
    pause_text      = "|cffffff00PAUSE|r",

    -- Game-Over
    gameover_title  = "|cffFF4444Game Over|r",
    gameover_score  = "Score: ",
    gameover_lines  = "Lines: ",
    gameover_best   = "Best: ",
    btn_retry       = "Retry!",
    btn_menu        = "Menu",

    -- Settings boxes
    box_theme       = "Theme & Preview",
    box_sounds      = "Sound",
    box_guide       = "How to Play",

    -- Preview hint
    hint_blocks     = "|cffaaaaaa7 block types – I O T L J S Z|r",

    -- Sounds
    sound_enabled   = "Sound effects active",
    sound_info      = "|cffaaaaaa" ..
        "Line clear: sound\n" ..
        "4 rows: fanfare\n" ..
        "Rotation: click\n" ..
        "Game Over: tone|r",

    -- Guide
    guide_controls  = "|cffffff00Controls:|r",
    guide_keys      = "  W / ↑ / Right-click  →  Rotate block     |    A / ←  →  Left     |    D / →  →  Right",
    guide_drop      = "  S / ↓  →  Soft drop (slow fall)           |    Space  →  Hard drop (instant land)",
    guide_empty     = "",
    guide_scoring   = "|cffffff00Scoring:|r",
    guide_score1    = "  1 line = 40 × (Level+1)    |    2 lines = 100 × (Level+1)",
    guide_score2    = "  3 lines = 300 × (Level+1)  |    4 lines = 1200 × (Level+1)  ← BlockDrop!",
    guide_mult      = "  Easy ×1.0  |  Normal ×1.5  |  Hard ×2.5",
    guide_empty2    = "",
    guide_levelup   = "|cffffff00Level-Up:|r  Every 10 cleared lines. Blocks fall faster!",
    guide_highscore = "|cffffff00Highscore:|r  Top 5 per difficulty, saved per character.",
    guide_sizes     = "  Easy: 12×22  |  Normal: 10×20  |  Hard: 8×18",
})
