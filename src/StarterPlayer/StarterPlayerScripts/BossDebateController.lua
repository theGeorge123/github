local Controller={}
function Controller.Init(remotes,parent,buttonFactory,labelFactory,colors)
 local state=remotes:WaitForChild("BossDebateState");local submit=remotes:WaitForChild("BossDebateSubmit")
 local card=Instance.new("Frame");card.AnchorPoint=Vector2.new(0,.5);card.Position=UDim2.new(0,14,.5,0);card.Size=UDim2.fromOffset(210,180);card.BackgroundColor3=colors.bg;card.Parent=parent
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=card
 local title=labelFactory(card,"BOSS DEBATE",18,colors.gold,true);title.Position=UDim2.fromOffset(14,10);title.Size=UDim2.new(1,-28,0,28)
 local disclosure=labelFactory(card,"Checking server availability...",11,colors.muted);disclosure.Position=UDim2.fromOffset(14,40);disclosure.Size=UDim2.new(1,-28,0,90);disclosure.TextYAlignment=Enum.TextYAlignment.Top
 local cta=buttonFactory(card,"LOCKED",colors.panel);cta.Position=UDim2.fromOffset(14,136);cta.Size=UDim2.new(1,-28,0,32);cta.Active=false;cta.AutoButtonColor=false
 local practice=Instance.new("Frame");practice.AnchorPoint=Vector2.new(.5,.5);practice.Position=UDim2.fromScale(.5,.5);practice.Size=UDim2.fromOffset(400,420);practice.BackgroundColor3=colors.bg;practice.Visible=false;practice.Parent=parent
 local pc=Instance.new("UICorner");pc.CornerRadius=UDim.new(0,14);pc.Parent=practice
 local pt=labelFactory(practice,"SCRIPTED PRACTICE",20,colors.gold,true);pt.Position=UDim2.fromOffset(16,12);pt.Size=UDim2.new(1,-32,0,28)
 local status=labelFactory(practice,"Authored prompts only. No score, winner, or rewards.",12,colors.muted);status.Position=UDim2.fromOffset(16,44);status.Size=UDim2.new(1,-32,0,70);status.TextYAlignment=Enum.TextYAlignment.Top
 local log=labelFactory(practice,"",13,colors.white);log.Position=UDim2.fromOffset(16,112);log.Size=UDim2.new(1,-32,0,150);log.TextYAlignment=Enum.TextYAlignment.Top
 local box=Instance.new("TextBox");box.MultiLine=true;box.TextWrapped=true;box.PlaceholderText="Write your assigned position...";box.TextColor3=colors.white;box.PlaceholderColor3=colors.muted;box.BackgroundColor3=colors.panel;box.Position=UDim2.fromOffset(16,270);box.Size=UDim2.new(1,-32,0,76);box.Parent=practice;local bc=Instance.new("UICorner");bc.CornerRadius=UDim.new(0,8);bc.Parent=box
 local send=buttonFactory(practice,"SEND TURN",colors.blue);send.Position=UDim2.fromOffset(16,354);send.Size=UDim2.new(.62,-20,0,46);send.Active=false
 local leave=buttonFactory(practice,"LEAVE",colors.panel);leave.Position=UDim2.new(.62,4,0,354);leave.Size=UDim2.new(.38,-20,0,46)
 local session=nil;local round=nil;local turnToken=nil;local submission=0;local pending=nil
 cta.Activated:Connect(function()if cta.Active then submit:FireServer({Action="EnterPractice"})end end)
 send.Activated:Connect(function()if not session or not turnToken or pending or box.Text==""then return end;submission+=1;pending=submission;send.Active=false;submit:FireServer({Action="SubmitArgument",SessionId=session,RoundGeneration=round,TurnToken=turnToken,SubmissionId=pending,Text=box.Text})end)
 leave.Activated:Connect(function()if session then submit:FireServer({Action="LeavePractice",SessionId=session})end;practice.Visible=false end)
 state.OnClientEvent:Connect(function(message)
  if message.Kind=="BossAvailability"then disclosure.Text=message.Disclosure;cta.Text=message.Tier;cta.Active=message.Tier=="SCRIPTED_PRACTICE";cta.AutoButtonColor=cta.Active
  elseif message.Kind=="BossPracticeStarted"then session=message.SessionId;round=message.RoundGeneration;practice.Visible=true;status.Text=message.Disclosure.."\nYOU: "..message.PlayerPosition.."\nAUTHORED OPPOSITION: "..message.BossPosition;log.Text=message.Topic.Question
  elseif message.Kind=="BossPlayerTurn"then turnToken=message.TurnToken;send.Active=true;send.Text="SEND TURN"
  elseif message.Kind=="BossArgumentAccepted"then if message.SubmissionId==pending then pending=nil;box.Text=""end;log.Text=log.Text.."\n\nYOU: "..message.FilteredText
  elseif message.Kind=="BossScriptedReply"then log.Text=log.Text.."\n\n"..message.Label..": "..message.Text
  elseif message.Kind=="BossArgumentRejected"then if message.SubmissionId==pending or message.SubmissionId==nil then pending=nil;send.Active=message.CanRetry==true;send.Text=message.CanRetry and "TRY AGAIN"or"UNAVAILABLE";status.Text=message.Message end
  elseif message.Kind=="BossPracticeComplete"then send.Active=false;status.Text=message.Message;log.Text=log.Text.."\n\nCOMPLETE: No score, winner, or rewards."
  elseif message.Kind=="BossPracticeEnded"then session=nil;round=nil;turnToken=nil;pending=nil;practice.Visible=false end
 end)
 submit:FireServer({Action="GetAvailability"});return card
end
return Controller
