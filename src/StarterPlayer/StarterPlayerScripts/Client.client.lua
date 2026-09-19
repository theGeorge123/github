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
local pendingTurn
local pendingPlayerWrapper
local pendingPlayerBubble
local thinkingWrapper
local thinkingSpeaker
local thinkingBubble
local lastSent = 0
local lastRenderedTurn = -1
local lastProgress = 0
local lastSuspicion = 0
local suggestionIds = {}
local suggestionTexts = {}

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

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = object
end

local function stroke(object, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or colors.Cyan
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.3
    s.Parent = object
end

local function label(parent, text, size, color, font)
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Text = text
    object.TextColor3 = color or colors.White
    object.TextSize = size or 15
    object.Font = font or Enum.Font.Gotham
    object.TextWrapped = true
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.Parent = parent
    return object
end

local function button(parent, text, accent)
    local object = Instance.new("TextButton")
    object.BackgroundColor3 = accent or colors.Panel2
    object.AutoButtonColor = true
    object.TextColor3 = colors.White
    object.Text = text
    object.TextSize = 13
    object.TextWrapped = true
    object.Font = Enum.Font.GothamMedium
    object.Parent = parent
    corner(object, 10)
    stroke(object, colors.Cyan, 1, 0.68)
    return object
end

local function ping(pitch)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    sound.Volume = 0.2
    sound.PlaybackSpeed = pitch or 1
    sound.Parent = SoundService
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    sound:Play()
end

local screen = Instance.new("ScreenGui")
screen.Name = "BeatTheBotHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = player:WaitForChild("PlayerGui")

local header = Instance.new("Frame")
header.Size = UDim2.new(0.98, 0, 0, 70)
header.Position = UDim2.new(0.01, 0, 0, 6)
header.BackgroundColor3 = colors.Panel
header.BackgroundTransparency = 0.05
header.Parent = screen
corner(header, 14)
stroke(header, colors.Cyan, 1.5, 0.45)

local stats = label(header, "BEAT THE BOT  |  Loading profile...", 16, colors.Cyan, Enum.Font.GothamBold)
stats.Position = UDim2.fromOffset(14, 2)
stats.Size = UDim2.new(1, -232, 0, 34)

local guidance = label(header, "Explore the AI Citadel. Ranked districts unlock through ELO; Daily Trial is in the plaza.", 12, colors.Muted)
guidance.Position = UDim2.fromOffset(14, 32)
guidance.Size = UDim2.new(1, -28, 0, 30)

local profileButton = button(header, "PROFILE", colors.Panel2)
profileButton.Size = UDim2.fromOffset(96, 32)
profileButton.Position = UDim2.new(1, -214, 0, 5)

local toggle = button(header, "MATCH", Color3.fromRGB(31, 74, 92))
toggle.Size = UDim2.fromOffset(96, 32)
toggle.Position = UDim2.new(1, -110, 0, 5)

local profileCard = Instance.new("Frame")
profileCard.AnchorPoint = Vector2.new(0.5, 0)
profileCard.Position = UDim2.new(0.5, 0, 0, 82)
profileCard.Size = UDim2.new(0.92, 0, 0, 250)
profileCard.BackgroundColor3 = colors.Background
profileCard.BackgroundTransparency = 0.02
profileCard.Visible = false
profileCard.ZIndex = 15
profileCard.Parent = screen
corner(profileCard, 16)
stroke(profileCard, colors.Gold, 1.5, 0.3)

local profileConstraint = Instance.new("UISizeConstraint")
profileConstraint.MaxSize = Vector2.new(560, 250)
profileConstraint.Parent = profileCard

local profileTitle = label(profileCard, "CITADEL PROFILE", 21, colors.Gold, Enum.Font.GothamBold)
profileTitle.Position = UDim2.fromOffset(18, 12)
profileTitle.Size = UDim2.new(1, -36, 0, 30)
profileTitle.ZIndex = 16

local profileDetails = label(profileCard, "Loading profile...", 15, colors.White, Enum.Font.GothamMedium)
profileDetails.Position = UDim2.fromOffset(18, 50)
profileDetails.Size = UDim2.new(1, -36, 0, 92)
profileDetails.TextYAlignment = Enum.TextYAlignment.Top
profileDetails.ZIndex = 16

local masteryDetails = label(profileCard, "Start a match to inspect opponent mastery.", 13, colors.Muted)
masteryDetails.Position = UDim2.fromOffset(18, 144)
masteryDetails.Size = UDim2.new(1, -36, 0, 88)
masteryDetails.TextYAlignment = Enum.TextYAlignment.Top
masteryDetails.ZIndex = 16

local function refreshProfileCard()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end
    local elo = leaderstats:FindFirstChild("Elo")
    local wins = leaderstats:FindFirstChild("Wins")
    local losses = leaderstats:FindFirstChild("Losses")
    local insight = leaderstats:FindFirstChild("Insight")
    profileDetails.Text = string.format(
        "ELO %d  •  %s  •  Server rank %s\nWins %d  •  Losses %d  •  Insight %d\nDaily streak %d  •  Equipped title: %s\nVIP %s  •  Founder %s",
        elo and elo.Value or 0,
        player:GetAttribute("RankTitle") or "Outsider",
        player:GetAttribute("ServerRank") and ("#" .. tostring(player:GetAttribute("ServerRank"))) or "—",
        wins and wins.Value or 0,
        losses and losses.Value or 0,
        insight and insight.Value or 0,
        player:GetAttribute("DailyStreak") or 0,
        player:GetAttribute("EquippedTitle") ~= "" and player:GetAttribute("EquippedTitle") or "None",
        player:GetAttribute("VIP") and "Yes" or "No",
        player:GetAttribute("Founder") and "Yes" or "No"
    )
    if current and current.Mastery then
        masteryDetails.Text = string.format(
            "%s mastery\nLevel %d  •  XP %d  •  Wins %d/%d attempts\nBest successful run: %s messages",
            current.OpponentName or current.GuardName or "Opponent",
            current.Mastery.Level or 0,
            current.Mastery.XP or 0,
            current.Mastery.Wins or 0,
            current.Mastery.Attempts or 0,
            current.Mastery.BestSuccessfulMessageCount and tostring(current.Mastery.BestSuccessfulMessageCount) or "—"
        )
    end
end

profileButton.Activated:Connect(function()
    profileCard.Visible = not profileCard.Visible
    if profileCard.Visible then
        refreshProfileCard()
    end
end)

local tutorial = Instance.new("Frame")
tutorial.AnchorPoint = Vector2.new(0.5, 0.5)
tutorial.Position = UDim2.fromScale(0.5, 0.5)
tutorial.Size = UDim2.new(0.88, 0, 0, 330)
tutorial.BackgroundColor3 = colors.Background
tutorial.ZIndex = 30
tutorial.Parent = screen
corner(tutorial, 18)
stroke(tutorial, colors.Cyan, 2, 0.2)

local tutorialConstraint = Instance.new("UISizeConstraint")
tutorialConstraint.MaxSize = Vector2.new(480, 360)
tutorialConstraint.Parent = tutorial

local tutorialTitle = label(tutorial, "OUTSMART THE CITADEL", 24, colors.Gold, Enum.Font.GothamBlack)
tutorialTitle.TextXAlignment = Enum.TextXAlignment.Center
tutorialTitle.Position = UDim2.fromOffset(20, 20)
tutorialTitle.Size = UDim2.new(1, -40, 0, 38)
tutorialTitle.ZIndex = 31

local tutorialBody = label(tutorial, [[1  Walk to a glowing challenge console.

2  Persuade the opponent in eight messages.

3  Raise TRUST and keep SUSPICION low.

Win ranked matches to unlock deeper districts. The Daily Trial is in the plaza.]], 16, colors.White, Enum.Font.GothamMedium)
tutorialBody.Position = UDim2.fromOffset(26, 66)
tutorialBody.Size = UDim2.new(1, -52, 0, 190)
tutorialBody.TextYAlignment = Enum.TextYAlignment.Top
tutorialBody.ZIndex = 31

local tutorialStart = button(tutorial, "START EXPLORING", Color3.fromRGB(22, 112, 95))
tutorialStart.AnchorPoint = Vector2.new(0.5, 1)
tutorialStart.Position = UDim2.new(0.5, 0, 1, -22)
tutorialStart.Size = UDim2.new(0.82, 0, 0, 48)
tutorialStart.TextSize = 16
tutorialStart.ZIndex = 31

tutorialStart.Activated:Connect(function()
    tutorial.Visible = false
    guidance.Text = "Find a glowing console. Build Trust, avoid Suspicion, and persuade in eight messages."
end)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 82)
panel.Size = UDim2.new(0.98, 0, 1, -92)
panel.BackgroundColor3 = colors.Background
panel.BackgroundTransparency = 0.025
panel.Visible = false
panel.Parent = screen
corner(panel, 16)
stroke(panel, colors.Cyan, 1.5, 0.35)

