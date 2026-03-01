--[[
    Gaming Hub
    StateMachine.lua
    Version: 0.1.0 (Core Skeleton)
]]

local GamingHub = _G.GamingHub
GamingHub.StateMachine = {}

local SM = GamingHub.StateMachine

SM.currentState = "IDLE"

SM.transitions = {
    IDLE = { INITIALIZING = true },
    INITIALIZING = { PLAYER_TURN = true },
    PLAYER_TURN = { CHECK_WIN = true },
    AI_TURN = { CHECK_WIN = true },
    CHECK_WIN = {
        PLAYER_TURN = true,
        AI_TURN = true,
        GAME_OVER = true
    },
    GAME_OVER = {
        IDLE = true,
        INITIALIZING = true
    }
}

function SM:GetState()
    return self.currentState
end

function SM:CanTransition(newState)
    local allowed = self.transitions[self.currentState]
    return allowed and allowed[newState]
end

function SM:SetState(newState)
    if self:CanTransition(newState) then
        self.currentState = newState
        return true
    else
        print("Invalid State Transition:", self.currentState, "->", newState)
        return false
    end
end

function SM:Reset()
    self.currentState = "IDLE"
end