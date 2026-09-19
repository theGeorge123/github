local DailyTrialDefinitions = require(script.Parent.Parent.Core.DailyTrialDefinitions)

local DailyTrialService = {}

function DailyTrialService.DayKey(unixTimestamp)
    return os.date("!%Y-%m-%d", unixTimestamp or os.time())
end

function DailyTrialService.DayOrdinal(unixTimestamp)
    return math.floor((unixTimestamp or os.time()) / 86400)
end

function DailyTrialService.Plan(profile, unixTimestamp)
    local dayKey = DailyTrialService.DayKey(unixTimestamp)
    local trial = DailyTrialDefinitions.ForDay(dayKey)
    local alreadyUsed = profile
        and profile.DailyTrial
        and profile.DailyTrial.OfficialDay == dayKey

    trial.DayOrdinal = DailyTrialService.DayOrdinal(unixTimestamp)
    trial.Mode = alreadyUsed and "DailyPractice" or "Daily"
    trial.Official = not alreadyUsed
    return trial
end

return DailyTrialService