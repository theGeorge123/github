-- DebateWorldService — dark fantasy guardian temple build (v0.5.2).
-- Public API preserved: Init, Refresh, PlaySound, React, SetActivePlayer, Celebrate.
-- Public names preserved: BeatTheBotDebateStage, DebateSpawn, <NAME>Judge models, PlayerPodiumA/B.
-- v0.5.2: Clones sanitized Creator Store assets from ServerStorage.TempleAssets with primitive fallback.
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Definitions=require(script.Parent.Parent.Core.GuardianTempleDefinitions)
local World = {Spawn=nil, Judges={}, Podiums={}, PodRunes={}, Sounds={}, Hologram=nil, HoloBase=nil, HoloPlayerIndex=nil, LightingPulseToken=0, MissingTemplates={}}
local C = {stone=Color3.fromRGB(56,60,72),darkstone=Color3.fromRGB(36,40,52),navy=Color3.fromRGB(14,20,34),cyan=Color3.fromRGB(80,220,232),teal=Color3.fromRGB(48,178,190),pale=Color3.fromRGB(168,240,248),gold=Color3.fromRGB(255,194,82),orange=Color3.fromRGB(255,138,48),white=Color3.fromRGB(222,238,246),purple=Color3.fromRGB(140,190,255),green=Color3.fromRGB(95,205,175)}
local function part(name,size,cframe,color,parent,material)local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cframe;p.Anchored=true;p.Color=color;p.Material=material or Enum.Material.Slate;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p end
local function text(target,value,color)local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(900,300);g.Parent=target;local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Text=value;l.TextColor3=color or C.white;l.TextScaled=true;l.TextWrapped=true;l.Font=Enum.Font.GothamBold;l.Parent=g end
local function sound(parent,name,id,volume)
 local s=Instance.new("Sound");s.Name=name;s.SoundId=type(id)=="string"and id~=""and("rbxassetid://"..id)or"";s.Volume=volume;s.RollOffMaxDistance=90;s.Parent=parent;World.Sounds[name]=s;return s
end
local function glow(parent,color,range,brightness)local light=Instance.new("PointLight");light.Color=color;light.Range=range or 18;light.Brightness=brightness or 2;light.Shadows=true;light.Parent=parent;return light end
local function rune(parent,name,size,cframe,color)local r=part(name,size,cframe,color or C.cyan,parent,Enum.Material.Neon);r.CanCollide=false;r.Transparency=.3;return r end
local function fireBowl(root,x,z)
 local bowl=part("FireBowl",Vector3.new(3.6,1.6,3.6),CFrame.new(x,1.3,z),C.stone,root,Enum.Material.Slate)
 local ember=part("Ember",Vector3.new(2,2,2),CFrame.new(x,2.2,z),C.orange,root,Enum.Material.Neon);ember.Shape=Enum.PartType.Ball;ember.CanCollide=false
 local fire=Instance.new("ParticleEmitter");fire.Color=ColorSequence.new(C.orange);fire.Lifetime=NumberRange.new(.7,1.3);fire.Speed=NumberRange.new(2,4);fire.SpreadAngle=Vector2.new(18,18);fire.Rate=14;fire.Size=NumberSequence.new(.7,.1);fire.Transparency=NumberSequence.new(.2,.9);fire.LightEmission=1;fire.Parent=ember
 glow(bowl,C.orange,20,2.4)
end
-- Decorative templates are server-only so clients receive only the visible clones.
local function sanitizeDecorative(model)
 for _,descendant in ipairs(model:GetDescendants())do
  if descendant:IsA("BasePart")then
   descendant.Anchored=true;descendant.CanCollide=false;descendant.CanTouch=false;descendant.CanQuery=false
  elseif descendant:IsA("Script")or descendant:IsA("LocalScript")or descendant:IsA("ClickDetector")or descendant:IsA("ProximityPrompt")or descendant:IsA("BillboardGui")then
   descendant:Destroy()
  elseif descendant:IsA("Sound")then
   descendant:Stop();descendant:Destroy()
  end
 end
