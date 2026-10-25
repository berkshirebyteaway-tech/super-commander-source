local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local S=require(script.Parent.Parent.Core.StrideMotion)
local Vehicle=require(script.Parent.CommanderVehicle)
local G=require(script.Parent.Parent.Core.CommandGesture)
local M={range=140,rigs=setmetatable({},{__mode='k'}),enabled=true}
M.posing=nil;M.holders=setmetatable({},{__mode='k'})
local gameSettings=nil
pcall(function()gameSettings=UserSettings():GetService("UserGameSettings")end)

local function frame(j)
    local cf=if j:IsA("Motor6D")then j.C0 else (j.Attachment0 and j.Attachment0.CFrame or CFrame.identity)
    local rot=cf.Rotation;return rot,rot:Inverse()
end
local function seat(j,part)
    if j:IsA("Motor6D")then return if part==0 then j.C0.Position else j.C1.Position end
    local a=if part==0 then j.Attachment0 else j.Attachment1;return a and a.Position or Vector3.zero
end
local NAMES={Root={"Root","RootJoint"},Neck={"Neck"},LeftHip={"LeftHip","Left Hip"},RightHip={"RightHip","Right Hip"},LeftKnee={"LeftKnee"},RightKnee={"RightKnee"},LeftAnkle={"LeftAnkle"},
    RightAnkle={"RightAnkle"},Waist={"Waist"},LeftShoulder={"LeftShoulder","Left Shoulder"},RightShoulder={"RightShoulder","Right Shoulder"},LeftElbow={"LeftElbow"},RightElbow={"RightElbow"},
    LeftWrist={"LeftWrist"},RightWrist={"RightWrist"}}
local function build(c)
    local found={}
    for _,o in ipairs(c:GetDescendants())do
        if o:IsA("AnimationConstraint")or o:IsA("Motor6D")then
            for key,names in pairs(NAMES)do if not found[key]and table.find(names,o.Name)then found[key]=o end end
        end
    end
    if not found.Root then return nil end
    local rig={joints={},base={},lean={0,0,0,0},dip=0,dipV=0,head=0,headV=0,fallPeak=0}
    for key,j in pairs(found)do local rot,inv=frame(j);rig.joints[key]={j=j,rot=rot,inv=inv}end
    local hip,knee,ankle=found.LeftHip,found.LeftKnee,found.LeftAnkle
    if hip and knee then
        rig.thigh=(seat(hip,1)-seat(knee,0)).Magnitude
        rig.shin=ankle and (seat(knee,1)-seat(ankle,0)).Magnitude or rig.thigh
        rig.legScale=1;local ok,s=pcall(function()return c:GetScale()end);if ok then rig.legScale=s end
    end
    local r=S.ride;local hipA,kneeA,ankleA,drop=S.rideLegs(rig.thigh or 1,rig.shin or 1)
    local want={Root=CFrame.new(0,-drop,0),Waist=CFrame.Angles(-r.waist,0,0),Neck=CFrame.Angles(r.waist,0,0),
        LeftHip=CFrame.Angles(hipA,0,0),RightHip=CFrame.Angles(hipA,0,0),LeftKnee=CFrame.Angles(-kneeA,0,0),RightKnee=CFrame.Angles(-kneeA,0,0),
        LeftAnkle=CFrame.Angles(ankleA,0,0),RightAnkle=CFrame.Angles(ankleA,0,0),
        LeftShoulder=CFrame.Angles(r.shoulder,0,r.inward),RightShoulder=CFrame.Angles(r.shoulder,0,-r.inward),
        LeftElbow=CFrame.Angles(r.elbow,0,0),RightElbow=CFrame.Angles(r.elbow,0,0),LeftWrist=CFrame.identity,RightWrist=CFrame.identity}
    rig.stance={}
    rig.byJoint={}
    for key,cf in pairs(want)do local e=rig.joints[key];if e then rig.stance[key]=e.inv*cf*e.rot;rig.byJoint[e.j]=rig.stance[key];M.holders[e.j]=rig end end
    return rig
