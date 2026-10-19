local Debris=game:GetService("Debris")
local RunService=game:GetService("RunService")
local G=require(script.Parent.ToyGeometry)
local WG=require(script.Parent.Parent.Core.WorldGeometry)
local Themes=require(script.Parent.NukeThemes)
local Skin=require(script.Parent.SkinMapStyle)
local M={};M.__index=M
local UP=Vector3.yAxis
local V=Vector3.new
local FLAT=CFrame.Angles(0,0,math.pi/2)
local ZC=CFrame.Angles(0,math.pi/2,0)
local NEON,SMOOTH=Enum.Material.Neon,Enum.Material.SmoothPlastic
local k,out2,out4=Themes.k,Themes.out2,Themes.out4
local features=require(script.Parent.Parent.Core.CollectionDefinitions).features
local phone
local function particleCap(tier)
    if phone==nil then local ok,r=pcall(function()local U=game:GetService("UserInputService");return U.TouchEnabled and not U.KeyboardEnabled end);phone=ok and r==true end
    local f=features[tier or 0];return f and (phone and f.particlesPhone or f.particlesPC)or 0
end
M.size={AtomBomb=1.1,HydrogenBomb=1.6,MIRV=1.5,MIRVWarhead=.55}

local function piece(parent,name,shape,size,cf,color,material,transparency)
    return Themes.part(parent,name,size,cf,color,material or NEON,transparency,shape=="sphere"and"ell"or shape=="cylinder"and"cyl"or shape~="block"and shape or nil)
end
local function trail(parent,name,half,colors,life,transparency,width,emission)
    local a=Instance.new("Attachment");a.Name=name.."A";a.Position=V(-half,0,0);a.Parent=parent
    local b=Instance.new("Attachment");b.Name=name.."B";b.Position=V(half,0,0);b.Parent=parent
    local t=Instance.new("Trail");t.Name=name;t.Attachment0=a;t.Attachment1=b;t.FaceCamera=true;t.Lifetime=life
    t.Color=colors;t.Transparency=transparency;t.WidthScale=width;t.LightEmission=emission;t.MinLength=.05;t.Parent=parent
    return t
end

local live,byModel,beat={},setmetatable({},{__mode="k"}),nil
local function drop(h)live[h]=nil;if byModel[h.model]==h then byModel[h.model]=nil end end
local function tick()
    local now=os.clock()
    for h in pairs(live)do
        if h.dead then drop(h)
        elseif h.model.Parent then h.orphan=nil;if h.step(now-h.t0)==false then drop(h);h.model:Destroy()end
        else h.orphan=h.orphan or now;if now-h.orphan>30 then drop(h)end end
    end
    if next(live)==nil and beat then beat:Disconnect();beat=nil end
end
local function track(model,step)
    local h={model=model,step=step,t0=os.clock()};live[h]=true;byModel[model]=h
    pcall(function()model.Destroying:Once(function()h.dead=true end)end)
    if not beat then local ok,c=pcall(function()return RunService.Heartbeat:Connect(tick)end);beat=ok and c or nil end
    return h
end
function M.pose(model,t)local h=byModel[model];if h then return h.step(t)end end