end
local function judgeTag(model,name,color,boxCFrame,boxSize)
 local anchor=part("JudgeTagAnchor",Vector3.new(.2,.2,.2),CFrame.new(boxCFrame.Position+Vector3.new(0,boxSize.Y*.5+2.2,0)),C.navy,model,Enum.Material.SmoothPlastic);anchor.Transparency=1;anchor.CanCollide=false
 local tag=Instance.new("BillboardGui");tag.Name="JudgeNameTag";tag.Size=UDim2.fromOffset(210,50);tag.AlwaysOnTop=true;tag.MaxDistance=130;tag.Parent=anchor
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=C.navy;label.BackgroundTransparency=.12;label.Text=name.." • SCRIPTED JUDGE";label.TextColor3=color;label.TextScaled=true;label.TextWrapped=true;label.Font=Enum.Font.GothamBold;label.Parent=tag
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,8);corner.Parent=label
end
local function placeByBoundingCenter(model,targetCenter,rotation)
 model:PivotTo(CFrame.new(targetCenter)*rotation)
 local boxCFrame=model:GetBoundingBox()
 local delta=targetCenter-boxCFrame.Position
 model:PivotTo(model:GetPivot()+delta)
end
local function cloneTemplate(name)
 local container=ServerStorage:FindFirstChild("TempleAssets");local template=container and container:FindFirstChild(name)
 if not template or not template:IsA("Model")then
  if not World.MissingTemplates[name]then World.MissingTemplates[name]=true;print("BEAT_THE_BOT_TEMPLE_FALLBACK",name)end
  return nil
 end
 local clone=template:Clone();sanitizeDecorative(clone);return clone
end
-- v0.5.2: Asset-based fire bowl with primitive fallback
local function torchBowl(root,x,z)
 local bowl=cloneTemplate("FireBowl")
 if bowl then
  bowl.Name="FireBowl";bowl.Parent=root
  local _,size=bowl:GetBoundingBox()
  local targetHeight = 5
  local scale = targetHeight / size.Y
  bowl:ScaleTo(scale)
  local _,scaledSize=bowl:GetBoundingBox();local rotation=bowl:GetPivot()-bowl:GetPivot().Position
  placeByBoundingCenter(bowl,Vector3.new(x,scaledSize.Y*.5,z),rotation)
  return
 end
 fireBowl(root,x,z)
end
local function pillar(root,x,z)
 local col=part("Pillar",Vector3.new(5.5,24,5.5),CFrame.new(x,12,z),C.stone,root,Enum.Material.Slate)
 part("PillarCap",Vector3.new(6.5,1.2,6.5),CFrame.new(x,24.6,z),C.darkstone,root,Enum.Material.Slate)
 local band=rune(root,"PillarRune",Vector3.new(6,.5,6),CFrame.new(x,20,z),C.cyan);glow(band,C.cyan,15,1.1)
