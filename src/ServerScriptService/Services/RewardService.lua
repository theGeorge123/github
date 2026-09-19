local RewardDefinitions = require(script.Parent.Parent.Core.RewardDefinitions)
local MasteryService = require(script.Parent.MasteryService)
local DailyTrialService = require(script.Parent.DailyTrialService)

local RewardService = {}

local function insightFor(mode, won)
    local values = RewardDefinitions.Insight
    if mode == "Daily" then
        return values.DailyCompletion + (won and values.DailyWin or 0)
    elseif mode == "DailyPractice" then
        return values.DailyPractice
    end
    return values.RankedCompletion + (won and values.RankedWin or 0)
end

function RewardService.BuildMetadata(profile, match, won, isVip)
    local mode = match.Mode or "Ranked"
    local insight = insightFor(mode, won)

    if isVip then
        insight = math.floor(insight * RewardDefinitions.Insight.VIPMultiplier + 0.5)
    end

    local mastery = MasteryService.Project(profile, match.Opponent.Id, won)
    local dayKey = match.DayKey or DailyTrialService.DayKey()
    local reward = {
        Insight = insight,
        MasteryXP = mastery.XP,
        MasteryLevel = mastery.Level,
        Items = mastery.Items,
    }

    if won and mode ~= "DailyPractice" then
        reward.FirstWinDayKey = dayKey
        reward.FirstWinBonus = RewardDefinitions.Insight.FirstWinOfDay
    end

    return {
        Ranked = mode == "Ranked",
        Mode = mode,
        OpponentId = match.Opponent.Id,
        DayKey = match.DayKey,
        DayOrdinal = match.DayOrdinal,
        Messages = match.State.Turns,
        CompletionTime = math.max(0, (workspace:GetServerTimeNow() - match.StartedAt)),
        FinalTrust = match.State.Trust,
        FinalSuspicion = match.State.Suspicion,
        Reward = reward,
        StreakRewards = RewardDefinitions.DailyStreak,
    }
end

return RewardService