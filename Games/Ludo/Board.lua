--[[
    Gaming Hub – Mensch ärgere dich nicht (Ludo)
    Games/Ludo/Board.lua

    Das 11x11 Grid-System. Grid-Indizes 1-121 (Zeile×11+Spalte).
    Alle Pfad-Koordinaten sind Grid-Indizes.

    Brett-Layout (11x11, r=Zeile 1-11, c=Spalte 1-11):
    ┌─────────────────────────────────────┐
    │ BB  .  .  │  .  .  RR             │  ← Zeile 1-2: Ecken = Basen
    │ BB  .  .  │  .  .  RR             │
    │ .   .  .  │  .  .  .              │
    │ .   .  .  r  .  .  .              │  ← Zielgerade ROT (r)
    │ .   .  .  r  .  .  .              │
    │ .   b  b  b  b  b  .              │  ← Zielgerade BLAU
    │ .   .  .  g  .  .  .              │  ← Zielgerade GRÜN
    │ .   .  .  g  .  .  .              │
    │ .   .  .  │  .  .  .              │
    │ GG  .  .  │  .  .  GE GE          │
    │ GG  .  .  │  .  .  GE GE          │  ← Zeile 10-11: Ecken
    └─────────────────────────────────────┘

    Spieler-Farbzuordnung (fest):
      Spieler 1 = BLAU   → Start-Feld 45,  Home-Eingang bei Pfad-Index 1
      Spieler 2 = ROT    → Start-Feld 19,  Home-Eingang bei Pfad-Index 11
      Spieler 3 = GRÜN   → Start-Feld 75,  Home-Eingang bei Pfad-Index 21 (KI-Standard)
      Spieler 4 = GELB   → Start-Feld 97,  Home-Eingang bei Pfad-Index 31

    HINWEIS: Im 2-Spieler-Modus (Spieler vs KI):
      Spieler-Farbe: wählbar (Blau oder Rot)
      KI-Farbe:      die jeweils andere (Rot oder Blau)
      → Spieler 3 & 4 (Grün/Gelb) werden nicht genutzt

    Koordinatensystem: idx = (row-1)*11 + col,  row/col 1-basiert
]]

local GamingHub = _G.GamingHub
GamingHub.LUDO_Board = {}
local B = GamingHub.LUDO_Board

-- ============================================================
-- HAUPTPFAD – 40 Felder, im Uhrzeigersinn
-- Jeder Spieler startet 10 Felder versetzt.
-- Spieler 1 (BLAU)  → Offset 0  (Startfeld = MAIN_PATH[1]  = 45)
-- Spieler 2 (ROT)   → Offset 10 (Startfeld = MAIN_PATH[11] = 7)
-- Spieler 3 (GRÜN)  → Offset 20 (Startfeld = MAIN_PATH[21] = 77)
-- Spieler 4 (GELB)  → Offset 30 (Startfeld = MAIN_PATH[31] = 115)
-- ============================================================
B.MAIN_PATH = {
    -- Zeile 6 nach rechts (Blau-Arm, unten)
    45, 46, 47, 48, 49,           -- 1-5  (Blau-Startseite)
    -- Aufwärts rechte Spalte (Spalte 5→1)
    39, 28, 17, 6,                -- 6-9
    -- Zeile 1 nach rechts
    7,                            -- 10
    -- Aufwärts + Ecke oben rechts
    8,                            -- 11  (Rot-Start)
    19, 30, 41, 52,               -- 12-15
    -- Zeile 6 nach rechts
    53, 54, 55, 56,               -- 16-19
    -- Abwärts rechts
    67,                           -- 20
    78,                           -- 21  (Grün-Start)
    77, 76, 75, 74,               -- 22-25
    -- Untere rechte Ecke
    84, 95, 106, 117,             -- 26-29
    -- Zeile 11 nach links
    116,                          -- 30
    115,                          -- 31  (Gelb-Start)
    104, 93, 82, 71,              -- 32-35
    -- Aufwärts links
    70, 69, 68, 67,               -- 36-39  (achtung: Zeile 7 ist Grün-Zielgerade!)
    -- Zurück zu Blau-Startseite
    56,                           -- 40  (vor Blau-Eingang)
}

-- ============================================================
-- ZIELGERADEN – je 4 Felder pro Spieler (relPos 41-44)
-- ============================================================
B.HOME_PATH = {
    [1] = { 57, 58, 59, 60 },    -- BLAU:  Zeile 6, Spalten 2-5 (nach innen)
    [2] = { 12, 23, 34, 45 },    -- ROT:   Spalte 1, Zeilen 2-5  -- HINWEIS: wird korrigiert
    [3] = { 75, 64, 63, 62 },    -- GRÜN:  Zeile 7, Spalten 5-2 (nach innen)
    [4] = { 110,99, 88, 77 },    -- GELB:  Spalte 11→innen
}

