local T={}
local V=Vector3.new
local UP=Vector3.yAxis
local NEON,METAL,SMOOTH,ICE,GLASS=Enum.Material.Neon,Enum.Material.Metal,Enum.Material.SmoothPlastic,Enum.Material.Ice,Enum.Material.Glass
local ZC=CFrame.Angles(0,math.pi/2,0)
local FLAT=CFrame.Angles(0,0,math.pi/2)
local TAU=math.pi*2
local function k(t,a,b)return math.clamp((t-a)/(b-a),0,1)end
local function out2(x)return 1-(1-x)^2 end
local function out4(x)return 1-(1-x)^4 end
local function in2(x)return x*x end
local function hash(a,b)local x=math.sin(a*12.9898+b*78.233)*43758.5453;return x-math.floor(x)end
local function hue(h)
    local f=h%1;local tri=1-math.abs(2*f-1)
    return Color3.fromHSV(.45+.47*tri,.72-.6*math.max(0,(tri-.8)/.2),1)
end
T.k,T.out2,T.out4,T.in2,T.hash,T.hue=k,out2,out4,in2,hash,hue

function T.part(parent,name,size,cf,color,material,transparency,shape)
    local p=Instance.new(shape=='wedge'and'WedgePart'or'Part');p.Name=name
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
    p.Material=material or SMOOTH;p.Color=color;p.Transparency=transparency or 0
    if shape=='ell'then local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
    elseif shape=='ball'then p.Shape=Enum.PartType.Ball elseif shape=='cyl'then p.Shape=Enum.PartType.Cylinder end
    p.Size=size;p.CFrame=cf;p.Parent=parent;return p
end
function T.span(p,a,b,th)
    local d=(b-a).Magnitude;if d<1e-3 then p.Transparency=1;return end
    p.Size=V(th,th,d);p.CFrame=CFrame.lookAt((a+b)/2,b)
end
function T.placeRing(list,center,r,rot,th,fill)
    local n=#list;local len=math.max(.02,TAU*r/n*(fill or .62))
    for i,p in ipairs(list)do p.Size=V(len,th,th*1.6);p.CFrame=center*CFrame.Angles(0,rot+i/n*TAU,0)*CFrame.new(0,0,-r)end
end

local W={}
W.classic=function(b)
    local s,w=b.s,b.w
    b.rod('Airframe',-.8*s,.7*s,.2*s,w.body)
    b.add('Nose',V(.4,.4,.4)*s,CFrame.new(0,0,-.85*s),w.nose,SMOOTH,0,'ball')
    b.band(-.35*s,-.15*s,.21*s)
    for i=0,3 do b.add('Fin',V(.04,.42,.35)*s,CFrame.new(0,0,.55*s)*CFrame.Angles(0,0,i*math.pi/2)*CFrame.new(0,.25*s,0),w.fins)end
    return {tail=.8*s,tailSize=.34*s,band2={.3*s,.42*s,.21*s},nose=-1.02*s,noseR=.14*s}
end
W.steel=function(b)
    local s,w=b.s,b.w
    b.add('Airframe',V(.5,.5,1.3)*s,CFrame.new(0,0,-.15*s),w.body,METAL,0,'ell')
    b.rod('TailCone',.28*s,.56*s,.16*s,w.body,METAL);b.rod('TailCone',.56*s,.76*s,.11*s,w.nose,METAL)
    b.rod('Fuze',-.92*s,-.76*s,.045*s,w.trim,METAL)
    b.rod('NoseStripe',-.6*s,-.55*s,.19*s,w.stripe)
    b.rod('Seam',-.01*s,.02*s,.248*s,w.trim,METAL)
    b.band(-.42*s,-.3*s,.245*s)
    for i=0,3 do
        local a=CFrame.Angles(0,0,i*math.pi/2)
        b.add('Fin',V(.035,.27,.36)*s,CFrame.new(0,0,.62*s)*a*CFrame.new(0,.2*s,0),w.fins,METAL)
        b.add('TailBox',V(.47,.025,.2)*s,CFrame.new(0,0,.7*s)*CFrame.Angles(0,0,i*math.pi/2+math.pi/4)*CFrame.new(0,.235*s,0),w.fins,METAL)
        local r=CFrame.Angles(0,0,i*math.pi/2+math.pi/4)
        b.add('Rivet',V(.05,.05,.05)*s,CFrame.new(0,0,-.2*s)*r*CFrame.new(0,.248*s,0),w.trim,METAL,0,'ball')
        b.add('Rivet',V(.05,.05,.05)*s,CFrame.new(0,0,.34*s)*r*CFrame.new(0,.163*s,0),w.trim,METAL,0,'ball')
    end
    return {tail=.84*s,tailSize=.26*s,band2={.14*s,.24*s,.225*s},nose=-.95*s,noseR=.12*s}
