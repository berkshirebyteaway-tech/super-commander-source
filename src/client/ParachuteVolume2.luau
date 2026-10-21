local M={builders={},kinds={}}
local B,K=M.builders,M.kinds
local V3=Vector3.new
local UP=V3(0,1,0)
local Glass,Metal=Enum.Material.Glass,Enum.Material.Metal
local Ball,Cyl=Enum.PartType.Ball,Enum.PartType.Cylinder
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
local function along(center,dir,up)up=up or UP;if math.abs(dir.Unit:Dot(up))>.97 then up=V3(0,0,1)end;return CFrame.lookAt(center,center+dir,up)end
local function fan(S,A,Bv,f0,f1)
    local A0,B0,A1,B1=S:Lerp(A,f0),S:Lerp(Bv,f0),S:Lerp(A,f1),S:Lerp(Bv,f1)
    local L=(A1+B1)/2-(A0+B0)/2;local len=L.Magnitude;L=L.Unit
    local W=(B1-A1)+(B0-A0);W=(W-L*W:Dot(L)).Unit
    local N=L:Cross(W);if N.Y<0 then W=-W;N=-N end
    return CFrame.fromMatrix((A0+B0+A1+B1)/4,W,N,W:Cross(N)),((B0-A0).Magnitude+(B1-A1).Magnitude)/2,len
end
local function plate(a,b,tan)
    local d=(b-a).Unit;local n=d:Cross(tan).Unit;if n.Y<0 then n=-n end
    return CFrame.fromMatrix((a+b)/2,tan,n,tan:Cross(n)),(b-a).Magnitude
end
local function setSize(p,size,scale)p.Size=size*scale end
local function gate(p,need,phase,alpha)p.Transparency=need>phase and 1 or alpha end
local function sheen(u,sat)return Color3.fromHSV(.76+.14*(.5+.5*math.sin(u)),sat,1)end

local KN=7
local function kb(k,t)local u=k/KN;return V3(math.sin(t*2.1-k*.8)*(.12+1.05*u),-.05-.3*u+.1*math.sin(t*1.4-k*.6),2.3+k*.6)end
local function sailXf(a,t)return a.hinge*CFrame.Angles(0,0,a.side*.05*math.sin(t*2.6+a.side*.8))*CFrame.new(0,.05*math.sin(t*2.6+a.f*2),0)*a.hinge:Inverse()end
function B.kite(add,anim,dark,trim,accent)
    local jade,jade2=dark:Lerp(trim,.3),dark:Lerp(trim,.5);local gold=accent;local anchors={}
    local C=V3(0,.3,-.2);local Nz,T=V3(0,.12,-2.6),V3(0,-.05,2.3);local hinge=CFrame.new(C)
    for _,s in ipairs({-1,1})do
        local W=V3(s*4.2,.5,-.4)
        for q,pair in ipairs({{Nz,W},{W,T}})do for half=0,1 do
            local cf,w,len=fan(C,pair[1],pair[2],half==0 and .06 or .5,half==0 and .56 or .97)
            anim(add('DragonSail',V3(w*(half==0 and 1.25 or 1.08),.14,len+.1),cf,(q+half)%2==0 and jade or jade2,{mesh='soft'}),'kiteSail',{hinge=hinge,side=s,f=q+half})
            anim(add('DragonScale',V3(.6,.06,.6),cf*CFrame.new(0,.1,0)*CFrame.Angles(0,math.pi/4,0),gold,{material=Metal}),'kiteSail',{hinge=hinge,side=s,f=q+half})
        end end
        local cf,len=span(V3(0,.02,-.4),W+V3(-s*.1,.05,0));add('CrossSpar',V3(.12,.12,len),cf,gold,{material=Metal})
        for _,p in ipairs({V3(s*1.3,-.05,-1.3),V3(s*1.3,-.05,1.0),V3(s*3.0,.15,-.9),V3(s*3.0,.15,.15)})do table.insert(anchors,p)end
    end
    add('Spine',V3(.14,.06,4.4),CFrame.new(0,.46,-.15),nil,{tint='full',glow=true})
    add('DragonHead',V3(1.3,.8,1.5),CFrame.new(0,.45,-3.25),dark:Lerp(trim,.2),{mesh='soft'})
    add('Snout',V3(.9,.5,.95),CFrame.new(0,.36,-4.1),jade2,{mesh='soft'})
    for _,s in ipairs({-1,1})do
        local hc,hl=span(V3(s*.35,.8,-3.45),V3(s*.8,1.3,-2.3));add('Horn',V3(.18,.18,hl),hc,gold,{material=Metal})
        add('Eye',V3(.3,.3,.3),CFrame.new(s*.5,.66,-3.65),gold,{glow=true,shape=Ball})
        for seg=1,2 do anim(add('Whisker',V3(.1,.1,1.25),CFrame.new(s*.4,.32,-4.45),gold,{glow=true}),'kiteWhisker',{side=s,seg=seg,root=V3(s*.4,.32,-4.45)})end
    end
    anim(add('DragonPearl',V3(.6,.6,.6),CFrame.new(0,.7,-5.2),trim:Lerp(Color3.new(1,1,1),.5),{glow=true,shape=Ball}),'kitePearl',{})
    for k=1,KN do
        local th=.85-.45*k/KN
        anim(add('SerpentBody',V3(th,th*.8,1),CFrame.new(kb(k,0)),k%2==0 and jade2 or jade,{mesh='soft'}),'kiteBody',{k=k,th=th})
        anim(add('DorsalSpike',V3(.12,.36,.4),CFrame.new(kb(k,0)),gold,{material=Metal}),'kiteBody',{k=k,th=th,spike=true})
    end
    for r=-1,1 do for seg=1,2 do
        anim(add('TailRibbon',V3(.38,.05,.95),CFrame.new(kb(KN,0)),r==0 and trim or gold,{glow=true,alpha=seg==2 and .3 or .1}),'kiteRibbon',{r=r,seg=seg})
    end end
    for i=0,1 do anim(add('JadeMist',V3(.26,.26,.26),CFrame.new(kb(3+i*3,0)),trim,{glow=true,shape=Ball}),'kiteMote',{i=i})end
    return {anchors=anchors,crest=CFrame.new(0,.5,.6)}
