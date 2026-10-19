local M={builders={},kinds={}}
local B,K=M.builders,M.kinds
local V3=Vector3.new
local UP=V3(0,1,0)
local Glass=Enum.Material.Glass
local Ball,Cyl=Enum.PartType.Ball,Enum.PartType.Cylinder
local function prism(h,sat)local f=h%1;return Color3.fromHSV(.45+.47*(1-math.abs(2*f-1)),sat,1)end
local function hash(a,b,c)local x=math.sin(a*12.9898+b*78.233+c*37.719)*43758.5453;return x-math.floor(x)end
local function edge(a,b,back)
    local x=(b-a).Unit;local z=(back-x*back:Dot(x)).Unit;local y=z:Cross(x)
    if y.Y<0 then x,y=-x,-y end
    return CFrame.fromMatrix((a+b)/2,x,y,x:Cross(y))
end
local function span(a,b,up)
    local d=b-a;up=up or UP
    if math.abs(d.Unit:Dot(up))>.97 then up=V3(0,0,1)end
    return CFrame.lookAt((a+b)/2,b,up),d.Magnitude
end
local function along(center,dir,up)if math.abs(dir.Unit:Dot(up))>.97 then up=V3(0,0,1)end;return CFrame.lookAt(center,center+dir,up)end
local function fan(S,A,Bv,f0,f1)
    local A0,B0,A1,B1=S:Lerp(A,f0),S:Lerp(Bv,f0),S:Lerp(A,f1),S:Lerp(Bv,f1)
    local L=(A1+B1)/2-(A0+B0)/2;local len=L.Magnitude;L=L.Unit
    local W=(B1-A1)+(B0-A0);W=(W-L*W:Dot(L)).Unit
    local N=L:Cross(W);if N.Y<0 then W=-W;N=-N end
    return CFrame.fromMatrix((A0+B0+A1+B1)/4,W,N,W:Cross(N)),((B0-A0).Magnitude+(B1-A1).Magnitude)/2,len
end
local function setSize(p,a,size,scale)p.Size=size*scale end

local function pumpXf(a,t,k)return a.base*CFrame.Angles(-.035*k*math.sin(t*2.2),.02*k*math.sin(t*1.3),0)*a.base:Inverse()end
function B.stinger(add,anim,dark,trim,accent)
    local deep=dark:Lerp(Color3.new(),.5);local membrane=trim:Lerp(accent,.3);local anchors={}
    add('Thorax',V3(1.3,.8,1.7),CFrame.new(0,.35,-.6),deep,{mesh='soft'})
    add('Spine',V3(.14,.06,1.4),CFrame.new(0,.77,-.6),nil,{tint='full',glow=true})
    add('Head',V3(1.0,.75,.85),CFrame.new(0,.4,-1.8),dark,{mesh='soft'})
    for _,s in ipairs({-1,1})do
        add('Eye',V3(.34,.46,.55),CFrame.new(s*.43,.5,-1.88),accent,{glow=true,mesh='soft'})
        local cf,len=span(V3(s*.2,.72,-2.05),V3(s*.75,1.35,-2.95));add('Antenna',V3(.07,.07,len),cf,trim,{glow=true})
    end
    local base=CFrame.new(0,.3,.2)
    local seg={{.75,.28,1.25},{1.45,.2,1.38},{2.1,.08,1.22},{2.7,-.07,.98},{3.2,-.22,.68}}
    for k,q in ipairs(seg)do
        anim(add('Abdomen',V3(q[3],q[3]*.78,.82),CFrame.new(0,q[2],q[1])*CFrame.Angles(-.12*k/5,0,0),k%2==1 and accent or deep,{mesh='soft',glow=k%2==1 and nil}),'sting',{k=k,base=base})
    end
    local s0,tip=V3(0,-.32,3.45),V3(0,-.72,4.45)
    anim(add('Stinger',V3(.13,.13,(tip-s0).Magnitude),span(s0,tip),trim,{glow=true}),'sting',{k=5,base=base})
    for i=0,2 do anim(add('VenomDrop',V3(.22,.22,.22),CFrame.new(tip),accent,{glow=true,shape=Ball}),'drip',{i=i,base=base,tip=tip})end
    local back=V3(0,0,1)
    for _,s in ipairs({-1,1})do
        for w,W in ipairs({{root=V3(s*.55,.62,-.8),dir=V3(s,.62,.26),L=5.6,c=1.9,c2=1.05},{root=V3(s*.5,.5,-.1),dir=V3(s,.36,.78),L=4.0,c=1.35,c2=.75}})do
            local R=W.root;local E=R+W.dir.Unit*W.L;local cf=edge(R,E,back);local hinge=CFrame.new(R)
            local L=W.L*((cf*V3(1,0,0)-cf.Position):Dot(W.dir)>0 and 1 or -1)
            local function buzz(p)return anim(p,'buzz',{hinge=hinge,side=s,w=w})end
            buzz(add('Wing',V3(W.L*.58,.06,W.c),cf*CFrame.new(-L*.21,0,W.c/2-.08),membrane,{material=Glass,alpha=.42}))
            buzz(add('WingTip',V3(W.L*.44,.06,W.c2),cf*CFrame.new(L*.27,0,W.c2/2-.05),membrane,{material=Glass,alpha=.42}))
            buzz(add('Vein',V3(W.L,.08,.1),cf*CFrame.new(0,.04,.02),accent,{glow=true}))
            buzz(add('Vein',V3(W.L*.7,.07,.08),cf*CFrame.new(-L*.12,.04,W.c*.62)*CFrame.Angles(0,-.12*math.sign(L),0),accent,{glow=true}))
            buzz(add('WingSpot',V3(.42,.08,.42),cf*CFrame.new(L*.36,.05,.32)*CFrame.Angles(0,math.pi/4,0),trim,{glow=true}))
            table.insert(anchors,(cf*CFrame.new(-L*.18,-.1,W.c*.4)).Position)
        end
        table.insert(anchors,V3(s*.6,-.05,-1.0));table.insert(anchors,V3(s*.6,-.05,.3))
    end
    return {anchors=anchors,crest=CFrame.new(0,.82,-.6)}
