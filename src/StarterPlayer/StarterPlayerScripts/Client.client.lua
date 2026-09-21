local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage")
local p=Players.LocalPlayer;local BossController=require(script.Parent.BossDebateController);local r=RS:WaitForChild("BeatTheBotRemotes");local state=r:WaitForChild("MultiplayerDebateState");local submit=r:WaitForChild("MultiplayerDebateSubmit")
local C={bg=Color3.fromRGB(10,16,29),panel=Color3.fromRGB(22,32,50),blue=Color3.fromRGB(73,168,235),gold=Color3.fromRGB(255,194,82),white=Color3.fromRGB(240,245,252),muted=Color3.fromRGB(165,180,200),green=Color3.fromRGB(89,190,130)}
local function corner(x,n)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,n or 10);c.Parent=x end
local function label(pa,t,z,col,b)local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Text=t;l.TextColor3=col or C.white;l.TextSize=z or 14;l.Font=b and Enum.Font.GothamBold or Enum.Font.Gotham;l.TextWrapped=true;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=pa;return l end
local function button(pa,t,col)local b=Instance.new("TextButton");b.Text=t;b.TextColor3=C.white;b.TextSize=14;b.Font=Enum.Font.GothamBold;b.BackgroundColor3=col or C.panel;b.Parent=pa;corner(b,9);return b end
local g=Instance.new("ScreenGui");g.Name="MultiplayerDebateUI";g.ResetOnSpawn=false;g.Parent=p:WaitForChild("PlayerGui")
local MAX_ARGUMENT_BYTES=500 -- mirrors authoritative server limit
local badge=label(g,"2 PLAYERS • SCRIPTED AI • SESSION POINTS",12,C.gold,true);badge.Position=UDim2.fromOffset(14,8);badge.Size=UDim2.fromOffset(330,26)
local menu=Instance.new("Frame");menu.AnchorPoint=Vector2.new(1,.5);menu.Position=UDim2.new(1,-14,.5,0);menu.Size=UDim2.fromOffset(142,218);menu.BackgroundColor3=C.bg;menu.Parent=g;corner(menu,12)
local ml=Instance.new("UIListLayout");ml.Padding=UDim.new(0,7);ml.HorizontalAlignment=Enum.HorizontalAlignment.Center;ml.VerticalAlignment=Enum.VerticalAlignment.Center;ml.Parent=menu
local play=button(menu,"FIND DEBATE",C.blue);play.Size=UDim2.new(1,-16,0,44)
local chairs=button(menu,"CHAIRS");chairs.Size=play.Size
local titles=button(menu,"TITLES");titles.Size=play.Size
local profileButton=button(menu,"PROFILE");profileButton.Size=play.Size
BossController.Init(r,g,button,label,C)
local onboarding=Instance.new("Frame");onboarding.Name="FirstSessionOnboarding";onboarding.AnchorPoint=Vector2.new(.5,.5);onboarding.Position=UDim2.fromScale(.5,.5);onboarding.Size=UDim2.new(.84,0,.72,0);onboarding.BackgroundColor3=C.bg;onboarding.ZIndex=20;onboarding.Parent=g;corner(onboarding,16)
local oc=Instance.new("UISizeConstraint");oc.MaxSize=Vector2.new(680,520);oc.MinSize=Vector2.new(300,360);oc.Parent=onboarding
local oh=label(onboarding,"WELCOME TO THE SCRIPTED CHECKLIST PANEL",24,C.gold,true);oh.Position=UDim2.fromOffset(24,22);oh.Size=UDim2.new(1,-48,0,66);oh.TextXAlignment=Enum.TextXAlignment.Center;oh.ZIndex=21
local ob=label(onboarding,"1  YOU ARE ASSIGNED A SIDE\nArgue that position, even when it is not your personal view.\n\n2  THREE TURNS • 45 SECONDS EACH\nOpening, rebuttal, then closing.\n\n3  THREE VISIBLE CHECKS\nRIVET: reason words like because\nPIP: an example or scenario\nMOSS: a rebuttal marked by however or but\n\nSCRIPTED PRACTICE • NOT A REAL OPPONENT\nThe panel detects writing markers. It does not judge truth or argument quality.",16,C.white);ob.Position=UDim2.fromOffset(30,96);ob.Size=UDim2.new(1,-60,1,-170);ob.TextYAlignment=Enum.TextYAlignment.Top;ob.TextXAlignment=Enum.TextXAlignment.Center;ob.ZIndex=21
local dismiss=button(onboarding,"ENTER ARENA",C.blue);dismiss.AnchorPoint=Vector2.new(.5,1);dismiss.Position=UDim2.new(.5,0,1,-22);dismiss.Size=UDim2.fromOffset(190,48);dismiss.ZIndex=21;dismiss.Activated:Connect(function()onboarding.Visible=false end);task.delay(30,function()if onboarding.Parent then onboarding.Visible=false end end)
local panel=Instance.new("Frame");panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.46,.52);panel.Size=UDim2.new(.8,0,.82,0);panel.BackgroundColor3=C.bg;panel.Visible=false;panel.Parent=g;corner(panel,16)
local pc=Instance.new("UISizeConstraint");pc.MaxSize=Vector2.new(820,700);pc.MinSize=Vector2.new(310,440);pc.Parent=panel
local title=label(panel,"WAITING FOR ANOTHER PLAYER",22,C.white,true);title.Position=UDim2.fromOffset(18,12);title.Size=UDim2.new(1,-36,0,34)
local topic=label(panel,"Two players take turns responding to the AI.",13,C.gold,true);topic.Position=UDim2.fromOffset(18,48);topic.Size=UDim2.new(1,-36,0,48)
local turn=label(panel,"",14,C.green,true);turn.Position=UDim2.fromOffset(18,96);turn.Size=UDim2.new(1,-36,0,28)
local log=Instance.new("ScrollingFrame");log.Position=UDim2.fromOffset(18,128);log.Size=UDim2.new(1,-36,1,-240);log.BackgroundColor3=C.panel;log.AutomaticCanvasSize=Enum.AutomaticSize.Y;log.CanvasSize=UDim2.new();log.BorderSizePixel=0;log.Parent=panel;corner(log,10)
local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,8);ll.Parent=log
local box=Instance.new("TextBox");box.PlaceholderText="Give a reason, example, or rebuttal…";box.Text="";box.MultiLine=true;box.TextWrapped=true;box.TextColor3=C.white;box.PlaceholderColor3=C.muted;box.TextSize=14;box.Font=Enum.Font.Gotham;box.BackgroundColor3=C.panel;box.Position=UDim2.new(0,18,1,-98);box.Size=UDim2.new(1,-146,0,78);box.Parent=panel;corner(box,10)
local counter=label(panel,"0 / 500 bytes",11,C.muted);counter.Position=UDim2.new(0,18,1,-118);counter.Size=UDim2.new(1,-146,0,18)
box:GetPropertyChangedSignal("Text"):Connect(function()local bytes=#box.Text;counter.Text=("%d / %d bytes"):format(bytes,MAX_ARGUMENT_BYTES);counter.TextColor3=bytes>MAX_ARGUMENT_BYTES and C.gold or C.muted end)
local send=button(panel,"SEND TURN",C.blue);send.Position=UDim2.new(1,-116,1,-98);send.Size=UDim2.fromOffset(98,78);send.Active=false;send.AutoButtonColor=false
local queued=false
local nextSubmissionId=0
local pendingSubmissionId=nil
local pendingText=nil
local myTurn=false
local rematch=button(panel,"REMATCH",C.green);rematch.Position=UDim2.new(0,18,1,-138);rematch.Size=UDim2.fromOffset(112,34);rematch.Visible=false
local function popup(heading,body)local f=Instance.new("Frame");f.AnchorPoint=Vector2.new(1,.5);f.Position=UDim2.new(1,-164,.5,0);f.Size=UDim2.fromOffset(280,260);f.BackgroundColor3=C.bg;f.Parent=g;corner(f,12);local h=label(f,heading,20,C.gold,true);h.Position=UDim2.fromOffset(16,12);h.Size=UDim2.new(1,-32,0,30);local b=label(f,body,14,C.white);b.Position=UDim2.fromOffset(16,48);b.Size=UDim2.new(1,-32,1,-64);b.TextYAlignment=Enum.TextYAlignment.Top;task.delay(6,function()if f.Parent then f:Destroy()end end)end
chairs.Activated:Connect(function()popup("CHAIRS","Starter Chair — owned\nBlue Chair — 30 points\nGold Chair — 100 points\n\nSession preview only; no purchase or persistence.")end)
titles.Activated:Connect(function()popup("TITLES","Debater — owned\nClear Thinker — 60 points\n\nSession preview only; no purchase or persistence.")end)
profileButton.Activated:Connect(function()submit:FireServer("profile")end)
rematch.Activated:Connect(function()submit:FireServer("rematch");rematch.Text="WAITING…";rematch.Active=false end)
local function row(who,text,col)local x=label(log,who.."\n"..text,14,col,who~="SYSTEM");x.Size=UDim2.new(1,-18,0,68);x.AutomaticSize=Enum.AutomaticSize.Y;x.TextYAlignment=Enum.TextYAlignment.Top;x.Parent=log;return x end
local function countScore(name,points)local x=row("SCORE",name..": 0 session points",C.green);task.spawn(function()for value=1,points do if not x.Parent then return end;x.Text="SCORE\n"..name..": "..value.." session points";task.wait(.035)end end)end
play.Activated:Connect(function()panel.Visible=true;if queued then submit:FireServer("cancelQueue")else submit:FireServer("queue")end end)
send.Activated:Connect(function()if not myTurn or pendingSubmissionId~=nil or box.Text==""then return end;nextSubmissionId+=1;pendingSubmissionId=nextSubmissionId;pendingText=box.Text;submit:FireServer("argument",{Id=pendingSubmissionId,Text=pendingText});send.Text="SENDING…";send.Active=false;send.AutoButtonColor=false end)
state.OnClientEvent:Connect(function(m)
 if m.Kind=="Lobby"then queued=m.Status=="QUEUED";play.Text=queued and "CANCEL SEARCH" or "FIND DEBATE";if queued then panel.Visible=true;title.Text="WAITING FOR ANOTHER PLAYER";topic.Text=("Players waiting: %d"):format(m.QueueSize or 1)end
 elseif m.Kind=="Profile"then local x=m.Profile;popup("PROFILE",("Session points: %d\nChair: %s\nTitle: %s\n\nProgress resets when this server closes."):format(x.Points,x.Chair,x.Title))
 elseif m.Kind=="Start"then rematch.Visible=false;rematch.Text="REMATCH";rematch.Active=true;queued=false;play.Text="FIND DEBATE";title.Text=m.Players[1].Name.."  vs  "..m.Players[2].Name;topic.Text=m.Topic.Topic.."\nYour assigned side appears with each turn.";for _,x in ipairs(log:GetChildren())do if x:IsA("TextLabel")then x:Destroy()end end;row("SCRIPTED HOST",m.Opening,C.gold);row("SCORING",m.Rules.." Base +10, reason +5, example +5, rebuttal +5.",C.muted)
 elseif m.Kind=="Turn"then myTurn=m.UserId==p.UserId;turn.Text=(myTurn and "YOUR TURN" or (m.Name.." IS THINKING")).." • "..m.Role.." • "..m.Side;if myTurn then row("SCRIPTED HOST",m.HostPrompt,C.gold)end;send.Text=myTurn and "SEND TURN" or "WAIT";send.Active=myTurn;send.AutoButtonColor=myTurn
 elseif m.Kind=="PlayerTurn"then if m.UserId==p.UserId and m.SubmissionId==pendingSubmissionId then pendingSubmissionId=nil;pendingText=nil;box.Text="";myTurn=false end;row(m.Name.."  +"..m.Points,m.Text.."\n"..table.concat(m.Reasons," • "),C.white);for _,reaction in ipairs(m.JudgeReactions or {})do row(reaction.Judge.." • "..(reaction.Earned and "+5"or"NOT DETECTED"),reaction.Commentary.."\n"..reaction.Label,reaction.Earned and C.green or C.muted)end
 elseif m.Kind=="AIReply"then row(m.Label,m.Text,C.gold)
 elseif m.Kind=="Complete"then myTurn=false;send.Text="COMPLETE";turn.Text=m.Message;rematch.Visible=true;for index,verdict in ipairs((m.Panel and m.Panel.Lines)or{})do task.delay((index-1)*.7,function()row(verdict.Judge,verdict.Text,C.gold)end)end;task.delay(2.3,function()row("PANEL DISCLOSURE",m.Panel and m.Panel.Disclosure or "SCRIPTED PRACTICE — checklist totals only.",C.muted);for _,s in ipairs(m.Scores)do countScore(s.Name,s.Points)end end)
 elseif m.Kind=="TenSecondWarning"then if m.UserId==p.UserId then row("10 SECONDS","Finish and send your current turn.",C.gold)end
 elseif m.Kind=="ArgumentRejected"then if m.SubmissionId==pendingSubmissionId or m.SubmissionId==nil then pendingSubmissionId=nil;if pendingText then box.Text=pendingText end;pendingText=nil;myTurn=m.CanRetry==true;send.Text=myTurn and "SEND TURN" or "WAIT";send.Active=myTurn;send.AutoButtonColor=myTurn;row("SYSTEM",m.Message,C.gold)end
 elseif m.Kind=="TurnTimedOut"then myTurn=false;row("SYSTEM",m.Message,C.gold)
 elseif m.Kind=="RematchStatus"then row("SYSTEM",m.Name.." wants another round.",C.green)
 elseif m.Kind=="Ended"or m.Kind=="Error"then myTurn=false;row("SYSTEM",m.Message,C.gold)end
 log.CanvasPosition=Vector2.new(0,99999)
end)
