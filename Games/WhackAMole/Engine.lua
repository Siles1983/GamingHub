-- Whack-a-Mole – Games/WhackAMole/Engine.lua

GamingHub = GamingHub or {}
GamingHub.WAM_Engine = {}
local E = GamingHub.WAM_Engine

E.state         = "IDLE"
E._board        = nil
E._ticker       = nil
E._spawnTicker  = nil

-- ============================================================
-- StartGame
-- ============================================================
function E:StartGame(difficulty)
    self:StopGame()

    local L = GamingHub.WAM_Logic
    local R = GamingHub.WAM_Renderer
    local S = GamingHub.WAM_Settings

    self._board = L:NewBoard(difficulty)
    self._board.gameActive = true
    self.state  = "PLAYING"

    R:EnterPlayState(self._board)

    -- 1s Countdown-Ticker
    self._ticker = C_Timer.NewTicker(1, function()
        if E.state ~= "PLAYING" then return end
        local b = E._board
        b.timeLeft = b.timeLeft - 1
        R:UpdateHUD(b)
        if b.timeLeft <= 0 then
            E:_gameOver(false)
        end
    end)

    -- Spawn-Ticker
    local spawnInterval = L:GetSpawnInterval(self._board)
    self._spawnTicker = C_Timer.NewTicker(spawnInterval, function()
        if E.state ~= "PLAYING" then return end
        E:_spawnMole()
        -- Doppel-Spawn bei wenig Zeit
        if E._board and E._board.timeLeft <= 15 then
            if math.random(100) <= 35 then
                C_Timer.After(0.25, function()
                    if E.state == "PLAYING" then E:_spawnMole() end
                end)
            end
        end
    end)

    if S:Get("sound") then PlaySound(774) end
end

-- ============================================================
-- StopGame
-- ============================================================
function E:StopGame()
    if self._ticker      then self._ticker:Cancel();      self._ticker      = nil end
    if self._spawnTicker then self._spawnTicker:Cancel(); self._spawnTicker = nil end
    self.state  = "IDLE"
    self._board = nil
end

-- ============================================================
-- _spawnMole
-- ============================================================
function E:_spawnMole()
    local b = self._board
    if not b then return end
    local L = GamingHub.WAM_Logic
    local R = GamingHub.WAM_Renderer

    local free = L:GetFreeHoles(b)
    if #free == 0 then return end

    local slot   = free[math.random(#free)]
    local r, c   = slot.r, slot.c
    local isBomb, icon = L:PickSpawnType(b)

    b.holes[r][c].active = true
    b.holes[r][c].isBomb = isBomb
    b.holes[r][c].icon   = icon

    R:ShowMole(r, c, icon, isBomb)

    -- Auto-hide nach moleSpeed
    C_Timer.After(b.moleSpeed, function()
        if E.state ~= "PLAYING" then return end
        if b.holes[r] and b.holes[r][c] and b.holes[r][c].active then
            L:MoleMissed(b, r, c)
            R:HideMole(r, c)
            R:UpdateHUD(b)
        end
    end)
end

-- ============================================================
-- OnMoleClick – von Renderer aufgerufen
-- ============================================================
function E:OnMoleClick(r, c)
    if self.state ~= "PLAYING" then return end
    local b = self._board
    if not b then return end

    local L = GamingHub.WAM_Logic
    local R = GamingHub.WAM_Renderer
    local S = GamingHub.WAM_Settings

    local result, pts = L:HitMole(b, r, c)

    if result == "bomb" then
        R:HideMole(r, c)
        R:ShowBoomEffect(r, c)
        if S:Get("sound") then PlaySound(8959) end
        C_Timer.After(0.6, function()
            E:_gameOver(true)
        end)
    elseif result == "hit" then
        R:HideMole(r, c)
        R:ShowHitEffect(r, c, "+" .. (pts or 0))
        R:UpdateHUD(b)
        if S:Get("sound") then PlaySound(1115) end
    end
end

-- ============================================================
-- _gameOver
-- ============================================================
function E:_gameOver(hitBomb)
    if self._ticker      then self._ticker:Cancel();      self._ticker      = nil end
    if self._spawnTicker then self._spawnTicker:Cancel(); self._spawnTicker = nil end
    self.state = "GAMEOVER"

    local b = self._board
    if not b then return end

    local S = GamingHub.WAM_Settings
    local R = GamingHub.WAM_Renderer

    S:SubmitScore(b.difficulty, b.score, b.missed)

    -- Alle aktiven Moles verstecken
    for r = 1, b.gridSize do
        for c = 1, b.gridSize do
            if b.holes[r][c].active then
                b.holes[r][c].active = false
                R:HideMole(r, c)
            end
        end
    end

    if S:Get("sound") then PlaySound(847) end

    R:ShowGameOver(b, hitBomb)
end
