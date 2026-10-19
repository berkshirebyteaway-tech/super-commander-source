local G=require(script.Parent.ToyGeometry)
local V3,CF,ANG=Vector3.new,CFrame.new,CFrame.Angles
local MAT=Enum.Material
local PI=math.pi
local C=Color3.fromRGB
local floor=.31
local well=C(12,16,22);local warm=C(255,206,128);local steel=C(172,184,198)
local M={}
local T,kit
local refs={}
local function count(m)local n=0;for _,v in ipairs(m:GetDescendants())do if v:IsA('BasePart')then n+=1 end end;return n end
local function refCount(theme,kind,L,d)
    local key=theme..kind..L..tostring(d)
    if not refs[key]then
        local m=Instance.new('Model');local grey={128,128,128}
        T[theme](kit(m,{tier=3,primary=grey,secondary=grey,accent=grey},L,d,C(128,128,128)),kind);refs[key]=count(m);m:Destroy()
    end
    return refs[key]
end
local seq=0
local function fit(k,cap)
    local n=count(k.m);if n<=cap then return end
    local spare={}
    for _,v in ipairs(k.m:GetDescendants())do if v:IsA('BasePart')and v:GetAttribute('Trim')then table.insert(spare,v)end end
    table.sort(spare,function(a,b)return a:GetAttribute('Trim')>b:GetAttribute('Trim')end)
    for _,v in ipairs(spare)do if n<=cap then break end;v:Destroy();n-=1 end
    for i=#k.items,1,-1 do if not k.items[i].part.Parent then table.remove(k.items,i)end end
end
local function extend(k)
    seq=0
    function k.opt(level,fn)
        local before={};for _,v in ipairs(k.m:GetChildren())do before[v]=true end
        fn()
        for _,v in ipairs(k.m:GetChildren())do if not before[v]and v:IsA('BasePart')then seq+=1;v:SetAttribute('Trim',level*1e6+seq)end end
    end
    function k.dopt(level,fn)if k.d then fn()else k.opt(level,fn)end end
    function k.glass(p,t,refl)p.Material=MAT.Glass;p.Reflectance=refl or .1;p.CastShadow=false;k.fade(p,t or .5);return p end
    function k.metal(p,r)p.Material=MAT.Metal;p.Reflectance=r or .05;return p end
    function k.basalt(p)p.Material=MAT.Basalt;return p end
    return k
end
local function rise(h,speed,t0)return function(t)local y=(t*speed)%h;return CF(0,y,0),(t0 or .25)+.7*(y/h)^2 end end
local function drift(h,speed,sway)return function(t)local y=(t*speed)%h;return CF(math.sin(t*2.1)*(sway or .06),y,math.cos(t*1.7)*(sway or .06)),.2+.75*(y/h)^3 end end
local function slide(dir,len,speed)return function(t)local s=(t*speed)%len;local f=s/len;return CF(dir*s),.1+.85*math.abs(f*2-1)^6 end end
local function arc(seed)return function(t)
    local on=math.sin(t*9+seed)+math.sin(t*23.7+seed*2.3)>-.1
    return CF(math.sin(t*41+seed)*.035,math.sin(t*29+seed*1.7)*.03,math.sin(t*37+seed*.7)*.035),on and .05 or 1
end end
local function breathe(f,lo,hi,seed)return function(t)return nil,lo+(hi-lo)*(.5+.5*math.sin(t*f+(seed or 0)))end end
local function rails(k,ballast,rail,lit)
    for _,z in ipairs({.95,-.2})do
        k.b('Ballast',{5.5,.06,.66},{.5,floor+.03,z},ballast)
        if lit or not k.d then k.lit(k.b('Rail',{5.5,.03,.08},{.5,floor+.08,z},rail),.05)
        else for _,s in ipairs({-1,1})do k.metal(k.b('Rail',{5.5,.07,.07},{.5,floor+.095,z+s*.21},rail))end end
    end
end
local function well2(k,ring,inner,door,stripe,collar,litRing)
    local r=k.c('HazardRing',1.35,.04,{0,floor+.01,0},ring);if litRing then k.lit(r,.2)end
    k.c('RingInner',1.12,.05,{0,floor+.015,0},inner)
    k.b('LaunchWell',{1.9,.06,1.9},{0,floor+.04,-.1},well)
    for _,s in ipairs({-1,1})do
        local dd=k.b('HatchDoor',{1.9,.1,.62},{0,floor+.17,-.1+s*1.27},door,ANG(-s*math.rad(24),0,0),'armor')
        k.lit(k.b('HatchStripe',{1.76,.02,.07},dd.CFrame*CF(0,.06,s*.19),stripe),.1)
    end
    return k.c('SiloCollar',k.l==1 and .72 or .92,.3,{0,floor+.15,0},collar)
end
local function launcher(k,pack,base,tube,cap,capMat)
    local cols=k.l==1 and {-.29,.29}or {-.44,0,.44}
    G.part(k.m,'LauncherTube',V3(#cols*.44+.14,.22,1.0),pack*CF(0,-.38,-.1),base,'armor')
    if not k.d then G.part(k.m,'Tube',V3(#cols*.44+.1,.84,1.5),pack*CF(0,.14,0),tube,'armor');return end
    for _,x in ipairs(cols)do for _,y in ipairs({-.08,.36})do
        local t=G.cylinder(k.m,'Tube',.21,1.6,pack*CF(x,y,0)*ANG(PI/2,0,0),tube);t.Material=MAT.SmoothPlastic
        local c=G.cylinder(k.m,'MissileCap',.17,.05,pack*CF(x,y,.81)*ANG(PI/2,0,0),cap);if capMat then c.Material=capMat;c.CastShadow=false else k.lit(c,.05)end
    end end
end
local function dish(k,x,y,z,color,refl)
    local span=k.l>=3 and 2.0 or 1.75
    return k.metal(G.part(k.m,'RadarDish',V3(span,.5,span),CF(x,y,z)*ANG(math.rad(48),math.rad(28),0),color,'dish'),refl or .05)
end
local function gantry(k,leg,boom,house,glow,H)
    local top=.33+H
    for _,x in ipairs({-.55,.55})do for _,z in ipairs(k.d and {-1.6,-.42}or {-1.01})do k.b('CraneLeg',{.16,H,k.d and .16 or 1.3},{x,.33+H/2,z},leg)end end
    k.b('CranePortal',{1.36,.22,1.44},{0,top,-1.01},leg,nil,'armor')
    k.b('CraneBoom',{.36,.26,4.05},{0,top+.22,.12},boom,nil,'armor')
    if glow then k.lit(k.b('BoomBand',{.38,.05,3.9},{0,top+.36,.12},glow),.1)end
    k.b('CraneHouse',{.8,.46,.74},{0,top+.58,-1.2},house,nil,'armor')
    return top
end
local function bio(k,kind)
    local lab,frame,green,mint=C(214,224,216),k.P:Lerp(C(96,116,104),.25),k.A,k.S;local L,d=k.l,k.d
    local tint=C(186,236,190);local pipe=C(150,170,160);local deep=C(30,70,58);local hazard=C(236,214,80)
    k.lot(kind,C(70,84,76),C(150,164,154),MAT.Concrete,MAT.Concrete)
    local function tank(x,z,y0,r,h,bubbles,extra,name)
        local function base()k.c(name or 'TankBase',r+.07,.14,{x,y0+.07,z},frame)end
        local function shell()k.glass(k.c('TankGlass',r,h,{x,y0+.14+h/2,z},tint),.55,.2)end
        if d then base()else k.opt(1,base)end
        k.lit(k.c('Culture',r*.8,h,{x,y0+.14+h/2,z},green),.18)
        if d then shell()else k.opt(1,shell)end
        k.c('TankLid',r+.05,.12,{x,y0+.2+h,z},lab)
        for i=1,bubbles+(extra or 0)do
            local a=i*2.4;local bx,bz=x+math.cos(a)*r*.82,z+math.sin(a)*r*.82
            local function make()local b=k.lit(k.ball('Bubble',r*(i%2==0 and .34 or .26),{bx,y0+.25,bz},C(224,255,214)),.3);k.move(b,{fn=rise(h*.85,.5+.08*i),offset=i*1.37})end
            if i>bubbles then k.opt(3,make)else make()end
        end
        return y0+.26+h
    end
    local function pipeline(a,b,r)return k.metal(k.rod('Pipe',a,b,r or .06,pipe),.08)end
    if kind=='City'then
        local H=2.0+.45*(L-1);local tx,tz=-.6,-.55
        k.c('TowerBlock1',.74,.45,{tx,floor+.22,tz},frame)
        local top=tank(tx,tz,floor+.4,.6,H,2,2,'TowerBase')
        k.dome('TowerCrown',{1.3,.8,1.3},{tx,top,tz},lab)
        k.opt(2,function()k.lit(k.c('CrownBand',.66,.06,{tx,top+.04,tz},green),.1)end)
        k.opt(1,function()k.rod('Spire',{tx,top+.3,tz},{tx,top+1.0,tz},.04,frame);k.lit(k.ball('MastLamp',.16,{tx,top+1.04,tz},green))end)
        k.opt(3,function()for _,y in ipairs({.33,.66})do k.c('TankHoop',.63,.06,{tx,floor+.54+H*y,tz},frame)end end)
        local h2=1.5+.4*(L-1)
        k.b('TowerBlock2',{1.05,h2,1.0},{.9,floor+h2/2,-.85},lab,nil,'armor')
        for i=1,(d and L+1 or 1)do k.lit(k.b('Window',{1.07,.1,.7},{.9,floor+h2*i/(L+2),-.8},green),.15)end
        k.opt(1,function()k.b('RoofPlant',{.6,.22,.5},{.78,floor+h2+.11,-.95},frame,nil,'armor')end)
        k.opt(2,function()k.c('RoofFan',.18,.06,{.78,floor+h2+.25,-.95},mint)
            k.lit(k.b('HazardStripe',{1.06,.06,.06},{.9,floor+.12,-.34},hazard),.2)end)
        k.flag(1.25,-1.2,floor+h2,.75,frame,k.owner)
        k.opt(1,function()pipeline({tx+.55,floor+1.2,tz},{.38,floor+1.2,-.75},.08)end)
        k.opt(2,function()k.lit(k.rod('GlowPipe',{tx+.55,floor+.9,tz-.15},{.38,floor+.9,-.95},.045,green),.15)end)
        local th=.8+.25*(L-1)
        for i,x in ipairs({.45,1.2})do tank(x,.85,floor,.3,th,1,i==2 and 1 or 0)end
        k.opt(2,function()pipeline({.45,floor+th+.3,.85},{1.2,floor+th+.3,.85},.05)end)
        if L>=2 then
            k.ball('StoreTank',.95,{-1.0,floor+.85,1.08},lab)
            k.lit(k.c('StoreBand',.49,.07,{-1.0,floor+.85,1.08},green),.15)
            k.opt(2,function()for _,s in ipairs({{-1,-1},{1,1},{-1,1},{1,-1}})do k.rod('StoreLeg',{-1.0+s[1]*.28,floor,1.08+s[2]*.28},{-1.0+s[1]*.22,floor+.6,1.08+s[2]*.22},.04,frame)end end)
            k.opt(1,function()pipeline({-1.0,floor+1.3,1.08},{tx,floor+1.3,tz+.5},.05)end)
        end
        if L>=3 then k.b('LabAnnex',{.7,.6,.6},{-1.3,floor+.3,-.05},lab,nil,'armor');k.lit(k.b('Window',{.04,.1,.45},{-.94,floor+.4,-.05},green),.15)end
    elseif kind=='DefensePost'then
        local h=.7+.18*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            k.b('Wall',{s-.95,h,.42},CF(0,floor+h/2,0)*f,lab,nil,'armor')
            k.dopt(1,function()k.lit(k.b('WallSeam',{s-.95,.06,.44},CF(0,floor+h*.7,0)*f,green),.15)end)
        end end
        for i,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            local x,z=c[1]*1.5,c[2]*1.5
            k.c('Bastion',.5,.2,{x,floor+.1,z},frame)
            k.lit(k.c('Culture',.36,h+.5,{x,floor+.2+(h+.5)/2,z},green),.18)
            k.dopt(1,function()k.glass(k.c('TankGlass',.46,h+.5,{x,floor+.2+(h+.5)/2,z},tint),.55,.2)end)
            k.c('TankLid',.5,.1,{x,floor+.75+h,z},lab)
            local function bub()local b=k.lit(k.ball('Bubble',.16,{x+.3,floor+.3,z},C(224,255,214)),.3);k.move(b,{fn=rise(h+.3,.55),offset=i*1.1})end
            if i<=2 then bub()else k.opt(3,bub)end
        end
        local keep=.95+.2*(L-1)
        k.c('BunkerCore',.75,keep,{0,floor+keep/2,0},frame)
        k.lit(k.c('KeepBand',.76,.07,{0,floor+keep*.75,0},green),.1)
        k.glass(k.dome('ShieldDome',{1.7,1.4,1.7},{0,floor+keep,0},tint),.5,.25)
        k.lit(k.ball('CultureCore',.6,{0,floor+keep+.18,0},green),.1)
        k.b('TurretHead',{.5,.24,.5},{0,floor+keep+.62,0},lab,nil,'armor')
        k.rod('TurretBarrel',{.1,floor+keep+.66,.1},{.75,floor+keep+.7,.75},.06,frame)
        k.flag(-1.5,-1.5,floor+h+.85,1.2,frame,k.owner)
        k.opt(2,function()for _,c in ipairs({{-1,0},{1,0}})do pipeline({c[1]*1.5,floor+h+.35,-1.5},{c[1]*1.5,floor+h+.35,1.5},.05)end end)
        if L>=2 then k.b('Gatehouse',{1.15,h+.3,.62},{0,floor+(h+.3)/2,s/2-.22},lab,nil,'armor')
            k.lit(k.b('GateLight',{.7,.08,.04},{0,floor+h+.05,s/2+.1},green),.1)
            k.opt(2,function()k.b('GateDoor',{.5,.44,.04},{0,floor+.22,s/2+.1},deep)end)
        end
        if L>=3 then k.opt(1,function()for _,x in ipairs({-1.5,1.5})do k.rod('BastionBarrel',{x,floor+h+.6,1.5},{x+.45*math.sign(x),floor+h+.66,1.95},.05,frame)end end)end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(32,86,74))
        for _,s in ipairs({-1,1})do k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},lab,nil,'armor')end
        local top=gantry(k,lab,lab,frame,green,2.45+.25*(L-1))
        k.opt(2,function()k.rod('CraneCable',{0,top+.1,1.35},{0,.95,1.35},.03,frame)end)
        k.b('Hull',{2.5,.42,.86},{-.2,.25,1.15},deep,nil,'armor')
        k.w('Bow',{.86,.42,.55},{1.27,.25,1.15},deep,ANG(0,-PI/2,0))
        k.b('HullStripe',{2.52,.1,.88},{-.2,.38,1.15},k.owner)
        k.b('Bridge',{.5,.55,.7},{-1.15,.72,1.15},lab,nil,'armor')
        k.opt(2,function()k.lit(k.b('BridgeWindow',{.52,.08,.72},{-1.15,.86,1.15},green),.15)end)
        for i,x in ipairs({-.45,.25,.95})do
            if i<3 or L>=2 then
                k.lit(k.c('Culture',.2,.42,{x,.67,1.15},green),.18)
                k.glass(k.c('TankGlass',.26,.42,{x,.67,1.15},tint),.5,.2)
                if i==1 then local b=k.lit(k.ball('Bubble',.12,{x+.2,.5,1.15},C(224,255,214)),.3);k.move(b,{fn=rise(.4,.3),offset=1})end
            end
        end
        tank(1.45,-1.55,floor,.3,.7+.15*(L-1),1,1)
        k.opt(1,function()tank(-1.5,-1.55,floor,.26,.55,0,1)end)
    elseif kind=='Factory'then
        rails(k,C(96,108,100),steel)
        for _,z in ipairs({-.7,1.45})do k.b('ExitGatePost',{.22,1.1,.22},{2.12,floor+.55,z},lab,nil,'armor')end
        k.b('ExitGate',{.3,.2,2.4},{2.12,floor+1.1,.375},frame,nil,'armor')
        k.b('ExitGateBand',{.32,.07,1.6},{2.12,floor+1.0,.375},k.owner)
        k.b('Locomotive',{1.45,.58,.62},{.6,floor+.44,.95},lab,nil,'armor')
        k.w('LocoNose',{.62,.5,.4},{1.5,floor+.4,.95},lab,ANG(0,-PI/2,0))
        k.lit(k.b('LocoStripe',{1.47,.08,.64},{.6,floor+.5,.95},green),.1)
        k.b('TrainCab',{.5,.3,.62},{.1,floor+.88,.95},frame,nil,'armor')
        for i,x in ipairs({-.8,-1.9})do
            k.b('CargoWagon',{1.0,.16,.56},{x,floor+.2,.95},frame)
            k.lit(k.c('Culture',.2,.8,{x,floor+.55,.95},green,ANG(0,0,PI/2)),.2)
            k.dopt(1,function()k.glass(k.c('TankGlass',.26,.86,{x,floor+.55,.95},tint,ANG(0,0,PI/2)),.5,.2)end)
            local function bub()local b=k.lit(k.ball('Bubble',.12,{x-.3,floor+.66,.95},C(224,255,214)),.3);k.move(b,{fn=slide(V3(1,0,0),.6,.35),offset=i})end
            if i==1 then bub()else k.opt(3,bub)end
        end
        k.b('Platform',{3.6,.18,.55},{0,floor+.09,-1.0},lab,nil,'board')
        k.opt(2,function()k.lit(k.b('PlatformEdge',{3.6,.03,.05},{0,floor+.19,-.73},green),.1)end)
        if L>=2 then k.b('TankWagon',{1.2,.14,.5},{1.05,floor+.2,-.2},frame);k.c('ShuntTank',.22,1.1,{1.05,floor+.45,-.2},lab,ANG(0,0,PI/2))
            k.b('ShuntEngine',{.8,.48,.52},{-.15,floor+.37,-.2},lab,nil,'armor')end
        tank(-1.3,-1.05,floor+.18,.26,.7+.2*(L-1),1,1)
        if L>=3 then k.opt(1,function()tank(1.4,-1.05,floor+.18,.22,.6,0,1)end)end
        k.opt(2,function()k.lit(k.ball('SignalLamp',.16,{-1.95,floor+.78,-.75},green));k.rod('SignalPost',{-1.95,floor,-.75},{-1.95,floor+.7,-.75},.045,frame)end)
    elseif kind=='MissileSilo'then
        well2(k,green,frame,lab,green,lab,true)
        k.missiles(C(236,244,236),C(150,236,130))
        local th=2.2+.2*(L-1)
        tank(-1.32,-.55,floor,.36,th,2,1)
        k.dome('Radome',{.6,.4,.6},{-1.32,floor+th+.3,-.55},lab)
        k.opt(2,function()for _,y in ipairs({.8,1.8})do pipeline({-1.0,floor+y,-.5},{-.5,floor+y*.5,-.2},.05)end end)
        k.opt(3,function()for i=1,2 do local b=k.lit(k.ball('Vapor',.22,{(i-1.5)*.7,floor+.2,.55},C(200,255,180)),.4);k.move(b,{fn=drift(1.2,.4,.08),offset=i*1.6})end end)
        tank(1.45,.45,floor,.24,.7,0,1)
        k.opt(3,function()for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do k.lit(k.ball('PadLamp',.14,{c[1]*1.25,floor+.08,c[2]*1.25},green))end end)
        k.opt(1,function()k.b('ServiceArm',{.6,.08,.12},{-.98,floor+1.5,-.45},lab);k.b('ServiceArm',{.6,.08,.12},{-.98,floor+2.2,-.45},lab)end)
    elseif kind=='SAMLauncher'then
        k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},frame,nil,'armor')
        k.lit(k.b('ChassisBand',{1.97,.05,1.57},{.5,floor+.3,.5},green),.15)
        k.c('Turntable',.5,.16,{.5,floor+.44,.5},lab)
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),frame,lab,green)
        local top=tank(-1.05,-.95,floor,.42,.8,1,1)
        k.rod('RadarMast',{-1.05,top,-.95},{-1.05,top+.6,-.95},.07,frame)
        dish(k,-1.05,top+.8,-.95,lab)
        k.b('RadarCabin',{.6,.4,.5},{-1.5,floor+.2,-.1},lab,nil,'armor')
        k.opt(1,function()k.lit(k.b('CabinWindow',{.04,.1,.36},{-1.19,floor+.26,-.1},green),.15);k.b('CabinRoof',{.66,.06,.56},{-1.5,floor+.43,-.1},frame)end)
        k.opt(2,function()pipeline({-.65,floor+.5,-.8},{-.3,floor+.3,.1},.05);pipeline({-1.45,floor+.42,-.4},{-1.25,floor+.7,-.75},.04)end)
        k.opt(3,function()for i,x in ipairs({-.2,.2,.6,1.0})do k.lit(k.ball('PadLamp',.12,{x+.1,floor+.06,1.55},green))end;k.flag(1.6,-1.5,floor,1.6,frame,k.owner)end)
        k.opt(2,function()tank(1.55,-1.0,floor,.2,.5,0,1)end)
    end
