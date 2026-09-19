local ProfileStore = {}
ProfileStore.__index = ProfileStore

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = copy(child)
    end
    return result
end

local function defaultProfile(config)
    return {
        Schema = config.ProfileSchema or 2,
        Elo = config.InitialRating,
        BestElo = config.InitialRating,
        Wins = 0,
        Losses = 0,
        Insight = 0,
        Mastery = {},
        Inventory = { Owned = {} },
        Equipped = {},
        DailyTrial = {
            OfficialDay = nil,
            OfficialMatchId = nil,
            Result = nil,
            Streak = 0,
            LastCompletedDayOrdinal = nil,
            BestResult = nil,
        },
        RewardClaims = {},
    }
end

local function normalize(profile, config)
    profile.Schema = config.ProfileSchema or 2
    profile.Elo = tonumber(profile.Elo) or config.InitialRating
    profile.BestElo = math.max(tonumber(profile.BestElo) or profile.Elo, profile.Elo)
    profile.Wins = math.max(0, tonumber(profile.Wins) or 0)
    profile.Losses = math.max(0, tonumber(profile.Losses) or 0)
    profile.Insight = math.max(0, tonumber(profile.Insight) or 0)
    profile.Mastery = type(profile.Mastery) == "table" and profile.Mastery or {}
    profile.Inventory = type(profile.Inventory) == "table" and profile.Inventory or {}
    profile.Inventory.Owned = type(profile.Inventory.Owned) == "table" and profile.Inventory.Owned or {}
    profile.Equipped = type(profile.Equipped) == "table" and profile.Equipped or {}
    profile.DailyTrial = type(profile.DailyTrial) == "table" and profile.DailyTrial or {}
    profile.DailyTrial.Streak = math.max(0, tonumber(profile.DailyTrial.Streak) or 0)
    profile.RewardClaims = type(profile.RewardClaims) == "table" and profile.RewardClaims or {}
    return profile
end

local function migrate(old, config)
    if old == nil then
        return defaultProfile(config)
    end

    local schema = tonumber(old.Schema)
    local current = config.ProfileSchema or 2
    if schema == current then
        return normalize(copy(old), config)
    end
    if schema == 1 and current == 2 then
        local migrated = copy(old)
        migrated.Schema = 2
        return normalize(migrated, config)
    end
    return nil
end

local function activeInfo(active, defaultRating)
    if type(active) == "table" then
        return active.Id, active.OpponentRating or defaultRating, active.Metadata
    end
    return active, defaultRating, nil
end

local function addItems(profile, items)
    for _, itemId in ipairs(items or {}) do
        if type(itemId) == "string" and itemId ~= "" then
            profile.Inventory.Owned[itemId] = true
        end
    end
end

local function masteryEntry(profile, opponentId)
    local entry = profile.Mastery[opponentId]
    if type(entry) ~= "table" then
        entry = {
            Wins = 0,
            Attempts = 0,
            Losses = 0,
            XP = 0,
            Level = 0,
            BestSuccessfulMessageCount = nil,
        }
        profile.Mastery[opponentId] = entry
    end
    entry.Wins = math.max(0, tonumber(entry.Wins) or 0)
    entry.Attempts = math.max(0, tonumber(entry.Attempts) or 0)
    entry.Losses = math.max(0, tonumber(entry.Losses) or 0)
    entry.XP = math.max(0, tonumber(entry.XP) or 0)
    entry.Level = math.max(0, tonumber(entry.Level) or 0)
    return entry
end

function ProfileStore.HasPlayed(profile)
    if type(profile) ~= "table" then
        return false
    end
    if (tonumber(profile.Wins) or 0) > 0 or (tonumber(profile.Losses) or 0) > 0 then
        return true
    end
    for _, mastery in pairs(type(profile.Mastery) == "table" and profile.Mastery or {}) do
        if type(mastery) == "table" and (tonumber(mastery.Attempts) or 0) > 0 then
            return true
        end
    end
    return type(profile.DailyTrial) == "table" and profile.DailyTrial.Result ~= nil
end

function ProfileStore.new(store, config, rules, clock)
    return setmetatable({ Store = store, Config = config, Rules = rules, Clock = clock }, ProfileStore)
