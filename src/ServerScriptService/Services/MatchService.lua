local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Rules = require(script.Parent.Parent.Core.Rules)
local Protocol = require(script.Parent.Parent.Core.Protocol)
local GuardDefinitions = require(script.Parent.Parent.Core.GuardDefinitions)
local Adapter = require(script.Parent.Parent.AI.Adapter)
local TelemetryService = require(script.Parent.TelemetryService)

local MatchService = {
    Matches = {},
    Slots = {},
    LastArena = {},
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
    requirements = "What would convince you to let me through?",
    permit = "I am an authorised royal courier. I can explain my credentials.",
    verify = "Ask me for a detail you can use to verify my story.",
    escort = "Escort me personally if you still doubt me.",
    flattery = "A guard with your reputation can judge this fairly.",
    authority = "The palace is expecting this delivery; question me if you doubt it.",
    urgency = "Every minute this waits creates a problem inside.",
    joke = "If I were smuggling something, I'd have picked a smaller box.",
}

local function suggestionsFor(match)
    local state = match.State
    local ids

    if not state.PermitPresented then
        ids = match.Guard.Id == "brann"
            and { "requirements", "permit", "flattery" }
            or { "requirements", "permit", "authority" }
    elseif not state.SealVerified then
        ids = { "verify", "authority", match.Guard.Id == "elowen" and "escort" or "flattery" }
    elseif match.Guard.RequiresEscort and not state.EscortOffered then
        ids = { "escort", "authority", "urgency" }
    elseif match.Guard.Id == "brann" then
        ids = { "flattery", "authority", "joke" }
    elseif match.Guard.Id == "elowen" then
        ids = { "escort", "verify", "requirements" }
    else
        ids = { "authority", "escort", "requirements" }
    end

    local result = {}
    for _, id in ipairs(ids) do
        table.insert(result, {
            Id = id,
            Text = suggestionText[id] or choices[id] or id,
        })
    end
    return result
end

local function pushHistory(match, playerMessage, guardMessage)
    table.insert(match.History, {
        Player = playerMessage,
        Guard = guardMessage,
    })

    while #match.History > Config.MaxTurns do
        table.remove(match.History, 1)
    end
end

local function tell(player, message)
    if player.Parent then
        remote:FireClient(player, {
            Kind = "Notice",
            Message = message,
        })
    end
end

local function send(match, message, delta)
    if match.Player.Parent then
        remote:FireClient(match.Player, {
            Kind = "Match",
            MatchId = match.Id,
            ArenaId = match.ArenaId,
            Status = match.State.Status,
            Turns = match.State.Turns,
            Progress = match.State.Trust,
            Trust = match.State.Trust,
            Suspicion = match.State.Suspicion,
            Deadline = match.Deadline,
            Message = message,
            Hint = Rules.Hint(match.State, match.Guard),
            Summary = match.Summary,
            Delta = delta,
            GuardId = match.Guard.Id,
            GuardName = match.Guard.Name,
            GuardTitle = match.Guard.Title,
            GuardRating = match.Guard.Rating,
            AIProvider = Config.AIProvider,
            PlayerMessage = match.LastPlayerMessage,
            Suggestions = suggestionsFor(match),
        })
    end
end

