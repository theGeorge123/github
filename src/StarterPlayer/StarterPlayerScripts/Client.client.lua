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
local lastRenderedTurn = -1
local pendingTurn
local pendingPlayerBubble
local thinkingWrapper
local thinkingSpeaker
local thinkingBubble
local lastProgress = 0
local lastSuspicion = 0
local suggestionIds = {}
local suggestionTexts = {}
local submit

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

local subtitle = label(opponentCard, "AI-POWERED  •  RANKED OPPONENT  •  8 MOVES", 24, 12, colors.Muted, Enum.Font.GothamMedium)
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

local conversation = Instance.new("Frame")
conversation.Size = UDim2.new(1, 0, 0, 0)
conversation.AutomaticSize = Enum.AutomaticSize.Y
conversation.BackgroundTransparency = 1
conversation.Parent = scroll
ordered(conversation)

local conversationLayout = Instance.new("UIListLayout")
conversationLayout.Padding = UDim.new(0, 10)
conversationLayout.SortOrder = Enum.SortOrder.LayoutOrder
conversationLayout.Parent = conversation

local function addConversationBubble(speakerText, message, isPlayer, muted)
    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 0)
    wrapper.AutomaticSize = Enum.AutomaticSize.Y
    wrapper.BackgroundTransparency = 1
    wrapper.Parent = conversation

    local bubbleLayout = Instance.new("UIListLayout")
    bubbleLayout.Padding = UDim.new(0, 4)
    bubbleLayout.HorizontalAlignment = isPlayer and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
    bubbleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bubbleLayout.Parent = wrapper

    local speaker = label(wrapper, speakerText, 18, 11, isPlayer and colors.Cyan or colors.Gold, Enum.Font.GothamBold)
    speaker.AutomaticSize = Enum.AutomaticSize.Y
    speaker.Size = UDim2.new(0.88, 0, 0, 0)
    speaker.TextXAlignment = isPlayer and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left

    local bubble = label(wrapper, message, 0, 16, muted and colors.Muted or colors.White, Enum.Font.GothamMedium)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Size = UDim2.new(0.88, 0, 0, 0)
    bubble.BackgroundTransparency = 0
    bubble.BackgroundColor3 = isPlayer and Color3.fromRGB(26, 70, 86) or colors.Panel
    bubble.TextXAlignment = Enum.TextXAlignment.Left

    local bubblePadding = Instance.new("UIPadding")
    bubblePadding.PaddingLeft = UDim.new(0, 12)
    bubblePadding.PaddingRight = UDim.new(0, 12)
    bubblePadding.PaddingTop = UDim.new(0, 10)
    bubblePadding.PaddingBottom = UDim.new(0, 10)
    bubblePadding.Parent = bubble

    corner(bubble, 12)
    stroke(bubble, isPlayer and colors.Cyan or colors.Gold, 1, 0.7)

    return wrapper, speaker, bubble
end

local function clearConversation()
    for _, child in ipairs(conversation:GetChildren()) do
        if child ~= conversationLayout then
            child:Destroy()
        end
    end
    thinkingWrapper = nil
    thinkingSpeaker = nil
    thinkingBubble = nil
    pendingPlayerBubble = nil
    pendingTurn = nil
    lastRenderedTurn = -1
end

local function scrollToLatest()
    task.defer(function()
        task.wait()
        local maxY = math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y)
        scroll.CanvasPosition = Vector2.new(0, maxY)
    end)
end

local function startThinking()
    if thinkingWrapper then
        thinkingWrapper:Destroy()
    end
    thinkingWrapper, thinkingSpeaker, thinkingBubble = addConversationBubble("GUARD", "Thinking…", false, true)
    scrollToLatest()
end

local function resolveThinking(guardName, message)
    if thinkingBubble and thinkingBubble.Parent then
        thinkingSpeaker.Text = string.upper(guardName or "GUARD")
        thinkingBubble.Text = message
        thinkingBubble.TextColor3 = colors.White
    else
        addConversationBubble(string.upper(guardName or "GUARD"), message, false, false)
    end
    thinkingWrapper = nil
    thinkingSpeaker = nil
    thinkingBubble = nil
    scrollToLatest()
end

local function cancelThinking()
    if thinkingWrapper and thinkingWrapper.Parent then
        thinkingWrapper:Destroy()
    end
    thinkingWrapper = nil
    thinkingSpeaker = nil
    thinkingBubble = nil
end

local hint = ordered(label(scroll, "", 50, 14, colors.Gold, Enum.Font.GothamMedium))
ordered(label(scroll, "SUGGESTIONS  •  OR TYPE YOUR OWN ARGUMENT", 24, 13, colors.Muted, Enum.Font.GothamBold))

local suggestionButtons = {}
for index = 1, 3 do
    local move = ordered(button(scroll, "Suggestion loading…", 44))
    suggestionButtons[index] = move
    move.Activated:Connect(function()
        local id = suggestionIds[index]
        local text = suggestionTexts[index]
        if id and text then
            submit("Choice", id, text)
        end
    end)
