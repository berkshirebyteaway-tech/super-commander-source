local C=require(script.Parent.Parent.Core.CosmeticCatalog)
local T=require(script.Parent.TrailThemes)
local V=require(script.Parent.TrailVolume)
local M={};M.__index=M
local specs={
    dust={pieces={{kind='puff',every=.09,life=.8,cap=9}}},
    afterglow={pieces={}},
    lightning={pieces={{kind='bolt',every=.12,life=.4,cap=4}}},
    flame={pieces={{kind='feather',every=.16,life=1.1,cap=7},{kind='lick',every=.11,life=.6,cap=6}},wings=true},
    comet={pieces={{kind='star',every=.09,life=1,cap=10}},head=true},
}
for theme,spec in pairs(V.specs)do specs[theme]=spec end
local byTier={'dust','afterglow','lightning','flame','comet'}
local folder
local function fxFolder()
    if not folder or not folder.Parent then folder=Instance.new('Folder');folder.Name='CommanderTrailFx';folder.Parent=workspace end
    return folder
end
local function rgb(a)return Color3.fromRGB(table.unpack(a))end
function M.attach(model,style)
    if not model or style=='classic'or not C.styles[style]then return nil end
    local root=model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart');if not root then return nil end
    local skin=C.get(style);local tier=skin.tier or 1;local theme=specs[skin.theme]and skin.theme or byTier[tier]or 'dust'
    local h=model:FindFirstChildOfClass('Humanoid')
    local rs=math.clamp(math.max(root.Size.X,root.Size.Y,root.Size.Z)/2,.3,2.5)
    local self=setmetatable({root=root,parts={},trails={},emitters={},pool={},style=skin,theme=theme,spec=specs[theme],k=3.5*rs,
        foot=h and (h.HipHeight or 2)+root.Size.Y/2 or root.Size.Y/2,last=root.Position,age=0,clock=os.clock(),spawned={},open=0},M)
    local k=self.k;local accent,trim=rgb(skin.accent),rgb(skin.secondary)
    local function trail(name,a,b,life,color,transparency,width,emission)
        local a0,a1=Instance.new('Attachment'),Instance.new('Attachment');a0.Name=name..'0';a1.Name=name..'1'
        a0.Position=a;a1.Position=b;a0.Parent=root;a1.Parent=root;table.insert(self.parts,a0);table.insert(self.parts,a1)
        local t=Instance.new('Trail');t.Name='CommanderTrail';t.Attachment0=a0;t.Attachment1=a1;t.Color=color
        t.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,transparency),NumberSequenceKeypoint.new(1,1)})
        t.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,width or .3)})
        t.Lifetime=life;t.MinLength=.1;t.FaceCamera=true;t.LightEmission=emission or 1;t.LightInfluence=0;t.Enabled=false;t.Parent=root
        table.insert(self.trails,t);return t,a0,a1
    end
    local function emitter(name,at,rate,life,size,speed,color,accel)
        local a=Instance.new('Attachment');a.Name=name;a.Position=at;a.Parent=root;table.insert(self.parts,a)
        local e=Instance.new('ParticleEmitter');e.Name=name;e.Rate=rate;e.Lifetime=NumberRange.new(life*.6,life);e.Speed=NumberRange.new(speed*.4,speed)
        e.SpreadAngle=Vector2.new(180,180);e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size),NumberSequenceKeypoint.new(1,0)})
        e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)});e.Color=color
        e.LightEmission=1;e.LightInfluence=0;e.Drag=3;e.Acceleration=accel or Vector3.zero;e.Enabled=false;e.Parent=a
        table.insert(self.emitters,e);return e
    end
    local feet=-self.foot
    if theme=='afterglow'then
        for _,x in ipairs({-.12*k,.12*k})do
            trail('Afterglow',Vector3.new(x,feet+.15*k,.05*k),Vector3.new(x,feet+.19*k,.05*k),.75,ColorSequence.new(accent,trim),0,.3)
            trail('AfterglowHalo',Vector3.new(x,feet+.1*k,.05*k),Vector3.new(x,feet+.22*k,.05*k),.6,ColorSequence.new(accent,trim),.66,.4)
        end
    elseif theme=='lightning'then
        trail('BoltPath',Vector3.new(0,feet+.02*k,.05*k),Vector3.new(0,feet+.05*k,.05*k),.4,ColorSequence.new(accent,rgb(skin.primary)),.35)
        emitter('LightningSparks',Vector3.new(0,feet+.1*k,0),24,.4,.07*k,2.5*k,ColorSequence.new(trim,accent),Vector3.new(0,-2*k,0))
    elseif theme=='flame'then
        trail('EmberPath',Vector3.new(0,feet+.02*k,.05*k),Vector3.new(0,feet+.1*k,.05*k),.5,ColorSequence.new(accent,Color3.fromRGB(236,124,36)),.45,.5)
        emitter('FlameEmbers',Vector3.new(0,feet+.92*k,.12*k),30,1,.06*k,.6*k,ColorSequence.new(trim,accent),Vector3.new(0,.8*k,0))
        self.wings=T.wings(fxFolder(),skin)
        for _,f in ipairs(self.wings)do table.insert(self.spawned,f.vane);table.insert(self.spawned,f.core)end
    elseif theme=='comet'then
        local y=feet+.44*k;local z=.3*k
        trail('CometTail',Vector3.new(0,y-.1*k,z),Vector3.new(0,y+.1*k,z),.6,ColorSequence.new(Color3.new(1,1,1),accent),.15,.2)
        for lane=1,2 do local _,a0,a1=trail('CometLane',Vector3.new(0,y,z),Vector3.new(0,y+.04*k,z),.6,ColorSequence.new(accent,trim),0,.2);self['lane'..lane]={a0,a1}end
        for _,x in ipairs({-.2*k,.2*k})do trail('CometVeil',Vector3.new(x,y-.22*k,z+.05*k),Vector3.new(x,y+.18*k,z+.05*k),.6,ColorSequence.new(accent,trim),.62,.6)end
        emitter('CometSparkles',Vector3.new(0,y,z),30,1.1,.08*k,.5*k,ColorSequence.new(Color3.new(1,1,1),accent))
        self.head=T.cometHead(fxFolder(),skin)
        for _,p in ipairs({self.head.core,self.head.glow,self.head.coma})do table.insert(self.spawned,p)end
        for _,p in ipairs(self.head.halo)do table.insert(self.spawned,p)end
    end
    if V.specs[theme]then V.attach(self,theme,trail,emitter,fxFolder())end
    for _,p in ipairs(self.spawned)do p.Transparency=1 end
    self.trail=self.trails[1]
    return self