end
W.cryo=function(b)
    local s,w=b.s,b.w
    local function hex(name,z0,z1,a,color,material,tr)
        for i=0,2 do b.add(name,V(a,a*1.732,z1-z0),CFrame.new(0,0,(z0+z1)/2)*CFrame.Angles(0,0,i*math.pi/3),color,material,tr)end
    end
    hex('IceShell',-.6*s,.5*s,.24*s,w.body,ICE,.22)
    b.rod('ColdCore',-.56*s,.46*s,.085*s,w.core,NEON)
    hex('IceTip',-.76*s,-.6*s,.16*s,w.body,ICE,.15);hex('IceTip',-.9*s,-.76*s,.09*s,w.nose,ICE,.1)
    b.add('IceTip',V(.06,.06,.2)*s,CFrame.new(0,0,-1*s)*CFrame.Angles(0,0,math.pi/4),w.nose,GLASS)
    b.band(-.36*s,-.24*s,.25*s)
    b.rod('TailRing',.5*s,.64*s,.16*s,w.trim,METAL)
    local tips={}
    for i=0,2 do
        local a=CFrame.Angles(0,0,math.pi/2+i*TAU/3)
        b.add('FrostFin',V(.03,.34,.46)*s,CFrame.new(0,0,.36*s)*a*CFrame.new(0,.38*s,0),w.fins,ICE,.12)
        for j,side in ipairs({-1,1})do
            b.add('Frost',V(.025,.16,.025)*s,CFrame.new(0,0,(.2+j*.16)*s)*a*CFrame.new(0,.58*s,0)*CFrame.Angles(.5,0,side*.5),w.nose,GLASS)
        end
        table.insert(tips,(CFrame.new(0,0,.58*s)*a*CFrame.new(0,.54*s,0)).Position)
    end
    for i,c in ipairs({{-.32,.6},{-.05,2.6},{.18,4.4},{-.46,3.7}})do
        local p=b.add('Crystal',V(.07,.07,.18)*s,CFrame.new(0,0,c[1]*s)*CFrame.Angles(0,0,c[2])*CFrame.new(0,.24*s,0)*CFrame.Angles(-.7,0,.785),i<=2 and w.core or w.nose,i<=2 and NEON or GLASS,i<=2 and .2 or 0)
    end
    return {tail=.72*s,tailSize=.26*s,band2={.2*s,.3*s,.25*s},nose=-1.05*s,noseR=.12*s,tips=tips}
end
W.plasma=function(b)
    local s,w=b.s,b.w
    for _,z in ipairs({{-.5,-.2},{-.16,.16},{.2,.5}})do local seg=b.rod('Capsule',z[1]*s,z[2]*s,.19*s,w.body);seg.Reflectance=.25 end
    for _,z in ipairs({-.2,.16})do b.rod('PlasmaSeam',z*s,(z+.04)*s,.196*s,w.core,NEON)end
    b.add('Nose',V(.4,.4,.64)*s,CFrame.new(0,0,-.5*s),w.nose,SMOOTH,0,'ell')
    b.add('PlasmaTip',V(.12,.12,.12)*s,CFrame.new(0,0,-.8*s),w.core,NEON,0,'ball')
    b.add('Tail',V(.4,.4,.32)*s,CFrame.new(0,0,.5*s),w.fins,SMOOTH,0,'ell')
    b.rod('EmitterCollar',.6*s,.72*s,.16*s,w.fins,METAL)
    for i=0,3 do b.add('EmitterNode',V(.075,.075,.075)*s,CFrame.new(0,0,.66*s)*CFrame.Angles(0,0,math.pi/4+i*math.pi/2)*CFrame.new(0,.165*s,0),w.glow,NEON,0,'ball')end
    for i=0,3 do b.add('PlasmaWindow',V(.035,.035,.62)*s,CFrame.new(0,0,.02*s)*CFrame.Angles(0,0,math.pi/4+i*math.pi/2)*CFrame.new(0,.188*s,0),w.core,NEON)end
    for i=0,3 do
        local cf=CFrame.new(0,0,.42*s)*CFrame.Angles(0,0,i*math.pi/2)*CFrame.new(0,.29*s,0)*CFrame.Angles(-.35,0,0)
        b.add('Fin',V(.03,.22,.34)*s,cf,w.fins);b.add('FinEdge',V(.04,.03,.34)*s,cf*CFrame.new(0,.11*s,0),w.core,NEON)
    end
    b.band(-.42*s,-.3*s,.2*s)
    for ring=0,1 do
        local dashes=b.ring('PlasmaRing',6,w.glow)
        b.move(dashes,function(t,_,_,list)
            local f=(t*.55+ring*.5)%1;local z=(.42-.9*f)*s;local fade=math.min(f/.15,(1-f)/.15,1)
            local r=(.26+.05*math.sin(f*math.pi))*s
            for i,p in ipairs(list)do
                p.Transparency=1-fade*.95
                p.Size=V(TAU*r/6*.6,.045*s,.07*s);p.CFrame=CFrame.new(0,0,z)*CFrame.Angles(0,0,t*1.6*(ring==0 and 1 or -1)+i/6*TAU)*CFrame.new(0,r,0)
            end
        end)
    end
    return {tail=.76*s,tailSize=.26*s,band2={.26*s,.36*s,.2*s},nose=-.82*s,noseR=.12*s}
