local TesterPolicy = {}

-- Server-only private playtest access. This does not change ELO, rewards, VIP,
-- or public progression. Remove an account here when its playtest ends.
local testerUserIds = {
    [1753929845] = true,
}

function TesterPolicy.IsTester(player)
    return player ~= nil and testerUserIds[player.UserId] == true
end

return TesterPolicy
