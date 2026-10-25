local Manifest=require(script.Parent.CosmeticMeshManifest)
local M={state={},diagnostics={},enabled=true}
local templates={};local waiting={};local watchers={};local rigs={}
local LIMIT=4;local active=0;local queue={}
local RETRIES=3;local BACKOFF={15,60,180};local fails={}
local Assets=(function()local ok,s=pcall(function()return game:GetService('AssetService')end);return ok and s or nil end)()
local MAT=Enum.Material
local V3,CF,ANG=Vector3.new,CFrame.new,CFrame.Angles
local rad=math.rad
local function rgb(a)return Color3.fromRGB(table.unpack(a))end
local function prism(h)local f=h%1;return Color3.fromHSV(.5+.28*(1-math.abs(2*f-1)),.62,.95)end
M.prism=prism

local function create(meshId)
    if not Assets then return nil end
    local opts={CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Automatic}
    local ok,p=false,nil
    if Content and Content.fromUri then ok,p=pcall(function()return Assets:CreateMeshPartAsync(Content.fromUri(meshId),opts)end)end
    if not ok or not p then ok,p=pcall(function()return Assets:CreateMeshPartAsync(meshId,opts)end)end
    if not ok or typeof(p)~='Instance'then return nil,tostring(p)end
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=true
    return p
end
local function settle(key)
    local item=Manifest[key];local failed=false
    for _,d in ipairs(item.parts)do local t=templates[d.meshId];if t==nil then return end;if t==false then failed=true end end
    M.state[key]=failed and 'failed'or 'ready'
    local list=watchers[key];watchers[key]=nil
    if not failed and list then for _,fn in ipairs(list)do local ok,err=pcall(fn);if not ok then M.diagnostics[key]=tostring(err)end end end
end
local function pump()
    while active<LIMIT and #queue>0 do
        local id=table.remove(queue,1);active+=1
        task.spawn(function()
            local p,err=create(id)
            templates[id]=p or false;if err then M.diagnostics[id]=err end
            if p then fails[id]=nil else local f=fails[id]or {n=0};f.n+=1;f.at=os.clock();fails[id]=f end
            active-=1
            local keys=waiting[id];waiting[id]=nil
            if keys then for key in pairs(keys)do settle(key)end end
            pump()
        end)
    end
end
function M.has(key)return M.enabled and Manifest[key]~=nil end
local function retry(key,now)
    local again,pending={},false
    for _,d in ipairs(Manifest[key].parts)do local id=d.meshId;if templates[id]==nil then pending=true end
        if templates[id]==false then local f=fails[id]
            if not f or f.n>RETRIES or now-f.at<BACKOFF[f.n]then return false end
            again[id]=true end end
    if not next(again)and not pending then return false end
    for id in pairs(again)do templates[id]=nil end
    M.state[key]=nil;return true
end
function M.request(key)
    if not M.has(key)then return nil end
    local s=M.state[key];if s=='failed'and Assets then retry(key,os.clock());s=M.state[key]end;if s then return s end
    if not Assets then M.state[key]='failed';return 'failed'end
    M.state[key]='loading'
    for _,d in ipairs(Manifest[key].parts)do
        local id=d.meshId
        if templates[id]==nil then
            if not waiting[id]then waiting[id]={};table.insert(queue,id)end
            waiting[id][key]=true
        end
    end
    settle(key);pump()
    return M.state[key]
end
function M.ready(key)return M.has(key)and M.request(key)=='ready'end
function M.watch(key,fn)
    local s=M.request(key);if s~='loading'then return false end
    watchers[key]=watchers[key]or {};table.insert(watchers[key],fn);return true
end
function M.watchModel(key,model,fn)
    local dead=false;pcall(function()model.Destroying:Once(function()dead=true end)end)
    return M.watch(key,function()if not dead then fn(model)end end)
end
function M.prefetch(styleId)
    if type(styleId)~='string'then return end
    if Manifest[styleId]then M.request(styleId)end
    if styleId:match('_buildings$')then for _,role in ipairs({'City','DefensePost','Port','Factory','MissileSilo','SAMLauncher'})do M.request(styleId..'/'..role)end end
end
function M.prefetchStandard(id)if type(id)=='string'then for _,k in ipairs(M.standardKeys(id))do M.request(k)end end end

