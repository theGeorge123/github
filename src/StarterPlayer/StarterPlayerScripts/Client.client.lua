-- Client: multiplayer debate UI. Presentation only.
-- v0.5.1 guardian-temple port: hologram choice cards, arena scoreboard/topic
-- text, countdown timer, and the boss-practice layout. Judge reactions, podium
-- cues, sounds, and the round-end celebration are server-owned (DebateWorldService);
-- this client never drives those parts itself. Panel verdicts, disclosures, and
-- onboarding follow the repo's scripted-practice wording verbatim.
-- All debate state, scoring, turns, and filtering are server-authoritative via
-- MultiplayerDebateState / MultiplayerDebateSubmit. This script never invents game logic;
-- it renders existing server state and mirrors the server byte limit for feedback.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
-- StarterPlayerScripts children replicate in arbitrary order; wait (with a timeout)
-- instead of indexing directly so the UI never dies on a replication race.
local bossModule = script.Parent:WaitForChild("BossDebateController", 10)
if not bossModule then
    warn("BeatTheBot client: BossDebateController never replicated; debate UI disabled")
    return
end
local BossController = require(bossModule)
local remotes = RS:WaitForChild("BeatTheBotRemotes", 10)
if not remotes then
    warn("BeatTheBot client: remotes never replicated; debate UI disabled")
    return
end
local state = remotes:WaitForChild("MultiplayerDebateState", 10)
local submit = remotes:WaitForChild("MultiplayerDebateSubmit", 10)
if not state or not submit then
    warn("BeatTheBot client: debate remotes missing; debate UI disabled")
    return
end

local C = {
    bg = Color3.fromRGB(12, 18, 34),
    panel = Color3.fromRGB(24, 35, 56),
    blue = Color3.fromRGB(64, 170, 255),
    gold = Color3.fromRGB(255, 200, 60),
    white = Color3.fromRGB(240, 246, 255),
    muted = Color3.fromRGB(170, 185, 205),
    green = Color3.fromRGB(96, 230, 140),
    magenta = Color3.fromRGB(255, 90, 160),
}

local function corner(x, n)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, n or 10)
    c.Parent = x
end

local function label(pa, t, z, col, b)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = t
    l.TextColor3 = col or C.white
    l.TextSize = z or 16
    l.Font = b and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = pa
    return l
end

local function button(pa, t, col)
    local b = Instance.new("TextButton")
    b.Text = t
    b.TextColor3 = C.white
    b.TextSize = 16
    b.Font = Enum.Font.GothamBold
    b.BackgroundColor3 = col or C.panel
    b.Parent = pa
    corner(b, 9)
    return b
end

local g = Instance.new("ScreenGui")
g.Name = "MultiplayerDebateUI"
g.ResetOnSpawn = false
-- Render above any remaining core UI so menu clicks are never stolen.
g.DisplayOrder = 50
g.Parent = player:WaitForChild("PlayerGui")

-- The core player list (top-right) and backpack (top-center) collide with the
-- debate menu and badge. This game has no tools and tracks scores in its own UI,
-- so hide both; chat stays enabled. Presentation only, client-side.
local StarterGui = game:GetService("StarterGui")
local function hideRedundantCoreGui()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
end
hideRedundantCoreGui()
task.delay(1, hideRedundantCoreGui) -- retry once in case core was not ready

local MAX_ARGUMENT_BYTES = 500 -- mirrors authoritative server limit

-- Top disclosure badge (top-center: clear of chat on the left and menu on the right).
-- Wording is the repo's scripted-practice disclosure, kept verbatim.
local badge = label(g, "SCRIPTED PRACTICE \u{2014} NO WINNER OR SCORE \u{2022} NOT A REAL OPPONENT", 12, C.gold, true)
badge.AnchorPoint = Vector2.new(0.5, 0)
badge.Position = UDim2.new(0.5, 0, 0, 8)
badge.Size = UDim2.fromOffset(480, 28)

