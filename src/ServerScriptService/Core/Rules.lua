local Rules = {}

Rules.Intents = table.freeze({
    requirements = true,
    permit = true,
    verify = true,
    escort = true,
    flattery = true,
    authority = true,
    urgency = true,
    joke = true,
    bribe = true,
    threat = true,
    irrelevant = true,
})

Rules.Strengths = table.freeze({
    weak = true,
    normal = true,
    strong = true,
})

Rules.Summaries = table.freeze({
    requirements = "Asked about the entry rules.",
    permit = "Presented a delivery permit.",
    verify = "Offered a way to verify the permit.",
    escort = "Offered to enter under supervision.",
    flattery = "Appealed to the Guard's pride.",
    authority = "Appealed to royal authority.",
    urgency = "Argued that the situation is urgent.",
    joke = "Tried humor.",
    bribe = "Offered a bribe.",
    threat = "Tried intimidation.",
    irrelevant = "Tried another argument.",
})

local strengthScale = {
    weak = 0.6,
    normal = 1,
    strong = 1.2,
}

local function clampRound(value)
    return math.round(math.clamp(value, -100, 100))
end

function Rules.New()
    return {
        Turns = 0,
        Trust = 0,
        Suspicion = 0,
        Status = "Playing",
        Intent = "irrelevant",
        RequirementsKnown = false,
        PermitPresented = false,
        SealVerified = false,
        EscortOffered = false,
        Used = {},
    }
end

function Rules.Hint(state, guard)
    if not state.PermitPresented then
        return "You are carrying an official permit. Evidence matters."
    end
    if not state.SealVerified then
        return "A claim becomes stronger when the Guard can verify it."
    end
    if guard and guard.RequiresEscort and not state.EscortOffered then
        return "A compromise that lowers the Guard's risk may help."
    end
    return "Read the Guard's personality. The same tactic will not work equally well on everyone."
end

function Rules.FallbackReply(guard, state, intent)
    local name = guard and guard.Name or "The Guard"
    if state.Status == "Won" then
        return "All right. Your permit checks out. The gate is open."
    end
    if state.Status == "Lost" and state.Suspicion >= 100 then
        return "Enough. I do not trust this. The gate stays closed."
    end
    if state.Status == "Lost" then
        return "Your eight moves are over. The gate stays closed."
    end

    local replies = {
        requirements = "Deliveries need a valid permit and a reason I can verify.",
        permit = "A permit helps, but paper alone is not proof.",
        verify = "Good. Give me something I can actually check.",
        escort = "Letting me supervise you would reduce the risk.",
        flattery = name .. " hears the compliment, but still watches you carefully.",
        authority = "Names and titles matter only if the story holds together.",
        urgency = "Urgency can be real, but rushing a guard is also suspicious.",
        joke = "I will admit that was not terrible. The gate is still closed.",
        bribe = "Trying to buy a royal guard is a bad idea.",
        threat = "Threatening me makes this very simple: no.",
        irrelevant = "That does not answer the problem in front of me.",
    }
    return replies[intent] or "Convince me."
end

local function objectiveReady(state, guard)
    if not state.PermitPresented or not state.SealVerified then
        return false
    end
    if guard.RequiresEscort and not state.EscortOffered then
        return false
    end
    return state.Trust >= guard.TrustToWin
end

function Rules.Advance(state, decision, guard, maxTurns)
    if state.Status ~= "Playing" then
        return nil, "This match has ended."
    end

    if type(decision) == "string" then
        decision = { Intent = decision, Strength = "normal" }
    end

    if type(decision) ~= "table" or not Rules.Intents[decision.Intent] or not Rules.Strengths[decision.Strength] then
        return nil, "Invalid opponent response."
    end
    if not guard or not guard.Reactions or not guard.Reactions[decision.Intent] then
        return nil, "Missing guard reaction."
    end

    local nextState = table.clone(state)
    nextState.Used = table.clone(state.Used or {})
    nextState.Turns += 1
    nextState.Intent = decision.Intent

    if decision.Intent == "requirements" then
        nextState.RequirementsKnown = true
    elseif decision.Intent == "permit" then
        nextState.PermitPresented = true
    elseif decision.Intent == "verify" and state.PermitPresented then
        nextState.SealVerified = true
    elseif decision.Intent == "escort" then
        nextState.EscortOffered = true
    end

    local reaction = guard.Reactions[decision.Intent]
    local trustDelta = reaction.Trust or 0
    local suspicionDelta = reaction.Suspicion or 0
    local scale = strengthScale[decision.Strength]

    trustDelta *= scale

    if nextState.Used[decision.Intent] then
        trustDelta *= 0.35
        suspicionDelta += 4
    end

    if decision.Intent == "verify" and not state.PermitPresented then
        trustDelta *= 0.35
        suspicionDelta += 5
    end

    nextState.Used[decision.Intent] = true
    nextState.Trust = math.clamp(state.Trust + clampRound(trustDelta), 0, 100)
    nextState.Suspicion = math.clamp(state.Suspicion + clampRound(suspicionDelta), 0, 100)

    if objectiveReady(nextState, guard) then
        nextState.Status = "Won"
    elseif nextState.Suspicion >= 100 then
        nextState.Status = "Lost"
    elseif nextState.Turns >= maxTurns then
        nextState.Status = "Lost"
    end

    return nextState, Rules.FallbackReply(guard, nextState, decision.Intent), {
        TrustDelta = nextState.Trust - state.Trust,
        SuspicionDelta = nextState.Suspicion - state.Suspicion,
    }
end

function Rules.Rating(rating, opponentRating, won, ratingK)
    local expected = 1 / (1 + 10 ^ ((opponentRating - rating) / 400))
    local delta = math.round(ratingK * ((won and 1 or 0) - expected))
    local nextRating = math.max(100, rating + delta)
    return nextRating, nextRating - rating
end

return Rules