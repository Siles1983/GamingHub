--[[
    Gaming Hub
    Games/Snake/Language.lua
    Version: 1.0.0

    Alle lokalisierbaren Strings fuer Snake.
    Zugriff: local L = GamingHub.GetLocaleTable("SNAKE")
]]

-- ============================================================
-- DEUTSCH (deDE)
-- ============================================================
GamingHub.RegisterLocale("SNAKE", "deDE", {

    -- Schwierigkeits-Buttons (Renderer)
    diff_easy       = "Easy",
    diff_normal     = "Normal",
    diff_hard       = "Hard",

    -- Buttons (Renderer)
    btn_exit        = "Beenden",
    btn_new_game    = "Neues Spiel",
    btn_new_game_ov = "▶ Neues Spiel",

    -- Hint (Renderer)
    hint_start      = "|cffaaaaaa Wähle eine Schwierigkeit um zu starten.\n\nSteuerung: WASD oder Pfeiltasten|r",

    -- Statusbar (Renderer)
    status_score    = "|cffaaaaaa Score:|r |cffffff00%d|r",
    status_best     = "|cffaaaaaa Best:|r |cffffd700%d|r",

    -- Overlay: Sieg (Renderer)
    result_win_title  = "|cffffd700Gewonnen!|r",
    -- Overlay: Verloren (Renderer)
    result_loss_title = "|cffff4444Game Over!|r",
    -- Overlay: gemeinsam (Renderer)
    result_sub        = "|cffaaaaaa Score:|r |cffffff00%d|r  |cffaaaaaa Länge:|r |cffffff00%d|r",
    result_new_hs     = "|cffffd700★ Neuer Highscore! ★|r",
    result_hs         = "|cffaaaaaa Highscore: |cffffff00%d|r",

    -- Settings-Panel: Box-Titel
    box_theme       = "Thema & Darstellung",
    box_sounds      = "Sounds",
    box_guide       = "Spielanleitung",

    -- Settings-Panel: Dropdown + Vorschau
    label_theme     = "Thema:",
    label_preview   = "|cffaaaaaa Vorschau (Kopf / Körper / Futter):|r",
    preview_head    = "Kopf",
    preview_body    = "Körper",
    preview_food    = "Futter",

    -- Settings-Panel: Sounds
    sound_enabled   = "Sounds aktiviert",
    sound_eat       = "Fressen",
    sound_die       = "Game Over",
    sound_start     = "Spielstart",

    -- Settings-Panel: Spielanleitung
    guide_goal      = "|cffffff00Ziel:|r Fresse so viel wie möglich, ohne dich selbst zu beißen!",
    guide_controls  = "|cffffff00Steuerung:|r WASD oder Pfeiltasten. Die Schlange bewegt sich automatisch.",
    guide_wrap      = "|cffffff00Rand:|r Die Schlange erscheint am gegenüberliegenden Rand wieder (Wrap-Around).",
    guide_score     = "|cffffff00Score:|r Easy ×1 · Normal ×2 · Hard ×4 Punkte pro gefreसsenem Bissen.",
    guide_diff      = "|cffffff00Schwierigkeit:|r Easy=20×20 (langsam), Normal=16×16 (mittel), Hard=10×10 (schnell).",
    guide_hint      = "|cffaaaaaa Highscore wird pro Schwierigkeit gespeichert und oben rechts im Spiel angezeigt.|r",

    -- Reset
    btn_reset       = "Einstellungen zurücksetzen",
})

-- ============================================================
-- ENGLISCH (enUS) – Fallback
-- ============================================================
GamingHub.RegisterLocale("SNAKE", "enUS", {

    -- Difficulty buttons
    diff_easy       = "Easy",
    diff_normal     = "Normal",
    diff_hard       = "Hard",

    -- Buttons
    btn_exit        = "Exit",
    btn_new_game    = "New Game",
    btn_new_game_ov = "▶ New Game",

    -- Hint
    hint_start      = "|cffaaaaaa Choose a difficulty to start.\n\nControls: WASD or Arrow Keys|r",

    -- Statusbar
    status_score    = "|cffaaaaaa Score:|r |cffffff00%d|r",
    status_best     = "|cffaaaaaa Best:|r |cffffd700%d|r",

    -- Overlay
    result_win_title  = "|cffffd700You won!|r",
    result_loss_title = "|cffff4444Game Over!|r",
    result_sub        = "|cffaaaaaa Score:|r |cffffff00%d|r  |cffaaaaaa Length:|r |cffffff00%d|r",
    result_new_hs     = "|cffffd700★ New Highscore! ★|r",
    result_hs         = "|cffaaaaaa Highscore: |cffffff00%d|r",

    -- Settings boxes
    box_theme       = "Theme & Display",
    box_sounds      = "Sounds",
    box_guide       = "How to Play",

    -- Dropdown + preview
    label_theme     = "Theme:",
    label_preview   = "|cffaaaaaa Preview (Head / Body / Food):|r",
    preview_head    = "Head",
    preview_body    = "Body",
    preview_food    = "Food",

    -- Sounds
    sound_enabled   = "Sounds enabled",
    sound_eat       = "Eating",
    sound_die       = "Game Over",
    sound_start     = "Game start",

    -- Guide
    guide_goal      = "|cffffff00Goal:|r Eat as much as possible without biting yourself!",
    guide_controls  = "|cffffff00Controls:|r WASD or Arrow Keys. The snake moves automatically.",
    guide_wrap      = "|cffffff00Borders:|r The snake reappears on the opposite side (wrap-around).",
    guide_score     = "|cffffff00Score:|r Easy ×1 · Normal ×2 · Hard ×4 points per food eaten.",
    guide_diff      = "|cffffff00Difficulty:|r Easy=20×20 (slow), Normal=16×16 (medium), Hard=10×10 (fast).",
    guide_hint      = "|cffaaaaaa Highscore is saved per difficulty and shown top-right during play.|r",

    -- Reset
    btn_reset       = "Reset settings",
})