-- Compact right-side menu (top-right: the core player list is disabled, so this
-- corner is free; staying high also keeps it clear of the mobile jump button
-- at bottom-right).
local menu = Instance.new("Frame")
menu.AnchorPoint = Vector2.new(1, 0)
menu.Position = UDim2.new(1, -14, 0, 36)
menu.Size = UDim2.fromOffset(156, 210)
menu.BackgroundColor3 = C.bg
menu.Parent = g
corner(menu, 12)
local ml = Instance.new("UIListLayout")
ml.Padding = UDim.new(0, 6)
ml.HorizontalAlignment = Enum.HorizontalAlignment.Center
ml.VerticalAlignment = Enum.VerticalAlignment.Center
ml.Parent = menu
local play = button(menu, "FIND DEBATE", C.blue)
play.Size = UDim2.new(1, -16, 0, 44)
local chairs = button(menu, "CHAIRS")
chairs.Size = play.Size
local titles = button(menu, "TITLES")
titles.Size = play.Size
local profileButton = button(menu, "PROFILE")
profileButton.Size = play.Size

-- Boss (SCRIPTED PRACTICE) card lives on the left; same remotes, no second loop.
-- hooks lets the boss controller ask the client to yield the screen when practice opens.
local bossHooks = {}
local boss = BossController.Init(remotes, g, button, label, C, bossHooks)

-- First-session onboarding (repo wording verbatim; dismissable, auto-hides).
local onboarding = Instance.new("Frame")
onboarding.Name = "FirstSessionOnboarding"
onboarding.AnchorPoint = Vector2.new(0.5, 0.5)
onboarding.Position = UDim2.fromScale(0.5, 0.5)
onboarding.Size = UDim2.new(0.84, 0, 0.72, 0)
onboarding.BackgroundColor3 = C.bg
onboarding.ZIndex = 20
onboarding.Parent = g
corner(onboarding, 16)
local oc = Instance.new("UISizeConstraint")
oc.MaxSize = Vector2.new(680, 520)
oc.MinSize = Vector2.new(300, 360)
oc.Parent = onboarding
local oh = label(onboarding, "WELCOME TO THE SCRIPTED CHECKLIST PANEL", 24, C.gold, true)
oh.Position = UDim2.fromOffset(24, 22)
oh.Size = UDim2.new(1, -48, 0, 66)
oh.TextXAlignment = Enum.TextXAlignment.Center
oh.ZIndex = 21
local ob = label(onboarding, "1  YOU ARE ASSIGNED A SIDE\nArgue that position, even when it is not your personal view.\n\n2  THREE TURNS \u{2022} 45 SECONDS EACH\nOpening, rebuttal, then closing.\n\n3  THREE VISIBLE CHECKS\nRIVET: reason words like because\nPIP: an example or scenario\nMOSS: a rebuttal marked by however or but\n\nSCRIPTED PRACTICE \u{2022} NOT A REAL OPPONENT\nThe panel detects writing markers. It does not judge truth or argument quality.", 16, C.white)
ob.Position = UDim2.fromOffset(30, 96)
ob.Size = UDim2.new(1, -60, 1, -170)
ob.TextYAlignment = Enum.TextYAlignment.Top
ob.TextXAlignment = Enum.TextXAlignment.Center
ob.ZIndex = 21
local dismiss = button(onboarding, "ENTER ARENA", C.blue)
dismiss.AnchorPoint = Vector2.new(0.5, 1)
dismiss.Position = UDim2.new(0.5, 0, 1, -22)
dismiss.Size = UDim2.fromOffset(190, 48)
dismiss.ZIndex = 21
dismiss.Activated:Connect(function()
    onboarding.Visible = false
end)
task.delay(30, function()
    if onboarding.Parent then onboarding.Visible = false end
end)

-- Main debate panel.
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.46, 0.52)
panel.Size = UDim2.new(0.86, 0, 0.86, 0)
panel.BackgroundColor3 = C.bg
panel.Visible = false
panel.Parent = g
corner(panel, 16)
local pc = Instance.new("UISizeConstraint")
pc.MaxSize = Vector2.new(860, 720)
pc.MinSize = Vector2.new(300, 430)
pc.Parent = panel
-- Shrink the whole panel when the viewport is too short (landscape phones) so
-- the timer, input row, and send button always stay on screen.
local uiScale = Instance.new("UIScale")
uiScale.Parent = panel
local function fitPanel()
    local avail = g.AbsoluteSize
    uiScale.Scale = math.min(1, avail.Y / 450, avail.X / 940)
end
fitPanel()
g:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPanel)

local title = label(panel, "WAITING FOR ANOTHER PLAYER", 22, C.white, true)
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.new(1, -36, 0, 34)

local topic = label(panel, "Two real players take turns. The host is scripted; it never judges truth.", 15, C.gold, true)
topic.Position = UDim2.fromOffset(18, 48)
topic.Size = UDim2.new(1, -36, 0, 52)

