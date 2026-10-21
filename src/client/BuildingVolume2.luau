local G=require(script.Parent.ToyGeometry)
local V3,CF,ANG=Vector3.new,CFrame.new,CFrame.Angles
local MAT=Enum.Material
local PI=math.pi
local C=Color3.fromRGB
local floor=.31
local well=C(12,16,22)
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
    return k
end
local function hash(n)local x=math.sin(n*12.9898+4.1)*43758.5453;return x-math.floor(x)end
local function rise(h,speed,t0)return function(t)local y=(t*speed)%h;return CF(0,y,0),(t0 or .25)+.7*(y/h)^2 end end
local function fall(h,speed,sway)return function(t)local y=(t*speed)%h;return CF(math.sin(t*1.9)*(sway or .12),-y,math.cos(t*1.3)*(sway or .12)),.15+.8*(y/h)^3 end end
local function slide(dir,len,speed)return function(t)local s=(t*speed)%len;local f=s/len;return CF(dir*s),.1+.85*math.abs(f*2-1)^6 end end
local function breathe(f,lo,hi,seed)return function(t)return nil,lo+(hi-lo)*(.5+.5*math.sin(t*f+(seed or 0)))end end
local function glitch(seed,amp)return function(t,ph)
    local s=math.floor(t*7+seed*3.1);local chance=({.14,.45,.8})[ph or 1]
    if hash(s+seed*17)<chance then local a=amp*(ph or 1)
        return CF(math.floor((hash(s*1.3+seed)-.5)*4+.5)*a,0,math.floor((hash(s*2.1+seed)-.5)*4+.5)*a),nil end
    return nil,nil
