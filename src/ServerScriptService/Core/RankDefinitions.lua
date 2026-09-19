local RankDefinitions = {}

local ranks = {
    { MinElo = 0, Name = "Outsider" },
    { MinElo = 1000, Name = "Courier" },
    { MinElo = 1100, Name = "Envoy" },
    { MinElo = 1250, Name = "Investigator" },
    { MinElo = 1500, Name = "Diplomat" },
    { MinElo = 1800, Name = "Mastermind" },
    { MinElo = 2000, Name = "AI Breaker" },
}

function RankDefinitions.ForElo(elo)
    local selected = ranks[1]
    elo = tonumber(elo) or 0
    for _, rank in ipairs(ranks) do
        if elo >= rank.MinElo then
            selected = rank
        else
            break
        end
    end
    return selected
end

function RankDefinitions.All()
    return ranks
end

return RankDefinitions