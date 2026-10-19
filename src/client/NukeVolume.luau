return function(T)
local W,Tr,I=T.warheads,T.trails,T.impacts
local V=Vector3.new
local UP=Vector3.yAxis
local NEON,METAL,SMOOTH,GLASS,SLATE,FORCE=Enum.Material.Neon,Enum.Material.Metal,Enum.Material.SmoothPlastic,Enum.Material.Glass,Enum.Material.Slate,Enum.Material.ForceField
local ZC=CFrame.Angles(0,math.pi/2,0)
local FLAT=CFrame.Angles(0,0,math.pi/2)
local XY=CFrame.Angles(math.pi/2,0,0)
local TAU=math.pi*2
local k,out2,out4,in2,hash,hue=T.k,T.out2,T.out4,T.in2,T.hash,T.hue
local radiusRing,span,placeRing=T.radiusRing,T.span,T.placeRing
local function ns(...)local a={...};local t={};for i=1,#a,2 do table.insert(t,NumberSequenceKeypoint.new(a[i],a[i+1]))end;return NumberSequence.new(t)end
local function cs(...)local a={...};local t={};for i,c in ipairs(a)do table.insert(t,ColorSequenceKeypoint.new((i-1)/(#a-1),c))end;return ColorSequence.new(t)end
local function tube(b,name,x,y,z0,z1,r,color,material,tr)return b.add(name,V(math.abs(z1-z0),r*2,r*2),CFrame.new(x,y,(z0+z1)/2)*ZC,color,material,tr,'cyl')end
local function light(part,color,brightness,range)
    local l=Instance.new('PointLight');l.Color=color;l.Brightness=brightness;l.Range=range;l.Shadows=false;l.Parent=part;return l
end
local function spin(list,homes,a)local r=CFrame.Angles(0,0,a);for i,p in ipairs(list)do p.CFrame=r*homes[i]end end

W.toxin=function(b)
    local s,w=b.s,b.w
    local can=b.rod('Canister',-.46*s,.46*s,.19*s,w.body,METAL);can.Reflectance=.1
    b.add('Nose',V(.38,.38,.5)*s,CFrame.new(0,0,-.48*s),w.nose,METAL,0,'ell')
    b.rod('Nozzle',-.86*s,-.68*s,.045*s,w.trim,METAL)
    b.add('NozzleTip',V(.11,.11,.11)*s,CFrame.new(0,0,-.88*s),w.core,NEON,0,'ball')
    b.rod('HazardStripe',-.36*s,-.3*s,.196*s,w.stripe)
    b.rod('TailCone',.46*s,.64*s,.13*s,w.fins,METAL)
    b.band(-.2*s,-.1*s,.196*s)
    local bubbles={}
    for i=0,2 do
        local a=i*TAU/3;local at=(CFrame.Angles(0,0,a)*CFrame.new(0,.28*s,0)).Position;local x,y=at.X,at.Y
        tube(b,'Vial',x,y,-.4*s,.36*s,.085*s,w.glass,GLASS,.45)
        tube(b,'Toxin',x,y,-.37*s,.33*s,.056*s,w.core,NEON,.05)
        tube(b,'VialCap',x,y,-.46*s,-.4*s,.094*s,w.trim,METAL);tube(b,'VialCap',x,y,.36*s,.42*s,.094*s,w.trim,METAL)
        for _,z in ipairs({-.2,.18})do b.add('Clamp',V(.07,.1,.06)*s,CFrame.new(0,0,z*s)*CFrame.Angles(0,0,a)*CFrame.new(0,.21*s,0),w.fins,METAL)end
        b.add('Fin',V(.03,.22,.3)*s,CFrame.new(0,0,.52*s)*CFrame.Angles(0,0,a+TAU/6)*CFrame.new(0,.24*s,0)*CFrame.Angles(-.3,0,0),w.fins,METAL)
        for _=1,2 do table.insert(bubbles,b.add('Bubble',V(.07,.07,.07)*s,CFrame.new(x,y,0),w.bubble,NEON,0,'ball'))end
    end
    b.move(bubbles,function(t,_,_,list,homes)
        for i,p in ipairs(list)do
            local f=(t*.7+i*.37)%1;local h=homes[i].Position
            p.CFrame=CFrame.new(h.X+math.sin(t*7+i)*.012*s,h.Y,(.3-.64*f)*s);p.Size=Vector3.one*(.03+.045*math.sin(f*math.pi))*s
            p.Transparency=f>.92 and 1 or 0
        end
    end)
    return {tail=.68*s,tailSize=.24*s,band2={.24*s,.32*s,.196*s},nose=-.92*s,noseR=.1*s}
end
W.tsunami=function(b)
    local s,w=b.s,b.w
    local hull=b.add('Hull',V(.36,.36,1.3)*s,CFrame.new(0,0,-.08*s),w.body,SMOOTH,0,'ell');hull.Reflectance=.25
    b.add('WaterSheath',V(.5,.5,1.12)*s,CFrame.new(0,0,-.16*s),w.water,GLASS,.55,'ell')
    b.add('FoamTip',V(.15,.15,.28)*s,CFrame.new(0,0,-.74*s),w.trim,SMOOTH,0,'ell')
    for _,z in ipairs({-.32,.2})do b.rod('WaterLine',z*s,(z+.035)*s,.172*s,w.core,NEON)end
    b.rod('TailCone',.5*s,.7*s,.1*s,w.fins,METAL)
    b.band(-.12*s,-.04*s,.182*s)
    for i=0,2 do
        local cf=CFrame.new(0,0,.42*s)*CFrame.Angles(0,0,i*TAU/3)*CFrame.new(0,.2*s,0)*CFrame.Angles(-.4,0,0)
        b.add('Fin',V(.03,.22,.34)*s,cf,w.water,GLASS,.2)
        b.add('FinFoam',V(.04,.035,.34)*s,cf*CFrame.new(0,.11*s,0),w.trim,NEON)
    end
    local crest={}
    for i=0,2 do for j=0,2 do
        local h=(.15+.04*j)*s
        local base=CFrame.new(0,0,(-.44+.3*j)*s)*CFrame.Angles(0,0,i*TAU/3+j*.75)*CFrame.new(0,.21*s,0)*CFrame.Angles(0,.5,0)
        table.insert(crest,b.add('WaveCrest',V(.035*s,h,.3*s),base*CFrame.new(0,h/2,0),w.water,GLASS,.12,'wedge'))
        table.insert(crest,b.add('Foam',V(.075,.075,.075)*s,base*CFrame.new(0,h,.13*s),w.trim,NEON,0,'ball'))
    end end
    b.move(crest,function(t,_,_,list,homes)spin(list,homes,t*1.6)end)
    local spray={};for i=1,6 do spray[i]=b.add('Spray',V(.05,.05,.05)*s,CFrame.identity,w.trim,NEON,0,'ball')end
    b.move(spray,function(t,_,_,list)
        for i,p in ipairs(list)do local f=(t*.8+i/6)%1;local a=t*1.6+i*1.3;local r=(.27+.16*f)*s;p.CFrame=CFrame.new(math.cos(a)*r,math.sin(a)*r,(-.3+.9*f)*s);p.Transparency=f end
    end)
    return {tail=.74*s,tailSize=.22*s,band2={.1*s,.16*s,.17*s},nose=-.88*s,noseR=.1*s}
end
W.lava=function(b)
    local s,w=b.s,b.w
    local core=b.rod('MoltenCore',-.5*s,.5*s,.15*s,w.core,NEON)
    local plates={}
    for ring=0,2 do for i=0,3 do
        local z=(-.33+.34*ring)*s;local a=i*math.pi/2+ring*.6+hash(ring,i)*.3
        local cf=CFrame.new(0,0,z)*CFrame.Angles(0,0,a)*CFrame.new(0,.165*s,0)*CFrame.Angles((hash(i,ring)-.5)*.3,0,(hash(ring+3,i)-.5)*.25)
        table.insert(plates,b.add('Crust',V((.16+.05*hash(i,ring+7))*s,.085*s,.27*s),cf,(i+ring)%2==0 and w.body or w.crust,SLATE))
    end end
    for i=0,3 do table.insert(plates,b.add('Vein',V(.025,.02,.22)*s,plates[5+i].CFrame*CFrame.new(0,.044*s,0)*CFrame.Angles(0,.5*(i%2==0 and 1 or -1),0),w.glow,NEON))end
    b.move(plates,function(t,_,_,list,homes)for i,p in ipairs(list)do p.CFrame=homes[i]*CFrame.new(0,.014*s*math.sin(t*3+i*1.3),0)end end)
    b.move({core},function(t,_,_,list)list[1].Color=w.core:Lerp(w.trim,.5+.5*math.sin(t*4))end)
    b.add('RockNose',V(.34,.34,.46)*s,CFrame.new(0,0,-.6*s),w.body,SLATE,0,'ell')
    b.add('MoltenTip',V(.14,.14,.14)*s,CFrame.new(0,0,-.83*s),w.glow,NEON,0,'ball')
    for i=0,2 do b.add('Shard',V(.06,.1,.24)*s,CFrame.new(0,0,-.66*s)*CFrame.Angles(0,0,i*TAU/3+.4)*CFrame.new(0,.15*s,0)*CFrame.Angles(.3,0,0),w.crust,SLATE,0,'wedge')end
    for i=0,3 do b.add('Crack',V(.026,.026,.24)*s,CFrame.new(0,0,-.58*s)*CFrame.Angles(0,0,i*math.pi/2+.9)*CFrame.new(0,.168*s,0)*CFrame.Angles(.22,0,0),w.core,NEON)end
    b.rod('TailBell',.5*s,.66*s,.12*s,w.crust,SLATE)
    b.band(-.19*s,-.13*s,.17*s)
    for i=0,2 do
        local cf=CFrame.new(0,0,.54*s)*CFrame.Angles(0,0,i*TAU/3+math.pi/3)*CFrame.new(0,.2*s,0)
        b.add('Fin',V(.06,.2,.3)*s,cf,w.body,SLATE,0,'wedge')
        b.add('FinSeam',V(.035,.035,.3)*s,cf*CFrame.new(0,-.09*s,0),w.core,NEON)
    end
    local drips={};for i=1,3 do drips[i]=b.add('Drip',V(.08,.08,.08)*s,CFrame.identity,w.glow,NEON,0,'ell')end
    b.move(drips,function(t,_,_,list)
        for i,p in ipairs(list)do
            local f=(t*.9+i/3)%1;local a=i/3*TAU+.5;local r=.13*s
            p.Size=V(.08,.08,.08+.18*f)*s*(1-.45*f);p.CFrame=CFrame.new(math.cos(a)*r,math.sin(a)*r-.28*s*f*f,(.52+.5*f)*s);p.Transparency=f>.88 and 1 or 0
        end
    end)
    return {tail=.7*s,tailSize=.24*s,band2={.15*s,.21*s,.17*s},nose=-.9*s,noseR=.11*s}
end
W.thunder=function(b)
    local s,w=b.s,b.w
    for _,z in ipairs({{-.4,-.14},{.22,.52}})do b.rod('Hull',z[1]*s,z[2]*s,.16*s,w.body).Reflectance=.15 end
    b.add('Nose',V(.32,.32,.36)*s,CFrame.new(0,0,-.42*s),w.body,SMOOTH,0,'ell').Reflectance=.15
    b.rod('Rod',-1.2*s,-.55*s,.026*s,w.trim,METAL)
    b.add('RodTip',V(.1,.1,.1)*s,CFrame.new(0,0,-1.22*s),w.core,NEON,0,'ball')
    for i,z in ipairs({-.66,-.79,-.92,-1.05})do b.rod('Insulator',z*s,(z+.035)*s,(.12-.017*i)*s,w.nose,GLASS,.1)end
    b.add('Capacitor',V(.42,.42,.42)*s,CFrame.new(0,0,.04*s),w.nose,GLASS,.45,'ell')
    local core=b.add('ChargeCore',V(.2,.2,.2)*s,CFrame.new(0,0,.04*s),w.core,NEON,0,'ball')
    b.rod('TailCone',.52*s,.7*s,.11*s,w.fins,METAL)
    b.band(-.32*s,-.22*s,.165*s)
    for i=0,2 do
        local a=i*TAU/3
        local cf=CFrame.new(0,0,.46*s)*CFrame.Angles(0,0,a)*CFrame.new(0,.26*s,0)*CFrame.Angles(-.5,0,0)
        b.add('Fin',V(.03,.24,.3)*s,cf,w.fins,METAL)
        b.add('FinTip',V(.06,.06,.06)*s,cf*CFrame.new(0,.12*s,.14*s),w.glow,NEON,0,'ball')
        b.add('Canard',V(.025,.12,.14)*s,CFrame.new(0,0,-.3*s)*CFrame.Angles(0,0,a+TAU/6)*CFrame.new(0,.2*s,0),w.fins,METAL)
    end
    local bolts={};for i=1,9 do bolts[i]=b.add('Arc',V(.1,.1,.1),CFrame.identity,w.bolt,NEON)end
    b.move(bolts,function(t,_,_,list)
        local roll=math.floor(t/.08)
        for j=0,2 do
            local on=hash(j+1,roll)>.2;local a=j*TAU/3+hash(j+4,roll)*1.4
            local p0=V(math.cos(a)*.2*s,math.sin(a)*.2*s,0);local p3=V(0,0,(-.6-.45*hash(j+7,roll))*s)
            local pts={p0}
            for m=1,2 do
                local f=m/3;local b2=a+(hash(m+j*3,roll)-.5)*.9
                table.insert(pts,p0:Lerp(p3,f)+V(math.cos(b2),math.sin(b2),0)*(.14+.12*hash(j*3+m,roll))*s*math.sin(f*math.pi))
            end
            table.insert(pts,p3)
            for m=1,3 do local p=list[j*3+m];if on then span(p,pts[m],pts[m+1],.026*s);p.Transparency=0 else p.Transparency=1 end end
        end
    end)
    local spark=b.add('Spark',V(.09,.09,.09)*s,CFrame.identity,w.core,NEON,0,'ball')
    b.move({spark},function(t,_,_,list)local f=(t*1.4)%1;list[1].CFrame=CFrame.new(0,0,(-.56-.64*f)*s);list[1].Transparency=f>.95 and 1 or 0 end)
    b.move({core},function(t,_,_,list)list[1].Color=w.core:Lerp(w.bolt,.5+.5*math.sin(t*11))end)
    return {tail=.74*s,tailSize=.22*s,band2={.3*s,.38*s,.165*s},nose=-.6*s,noseR=.12*s}
end

W.regal=function(b)
    local s,w=b.s,b.w;local zc=-.12*s;local C=CFrame.new(0,0,zc)
    local body=b.add('Body',V(.46,.46,1.16)*s,CFrame.new(0,0,-.02*s),w.body,METAL,0,'ell');body.Reflectance=.3
    b.rod('GoldBand',-.4*s,-.35*s,.2*s,w.trim,METAL);b.rod('GoldBand',.34*s,.39*s,.198*s,w.trim,METAL)
    b.add('GoldNose',V(.26,.26,.36)*s,CFrame.new(0,0,-.64*s),w.trim,METAL,0,'ell')
    b.add('Orb',V(.17,.17,.17)*s,CFrame.new(0,0,-.84*s),w.nose,METAL,0,'ball')
    b.rod('Finial',-1.08*s,-.9*s,.02*s,w.trim,METAL)
    b.add('Cross',V(.14,.026,.026)*s,CFrame.new(0,0,-1.02*s),w.trim,METAL);b.add('Cross',V(.026,.14,.026)*s,CFrame.new(0,0,-1.02*s),w.trim,METAL)
    local crown={}
    for i=0,5 do
        local tall=i%2==0;local L=(tall and .5 or .32)*s
        local cf=C*CFrame.Angles(0,0,i/6*TAU)*CFrame.new(0,.3*s,0)*CFrame.Angles(.32,0,0)*CFrame.Angles(0,0,math.pi/2)
        for _,p in ipairs(b.blade('CrownPoint',cf*CFrame.new(0,0,-L/2),L,.085*s,.03*s,w.trim,METAL))do table.insert(crown,p)end
        table.insert(crown,b.add('Jewel',V(tall and .11 or .08,tall and .11 or .08,tall and .11 or .08)*s,cf*CFrame.new(0,0,-L),tall and w.jewel or w.core,NEON,0,'ball'))
    end
    b.move(crown,function(t,_,_,list,homes)local r=C*CFrame.Angles(0,0,t*.6)*C:Inverse();for i,p in ipairs(list)do p.CFrame=r*homes[i]end end)
    b.rod('Circlet',zc-.035*s,zc+.035*s,.3*s,w.trim,METAL)
    local band=b.ring('CrownBand',8,w.glow)
    b.move(band,function(t,_,_,list)placeRing(list,C*XY,.3*s,t*.6,.05*s,.9)end)
    local halo=b.add('Halo',V(.95,.95,.95)*s,C,w.glow,NEON,.9,'ball')
    light(halo,w.light,1.5,math.max(4,s*4))
    b.move({halo},function(t,_,_,list)list[1].Transparency=.88+.04*math.sin(t*4)end)
    local stars={};for _=1,3 do table.insert(stars,b.add('Star',V(.026,.22,.026)*s,C,w.core,NEON));table.insert(stars,b.add('Star',V(.22,.026,.026)*s,C,w.core,NEON))end
    b.move(stars,function(t,_,_,list)
        for i=1,3 do
            local at=C*CFrame.Angles(.5,0,0)*CFrame.Angles(0,0,t*1.3+i/3*TAU)*CFrame.new(0,.58*s,0)*CFrame.Angles(0,0,t*2)
            local tw=.55+.45*math.abs(math.sin(t*3+i*2))
            for j=0,1 do local p=list[i*2-1+j];p.CFrame=at;p.Size=p.Size*tw end
        end
    end)
    for i=0,3 do
        local cf=CFrame.new(0,0,.5*s)*CFrame.Angles(0,0,math.pi/4+i*math.pi/2)*CFrame.new(0,.24*s,0)*CFrame.Angles(-.4,0,0)
        b.add('Fin',V(.03,.22,.32)*s,cf,w.fins,METAL)
        b.add('FinGilt',V(.04,.035,.34)*s,cf*CFrame.new(0,.11*s,0),w.trim,METAL)
    end
    b.rod('EngineBell',.56*s,.68*s,.12*s,w.trim,METAL)
    b.band(-.3*s,-.24*s,.21*s)
    return {tail=.72*s,tailSize=.24*s,band2={.18*s,.24*s,.22*s},nose=-1.08*s,noseR=.1*s,bright=1.5}
end
local function feather(b,name,root,dir,thick,L,width,color,material)
    local Z=-dir;local X=thick;local Y=Z:Cross(X)
    return b.add(name,V(.025*b.s,width,L),CFrame.fromMatrix(root+dir*L/2,X,Y,Z),color,material,0,'wedge')
end
W.firebird=function(b)
    local s,w=b.s,b.w
    b.add('Body',V(.34,.3,1)*s,CFrame.new(0,0,-.12*s),w.body,SMOOTH,0,'ell')
    local breast=b.add('Breast',V(.24,.2,.62)*s,CFrame.new(0,-.06*s,-.2*s),w.core,NEON,0,'ell')
    light(breast,w.light,1.6,math.max(4,s*4))
    b.add('Head',V(.26,.26,.26)*s,CFrame.new(0,.07*s,-.66*s),w.feather,SMOOTH,0,'ball')
    b.add('Beak',V(.07,.09,.22)*s,CFrame.new(0,.04*s,-.86*s),w.nose,METAL,0,'wedge')
    for _,x in ipairs({-.1,.1})do b.add('Eye',V(.045,.045,.045)*s,CFrame.new(x*s,.12*s,-.74*s),w.core,NEON,0,'ball')end
    for j=-1,1 do b.add('Crest',V(.025,.13,.3)*s,CFrame.new(j*.05*s,.21*s,-.55*s)*CFrame.Angles(.25,j*.35,0),j==0 and w.glow or w.feather,j==0 and NEON or SMOOTH,0,'wedge')end
    for j=0,2 do b.add('FlameRidge',V(.025,.1,.22)*s,CFrame.new(0,.17*s,(-.32+.2*j)*s),w.glow,NEON,0,'wedge')end
    local wings={}
    for _,sd in ipairs({-1,1})do
        local sh=V(sd*.12*s,.06*s,-.22*s);local list={}
        for j=0,4 do
            local phi=-.12+.24*j;local dir=V(sd*math.cos(phi),0,math.sin(phi));local L=(.96-.11*j)*s
            table.insert(list,feather(b,'Feather',sh,dir,V(0,-sd,0),L,(.2-.015*j)*s,j==0 and w.feather or w.body,SMOOTH))
            if j<3 then table.insert(list,b.add('FlameTip',V(.075,.075,.075)*s,CFrame.new(sh+dir*L),w.glow,NEON,0,'ball'))end
        end
        for j=0,1 do
            local phi=.1+.3*j;local dir=V(sd*math.cos(phi),0,math.sin(phi))
            table.insert(list,feather(b,'Covert',sh+V(0,.025*s,0),dir,V(0,-sd,0),(.4-.06*j)*s,.14*s,w.glow,NEON))
        end
        table.insert(wings,{sd=sd,sh=sh,list=list})
    end
    for _,wing in ipairs(wings)do
        b.move(wing.list,function(t,_,_,list,homes)
            local r=CFrame.new(wing.sh)*CFrame.Angles(0,0,wing.sd*(.12+.38*math.sin(t*4.5)))*CFrame.new(-wing.sh)
            for i,p in ipairs(list)do p.CFrame=r*homes[i]end
        end)
    end
    local tail={};local root=V(0,.02*s,.3*s)
    for j=-2,2 do
        local psi=j*.24;local dir=V(math.sin(psi),.05,math.cos(psi)).Unit;local L=(.82-.12*math.abs(j))*s
        table.insert(tail,feather(b,'TailFeather',root,dir,V(0,1,0),L,.12*s,j%2==0 and w.feather or w.body,SMOOTH))
        table.insert(tail,b.add('TailFlame',V(.08,.08,.08)*s,CFrame.new(root+dir*L),j==0 and w.core or w.glow,NEON,0,'ball'))
    end
    b.move(tail,function(t,_,_,list,homes)
        local r=CFrame.new(root)*CFrame.Angles(.06*math.sin(t*3.1),.14*math.sin(t*2.2),0)*CFrame.new(-root)
        for i,p in ipairs(list)do p.CFrame=r*homes[i]end
    end)
    local halo=b.add('Halo',V(1,1,1)*s,CFrame.new(0,0,-.15*s),w.glow,NEON,.86,'ball')
    b.move({halo},function(t,_,_,list)list[1].Transparency=.84+.06*math.sin(t*5)end)
    b.band(-.52*s,-.46*s,.12*s)
    return {tail=.4*s,tailSize=.2*s,band2={.12*s,.18*s,.155*s},nose=-.98*s,noseR=.1*s,bright=1.5}
end

W.eclipse=function(b)
    local s,w=b.s,b.w;local M=CFrame.new(0,0,-.5*s)
    local function grow(p,phase,t,at)local f=at and math.clamp((t-at)/.6,0,1)or 1;if phase<p then f=0 end;return f end
    local moon=b.add('BlackSun',V(.6,.6,.6)*s,M,w.body,GLASS,0,'ball');moon.Reflectance=.45
    b.add('CoronaDisc',V(.02,.84,.84)*s,M*CFrame.new(0,0,.08*s)*ZC,w.corona,NEON,.3,'cyl')
    local veil=b.add('CoronaVeil',V(.02,1.24,1.24)*s,M*CFrame.new(0,0,.12*s)*ZC,w.glow,FORCE,.5,'cyl')
    light(veil,w.light,1.4,math.max(4,s*4))
    local rim=b.ring('Rim',16,w.corona)
    b.move(rim,function(t,_,_,list)placeRing(list,M*XY,.33*s,t*.5,.035*s,.75);for i,p in ipairs(list)do p.Color=i%4==0 and hue(t*.12+i/16)or w.corona end end)
    local bead={b.add('DiamondBead',V(.12,.12,.12)*s,M,w.trim,NEON,0,'ball'),b.add('BeadFlare',V(.026,.34,.026)*s,M,w.trim,NEON),b.add('BeadFlare',V(.34,.026,.026)*s,M,w.trim,NEON)}
    b.move(bead,function(t,_,_,list)
        local at=M*CFrame.Angles(0,0,t*1.1)*CFrame.new(0,.34*s,-.03*s);local tw=.7+.3*math.sin(t*7)
        list[1].CFrame=at;for i=2,3 do list[i].CFrame=at*CFrame.Angles(0,0,math.pi/4);list[i].Size=list[i].Size*tw end
    end)
    local hull=b.rod('Hull',-.24*s,.56*s,.13*s,w.body,METAL);hull.Reflectance=.35
    b.rod('TailCone',.56*s,.74*s,.09*s,w.fins,METAL)
    b.rod('UmbraLine',-.04*s,0,.136*s,w.corona,NEON)
    b.band(.1*s,.18*s,.135*s)
    local edges={}
    for i=0,3 do
        local cf=CFrame.new(0,0,.5*s)*CFrame.Angles(0,0,math.pi/4+i*math.pi/2)*CFrame.new(0,.2*s,0)
        b.add('Fin',V(.03,.22,.36)*s,cf,w.fins,GLASS,0,'wedge').Reflectance=.4
        table.insert(edges,b.add('PrismEdge',V(.035,.035,.42)*s,cf*CFrame.Angles(-.55,0,0),w.core,NEON))
    end
    b.move(edges,function(t,_,_,list)for i,p in ipairs(list)do p.Color=hue(t*.08+i/4)end end)
    local rays=b.ring('Corona',16,w.corona);local len={};for i=1,16 do len[i]=(.14+.26*hash(i,51))*s end
    b.move(rays,function(t,phase,ph,list)
        local f=grow(2,phase,t,ph[2])
        for i,p in ipairs(list)do
            local L=math.max(.01,len[i]*f*(.8+.2*math.sin(t*3+i*1.7)))
            p.Size=V((i%2==0 and .034 or .022)*s,L,.03*s);p.CFrame=M*CFrame.Angles(0,0,i/16*TAU+t*.25)*CFrame.new(0,.32*s+L/2,0)
            p.Color=i%4==0 and hue(t*.12+i/16)or w.corona;p.Transparency=f<=0 and 1 or (i%2==0 and .1 or .3)
        end
    end)
    local long=b.ring('OuterCorona',8,w.glow);local len2={};for i=1,8 do len2[i]=(.5+.25*hash(i,52))*s end
    b.move(long,function(t,phase,ph,list)
        local f=grow(3,phase,t,ph[3])
        for i,p in ipairs(list)do
            local L=math.max(.01,len2[i]*f*(.85+.15*math.sin(t*2+i)))
            p.Size=V(.022*s,L,.022*s);p.CFrame=M*CFrame.Angles(0,0,(i+.5)/8*TAU-t*.18)*CFrame.new(0,.34*s+L/2,.02*s)
            p.Color=hue(t*.1+i/8);p.Transparency=f<=0 and 1 or .15
        end
    end)
    local halo=b.ring('Halo',10,w.trim)
    b.move(halo,function(t,phase,ph,list)
        local f=grow(3,phase,t,ph[3]);placeRing(list,M*CFrame.new(0,0,.04*s)*XY,(.62+.42*out2(f))*s,-t*.4,.026*s,.55)
        for i,p in ipairs(list)do p.Color=hue(t*.1+i/10+.3);p.Transparency=f<=0 and 1 or 1-.85*f end
    end)
    local glints={};for i=1,4 do glints[i]=b.add('PrismGlint',V(.07,.2,.07)*s,M,w.core,NEON)end
    b.move(glints,function(t,phase,ph,list)
        local f=grow(3,phase,t,ph[3])
        for i,p in ipairs(list)do
            p.CFrame=M*CFrame.Angles(0,0,-t*.9+i/4*TAU)*CFrame.new(0,(.72+.3*f)*s,math.sin(t*2+i)*.12*s)*CFrame.Angles(t*2,0,math.pi/4)
            p.Color=hue(t*.15+i*.25);p.Transparency=f<=0 and 1 or 1-f
        end
    end)
    return {tail=.78*s,tailSize=.2*s,band2={.3*s,.38*s,.135*s},nose=-.82*s,noseR=.14*s,phases=true,bright=1.3}
end

Tr.toxin=function(b,tail,tr,info)
    b.trail(tail,'MiasmaTrail',tr.smokeWidth*b.s*.9,ColorSequence.new(tr.haze,tr.smoke),4.4,ns(0,.72,.25,.58,1,1),ns(0,.5,1,3),.15)
    b.emitter('Drips',{Color=ColorSequence.new(tr.drip,tr.hot),Size=ns(0,.1*b.s,1,.03*b.s),Transparency=ns(0,.1,1,1),Lifetime=NumberRange.new(.8,1.2),Rate=20,Speed=NumberRange.new(.2,.8),
        SpreadAngle=Vector2.new(30,30),Acceleration=V(0,-6,0),LightEmission=.8},24)
    b.emitter('Bubbles',{Color=ColorSequence.new(tr.drip),Size=ns(0,.04*b.s,.7,.14*b.s,1,.16*b.s),Transparency=ns(0,.3,.85,.4,1,1),Lifetime=NumberRange.new(1,1.4),Rate=16,Speed=NumberRange.new(.3,.9),
        SpreadAngle=Vector2.new(180,180),Acceleration=V(0,.8,0),LightEmission=.5},22)
end
Tr.tsunami=function(b,tail,tr,info)
    for i=0,1 do b.orbit('FoamRibbon',.34*b.s,8,i*math.pi,.12*b.s,ColorSequence.new(tr.foam,tr.ribbon),ns(0,0,.6,.4,1,1),1)end
    b.trail(tail,'WakeTrail',tr.smokeWidth*b.s*.7,ColorSequence.new(tr.haze,tr.smoke),2.4,ns(0,.6,1,1),ns(0,.6,1,2.6),.3)
    b.emitter('Spray',{Color=ColorSequence.new(tr.foam,tr.ribbon),Size=ns(0,.1*b.s,1,.02*b.s),Transparency=ns(0,.1,1,1),Lifetime=NumberRange.new(.7,1.1),Rate=36,Speed=NumberRange.new(1,2.4),
        SpreadAngle=Vector2.new(60,60),Acceleration=V(0,-5,0),LightEmission=.5},40)
end
Tr.lava=function(b,tail,tr,info)
    b.trail(tail,'MagmaTrail',tr.width*b.s*.7,ColorSequence.new(tr.core,tr.hot),1.3,ns(0,.1,.5,.4,1,1),ns(0,1,1,.4),1)
    b.trail(tail,'AshTrail',tr.smokeWidth*b.s*.9,ColorSequence.new(tr.haze,tr.smoke),4.6,ns(0,.6,.3,.5,1,1),ns(0,.6,1,2.8),0)
    b.emitter('Cinders',{Color=ColorSequence.new(tr.ember,tr.hot),Size=ns(0,.12*b.s,1,.02*b.s),Transparency=ns(0,0,.7,.3,1,1),Lifetime=NumberRange.new(.9,1.3),Rate=40,Speed=NumberRange.new(.5,1.8),
        SpreadAngle=Vector2.new(70,70),Acceleration=V(0,-7,0),LightEmission=1},50)
end
Tr.thunder=function(b,tail,tr,info)
    b.trail(tail,'StormTrail',tr.smokeWidth*b.s*.9,ColorSequence.new(tr.haze,tr.smoke),4.2,ns(0,.55,.3,.45,1,1),ns(0,.7,1,2.6),0)
    for i=1,3 do b.arc('Lightning',tr.bolt,.05*b.s,(1.4+.5*i)*b.s)end
    b.emitter('Sparks',{Color=ColorSequence.new(tr.bolt,tr.spark),Size=ns(0,.1*b.s,1,0),Transparency=ns(0,0,1,.5),Lifetime=NumberRange.new(.2,.4),Rate=40,Speed=NumberRange.new(2,5),
        SpreadAngle=Vector2.new(180,180),LightEmission=1},16)
end
Tr.regal=function(b,tail,tr,info)
    for i=0,1 do b.orbit('GoldRibbon',.44*b.s,6,i*math.pi,.13*b.s,ColorSequence.new(tr.core,tr.ribbon),ns(0,0,.6,.35,1,1),1.3)end
    b.trail(tail,'VelvetTrail',tr.smokeWidth*b.s*.7,ColorSequence.new(tr.haze,tr.smoke),3.2,ns(0,.55,1,1),ns(0,.6,1,2.2),.2)
    b.emitter('Stardust',{Color=ColorSequence.new(tr.star,tr.ribbon),Size=ns(0,.05*b.s,.3,.14*b.s,1,0),Transparency=ns(0,0,1,.3),Lifetime=NumberRange.new(1,1.6),Rate=60,Speed=NumberRange.new(.3,1.2),
        SpreadAngle=Vector2.new(180,180),LightEmission=1,RotSpeed=NumberRange.new(-90,90)},96)
    b.emitter('Sapphires',{Color=ColorSequence.new(tr.jewel),Size=ns(0,.12*b.s,1,0),Transparency=ns(0,0,1,.4),Lifetime=NumberRange.new(.8,1.2),Rate=14,Speed=NumberRange.new(.4,1.4),
        SpreadAngle=Vector2.new(180,180),LightEmission=1},20)
end
Tr.firebird=function(b,tail,tr,info)
    for i=0,2 do b.orbit('FlameFeather',.36*b.s,-7,i*TAU/3,.18*b.s,cs(tr.core,tr.ribbon,tr.hot),ns(0,0,.5,.3,1,1),1.1)end
    b.trail(tail,'HeatTrail',tr.smokeWidth*b.s*.3,ColorSequence.new(tr.haze,tr.hot),1.3,ns(0,.4,1,1),ns(0,1,1,1.8),1)
    b.emitter('Embers',{Color=ColorSequence.new(tr.core,tr.ember),Size=ns(0,.12*b.s,1,0),Transparency=ns(0,0,1,.5),Lifetime=NumberRange.new(1,1.4),Rate=70,Speed=NumberRange.new(.6,2),
        SpreadAngle=Vector2.new(180,180),Acceleration=V(0,1.4,0),LightEmission=1},100)
    b.emitter('FlameLicks',{Color=ColorSequence.new(tr.core,tr.hot),Size=ns(0,.24*b.s,1,0),Transparency=ns(0,0,1,.5),Lifetime=NumberRange.new(.35,.55),Rate=36,Speed=NumberRange.new(1,2),
        SpreadAngle=Vector2.new(25,25),LightEmission=1},20)
end
Tr.eclipse=function(b,tail,tr,info)
    local colors=T.prism()
    b.trail(tail,'UmbraTrail',tr.smokeWidth*b.s*.85,ColorSequence.new(tr.haze,tr.smoke),4.4,ns(0,.35,.3,.3,1,1),ns(0,.5,1,2.8),0)
    for i=0,2 do b.orbit('CoronaRibbon',(.38+i*.12)*b.s,5-i*1.5,i*TAU/3,.15*b.s,i==0 and ColorSequence.new(tr.core,tr.ribbon)or colors,ns(0,0,.65,.35,1,1),1.7)end
    b.emitter('Glints',{Color=colors,Size=ns(0,.08*b.s,.5,.16*b.s,1,0),Transparency=ns(0,0,1,.3),Lifetime=NumberRange.new(1.2,1.6),Rate=50,Speed=NumberRange.new(.3,1.4),
        SpreadAngle=Vector2.new(180,180),LightEmission=1,RotSpeed=NumberRange.new(-120,120)},80)
    b.emitter('Motes',{Color=ColorSequence.new(tr.haze),Size=ns(0,.14*b.s,1,.3*b.s),Transparency=ns(0,.4,1,1),Lifetime=NumberRange.new(1.5,2),Rate=18,Speed=NumberRange.new(.2,.6),
        SpreadAngle=Vector2.new(180,180),LightEmission=0},36)
end

I.toxin=function(d)
    local R,s=d.R,d.skin
    local pool=d.add('ToxicPool','cyl',V(.05,1,1),CFrame.new(d.ground)*FLAT,s.gas,NEON,1)
    d.el(function(t)
        local r=math.max(.1,R*.78*out2(k(t,.1,1.4)));pool.Size=V(.05,r*2,r*2);pool.CFrame=CFrame.new(d.ground+UP*.08)*FLAT
        pool.Transparency=t<.1 and 1 or .5+.08*math.sin(t*4)+.42*k(t,3.6,5)
    end)
    for i=1,7 do
        local a=i/7*TAU+hash(i,21)*.6;local dir=V(math.cos(a),0,math.sin(a));local far=R*(.5+.3*hash(i,22))
        local p=d.add('GasCloud','ell',V(1,1,1),CFrame.new(d.ground),i%2==0 and s.gas or s.cap,SMOOTH,1)
        d.el(function(t)
            local g=out2(k(t,.15,2.2));local sz=R*(.18+.24*g)*(1+.08*math.sin(t*3+i))
            p.Size=V(sz*1.5,sz*.75,sz*1.5);p.CFrame=CFrame.new(d.ground+dir*far*g+UP*sz*.3)
            p.Transparency=t<.15 and 1 or .3+.7*k(t,3.4,5)
        end)
    end
    for i=1,8 do
        local a=hash(i,23)*TAU;local r0=R*.62*math.sqrt(hash(i,24));local at=d.ground+V(math.cos(a)*r0,0,math.sin(a)*r0)
        local p=d.add('Bubble','ball',V(1,1,1),CFrame.new(at),s.bubble,NEON,1)
        d.el(function(t)
            local cyc=(t*.9+hash(i,25))%1;local sz=R*.1*out2(cyc)*(.6+.4*hash(i,26))
            p.Size=Vector3.one*math.max(.05,sz);p.CFrame=CFrame.new(at+UP*(R*.05+cyc*R*.22))
            p.Transparency=(t<.4 or t>4.2 or cyc>.92)and 1 or .25+.5*cyc
        end)
    end
    radiusRing(d,s.ring,16,.2,3)
    d.emit(.05,{Color=ColorSequence.new(s.bubble,s.gas),Size=ns(0,R*.03,1,0),Transparency=ns(0,0,1,.6),Lifetime=NumberRange.new(1,1.6),Speed=NumberRange.new(R*.4,R*1),
        SpreadAngle=Vector2.new(60,60),Acceleration=V(0,-R*.6,0),LightEmission=.7},40)
end
I.tsunami=function(d)
    local R,s=d.R,d.skin
    local sheet=d.add('WaterSheet','cyl',V(.05,1,1),CFrame.new(d.ground)*FLAT,s.water,SMOOTH,1)
    local column=d.add('Geyser','cyl',V(1,1,1),CFrame.new(d.ground)*FLAT,s.water,GLASS,1)
    local foamTop=d.add('GeyserFoam','ell',V(1,1,1),CFrame.new(d.ground),s.foam,SMOOTH,1)
    d.el(function(t)
        local r=math.max(.1,R*1.02*out2(k(t,.1,1.6)));sheet.Size=V(.05,r*2,r*2);sheet.CFrame=CFrame.new(d.ground+UP*.06)*FLAT;sheet.Transparency=t<.1 and 1 or .7+.3*k(t,3,4.6)
        local h=R*1.1*out4(k(t,0,.35))*(1-in2(k(t,.9,2.1)));local wd=R*.17*(1+.6*k(t,.9,2.1))
        column.Size=V(math.max(.1,h),wd,wd);column.CFrame=CFrame.new(d.ground+UP*h/2)*FLAT;column.Transparency=h<.2 and 1 or .2
        foamTop.Size=V(wd*1.8,wd*.9,wd*1.8);foamTop.CFrame=CFrame.new(d.ground+UP*h);foamTop.Transparency=h<.2 and 1 or .1
    end)
    for i=1,8 do
        local a=i/8*TAU;local dir=V(math.cos(a),0,math.sin(a))
        local p=d.add('Splash','block',V(1,1,1),CFrame.new(d.ground),s.foam,SMOOTH,1)
        d.el(function(t)
            local L=math.max(.05,R*.34*out2(k(t,.05,.6))*(1-k(t,1,1.6)))
            p.Size=V(R*.04,L,R*.04);p.CFrame=CFrame.new(d.ground+dir*R*.17)*CFrame.Angles(0,-a,0)*CFrame.Angles(0,0,-.55)*CFrame.new(0,L/2,0)
            p.Transparency=t<.05 and 1 or .1+.9*k(t,1,1.6)
        end)
    end
    local n=12
    for i=1,n do
        local a=(i-.5)/n*TAU;local dir=V(math.cos(a),0,math.sin(a))
        local wall=d.add('Wave','wedge',V(1,1,1),CFrame.new(d.ground),s.water,GLASS,1)
        local foam=d.add('WaveFoam','block',V(1,1,1),CFrame.new(d.ground),s.foam,NEON,1)
        d.el(function(t)
            local g=out2(k(t,.08,1.5));local r=R*(.2+.8*g)
            local h=math.max(.05,R*.34*math.sin(math.pi*math.min(.98,.12+g*.86))^.6*(1-k(t,1.5,2.4)))
            local wd,depth=TAU*r/n*1.03,R*.24;local at=d.ground+dir*r;local cf=CFrame.lookAt(at,at-dir)
            wall.Size=V(wd,h,depth);wall.CFrame=cf*CFrame.new(0,h/2,0)
            foam.Size=V(wd,R*.045,R*.08);foam.CFrame=cf*CFrame.new(0,h,depth/2-R*.03)
            local tr=t<.08 and 1 or .2+.8*k(t,1.6,2.6);wall.Transparency=tr;foam.Transparency=math.max(tr,.05)
        end)
    end
    radiusRing(d,s.ring,12,.9,2.8)
    d.emit(.08,{Color=ColorSequence.new(s.foam,s.water),Size=ns(0,R*.03,1,0),Transparency=ns(0,0,1,.6),Lifetime=NumberRange.new(1,1.6),Speed=NumberRange.new(R*.6,R*1.2),
        SpreadAngle=Vector2.new(40,40),Acceleration=V(0,-R*1.2,0),LightEmission=.4},50)
end
I.lava=function(d)
    local R,s=d.R,d.skin
    local pool=d.add('MagmaPool','cyl',V(.05,1,1),CFrame.new(d.ground)*FLAT,s.magma,NEON,1)
    local fount=d.add('Fountain','cyl',V(1,1,1),CFrame.new(d.ground)*FLAT,s.magma,NEON,1)
    d.el(function(t)
        local r=math.max(.1,R*.5*out2(k(t,.05,.9)));pool.Size=V(.05,r*2,r*2);pool.CFrame=CFrame.new(d.ground+UP*.08)*FLAT
        pool.Color=s.magma:Lerp(s.ember,k(t,1.5,3.5));pool.Transparency=t<.05 and 1 or .05+.95*k(t,3.6,5)
        local h=R*.8*out4(k(t,0,.3))*(1-in2(k(t,1,2.2)));local wd=R*.11*(1-.4*k(t,1,2.2))
        fount.Size=V(math.max(.1,h),wd,wd);fount.CFrame=CFrame.new(d.ground+UP*h/2)*FLAT;fount.Transparency=h<.2 and 1 or .05
    end)
    for i=1,10 do
        local a=i/10*TAU+hash(i,31)*.5;local dir=V(math.cos(a),0,math.sin(a));local vh=R*(.2+.3*hash(i,32));local vy=R*(1.3+.7*hash(i,33));local tl=vy/(R*1.2)
        local p=d.add('LavaBomb','ball',Vector3.one*R*(.06+.04*hash(i,34)),CFrame.new(d.ground),s.magma,NEON,1)
        d.el(function(t)
            local u=math.min(t-.05,tl);if u<0 then p.Transparency=1;return end
            local y=math.max(0,vy*u-R*1.2*u*u);p.CFrame=CFrame.new(d.ground+dir*vh*u+UP*(y+R*.03))
            p.Color=s.magma:Lerp(s.rock,k(t,tl,tl+1.6));p.Transparency=k(t,3.8,5)
        end)
    end
    for i=1,8 do
        local a=i/8*TAU+hash(i,35)*.4;local kink=a+(hash(i,37)-.5)*.6;local L1,L2=R*(.3+.15*hash(i,36)),R*(.25+.2*hash(i,38))
        local segs={d.add('Fissure','block',V(1,1,1),CFrame.new(d.ground),s.magma,NEON,1),d.add('Fissure','block',V(1,1,1),CFrame.new(d.ground),s.magma,NEON,1)}
        d.el(function(t)
            local g=out2(k(t,.1,.8));local p0=d.ground+UP*.12+V(math.cos(a),0,math.sin(a))*R*.12
            local p1=p0+V(math.cos(a),0,math.sin(a))*L1*math.min(1,g*2);local p2=p1+V(math.cos(kink),0,math.sin(kink))*L2*math.max(0,g*2-1)
            local pts={p0,p1,p2}
            for j,p in ipairs(segs)do
                if t<.1 then p.Transparency=1 else span(p,pts[j],pts[j+1],math.max(.06,R*.03*(1.2-.4*j)));if (pts[j+1]-pts[j]).Magnitude>.02 then p.Transparency=k(t,3.6,5)end end
                p.Color=s.magma:Lerp(s.ember,k(t,2,4))
            end
        end)
    end
    radiusRing(d,s.ring,12,.2,3)
    d.emit(.05,{Color=ColorSequence.new(s.core,s.magma),Size=ns(0,R*.035,1,0),Transparency=ns(0,0,1,.4),Lifetime=NumberRange.new(1,1.8),Speed=NumberRange.new(R*.6,R*1.4),
        SpreadAngle=Vector2.new(35,35),Acceleration=V(0,-R*1.1,0),LightEmission=1},55)
end
I.thunder=function(d)
    local R,s=d.R,d.skin;local top=R*1.25
    local cloud=d.add('StormCloud','ell',V(1,1,1),CFrame.new(d.ground),s.cloud,SMOOTH,1)
    local lobes={};for i=1,3 do lobes[i]=d.add('CloudLobe','ell',V(1,1,1),CFrame.new(d.ground),s.cap,SMOOTH,1)end
    local glow=not d.reduced and light(cloud,s.bolt,0,math.min(60,R*2.4))
    d.el(function(t)
        local g=out2(k(t,0,.5));local fade=k(t,3,4.5);local strike=t>.05 and t<3.2 and (t%.21)<.07
        cloud.Size=V(R*(.6+.9*g),R*(.12+.14*g),R*(.6+.9*g));cloud.CFrame=CFrame.new(d.ground+UP*top);cloud.Transparency=t<.02 and 1 or .12+.88*fade
        cloud.Color=strike and s.cap:Lerp(s.bolt,.45)or s.cloud
        for i,p in ipairs(lobes)do
            local a=i/3*TAU+t*.2;p.Size=V(R*.55,R*.24,R*.55)*g+Vector3.one*.1
            p.CFrame=CFrame.new(d.ground+UP*(top+R*.09)+V(math.cos(a),0,math.sin(a))*R*.38*g);p.Transparency=t<.02 and 1 or .2+.8*fade
        end
        if glow then glow.Brightness=strike and 6 or 0 end
    end)
    for i=1,6 do
        local segs={};for j=1,4 do segs[j]=d.add('Lightning','block',V(.1,.1,.1),CFrame.new(d.ground),s.bolt,NEON,1)end
        local mark=d.add('StrikeMark','cyl',V(.05,1,1),CFrame.new(d.ground)*FLAT,s.fire,NEON,1)
        d.el(function(t)
            local period=.42;local u=t+hash(i,40)*period;local n=math.floor(u/period);local ph=u%period
            local on=t>.05 and t<3.2 and ph<.19
            local a=hash(i,n+1)*TAU;local r=R*(.12+.82*math.sqrt(hash(i+9,n+1)))
            local hit=d.ground+V(math.cos(a)*r,.1,math.sin(a)*r);local from=d.ground+UP*top+V(math.cos(a)*r*.45,0,math.sin(a)*r*.45)
            local prev=from
            for j=1,4 do
                local at=from:Lerp(hit,j/4);if j<4 then at+=V(hash(i*7+j,n)-.5,0,hash(i*5+j,n)-.5)*R*.24 end
                local p=segs[j];if on then span(p,prev,at,math.max(.1,R*.034));p.Transparency=0 else p.Transparency=1 end;prev=at
            end
            mark.Size=V(.05,R*.18,R*.18);mark.CFrame=CFrame.new(hit+UP*.03)*FLAT
            mark.Transparency=(t<.05 or t>3.4)and 1 or on and .05 or math.min(1,.35+ph*1.8)
        end)
    end
    local ring=radiusRing(d,s.ring,16,.15,2.8)
    d.el(function(t)local step=math.floor(t/.06);if t<2.8 then for i,p in ipairs(ring)do if hash(i,step)<.22 then p.Transparency=math.max(p.Transparency,.7)end end end end)
    d.emit(.06,{Color=ColorSequence.new(s.bolt,s.fire),Size=ns(0,R*.03,1,0),Transparency=ns(0,0,1,.5),Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(R*.9,R*1.8),
        SpreadAngle=Vector2.new(85,85),LightEmission=1},50)
end
I.regal=function(d)
    local R,s=d.R,d.skin;local cr=R*.56
    for i=1,8 do
        local tall=i%2==1;local H=R*(tall and 1.15 or .7);local a=i/8*TAU;local hw=R*(tall and .1 or .08)
        local w1=d.add('CrownPoint','wedge',V(1,1,1),CFrame.new(d.ground),s.gold,METAL,1)
        local w2=d.add('CrownPoint','wedge',V(1,1,1),CFrame.new(d.ground),s.gold,METAL,1)
        local jewel=d.add('CrownJewel','ball',Vector3.one*R*(tall and .14 or .09),CFrame.new(d.ground),tall and s.jewel or s.core,NEON,1)
        d.el(function(t)
            local g=out4(k(t,.1+.03*i,.7+.03*i));local h=math.max(.05,H*g);local aa=a+t*.16
            local dir=V(math.cos(aa),0,math.sin(aa));local tan=V(-math.sin(aa),0,math.cos(aa));local base=d.ground+dir*cr
            local cf=CFrame.lookAt(base,base+UP*.93+dir*.37,tan)*CFrame.new(0,0,-h/2)
            w1.Size=V(R*.03,hw,h);w1.CFrame=cf*CFrame.new(0,hw/2,0);w2.Size=w1.Size;w2.CFrame=cf*CFrame.new(0,-hw/2,0)*CFrame.Angles(0,0,math.pi)
            jewel.CFrame=cf*CFrame.new(0,0,-h/2)
            local tr=t<.1 and 1 or .05+.95*k(t,3,4.2);w1.Transparency=tr;w2.Transparency=tr;jewel.Transparency=tr
        end)
    end
    local band=d.ring('CrownBand',12,s.gold)
    d.el(function(t)
        local g=out4(k(t,.1,.6));placeRing(band,CFrame.new(d.ground+UP*R*.1*g),cr*1.02,t*.16,math.max(.1,R*.05),.95)
        for _,p in ipairs(band)do p.Transparency=t<.1 and 1 or .05+.95*k(t,3,4.2)end
    end)
    local orb=d.add('RoyalOrb','ball',V(1,1,1),CFrame.new(d.ground),s.gold,NEON,1)
    local glint={d.add('StarGlint','block',V(1,1,1),CFrame.new(d.ground),s.core,NEON,1),d.add('StarGlint','block',V(1,1,1),CFrame.new(d.ground),s.core,NEON,1)}
    if not d.reduced then local l=light(orb,s.gold,0,math.min(60,R*2.2));d.el(function(t)l.Brightness=4*k(t,.1,.3)*(1-k(t,1.5,3.2))end)end
    d.el(function(t)
        local y=R*(.2+.75*out2(k(t,.2,1.2)));local o=R*.22*out2(k(t,.2,.6));local c=d.ground+UP*y
        orb.Size=Vector3.one*math.max(.1,o);orb.CFrame=CFrame.new(c);orb.Transparency=t<.2 and 1 or .05+.95*k(t,2.6,3.6)
        local f=math.sin(math.pi*k(t,.4,1.4));local L=R*.9*f
        for j,p in ipairs(glint)do p.Size=V(math.max(.05,R*.03),math.max(.05,L),math.max(.05,R*.03));p.CFrame=CFrame.new(c)*CFrame.Angles(0,t*.5,j==1 and math.pi/4 or -math.pi/4);p.Transparency=f<.05 and 1 or .15 end
    end)
    radiusRing(d,s.ring,16,.15,3)
    d.emit(.15,{Color=ColorSequence.new(s.core,s.gold),Size=ns(0,R*.025,.4,R*.04,1,0),Transparency=ns(0,0,1,.3),Lifetime=NumberRange.new(1.2,2),Speed=NumberRange.new(R*.5,R*1.3),
        SpreadAngle=Vector2.new(55,55),Acceleration=V(0,-R*.3,0),LightEmission=1,RotSpeed=NumberRange.new(-90,90)},110)
    d.emit(.3,{Color=ColorSequence.new(s.jewel),Size=ns(0,R*.03,1,0),Transparency=ns(0,0,1,.4),Lifetime=NumberRange.new(1,1.6),Speed=NumberRange.new(R*.4,R*1),
        SpreadAngle=Vector2.new(70,70),LightEmission=1},30)
end
I.firebird=function(d)
    local R,s=d.R,d.skin
    local function centre(t)return d.ground+UP*R*(.5+.95*out2(k(t,.1,1.3)))end
    local pillar=d.add('FirePillar','cyl',V(1,1,1),CFrame.new(d.ground)*FLAT,s.fire,NEON,1)
    local body=d.add('PhoenixBody','ell',V(1,1,1),CFrame.new(d.ground),s.wing,NEON,1)
    local head=d.add('PhoenixHead','ball',V(1,1,1),CFrame.new(d.ground),s.core,NEON,1)
    local crest={};for i=1,3 do crest[i]=d.add('PhoenixCrest','wedge',V(1,1,1),CFrame.new(d.ground),s.feather,NEON,1)end
    if not d.reduced then local l=light(body,s.fire,0,math.min(60,R*2.4));d.el(function(t)l.Brightness=5*k(t,.1,.3)*(1-k(t,2.2,3.4))end)end
    local function alpha(t)return t<.15 and 1 or .05+.95*k(t,2.5,3.5)end
    d.el(function(t)
        local c=centre(t);local g=out2(k(t,.1,.6))
        local h=(c-d.ground).Magnitude;local wd=R*.12*(1-.5*k(t,1.2,2.6))
        pillar.Size=V(math.max(.1,h),wd,wd);pillar.CFrame=CFrame.new(d.ground+UP*h/2)*FLAT;pillar.Transparency=t<.1 and 1 or .2+.8*k(t,1.4,2.8)
        body.Size=V(R*.22,R*.55,R*.22)*g+Vector3.one*.1;body.CFrame=CFrame.new(c);body.Transparency=alpha(t)
        local hc=c+UP*R*.35*g;head.Size=Vector3.one*math.max(.1,R*.17*g);head.CFrame=CFrame.new(hc);head.Transparency=alpha(t)
        for i,p in ipairs(crest)do
            local L=R*(.16+.04*(2-math.abs(i-2)))*g;local tilt=(i-2)*.45
            p.Size=V(R*.02,R*.07,math.max(.05,L));p.CFrame=CFrame.new(hc)*CFrame.Angles(0,0,tilt)*CFrame.Angles(-math.pi/2+.35,0,0)*CFrame.new(0,0,-L/2)
            p.Transparency=alpha(t)
        end
    end)
    for _,sd in ipairs({-1,1})do
        for j=1,5 do
            local f1=d.add('WingFeather','wedge',V(1,1,1),CFrame.new(d.ground),j%2==1 and s.wing or s.feather,NEON,1)
            local f2=j<=3 and d.add('WingGlow','wedge',V(1,1,1),CFrame.new(d.ground),s.core,NEON,1)
            d.el(function(t)
                local c=centre(t)+UP*R*.08;local g=out2(k(t,.25,.9))
                local beat=.3*math.sin((t-.9)*5)*k(t,.9,1.1)*(1-k(t,2,2.6))
                local beta=(.2+.05*j)+((.4+.27*j)-(.2+.05*j))*g+beat
                local dir=V(sd*math.sin(beta),math.cos(beta),0);local L=R*(1.1-.1*j)*(.35+.65*g)
                local Z=-dir;local X=V(0,0,sd);local Y=Z:Cross(X)
                f1.Size=V(R*.025,R*(.26-.02*j),L);f1.CFrame=CFrame.fromMatrix(c+dir*L/2+V(0,0,-.01*j*R),X,Y,Z);f1.Transparency=alpha(t)
                if f2 then f2.Size=V(R*.02,R*.08,L*.75);f2.CFrame=CFrame.fromMatrix(c+dir*L*.42+V(0,0,R*.02),X,Y,Z);f2.Transparency=math.max(alpha(t),.2)end
            end)
        end
    end
    for j=1,5 do
        local p=d.add('TailFeather','wedge',V(1,1,1),CFrame.new(d.ground),j%2==0 and s.feather or s.wing,NEON,1)
        d.el(function(t)
            local c=centre(t);local g=out2(k(t,.2,.8));local psi=(j-3)*.32+.06*math.sin(t*3);local dir=V(math.sin(psi),-math.cos(psi),.25).Unit
            local L=R*(.7-.08*math.abs(j-3))*(.3+.7*g);local Z=-dir;local X=V(0,0,1);local Y=Z:Cross(X)
            p.Size=V(R*.022,R*.13,L);p.CFrame=CFrame.fromMatrix(c-UP*R*.2+dir*L/2,X,Y,Z);p.Transparency=alpha(t)
        end)
    end
    radiusRing(d,s.ring,16,.15,3)
    d.emit(2.5,{Color=ColorSequence.new(s.core,s.fire),Size=ns(0,R*.035,1,0),Transparency=ns(0,0,1,.4),Lifetime=NumberRange.new(1,1.8),Speed=NumberRange.new(R*.3,R*.9),
        SpreadAngle=Vector2.new(180,180),Acceleration=V(0,R*.3,0),LightEmission=1},90)
    d.emit(.05,{Color=ColorSequence.new(s.feather,s.fire),Size=ns(0,R*.03,1,0),Transparency=ns(0,0,1,.4),Lifetime=NumberRange.new(1,1.6),Speed=NumberRange.new(R*.5,R*1.3),
        SpreadAngle=Vector2.new(55,55),Acceleration=V(0,R*.2,0),LightEmission=1},50)
end
I.eclipse=function(d)
    local R,s=d.R,d.skin;local bang=.6
    local sun=d.add('WhiteSun','ball',V(1,1,1),CFrame.new(d.ground),s.corona,NEON,1)
    local moon=d.add('BlackSun','ball',V(1,1,1),CFrame.new(d.ground),s.void,GLASS,1);moon.Reflectance=.4
    local umbra=d.add('Umbra','cyl',V(.05,1,1),CFrame.new(d.ground)*FLAT,s.void,SMOOTH,1)
    local bead=d.add('DiamondRing','ball',V(1,1,1),CFrame.new(d.ground),s.flash,NEON,1)
    local glow=d.add('CoronaGlow','ball',V(1,1,1),CFrame.new(d.ground),s.corona,NEON,1)
    local rim=d.ring('CoronaRim',16,s.corona)
    local rays=d.ring('CoronaRay',16,s.corona)
    local function centre(t)return d.ground+UP*R*(.7+.3*out2(k(t-bang,0,2)))end
    local function moonR(t)return R*.21*out2(k(t,0,.2))*(.92+.14*out2(k(t,.08,bang)))*(1-k(t-bang,3,3.8))end
    d.el(function(t)
        local tb=t-bang;local c=centre(t);local rs=R*.21*out2(k(t,0,.2));local cover=out2(k(t,.08,bang));local mr=moonR(t)
        sun.Size=Vector3.one*math.max(.1,rs*2);sun.CFrame=CFrame.new(c);sun.Transparency=(rs<.05 or tb>0)and 1 or 0
        moon.Size=Vector3.one*math.max(.1,mr*2);moon.CFrame=CFrame.new(c+V(.8,.5,.35).Unit*rs*2.2*(1-cover));moon.Transparency=mr<.05 and 1 or 0
        local u=R*out2(k(t,.05,bang));umbra.Size=V(.05,math.max(.1,u*2),math.max(.1,u*2));umbra.CFrame=CFrame.new(d.ground+UP*.1)*FLAT
        umbra.Transparency=t<.05 and 1 or tb<0 and .7-.35*cover or .35+.65*k(tb,0,.9)
        local cg=tb<0 and k(cover,.8,1)or 1-k(tb,3,3.8);glow.Size=Vector3.one*math.max(.1,mr*2*(1.45+.12*math.sin(t*4)+.5*out2(k(tb,0,.4))*(1-k(tb,.4,1.4))));glow.CFrame=CFrame.new(c)
        glow.Color=s.corona:Lerp(hue(t*.15+.6),.35);glow.Transparency=(cg<=0 or mr<.05)and 1 or 1-.2*cg
        local f=1-math.abs(tb)/.22;bead.Size=Vector3.one*math.max(.1,R*(.06+.3*math.max(0,f)^2));bead.CFrame=CFrame.new(c+V(-1,.4,.6).Unit*mr*1.05);bead.Transparency=f<=0 and 1 or 0
        local on=k(cover,.75,1);local rr=mr*(1.3+.25*math.sin(t*5))
        placeRing(rim,CFrame.new(c),rr,t*.7,math.max(.08,R*.022),.7)
        for i,p in ipairs(rim)do p.Color=i%4==0 and hue(t*.2+i/16)or s.corona;p.Transparency=(on<=0 or mr<.05)and 1 or 1-.9*on end
        for i,p in ipairs(rays)do
            local a=i/16*TAU+t*.2;local e=(hash(i,61)-.5)*.9;local dir=V(math.cos(a)*math.cos(e),math.sin(e),math.sin(a)*math.cos(e))
            local L=tb<0 and R*.12*on*(.7+.3*hash(i,60))or R*((.16+.62*out2(k(tb,0,.45))*(1-k(tb,1.2,2.2)))*(.55+.45*hash(i,60)))*(1-k(tb,3,3.8))
            if L<.05 or mr<.05 then p.Transparency=1 else span(p,c+dir*mr*1.15,c+dir*(mr*1.15+L),math.max(.08,R*.022));p.Color=i%3==0 and hue(t*.2+i/16)or s.corona;p.Transparency=.1 end
        end
    end)
    local ground1,ground2,orbit,orbit2=d.ring('EclipseRing',16,s.corona),d.ring('PrismRing',16,s.ring),d.ring('CoronaHoop',12,s.corona),d.ring('CoronaHoop',12,s.corona)
    d.el(function(t)
        local tb=t-bang;local c=centre(t)
        if tb<0 then for _,l in ipairs({ground1,ground2,orbit,orbit2})do for _,p in ipairs(l)do p.Transparency=1 end end;return end
        placeRing(ground1,CFrame.new(d.ground+UP*.16),R*(.12+.88*out4(k(tb,0,.6))),t*.3,math.max(.08,R*.026),.72)
        for _,p in ipairs(ground1)do p.Transparency=.05+.95*k(tb,2.6,3.6)end
        placeRing(ground2,CFrame.new(d.ground+UP*.2),R*(.12+1.38*out4(k(tb,.05,1.1))),-t*.4,math.max(.08,R*.02),.6)
        for i,p in ipairs(ground2)do p.Color=hue(t*.3+i/16);p.Transparency=.1+.9*k(tb,.5,1.2)end
        placeRing(orbit,CFrame.new(c)*CFrame.Angles(0,t*.6,0)*XY,R*(.25+.65*out2(k(tb,0,.9))),t*1.2,math.max(.08,R*.02),.7)
        for i,p in ipairs(orbit)do p.Color=i%2==0 and hue(t*.25+i/12)or s.corona;p.Transparency=.1+.9*k(tb,1,2)end
        placeRing(orbit2,CFrame.new(c)*CFrame.Angles(0,-t*.6+math.pi/2,0)*CFrame.Angles(0,0,.5)*XY,R*(.25+.5*out2(k(tb,.1,1))),-t*1.2,math.max(.08,R*.02),.7)
        for i,p in ipairs(orbit2)do p.Color=hue(t*.25+i/12+.5);p.Transparency=.1+.9*k(tb,1.1,2.1)end
    end)
    local under=d.parts.CapGlow
    if under then d.el(function(t)under.Color=hue(t*.2+.55)end)end
    d.emit(bang,{Color=T.prism(),Size=ns(0,R*.03,.4,R*.04,1,0),Transparency=ns(0,0,1,.3),Lifetime=NumberRange.new(1.2,2),Speed=NumberRange.new(R*.6,R*1.5),
        SpreadAngle=Vector2.new(75,75),LightEmission=1,RotSpeed=NumberRange.new(-120,120)},140)
end
I.delay.eclipse=.6
end
