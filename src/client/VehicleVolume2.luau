local G=require(script.Parent.ToyGeometry)
return function(h)
local glow,wedge,track,console=h.glow,h.wedge,h.track,h.console
local Metal,Glass=Enum.Material.Metal,Enum.Material.Glass
local function metal(p,r)p.Material=Metal;p.Reflectance=r or .12;return p end
local function ell(m,name,size,cf,color)local p=G.block(m,name,size,cf,color);local k=Instance.new('SpecialMesh');k.MeshType=Enum.MeshType.Sphere;k.Parent=p;return p end
local function noise(n)local x=math.sin(n*12.9898)*43758.5453;return x-math.floor(x)end
local function axisX(c)return CFrame.new(c)*CFrame.Angles(0,0,math.pi/2)end
local function ease(u)u=math.clamp(u,0,1);return u*u*(3-2*u)end
local function shared(f)
    local lt,ls,lp,lr,v
    return function(t,s,ph,r)if t~=lt or s~=ls or ph~=lp or r~=lr then lt,ls,lp,lr=t,s,ph,r;v=f(t,s,ph,r)end;return v end
end
local function fx(st,p,need,fn,extra)
    local base=p.Transparency;local a=extra or {}
    a.fn=function(self,t,s,ph,r)
        if need then p.Transparency=need>ph and 1 or base end
        return fn and fn(t,s,ph,r,p,base)or self.home
    end
    return track(st,p,'fn',a)
end
local function spark(st,p,from,vel,grav,rate,offset,need)
    p.CastShadow=false;local base=p.Transparency
    return track(st,p,'fn',{fn=function(_,t,_,ph,reduced)
        if reduced or(need and need>ph)then p.Transparency=1;return CFrame.new(from)end
        local u=(t*rate+offset)%1;p.Transparency=base+(1-base)*u^1.6
        return CFrame.new(from+vel*u-Vector3.new(0,grav*u*u,0))
    end})