local function builder(model,s,w,owner,tier)
    local b={model=model,s=s,w=w,owner=owner,tier=tier,moves={},orbits={},emitters={},arcs={}}
    function b.add(name,size,cf,color,material,tr,shape)return Themes.part(model,name,size,cf,color,material or SMOOTH,tr,shape)end
    function b.rod(name,z0,z1,r,color,material,tr)return b.add(name,V(math.abs(z1-z0),r*2,r*2),CFrame.new(0,0,(z0+z1)/2)*ZC,color,material,tr,"cyl")end
    function b.band(z0,z1,r)return b.rod("OwnerBand",z0,z1,r,owner)end
    function b.blade(name,cf,L,h,th,color,material)
        return {b.add(name,V(th,h,L),cf*CFrame.new(0,h/2,0),color,material,0,"wedge"),b.add(name,V(th,h,L),cf*CFrame.new(0,-h/2,0)*CFrame.Angles(0,0,math.pi),color,material,0,"wedge")}
    end
    function b.ring(name,n,color)local list={};for i=1,n do list[i]=b.add(name,V(.1,.1,.1),CFrame.identity,color,NEON)end;return list end
    function b.move(list,fn)
        local homes,sizes={},{};for i,p in ipairs(list)do homes[i]=p.CFrame;sizes[i]=p.Size end
        table.insert(b.moves,{list=list,homes=homes,sizes=sizes,fn=fn})
    end
    b.trail=trail
    function b.anchor(name,at)local p=b.add(name,V(.05,.05,.05),CFrame.new(at),w.body,SMOOTH,1);return p end
    function b.emitter(name,props,cap)
        local holder=model:FindFirstChild("EmitterTail")or b.add("EmitterTail",V(.1,.1,.1)*s,CFrame.new(0,0,b.tail or 0),w.glow,SMOOTH,1)
        local e=Instance.new("ParticleEmitter");e.Name=name;for key,v in pairs(props)do e[key]=v end
        local limit=particleCap(tier);if cap>limit then e.Rate=e.Rate*math.max(0,limit)/cap end
        e.Enabled=false;e:SetAttribute("Cap",math.min(cap,limit));e.Parent=holder;table.insert(b.emitters,e);return e
    end
    function b.orbit(name,radius,speed,offset,width,colors,transparency,life)
        local a0=Instance.new("Attachment");a0.Name=name.."A";a0.Parent=b.exhaust
        local a1=Instance.new("Attachment");a1.Name=name.."B";a1.Parent=b.exhaust
        local t=Instance.new("Trail");t.Name=name;t.Attachment0=a0;t.Attachment1=a1;t.FaceCamera=true;t.Lifetime=life;t.Color=colors;t.Transparency=transparency
        t.WidthScale=NumberSequence.new(1,.3);t.LightEmission=1;t.MinLength=.05;t.Parent=b.exhaust
        table.insert(b.orbits,{a0=a0,a1=a1,r=radius,w=speed,off=offset,width=width})
    end
    function b.arc(name,color,width,length)
        local a0=Instance.new("Attachment");a0.Name=name.."A";a0.Parent=b.exhaust
        local a1=Instance.new("Attachment");a1.Name=name.."B";a1.CFrame=CFrame.new(0,0,length);a1.Parent=b.exhaust
        local beam=Instance.new("Beam");beam.Name=name;beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=width;beam.Width1=width*.3;beam.Segments=8
        beam.FaceCamera=true;beam.LightEmission=1;beam.Color=ColorSequence.new(color);beam.Transparency=NumberSequence.new(0,.6);beam.Parent=b.exhaust
        table.insert(b.arcs,{beam=beam,a0=a0,a1=a1,length=length})
    end
    return b
end
local function scaled(cf,scale)return scale==1 and cf or CFrame.new(cf.Position*scale)*cf.Rotation end
local Meshes=require(script.Parent.CosmeticMeshes)
local function meshWarhead(b,model,style,owner,s,info)
    local key,tier=style.id,style.tier or 0;local function rgb(a)return Color3.fromRGB(table.unpack(a))end
    for _,c in ipairs(model:GetChildren())do c:Destroy()end;b.moves={}
    local k=s*.5;local list=Meshes.build(model,key,{scale=k,colors={team=owner,primary=rgb(style.primary),secondary=rgb(style.secondary),accent=rgb(style.accent)}})
    local st=Meshes.stats(key)
    local names={Body=true,Shell=true,Shaft=true,Hull=true,Casing=true};local body
    for _,e in ipairs(Meshes.rig(key).parts)do local z=e.def.size;if names[e.def.name]then body=e;break end
        if math.max(z[1],z[2])<=1.6 and(not body or z[3]>body.def.size[3])then body=e end end
    local bz=body.home.Position.Z*k;local bl=body.def.size[3]*k;local br=math.min(body.def.size[1],body.def.size[2])*k/2
    local rate=tier>=5 and 1.6 or 1.2;local phases=false
    local crest=Meshes.crestKind(key,tier,'nuclear')
    if crest then Meshes.crest(model,list,crest,CFrame.new(0,0,bz+bl*.3)*CFrame.Angles(math.pi/2,0,0),br*1.8,rgb(style.accent))end
    for _,r in ipairs(list)do
        r.part.CastShadow=false
        local hue=Meshes.prismatic(r,tier);if r.phase then phases=true end
        if r.kind or r.phase or hue then
            b.move({r.part},function(t,phase,_,l,homes)
                local p=l[1];if r.kind then p.CFrame=Meshes.motion(r,t,0,rate)*homes[1]end
                if r.phase then p.Transparency=phase<r.phase and 1 or 0 end
                if hue then p.Color=Meshes.prism(t*.06+r.index*.07)end
            end)
        end
    end
    b.rod('OwnerBand',bz+bl*.08,bz+bl*.08+.12*s,br*1.06,owner)
    model:SetAttribute('MeshItem',key)
    local tips;if info.tips then
        local fin;for _,e in ipairs(Meshes.rig(key).parts)do if e.def.name:find('Fin')then fin=e end end
        local z=(fin and fin.home.Position.Z or st.hi.Z*.8)*k;local r=(fin and fin.def.size[1]/2 or br/k*1.4)*k*.92
        tips={};for i=0,2 do local a=i*math.pi*2/3;table.insert(tips,V(math.sin(a)*r,math.cos(a)*r,z))end
    end
    return {tips=tips,tail=st.hi.Z*k,tailSize=.26*s,band2={bz+bl*.24,bz+bl*.24+.1*s,br*1.06},nose=st.lo.Z*k,noseR=br,bright=info.bright,phases=phases}
