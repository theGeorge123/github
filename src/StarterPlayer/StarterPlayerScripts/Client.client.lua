local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Shared.Config)
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "CrystalRushUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function roundify(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = object
end

local function stroke(object, transparency)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(130, 115, 255)
    s.Transparency = transparency or 0.35
    s.Thickness = 1.5
    s.Parent = object
end

local function buttonBase(text)
    local button = Instance.new("TextButton")
    button.BackgroundColor3 = Color3.fromRGB(100, 80, 255)
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 17
    roundify(button, 14)
    return button
end

local top = Instance.new("Frame")
top.Size = UDim2.new(0, 420, 0, 78)
top.Position = UDim2.new(0.5, -210, 0, 22)
top.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
top.BackgroundTransparency = 0.08
top.Parent = gui
roundify(top, 18)
stroke(top)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 32)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "CRYSTAL RUSH"
title.TextColor3 = Color3.fromRGB(150, 235, 255)
title.TextSize = 23
title.Parent = top

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 28)
status.Position = UDim2.new(0, 10, 0, 40)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamMedium
status.Text = "Loading..."
status.TextColor3 = Color3.fromRGB(230, 230, 240)
status.TextSize = 18
status.Parent = top

local stats = Instance.new("Frame")
stats.Size = UDim2.new(0, 220, 0, 96)
stats.Position = UDim2.new(0, 22, 0, 22)
stats.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
stats.BackgroundTransparency = 0.08
stats.Parent = gui
roundify(stats, 16)
stroke(stats)

local statLabel = Instance.new("TextLabel")
statLabel.Size = UDim2.new(1, -20, 1, -16)
statLabel.Position = UDim2.new(0, 10, 0, 8)
statLabel.BackgroundTransparency = 1
statLabel.Font = Enum.Font.GothamSemibold
statLabel.TextXAlignment = Enum.TextXAlignment.Left
statLabel.TextYAlignment = Enum.TextYAlignment.Top
statLabel.Text = "Coins: 0\nXP: 0\nWins: 0"
statLabel.TextColor3 = Color3.fromRGB(240, 240, 248)
statLabel.TextSize = 18
statLabel.Parent = stats

local shopButton = buttonBase("UPGRADES")
shopButton.Size = UDim2.new(0, 170, 0, 50)
shopButton.Position = UDim2.new(1, -192, 0, 28)
shopButton.Parent = gui

local dailyButton = buttonBase("DAILY REWARD")
dailyButton.Size = UDim2.new(0, 170, 0, 50)
dailyButton.Position = UDim2.new(1, -192, 0, 88)
dailyButton.BackgroundColor3 = Color3.fromRGB(30, 170, 150)
dailyButton.Parent = gui

local shop = Instance.new("Frame")
shop.Size = UDim2.new(0, 390, 0, 360)
shop.Position = UDim2.new(0.5, -195, 0.5, -180)
shop.BackgroundColor3 = Color3.fromRGB(18, 20, 31)
shop.Visible = false
shop.Parent = gui
roundify(shop, 20)
stroke(shop, 0.15)

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, -30, 0, 55)
shopTitle.Position = UDim2.new(0, 15, 0, 10)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Text = "PERMANENT UPGRADES"
shopTitle.TextColor3 = Color3.fromRGB(150, 235, 255)
shopTitle.TextSize = 22
shopTitle.Parent = shop

local message = Instance.new("TextLabel")
message.Size = UDim2.new(1, -30, 0, 30)
message.Position = UDim2.new(0, 15, 1, -40)
message.BackgroundTransparency = 1
message.Font = Enum.Font.Gotham
message.Text = ""
message.TextColor3 = Color3.fromRGB(255, 220, 130)
message.TextSize = 15
message.Parent = shop

local questPanel = Instance.new("Frame")
questPanel.Size = UDim2.new(0, 300, 0, 220)
questPanel.Position = UDim2.new(0, 22, 1, -245)
questPanel.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
questPanel.BackgroundTransparency = 0.08
questPanel.Parent = gui
roundify(questPanel, 16)
stroke(questPanel)

local questTitle = Instance.new("TextLabel")
questTitle.Size = UDim2.new(1, -20, 0, 36)
questTitle.Position = UDim2.new(0, 10, 0, 6)
questTitle.BackgroundTransparency = 1
questTitle.Font = Enum.Font.GothamBold
questTitle.Text = "DAILY QUESTS"
questTitle.TextColor3 = Color3.fromRGB(150, 235, 255)
questTitle.TextSize = 18
questTitle.Parent = questPanel

local profile = {
    Coins = 0,
    XP = 0,
    Wins = 0,
    Upgrades = { Speed = 0, Jump = 0, Magnet = 0 },
    Daily = { Streak = 0, CanClaim = true },
    Quests = {
        Progress = { Collect = 0, Rounds = 0, Survive = 0 },
        Claimed = { Collect = false, Rounds = false, Survive = false },
    },
}

local upgradeButtons = {}
local questButtons = {}