end
function K.sting(a,p,t)return pumpXf(a,t,a.k)*a.home end
function K.drip(a,p,t)
    local u=(t*.5+a.i/3)%1
    p.Transparency=.1+.85*u*u
    return CFrame.new(pumpXf(a,t,5)*a.tip+V3(0,-u*2.3,u*.25))
end
function K.buzz(a,p,t,reduced)
    local ang=reduced and 0 or (.16*math.sin(t*9+(a.w-1)*1.9)+.05)
    return a.hinge*CFrame.Angles(0,0,a.side*ang)*a.hinge:Inverse()*a.home
end

local JR,JH,JRIM=3.1,2.4,-.7
local function jpulse(t)return math.sin(t*2.2)end
function B.jellyfish(add,anim,dark,trim,accent)
    local N=8;local rings={0,.6,1.12}
    local function pt(phi,ang)local r=JR*math.cos(phi);return V3(math.sin(ang)*r,JRIM+JH*math.sin(phi),-math.cos(ang)*r)end
    for i=0,N-1 do
        local ang=(i+.5)/N*math.pi*2;local tangent=V3(math.cos(ang),0,math.sin(ang))
        for j=1,2 do
            local a,b=pt(rings[j],ang),pt(rings[j+1],ang);local up=(b-a).Unit
            local size=V3(2*math.pi*JR*math.cos(rings[j])/N*1.07,(b-a).Magnitude+.1,.12)
            anim(add('Bell',size,CFrame.fromMatrix((a+b)/2,tangent,up,tangent:Cross(up)),dark:Lerp(accent,j==1 and .4 or .56),{material=Glass,alpha=.36}),'bell',{amp=j==1 and .075 or .04,lift=j==1 and 0 or -.05,size=size})
        end
        local la=i/N*math.pi*2;local out=V3(math.sin(la),0,-math.cos(la));local lt=V3(math.cos(la),0,math.sin(la))
        local size=V3(1.15,.6,.1)
        anim(add('Frill',size,CFrame.fromMatrix(pt(0,la)+out*.12+V3(0,-.28,0),lt,(UP*.9+out*.3).Unit,lt:Cross((UP*.9+out*.3).Unit)),trim:Lerp(accent,.45),{glow=true,alpha=.35}),'bell',{amp=.09,lift=.03,size=size})
    end
    anim(add('BellCap',V3(.24,2.95,2.95),CFrame.new(0,JRIM+JH*math.sin(1.12)+.03,0)*CFrame.Angles(0,0,math.pi/2),dark:Lerp(accent,.58),{material=Glass,alpha=.3,shape=Cyl}),'bell',{amp=0,lift=-.1})
    anim(add('Ocellus',V3(.5,.5,.5),CFrame.new(0,JRIM+JH*math.sin(1.12)+.22,0),nil,{tint='full',glow=true,shape=Ball}),'bell',{amp=0,lift=-.1})
    anim(add('Core',V3(2.1,2.1,2.1),CFrame.new(0,.35,0),accent,{glow=true,alpha=.42,shape=Ball}),'bell',{amp=0,lift=-.06,glowCore=true})
    for k=0,5 do
        local ang=(k+.25)/6*math.pi*2;local out=V3(math.sin(ang),0,-math.cos(ang))
        local d={k=k,base=V3(out.X*JR*.96,JRIM-.12,out.Z*JR*.96),tau=V3(math.cos(ang),0,math.sin(ang)),out=out,L1=1.7,L2=1.6,lean=-.18}
        local s1=table.clone(d);s1.seg=1;local s2=table.clone(d);s2.seg=2
        anim(add('Tentacle',V3(.24,.24,1.75),CFrame.new(),trim:Lerp(accent,.3),{material=Glass,alpha=.18}),'tentacle',s1)
        anim(add('TentacleTip',V3(.12,.12,1.6),CFrame.new(),trim,{glow=true,alpha=.1}),'tentacle',s2)
    end
    for _,s in ipairs({-1,1})do
        anim(add('OralArm',V3(.55,.12,2.7),CFrame.new(),trim:Lerp(accent,.25),{glow=true,alpha=.3}),'tentacle',{k=s*2.5,seg=1,base=V3(s*.35,-.55,.1),tau=V3(0,0,1),out=V3(s,0,0),L1=2.6,L2=0,lean=s*.06,center=true})
    end
    for i=0,2 do anim(add('Bubble',V3(.32,.32,.32),CFrame.new(),trim,{material=Glass,alpha=.3,shape=Ball}),'bubble',{i=i})end
    local anchors={};for k=0,7 do local ang=(k+.5)/8*math.pi*2;table.insert(anchors,V3(math.sin(ang)*JR*.9,JRIM-.15,-math.cos(ang)*JR*.9))end
    return {anchors=anchors,crest=CFrame.new(0,JRIM+JH*math.sin(1.12)+.16,0)}
