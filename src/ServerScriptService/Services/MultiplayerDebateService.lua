local Players=game:GetService("Players")
local TextService=game:GetService("TextService")
local Definitions=require(script.Parent.Parent.Core.MultiplayerDebateDefinitions)
local Protocol=require(script.Parent.Parent.Core.DebateProtocol)
local Service={Queue={},Sessions={},Profiles={},LastSubmit={}}
local function profile(p)
 local x=Service.Profiles[p];if not x then x={Points=0,Chair="starter-chair",Title="Debater"};Service.Profiles[p]=x end;return x
end
local function send(remote,p,data) if p and p.Parent then remote:FireClient(p,data) end end
local function both(s,remote,data) for _,p in ipairs(s.Players) do send(remote,p,data) end end
local function unlocks(points)local owned={};for _,u in ipairs(Definitions.Unlocks)do if points>=u.Points then owned[u.Id]=true end end;return owned end
local function publicProfile(p)local x=profile(p);return {Points=x.Points,Chair=x.Chair,Title=x.Title,Unlocks=unlocks(x.Points)}end
local function topicFor(s)return Definitions.Topics[((s.Round-1)%#Definitions.Topics)+1]end
local function publishLobby(remote,p,status)send(remote,p,Protocol.Lobby(status,publicProfile(p),#Service.Queue))end
local function publishProfile(remote,p)send(remote,p,Protocol.Profile(publicProfile(p)))end
local function beginRound(s,remote)
 s.Turns={0,0};s.PlayerIndex=(s.Round%2)+1;s.Closed=false;s.Rematch={};local t=topicFor(s)
 both(s,remote,Protocol.Start(s.Round,t,{Name=s.Players[1].DisplayName,UserId=s.Players[1].UserId,Profile=publicProfile(s.Players[1])},{Name=s.Players[2].DisplayName,UserId=s.Players[2].UserId,Profile=publicProfile(s.Players[2])},t.Opening,"Session points use a visible writing checklist; they are not an AI judgment."))
 local n=s.Players[s.PlayerIndex];both(s,remote,{Kind="Turn",UserId=n.UserId,Name=n.DisplayName,TurnNumber=1})
end
local function start(remote,a,b)local s={Players={a,b},Round=1,Scores={[a]=0,[b]=0}};Service.Sessions[a]=s;Service.Sessions[b]=s;beginRound(s,remote)end
local function removeQueued(p)for i=#Service.Queue,1,-1 do if Service.Queue[i]==p then table.remove(Service.Queue,i)end end end
local function endSession(s,remote,message)
 for _,q in ipairs(s.Players)do Service.Sessions[q]=nil;send(remote,q,{Kind="Ended",Message=message,Profile=publicProfile(q)})end
end
function Service.Init(remote,submit)
 submit.OnServerEvent:Connect(function(p,action,value)
  if action=="queue"then if Service.Sessions[p]then return end;removeQueued(p);table.insert(Service.Queue,p);publishLobby(remote,p,"QUEUED");while #Service.Queue>=2 do local a=table.remove(Service.Queue,1);local b=table.remove(Service.Queue,1);if a.Parent==Players and b.Parent==Players then start(remote,a,b)elseif a.Parent==Players then table.insert(Service.Queue,1,a)elseif b.Parent==Players then table.insert(Service.Queue,1,b)end end
  elseif action=="cancelQueue"then removeQueued(p);publishLobby(remote,p,"READY")
  elseif action=="profile"then publishProfile(remote,p)
  elseif action=="equip"and type(value)=="table"then local x=profile(p);local owned=unlocks(x.Points);if value.Kind=="chair"and owned[value.Id]then x.Chair=value.Id elseif value.Kind=="title"and owned[value.Id]then x.Title=value.Id end;publishLobby(remote,p,"READY")
  elseif action=="argument"then
   local now=os.clock();if now-(Service.LastSubmit[p]or 0)<1 then return end;Service.LastSubmit[p]=now
   local s=Service.Sessions[p];if not s or s.Closed or s.Players[s.PlayerIndex]~=p or type(value)~="string"or #value<2 or #value>Definitions.MaxArgumentBytes then return end
   local ok,filtered=pcall(function()return TextService:FilterStringAsync(value,p.UserId):GetNonChatStringForBroadcastAsync()end);if not ok or filtered==""then send(remote,p,{Kind="Error",Message="That turn could not be filtered."});return end
   local score,reasons=Definitions.Score(filtered);profile(p).Points+=score;s.Scores[p]=(s.Scores[p]or 0)+score;s.Turns[s.PlayerIndex]+=1
   both(s,remote,{Kind="PlayerTurn",Name=p.DisplayName,Text=filtered,Points=score,Reasons=reasons,RoundTotal=s.Scores[p],Profile=publicProfile(p)})
   local t=topicFor(s);both(s,remote,{Kind="AIReply",Character=t.Character,Text="Scripted AI prompt: the next speaker should address the previous reason, add an example, or challenge a trade-off.",Label="SCRIPTED AI PRACTICE"})
   if s.Turns[1]>=Definitions.PlayerTurnsEach and s.Turns[2]>=Definitions.PlayerTurnsEach then s.Closed=true;both(s,remote,{Kind="Complete",Round=s.Round,Scores={{Name=s.Players[1].DisplayName,Points=s.Scores[s.Players[1]]},{Name=s.Players[2].DisplayName,Points=s.Scores[s.Players[2]]}},Message="Round complete. Points reflect the visible checklist, not debate truth."})else s.PlayerIndex=s.PlayerIndex==1 and 2 or 1;local n=s.Players[s.PlayerIndex];both(s,remote,{Kind="Turn",UserId=n.UserId,Name=n.DisplayName,TurnNumber=s.Turns[s.PlayerIndex]+1})end
  elseif action=="rematch"then local s=Service.Sessions[p];if not s or not s.Closed then return end;s.Rematch[p]=true;both(s,remote,{Kind="RematchStatus",Name=p.DisplayName});if s.Rematch[s.Players[1]]and s.Rematch[s.Players[2]]then s.Round+=1;beginRound(s,remote)end
  elseif action=="leave"then removeQueued(p);local s=Service.Sessions[p];if s then endSession(s,remote,"A player left the debate.")else publishLobby(remote,p,"READY")end end
 end)
 Players.PlayerAdded:Connect(function(p)task.defer(function()publishLobby(remote,p,"READY")end)end)
 Players.PlayerRemoving:Connect(function(p)removeQueued(p);local s=Service.Sessions[p];if s then endSession(s,remote,"A player disconnected.")end;Service.Profiles[p]=nil;Service.LastSubmit[p]=nil end)
end
return Service
