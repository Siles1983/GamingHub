--[[
    Gaming Hub
    Games/Sudoku/Language.lua
    Version: 1.0.0

    Alle lokalisierbaren Strings fuer Sudoku.
    Zugriff: local L = GamingHub.GetLocaleTable("SUDOKU")
]]

-- ============================================================
-- DEUTSCH (deDE)
-- ============================================================
GamingHub.RegisterLocale("SUDOKU", "deDE", {

    -- Schwierigkeits-Buttons (Renderer)
    diff_easy       = "Easy",
    diff_normal     = "Normal",
    diff_hard       = "Hard",

    -- Buttons (Renderer)
    btn_exit        = "Beenden",
    btn_new_puzzle  = "Neues Puzzle",

    -- Hints / Statistik (Renderer)
    hint_start      = "|cffaaaaaa Wähle eine Schwierigkeit um zu starten.|r",
    stats_text      = "|cffaaaaaa Züge:|r %d   |cffaaaaaa Fehler:|r %d",

    -- Overlay: Sieg (Renderer)
    result_title    = "|cffffd700Gelöst!|r",
    result_sub      = "Züge: |cffffff00%d|r   Fehler: |cffff6666%d|r\nSchwierigkeit: |cffffd700%s|r",

    -- EnterIdleState: DIFFS-Referenz intern – kein extra Key nötig

    -- Settings-Panel: Box-Titel
    box_difficulty  = "Schwierigkeit",
    box_sounds      = "Sounds",

    -- Settings-Panel: Schwierigkeits-Info
    info_easy_title  = "|cffffd700Easy:|r",
    info_easy_text1  = "~46 Felder vorgegeben.",
    info_easy_text2  = "Viele Hinweise, ideal zum Einstieg.",
    info_normal_title= "|cffffd700Normal:|r",
    info_normal_text1= "~38 Felder vorgegeben.",
    info_normal_text2= "Ausgeglichene Herausforderung.",
    info_hard_title  = "|cffffd700Hard:|r",
    info_hard_text1  = "~28 Felder vorgegeben.",
    info_hard_text2  = "Wenige Hinweise, erfordert",
    info_hard_text3  = "fortgeschrittene Techniken.",

    -- Settings-Panel: Sounds
    sound_enabled   = "Sounds aktiviert",
    sound_place     = "Zahl gesetzt",
    sound_error     = "Fehler",
    sound_complete  = "Gelöst",
    sound_hint      = "|cff888888Sounds werden nur abgespielt wenn\ndein Spiel-Sound aktiv ist.|r",

    -- Reset
    btn_reset       = "Auf Standard zurücksetzen",
})

-- ============================================================
-- ENGLISCH (enUS) – Fallback
-- ============================================================
GamingHub.RegisterLocale("SUDOKU", "enUS", {

    -- Difficulty buttons
    diff_easy       = "Easy",
    diff_normal     = "Normal",
    diff_hard       = "Hard",

    -- Buttons
    btn_exit        = "Exit",
    btn_new_puzzle  = "New Puzzle",

    -- Hints / Stats
    hint_start      = "|cffaaaaaa Choose a difficulty to start.|r",
    stats_text      = "|cffaaaaaa Moves:|r %d   |cffaaaaaa Mistakes:|r %d",

    -- Overlay: Victory
    result_title    = "|cffffd700Solved!|r",
    result_sub      = "Moves: |cffffff00%d|r   Mistakes: |cffff6666%d|r\nDifficulty: |cffffd700%s|r",

    -- Settings boxes
    box_difficulty  = "Difficulty",
    box_sounds      = "Sounds",

    -- Difficulty info
    info_easy_title  = "|cffffd700Easy:|r",
    info_easy_text1  = "~46 cells given.",
    info_easy_text2  = "Many hints, ideal for beginners.",
    info_normal_title= "|cffffd700Normal:|r",
    info_normal_text1= "~38 cells given.",
    info_normal_text2= "Balanced challenge.",
    info_hard_title  = "|cffffd700Hard:|r",
    info_hard_text1  = "~28 cells given.",
    info_hard_text2  = "Few hints, requires",
    info_hard_text3  = "advanced techniques.",

    -- Sounds
    sound_enabled   = "Sounds enabled",
    sound_place     = "Number placed",
    sound_error     = "Mistake",
    sound_complete  = "Solved",
    sound_hint      = "|cff888888Sounds only play if your in-game sound is active.|r",

    -- Reset
    btn_reset       = "Reset to defaults",
})