end
local B={}
function B.serpent(m,st,dark,trim,accent)
    st.float=true;st.body=true
    local jade=dark:Lerp(trim,.45);local gold=accent;local mist=trim:Lerp(Color3.new(1,1,1),.55)
    local n=9;local S={k=0}
    local spine=shared(function(t,speed,_,reduced)
        local dt=math.clamp(t-(S.t or t),0,.25);S.t=t
        if reduced then S.k=0 else S.k+=((speed>1 and 1 or 0)-S.k)*(1-math.exp(-dt*2.5))end
        local k=ease(S.k);local w=reduced and 0 or t;local pts={}
        for i=0,n+1 do
            local z=-2.2+i*.66;local amp=.75*math.clamp((math.abs(z)-.5)/2.2,0,1)
            local fly=Vector3.new(amp*math.sin(w*3.2-i*.75),(i==0 and .95 or .42)+math.clamp((math.abs(z)-.8)/2,0,1)*.2*math.sin(w*2.3-i*.9),z)
            local a=i/(n+1)*math.pi*1.8+math.sin(w*.6)*.05;local r=1.5*(1+.03*math.sin(w*1.4))*(1-i*.012)
            local coil=Vector3.new(-math.sin(a)*r,(i==0 and 1.05 or .32+math.max(0,3-i)*.12)+.04*math.sin(w*1.6-i),-math.cos(a)*r)
            pts[i]=coil:Lerp(fly,k)
        end
        local cfs={}
        for i=0,n+1 do
            local f=i==0 and(pts[0]-pts[1]).Unit:Lerp(Vector3.new(0,.1,-1),(1-k)*.7)or pts[i-1]-pts[i]
            cfs[i]=CFrame.lookAt(pts[i],pts[i]+f)
        end
        S.cf=cfs;return S
    end)
    local function on(i,p,off,extra)
        off=off or CFrame.identity
        return fx(st,p,nil,function(t,s,ph,r,q,base)local cf=spine(t,s,ph,r).cf[i]*off;return extra and extra(cf,t,r,q,base)or cf end)
    end
    local cloud=ell(m,'CloudDeck',Vector3.new(1.5,.3,1.4),CFrame.new(0,.5,0),mist);cloud.Transparency=.1
    for _,side in ipairs({-1,1})do
        ell(m,'CloudPuff',Vector3.new(.8,.26,.7),CFrame.new(side*.55,.44,.32),mist).Transparency=.15
        glow(G.cylinder(m,'GoldSwirl',.18,.03,CFrame.new(side*.48,.62,-.32),gold))
    end
    on(0,G.part(m,'DragonHead',Vector3.new(.62,.46,.8),CFrame.identity,jade,'key'))
    on(0,G.part(m,'Snout',Vector3.new(.46,.3,.55),CFrame.identity,dark,'soft'),CFrame.new(0,-.04,-.6))
    on(0,G.part(m,'Jaw',Vector3.new(.4,.1,.6),CFrame.identity,trim,'armor'),CFrame.new(0,-.2,-.2),function(cf,t,r)return cf*CFrame.Angles(r and 0 or -math.max(0,math.sin(t*1.3))*.25,0,0)*CFrame.new(0,-.04,-.3)end)
    on(0,glow(G.block(m,'Mane',Vector3.new(.1,.42,.75),CFrame.identity,trim),.25),CFrame.new(0,.3,.35))
    for _,side in ipairs({-1,1})do
        on(0,glow(G.ball(m,'Eye',Vector3.one*.14,CFrame.identity,gold)),CFrame.new(side*.25,.1,-.22))
        on(0,metal(G.block(m,'Antler',Vector3.new(.07,.07,.75),CFrame.identity,gold),.25),CFrame.new(side*.18,.32,.3)*CFrame.Angles(.5,side*.35,0))
        local function whisker(cf,t,r)return cf*CFrame.new(side*.22,-.1,-.7)*CFrame.Angles(r and 0 or math.sin(t*2.4+side)*.15,side*.75+(r and 0 or math.sin(t*3+side)*.2),0)end
        on(0,glow(G.block(m,'Whisker',Vector3.new(.04,.04,1.0),CFrame.identity,gold)),nil,function(cf,t,r)return whisker(cf,t,r)*CFrame.new(0,0,.5)end)
        on(0,glow(G.ball(m,'WhiskerTip',Vector3.one*.09,CFrame.identity,trim)),nil,function(cf,t,r)return whisker(cf,t,r)*CFrame.new(0,0,1.0)end)
    end
    on(0,glow(G.ball(m,'Pearl',Vector3.one*.26,CFrame.identity,gold)),nil,function(cf,t,r)
        return CFrame.new((cf*CFrame.new(r and 0 or math.sin(t*2)*.28,.1+(r and 0 or math.cos(t*2.6)*.1),-1.3)).Position)end)
    for i=1,n do
        local w=.82-i*.035
        on(i,ell(m,'Coil',Vector3.new(w,w*.7,.82),CFrame.identity,i%2==0 and dark or jade))
        on(i,metal(wedge(m,'DorsalSpine',Vector3.new(.08,.26,.36),CFrame.identity,gold),.2),CFrame.new(0,w*.35+.1,.05))
        on(i,glow(G.block(m,'ScaleGlint',Vector3.new(w*.55,.03,.18),CFrame.identity,trim),.3),CFrame.new(0,w*.35+.01,-.22),function(cf,t,r,q,base)
            q.Transparency=r and base or base+(1-base)*(math.sin(t*4-i*.9)*.5+.5)*.8;return cf end)
        if i==2 or i==6 then for _,side in ipairs({-1,1})do
            on(i,metal(G.block(m,'Claw',Vector3.new(.12,.12,.32),CFrame.identity,gold),.25),CFrame.new(side*w*.52,-.18,0)*CFrame.Angles(.4,0,side*.4))
        end end
    end
    on(n+1,ell(m,'TailTip',Vector3.new(.3,.22,.7),CFrame.identity,jade))
    for _,side in ipairs({-1,1})do
        on(n+1,glow(wedge(m,'TailFrond',Vector3.new(.06,.45,.8),CFrame.identity,trim),.2),nil,function(cf,t,r)
            return cf*CFrame.new(side*.1,.08,.25)*CFrame.Angles(0,side*(.4+(r and 0 or math.sin(t*3.5)*.25)),side*.5)*CFrame.new(0,0,.3)end)
    end
    for i=0,7 do
        local seg=({1,5,6,7,8,9,7,1})[i+1];local p=glow(G.ball(m,'JadeMist',Vector3.one*(.14+(i%3)*.03),CFrame.identity,i%2==0 and trim or gold),.2)
        on(seg,p,nil,function(cf,t,r,q,base)
            local u=(t*.7+i/8)%1;q.Transparency=r and 1 or base+(1-base)*u^1.4
            return CFrame.new(cf.Position+Vector3.new((noise(i)-.5)*.4,.2+u*.9,(noise(i+9)-.5)*.4))end)
    end
    track(st,glow(G.cylinder(m,'JadeGlow',1.75,.03,CFrame.new(0,.03,.4),trim),.8),'pulse',{rate=2,range=.12,offset=0,ground=true})
