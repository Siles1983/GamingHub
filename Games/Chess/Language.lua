--[[
    Gaming Hub
    Games/Chess/Language.lua
    Version: 1.0.0

    Alle lokalisierbaren Strings fuer Mini-Schach.
    Zugriff: local L = GamingHub.GetLocaleTable("CHESS")
]]

-- ============================================================
-- DEUTSCH (deDE)
-- ============================================================
GamingHub.RegisterLocale("CHESS", "deDE", {

    -- Figurennamen (Renderer: Tooltip + CaptureBar + SettingsPanel)
    piece_king      = "König",
    piece_queen     = "Dame",
    piece_rook      = "Turm",
    piece_knight    = "Springer",
    piece_pawn      = "Bauer",

    -- Schwierigkeits-Buttons (Renderer)
    diff_easy       = "Classic",
    diff_normal     = "Pro",
    diff_hard       = "Insane",

    -- Buttons (Renderer)
    btn_exit        = "Beenden",
    btn_resign      = "Aufgeben",
    btn_new_game    = "Neues Spiel",

    -- Status-Texte (Renderer)
    status_checkmate = "|cffff4444Schachmatt!|r",
    status_stalemate = "|cffaaaaaa Patt!|r",
    status_check     = "|cffffff00⚠ Schach!|r",
    status_ai_turn   = "|cffaaaaaa KI denkt...|r",
    status_move      = "|cffaaaaaa Zug:|r %d",

    -- Hint (Renderer)
    hint_start      = "|cffaaaaaa Wähle eine Schwierigkeit um zu starten.|r",

    -- Capture Bars (Renderer)
    capture_taken   = "|cffffff00Geschlagen:|r",
    capture_lost    = "|cffff4444Verloren:|r",

    -- Game Over Overlay (Renderer)
    result_win      = "|cffffd700Sieg!|r",
    result_win_sub  = "Du hast den Horde-König geschlagen!\nZüge: ",
    result_loss     = "Niederlage!",
    result_loss_sub = "Der Horde-König hat gewonnen.\nZüge: ",
    result_draw     = "|cffaaaaaa Patt!|r",
    result_draw_sub = "Unentschieden – kein legaler Zug möglich.",

    -- Settings-Panel: Box-Titel
    box_legend      = "Figuren-Übersicht",
    box_ki_sounds   = "KI & Sounds",

    -- Settings-Panel: Figuren-Beschreibungen
    piece_king_desc   = "1 Feld in alle Richtungen.\nMuss geschützt werden.",
    piece_queen_desc  = "Beliebig weit: gerade + diagonal.\nMächtigste Figur.",
    piece_rook_desc   = "Beliebig weit: nur gerade\n(horizontal / vertikal).",
    piece_knight_desc = "L-Form: 2+1 Felder. Einzige\nFigur die überspringen kann.",
    piece_pawn_desc   = "1 Feld vorwärts. Schlägt\nnur diagonal. → Dame (letzte Reihe).",

    -- Settings-Panel: KI-Info
    info_classic_title = "|cffffd700Classic:|r",
    info_classic_text  = "Zufällige Züge.",
    info_classic_text2 = "Gut zum Kennenlernen.",
    info_pro_title     = "|cffffd700Pro:|r",
    info_pro_text1     = "Greedy – schlägt immer",
    info_pro_text2     = "wenn möglich, meidet Fallen.",
    info_insane_title  = "|cffffd700Insane:|r",
    info_insane_text1  = "Minimax (Tiefe 3) mit",
    info_insane_text2  = "Alpha-Beta. Denkt 3 Züge voraus.",
    info_diff_hint     = "|cffaaaaaa Schwierigkeit direkt im Spielfeld\nwählbar.|r",

    -- Settings-Panel: Sound
    sound_enabled   = "Sounds aktiviert",
    sound_hint      = "|cff888888Sounds nur bei aktivem Spiel-Sound.|r",

    -- Reset
    btn_reset       = "Auf Standard zurücksetzen",
})

-- ============================================================
-- ENGLISCH (enUS) – Fallback
-- ============================================================
GamingHub.RegisterLocale("CHESS", "enUS", {

    -- Piece names
    piece_king      = "King",
    piece_queen     = "Queen",
    piece_rook      = "Rook",
    piece_knight    = "Knight",
    piece_pawn      = "Pawn",

    -- Difficulty buttons
    diff_easy       = "Classic",
    diff_normal     = "Pro",
    diff_hard       = "Insane",

    -- Buttons
    btn_exit        = "Exit",
    btn_resign      = "Resign",
    btn_new_game    = "New Game",

    -- Status texts
    status_checkmate = "|cffff4444Checkmate!|r",
    status_stalemate = "|cffaaaaaa Stalemate!|r",
    status_check     = "|cffffff00⚠ Check!|r",
    status_ai_turn   = "|cffaaaaaa AI thinking...|r",
    status_move      = "|cffaaaaaa Move:|r %d",

    -- Hint
    hint_start      = "|cffaaaaaa Choose a difficulty to start.|r",

    -- Capture bars
    capture_taken   = "|cffffff00Captured:|r",
    capture_lost    = "|cffff4444Lost:|r",

    -- Game Over
    result_win      = "|cffffd700Victory!|r",
    result_win_sub  = "You defeated the Horde King!\nMoves: ",
    result_loss     = "Defeat!",
    result_loss_sub = "The Horde King has won.\nMoves: ",
    result_draw     = "|cffaaaaaa Draw!|r",
    result_draw_sub = "Stalemate – no legal move possible.",

    -- Settings boxes
    box_legend      = "Piece Overview",
    box_ki_sounds   = "AI & Sounds",

    -- Piece descriptions
    piece_king_desc   = "1 square in any direction.\nMust be protected.",
    piece_queen_desc  = "Any distance: straight + diagonal.\nMost powerful piece.",
    piece_rook_desc   = "Any distance: straight only\n(horizontal / vertical).",
    piece_knight_desc = "L-shape: 2+1 squares. Only\npiece that can jump over others.",
    piece_pawn_desc   = "1 square forward. Captures\ndiagonally only. → Queen (last rank).",

    -- AI info
    info_classic_title = "|cffffd700Classic:|r",
    info_classic_text  = "Random moves.",
    info_classic_text2 = "Good for learning the game.",
    info_pro_title     = "|cffffd700Pro:|r",
    info_pro_text1     = "Greedy – always captures",
    info_pro_text2     = "when possible, avoids traps.",
    info_insane_title  = "|cffffd700Insane:|r",
    info_insane_text1  = "Minimax (depth 3) with",
    info_insane_text2  = "Alpha-Beta. Looks 3 moves ahead.",
    info_diff_hint     = "|cffaaaaaa Difficulty chosen directly in the game area.|r",

    -- Sound
    sound_enabled   = "Sounds enabled",
    sound_hint      = "|cff888888Sounds only play if your in-game sound is active.|r",

    -- Reset
    btn_reset       = "Reset to defaults",
})