end

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

submit = function(kind, value, displayText)
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
    pendingTurn = current.Turns + 1
    lastSent = os.clock()
    guidance.Text = "The Guard is considering your move..."

    local shown = displayText or value
    local _, _, playerBubble = addConversationBubble("YOU", shown, true, false)
    pendingPlayerBubble = playerBubble
    startThinking()
    scrollToLatest()

    submitRemote:FireServer({
        MatchId = current.MatchId,
        Turn = current.Turns + 1,
        Kind = kind,
        Value = value,
    })
end

input.Parent = scroll
ordered(input)

local send = ordered(button(scroll, "SEND ARGUMENT", 48, Color3.fromRGB(22, 102, 112)))
send.TextSize = 16
send.Activated:Connect(function()
    submit("Text", input.Text, input.Text)
end)

input.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submit("Text", input.Text, input.Text)
    end
end)

local hide = ordered(button(scroll, "WATCH FROM THE ARENA", 42))
hide.Activated:Connect(function()
    panel.Visible = false
end)

ordered(label(
    scroll,
    "AI-POWERED OPPONENT  •  You are interacting with generative AI. It can make mistakes. The server—not the model—controls Trust, Suspicion, wins, losses and ELO.",
    70,
    12,
    colors.Muted
))

local resultOverlay = Instance.new("Frame")
resultOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
resultOverlay.Position = UDim2.fromScale(0.5, 0.5)
resultOverlay.Size = UDim2.new(0.9, 0, 0, 330)
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
resultTitle.ZIndex = 21
resultTitle.Position = UDim2.fromOffset(20, 28)
resultTitle.Size = UDim2.new(1, -40, 0, 54)

local resultReason = label(resultOverlay, "", 72, 16, colors.White, Enum.Font.GothamMedium)
resultReason.TextXAlignment = Enum.TextXAlignment.Center
resultReason.ZIndex = 21
resultReason.Position = UDim2.fromOffset(28, 91)
resultReason.Size = UDim2.new(1, -56, 0, 72)

local resultRating = label(resultOverlay, "", 38, 20, colors.Gold, Enum.Font.GothamBold)
resultRating.TextXAlignment = Enum.TextXAlignment.Center
resultRating.ZIndex = 21
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
        pending = false
        cancelThinking()
        pendingTurn = nil
        pendingPlayerBubble = nil
        guidance.Text = packet.Message
        return
    end

    if packet.Kind ~= "Match" then
        return
    end

    if not current or current.MatchId ~= packet.MatchId then
        clearConversation()
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
        and ("🛡 " .. string.upper(packet.GuardName or "THE GUARD"))
        or string.upper(packet.Status == "Won" and "GATE OPEN" or "GATE CLOSED")

    subtitle.Text = string.format(
        "AI-POWERED  •  %s  •  %d ELO  •  %d MOVES",
        packet.GuardTitle or "Guard",
        packet.GuardRating or 1000,
        Config.MaxTurns
    )

    rematchButton.Text = "REMATCH " .. string.upper(packet.GuardName or "THE GUARD")

    if packet.Turns == 0 and lastRenderedTurn < 0 then
        addConversationBubble(string.upper(packet.GuardName or "GUARD"), packet.Message, false, false)
        lastRenderedTurn = 0
        scrollToLatest()
    elseif pendingTurn and packet.Turns == pendingTurn then
        if pendingPlayerBubble and packet.PlayerMessage then
            pendingPlayerBubble.Text = packet.PlayerMessage
        end
        resolveThinking(packet.GuardName, packet.Message)
        lastRenderedTurn = packet.Turns
        pendingTurn = nil
        pendingPlayerBubble = nil
    elseif packet.Turns > lastRenderedTurn then
        if packet.PlayerMessage then
            addConversationBubble("YOU", packet.PlayerMessage, true, false)
        end
        addConversationBubble(string.upper(packet.GuardName or "GUARD"), packet.Message, false, false)
        lastRenderedTurn = packet.Turns
        scrollToLatest()
    end

    for index = 1, 3 do
        local suggestion = packet.Suggestions and packet.Suggestions[index]
        suggestionIds[index] = suggestion and suggestion.Id or nil
        suggestionTexts[index] = suggestion and suggestion.Text or nil
        suggestionButtons[index].Text = suggestion and suggestion.Text or "No suggestion"
        suggestionButtons[index].Visible = suggestion ~= nil and packet.Status == "Playing"
    end

    hint.Text = packet.Status == "Playing" and ("TACTICAL HINT  •  " .. packet.Hint) or "Result locked. Rematch or return to the plaza."
    guidance.Text = packet.Status == "Playing"
        and "Read the Guard's reply, choose a suggestion, or write your own argument."
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
    scrollToLatest()
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