end
local function abyss(k,kind)
    local hullC,pale,cyan=k.P:Lerp(C(110,152,184),.42),k.S,k.A;local L,d=k.l,k.d
    local deep=C(16,34,50);local tint=C(170,228,250);local coral=C(255,150,118);local sand=C(66,86,92)
    local function hull(p)p.Material=MAT.Metal;p.Reflectance=.12;return p end
    k.lot(kind,C(36,54,66),sand,MAT.Concrete,MAT.Sand)
    local function bubble(x,y,z,s,h,off,level)
        local function make()local b=k.lit(k.ball('Bubble',s,{x,y,z},C(206,244,255)),.35);k.move(b,{fn=drift(h,.42,.07),offset=off})end
        if level then k.opt(level,make)else make()end
    end
    local function habitat(x,z,y,r,dh,name)
        hull(k.c(name or 'HabDrum',r,.36,{x,y+.18,z},hullC))
        k.lit(k.c('Portholes',r+.01,.07,{x,y+.2,z},cyan),.2)
        k.glass(k.dome('GlassDome',{r*1.9,dh*2,r*1.9},{x,y+.36,z},tint),.45,.25)
        k.dopt(1,function()k.lit(k.ball('DomeLight',r*.7,{x,y+.42,z},warm),.15)end)
        return y+.36+dh
    end
    local function coralLamp(x,z,level)k.opt(level or 2,function()k.lit(k.ball('CoralLamp',.16,{x,floor+.08,z},coral))end)end
    local function kelp(x,z,h,level)k.opt(level or 3,function()k.move(k.b('Kelp',{.08,h,.04},{x,floor+h/2,z},C(70,170,140)),{sway=.12,pivot=V3(0,-h/2,0)})end)end
    if kind=='City'then
        local H=2.1+.45*(L-1);local tx,tz=-.55,-.55
        hull(k.c('TowerBlock1',.62,H,{tx,floor+H/2,tz},hullC))
        for i=1,(d and L+1 or 1)do k.lit(k.c('Portholes',.63,.08,{tx,floor+H*i/(L+2),tz},cyan),.15)end
        hull(k.c('TowerCap',.72,.16,{tx,floor+H+.08,tz},hullC:Lerp(pale,.25)))
        k.glass(k.dome('TowerCrown',{1.3,1.5,1.3},{tx,floor+H+.16,tz},tint),.42,.25)
        k.lit(k.ball('DomeLight',.5,{tx,floor+H+.35,tz},cyan),.1)
        k.b('OwnerRing',{1.28,.12,1.28},{tx,floor+H*.35,tz},k.owner,nil,'armor')
        k.opt(1,function()k.rod('Spire',{tx,floor+H+.8,tz},{tx,floor+H+1.35,tz},.035,pale);k.lit(k.ball('MastLamp',.14,{tx,floor+H+1.38,tz},coral))end)
        bubble(tx+.35,floor+H+.6,tz,.2,1.4,0);bubble(tx-.2,floor+H+.7,tz+.25,.14,1.2,1.1,3)
        local h2=1.2+.35*(L-1)
        local top=habitat(.95,-.9,floor+h2-.36,.62,.55)
        hull(k.c('TowerBlock2',.5,h2-.36,{.95,floor+(h2-.36)/2,-.9},hullC))
        bubble(1.1,top+.1,-.9,.18,1.1,.6)
        local t3=habitat(.85,.85,floor,.72,.6,'TowerBlock3')
        bubble(.75,t3+.05,.85,.16,1.0,1.7,3)
        k.opt(1,function()hull(k.rod('Corridor',{tx+.5,floor+.3,tz+.2},{.35,floor+.3,.7},.15,hullC))end)
        k.opt(2,function()hull(k.rod('Corridor',{tx+.6,floor+1.0,tz-.1},{.5,floor+1.0,-.9},.12,hullC))end)
        if L>=2 then local t4=habitat(-1.15,1.05,floor,.5,.42);bubble(-1.1,t4,1.05,.14,.9,2.3,3)
            k.opt(2,function()hull(k.rod('Corridor',{-.85,floor+.25,.85},{.2,floor+.25,.7},.12,hullC))end)end
        if L>=3 then k.opt(1,function()k.lit(k.c('ObsGlass',.66,.2,{tx,floor+H*.8,tz},cyan),.3)end)end
        coralLamp(1.6,1.6);coralLamp(-1.65,-1.6);coralLamp(.1,1.65,3)
        kelp(1.55,-1.6,.9);kelp(-1.6,.3,.7);kelp(1.65,.1,.6);kelp(-1.7,-.9,.8);kelp(.3,-1.7,.55)
        k.opt(2,function()for i=0,3 do local a=i*PI/2+PI/4;hull(k.b('Fin',{.08,.7,.42},CF(tx,floor+.35,tz)*ANG(0,a,0)*CF(0,0,-.72),pale,nil,'armor'))end end)
        k.opt(2,function()k.b('Searchlight',{.22,.16,.3},{.95,top+.05,-.45},pale,ANG(-.4,0,0),'armor');k.lit(k.b('Lens',{.18,.12,.03},{.95,top+.08,-.29},C(230,250,255),ANG(-.4,0,0)))end)
        bubble(-1.0,floor+.3,-1.4,.12,1.0,.8,3)
    elseif kind=='DefensePost'then
        local h=.6+.16*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            hull(k.b('Wall',{s-.95,h,.42},CF(0,floor+h/2,0)*f,hullC,nil,'armor'))
            k.dopt(1,function()k.lit(k.b('WallSeam',{s-.95,.05,.44},CF(0,floor+h*.65,0)*f,cyan),.15)end)
        end end
        for i,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            local x,z=c[1]*1.5,c[2]*1.5
            hull(k.c('Bastion',.52,h+.15,{x,floor+(h+.15)/2,z},hullC))
            k.glass(k.dome('BastionDome',{.95,.9,.95},{x,floor+h+.15,z},tint),.42,.25)
            k.dopt(1,function()k.lit(k.ball('DomeLight',.34,{x,floor+h+.22,z},i%2==0 and coral or cyan),.1)end)
            bubble(x+.2,floor+h+.55,z,.14,1.0,i*.9,i<=2 and 3 or nil)
        end
        local keep=.9+.2*(L-1)
        hull(k.c('BunkerCore',.8,keep,{0,floor+keep/2,0},hullC))
        k.lit(k.c('Portholes',.81,.08,{0,floor+keep*.6,0},cyan),.1)
        k.glass(k.dome('ShieldDome',{2.0,1.7,2.0},{0,floor+keep,0},tint),.5,.25)
        k.b('TurretHead',{.55,.26,.55},{0,floor+keep+.15,0},pale,nil,'armor')
        k.rod('TurretBarrel',{.1,floor+keep+.2,.1},{.8,floor+keep+.25,.8},.06,deep)
        k.lit(k.ball('DomeLight',.3,{0,floor+keep+.55,0},cyan),.1)
        bubble(.3,floor+keep+.9,-.2,.2,1.3,.4)
        k.flag(-1.5,-1.5,floor+h+.6,1.1,pale,k.owner)
        if L>=2 then hull(k.b('Gatehouse',{1.1,h+.3,.62},{0,floor+(h+.3)/2,s/2-.22},hullC,nil,'armor'))
            k.lit(k.c('Hatch',.24,.04,{0,floor+.35,s/2+.1},coral,ANG(PI/2,0,0)),.1)end
        coralLamp(-.9,-.9);coralLamp(.9,-.9,3);kelp(-.9,.9,.6);kelp(.95,.85,.5)
        if L>=3 then k.opt(1,function()for _,x in ipairs({-1.5,1.5})do k.rod('BastionBarrel',{x,floor+h+.3,1.5},{x+.45*math.sign(x),floor+h+.36,1.95},.05,deep)end end)end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(18,62,96))
        for _,s in ipairs({-1,1})do hull(k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},hullC,nil,'armor'))end
        local H=2.35+.25*(L-1);local top=.33+H
        for _,x in ipairs({-.55,.55})do for _,z in ipairs(d and {-1.6,-.42}or {-1.01})do hull(k.b('CraneLeg',{.16,H,d and .16 or 1.3},{x,.33+H/2,z},hullC))end end
        hull(k.b('CranePortal',{1.36,.22,1.44},{0,top,-1.01},hullC,nil,'armor'))
        k.b('CraneBoom',{.32,.24,4.0},{0,top+.22,.12},pale,nil,'armor')
        k.lit(k.b('BoomBand',{.34,.05,3.8},{0,top+.35,.12},cyan),.15)
        k.b('CraneHouse',{.7,.3,.7},{0,top+.48,-1.2},hullC,nil,'armor')
        k.glass(k.dome('CraneDome',{.66,.6,.66},{0,top+.62,-1.2},tint),.4,.25)
        k.opt(2,function()k.rod('CraneCable',{0,top+.1,1.35},{0,1.0,1.35},.03,deep)end)
        hull(k.c('Hull',.3,2.2,{-.1,.3,1.15},deep:Lerp(hullC,.4),ANG(0,0,PI/2)))
        hull(k.ball('Bow',.6,{1.0,.3,1.15},deep:Lerp(hullC,.4)))
        k.dopt(1,function()hull(k.ball('Stern',.56,{-1.2,.3,1.15},deep:Lerp(hullC,.4)))end)
        k.b('Bridge',{.6,.42,.3},{-.2,.75,1.15},k.owner,nil,'armor')
        k.lit(k.b('BridgeWindow',{.62,.06,.32},{-.2,.86,1.15},cyan),.1)
        k.opt(1,function()k.rod('Periscope',{-.1,.9,1.15},{-.1,1.35,1.15},.03,pale)end)
        k.lit(k.b('Waterline',{2.2,.04,.62},{-.1,.12,1.15},cyan),.2)
        bubble(.6,.5,1.45,.16,1.2,0);bubble(-.7,.5,.85,.13,1.0,1.4,3)
        local t=habitat(1.45,-1.55,floor,.45,.42)
        bubble(1.45,t,-1.55,.14,1.0,2.1,3)
        if L>=2 then k.opt(1,function()habitat(-1.5,-1.55,floor,.38,.36)end)end
        coralLamp(-1.0,-.5);kelp(-1.7,1.8,.5)
        if L>=3 then for _,z in ipairs({-1.6,-.42})do hull(k.b('CraneLeg',{.15,H*.78,.15},{-1.45,.33+H*.39,z},hullC))end
            k.b('CraneBoom2',{.28,.2,3.4},{-1.45,.33+H*.78+.1,-.05},pale,nil,'armor')end
    elseif kind=='Factory'then
        rails(k,C(54,74,84),steel,true)
        for _,z in ipairs({-.7,1.45})do hull(k.b('ExitGatePost',{.26,1.15,.26},{2.12,floor+.57,z},hullC,nil,'armor'))end
        hull(k.b('ExitGate',{.36,.24,2.5},{2.12,floor+1.15,.375},hullC,nil,'armor'))
        k.b('ExitGateBand',{.38,.08,1.6},{2.12,floor+1.04,.375},k.owner)
        local carC=pale:Lerp(hullC,.35)
        hull(k.c('Locomotive',.3,1.4,{.6,floor+.45,.95},carC,ANG(0,0,PI/2)))
        hull(k.ball('LocoNose',.6,{1.3,floor+.45,.95},carC))
        k.lit(k.c('LocoStripe',.31,1.3,{.6,floor+.45,.95},cyan,ANG(0,0,PI/2)),.6)
        k.b('LocoOwner',{1.0,.07,.3},{.55,floor+.76,.95},k.owner)
        for i,x in ipairs({-.8,-1.9})do
            hull(k.c('CargoWagon',.28,1.0,{x,floor+.43,.95},i==1 and hullC or carC,ANG(0,0,PI/2)))
            k.dopt(1,function()k.lit(k.c('Portholes',.29,.08,{x,floor+.43,.95},i==1 and cyan or coral,ANG(0,0,PI/2)),.1)end)
        end
        k.b('Platform',{3.6,.18,.55},{0,floor+.09,-1.0},hullC,nil,'board')
        if L>=2 then hull(k.c('TankWagon',.24,1.2,{1.05,floor+.4,-.2},carC,ANG(0,0,PI/2)));hull(k.b('ShuntEngine',{.8,.46,.5},{-.15,floor+.37,-.2},hullC,nil,'armor'))end
        local t=habitat(-1.35,-1.1,floor+.18,.42,.4)
        bubble(-1.3,t,-1.1,.15,1.1,0)
        k.opt(1,function()local t2=habitat(1.3,-1.1,floor+.18,.36,.34);bubble(1.3,t2,-1.1,.12,.9,1.3,3)end)
        if L>=3 then k.opt(1,function()k.glass(k.c('GlassTunnel',.5,1.6,{-.2,floor+.4,.95},tint,ANG(0,0,PI/2)),.6,.25)end)end
        coralLamp(-1.95,-.6);kelp(2.0,-1.6,.6);kelp(-2.0,1.7,.5);coralLamp(.0,-1.55,3)
    elseif kind=='MissileSilo'then
        well2(k,cyan,deep,hullC,cyan,pale,true)
        k.missiles(C(226,240,248),C(120,214,240))
        local th=2.4+.2*(L-1)
        hull(k.c('ServiceTower',.34,th,{-1.32,floor+th/2,-.55},hullC))
        k.lit(k.c('Portholes',.35,.08,{-1.32,floor+th*.7,-.55},cyan),.1)
        k.dopt(1,function()k.lit(k.c('Portholes',.35,.08,{-1.32,floor+th*.4,-.55},coral),.1)end)
        k.glass(k.dome('Radome',{.8,.8,.8},{-1.32,floor+th,-.55},tint),.4,.25)
        k.lit(k.ball('DomeLight',.3,{-1.32,floor+th+.1,-.55},cyan),.1)
        bubble(-.3,floor+.4,.2,.2,1.8,0);bubble(.4,floor+.4,-.3,.15,1.6,1.2)
        k.opt(3,function()for i=1,2 do local b=k.lit(k.ball('Bubble',.12,{(i-1.5)*.9,floor+.4,.4},C(206,244,255)),.35);k.move(b,{fn=drift(1.4,.42,.07),offset=i*.8+.3})end end)
        k.opt(1,function()for _,y in ipairs({.8,1.6})do k.b('ServiceArm',{.6,.08,.12},{-.98,floor+y,-.45},pale)end end)
        local function fuel()local t=habitat(1.45,.45,floor,.36,.34);bubble(1.45,t,.45,.12,.9,2.2,3)end
        if d then fuel()else k.opt(1,fuel)end
        coralLamp(1.25,-1.0);coralLamp(-1.0,1.25,3);kelp(1.5,-.6,.7);kelp(-.4,1.6,.5)
    elseif kind=='SAMLauncher'then
        hull(k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},hullC,nil,'armor'))
        k.lit(k.b('ChassisBand',{1.97,.05,1.57},{.5,floor+.3,.5},cyan),.15)
        k.c('Turntable',.5,.16,{.5,floor+.44,.5},pale)
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),hullC,pale,cyan)
        local top=habitat(-1.05,-.95,floor,.55,.5,'RadarCabin')
        k.rod('RadarMast',{-1.05,top-.2,-.95},{-1.05,top+.5,-.95},.07,pale)
        dish(k,-1.05,top+.7,-.95,pale,.1)
        bubble(-.7,top,-.7,.16,1.1,0)
        k.opt(1,function()local t=habitat(1.5,-1.2,floor,.36,.32);bubble(1.5,t,-1.2,.12,.9,1.5,3)end)
        coralLamp(-1.6,.6);coralLamp(-.2,1.6,3);kelp(-1.65,1.5,.7);kelp(1.75,1.6,.5,2)
        k.opt(3,function()k.flag(1.75,.1,floor,1.4,pale,k.owner)end)
    end
