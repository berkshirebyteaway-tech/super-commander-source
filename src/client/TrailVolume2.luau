local V={};local T
local function rgb(a)return Color3.fromRGB(table.unpack(a))end
local function out(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function piece(...)return T.piece(...)end
local function hash(n)return T.hash(n)end
local white=Color3.new(1,1,1)
local function halo(x,sat)return Color3.fromHSV(.8+.1*(.5+.5*math.sin(x)),sat or .45,1)end
local function seg(p,o,a,b,w,h)
    local d=b-a;local len=d.Magnitude;if len<1e-3 then p.Transparency=1;return end
    p.Size=Vector3.new(w,h,len);p.CFrame=o*CFrame.lookAt((a+b)/2,b,math.abs(d.Unit.Y)>.97 and Vector3.xAxis or Vector3.yAxis)
end
local function hideAll(list,hidden)if hidden then for _,p in ipairs(list)do p.Transparency=1 end end end
local function across(along,d)
    local q=along(d+.05)-along(math.max(0,d-.05));local s=Vector3.yAxis:Cross(q)
    return s.Magnitude>1e-4 and s.Unit or Vector3.zAxis
end
local function ring(parts,c,r,spin,w,h)
    local n=#parts
    for i,p in ipairs(parts)do local a0,a1=spin+(i-1)/n*math.pi*2,spin+i/n*math.pi*2
        seg(p,c,Vector3.new(math.cos(a0)*r,0,math.sin(a0)*r),Vector3.new(math.cos(a1)*r,0,math.sin(a1)*r),w,h)
    end
end
local ghostBlocks={{Vector3.new(0,1.02,0),Vector3.new(.24,.24,.24)},{Vector3.new(0,.66,0),Vector3.new(.22,.38,.32)},
    {Vector3.new(0,.21,-.08),Vector3.new(.12,.42,.12)},{Vector3.new(0,.21,.08),Vector3.new(.12,.42,.12)},
    {Vector3.new(0,.66,-.23),Vector3.new(.1,.34,.1)},{Vector3.new(0,.66,.23),Vector3.new(.1,.34,.1)}}
V.kinds={
    dragonGlint={life=.9,build=function(e,parent,style)
        e.parts={piece(parent,'DragonGlint',Vector3.one,rgb(style.accent),true),piece(parent,'DragonGlint',Vector3.one,white,true)}
    end,pose=function(e,o,u,t,k)
        local h=e.seed;local tw=(.5+.5*math.abs(math.sin(t*10+h*7)))*(1-.5*u)
        local cf=o*CFrame.new(.1*u*k,(.28+.12*hash(h)+.25*u)*k,e.side*(.08+.26*hash(h+1))*k)*CFrame.Angles(0,t*2+h,0)
        local a,b=e.parts[1],e.parts[2]
        a.Size=Vector3.new(.24,.025,.025)*k*tw;b.Size=Vector3.new(.025,.025,.24)*k*tw;a.CFrame=cf;b.CFrame=cf
        a.Transparency=.05+.9*u^1.4;b.Transparency=.1+.9*u^1.4
    end},
    gem={life=1.2,build=function(e,parent,style)
        local ice=rgb(style.secondary)
        local g=piece(parent,'Gem',Vector3.one,ice:Lerp(white,.35),false);g.Material=Enum.Material.Glass;g.Reflectance=.3
        e.parts={g,piece(parent,'GemCore',Vector3.one,white,true),piece(parent,'GemFlare',Vector3.one,white,true),piece(parent,'GemFlare',Vector3.one,ice,true)}
    end,pose=function(e,o,u,t,k)
        local h=e.seed;local b=math.abs(math.cos(u*7.85))
        local pos=Vector3.new((.08+.55*u)*k,(.05+.62*(1-u)^2*b)*k,e.side*(.06+.32*hash(h)*out(u*2))*k)
        local s=(.12+.03*hash(h+2))*k*(1-.35*u^2);local cf=o*CFrame.new(pos)*CFrame.Angles(.785,t*3+h*5,.615)
        local g,c=e.parts[1],e.parts[2]
        g.Size=Vector3.one*s;g.CFrame=cf;g.Transparency=.15+.85*u^2
        c.Size=Vector3.one*s*.45;c.CFrame=cf;c.Transparency=.1+.9*u^1.5
        local flash=math.max(0,1-b*4)*(1-u)
        for i=3,4 do local p=e.parts[i]
            p.Size=(i==3 and Vector3.new(.36,.02,.02)or Vector3.new(.02,.02,.36))*k*(.3+.9*flash)
            p.CFrame=o*CFrame.new(pos.X,.03*k,pos.Z)*CFrame.Angles(0,.785,0);p.Transparency=1-.92*flash
        end
    end},
    glitter={life=.9,build=function(e,parent,style)
        local ice=rgb(style.secondary)
        e.parts={piece(parent,'Glitter',Vector3.one,white,true),piece(parent,'Glitter',Vector3.one,ice,true),piece(parent,'Glitter',Vector3.one,ice:Lerp(white,.5),true)}
    end,pose=function(e,o,u,t,k)
        for i,p in ipairs(e.parts)do local h=e.seed+i*2.3;local tw=math.abs(math.sin(t*12+h*9))
            p.Size=Vector3.one*(.025+.035*tw)*k
            p.CFrame=o*CFrame.new((.05+.4*u*hash(h))*k,((.1+.75*hash(h+1))*(1-u)+.02)*k,(hash(h+2)-.5)*.6*k)*CFrame.Angles(.785,t+h,.785)
            p.Transparency=math.min(1,.1+.5*(1-tw)+.4*u)
        end
    end},
    plumeFeather={life=2,build=function(e,parent,style)
        e.style=style
        e.parts={piece(parent,'SeraphFeather',Vector3.one,rgb(style.primary),true,true),piece(parent,'SeraphFeatherQuill',Vector3.one,rgb(style.secondary),true),
            piece(parent,'SeraphFeatherGlow',Vector3.one,rgb(style.secondary),true,true)}
    end,pose=function(e,o,u,t,k)
        local h,side=e.seed,e.side;local f=math.min(1,u/.7);local sway=math.sin(u*9+h*5)
        local pos=Vector3.new((.1+.45*u)*k,math.max(.03,1-.97*f)*k,(side*(.25+.25*hash(h))+sway*.14*(1-f))*k)
        local cf=o*CFrame.new(pos)*CFrame.Angles(sway*.5*(1-f),h*6+u*1.5,sway*.35*(1-f));local s=k*(1-.25*u)
        local a,b,c=e.parts[1],e.parts[2],e.parts[3]
        a.Size=Vector3.new(.13,.02,.4)*s;a.CFrame=cf;a.Color=rgb(e.style.primary):Lerp(rgb(e.style.secondary),.4*(.5+.5*math.sin(t*6-h*3)))
        b.Size=Vector3.new(.025,.03,.36)*s;b.CFrame=cf*CFrame.new(0,.012*s,0)
        a.Transparency=.05+.9*math.max(0,(u-.6)/.4)^1.3;b.Transparency=a.Transparency
        c.Size=Vector3.new(.26,.01,.55)*s;c.CFrame=cf*CFrame.new(0,-.01*s,0);c.Transparency=f>=1 and math.min(1,.55+.45*(u-.7)/.3)or .8
    end},
    downFeather={life=1.6,build=function(e,parent,style)
        e.parts={piece(parent,'SeraphDown',Vector3.one,rgb(style.secondary),true,true),piece(parent,'SeraphDownCore',Vector3.one,white,true,true)}
    end,pose=function(e,o,u,t,k)
        local h=e.seed;local a=u*5+h*6;local r=(.18+.25*u)*k
        local pos=Vector3.new(.25*k+math.cos(a)*r*.5,(.08+.5*math.sin(math.pi*u))*k,math.sin(a)*r)
        local cf=o*CFrame.new(pos)*CFrame.Angles(0,a,math.sin(t*4+h)*.4);local s=k*(1-.4*u)
        e.parts[1].Size=Vector3.new(.08,.02,.22)*s;e.parts[1].CFrame=cf;e.parts[1].Transparency=.1+.9*u^1.5
        e.parts[2].Size=Vector3.new(.03,.025,.14)*s;e.parts[2].CFrame=cf;e.parts[2].Transparency=.05+.95*u^1.3
    end},
    haloRing={life=1.5,build=function(e,parent)
        e.parts={};for i=1,8 do e.parts[i]=piece(parent,'SeraphHaloRing',Vector3.one,halo(i),true)end
    end,pose=function(e,o,u,t,k)
        local r=(.2+.55*out(u*1.6))*k;local fade=u<.4 and .1 or .1+.9*((u-.4)/.6)^1.2
        ring(e.parts,o*CFrame.new(0,.03*k,0),r,t*.8+e.seed,.05*k,.025*k)
        for i,p in ipairs(e.parts)do p.Color=halo(i/8*math.pi*2+t*2+e.seed);p.Transparency=fade end
    end},
    pixelGhost={life=.9,build=function(e,parent,style)
        e.cy,e.mg=rgb(style.secondary),rgb(style.accent);e.parts={}
        for i=1,6 do e.parts[i]=piece(parent,'GlitchPixel',Vector3.one,e.cy,true)end
    end,pose=function(e,o,u,t,k)
        local ph=e.ph or 1;local g=math.floor(t*12);local s=e.seed;local chance=({.86,.55,.25})[ph]
        local root=o*CFrame.new(0,0,e.side*.18*k)
        for i,p in ipairs(e.parts)do local b=ghostBlocks[i];local hit=hash(s+g*1.3+i*.7)>chance
            local off=hit and Vector3.new(0,(hash(s+g+i)-.5)*ph*.06,math.round((hash(s+g*2.1+i)-.5)*ph*2)*.08)*k or Vector3.zero
            p.Size=b[2]*k;p.CFrame=root*CFrame.new(b[1]*k+off);p.Color=hit and e.mg or e.cy
            p.Transparency=math.min(1,.25+.7*u+(hit and ph>=3 and .2 or 0))
        end
    end},
    pixelChunk={life=1,build=function(e,parent,style)
        local c={rgb(style.secondary),rgb(style.accent),rgb(style.secondary):Lerp(white,.4)};e.parts={}
        for i=1,3 do e.parts[i]=piece(parent,'GlitchChunk',Vector3.one,c[i],true)end
    end,pose=function(e,o,u,t,k)
        local q=.1*k;local step=math.floor(u*6)/6;local ph=e.ph or 2
        for i,p in ipairs(e.parts)do local h=e.seed+i*3.1
            local dz=math.round(e.side*(.15+.5*hash(h))*(.3+step)*k/q)*q;local dx=math.round((.1+.5*hash(h+1)*step)*k/q)*q
            local sz=(.08+.08*hash(h+2))*k*(ph>=3 and 1.3 or 1)
            p.Size=Vector3.new(sz,.02*k,sz);p.CFrame=o*CFrame.new(dx,(.02+.04*i)*k,dz)
            p.Transparency=math.min(1,(hash(h+math.floor(t*14))>.8 and .7 or .08)+.9*u^2)
        end
    end},
    codeLine={life=1.1,build=function(e,parent,style)
        e.parts={piece(parent,'GlitchCode',Vector3.one,rgb(style.secondary),true),piece(parent,'GlitchCursor',Vector3.one,rgb(style.accent),true)}
    end,pose=function(e,o,u,t,k)
        local h=e.seed;local n=math.floor(math.min(1,u*3)*6+.5)/6;local len=(.15+.35*hash(h))*k*n+.01
        local z=e.side*(.32+.18*hash(h+1))*k;local x=(.15+.9*u)*k;local a,b=e.parts[1],e.parts[2]
        a.Size=Vector3.new(len,.02*k,.05*k);a.CFrame=o*CFrame.new(x+len/2,.03*k,z)
        b.Size=Vector3.new(.06,.03,.06)*k;b.CFrame=o*CFrame.new(x+len+.04*k,.035*k,z)
        a.Transparency=.1+.85*u^1.5;b.Transparency=math.floor(t*6+h)%2==0 and .05+.9*u or 1
    end},
    ripple={life=1.8,build=function(e,parent,style)
        e.style=style;e.parts={};for i=1,8 do e.parts[i]=piece(parent,'AbyssRipple',Vector3.one,rgb(style.secondary),true)end
    end,pose=function(e,o,u,t,k)
        local ph=e.ph or 1;local r=(.12+(.42+.12*ph)*out(u))*k;local c=o*CFrame.new(0,.02*k,0)
        local col=rgb(e.style.secondary):Lerp(rgb(e.style.accent),u);local fade=.08+.92*u^1.3;local n=#e.parts
        local function at(a)local w=r*(1+.08*math.sin(a*3+t*3));return Vector3.new(math.cos(a)*w,0,math.sin(a)*w)end
        for i,p in ipairs(e.parts)do local a0,a1=(i-1)/n*math.pi*2+e.seed,i/n*math.pi*2+e.seed
            seg(p,c,at(a0),at(a1),.045*k*(1-.4*u),.02*k);p.Color=col;p.Transparency=fade
        end
    end},
    spore={life=1.2,build=function(e,parent,style)
        e.parts={piece(parent,'AbyssSpore',Vector3.one,rgb(style.secondary),true,true),piece(parent,'AbyssSporeHalo',Vector3.one,rgb(style.accent),true,true)}
    end,pose=function(e,o,u,t,k)
        local h=e.seed;local pulse=.7+.3*math.sin(t*6+h*4)
        local pos=Vector3.new((.1+.3*u)*k,(.04+.55*math.sin(math.pi*u)*(.5+.5*hash(h)))*k,(e.side*(.15+.35*hash(h+1))+math.sin(t*3+h*5)*.05)*k)
        local a,b=e.parts[1],e.parts[2]
        a.Size=Vector3.one*.06*k*pulse;a.CFrame=o*CFrame.new(pos);a.Transparency=.05+.9*u^1.5
        b.Size=Vector3.one*.16*k*pulse;b.CFrame=a.CFrame;b.Transparency=.6+.4*u
    end},
}
function V.dragon(parent,style)
    local dark,pale,gold=rgb(style.primary),rgb(style.secondary),rgb(style.accent);local jade=dark:Lerp(pale,.35)
    local d={segs={},style=style}
    for i=1,10 do
        local plate=piece(parent,'DragonBody',Vector3.one,jade:Lerp(dark,i%2*.35),false);plate.Reflectance=.12
        d.segs[i]={plate=plate,scale=piece(parent,'DragonScale',Vector3.one,pale,true),spine=piece(parent,'DragonSpine',Vector3.one,gold,true)}
    end
    d.skull=piece(parent,'DragonHead',Vector3.one,jade,false);d.snout=piece(parent,'DragonSnout',Vector3.one,jade:Lerp(pale,.3),false)
    d.horns={piece(parent,'DragonHorn',Vector3.one,gold,true),piece(parent,'DragonHorn',Vector3.one,gold,true)}
    d.whiskers={piece(parent,'DragonWhisker',Vector3.one,gold,true),piece(parent,'DragonWhisker',Vector3.one,gold,true)}
    d.eyes={piece(parent,'DragonEye',Vector3.one,gold,true,true),piece(parent,'DragonEye',Vector3.one,gold,true,true)}
    d.fins={piece(parent,'DragonTailFin',Vector3.one,gold,true),piece(parent,'DragonTailFin',Vector3.one,gold,true)}
    d.claws={};for i=1,4 do d.claws[i]=piece(parent,'DragonClaw',Vector3.one,gold,true)end
    d.pearl=piece(parent,'DragonPearl',Vector3.one,Color3.fromRGB(255,240,200),true,true)
    return d
end
function V.dragonParts(d)
    local list={d.skull,d.snout,d.pearl}
    for _,s in ipairs(d.segs)do table.insert(list,s.plate);table.insert(list,s.scale);table.insert(list,s.spine)end
    for _,g in ipairs({d.horns,d.whiskers,d.eyes,d.fins,d.claws})do for _,p in ipairs(g)do table.insert(list,p)end end
    return list
end
function V.poseDragon(d,along,t,k,open)
    local hidden=open<.03;local n=#d.segs;local L=2.5*(.25+.75*open);local pale,gold=rgb(d.style.secondary),rgb(d.style.accent)
    local function at(f)
        local dist=.12+f*L;local side=across(along,dist)
        return along(dist)+side*math.sin(f*7-t*4)*(.06+.2*f)*k+Vector3.new(0,(.3-.14*f+.06*math.sin(f*9-t*5))*k,0),side
    end
    local p0=at(0)
    for i,s in ipairs(d.segs)do
        local p1=at(i/n);local fm=(i-.5)/n;local w=(.3-.2*fm)*k;local th=1-.5*fm;local fr=CFrame.lookAt((p0+p1)/2,p1)
        local glint=math.max(0,math.sin(fm*10-t*5))
        s.plate.Size=Vector3.new(w,.1*k*th,(p1-p0).Magnitude*1.1);s.plate.CFrame=fr;s.plate.Transparency=.35*fm^2
        s.scale.Size=Vector3.new(w*.55,.02*k,w*.55);s.scale.CFrame=fr*CFrame.new(0,.05*k*th,0)*CFrame.Angles(0,math.pi/4,0)
        s.scale.Color=pale:Lerp(white,.6*glint);s.scale.Transparency=.15+.35*(1-glint)
        s.spine.Size=Vector3.new(.03*k,.07*k*th,(p1-p0).Magnitude*.6);s.spine.CFrame=fr*CFrame.new(0,.08*k*th,0);s.spine.Color=gold:Lerp(white,.3*glint)
        s.spine.Transparency=0;p0=p1
    end
    local ph=at(0);local fwd=ph-at(.08);fwd=fwd.Magnitude>1e-4 and fwd.Unit or Vector3.xAxis
    local hf=CFrame.lookAt(ph,ph+fwd)
    d.skull.Size=Vector3.new(.28,.16,.3)*k;d.skull.CFrame=hf;d.skull.Transparency=0
    d.snout.Size=Vector3.new(.18,.1,.2)*k;d.snout.CFrame=hf*CFrame.new(0,-.02*k,-.22*k);d.snout.Transparency=0
    for j,sd in ipairs({-1,1})do
        seg(d.horns[j],hf,Vector3.new(sd*.08,.07,.05)*k,Vector3.new(sd*.14,.2,.27)*k,.035*k,.035*k);d.horns[j].Transparency=0
        local wv=math.sin(t*3+j*2)*.06
        seg(d.whiskers[j],hf,Vector3.new(sd*.08,-.03,-.3)*k,Vector3.new(sd*(.3+wv),-.02,-.12+wv)*k,.02*k,.02*k);d.whiskers[j].Transparency=.05
        d.eyes[j].Size=Vector3.one*.06*k;d.eyes[j].CFrame=hf*CFrame.new(sd*.11*k,.06*k,-.08*k);d.eyes[j].Transparency=0
    end
    d.pearl.Size=Vector3.one*.12*k*(1+.1*math.sin(t*6));d.pearl.CFrame=hf*CFrame.new(math.cos(t*2)*.25*k,.12*k,(-.4+math.sin(t*2)*.1)*k);d.pearl.Transparency=.05
    for j,f in ipairs({.22,.22,.55,.55})do local p,side=at(f);local sd=j%2==0 and 1 or -1;local w=(.3-.2*f)*k
        seg(d.claws[j],CFrame.identity,p+side*sd*w*.4,p+side*sd*(w*.4+.12*k)-Vector3.new(0,.12*k,0),.05*k,.05*k);d.claws[j].Transparency=0
    end
    local tip,side=at(1);local back=(tip-at(.95));back=back.Magnitude>1e-4 and back.Unit or Vector3.xAxis
    for j,sd in ipairs({-1,1})do seg(d.fins[j],CFrame.identity,tip,tip+back*.26*k+side*sd*.16*k+Vector3.new(0,.03*k,0),.1*k,.02*k);d.fins[j].Transparency=.1 end
    if hidden then hideAll(V.dragonParts(d),true)end
end
function V.jewel(parent,style)
    local g=piece(parent,'DiamondBrilliant',Vector3.one,rgb(style.secondary):Lerp(white,.5),false);g.Material=Enum.Material.Glass;g.Reflectance=.35
    local j={gem=g,top=piece(parent,'DiamondTable',Vector3.one,white,true),prongs={}}
    for i=1,4 do j.prongs[i]=piece(parent,'DiamondSetting',Vector3.one,rgb(style.accent),true)end
    return j
end
function V.jewelParts(j)return {j.gem,j.top,j.prongs[1],j.prongs[2],j.prongs[3],j.prongs[4]}end
function V.poseJewel(j,cf,t,k,show)
    local c=cf*CFrame.new(0,math.sin(t*2.2)*.04*k,0)*CFrame.Angles(0,t*1.6,0)
    j.gem.Size=Vector3.one*.22*k;j.gem.CFrame=c*CFrame.Angles(.785,0,.785);j.gem.Transparency=.1
    j.top.Size=Vector3.new(.12,.02,.12)*k*(1+.3*math.abs(math.sin(t*4.5)));j.top.CFrame=c*CFrame.new(0,.17*k,0)*CFrame.Angles(0,.785,0);j.top.Transparency=0
    for i,p in ipairs(j.prongs)do local a=i/4*math.pi*2
        seg(p,c,Vector3.new(math.cos(a),-.12,math.sin(a))*.17*k,Vector3.new(math.cos(a+math.pi/2),-.12,math.sin(a+math.pi/2))*.17*k,.03*k,.03*k);p.Transparency=0
    end
    hideAll(V.jewelParts(j),not show)
end
local wingSpec={{.92,.3,.6},{.74,.8,.52},{1.08,-.3,.48}}
function V.wings6(parent,style)
    local list={};local ivory,gold=rgb(style.primary),rgb(style.secondary)
    for pair=1,3 do for _,side in ipairs({-1,1})do
        local w={pair=pair,side=side,vanes={},core=piece(parent,'SeraphWingCore',Vector3.one,gold,true)}
        for f=1,3 do w.vanes[f]=piece(parent,'SeraphWing',Vector3.one,ivory,true)end
        table.insert(list,w)
    end end
    return {wings=list,style=style}
end
function V.wingParts(ws)local list={};for _,w in ipairs(ws.wings)do table.insert(list,w.core);for _,v in ipairs(w.vanes)do table.insert(list,v)end end;return list end
function V.poseWings6(ws,cf,t,k,open,phase)
    local ivory,gold=rgb(ws.style.primary),rgb(ws.style.secondary)
    for _,w in ipairs(ws.wings)do
        local sp=wingSpec[w.pair];local hidden=open<.03 or w.pair>phase
        local flap=math.sin(t*2.6-w.pair*.7)*.12*open;local a=Vector3.new(.1,sp[1],w.side*.12)*k;local L=sp[3]*(.3+.7*open)*k
        for f,v in ipairs(w.vanes)do
            local yaw=(sp[2]+(f-2)*.32)*(.4+.6*open)
            local dir=Vector3.new(math.sin(yaw),.18+flap+(f-2)*.05,w.side*math.cos(yaw)).Unit;local len=L*(1-.12*math.abs(f-2))
            seg(v,cf,a,a+dir*len,.15*k,.025*k);v.Color=ivory:Lerp(gold,.35*(.5+.5*math.sin(t*5-f-w.pair*2)))
            v.Transparency=hidden and 1 or f==2 and .1 or .3
            if f==2 then seg(w.core,cf,a+Vector3.new(0,.015*k,0),a+dir*len*.7+Vector3.new(0,.015*k,0),.04*k,.03*k);w.core.Transparency=hidden and 1 or 0 end
        end
    end
end
function V.halo(parent)
    local h={ring={},glow=piece(parent,'SeraphHaloGlow',Vector3.one,halo(0),true,true)}
    for i=1,8 do h.ring[i]=piece(parent,'SeraphHalo',Vector3.one,halo(i),true)end
    return h
end
function V.poseHalo(h,cf,t,k,show)
    local c=cf*CFrame.new(0,.03*k*math.sin(t*1.7),0);ring(h.ring,c,.2*k*(1+.05*math.sin(t*3)),t*.6,.05*k,.035*k)
    for i,p in ipairs(h.ring)do p.Color=halo(i*.8+t*2);p.Transparency=show and .02 or 1 end
    h.glow.Size=Vector3.new(.62,.02,.62)*k;h.glow.CFrame=c;h.glow.Transparency=show and .72 or 1
end
local wireEdges={}
for _,a in ipairs({-1,1})do for _,b in ipairs({-1,1})do
    table.insert(wireEdges,{Vector3.new(-1,a,b),Vector3.new(1,a,b)});table.insert(wireEdges,{Vector3.new(a,-1,b),Vector3.new(a,1,b)})
    table.insert(wireEdges,{Vector3.new(a,b,-1),Vector3.new(a,b,1)})
end end
function V.data(parent,style)
    local cy,mg=rgb(style.secondary),rgb(style.accent);local d={cy=cy,mg=mg,lanes={},edges={}}
    for lane=1,3 do d.lanes[lane]={};for i=1,6 do d.lanes[lane][i]=piece(parent,'GlitchLane',Vector3.one,cy,true)end end
    for i=1,12 do d.edges[i]=piece(parent,'GlitchWire',Vector3.one,i%2==0 and mg or cy,true)end
    return d
end
function V.dataParts(d)local list={};for _,l in ipairs(d.lanes)do for _,p in ipairs(l)do table.insert(list,p)end end;for _,p in ipairs(d.edges)do table.insert(list,p)end;return list end
function V.poseData(d,place,cube,t,k,open,phase)
    local g=math.floor(t*10);local hidden=open<.03
    for lane,list in ipairs(d.lanes)do local shown=not hidden and (lane==2 or lane==1 and phase>=2 or lane==3 and phase>=3)
        for i,p in ipairs(list)do local f=((i-1)/#list+t*.6+lane*.13)%1;local h=lane*7+i
            local len=(.1+.2*hash(h))*k;local jit=hash(h+g)>({.92,.75,.55})[phase]and math.round((hash(h*1.7+g)-.5)*2)*.08*k or 0
            p.Size=Vector3.new(len,.02*k,.06*k);p.CFrame=place((.2+1.8*f)*(.3+.7*open))*CFrame.new(0,.025*k,(lane-2)*.2*k+jit)
            p.Color=hash(h+math.floor(t*4))>.8 and d.mg or d.cy;p.Transparency=shown and .1+.8*f or 1
        end
    end
    local s=.2*k*(1+.08*math.sin(t*5));local c=cube*CFrame.Angles(t*.7,t*1.1,0)
    for i,p in ipairs(d.edges)do local e=wireEdges[i]
        local jit=hash(g+i*1.7)>.8 and Vector3.new(0,0,math.round((hash(g*1.3+i)-.5)*2)*.06*k)or Vector3.zero
        seg(p,c,e[1]*s+jit,e[2]*s+jit,.025*k,.025*k);p.Color=hash(g*.7+i)>.5 and d.cy or d.mg
        p.Transparency=(hidden or phase<3)and 1 or hash(g*2.1+i)>.9 and .7 or .05
    end
end
local tentSpec={{-1,.2,1.6},{1,.2,1.6},{-1,.42,1.25},{1,.42,1.25}}
function V.abyss(parent,style)
    local teal,violet,ink=rgb(style.secondary),rgb(style.accent),rgb(style.primary);local a={style=style,eyes={},pupils={},tentacles={}}
    for j=1,2 do a.eyes[j]=piece(parent,'AbyssEye',Vector3.one,violet:Lerp(teal,.3),true,true);a.pupils[j]=piece(parent,'AbyssPupil',Vector3.one,ink,false,true)end
    a.sclera=piece(parent,'AbyssGiantEye',Vector3.one,teal,true,true);a.iris=piece(parent,'AbyssIris',Vector3.one,violet,true,true)
    a.slit=piece(parent,'AbyssSlit',Vector3.one,ink,false,true);a.lids={piece(parent,'AbyssLid',Vector3.one,teal,true),piece(parent,'AbyssLid',Vector3.one,teal,true)}
    for j=1,4 do local tn={segs={},tip=piece(parent,'AbyssTentacleTip',Vector3.one,violet,true,true)}
        for i=1,6 do tn.segs[i]=piece(parent,'AbyssTentacle',Vector3.one,teal:Lerp(violet,(i-1)/5),true)end
        a.tentacles[j]=tn
    end
    return a
end
function V.abyssParts(a)
    local list={a.eyes[1],a.eyes[2],a.pupils[1],a.pupils[2],a.sclera,a.iris,a.slit,a.lids[1],a.lids[2]}
    for _,tn in ipairs(a.tentacles)do table.insert(list,tn.tip);for _,p in ipairs(tn.segs)do table.insert(list,p)end end
    return list
end
function V.poseAbyss(a,along,place,t,k,open,phase)
    local hidden=open<.03;local blink=(t%4.3)<.15 and .15 or 1
    for j,sd in ipairs({-1,1})do
        local cf=place(.55*(.4+.6*open))*CFrame.new(0,.02*k,sd*.13*k)
        a.eyes[j].Size=Vector3.new(.1*blink,.02,.17)*k;a.eyes[j].CFrame=cf;a.eyes[j].Transparency=hidden and 1 or .15
        a.pupils[j].Size=Vector3.new(.03*blink,.03,.07)*k;a.pupils[j].CFrame=cf*CFrame.new(-.01*k,.004*k,0);a.pupils[j].Transparency=hidden and 1 or 0
    end
    local big=not hidden and phase>=3;local cf=place(1.25*(.4+.6*open))*CFrame.new(0,.015*k,0);local look=math.sin(t*.9)*.05*k
    a.sclera.Size=Vector3.new(.5,.02,.85)*k;a.sclera.CFrame=cf;a.sclera.Transparency=big and .35 or 1
    a.iris.Size=Vector3.new(.32,.03,.32)*k*(1+.05*math.sin(t*2));a.iris.CFrame=cf*CFrame.new(-.05*k,.004*k,look);a.iris.Transparency=big and .05 or 1
    a.slit.Size=Vector3.new(.26,.035,.06)*k;a.slit.CFrame=cf*CFrame.new(-.05*k,.008*k,look);a.slit.Transparency=big and 0 or 1
    for j,sd in ipairs({-1,1})do local lid=a.lids[j];lid.Size=Vector3.new(.03,.03,.72)*k;lid.CFrame=cf*CFrame.new(sd*.24*k,.01*k,0);lid.Transparency=big and .1 or 1 end
    for j,tn in ipairs(a.tentacles)do local sp=tentSpec[j];local up=not hidden and phase>=(j<=2 and 2 or 3);local L=sp[3]*(.3+.7*open)
        local function at(f)
            local d=.25+f*L;local side=across(along,d);local curl=math.sin(f*6-t*3+j*1.3)*(.05+.18*f)
            return along(d)+side*(sp[1]*(sp[2]+.1*f)+curl)*k+Vector3.new(0,(.04+.3*math.sin(math.pi*math.min(1,f*1.15))*(.6+.4*math.sin(t*2+j)))*k,0)
        end
        local p0=at(0)
        for i,p in ipairs(tn.segs)do local p1=at(i/#tn.segs);local w=(.12-.08*(i-1)/#tn.segs)*k
            seg(p,CFrame.identity,p0,p1,w,w);p.Transparency=up and .1+.04*i or 1;p0=p1
        end
        tn.tip.Size=Vector3.one*.1*k*(1+.25*math.sin(t*5+j));tn.tip.CFrame=CFrame.new(p0);tn.tip.Transparency=up and .05 or 1
    end
end
local function light(state,parent,color,range)
    local l=Instance.new('PointLight');l.Color=color;l.Range=range or 3;l.Brightness=.7;l.Shadows=false;l.Parent=parent;state.light=l
end
local function phased(s,phase)for _,e in ipairs(s.elements)do e.ph=phase end end
V.display={
    dragontail=function(model,state,style,stream)
        state.dragon=V.dragon(model,style);stream('dragonGlint',8,1.8,.4,1);light(state,state.dragon.pearl,rgb(style.accent))
        state.vstep=function(s,base,t)V.poseDragon(s.dragon,function(d)return (base*T.path(.3+d)).Position end,t,1,1)end
    end,
    gemdust=function(model,state,style,stream,ribbon)
        ribbon(model,state,'GemPath',0,.02,.05,2,5,.2,.02,white,rgb(style.secondary),true,.45)
        state.jewel=V.jewel(model,style);stream('gem',8,1.6,.1,1.2);stream('glitter',6,1.8,.05,.9);light(state,state.jewel.top,rgb(style.secondary))
        state.vstep=function(s,base,t)V.poseJewel(s.jewel,base*CFrame.new(.32,1,0),t,1,true)end
    end,
    plume=function(model,state,style,stream,ribbon)
        ribbon(model,state,'PlumePath',0,.02,.05,2.2,5,.22,.02,rgb(style.primary),rgb(style.secondary),true,.4)
        state.wings6=V.wings6(model,style);state.halo=V.halo(model)
        stream('plumeFeather',8,1.8,.1,2);stream('downFeather',6,1.4,.1,1.6,2);stream('haloRing',2,1.6,.4,2.2,3)
        light(state,state.wings6.wings[1].core,rgb(style.secondary))
        state.vstep=function(s,base,t,phase)
            V.poseWings6(s.wings6,base,t,1,1,phase);V.poseHalo(s.halo,base*CFrame.new(0,1.32,0),t,1,phase>=3)
            s.light.Color=phase>=3 and halo(t) or rgb(s.style.secondary)
        end
    end,
    datastream=function(model,state,style,stream)
        state.data=V.data(model,style)
        stream('pixelGhost',4,1.8,.15,1.1);stream('pixelChunk',6,1.8,.1,1,2);stream('codeLine',6,1.6,.05,1.2,3)
        light(state,state.data.edges[1],rgb(style.secondary))
        state.vstep=function(s,base,t,phase)phased(s,phase)
            V.poseData(s.data,function(d)return base*T.path(.15+d)end,base*CFrame.new(.35,.78,0),t,1,1,phase)
        end
    end,
    biolume=function(model,state,style,stream,ribbon)
        ribbon(model,state,'AbyssPath',0,.01,.05,2.2,5,.3,.02,rgb(style.primary):Lerp(rgb(style.secondary),.25),rgb(style.accent),true,.5)
        state.abyss=V.abyss(model,style);stream('ripple',4,1.8,.2,1.8);stream('spore',6,1.8,.1,1.4)
        light(state,state.abyss.eyes[1],rgb(style.secondary),3.5)
        state.vstep=function(s,base,t,phase)phased(s,phase)
            V.poseAbyss(s.abyss,function(d)return (base*T.path(.2+d)).Position end,function(d)return base*T.path(.2+d)end,t,1,1,phase)
        end
    end,
}
V.specs={
    dragontail={pieces={{kind='dragonGlint',every=.1,life=.8,cap=8,at=.8}}},
    gemdust={pieces={{kind='gem',every=.13,life=1.1,cap=8},{kind='glitter',every=.08,life=.8,cap=6}}},
    plume={pieces={{kind='plumeFeather',every=.16,life=1.8,cap=8},{kind='downFeather',every=.2,life=1.3,cap=6,phase=2},{kind='haloRing',every=.75,life=1.4,cap=2,phase=3,at=.6}}},
    datastream={pieces={{kind='pixelGhost',every=.14,life=.6,cap=4},{kind='pixelChunk',every=.1,life=.7,cap=6,phase=2},{kind='codeLine',every=.09,life=.9,cap=6,phase=3}}},
    biolume={pieces={{kind='ripple',every=.32,life=1.3,cap=4},{kind='spore',every=.12,life=1.1,cap=6}}},
}
function V.attach(self,theme,trail,emitter,fx)
    local skin,k=self.style,self.k;local feet=-self.foot;local accent,trim,dark=rgb(skin.accent),rgb(skin.secondary),rgb(skin.primary)
    local s={attached={},gated={}};self.vol=s;self.volStep=V.step
    local function keep(list)for _,p in ipairs(list)do table.insert(self.spawned,p);table.insert(s.attached,p)end end
    local function ground(name,w,y,life,color,transparency,width)
        local t=trail(name,Vector3.new(-w,feet+y,.1*k),Vector3.new(w,feet+y,.1*k),life,color,transparency,width);t.FaceCamera=false;return t
    end
    if theme=='dragontail'then
        ground('DragonWake',.16*k,.05*k,.5,ColorSequence.new(trim,dark),.4,.3)
        emitter('DragonGlints',Vector3.new(0,feet+.3*k,.4*k),16,.9,.06*k,.5*k,ColorSequence.new(accent,trim))
        s.dragon=V.dragon(fx,skin);s.track=true;keep(V.dragonParts(s.dragon))
    elseif theme=='gemdust'then
        ground('GemDust',.12*k,.03*k,.55,ColorSequence.new(white,trim),.3,.3)
        emitter('GemSparkle',Vector3.new(0,feet+.8*k,.2*k),24,.8,.05*k,.5*k,ColorSequence.new(white,trim),Vector3.new(0,-1.5*k,0))
        s.jewel=V.jewel(fx,skin);keep(V.jewelParts(s.jewel))
    elseif theme=='plume'then
        ground('PlumeLight',.14*k,.03*k,.5,ColorSequence.new(dark,trim),.3,.4)
        table.insert(s.gated,{ground('PlumeVeil',.42*k,.02*k,.6,ColorSequence.new(halo(0),halo(math.pi)),.6,.6),3})
        emitter('PlumeSparkle',Vector3.new(0,feet+.9*k,.2*k),20,1.2,.06*k,.4*k,ColorSequence.new(white,trim),Vector3.new(0,-.4*k,0))
        s.wings6=V.wings6(fx,skin);s.halo=V.halo(fx);keep(V.wingParts(s.wings6));keep(s.halo.ring);keep({s.halo.glow})
        s.grow={.5,.9,1.4}
    elseif theme=='datastream'then
        ground('DataLine',.08*k,.03*k,.4,ColorSequence.new(trim,dark),.15,.5)
        local split=trail('DataSplit',Vector3.new(.14*k,feet+.03*k,.1*k),Vector3.new(.22*k,feet+.03*k,.1*k),.4,ColorSequence.new(accent,dark),.2,.5)
        split.FaceCamera=false;table.insert(s.gated,{split,2})
        emitter('DataSparks',Vector3.new(0,feet+.4*k,.2*k),18,.5,.06*k,1.5*k,ColorSequence.new(trim,accent),Vector3.new(0,-2*k,0))
        s.data=V.data(fx,skin);keep(V.dataParts(s.data));s.grow={.4,.75,1.2}
    elseif theme=='biolume'then
        ground('AbyssGlow',.2*k,.02*k,.6,ColorSequence.new(trim,dark),.35,.6)
        table.insert(s.gated,{ground('AbyssVeil',.5*k,.015*k,.7,ColorSequence.new(accent,dark),.65,.7),3})
        emitter('Biolume',Vector3.new(0,feet+.1*k,.3*k),16,1.4,.06*k,.3*k,ColorSequence.new(trim,accent),Vector3.new(0,.5*k,0))
        s.abyss=V.abyss(fx,skin);s.track=true;keep(V.abyssParts(s.abyss));s.grow={.6,1,1.5}
    end
end
local function track(s,cur,k)
    local h=s.hist
    if not h or (cur-h[1]).Magnitude>6*k then s.hist={cur};return end
    if (cur-h[1]).Magnitude>.2*k then table.insert(h,1,cur)end
    local total=0;for i=2,#h do total+=(h[i]-h[i-1]).Magnitude;if total>3.6*k then for j=#h,i+1,-1 do h[j]=nil end;break end end
end
local function walk(s,cur,back,d)
    local prev=cur
    for _,p in ipairs(s.hist or {})do local l=(p-prev).Magnitude
        if l>=d then return prev+(p-prev)*(d/l)end
        d-=l;prev=p
    end
    return prev+back*d
end
function V.step(self,body,now,moving,reduced,phase)
    local s=self.vol;local k=self.k;local open=self.open
    if not body and not s.folded then s.folded=true;s.hist=nil
        for _,p in ipairs(s.attached)do p.Transparency=1 end
    elseif body then s.folded=nil end
    for _,list in pairs(self.pool)do for _,e in ipairs(list)do e.ph=phase end end
    if s.grow then local life=reduced and .22 or s.grow[phase];for _,t in ipairs(self.trails)do t.Lifetime=life end end
    for _,g in ipairs(s.gated)do g[1].Enabled=moving and not reduced and phase>=g[2] end
    if not body then return end
    local cur,back=body.Position,body.XVector
    if s.track then track(s,cur,k)end
    local function along(d)return walk(s,cur,back,d*k)end
    local function place(d)return body*CFrame.new(d*k,0,0)end
    if s.dragon then V.poseDragon(s.dragon,along,now,k,open)end
    if s.jewel then V.poseJewel(s.jewel,body*CFrame.new(.32*k,1*k,0),now,k,open>.3)end
    if s.wings6 then V.poseWings6(s.wings6,body,now,k,open,phase);V.poseHalo(s.halo,body*CFrame.new(0,1.5*k,0),now,k,open>.3 and phase>=3)end
    if s.data then V.poseData(s.data,place,body*CFrame.new(.35*k,.78*k,0),now,k,open,phase)end
    if s.abyss then V.poseAbyss(s.abyss,along,place,now,k,open,phase)end
end
function V.install(themes)T=themes;for name,kind in pairs(V.kinds)do T.kinds[name]=kind end end
return V