end end
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
local corners={{-1,-1},{1,-1},{-1,1},{1,1}}
local function pagoda(k,kind)
    local jade,gold=k.S,k.A:Lerp(C(255,230,150),.15);local L,d=k.l,k.d
    local wall=k.S:Lerp(C(240,246,238),.55);local tile=k.P:Lerp(C(30,92,86),.3);local deep=k.P;local lamp=C(255,224,140);local pearl=C(236,255,246)
    local function G2(p)p.Material=MAT.Metal;p.Reflectance=.14;return p end
    k.lot(kind,C(44,66,62),C(78,104,96),MAT.Slate,MAT.Marble)
    local function storey(x,z,y,w,h,name,lvl)
        k.b(name or 'Storey',{w,h,w},{x,y+h/2,z},wall,nil,'armor')
        local ew=w+.46
        k.b('Eave',{ew,.1,ew},{x,y+h+.05,z},tile,nil,'armor')
        k.dopt(lvl or 1,function()G2(k.b('EaveTrim',{ew+.05,.04,ew+.05},{x,y+h+.11,z},gold))end)
        k.opt((lvl or 1)+1,function()for _,c in ipairs(corners)do
            G2(k.b('EaveTip',{.07,.2,.07},{x+c[1]*ew/2,y+h+.17,z+c[2]*ew/2},gold,ANG(c[2]*.55,0,-c[1]*.55)))end end)
        return y+h+.1
    end
    local function tower(x,z,y,w,n,h,name)
        local top=y
        for i=1,n do top=storey(x,z,top,w*(1-.17*(i-1)),h*(1-.1*(i-1)),i==1 and name or 'Storey',math.min(i,3))end
        k.dome('RoofCap',{w*.55,.4,w*.55},{x,top,z},tile)
        k.opt(1,function()G2(k.rod('Finial',{x,top+.1,z},{x,top+.65,z},.035,gold))end)
        return top
    end
    local function lantern(x,y,z,lvl,i)
        local function make()
            local l=k.lit(k.b('Lantern',{.15,.2,.15},{x,y-.16,z},i%2==0 and lamp or jade),.05)
            k.move(l,{sway=.14,pivot=V3(0,.16,0),offset=i})
            k.move(G2(k.b('LanternCap',{.18,.04,.18},{x,y-.05,z},gold)),{sway=.14,pivot=V3(0,.05,0),offset=i})
        end
        if lvl then k.opt(lvl,make)else make()end
    end
    local function dragon(cx,cz,y,R,n,speed)
        n=d and n or math.ceil(n*.7)
        local axis=CF(cx,y,cz);local function f(a,h)local r=R*(1+.18*math.sin(a*2));return axis*ANG(0,a,0)*CF(0,h+.2*math.sin(a*2+.6),-r)end
        local spec={axis=axis,spin=speed,bob=.06,freq=2.2}
        for i=0,n-1 do
            local a=i/n*PI*1.65;local s=.32-.15*(i/n)
            k.move(k.ball('DragonBody',s,f(a,0),i%3==0 and gold or jade),spec)
            if i%2==1 then k.opt(2,function()k.move(G2(k.b('DragonFin',{.05,.14,.12},f(a,s*.45),gold)),spec)end)end
        end
        local ha=PI*1.65+.12;local head=f(ha,.04)*ANG(0,-PI/2,0)
        k.move(k.b('DragonHead',{.4,.24,.28},head,jade,nil,'armor'),spec)
        k.move(G2(k.b('DragonJaw',{.22,.08,.22},head*CF(-.22,-.08,0),gold)),spec)
        for _,s in ipairs({-1,1})do
            k.move(G2(k.b('DragonHorn',{.04,.04,.3},head*CF(.1,.14,s*.08)*ANG(.6,s*.4,0),gold)),spec)
            k.opt(1,function()k.move(k.lit(k.b('DragonEye',{.05,.05,.05},head*CF(-.1,.06,s*.13),lamp)),spec)end)
            k.opt(3,function()k.move(G2(k.b('Whisker',{.36,.02,.02},head*CF(-.3,-.02,s*.14)*ANG(0,s*.35,0),gold)),spec)end)
        end
        local orb=k.lit(k.ball('DragonPearl',.24,f(ha+.45,.18),pearl));k.move(orb,{axis=axis,spin=speed,bob=.09,freq=1.4});k.light(orb,jade,9,1.1)
    end
    local function glints(cx,cz,y,R,n,h)
        for i=1,n do local a=i*2.39;local x,z=cx+math.cos(a)*R,cz+math.sin(a)*R
            local function make()k.move(k.lit(k.ball('ScaleGlint',.08,{x,y,z},i%2==0 and jade or gold),.15),{fn=rise(h,.45+.06*i),offset=i*1.3})end
            if i>2 then k.opt(3,make)else make()end
        end
    end
    if kind=='City'then
        local tx,tz=-.35,-.4;local n=2+L
        local top=tower(tx,tz,floor,1.25,n,.55,'TowerBlock1')
        local crown=G2(k.c('TowerCrown',.12,.08,{tx,top+.7,tz},gold));crown.Material=MAT.Neon
        dragon(tx,tz,floor+.55*n*.55+.5,1.15,12,.32)
        local hy=storey(1.15,-1.25,floor,.7,.55+.15*(L-1),'TowerBlock2',2)
        k.dome('RoofCap',{.4,.3,.4},{1.15,hy,-1.25},tile)
        if L>=2 then storey(1.2,.55,floor,.62,.45,'TowerBlock3',2)end
        for _,x in ipairs({-.75,.75})do k.c('GatePost',.08,1.0,{x,floor+.5,1.45},deep)end
        k.b('GateBeam',{1.9,.12,.2},{0,floor+1.02,1.45},tile,nil,'armor')
        G2(k.b('GateGilt',{1.95,.05,.24},{0,floor+1.1,1.45},gold))
        k.move(k.b('Banner',{.5,.45,.04},{0,floor+.72,1.45},k.owner),{sway=.06,pivot=V3(0,.22,0)})
        for i,c in ipairs(corners)do lantern(tx+c[1]*.86,floor+.55+.05,tz+c[2]*.86,i>2 and 2 or nil,i)end
        glints(tx,tz,floor+.6,1.0,4,2.2)
    elseif kind=='DefensePost'then
        local h=.65+.16*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            k.b('Wall',{s-.95,h,.4},CF(0,floor+h/2,0)*f,wall,nil,'armor')
            k.dopt(1,function()G2(k.b('WallCoping',{s-.9,.07,.46},CF(0,floor+h+.03,0)*f,tile))end)
        end end
        for _,c in ipairs(corners)do k.b('Bastion',{.5,h+.3,.5},{c[1]*1.5,floor+(h+.3)/2,c[2]*1.5},wall,nil,'armor');k.dome('RoofCap',{.8,.34,.8},{c[1]*1.5,floor+h+.3,c[2]*1.5},tile)end
        local top=tower(0,0,floor,1.05,1+math.min(L,2),.5,'BunkerCore')
        local crown=G2(k.c('TurretHead',.12,.08,{0,top+.7,0},gold));crown.Material=MAT.Neon
        dragon(0,0,floor+.95,1.0,9,.36)
        if L>=2 then k.opt(1,function()for _,x in ipairs({-.5,.5})do k.c('GatePost',.08,.9,{x,floor+.45,s/2-.05},deep)end
            k.b('GateBeam',{1.3,.12,.2},{0,floor+.92,s/2-.05},tile,nil,'armor')end)end
        k.flag(1.5,1.5,floor+h+.9,.85,gold,k.owner,true)
        for i,x in ipairs({-.6,.6})do lantern(x,floor+h+.02,s/2+.05,nil,i)end
        k.opt(2,function()for i,x in ipairs({-.6,.6})do lantern(x,floor+h+.02,-s/2-.05,nil,i+2)end end)
        glints(0,0,floor+.6,.8,4,1.8)
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(24,88,104))
        for _,s in ipairs({-1,1})do k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},C(70,96,90),nil,'armor');k.dopt(1,function()G2(k.b('PierTrim',{.46,.04,2.42},{s*1.94,.27,.95},gold))end)end
        local top=gantry(k,deep,tile,wall,nil,2.3+.25*(L-1))
        G2(k.b('BoomTrim',{.38,.05,4.0},{0,top+.36,.12},gold))
        k.b('Hull',{2.4,.42,.84},{-.15,.27,1.15},deep,nil,'armor')
        k.w('Bow',{.84,.42,.6},{1.35,.27,1.15},deep,ANG(0,-PI/2,0))
        G2(k.b('HullRail',{2.44,.06,.86},{-.15,.47,1.15},gold))
        k.b('ProwHead',{.36,.26,.24},{1.75,.62,1.15},jade,nil,'armor')
        k.opt(1,function()for _,s in ipairs({-1,1})do G2(k.b('ProwHorn',{.22,.04,.04},{1.75,.8,1.15+s*.07},gold,ANG(0,0,.6)))end end)
        for i,x in ipairs({-.6,.35})do
            local mh=1.3+(i==2 and .2 or 0)
            k.rod('Mast',{x,.48,1.15},{x,.48+mh,1.15},.04,deep)
            k.move(k.b('Sail',{.06,mh*.6,.9},{x+.03,.48+mh*.55,1.15},k.owner,nil,'soft'),{sway=.04,pivot=V3(0,mh*.3,0),axisX=true})
            k.opt(2,function()for j=1,2 do G2(k.b('SailBatten',{.07,.03,.92},{x+.03,.48+mh*(.35+.25*j),1.15},gold))end end)
        end
        local lx,lz=1.55,-1.6
        local lt=tower(lx,lz,floor,.62,1+L,.5,'Lighthouse')
        local beacon=k.lit(k.ball('Lantern',.2,{lx,lt+.3,lz},lamp));k.light(beacon,lamp,8,1)
        dragon(lx-.15,lz+.15,floor+.75,.75,9,.4)
        for i,x in ipairs({-1.94,1.94})do lantern(x,.7,2.0,i==2 and 2 or nil,i)end
        k.opt(1,function()for _,x in ipairs({-1.94,1.94})do k.c('LampPost',.03,.45,{x,.5,2.0},deep)end end)
        glints(lx,lz,floor+.5,.6,3,1.6)
    elseif kind=='Factory'then
        rails(k,C(70,90,84),gold)
        for _,z in ipairs({-.85,1.6})do k.c('ExitGatePost',.1,1.3,{2.12,floor+.65,z},deep)end
        k.b('ExitGate',{.4,.16,2.7},{2.12,floor+1.36,.375},tile,nil,'armor')
        G2(k.b('GateGilt',{.44,.05,2.75},{2.12,floor+1.46,.375},gold))
        k.b('ExitGateBand',{.42,.12,1.6},{2.12,floor+1.15,.375},k.owner)
        dragon(2.12,.375,floor+1.7,.6,8,.45)
        k.b('Locomotive',{1.45,.52,.6},{.6,floor+.42,.95},deep,nil,'armor')
        k.b('LocoNose',{.42,.32,.42},{1.48,floor+.5,.95},jade,nil,'armor')
        k.opt(1,function()for _,s in ipairs({-1,1})do G2(k.b('NoseHorn',{.26,.04,.04},{1.5,floor+.72,.95+s*.12},gold,ANG(0,0,.6)))end end)
        G2(k.b('LocoStripe',{1.47,.07,.62},{.6,floor+.58,.95},gold))
        k.b('TrainCab',{.5,.32,.6},{.1,floor+.84,.95},wall,nil,'armor')
        for _,x in ipairs({-.8,-1.9})do
            k.b('CargoWagon',{1.0,.48,.58},{x,floor+.4,.95},wall,nil,'armor')
            k.opt(1,function()k.b('WagonRoof',{1.08,.08,.66},{x,floor+.68,.95},tile)end)
        end
        k.b('Platform',{3.6,.2,.6},{0,floor+.1,-1.05},C(96,120,112),nil,'armor')
        local sy=storey(-.3,-1.35,floor+.2,.9,.6+.1*(L-1),'StationHall',2)
        k.dome('RoofCap',{.5,.3,.5},{-.3,sy,-1.35},tile)
        local ct=tower(1.35,-1.35,floor+.2,.6,1+math.min(L,2),.45,'ClockTower')
        local face=k.lit(k.ball('Lantern',.18,{1.35,ct+.25,-1.35},lamp));k.light(face,lamp,6,.8)
        for i,x in ipairs({-1.2,.6})do lantern(x,floor+1.05,-.75,i==2 and 2 or nil,i)end
        if L>=2 then k.c('TankWagon',.22,1.2,{1.05,floor+.42,-.2},deep,ANG(0,0,PI/2));G2(k.c('TankBand',.23,.1,{1.05,floor+.42,-.2},gold,ANG(0,0,PI/2)))
            k.b('ShuntEngine',{.8,.46,.5},{-.15,floor+.36,-.2},jade,nil,'armor')end
        glints(2.12,.375,floor+.8,.5,3,1.4)
    elseif kind=='MissileSilo'then
        well2(k,gold,tile,deep,gold,jade)
        k.missiles(C(236,246,240),gold)
        dragon(0,0,floor+1.6,k.l==1 and .85 or 1.2,10,.3)
        local st=tower(-1.32,-.6,floor,.55,1+math.min(L,2),.6,'ServiceTower')
        k.light(k.lit(k.ball('Lantern',.16,{-1.32,st+.3,-.6},lamp)),lamp,7,.9)
        for i,c in ipairs({{1.3,1.2},{-1.3,1.2},{1.3,-1.2}})do k.opt(1,function()k.c('LampPost',.03,.6,{c[1],floor+.3,c[2]},deep)end);lantern(c[1],floor+.66,c[2],i==3 and 2 or nil,i)end
        k.opt(2,function()k.flag(1.5,.3,floor,1.4,gold,k.owner,true)end)
        glints(0,0,floor+.5,1.0,4,2.4)
    elseif kind=='SAMLauncher'then
        k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},deep,nil,'armor')
        G2(k.b('ChassisTrim',{1.99,.06,1.59},{.5,floor+.36,.5},gold))
        G2(k.c('Turntable',.5,.16,{.5,floor+.44,.5},gold))
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),tile,wall,gold,MAT.Metal)
        local cy=storey(-1.05,-.95,floor,.85,.6,'RadarCabin',2)
        G2(k.rod('RadarMast',{-1.05,cy,-.95},{-1.05,cy+.75,-.95},.07,gold))
        dish(k,-1.05,cy+.95,-.95,gold,.14).Material=MAT.Metal
        dragon(-1.05,-.95,cy+.35,.75,9,-.4)
        local tt=tower(1.6,-1.45,floor,.5,2,.45,'Turret')
        k.move(k.b('Banner',{.3,.4,.04},{1.6,floor+.55,-1.2},k.owner),{sway=.07,pivot=V3(0,.2,0)})
        for i,c in ipairs({{-1.6,.7},{1.65,1.5}})do k.c('LampPost',.03,.6,{c[1],floor+.3,c[2]},deep);lantern(c[1],floor+.66,c[2],i==2 and 2 or nil,i)end
        k.light(k.lit(k.ball('Lantern',.14,{1.6,tt+.3,-1.45},lamp)),lamp,6,.8)
        glints(-1.05,-.95,floor+.6,.7,3,1.8)
    end
