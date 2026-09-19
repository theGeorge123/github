local Rules = {}

Rules.Intents = table.freeze({
    requirements = true, permit = true, verify = true, escort = true,
    flattery = true, authority = true, urgency = true, joke = true,
    bribe = true, threat = true, irrelevant = true,
})

Rules.Strengths = table.freeze({
    weak = true, normal = true, strong = true,
})

Rules.Summaries = table.freeze({
    requirements = "Asked what standard had to be satisfied.",
    permit = "Explained credentials or authorization.",
    verify = "Offered a concrete way to verify the story.",
    escort = "Offered a supervised, lower-risk compromise.",
    flattery = "Appealed to the opponent's pride or reputation.",
    authority = "Appealed to credible authority.",
    urgency = "Argued that delay creates a real problem.",
    joke = "Used humor to lower the tension.",
    bribe = "Offered something improper.",
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

function Rules.Hint(state, opponent)
    local objective = opponent and opponent.Objective
    if objective then
        for _, intent in ipairs(objective.SuggestedTactics or objective.RequiredTactics or {}) do
            if not (state.Used or {})[intent] then
                local hints = {
                    requirements = "Ask what standard they are actually trying to satisfy.",
                    permit = "Explain what your credentials mean and why the claim should be believed.",
                    verify = "Offer a concrete detail, contact, code, or explanation they can check in conversation.",
                    escort = "A supervised or reversible compromise can reduce the opponent's risk.",
                    flattery = "Respect can help with proud opponents, but it still needs a credible argument behind it.",
                    authority = "Authority works best when you explain why it is credible rather than merely naming it.",
                    urgency = "Explain the cost of delay without demanding that the opponent ignore their responsibility.",
                }
                if hints[intent] then
                    return hints[intent]
                end
            end
        end
    end
    return "Respond to the opponent's latest concern and keep your account consistent."
end

function Rules.FallbackReply(opponent, state, intent)
    local objective = opponent and opponent.Objective

    if state.Status == "Won" then
        return objective and objective.SuccessReply or "All right. Your explanation holds together."
    end
    if state.Status == "Lost" and state.Suspicion >= 100 then
        return "Enough. I do not trust this explanation."
    end
    if state.Status == "Lost" then
        return objective and objective.FailureReply or "You are out of moves, and I am not convinced."
    end

    local replies = {
        requirements = "Good. Start with the standard that actually has to be satisfied.",
        permit = "Credentials are still a claim. Give me a reason I can verify.",
        verify = "A concrete verification path makes the story stronger.",
        escort = "A supervised compromise can reduce the risk.",
        flattery = "Respect is noted, but I still expect a credible case.",
        authority = "Authority matters only if the claim is specific and believable.",
        urgency = "Urgency may be real, but pressure can also hide a weak story.",
        joke = "That lowers the tension. It does not resolve the underlying question.",
        bribe = "Offering me something improper makes your position worse.",
        threat = "Threatening me ends any benefit of the doubt.",
        irrelevant = "That does not answer the concern in front of you.",
    }
    return replies[intent] or "Convince me."
end

local function objectiveReady(state, opponent)
    local objective = opponent and opponent.Objective
    if objective then
        for _, intent in ipairs(objective.RequiredTactics or {}) do
            if not (state.Used or {})[intent] then
                return false
            end
        end
        return state.Trust >= (objective.TrustToWin or 80)
    end

    if not state.PermitPresented or not state.SealVerified then
        return false
    end
    if opponent and opponent.RequiresEscort and not state.EscortOffered then
        return false
    end
    return state.Trust >= ((opponent and opponent.TrustToWin) or 80)
end

function Rules.Advance(state, decision, opponent, maxTurns)
    if state.Status ~= "Playing" then
        return nil, "This match has ended."
    end

    if type(decision) == "string" then
        decision = { Intent = decision, Strength = "normal" }
    end

    if type(decision) ~= "table" or not Rules.Intents[decision.Intent] or not Rules.Strengths[decision.Strength] then
        return nil, "Invalid opponent response."
    end
    if not opponent or not opponent.Reactions or not opponent.Reactions[decision.Intent] then
        return nil, "Missing opponent reaction."
    end

    local nextState = table.clone(state)
    nextState.Used = table.clone(state.Used or {})
    nextState.Turns += 1
    nextState.Intent = decision.Intent

    if decision.Intent == "requirements" then
        nextState.RequirementsKnown = true
    elseif decision.Intent == "permit" then
        nextState.PermitPresented = true
    elseif decision.Intent == "verify" then
        nextState.SealVerified = true
    elseif decision.Intent == "escort" then
        nextState.EscortOffered = true
    end

    local reaction = opponent.Reactions[decision.Intent]
    local trustDelta = (reaction.Trust or 0) * strengthScale[decision.Strength]
    local suspicionDelta = reaction.Suspicion or 0

    if nextState.Used[decision.Intent] then
        trustDelta *= 0.35
        suspicionDelta += 4
    end

    if decision.Intent == "verify" and not state.PermitPresented and not opponent.Objective then
        trustDelta *= 0.35
        suspicionDelta = math.max(0, suspicionDelta) + 5
        nextState.SealVerified = false
    end

    nextState.Used[decision.Intent] = true
    nextState.Trust = math.clamp(state.Trust + clampRound(trustDelta), 0, 100)
    nextState.Suspicion = math.clamp(state.Suspicion + clampRound(suspicionDelta), 0, 100)

    if objectiveReady(nextState, opponent) then
        nextState.Status = "Won"
    elseif nextState.Suspicion >= 100 or nextState.Turns >= maxTurns then
        nextState.Status = "Lost"
    end

    return nextState, Rules.FallbackReply(opponent, nextState, decision.Intent), {
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