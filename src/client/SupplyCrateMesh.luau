local Meshes=require(script.Parent.CosmeticMeshes)
local K=require(script.Parent.SkinShopKit)
local Rules=require(script.Parent.Parent.Core.SupplyLandingRules)
local M={}
local CF,V3,ANG=CFrame.new,Vector3.new,CFrame.Angles
local rad=math.rad
local states=setmetatable({},{__mode='k'})

M.grades={K.rarity.normal,K.rarity.rare,K.rarity.epic,K.rarity.legendary,K.rarity.mythic}
M.box=K.box
function M.mythic(t,i)local h,sat=Rules.mythicLight((t or 0)/6+(i or 0)*.13);return Color3.fromHSV(h,sat,1)end
function M.gradeColor(g,t,i)return g>=5 and M.mythic(t,i)or M.grades[math.clamp(g,1,5)]end
M.rainbow=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromHSV(.80,.6,1)),ColorSequenceKeypoint.new(.5,Color3.fromHSV(.86,.52,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(.92,.44,1))})

M.kinds={'basic','epic','legendary','mythic'}
M.keys={'supply/crate_basic','supply/crate_epic','supply/crate_legendary','supply/crate_mythic',
    'supply/aircraft_transport','supply/aircraft_fighter','supply/aircraft_stealth','supply/chute'}
function M.crateKey(kind)return 'supply/crate_'..(Rules.boxTier[kind]and kind or 'basic')end
local fetched=false
function M.prefetch()if fetched then return end;fetched=true;for _,k in ipairs(M.keys)do Meshes.request(k)end end
function M.ready(key)return Meshes.ready(key)end

local function hingeOf(r)local p=r.def.pivot;return p and(r.home*CF(p[1],p[2],p[3])).Position end
local function byName(list)local out={};for _,r in ipairs(list)do out[r.def.name]=r end;return out end
local function quintOut(u)u=math.clamp(u,0,1);return 1-(1-u)^5 end
local function backOut(u)u=math.clamp(u,0,1);local c=1.70158;return 1+(c+1)*(u-1)^3+c*(u-1)^2 end
local function ease(u)u=math.clamp(u,0,1);return u*u*(3-2*u)end

