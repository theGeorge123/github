local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local WorldService = { Arenas = {}, HumanWins = 0, BotWins = 0 }
local root
local leaderboard
local championLabel
local championId
local championVersion = 0
local championModel

local palette = {
    Night = Color3.fromRGB(11, 16, 30),
    Navy = Color3.fromRGB(18, 25, 45),
    Slate = Color3.fromRGB(43, 50, 65),
    Stone = Color3.fromRGB(92, 96, 105),
    StoneDark = Color3.fromRGB(59, 63, 73),
    Cyan = Color3.fromRGB(73, 220, 236),
    Gold = Color3.fromRGB(255, 199, 89),
    Warm = Color3.fromRGB(255, 132, 64),
    Red = Color3.fromRGB(236, 78, 89),
    Green = Color3.fromRGB(74, 222, 128),
    White = Color3.fromRGB(238, 244, 255),
}

local function part(name, size, position, color, parent, material)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.Position = position
    object.Anchored = true
    object.Color = color
    object.Material = material or Enum.Material.SmoothPlastic
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent or root
    return object
end

local function board(name, position, size, accent)
    local panel = part(name, size, position, palette.Navy, root, Enum.Material.Metal)
    panel.CFrame *= CFrame.Angles(0, math.pi, 0)

    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.CanvasSize = Vector2.new(1000, 600)
    surface.LightInfluence = 0
    surface.Parent = panel

    local backing = Instance.new("Frame")
    backing.Size = UDim2.fromScale(1, 1)
    backing.BackgroundColor3 = palette.Night
    backing.BackgroundTransparency = 0.08
    backing.BorderSizePixel = 0
    backing.Parent = surface

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 8
    stroke.Color = accent or palette.Cyan
    stroke.Transparency = 0.25
    stroke.Parent = backing

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(0.92, 0.9)
    label.Position = UDim2.fromScale(0.04, 0.05)
    label.BackgroundTransparency = 1
    label.TextColor3 = accent or palette.Cyan
    label.Font = Enum.Font.GothamBold
    label.TextSize = 38
    label.TextWrapped = true
    label.RichText = false
    label.TextStrokeTransparency = 0.8
    label.Parent = backing
    return label
end

local function configureLighting()
    Lighting.ClockTime = 18.4
    Lighting.Brightness = 2.4
    Lighting.Ambient = Color3.fromRGB(58, 66, 91)
    Lighting.OutdoorAmbient = Color3.fromRGB(88, 96, 122)
    Lighting.ColorShift_Top = Color3.fromRGB(255, 196, 156)
    Lighting.ShadowSoftness = 0.22
    pcall(function()
        Lighting.LightingStyle = Enum.LightingStyle.Realistic
    end)

    for _, child in ipairs(Lighting:GetChildren()) do
        if child.Name == "BeatTheBotAtmosphere" or child.Name == "BeatTheBotBloom" or child.Name == "BeatTheBotColor" then
            child:Destroy()
        end
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "BeatTheBotAtmosphere"
    atmosphere.Density = 0.28
    atmosphere.Offset = 0.08
    atmosphere.Haze = 1.2
    atmosphere.Glare = 0.2
    atmosphere.Color = Color3.fromRGB(184, 194, 222)
    atmosphere.Decay = Color3.fromRGB(255, 151, 102)
    atmosphere.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "BeatTheBotBloom"
    bloom.Intensity = 0.45
    bloom.Size = 20
    bloom.Threshold = 1.1
    bloom.Parent = Lighting

    local color = Instance.new("ColorCorrectionEffect")
    color.Name = "BeatTheBotColor"
    color.Brightness = -0.02
    color.Contrast = 0.08
    color.Saturation = 0.05
    color.TintColor = Color3.fromRGB(242, 239, 255)
    color.Parent = Lighting
end

