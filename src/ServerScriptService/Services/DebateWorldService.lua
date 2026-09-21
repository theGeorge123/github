local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local World = {Spawn=nil, Judges={}, Podiums={}, Sounds={}}
local C = {navy=Color3.fromRGB(13,20,36),blue=Color3.fromRGB(74,104,132),cyan=Color3.fromRGB(80,220,232),gold=Color3.fromRGB(255,194,82),green=Color3.fromRGB(89,190,130),white=Color3.fromRGB(235,242,250),purple=Color3.fromRGB(178,112,255)}
local function part(name,size,cframe,color,parent,material)local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cframe;p.Anchored=true;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p end
local function text(target,value,color)local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(900,300);g.Parent=target;local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Text=value;l.TextColor3=color or C.white;l.TextScaled=true;l.TextWrapped=true;l.Font=Enum.Font.GothamBold;l.Parent=g end
local function sound(parent,name,id,volume)local s=Instance.new("Sound");s.Name=name;s.SoundId="rbxassetid://"..id;s.Volume=volume;s.RollOffMaxDistance=90;s.Parent=parent;World.Sounds[name]=s;return s end
local function glow(parent,color,range,brightness)local light=Instance.new("PointLight");light.Color=color;light.Range=range or 18;light.Brightness=brightness or 2;light.Shadows=true;light.Parent=parent;return light end
local function judge(root,name,x,y,z,color,headShape)
 local m=Instance.new("Model");m.Name=name.."Judge";m.Parent=root
 local body=part("Body",Vector3.new(8,9,5),CFrame.new(x,y,z),color,m,Enum.Material.Metal)
 part("Chest",Vector3.new(5.5,2.2,5.3),CFrame.new(x,y+1,z-.1),C.navy,m,Enum.Material.Metal);part("LeftArm",Vector3.new(1.8,7,1.8),CFrame.new(x-5,y,z),color,m,Enum.Material.Metal);part("RightArm",Vector3.new(1.8,7,1.8),CFrame.new(x+5,y,z),color,m,Enum.Material.Metal)
 local head=part("Head",Vector3.new(6,5.5,5.5),CFrame.new(x,y+7,z),C.white,m);if headShape=="round"then head.Shape=Enum.PartType.Ball end
 local eye=part("Eyes",Vector3.new(3.4,.65,.3),CFrame.new(x,y+7,z+2.8),color,m,Enum.Material.Neon);eye.CanCollide=false
 local base=part("HoverCore",Vector3.new(7,1,4),CFrame.new(x,y-5,z),C.navy,m,Enum.Material.Metal);local light=glow(base,color,22,2.2)
 local tag=Instance.new("BillboardGui");tag.Size=UDim2.fromOffset(190,48);tag.StudsOffset=Vector3.new(0,4.4,0);tag.AlwaysOnTop=true;tag.Parent=head;local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=C.navy;label.BackgroundTransparency=.15;label.Text=name.." • SCRIPTED JUDGE";label.TextColor3=color;label.TextScaled=true;label.Font=Enum.Font.GothamBold;label.Parent=tag
 m.PrimaryPart=body;World.Judges[name]={Model=m,BaseCFrame=body.CFrame,Eye=eye,Light=light}
end
local function collectible(root,name,pos,color)
 local model=Instance.new("Model");model.Name=name.."Collectible";model.Parent=root;local core=part("Core",Vector3.new(2.2,2.2,2.2),CFrame.new(pos),color,model,Enum.Material.Neon);core.Shape=Enum.PartType.Ball;core.CanCollide=false
 local ring=part("Ring",Vector3.new(.35,3.2,3.2),CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90)),C.white,model,Enum.Material.Metal);ring.Shape=Enum.PartType.Cylinder;ring.CanCollide=false
 local prompt=Instance.new("ProximityPrompt");prompt.ActionText="INSPECT";prompt.ObjectText=name.." — COMING SOON";prompt.HoldDuration=0;prompt.MaxActivationDistance=10;prompt.Parent=core
 local billboard=Instance.new("BillboardGui");billboard.Size=UDim2.fromOffset(160,42);billboard.StudsOffset=Vector3.new(0,2.3,0);billboard.AlwaysOnTop=true;billboard.Enabled=false;billboard.Parent=core;local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=C.navy;label.Text=name.." • COMING SOON";label.TextColor3=color;label.TextScaled=true;label.Font=Enum.Font.GothamBold;label.Parent=billboard
 prompt.Triggered:Connect(function()billboard.Enabled=true;task.delay(2,function()if billboard.Parent then billboard.Enabled=false end end)end)
 task.spawn(function()local start=core.CFrame;local angle=0;while core.Parent do angle+=.025;core.CFrame=start*CFrame.new(0,math.sin(angle*2)*.35,0)*CFrame.Angles(0,angle,0);ring.CFrame=core.CFrame*CFrame.Angles(0,0,math.rad(90));task.wait(.04)end end)
end
function World.PlaySound(name)local s=World.Sounds[name];if s then s.TimePosition=0;s:Play()end end
function World.React(reactions)
 for _,reaction in ipairs(reactions or {})do local data=World.Judges[reaction.Judge];if data then local pivot=data.Model:GetPivot();TweenService:Create(data.Eye,TweenInfo.new(.16),{Transparency=reaction.Earned and 0 or .45,Size=reaction.Earned and Vector3.new(4.2,.9,.35)or Vector3.new(3.4,.65,.3)}):Play();data.Model:PivotTo(pivot*CFrame.Angles(math.rad(reaction.Earned and -4 or 2),0,0));task.delay(.3,function()if data.Model.Parent then data.Model:PivotTo(pivot);TweenService:Create(data.Eye,TweenInfo.new(.25),{Transparency=0,Size=Vector3.new(3.4,.65,.3)}):Play()end end)end end