local function fillCrate(model,kind)
    local key=M.crateKey(kind);local accent=K.box[kind]or K.box.basic
    local list=Meshes.build(model,key,{colors={accent=accent,signal=accent}});if not list then return nil end
    local n=byName(list);local anchors=require(script.Parent.CosmeticMeshManifest)[key].anchors or {}
    local c={key=key,kind=kind,tier=Rules.boxTier[kind]or 1,list=list,lamps={},doors={},rings={},petals={},anchors=anchors}
    for i=1,4 do local r=n['Lamp'..i];c.lamps[i]=r.part;r.part.Color=Color3.fromRGB(table.unpack(r.def.color));r.part.Material=Enum.Material.SmoothPlastic end
    c.front=n.SeamFront.part;c.body=n.SeamBody.part;c.mark=n.Mark.part
    c.plate={part=n.SealPlate.part,home=n.SealPlate.home}
    for _,name in ipairs({'DoorL','DoorR'})do local r=n[name]
        local h=hingeOf(r);c.doors[#c.doors+1]={part=r.part,home=CF(h):ToObjectSpace(r.home),hinge=CF(h),dir=name=='DoorL'and -1 or 1}
    end
    for _,name in ipairs({'RingA','RingB'})do local r=n[name];if r then c.rings[#c.rings+1]={part=r.part,home=r.home,name=name}end end
    if n.CrownA then c.crown={part=n.CrownA.part,home=n.CrownA.home}end
    for i=1,4 do local r=n['Petal'..i];if r then
        local h=hingeOf(r);local sx=r.def.pos[1]>0 and 1 or -1;local sz=r.def.pos[3]>0 and 1 or -1
        c.petals[i]={part=r.part,home=r.home,hinge=h,axis=V3(sz,0,-sx).Unit,index=i}
    end end
    local lo,hi;for _,r in ipairs(list)do local hs=r.part.Size/2;local p=r.home.Position;lo=lo and lo:Min(p-hs)or p-hs;hi=hi and hi:Max(p+hs)or p+hs end
    c.height=hi.Y;c.radius=math.max(math.abs(lo.X),hi.X,math.abs(lo.Z),hi.Z)
    model:SetAttribute('MeshItem',key)
    return c
end
local function about(h,axis,a)return CF(h)*CFrame.fromAxisAngle(axis,a)*CF(-h)end
local function placePetals(c,frame,angle,t)
    for _,p in ipairs(c.petals)do p.part.CFrame=frame*about(p.hinge,p.axis,rad(type(angle)=='function'and angle(p.index)or angle))*p.home end
end

function M.shopModel(model,kind)
    M.prefetch()
    local c=fillCrate(model,kind);if not c then return false end
    c.shop=true;states[model]=c
    if c.tier>=4 and model:FindFirstChild('Body')then
        local light=Instance.new('PointLight');light.Name='CrateGlow';light.Color=K.box[kind];light.Range=9;light.Brightness=c.tier>=5 and 1.4 or 1;light.Shadows=false;light.Parent=model.Body
    end
    return true
end
function M.isMesh(model)return states[model]~=nil end
function M.shopStep(model,base,age,reduced)
    local c=states[model];if not c then return false end
    local tier=c.tier;local half=reduced and .5 or 1
    local bob=(not reduced and tier>=3)and math.sin(age*math.pi*2/3.2)*({0,0,.04,.05,.06})[tier]or 0
    local frame=base*CF(0,bob,0)*ANG(0,reduced and 0 or rad(18)*age,0)
    model:PivotTo(frame)
    for _,r in ipairs(c.rings)do
        local a=r.name=='RingA'and -rad(58)*age*half or rad(60)*age*half
        r.part.CFrame=frame*ANG(0,a,0)*r.home
    end
    if c.crown then
        local up=reduced and 0 or (math.sin(age*math.pi*2/2.6)*.5+.5)*.18
        c.crown.part.CFrame=frame*CF(0,up,0)*ANG(0,rad(25)*age*half,0)*c.crown.home
        c.crown.part.Color=M.mythic(age,0)
    end
    if #c.petals>0 then
        local breath=reduced and 0 or (math.sin(age*math.pi*2/4)*.5+.5)*4
        placePetals(c,frame,breath)
        for _,p in ipairs(c.petals)do p.part.Color=M.mythic(age,p.index)end
    end
    return true
end

function M.cineCrate(kind,dark,glowFn,emitterFn,smokeProps)
    if not Meshes.ready(M.crateKey(kind))then return nil end
    local m=Instance.new('Model');m.Name='SupplyCrate'
    local root=Instance.new('Part');root.Name='Root';root.Size=V3(.2,.2,.2);root.Transparency=1;root.Anchored=true;root.CanCollide=false;root.CanTouch=false;root.CanQuery=false;root.Parent=m;m.PrimaryPart=root
    local c=fillCrate(m,kind);if not c then m:Destroy();return nil end
    c.mesh=true;c.root=root;c.seams={c.front,c.body}
    local inner=Instance.new('Part');inner.Name='InnerGlow';inner.Size=V3(5.4,3.4,4.0);inner.CFrame=CF(0,2.43,-.1);inner.Anchored=true;inner.CanCollide=false;inner.CanTouch=false;inner.CanQuery=false
    inner.Parent=m;glowFn(inner,M.grades[1]);inner.Transparency=1;c.inner=inner
    c.light=Instance.new('PointLight');c.light.Range=16;c.light.Brightness=0;c.light.Shadows=false;c.light.Parent=inner
    c.smoke=emitterFn(root,smokeProps)
    c.sig={g=1,prev=1,at=-10}
    m.WorldPivot=CFrame.identity
    return m,c
end
function M.signal(c,g,clock)if g~=c.sig.g then c.sig={g=g,prev=c.sig.g,at=clock}end end
function M.doorAngle(u)
    if u<.55 then return 111*quintOut(u/.55)end
    return 111-6*ease((u-.55)/.15)
end
function M.cineStep(c,frame,info)
    local t=info.t;local reduced=info.reduced
    local sig=c.sig;local age=t-sig.at
    local col=M.gradeColor(sig.g,t);local prev=M.gradeColor(sig.prev,t)
    c.front.Color=(not reduced and age<.08)and Color3.new(1,1,1)or col
    c.body.Color=age<.15 and prev or col
    if info.pulseAt then local p=t-info.pulseAt;if p>=0 and p<.6 then local on=math.floor(p/.1)%2==0;c.front.Transparency=on and 0 or .5;c.body.Transparency=on and 0 or .5 else c.front.Transparency=0;c.body.Transparency=0 end end
    if info.beat=='pause'or info.beat=='open'or info.beat=='reveal'then c.mark.Color=M.gradeColor(info.tier,t)end
    local press=info.sealPress and .02 or 0;local jx=0
    if info.jitterAt and t-info.jitterAt<.12 then jx=(math.floor((t-info.jitterAt)/.04)%2==0 and .03 or -.03)end
    c.plate.part.CFrame=frame*CF(jx,0,press)*c.plate.home
    local fast=info.beat=='descent';local half=reduced and .5 or 1
    local wob=0;if info.landAt then local l=t-info.landAt;if l>=0 and l<.8 then wob=rad(6)*math.sin(l*18)*(1-l/.8)end end
    for _,r in ipairs(c.rings)do
        local a=(r.name=='RingA'and -(fast and 90 or 58)or(fast and 120 or 60))*t*half
        r.part.CFrame=frame*ANG(wob,rad(a),0)*r.home
    end
    if c.crown then
        local y=0;local fade=0
        if info.landAt then local l=t-info.landAt;if l>=0 and l<.6 then y=-.25*math.exp(-l*7)*math.cos(l*16)end end
        if info.openAt then local o=math.clamp((t-info.openAt)/.7,0,1);y=1.2*ease(o)
            if info.crownTop then y=math.max(y,info.crownTop-c.crown.home.Position.Y)end
        end
        if info.sink and info.sink>0 then fade=math.clamp(info.sink/.33,0,1)end
        local spin=rad(info.openAt and 90 or 25)*t*half
        c.crown.part.CFrame=frame*CF(0,y,0)*ANG(0,spin,0)*c.crown.home
        c.crown.part.Transparency=fade;c.crown.part.Color=M.mythic(t,0)
    end
    if #c.petals>0 then
        local function angle(i)
            if info.openAt then
                local start=info.openAt+.21+(i-1)*.08;return 62*backOut((t-start)/.5)
            elseif info.landAt then local l=t-info.landAt;if l>=0 and l<.4 then return 8*math.sin(math.pi*l/.4)end end
            return 0
        end
        placePetals(c,frame,angle)
        for _,p in ipairs(c.petals)do p.part.Color=M.mythic(t,p.index)end
    end
end
function M.descentYaw(u,k)return rad(10)*u*(1-k)end
function M.descentPose(tier,t,u,k)
    local amp=rad(tier>=5 and 3 or 4)
    local jerk=0;local nod=0
    if u<.5 then
        local j=u/.5;nod=rad(6)*math.sin(math.pi*math.min(1,j*2))*(1-j)
        jerk=j<.4 and -.6*ease(j/.4)or j<.7 and -.6+.9*ease((j-.4)/.3)or .3*(1-ease((j-.7)/.3))
    end
    return CF(0,jerk,0)*ANG(math.sin(t*math.pi*2/2.2)*amp*(1-k)+nod,M.descentYaw(u,k),0)
end
function M.landingPose(tier,u)
    local down=tier>=5 and -.15 or -.12;local up=tier>=5 and .06 or .05;local y
    if u<.06 then y=down*(u/.06)elseif u<.16 then y=down+(up-down)*ease((u-.06)/.1)elseif u<.3 then y=up*(1-ease((u-.16)/.14))else y=0 end
    return CF(0,y,0)*ANG(0,0,rad(2)*math.max(0,1-u/.3))
end

function M.aircraft(kind)
    local key='supply/aircraft_'..kind;if not Meshes.ready(key)then return nil end
    local m=Instance.new('Model');m.Name='SupplyAircraft'
    local list=Meshes.build(m,key,{colors={signal=M.grades[1]}});if not list then m:Destroy();return nil end
    local n=byName(list);local lights={};local extra={mesh=true}
    for _,r in ipairs(list)do
        r.part.CastShadow=false
        if r.def.tint=='signal'then
            local idx=tonumber(r.def.name:match('^TrailingEdge(%d+)$'))
            lights[#lights+1]=r.part;if idx then r.part:SetAttribute('SweepRank',4-((idx-1)%4))end
        end
    end
    if n.Ramp then extra.ramp={part=n.Ramp.part,home=n.Ramp.home,hinge=hingeOf(n.Ramp)}end
    m.WorldPivot=CFrame.identity
    return m,lights,extra
end
function M.rampAngle(pz)
    if pz>75 then return 0 elseif pz>0 then return 40*ease((75-pz)/75)
    elseif pz>-90 then return 40+8*math.sin(math.pi*(-pz)/90)
    else return 40*(1-ease((-pz-90)/75))end
end
function M.poseRamp(extra,frame,angle)
    local r=extra and extra.ramp;if not r then return end
    r.part.CFrame=frame*about(r.hinge,Vector3.xAxis,rad(angle))*r.home
end
function M.paintLights(lights,g,t,sweepAge)
    for i,p in ipairs(lights)do
        local rank=p:GetAttribute('SweepRank');local on=g>1 and(not rank or(sweepAge or 99)>=(rank-1)*.05)
        p.Material=on and Enum.Material.Neon or Enum.Material.SmoothPlastic
        p.Color=on and M.gradeColor(g,t,i)or M.grades[1]:Lerp(Color3.new(0,0,0),.45)
    end
end
function M.chute()
    local key='supply/chute';if not Meshes.ready(key)then return nil end
    local m=Instance.new('Model');m.Name='SupplyChute'
    local hub=Instance.new('Part');hub.Name='Hub';hub.Size=V3(.3,.3,.3);hub.Transparency=1;hub.Anchored=true;hub.CanCollide=false;hub.CanTouch=false;hub.CanQuery=false;hub.Parent=m;m.PrimaryPart=hub
    local list=Meshes.build(m,key,{colors={signal=M.grades[1]}});if not list then m:Destroy();return nil end
    local n=byName(list);local gores={}
    for i=1,8 do local r=n['Gore'..i];r.part.CastShadow=false;gores[i]=r.part end
    local trims={};for _,name in ipairs({'Vent','Skirt'})do if n[name]then n[name].part.CastShadow=false;trims[#trims+1]=n[name].part end end
    m.WorldPivot=CFrame.identity
    return m,gores,trims,hub
end
function M.lineTop(a)local d=V3(a.X,0,a.Z);d=d.Magnitude>0 and d.Unit or Vector3.xAxis;return d*8.6+V3(0,-3.9,0)end
M.chuteLift=13.6
return M
