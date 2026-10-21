return function(T)
local W,Tr,I=T.warheads,T.trails,T.impacts
local V=Vector3.new
local UP=Vector3.yAxis
local NEON,METAL,SMOOTH,GLASS,ICE=Enum.Material.Neon,Enum.Material.Metal,Enum.Material.SmoothPlastic,Enum.Material.Glass,Enum.Material.Ice
local FLAT=CFrame.Angles(0,0,math.pi/2)
local XY=CFrame.Angles(math.pi/2,0,0)
local TAU=math.pi*2
local k,out2,out4,in2,hash=T.k,T.out2,T.out4,T.in2,T.hash
local radiusRing,span,placeRing=T.radiusRing,T.span,T.placeRing
local function ns(...)local a={...};local t={};for i=1,#a,2 do table.insert(t,NumberSequenceKeypoint.new(a[i],a[i+1]))end;return NumberSequence.new(t)end
local function cs(...)local a={...};local t={};for i,c in ipairs(a)do table.insert(t,ColorSequenceKeypoint.new((i-1)/(#a-1),c))end;return ColorSequence.new(t)end
local function light(part,color,brightness,range)
    local l=Instance.new('PointLight');l.Color=color;l.Brightness=brightness;l.Range=range;l.Shadows=false;l.Parent=part;return l
end
local function frame(root,dir,thick,L)return CFrame.fromMatrix(root+dir*L/2,thick,(-dir):Cross(thick),-dir)end
local function feather(b,name,root,dir,thick,L,width,color,material,tr)return b.add(name,V(.025*b.s,width,L),frame(root,dir,thick,L),color,material,tr or 0,'wedge')end
local function grow(p,phase,t,at)local f=at and math.clamp((t-at)/.6,0,1)or 1;if phase<p then f=0 end;return f end
local function hide(list)for _,p in ipairs(list)do p.Transparency=1 end end
local function snap(x,q)return math.floor(x/q+.5)*q end

W.dragonbreath=function(b)
    local s,w=b.s,b.w
    local skull=b.add('Skull',V(.38,.3,.5)*s,CFrame.new(0,.02*s,-.5*s),w.body,SMOOTH,0,'ell');skull.Reflectance=.2
    b.add('Snout',V(.26,.18,.36)*s,CFrame.new(0,0,-.82*s),w.body,SMOOTH,0,'ell')
    b.add('Brow',V(.3,.05,.16)*s,CFrame.new(0,.15*s,-.6*s),w.trim,METAL)
    b.rod('Neck',-.34*s,-.1*s,.13*s,w.fins,SMOOTH)
    for _,x in ipairs({-1,1})do
        b.add('Eye',V(.075,.06,.075)*s,CFrame.new(x*.13*s,.1*s,-.66*s),w.eye,NEON,0,'ball')
        b.add('Nostril',V(.045,.045,.045)*s,CFrame.new(x*.065*s,.07*s,-.97*s),w.core,NEON,0,'ball')
        local dir=V(x*.35,.42,.84).Unit
        feather(b,'Antler',V(x*.1*s,.12*s,-.56*s),dir,(dir:Cross(UP)).Unit,.46*s,.08*s,w.trim,METAL)
    end
    local jaw=b.add('Jaw',V(.22,.07,.3)*s,CFrame.new(0,-.1*s,-.78*s),w.fins,SMOOTH,0,'ell')
    local hinge=V(0,-.08*s,-.62*s)
    b.move({jaw},function(t,_,_,list,homes)list[1].CFrame=CFrame.new(hinge)*CFrame.Angles(.12+.12*math.sin(t*3),0,0)*CFrame.new(-hinge)*homes[1]end)
    local breath=b.add('BreathCore',V(.13,.13,.13)*s,CFrame.new(0,-.05*s,-.9*s),w.core,NEON,0,'ball')
    light(breath,w.light,1.6,math.max(4,s*4))
    local flames={};for i=1,3 do flames[i]=b.add('Flame',V(.1,.1,.2)*s,CFrame.identity,i==2 and w.core or w.glow,NEON,0,'ell')end
    b.move(flames,function(t,_,_,list)
        for i,p in ipairs(list)do
            local f=(t*1.8+i/3)%1;local a=i/3*TAU+t*5
            p.Size=V(.1,.1,.2)*s*(1-.6*f)+V(0,0,.12*s*f);p.CFrame=CFrame.new(math.cos(a)*.04*s*f,-.05*s+math.sin(a)*.04*s*f,(-.98-.34*f)*s);p.Transparency=.1+.85*f
        end
    end)
    local whiskers={};for i=1,4 do whiskers[i]=b.add('Whisker',V(.1,.1,.1),CFrame.identity,w.trim,NEON)end
    b.move(whiskers,function(t,_,_,list)
        for side=0,1 do
            local x=side==0 and -1 or 1;local p0=V(x*.09*s,.02*s,-.92*s)
            local p1=p0+V(x*.22*s,-.04*s+.04*s*math.sin(t*3+side),.2*s);local p2=p1+V(x*.16*s+.06*s*math.sin(t*2.4+side),.03*s,.3*s)
            span(list[side*2+1],p0,p1,.022*s);span(list[side*2+2],p1,p2,.016*s)
        end
    end)
    local mane={}
    for j=0,4 do table.insert(mane,b.add('Mane',V(.03,.14,.16)*s,CFrame.new(0,(.17-.012*j)*s,(-.46+.07*j)*s)*CFrame.Angles(.5,0,0),w.mane,NEON,0,'wedge'))end
    b.move(mane,function(t,_,_,list,homes)for i,p in ipairs(list)do p.CFrame=homes[i]*CFrame.Angles(0,.25*math.sin(t*4-i*.7),0)end end)
    local n=8;local coils,spines={},{}
    for i=1,n do
        coils[i]=b.add('Coil',Vector3.one*(.27-.016*i)*s,CFrame.new(0,0,(-.06+.105*(i-1))*s),i%2==0 and w.body or w.fins,SMOOTH,0,'ball')
        spines[i]=b.add('Spine',V(.03,.1,.13)*s,CFrame.new(0,.14*s,(-.06+.105*(i-1))*s),w.trim,METAL,0,'wedge')
    end
    local function at(i,t)
        local a=(.03+.15*i/n)*s;local ph=t*4.2-i*.75
        return V(a*math.sin(ph),.35*a*math.cos(ph),(-.06+.105*(i-1))*s)
    end
    local body={};for i=1,n do body[i]=coils[i]end;for i=1,n do body[n+i]=spines[i]end
    local claws={};for i=1,4 do claws[i]=b.add('Claw',V(.03,.06,.14)*s,CFrame.identity,w.trim,METAL,0,'wedge')end
    local fan={b.add('TailFan',V(.025,.16,.3)*s,CFrame.identity,w.trim,METAL,0,'wedge'),b.add('TailFan',V(.025,.16,.3)*s,CFrame.identity,w.trim,METAL,0,'wedge')}
    for _,p in ipairs(claws)do table.insert(body,p)end;for _,p in ipairs(fan)do table.insert(body,p)end
    b.move(body,function(t,_,_,list)
        for i=1,n do
            local p=at(i,t);local nx=at(math.min(n,i+1),t);local pr=at(math.max(1,i-1),t)
            local dir=(nx-pr).Unit;local r=(.27-.016*i)*s
            list[i].CFrame=CFrame.new(p)
            list[n+i].CFrame=CFrame.lookAt(p+UP*r*.5,p+UP*r*.5-dir)
        end
        for c,i in ipairs({2,2,5,5})do
            local x=c%2==0 and 1 or -1;local p=at(i,t);local r=(.27-.016*i)*s;local dir=V(x*.7,-.45,.55).Unit
            list[2*n+c].CFrame=frame(p+V(x*r*.4,-r*.2,0),dir,(dir:Cross(UP)).Unit,.14*s)
        end
        local tail=at(n,t);local back=(tail-at(n-1,t)).Unit
        for c=1,2 do
            local x=c==1 and -1 or 1;local dir=(back+V(x*.75,0,0)).Unit
            list[2*n+4+c].CFrame=frame(tail+back*.06*s,dir,V(0,1,0):Cross(dir).Unit:Cross(dir).Unit,.3*s)
        end
    end)
    local pearl={b.add('Pearl',V(.12,.12,.12)*s,CFrame.identity,w.eye,NEON,0,'ball'),b.add('PearlFlame',V(.24,.24,.24)*s,CFrame.identity,w.glow,NEON,.6,'ball')}
    b.move(pearl,function(t,_,_,list)
        local a=t*1.7;local c=CFrame.new(math.cos(a)*.46*s,.08*s+.06*s*math.sin(t*3),-.6*s+math.sin(a)*.4*s)
        list[1].CFrame=c;list[2].CFrame=c;list[2].Size=V(.24,.24,.24)*s*(.85+.15*math.sin(t*9));list[2].Transparency=.55+.1*math.sin(t*7)
    end)
    local aura=b.add('Aura',V(.9,.7,1.1)*s,CFrame.new(0,0,-.6*s),w.glow,NEON,.9,'ell')
    b.move({aura},function(t,_,_,list)list[1].Transparency=.87+.05*math.sin(t*4)end)
    b.band(-.3*s,-.24*s,.14*s)
    return {tail=.82*s,tailSize=.2*s,band2={-.2*s,-.15*s,.14*s},nose=-1*s,noseR=.12*s,bright=1.5}
end
W.gem=function(b)
    local s,w=b.s,b.w;local z0,r=-.18*s,.34*s
    local gem={};local chord=2*r*math.sin(math.pi/8)*1.06
    for i=0,7 do
        local a=i/8*TAU;local L=.78*s
        local pf=b.add('Pavilion',V(chord,r,L),CFrame.new(0,0,z0-L/2)*CFrame.Angles(0,0,a)*CFrame.new(0,r/2,0),i%2==0 and w.gem or w.nose,GLASS,.12)
        pf.Reflectance=.5;table.insert(gem,pf)
        local Lc=.3*s
        local cf=b.add('CrownFacet',V(chord,r,Lc),CFrame.new(0,0,z0+Lc/2)*CFrame.Angles(0,0,a+math.pi/8)*CFrame.new(0,r/2,0)*CFrame.Angles(0,math.pi,0),i%2==0 and w.nose or w.gem,ICE,.08)
        cf.Reflectance=.4;table.insert(gem,cf)
    end
    table.insert(gem,b.rod('Table',z0+.13*s,z0+.15*s,r*.56,w.nose,GLASS,.05))
    local fire=b.add('GemFire',V(.3,.3,.42)*s,CFrame.new(0,0,z0-.12*s),w.core,NEON,.15,'ell');table.insert(gem,fire)
    light(fire,w.light,1.8,math.max(4,s*4.5))
    b.move(gem,function(t,_,_,list,homes)local r2=CFrame.Angles(0,0,t*.8);for i,p in ipairs(list)do p.CFrame=r2*homes[i]end;list[#list].Size=V(.3,.3,.42)*s*(.9+.1*math.sin(t*5))end)
    b.rod('Girdle',z0-.012*s,z0+.012*s,r*1.03,w.trim,METAL)
    local hull=b.rod('Body',z0+.2*s,.64*s,.14*s,w.body,METAL);hull.Reflectance=.35
    for _,z in ipairs({.22,.5})do b.rod('GoldCollar',z*s,(z+.035)*s,.15*s,w.trim,METAL)end
    for i=0,3 do
        local a=i/4*TAU+math.pi/4;local p=b.add('Prong',V(.1,.1,.1),CFrame.identity,w.trim,METAL)
        span(p,V(math.cos(a)*.14*s,math.sin(a)*.14*s,z0+.32*s),V(math.cos(a)*r*1.02,math.sin(a)*r*1.02,z0-.02*s),.045*s)
    end
    local glints={};for i=1,2 do glints[i]=b.add('FacetGlint',V(.1,.1,.1),CFrame.identity,w.spark,NEON)end
    b.move(glints,function(t,_,_,list)
        for i,p in ipairs(list)do local a=t*2.6+i*math.pi;span(p,V(math.cos(a)*r*1.04,math.sin(a)*r*1.04,z0),V(0,0,z0-.78*s),.018*s);p.Transparency=.1+.5*math.abs(math.sin(t*1.3+i))end
    end)
    local stars={};for _=1,4 do table.insert(stars,b.add('Star',V(.024,.2,.024)*s,CFrame.identity,w.spark,NEON));table.insert(stars,b.add('Star',V(.2,.024,.024)*s,CFrame.identity,w.spark,NEON))end
    b.move(stars,function(t,_,_,list)
        for i=1,4 do
            local hop=math.floor(t*1.6+i*.37);local u=.15+.6*hash(i,hop);local a=hash(i+4,hop)*TAU
            local at=CFrame.new(math.cos(a)*r*(1-u)*1.08,math.sin(a)*r*(1-u)*1.08,z0-.78*s*u)*CFrame.Angles(0,0,t*2)
            local tw=math.abs(math.sin((t*1.6+i*.37)%1*math.pi))
            for j=0,1 do local p=list[i*2-1+j];p.CFrame=at;p.Size=p.Size*(.2+.8*tw)end
        end
    end)
    local sats={};for i=1,3 do sats[i]=b.add('Satellite',V(.11,.11,.15)*s,CFrame.identity,i==2 and w.glow or w.gem,GLASS,.1,'ell')end
    b.move(sats,function(t,_,_,list)for i,p in ipairs(list)do local a=t*1.5+i/3*TAU;p.CFrame=CFrame.new(math.cos(a)*.34*s,math.sin(a)*.34*s,(.3+.06*math.sin(t*2+i))*s)*CFrame.Angles(t*2,t*3,0)end end)
    for i=0,3 do
        local cf=CFrame.new(0,0,.52*s)*CFrame.Angles(0,0,math.pi/4+i*math.pi/2)*CFrame.new(0,.22*s,0)*CFrame.Angles(-.4,0,0)
        b.add('Fin',V(.03,.22,.3)*s,cf,w.fins,METAL).Reflectance=.3
        b.add('FinGilt',V(.04,.035,.32)*s,cf*CFrame.new(0,.11*s,0),w.trim,METAL)
    end
    b.rod('EngineBell',.62*s,.72*s,.11*s,w.trim,METAL)
    local halo=b.add('Halo',V(1,1,1)*s,CFrame.new(0,0,z0-.2*s),w.glow,NEON,.9,'ball')
    b.move({halo},function(t,_,_,list)list[1].Transparency=.87+.05*math.sin(t*4)end)
    b.band(.3*s,.36*s,.15*s)
    return {tail=.74*s,tailSize=.2*s,band2={.42*s,.47*s,.15*s},nose=-.96*s,noseR=.1*s,bright=1.6}
end

W.judgment=function(b)
    local s,w=b.s,b.w
    for _,roll in ipairs({0,math.pi/2})do b.blade('SpearHead',CFrame.new(0,0,-.84*s)*CFrame.Angles(0,0,roll),.56*s,.2*s,.03*s,w.blade,NEON)end
    local tip=b.add('SpearGlow',V(.15,.15,.15)*s,CFrame.new(0,0,-.58*s),w.core,NEON,0,'ball')
    b.add('Guard',V(.52,.05,.08)*s,CFrame.new(0,0,-.54*s),w.trim,METAL)
    b.rod('Shaft',-.56*s,.7*s,.075*s,w.body,GLASS,.3)
    b.rod('LightCore',-.56*s,.68*s,.03*s,w.core,NEON)
    b.rod('Grip',.02*s,.52*s,.1*s,w.body,SMOOTH)
    for _,z in ipairs({-.5,.02})do b.rod('GoldCollar',z*s,(z+.04)*s,.11*s,w.trim,METAL)end
    b.add('Pommel',V(.14,.14,.14)*s,CFrame.new(0,0,.74*s),w.trim,METAL,0,'ball')
    for i=0,2 do b.add('Fin',V(.025,.14,.2)*s,CFrame.new(0,0,.62*s)*CFrame.Angles(0,0,i*TAU/3)*CFrame.new(0,.13*s,0),w.fins,SMOOTH,0,'wedge')end
    local radiance=b.add('Radiance',V(.7,.7,.9)*s,CFrame.new(0,0,-.72*s),w.glow,NEON,.85,'ell')
    light(radiance,w.light,1.6,math.max(4,s*4.5))
    b.move({radiance,tip},function(t,_,_,list)list[1].Transparency=.83+.06*math.sin(t*4);list[2].Size=V(.15,.15,.15)*s*(.9+.15*math.sin(t*6))end)
    local pairs_={{p=1,z=-.2,phi=-.15,L=.82},{p=2,z=-.44,phi=-.62,L=.66},{p=3,z=.3,phi=.42,L=.6}}
    for n,wp in ipairs(pairs_)do
        for _,sd in ipairs({-1,1})do
            local root=V(sd*.06*s,0,wp.z*s);local list={}
            for j=0,3 do table.insert(list,b.add('Feather',V(.1,.1,.1),CFrame.identity,j%2==0 and w.feather or w.body,SMOOTH,0,'wedge'))end
            table.insert(list,b.add('FeatherLight',V(.1,.1,.1),CFrame.identity,w.glow,NEON,0,'wedge'))
            b.move(list,function(t,phase,ph,l)
                local f=wp.p==1 and 1 or grow(wp.p,phase,t,ph[wp.p]);if f<=0 then hide(l);return end
                local beat=CFrame.new(root)*CFrame.Angles(0,0,sd*(.1+.2*math.sin(t*3.2+n)))*CFrame.new(-root);local g=out2(f)
                for j=0,4 do
                    local jj=math.min(j,3);local phi=1.5+((wp.phi+.18*jj)-1.5)*g;local dir=V(sd*math.cos(phi),0,math.sin(phi))
                    local L=(wp.L-.1*jj)*s*(j==4 and .96 or 1);local p=l[j+1]
                    p.Size=V((j==4 and .03 or .025)*s,(j==4 and .05 or .15-.012*jj)*s,L);p.CFrame=beat*frame(root+V(0,j==4 and .012*s or 0,0),dir,V(0,-sd,0),L)
                    p.Transparency=j==4 and math.max(.1,1-f)or 1-f
                end
            end)
        end
    end
    local rays={};for i=1,8 do rays[i]=b.add('Ray',V(.1,.1,.1),CFrame.identity,w.glow,NEON)end
    b.move(rays,function(t,phase,ph,list)
        local f=grow(2,phase,t,ph[2]);if f<=0 then hide(list);return end
        local c=V(0,0,-.78*s)
        for i,p in ipairs(list)do
            local a=i/8*TAU+t*.4;local dir=V(math.cos(a),0,math.sin(a));local L=(.16+.12*math.abs(math.sin(t*2.5+i)))*s*f
            span(p,c+dir*.14*s,c+dir*(.14*s+L),.016*s);p.Transparency=.15+.5*(1-f)
        end
    end)
    local C=CFrame.new(0,.1*s,-.18*s)
    local halo=b.ring('Halo',16,w.halo)
    b.move(halo,function(t,phase,ph,list)
        local f=grow(3,phase,t,ph[3]);placeRing(list,C,(.4+.16*out2(f))*s,t*.6,.03*s,.66)
        for _,p in ipairs(list)do p.Transparency=f<=0 and 1 or 1-.9*f end
    end)
    local glints={};for i=1,4 do glints[i]=b.add('HaloGlint',V(.08,.08,.08)*s,CFrame.identity,w.core,NEON,0,'ball')end
    b.move(glints,function(t,phase,ph,list)
        local f=grow(3,phase,t,ph[3])
        for i,p in ipairs(list)do local a=-t*1.1+i/4*TAU;p.CFrame=C*CFrame.new(math.cos(a)*(.4+.16*f)*s,0,math.sin(a)*(.4+.16*f)*s);p.Size=Vector3.one*.08*s*(.7+.5*math.abs(math.sin(t*4+i)));p.Transparency=f<=0 and 1 or 1-f end
    end)
    local motes={};for i=1,4 do motes[i]=b.add('Plume',V(.02,.06,.13)*s,CFrame.identity,w.feather,NEON,0,'wedge')end
    b.move(motes,function(t,_,_,list)
        for i,p in ipairs(list)do local f=(t*.6+i/4)%1;local x=(i%2==0 and 1 or -1)*(.3+.3*f)*s
            p.CFrame=CFrame.new(x,.06*s*math.sin(t*3+i),(-.1+.9*f)*s)*CFrame.Angles(t*2+i,t*3,0);p.Transparency=f>.85 and 1 or .2+.6*f end
    end)
    b.band(.1*s,.16*s,.105*s)
    return {tail=.82*s,tailSize=.2*s,band2={.38*s,.44*s,.105*s},nose=-1.12*s,noseR=.1*s,phases=true,bright=1.5}
end
W.delete=function(b)
    local s,w=b.s,b.w;local zc=-.26*s;local C=CFrame.new(0,0,zc)
    local function glitch(t,phase)local q=math.floor(t/.11);return hash(q,7)>(phase>=3 and .45 or phase==2 and .6 or .84),q end
    for i,z in ipairs({-.64,-.84,-1})do b.add('PixelNose',Vector3.one*(.4-.13*i)*s,CFrame.new(0,0,z*s),i==3 and w.nose or w.body,i==3 and NEON or GLASS,0).Reflectance=.3 end
    b.rod('Spine',-.04*s,.62*s,.12*s,w.fins,METAL).Reflectance=.3
    b.rod('DataLine',.06*s,.56*s,.124*s,w.trim,NEON,.6)
    for i,z in ipairs({.66,.78})do b.add('PixelTail',Vector3.one*(.32-.1*i)*s,CFrame.new(0,0,z*s),w.body,GLASS,0)end
    for i=0,3 do b.add('PixelFin',V(.03,.17,.17)*s,CFrame.new(0,0,.6*s)*CFrame.Angles(0,0,i*math.pi/2)*CFrame.new(0,.2*s,0),i%2==0 and w.trim or w.pixel,NEON,.15)end
    local subs={};local q=.135*s
    for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do local p=b.add('SubCube',Vector3.one*.26*s,C*CFrame.new(x*q,y*q,z*q),w.body,GLASS,0);p.Reflectance=.35;table.insert(subs,p)end end end
    local core=b.add('Core',Vector3.one*.16*s,C,w.core,NEON,0)
    table.insert(subs,core)
    b.move(subs,function(t,phase,ph,list,homes)
        local f2,f3=grow(2,phase,t,ph[2]),grow(3,phase,t,ph[3]);local on,qq=glitch(t,phase)
        for i=1,8 do
            local d=homes[i].Position-C.Position;local out=(.03+.04*math.sin(t*3+i))*s*f2+.05*s*f3
            local jit=on and V(hash(i,qq)-.5,hash(i+8,qq)-.5,0)*.08*s or Vector3.zero
            local at=C.Position+d+d.Unit*out+jit;list[i].CFrame=CFrame.new(snap(at.X,.02*s),snap(at.Y,.02*s),snap(at.Z,.02*s))
        end
        list[9].CFrame=C*CFrame.Angles(0,0,snap(t*2,math.pi/4))*CFrame.Angles(snap(t*1.3,math.pi/4),0,0);list[9].Size=Vector3.one*.16*s*(1+.4*f2)
    end)
    local edges=b.ring('Wire',12,w.trim)
    b.move(edges,function(t,phase,ph,list)
        local f3=grow(3,phase,t,ph[3]);local h=(.29+.17*out2(f3)+.01*math.sin(t*6))*s;local on=glitch(t,phase);local th=.022*s;local n=0
        for axis=1,3 do for a=-1,1,2 do for c=-1,1,2 do
            n+=1;local p=list[n]
            local pos=axis==1 and V(0,a*h,c*h)or axis==2 and V(a*h,0,c*h)or V(a*h,c*h,0)
            p.Size=axis==1 and V(2*h,th,th)or axis==2 and V(th,2*h,th)or V(th,th,2*h);p.CFrame=C*CFrame.Angles(0,0,f3*t*.5)*CFrame.new(pos)
            p.Color=on and n%3==0 and w.pixel or w.trim;p.Transparency=.05
        end end end
    end)
    local ghosts={b.add('GhostCyan',Vector3.one*.58*s,C,w.trim,NEON,1),b.add('GhostMagenta',Vector3.one*.58*s,C,w.pixel,NEON,1)}
    local tears={};for i=1,4 do tears[i]=b.add('Tear',V(.7,.035,.12)*s,C,i%2==0 and w.pixel or w.trim,NEON,1)end
    local flicker={};for _,p in ipairs(ghosts)do table.insert(flicker,p)end;for _,p in ipairs(tears)do table.insert(flicker,p)end
    b.move(flicker,function(t,phase,_,list)
        local on,qq=glitch(t,phase)
        for i=1,2 do local p=list[i];local sd=i==1 and 1 or -1;p.CFrame=C*CFrame.new(sd*(.03+.04*hash(i,qq))*s,0,0);p.Transparency=on and .72 or 1 end
        for i=3,6 do local p=list[i];local y=(hash(i,qq)-.5)*.5*s;p.CFrame=C*CFrame.new((hash(i+3,qq)-.5)*.24*s,y,(hash(i+6,qq)-.5)*.3*s);p.Transparency=on and hash(i,qq+1)>.3 and .1 or 1 end
    end)
    local scan=b.add('Scanline',V(.62,.62,.012)*s,C,w.trim,NEON,.6)
    b.move({scan},function(t,_,_,list)local f=(t*.9)%1;list[1].CFrame=CFrame.new(0,0,(-.7+1.4*f)*s);list[1].Transparency=.55+.4*math.abs(2*f-1)end)
    local chunks={};for i=1,10 do chunks[i]=b.add('Pixel',Vector3.one*.075*s,C,i%2==0 and w.pixel or w.trim,NEON,1)end
    b.move(chunks,function(t,phase,ph,list)
        local f=grow(2,phase,t,ph[2]);if f<=0 then hide(list);return end
        for i,p in ipairs(list)do
            local hop=math.floor(t*3+i*.29);local a=snap(hash(i,hop)*TAU,TAU/8);local r=(.42+.12*hash(i+9,hop))*s*f
            p.CFrame=C*CFrame.new(snap(math.cos(a)*r,.05*s),snap(math.sin(a)*r,.05*s),snap((hash(i+3,hop)-.5)*.5*s,.05*s));p.Transparency=.05+.9*(1-f)
        end
    end)
    local code={};for i=1,16 do code[i]=b.add('Code',V(.1,.1,.1),C,i%5==0 and w.pixel or w.code,NEON,1)end
    b.move(code,function(t,phase,ph,list)
        local f=grow(3,phase,t,ph[3]);if f<=0 then hide(list);return end
        for i,p in ipairs(list)do
            local lane=(i-1)%4;local u=(t*.8+hash(i,3))%1;local L=(.05+.1*hash(i,4))*s
            local x=(lane%2==0 and -1 or 1)*.24*s;local y=(lane<2 and -1 or 1)*.24*s
            p.Size=V(.022*s,.022*s,L);p.CFrame=CFrame.new(x,y,(-.8+1.6*u)*s);p.Transparency=(u<.05 or u>.95)and 1 or .05+.9*(1-f)
        end
    end)
    local ring=b.ring('PixelRing',12,w.pixel)
    b.move(ring,function(t,phase,ph,list)
        local f=grow(3,phase,t,ph[3]);local r=(.5+.14*out2(f))*s;local rot=snap(t*.9,TAU/24)
        for i,p in ipairs(list)do p.Size=Vector3.one*.075*s;p.CFrame=C*CFrame.Angles(0,rot+i/12*TAU,0)*CFrame.new(0,0,-r);p.Transparency=f<=0 and 1 or 1-.95*f end
    end)
    b.band(.12*s,.18*s,.13*s)
    return {tail=.86*s,tailSize=.2*s,band2={.4*s,.46*s,.13*s},nose=-1.08*s,noseR=.1*s,phases=true,bright=1.4}
end
W.maw=function(b)
    local s,w=b.s,b.w
    local hull=b.add('Hull',V(.44,.38,1.3)*s,CFrame.new(0,0,-.05*s),w.body,SMOOTH,0,'ell');hull.Reflectance=.35
    b.add('WaterSheath',V(.56,.5,1.16)*s,CFrame.new(0,0,-.15*s),w.water,GLASS,.6,'ell')
    b.add('UpperJaw',V(.36,.2,.44)*s,CFrame.new(0,.04*s,-.78*s),w.body,SMOOTH,0,'ell').Reflectance=.35
    for i=-1,1 do b.add('Tooth',V(.03,.07,.03)*s,CFrame.new(i*.08*s,-.06*s,(-.94+.04*math.abs(i))*s)*CFrame.Angles(0,0,math.pi),w.trim,SMOOTH,0,'wedge')end
    local hinge=V(0,-.07*s,-.6*s)
    local jaw={b.add('LowerJaw',V(.3,.08,.38)*s,CFrame.new(0,-.11*s,-.78*s),w.fins,SMOOTH,0,'ell')}
    for i=-1,1 do table.insert(jaw,b.add('Tooth',V(.03,.06,.03)*s,CFrame.new(i*.07*s,-.05*s,(-.92+.04*math.abs(i))*s),w.trim,SMOOTH,0,'wedge'))end
    local throat=b.add('Throat',V(.14,.14,.14)*s,CFrame.new(0,-.03*s,-.7*s),w.maw,NEON,0,'ball')
    table.insert(jaw,throat)
    b.move(jaw,function(t,phase,ph,list,homes)
        local f=grow(3,phase,t,ph[3]);local open=.08+.04*math.sin(t*2)+.4*f*(.7+.3*math.sin(t*3))
        local r=CFrame.new(hinge)*CFrame.Angles(open,0,0)*CFrame.new(-hinge)
        for i=1,4 do list[i].CFrame=r*homes[i]end
        list[5].Size=Vector3.one*(.1+.1*f)*s;list[5].Transparency=.4-.35*f
    end)
    local eyes={}
    for _,x in ipairs({-1,1})do
        table.insert(eyes,b.add('Eye',V(.07,.07,.07)*s,CFrame.new(x*.14*s,.1*s,-.72*s),w.eye,NEON,0,'ball'))
        table.insert(eyes,b.add('EyeGlow',V(.14,.14,.14)*s,CFrame.new(x*.14*s,.1*s,-.72*s),w.glow,NEON,.55,'ball'))
    end
    b.move(eyes,function(t,phase,ph,list)
        local f=grow(3,phase,t,ph[3])
        for i=2,4,2 do local p=list[i];p.Size=Vector3.one*(.13+.05*math.sin(t*3)+.08*f)*s;p.Color=w.glow:Lerp(w.halo,f);p.Transparency=.5+.15*math.sin(t*3)end
    end)
    local spots={}
    for i=1,10 do local x=i%2==0 and 1 or -1;local z=(-.45+.1*(i-1))*s;table.insert(spots,b.add('LightSpot',V(.05,.05,.05)*s,CFrame.new(x*(.19-.06*math.abs(z/s))*s,(.06-.03*(i%3))*s,z),w.core,NEON,0,'ball'))end
    b.move(spots,function(t,_,_,list,homes)for i,p in ipairs(list)do p.Size=Vector3.one*s*(.035+.035*math.max(0,math.sin(t*3-i*.6)))end end)
    for i=0,3 do b.add('Dorsal',V(.03,.12,.2)*s,CFrame.new(0,.2*s,(-.32+.24*i)*s)*CFrame.Angles(.4,0,0),i%2==0 and w.fins or w.body,SMOOTH,0,'wedge')end
    local fluke={}
    for _,x in ipairs({-1,1})do local dir=V(x*.8,0,.6).Unit;table.insert(fluke,feather(b,'Fluke',V(0,0,.56*s),dir,V(0,1,0),.38*s,.18*s,w.fins,SMOOTH))end
    b.move(fluke,function(t,_,_,list,homes)local r=CFrame.new(0,0,.5*s)*CFrame.Angles(0,.3*math.sin(t*2.6),0)*CFrame.new(0,0,-.5*s);for i,p in ipairs(list)do p.CFrame=r*homes[i]end end)
    local tent={};for i=1,24 do tent[i]=b.add(i>18 and 'TentacleTip' or 'Tentacle',i>18 and V(.07,.07,.07)*s or V(.1,.1,.1),CFrame.identity,i>18 and w.halo or (i%3==0 and w.core or w.fins),NEON,1,i>18 and 'ball' or nil)end
    for i=1,18 do tent[i].Material=i%3==0 and NEON or SMOOTH end
    b.move(tent,function(t,phase,ph,list)
        local f=grow(2,phase,t,ph[2]);if f<=0 then hide(list);return end
        for n=0,5 do
            local x=n%2==0 and -1 or 1;local z=(.08+.2*math.floor(n/2))*s;local prev=V(x*.17*s,-.03*s,z)
            local base=.9+.35*math.floor(n/2)
            for j=1,3 do
                local u=j/3;local a=base+u*(.7+.25*math.sin(t*2.2+n))*f;local L=.22*s*f
                local at=prev+V(x*math.cos(a)*.8,(.04*math.sin(t*3+n+j)),math.sin(a))*L
                span(list[n*3+j],prev,at,(.07-.017*j)*s);list[n*3+j].Transparency=1-f;prev=at
            end
            list[18+n+1].CFrame=CFrame.new(prev);list[18+n+1].Transparency=1-f
        end
    end)
    local swirl=b.ring('Swirl',8,w.core)
    b.move(swirl,function(t,phase,ph,list)
        local f=grow(2,phase,t,ph[2]);placeRing(list,CFrame.new(0,0,-.42*s)*XY,(.3+.04*math.sin(t*4))*s,t*3,.03*s,.55)
        for i,p in ipairs(list)do p.Color=i%2==0 and w.core or w.eye;p.Transparency=f<=0 and 1 or 1-.8*f end
    end)
    local E=CFrame.new(0,.2*s,-.52*s)
    local eye={b.add('GiantEye',V(.24,.16,.24)*s,E,w.eye,NEON,1,'ell'),b.add('Pupil',V(.04,.03,.17)*s,E*CFrame.new(0,.07*s,0),w.body,SMOOTH,1)}
    b.move(eye,function(t,phase,ph,list,homes)
        local f=grow(3,phase,t,ph[3]);list[1].Size=V(.24,.16,.24)*s*math.max(.05,out2(f));list[1].Transparency=f<=0 and 1 or 1-f
        list[2].Size=V(.04+.03*(.5+.5*math.sin(t*2)),.03,.17)*s*math.max(.05,f);list[2].Transparency=f<=0 and 1 or 1-f
    end)
    local iris=b.ring('Iris',8,w.halo)
    b.move(iris,function(t,phase,ph,list)local f=grow(3,phase,t,ph[3]);placeRing(list,E*CFrame.new(0,.04*s,0),(.15+.02*math.sin(t*3))*s*math.max(.1,f),-t*1.4,.02*s,.7);for _,p in ipairs(list)do p.Transparency=f<=0 and 1 or 1-.9*f end end)
    local halo=b.ring('Halo',12,w.halo)
    b.move(halo,function(t,phase,ph,list)local f=grow(3,phase,t,ph[3]);placeRing(list,CFrame.new(0,.06*s,-.12*s),(.52+.14*out2(f))*s,t*.5,.03*s,.62);for _,p in ipairs(list)do p.Transparency=f<=0 and 1 or 1-.88*f end end)
    b.band(-.3*s,-.24*s,.205*s)
    return {tail=.66*s,tailSize=.2*s,band2={.16*s,.22*s,.2*s},nose=-1*s,noseR=.12*s,phases=true,bright=1.4}
end

Tr.dragonbreath=function(b,tail,tr,info)
    b.orbit('DragonBody',.42*b.s,4.5,0,.26*b.s,cs(tr.core,tr.ribbon,tr.scale),ns(0,0,.6,.3,1,1),1.6)
    b.orbit('GoldBelly',.42*b.s,4.5,.45,.08*b.s,ColorSequence.new(tr.gold,tr.ribbon),ns(0,0,.7,.4,1,1),1.5)
    b.trail(tail,'JadeMist',tr.smokeWidth*b.s*.7,ColorSequence.new(tr.haze,tr.smoke),3.2,ns(0,.55,1,1),ns(0,.6,1,2.4),.3)
    b.emitter('Scales',{Color=ColorSequence.new(tr.scale,tr.gold),Size=ns(0,.06*b.s,.3,.15*b.s,1,0),Transparency=ns(0,0,1,.4),Lifetime=NumberRange.new(1,1.5),Rate=60,Speed=NumberRange.new(.3,1.2),
        SpreadAngle=Vector2.new(180,180),LightEmission=1,RotSpeed=NumberRange.new(-120,120)},90)
    b.emitter('FlameWisps',{Color=ColorSequence.new(tr.core,tr.hot),Size=ns(0,.22*b.s,1,0),Transparency=ns(0,0,1,.5),Lifetime=NumberRange.new(.4,.6),Rate=40,Speed=NumberRange.new(1,2),
        SpreadAngle=Vector2.new(25,25),LightEmission=1},24)
end
Tr.gem=function(b,tail,tr,info)
    for i=0,1 do b.orbit('CrystalRibbon',.36*b.s,7,i*math.pi,.1*b.s,ColorSequence.new(tr.spark,tr.ribbon),ns(0,0,.6,.35,1,1),1.3)end
    b.trail(tail,'FrostHaze',tr.smokeWidth*b.s*.6,ColorSequence.new(tr.haze,tr.smoke),2.6,ns(0,.6,1,1),ns(0,.5,1,2),.4)
    b.emitter('Twinkles',{Color=ColorSequence.new(tr.spark,tr.ribbon),Size=ns(0,0,.2,.2*b.s,.5,.06*b.s,1,0),Transparency=ns(0,0,1,.2),Lifetime=NumberRange.new(.9,1.4),Rate=70,Speed=NumberRange.new(.2,1),
        SpreadAngle=Vector2.new(180,180),LightEmission=1,RotSpeed=NumberRange.new(-60,60)},100)
    b.emitter('GemDust',{Color=ColorSequence.new(tr.hot,tr.gold),Size=ns(0,.1*b.s,1,.02*b.s),Transparency=ns(0,0,1,.5),Lifetime=NumberRange.new(.9,1.3),Rate=20,Speed=NumberRange.new(.4,1.2),
        SpreadAngle=Vector2.new(70,70),Acceleration=V(0,-4,0),LightEmission=.8},26)
end
Tr.judgment=function(b,tail,tr,info)
    b.trail(tail,'RadianceTrail',tr.width*b.s*.8,ColorSequence.new(tr.core,tr.hot),1.4,ns(0,.2,.5,.5,1,1),ns(0,1,1,.6),1)
    for i=0,1 do b.orbit('GoldRibbon',.4*b.s,5,i*math.pi,.13*b.s,ColorSequence.new(tr.core,tr.ribbon),ns(0,0,.6,.35,1,1),1.6)end
    b.orbit('HaloRibbon',.55*b.s,-3,math.pi/2,.1*b.s,ColorSequence.new(tr.halo,tr.core),ns(0,.1,.7,.4,1,1),1.8)
    b.emitter('Feathers',{Color=ColorSequence.new(tr.feather),Size=ns(0,.16*b.s,1,.1*b.s),Transparency=ns(0,0,.7,.2,1,1),Lifetime=NumberRange.new(1.6,2.2),Rate=40,Speed=NumberRange.new(.2,.7),
        SpreadAngle=Vector2.new(180,180),Acceleration=V(0,-1.2,0),LightEmission=.4,RotSpeed=NumberRange.new(-90,90),Rotation=NumberRange.new(0,360)},90)
    b.emitter('HolyMotes',{Color=ColorSequence.new(tr.core,tr.halo),Size=ns(0,.05*b.s,.4,.13*b.s,1,0),Transparency=ns(0,0,1,.3),Lifetime=NumberRange.new(1,1.4),Rate=50,Speed=NumberRange.new(.3,1.2),
        SpreadAngle=Vector2.new(180,180),LightEmission=1},70)
end
Tr.delete=function(b,tail,tr,info)
    b.trail(tail,'ScanTrail',tr.smokeWidth*b.s*.8,ColorSequence.new(tr.haze,tr.smoke),3.6,ns(0,.45,.3,.4,1,1),ns(0,.6,1,2.2),0)
    b.orbit('CyanSplit',.34*b.s,9,0,.12*b.s,ColorSequence.new(tr.core,tr.ribbon),ns(0,0,.6,.35,1,1),1.2)
    b.orbit('MagentaSplit',.34*b.s,9,math.pi,.12*b.s,ColorSequence.new(tr.pixel,tr.ribbon),ns(0,0,.6,.35,1,1),1.2)
    for i=1,2 do b.arc('Tear',i==1 and tr.pixel or tr.ribbon,.05*b.s,(1.3+.4*i)*b.s)end
    b.emitter('Pixels',{Color=ColorSequence.new(tr.ribbon,tr.pixel),Size=ns(0,.14*b.s,.8,.1*b.s,1,0),Transparency=ns(0,0,.8,.2,1,1),Lifetime=NumberRange.new(1,1.5),Rate=60,Speed=NumberRange.new(.3,1.2),
        SpreadAngle=Vector2.new(180,180),LightEmission=1},90)
    b.emitter('CodeBits',{Color=ColorSequence.new(tr.core,tr.ribbon),Size=ns(0,.06*b.s,1,.03*b.s),Transparency=ns(0,0,1,.4),Lifetime=NumberRange.new(.6,.9),Rate=60,Speed=NumberRange.new(2,4),
        SpreadAngle=Vector2.new(15,15),LightEmission=1},54)
end
Tr.maw=function(b,tail,tr,info)
    b.trail(tail,'AbyssWake',tr.smokeWidth*b.s*.85,ColorSequence.new(tr.haze,tr.smoke),4,ns(0,.4,.3,.35,1,1),ns(0,.6,1,2.6),.1)
    b.orbit('TealTendril',.4*b.s,6,0,.15*b.s,ColorSequence.new(tr.core,tr.ribbon),ns(0,0,.6,.35,1,1),1.6)
    b.orbit('VioletTendril',.5*b.s,-4,math.pi,.11*b.s,ColorSequence.new(tr.violet,tr.ribbon),ns(0,0,.6,.4,1,1),1.7)
    b.emitter('Bubbles',{Color=ColorSequence.new(tr.bubble),Size=ns(0,.05*b.s,.7,.15*b.s,1,.17*b.s),Transparency=ns(0,.3,.85,.4,1,1),Lifetime=NumberRange.new(1.2,1.6),Rate=40,Speed=NumberRange.new(.3,.9),
        SpreadAngle=Vector2.new(180,180),Acceleration=V(0,1,0),LightEmission=.5},64)
    b.emitter('Biolume',{Color=ColorSequence.new(tr.core,tr.violet),Size=ns(0,.05*b.s,.4,.12*b.s,1,0),Transparency=ns(0,0,1,.3),Lifetime=NumberRange.new(1,1.5),Rate=50,Speed=NumberRange.new(.2,1),
        SpreadAngle=Vector2.new(180,180),LightEmission=1},75)
end

I.dragonbreath=function(d)
    local R,s=d.R,d.skin
    local pool=d.add('JadePool','cyl',V(.05,1,1),CFrame.new(d.ground)*FLAT,s.fire,NEON,1)
    d.el(function(t)local r=math.max(.1,R*.55*out2(k(t,.05,.6)));pool.Size=V(.05,r*2,r*2);pool.CFrame=CFrame.new(d.ground+UP*.08)*FLAT;pool.Transparency=t<.05 and 1 or .35+.65*k(t,2.8,4.2)end)
    for a=1,3 do
        local segs={};for j=1,4 do segs[j]=d.add('FlameVortex','block',V(.1,.1,.1),CFrame.new(d.ground),j%2==0 and s.flame or s.fire,NEON,1)end
        d.el(function(t)
            local g=out2(k(t,.05,.9));local top=R*1.2*g;local fade=k(t,2.6,3.8);local prev
            for j=0,4 do
                local u=j/4;local ang=a/3*TAU+u*TAU*.9-t*3.2;local r=R*(.5-.32*u)*(.6+.4*g)
                local at=d.ground+V(math.cos(ang)*r,.1+u*top,math.sin(ang)*r)
                if prev then local p=segs[j];if g<.02 then p.Transparency=1 else span(p,prev,at,math.max(.1,R*(.08-.04*u)));p.Transparency=.05+.95*fade end end
                prev=at
            end
        end)
    end
    local head=d.add('DragonHead','ell',V(1,1,1),CFrame.new(d.ground),s.jade,SMOOTH,1)
    local jaw=d.add('DragonJaw','ell',V(1,1,1),CFrame.new(d.ground),s.jade,SMOOTH,1)
    local horns={d.add('DragonHorn','block',V(1,1,1),CFrame.new(d.ground),s.gold,NEON,1),d.add('DragonHorn','block',V(1,1,1),CFrame.new(d.ground),s.gold,NEON,1)}
    local eyes={d.add('DragonEye','ball',V(1,1,1),CFrame.new(d.ground),s.gold,NEON,1),d.add('DragonEye','ball',V(1,1,1),CFrame.new(d.ground),s.gold,NEON,1)}
    if not d.reduced then local l=light(head,s.flame,0,math.min(60,R*2.2));d.el(function(t)l.Brightness=4*k(t,.2,.5)*(1-k(t,2,3.4))end)end
    d.el(function(t)
        local g=out2(k(t,.2,.8));local roar=math.sin(math.pi*k(t,.9,1.9));local c=d.ground+UP*R*(.4+.85*out2(k(t,.2,1.1)))
        local cf=CFrame.new(c)*CFrame.Angles(0,t*.7,0)*CFrame.Angles(.25+.75*roar,0,0);local tr=t<.2 and 1 or .05+.95*k(t,2.8,3.8)
        head.Size=V(R*.22,R*.18,R*.34)*g+Vector3.one*.1;head.CFrame=cf;head.Transparency=tr
        jaw.Size=V(R*.16,R*.06,R*.26)*g+Vector3.one*.1;jaw.CFrame=cf*CFrame.new(0,-R*.08*g,-R*.02*g)*CFrame.Angles(-(.15+.7*roar),0,0)*CFrame.new(0,0,-R*.06*g);jaw.Transparency=tr
        for i,sd in ipairs({-1,1})do
            if g<.05 then horns[i].Transparency=1;eyes[i].Transparency=1 else
                span(horns[i],cf*V(sd*R*.05*g,R*.07*g,R*.02*g),cf*V(sd*R*.13*g,R*.17*g,R*.22*g),math.max(.08,R*.03*g));horns[i].Transparency=tr
                eyes[i].Size=Vector3.one*math.max(.1,R*.045*g);eyes[i].CFrame=cf*CFrame.new(sd*R*.075*g,R*.045*g,-R*.08*g);eyes[i].Transparency=tr
            end
        end
    end)
    local roarA,roarB=d.ring('RoarRing',12,s.flame),d.ring('RoarRing',7,s.gold)
    local wave=d.add('RoarWave','cyl',V(.05,1,1),CFrame.new(d.ground)*FLAT,s.shock,NEON,1)
    d.el(function(t)
        local u=t-1.1;if u<0 then hide(roarA);hide(roarB);wave.Transparency=1;return end
        placeRing(roarA,CFrame.new(d.ground+UP*.3),R*(.15+1.25*out4(k(u,0,.9))),t*.5,math.max(.1,R*.03),.7)
        for _,p in ipairs(roarA)do p.Transparency=.05+.95*k(u,.4,1.1)end
        placeRing(roarB,CFrame.new(d.ground+UP*.35),R*(.1+1*out4(k(u,.12,1.1))),-t*.6,math.max(.08,R*.022),.55)
        for _,p in ipairs(roarB)do p.Transparency=.1+.9*k(u,.6,1.3)end
        local r=math.max(.1,R*(.2+1.1*out4(k(u,0,.8))));wave.Size=V(.05,r*2,r*2);wave.CFrame=CFrame.new(d.ground+UP*.25)*FLAT;wave.Transparency=.55+.45*k(u,0,.8)
    end)
    radiusRing(d,s.ring,16,.15,3)
    d.emit(.05,{Color=ColorSequence.new(s.flame,s.fire),Size=ns(0,R*.035,1,0),Transparency=ns(0,0,1,.4),Lifetime=NumberRange.new(1,1.7),Speed=NumberRange.new(R*.5,R*1.3),
        SpreadAngle=Vector2.new(60,60),Acceleration=V(0,R*.2,0),LightEmission=1},90)
    d.emit(1.1,{Color=ColorSequence.new(s.gold,s.flame),Size=ns(0,R*.025,.4,R*.035,1,0),Transparency=ns(0,0,1,.3),Lifetime=NumberRange.new(1,1.6),Speed=NumberRange.new(R*.6,R*1.4),
        SpreadAngle=Vector2.new(180,20),LightEmission=1,RotSpeed=NumberRange.new(-90,90)},60)
end
I.gem=function(d)
    local R,s=d.R,d.skin;local cut=1
    local function centre(t)return d.ground+UP*R*(.5+.25*out2(k(t,0,.7)))end
    local facets={}
    for i=1,16 do local p=d.add(i<=8 and 'Pavilion' or 'CrownFacet','wedge',V(1,1,1),CFrame.new(d.ground),i%2==0 and s.gem or s.core,i<=8 and GLASS or ICE,1);p.Reflectance=.45;facets[i]=p end
    local tbl=d.add('Table','cyl',V(1,1,1),CFrame.new(d.ground)*FLAT,s.core,GLASS,1)
    local fire=d.add('GemFire','ball',V(1,1,1),CFrame.new(d.ground),s.fire,NEON,1)
    if not d.reduced then local l=light(fire,s.fire,0,math.min(60,R*2.4));d.el(function(t)l.Brightness=5*k(t,.1,.4)*(1-k(t,cut,cut+1.6))end)end
    d.el(function(t)
        local g=out4(k(t,0,.5));local c=centre(t);local spin=t*1.1;local rd=R*.3*g+.05;local L=R*.44*g+.05;local Lc=R*.16*g+.05;local chord=2*rd*math.sin(math.pi/8)*1.06
        local tb=t-cut
        for i,p in ipairs(facets)do
            local n=(i-1)%8;local ang=spin+n/8*TAU+(i>8 and math.pi/8 or 0);local base=CFrame.new(c)*CFrame.Angles(0,ang,0)
            local home=i<=8 and base*CFrame.Angles(-math.pi/2,0,0)*CFrame.new(0,rd/2,-L/2)or base*CFrame.Angles(math.pi/2,0,0)*CFrame.new(0,rd/2,-Lc/2)
            p.Size=i<=8 and V(chord,rd,L)or V(chord,rd,Lc)
            if tb<0 then p.CFrame=home;p.Transparency=t<.02 and 1 or .12 else
                local dir=V(math.cos(ang),0,math.sin(ang));local u=math.min(tb,1.4)
                p.CFrame=CFrame.new(dir*R*.9*out2(k(tb,0,1.2))+UP*(R*1.1*u-R*1.4*u*u))*home*CFrame.Angles(tb*3,tb*2+i,0)
                p.Transparency=.12+.88*k(tb,.8,1.5)
            end
        end
        tbl.Size=V(.05,rd*1.1,rd*1.1);tbl.CFrame=CFrame.new(c+UP*Lc*.55)*FLAT;tbl.Transparency=(t<.02 or tb>0)and 1 or .1
        fire.Size=Vector3.one*math.max(.1,rd*1.1*(.9+.1*math.sin(t*6)));fire.CFrame=CFrame.new(c-UP*L*.25);fire.Transparency=(t<.02 or tb>.15)and 1 or .2
    end)
    local star={d.add('StarFlash','block',V(1,1,1),CFrame.new(d.ground),s.flash,NEON,1),d.add('StarFlash','block',V(1,1,1),CFrame.new(d.ground),s.flash,NEON,1)}
    d.el(function(t)
        local f=math.sin(math.pi*k(t,cut-.05,cut+.45));local c=centre(t)
        for j,p in ipairs(star)do p.Size=V(math.max(.1,R*.04),math.max(.1,R*.04),math.max(.1,R*1.6*f));p.CFrame=CFrame.new(c)*CFrame.Angles(0,t*.5+(j==1 and 0 or math.pi/2),0)*CFrame.Angles(.3,0,0);p.Transparency=f<.05 and 1 or .1 end
    end)
    for i=1,16 do
        local a=hash(i,71)*TAU;local r0=R*.92*math.sqrt(hash(i,72));local at=d.ground+V(math.cos(a)*r0,0,math.sin(a)*r0);local t0=cut+.1+.9*hash(i,73);local h0=R*(1.2+.5*hash(i,74))
        local p=d.add('GemShard','block',V(.05,.05,.12)*R*(.7+.5*hash(i,75)),CFrame.new(at),i%5==0 and s.gold or i%2==0 and s.gem or s.core,i%3==0 and NEON or GLASS,1);p.Reflectance=.5
        d.el(function(t)
            local u=t-t0;if u<0 then p.Transparency=1;return end
            local fall=math.min(1,u/.8);local y=h0*(1-in2(fall))
            p.CFrame=CFrame.new(at+UP*(y+R*.03))*CFrame.Angles(u*5*(1-fall)+i,u*3+i,.5);p.Transparency=fall<1 and .05 or (.05+.5*math.abs(math.sin(t*6+i)))*(1-k(t,3.4,4.4))+k(t,3.4,4.4)
        end)
    end
    radiusRing(d,s.ring,16,.15,3)
    d.emit(cut,{Color=ColorSequence.new(s.flash,s.gem),Size=ns(0,0,.2,R*.04,1,0),Transparency=ns(0,0,1,.2),Lifetime=NumberRange.new(1.2,1.8),Speed=NumberRange.new(R*.6,R*1.4),
        SpreadAngle=Vector2.new(180,180),Acceleration=V(0,-R*.5,0),LightEmission=1,RotSpeed=NumberRange.new(-90,90)},110)
    d.emit(.05,{Color=ColorSequence.new(s.core,s.fire),Size=ns(0,R*.03,1,0),Transparency=ns(0,0,1,.5),Lifetime=NumberRange.new(.8,1.2),Speed=NumberRange.new(R*.5,R*1.1),
        SpreadAngle=Vector2.new(55,55),LightEmission=1},40)
end
I.judgment=function(d)
    local R,s=d.R,d.skin;local bang=.5;local sky=R*3.2
    local spear=d.add('LightSpear','cyl',V(1,1,1),CFrame.new(d.ground)*FLAT,s.pillar,NEON,1)
    local blades={};for i=1,4 do blades[i]=d.add('SpearHead','wedge',V(1,1,1),CFrame.new(d.ground),s.gold,NEON,1)end
    d.el(function(t)
        local f=in2(k(t,0,bang));local tipY=sky*(1-f);local tr=t>=bang+.15 and 1 or 0
        local len=R*1.6;spear.Size=V(len,R*.07,R*.07);spear.CFrame=CFrame.new(d.ground+UP*(tipY+R*.32+len/2))*FLAT;spear.Transparency=tr
        for i,p in ipairs(blades)do
            local roll=(i-1)%2*math.pi/2+(i>2 and math.pi or 0);local h=R*.12
            p.Size=V(R*.02,h,R*.34);p.CFrame=CFrame.new(d.ground+UP*(tipY+R*.17))*CFrame.Angles(0,roll,0)*CFrame.Angles(-math.pi/2,0,0)*CFrame.new(0,h/2,0);p.Transparency=tr
        end
    end)
    local pillar=d.add('HolyPillar','cyl',V(1,1,1),CFrame.new(d.ground)*FLAT,s.pillar,NEON,1)
    local sheath=d.add('PillarSheath','cyl',V(1,1,1),CFrame.new(d.ground)*FLAT,s.fire,NEON,1)
    if not d.reduced then local l=light(pillar,s.pillar,0,math.min(60,R*2.6));d.el(function(t)l.Brightness=6*k(t,bang,bang+.15)*(1-k(t,bang+1.6,bang+3))end)end
    d.el(function(t)
        local tb=t-bang;if tb<0 then pillar.Transparency=1;sheath.Transparency=1;return end
        local h=math.max(.1,sky*out4(k(tb,0,.25)));local r=R*.1*(1-.5*k(tb,1.4,3))
        pillar.Size=V(h,r*2,r*2);pillar.CFrame=CFrame.new(d.ground+UP*h/2)*FLAT;pillar.Transparency=.05+.95*k(tb,2.4,3.4)
        sheath.Size=V(h*.95,r*5.5,r*5.5);sheath.CFrame=pillar.CFrame;sheath.Transparency=.6+.4*k(tb,1.8,3)
    end)
    for i=1,6 do
        local a=i/6*TAU+.3
        for j=1,3 do
            local p=d.add('WingOfLight','wedge',V(1,1,1),CFrame.new(d.ground),j==2 and s.pillar or s.feather,NEON,1)
            d.el(function(t)
                local tb=t-bang;if tb<.05 then p.Transparency=1;return end
                local g=out2(k(tb,.05,.9));local beat=.12*math.sin(tb*3+i)*k(tb,.9,1.2)
                local aa=a+(j-2)*.24;local dir=V(math.cos(aa),0,math.sin(aa));local beta=.15+(1.38-.15)*g+beat
                local fd=(dir*math.sin(beta)+UP*math.cos(beta)).Unit;local tan=UP:Cross(dir).Unit;local L=R*(.95-.12*math.abs(j-2))*(.35+.65*g)
                local root=d.ground+UP*R*.55+dir*R*.08;local Z=-fd;local X=tan:Cross(Z)
                p.Size=V(R*.02,R*(.2-.03*math.abs(j-2)),L);p.CFrame=CFrame.fromMatrix(root+fd*L/2,X,tan,Z);p.Transparency=.2+.8*k(tb,2.6,3.6)
            end)
        end
    end
    local halo,wave=d.ring('Halo',16,s.halo),d.ring('HaloWave',16,s.halo)
    d.el(function(t)
        local tb=t-bang;if tb<0 then hide(halo);hide(wave);return end
        local g=out2(k(tb,.1,.8));placeRing(halo,CFrame.new(d.ground+UP*R*(1.1+.4*g)),R*(.3+.25*g),t*.5,math.max(.1,R*.03),.68)
        for _,p in ipairs(halo)do p.Transparency=.05+.95*k(tb,2.8,3.8)end
        placeRing(wave,CFrame.new(d.ground+UP*.3),R*(.15+1.25*out4(k(tb,0,1))),-t*.4,math.max(.08,R*.026),.6)
        for _,p in ipairs(wave)do p.Transparency=.1+.9*k(tb,.5,1.2)end
    end)
    local seal=d.ring('Seal',12,s.gold)
    d.el(function(t)
        local tb=t-bang;if tb<0 then hide(seal);return end
        placeRing(seal,CFrame.new(d.ground+UP*.18),R*(.3+.25*out2(k(tb,0,.6))),-t*.35,math.max(.08,R*.02),.5)
        for _,p in ipairs(seal)do p.Transparency=.1+.9*k(tb,2.6,3.6)end
    end)
    for i=1,16 do
        local a=hash(i,81)*TAU;local r0=R*.95*math.sqrt(hash(i,82));local t0=bang+.3+.9*hash(i,83);local h0=R*(1.4+.6*hash(i,84))
        local p=d.add('FallingFeather','wedge',V(.025,.08,.22)*R,CFrame.new(d.ground),i%4==0 and s.halo or s.feather,i%4==0 and NEON or SMOOTH,1)
        d.el(function(t)
            local u=t-t0;if u<0 then p.Transparency=1;return end
            local y=math.max(0,h0-R*.5*u);local sway=math.sin(u*2.4+i)*R*.08
            p.CFrame=CFrame.new(d.ground+V(math.cos(a)*r0+sway,y+R*.02,math.sin(a)*r0))*CFrame.Angles(.4*math.sin(u*2.4+i),u*1.5+i,.3);p.Transparency=.1+.9*k(u,2.4,3.2)
        end)
    end
    radiusRing(d,s.ring,16,bang,bang+2.6)
    local under=d.parts.CapGlow
    if under then d.el(function(t)under.Color=s.fire:Lerp(s.halo,.5+.5*math.sin(t*2))end)end
    d.emit(bang,{Color=ColorSequence.new(s.pillar,s.halo),Size=ns(0,R*.03,.4,R*.04,1,0),Transparency=ns(0,0,1,.3),Lifetime=NumberRange.new(1.2,2),Speed=NumberRange.new(R*.6,R*1.5),
        SpreadAngle=Vector2.new(75,75),LightEmission=1,RotSpeed=NumberRange.new(-120,120)},140)
    d.emit(bang+.3,{Color=ColorSequence.new(s.feather),Size=ns(0,R*.04,1,R*.02),Transparency=ns(0,0,1,.4),Lifetime=NumberRange.new(1.8,2.6),Speed=NumberRange.new(R*.2,R*.6),
        SpreadAngle=Vector2.new(180,180),Acceleration=V(0,-R*.2,0),LightEmission=.4,RotSpeed=NumberRange.new(-90,90)},60)
end
I.delay.judgment=.5
I.delete=function(d)
    local R,s=d.R,d.skin;local bang=.4;local h=R*.85
    local marquee={};for i=1,16 do marquee[i]=d.add('Marquee','block',V(1,1,1),CFrame.new(d.ground),i%4==0 and s.pixel or s.ring,NEON,1)end
    d.el(function(t)
        local g=out4(k(t,0,.3));local hh=h*(.6+.4*g);local march=(t*1.2)%1;local on=t<3.6 and not (t>bang and t<bang+.12)
        for i,p in ipairs(marquee)do
            local side=math.floor((i-1)/4);local j=(i-1)%4;local u=(j+march)/4*2-1;local L=hh*2/4*.55
            local pos=side==0 and V(u*hh,0,-hh)or side==1 and V(hh,0,u*hh)or side==2 and V(-u*hh,0,hh)or V(-hh,0,-u*hh)
            p.Size=side%2==0 and V(L,R*.025,R*.03)or V(R*.03,R*.025,L);p.CFrame=CFrame.new(d.ground+UP*.3+pos);p.Transparency=on and .05+.95*k(t,3,3.6)or 1
        end
    end)
    local void=d.add('Deleted','block',V(1,1,1),CFrame.new(d.ground),s.void,SMOOTH,1)
    d.el(function(t)local tb=t-bang;void.Size=V(h*2,.05,h*2);void.CFrame=CFrame.new(d.ground+UP*.12);void.Transparency=tb<0 and 1 or .35+.65*k(tb,1.2,1.9)end)
    local n=7;local cell=h*2/n
    for x=1,n do for z=1,n do
        local i=(x-1)*n+z;local at=d.ground+V((x-.5)*cell-h,0,(z-.5)*cell-h);local out=.05+.8*hash(i,91);local back=1.3+.8*hash(i,92)
        local p=d.add('PixelTile','block',V(1,1,1),CFrame.new(at),(x+z)%3==0 and s.pixel or (x+z)%3==1 and s.ring or s.void,NEON,1)
        d.el(function(t)
            local tb=t-bang;if tb<0 then p.Transparency=1;return end
            local o=out2(k(tb,out,out+.35));local r=out2(k(tb,back,back+.3));local sz=cell*.92*math.max(1-o,r)
            p.Size=V(math.max(.05,sz),R*.03,math.max(.05,sz));p.CFrame=CFrame.new(at+UP*(.2+R*.5*o*(1-r)+R*.25*(1-r)*(tb>back and 1 or 0)))
            p.Transparency=(o>=1 and r<=0)and 1 or .1+.9*k(tb,back+.5,back+1.1)
        end)
    end end
    for i=1,8 do
        local cx,cy,cz=(i%2==0 and 1 or -1),(math.floor((i-1)/2)%2==0 and 1 or -1),(i>4 and 1 or -1)
        local p=d.add('SubCube','block',Vector3.one*R*.12,CFrame.new(d.ground),i%3==0 and s.pixel or s.void,i%3==0 and NEON or GLASS,1);p.Reflectance=.35
        d.el(function(t)
            local tb=t-bang;if tb<0 or tb>2.6 then p.Transparency=1;return end
            local o=out4(k(tb,0,.4))*(1-in2(k(tb,1.8,2.5)));local c=d.ground+UP*R*.45+V(cx*R*.06,cy*R*.06,cz*R*.06)+V(cx,cy*.4,cz)*R*.6*o
            local q=R*.05;p.CFrame=CFrame.new(snap(c.X,q),snap(c.Y,q),snap(c.Z,q))*CFrame.Angles(0,snap(tb*2,math.pi/4),0);p.Transparency=.05
        end)
    end
    for i=1,8 do
        local at=d.ground+V((hash(i,93)-.5)*h*1.6,0,(hash(i,94)-.5)*h*1.6)
        local p=d.add('CodeColumn','block',V(1,1,1),CFrame.new(at),i%3==0 and s.pixel or s.ring,NEON,1)
        d.el(function(t)
            local tb=t-bang;if tb<.15 or tb>2.6 then p.Transparency=1;return end
            local u=(tb*1.1+hash(i,95))%1;local L=R*(.2+.3*hash(i,96))
            p.Size=V(R*.03,L,R*.03);p.CFrame=CFrame.new(at+UP*(R*.1+u*R*1.1));p.Transparency=(u>.9)and 1 or .1+.9*k(tb,2,2.6)
        end)
    end
    for c=1,2 do
        local bars={};for j=1,4 do bars[j]=d.add('SquareWave','block',V(1,1,1),CFrame.new(d.ground),c==1 and s.ring or s.pixel,NEON,1)end
        d.el(function(t)
            local tb=t-bang;if tb<0 then hide(bars);return end
            local e=h*(.25+1.4*out4(k(tb,0,.9)))+(c==2 and R*.04 or 0);local th=math.max(.1,R*.03)
            for j,p in ipairs(bars)do
                p.Size=j%2==1 and V(e*2,th,th)or V(th,th,e*2);p.CFrame=CFrame.new(d.ground+UP*(.35+.03*c)+(j==1 and V(0,0,-e)or j==2 and V(e,0,0)or j==3 and V(0,0,e)or V(-e,0,0)))
                p.Transparency=.1+.9*k(tb,.5,1.1)
            end
        end)
    end
    radiusRing(d,s.ring,16,bang,bang+2.4)
    local under=d.parts.CapGlow
    if under then d.el(function(t)under.Color=math.floor(t/.15)%2==0 and s.ring or s.pixel end)end
    d.emit(bang,{Color=ColorSequence.new(s.ring,s.pixel),Size=ns(0,R*.045,.8,R*.03,1,0),Transparency=ns(0,0,1,.3),Lifetime=NumberRange.new(1,1.6),Speed=NumberRange.new(R*.6,R*1.4),
        SpreadAngle=Vector2.new(80,80),LightEmission=1},140)
end
I.delay.delete=.4
I.maw=function(d)
    local R,s=d.R,d.skin
    local abyss=d.add('Abyss','cyl',V(.05,1,1),CFrame.new(d.ground)*FLAT,s.abyss,SMOOTH,1)
    local function open(t)return out2(k(t,0,.7))*(1-in2(k(t,3.6,4.4)))end
    d.el(function(t)local r=math.max(.1,R*.8*open(t));abyss.Size=V(.05,r*2,r*2);abyss.CFrame=CFrame.new(d.ground+UP*.1)*FLAT;abyss.Transparency=t<.02 and 1 or .3+.7*k(t,3.9,4.6)end)
    for a=1,3 do
        local segs={};for j=1,8 do segs[j]=d.add('Whirlpool','block',V(.1,.1,.1),CFrame.new(d.ground),j%2==0 and s.foam or s.water,NEON,1)end
        d.el(function(t)
            local g=open(t);local prev
            for j=0,8 do
                local u=j/8;local ang=a/3*TAU+u*TAU*1.1+t*2.6;local r=R*(.82-.72*u)*g
                local at=d.ground+V(math.cos(ang)*r,.18+.06*(1-u),math.sin(ang)*r)
                if prev then local p=segs[j];if g<.03 then p.Transparency=1 else span(p,prev,at,math.max(.08,R*(.05-.03*u)));p.Transparency=.15+.85*k(t,3.8,4.5)end end
                prev=at
            end
        end)
    end
    local rim=d.ring('FoamRim',12,s.foam)
    d.el(function(t)local g=open(t);placeRing(rim,CFrame.new(d.ground+UP*.25),math.max(.1,R*.84*g),t*1.4,math.max(.08,R*.03),.6);for _,p in ipairs(rim)do p.Transparency=g<.03 and 1 or .2+.8*k(t,3.8,4.5)end end)
    local function headCF(t)
        local rise=out2(k(t,2,2.7))*(1-in2(k(t,3.4,4.1)));local c=d.ground+UP*R*(-.05+.8*rise)
        return CFrame.new(c)*CFrame.Angles(0,.4+t*.15,0)*CFrame.Angles(.9,0,0),rise
    end
    local head=d.add('LeviathanHead','ell',V(1,1,1),CFrame.new(d.ground),s.flesh,SMOOTH,1);head.Reflectance=.3
    local jaw=d.add('LeviathanJaw','ell',V(1,1,1),CFrame.new(d.ground),s.abyss,SMOOTH,1)
    local throat=d.add('Throat','ball',V(1,1,1),CFrame.new(d.ground),s.violet,NEON,1)
    local teeth={};for i=1,8 do teeth[i]=d.add('Fang','wedge',V(1,1,1),CFrame.new(d.ground),s.teeth,SMOOTH,1)end
    local eyes={d.add('AbyssEye','ball',V(1,1,1),CFrame.new(d.ground),s.eye,NEON,1),d.add('AbyssEye','ball',V(1,1,1),CFrame.new(d.ground),s.eye,NEON,1)}
    if not d.reduced then local l=light(throat,s.violet,0,math.min(60,R*2));d.el(function(t)l.Brightness=4*k(t,2.2,2.6)*(1-k(t,3.2,3.6))end)end
    d.el(function(t)
        local cf,rise=headCF(t);local gape=out2(k(t,2.3,2.9))*(1-out4(k(t,3.05,3.3)));local tr=rise<.03 and 1 or 0
        head.Size=V(R*.36,R*.26,R*.5);head.CFrame=cf;head.Transparency=tr
        local jcf=cf*CFrame.new(0,-R*.1,R*.12)*CFrame.Angles(gape*.9,0,0)*CFrame.new(0,0,-R*.22)
        jaw.Size=V(R*.3,R*.1,R*.44);jaw.CFrame=jcf;jaw.Transparency=tr
        throat.Size=Vector3.one*math.max(.1,R*.16*gape);throat.CFrame=cf*CFrame.new(0,-R*.08,-R*.1);throat.Transparency=(tr==1 or gape<.05)and 1 or .1
        for i,p in ipairs(teeth)do
            local upper=i<=4;local x=((i-1)%4-1.5)*R*.06;local hh=R*.07
            p.Size=V(R*.03,hh,R*.035);p.CFrame=(upper and cf*CFrame.new(x,-R*.1,-R*.2)*CFrame.Angles(0,0,math.pi) or jcf*CFrame.new(x,R*.07,-R*.16))*CFrame.new(0,hh/2,0)
            p.Transparency=tr==1 and 1 or (gape<.05 and .6 or 0)
        end
        for i,p in ipairs(eyes)do
            local sd=i==1 and -1 or 1;local glow=k(t,.2,.6)*(1-k(t,3.6,4.2))
            local under=d.ground+UP*.2+V(sd*R*.12,0,0)
            local at=rise>.03 and (cf*CFrame.new(sd*R*.15,R*.08,-R*.08)).Position or under
            p.Size=Vector3.one*math.max(.1,R*(.06+.02*math.sin(t*3))*(rise>.03 and 1 or 1.2));p.CFrame=CFrame.new(at)
            p.Color=s.eye:Lerp(s.violet,k(t,2,2.6));p.Transparency=glow<=0 and 1 or 1-.9*glow
        end
    end)
    for i=1,8 do
        local a=i/8*TAU+.2;local dir=V(math.cos(a),0,math.sin(a));local tan=V(-dir.Z,0,dir.X);local H=R*(.75+.35*hash(i,101))
        local segs={};for j=1,4 do segs[j]=d.add('Tentacle','block',V(.1,.1,.1),CFrame.new(d.ground),j==4 and s.fire or s.flesh,j==4 and NEON or SMOOTH,1)end
        d.el(function(t)
            local g=out2(k(t,.9+.08*i,1.7+.08*i))*(1-in2(k(t,3.5,4.2)));if g<.03 then hide(segs);return end
            local base=d.ground+dir*R*.62;local prev=base
            for j=1,4 do
                local u=j/4;local curl=u*u*(1.1+.3*math.sin(t*1.6+i))
                local at=base+UP*H*g*math.sin(u*1.4)/math.sin(1.4)-dir*R*.38*curl*g+tan*math.sin(t*2+u*3+i)*R*.1*u
                span(segs[j],prev,at,math.max(.08,R*(.075-.014*j)));segs[j].Transparency=0;prev=at
            end
        end)
    end
    radiusRing(d,s.ring,16,.2,3.2)
    local under=d.parts.CapGlow
    if under then d.el(function(t)under.Color=s.fire:Lerp(s.violet,k(t,2,3))end)end
    d.emit(.05,{Color=ColorSequence.new(s.foam,s.water),Size=ns(0,R*.03,1,0),Transparency=ns(0,0,1,.6),Lifetime=NumberRange.new(1,1.6),Speed=NumberRange.new(R*.6,R*1.2),
        SpreadAngle=Vector2.new(40,40),Acceleration=V(0,-R*1.2,0),LightEmission=.4},70)
    d.emit(3.1,{Color=ColorSequence.new(s.violet,s.fire),Size=ns(0,R*.03,.4,R*.04,1,0),Transparency=ns(0,0,1,.3),Lifetime=NumberRange.new(1.2,1.8),Speed=NumberRange.new(R*.5,R*1.2),
        SpreadAngle=Vector2.new(180,180),LightEmission=1,RotSpeed=NumberRange.new(-90,90)},140)
end
end
