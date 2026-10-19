local M={}
M.lean={omega=13,zeta=.55,pitchPerAccel=math.rad(1.1),rollPerAccel=math.rad(1.3),maxPitch=math.rad(10),maxRoll=math.rad(11),runPitch=math.rad(4),air=.35}
M.land={omega=15,zeta=.6,minFall=14,fullFall=55,kick=35,hip=math.rad(30),torso=math.rad(9),maxDip=1.15}
M.turnRate=16
M.headLead=.55;M.headMax=math.rad(40)
M.ride={hip=math.rad(12),knee=math.rad(22),shoulder=math.rad(34),elbow=math.rad(30),inward=math.rad(7),waist=math.rad(4),lean=.45,blendIn=12,blendOut=9}
function M.rideLegs(thigh,shin)
    local r=M.ride;local s=r.knee-r.hip
    return r.hip,r.knee,s,thigh*(1-math.cos(r.hip))+shin*(1-math.cos(s))
end

function M.spring(x,v,target,omega,zeta,dt)
    local steps=math.max(1,math.ceil(dt*120));local h=dt/steps
    for _=1,steps do v+=(-2*zeta*omega*v-omega*omega*(x-target))*h;x+=v*h end
    return x,v
end

function M.leanTarget(accelF,accelR,speed,walkSpeed,airborne)
    local p=M.lean;local ref=math.max(walkSpeed or 16,8);local share=airborne and p.air or 1
    local pitch=math.clamp(accelF/ref*p.pitchPerAccel*share+p.runPitch*math.min(1,speed/ref),-p.maxPitch,p.maxPitch)
    local roll=math.clamp(accelR/ref*p.rollPerAccel*share,-p.maxRoll,p.maxRoll)
    return pitch,roll
end

function M.landKick(fallSpeed)
    local p=M.land;local s=math.clamp((fallSpeed-p.minFall)/(p.fullFall-p.minFall),0,1)
    return s>0 and p.kick*(.35+.65*s) or 0
end

function M.legPose(dip,thigh,shin)
    local d=math.clamp(dip,0,M.land.maxDip)
    local a=d*M.land.hip
    local b=math.asin(math.clamp(thigh/math.max(shin,1e-3)*math.sin(a),-1,1))
    return a,b,thigh*(1-math.cos(a))+shin*(1-math.cos(b)),d*M.land.torso
end

function M.yaw(lx,lz)return math.atan2(-lx,-lz)end
function M.wrap(a)return (a+math.pi)%(2*math.pi)-math.pi end
function M.turn(current,desired,dt,rate)
    local left=M.wrap(desired-current);local step=left*(1-math.exp(-(rate or M.turnRate)*dt))
    return M.wrap(current+step),left-step
end
return M