-- Korrekte Zielgeraden (Spalte 6 = Mitte, je nach Spieler)
-- Blau   kommt von links (Zeile 6): Spalten 2,3,4,5 → idx 57,58,59,60
-- Rot    kommt von oben (Spalte 6): Zeilen 2,3,4,5 → idx 17,28,39,50  (col=6)
-- Grün   kommt von rechts(Zeile 7): Spalten 10,9,8,7 → idx 75(falsch)
-- Gelb   kommt von unten (Spalte 6): Zeilen 10,9,8,7 → idx 105,94,83,72
B.HOME_PATH = {
    [1] = { 57, 58, 59, 60 },    -- BLAU:  Zeile 6, col 2,3,4,5 → Mitte
    [2] = { 17, 28, 39, 50 },    -- ROT:   col 6, Zeile 2,3,4,5 → Mitte
    [3] = { 75, 74, 73, 72 },    -- GRÜN:  Zeile 7, col 10,9,8,7 → Mitte
    [4] = { 105,94, 83, 72 },    -- GELB:  col 6, Zeile 10,9,8,7 → Mitte
}

-- ============================================================
-- BASEN – 4 Startfelder pro Spieler (wo Figuren warten)
-- ============================================================
B.BASE_FIELDS = {
    [1] = { 1,  2,  12, 13  },   -- BLAU:  oben links (Zeilen 1-2, Spalten 1-2)
    [2] = { 10, 11, 21, 22  },   -- ROT:   oben rechts
    [3] = { 100,101,111,112 },   -- GRÜN:  unten links
    [4] = { 110,111,121,122 },   -- GELB:  unten rechts (122 existiert nicht – fix)
}
-- Fixup: 122 > 121, Gelb-Basis:
B.BASE_FIELDS[4] = { 110, 111, 120, 121 }

-- ============================================================
-- EINSTIEGSFELDER – das erste Feld auf dem MAIN_PATH je Spieler
-- = MAIN_PATH[ offset+1 ]
-- ============================================================
B.PLAYER_OFFSET = { [1]=0, [2]=10, [3]=20, [4]=30 }
B.PLAYER_ENTRY  = {
    [1] = B.MAIN_PATH[1],   -- 45
    [2] = B.MAIN_PATH[11],  -- 8
    [3] = B.MAIN_PATH[21],  -- 78
    [4] = B.MAIN_PATH[31],  -- 115
}

-- ============================================================
-- ZENTRALFELD – Würfel-Button-Position
-- Mitte des 11x11 Grids = Zeile 6, Spalte 6 = Index 61
-- ============================================================
B.CENTER_FIELD = 61

-- ============================================================
-- Felder die SICHER sind (Startfeld = kann nicht geschlagen werden)
-- ============================================================
B.SAFE_FIELDS = {}
for pID = 1, 4 do
    B.SAFE_FIELDS[ B.PLAYER_ENTRY[pID] ] = true
end

-- ============================================================
-- Hilfsfunktionen
-- ============================================================

-- Gibt den Grid-Index für relPos (1-44) eines Spielers zurück
function B:GetGridIndex(playerID, relPos)
    if relPos <= 40 then
        local offset   = B.PLAYER_OFFSET[playerID]
        local globalIdx = ((relPos + offset - 1) % 40) + 1
        return B.MAIN_PATH[globalIdx]
    else
        local homeIdx = relPos - 40
        local homePath = B.HOME_PATH[playerID]
        if homePath and homePath[homeIdx] then
            return homePath[homeIdx]
        end
        return nil
    end
end

-- Gibt zurück ob ein Grid-Feld zum Spielfeld gehört (Pfad/Basis/Home)
function B:IsGameField(gridIdx)
    -- Hauptpfad
    for _, v in ipairs(B.MAIN_PATH) do
        if v == gridIdx then return true end
    end
    -- Zielgeraden
    for _, path in ipairs(B.HOME_PATH) do
        for _, v in ipairs(path) do
            if v == gridIdx then return true end
        end
    end
    -- Basen
    for _, base in ipairs(B.BASE_FIELDS) do
        for _, v in ipairs(base) do
            if v == gridIdx then return true end
        end
    end
    -- Zentrum (Würfel)
    if gridIdx == B.CENTER_FIELD then return true end
    return false
end

-- Alle Felder die sichtbar sind (für Renderer)
function B:GetAllVisibleFields()
    local fields = {}
    local seen   = {}
    local function add(idx)
        if idx and idx >= 1 and idx <= 121 and not seen[idx] then
            seen[idx] = true
            fields[#fields+1] = idx
        end
    end
    for _, v in ipairs(B.MAIN_PATH) do add(v) end
    for _, path in ipairs(B.HOME_PATH) do
        for _, v in ipairs(path) do add(v) end
    end
    for _, base in ipairs(B.BASE_FIELDS) do
        for _, v in ipairs(base) do add(v) end
    end
    add(B.CENTER_FIELD)
    return fields
end

-- Spieler-Farben (RGB)
B.PLAYER_COLORS = {
    [1] = { 0.2, 0.5, 1.0 },   -- BLAU
    [2] = { 1.0, 0.2, 0.2 },   -- ROT
    [3] = { 0.2, 0.9, 0.2 },   -- GRÜN
    [4] = { 1.0, 0.9, 0.1 },   -- GELB
}

B.PLAYER_NAMES = { [1]="Blau", [2]="Rot", [3]="Grün", [4]="Gelb" }
