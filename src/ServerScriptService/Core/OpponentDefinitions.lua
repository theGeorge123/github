local OpponentDefinitions = {}

local function reactions(overrides)
    local base = {
        requirements = { Trust = 8, Suspicion = 0 },
        permit = { Trust = 16, Suspicion = 0 },
        verify = { Trust = 24, Suspicion = -4 },
        escort = { Trust = 16, Suspicion = -4 },
        flattery = { Trust = 5, Suspicion = 1 },
        authority = { Trust = 10, Suspicion = 2 },
        urgency = { Trust = 5, Suspicion = 5 },
        joke = { Trust = 3, Suspicion = 0 },
        bribe = { Trust = 0, Suspicion = 40 },
        threat = { Trust = 0, Suspicion = 60 },
        irrelevant = { Trust = 0, Suspicion = 7 },
    }
    for intent, value in pairs(overrides or {}) do
        base[intent] = value
    end
    return base
end

local function objective(description, required, suggested, trust, successReply, failureReply)
    return {
        Description = description,
        RequiredTactics = required,
        SuggestedTactics = suggested or required,
        TrustToWin = trust or 80,
        SuccessReply = successReply or "Your explanation holds together. Proceed.",
        FailureReply = failureReply or "I am not satisfied with that explanation.",
    }
end

