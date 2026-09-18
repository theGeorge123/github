local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldService = {}

local world
local hazard
local arena

local function makePart(name, size, position, color, material, parent)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.Position = position
    p.Color = color
    p.Material = material
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

function WorldService.Init()
    local old = Workspace:FindFirstChild("CrystalRushWorld")
    if old then old:Destroy() end

    world = Instance.new("Folder")
    world.Name = "CrystalRushWorld"
    world.Parent = Workspace

    Lighting.ClockTime = 20
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(45, 40, 70)
    Lighting.OutdoorAmbient = Color3.fromRGB(70, 60, 110)

    local lobby = makePart(
        "Lobby",
        Vector3.new(70, 2, 70),
        Vector3.new(0, 45, -125),
        Color3.fromRGB(45, 49, 70),
        Enum.Material.Slate,
        world
    )

    local lobbySpawn = Instance.new("SpawnLocation")
    lobbySpawn.Name = "LobbySpawn"
    lobbySpawn.Size = Vector3.new(8, 1, 8)
    lobbySpawn.Position = lobby.Position + Vector3.new(0, 2, 0)
    lobbySpawn.Anchored = true
    lobbySpawn.Neutral = true
    lobbySpawn.Color = Color3.fromRGB(120, 90, 255)
    lobbySpawn.Material = Enum.Material.Neon
    lobbySpawn.Parent = world

    arena = makePart(
        "Arena",
        Vector3.new(Config.ArenaSize, 3, Config.ArenaSize),
        Vector3.new(0, Config.ArenaY, 0),
        Color3.fromRGB(35, 38, 55),
        Enum.Material.Slate,
        world
    )

    for i = 1, 18 do
        local angle = (i / 18) * math.pi * 2
        local radius = 45 + ((i % 3) * 12)
        local height = 3 + ((i % 4) * 2)
        local pillar = makePart(
            "Pillar",
            Vector3.new(8, height, 8),
            Vector3.new(math.cos(angle) * radius, Config.ArenaY + 2 + height / 2, math.sin(angle) * radius),
            Color3.fromRGB(70, 75, 110),
            Enum.Material.Metal,
            world
        )
        pillar.Orientation = Vector3.new(0, math.deg(angle), 0)
    end

    local core = makePart(
        "Core",
        Vector3.new(14, 18, 14),
        Vector3.new(0, Config.ArenaY + 10, 0),
        Color3.fromRGB(88, 70, 255),
        Enum.Material.Neon,
        world
    )
    core.Shape = Enum.PartType.Cylinder
    core.Orientation = Vector3.new(0, 0, 90)

    hazard = makePart(
        "Hazard",
        Vector3.new(Config.ArenaSize + 35, 3, Config.ArenaSize + 35),
        Vector3.new(0, Config.HazardStartY, 0),
        Color3.fromRGB(255, 60, 90),
        Enum.Material.Neon,
        world
    )
    hazard.Transparency = 0.2

    hazard.Touched:Connect(function(hit)
        local character = hit:FindFirstAncestorOfClass("Model")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end)
end

function WorldService.GetArena()
    return arena
end

function WorldService.GetHazard()
    return hazard
end

function WorldService.ResetHazard()
    if hazard then
        hazard.Position = Vector3.new(0, Config.HazardStartY, 0)
    end
end

function WorldService.SetHazardProgress(alpha)
    if not hazard then return end
    local y = Config.HazardStartY + (Config.HazardEndY - Config.HazardStartY) * math.clamp(alpha, 0, 1)
    hazard.Position = Vector3.new(0, y, 0)
end

function WorldService.RandomArenaPosition(height)
    local half = Config.ArenaSize / 2 - 10
    return Vector3.new(
        math.random(-half, half),
        Config.ArenaY + (height or 4),
        math.random(-half, half)
    )
end

function WorldService.TeleportToArena(player, index)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local angle = ((index or 1) / math.max(1, #game.Players:GetPlayers())) * math.pi * 2
    local pos = Vector3.new(math.cos(angle) * 55, Config.ArenaY + 6, math.sin(angle) * 55)
    root.CFrame = CFrame.new(pos, Vector3.new(0, Config.ArenaY, 0))
end

return WorldService