end
function K.kiteSail(a,p,t)return sailXf(a,t)*a.home end
function K.kiteWhisker(a,p,t,reduced)
    local w=reduced and 0 or t*3.1+a.side
    local d1=CFrame.fromAxisAngle(UP,-a.side*(.25+.25*math.sin(w)))*V3(a.side,-.12,.55).Unit
    if a.seg==1 then return along(a.root+d1*.6,d1)end
    local d2=CFrame.fromAxisAngle(UP,-a.side*.45*math.sin(w-1.2))*d1
    return along(a.root+d1*1.2+d2*.6,d2)
end
function K.kitePearl(a,p,t,reduced)
    local c=V3(.45*math.sin(t*1.3),.7+.15*math.sin(t*2.2),-5.2+.25*math.cos(t*1.3))
    if not reduced then p.Color=Color3.fromRGB(200,255,235):Lerp(Color3.new(1,1,1),.5+.5*math.sin(t*3))end
    return CFrame.new(c)
end
function K.kiteBody(a,p,t,reduced,phase,scale)
    local A,Bv=kb(a.k-1,t),kb(a.k,t);local cf,len=span(A,Bv)
    if a.spike then return cf*CFrame.new(0,a.th*.4+.14,0)*CFrame.Angles(-.35,0,0)end
    setSize(p,V3(a.th,a.th*.8,len+.22),scale);return cf
end
function K.kiteRibbon(a,p,t)
    local tip=kb(KN,t);local back=(tip-kb(KN-1,t)).Unit
    local d1=CFrame.fromAxisAngle(UP,a.r*.45+.3*math.sin(t*3.4+a.r))*back
    if a.seg==1 then return along(tip+d1*.47,d1)end
    local d2=CFrame.fromAxisAngle(UP,.45*math.sin(t*3.4+a.r-1.1))*d1
    return along(tip+d1*.92+d2*.47,d2)
end
function K.kiteMote(a,p,t)
    local u=(t*.45+a.i/2)%1;local at=kb(3+a.i*3,t)
    p.Transparency=.15+.85*u*u
    return CFrame.new(at+V3(math.sin(a.i*2+u*4)*.4,.3+u*1.8,u*1.2))
end