end
function B.supercar(m,st,dark,trim,accent)
    st.float=true;st.body=true
    local gold=accent;local ice=trim;local white=dark:Lerp(Color3.new(1,1,1),.5)
    local function gem(p,a)p.Material=Glass;p.Reflectance=.35;p.Transparency=a or .05;return p end
    gem(G.part(m,'Chassis',Vector3.new(1.9,.3,3.8),CFrame.new(0,.5,.15),dark,'armor'))
    gem(G.block(m,'DiamondNose',Vector3.new(1.35,.3,1.35),CFrame.new(0,.52,-1.85)*CFrame.Angles(0,math.pi/4,0),white))
    gem(wedge(m,'Bonnet',Vector3.new(1.6,.32,1.1),CFrame.new(0,.78,-1.2)*CFrame.Angles(0,math.pi,0),dark))
    gem(wedge(m,'RearDeck',Vector3.new(1.7,.38,1.0),CFrame.new(0,.82,1.5),dark))
    G.part(m,'CockpitFloor',Vector3.new(1.1,.06,1.1),CFrame.new(0,.68,0),ice:Lerp(dark,.5),'board')
    local screen=gem(G.block(m,'Windscreen',Vector3.new(1.2,.45,.05),CFrame.new(0,1.0,-.82)*CFrame.Angles(-.75,0,0),ice),.45);screen.CastShadow=false
    for _,side in ipairs({-1,1})do
        gem(G.part(m,'SidePod',Vector3.new(.38,.42,3.2),CFrame.new(side*1.02,.62,.2)*CFrame.Angles(0,0,side*.35),dark,'armor'))
        metal(G.block(m,'SpoilerStrut',Vector3.new(.08,.45,.12),CFrame.new(side*.7,1.15,2.0),gold),.3)
        glow(G.block(m,'GoldTrim',Vector3.new(.08,.06,3.4),CFrame.new(side*1.2,.84,.3),gold))
        glow(G.block(m,'NoseTrim',Vector3.new(.07,.05,1.0),CFrame.new(side*.4,.69,-2.15)*CFrame.Angles(0,side*-.785,0),gold))
        glow(G.block(m,'Headlight',Vector3.new(.32,.08,.05),CFrame.new(side*.62,.6,-2.0)*CFrame.Angles(0,side*-.6,0),ice))
        track(st,glow(G.cylinder(m,'Thruster',.16,.3,CFrame.new(side*.55,.62,2.12)*CFrame.Angles(math.pi/2,0,0),ice),.2),'pulse',{rate=10,range=.4,offset=side})
    end
    metal(G.part(m,'Spoiler',Vector3.new(2.2,.08,.45),CFrame.new(0,1.4,2.05),gold,'board'),.3)
    glow(G.block(m,'TailStrip',Vector3.new(1.5,.06,.05),CFrame.new(0,.82,2.06),ice))
    console(m,-.85,1.45,.9,ice,dark,gold)
    for i=-1,1 do metal(G.block(m,'SetGem',Vector3.new(.2,.2,.2),CFrame.new(i*.42,.92,-1.45+math.abs(i)*.15)*CFrame.Angles(math.pi/4,math.pi/4,0),ice),.4).Material=Glass end
    for i=0,5 do
        local side=i%2==0 and -1 or 1;local z=-1.8+math.floor(i/2)*1.6
        local p=glow(G.ball(m,'Glint',Vector3.one*.16,CFrame.new(side*(1.2-math.abs(z+.2)*.12),.88,z),i%3==0 and white or ice))
        fx(st,p,nil,function(t,_,_,r,q)q.Transparency=r and .3 or math.clamp(1-math.max(0,math.sin(t*2.3+i*1.9))^6*1.2,0,1);return nil end)
    end
    for ci,c in ipairs({Vector3.new(-1.05,.32,-1.35),Vector3.new(1.05,.32,-1.35),Vector3.new(-1.05,.32,1.45),Vector3.new(1.05,.32,1.45)})do
        local dir=(ci%2==0)and 1 or -1
        glow(G.cylinder(m,'RingCore',.3,.05,CFrame.new(c),ice),.25)
        for k=0,3 do
            local p=metal(G.block(m,'HoverRing',Vector3.new(.38,.07,.08),CFrame.identity,k%2==0 and gold or white),.3)
            fx(st,p,nil,function(t,s,_,r)return CFrame.new(c)*CFrame.Angles(0,k*math.pi/2+(r and 0 or t*(4+math.min(s,12)*.4)*dir),0)*CFrame.new(0,0,-.42)end)
        end
    end
    local L={moving=false,at=-9}
    local launch=shared(function(t,s,_,r)
        local now=s>1 and not r;if now and not L.moving then L.at=t end;L.moving=now;return L end)
    for i=0,5 do
        local side=i%2==0 and -1 or 1;local from=Vector3.new(side*.6,.6,2.15)
        local vel=Vector3.new(side*(.5+noise(i)*.9),.9+noise(i+3)*.8,1.6+noise(i+7)*1.2)
        local p=glow(G.ball(m,'LaunchSpark',Vector3.one*(.13+(i%3)*.03),CFrame.new(from),i%3==2 and white or gold))
        fx(st,p,nil,function(t,s,ph,r,q,base)
            local u=(t-launch(t,s,ph,r).at)/.9
            if r or u<0 or u>1 then q.Transparency=1;return CFrame.new(from)end
            q.Transparency=base+(1-base)*u^1.5;return CFrame.new(from+vel*u-Vector3.new(0,1.2*u*u,0))
        end)
    end
    track(st,glow(G.cylinder(m,'Underglow',1.6,.03,CFrame.new(0,.03,.1),ice),.72),'pulse',{rate=2.6,range=.15,offset=0,ground=true})