end
W.sun=function(b)
    local s,w=b.s,b.w
    local shaft=b.rod('Lance',-.5*s,.86*s,.095*s,w.body,METAL);shaft.Reflectance=.15
    b.rod('Socket',-.62*s,-.46*s,.13*s,w.fins,METAL)
    for _,z in ipairs({.3,.55})do b.rod('LanceCollar',z*s,(z+.04)*s,.11*s,w.trim,NEON)end
    local head={}
    for _,roll in ipairs({0,math.pi/2})do for _,p in ipairs(b.blade('SpearHead',CFrame.new(0,0,-.97*s)*CFrame.Angles(0,0,roll),.72*s,.21*s,.035*s,w.nose,METAL))do table.insert(head,p)end end
    for _,roll in ipairs({math.pi/4,-math.pi/4})do for _,p in ipairs(b.blade('SpearBarb',CFrame.new(0,0,-.72*s)*CFrame.Angles(0,0,roll),.32*s,.13*s,.03*s,w.body,METAL))do table.insert(head,p)end end
    b.move(head,function(t,_,_,list,homes)for i,p in ipairs(list)do p.CFrame=CFrame.Angles(0,0,t*.9)*homes[i]end end)
    b.add('SpearGlow',V(.17,.17,.17)*s,CFrame.new(0,0,-.62*s),w.core,NEON,0,'ball')
    b.rod('Hub',-.02*s,.12*s,.14*s,w.fins,METAL)
    local core=b.add('SunCore',V(.3,.3,.3)*s,CFrame.new(0,0,.05*s),w.core,NEON,0,'ball')
    local halo=b.add('SunHalo',V(.8,.8,.8)*s,CFrame.new(0,0,.05*s),w.glow,NEON,.8,'ball')
    local light=Instance.new('PointLight');light.Name='SunLight';light.Color=w.glow;light.Brightness=1.4;light.Range=math.max(4,s*4);light.Shadows=false;light.Parent=core
    local vanes={}
    for i=0,7 do
        local long=i%2==0;local L=(long and .56 or .36)*s
        local cf=CFrame.new(0,0,.07*s)*CFrame.Angles(0,0,i/8*TAU)*CFrame.new(0,.13*s+L/2,0)*CFrame.Angles(math.pi/2,0,0)*CFrame.Angles(0,0,math.pi)
        table.insert(vanes,b.add('FlareVane',V(.03*s,(long and .24 or .16)*s,L),cf,long and w.body or w.glow,long and METAL or NEON,0,'wedge'))
        if long then table.insert(vanes,b.add('VaneTip',V(.07,.07,.07)*s,CFrame.new(0,0,.03*s)*CFrame.Angles(0,0,i/8*TAU)*CFrame.new(0,.13*s+L,0),w.core,NEON,0,'ball'))end
    end
    b.move(vanes,function(t,_,_,list,homes)for i,p in ipairs(list)do p.CFrame=CFrame.Angles(0,0,-t*2.2)*homes[i]end end)
    b.move({halo},function(t,_,_,list)list[1].Transparency=.78+.08*math.sin(t*5)end)
    local embers={};for i=1,3 do embers[i]=b.add('Ember',V(.06,.06,.06)*s,CFrame.identity,w.glow,NEON,0,'ball')end
    b.move(embers,function(t,_,_,list)for i,p in ipairs(list)do local a=t*3+i/3*TAU;p.CFrame=CFrame.new(math.cos(a)*.2*s,math.sin(a)*.2*s,(-.3+.12*math.sin(t*2+i))*s)end end)
    for i=0,2 do
        local a=CFrame.new(0,0,.74*s)*CFrame.Angles(0,0,i*TAU/3)
        b.add('Fin',V(.025,.19,.26)*s,a*CFrame.new(0,.17*s,0),w.fins,METAL)
        b.add('FinTip',V(.05,.05,.05)*s,a*CFrame.new(0,.265*s,.1*s),w.core,NEON,0,'ball')
        b.add('FlameFin',V(.02,.11,.18)*s,CFrame.new(0,0,.78*s)*CFrame.Angles(0,0,i*TAU/3+TAU/6)*CFrame.new(0,.13*s,0),w.glow,NEON)
    end
    b.rod('EngineBell',.86*s,.94*s,.11*s,w.fins,METAL)
    b.band(-.38*s,-.24*s,.12*s)
    return {tail=.98*s,tailSize=.26*s,band2={.4*s,.5*s,.12*s},nose=-1.3*s,noseR=.1*s,bright=1.6}
