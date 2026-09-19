local Rules = {}

Rules.Intents = table.freeze({
    requirements = true, permit = true, verify = true, escort = true,
    joke = true, bribe = true, threat = true, unknown = true,
})

Rules.Summaries = table.freeze({
    requirements = "Asked about entry requirements.",
    permit = "Presented a delivery permit.",
    verify = "Suggested checking the royal seal.",
    escort = "Offered to enter under escort.",
    joke = "Tried a joke.",
    bribe = "Offered gold.",
    threat = "Tried intimidation.",
    unknown = "Tried a different argument.",
})

local sequence = { "requirements", "permit", "verify", "escort" }
local replies = {
    "Deliveries need a permit. Do you have one?",
    "A permit! But it might be fake. How can I check it?",
    "The royal seal is genuine. How do I keep an eye on you inside?",
    "An escort is a fair compromise. The gate is open. You win!",
}
local hints = {
    "Start by asking what is required to enter.",
    "You are a courier with a delivery permit. Show it.",
    "Your permit has a royal seal. Offer a way to verify it.",
    "Offer to let the guard escort you inside.",
}

function Rules.New()
    return { Turns = 0, Progress = 0, Suspicion = 0, Status = "Playing", Intent = "unknown" }
end

function Rules.Hint(state)
    return hints[state.Progress + 1] or "The gate is open!"
end

function Rules.Advance(state, intent, maxTurns)
    if state.Status ~= "Playing" then
        return nil, "This match has ended."
    end
    if not Rules.Intents[intent] then
        return nil, "Invalid opponent response."
    end
    local nextState = table.clone(state)
    nextState.Turns += 1
    nextState.Intent = intent
    local reply
    if intent == sequence[state.Progress + 1] then
        nextState.Progress += 1
        reply = replies[nextState.Progress]
    elseif intent == "threat" or intent == "bribe" then
        nextState.Suspicion = math.min(100, state.Suspicion + (intent == "threat" and 40 or 25))
        reply = "That makes me suspicious, not convinced. Follow the entry procedure."
    elseif intent == "joke" then
        reply = "To reach the high court? Ha! Funny, but the entry rules still apply."
    else
        reply = "That is not what I need right now. " .. Rules.Hint(state)
    end
    if nextState.Progress == 4 then
        nextState.Status = "Won"
    elseif nextState.Suspicion >= 100 then
        nextState.Status = "Lost"
        reply = "I cannot trust you. The gate stays closed. I win this time."
    elseif nextState.Turns >= maxTurns then
        nextState.Status = "Lost"
        reply = "Your eight moves are up. The gate stays closed. Try a different approach!"
    end
    return nextState, reply
end

function Rules.Rating(rating, opponentRating, won, ratingK)
    local expected = 1 / (1 + 10 ^ ((opponentRating - rating) / 400))
    local delta = math.round(ratingK * ((won and 1 or 0) - expected))
    local nextRating = math.max(100, rating + delta)
    return nextRating, nextRating - rating
end

return Rules
