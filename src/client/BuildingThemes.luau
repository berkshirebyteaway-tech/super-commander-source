local G=require(script.Parent.ToyGeometry)
local M={};local states=setmetatable({},{__mode='k'})
local V3,CF,ANG=Vector3.new,CFrame.new,CFrame.Angles
local MAT=Enum.Material
local PI=math.pi
local function rgb(a)return Color3.fromRGB(table.unpack(a))end
local C=Color3.fromRGB
local ice=C(211,223,235);local warm=C(255,206,128);local well=C(12,16,22);local steel=C(172,184,198)
local floor=.31
local fronts={Port=-.25,MissileSilo=1.72}
local function kit(model,style,level,detailed,owner)
    local k={m=model,l=level,d=detailed,owner=owner,tier=style.tier or 0,P=rgb(style.primary),S=rgb(style.secondary),A=rgb(style.accent),items={}}
    local function frame(pos,rot)return (type(pos)=='table'and pos[1]~=nil and CF(pos[1],pos[2],pos[3])or pos)*(rot or CFrame.identity)end
    k.frame=frame
    function k.b(name,size,pos,color,rot,shape)
        local s=V3(size[1],size[2],size[3]);local f=frame(pos,rot)
        if shape then return G.part(model,name,s,f,color,shape)end
        return G.block(model,name,s,f,color)
    end
    function k.w(name,size,pos,color,rot)
        local p=Instance.new('WedgePart');p.Name=name;p.Size=V3(size[1],size[2],size[3]);p.CFrame=frame(pos,rot);p.Color=color
        p.Material=MAT.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=model;return p
    end
    function k.gable(name,size,pos,color,rot)
        local f=frame(pos,rot);local w,h,d=size[1],size[2],size[3]
        k.w(name,{w,h,d/2},f*CF(0,0,-d/4),color);k.w(name,{w,h,d/2},f*CF(0,0,d/4)*ANG(0,PI,0),color)
    end
    function k.c(name,r,h,pos,color,rot)return G.cylinder(model,name,r,h,frame(pos,rot),color)end
    function k.ball(name,d,pos,color)return G.ball(model,name,V3(d,d,d),frame(pos),color)end
    function k.dome(name,size,pos,color)
        local p=G.block(model,name,V3(size[1],size[2],size[3]),frame(pos),color)
        local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p;return p
    end
    function k.rod(name,a,c,r,color)return G.rod(model,name,V3(a[1],a[2],a[3]),V3(c[1],c[2],c[3]),r,color)end
    function k.beam(name,a,c,w,h,color,shape)
        local pa,pc=V3(a[1],a[2],a[3]),V3(c[1],c[2],c[3])
        return k.b(name,{w,h,(pc-pa).Magnitude},CFrame.lookAt((pa+pc)/2,pc),color,nil,shape)
    end
    function k.mat(p,m,r)p.Material=m;p.Reflectance=r or 0;return p end
    function k.fade(p,t)p.Transparency=t;p:SetAttribute('BaseTransparency',t);return p end
    function k.lit(p,t)p.Material=MAT.Neon;p.CastShadow=false;if t then k.fade(p,t)end;return p end
    function k.gold(p)p.Material=MAT.Metal;p.Reflectance=.12;return p end
    function k.move(p,spec)local s=table.clone(spec);s.part=p;s.home=p.CFrame;s.color=p.Color;table.insert(k.items,s);return p end
    function k.ring(name,center,R,n,h,t,color,spec,fill)
        local out={}
        for i=0,n-1 do
            local p=k.b(name,{2*PI*R/n*(fill or .72),h,t},center*ANG(0,i/n*PI*2,0)*CF(0,0,-R),color)
            if spec then local s=table.clone(spec);s.axis=s.axis or center;k.move(p,s)end
            table.insert(out,p)
        end
        return out
    end
    function k.light(p,color,range,bright)
        local l=Instance.new('PointLight');l.Name='CollectionLight';l.Color=color;l.Range=range or 6;l.Brightness=bright or .8;l.Shadows=false;l.Parent=p;k.lamp=l;return l
    end
    function k.lot(kind,pad,top,padMat,topMat)
        G.shadow(model,0,0,2.25).Color=C(22,29,38)
        local p,t
        if kind=='MissileSilo'then p=k.c('ConcretePad',2.05,.26,{0,.13,0},pad);t=k.c('PadTop',1.88,.05,{0,.285,0},top)
        elseif kind=='Port'then p=k.b('ConcretePad',{4.3,.3,1.9},{0,.15,-1.2},pad,nil,'armor');t=k.b('PadTop',{4.1,.05,1.72},{0,.305,-1.2},top,nil,'board')
        else p=k.b('ConcretePad',{4.2,.26,4.2},{0,.13,0},pad,nil,'armor');t=k.b('PadTop',{3.86,.05,3.86},{0,.285,0},top,nil,'board')end
        p.Material=padMat or MAT.Concrete;if topMat then t.Material=topMat end
        local front=fronts[kind]or 2.02;k.front=front
        k.b('OwnerBand',{kind=='MissileSilo'and 1.5 or 2.3,.1,.12},{0,.29,front+.03},owner)
        local beacon=k.b('StatusBeacon',{.34,.08,.18},{kind=='MissileSilo'and -1.0 or -1.6,.33,front-.1},ice);beacon.Material=MAT.Neon;beacon.Transparency=.08
        if level>=2 then k.b('LevelStripe',{.36+.22*(level-2),.07,.13},{kind=='MissileSilo'and 1.0 or 1.36,.33,front-.1},C(245,196,81))end
        return p,t
    end
    function k.missiles(body,nose,y0,spec)
        local L=k.l;local spots=L==1 and {{0,0}}or L==2 and {{-.5,.05},{.5,.05}}or {{-.56,.32},{.56,.32},{0,-.6}}
        local r=L==1 and .34 or .29;local len=L==1 and 2.75 or 2.45;y0=y0 or floor+.3
        for i,s in ipairs(spots)do
            local x,z=s[1],s[2];local suffix=i==1 and ''or tostring(i)
            local parts={k.c('Missile'..suffix,r,len,{x,y0+len/2,z},body),k.ball('MissileNose'..suffix,r*2,{x,y0+len,z},nose)}
            if k.d then table.insert(parts,k.rod('MissileTip'..suffix,{x,y0+len+r*.55,z},{x,y0+len+r*1.8,z},.065,nose))end
            for _,p in ipairs(parts)do p:SetAttribute('ReadyColor',p.Color)end
            table.insert(parts,k.c('MissileBand',r+.008,.24,{x,y0+len*.78,z},owner))
            if spec then for j,p in ipairs(parts)do local s2=table.clone(spec);s2.offset=i*1.3;k.move(p,s2)end end
        end
        return r,len
    end
    function k.flag(x,z,y,h,pole,cloth,motion)
        k.mat(k.rod('FlagPole',{x,y,z},{x,y+h,z},.045,pole),MAT.Metal)
        local f=k.b('Flag',{.86,.5,.05},{x+.45,y+h-.27,z},cloth)
        if motion then k.move(f,{sway=.08,pivot=V3(-.43,0,0)})end
        return f
    end
    return k
end
local T={}
local function tube(k,pack,x,y,body,cap,capT)
    local t=G.cylinder(k.m,'Tube',.21,1.6,pack*CF(x,y,0)*ANG(PI/2,0,0),body);t.Material=MAT.SmoothPlastic
    k.lit(G.cylinder(k.m,'MissileCap',.16,.04,pack*CF(x,y,.81)*ANG(PI/2,0,0),cap),capT or .1)