end
local function crystal(k,kind)
    local plat,ice,gold=k.P,k.S,k.A;local L,d=k.l,k.d
    local glassC=ice:Lerp(C(220,240,255),.35);local deep=C(40,56,78);local white=C(248,252,255);local core=C(190,228,255)
    local function G2(p)p.Material=MAT.Metal;p.Reflectance=.2;return p end
    local function crys(p,t)return k.glass(p,t or .28,.35)end
    k.lot(kind,C(150,160,174),C(214,222,232),MAT.Marble,MAT.Glass)
    local function tower(name,x,z,y,w,h,lvl)
        crys(k.b(name,{w,h,w},{x,y+h/2,z},glassC,ANG(0,PI/4,0)))
        k.lit(k.b('CrystalCore',{w*.45,h*.96,w*.45},{x,y+h/2,z},core,ANG(0,PI/4,0)),.2)
        local r=w*.707
        local frame=function()for i=0,3 do local a=i*PI/2;G2(k.b('GoldFrame',{.05,h,.05},{x+math.cos(a)*r,y+h/2,z+math.sin(a)*r},gold))end end
        if lvl then k.opt(lvl,frame)else k.dopt(1,frame)end
        G2(k.b('GoldCap',{w+.08,.07,w+.08},{x,y+h,z},gold,ANG(0,PI/4,0)))
        return y+h
    end
    local function gem(x,y,z,s,speed)
        local axis=CF(x,y,z);local spec={axis=axis,spin=speed,bob=.05,freq=1.2}
        k.move(crys(k.b('GemPavilion',{s*.72,s*.72,s*.72},axis*ANG(PI/4,0,PI/4),white),.12),spec)
        k.move(crys(k.c('GemTable',s*.42,.08,axis*CF(0,s*.42,0),white),.18),spec)
        k.move(G2(k.c('GemGirdle',s*.56,.05,axis*CF(0,s*.2,0),gold)),spec)
        local heart=k.lit(k.ball('GemHeart',s*.35,axis,core));k.move(heart,spec);k.light(heart,core,10,1.2)
        k.opt(2,function()for i=0,3 do k.move(crys(k.b('GemFacet',{s*.22,s*.06,s*.3},axis*ANG(0,i*PI/2+PI/4,0)*CF(0,s*.3,-s*.36)*ANG(-.5,0,0),white),.2),spec)end end)
        return y+s*.5
    end
    local function star(x,y,z,R,speed)
        local axis=CF(x,y,z)
        for i=0,7 do local len=i%2==0 and R or R*.55
            local p=k.lit(k.b('StarRay',{.12,.04,len},axis*ANG(0,i*PI/4,0)*CF(0,0,-len/2),i%2==0 and white or ice),.08)
            p.CastShadow=false;k.move(p,{axis=axis,spin=speed})
        end
        k.opt(1,function()local h=k.lit(k.c('StarHalo',R*.42,.03,{x,y-.01,z},ice),.45);h.CastShadow=false end)
    end
    local function sparkle(x,z,y,R,n,h)
        for i=1,n do local a=i*2.2;local px,pz=x+math.cos(a)*R,z+math.sin(a)*R
            local function tw()k.move(k.lit(k.b('Twinkle',{.1,.1,.1},CF(px,y+h*(.3+.12*(i%4)),pz)*ANG(PI/4,0,PI/4),white),.2),{fn=breathe(3.2+.4*i,0,.9,i*1.7),spin=1.2,axis=CF(px,0,pz)})end
            local function mote()k.move(k.lit(k.ball('IceMote',.07,{px*.9,y,pz*.9},ice),.2),{fn=rise(h,.5+.07*i),offset=i*1.1})end
            if i>2 then k.opt(3,tw);k.opt(3,mote)else tw();mote()end
        end
    end
    if kind=='City'then
        local H=2.2+.45*(L-1);local tx,tz=-.45,-.4
        k.b('TowerBase',{1.35,.2,1.35},{tx,floor+.1,tz},plat,nil,'armor')
        local top=tower('TowerBlock1',tx,tz,floor+.2,.95,H)
        star(tx,top+.06,tz,1.05,.3)
        local gy=gem(tx,top+.75,tz,.85,.6)
        G2(k.c('TowerCrown',.1,.25,{tx,top+.18,tz},gold))
        local h2=1.2+.35*(L-1)
        tower('TowerBlock2',.95,-1.0,floor,.66,h2)
        star(.95,floor+h2+.05,-1.0,.55,-.4)
        if L>=2 then tower('TowerBlock3',.95,.75,floor,.58,.9+.25*(L-2),2)end
        k.flag(-1.5,1.4,floor,1.0,gold,k.owner,true)
        k.opt(2,function()G2(k.b('PlazaGilt',{2.6,.03,.06},{0,floor+.02,1.6},gold))end)
        sparkle(tx,tz,floor+.4,1.1,5,gy-floor)
    elseif kind=='DefensePost'then
        local h=.62+.16*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            k.b('Wall',{s-.95,h,.4},CF(0,floor+h/2,0)*f,plat,nil,'armor')
            k.dopt(1,function()crys(k.b('WallGlass',{s-.95,.14,.44},CF(0,floor+h+.07,0)*f,glassC),.3)end)
            k.opt(2,function()G2(k.b('WallGilt',{s-.9,.04,.46},CF(0,floor+h+.15,0)*f,gold))end)
        end end
        for _,c in ipairs(corners)do tower('Bastion',c[1]*1.5,c[2]*1.5,floor,.5,h+.6,2)end
        local keep=1.0+.25*(L-1)
        local top=tower('BunkerCore',0,0,floor,.95,keep)
        star(0,top+.06,0,1.0,.32)
        local gy=gem(0,top+.7,0,.8,.65)
        G2(k.c('TurretHead',.1,.22,{0,top+.15,0},gold))
        k.flag(1.5,1.5,floor+h+.6,.9,gold,k.owner,true)
        if L>=2 then k.opt(2,function()for _,x in ipairs({-.55,.55})do tower('Gatehouse',x,s/2-.22,floor,.3,h+.35,3)end end)end
        sparkle(0,0,floor+.4,1.0,5,gy-floor)
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(40,118,160))
        for _,s in ipairs({-1,1})do k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},plat,nil,'armor');k.dopt(1,function()G2(k.b('PierTrim',{.46,.04,2.42},{s*1.94,.27,.95},gold))end)end
        local top=gantry(k,plat,plat:Lerp(ice,.3),plat,nil,2.35+.25*(L-1))
        G2(k.b('BoomTrim',{.38,.05,4.0},{0,top+.36,.12},gold))
        k.opt(2,function()crys(k.b('CraneGlass',{.82,.2,.76},{0,top+.9,-1.2},glassC),.3)end)
        k.b('Hull',{2.4,.38,.82},{-.15,.25,1.15},white,nil,'armor')
        k.w('Bow',{.82,.38,.7},{1.4,.25,1.15},white,ANG(0,-PI/2,0))
        G2(k.b('HullRail',{2.44,.05,.84},{-.15,.45,1.15},gold))
        crys(k.b('Bridge',{.9,.34,.62},{-.6,.62,1.15},glassC),.25)
        k.rod('Mast',{.45,.44,1.15},{.45,2.0,1.15},.04,gold)
        k.move(k.b('Sail',{.06,1.1,.8},{.48,1.3,1.15},k.owner,nil,'soft'),{sway=.04,pivot=V3(0,.55,0),axisX=true})
        local lx,lz=1.55,-1.6
        local lt=tower('Lighthouse',lx,lz,floor,.52,2.0+.3*(L-1))
        star(lx,lt+.05,lz,.6,.4)
        local gy=gem(lx,lt+.6,lz,.6,.7)
        sparkle(lx,lz,floor+.4,.7,4,gy-floor)
        k.opt(3,function()k.lit(k.b('WaterGlint',{1.2,.02,.05},{-.2,.07,2.0},white),.4)end)
    elseif kind=='Factory'then
        rails(k,C(150,160,174),gold)
        for _,z in ipairs({-.85,1.6})do tower('ExitGatePost',2.12,z,floor,.32,1.25,1)end
        k.b('ExitGate',{.4,.2,2.6},{2.12,floor+1.35,.375},plat,nil,'armor')
        G2(k.b('GateGilt',{.44,.05,2.64},{2.12,floor+1.47,.375},gold))
        k.b('ExitGateBand',{.42,.12,1.6},{2.12,floor+1.15,.375},k.owner)
        local gy=gem(2.12,floor+2.05,.375,.6,.7)
        k.b('Locomotive',{1.4,.48,.58},{.55,floor+.4,.95},white,nil,'armor')
        crys(k.w('LocoNose',{.58,.42,.5},{1.5,floor+.37,.95},glassC,ANG(0,-PI/2,0)),.2)
        G2(k.b('LocoStripe',{1.42,.06,.6},{.55,floor+.54,.95},gold))
        crys(k.b('TrainCab',{.5,.28,.58},{.05,floor+.78,.95},glassC),.25)
        for _,x in ipairs({-.85,-1.95})do
            k.b('CargoWagon',{1.0,.44,.56},{x,floor+.38,.95},white,nil,'armor')
            k.opt(1,function()crys(k.b('WagonGlass',{.9,.12,.58},{x,floor+.56,.95},glassC),.3)end)
        end
        k.b('Platform',{3.6,.2,.6},{0,floor+.1,-1.05},plat,nil,'armor')
        local st=tower('StationHall',-.3,-1.35,floor+.2,.7,.8+.15*(L-1))
        star(-.3,st+.05,-1.35,.7,.35)
        tower('ClockTower',1.3,-1.35,floor+.2,.42,1.1+.2*(L-1),2)
        if L>=2 then k.c('TankWagon',.22,1.2,{1.05,floor+.42,-.2},plat,ANG(0,0,PI/2));G2(k.c('TankBand',.23,.1,{1.05,floor+.42,-.2},gold,ANG(0,0,PI/2)))
            k.b('ShuntEngine',{.8,.44,.5},{-.15,floor+.34,-.2},white,nil,'armor')end
        sparkle(2.12,.375,floor+.6,.55,4,gy-floor)
    elseif kind=='MissileSilo'then
        well2(k,gold,deep,plat,gold,gold,true)
        k.missiles(C(250,252,255),glassC)
        star(0,floor+.36,0,1.25,.25)
        local st=tower('ServiceTower',-1.32,-.6,floor,.48,2.5+.2*(L-1))
        local gy=gem(-1.32,st+.55,-.6,.55,.7)
        for _,c in ipairs({{1.45,.6},{1.1,-1.3}})do tower('Turret',c[1],c[2],floor,.3,.75,2)end
        k.opt(2,function()k.flag(-.4,1.5,floor,1.4,gold,k.owner,true)end)
        sparkle(0,0,floor+.4,1.1,5,gy-floor)
    elseif kind=='SAMLauncher'then
        k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},plat,nil,'armor')
        G2(k.b('ChassisTrim',{1.99,.06,1.59},{.5,floor+.36,.5},gold))
        G2(k.c('Turntable',.5,.16,{.5,floor+.44,.5},gold))
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),deep,white,gold,MAT.Metal)
        local ct=tower('RadarCabin',-1.05,-.95,floor,.8,.85)
        star(-1.05,ct+.05,-.95,.85,.35)
        G2(k.rod('RadarMast',{-1.05,ct,-.95},{-1.05,ct+.7,-.95},.07,gold))
        dish(k,-1.05,ct+.9,-.95,white,.2).Material=MAT.Metal
        local gy=gem(1.55,floor+1.9,-1.4,.55,.75)
        tower('Turret',1.55,-1.4,floor,.32,1.1,1)
        k.flag(1.75,1.5,floor,1.2,gold,k.owner,true)
        sparkle(-.2,-.2,floor+.4,1.2,5,gy-floor)
    end