local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(760, 860)
constraint.Parent = panel

local opponentCard = Instance.new("Frame")
opponentCard.Position = UDim2.fromOffset(14, 10)
opponentCard.Size = UDim2.new(1, -28, 0, 56)
opponentCard.BackgroundColor3 = colors.Panel
opponentCard.Parent = panel
corner(opponentCard, 12)
stroke(opponentCard, colors.Gold, 1.5, 0.35)

local title = label(opponentCard, "THE CASTLE GUARD", 20, colors.Gold, Enum.Font.GothamBold)
title.Position = UDim2.fromOffset(14, 2)
title.Size = UDim2.new(1, -28, 0, 27)

local subtitle = label(opponentCard, "AI-POWERED  •  RANKED  •  8 MESSAGES", 11, colors.Muted, Enum.Font.GothamMedium)
subtitle.Position = UDim2.fromOffset(14, 28)
subtitle.Size = UDim2.new(1, -28, 0, 22)

local function meter(parent, name, fillColor, xScale)
    local holder = Instance.new("Frame")
    holder.Position = UDim2.new(xScale, xScale == 0 and 14 or 4, 0, 72)
    holder.Size = UDim2.new(0.5, -20, 0, 34)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local heading = label(holder, name, 11, colors.Muted, Enum.Font.GothamBold)
    heading.Size = UDim2.new(0.68, 0, 0, 17)

    local value = label(holder, "0%", 11, fillColor, Enum.Font.GothamBold)
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Position = UDim2.new(0.68, 0, 0, 0)
    value.Size = UDim2.new(0.32, 0, 0, 17)

    local track = Instance.new("Frame")
    track.Position = UDim2.fromOffset(0, 20)
    track.Size = UDim2.new(1, 0, 0, 8)
    track.BackgroundColor3 = colors.Panel2
    track.Parent = holder
    corner(track, 5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = fillColor
    fill.Parent = track
    corner(fill, 5)

    return fill, value
end

local trustFill, trustValue = meter(panel, "TRUST", colors.Green, 0)
local suspicionFill, suspicionValue = meter(panel, "SUSPICION", colors.Red, 0.5)

local statusLine = label(panel, "MOVE 0 / 8  •  180s", 12, colors.Cyan, Enum.Font.GothamBold)
statusLine.Position = UDim2.fromOffset(14, 108)
statusLine.Size = UDim2.new(1, -28, 0, 20)

local conversationScroll = Instance.new("ScrollingFrame")
conversationScroll.Position = UDim2.fromOffset(14, 130)
conversationScroll.Size = UDim2.new(1, -28, 1, -302)
conversationScroll.BackgroundColor3 = Color3.fromRGB(8, 12, 23)
conversationScroll.BackgroundTransparency = 0.12
conversationScroll.BorderSizePixel = 0
conversationScroll.ScrollBarThickness = 4
conversationScroll.ScrollBarImageColor3 = colors.Cyan
conversationScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
conversationScroll.CanvasSize = UDim2.new()
conversationScroll.Parent = panel
corner(conversationScroll, 12)
stroke(conversationScroll, colors.Cyan, 1, 0.82)

local conversationPadding = Instance.new("UIPadding")
conversationPadding.PaddingLeft = UDim.new(0, 10)
conversationPadding.PaddingRight = UDim.new(0, 10)
conversationPadding.PaddingTop = UDim.new(0, 10)
conversationPadding.PaddingBottom = UDim.new(0, 10)
conversationPadding.Parent = conversationScroll

local conversation = Instance.new("Frame")
conversation.Size = UDim2.new(1, 0, 0, 0)
conversation.AutomaticSize = Enum.AutomaticSize.Y
conversation.BackgroundTransparency = 1
conversation.Parent = conversationScroll

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

    local speaker = label(wrapper, speakerText, 10, isPlayer and colors.Cyan or colors.Gold, Enum.Font.GothamBold)
    speaker.AutomaticSize = Enum.AutomaticSize.Y
    speaker.Size = UDim2.new(0.94, 0, 0, 0)
    speaker.TextXAlignment = isPlayer and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left

    local bubble = label(wrapper, message, 15, muted and colors.Muted or colors.White, Enum.Font.GothamMedium)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Size = UDim2.new(0.94, 0, 0, 0)
    bubble.BackgroundTransparency = 0
    bubble.BackgroundColor3 = isPlayer and Color3.fromRGB(26, 70, 86) or colors.Panel
    bubble.TextXAlignment = Enum.TextXAlignment.Left
    bubble.TextYAlignment = Enum.TextYAlignment.Top

    local bubblePadding = Instance.new("UIPadding")
    bubblePadding.PaddingLeft = UDim.new(0, 12)
    bubblePadding.PaddingRight = UDim.new(0, 12)
    bubblePadding.PaddingTop = UDim.new(0, 9)
    bubblePadding.PaddingBottom = UDim.new(0, 9)
    bubblePadding.Parent = bubble

    corner(bubble, 12)
    stroke(bubble, isPlayer and colors.Cyan or colors.Gold, 1, 0.7)

    return wrapper, speaker, bubble
end

local function scrollToLatest()
    task.defer(function()
        task.wait()
        local maxY = math.max(0, conversationScroll.AbsoluteCanvasSize.Y - conversationScroll.AbsoluteSize.Y)
        conversationScroll.CanvasPosition = Vector2.new(0, maxY)
    end)
end

local function clearConversation()
    for _, child in ipairs(conversation:GetChildren()) do
        if child ~= conversationLayout then
            child:Destroy()
        end
    end
    pendingTurn = nil
    pendingPlayerWrapper = nil
    pendingPlayerBubble = nil
    thinkingWrapper = nil
    thinkingSpeaker = nil
    thinkingBubble = nil
    lastRenderedTurn = -1
end

local function cancelPendingExchange()
    if thinkingWrapper and thinkingWrapper.Parent then
        thinkingWrapper:Destroy()
    end
    if pendingPlayerWrapper and pendingPlayerWrapper.Parent then
        pendingPlayerWrapper:Destroy()
    end
    thinkingWrapper = nil
    thinkingSpeaker = nil
    thinkingBubble = nil
    pendingPlayerWrapper = nil
    pendingPlayerBubble = nil
    pendingTurn = nil
end

local function startThinking()
    if thinkingWrapper and thinkingWrapper.Parent then
        thinkingWrapper:Destroy()
    end
    thinkingWrapper, thinkingSpeaker, thinkingBubble = addConversationBubble("OPPONENT", "Thinking…", false, true)
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

local composer = Instance.new("Frame")
composer.AnchorPoint = Vector2.new(0, 1)
composer.Position = UDim2.new(0, 14, 1, -12)
composer.Size = UDim2.new(1, -28, 0, 160)
composer.BackgroundTransparency = 1
composer.Parent = panel

local hint = label(composer, "Convince the Guard with words. There are no physical items to show.", 12, colors.Gold, Enum.Font.GothamMedium)
hint.Size = UDim2.new(1, 0, 0, 24)

local suggestionLabel = label(composer, "SUGGESTIONS  •  OPTIONAL", 10, colors.Muted, Enum.Font.GothamBold)
suggestionLabel.Position = UDim2.fromOffset(0, 24)
suggestionLabel.Size = UDim2.new(1, 0, 0, 14)

local suggestionRow = Instance.new("Frame")
suggestionRow.Position = UDim2.fromOffset(0, 40)
suggestionRow.Size = UDim2.new(1, 0, 0, 42)
suggestionRow.BackgroundTransparency = 1
suggestionRow.Parent = composer

local suggestionLayout = Instance.new("UIListLayout")
suggestionLayout.FillDirection = Enum.FillDirection.Horizontal
suggestionLayout.Padding = UDim.new(0, 7)
suggestionLayout.SortOrder = Enum.SortOrder.LayoutOrder
suggestionLayout.Parent = suggestionRow

local suggestionButtons = {}
for index = 1, 2 do
    local move = button(suggestionRow, "Suggestion loading…")
    move.Size = UDim2.new(0.5, -4, 1, 0)
    move.LayoutOrder = index
    suggestionButtons[index] = move
end

local input = Instance.new("TextBox")
input.Position = UDim2.fromOffset(0, 90)
input.Size = UDim2.new(1, -118, 0, 46)
input.BackgroundColor3 = colors.Panel2
input.TextColor3 = colors.White
input.PlaceholderColor3 = colors.Muted
input.PlaceholderText = "Make your argument..."
input.Text = ""
input.ClearTextOnFocus = false
input.MultiLine = false
input.TextSize = 15
input.Font = Enum.Font.Gotham
input.TextXAlignment = Enum.TextXAlignment.Left
input.Parent = composer
corner(input, 10)
stroke(input, colors.Cyan, 1, 0.65)

local inputPadding = Instance.new("UIPadding")
inputPadding.PaddingLeft = UDim.new(0, 12)
inputPadding.PaddingRight = UDim.new(0, 12)
inputPadding.Parent = input

local send = button(composer, "SEND", Color3.fromRGB(22, 102, 112))
send.Position = UDim2.new(1, -108, 0, 90)
send.Size = UDim2.fromOffset(108, 46)
send.TextSize = 15

local function animateMeter(fill, valueLabel, value)
    valueLabel.Text = string.format("%d%%", value)
    TweenService:Create(
        fill,
        TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1) }
    ):Play()