end
W.singularity=function(b)
    local s,w=b.s,b.w;local zc=-.2*s;local C=CFrame.new(0,0,zc)
    local XY=CFrame.Angles(math.pi/2,0,0)
    local function grow(p,phase,t,at)
        local f=at and math.clamp((t-at)/.5,0,1)or 1;if phase<p then f=0 end;return f
    end
    b.add('NeedleTip',V(.07,.07,.07)*s,CFrame.new(0,0,-1.5*s),w.core,NEON,0,'ball')
    b.rod('Needle',-1.5*s,-1.1*s,.025*s,w.trim,METAL)
    local cone=b.add('NoseCone',V(.29,.29,.6)*s,CFrame.new(0,0,-1*s),w.body,METAL,0,'ell');cone.Reflectance=.4
    local fwd=b.rod('Hull',-1*s,-.54*s,.145*s,w.body,METAL);fwd.Reflectance=.3
    local aft=b.rod('Hull',.13*s,.66*s,.145*s,w.body,METAL);aft.Reflectance=.3
    b.rod('TailCone',.66*s,.82*s,.1*s,w.fins,METAL)
    local lines={}
    for i=0,1 do table.insert(lines,b.add('PrismLine',V(.03,.03,.42)*s,CFrame.new(0,0,-.77*s)*CFrame.Angles(0,0,math.pi/2+i*math.pi)*CFrame.new(0,.145*s,0),w.core,NEON))end
    b.move(lines,function(t,_,_,list)for i,p in ipairs(list)do p.Color=hue(t*.12+i/2)end end)
    b.rod('CageMount',-.58*s,-.52*s,.165*s,w.trim,NEON);b.rod('CageMount',.12*s,.18*s,.165*s,w.trim,NEON)
    b.band(.28*s,.38*s,.15*s)
    local core=b.add('Core',V(.42,.42,.42)*s,C,w.body,GLASS,0,'ball');core.Reflectance=.3
    local horizon=b.ring('Horizon',8,w.core)
    b.move(horizon,function(t,_,_,list)T.placeRing(list,C*XY,.28*s,t*4,.06*s,1.04);for i,p in ipairs(list)do p.Color=hue(t*.15+i/8)end end)
    local outer,inner=b.ring('Gimbal',6,w.trim),b.ring('Gimbal',6,w.glow)
    b.move(outer,function(t,_,_,list)T.placeRing(list,C*CFrame.Angles(0,0,t*.7+math.pi/2),.36*s,0,.022*s,1.04)end)
    b.move(inner,function(t,_,_,list)T.placeRing(list,C*CFrame.Angles(0,0,t*.7)*CFrame.Angles(t*1.6,0,0),.32*s,0,.022*s,1.04)end)
    local fins={}
    for i=0,3 do
        local cf=CFrame.new(0,0,.56*s)*CFrame.Angles(0,0,math.pi/4+i*math.pi/2)*CFrame.new(0,.3*s,0)*CFrame.Angles(-.45,0,0)
        b.add('PrismFin',V(.025,.3,.42)*s,cf,w.glow,GLASS,.45)
        table.insert(fins,b.add('PrismEdge',V(.035,.035,.44)*s,cf*CFrame.new(0,.15*s,0),w.core,NEON))
    end
    b.move(fins,function(t,_,_,list)for i,p in ipairs(list)do p.Color=hue(t*.08+i/4)end end)
    local D=C*CFrame.Angles(.25,0,0)*XY
    local disk=b.ring('Accretion',10,w.core)
    b.move(disk,function(t,phase,ph,list)
        local f=grow(2,phase,t,ph[2]);T.placeRing(list,D,(.36+.26*out2(f))*s,-t*1.8,.045*s,.9)
        for i,p in ipairs(list)do p.Color=hue(t*.12+i/10+.3);p.Transparency=f<=0 and 1 or 1-.9*f end
    end)
    local sheet=b.add('AccretionGlow',V(.01,1,1)*s,D*CFrame.Angles(0,0,math.pi/2),w.glow,NEON,1,'cyl')
    b.move({sheet},function(t,phase,ph,list)
        local f=grow(2,phase,t,ph[2]);local p=list[1];local d=(.62+.52*out2(f))*s
        p.Size=V(.01*s,d,d);p.Color=hue(t*.12+.55);p.Transparency=f<=0 and 1 or 1-.14*f
    end)
    local jets={b.rod('Jet',-1.85*s,-1.52*s,.02*s,w.core,NEON),b.rod('Jet',zc-.36*s,zc+.36*s,.03*s,w.trim,NEON)}
    b.move(jets,function(t,phase,ph,list)local f=grow(2,phase,t,ph[2]);for _,p in ipairs(list)do p.Transparency=f<=0 and 1 or math.max(1-f,.1+.3*math.sin(t*9)^2)end end)
    local H=function(t)return C*CFrame.Angles(0,0,t*.5)*CFrame.Angles(-.95,0,0)*XY end
    local halo=b.ring('Halo',8,w.trim)
    b.move(halo,function(t,phase,ph,list)
        local f=grow(3,phase,t,ph[3]);T.placeRing(list,H(t),(.5+.26*out2(f))*s,t*.8,.028*s,1.02)
        for i,p in ipairs(list)do p.Color=hue(t*.1+i/8+.6);p.Transparency=f<=0 and 1 or 1-.8*f end
    end)
    local prisms={}
    for i=1,4 do table.insert(prisms,b.add('Prism',V(.09,.22,.09)*s,C,w.core,NEON))end
    b.move(prisms,function(t,phase,ph,list)
        local f=grow(3,phase,t,ph[3])
        for i,p in ipairs(list)do p.Transparency=f<=0 and 1 or 1-f;p.Color=hue(t*.1+i*.25);p.CFrame=H(t)*CFrame.Angles(0,-t*1.3+(i+.5)/4*TAU,0)*CFrame.new(0,0,-(.5+.26*f)*s)*CFrame.Angles(t*2,0,math.pi/4)end
    end)
    return {tail=.84*s,tailSize=.2*s,band2={.44*s,.52*s,.15*s},nose=-1.12*s,noseR=.12*s,phases=true,bright=1.4}
end
T.warheads=W

local function seq(...)return NumberSequence.new(...)end
local function prism()
    local keys={};for i=0,5 do table.insert(keys,ColorSequenceKeypoint.new(i/5,hue(i/6)))end;return ColorSequence.new(keys)
end
local Tr={}
Tr.steel=function(b,tail,tr,info)
    b.trail(tail,'HazeTrail',tr.smokeWidth*b.s*.85,ColorSequence.new(tr.haze),4.2,seq({NumberSequenceKeypoint.new(0,.82),NumberSequenceKeypoint.new(.2,.7),NumberSequenceKeypoint.new(1,1)}),seq(.6,2.6),0)
end
Tr.cryo=function(b,tail,tr,info)
    for i,tip in ipairs(info.tips or {})do
        local holder=b.model:FindFirstChild('FrostFin')and b.anchor('Contrail'..i,tip)
        if holder then b.trail(holder,'Contrail',.05*b.s,ColorSequence.new(tr.haze),2.4,seq({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,1)}),seq(1,2.2),.3)end
    end
    b.emitter('Snow',{Color=ColorSequence.new(tr.snow),Size=seq({NumberSequenceKeypoint.new(0,.12*b.s),NumberSequenceKeypoint.new(1,.04*b.s)}),
        Transparency=seq({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(1,1)}),Lifetime=NumberRange.new(1.6,2),Rate=8,Speed=NumberRange.new(.4,1.2),
        SpreadAngle=Vector2.new(180,180),Acceleration=V(0,-1.5,0),LightEmission=.6,RotSpeed=NumberRange.new(-90,90)},16)