end
function M.warhead(kind,warhead,trailSkin,owner)
    local s=(M.size[kind]or 1)*1.3;local model=Instance.new("Model");model.Name=kind
    local theme=Themes.warheads[warhead.theme]and warhead.theme or "classic"
    local b=builder(model,s,warhead,owner,warhead.tier or 0)
    if kind=="MIRVWarhead"then
        b.rod("Airframe",-.6*s,.6*s,.2*s,warhead.body);b.add("Nose",V(.4,.4,.4)*s,CFrame.new(0,0,-.65*s),warhead.nose,SMOOTH,0,"ball")
        b.band(-.3*s,-.1*s,.21*s)
        local tail=b.add("Exhaust",V(.34,.34,.34)*s,CFrame.new(0,0,.7*s),warhead.glow,NEON,0,"ball")
        trail(tail,"CoreTrail",trailSkin.width*s*.5,ColorSequence.new(trailSkin.core,trailSkin.hot),math.max(.65,trailSkin.coreLife),NumberSequence.new(0,1),NumberSequence.new(1,.2),1)
        model:SetAttribute("MobileUnit",true);model:SetAttribute("NukeSkin",true);model:SetAttribute("NukeTheme",theme);model.WorldPivot=CFrame.identity
        return model
    end
    local info=Themes.warheads[theme](b)
    local key=warhead.collection and warhead.collection.id
    local meshed=key and Meshes.ready(key)
    if meshed then info=meshWarhead(b,model,warhead.collection,owner,s,info)end
    local function dress(i)
        if kind=="HydrogenBomb"then b.rod("OwnerBand",i.band2[1],i.band2[2],i.band2[3],owner)end
        if kind=="MIRV"then for n=0,2 do b.add("BusWarhead",V(.14,.14,.3)*s,CFrame.new(0,0,i.nose+.22*s)*CFrame.Angles(0,0,n*math.pi*2/3)*CFrame.new(0,i.noseR+.07*s,0),warhead.nose,SMOOTH,0,"ell")end end
    end
    dress(info)
    local geometry=model:GetChildren()
    b.tail=info.tail
    local tail=b.add("Exhaust",V(1,1,1)*info.tailSize,CFrame.new(0,0,info.tail),warhead.glow,NEON,0,"ball");b.exhaust=tail
    local light=Instance.new("PointLight");light.Name="EngineLight";light.Color=warhead.light;light.Brightness=2.2*(info.bright or 1);light.Range=math.max(4,s*6);light.Shadows=false;light.Parent=tail
    trail(tail,"CoreTrail",trailSkin.width*s*.5,ColorSequence.new(trailSkin.core,trailSkin.hot),math.max(.65,trailSkin.coreLife),NumberSequence.new(0,1),NumberSequence.new(1,.2),1)
    trail(tail,"SmokeTrail",trailSkin.smokeWidth*s*.5,ColorSequence.new(trailSkin.smoke),math.max(5.5,trailSkin.smokeLife),
        NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(.15,.35),NumberSequenceKeypoint.new(1,1)}),
        NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,2.4)}),0)
    local extra=Themes.trails[trailSkin.theme or "classic"];if extra then extra(b,tail,trailSkin,info)end
    model:SetAttribute("MobileUnit",true);model:SetAttribute("NukeSkin",true);model:SetAttribute("NukeTheme",theme)
    if warhead.collection then
        local c=warhead.collection;model:SetAttribute("CollectionTier",c.tier);model:SetAttribute("CollectionStyle",c.id);model:SetAttribute("CollectionRole","nuclear")
        model:SetAttribute("CollectionPhases",info.phases and 3 or 1)
    end
    model.WorldPivot=CFrame.identity
    if key and not meshed then Meshes.watchModel(key,model,function()
        local pivot,scale=model:GetPivot(),model:GetScale()
        for _,p in ipairs(geometry)do p:Destroy()end
        local old={};for _,p in ipairs(model:GetChildren())do old[p]=true end
        local holder=Instance.new("Folder");local mesh=meshWarhead(b,holder,warhead.collection,owner,s,info)
        for _,p in ipairs(holder:GetChildren())do p.Parent=model end;holder:Destroy();dress(mesh)
        for _,p in ipairs(model:GetChildren())do if not old[p]and p:IsA("BasePart")then
            p.CFrame=pivot*scaled(p.CFrame,scale);if scale~=1 then p.Size*=scale end
        end end
        local at=pivot*scaled(CFrame.new(0,0,mesh.tail),scale);tail.CFrame=at
        local holderTail=model:FindFirstChild("EmitterTail");if holderTail then holderTail.CFrame=at end
        model:SetAttribute("MeshItem",key);model:SetAttribute("CollectionPhases",mesh.phases and 3 or 1);info.phases=mesh.phases
    end)end
    if #b.moves==0 and #b.orbits==0 and #b.emitters==0 and #b.arcs==0 and not(key and not meshed)then return model end
    local lastPos,posed
    local function step(t)
        local reduced=model:GetAttribute("NukeReduced")==true
        local pivot=model:GetPivot();local moving=lastPos~=nil and (pivot.Position-lastPos).Magnitude>.01;lastPos=pivot.Position
        for _,e in ipairs(b.emitters)do local on=moving and not reduced;if e.Enabled~=on then e.Enabled=on end end
        if reduced and posed then return end
        posed=reduced
        local tt=reduced and 0 or t;local phase=info.phases and (reduced and 3 or math.min(3,1+math.floor(t/1.4)))or 1
        local starts=reduced and {0,-9,-9}or {0,1.4,2.8}
        local scale=model:GetScale()
        for _,m in ipairs(b.moves)do
            for i,p in ipairs(m.list)do p.CFrame=m.homes[i];p.Size=m.sizes[i]end
            m.fn(tt,phase,starts,m.list,m.homes)
            for _,p in ipairs(m.list)do p.CFrame=pivot*scaled(p.CFrame,scale);if scale~=1 then p.Size*=scale end end
        end
        for _,o in ipairs(b.orbits)do
            local a=o.off+tt*o.w;local dir=V(math.cos(a),math.sin(a),0)*scale
            o.a0.Position=dir*(o.r-o.width/2);o.a1.Position=dir*(o.r+o.width/2)
        end
        local roll=math.floor(tt/.06)
        for i,arc in ipairs(b.arcs)do
            arc.beam.CurveSize0=(Themes.hash(i,roll)-.5)*arc.length*1.2;arc.beam.CurveSize1=(Themes.hash(i+5,roll)-.5)*arc.length*1.2
            arc.a0.CFrame=CFrame.Angles(0,0,Themes.hash(i+9,roll)*math.pi*2);arc.a1.CFrame=CFrame.new(0,0,arc.length*scale)*CFrame.Angles(0,0,Themes.hash(i+13,roll)*math.pi*2)
        end
    end
    step(4.2);lastPos=nil
    track(model,step)
    return model
