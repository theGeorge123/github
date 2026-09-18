local AnalyticsService = game:GetService("AnalyticsService")

local TelemetryService = {}

function TelemetryService.Log(player, eventName, value)
    if not player then
        return
    end

    task.spawn(function()
        pcall(function()
            AnalyticsService:LogCustomEvent(player, eventName, value or 1)
        end)
    end)
end

return TelemetryService
