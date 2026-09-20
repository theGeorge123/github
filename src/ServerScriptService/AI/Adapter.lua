local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local Rules=require(script.Parent.Parent.Core.Rules)
local Diagnostics=require(script.Parent.Parent.Core.AIDiagnostics)
local LocalAdapter=require(script.Parent.LocalAdapter)
local RobloxAdapter=require(script.Parent.RobloxAdapter)
local Adapter={}
local providers={Local=LocalAdapter,Roblox=RobloxAdapter}
local function failure(stage,category)return {Ok=false,Diagnostics=Diagnostics.Failure(stage,category,0,0,0)}end
function Adapter.Decide(context)
 local provider=providers[Config.AIProvider];if not provider then return failure("CONFIGURE","UNAVAILABLE")end
 local ok,result=pcall(provider.Decide,context);if not ok then return failure("GENERATE","UNKNOWN_FAILURE")end
 if type(result)~="table"or result.Ok~=true then if type(result)=="table"and result.Diagnostics then return {Ok=false,Diagnostics=result.Diagnostics}end;return failure("GENERATE","UNKNOWN_FAILURE")end
 if not Rules.Intents[result.Intent]or not Rules.Strengths[result.Strength]or(result.Reply~=nil and type(result.Reply)~="string")then return failure("PARSE","BAD_SCHEMA")end
 return result
end
return Adapter
