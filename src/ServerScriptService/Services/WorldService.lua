local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local DistrictDefinitions = require(script.Parent.Parent.Core.DistrictDefinitions)

local WorldService = {
    Arenas = {},
    DailyArena = nil,
    FastTravelPrompts = {},
    HumanWins = 0,
    BotWins = 0,
    Destinations = {},
}

local root
local leaderboard
local humanVsAI
local championLabel

local palette = {
    Night = Color3.fromRGB(12, 16, 26),
    Deep = Color3.fromRGB(22, 27, 38),
    Stone = Color3.fromRGB(94, 91, 87),
    DarkStone = Color3.fromRGB(55, 58, 66),
    WetStone = Color3.fromRGB(39, 47, 59),
    WarmStone = Color3.fromRGB(122, 107, 88),
    Wood = Color3.fromRGB(88, 58, 39),
    Iron = Color3.fromRGB(49, 54, 62),
    Gold = Color3.fromRGB(220, 174, 75),
    Amber = Color3.fromRGB(244, 154, 65),
    Cyan = Color3.fromRGB(79, 202, 220),
    Blue = Color3.fromRGB(91, 130, 181),
    Violet = Color3.fromRGB(126, 102, 177),
    Green = Color3.fromRGB(83, 163, 111),
    Red = Color3.fromRGB(186, 67, 71),
    White = Color3.fromRGB(235, 239, 244),
}

local accentByName = {
    Gold = palette.Gold,
    Crimson = palette.Red,
    Cyan = palette.Cyan,
    Amber = palette.Amber,
    Ivory = palette.White,
    Emerald = palette.Green,
    Blue = palette.Blue,
    Silver = Color3.fromRGB(180, 189, 204),
    Violet = palette.Violet,
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

local function invisibleMarker(name, position, parent)
    local marker = part(name, Vector3.new(2, 1, 2), position, palette.Cyan, parent, Enum.Material.SmoothPlastic)
    marker.Transparency = 1
    marker.CanCollide = false
    return marker
end

local function addTextSurface(target, face, text, textColor, backgroundColor)
    local surface = Instance.new("SurfaceGui")
    surface.Face = face or Enum.NormalId.Front
    surface.CanvasSize = Vector2.new(1000, 500)
    surface.LightInfluence = 0
    surface.Parent = target

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BorderSizePixel = 0
    frame.BackgroundColor3 = backgroundColor or palette.Night
    frame.BackgroundTransparency = 0.08
    frame.Parent = surface

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 7
    stroke.Color = textColor or palette.Gold
    stroke.Transparency = 0.3
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(0.92, 0.88)
    label.Position = UDim2.fromScale(0.04, 0.06)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = textColor or palette.White
    label.TextWrapped = true
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.8
    label.Parent = frame
    return label
end

local function board(name, position, size, text, accent, parent)
    local panel = part(name, size, position, palette.Deep, parent or root, Enum.Material.Metal)
    return panel, addTextSurface(panel, Enum.NormalId.Front, text, accent or palette.Gold, palette.Night)
end

local function torch(position, parent)
    local pole = part("TorchPole", Vector3.new(0.45, 4.8, 0.45), position, palette.Iron, parent, Enum.Material.Metal)
    local flame = part("TorchFlame", Vector3.new(0.55, 0.7, 0.55), position + Vector3.new(0, 2.7, 0), palette.Amber, parent, Enum.Material.Neon)
    pole.CanCollide = false
    flame.CanCollide = false

    local fire = Instance.new("Fire")
    fire.Size = 3.5
    fire.Heat = 4
    fire.Color = Color3.fromRGB(255, 170, 75)
    fire.SecondaryColor = Color3.fromRGB(255, 78, 30)
    fire.Parent = flame

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 178, 103)
    light.Brightness = 1.7
    light.Range = 17
    light.Shadows = true
    light.Parent = flame
end

local function lantern(position, parent, color)
    local housing = part("Lantern", Vector3.new(1.1, 1.5, 1.1), position, palette.Iron, parent, Enum.Material.Metal)
    housing.CanCollide = false
    local glow = part("LanternGlow", Vector3.new(0.65, 0.9, 0.65), position, color or palette.Amber, parent, Enum.Material.Neon)
    glow.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = color or palette.Amber
    light.Brightness = 1.4
    light.Range = 15
    light.Parent = glow