local function show(match, spectatorMessage)
    local remaining = math.max(0, math.ceil(match.Deadline - workspace:GetServerTimeNow()))
    worldService.ShowArena(
        match.ArenaId,
        string.format(
            "@%s vs %s\n%s | Move %d/%d | %ds left\nTrust %d%% | Suspicion %d%%\n%s\nGUARD: %s",
            match.Player.Name,
            string.upper(match.Guard.Name),
            match.State.Status,
            match.State.Turns,
            Config.MaxTurns,
            remaining,
            match.State.Trust,
            match.State.Suspicion,
            match.Summary or "",
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

    local arena = worldService.Arenas[match.ArenaId]
    if arena then
        arena.Prompt.Enabled = true
        worldService.ShowArena(
            match.ArenaId,
            "AVAILABLE\nAI GUARD CHALLENGE\nDifferent guards react to different tactics.\n8 moves | 3 minutes | Ranked",
            false,
            0,
            0,
            "Available"
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

    local profile = dataService.Update(
        match.Player,
        "Finish",
        match.Id,
        won,
        match.Guard.Rating
    )

    match.Saving = false

    if profile then
        MatchService.LastArena[match.Player] = match.ArenaId
        worldService.Record(won)
        worldService.Refresh(dataService)

        TelemetryService.MatchFinished(
            match.Player,
            match.Guard,
            won,
            match.State.Turns,
            workspace:GetServerTimeNow() - match.StartedAt
        )

        send(match, reason, profile.LastMatch.Delta)
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

function MatchService.Start(player, arenaId, trustedRematch)
    if MatchService.Closing or MatchService.Matches[player] then
        return
    end

    local arena = worldService.Arenas[arenaId]
    local profile = dataService.Get(player)
    local character = player.Character
    local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not arena or not profile or not characterRoot or not humanoid or humanoid.Health <= 0 then
        tell(player, "Wait for your profile and character to load.")
        return
    end

    if not trustedRematch and (characterRoot.Position - arena.Console.Position).Magnitude > 16 then
        return
    end

    if MatchService.Slots[arenaId] then
        tell(player, "This arena is busy. Try another console.")
        return
    end

    if lastRequest[player] and os.clock() - lastRequest[player] < Config.RequestCooldown then
        return
    end

    lastRequest[player] = os.clock()

    local guard = GuardDefinitions.Select(profile.Elo, rng:NextNumber())
    local concern = GuardDefinitions.SelectConcern(guard, rng:NextNumber())

    local match = {
        Id = HttpService:GenerateGUID(false),
        Player = player,
        ArenaId = arenaId,
        Guard = guard,
        Concern = concern,
        History = {},
        LastPlayerMessage = nil,
        State = Rules.New(),
        Busy = true,
        Ended = false,
        Deadline = workspace:GetServerTimeNow() + Config.MatchSeconds,
        StartedAt = workspace:GetServerTimeNow(),
    }

    MatchService.Matches[player] = match
    MatchService.Slots[arenaId] = match
    arena.Prompt.Enabled = false

    if worldService.SetGuard then
        worldService.SetGuard(arenaId, guard)
    end

    local saved = dataService.Update(
        player,
        "Begin",
        match.Id,
        nil,
        guard.Rating
    )

    if not saved then
        match.Ended = true
        releaseArena(match)
        player:Kick("Could not safely start a ranked match. Please rejoin shortly.")
        return
    end

    if match.Ended then
        return
    end

    match.Busy = false
    match.Deadline = workspace:GetServerTimeNow() + Config.MatchSeconds
    match.StartedAt = workspace:GetServerTimeNow()

    local intro = string.format(
        "I am %s, %s. You have eight messages. Convince me with words that you have a legitimate reason to pass this gate.",
        guard.Name,
        string.lower(guard.Title)
    )

    if saved.Wins + saved.Losses > 0 then
        intro = string.format(
            "%s. You have %d wins and %d losses against the gate. I will judge this attempt on its own merits.",
            guard.Name,
            saved.Wins,
            saved.Losses
        )
    end

    match.Reply = intro
    match.SpectatorReply = "The Guard is waiting for the first argument."
    match.LastPlayerMessage = nil

    TelemetryService.MatchStarted(player, guard)

    send(match, intro)
    show(match, match.SpectatorReply)
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
        MatchService.Finish(match, false, "Time is up. The Guard wins!")
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

        decision = {
            Intent = payload.Value,
            Strength = "normal",
            Provider = "Quick",
        }
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
                Guard = match.Guard,
                Concern = match.Concern,
                History = match.History,
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
            warn("BEAT_THE_BOT_AI_DEGRADED: generated response was unusable; deterministic classification used for this turn")
        end
    end

    TelemetryService.Move(player, payload.Kind)

    if match.Ended then
        return
    end

    if workspace:GetServerTimeNow() >= match.Deadline then
        MatchService.Finish(match, false, "Time is up. The Guard wins!")
        return
    end

    local nextState, fallbackReply = Rules.Advance(
        match.State,
        decision,
        match.Guard,
        Config.MaxTurns
    )

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
    pushHistory(match, playerMessage, playerReply)
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

    if match then
        if not match.Ended or match.Saving then
            return
        end

        arenaId = match.ArenaId

        if MatchService.Slots[arenaId] == match then
            releaseArena(match)
        end
    else
        arenaId = MatchService.LastArena[player]
    end

    if not arenaId then
        return
    end

    if MatchService.Slots[arenaId] then
        arenaId = nil

        for candidate = 1, Config.ArenaCount do
            if not MatchService.Slots[candidate] then
                arenaId = candidate
                break
            end
        end
    end

    if not arenaId then
        tell(player, "Every arena is busy. Try again in a moment.")
        return
    end

    TelemetryService.Rematch(player)

    lastRequest[player] = nil
    task.defer(MatchService.Start, player, arenaId, true)
end

function MatchService.Forfeit(player)
    local match = MatchService.Matches[player]

    if match then
        MatchService.Finish(match, false, "Match forfeited. The Guard wins!")
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
                        task.spawn(MatchService.Finish, match, false, "Time is up. The Guard wins!")
                    elseif not match.Busy then
                        show(match, match.SpectatorReply or "The Guard is considering the argument.")
                    end
                end
            end
        end
    end)
end

return MatchService