end
function K.bell(a,p,t,reduced,phase,scale)
    local w=jpulse(t);local s=1+a.amp*w;local h=a.home
    if a.size then setSize(p,a,V3(a.size.X*s,a.size.Y,a.size.Z),scale)end
    if a.glowCore and not reduced then p.Transparency=.38+.12*w end
    return CFrame.new(h.X*s,h.Y+a.lift*w,h.Z*s)*h.Rotation
end
function K.tentacle(a,p,t)
    local s=1+.075*jpulse(t);local base=a.center and a.base or V3(a.base.X*s,a.base.Y,a.base.Z*s)
    local w=t*2.2-a.k*.8
    local d1=CFrame.fromAxisAngle(a.tau,a.lean+.2*math.sin(w-.9))*V3(0,-1,0)
    if a.seg==1 then return along(base+d1*a.L1/2,d1,a.out)end
    local d2=CFrame.fromAxisAngle(a.tau,.32*math.sin(w-1.9))*d1
    return along(base+d1*(a.L1-.05)+d2*a.L2/2,d2,a.out)
end
function K.bubble(a,p,t)
    local u=(t*.32+a.i/3)%1;local ang=a.i*2.1+.6+u*.8
    p.Transparency=.25+.7*u^2
    return CFrame.new(math.sin(ang)*(JR+.35-u*.6),JRIM-.6+u*3.6,-math.cos(ang)*(JR+.35-u*.6))
end

local function breath(a,t)return a.hinge*CFrame.Angles(0,0,a.side*.07*math.sin(t*1.3))*a.hinge:Inverse()end
function B.magma(add,anim,dark,trim,accent)
    local rock=dark:Lerp(Color3.fromRGB(36,34,38),.45);local rock2=accent:Lerp(dark,.72);local basalt=Enum.Material.Basalt
    add('Keel',V3(1.4,.44,3.8),CFrame.new(0,.16,.25),rock,{mesh='soft',material=basalt})
    add('Spine',V3(.14,.06,3.3),CFrame.new(0,.4,.25),nil,{tint='full',glow=true})
    local anchors={}
    for _,s in ipairs({-1,1})do
        local S=V3(s*.55,.22,-.7);local hinge=CFrame.new(S)
        local R={V3(s*5.3,1.0,-1.6),V3(s*6.3,.35,.85),V3(s*4.7,-.25,2.75),V3(s*2.3,-.25,3.35)}
        local function wing(p,kind,d)d=d or {};d.hinge=hinge;d.side=s;return anim(p,kind or 'basalt',d)end
        for k=1,3 do
            local A,Bv=R[k],R[k+1]
            for half=0,1 do
                local cf,w,len=fan(S,A,Bv,half==0 and .1 or .5,half==0 and .56 or .88)
                wing(add('BasaltPlate',V3(w*(half==0 and 1.3 or 1.12),.22,len+.08),cf,half==0 and rock or rock2,{material=basalt}))
                if half==1 then table.insert(anchors,(cf*CFrame.new(0,-.15,-len*.4)).Position)end
            end
            local x0=S:Lerp(A,.64):Lerp(S:Lerp(Bv,.64),.22);local x1=S:Lerp(Bv,.8):Lerp(S:Lerp(A,.8),.3)
            local cf,len=span(x0,x1);wing(add('LavaCrack',V3(.09,.06,len),CFrame.new(0,.14,0)*cf,accent,{glow=true}),'basalt',{pulse=k+.5,color=accent})
        end
        for k=1,4 do
            local cf,len=span(S,R[k]);wing(add('LavaRib',V3(.24,.14,len),cf*CFrame.new(0,.14,0),accent,{glow=true}),'basalt',{pulse=k,color=accent})
            local dir=(R[k]-S).Unit;local cfc,lc=span(R[k]-dir*.1,R[k]+dir*.8+V3(0,-.12,0))
            wing(add('Claw',V3(.16,.16,lc),cfc,rock,{material=basalt}))
        end
        for k=2,3 do wing(add('LavaDrop',V3(.28,.28,.28),CFrame.new(R[k]),trim,{glow=true,shape=Ball}),'lavadrop',{i=k,tip=R[k]})end
    end
    return {anchors=anchors,crest=CFrame.new(0,.42,-.4)}
