local DistrictDefinitions = {}

local order = { "central_plaza", "great_gate", "customs", "watch", "royal_court", "oracle_spire" }

local districts = {
    central_plaza = { Id = "central_plaza", Name = "Central Plaza", UnlockElo = 0, Playable = false, FastTravel = true },
    great_gate = { Id = "great_gate", Name = "Great Gate", UnlockElo = 0, Playable = true, FastTravel = true },
    customs = { Id = "customs", Name = "Customs Quarter", UnlockElo = 1100, Playable = true, FastTravel = true },
    watch = { Id = "watch", Name = "Watch District", UnlockElo = 1250, Playable = true, FastTravel = true },
    royal_court = { Id = "royal_court", Name = "Royal Court", UnlockElo = 1500, Playable = false, Teaser = true, FastTravel = false },
    oracle_spire = { Id = "oracle_spire", Name = "Oracle Spire", UnlockElo = 1800, Playable = false, Teaser = true, FastTravel = false },
}

local arenaDistrict = {
    [1] = "great_gate",
    [2] = "great_gate",
    [3] = "customs",
    [4] = "watch",
}

function DistrictDefinitions.Get(id)
    return districts[id]
end

function DistrictDefinitions.ForArena(arenaId)
    return districts[arenaDistrict[arenaId]]
end

function DistrictDefinitions.NextPlayable(elo)
    elo = tonumber(elo) or 0
    for _, id in ipairs(order) do
        local district = districts[id]
        if district.Playable and district.UnlockElo > elo then
            return {
                Id = district.Id,
                Name = district.Name,
                UnlockElo = district.UnlockElo,
                RemainingElo = district.UnlockElo - elo,
            }
        end
    end
    return nil
end

function DistrictDefinitions.CanAccess(elo, districtId)
    local district = districts[districtId]
    return district ~= nil and (tonumber(elo) or 0) >= district.UnlockElo
end

function DistrictDefinitions.All()
    local result = {}
    for _, id in ipairs(order) do
        table.insert(result, districts[id])
    end
    return result
end

function DistrictDefinitions.FastTravelDestinations()
    local result = {}
    for _, id in ipairs(order) do
        if districts[id].FastTravel then
            table.insert(result, districts[id])
        end
    end
    return result
end

return DistrictDefinitions
