local Players=game:GetService("Players")
local Service=require(game:GetService("ServerScriptService").Services.DebateProbeService)
local ran=false
local function run(player)if ran then return end;ran=true;Service.RunFixed(player)end
Players.PlayerAdded:Connect(run)
Players.PlayerRemoving:Connect(function()Service.Cancel()end)
for _,player in ipairs(Players:GetPlayers())do task.spawn(run,player)end