end

local function flashGuidance(text, color)
    guidance.Text = text
    guidance.TextColor3 = color
    task.delay(0.7, function()
        if guidance.Parent then
            guidance.TextColor3 = colors.Muted
        end
    end)
end

local function submit(kind, value, displayText)
    if not current or current.Status ~= "Playing" or pending then
        return
    end
    if os.clock() - lastSent < Config.RequestCooldown then
        return
    end
    if kind == "Text" and (#value == 0 or #value > Config.MaxMessageBytes) then
        guidance.Text = "Use 1–240 bytes."
        return
    end

    pending = true
    pendingTurn = current.Turns + 1
    lastSent = os.clock()
    guidance.Text = "The opponent is thinking about what you said..."

    local shown = displayText or value
    pendingPlayerWrapper, _, pendingPlayerBubble = addConversationBubble("YOU", shown, true, false)
    startThinking()
    scrollToLatest()

    submitRemote:FireServer({
        MatchId = current.MatchId,
        Turn = current.Turns + 1,
        Kind = kind,
        Value = value,
    })
end

for index, move in ipairs(suggestionButtons) do
    move.Activated:Connect(function()
        local id = suggestionIds[index]
        local text = suggestionTexts[index]
        if id and text then
            submit("Choice", id, text)
        end
    end)
end

send.Activated:Connect(function()
    submit("Text", input.Text, input.Text)
end)

input.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submit("Text", input.Text, input.Text)
    end
end)