end
local function layer(rig,key,r)
    local e=rig.joints[key];if not e or not e.j.Parent then return end
    local base=e.j.Transform;if rig.base[e.j]==nil then rig.base[e.j]=base end;e.j.Transform=e.inv*r*e.rot*base
end
local function restore(rig)
    for j,base in pairs(rig.base)do if j.Parent then j.Transform=base end;rig.base[j]=nil end
end

local function stepRig(rig,c,hrp,hum,dt,own,reduced)
    local pos=hrp.Position
    local last=rig.pos;rig.pos=pos
    if not last or (pos-last).Magnitude>40 or dt<=0 then rig.vel=Vector3.zero;rig.acc=Vector3.zero;rig.fallPeak=0;return end
    local raw=(pos-last)/dt
    local vf=rig.vel or Vector3.zero
    local nv=vf:Lerp(Vector3.new(raw.X,0,raw.Z),1-math.exp(-dt*(own and 22 or 10)))
    rig.acc=(rig.acc or Vector3.zero):Lerp((nv-vf)/dt,1-math.exp(-dt*(own and 14 or 8)));rig.vel=nv
    local vy=if own then hrp.AssemblyLinearVelocity.Y else raw.Y
    local airborne=if own then hum.FloorMaterial==Enum.Material.Air else math.abs(raw.Y)>4
    if airborne then rig.fallPeak=math.max(rig.fallPeak,-vy)
    elseif rig.fallPeak>0 then rig.dipV+=S.landKick(rig.fallPeak);rig.fallPeak=0 end
    if reduced then rig.lean={0,0,0,0};rig.dip=0;rig.dipV=0;rig.head=0;rig.headV=0;return end
    local look=hrp.CFrame.LookVector;local right=hrp.CFrame.RightVector
    local a=rig.acc;local speed=nv.Magnitude
    local tp,tr=S.leanTarget(a:Dot(look),a:Dot(right),speed,hum.WalkSpeed,airborne)
    local l=rig.lean;local p=S.lean
    l[1],l[2]=S.spring(l[1],l[2],tp,p.omega,p.zeta,dt);l[3],l[4]=S.spring(l[3],l[4],tr,p.omega,p.zeta,dt)
    rig.dip,rig.dipV=S.spring(rig.dip,rig.dipV,0,S.land.omega,S.land.zeta,dt)
end

local function ride(rig,c,hrp,dt,reduced)
    local want=Vehicle.riders[c]and 1 or 0;local w=rig.ride or 0
    if reduced then w=want else w+=(want-w)*(1-math.exp(-dt*(want>w and S.ride.blendIn or S.ride.blendOut)))end
    if math.abs(w-want)<.002 then w=want end;rig.ride=w
    local steps=rig.want~=want and hrp:FindFirstChild("Running");rig.want=want
    if steps and steps:IsA("Sound")then
        local kept=steps:GetAttribute("RideVolume")
        if want==1 and not kept then steps:SetAttribute("RideVolume",steps.Volume);steps.Volume=0
        elseif want==0 and kept then steps.Volume=kept;steps:SetAttribute("RideVolume",nil)end
    end
    if w<=0 then return end
    local posing=M.posing
    for key,target in pairs(rig.stance)do
        local j=rig.joints[key].j
        if j.Parent and not(posing and posing[j])then
            local base=j.Transform;if rig.base[j]==nil then rig.base[j]=base end;j.Transform=base:Lerp(target,w)
        end
    end
end

function M.stance(j)
    local rig=M.holders[j];local w=rig and rig.ride
    if w and w>0 and rig.byJoint[j]then return rig.byJoint[j],w end
end