local function home(d)return CF(d.pos[1],d.pos[2],d.pos[3])*ANG(rad(d.rot[1]),rad(d.rot[2]),rad(d.rot[3]))end
local function thinAxis(d,cf)
    local s=d.size;local a=s[1]<=s[2]and s[1]<=s[3]and Vector3.xAxis or s[2]<=s[3]and Vector3.yAxis or Vector3.zAxis
    return cf.Rotation*a
end
local function legId(name)
    local id=name:gsub('^Leg','');for _,w in ipairs({'Thigh','Shin','Light','Knee','Foot'})do local s=id:gsub('^'..w,'');if s~=id then return s end end
    return id
end
function M.rig(key)
    local r=rigs[key];if r then return r end
    local item=Manifest[key];r={parts={},legs={}};rigs[key]=r
    local turret
    for _,d in ipairs(item.parts)do if d.name=='Turret'and d.pivot then turret=(home(d)*CF(d.pivot[1],d.pivot[2],d.pivot[3])).Position end end
    local groups={}
    for i,d in ipairs(item.parts)do
        local cf=home(d);local e={def=d,home=cf,index=i}
        local hinge=d.pivot and(cf*CF(d.pivot[1],d.pivot[2],d.pivot[3])).Position
        local n=d.name;e.side=d.pos[1]<-.01 and -1 or d.pos[1]>.01 and 1 or 0
        if turret and hinge and(hinge-turret).Magnitude<.08 then e.kind='turret';e.hinge=turret
        elseif n:match('^Leg')then e.kind='leg';e.leg=legId(n);e.hinge=hinge
            local g=groups[e.leg]or {parts={}};groups[e.leg]=g;table.insert(g.parts,e)
            if hinge and(not g.hip or hinge.Y>g.hip.Y)then g.hip=hinge end
        elseif hinge then
            e.hinge=hinge
            if n:match('^Ring')then e.kind='ring';e.axis=thinAxis(d,cf)
            elseif n:match('^Wing')then e.kind='wing'
            elseif n:match('^Wheel')then e.kind='wheel';e.axis=thinAxis(d,cf);e.radius=math.max(d.size[1],d.size[2],d.size[3])/2
            elseif n:match('^Hatch')then e.kind='hatch'
            elseif n:match('^Head')then e.kind='head'
            elseif n:match('^Tassel')or n:match('^Pennant')or n:match('^Tentacle')or n:match('^Ribbon')or n:match('^Tail')and not n:match('^TailSeg')or n=='LightWall'then e.kind='sway'
            elseif n:match('^Seg%d')or n:match('^TailSeg')then e.kind='wave';e.seg=tonumber(n:match('%d+'))or 1
            elseif n:match('^HoverRing')or n:match('^Halo')or n:match('^Orbit')then e.kind='ring';e.axis=thinAxis(d,cf)
            elseif n:match('^PixelShift')or n:match('^Shard')then e.kind='glitch'end
        end
        table.insert(r.parts,e)
    end
    local tripod=false;for id in pairs(groups)do if id:match('^M')then tripod=true end end
    for id,g in pairs(groups)do
        local fb,lr,n=id:match('^([FMB])([LR])(%d*)$')
        local a=fb and(tripod and((fb=='M')==(lr=='L'))or(not tripod and((fb=='F')==(lr=='L'))))
        g.offset=(a and 0 or math.pi)+(tonumber(n)or 0)*.9
        for _,e in ipairs(g.parts)do e.hip=g.hip or e.hinge or e.home.Position;e.offset=g.offset end
        r.legs[id]=g
    end
    return r
