local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BeatTheBotRemotes")
local stateRemote = remotes:WaitForChild("State")
local submitRemote = remotes:WaitForChild("Submit")
local rematchRemote = remotes:WaitForChild("Rematch")

local current
local pending = false
local lastSent = 0
local history = {}
local lastHistoryTurn = -1
local lastProgress = 0
local lastSuspicion = 0

local colors = {
    Background = Color3.fromRGB(10, 15, 29),
    Panel = Color3.fromRGB(18, 25, 45),
    Panel2 = Color3.fromRGB(29, 39, 61),
    Cyan = Color3.fromRGB(73, 220, 236),
    Gold = Color3.fromRGB(255, 199, 89),
    Green = Color3.fromRGB(74, 222, 128),
    Red = Color3.fromRGB(236, 78, 89),
    White = Color3.fromRGB(239, 245, 255),
    Muted = Color3.fromRGB(166, 183, 206),
}

local screen = Instance.new("ScreenGui")
screen.Name = "BeatTheBotHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = player:WaitForChild("PlayerGui")

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = object
    return c
end

local function stroke(object, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or colors.Cyan
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.3
    s.Parent = object
    return s
end

local function label(parent, text, height, size, color, font)
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Size = UDim2.new(1, 0, 0, height)
    object.Text = text
    object.Font = font or Enum.Font.Gotham
    object.TextSize = size or 16
    object.TextColor3 = color or colors.White
    object.TextWrapped = true
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.RichText = false
    object.Parent = parent
    return object
end

local function button(parent, text, height, accent)
    local object = Instance.new("TextButton")
    object.Size = UDim2.new(1, 0, 0, height or 44)
    object.BackgroundColor3 = accent or colors.Panel2
    object.AutoButtonColor = true
    object.TextColor3 = colors.White
    object.Text = text
    object.TextSize = 15
    object.TextWrapped = true
    object.Font = Enum.Font.GothamMedium
    object.Parent = parent
    corner(object, 10)
    stroke(object, colors.Cyan, 1, 0.65)
    return object
end

local function ping(pitch)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    sound.Volume = 0.22
    sound.PlaybackSpeed = pitch or 1
    sound.Parent = SoundService
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    sound:Play()
end

local header = Instance.new("Frame")
header.Size = UDim2.new(0.94, 0, 0, 82)
header.Position = UDim2.new(0.03, 0, 0, 8)
header.BackgroundColor3 = colors.Panel
header.BackgroundTransparency = 0.05
header.Parent = screen
corner(header, 14)
stroke(header, colors.Cyan, 1.5, 0.45)

local stats = label(header, "BEAT THE BOT  |  Loading profile...", 36, 17, colors.Cyan, Enum.Font.GothamBold)
stats.Position = UDim2.fromOffset(14, 2)
stats.Size = UDim2.new(1, -130, 0, 36)

local guidance = label(header, "Walk to a glowing arena console. Beat the Guard in 8 moves.", 38, 13, colors.Muted)
guidance.Position = UDim2.fromOffset(14, 38)
guidance.Size = UDim2.new(1, -28, 0, 38)

local toggle = button(header, "MATCH", 34, Color3.fromRGB(31, 74, 92))
toggle.Size = UDim2.fromOffset(100, 34)
toggle.Position = UDim2.new(1, -114, 0, 6)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 100)
panel.Size = UDim2.new(0.94, 0, 0.74, -30)
panel.BackgroundColor3 = colors.Background
panel.BackgroundTransparency = 0.03
panel.Visible = false
panel.Parent = screen
corner(panel, 16)
stroke(panel, colors.Cyan, 1.5, 0.35)

local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(570, 880)
constraint.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(16, 14)
scroll.Size = UDim2.new(1, -32, 1, -28)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = colors.Cyan
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 18)
padding.Parent = scroll

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local order = 0
local function ordered(object)
    order += 1
    object.LayoutOrder = order
    return object
end

local opponentCard = Instance.new("Frame")
opponentCard.Size = UDim2.new(1, 0, 0, 78)
opponentCard.BackgroundColor3 = colors.Panel
opponentCard.Parent = scroll
corner(opponentCard, 12)
stroke(opponentCard, colors.Gold, 1.5, 0.35)
ordered(opponentCard)

local title = label(opponentCard, "🛡 THE CASTLE GUARD", 32, 22, colors.Gold, Enum.Font.GothamBold)
title.Position = UDim2.fromOffset(14, 8)
title.Size = UDim2.new(1, -28, 0, 32)

