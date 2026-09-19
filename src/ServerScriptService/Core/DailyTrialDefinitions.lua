local DailyTrialDefinitions = {}

local trials = {
    { OpponentId = "aldric", Scenario = "Late courier", Objective = "Convince Aldric that a late delivery is legitimate without asking him to ignore procedure.", HiddenConcern = "A forged permit was discovered earlier today." },
    { OpponentId = "customs_officer", Scenario = "Unusual cargo declaration", Objective = "Explain an unusual cargo declaration clearly enough for customs to accept the story.", HiddenConcern = "The officer was warned that smugglers are using overly rehearsed explanations." },
    { OpponentId = "royal_clerk", Scenario = "Emergency authorization", Objective = "Persuade the clerk to authorize a request while giving them a defensible reasoning trail.", HiddenConcern = "The clerk expects an audit tomorrow morning." },
    { OpponentId = "detective", Scenario = "Contradiction check", Objective = "Survive questioning without contradicting your earlier account.", HiddenConcern = "The detective believes one detail in the initial report is false." },
    { OpponentId = "elowen", Scenario = "Risk-managed entry", Objective = "Reduce Elowen's risk enough that she accepts a supervised compromise.", HiddenConcern = "A dangerous parcel warning has made her unusually cautious." },
}

local function hashDay(dayKey)
    local value = 0
    for index = 1, #dayKey do
        value = (value * 131 + string.byte(dayKey, index)) % 2147483647
    end
    return value
end

function DailyTrialDefinitions.ForDay(dayKey)
    assert(type(dayKey) == "string" and #dayKey >= 8, "Invalid day key")
    local trial = trials[(hashDay(dayKey) % #trials) + 1]
    return {
        OpponentId = trial.OpponentId,
        Scenario = trial.Scenario,
        Objective = trial.Objective,
        HiddenConcern = trial.HiddenConcern,
        DayKey = dayKey,
    }
end

return DailyTrialDefinitions