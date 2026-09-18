local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local RoundService = {}

local DataService
local WorldService
local CrystalService
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
    for player in pairs(participants) do
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if player.Parent == Players and humanoid and humanoid.Health > 0 then
            table.insert(alive, player)
        end
    end
    return alive
end

function RoundService.Init(dataService, worldService, crystalService, remoteFolder)
    DataService = dataService
    WorldService = worldService
    CrystalService = crystalService
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
                participants[player] = true
                if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                    player:LoadCharacter()
                    player.CharacterAdded:Wait()
                    task.wait(0.1)
                end
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
            end

            if #survivors == 1 then
                DataService.Add(survivors[1], "Coins", Config.RoundWinCoins)
                DataService.Add(survivors[1], "Wins", 1)
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
