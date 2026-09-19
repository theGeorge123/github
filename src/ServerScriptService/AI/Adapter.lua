local LocalAdapter = require(script.Parent.LocalAdapter)
local Rules = require(script.Parent.Parent.Core.Rules)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Adapter = {}

assert(Config.AIProvider == "Local", "Only the Local provider is implemented. See docs/AI_ADAPTER.md.")

function Adapter.Decide(context)
    local result = LocalAdapter.Decide(table.freeze(context))
    assert(type(result) == "table" and Rules.Intents[result.Intent], "Invalid adapter intent")
    return result.Intent
end

return Adapter