end
function K.basalt(a,p,t,reduced)
    if a.pulse and not reduced then local w=math.max(0,math.sin(t*2.4-a.pulse*.9))^3;p.Color=a.color:Lerp(Color3.fromRGB(255,226,150),w*.75)end
    return breath(a,t)*a.home
end
function K.lavadrop(a,p,t)
    local u=(t*.42+a.i*.37)%1
    p.Transparency=.05+.9*u^2;p.Color=Color3.fromRGB(255,214,140):Lerp(Color3.fromRGB(255,130,40),u)
    return CFrame.new(breath(a,t)*a.tip+V3(0,-.15-u*2.8,u*.5))
end

local BOLT_X={-2.5,.3,2.7};local BOLT_OFF={0,1.0,1.85};local BOLT_P=2.7
local function flash(j,t)
    local x=t+BOLT_OFF[j];local ph=x%BOLT_P
    return ph<.1 or (ph>.18 and ph<.42),math.floor(x/BOLT_P)
end
function B.thundercloud(add,anim,dark,trim,accent)
    local low=dark:Lerp(Color3.new(),.28)
    add('CloudBase',V3(7.2,.45,2.5),CFrame.new(0,-.5,.35),dark:Lerp(trim,.12),{mesh='soft'})
    add('Charge',V3(6.6,.07,.08),CFrame.new(0,-.66,-.92),nil,{tint='full',glow=true})
    local puffs={{-3.7,-.05,.35,2.3},{-1.9,.1,-.45,2.8},{0,.2,.3,3.1},{1.95,.1,-.4,2.8},{3.75,-.05,.35,2.3},{-2.6,0,1.25,2.2},{2.6,0,1.3,2.2},
        {-2.7,1.0,.05,2.2},{-.9,1.4,-.25,2.6},{1.0,1.35,.25,2.5},{2.8,.9,-.05,2.0},{.05,2.25,0,1.9},{-1.6,2.0,.4,1.4}}
    for i,q in ipairs(puffs)do
        local tone=q[2]>1.8 and dark:Lerp(trim,.56)or q[2]>.6 and dark:Lerp(trim,.38)or dark:Lerp(trim,.17)
        local near=1;for j=2,3 do if math.abs(BOLT_X[j]-q[1])<math.abs(BOLT_X[near]-q[1])then near=j end end
        anim(add('Puff',V3(q[4],q[4],q[4]),CFrame.new(q[1],q[2],q[3]),tone,{shape=Ball}),'puff',{i=i,j=near,color=tone,lit=math.clamp(1-math.abs(BOLT_X[near]-q[1])/2.6,.25,1)*(q[2]>1.8 and .6 or 1)})
    end
    for j=1,3 do for i=1,4 do
        anim(add('Lightning',V3(.2,.2,1),CFrame.new(),trim,{glow=true}),'bolt',{j=j,i=i})
    end end
    for i=0,5 do anim(add('Rain',V3(.05,.62,.05),CFrame.new(),accent:Lerp(trim,.4),{glow=true,alpha=.5}),'rain',{i=i,x=-3.4+i*1.36+(i%2)*.3,z=(i%3-1)*.9})end
    local anchors={};for _,s in ipairs({-1,1})do for _,p in ipairs({V3(s*1.4,-.8,-.9),V3(s*1.4,-.8,1.5),V3(s*3.4,-.8,-.7),V3(s*3.4,-.8,1.3)})do table.insert(anchors,p)end end
    return {anchors=anchors,crest=CFrame.new(0,3.05,0)}
end
function K.puff(a,p,t,reduced)
    if not reduced then local on=flash(a.j,t);p.Color=on and a.color:Lerp(Color3.fromRGB(205,220,255),.62*a.lit)or a.color end
    return a.home*CFrame.new(math.sin(t*.7+a.i*1.3)*.06,math.sin(t*.9+a.i)*.09,0)
end
function K.bolt(a,p,t,reduced,phase,scale)
    local on,n=flash(a.j,t)
    local pos=V3(BOLT_X[a.j],-.85,.25)
    local prev=pos
    for i=1,a.i do prev=pos;pos=pos+V3((hash(n,a.j,i)-.5)*1.1,-.78,(hash(n,a.j,i+9)-.5)*.6)end
    p.Transparency=on and 0 or 1
    local cf,len=span(prev,pos);setSize(p,a,V3(.22-a.i*.03,.22-a.i*.03,len+.12),scale)
    return cf
