local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local Diagnostics=require(script.Parent.Parent.Core.AIDiagnostics)
local Executor={};local busy=false
function Executor.Execute(request)
 if busy then return {Ok=false,Diagnostics=Diagnostics.Failure("GENERATE","UNAVAILABLE",0,#request.Prompt,0)}end
 busy=true;local generator;local response;local stage="CREATE";local started=os.clock();local ok=pcall(function()
  stage="CREATE";generator=Instance.new("TextGenerator");stage="CONFIGURE";generator.Name="BeatTheBotFixedProbe";generator.SystemPrompt="Return only the exact JSON schema requested by the fixed server prompt.";generator.Parent=workspace;stage="GENERATE";response=generator:GenerateTextAsync({UserPrompt=request.Prompt,MaxTokens=request.MaxTokens})
 end);if generator then generator:Destroy();generator=nil end;busy=false
 local elapsed=math.floor((os.clock()-started)*1000);local input=#request.Prompt
 if not ok then local category=stage=="CREATE"and"CLASS_UNAVAILABLE"or stage=="CONFIGURE"and"CONFIGURE_FAILED"or"GENERATION_FAILED";return {Ok=false,Diagnostics=Diagnostics.Failure(stage,category,elapsed,input,0)}end
 if type(response)~="table"then return {Ok=false,Diagnostics=Diagnostics.Failure("RESPONSE","INVALID_RESPONSE_SHAPE",elapsed,input,0)}end
 if type(response.GeneratedText)~="string"or response.GeneratedText==""then return {Ok=false,Diagnostics=Diagnostics.Failure("RESPONSE","EMPTY_RESPONSE",elapsed,input,0)}end
 return {Ok=true,Text=response.GeneratedText,Diagnostics=Diagnostics.Success("RESPONSE",elapsed,input,#response.GeneratedText,"LIVE"),SlowCompletion=elapsed>Config.DebateProbe.SlowThresholdMs}
end
return Executor
