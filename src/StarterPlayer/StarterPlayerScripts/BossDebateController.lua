local Controller={}
function Controller.Init(remotes,parent,buttonFactory,labelFactory,colors)
 local state=remotes:WaitForChild("BossDebateState");local submit=remotes:WaitForChild("BossDebateSubmit")
 local card=Instance.new("Frame");card.AnchorPoint=Vector2.new(0,.5);card.Position=UDim2.new(0,14,.5,0);card.Size=UDim2.fromOffset(190,160);card.BackgroundColor3=colors.bg;card.Parent=parent
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=card
 local title=labelFactory(card,"BOSS DEBATE",18,colors.gold,true);title.Position=UDim2.fromOffset(14,12);title.Size=UDim2.new(1,-28,0,28)
 local disclosure=labelFactory(card,"Checking server availability...",12,colors.muted);disclosure.Position=UDim2.fromOffset(14,44);disclosure.Size=UDim2.new(1,-28,0,62);disclosure.TextYAlignment=Enum.TextYAlignment.Top
 local cta=buttonFactory(card,"LOCKED",colors.panel);cta.Position=UDim2.fromOffset(14,112);cta.Size=UDim2.new(1,-28,0,34);cta.Active=false;cta.AutoButtonColor=false
 state.OnClientEvent:Connect(function(message)if message.Kind=="BossAvailability"then disclosure.Text=message.Disclosure;cta.Text=message.Tier;cta.Active=false;cta.AutoButtonColor=false end end)
 submit:FireServer({Action="GetAvailability"})
 return card
end
return Controller