local GR,GT,GH,GC=3.5,1.65,1.15,-2.1
local function gpt(r,ang,y)return V3(math.sin(ang)*r,y,-math.cos(ang)*r)end
local function tanAt(ang)return V3(math.cos(ang),0,math.sin(ang))end
local function spinXf(t)return CFrame.Angles(0,t*.2,0)end
function B.gemcanopy(add,anim,dark,trim,accent)
    local ice,ice2=dark:Lerp(trim,.35),dark:Lerp(trim,.7);local gold=accent;local white=Color3.fromRGB(245,250,255)
    local function spin(p)return anim(p,'gemSpin',{})end
    local function glass(p)p.Reflectance=.25;return spin(p)end
    glass(add('GemTable',V3(.1,GT*2,GT*2),CFrame.new(0,GH+.02,0)*CFrame.Angles(0,0,math.pi/2),white,{material=Glass,alpha=.15,shape=Cyl}))
    add('Spine',V3(.12,.05,2.4),CFrame.new(0,GH+.1,0),nil,{tint='full',glow=true})
    anim(add('GemCore',V3(2.3,2.3,2.3),CFrame.new(0,.15,0),trim,{glow=true,alpha=.5,shape=Ball}),'gemSweep',{core=true})
    for k=0,7 do
        local ang=k/8*math.pi*2;local tan=tanAt(ang)
        local cf,len=plate(gpt(GT,ang,GH),gpt(GR,ang,0),tan)
        glass(add('BezelFacet',V3(2*math.pi*(GR+GT)/2/8*1.02,.12,len+.06),cf,k%2==0 and ice2 or ice,{material=Glass,alpha=.12}))
        local a2=ang+math.pi/8;local t2=tanAt(a2)
        cf,len=plate(gpt(GT*1.08,a2,GH-.08),gpt(GR*.82,a2,.32),t2)
        glass(add('StarFacet',V3(1.15,.1,len),cf*CFrame.new(0,.07,0),white:Lerp(trim,.25),{material=Glass,alpha=.18}))
        cf,len=span(gpt(GT,a2,GH+.05),gpt(GR,a2,.04));spin(add('GoldSeam',V3(.09,.09,len),cf,gold,{material=Metal}))
        cf,len=span(gpt(GR,ang-.02,0),gpt(GR,ang+math.pi/4+.02,0));spin(add('Girdle',V3(.18,.2,len),cf,gold,{material=Metal}))
        cf,len=plate(gpt(GR,ang,-.05),V3(0,GC,0),tan)
        glass(add('PavilionFacet',V3(2*math.pi*GR/2/8*1.1,.1,len),cf,k%2==0 and ice or dark:Lerp(trim,.5),{material=Glass,alpha=.22}))
    end
    for k=0,3 do
        local ang=k/4*math.pi*2+math.pi/8;local cf,len=span(gpt(GR+.1,ang,-.12),gpt(GR*.86,ang,.55))
        spin(add('Prong',V3(.22,.22,len),cf,gold,{material=Metal}))
    end
    anim(add('Culet',V3(.4,.4,.4),CFrame.new(0,GC,0),trim,{glow=true,shape=Ball}),'gemSweep',{core=true})
    anim(add('LightSweep',V3(.16,.06,GT*1.7),CFrame.new(0,GH+.1,0),white,{glow=true,alpha=.3}),'gemSweep',{})
    for k=0,2 do anim(add('StarGlint',V3(1,.05,.08),CFrame.new(),white,{glow=true}),'gemGlint',{k=k})end
    local anchors={};for _,s in ipairs({-1,1})do for _,p in ipairs({V3(s*1.4,-.3,-2.4),V3(s*1.4,-.3,2.4),V3(s*2.9,-.2,-1.3),V3(s*2.9,-.2,1.3)})do table.insert(anchors,p)end end
    return {anchors=anchors,crest=CFrame.new(0,GH+.12,0)}
end
function K.gemSpin(a,p,t)return spinXf(t)*a.home end
function K.gemSweep(a,p,t,reduced)
    if a.core then if not reduced then p.Color=Color3.fromRGB(170,215,255):Lerp(Color3.new(1,1,1),.35+.35*math.sin(t*1.8))end;return a.home end
    local u=(t*.4)%1.6;local on=u<1
    p.Transparency=(reduced or not on)and 1 or .15+.6*math.abs(u*2-1)
    return CFrame.new(-GT*.9+(on and u or 0)*GT*1.8,GH+.12,0)*CFrame.Angles(0,.5,0)
