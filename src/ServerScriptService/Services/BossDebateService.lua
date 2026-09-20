local Players=game:GetService("Players")
local TextService=game:GetService("TextService")
local Definitions=require(script.Parent.Parent.Core.BossDebateDefinitions)
local State=require(script.Parent.Parent.Core.BossDebateRoundState)
local Ledger=require(script.Parent.Parent.Core.BossDebateSubmissionLedger)
local Protocol=require(script.Parent.Parent.Core.BossDebateProtocol)
local Availability=require(script.Parent.Parent.Core.BossDebateAvailability)
local Participation=require(script.Parent.DebateParticipationService)
local Service={Sessions={}}
local nextSession=0
local function send(remote,player,message)if player and player.Parent then remote:FireClient(player,message)end end
local function rejected(id,code,message,retry)return {Kind="BossArgumentRejected",SubmissionId=id,Code=code,Message=message,CanRetry=retry==true,PreserveDraft=true}end
local function release(player,session)if session then Participation.Release(player,session.Claim)end;Service.Sessions[player]=nil end
local function finish(remote,player,session,message)
 if session.State.Phase~="COMPLETE"then State.abort(session.State)end
 send(remote,player,{Kind="BossPracticeComplete",Message=message,NoWinner=true,NoScore=true,NoRewards=true})
end
local function publishTurn(remote,player,session,token)
 local deadline=workspace:GetServerTimeNow()+Definitions.PlayerTurnSeconds
 send(remote,player,{Kind="BossPlayerTurn",SessionId=session.Id,RoundGeneration=session.State.RoundGeneration,TurnToken=token.TurnToken,Deadline=deadline})
 task.delay(Definitions.PlayerTurnSeconds,function()
  if Service.Sessions[player]~=session or not State.matches(session.State,token)then return end
  State.abort(session.State);finish(remote,player,session,"Practice ended because the player turn timed out. No score, winner, or rewards were created.")
 end)
end
local function start(remote,player)
 local claimed,claim=Participation.TryClaim(player,"BOSS")
 if not claimed then send(remote,player,rejected(nil,"PLAYER_BUSY","Cancel multiplayer search or leave the multiplayer debate before entering Boss Practice.",false));return end
 nextSession+=1
 local session={Id=("boss-%d-%d"):format(player.UserId,nextSession),Claim=claim,State=State.new(claim.Generation,nextSession,1),Ledger=Ledger.new()}
 Service.Sessions[player]=session
 send(remote,player,{Kind="BossPracticeStarted",SessionId=session.Id,RoundGeneration=1,Topic=Definitions.Topic,PlayerPosition=Definitions.Topic.PlayerPosition,BossPosition=Definitions.Topic.BossPosition,Disclosure=Definitions.Disclosure})
 publishTurn(remote,player,session,State.startTurn(session.State))
end
local function leave(remote,player)
 local session=Service.Sessions[player]
 if session then State.abort(session.State);State.close(session.State);release(player,session)end
 send(remote,player,{Kind="BossPracticeEnded"})
end
local function submitArgument(remote,player,message)
 local session=Service.Sessions[player]
 if not session or session.Id~=message.SessionId or session.State.RoundGeneration~=message.RoundGeneration then send(remote,player,rejected(message.SubmissionId,"STALE_SESSION","This practice session is no longer active.",false));return end
 if session.State.Phase~="PLAYER_TURN"or session.State.TurnToken~=message.TurnToken then send(remote,player,rejected(message.SubmissionId,"STALE_TURN","That turn is no longer active.",false));return end
 if #message.Text==0 or #message.Text>Definitions.MaxArgumentBytes then send(remote,player,rejected(message.SubmissionId,"INVALID_TEXT","Enter 1 to 500 bytes.",true));return end
 local action,value=Ledger.begin(session.Ledger,message.SubmissionId,message.Text)
 if action=="IGNORE"then return elseif action=="REPLAY"then send(remote,player,value);return elseif action=="REJECT"then send(remote,player,rejected(message.SubmissionId,value,"Use a new increasing submission ID.",false));return end
 local filterToken=State.beginFiltering(session.State,message.TurnToken)
 if not filterToken then local ack=rejected(message.SubmissionId,"STALE_TURN","That turn is no longer active.",false);Ledger.finish(session.Ledger,message.SubmissionId,"REJECTED",ack);send(remote,player,ack);return end
 local ok,filtered=pcall(function()return TextService:FilterStringAsync(message.Text,player.UserId):GetNonChatStringForUserAsync(player.UserId)end)
 if Service.Sessions[player]~=session or not State.matches(session.State,filterToken)then return end
 if not ok or filtered==""then local retry=State.filterFailed(session.State,filterToken);local ack=rejected(message.SubmissionId,"FILTER_FAILED","That text could not be filtered. Your draft was kept; try again.",true);Ledger.finish(session.Ledger,message.SubmissionId,"REJECTED",ack);send(remote,player,ack);publishTurn(remote,player,session,retry);return end
 if not State.acceptFiltered(session.State,filterToken)then return end
 local accepted={Kind="BossArgumentAccepted",SubmissionId=message.SubmissionId,TurnToken=message.TurnToken,FilteredText=filtered};Ledger.finish(session.Ledger,message.SubmissionId,"ACCEPTED",accepted);send(remote,player,accepted)
 send(remote,player,{Kind="BossScriptedReply",Text=Definitions.ScriptedReplies[session.State.Turn],Label="SCRIPTED PRACTICE - NOT A SEMANTIC RESPONSE"})
 local nextTurn=State.finishReply(session.State,Definitions.PlayerTurns)
 if nextTurn=="COMPLETE"then finish(remote,player,session,"Three-turn authored practice complete. No score, winner, or rewards were created.")else publishTurn(remote,player,session,nextTurn)end
end
function Service.Init(stateRemote,submitRemote,config)
 submitRemote.OnServerEvent:Connect(function(player,message)
  local valid=Protocol.ValidateClient(message);local tier,reason,disclosure=Availability.Resolve(config)
  if not valid then send(stateRemote,player,rejected(nil,"INVALID_ACTION",disclosure,false));return end
  if message.Action=="GetAvailability"then send(stateRemote,player,Protocol.Availability(tier,reason,disclosure))
  elseif tier~="SCRIPTED_PRACTICE"then send(stateRemote,player,rejected(nil,"BOSS_LOCKED",disclosure,false))
  elseif message.Action=="EnterPractice"then if Service.Sessions[player]then send(stateRemote,player,rejected(nil,"ALREADY_ACTIVE","Leave or restart the current practice first.",false))else start(stateRemote,player)end
  elseif message.Action=="SubmitArgument"then submitArgument(stateRemote,player,message)
  elseif message.Action=="LeavePractice"then leave(stateRemote,player)
  elseif message.Action=="RestartPractice"then leave(stateRemote,player);start(stateRemote,player)end
 end)
 Players.PlayerRemoving:Connect(function(player)local s=Service.Sessions[player];if s then release(player,s)end;Participation.Disconnect(player)end)
end
return Service
