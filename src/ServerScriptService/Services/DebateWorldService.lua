-- DebateWorldService builds the v0.5.1 guardian-temple debate arena at runtime.
-- Presentation only: no debate state, scoring, or authority lives here.
-- Public API preserved: World.Init() -> workspace.BeatTheBotDebateStage with
-- child DebateSpawn; World.Spawn; World.Refresh() no-op. Primitive parts only.
-- Judge/podium reaction API (consumed by MultiplayerDebateService):
-- World.React(reactions), World.SetActivePlayer(playerIndex),
-- World.Celebrate(leadingUserId, players), World.PlaySound(name).
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local World = { Spawn = nil, Judges = {}, Podiums = {}, Sounds = {} }

-- Temple lighting baseline, restored after reaction flashes (configureLighting owns it).
local TEMPLE_COLOR_SHIFT_TOP = Color3.fromRGB(18, 70, 72)
local EYE_BASE_SIZE = Vector3.new(4.4, 0.75, 0.35)
local podiumData = {} -- [podium part] = { BaseY = number, Top = neon part }
local C = {
    void = Color3.fromRGB(5, 10, 13),
    stone = Color3.fromRGB(22, 31, 35),
    stone2 = Color3.fromRGB(35, 47, 51),
    slate = Color3.fromRGB(48, 61, 64),
    armor = Color3.fromRGB(18, 27, 31),
    armorEdge = Color3.fromRGB(44, 61, 65),
    cyan = Color3.fromRGB(42, 242, 229),
    teal = Color3.fromRGB(20, 174, 170),
    pale = Color3.fromRGB(205, 255, 250),
    warm = Color3.fromRGB(255, 135, 45),
    ember = Color3.fromRGB(255, 197, 85),
    banner = Color3.fromRGB(8, 14, 17),
}

local function part(name, size, pos, color, parent, material)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Position = name, size, pos
    p.Anchored = true
    p.Color = color
    p.Material = material or Enum.Material.Slate
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function deco(name, size, pos, color, parent, material)
    local p = part(name, size, pos, color, parent, material)
    p.CanCollide = false
    return p
end

local function surface(target, canvas)
    local g = Instance.new("SurfaceGui")
    g.Face = Enum.NormalId.Front
    g.CanvasSize = canvas or Vector2.new(900, 300)
    g.LightInfluence = 0.15
    g.Parent = target
    return g
end

local function text(parent, value, color, name)
    local l = Instance.new("TextLabel")
    l.Name = name or "Text"
    l.Size = UDim2.fromScale(1, 1)
    l.BackgroundTransparency = 1
    l.Text = value
    l.TextColor3 = color or C.pale
    l.TextScaled = true
    l.TextWrapped = true
    l.Font = Enum.Font.GothamBold
    l.Parent = parent
    return l
end

local function pointLight(parent, color, range, brightness)
    local l = Instance.new("PointLight")
    l.Color = color
    l.Range = range or 24
    l.Brightness = brightness or 1.4
    l.Shadows = true
    l.Parent = parent
    return l
end

local function cylinder(name, size, pos, color, parent, material, rotation)
    local p = part(name, size, pos, color, parent, material)
    p.Shape = Enum.PartType.Cylinder
    p.CFrame = CFrame.new(pos) * (rotation or CFrame.Angles(0, 0, math.rad(90)))
    return p
end

local function torchBowl(root, x, y, z)
    cylinder("FireBowl", Vector3.new(1.5, 4.2, 4.2), Vector3.new(x, y, z), C.armorEdge, root, Enum.Material.Metal)
    local flame = deco("TempleFlame", Vector3.new(2.0, 2.8, 2.0), Vector3.new(x, y + 2.1, z), C.warm, root, Enum.Material.Neon)
    flame.Shape = Enum.PartType.Ball
    pointLight(flame, C.ember, 28, 2.5)
    local fire = Instance.new("Fire")
    fire.Color, fire.SecondaryColor = C.ember, C.warm
    fire.Size, fire.Heat = 6, 5
    fire.Parent = flame
end