-- Turn status row: side badge + turn text + countdown timer.
local sideBadge = Instance.new("TextLabel")
sideBadge.BackgroundColor3 = C.panel
sideBadge.TextColor3 = C.magenta
sideBadge.Font = Enum.Font.GothamBold
sideBadge.TextSize = 14
sideBadge.Text = ""
sideBadge.Position = UDim2.fromOffset(18, 100)
sideBadge.Size = UDim2.fromOffset(170, 30)
sideBadge.Parent = panel
corner(sideBadge, 8)

local turn = label(panel, "", 16, C.green, true)
turn.Position = UDim2.fromOffset(196, 100)
turn.Size = UDim2.new(1, -320, 0, 30)

local timer = Instance.new("TextLabel")
timer.AnchorPoint = Vector2.new(1, 0)
timer.Position = UDim2.new(1, -18, 0, 100)
timer.Size = UDim2.fromOffset(106, 30)
timer.BackgroundColor3 = C.panel
timer.TextColor3 = C.white
timer.Font = Enum.Font.GothamBold
timer.TextSize = 18
timer.Text = ""
timer.Parent = panel
corner(timer, 8)

-- Session scoreboard.
local scorebar = Instance.new("Frame")
scorebar.Position = UDim2.fromOffset(18, 136)
scorebar.Size = UDim2.new(1, -36, 0, 34)
scorebar.BackgroundColor3 = C.panel
scorebar.Parent = panel
corner(scorebar, 8)
local scoreL = label(scorebar, "P1: 0", 16, C.blue, true)
scoreL.Position = UDim2.fromOffset(12, 0)
scoreL.Size = UDim2.fromScale(0.5, 1)
local scoreR = label(scorebar, "P2: 0", 16, C.gold, true)
scoreR.AnchorPoint = Vector2.new(1, 0)
scoreR.Position = UDim2.new(1, -12, 0, 0)
scoreR.Size = UDim2.fromScale(0.5, 1)
scoreR.TextXAlignment = Enum.TextXAlignment.Right

-- Transcript.
local log = Instance.new("ScrollingFrame")
log.Position = UDim2.fromOffset(18, 176)
log.Size = UDim2.new(1, -36, 1, -300)
log.BackgroundColor3 = C.panel
log.AutomaticCanvasSize = Enum.AutomaticSize.Y
log.CanvasSize = UDim2.new()
log.BorderSizePixel = 0
log.Parent = panel
corner(log, 10)
local ll = Instance.new("UIListLayout")
ll.Padding = UDim.new(0, 8)
ll.Parent = log

-- Input row (large mobile-friendly controls).
local counter = label(panel, "0 / 500 bytes", 12, C.muted)
counter.Position = UDim2.new(0, 18, 1, -124)
counter.Size = UDim2.new(1, -150, 0, 18)

local box = Instance.new("TextBox")
box.PlaceholderText = "Give a reason, example, or rebuttal\u{2026}"
box.Text = ""
box.MultiLine = true
box.TextWrapped = true
box.TextColor3 = C.white
box.PlaceholderColor3 = C.muted
box.TextSize = 16
box.Font = Enum.Font.Gotham
box.BackgroundColor3 = C.panel
box.Position = UDim2.new(0, 18, 1, -104)
box.Size = UDim2.new(1, -150, 0, 86)
box.Parent = panel
corner(box, 10)
box:GetPropertyChangedSignal("Text"):Connect(function()
    local bytes = #box.Text
    counter.Text = ("%d / %d bytes"):format(bytes, MAX_ARGUMENT_BYTES)
    counter.TextColor3 = bytes > MAX_ARGUMENT_BYTES and C.gold or C.muted
end)

local send = button(panel, "SEND TURN", C.blue)
send.Position = UDim2.new(1, -124, 1, -104)
send.Size = UDim2.fromOffset(106, 86)
send.TextSize = 18
send.Active = false
send.AutoButtonColor = false

local rematch = button(panel, "REMATCH", C.green)
rematch.Position = UDim2.new(0, 18, 1, -142)
rematch.Size = UDim2.fromOffset(130, 34)
rematch.Visible = false

-- Mutual exclusion between the multiplayer panel and the boss practice card.
-- Presentation only: the server independently rejects joining a debate while a
-- practice session is active, so this never bypasses server authority.
local inDebate = false
local function setMultiplayerVisible(v)
    panel.Visible = v
    if boss and boss.Card then
        boss.Card.Visible = (not v) and not boss.IsPracticeActive()
    end