end
function M.setReduced(model,reduced)
    model:SetAttribute("NukeReduced",reduced==true)
    for _,t in ipairs(model:GetDescendants())do
        if t:IsA("Trail")then t.Enabled=not reduced or t.Name=="CoreTrail";if not t:GetAttribute("FullLife")then t:SetAttribute("FullLife",t.Lifetime)end;t.Lifetime=reduced and .12 or t:GetAttribute("FullLife")
        elseif t:IsA("Beam")then t.Enabled=not reduced
        elseif t:IsA("ParticleEmitter")and reduced then t.Enabled=false end
    end
end

M.telegraphCircle={0,0,1/.9}
function M.telegraph(parent,position,radius,color,overlay,skin)
    local model=Instance.new("Model");model.Name="NukeTelegraph";model.Parent=parent
    local d=radius*2
    if overlay then
        local carrier=piece(model,"Fill","block",V(d,.05,d),CFrame.new(position+UP*.22),color,SMOOTH,1)
        local gui=Instance.new("SurfaceGui");gui.Name="Telegraph";gui.Face=Enum.NormalId.Top;gui.AlwaysOnTop=true;gui.LightInfluence=0;gui.Brightness=1.6
        gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;gui.CanvasSize=Vector2.new(512,512);gui.MaxDistance=4000;gui.Parent=carrier
        local fill=Instance.new("Frame");fill.Name="Disc";fill.Size=UDim2.fromScale(1,1);fill.BorderSizePixel=0;fill.BackgroundColor3=color;fill.BackgroundTransparency=.82;fill.Parent=gui
        local round=Instance.new("UICorner");round.CornerRadius=UDim.new(.5,0);round.Parent=fill
        local dashes=24;local thick=math.max(5,math.floor(512*math.max(.08,radius*.025)/d+.5))
        for i=1,dashes do
            local a=(i-.5)/dashes*math.pi*2;local r=256-thick/2
            local dash=Instance.new("Frame");dash.Name="Dash";dash.AnchorPoint=Vector2.new(.5,.5);dash.BorderSizePixel=0;dash.BackgroundColor3=color;dash.BackgroundTransparency=.15
            dash.Size=UDim2.fromOffset(math.pi*512/dashes*.62,thick);dash.Position=UDim2.fromOffset(256+math.cos(a)*r,256+math.sin(a)*r);dash.Rotation=math.deg(a)+90;dash.Parent=gui
        end
        model.WorldPivot=CFrame.new(position)
        local layers
        if skin then
            local inner=Instance.new("Frame");inner.Name="Skin";inner.AnchorPoint=Vector2.new(.5,.5);inner.Position=UDim2.fromScale(.5,.5)
            inner.Size=UDim2.fromScale(.86,.86);inner.BackgroundTransparency=1;inner.ZIndex=2;inner.Parent=gui
            local quiet=table.clone(skin);quiet.glow=nil;quiet.gem=false;quiet.orbit=false;quiet.bezelAlpha=.55
            layers=Skin.attach({front=inner,back=inner,top=inner,box=1,N=128,frontZ=2,backZ=1,topZ=3})
            Skin.apply(layers,quiet,"Telegraph",M.telegraphCircle,512,false,false)
        end
        return {model=model,disc=carrier,fill=fill,center=position,spin=0,skin=layers}
    end
    local disc=piece(model,"Fill","cylinder",V(.05,d,d),CFrame.new(position+UP*.22)*FLAT,color,NEON,.82)
    local dashes=24;local arc=2*math.pi*radius/dashes
    for i=1,dashes do
        local a=(i-.5)/dashes*math.pi*2;local at=position+UP*.26+V(math.cos(a),0,math.sin(a))*radius
        piece(model,"Dash","block",V(math.max(.08,radius*.025),.06,arc*.62),CFrame.lookAt(at,at+V(-math.sin(a),0,math.cos(a))),color,NEON,.15)
    end
    model.WorldPivot=CFrame.new(position)
    return {model=model,disc=disc,center=position,spin=0}