end
function K.rain(a,p,t)
    local u=(t*1.1+a.i/6)%1
    p.Transparency=.45+.5*u
    return CFrame.new(a.x+u*.25,-.95-u*3.0,a.z+u*.35)*CFrame.Angles(.12,0,-.08)
end

local function drapeXf(a,t)return a.hinge*CFrame.Angles(.16+.11*math.sin(t*2.1+a.i*.9),0,0)*a.hinge:Inverse()end
function B.royal(add,anim,dark,trim,accent)
    local navy2=dark:Lerp(Color3.fromRGB(78,98,200),.35);local gold=accent:Lerp(trim,.25);local Metal=Enum.Material.Metal
    local function cell(x)local u=x/3.5;return CFrame.new(x*1.45,-1.4*u*u,0)*CFrame.Angles(0,0,-u*.42),4.4-.9*u*u end
    for i=-3,3 do
        local cf,chord=cell(i)
        add('RoyalCell',V3(1.5,.6,chord),cf,i%2==0 and dark or navy2,{mesh='soft'})
        if math.abs(i)==2 then add('Heraldry',V3(.8,.06,.8),cf*CFrame.new(0,.32,-.2)*CFrame.Angles(0,math.pi/4,0),accent,{glow=true})end
        if i<3 then local rc,rch=cell(i+.5);add('GoldRib',V3(.13,.7,rch+.06),rc,gold,{material=Metal})end
        if math.abs(i)<=2 then
            local hinge=cf*CFrame.new(0,-.22,chord/2+.03)
            anim(add('Valance',V3(1.36,.9,.07),hinge*CFrame.new(0,-.45,0),i%2==0 and accent:Lerp(trim,.35) or accent:Lerp(dark,.25),{material=Metal}),'drape',{hinge=hinge,i=i})
            anim(add('Tassel',V3(.2,.62,.2),hinge*CFrame.new(0,-1.2,0),trim,{mesh='soft',glow=true}),'tassel',{hinge=hinge,i=i,top=(hinge*CFrame.new(0,-.88,0)).Position})
        end
    end
    add('Sash',V3(.32,.06,3.9),CFrame.new(0,.32,0),nil,{tint='full',glow=true})
    add('UnderGlow',V3(5.6,.05,2.8),CFrame.new(0,-.4,0),accent,{glow=true,alpha=.6})
    local c=CFrame.new(0,.55,.25)
    anim(add('CrownBand',V3(.42,1.5,1.5),c*CFrame.new(0,.2,0)*CFrame.Angles(0,0,math.pi/2),gold,{shape=Cyl,material=Metal}),'crown',{c=c})
    for k=0,4 do
        local ang=k/5*math.pi*2
        anim(add('CrownProng',V3(.22,.6,.22),c*CFrame.Angles(0,ang,0)*CFrame.new(0,.62,-.62)*CFrame.Angles(-.22,0,0)*CFrame.Angles(0,math.pi/4,0),gold,{material=Metal}),'crown',{c=c})
    end
    for k=0,2 do anim(add('CrownGem',V3(.22,.22,.22),c*CFrame.Angles(0,k/3*math.pi*2,0)*CFrame.new(0,.22,-.76),k==0 and trim or accent,{glow=true,shape=Ball}),'crown',{c=c,gem=k})end
    anim(add('CrownOrb',V3(.36,.36,.36),c*CFrame.new(0,.82,0),trim,{glow=true,shape=Ball}),'crown',{c=c,gem=3})
    for _,s in ipairs({-1,1})do
        local q=CFrame.new(s*4.95,-1.55,.35)
        add('BannerBar',V3(1.6,.14,.14),q,gold,{material=Metal})
        for j=1,3 do anim(add('Banner',V3(1.3,.8,.07),q,j==2 and navy2 or dark),'banner',{q=q,j=j,side=s})end
        anim(add('BannerCrest',V3(.5,.5,.09),q,accent,{glow=true}),'banner',{q=q,j=2,side=s,off=CFrame.Angles(0,0,math.pi/4)})
        for _,x in ipairs({-.38,.38})do anim(add('SwallowTail',V3(.6,.6,.07),q,dark),'banner',{q=q,j=3,side=s,off=CFrame.new(x,-.48,0)*CFrame.Angles(0,0,math.pi/4)})end
    end
    local anchors={};for _,s in ipairs({-1,1})do for _,p in ipairs({V3(s*1.3,-.3,-1.4),V3(s*1.3,-.3,1.4),V3(s*3.3,-.95,-1.2),V3(s*3.3,-.95,1.2)})do table.insert(anchors,p)end end
    return {anchors=anchors,crest=CFrame.new(0,.42,.25)}
end
function K.drape(a,p,t)return drapeXf(a,t)*a.home end
function K.tassel(a,p,t)
    local top=drapeXf(a,t)*a.top
    return CFrame.new(top)*CFrame.Angles(.25*math.sin(t*2.1+a.i*.9-.6),0,.14*math.sin(t*1.6+a.i))*CFrame.new(0,-.32,0)