local function rune(root, x, y, z, scale)
    scale = scale or 1
    deco("RuneStem", Vector3.new(0.8 * scale, 13 * scale, 0.35), Vector3.new(x, y, z), C.cyan, root, Enum.Material.Neon)
    local top = deco("RuneTop", Vector3.new(7 * scale, 0.75 * scale, 0.35), Vector3.new(x, y + 4.5 * scale, z), C.cyan, root, Enum.Material.Neon)
    top.CFrame = CFrame.new(top.Position) * CFrame.Angles(0, 0, math.rad(45))
    local bot = deco("RuneBottom", Vector3.new(7 * scale, 0.75 * scale, 0.35), Vector3.new(x, y - 4.5 * scale, z), C.cyan, root, Enum.Material.Neon)
    bot.CFrame = CFrame.new(bot.Position) * CFrame.Angles(0, 0, math.rad(-45))
    local core = deco("RuneCore", Vector3.new(3.5 * scale, 3.5 * scale, 0.45), Vector3.new(x, y, z - 0.05), C.teal, root, Enum.Material.Neon)
    core.Shape = Enum.PartType.Ball
    pointLight(core, C.cyan, 38, 2.3)
end

local function banner(root, x, y, z)
    local cloth = deco("TempleBanner", Vector3.new(9, 22, 0.6), Vector3.new(x, y, z), C.banner, root, Enum.Material.Fabric)
    deco("BannerBar", Vector3.new(12, 0.7, 0.8), Vector3.new(x, y + 11.5, z), C.armorEdge, root, Enum.Material.Metal)
    deco("BannerSigilV", Vector3.new(0.6, 11, 0.25), Vector3.new(x, y, z + 0.43), C.teal, root, Enum.Material.Neon)
    local mark = deco("BannerSigilH", Vector3.new(5.5, 0.6, 0.25), Vector3.new(x, y + 1.2, z + 0.43), C.teal, root, Enum.Material.Neon)
    mark.CFrame = CFrame.new(mark.Position) * CFrame.Angles(0, 0, math.rad(45))
    cloth.CanCollide = false
end

local function blade(root, name, x, y, z, height, halberd)
    local shaft = part(name .. "Shaft", Vector3.new(0.7, height, 0.7), Vector3.new(x, y, z), C.armorEdge, root, Enum.Material.Metal)
    shaft.CanCollide = false
    local spear = part(name .. "Blade", Vector3.new(2.5, 5.5, 0.7), Vector3.new(x, y + height * 0.5 + 2.1, z), C.slate, root, Enum.Material.Metal)
    spear.CanCollide = false
    if halberd then
        local axe = part(name .. "Axe", Vector3.new(4.8, 2.5, 0.8), Vector3.new(x + 1.8, y + height * 0.5 + 0.6, z), C.slate, root, Enum.Material.Metal)
        axe.CanCollide = false
        deco(name .. "Rune", Vector3.new(0.35, 3.2, 0.85), Vector3.new(x, y + height * 0.5 + 2, z + 0.1), C.cyan, root, Enum.Material.Neon)
    end
end

