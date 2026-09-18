local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DataService = {}

local store = DataStoreService:GetDataStore("CrystalRush_v1")
local profiles = {}
local remotes

local DEFAULT = {
    Coins = 0,
    XP = 0,
    Wins = 0,
    Upgrades = {
        Speed = 0,
        Jump = 0,
        Magnet = 0,
    },
}

local function copyDefault()
    return {
        Coins = DEFAULT.Coins,
        XP = DEFAULT.XP,
        Wins = DEFAULT.Wins,
        Upgrades = {
            Speed = 0,
            Jump = 0,
            Magnet = 0,
        },
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
    return result
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

local function loadPlayer(player)
    local loaded
    local ok = pcall(function()
        loaded = store:GetAsync("u_" .. player.UserId)
    end)

    profiles[player] = reconcile(ok and loaded or nil)

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
    remotes.DataUpdated:FireClient(player, profiles[player])
end

function DataService.Init(remoteFolder)
    remotes = remoteFolder

    remotes.GetProfile.OnServerInvoke = function(player)
        local timeout = os.clock() + 5
        while not profiles[player] and os.clock() < timeout do
            task.wait(0.05)
        end
        return profiles[player] or copyDefault()
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

function DataService.Add(player, key, amount)
    local profile = profiles[player]
    if not profile or type(profile[key]) ~= "number" then
        return
    end
    profile[key] += amount
    updateLeaderstats(player)
    if remotes then
        remotes.DataUpdated:FireClient(player, profile)
    end
end

function DataService.SetUpgrade(player, name, level)
    local profile = profiles[player]
    if not profile or profile.Upgrades[name] == nil then
        return false
    end
    profile.Upgrades[name] = level
    if remotes then
        remotes.DataUpdated:FireClient(player, profile)
    end
    return true
end

function DataService.SpendCoins(player, amount)
    local profile = profiles[player]
    if not profile or profile.Coins < amount then
        return false
    end
    profile.Coins -= amount
    updateLeaderstats(player)
    if remotes then
        remotes.DataUpdated:FireClient(player, profile)
    end
    return true
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
