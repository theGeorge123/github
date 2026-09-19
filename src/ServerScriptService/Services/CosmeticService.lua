local CosmeticDefinitions = require(script.Parent.Parent.Core.CosmeticDefinitions)

local CosmeticService = {}

local dataService
local remote

local function notice(player, message)
    if player and player.Parent and remote then
        remote:FireClient(player, { Kind = "Notice", Message = message })
    end
end

function CosmeticService.Init(data, stateRemote, equipRemote)
    dataService = data
    remote = stateRemote

    equipRemote.OnServerEvent:Connect(function(player, itemId)
        if type(itemId) ~= "string" or #itemId > 80 then
            return
        end

        local item = CosmeticDefinitions.Get(itemId)
        if not item then
            return
        end

        local profile = dataService.Get(player)
        if not profile or not profile.Inventory or not profile.Inventory.Owned[itemId] then
            notice(player, "You do not own that cosmetic.")
            return
        end

        local updated = dataService.Mutate(player, "EquipCosmetic", {
            Id = item.Id,
            Category = item.Category,
        })

        if updated then
            notice(player, item.Name .. " equipped.")
        end
    end)
end

return CosmeticService