local subtitle = label(opponentCard, "RANKED OPPONENT  •  1,000 ELO  •  8 MOVES", 24, 12, colors.Muted, Enum.Font.GothamMedium)
subtitle.Position = UDim2.fromOffset(14, 43)
subtitle.Size = UDim2.new(1, -28, 0, 24)

local objective = ordered(label(
    scroll,
    "OBJECTIVE  •  Get your sealed delivery through the gate. Build trust before suspicion reaches 100% or your eight moves run out.",
    58,
    14,
    colors.White,
    Enum.Font.GothamMedium
))

local function meter(parent, name, fillColor)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 54)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local heading = label(holder, name, 20, 13, colors.Muted, Enum.Font.GothamBold)
    heading.Size = UDim2.new(0.7, 0, 0, 20)

    local value = label(holder, "0%", 20, 13, fillColor, Enum.Font.GothamBold)
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Position = UDim2.new(0.7, 0, 0, 0)
    value.Size = UDim2.new(0.3, 0, 0, 20)

    local track = Instance.new("Frame")
    track.Position = UDim2.fromOffset(0, 28)
    track.Size = UDim2.new(1, 0, 0, 14)
    track.BackgroundColor3 = colors.Panel2
    track.Parent = holder
    corner(track, 7)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = fillColor
    fill.Parent = track
    corner(fill, 7)

    return holder, fill, value
end

local trustHolder, trustFill, trustValue = meter(scroll, "TRUST", colors.Green)
ordered(trustHolder)
local suspicionHolder, suspicionFill, suspicionValue = meter(scroll, "SUSPICION", colors.Red)
ordered(suspicionHolder)

local statusLine = ordered(label(scroll, "MOVE 0 / 8  •  180s remaining", 28, 14, colors.Cyan, Enum.Font.GothamBold))

local responseCard = Instance.new("Frame")
responseCard.Size = UDim2.new(1, 0, 0, 0)
responseCard.AutomaticSize = Enum.AutomaticSize.Y
responseCard.BackgroundColor3 = colors.Panel
responseCard.Parent = scroll
corner(responseCard, 12)
stroke(responseCard, colors.Gold, 1, 0.65)
ordered(responseCard)

local responsePadding = Instance.new("UIPadding")
responsePadding.PaddingLeft = UDim.new(0, 14)
responsePadding.PaddingRight = UDim.new(0, 14)
responsePadding.PaddingTop = UDim.new(0, 12)
responsePadding.PaddingBottom = UDim.new(0, 12)
responsePadding.Parent = responseCard

local responseLabel = label(responseCard, "The Guard is waiting.", 0, 17, colors.White, Enum.Font.GothamMedium)
responseLabel.AutomaticSize = Enum.AutomaticSize.Y
responseLabel.Size = UDim2.new(1, 0, 0, 0)

local transcript = ordered(label(scroll, "", 0, 14, colors.Muted))
transcript.AutomaticSize = Enum.AutomaticSize.Y

local hint = ordered(label(scroll, "", 50, 14, colors.Gold, Enum.Font.GothamMedium))
ordered(label(scroll, "QUICK MOVES", 24, 13, colors.Muted, Enum.Font.GothamBold))

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, 0, 0, 52)
input.BackgroundColor3 = colors.Panel2
input.TextColor3 = colors.White
input.PlaceholderColor3 = colors.Muted
input.PlaceholderText = "Try your own argument..."
input.Text = ""
input.ClearTextOnFocus = false
input.MultiLine = false
input.TextSize = 16
input.Font = Enum.Font.Gotham
input.TextXAlignment = Enum.TextXAlignment.Left
input.Parent = scroll
corner(input, 10)
stroke(input, colors.Cyan, 1, 0.65)

local inputPadding = Instance.new("UIPadding")
inputPadding.PaddingLeft = UDim.new(0, 12)
inputPadding.PaddingRight = UDim.new(0, 12)
inputPadding.Parent = input