end
local function about(h,axis,a)return CF(h)*CFrame.fromAxisAngle(axis,a)*CF(-h)end
function M.motion(e,t,speed,rate,clock)
    local k=e.kind;if not k then return nil end
    rate=rate or 1;speed=speed or 0
    if k=='ring'then return about(e.hinge,e.axis,t*.9*rate*(e.spin or 1)*(e.index%2==0 and -1 or 1))
    elseif k=='turret'then return about(e.hinge,Vector3.yAxis,math.sin(t*.35)*.9)
    elseif k=='wing'then return about(e.hinge,Vector3.zAxis,-e.side*math.sin(t*1.7)*.13)
    elseif k=='wheel'then return about(e.hinge,e.axis,-(clock and clock.wheel or t*math.max(speed,.6))/e.radius)
    elseif k=='hatch'then
        local c=(t/8)%1;local o=c<.12 and c/.12 or c<.5 and 1 or c<.62 and 1-(c-.5)/.12 or 0;o=o*o*(3-2*o)
        return about(e.hinge,Vector3.zAxis,-e.side*o*1.15)
    elseif k=='head'then return about(e.hinge,Vector3.xAxis,math.sin(t*1.3)*.09)
    elseif k=='sway'then return about(e.hinge,Vector3.xAxis,math.sin(t*2.1)*.12)
    elseif k=='wave'then return CF(0,math.sin(t*2.4-(e.seg or 1)*.35)*.07,0)
    elseif k=='glitch'then
        local n=math.floor(t*10)+e.index*7;if n%9~=0 then return CFrame.identity end
        return CF(((n//9)%2==0 and .08 or -.08),0,((n//18)%2==0 and .05 or -.05))
    elseif k=='leg'then
        local stride=math.clamp(speed/10,0,1)
        return about(e.hip,Vector3.xAxis,math.sin((clock and clock.leg or t*(5+stride*3))+e.offset)*(.04+.36*stride))
    end
end

function M.build(parent,key,opts)
    if not M.ready(key)then return nil end
    opts=opts or {};local origin=opts.origin or CFrame.identity;local s=opts.scale or 1;local colors=opts.colors or {}
    local out={}
    for _,e in ipairs(M.rig(key).parts)do
        local d=e.def
        if opts.keep and not opts.keep(e)then continue end
        local t=templates[d.meshId];local p=t:Clone()
        local k=1;local cf=e.home;local hb=opts.heroBase
        local wide=opts.groundCap and d.name:sub(-3)=='Top'and d.size[2]<=.1 and d.pos[2]<.2 and math.max(d.size[1],d.size[3])
        local gk=wide and wide>opts.groundCap and opts.groundCap/wide or 1
        if gk<1 then cf=CF(cf.Position*V3(gk,1,gk))*cf.Rotation end
        if hb and opts.heroScale and d.pos[2]-d.size[2]/2>hb.Y-.05 and d.name~='Plinth'and d.name~='OwnerBand'then
            k=opts.heroScale;cf=CF(hb+(cf.Position-hb)*k)*cf.Rotation
        end
        p.Name=d.name;p.Size=V3(d.size[1]*gk,d.size[2],d.size[3]*gk)*s*k
        local o=opts.originFor and opts.originFor(d)or origin
        local at=o*CF(cf.Position*s)*cf.Rotation
        p.CFrame=at;p.Material=MAT[d.material]or MAT.SmoothPlastic
        p.Color=d.tint and colors[d.tint]or rgb(d.color)
        if d.material=='Neon'then p.CastShadow=false end
        local base=0
        if d.name:sub(-3)=='Top'then
            p.CastShadow=false
            if d.size[2]<=.1 and d.pos[2]<.2 then base=d.material=='Neon'and .2 or .3 end
        end
        if d.name:match('^WingTip')or d.name=='Tentacles'then base=.35 end
        p.Transparency=base
        p:SetAttribute('BaseTransparency',base);p:SetAttribute('MeshItem',key)
        p.Parent=parent
        local r={part=p,home=at,def=d,kind=e.kind,phase=d.phase,tint=d.tint,side=e.side,index=e.index,offset=e.offset,radius=e.radius and e.radius*s*k}
        if e.kind then
            local function place(v)return v and o*((k~=1 and hb+(v-hb)*k or v)*s)end
            r.hinge=place(e.hinge);r.hip=place(e.hip);r.axis=e.axis and o.Rotation*e.axis
        end
        table.insert(out,r)
    end
    return out
end
function M.prismatic(r,tier)return tier==5 and r.def.material=='Neon'and r.tint~='team'and r.def.name:sub(-3)~='Top'end

function M.crestKind(key,tier,slot)
    if not Manifest[key]then return nil end
    if tier==5 and(slot=='parachute'or slot=='buildings')then return M.stats(key).phases<2 and 'prism'or nil end
    if tier==4 then local s=M.stats(key);if s.neon<2 or s.movers==0 then return 'halo'end end
    return nil
end
function M.crest(parent,list,kind,frame,radius,color,lite)
    local axis=frame.Rotation*Vector3.yAxis;local hinge=frame.Position;local n0=#list
    local function add(name,size,cf,phase,ball)
        local p=Instance.new('Part');p.Name='Crest'..name;p.Size=size;p.CFrame=frame*cf;p.Color=color
        p.Material=MAT.Neon;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
        if ball then p.Shape=Enum.PartType.Ball end
        p:SetAttribute('BaseTransparency',0);p:SetAttribute('Crest',kind);p.Parent=parent
        table.insert(list,{part=p,home=p.CFrame,def={name=p.Name,material='Neon'},kind='ring',hinge=hinge,axis=axis,
            index=1+2*(#list-n0),phase=phase,tint='accent',spin=kind=='halo'and .45 or .3,crest=true})
    end
    local R=radius;local th=math.max(.05,R*.045);local tau=math.pi*2
    if kind=='halo'then
        local n=lite and 6 or 8
        for i=0,n-1 do add('Halo',V3(R*tau/n*.62,th,th*1.4),ANG(0,i/n*tau,0)*CF(0,0,-R))end
        for i=0,1 do add('Satellite',V3(1,1,1)*th*3.4,ANG(0,i*math.pi,0)*CF(0,th*2.4,-R),nil,true)end
    else
        local k=R/2.2
        add('Prism',V3(.42,1.3,.42)*k,CF(0,.7*k,0)*ANG(0,math.pi/4,0),1)
        for _,side in ipairs({-1,1})do add('Prism',V3(.28,.85,.28)*k,CF(side*R*.5,.42*k,0)*ANG(0,math.pi/4,side*.32),2)end
        if not lite then for i=0,5 do add('Shard',V3(.13,.46,.13)*k,ANG(0,i/6*tau,0)*CF(0,.2*k,-R*.9)*ANG(.35,0,0),3)end end
        local n=lite and 6 or 10
        for i=0,n-1 do add('Ring',V3(R*1.3*tau/n*.6,th,th*1.4),ANG(0,(i+.5)/n*tau,0)*CF(0,.05*k,-R*1.3),3)end
    end
    return list
end

local standardLevels={standard={1,1,1,0},vanguard={1,1,1,1},pathfinder={2,1,2,1},sentinel={2,2,2,2},marshal={2,2,2,2},grandmarshal={3,2,3,3},ascendant={3,3,3,3},sovereign={3,'3s',3,3}}
function M.standardKeys(id)
    local l=standardLevels[id]or standardLevels.standard;local out={'standard/pole'..l[1],'standard/finial'..l[2],'standard/base'..l[3]}
    if l[4]>0 then table.insert(out,'standard/trim'..l[4])end
    return out
end
function M.standardReady(id)local ok=true;for _,k in ipairs(M.standardKeys(id))do if not M.ready(k)then ok=false end end;return ok end

M.manifest=Manifest
function M.stats(key)
    local item=Manifest[key];local r=M.rig(key)
    local s={tris=item.tris or 0,parts=#item.parts,movers=0,kinds={},neon=0,premium=0,phases=0,lo=V3(math.huge,math.huge,math.huge),hi=V3(-math.huge,-math.huge,-math.huge)}
    local premium={Metal=true,Foil=true,Marble=true,Glass=true,DiamondPlate=true,Neon=true}
    for _,e in ipairs(r.parts)do
        local d=e.def
        if e.kind then s.movers+=1;s.kinds[e.kind]=true end
        if d.material=='Neon'then s.neon+=1 end;if premium[d.material]then s.premium+=1 end;if d.phase then s.phases=math.max(s.phases,d.phase)end
        local half=V3(d.size[1],d.size[2],d.size[3])/2;local c=e.home
        for _,sx in ipairs({-1,1})do for _,sy in ipairs({-1,1})do for _,sz in ipairs({-1,1})do
            local p=c*V3(half.X*sx,half.Y*sy,half.Z*sz);s.lo=s.lo:Min(p);s.hi=s.hi:Max(p)
        end end end
    end
    local n=0;for _ in pairs(s.kinds)do n+=1 end;s.motionKinds=n
    return s
end
return M
