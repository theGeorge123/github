local DebateDiagnostics = {}

DebateDiagnostics.Sources = table.freeze({
    LIVE = true,
    SCRIPTED = true,
})

DebateDiagnostics.Failures = table.freeze({
    TIMEOUT = true,
    FILTER_FAILED = true,
    MALFORMED = true,
    UNAVAILABLE = true,
    UNKNOWN_FAILURE = true,
})

local function boundedInteger(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

function DebateDiagnostics.Failure(category, phase, elapsedMs, inputBytes, outputBytes)
    if not DebateDiagnostics.Failures[category] then
        category = "UNKNOWN_FAILURE"
    end
    return table.freeze({
        Ok = false,
        Category = category,
        Phase = phase == "JUDGE" and "JUDGE" or "ARGUE",
        ElapsedMs = boundedInteger(elapsedMs),
        InputBytes = boundedInteger(inputBytes),
        OutputBytes = boundedInteger(outputBytes),
    })
end

function DebateDiagnostics.Success(source, phase, elapsedMs, inputBytes, outputBytes, payload)
    assert(DebateDiagnostics.Sources[source], "Unknown debate source")
    return {
        Ok = true,
        Source = source,
        Phase = phase == "JUDGE" and "JUDGE" or "ARGUE",
        ElapsedMs = boundedInteger(elapsedMs),
        InputBytes = boundedInteger(inputBytes),
        OutputBytes = boundedInteger(outputBytes),
        Payload = payload,
    }
end

function DebateDiagnostics.LogFields(result, buildVersion)
    return table.freeze({
        Build = tostring(buildVersion or "unknown"):sub(1, 32),
        Phase = result.Phase,
        Source = result.Source,
        Category = result.Category,
        ElapsedMs = boundedInteger(result.ElapsedMs),
        InputBytes = boundedInteger(result.InputBytes),
        OutputBytes = boundedInteger(result.OutputBytes),
        Schema = 1,
    })
end

return DebateDiagnostics
