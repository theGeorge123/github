-- DebateWorldService — bright marble guardian debate arena + distinct hero judges (v0.6.1).
-- Public API preserved: Init, Refresh, PlaySound, React, SetActivePlayer, Celebrate.
-- Public names preserved: BeatTheBotDebateStage, DebateSpawn, <NAME>Judge models, PlayerPodiumA/B.
-- v0.5.2: Clones sanitized Creator Store assets from ServerStorage.TempleAssets with primitive fallback.
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Definitions=require(script.Parent.Parent.Core.GuardianTempleDefinitions)
local World = {Spawn=nil, Judges={}, Podiums={}, PodRunes={}, Sounds={}, Hologram=nil, HoloBase=nil, HoloPlayerIndex=nil, LightingPulseToken=0, MissingTemplates={}}
local C = {stone=Color3.fromRGB(218,221,224),darkstone=Color3.fromRGB(89,101,118),navy=Color3.fromRGB(16,35,70),blue=Color3.fromRGB(46,128,255),cyan=Color3.fromRGB(74,211,255),teal=Color3.fromRGB(55,188,202),pale=Color3.fromRGB(215,247,255),gold=Color3.fromRGB(246,184,55),orange=Color3.fromRGB(255,143,49),white=Color3.fromRGB(248,249,250),purple=Color3.fromRGB(151,190,255),green=Color3.fromRGB(82,174,104),red=Color3.fromRGB(235,68,82),leaf=Color3.fromRGB(54,132,72),water=Color3.fromRGB(92,203,255),wood=Color3.fromRGB(96,68,47)}
local function part(name,size,cframe,color,parent,material)local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cframe;p.Anchored=true;p.Color=color;p.Material=material or Enum.Material.Slate;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p end
local function text(target,value,color)local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(900,300);g.Parent=target;local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Text=value;l.TextColor3=color or C.white;l.TextScaled=true;l.TextWrapped=true;l.Font=Enum.Font.GothamBold;l.Parent=g end
local function sound(parent,name,id,volume)
 local s=Instance.new("Sound");s.Name=name;s.SoundId=type(id)=="string"and id~=""and("rbxassetid://"..id)or"";s.Volume=volume;s.RollOffMaxDistance=90;s.Parent=parent;World.Sounds[name]=s;return s
end
local function glow(parent,color,range,brightness)local light=Instance.new("PointLight");light.Color=color;light.Range=range or 18;light.Brightness=brightness or 2;light.Shadows=true;light.Parent=parent;return light end
local function rune(parent,name,size,cframe,color)local r=part(name,size,cframe,color or C.cyan,parent,Enum.Material.Neon);r.CanCollide=false;r.Transparency=.24;return r end
local function stageLight(root,name,position,color,brightness,range)
 local anchor=part(name,Vector3.new(.2,.2,.2),CFrame.new(position),C.white,root,Enum.Material.SmoothPlastic);anchor.Transparency=1;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false
 local light=Instance.new("PointLight");light.Color=color;light.Brightness=brightness or 2;light.Range=range or 30;light.Shadows=true;light.Parent=anchor
 return anchor
end
local function judgeBackdrop(root,name,x,z,color,width,height)
 local panel=part(name.."Backdrop",Vector3.new(width,height,1.1),CFrame.new(x,height*.5+5,z),C.darkstone,root,Enum.Material.Slate)
 panel.CanCollide=false
 rune(root,name.."BackdropLeft",Vector3.new(.45,height+.8,.2),CFrame.new(x-width*.5+.55,height*.5+5,z+.62),color)
 rune(root,name.."BackdropRight",Vector3.new(.45,height+.8,.2),CFrame.new(x+width*.5-.55,height*.5+5,z+.62),color)
 rune(root,name.."BackdropTop",Vector3.new(width-.8,.45,.2),CFrame.new(x,height+4.6,z+.62),color)
 stageLight(root,name.."KeyLight",Vector3.new(x,19,z+7),color,1.8,30)
end
local function cylinder(name,diameter,height,cframe,color,parent,material)
 local p=part(name,Vector3.new(height,diameter,diameter),cframe*CFrame.Angles(0,0,math.rad(90)),color,parent,material);p.Shape=Enum.PartType.Cylinder;return p
end
local function trimBlock(root,name,size,cframe)
 return part(name,size,cframe,C.gold,root,Enum.Material.Metal)
end
local function marbleColumn(root,x,z,height)
 part("ColumnBase",Vector3.new(6.8,1.4,6.8),CFrame.new(x,.7,z),C.white,root,Enum.Material.Marble)
 part("Column",Vector3.new(5.2,height,5.2),CFrame.new(x,1.4+height*.5,z),C.stone,root,Enum.Material.Marble)
 trimBlock(root,"ColumnGoldBand",Vector3.new(5.7,.45,5.7),CFrame.new(x,height*.58,z))
 trimBlock(root,"ColumnGoldBand",Vector3.new(5.7,.45,5.7),CFrame.new(x,height*.78,z))
 part("ColumnCapital",Vector3.new(7,1.5,7),CFrame.new(x,height+2.15,z),C.white,root,Enum.Material.Marble)