local function submit(kind, value)
    if not current or current.Status ~= "Playing" or pending then
        return
    end

    if os.clock() - lastSent < Config.RequestCooldown then
        return
    end

    if kind == "Text" and (#value == 0 or #value > Config.MaxMessageBytes) then
        guidance.Text = "Use 1–240 bytes, or select a quick move."
        return
    end

    pending = true
    lastSent = os.clock()
    guidance.Text = "The Guard is considering your move..."

    submitRemote:FireServer({
        MatchId = current.MatchId,
        Turn = current.Turns + 1,
        Kind = kind,
        Value = value,
    })
end

for _, choice in ipairs(Config.Choices) do
    local move = ordered(button(scroll, choice.Text, 44))
    move.Activated:Connect(function()
        submit("Choice", choice.Id)
    end)
end

input.Parent = scroll
ordered(input)

local send = ordered(button(scroll, "SEND ARGUMENT", 48, Color3.fromRGB(22, 102, 112)))
send.TextSize = 16
send.Activated:Connect(function()
    submit("Text", input.Text)
end)

input.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submit("Text", input.Text)
    end
end)

local hide = ordered(button(scroll, "WATCH FROM THE ARENA", 42))
hide.Activated:Connect(function()
    panel.Visible = false
end)

ordered(label(
    scroll,
    "Prototype opponent: rule-based local logic. The ranked server controls turns, results and ELO. Real AI will plug into the same adapter later.",
    70,
    12,
    colors.Muted
))

local resultOverlay = Instance.new("Frame")
resultOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
resultOverlay.Position = UDim2.fromScale(0.5, 0.5)
resultOverlay.Size = UDim2.fromOffset(430, 330)
resultOverlay.BackgroundColor3 = colors.Background
resultOverlay.Visible = false
resultOverlay.ZIndex = 20
resultOverlay.Parent = screen
corner(resultOverlay, 18)
stroke(resultOverlay, colors.Gold, 2, 0.15)

local resultConstraint = Instance.new("UISizeConstraint")
resultConstraint.MaxSize = Vector2.new(430, 360)
resultConstraint.MinSize = Vector2.new(290, 300)
resultConstraint.Parent = resultOverlay

local resultScale = Instance.new("UIScale")
resultScale.Scale = 0.9
resultScale.Parent = resultOverlay

local resultTitle = label(resultOverlay, "VICTORY", 54, 34, colors.Green, Enum.Font.GothamBlack)
resultTitle.TextXAlignment = Enum.TextXAlignment.Center
resultTitle.Position = UDim2.fromOffset(20, 28)
resultTitle.Size = UDim2.new(1, -40, 0, 54)

local resultReason = label(resultOverlay, "", 72, 16, colors.White, Enum.Font.GothamMedium)
resultReason.TextXAlignment = Enum.TextXAlignment.Center
resultReason.Position = UDim2.fromOffset(28, 91)
resultReason.Size = UDim2.new(1, -56, 0, 72)

local resultRating = label(resultOverlay, "", 38, 20, colors.Gold, Enum.Font.GothamBold)
resultRating.TextXAlignment = Enum.TextXAlignment.Center
resultRating.Position = UDim2.fromOffset(20, 162)
resultRating.Size = UDim2.new(1, -40, 0, 38)

local rematchButton = button(resultOverlay, "REMATCH THE GUARD", 48, Color3.fromRGB(22, 112, 95))
rematchButton.Position = UDim2.new(0.08, 0, 1, -112)
rematchButton.Size = UDim2.new(0.84, 0, 0, 48)
rematchButton.ZIndex = 21

local plazaButton = button(resultOverlay, "BACK TO PLAZA", 40, colors.Panel2)
plazaButton.Position = UDim2.new(0.08, 0, 1, -58)
plazaButton.Size = UDim2.new(0.84, 0, 0, 40)
plazaButton.ZIndex = 21

local function animateMeter(fill, valueLabel, value)
    valueLabel.Text = string.format("%d%%", value)
    TweenService:Create(
        fill,
        TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1) }
    ):Play()
end

local function flashGuidance(text, color)
    guidance.Text = text
    guidance.TextColor3 = color
    task.delay(0.75, function()
        if guidance.Parent then
            guidance.TextColor3 = colors.Muted
        end
    end)
end

local function showResult(packet)
    local won = packet.Status == "Won"
    resultTitle.Text = won and "GATE BROKEN" or "THE GUARD WINS"
    resultTitle.TextColor3 = won and colors.Green or colors.Red
    resultReason.Text = packet.Message
    resultRating.Text = string.format("ELO %+d", packet.Delta or 0)
    resultOverlay.Visible = true
    resultScale.Scale = 0.86

    TweenService:Create(
        resultScale,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = 1 }
    ):Play()

    ping(won and 1.25 or 0.72)