local function torch(position, parent)
    local pole = part("TorchPole", Vector3.new(0.5, 5, 0.5), position, palette.StoneDark, parent, Enum.Material.Metal)
    local bowl = part("TorchBowl", Vector3.new(1.4, 0.5, 1.4), position + Vector3.new(0, 2.7, 0), palette.Gold, parent, Enum.Material.Metal)

    local flamePart = part("TorchFlame", Vector3.new(0.6, 0.7, 0.6), position + Vector3.new(0, 3.4, 0), palette.Warm, parent, Enum.Material.Neon)
    flamePart.CanCollide = false

    local fire = Instance.new("Fire")
    fire.Size = 4
    fire.Heat = 5
    fire.Color = Color3.fromRGB(255, 170, 70)
    fire.SecondaryColor = Color3.fromRGB(255, 75, 25)
    fire.Parent = flamePart

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 176, 92)
    light.Brightness = 2.2
    light.Range = 18
    light.Shadows = true
    light.Parent = flamePart

    return pole, bowl, flamePart
end

local function tower(center, side, parent)
    local x = center.X + side * 12
    local base = part("Tower", Vector3.new(13, 22, 13), Vector3.new(x, 11, center.Z - 14), palette.Stone, parent, Enum.Material.Slate)

    for y = 4, 20, 4 do
        local band = part("StoneBand", Vector3.new(13.5, 0.35, 13.5), Vector3.new(x, y, center.Z - 14), palette.StoneDark, parent, Enum.Material.Slate)
        band.CanCollide = false
    end

    for _, dx in ipairs({ -4.5, 0, 4.5 }) do
        part("Battlement", Vector3.new(2.5, 3, 2.5), Vector3.new(x + dx, 23.5, center.Z - 14), palette.StoneDark, parent, Enum.Material.Slate)
    end

    torch(Vector3.new(x - side * 4.2, 8, center.Z - 6.5), parent)
    return base
end

local function banner(position, text, parent)
    local bannerPart = part("Banner", Vector3.new(5, 8, 0.35), position, Color3.fromRGB(39, 62, 103), parent, Enum.Material.Fabric)
    bannerPart.CanCollide = false

    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.CanvasSize = Vector2.new(300, 450)
    surface.LightInfluence = 0
    surface.Parent = bannerPart

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = palette.Gold
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Parent = surface
end

local function fallbackGuard(center, parent)
    local model = Instance.new("Model")
    model.Name = "CastleGuard"
    model.Parent = parent

    local torso = part("Torso", Vector3.new(3.4, 4.6, 2.1), center + Vector3.new(0, 4.7, -7), Color3.fromRGB(69, 82, 108), model, Enum.Material.Metal)
    local head = part("Head", Vector3.new(2.2, 2.2, 2.2), center + Vector3.new(0, 8.1, -7), Color3.fromRGB(202, 167, 132), model)
    head.Shape = Enum.PartType.Ball
    part("Helmet", Vector3.new(2.8, 1.2, 2.8), center + Vector3.new(0, 9.1, -7), palette.StoneDark, model, Enum.Material.Metal)
    part("Chestplate", Vector3.new(3.7, 3.1, 2.35), center + Vector3.new(0, 5, -7), palette.Stone, model, Enum.Material.Metal)
    part("Belt", Vector3.new(3.6, 0.45, 2.3), center + Vector3.new(0, 3.7, -7), palette.Gold, model, Enum.Material.Metal)

    for _, offset in ipairs({ -1, 1 }) do
        local leg = part("Leg", Vector3.new(1.15, 3.1, 1.2), center + Vector3.new(offset * 0.85, 1.9, -7), palette.StoneDark, model, Enum.Material.Metal)
        local arm = part("Arm", Vector3.new(1.05, 3.8, 1.05), center + Vector3.new(offset * 2.1, 5, -7), palette.Stone, model, Enum.Material.Metal)
        arm.CFrame *= CFrame.Angles(0, 0, math.rad(offset * 7))
        leg.CanCollide = false
    end

    local spear = part("Spear", Vector3.new(0.25, 9, 0.25), center + Vector3.new(3.2, 5.2, -6.7), palette.Gold, model, Enum.Material.Metal)
    spear.CanCollide = false
    return model, torso
end