end
local function volcano(k,kind)
    local rock,lava,hot=k.P:Lerp(C(146,126,116),.8),k.A,k.S;local L,d=k.l,k.d
    local dark=C(52,46,46);local iron=C(104,98,100);local core=C(255,206,110)
    local function stone(p)p.Material=MAT.Basalt;return p end
    k.lot(kind,C(58,50,48),C(84,74,70),MAT.Basalt,MAT.Slate)
    local function ember(x,y,z,h,off,level)
        local function make()local e=k.lit(k.ball('Ember',.1,{x,y,z},core));k.move(e,{fn=drift(h,.55,.1),offset=off})end
        if level then k.opt(level,make)else make()end
    end
    local function columns(x,z,h,r,name)
        stone(k.c(name or 'Column',r,h,{x,floor+h/2,z},rock))
        k.dopt(1,function()stone(k.c('Column',r*.75,h*.72,{x+r*1.1,floor+h*.36,z+r*.4},rock:Lerp(dark,.3)))end)
        k.opt(2,function()stone(k.c('Column',r*.65,h*.55,{x-r*.6,floor+h*.275,z+r*1.05},rock:Lerp(dark,.15)))end)
    end
    local function channel(a,b,w,off,level)
        local pa,pb=V3(a[1],a[2],a[3]),V3(b[1],b[2],b[3]);local len=(pb-pa).Magnitude;local dir=(pb-pa).Unit
        k.lit(k.beam('LavaChannel',a,b,w,.03,lava),.05)
        local function blob()local p=k.lit(k.b('LavaFlow',{w*1.3,.06,w*1.8},CFrame.lookAt(pa,pb),core));k.move(p,{fn=slide(dir,len,.45),offset=off})end
        if level then k.opt(level,blob)else blob()end
    end
    local function cone(x,z,y,r,h,name)
        local n=3
        for i=1,n do local function drum()stone(k.c(i==1 and (name or 'Cone')or 'Cone',r*(1-(i-1)*.27),h/n,{x,y+h/n*(i-.5),z},rock:Lerp(dark,i*.08)))end
            if i==n then k.dopt(1,drum)else drum()end end
        local crater=k.lit(k.c('Crater',r*.38,.06,{x,y+h+.01,z},lava))
        k.dopt(1,function()k.lit(k.b('LavaFall',{.12,h*.95,.06},CF(x,y+h*.5,z)*ANG(0,.5,0)*CF(0,0,r*.66)*ANG(-.35,0,0),lava),.05)end)
        return crater,y+h
    end
    if kind=='City'then
        local H=2.4+.45*(L-1);local tx,tz=-.6,-.55
        stone(k.b('TowerBlock1',{1.0,H,1.0},{tx,floor+H/2,tz},rock,ANG(0,PI/6,0),'armor'))
        for i=1,(d and L+1 or 1)do k.lit(k.b('Window',{.08,H*.18,1.02},{tx,floor+H*(i/(L+2)),tz},lava,ANG(0,PI/6,0)),.1)end
        stone(k.b('TowerCrown',{1.2,.3,1.2},{tx,floor+H+.15,tz},dark,ANG(0,PI/6,0),'armor'))
        k.opt(1,function()for i=0,3 do stone(k.b('Battlement',{.26,.32,.26},CF(tx,floor+H+.45,tz)*ANG(0,PI/6+i*PI/2,0)*CF(.45,0,.45),rock,nil,'armor'))end end)
        local brazier=k.lit(k.c('Brazier',.32,.1,{tx,floor+H+.33,tz},lava));k.light(brazier,lava,7,.9)
        ember(tx,floor+H+.4,tz,1.3,0);ember(tx+.15,floor+H+.4,tz-.1,1.1,1.1,3)
        local h2=1.4+.35*(L-1)
        stone(k.b('TowerBlock2',{1.1,h2*.6,1.05},{.9,floor+h2*.3,-.85},rock,nil,'armor'))
        stone(k.b('TowerBlock2b',{.75,h2*.4,.7},{.9,floor+h2*.8,-.85},rock:Lerp(dark,.2),nil,'armor'))
        k.lit(k.b('Window',{.8,.08,.04},{.9,floor+h2*.45,-.32},lava),.1)
        k.flag(.9,-.85,floor+h2,.8,iron,k.owner)
        local _,ctop=cone(.85,.85,floor,.85,1.0+.25*(L-1),'TowerBlock3')
        ember(.85,ctop,.85,1.3,.5);ember(.75,ctop,.95,1.1,1.7,3)
        k.opt(3,function()for i=1,2 do local s=k.ball('Smoke',.4,{.85,ctop+.3,.85},C(90,84,82));k.fade(s,.45);k.move(s,{fn=drift(1.4,.3,.15),offset=i*2.3})end end)
        channel({.5,floor+.02,.4},{-.2,floor+.02,1.7},.14,0)
        k.opt(2,function()channel({1.2,floor+.02,.4},{1.75,floor+.02,-.6},.1,1.4)end)
        if L>=2 then columns(-1.1,1.05,1.2+.3*(L-2),.3,'TowerBlock4')end
        if L>=3 then k.opt(1,function()stone(k.b('Bridge',{1.0,.16,.3},{.15,floor+1.3,-.75},dark,nil,'armor'))end)end
        k.opt(2,function()columns(1.6,-1.65,.6,.2)end)
        k.opt(2,function()columns(-1.65,-1.65,.75,.22)end)
        k.opt(3,function()columns(1.65,.0,.5,.18)end)
        k.opt(2,function()k.lit(k.c('LavaPool',.5,.03,{-1.5,floor+.01,-.1},lava),.1)end)
        ember(-1.5,floor+.1,-.1,1.0,2.4,3)
    elseif kind=='DefensePost'then
        local h=.75+.18*(L-1);local s=3.3
        for i,side in ipairs({-1,1})do for j,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            stone(k.b('Wall',{s-.95,h,.44},CF(0,floor+h/2,0)*f,rock,nil,'armor'))
            k.dopt(1,function()k.lit(k.b('LavaCrack',{s-1.3,.05,.46},CF(0,floor+h*.45,0)*f*ANG(0,0,(i+j)%2==0 and .12 or -.1),lava),.05)end)
        end end
        for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            local x,z=c[1]*1.5,c[2]*1.5
            stone(k.c('Bastion',.5,h+.45,{x,floor+(h+.45)/2,z},rock:Lerp(dark,.15)))
            k.dopt(1,function()stone(k.c('Column',.3,h+.75,{x-c[1]*.1,floor+(h+.75)/2,z-c[2]*.35},rock))end)
            k.opt(2,function()k.lit(k.c('BastionFire',.28,.05,{x,floor+h+.46,z},lava))end)
        end
        local crater,top=cone(0,0,floor,1.0,1.1+.22*(L-1),'BunkerCore')
        k.light(crater,lava,8,1)
        k.b('TurretHead',{.5,.24,.5},{0,top+.12,0},iron,nil,'armor')
        k.rod('TurretBarrel',{.1,top+.16,.1},{.8,top+.2,.8},.06,dark)
        ember(.2,top+.1,-.2,1.3,0);ember(-.2,top+.1,.2,1.1,1.2,3)
        k.flag(-1.5,-1.5,floor+h+.45,1.3,iron,k.owner)
        channel({-1.0,floor+.02,1.1},{1.0,floor+.02,1.1},.12,0,3)
        if L>=2 then stone(k.b('Gatehouse',{1.1,h+.35,.62},{0,floor+(h+.35)/2,s/2-.22},rock:Lerp(dark,.2),nil,'armor'))
            k.lit(k.b('GateGlow',{.5,.42,.04},{0,floor+.21,s/2+.1},lava),.05)end
        if L>=3 then k.opt(1,function()for _,x in ipairs({-1.5,1.5})do k.rod('BastionBarrel',{x,floor+h+.3,1.5},{x+.45*math.sign(x),floor+h+.36,1.95},.05,iron)end end)end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(28,52,62))
        for _,s in ipairs({-1,1})do stone(k.b('Pier',{.42,.28,2.4},{s*1.94,.14,.95},rock,nil,'armor'))end
        local top=gantry(k,iron,iron,rock,lava,2.45+.25*(L-1))
        k.opt(2,function()k.rod('CraneCable',{0,top+.1,1.35},{0,1.0,1.35},.03,dark)end)
        k.b('Hull',{2.5,.44,.86},{-.2,.25,1.15},dark,nil,'armor')
        k.w('Bow',{.86,.44,.55},{1.27,.25,1.15},dark,ANG(0,-PI/2,0))
        k.b('HullStripe',{2.52,.1,.88},{-.2,.38,1.15},k.owner)
        stone(k.b('Bridge',{.55,.5,.7},{-1.1,.7,1.15},iron,nil,'armor'))
        k.lit(k.b('BridgeWindow',{.57,.07,.72},{-1.1,.85,1.15},lava),.1)
        for i,x in ipairs({-.35,.35})do k.c('Funnel',.15,.5,{x,.72,1.15},iron);k.dopt(1,function()k.lit(k.c('FunnelGlow',.11,.04,{x,.98,1.15},lava))end)
            ember(x,1.0,1.15,1.0,i*.9,i==2 and 3 or nil)end
        k.b('Container',{.5,.28,.6},{.85,.6,1.15},rock,nil,'armor')
        local _,ct=cone(1.45,-1.6,floor,.45,.6+.15*(L-1))
        ember(1.45,ct,-1.6,1.0,1.6,3)
        channel({-1.7,floor+.02,-1.6},{-.8,floor+.02,-1.6},.12,0,3)
        if L>=3 then for _,z in ipairs({-1.6,-.42})do k.b('CraneLeg',{.15,(2.95)*.78,.15},{-1.45,.33+2.95*.39,z},iron)end
            k.b('CraneBoom2',{.28,.2,3.4},{-1.45,.33+2.95*.78+.1,-.05},iron,nil,'armor')end
    elseif kind=='Factory'then
        rails(k,C(60,52,50),C(120,110,110))
        for _,z in ipairs({-.7,1.45})do stone(k.b('ExitGatePost',{.34,1.2,.34},{2.12,floor+.6,z},rock,nil,'armor'))end
        stone(k.b('ExitGate',{.42,.3,2.6},{2.12,floor+1.25,.375},dark,nil,'armor'))
        k.b('ExitGateBand',{.44,.08,1.6},{2.12,floor+1.12,.375},k.owner)
        k.b('Locomotive',{1.45,.56,.6},{.6,floor+.44,.95},iron,nil,'armor')
        k.w('LocoNose',{.6,.48,.4},{1.5,floor+.4,.95},iron,ANG(0,-PI/2,0))
        k.lit(k.b('LocoStripe',{.5,.12,.62},{1.0,floor+.3,.95},lava),.05)
        k.dopt(1,function()k.b('TrainCab',{.5,.32,.6},{.1,floor+.88,.95},dark,nil,'armor')end)
        k.opt(1,function()k.c('Chimney',.1,.3,{1.0,floor+.86,.95},dark);ember(1.0,floor+1.0,.95,1.0,0)end)
        for i,x in ipairs({-.8,-1.9})do
            k.b('CargoWagon',{1.0,.4,.56},{x,floor+.36,.95},dark,nil,'armor')
            local function load()k.lit(k.b('MoltenLoad',{.85,.08,.44},{x,floor+.58,.95},i==1 and core or lava),.05)end
            if i==1 then load()else k.dopt(1,load)end
            k.opt(2,function()stone(k.ball('Ore',.3,{x+.15,floor+.62,.95},rock))end)
        end
        k.b('Platform',{3.6,.18,.55},{0,floor+.09,-1.0},rock,nil,'board')
        channel({-1.7,floor+.2,-.78},{1.7,floor+.2,-.78},.08,.5)
        if L>=2 then k.b('TankWagon',{1.2,.4,.5},{1.05,floor+.38,-.2},dark,nil,'armor');k.lit(k.b('TankGlow',{1.0,.06,.52},{1.05,floor+.45,-.2},lava),.1)
            k.b('ShuntEngine',{.8,.48,.52},{-.15,floor+.37,-.2},iron,nil,'armor')end
        local _,ct=cone(-1.35,-1.15,floor+.18,.42,.55+.15*(L-1))
        ember(-1.35,ct,-1.15,1.0,1.4,3)
        if L>=3 then k.opt(1,function()columns(1.45,-1.2,.8,.2)end)end
        k.opt(2,function()k.lit(k.ball('SignalLamp',.16,{1.95,floor+.78,-.75},lava));k.rod('SignalPost',{1.95,floor,-.75},{1.95,floor+.7,-.75},.045,iron)end)
    elseif kind=='MissileSilo'then
        well2(k,lava,dark,rock,lava,rock,true)
        k.missiles(C(138,128,126),C(255,170,80))
        local th=2.6+.2*(L-1)
        stone(k.b('ServiceTower',{.46,th,.46},{-1.32,floor+th/2,-.55},rock,ANG(0,PI/6,0),'armor'))
        k.lit(k.b('TowerSlit',{.06,th*.6,.48},{-1.32,floor+th*.5,-.55},lava,ANG(0,PI/6,0)),.1)
        k.dopt(1,function()stone(k.c('Column',.2,th*.7,{-1.0,floor+th*.35,-.95},rock:Lerp(dark,.2)))end)
        local b=k.lit(k.c('Brazier',.24,.1,{-1.32,floor+th+.05,-.55},lava));k.light(b,lava,7,.9)
        ember(-1.32,floor+th+.1,-.55,1.0,0);ember(0,floor+.4,.2,1.6,.8);ember(.4,floor+.4,-.4,1.4,1.9,3)
        k.opt(1,function()for _,y in ipairs({.9,1.8})do k.b('ServiceArm',{.6,.08,.12},{-.98,floor+y,-.45},iron)end end)
        k.opt(2,function()channel({1.0,floor+.02,1.2},{1.6,floor+.02,-.3},.1,.3)end)
        local _,ct=cone(1.45,.45,floor,.36,.55);ember(1.45,ct,.45,.9,2.4,3)
        k.opt(3,function()for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do k.lit(k.ball('PadFire',.14,{c[1]*1.25,floor+.08,c[2]*1.25},lava))end end)
    elseif kind=='SAMLauncher'then
        stone(k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},rock,nil,'armor'))
        k.dopt(1,function()k.lit(k.b('ChassisBand',{1.97,.05,1.57},{.5,floor+.3,.5},lava),.1)end)
        k.c('Turntable',.5,.16,{.5,floor+.44,.5},iron)
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),dark,iron,lava)
        columns(-1.05,-.95,.9,.42,'RadarCabin')
        k.rod('RadarMast',{-1.05,floor+.9,-.95},{-1.05,floor+1.55,-.95},.07,iron)
        dish(k,-1.05,floor+1.8,-.95,iron,.1)
        channel({-1.7,floor+.02,.2},{-.2,floor+.02,1.6},.12,0)
        ember(-.6,floor+.9,-.6,1.0,1.1,3)
        k.opt(2,function()local _,ct=cone(1.55,-1.25,floor,.3,.45);ember(1.55,ct,-1.25,.8,2.1,3)end)
        k.opt(3,function()k.flag(1.75,.2,floor,1.4,iron,k.owner)end)
    end
