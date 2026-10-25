local G=require(script.Parent.Parent.Core.WorldGeometry)
local Pattern=require(script.Parent.TerritoryCollection)
local Authored=require(script.Parent.TerritoryPatterns)
local TweenService=game:GetService('TweenService')
local M={}
M.rate={[3]=2.2,[4]=3.2,[5]=7}
M.life={[3]=1.2,[4]=1.4,[5]=1.15}
M.sources={pulse_territory={4},venom_territory={1},tidal_territory={1},ember_territory={6},storm_territory={1},scale_territory={5},
    solaris_territory={2},crown_territory={3},phoenix_territory={7,8},filigree_territory={2,5},halloween_territory={2},dragon_territory={5},diamond_territory={6},
    parallax_territory={1,8},eclipse_territory={5,6,7},galaxy_territory={1,2,3,4,6,7},seraph_territory={2,4},glitch_territory={2,3},leviathan_territory={2,8}}
M.maxPerFrame=2
M.totalRate=16
M.texture='rbxasset://textures/particles/sparkles_main.dds'
M.looks={
    dragonscale={size=1.15,life=1.25,rate=1.15,border=true,drift=.5,colors=function(s)return s.secondary,s.accent end},
    facets={size=1.3,life=1.1,rate=1,sweep=true,colors=function()return Color3.fromRGB(236,246,255),Color3.fromRGB(170,215,255)end},
    plumes={size=1.25,life=1.5,rate=1,drift=.25,colors=function(s)return Color3.fromRGB(255,250,240),s.accent end},
    pixels={size=.9,life=.8,rate=.8,blocks=true,colors=function(s)return s.secondary,s.accent end},
    abyss={size=1.7,life=2,rate=.9,colors=function(s)return s.secondary,s.accent end},
    lanterns={size=1.2,life=.72,rate=1.6,flicker=true,bats=3,colors=function(s)return Color3.fromRGB(table.unpack(Authored.tones.gleam)),s.accent end},
}
M.sweep={period=5.5,duration=1.2,rate=34}
M.blocks={max=16,rate={5,9,14},life={.09,.22}}
M.bats={max=6,rate=.6,life=1.2,reach=2,span=3,depth=1.5,flap=.16}
local function steps(life)
    local levels={.05,.32,0,.4,.12,.36,.02,.24}
    local k={NumberSequenceKeypoint.new(0,1)};local dt=.1/life
    for i,v in ipairs(levels)do
        local t=math.min((i-1)*dt+.04,.97);if i>1 then table.insert(k,NumberSequenceKeypoint.new(t,levels[i-1]))end
        table.insert(k,NumberSequenceKeypoint.new(math.min(t+.004,.975),v))
    end
    table.insert(k,NumberSequenceKeypoint.new(1,1));return NumberSequence.new(k)
end
local WHITE=Color3.new(1,1,1)
local function rgb(a,f)return a and Color3.fromRGB(a[1],a[2],a[3])or f end
function M.new(folder)
    local anchor=Instance.new('Part');anchor.Name='TerritoryGlints';anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false
    anchor.CanTouch=false;anchor.CastShadow=false;anchor.Transparency=1;anchor.Size=Vector3.one*.1;anchor.Parent=folder
    return {anchor=anchor,emitters={},owners={},debt={},box=nil,boxAge=1,scale=1,rng=Random.new(1018),clock=0,sweepDebt=0,blockDebt={},blocks={},nextBlock=1,
        batDebt={},bats={},nextBat=1}