end
function K.crown(a,p,t,reduced)
    if a.gem and not reduced then p.Color=Color3.fromRGB(255,214,110):Lerp(Color3.new(1,1,1),math.max(0,math.sin(t*3.1+a.gem*1.7))^8)end
    return a.c*CFrame.Angles(0,t*.45,0)*CFrame.new(0,math.sin(t*1.4)*.06,0)*a.c:Inverse()*a.home
end
function K.banner(a,p,t)
    local w=t*2.3+a.side;local th=.2+.1*math.sin(w);local top=a.q.Position+V3(0,-.08,0)
    local cf
    for j=1,a.j do
        if j>1 then th+=.12*math.sin(w-j*.9)end
        local d=V3(0,-math.cos(th),math.sin(th))
        cf=CFrame.fromMatrix(top+d*.4,V3(1,0,0),-d,V3(1,0,0):Cross(-d))
        top+=d*.78
    end
    return a.off and cf*a.off or cf
end

local function beatXf(a,t)return a.hinge*CFrame.Angles(0,0,a.side*.3*math.sin(t*1.9))*a.hinge:Inverse()end
function B.phoenix(add,anim,dark,trim,accent)
    local ember=accent:Lerp(dark,.3);local flameA,flameB=trim,Color3.fromRGB(255,196,70)
    add('Body',V3(1.1,.6,2.7),CFrame.new(0,.25,.1),dark:Lerp(accent,.4),{mesh='soft'})
    add('Spine',V3(.14,.06,2.3),CFrame.new(0,.57,.2),nil,{tint='full',glow=true})
    add('Head',V3(.75,.62,.9),CFrame.new(0,.62,-1.5),accent:Lerp(dark,.12),{mesh='soft'})
    add('Beak',V3(.26,.22,.55),CFrame.new(0,.52,-2.1),trim)
    for k=-1,1 do
        local cf,len=span(V3(k*.12,.85,-1.55),V3(k*.45,1.95-math.abs(k)*.35,-.75+math.abs(k)*.2))
        anim(add('FireCrest',V3(.16,.16,len),cf,k==0 and flameA or accent,{glow=true}),'flicker',{k=k+2})
    end
    local back=V3(0,0,1)
    for _,s in ipairs({-1,1})do
        local H=V3(s*.55,.35,-.3);local hinge=CFrame.new(H)
        local o=V3(s*math.cos(.5),math.sin(.5),0);local nrm=back:Cross(o)*s
        local W=H+o*3.4+V3(0,0,-.25);local Tp=W+o*3.3+V3(0,.35,.85)
        local function wing(p,kind,d)d=d or {};d.hinge=hinge;d.side=s;return anim(p,kind or 'beat',d)end
        local cf,len=span(H,W,nrm);wing(add('WingArm',V3(.18,.18,len+.1),cf,flameA,{glow=true}))
        cf,len=span(W,Tp,nrm);wing(add('WingArm',V3(.14,.14,len+.1),cf,flameA,{glow=true}))
        wing(add('Covert',V3((W-H).Magnitude,.18,1.6),edge(H,W,back)*CFrame.new(0,-.03,.75),ember,{mesh='soft'}))
        wing(add('Covert',V3((Tp-W).Magnitude,.14,1.0),edge(W,Tp,back)*CFrame.new(0,-.03,.45),accent,{mesh='soft'}))
        wing(add('FlameGlow',V3((Tp-H).Magnitude*.8,.05,1.6),edge(H,Tp,back)*CFrame.new(0,-.14,1.2),accent,{glow=true,alpha=.68}))
        for k=1,5 do
            local f=(k-1)/4;local root=H:Lerp(Tp,.14+.2*(k-1))
            local dir=(back*(1-f*.8)+o*f*1.15+UP*(.32+.28*f)).Unit;local L=2.6+.35*k
            local fl=CFrame.new(root)
            wing(add('FlameFeather',V3(.82,.13,L*.72),along(root+dir*L*.36,dir,nrm),k%2==0 and accent or accent:Lerp(dark,.35),{mesh='soft'}),'feather',{root=fl,k=k})
            wing(add('FlameTip',V3(.5,.1,L*.5),along(root+dir*L*.92,dir,nrm),k%2==0 and flameA or flameB,{glow=true}),'feather',{root=fl,k=k,flame=true})
        end
    end
    for k=-1,1 do
        local root=V3(k*.25,.15,1.35);local dir=V3(k*.32,-.18,1).Unit
        anim(add('TailPlume',V3(.42,.1,2.6),along(root+dir*1.3,dir,UP),k==0 and accent or ember,{mesh='soft'}),'plume',{root=CFrame.new(root),k=k})
        anim(add('TailFlame',V3(.3,.08,1.7),along(root+dir*3.3,dir,UP),k==0 and flameA or flameB,{glow=true}),'plume',{root=CFrame.new(root),k=k,flame=true,joint=CFrame.new(root+dir*2.55)})
    end
    local spawn={}
    for _,s in ipairs({-1,1})do
        local H=V3(s*.55,.35,-.3);local o=V3(s*math.cos(.5),math.sin(.5),0);local W=H+o*3.4+V3(0,0,-.25);local Tp=W+o*3.3+V3(0,.35,.85)
        for _,f in ipairs({.6,.95,.4})do table.insert(spawn,{H:Lerp(Tp,f)+V3(0,0,1.6),s})end
    end
    table.insert(spawn,{V3(-.6,.1,4.2),0});table.insert(spawn,{V3(.6,.1,4.2),0})
    for i,sp in ipairs(spawn)do anim(add('Ember',V3(.2,.2,.2),CFrame.new(sp[1]),flameA,{glow=true}),'ember',{i=i,at=sp[1],side=sp[2],hinge=CFrame.new(sp[2]*.55,.35,-.3)})end
    local anchors={};for _,s in ipairs({-1,1})do for _,p in ipairs({V3(s*.5,-.05,-.9),V3(s*.5,-.05,1.0),V3(s*1.8,1.1,-.5),V3(s*1.8,1.1,.9)})do table.insert(anchors,p)end end
    return {anchors=anchors,crest=CFrame.new(0,.62,.45)}