local function apply(rig)
    local l=rig.lean;local keep=1-(rig.ride or 0)*(1-S.ride.lean);local pitch,roll=l[1]*keep,l[3]*keep;local dip=rig.dip;local head=rig.head
    if math.abs(pitch)+math.abs(roll)+math.abs(dip)+math.abs(head)<1e-3 then return end
    local hipA,kneeA,drop,torso=0,0,0,0
    if rig.thigh and dip>0 then
        local a,b,d,t=S.legPose(dip,rig.thigh,rig.shin);hipA,kneeA,drop,torso=a,a+b,d,t
    end
    local p=pitch+torso
    layer(rig,"Root",CFrame.new(0,-drop,0)*CFrame.Angles(-p,0,-roll))
    if hipA~=0 or p~=0 then
        local hip=CFrame.Angles(hipA+torso+pitch*.5,0,0)
        layer(rig,"LeftHip",hip);layer(rig,"RightHip",hip)
        if kneeA~=0 then local knee=CFrame.Angles(-kneeA,0,0);layer(rig,"LeftKnee",knee);layer(rig,"RightKnee",knee)end
    end
    if head~=0 or p~=0 then layer(rig,"Neck",CFrame.Angles(p*.6,head,roll*.4))end
end

local function turnOwn(rig,c,hrp,hum,dt,reduced)
    local move=hum.MoveDirection
    local shiftLock=gameSettings and gameSettings.RotationType==Enum.RotationType.CameraRelative
    local free=not shiftLock and not hum.Sit and not hum.PlatformStand
    if hum.AutoRotate~=not free then hum.AutoRotate=not free end
    local left=0
    if free and hum.WalkSpeed>0 and Vector2.new(move.X,move.Z).Magnitude>.01 then
        local look=hrp.CFrame.LookVector
        local yaw=S.yaw(look.X,look.Z);local new
        new,left=S.turn(yaw,S.yaw(move.X,move.Z),dt)
        if math.abs(new-yaw)>1e-4 then hrp.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(0,new,0)end
    elseif free and rig.face and not reduced and not(rig.vel and rig.vel.Magnitude>3)then
        local look=hrp.CFrame.LookVector;local yaw=S.yaw(look.X,look.Z);local new=S.turn(yaw,rig.face.to,dt)
        if math.abs(new-yaw)>1e-4 then hrp.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(0,new,0)end
    end
    local target=reduced and 0 or math.clamp(left*S.headLead,-S.headMax,S.headMax)
    rig.head,rig.headV=S.spring(rig.head,rig.headV,target,18,.7,dt)
end

local function face(rig,hrp,dt,reduced)
    local f=rig.face;if not f then rig.yawOff=0;return end
    f.t+=dt
    local moving=rig.vel and rig.vel.Magnitude>3
    if reduced then f.hold=G.hold elseif moving then f.hold+=dt*4 elseif f.t>=f.dur and not rig.g then f.hold+=dt end
    local w=math.clamp((G.hold-f.hold)/.3,0,1)
    if w<=0 then rig.face=nil;rig.yawOff=0;return end
    local look=hrp.CFrame.LookVector
    rig.yawOff=S.wrap(G.turnYaw(f.from,f.to,f.t/f.dur)-S.yaw(look.X,look.Z))*w
end
local function gesture(rig,dt,reduced)
    local g=rig.g;local ch=rig.ch
    if ch then table.clear(ch)end
    if not g then return nil end
    if reduced then rig.g=nil;return nil end
    g.t+=dt;ch=ch or {};rig.ch=ch
    if not G.sample(g.kind,g.t,ch)then rig.g=nil;return nil end
    return ch
end
local function unposed(rig,key)local e=rig.joints[key];local posing=M.posing;return e and not(posing and posing[e.j])end
local function pose(rig,ch)
    local yaw=(rig.yawOff or 0)+(ch and ch.spin or 0)
    if not ch and math.abs(yaw)<1e-3 then return end
    local s=rig.legScale or 1
    local root=CFrame.Angles(0,yaw,0);if ch then root*=CFrame.new(0,(ch.y or 0)*s,-(ch.lunge or 0)*s)end
    layer(rig,"Root",root)
    if not ch then return end
    if unposed(rig,"Waist")and(ch.twist or ch.lean)then layer(rig,"Waist",CFrame.Angles(0,ch.twist or 0,0)*CFrame.Angles(-(ch.lean or 0),0,0))end
    if unposed(rig,"RightHip")and ch.rHip then layer(rig,"RightHip",CFrame.Angles(ch.rHip,0,0))end
    if unposed(rig,"LeftHip")and ch.lHip then layer(rig,"LeftHip",CFrame.Angles(ch.lHip,0,0))end
    local w=G.armWeight(rig.g.kind,rig.g.t);if w<=0 then return end
    for key,r in pairs({RightShoulder=CFrame.Angles(ch.rSx or 0,0,0)*CFrame.Angles(0,0,ch.rSz or 0),LeftShoulder=CFrame.Angles(ch.lSx or 0,0,0)*CFrame.Angles(0,0,ch.lSz or 0),
        RightElbow=CFrame.Angles(ch.rE or 0,0,0),LeftElbow=CFrame.Angles(ch.lE or 0,0,0)})do
        local e=rig.joints[key]
        if e and e.j.Parent and unposed(rig,key)then
            local base=e.j.Transform;if rig.base[e.j]==nil then rig.base[e.j]=base end;e.j.Transform=base:Lerp(e.inv*r*e.rot,w)
        end
    end