local function guardian(root, name, criterion, position, central)
    local model = Instance.new("Model")
    model.Name = "Judge" .. name
    model.Parent = root
    local x, y, z = position.X, position.Y, position.Z
    local dais = part("Dais", Vector3.new(14, 3, 10), Vector3.new(x, y, z), C.stone, model, Enum.Material.Cobblestone)
    deco("DaisRune", Vector3.new(10, 0.45, 10.3), Vector3.new(x, y + 1.7, z), C.teal, model, Enum.Material.Neon)
    part("Cape", Vector3.new(9, 11, 2.0), Vector3.new(x, y + 7.3, z - 2), C.banner, model, Enum.Material.Fabric)
    part("TorsoArmor", Vector3.new(8.5, 9.5, 5.2), Vector3.new(x, y + 8, z), C.armor, model, Enum.Material.Metal)
    part("ChestPlate", Vector3.new(6.4, 5.8, 1.2), Vector3.new(x, y + 9.2, z + 2.6), C.armorEdge, model, Enum.Material.Metal)
    part("PauldronL", Vector3.new(4.2, 2.3, 5.8), Vector3.new(x - 5.1, y + 11.4, z), C.armorEdge, model, Enum.Material.Metal)
    part("PauldronR", Vector3.new(4.2, 2.3, 5.8), Vector3.new(x + 5.1, y + 11.4, z), C.armorEdge, model, Enum.Material.Metal)
    part("ArmL", Vector3.new(2.1, 8.5, 2.3), Vector3.new(x - 5, y + 6.8, z), C.armor, model, Enum.Material.Metal)
    part("ArmR", Vector3.new(2.1, 8.5, 2.3), Vector3.new(x + 5, y + 6.8, z), C.armor, model, Enum.Material.Metal)
    local hood = part("Hood", Vector3.new(7.4, 6.8, 6.2), Vector3.new(x, y + 16.6, z), C.armor, model, Enum.Material.Metal)
    local face = deco("FaceVoid", Vector3.new(5.2, 3.4, 0.8), Vector3.new(x, y + 16.2, z + 3.1), C.void, model, Enum.Material.SmoothPlastic)
    local eyes = deco("GlowingEyes", Vector3.new(4.4, 0.75, 0.35), Vector3.new(x, y + 16.5, z + 3.58), C.cyan, model, Enum.Material.Neon)
    if central then
        deco("VisorStem", Vector3.new(0.65, 2.5, 0.4), Vector3.new(x, y + 15.7, z + 3.6), C.cyan, model, Enum.Material.Neon)
        blade(model, "Halberd", x + 7, y + 10, z + 0.5, 22, true)
    else
        part("CloakSkirt", Vector3.new(10, 8, 5), Vector3.new(x, y + 2.8, z - 0.8), C.banner, model, Enum.Material.Fabric)
        blade(model, "SentinelSword", x, y + 8, z + 4.2, 17, false)
        part("SwordGuard", Vector3.new(5.5, 0.7, 0.8), Vector3.new(x, y + 9.6, z + 4.2), C.slate, model, Enum.Material.Metal)
    end
    deco("ChestRune", Vector3.new(0.8, 4.0, 0.35), Vector3.new(x, y + 9.1, z + 3.25), C.teal, model, Enum.Material.Neon)
    local eyeLight = pointLight(eyes, C.cyan, 38, central and 3.2 or 2.3)
    pointLight(face, C.teal, 22, 1.0)
    local tag = Instance.new("BillboardGui")
    tag.Name = "JudgeTag"
    tag.Size = UDim2.fromOffset(290, 76)
    tag.StudsOffset = Vector3.new(0, 5.4, 0)
    tag.AlwaysOnTop = true
    tag.Parent = hood
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = C.void
    label.BackgroundTransparency = 0.2
    label.Text = name .. "  -  " .. criterion .. "  -  SCRIPTED"
    label.TextColor3 = C.cyan
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.Parent = tag
    model.PrimaryPart = dais
    model:SetAttribute("BaseY", y)
    face.CanCollide = false
    World.Judges[name] = { Model = model, Eye = eyes, Light = eyeLight, BaseBrightness = central and 3.2 or 2.3 }
    return model
end

local function creature(root, name, x, z, kind)
    local m = Instance.new("Model")
    m.Name, m.Parent = name, root
    local body = part("Body", Vector3.new(3.2, 3.2, 3.2), Vector3.new(x, 2.5, z), C.armorEdge, m, Enum.Material.Metal)
    if kind == "blob" then body.Shape = Enum.PartType.Ball end
    deco("Visor", Vector3.new(2.1, 0.45, 0.25), Vector3.new(x, 2.8, z + 1.65), C.cyan, m, Enum.Material.Neon)
    part("FootL", Vector3.new(1, 0.8, 1.1), Vector3.new(x - 0.85, 0.4, z), C.armor, m, Enum.Material.Metal)
    part("FootR", Vector3.new(1, 0.8, 1.1), Vector3.new(x + 0.85, 0.4, z), C.armor, m, Enum.Material.Metal)
    pointLight(body, C.teal, 12, 0.6)
    local tag = Instance.new("BillboardGui")
    tag.Name, tag.Size, tag.StudsOffset, tag.AlwaysOnTop = "CollectibleTag", UDim2.fromOffset(170, 36), Vector3.new(0, 4, 0), true
    tag.Parent = body
    local l = text(tag, name .. " - PLACEHOLDER COLLECTIBLE", C.pale)
    l.BackgroundColor3, l.BackgroundTransparency = C.void, 0.2
    m.PrimaryPart = body
    return m