end
function M:frame(delta)
    local look=self.root.CFrame.LookVector*Vector3.new(1,0,1)
    if look.Magnitude<.1 then look=delta*Vector3.new(1,0,1)end
    if look.Magnitude<.01 then look=Vector3.new(0,0,-1)end
    return CFrame.fromMatrix(self.root.Position-Vector3.new(0,self.foot,0),-look.Unit,Vector3.yAxis)
end
function M:spawn(piece,origin,now)
    local list=self.pool[piece.kind];if not list then list={};self.pool[piece.kind]=list end
    local e
    for _,v in ipairs(list)do if not v.live then e=v;break end end
    if not e and #list<piece.cap then
        e=T.element(piece.kind,fxFolder(),self.style,#list*1.7+self.style.tier,#list%2==0 and 1 or -1);table.insert(list,e)
        for _,p in ipairs(e.parts)do table.insert(self.spawned,p)end
    end
    if not e then
        e=list[1];for _,v in ipairs(list)do if v.born<e.born then e=v end end
    end
    e.live=true;e.born=now;e.origin=origin;e.life=piece.life;e.side=-(e.side or 1);e.seed+=1.618
end
function M:step(active,reduced)
    if not self.root.Parent then return self:destroy()end
    local now=os.clock();local dt=math.clamp(now-self.clock,0,.1);self.clock=now
    local pos=self.root.Position;local delta=pos-self.last;local moved=delta.Magnitude;self.last=pos
    self.age+=dt
    if not active and self.quiet==(reduced==true) then return end
    local moving=active==true and moved>.02 and moved<=35
    if moving then self.movingSince=self.movingSince or now else self.movingSince=nil end
    local phase=self.style.tier==5 and math.min(3,1+math.floor((self.movingSince and now-self.movingSince or 0)/.7))or 1
    if self.phase~=phase then self.phase=phase;self.root:SetAttribute('TrailEvolution',phase)end
    local k=self.k
    for i,t in ipairs(self.trails)do
        if moved>35 or not active then t:Clear()end
        t.Enabled=moving and (not reduced or i==1)
        if self.theme=='comet'then t.Lifetime=reduced and .22 or ({.45,.85,1.35})[phase]*(i==1 and 1 or .8)
        elseif reduced then t.Lifetime=.22 end
    end
    for _,e in ipairs(self.emitters)do e.Enabled=moving and not reduced end
    local frame=moving and self:frame(delta)
    for i,piece in ipairs(self.spec.pieces)do
        local every=reduced and (piece.kind=='puff'and piece.every*3 or nil)or piece.every
        if frame and every and (not piece.phase or phase>=piece.phase)then
            self.timers=self.timers or {};self.timers[i]=(self.timers[i]or 0)+dt
            if self.timers[i]>=every then self.timers[i]=0
                local origin=frame
                if piece.kind=='star'then origin=frame*CFrame.new(.3*k,0,0)elseif piece.at then origin=frame*CFrame.new(piece.at*k,0,0)end
                self:spawn(piece,origin,now)
            end
        end
    end
    local live=false
    for _,list in pairs(self.pool)do for _,e in ipairs(list)do
        if e.live then
            local u=(now-e.born)/e.life
            if u>=1 or reduced and e.kind~='puff'then e.live=false;T.hide(e)else T.pose(e,e.origin,u,now,k);live=true end
        end
    end end
    if self.wings or self.head or self.vol then
        self.open=math.clamp(self.open+(moving and not reduced and dt*4 or -dt*3),0,1)
        local body=(moving or self.open>0)and self:frame(delta)
        if self.wings and body then T.poseWings(self.wings,body*CFrame.new(.1*k,.92*k,0),now,k,self.open)end
        if self.head and body then T.poseHead(self.head,body*CFrame.new(.3*k,.44*k,0),now,k,phase,self.open>.3)end
        if self.vol then V.step(self,body,now,moving,reduced,phase)end
        if self.lane1 then
            local y=-self.foot+.44*k;local r=(.08+.04*phase)*k
            for lane=1,2 do local a=now*6+lane*math.pi;local list=self['lane'..lane]
                local off=Vector3.new(math.sin(a)*r,math.cos(a)*r,.3*k);list[1].Position=Vector3.new(0,y,0)+off;list[2].Position=Vector3.new(0,y+.05*k,0)+off
                self.trails[lane+1].Enabled=moving and not reduced and phase>=2
            end
            for i=4,5 do self.trails[i].Enabled=moving and not reduced and phase>=3 end
        end
    end
    if self.theme=='comet'and moving and now-(self.tint or 0)>.12 then
        self.tint=now
        for i,t in ipairs(self.trails)do t.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,i==1 and Color3.new(1,1,1)or T.prism(now*.4+i*.2,.6)),ColorSequenceKeypoint.new(.5,T.prism(now*.4+i*.2+.3,.6)),ColorSequenceKeypoint.new(1,T.prism(now*.4+i*.2+.6,.6))})end
    end
    if not active and not live and (self.open or 0)<=0 then self.quiet=reduced==true else self.quiet=nil end
    if active and moved>.02 and not self.heard then self.heard=true
        local p=game.Players.LocalPlayer
        if not reduced and p and (p.Character==self.root.Parent or self.root.Parent:GetAttribute('UserId')==p.UserId)then require(script.Parent.CollectionArt).sound(self.style)end
    end
