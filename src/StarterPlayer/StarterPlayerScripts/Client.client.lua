local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage")
local p=Players.LocalPlayer;local r=RS:WaitForChild("BeatTheBotRemotes");local state=r:WaitForChild("MultiplayerDebateState");local submit=r:WaitForChild("MultiplayerDebateSubmit")
local C={bg=Color3.fromRGB(10,16,29),panel=Color3.fromRGB(22,32,50),blue=Color3.fromRGB(73,168,235),gold=Color3.fromRGB(255,194,82),white=Color3.fromRGB(240,245,252),muted=Color3.fromRGB(165,180,200),green=Color3.fromRGB(89,190,130)}
local function corner(x,n)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,n or 10);c.Parent=x end
local function label(pa,t,z,col,b)local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Text=t;l.TextColor3=col or C.white;l.TextSize=z or 14;l.Font=b and Enum.Font.GothamBold or Enum.Font.Gotham;l.TextWrapped=true;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=pa;return l end
local function button(pa,t,col)local b=Instance.new("TextButton");b.Text=t;b.TextColor3=C.white;b.TextSize=14;b.Font=Enum.Font.GothamBold;b.BackgroundColor3=col or C.panel;b.Parent=pa;corner(b,9);return b end
local g=Instance.new("ScreenGui");g.Name="MultiplayerDebateUI";g.ResetOnSpawn=false;g.Parent=p:WaitForChild("PlayerGui")
local badge=label(g,"2 PLAYERS • SCRIPTED AI • SESSION POINTS",12,C.gold,true);badge.Position=UDim2.fromOffset(14,8);badge.Size=UDim2.fromOffset(330,26)
local menu=Instance.new("Frame");menu.AnchorPoint=Vector2.new(1,.5);menu.Position=UDim2.new(1,-14,.5,0);menu.Size=UDim2.fromOffset(142,218);menu.BackgroundColor3=C.bg;menu.Parent=g;corner(menu,12)
local ml=Instance.new("UIListLayout");ml.Padding=UDim.new(0,7);ml.HorizontalAlignment=Enum.HorizontalAlignment.Center;ml.VerticalAlignment=Enum.VerticalAlignment.Center;ml.Parent=menu
local play=button(menu,"FIND DEBATE",C.blue);play.Size=UDim2.new(1,-16,0,44)
local chairs=button(menu,"CHAIRS");chairs.Size=play.Size
local titles=button(menu,"TITLES");titles.Size=play.Size
local profileButton=button(menu,"PROFILE");profileButton.Size=play.Size
local panel=Instance.new("Frame");panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.46,.52);panel.Size=UDim2.new(.8,0,.82,0);panel.BackgroundColor3=C.bg;panel.Visible=false;panel.Parent=g;corner(panel,16)
local pc=Instance.new("UISizeConstraint");pc.MaxSize=Vector2.new(820,700);pc.MinSize=Vector2.new(310,440);pc.Parent=panel
local title=label(panel,"WAITING FOR ANOTHER PLAYER",22,C.white,true);title.Position=UDim2.fromOffset(18,12);title.Size=UDim2.new(1,-36,0,34)
local topic=label(panel,"Two players take turns responding to the AI.",13,C.gold,true);topic.Position=UDim2.fromOffset(18,48);topic.Size=UDim2.new(1,-36,0,48)
local turn=label(panel,"",14,C.green,true);turn.Position=UDim2.fromOffset(18,96);turn.Size=UDim2.new(1,-36,0,28)
local log=Instance.new("ScrollingFrame");log.Position=UDim2.fromOffset(18,128);log.Size=UDim2.new(1,-36,1,-240);log.BackgroundColor3=C.panel;log.AutomaticCanvasSize=Enum.AutomaticSize.Y;log.CanvasSize=UDim2.new();log.BorderSizePixel=0;log.Parent=panel;corner(log,10)
local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,8);ll.Parent=log
local box=Instance.new("TextBox");box.PlaceholderText="Give a reason, example, or rebuttal…";box.Text="";box.MultiLine=true;box.TextWrapped=true;box.TextColor3=C.white;box.PlaceholderColor3=C.muted;box.TextSize=14;box.Font=Enum.Font.Gotham;box.BackgroundColor3=C.panel;box.Position=UDim2.new(0,18,1,-98);box.Size=UDim2.new(1,-146,0,78);box.Parent=panel;corner(box,10)
local send=button(panel,"SEND TURN",C.blue);send.Position=UDim2.new(1,-116,1,-98);send.Size=UDim2.fromOffset(98,78);send.Active=false;send.AutoButtonColor=false
local queued=false
local myTurn=false
local rematch=button(panel,"REMATCH",C.green);rematch.Position=UDim2.new(0,18,1,-138);rematch.Size=UDim2.fromOffset(112,34);rematch.Visible=false
local function popup(heading,body)local f=Instance.new("Frame");f.AnchorPoint=Vector2.new(1,.5);f.Position=UDim2.new(1,-164,.5,0);f.Size=UDim2.fromOffset(280,260);f.BackgroundColor3=C.bg;f.Parent=g;corner(f,12);local h=label(f,heading,20,C.gold,true);h.Position=UDim2.fromOffset(16,12);h.Size=UDim2.new(1,-32,0,30);local b=label(f,body,14,C.white);b.Position=UDim2.fromOffset(16,48);b.Size=UDim2.new(1,-32,1,-64);b.TextYAlignment=Enum.TextYAlignment.Top;task.delay(6,function()if f.Parent then f:Destroy()end end)end
chairs.Activated:Connect(function()popup("CHAIRS","Starter Chair — owned\nBlue Chair — 30 points\nGold Chair — 100 points\n\nSession preview only; no purchase or persistence.")end)
titles.Activated:Connect(function()popup("TITLES","Debater — owned\nClear Thinker — 60 points\n\nSession preview only; no purchase or persistence.")end)
profileButton.Activated:Connect(function()submit:FireServer("profile")end)
rematch.Activated:Connect(function()submit:FireServer("rematch");rematch.Text="WAITING…";rematch.Active=false end)
local function row(who,text,col)local x=label(log,who.."\n"..text,14,col,who~="SYSTEM");x.Size=UDim2.new(1,-18,0,68);x.AutomaticSize=Enum.AutomaticSize.Y;x.TextYAlignment=Enum.TextYAlignment.Top;x.Parent=log;return x end
play.Activated:Connect(function()panel.Visible=true;if queued then submit:FireServer("cancelQueue")else submit:FireServer("queue")end end)
send.Activated:Connect(function()if myTurn and box.Text~=""then submit:FireServer("argument",box.Text);box.Text="";myTurn=false;send.Text="WAIT"end end)
state.OnClientEvent:Connect(function(m)
 if m.Kind=="Lobby"then queued=m.Status=="QUEUED";play.Text=queued and "CANCEL SEARCH" or "FIND DEBATE";if queued then panel.Visible=true;title.Text="WAITING FOR ANOTHER PLAYER";topic.Text=("Players waiting: %d"):format(m.QueueSize or 1)end
 elseif m.Kind=="Profile"then local x=m.Profile;popup("PROFILE",("Session points: %d\nChair: %s\nTitle: %s\n\nProgress resets when this server closes."):format(x.Points,x.Chair,x.Title))
 elseif m.Kind=="Start"then rematch.Visible=false;rematch.Text="REMATCH";rematch.Active=true;queued=false;play.Text="FIND DEBATE";title.Text=m.Players[1].Name.."  vs  "..m.Players[2].Name;topic.Text=m.Topic.Topic.."\nAI position: "..m.Topic.AIPosition;for _,x in ipairs(log:GetChildren())do if x:IsA("TextLabel")then x:Destroy()end end;row("AI OPENING",m.Opening,C.gold);row("SCORING",m.Rules.." Base +10, reason +5, example +5, rebuttal +5.",C.muted)
 elseif m.Kind=="Turn"then myTurn=m.UserId==p.UserId;turn.Text=myTurn and "YOUR TURN" or (m.Name.." IS THINKING");send.Text=myTurn and "SEND TURN" or "WAIT";send.Active=myTurn;send.AutoButtonColor=myTurn
 elseif m.Kind=="PlayerTurn"then row(m.Name.."  +"..m.Points,m.Text.."\n"..table.concat(m.Reasons," • "),C.white)
 elseif m.Kind=="AIReply"then row(m.Label,m.Text,C.gold)
 elseif m.Kind=="Complete"then myTurn=false;send.Text="COMPLETE";turn.Text=m.Message;rematch.Visible=true;for _,s in ipairs(m.Scores)do row("SCORE",s.Name..": "..s.Points.." session points",C.green)end
 elseif m.Kind=="TurnTimedOut"then myTurn=false;row("SYSTEM",m.Message,C.gold)
 elseif m.Kind=="RematchStatus"then row("SYSTEM",m.Name.." wants another round.",C.green)
 elseif m.Kind=="Ended"or m.Kind=="Error"then myTurn=false;row("SYSTEM",m.Message,C.gold)end
 log.CanvasPosition=Vector2.new(0,99999)
end)