end
local function sanctum(k,kind)
    local ivory,gold,pink=k.P,k.S:Lerp(C(255,214,120),.25),k.A;local L,d=k.l,k.d
    local marble=C(232,232,242);local deep=C(120,112,140);local lamp=C(255,240,200);local violet=C(214,150,255)
    local function G2(p)p.Material=MAT.Metal;p.Reflectance=.16;return p end
    local function float(p,spec)spec=spec or {};spec.bob=spec.bob or .05;spec.lift=spec.lift or V3(0,.1,0);return k.move(p,spec)end
    k.lot(kind,C(196,194,210),C(236,234,244),MAT.Marble,MAT.Marble)
    local function temple(name,x,z,y,R,h,n,off)
        local spec={offset=off}
        local function fl(p)return float(p,table.clone(spec))end
        fl(k.c(name,R,.2,{x,y+.1,z},marble))
        k.opt(2,function()fl(G2(k.c('TempleRim',R+.04,.05,{x,y+.22,z},gold)))end)
        n=d and n or math.ceil(n*.6)
        for i=0,n-1 do local a=i/n*PI*2;fl(k.c('Column',.06,h,{x+math.cos(a)*R*.78,y+.2+h/2,z+math.sin(a)*R*.78},ivory))end
        fl(k.c('Entablature',R*.92,.14,{x,y+.27+h,z},ivory))
        k.dopt(1,function()fl(G2(k.c('Frieze',R*.94,.04,{x,y+.36+h,z},gold)))end)
        fl(k.dome('TempleDome',{R*1.3,R*.9,R*1.3},{x,y+.34+h,z},ivory))
        k.opt(1,function()fl(k.lit(k.c('InnerLight',R*.45,h*.8,{x,y+.2+h/2,z},lamp),.35))end)
        return y+.34+h+R*.45
    end
    local function wing(root,yaw,side,len,phase,i,lift)
        local base=CF(root)*ANG(0,yaw,0)
        for j=1,3 do
            local l=len*(1-.2*(j-1));local f=base*ANG(0,side*(j-2)*.32,0)*CF(side*l/2,0,0)
            local spec={sway=.12,pivot=V3(-side*l/2,0,0),phase=phase,offset=i,lift=lift}
            local p=k.b('Feather',{l,.05,.2-.03*j},f,j==1 and ivory or marble,nil,'soft');k.move(p,spec)
            if j==3 then k.fade(p,.35)end
            if j==1 then local e=k.lit(k.b('FeatherEdge',{l*.9,.02,.04},f*CF(0,.035,.06),gold),.15);k.move(e,table.clone(spec))end
        end
        local sheen=k.b('WingSheen',{len,.03,.36},base*CF(side*len/2,.05,0),pink);sheen.Material=MAT.ForceField;sheen.CastShadow=false
        k.move(sheen,{sway=.12,pivot=V3(-side*len/2,0,0),phase=phase,offset=i,lift=lift})
    end
    local function wings(x,y,z,len,lift)
        for pair=1,3 do local yaw=({0,.55,-.55})[pair];local l=len*({1,.85,.72})[pair]
            for _,side in ipairs({-1,1})do wing(V3(x,y+.04*pair,z),yaw,side,l,pair>1 and pair or nil,pair,lift)end
        end
    end
    local function halo(x,y,z,R,lift)
        local axis=CF(x,y,z)
        local segs=k.ring('Halo',axis,R,d and 10 or 7,.07,.09,pink,{spin=.5,phase=3,lift=lift},1.06)
        for _,p in ipairs(segs)do p.Material=MAT.Neon;p.CastShadow=false end
        local disc=k.lit(k.c('HaloGlow',R*1.25,.02,axis*CF(0,-.02,0),violet),.6);disc.CastShadow=false;k.move(disc,{phase=3,lift=lift,fn=breathe(1.4,.45,.75)})
        local orb=k.lit(k.ball('HaloCore',.16,{x,y,z},C(255,236,250)));k.move(orb,{phase=3,lift=lift});k.light(orb,pink,10,1.2)
    end
    local function feathers(x,z,y,R,n,h)
        for i=1,n do local a=i*2.3;local px,pz=x+math.cos(a)*R,z+math.sin(a)*R
            local function f1()k.move(k.lit(k.b('FallingFeather',{.18,.02,.07},CF(px,y+h,pz)*ANG(0,a,.3),gold),.2),{fn=fall(h,.35+.05*i),offset=i*1.4})end
            local function f2()k.move(k.lit(k.ball('GraceSpark',.07,{px*.8+x*.2,y,pz*.8+z*.2},i%2==0 and pink or violet),.2),{fn=rise(h*.8,.5+.06*i),offset=i*.9})end
            if i>3 then k.opt(3,f1);k.opt(3,f2)else f1();f2()end
        end
    end
    local up=V3(0,.1,0)
    if kind=='City'then
        local tx,tz=-.3,-.35
        k.b('TowerBase',{1.9,.18,1.9},{tx,floor+.09,tz},marble,nil,'armor')
        k.b('TowerStep',{1.5,.14,1.5},{tx,floor+.25,tz},ivory,nil,'armor')
        local y1=temple('TowerBlock1',tx,tz,floor+.6,.75,.75+.2*(L-1),6,0)
        local top=temple('TowerCrown',tx,tz,y1-.05,.45,.45,4,.5)
        wings(tx,top-.2,tz,1.6,up)
        halo(tx,top+.5,tz,.55,up)
        temple('TowerBlock2',1.15,-1.2,floor+.3,.42,.55+.15*(L-1),4,1)
        if L>=2 then k.c('TowerBlock3',.3,.9,{1.1,floor+.45,.85},ivory);float(k.lit(k.ball('ShrineOrb',.3,{1.1,floor+1.15,.85},lamp),.1),{offset=1.6})end
        k.flag(-1.6,1.45,floor,1.0,gold,k.owner,true)
        feathers(tx,tz,floor+.3,1.3,6,2.6)
    elseif kind=='DefensePost'then
        local h=.62+.16*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            k.b('Wall',{s-.95,h,.4},CF(0,floor+h/2,0)*f,marble,nil,'armor')
            k.dopt(1,function()G2(k.b('WallCoping',{s-.9,.06,.44},CF(0,floor+h+.03,0)*f,gold))end)
        end end
        for i,c in ipairs(corners)do k.c('Bastion',.36,h+.2,{c[1]*1.5,floor+(h+.2)/2,c[2]*1.5},ivory)
            float(k.lit(k.ball('BastionCap',.26,{c[1]*1.5,floor+h+.55,c[2]*1.5},lamp),.1),{offset=i})end
        k.c('BunkerCore',.6,.4,{0,floor+.2,0},marble)
        local top=temple('TurretHead',0,0,floor+.55,.7,.7+.15*(L-1),6,0)
        wings(0,top-.2,0,1.5,up)
        halo(0,top+.45,0,.5,up)
        k.flag(1.5,1.5,floor+h+.2,.9,gold,k.owner,true)
        if L>=2 then for _,x in ipairs({-.55,.55})do k.c('Gatehouse',.16,h+.35,{x,floor+(h+.35)/2,s/2-.22},ivory)end end
        feathers(0,0,floor+.3,1.2,6,2.2)
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(70,140,190))
        for _,s in ipairs({-1,1})do k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},marble,nil,'armor');k.dopt(1,function()G2(k.b('PierTrim',{.46,.04,2.42},{s*1.94,.27,.95},gold))end)end
        local top=gantry(k,ivory,ivory,marble,nil,2.3+.25*(L-1))
        G2(k.b('BoomTrim',{.38,.05,4.0},{0,top+.36,.12},gold))
        k.b('Hull',{2.4,.38,.82},{-.15,.25,1.15},ivory,nil,'armor')
        k.w('Bow',{.82,.38,.6},{1.4,.25,1.15},ivory,ANG(0,-PI/2,0))
        G2(k.b('HullRail',{2.44,.05,.84},{-.15,.45,1.15},gold))
        k.rod('SwanNeck',{1.55,.4,1.15},{1.85,1.0,1.15},.06,ivory)
        for i,x in ipairs({-.6,.35})do local mh=1.3+(i==2 and .2 or 0)
            G2(k.rod('Mast',{x,.44,1.15},{x,.44+mh,1.15},.04,gold))
            k.move(k.b('Sail',{.06,mh*.6,.9},{x+.03,.44+mh*.55,1.15},k.owner,nil,'soft'),{sway=.04,pivot=V3(0,mh*.3,0),axisX=true})
        end
        local lx,lz=1.5,-1.55
        k.c('Lighthouse',.3,1.4+.25*(L-1),{lx,floor+.7+.125*(L-1),lz},marble)
        local lt=temple('LighthouseTemple',lx,lz,floor+1.45+.25*(L-1),.4,.4,4,0)
        wings(lx,lt-.15,lz,1.0,up)
        halo(lx,lt+.4,lz,.4,up)
        feathers(lx,lz,floor+.4,.8,5,2.2)
    elseif kind=='Factory'then
        rails(k,C(200,198,214),gold)
        for _,z in ipairs({-.85,1.6})do k.c('ExitGatePost',.12,1.3,{2.12,floor+.65,z},ivory)end
        k.b('ExitGate',{.4,.2,2.6},{2.12,floor+1.35,.375},marble,nil,'armor')
        G2(k.b('GateGilt',{.44,.05,2.64},{2.12,floor+1.47,.375},gold))
        k.b('ExitGateBand',{.42,.12,1.6},{2.12,floor+1.15,.375},k.owner)
        k.b('Locomotive',{1.4,.48,.58},{.55,floor+.4,.95},ivory,nil,'armor')
        k.w('LocoNose',{.58,.42,.5},{1.5,floor+.37,.95},marble,ANG(0,-PI/2,0))
        G2(k.b('LocoStripe',{1.42,.06,.6},{.55,floor+.54,.95},gold))
        k.b('TrainCab',{.5,.28,.58},{.05,floor+.78,.95},marble,nil,'armor')
        for _,x in ipairs({-.85,-1.95})do k.b('CargoWagon',{1.0,.44,.56},{x,floor+.38,.95},ivory,nil,'armor')
            k.opt(1,function()G2(k.b('WagonGilt',{1.02,.04,.58},{x,floor+.6,.95},gold))end)end
        k.b('Platform',{3.6,.2,.6},{0,floor+.1,-1.05},marble,nil,'armor')
        local st=temple('StationHall',-.3,-1.3,floor+.45,.55,.5+.1*(L-1),5,0)
        wings(-.3,st-.15,-1.3,1.25,up)
        halo(-.3,st+.4,-1.3,.42,up)
        k.c('ClockTower',.25,1.0,{1.35,floor+.5,-1.35},ivory);float(k.lit(k.ball('ShrineOrb',.26,{1.35,floor+1.2,-1.35},lamp),.1),{offset=1})
        if L>=2 then k.c('TankWagon',.22,1.2,{1.05,floor+.42,-.2},ivory,ANG(0,0,PI/2));G2(k.c('TankBand',.23,.1,{1.05,floor+.42,-.2},gold,ANG(0,0,PI/2)))
            k.b('ShuntEngine',{.8,.44,.5},{-.15,floor+.34,-.2},marble,nil,'armor')end
        feathers(.2,-.8,floor+.4,1.1,5,2.0)
    elseif kind=='MissileSilo'then
        well2(k,gold,deep,ivory,gold,gold,true)
        k.missiles(C(250,248,255),pink:Lerp(C(255,255,255),.3))
        local pt=temple('ServiceTower',-1.3,-.6,floor+.3,.42,1.6+.2*(L-1),4,0)
        wings(0,floor+3.3,0,1.55,up)
        halo(0,floor+3.75,0,.6,up)
        for i,c in ipairs({{1.45,.6},{1.1,-1.3}})do k.c('Turret',.2,.75,{c[1],floor+.375,c[2]},ivory);float(k.lit(k.ball('TurretOrb',.2,{c[1],floor+1.0,c[2]},lamp),.1),{offset=i})end
        k.opt(2,function()k.flag(-.4,1.5,floor,1.4,gold,k.owner,true)end)
        feathers(0,0,floor+.4,1.1,6,pt-floor)
    elseif kind=='SAMLauncher'then
        k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},marble,nil,'armor')
        G2(k.b('ChassisTrim',{1.99,.06,1.59},{.5,floor+.36,.5},gold))
        G2(k.c('Turntable',.5,.16,{.5,floor+.44,.5},gold))
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),deep,ivory,gold,MAT.Metal)
        k.c('RadarCabin',.5,.5,{-1.05,floor+.25,-.95},marble)
        local ct=temple('CabinTemple',-1.05,-.95,floor+.55,.5,.4,4,0)
        G2(k.rod('RadarMast',{-1.05,ct,-.95},{-1.05,ct+.55,-.95},.07,gold))
        dish(k,-1.05,ct+.75,-.95,ivory,.2).Material=MAT.Metal
        wings(-1.05,ct-.25,-.95,1.25,up)
        halo(.5,floor+2.3,.5,.5,up)
        k.flag(1.75,1.5,floor,1.2,gold,k.owner,true)
        feathers(-.2,-.2,floor+.4,1.2,6,2.0)
    end