end

local function banner(position, symbol, color, parent)
    local cloth = part("Banner", Vector3.new(5, 8, 0.25), position, color, parent, Enum.Material.Fabric)
    cloth.CanCollide = false
    local label = addTextSurface(cloth, Enum.NormalId.Front, symbol, palette.Gold, color)
    label.TextScaled = true
end

local function tower(position, height, parent, accent)
    part("Tower", Vector3.new(16, height, 16), position + Vector3.new(0, height / 2, 0), palette.Stone, parent, Enum.Material.Slate)
    part("TowerCrown", Vector3.new(19, 2, 19), position + Vector3.new(0, height + 1, 0), palette.DarkStone, parent, Enum.Material.Slate)

    for _, dx in ipairs({ -6, 0, 6 }) do
        part("Battlement", Vector3.new(3, 4, 3), position + Vector3.new(dx, height + 3, -6), palette.DarkStone, parent, Enum.Material.Slate)
    end

    if accent then
        local beacon = part("TowerBeacon", Vector3.new(1.2, 1.2, 1.2), position + Vector3.new(0, height + 5, 0), accent, parent, Enum.Material.Neon)
        beacon.Shape = Enum.PartType.Ball
        beacon.CanCollide = false
    end
end

local function wall(position, size, parent, color)
    return part("CitadelWall", size, position, color or palette.Stone, parent, Enum.Material.Slate)
end

local function path(position, size, parent, material, color)
    local p = part("CitadelPath", size, position, color or palette.DarkStone, parent, material or Enum.Material.Cobblestone)
    p.CanCollide = true
    return p
end

local function districtSign(name, position, title, subtitle, accent, parent)
    local _, label = board(name, position, Vector3.new(30, 9, 1), title .. "\n" .. subtitle, accent, parent)
    return label
end

local function configureLighting()
    Lighting.ClockTime = 19.1
    Lighting.Brightness = 2.2
    Lighting.Ambient = Color3.fromRGB(54, 59, 76)
    Lighting.OutdoorAmbient = Color3.fromRGB(75, 81, 98)
    Lighting.ColorShift_Top = Color3.fromRGB(255, 201, 167)
    Lighting.ShadowSoftness = 0.28

    pcall(function()
        Lighting.LightingStyle = Enum.LightingStyle.Realistic
    end)

    for _, child in ipairs(Lighting:GetChildren()) do
        if string.sub(child.Name, 1, 11) == "BeatTheBot_" then
            child:Destroy()
        end
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "BeatTheBot_Atmosphere"
    atmosphere.Density = 0.31
    atmosphere.Offset = 0.08
    atmosphere.Haze = 1.7
    atmosphere.Glare = 0.18
    atmosphere.Color = Color3.fromRGB(174, 184, 207)
    atmosphere.Decay = Color3.fromRGB(114, 91, 108)
    atmosphere.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "BeatTheBot_Bloom"
    bloom.Intensity = 0.32
    bloom.Size = 20
    bloom.Threshold = 1.15
    bloom.Parent = Lighting

    local color = Instance.new("ColorCorrectionEffect")
    color.Name = "BeatTheBot_Color"
    color.Brightness = -0.025
    color.Contrast = 0.11
    color.Saturation = -0.03
    color.TintColor = Color3.fromRGB(235, 235, 248)
    color.Parent = Lighting
end