end
function K.gemGlint(a,p,t,reduced,phase,scale)
    local ang=a.k/3*math.pi*2+.4;local r=(GT+GR)/2;local u=(t*.7+a.k*.37)%1
    local w=reduced and .6 or math.max(0,1-math.abs(u-.15)/.15)
    setSize(p,V3(.15+1.5*w,.05,.08),scale);p.Transparency=w<.05 and 1 or .05
    if not reduced then p.Color=Color3.new(1,1,1):Lerp(Color3.fromRGB(170,215,255),1-w)end
    local pos=spinXf(t)*gpt(r,ang,GH*.55+.15)
    return CFrame.new(pos)*CFrame.Angles(0,math.pi/4+w*1.6,0)*CFrame.Angles(.3,0,0)
end

local SW={
    {x=.7,y=.4,z=-.15,dir=V3(1,.5,-.08),L=4.0,n=4,chord=1.7,back=V3(0,-.05,1),phase=1},
    {x=.55,y=.32,z=-.75,dir=V3(.78,.55,-.75),L=3.1,n=3,chord=1.25,back=V3(.25,-.05,-1),phase=2},
    {x=.55,y=.28,z=.65,dir=V3(.78,.45,.8),L=3.3,n=3,chord=1.25,back=V3(-.2,-.05,1),phase=3},
}
local function swingXf(a,t)
    local ang=.2*math.sin(t*1.6+a.w*.9)+.04
    return CFrame.new(a.root)*CFrame.fromAxisAngle(a.axis,ang)*CFrame.new(-a.root)
end
function B.seraphwings(add,anim,dark,trim,accent)
    local ivory,gold,pink=dark,trim,accent
    add('SeraphCore',V3(1.0,.7,2.0),CFrame.new(0,.3,0),ivory:Lerp(gold,.15),{mesh='soft'})
    add('Spine',V3(.12,.06,1.6),CFrame.new(0,.67,.05),nil,{tint='full',glow=true})
    anim(add('HeartGem',V3(.45,.45,.45),CFrame.new(0,.7,-.6),pink,{glow=true,shape=Ball}),'seraphCore',{})
    for w,W in ipairs(SW)do for _,s in ipairs({-1,1})do
        local root=V3(s*W.x,W.y,W.z);local dir=V3(W.dir.X*s,W.dir.Y,W.dir.Z).Unit;local back=V3(W.back.X*s,W.back.Y,W.back.Z).Unit
        local flat=V3(dir.X,0,dir.Z).Unit;local axis=flat:Cross(UP)
        local d={root=root,axis=axis,w=w,phase=W.phase}
        local function wing(p,extra)local e=table.clone(d);if extra then for k,v in pairs(extra)do e[k]=v end end;return anim(p,'seraphWing',e)end
        local tip=root+dir*W.L
        local cf,len=span(root,tip);wing(add('WingArm',V3(.17,.17,len),cf,gold,{material=Metal}))
        wing(add('Covert',V3(W.L*.95,.14,W.chord),edge(root,tip,back)*CFrame.new(0,.05,W.chord*.42),ivory,{mesh='soft'}))
        if w==1 then wing(add('WingSheen',V3(W.L*1.05,.05,W.chord*1.9),edge(root,tip,back)*CFrame.new(0,-.1,W.chord*.95),pink,{material=Glass,alpha=.55}),{sheen=true})end
        for j=1,W.n do
            local f=j/(W.n+.2);local r0=root:Lerp(tip,.25+.75*f)
            local fd=(back*(1-f*.55)+dir*f*1.0+UP*.06).Unit;local fl=W.chord*(1.15+f*.8)
            wing(add('Feather',V3(.62,.08,fl),along(r0+fd*fl/2,fd),ivory:Lerp(gold,j%2==0 and .12 or 0)))
            wing(add('FeatherTip',V3(.44,.06,fl*.36),along(r0+fd*(fl+fl*.12),fd),gold,{glow=true,alpha=.22}),{tip=j})
        end
    end end
    for k=0,7 do anim(add('Halo',V3(1,.1,.17),CFrame.new(),pink,{glow=true}),'seraphHalo',{k=k})end
    for i=0,2 do anim(add('DriftFeather',V3(.24,.03,.5),CFrame.new(),ivory,{glow=true}),'seraphFeather',{i=i,side=i%2==0 and 1 or -1})end
    local anchors={};for _,s in ipairs({-1,1})do for _,p in ipairs({V3(s*.6,-.05,-.8),V3(s*.6,-.05,.8),V3(s*1.9,.55,-.55),V3(s*1.9,.55,.75)})do table.insert(anchors,p)end end
    return {anchors=anchors,crest=CFrame.new(0,.7,.55)}
