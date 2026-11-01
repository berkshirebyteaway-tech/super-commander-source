local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local M={}
local UP=Vector3.yAxis
local FLAT=CFrame.Angles(0,0,math.pi/2)
local HIDE=CFrame.new(0,-1e4,0)
local WHITE=Color3.new(1,1,1)
M.colors={
    core=Color3.fromRGB(255,250,232),flame=Color3.fromRGB(255,214,96),fire=Color3.fromRGB(255,154,60),ember=Color3.fromRGB(236,124,36),
    smoke=Color3.fromRGB(128,134,150),soot=Color3.fromRGB(52,56,66),dust=Color3.fromRGB(206,198,180),gold=Color3.fromRGB(255,206,84),
    cream=Color3.fromRGB(250,240,214),mint=Color3.fromRGB(116,232,196),sky=Color3.fromRGB(150,214,255),
}
M.cap=UIS.TouchEnabled and not UIS.KeyboardEnabled and 260 or 520
M.reduced=false;M.lite=false

local function clamp01(x)return x<0 and 0 or x>1 and 1 or x end
local E={}
function E.out(x)x=clamp01(x);return 1-(1-x)^3 end
function E.outExpo(x)x=clamp01(x);return x>=1 and 1 or 1-2^(-10*x)end
function E.inQuad(x)x=clamp01(x);return x*x end
function E.pop(x)x=clamp01(x);local c=2.2;local u=x-1;return 1+(c+1)*u*u*u+c*u*u end
function E.leave(x,tail)return 1-E.inQuad((x-(1-tail))/tail)end
M.ease=E

local folder,pool,live,used=nil,{block={},ball={},cyl={}},{},0
local function make(kind)
    local p=Instance.new("Part");p.Name="Fx";p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
    p.Material=Enum.Material.SmoothPlastic;p.Transparency=1;p.CFrame=HIDE;p.Size=Vector3.one*.2
    if kind=="ball"then local m=Instance.new("SpecialMesh");m.MeshType=Enum.MeshType.Sphere;m.Parent=p
    elseif kind=="cyl"then p.Shape=Enum.PartType.Cylinder end
    p.Parent=folder;return p
end
local function take(kind,color,material,transparency)
    if used>=M.cap then return nil end
    local list=pool[kind];local p=table.remove(list)or make(kind)
    used+=1;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Transparency=transparency or 0
    return p
end
local function give(kind,p)
    used-=1;p.Transparency=1;p.CFrame=HIDE;table.insert(pool[kind],p)
end
function M.liveParts()return used end

local moves,cfs={},{}
local beat
local function tick(dt)
    local now=os.clock();table.clear(moves);table.clear(cfs)
    for i=#live,1,-1 do local e=live[i];local t=now-e.t0
        if t>=e.life or e.dead then
            for k,p in ipairs(e.parts)do give(e.kinds[k],p)end
            if e.light then e.light.Brightness=0;e.light.Enabled=false end
            table.remove(live,i)
        elseif t>=0 then e.pose(e,t/e.life,t)
            for k,p in ipairs(e.parts)do table.insert(moves,p);table.insert(cfs,e.cf[k])end
        end
    end
    if #moves>0 then workspace:BulkMoveTo(moves,cfs,Enum.BulkMoveMode.FireCFrameChanged)end
    if #live==0 and beat then beat:Disconnect();beat=nil end
end
local function element(kinds,life,delay,pose,color,material)
    if not folder or not folder.Parent then folder=Instance.new("Folder");folder.Name="FxKit";folder.Parent=workspace end
    local e={parts={},kinds={},cf={},t0=os.clock()+(delay or 0),life=life,pose=pose}
    for k,kind in ipairs(kinds)do
        local p=take(kind,type(color)=="table"and color[k]or color,material)
        if not p then break end
        e.parts[k]=p;e.kinds[k]=kind;e.cf[k]=HIDE
    end
    if #e.parts==0 then return nil end
    for _,p in ipairs(e.parts)do p.CFrame=HIDE end
    table.insert(live,e)
    if not beat then beat=RunService.Heartbeat:Connect(tick)end
    return e
