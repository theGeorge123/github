local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config)
assert(RunService:IsStudio() and not Config.StudioPersistence, "Smoke tests require Studio session-only mode")

local services = game:GetService("ServerScriptService").Services
local DataService = require(services.DataService)
local MatchService = require(services.MatchService)
local WorldService = require(services.WorldService)

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local deadline = os.clock() + 30
while not player:GetAttribute("ProfileReady") and os.clock() < deadline do
    task.wait(0.1)
end
assert(player:GetAttribute("ProfileReady"), "Profile failed to load")

local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
character:PivotTo(CFrame.new(WorldService.Arenas[1].Console.Position + Vector3.new(0, 3, 4)))

MatchService.Start(player, 1)
local match = MatchService.Matches[player]
assert(match and not match.Ended, "Match did not start")
assert(DataService.Get(player).ActiveMatch == match.Id, "Active marker missing")

MatchService.Submit(player, { MatchId = "forged", Turn = 1, Kind = "Choice", Value = "escort" })
assert(match.State.Turns == 0, "Forged submission accepted")

for _, intent in ipairs({ "requirements", "permit", "verify", "escort" }) do
    task.wait(1.1)
    MatchService.Submit(player, { MatchId = match.Id, Turn = match.State.Turns + 1, Kind = "Choice", Value = intent })
end

assert(match.Ended and match.State.Status == "Won", "Ordered challenge did not win")
local profile = DataService.Get(player)
assert(profile.Wins == 1 and profile.Losses == 0 and profile.Elo == 1016, "Incorrect saved victory")

MatchService.Finish(match, true, "duplicate")
assert(DataService.Get(player).Wins == 1, "Duplicate reward")
assert(WorldService.HumanWins == 1 and WorldService.BotWins == 0, "Server totals wrong")

task.wait(Config.ArenaResetSeconds + 0.2)
assert(MatchService.Matches[player] == nil, "Completed match did not release")
MatchService.RequestRematch(player)
task.wait(0.2)
local second = MatchService.Matches[player]
assert(second and second ~= match and not second.Ended, "Rematch did not start")
assert(second.ArenaId == 1, "Rematch changed arena unexpectedly")

MatchService.Forfeit(player)
assert(DataService.Get(player).Wins == 1 and DataService.Get(player).Losses == 1, "Forfeit was not stored")
assert(WorldService.BotWins == 1, "Guard total missing")
assert(player.leaderstats.Elo.Value == DataService.Get(player).Elo, "Leaderstats stale")

print("BEAT_THE_BOT_SMOKE_PASS: win, protocol, persistence, idempotency, rematch, forfeit, counters, leaderstats")