end
function M.gesture(c,kind,target)
    local rig=c and M.rigs[c];local hrp=c and c:FindFirstChild("HumanoidRootPart")
    if not M.enabled or not rig or not rig.joints or not hrp or not G.kinds[kind]then return false,0 end
    local prev=rig.g;local at=G.start(kind,prev and prev.kind,prev and prev.t)
    rig.g={kind=kind,t=at}
    local d=target and target-hrp.Position
    if d and d.X*d.X+d.Z*d.Z>1 then
        local look=hrp.CFrame.LookVector;local now=S.yaw(look.X,look.Z)+(rig.yawOff or 0)
        rig.face={from=now,to=S.yaw(d.X,d.Z),t=0,dur=at>0 and G.turn.jab or G.turn.time,hold=0}
    elseif rig.face then rig.face.hold=0 end
    return true,at
end

function M.start()
    if M.started then return end;M.started=true
    local me=Players.LocalPlayer
    RunService.PreAnimation:Connect(function()for c,rig in pairs(M.rigs)do if not c.Parent then M.rigs[c]=nil elseif rig.base then restore(rig)end end end)
    RunService.PreSimulation:Connect(function(dt)
        local camera=workspace.CurrentCamera;local eye=camera and camera.CFrame.Position
        local reduced=me:GetAttribute('CommanderReducedEffects')==true or not M.enabled
        for _,player in ipairs(Players:GetPlayers())do
            local c=player.Character;local hrp=c and c:FindFirstChild("HumanoidRootPart");local hum=c and c:FindFirstChildOfClass("Humanoid")
            local own=player==me
            if not hrp or not hum or hrp.Anchored or hum.Health<=0 or (not own and eye and (hrp.Position-eye).Magnitude>(Vehicle.riders[c]and 180 or M.range))then
                if c and M.rigs[c]then local r=M.rigs[c];r.pos=nil;r.g=nil;r.face=nil end;continue
            end
            local rig=M.rigs[c]
            if rig and rig.retry and os.clock()<rig.retry then continue end
            local now=os.clock()
            if rig and not rig.retry and rig.thigh and now>=(rig.scaleCheck or 0)then
                rig.scaleCheck=now+.5;local ok,s=pcall(c.GetScale,c);if ok and math.abs(s-rig.legScale)>1e-3 then rig.carry=true end
            end
            if not rig or rig.retry or rig.carry or not rig.joints.Root.j.Parent then
                local old=rig and rig.carry and rig
                rig=build(c);if not rig then M.rigs[c]={retry=now+2};continue end;M.rigs[c]=rig
                if old then for _,k in ipairs({'pos','vel','acc','lean','dip','dipV','head','headV','fallPeak','ride'})do rig[k]=old[k]end;rig.scaleCheck=old.scaleCheck end
            end
            stepRig(rig,c,hrp,hum,dt,own,reduced)
            if own then turnOwn(rig,c,hrp,hum,dt,reduced)end
            ride(rig,c,hrp,dt,reduced)
            apply(rig)
            face(rig,hrp,dt,reduced);pose(rig,gesture(rig,dt,reduced))
        end
    end)
end
return M