end
bossHooks.onPracticeOpened = function()
    -- A practice session owns the screen; drop the multiplayer panel if it was open.
    panel.Visible = false
end

local queued = false
local nextSubmissionId = 0
local pendingSubmissionId = nil
local pendingText = nil
local myTurn = false
local deadline = nil
local debatePlayers = nil -- { {Name, UserId}, {Name, UserId} }
local roundScores = { 0, 0 }
local topicSides = nil

-- 3D presentation hooks (local-only visuals driven by server state).
local function stagePart(name)
    local stage = workspace:FindFirstChild("BeatTheBotDebateStage")
    return stage and stage:FindFirstChild(name) or nil
end

local function setStageText(partName, labelName, value)
    local p = stagePart(partName)
    local gui = p and p:FindFirstChildOfClass("SurfaceGui")
    local l = gui and gui:FindFirstChild(labelName)
    if l and l:IsA("TextLabel") then
        l.Text = value
    end
end


local function clearTurnHolograms()
    local stage = workspace:FindFirstChild("BeatTheBotDebateStage")
    local old = stage and stage:FindFirstChild("TurnHolograms")
    if old then old:Destroy() end
end

local function showTurnHolograms(side)
    clearTurnHolograms()
    local stage = workspace:FindFirstChild("BeatTheBotDebateStage")
    if not stage then return end
    local folder = Instance.new("Folder")
    folder.Name = "TurnHolograms"
    folder.Parent = stage
    local icons = {
        {Text="...", X=-4.5, Y=12.5},
        {Text="<> ", X=0, Y=15.5},
        {Text="!", X=4.5, Y=12.5},
    }
    local sideX = side == "Affirmative" and -5 or 5
    for index, info in ipairs(icons) do
        local anchor = Instance.new("Part")
        anchor.Name = "HologramIcon" .. index
        anchor.Size = Vector3.new(3.6, 3.6, 0.25)
        anchor.Position = Vector3.new(sideX + info.X, info.Y, 1)
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.Material = Enum.Material.Neon
        anchor.Color = Color3.fromRGB(42, 242, 229)
        anchor.Transparency = 0.72
        anchor.Parent = folder
        local gui = Instance.new("BillboardGui")
        gui.Name = "ChoiceIcon"
        gui.Size = UDim2.fromOffset(78, 78)
        gui.AlwaysOnTop = true
        gui.LightInfluence = 0
        gui.Parent = anchor
        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundColor3 = Color3.fromRGB(5, 18, 22)
        frame.BackgroundTransparency = 0.18
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(42, 242, 229)
        frame.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = frame
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = info.Text
        label.TextColor3 = Color3.fromRGB(205, 255, 250)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = frame
        local glow = Instance.new("PointLight")
        glow.Color = Color3.fromRGB(42, 242, 229)
        glow.Range = 13
        glow.Brightness = 0.8
        glow.Parent = anchor
        local base = anchor.Position
        task.spawn(function()
            local start = os.clock()
            while anchor.Parent do
                anchor.Position = base + Vector3.new(0, math.sin((os.clock()-start)*1.6 + index)*0.35, 0)
                RunService.RenderStepped:Wait()
            end
        end)
    end
end

local displayedScores = {0, 0}
local function updateStageScores()
    if not debatePlayers then return end
    local starts = {displayedScores[1], displayedScores[2]}
    local targets = {roundScores[1], roundScores[2]}
    task.spawn(function()
        for step = 1, 12 do
            for i = 1, 2 do
                displayedScores[i] = math.floor(starts[i] + (targets[i] - starts[i]) * step / 12 + 0.5)
            end
            setStageText("Scoreboard", "ScoreLeftText", tostring(displayedScores[1]))
            setStageText("Scoreboard", "ScoreRightText", tostring(displayedScores[2]))
            task.wait(0.035)
        end
    end)
end

local function updateScorebar()
    if debatePlayers then
        scoreL.Text = debatePlayers[1].Name .. ": " .. roundScores[1]
        scoreR.Text = debatePlayers[2].Name .. ": " .. roundScores[2]
    end
end

-- Countdown driven by the server-provided deadline; display only.
RunService.Heartbeat:Connect(function()
    if deadline == nil then
        timer.Text = ""
        return
    end
    local remaining = deadline - workspace:GetServerTimeNow()
    if remaining <= 0 then
        timer.Text = "0:00"
        timer.TextColor3 = C.magenta
        return
    end
    timer.Text = ("%d:%02d"):format(math.floor(remaining / 60), math.floor(remaining % 60))
    timer.TextColor3 = remaining <= 10 and C.magenta or C.white
end)