end
local function tesla(k,kind)
    local steelC,pale,blue=k.P:Lerp(C(176,188,212),.82),k.S,k.A;local L,d=k.l,k.d
    local dark=C(36,42,56);local bolt=C(226,236,255);local copper=C(214,170,120)
    local function metal(p)p.Material=MAT.Metal;p.Reflectance=.15;return p end
    k.lot(kind,C(40,46,60),C(70,78,96),MAT.Metal,MAT.DiamondPlate)
    local function coil(x,z,y,h,r,name)
        metal(k.c(name or 'CoilColumn',r,h,{x,y+h/2,z},steelC))
        local rings=d and 3 or 1
        for i=1,rings do local function ring()k.metal(k.c('CoilRing',r+.09,.05,{x,y+h*(.25+.55*(i-1)/math.max(rings-1,1)),z},i%2==0 and copper or pale),.2)end
            if i==1 then k.dopt(1,ring)else k.opt(2,ring)end end
        metal(k.dome('Toroid',{r*4.2,r*1.3,r*4.2},{x,y+h+.04,z},pale))
        local cap=k.lit(k.ball('Terminal',r*1.3,{x,y+h+.24,z},bolt));return V3(x,y+h+.24,z),cap
    end
    local function arcBetween(a,b,seed,level)
        local function make()
            local dir=b-a;local side=dir:Cross(Vector3.yAxis);side=side.Magnitude>.01 and side.Unit or Vector3.xAxis
            local p1=a+dir*.33+side*.16+V3(0,.12,0);local p2=a+dir*.66-side*.16-V3(0,.05,0)
            for i,seg in ipairs({{a,p1},{p1,p2},{p2,b}})do
                local p=k.lit(k.beam('Arc',{seg[1].X,seg[1].Y,seg[1].Z},{seg[2].X,seg[2].Y,seg[2].Z},.05,.05,i==2 and blue or bolt),.05)
                k.move(p,{fn=arc(seed+i*.7)})
            end
        end
        if level then k.opt(level,make)else make()end
    end
    if kind=='City'then
        local H=2.3+.45*(L-1)
        local hall=1.0+.3*(L-1)
        metal(k.b('TowerBlock1',{1.3,hall,1.1},{-.1,floor+hall/2,-.2},dark,nil,'armor'))
        for i=1,(d and L+1 or 1)do k.lit(k.b('Window',{1.32,.07,1.12},{-.1,floor+hall*i/(L+2),-.2},blue),.15)end
        metal(k.b('HallRoof',{1.4,.12,1.2},{-.1,floor+hall+.06,-.2},steelC,nil,'armor'))
        local t1=coil(-.75,-.75,floor,H,.2,'TowerBlock2')
        local t2=coil(.95,-.9,floor,H*.8,.17,'TowerBlock3')
        local t3=coil(.75,.9,floor,H*.62,.16,'TowerCrown')
        arcBetween(t1,t2,0);arcBetween(t2,t3,1.7,1);arcBetween(t3,t1,3.1,3)
        k.flag(-.1,-.2,floor+hall+.12,.8,steelC,k.owner)
        if L>=2 then local t4=coil(-1.2,1.05,floor,H*.5,.14);arcBetween(t4,t3,4.4,3)end
        k.opt(1,function()for _,x in ipairs({-.6,.4})do metal(k.c('Transformer',.22,.5,{x,floor+.25,.75},steelC));k.lit(k.c('TransformerBand',.23,.05,{x,floor+.4,.75},blue),.1)end end)
        k.opt(2,function()k.rod('Cable',{-.75,floor+.4,-.75},{-.6,floor+.45,.75},.03,dark);k.rod('Cable',{.95,floor+.4,-.9},{.4,floor+.45,.75},.03,dark)end)
        k.opt(3,function()for _,c in ipairs({{-1.7,-1.7},{1.7,-1.7},{-1.7,1.7},{1.7,1.7}})do k.lit(k.ball('PadLamp',.14,{c[1],floor+.08,c[2]},blue))end end)
    elseif kind=='DefensePost'then
        local h=.65+.16*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            metal(k.b('Wall',{s-.95,h,.4},CF(0,floor+h/2,0)*f,steelC:Lerp(dark,.35),nil,'armor'))
            k.dopt(1,function()k.lit(k.b('WallLight',{s-.95,.05,.42},CF(0,floor+h+.02,0)*f,blue),.1)end)
        end end
        local tops={}
        for i,c in ipairs({{-1,-1},{1,-1},{1,1},{-1,1}})do
            metal(k.b('Bastion',{.6,h+.1,.6},{c[1]*1.5,floor+(h+.1)/2,c[2]*1.5},dark,ANG(0,PI/4,0),'armor'))
            if i<=2 then tops[i]=coil(c[1]*1.5,c[2]*1.5,floor+h+.1,.75,.11)
            else tops[i]=V3(c[1]*1.5,floor+h+1.09,c[2]*1.5);k.opt(1,function()coil(c[1]*1.5,c[2]*1.5,floor+h+.1,.75,.11)end)end
        end
        for i=1,4 do arcBetween(tops[i],tops[i%4+1],i*1.3,i>1 and (i>2 and 3 or 2)or nil)end
        local keep=.8+.2*(L-1)
        metal(k.c('BunkerCore',.7,keep,{0,floor+keep/2,0},dark))
        k.lit(k.c('KeepBand',.71,.06,{0,floor+keep*.7,0},blue),.1)
        local kt,cap=coil(0,0,floor+keep,1.0,.18,'TurretHead')
        k.light(cap,blue,8,1)
        k.rod('TurretBarrel',{.1,floor+keep+.15,.1},{.85,floor+keep+.2,.85},.06,steelC)
        k.flag(-1.0,-1.5,floor+h,1.3,steelC,k.owner)
        if L>=2 then metal(k.b('Gatehouse',{1.1,h+.3,.6},{0,floor+(h+.3)/2,s/2-.22},dark,nil,'armor'));k.lit(k.b('GateLight',{.7,.07,.04},{0,floor+h+.05,s/2+.1},blue),.1)end
        if L>=3 then k.opt(1,function()for _,x in ipairs({-1.5,1.5})do k.rod('BastionBarrel',{x,floor+h+.3,1.5},{x+.45*math.sign(x),floor+h+.36,1.95},.05,steelC)end end)end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(24,58,96))
        for _,s in ipairs({-1,1})do metal(k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},steelC:Lerp(dark,.3),nil,'armor'))end
        local top=gantry(k,steelC,pale,dark,blue,2.4+.25*(L-1))
        k.opt(2,function()k.rod('CraneCable',{0,top+.1,1.35},{0,1.0,1.35},.03,dark)end)
        k.b('Hull',{2.5,.42,.84},{-.2,.25,1.15},dark,nil,'armor')
        k.w('Bow',{.84,.42,.55},{1.27,.25,1.15},dark,ANG(0,-PI/2,0))
        k.b('HullStripe',{2.52,.1,.86},{-.2,.38,1.15},k.owner)
        metal(k.b('Bridge',{.5,.5,.66},{-1.1,.7,1.15},steelC,nil,'armor'))
        k.lit(k.b('BridgeWindow',{.52,.07,.68},{-1.1,.84,1.15},blue),.1)
        local sc=V3(.35,1.26,1.15);k.opt(1,function()coil(.35,1.15,.47,.55,.1,'Mast')end)
        k.dopt(1,function()k.b('Container',{.55,.3,.62},{-.4,.6,1.15},pale,nil,'armor')end)
        local bt=coil(1.5,-1.55,floor,1.6+.2*(L-1),.16,'Lighthouse')
        arcBetween(bt,V3(.18,top+.22,-.6),0)
        arcBetween(sc,V3(0,top+.1,1.3),2.2,3)
        if L>=3 then for _,z in ipairs({-1.6,-.42})do k.b('CraneLeg',{.15,2.9*.78,.15},{-1.45,.33+2.9*.39,z},steelC)end
            k.b('CraneBoom2',{.28,.2,3.4},{-1.45,.33+2.9*.78+.1,-.05},pale,nil,'armor')end
    elseif kind=='Factory'then
        rails(k,C(70,78,92),steel)
        for _,z in ipairs({-.7,1.45})do metal(k.b('ExitGatePost',{.2,1.25,.2},{2.12,floor+.62,z},steelC,nil,'armor'))end
        metal(k.b('ExitGate',{.26,.18,2.4},{2.12,floor+1.25,.375},steelC,nil,'armor'))
        k.b('ExitGateBand',{.28,.07,1.6},{2.12,floor+1.15,.375},k.owner)
        k.b('Locomotive',{1.5,.56,.6},{.6,floor+.44,.95},pale,nil,'armor')
        k.w('LocoNose',{.6,.5,.4},{1.55,floor+.4,.95},pale,ANG(0,-PI/2,0))
        k.lit(k.b('LocoStripe',{1.52,.07,.62},{.6,floor+.5,.95},blue),.1)
        k.dopt(1,function()k.b('TrainCab',{.5,.28,.6},{.1,floor+.86,.95},dark,nil,'armor')end)
        local wire=floor+1.45
        k.rod('Pantograph',{.7,floor+.72,.95},{.85,wire,.95},.025,dark)
        k.opt(1,function()k.rod('Catenary',{-2.0,wire,.95},{2.12,wire,.95},.02,dark)end)
        arcBetween(V3(.85,wire,.95),V3(.95,floor+.75,.95),0)
        for i,x in ipairs({-.8,-1.9})do k.b('CargoWagon',{1.0,.48,.56},{x,floor+.4,.95},i==1 and steelC or dark,nil,'armor')
            k.dopt(1,function()k.lit(k.b('WagonBand',{1.02,.05,.58},{x,floor+.56,.95},blue),.2)end)end
        k.b('Platform',{3.6,.18,.55},{0,floor+.09,-1.0},steelC:Lerp(dark,.3),nil,'board')
        k.opt(2,function()for _,x in ipairs({-1.2,1.3})do k.rod('CatenaryMast',{x,floor,.55},{x,wire+.05,.55},.04,steelC);k.rod('MastArm',{x,wire,.55},{x,wire,.95},.03,steelC)end end)
        if L>=2 then k.b('TankWagon',{1.2,.42,.5},{1.05,floor+.37,-.2},steelC,nil,'armor');k.b('ShuntEngine',{.8,.48,.52},{-.15,floor+.37,-.2},pale,nil,'armor')end
        local c1=coil(-1.35,-1.1,floor+.18,.9+.2*(L-1),.14,'Substation')
        k.opt(1,function()local c2=coil(1.35,-1.1,floor+.18,.75,.12);arcBetween(c1,c2,2.5,2)end)
    elseif kind=='MissileSilo'then
        well2(k,blue,dark,steelC:Lerp(dark,.3),blue,pale,true)
        k.missiles(C(222,230,246),C(170,200,255))
        local th=2.4+.2*(L-1)
        local t=coil(-1.32,-.55,floor,th,.2,'ServiceTower')
        arcBetween(t,V3(-.75,floor+.3,-.2),0)
        k.opt(1,function()for _,y in ipairs({.8,1.6})do k.b('ServiceArm',{.6,.08,.12},{-.98,floor+y,-.45},steelC)end end)
        k.opt(1,function()local t2=coil(1.4,.5,floor,.9,.12);arcBetween(t2,V3(.8,floor+.3,.3),1.4,2)end)
        k.opt(3,function()for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do k.lit(k.ball('PadLamp',.14,{c[1]*1.25,floor+.08,c[2]*1.25},blue))end end)
    elseif kind=='SAMLauncher'then
        metal(k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},steelC:Lerp(dark,.4),nil,'armor'))
        k.lit(k.b('ChassisBand',{1.97,.05,1.57},{.5,floor+.3,.5},blue),.15)
        k.c('Turntable',.5,.16,{.5,floor+.44,.5},pale)
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),dark,steelC,blue)
        metal(k.b('RadarCabin',{.9,.5,.8},{-1.05,floor+.25,-.95},dark,nil,'armor'))
        k.rod('RadarMast',{-1.05,floor+.5,-.95},{-1.05,floor+1.55,-.95},.08,steelC)
        dish(k,-1.05,floor+1.8,-.95,pale,.15)
        local t=coil(-1.55,.6,floor,1.1,.13,'Pylon')
        arcBetween(t,V3(-1.05,floor+1.3,-.95),0)
        k.opt(1,function()k.lit(k.b('CabinWindow',{.5,.08,.04},{-1.05,floor+.35,-.54},blue),.1)end)
        k.opt(3,function()k.flag(1.75,-1.5,floor,1.4,steelC,k.owner)end)
    end
