local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Rules = require(script.Parent.Parent.Core.Rules)
local LocalAdapter = require(script.Parent.LocalAdapter)
local RobloxAdapter = require(script.Parent.RobloxAdapter)

local Adapter = {}

local providers = {
    Local = LocalAdapter,
    Roblox = RobloxAdapter,
}

function Adapter.Decide(context)
    local provider = providers[Config.AIProvider]
    assert(provider, "Unsupported AI provider: " .. tostring(Config.AIProvider))

    local ok, result = pcall(provider.Decide, context)

    if not ok and Config.AIProvider == "Roblox" then
        local fallback = LocalAdapter.Decide(context)
        fallback.Provider = "Fallback"
        fallback.Degraded = true
        return fallback
    end

    if not ok then
        error(result)
    end

    assert(type(result) == "table", "AI adapter must return a table")
    assert(Rules.Intents[result.Intent], "Invalid adapter intent")
    assert(Rules.Strengths[result.Strength], "Invalid adapter strength")
    if result.Reply ~= nil then
        assert(type(result.Reply) == "string", "Invalid adapter reply")
    end
    return result
end

return Adapter