end

rematchButton.Activated:Connect(function()
    if not current or current.Status == "Playing" then
        return
    end
    resultOverlay.Visible = false
    panel.Visible = true
    guidance.Text = "Setting up the rematch..."
    rematchRemote:FireServer()
end)

plazaButton.Activated:Connect(function()
    resultOverlay.Visible = false
    panel.Visible = false
    guidance.Text = "Walk to any glowing console when you want another match."
end)

toggle.Activated:Connect(function()
    if current then
        panel.Visible = not panel.Visible
    else
        guidance.Text = "Walk to a glowing console and use its Challenge Guard prompt."
    end
end)

stateRemote.OnClientEvent:Connect(function(packet)
    pending = false

    if packet.Kind == "Notice" then
        guidance.Text = packet.Message
        return
    end

    if packet.Kind ~= "Match" then
        return
    end

    if not current or current.MatchId ~= packet.MatchId then
        history = {}
        lastHistoryTurn = -1
        lastProgress = 0
        lastSuspicion = 0
        resultOverlay.Visible = false
        panel.Visible = true
        scroll.CanvasPosition = Vector2.zero
    end

    current = packet

    animateMeter(trustFill, trustValue, packet.Progress)
    animateMeter(suspicionFill, suspicionValue, packet.Suspicion)

    if packet.Progress > lastProgress then
        flashGuidance(string.format("+%d TRUST", packet.Progress - lastProgress), colors.Green)
        ping(1.12)
    elseif packet.Suspicion > lastSuspicion then
        flashGuidance(string.format("+%d SUSPICION", packet.Suspicion - lastSuspicion), colors.Red)
        ping(0.86)
    end

    lastProgress = packet.Progress
    lastSuspicion = packet.Suspicion

    title.Text = packet.Status == "Playing"
        and "🛡 THE CASTLE GUARD"
        or string.upper(packet.Status == "Won" and "GATE OPEN" or "GATE CLOSED")

    if packet.Turns ~= lastHistoryTurn then
        lastHistoryTurn = packet.Turns
        if packet.Summary then
            table.insert(history, "YOU  •  " .. packet.Summary)
        end
        table.insert(history, "GUARD  •  " .. packet.Message)
    elseif #history > 0 then
        history[#history] = "GUARD  •  " .. packet.Message
    else
        table.insert(history, "GUARD  •  " .. packet.Message)
    end

    responseLabel.Text = packet.Message
    transcript.Text = table.concat(history, "\n\n")
    hint.Text = packet.Status == "Playing" and ("TACTICAL HINT  •  " .. packet.Hint) or "Result locked. Rematch or return to the plaza."
    guidance.Text = packet.Status == "Playing"
        and "Choose a move or write your own argument."
        or packet.Message

    if packet.Delta ~= nil then
        guidance.Text = string.format(
            "%s  •  ELO %+d%s",
            string.upper(packet.Status),
            packet.Delta,
            player:GetAttribute("SessionOnly") and "  •  TEST SESSION" or ""
        )
        showResult(packet)
    end

    input.Text = ""
end)

task.spawn(function()
    local leaderstats = player:WaitForChild("leaderstats")
    local elo = leaderstats:WaitForChild("Elo")
    local wins = leaderstats:WaitForChild("Wins")
    local losses = leaderstats:WaitForChild("Losses")

    local function refresh()
        stats.Text = string.format(
            "ELO %d  •  W %d  L %d%s",
            elo.Value,
            wins.Value,
            losses.Value,
            player:GetAttribute("SessionOnly") and "  •  TEST ONLY" or ""
        )
    end

    elo.Changed:Connect(refresh)
    wins.Changed:Connect(refresh)
    losses.Changed:Connect(refresh)
    player:GetAttributeChangedSignal("SessionOnly"):Connect(refresh)
    refresh()
end)

RunService.Heartbeat:Connect(function()
    if current and current.Status == "Playing" then
        statusLine.Text = string.format(
            "MOVE %d / %d  •  %ds remaining",
            current.Turns,
            Config.MaxTurns,
            math.max(0, math.ceil(current.Deadline - workspace:GetServerTimeNow()))
        )
    elseif current then
        statusLine.Text = "MATCH COMPLETE"
    else
        statusLine.Text = "FIND AN ARENA TO BEGIN"
    end
end)