end
function K.seraphCore(a,p,t,reduced)
    if not reduced then p.Color=Color3.fromRGB(255,143,216):Lerp(Color3.new(1,1,1),.25+.25*math.sin(t*2.2))end
    return a.home
end
function K.seraphWing(a,p,t,reduced,phase)
    if a.sheen then gate(p,a.phase,phase,reduced and .55 or .5+.12*math.sin(t*1.3));if not reduced then p.Color=sheen(t*.9,.45)end
    elseif a.tip then gate(p,a.phase,phase,.22);if not reduced then p.Color=Color3.fromRGB(255,232,170):Lerp(Color3.fromRGB(255,143,216),.5+.5*math.sin(t*1.7+a.tip*.9+a.w))end
    else gate(p,a.phase,phase,0)end
    return swingXf(a,reduced and 0 or t)*a.home
end
function K.seraphHalo(a,p,t,reduced,phase,scale)
    gate(p,3,phase,0);local th=a.k/8*math.pi*2+t*.3;local r=1.35+(reduced and 0 or .05*math.sin(t*2))
    setSize(p,V3(2*math.pi*r/8*.84,.1,.17),scale)
    if not reduced then p.Color=sheen(t*1.2+a.k*.8,.5)end
    return CFrame.fromMatrix(V3(r*math.cos(th),1.6+.06*math.sin(t*1.5),r*math.sin(th)),V3(-math.sin(th),0,math.cos(th)),UP)
end
function K.seraphFeather(a,p,t)
    local u=(t*.3+a.i/3)%1
    p.Transparency=.2+.8*u*u
    return CFrame.new(a.side*(2.6+a.i*.6)+math.sin(u*6+a.i)*.4,.4-u*3.4,.6+u*1.2)*CFrame.Angles(math.sin(u*5)*.6,u*3+a.i,math.cos(u*4)*.5)
end

local BX,BZ=1.1,1.1
local function bugHome(i,j)return V3(i*BX,.35-.14*i*i,-1.65+j*BZ)end
local function bugRot(i)return CFrame.Angles(0,0,math.atan(-.28*i/BX))end
local function torn(id,t,phase)
    local slot=math.floor(t*2.5);local rate=phase>=3 and .24 or phase==2 and .17 or .06
    if hash(slot,id,1)>rate then return nil end
    local m=phase>=2 and 1 or .5
    return V3((hash(slot,id,2)-.5)*.8*m,.25+hash(slot,id,3)*.7*m,(hash(slot,id,4)-.5)*.8*m),hash(slot,id,5)<.5
end
function B.bugcanopy(add,anim,dark,trim,accent)
    local cyan,mag=trim,accent;local id=0
    for i=-3,3 do for j=0,3 do
        id+=1;local col=(i+j)%2==0 and dark:Lerp(cyan,.16)or dark:Lerp(mag,.13)
        local p=add('PixelTile',V3(1.0,.32,1.0),CFrame.new(bugHome(i,j))*bugRot(i),col,{material=Glass,alpha=.08});p.Reflectance=.2
        anim(p,'bugTile',{i=i,j=j,id=id,color=col})
    end end
    add('Spine',V3(.12,.05,4.3),CFrame.new(0,.54,0),nil,{tint='full',glow=true})
    add('DataGlow',V3(6.2,.05,4.0),CFrame.new(0,-.2,0),cyan,{glow=true,alpha=.78})
    for g=0,3 do anim(add('ChromaGhost',V3(1.0,.3,1.0),CFrame.new(),g%2==0 and cyan or mag,{glow=true,alpha=.5}),'bugGhost',{g=g})end
    for k=0,11 do anim(add('PixelChunk',V3(.42,.42,.42),CFrame.new(),k%2==0 and cyan or mag,{glow=true}),'bugShard',{k=k,phase=2})end
    for k=0,1 do anim(add('Scanline',V3(7.4,.06,.1),CFrame.new(),k==0 and cyan or mag,{glow=true,alpha=.3}),'bugScan',{k=k,phase=2})end
    for l=0,7 do
        local x=(l-3.5)*BX
        anim(add('Wireframe',V3(.05,.05,4.5),CFrame.new(x,.55-.14*(x/BX)^2,0),cyan,{glow=true}),'bugWire',{l=l,phase=3})
    end
    for k=0,9 do anim(add('CodeBlock',V3(.14,.07,.42),CFrame.new(),k%3==0 and mag or cyan,{glow=true}),'bugCode',{k=k,l=k%8,phase=3})end
    anim(add('Cursor',V3(.5,.07,.75),CFrame.new(),Color3.new(1,1,1),{glow=true}),'bugCursor',{phase=3})
    anim(add('CursorTail',V3(.15,.07,.5),CFrame.new(),cyan,{glow=true}),'bugCursor',{phase=3,tail=true})
    local anchors={};for _,s in ipairs({-1,1})do for _,p in ipairs({V3(s*1.1,-.05,-1.1),V3(s*1.1,-.05,1.1),V3(s*2.75,-.8,-1.1),V3(s*2.75,-.8,1.1)})do table.insert(anchors,p)end end
    return {anchors=anchors,crest=CFrame.new(0,.58,.55)}
