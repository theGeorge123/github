local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

local store = DataStoreService:GetDataStore("CrystalRush_v2")
local profiles = {}
local remotes

local function utcDay()
    return math.floor(os.time() / 86400)
end

local function freshQuestState(day)
    return {
        Day = day,
        Progress = {
            Collect = 0,
            Rounds = 0,
            Survive = 0,
        },
        Claimed = {
            Collect = false,
            Rounds = false,
            Survive = false,
        },
    }
end

local function copyDefault()
    local day = utcDay()
    return {
        Coins = 0,
        XP = 0,
        Wins = 0,
        Upgrades = {
            Speed = 0,
            Jump = 0,
            Magnet = 0,
        },
        Daily = {
            LastClaimDay = -1,
            Streak = 0,
        },
        Quests = freshQuestState(day),
    }
end

local function reconcile(data)
    local result = copyDefault()
    if type(data) ~= "table" then
        return result
    end

    result.Coins = tonumber(data.Coins) or 0
    result.XP = tonumber(data.XP) or 0
    result.Wins = tonumber(data.Wins) or 0

    if type(data.Upgrades) == "table" then
        for name in pairs(result.Upgrades) do
            result.Upgrades[name] = tonumber(data.Upgrades[name]) or 0
        end
    end

    if type(data.Daily) == "table" then
        result.Daily.LastClaimDay = tonumber(data.Daily.LastClaimDay) or -1
        result.Daily.Streak = tonumber(data.Daily.Streak) or 0
    end

    if type(data.Quests) == "table" and tonumber(data.Quests.Day) == utcDay() then
        result.Quests.Day = utcDay()
        if type(data.Quests.Progress) == "table" then
            for name in pairs(result.Quests.Progress) do
                result.Quests.Progress[name] = tonumber(data.Quests.Progress[name]) or 0
            end
        end
        if type(data.Quests.Claimed) == "table" then
            for name in pairs(result.Quests.Claimed) do
                result.Quests.Claimed[name] = data.Quests.Claimed[name] == true
            end
        end
    end

    return result
end

local function refreshDailyState(profile)
    local day = utcDay()
    if profile.Quests.Day ~= day then
        profile.Quests = freshQuestState(day)
    end
end

local function publicProfile(profile)
    refreshDailyState(profile)
    return {
        Coins = profile.Coins,
        XP = profile.XP,
        Wins = profile.Wins,
        Upgrades = profile.Upgrades,
        Daily = {
            Streak = profile.Daily.Streak,
            CanClaim = profile.Daily.LastClaimDay ~= utcDay(),
        },
        Quests = profile.Quests,
    }
end

local function updateLeaderstats(player)
    local profile = profiles[player]
    local leaderstats = player:FindFirstChild("leaderstats")
    if not profile or not leaderstats then
        return
    end
    leaderstats.Coins.Value = profile.Coins
    leaderstats.Wins.Value = profile.Wins
end

local function push(player)
    local profile = profiles[player]
    if profile and remotes then
        remotes.DataUpdated:FireClient(player, publicProfile(profile))
    end
end

local function loadPlayer(player)
    if profiles[player] then
        return
    end

    local loaded
    local ok = pcall(function()
        loaded = store:GetAsync("u_" .. player.UserId)
    end)

    profiles[player] = reconcile(ok and loaded or nil)

    local old = player:FindFirstChild("leaderstats")
    if old then
        old:Destroy()
    end

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Parent = leaderstats

    local wins = Instance.new("IntValue")
    wins.Name = "Wins"
    wins.Parent = leaderstats

    updateLeaderstats(player)
    push(player)
end

function DataService.Init(remoteFolder)
    remotes = remoteFolder

    remotes.GetProfile.OnServerInvoke = function(player)
        local timeout = os.clock() + 5
        while not profiles[player] and os.clock() < timeout do
            task.wait(0.05)
        end
        local profile = profiles[player]
        return profile and publicProfile(profile) or publicProfile(copyDefault())
    end

    Players.PlayerAdded:Connect(loadPlayer)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(loadPlayer, player)
    end

    Players.PlayerRemoving:Connect(function(player)
        DataService.Save(player)
        profiles[player] = nil
    end)

    game:BindToClose(function()
        for _, player in ipairs(Players:GetPlayers()) do
            DataService.Save(player)
        end
    end)
end

function DataService.Get(player)
    return profiles[player]
end

function DataService.GetPublic(player)
    local profile = profiles[player]
    return profile and publicProfile(profile) or nil
end

function DataService.Add(player, key, amount)
    local profile = profiles[player]
    if not profile or type(profile[key]) ~= "number" then
        return
    end
    profile[key] += amount
    updateLeaderstats(player)
    push(player)
end

function DataService.SetUpgrade(player, name, level)
    local profile = profiles[player]
    if not profile or profile.Upgrades[name] == nil then
        return false
    end
    profile.Upgrades[name] = level
    push(player)
    return true
end

function DataService.SpendCoins(player, amount)
    local profile = profiles[player]
    if not profile or profile.Coins < amount then
        return false
    end
    profile.Coins -= amount
    updateLeaderstats(player)
    push(player)
    return true
end

function DataService.AddQuestProgress(player, name, amount)
    local profile = profiles[player]
    local quest = Config.Quests[name]
    if not profile or not quest then
        return
    end

    refreshDailyState(profile)
    if profile.Quests.Claimed[name] then
        return
    end

    profile.Quests.Progress[name] = math.min(
        quest.target,
        (profile.Quests.Progress[name] or 0) + amount
    )
    push(player)
end

function DataService.ClaimQuest(player, name)
    local profile = profiles[player]
    local quest = Config.Quests[name]
    if not profile or not quest then
        return false, "Invalid quest"
    end

    refreshDailyState(profile)

    if profile.Quests.Claimed[name] then
        return false, "Already claimed"
    end

    if (profile.Quests.Progress[name] or 0) < quest.target then
        return false, "Quest not complete"
    end

    profile.Quests.Claimed[name] = true
    profile.Coins += quest.reward
    updateLeaderstats(player)
    push(player)
    return true, quest.reward
end

function DataService.ClaimDaily(player)
    local profile = profiles[player]
    if not profile then
        return false, "Profile not loaded"
    end

    local day = utcDay()
    if profile.Daily.LastClaimDay == day then
        return false, "Already claimed"
    end

    if profile.Daily.LastClaimDay == day - 1 then
        profile.Daily.Streak += 1
    else
        profile.Daily.Streak = 1
    end

    profile.Daily.LastClaimDay = day
    local reward = math.min(
        Config.DailyReward.maxCoins,
        Config.DailyReward.baseCoins + ((profile.Daily.Streak - 1) * Config.DailyReward.streakBonus)
    )

    profile.Coins += reward
    updateLeaderstats(player)
    push(player)
    return true, reward, profile.Daily.Streak
end

function DataService.Save(player)
    local profile = profiles[player]
    if not profile then
        return
    end
    pcall(function()
        store:SetAsync("u_" .. player.UserId, profile)
    end)
end

return DataService