end
local function palace(k,kind)
    local ivory,navy,gold=k.P,k.S:Lerp(C(96,120,214),.32),k.A:Lerp(C(255,232,150),.25);local L,d=k.l,k.d
    local stoneC=C(206,198,180);local lamp=C(255,226,150);local deep=C(60,48,40);local navyLit=navy:Lerp(C(120,140,230),.35)
    local function G2(p)p.Material=MAT.Metal;p.Reflectance=.14;return p end
    k.lot(kind,C(170,164,150),C(214,208,192),MAT.Cobblestone,MAT.Marble)
    local function tower(x,z,y,h,r,roofH,name,fin)
        k.c(name or 'Tower',r,h,{x,y+h/2,z},ivory)
        roofH=roofH or r*3
        k.dopt(1,function()G2(k.c('Eave',r+.06,.07,{x,y+h,z},gold))end)
        k.dome('SpireRoof',{r*2,roofH*2,r*2},{x,y+h,z},navy)
        k.opt(2,function()k.dome('SpireTip',{r*.62,roofH*.8,r*.62},{x,y+h+roofH*.8,z},navy)end)
        local top=y+h+roofH*1.15
        if fin~=false then k.opt(1,function()G2(k.rod('Finial',{x,top-.05,z},{x,top+.3,z},.025,gold));k.lit(k.ball('FinialJewel',.09,{x,top+.32,z},lamp))end)end
        return top
    end
    local function banner(x,y,z,w,h,rot,level)
        local function make()
            local f=CF(x,y,z)*(rot or CFrame.identity)
            k.move(k.b('Banner',{w,h,.04},f,k.owner),{sway=.07,pivot=V3(0,h/2,0)})
            G2(k.b('BannerRod',{w+.1,.05,.06},f*CF(0,h/2+.02,0),gold))
        end
        if level then k.opt(level,make)else make()end
    end
    local function crown(center,R,n,speed)
        n=d and n or math.ceil(n*.6)
        for i=0,n-1 do
            local f=center*ANG(0,i/n*PI*2,0)*CF(0,0,-R)
            k.move(G2(k.b('CrownBand',{2*PI*R/n*.8,.1,.06},f,gold)),{axis=center,spin=speed})
            if i%2==0 then k.opt(2,function()k.move(G2(k.b('CrownPoint',{.08,.22,.08},f*CF(0,.14,0)*ANG(0,0,PI/4),gold)),{axis=center,spin=speed})end)end
        end
    end
    if kind=='City'then
        local H=1.5+.4*(L-1);local kx,kz=-.2,-.45;local kh=.95+.15*(L-1)
        k.b('TowerBlock1',{1.7,kh,1.5},{kx,floor+kh/2,kz},ivory,nil,'armor')
        G2(k.b('Cornice',{1.76,.08,1.56},{kx,floor+kh,kz},gold))
        k.dopt(1,function()for _,x in ipairs({-.45,0,.45})do k.lit(k.b('Window',{.16,.3,.04},{kx+x,floor+kh*.55,kz+.76},warm),.1)end end)
        local top=tower(kx,kz,floor+kh,H,.48,1.25,'TowerCrown')
        local jewel=k.lit(k.ball('CrownJewel',.18,{kx,top+.1,kz},lamp));k.light(jewel,lamp,8,1)
        k.dopt(1,function()k.lit(k.b('Window',{.18,.36,.04},{kx,floor+kh+H*.55,kz+.48},warm),.1)end)
        crown(CF(kx,floor+kh+H+.05,kz),.62,10,.5)
        for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do tower(kx+c[1]*.78,kz+c[2]*.68,floor+kh,.45,.17,.45,'Turret',c[2]>0)end
        k.b('CurtainWall',{2.6,.55,.3},{0,floor+.275,1.2},ivory,nil,'armor')
        k.dopt(1,function()G2(k.b('WallCoping',{2.64,.06,.34},{0,floor+.56,1.2},gold))end)
        k.b('GateDoor',{.42,.42,.04},{0,floor+.21,1.37},deep)
        G2(k.b('GateArch',{.6,.1,.08},{0,floor+.47,1.37},gold))
        for _,x in ipairs({-1.45,1.45})do tower(x,1.2,floor,1.05+.3*(L-1),.3,.75,'TowerBlock2')end
        banner(-.75,floor+.3,1.37,.32,.42,nil);banner(.75,floor+.3,1.37,.32,.42,nil,2)
        banner(kx,floor+kh*.5,kz+.79,.4,.6,nil)
        if L>=2 then tower(1.3,-1.4,floor,1.3+.35*(L-2),.28,.7,'TowerBlock3')
            k.opt(1,function()k.b('Bridge',{.9,.16,.24},{.85,floor+1.0,-1.0},ivory,ANG(0,.6,0),'armor')end)end
        if L>=3 then tower(-1.45,-1.45,floor,1.5,.26,.65,'TowerBlock4')end
        k.opt(3,function()for _,c in ipairs({{-1.7,1.75},{1.7,1.75}})do k.lit(k.ball('Lantern',.14,{c[1],floor+.1,c[2]},lamp))end end)
    elseif kind=='DefensePost'then
        local h=.75+.18*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            k.b('Wall',{s-.95,h,.4},CF(0,floor+h/2,0)*f,ivory,nil,'armor')
            k.dopt(1,function()G2(k.b('WallCoping',{s-.95,.06,.44},CF(0,floor+h+.03,0)*f,gold))end)
            k.opt(3,function()for _,x in ipairs({-.7,0,.7})do k.b('Merlon',{.22,.18,.36},CF(0,floor+h+.15,0)*f*CF(x,0,0),ivory)end end)
        end end
        for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do tower(c[1]*1.5,c[2]*1.5,floor,h+.55,.42,.85,'Bastion')end
        local keep=1.2+.25*(L-1)
        k.b('BunkerCore',{1.1,keep,1.1},{0,floor+keep/2,0},ivory,nil,'armor')
        G2(k.b('KeepRim',{1.16,.08,1.16},{0,floor+keep,0},gold))
        k.dopt(1,function()k.lit(k.b('Window',{.2,.36,.04},{0,floor+keep*.6,.56},warm),.1)end)
        local top=tower(0,0,floor+keep,.35,.36,.95,'TurretHead')
        local jewel=k.lit(k.ball('CrownJewel',.16,{0,top+.08,0},lamp));k.light(jewel,lamp,8,1)
        crown(CF(0,floor+keep+.4,0),.62,10,.55)
        k.rod('TurretBarrel',{.4,floor+keep-.1,.4},{.95,floor+keep-.05,.95},.06,deep)
        if L>=2 then
            for _,x in ipairs({-.55,.55})do tower(x,s/2-.22,floor,h+.45,.24,.5,'Gatehouse',false)end
            k.b('GateDoor',{.5,.5,.04},{0,floor+.25,s/2-.01},deep)
        end
        banner(0,floor+h*.55,s/2-.0,.5,.55,nil)
        banner(-.8,floor+h*.55,-s/2,.36,.5,ANG(0,PI,0),2)
        k.opt(2,function()k.flag(1.5,1.5,floor+h+1.5,.9,gold,k.owner,true)end)
        if L>=3 then k.opt(1,function()for _,x in ipairs({-1.5,1.5})do G2(k.rod('BastionBarrel',{x,floor+h+.2,1.5},{x+.45*math.sign(x),floor+h+.26,1.95},.05,gold))end end)end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(30,92,138))
        for _,s in ipairs({-1,1})do k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},stoneC,nil,'armor');k.dopt(1,function()G2(k.b('PierTrim',{.46,.04,2.42},{s*1.94,.27,.95},gold))end)end
        local top=gantry(k,ivory,navy,ivory,nil,2.45+.25*(L-1))
        G2(k.b('BoomTrim',{.38,.05,4.0},{0,top+.36,.12},gold))
        k.dome('CraneDome',{.6,.7,.6},{0,top+.81,-1.2},navy)
        k.opt(2,function()k.rod('CraneCable',{0,top+.1,1.35},{0,1.05,1.35},.03,deep)end)
        k.b('Hull',{2.5,.46,.86},{-.15,.27,1.15},navy,nil,'armor')
        k.w('Bow',{.86,.46,.6},{1.4,.27,1.15},navy,ANG(0,-PI/2,0))
        G2(k.b('HullRail',{2.52,.07,.88},{-.15,.48,1.15},gold))
        k.b('Bridge',{.55,.42,.8},{-1.1,.7,1.15},ivory,nil,'armor')
        k.dopt(1,function()k.dome('SternRoof',{.5,.6,.5},{-1.1,.91,1.15},navy)end)
        for i,x in ipairs({-.35,.55})do
            local mh=1.45+(i==2 and .2 or 0)
            G2(k.rod('Mast',{x,.5,1.15},{x,.5+mh,1.15},.04,gold))
            k.move(k.b('Sail',{.06,mh*.55,.95},{x+.03,.5+mh*.55,1.15},k.owner,nil,'soft'),{sway=.04,pivot=V3(0,mh*.27,0),axisX=true})
            k.opt(2,function()k.move(k.b('Pennant',{.05,.12,.4},{x,.5+mh+.05,1.35},navy),{sway=.1,pivot=V3(0,0,-.2),axisX=true})end)
        end
        local lh=2.3+.3*(L-1);local lx,lz=1.55,-1.6
        k.c('Lighthouse',.4,lh,{lx,floor+lh/2,lz},ivory)
        k.dopt(1,function()G2(k.c('LighthouseBand',.42,.08,{lx,floor+lh*.5,lz},gold))end)
        local lantern=k.lit(k.c('Lantern',.26,.3,{lx,floor+lh+.15,lz},lamp));k.light(lantern,lamp,8,1)
        k.dome('SpireRoof',{.7,1.1,.7},{lx,floor+lh+.3,lz},navy)
        k.opt(1,function()G2(k.rod('Finial',{lx,floor+lh+.8,lz},{lx,floor+lh+1.1,lz},.025,gold))end)
        local axis=CF(lx,floor+lh+.15,lz)
        for i=0,(d and 1 or 0)do k.move(k.lit(k.b('LightBeam',{.12,.1,1.5},axis*ANG(0,i*PI,0)*CF(0,0,-.9),lamp),.55),{axis=axis,spin=1.1})end
        banner(-1.5,floor+.85,-2.05,.36,.5,nil,2)
        k.opt(1,function()tower(-1.5,-1.55,floor,.9,.26,.55)end)
        if L>=3 then for _,z in ipairs({-1.6,-.42})do k.b('CraneLeg',{.15,2.95*.78,.15},{-1.45,.33+2.95*.39,z},ivory)end
            k.b('CraneBoom2',{.28,.2,3.4},{-1.45,.33+2.95*.78+.1,-.05},navy,nil,'armor')end
    elseif kind=='Factory'then
        rails(k,C(150,140,124),gold)
        for _,z in ipairs({-.85,1.6})do tower(2.12,z,floor,1.25,.24,.5,'ExitGatePost')end
        k.b('ExitGate',{.4,.32,2.5},{2.12,floor+1.1,.375},ivory,nil,'armor')
        G2(k.b('GateGilt',{.44,.06,2.54},{2.12,floor+1.27,.375},gold))
        k.b('ExitGateBand',{.42,.12,1.6},{2.12,floor+1.0,.375},k.owner)
        k.b('Locomotive',{1.45,.56,.6},{.6,floor+.44,.95},navy,nil,'armor')
        k.w('LocoNose',{.6,.48,.4},{1.5,floor+.4,.95},navy,ANG(0,-PI/2,0))
        G2(k.b('LocoStripe',{1.47,.07,.62},{.6,floor+.6,.95},gold))
        k.b('TrainCab',{.5,.34,.6},{.1,floor+.88,.95},ivory,nil,'armor')
        G2(k.c('Chimney',.09,.3,{1.05,floor+.86,.95},gold))
        for i,x in ipairs({-.8,-1.9})do
            k.b('CargoWagon',{1.0,.5,.58},{x,floor+.42,.95},ivory,nil,'armor')
            k.opt(1,function()k.b('WagonRoof',{1.04,.08,.62},{x,floor+.71,.95},navy)end)
            k.opt(2,function()k.lit(k.b('WagonWindow',{.8,.1,.6},{x,floor+.5,.95},warm),.1)end)
        end
        k.b('Platform',{3.6,.2,.6},{0,floor+.1,-1.05},stoneC,nil,'armor')
        local hh=.8+.1*(L-1)
        k.b('StationHall',{2.6,hh,.55},{-.3,floor+.2+hh/2,-1.25},ivory,nil,'armor')
        k.gable('HallRoof',{2.7,.45,.75},{-.3,floor+.2+hh+.22,-1.25},navy)
        k.dopt(1,function()for _,x in ipairs({-1.1,-.3,.5})do k.lit(k.b('Window',{.3,.3,.04},{x,floor+.2+hh*.5,-.97},warm),.1)end end)
        local ct=tower(1.35,-1.3,floor+.2,1.1+.25*(L-1),.28,.8,'ClockTower')
        local face=k.lit(k.c('ClockFace',.17,.03,{1.35,floor+.2+.9+.25*(L-1),-1.0},lamp,ANG(PI/2,0,0)));k.light(face,lamp,6,.8)
        crown(CF(1.35,floor+1.35+.25*(L-1),-1.3),.42,8,.6)
        banner(2.12,floor+.7,1.15,.3,.45,ANG(0,PI/2,0));banner(2.12,floor+.7,-.4,.3,.45,ANG(0,PI/2,0),2)
        if L>=2 then k.c('TankWagon',.22,1.2,{1.05,floor+.42,-.2},navy,ANG(0,0,PI/2));G2(k.c('TankBand',.23,.1,{1.05,floor+.42,-.2},gold,ANG(0,0,PI/2)))
            k.b('ShuntEngine',{.8,.46,.5},{-.15,floor+.36,-.2},ivory,nil,'armor')end
    elseif kind=='MissileSilo'then
        well2(k,gold,stoneC,ivory,gold,gold)
        k.missiles(C(246,240,226),navyLit)
        local r,len=.3,2.6
        crown(CF(0,floor+1.9,0),k.l==1 and .75 or 1.15,12,.35)
        local th=2.6+.2*(L-1)
        tower(-1.32,-.6,floor,th,.3,.8,'ServiceTower')
        k.dopt(1,function()k.lit(k.b('Window',{.14,.3,.04},{-1.32,floor+th*.6,-.29},warm),.1)end)
        for _,c in ipairs({{1.45,.55},{1.0,-1.25}})do tower(c[1],c[2],floor,.75,.2,.45,'Turret')end
        banner(1.45,floor+.5,.78,.3,.4,nil,2)
        local jewel=k.lit(k.ball('Lantern',.16,{-1.32,floor+th+.95,-.6},lamp));k.light(jewel,lamp,7,.9)
        k.opt(1,function()for _,y in ipairs({.9,1.8})do G2(k.b('ServiceArm',{.6,.07,.12},{-.98,floor+y,-.5},gold))end end)
        k.opt(3,function()for _,c in ipairs({{-1,1},{1,1},{-1,-1}})do k.lit(k.ball('PadLamp',.13,{c[1]*1.25,floor+.08,c[2]*1.25},lamp))end end)
        k.opt(2,function()k.flag(-.4,1.5,floor,1.5,gold,k.owner,true)end)
    elseif kind=='SAMLauncher'then
        k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},ivory,nil,'armor')
        G2(k.b('ChassisTrim',{1.99,.06,1.59},{.5,floor+.36,.5},gold))
        G2(k.c('Turntable',.5,.16,{.5,floor+.44,.5},gold))
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),stoneC,ivory,gold,MAT.Metal)
        k.c('RadarCabin',.58,.95,{-1.05,floor+.47,-.95},ivory)
        k.dopt(1,function()G2(k.c('CabinRim',.62,.08,{-1.05,floor+.95,-.95},gold))end)
        k.dome('CabinDome',{1.1,.8,1.1},{-1.05,floor+.95,-.95},navy)
        G2(k.rod('RadarMast',{-1.05,floor+1.2,-.95},{-1.05,floor+1.8,-.95},.07,gold))
        local dd=dish(k,-1.05,floor+2.0,-.95,gold,.14);dd.Material=MAT.Metal
        crown(CF(-1.05,floor+1.45,-.95),.75,10,-.5)
        k.light(k.lit(k.ball('Lantern',.16,{-1.05,floor+1.2,-.4},lamp)),lamp,7,.9)
        tower(1.6,-1.45,floor,1.1,.22,.55,'Turret')
        banner(1.6,floor+.7,-1.2,.3,.45,nil)
        k.opt(1,function()tower(-1.65,.7,floor,.8,.2,.45)end)
        k.opt(3,function()k.dopt(1,function()k.lit(k.b('Window',{.16,.3,.04},{-1.05,floor+.5,-.37},warm),.1)end)end)
    end