end
function K.beat(a,p,t)return beatXf(a,t)*a.home end
function K.feather(a,p,t,reduced)
    if a.flame and not reduced then p.Color=Color3.fromRGB(255,232,160):Lerp(Color3.fromRGB(255,170,40),.5+.5*math.sin(t*9+a.k*1.7))end
    return beatXf(a,t)*a.root*CFrame.Angles(0,0,a.side*.12*math.sin(t*1.9-.8-a.k*.18))*a.root:Inverse()*a.home
end
function K.flicker(a,p,t,reduced)
    if not reduced then p.Color=Color3.fromRGB(255,232,160):Lerp(Color3.fromRGB(255,170,40),.5+.5*math.sin(t*8+a.k*2.1))end
    return a.home*CFrame.new(0,0,math.sin(t*6+a.k)*.04)
end
function K.plume(a,p,t,reduced)
    local sway=a.root*CFrame.Angles(.1*math.sin(t*2.2-a.k),.12*math.sin(t*1.5+a.k),0)*a.root:Inverse()
    if a.flame then
        if not reduced then p.Color=Color3.fromRGB(255,232,160):Lerp(Color3.fromRGB(255,170,40),.5+.5*math.sin(t*9+a.k))end
        local j=sway*a.joint;return j*CFrame.Angles(.18*math.sin(t*2.2-a.k-1),0,0)*a.joint:Inverse()*sway*a.home
    end
    return sway*a.home
end
function K.ember(a,p,t)
    local u=(t*.55+a.i/8)%1
    local at=a.side~=0 and (beatXf(a,t)*a.at)or a.at
    p.Transparency=math.min(1,.05+.95*u^1.6)
    p.Color=Color3.fromRGB(255,236,170):Lerp(Color3.fromRGB(255,150,40),u)
    return CFrame.new(at+V3(math.sin(a.i*2.3+u*5)*.35,u*2.6,u*1.4))*CFrame.Angles(u*4+a.i,u*3,0)
end

local EC=V3(0,.7,0);local EN=V3(0,.8,.6);local EU=V3(1,0,0)
local EF=CFrame.fromMatrix(EC,EU,EN,EU:Cross(EN))
local RINGS={
    {a=5.5,b=1.55,frame=EF*CFrame.Angles(.42,0,0)*CFrame.Angles(0,.2,0),w=.32,hue=0,phase=1},
    {a=4.7,b=1.9,frame=EF*CFrame.Angles(-.36,0,0)*CFrame.Angles(0,-.24,0),w=-.26,hue=.5,phase=2},
}
local RAYS={1.6,2.5,1.3,2.9,1.8,2.3,1.4,2.7,1.7,2.1}
local function planeCF(frame,pos,dir)return frame*CFrame.fromMatrix(pos,dir,UP,dir:Cross(UP))end
local function ringCF(r,theta,open)
    local a=r.a*(.3+.7*open)
    local pos=V3(a*math.cos(theta),0,r.b*math.sin(theta));local tan=V3(-a*math.sin(theta),0,r.b*math.cos(theta))
    return planeCF(r.frame,pos,tan.Unit),tan.Magnitude
end
local function burst(t,phase)
    local base=phase>=3 and 1 or phase==2 and .72 or .42
    if phase<3 then return base end
    return base+.55*math.max(0,1-(t%5.5)/1.3)
