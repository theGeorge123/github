local RewardDefinitions = require(script.Parent.Parent.Core.RewardDefinitions)
local CosmeticDefinitions = require(script.Parent.Parent.Core.CosmeticDefinitions)

local MasteryService = {}

function MasteryService.LevelForXP(xp)
    xp = math.max(0, tonumber(xp) or 0)
    local thresholds = RewardDefinitions.Mastery.Thresholds
    local level = 0
    for candidate = 1, 4 do
        if xp >= (thresholds[candidate] or math.huge) then
            level = candidate
        end
    end
    return level
end

function MasteryService.Project(profile, opponentId, won)
    local current = profile and profile.Mastery and profile.Mastery[opponentId] or nil
    local currentXP = current and tonumber(current.XP) or 0
    local currentLevel = current and tonumber(current.Level) or 0
    local gain = RewardDefinitions.Mastery.AttemptXP + (won and RewardDefinitions.Mastery.WinXP or 0)
    local nextXP = currentXP + gain
    local nextLevel = MasteryService.LevelForXP(nextXP)
    local items = {}

    for level = currentLevel + 1, nextLevel do
        local kind = RewardDefinitions.Mastery.Milestones[level]
        if kind then
            table.insert(items, CosmeticDefinitions.MasteryItem(kind, opponentId))
        end
    end

    return {
        XP = gain,
        Level = nextLevel,
        Items = items,
    }
end

return MasteryService