end
function K.bugTile(a,p,t,reduced,phase)
    local off,cy;if not reduced then off,cy=torn(a.id,t,phase)end
    local wave=reduced and 0 or .05*math.sin(t*2+a.i*.6+a.j*.4)
    if off then p.Color=a.color:Lerp(cy and Color3.fromRGB(80,240,255)or Color3.fromRGB(255,90,220),.6);return CFrame.new(bugHome(a.i,a.j)+off)*bugRot(a.i)*CFrame.Angles(off.Z*.4,0,off.X*.4)end
    p.Color=a.color;return CFrame.new(bugHome(a.i,a.j)+V3(0,wave,0))*bugRot(a.i)
end
function K.bugGhost(a,p,t,reduced,phase)
    local period=phase>=3 and 1.2 or phase==2 and 1.8 or 3.6;local slot=math.floor(t/period);local u=t%period
    local on=not reduced and u<.35;p.Transparency=on and .45 or 1
    local id=1+math.floor(hash(slot,math.floor(a.g/2),7)*28);local i,j=math.floor((id-1)/4)-3,(id-1)%4
    local side=a.g%2==0 and -1 or 1
    return CFrame.new(bugHome(i,j)+V3(side*.2,.12,side*-.08))*bugRot(i)
end
function K.bugShard(a,p,t,reduced,phase)
    local id=1+(a.k*5)%28;local i,j=math.floor((id-1)/4)-3,(id-1)%4;local base=bugHome(i,j)+V3(((a.k%4)-1.5)*.24,.05,(math.floor(a.k/4)%3-1)*.24)
    local u=(t*.55+a.k/12)%1;local out=u<.7 and math.sin(u/.7*math.pi/2) or 1-(u-.7)/.3
    if reduced then out=0 end
    p.Transparency=(a.phase>phase or out<.05)and 1 or 0
    local dir=V3(i*.35+(hash(a.k,1,1)-.5),1.2,(j-1.5)*.4).Unit
    return CFrame.new(base+dir*out*1.7)*CFrame.Angles(out*1.2,out*.8,0)
end
function K.bugScan(a,p,t,reduced,phase)
    gate(p,a.phase,phase,reduced and 1 or .3)
    local u=(t*.5+a.k*.5)%1
    return CFrame.new(0,.7,-2.2+u*4.4)
end
function K.bugWire(a,p,t,reduced,phase)
    gate(p,a.phase,phase,(reduced or hash(math.floor(t*6),a.l,3)>.15)and .1 or .7)
    return a.home
end
function K.bugCode(a,p,t,reduced,phase)
    gate(p,a.phase,phase,0)
    local x=(a.l-3.5)*BX;local u=((reduced and 0 or t)*(.45+hash(a.k,2,2)*.3)+a.k*.37)%1
    return CFrame.new(x,.6-.14*(x/BX)^2,-2.2+u*4.4)
end
function K.bugCursor(a,p,t,reduced,phase)
    gate(p,a.phase,phase,0)
    local slot=reduced and 0 or math.floor(t/1.3);local id=1+math.floor(hash(slot,4,4)*28);local i,j=math.floor((id-1)/4)-3,(id-1)%4
    local at=bugHome(i,j)+V3(0,.75+.1*math.sin(t*4),0)
    local cf=CFrame.new(at)*CFrame.Angles(0,.6,0)
    if a.tail then return cf*CFrame.new(.12,0,.5)*CFrame.Angles(0,-.5,0)end
    return cf
