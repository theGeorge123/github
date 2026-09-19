local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BeatTheBotRemotes")
local stateRemote = remotes:WaitForChild("State")
local submitRemote = remotes:WaitForChild("Submit")
local current
local pending = false
local lastSent = 0
local history = {}
local lastHistoryTurn = -1
local navy = Color3.fromRGB(18, 25, 45)
local cyan = Color3.fromRGB(73, 220, 236)
local white = Color3.fromRGB(239, 245, 255)
local muted = Color3.fromRGB(177, 195, 217)

local screen = Instance.new("ScreenGui")
screen.Name = "BeatTheBotHUD"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = player:WaitForChild("PlayerGui")

local function round(object)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = object
end

local function label(parent, text, height, size, color)
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Size = UDim2.new(1, 0, 0, height)
    object.Text = text
    object.Font = Enum.Font.Gotham
    object.TextSize = size or 16
    object.TextColor3 = color or white
    object.TextWrapped = true
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.RichText = false
    object.Parent = parent
    return object
end

local function button(parent, text, height)
    local object = Instance.new("TextButton")
    object.Size = UDim2.new(1, 0, 0, height or 42)
    object.BackgroundColor3 = Color3.fromRGB(35, 63, 81)
    object.TextColor3 = white
    object.Text = text
    object.TextSize = 16
    object.TextWrapped = true
    object.Font = Enum.Font.GothamMedium
    object.Parent = parent
    round(object)
    return object
end

local header = Instance.new("Frame")
header.Size = UDim2.new(0.94, 0, 0, 76)
header.Position = UDim2.new(0.03, 0, 0, 8)
header.BackgroundColor3 = navy
header.Parent = screen
round(header)
local stats = label(header, "BEAT THE BOT  |  Loading your profile...", 36, 17, cyan)
stats.Position = UDim2.fromOffset(12, 0)
stats.Size = UDim2.new(1, -135, 0, 36)
local guidance = label(header, "Walk to a glowing arena console. Watch other matches from the benches.", 34, 13, muted)
guidance.Position = UDim2.fromOffset(12, 35)
guidance.Size = UDim2.new(1, -24, 0, 34)
local toggle = button(header, "MATCH", 32)
toggle.Size = UDim2.fromOffset(100, 32)
toggle.Position = UDim2.new(1, -112, 0, 3)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 94)
panel.Size = UDim2.new(0.94, 0, 0.72, -30)
panel.BackgroundColor3 = navy
panel.Visible = false
panel.Parent = screen
round(panel)
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(540, 850)
constraint.Parent = panel
local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(14, 12)
scroll.Size = UDim2.new(1, -28, 1, -24)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = panel
local padding = Instance.new("UIPadding")
padding.PaddingRight = UDim.new(0, 9)
padding.PaddingBottom = UDim.new(0, 12)
padding.Parent = scroll
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 9)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll
local order = 0
local function ordered(object)
    order += 1
    object.LayoutOrder = order
    return object
end

local title = ordered(label(scroll, "THE CASTLE GUARD", 30, 23, cyan))
ordered(label(scroll, "Get your delivery through the gate. You carry a permit with a royal seal. Build trust to 100% before 8 moves run out. Suspicion at 100% loses.", 68, 15, muted))
local meters = ordered(label(scroll, "", 45, 18, cyan))
local clockLabel = ordered(label(scroll, "", 25, 14, muted))
local transcript = ordered(label(scroll, "", 0, 17))
transcript.AutomaticSize = Enum.AutomaticSize.Y
local hint = ordered(label(scroll, "", 52, 15, Color3.fromRGB(255, 199, 89)))
ordered(label(scroll, "QUICK MOVES — or type your own below", 26, 14, muted))

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, 0, 0, 50)
input.BackgroundColor3 = Color3.fromRGB(35, 46, 66)
input.TextColor3 = white
input.PlaceholderColor3 = muted
input.PlaceholderText = "Your argument (English, 240 bytes max)"
input.Text = ""
input.ClearTextOnFocus = false
input.MultiLine = false
input.TextSize = 16
input.Font = Enum.Font.Gotham
round(input)

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
    guidance.Text = "Guard is thinking..."
    submitRemote:FireServer({
        MatchId = current.MatchId, Turn = current.Turns + 1, Kind = kind, Value = value,
    })
end

for _, choice in ipairs(Config.Choices) do
    local move = ordered(button(scroll, choice.Text))
    move.Activated:Connect(function()
        submit("Choice", choice.Id)
    end)
end
input.Parent = scroll
ordered(input)
local send = ordered(button(scroll, "SEND ARGUMENT"))
send.BackgroundColor3 = Color3.fromRGB(21, 111, 120)
send.Activated:Connect(function()
    submit("Text", input.Text)
end)
input.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submit("Text", input.Text)
    end
end)
ordered(label(scroll, "Local, rule-based opponent — not a live language model. Quick moves work without text filtering. Resetting, leaving, or timing out forfeits the match. Hiding this panel does not pause the timer.", 80, 13, muted))
local hide = ordered(button(scroll, "HIDE PANEL / WATCH THE ARENA"))
hide.Activated:Connect(function()
    panel.Visible = false
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
        panel.Visible = true
        scroll.CanvasPosition = Vector2.zero
    end
    current = packet
    title.Text = string.format("ARENA %d  |  %s", packet.ArenaId, packet.Status == "Playing" and "THE CASTLE GUARD" or string.upper(packet.Status))
    meters.Text = string.format("Trust %d%%  |  Suspicion %d%%\nMoves used: %d / %d", packet.Progress, packet.Suspicion, packet.Turns, Config.MaxTurns)
    if packet.Turns ~= lastHistoryTurn then
        lastHistoryTurn = packet.Turns
        if packet.Summary then
            table.insert(history, "YOU: " .. packet.Summary)
        end
        table.insert(history, "GUARD: " .. packet.Message)
    elseif #history > 0 then
        history[#history] = "GUARD: " .. packet.Message
    end
    transcript.Text = table.concat(history, "\n\n")
    hint.Text = packet.Status == "Playing" and ("TIP: " .. packet.Hint) or "Try another match once the console reopens (5 seconds)."
    guidance.Text = packet.Status == "Playing" and "Choose a quick move or type an argument. Spectators see only safe move summaries." or packet.Message
    if packet.Delta then
        guidance.Text = string.format("%s  |  ELO %+d  |  Result saved%s", string.upper(packet.Status), packet.Delta, player:GetAttribute("SessionOnly") and " for this Studio session only" or "")
    end
    input.Text = ""
end)

task.spawn(function()
    local leaderstats = player:WaitForChild("leaderstats")
    local elo = leaderstats:WaitForChild("Elo")
    local wins = leaderstats:WaitForChild("Wins")
    local losses = leaderstats:WaitForChild("Losses")
    local function refresh()
        stats.Text = string.format("ELO %d  |  W %d  L %d%s", elo.Value, wins.Value, losses.Value, player:GetAttribute("SessionOnly") and "  |  TEST ONLY" or "")
    end
    elo.Changed:Connect(refresh)
    wins.Changed:Connect(refresh)
    losses.Changed:Connect(refresh)
    player:GetAttributeChangedSignal("SessionOnly"):Connect(refresh)
    refresh()
end)

RunService.Heartbeat:Connect(function()
    if current and current.Status == "Playing" then
        clockLabel.Text = string.format("%ds remaining — eight moves, three minutes", math.max(0, math.ceil(current.Deadline - workspace:GetServerTimeNow())))
    else
        clockLabel.Text = "Match complete"
    end
end)
