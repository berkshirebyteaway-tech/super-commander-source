local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
local Audio=require(script.Parent.ToyAudio)
local Particles=require(script.Parent.ToyParticles)
local L=require(script.Parent.Localization)
local M={};M.__index=M
local function color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
function M.new()
    local f=Instance.new("Folder");f.Name="FrontierEffects";f.Parent=workspace
    local self=setmetatable({folder=f,active=0,maxActive=4,rings={},lastId=0,reduced=false,flashes=true,poses={},lastOrder={},stamps=0,connections=0,flashCount=0,epoch=0},M)
    local Motion=require(script.Parent.CharacterMotion);Motion.posing=self.poses
    self.particles=Particles.new(f)
    self.orderFx=require(script.Parent.CommanderOrderFx).new(f)
    RunService.RenderStepped:Connect(function(dt)
        if self.reduced then self.particles:clear() else self.particles:step(dt) end
        self.orderFx:step(dt,self.reduced)
    end)
    RunService.PreAnimation:Connect(function()
        for joint,p in pairs(self.poses) do
            if joint.Parent then if p.base then joint.Transform=p.base;p.base=nil end else self.poses[joint]=nil end
        end
    end)
    RunService.PreSimulation:Connect(function(dt)
        for joint,p in pairs(self.poses) do
            p.elapsed+=dt;if self.reduced then p.elapsed=p.duration end
            if not joint.Parent or p.elapsed>=p.duration then self.poses[joint]=nil;f:SetAttribute("PoseWeight",0);continue end
            local weight=M.poseWeight(p.elapsed/p.duration,p.victory)
            p.base=joint.Transform;local from=p.base;local held,hw=Motion.stance(joint);if held then from=from:Lerp(held,hw)end
            joint.Transform=from:Lerp(p.target,math.clamp(weight,0,1))*p.overshoot:Lerp(CFrame.identity,1-math.max(0,weight-1)/.08)
            f:SetAttribute("PoseWeight",weight)
        end
    end)
    return self
end
function M:burst(position,style,large)
    self:bricks(position,{color(style.primary or style.accent),color(style.accent),color(style.secondary or {191,239,255})},large and 10 or 5,large and 2.4 or 1.5)
end
function M:bricks(position,colors,count,force,assemble,priority)
    if not self.reduced then self.particles:burst(position,colors,count,force,assemble,priority) end
end
function M:connection(a,b,tint,kind)
    if self.reduced or self.connections>=3 or (b-a).Magnitude<.1 then return end
    self.connections+=1;local epoch=self.epoch
    local model=Instance.new('Model');model.Name='TacticalConnection';model:SetAttribute('Kind',kind);model.Parent=self.folder
    local lift=math.min(4,(b-a).Magnitude*.06)
    for i=1,8 do
        local t0,t1=(i-1)/8,i/8
        local start=a:Lerp(b,t0)+Vector3.new(0,math.sin(t0*math.pi)*lift,0)
        local finish=a:Lerp(b,t1)+Vector3.new(0,math.sin(t1*math.pi)*lift,0)
        local p=Instance.new('Part');p.Name='SignalSegment';p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
        p.Color=tint;p.Transparency=.45;p.Material=Enum.Material.SmoothPlastic;p.Size=Vector3.new(.08,.06,(finish-start).Magnitude*.76);p.CFrame=CFrame.lookAt((start+finish)/2,finish);p.Parent=model
        TweenService:Create(p,TweenInfo.new(.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,(i-1)*.025),{Transparency=1}):Play()
    end
    self.folder:SetAttribute('LastConnection',kind);self.folder:SetAttribute('Connections',(self.folder:GetAttribute('Connections')or 0)+1)
    Debris:AddItem(model,.6);task.delay(.6,function()if epoch==self.epoch then self.connections=math.max(0,self.connections-1)end end)
end
function M:flash(position,tint)
    if self.reduced or self.flashes==false or self.flashCount>=2 then return end
    self.flashCount+=1;local epoch=self.epoch
    local model=Instance.new('Model');model.Name='ImpactGlint';model.Parent=self.folder
    local p=Instance.new('Part');p.Name='Glint';p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
    p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.Neon;p.Color=tint;p.Transparency=.35;p.Size=Vector3.new(.8,.35,.8);p.Position=position+Vector3.new(0,.45,0);p.Parent=model
    local light=Instance.new('PointLight');light.Color=tint;light.Brightness=1.8;light.Range=8;light.Shadows=false;light.Parent=p
    TweenService:Create(p,TweenInfo.new(.22),{Transparency=1,Size=Vector3.new(1.4,.08,1.4)}):Play();TweenService:Create(light,TweenInfo.new(.22),{Brightness=0}):Play()
    Debris:AddItem(model,.25);task.delay(.25,function()if epoch==self.epoch then self.flashCount=math.max(0,self.flashCount-1)end end)