end

local function collectibleInteraction(model)
    local body = model:FindFirstChild("Body")
    if not body then return end
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name, prompt.ActionText, prompt.ObjectText = "ComingSoonPrompt", "COLLECT", model.Name
    prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0.25, 10, false
    prompt.Parent = body
    prompt.Triggered:Connect(function(player)
        local gui = Instance.new("ScreenGui")
        gui.Name, gui.ResetOnSpawn = "CollectibleComingSoon", false
        local card = Instance.new("TextLabel")
        card.AnchorPoint, card.Position, card.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.72), UDim2.fromOffset(320, 72)
        card.BackgroundColor3, card.BackgroundTransparency = C.void, 0.08
        card.TextColor3, card.TextScaled, card.Font = C.pale, true, Enum.Font.GothamBold
        card.Text = model.Name .. " COLLECTION - COMING SOON"
        card.Parent = gui
        gui.Parent = player:FindFirstChildOfClass("PlayerGui")
        task.delay(2.5, function() if gui.Parent then gui:Destroy() end end)
    end)
end

local function animateWorld(root, judges, creatures)
    task.spawn(function()
        local started = os.clock()
        while root.Parent do
            local t = os.clock() - started
            for index, model in ipairs(judges) do
                local base = model:GetAttribute("BasePivot")
                if base then model:PivotTo(base * CFrame.new(0, math.sin(t * 0.85 + index) * 0.32, 0) * CFrame.Angles(math.rad(math.sin(t * 0.55 + index) * 0.7), 0, 0)) end
            end
            for index, model in ipairs(creatures) do
                local base = model:GetAttribute("BasePivot")
                if base then model:PivotTo(base * CFrame.new(0, math.sin(t * 1.8 + index) * 0.28, 0) * CFrame.Angles(0, t * 0.28, 0)) end
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

local function configureLighting()
    Lighting.ClockTime = 20.2
    Lighting.Brightness = 1.25
    Lighting.Ambient = Color3.fromRGB(18, 46, 50)
    Lighting.OutdoorAmbient = Color3.fromRGB(9, 25, 30)
    Lighting.ColorShift_Top = Color3.fromRGB(18, 70, 72)
    Lighting.ColorShift_Bottom = Color3.fromRGB(4, 13, 17)
    Lighting.EnvironmentDiffuseScale = 0.35
    Lighting.EnvironmentSpecularScale = 1
    Lighting.ExposureCompensation = -0.35
    Lighting.ShadowSoftness = 0.28
    pcall(function() Lighting.LightingStyle = Enum.LightingStyle.Realistic end)
    for _, name in ipairs({"GuardianTempleAtmosphere", "GuardianTempleColor"}) do
        local old = Lighting:FindFirstChild(name)
        if old then old:Destroy() end
    end
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "GuardianTempleAtmosphere"
    atmosphere.Color = Color3.fromRGB(64, 105, 108)
    atmosphere.Decay = Color3.fromRGB(8, 22, 28)
    atmosphere.Density = 0.43
    atmosphere.Offset = 0.05
    atmosphere.Glare = 0.08
    atmosphere.Haze = 2.2
    atmosphere.Parent = Lighting
    local grade = Instance.new("ColorCorrectionEffect")
    grade.Name = "GuardianTempleColor"
    grade.Brightness = -0.05
    grade.Contrast = 0.22
    grade.Saturation = -0.22
    grade.TintColor = Color3.fromRGB(175, 230, 225)
    grade.Parent = Lighting
end

-- Arena audio. Sound IDs are the repo's configured IDs; leave them untouched
-- until each one is verified in Studio.
local function sound(parent, name, id, volume)
    local s = Instance.new("Sound")
    s.Name = name
    s.SoundId = "rbxassetid://" .. id
    s.Volume = volume
    s.RollOffMaxDistance = 90
    s.Parent = parent
    World.Sounds[name] = s
    return s
end

function World.PlaySound(name)
    local s = World.Sounds[name]
    if s then
        s.TimePosition = 0
        s:Play()
    end
end

-- Judge reaction flash. The guardians idle-bob every Heartbeat via animateWorld,
-- so the reaction is the eye flash (no model tilt; it would be overwritten).
function World.React(reactions)
    for _, reaction in ipairs(reactions or {}) do
        -- JudgeService emits mixed-case ids ("Rivet"); the arena registers uppercase.
        local data = World.Judges[string.upper(tostring(reaction.Judge or ""))]
        if data and data.Eye and data.Eye.Parent then
            local eye = data.Eye
            TweenService:Create(eye, TweenInfo.new(0.16), {
                Transparency = reaction.Earned and 0 or 0.45,
                Size = reaction.Earned and Vector3.new(5.2, 1.05, 0.4) or EYE_BASE_SIZE,
            }):Play()
            if data.Light and data.Light.Parent then
                TweenService:Create(data.Light, TweenInfo.new(0.16), {
                    Brightness = reaction.Earned and (data.BaseBrightness + 1.6) or 0.9,
                }):Play()
            end
            task.delay(0.3, function()
                if eye.Parent then
                    TweenService:Create(eye, TweenInfo.new(0.25), { Transparency = 0, Size = EYE_BASE_SIZE }):Play()
                    if data.Light and data.Light.Parent then
                        TweenService:Create(data.Light, TweenInfo.new(0.25), { Brightness = data.BaseBrightness }):Play()
                    end
                end
            end)
        end
    end
end

-- Active-player podium cue: raise the speaker's podium and warm its neon top.
function World.SetActivePlayer(playerIndex)
    for index, podium in pairs(World.Podiums) do
        local data = podiumData[podium]
        local active = index == playerIndex
        if data then
            TweenService:Create(podium, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = Vector3.new(podium.Position.X, data.BaseY + (active and 0.55 or 0), podium.Position.Z),
            }):Play()
            if data.Top and data.Top.Parent then
                data.Top.Color = active and C.ember or C.cyan
            end
        end
    end
    Lighting.ColorShift_Top = C.cyan
    task.delay(0.18, function()
        Lighting.ColorShift_Top = TEMPLE_COLOR_SHIFT_TOP
    end)
    World.PlaySound("TurnStart")