end
local function judge(root,name,x,y,z,color,headShape)
 local m=Instance.new("Model");m.Name=name.."Judge";m.Parent=root
 local body=part("Body",Vector3.new(9,10,6),CFrame.new(x,y,z),C.darkstone,m,Enum.Material.Metal)
 part("Chest",Vector3.new(6.4,3,6.3),CFrame.new(x,y+1.2,z-.1),color,m,Enum.Material.Metal)
 part("LeftPauldron",Vector3.new(3.4,2.4,3.4),CFrame.new(x-5.6,y+4.2,z),color,m,Enum.Material.Metal);part("RightPauldron",Vector3.new(3.4,2.4,3.4),CFrame.new(x+5.6,y+4.2,z),color,m,Enum.Material.Metal)
 part("LeftArm",Vector3.new(2.2,8,2.2),CFrame.new(x-5.2,y-1,z),C.darkstone,m,Enum.Material.Metal);part("RightArm",Vector3.new(2.2,8,2.2),CFrame.new(x+5.2,y-1,z),C.darkstone,m,Enum.Material.Metal)
 part("LeftGauntlet",Vector3.new(2.7,2,2.7),CFrame.new(x-5.2,y-4.8,z),color,m,Enum.Material.Metal);part("RightGauntlet",Vector3.new(2.7,2,2.7),CFrame.new(x+5.2,y-4.8,z),color,m,Enum.Material.Metal)
 local head=part("Head",Vector3.new(6.5,5.5,6),CFrame.new(x,y+7.5,z),C.darkstone,m,Enum.Material.Metal);if headShape=="round"then head.Shape=Enum.PartType.Ball end
 local eye=part("Eyes",Vector3.new(4,.8,.4),CFrame.new(x,y+7.6,z+3.05),color,m,Enum.Material.Neon);eye.CanCollide=false
 rune(m,"ChestRune",Vector3.new(1.1,4.2,.35),CFrame.new(x,y+1.2,z+3.2),color)
 local base=part("HoverCore",Vector3.new(.8,7.5,7.5),CFrame.new(x,y-6.2,z)*CFrame.Angles(0,0,math.rad(90)),C.navy,m,Enum.Material.Metal)
 rune(m,"HoverRune",Vector3.new(.5,8.4,8.4),CFrame.new(x,y-6.2,z)*CFrame.Angles(0,0,math.rad(90)),color)
 local light=glow(base,color,24,2.2)
 judgeTag(m,name,color,CFrame.new(x,y+.65,z),Vector3.new(12,16.3,7.5))
 m.PrimaryPart=body;World.Judges[name]={Model=m,BaseCFrame=body.CFrame,Eye=eye,Light=light,ReactionStarted=0,ReactionUntil=0,ReactionPitch=0}
end
-- v0.5.2: Asset-based guardian with primitive fallback
local function guardian(root,name,x,y,z,color,headShape,statueHeight)
 local assetName = (name == "PIP") and "GuardianOverlord" or "GuardianSentinel"
 local m=cloneTemplate(assetName)
 if m then
  m.Name=name.."Judge";m.Parent=root
  local _,nativeSize=m:GetBoundingBox()
  local scale = statueHeight / nativeSize.Y
  m:ScaleTo(scale)
  local boxCFrame,scaledSize=m:GetBoundingBox();local rotation=m:GetPivot()-m:GetPivot().Position
  local judgeDefinition=Definitions.Judges[name];if judgeDefinition and judgeDefinition.YawDegrees~=0 then rotation=CFrame.Angles(0,math.rad(judgeDefinition.YawDegrees),0)*rotation end
  placeByBoundingCenter(m,Vector3.new(x,y,z),rotation)
  boxCFrame=m:GetBoundingBox()
  local eyeAnchor=m:FindFirstChild("JudgeEyeAnchor",true);local chestAnchor=m:FindFirstChild("JudgeChestAnchor",true)
  local eyePosition=eyeAnchor and(eyeAnchor:IsA("Attachment")and eyeAnchor.WorldPosition or eyeAnchor:IsA("BasePart")and eyeAnchor.Position)or(boxCFrame.Position+Vector3.new(0,scaledSize.Y*.25,scaledSize.Z*.5+.15))
  local chestPosition=chestAnchor and(chestAnchor:IsA("Attachment")and chestAnchor.WorldPosition or chestAnchor:IsA("BasePart")and chestAnchor.Position)or(boxCFrame.Position+Vector3.new(0,-scaledSize.Y*.08,scaledSize.Z*.5+.12))
  local eye=part("Eyes",Vector3.new(4,.8,.4),CFrame.new(eyePosition),color,m,Enum.Material.Neon);eye.CanCollide=false
  rune(m,"ChestRune",Vector3.new(1.1,4.2,.35),CFrame.new(chestPosition),color)
  local light = glow(m:FindFirstChildWhichIsA("BasePart", true) or m.PrimaryPart or m:GetChildren()[1], color, 24, 2.2)
  judgeTag(m,name,color,boxCFrame,scaledSize)
  -- Set PrimaryPart for float animation
  if not m.PrimaryPart then
   m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart", true)
  end
  World.Judges[name]={Model=m,BaseCFrame=m:GetPivot(),Eye=eye,Light=light,ReactionStarted=0,ReactionUntil=0,ReactionPitch=0}
  return
 end
 -- Fallback to primitive judge
 judge(root,name,x,y,z,color,headShape)
