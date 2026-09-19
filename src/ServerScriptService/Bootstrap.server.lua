local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local services = script.Parent.Services
local DataService = require(services.DataService)
local WorldService = require(services.WorldService)
local MatchService = require(services.MatchService)

local remotes = Instance.new("Folder")
remotes.Name = "BeatTheBotRemotes"
remotes.Parent = ReplicatedStorage
local state = Instance.new("RemoteEvent")
state.Name = "State"
state.Parent = remotes
local submit = Instance.new("RemoteEvent")
submit.Name = "Submit"
submit.Parent = remotes

DataService.Init()
MatchService.Init(DataService, WorldService, state, submit)
WorldService.Init(MatchService.Start)

local leaving = {}
local function leave(player)
    if leaving[player] then
        return
    end
    leaving[player] = true
    MatchService.Leave(player)
    DataService.Release(player)
    leaving[player] = nil
end

local function join(player)
    player.RespawnLocation = WorldService.Spawn
    player.CharacterRemoving:Connect(function()
        MatchService.Forfeit(player)
    end)
    task.spawn(DataService.Load, player)
end

Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(leave)
for _, player in ipairs(Players:GetPlayers()) do
    join(player)
end

task.spawn(function()
    while true do
        WorldService.Refresh(DataService)
        task.wait(5)
    end
end)

game:BindToClose(function()
    MatchService.Closing = true
    local pending = 0
    for player in pairs(DataService.Sessions) do
        pending += 1
        task.spawn(function()
            while leaving[player] do
                task.wait()
            end
            leave(player)
            pending -= 1
        end)
    end
    local deadline = os.clock() + 25
    while pending > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end)

print("Beat the Bot ready: local opponent, server-owned rules, four arenas.")