end
function M:destroy()
    for _,t in ipairs(self.trails or {})do t:Destroy()end;self.trails={};self.trail=nil
    for _,e in ipairs(self.emitters or {})do e:Destroy()end;self.emitters={}
    for _,p in ipairs(self.parts or {})do p:Destroy()end;self.parts={}
    for _,p in ipairs(self.spawned or {})do p:Destroy()end;self.spawned={};self.pool={};self.wings=nil;self.head=nil;self.vol=nil
end
function M.watch()
    local Players=game:GetService('Players');local Run=game:GetService('RunService');local states={}
    local heartbeat=0
    Run.RenderStepped:Connect(function(dt)
        heartbeat+=dt
        if heartbeat>=.25 then
            heartbeat=0
            for _,p in ipairs(Players:GetPlayers())do
                local character=p.Character;local style=p:GetAttribute('CommanderTrailStyle')or 'classic';local old=states[p]
                if old and (old.character~=character or old.style~=style)then if old.fx then old.fx:destroy()end;states[p]=nil;old=nil end
                if character and character.PrimaryPart and not old then states[p]={character=character,style=style,fx=M.attach(character,style)}end
            end
        end
        local camera=workspace.CurrentCamera
        if not camera then return end
        for player,v in pairs(states)do
            if not player.Parent or not v.character.Parent then if v.fx then v.fx:destroy()end;states[player]=nil
            elseif v.fx then local root=v.character.PrimaryPart;v.fx:step(root~=nil and root.LocalTransparencyModifier<.99 and (root.Position-camera.CFrame.Position).Magnitude<250,Players.LocalPlayer:GetAttribute('CommanderReducedEffects')==true)end
        end
    end)
end
return M