end

local TR,TH,TRIM=2.6,1.5,-.3
local TRINGS={0,.65,1.15}
local function tpt(phi,ang)local r=TR*math.cos(phi);return V3(math.sin(ang)*r,TRIM+TH*math.sin(phi),-math.cos(ang)*r)end
local TOP=TRIM+TH*math.sin(1.15)
local TENT={}
for k=0,3 do table.insert(TENT,{ang=(k+.5)/4*math.pi*2,L={1.35,1.15,.95},th=.36,phase=1})end
for k=0,3 do table.insert(TENT,{ang=k/4*math.pi*2,L={1.3,1.1,.9},th=.32,phase=2,rise=true})end
for _,a in ipairs({math.pi-.42,math.pi+.42})do table.insert(TENT,{ang=a,L={1.9,1.7,1.4},th=.5,phase=3})end
local function tentDirs(T,n,t)
    local out=V3(math.sin(T.ang),0,-math.cos(T.ang));local pitch=T.rise and {.12,.5,.9}or {-.22,-.12,.05}
    local dirs={};local w=t*1.5-n*.9
    for s=1,3 do
        local pt=pitch[s]+.12*math.sin(w-s*.7);local yaw=.32*math.sin(w-s*.9)*s/2
        dirs[s]=CFrame.fromAxisAngle(UP,yaw)*(out*math.cos(pt)+UP*math.sin(pt))
    end
    return dirs,out
end
function B.tendril(add,anim,dark,trim,accent)
    local navy=dark:Lerp(trim,.1);local teal,violet=trim,accent
    for i=0,7 do
        local ang=(i+.5)/8*math.pi*2;local tangent=V3(math.cos(ang),0,math.sin(ang))
        for j=1,2 do
            local a,b=tpt(TRINGS[j],ang),tpt(TRINGS[j+1],ang);local up=(b-a).Unit
            local p=add('Mantle',V3(2*math.pi*TR*math.cos(TRINGS[j])/8*1.08,(b-a).Magnitude+.1,.14),CFrame.fromMatrix((a+b)/2,tangent,up,tangent:Cross(up)),j==1 and navy or dark:Lerp(violet,.12),{material=Glass,alpha=.18});p.Reflectance=.15
        end
        local a,b=tpt(.08,i/8*math.pi*2),tpt(1.12,i/8*math.pi*2);local out=V3(math.sin(i/8*math.pi*2),0,-math.cos(i/8*math.pi*2))
        local cf,len=span(a+out*.1,b+out*.1);anim(add('Photophore',V3(.12,.08,len),cf,teal,{glow=true}),'levPhoto',{k=i})
    end
    add('MantleCap',V3(.2,2.3,2.3),CFrame.new(0,TOP+.02,0)*CFrame.Angles(0,0,math.pi/2),dark:Lerp(violet,.18),{material=Glass,alpha=.2,shape=Cyl})
    do local a,b=tpt(.35,math.pi),tpt(.95,math.pi);local cf,len=span(a+V3(0,.06,.08),b+V3(0,.06,.08));add('Spine',V3(.12,.06,len),cf,nil,{tint='full',glow=true})end
    anim(add('AbyssSheen',V3(.04,6.0,6.0),CFrame.new(0,TRIM-.08,0)*CFrame.Angles(0,0,math.pi/2),violet,{glow=true,alpha=.8,shape=Cyl}),'levSheen',{})
    for _,s in ipairs({-1,1})do
        for f=0,1 do anim(add('Fin',V3(1.25,.06,1.0),CFrame.new(s*(TR+.45),TRIM+.15,-.55+f*1.1),teal:Lerp(dark,.35),{material=Glass,alpha=.3}),'levFin',{side=s,f=f})end
        anim(add('DeepEye',V3(.32,.32,.32),CFrame.new(s*.75,TRIM+.25,-TR*.96),teal,{glow=true,shape=Ball}),'levDeepEye',{side=s})
    end
    for n,T in ipairs(TENT)do for s=1,3 do
        local th=T.th*(1-(s-1)*.25)
        anim(add(s==3 and 'TentacleTip' or 'Tentacle',V3(th,th*.8,T.L[s]),CFrame.new(),s==3 and teal or (s==1 and navy:Lerp(teal,.2) or navy:Lerp(violet,.3)),{glow=s==3,material=s<3 and Glass or nil,alpha=s==1 and .05 or s==2 and .25 or .2}),'levTent',{n=n,s=s})
    end end
    anim(add('EyeWhite',V3(.1,1.9,1.9),CFrame.new(0,TOP+.16,0)*CFrame.Angles(0,0,math.pi/2),teal:Lerp(Color3.new(1,1,1),.55),{glow=true,shape=Cyl}),'levEye',{})
    anim(add('EyeIris',V3(.12,1.15,1.15),CFrame.new(0,TOP+.2,0)*CFrame.Angles(0,0,math.pi/2),violet,{glow=true,shape=Cyl}),'levEye',{iris=true})
    anim(add('EyePupil',V3(.2,.08,.8),CFrame.new(0,TOP+.24,0),Color3.fromRGB(4,6,14)),'levEye',{iris=true,pupil=true})
    for _,s in ipairs({-1,1})do anim(add('EyeLid',V3(2.05,.14,1.05),CFrame.new(0,TOP+.3,s*.55),dark:Lerp(violet,.2),{mesh='soft'}),'levLid',{side=s})end
    for i=0,2 do anim(add('Plankton',V3(.2,.2,.2),CFrame.new(),teal,{glow=true,shape=Ball}),'levMote',{i=i})end
    local anchors={};for k=0,7 do local ang=(k+.5)/8*math.pi*2;table.insert(anchors,V3(math.sin(ang)*TR*.85,TRIM-.15,-math.cos(ang)*TR*.85))end
    return {anchors=anchors,crest=CFrame.new(0,TOP+.3,.9)}