toggle.Activated:Connect(function()
    profileCard.Visible = false
    if current then
        panel.Visible = not panel.Visible
    else
        guidance.Text = "Walk to a glowing Citadel challenge console or enter the Daily Trial."
    end
end)

local resultOverlay = Instance.new("Frame")
resultOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
resultOverlay.Position = UDim2.fromScale(0.5, 0.5)
resultOverlay.Size = UDim2.new(0.88, 0, 0, 315)
resultOverlay.BackgroundColor3 = colors.Background
resultOverlay.Visible = false
resultOverlay.ZIndex = 20
resultOverlay.Parent = screen
corner(resultOverlay, 18)
stroke(resultOverlay, colors.Gold, 2, 0.15)

local resultConstraint = Instance.new("UISizeConstraint")
resultConstraint.MaxSize = Vector2.new(430, 340)
resultConstraint.Parent = resultOverlay

local resultScale = Instance.new("UIScale")
resultScale.Scale = 0.9
resultScale.Parent = resultOverlay

local resultTitle = label(resultOverlay, "VICTORY", 32, colors.Green, Enum.Font.GothamBlack)
resultTitle.TextXAlignment = Enum.TextXAlignment.Center
resultTitle.ZIndex = 21
resultTitle.Position = UDim2.fromOffset(20, 24)
resultTitle.Size = UDim2.new(1, -40, 0, 48)