end
local function server(k,kind)
    local black,cyan,mag=k.P,k.S,k.A;local L,d=k.l,k.d
    local panel=C(20,24,34);local dim=C(30,90,110);local holo=C(110,230,255)
    k.lot(kind,C(16,18,26),C(28,32,44),MAT.Slate,MAT.Glass)
    local function rackMat(p)p.Material=MAT.Glass;p.Reflectance=.3;return p end
    local function rack(name,x,z,y,w,h,dd,rows)
        rackMat(k.b(name,{w,h,dd},{x,y+h/2,z},black,nil,'armor'))
        rows=d and rows or math.max(1,math.ceil(rows/2))
        for i=1,rows do local c=i%3==0 and mag or cyan
            k.move(k.lit(k.b('LedRow',{w+.02,.04,dd+.02},{x,y+h*i/(rows+1),z},c),.1),{fn=breathe(5+i,.05,.5,i*1.3)})end
        k.opt(1,function()k.glass(k.b('HoloShell',{w+.14,h+.08,dd+.14},{x,y+h/2+.02,z},holo),.82,.2)end)
        return y+h
    end
    local function grid(x,z,y,w,dd)
        local n=d and 4 or 3
        for i=1,n do local f=(i-.5)/n-.5
            k.move(k.lit(k.b('WireX',{w,.03,.03},{x,y,z+f*dd},cyan),.05),{fn=breathe(3,.0,.35,i)})
            k.move(k.lit(k.b('WireZ',{.03,.03,dd},{x+f*w,y,z},cyan),.05),{phase=2,fn=breathe(3,.0,.35,i+5)})
        end
        for _,s in ipairs({-1,1})do local len=math.sqrt(w*w+dd*dd)
            k.move(k.lit(k.b('WireDiag',{.03,.03,len},CF(x,y+.01,z)*ANG(0,s*math.atan2(w,dd),0),mag),.1),{phase=3})end
        k.move(k.lit(k.b('GridNode',{.1,.1,.1},{x,y+.03,z},C(240,255,255))),{fn=glitch(3,.06)})
    end
    local function pixels(x,z,y,R,n,seed)
        for i=1,n do local a=i*2.5+seed;local px,pz=x+math.cos(a)*R*(.5+.12*i%3),z+math.sin(a)*R*(.5+.12*i%3)
            local s=.12+.05*(i%3)
            k.move(k.lit(k.b('Pixel',{s,s,s},{px,y+.15*(i%4),pz},i%2==0 and cyan or holo),.05),{fn=glitch(seed+i,.08)})
            local function ghost()k.move(k.lit(k.b('PixelGhost',{s,s,s},{px+.05,y+.15*(i%4),pz-.04},mag),.45),{phase=2,fn=glitch(seed+i+40,.1)})end
            if i>2 then k.opt(3,ghost)else ghost()end
        end
    end
    local function chunk(x,z,y,w,h,dd,seed)
        k.move(k.glass(k.b('ChunkCyan',{w,h,dd},{x,y,z},cyan),.55,.1),{phase=2,fn=glitch(seed,.07)})
        k.move(k.glass(k.b('ChunkMagenta',{w,h,dd},{x,y,z},mag),.6,.1),{phase=2,fn=glitch(seed+9,.07)})
    end
    local function wire(x,z,y,w,h,dd)
        local e=.035
        for _,s in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            k.move(k.lit(k.b('Wireframe',{e,h,e},{x+s[1]*w/2,y+h/2,z+s[2]*dd/2},cyan),.05),{phase=3,fn=glitch(s[1]*3+s[2],.04)})
        end
        for _,yy in ipairs({y+h})do for _,s in ipairs({-1,1})do
            k.move(k.lit(k.b('Wireframe',{w,e,e},{x,yy,z+s*dd/2},cyan),.05),{phase=3})
            k.move(k.lit(k.b('Wireframe',{e,e,dd},{x+s*w/2,yy,z},cyan),.05),{phase=3})
        end end
    end
    local function code(x,z,y,h,n,seed)
        for i=1,n do local ox=(hash(seed+i)-.5)*.5
            local function make()k.move(k.lit(k.b('CodeBlock',{.18,.06,.04},{x+ox,y,z},i%2==0 and mag or cyan),.1),{phase=3,fn=slide(V3(0,1,0),h,.7+.15*i),offset=i*.7})end
            if i>2 then k.opt(3,make)else make()end
        end
    end
    local function core(x,y,z,R)
        local c=k.lit(k.ball('DataCore',R,{x,y,z},holo));k.move(c,{bob=.05,fn=glitch(77,.03)});k.light(c,cyan,10,1.2)
        local scan=k.lit(k.c('ScanDisc',R*1.6,.02,{x,y,z},cyan),.5);scan.CastShadow=false
        k.move(scan,{fn=function(t)local yy=math.sin(t*2.4)*R*.6;return CF(0,yy,0),.4+.3*math.abs(math.sin(t*2.4))end})
    end
    if kind=='City'then
        local H=2.0+.45*(L-1);local tx,tz=-.4,-.4
        local top=rack('TowerBlock1',tx,tz,floor,1.2,H,1.1,5)
        grid(tx,tz,top+.04,1.2,1.1)
        core(tx,top+.7,tz,.4)
        k.b('TowerCrown',{.5,.12,.5},{tx,top+.06,tz},panel,nil,'armor')
        pixels(tx,tz,top+.25,1.0,5,1)
        chunk(tx+.35,tz+.3,floor+H*.6,.5,.4,.5,2)
        wire(tx,tz,floor,1.36,H+.1,1.26)
        code(tx,tz+.6,floor+.2,H,4,3)
        local h2=1.1+.3*(L-1)
        local t2=rack('TowerBlock2',1.05,-1.0,floor,.7,h2,.7,3)
        grid(1.05,-1.0,t2+.03,.7,.7)
        if L>=2 then rack('TowerBlock3',1.0,.85,floor,.6,.8+.2*(L-2),.6,2)end
        k.flag(-1.6,1.45,floor,1.0,panel,k.owner,true)
        k.opt(2,function()k.lit(k.b('FloorTrace',{2.4,.02,.04},{0,floor+.02,1.5},cyan),.2)end)
    elseif kind=='DefensePost'then
        local h=.62+.16*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            rackMat(k.b('Wall',{s-.95,h,.4},CF(0,floor+h/2,0)*f,black,nil,'armor'))
            k.dopt(1,function()k.move(k.lit(k.b('WallSeam',{s-.95,.05,.42},CF(0,floor+h*.7,0)*f,cyan),.1),{fn=breathe(4,.05,.5,side)})end)
        end end
        for i,c in ipairs(corners)do rack('Bastion',c[1]*1.5,c[2]*1.5,floor,.5,h+.5,.5,2)end
        local keep=1.0+.25*(L-1)
        local top=rack('BunkerCore',0,0,floor,1.0,keep,1.0,3)
        grid(0,0,top+.04,1.0,1.0)
        core(0,top+.6,0,.36)
        k.b('TurretHead',{.45,.12,.45},{0,top+.06,0},panel,nil,'armor')
        pixels(0,0,top+.25,1.1,5,11)
        chunk(.3,.25,floor+keep*.6,.45,.35,.45,12)
        wire(0,0,floor,1.16,keep+.1,1.16)
        code(0,.55,floor+.2,keep,3,13)
        k.flag(1.5,1.5,floor+h+.5,.9,panel,k.owner,true)
        if L>=2 then for _,x in ipairs({-.55,.55})do rack('Gatehouse',x,s/2-.22,floor,.3,h+.3,.36,1)end end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(14,40,64))
        for _,s in ipairs({-1,1})do rackMat(k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},black,nil,'armor'));k.dopt(1,function()k.lit(k.b('PierGlow',{.05,.03,2.4},{s*1.72,.27,.95},cyan),.1)end)end
        local top=gantry(k,panel,black,panel,cyan,2.3+.25*(L-1))
        rackMat(k.b('Hull',{2.4,.38,.82},{-.15,.25,1.15},black,nil,'armor'))
        k.w('Bow',{.82,.38,.6},{1.4,.25,1.15},black,ANG(0,-PI/2,0))
        k.move(k.lit(k.b('HullGlow',{2.44,.04,.84},{-.15,.42,1.15},cyan),.1),{fn=breathe(3,.05,.5)})
        for i,x in ipairs({-.6,.35})do local mh=1.3+(i==2 and .2 or 0)
            k.rod('Mast',{x,.44,1.15},{x,.44+mh,1.15},.04,panel)
            k.move(k.b('Sail',{.06,mh*.6,.9},{x+.03,.44+mh*.55,1.15},k.owner,nil,'soft'),{sway=.04,pivot=V3(0,mh*.3,0),axisX=true})
        end
        local lx,lz=1.5,-1.55
        local lt=rack('Lighthouse',lx,lz,floor,.6,1.9+.25*(L-1),.6,4)
        grid(lx,lz,lt+.03,.6,.6)
        core(lx,lt+.5,lz,.32)
        pixels(lx,lz,lt+.2,.7,4,21)
        chunk(lx+.2,lz+.2,floor+1.0,.35,.35,.35,22)
        wire(lx,lz,floor,.74,2.0+.25*(L-1),.74)
        code(lx-.4,lz,floor+.2,1.8,3,23)
        k.opt(2,function()k.move(k.lit(k.b('DataWave',{.04,.03,2.2},{-1.5,.08,.95},cyan),.3),{fn=slide(V3(1,0,0),3.0,.8)})end)
    elseif kind=='Factory'then
        rails(k,C(20,24,34),cyan,true)
        for _,z in ipairs({-.85,1.6})do rackMat(k.b('ExitGatePost',{.3,1.3,.3},{2.12,floor+.65,z},black,nil,'armor'))end
        rackMat(k.b('ExitGate',{.4,.2,2.6},{2.12,floor+1.35,.375},black,nil,'armor'))
        k.lit(k.b('GateSeam',{.42,.04,2.62},{2.12,floor+1.46,.375},cyan),.05)
        k.b('ExitGateBand',{.42,.12,1.6},{2.12,floor+1.15,.375},k.owner)
        core(2.12,floor+1.95,.375,.32)
        rackMat(k.b('Locomotive',{1.4,.46,.58},{.55,floor+.4,.95},black,nil,'armor'))
        k.w('LocoNose',{.58,.42,.5},{1.5,floor+.37,.95},black,ANG(0,-PI/2,0))
        k.move(k.lit(k.b('LocoStripe',{1.42,.05,.6},{.55,floor+.5,.95},cyan),.05),{fn=breathe(4,.05,.4)})
        k.b('TrainCab',{.5,.28,.58},{.05,floor+.76,.95},panel,nil,'armor')
        for i,x in ipairs({-.85,-1.95})do rackMat(k.b('CargoWagon',{1.0,.44,.56},{x,floor+.38,.95},black,nil,'armor'))
            k.opt(1,function()k.lit(k.b('WagonLed',{1.02,.04,.58},{x,floor+.5,.95},i==1 and mag or cyan),.1)end)end
        k.b('Platform',{3.6,.2,.6},{0,floor+.1,-1.05},panel,nil,'armor')
        local st=rack('StationHall',-.3,-1.35,floor+.2,1.4,.7+.15*(L-1),.6,2)
        grid(-.3,-1.35,st+.03,1.4,.6)
        pixels(-.3,-1.35,st+.2,.8,5,31)
        chunk(.1,-1.2,floor+.6,.5,.3,.4,32)
        wire(-.3,-1.35,floor+.2,1.54,.8+.15*(L-1),.74)
        code(1.3,-1.35,floor+.2,1.3,3,33)
        rack('ClockTower',1.3,-1.4,floor+.2,.4,1.1+.2*(L-1),.4,2)
        if L>=2 then rackMat(k.c('TankWagon',.22,1.2,{1.05,floor+.42,-.2},black,ANG(0,0,PI/2)));k.lit(k.c('TankBand',.23,.06,{1.05,floor+.42,-.2},cyan,ANG(0,0,PI/2)),.1)
            rackMat(k.b('ShuntEngine',{.8,.44,.5},{-.15,floor+.34,-.2},black,nil,'armor'))end
    elseif kind=='MissileSilo'then
        well2(k,cyan,panel,black,mag,panel,true)
        k.missiles(C(30,34,46),cyan)
        local st=rack('ServiceTower',-1.32,-.6,floor,.55,2.4+.2*(L-1),.55,4)
        grid(-1.32,-.6,st+.03,.55,.55)
        core(-1.32,st+.5,-.6,.3)
        pixels(0,0,floor+3.0,1.0,5,41)
        chunk(-1.15,-.45,floor+1.3,.35,.4,.35,42)
        wire(-1.32,-.6,floor,.68,2.5+.2*(L-1),.68)
        code(1.3,.5,floor+.2,2.2,4,43)
        for _,c in ipairs({{1.45,.6},{1.1,-1.3}})do rack('Turret',c[1],c[2],floor,.3,.75,.3,1)end
        k.opt(2,function()k.flag(-.4,1.5,floor,1.4,panel,k.owner,true)end)
        grid(0,-.1,floor+.12,2.0,2.0)
    elseif kind=='SAMLauncher'then
        rackMat(k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},black,nil,'armor'))
        k.lit(k.b('ChassisSeam',{1.97,.04,1.57},{.5,floor+.3,.5},cyan),.05)
        k.c('Turntable',.5,.16,{.5,floor+.44,.5},panel)
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),black,panel,cyan)
        local ct=rack('RadarCabin',-1.05,-.95,floor,.8,.8,.7,2)
        grid(-1.05,-.95,ct+.03,.8,.7)
        k.rod('RadarMast',{-1.05,ct,-.95},{-1.05,ct+.6,-.95},.07,panel)
        dish(k,-1.05,ct+.8,-.95,panel,.2)
        core(.5,floor+2.2,.5,.3)
        pixels(.5,.5,floor+2.0,.9,5,51)
        chunk(-.85,-.8,floor+.5,.4,.35,.4,52)
        wire(-1.05,-.95,floor,.94,.9,.84)
        code(1.6,-1.4,floor+.2,1.6,3,53)
        rack('Turret',1.6,-1.45,floor,.32,1.0,.32,2)
        k.flag(1.75,1.5,floor,1.2,panel,k.owner,true)
    end
