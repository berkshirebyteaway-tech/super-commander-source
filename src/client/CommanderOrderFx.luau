local G=require(script.Parent.ToyGeometry)
local Art=require(script.Parent.CollectionArt)
local M={};M.__index=M
local rigs=setmetatable({},{__mode='k'})
local function rgb(a)return Color3.fromRGB(table.unpack(a))end
local function out(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local TAU=math.pi*2
local life={.8,1,1.15,1.5,1.7};local show={.42,.55,.5,.72,.85}
local function piece(rig,name,color,glow,anim,mode,phase,shape)
    local p=G.block(rig.model,name,Vector3.one,CFrame.identity,color);p.CastShadow=false
    p.Material=glow and Enum.Material.Neon or Enum.Material.Metal
    if shape=='ball'then p.Shape=Enum.PartType.Ball elseif shape=='cylinder'then p.Shape=Enum.PartType.Cylinder
    elseif shape=='round'then local m=Instance.new('SpecialMesh');m.MeshType=Enum.MeshType.Sphere;m.Parent=p end
    local item={part=p,anim=anim,mode=mode or 0,phase=phase or 1,color=color,cylinder=shape=='cylinder'}
    table.insert(rig.items,item);return item
end
local function disc(r,h,y)return function()return CFrame.new(0,y,0),Vector3.new(h,r*2,r*2)end end
local function dash(i,n,y,fill)
    return function(R)local a=i/n*TAU;return CFrame.Angles(0,a,0)*CFrame.new(0,y,-R),Vector3.new(TAU*R/n*fill,1,1)end
end
local themes={}
themes.signal=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    piece(rig,'SignalPlate',base,false,function(t)local c,sz=disc(.42,.04,.02)();return c,sz*out(t/.15),.25 end,0,1,'cylinder')
    piece(rig,'SignalCore',accent,false,function(t)local c,sz=disc(.13,.07,.05)();return c,sz,0 end,0,1,'cylinder')
    for i=0,15 do local d=dash(i,16,.05,.62)
        piece(rig,'SignalRing',accent,false,function(t)local R=.35+1.1*out(t);local c,sz=d(R);return c,sz*Vector3.new(1,.05,.07),.05+.9*t^2 end)
    end
    for i=0,3 do
        piece(rig,'SignalTick',i==0 and accent or trim,false,function(t)
            local R=.55+1.15*out(t);local len=i==0 and .34 or .2
            return CFrame.Angles(0,i*math.pi/2,0)*CFrame.new(0,.05,-R-len/2),Vector3.new(.08,.06,len),.1+.85*t^2
        end)
    end
end
themes.tactic=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    piece(rig,'TacticPlate',base,false,function(t)local c,sz=disc(.5,.04,.02)();return c,sz*out(t/.12),.2 end,0,1,'cylinder')
    for i=0,9 do local d=dash(i,10,.05,.55)
        piece(rig,'TacticSeam',accent,true,function(t)local c,sz=d(.56);return c,sz*Vector3.new(1,.03,.04),.35+.6*math.max(0,t-.6)/.4 end)
    end
    for j=0,2 do local k=1+j*.16;local z=-(.72+j*.46)
        for _,side in ipairs({-1,1})do
            local function arm(w,h,len,y)return function(t)
                local on=out((t-j*.12)/.22);local slide=(1-on)*.3
                return CFrame.new(side*.15*k,y,z+.15*k+slide)*CFrame.Angles(0,side*math.pi/4,0),Vector3.new(w*k,h,len*k),(1-on)+on*(.05+.7*math.max(0,t-.7)/.3)
            end end
            piece(rig,'TacticChevron',trim,false,arm(.13,.06,.46,.06))
            piece(rig,'TacticChevronLight',accent,true,arm(.05,.08,.4,.08))
        end
    end
    for _,cx in ipairs({-1,1})do for _,cz in ipairs({-1,1})do for axis=1,2 do
        piece(rig,'TacticBracket',accent,true,function(t)
            local h=.36+.3*(1-out((t-.25)/.3));local on=t>.2 and 1 or 0
            local cf=CFrame.new(0,0,-2.2)*(axis==1 and CFrame.new(cx*(h-.07),.06,cz*h)or CFrame.new(cx*h,.06,cz*(h-.07)))
            return cf,axis==1 and Vector3.new(.2,.06,.07)or Vector3.new(.07,.06,.2),on==0 and 1 or .05+.8*math.max(0,t-.75)/.25
        end)
    end end end
    piece(rig,'TacticMark',accent,true,function(t)return CFrame.new(0,.05,-2.2),Vector3.new(.04,.11,.11),t<.45 and 1 or .1 end,0,1,'cylinder')
end
themes.wave=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    piece(rig,'WavePlate',base,false,function(t)local c,sz=disc(.48,.04,.02)();return c,sz*out(t/.12),.15 end,0,1,'cylinder')
    piece(rig,'WaveOrb',accent,true,function(t,sec)return CFrame.new(0,.3+math.sin(sec*5)*.04,0),Vector3.one*(.2+.08*out(t/.2)),.05 end,0,1,'ball')
    for j=0,2 do
        for i=0,11 do local d=dash(i+j*.5,12,.06+j*.02,.6)
            piece(rig,'WaveRing',accent:Lerp(trim,j*.3),true,function(t)
                local tj=(t-j*.2)/.7;local R=.3+1.3*math.clamp(tj,0,1)
                local c,sz=d(R);return c,sz*Vector3.new(1,.07-j*.012,.1-j*.015),(tj<=0 or tj>=1)and 1 or .05+.75*tj^2
            end,j==1 and 2 or 1)
        end
    end
    for i=0,5 do
        piece(rig,'WaveSpark',trim,true,function(t)
            local a=i/6*TAU+.3;local R=.45+.5*t
            return CFrame.Angles(0,a,0)*CFrame.new(0,.12+.75*t,-R)*CFrame.Angles(.78,0,.78),Vector3.one*.07,.1+.85*t
        end,1)
    end
end
themes.crest=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local white=Color3.fromRGB(255,244,214)
    piece(rig,'CrestPlate',base,false,function(t)local c,sz=disc(.6,.04,.02)();return c,sz*out(t/.12),.1 end,0,1,'cylinder')
    for i=0,11 do
        piece(rig,'CrestRay',accent,true,function(t)
            local len=.6*out(t/.35);local a=i/12*TAU
            return CFrame.Angles(0,a,0)*CFrame.new(0,.04,-(.62+len/2)),Vector3.new(i%2==0 and .07 or .04,.03,math.max(.01,len)),.15+.8*math.max(0,t-.6)/.4
        end,2)
    end
    for i=0,13 do local d=dash(i,14,.05,.7)
        piece(rig,'CrestRing',accent,true,function(t)local c,sz=d(1.35*out(t/.3)+.01);return c,sz*Vector3.new(1,.05,.07),.2+.75*math.max(0,t-.6)/.4 end,2)
    end
    local function rise(t)return rig.preview and .25+1.35*out(t/.45)or .3+4.1*out(t/.45)end
    piece(rig,'CrestBeam',accent,true,function(t)local H=rise(t)-.05;return CFrame.new(0,H/2,0),Vector3.new(H,.5,.5),rig.preview and .8 or .88 end,0,1,'cylinder')
    local function crest(name,color,glow,cf,size,shape)
        piece(rig,name,color,glow,function(t,sec)
            local H=rise(t);local g=(.45+.55*out(t/.35))*(rig.preview and 1 or 1.3)
            local spin=rig.preview and 0 or sec*3.2
            local c=CFrame.new(0,H,0)*CFrame.Angles(0,spin,0)*CFrame.new(cf.Position*g)*cf.Rotation
            return c,size*g,0
        end,1,1,shape)
    end
    crest('CrestShield',trim,false,CFrame.new(0,.05,0),Vector3.new(.56,.58,.07))
    crest('CrestShield',trim,false,CFrame.new(0,-.24,0)*CFrame.Angles(0,0,math.pi/4),Vector3.new(.4,.4,.07))
    crest('CrestBorder',accent,true,CFrame.new(0,.35,0),Vector3.new(.66,.07,.1))
    for _,x in ipairs({-1,1})do
        crest('CrestBorder',accent,true,CFrame.new(x*.3,.08,0),Vector3.new(.07,.56,.1))
        crest('CrestBorder',accent,true,CFrame.new(x*.15,-.37,0)*CFrame.Angles(0,0,-x*math.pi/4),Vector3.new(.07,.46,.1))
    end
    for r=0,1 do crest('CrestStar',white,true,CFrame.new(0,.03,0)*CFrame.Angles(0,0,r*math.pi/4),Vector3.new(.22,.22,.12))end
    for _,x in ipairs({-1,1})do for j=0,4 do
        local b=.45+j*.42;local cf=CFrame.new(x*.52*math.sin(b),-.04-.5*math.cos(b),0)*CFrame.Angles(0,0,-x*(math.pi/2-b))
        crest('CrestLaurel',accent,true,cf,Vector3.new(.08,.22,.05),'round')
    end end
    for x=-1,1 do crest('CrestCrown',white,true,CFrame.new(x*.2,.5+(x==0 and .05 or 0),0),Vector3.new(.08,x==0 and .2 or .14,.08))end
    rig.lightAt=rig.items[#rig.items].part
end
local function cool(x,sat)local f=x%1;return Color3.fromHSV(.48+.38*(1-math.abs(2*f-1)),sat or .78,1)end
themes.domain=function(rig,s)
    local white=Color3.fromRGB(235,252,255)
    for i=-3,3 do for j=-3,3 do local r=math.abs(i)+math.abs(j)
        if r<=3 then local c0=r/6.5+((i+j)%2)*.025
            piece(rig,'DomainTile',cool(c0),true,function(t,sec)
                local g=out((t-r*.09)/.22);local y=.04+.04*math.sin(sec*6-r*1.3)
                return CFrame.new(i*.42,y,j*.42),Vector3.new(.37*g+.001,.04,.37*g+.001),g<=0 and 1 or .12+.75*math.max(0,t-.75)/.25,
                    not rig.preview and cool(c0-sec*.45)or nil
            end,1,r<=1 and 1 or r==2 and 2 or 3)
        end
    end end
    for i=0,15 do local d=dash(i,16,.07,.72)
        piece(rig,'DomainBorder',white,true,function(t,sec)
            local c,sz=d(1.72*out(t/.3)+.01);return c,sz*Vector3.new(1,.08,.11),.02+.8*math.max(0,t-.75)/.25,not rig.preview and cool(i/16-sec*.3,.35)or nil
        end,2)
    end
    local function top(t)return rig.preview and .3+2.2*out(t/.4)or .3+3.5*out(t/.4)end
    piece(rig,'DomainColumn',cool(.05),true,function(t)local H=top(t);return CFrame.new(0,H/2,0),Vector3.new(H,.42,.42),.5 end,0,1,'cylinder')
    for k=0,1 do
        piece(rig,'DomainCrystal',k==0 and white or cool(.4),true,function(t,sec)
            local g=out(t/.35)*(rig.preview and 1 or 1.25)
            return CFrame.new(0,top(t)+.62*g,0)*CFrame.Angles(0,k*math.pi/4+(rig.preview and 0 or sec*2.2),0),(k==0 and Vector3.new(.26,1.2,.26)or Vector3.new(.52,1.45,.52))*g,k==0 and 0 or .4,
                not rig.preview and k==1 and cool(sec*.5+.5)or nil
        end,2)
    end
    for i=0,11 do local d=dash(i,12,0,.6)
        piece(rig,'DomainCrown',cool(i/12),true,function(t,sec)
            local g=out((t-.25)/.3)*(rig.preview and 1 or 1.25);local c,sz=d(.82*g+.01)
            return CFrame.new(0,top(t)+.62*g,0)*CFrame.Angles(0,rig.preview and 0 or -sec*1.6,0)*CFrame.Angles(.35,0,0)*c,sz*Vector3.new(1,.09,.12)+Vector3.new(0,0,0),.02,
                not rig.preview and cool(i/12+sec*.5)or nil
        end,1,2)
    end
    rig.lightAt=rig.items[#rig.items-12].part
end
require(script.Parent.OrderVolume)(themes,{piece=piece,disc=disc,dash=dash,out=out,rgb=rgb,cool=cool})
require(script.Parent.OrderVolume2)(themes,{piece=piece,disc=disc,dash=dash,out=out,rgb=rgb,cool=cool})
local Meshes=require(script.Parent.CosmeticMeshes)
local SPREAD={spread=true}
local beats={
    carbon={Ground={spread=true,spin=30},Mark={spread=true,t0=.05}},
    cobalt={Ground={spread=true,spin=-40},Chevron={t0=.05,t1=.9,slide=.3},Bracket={grow={1.3,1,.2}}},
    pulse={Ground={spread=true,spin=20},Ring={ring={0,.5,.9,1.25},stagger=.12}},
    venom={Ground={grow={.4,1,.18}},Splash={t0=.05,t1=.6,ring={.05,.55,.8,1.15}},Bubble={t0=.2,blink=.1},Ring={spin=25}},
    tidal={Ground={spread=true,spin=15},Wave={spin=90},Spray={t0=.15,t1=.7,ring={.15,.55,.9,1.15}},Swirl={spin=220}},
    ember={Ground=SPREAD,Flame={spin=45,wobble=.12},Ember={t0=.1,t1=.8,ring={.1,.7,.8,1.2}},Ring={}},
    storm={Ground={spread=true,spin=-30},Bolt={flash={.05,.35,.65}},Target={grow={1.2,1,.2}},Ring={spin=60}},
    solaris={Ground={spread=true,spin=12},Laurel={t0=.08,grow={.7,1,.25}},Crest={t0=.15,grow={.8,1,.2}},Rim={spin=-8},Glow={ring={0,.5,.9,1.25}}},
    crown={Ground=SPREAD,Jewel={t0=.1,grow={0,1,.3}},Banner={t0=.05,grow={.85,1,.2}},Sapphire={t0=.05,grow={.85,1,.2}},Rim={spin=10},Glow={ring={0,.5,.9,1.25}}},
    phoenix={Ground=SPREAD,Feather={t0=.05,growX={.5,1,.25}},Flame={spin=50,wobble=.12},Rim={},Glow={ring={0,.5,.9,1.25}}},
    parallax={Ground={spread=true,spin=18},Prism={spin=-18},Orbit={spin=40,alternate=true},Halo={pulse=true},Rune={t0=.05,spin=30},Star={t0=.2,blink=.05},Crown={t0=.1,grow={.85,1,.2},spin=-12}},
    eclipse={Ground=SPREAD,Diamond={t0=.15,t1=.5,spark=true},Corona={spin=10,wobble=.2},Halo={pulse=true},Ray={t0=.1,spin=-20},Ring={spin=25}},
    dragon={Ground={spread=true,spin=12},Dragon={t0=.05,grow={.6,1,.3},spin=40},Pearl={t0=.2,spin=40},Rim={spin=-10},Glow={ring={0,.5,.9,1.25}}},
    diamond={Ground=SPREAD,Gem={t0=.1,grow={0,1,.36}},Spark={t0=.3,t1=.8,spark=true},Rim={spin=8},Glow={ring={0,.5,.9,1.25}}},
    seraph={Ground=SPREAD,Wing={t0=.05,grow={.5,1,.3},spin=15},Feather={t0=.05,grow={.5,1,.3},spin=15},Halo={pulse=true},Pillar={t0=.2,t1=.9,blink=.05},Ring={spin=20}},
    glitch={Ground={jitter=true},Cursor={t1=1,slide=1.2},Corner={t0=.1,blink=.1},Halo={spin=30},Shift={blink=.1},Grid={t0=.1,spin=-25}},
    leviathan={Ground={spread=true,spin=10},Tentacle={t0=.05,grow={.8,1,.3},spin=35},Sucker={t0=.05,grow={.8,1,.3},spin=35},Halo={pulse=true},Ripple={t0=.1,grow={.9,1.1,.9}},Eye={t0=.3,growZ={0,1,.15}}},
}
local function partBeat(series,name)
    local core=name:gsub('^Order',''):gsub('Top$','');local n=tonumber(core:match('%d+$'));core=core:gsub('%d+$','')
    local b=(beats[series]or {})[core]or {}
    if series=='seraph'and core=='Wing'and n==2 then b={t0=.15,spin=-15}end
    return b,n
end
local function meshTheme(rig,style)
    local series=style.id:match('^(%a+)_motion$')
    local list=Meshes.build(rig.model,style.id,{colors={primary=rgb(style.primary),secondary=rgb(style.secondary),accent=rgb(style.accent)}})
    if not list then return false end
    local life0=rig.life
    for _,r in ipairs(list)do
        local d=r.def;local b,n=partBeat(series,d.name);local base=r.part.Transparency
        local home=CFrame.new(r.home.Position)*r.home.Rotation;local size0=r.part.Size
        local t0,t1=(b.t0 or 0)+((b.stagger and n)and(n-1)*b.stagger or 0),b.t1 or 1
        local ring=b.ring and{b.ring[1]+((b.stagger and n)and(n-1)*b.stagger or 0),b.ring[2],b.ring[3],b.ring[4]}
        local spin=b.spin and(b.alternate and n==2 and -b.spin or b.spin)
        local item={part=r.part,mode=0,phase=d.phase or 1,color=r.part.Color}
        item.anim=function(t,sec)
            if t<t0 or t>t1 then return home,size0,1 end
            local g,gx,gz,tr=1,1,1,base
            if b.spread then local u=math.clamp(t/.18,0,1);g=u<1 and .6+.44*out(u)or 1.04-.04*math.clamp((t-.18)/.1,0,1)end
            if b.grow then g*=b.grow[1]+(b.grow[2]-b.grow[1])*out((t-t0)/b.grow[3])end
            if b.growX then gx=b.growX[1]+(b.growX[2]-b.growX[1])*out((t-t0)/b.growX[3])end
            if b.growZ then gz=b.growZ[1]+(b.growZ[2]-b.growZ[1])*out((t-t0)/b.growZ[3])end
            if ring then local u=math.clamp((t-ring[1])/ring[2],0,1);if t<ring[1]then return home,size0,1 end;g*=ring[3]+(ring[4]-ring[3])*u;tr=math.max(tr,.1+.9*u)end
            if b.spark then local u=math.clamp((t-t0)/math.max(.01,t1-t0),0,1);g*=1+.6*math.sin(u*math.pi)end
            if b.wobble then g*=1+.05*math.sin(sec*TAU/b.wobble)end
            if b.pulse then tr=math.max(tr,.1+.3*(.5+.5*math.sin(sec*TAU/.3)))end
            if b.blink and math.floor((sec-t0*life0)/b.blink)%2==1 then tr=1 end
            if b.flash then local on=false;for _,f in ipairs(b.flash)do if t>=f and t<f+.06/life0 then on=true end end;if not on then tr=1 end end
            g*=1+.08*math.max(0,(t-.75)/.25)
            local cf=home
            if spin then cf=CFrame.Angles(0,-math.rad(spin)*sec,0)*cf end
            if b.slide then cf=CFrame.new(0,0,-b.slide*(1-out((t-t0)/math.max(.05,(t1-t0)*.4))))*cf end
            if b.jitter then local k=math.floor(sec*10);cf=CFrame.new((k%3-1)*.08,0,((k//3)%3-1)*.08)*cf end
            cf=CFrame.new(cf.Position*Vector3.new(g*gx,1,g*gz))*cf.Rotation
            return cf,Vector3.new(size0.X*g*gx,size0.Y,size0.Z*g*gz),tr
        end
        table.insert(rig.items,item)
    end
    rig.mesh=true;return true
end
local byTier={'signal','tactic','wave','crest','domain'}
local function pose(rig,t,sec,pivot,scale,phase)
    for _,item in ipairs(rig.items)do
        local p=item.part;local cf,size,tr,col=item.anim(t,sec)
        if item.cylinder then cf=cf*CFrame.Angles(0,0,math.pi/2)end
        p.Size=size*scale;p.CFrame=pivot*CFrame.new(cf.Position*scale)*cf.Rotation
        p.Transparency=item.phase>phase and 1 or math.clamp(tr,0,1)
        if col then p.Color=col end
    end
end
function M.model(style)
    local m=Instance.new('Model');m.Name='CommanderOrderSeal';m.WorldPivot=CFrame.identity
    local theme=style.tier and (themes[style.theme]and style.theme or byTier[style.tier])
    if not theme then
        local trim=Color3.fromRGB(table.unpack(style.secondary));local accent=Color3.fromRGB(table.unpack(style.accent))
        local disc0=G.cylinder(m,'CommandDisc',.66,.04,CFrame.new(0,.03,0),Color3.fromRGB(table.unpack(style.primary)));disc0.Material=Enum.Material.Metal;disc0.Transparency=.35;disc0.CastShadow=false
        for _,side in ipairs({-1,1})do
            local p=G.block(m,'CommandChevron',Vector3.new(.15,.07,.72),CFrame.new(side*.19,.09,-.05)*CFrame.Angles(0,side*.565,0),trim)
            p.Material=Enum.Material.Metal;p.CastShadow=false
        end
        local core=G.cylinder(m,'CommandCore',.13,.08,CFrame.new(0,.1,.36),accent);core.Material=Enum.Material.Neon;core.CastShadow=false
        Art.apply(m,style,'motion',CFrame.new(0,.06,0),.95);m:SetAttribute('AppearanceOnly',true);return m
    end
    local tier=style.tier;local rig={model=m,items={},tier=tier,life=life[tier],preview=true};rigs[m]=rig
    if not(style.id and Meshes.ready(style.id)and meshTheme(rig,style))then themes[theme](rig,style)end
    pose(rig,rig.show or show[tier],0,CFrame.identity,1,3)
    local state=Art.apply(m,style,'motion',CFrame.new(0,.06,0),.95)
    if state then
        for _,it in ipairs(state.parts)do it.part:Destroy()end
        if state.light then state.light:Destroy();state.light=nil end
        state.parts={}
        for _,item in ipairs(rig.items)do
            item.part:SetAttribute('BaseTransparency',item.part.Transparency)
            table.insert(state.parts,{part=item.part,home=item.part.CFrame,mode=item.mode,color=item.color,phase=item.phase})
        end
        if tier>=4 and not rig.lightAt and rig.mesh then rig.lightAt=rig.items[1]and rig.items[1].part end
        if tier>=4 and rig.lightAt then
            local light=Instance.new('PointLight');light.Name='CollectionLight';light.Color=rgb(style.accent);light.Range=4;light.Brightness=.6;light.Shadows=false;light.Parent=rig.lightAt;state.light=light
        end
        m:SetAttribute('CollectionGeometry',#rig.items);m:SetAttribute('CollectionParticles',0)
        state.lastPivot=nil;Art.step(m,0,true,1)
    end
    m:SetAttribute('AppearanceOnly',true);return m
end
function M.new(parent)return setmetatable({parent=parent,active={},last=setmetatable({},{__mode='k'}),time=0},M)end
function M:emit(style,root,kind,reduced)
    if reduced or not style.tier or not root or not root.Parent then return false end
    local now=os.clock();if now-(self.last[root]or -10)<.65 then return false end
    local cap=game:GetService('UserInputService').TouchEnabled and 2 or 3;if #self.active>=cap then return false end
    self.last[root]=now
    local model=M.model(style);local rig=rigs[model];if rig then rig.preview=false end
    model.Parent=self.parent
    table.insert(self.active,{model=model,root=root,age=0,style=style,kind=kind,rig=rig,life=rig and rig.life or .65})
    return true
end
function M:step(dt,reduced)
    self.time+=dt
    for i=#self.active,1,-1 do local v=self.active[i];v.age+=dt
        if reduced or not v.root.Parent or v.age>=v.life then v.model:Destroy();table.remove(self.active,i)
        else
            local camera=workspace.CurrentCamera
            local want=camera and .256*2*(camera.CFrame.Position-v.root.Position).Magnitude*math.tan(math.rad(camera.FieldOfView)/2)/3.6 or 0
            local scale=math.clamp(math.max(math.clamp(v.root.Size.Y/2,.65,1.45)*1.35,want),.65,4.5)
            local h=v.root.Parent and v.root.Parent:FindFirstChildOfClass('Humanoid')
            local at=v.root.Position-Vector3.new(0,h and h.HipHeight+v.root.Size.Y/2-.05 or v.root.Size.Y*.9,0);local look=v.root.CFrame.LookVector*Vector3.new(1,0,1)
            local pivot=look.Magnitude>.01 and CFrame.lookAt(at,at+look)or CFrame.new(at)
            v.model.WorldPivot=pivot
            local t=v.age/v.life
            if v.rig then pose(v.rig,t,v.age,pivot,scale,v.style.tier==5 and math.min(3,1+math.floor(v.age/.22))or 3)
            else if v.scale~=scale then v.scale=scale;v.model:ScaleTo(scale)end;v.model:PivotTo(pivot)end
            local fade=math.max(0,(t-.75)/.25)
            for _,p in ipairs(v.model:GetChildren())do if p:IsA('BasePart')then p.LocalTransparencyModifier=fade end end
        end
    end
end
function M:clear()for _,v in ipairs(self.active)do v.model:Destroy()end;table.clear(self.active);self.last=setmetatable({},{__mode='k'})end
return M
