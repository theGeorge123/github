local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Rules = require(script.Parent.Parent.Core.Rules)
local Protocol = require(script.Parent.Parent.Core.Protocol)
local OpponentDefinitions = require(script.Parent.Parent.Core.OpponentDefinitions)
local DistrictDefinitions = require(script.Parent.Parent.Core.DistrictDefinitions)
local History = require(script.Parent.Parent.Core.History)
local ProfileStore = require(script.Parent.Parent.Core.ProfileStore)
local Adapter = require(script.Parent.Parent.AI.Adapter)
local TelemetryService = require(script.Parent.TelemetryService)
local ProgressionService = require(script.Parent.ProgressionService)
local DailyTrialService = require(script.Parent.DailyTrialService)
local RewardService = require(script.Parent.RewardService)
local EntitlementService = require(script.Parent.EntitlementService)

local MatchService = {
    Matches = {},
    Slots = {},
    LastArena = {},
    LastOpponent = {},
    Closing = false,
}

local dataService
local worldService
local remote
local lastRequest = {}
local choices = {}
local rng = Random.new()

for _, choice in ipairs(Config.Choices) do
    choices[choice.Id] = choice.Text
end

local suggestionText = {
    requirements = "What standard do I actually need to satisfy?",
    permit = "Let me explain exactly what authorizes my request.",
    verify = "I can give you a detail you can verify.",
    escort = "Use a supervised option if you still doubt me.",
    flattery = "Your judgment is why I would rather explain this to you.",
    authority = "There is credible authority behind this request; test the details.",
    urgency = "The delay has a concrete cost, and here is why.",
    joke = "Try a little humor without dodging the question.",
    bribe = "Offer something improper.",
    threat = "Try intimidation.",
}

local function suggestionsFor(match)
    local result = {}
    local used = match.State.Used or {}
    local objective = match.Opponent.Objective
    local preferred = objective and objective.SuggestedTactics or {}

    for _, id in ipairs(preferred) do
        if #result >= 2 then
            break
        end
        if not used[id] and suggestionText[id] then
            table.insert(result, { Id = id, Text = suggestionText[id] })
        end
    end

    if #result < 2 then
        for _, choice in ipairs(Config.Choices) do
            if #result >= 2 then
                break
            end
            local duplicate = false
            for _, existing in ipairs(result) do
                duplicate = duplicate or existing.Id == choice.Id
            end
            if not duplicate and choice.Id ~= "bribe" and choice.Id ~= "threat" then
                table.insert(result, { Id = choice.Id, Text = suggestionText[choice.Id] or choice.Text })
            end
        end
    end

    return result
end

local function arenaFor(arenaId)
    if arenaId == "daily" then
        return worldService.DailyArena
    end
    return worldService.Arenas[arenaId]
end

local function tell(player, message)
    if player.Parent then
        remote:FireClient(player, { Kind = "Notice", Message = message })
    end
end

local function currentMastery(profile, opponentId)
    local entry = profile and profile.Mastery and profile.Mastery[opponentId]
    return {
        Level = entry and entry.Level or 0,
        XP = entry and entry.XP or 0,
        Wins = entry and entry.Wins or 0,
        Attempts = entry and entry.Attempts or 0,
        BestSuccessfulMessageCount = entry and entry.BestSuccessfulMessageCount or nil,
    }
end

