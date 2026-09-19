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

local function activeInfo(active, defaultRating)
    if type(active) == "table" then
        return active.Id, active.OpponentRating or defaultRating
    end
    return active, defaultRating
end

function ProfileStore.new(store, config, rules, clock)
    return setmetatable({ Store = store, Config = config, Rules = rules, Clock = clock }, ProfileStore)
end

function ProfileStore:ApplyResult(profile, matchId, won, opponentRating)
    opponentRating = opponentRating or self.Config.OpponentRating
    local rating, delta = self.Rules.Rating(profile.Elo, opponentRating, won, self.Config.RatingK)
    profile.Elo = rating
    profile.Wins += won and 1 or 0
    profile.Losses += won and 0 or 1
    profile.BestElo = math.max(profile.BestElo, rating)
    profile.LastMatch = {
        Id = matchId,
        Won = won,
        Delta = delta,
        OpponentRating = opponentRating,
    }
    profile.ActiveMatch = nil
end

function ProfileStore:Acquire(userId, token)
    return self.Store:UpdateAsync(tostring(userId), function(old)
        local now = self.Clock()
        if old and (old.Schema ~= 1 or (old.Lock and old.Lock.Token ~= token and old.Lock.Expires > now)) then
            return nil
        end

        local profile = copy(old) or {
            Schema = 1,
            Elo = self.Config.InitialRating,
            BestElo = self.Config.InitialRating,
            Wins = 0,
            Losses = 0,
        }

        if profile.ActiveMatch and (not profile.Lock or profile.Lock.Token ~= token) then
            local id, opponentRating = activeInfo(profile.ActiveMatch, self.Config.OpponentRating)
            self:ApplyResult(profile, id, false, opponentRating)
        end

        profile.Lock = { Token = token, Expires = now + self.Config.LeaseSeconds }
        return profile
    end)
end

function ProfileStore:Update(userId, token, operation, matchId, won, opponentRating)
    return self.Store:UpdateAsync(tostring(userId), function(old)
        local now = self.Clock()
        if not old or not old.Lock or old.Lock.Token ~= token or old.Lock.Expires <= now then
            return nil
        end

        local profile = copy(old)
        local activeId, activeRating = activeInfo(profile.ActiveMatch, self.Config.OpponentRating)

        if operation == "Begin" then
            if activeId and activeId ~= matchId then
                return nil
            end
            if profile.LastMatch and profile.LastMatch.Id == matchId then
                return nil
            end
            profile.ActiveMatch = {
                Id = matchId,
                OpponentRating = opponentRating or self.Config.OpponentRating,
            }
        elseif operation == "Finish" then
            if not profile.LastMatch or profile.LastMatch.Id ~= matchId then
                if activeId ~= matchId then
                    return nil
                end
                self:ApplyResult(profile, matchId, won, opponentRating or activeRating)
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

return ProfileStore