end
function World.SetActivePlayer(playerIndex)
 for index,podium in pairs(World.Podiums)do TweenService:Create(podium,TweenInfo.new(.32,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=Vector3.new(podium.Position.X,index==playerIndex and 1.3 or .65,podium.Position.Z),Color=index==playerIndex and C.gold or C.blue}):Play()end
 Lighting.ColorShift_Top=C.cyan;task.delay(.18,function()Lighting.ColorShift_Top=Color3.new(0,0,0)end);World.PlaySound("TurnStart")
end
function World.Celebrate(leadingUserId,players)
 Lighting.ColorShift_Top=C.gold;World.PlaySound("VerdictSting");local leadingIndex=nil;for index,player in ipairs(players or {})do if player.UserId==leadingUserId then leadingIndex=index end end
 if leadingIndex then local podium=World.Podiums[leadingIndex];if podium then local rig=Instance.new("Part");rig.Name="ChecklistLeadSpotlight";rig.Size=Vector3.new(1,1,1);rig.CFrame=CFrame.new(podium.Position+Vector3.new(0,25,0));rig.Transparency=1;rig.Anchored=true;rig.CanCollide=false;rig.Parent=podium.Parent;local spot=Instance.new("SpotLight");spot.Color=C.gold;spot.Brightness=8;spot.Range=45;spot.Angle=70;spot.Face=Enum.NormalId.Bottom;spot.Parent=rig;task.delay(6,function()if rig.Parent then rig:Destroy()end end)end;World.PlaySound("MatchWin")end
 local emitter=Instance.new("ParticleEmitter");emitter.Name="ChecklistConfetti";emitter.Texture="rbxassetid://241837157";emitter.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.cyan),ColorSequenceKeypoint.new(.5,C.gold),ColorSequenceKeypoint.new(1,C.green)});emitter.Lifetime=NumberRange.new(2,3);emitter.Speed=NumberRange.new(14,22);emitter.SpreadAngle=Vector2.new(80,80);emitter.Rate=0;emitter.Parent=World.Spawn;emitter:Emit(120);task.delay(5,function()if emitter.Parent then emitter:Destroy()end;Lighting.ColorShift_Top=Color3.new(0,0,0)end)
end
function World.Init()
 for _,name in ipairs({"BeatTheBotWorld","BeatTheBotDebateStage"})do local old=workspace:FindFirstChild(name);if old then old:Destroy()end end;World.Judges={};World.Podiums={};World.Sounds={}
 local root=Instance.new("Folder");root.Name="BeatTheBotDebateStage";root.Parent=workspace;part("ArenaFloor",Vector3.new(54,1,42),CFrame.new(0,0,2),Color3.fromRGB(55,70,86),root,Enum.Material.Slate);part("StageInset",Vector3.new(34,.18,24),CFrame.new(0,.59,4),Color3.fromRGB(25,38,55),root);part("JudgeDais",Vector3.new(52,3,10),CFrame.new(0,5,-17),C.navy,root,Enum.Material.Metal)
 local sign=part("DebateSign",Vector3.new(24,3,.5),CFrame.new(0,20,-20.8),C.navy,root,Enum.Material.Metal);text(sign,"THE SCRIPTED CHECKLIST PANEL",C.gold)
 World.Podiums[1]=part("PlayerPodiumA",Vector3.new(8,1.2,7),CFrame.new(-9,.65,6),C.blue,root,Enum.Material.Metal);World.Podiums[2]=part("PlayerPodiumB",Vector3.new(8,1.2,7),CFrame.new(9,.65,6),C.blue,root,Enum.Material.Metal)
 judge(root,"RIVET",-15,14,-16,C.cyan,"square");judge(root,"PIP",0,16,-18,C.gold,"square");judge(root,"MOSS",15,14,-16,C.green,"round")
 collectible(root,"BLIP",Vector3.new(-21,2,15),C.cyan);collectible(root,"ZAPP",Vector3.new(0,2,19),C.purple);collectible(root,"CHOMP",Vector3.new(21,2,15),C.green)
 local audio=part("ArenaAudio",Vector3.new(1,1,1),CFrame.new(0,4,0),C.navy,root);audio.Transparency=1;audio.CanCollide=false;sound(audio,"TurnStart","6026984224",.18);sound(audio,"TenSecondWarning","6026984224",.14);sound(audio,"ScoreTick","911342077",.1);sound(audio,"VerdictSting","1843529634",.2);sound(audio,"MatchWin","1843529607",.22)
 local spawn=Instance.new("SpawnLocation");spawn.Name="DebateSpawn";spawn.Size=Vector3.new(8,1,5);spawn.CFrame=CFrame.new(0,1,15);spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Transparency=1;spawn.Parent=root;World.Spawn=spawn
 Lighting.ClockTime=18;Lighting.Brightness=2.8;Lighting.Ambient=Color3.fromRGB(95,110,135);Lighting.OutdoorAmbient=Color3.fromRGB(125,140,160);Lighting.EnvironmentDiffuseScale=1;Lighting.EnvironmentSpecularScale=.65
 task.spawn(function()local elapsed=0;while root.Parent do elapsed+=.035;for id,data in pairs(World.Judges)do if data.Model.Parent then local phase=id=="RIVET"and 0 or(id=="PIP"and 2 or 4);data.Model:PivotTo(data.BaseCFrame*CFrame.new(0,math.sin(elapsed+phase)*.35,0))end end;task.wait(.04)end end);return root
end
function World.Refresh()end
return World