local opponents = {
    aldric = {
        Id = "aldric", DisplayName = "Sir Aldric", Name = "Sir Aldric", Title = "Professional",
        District = "great_gate", Rating = 1000, UnlockElo = 0,
        Persona = "A disciplined royal gatekeeper who values procedure, verifiable evidence, calm cooperation, and duty.",
        SpeakingStyle = "Precise, formal, restrained.",
        Voice = "Precise, formal, restrained. Ask concrete follow-up questions and rarely waste words.",
        Concerns = {
            { Id = "forged_permit", Prompt = "A courier used a forged royal permit yesterday, so Aldric is unusually focused on authenticity." },
            { Id = "curfew", Prompt = "The gate is close to curfew and Aldric has strict orders not to create undefendable exceptions." },
            { Id = "inspection", Prompt = "A royal inspector may arrive tonight, so Aldric wants every decision to survive scrutiny." },
        },
        Objective = objective(
            "Convince Aldric that your reason to pass the Great Gate is legitimate and verifiable.",
            { "permit", "verify", "escort" }, { "permit", "verify", "escort" }, 82,
            "Your story is verifiable, and supervised entry keeps the risk controlled. Proceed.",
            "Your case does not meet the gate standard."
        ),
        Reactions = reactions({
            requirements = { Trust = 10, Suspicion = 0 }, permit = { Trust = 22, Suspicion = 0 },
            verify = { Trust = 30, Suspicion = -4 }, escort = { Trust = 26, Suspicion = -6 },
            flattery = { Trust = 2, Suspicion = 2 }, authority = { Trust = 7, Suspicion = 3 },
            bribe = { Trust = 0, Suspicion = 35 }, threat = { Trust = 0, Suspicion = 55 },
        }),
        Visual = { Accent = "Gold", Archetype = "Knight" },
    },
    brann = {
        Id = "brann", DisplayName = "Captain Brann", Name = "Captain Brann", Title = "Proud",
        District = "great_gate", Rating = 1050, UnlockElo = 1000,
        Persona = "A proud veteran guard who cares about status, respect, reputation, and being treated as an expert.",
        SpeakingStyle = "Confident, dry, competitive.",
        Voice = "Confident, dry, competitive. Notice disrespect and reward arguments that acknowledge your judgment.",
        Concerns = {
            { Id = "fake_noble", Prompt = "Earlier today someone falsely claimed to be a noble. Brann is irritated by borrowed status." },
            { Id = "reputation", Prompt = "Another guard called Brann gullible. He is determined not to look easily fooled." },
            { Id = "commendation", Prompt = "Brann expects a promotion review and wants to demonstrate independent judgment." },
        },
        Objective = objective(
            "Convince Brann that your claim is credible while respecting his judgment rather than ordering him around.",
            { "permit", "verify", "flattery" }, { "flattery", "permit", "verify" }, 84,
            "You respected the job and gave me something I can defend. Go on.",
            "You have not given me a reason to stake my reputation on this."
        ),
        Reactions = reactions({
            requirements = { Trust = 8, Suspicion = 0 }, permit = { Trust = 16, Suspicion = 0 },
            verify = { Trust = 20, Suspicion = -2 }, escort = { Trust = 12, Suspicion = -2 },
            flattery = { Trust = 28, Suspicion = -2 }, authority = { Trust = 20, Suspicion = 2 },
            urgency = { Trust = 1, Suspicion = 9 }, joke = { Trust = 7, Suspicion = 1 },
            bribe = { Trust = 0, Suspicion = 42 }, threat = { Trust = 0, Suspicion = 65 },
        }),
        Visual = { Accent = "Crimson", Archetype = "Captain" },
    },
    elowen = {
        Id = "elowen", DisplayName = "Warden Elowen", Name = "Warden Elowen", Title = "Cautious",
        District = "great_gate", Rating = 1150, UnlockElo = 1100,
        Persona = "A cautious gate warden who worries about costly mistakes and values evidence, verification, low-risk compromises, and calm reassurance.",
        SpeakingStyle = "Calm, observant, skeptical.",
        Voice = "Calm, observant, skeptical. Ask what could go wrong and respond well to concrete risk reduction.",
        Concerns = {
            { Id = "smuggling", Prompt = "A smuggling attempt was caught at another gate this week." },
            { Id = "unknown_parcel", Prompt = "Elowen was warned about dangerous parcels and wants to understand the risk she accepts." },
            { Id = "rush_order", Prompt = "Her commander warned wardens not to let urgency override verification." },
        },
        Objective = objective(
            "Reduce Elowen's risk enough that she accepts a controlled entry.",
            { "permit", "verify", "escort" }, { "verify", "escort", "permit" }, 80,
            "You have reduced the uncertainty enough for a supervised entry.",
            "There is still too much unresolved risk."
        ),
        Reactions = reactions({
            requirements = { Trust = 10, Suspicion = 0 }, permit = { Trust = 18, Suspicion = 0 },
            verify = { Trust = 32, Suspicion = -8 }, escort = { Trust = 24, Suspicion = -8 },
            flattery = { Trust = 4, Suspicion = 1 }, authority = { Trust = 7, Suspicion = 4 },
            urgency = { Trust = 10, Suspicion = 6 }, bribe = { Trust = 0, Suspicion = 48 },
            threat = { Trust = 0, Suspicion = 72 },
        }),
        Visual = { Accent = "Cyan", Archetype = "Warden" },
    },
    customs_officer = {
        Id = "customs_officer", DisplayName = "Officer Vale", Name = "Officer Vale", Title = "Customs Officer",
        District = "customs", Rating = 1125, UnlockElo = 1100,
        Persona = "A methodical customs officer who compares stories against declarations, incentives, and internal consistency.",
        SpeakingStyle = "Administrative, concise, detail-oriented.",
        Voice = "Administrative and concise. Ask for details that can be cross-checked verbally.",
        Concerns = {
            { Id = "cargo_mismatch", Prompt = "A shipment with a false cargo category was caught this morning." },
            { Id = "rush_fee", Prompt = "A merchant recently disguised a bribe as an expedited inspection fee." },
            { Id = "manifest_gap", Prompt = "Several manifests have unexplained gaps this week." },
        },
        Objective = objective(
            "Convince customs that your declared story is legitimate and internally consistent.",
            { "requirements", "permit", "verify" }, nil, 82,
            "Your declaration is consistent enough to clear this desk.",
            "The declaration still has gaps I cannot clear."
        ),
        Reactions = reactions({
            requirements = { Trust = 18, Suspicion = -2 }, permit = { Trust = 22, Suspicion = 0 },
            verify = { Trust = 30, Suspicion = -7 }, escort = { Trust = 8, Suspicion = -1 },
            authority = { Trust = 6, Suspicion = 6 }, urgency = { Trust = 2, Suspicion = 10 },
        }),
        Visual = { Accent = "Amber", Archetype = "Officer" },
    },
    royal_clerk = {
        Id = "royal_clerk", DisplayName = "Clerk Mirelle", Name = "Clerk Mirelle", Title = "Royal Clerk",
        District = "customs", Rating = 1200, UnlockElo = 1150,
        Persona = "A careful royal clerk who values defensible authorization, precise wording, and reasoning that survives an audit.",
        SpeakingStyle = "Polite, exacting, procedural.",
        Voice = "Polite and exacting. Notice vague authority claims and ask for a defensible chain of reasoning.",
        Concerns = {
            { Id = "audit", Prompt = "An audit starts tomorrow, so Mirelle wants every unusual approval to be explainable." },
            { Id = "forged_order", Prompt = "A false royal order circulated last month." },
            { Id = "precedent", Prompt = "Mirelle worries that one exception will become a precedent." },
        },
        Objective = objective(
            "Persuade the clerk to authorize your request with a defensible reason and verification path.",
            { "requirements", "authority", "verify" }, nil, 84,
            "That authorization path is defensible. I can approve it.",
            "I cannot put my seal on reasoning this incomplete."
        ),
        Reactions = reactions({
            requirements = { Trust = 20, Suspicion = -2 }, permit = { Trust = 12, Suspicion = 0 },
            verify = { Trust = 28, Suspicion = -5 }, authority = { Trust = 26, Suspicion = 0 },
            escort = { Trust = 5, Suspicion = 1 }, flattery = { Trust = 2, Suspicion = 2 },
        }),
        Visual = { Accent = "Ivory", Archetype = "Clerk" },
    },
    guildmaster = {
        Id = "guildmaster", DisplayName = "Guildmaster Orren", Name = "Guildmaster Orren", Title = "Guildmaster",
        District = "customs", Rating = 1275, UnlockElo = 1200,
        Persona = "A commercially minded guild leader who asks who benefits, what can be verified, and whether cooperation protects the guild.",
        SpeakingStyle = "Negotiating, pragmatic, socially sharp.",
        Voice = "Pragmatic and socially sharp. Respond to aligned incentives but reject naked bribery.",
        Concerns = {
            { Id = "rival", Prompt = "A rival guild is trying to exploit the customs dispute." },
            { Id = "reputation", Prompt = "Orren needs to look cooperative without appearing weak." },
            { Id = "losses", Prompt = "Recent delays have cost the guild money." },
        },
        Objective = objective(
            "Convince the Guildmaster that cooperation benefits the guild without crossing into bribery.",
            { "flattery", "authority", "verify" }, nil, 86,
            "That arrangement protects the guild and gives me a reason to cooperate.",
            "You have not shown why the guild should take this risk."
        ),
        Reactions = reactions({
            flattery = { Trust = 22, Suspicion = -2 }, authority = { Trust = 24, Suspicion = 0 },
            verify = { Trust = 28, Suspicion = -4 }, permit = { Trust = 8, Suspicion = 0 },
            urgency = { Trust = 12, Suspicion = 2 }, bribe = { Trust = 0, Suspicion = 55 },
        }),
        Visual = { Accent = "Emerald", Archetype = "Merchant" },
    },
    detective = {
        Id = "detective", DisplayName = "Detective Sera", Name = "Detective Sera", Title = "Detective",
        District = "watch", Rating = 1300, UnlockElo = 1250,
        Persona = "An investigator who listens for contradictions, missing causes, and details that change under pressure.",
        SpeakingStyle = "Quiet, probing, economical.",
        Voice = "Quiet and probing. Repeat exact details when a possible contradiction appears.",
        Concerns = {
            { Id = "timeline", Prompt = "Sera suspects the reported timeline contains one impossible interval." },
            { Id = "witness", Prompt = "A witness gave an account that differs from the expected story." },
            { Id = "motive", Prompt = "Sera is less interested in the event than in why someone might lie about it." },
        },
        Objective = objective(
            "Survive detective questioning with a consistent explanation and concrete verification.",
            { "requirements", "verify", "escort" }, nil, 84,
            "Your account stayed consistent under pressure. I have no basis to hold you.",
            "Your account still does not survive basic questioning."
        ),
        Reactions = reactions({
            requirements = { Trust = 18, Suspicion = -3 }, verify = { Trust = 30, Suspicion = -8 },
            escort = { Trust = 22, Suspicion = -5 }, permit = { Trust = 5, Suspicion = 2 },
            flattery = { Trust = 0, Suspicion = 6 }, authority = { Trust = 5, Suspicion = 8 },
            joke = { Trust = 0, Suspicion = 4 },
        }),
        Visual = { Accent = "Blue", Archetype = "Detective" },
    },
    inspector = {
        Id = "inspector", DisplayName = "Inspector Cael", Name = "Inspector Cael", Title = "Inspector",
        District = "watch", Rating = 1380, UnlockElo = 1325,
        Persona = "A senior inspector who tests whether claims remain coherent when reframed from another angle.",
        SpeakingStyle = "Formal, analytical, relentless.",
        Voice = "Formal and analytical. Challenge assumptions rather than accepting surface confidence.",
        Concerns = {
            { Id = "inside_help", Prompt = "Cael suspects someone inside the administration is helping a fraud ring." },
            { Id = "false_authority", Prompt = "Several suspects used real official names in fabricated stories." },
            { Id = "pattern", Prompt = "Cael sees a pattern across cases other officers have missed." },
        },
        Objective = objective(
            "Give the Inspector a coherent account that survives verification and authority checks.",
            { "requirements", "verify", "authority" }, nil, 87,
            "The account survives the checks I can make. That is enough for now.",
            "The story breaks when I test the assumptions behind it."
        ),
        Reactions = reactions({
            verify = { Trust = 32, Suspicion = -6 }, authority = { Trust = 22, Suspicion = 1 },
            requirements = { Trust = 20, Suspicion = -2 }, permit = { Trust = 7, Suspicion = 3 },
            urgency = { Trust = 0, Suspicion = 10 }, flattery = { Trust = 0, Suspicion = 5 },
        }),
        Visual = { Accent = "Silver", Archetype = "Inspector" },
    },
    watch_captain = {
        Id = "watch_captain", DisplayName = "Captain Nyra", Name = "Captain Nyra", Title = "Watch Captain",
        District = "watch", Rating = 1460, UnlockElo = 1400,
        Persona = "The Watch Captain balances public safety, political pressure, and limited manpower. She values verifiable plans and controlled risk.",
        SpeakingStyle = "Commanding, strategic, unsentimental.",
        Voice = "Commanding and strategic. Ask for a plan officers could execute safely.",
        Concerns = {
            { Id = "thin_watch", Prompt = "Half the night watch is already committed elsewhere." },
            { Id = "royal_pressure", Prompt = "The palace wants fast action but supplied incomplete information." },
            { Id = "public_panic", Prompt = "Nyra is trying to prevent a rumor from becoming a panic." },
        },
        Objective = objective(
            "Persuade the Watch Captain that your proposed course is verifiable, controlled, and worth committing officers to.",
            { "authority", "verify", "escort" }, { "verify", "escort", "authority" }, 89,
            "That plan gives me control points and a reason to act. I will authorize it.",
            "I will not commit the Watch to a plan with this many open risks."
        ),
        Reactions = reactions({
            authority = { Trust = 24, Suspicion = 0 }, verify = { Trust = 30, Suspicion = -6 },
            escort = { Trust = 28, Suspicion = -5 }, requirements = { Trust = 12, Suspicion = 0 },
            urgency = { Trust = 8, Suspicion = 6 }, flattery = { Trust = 1, Suspicion = 4 },
            bribe = { Trust = 0, Suspicion = 65 }, threat = { Trust = 0, Suspicion = 80 },
        }),
        Visual = { Accent = "Violet", Archetype = "Captain" },
    },
}

