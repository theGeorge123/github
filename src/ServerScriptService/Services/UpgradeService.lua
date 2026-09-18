local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local UpgradeService = {}
local DataService

local function apply(player)
    local profile = DataService.Get(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not profile or not humanoid then
        return
    end

    humanoid.UseJumpPower = true
    humanoid.WalkSpeed = Config.BaseWalkSpeed + profile.Upgrades.Speed * Config.Upgrades.Speed.valuePerLevel
    humanoid.JumpPower = Config.BaseJumpPower + profile.Upgrades.Jump * Config.Upgrades.Jump.valuePerLevel
end

function UpgradeService.Init(dataService, remoteFolder)
    DataService = dataService

    remoteFolder.PurchaseUpgrade.OnServerInvoke = function(player, name)
        local upgrade = Config.Upgrades[name]
        local profile = DataService.Get(player)
        if not upgrade or not profile then
            return false, "Invalid upgrade"
        end

        local level = profile.Upgrades[name] or 0
        if level >= upgrade.maxLevel then
            return false, "Max level"
        end

        local cost = Config.getUpgradeCost(name, level)
        if not DataService.SpendCoins(player, cost) then
            return false, "Not enough Coins"
        end

        DataService.SetUpgrade(player, name, level + 1)
        apply(player)
        return true, "Upgraded"
    end

    local function hookPlayer(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.2)
            apply(player)
        end)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        hookPlayer(player)
    end
    Players.PlayerAdded:Connect(hookPlayer)
end

function UpgradeService.Apply(player)
    apply(player)
end

return UpgradeService