end
function M:ring(position,tint,radius,priority,shape)
    if self.reduced then return end
    priority=priority or 0
    local live={};for _,r in ipairs(self.rings)do if r.live then table.insert(live,r)end end;self.rings=live
    if self.active>=self.maxActive then
        local victim=nil
        for _,r in ipairs(self.rings)do if r.priority<priority and (not victim or r.priority<victim.priority)then victim=r end end
        if not victim then return end
        victim.live=false;victim.model:Destroy();self.active-=1
    end
    self.active+=1
    local epoch=self.epoch
    local model=Instance.new("Model");model.Name="ToyPulseRing";model.Parent=self.folder
    local record={model=model,priority=priority,live=true};table.insert(self.rings,record)
    model:SetAttribute("Priority",priority)
    model:SetAttribute("Shape",shape or "pulse")
    for i=1,12 do
        local a=(i-.5)/12*math.pi*2;local dir=Vector3.new(math.cos(a),0,math.sin(a))
        local p=Instance.new("Part");p.Name="RingDash";p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Material=Enum.Material.SmoothPlastic;p.Color=tint;p.Transparency=.25
        p.Size=Vector3.new(.09,.045,radius*.3);p.CFrame=CFrame.lookAt(position+dir*radius*.5,position+dir*radius*.5+dir)*CFrame.Angles(0,math.pi/2,0);p.Parent=model
        local target=position+dir*radius
        if shape=="build"then
            local corner=math.floor((i-1)/3);local segment=(i-1)%3
            local yaw=CFrame.Angles(0,corner*math.pi/2,0)
            local at=Vector3.new(radius*.58,.06,radius*.58)
            local offset=segment==0 and Vector3.new(-radius*.14,0,0)or segment==1 and Vector3.new(0,0,-radius*.14)or Vector3.new(0,.2,0)
            p.Size=segment==0 and Vector3.new(radius*.3,.055,.075)or segment==1 and Vector3.new(.075,.055,radius*.3)or Vector3.new(.075,.4,.075)
            p.CFrame=CFrame.new(position)*yaw*CFrame.new(at+offset);target=p.Position+Vector3.new(0,.65,0)
        elseif shape=="intercept"then
            local arm=math.floor((i-1)/3);local segment=(i-1)%3
            local direction=Vector3.new(math.cos(math.pi/4+arm*math.pi/2),0,math.sin(math.pi/4+arm*math.pi/2))
            p.Size=Vector3.new(.13,.07,radius*.22)
            p.CFrame=CFrame.lookAt(position+direction*radius*(.12+segment*.19),position+direction*radius*2)
            target=p.Position+direction*radius*.55
        end
        TweenService:Create(p,TweenInfo.new(.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=target,Transparency=1}):Play()
    end
    Debris:AddItem(model,.6);task.delay(.6,function()if record.live and epoch==self.epoch then record.live=false;self.active=math.max(0,self.active-1)end end)
end
function M:stamp(position,text,tint)
    if self.stamps>=2 then return end;self.stamps+=1
    local epoch=self.epoch
    local anchor=Instance.new("Part");anchor.Name="ToyStamp";anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Transparency=1;anchor.Size=Vector3.one*.05;anchor.Position=position;anchor.Parent=self.folder
    local b=Instance.new("BillboardGui");b.Size=UDim2.fromOffset(150,30);b.StudsOffsetWorldSpace=Vector3.new(0,2,0);b.AlwaysOnTop=false;b.MaxDistance=350;b.Parent=anchor
    local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.Text=L.text(text);t.TextColor3=tint;t.TextStrokeColor3=Color3.fromRGB(38,55,54);t.TextStrokeTransparency=.1;t.Font=Enum.Font.BuilderSansBold;t.TextSize=16;t.Parent=b
    if not self.reduced then TweenService:Create(b,TweenInfo.new(.9),{StudsOffsetWorldSpace=Vector3.new(0,3,0)}):Play() end
    TweenService:Create(t,TweenInfo.new(.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,.6),{TextTransparency=1,TextStrokeTransparency=1}):Play()
    Debris:AddItem(anchor,1);task.delay(1,function()if epoch==self.epoch then self.stamps=math.max(0,self.stamps-1)end end)