local order = {
    "aldric", "brann", "elowen",
    "customs_officer", "royal_clerk", "guildmaster",
    "detective", "inspector", "watch_captain",
}

function OpponentDefinitions.Get(id)
    return opponents[id]
end

function OpponentDefinitions.All()
    local result = {}
    for _, id in ipairs(order) do
        table.insert(result, opponents[id])
    end
    return result
end

function OpponentDefinitions.Eligible(playerElo, districtId)
    local result = {}
    for _, id in ipairs(order) do
        local opponent = opponents[id]
        if playerElo >= opponent.UnlockElo and (not districtId or opponent.District == districtId) then
            table.insert(result, opponent)
        end
    end
    return result
end

function OpponentDefinitions.Select(playerElo, roll, districtId, avoidId)
    local eligible = OpponentDefinitions.Eligible(playerElo, districtId)
    assert(#eligible > 0, "No eligible opponents")

    if avoidId and #eligible > 1 then
        local alternatives = {}
        for _, opponent in ipairs(eligible) do
            if opponent.Id ~= avoidId then
                table.insert(alternatives, opponent)
            end
        end
        if #alternatives > 0 then
            eligible = alternatives
        end
    end

    local value = math.clamp(tonumber(roll) or 0, 0, 0.999999)
    return eligible[math.floor(value * #eligible) + 1]
end

function OpponentDefinitions.SelectConcern(opponent, roll)
    assert(opponent and opponent.Concerns and #opponent.Concerns > 0, "Opponent has no concerns")
    local value = math.clamp(tonumber(roll) or 0, 0, 0.999999)
    return opponent.Concerns[math.floor(value * #opponent.Concerns) + 1]
end

return OpponentDefinitions