end
Tr.plasma=function(b,tail,tr,info)
    for i=0,1 do b.orbit('PlasmaRibbon',.32*b.s,10,i*math.pi,.14*b.s,ColorSequence.new(tr.arc,tr.ribbon),seq({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),.9)end
    for i=1,2 do b.arc('PlasmaArc',tr.arc,.04*b.s,1.1*b.s)end
    b.emitter('Sparks',{Color=ColorSequence.new(tr.arc,tr.ribbon),Size=seq({NumberSequenceKeypoint.new(0,.09*b.s),NumberSequenceKeypoint.new(1,0)}),
        Transparency=seq(0,.6),Lifetime=NumberRange.new(.3,.5),Rate=24,Speed=NumberRange.new(1.5,3.5),SpreadAngle=Vector2.new(180,180),LightEmission=1},12)
end
Tr.sun=function(b,tail,tr,info)
    for i=0,2 do b.orbit('FlareRibbon',.4*b.s,7,i*TAU/3,.16*b.s,ColorSequence.new(tr.core,tr.ribbon),seq({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.6,.4),NumberSequenceKeypoint.new(1,1)}),1.15)end
    b.trail(tail,'HeatTrail',tr.smokeWidth*b.s*.22,ColorSequence.new(tr.haze,tr.hot),1.1,seq({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,1)}),seq(1,1.6),1)
    b.emitter('Embers',{Color=ColorSequence.new(tr.core,tr.ember),Size=seq({NumberSequenceKeypoint.new(0,.12*b.s),NumberSequenceKeypoint.new(1,0)}),
        Transparency=seq(0,.5),Lifetime=NumberRange.new(.9,1.3),Rate=36,Speed=NumberRange.new(.6,2),SpreadAngle=Vector2.new(180,180),Acceleration=V(0,1.2,0),LightEmission=1},47)
end
Tr.singularity=function(b,tail,tr,info)
    local colors=prism()
    for i=0,2 do b.orbit('PrismRibbon',(.4+i*.1)*b.s,-6+i,i*TAU/3,.17*b.s,colors,seq({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.7,.3),NumberSequenceKeypoint.new(1,1)}),1.8)end
    b.trail(tail,'WarpTrail',tr.smokeWidth*b.s*.8,ColorSequence.new(tr.haze,tr.smoke),4,seq({NumberSequenceKeypoint.new(0,.7),NumberSequenceKeypoint.new(1,1)}),seq(.4,2.8),.25)
    b.emitter('Stars',{Color=colors,Size=seq({NumberSequenceKeypoint.new(0,.1*b.s),NumberSequenceKeypoint.new(.5,.16*b.s),NumberSequenceKeypoint.new(1,0)}),
        Transparency=seq(0,.4),Lifetime=NumberRange.new(1.2,1.6),Rate=50,Speed=NumberRange.new(.3,1.4),SpreadAngle=Vector2.new(180,180),LightEmission=1,RotSpeed=NumberRange.new(-120,120)},80)
end
T.trails=Tr

local I={}
local function radiusRing(d,color,n,from,fade)
    local list=d.ring('RadiusRing',n or 16,color)
    d.el(function(t)
        local g=out2(k(t,from or .15,(from or .15)+.4));local tr=math.max(1-g*1.4,.15+.85*k(t,fade or 2.4,(fade or 2.4)+1))
        T.placeRing(list,CFrame.new(d.ground+UP*.14),d.R*(.88+.12*g),t*.25,math.max(.08,d.R*.022))
        for _,p in ipairs(list)do p.Transparency=tr end
    end)
    return list
end
I.steel=function(d)
    local R,s=d.R,d.skin
    local cap=d.parts.Cap
    local top=d.add('CapTop','ell',V(R*.5,R*.3,R*.5),CFrame.new(d.ground),s.cap,SMOOTH,1)
    local roll=d.add('CapRoll','ell',V(R*.9,R*.16,R*.9),CFrame.new(d.ground),s.smoke,SMOOTH,1)
    d.el(function(t)
        local a=out2(k(t,.1,2));local y=R*(.3+.65*a)
        top.Size=V(R*(.25+.35*a),R*(.15+.18*a),R*(.25+.35*a));top.CFrame=CFrame.new(d.ground+UP*(y+R*.18*a))
        roll.Size=V(R*(.4+.75*a),R*(.1+.08*a),R*(.4+.75*a));roll.CFrame=CFrame.new(d.ground+UP*(y-R*.17*a))
        local tr=t<.15 and 1 or .1+.9*k(t,2.6,5);top.Transparency=tr;roll.Transparency=math.max(tr,.15)
        if cap then top.Color=cap.Color end
    end)
    for i=1,8 do
        local a=i/8*TAU+hash(i,1);local dir=V(math.cos(a),0,math.sin(a));local vh=R*(.7+.5*hash(i,2));local vy=R*(1.2+.6*hash(i,3))
        local p=d.add('Debris','block',V(1,.7,.8)*R*.05,CFrame.new(d.ground),s.debris,SMOOTH,1)
        d.el(function(t)
            local u=math.min(t,1.6);local y=math.max(0,vy*u-R*1.8*u*u)
            p.CFrame=CFrame.new(d.ground+dir*vh*u+UP*y)*CFrame.Angles(u*7+i,u*5,0);p.Transparency=t>1.6 and 1 or .6*k(t,1.1,1.6)
        end)
    end
    radiusRing(d,s.ring,16)
