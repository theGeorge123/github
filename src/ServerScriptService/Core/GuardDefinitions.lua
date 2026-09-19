local GuardDefinitions = {}

local guards = {
    aldric = {
        Id = "aldric",
        Name = "Sir Aldric",
        Title = "The Professional",
        Rating = 1000,
        UnlockElo = 0,
        TrustToWin = 82,
        RequiresEscort = true,
        Persona = "A disciplined royal gatekeeper. He values procedure, verifiable evidence, calm cooperation, and duty. He dislikes shortcuts, vague claims, bribes, and threats.",
        Reactions = {
            requirements = { Trust = 10, Suspicion = 0 },
            permit = { Trust = 22, Suspicion = 0 },
            verify = { Trust = 30, Suspicion = -4 },
            escort = { Trust = 26, Suspicion = -6 },
            flattery = { Trust = 2, Suspicion = 2 },
            authority = { Trust = 7, Suspicion = 3 },
            urgency = { Trust = 4, Suspicion = 5 },
            joke = { Trust = 1, Suspicion = 0 },
            bribe = { Trust = 0, Suspicion = 35 },
            threat = { Trust = 0, Suspicion = 55 },
            irrelevant = { Trust = 0, Suspicion = 7 },
        },
    },
    brann = {
        Id = "brann",
        Name = "Captain Brann",
        Title = "The Proud",
        Rating = 1050,
        UnlockElo = 1000,
        TrustToWin = 84,
        RequiresEscort = false,
        Persona = "A proud veteran guard who cares deeply about status, respect, reputation, and being treated as an expert. He still requires a real permit and verification, but responds strongly to sincere respect and credible authority.",
        Reactions = {
            requirements = { Trust = 8, Suspicion = 0 },
            permit = { Trust = 16, Suspicion = 0 },
            verify = { Trust = 20, Suspicion = -2 },
            escort = { Trust = 12, Suspicion = -2 },
            flattery = { Trust = 28, Suspicion = -2 },
            authority = { Trust = 20, Suspicion = 2 },
            urgency = { Trust = 1, Suspicion = 9 },
            joke = { Trust = 7, Suspicion = 1 },
            bribe = { Trust = 0, Suspicion = 42 },
            threat = { Trust = 0, Suspicion = 65 },
            irrelevant = { Trust = 0, Suspicion = 8 },
        },
    },
    elowen = {
        Id = "elowen",
        Name = "Warden Elowen",
        Title = "The Cautious",
        Rating = 1150,
        UnlockElo = 1100,
        TrustToWin = 80,
        RequiresEscort = true,
        Persona = "A cautious gate warden who worries about making a costly mistake. She values evidence, verification, low-risk compromises, and calm reassurance. Pressure or reckless urgency makes her suspicious.",
        Reactions = {
            requirements = { Trust = 10, Suspicion = 0 },
            permit = { Trust = 18, Suspicion = 0 },
            verify = { Trust = 32, Suspicion = -8 },
            escort = { Trust = 24, Suspicion = -8 },
            flattery = { Trust = 4, Suspicion = 1 },
            authority = { Trust = 7, Suspicion = 4 },
            urgency = { Trust = 10, Suspicion = 6 },
            joke = { Trust = 2, Suspicion = 1 },
            bribe = { Trust = 0, Suspicion = 48 },
            threat = { Trust = 0, Suspicion = 72 },
            irrelevant = { Trust = 0, Suspicion = 7 },
        },
    },
}

local order = { "aldric", "brann", "elowen" }

function GuardDefinitions.Get(id)
    return guards[id]
end

function GuardDefinitions.Eligible(playerElo)
    local result = {}
    for _, id in ipairs(order) do
        local guard = guards[id]
        if playerElo >= guard.UnlockElo then
            table.insert(result, guard)
        end
    end
    return result
end

function GuardDefinitions.Select(playerElo, roll)
    local eligible = GuardDefinitions.Eligible(playerElo)
    assert(#eligible > 0, "No eligible guards")
    local value = math.clamp(tonumber(roll) or 0, 0, 0.999999)
    local index = math.floor(value * #eligible) + 1
    return eligible[index]
end

return GuardDefinitions