local function createStylizedOpponent(center, parent)
    local model = Instance.new("Model")
    model.Name = "Opponent"
    model.Parent = parent

    local legs = {
        part("LeftLeg", Vector3.new(1.1, 3, 1.1), center + Vector3.new(-0.8, 1.7, -5), palette.DarkStone, model, Enum.Material.Metal),
        part("RightLeg", Vector3.new(1.1, 3, 1.1), center + Vector3.new(0.8, 1.7, -5), palette.DarkStone, model, Enum.Material.Metal),
    }
    local torso = part("Torso", Vector3.new(3.5, 4.3, 2), center + Vector3.new(0, 5, -5), palette.Blue, model, Enum.Material.Fabric)
    local head = part("Head", Vector3.new(2.1, 2.1, 2.1), center + Vector3.new(0, 8.2, -5), Color3.fromRGB(197, 157, 124), model, Enum.Material.SmoothPlastic)
    head.Shape = Enum.PartType.Ball
    local mantle = part("Mantle", Vector3.new(3.9, 1.2, 2.2), center + Vector3.new(0, 6.6, -5), palette.Gold, model, Enum.Material.Fabric)
    mantle.CanCollide = false
    for _, leg in ipairs(legs) do
        leg.CanCollide = false
    end
    torso.CanCollide = false
    head.CanCollide = false

    local highlight = Instance.new("Highlight")
    highlight.Name = "OpponentHighlight"
    highlight.FillTransparency = 0.92
    highlight.OutlineTransparency = 0.22
    highlight.OutlineColor = palette.Cyan
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OpponentName"
    billboard.Size = UDim2.fromOffset(320, 70)
    billboard.StudsOffset = Vector3.new(0, 3.1, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = "AI OPPONENT\nRANKED"
    text.TextColor3 = palette.White
    text.TextStrokeTransparency = 0.35
    text.Font = Enum.Font.GothamBold
    text.TextSize = 18
    text.Parent = billboard

    return model
end

local function gateAssembly(center, parent, accent)
    local parts = {}
    for x = -4, 4, 2 do
        local bar = part("PortcullisBar", Vector3.new(0.45, 11, 0.55), center + Vector3.new(x, 6, -9), palette.Iron, parent, Enum.Material.Metal)
        table.insert(parts, { Part = bar, Closed = bar.CFrame })
    end
    for y = 3, 9, 3 do
        local cross = part("PortcullisCross", Vector3.new(9, 0.45, 0.55), center + Vector3.new(0, y, -9), palette.Iron, parent, Enum.Material.Metal)
        table.insert(parts, { Part = cross, Closed = cross.CFrame })
    end
    local crest = part("GateCrest", Vector3.new(10, 1.2, 0.7), center + Vector3.new(0, 12, -9), accent, parent, Enum.Material.Metal)
    crest.CanCollide = false
    return parts
end

local function createArena(arenaId, center, districtId, accent, daily)
    local folder = Instance.new("Folder")
    folder.Name = daily and "DailyArena" or ("Arena" .. tostring(arenaId))
    folder.Parent = root

    path(center, Vector3.new(58, 1.2, 48), folder, Enum.Material.Slate, districtId == "watch" and palette.WetStone or palette.DarkStone)
    wall(center + Vector3.new(-28, 5, -8), Vector3.new(2, 10, 34), folder)
    wall(center + Vector3.new(28, 5, -8), Vector3.new(2, 10, 34), folder)
    torch(center + Vector3.new(-21, 3, 7), folder)
    torch(center + Vector3.new(21, 3, 7), folder)

    local gateParts = gateAssembly(center, folder, accent)
    local opponent = createStylizedOpponent(center, folder)

    local _, label = board(
        "ArenaBoard",
        center + Vector3.new(0, 16, -10),
        Vector3.new(34, 10, 1),
        daily and "DAILY TRIAL\nOne official attempt each UTC day." or "AVAILABLE\nRANKED AI CHALLENGE",
        accent,
        folder
    )

    local console = part("ChallengeConsole", Vector3.new(6, 2.7, 4), center + Vector3.new(0, 1.8, 12), palette.Iron, folder, Enum.Material.Metal)
    local glow = part("ConsoleGlow", Vector3.new(5.2, 0.22, 3.2), center + Vector3.new(0, 3.25, 12), accent, folder, Enum.Material.Neon)
    glow.CanCollide = false

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = daily and "Enter Daily Trial" or "Challenge Opponent"
    prompt.ObjectText = daily and "Daily Trial" or (DistrictDefinitions.Get(districtId).Name .. " | Ranked")
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    prompt.Parent = console

    return {
        Center = center,
        DistrictId = districtId,
        Label = label,
        Prompt = prompt,
        Console = console,
        GateParts = gateParts,
        GateOpen = false,
        Guard = opponent,
    }
end

local function setGate(arena, open)
    if not arena or arena.GateOpen == open then
        return
    end
    arena.GateOpen = open

    for _, entry in ipairs(arena.GateParts or {}) do
        entry.Part.CanCollide = not open
        local target = open and (entry.Closed + Vector3.new(0, 13, 0)) or entry.Closed
        TweenService:Create(
            entry.Part,
            TweenInfo.new(open and 0.9 or 0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { CFrame = target }
        ):Play()
    end
end

local function createCentralPlaza(onDaily)
    local folder = Instance.new("Folder")
    folder.Name = "CentralPlaza"
    folder.Parent = root

    path(Vector3.new(0, 0, 210), Vector3.new(180, 2, 115), folder, Enum.Material.Slate, Color3.fromRGB(68, 70, 76))
    path(Vector3.new(0, 0.6, 138), Vector3.new(22, 0.35, 55), folder, Enum.Material.Cobblestone, palette.WarmStone)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "CitadelSpawn"
    spawn.Size = Vector3.new(14, 1, 14)
    spawn.Position = Vector3.new(0, 1.5, 245)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Material = Enum.Material.Slate
    spawn.Color = palette.Cyan
    spawn.Parent = folder
    WorldService.Spawn = spawn

    WorldService.Destinations.central_plaza = CFrame.new(0, 5, 228)
    WorldService.Destinations.great_gate = CFrame.new(0, 5, 118)
    WorldService.Destinations.customs = CFrame.new(0, 5, -20)
    WorldService.Destinations.watch = CFrame.new(0, 5, -170)

    tower(Vector3.new(-72, 0, 184), 29, folder, palette.Cyan)
    tower(Vector3.new(72, 0, 184), 29, folder, palette.Cyan)
    banner(Vector3.new(-64, 15, 174), "BTB", palette.Blue, folder)
    banner(Vector3.new(64, 15, 174), "AI", palette.Blue, folder)

    local _, welcome = board("CitadelWelcome", Vector3.new(0, 15, 258), Vector3.new(44, 16, 1), "BEAT THE BOT\nAI CITADEL\nPersuade. Rank up. Go deeper.", palette.Cyan, folder)
    welcome.TextScaled = true

    local _, dailySign = board("DailyLandmark", Vector3.new(0, 15, 181), Vector3.new(36, 13, 1), "DAILY TRIAL\nONE OFFICIAL SCORE\nPractice after completion", palette.Gold, folder)
    dailySign.TextScaled = true

    WorldService.DailyArena = createArena("daily", Vector3.new(0, 0.6, 158), "central_plaza", palette.Gold, true)
    if onDaily then
        WorldService.DailyArena.Prompt.Triggered:Connect(onDaily)
    end

    leaderboard = select(2, board("Leaderboard", Vector3.new(-56, 13, 232), Vector3.new(32, 18, 1), "SERVER LEADERBOARD", palette.Gold, folder))
    humanVsAI = select(2, board("HumanVsAI", Vector3.new(56, 13, 232), Vector3.new(30, 15, 1), "HUMANS VS AI", palette.Cyan, folder))
    championLabel = select(2, board("Champion", Vector3.new(56, 9, 201), Vector3.new(26, 10, 1), "SERVER CHAMPION\nWaiting for challengers", palette.Gold, folder))

    local travelBoard = part("TravelBoard", Vector3.new(30, 8, 1), Vector3.new(-55, 8, 201), palette.Deep, folder, Enum.Material.Metal)
    addTextSurface(travelBoard, Enum.NormalId.Front, "VIP FAST TRAVEL\nOnly to ELO-unlocked districts", palette.Cyan, palette.Night)

    local travel = {
        { Id = "central_plaza", X = -68 },
        { Id = "great_gate", X = -59 },
        { Id = "customs", X = -50 },
        { Id = "watch", X = -41 },
    }
    for _, entry in ipairs(travel) do
        local pad = part("FastTravel_" .. entry.Id, Vector3.new(7, 1, 7), Vector3.new(entry.X, 1, 188), palette.Cyan, folder, Enum.Material.Neon)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Fast Travel"
        prompt.ObjectText = DistrictDefinitions.Get(entry.Id).Name
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = pad
        WorldService.FastTravelPrompts[entry.Id] = prompt
    end

    local vipConsole = part("VIPObservatoryConsole", Vector3.new(9, 2, 6), Vector3.new(82, 1.2, 207), palette.Violet, folder, Enum.Material.Metal)
    local vipPrompt = Instance.new("ProximityPrompt")
    vipPrompt.ActionText = "Enter Observatory"
    vipPrompt.ObjectText = "VIP Observatory"
    vipPrompt.MaxActivationDistance = 12
    vipPrompt.RequiresLineOfSight = false
    vipPrompt.Parent = vipConsole
    WorldService.VIPPrompt = vipPrompt
end

local function createGreatGate(onStart)
    local folder = Instance.new("Folder")
    folder.Name = "GreatGate"
    folder.Parent = root

    path(Vector3.new(0, 0, 88), Vector3.new(190, 2, 115), folder, Enum.Material.Cobblestone, palette.DarkStone)
    wall(Vector3.new(-71, 11, 100), Vector3.new(48, 22, 8), folder)
    wall(Vector3.new(71, 11, 100), Vector3.new(48, 22, 8), folder)
    tower(Vector3.new(-35, 0, 100), 34, folder, palette.Gold)
    tower(Vector3.new(35, 0, 100), 34, folder, palette.Gold)
    banner(Vector3.new(-25, 17, 95), "I", palette.Blue, folder)
    banner(Vector3.new(25, 17, 95), "AI", palette.Blue, folder)

    for _, z in ipairs({ 55, 75, 95, 115 }) do
        torch(Vector3.new(-78, 3, z), folder)
        torch(Vector3.new(78, 3, z), folder)
    end

    districtSign("GreatGateSign", Vector3.new(0, 24, 119), "GREAT GATE", "RANKED ACCESS • OPEN", palette.Gold, folder)

    local centers = {
        Vector3.new(-45, 0.6, 72),
        Vector3.new(45, 0.6, 72),
    }
    for id, center in ipairs(centers) do
        local arena = createArena(id, center, "great_gate", palette.Gold, false)
        arena.Prompt.Triggered:Connect(function(player)
            onStart(player, id)
        end)
        WorldService.Arenas[id] = arena
    end

    for x = -62, 62, 31 do
        local cart = part("InspectionCart", Vector3.new(9, 3, 5), Vector3.new(x, 2, 125), palette.Wood, folder, Enum.Material.WoodPlanks)
        cart.CFrame *= CFrame.Angles(0, math.rad(8), 0)
        part("Cargo", Vector3.new(4, 3, 4), Vector3.new(x, 4.5, 125), palette.WarmStone, folder, Enum.Material.WoodPlanks)
    end
end

local function createCustoms(onStart)
    local folder = Instance.new("Folder")
    folder.Name = "CustomsQuarter"
    folder.Parent = root

    path(Vector3.new(0, 0, -52), Vector3.new(190, 2, 145), folder, Enum.Material.Cobblestone, Color3.fromRGB(91, 82, 70))
    districtSign("CustomsSign", Vector3.new(0, 19, 10), "CUSTOMS QUARTER", "UNLOCKS AT 1100 ELO", palette.Amber, folder)

    local canal = part("Canal", Vector3.new(34, 0.5, 130), Vector3.new(62, 0.1, -53), Color3.fromRGB(36, 83, 102), folder, Enum.Material.Glass)
    canal.CanCollide = false
    part("CanalBridge", Vector3.new(44, 1, 18), Vector3.new(62, 1, -45), palette.WarmStone, folder, Enum.Material.Cobblestone)

    for _, z in ipairs({ -5, -32, -60, -88, -115 }) do
        local stall = part("MarketStall", Vector3.new(18, 8, 11), Vector3.new(-67, 4, z), palette.Wood, folder, Enum.Material.WoodPlanks)
        stall.CanCollide = true
        part("Awning", Vector3.new(20, 0.5, 13), Vector3.new(-67, 8.3, z), (z % 2 == 0) and palette.Amber or palette.Green, folder, Enum.Material.Fabric)
        lantern(Vector3.new(-55, 6, z), folder, palette.Amber)
        for crate = 1, 3 do
            part("CargoCrate", Vector3.new(3, 3, 3), Vector3.new(-82 + crate * 4, 1.8, z + 8), palette.Wood, folder, Enum.Material.WoodPlanks)
        end
    end

    local office = part("CustomsOffice", Vector3.new(42, 18, 28), Vector3.new(25, 9, -108), palette.WarmStone, folder, Enum.Material.Brick)
    banner(office.Position + Vector3.new(-12, 2, -14.2), "C", palette.Red, folder)
    local guild = part("GuildHall", Vector3.new(44, 24, 34), Vector3.new(-23, 12, -115), Color3.fromRGB(108, 91, 68), folder, Enum.Material.Brick)
    banner(guild.Position + Vector3.new(12, 3, -17.2), "G", palette.Green, folder)

    local arena = createArena(3, Vector3.new(0, 0.6, -53), "customs", palette.Amber, false)
    arena.Prompt.Triggered:Connect(function(player)
        onStart(player, 3)
    end)
    WorldService.Arenas[3] = arena
end

local function createWatch(onStart)
    local folder = Instance.new("Folder")
    folder.Name = "WatchDistrict"
    folder.Parent = root

    path(Vector3.new(0, 0, -202), Vector3.new(190, 2, 145), folder, Enum.Material.Slate, palette.WetStone)
    districtSign("WatchSign", Vector3.new(0, 19, -140), "WATCH DISTRICT", "UNLOCKS AT 1250 ELO", palette.Blue, folder)

    for _, x in ipairs({ -75, 75 }) do
        tower(Vector3.new(x, 0, -190), 41, folder, palette.Blue)
        tower(Vector3.new(x, 0, -260), 35, folder, palette.Violet)
    end

    for _, z in ipairs({ -160, -190, -220, -250 }) do
        lantern(Vector3.new(-50, 8, z), folder, Color3.fromRGB(135, 171, 220))
        lantern(Vector3.new(50, 8, z), folder, Color3.fromRGB(135, 171, 220))
    end

    local evidence = part("EvidenceHall", Vector3.new(38, 18, 30), Vector3.new(-54, 9, -231), palette.Deep, folder, Enum.Material.Brick)
    local notice = part("NoticeBoard", Vector3.new(18, 11, 1), Vector3.new(-54, 10, -214), palette.Wood, folder, Enum.Material.WoodPlanks)
    addTextSurface(notice, Enum.NormalId.Front, "WATCH NOTICES\nCONTRADICTIONS • EVIDENCE • REPORTS", palette.White, palette.Wood)

    local cells = part("HoldingCells", Vector3.new(38, 18, 30), Vector3.new(54, 9, -231), palette.DarkStone, folder, Enum.Material.Slate)
    for x = 42, 66, 8 do
        part("CellBars", Vector3.new(0.45, 11, 24), Vector3.new(x, 6, -216), palette.Iron, folder, Enum.Material.Metal)
    end

    local rainHooks = Instance.new("Folder")
    rainHooks.Name = "RainVFXHooks"
    rainHooks:SetAttribute("EnabledByDefault", false)
    rainHooks.Parent = folder

    local arena = createArena(4, Vector3.new(0, 0.6, -202), "watch", palette.Blue, false)
    arena.Prompt.Triggered:Connect(function(player)
        onStart(player, 4)
    end)
    WorldService.Arenas[4] = arena

    evidence:SetAttribute("EnvironmentalStory", "Investigation staging")
    cells:SetAttribute("EnvironmentalStory", "Interrogation and holding")
end

local function createFutureLandmarks()
    local folder = Instance.new("Folder")
    folder.Name = "FutureCitadel"
    folder.Parent = root

    path(Vector3.new(0, 0, -345), Vector3.new(190, 2, 105), folder, Enum.Material.Marble, Color3.fromRGB(103, 99, 104))
    districtSign("RoyalCourtSign", Vector3.new(0, 26, -300), "ROYAL COURT", "VISIBLE TEASER • 1500 ELO", palette.Gold, folder)
    tower(Vector3.new(-55, 0, -365), 58, folder, palette.Gold)
    tower(Vector3.new(55, 0, -365), 58, folder, palette.Gold)
    local court = part("RoyalCourt", Vector3.new(86, 38, 44), Vector3.new(0, 19, -390), Color3.fromRGB(124, 117, 111), folder, Enum.Material.Marble)
    part("CourtRoof", Vector3.new(94, 5, 52), court.Position + Vector3.new(0, 21, 0), palette.Gold, folder, Enum.Material.Metal)

    path(Vector3.new(0, 0, -475), Vector3.new(170, 2, 120), folder, Enum.Material.Slate, palette.Deep)
    districtSign("OracleSign", Vector3.new(0, 32, -430), "ORACLE SPIRE", "VISIBLE TEASER • 1800 ELO", palette.Violet, folder)
    local spire = part("OracleSpire", Vector3.new(28, 105, 28), Vector3.new(0, 52.5, -500), Color3.fromRGB(69, 62, 88), folder, Enum.Material.Slate)
    local crystal = part("OracleBeacon", Vector3.new(9, 15, 9), spire.Position + Vector3.new(0, 61, 0), palette.Violet, folder, Enum.Material.Neon)
    crystal.Shape = Enum.PartType.Ball
    crystal.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = palette.Violet
    light.Brightness = 3
    light.Range = 70
    light.Parent = crystal
end

local function createObservatory()
    local folder = Instance.new("Folder")
    folder.Name = "VIPObservatory"
    folder.Parent = root

    local base = part("ObservatoryDeck", Vector3.new(58, 3, 58), Vector3.new(102, 45, -20), palette.Deep, folder, Enum.Material.Metal)
    part("ObservatoryDome", Vector3.new(34, 16, 34), Vector3.new(102, 54, -20), Color3.fromRGB(55, 47, 78), folder, Enum.Material.Glass).Transparency = 0.25
    for _, offset in ipairs({
        Vector3.new(-25, 5, -25), Vector3.new(25, 5, -25),
        Vector3.new(-25, 5, 25), Vector3.new(25, 5, 25),
    }) do
        local column = part("ObservatoryColumn", Vector3.new(3, 12, 3), base.Position + offset, palette.Violet, folder, Enum.Material.Marble)
        column.CanCollide = true
    end

    local _, label = board("VIPTitle", Vector3.new(102, 65, -49), Vector3.new(38, 11, 1), "VIP OBSERVATORY\nCOSMETIC • PRACTICE • CONVENIENCE", palette.Violet, folder)
    label.TextScaled = true

    local returnPad = part("ReturnPad", Vector3.new(9, 1, 9), Vector3.new(102, 47, 0), palette.Cyan, folder, Enum.Material.Neon)
    local returnPrompt = Instance.new("ProximityPrompt")
    returnPrompt.ActionText = "Return"
    returnPrompt.ObjectText = "Central Plaza"
    returnPrompt.MaxActivationDistance = 11
    returnPrompt.RequiresLineOfSight = false
    returnPrompt.Parent = returnPad

    WorldService.VIPReturnPrompt = returnPrompt
    WorldService.VIPCFrame = CFrame.new(102, 51, -20)
end

local function addHooks()
    local hooks = Instance.new("Folder")
    hooks.Name = "EnvironmentHooks"
    hooks.Parent = root

    for _, name in ipairs({ "GreatGateAmbient", "CustomsAmbient", "WatchAmbient", "CitadelVFX" }) do
        local hook = Instance.new("Folder")
        hook.Name = name
        hook.Parent = hooks
    end
end

function WorldService.Init(onStart, onDaily)
    local previous = workspace:FindFirstChild("BeatTheBotWorld")
    if previous then
        previous:Destroy()
    end

    WorldService.Arenas = {}
    WorldService.FastTravelPrompts = {}
    WorldService.Destinations = {}
    WorldService.DailyArena = nil

    root = Instance.new("Folder")
    root.Name = "BeatTheBotWorld"
    root.Parent = workspace

    configureLighting()
    part("SafetyFoundation", Vector3.new(240, 4, 820), Vector3.new(0, -4, -120), palette.Night, root, Enum.Material.Slate)
    path(Vector3.new(0, -0.8, -115), Vector3.new(22, 1, 720), root, Enum.Material.Cobblestone, palette.DarkStone)

    createCentralPlaza(onDaily)
    createGreatGate(onStart)
    createCustoms(onStart)
    createWatch(onStart)
    createFutureLandmarks()
    createObservatory()
    addHooks()

    if #WorldService.Arenas ~= 4 or not WorldService.DailyArena then
        error("AI Citadel world did not build all required challenge spaces")
    end

    print("BEAT_THE_BOT_WORLD_READY", #WorldService.Arenas, "ranked arenas plus Daily Trial")
end

function WorldService.GetDestinationCFrame(id)
    return WorldService.Destinations[id]
end

function WorldService.GetVIPCFrame()
    return WorldService.VIPCFrame
end

function WorldService.SetGuard(arenaId, opponent)
    local arena = arenaId == "daily" and WorldService.DailyArena or WorldService.Arenas[arenaId]
    if not arena or not opponent then
        return
    end

    arena.CurrentGuard = opponent
    local billboard = arena.Guard and arena.Guard:FindFirstChild("OpponentName", true)
    local text = billboard and billboard:FindFirstChildOfClass("TextLabel")
    if text then
        text.Text = string.format("%s\n%s | %d ELO", string.upper(opponent.Name), opponent.Title, opponent.Rating)
    end

    local accent = accentByName[opponent.Visual and opponent.Visual.Accent] or palette.Cyan
    local highlight = arena.Guard and arena.Guard:FindFirstChild("OpponentHighlight")
    if highlight then
        highlight.OutlineColor = accent
    end

    local torso = arena.Guard and arena.Guard:FindFirstChild("Torso")
    local mantle = arena.Guard and arena.Guard:FindFirstChild("Mantle")
    if torso then
        torso.Color = accent:Lerp(palette.Deep, 0.45)
    end
    if mantle then
        mantle.Color = accent
        mantle.Material = opponent.Visual and opponent.Visual.Archetype == "Merchant"
            and Enum.Material.SmoothPlastic
            or Enum.Material.Fabric
    end
end

function WorldService.ShowArena(arenaId, message, won, progress, suspicion, status)
    local arena = arenaId == "daily" and WorldService.DailyArena or WorldService.Arenas[arenaId]
    if not arena then
        return
    end

    arena.Label.Text = message
    setGate(arena, won == true)

    local highlight = arena.Guard and arena.Guard:FindFirstChild("OpponentHighlight")
    if highlight then
        if status == "Won" then
            highlight.OutlineColor = palette.Green
        elseif status == "Lost" or (suspicion or 0) >= 75 then
            highlight.OutlineColor = palette.Red
        elseif (progress or 0) >= 50 then
            highlight.OutlineColor = palette.Gold
        end
    end
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

    local lines = { "SERVER LEADERBOARD", "ELO  •  W/L  •  RANK" }
    for index, entry in ipairs(ranked) do
        entry.Player:SetAttribute("ServerRank", index)
        if index <= 8 then
            local rank = require(script.Parent.Parent.Core.RankDefinitions).ForElo(entry.Profile.Elo)
            table.insert(lines, string.format("%d. @%s  %d  %d/%d  %s", index, entry.Player.Name, entry.Profile.Elo, entry.Profile.Wins, entry.Profile.Losses, rank.Name))
        end
    end
    if #ranked == 0 then
        table.insert(lines, "No ranked players yet.")
    end
    if leaderboard then
        leaderboard.Text = table.concat(lines, "\n")
    end

    local total = WorldService.HumanWins + WorldService.BotWins
    local botRate = total > 0 and math.floor((WorldService.BotWins / total) * 100 + 0.5) or 0
    if humanVsAI then
        humanVsAI.Text = string.format("HUMANS VS AI\nHumans %d  •  AI %d\nAI win rate %d%%", WorldService.HumanWins, WorldService.BotWins, botRate)
    end

    local best = ranked[1]
    if championLabel then
        championLabel.Text = best
            and string.format("SERVER CHAMPION\n@%s\n%d ELO", best.Player.Name, best.Profile.Elo)
            or "SERVER CHAMPION\nWaiting for challengers"
    end
end

return WorldService
