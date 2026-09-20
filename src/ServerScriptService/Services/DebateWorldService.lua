local Lighting = game:GetService("Lighting")
local World = { Spawn = nil }
local C = { navy=Color3.fromRGB(13,20,36), blue=Color3.fromRGB(74,104,132), cyan=Color3.fromRGB(80,220,232), gold=Color3.fromRGB(255,194,82), green=Color3.fromRGB(89,190,130), white=Color3.fromRGB(235,242,250) }
local function part(name,size,pos,color,parent,material)
 local p=Instance.new("Part"); p.Name=name;p.Size=size;p.Position=pos;p.Anchored=true;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local function text(target,value,color)
 local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(900,300);g.Parent=target
 local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Text=value;l.TextColor3=color or C.white;l.TextScaled=true;l.TextWrapped=true;l.Font=Enum.Font.GothamBold;l.Parent=g
end
local function bot(root,name,x,color,shape)
 local m=Instance.new("Model");m.Name=name;m.Parent=root
 part("Body",Vector3.new(3.2,4,2.2),Vector3.new(x,4,-5),color,m,Enum.Material.Metal)
 part("LeftArm",Vector3.new(.7,3,.7),Vector3.new(x-2,4,-5),color,m,Enum.Material.Metal)
 part("RightArm",Vector3.new(.7,3,.7),Vector3.new(x+2,4,-5),color,m,Enum.Material.Metal)
 part("Base",Vector3.new(3.8,.6,2.8),Vector3.new(x,1.7,-5),C.navy,m,Enum.Material.Metal)
 local h=part("Head",Vector3.new(2.4,2.4,2.4),Vector3.new(x,7.2,-5),C.white,m,Enum.Material.SmoothPlastic); if shape=="round" then h.Shape=Enum.PartType.Ball end
 local eye=part("Eye",Vector3.new(1.2,.35,.2),Vector3.new(x,7.25,-3.75),C.cyan,m,Enum.Material.Neon);eye.CanCollide=false
 local tag=Instance.new("BillboardGui");tag.Size=UDim2.fromOffset(110,32);tag.StudsOffset=Vector3.new(0,2.3,0);tag.AlwaysOnTop=true;tag.Parent=h
 local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundColor3=C.navy;l.BackgroundTransparency=.15;l.Text=name;l.TextColor3=color;l.TextScaled=true;l.Font=Enum.Font.GothamBold;l.Parent=tag
end
function World.Init()
 for _,name in ipairs({"BeatTheBotWorld","BeatTheBotDebateStage"})do local old=workspace:FindFirstChild(name);if old then old:Destroy()end end
 local root=Instance.new("Folder");root.Name="BeatTheBotDebateStage";root.Parent=workspace
 part("Stage",Vector3.new(24,1,20),Vector3.new(0,0,0),Color3.fromRGB(100,118,132),root,Enum.Material.Slate)
 part("StageInset",Vector3.new(20,.15,16),Vector3.new(0,.58,0),Color3.fromRGB(42,58,74),root,Enum.Material.SmoothPlastic)
 part("Backdrop",Vector3.new(24,12,1),Vector3.new(0,6,-10),C.blue,root,Enum.Material.Metal)
 local sign=part("DebateSign",Vector3.new(15,3,.5),Vector3.new(0,8.3,-9.4),C.navy,root,Enum.Material.Metal);text(sign,"ARGUE YOUR ASSIGNED SIDE",C.gold)
 part("Table",Vector3.new(10,1,3),Vector3.new(0,3,-1),C.blue,root,Enum.Material.Wood)
 part("TableBase",Vector3.new(1.2,3,1.2),Vector3.new(0,1.5,-1),C.gold,root,Enum.Material.Metal)
 part("PlayerChairA",Vector3.new(3,1,3),Vector3.new(-5,1.3,3),C.blue,root,Enum.Material.Wood)
 part("PlayerChairB",Vector3.new(3,1,3),Vector3.new(5,1.3,3),C.gold,root,Enum.Material.Wood)
 bot(root,"RIVET",-7,C.cyan,"antenna");bot(root,"PIP",0,C.gold,"square");bot(root,"MOSS",7,C.green,"round")
 local spawn=Instance.new("SpawnLocation");spawn.Name="DebateSpawn";spawn.Size=Vector3.new(8,1,5);spawn.Position=Vector3.new(0,1,7);spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Transparency=1;spawn.Parent=root;World.Spawn=spawn
 Lighting.ClockTime=14;Lighting.Brightness=3.2;Lighting.Ambient=Color3.fromRGB(155,165,180);Lighting.OutdoorAmbient=Color3.fromRGB(175,185,198);Lighting.EnvironmentDiffuseScale=1;Lighting.EnvironmentSpecularScale=.5
 return root
end
function World.Refresh() end
return World