end
function B.seraph(m,st,dark,trim,accent)
    st.float=true;st.body=true
    local ivory=dark;local gold=trim;local pink=accent
    local disc=ell(m,'LightDisc',Vector3.new(1.5,.22,1.5),CFrame.new(0,.48,0),ivory);disc.Material=Glass;disc.Transparency=.15;disc.Reflectance=.2
    metal(G.cylinder(m,'DiscRim',.82,.06,CFrame.new(0,.44,0),gold),.3)
    metal(G.part(m,'Harness',Vector3.new(.62,.62,.12),CFrame.new(0,3.45,.68),gold,'armor'),.3)
    glow(G.ball(m,'HarnessGem',Vector3.one*.2,CFrame.new(0,3.45,.76),pink))
    local pairs_={{y=3.55,yaw=-.15,roll=.1,len=1.0,beat=0},{y=3.85,yaw=.45,roll=.35,len=.82,beat=1.1},{y=3.2,yaw=-.75,roll=-.15,len=.9,beat=2.2}}
    for j,w in ipairs(pairs_)do for _,side in ipairs({-1,1})do
        local root=CFrame.new(side*.3,w.y,.72)*CFrame.Angles(0,side*-w.yaw,side*w.roll)
        local flap=shared(function(t,_,_,r)return r and root or root*CFrame.Angles(0,0,side*math.sin(t*2.6+w.beat)*.32)end)
        local function wing(p,off)fx(st,p,j,function(t,s,ph,r)return flap(t,s,ph,r)*off end)end
        local L=w.len
        wing(G.part(m,'WingArm',Vector3.new(1.5*L,.12,.3),CFrame.identity,ivory,'soft'),CFrame.new(side*.75*L,0,0))
        wing(metal(G.block(m,'Covert',Vector3.new(1.3*L,.08,.5),CFrame.identity,gold),.25),CFrame.new(side*.7*L,.05,.3))
        wing(glow(G.block(m,'WingEdge',Vector3.new(1.5*L,.05,.06),CFrame.identity,pink)),CFrame.new(side*.75*L,.06,-.15))
        for f=1,4 do
            local len=(1.0+f*.22)*L;local a=side*(-.25+f*.2)
            local p=G.block(m,'Feather',Vector3.new(.22,.05,len),CFrame.identity,f==4 and gold:Lerp(ivory,.5)or ivory)
            p.Transparency=f>=3 and .35 or .05;p.CastShadow=false
            wing(p,CFrame.new(side*(.35+f*.28)*L,-.02,.15)*CFrame.Angles(0,-a,0)*CFrame.new(0,0,len/2))
        end
    end end
    for i=0,9 do
        local p=glow(G.block(m,'Halo',Vector3.new(.55,.07,.1),CFrame.identity,pink));p.CastShadow=false
        fx(st,p,3,function(t,_,_,r)return CFrame.new(0,5.55+(r and 0 or math.sin(t*1.5)*.06),.05)*CFrame.Angles(0,i/10*math.pi*2+(r and 0 or t*.5),0)*CFrame.new(0,0,-.95)end)
    end
    for i=0,1 do
        fx(st,glow(G.ball(m,'HaloGlint',Vector3.one*.17,CFrame.identity,gold)),3,function(t,_,_,r)
            return CFrame.new(0,5.6,.05)*CFrame.Angles(0,i*math.pi-(r and 0 or t*1.2),0)*CFrame.new(0,0,-.95)end)
    end
    for i=0,11 do
        local p=glow(G.block(m,'Sigil',Vector3.new(.62,.03,.09),CFrame.identity,i%3==0 and pink or gold),.2)
        fx(st,p,nil,function(t,_,_,r)return CFrame.Angles(0,i/12*math.pi*2+(r and 0 or t*.25),0)*CFrame.new(0,.04,-1.75)end,{ground=true})
    end
    track(st,glow(G.cylinder(m,'SigilCore',1.5,.03,CFrame.new(0,.03,0),pink),.82),'pulse',{rate=1.8,range=.12,offset=0,ground=true})
    for i=0,5 do
        local side=i%2==0 and -1 or 1;local from=Vector3.new(side*(1.0+(i%3)*.5),3.4,.9+(i%3)*.2)
        spark(st,glow(G.block(m,'DriftFeather',Vector3.new(.08,.03,.3),CFrame.new(from),i%3==0 and pink or ivory),.1),from,Vector3.new(side*.4,-2.4,.8),0,.45,i/6,1+math.floor(i/2))
    end
    for i=0,3 do
        fx(st,glow(G.ball(m,'Mote',Vector3.one*.14,CFrame.identity,pink)),2,function(t,_,_,r)
            local a=i/4*math.pi*2+(r and 0 or t*.8);return CFrame.new(math.cos(a)*1.3,2.2+(r and 0 or math.sin(t*1.9+i)*.5),math.sin(a)*1.3)end)
    end
