local AnalyticsService = game:GetService("AnalyticsService")

local TelemetryService = {}

local function safeName(value)
    return tostring(value or "unknown"):gsub("[^%w_]", "_")
end

function TelemetryService.Log(player, eventName, value)
    if not player or not player.Parent then
        return
    end

    local ok, err = pcall(function()
        AnalyticsService:LogCustomEvent(player, eventName, value or 1)
    end)

    if not ok then
        warn("Beat the Bot analytics error:", err)
    end
end

function TelemetryService.MatchStarted(player, guard)
    TelemetryService.Log(player, "BTB_MatchStarted_" .. safeName(guard.Id))
end

function TelemetryService.Move(player, kind)
    TelemetryService.Log(player, kind == "Text" and "BTB_TextMove" or "BTB_QuickMove")
end

function TelemetryService.AIError(player)
    TelemetryService.Log(player, "BTB_AIError")
end

function TelemetryService.MatchFinished(player, guard, won, turns, duration)
    TelemetryService.Log(player, (won and "BTB_MatchWon_" or "BTB_MatchLost_") .. safeName(guard.Id))
    TelemetryService.Log(player, "BTB_MovesUsed", turns)
    TelemetryService.Log(player, "BTB_MatchDuration", math.max(0, math.round(duration)))
end

function TelemetryService.Rematch(player)
    TelemetryService.Log(player, "BTB_Rematch")
end

return TelemetryService