local function send(match, message, delta)
    if not match.Player.Parent then
        return
    end

    local profile = dataService.Get(match.Player)
    local nextPlayable = profile and ProgressionService.NextPlayable(profile) or nil
    remote:FireClient(match.Player, {
        Kind = "Match",
        MatchId = match.Id,
        ArenaId = match.ArenaId,
        DistrictId = match.DistrictId,
        Mode = match.Mode,
        OfficialDaily = match.Mode == "Daily",
        Status = match.State.Status,
        Turns = match.State.Turns,
        Progress = match.State.Trust,
        Trust = match.State.Trust,
        Suspicion = match.State.Suspicion,
        Deadline = match.Deadline,
        Message = message,
        Hint = Rules.Hint(match.State, match.Opponent),
        Summary = match.Summary,
        Delta = delta,
        OpponentId = match.Opponent.Id,
        OpponentName = match.Opponent.Name,
        OpponentTitle = match.Opponent.Title,
        OpponentRating = match.Opponent.Rating,
        OpponentAccent = match.Opponent.Visual and match.Opponent.Visual.Accent or "Cyan",
        OpponentArchetype = match.Opponent.Visual and match.Opponent.Visual.Archetype or "Opponent",
        GuardId = match.Opponent.Id,
        GuardName = match.Opponent.Name,
        GuardTitle = match.Opponent.Title,
        GuardRating = match.Opponent.Rating,
        Objective = match.Objective,
        Scenario = match.Scenario,
        AIProvider = Config.AIProvider,
        PlayerMessage = match.LastPlayerMessage,
        Suggestions = suggestionsFor(match),
        Mastery = currentMastery(profile, match.Opponent.Id),
        Rank = profile and ProgressionService.Rank(profile).Name or "Outsider",
        Insight = profile and profile.Insight or 0,
        DailyStreak = profile and profile.DailyTrial and profile.DailyTrial.Streak or 0,
        NextUnlockName = nextPlayable and nextPlayable.Name or nil,
        NextUnlockElo = nextPlayable and nextPlayable.UnlockElo or nil,
        NextUnlockRemaining = nextPlayable and nextPlayable.RemainingElo or nil,
        RewardInsight = match.RewardOutcome and match.RewardOutcome.Insight or nil,
        RewardMasteryXP = match.RewardOutcome and match.RewardOutcome.MasteryXP or nil,
        RewardMasteryLevel = match.RewardOutcome and match.RewardOutcome.MasteryLevel or nil,
        RewardItems = match.RewardOutcome and match.RewardOutcome.Items or nil,
    })
end

local function show(match, spectatorMessage)
    local remaining = math.max(0, math.ceil(match.Deadline - workspace:GetServerTimeNow()))
    worldService.ShowArena(
        match.ArenaId,
        string.format(
            "@%s vs %s\n%s | %s | Move %d/%d | %ds\nTrust %d%% | Suspicion %d%%\n%s\nOPPONENT: %s",
            match.Player.Name,
            string.upper(match.Opponent.Name),
            match.Mode,
            match.State.Status,
            match.State.Turns,
            Config.MaxTurns,
            remaining,
            match.State.Trust,
            match.State.Suspicion,
            match.Summary or "Conversation in progress.",
            spectatorMessage
        ),
        match.State.Status == "Won",
        match.State.Trust,
        match.State.Suspicion,
        match.State.Status
    )
end

local function releaseArena(match)
    if MatchService.Slots[match.ArenaId] ~= match then
        return
    end

    MatchService.Slots[match.ArenaId] = nil
    if MatchService.Matches[match.Player] == match then
        MatchService.Matches[match.Player] = nil
    end

    local arena = arenaFor(match.ArenaId)
    if arena and arena.Prompt then
        arena.Prompt.Enabled = true
    end

    if match.ArenaId == "daily" then
        worldService.ShowArena("daily", "DAILY TRIAL\nOne official scored attempt each UTC day.\nPractice remains available afterward.", false, 0, 0, "Available")
    else
        local district = DistrictDefinitions.ForArena(match.ArenaId)
        worldService.ShowArena(
            match.ArenaId,
            string.format("AVAILABLE\n%s\n8 turns | Ranked\nServer-enforced ELO gate: %d", district.Name, district.UnlockElo),
            false, 0, 0, "Available"
        )
    end
end

local function filterGeneratedReply(player, reply)
    if type(reply) ~= "string" or reply == "" then
        return nil
    end

    local ok, filtered = pcall(function()
        local result = TextService:FilterStringAsync(reply, player.UserId)
        return result:GetNonChatStringForUserAsync(player.UserId)
    end)

    if not ok or not filtered or filtered == "" or string.find(filtered, "#", 1, true) then
        return nil
    end
    return filtered
end

