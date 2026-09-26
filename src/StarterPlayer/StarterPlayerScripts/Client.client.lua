local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage");local TweenService=game:GetService("TweenService")
local p=Players.LocalPlayer;local BossController=require(script.Parent:WaitForChild("BossDebateController"));local r=RS:WaitForChild("BeatTheBotRemotes");local state=r:WaitForChild("MultiplayerDebateState");local submit=r:WaitForChild("MultiplayerDebateSubmit")
local C={bg=Color3.fromRGB(22,31,46),panel=Color3.fromRGB(35,48,68),card=Color3.fromRGB(44,58,80),blue=Color3.fromRGB(73,168,235),gold=Color3.fromRGB(255,194,82),white=Color3.fromRGB(244,248,252),muted=Color3.fromRGB(181,194,211),green=Color3.fromRGB(89,190,130)}
local function corner(x,n)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,n or 10);c.Parent=x end
local function stroke(x,col,transparency,thickness)local s=Instance.new("UIStroke");s.Color=col or C.blue;s.Transparency=transparency or .55;s.Thickness=thickness or 1;s.Parent=x;return s end
local function label(pa,t,z,col,b)local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Text=t;l.TextColor3=col or C.white;l.TextSize=z or 14;l.Font=b and Enum.Font.GothamBold or Enum.Font.Gotham;l.TextWrapped=true;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=pa;return l end
local function button(pa,t,col)local b=Instance.new("TextButton");b.Text=t;b.TextColor3=C.white;b.TextSize=14;b.Font=Enum.Font.GothamBold;b.BackgroundColor3=col or C.panel;b.Parent=pa;corner(b,9);stroke(b,C.blue,.7,1);return b end
local g=Instance.new("ScreenGui");g.Name="MultiplayerDebateUI";g.ResetOnSpawn=false;g.Parent=p:WaitForChild("PlayerGui")
local MAX_ARGUMENT_BYTES=500 -- mirrors authoritative server limit
local badge=label(g,"GUARDIAN DEBATE ARENA • REAL PLAYER DEBATE OR SCRIPTED SOLO PRACTICE",12,C.gold,true);badge.Position=UDim2.fromOffset(14,8);badge.Size=UDim2.fromOffset(480,26)
local menu=Instance.new("Frame");menu.AnchorPoint=Vector2.new(1,.5);menu.Position=UDim2.new(1,-14,.5,0);menu.Size=UDim2.fromOffset(142,218);menu.BackgroundColor3=C.bg;menu.Parent=g;corner(menu,12)
local ml=Instance.new("UIListLayout");ml.Padding=UDim.new(0,7);ml.HorizontalAlignment=Enum.HorizontalAlignment.Center;ml.VerticalAlignment=Enum.VerticalAlignment.Center;ml.Parent=menu
local play=button(menu,"DEBATE A REAL PLAYER",C.blue);play.Size=UDim2.new(1,-16,0,44)
local chairs=button(menu,"CHAIRS");chairs.Size=play.Size
local titles=button(menu,"TITLES");titles.Size=play.Size
local profileButton=button(menu,"PROFILE");profileButton.Size=play.Size
BossController.Init(r,g,button,label,C)
local onboarding=Instance.new("Frame");onboarding.Name="FirstSessionOnboarding";onboarding.AnchorPoint=Vector2.new(.5,.5);onboarding.Position=UDim2.fromScale(.5,.5);onboarding.Size=UDim2.new(.84,0,.72,0);onboarding.BackgroundColor3=C.bg;onboarding.ZIndex=20;onboarding.Parent=g;corner(onboarding,16)
local oc=Instance.new("UISizeConstraint");oc.MaxSize=Vector2.new(680,520);oc.MinSize=Vector2.new(300,360);oc.Parent=onboarding
local oh=label(onboarding,"WELCOME TO THE GUARDIAN DEBATE ARENA",24,C.gold,true);oh.Position=UDim2.fromOffset(24,22);oh.Size=UDim2.new(1,-48,0,66);oh.TextXAlignment=Enum.TextXAlignment.Center;oh.ZIndex=21
local ob=label(onboarding,"1  TAKE A POSITION\nYou are assigned FOR or AGAINST after the topic is chosen.\n\n2  BUILD AN ARGUMENT\nOpening, rebuttal, then closing. Use the prompt chips when you get stuck.\n\n3  WATCH THE GUARDIANS REACT\nRIVET looks for a clear reason, PIP for a concrete example, and MOSS for a rebuttal signal.\n\nSCRIPTED PRACTICE • NOT A REAL OPPONENT\nThese reactions are writing-pattern feedback, not truth or argument-quality judgments.",16,C.white);ob.Position=UDim2.fromOffset(30,96);ob.Size=UDim2.new(1,-60,1,-170);ob.TextYAlignment=Enum.TextYAlignment.Top;ob.TextXAlignment=Enum.TextXAlignment.Center;ob.ZIndex=21
local cameraIntroActive=false
local function finishCameraIntro()
 if not cameraIntroActive then return end;cameraIntroActive=false;local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Custom
 local character=p.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid");if humanoid then camera.CameraSubject=humanoid end