end
function B.lightcycle(m,st,dark,trim,accent)
    st.body=true
    local cyan=trim;local mag=accent;local black=dark
    local glitch=shared(function(t,_,ph,r)
        if r then return 0 end
        local period=({2.2,1.1,.6})[ph]or 2.2;local u=(t%period)/period
        return u<.08+.04*ph and ph or 0
    end)
    local function body(p,i)
        local base=p.Transparency;local home=p.CFrame
        return fx(st,p,nil,function(t,s,ph,r,q)
            local g=glitch(t,s,ph,r);q.Transparency=ph>=3 and math.max(base,.55)or base
            if g>0 then local k=math.floor(t*20)+i;return CFrame.new((noise(k)-.5)*.12*g,0,(noise(k+5)-.5)*.1*g)*home end
            return home
        end)
    end
    local function gloss(p)p.Reflectance=.3;return p end
    body(gloss(G.part(m,'Chassis',Vector3.new(.7,.34,3.2),CFrame.new(0,.52,.1),black,'armor')),1)
    body(gloss(G.part(m,'FrontCowl',Vector3.new(.82,.46,1.1),CFrame.new(0,.82,-1.3)*CFrame.Angles(.2,0,0),black,'armor')),2)
    body(gloss(G.part(m,'RearCowl',Vector3.new(.86,.5,1.05),CFrame.new(0,.84,1.38)*CFrame.Angles(-.18,0,0),black,'armor')),3)
    body(glow(G.block(m,'Visor',Vector3.new(.5,.05,.5),CFrame.new(0,1.08,-1.3)*CFrame.Angles(.2,0,0),cyan)),4)
    body(glow(G.block(m,'SpineLight',Vector3.new(.08,.04,1.0),CFrame.new(0,1.1,1.38)*CFrame.Angles(-.18,0,0),cyan)),5)
    body(G.part(m,'Handlebar',Vector3.new(1.1,.08,.1),CFrame.new(0,1.35,-.85),black,'armor'),6)
    G.rod(m,'BarPost',Vector3.new(0,.9,-.95),Vector3.new(0,1.33,-.86),.05,black)
    for _,side in ipairs({-1,1})do
        body(G.part(m,'FootBoard',Vector3.new(.42,.06,1.1),CFrame.new(side*.52,.55,0),black,'board'),7+side)
        body(glow(G.block(m,'SideLine',Vector3.new(.04,.06,3.0),CFrame.new(side*.44,.62,.1),mag)),9+side)
        body(glow(G.block(m,'Grip',Vector3.new(.15,.12,.15),CFrame.new(side*.55,1.35,-.85),cyan)),11+side)
    end
    for wi,z in ipairs({-1.45,1.5})do
        local c=Vector3.new(0,.58,z);local hub=CFrame.new(c)*CFrame.Angles(0,math.pi/2,0)
        body(glow(G.cylinder(m,'WheelRim',.58,.18,axisX(c),cyan)),20+wi)
        body(gloss(G.cylinder(m,'WheelHub',.46,.22,axisX(c),black)),22+wi)
        for k=0,2 do track(st,G.block(m,'Spoke',Vector3.new(.08,.08,.86),CFrame.new(c)*CFrame.Angles(k*math.pi/3,0,0),k==0 and mag or black),'spin',{pivot=hub,rate=-8})end
    end
    local W={pts={}}
    local trail=shared(function(t,s,_,r)
        local model=W.model;if not model then return W end
        local pivot,scale=model:GetPivot(),model:GetScale();W.pivot,W.scale=pivot,scale
        local pos=pivot.Position;local h=W.pts;local last=h[#h]
        if last and((pos-last.p).Magnitude>12*scale or t<last.t)then table.clear(h);last=nil end
        if not last or(pos-last.p).Magnitude>.65*scale then table.insert(h,{p=pos,t=t})end
        while #h>0 and t-h[1].t>1.2 do table.remove(h,1)end
        local out={};local rear=pivot*Vector3.new(0,0,2.05*scale);table.insert(out,rear)
        for i=#h,1,-1 do if(h[i].p-pos).Magnitude>2.05*scale then table.insert(out,h[i].p)end end
        if #out<3 and s>1 and not r then
            table.clear(out);local len=math.min(s/6,1)
            for i=0,8 do table.insert(out,pivot*Vector3.new(math.sin(t*2-i*.6)*.08*i*len,0,(2.05+i*.55*len)*scale))end
        end
        W.out=out;return W
    end)
    local function toLocal(v)return W.pivot:PointToObjectSpace(v)/W.scale end
    local function along(u)
        local o=W.out;if not o or #o<2 then return nil end
        local f=u*(#o-1);local i=math.floor(f);if i>=#o-1 then i=#o-2 end
        return toLocal(o[i+1]:Lerp(o[i+2],f-i))
    end
    local function wallPart(p,i,y,hgt)
        p.CastShadow=false;local base=p.Transparency
        track(st,p,'fn',{ground=true,fn=function(self,t,s,ph,r)
            W.model=W.model or p.Parent;local T=trail(t,s,ph,r);local o=T.out
            if r or not o or not o[i+1]then p.Transparency=1;return self.home end
            local a,b=toLocal(o[i]),toLocal(o[i+1]);local d=b-a
            if d.Magnitude<.05 then p.Transparency=1;return self.home end
            p.Transparency=base+(1-base)*((i-1)/8)^1.5;p.Size=Vector3.new(.06,hgt,d.Magnitude+.04)*W.scale
            return CFrame.lookAt((a+b)/2+Vector3.new(0,y,0),b+Vector3.new(0,y,0))
        end})
    end
    for i=1,8 do
        wallPart(glow(G.block(m,'LightWall',Vector3.new(.06,.5,.5),CFrame.new(0,.3,2.4),cyan),.35),i,.3,.5)
        wallPart(glow(G.block(m,'WallEdge',Vector3.new(.06,.06,.5),CFrame.new(0,.58,2.4),mag)),i,.58,.06)
    end
    for gi,side in ipairs({-1,1})do
        local p=glow(G.block(m,'GlitchGhost',Vector3.new(.8,.4,3.6),CFrame.identity,side<0 and cyan or mag),.6)
        fx(st,p,nil,function(t,s,ph,r,q)
            local g=glitch(t,s,ph,r);q.Transparency=g>0 and .6 or 1
            return CFrame.new(side*(.18+.08*g),.6,.1+(noise(math.floor(t*20)+gi)-.5)*.2)end)
    end
    for i=0,9 do
        local p=glow(G.block(m,'PixelChunk',Vector3.one*(.18+(i%3)*.06),CFrame.identity,i%2==0 and cyan or mag),.15)
        fx(st,p,2,function(t,_,ph,r,q)
            local k=math.floor(t*(2+ph))+i*7;local side=i%2==0 and -1 or 1
            if ph>=2 then q.Transparency=r and .15 or noise(k*3)<.25 and 1 or .15 end
            return CFrame.new(side*(.9+noise(k)*.8),.5+noise(k+1)*.9,-2+noise(k+2)*4.2)
        end)
    end
    local wires={{Vector3.new(-.62,1.0,-2.05),Vector3.new(.62,1.0,-2.05)},{Vector3.new(-.62,1.0,2.1),Vector3.new(.62,1.0,2.1)},
        {Vector3.new(-.62,1.0,-2.05),Vector3.new(-.62,1.0,2.1)},{Vector3.new(.62,1.0,-2.05),Vector3.new(.62,1.0,2.1)},
        {Vector3.new(-.62,.15,-2.05),Vector3.new(-.62,1.0,-2.05)},{Vector3.new(.62,.15,-2.05),Vector3.new(.62,1.0,-2.05)},
        {Vector3.new(-.62,.15,2.1),Vector3.new(-.62,1.0,2.1)},{Vector3.new(.62,.15,2.1),Vector3.new(.62,1.0,2.1)},
        {Vector3.new(-.62,.15,-2.05),Vector3.new(-.62,.15,2.1)},{Vector3.new(.62,.15,-2.05),Vector3.new(.62,.15,2.1)}}
    for i,e in ipairs(wires)do
        local a,b=e[1],e[2];local p=glow(G.block(m,'Wireframe',Vector3.new(.05,.05,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),i%2==0 and mag or cyan),.1)
        p.Material=Enum.Material.ForceField;local home=p.CFrame
        fx(st,p,3,function(t,_,_,r)return r and home or CFrame.new(0,0,(noise(math.floor(t*12)+i)-.5)*.06)*home end)
    end
    for i=0,5 do
        local p=glow(G.block(m,'CodeBlock',Vector3.new(.22,.12,.34),CFrame.new(0,.7,2.6),i%2==0 and cyan or mag),.1)
        track(st,p,'fn',{ground=true,fn=function(self,t,s,ph,r)
            W.model=W.model or p.Parent;trail(t,s,ph,r)
            local at=not r and ph>=3 and along((t*.6+i/6)%1)
            p.Transparency=at and .1 or 1;return at and CFrame.new(at+Vector3.new(0,.3+(i%3)*.16,0))or self.home
        end})
    end
    for i=0,3 do spark(st,glow(G.block(m,'DataSpark',Vector3.one*.12,CFrame.new(0,.2,2.0),i%2==0 and cyan or mag)),Vector3.new(0,.15,2.0),Vector3.new((i-1.5)*.35,.7,1.3),.6,1.1,i/4)end
    track(st,glow(G.cylinder(m,'GridGlow',1.5,.03,CFrame.new(0,.03,0),cyan),.82),'pulse',{rate=3,range=.12,offset=0,ground=true})
    for i=-1,1,2 do
        track(st,glow(G.block(m,'GridLine',Vector3.new(.04,.02,3.6),CFrame.new(i*.95,.04,0),cyan),.5),'pulse',{rate=4,range=.3,offset=i,ground=true})
        track(st,glow(G.block(m,'GridLine',Vector3.new(2.6,.02,.04),CFrame.new(0,.04,i*1.1),mag),.5),'pulse',{rate=4,range=.3,offset=i+1,ground=true})
    end
end
function B.manta(m,st,dark,trim,accent)
    st.float=true;st.body=true
    local navy=dark;local teal=trim;local violet=accent;local deep=dark:Lerp(trim,.18)
    local bodyP=ell(m,'MantaBody',Vector3.new(1.8,.45,2.7),CFrame.new(0,.42,.1),navy);bodyP.Reflectance=.15
    G.part(m,'Saddle',Vector3.new(1.0,.06,1.0),CFrame.new(0,.66,0),deep,'board')
    glow(G.block(m,'DorsalStripe',Vector3.new(.1,.04,1.0),CFrame.new(0,.62,1.0),teal),.2)
    for _,side in ipairs({-1,1})do
        local fin=CFrame.new(side*.45,.42,-1.35)
        fx(st,glow(wedge(m,'CephalicFin',Vector3.new(.16,.18,.6),CFrame.identity,teal),.1),nil,function(t,_,_,r)
            return fin*CFrame.Angles(r and 0 or math.sin(t*1.8+side)*.18,side*.25,0)*CFrame.new(0,0,-.28)end)
        glow(G.ball(m,'MantaEye',Vector3.one*.16,CFrame.new(side*.5,.55,-1.05),teal))
    end
    local bands={{w=.45,c=2.0},{w=.45,c=1.7},{w=.45,c=1.3},{w=.4,c=.85}}
    for _,side in ipairs({-1,1})do
        local root=CFrame.new(side*.78,.42,.15)
        local wingPose=shared(function(t,s,_,r)
            local out={};local cf=root;local w=r and 0 or t*(2+math.min(s,12)*.08)
            for j,b in ipairs(bands)do
                cf=cf*CFrame.Angles(0,0,side*(r and 0 or math.sin(w-j*.7)*.16))
                out[j]=cf*CFrame.new(side*b.w/2,0,0);cf=cf*CFrame.new(side*b.w,0,0)
            end
            return out
        end)
        for j,b in ipairs(bands)do
            local tip=j==4
            local p=G.block(m,'WingBand',Vector3.new(b.w+.02,.1,b.c),CFrame.identity,j%2==0 and deep or navy)
            p.Material=Glass;p.Reflectance=.2;p.Transparency=tip and .5 or .1;p.CastShadow=false
            fx(st,p,nil,function(t,s,ph,r)return wingPose(t,s,ph,r)[j]*CFrame.new(0,0,(2.0-b.c)*.3)end)
            fx(st,glow(G.block(m,'LeadingEdge',Vector3.new(b.w+.02,.06,.07),CFrame.identity,teal),tip and .5 or 0),nil,function(t,s,ph,r)
                return wingPose(t,s,ph,r)[j]*CFrame.new(0,.04,(2.0-b.c)*.3-b.c/2+.04)end)
            for k,dz in ipairs({.18,-.2})do
                local spot=glow(G.ball(m,'BioSpot',Vector3.new(.14,.05,.14),CFrame.identity,(j+k)%2==0 and violet or teal),tip and .5 or .1)
                fx(st,spot,nil,function(t,s,ph,r,q,base)
                    q.Transparency=r and base or base+(1-base)*(math.sin(t*3-j*1.1-k*1.6+side)*.5+.5)*.7
                    return wingPose(t,s,ph,r)[j]*CFrame.new((k-1.5)*b.w*.3,.06,(2.0-b.c)*.3+b.c*dz)end)
            end
            if j==2 or j==3 then
                local function eye(t,s,ph,r)return wingPose(t,s,ph,r)[j]*CFrame.new(0,.07,(2.0-b.c)*.3-.05)end
                fx(st,glow(G.cylinder(m,'BackEye',.2,.03,CFrame.identity,violet)),3,function(t,s,ph,r)return eye(t,s,ph,r)end)
                fx(st,glow(G.ball(m,'BackPupil',Vector3.new(.1,.05,.18),CFrame.identity,teal)),3,function(t,s,ph,r,q)
                    local blink=not r and(t*.5+j*.3+side*.2)%1<.06;q.Transparency=(ph<3 or blink)and 1 or 0
                    return eye(t,s,ph,r)*CFrame.new(0,.02,0)end)
            end
        end
        local streamer=glow(G.block(m,'TipStreamer',Vector3.new(.05,.03,1.1),CFrame.identity,teal),.55)
        fx(st,streamer,nil,function(t,s,ph,r)return wingPose(t,s,ph,r)[4]*CFrame.new(side*.15,0,.75)*CFrame.Angles(0,r and 0 or math.sin(t*3)*.15,0)end)
    end
    local function chain(n,len,rootCf,rate,amp,off)
        return function(t,r)local out={};local cf=rootCf
            for k=1,n do cf=cf*CFrame.Angles(0,r and 0 or math.sin(t*rate-k*.8+off)*amp,0);out[k]=cf*CFrame.new(0,0,len/2);cf=cf*CFrame.new(0,0,len)end
            return out end
    end
    local whip=chain(3,.6,CFrame.new(0,.42,1.45),2.6,.22,0)
    for k=1,3 do fx(st,G.block(m,'TailWhip',Vector3.new(.12-.025*k,.08,.62),CFrame.identity,k==3 and teal or navy),nil,function(t,_,_,r)return whip(t,r)[k]end)end
    for ti=1,4 do
        local x=(ti-2.5)*.32;local arm=chain(4,.5,CFrame.new(x,.36,1.3)*CFrame.Angles(0,(ti-2.5)*.22,0),2.1,.3,ti*1.3)
        for k=1,4 do
            local p=k==4 and glow(G.ball(m,'TentacleTip',Vector3.new(.14,.1,.3),CFrame.identity,ti%2==0 and violet or teal))or G.block(m,'Tentacle',Vector3.new(.15-.025*k,.1,.52),CFrame.identity,k==3 and deep or navy)
            fx(st,p,2,function(t,_,_,r)return arm(t,r)[k]end)
        end
    end
    for i=0,7 do
        local a=i/8*math.pi*2;local from=Vector3.new(math.cos(a)*1.9,.25,math.sin(a)*1.9+.2)
        spark(st,glow(G.ball(m,'Plankton',Vector3.one*(.1+(i%3)*.03),CFrame.new(from),i%2==0 and teal or violet),.1),from,Vector3.new(math.cos(a)*.3,1.3,math.sin(a)*.3),-.1,.5,i/8)
    end
    track(st,glow(G.cylinder(m,'AbyssGlow',1.9,.03,CFrame.new(0,.03,.2),teal),.8),'pulse',{rate=1.6,range=.12,offset=0,ground=true})
end
return B
end
