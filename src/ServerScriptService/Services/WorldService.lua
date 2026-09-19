local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local WorldService = { Arenas = {}, HumanWins = 0, BotWins = 0 }
local root
local leaderboard
local championLabel
local championId
local championVersion = 0
local championModel
local navy = Color3.fromRGB(18, 25, 45)
local cyan = Color3.fromRGB(73, 220, 236)
local gold = Color3.fromRGB(255, 199, 89)

local function part(name, size, position, color, parent)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.Position = position
    object.Anchored = true
    object.Color = color
    object.Material = Enum.Material.SmoothPlastic
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent or root
    return object
end

local function board(name, position, size, color)
    local panel = part(name, size, position, navy)
    panel.CFrame *= CFrame.Angles(0, math.pi, 0)
    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.CanvasSize = Vector2.new(1000, 600)
    surface.Parent = panel
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(0.94, 0.92)
    label.Position = UDim2.fromScale(0.03, 0.04)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or cyan
    label.Font = Enum.Font.GothamBold
    label.TextSize = 38
    label.TextWrapped = true
    label.RichText = false
    label.Parent = surface
    return label
end

local function guard(center)
    local model = Instance.new("Model")
    model.Name = "CastleGuard"
    model.Parent = root
    part("Body", Vector3.new(3, 4, 2), center + Vector3.new(0, 4, -7), cyan, model)
    part("Head", Vector3.new(2, 2, 2), center + Vector3.new(0, 7, -7), gold, model)
    part("Helmet", Vector3.new(2.5, 0.8, 2.5), center + Vector3.new(0, 8.2, -7), navy, model)
    for _, offset in ipairs({ -1, 1 }) do
        part("Leg", Vector3.new(1, 2, 1), center + Vector3.new(offset, 1.5, -7), navy, model)
        part("Arm", Vector3.new(1, 3, 1), center + Vector3.new(offset * 2, 4, -7), cyan, model)
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
    Lighting.ClockTime = 17
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(130, 140, 170)
    workspace.FallenPartsDestroyHeight = -100
    part("Plaza", Vector3.new(180, 2, 180), Vector3.new(0, -1, 0), Color3.fromRGB(38, 47, 68))
    part("Walkway", Vector3.new(15, 0.2, 155), Vector3.new(0, 0.1, 0), navy)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "BeatTheBotSpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 1, 72)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Color = cyan
    spawn.Parent = root
    WorldService.Spawn = spawn
    local welcome = board("Welcome", Vector3.new(0, 10, 58), Vector3.new(24, 10, 1))
    welcome.Text = "BEAT THE BOT\n8 moves. One stubborn guard.\nWalk to a glowing console to play.\nLocal logic prototype | No paid advantages"
    for arenaId = 1, Config.ArenaCount do
        local column = (arenaId - 1) % 2
        local row = math.floor((arenaId - 1) / 2)
        local center = Vector3.new(column == 0 and -36 or 36, 0.5, -32 + row * 65)
        part("Stage", Vector3.new(42, 1, 38), center, navy)
        local trim = part("StageGlow", Vector3.new(42, 0.3, 1), center + Vector3.new(0, 0.65, 18), cyan)
        trim.Material = Enum.Material.Neon
        guard(center)
        local gate = part("Gate", Vector3.new(10, 10, 1), center + Vector3.new(0, 5, -14), gold)
        local label = board("ArenaBoard" .. arenaId, center + Vector3.new(0, 15, -14), Vector3.new(35, 12, 1))
        local console = part("JoinConsole", Vector3.new(5, 3, 3), center + Vector3.new(0, 2, 12), cyan)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Challenge Guard"
        prompt.ObjectText = "Arena " .. arenaId .. " | 8 moves"
        prompt.MaxActivationDistance = 12
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
        prompt.Parent = console
        prompt.Triggered:Connect(function(player)
            onStart(player, arenaId)
        end)
        for _, side in ipairs({ -1, 1 }) do
            part("SpectatorBench", Vector3.new(3, 2, 12), center + Vector3.new(side * 24, 1, 3), navy)
        end
        WorldService.Arenas[arenaId] = {
            Center = center, Label = label, Prompt = prompt, Console = console, Gate = gate,
        }
        WorldService.ShowArena(arenaId, "AVAILABLE\nTHE CASTLE GUARD | 1,000 ELO\nConvince the guard to let your delivery through.\n8 moves | 3 minutes | Walk to the console")
    end
    leaderboard = board("Leaderboard", Vector3.new(0, 14, -70), Vector3.new(35, 22, 1), gold)
    part("ChampionPedestal", Vector3.new(10, 3, 10), Vector3.new(0, 1.5, -23), gold)
    championLabel = board("ChampionTitle", Vector3.new(0, 15, -27), Vector3.new(22, 7, 1), gold)
    championLabel.Text = "SERVER CHAMPION\nWaiting for challengers"
end

function WorldService.ShowArena(arenaId, message, won)
    local arena = WorldService.Arenas[arenaId]
    arena.Label.Text = message
    arena.Gate.Transparency = won and 0.8 or 0
    arena.Gate.CanCollide = not won
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
    table.insert(lines, string.format("\nTHIS SERVER'S MATCHES\nHumans %d  :  Guard %d", WorldService.HumanWins, WorldService.BotWins))
    leaderboard.Text = table.concat(lines, "\n")
    local best = ranked[1]
    championLabel.Text = best and string.format("SERVER CHAMPION\n@%s | %d ELO", best.Player.Name, best.Profile.Elo) or "SERVER CHAMPION\nWaiting for challengers"
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
        model:PivotTo(CFrame.new(0, 6, -23) * CFrame.Angles(0, math.pi, 0))
        model.Parent = root
        championModel = model
    end)
end

return WorldService
