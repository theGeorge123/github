local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CrystalService = {}

local folder
local running = false
local DataService
local WorldService
local TelemetryService
local sessionCollected = {}

local function milestone(value)
    return value == 1 or value == 10 or value == 25 or value == 50
end

local function createCrystal()
    if not running then return end

    local crystal = Instance.new("Part")
    crystal.Name = "Crystal"
    crystal.Size = Vector3.new(2.5, 4, 2.5)
    crystal.CFrame = CFrame.new(WorldService.RandomArenaPosition(4)) * CFrame.Angles(0, math.rad(45), math.rad(45))
    crystal.Color = Color3.fromRGB(80, 235, 255)
    crystal.Material = Enum.Material.Neon
    crystal.Anchored = true
    crystal.CanCollide = false
    crystal.Parent = folder

    local light = Instance.new("PointLight")
    light.Color = crystal.Color
    light.Brightness = 1.5
    light.Range = 10
    light.Parent = crystal

    local claimed = false
    crystal.Touched:Connect(function(hit)
        if claimed or not running then return end
        local character = hit:FindFirstAncestorOfClass("Model")
        local player = character and Players:GetPlayerFromCharacter(character)
        if not player then return end

        claimed = true
        DataService.Add(player, "Coins", Config.CoinReward)
        DataService.Add(player, "XP", Config.XPReward)
        DataService.AddQuestProgress(player, "Collect", 1)

        sessionCollected[player] = (sessionCollected[player] or 0) + 1
        if milestone(sessionCollected[player]) then
            TelemetryService.Log(player, "CrystalMilestone", sessionCollected[player])
        end

        crystal:Destroy()

        task.delay(Config.CrystalRespawnDelay, function()
            if running then
                createCrystal()
            end
        end)
    end)
end

function CrystalService.Init(dataService, worldService, telemetryService)
    DataService = dataService
    WorldService = worldService
    TelemetryService = telemetryService

    folder = Instance.new("Folder")
    folder.Name = "Crystals"
    folder.Parent = workspace

    Players.PlayerRemoving:Connect(function(player)
        sessionCollected[player] = nil
    end)

    RunService.Heartbeat:Connect(function(dt)
        if not running then return end

        for _, crystal in ipairs(folder:GetChildren()) do
            if crystal:IsA("BasePart") then
                crystal.CFrame *= CFrame.Angles(0, dt * 1.8, 0)

                local bestRoot
                local bestDistance = math.huge
                for _, player in ipairs(Players:GetPlayers()) do
                    local profile = DataService.Get(player)
                    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    local level = profile and profile.Upgrades.Magnet or 0
                    local radius = 4 + level * Config.Upgrades.Magnet.valuePerLevel
                    if root and level > 0 then
                        local distance = (root.Position - crystal.Position).Magnitude
                        if distance < radius and distance < bestDistance then
                            bestDistance = distance
                            bestRoot = root
                        end
                    end
                end

                if bestRoot then
                    local target = bestRoot.Position + Vector3.new(0, 1.5, 0)
                    crystal.Position = crystal.Position:Lerp(target, math.clamp(dt * 7, 0, 1))
                end
            end
        end
    end)
end

function CrystalService.Start()
    running = true
    folder:ClearAllChildren()
    for _ = 1, Config.CrystalCount do
        createCrystal()
    end
end

function CrystalService.Stop()
    running = false
    folder:ClearAllChildren()
end

return CrystalService