end
function M.stepTelegraph(t,now,dt,reduced)
    if reduced then return end
    t.spin=(t.spin+math.rad(20)*dt)%(math.pi*2)
    t.model:PivotTo(CFrame.new(t.center)*CFrame.Angles(0,t.spin,0))
    if t.fill then t.fill.BackgroundTransparency=.8+.06*math.sin(now*3)else t.disc.Transparency=.8+.06*math.sin(now*3)end
    if t.skin and t.skin.animated then Skin.step(t.skin,now,false)end
end

function M.new(folder,world)
    return setmetatable({folder=folder,world=world,active=0,light=0},M)
end
function M:launch(position,trailSkin,reduced)
    if reduced or self.light>=6 then return end
    if trailSkin.collection then require(script.Parent.CollectionArt).sound(trailSkin.collection)end
    self.light+=1;task.delay(2.6,function()self.light=math.max(0,self.light-1)end)
    local model=Instance.new("Model");model.Name="NukeLaunch";model.Parent=self.folder
    local flash=piece(model,"Flash","sphere",Vector3.one*1.2,CFrame.new(position+UP*.6),trailSkin.core,NEON,0)
    local puffs={}
    for i=1,4 do puffs[i]=piece(model,"Plume","sphere",Vector3.one*(.9+i*.15),CFrame.new(position+UP*.4),trailSkin.smoke,SMOOTH,.3)end
    local ring=(trailSkin.tier or 0)>=2 and piece(model,"LaunchRing","cylinder",V(.05,1,1),CFrame.new(position+UP*.2)*FLAT,trailSkin.hot,NEON,1)
    track(model,function(t)
        local f=out2(k(t,0,.35));flash.Size=Vector3.one*(1.2+1.8*f);flash.Transparency=f
        for i,p in ipairs(puffs)do
            local a=out2(k(t,(i-1)*.08,2.2+(i-1)*.08));local drift=V(math.cos(i*1.9),0,math.sin(i*1.9))*.6
            p.CFrame=CFrame.new((position+UP*.4):Lerp(position+UP*(1.5+i*.9)+drift,a));p.Size=Vector3.one*((.9+i*.15)+((2.2+i*.5)-(.9+i*.15))*a)
            p.Transparency=.3+.7*out2(k(t,.8+(i-1)*.08,2.2+(i-1)*.08))
        end
        if ring then local g=out4(k(t,0,.9));local r=1+5*g*(1+(trailSkin.tier-2)*.25);ring.Size=V(.05,r*2,r*2);ring.Transparency=.2+.8*g end
        return t<2.6
    end)
    Debris:AddItem(model,3)