end

function ProfileStore:ApplyResult(profile, matchId, won, opponentRating, metadata)
    metadata = type(metadata) == "table" and metadata or {}
    local ranked = metadata.Ranked ~= false
    local delta = 0

    if ranked then
        local nextRating
        nextRating, delta = self.Rules.Rating(profile.Elo, opponentRating, won, self.Config.RatingK)
        profile.Elo = nextRating
        profile.Wins += won and 1 or 0
        profile.Losses += won and 0 or 1
        profile.BestElo = math.max(profile.BestElo, nextRating)
    end

    profile.LastMatch = {
        Id = matchId,
        Won = won,
        Delta = delta,
        OpponentRating = opponentRating,
        OpponentId = metadata.OpponentId,
        Mode = metadata.Mode or (ranked and "Ranked" or "Practice"),
    }

    local matchClaim = "match:" .. tostring(matchId)
    if not profile.RewardClaims[matchClaim] then
        profile.RewardClaims[matchClaim] = true
        local reward = type(metadata.Reward) == "table" and metadata.Reward or {}

        profile.Insight += math.max(0, math.floor(tonumber(reward.Insight) or 0))

        if won and type(reward.FirstWinDayKey) == "string" then
            local firstWinClaim = "firstwin:" .. reward.FirstWinDayKey
            if not profile.RewardClaims[firstWinClaim] then
                profile.RewardClaims[firstWinClaim] = true
                profile.Insight += math.max(0, math.floor(tonumber(reward.FirstWinBonus) or 0))
            end
        end

        if type(metadata.OpponentId) == "string" and metadata.OpponentId ~= "" then
            local mastery = masteryEntry(profile, metadata.OpponentId)
            mastery.Attempts += 1
            mastery.Wins += won and 1 or 0
            mastery.Losses += won and 0 or 1
            mastery.XP += math.max(0, math.floor(tonumber(reward.MasteryXP) or 0))
            mastery.Level = math.max(mastery.Level, math.max(0, math.floor(tonumber(reward.MasteryLevel) or 0)))

            if won then
                local messages = tonumber(metadata.Messages)
                if messages and messages > 0 then
                    if mastery.BestSuccessfulMessageCount then
                        mastery.BestSuccessfulMessageCount = math.min(mastery.BestSuccessfulMessageCount, messages)
                    else
                        mastery.BestSuccessfulMessageCount = messages
                    end
                end
            end
        end

        addItems(profile, reward.Items)

        if metadata.Mode == "Daily" and type(metadata.DayKey) == "string" then
            local daily = profile.DailyTrial
            local ordinal = tonumber(metadata.DayOrdinal)

            if ordinal and daily.LastCompletedDayOrdinal ~= ordinal then
                if daily.LastCompletedDayOrdinal == ordinal - 1 then
                    daily.Streak += 1
                else
                    daily.Streak = 1
                end
                daily.LastCompletedDayOrdinal = ordinal
            end

            daily.Result = {
                DayKey = metadata.DayKey,
                Won = won,
                Messages = tonumber(metadata.Messages) or 0,
                CompletionTime = tonumber(metadata.CompletionTime) or 0,
                FinalTrust = tonumber(metadata.FinalTrust) or 0,
                FinalSuspicion = tonumber(metadata.FinalSuspicion) or 0,
                OpponentId = metadata.OpponentId,
            }

            if won then
                local best = daily.BestResult
                local candidateMessages = daily.Result.Messages
                local candidateTime = daily.Result.CompletionTime
                if not best
                    or candidateMessages < (best.Messages or math.huge)
                    or (candidateMessages == best.Messages and candidateTime < (best.CompletionTime or math.huge))
                then
                    daily.BestResult = copy(daily.Result)
                end
            end

            local streakReward = metadata.StreakRewards and metadata.StreakRewards[daily.Streak]
            local streakClaim = "streak:" .. tostring(daily.Streak)
            if streakReward and not profile.RewardClaims[streakClaim] then
                profile.RewardClaims[streakClaim] = true
                profile.Insight += math.max(0, math.floor(tonumber(streakReward.Insight) or 0))
                if streakReward.Item then
                    addItems(profile, { streakReward.Item })
                end
            end
        end
    end

    profile.ActiveMatch = nil
