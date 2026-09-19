local DebateClient = {}
function DebateClient.Start()
    local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage");local UIS=game:GetService("UserInputService")
    local p=Players.LocalPlayer;local r=RS:WaitForChild("BeatTheBotRemotes");local state=r:WaitForChild("DebateState");local submit=r:WaitForChild("DebateSubmit")
    local C={bg=Color3.fromRGB(10,16,29),panel=Color3.fromRGB(21,31,50),panel2=Color3.fromRGB(33,48,70),cyan=Color3.fromRGB(80,220,232),gold=Color3.fromRGB(255,194,82),green=Color3.fromRGB(89,190,130),white=Color3.fromRGB(240,245,252),muted=Color3.fromRGB(165,180,200)}
    local function corner(x,n)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,n or 10);c.Parent=x end
    local function label(parent,text,size,color,bold)local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Text=text;l.TextColor3=color or C.white;l.TextSize=size or 14;l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham;l.TextWrapped=true;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=parent;return l end
    local function button(parent,text,color)local b=Instance.new("TextButton");b.Text=text;b.TextColor3=C.white;b.TextSize=14;b.Font=Enum.Font.GothamBold;b.BackgroundColor3=color or C.panel2;b.Parent=parent;corner(b,9);return b end
    local gui=Instance.new("ScreenGui");gui.Name="DebatePrototypeUI";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.Parent=p:WaitForChild("PlayerGui")
    local badge=label(gui,"PRIVATE • UNRANKED • SESSION ONLY",12,C.gold,true);badge.Position=UDim2.fromOffset(16,10);badge.Size=UDim2.fromOffset(285,24)
    local menu=Instance.new("Frame");menu.AnchorPoint=Vector2.new(1,.5);menu.Position=UDim2.new(1,-14,.5,0);menu.Size=UDim2.fromOffset(132,224);menu.BackgroundColor3=C.bg;menu.BackgroundTransparency=.08;menu.Parent=gui;corner(menu,12)
    local list=Instance.new("UIListLayout");list.Padding=UDim.new(0,7);list.HorizontalAlignment=Enum.HorizontalAlignment.Center;list.VerticalAlignment=Enum.VerticalAlignment.Center;list.Parent=menu
    local play=button(menu,"▶ PLAY",C.cyan);play.Size=UDim2.new(1,-16,0,44);play.TextColor3=C.bg
    local chairs=button(menu,"CHAIRS",C.panel2);chairs.Size=play.Size
    local titles=button(menu,"TITLES",C.panel2);titles.Size=play.Size
    local profile=button(menu,"PROFILE",C.panel2);profile.Size=play.Size
    local select=Instance.new("Frame");select.AnchorPoint=Vector2.new(.5,.5);select.Position=UDim2.fromScale(.5,.48);select.Size=UDim2.new(.82,0,.72,0);select.BackgroundColor3=C.bg;select.Visible=false;select.Parent=gui;corner(select,16)
    local cons=Instance.new("UISizeConstraint");cons.MaxSize=Vector2.new(760,590);cons.MinSize=Vector2.new(300,380);cons.Parent=select
    local head=label(select,"CHOOSE YOUR DEBATE",24,C.white,true);head.Position=UDim2.fromOffset(22,16);head.Size=UDim2.new(1,-44,0,36)
    local sub=label(select,"Pick one character and topic. Four arguments each.",13,C.muted);sub.Position=UDim2.fromOffset(22,50);sub.Size=UDim2.new(1,-44,0,30)
    local defs={
     {"RIVET","Optional hints in building games","Hints stay available but optional",C.cyan},
     {"PIP","Piece limits in build challenges","Challenges use a clear piece limit",C.gold},
     {"MOSS","Individual contribution scores","Feedback stays private, not a leaderboard",C.green},
    }
    for i,d in ipairs(defs) do local card=button(select,d[1].."\n"..d[2].."\n"..d[3],C.panel);card.Position=UDim2.new(.04,0,.15+(i-1)*.245,0);card.Size=UDim2.new(.92,0,.205,0);card.TextColor3=d[4];card.TextSize=16;card.Activated:Connect(function()submit:FireServer("select",d[1])end)end
    local close=button(select,"CLOSE",C.panel2);close.Position=UDim2.new(.04,0,.9,0);close.Size=UDim2.new(.92,0,.07,0);close.Activated:Connect(function()select.Visible=false end)
    local debate=Instance.new("Frame");debate.AnchorPoint=Vector2.new(.5,.5);debate.Position=UDim2.fromScale(.46,.52);debate.Size=UDim2.new(.82,0,.84,0);debate.BackgroundColor3=C.bg;debate.Visible=false;debate.Parent=gui;corner(debate,16)
    local dc=Instance.new("UISizeConstraint");dc.MaxSize=Vector2.new(820,720);dc.MinSize=Vector2.new(310,440);dc.Parent=debate
    local dtitle=label(debate,"DEBATE",22,C.white,true);dtitle.Position=UDim2.fromOffset(18,12);dtitle.Size=UDim2.new(1,-36,0,32)
    local topic=label(debate,"",14,C.gold,true);topic.Position=UDim2.fromOffset(18,44);topic.Size=UDim2.new(1,-36,0,44)
    local practice=label(debate,"SCRIPTED PRACTICE — NO WINNER OR SCORE",12,C.gold,true);practice.Position=UDim2.fromOffset(18,86);practice.Size=UDim2.new(1,-36,0,24)
    local log=Instance.new("ScrollingFrame");log.Position=UDim2.fromOffset(18,116);log.Size=UDim2.new(1,-36,1,-220);log.BackgroundColor3=C.panel;log.BorderSizePixel=0;log.AutomaticCanvasSize=Enum.AutomaticSize.Y;log.CanvasSize=UDim2.new();log.ScrollBarThickness=5;log.Parent=debate;corner(log,10)
    local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,8);ll.Parent=log
    local box=Instance.new("TextBox");box.PlaceholderText="Make one clear claim and give a reason or example…";box.Text="";box.ClearTextOnFocus=false;box.MultiLine=true;box.TextWrapped=true;box.TextColor3=C.white;box.PlaceholderColor3=C.muted;box.TextSize=14;box.Font=Enum.Font.Gotham;box.BackgroundColor3=C.panel2;box.Position=UDim2.new(0,18,1,-94);box.Size=UDim2.new(1,-142,0,76);box.Parent=debate;corner(box,10)
    local send=button(debate,"SEND\n1 / 4",C.cyan);send.TextColor3=C.bg;send.Position=UDim2.new(1,-116,1,-94);send.Size=UDim2.fromOffset(98,76)
    local turn=0
    local function row(who,text,color)local x=label(log,who.."\n"..text,14,color,who~="YOU");x.Size=UDim2.new(1,-18,0,74);x.AutomaticSize=Enum.AutomaticSize.Y;x.Parent=log;x.TextYAlignment=Enum.TextYAlignment.Top;return x end
    play.Activated:Connect(function()select.Visible=true end)
    local function shell(titleText,body)local f=Instance.new("Frame");f.AnchorPoint=Vector2.new(1,.5);f.Position=UDim2.new(1,-158,.5,0);f.Size=UDim2.fromOffset(260,220);f.BackgroundColor3=C.bg;f.Parent=gui;corner(f,12);local h=label(f,titleText,19,C.gold,true);h.Position=UDim2.fromOffset(16,12);h.Size=UDim2.new(1,-32,0,30);local b=label(f,body,14,C.white);b.Position=UDim2.fromOffset(16,50);b.Size=UDim2.new(1,-32,1,-66);b.TextYAlignment=Enum.TextYAlignment.Top;task.delay(5,function()if f.Parent then f:Destroy()end end)end
    chairs.Activated:Connect(function()shell("CHAIRS","Practice chair preview\nNo item is equipped or saved\n\nMore chairs are visual-only in this prototype. No Robux or paid products.")end)
    titles.Activated:Connect(function()shell("TITLES","Debater preview\nNo title is equipped or saved\n\nClear Thinker\nComplete a future live debate to unlock.")end)
    profile.Activated:Connect(function()shell("PROFILE","Private tester\nSession-only debate prototype\nNo ELO, rewards, persistence, or production writes.")end)
    send.Activated:Connect(function()if box.Text~="" and turn<4 then submit:FireServer("argument",box.Text);box.Text=""end end)
    state.OnClientEvent:Connect(function(m)
     if m.Kind=="Selected" then select.Visible=false;debate.Visible=true;turn=0;for _,x in ipairs(log:GetChildren())do if x:IsA("TextLabel")then x:Destroy()end end;dtitle.Text=m.Character;topic.Text=m.Definition.Topic.."\nPosition: "..m.Definition.Position;row(m.Character,m.Definition.Opening,C.cyan);send.Text="SEND\n1 / 4"
     elseif m.Kind=="Reply" then turn=m.Turn;row("YOU",m.PlayerText,C.white);row(dtitle.Text,m.BotText,C.cyan);send.Text=turn<4 and ("SEND\n"..(turn+1).." / 4") or "DONE";log.CanvasPosition=Vector2.new(0,99999)
     elseif m.Kind=="Complete" then row("RESULT",m.Message.."\n\nRubric for live mode: Relevance 20% • Reasoning 30% • Evidence 20% • Rebuttal 30%",C.gold)
     elseif m.Kind=="Error" then row("SYSTEM","Your message could not be filtered. Try different wording.",C.gold) end
    end)
    if UIS.TouchEnabled then menu.Size=UDim2.fromOffset(112,208);select.Size=UDim2.new(.92,0,.76,0);debate.Size=UDim2.new(.94,0,.82,0) end
end
return DebateClient
