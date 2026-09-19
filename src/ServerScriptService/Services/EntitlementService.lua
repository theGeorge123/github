local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local EntitlementService = {}

local function contains(list, userId)
    for _, candidate in ipairs(list or {}) do
        if tonumber(candidate) == userId then
            return true
        end
    end
    return false
end

function EntitlementService.IsFounder(player)
    return player ~= nil and contains(Config.Entitlements.FounderUserIds, player.UserId)
end

function EntitlementService.IsVIP(player)
    return player ~= nil
        and (EntitlementService.IsFounder(player) or contains(Config.Entitlements.VIPUserIds, player.UserId))
end

function EntitlementService.Publish(player)
    local founder = EntitlementService.IsFounder(player)
    player:SetAttribute("Founder", founder)
    player:SetAttribute("VIP", founder or EntitlementService.IsVIP(player))
end

function EntitlementService.GrantOwnedCosmetics(player, dataService)
    local items = {}
    if EntitlementService.IsVIP(player) then
        table.insert(items, "vip_nameplate")
        table.insert(items, "vip_aura")
    end
    if EntitlementService.IsFounder(player) then
        table.insert(items, "founder_title")
    end
    if #items > 0 then
        dataService.Mutate(player, "GrantItems", {
            ClaimKey = "entitlements:v1",
            Items = items,
        })
    end
end

return EntitlementService