end
local function rep(kind,n)local t={};for i=1,n do t[i]=kind end;return t end
function M.clear()for _,e in ipairs(live)do e.dead=true end;tick(0)end
function M.step(dt)tick(dt or 0)end

local rnd=Random.new(2410)
local function camFacing(at)
    local cam=workspace.CurrentCamera
    if cam then return CFrame.new(at)*cam.CFrame.Rotation end
    return CFrame.lookAt(at,at+Vector3.new(0,40,30))
end

function M.flash(at,r,life,color,lit)
    local e=element({"ball"},life or .16,0,function(e,u)
        local s=r*(u<.35 and E.outExpo(u/.35)*1.1 or 1.1-0.9*E.inQuad((u-.35)/.65))
        local p=e.parts[1];p.Size=Vector3.one*math.max(.01,s);e.cf[1]=CFrame.new(at)
        p.Transparency=u<.4 and 0 or (u-.4)/.6*.7
        if e.light then e.light.Brightness=(1-u)*4 end
    end,color or M.colors.core,Enum.Material.Neon)
    if e and lit~=false then
        local l=e.parts[1]:FindFirstChildOfClass("PointLight")or Instance.new("PointLight")
        l.Color=M.colors.fire;l.Shadows=false;l.Range=math.min(22,r*6);l.Brightness=4;l.Enabled=true;l.Parent=e.parts[1];e.light=l
    end
    return e
end

function M.fireball(at,r,n,rise,life,palette)
    palette=palette or {M.colors.flame,M.colors.fire,M.colors.smoke}
    local seeds={}
    for i=1,n do local a=i/n*math.pi*2+rnd:NextNumber(-.4,.4);local d=i==1 and 0 or rnd:NextNumber(.35,.8)
        seeds[i]={dir=Vector3.new(math.cos(a)*d,0,math.sin(a)*d),k=i==1 and 1.25 or rnd:NextNumber(.75,1.05),lag=(i-1)*.012,spin=rnd:NextNumber(.85,1.15)}
    end
    local kinds=rep("ball",n*2)
    return element(kinds,life,0,function(e,u)
        for i,s in ipairs(seeds)do
            local v=clamp01((u-s.lag)/(1-s.lag))
            local grow=E.pop(math.min(1,v/.22))*E.leave(v,.38)
            local size=r*s.k*grow
            local pos=at+s.dir*r*(.4+.9*E.out(v))+UP*(r*.35+rise*E.out(v)*s.spin)
            local c=v<.28 and palette[1]:Lerp(palette[2],v/.28)or palette[2]:Lerp(palette[3],clamp01((v-.28)/.4))
            local body,cap=e.parts[i*2-1],e.parts[i*2]
            local hot=i==1 and v<.16
            if body then body.Size=Vector3.one*math.max(.01,size);body.Color=c;local mat=hot and Enum.Material.Neon or Enum.Material.SmoothPlastic;if body.Material~=mat then body.Material=mat end;e.cf[i*2-1]=CFrame.new(pos)end
            if cap then cap.Size=Vector3.one*math.max(.01,size*.6);cap.Color=c:Lerp(WHITE,v<.3 and .45 or .18);if cap.Material~=Enum.Material.SmoothPlastic then cap.Material=Enum.Material.SmoothPlastic end
                e.cf[i*2]=CFrame.new(pos+Vector3.new(-.14,.24,-.14)*size)end
        end
    end,palette[1],Enum.Material.Neon)
end