end
T.field=function(k,kind)
    local olive,canvas,amber=k.P:Lerp(k.S,.22),k.S:Lerp(C(236,228,190),.3),k.A;local L,d=k.l,k.d
    local timber=C(164,124,76);local bag=C(214,198,148);local dark=C(52,56,44);local net=C(104,130,70);local drab=C(156,164,114)
    k.lot(kind,C(128,114,84),C(176,160,118),MAT.Ground,MAT.Sand)
    local function bags(name,len,h,cf)
        k.b(name,{len,h*.55,.5},cf*CF(0,h*.275,0),bag,nil,'soft')
        if d then k.b(name,{len*.9,h*.48,.4},cf*CF(0,h*.55+h*.22,0),bag:Lerp(canvas,.25),nil,'soft')end
    end
    if kind=='City'then
        local H=2.3+.5*(L-1);local n=L+1;local y=floor
        for i=1,n do local h=H/n;local alt=i%2==0
            k.b('TowerBlock'..i,{1.36,h-.02,1.24},{-.6+(alt and .07 or 0),y+h/2,-.55},alt and drab or olive,ANG(0,alt and .07 or 0,0),'armor')
            if d then k.lit(k.b('Window',{.86,h*.24,.04},{-.6,y+h*.58,.08},warm))end
            k.b('HazardStripe',{1.38,.05,1.26},{-.6+(alt and .07 or 0),y+h-.04,-.55},alt and amber or dark,ANG(0,alt and .07 or 0,0))
            y+=h
        end
        if d then for _,s in ipairs({{-1,-1},{1,1},{-1,1},{1,-1}})do k.rod('LookoutPost',{-.6+s[1]*.5,y,-.55+s[2]*.45},{-.6+s[1]*.5,y+.55,-.55+s[2]*.45},.04,timber)end end
        k.gable('TowerCrown',{1.35,.42,1.2},{-.6,y+.55+.21,-.55},canvas)
        k.rod('Spire',{-.95,y+.6,-.85},{-.95,y+1.55,-.85},.035,dark)
        k.lit(k.ball('MastLamp',.14,{-.95,y+1.58,-.85},amber))
        local h2=.9+.3*(L-1)
        k.b('TowerBlock',{1.1,h2,.95},{.9,floor+h2/2,-.85},timber,nil,'armor')
        k.gable('BarracksRoof',{1.25,.5,1.1},{.9,floor+h2+.25,-.85},canvas)
        if d then k.lit(k.b('Window',{.7,.18,.04},{.9,floor+h2*.6,-.36},warm))end
        k.b('TentFloor',{1.3,.08,1.15},{.8,floor+.04,.82},timber,nil,'board')
        k.gable('Tent',{1.25,.95,1.1},{.8,floor+.08+.475,.82},canvas,ANG(0,PI/2,0))
        k.flag(.8,.82,floor+1.0,.7,timber,k.owner)
        if L>=2 then
            local th=1.1+.3*(L-2)
            if d then for _,s in ipairs({{-1,-1},{1,1},{-1,1},{1,-1}})do k.rod('TowerLeg',{-1.05+s[1]*.32,floor,1.05+s[2]*.32},{-1.05+s[1]*.22,floor+th,1.05+s[2]*.22},.045,timber)end
            else k.b('TowerLeg',{.3,th,.3},{-1.05,floor+th/2,1.05},timber)end
            k.c('WaterTank',.4,.6,{-1.05,floor+th+.3,1.05},olive)
            k.c('TankLid',.44,.08,{-1.05,floor+th+.64,1.05},dark)
        end
        if d then
            k.fade(k.b('CamoNet',{1.5,.05,1.5},{.45,floor+1.55+.3*(L-1),-.2},net,ANG(.12,.4,-.18)),.12)
            bags('Sandbags',1.3,.42,CF(-.95,floor,1.45))
        end
    elseif kind=='DefensePost'then
        local h=.62+.16*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do
            bags('Wall',s-1.05,h,CF(0,floor,side*(s/2-.25)))
            bags('Wall',s-1.05,h,CF(side*(s/2-.25),floor,0)*ANG(0,PI/2,0))
        end
        for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            k.c('Bastion',.56,h+.12,{c[1]*1.5,floor+(h+.12)/2,c[2]*1.5},bag:Lerp(canvas,.15))
            k.c('BastionPit',.38,.04,{c[1]*1.5,floor+h+.13,c[2]*1.5},dark)
        end
        local keep=.75+.2*(L-1)
        k.b('BunkerCore',{1.45,keep,1.45},{0,floor+keep/2,0},olive,nil,'armor')
        k.b('Firing slit',{1.0,.12,.04},{0,floor+keep*.65,.74},well)
        k.c('TurretHead',.42,.3,{0,floor+keep+.15,0},drab)
        k.rod('TurretBarrel',{0,floor+keep+.2,.2},{0,floor+keep+.26,1.05},.07,dark)
        if d then k.fade(k.b('CamoNet',{1.9,.05,1.7},{-.15,floor+keep+.36,-.25},net,ANG(.06,.35,-.1)),.1)end
        k.flag(-1.5,-1.5,floor+h+.12,1.6,timber,k.owner)
        if L>=2 then
            for _,x in ipairs({-.62,.62})do k.b('GatePost',{.16,h+.55,.16},{x,floor+(h+.55)/2,s/2-.25},timber)end
            k.b('GateBeam',{1.5,.16,.18},{0,floor+h+.5,s/2-.25},amber)
            if d then for _,x in ipairs({-.4,0,.4})do k.b('GateStripe',{.14,.17,.19},{x,floor+h+.5,s/2-.25},dark)end end
        end
        if L>=3 and d then for _,x in ipairs({-1.5,1.5})do k.rod('BastionBarrel',{x,floor+h+.2,1.5},{x+.45*math.sign(x),floor+h+.26,1.95},.05,dark)end end
        if d then
            k.b('Crate',{.42,.34,.42},{1.0,floor+.17,-.75},timber,ANG(0,.3,0),'armor')
            k.b('Crate',{.36,.3,.36},{.9,floor+.49,-.75},timber:Lerp(canvas,.2),ANG(0,.7,0),'armor')
        end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(40,92,108))
        for _,s in ipairs({-1,1})do k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},timber,nil,'armor')end
        k.c('CraneBase',.5,.3,{.2,floor+.15,-1.25},olive)
        k.b('CraneHouse',{.8,.55,.7},{.2,floor+.55,-1.4},olive,nil,'armor')
        k.b('CraneStripe',{.82,.1,.72},{.2,floor+.55,-1.4},amber)
        local pivot={.2,floor+.75,-1.05};local tip={.2,3.1+.2*(L-1),1.25}
        k.mat(k.beam('CraneBoom',pivot,tip,.28,.28,amber,'armor'),MAT.Metal)
        k.mat(k.rod('CraneMast',{.2,floor+.8,-1.6},{.2,2.0+.15*(L-1),-1.7},.08,amber),MAT.Metal)
        if d then
            k.rod('CraneCable',{.2,2.0+.15*(L-1),-1.7},tip,.025,dark)
            k.rod('CraneCable',tip,{.2,1.25,1.25},.025,dark)
        end
        k.b('CargoNet',{.5,.4,.5},{.2,1.05,1.25},canvas,nil,'soft')
        k.b('Hull',{2.6,.4,.95},{-.2,.25,1.15},olive,nil,'armor')
        k.w('BowRamp',{.95,.4,.45},{1.32,.25,1.15},olive,ANG(0,-PI/2,0))
        k.b('Bridge',{.48,.6,.7},{-1.2,.75,1.15},drab,nil,'armor')
        if d then k.b('BridgeWindow',{.5,.1,.5},{-1.2,.92,1.15},well)end
        k.b('Container',{.75,.36,.7},{-.55,.63,1.15},canvas,nil,'soft')
        if L>=2 then k.b('Container',{.6,.34,.66},{.3,.62,1.15},k.owner:Lerp(canvas,.35),nil,'armor')end
        if d then
            for i,x in ipairs({-1.55,-1.25})do k.c('FuelDrum',.15,.36,{x,floor+.18,-1.65+i*.05},olive)end
            k.b('QuayCargo',{.6,.4,.5},{1.45,floor+.2,-1.55},timber,nil,'armor')
        end
        if L>=3 then bags('Sandbags',1.2,.4,CF(-1.15,floor,-.6))end
    elseif kind=='Factory'then
        for _,z in ipairs({.95,-.2})do
            k.b('Ballast',{5.5,.06,.66},{.5,floor+.03,z},C(96,84,64))
            for _,s in ipairs({-1,1})do k.mat(k.b('Rail',{5.5,.07,.07},{.5,floor+.095,z+s*.21},steel),MAT.Metal)end
        end
        for _,z in ipairs({-.7,1.45})do k.b('ExitGatePost',{.18,1.1,.18},{2.12,floor+.55,z},timber)end
        k.b('ExitGate',{.26,.18,2.4},{2.12,floor+1.1,.375},amber)
        k.b('ExitGateBand',{.27,.06,1.6},{2.12,floor+1.21,.375},k.owner)
        k.b('Locomotive',{1.45,.58,.62},{.6,floor+.44,.95},olive,nil,'armor')
        k.w('LocoNose',{.62,.5,.4},{1.5,floor+.4,.95},olive,ANG(0,-PI/2,0))
        k.b('LocoStripe',{1.47,.12,.64},{.6,floor+.36,.95},k.owner)
        k.b('TrainCab',{.5,.3,.62},{.1,floor+.88,.95},drab,nil,'armor')
        k.b('HazardStripe',{.06,.2,.64},{1.33,floor+.62,.95},amber)
        if d then k.lit(k.b('Headlight',{.05,.12,.26},{1.72,floor+.42,.95},warm))end
        k.b('CargoWagon',{1.05,.16,.58},{-.75,floor+.2,.95},dark)
        k.b('CanvasLoad',{.9,.42,.5},{-.75,floor+.48,.95},canvas,nil,'soft')
        k.b('ContainerWagon',{1.0,.52,.6},{-1.85,floor+.41,.95},amber:Lerp(olive,.45),nil,'armor')
        k.b('Platform',{3.6,.18,.55},{0,floor+.09,-1.0},timber,nil,'board')
        if L>=2 then
            k.c('TankWagon',.24,1.25,{1.05,floor+.4,-.2},olive,ANG(0,0,PI/2))
            k.b('ShuntEngine',{.8,.48,.52},{-.15,floor+.37,-.2},drab,nil,'armor')
        end
        if L>=3 then k.b('PlatformCanopy',{3.2,.07,.8},{0,floor+1.0,-1.02},canvas,ANG(.1,0,0),'soft')
            if d then for _,x in ipairs({-1.4,1.4})do k.rod('CanopyPost',{x,floor+.18,-1.2},{x,floor+.98,-1.2},.04,timber)end end
        end
        if d then k.lit(k.b('SignalLamp',{.12,.18,.12},{-1.95,floor+.75,-.75},amber));k.rod('SignalPost',{-1.95,floor,-.75},{-1.95,floor+.7,-.75},.045,timber)end
    elseif kind=='MissileSilo'then
        k.c('HazardRing',1.35,.04,{0,floor+.01,0},amber)
        k.c('RingInner',1.12,.05,{0,floor+.015,0},C(80,76,60))
        k.b('LaunchWell',{1.9,.06,1.9},{0,floor+.04,-.1},well)
        for _,s in ipairs({-1,1})do
            local door=k.b('HatchDoor',{1.9,.1,.62},{0,floor+.17,-.1+s*1.27},olive,ANG(-s*math.rad(24),0,0),'armor')
            k.b('HatchStripe',{1.76,.02,.1},door.CFrame*CF(0,.06,s*.18),amber)
        end
        if d then for i=0,3 do local a=i*PI/2+PI/4;bags('Sandbags',1.0,.36,ANG(0,a,0)*CF(0,floor,-1.68))end end
        k.c('SiloCollar',L==1 and .72 or .92,.3,{0,floor+.15,0},timber)
        k.missiles(C(214,210,170),olive)
        if d then
            for _,x in ipairs({-1.5,-1.14})do k.rod('ServiceTower',{x,floor,-.55},{x,floor+3.0,-.55},.05,timber)end
            for _,y in ipairs({1.2,2.2,3.0})do k.b('ServiceArm',{.6,.07,.36},{-1.24,floor+y,-.55},timber,nil,'board')end
            k.lit(k.ball('MastLamp',.14,{-1.32,floor+3.1,-.55},amber))
            k.fade(k.b('CamoNet',{1.5,.05,.9},{1.1,floor+.5,.3},net,ANG(.2,.5,.3)),.1)
        else k.b('ServiceTower',{.34,3.0,.34},{-1.32,floor+1.5,-.55},timber)end
    elseif kind=='SAMLauncher'then
        k.b('Chassis',{1.5,.32,2.0},{.5,floor+.36,.4},olive,nil,'armor')
        if d then for _,z in ipairs({-.35,.25,.95})do for _,s in ipairs({-1,1})do k.c('Wheel',.2,.16,{.5+s*.72,floor+.2,z},dark,ANG(0,0,PI/2))end end end
        k.b('Cab',{1.3,.48,.55},{.5,floor+.76,-.42},drab,nil,'armor')
        k.b('CabGlass',{1.1,.16,.05},{.5,floor+.86,-.7},well)
        k.c('Turntable',.45,.14,{.5,floor+.58,.55},dark)
        local pack=CF(.5,floor+1.05,.5)*ANG(math.rad(-38),0,0)
        local cols=L==1 and {-.25,.25}or {-.42,0,.42}
        G.part(k.m,'LauncherTube',V3(#cols*.42+.12,.2,1.0),pack*CF(0,-.36,-.1),dark,'armor')
        for _,x in ipairs(cols)do for _,y in ipairs(d and {-.06,.34}or {.14})do
            G.part(k.m,'Tube',V3(.38,d and .38 or .78,1.6),pack*CF(x,y,0),canvas,'soft')
        end end
        bags('Sandbags',2.0,.5,CF(1.55,floor,.4)*ANG(0,PI/2,0))
        k.b('RadarCabin',{.95,.5,.85},{-1.05,floor+.25,-.95},olive,nil,'armor')
        if d then k.fade(k.b('CamoNet',{1.25,.05,1.1},{-1.05,floor+.56,-.95},net,ANG(.08,.2,-.06)),.1)end
        k.rod('RadarMast',{-1.05,floor+.5,-.95},{-1.05,floor+1.55,-.95},.08,timber)
        local span=L>=3 and 1.95 or 1.7
        k.mat(G.part(k.m,'RadarDish',V3(span,.5,span),CF(-1.05,floor+1.8,-.95)*ANG(math.rad(48),math.rad(28),0),canvas,'dish'),MAT.Fabric)
    end
end
T.polar=function(k,kind)
    local panel,snow,blue=k.P,k.S,k.A;local L,d=k.l,k.d
    local navy=C(44,62,92);local grey=C(150,166,184);local frost=C(178,216,240);local seam=C(176,190,204)
    k.lot(kind,C(196,210,224),snow,MAT.Concrete,MAT.Snow)
    local function lamp(name,pos,s)return k.lit(k.ball(name,s or .14,pos,blue))end
    if kind=='City'then
        local H=2.3+.5*(L-1)
        k.c('TowerBlock',.68,H,{-.6,floor+H/2,-.55},panel)
        for i=1,(d and L+1 or L)do k.lit(k.c('LightBand',.695,.06,{-.6,floor+H*i/(L+2),-.55},blue),.15)end
        if d then k.lit(k.b('Window',{.32,H*.62,.04},{-.6,floor+H*.5,.12},warm))end
        k.c('TowerCap',.74,.14,{-.6,floor+H+.07,-.55},snow)
        k.dome('Radome',{1.05,1.0,1.05},{-.6,floor+H+.5,-.55},snow)
        k.rod('Spire',{-.2,floor+H+.1,-.25},{-.2,floor+H+1.05,-.25},.035,grey);lamp('MastLamp',{-.2,floor+H+1.1,-.25})
        local h2=.62+.15*(L-1);local legs=.85
        k.b('Module',{1.4,h2,.92},{.85,floor+legs+h2/2,-.9},panel,nil,'armor')
        k.lit(k.b('ModuleBand',{1.42,.07,.94},{.85,floor+legs+h2*.62,-.9},blue),.1)
        if d then k.lit(k.b('Window',{.9,.12,.04},{.85,floor+legs+h2*.35,-.43},warm))end
        k.b('SnowCap',{1.36,.1,.88},{.85,floor+legs+h2+.05,-.9},snow,nil,'soft')
        local roof=floor+legs+h2+.1
        if d then k.rod('DishPost',{1.25,roof,-.95},{1.25,roof+.22,-.95},.035,grey)end
        k.mat(G.part(k.m,'RoofDish',V3(.6,.2,.6),CF(1.25,roof+.3,-.95)*ANG(math.rad(40),math.rad(30),0),snow,'dish'),MAT.Metal,.03)
        for _,s in ipairs(d and {{-1,-1},{1,-1},{-1,1},{1,1}}or {{-1,0},{1,0}})do k.rod('Stilt',{.85+s[1]*.55,floor,-.9+s[2]*.3},{.85+s[1]*.55,floor+legs,-.9+s[2]*.3},.06,grey)end
        k.dome('Dome',{1.6,1.5,1.6},{.8,floor,.78},snow)
        if d then k.ring('DomeRib',CF(.8,floor+.38,.78),.7,8,.05,.06,seam,nil,.85)end
        lamp('DoorLamp',{.8,floor+.25,1.58},.16)
        k.beam('Walkway',{-.6,floor+.22,-.55},{.8,floor+.22,.78},.44,.42,panel,'armor')
        k.lit(k.beam('WalkwayBand',{-.6,floor+.44,-.55},{.8,floor+.44,.78},.12,.04,blue),.1)
        for _,z in ipairs({-1.55,-1.0})do k.c('FuelTank',.2,.58,{-1.62,floor+.29,z},snow)end
        if L>=3 then
            k.c('ObsDeck',.88,.1,{-.6,floor+H*.9,-.55},snow)
            k.lit(k.c('ObsGlass',.8,.18,{-.6,floor+H*.9+.14,-.55},blue),.2)
        end
        if L>=2 then
            local th=1.7+.35*(L-2)
            k.rod('TurbineMast',{-1.05,floor,1.05},{-1.05,floor+th,1.05},.06,panel)
            k.b('TurbineHub',{.2,.2,.32},{-1.05,floor+th,1.18},snow)
            for i=0,2 do k.b('TurbineBlade',{.1,.8,.03},CF(-1.05,floor+th,1.33)*ANG(0,0,i*PI*2/3+.3)*CF(0,.4,0),snow)end
        end
        if d then k.b('SnowDrift',{1.0,.2,.6},{1.3,floor+.08,1.55},snow,ANG(0,.4,0),'soft')end
    elseif kind=='DefensePost'then
        local h=.72+.18*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do
            for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
                local f=rot*CF(0,0,side*(s/2-.23))
                k.mat(k.b('Wall',{s-.95,h,.46},CF(0,floor+h/2,0)*f,frost,nil,'armor'),MAT.Ice,.05)
                if d then k.b('SnowCap',{s-.95,.12,.5},CF(0,floor+h+.04,0)*f,snow,nil,'soft')end
            end
        end
        for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            k.c('Bastion',.56,h,{c[1]*1.5,floor+h/2,c[2]*1.5},panel)
            k.dome('BastionDome',{1.1,1.0,1.1},{c[1]*1.5,floor+h,c[2]*1.5},snow)
            if d then lamp('BastionLamp',{c[1]*1.5,floor+h+.52,c[2]*1.5},.12)end
        end
        local keep=1.1+.22*(L-1)
        k.c('BunkerCore',.74,keep,{0,floor+keep/2,0},panel)
        k.lit(k.c('LightBand',.745,.07,{0,floor+keep*.7,0},blue),.1)
        k.c('KeepRim',.8,.12,{0,floor+keep+.06,0},snow)
        k.b('TurretHead',{.7,.32,.7},{0,floor+keep+.28,0},snow,nil,'armor')
        k.rod('TurretBarrel',{.15,floor+keep+.3,.15},{.8,floor+keep+.36,.8},.07,navy)
        k.rod('Antenna',{-.25,floor+keep+.4,-.25},{-.25,floor+keep+1.2,-.25},.03,grey)
        if d then lamp('MastLamp',{-.25,floor+keep+1.24,-.25},.12)end
        k.flag(-1.5,-1.5,floor+h+.45,1.4,grey,k.owner)
        if L>=2 then k.b('Gatehouse',{1.15,h+.36,.66},{0,floor+(h+.36)/2,s/2-.23},panel,nil,'armor')
            k.lit(k.b('GateLight',{.6,.08,.04},{0,floor+h+.1,s/2+.11},blue),.1)
            if d then k.b('GateDoor',{.5,.44,.04},{0,floor+.22,s/2+.11},navy)end
        end
        if L>=3 and d then for _,x in ipairs({-1.5,1.5})do k.rod('BastionBarrel',{x,floor+h+.3,1.5},{x+.45*math.sign(x),floor+h+.36,1.95},.05,navy)end end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(30,84,124))
        for _,s in ipairs({-1,1})do k.b('Pier',{.42,.28,2.4},{s*1.94,.14,.95},snow,nil,'soft')end
        if d then for _,f in ipairs({{-1.4,1.95,.7},{1.35,.3,.5},{1.45,1.9,.55}})do k.b('IceFloe',{f[3],.08,f[3]*.7},{f[1],.07,f[2]},snow,ANG(0,f[1],0),'soft')end end
        local H=2.45+.25*(L-1);local top=.33+H
        for _,x in ipairs({-.55,.55})do for _,z in ipairs(d and {-1.6,-.42}or {-1.01})do k.b('CraneLeg',{.16,H,d and .16 or 1.3},{x,.33+H/2,z},panel)end end
        k.b('CranePortal',{1.36,.22,1.44},{0,top,-1.01},panel,nil,'armor')
        k.b('CraneBoom',{.36,.26,4.05},{0,top+.22,.12},snow,nil,'armor')
        k.lit(k.b('BoomBand',{.38,.06,3.9},{0,top+.36,.12},blue),.15)
        k.b('CraneHouse',{.8,.46,.74},{0,top+.58,-1.2},panel,nil,'armor');k.lit(k.b('CraneWindow',{.6,.1,.04},{0,top+.62,-.82},blue),.1)
        if d then k.rod('CraneCable',{0,top+.1,1.35},{0,.95,1.35},.03,navy)end
        k.b('Hull',{2.4,.44,.86},{-.28,.25,1.15},navy,nil,'armor')
        k.w('Bow',{.86,.44,.55},{1.19,.25,1.15},navy,ANG(0,-PI/2,0))
        k.b('HullStripe',{2.42,.08,.88},{-.28,.37,1.15},snow)
        k.b('Bridge',{.7,.42,.7},{-1.0,.68,1.15},snow,nil,'armor')
        k.b('Bridge',{.5,.3,.6},{-1.05,1.04,1.15},snow,nil,'armor')
        if d then k.lit(k.b('BridgeWindow',{.52,.08,.62},{-1.05,1.08,1.15},blue),.2)end
        for i,c in ipairs({k.owner:Lerp(snow,.15),snow,blue:Lerp(snow,.5)})do
            if d or i<3 then k.b('Container',{.5,.3,.66},{-.42+i*.55,.61,1.15},c,nil,'armor')end
        end
        if d then for _,x in ipairs({-1.5,1.5})do k.c('FuelTank',.32,.6,{x,floor+.3,-1.5},snow)end end
        if L>=3 then
            for _,z in ipairs({-1.6,-.42})do k.b('CraneLeg',{.16,H*.78,.16},{-1.45,.33+H*.39,z},panel)end
            k.b('CraneBoom2',{.28,.2,3.4},{-1.45,.33+H*.78+.1,-.05},snow,nil,'armor')
        end
    elseif kind=='Factory'then
        for _,z in ipairs({.95,-.2})do
            k.b('Ballast',{5.5,.06,.66},{.5,floor+.03,z},C(150,162,176))
            for _,s in ipairs({-1,1})do k.mat(k.b('Rail',{5.5,.07,.07},{.5,floor+.095,z+s*.21},steel),MAT.Metal)end
        end
        for _,z in ipairs({-.75,1.5})do k.b('ExitGatePost',{.34,1.1,.34},{2.12,floor+.55,z},panel,nil,'armor')end
        k.b('ExitGate',{.4,.26,2.6},{2.12,floor+1.2,.375},panel,nil,'armor')
        k.b('SnowCap',{.46,.1,2.62},{2.12,floor+1.37,.375},snow,nil,'soft')
        k.lit(k.b('ExitGateBand',{.42,.06,1.6},{2.12,floor+1.1,.375},blue),.1)
        k.b('Locomotive',{1.5,.58,.62},{.6,floor+.44,.95},snow,nil,'armor')
        k.lit(k.b('LocoStripe',{1.52,.08,.64},{.6,floor+.5,.95},blue),.1)
        k.b('LocoOwner',{1.52,.1,.64},{.6,floor+.3,.95},k.owner)
        k.w('Plough',{.64,.4,.42},{1.55,floor+.26,.95},navy,ANG(0,-PI/2,0))
        k.b('TrainCab',{.52,.3,.62},{.1,floor+.88,.95},panel,nil,'armor')
        if d then k.b('CabGlass',{.54,.1,.5},{.1,floor+.92,.95},navy);k.lit(k.b('Headlight',{.05,.12,.26},{1.4,floor+.62,.95},warm))end
        for i,x in ipairs({-.75,-1.85})do
            k.b('CargoWagon',{1.02,.52,.6},{x,floor+.41,.95},i==1 and panel or snow,nil,'armor')
            if d then k.lit(k.b('WagonBand',{1.04,.05,.62},{x,floor+.55,.95},blue),.25)end
        end
        k.b('Platform',{3.6,.18,.55},{0,floor+.09,-1.0},snow,nil,'board')
        if L>=2 then
            k.c('TankWagon',.24,1.25,{1.05,floor+.4,-.2},snow,ANG(0,0,PI/2))
            k.b('ShuntEngine',{.8,.48,.52},{-.15,floor+.37,-.2},panel,nil,'armor')
        end
        if L>=3 then k.b('PlatformCanopy',{3.2,.12,.8},{0,floor+1.0,-1.02},panel,nil,'armor');k.b('SnowCap',{3.1,.08,.72},{0,floor+1.09,-1.02},snow,nil,'soft')
            if d then for _,x in ipairs({-1.4,1.4})do k.rod('CanopyPost',{x,floor+.18,-1.2},{x,floor+.98,-1.2},.04,grey)end end
        end
        lamp('SignalLamp',{-1.95,floor+.78,-.75},.16);k.rod('SignalPost',{-1.95,floor,-.75},{-1.95,floor+.7,-.75},.045,grey)
    elseif kind=='MissileSilo'then
        k.lit(k.c('HazardRing',1.35,.04,{0,floor+.01,0},blue),.35)
        k.c('RingInner',1.12,.05,{0,floor+.015,0},grey)
        k.b('LaunchWell',{1.9,.06,1.9},{0,floor+.04,-.1},well)
        for _,s in ipairs({-1,1})do
            local door=k.b('HatchDoor',{1.9,.1,.62},{0,floor+.17,-.1+s*1.27},panel,ANG(-s*math.rad(24),0,0),'armor')
            k.lit(k.b('HatchStripe',{1.76,.02,.08},door.CFrame*CF(0,.06,s*.18),blue),.1)
        end
        k.c('SiloCollar',L==1 and .72 or .92,.3,{0,floor+.15,0},snow)
        k.missiles(C(238,245,252),C(200,222,244))
        k.b('ServiceTower',{.42,3.0,.42},{-1.32,floor+1.5,-.55},panel,nil,'armor')
        k.lit(k.b('TowerBand',{.44,.06,.44},{-1.32,floor+2.4,-.55},blue),.1)
        k.dome('Radome',{.7,.66,.7},{-1.32,floor+3.15,-.55},snow)
        if d then for _,y in ipairs({.6,1.4,2.35})do k.b('ServiceArm',{.62,.09,.12},{-.98,floor+y,-.45},steel)end
            k.b('SnowDrift',{.9,.2,.5},{1.25,floor+.06,-.9},snow,ANG(0,.6,0),'soft')
            k.rod('Antenna',{-1.32,floor+3.4,-.55},{-1.32,floor+3.95,-.55},.03,grey);lamp('MastLamp',{-1.32,floor+3.98,-.55},.12)
            for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do lamp('PadLamp',{c[1]*1.2,floor+.08,c[2]*1.2},.14)end
            for _,z in ipairs({.1,.66})do k.c('FuelTank',.22,.7,{1.5,floor+.35,z},snow);k.lit(k.c('TankBand',.225,.05,{1.5,floor+.5,z},blue),.1)end
        end
    elseif kind=='SAMLauncher'then
        for _,s in ipairs({-1,1})do k.b('Track',{.34,.34,1.95},{.5+s*.8,floor+.17,.45},navy,nil,'soft')end
        k.b('Chassis',{1.3,.36,1.8},{.5,floor+.4,.45},panel,nil,'armor')
        k.c('Turntable',.48,.16,{.5,floor+.66,.5},snow)
        local pack=CF(.5,floor+1.15,.42)*ANG(math.rad(-40),0,0)
        local cols=L==1 and {-.29,.29}or {-.44,0,.44}
        G.part(k.m,'LauncherTube',V3(#cols*.44+.14,.22,1.0),pack*CF(0,-.38,-.1),grey,'armor')
        if not d then G.part(k.m,'Tube',V3(#cols*.44+.1,.84,1.5),pack*CF(0,.14,0),snow,'armor')end
        for _,x in ipairs(d and cols or {})do for _,y in ipairs({-.08,.36})do
            tube(k,pack,x,y,snow,blue)
        end end
        k.b('RadarCabin',{1.0,.55,.9},{-1.05,floor+.275,-.95},panel,nil,'armor')
        k.b('SnowCap',{.96,.08,.86},{-1.05,floor+.58,-.95},snow,nil,'soft')
        k.lit(k.b('CabinWindow',{.5,.1,.04},{-1.2,floor+.34,-.49},blue),.1)
        k.c('FuelTank',.22,.62,{-1.5,floor+.31,.35},snow)
        if d then k.lit(k.c('TankBand',.225,.05,{-1.5,floor+.44,.35},blue),.1)end
        k.dome('Radome',{.62,.6,.62},{-.75,floor+.55,-.7},snow)
        k.rod('RadarMast',{-1.15,floor+.55,-1.05},{-1.15,floor+1.55,-1.05},.08,grey)
        local span=L>=3 and 2.0 or 1.75
        k.mat(G.part(k.m,'RadarDish',V3(span,.5,span),CF(-1.15,floor+1.8,-1.05)*ANG(math.rad(48),math.rad(28),0),snow,'dish'),MAT.Metal,.03)
        if d then lamp('MastLamp',{-1.5,floor+.7,-1.3},.14)end
    end
end
T.neon=function(k,kind)
    local glass,violet,neon=k.P:Lerp(k.S,.42),k.S,k.A;local L,d=k.l,k.d
    local black=C(48,40,76);local pink=C(255,110,210);local lilac=C(214,190,255)
    local function g(p,refl)p.Material=MAT.Glass;p.Reflectance=refl or .12;return p end
    local function strip(name,size,pos,color,rot,t)return k.lit(k.b(name,size,pos,color or neon,rot),t)end
    k.lot(kind,C(24,20,36),C(36,30,56),MAT.Metal,MAT.Metal)
    if kind=='City'or kind=='DefensePost'or kind=='Factory'or kind=='SAMLauncher'then
        for _,s in ipairs(d and {-1,1}or {1})do strip('LotEdge',{3.86,.03,.05},{0,.32,s*1.93},neon,nil,.15);strip('LotEdge',{.05,.03,3.86},{s*1.93,.32,0},neon,nil,.15)end
    end
    local function holo(name,size,cf,spec,color)
        local p=k.lit(k.b(name,size,cf,color or neon),.45);p.CastShadow=false;if spec then k.move(p,spec)end;return p
    end
    if kind=='City'then
        local H=2.8+.45*(L-1)
        g(k.b('TowerBlock1',{1.08,H,1.08},{-.6,floor+H/2,-.55},glass,nil,'armor'))
        for _,x in ipairs({-1,1})do strip('NeonEdge',{.05,H,.05},{-.6+x*.54,floor+H/2,-.01},neon)end
        if d then strip('Window',{.5,H*.74,.03},{-.6,floor+H*.48,-.0},lilac,nil,.5)
            for i=1,4 do strip('FloorLine',{1.1,.03,1.1},{-.6,floor+H*i/5,-.55},violet,nil,.25)end end
        strip('TowerCap',{1.14,.06,1.14},{-.6,floor+H,-.55},neon)
        g(k.b('TowerCrown',{.66,.6,.66},{-.6,floor+H+.3,-.55},glass,nil,'armor'))
        strip('CrownCap',{.7,.05,.7},{-.6,floor+H+.6,-.55},pink)
        strip('Spire',{.06,.5,.06},{-.6,floor+H+.85,-.55},neon)
        if d then for _,s in ipairs({-1,1})do strip('CrownAntenna',{.03,.4,.03},{-.6+s*.25,floor+H+.8,-.55-s*.25},violet)end
            strip('Storefront',{.9,.14,.03},{-.6,floor+.1,.0},pink,nil,.2)end
        local axis=CF(-.6,floor+H+.35,-.55)
        for i=0,(d and 1 or 0)do holo('HoloSign',{.9,.42,.04},axis*ANG(0,i*PI,0)*CF(0,0,-.72),{axis=axis,spin=.8},i==0 and neon or pink)end
        local h2=1.9+.45*(L-1)
        g(k.b('TowerBlock2',{.98,h2,.98},{.9,floor+h2/2,-.85},glass,nil,'armor'))
        k.w('TowerSlope',{.98,.6,.98},{.9,floor+h2+.3,-.85},glass,ANG(0,PI,0))
        for i=1,(d and 3 or 1)do strip('NeonBand',{1.0,.04,1.0},{.9,floor+h2*i/4,-.85},violet,nil,.1)end
        strip('Window',{.03,h2*.7,.4},{1.395,floor+h2*.5,-.95},lilac,nil,.5)
        strip('BladeSign',{.3,.7,.06},{1.54,floor+h2*.55,-.45},pink,nil,.15)
        if d then strip('Storefront',{.03,.14,.8},{1.395,floor+.1,-.85},pink,nil,.2)end
        local h3=1.2+.3*(L-1)
        g(k.b('TowerBlock3',{1.05,h3,.95},{.85,floor+h3/2,.8},glass,nil,'armor'))
        strip('Billboard',{.85,.55,.03},{.85,floor+h3*.6,1.29},pink,nil,.25)
        strip('TowerCap',{1.08,.05,.98},{.85,floor+h3,.8},neon)
        for i=1,L do strip('FloorLine',{1.07,.03,.97},{.85,floor+h3*i/(L+1),.8},violet,nil,.25)end
        strip('Antenna',{.04,.6,.04},{1.15,floor+h3+.3,.6},neon)
        if d then k.lit(k.ball('AntennaTip',.12,{1.15,floor+h3+.62,.6},pink))end
        if L>=2 then
            local h4=.95+.3*(L-2)
            g(k.b('TowerBlock4',{.9,h4,.8},{-1.0,floor+h4/2,1.08},glass,nil,'armor'))
            strip('NeonEdge',{.92,.05,.82},{-1.0,floor+h4,1.08},violet)
            strip('Skybridge',{1.0,.12,.16},{.15,floor+1.55,-.7},neon,nil,.2)
            strip('Skybridge',{.92,.1,.16},{-.11,floor+.7,.98},pink,nil,.2)
            if L>=3 then g(k.w('TowerSlope',{.8,.4,.9},{-1.0,floor+h4+.22,1.08},glass,ANG(0,PI/2,0)))
                strip('Spire',{.05,.45,.05},{-1.3,floor+h4+.45,1.08},neon)end
        end
    elseif kind=='DefensePost'then
        local h=.72+.18*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.21))
            g(k.b('Wall',{s-.9,h,.42},CF(0,floor+h/2,0)*f,glass,nil,'armor'))
            strip('WallNeon',{s-.9,.05,.1},CF(0,floor+h+.02,0)*f,neon)
        end end
        for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            g(k.b('Bastion',{1.0,h+.2,1.0},{c[1]*1.5,floor+(h+.2)/2,c[2]*1.5},black,ANG(0,PI/4,0),'armor'))
            strip('BastionCap',{.7,.05,.7},{c[1]*1.5,floor+h+.22,c[2]*1.5},violet,ANG(0,PI/4,0))
        end
        local keep=1.05+.22*(L-1)
        g(k.c('BunkerCore',.74,keep,{0,floor+keep/2,0},glass))
        k.lit(k.c('KeepRim',.78,.08,{0,floor+keep,0},neon))
        k.b('TurretHead',{.6,.28,.6},{0,floor+keep+.18,0},black,nil,'armor')
        k.rod('TurretBarrel',{.12,floor+keep+.22,.12},{.8,floor+keep+.28,.8},.07,black)
        local dome=k.dome('ShieldDome',{2.0,1.6,2.0},{0,floor+keep,0},neon);k.lit(dome,.78)
        local axis=CF(0,floor+keep+.35,0)*ANG(.3,0,0)
        k.ring('HoloRing',axis,1.08,d and 10 or 6,.06,.06,pink,{spin=.9})
        k.flag(-1.5,-1.5,floor+h+.2,1.5,neon,k.owner);k.lit(k.m:FindFirstChild('FlagPole'))
        if L>=2 then g(k.b('Gatehouse',{1.1,h+.34,.62},{0,floor+(h+.34)/2,s/2-.21},glass,nil,'armor'));strip('GateNeon',{.7,.06,.04},{0,floor+h+.1,s/2+.11},pink)end
        if L>=3 and d then for _,x in ipairs({-1.5,1.5})do strip('BastionBarrel',{.08,.08,.5},{x+.2*math.sign(x),floor+h+.36,1.75},neon,ANG(0,math.sign(x)*.7,0))end end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(26,22,56))
        for _,s in ipairs({-1,1})do g(k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},black,nil,'armor'));strip('PierNeon',{.05,.03,2.4},{s*1.72,.27,.95},neon)end
        local H=2.45+.25*(L-1);local top=.33+H
        for _,x in ipairs({-.55,.55})do for _,z in ipairs(d and {-1.6,-.42}or {-1.01})do g(k.b('CraneLeg',{.15,H,d and .15 or 1.3},{x,.33+H/2,z},black))end end
        g(k.b('CranePortal',{1.32,.2,1.4},{0,top,-1.01},black,nil,'armor'))
        g(k.b('CraneBoom',{.34,.24,4.05},{0,top+.22,.12},black,nil,'armor'))
        for _,x in ipairs({-.17,.17})do strip('BoomNeon',{.04,.04,4.05},{x,top+.35,.12},neon)end
        g(k.b('CraneHouse',{.78,.44,.72},{0,top+.56,-1.2},glass,nil,'armor'));strip('CraneWindow',{.6,.1,.03},{0,top+.6,-.83},pink)
        if d then strip('CraneCable',{.03,top-.7,.03},{0,(top+.95)/2+.05,1.35},violet,nil,.3)end
        g(k.b('Hull',{2.55,.42,.86},{-.2,.25,1.15},black,nil,'armor'))
        k.w('Bow',{.86,.42,.5},{1.3,.25,1.15},black,ANG(0,-PI/2,0))
        strip('Waterline',{2.58,.04,.88},{-.2,.1,1.15},neon)
        g(k.b('Bridge',{.42,.52,.66},{-1.2,.72,1.15},glass,nil,'armor'));strip('BridgeWindow',{.44,.07,.68},{-1.2,.86,1.15},pink)
        strip('BridgeMast',{.04,.6,.04},{-1.2,1.28,1.15},violet)
        if d then k.lit(k.ball('MastTip',.1,{-1.2,1.6,1.15},pink))end
        for i,c in ipairs({k.owner,violet,neon})do
            if d or i<3 then local box=k.b('Container',{.6,.3,.66},{-.72+i*.66,.61,1.15},c:Lerp(black,.45),nil,'armor');if i==1 then box.Color=k.owner end end
        end
        if L>=2 and d then strip('ContainerGlow',{1.9,.03,.68},{-.06,.77,1.15},neon,nil,.3)end
        local axis=CF(1.45,floor+1.2,-1.45)
        g(k.b('QuayCargo',{.5,.8,.5},{1.45,floor+.4,-1.45},black,nil,'armor'))
        for i=0,(d and 1 or 0)do holo('HoloSign',{.7,.36,.04},axis*ANG(0,i*PI,0)*CF(0,0,-.5),{axis=axis,spin=.8},i==0 and neon or pink)end
        if L>=3 then
            for _,z in ipairs({-1.6,-.42})do g(k.b('CraneLeg',{.15,H*.78,.15},{-1.45,.33+H*.39,z},black))end
            g(k.b('CraneBoom2',{.28,.2,3.4},{-1.45,.33+H*.78+.1,-.05},black,nil,'armor'));strip('BoomNeon',{.04,.04,3.4},{-1.45,.33+H*.78+.21,-.05},violet)
        end
    elseif kind=='Factory'then
        for _,z in ipairs({.95,-.2})do
            g(k.b('Ballast',{5.5,.1,.5},{.5,floor+.05,z},black))
            strip('Rail',{5.5,.03,.08},{.5,floor+.11,z},neon,nil,.05)
        end
        for _,z in ipairs({-.7,1.45})do g(k.b('ExitGatePost',{.16,1.15,.16},{2.12,floor+.57,z},black));strip('GatePostNeon',{.04,1.0,.04},{2.03,floor+.55,z},violet)end
        strip('ExitGate',{.14,.12,2.3},{2.12,floor+1.15,.375},neon)
        k.b('ExitGateBand',{.2,.08,1.4},{2.12,floor+1.26,.375},k.owner)
        local train={}
        table.insert(train,g(k.b('Locomotive',{1.6,.46,.56},{.55,floor+.48,.95},glass,nil,'armor')))
        table.insert(train,g(k.w('LocoNose',{.56,.46,.75},{1.72,floor+.48,.95},glass,ANG(0,-PI/2,0))))
        table.insert(train,strip('LocoRoof',{1.6,.03,.2},{.55,floor+.72,.95},neon,nil,.1))
        table.insert(train,strip('LocoStripe',{2.1,.06,.58},{.8,floor+.42,.95},neon))
        table.insert(train,k.b('LocoOwner',{1.62,.07,.58},{.55,floor+.3,.95},k.owner))
        table.insert(train,strip('TrainCab',{1.3,.08,.58},{.5,floor+.6,.95},pink,nil,.2))
        table.insert(train,g(k.b('CargoWagon',{1.3,.42,.54},{-.95,floor+.46,.95},glass,nil,'armor')))
        if d then table.insert(train,strip('WagonWindow',{1.1,.07,.56},{-.95,floor+.55,.95},lilac,nil,.3))end
        for _,p in ipairs(train)do k.move(p,{bob=.035,freq=2.2})end
        g(k.b('Platform',{3.6,.18,.55},{0,floor+.09,-1.0},glass,nil,'board'))
        strip('PlatformEdge',{3.6,.03,.05},{0,floor+.19,-.73},neon)
        if L>=2 then g(k.b('TankWagon',{1.3,.4,.5},{1.05,floor+.42,-.2},black,nil,'armor'));strip('TankStripe',{1.32,.05,.52},{1.05,floor+.5,-.2},violet)
            g(k.b('ShuntEngine',{.8,.44,.5},{-.15,floor+.42,-.2},glass,nil,'armor'))end
        if L>=3 then g(k.b('PlatformCanopy',{3.2,.08,.72},{0,floor+1.0,-1.02},glass,nil,'armor'));strip('CanopyNeon',{3.2,.03,.05},{0,floor+.96,-.67},pink)
            if d then for _,x in ipairs({-1.4,1.4})do strip('CanopyPost',{.04,.8,.04},{x,floor+.58,-1.2},violet,nil,.2)end end
        end
        do local axis=CF(-1.6,floor+1.1,-1.3)
            for i=0,(d and 1 or 0)do holo('HoloSign',{.6,.32,.04},axis*ANG(0,i*PI,0)*CF(0,0,-.32),{axis=axis,spin=.8},i==0 and neon or pink)end
            g(k.b('SignalPost',{.08,.8,.08},{-1.6,floor+.4,-1.3},black))
        end
    elseif kind=='MissileSilo'then
        k.lit(k.c('HazardRing',1.35,.04,{0,floor+.01,0},neon),.2)
        g(k.c('RingInner',1.12,.05,{0,floor+.015,0},black))
        k.b('LaunchWell',{1.9,.06,1.9},{0,floor+.04,-.1},well)
        for _,s in ipairs({-1,1})do
            local door=g(k.b('HatchDoor',{1.9,.1,.62},{0,floor+.17,-.1+s*1.27},black,ANG(-s*math.rad(24),0,0),'armor'))
            k.lit(k.b('HatchStripe',{1.76,.02,.06},door.CFrame*CF(0,.06,s*.2),pink))
        end
        k.lit(k.c('SiloCollar',L==1 and .72 or .92,.3,{0,floor+.15,0},violet),.2)
        local r,len=k.missiles(C(216,206,240),C(180,150,240))
        local axis=CF(0,floor+.3+len*.55,0)*ANG(.15,0,0)
        k.ring('HoloRing',axis,L==1 and .75 or 1.12,d and 10 or 6,.05,.06,pink,{spin=1.0})
        g(k.b('ServiceTower',{.34,3.0,.34},{-1.32,floor+1.5,-.55},black,nil,'armor'))
        strip('TowerNeon',{.04,3.0,.04},{-1.15,floor+1.5,-.38},neon)
        strip('TowerNeon',{.04,3.0,.04},{-1.49,floor+1.5,-.38},neon)
        strip('TowerCap',{.38,.05,.38},{-1.32,floor+3.0,-.55},pink)
        strip('Antenna',{.04,.55,.04},{-1.32,floor+3.3,-.55},violet)
        if d then for _,y in ipairs({.6,1.4,2.35})do strip('ServiceArm',{.6,.05,.08},{-.98,floor+y,-.45},violet)end
            k.lit(k.ball('AntennaTip',.12,{-1.32,floor+3.6,-.55},pink))end
    elseif kind=='SAMLauncher'then
        g(k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},black,nil,'armor'))
        strip('ChassisNeon',{1.97,.04,1.57},{.5,floor+.34,.5},neon,nil,.1)
        k.c('Turntable',.5,.16,{.5,floor+.44,.5},violet)
        local pack=CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0)
        local cols=L==1 and {-.29,.29}or {-.44,0,.44}
        G.part(k.m,'LauncherTube',V3(#cols*.44+.14,.22,1.0),pack*CF(0,-.38,-.1),black,'armor')
        if not d then g(G.part(k.m,'Tube',V3(#cols*.44+.1,.84,1.5),pack*CF(0,.14,0),glass,'armor'))end
        for _,x in ipairs(d and cols or {})do for _,y in ipairs({-.08,.36})do tube(k,pack,x,y,glass,pink,0)end end
        g(k.b('RadarCabin',{1.0,.55,.9},{-1.05,floor+.275,-.95},glass,nil,'armor'))
        strip('CabinNeon',{1.02,.05,.92},{-1.05,floor+.55,-.95},violet)
        k.rod('RadarMast',{-1.05,floor+.55,-.95},{-1.05,floor+1.55,-.95},.09,black)
        local span=L>=3 and 2.0 or 1.75
        g(G.part(k.m,'RadarDish',V3(span,.5,span),CF(-1.05,floor+1.8,-.95)*ANG(math.rad(48),math.rad(28),0),C(150,124,214),'dish'),.2)
        local axis=CF(-1.05,floor+1.25,-.95)
        k.ring('HoloRing',axis,.95,d and 10 or 6,.05,.06,neon,{spin=-1.0})
    end
end
T.imperial=function(k,kind)
    local ivory,gold,bright=k.P,k.S:Lerp(C(240,214,150),.3),k.A:Lerp(C(255,236,170),.25);local L,d=k.l,k.d
    local marble=C(204,192,166);local deep=C(86,64,40);local lamp=C(255,226,150)
    local function G2(p)return k.gold(p)end
    k.lot(kind,marble,ivory,MAT.Marble,MAT.Marble)
    if kind~='Port'and kind~='MissileSilo'then G2(k.b('PlinthTrim',{4.0,.04,4.0},{0,.27,0},gold))
    elseif kind=='MissileSilo'then G2(k.c('PlinthTrim',1.96,.04,{0,.27,0},gold))end
    local function halo(center,R,n,speed,h)return k.ring('GildedRing',center,R,d and n or math.ceil(n*.6),h or .09,.09,bright,{spin=speed},.75)end
    local function banner(x,y,z,w,h,rot)
        local b=k.b('Banner',{w or .42,h or .9,.04},CF(x,y,z)*(rot or CFrame.identity),k.owner)
        k.move(b,{sway=.06,pivot=V3(0,(h or .9)/2,0)})
        G2(k.b('BannerRod',{(w or .42)+.1,.05,.06},CF(x,y+(h or .9)/2+.02,z)*(rot or CFrame.identity),gold))
        return b
    end
    local function column(x,z,y,h,r)return k.c('Column',r or .09,h,{x,y+h/2,z},ivory)end
    local function minaret(x,z,h,r)
        k.c('Minaret',r,h,{x,floor+h/2,z},ivory)
        G2(k.c('MinaretBand',r+.02,.08,{x,floor+h*.75,z},gold))
        G2(k.dome('MinaretDome',{r*2.3,r*3.2,r*2.3},{x,floor+h,z},bright))
        if d then G2(k.rod('MinaretSpire',{x,floor+h+r*1.4,z},{x,floor+h+r*1.4+.45,z},.03,bright))end
    end
    if kind=='City'then
        local H=1.2+.3*(L-1);local cx,cz=0,-.25;local base=floor+.4
        k.b('Terrace',{2.7,.4,2.5},{cx,floor+.2,cz},ivory,nil,'armor')
        G2(k.b('TerraceTrim',{2.74,.06,2.54},{cx,floor+.38,cz},gold))
        k.c('TowerBlock1',.9,H,{cx,base+H/2,cz},ivory)
        if d then for i=0,7 do local a=i/8*PI*2;column(cx+math.cos(a)*1.08,cz+math.sin(a)*1.08,base,H)end
        else for i=0,3 do local a=i/4*PI*2+PI/4;column(cx+math.cos(a)*1.08,cz+math.sin(a)*1.08,base,H)end end
        G2(k.c('Cornice',1.22,.14,{cx,base+H+.07,cz},gold))
        local domeY=base+H+.14
        local dome=G2(k.dome('TowerCrown',{1.95,2.5,1.95},{cx,domeY,cz},bright))
        k.light(dome,lamp,7,.9)
        if d then k.lit(k.b('Window',{.34,H*.55,.04},{cx,base+H*.5,cz+.9},warm))end
        k.c('Lantern',.2,.36,{cx,domeY+1.35,cz},ivory)
        G2(k.c('Crown',.28,.16,{cx,domeY+1.6,cz},bright))
        G2(k.rod('Spire',{cx,domeY+1.68,cz},{cx,domeY+2.35,cz},.045,bright))
        k.lit(k.ball('CrownJewel',.16,{cx,domeY+2.35,cz},lamp))
        halo(CF(cx,domeY+.55,cz)*ANG(.32,0,.12),1.3,12,.45,.08)
        local mh=1.8+.4*(L-1)
        for _,c in ipairs({{-1.55,-1.6},{1.55,-1.6},{-1.55,1.25},{1.55,1.25}})do minaret(c[1],c[2],mh,.2)end
        banner(-1.55,floor+mh*.62,1.5,.4,.8);banner(1.55,floor+mh*.62,1.5,.4,.8)
        G2(k.b('Portal',{.6,.75,.08},{cx,floor+.75,cz+1.27},gold))
        k.b('PortalDoor',{.4,.55,.04},{cx,floor+.68,cz+1.32},deep)
    elseif kind=='DefensePost'then
        local h=.8+.18*(L-1);local s=3.3
        for _,side in ipairs({-1,1})do for _,rot in ipairs({CFrame.identity,ANG(0,PI/2,0)})do
            local f=rot*CF(0,0,side*(s/2-.21))
            k.b('Wall',{s-.9,h,.42},CF(0,floor+h/2,0)*f,ivory,nil,'armor')
            G2(k.b('WallCoping',{s-.9,.08,.48},CF(0,floor+h+.04,0)*f,gold))
        end end
        for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            k.c('Bastion',.55,h+.5,{c[1]*1.5,floor+(h+.5)/2,c[2]*1.5},ivory)
            G2(k.dome('BastionDome',{1.05,1.2,1.05},{c[1]*1.5,floor+h+.5,c[2]*1.5},bright))
            if d then G2(k.c('BastionBand',.57,.07,{c[1]*1.5,floor+h+.3,c[2]*1.5},gold))end
        end
        local keep=1.7+.3*(L-1)
        k.c('BunkerCore',.66,keep,{0,floor+keep/2,0},ivory)
        G2(k.c('KeepRim',.74,.12,{0,floor+keep,0},gold))
        if d then k.lit(k.b('Window',{.24,.4,.04},{0,floor+keep*.62,.66},warm))end
        local dome=G2(k.dome('TurretHead',{1.3,1.7,1.3},{0,floor+keep+.06,0},bright))
        k.light(dome,lamp,7,.9)
        G2(k.c('Crown',.24,.16,{0,floor+keep+.92,0},bright))
        G2(k.rod('Spire',{0,floor+keep+1.0,0},{0,floor+keep+1.55,0},.04,bright))
        halo(CF(0,floor+keep+.35,0)*ANG(.25,0,0),1.05,12,.5,.08)
        if L>=2 then
            for _,x in ipairs({-.62,.62})do k.b('Gatehouse',{.42,h+.75,.5},{x,floor+(h+.75)/2,s/2-.21},ivory,nil,'armor')end
            k.b('GateAttic',{1.7,.38,.56},{0,floor+h+.94,s/2-.21},ivory,nil,'armor')
            G2(k.b('GateGilt',{1.74,.07,.6},{0,floor+h+1.15,s/2-.21},gold))
            G2(k.b('GateEagle',{.5,.3,.2},{0,floor+h+1.33,s/2-.21},bright,nil,'soft'))
            banner(0,floor+h+.32,s/2+.08,.6,.6)
        else banner(0,floor+h*.5,s/2+.03,.6,.55)end
        banner(-1.0,floor+h*.55,-s/2-.03,.4,.55,ANG(0,PI,0))
        if L>=3 and d then for _,x in ipairs({-1.5,1.5})do G2(k.rod('BastionBarrel',{x,floor+h+.3,1.5},{x+.45*math.sign(x),floor+h+.36,1.95},.06,gold))end end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(30,104,132))
        for _,s in ipairs({-1,1})do k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},marble,nil,'armor');G2(k.b('PierTrim',{.46,.04,2.42},{s*1.94,.27,.95},gold))end
        local H=2.45+.25*(L-1);local top=.33+H
        for _,x in ipairs({-.55,.55})do for _,z in ipairs(d and {-1.6,-.42}or {-1.01})do k.b('CraneLeg',{.17,H,d and .17 or 1.3},{x,.33+H/2,z},ivory)end end
        G2(k.b('CranePortal',{1.32,.2,1.4},{0,top,-1.01},bright,nil,'armor'))
        G2(k.b('CraneBoom',{.34,.24,4.05},{0,top+.22,.12},bright,nil,'armor'))
        k.b('CraneHouse',{.78,.44,.72},{0,top+.56,-1.2},ivory,nil,'armor')
        G2(k.dome('CraneDome',{.6,.5,.6},{0,top+.78,-1.2},bright))
        if d then k.rod('CraneCable',{0,top+.1,1.35},{0,1.05,1.35},.03,deep)end
        k.b('Hull',{2.5,.46,.86},{-.15,.27,1.15},ivory,nil,'armor')
        k.w('Bow',{.86,.46,.6},{1.4,.27,1.15},ivory,ANG(0,-PI/2,0))
        G2(k.b('HullRail',{2.52,.07,.88},{-.15,.48,1.15},gold))
        k.b('Bridge',{.55,.42,.8},{-1.1,.7,1.15},ivory,nil,'armor')
        G2(k.b('BridgeGilt',{.57,.06,.82},{-1.1,.9,1.15},gold))
        for i,x in ipairs({-.35,.55})do
            local mh=1.5+(i==2 and .2 or 0)
            G2(k.rod('Mast',{x,.5,1.15},{x,.5+mh,1.15},.04,gold))
            local sail=k.b('Sail',{.06,mh*.55,.95},{x+.03,.5+mh*.55,1.15},k.owner,nil,'soft')
            k.move(sail,{sway=.04,pivot=V3(0,mh*.27,0),axisX=true})
        end
        local lh=2.6+.3*(L-1);local lx,lz=1.55,-1.6
        k.c('Lighthouse',.42,lh*.6,{lx,floor+lh*.3,lz},ivory)
        k.c('Lighthouse',.32,lh*.4,{lx,floor+lh*.8,lz},ivory)
        G2(k.c('LighthouseRim',.42,.1,{lx,floor+lh*.6,lz},gold))
        local lantern=k.lit(k.c('Lantern',.24,.32,{lx,floor+lh+.16,lz},lamp))
        k.light(lantern,lamp,8,1)
        G2(k.dome('LanternDome',{.6,.6,.6},{lx,floor+lh+.32,lz},bright))
        local axis=CF(lx,floor+lh+.16,lz)
        for i=0,(d and 1 or 0)do k.move(k.lit(k.b('LightBeam',{.12,.1,1.6},axis*ANG(0,i*PI,0)*CF(0,0,-.95),lamp),.55),{axis=axis,spin=1.1})end
        if d then for i=0,2 do column(-1.6+i*.5,-2.0,floor,1.0,.08)end;k.b('Colonnade',{1.3,.12,.3},{-1.1,floor+1.06,-2.0},ivory,nil,'armor')end
        if L>=3 then
            for _,z in ipairs({-1.6,-.42})do k.b('CraneLeg',{.15,H*.78,.15},{-1.45,.33+H*.39,z},ivory)end
            G2(k.b('CraneBoom2',{.28,.2,3.4},{-1.45,.33+H*.78+.1,-.05},bright,nil,'armor'))
        end
    elseif kind=='Factory'then
        for _,z in ipairs({.95,-.2})do
            k.b('Ballast',{5.5,.06,.66},{.5,floor+.03,z},marble)
            for _,s in ipairs({-1,1})do G2(k.b('Rail',{5.5,.07,.07},{.5,floor+.095,z+s*.21},gold))end
        end
        for _,z in ipairs({-.85,1.6})do k.b('ExitGatePost',{.45,1.35,.45},{2.12,floor+.67,z},ivory,nil,'armor')end
        k.b('ExitGate',{.5,.42,2.9},{2.12,floor+1.55,.375},ivory,nil,'armor')
        G2(k.b('GateGilt',{.54,.07,2.94},{2.12,floor+1.78,.375},gold))
        G2(k.b('GateEagle',{.24,.32,.6},{2.12,floor+1.98,.375},bright,nil,'soft'))
        k.b('ExitGateBand',{.52,.12,1.6},{2.12,floor+1.42,.375},k.owner)
        k.b('LocoFrame',{1.6,.2,.56},{.6,floor+.2,.95},deep,nil,'armor')
        local boiler=G2(k.c('Locomotive',.27,1.15,{.85,floor+.55,.95},bright,ANG(0,0,PI/2)))
        G2(k.c('Chimney',.1,.36,{1.2,floor+.95,.95},gold))
        k.b('TrainCab',{.5,.62,.6},{.05,floor+.6,.95},ivory,nil,'armor')
        G2(k.b('CabRoof',{.6,.07,.66},{.05,floor+.94,.95},gold))
        k.b('LocoStripe',{.52,.1,.62},{.05,floor+.42,.95},k.owner)
        if d then k.lit(k.ball('Headlight',.16,{1.45,floor+.58,.95},lamp))end
        k.light(boiler,lamp,6,.7)
        for i,x in ipairs({-.85,-1.95})do
            k.b('CargoWagon',{1.0,.5,.58},{x,floor+.42,.95},ivory,nil,'armor')
            G2(k.b('WagonRoof',{1.04,.07,.62},{x,floor+.7,.95},gold))
            if d then k.lit(k.b('WagonWindow',{.8,.1,.6},{x,floor+.5,.95},warm),.1)end
        end
        k.b('Platform',{3.6,.2,.6},{0,floor+.1,-1.05},ivory,nil,'armor')
        local ch=1.05+.15*(L-1)
        for i=0,(d and 4 or 2)do column(-1.6+i*(3.2/(d and 4 or 2)),-1.2,floor+.2,ch,.08)end
        k.c('Vault',.42,3.5,{0,floor+.2+ch+.1,-1.2},ivory,ANG(0,0,PI/2))
        G2(k.b('VaultRidge',{3.5,.06,.12},{0,floor+.2+ch+.53,-1.2},gold))
        if L>=2 then
            k.b('ClockTower',{.5,.7+.2*(L-2),.5},{0,floor+.2+ch+.6+.1*(L-2),-1.2},ivory,nil,'armor')
            G2(k.dome('ClockDome',{.55,.75,.55},{0,floor+.2+ch+.95+.2*(L-2),-1.2},bright))
            k.lit(k.c('ClockFace',.15,.03,{0,floor+.2+ch+.6+.1*(L-2),-.94},lamp,ANG(PI/2,0,0)))
            G2(k.c('TankWagon',.22,1.2,{1.05,floor+.42,-.2},gold,ANG(0,0,PI/2)))
            k.b('ShuntEngine',{.8,.46,.5},{-.15,floor+.36,-.2},ivory,nil,'armor')
        end
        if L>=3 then local axis=CF(0,floor+.2+ch+1.9,-1.2);halo(axis,.55,8,.6,.06)end
    elseif kind=='MissileSilo'then
        G2(k.c('HazardRing',1.35,.04,{0,floor+.01,0},gold))
        k.c('RingInner',1.12,.05,{0,floor+.015,0},marble)
        k.b('LaunchWell',{1.9,.06,1.9},{0,floor+.04,-.1},well)
        for _,s in ipairs({-1,1})do
            local door=k.b('HatchDoor',{1.9,.1,.62},{0,floor+.17,-.1+s*1.27},ivory,ANG(-s*math.rad(24),0,0),'armor')
            G2(k.b('HatchStripe',{1.76,.02,.1},door.CFrame*CF(0,.06,s*.18),gold))
        end
        G2(k.c('SiloCollar',L==1 and .72 or .92,.3,{0,floor+.15,0},gold))
        local r,len=k.missiles(C(246,240,226),bright)
        local ch=2.0+.15*(L-1);local n=d and 8 or 4
        for i=0,n-1 do local a=i/n*PI*2+PI/8;column(math.cos(a)*1.72,math.sin(a)*1.72,floor,ch,.1)end
        local ring=halo(CF(0,floor+ch+.06,0),1.72,14,.22,.12)
        k.light(ring[1],lamp,7,.9)
        k.b('ServiceTower',{.42,3.2,.42},{-1.3,floor+1.6,-1.0},ivory,nil,'armor')
        G2(k.b('ObeliskTip',{.32,.32,.32},{-1.3,floor+3.28,-1.0},bright,ANG(PI/4,0,PI/4)))
        G2(k.b('ObeliskBand',{.46,.08,.46},{-1.3,floor+2.5,-1.0},gold))
        if d then k.lit(k.b('Window',{.06,.4,.2},{-1.08,floor+2.0,-1.0},warm))end
        banner(1.3,floor+1.4,1.15,.4,.75,ANG(0,-PI/4,0))
    elseif kind=='SAMLauncher'then
        k.b('Chassis',{1.95,.36,1.55},{.5,floor+.18,.5},ivory,nil,'armor')
        G2(k.b('ChassisTrim',{1.99,.06,1.59},{.5,floor+.36,.5},gold))
        G2(k.c('Turntable',.5,.16,{.5,floor+.44,.5},gold))
        local pack=CF(.5,floor+.95,.42)*ANG(math.rad(-40),0,0)
        local cols=L==1 and {-.29,.29}or {-.44,0,.44}
        G.part(k.m,'LauncherTube',V3(#cols*.44+.14,.22,1.0),pack*CF(0,-.38,-.1),marble,'armor')
        if not d then G.part(k.m,'Tube',V3(#cols*.44+.1,.84,1.5),pack*CF(0,.14,0),ivory,'armor')end
        for _,x in ipairs(d and cols or {})do for _,y in ipairs({-.08,.36})do
            local t=G.cylinder(k.m,'Tube',.21,1.6,pack*CF(x,y,0)*ANG(PI/2,0,0),ivory);t.Material=MAT.SmoothPlastic
            G2(G.cylinder(k.m,'MissileCap',.17,.06,pack*CF(x,y,.81)*ANG(PI/2,0,0),bright))
        end end
        k.c('RadarCabin',.62,.9,{-1.05,floor+.45,-.95},ivory)
        G2(k.c('CabinRim',.68,.1,{-1.05,floor+.9,-.95},gold))
        G2(k.dome('CabinDome',{1.1,.8,1.1},{-1.05,floor+.92,-.95},bright))
        G2(k.rod('RadarMast',{-1.05,floor+1.1,-.95},{-1.05,floor+1.75,-.95},.07,gold))
        local span=L>=3 and 2.05 or 1.8
        G2(G.part(k.m,'RadarDish',V3(span,.5,span),CF(-1.05,floor+2.0,-.95)*ANG(math.rad(48),math.rad(28),0),bright,'dish'))
        local ring=halo(CF(-1.05,floor+2.0,-.95)*ANG(.5,0,.2),1.2,12,-.5,.07)
        k.light(ring[1],lamp,7,.9)
        G2(k.rod('BannerPole',{1.6,floor,-1.5},{1.6,floor+1.9,-1.5},.04,gold))
        banner(1.6,floor+1.4,-1.47,.4,.7)
    end
end
T.orbital=function(k,kind)
    local cyan=k.A;local L,d=k.l,k.d
    local hullC=k.P:Lerp(C(84,104,134),.18);local trim=k.S:Lerp(C(150,180,205),.25);local deep=C(14,18,28);local glassTint=C(130,214,232)
    local function glow(p,t)return k.lit(p,t)end
    local function hull(p)p.Material=MAT.Metal;p.Reflectance=.18;return p end
    local function float(p,spec)spec=spec or {};spec.bob=spec.bob or .05;return k.move(p,spec)end
    local function seam(name,size,pos,rot)return glow(k.b(name,size,pos,cyan,rot),.05)end
    local function halo(name,center,R,n,spec,neon,h,t)
        for _,p in ipairs(k.ring(name,center,R,n,h or .12,t or .18,neon and cyan or trim,spec,1.06))do
            if neon then p.Material=MAT.Neon;p.CastShadow=false else p.Material=MAT.Metal;p.Reflectance=.15 end
        end
    end
    local function core(pos,size,spec)
        local ball=glow(k.ball('EnergyCore',size,pos,cyan))
        local shell=k.ball('CoreShell',size*1.4,pos,glassTint);shell.Material=MAT.Glass;k.fade(shell,.62);shell.CastShadow=false
        if spec then k.move(ball,spec);k.move(shell,spec)end
        k.light(ball,cyan,9,1.1);return ball
    end
    local function prism(name,size,pos,phase,lift,rot)
        local p=k.b(name,size,pos,cyan,rot or ANG(0,PI/4,0));p.Material=MAT.Neon;p.CastShadow=false
        return k.move(p,{hue=true,phase=phase,bob=.05,spin=.6,lift=lift,axis=CF(k.frame(pos).Position)})
    end
    local function deck(name,x,y,z,R,spec)
        local rim=glow(k.c(name..'Rim',R,.08,{x,y,z},cyan),.05);local top=hull(k.c(name,R-.12,.14,{x,y+.02,z},hullC))
        if spec then k.move(rim,spec);k.move(top,spec)end
    end
    local function emitter(x,z,R)
        glow(k.c('GravRing',R,.03,{x,floor+.01,z},cyan),.1)
        k.c('GravInner',R-.14,.04,{x,floor+.015,z},deep)
    end
    k.lot(kind,k.P,deep,MAT.Metal,MAT.Metal)
    if kind=='City'then
        local cx,cz=-.3,-.3;emitter(cx,cz,1.5)
        hull(k.c('Emitter',.7,.3,{cx,floor+.15,cz},hullC))
        deck('Deck',cx,floor+.62,cz,1.45,{lift=V3(0,.04,0),bob=.03})
        local n=L+1;local segH=.5;local gap=.12;local y=floor+.85
        for i=1,n do local r=.78-.07*i;local lift=V3(0,.04*i,0)
            float(hull(k.c(i==1 and 'TowerBlock1'or 'TowerSegment',r,segH,{cx,y+segH/2,cz},hullC)),{lift=lift,bob=.03,offset=i})
            float(glow(k.c('Seam',r+.015,.05,{cx,y+segH*.55,cz},cyan),.05),{lift=lift,bob=.03,offset=i})
            y+=segH+gap
        end
        local up=V3(0,.04*n+.01,0);local coreY=y+.34
        core({cx,coreY,cz},.74,{lift=up,bob=.04})
        halo('Halo',CF(cx,coreY,cz)*ANG(.22,0,.1),.9,d and 12 or 8,{spin=.5,lift=up},true)
        prism('TowerCrown',{.3,.5,.3},{cx,coreY+.76,cz},1,up)
        for i,t in ipairs({{1.1,-1.1,1.25+.25*(L-1)},{1.0,1.0,.85+.2*(L-1)}})do
            local x,z,h=t[1],t[2],t[3]
            float(hull(k.b('TowerBlock'..(i+1),{.72,h,.72},{x,floor+.4+h/2,z},hullC,ANG(0,PI/4,0),'armor')),{lift=V3(0,.06,0),offset=i*2})
            float(glow(k.b('Window',{.06,h*.8,.74},{x,floor+.4+h/2,z},cyan,ANG(0,PI/4,0)),.1),{lift=V3(0,.06,0),offset=i*2})
        end
        halo('Halo2',CF(cx,floor+2.0,cz)*ANG(.5,0,.2),1.35,d and 10 or 6,{spin=-.35,phase=2,lift=V3(0,.06,0)},false,.1,.14)
        local sat=CF(cx,floor+2.7,cz)
        for i=0,1 do local f=sat*ANG(0,i*PI,0)*CF(1.7,0,0)
            k.move(k.b('Satellite',{.36,.24,.24},f,trim,nil,'armor'),{axis=sat,spin=.7,phase=2})
            k.move(glow(k.b('SolarWing',{.08,.04,.7},f,cyan),.1),{axis=sat,spin=.7,phase=2})
        end
        halo('OuterRing',CF(cx,floor+.72,cz),1.95,d and 12 or 8,{spin=.25,phase=3},true,.08,.12)
    elseif kind=='DefensePost'then
        local h=.62+.16*(L-1);local s=3.3
        emitter(0,0,1.15)
        for i=0,3 do
            local f=ANG(0,i*PI/2,0)*CF(0,0,s/2-.25);local out=(f.Position).Unit;local lift=out*.08+V3(0,.05,0)
            float(hull(k.b('Wall',{s-1.2,h,.32},CF(0,floor+.42+h/2,0)*f,hullC,nil,'armor')),{lift=lift,offset=i})
            float(seam('WallSeam',{s-1.25,.06,.34},CF(0,floor+.42+h,0)*f),{lift=lift,offset=i})
        end
        for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            hull(k.b('Bastion',{.44,h+.9,.44},{c[1]*1.5,floor+(h+.9)/2,c[2]*1.5},hullC,ANG(0,PI/4,0),'armor'))
            float(glow(k.b('BastionCap',{.32,.32,.32},{c[1]*1.5,floor+h+1.2,c[2]*1.5},cyan,ANG(PI/4,0,PI/4)),.05),{bob=.06,offset=c[1]+c[2]*2})
        end
        local coreY=floor+1.2+.15*(L-1)
        hull(k.c('BunkerCore',.55,.4,{0,floor+.2,0},hullC))
        core({0,coreY,0},.9,{bob=.05,lift=V3(0,.1,0)})
        halo('Halo',CF(0,coreY,0),1.0,d and 12 or 8,{spin=.6,lift=V3(0,.1,0)},true)
        prism('TowerCrown',{.3,.65,.3},{0,coreY+.98,0},1,V3(0,.1,0))
        halo('GyroRing',CF(0,coreY,0)*ANG(PI/2,0,0),1.2,d and 10 or 6,{spin=.8,phase=2,lift=V3(0,.1,0)},false,.1,.12)
        local dome=k.dome('ShieldDome',{3.9,2.9,3.9},{0,floor+.3,0},glassTint);dome.Material=MAT.Glass;k.fade(dome,.74);dome.CastShadow=false
        k.move(dome,{phase=3})
        k.move(glow(k.c('ShieldRim',1.95,.06,{0,floor+.32,0},cyan),.1),{phase=3})
        k.flag(-1.5,-1.5,floor+h+1.3,1.0,trim,k.owner,true)
        if L>=2 then for _,x in ipairs({-.55,.55})do float(hull(k.b('Gatehouse',{.3,h+.5,.36},{x,floor+.42+(h+.5)/2,s/2-.25},hullC,nil,'armor')),{lift=V3(0,0,.08)})end
            float(seam('GateNeon',{.8,.07,.07},{0,floor+.42+h+.4,s/2-.25}),{lift=V3(0,0,.08)})end
    elseif kind=='Port'then
        k.b('Basin',{4.3,.06,2.5},{0,.03,.95},C(20,54,92))
        for _,s in ipairs({-1,1})do hull(k.b('Pier',{.42,.26,2.4},{s*1.94,.13,.95},hullC,nil,'armor'));seam('PierGlow',{.05,.03,2.4},{s*1.72,.27,.95})end
        local H=2.0+.2*(L-1);local top=floor+H
        for _,x in ipairs({-.55,.55})do hull(k.b('CraneLeg',{.22,H,.55},{x,floor+H/2,-1.3},hullC,nil,'armor'));seam('LegSeam',{.04,H*.8,.04},{x,floor+H/2,-1.0})end
        hull(k.b('CranePortal',{1.4,.26,.75},{0,top,-1.3},hullC,nil,'armor'))
        hull(k.b('CraneBoom',{.38,.26,3.7},{0,top+.26,.3},hullC,nil,'armor'))
        for _,x in ipairs({-.15,.15})do seam('BoomSeam',{.05,.05,3.7},{x,top+.4,.3})end
        local up=V3(0,.08,0)
        core({0,top+.62,-1.3},.66,{bob=.04,lift=up})
        halo('Halo',CF(0,top+.62,-1.3)*ANG(.2,0,0),.7,d and 12 or 8,{spin=.6,lift=up},true,.1,.14)
        prism('TowerCrown',{.26,.5,.26},{0,top+1.3,-1.3},1,up)
        local beam=k.lit(k.c('TractorBeam',.26,top-.75,{0,(top+.75)/2+.1,1.6},cyan),.7);beam.CastShadow=false
        float(k.b('Container',{.6,.36,.6},{0,1.35,1.6},k.owner,nil,'armor'),{bob=.1,freq=1.1,lift=V3(0,.18,0)})
        local ship={hull(k.b('Hull',{2.5,.34,.8},{-.25,.42,1.15},hullC,nil,'armor')),hull(k.w('Bow',{.8,.34,.6},{1.3,.42,1.15},hullC,ANG(0,-PI/2,0))),
            seam('HullGlow',{2.5,.05,.82},{-.25,.3,1.15}),k.b('Deck',{2.2,.04,.6},{-.25,.6,1.15},trim),glow(k.b('Bridge',{.5,.36,.56},{-1.15,.78,1.15},glassTint),.35)}
        for _,p in ipairs(ship)do float(p,{bob=.04,freq=1.3})end
        hull(k.b('ControlPod',{.5,.8+.2*(L-1),.5},{1.5,floor+.4+.1*(L-1),-1.5},hullC,ANG(0,PI/4,0),'armor'))
        seam('PodCap',{.36,.05,.36},{1.5,floor+.82+.2*(L-1),-1.5},ANG(0,PI/4,0))
        local hub=CF(0,top+.62,-1.3)
        for i=0,1 do local f=hub*ANG(0,i*PI,0)*CF(1.25,.2,0)
            k.move(k.b('Satellite',{.3,.2,.2},f,trim,nil,'armor'),{axis=hub,spin=.8,phase=2})
            k.move(glow(k.b('SolarWing',{.06,.03,.55},f,cyan),.1),{axis=hub,spin=.8,phase=2})
        end
        halo('LaunchRing',CF(0,1.0,1.6),1.0,d and 12 or 8,{spin=-.5,phase=3},true,.08,.12)
    elseif kind=='Factory'then
        for _,z in ipairs({.95,-.2})do
            hull(k.b('Ballast',{5.5,.1,.42},{.5,floor+.12,z},hullC,nil,'armor'))
            seam('Rail',{5.5,.03,.08},{.5,floor+.18,z})
        end
        for gi,gt in ipairs({{-1.35,'GateRing',false},{2.0,'ExitGate',true}})do
            local axis=CF(gt[1],floor+1.0,.375)*ANG(0,0,PI/2)
            halo(gt[2],axis,1.02,d and 12 or 8,{spin=gi==1 and .5 or -.6},gt[3],.12,.18)
        end
        k.b('ExitGateBand',{.22,.12,.8},{2.0,floor+2.12,.375},k.owner)
        local train={hull(k.c('Locomotive',.28,1.7,{.5,floor+.6,.95},hullC,ANG(0,0,PI/2))),hull(k.dome('LocoNose',{.8,.56,.56},{1.35,floor+.6,.95},hullC)),
            seam('LocoStripe',{2.2,.06,.58},{.6,floor+.6,.95}),k.b('LocoOwner',{1.0,.08,.4},{.3,floor+.88,.95},k.owner),
            hull(k.c('CargoWagon',.25,1.1,{-1.0,floor+.6,.95},hullC,ANG(0,0,PI/2))),glow(k.c('TrainCab',.14,1.0,{-1.0,floor+.6,.95},glassTint,ANG(0,0,PI/2)),.2)}
        for _,p in ipairs(train)do float(p,{bob=.04,freq=2,lift=V3(0,.05,0)})end
        float(hull(k.b('Platform',{3.4,.14,.55},{0,floor+.35,-1.05},hullC,nil,'armor')),{bob=.03})
        float(seam('PlatformEdge',{3.4,.04,.05},{0,floor+.43,-.78}),{bob=.03})
        if L>=2 then float(hull(k.c('TankWagon',.22,1.2,{1.05,floor+.5,-.2},hullC,ANG(0,0,PI/2))),{bob=.04})
            float(hull(k.b('ShuntEngine',{.8,.36,.46},{-.15,floor+.5,-.2},hullC,nil,'armor')),{bob=.04,offset=.6})
            float(seam('ShuntSeam',{.82,.05,.48},{-.15,floor+.52,-.2}),{bob=.04,offset=.6})
        end
        if L>=3 then
            float(hull(k.dome('CargoPod',{.9,.42,.42},{-1.3,floor+.5,-.2},hullC)),{bob=.04,offset=1.2})
            float(glow(k.c('PodSeam',.225,.05,{-1.3,floor+.5,-.2},cyan,ANG(0,0,PI/2)),.05),{bob=.04,offset=1.2})
        end
        hull(k.c('StationPylon',.16,.9,{0,floor+.45,-1.55},hullC))
        core({0,floor+1.32,-1.55},.6,{bob=.04})
        prism('TowerCrown',{.24,.42,.24},{0,floor+1.98,-1.55},1)
        local canopy=k.b('StationCanopy',{3.3,.08,.8},{0,floor+1.16,-1.1},glassTint,ANG(.12,0,0),'armor');canopy.Material=MAT.Glass;canopy.Reflectance=.2;k.fade(canopy,.35)
        float(canopy,{phase=2,bob=.03,lift=V3(0,.06,0)})
        float(seam('CanopyEdge',{3.3,.04,.06},{0,floor+1.12,-.72}),{phase=2,bob=.03,lift=V3(0,.06,0)})
        for _,x in ipairs({-1.5,1.5})do prism('Prism',{.2,.5,.2},{x,floor+.85,-1.1},3)end
    elseif kind=='MissileSilo'then
        glow(k.c('HazardRing',1.35,.04,{0,floor+.01,0},cyan),.1)
        k.c('RingInner',1.12,.05,{0,floor+.015,0},deep)
        k.b('LaunchWell',{1.9,.06,1.9},{0,floor+.04,-.1},well)
        glow(k.c('SiloCollar',L==1 and .72 or .92,.06,{0,floor+.08,0},cyan),.25)
        core({0,floor+.34,0},.56)
        for i=0,3 do
            local a=i*PI/2+PI/4;local f=ANG(0,a,0)*CF(0,floor+.35,-1.3)*ANG(-.5,0,0);local lift=(ANG(0,a,0)*V3(0,0,-1))*.1+V3(0,.12,0)
            float(hull(k.b('HatchDoor',{1.0,.1,.6},f,hullC,nil,'armor')),{lift=lift,offset=i})
            float(seam('HatchStripe',{.8,.02,.06},f*CF(0,.06,0)),{lift=lift,offset=i})
        end
        local r,len=k.missiles(C(232,244,252),cyan:Lerp(C(255,255,255),.4),floor+.6,{bob=.05,lift=V3(0,.06,0)})
        halo('LevRing',CF(0,floor+.8,0),L==1 and .8 or 1.2,d and 12 or 8,{spin=.8},true)
        halo('LevRing2',CF(0,floor+1.9,0)*ANG(.35,0,0),L==1 and 1.05 or 1.4,d and 10 or 6,{spin=-.5,phase=2,lift=V3(0,.08,0)},false,.1,.14)
        prism('TowerCrown',{.3,.6,.3},{0,floor+.6+len+.85,0},1,V3(0,.06,0))
        for i=1,3 do local lift=V3(0,.06*i,0)
            float(hull(k.b('ServiceTower',{.36,.8,.36},{-1.4,floor+.25+i*.95,-.75},hullC,ANG(0,PI/4,0),'armor')),{lift=lift,offset=i})
            float(seam('PylonJoint',{.28,.07,.28},{-1.4,floor+.25+i*.95+.47,-.75},ANG(0,PI/4,0)),{lift=lift,offset=i})end
        for _,s in ipairs({-1,1})do prism('Prism',{.2,.45,.2},{s*1.25,floor+1.1,.6},3)end
    elseif kind=='SAMLauncher'then
        emitter(.5,.5,.95);emitter(-1.05,-.95,.8)
        hull(k.b('Chassis',{1.6,.24,1.3},{.5,floor+.12,.5},hullC,nil,'armor'))
        local pack=CF(.5,floor+1.1,.42)*ANG(math.rad(-40),0,0)
        local cols=L==1 and {-.29,.29}or {-.44,0,.44}
        local launcher={hull(G.part(k.m,'LauncherTube',V3(#cols*.44+.14,.22,1.0),pack*CF(0,-.38,-.1),hullC,'armor'))}
        if not d then table.insert(launcher,hull(G.part(k.m,'Tube',V3(#cols*.44+.1,.84,1.5),pack*CF(0,.14,0),hullC,'armor')))end
        for _,x in ipairs(d and cols or {})do for _,y in ipairs({-.08,.36})do
            table.insert(launcher,hull(G.cylinder(k.m,'Tube',.21,1.6,pack*CF(x,y,0)*ANG(PI/2,0,0),hullC:Lerp(trim,.2))))
            table.insert(launcher,glow(G.cylinder(k.m,'MissileCap',.17,.05,pack*CF(x,y,.81)*ANG(PI/2,0,0),cyan),.02))
        end end
        for _,p in ipairs(launcher)do float(p,{bob=.04,lift=V3(0,.06,0)})end
        hull(k.c('RadarCabin',.45,.4,{-1.05,floor+.2,-.95},hullC))
        core({-1.05,floor+.95,-.95},.6)
        halo('Halo',CF(-1.05,floor+.95,-.95)*ANG(.2,0,0),.66,d and 12 or 8,{spin=.7},true,.1,.14)
        glow(k.rod('RadarMast',{-1.05,floor+1.25,-.95},{-1.05,floor+2.1,-.95},.06,cyan),.1)
        local span=L>=3 and 2.0 or 1.75
        k.mat(G.part(k.m,'RadarDish',V3(span,.5,span),CF(-1.05,floor+2.35,-.95)*ANG(math.rad(48),math.rad(28),0),trim,'dish'),MAT.Metal,.12)
        prism('TowerCrown',{.24,.5,.24},{.5,floor+2.25,.5},1)
        local sat=CF(-.3,floor+2.4,-.3)
        for i=0,2 do
            local f=sat*ANG(0,i*PI*2/3,0)*CF(1.75,0,0)
            k.move(k.b('Satellite',{.4,.26,.26},f,trim,nil,'armor'),{axis=sat,spin=.5,phase=i==0 and 2 or i+1,bob=.05})
            k.move(glow(k.b('SolarWing',{.06,.03,.8},f,cyan),.1),{axis=sat,spin=.5,phase=i==0 and 2 or i+1,bob=.05})
        end
        halo('OuterRing',CF(-.2,floor+1.5,-.2)*ANG(.3,0,-.15),2.05,d and 12 or 8,{spin=-.25,phase=3},true,.07,.11)
    end
end
local motion={field=0,polar=0,neon=1,imperial=3,orbital=4}
require(script.Parent.BuildingVolume).register(T,motion,kit)
require(script.Parent.BuildingVolume2).register(T,motion,kit)
function M.has(style)return style and style.tier~=nil and T[style.theme]~=nil end
local Meshes=require(script.Parent.CosmeticMeshes)
local levelScale={.84,.92,1}
local farDrop={Bush=true,Door=true,Win=true,Slit=true,Cable=true,Cargo=true}
local function meshKey(style,kind)return style.id and style.id..'/'..kind end
local function meshFill(model,kind,style,level,detailed,owner)
    local key=meshKey(style,kind);local tier=style.tier or 0
    local top,half,px,wide=.3,2.25,0,2.25
    local turn=CFrame.Angles(0,PI,0)
    for _,e in ipairs(Meshes.rig(key).parts)do if e.def.name=='Plinth'then
        local p,z=e.def.pos,e.def.size;top=p[2]+z[2]/2;half=-p[3]+z[3]/2;px=-p[1];wide=z[1]/2
    end end
    local list=Meshes.build(model,key,{origin=turn,colors={team=owner,primary=rgb(style.primary),secondary=rgb(style.secondary),accent=rgb(style.accent)},
        heroScale=levelScale[level],heroBase=V3(0,top,0),groundCap=5,keep=function(e)
            local d=e.def;local z=d.size
            local n=d.name:match('^Missile(%d*)$');if n and (tonumber(n)or 1)>level then return false end
            if not detailed and style.id=='default_buildings'and farDrop[d.name]then return false end
            if not detailed and d.name:sub(-3)=='Top'then return d.name=='RoofRimTop'or d.name=='RoofHaloTop'or d.name=='RoofCrownTop'end
            return detailed or e.kind~=nil or V3(z[1],z[2],z[3]).Magnitude>=.45
        end})
    if not list then return nil end
    local crest=Meshes.crestKind(key,tier,'buildings')
    if crest then
        local roof=top;for _,r in ipairs(list)do if r.def.name~='Plinth'then roof=math.max(roof,r.home.Y+r.part.Size.Y/2)end end
        Meshes.crest(model,list,crest,CF(0,roof+.22,0),half*.55,rgb(style.accent),not detailed)
    end
    local items={};local rate=tier>=5 and 1.2 or tier>=4 and 1 or .8;local tallest,highest
    local authored=false;for _,r in ipairs(list)do if r.phase and not r.crest then authored=true end end
    local grow=tier==5 and not authored
    for _,r in ipairs(list)do
        local hue=Meshes.prismatic(r,tier);local phase=r.phase;local glow=grow and not r.crest and r.def.material=='Neon'and r.tint~='team'
        if r.kind or phase or hue or glow then
            local it={part=r.part,home=r.home,color=r.part.Color,phase=phase,hue=hue or nil}
            if r.kind or glow then it.fn=function(t,ph)return r.kind and Meshes.motion(r,t,0,rate)or nil,glow and({.5,.25,0})[ph]or nil end end
            table.insert(items,it)
        end
        if r.def.material=='Neon'and(not tallest or r.home.Y>tallest.home.Y)then tallest=r end
        if r.tint~='team'and(not highest or r.home.Y>highest.home.Y)then highest=r end
        if r.part.Size.Magnitude<.7 then r.part.CastShadow=false end
    end
    tallest=tallest or highest
    local fit=math.min(1,wide/2.25)
    local function tab(name,w,x,color)
        local p=G.block(model,name,V3(w,.12,.06),CF(px+x*fit,top*.55,half+.03),color);p.CastShadow=false;return p
    end
    local beacon=tab('StatusBeacon',.42,-1.5,ice);beacon.Material=MAT.Neon;beacon.Transparency=.08
    if level>=2 then tab('LevelStripe',.36+.22*(level-2),1.3,C(245,196,81))end
    if kind=='MissileSilo'and not model:FindFirstChild('Missile')then
        for i=1,level do local p=tab(i==1 and 'Missile'or 'Missile'..i,.22,-.98+(i-1)*.32,ice);p.Material=MAT.Neon end
    end
    for i=1,3 do local missile=model:FindFirstChild(i==1 and 'Missile'or 'Missile'..i);if missile then missile:SetAttribute('ReadyColor',missile.Color)end end
    local light
    if tier>=4 and tallest then
        light=Instance.new('PointLight');light.Name='CollectionLight';light.Color=tallest.part.Color;light.Range=6;light.Brightness=.8;light.Shadows=false;light.Parent=tallest.part
    end
    local kinds={};local movers=0;for _,r in ipairs(list)do if r.kind then movers+=1;kinds[r.kind]=true end end
    local n=0;for _ in pairs(kinds)do n+=1 end
    model:SetAttribute('MeshItem',key);model:SetAttribute('CollectionMotion',n);model:SetAttribute('RoleKineticParts',movers)
    model:SetAttribute('CollectionArchitecture','mesh:'..key)
    return {items=items,tier=tier,light=light}
end
local function attributes(model,kind,style,tier)
    model:SetAttribute('CollectionTier',tier);model:SetAttribute('CollectionStyle',style.id);model:SetAttribute('CollectionRole',kind)
    model:SetAttribute('CollectionPhases',tier==5 and 3 or 1);model:SetAttribute('CollectionParticles',0)
end
local function meshSwap(model,kind,style,level,detailed,owner)
    if not states[model]then return end
    local pivot,scale=model:GetPivot(),model:GetScale()
    for _,c in ipairs(model:GetChildren())do if c:IsA('BasePart')then c:Destroy()end end
    if scale~=1 then model:ScaleTo(1)end
    model.WorldPivot=CFrame.identity
    local state=meshFill(model,kind,style,level,detailed,owner);if not state then return end
    states[model]=state
    if scale~=1 then model:ScaleTo(scale)end
    model:PivotTo(pivot)
    local building=model:GetAttribute('Building')==true
    for _,p in ipairs(model:GetChildren())do if p:IsA('BasePart')then p.Transparency=math.max(p:GetAttribute('BaseTransparency')or p.Transparency,building and .55 or 0)end end
    model:SetAttribute('DisplayStatus',nil);model:SetAttribute('ReadyMissiles',nil);model:SetAttribute('PartCount',#model:GetChildren())
    M.step(model,0,true)
end
function M.create(kind,style,level,detailed,ownerColor)
    local model=Instance.new('Model');model.Name=kind
    local owner=ownerColor or rgb(style.territory or style.accent)
    local key=meshKey(style,kind)
    local state=key and Meshes.ready(key)and meshFill(model,kind,style,level,detailed,owner)
    if not state then
        local k=kit(model,style,level,detailed,owner)
        T[style.theme](k,kind)
        state={items=k.items,tier=k.tier,light=k.lamp}
        model:SetAttribute('CollectionMotion',motion[style.theme]);model:SetAttribute('CollectionArchitecture',style.theme..':'..kind);model:SetAttribute('RoleKineticParts',#k.items)
        if key then Meshes.watchModel(key,model,function()meshSwap(model,kind,style,level,detailed,owner)end)end
    end
    states[model]=state
    attributes(model,kind,style,state.tier)
    model.WorldPivot=CFrame.identity
    M.step(model,0,true,3)
    return model
end
M.defaultMeshes=true
local defaultStyle={id='default_buildings',tier=0,primary={243,235,221},secondary={226,214,194},accent={245,196,81}}
function M.defaultKey(kind)local key='default_buildings/'..kind;return M.defaultMeshes and Meshes.has(key)and key or nil end
function M.prefetchDefault()for _,kind in ipairs({'City','DefensePost','Port','Factory','MissileSilo','SAMLauncher'})do local key=M.defaultKey(kind);if key then Meshes.request(key)end end end
function M.createDefault(kind,level,detailed,owner,block)
    local key=M.defaultKey(kind)
    if key and Meshes.ready(key)then
        local model=Instance.new('Model');model.Name=kind
        local state=meshFill(model,kind,defaultStyle,level,detailed,owner)
        if state then states[model]=state;model.WorldPivot=CFrame.identity;M.step(model,0,true);return model end
        model:Destroy()
    end
    local model=block()
    if key then states[model]={items={},tier=0};Meshes.watchModel(key,model,function()meshSwap(model,kind,defaultStyle,level,detailed,owner)end)end
    return model
end
function M.step(model,at,reduced,phase,batch)
    local st=states[model];if not st then return false end
    phase=st.tier==5 and math.clamp(phase or model:GetAttribute('CollectionPhase')or 1+math.floor(at/2.5)%3,1,3)or 1
    local pivot,scale=model:GetPivot(),model:GetScale();local building=model:GetAttribute('Building')==true
    if reduced and st.lastReduced and st.lastPivot==pivot and st.lastScale==scale and st.lastPhase==phase and st.lastBuilding==building then return true end
    local moved=st.lastPivot~=pivot or st.lastScale~=scale or st.lastPhase~=phase or st.lastReduced~=reduced
    st.lastReduced,st.lastPivot,st.lastScale,st.lastPhase,st.lastBuilding=reduced,pivot,scale,phase,building
    if st.light then st.light.Enabled=not reduced end
    local fade=building and .55 or 0
    for i,it in ipairs(st.items)do
        local p=it.part;if not p.Parent then continue end
        local cf=it.home;it.tr=nil
        local still=reduced or not(it.fn or it.sway or it.spin or it.bob)
        if not reduced then
            local t=at+(it.offset or 0)
            if it.fn then local pre;pre,it.tr=it.fn(t,phase);if pre then cf=pre*cf end end
            if it.sway then local pv=it.pivot or V3();local a=math.sin(t*1.4+i)*it.sway
                cf=cf*CF(pv)*(it.axisX and ANG(a,0,0)or ANG(0,0,a))*CF(-pv)end
            if it.spin then local ax=it.axis;cf=ax*ANG(0,at*it.spin,0)*ax:Inverse()*cf end
            if it.bob then cf=CF(0,math.sin(t*(it.freq or 1.6)+i*.3)*it.bob,0)*cf end
        end
        if it.lift then cf=CF(it.lift*(phase-1))*cf end
        if it.hue then p.Color=reduced and it.color or Color3.fromHSV(.5+.14*(1+math.sin(at*.4+i*.6)),.62,.95)end
        local base=it.base;if base==nil then base=p:GetAttribute('BaseTransparency')or 0;it.base=base end
        local alpha=(it.phase and phase<it.phase)and 1 or math.max(it.tr or base,fade)
        if math.abs(p.Transparency-alpha)>1e-4 then p.Transparency=alpha end
        if moved or not still then
            local world=pivot*CF(cf.Position*scale)*(cf-cf.Position)
            if batch then batch:put(p,world)else p.CFrame=world end
        end
    end
    return true
end
return M
