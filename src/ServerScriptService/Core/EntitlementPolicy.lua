local EntitlementPolicy = {}

function EntitlementPolicy.CanUseObservatory(isVip)
    return isVip == true
end

function EntitlementPolicy.CanFastTravel(isVip, elo, unlockElo)
    return isVip == true and (tonumber(elo) or 0) >= (tonumber(unlockElo) or math.huge)
end

function EntitlementPolicy.RankedModifier()
    return 1
end

return EntitlementPolicy