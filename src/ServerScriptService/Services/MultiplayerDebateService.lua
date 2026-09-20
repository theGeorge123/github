local Players=game:GetService("Players")
local TextService=game:GetService("TextService")
local Definitions=require(script.Parent.Parent.Core.MultiplayerDebateDefinitions)
local Protocol=require(script.Parent.Parent.Core.DebateProtocol)
local RoundState=require(script.Parent.Parent.Core.DebateRoundState)
local ArgumentValidation=require(script.Parent.Parent.Core.ArgumentValidation)
local Participation=require(script.Parent.DebateParticipationService)
local Structure=require(script.Parent.Parent.Core.DebateStructure)
local AntiEmptyPolicy=require(script.Parent.Parent.Core.AntiEmptyLobbyPolicy)
local Service={Queue={},Sessions={},Profiles={},LastSubmit={},Claims={},Background={},Offers={}}
local nextSessionId=0
local function profile(p)
 local x=Service.Profiles[p];if not x then x={Points=0,Chair="starter-chair",Title="Debater"};Service.Profiles[p]=x end;return x
end
local function send(remote,p,data) if p and p.Parent then remote:FireClient(p,data) end end
local function reject(remote,p,id,code,message)send(remote,p,{Kind="ArgumentRejected",SubmissionId=id,Code=code,Message=message,CanRetry=true})end
local function both(s,remote,data) for _,p in ipairs(s.Players) do send(remote,p,data) end end
local function unlocks(points)local owned={};for _,u in ipairs(Definitions.Unlocks)do if points>=u.Points then owned[u.Id]=true end end;return owned end
local function publicProfile(p)local x=profile(p);return {Points=x.Points,Chair=x.Chair,Title=x.Title,Unlocks=unlocks(x.Points)}end
local function topicFor(s)return Definitions.Topics[((s.Round-1)%#Definitions.Topics)+1]end
local function publishLobby(remote,p,status)send(remote,p,Protocol.Lobby(status,publicProfile(p),#Service.Queue))end
local function publishProfile(remote,p)send(remote,p,Protocol.Profile(publicProfile(p)))end
local function playerIndexFor(s,p)for i,q in ipairs(s.Players)do if q==p then return i end end end
local publishTurn
local function completeRound(s,remote)
 s.Closed=true;both(s,remote,{Kind="Complete",Round=s.Round,Scores={{Name=s.Players[1].DisplayName,Points=s.Scores[s.Players[1]]or 0},{Name=s.Players[2].DisplayName,Points=s.Scores[s.Players[2]]or 0}},Message="Round complete. Points reflect the visible checklist, not debate truth."})
end
publishTurn=function(s,remote)
 local turn=RoundState.beginTurn(s.RoundState);local player=s.Players[turn.PlayerIndex];local deadline=workspace:GetServerTimeNow()+Definitions.TurnSeconds;s.TurnDeadline=deadline
 local side=Structure.SideFor(s.Round,turn.PlayerIndex);local role=Structure.RoleForTurn(turn.TurnNumber)
 both(s,remote,{Kind="Turn",UserId=player.UserId,Name=player.DisplayName,TurnNumber=turn.TurnNumber,Deadline=deadline,Side=side,Role=role,HostPrompt=Structure.HostPrompt(topicFor(s),role,side,s.PreviousCriteria)})
 local sessionId=s.Id
 task.delay(Definitions.TurnSeconds,function()
  if s.Ended or Service.Sessions[player]~=s or s.Id~=sessionId then return end
  local result=RoundState.completeTurn(s.RoundState,turn.RoundGeneration,turn.TurnToken,turn.PlayerIndex);if not result.Applied then return end
  both(s,remote,{Kind="TurnTimedOut",UserId=player.UserId,Name=player.DisplayName,Message=player.DisplayName.." ran out of time. No points were awarded."})
  if result.Complete then completeRound(s,remote)else publishTurn(s,remote)end
 end)
end
local function beginRound(s,remote)
 s.RoundGeneration=(s.RoundGeneration or 0)+1;s.RoundState=RoundState.new(s.RoundGeneration,Definitions.PlayerTurnsEach,(s.Round%2)+1);s.Closed=false;s.Rematch={};s.PreviousCriteria=nil;s.Scores={[s.Players[1]]=0,[s.Players[2]]=0};local t=topicFor(s)
 both(s,remote,Protocol.Start(s.Round,t,{Name=s.Players[1].DisplayName,UserId=s.Players[1].UserId,Profile=publicProfile(s.Players[1])},{Name=s.Players[2].DisplayName,UserId=s.Players[2].UserId,Profile=publicProfile(s.Players[2])},t.ScriptedOpening,"Session points use a visible writing checklist; they are not an AI judgment."));publishTurn(s,remote)
end

local function start(remote,a,b)nextSessionId=nextSessionId+1;local s={Id=nextSessionId,Players={a,b},Round=1,RoundGeneration=0,Scores={},Ended=false};Service.Sessions[a]=s;Service.Sessions[b]=s;beginRound(s,remote)end
local function removeQueued(p)for i=#Service.Queue,1,-1 do if Service.Queue[i]==p then table.remove(Service.Queue,i)end end end
local function releaseClaim(p)local claim=Service.Claims[p];if claim then Participation.Release(p,claim);Service.Claims[p]=nil end end
local function sendOffer(remote,bossPlayer,queuedPlayer)
 local id=("offer-%d-%d-%d"):format(bossPlayer.UserId,queuedPlayer.UserId,math.floor(os.clock()*1000));local offer=AntiEmptyPolicy.NewOffer(id,bossPlayer,queuedPlayer,workspace:GetServerTimeNow()+30);Service.Offers[bossPlayer]=offer;Service.Offers[queuedPlayer]=offer
 send(remote,bossPlayer,{Kind="MatchOffer",OfferId=id,OpponentName=queuedPlayer.DisplayName,Message="Opponent found. Finish your current scripted turn, then choose SWITCH TO PLAYER."})
 send(remote,queuedPlayer,{Kind="Lobby",Status="QUEUED",Profile=publicProfile(queuedPlayer),QueueSize=#Service.Queue,Message="Opponent found and finishing a scripted turn."})
 task.delay(30,function()if Service.Offers[bossPlayer]~=offer then return end;Service.Offers[bossPlayer]=nil;Service.Offers[queuedPlayer]=nil;if queuedPlayer.Parent==Players and Service.Claims[queuedPlayer]then table.insert(Service.Queue,1,queuedPlayer);publishLobby(remote,queuedPlayer,"QUEUED")end end)
end
local function tryBackgroundOffers(remote)
 for bossPlayer in pairs(Service.Background)do if bossPlayer.Parent==Players and not Service.Offers[bossPlayer]and #Service.Queue>0 then local queued=table.remove(Service.Queue,1);if queued~=bossPlayer and queued.Parent==Players then sendOffer(remote,bossPlayer,queued);return end end end
end
local function endSession(s,remote,message)
 s.Ended=true;if s.RoundState then RoundState.close(s.RoundState)end;for _,q in ipairs(s.Players)do Service.Sessions[q]=nil;releaseClaim(q);send(remote,q,{Kind="Ended",Message=message,Profile=publicProfile(q)})end
end
function Service.Init(remote,submit)
 submit.OnServerEvent:Connect(function(p,action,value)
  if action=="queue"then if Service.Sessions[p]then return end;local claimed,claim=Participation.TryClaim(p,"MULTIPLAYER");if not claimed then send(remote,p,{Kind="Error",Code="PLAYER_BUSY",Message="Leave the other debate mode before joining multiplayer."});return end;Service.Claims[p]=claim;removeQueued(p);table.insert(Service.Queue,p);publishLobby(remote,p,"QUEUED");tryBackgroundOffers(remote);while #Service.Queue>=2 do local a=table.remove(Service.Queue,1);local b=table.remove(Service.Queue,1);if a.Parent==Players and b.Parent==Players then start(remote,a,b)elseif a.Parent==Players then releaseClaim(b);table.insert(Service.Queue,1,a)elseif b.Parent==Players then releaseClaim(a);table.insert(Service.Queue,1,b)else releaseClaim(a);releaseClaim(b)end end
  elseif action=="backgroundQueue"then
   if Service.Sessions[p]then return end;if not AntiEmptyPolicy.CanBackgroundSearch(Participation.Get(p))then send(remote,p,{Kind="Error",Code="BOSS_REQUIRED",Message="Start scripted Boss Practice before background matchmaking."});return end;Service.Background[p]=true;send(remote,p,{Kind="BackgroundQueue",Status="SEARCHING",Message="Looking for a real player while scripted practice continues."});tryBackgroundOffers(remote)
  elseif action=="cancelBackground"then Service.Background[p]=nil;local offer=Service.Offers[p];if offer then Service.Offers[offer.BossPlayer]=nil;Service.Offers[offer.QueuedPlayer]=nil;if offer.QueuedPlayer.Parent==Players and Service.Claims[offer.QueuedPlayer]then table.insert(Service.Queue,1,offer.QueuedPlayer);publishLobby(remote,offer.QueuedPlayer,"QUEUED")end end;send(remote,p,{Kind="BackgroundQueue",Status="OFF",Message="Background matchmaking cancelled."})
  elseif action=="acceptOffer"then
   local offer=Service.Offers[p];local canAccept,acceptCode=AntiEmptyPolicy.CanAccept(offer,type(value)=="table"and value.OfferId or nil,Participation.Get(p));if not canAccept then send(remote,p,{Kind="Error",Code=acceptCode,Message=acceptCode=="FINISH_CURRENT_TURN"and"Finish the current scripted turn and leave practice before switching."or"That opponent offer expired."});return end
   AntiEmptyPolicy.Resolve(offer,"ACCEPTED")
   local claimed,claim=Participation.TryClaim(p,"MULTIPLAYER");if not claimed then send(remote,p,{Kind="Error",Code="PLAYER_BUSY",Message="Leave the other mode before switching."});return end
   Service.Claims[p]=claim;Service.Background[p]=nil;Service.Offers[offer.BossPlayer]=nil;Service.Offers[offer.QueuedPlayer]=nil
   if offer.QueuedPlayer.Parent==Players and Service.Claims[offer.QueuedPlayer]then start(remote,p,offer.QueuedPlayer)else releaseClaim(p);send(remote,p,{Kind="Error",Code="OPPONENT_LEFT",Message="That player left. Background matchmaking can continue."})end
  elseif action=="cancelQueue"then removeQueued(p);releaseClaim(p);publishLobby(remote,p,"READY")
  elseif action=="profile"then publishProfile(remote,p)
  elseif action=="equip"and type(value)=="table"then local x=profile(p);local owned=unlocks(x.Points);if value.Kind=="chair"and owned[value.Id]then x.Chair=value.Id elseif value.Kind=="title"and owned[value.Id]then x.Title=value.Id end;publishLobby(remote,p,"READY")
  elseif action=="argument"then
   local submissionId=type(value)=="table"and value.Id or nil
   local valid,code,message=ArgumentValidation.Validate(value,Definitions.MaxArgumentBytes);if not valid then reject(remote,p,submissionId,code,message);return end
   local s=Service.Sessions[p];if not s or s.Closed then reject(remote,p,value.Id,"NO_ACTIVE_ROUND","There is no active debate round.");return end
   local playerIndex=playerIndexFor(s,p);if not playerIndex or s.RoundState.PlayerIndex~=playerIndex then reject(remote,p,value.Id,"NOT_YOUR_TURN","Wait for your turn before sending.");return end
   local now=os.clock();if now-(Service.LastSubmit[p]or 0)<1 then reject(remote,p,value.Id,"RATE_LIMITED","Wait a moment before trying again.");return end;Service.LastSubmit[p]=now
   local token={Generation=s.RoundState.RoundGeneration,Turn=s.RoundState.TurnToken,PlayerIndex=playerIndex,SessionId=s.Id}
   local ok,filtered=pcall(function()return TextService:FilterStringAsync(value.Text,p.UserId):GetNonChatStringForBroadcastAsync()end);if not ok or filtered==""then reject(remote,p,value.Id,"FILTER_FAILED","That turn could not be filtered. Edit it and try again.");return end
   if Service.Sessions[p]~=s or s.Id~=token.SessionId or not RoundState.matches(s.RoundState,token.Generation,token.Turn,token.PlayerIndex)then reject(remote,p,value.Id,"TURN_EXPIRED","That turn already ended. Your draft was kept.");return end
   local score,reasons,criteria=Definitions.Score(filtered);if score==0 then reject(remote,p,value.Id,"NO_MEANINGFUL_TEXT","Add a readable argument before sending.");return end;profile(p).Points+=score;s.Scores[p]=(s.Scores[p]or 0)+score
   both(s,remote,{Kind="PlayerTurn",UserId=p.UserId,SubmissionId=value.Id,Name=p.DisplayName,Text=filtered,Points=score,Reasons=reasons,Criteria=criteria,RoundTotal=s.Scores[p],Profile=publicProfile(p)})
   s.PreviousCriteria=criteria
   local result=RoundState.completeTurn(s.RoundState,token.Generation,token.Turn,token.PlayerIndex);if result.Complete then completeRound(s,remote)else publishTurn(s,remote)end

  elseif action=="rematch"then local s=Service.Sessions[p];if not s or not s.Closed then return end;s.Rematch[p]=true;both(s,remote,{Kind="RematchStatus",Name=p.DisplayName});if s.Rematch[s.Players[1]]and s.Rematch[s.Players[2]]then s.Round+=1;beginRound(s,remote)end
  elseif action=="leave"then Service.Background[p]=nil;Service.Offers[p]=nil;removeQueued(p);releaseClaim(p);local s=Service.Sessions[p];if s then endSession(s,remote,"A player left the debate.")else publishLobby(remote,p,"READY")end end
 end)
 Players.PlayerAdded:Connect(function(p)task.defer(function()publishLobby(remote,p,"READY")end)end)
 Players.PlayerRemoving:Connect(function(p)Service.Background[p]=nil;local offer=Service.Offers[p];if offer then Service.Offers[offer.BossPlayer]=nil;Service.Offers[offer.QueuedPlayer]=nil end;removeQueued(p);releaseClaim(p);local s=Service.Sessions[p];if s then endSession(s,remote,"A player disconnected.")end;Service.Profiles[p]=nil;Service.LastSubmit[p]=nil;Participation.Disconnect(p)end)
end
return Service