end
function K.levPhoto(a,p,t,reduced)
    if not reduced then local w=math.max(0,math.sin(t*2.2-a.k*.6))^3;p.Color=Color3.fromRGB(60,240,220):Lerp(Color3.fromRGB(215,255,250),w*.7)end
    return a.home
end
function K.levSheen(a,p,t,reduced)
    if not reduced then p.Color=sheen(t*.8,.55);p.Transparency=.78+.08*math.sin(t*1.1)end
    return a.home
end
function K.levFin(a,p,t,reduced)
    local hinge=V3(a.side*TR,TRIM+.15,a.home.Z);local ang=reduced and 0 or .28*math.sin(t*2.4-a.f*1.3)
    return CFrame.new(hinge)*CFrame.Angles(0,0,a.side*ang)*CFrame.new(-hinge)*a.home
end
function K.levDeepEye(a,p,t,reduced)
    if not reduced then p.Transparency=.1+.3*(.5+.5*math.sin(t*1.7+a.side))end
    return a.home
end
function K.levTent(a,p,t,reduced,phase,scale)
    local T=TENT[a.n];gate(p,T.phase,phase,a.s==1 and .05 or .22)
    local dirs,out=tentDirs(T,a.n,reduced and 0 or t)
    local pos=V3(out.X*TR*.97,TRIM-.05,out.Z*TR*.97)
    for s=1,a.s-1 do pos+=dirs[s]*(T.L[s]-.06)end
    local d=dirs[a.s];if a.s==3 and not reduced then p.Color=Color3.fromRGB(60,240,220):Lerp(Color3.fromRGB(200,170,255),.5+.5*math.sin(t*2+a.n))end
    return along(pos+d*T.L[a.s]/2,d,out)
end
local function blink(t)local u=t%6.5;return u<.18 and math.sin(u/.18*math.pi)or 0 end
function K.levEye(a,p,t,reduced,phase)
    gate(p,3,phase,0)
    if not a.iris then return a.home end
    if not reduced and not a.pupil then p.Color=sheen(t*.7,.6)end
    local look=reduced and Vector3.zero or V3(.22*math.sin(t*.7),0,.18*math.sin(t*.53+1))
    return CFrame.new(look)*a.home
end
function K.levLid(a,p,t,reduced,phase)
    gate(p,3,phase,0)
    local shut=reduced and 0 or blink(t)
    return CFrame.new(0,0,a.side*.8*(1-shut))*a.home
end
function K.levMote(a,p,t)
    local u=(t*.25+a.i/3)%1;local ang=a.i*2.1+u*1.4
    p.Transparency=.2+.75*u*u
    return CFrame.new(math.sin(ang)*(TR+.9),TRIM-.4+u*3.2,-math.cos(ang)*(TR+.9))
end
return M