end
local function pyre(k,kind)
    local terra,sand,gold,flame=k.P:Lerp(C(218,144,82),.62),C(222,184,132),k.S,k.A;local L,d=k.l,k.d
    local core=C(255,236,160);local tip=C(255,150,40);local deep=C(70,36,22);local lamp=C(255,200,110)
    local function G2(p)p.Material=MAT.Metal;p.Reflectance=.14;return p end
    k.lot(kind,C(150,104,72),C(204,166,120),MAT.Sandstone,MAT.Sandstone)
    local function brazier(x,y,z,s,light)
        G2(k.c('Brazier',.2*s,.12*s,{x,y+.06*s,z},gold))
        local f=k.lit(k.b('Flame',{.18*s,.34*s,.18*s},{x,y+.3*s,z},flame,ANG(0,PI/4,0)),.1)
        k.move(f,{fn=function(t)return CF(0,math.sin(t*7+x)*.03*s,0),.05+.25*(.5+.5*math.sin(t*11+z))end})
        k.dopt(2,function()local c=k.lit(k.ball('FlameCore',.16*s,{x,y+.22*s,z},core));k.move(c,{fn=rise(.35*s,.6)})end)
        if light then k.light(f,lamp,8,1)end
        return y+.5*s
    end
    local function phoenix(x,y,z,s,full)
        local tilt=ANG(-.45,0,0)
        k.lit(k.ball('PhoenixBody',.34*s,{x,y,z},core))
        k.lit(k.ball('PhoenixHead',.2*s,{x,y+.28*s,z+.08*s},gold))
        k.opt(2,function()k.lit(k.b('Crest',{.04*s,.18*s,.12*s},{x,y+.42*s,z+.02*s},flame,ANG(-.4,0,0)))end)
        for i,a in ipairs({-.35,0,.35})do local function tail()k.lit(k.b('TailFeather',{.1*s,.08*s,.75*s},CF(x,y-.12*s,z)*ANG(.5,a,0)*CF(0,0,-.38*s),i==2 and flame or tip),.05)end
            if i==2 then tail()else k.opt(2,tail)end end
        local lens=full and {.95,.8,.6}or {.85,.6}
        for _,side in ipairs({-1,1})do
            local sh=V3(x+side*.12*s,y+.06*s,z)
            local function flap(t)local a=side*(math.sin(t*1.8)*.28+.08);return CF(sh)*tilt*ANG(0,0,a)*tilt:Inverse()*CF(-sh)end
            for j,len in ipairs(lens)do
                local fan=side*(.55-j*.32)
                local function feather()
                    local p=k.lit(k.b('WingFeather',{len*s,.16*s,.05},CF(sh)*tilt*ANG(0,0,fan)*CF(side*len*s/2,0,0),j==1 and core or j==2 and flame or tip),.05)
                    k.move(p,{fn=flap})
                end
                if j<=2 then feather()else k.opt(1,feather)end
            end
        end
    end
    local function embers(center,R,n,speed,level)
        k.opt(level or 2,function()for i=0,(d and n or math.ceil(n*.5))-1 do
            local f=center*ANG(0,i/n*PI*2,0)*CF(0,0,-R)
            k.move(k.lit(k.ball('Ember',.1,f,i%2==0 and core or flame)),{axis=center,spin=speed,bob=.05})
        end end)
    end
    local function ziggurat(x,z,y,w,dd,steps,h,name)
        for i=1,steps do local f=1-(i-1)*.24
            k.b(i==1 and (name or 'Temple')or 'TempleStep',{w*f,h,dd*f},{x,y+h*(i-.5),z},i%2==1 and terra or sand,nil,'armor')
            k.dopt(1,function()G2(k.b('StepTrim',{w*f+.04,.05,dd*f+.04},{x,y+h*i,z},gold))end)
        end
        return y+h*steps
    end
    local function obelisk(x,z,h,name)
        k.b(name or 'Obelisk',{.3,h,.3},{x,floor+h/2,z},sand,nil,'armor')
        k.dopt(1,function()G2(k.b('ObeliskBand',{.34,.06,.34},{x,floor+h*.75,z},gold))end)
        return brazier(x,floor+h,z,.9)
    end
    if kind=='City'then
        local sh=.42+.12*(L-1)
        local top=ziggurat(-.2,-.35,floor,2.4,2.1,3,sh,'TowerBlock1')
        k.b('Shrine',{.7,.5,.6},{-.2,top+.25,-.35},sand,nil,'armor')
        G2(k.b('ShrineRoof',{.84,.08,.74},{-.2,top+.54,-.35},gold))
        k.dopt(1,function()k.lit(k.b('ShrineDoor',{.28,.34,.04},{-.2,top+.2,-.04},flame),.1)end)
        k.w('Stair',{.6,top-floor,1.0},{-.2,floor+(top-floor)/2,.95},sand,ANG(0,PI,0))
        local py=top+.95
        phoenix(-.2,py+.1,-.35,1.6,true)
        local glow=k.lit(k.ball('SunCore',.3,{-.2,top+.7,-.35},core));k.light(glow,lamp,9,1.1)
        embers(CF(-.2,top+.85,-.35),.85,10,.5,1)
        k.b('OwnerBanner',{.5,.7,.04},{-.2,floor+sh*1.4,.7},k.owner)
        local oh=1.5+.35*(L-1)
        obelisk(1.5,1.3,oh,'TowerBlock2');obelisk(-1.6,1.3,oh*.85,'TowerBlock3')
        if L>=2 then obelisk(1.5,-1.55,oh*1.1,'TowerBlock4')end
        if L>=3 then k.opt(1,function()obelisk(-1.6,-1.55,oh)end)end
    elseif kind=='DefensePost'then
        local h=.72+.18*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            k.b('Wall',{s-.95,h,.42},CF(0,floor+h/2,0)*f,terra,nil,'armor')
            k.dopt(1,function()G2(k.b('WallCoping',{s-.95,.07,.46},CF(0,floor+h+.03,0)*f,gold))end)
        end end
        for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            k.b('Bastion',{.62,h+.35,.62},{c[1]*1.5,floor+(h+.35)/2,c[2]*1.5},sand,nil,'armor')
            brazier(c[1]*1.5,floor+h+.35,c[2]*1.5,1.0)
        end
        local top=ziggurat(0,0,floor,1.5,1.5,2,.5+.12*(L-1),'BunkerCore')
        local glow=k.lit(k.ball('SunCore',.36,{0,top+.18,0},core));k.light(glow,lamp,9,1.1)
        phoenix(0,top+.7,0,1.2,d)
        embers(CF(0,top+.6,0),.8,10,.55)
        k.rod('TurretBarrel',{.5,top-.2,.5},{1.0,top-.15,1.0},.06,deep)
        k.b('OwnerBanner',{.5,.55,.04},{0,floor+h*.5,s/2},k.owner)
        if L>=2 then for _,x in ipairs({-.55,.55})do k.b('Gatehouse',{.36,h+.45,.5},{x,floor+(h+.45)/2,s/2-.22},sand,nil,'armor');k.opt(1,function()brazier(x,floor+h+.45,s/2-.22,.7)end)end end
        if L>=3 then k.opt(1,function()for _,x in ipairs({-1.5,1.5})do G2(k.rod('BastionBarrel',{x,floor+h+.2,1.5},{x+.45*math.sign(x),floor+h+.26,1.95},.05,gold))end end)end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(28,96,118))
        for _,s in ipairs({-1,1})do k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},sand,nil,'armor')end
        local top=gantry(k,sand,gold,terra,nil,2.45+.25*(L-1))
        k.opt(2,function()k.rod('CraneCable',{0,top+.1,1.35},{0,1.05,1.35},.03,deep)end)
        k.b('Hull',{2.5,.44,.86},{-.15,.26,1.15},terra,nil,'armor')
        k.w('Bow',{.86,.44,.6},{1.4,.26,1.15},terra,ANG(0,-PI/2,0))
        G2(k.b('HullRail',{2.52,.07,.88},{-.15,.47,1.15},gold))
        k.b('HullStripe',{2.52,.1,.88},{-.15,.32,1.15},k.owner)
        k.b('Bridge',{.5,.4,.75},{-1.1,.68,1.15},sand,nil,'armor')
        for i,x in ipairs({-.35,.55})do local mh=1.4+(i==2 and .2 or 0)
            G2(k.rod('Mast',{x,.5,1.15},{x,.5+mh,1.15},.04,gold))
            k.move(k.lit(k.b('Sail',{.06,mh*.55,.9},{x+.03,.5+mh*.55,1.15},i==1 and flame or tip),.15),{sway=.05,pivot=V3(0,mh*.27,0),axisX=true})
        end
        k.opt(1,function()k.lit(k.ball('Figurehead',.22,{1.75,.62,1.15},core));k.lit(k.b('WingFeather',{.06,.12,.5},{1.7,.7,1.15},flame,ANG(.4,0,0)))end)
        local lh=1.8+.3*(L-1);local lx,lz=1.5,-1.6
        local lt=ziggurat(lx,lz,floor,.75,.75,2,lh/2,'Lighthouse')
        phoenix(lx,lt+.55,lz,.8,false)
        local glow=k.lit(k.ball('SunCore',.26,{lx,lt+.15,lz},core));k.light(glow,lamp,9,1)
        embers(CF(lx,lt+.4,lz),.55,8,.6,2)
        k.opt(1,function()obelisk(-1.55,-1.55,1.2)end)
        if L>=3 then for _,z in ipairs({-1.6,-.42})do k.b('CraneLeg',{.15,2.95*.78,.15},{-1.45,.33+2.95*.39,z},sand)end
            G2(k.b('CraneBoom2',{.28,.2,3.4},{-1.45,.33+2.95*.78+.1,-.05},gold,nil,'armor'))end
    elseif kind=='Factory'then
        rails(k,C(150,116,88),gold)
        for _,z in ipairs({-.75,1.5})do k.b('ExitGatePost',{.36,1.25,.36},{2.12,floor+.62,z},sand,nil,'armor')end
        k.b('ExitGate',{.42,.3,2.6},{2.12,floor+1.38,.375},terra,nil,'armor')
        G2(k.b('GateGilt',{.46,.06,2.64},{2.12,floor+1.54,.375},gold))
        k.b('ExitGateBand',{.44,.1,1.6},{2.12,floor+1.25,.375},k.owner)
        phoenix(2.12,floor+2.0,.375,1.0,d)
        k.b('Locomotive',{1.45,.56,.6},{.6,floor+.44,.95},terra,nil,'armor')
        k.w('LocoNose',{.6,.48,.4},{1.5,floor+.4,.95},terra,ANG(0,-PI/2,0))
        G2(k.b('LocoStripe',{1.47,.07,.62},{.6,floor+.6,.95},gold))
        k.b('TrainCab',{.5,.34,.6},{.1,floor+.88,.95},sand,nil,'armor')
        brazier(1.05,floor+.72,.95,.8,true)
        for i,x in ipairs({-.8,-1.9})do k.b('CargoWagon',{1.0,.5,.58},{x,floor+.42,.95},sand,nil,'armor')
            k.dopt(1,function()G2(k.b('WagonRoof',{1.04,.07,.62},{x,floor+.7,.95},gold))end)
            k.opt(2,function()k.lit(k.b('WagonWindow',{.8,.1,.6},{x,floor+.5,.95},lamp),.1)end)end
        k.b('Platform',{3.6,.2,.6},{0,floor+.1,-1.05},sand,nil,'armor')
        local hh=.75+.1*(L-1)
        for i=0,(d and 4 or 2)do k.b('Column',{.16,hh,.16},{-1.6+i*(3.2/(d and 4 or 2)),floor+.2+hh/2,-1.2},terra)end
        k.b('Vault',{3.5,.14,.7},{0,floor+.2+hh+.07,-1.2},terra,nil,'armor')
        G2(k.b('VaultTrim',{3.54,.05,.74},{0,floor+.2+hh+.16,-1.2},gold))
        brazier(-1.6,floor+.36+hh,-1.2,.8);k.opt(1,function()brazier(1.6,floor+.36+hh,-1.2,.8)end)
        embers(CF(2.12,floor+1.9,.375),.7,8,.6,3)
        if L>=2 then k.b('TankWagon',{1.2,.42,.5},{1.05,floor+.37,-.2},terra,nil,'armor');G2(k.b('TankBand',{1.22,.06,.52},{1.05,floor+.45,-.2},gold))
            k.b('ShuntEngine',{.8,.46,.5},{-.15,floor+.36,-.2},sand,nil,'armor')end
    elseif kind=='MissileSilo'then
        well2(k,gold,terra,sand,flame,gold)
        k.missiles(C(250,236,206),C(255,196,90))
        embers(CF(0,floor+1.6,0),k.l==1 and .7 or 1.1,12,.45,1)
        local th=1.2+.15*(L-1)
        local tt=ziggurat(-1.35,-.75,floor,.8,.8,3,th/2.2,'ServiceTower')
        phoenix(-1.35,tt+.6,-.75,1.0,true)
        local glow=k.lit(k.ball('SunCore',.28,{-1.35,tt+.15,-.75},core));k.light(glow,lamp,9,1)
        for _,c in ipairs({{1.4,.5},{.9,-1.3}})do obelisk(c[1],c[2],.9)end
        k.b('OwnerBanner',{.45,.55,.04},{-1.35,floor+th*.4,-.33},k.owner)
        k.opt(3,function()for _,c in ipairs({{-1,1},{1,1},{-1,-1}})do k.lit(k.ball('PadFire',.13,{c[1]*1.25,floor+.08,c[2]*1.25},flame))end end)
    elseif kind=='SAMLauncher'then
        k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},terra,nil,'armor')
        G2(k.b('ChassisTrim',{1.99,.06,1.59},{.5,floor+.36,.5},gold))
        G2(k.c('Turntable',.5,.16,{.5,floor+.44,.5},gold))
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),sand,sand,flame)
        local tt=ziggurat(-1.05,-.95,floor,1.1,1.1,2,.4,'RadarCabin')
        G2(k.rod('RadarMast',{-1.05,tt,-.95},{-1.05,tt+.7,-.95},.07,gold))
        local dd=dish(k,-1.05,tt+.9,-.95,gold,.14)
        phoenix(-1.05,tt+.35,-.2,.85,false)
        local glow=k.lit(k.ball('SunCore',.24,{-1.05,tt+.12,-.95},core));k.light(glow,lamp,8,1)
        embers(CF(-1.05,tt+.9,-.95),.8,8,-.5,2)
        obelisk(1.65,-1.5,1.1)
        k.b('OwnerBanner',{.4,.5,.04},{-1.05,floor+.3,-.38},k.owner)
        k.opt(1,function()obelisk(-1.65,.8,.8)end)
    end
