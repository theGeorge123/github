local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local ProfileStore = require(script.Parent.Parent.Core.ProfileStore)
local Rules = require(script.Parent.Parent.Core.Rules)
local RankDefinitions = require(script.Parent.Parent.Core.RankDefinitions)

local DataService = { Sessions = {} }
local repository
local sessionOnly = RunService:IsStudio() and not Config.StudioPersistence

local function retry(callback)
    for attempt = 1, 3 do
        local ok, result = pcall(callback)
        if ok then
            return result
        end
        warn("Beat the Bot: profile request failed; retrying without logging profile content.")
        task.wait(attempt)
    end
    return nil
end

local function ensureStat(stats, name)
    local value = stats:FindFirstChild(name)
    if not value then
        value = Instance.new("IntValue")
        value.Name = name
        value.Parent = stats
    end
    return value
end

local function publish(player, session)
    local profile = session.Profile
    local stats = player:FindFirstChild("leaderstats")
    if not stats then
        stats = Instance.new("Folder")
        stats.Name = "leaderstats"
        stats.Parent = player
    end

    ensureStat(stats, "Elo").Value = profile.Elo
    ensureStat(stats, "Wins").Value = profile.Wins
    ensureStat(stats, "Losses").Value = profile.Losses
    ensureStat(stats, "Insight").Value = profile.Insight or 0

    local rank = RankDefinitions.ForElo(profile.Elo)
    player:SetAttribute("RankTitle", rank.Name)
    player:SetAttribute("DailyStreak", profile.DailyTrial and profile.DailyTrial.Streak or 0)
    player:SetAttribute("EquippedTitle", profile.Equipped and profile.Equipped.Titles or "")
    player:SetAttribute("SessionOnly", sessionOnly)
    player:SetAttribute("HasPlayedBefore", ProfileStore.HasPlayed(profile))
    player:SetAttribute("ProfileReady", true)
end

function DataService.Init()
    local store

    if sessionOnly then
        local records = {}
        store = {
            UpdateAsync = function(_, key, transform)
                local result = transform(records[key])
                if result then
                    records[key] = result
                end
                return result
            end,
        }
    else
        store = DataStoreService:GetDataStore(Config.StoreName)
    end

    repository = ProfileStore.new(store, Config, Rules, os.time)

    task.spawn(function()
        while true do
            task.wait(Config.SaveInterval)
            for player in pairs(DataService.Sessions) do
                task.spawn(function()
                    local session = DataService.Sessions[player]
                    if session and not session.Closing then
                        local result = DataService.Update(player, "Renew")
                        if not result and player.Parent then
                            player:Kick("Your data session could not be renewed. Please rejoin shortly.")
                        end
                    end
                end)
            end
        end
    end)
end

function DataService.Load(player)
    local token = HttpService:GenerateGUID(false)
    local profile = retry(function()
        return repository:Acquire(player.UserId, token)
    end)

    if not profile then
        player:Kick("Data unavailable or already open on another server. Please try again shortly.")
        return nil
    end

    local session = {
        Token = token,
        Profile = profile,
        Busy = false,
        Closing = false,
    }
    DataService.Sessions[player] = session

    if not player.Parent then
        DataService.Release(player)
        return nil
    end

    publish(player, session)
    return profile
end

function DataService.Get(player)
    local session = DataService.Sessions[player]
    return session and session.Profile
end

local function lockSession(player)
    local session = DataService.Sessions[player]
    if not session then
        return nil
    end

    while session.Busy do
        task.wait()
    end

    if DataService.Sessions[player] ~= session or session.Released then
        return nil
    end

    session.Busy = true
    return session
end

local function finishSessionOperation(player, session, profile, releasing)
    if profile then
        session.Profile = profile
        if releasing then
            session.Released = true
        elseif player.Parent then
            publish(player, session)
        end
    end
    session.Busy = false
    return profile
end

function DataService.Update(player, operation, matchId, won, opponentRating, metadata)
    local session = lockSession(player)
    if not session then
        return nil
    end

    local profile = retry(function()
        return repository:Update(
            player.UserId,
            session.Token,
            operation,
            matchId,
            won,
            opponentRating,
            metadata
        )
    end)

    return finishSessionOperation(player, session, profile, operation == "Release")
end

function DataService.Mutate(player, operation, payload)
    local session = lockSession(player)
    if not session then
        return nil
    end

    local profile = retry(function()
        return repository:Mutate(player.UserId, session.Token, operation, payload)
    end)

    return finishSessionOperation(player, session, profile, false)
end

function DataService.Release(player)
    local session = DataService.Sessions[player]
    if not session or session.Closing then
        return
    end

    session.Closing = true
    DataService.Update(player, "Release")
    DataService.Sessions[player] = nil
end

return DataService