local function popup(heading, body)
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(1, 0.5)
    f.Position = UDim2.new(1, -178, 0.5, 0)
    f.Size = UDim2.fromOffset(300, 270)
    f.BackgroundColor3 = C.bg
    f.Parent = g
    corner(f, 12)
    local h = label(f, heading, 20, C.gold, true)
    h.Position = UDim2.fromOffset(16, 12)
    h.Size = UDim2.new(1, -32, 0, 30)
    local b = label(f, body, 15, C.white)
    b.Position = UDim2.fromOffset(16, 48)
    b.Size = UDim2.new(1, -32, 1, -64)
    b.TextYAlignment = Enum.TextYAlignment.Top
    task.delay(6, function()
        if f.Parent then f:Destroy() end
    end)
end

chairs.Activated:Connect(function()
    popup("CHAIRS", "Starter Chair \u{2014} owned\nBlue Chair \u{2014} 30 points\nGold Chair \u{2014} 100 points\n\nSession preview only; no purchase or persistence.")
end)
titles.Activated:Connect(function()
    popup("TITLES", "Debater \u{2014} owned\nClear Thinker \u{2014} 60 points\n\nSession preview only; no purchase or persistence.")
end)
profileButton.Activated:Connect(function() submit:FireServer("profile") end)
rematch.Activated:Connect(function()
    submit:FireServer("rematch")
    rematch.Text = "WAITING\u{2026}"
    rematch.Active = false
end)

local function row(who, text, col)
    local x = label(log, who .. "\n" .. text, 16, col, who ~= "SYSTEM")
    x.Size = UDim2.new(1, -18, 0, 72)
    x.AutomaticSize = Enum.AutomaticSize.Y
    x.TextYAlignment = Enum.TextYAlignment.Top
    x.Parent = log
    return x
end

local function clearLog()
    for _, x in ipairs(log:GetChildren()) do
        if x:IsA("TextLabel") then x:Destroy() end
    end
end

local function countScore(name, points)
    local x = row("SCORE", name .. ": 0 session points", C.green)
    task.spawn(function()
        for value = 1, points do
            if not x.Parent then return end
            x.Text = "SCORE\n" .. name .. ": " .. value .. " session points"
            task.wait(0.035)
        end
    end)
end

play.Activated:Connect(function()
    if boss and boss.IsPracticeActive() then
        popup("MULTIPLAYER", "Leave SCRIPTED PRACTICE first (LEAVE button), then find a real debate.")
        return
    end
    if queued then
        submit:FireServer("cancelQueue")
    else
        submit:FireServer("queue")
    end
end)

send.Activated:Connect(function()
    if not myTurn or pendingSubmissionId ~= nil or box.Text == "" then return end
    nextSubmissionId += 1
    pendingSubmissionId = nextSubmissionId
    pendingText = box.Text
    submit:FireServer("argument", { Id = pendingSubmissionId, Text = pendingText })
    send.Text = "SENDING\u{2026}"
    send.Active = false
    send.AutoButtonColor = false
end)

local function sideLabel(side)
    if topicSides and side and topicSides[side] then
        return topicSides[side].Label or side
    end
    return side or ""
end