end
local dismiss=button(onboarding,"ENTER ARENA",C.blue);dismiss.AnchorPoint=Vector2.new(.5,1);dismiss.Position=UDim2.new(.5,0,1,-22);dismiss.Size=UDim2.fromOffset(190,48);dismiss.ZIndex=21;dismiss.Activated:Connect(function()onboarding.Visible=false;finishCameraIntro()end);task.delay(30,function()if onboarding.Parent then onboarding.Visible=false;finishCameraIntro()end end)
task.spawn(function()
 local stage=workspace:WaitForChild("BeatTheBotDebateStage",10);if not stage or not onboarding.Visible then return end
 local anchor=stage:FindFirstChild("ArenaCameraAnchor");local focus=stage:FindFirstChild("ArenaCameraFocus");if not anchor or not focus then return end
 local camera=workspace.CurrentCamera;cameraIntroActive=true;camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=anchor.CFrame
 local destination=CFrame.lookAt(Vector3.new(0,14,29),focus.Position);local tween=TweenService:Create(camera,TweenInfo.new(2.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=destination});tween:Play()
 task.delay(2.5,finishCameraIntro)
end)
local panel=Instance.new("Frame");panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.46,.52);panel.Size=UDim2.new(.8,0,.82,0);panel.BackgroundColor3=C.bg;panel.Visible=false;panel.Parent=g;corner(panel,16)
local pc=Instance.new("UISizeConstraint");pc.MaxSize=Vector2.new(820,700);pc.MinSize=Vector2.new(310,440);pc.Parent=panel
local title=label(panel,"WAITING FOR ANOTHER PLAYER",22,C.white,true);title.Position=UDim2.fromOffset(18,12);title.Size=UDim2.new(1,-140,0,34);local panelLeave=button(panel,"LEAVE",C.panel);panelLeave.Name="LeaveDebate";panelLeave.AnchorPoint=Vector2.new(1,0);panelLeave.Position=UDim2.new(1,-14,0,12);panelLeave.Size=UDim2.fromOffset(110,34);panelLeave.ZIndex=10
local topic=label(panel,"Two players take turns making and answering arguments.",13,C.gold,true);topic.Position=UDim2.fromOffset(18,48);topic.Size=UDim2.new(1,-36,0,48)
local turn=label(panel,"",14,C.green,true);turn.Position=UDim2.fromOffset(18,96);turn.Size=UDim2.new(1,-36,0,28)
local scoreline=label(panel,"PANEL SIGNALS • RIVET reason • PIP example • MOSS rebuttal",11,C.muted,true);scoreline.Position=UDim2.fromOffset(18,122);scoreline.Size=UDim2.new(1,-36,0,24)
local log=Instance.new("ScrollingFrame");log.Position=UDim2.fromOffset(18,150);log.Size=UDim2.new(1,-36,1,-318);log.BackgroundColor3=C.panel;log.AutomaticCanvasSize=Enum.AutomaticSize.Y;log.CanvasSize=UDim2.new();log.BorderSizePixel=0;log.Parent=panel;corner(log,10);stroke(log,C.blue,.82,1)
local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,8);ll.Parent=log
local box=Instance.new("TextBox");box.PlaceholderText="Give a reason, example, or rebuttal…";box.Text="";box.MultiLine=true;box.TextWrapped=true;box.TextColor3=C.white;box.PlaceholderColor3=C.muted;box.TextSize=14;box.Font=Enum.Font.Gotham;box.BackgroundColor3=C.panel;box.Position=UDim2.new(0,18,1,-98);box.Size=UDim2.new(1,-146,0,78);box.Parent=panel;corner(box,10)
local queued=false
local nextSubmissionId=0
local pendingSubmissionId=nil
local pendingText=nil
local myTurn=false
local assist=Instance.new("Frame");assist.Name="ArgumentAssist";assist.BackgroundTransparency=1;assist.Position=UDim2.new(0,18,1,-162);assist.Size=UDim2.new(1,-36,0,34);assist.Parent=panel
local assistLayout=Instance.new("UIListLayout");assistLayout.FillDirection=Enum.FillDirection.Horizontal;assistLayout.Padding=UDim.new(0,7);assistLayout.HorizontalAlignment=Enum.HorizontalAlignment.Left;assistLayout.Parent=assist
local assistButtons={}
local function addAssist(textValue,starter)
 local b=button(assist,textValue,C.card);b.Size=UDim2.new(.31,-4,1,0);b.TextSize=12;b.Active=false;b.AutoButtonColor=false
 b.Activated:Connect(function()if not myTurn or pendingSubmissionId~=nil then return end;local prefix=box.Text==""and""or(box.Text:sub(-1)==" "and""or" ");box.Text=box.Text..prefix..starter;box.CursorPosition=#box.Text+1;box:CaptureFocus()end)
 table.insert(assistButtons,b)
end
local counter=label(panel,"0 / 500 bytes",11,C.muted);counter.Position=UDim2.new(0,18,1,-122);counter.Size=UDim2.new(1,-146,0,18)
box:GetPropertyChangedSignal("Text"):Connect(function()local bytes=#box.Text;counter.Text=("%d / %d bytes"):format(bytes,MAX_ARGUMENT_BYTES);counter.TextColor3=bytes>MAX_ARGUMENT_BYTES and C.gold or C.muted end)
local send=button(panel,"SEND TURN",C.blue);send.Position=UDim2.new(1,-116,1,-98);send.Size=UDim2.fromOffset(98,78);send.Active=false;send.AutoButtonColor=false
addAssist("REASON","Because ");addAssist("EXAMPLE","For example, ");addAssist("REBUTTAL","However, ")
local function setAssistEnabled(enabled)for _,b in ipairs(assistButtons)do b.Active=enabled;b.AutoButtonColor=enabled;b.BackgroundColor3=enabled and C.card or C.panel end end
local rematch=button(panel,"REMATCH",C.green);rematch.Position=UDim2.new(0,18,1,-138);rematch.Size=UDim2.fromOffset(112,34);rematch.Visible=false
local topicChoice=Instance.new("Frame");topicChoice.Name="TopicChoice";topicChoice.Position=UDim2.fromOffset(18,96);topicChoice.Size=UDim2.new(1,-36,1,-116);topicChoice.BackgroundColor3=C.bg;topicChoice.ZIndex=8;topicChoice.Visible=false;topicChoice.Parent=panel;corner(topicChoice,12)
local topicChoiceTitle=label(topicChoice,"CHOOSE THE TOPIC",18,C.gold,true);topicChoiceTitle.Position=UDim2.fromOffset(14,12);topicChoiceTitle.Size=UDim2.new(1,-28,0,52);topicChoiceTitle.TextXAlignment=Enum.TextXAlignment.Center;topicChoiceTitle.ZIndex=9
local topicButtons={};local topicConnections={};for index=1,3 do local choice=button(topicChoice,"",C.panel);choice.Position=UDim2.new(0,14,0,72+(index-1)*94);choice.Size=UDim2.new(1,-28,0,78);choice.TextWrapped=true;choice.ZIndex=9;topicButtons[index]=choice end
local function showTopicChoice(message)
 for _,connection in ipairs(topicConnections)do connection:Disconnect()end;table.clear(topicConnections)
 topicChoice.Visible=true;local mine=message.PickerUserId==p.UserId;topicChoiceTitle.Text=mine and"CHOOSE 1 OF 3 TOPICS — YOUR SIDE IS ASSIGNED NEXT"or(message.PickerName.." IS CHOOSING — SIDES ARE ASSIGNED NEXT")
 for index,choice in ipairs(topicButtons)do local offered=message.Topics[index];choice.Text=offered and((offered.Category or"TOPIC").." • "..offered.Topic)or"";choice.Active=mine;choice.AutoButtonColor=mine;choice.BackgroundColor3=mine and C.blue or C.panel
  if offered then table.insert(topicConnections,choice.Activated:Connect(function()if topicChoice.Visible and choice.Active then for _,other in ipairs(topicButtons)do other.Active=false;other.AutoButtonColor=false end;topicChoiceTitle.Text="TOPIC LOCKED — ASSIGNING SIDES…";submit:FireServer("topic",{TopicId=offered.Id})end end))end
 end
end
local activePopup=nil;local popupWanted=nil
local function popup(heading,body,rows)if activePopup then activePopup:Destroy()end;local f=Instance.new("Frame");f.Name="MenuPopup";f.AnchorPoint=Vector2.new(1,.5);f.Position=UDim2.new(1,-164,.5,0);f.Size=UDim2.fromOffset(300,rows and(96+#rows*40+70)or 260);f.BackgroundColor3=C.bg;f.ZIndex=12;f.Parent=g;corner(f,12);activePopup=f
local h=label(f,heading,20,C.gold,true);h.Position=UDim2.fromOffset(16,12);h.Size=UDim2.new(1,-64,0,30);h.ZIndex=13
local x=button(f,"X",C.panel);x.Name="Close";x.AnchorPoint=Vector2.new(1,0);x.Position=UDim2.new(1,-10,0,10);x.Size=UDim2.fromOffset(34,34);x.ZIndex=14;x.Activated:Connect(function()f:Destroy();if activePopup==f then activePopup=nil end end)
local y=50;for _,r in ipairs(rows or{})do local l=label(f,r.Text,14,r.Color or C.white);l.Position=UDim2.fromOffset(16,y+6);l.Size=UDim2.new(1,-150,0,24);l.ZIndex=13;if r.Action then local b=button(f,r.Action,r.Enabled and C.blue or C.panel);b.Position=UDim2.new(1,-126,0,y);b.Size=UDim2.fromOffset(110,34);b.ZIndex=14;b.AutoButtonColor=r.Enabled==true;if r.Enabled and r.OnClick then b.Activated:Connect(r.OnClick)end end;y+=40 end
local b=label(f,body,rows and 12 or 14,rows and C.muted or C.white);b.Position=UDim2.fromOffset(16,y+4);b.Size=UDim2.new(1,-32,1,-(y+16));b.TextYAlignment=Enum.TextYAlignment.Top;b.ZIndex=13 end
local function cosmeticRows(x,kind)local rows={};if kind=="title"then table.insert(rows,{Text="Debater",Action=x.Title=="Debater"and"EQUIPPED"or"EQUIP",Enabled=x.Title~="Debater",OnClick=function()submit:FireServer("equip",{Kind="title",Id="Debater"});popupWanted="TITLES";submit:FireServer("profile")end})end
for _,u in ipairs(x.Catalog or{})do if u.Kind==kind then local owned=x.Unlocks and x.Unlocks[u.Id];local equipped=(kind=="chair"and x.Chair==u.Id)or(kind=="title"and x.Title==u.Id);local name=string.gsub(u.Label," title$","");table.insert(rows,{Text=name..(owned and""or("  •  "..u.Points.." pts")),Color=owned and C.white or C.muted,Action=equipped and"EQUIPPED"or(owned and"EQUIP"or"LOCKED"),Enabled=owned and not equipped,OnClick=function()submit:FireServer("equip",{Kind=kind,Id=u.Id});popupWanted=(kind=="chair"and"CHAIRS"or"TITLES");submit:FireServer("profile")end})end end;return rows end
chairs.Activated:Connect(function()popupWanted="CHAIRS";submit:FireServer("profile")end)
titles.Activated:Connect(function()popupWanted="TITLES";submit:FireServer("profile")end)
profileButton.Activated:Connect(function()popupWanted="PROFILE";submit:FireServer("profile")end)
rematch.Activated:Connect(function()submit:FireServer("rematch");rematch.Text="WAITING…";rematch.Active=false end)
local function row(who,text,col)local x=label(log,who.."\n"..text,14,col,who~="SYSTEM");x.Size=UDim2.new(1,-18,0,68);x.AutomaticSize=Enum.AutomaticSize.Y;x.TextYAlignment=Enum.TextYAlignment.Top;x.BackgroundTransparency=.28;x.BackgroundColor3=C.card;corner(x,8);stroke(x,col or C.blue,.8,1);local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,10);pad.PaddingRight=UDim.new(0,10);pad.PaddingTop=UDim.new(0,8);pad.PaddingBottom=UDim.new(0,8);pad.Parent=x;x.Parent=log;return x end
local function countScore(name,points)local x=row("SCORE",name..": 0 session points",C.green);task.spawn(function()for value=1,points do if not x.Parent then return end;x.Text="SCORE\n"..name..": "..value.." session points";task.wait(.035)end end)end
play.Activated:Connect(function()if queued then panel.Visible=false;submit:FireServer("cancelQueue")else panel.Visible=true;submit:FireServer("queue")end end)
panelLeave.Activated:Connect(function()submit:FireServer("leave");topicChoice.Visible=false;panel.Visible=false end)
send.Activated:Connect(function()if not myTurn or pendingSubmissionId~=nil or box.Text==""then return end;nextSubmissionId+=1;pendingSubmissionId=nextSubmissionId;pendingText=box.Text;submit:FireServer("argument",{Id=pendingSubmissionId,Text=pendingText});send.Text="SENDING…";send.Active=false;send.AutoButtonColor=false end)
state.OnClientEvent:Connect(function(m)
 if m.Kind=="Lobby"then queued=m.Status=="QUEUED";play.Text=queued and "CANCEL SEARCH" or "DEBATE A REAL PLAYER";if queued then panel.Visible=true;title.Text="WAITING FOR ANOTHER PLAYER";topic.Text=("Players waiting: %d"):format(m.QueueSize or 1)end
 elseif m.Kind=="Profile"then local x=m.Profile;local want=popupWanted or"PROFILE";popupWanted=nil;if want=="CHAIRS"then popup("CHAIRS",("Session points: %d. Session preview only; no purchase or persistence."):format(x.Points),cosmeticRows(x,"chair"))elseif want=="TITLES"then popup("TITLES",("Session points: %d. Session preview only; no purchase or persistence."):format(x.Points),cosmeticRows(x,"title"))else popup("PROFILE",("Session points: %d\nChair: %s\nTitle: %s\n\nProgress resets when this server closes."):format(x.Points,x.Chair,x.Title))end
 elseif m.Kind=="TopicOffer"then panel.Visible=true;rematch.Visible=false;myTurn=false;send.Active=false;title.Text="TOPIC SELECTION";topic.Text=m.Message;showTopicChoice(m)
 elseif m.Kind=="Start"then topicChoice.Visible=false;rematch.Visible=false;rematch.Text="REMATCH";rematch.Active=true;queued=false;play.Text="DEBATE A REAL PLAYER";title.Text=m.Players[1].Name.."  vs  "..m.Players[2].Name;topic.Text=m.Topic.Topic.."\nYour assigned side appears with each turn.";scoreline.Text="PANEL SIGNALS • RIVET reason • PIP example • MOSS rebuttal";setAssistEnabled(false);for _,x in ipairs(log:GetChildren())do if x:IsA("TextLabel")then x:Destroy()end end;row("SCRIPTED HOST",m.Opening,C.gold);row("FORMAT",m.Rules.." Base +10, reason +5, example +5, rebuttal +5. These are visible writing checks, not semantic judging.",C.muted)
 elseif m.Kind=="Turn"then myTurn=m.UserId==p.UserId;turn.Text=(myTurn and "YOUR TURN" or (m.Name.." IS THINKING")).." • "..m.Role.." • "..m.Side;local role=string.upper(m.Role or"");box.PlaceholderText=role=="OPENING"and"State your claim and give a clear reason…"or(role=="REBUTTAL"and"Answer the other side's strongest point…"or"Close by connecting your reason, example, and rebuttal…");setAssistEnabled(myTurn);if myTurn then row("YOUR PROMPT",m.HostPrompt,C.gold)end;send.Text=myTurn and "SEND TURN" or "WAIT";send.Active=myTurn;send.AutoButtonColor=myTurn
 elseif m.Kind=="PlayerTurn"then if m.UserId==p.UserId and m.SubmissionId==pendingSubmissionId then pendingSubmissionId=nil;pendingText=nil;box.Text="";myTurn=false;setAssistEnabled(false)end;scoreline.Text=("LAST PANEL SIGNAL • %s +%d • %s"):format(m.Name,m.Points or 0,table.concat(m.Reasons or{}," • "));row(m.Name.."  +"..m.Points,m.Text.."\n"..table.concat(m.Reasons," • "),C.white);for _,reaction in ipairs(m.JudgeReactions or {})do row(reaction.Judge.." • "..(reaction.Earned and "SIGNAL DETECTED +5"or"NOT DETECTED"),reaction.Commentary.."\n"..reaction.Label,reaction.Earned and C.green or C.muted)end
 elseif m.Kind=="AIReply"then row(m.Label,m.Text,C.gold)
 elseif m.Kind=="Complete"then myTurn=false;setAssistEnabled(false);send.Text="COMPLETE";turn.Text=m.Message;rematch.Visible=true;for index,verdict in ipairs((m.Panel and m.Panel.Lines)or{})do task.delay((index-1)*.7,function()row(verdict.Judge,verdict.Text,C.gold)end)end;task.delay(2.3,function()row("PANEL DISCLOSURE",m.Panel and m.Panel.Disclosure or "SCRIPTED PRACTICE — checklist totals only.",C.muted);for _,s in ipairs(m.Scores)do countScore(s.Name,s.Points)end end)
 elseif m.Kind=="TenSecondWarning"then if m.UserId==p.UserId then row("10 SECONDS","Finish and send your current turn.",C.gold)end
 elseif m.Kind=="ArgumentRejected"then if m.SubmissionId==pendingSubmissionId or m.SubmissionId==nil then pendingSubmissionId=nil;if pendingText then box.Text=pendingText end;pendingText=nil;myTurn=m.CanRetry==true;setAssistEnabled(myTurn);send.Text=myTurn and "SEND TURN" or "WAIT";send.Active=myTurn;send.AutoButtonColor=myTurn;row("SYSTEM",m.Message,C.gold)end
 elseif m.Kind=="TurnTimedOut"then myTurn=false;setAssistEnabled(false);row("SYSTEM",m.Message,C.gold)
 elseif m.Kind=="RematchStatus"then row("SYSTEM",m.Name.." wants another round.",C.green)
 elseif m.Kind=="Ended"or m.Kind=="Error"then myTurn=false;if m.Kind=="Ended"then topicChoice.Visible=false end;row("SYSTEM",m.Message,C.gold)end
 log.CanvasPosition=Vector2.new(0,99999)
end)