end
-- v0.5.2: Asset-based banner with primitive fallback (banners are decorative)
local function banner(root,x,z,bannerHeight)
 local b=cloneTemplate("TempleBanner")
 if b then
  b.Name="TempleBanner";b.Parent=root
  local _,nativeSize=b:GetBoundingBox()
  local scale = bannerHeight / nativeSize.Y
  b:ScaleTo(scale)
  local _,scaledSize = b:GetBoundingBox()
  local rotation=b:GetPivot()-b:GetPivot().Position
  placeByBoundingCenter(b,Vector3.new(x,scaledSize.Y*.5,z),rotation)
  return
 end
 -- Primitive fallback: simple stone slab banner
 local slab=part("TempleBanner",Vector3.new(8,bannerHeight,1),CFrame.new(x,bannerHeight*0.5,z),C.darkstone,root,Enum.Material.Slate)
end
local function collectible(root,name,pos,color)
 local model=Instance.new("Model");model.Name=name.."Collectible";model.Parent=root;local core=part("Core",Vector3.new(2.2,2.2,2.2),CFrame.new(pos),color,model,Enum.Material.Neon);core.Shape=Enum.PartType.Ball;core.CanCollide=false
 local ring=part("Ring",Vector3.new(.35,3.2,3.2),CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90)),C.white,model,Enum.Material.Metal);ring.Shape=Enum.PartType.Cylinder;ring.CanCollide=false
 local prompt=Instance.new("ProximityPrompt");prompt.ActionText="INSPECT";prompt.ObjectText=name.." — COMING SOON";prompt.HoldDuration=0;prompt.MaxActivationDistance=10;prompt.Parent=core
 local billboard=Instance.new("BillboardGui");billboard.Size=UDim2.fromOffset(160,42);billboard.StudsOffset=Vector3.new(0,2.3,0);billboard.AlwaysOnTop=true;billboard.Enabled=false;billboard.Parent=core;local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=C.navy;label.Text=name.." • COMING SOON";label.TextColor3=color;label.TextScaled=true;label.Font=Enum.Font.GothamBold;label.Parent=billboard
 prompt.Triggered:Connect(function()billboard.Enabled=true;task.delay(2,function()if billboard.Parent then billboard.Enabled=false end end)end)
 task.spawn(function()local start=core.CFrame;local angle=0;while core.Parent do angle+=.025;core.CFrame=start*CFrame.new(0,math.sin(angle*2)*.35,0)*CFrame.Angles(0,angle,0);ring.CFrame=core.CFrame*CFrame.Angles(0,0,math.rad(90));task.wait(.04)end end)
end
local function destroyHologram()
 if World.Hologram then World.Hologram:Destroy()end;World.Hologram=nil;World.HoloBase=nil;World.HoloPlayerIndex=nil
end
local function pulseLighting(color,duration)
 World.LightingPulseToken+=1;local token=World.LightingPulseToken;Lighting.ColorShift_Top=color
 task.delay(duration,function()if World.LightingPulseToken==token then Lighting.ColorShift_Top=Color3.new(0,0,0)end end)
end
function World.PlaySound(name)local s=World.Sounds[name];if s and s.SoundId~=""then s.TimePosition=0;s:Play()end end
function World.React(reactions)
 local now=os.clock()
 for _,reaction in ipairs(reactions or {})do local data=World.Judges[reaction.Judge];if data then
  data.ReactionStarted=now;data.ReactionUntil=now+.38;data.ReactionPitch=math.rad(reaction.Earned and -5 or 2)
  TweenService:Create(data.Eye,TweenInfo.new(.16),{Transparency=reaction.Earned and 0 or .45,Size=reaction.Earned and Vector3.new(5,1.1,.5)or Vector3.new(3.2,.7,.35)}):Play()
  task.delay(.3,function()if data.Eye.Parent then TweenService:Create(data.Eye,TweenInfo.new(.25),{Transparency=0,Size=Vector3.new(4,.8,.4)}):Play()end end)
 end end