end
I.cryo=function(d)
    local R,s=d.R,d.skin
    for i=1,10 do
        local a=i/10*TAU+hash(i,4)*.5;local e=.45+.7*hash(i,5);local dist=R*(.32+.2*hash(i,6))
        local dir=V(math.cos(a)*math.cos(e),math.sin(e),math.sin(a)*math.cos(e))
        local p=d.add('IceShard','block',V(.05,.05,.24)*R,CFrame.new(d.ground),s.ice,ICE,1)
        d.el(function(t)
            local at=d.ground+UP*R*.08+dir*dist*out4(k(t,0,.35))
            p.CFrame=CFrame.lookAt(at,at+dir)*CFrame.Angles(0,0,math.pi/4+t*.3);p.Transparency=t<.02 and 1 or .08+.92*k(t,2.6,3.6)
        end)
    end
    for i=1,16 do
        local a=i/16*TAU;local dir=V(math.cos(a),0,math.sin(a));local hi=.75+.5*hash(i,7)
        local p=d.add('FrostSpike','block',V(1,1,1),CFrame.new(d.ground),i%2==0 and s.ice or s.core,ICE,1)
        d.el(function(t)
            local g=out2(k(t,.05,.85));local h=math.max(.05,R*.2*hi*out2(k(t,.08,.85)))
            p.Size=V(R*.05,h,R*.05);p.CFrame=CFrame.new(d.ground+dir*R*(.25+.75*g))*CFrame.Angles(0,-a,0)*CFrame.Angles(0,0,-.35)*CFrame.new(0,h/2,0)*CFrame.Angles(0,math.pi/4,0)
            p.Transparency=t<.06 and 1 or .05+.95*k(t,3.4,4.6)
        end)
    end
    d.emit(.05,{Color=ColorSequence.new(s.flash),Size=seq(R*.035,0),Transparency=seq(0,1),Lifetime=NumberRange.new(1.4,2.2),Speed=NumberRange.new(R*.4,R*1.1),
        SpreadAngle=Vector2.new(70,70),Acceleration=V(0,-R*.4,0),LightEmission=.7},20)
end
I.plasma=function(d)
    local R,s=d.R,d.skin
    local dome=d.add('PlasmaDome','ball',V(1,1,1),CFrame.new(d.ground),s.dome,Enum.Material.Neon,1)
    local shell=d.add('PlasmaShell','ball',V(1,1,1),CFrame.new(d.ground),s.core,Enum.Material.Neon,1)
    local arcs={}
    for i=1,6 do arcs[i]={};for j=1,3 do arcs[i][j]=d.add('PlasmaArc','block',V(.1,.1,.1),CFrame.new(d.ground),s.arc,Enum.Material.Neon,1)end end
    local function radius(t)return R*.72*out4(k(t,.03,.45))*(1-out2(k(t,1.8,2.3)))end
    d.el(function(t)
        local rd=radius(t)
        dome.Size=Vector3.one*math.max(.1,rd*2);dome.CFrame=CFrame.new(d.ground);dome.Transparency=rd<.05 and 1 or .5+.08*math.sin(t*26)+.4*k(t,1.6,2.3)
        shell.Size=Vector3.one*math.max(.1,rd*1.3);shell.CFrame=CFrame.new(d.ground);shell.Transparency=rd<.05 and 1 or .8+.15*k(t,1.4,2.3)
        local step=math.floor(t/.07)
        for i,arc in ipairs(arcs)do
            local on=rd>R*.1 and t<1.9 and hash(i,step)>.22
            local a=i/6*TAU+hash(i,step+.5)*.8;local dir=V(math.cos(a),0,math.sin(a));local tan=dir:Cross(UP)
            local pts={d.ground+UP*rd*.98}
            for j=1,2 do local th=j/3*math.pi/2;table.insert(pts,d.ground+(dir*math.sin(th)+UP*math.cos(th))*rd*1.01+tan*rd*.16*(hash(i*3+j,step)-.5))end
            table.insert(pts,d.ground+dir*rd*.99+UP*.1)
            for j,p in ipairs(arc)do if on then T.span(p,pts[j],pts[j+1],math.max(.06,R*.014));p.Transparency=0 else p.Transparency=1 end end
        end
    end)
    local ring=radiusRing(d,s.ring,16,.2,2.2)
    d.el(function(t)local step=math.floor(t/.06);if t<2.2 then for i,p in ipairs(ring)do if hash(i,step)<.2 then p.Transparency=math.max(p.Transparency,.7)end end end end)
    d.emit(.06,{Color=ColorSequence.new(s.arc,s.dome),Size=seq(R*.03,0),Transparency=seq(0,.5),Lifetime=NumberRange.new(.5,.9),Speed=NumberRange.new(R*.8,R*1.6),
        SpreadAngle=Vector2.new(80,80),LightEmission=1},50)
