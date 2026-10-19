local Avatar=require(script.Parent.DropAvatar)
local spring=require(script.Parent.Parent.Core.DropMotion).spring
local M={};M.__index=M
local V=Vector3.new;local ZERO=Vector3.zero
local function role(name)
    if name:find('UpperArm')then return 'shoulder'elseif name:find('LowerArm')then return 'elbow'elseif name:find('Hand')then return 'wrist'
    elseif name:find('UpperLeg')then return 'hip'elseif name:find('LowerLeg')then return 'knee'elseif name:find('Foot')then return 'ankle'
    elseif name:find('Arm')then return 'shoulder'elseif name:find('Leg')then return 'hip'
    elseif name=='Head'then return 'neck'elseif name=='UpperTorso'then return 'waist'end
    return nil
end
local function compile(def)
    local out={waist0=def.waist or ZERO,neck0=def.neck or ZERO}
    for _,r in ipairs({'shoulder','elbow','wrist','hip','knee','ankle'})do
        local right=def.R and def.R[r]or def[r]or ZERO;local left=def.L and def.L[r]or def[r]or ZERO
        out[r..'1']=right;out[r..'-1']=V(left.X,-left.Y,-left.Z)
    end
    return out
end
local POSES={
    stand=compile({}),
    exit=compile({waist=V(-.3,0,0),neck=V(-.25,0,0),shoulder=V(.45,.2,2.35),elbow=V(0,0,.7),hip=V(.75,0,.18),knee=V(-1.25,0,0),ankle=V(-.2,0,0)}),
    box=compile({waist=V(.24,0,0),neck=V(.42,0,0),shoulder=V(0,-.38,1.32),elbow=V(0,0,1.45),wrist=V(0,0,.2),hip=V(-.24,0,.3),knee=V(-1.05,0,0),ankle=V(-.4,0,0)}),
    dive=compile({waist=V(.06,0,0),neck=V(.62,0,0),shoulder=V(-.3,-.75,.32),elbow=V(0,0,.12),wrist=V(-.2,0,0),hip=V(-.06,0,.05),knee=V(-.12,0,0),ankle=V(-.6,0,0)}),
    canopy=compile({waist=V(-.05,0,0),neck=V(-.32,0,0),R={shoulder=V(.25,0,2.15),elbow=V(0,0,.35)},L={shoulder=V(.15,0,2.6),elbow=V(0,0,.6)},hip=V(.38,0,.12),knee=V(-.55,0,0),ankle=V(.2,0,0)}),
    flare=compile({waist=V(.1,0,0),neck=V(-.2,0,0),R={shoulder=V(.3,0,1.6),elbow=V(0,0,.3)},L={shoulder=V(.55,0,.75),elbow=V(0,0,.2)},hip=V(.85,0,.1),knee=V(-.35,0,0),ankle=V(.25,0,0)}),
    land=compile({waist=V(-.42,0,0),neck=V(.38,0,0),R={shoulder=V(.2,0,1.05),elbow=V(0,0,.45),hip=V(.25,0,.1),knee=V(-1.75,0,0),ankle=V(.3,0,0)},
        L={shoulder=V(1.05,0,.3),elbow=V(-.25,0,0),hip=V(1.45,0,.12),knee=V(-1.5,0,0),ankle=V(.1,0,0)}}),
}
M.poses=POSES
local TUNE={waist0={10,.62},neck0={9,.55},shoulder={15,.4},elbow={17,.36},wrist={18,.4},hip={12,.44},knee={14,.4},ankle={16,.45}}
local function smooth(a,b,x)local t=math.clamp((x-a)/(b-a),0,1);return t*t*(3-2*t)end
function M.new(model)
    local data=Avatar.joints(model);local root=model.PrimaryPart
    if not data or not root or #data.bones==0 then return nil end
    local k=model:GetScale()/math.max(.01,data.scale or 1)
    local children={}
    for _,b in ipairs(data.bones)do if b.part0.Parent and b.part1.Parent then local c=children[b.part0];if not c then c={};children[b.part0]=c end;table.insert(c,b)end end
    local order={};local queue={root};local seen={[root]=true};local head=1
    while head<=#queue and head<=64 do
        local parent=queue[head];head+=1
        for _,b in ipairs(children[parent]or {})do if not seen[b.part1]then
            seen[b.part1]=true;table.insert(queue,b.part1)
            local name=b.part1.Name;local side=name:find('Left')and -1 or name:find('Right')and 1 or 0
            local r=role(name);local pivot=CFrame.new(b.pivot*k)
            local key=r and ((r=='waist'or r=='neck')and r..'0'or r..side)
            local tune=r and (TUNE[key]or TUNE[r])or {12,.5}
            table.insert(order,{part0=b.part0,part1=b.part1,pivot=pivot,back=pivot:Inverse()*b.part0.CFrame:ToObjectSpace(b.part1.CFrame),
                key=key,role=r,side=side,omega=tune[1],damping=tune[2],seed=#order*1.73,x=0,y=0,z=0,vx=0,vy=0,vz=0})
        end end
    end
    if #order==0 then return nil end
    return setmetatable({root=root,order=order,frames={},hip=math.max(1,(model:GetAttribute('GroundHeight')or 3)-root.Size.Y*.5),dive=0,lastTime=nil,wasLanded=false},M)
end
function M:step(motion,airborne)
    local t=motion.time or 0;local dt=math.clamp(t-(self.lastTime or t),0,.1);self.lastTime=t
    local reduced=motion.reducedEffects==true
    local w={}
    local open=math.clamp(motion.inflation or 0,0,1)
    if motion.landed then
        local a=motion.landAge or 0
        local crouch=a<.55 and 1 or 1-smooth(.55,1.15,a)
        w.land=crouch;w.stand=1-crouch
        if not self.wasLanded then self.wasLanded=true
            for _,j in ipairs(self.order)do
                if j.role=='knee'then j.vx-=8 elseif j.role=='hip'then j.vx+=6 elseif j.key=='waist0'then j.vx-=5 elseif j.role=='shoulder'then j.vz+=j.side*4 end
            end
        end
    elseif not airborne then w.stand=1
    else
        self.wasLanded=false
        local exit=motion.introT and 1-smooth(.1,.62,motion.introT)or 0
        self.dive+=((motion.diving and 1 or 0)-self.dive)*(1-math.exp(-dt*5))
        local near=math.clamp(motion.near or 0,0,1)
        local fall=1-open
        w.exit=fall*exit;w.box=fall*(1-exit)*(1-self.dive);w.dive=fall*(1-exit)*self.dive
        w.canopy=open*(1-near);w.flare=open*near
    end
    local free=(w.box or 0)+(w.dive or 0)
    local speed=motion.speed or 0;local steer=motion.steer or 0;local pitchV=math.clamp(motion.pitchV or 0,-12,12)
    local hang=w.canopy or 0
    for i,j in ipairs(self.order)do if j.key then
        local tx,ty,tz=0,0,0
        for name,weight in pairs(w)do if weight>0 then local p=POSES[name][j.key];if p then tx+=p.X*weight;ty+=p.Y*weight;tz+=p.Z*weight end end end
        if not reduced then
            local r=j.role
            local amp=(r=='elbow'or r=='wrist')and .11 or (r=='shoulder')and .07 or (r=='knee'or r=='ankle')and .07 or r=='hip'and .05 or .03
            local freq=(r=='elbow'or r=='wrist'or r=='ankle')and 6.5 or 3.6
            local gust=free*amp*(1+speed*.8+self.dive*.6)
            if gust>0 then
                tx+=gust*2*math.noise(t*freq,j.seed,1.3);tz+=gust*2*math.noise(t*freq,j.seed,7.1)
            end
            if hang>0 and (r=='hip'or r=='knee')then tx+=hang*(.1*math.sin(t*1.9+j.side*.8)+(r=='hip'and -.25*steer*j.side or 0))end
            if hang>0 and r=='shoulder'and j.side==-1 then tz-=hang*math.max(0,steer)*.9 end
            if r=='hip'or r=='knee'or r=='shoulder'then tx-=pitchV*(r=='knee'and .05 or .08)end
        end
        local dtj=reduced and dt*1.6 or dt
        local omega=j.omega*((j.role=='hip'or j.role=='knee')and (1-.35*hang)or 1)
        j.x,j.vx=spring(j.x,j.vx,tx,omega,j.damping,dtj)
        j.y,j.vy=spring(j.y,j.vy,ty,omega,j.damping,dtj)
        j.z,j.vz=spring(j.z,j.vz,tz,omega,j.damping,dtj)
        if j.x~=j.x or math.abs(j.x)>6 then j.x,j.vx,j.y,j.vy,j.z,j.vz=tx,0,ty,0,tz,0 end
    end end
    self.drop=(w.land or 0)*self.hip*.5
    return self
end
function M:apply(cf,place)
    local frames=self.frames
    local rootCF=self.drop and self.drop>0 and cf*CFrame.new(0,-self.drop,0)or cf
    frames[self.root]=rootCF;place(self.root,rootCF)
    for _,j in ipairs(self.order)do
        local parent=frames[j.part0]
        if parent then
            local at=j.key and parent*j.pivot*CFrame.Angles(j.x,j.y,j.z)*j.back or parent*j.pivot*j.back
            frames[j.part1]=at;place(j.part1,at)
        end
    end
    return rootCF
end
function M:frame(part)return self.frames[part]end
return M