end
function World.SetActivePlayer(playerIndex)
 for index,podium in pairs(World.Podiums)do
  local active=index==playerIndex
  TweenService:Create(podium,TweenInfo.new(.32,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=Vector3.new(podium.Position.X,active and 1.3 or .65,podium.Position.Z)}):Play()
  local runePart=World.PodRunes[index]
  if runePart then TweenService:Create(runePart,TweenInfo.new(.32),{Color=active and C.cyan or C.teal,Transparency=active and 0 or .35,Position=Vector3.new(runePart.Position.X,active and 1.42 or .72,runePart.Position.Z)}):Play() end
 end
 destroyHologram()
 if playerIndex and World.Podiums[playerIndex] then
  local podium=World.Podiums[playerIndex]
  local m=Instance.new("Model");m.Name="TurnHologram";m.Parent=podium.Parent
  local basePos=podium.Position+Vector3.new(0,7,0)
  local base=part("HoloBase",Vector3.new(4,.25,4),CFrame.new(basePos),C.cyan,m,Enum.Material.Neon);base.CanCollide=false;base.Transparency=.45
  glow(base,C.cyan,14,1.5)
  for i,word in ipairs({"BECAUSE","FOR EXAMPLE","HOWEVER"})do
   local shard=part("Choice"..i,Vector3.new(1.7,1.7,.3),CFrame.new(basePos+Vector3.new(0,1.6,0)),C.cyan,m,Enum.Material.Neon);shard.CanCollide=false;shard.Transparency=.2
   local bb=Instance.new("BillboardGui");bb.Size=UDim2.fromOffset(150,34);bb.StudsOffset=Vector3.new(0,1.5,0);bb.AlwaysOnTop=true;bb.Parent=shard
   local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Text=word;l.TextColor3=C.cyan;l.TextScaled=true;l.Font=Enum.Font.GothamBold;l.Parent=bb
  end
  World.Hologram=m;World.HoloBase=base;World.HoloPlayerIndex=playerIndex
 end
 pulseLighting(C.cyan,.18);World.PlaySound("TurnStart")
end
function World.Celebrate(leadingUserId,players)
 destroyHologram();pulseLighting(C.cyan,5);World.PlaySound("VerdictSting");local leadingIndex=nil;for index,player in ipairs(players or {})do if player.UserId==leadingUserId then leadingIndex=index end end
 if leadingIndex then local podium=World.Podiums[leadingIndex];if podium then local rig=Instance.new("Part");rig.Name="ChecklistLeadSpotlight";rig.Size=Vector3.new(1,1,1);rig.CFrame=CFrame.new(podium.Position+Vector3.new(0,25,0));rig.Transparency=1;rig.Anchored=true;rig.CanCollide=false;rig.Parent=podium.Parent;local spot=Instance.new("SpotLight");spot.Color=C.cyan;spot.Brightness=8;spot.Range=45;spot.Angle=70;spot.Face=Enum.NormalId.Bottom;spot.Parent=rig;task.delay(6,function()if rig.Parent then rig:Destroy() end end)end;World.PlaySound("MatchWin")end
 local emitter=Instance.new("ParticleEmitter");emitter.Name="ChecklistConfetti";emitter.Texture="rbxassetid://241837157";emitter.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.cyan),ColorSequenceKeypoint.new(.5,C.teal),ColorSequenceKeypoint.new(1,C.pale)});emitter.Lifetime=NumberRange.new(2,3);emitter.Speed=NumberRange.new(14,22);emitter.SpreadAngle=Vector2.new(80,80);emitter.Rate=0;emitter.Parent=World.Spawn;emitter:Emit(120);task.delay(5,function()if emitter.Parent then emitter:Destroy()end end)