state.OnClientEvent:Connect(function(m)
    if m.Kind == "Lobby" then
        queued = m.Status == "QUEUED"
        play.Text = queued and "CANCEL SEARCH" or "FIND DEBATE"
        if queued then
            setMultiplayerVisible(true)
            title.Text = "WAITING FOR ANOTHER PLAYER"
            topic.Text = ("Players waiting: %d"):format(m.QueueSize or 1)
        elseif not inDebate then
            setMultiplayerVisible(false)
        end
    elseif m.Kind == "Profile" then
        local x = m.Profile
        popup("PROFILE", ("Session points: %d\nChair: %s\nTitle: %s\n\nProgress resets when this server closes."):format(x.Points, x.Chair, x.Title))
    elseif m.Kind == "Start" then
        clearTurnHolograms()
        rematch.Visible = false
        rematch.Text = "REMATCH"
        rematch.Active = true
        queued = false
        inDebate = true
        play.Text = "FIND DEBATE"
        setMultiplayerVisible(true)
        debatePlayers = { { Name = m.Players[1].Name, UserId = m.Players[1].UserId }, { Name = m.Players[2].Name, UserId = m.Players[2].UserId } }
        roundScores = { 0, 0 }
        displayedScores = { 0, 0 }
        topicSides = m.Topic and m.Topic.Sides or nil
        title.Text = m.Players[1].Name .. "  vs  " .. m.Players[2].Name
        topic.Text = "TOPIC: " .. m.Topic.Topic
        sideBadge.Text = ""
        updateScorebar()
        updateStageScores()
        setStageText("TopicDisplay", "TopicText", m.Topic.Topic or "")
        clearLog()
        row("SCRIPTED HOST", m.Opening, C.gold)
        row("SCORING", m.Rules .. " Base +10, reason +5, example +5, rebuttal +5.", C.muted)
    elseif m.Kind == "Turn" then
        myTurn = m.UserId == player.UserId
        deadline = m.Deadline
        local sLabel = sideLabel(m.Side)
        sideBadge.Text = "SIDE: " .. sLabel
        sideBadge.TextColor3 = m.Side == "Affirmative" and C.blue or C.magenta
        turn.Text = (myTurn and "YOUR TURN" or (m.Name .. " IS THINKING")) .. " \u{2022} " .. m.Role
        if myTurn then
            row("SCRIPTED HOST", m.HostPrompt, C.gold)
        end
        send.Text = myTurn and "SEND TURN" or "WAIT"
        send.Active = myTurn
        send.AutoButtonColor = myTurn
        showTurnHolograms(m.Side)
    elseif m.Kind == "PlayerTurn" then
        clearTurnHolograms()
        if m.UserId == player.UserId and m.SubmissionId == pendingSubmissionId then
            pendingSubmissionId = nil
            pendingText = nil
            box.Text = ""
            myTurn = false
        end
        if debatePlayers then
            for i, info in ipairs(debatePlayers) do
                if info.UserId == m.UserId then
                    roundScores[i] = m.RoundTotal or roundScores[i]
                end
            end
            updateScorebar()
            updateStageScores()
        end
        row(m.Name .. "  +" .. m.Points, m.Text .. "\n" .. table.concat(m.Reasons, " \u{2022} "), C.white)
        for _, reaction in ipairs(m.JudgeReactions or {}) do
            row(reaction.Judge .. " \u{2022} " .. (reaction.Earned and "+5" or "NOT DETECTED"), reaction.Commentary .. "\n" .. reaction.Label, reaction.Earned and C.green or C.muted)
        end
    elseif m.Kind == "AIReply" then
        row(m.Label, m.Text, C.gold)
    elseif m.Kind == "Complete" then
        clearTurnHolograms()
        myTurn = false
        deadline = nil
        inDebate = false
        send.Text = "COMPLETE"
        turn.Text = m.Message
        rematch.Visible = true
        for index, verdict in ipairs((m.Panel and m.Panel.Lines) or {}) do
            task.delay((index - 1) * 0.7, function()
                row(verdict.Judge, verdict.Text, C.gold)
            end)
        end
        task.delay(2.3, function()
            row("PANEL DISCLOSURE", m.Panel and m.Panel.Disclosure or "SCRIPTED PRACTICE \u{2014} checklist totals only.", C.muted)
            for _, s in ipairs(m.Scores) do
                countScore(s.Name, s.Points)
            end
        end)
    elseif m.Kind == "TenSecondWarning" then
        if m.UserId == player.UserId then
            row("10 SECONDS", "Finish and send your current turn.", C.gold)
        end
    elseif m.Kind == "ArgumentRejected" then
        if m.SubmissionId == pendingSubmissionId or m.SubmissionId == nil then
            pendingSubmissionId = nil
            if pendingText then box.Text = pendingText end -- rejected input keeps the draft
            pendingText = nil
            myTurn = m.CanRetry == true
            send.Text = myTurn and "SEND TURN" or "WAIT"
            send.Active = myTurn
            send.AutoButtonColor = myTurn
            row("SYSTEM", m.Message, C.gold)
        end
    elseif m.Kind == "TurnTimedOut" then
        myTurn = false
        deadline = nil
        row("SYSTEM", m.Message, C.gold)
    elseif m.Kind == "RematchStatus" then
        row("SYSTEM", m.Name .. " wants another round.", C.green)
    elseif m.Kind == "Ended" or m.Kind == "Error" then
        myTurn = false
        deadline = nil
        inDebate = false
        row("SYSTEM", m.Message, C.gold)
    end
    log.CanvasPosition = Vector2.new(0, 99999)
end)