function M.puffs(at,r,n,color,life,rise,spread,ring,delay,head)
    local seeds={}
    for i=1,n do local a=i/n*math.pi*2+rnd:NextNumber(-.3,.3)
        seeds[i]={dir=Vector3.new(math.cos(a),0,math.sin(a)),k=rnd:NextNumber(.75,1.15),lag=rnd:NextNumber(0,.12)}
    end
    local light=head and color:Lerp(WHITE,head)
    return element(rep("ball",head and n*2 or n),life,delay,function(e,u)
        for i,s in ipairs(seeds)do local p=e.parts[i];if not p then break end
            local v=clamp01((u-s.lag)/(1-s.lag))
            local size=r*s.k*E.pop(math.min(1,v/.3))*E.leave(v,.45)
            local out=ring and spread*(.35+.65*E.outExpo(v))or spread*E.out(v)*(.3+.2*i/n)
            local pos=at+s.dir*out+UP*(size*.3+rise*E.out(v))
            p.Size=Vector3.new(size,size*(ring and .62 or .85),size);e.cf[i]=CFrame.new(pos)
            local h=head and e.parts[n+i]
            if h then h.Size=Vector3.new(size*.6,size*.42,size*.6);h.Color=light;e.cf[n+i]=CFrame.new(pos+Vector3.new(-.12,.2,-.12)*size)end
        end
    end,color,Enum.Material.SmoothPlastic)
end

function M.ring(at,r0,r1,color,life,width,segments,material,delay)
    segments=segments or 18
    return element(rep("block",segments),life,delay,function(e,u)
        local r=r0+(r1-r0)*E.outExpo(u)
        local w=width*(1-.75*E.out(u))
        local arc=2*math.pi*r/segments*1.08
        for i=1,segments do local p=e.parts[i];if not p then break end
            local a=(i-.5)/segments*math.pi*2
            p.Size=Vector3.new(arc,math.max(.03,w*.35),w);p.Transparency=u<.45 and 0 or (u-.45)/.55
            e.cf[i]=CFrame.new(at+Vector3.new(math.cos(a)*r,.04,math.sin(a)*r))*CFrame.Angles(0,-a+math.pi/2,0)
        end
    end,color,material or Enum.Material.Neon)
end

function M.spikes(at,n,len,width,color,life,delay,yaw)
    local seeds={}
    for i=1,n do seeds[i]={a=(yaw or 0)+i/n*math.pi*2+rnd:NextNumber(-.12,.12),k=i%2==0 and .62 or 1}end
    return element(rep("block",n),life,delay,function(e,u)
        local head=E.outExpo(math.min(1,u/.45));local tail=E.inQuad(math.max(0,(u-.25)/.75))
        for i,s in ipairs(seeds)do local p=e.parts[i];if not p then break end
            local L=len*s.k;local a,b=L*.12+L*tail,L*.12+L*head;local l=math.max(.02,b-a)
            local dir=Vector3.new(math.cos(s.a),0,math.sin(s.a))
            p.Size=Vector3.new(width*(1-.6*tail)*s.k,.05,l)
            e.cf[i]=CFrame.lookAt(at+dir*((a+b)/2)+UP*.06,at+dir*(b+1)+UP*.06)
        end
    end,color,Enum.Material.Neon)
end