local resultReason = label(resultOverlay, "", 15, colors.White, Enum.Font.GothamMedium)
resultReason.TextXAlignment = Enum.TextXAlignment.Center
resultReason.ZIndex = 21
resultReason.Position = UDim2.fromOffset(28, 78)
resultReason.Size = UDim2.new(1, -56, 0, 78)

local resultRating = label(resultOverlay, "", 20, colors.Gold, Enum.Font.GothamBold)
resultRating.TextXAlignment = Enum.TextXAlignment.Center
resultRating.ZIndex = 21
resultRating.Position = UDim2.fromOffset(20, 158)
resultRating.Size = UDim2.new(1, -40, 0, 34)

local rematchButton = button(resultOverlay, "REMATCH", Color3.fromRGB(22, 112, 95))
rematchButton.Position = UDim2.new(0.08, 0, 1, -105)
rematchButton.Size = UDim2.new(0.84, 0, 0, 44)
rematchButton.ZIndex = 21

local plazaButton = button(resultOverlay, "BACK TO PLAZA", colors.Panel2)
plazaButton.Position = UDim2.new(0.08, 0, 1, -55)
plazaButton.Size = UDim2.new(0.84, 0, 0, 38)
plazaButton.ZIndex = 21

local function showResult(packet)
    local won = packet.Status == "Won"
    resultTitle.Text = won and "PERSUASION SUCCESS" or "OPPONENT HOLDS"
    resultTitle.TextColor3 = won and colors.Green or colors.Red
    resultReason.Text = packet.Message
    if packet.Mode == "Ranked" then
        resultRating.Text = string.format("RANKED • ELO %+d", packet.Delta or 0)
    elseif packet.Mode == "Daily" then
        resultRating.Text = "OFFICIAL DAILY SCORE LOCKED"
    else
        resultRating.Text = "PRACTICE • ELO UNCHANGED"
    end
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
    guidance.Text = "Walk to a glowing console when you want another match."