end
local function emitter(g,id,s)
    local e=g.emitters[id]
    if e and e.key==s.key then return e end
    if e then e.att:Destroy()end
    local att=Instance.new('Attachment');att.Name='Glint'..tostring(id);att.Parent=g.anchor
    local p=Instance.new('ParticleEmitter');p.Texture=M.texture;p.Rate=0;p.LightEmission=1;p.LightInfluence=0;p.Brightness=s.tier>=5 and 3 or s.tier>=4 and 2.2 or 1.8
    local look=s.look;local life=M.life[s.tier]*(look and look.life or 1)
    p.Lifetime=NumberRange.new(life*.85,life*1.15);p.Speed=NumberRange.new(0,look and look.drift or 0);p.SpreadAngle=Vector2.new(180,0);p.LockedToPart=false
    p.Orientation=Enum.ParticleOrientation.FacingCamera;p.Rotation=NumberRange.new(0,360);p.RotSpeed=NumberRange.new(-40,40)
    p.ZOffset=.5;p.Shape=Enum.ParticleEmitterShape.Box;p.EmissionDirection=Enum.NormalId.Top
    p.Transparency=look and look.flicker and steps(life)or NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.05),NumberSequenceKeypoint.new(.7,.25),NumberSequenceKeypoint.new(1,1)})
    if look and look.flicker then p.RotSpeed=NumberRange.new(0,0)end
    if look then local a,b=look.colors(s);p.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,a),ColorSequenceKeypoint.new(.5,a:Lerp(b,.5):Lerp(WHITE,.3)),ColorSequenceKeypoint.new(1,b)})
    elseif s.tier>=5 then
        p.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,s.secondary),ColorSequenceKeypoint.new(.45,s.accent:Lerp(WHITE,.4)),ColorSequenceKeypoint.new(1,s.accent)})
    else p.Color=ColorSequence.new(s.accent:Lerp(WHITE,.3),s.accent)end
    p.Parent=att
    e={att=att,p=p,key=s.key,size=0};g.emitters[id]=e;return e
end
local function size(e,s,scale)
    local peak=(s.tier>=5 and 1.9 or s.tier>=4 and 1.35 or 1.1)*scale*(s.look and s.look.size or 1)
    if math.abs(peak-e.size)<.08*peak then return end
    e.size=peak
    e.p.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,peak*.25),NumberSequenceKeypoint.new(.35,peak),NumberSequenceKeypoint.new(1,peak*.3)})
end
M.maxOwners=10
function M.setOwners(g,styles)
    local n=0;for _ in pairs(styles)do n+=1 end
    if n>M.maxOwners then
        local list={};for id,s in pairs(styles)do table.insert(list,{id=id,s=s})end
        table.sort(list,function(a,b)if a.s.tier~=b.s.tier then return a.s.tier>b.s.tier end;if (a.s.share or 0)~=(b.s.share or 0)then return (a.s.share or 0)>(b.s.share or 0)end;return tostring(a.id)<tostring(b.id)end)
        styles={};for i=1,M.maxOwners do styles[list[i].id]=list[i].s end
    end
    g.owners=styles
    for id,e in pairs(g.emitters)do if not styles[id]then e.att:Destroy();g.emitters[id]=nil;g.debt[id]=nil end end
    for id,s in pairs(styles)do emitter(g,id,s)end
end
local function viewBox(camera,width,height)
    local vp=camera.ViewportSize;local half=Vector2.new(width,height)*G.scale/2
    local minX,minZ,maxX,maxZ=math.huge,math.huge,-math.huge,-math.huge
    for _,f in ipairs({{0,0},{1,0},{0,1},{1,1},{.5,.5}})do
        local ray=camera:ViewportPointToRay(vp.X*f[1],vp.Y*f[2])
        local dy=ray.Direction.Y;local hit
        if dy<-1e-3 then hit=ray.Origin+ray.Direction*((G.surfaceY-ray.Origin.Y)/dy)
        else hit=ray.Origin+Vector3.new(ray.Direction.X,0,ray.Direction.Z).Unit*1e4 end
        minX=math.min(minX,hit.X);maxX=math.max(maxX,hit.X);minZ=math.min(minZ,hit.Z);maxZ=math.max(maxZ,hit.Z)
    end
    minX=math.max(minX,-half.X);maxX=math.min(maxX,half.X);minZ=math.max(minZ,-half.Y);maxZ=math.min(maxZ,half.Y)
    if minX>=maxX or minZ>=maxZ then return nil end
    return {x=minX,z=minZ,w=maxX-minX,h=maxZ-minZ}
