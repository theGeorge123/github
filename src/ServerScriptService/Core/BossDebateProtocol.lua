local Protocol={}
local CLIENT_ACTIONS={GetAvailability=true,EnterPractice=true,SelectTopic=true,SubmitArgument=true,LeavePractice=true,RestartPractice=true}
function Protocol.ValidateClient(message)
 if type(message)~="table"or not CLIENT_ACTIONS[message.Action]then return false,"INVALID_ACTION"end
 if message.Action=="GetAvailability"or message.Action=="EnterPractice"then return true end
 if message.Action=="SelectTopic"then return type(message.SessionId)=="string"and type(message.TopicId)=="string","INVALID_TOPIC"end
 if message.Action=="SubmitArgument"then
  if type(message.SessionId)~="string"or type(message.RoundGeneration)~="number"or type(message.TurnToken)~="number"or type(message.SubmissionId)~="number"or type(message.Text)~="string"then return false,"INVALID_SUBMISSION"end
 elseif message.Action=="LeavePractice"or message.Action=="RestartPractice"then
  if type(message.SessionId)~="string"then return false,"INVALID_SESSION"end
 end
 return true
end
function Protocol.Availability(tier,reason,disclosure)
 assert(tier=="LOCKED"or tier=="SCRIPTED_PRACTICE"or tier=="LIVE_AI_BETA","Invalid Boss tier")
 return {Kind="BossAvailability",Tier=tier,ReasonCode=reason,Disclosure=disclosure}
end
function Protocol.Rejected(code,message)
 return {Kind="BossArgumentRejected",Code=code,Message=message,CanRetry=false,PreserveDraft=true}
end
return Protocol