end)

stateRemote.OnClientEvent:Connect(function(packet)
    if packet.Kind == "Notice" then
        pending = false
        cancelPendingExchange()
        guidance.Text = packet.Message
        return
    end

    if packet.Kind ~= "Match" then
        return
    end

    tutorial.Visible = false
    pending = false

    if not current or current.MatchId ~= packet.MatchId then
        clearConversation()
        lastProgress = 0
        lastSuspicion = 0
        resultOverlay.Visible = false
        panel.Visible = true
        conversationScroll.CanvasPosition = Vector2.zero
    end

    current = packet
    refreshProfileCard()

    animateMeter(trustFill, trustValue, packet.Progress)
    animateMeter(suspicionFill, suspicionValue, packet.Suspicion)

    if packet.Progress > lastProgress then
        flashGuidance(string.format("TRUST +%d • Good approach", packet.Progress - lastProgress), colors.Green)
        ping(1.12)
    elseif packet.Suspicion > lastSuspicion then
        flashGuidance(string.format("SUSPICION +%d • Change approach", packet.Suspicion - lastSuspicion), colors.Red)
        ping(0.86)
    end

    lastProgress = packet.Progress
    lastSuspicion = packet.Suspicion

    title.Text = packet.Status == "Playing"
        and string.upper(packet.OpponentName or packet.GuardName or "AI OPPONENT")
        or (packet.Status == "Won" and "PERSUASION SUCCESS" or "CHALLENGE ENDED")

    subtitle.Text = string.format(
        "%s  •  %s  •  %d ELO  •  MASTERY %d  •  %d MESSAGES",
        string.upper(packet.Mode or "Ranked"),
        packet.OpponentTitle or packet.GuardTitle or "Opponent",
        packet.OpponentRating or packet.GuardRating or 1000,
        packet.Mastery and packet.Mastery.Level or 0,
        Config.MaxTurns
    )

    rematchButton.Text = packet.Mode == "Daily" and "PRACTICE TODAY'S TRIAL"
        or ("REMATCH " .. string.upper(packet.OpponentName or packet.GuardName or "OPPONENT"))

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
        pendingPlayerWrapper = nil
        pendingPlayerBubble = nil
    elseif packet.Turns > lastRenderedTurn then
        if packet.PlayerMessage then
            addConversationBubble("YOU", packet.PlayerMessage, true, false)
        end
        addConversationBubble(string.upper(packet.GuardName or "GUARD"), packet.Message, false, false)
        lastRenderedTurn = packet.Turns
        scrollToLatest()
    end

    for index = 1, 2 do
        local suggestion = packet.Suggestions and packet.Suggestions[index]
        suggestionIds[index] = suggestion and suggestion.Id or nil
        suggestionTexts[index] = suggestion and suggestion.Text or nil
        suggestionButtons[index].Text = suggestion and suggestion.Text or "—"
        suggestionButtons[index].Active = suggestion ~= nil and packet.Status == "Playing"
        suggestionButtons[index].AutoButtonColor = suggestion ~= nil and packet.Status == "Playing"
    end

    hint.Text = packet.Status == "Playing"
        and ("HINT  •  " .. packet.Hint)
        or "Match complete."

    guidance.Text = packet.Status == "Playing"
        and ((packet.Mode == "Daily" and "Official Daily Trial • one scored attempt today") or (packet.Mode == "DailyPractice" and "Daily practice • official score already locked") or "Ranked • respond to what the opponent actually said.")
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
    local insight = leaderstats:WaitForChild("Insight")

    local function refresh()
        stats.Text = string.format(
            "ELO %d  •  %s  •  INSIGHT %d  •  STREAK %d%s",
            elo.Value,
            player:GetAttribute("RankTitle") or "Outsider",
            insight.Value,
            player:GetAttribute("DailyStreak") or 0,
            player:GetAttribute("SessionOnly") and "  •  TEST" or ""
        )
        refreshProfileCard()
    end

    elo.Changed:Connect(refresh)
    wins.Changed:Connect(refresh)
    losses.Changed:Connect(refresh)
    insight.Changed:Connect(refresh)
    for _, attribute in ipairs({ "RankTitle", "ServerRank", "DailyStreak", "EquippedTitle", "VIP", "Founder", "SessionOnly" }) do
        player:GetAttributeChangedSignal(attribute):Connect(refresh)
    end
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