end

-- Round-end celebration: ember light wash, spotlight on the leading podium, confetti.
function World.Celebrate(leadingUserId, players)
    Lighting.ColorShift_Top = C.ember
    World.PlaySound("VerdictSting")
    local leadingIndex = nil
    for index, player in ipairs(players or {}) do
        if player.UserId == leadingUserId then
            leadingIndex = index
        end
    end
    if leadingIndex then
        local podium = World.Podiums[leadingIndex]
        if podium then
            local rig = Instance.new("Part")
            rig.Name = "ChecklistLeadSpotlight"
            rig.Size = Vector3.new(1, 1, 1)
            rig.CFrame = CFrame.new(podium.Position + Vector3.new(0, 25, 0))
            rig.Transparency = 1
            rig.Anchored = true
            rig.CanCollide = false
            rig.Parent = podium.Parent
            local spot = Instance.new("SpotLight")
            spot.Color = C.ember
            spot.Brightness = 8
            spot.Range = 45
            spot.Angle = 70
            spot.Face = Enum.NormalId.Bottom
            spot.Parent = rig
            task.delay(6, function()
                if rig.Parent then rig:Destroy() end
            end)
        end
        World.PlaySound("MatchWin")
    end
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "ChecklistConfetti"
    emitter.Texture = "rbxassetid://241837157"
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.cyan),
        ColorSequenceKeypoint.new(0.5, C.ember),
        ColorSequenceKeypoint.new(1, C.pale),
    })
    emitter.Lifetime = NumberRange.new(2, 3)
    emitter.Speed = NumberRange.new(14, 22)
    emitter.SpreadAngle = Vector2.new(80, 80)
    emitter.Rate = 0
    emitter.Parent = World.Spawn
    emitter:Emit(120)
    task.delay(5, function()
        if emitter.Parent then emitter:Destroy() end
        Lighting.ColorShift_Top = TEMPLE_COLOR_SHIFT_TOP
    end)
end