end
local function bannerPanel(root,x,y,z,labelText)
 local panel=part("RoyalBanner",Vector3.new(7.5,14,.45),CFrame.new(x,y,z),C.navy,root,Enum.Material.Fabric);panel.CanCollide=false
 trimBlock(root,"BannerTop",Vector3.new(8.1,.42,.55),CFrame.new(x,y+7.1,z+.05))
 trimBlock(root,"BannerLeft",Vector3.new(.28,13.6,.55),CFrame.new(x-3.55,y,z+.05))
 trimBlock(root,"BannerRight",Vector3.new(.28,13.6,.55),CFrame.new(x+3.55,y,z+.05))
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(420,760);gui.Parent=panel
 local emblem=Instance.new("TextLabel");emblem.BackgroundTransparency=1;emblem.Size=UDim2.fromScale(1,1);emblem.Text="◆\n"..labelText;emblem.TextColor3=C.gold;emblem.TextScaled=true;emblem.TextWrapped=true;emblem.Font=Enum.Font.GothamBold;emblem.Parent=gui
end
local function waterfall(root,x,z,height)
 local water=part("Waterfall",Vector3.new(8,height,.55),CFrame.new(x,height*.5+5,z),C.water,root,Enum.Material.Glass);water.Transparency=.28;water.CanCollide=false;water.CastShadow=false
 local foam=rune(root,"WaterfallFoam",Vector3.new(8.5,.35,2.2),CFrame.new(x,5.15,z+1),C.pale);foam.Transparency=.18
 local pool=part("WaterPool",Vector3.new(11,.25,5),CFrame.new(x,.66,z+2),C.water,root,Enum.Material.Glass);pool.Transparency=.25;pool.CanCollide=false
 stageLight(root,"WaterGlow",Vector3.new(x,8,z+2),C.water,.8,18)
end
local function garden(root,x,z,scale)
 local s=scale or 1
 local planter=part("Planter",Vector3.new(7*s,1.7*s,4.5*s),CFrame.new(x,.85*s,z),C.white,root,Enum.Material.Marble)
 trimBlock(root,"PlanterTrim",Vector3.new(7.2*s,.28*s,4.7*s),CFrame.new(x,1.65*s,z))
 for i,offset in ipairs({Vector3.new(-2.1,2.2,0),Vector3.new(0,2.8,.3),Vector3.new(2,2.1,-.2),Vector3.new(-.8,3.6,-.4),Vector3.new(1.1,3.8,.2)})do
  local leaf=part("LeafCluster"..i,Vector3.new(2.7*s,2.7*s,2.7*s),CFrame.new(x+offset.X*s,offset.Y*s,z+offset.Z*s),i%2==0 and C.green or C.leaf,root,Enum.Material.Grass);leaf.Shape=Enum.PartType.Ball;leaf.CanCollide=false
 end
end
local function terrace(root,side)
 local x=side*39
 for row=0,3 do
  local z=4-row*8
  part("SpectatorTerrace",Vector3.new(12,1.3,6.5),CFrame.new(x,row*1.3+.65,z),C.white,root,Enum.Material.Marble)
  trimBlock(root,"TerraceTrim",Vector3.new(12.2,.22,6.7),CFrame.new(x,row*1.3+1.34,z))
 end
end
local function judgePlinth(root,name,x,z,color,role)
 local base=part(name.."Plinth",Vector3.new(18,4.8,11),CFrame.new(x,7.8,z),C.white,root,Enum.Material.Marble)
 trimBlock(root,name.."PlinthGold",Vector3.new(18.5,.5,11.5),CFrame.new(x,10.25,z))
 local plaque=part(name.."Plaque",Vector3.new(13.8,3.3,.5),CFrame.new(x,7.3,z+5.75),C.navy,root,Enum.Material.Metal);plaque.CanCollide=false
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(760,220);gui.Parent=plaque
 local label=Instance.new("TextLabel");label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.Text=name.."\n"..role;label.TextColor3=color;label.TextScaled=true;label.TextWrapped=true;label.Font=Enum.Font.GothamBold;label.Parent=gui
 stageLight(root,name.."HeroLight",Vector3.new(x,17,z+7),color,2.2,32)
 return base