end

function ProfileStore:Acquire(userId, token)
    return self.Store:UpdateAsync(tostring(userId), function(old)
        local now = self.Clock()

        if old then
            local schema = tonumber(old.Schema)
            local current = self.Config.ProfileSchema or 2
            if schema ~= 1 and schema ~= current then
                return nil
            end
            if old.Lock and old.Lock.Token ~= token and old.Lock.Expires > now then
                return nil
            end
        end

        local profile = migrate(old, self.Config)
        if not profile then
            return nil
        end

        if profile.ActiveMatch and (not profile.Lock or profile.Lock.Token ~= token) then
            local id, opponentRating, metadata = activeInfo(profile.ActiveMatch, self.Config.OpponentRating)
            self:ApplyResult(profile, id, false, opponentRating, metadata)
        end

        profile.Lock = { Token = token, Expires = now + self.Config.LeaseSeconds }
        return profile
    end)
end

function ProfileStore:Update(userId, token, operation, matchId, won, opponentRating, metadata)
    return self.Store:UpdateAsync(tostring(userId), function(old)
        local now = self.Clock()
        if not old or not old.Lock or old.Lock.Token ~= token or old.Lock.Expires <= now then
            return nil
        end

        local profile = migrate(old, self.Config)
        if not profile then
            return nil
        end

        local activeId, activeRating, activeMetadata = activeInfo(profile.ActiveMatch, self.Config.OpponentRating)

        if operation == "Begin" then
            if activeId and activeId ~= matchId then
                return nil
            end
            if profile.LastMatch and profile.LastMatch.Id == matchId then
                return nil
            end

            metadata = type(metadata) == "table" and copy(metadata) or {}
            if metadata.Mode == "Daily" then
                if type(metadata.DayKey) ~= "string" or profile.DailyTrial.OfficialDay == metadata.DayKey then
                    return nil
                end
                profile.DailyTrial.OfficialDay = metadata.DayKey
                profile.DailyTrial.OfficialMatchId = matchId
                profile.DailyTrial.Result = nil
            end

            profile.ActiveMatch = {
                Id = matchId,
                OpponentRating = opponentRating or self.Config.OpponentRating,
                Metadata = metadata,
            }
        elseif operation == "Finish" then
            if not profile.LastMatch or profile.LastMatch.Id ~= matchId then
                if activeId ~= matchId then
                    return nil
                end
                self:ApplyResult(profile, matchId, won == true, opponentRating or activeRating, metadata or activeMetadata)
            end
        elseif operation ~= "Renew" and operation ~= "Release" then
            return nil
        end

        profile.Lock = operation ~= "Release"
            and { Token = token, Expires = now + self.Config.LeaseSeconds }
            or nil

        return profile
    end)
end

function ProfileStore:Mutate(userId, token, operation, payload)
    return self.Store:UpdateAsync(tostring(userId), function(old)
        local now = self.Clock()
        if not old or not old.Lock or old.Lock.Token ~= token or old.Lock.Expires <= now then
            return nil
        end

        local profile = migrate(old, self.Config)
        if not profile then
            return nil
        end
        payload = type(payload) == "table" and payload or {}

        if operation == "GrantItems" then
            local claimKey = payload.ClaimKey
            if type(claimKey) ~= "string" or claimKey == "" then
                return nil
            end
            if not profile.RewardClaims[claimKey] then
                profile.RewardClaims[claimKey] = true
                addItems(profile, payload.Items)
            end
        elseif operation == "EquipCosmetic" then
            if type(payload.Id) ~= "string" or type(payload.Category) ~= "string" then
                return nil
            end
            if not profile.Inventory.Owned[payload.Id] then
                return nil
            end
            profile.Equipped[payload.Category] = payload.Id
        elseif operation == "UnequipCosmetic" then
            if type(payload.Category) ~= "string" then
                return nil
            end
            profile.Equipped[payload.Category] = nil
        else
            return nil
        end

        profile.Lock = { Token = token, Expires = now + self.Config.LeaseSeconds }
        return profile
    end)
end

return ProfileStore
