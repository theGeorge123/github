local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Definitions = require(script.Parent.Parent.Core.DebateDefinitions)
local TesterPolicy = require(script.Parent.Parent.Core.TesterPolicy)

local DebateService = { Sessions = {} }
local function publish(remote, player, payload) remote:FireClient(player, payload) end

function DebateService.Init(remote, submit)
    DebateService.Remote = remote
    submit.OnServerEvent:Connect(function(player, action, value)
        if not TesterPolicy.IsTester(player) then return end
        if action == "select" and Definitions.Characters[value] then
            DebateService.Sessions[player] = { Id = HttpService:GenerateGUID(false), Character = value, Turn = 0, Closed = false }
            publish(remote, player, { Kind = "Selected", Character = value, Definition = Definitions.Characters[value], Turns = Definitions.Turns })
        elseif action == "argument" then
            local session = DebateService.Sessions[player]
            if not session or session.Closed or type(value) ~= "string" or #value < 2 or #value > 500 then return end
            local turn = session.Turn + 1
            if turn > Definitions.Turns then return end
            local ok, filtered = pcall(function()
                local result = TextService:FilterStringAsync(value, player.UserId)
                return result:GetNonChatStringForBroadcastAsync()
            end)
            if not ok or filtered == "" then
                publish(remote, player, { Kind = "Error", Category = "FILTER_FAILED" })
                return
            end
            session.Turn = turn
            local definition = Definitions.Characters[session.Character]
            publish(remote, player, {
                Kind = "Reply", Turn = turn, PlayerText = filtered, BotText = definition.Replies[turn],
                Source = "SCRIPTED", Label = "SCRIPTED PRACTICE — NO WINNER OR SCORE",
            })
            if turn == Definitions.Turns then
                session.Closed = true
                publish(remote, player, { Kind = "Complete", Rubric = Definitions.Rubric, ReliableVerdict = false, Message = "Practice complete. Live judging is unavailable; no winner or numeric total was assigned." })
            end
        elseif action == "reset" then
            DebateService.Sessions[player] = nil
            publish(remote, player, { Kind = "Reset" })
        end
    end)
end
return DebateService