function World.Init()
    for _, name in ipairs({"BeatTheBotWorld", "BeatTheBotDebateStage"}) do
        local old = workspace:FindFirstChild(name)
        if old then old:Destroy() end
    end
    World.Judges = {}
    World.Podiums = {}
    World.Sounds = {}
    podiumData = {}
    configureLighting()
    local root = Instance.new("Folder")
    root.Name, root.Parent = "BeatTheBotDebateStage", workspace

    -- Wet dark-stone floor: a thin reflective glass skin catches cyan and fire light.
    part("TempleFloor", Vector3.new(94, 2, 94), Vector3.new(0, -1, 0), C.stone, root, Enum.Material.Cobblestone)
    local wet = deco("WetStoneSheen", Vector3.new(92, 0.12, 92), Vector3.new(0, 0.06, 0), C.slate, root, Enum.Material.Glass)
    wet.Transparency, wet.Reflectance = 0.58, 0.22
    deco("CenterRune", Vector3.new(1.0, 0.16, 72), Vector3.new(0, 0.14, 0), C.teal, root, Enum.Material.Neon)
    for z = -32, 32, 8 do
        deco("FloorRune", Vector3.new(25, 0.12, 0.34), Vector3.new(0, 0.16, z), C.teal, root, Enum.Material.Neon).Transparency = 0.45
    end

    -- Monumental temple wall, stepped towers, pillars, banners, and cyan rune gate.
    part("TempleBackdrop", Vector3.new(86, 48, 5), Vector3.new(0, 23, -43), C.stone, root, Enum.Material.Slate)
    part("TempleGate", Vector3.new(24, 38, 3), Vector3.new(0, 18, -39.8), C.void, root, Enum.Material.Metal)
    rune(root, 0, 21, -37.9, 1.25)
    for _, x in ipairs({-38, -27, -15, 15, 27, 38}) do
        part("TemplePillar", Vector3.new(7, 52, 7), Vector3.new(x, 25, -38.5), C.stone2, root, Enum.Material.Cobblestone)
        part("PillarCap", Vector3.new(9, 2.2, 9), Vector3.new(x, 50, -38.5), C.slate, root, Enum.Material.Slate)
        deco("PillarRune", Vector3.new(0.7, 25, 0.35), Vector3.new(x, 28, -34.8), C.teal, root, Enum.Material.Neon)
    end
    banner(root, -31, 25, -34.5)
    banner(root, 31, 25, -34.5)
    for _, x in ipairs({-42, -24, 24, 42}) do torchBowl(root, x, 3, -27) end

    -- Raised debate stage and opposing podiums, now carved stone with cyan inlays.
    part("Stage", Vector3.new(40, 1.8, 30), Vector3.new(0, 0.9, -1), C.stone2, root, Enum.Material.Slate)
    deco("StageFrontRune", Vector3.new(34, 0.45, 0.45), Vector3.new(0, 1.85, 14.2), C.cyan, root, Enum.Material.Neon)
    for _, side in ipairs({{dir=-1,label="DEBATER ONE"},{dir=1,label="DEBATER TWO"}}) do
        local x = 13 * side.dir
        part("Platform" .. side.dir, Vector3.new(10, 1, 10), Vector3.new(x, 2.1, 2), C.slate, root, Enum.Material.Cobblestone)
        local podium = part("Podium" .. side.dir, Vector3.new(3, 3.6, 2), Vector3.new(x, 4.4, 5.4), C.armor, root, Enum.Material.Metal)
        local podiumTop = deco("PodiumTop" .. side.dir, Vector3.new(3.4, 0.35, 2.4), Vector3.new(x, 6.3, 5.4), C.cyan, root, Enum.Material.Neon)
        local podiumIndex = side.dir == -1 and 1 or 2
        World.Podiums[podiumIndex] = podium
        podiumData[podium] = { BaseY = 4.4, Top = podiumTop }
        local board = part("Backboard" .. side.dir, Vector3.new(10, 7, 1), Vector3.new(x, 6.5, -3.4), C.armor, root, Enum.Material.Metal)
        deco("BoardTrim" .. side.dir, Vector3.new(10.4, 0.45, 0.6), Vector3.new(x, 10.1, -3.4), C.teal, root, Enum.Material.Neon)
        text(surface(board, Vector2.new(600,420)), side.label, C.cyan)
        pointLight(board, C.teal, 18, 0.8)
    end

    part("HostPlatform", Vector3.new(12, 1.2, 9), Vector3.new(0, 2.2, -11), C.slate, root, Enum.Material.Slate)
    local hostBoard = part("HostBoard", Vector3.new(14, 9, 1), Vector3.new(0, 7.5, -15.4), C.armor, root, Enum.Material.Metal)
    text(surface(hostBoard, Vector2.new(840,540)), "SCRIPTED HOST", C.cyan)
    local marquee = part("TopicDisplay", Vector3.new(24, 5, 1), Vector3.new(0, 14.5, -15.2), C.void, root, Enum.Material.Metal)
    deco("MarqueeTrim", Vector3.new(24.6, 0.5, 0.6), Vector3.new(0, 17.3, -15.2), C.cyan, root, Enum.Material.Neon)
    text(surface(marquee, Vector2.new(1300,300)), "TONIGHT'S TOPIC APPEARS HERE", C.pale, "TopicText")
    pointLight(marquee, C.teal, 26, 1.1)

    local scoreboard = part("Scoreboard", Vector3.new(16, 4, 1), Vector3.new(0, 10.5, 13.5), C.void, root, Enum.Material.Metal)
    local sg = surface(scoreboard, Vector2.new(960,240))
    local sl = text(sg, "0", C.cyan, "ScoreLeftText"); sl.Size = UDim2.fromScale(0.42,1)
    local vs = text(sg, "VS", C.pale, "VsText"); vs.Size = UDim2.fromScale(0.16,1)
    local sr = text(sg, "0", C.cyan, "ScoreRightText"); sr.Size = UDim2.fromScale(0.42,1); sr.Position = UDim2.fromScale(0.58,0)
    pointLight(scoreboard, C.teal, 22, 1.0)

    -- RIVET and MOSS are hooded sword sentinels; central PIP bears the halberd.
    local judges = {
        guardian(root, "RIVET", "STRUCTURE / BECAUSE", Vector3.new(-23, 17, -27), false),
        guardian(root, "PIP", "EVIDENCE / FOR EXAMPLE", Vector3.new(0, 21, -32), true),
        guardian(root, "MOSS", "REBUTTAL / HOWEVER", Vector3.new(23, 17, -27), false),
    }
    for _, judge in ipairs(judges) do judge:SetAttribute("BasePivot", judge:GetPivot()) end

    local creatures = {creature(root,"BLIP",-31,18,"blob"),creature(root,"ZAPP",31,18,"cube"),creature(root,"CHOMP",0,27,"cube")}
    for _, collectible in ipairs(creatures) do
        collectibleInteraction(collectible)
        collectible:SetAttribute("BasePivot", collectible:GetPivot())
    end
    animateWorld(root, judges, creatures)

    local revealIndex = 0
    for _, object in ipairs(root:GetDescendants()) do
        if object:IsA("BasePart") and object.Name ~= "TempleFloor" and object.Name ~= "WetStoneSheen" then
            revealIndex += 1
            local goal = object.Position
            object.Position = goal - Vector3.new(0, math.min(12, math.max(2, goal.Y + 1)), 0)
            TweenService:Create(object, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, math.min(1.0, revealIndex * 0.009)), {Position=goal}):Play()
        end
    end

    local audio = part("ArenaAudio", Vector3.new(1, 1, 1), Vector3.new(0, 4, 0), C.armor, root)
    audio.Transparency = 1
    audio.CanCollide = false
    sound(audio, "TurnStart", "6026984224", 0.18)
    sound(audio, "TenSecondWarning", "6026984224", 0.14)
    sound(audio, "ScoreTick", "911342077", 0.1)
    sound(audio, "VerdictSting", "1843529634", 0.2)
    sound(audio, "MatchWin", "1843529607", 0.22)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name, spawn.Size, spawn.Position = "DebateSpawn", Vector3.new(10,1,6), Vector3.new(0,1,20)
    spawn.Anchored, spawn.Neutral, spawn.Duration, spawn.Transparency = true, true, 0, 1
    spawn.Parent = root
    World.Spawn = spawn
    return root
end

function World.Refresh() end
return World