end
function M:detonate(position,kind,radius,inner,skin,reduced)
    local R=math.max(2,(radius or 30)*WG.scale)
    local light=reduced or kind=="MIRVWarhead"or self.active>=3
    if light and self.light>=10 then return end
    local theme=Themes.impacts[skin.theme or ""]and skin.theme or nil
    local delay=not light and theme and Themes.impacts.delay[theme]or 0
    local model=Instance.new("Model");model.Name="NukeDetonation";model:SetAttribute("Kind",kind);model:SetAttribute("Full",not light);model:SetAttribute("NukeTheme",skin.theme or "classic");model.Parent=self.folder
    local hold=(light and 1.4 or 6.5)+delay
    if light then self.light+=1;task.delay(hold,function()self.light=math.max(0,self.light-1)end)
    else self.active+=1;task.delay(4.5+delay,function()self.active=math.max(0,self.active-1)end)end
    local ground=position+UP*.15
    local els,parts={},{}
    local d={model=model,R=R,ground=ground,position=position,kind=kind,skin=skin,reduced=reduced,parts=parts}
    function d.add(name,shape,size,cf,color,material,tr)local p=Themes.part(model,name,size,cf,color,material or NEON,tr,shape~="block"and shape or nil);parts[name]=parts[name]or p;return p end
    function d.el(fn)table.insert(els,fn)end
    function d.ring(name,n,color)local list={};for i=1,n do list[i]=d.add(name,"block",V(.1,.1,.1),CFrame.new(ground),color,NEON,1)end;return list end
    function d.emit(at,props,count)
        count=math.min(count,particleCap(skin.tier))
        if reduced or count<=0 then return end
        local holder=d.add("Burst","block",Vector3.one*R*.2,CFrame.new(ground+UP*R*.2),skin.flash,SMOOTH,1)
        local e=Instance.new("ParticleEmitter");e.Name="Burst";for key,v in pairs(props)do e[key]=v end;e.Enabled=false;e.Rate=0;e.Parent=holder
        local fired=false;d.el(function(t)if not fired and t>=at then fired=true;pcall(function()e:Emit(count)end)end end)
    end
    local function shared(fn)d.el(function(t)fn(t-delay)end)end
    if not reduced then
        local flash=d.add("Flash","ell",Vector3.one*R*.2,CFrame.new(ground+UP*R*.12),skin.flash,NEON,1)
        local glow=Instance.new("PointLight");glow.Color=skin.fire;glow.Shadows=false;glow.Range=math.min(60,R*(light and 1.6 or 2.6));glow.Brightness=0;glow.Parent=flash
        shared(function(t)
            if t<0 then flash.Transparency=1;return end
            flash.Size=Vector3.one*R*(.2+((light and .55 or .95)-.2)*out2(k(t,0,.12)));flash.Transparency=out2(k(t,.1,.5))
            glow.Brightness=(light and 3 or 8)*(1-out2(k(t,0,light and .5 or .9)))
        end)
    end
    local shock=d.add("Shockwave","cyl",V(.06,R*.3,R*.3),CFrame.new(ground+UP*.2)*FLAT,skin.shock,NEON,1)
    local shockTime=light and .7 or (kind=="HydrogenBomb"and 1.5 or 1.2)
    shared(function(t)if t<0 then return end;local a=out4(k(t,0,shockTime));shock.Size=V(.06,R*(.3+2.7*a),R*(.3+2.7*a));shock.Transparency=.15+.85*a end)
    local fire=d.add("Fireball","ell",Vector3.one*R*.15,CFrame.new(ground+UP*R*.1),skin.core,NEON,1)
    shared(function(t)
        if t<0 then return end
        fire.Size=Vector3.one*R*(.15+((light and .35 or .55)-.15)*out2(k(t,0,light and .3 or .55)))
        fire.Color=t<.35 and skin.core:Lerp(skin.fire,out2(k(t,0,.35)))or skin.fire:Lerp(skin.ember,out2(k(t,.35,.35+(light and .5 or 1.1))))
        fire.Transparency=out2(k(t,light and .3 or .9,(light and .8 or 2.2)))
        if not light then fire.CFrame=CFrame.new(ground+UP*R*(.1+.4*(1-math.cos(math.pi*k(t,0,1.9)))/2))end
    end)
    if not light then
        local dust=d.add("Dust","cyl",V(R*.06,R*.4,R*.4),CFrame.new(ground+UP*R*.03)*FLAT,skin.dust,SMOOTH,1)
        shared(function(t)if t<0 then return end;local a=out2(k(t,0,1.9));dust.Size=V(R*(.06-.04*a),R*(.4+2.1*a),R*(.4+2.1*a));dust.Transparency=.4+.6*a end)
        local stemW=R*.17;local stemH=R*.8
        local stem=d.add("Stem","cyl",V(.1,stemW,stemW),CFrame.new(ground)*FLAT,skin.smoke,SMOOTH,1)
        local cap=d.add("Cap","ell",V(R*.45,R*.25,R*.45),CFrame.new(ground+UP*R*.3),skin.ember,SMOOTH,1)
        local under=d.add("CapGlow","ell",V(R*.4,R*.14,R*.4),CFrame.new(ground+UP*R*.24),skin.fire,NEON,1)
        local collar=kind=="HydrogenBomb"and d.add("Collar","cyl",V(R*.05,R*.35,R*.35),CFrame.new(ground+UP*R*.45)*FLAT,skin.shock,SMOOTH,1)
        shared(function(t)
            if t<0 then return end
            local a=out2(k(t,.15,1.85));local h=.1+(stemH-.1)*a
            stem.Size=V(h,stemW*(1+.3*a),stemW*(1+.3*a));stem.CFrame=CFrame.new(ground+UP*h/2)*FLAT;stem.Transparency=t<.15 and 1 or .2+.8*out2(k(t,2.4,4.4))
            local c=out2(k(t,.1,2))
            cap.Size=V(R*(.45+.7*c),R*(.25+.3*c),R*(.45+.7*c));cap.CFrame=CFrame.new(ground+UP*R*(.3+.65*c));cap.Color=skin.ember:Lerp(skin.cap,out2(k(t,.3,1.9)))
            cap.Transparency=t<.1 and 1 or .1+.9*out2(k(t,2.6,5))
            under.Size=V(R*(.4+.5*c),R*(.14+.08*c),R*(.4+.5*c));under.CFrame=CFrame.new(ground+UP*R*(.24+.54*c));under.Transparency=t<.1 and 1 or .15+.85*out2(k(t,.6,2.1))
            if collar then local g=out2(k(t,.4,2.2));collar.Size=V(R*(.05-.02*g),R*(.35+1.05*g),R*(.35+1.05*g));collar.Transparency=t<.4 and 1 or .35+.65*g end
        end)
        local burnt=math.max(1,(inner or radius*.4)*WG.scale)*2
        local scorch=d.add("Scorch","cyl",V(.04,burnt,burnt),CFrame.new(position+UP*.12)*FLAT,skin.scorch,SMOOTH,1)
        shared(function(t)scorch.Transparency=t<0 and 1 or .3+.7*out2(k(t,2.8,6.3))end)
        if theme then Themes.impacts[theme](d)end
    end
    for _,fn in ipairs(els)do fn(0)end
    track(model,function(t)for _,fn in ipairs(els)do fn(t)end;return t<hold end)
    Debris:AddItem(model,hold+.5)
    return model
end
return M