function M.debris(at,n,colors,s,ground,life)
    local seeds={}
    for i=1,n do local a=i/n*math.pi*2+rnd:NextNumber(-.3,.3)
        seeds[i]={dir=Vector3.new(math.cos(a),0,math.sin(a)),v=s*rnd:NextNumber(1.6,2.6),up=s*rnd:NextNumber(3.2,4.6),
            size=Vector3.new(rnd:NextNumber(.18,.3),rnd:NextNumber(.14,.24),rnd:NextNumber(.16,.28))*s,spin=Vector3.new(rnd:NextNumber(-9,9),rnd:NextNumber(-9,9),rnd:NextNumber(-9,9))}
    end
    local kinds,cols=rep("block",n),{};for i=1,n do cols[i]=colors[(i-1)%#colors+1]end
    local g=s*22
    return element(kinds,life,0,function(e,u,t)
        for i,d in ipairs(seeds)do local p=e.parts[i];if not p then break end
            local t1=2*d.up/g;local y,x,rest
            if t<t1 then y=d.up*t-.5*g*t*t;x=d.v*t
            else local tb=t-t1;local up2=d.up*.35;local t2=2*up2/g
                if tb<t2 then y=up2*tb-.5*g*tb*tb;x=d.v*t1+d.v*.35*tb else y=0;x=d.v*t1+d.v*.35*t2;rest=true end
            end
            local k=E.leave(u,.3);p.Size=d.size*math.max(.01,k)
            local spin=rest and t1*1.4 or t
            e.cf[i]=CFrame.new(at+d.dir*x+UP*(y+d.size.Y*.5))*CFrame.Angles(d.spin.X*spin*.2,d.spin.Y*spin*.2,d.spin.Z*spin*.2)
        end
    end,cols,Enum.Material.SmoothPlastic)
end

function M.sparks(at,n,color,s,life,ground)
    local seeds={}
    for i=1,n do local a=rnd:NextNumber(0,math.pi*2)
        seeds[i]={vel=Vector3.new(math.cos(a)*rnd:NextNumber(1.5,3.2),rnd:NextNumber(3.5,6),math.sin(a)*rnd:NextNumber(1.5,3.2))*s,k=rnd:NextNumber(.7,1.2)}
    end
    local g=s*16
    return element(rep("block",n),life,0,function(e,u,t)
        for i,d in ipairs(seeds)do local p=e.parts[i];if not p then break end
            local vel=d.vel-UP*g*t;local pos=at+d.vel*t-UP*.5*g*t*t
            if ground and pos.Y<ground then pos=Vector3.new(pos.X,ground,pos.Z)end
            local k=E.leave(u,.5)*d.k;local len=math.clamp(vel.Magnitude*.05,.08,.9)*s
            p.Size=Vector3.new(.07*s*k,.07*s*k,math.max(.02,len*k))
            e.cf[i]=CFrame.lookAt(pos,pos+(vel.Magnitude>.01 and vel.Unit or UP))
        end
    end,color,Enum.Material.Neon)
end

function M.stars(at,n,colors,spread,size,life,rise,delay)
    local seeds={}
    for i=1,n do local a=rnd:NextNumber(0,math.pi*2);local d=rnd:NextNumber(.35,1)*spread
        seeds[i]={off=Vector3.new(math.cos(a)*d,rnd:NextNumber(.2,1)*spread*.6,math.sin(a)*d),lag=rnd:NextNumber(0,.45),k=rnd:NextNumber(.6,1.1)}
    end
    local kinds,cols={},{}
    for i=1,n do kinds[i*2-1]="block";kinds[i*2]="block";local c=colors[(i-1)%#colors+1];cols[i*2-1]=c;cols[i*2]=c end
    return element(kinds,life,delay,function(e,u)
        for i,s in ipairs(seeds)do
            local v=clamp01((u-s.lag)/(1-s.lag))
            local k=size*s.k*E.pop(math.min(1,v/.25))*E.leave(v,.5)
            local base=camFacing(at+s.off+UP*rise*E.out(v))*CFrame.Angles(0,0,v*math.pi*.5)
            local a,b=e.parts[i*2-1],e.parts[i*2]
            if a then a.Size=Vector3.new(k*.16,k,.04);e.cf[i*2-1]=base end
            if b then b.Size=Vector3.new(k,k*.16,.04);e.cf[i*2]=base end
        end
    end,cols,Enum.Material.Neon)
end

function M.scorch(at,r,n,life,color)
    local kinds={"cyl"};for i=1,n do kinds[i+1]="block"end
    local seeds={};for i=1,n do seeds[i]={a=i/n*math.pi*2+rnd:NextNumber(-.3,.3),k=rnd:NextNumber(.75,1.25)}end
    return element(kinds,life,0,function(e,u)
        local grow=E.outExpo(math.min(1,u/.08));local fade=u<.6 and .25 or .25+.75*(u-.6)/.4
        local d=e.parts[1];d.Size=Vector3.new(.03,r*2*grow,r*2*grow);d.Transparency=fade;e.cf[1]=CFrame.new(at+UP*.02)*FLAT
        for i,s in ipairs(seeds)do local p=e.parts[i+1];if not p then break end
            local L=r*1.05*s.k*grow;local dir=Vector3.new(math.cos(s.a),0,math.sin(s.a))
            p.Size=Vector3.new(r*.12,.03,L);p.Transparency=fade;e.cf[i+1]=CFrame.lookAt(at+dir*(r*.3+L/2)+UP*.025,at+dir*(r*.3+L+1)+UP*.025)
        end
    end,color or M.colors.soot,Enum.Material.SmoothPlastic)
end

function M.pillar(at,r,h,color,life,delay)
    return element({"cyl","cyl"},life,delay,function(e,u)
        local up=E.outExpo(math.min(1,u/.3));local pinch=E.inQuad(math.max(0,(u-.35)/.65))
        local height=h*up;local bottom=h*pinch*.9;local len=math.max(.02,height-bottom)
        local w=r*(1-pinch)*(u<.2 and E.pop(u/.2)or 1)
        local core,glow=e.parts[1],e.parts[2]
        core.Size=Vector3.new(len,w*.45,w*.45);e.cf[1]=CFrame.new(at+UP*(bottom+len/2))*CFrame.Angles(0,0,math.pi/2)
        if glow then glow.Size=Vector3.new(len,w,w);glow.Transparency=.55+.45*pinch;e.cf[2]=e.cf[1]end
    end,{M.colors.core,color},Enum.Material.Neon)
end

function M.chevrons(at,size,color,life,count)
    count=count or 3
    return element(rep("block",count*2),life,0,function(e,u)
        for i=1,count do
            local v=clamp01((u-(i-1)*.14)/.6)
            local k=size*E.pop(math.min(1,v/.3))*E.leave(v,.35)
            local base=camFacing(at+UP*size*.8)*CFrame.new(0,i*size*.75+E.out(v)*size*.9,0)
            local a,b=e.parts[i*2-1],e.parts[i*2]
            if a then a.Size=Vector3.new(k*.22,k*.7,.05);e.cf[i*2-1]=base*CFrame.new(-k*.2,0,0)*CFrame.Angles(0,0,-math.rad(42))end
            if b then b.Size=Vector3.new(k*.22,k*.7,.05);e.cf[i*2]=base*CFrame.new(k*.2,0,0)*CFrame.Angles(0,0,math.rad(42))end
        end
    end,color,Enum.Material.Neon)
end

function M.brackets(at,r,color,life)
    return element(rep("block",8),life,0,function(e,u)
        local snap=E.pop(math.min(1,u/.3));local out=E.leave(u,.3)
        local d=r*(1.9-.9*snap);local arm=r*.42*out
        for c=0,3 do local yaw=CFrame.new(at+UP*.08)*CFrame.Angles(0,c*math.pi/2+math.pi/4,0)
            local corner=yaw*CFrame.new(0,0,-d)
            local a,b=e.parts[c*2+1],e.parts[c*2+2]
            if a then a.Size=Vector3.new(arm,.08,.12*r);e.cf[c*2+1]=corner*CFrame.Angles(0,math.rad(45),0)*CFrame.new(arm/2,0,0)end
            if b then b.Size=Vector3.new(arm,.08,.12*r);e.cf[c*2+2]=corner*CFrame.Angles(0,math.rad(135),0)*CFrame.new(arm/2,0,0)end
        end
    end,color,Enum.Material.Neon)
end

local Tex=require(script.Parent.FxTextures)
M.particleCap=UIS.TouchEnabled and not UIS.KeyboardEnabled and 160 or 320
local emitters,particles={},0
local function seq(v,kind)
    if typeof(v)=="NumberSequence"or typeof(v)=="ColorSequence"then return v end
    if kind=="color"then
        if typeof(v)=="Color3"then return ColorSequence.new(v)end
        local keys={};for i,c in ipairs(v)do keys[i]=ColorSequenceKeypoint.new(c[1],c[2])end;return ColorSequence.new(keys)
    end
    if type(v)=="number"then return NumberSequence.new(v)end
    local keys={};for i,k in ipairs(v)do keys[i]=NumberSequenceKeypoint.new(k[1],k[2])end;return NumberSequence.new(keys)
end
local function half(v)
    if type(v)=="number"then return v/2 end
    local t={};for i,k in ipairs(v)do t[i]={k[1],k[2]/2}end;return t
end
local function lease(tex)
    local list=emitters[tex];if not list then list={};emitters[tex]=list end
    local now=os.clock()
    for _,l in ipairs(list)do if l.free<=now then return l end end
    if #list>=24 then return nil end
    if not folder or not folder.Parent then folder=Instance.new("Folder");folder.Name="FxKit";folder.Parent=workspace end
    local anchor=Instance.new("Part");anchor.Name="FxEmitter";anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false
    anchor.CastShadow=false;anchor.Transparency=1;anchor.Size=Vector3.one*.1;anchor.Parent=folder
    local e=Instance.new("ParticleEmitter");e.Name=tex;e.Enabled=false;e.Rate=0;e.Texture=Tex[tex];e.LightInfluence=0;e.Parent=anchor
    if Tex.flipbook[tex]then e.FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4;e.FlipbookMode=Enum.ParticleFlipbookMode.OneShot end
    local l={anchor=anchor,emitter=e,free=0};table.insert(list,l);return l
end
function M.sprites(tex,at,o)
    if not Tex[tex]then return false end
    local function fire()
        local n=o.count or 1;if particles+n>M.particleCap then return end
        local l=lease(tex);if not l then return end
        local e=l.emitter;local life=o.life or {.5,.5}
        l.anchor.CFrame=CFrame.new(at)
        e.Lifetime=NumberRange.new(life[1],life[2]);e.Size=seq(half(o.size or 1));e.Color=seq(o.color or Color3.new(1,1,1),"color")
        e.Transparency=seq(o.alpha or 0);e.Speed=NumberRange.new((o.speed or {0,0})[1],(o.speed or {0,0})[2])
        e.SpreadAngle=Vector2.new(o.spread or 0,o.spread or 0);e.Acceleration=o.accel or Vector3.zero;e.Drag=o.drag or 0
        e.Rotation=NumberRange.new((o.rot or {0,0})[1],(o.rot or {0,0})[2]);e.RotSpeed=NumberRange.new((o.spin or {0,0})[1],(o.spin or {0,0})[2])
        e.LightEmission=o.glow or 0;e.LightInfluence=(o.glow or 0)>0 and 0 or 1;e.Brightness=o.bright or 1;e.ZOffset=o.z or 0
        e.EmissionDirection=Enum.NormalId.Top
        e.Orientation=o.flat and Enum.ParticleOrientation.VelocityPerpendicular or Enum.ParticleOrientation.FacingCamera
        if o.flat and (o.speed==nil)then e.Speed=NumberRange.new(.01,.01)end
        e:Emit(n);particles+=n;l.free=os.clock()+life[2]+.05
        task.delay(life[2],function()particles=math.max(0,particles-n)end)
    end
    if o.delay and o.delay>0 then task.delay(o.delay,fire)else fire()end
    return true
end
function M.liveParticles()return particles end
function M.layer(base,over)
    if not over then return base end
    local out={}
    for key,b in pairs(base)do
        local o=over[key]
        if o==false then out[key]=nil
        elseif type(o)=="table"then local t=table.clone(b);for k2,v in pairs(o)do t[k2]=v end;out[key]=t
        else out[key]=b end
    end
    return out
end
M.textures=Tex

return M
