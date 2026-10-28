local Audio=require(script.Parent.ToyAudio)
local Sound=game:GetService('SoundService')
local Tween=game:GetService('TweenService')
local M={};M.__index=M
local SMOKE='rbxasset://textures/particles/smoke_main.dds'
local WIND=9125742262
local function part(parent,name,size,cf,color,material,shape)
    local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;if shape then p.Shape=shape end;p.Parent=parent;return p
end
local jet
function M.new(parent)
    local self=setmetatable({jets={},fx={},streaks={},escorts={},wing={},cloudEmitters={},shake=0,time=0},M)
    local gui=Instance.new('ScreenGui');gui.Name='DropSpectacle';gui.IgnoreGuiInset=true;gui.ScreenInsets=Enum.ScreenInsets.None;gui.ClipToDeviceSafeArea=false;gui.ResetOnSpawn=false;gui.DisplayOrder=6
    gui.Parent=parent:FindFirstAncestorOfClass('PlayerGui');self.gui=gui
    self.flash=Instance.new('Frame');self.flash.Name='CloudFlash';self.flash.Size=UDim2.fromScale(1,1);self.flash.BorderSizePixel=0;self.flash.BackgroundColor3=Color3.fromRGB(236,244,250);self.flash.BackgroundTransparency=1;self.flash.Parent=gui
    self.wind=Instance.new('Sound');self.wind.Name='DropWind';self.wind.SoundId='rbxassetid://'..WIND;self.wind.Looped=true;self.wind.Volume=0;self.wind.Parent=Sound
    return self
end
function M:begin(folder,reduced,touch)
    self:clear();self.folder=folder;self.reduced=reduced;self.touch=touch;self.started=true
    local anchor=part(folder,'Slipstream',Vector3.one*.2,CFrame.new(),Color3.new(1,1,1));anchor.Transparency=1;self.anchor=anchor
    local count=reduced and 0 or touch and 10 or 18
    local random=Random.new(41)
    for i=1,count do
        local a0=Instance.new('Attachment');a0.Parent=anchor;local a1=Instance.new('Attachment');a1.Parent=anchor
        local b=Instance.new('Beam');b.Attachment0=a0;b.Attachment1=a1;b.FaceCamera=true;b.LightInfluence=0;b.LightEmission=.5;b.Segments=1
        b.Color=ColorSequence.new(Color3.fromRGB(214,238,248));b.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,.35),NumberSequenceKeypoint.new(1,1)})
        b.Width0=0;b.Width1=0;b.Parent=anchor
        local angle=random:NextNumber(0,math.pi*2);local radius=random:NextNumber(3.5,17)
        self.streaks[i]={beam=b,a0=a0,a1=a1,x=math.cos(angle)*radius,z=math.sin(angle)*radius,phase=random:NextNumber(),length=random:NextNumber(5,10),width=random:NextNumber(.07,.16)}
    end
    self.escorts={};self.wing={}
    if not reduced then
        local hull=Color3.fromRGB(176,188,200)
        for i=1,3 do self.escorts[i]=jet(folder,12,hull)end
        for i=1,(touch and 3 or 5)do self.wing[i]=jet(folder,14,hull)end
    end
