local TextService=game:GetService("TextService")
local Definitions=require(script.Parent.Parent.Core.MultiplayerDebateDefinitions)
local Service={Queue={},Sessions={},Points={}}
local function send(remote,p,data) if p and p.Parent then remote:FireClient(p,data) end end
local function both(s,remote,data) for _,p in ipairs(s.Players) do send(remote,p,data) end end
local function topicFor(s) return Definitions.Topics[((s.Index-1)%#Definitions.Topics)+1] end
local function nextUnlock(points)
 for _,u in ipairs(Definitions.Unlocks) do if points<u.Points then return u end end
 return Definitions.Unlocks[#Definitions.Unlocks]
end
local function start(remote,a,b)
 local s={Players={a,b},Index=1,PlayerIndex=1,Turns={0,0},Closed=false};Service.Sessions[a]=s;Service.Sessions[b]=s
 local t=topicFor(s);both(s,remote,{Kind="Start",Topic=t,Players={a.DisplayName,b.DisplayName},YourSeat=a==a and 1 or 2,Opening=t.Opening,Rules="Practice points use a visible writing checklist; they are not an AI judgment."})
 send(remote,a,{Kind="Seat",Seat=1});send(remote,b,{Kind="Seat",Seat=2});both(s,remote,{Kind="Turn",UserId=a.UserId,Name=a.DisplayName})
end
local function removeQueued(p) for i=#Service.Queue,1,-1 do if Service.Queue[i]==p then table.remove(Service.Queue,i) end end end
function Service.Init(remote,submit)
 submit.OnServerEvent:Connect(function(p,action,value)
  if action=="queue" then
   if Service.Sessions[p] then return end;removeQueued(p);table.insert(Service.Queue,p);send(remote,p,{Kind="Queued"})
   while #Service.Queue>=2 do local a=table.remove(Service.Queue,1);local b=table.remove(Service.Queue,1);if a.Parent and b.Parent then start(remote,a,b) end end
  elseif action=="argument" then
   local s=Service.Sessions[p];if not s or s.Closed or s.Players[s.PlayerIndex]~=p or type(value)~="string" or #value<2 or #value>Definitions.MaxArgumentBytes then return end
   local ok,filtered=pcall(function() return TextService:FilterStringAsync(value,p.UserId):GetNonChatStringForBroadcastAsync() end)
   if not ok or filtered=="" then send(remote,p,{Kind="Error",Message="That turn could not be filtered."});return end
   local score,reasons=Definitions.Score(filtered);Service.Points[p]=(Service.Points[p] or 0)+score;s.Turns[s.PlayerIndex]+=1
   local t=topicFor(s);both(s,remote,{Kind="PlayerTurn",Name=p.DisplayName,Text=filtered,Points=score,Reasons=reasons,Total=Service.Points[p],NextUnlock=nextUnlock(Service.Points[p])})
   both(s,remote,{Kind="AIReply",Character=t.Character,Text="Scripted AI prompt: the next speaker should address the previous reason, add an example, or challenge a trade-off.",Label="SCRIPTED AI PRACTICE"})
   local done=s.Turns[1]>=Definitions.PlayerTurnsEach and s.Turns[2]>=Definitions.PlayerTurnsEach
   if done then s.Closed=true;both(s,remote,{Kind="Complete",Scores={{Name=s.Players[1].DisplayName,Points=Service.Points[s.Players[1]] or 0},{Name=s.Players[2].DisplayName,Points=Service.Points[s.Players[2]] or 0}},Message="Practice complete. Points reflect the visible writing checklist, not debate truth."})
   else s.PlayerIndex=s.PlayerIndex==1 and 2 or 1;local n=s.Players[s.PlayerIndex];both(s,remote,{Kind="Turn",UserId=n.UserId,Name=n.DisplayName}) end
  elseif action=="leave" then removeQueued(p);local s=Service.Sessions[p];if s then s.Closed=true;for _,q in ipairs(s.Players) do Service.Sessions[q]=nil;send(remote,q,{Kind="Ended",Message="A player left the practice debate."}) end end
  end
 end)
 game:GetService("Players").PlayerRemoving:Connect(function(p) removeQueued(p);local s=Service.Sessions[p];if s then for _,q in ipairs(s.Players) do Service.Sessions[q]=nil;send(remote,q,{Kind="Ended",Message="A player disconnected."}) end end end)
end
return Service