end
function B.eclipse(add,anim,dark,trim,accent)
    local disc=add('BlackSun',V3(.24,4.3,4.3),CFrame.fromMatrix(EC,EN,EU,EN:Cross(EU)),dark,{shape=Cyl,material=Glass})
    disc.Reflectance=.3
    add('SunRim',V3(.1,4.62,4.62),CFrame.fromMatrix(EC-EN*.1,EN,EU,EN:Cross(EU)),nil,{shape=Cyl,tint='band',glow=true})
    anim(add('CoronaHaze',V3(.04,7.2,7.2),CFrame.fromMatrix(EC-EN*.22,EN,EU,EN:Cross(EU)),accent:Lerp(trim,.3),{shape=Cyl,glow=true,alpha=.9}),'haze',{phase=3})
    for k=0,11 do anim(add('Limb',V3(1,.1,.17),CFrame.new(),trim,{glow=true}),'limb',{k=k})end
    for k=1,#RAYS do anim(add('CoronaRay',V3(1,.06,.34),CFrame.new(),trim:Lerp(accent,k%2==0 and .65 or .2),{glow=true,alpha=.3}),'ray',{k=k,L=RAYS[k]})end
    anim(add('DiamondRing',V3(.6,.6,.6),CFrame.new(),Color3.new(1,1,1),{glow=true,shape=Ball}),'flare',{phase=2})
    for k=0,1 do anim(add('Flare',V3(2.6,.05,.07),CFrame.new(),trim,{glow=true}),'flare',{phase=2,cross=k})end
    for r,ring in ipairs(RINGS)do for k=0,13 do anim(add('RingWing',V3(1,.14,.26),CFrame.new(),accent,{glow=true}),'ring',{r=r,k=k,phase=ring.phase})end end
    for k=0,5 do anim(add('PrismGlint',V3(.36,.36,.36),CFrame.new(),trim,{glow=true}),'glint',{k=k,r=k%2+1,phase=3})end
    local anchors={};for _,s in ipairs({-1,1})do for _,p in ipairs({V3(s*.7,-.25,1.15),V3(s*.7,1.4,-.9),V3(s*1.7,.35,.45),V3(s*1.7,.95,-.35)})do table.insert(anchors,p)end end
    return {anchors=anchors,crest=CFrame.new(0,2.35,-1.55)}
end
local function gate(p,need,phase,alpha)p.Transparency=need>phase and 1 or alpha end
function K.haze(a,p,t,reduced,phase)
    gate(p,3,phase,reduced and .9 or .91-.08*math.max(0,1-(t%5.5)/1.3))
    return a.home
end
function K.limb(a,p,t,reduced,phase,scale)
    local th=a.k/12*math.pi*2+t*.22;local r=2.3
    setSize(p,a,V3(2*math.pi*r/12*.82,.1,.17),scale)
    if not reduced then p.Color=Color3.fromRGB(235,230,255):Lerp(Color3.fromRGB(200,150,255),.5+.5*math.sin(t*1.6+a.k))end
    return planeCF(EF,V3(r*math.cos(th),.05,r*math.sin(th)),V3(-math.sin(th),0,math.cos(th)))
end
function K.ray(a,p,t,reduced,phase,scale,open)
    local th=(a.k-.5)/#RAYS*math.pi*2+t*.05;local L=a.L*burst(t,phase)*(1+(phase>=3 and .12*math.sin(t*1.3+a.k*1.7)or 0))*(.4+.6*open)
    setSize(p,a,V3(L,.06,.34-L*.04),scale)
    p.Transparency=reduced and .3 or .22+.16*(.5+.5*math.sin(t*2+a.k))
    local dir=V3(math.cos(th),0,math.sin(th))
    return planeCF(EF,dir*(2.35+L/2),dir)
end
function K.flare(a,p,t,reduced,phase,scale)
    gate(p,2,phase,0)
    local th=-2.25+t*.22;local pos=V3(2.3*math.cos(th),.14,2.3*math.sin(th))
    if a.cross==nil then return planeCF(EF,pos,V3(1,0,0))end
    local tw=reduced and 1 or .7+.5*math.max(0,math.sin(t*2.6))
    setSize(p,a,V3(2.6*tw*(a.cross==0 and 1 or .7),.05,.07),scale)
    return planeCF(EF,pos,a.cross==0 and V3(1,0,0) or V3(0,0,1))
end
function K.ring(a,p,t,reduced,phase,scale,open)
    local r=RINGS[a.r];gate(p,a.phase,phase,0)
    local th=a.k/14*math.pi*2+t*r.w;local cf,rate=ringCF(r,th,open)
    setSize(p,a,V3(rate*math.pi*2/14*.8,.14,.26),scale)
    p.Color=reduced and prism(a.k/14+r.hue,.5)or prism(a.k/14+r.hue+t*.05,.55)
    return cf
end
function K.glint(a,p,t,reduced,phase,scale,open)
    gate(p,3,phase,0)
    local r=RINGS[a.r];local th=a.k/6*math.pi*2+t*r.w*2.6
    local cf=ringCF(r,th,open)
    if not reduced then p.Color=prism(a.k/6+t*.08,.25)end
    return cf*CFrame.new(0,.12,0)*CFrame.Angles(t*2+a.k,t*1.4,math.pi/4)
end
return M
