local HttpService = game:GetService("HttpService")
local Diagnostics = require(script.Parent.Parent.Core.DebateDiagnostics)

local DebateProbeAdapter = {}

local function classify(message)
    local lower = string.lower(tostring(message or ""))
    if string.find(lower, "timeout", 1, true) then
        return "TIMEOUT"
    elseif string.find(lower, "filter", 1, true) then
        return "FILTER_FAILED"
    elseif string.find(lower, "parse", 1, true) or string.find(lower, "malformed", 1, true) then
        return "MALFORMED"
    elseif string.find(lower, "unavailable", 1, true) or string.find(lower, "not enabled", 1, true) then
        return "UNAVAILABLE"
    end
    return "UNKNOWN_FAILURE"
end

function DebateProbeAdapter.ValidatePayload(payload, expectedMessageId)
    if type(payload) ~= "table" or type(payload.text) ~= "string" then
        return nil
    end
    if utf8.len(payload.text) == nil or utf8.len(payload.text) > 500 then
        return nil
    end
    if type(payload.addresses) ~= "table" or #payload.addresses == 0 or #payload.addresses > 2 then
        return nil
    end
    local addressed = false
    for _, id in ipairs(payload.addresses) do
        if type(id) ~= "string" or not string.match(id, "^[PB][1-4]$") then
            return nil
        end
        addressed = addressed or id == expectedMessageId
    end
    if not addressed then
        return nil
    end
    return payload
end

function DebateProbeAdapter.Run(executor, request, generationId, currentGeneration)
    local started = os.clock()
    local inputBytes = #(request.Prompt or "")
    local ok, response = pcall(executor, request)
    local elapsedMs = math.floor((os.clock() - started) * 1000)

    if currentGeneration() ~= generationId then
        return Diagnostics.Failure("TIMEOUT", "ARGUE", elapsedMs, inputBytes, 0)
    end
    if not ok then
        return Diagnostics.Failure(classify(response), "ARGUE", elapsedMs, inputBytes, 0)
    end
    if type(response) ~= "string" or response == "" then
        return Diagnostics.Failure("UNAVAILABLE", "ARGUE", elapsedMs, inputBytes, 0)
    end

    local decodedOk, payload = pcall(HttpService.JSONDecode, HttpService, response)
    if not decodedOk or not DebateProbeAdapter.ValidatePayload(payload, request.ExpectedMessageId) then
        return Diagnostics.Failure("MALFORMED", "ARGUE", elapsedMs, inputBytes, #response)
    end
    return Diagnostics.Success("LIVE", "ARGUE", elapsedMs, inputBytes, #response, payload)
end

return DebateProbeAdapter