end
function M:clear()
    self.epoch+=1;self.active=0;self.rings={};self.stamps=0;self.connections=0;self.flashCount=0
    self.particles:clear();self.lastOrder={};self.orderFx:clear()
    for _,child in ipairs(self.folder:GetChildren()) do if child:IsA("Model") or child:IsA("BillboardGui") or child.Name=="ToyStamp" then child:Destroy() end end
end
function M.poseWeight(t,victory)
    local up,hold=victory and .18 or .2,victory and .58 or .6
    if t<up then local u=t/up-1;return 1+2.2*u*u*u+1.2*u*u end
    if t<hold then return 1 end
    return .5+.5*math.cos((t-hold)/(1-hold)*math.pi)
end
local function joint(character,r15,r6)
    local legacy=nil
    for _,o in ipairs(character:GetDescendants())do
        if o:IsA("AnimationConstraint")or o:IsA("Motor6D")then
            if o.Name==r15 then return o,false end
            if r6 and o.Name==r6 and o:IsA("Motor6D")then legacy=o end
        end
    end
    if legacy then return legacy,true end
end
function M:pose(character,kind,tier)
    if self.reduced or not character then return end
    local victory=kind=="victory";local duration=victory and 1.4 or .72
    local shoulder,r6=joint(character,"RightShoulder","Right Shoulder")
    if not shoulder or self.poses[shoulder] then return end
    local function add(j,target,overshoot)
        if j and not self.poses[j] then self.poses[j]={elapsed=0,duration=duration,victory=victory,target=target,overshoot=overshoot or CFrame.identity} end
    end
    local lift=math.rad(victory and 150 or 100+(tier or 0)*2)
    add(shoulder,r6 and CFrame.Angles(0,0,lift)or CFrame.Angles(lift,0,math.rad(victory and 32 or 6)),r6 and CFrame.Angles(0,0,math.rad(6))or CFrame.Angles(math.rad(6),0,0))
    local left,leftR6=joint(character,"LeftShoulder","Left Shoulder")
    if victory then add(left,leftR6 and CFrame.Angles(0,0,-lift)or CFrame.Angles(lift,0,math.rad(-32)))
    else
        add(left,leftR6 and CFrame.identity or CFrame.Angles(math.rad(-8),0,math.rad(-6)))
        add((joint(character,"RightElbow")),CFrame.identity)
        add((joint(character,"Waist")),CFrame.Angles(math.rad(-5),math.rad(14),0))
    end
    self.folder:SetAttribute("PoseRig",shoulder.ClassName)