local function refresh()
    statLabel.Text = string.format("Coins: %d\nXP: %d\nWins: %d", profile.Coins or 0, profile.XP or 0, profile.Wins or 0)

    local daily = profile.Daily or {}
    if daily.CanClaim then
        dailyButton.Text = string.format("DAILY REWARD • %d🔥", daily.Streak or 0)
        dailyButton.AutoButtonColor = true
        dailyButton.BackgroundColor3 = Color3.fromRGB(30, 170, 150)
    else
        dailyButton.Text = string.format("CLAIMED • %d DAY STREAK", daily.Streak or 0)
        dailyButton.AutoButtonColor = false
        dailyButton.BackgroundColor3 = Color3.fromRGB(65, 70, 80)
    end

    for name, button in pairs(upgradeButtons) do
        local level = profile.Upgrades and profile.Upgrades[name] or 0
        local data = Config.Upgrades[name]
        if level >= data.maxLevel then
            button.Text = string.format("%s  Lv.%d  •  MAX", name, level)
        else
            button.Text = string.format("%s  Lv.%d  •  %d Coins", name, level, Config.getUpgradeCost(name, level))
        end
    end

    for name, button in pairs(questButtons) do
        local data = Config.Quests[name]
        local progress = profile.Quests and profile.Quests.Progress and profile.Quests.Progress[name] or 0
        local claimed = profile.Quests and profile.Quests.Claimed and profile.Quests.Claimed[name]
        if claimed then
            button.Text = string.format("✓ %s  •  CLAIMED", data.label)
            button.BackgroundColor3 = Color3.fromRGB(50, 80, 70)
        elseif progress >= data.target then
            button.Text = string.format("%s  •  CLAIM +%d", data.label, data.reward)
            button.BackgroundColor3 = Color3.fromRGB(30, 140, 115)
        else
            button.Text = string.format("%s  •  %d/%d", data.label, progress, data.target)
            button.BackgroundColor3 = Color3.fromRGB(42, 45, 67)
        end
    end
end

for index, name in ipairs({ "Speed", "Jump", "Magnet" }) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -40, 0, 66)
    button.Position = UDim2.new(0, 20, 0, 62 + (index - 1) * 78)
    button.BackgroundColor3 = Color3.fromRGB(42, 45, 67)
    button.Font = Enum.Font.GothamSemibold
    button.TextColor3 = Color3.fromRGB(245, 245, 250)
    button.TextSize = 17
    button.Parent = shop
    roundify(button, 14)
    stroke(button, 0.65)
    upgradeButtons[name] = button

    button.MouseButton1Click:Connect(function()
        local ok, result, msg = pcall(function()
            return remotes.PurchaseUpgrade:InvokeServer(name)
        end)
        message.Text = ok and (msg or "") or "Purchase failed"
        if ok and result then
            button.BackgroundColor3 = Color3.fromRGB(65, 75, 100)
            TweenService:Create(button, TweenInfo.new(0.25), {
                BackgroundColor3 = Color3.fromRGB(42, 45, 67)
            }):Play()
        end
    end)
end

for index, name in ipairs({ "Collect", "Rounds", "Survive" }) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 48)
    button.Position = UDim2.new(0, 10, 0, 44 + (index - 1) * 56)
    button.BackgroundColor3 = Color3.fromRGB(42, 45, 67)
    button.Font = Enum.Font.GothamMedium
    button.TextColor3 = Color3.fromRGB(240, 240, 248)
    button.TextSize = 14
    button.TextWrapped = true
    button.Parent = questPanel
    roundify(button, 10)
    questButtons[name] = button

    button.MouseButton1Click:Connect(function()
        local ok, result, msg = pcall(function()
            return remotes.ClaimQuest:InvokeServer(name)
        end)
        if ok and result then
            message.Text = "Quest reward: " .. tostring(msg)
        end
    end)
end

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0, 600, 0, 36)
hint.Position = UDim2.new(0.5, -300, 1, -55)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.GothamMedium
hint.Text = "Collect glowing crystals • Stay above the rising energy • Survive to earn bonuses"
hint.TextColor3 = Color3.fromRGB(225, 225, 240)
hint.TextStrokeTransparency = 0.55
hint.TextSize = 16
hint.Parent = gui

shopButton.MouseButton1Click:Connect(function()
    shop.Visible = not shop.Visible
end)

dailyButton.MouseButton1Click:Connect(function()
    if profile.Daily and not profile.Daily.CanClaim then
        return
    end

    local ok, result, msg = pcall(function()
        return remotes.ClaimDaily:InvokeServer()
    end)

    if ok and result then
        message.Text = "Daily reward: " .. tostring(msg)
    end
end)

remotes.DataUpdated.OnClientEvent:Connect(function(data)
    profile = data
    refresh()
end)

remotes.RoundState.OnClientEvent:Connect(function(data)
    if data.phase == "Intermission" then
        status.Text = string.format("Next round in %ds", data.timeLeft)
    elseif data.phase == "Round" then
        status.Text = string.format("Round %d  •  %ds remaining", data.round, data.timeLeft)
    else
        status.Text = "Round over — rewards paid"
    end
end)

local ok, initialProfile = pcall(function()
    return remotes.GetProfile:InvokeServer()
end)
if ok and type(initialProfile) == "table" then
    profile = initialProfile
end
refresh()
