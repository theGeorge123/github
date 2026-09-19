local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(script.Parent.Parent.Core.DebateProbeDefinitions)
local Diagnostics = require(script.Parent.Parent.Core.DebateDiagnostics)
local Adapter = require(script.Parent.Parent.AI.DebateProbeAdapter)

local DebateProbeService = {}
local activeGeneration = {}

local function enabledFor(player, testerPolicy)
    return Config.DebateEnabled == true
        and Config.DebateLiveEnabled == true
        and testerPolicy.IsTester(player)
end

local function safeLog(result)
    local fields = Diagnostics.LogFields(result, Config.Version)
    print(string.format(
        "BEAT_THE_BOT_DEBATE_PROBE phase=%s source=%s category=%s elapsed_ms=%d input_bytes=%d output_bytes=%d schema=%d",
        fields.Phase,
        fields.Source or "NONE",
        fields.Category or "NONE",
        fields.ElapsedMs,
        fields.InputBytes,
        fields.OutputBytes,
        fields.Schema
    ))
end

local function probePrompt(turn)
    return table.concat({
        "PRIVATE UNRANKED DEBATE PROBE. Return JSON only.",
        "Character position: " .. Definitions.CharacterPosition,
        "Player position: " .. Definitions.PlayerPosition,
        "Address message " .. turn.Id .. ": " .. turn.Text,
        'Schema: {"text":"...","addresses":["' .. turn.Id .. '"]}',
        "Do not invent statistics, rewards, ELO, user facts or external sources.",
    }, "\n")
end

function DebateProbeService.Run(player, testerPolicy, executor)
    if not enabledFor(player, testerPolicy) then
        return Diagnostics.Failure("UNAVAILABLE", "ARGUE", 0, 0, 0)
    end

    activeGeneration[player] = (activeGeneration[player] or 0) + 1
    local generationId = activeGeneration[player]
    local results = {}

    for _, turn in ipairs(Definitions.Exchanges) do
        local request = {
            Prompt = probePrompt(turn),
            ExpectedMessageId = turn.Id,
            MaxTokens = 120,
            DeadlineSeconds = 12,
        }
        local result = Adapter.Run(executor, request, generationId, function()
            return activeGeneration[player]
        end)
        safeLog(result)
        table.insert(results, result)
        if not result.Ok then
            break
        end
    end
    return results
end

function DebateProbeService.Cancel(player)
    activeGeneration[player] = (activeGeneration[player] or 0) + 1
end

return DebateProbeService