end
I.sun=function(d)
    local R,s=d.R,d.skin
    local pillar=d.add('FlarePillar','cyl',V(1,1,1),CFrame.new(d.ground)*FLAT,s.pillar,Enum.Material.Neon,1)
    local sheath=d.add('FlareSheath','cyl',V(1,1,1),CFrame.new(d.ground)*FLAT,s.fire,Enum.Material.Neon,1)
    local crown=d.add('SunDisc','ball',V(1,1,1),CFrame.new(d.ground),s.core,Enum.Material.Neon,1)
    if not d.reduced then
        local light=Instance.new('PointLight');light.Name='SunLight';light.Color=s.ring;light.Range=math.min(60,R*2.2);light.Shadows=false;light.Brightness=0;light.Parent=crown
        d.el(function(t)light.Brightness=5*(1-k(t,.4,2.6))*k(t,0,.1)end)
    end
    d.el(function(t)
        local h=math.max(.1,R*2.3*out4(k(t,.03,.4)));local r=R*.08*(1-.6*k(t,1.2,2.6))
        pillar.Size=V(h,r*2,r*2);pillar.CFrame=CFrame.new(d.ground+UP*h/2)*FLAT;pillar.Transparency=t<.03 and 1 or k(t,1.4,2.8)
        sheath.Size=V(h*.92,r*5,r*5);sheath.CFrame=pillar.CFrame;sheath.Transparency=t<.03 and 1 or .6+.4*k(t,1,2.4)
        local c=R*.42*out2(k(t,.1,.5));crown.Size=Vector3.one*math.max(.1,c);crown.CFrame=CFrame.new(d.ground+UP*h);crown.Transparency=t<.1 and 1 or .1+.9*k(t,1.2,2.4)
    end)
    local rays={}
    for i=1,12 do rays[i]=d.add('SunRay','block',V(1,1,1),CFrame.new(d.ground),i%2==0 and s.ring or s.core,Enum.Material.Neon,1)end
    d.el(function(t)
        local g=out2(k(t,.05,.5))
        for i,p in ipairs(rays)do
            local a=i/12*TAU+t*.35;local dir=V(math.cos(a),0,math.sin(a));local len=math.max(.05,R*(i%2==0 and .85 or .6)*g)
            p.Size=V(math.max(.06,R*.025),.06,len);p.CFrame=CFrame.lookAt(d.ground+UP*.2+dir*(R*.12+len/2),d.ground+UP*.2+dir*R*2)
            p.Transparency=t<.05 and 1 or .2+.8*k(t,1.5,3)
        end
    end)
    local inner=d.ring('InnerRing',10,s.fire)
    d.el(function(t)
        local g=out2(k(t,.25,.7));T.placeRing(inner,CFrame.new(d.ground+UP*.16),R*.78*(.6+.4*g),-t*.5,math.max(.08,R*.02))
        for _,p in ipairs(inner)do p.Transparency=t<.25 and 1 or .2+.8*k(t,2.2,3.4)end
    end)
    radiusRing(d,s.ring,16,.1,2.6)
    for i=1,3 do
        local segs={};for j=1,3 do segs[j]=d.add('FlareLoop','block',V(.1,.1,.1),CFrame.new(d.ground),s.fire,Enum.Material.Neon,1)end
        local a=i/3*TAU+.4;local dir=V(math.cos(a),0,math.sin(a));local center=d.ground+dir*R*.42
        d.el(function(t)
            local g=out2(k(t,.2,.8));local rl=R*.2*g
            for j,p in ipairs(segs)do
                local a0,a1=(j-1)/3*math.pi,j/3*math.pi
                if g<.05 then p.Transparency=1 else
                    T.span(p,center+dir*math.cos(a0)*rl+UP*math.sin(a0)*rl*1.7,center+dir*math.cos(a1)*rl+UP*math.sin(a1)*rl*1.7,math.max(.07,R*.022))
                    p.Transparency=k(t,1.6,2.6)
                end
            end
        end)
    end
    d.emit(.05,{Color=ColorSequence.new(s.core,s.fire),Size=seq(R*.035,0),Transparency=seq(0,.4),Lifetime=NumberRange.new(1,1.8),Speed=NumberRange.new(R*.5,R*1.4),
        SpreadAngle=Vector2.new(60,60),Acceleration=V(0,R*.15,0),LightEmission=1},90)