end
local function worldModeSign(root,x,z,titleText,subtitleText,color)
 local post=part("ModeSignPost",Vector3.new(.8,7,.8),CFrame.new(x,3.5,z),C.gold,root,Enum.Material.Metal)
 local board=part("ModeSign",Vector3.new(15,7,.55),CFrame.lookAt(Vector3.new(x,7,z),Vector3.new(0,6,7)),C.navy,root,Enum.Material.Metal);board.CanCollide=false
 trimBlock(root,"ModeSignTop",Vector3.new(15.6,.35,.7),board.CFrame*CFrame.new(0,3.6,0))
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(820,360);gui.Parent=board
 local title=Instance.new("TextLabel");title.BackgroundTransparency=1;title.Position=UDim2.fromScale(.06,.1);title.Size=UDim2.fromScale(.88,.48);title.Text=titleText;title.TextColor3=color;title.TextScaled=true;title.TextWrapped=true;title.Font=Enum.Font.GothamBold;title.Parent=gui
 local sub=Instance.new("TextLabel");sub.BackgroundTransparency=1;sub.Position=UDim2.fromScale(.08,.62);sub.Size=UDim2.fromScale(.84,.24);sub.Text=subtitleText;sub.TextColor3=C.white;sub.TextScaled=true;sub.TextWrapped=true;sub.Font=Enum.Font.Gotham;sub.Parent=gui
 return post
end
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
local function heroPart(model,name,size,cframe,color,material)
 local p=part(name,size,cframe,color,model,material or Enum.Material.Metal);p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;return p
end
local function heroBall(model,name,size,cframe,color,material)
 local p=heroPart(model,name,Vector3.new(size,size,size),cframe,color,material);p.Shape=Enum.PartType.Ball;return p
end
local function heroWedge(model,name,size,cframe,color,material)
 local p=Instance.new("WedgePart");p.Name=name;p.Size=size;p.CFrame=cframe;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Color=color;p.Material=material or Enum.Material.Metal;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=model;return p
end
local function reactionEmitter(parent,color,speed,spread)
 local emitter=Instance.new("ParticleEmitter");emitter.Name="HeroReaction";emitter.Enabled=false;emitter.Rate=0;emitter.Color=ColorSequence.new(color);emitter.LightEmission=.8;emitter.Lifetime=NumberRange.new(.45,.8);emitter.Speed=NumberRange.new(speed*.7,speed);emitter.SpreadAngle=Vector2.new(spread,spread);emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.42),NumberSequenceKeypoint.new(.5,.22),NumberSequenceKeypoint.new(1,0)});emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(1,1)});emitter.Parent=parent;return emitter