local function createGuard(center, parent)
    local ok, model = pcall(function()
        local description = Instance.new("HumanoidDescription")
        description.HeadColor = Color3.fromRGB(202, 167, 132)
        description.LeftArmColor = Color3.fromRGB(86, 94, 108)
        description.RightArmColor = Color3.fromRGB(86, 94, 108)
        description.LeftLegColor = Color3.fromRGB(46, 52, 66)
        description.RightLegColor = Color3.fromRGB(46, 52, 66)
        description.TorsoColor = Color3.fromRGB(67, 78, 101)
        description.HeightScale = 1.06
        description.WidthScale = 1.05
        description.DepthScale = 1.02
        return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
    end)

    local anchor
    if not ok or not model then
        model, anchor = fallbackGuard(center, parent)
    else
        model.Name = "CastleGuard"
        model.Parent = parent
        for _, object in ipairs(model:GetDescendants()) do
            if object:IsA("BasePart") then
                object.Anchored = true
                object.CanCollide = false
                object.Material = Enum.Material.SmoothPlastic
            elseif object:IsA("Script") or object:IsA("LocalScript") then
                object:Destroy()
            end
        end
        model:PivotTo(CFrame.new(center + Vector3.new(0, 3.1, -7)) * CFrame.Angles(0, math.pi, 0))
        anchor = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")

        if anchor then
            local chest = part("KnightChest", Vector3.new(3.4, 2.7, 1.6), anchor.Position + Vector3.new(0, 0.15, -0.15), palette.Stone, model, Enum.Material.Metal)
            chest.CanCollide = false
            local belt = part("KnightBelt", Vector3.new(3.35, 0.38, 1.7), anchor.Position + Vector3.new(0, -1.35, -0.15), palette.Gold, model, Enum.Material.Metal)
            belt.CanCollide = false
        end

        local head = model:FindFirstChild("Head")
        if head then
            local helmet = part("KnightHelmet", Vector3.new(2.25, 1.15, 2.25), head.Position + Vector3.new(0, 0.55, 0), palette.StoneDark, model, Enum.Material.Metal)
            helmet.CanCollide = false
            local crest = part("KnightCrest", Vector3.new(0.35, 1.5, 2.0), head.Position + Vector3.new(0, 1.55, 0), Color3.fromRGB(51, 84, 145), model, Enum.Material.Fabric)
            crest.CanCollide = false
        end
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "GuardHighlight"
    highlight.FillTransparency = 0.9
    highlight.OutlineTransparency = 0.25
    highlight.OutlineColor = palette.Cyan
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model

    local head = model:FindFirstChild("Head") or anchor
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "GuardName"
        billboard.Size = UDim2.fromOffset(300, 70)
        billboard.StudsOffset = Vector3.new(0, 3.6, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.Text = "AI GUARD\nRANKED OPPONENT"
        text.TextColor3 = palette.White
        text.TextStrokeTransparency = 0.4
        text.Font = Enum.Font.GothamBold
        text.TextSize = 18
        text.Parent = billboard
    end

    return model
end

local function createArena(arenaId, center)
    local arenaFolder = Instance.new("Folder")
    arenaFolder.Name = "Arena" .. arenaId
    arenaFolder.Parent = root

    local stage = part("Stage", Vector3.new(48, 1.2, 44), center, palette.StoneDark, arenaFolder, Enum.Material.Slate)
    stage.Position = center

    part("Carpet", Vector3.new(10, 0.12, 34), center + Vector3.new(0, 0.68, 1), Color3.fromRGB(48, 70, 112), arenaFolder, Enum.Material.Fabric)

    for _, side in ipairs({ -1, 1 }) do
        tower(center, side, arenaFolder)
        part("Wall", Vector3.new(11, 12, 3), center + Vector3.new(side * 19, 6, -14), palette.Stone, arenaFolder, Enum.Material.Slate)
    end

    local gate = part("Portcullis", Vector3.new(9, 11, 0.8), center + Vector3.new(0, 5.5, -14), palette.Gold, arenaFolder, Enum.Material.Metal)
    local closedCFrame = gate.CFrame
    local gateParts = {
        { Part = gate, ClosedCFrame = gate.CFrame },
    }

    for x = -3, 3, 1.5 do
        local bar = part("GateBar", Vector3.new(0.35, 10, 0.45), center + Vector3.new(x, 5.5, -13.45), palette.StoneDark, arenaFolder, Enum.Material.Metal)
        bar.CanCollide = false
        table.insert(gateParts, { Part = bar, ClosedCFrame = bar.CFrame })
    end
    for y = 2.5, 8.5, 3 do
        local bar = part("GateCrossbar", Vector3.new(8.5, 0.35, 0.45), center + Vector3.new(0, y, -13.45), palette.StoneDark, arenaFolder, Enum.Material.Metal)
        bar.CanCollide = false
        table.insert(gateParts, { Part = bar, ClosedCFrame = bar.CFrame })
    end

    banner(center + Vector3.new(-6, 13, -13.35), "I", arenaFolder)
    banner(center + Vector3.new(6, 13, -13.35), "AI", arenaFolder)

    local guardModel = createGuard(center, arenaFolder)

    local label = board("ArenaBoard" .. arenaId, center + Vector3.new(0, 17, -14.7), Vector3.new(36, 11, 1), palette.Gold)

    local console = part("JoinConsole", Vector3.new(6, 2.6, 4), center + Vector3.new(0, 2, 15), palette.Cyan, arenaFolder, Enum.Material.Metal)
    local consoleGlow = part("ConsoleGlow", Vector3.new(5.3, 0.2, 3.3), center + Vector3.new(0, 3.36, 15), palette.Cyan, arenaFolder, Enum.Material.Neon)
    consoleGlow.CanCollide = false

    local consoleLight = Instance.new("PointLight")
    consoleLight.Color = palette.Cyan
    consoleLight.Brightness = 1.6
    consoleLight.Range = 12
    consoleLight.Parent = consoleGlow

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Challenge Guard"
    prompt.ObjectText = "Arena " .. arenaId .. " | Ranked"
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    prompt.Parent = console

    for _, side in ipairs({ -1, 1 }) do
        local bench = part("SpectatorBench", Vector3.new(3, 2, 14), center + Vector3.new(side * 27, 1, 4), palette.Navy, arenaFolder, Enum.Material.WoodPlanks)
        bench.CFrame *= CFrame.Angles(0, math.rad(side * 8), 0)
        torch(center + Vector3.new(side * 21, 3, -2), arenaFolder)
    end

    return {
        Center = center,
        Label = label,
        Prompt = prompt,
        Console = console,
        Gate = gate,
        GateClosedCFrame = closedCFrame,
        GateParts = gateParts,
        GateOpen = false,
        Guard = guardModel,
    }
end

local function setGate(arena, open)
    if arena.GateOpen == open then
        return
    end

    arena.GateOpen = open
    arena.Gate.CanCollide = not open

    for index, entry in ipairs(arena.GateParts or {}) do
        local target = open and (entry.ClosedCFrame + Vector3.new(0, 13, 0)) or entry.ClosedCFrame
        TweenService:Create(
            entry.Part,
            TweenInfo.new(open and 1.1 or 0.7, Enum.EasingStyle.Quart, open and Enum.EasingDirection.Out or Enum.EasingDirection.InOut),
            {
                CFrame = target,
                Transparency = index == 1 and (open and 0.2 or 0) or 0,
            }
        ):Play()
    end

    if open then
        local sparkle = Instance.new("Sparkles")
        sparkle.Name = "VictorySparkles"
        sparkle.SparkleColor = palette.Gold
        sparkle.Parent = (arena.GateParts and arena.GateParts[2] and arena.GateParts[2].Part) or arena.Gate
        task.delay(2.5, function()
            if sparkle.Parent then
                sparkle:Destroy()
            end
        end)
    end
end

local function setGuardMood(arena, progress, suspicion, status)
    local highlight = arena.Guard and arena.Guard:FindFirstChild("GuardHighlight")
    if not highlight then
        return
    end

    if status == "Won" then
        highlight.OutlineColor = palette.Green
    elseif status == "Lost" or suspicion >= 75 then
        highlight.OutlineColor = palette.Red
    elseif progress >= 50 then
        highlight.OutlineColor = palette.Gold
    else
        highlight.OutlineColor = palette.Cyan
    end
end

function WorldService.Init(onStart)
    local previous = workspace:FindFirstChild("BeatTheBotWorld")
    if previous then
        previous:Destroy()
    end

    root = Instance.new("Folder")
    root.Name = "BeatTheBotWorld"
    root.Parent = workspace

    configureLighting()
    part("SafetyFoundation", Vector3.new(260, 4, 260), Vector3.new(0, -4, 0), palette.Night, root, Enum.Material.Slate)
    part("Plaza", Vector3.new(205, 2, 205), Vector3.new(0, -1, 0), Color3.fromRGB(31, 38, 56), root, Enum.Material.Slate)
    part("CentralWalkway", Vector3.new(18, 0.18, 180), Vector3.new(0, 0.1, 0), palette.Navy, root, Enum.Material.Metal)

    for x = -80, 80, 20 do
        local strip = part("PlazaLight", Vector3.new(10, 0.06, 0.35), Vector3.new(x, 0.05, 82), palette.Cyan, root, Enum.Material.Neon)
        strip.CanCollide = false
    end

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "BeatTheBotSpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 1, 84)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Color = palette.Cyan
    spawn.Material = Enum.Material.Neon
    spawn.Parent = root
    WorldService.Spawn = spawn

    local welcome = board("Welcome", Vector3.new(0, 11, 66), Vector3.new(30, 11, 1), palette.Cyan)
    welcome.Text = "BEAT THE BOT\n3 AI GUARD PERSONALITIES\n8 moves. Read them. Outsmart them.\nRank up. Become server champion."

    for arenaId = 1, Config.ArenaCount do
        local column = (arenaId - 1) % 2
        local row = math.floor((arenaId - 1) / 2)
        local center = Vector3.new(column == 0 and -43 or 43, 0.6, -34 + row * 72)

        local ok, arenaOrError = pcall(createArena, arenaId, center)
        if ok then
            local arena = arenaOrError
            arena.Prompt.Triggered:Connect(function(player)
                onStart(player, arenaId)
            end)
            WorldService.Arenas[arenaId] = arena
            WorldService.ShowArena(
                arenaId,
                "AVAILABLE\nAI GUARD CHALLENGE\nDifferent guards react to different tactics.\n8 moves | 3 minutes | Ranked",
                false,
                0,
                0,
                "Available"
            )
        else
            warn("BEAT_THE_BOT_ARENA_BUILD_FAILED", arenaId, arenaOrError)
        end
    end

    leaderboard = board("Leaderboard", Vector3.new(0, 15, -88), Vector3.new(38, 24, 1), palette.Gold)

    local championBase = part("ChampionPedestal", Vector3.new(13, 3, 13), Vector3.new(0, 1.5, -28), palette.Gold, root, Enum.Material.Metal)
    local ring = part("ChampionRing", Vector3.new(11, 0.25, 11), Vector3.new(0, 3.15, -28), palette.Cyan, root, Enum.Material.Neon)
    ring.CanCollide = false

    championLabel = board("ChampionTitle", Vector3.new(0, 16, -33), Vector3.new(26, 8, 1), palette.Gold)
    championLabel.Text = "SERVER CHAMPION\nWaiting for challengers"

    local humanVsAI = board("HumanVsAI", Vector3.new(0, 10, 28), Vector3.new(28, 10, 1), palette.Cyan)
    humanVsAI.Name = "HumanVsAI"
    WorldService.HumanVsAI = humanVsAI

    if #WorldService.Arenas == 0 then
        error("No arenas were created. Check BEAT_THE_BOT_ARENA_BUILD_FAILED warnings above.")
    end

    print("BEAT_THE_BOT_WORLD_READY", #WorldService.Arenas, "arenas", WorldService.Spawn:GetFullName())
end

function WorldService.SetGuard(arenaId, guard)
    local arena = WorldService.Arenas[arenaId]
    if not arena or not guard then
        return
    end

    arena.CurrentGuard = guard

    if arena.Guard then
        local billboard = arena.Guard:FindFirstChild("GuardName", true)
        local text = billboard and billboard:FindFirstChildOfClass("TextLabel")
        if text then
            text.Text = string.format("%s\n%s | %d ELO", string.upper(guard.Name), guard.Title, guard.Rating)
        end
    end
end

function WorldService.ShowArena(arenaId, message, won, progress, suspicion, status)
    local arena = WorldService.Arenas[arenaId]
    if not arena then
        return
    end

    arena.Label.Text = message
    setGate(arena, won == true)
    setGuardMood(arena, progress or 0, suspicion or 0, status or "Available")
end

function WorldService.Record(won)
    if won then
        WorldService.HumanWins += 1
    else
        WorldService.BotWins += 1
    end
end

function WorldService.Refresh(dataService)
    local ranked = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local profile = dataService.Get(player)
        if profile then
            table.insert(ranked, { Player = player, Profile = profile })
        end
    end

    table.sort(ranked, function(left, right)
        if left.Profile.Elo ~= right.Profile.Elo then
            return left.Profile.Elo > right.Profile.Elo
        end
        if left.Profile.Wins ~= right.Profile.Wins then
            return left.Profile.Wins > right.Profile.Wins
        end
        return left.Player.UserId < right.Player.UserId
    end)

    local lines = { "SERVER LEADERBOARD", "RATING  |  WINS / LOSSES" }
    for rank, entry in ipairs(ranked) do
        if rank > 8 then
            break
        end
        table.insert(lines, string.format("%d. @%s   %d   %d/%d", rank, entry.Player.Name, entry.Profile.Elo, entry.Profile.Wins, entry.Profile.Losses))
    end

    if #ranked == 0 then
        table.insert(lines, "No ranked players yet.")
    end

    if leaderboard then
        leaderboard.Text = table.concat(lines, "\n")
    end

    local total = WorldService.HumanWins + WorldService.BotWins
    local aiRate = total > 0 and math.floor((WorldService.BotWins / total) * 100 + 0.5) or 0
    if WorldService.HumanVsAI then
        WorldService.HumanVsAI.Text = string.format(
            "HUMANS VS AI\nHumans %d   |   Guard %d\nAI win rate: %d%%",
            WorldService.HumanWins,
            WorldService.BotWins,
            aiRate
        )
    end

    local best = ranked[1]
    if championLabel then
        championLabel.Text = best
            and string.format("SERVER CHAMPION\n@%s | %d ELO", best.Player.Name, best.Profile.Elo)
            or "SERVER CHAMPION\nWaiting for challengers"
    end

    local nextId = best and best.Player.UserId or nil
    if nextId == championId then
        return
    end

    championId = nextId
    championVersion += 1
    local version = championVersion

    if championModel then
        championModel:Destroy()
        championModel = nil
    end

    if not nextId then
        return
    end

    task.spawn(function()
        local ok, model = pcall(function()
            return Players:CreateHumanoidModelFromUserIdAsync(nextId)
        end)
        if not ok then
            return
        end

        if version ~= championVersion then
            model:Destroy()
            return
        end

        model.Name = "ChampionAvatar"
        for _, object in ipairs(model:GetDescendants()) do
            if object:IsA("BasePart") then
                object.Anchored = true
                object.CanCollide = false
            elseif object:IsA("Script") or object:IsA("LocalScript") then
                object:Destroy()
            end
        end

        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.88
        highlight.OutlineTransparency = 0.1
        highlight.OutlineColor = palette.Gold
        highlight.Parent = model

        model:PivotTo(CFrame.new(0, 6, -28) * CFrame.Angles(0, math.pi, 0))
        model.Parent = root
        championModel = model
    end)
end

return WorldService