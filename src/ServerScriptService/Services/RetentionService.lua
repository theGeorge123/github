local RetentionService = {}

function RetentionService.Init(DataService, TelemetryService, remotes)
    remotes.ClaimDaily.OnServerInvoke = function(player)
        local ok, reward, streak = DataService.ClaimDaily(player)
        if ok then
            TelemetryService.Log(player, "DailyRewardClaimed", streak)
            return true, string.format("+%d Coins • %d day streak", reward, streak)
        end
        return false, reward
    end

    remotes.ClaimQuest.OnServerInvoke = function(player, questName)
        local ok, reward = DataService.ClaimQuest(player, questName)
        if ok then
            TelemetryService.Log(player, "DailyQuestClaimed", reward)
            return true, string.format("+%d Coins", reward)
        end
        return false, reward
    end
end

return RetentionService
