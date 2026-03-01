-- Hangman Engine.lua

GamingHub = GamingHub or {}
GamingHub.HGM_Engine = {}
local E = GamingHub.HGM_Engine

local Logic    = GamingHub.HGM_Logic
local Settings = GamingHub.HGM_Settings

E.board = nil
E.state = "IDLE"

function E:StartGame()
    local Renderer = GamingHub.HGM_Renderer
    if not Renderer then return end

    local cat     = Settings:Get("category")
    local maxErr  = Settings:GetMaxErrors()
    local entry   = Logic:PickWord(cat)

    self.board = Logic:NewBoard(entry, maxErr)
    self.state = "PLAYING"

    -- Tastatur + Runen zurücksetzen, dann rendern
    Renderer:_resetKeyboard()
    Renderer:_resetRunes(maxErr)
    Renderer:RenderBoard(self.board)
    GamingHub.Engine:Emit("HGM_GAME_STARTED", {})
end

function E:GuessLetter(letter)
    if self.state ~= "PLAYING" then return end
    local Renderer = GamingHub.HGM_Renderer

    local found = Logic:GuessLetter(self.board, letter)

    if Settings:Get("sound") then
        PlaySound(found and 857 or 847)
    end

    Renderer:RenderBoard(self.board)

    if self.board.won then
        self.state = "WON"
        Settings:IncrWins()
        if Settings:Get("sound") then PlaySound(888765) end
        Renderer:ShowGameOver(true, self.board)
        GamingHub.Engine:Emit("HGM_GAME_WON", {})
    elseif self.board.lost then
        self.state = "LOST"
        Settings:IncrLosses()
        if Settings:Get("sound") then PlaySound(846) end
        Renderer:ShowGameOver(false, self.board)
        GamingHub.Engine:Emit("HGM_GAME_LOST", {})
    end
end

function E:StopGame()
    self.board = nil
    self.state = "IDLE"
    local Renderer = GamingHub.HGM_Renderer
    if Renderer then Renderer:EnterIdleState() end
end