end
I.singularity=function(d)
    local R,s=d.R,d.skin;local bang=.75
    local void=d.add('Void','ball',V(1,1,1),CFrame.new(d.ground),s.void,GLASS,1)
    local lens=d.add('Lens','cyl',V(.05,1,1),CFrame.new(d.ground+UP*.1)*FLAT,s.void,SMOOTH,1)
    local disk=d.add('Remnant','cyl',V(.05,1,1),CFrame.new(d.ground)*FLAT,s.ring,Enum.Material.Neon,1)
    local rim=d.add('Horizon','ball',V(1,1,1),CFrame.new(d.ground),s.fire,Enum.Material.Neon,1)
    local well=d.add('GravityWell','ball',V(1,1,1),CFrame.new(d.ground),s.fire,GLASS,1)
    d.el(function(t)
        local tb=t-bang
        if tb<0 then
            local r=R*.18*out2(k(t,0,.4))*(1-in2(k(t,.55,bang)));void.Size=Vector3.one*math.max(.1,r*2);void.CFrame=CFrame.new(d.ground+UP*R*.2);void.Transparency=r<.05 and 1 or 0
            local l=R*.75*(1-in2(k(t,0,bang)));lens.Size=V(.05,l*2,l*2);lens.Transparency=.35+.65*k(t,.6,bang);disk.Transparency=1
            rim.Size=Vector3.one*math.max(.1,r*2.3);rim.CFrame=void.CFrame;rim.Transparency=r<.05 and 1 or .55
            local wr=R*.85*(1-in2(k(t,0,bang)));well.Size=Vector3.one*math.max(.1,wr*2);well.CFrame=CFrame.new(d.ground);well.Transparency=.72+.28*k(t,.5,bang)
        else
            local y=R*(.2+.6*out2(k(tb,0,2)));local r=R*.1*out2(k(tb,.2,.6))*(1-in2(k(tb,3.3,3.9)))
            void.Size=Vector3.one*math.max(.1,r*2);void.CFrame=CFrame.new(d.ground+UP*y);void.Transparency=r<.05 and 1 or 0
            disk.Size=V(.05,r*5,r*5);disk.CFrame=CFrame.new(d.ground+UP*y)*CFrame.Angles(.35,0,0)*FLAT;disk.Color=hue(t*.25);disk.Transparency=r<.05 and 1 or .25
            rim.Size=Vector3.one*math.max(.1,r*2.4);rim.CFrame=void.CFrame;rim.Transparency=r<.05 and 1 or .5
            lens.Transparency=1;well.Transparency=1
        end
    end)
    for i=1,10 do
        local a=i/10*TAU+hash(i,8);local dir=V(math.cos(a),0,math.sin(a));local r0=R*(.55+.45*hash(i,9))
        local p=d.add('Infall','block',V(1,.8,.7)*R*.045,CFrame.new(d.ground),s.dust,SMOOTH,1)
        d.el(function(t)
            local g=in2(k(t,0,bang));local at=d.ground+dir*r0*(1-g)+UP*R*(.05+.15*g)
            p.CFrame=CFrame.new(at)*CFrame.Angles(t*6,t*4+i,0);p.Transparency=t>=bang and 1 or .1
        end)
    end
    local ring=d.ring('PrismRing',16,s.ring)
    d.el(function(t)
        local tb=t-bang;local r=tb<0 and R*(1-.85*in2(k(t,0,bang)))or R*(.15+.85*out4(k(tb,0,.5)))
        T.placeRing(ring,CFrame.new(d.ground+UP*(tb<0 and R*.2*k(t,0,bang)or .15)),r,tb<0 and t*(2+8*t)or t*.4,math.max(.08,R*.024))
        local tr=.05+.95*k(tb,2.4,3.4)
        for i,p in ipairs(ring)do p.Color=hue(t*.3+i/16);p.Transparency=tr end
    end)
    for i=0,2 do
        local wave=d.add('PrismWave','cyl',V(.05,1,1),CFrame.new(d.ground)*FLAT,hue(i/3),Enum.Material.Neon,1)
        d.el(function(t)
            local tb=t-bang;if tb<0 then wave.Transparency=1;return end
            local r=math.max(.1,R*(1.5-i*.18)*out4(k(tb,0,1+.2*i)));wave.Size=V(.05+.02*i,r*2,r*2);wave.CFrame=CFrame.new(d.ground+UP*(.22+.04*i))*FLAT
            wave.Color=hue(t*.4+i/3);wave.Transparency=.8+.2*k(tb,.1,1+.2*i)
        end)
    end
    for i=1,8 do
        local a=i/8*TAU+hash(i,10);local e=.25+.6*hash(i,11);local dir=V(math.cos(a)*math.cos(e),math.sin(e),math.sin(a)*math.cos(e))
        local p=d.add('PrismShard','block',V(.04,.04,.18)*R,CFrame.new(d.ground),s.ring,Enum.Material.Neon,1)
        d.el(function(t)
            local tb=t-bang;if tb<0 then p.Transparency=1;return end
            local at=d.ground+UP*R*.2+dir*R*.62*out4(k(tb,0,.6));p.CFrame=CFrame.lookAt(at,at+dir)*CFrame.Angles(0,0,tb*3)
            p.Color=hue(t*.3+i/8);p.Transparency=k(tb,1.2,2.2)
        end)
    end
    local helix={};for i=1,14 do helix[i]=d.add('Vortex','block',V(.1,.1,.1),CFrame.new(d.ground),s.ring,Enum.Material.Neon,1)end
    d.el(function(t)
        local tb=t-bang;if tb<0 or tb>3.2 then for _,p in ipairs(helix)do p.Transparency=1 end;return end
        local g=out2(k(tb,0,.8));local top=R*(.2+.75*out2(k(tb,0,2)))*g;local prev
        for i=0,14 do
            local u=i/14;local a=u*TAU*2.2-t*4;local r=R*(.45-.25*u)
            local at=d.ground+V(math.cos(a)*r,u*top,math.sin(a)*r)
            if prev then local p=helix[i];T.span(p,prev,at,math.max(.08,R*.026));p.Color=hue(t*.3+u);p.Transparency=.1+.9*k(tb,2.2,3.2)end
            prev=at
        end
    end)
    local glow=d.parts.CapGlow
    if glow then d.el(function(t)glow.Color=hue(t*.2+.6)end)end
    d.emit(bang,{Color=prism(),Size=seq({NumberSequenceKeypoint.new(0,R*.03),NumberSequenceKeypoint.new(.4,R*.04),NumberSequenceKeypoint.new(1,0)}),Transparency=seq(0,.3),Lifetime=NumberRange.new(1.2,2),Speed=NumberRange.new(R*.6,R*1.5),
        SpreadAngle=Vector2.new(75,75),LightEmission=1,RotSpeed=NumberRange.new(-120,120)},120)
end
I.delay={singularity=.75}
T.impacts=I
T.radiusRing,T.prism=radiusRing,prism
require(script.Parent.NukeVolume)(T)
require(script.Parent.NukeVolume2)(T)
return T