end
local PARK=CFrame.new(0,-1e4,0)
function jet(folder,length,color)
    local m=Instance.new('Model');m.Name='EscortJet';local trails={}
    local s=length/10
    local body=part(m,'Fuselage',Vector3.new(10,1.1,1.2)*s,CFrame.new(),color,Enum.Material.SmoothPlastic,Enum.PartType.Ball);m.PrimaryPart=body
    part(m,'Spine',Vector3.new(6,.8,.9)*s,CFrame.new(-1*s,.15*s,0),color,Enum.Material.SmoothPlastic)
    part(m,'Stripe',Vector3.new(4,.1,.92)*s,CFrame.new(-1*s,.56*s,0),Color3.fromRGB(54,226,208),Enum.Material.Neon)
    part(m,'Canopy',Vector3.new(2.2,.6,.7)*s,CFrame.new(2.4*s,.5*s,0),Color3.fromRGB(28,52,70),Enum.Material.Glass,Enum.PartType.Ball)
    for side=-1,1,2 do
        part(m,'Wing',Vector3.new(3.6,.14,4.6)*s,CFrame.new(-1.2*s,0,side*2.5*s)*CFrame.Angles(0,side*.5,0),color,Enum.Material.SmoothPlastic)
        part(m,'Stabilizer',Vector3.new(1.6,.12,1.6)*s,CFrame.new(-4.2*s,.1*s,side*1.1*s)*CFrame.Angles(0,side*.45,0),color,Enum.Material.SmoothPlastic)
        part(m,'Fin',Vector3.new(1.6,1.6,.1)*s,CFrame.new(-4*s,.95*s,side*.45*s)*CFrame.Angles(side*.25,0,0),color,Enum.Material.SmoothPlastic)
        part(m,'NavLight',Vector3.new(.35,.2,.35)*s,CFrame.new(-1.6*s,.1*s,side*4.3*s),side<0 and Color3.fromRGB(255,80,80)or Color3.fromRGB(90,255,140),Enum.Material.Neon,Enum.PartType.Ball)
    end
    local burner=part(m,'Afterburner',Vector3.new(.5,.7,.7)*s,CFrame.new(-5.1*s,0,0),Color3.fromRGB(255,170,90),Enum.Material.Neon,Enum.PartType.Ball)
    local glow=Instance.new('PointLight');glow.Color=Color3.fromRGB(255,170,100);glow.Brightness=2;glow.Range=8*s;glow.Shadows=false;glow.Parent=burner
    for side=-1,1,2 do
        local a=Instance.new('Attachment');a.Position=Vector3.new(-1.5*s,0,side*4.2*s);a.Parent=body
        local b=Instance.new('Attachment');b.Position=Vector3.new(-1.5*s,.12*s,side*4.2*s);b.Parent=body
        local t=Instance.new('Trail');t.Attachment0=a;t.Attachment1=b;t.Lifetime=1.6;t.MinLength=.2;t.FaceCamera=true;t.LightInfluence=0;t.LightEmission=.2
        t.Color=ColorSequence.new(Color3.fromRGB(240,246,250));t.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(1,1)})
        t.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,3)});t.Enabled=false;t.Parent=body;table.insert(trails,t)
    end
    local a=Instance.new('Attachment');a.Position=Vector3.new(-5.2*s,-.25*s,0);a.Parent=body
    local b=Instance.new('Attachment');b.Position=Vector3.new(-5.2*s,.25*s,0);b.Parent=body
    local t=Instance.new('Trail');t.Attachment0=a;t.Attachment1=b;t.Lifetime=.35;t.FaceCamera=true;t.LightEmission=1;t.LightInfluence=0
    t.Color=ColorSequence.new(Color3.fromRGB(255,190,110),Color3.fromRGB(255,120,60));t.Transparency=NumberSequence.new(.2,1);t.Enabled=false;t.Parent=body;table.insert(trails,t)
    m:PivotTo(PARK);m.Parent=folder;return {model=m,trails=trails}
end
function M:formation(pool,from,to,seconds,offsets)
    local frame=CFrame.lookAt(from,to)
    for i,o in ipairs(offsets)do local j=pool[i];if j then
        j.from=from;j.to=to;j.frame=frame;j.offset=o;j.start=self.time+(i-1)*.05;j.seconds=seconds;j.flying=false;table.insert(self.jets,j)
    end end
end
function M:ring(at,radius,seconds,color,transparency)
    local p=part(self.folder,'DropRing',Vector3.new(.25,1,1),CFrame.new(at)*CFrame.Angles(0,0,math.pi/2),color,Enum.Material.Neon,Enum.PartType.Cylinder)
    p.Transparency=transparency
    Tween:Create(p,TweenInfo.new(seconds,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(.12,radius*2,radius*2),Transparency=1}):Play()
    table.insert(self.fx,{part=p,until_=self.time+seconds+.1})
end
function M:dust(at,count,color,radius)
    local p=part(self.folder,'DropDust',Vector3.one*.2,CFrame.new(at),color);p.Transparency=1
    local e=Instance.new('ParticleEmitter');e.Texture=SMOKE;e.Rate=0;e.Lifetime=NumberRange.new(.7,1.4);e.Speed=NumberRange.new(radius*.9,radius*1.6)
    e.SpreadAngle=Vector2.new(80,80);e.EmissionDirection=Enum.NormalId.Top;e.Acceleration=Vector3.new(0,-radius*.6,0);e.Drag=3
    e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,radius*.18),NumberSequenceKeypoint.new(1,radius*.5)})
    e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(1,1)});e.Color=ColorSequence.new(color)
    e.LightInfluence=.4;e.RotSpeed=NumberRange.new(-60,60);e.Rotation=NumberRange.new(0,360);e.Parent=p;e:Emit(count)
    table.insert(self.fx,{part=p,until_=self.time+1.6})
