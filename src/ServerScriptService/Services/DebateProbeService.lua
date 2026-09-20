local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local TesterPolicy=require(script.Parent.Parent.Core.TesterPolicy)
local Diagnostics=require(script.Parent.Parent.Core.AIDiagnostics)
local Parser=require(script.Parent.Parent.AI.DebateProbeAdapter)
local Executor=require(script.Parent.Parent.AI.RobloxTextGeneratorProbeExecutor)
local Service={};local generation=0;local busy=false
local FIXED_PROMPT=table.concat({"PRIVATE FIXED-INPUT TECHNICAL PROBE.","Return exactly this JSON schema and no other text:",'{"text":"one short child-safe sentence about checking evidence","addresses":["P1"]}',"The addresses value must contain P1.","Do not include scores, rewards, winners, citations, URLs, or personal facts."},"\n")
local function log(result)local f=Diagnostics.LogFields(result,Config.Version);print(string.format("BEAT_THE_BOT_AI schema=%d build=%s stage=%s category=%s source=%s elapsed_ms=%d input_bytes=%d output_bytes=%d",f.Schema,f.Build,f.Stage,f.Category,f.Source,f.ElapsedMs,f.InputBytes,f.OutputBytes))end
function Service.RunFixed(player)
 if not(Config.DebateEnabled and Config.DebateLiveEnabled and Config.DebateProbe.Enabled and TesterPolicy.CanRunLiveProbe(player)and game.PrivateServerId~="")then local d=Diagnostics.Failure("CREATE","UNAVAILABLE",0,#FIXED_PROMPT,0);log(d);return false,"UNAVAILABLE"end
 if busy then local d=Diagnostics.Failure("GENERATE","UNAVAILABLE",0,#FIXED_PROMPT,0);log(d);return false,"UNAVAILABLE"end
 busy=true;generation+=1;local mine=generation;local result=Executor.Execute({Prompt=FIXED_PROMPT,MaxTokens=Config.DebateProbe.MaxTokens});busy=false
 if mine~=generation or not player.Parent then local d=Diagnostics.Failure("APPLY",mine~=generation and"CANCELLED"or"STALE",result.Diagnostics.ElapsedMs,#FIXED_PROMPT,result.Diagnostics.OutputBytes);log(d);return false,d.Category end
 if not result.Ok then log(result.Diagnostics);return false,result.Diagnostics.Category end
 local payload,category=Parser.Parse(result.Text,"P1",Config.DebateProbe.MaxOutputBytes,Config.DebateProbe.MaxTextBytes)
 result.Text=nil
 if not payload then local d=Diagnostics.Failure("PARSE",category,result.Diagnostics.ElapsedMs,#FIXED_PROMPT,result.Diagnostics.OutputBytes);log(d);return false,category end
 payload=nil;local d=Diagnostics.Success("PARSE",result.Diagnostics.ElapsedMs,#FIXED_PROMPT,result.Diagnostics.OutputBytes,"LIVE");log(d);return true,"OK"
end
function Service.Cancel()generation+=1 end
return Service