end
function World.Init()
 for _,name in ipairs({"BeatTheBotWorld","BeatTheBotDebateStage"})do local old=workspace:FindFirstChild(name);if old then old:Destroy()end end
 destroyHologram();World.Judges={};World.Podiums={};World.PodRunes={};World.Sounds={};World.MissingTemplates={};World.LightingPulseToken+=1
 local root=Instance.new("Folder");root.Name="BeatTheBotDebateStage";root.Parent=workspace
 part("ArenaFloor",Vector3.new(Definitions.Arena.SizeX,1,Definitions.Arena.SizeZ),CFrame.new(0,0,Definitions.Arena.CenterZ),C.stone,root,Enum.Material.Slate)
 part("StageInset",Vector3.new(36,.2,26),CFrame.new(0,.59,4),C.darkstone,root,Enum.Material.Slate)
 rune(root,"StageRuneN",Vector3.new(36.6,.15,.5),CFrame.new(0,.7,-8.9));rune(root,"StageRuneS",Vector3.new(36.6,.15,.5),CFrame.new(0,.7,16.9));rune(root,"StageRuneE",Vector3.new(.5,.15,26.6),CFrame.new(18.3,.7,4));rune(root,"StageRuneW",Vector3.new(.5,.15,26.6),CFrame.new(-18.3,.7,4))
 local circle=rune(root,"StageRuneCircle",Vector3.new(.15,13,13),CFrame.new(0,.7,4)*CFrame.Angles(0,0,math.rad(90)),C.teal);circle.Transparency=.45
 part("JudgeDais",Vector3.new(54,4,12),CFrame.new(0,6,-18),C.darkstone,root,Enum.Material.Slate)
 part("DaisStep1",Vector3.new(26,1.4,3),CFrame.new(0,.7,-10.4),C.stone,root,Enum.Material.Slate);part("DaisStep2",Vector3.new(26,2.8,3),CFrame.new(0,1.4,-12.2),C.stone,root,Enum.Material.Slate)
 part("TempleWall",Vector3.new(90,40,3),CFrame.new(0,20,-35.5),C.darkstone,root,Enum.Material.Slate)
 for _,wx in ipairs({-21,-7,7,21})do rune(root,"WallRune",Vector3.new(.7,17,.35),CFrame.new(wx,15,-33.9)) end
 for _,px in ipairs({-27,27})do for _,pz in ipairs({-18,2,22})do pillar(root,px,pz) end end
 -- v0.5.2: Fire bowls using Creator Store asset (falls back to primitive)
 torchBowl(root,-42,-27);torchBowl(root,-24,-27);torchBowl(root,24,-27);torchBowl(root,42,-27)
 local sign=part("DebateSign",Vector3.new(24,3,.5),CFrame.new(0,10,-11.8),C.navy,root,Enum.Material.Metal);text(sign,"THE SCRIPTED CHECKLIST PANEL",C.gold)
 local function podium(name,cframe)local p=part(name,Vector3.new(8,1.2,7),cframe,C.darkstone,root,Enum.Material.Slate);local r=rune(root,name.."Rune",Vector3.new(8.4,.2,7.4),CFrame.new(cframe.X,.72,cframe.Z),C.teal);return p,r end
 World.Podiums[1],World.PodRunes[1]=podium("PlayerPodiumA",CFrame.new(-9,.65,6));World.Podiums[2],World.PodRunes[2]=podium("PlayerPodiumB",CFrame.new(9,.65,6))
 -- v0.5.2: Guardians using Creator Store assets (falls back to primitives)
 -- GuardianSentinel natively faces -Z; template already rotated 180° on Y so clones face +Z
 local rivet=Definitions.Judges.RIVET;local pip=Definitions.Judges.PIP;local moss=Definitions.Judges.MOSS
 guardian(root,"RIVET",rivet.X,rivet.Y,rivet.Z,C.cyan,"square",rivet.Height)
 guardian(root,"PIP",pip.X,pip.Y,pip.Z,C.teal,"square",pip.Height)
 guardian(root,"MOSS",moss.X,moss.Y,moss.Z,C.pale,"round",moss.Height)
 -- v0.5.2: Temple banners flanking the guardians
 banner(root,-31,-34.5,22);banner(root,31,-34.5,22)
 local blip=Definitions.Collectibles.BLIP;local zapp=Definitions.Collectibles.ZAPP;local chomp=Definitions.Collectibles.CHOMP
 collectible(root,"BLIP",Vector3.new(blip.X,blip.Y,blip.Z),C.cyan);collectible(root,"ZAPP",Vector3.new(zapp.X,zapp.Y,zapp.Z),C.teal);collectible(root,"CHOMP",Vector3.new(chomp.X,chomp.Y,chomp.Z),C.pale)
 local audio=part("ArenaAudio",Vector3.new(1,1,1),CFrame.new(0,4,0),C.navy,root);audio.Transparency=1;audio.CanCollide=false
 sound(audio,"TurnStart",Definitions.Sounds.TurnStart,.18);sound(audio,"TenSecondWarning",Definitions.Sounds.TenSecondWarning,.14)
 sound(audio,"ScoreTick",Definitions.Sounds.ScoreTick,.1);sound(audio,"VerdictSting",Definitions.Sounds.VerdictSting,.2);sound(audio,"MatchWin",Definitions.Sounds.MatchWin,.22)
 local spawnDefinition=Definitions.Spawn;local spawn=Instance.new("SpawnLocation");spawn.Name="DebateSpawn";spawn.Size=Vector3.new(8,1,5);spawn.CFrame=CFrame.lookAt(Vector3.new(spawnDefinition.X,spawnDefinition.Y,spawnDefinition.Z),Vector3.new(spawnDefinition.LookX,spawnDefinition.LookY,spawnDefinition.LookZ));spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Transparency=1;spawn.Parent=root;World.Spawn=spawn
 local cameraFocus=part("ArenaCameraFocus",Vector3.new(1,1,1),CFrame.new(0,14,-22),C.navy,root);cameraFocus.Transparency=1;cameraFocus.CanCollide=false;cameraFocus.CanTouch=false;cameraFocus.CanQuery=false
 local cameraAnchor=part("ArenaCameraAnchor",Vector3.new(1,1,1),CFrame.lookAt(Vector3.new(0,18,35),cameraFocus.Position),C.navy,root);cameraAnchor.Transparency=1;cameraAnchor.CanCollide=false;cameraAnchor.CanTouch=false;cameraAnchor.CanQuery=false
 Lighting.ClockTime=0;Lighting.Brightness=1.1;Lighting.Ambient=Color3.fromRGB(28,32,46);Lighting.OutdoorAmbient=Color3.fromRGB(38,44,60);Lighting.FogColor=Color3.fromRGB(10,13,22);Lighting.FogStart=50;Lighting.FogEnd=240;Lighting.EnvironmentDiffuseScale=.55;Lighting.EnvironmentSpecularScale=.4
 task.spawn(function()
  local elapsed=0
  while root.Parent do
   elapsed+=.035
   local now=os.clock()
   for id,data in pairs(World.Judges)do if data.Model.Parent then
    local phase=id=="RIVET"and 0 or(id=="PIP"and 2 or 4);local pitch=0
    if now<data.ReactionUntil then local progress=(now-data.ReactionStarted)/(data.ReactionUntil-data.ReactionStarted);pitch=math.sin(math.clamp(progress,0,1)*math.pi)*data.ReactionPitch end
    data.Model:PivotTo(data.BaseCFrame*CFrame.new(0,math.sin(elapsed+phase)*.35,0)*CFrame.Angles(pitch,0,0))
   end end
   if World.Hologram and World.Hologram.Parent and World.HoloBase and World.HoloPlayerIndex then
    local podium=World.Podiums[World.HoloPlayerIndex]
    if podium then World.HoloBase.CFrame=CFrame.new(podium.Position+Vector3.new(0,7,0))end
    for i=1,3 do local shard=World.Hologram:FindFirstChild("Choice"..i)
     if shard then local a=elapsed*.9+(i-1)*2.094;shard.CFrame=World.HoloBase.CFrame*CFrame.new(math.cos(a)*2.7,1.6+math.sin(elapsed*2+i)*.3,math.sin(a)*2.7)*CFrame.Angles(0,a,0)end
    end
   end
   task.wait(.04)
  end
 end)
 return root
end
function World.Refresh()end
return World
