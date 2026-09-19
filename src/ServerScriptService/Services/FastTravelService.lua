local DistrictDefinitions = require(script.Parent.Parent.Core.DistrictDefinitions)
local EntitlementPolicy = require(script.Parent.Parent.Core.EntitlementPolicy)

local FastTravelService = {}

local dataService
local worldService
local entitlementService
local remote

local function notice(player, message)
    if player and player.Parent and remote then
        remote:FireClient(player, { Kind = "Notice", Message = message })
    end
end

local function pivot(player, target)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid or humanoid.Health <= 0 then
        return false
    end
    character:PivotTo(target)
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    return true
end

function FastTravelService.Init(data, world, entitlements, stateRemote)
    dataService = data
    worldService = world
    entitlementService = entitlements
    remote = stateRemote
end

function FastTravelService.Request(player, destinationId)
    local profile = dataService.Get(player)
    local district = DistrictDefinitions.Get(destinationId)
    if not profile or not district or not district.FastTravel then
        return false
    end

    local isVip = entitlementService.IsVIP(player)
    if not EntitlementPolicy.CanFastTravel(isVip, profile.Elo, district.UnlockElo) then
        notice(player, isVip and "That district is still locked by ELO." or "Fast travel is a VIP convenience. Walking remains free.")
        return false
    end

    local target = worldService.GetDestinationCFrame(destinationId)
    if not target then
        return false
    end

    return pivot(player, target)
end

function FastTravelService.RequestVIPObservatory(player)
    if not EntitlementPolicy.CanUseObservatory(entitlementService.IsVIP(player)) then
        notice(player, "The VIP Observatory is visible to everyone, but entry requires the placeholder VIP entitlement.")
        return false
    end
    local target = worldService.GetVIPCFrame()
    return target ~= nil and pivot(player, target) or false
end

function FastTravelService.ReturnToPlaza(player)
    local target = worldService.GetDestinationCFrame("central_plaza")
    return target ~= nil and pivot(player, target) or false
end

return FastTravelService