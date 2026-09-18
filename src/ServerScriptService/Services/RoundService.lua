local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local RoundService = {}

local DataService
local WorldService
local CrystalService
local TelemetryService
local remotes
local roundNumber = 0

local function broadcast(phase, timeLeft)
    remotes.RoundState:FireAllClients({
        phase = phase,
        timeLeft = timeLeft,
        round = roundNumber,
    })
end

local function alivePlayers(participants)
    local alive = {}
    for player, isAlive in pairs(participants) do
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if isAlive and player.Parent == Players and humanoid and humanoid.Health > 0 then
            table.insert(alive, player)
        end
    end
    return alive
end

local function markDeath(participants, player)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    humanoid.Died:Connect(function()
        participants[player] = false
    end)
end

function RoundService.Init(dataService, worldService, crystalService, telemetryService, remoteFolder)
    DataService = dataService
    WorldService = worldService
    CrystalService = crystalService
    TelemetryService = telemetryService
    remotes = remoteFolder
end

function RoundService.Start()
    task.spawn(function()
        while true do
            WorldService.ResetHazard()
            CrystalService.Stop()

            for t = Config.Intermission, 0, -1 do
                broadcast("Intermission", t)
                task.wait(1)
            end

            roundNumber += 1
            local participants = {}

            for index, player in ipairs(Players:GetPlayers()) do
                if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                    player:LoadCharacter()
                    player.CharacterAdded:Wait()
                    task.wait(0.1)
                end

                participants[player] = true
                markDeath(participants, player)
                DataService.AddQuestProgress(player, "Rounds", 1)
                TelemetryService.Log(player, "RoundStarted", roundNumber)
                WorldService.TeleportToArena(player, index)
            end

            CrystalService.Start()

            for elapsed = 0, Config.RoundDuration do
                local remaining = Config.RoundDuration - elapsed
                broadcast("Round", remaining)
                WorldService.SetHazardProgress(elapsed / Config.RoundDuration)

                if elapsed > 8 and #alivePlayers(participants) <= 1 and next(participants) ~= nil then
                    break
                end

                task.wait(1)
            end

            CrystalService.Stop()

            local survivors = alivePlayers(participants)
            for _, player in ipairs(survivors) do
                DataService.Add(player, "Coins", Config.RoundSurvivalCoins)
                DataService.AddQuestProgress(player, "Survive", 1)
                TelemetryService.Log(player, "RoundSurvived", roundNumber)
            end

            if #survivors == 1 then
                DataService.Add(survivors[1], "Coins", Config.RoundWinCoins)
                DataService.Add(survivors[1], "Wins", 1)
                TelemetryService.Log(survivors[1], "RoundWon", roundNumber)
            end

            broadcast("RoundOver", 5)
            task.wait(5)

            for _, player in ipairs(Players:GetPlayers()) do
                player:LoadCharacter()
            end
        end
    end)
end

return RoundService