end
local function pick(g,box,width,height,owners,id,border,src)
    local fallback
    for _=1,5 do
        local x=box.x+g.rng:NextNumber()*box.w;local z=box.z+g.rng:NextNumber()*box.h
        local tile=G.toTile(x,z,width,height)
        if tile and src and not border then
            local o=src[g.rng:NextInteger(1,#src)];local tx,ty=tile%width,tile//width
            tx=tx-tx%src.w+o%src.w;ty=ty-ty%src.h+o//src.w
            tile=tx<width and ty<height and ty*width+tx or nil
        end
        if tile and owners[tile]==id then
            if not border then return tile end
            fallback=fallback or tile
            if owners[tile+1]~=id or owners[tile-1]~=id or owners[tile+width]~=id or owners[tile-width]~=id then return tile end
        end
    end
    return fallback
end
local function emitAt(g,id,s,tile,width,height)
    local e=emitter(g,id,s);size(e,s,g.scale)
    local wx,wy,wz=G.toWorld(tile,width,height)
    e.att.WorldPosition=Vector3.new(wx,wy+.12,wz);e.p:Emit(1)
end
local function block(g)
    local b=g.blocks[g.nextBlock]
    if not b then
        local p=Instance.new('Part');p.Name='GlitchBlock';p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
        p.Material=Enum.Material.Neon;p.Transparency=1;p.Size=Vector3.new(1,.02,1);p.Parent=g.anchor
        b={p=p,left=0};g.blocks[g.nextBlock]=b
    end
    g.nextBlock=g.nextBlock%M.blocks.max+1;return b
end
local function flicker(g,s,tile,width,height)
    local tx,ty=tile%width,tile//width;local n=4*math.clamp(s.phase or 1,1,3)
    local w,h=n*(g.rng:NextNumber()<.5 and 1 or 2),n
    local x0,y0=tx-tx%4,ty-ty%4
    local wx,wy,wz=G.toWorld(y0*width+x0,width,height);local t=G.scale
    for k,c in ipairs({s.secondary,s.accent})do
        local b=block(g);b.left=M.blocks.life[1]+g.rng:NextNumber()*(M.blocks.life[2]-M.blocks.life[1])
        b.p.Color=c;b.p.Size=Vector3.new(w*t,.02,h*t);b.p.Transparency=k==1 and .15 or .35
        b.p.CFrame=CFrame.new(wx+(w/2-.5+(k-1))*t,wy+.1+k*.01,wz+(h/2-.5)*t)
    end
end
local function bat(g,s,tile,width,height)
    local b=g.bats[g.nextBat]
    if b and b.until_>g.clock then return end
    if not b then
        local m=Instance.new('Model');m.Name='LanternBat';b={m=m,wings={}}
        for side=-1,1,2 do
            local w=Instance.new('Part');w.Name=side<0 and 'L'or 'R';w.Anchored=true;w.CanCollide=false;w.CanQuery=false;w.CanTouch=false;w.CastShadow=false
            w.Material=Enum.Material.SmoothPlastic;w.Transparency=1;w.Parent=m;table.insert(b.wings,{p=w,side=side})
        end
        m.Parent=g.anchor;g.bats[g.nextBat]=b
    end
    g.nextBat=g.nextBat%M.bats.max+1
    for _,t in ipairs(b.tweens or {})do t:Cancel()end
    local t=G.scale;local B=M.bats;local wx,wy,wz=G.toWorld(tile,width,height)
    local yaw=g.rng:NextNumber()*math.pi*2;local dir=Vector3.new(math.sin(yaw),0,math.cos(yaw))
    local span,depth=B.span*t*g.scale*.6,B.depth*t*g.scale*.6
    local tweens={}
    for _,w in ipairs(b.wings)do
        local root=CFrame.new(wx,wy+.11,wz)*CFrame.Angles(0,yaw,0)
        local cf=root*CFrame.new(w.side*span/4,0,depth/4)*CFrame.Angles(0,w.side*.38,0)
        w.p.Color=s.base;w.p.Size=Vector3.new(span/2,.02,depth/2);w.p.CFrame=cf;w.p.Transparency=.25
        local fly=TweenInfo.new(B.life,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
        table.insert(tweens,TweenService:Create(w.p,fly,{CFrame=cf+dir*B.reach*t,Transparency=1}))
        local flap=TweenInfo.new(B.flap,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true)
        table.insert(tweens,TweenService:Create(w.p,flap,{Size=Vector3.new(span/5,.02,depth/2)}))
    end
    for _,tw in ipairs(tweens)do tw:Play()end
    b.tweens=tweens;b.until_=g.clock+B.life
end
local function stopBats(g)
    for _,b in ipairs(g.bats)do for _,t in ipairs(b.tweens or {})do t:Cancel()end;b.tweens=nil;b.until_=0;for _,w in ipairs(b.wings)do w.p.Transparency=1 end end
end
function M.step(g,dt,camera,width,height,owners,reduced)
    if reduced then for _,b in ipairs(g.blocks)do if b.left>0 then b.left=0;b.p.Transparency=1 end end;stopBats(g)end
    for _,b in ipairs(g.bats)do if b.tweens and b.until_<=g.clock then for _,t in ipairs(b.tweens)do t:Cancel()end;b.tweens=nil;for _,w in ipairs(b.wings)do w.p.Transparency=1 end end end
    for _,b in ipairs(g.blocks)do if b.left>0 then b.left-=dt;if b.left<=0 then b.p.Transparency=1 end end end
    if reduced or not next(g.owners)or not camera then return end
    g.boxAge+=dt;g.clock+=dt
    if g.boxAge>=.25 then
        g.boxAge=0;g.box=viewBox(camera,width,height)
        local focus=camera.Focus.Position;g.scale=math.clamp((camera.CFrame.Position-focus).Magnitude/34,.7,3)
    end
    local box=g.box;if not box then return end
    local emitted=0
    local function base(s)return ((M.rate[s.tier]or 0)+(s.tier>=5 and 3*((s.phase or 1)-1)or 0))*(s.look and s.look.rate or 1)end
    local sums={0,0,0,0,0};for _,s in pairs(g.owners)do sums[s.tier]=(sums[s.tier]or 0)+base(s)end
    local left,shares=M.totalRate,{};local far=math.clamp(2.2/g.scale,.35,1)
    for tier=5,3,-1 do local want=sums[tier]or 0;shares[tier]=want>0 and math.min(1,left/want)*far or 0;left=math.max(0,left-want)end
    local u=(g.clock%M.sweep.period)/M.sweep.duration
    local sweeping=u<1;if sweeping then g.sweepDebt=math.min(g.sweepDebt+M.sweep.rate*dt,2)end
    for id,s in pairs(g.owners)do
        local look=s.look
        local debt=math.min((g.debt[id]or 0)+base(s)*(shares[s.tier]or 0)*dt,2);g.debt[id]=debt
        while debt>=1 and emitted<M.maxPerFrame do
            debt-=1;emitted+=1
            local tile=pick(g,box,width,height,owners,id,look and look.border,s.sources)
            if tile then emitAt(g,id,s,tile,width,height)end
        end
        g.debt[id]=debt
        if look and look.sweep and sweeping then
            while g.sweepDebt>=1 do
                g.sweepDebt-=1
                local a=g.rng:NextNumber();local k=math.clamp(2*u-a,0,1)
                local tile=G.toTile(box.x+a*box.w,box.z+k*box.h,width,height)
                if tile and owners[tile]==id then emitAt(g,id,s,tile,width,height)end
            end
        elseif look and look.blocks then
            local rate=M.blocks.rate[math.clamp(s.phase or 1,1,3)]*math.clamp(2.2/g.scale,.5,1)
            local bd=math.min((g.blockDebt[id]or 0)+rate*dt,2)
            while bd>=1 do bd-=1;local tile=pick(g,box,width,height,owners,id);if tile then flicker(g,s,tile,width,height)end end
            g.blockDebt[id]=bd
        end
        if look and look.bats and s.batSources then
            local bd=math.min((g.batDebt[id]or 0)+M.bats.rate*math.clamp(2.2/g.scale,.4,1)*dt,1.5)
            while bd>=1 do bd-=1;local tile=pick(g,box,width,height,owners,id,false,s.batSources);if tile then bat(g,s,tile,width,height)end end
            g.batDebt[id]=bd
        end
    end
end
local sourceCache={}
local function sources(style,want,key)
    local id=key or style.id;local cached=sourceCache[id];if cached~=nil then return cached or nil end
    want=want or M.sources[style.id];local spec=want and Pattern.spec(style,1);local list=false
    if spec then
        local set={};for _,c in ipairs(want)do set[c]=true end
        list={w=spec.w,h=spec.h}
        for i=0,spec.w*spec.h-1 do if set[buffer.readu8(spec.buf,i)]then table.insert(list,i)end end
        if #list==0 then list=false end
    end
    sourceCache[id]=list;return list or nil
end
function M.styleFor(style,phase,share)
    local s={tier=style.tier or 0,accent=rgb(style.accent,Color3.fromRGB(255,207,91)),secondary=rgb(style.secondary,WHITE),phase=phase,share=share,look=M.looks[style.motif],sources=sources(style)}
    if s.look and s.look.bats then s.base=rgb(style.primary,Color3.fromRGB(20,14,30));s.batSources=sources(style,{s.look.bats},tostring(style.id)..':bats')end
    s.key=tostring(style.id)..':'..s.tier;return s
end
function M.destroy(g)stopBats(g);if g.anchor then g.anchor:Destroy()end;g.emitters={};g.owners={};g.blocks={};g.bats={}end
return M
