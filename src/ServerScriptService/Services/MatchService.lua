local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Rules = require(script.Parent.Parent.Core.Rules)
local Protocol = require(script.Parent.Parent.Core.Protocol)
local Adapter = require(script.Parent.Parent.AI.Adapter)
local MatchService = { Matches = {}, Slots = {}, Closing = false }
local dataService
local worldService
local remote
local lastRequest = {}
local choices = {}
for _, choice in ipairs(Config.Choices) do
    choices[choice.Id] = choice.Text
end

local function tell(player, message)
    if player.Parent then
        remote:FireClient(player, { Kind = "Notice", Message = message })
    end
end

local function send(match, message, delta)
    if match.Player.Parent then
        remote:FireClient(match.Player, {
            Kind = "Match", MatchId = match.Id, ArenaId = match.ArenaId,
            Status = match.State.Status, Turns = match.State.Turns,
            Progress = match.State.Progress * 25, Suspicion = match.State.Suspicion,
            Deadline = match.Deadline, Message = message, Hint = Rules.Hint(match.State),
            Summary = match.Summary, Delta = delta,
        })
    end
end

local function show(match, message)
    local remaining = math.max(0, math.ceil(match.Deadline - workspace:GetServerTimeNow()))
    worldService.ShowArena(match.ArenaId, string.format(
        "@%s vs THE GUARD\n%s | Move %d/8 | %ds left\nTrust %d%% | Suspicion %d%%\n%s\nGUARD: %s",
        match.Player.Name, match.State.Status, match.State.Turns, remaining,
        match.State.Progress * 25, match.State.Suspicion, match.Summary or "", message
    ), match.State.Status == "Won")
end

local function releaseArena(match)
    if MatchService.Slots[match.ArenaId] ~= match then
        return
    end
    MatchService.Slots[match.ArenaId] = nil
    if MatchService.Matches[match.Player] == match then
        MatchService.Matches[match.Player] = nil
    end
    worldService.Arenas[match.ArenaId].Prompt.Enabled = true
    worldService.ShowArena(match.ArenaId, "AVAILABLE\nTHE CASTLE GUARD | 1,000 ELO\nDeliver your parcel through the gate.\n8 moves | Walk to the console")
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
    send(match, "Saving result...")
    local profile = dataService.Update(match.Player, "Finish", match.Id, won)
    match.Saving = false
    if profile then
        worldService.Record(won)
        worldService.Refresh(dataService)
        send(match, reason, profile.LastMatch.Delta)
    else
        send(match, "Result could not be confirmed. Rejoin shortly; an unfinished match may count as a loss.")
        if match.Player.Parent then
            match.Player:Kick("Result save unavailable. Please rejoin shortly. Unfinished matches count as losses.")
        end
    end
    task.delay(5, function()
        releaseArena(match)
    end)
end

function MatchService.Start(player, arenaId)
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
    if (characterRoot.Position - arena.Console.Position).Magnitude > 16 then
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
    local match = {
        Id = HttpService:GenerateGUID(false), Player = player, ArenaId = arenaId,
        State = Rules.New(), Busy = true, Ended = false,
        Deadline = workspace:GetServerTimeNow() + Config.MatchSeconds,
    }
    MatchService.Matches[player] = match
    MatchService.Slots[arenaId] = match
    arena.Prompt.Enabled = false
    local saved = dataService.Update(player, "Begin", match.Id)
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
    local intro = "You are a courier with a sealed delivery permit. Convince me to let you through. Ask about my rules first."
    if saved.Wins + saved.Losses > 0 then
        intro = string.format("Welcome back! You have %d wins against me; I have %d. The same entry rules still apply.", saved.Wins, saved.Losses)
    end
    match.Reply = intro
    send(match, intro)
    show(match, intro)
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
    local intent
    if payload.Kind == "Choice" then
        if not choices[payload.Value] then
            match.Busy = false
            tell(player, "Choose one of the available moves.")
            return
        end
        intent = payload.Value
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
            tell(player, "That message could not be processed safely. Try a different message or a quick move; no turn was used.")
            return
        end
        local success, result = pcall(function()
            local profile = dataService.Get(player)
            return Adapter.Decide({
                Message = filtered,
                State = table.freeze(table.clone(match.State)),
                Memory = table.freeze({ Wins = profile.Wins, Losses = profile.Losses }),
            })
        end)
        if match.Ended then
            return
        end
        if not success then
            match.Busy = false
            tell(player, "The opponent could not respond. Try a quick move; no turn was used.")
            return
        end
        intent = result
    end
    if match.Ended then
        return
    end
    if workspace:GetServerTimeNow() >= match.Deadline then
        MatchService.Finish(match, false, "Time is up. The Guard wins!")
        return
    end
    local state, reply = Rules.Advance(match.State, intent, Config.MaxTurns)
    if not state then
        match.Busy = false
        tell(player, "The opponent returned an invalid move. No turn was used.")
        return
    end
    match.State = state
    match.Reply = reply
    match.Summary = Rules.Summaries[intent]
    match.Busy = false
    if state.Status ~= "Playing" then
        MatchService.Finish(match, state.Status == "Won", reply)
    else
        send(match, reply)
        show(match, reply)
    end
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
end

function MatchService.Init(data, world, stateRemote, submitRemote)
    dataService, worldService, remote = data, world, stateRemote
    submitRemote.OnServerEvent:Connect(MatchService.Submit)
    task.spawn(function()
        while true do
            task.wait(1)
            for _, match in pairs(MatchService.Matches) do
                if not match.Ended then
                    if workspace:GetServerTimeNow() >= match.Deadline then
                        task.spawn(MatchService.Finish, match, false, "Time is up. The Guard wins!")
                    elseif not match.Busy then
                        show(match, match.Reply or "Preparing the match...")
                    end
                end
            end
        end
    end)
end

return MatchService