end
local function monolith(k,kind)
    local obsidian,corona,violet=k.P,k.S,k.A;local L,d=k.l,k.d
    local edge=violet:Lerp(C(150,110,255),.3);local deep=C(30,28,46);local face=C(64,60,92)
    local tilt=ANG(math.rad(12),0,0)
    k.lot(kind,C(28,26,40),C(46,42,64),MAT.Slate,MAT.Glass)
    local function black(p)p.Material=MAT.Glass;p.Reflectance=.35;return p end
    local function float(p,spec)spec=spec or {};spec.bob=spec.bob or .05;return k.move(p,spec)end
    local function slab(name,x,z,y,w,h,t,rot,lift,off)
        local f=CF(x,y+h/2,z)*(rot or CFrame.identity)
        local s=float(black(k.b(name,{w,h,t},f,obsidian,nil,'armor')),{lift=lift,offset=off,bob=lift and .04 or 0})
        for i,sx in ipairs({-1,1})do
            local function seam()float(k.lit(k.b('Seam',{.04,h*.92,t+.02},f*CF(sx*(w/2-.03),0,0),edge),.05),{lift=lift,offset=off,bob=lift and .04 or 0})end
            k.opt(i,seam)
        end
        return s
    end
    local function ring(name,center,R,n,phase,spin,color,h)
        local segs=k.ring(name,center,R,d and math.ceil(n*.8)or math.ceil(n*.55),h or .06,.08,color or corona,{spin=spin,phase=phase},1.04)
        for _,p in ipairs(segs)do p.Material=MAT.Neon;p.CastShadow=false end
        return segs
    end
    local function prism(pos,phase,s,lift)
        local p=k.lit(k.b('Prism',{.16*(s or 1),.36*(s or 1),.16*(s or 1)},CF(pos[1],pos[2],pos[3])*ANG(PI/4,0,PI/4),C(150,120,255)))
        k.move(p,{hue=true,phase=phase,bob=.07,spin=.7,lift=lift,axis=CF(pos[1],pos[2],pos[3])})
    end
    local function eclipse(x,y,z,R,lift)
        local c=CF(x,y,z)*tilt
        float(black(k.c('EclipseDisc',R,.08,c,C(6,6,12))),{lift=lift,bob=.04})
        local halo=float(k.lit(k.c('CoronaGlow',R*1.3,.04,c*CF(0,-.03,0),violet:Lerp(corona,.5)),.3),{lift=lift,bob=.04})
        halo.CastShadow=false
        local n0=#k.items;ring('Corona',c,R*1.08,12,nil,.4);for i=n0+1,#k.items do k.items[i].lift=lift end
        local bead=k.lit(k.ball('DiamondBead',R*.32,c*CF(0,.02,-R*1.08),C(250,248,255)))
        k.move(bead,{axis=c,spin=.4,lift=lift});k.light(bead,corona,10,1.2)
        k.opt(1,function()local b=k.lit(k.c('LightFall',R*.28,.9,c*CF(0,-.5,0),violet),.45);b.CastShadow=false;k.move(b,{lift=lift,fn=breathe(1.6,.3,.65)})end)
        k.opt(2,function()for i=0,5 do local a=i/6*PI*2+.26
            local p=k.lit(k.b('CoronaRay',{.06,.03,R*.9},c*ANG(0,a,0)*CF(0,-.01,-(R*1.25+R*.45)),corona),.2)
            k.move(p,{phase=3,lift=lift,fn=breathe(2.2,.1,.6,i)})
        end end)
    end
    local up=V3(0,.12,0)
    if kind=='City'then
        local H=2.8+.4*(L-1);local cx,cz=-.3,-.4
        black(k.b('TowerBlock1',{.95,H,.42},{cx,floor+H/2,cz},obsidian,nil,'armor'))
        k.lit(k.b('Seam',{.05,H*.95,.44},{cx-.45,floor+H/2,cz},edge),.05)
        k.dopt(1,function()k.lit(k.b('Seam',{.05,H*.95,.44},{cx+.45,floor+H/2,cz},edge),.05)end)
        k.opt(2,function()k.lit(k.b('Glyph',{.5,.05,.44},{cx,floor+H*.62,cz},corona),.15)end)
        slab('TowerBlock2',.85,-.95,floor+.1,.6,H*.68,.32,ANG(0,-.4,-.12),V3(.08,.08,-.04),1)
        slab('TowerBlock3',.75,.75,floor+.1,.55,H*.5,.3,ANG(0,.5,.1),V3(.08,.06,.08),2)
        if L>=2 then slab('TowerBlock4',-1.25,.95,floor+.1,.5,H*.42,.28,ANG(0,-.6,.1),V3(-.08,.05,.08),3)end
        eclipse(cx,floor+H+.8,cz,.85,up)
        ring('LightRing',CF(cx,floor+H*.55,cz),1.15,12,1,.5)
        ring('LightRing2',CF(cx,floor+H*.4,cz)*ANG(.35,0,.15),1.5,10,2,-.4,violet)
        ring('LightRing3',CF(cx+.2,floor+.5,cz+.2),1.95,12,3,.25)
        prism({1.25,floor+H*.68+.5,-1.1},1);prism({.95,floor+H*.5+.45,.95},1)
        prism({-1.5,floor+1.5,-1.4},2,.9,up);prism({1.6,floor+1.2,.1},3,.9,up)
        k.opt(3,function()for _,c in ipairs({{-1.75,-1.75},{1.75,1.75},{-1.75,1.75}})do k.lit(k.ball('PadLamp',.13,{c[1],floor+.08,c[2]},violet))end end)
    elseif kind=='DefensePost'then
        local h=.65+.16*(L-1);local s=3.3
        for i=0,3 do local f=ANG(0,i*PI/2,0)*CF(0,0,s/2-.24);local out=f.Position.Unit*.1+V3(0,.04,0)
            float(black(k.b('Wall',{s-1.0,h,.36},CF(0,floor+h/2,0)*f,obsidian,nil,'armor')),{lift=out,bob=0,offset=i})
            k.opt(1,function()float(k.lit(k.b('WallSeam',{s-1.05,.05,.1},CF(0,floor+h+.01,0)*f,edge),.05),{lift=out,bob=0,offset=i})end)
        end
        for i,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            slab('Bastion',c[1]*1.5,c[2]*1.5,floor,.42,h+.9,.42,ANG(c[2]*.12,0,-c[1]*.12),V3(c[1]*.06,.05,c[2]*.06),i)
            prism({c[1]*1.62,floor+h+1.3,c[2]*1.62},i<=2 and 1 or 2,.8)
        end
        local keep=1.3+.2*(L-1)
        slab('BunkerCore',0,0,floor,.7,keep,.7,nil)
        k.rod('TurretBarrel',{.3,floor+keep*.7,.3},{.9,floor+keep*.7+.05,.9},.06,deep)
        eclipse(0,floor+keep+.85,0,.62,up)
        ring('LightRing',CF(0,floor+keep*.6,0),1.0,12,1,.6)
        ring('LightRing2',CF(0,floor+keep*.7,0)*ANG(PI/2-.3,0,0),1.25,10,2,.5,violet)
        local dome=k.dome('ShieldDome',{3.9,2.8,3.9},{0,floor+.3,0},C(170,150,240));dome.Material=MAT.Glass;k.fade(dome,.8);dome.CastShadow=false;k.move(dome,{phase=3})
        ring('LightRing3',CF(0,floor+.35,0),1.95,12,3,-.25)
        k.flag(-1.5,-.4,floor+h,1.2,face,k.owner,true)
        if L>=2 then for _,x in ipairs({-.55,.55})do slab('Gatehouse',x,s/2-.24,floor,.3,h+.5,.36,nil)end end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(22,30,64))
        for _,s in ipairs({-1,1})do black(k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},obsidian,nil,'armor'));k.dopt(1,function()k.lit(k.b('PierSeam',{.05,.03,2.4},{s*1.72,.27,.95},edge),.05)end)end
        local top=gantry(k,obsidian,face,obsidian,violet,2.35+.25*(L-1))
        for _,n in ipairs({'CraneLeg','CranePortal','CraneBoom','CraneHouse'})do for _,p in ipairs(k.m:GetChildren())do if p.Name==n then black(p)end end end
        local ship={black(k.b('Hull',{2.5,.4,.84},{-.2,.3,1.15},obsidian,nil,'armor')),black(k.w('Bow',{.84,.4,.55},{1.27,.3,1.15},obsidian,ANG(0,-PI/2,0))),
            k.lit(k.b('Waterline',{2.52,.05,.86},{-.2,.14,1.15},corona),.05),k.b('Bridge',{.5,.46,.6},{-1.1,.72,1.15},face,nil,'armor'),k.b('HullStripe',{1.4,.1,.86},{.1,.46,1.15},k.owner)}
        for _,p in ipairs(ship)do float(p,{bob=.04,freq=1.2})end
        ring('LightRing',CF(.2,1.0,1.15),.6,10,1,.7)
        local lh=2.0+.3*(L-1)
        slab('Lighthouse',1.5,-1.6,floor,.5,lh,.4,nil)
        eclipse(1.5,floor+lh+.75,-1.6,.5,up)
        ring('LightRing2',CF(1.5,floor+lh*.55,-1.6),.75,10,2,-.6,violet)
        ring('LightRing3',CF(0,top+.5,-1.0),1.3,12,3,.3)
        prism({-1.5,floor+1.3,-1.6},1);prism({1.0,1.4,1.7},2,.8,up)
        k.opt(2,function()slab('Shard',-1.5,-1.6,floor,.36,1.0,.3,ANG(0,.4,.1),V3(-.05,.06,0),2)end)
        if L>=3 then for _,z in ipairs({-1.6,-.42})do black(k.b('CraneLeg',{.15,2.85*.78,.15},{-1.45,.33+2.85*.39,z},obsidian))end
            black(k.b('CraneBoom2',{.28,.2,3.4},{-1.45,.33+2.85*.78+.1,-.05},face,nil,'armor'))end
    elseif kind=='Factory'then
        rails(k,C(36,34,54),violet,true)
        for _,z in ipairs({-.7,1.45})do black(k.b('ExitGatePost',{.22,1.2,.22},{2.12,floor+.6,z},obsidian,nil,'armor'))end
        black(k.b('ExitGate',{.28,.2,2.4},{2.12,floor+1.2,.375},obsidian,nil,'armor'))
        k.b('ExitGateBand',{.3,.08,1.6},{2.12,floor+1.08,.375},k.owner)
        ring('GateRing',CF(-1.35,floor+.95,.375)*ANG(0,0,PI/2),1.0,12,1,.5)
        local train={black(k.b('Locomotive',{1.6,.48,.56},{.55,floor+.48,.95},obsidian,nil,'armor')),black(k.w('LocoNose',{.56,.48,.75},{1.72,floor+.48,.95},obsidian,ANG(0,-PI/2,0))),
            k.lit(k.b('LocoStripe',{2.1,.05,.58},{.8,floor+.42,.95},corona),.05),k.b('LocoOwner',{1.0,.07,.4},{.4,floor+.73,.95},k.owner),
            black(k.b('CargoWagon',{1.3,.44,.54},{-.95,floor+.46,.95},obsidian,nil,'armor')),k.lit(k.b('WagonSeam',{1.32,.05,.56},{-.95,floor+.55,.95},edge),.1)}
        for _,p in ipairs(train)do float(p,{bob=.035,freq=2,lift=V3(0,.04,0)})end
        k.b('Platform',{3.6,.18,.55},{0,floor+.09,-1.0},face,nil,'board')
        k.dopt(1,function()k.lit(k.b('PlatformEdge',{3.6,.03,.05},{0,floor+.19,-.73},edge),.05)end)
        slab('StationPylon',0,-1.4,floor+.18,.6,1.5+.2*(L-1),.3,nil)
        eclipse(0,floor+2.4+.2*(L-1),-1.4,.5,up)
        ring('LightRing2',CF(2.12,floor+1.0,.375)*ANG(0,0,PI/2),1.05,10,2,-.6,violet)
        ring('LightRing3',CF(0,floor+1.2,-1.4),1.2,12,3,.35)
        if L>=2 then black(k.b('TankWagon',{1.3,.4,.5},{1.05,floor+.42,-.2},obsidian,nil,'armor'));black(k.b('ShuntEngine',{.8,.44,.5},{-.15,floor+.42,-.2},obsidian,nil,'armor'))end
        prism({-1.5,floor+.9,-1.1},1);prism({1.5,floor+.9,-1.1},2)
        if L>=3 then k.opt(1,function()slab('Shard',1.4,-1.35,floor+.18,.36,.9,.26,ANG(0,.3,.12),V3(.05,.05,0),1)end)end
    elseif kind=='MissileSilo'then
        well2(k,corona,deep,obsidian,violet,face,true)
        for _,p in ipairs(k.m:GetChildren())do if p.Name=='HatchDoor'then black(p)end end
        k.missiles(C(240,238,252),violet:Lerp(C(255,255,255),.25),floor+.3,{bob=.04,lift=V3(0,.06,0)})
        local th=2.8+.2*(L-1)
        slab('ServiceTower',-1.35,-.6,floor,.5,th,.36,nil)
        eclipse(0,floor+3.9,-.2,.62,up)
        ring('LightRing',CF(0,floor+1.0,0),k.l==1 and .8 or 1.2,12,1,.7)
        ring('LightRing2',CF(0,floor+1.9,0)*ANG(.35,0,0),k.l==1 and 1.05 or 1.4,10,2,-.5,violet)
        ring('LightRing3',CF(0,floor+.4,0),1.75,12,3,.25)
        slab('Shard',1.45,.5,floor,.36,1.2,.28,ANG(0,.5,-.12),V3(.06,.06,0),1)
        prism({-1.35,floor+th+.4,-.6},1);prism({1.5,floor+1.6,.5},2,.8,up)
        k.opt(3,function()for _,c in ipairs({{-1,1},{1,1},{-1,-1},{1,-1}})do k.lit(k.ball('PadLamp',.13,{c[1]*1.25,floor+.08,c[2]*1.25},violet))end end)
    elseif kind=='SAMLauncher'then
        black(k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},obsidian,nil,'armor'))
        k.lit(k.b('ChassisSeam',{1.97,.05,1.57},{.5,floor+.3,.5},edge),.05)
        k.c('Turntable',.5,.16,{.5,floor+.44,.5},face)
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),obsidian,face,corona)
        slab('RadarCabin',-1.05,-.95,floor,.6,1.3,.5,nil)
        k.rod('RadarMast',{-1.05,floor+1.3,-.95},{-1.05,floor+1.75,-.95},.07,face)
        dish(k,-1.05,floor+1.95,-.95,corona:Lerp(face,.25),.2)
        eclipse(-1.55,floor+2.7,-1.55,.5,up)
        ring('LightRing',CF(-1.05,floor+1.2,-.95),.85,12,1,.6)
        ring('LightRing2',CF(-1.05,floor+1.6,-.95)*ANG(.4,0,.2),1.15,10,2,-.5,violet)
        ring('LightRing3',CF(-.2,floor+.6,-.2),2.0,12,3,.22)
        prism({1.55,floor+1.5,-1.4},1);prism({-1.6,floor+1.0,.7},2,.8,up)
        k.opt(2,function()slab('Shard',1.6,-1.4,floor,.34,1.0,.26,ANG(0,.4,.1),V3(.05,.05,0),2)end)
        k.opt(3,function()k.flag(1.75,1.5,floor,1.3,face,k.owner,true)end)
    end
end
local themes={
    {'bio',3,bio},{'abyss',3,abyss},{'volcano',3,volcano},{'tesla',3,tesla},{'palace',4,palace},{'pyre',4,pyre},
    {'monolith',5,monolith},
}
function M.register(themeTable,motionTable,kitFn)
    T,kit=themeTable,kitFn
    for _,t in ipairs(themes)do
        local key,grade,build=t[1],t[2],t[3]
        themeTable[key]=function(k,kind)
            build(extend(k),kind)
            if grade==3 then fit(k,refCount('neon',kind,k.l,k.d))
            elseif grade==4 then fit(k,refCount('orbital',kind,k.l,k.d)-1)
            else fit(k,refCount('orbital',kind,k.l,k.d)+12)end
        end
        motionTable[key]=grade==3 and 1 or grade==4 and 3 or 4
    end
end
return M