end
local function deeptemple(k,kind)
    local navy,teal,violet=k.P,k.S,k.A;local L,d=k.l,k.d
    local stone=navy:Lerp(C(40,64,92),.45);local skin=C(40,58,96);local deep=C(4,12,22);local foam=C(190,255,246)
    local function wet(p)p.Material=MAT.Glass;p.Reflectance=.25;return p end
    k.lot(kind,C(18,30,46),C(30,46,66),MAT.Slate,MAT.Slate)
    local function shrine(name,x,z,y,w,h)
        k.mat(k.b(name,{w,h,w},{x,y+h/2,z},stone,nil,'armor'),MAT.Slate)
        k.dopt(1,function()k.move(k.lit(k.b('GlowSeam',{w+.02,.05,w+.02},{x,y+h*.7,z},teal),.1),{fn=breathe(1.3,.05,.5,x)})end)
        k.mat(k.b('Capstone',{w+.16,.1,w+.16},{x,y+h+.05,z},deep,nil,'armor'),MAT.Slate)
        return y+h+.1
    end
    local function tentacle(root,yaw,len,rise0,curl,n,spec,i)
        local base=CF(root)*ANG(0,yaw,0)
        for j=0,n-1 do local f=j/(n-1);local r=.2*(1-.6*f)
            local pos=base*V3(0,rise0*math.sin(f*PI*.6),-len*f+curl*f*f)
            local s=table.clone(spec);s.offset=(i or 0)+j*.35
            k.move(wet(k.ball('Tentacle',r*2,{pos.X,pos.Y,pos.Z},j%2==0 and skin or skin:Lerp(violet,.25))),s)
            if j%2==1 then k.opt(2,function()local q=table.clone(s);k.move(k.lit(k.ball('Sucker',r*.7,{pos.X,pos.Y+r*.8,pos.Z},teal),.15),q)end)end
        end
    end
    local function water(x,z,R)
        local w=k.glass(k.c('Water',R,.06,{x,floor+.05,z},teal:Lerp(navy,.4)),.55,.2)
        k.move(w,{fn=breathe(1.1,.45,.65)})
        for i=1,3 do local function rip()k.move(k.lit(k.c('Ripple',R*(.45+.18*i),.02,{x,floor+.09,z},teal),.4),{fn=breathe(2,.35,1,-i*1.4)})end
            if i==3 then k.opt(2,rip)else rip()end end
        for _,s in ipairs({-1,1})do
            k.move(k.lit(k.ball('DeepEye',.16,{x+s*.32+R*.45,floor+.02,z+R*.35},violet)),{fn=breathe(.9,.05,.7,s)})
        end
    end
    local function ring(x,z,y,R,n,lift)
        local axis=CF(x,y,z)
        n=d and n or math.ceil(n*.7)
        for i=0,n-1 do local a=i/n*PI*2
            local root=axis*ANG(0,a,0)*CF(0,0,-R)
            tentacle(root.Position,a+PI,R*.8,.55,-.25,4,{phase=2,axis=axis,spin=.15,bob=.05,freq=1.8,lift=lift},i)
        end
    end
    local function eye(x,y,z,R,lift)
        local sp={phase=3,lift=lift}
        local sc=k.lit(k.c('EyeSclera',R,.05,{x,y,z},foam:Lerp(teal,.35)),.05);k.move(sc,table.clone(sp));k.light(sc,teal,10,1.2)
        k.move(k.lit(k.c('EyeIris',R*.62,.06,{x,y+.01,z},violet)),table.clone(sp))
        k.move(k.b('EyePupil',{R*.18,.08,R*.9},{x,y+.03,z},deep),{phase=3,lift=lift,fn=function(t)return CF(math.sin(t*.7)*R*.18,0,0),nil end})
        for _,s in ipairs({-1,1})do
            k.move(wet(k.b('EyeLid',{R*2.1,.08,R*1.05},{x,y+.06,z+s*R*.55},skin,nil,'soft')),{phase=3,lift=lift,fn=function(t)
                local b=math.max(0,math.sin(t*.9))^24;return CF(0,0,-s*R*.5*b),nil end})
        end
        k.move(k.lit(k.c('EyeGlow',R*1.35,.02,{x,y-.02,z},violet),.6),{phase=3,lift=lift,fn=breathe(1.2,.45,.8)})
    end
    local function motes(x,z,y,R,n,h)
        for i=1,n do local a=i*2.4;local function make()k.move(k.lit(k.ball('Biolume',.08,{x+math.cos(a)*R,y,z+math.sin(a)*R},i%2==0 and teal or violet),.2),{fn=rise(h,.4+.06*i),offset=i*1.2})end
            if i>3 then k.opt(3,make)else make()end end
    end
    local function wraps(x,z,R,n)
        for i=0,n-1 do local a=i/n*PI*2+.4
            tentacle(V3(x+math.cos(a)*R,floor+.1,z+math.sin(a)*R),-a-PI/2,R*1.0,.35,.2,d and 4 or 3,{bob=.03,freq=1.2},i)
        end
    end
    local up=V3(0,.06,0)
    if kind=='City'then
        local tx,tz=-.35,-.4
        water(tx,tz,1.7)
        local y=shrine('TowerBlock1',tx,tz,floor,1.3,.8+.15*(L-1))
        y=shrine('TowerStep',tx,tz,y,1.0,.6+.15*(L-1))
        y=shrine('TowerCrown',tx,tz,y,.75,.4)
        wraps(tx,tz,.75,3)
        ring(tx,tz,y,.62,5,up)
        eye(tx,y+.08,tz,.42,up)
        shrine('TowerBlock2',1.1,-1.15,floor,.6,.8+.25*(L-1))
        if L>=2 then shrine('TowerBlock3',1.05,.9,floor,.5,.6+.2*(L-2))end
        k.flag(-1.6,1.45,floor,1.0,stone,k.owner,true)
        motes(tx,tz,floor+.2,1.2,5,2.4)
    elseif kind=='DefensePost'then
        local h=.62+.16*(L-1);local s=3.3
        water(0,0,1.3)
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.22))
            k.mat(k.b('Wall',{s-.95,h,.4},CF(0,floor+h/2,0)*f,stone,nil,'armor'),MAT.Slate)
            k.dopt(1,function()k.lit(k.b('WallSeam',{s-.95,.05,.42},CF(0,floor+h*.7,0)*f,teal),.15)end)
        end end
        for i,c in ipairs(corners)do shrine('Bastion',c[1]*1.5,c[2]*1.5,floor,.48,h+.4)end
        local y=shrine('BunkerCore',0,0,floor,1.0,.8+.2*(L-1))
        y=shrine('TurretHead',0,0,y,.7,.35)
        wraps(0,0,.55,3)
        ring(0,0,y,.55,5,up)
        eye(0,y+.08,0,.38,up)
        k.flag(1.5,1.5,floor+h+.4,.9,stone,k.owner,true)
        if L>=2 then for _,x in ipairs({-.55,.55})do shrine('Gatehouse',x,s/2-.22,floor,.3,h+.25)end end
        motes(0,0,floor+.2,1.1,5,2.0)
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(10,40,70))
        for _,s in ipairs({-1,1})do k.mat(k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},stone,nil,'armor'),MAT.Slate)end
        for i,s in ipairs({-1,1})do local function crash()
            k.move(k.lit(k.b('WaveCrest',{.08,.12,2.2},{s*.9,.14,.95},foam),.3),{fn=slide(V3(s*.75,0,0),.85,.5+.1*i)})end
            crash();k.opt(2,function()k.move(k.lit(k.b('Spray',{.1,.18,.4},{s*1.68,.34,.6+.5*i},foam),.4),{fn=breathe(2.6,.2,1,i*2)})end)
        end
        local top=gantry(k,stone,deep,stone,teal,2.3+.25*(L-1))
        wet(k.b('Hull',{2.4,.38,.82},{-.15,.25,1.15},skin,nil,'armor'))
        k.w('Bow',{.82,.38,.6},{1.4,.25,1.15},skin,ANG(0,-PI/2,0))
        k.lit(k.b('HullGlow',{2.44,.04,.84},{-.15,.42,1.15},teal),.15)
        for i,x in ipairs({-.6,.35})do local mh=1.3+(i==2 and .2 or 0)
            k.rod('Mast',{x,.44,1.15},{x,.44+mh,1.15},.04,stone)
            k.move(k.b('Sail',{.06,mh*.6,.9},{x+.03,.44+mh*.55,1.15},k.owner,nil,'soft'),{sway=.04,pivot=V3(0,mh*.3,0),axisX=true})
        end
        tentacle(V3(-1.5,.1,1.7),PI*.6,1.0,.6,.3,d and 5 or 4,{bob=.04,freq=1.4},1)
        local lx,lz=1.5,-1.55
        local y=shrine('Lighthouse',lx,lz,floor,.6,1.6+.25*(L-1))
        y=shrine('LighthouseCap',lx,lz,y,.45,.3)
        ring(lx,lz,y,.42,4,up)
        eye(lx,y+.08,lz,.3,up)
        local beacon=k.lit(k.ball('DeepEye',.18,{lx+.32,floor+.8,lz+.32},violet));k.move(beacon,{fn=breathe(.9,.05,.6)})
        motes(lx,lz,floor+.2,.7,4,2.0)
    elseif kind=='Factory'then
        rails(k,C(20,32,46),teal,true)
        for _,z in ipairs({-.85,1.6})do k.mat(k.b('ExitGatePost',{.3,1.3,.3},{2.12,floor+.65,z},stone,nil,'armor'),MAT.Slate)end
        k.mat(k.b('ExitGate',{.4,.2,2.6},{2.12,floor+1.35,.375},stone,nil,'armor'),MAT.Slate)
        k.lit(k.b('GateSeam',{.42,.04,2.62},{2.12,floor+1.46,.375},teal),.1)
        k.b('ExitGateBand',{.42,.12,1.6},{2.12,floor+1.15,.375},k.owner)
        tentacle(V3(2.12,floor+.1,1.75),PI,.9,1.3,.4,d and 5 or 4,{bob=.04,freq=1.3},2)
        wet(k.b('Locomotive',{1.4,.46,.58},{.55,floor+.4,.95},skin,nil,'armor'))
        k.w('LocoNose',{.58,.42,.5},{1.5,floor+.37,.95},skin,ANG(0,-PI/2,0))
        k.lit(k.b('LocoStripe',{1.42,.05,.6},{.55,floor+.5,.95},teal),.1)
        k.b('TrainCab',{.5,.28,.58},{.05,floor+.76,.95},stone,nil,'armor')
        for _,x in ipairs({-.85,-1.95})do k.mat(k.b('CargoWagon',{1.0,.44,.56},{x,floor+.38,.95},stone,nil,'armor'),MAT.Slate)
            k.opt(1,function()k.lit(k.b('WagonGlow',{1.02,.04,.58},{x,floor+.5,.95},teal),.2)end)end
        k.b('Platform',{3.6,.2,.6},{0,floor+.1,-1.05},stone,nil,'armor')
        water(-.3,-1.35,1.0)
        local y=shrine('StationHall',-.3,-1.35,floor+.2,.9,.7+.15*(L-1))
        ring(-.3,-1.35,y,.45,4,up)
        eye(-.3,y+.08,-1.35,.32,up)
        shrine('ClockTower',1.3,-1.4,floor+.2,.42,1.0+.2*(L-1))
        if L>=2 then k.c('TankWagon',.22,1.2,{1.05,floor+.42,-.2},skin,ANG(0,0,PI/2));k.lit(k.c('TankBand',.23,.06,{1.05,floor+.42,-.2},teal,ANG(0,0,PI/2)),.1)
            k.b('ShuntEngine',{.8,.44,.5},{-.15,floor+.34,-.2},stone,nil,'armor')end
        motes(-.3,-1.35,floor+.3,.8,4,1.8)
    elseif kind=='MissileSilo'then
        well2(k,teal,deep,stone,violet,stone,true)
        k.missiles(C(214,236,240),violet)
        water(0,0,1.3)
        wraps(0,0,1.15,4)
        ring(0,0,floor+1.2,1.05,5,up)
        local y=shrine('ServiceTower',-1.32,-.6,floor,.55,2.3+.2*(L-1))
        eye(-1.32,y+.08,-.6,.3,up)
        for _,c in ipairs({{1.45,.6},{1.1,-1.3}})do shrine('Turret',c[1],c[2],floor,.3,.7)end
        k.opt(2,function()k.flag(-.4,1.5,floor,1.4,stone,k.owner,true)end)
        motes(0,0,floor+.3,1.0,5,2.4)
    elseif kind=='SAMLauncher'then
        wet(k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},skin,nil,'armor'))
        k.lit(k.b('ChassisSeam',{1.97,.04,1.57},{.5,floor+.3,.5},teal),.1)
        k.c('Turntable',.5,.16,{.5,floor+.44,.5},stone)
        launcher(k,CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0),stone,skin,teal)
        water(-1.05,-.95,1.0)
        local cy=shrine('RadarCabin',-1.05,-.95,floor,.8,.75)
        k.rod('RadarMast',{-1.05,cy,-.95},{-1.05,cy+.6,-.95},.07,stone)
        dish(k,-1.05,cy+.8,-.95,stone,.2)
        ring(-1.05,-.95,cy,.5,4,up)
        local ty=shrine('Turret',1.55,-1.4,floor,.5,1.0)
        eye(1.55,ty+.08,-1.4,.3,up)
        tentacle(V3(1.75,floor+.1,1.4),PI*1.2,.9,.8,.3,d and 4 or 3,{bob=.04,freq=1.3},3)
        k.flag(1.75,1.5,floor,1.2,stone,k.owner,true)
        motes(-.2,-.2,floor+.3,1.1,5,2.0)
    end
end
local themes={{'pagoda',4,pagoda},{'crystal',4,crystal},{'sanctum',5,sanctum},{'server',5,server},{'deeptemple',5,deeptemple}}
function M.register(themeTable,motionTable,kitFn)
    T,kit=themeTable,kitFn
    for _,t in ipairs(themes)do
        local key,grade,build=t[1],t[2],t[3]
        themeTable[key]=function(k,kind)
            build(extend(k),kind)
            if grade==4 then fit(k,refCount('orbital',kind,k.l,k.d)-1)else fit(k,refCount('monolith',kind,k.l,k.d)+10)end
        end
        motionTable[key]=grade==4 and 3 or 4
    end
end
return M
