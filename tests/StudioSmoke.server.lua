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
assert(#WorldService.Arenas == 4, "Expected four ranked challenge spaces")
assert(WorldService.DailyArena, "Daily Trial arena missing")
assert(WorldService.GetDestinationCFrame("customs"), "Customs travel destination missing")
assert(WorldService.GetVIPCFrame(), "VIP Observatory destination missing")
assert(workspace.BeatTheBotWorld:FindFirstChild("FutureCitadel"), "Royal Court / Oracle teaser district missing")
assert(workspace.BeatTheBotWorld:FindFirstChild("VIPObservatory"), "VIP Observatory missing")

local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
character:PivotTo(CFrame.new(WorldService.Arenas[1].Console.Position + Vector3.new(0, 3, 4)))

MatchService.Start(player, 1)
local match = MatchService.Matches[player]

assert(match and not match.Ended, "Ranked match did not start")
assert(match.Opponent and match.Opponent.Id, "No opponent was selected")
assert(match.DistrictId == "great_gate", "Wrong district assigned to Great Gate arena")
assert(match.Concern and match.Concern.Id, "No hidden concern was selected")
assert(match.History and #match.History == 0, "Private history should start empty")
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

for _, intent in ipairs(sequences[match.Opponent.Id]) do
    task.wait(1.1)
    MatchService.Submit(player, {
        MatchId = match.Id,
        Turn = match.State.Turns + 1,
        Kind = "Choice",
        Value = intent,
    })
end

assert(match.Ended and match.State.Status == "Won", "Great Gate quick path did not win")
assert(#match.History <= Config.MaxTurns, "Private history exceeded eight turns")
assert(match.LastPlayerMessage ~= nil, "Private player display message missing")

local expectedElo = Rules.Rating(1000, match.Opponent.Rating, true, Config.RatingK)
local profile = DataService.Get(player)
assert(profile.Wins == 1 and profile.Losses == 0, "Incorrect saved ranked victory")
assert(profile.Elo == expectedElo, "Dynamic opponent Elo was not applied")
assert(profile.LastMatch.OpponentRating == match.Opponent.Rating, "Opponent rating was not stored")
assert(profile.Insight > 0, "Ranked completion did not award Insight")
assert(profile.Mastery[match.Opponent.Id].Attempts == 1, "Mastery attempt was not recorded")

MatchService.Finish(match, true, "duplicate")
profile = DataService.Get(player)
assert(profile.Wins == 1, "Duplicate ranked result")
assert(profile.Mastery[match.Opponent.Id].Attempts == 1, "Duplicate mastery reward")
assert(WorldService.HumanWins == 1 and WorldService.BotWins == 0, "Ranked server totals wrong")

task.wait(Config.ArenaResetSeconds + 0.2)
assert(MatchService.Matches[player] == nil, "Completed match did not release")

local beforeLocked = DataService.Get(player).Elo
MatchService.Start(player, 4, true)
assert(MatchService.Matches[player] == nil, "Locked Watch District accepted a ranked start")
assert(DataService.Get(player).Elo == beforeLocked, "Rejected district start changed ELO")

MatchService.RequestRematch(player)
task.wait(0.2)
local second = MatchService.Matches[player]
assert(second and second.ArenaId == 1 and second.Mode == "Ranked", "Ranked rematch did not start")

MatchService.Forfeit(player)
profile = DataService.Get(player)
assert(profile.Wins == 1 and profile.Losses == 1, "Forfeit was not stored")
assert(WorldService.BotWins == 1, "Ranked bot total missing")

task.wait(Config.ArenaResetSeconds + 0.2)
task.wait(1.1)

local eloBeforeDaily = DataService.Get(player).Elo
MatchService.StartDaily(player)
local daily = MatchService.Matches[player]
assert(daily and daily.Mode == "Daily", "Official Daily Trial did not start")
assert(daily.DayKey and daily.DayOrdinal, "Daily Trial key/ordinal missing")
assert(DataService.Get(player).DailyTrial.OfficialMatchId == daily.Id, "Official Daily Trial reservation missing")

local dailySequence = { "requirements", "permit", "verify", "escort", "flattery", "authority", "urgency", "joke" }
for _, intent in ipairs(dailySequence) do
    if daily.Ended then
        break
    end
    task.wait(1.1)
    MatchService.Submit(player, {
        MatchId = daily.Id,
        Turn = daily.State.Turns + 1,
        Kind = "Choice",
        Value = intent,
    })
end

assert(daily.Ended, "Daily Trial did not reach a terminal state")
profile = DataService.Get(player)
assert(profile.Elo == eloBeforeDaily, "Daily Trial changed ranked ELO")
assert(profile.DailyTrial.Result and profile.DailyTrial.Result.DayKey == daily.DayKey, "Official Daily result missing")
assert(profile.DailyTrial.Streak >= 1, "Daily streak did not update")

local officialId = profile.DailyTrial.OfficialMatchId
local officialMessages = profile.DailyTrial.Result.Messages

task.wait(Config.ArenaResetSeconds + 0.2)
task.wait(1.1)
MatchService.StartDaily(player)
local practice = MatchService.Matches[player]
assert(practice and practice.Mode == "DailyPractice", "Second Daily run was not practice")
assert(DataService.Get(player).DailyTrial.OfficialMatchId == officialId, "Practice replaced official match id")

MatchService.Forfeit(player)
profile = DataService.Get(player)
assert(profile.Elo == eloBeforeDaily, "Daily practice changed ranked ELO")
assert(profile.DailyTrial.Result.Messages == officialMessages, "Daily practice replaced official result")

assert(player.leaderstats.Elo.Value == profile.Elo, "Leaderstats ELO stale")
assert(player.leaderstats.Insight.Value == profile.Insight, "Leaderstats Insight stale")
assert(type(player:GetAttribute("RankTitle")) == "string", "Rank title attribute missing")

print("BEAT_THE_BOT_SMOKE_PASS: world, district gate, ranked match, rewards, mastery, Daily Trial reservation, practice isolation")