end
function M:receive(event)
    if type(event)~="table" or event.schema~=1 or type(event.id)~="number" or event.id<=self.lastId then return end
    if event.roomId~=self.roomId or self.roomId==nil then return end
    self.lastId=event.id;self.folder:SetAttribute("LastEvent",event.kind);self.folder:SetAttribute("EventCount",(self.folder:GetAttribute("EventCount") or 0)+1)
    local style=Catalog.get(event.style)
    local p=Players:GetPlayerByUserId(event.playerId or 0);local char=p and p.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
    if p==Players.LocalPlayer then Audio.play(event.kind) end
    if event.kind=="attack" or event.kind=="build" or event.kind=="upgrade" then
        if root and os.clock()-(self.lastOrder[p] or 0)>.2 then
            self.lastOrder[p]=os.clock();self:pose(char,nil,style.tier)
            if self.orderFx:emit(style,root,event.kind,self.reduced)and p==Players.LocalPlayer and os.clock()-(self.lastCollectionSound or -10)>=8 then
                self.lastCollectionSound=os.clock();require(script.Parent.CollectionArt).sound(style)
            end
            local lot=event.kind=="build" and type(event.position)=="table" and Vector3.new(event.position[1],event.position[2],event.position[3])
            if lot then self:burst(lot,style,false);self:ring(lot,color(style.accent),2.2,1,"build") else self:burst(root.Position-Vector3.new(0,2,0),style,false) end
            if not self.reduced and p~=Players.LocalPlayer then
                local b=Instance.new("BillboardGui");b.Name="CommanderOrder";b.Size=UDim2.fromOffset(120,40);b.StudsOffsetWorldSpace=Vector3.new(0,4,0);b.AlwaysOnTop=false;b.Adornee=root;b.Parent=self.folder
                local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.Text=L.text(({attack="출격",build="건설 개시",upgrade="강화"})[event.kind]);t.TextColor3=color(style.accent);t.TextStrokeTransparency=.25;t.Font=Enum.Font.BuilderSansBold;t.TextSize=20;t.Parent=b
                TweenService:Create(b,TweenInfo.new(.85),{StudsOffsetWorldSpace=Vector3.new(0,6,0)}):Play();TweenService:Create(t,TweenInfo.new(.85),{TextTransparency=1,TextStrokeTransparency=1}):Play();Debris:AddItem(b,1)
            end
        end
    end
    if event.kind=="grow" and root and not self.reduced then
        self:burst(root.Position-Vector3.new(0,2,0),style,true)
        local b=Instance.new("BillboardGui");b.Name="CommanderGrow";b.Size=UDim2.fromOffset(120,40);b.StudsOffsetWorldSpace=Vector3.new(0,5,0);b.Adornee=root;b.Parent=self.folder
        local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.Text=L.text("규모 확대");t.TextColor3=color(style.accent);t.TextStrokeTransparency=.25;t.Font=Enum.Font.BuilderSansBold;t.TextSize=24;t.Parent=b
        local scale=Instance.new("UIScale");scale.Scale=.4;scale.Parent=t
        TweenService:Create(scale,TweenInfo.new(.35,Enum.EasingStyle.Quint),{Scale=1}):Play()
        TweenService:Create(t,TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,.7),{TextTransparency=1,TextStrokeTransparency=1}):Play();Debris:AddItem(b,1.2)
    end
    if (event.kind=="settle" or event.kind=="relocate") and type(event.position)=="table" then
        if p==Players.LocalPlayer then Audio.play("confirm") end
        self:burst(Vector3.new(event.position[1],event.position[2],event.position[3]),style,event.kind=="settle")
        if root and not self.reduced then
            self:pose(char)
            local b=Instance.new("BillboardGui");b.Name="CommanderSpawn";b.Size=UDim2.fromOffset(140,40);b.StudsOffsetWorldSpace=Vector3.new(0,4,0);b.Adornee=root;b.Parent=self.folder
            local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.Text=L.text(event.kind=="settle" and "여기서 시작" or "자리 이동");t.TextColor3=color(style.accent);t.TextStrokeTransparency=.25;t.Font=Enum.Font.BuilderSansBold;t.TextSize=20;t.Parent=b
            TweenService:Create(b,TweenInfo.new(1.1),{StudsOffsetWorldSpace=Vector3.new(0,6.5,0)}):Play();TweenService:Create(t,TweenInfo.new(.5,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,.6),{TextTransparency=1,TextStrokeTransparency=1}):Play();Debris:AddItem(b,1.2)
        end
    end
    if (event.kind=="complete" or event.kind=="upgrade") and type(event.position)=="table" then self:burst(Vector3.new(event.position[1],event.position[2],event.position[3]),style,true) end
end
function M:attachProjectileTrail(projectile,styleId)
    local style=Catalog.get(styleId)
    local a=Instance.new("Attachment");a.Position=Vector3.new(-.2,0,0);a.Parent=projectile
    local b=Instance.new("Attachment");b.Position=Vector3.new(.2,0,0);b.Parent=projectile
    local t=Instance.new("Trail");t.Attachment0=a;t.Attachment1=b;t.Color=ColorSequence.new(color(style.primary),color(style.accent));t.Lifetime=self.reduced and .1 or .55;t.LightEmission=.7;t.FaceCamera=true;t.Parent=projectile
    return t
end
function M:createProjectile(kind,loadout)
    local style=Catalog.forSlot(loadout,"projectile")
    local body=Instance.new("Part");body.Name=kind.."Visual";body.Size=Vector3.new(.65,.65,2.5);body.Shape=Enum.PartType.Cylinder;body.Anchored=true;body.CanCollide=false;body.CanTouch=false;body.CanQuery=false;body.CastShadow=false;body.Color=color(style.secondary);body.Material=Enum.Material.Metal
    body.Parent=self.folder;self:attachProjectileTrail(body,loadout and loadout.trail)
    return {body=body,kind=kind,cosmetics=loadout}
end
function M:updateProjectile(handle,position,direction)
    if handle.body.Parent then handle.body.CFrame=CFrame.lookAt(position,position+direction) end
end
function M:impactProjectile(handle,position)
    handle.body:Destroy();self:burst(position,Catalog.forSlot(handle.cosmetics,"impact"),true)
end
return M