end
local function decorateHero(model,name,boxCFrame,boxSize,color)
 local center=boxCFrame.Position;local w,h,d=boxSize.X,boxSize.Y,boxSize.Z;local front=center.Z+d*.5+.35
 local signature={Parts={},IdleParts={}}
 local function keep(p)table.insert(signature.Parts,p);return p end
 local core=keep(heroBall(model,name.."HeroCore",math.clamp(w*.16,1.6,3),CFrame.new(center.X,center.Y+h*.02,front),color,Enum.Material.Neon));core.Transparency=.05;signature.Core=core;signature.Emitter=reactionEmitter(core,color,name=="RIVET"and 12 or 8,name=="MOSS"and 85 or 55);glow(core,color,22,2.2)
 if name=="PIP"then
  local white=Color3.fromRGB(242,246,250)
  keep(heroPart(model,"PIPChestPlate",Vector3.new(w*.58,h*.16,.45),CFrame.new(center.X,center.Y+h*.06,front-.1),white,Enum.Material.Metal))
  keep(heroPart(model,"PIPGoldSash",Vector3.new(w*.62,.38,.5),CFrame.new(center.X,center.Y+h*.13,front),C.gold,Enum.Material.Metal))
  local halo=keep(heroBall(model,"PIPHalo",math.clamp(w*.48,4.5,8),CFrame.new(center.X,center.Y+h*.39,center.Z-d*.15),C.blue,Enum.Material.Neon));halo.Transparency=.78;signature.Halo=halo
  local beam=keep(heroPart(model,"PIPBalanceBeam",Vector3.new(w*.72,.32,.32),CFrame.new(center.X,center.Y+h*.17,front+1.3),C.gold,Enum.Material.Metal));signature.Beam=beam
  local left=keep(heroPart(model,"PIPScaleLeft",Vector3.new(w*.22,.28,d*.26),CFrame.new(center.X-w*.25,center.Y+h*.08,front+1.15),C.blue,Enum.Material.Neon));left.Transparency=.12
  local right=keep(heroPart(model,"PIPScaleRight",Vector3.new(w*.22,.28,d*.26),CFrame.new(center.X+w*.25,center.Y+h*.08,front+1.15),C.blue,Enum.Material.Neon));right.Transparency=.12
  signature.LeftScale=left;signature.RightScale=right
  keep(heroPart(model,"PIPLeftWing",Vector3.new(w*.18,h*.32,.5),CFrame.new(center.X-w*.43,center.Y+h*.15,center.Z)*CFrame.Angles(0,0,math.rad(-18)),C.gold,Enum.Material.Metal))
  keep(heroPart(model,"PIPRightWing",Vector3.new(w*.18,h*.32,.5),CFrame.new(center.X+w*.43,center.Y+h*.15,center.Z)*CFrame.Angles(0,0,math.rad(18)),C.gold,Enum.Material.Metal))
  signature.IdleStyle="BALANCE";signature.IdleParts={left,right};signature.ReactionDuration=.46;signature.ReactionPitch=math.rad(-3)
 elseif name=="RIVET"then
  keep(heroPart(model,"RIVETChestPlate",Vector3.new(w*.64,h*.2,.55),CFrame.new(center.X,center.Y+h*.03,front-.05),Color3.fromRGB(47,48,56),Enum.Material.Metal))
  for index,offset in ipairs({-.16,0,.16})do
   local crack=keep(heroPart(model,"RIVETCrack"..index,Vector3.new(.34,h*.26,.28),CFrame.new(center.X+offset*w,center.Y+h*.02,front+.25)*CFrame.Angles(0,0,math.rad(index==2 and -22 or 22)),C.red,Enum.Material.Neon));crack.Transparency=.08
  end
  local fist=keep(heroPart(model,"RIVETPowerFist",Vector3.new(w*.38,h*.25,d*.72),CFrame.new(center.X+w*.42,center.Y-h*.08,front+.8),C.red,Enum.Material.Metal));signature.PowerFist=fist
  local knuckle=keep(heroPart(model,"RIVETKnuckleGlow",Vector3.new(w*.32,.7,d*.6),CFrame.new(center.X+w*.42,center.Y-h*.02,front+1.2),C.red,Enum.Material.Neon));knuckle.Transparency=.08;signature.Knuckle=knuckle
  keep(heroWedge(model,"RIVETHornLeft",Vector3.new(w*.18,h*.24,d*.2),CFrame.new(center.X-w*.24,center.Y+h*.48,center.Z)*CFrame.Angles(0,math.rad(90),math.rad(-18)),Color3.fromRGB(35,36,43),Enum.Material.Metal))
  keep(heroWedge(model,"RIVETHornRight",Vector3.new(w*.18,h*.24,d*.2),CFrame.new(center.X+w*.24,center.Y+h*.48,center.Z)*CFrame.Angles(0,math.rad(-90),math.rad(18)),Color3.fromRGB(35,36,43),Enum.Material.Metal))
  keep(heroPart(model,"RIVETLeftShoulder",Vector3.new(w*.3,h*.18,d*.58),CFrame.new(center.X-w*.48,center.Y+h*.2,center.Z),Color3.fromRGB(49,50,58),Enum.Material.Metal))
  keep(heroPart(model,"RIVETRightShoulder",Vector3.new(w*.3,h*.18,d*.58),CFrame.new(center.X+w*.48,center.Y+h*.2,center.Z),Color3.fromRGB(49,50,58),Enum.Material.Metal))
  signature.IdleStyle="POWER";signature.IdleParts={knuckle};signature.ReactionDuration=.34;signature.ReactionPitch=math.rad(-9)
 elseif name=="MOSS"then
  keep(heroPart(model,"MOSSChestBark",Vector3.new(w*.58,h*.22,.52),CFrame.new(center.X,center.Y+h*.02,front-.08),C.wood,Enum.Material.Wood))
  local staff=keep(heroPart(model,"MOSSStaff",Vector3.new(.7,h*.78,.7),CFrame.new(center.X+w*.46,center.Y-h*.02,center.Z),C.wood,Enum.Material.Wood));signature.Staff=staff
  local staffOrb=keep(heroBall(model,"MOSSStaffOrb",math.clamp(w*.2,1.8,3.3),CFrame.new(center.X+w*.46,center.Y+h*.4,center.Z),color,Enum.Material.Neon));signature.StaffOrb=staffOrb;glow(staffOrb,color,18,1.6)
  for index,spec in ipairs({
   {-1,w*.18,h*.47,-22},{-1,w*.3,h*.56,-42},{-1,w*.38,h*.43,-62},
   {1,w*.18,h*.47,22},{1,w*.3,h*.56,42},{1,w*.38,h*.43,62}
  })do
   local side,xoff,yoff,angle=spec[1],spec[2],spec[3],spec[4]
   keep(heroPart(model,"MOSSAntler"..index,Vector3.new(.5,h*.23,.5),CFrame.new(center.X+side*xoff,center.Y+yoff,center.Z)*CFrame.Angles(0,0,math.rad(angle)),C.wood,Enum.Material.Wood))
  end
  for index,pos in ipairs({Vector3.new(-w*.4,h*.18,0),Vector3.new(-w*.28,h*.27,.1),Vector3.new(w*.38,h*.17,0),Vector3.new(w*.26,h*.29,.05),Vector3.new(0,h*.32,-.15)})do
   local leaf=keep(heroBall(model,"MOSSLeaf"..index,math.clamp(w*.18,1.5,2.8),CFrame.new(center+pos),index%2==0 and C.green or C.leaf,Enum.Material.Grass));leaf.Transparency=.03;table.insert(signature.IdleParts,leaf)
  end
  signature.IdleStyle="GROWTH";signature.ReactionDuration=.7;signature.ReactionPitch=math.rad(-4)
 end
 for _,p in ipairs(signature.Parts)do p:SetAttribute("HeroBaseSizeX",p.Size.X);p:SetAttribute("HeroBaseSizeY",p.Size.Y);p:SetAttribute("HeroBaseSizeZ",p.Size.Z);p:SetAttribute("HeroBaseColor",p.Color)end
 if signature.LeftScale then signature.LeftScaleOffset=model:GetPivot():ToObjectSpace(signature.LeftScale.CFrame)end
 if signature.RightScale then signature.RightScaleOffset=model:GetPivot():ToObjectSpace(signature.RightScale.CFrame)end
 return signature
