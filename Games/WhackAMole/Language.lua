--[[
    Gaming Hub
    Games/WhackAMole/Language.lua
    Version: 1.0.0

    Alle lokalisierbaren Strings fuer Whack-a-Mole.
    Zugriff: local L = GamingHub.GetLocaleTable("WHACKAMOLE")
]]

-- ============================================================
-- DEUTSCH (deDE)
-- ============================================================
GamingHub.RegisterLocale("WHACKAMOLE", "deDE", {

    -- Schwierigkeits-Buttons (Renderer)
    diff_easy       = "Easy",
    diff_normal     = "Normal",
    diff_hard       = "Hard",

    -- Buttons (Renderer)
    btn_exit        = "Beenden",
    btn_retry       = "Nochmal!",
    btn_menu        = "Menü",

    -- Hint (Renderer)
    hint_start      = "|cffaaaaaa Wähle eine Schwierigkeit und haue die Moles!|r",

    -- HUD Labels (Renderer)
    hud_score       = "|cffffff00Score:|r",
    hud_time        = "|cffffff00Zeit:|r",
    hud_missed      = "|cffff4444Verpasst:|r",
    hud_highscore   = "|cffffff00Highscore:|r",

    -- Boom-Effekt (Renderer)
    boom_text       = "|cffFF0000BOOM!|r",

    -- GameOver-Panel (Renderer)
    go_title_bomb   = "|cffFF4444BOOM! Erwischt!|r",
    go_title_time   = "|cffffff00Zeit abgelaufen!|r",
    go_reason_bomb  = "|cffff9900Die Bombe hat dich erwischt!|r",
    go_score        = "Score: ",
    go_missed       = "Verpasst: ",
    go_highscore    = "Highscore: ",

    -- Settings-Panel: Box-Titel
    box_preview     = "Maulwurf-Vorschau",
    box_sounds      = "Sound",
    box_guide       = "Spielanleitung",

    -- Settings-Panel: Bombe-Hinweis
    bomb_hint       = "|cffFF4444Bombe: Treffer = Game Over!|r  (ab Score 30, 25% Chance)",

    -- Settings-Panel: Sounds
    sound_enabled   = "Soundeffekte aktiv",

    -- Settings-Panel: Spielanleitung
    guide_goal      = "|cffaaaaaa Ziel:|r Haue so viele Moles wie möglich in 30 Sekunden!",
    guide_click     = "|cffaaaaaa Klick:|r Auf ein Mole klicken = Punkte",
    guide_points    = "|cffaaaaaa Punkte:|r 10 × Schwierigkeitsfaktor (Easy ×1, Normal ×1.5, Hard ×2.5)",
    guide_bomb      = "|cffFF4444 Bombe:|r Ab Score 30 erscheinen Bomben (25% Chance) → NICHT anklicken!",
    guide_diff      = "|cffaaaaaa Schwierigkeit:|r Easy=2×2, Normal=3×3, Hard=4×4 Felder",
    guide_missed    = "|cffaaaaaa Verpasst:|r Jedes Mole das verschwindet ohne Hit = +1 Verpasst",
    guide_highscore = "|cffaaaaaa Highscore:|r Top 5 pro Schwierigkeit, pro Charakter",
    guide_timer     = "|cffaaaaaa Timer:|r Wird bei wenig Zeit rot — Tempo steigt!",
})

-- ============================================================
-- ENGLISCH (enUS) – Fallback
-- ============================================================
GamingHub.RegisterLocale("WHACKAMOLE", "enUS", {

    -- Difficulty buttons
    diff_easy       = "Easy",
    diff_normal     = "Normal",
    diff_hard       = "Hard",

    -- Buttons
    btn_exit        = "Exit",
    btn_retry       = "Retry!",
    btn_menu        = "Menu",

    -- Hint
    hint_start      = "|cffaaaaaa Choose a difficulty and whack the moles!|r",

    -- HUD Labels
    hud_score       = "|cffffff00Score:|r",
    hud_time        = "|cffffff00Time:|r",
    hud_missed      = "|cffff4444Missed:|r",
    hud_highscore   = "|cffffff00Highscore:|r",

    -- Boom effect
    boom_text       = "|cffFF0000BOOM!|r",

    -- GameOver panel
    go_title_bomb   = "|cffFF4444BOOM! Busted!|r",
    go_title_time   = "|cffffff00Time's up!|r",
    go_reason_bomb  = "|cffff9900The bomb got you!|r",
    go_score        = "Score: ",
    go_missed       = "Missed: ",
    go_highscore    = "Highscore: ",

    -- Settings boxes
    box_preview     = "Mole Preview",
    box_sounds      = "Sound",
    box_guide       = "How to Play",

    -- Bomb hint
    bomb_hint       = "|cffFF4444Bomb: Hit = Game Over!|r  (from score 30, 25% chance)",

    -- Sounds
    sound_enabled   = "Sound effects active",

    -- Guide
    guide_goal      = "|cffaaaaaa Goal:|r Whack as many moles as possible in 30 seconds!",
    guide_click     = "|cffaaaaaa Click:|r Clicking a mole = points",
    guide_points    = "|cffaaaaaa Points:|r 10 × difficulty factor (Easy ×1, Normal ×1.5, Hard ×2.5)",
    guide_bomb      = "|cffFF4444 Bomb:|r From score 30, bombs appear (25% chance) → DON'T click!",
    guide_diff      = "|cffaaaaaa Difficulty:|r Easy=2×2, Normal=3×3, Hard=4×4 grid",
    guide_missed    = "|cffaaaaaa Missed:|r Each mole that disappears without a hit = +1 missed",
    guide_highscore = "|cffaaaaaa Highscore:|r Top 5 per difficulty, per character",
    guide_timer     = "|cffaaaaaa Timer:|r Turns red when time is short — pace increases!",
})