end
function M:deployed(at,color,own)
    if not self.started then return end
    self:ring(at,own and 11 or 7,.5,Color3.fromRGB(230,242,250),own and .45 or .6)
    if own then Audio.play('dropDeploy',1);self.shake=math.max(self.shake,.9)end
end
function M:landed(at,color,own)
    if not self.started then return end
    local earth=Color3.fromRGB(176,160,132):Lerp(color,.25)
    self:ring(at+Vector3.new(0,.15,0),own and 13 or 8,.65,color:Lerp(Color3.new(1,1,1),.55),own and .3 or .5)
    if not self.reduced then self:dust(at+Vector3.new(0,.4,0),own and (self.touch and 12 or 20)or 5,earth,own and 9 or 6)end
    if own then Audio.play('dropLand',1);self.shake=math.max(self.shake,1.4)end
end
function M:step(dt,info)
    if not self.started then return end
    if not info.paused then self.time+=dt end
    local reduced=self.reduced;local me=info.me
    if not self.escort and info.shot.active and info.elapsed>=.3 and info.camera then
        self.escort=true
        if not reduced and not info.obscured then
            local cam=info.camera;local center=cam.Position+cam.LookVector*95
            self:formation(self.escorts,center-cam.RightVector*190+cam.UpVector*10,center+cam.RightVector*190-cam.UpVector*6,1.5,{Vector3.zero,Vector3.new(-12,3,9),Vector3.new(12,-3,9)})
            Audio.play('dropJets',1)
        end
    end
    if not self.flyover and me and not info.shot.active and info.elapsed>=info.planeSeconds+.9 then
        self.flyover=true
        if not reduced and not info.obscured then
            local below=me.position-Vector3.new(0,math.clamp(me.position.Y-info.surfaceY,30,400)*.58,0)
            local dir=CFrame.Angles(0,info.heading+.6,0).LookVector
            self:formation(self.wing,below-dir*220,below+dir*220,2.2,{Vector3.zero,Vector3.new(-13,0,12),Vector3.new(13,0,12),Vector3.new(-26,0,24),Vector3.new(26,0,24)})
            Audio.play('dropJets',.8,.85)
        end
    end
    for i=#self.jets,1,-1 do
        local j=self.jets[i];local u=(self.time-j.start)/j.seconds
        if u>=1.6 then
            for _,t in ipairs(j.trails)do t.Enabled=false;t:Clear()end;j.model:PivotTo(PARK);j.flying=false;table.remove(self.jets,i)
        elseif u>=0 then
            local pos=j.from:Lerp(j.to,math.min(u,1.4))+j.frame:VectorToWorldSpace(j.offset)
            local bank=math.sin(u*math.pi)*.18
            j.model:PivotTo(CFrame.lookAt(pos,pos+j.frame.LookVector)*CFrame.Angles(0,math.pi/2,0)*CFrame.Angles(bank,0,0))
            if not j.flying then j.flying=true;for _,t in ipairs(j.trails)do t:Clear();t.Enabled=true end end
        end
    end
    if not self.clouds and me and me.free>.5 and not info.shot.active then
        self.clouds=true
        local deck=info.surfaceY+info.top*.6
        if me.position.Y>deck+20 and (info.wide or 0)<.5 then
            self.deckY=deck
            self.cloudEmitters={}
            local holder=part(self.folder,'CloudDeck',Vector3.one*.2,CFrame.new(me.position.X,deck,me.position.Z),Color3.new(1,1,1));holder.Transparency=1;self.deck=holder
            local rings=reduced and {{0,1},{20,5}}or self.touch and {{0,2},{18,6},{36,8}}or {{0,3},{17,8},{34,12},{52,12}}
            local random=Random.new(7)
            for _,r in ipairs(rings)do for k=1,r[2]do
                local a=Instance.new('Attachment');local angle=(k/r[2]+random:NextNumber(-.1,.1))*math.pi*2
                a.Position=Vector3.new(math.cos(angle)*r[1],random:NextNumber(-4,4),math.sin(angle)*r[1]);a.Parent=holder
                local e=Instance.new('ParticleEmitter');e.Texture=SMOKE;e.Rate=0;e.Speed=NumberRange.new(0,.6);e.Lifetime=NumberRange.new(11,12)
                e.Size=NumberSequence.new(random:NextNumber(16,26));e.LightInfluence=.25;e.LightEmission=.08;e.Color=ColorSequence.new(Color3.fromRGB(226,236,244))
                e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.06,.42),NumberSequenceKeypoint.new(.85,.5),NumberSequenceKeypoint.new(1,1)})
                e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-6,6);e.Parent=a;e:Emit(2);table.insert(self.cloudEmitters,e)
            end end
        end
    end
    if self.deckY and me then
        if not self.punched and me.position.Y<self.deckY+3 then self.punched=self.time
            if not reduced and info.flashes and not info.obscured and not me.landed then self.flash.BackgroundTransparency=.55;Tween:Create(self.flash,TweenInfo.new(.4),{BackgroundTransparency=1}):Play()end
            Audio.play('dropCloud',1);self.shake=math.max(self.shake,.5)
        end
        if self.punched and self.deck then
            local a=math.clamp((self.time-self.punched)/.9,0,1)
            for _,e in ipairs(self.cloudEmitters)do e.Transparency=NumberSequence.new(.45+.55*a)end
            if a>=1 then self.deck:Destroy();self.deck=nil;self.cloudEmitters={}end
        end
    end
    local intensity=me and not me.landed and (me.free*(1+me.dive*.6)+me.open*.25)or 0
    if info.shot.active then intensity*=.6 end
    if self.anchor and me then
        self.anchor.CFrame=CFrame.new(me.position)
        local speed=60+me.dive*55-me.open*40;local span=46
        for _,s in ipairs(self.streaks)do
            local y=((s.phase+self.time*speed/span)%1)*span-span*.6
            s.a0.Position=Vector3.new(s.x,y,s.z);s.a1.Position=Vector3.new(s.x,y+s.length*(.6+intensity*.5),s.z)
            local w=s.width*math.clamp(intensity,0,1.3)*(info.obscured and 0 or 1)
            s.beam.Width0=w;s.beam.Width1=w
        end
    end
    local muted=Sound:GetAttribute('ToySoundsMuted')==true or info.obscured or info.paused
    local volume=muted and 0 or math.clamp(intensity,0,1.4)*.32*(Sound:GetAttribute('ToySoundsVolume')or 1)
    if volume>.001 and not self.wind.Playing then self.wind:Play()end
    self.wind.Volume+=(volume-self.wind.Volume)*(1-math.exp(-dt*4));self.wind.PlaybackSpeed=.85+(me and me.dive*.15+me.free*.1 or 0)
    if self.wind.Volume<.002 and volume<=.001 and self.wind.Playing then self.wind:Stop()end
    for i=#self.fx,1,-1 do if self.time>=self.fx[i].until_ then self.fx[i].part:Destroy();table.remove(self.fx,i)end end
    self.shake*= math.exp(-dt*3.2)
end
function M:cameraOffset(base)
    local t=self.time;local amount=self.shake*.5+(base or 0)
    if amount<.003 then return CFrame.identity end
    return CFrame.new(math.noise(t*13,1.1)*amount,math.noise(t*13,4.7)*amount*.7,0)*CFrame.Angles(0,0,math.noise(t*9,8.3)*amount*.02)
end
function M:clear()
    self.started=false;self.escort=nil;self.flyover=nil;self.clouds=nil;self.deckY=nil;self.punched=nil;self.shake=0
    self.jets={};for _,list in ipairs({self.escorts or {},self.wing or {}})do for _,j in ipairs(list)do j.model:Destroy()end end;self.escorts={};self.wing={}
    for _,f in ipairs(self.fx)do f.part:Destroy()end;self.fx={}
    if self.deck then self.deck:Destroy();self.deck=nil end;self.cloudEmitters={}
    if self.anchor then self.anchor:Destroy();self.anchor=nil end;self.streaks={}
    self.flash.BackgroundTransparency=1;self.wind:Stop();self.wind.Volume=0
end
function M:destroy()self:clear();self.gui:Destroy();self.wind:Destroy()end
return M