end
local function baseSize(p)
 if not p then return nil end
 return Vector3.new(p:GetAttribute("HeroBaseSizeX")or p.Size.X,p:GetAttribute("HeroBaseSizeY")or p.Size.Y,p:GetAttribute("HeroBaseSizeZ")or p.Size.Z)
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
 local boxCFrame,boxSize=m:GetBoundingBox()
 judgeTag(m,name,color,boxCFrame,boxSize)
 local signature=decorateHero(m,name,boxCFrame,boxSize,color)
 m.PrimaryPart=body;World.Judges[name]={Model=m,BaseCFrame=body.CFrame,Eye=eye,Light=light,Signature=signature,ReactionStarted=0,ReactionUntil=0,ReactionPitch=signature.ReactionPitch or 0,IdleAmplitude=name=="RIVET"and .12 or(name=="MOSS"and .18 or .16)}
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
  local signature=decorateHero(m,name,boxCFrame,scaledSize,color)
  local highlight=Instance.new("Highlight");highlight.Name="GuardianOutline";highlight.FillColor=color;highlight.FillTransparency=.9;highlight.OutlineColor=color;highlight.OutlineTransparency=.08;highlight.DepthMode=Enum.HighlightDepthMode.Occluded;highlight.Parent=m
  -- Set PrimaryPart for float animation
  if not m.PrimaryPart then
   m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart", true)
  end
  World.Judges[name]={Model=m,BaseCFrame=m:GetPivot(),Eye=eye,Light=light,Signature=signature,ReactionStarted=0,ReactionUntil=0,ReactionPitch=signature.ReactionPitch or 0,IdleAmplitude=name=="RIVET"and .12 or(name=="MOSS"and .18 or .16)}
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
  local signature=data.Signature or{};local duration=signature.ReactionDuration or .4
  data.ReactionStarted=now;data.ReactionUntil=now+duration;data.ReactionPitch=reaction.Earned and(signature.ReactionPitch or math.rad(-4))or math.rad(2)
  TweenService:Create(data.Eye,TweenInfo.new(.14),{Transparency=reaction.Earned and 0 or .52,Size=reaction.Earned and Vector3.new(5.2,1.15,.55)or Vector3.new(3.1,.65,.35)}):Play()
  if reaction.Earned then
   if signature.Emitter then signature.Emitter:Emit(reaction.Judge=="RIVET"and 34 or(reaction.Judge=="MOSS"and 24 or 18))end
   if reaction.Judge=="PIP"then
    if signature.Halo then TweenService:Create(signature.Halo,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=.52,Size=baseSize(signature.Halo)*1.14}):Play()end
    if signature.LeftScale then TweenService:Create(signature.LeftScale,TweenInfo.new(.22),{Color=C.gold,Transparency=0}):Play()end
    if signature.RightScale then TweenService:Create(signature.RightScale,TweenInfo.new(.22),{Color=C.gold,Transparency=0}):Play()end
   elseif reaction.Judge=="RIVET"then
    if signature.PowerFist then TweenService:Create(signature.PowerFist,TweenInfo.new(.16,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=baseSize(signature.PowerFist)*1.16}):Play()end
    if signature.Knuckle then TweenService:Create(signature.Knuckle,TweenInfo.new(.12),{Transparency=0,Color=C.orange}):Play()end
   elseif reaction.Judge=="MOSS"then
    if signature.StaffOrb then TweenService:Create(signature.StaffOrb,TweenInfo.new(.3,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Size=baseSize(signature.StaffOrb)*1.22,Color=C.pale}):Play()end
    for _,leaf in ipairs(signature.IdleParts or{})do if leaf and leaf.Parent then TweenService:Create(leaf,TweenInfo.new(.32),{Color=C.green,Size=baseSize(leaf)*1.08}):Play()end end
   end
  end
  task.delay(duration,function()
   if data.Eye.Parent then TweenService:Create(data.Eye,TweenInfo.new(.25),{Transparency=0,Size=Vector3.new(4,.8,.4)}):Play()end
   if reaction.Judge=="PIP"then
    if signature.Halo and signature.Halo.Parent then TweenService:Create(signature.Halo,TweenInfo.new(.3),{Transparency=.78,Size=baseSize(signature.Halo)}):Play()end
    for _,scale in ipairs({signature.LeftScale,signature.RightScale})do if scale and scale.Parent then TweenService:Create(scale,TweenInfo.new(.3),{Color=C.blue,Transparency=.12}):Play()end end
   elseif reaction.Judge=="RIVET"then
    if signature.PowerFist and signature.PowerFist.Parent then TweenService:Create(signature.PowerFist,TweenInfo.new(.28),{Size=baseSize(signature.PowerFist)}):Play()end
    if signature.Knuckle and signature.Knuckle.Parent then TweenService:Create(signature.Knuckle,TweenInfo.new(.25),{Transparency=.08,Color=C.red}):Play()end
   elseif reaction.Judge=="MOSS"then
    if signature.StaffOrb and signature.StaffOrb.Parent then TweenService:Create(signature.StaffOrb,TweenInfo.new(.35),{Size=baseSize(signature.StaffOrb),Color=C.green}):Play()end
    for _,leaf in ipairs(signature.IdleParts or{})do if leaf and leaf.Parent then TweenService:Create(leaf,TweenInfo.new(.35),{Size=baseSize(leaf),Color=leaf:GetAttribute("HeroBaseColor")or C.green}):Play()end end
   end
  end)
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

 -- Bright marble foundation and ceremonial center.
 part("ArenaFloor",Vector3.new(Definitions.Arena.SizeX,1,Definitions.Arena.SizeZ),CFrame.new(0,0,Definitions.Arena.CenterZ),C.stone,root,Enum.Material.Marble)
 part("ArenaApron",Vector3.new(84,.22,56),CFrame.new(0,.61,-4),C.white,root,Enum.Material.Marble)
 local arenaDisc=cylinder("ArenaDisc",39,.42,CFrame.new(0,.86,5),C.white,root,Enum.Material.Marble)
 arenaDisc.CanCollide=true
 local goldRing=cylinder("ArenaGoldRing",41,.16,CFrame.new(0,1.09,5),C.gold,root,Enum.Material.Metal);goldRing.CanCollide=false
 local innerDisc=cylinder("ArenaInnerDisc",31,.2,CFrame.new(0,1.2,5),Color3.fromRGB(235,239,244),root,Enum.Material.Marble);innerDisc.CanCollide=false
 local innerRing=cylinder("ArenaInnerGoldRing",32.5,.12,CFrame.new(0,1.33,5),C.gold,root,Enum.Material.Metal);innerRing.CanCollide=false
 rune(root,"ArenaAxisN",Vector3.new(.35,.08,25),CFrame.new(0,1.38,-1),C.blue)
 rune(root,"ArenaAxisE",Vector3.new(25,.08,.35),CFrame.new(0,1.39,5),C.blue)

 -- Grand entrance path and staircase.
 part("EntryPath",Vector3.new(16,.3,17),CFrame.new(0,.72,24),C.white,root,Enum.Material.Marble)
 for i=0,6 do
  local y=.8+i*.55;local z=17-i*1.65;local width=24-i*.9
  part("GrandStair",Vector3.new(width,1.1,2),CFrame.new(0,y,z),C.white,root,Enum.Material.Marble)
  trimBlock(root,"GrandStairGold",Vector3.new(width+.15,.16,.22),CFrame.new(0,y+.62,z+1.02))
 end
 rune(root,"EntryPathLeft",Vector3.new(.3,.12,16.5),CFrame.new(-7.6,.92,24),C.gold)
 rune(root,"EntryPathRight",Vector3.new(.3,.12,16.5),CFrame.new(7.6,.92,24),C.gold)

 -- Monumental back wall, columns and royal banners.
 part("TempleWall",Vector3.new(90,38,3),CFrame.new(0,20,-36.5),C.white,root,Enum.Material.Marble)
 part("TempleWallInset",Vector3.new(72,30,.8),CFrame.new(0,19,-34.55),Color3.fromRGB(202,210,221),root,Enum.Material.Marble)
 for _,x in ipairs({-40,-28,28,40})do marbleColumn(root,x,-31,28)end
 for _,x in ipairs({-34,34})do marbleColumn(root,x,8,22)end
 bannerPanel(root,-31,20,-34,"PIP")
 bannerPanel(root,31,20,-34,"MOSS")
 bannerPanel(root,-12,22,-34,"RIVET")
 bannerPanel(root,12,22,-34,"ARENA")
 waterfall(root,-42,-34,29);waterfall(root,42,-34,29)

 -- Side terraces and gardens keep the arena rich without blocking play.
 terrace(root,-1);terrace(root,1)
 garden(root,-32,22,1);garden(root,32,22,1)
 garden(root,-32,-8,.9);garden(root,32,-8,.9)
 garden(root,-43,8,.72);garden(root,43,8,.72)

 -- Judge staircase/dais.
 for i=0,4 do
  local width=64-i*5;local z=-12.5-i*2.4;local y=1.5+i*.9
  part("JudgeStair",Vector3.new(width,1.8,2.6),CFrame.new(0,y,z),C.white,root,Enum.Material.Marble)
  trimBlock(root,"JudgeStairGold",Vector3.new(width+.1,.18,.25),CFrame.new(0,y+.98,z+1.35))
 end
 part("JudgeDais",Vector3.new(66,5,14),CFrame.new(0,6.8,-27.5),C.white,root,Enum.Material.Marble)
 trimBlock(root,"JudgeDaisGold",Vector3.new(66.5,.55,14.5),CFrame.new(0,9.55,-27.5))
 judgePlinth(root,"RIVET",-23,-28,C.red,"REASON • CLARITY")
 judgePlinth(root,"PIP",0,-31,C.blue,"EXAMPLE • STRUCTURE")
 judgePlinth(root,"MOSS",23,-28,Color3.fromRGB(74,224,113),"REBUTTAL • NUANCE")

 -- World-space mode cards mirror the actual UI choices.
 worldModeSign(root,-28,22,"DEBATE A\nREAL PLAYER","HUMAN OPPONENT • MULTIPLAYER",C.cyan)
 worldModeSign(root,28,22,"SOLO PRACTICE","SCRIPTED BOT • NO WINNER",C.gold)

 -- Hero arena sign and flame accents.
 local sign=part("DebateSign",Vector3.new(30,4.5,.65),CFrame.new(0,19,-12.3),C.navy,root,Enum.Material.Metal);text(sign,"GUARDIAN DEBATE ARENA",C.gold)
 trimBlock(root,"DebateSignTop",Vector3.new(31,.35,.8),CFrame.new(0,21.55,-12.3))
 for _,x in ipairs({-43,-25,25,43})do torchBowl(root,x,-25)end
 for _,x in ipairs({-22,22})do torchBowl(root,x,12)end

 -- Player podiums: marble base, navy face, gold rim, reactive rune.
 local function podium(name,cframe)
  part(name.."Base",Vector3.new(9.5,2.3,8.5),CFrame.new(cframe.X,1.2,cframe.Z),C.white,root,Enum.Material.Marble)
  local face=part(name.."Face",Vector3.new(7.6,2.3,.5),CFrame.new(cframe.X,2.1,cframe.Z+4.15),C.navy,root,Enum.Material.Metal);face.CanCollide=false
  trimBlock(root,name.."GoldRim",Vector3.new(9.9,.35,8.9),CFrame.new(cframe.X,2.48,cframe.Z))
  local p=part(name,Vector3.new(8,1.2,7),CFrame.new(cframe.X,2.9,cframe.Z),C.darkstone,root,Enum.Material.Marble)
  local r=rune(root,name.."Rune",Vector3.new(8.4,.18,7.4),CFrame.new(cframe.X,3.53,cframe.Z),C.blue)
  return p,r
 end
 World.Podiums[1],World.PodRunes[1]=podium("PlayerPodiumA",CFrame.new(-10,0,6))
 World.Podiums[2],World.PodRunes[2]=podium("PlayerPodiumB",CFrame.new(10,0,6))

 -- Existing sanitized guardians remain the functional judge models, now framed as hero statues.
 local rivet=Definitions.Judges.RIVET;local pip=Definitions.Judges.PIP;local moss=Definitions.Judges.MOSS
 guardian(root,"RIVET",rivet.X,rivet.Y,rivet.Z,C.red,"square",rivet.Height)
 guardian(root,"PIP",pip.X,pip.Y,pip.Z,C.blue,"square",pip.Height)
 guardian(root,"MOSS",moss.X,moss.Y,moss.Z,Color3.fromRGB(74,224,113),"round",moss.Height)

 -- Decorative collectibles move to the gardens instead of occupying the arena focal point.
 local blip=Definitions.Collectibles.BLIP;local zapp=Definitions.Collectibles.ZAPP;local chomp=Definitions.Collectibles.CHOMP
 collectible(root,"BLIP",Vector3.new(blip.X,blip.Y,blip.Z),C.cyan)
 collectible(root,"ZAPP",Vector3.new(zapp.X,zapp.Y,zapp.Z),C.gold)
 collectible(root,"CHOMP",Vector3.new(chomp.X,chomp.Y,chomp.Z),C.green)

 local audio=part("ArenaAudio",Vector3.new(1,1,1),CFrame.new(0,4,0),C.navy,root);audio.Transparency=1;audio.CanCollide=false
 sound(audio,"TurnStart",Definitions.Sounds.TurnStart,.18);sound(audio,"TenSecondWarning",Definitions.Sounds.TenSecondWarning,.14)
 sound(audio,"ScoreTick",Definitions.Sounds.ScoreTick,.1);sound(audio,"VerdictSting",Definitions.Sounds.VerdictSting,.2);sound(audio,"MatchWin",Definitions.Sounds.MatchWin,.22)

 local spawnDefinition=Definitions.Spawn;local spawn=Instance.new("SpawnLocation");spawn.Name="DebateSpawn";spawn.Size=Vector3.new(8,1,5);spawn.CFrame=CFrame.lookAt(Vector3.new(spawnDefinition.X,spawnDefinition.Y+1.1,spawnDefinition.Z+5),Vector3.new(spawnDefinition.LookX,spawnDefinition.LookY,spawnDefinition.LookZ));spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Transparency=1;spawn.Parent=root;World.Spawn=spawn
 local cameraFocus=part("ArenaCameraFocus",Vector3.new(1,1,1),CFrame.new(0,14,-22),C.navy,root);cameraFocus.Transparency=1;cameraFocus.CanCollide=false;cameraFocus.CanTouch=false;cameraFocus.CanQuery=false
 local cameraAnchor=part("ArenaCameraAnchor",Vector3.new(1,1,1),CFrame.lookAt(Vector3.new(0,21,43),cameraFocus.Position),C.navy,root);cameraAnchor.Transparency=1;cameraAnchor.CanCollide=false;cameraAnchor.CanTouch=false;cameraAnchor.CanQuery=false

 -- Bright sky-temple grade.
 Lighting.ClockTime=14.2;Lighting.Brightness=3;Lighting.ExposureCompensation=.34;Lighting.Ambient=Color3.fromRGB(145,154,170);Lighting.OutdoorAmbient=Color3.fromRGB(188,197,211);Lighting.FogColor=Color3.fromRGB(202,224,242);Lighting.FogStart=220;Lighting.FogEnd=820;Lighting.EnvironmentDiffuseScale=1;Lighting.EnvironmentSpecularScale=.9;Lighting.GlobalShadows=true;Lighting.ShadowSoftness=.38
 local bloom=Lighting:FindFirstChild("BeatTheBotBloom");if not bloom then bloom=Instance.new("BloomEffect");bloom.Name="BeatTheBotBloom";bloom.Parent=Lighting end;bloom.Intensity=.18;bloom.Size=20;bloom.Threshold=1.35
 local grade=Lighting:FindFirstChild("BeatTheBotColorGrade");if not grade then grade=Instance.new("ColorCorrectionEffect");grade.Name="BeatTheBotColorGrade";grade.Parent=Lighting end;grade.Brightness=.06;grade.Contrast=.08;grade.Saturation=.12;grade.TintColor=Color3.fromRGB(251,248,238)
 local rays=Lighting:FindFirstChild("BeatTheBotSunRays");if not rays then rays=Instance.new("SunRaysEffect");rays.Name="BeatTheBotSunRays";rays.Parent=Lighting end;rays.Intensity=.06;rays.Spread=.74
 local atmosphere=Lighting:FindFirstChild("BeatTheBotAtmosphere");if not atmosphere then atmosphere=Instance.new("Atmosphere");atmosphere.Name="BeatTheBotAtmosphere";atmosphere.Parent=Lighting end;atmosphere.Density=.18;atmosphere.Offset=.1;atmosphere.Color=Color3.fromRGB(215,232,246);atmosphere.Decay=Color3.fromRGB(143,164,190);atmosphere.Glare=.08;atmosphere.Haze=1.2

 stageLight(root,"ArenaWarmFill",Vector3.new(0,18,17),Color3.fromRGB(255,230,185),1.2,55)
 stageLight(root,"ArenaCoolFill",Vector3.new(0,15,-3),Color3.fromRGB(190,225,255),1.3,48)

 task.spawn(function()
  local elapsed=0
  while root.Parent do
   elapsed+=.035
   local now=os.clock()
   for id,data in pairs(World.Judges)do if data.Model.Parent then
    local phase=id=="RIVET"and 0 or(id=="PIP"and 2 or 4);local pitch=0
    if now<data.ReactionUntil then local progress=(now-data.ReactionStarted)/(data.ReactionUntil-data.ReactionStarted);pitch=math.sin(math.clamp(progress,0,1)*math.pi)*data.ReactionPitch end
    local amplitude=data.IdleAmplitude or .16
    data.Model:PivotTo(data.BaseCFrame*CFrame.new(0,math.sin(elapsed+phase)*amplitude,0)*CFrame.Angles(pitch,0,0))
    local signature=data.Signature
    if signature and signature.IdleStyle=="BALANCE"and signature.LeftScale and signature.RightScale and signature.LeftScaleOffset and signature.RightScaleOffset then
     local sway=math.sin(elapsed*1.25+phase)*.045
     local pivot=data.Model:GetPivot()
     signature.LeftScale.CFrame=pivot*signature.LeftScaleOffset*CFrame.Angles(0,0,sway)
     signature.RightScale.CFrame=pivot*signature.RightScaleOffset*CFrame.Angles(0,0,-sway)
    elseif signature and signature.IdleStyle=="GROWTH"and signature.StaffOrb then
     signature.StaffOrb.Transparency=.06+math.abs(math.sin(elapsed*1.3))*.12
    elseif signature and signature.IdleStyle=="POWER"and signature.Knuckle then
     signature.Knuckle.Transparency=.05+math.abs(math.sin(elapsed*2.6))*.12
    end
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
