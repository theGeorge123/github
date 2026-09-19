local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local services = script.Parent.Services

local DataService = require(services.DataService)
local WorldService = require(services.WorldService)
local MatchService = require(services.MatchService)
local EntitlementService = require(services.EntitlementService)
local FastTravelService = require(services.FastTravelService)
local CosmeticService = require(services.CosmeticService)

local previousRemotes = ReplicatedStorage:FindFirstChild("BeatTheBotRemotes")
if previousRemotes then
    previousRemotes:Destroy()
end

local remotes = Instance.new("Folder")
remotes.Name = "BeatTheBotRemotes"
remotes.Parent = ReplicatedStorage

local function remoteEvent(name)
    local event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = remotes
    return event
end

local state = remoteEvent("State")
local submit = remoteEvent("Submit")
local rematch = remoteEvent("Rematch")
local equipCosmetic = remoteEvent("EquipCosmetic")

local fallbackFolder = Instance.new("Folder")
fallbackFolder.Name = "BeatTheBotFallback"
fallbackFolder.Parent = workspace

local fallbackFloor = Instance.new("Part")
fallbackFloor.Name = "EmergencyFloor"
fallbackFloor.Size = Vector3.new(600, 4, 600)
fallbackFloor.Position = Vector3.new(0, -4, 0)
fallbackFloor.Anchored = true
fallbackFloor.CanCollide = true
fallbackFloor.Material = Enum.Material.Slate
fallbackFloor.Color = Color3.fromRGB(20, 25, 38)
fallbackFloor.Parent = fallbackFolder

local fallbackSpawn = Instance.new("SpawnLocation")
fallbackSpawn.Name = "EmergencySpawn"
fallbackSpawn.Size = Vector3.new(18, 1, 18)
fallbackSpawn.Position = Vector3.new(0, 1, 70)
fallbackSpawn.Anchored = true
fallbackSpawn.CanCollide = true
fallbackSpawn.Neutral = true
fallbackSpawn.Duration = 0
fallbackSpawn.Material = Enum.Material.Neon
fallbackSpawn.Color = Color3.fromRGB(73, 220, 236)
fallbackSpawn.Parent = fallbackFolder

WorldService.Spawn = fallbackSpawn

DataService.Init()
MatchService.Init(DataService, WorldService, state, submit, rematch)
FastTravelService.Init(DataService, WorldService, EntitlementService, state)
CosmeticService.Init(DataService, state, equipCosmetic)

local worldOk, worldError = pcall(function()
    WorldService.Init(MatchService.Start, MatchService.StartDaily)
end)

if worldOk then
    fallbackFolder:Destroy()

    for destinationId, prompt in pairs(WorldService.FastTravelPrompts) do
        prompt.Triggered:Connect(function(player)
            FastTravelService.Request(player, destinationId)
        end)
    end

    if WorldService.VIPPrompt then
        WorldService.VIPPrompt.Triggered:Connect(FastTravelService.RequestVIPObservatory)
    end
    if WorldService.VIPReturnPrompt then
        WorldService.VIPReturnPrompt.Triggered:Connect(FastTravelService.ReturnToPlaza)
    end

    print("BEAT_THE_BOT_WORLD_BUILD_OK", #WorldService.Arenas, "ranked arenas plus Daily Trial")
else
    warn("BEAT_THE_BOT_WORLD_BUILD_FAILED:", worldError)

    local sign = Instance.new("Part")
    sign.Name = "BuildFailureSign"
    sign.Size = Vector3.new(30, 12, 1)
    sign.Position = Vector3.new(0, 10, 55)
    sign.Anchored = true
    sign.CanCollide = false
    sign.Color = Color3.fromRGB(120, 30, 40)
    sign.Parent = fallbackFolder

    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.CanvasSize = Vector2.new(900, 360)
    surface.Parent = sign

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextWrapped = true
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = "WORLD BUILD FAILED\nOpen View > Output and copy the BEAT_THE_BOT_WORLD_BUILD_FAILED error."
    label.Parent = surface
end

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

local function placeCharacter(character)
    local rootPart = character:WaitForChild("HumanoidRootPart", 10)
    if not rootPart or not WorldService.Spawn or not WorldService.Spawn.Parent then
        return
    end

    task.defer(function()
        if character.Parent and WorldService.Spawn and WorldService.Spawn.Parent then
            character:PivotTo(WorldService.Spawn.CFrame + Vector3.new(0, 5, 0))
            local currentRoot = character:FindFirstChild("HumanoidRootPart")
            if currentRoot then
                currentRoot.AssemblyLinearVelocity = Vector3.zero
                currentRoot.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end

local function join(player)
    player.RespawnLocation = WorldService.Spawn
    EntitlementService.Publish(player)

    player.CharacterAdded:Connect(placeCharacter)
    player.CharacterRemoving:Connect(function()
        MatchService.Forfeit(player)
    end)

    if player.Character then
        task.spawn(placeCharacter, player.Character)
    end

    task.spawn(function()
        local profile = DataService.Load(player)
        if profile and player.Parent then
            EntitlementService.Publish(player)
            EntitlementService.GrantOwnedCosmetics(player, DataService)
            WorldService.Refresh(DataService)
        end
    end)
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

print("Beat the Bot v0.4 AI Citadel ready: server-owned progression, Daily Trial, mastery, Insight and placeholder VIP.")
if worldOk then
    print("BEAT_THE_BOT_STARTUP_OK")
end