local function startMatch(player, arenaId, mode, opponent, plan, trustedRematch)
    if MatchService.Closing or MatchService.Matches[player] then
        return
    end

    local arena = arenaFor(arenaId)
    local profile = dataService.Get(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not arena or not profile or not root or not humanoid or humanoid.Health <= 0 then
        tell(player, "Wait for your profile and character to load.")
        return
    end

    local districtId = arena.DistrictId or "central_plaza"

    if mode == "Ranked" and not ProgressionService.CanAccess(profile, districtId, player) then
        local district = DistrictDefinitions.Get(districtId)
        tell(player, string.format("%s unlocks at %d ELO.", district.Name, district.UnlockElo))
        return
    end

    if mode == "Ranked" and not trustedRematch and (root.Position - arena.Console.Position).Magnitude > 16 then
        return
    end

    if MatchService.Slots[arenaId] then
        tell(player, "That challenge space is busy. Try another.")
        return
    end

    if lastRequest[player] and os.clock() - lastRequest[player] < Config.RequestCooldown then
        return
    end
    lastRequest[player] = os.clock()

    if not opponent then
        local eligible = OpponentDefinitions.Eligible(profile.Elo, districtId)
        if #eligible == 0 then
            tell(player, "No ranked opponent is available for your current progression.")
            return
        end
        opponent = OpponentDefinitions.Select(profile.Elo, rng:NextNumber(), districtId, MatchService.LastOpponent[player])
    end

    local concern = OpponentDefinitions.SelectConcern(opponent, rng:NextNumber())
    local match = {
        Id = HttpService:GenerateGUID(false),
        Player = player,
        ArenaId = arenaId,
        DistrictId = districtId,
        Opponent = opponent,
        Guard = opponent,
        Concern = concern,
        History = {},
        LastPlayerMessage = nil,
        State = Rules.New(),
        Busy = true,
        Ended = false,
        Mode = mode,
        DayKey = plan and plan.DayKey or nil,
        DayOrdinal = plan and plan.DayOrdinal or nil,
        Scenario = plan and plan.Scenario or nil,
        Objective = plan and plan.Objective or (opponent.Objective and opponent.Objective.Description),
        Deadline = workspace:GetServerTimeNow() + Config.MatchSeconds,
        StartedAt = workspace:GetServerTimeNow(),
    }

    MatchService.Matches[player] = match
    MatchService.LastOpponent[player] = opponent.Id
    MatchService.Slots[arenaId] = match
    if arena.Prompt then
        arena.Prompt.Enabled = false
    end
    if worldService.SetGuard then
        worldService.SetGuard(arenaId, opponent)
    end

    local beginMetadata = {
        Ranked = mode == "Ranked",
        Mode = mode,
        OpponentId = opponent.Id,
        DayKey = match.DayKey,
        DayOrdinal = match.DayOrdinal,
    }

    local saved = dataService.Update(player, "Begin", match.Id, nil, opponent.Rating, beginMetadata)
    if not saved then
        match.Ended = true
        releaseArena(match)
        if mode == "Daily" or mode == "DailyPractice" then
            tell(player, "Daily Trial state changed. Try the landmark again.")
        elseif player.Parent then
            player:Kick("Could not safely start a ranked match. Please rejoin shortly.")
        end
        return
    end

    match.Busy = false
    match.Deadline = workspace:GetServerTimeNow() + Config.MatchSeconds
    match.StartedAt = workspace:GetServerTimeNow()

    local intro
    if mode == "Daily" then
        intro = string.format(
            "Official Daily Trial: %s. %s You have eight turns.",
            match.Scenario or "Today's challenge",
            match.Objective or "Make a coherent case."
        )
    elseif mode == "DailyPractice" then
        intro = string.format(
            "Daily practice only: today's official score is already locked. %s",
            match.Objective or "Practice the scenario."
        )
    else
        intro = string.format(
            "I am %s, %s of the %s. You have eight turns. %s",
            opponent.Name,
            string.lower(opponent.Title),
            DistrictDefinitions.Get(opponent.District).Name,
            opponent.Objective.Description
        )
    end

    match.Reply = intro
    match.SpectatorReply = "The opponent is waiting for the first argument."
    TelemetryService.MatchStarted(player, opponent, not ProfileStore.HasPlayed(profile))
    send(match, intro)
    show(match, match.SpectatorReply)
end

function MatchService.Start(player, arenaId, trustedRematch)
    local profile = dataService.Get(player)
    local district = DistrictDefinitions.ForArena(arenaId)
    if not profile or not district then
        tell(player, "Wait for your profile to load.")
        return
    end
    if not ProgressionService.CanAccess(profile, district.Id, player) then
        tell(player, string.format("%s unlocks at %d ELO.", district.Name, district.UnlockElo))
        return
    end
    startMatch(player, arenaId, "Ranked", nil, nil, trustedRematch == true)
end

function MatchService.StartDaily(player)
    if MatchService.Matches[player] then
        return
    end
    local profile = dataService.Get(player)
    if not profile then
        tell(player, "Wait for your profile to load.")
        return
    end

    local plan = DailyTrialService.Plan(profile)
    local opponent = OpponentDefinitions.Get(plan.OpponentId)
    if not opponent then
        tell(player, "Today's Daily Trial configuration is unavailable.")
        return
    end

    startMatch(player, "daily", plan.Mode, opponent, plan, true)
end

function MatchService.Finish(match, won, reason)
    if match.Ended then
        while match.Saving do
            task.wait()
        end
        return
    end

    match.Ended = true
    match.Saving = true
    match.State.Status = won and "Won" or "Lost"
    show(match, reason)
    match.Reply = reason
    send(match, reason)

    local before = dataService.Get(match.Player)
    local metadata = RewardService.BuildMetadata(
        before,
        match,
        won,
        EntitlementService.IsVIP(match.Player)
    )

    local profile = dataService.Update(
        match.Player,
        "Finish",
        match.Id,
        won,
        match.Opponent.Rating,
        metadata
    )

    match.Saving = false

    if profile then
        local beforeMastery = before and before.Mastery and before.Mastery[match.Opponent.Id] or nil
        local afterMastery = profile.Mastery and profile.Mastery[match.Opponent.Id] or nil
        local newItems = {}
        for _, itemId in ipairs(metadata.Reward and metadata.Reward.Items or {}) do
            local ownedBefore = before and before.Inventory and before.Inventory.Owned and before.Inventory.Owned[itemId]
            local ownedAfter = profile.Inventory and profile.Inventory.Owned and profile.Inventory.Owned[itemId]
            if not ownedBefore and ownedAfter then
                table.insert(newItems, itemId)
            end
        end
        match.RewardOutcome = {
            Insight = math.max(0, (profile.Insight or 0) - (before and before.Insight or 0)),
            MasteryXP = math.max(0, (afterMastery and afterMastery.XP or 0) - (beforeMastery and beforeMastery.XP or 0)),
            MasteryLevel = afterMastery and afterMastery.Level or 0,
            Items = newItems,
        }
        MatchService.LastArena[match.Player] = match.ArenaId
        if match.Mode == "Ranked" then
            worldService.Record(won)
        end
        worldService.Refresh(dataService)

        TelemetryService.MatchFinished(
            match.Player,
            match.Opponent,
            won,
            match.State.Turns,
            workspace:GetServerTimeNow() - match.StartedAt
        )

        local delta = profile.LastMatch and profile.LastMatch.Delta or 0
        send(match, reason, delta)
    else
        send(match, "Result could not be confirmed. Rejoin shortly; an unfinished match may count as a loss.")
        if match.Player.Parent then
            match.Player:Kick("Result save unavailable. Please rejoin shortly. Unfinished matches count as losses.")
        end
    end

    task.delay(Config.ArenaResetSeconds, function()
        releaseArena(match)
    end)
end

function MatchService.Submit(player, payload)
    local match = MatchService.Matches[player]
    if not match or match.Ended or match.Busy then
        return
    end
    if not Protocol.Validate(payload, match, Config.MaxMessageBytes) then
        return
    end
    if os.clock() - (lastRequest[player] or 0) < Config.RequestCooldown then
        tell(player, "Wait a moment before your next move.")
        return
    end
    lastRequest[player] = os.clock()

    if workspace:GetServerTimeNow() >= match.Deadline then
        MatchService.Finish(match, false, "Time is up. The opponent wins.")
        return
    end

    match.Busy = true
    local decision
    local playerMessage

    if payload.Kind == "Choice" then
        if not choices[payload.Value] then
            match.Busy = false
            tell(player, "Choose one of the available moves.")
            return
        end
        playerMessage = suggestionText[payload.Value] or choices[payload.Value]
        decision = { Intent = payload.Value, Strength = "normal", Provider = "Quick" }
    else
        local ok, filtered = pcall(function()
            local result = TextService:FilterStringAsync(payload.Value, player.UserId)
            return result:GetNonChatStringForUserAsync(player.UserId)
        end)

        if match.Ended then
            return
        end
        if not ok or filtered == "" or string.find(filtered, "#", 1, true) then
            match.Busy = false
            tell(player, "That message could not be processed safely. Try different wording; no turn was used.")
            return
        end

        playerMessage = filtered
        local success, result = pcall(function()
            return Adapter.Decide({
                Message = filtered,
                State = table.freeze(table.clone(match.State)),
                Guard = match.Opponent,
                Opponent = match.Opponent,
                Concern = match.Concern,
                History = match.History,
                Scenario = match.Scenario,
                Objective = match.Objective,
            })
        end)

        if match.Ended then
            return
        end
        if not success then
            match.Busy = false
            TelemetryService.AIError(player)
            warn("BEAT_THE_BOT_AI_ERROR:", result)
            tell(player, "The AI could not answer that turn. No move was used; try again or use a quick move.")
            return
        end

        decision = result
        if decision.Degraded then
            TelemetryService.AIError(player)
            warn("BEAT_THE_BOT_AI_DEGRADED: deterministic classification used for this turn")
        end
    end

    TelemetryService.Move(player, payload.Kind)

    if match.Ended then
        return
    end
    if workspace:GetServerTimeNow() >= match.Deadline then
        MatchService.Finish(match, false, "Time is up. The opponent wins.")
        return
    end

    local nextState, fallbackReply = Rules.Advance(match.State, decision, match.Opponent, Config.MaxTurns)
    if not nextState then
        match.Busy = false
        tell(player, "The opponent returned an invalid move. No turn was used.")
        return
    end

    match.State = nextState
    match.Summary = Rules.Summaries[decision.Intent]
    match.LastPlayerMessage = playerMessage
    match.SpectatorReply = fallbackReply

    local playerReply = fallbackReply
    if nextState.Status == "Playing" and decision.Provider == "Roblox" then
        playerReply = filterGeneratedReply(player, decision.Reply) or fallbackReply
    end

    match.Reply = playerReply
    History.Push(match.History, playerMessage, playerReply, Config.MaxTurns)
    match.Busy = false

    if nextState.Status ~= "Playing" then
        MatchService.Finish(match, nextState.Status == "Won", fallbackReply)
    else
        send(match, playerReply)
        show(match, fallbackReply)
    end
end

function MatchService.RequestRematch(player)
    local match = MatchService.Matches[player]
    local arenaId
    local previousMode

    if match then
        if not match.Ended or match.Saving then
            return
        end
        arenaId = match.ArenaId
        previousMode = match.Mode
        if MatchService.Slots[arenaId] == match then
            releaseArena(match)
        end
    else
        arenaId = MatchService.LastArena[player]
    end

    TelemetryService.Rematch(player)
    lastRequest[player] = nil

    if previousMode == "Daily" or previousMode == "DailyPractice" or arenaId == "daily" then
        task.defer(MatchService.StartDaily, player)
        return
    end

    if not arenaId then
        return
    end

    if MatchService.Slots[arenaId] then
        arenaId = nil
        local profile = dataService.Get(player)
        for candidate = 1, Config.ArenaCount do
            local district = DistrictDefinitions.ForArena(candidate)
            if not MatchService.Slots[candidate]
                and district
                and ProgressionService.CanAccess(profile, district.Id, player)
            then
                arenaId = candidate
                break
            end
        end
    end

    if not arenaId then
        tell(player, "Every unlocked arena is busy. Try again in a moment.")
        return
    end

    task.defer(MatchService.Start, player, arenaId, true)
end

function MatchService.Forfeit(player)
    local match = MatchService.Matches[player]
    if match then
        MatchService.Finish(match, false, "Match forfeited. The opponent wins.")
    end
end

function MatchService.Leave(player)
    MatchService.Forfeit(player)
    local match = MatchService.Matches[player]
    if match then
        releaseArena(match)
    end
    lastRequest[player] = nil
    MatchService.LastArena[player] = nil
    MatchService.LastOpponent[player] = nil
end

function MatchService.Init(data, world, stateRemote, submitRemote, rematchRemote)
    dataService = data
    worldService = world
    remote = stateRemote

    submitRemote.OnServerEvent:Connect(MatchService.Submit)
    rematchRemote.OnServerEvent:Connect(MatchService.RequestRematch)

    task.spawn(function()
        while true do
            task.wait(1)
            for _, match in pairs(MatchService.Matches) do
                if not match.Ended then
                    if workspace:GetServerTimeNow() >= match.Deadline then
                        task.spawn(MatchService.Finish, match, false, "Time is up. The opponent wins.")
                    elseif not match.Busy then
                        show(match, match.SpectatorReply or "The opponent is considering the argument.")
                    end
                end
            end
        end
    end)
end

return MatchService
