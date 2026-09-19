local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config)

assert(RunService:IsStudio() and not Config.StudioPersistence, "Smoke tests require Studio session-only mode")

local services = game:GetService("ServerScriptService").Services
local core = game:GetService("ServerScriptService").Core
local DataService = require(services.DataService)
local MatchService = require(services.MatchService)
local WorldService = require(services.WorldService)
local Rules = require(core.Rules)

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local deadline = os.clock() + 30

while not player:GetAttribute("ProfileReady") and os.clock() < deadline do
    task.wait(0.1)
end

assert(player:GetAttribute("ProfileReady"), "Profile failed to load")
assert(#WorldService.Arenas > 0, "No arenas were built")

local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
character:PivotTo(CFrame.new(WorldService.Arenas[1].Console.Position + Vector3.new(0, 3, 4)))

MatchService.Start(player, 1)

local match = MatchService.Matches[player]
assert(match and not match.Ended, "Match did not start")
assert(match.Guard and match.Guard.Id, "No guard was selected")
assert(match.Concern and match.Concern.Id, "No hidden concern was selected")
assert(match.History and #match.History == 0, "Match history should start empty")
assert(DataService.Get(player).ActiveMatch.Id == match.Id, "Active marker missing")

MatchService.Submit(player, {
    MatchId = "forged",
    Turn = 1,
    Kind = "Choice",
    Value = "escort",
})
assert(match.State.Turns == 0, "Forged submission accepted")

local sequences = {
    aldric = { "requirements", "permit", "verify", "escort" },
    brann = { "requirements", "permit", "verify", "flattery", "authority" },
    elowen = { "requirements", "permit", "verify", "escort" },
}

for _, intent in ipairs(sequences[match.Guard.Id]) do
    task.wait(1.1)
    MatchService.Submit(player, {
        MatchId = match.Id,
        Turn = match.State.Turns + 1,
        Kind = "Choice",
        Value = intent,
    })
end

assert(match.Ended and match.State.Status == "Won", "Guard-specific quick path did not win")
assert(#match.History <= 3, "Private match history exceeded its three-turn bound")
assert(match.LastPlayerMessage ~= nil, "Private player display message missing")

local expectedElo = Rules.Rating(1000, match.Guard.Rating, true, Config.RatingK)
local profile = DataService.Get(player)

assert(profile.Wins == 1 and profile.Losses == 0, "Incorrect saved victory")
assert(profile.Elo == expectedElo, "Dynamic opponent Elo was not applied")
assert(profile.LastMatch.OpponentRating == match.Guard.Rating, "Opponent rating was not stored")

MatchService.Finish(match, true, "duplicate")
assert(DataService.Get(player).Wins == 1, "Duplicate reward")
assert(WorldService.HumanWins == 1 and WorldService.BotWins == 0, "Server totals wrong")

task.wait(Config.ArenaResetSeconds + 0.2)
assert(MatchService.Matches[player] == nil, "Completed match did not release")

MatchService.RequestRematch(player)
task.wait(0.2)

local second = MatchService.Matches[player]
assert(second and second ~= match and not second.Ended, "Rematch did not start")
assert(second.Guard and second.Guard.Id, "Rematch has no guard")

MatchService.Forfeit(player)
assert(DataService.Get(player).Wins == 1 and DataService.Get(player).Losses == 1, "Forfeit was not stored")
assert(WorldService.BotWins == 1, "Guard total missing")
assert(player.leaderstats.Elo.Value == DataService.Get(player).Elo, "Leaderstats stale")

print("BEAT_THE_BOT_SMOKE_PASS: world, guard selection, protocol, dynamic Elo, persistence, idempotency, rematch, forfeit")