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

local services = script.Parent:WaitForChild("Services")

local DataService = require(services.DataService)
local WorldService = require(services.WorldService)
local UpgradeService = require(services.UpgradeService)
local CrystalService = require(services.CrystalService)
local RoundService = require(services.RoundService)

WorldService.Init()
DataService.Init(remotes)
UpgradeService.Init(DataService, remotes)
CrystalService.Init(DataService, WorldService)
RoundService.Init(DataService, WorldService, CrystalService, remotes)
RoundService.Start()

print("Crystal Rush server started")
