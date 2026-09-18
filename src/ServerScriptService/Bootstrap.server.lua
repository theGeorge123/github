local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreate(className, name, parent)
    local object = parent:FindFirstChild(name)
    if object then return object end
    object = Instance.new(className)
    object.Name = name
    object.Parent = parent
    return object
end

local remotes = getOrCreate("Folder", "Remotes", ReplicatedStorage)
getOrCreate("RemoteEvent", "RoundState", remotes)
getOrCreate("RemoteEvent", "DataUpdated", remotes)
getOrCreate("RemoteFunction", "PurchaseUpgrade", remotes)
getOrCreate("RemoteFunction", "GetProfile", remotes)
getOrCreate("RemoteFunction", "ClaimDaily", remotes)
getOrCreate("RemoteFunction", "ClaimQuest", remotes)

local services = script.Parent:WaitForChild("Services")

local DataService = require(services.DataService)
local WorldService = require(services.WorldService)
local UpgradeService = require(services.UpgradeService)
local CrystalService = require(services.CrystalService)
local RoundService = require(services.RoundService)
local RetentionService = require(services.RetentionService)
local TelemetryService = require(services.TelemetryService)

WorldService.Init()
DataService.Init(remotes)
RetentionService.Init(DataService, TelemetryService, remotes)
UpgradeService.Init(DataService, TelemetryService, remotes)
CrystalService.Init(DataService, WorldService, TelemetryService)
RoundService.Init(DataService, WorldService, CrystalService, TelemetryService, remotes)
RoundService.Start()

local function logJoin(player)
    TelemetryService.Log(player, "SessionStarted", 1)
end

Players.PlayerAdded:Connect(logJoin)
for _, player in ipairs(Players:GetPlayers()) do
    logJoin(player)
end

print("Crystal Rush server started")
