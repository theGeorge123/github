local RankDefinitions = require(script.Parent.Parent.Core.RankDefinitions)
local DistrictDefinitions = require(script.Parent.Parent.Core.DistrictDefinitions)

local ProgressionService = {}

function ProgressionService.Rank(profile)
    return RankDefinitions.ForElo(profile and profile.Elo or 0)
end

function ProgressionService.CanAccess(profile, districtId)
    return profile ~= nil and DistrictDefinitions.CanAccess(profile.Elo, districtId)
end

function ProgressionService.Status(profile)
    local rank = ProgressionService.Rank(profile)
    return {
        Elo = profile and profile.Elo or 0,
        Rank = rank.Name,
        Insight = profile and profile.Insight or 0,
        DailyStreak = profile and profile.DailyTrial and profile.DailyTrial.Streak or 0,
    }
end

return ProgressionService