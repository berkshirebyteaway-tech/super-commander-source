local M={};M.__index=M
local function spring(x,v,target,omega,damping,dt)
    local y=x-target;local w=omega*math.sqrt(1-damping*damping)
    local e=math.exp(-damping*omega*dt);local c,s=math.cos(w*dt),math.sin(w*dt)
    local b=(v+damping*omega*y)/w
    return target+e*(y*c+b*s),e*(v*c-(damping*omega*b+w*y)*s)
end
M.spring=spring
function M.height(altitude)
    local a=math.clamp(altitude,0,1)
    local t,start,finish,m0,m1
    if a>=.58 then t=(1-a)/.42;start=1;finish=.36;m0=0;m1=-1.3*.42
    else t=(.58-a)/.58;start=.36;finish=0;m0=-1.3*.58;m1=-.18*.58 end
    local t2,t3=t*t,t*t*t
    return math.clamp((2*t3-3*t2+1)*start+(t3-2*t2+t)*m0+(-2*t3+3*t2)*finish+(t3-t2)*m1,0,1)
end
function M.clock(state,raw,dt,hold)
    local c=state.clock
    if c==nil or math.abs(raw-c)>.35 then c=raw
    else
        local n=hold and c or c+dt;n+=(raw-n)*(1-math.exp(-math.max(dt,0)*4))
        c=hold and n or math.max(c,n)
    end
    state.clock=c;return c
end
function M.heldTurn(state,x,y,z,angle,share)
    local a=angle*share
    if state.w then
        local dot=x*state.x+y*state.y+z*state.z
        local h1,h2=a/2,(2*math.pi-angle)*share/2
        if math.cos(h2)*state.w-dot*math.sin(h2)>math.cos(h1)*state.w+dot*math.sin(h1)then x,y,z,a=-x,-y,-z,h2*2 end
    end
    local s=math.sin(a/2);state.w,state.x,state.y,state.z=math.cos(a/2),x*s,y*s,z*s
    return x,y,z,a
end
function M.new(seed)
    return setmetatable({open=0,openV=0,bank=0,bankV=0,pitch=-1.1,pitchV=0,heading=0,vx=0,vz=0,time=0,seed=seed or 1,deployAge=0,landAge=0},M)
end
function M:step(dt,input)
    dt=math.clamp(dt,0,.1);if input.paused then dt=0 end
    self.time+=dt
    local vx,vz=input.vx or 0,input.vz or 0
    local a=1-math.exp(-dt*9);self.vx+=(vx-self.vx)*a;self.vz+=(vz-self.vz)*a
    local speed=math.sqrt(self.vx*self.vx+self.vz*self.vz)
    local delta=0
    if speed>.025 then
        local desired=math.atan2(-self.vx,-self.vz)
        delta=(desired-self.heading+math.pi)%(2*math.pi)-math.pi
        self.heading+=delta*(1-math.exp(-dt*5))
    end
    local airborne=input.airborne~=false
    if airborne and (input.altitude or 1)<.58 and not self.deployed then self.deployed=true;self.deployAge=0 end
    if self.deployed then self.deployAge+=dt end
    if input.landed and not self.landed then self.landed=true;self.landAge=0 end
    if self.landed then self.landAge+=dt end
    local target=self.deployed and not self.landed and 1 or 0
    self.open,self.openV=spring(self.open,self.openV,target,self.landed and 15 or 17,.62,dt)
    local inflation=math.clamp(self.open,0,1.065)
    local swing=not input.reduced and self.deployed and not self.landed and math.sin(self.time*2.6+self.seed)*.028 or 0
    local bank=math.clamp(delta*.18,-.26,.26)
    if input.reduced then bank*=.35 end
    self.bank,self.bankV=spring(self.bank,self.bankV,bank,8,.72,dt)
    local pitch=self.landed and 0 or self.deployed and (.06+speed*.10)or (input.diving and -1.32 or -1.1)
    local hanging=self.deployed and not self.landed and not input.reduced
    local settle=hanging and math.clamp(self.deployAge/3,0,1)or 1
    self.pitch,self.pitchV=spring(self.pitch,self.pitchV,pitch,hanging and 7+5*settle or 12,hanging and .28+.44*settle or .72,dt)
    local pop=self.deployed and not self.landed and math.sin(math.min(1,self.deployAge/.7)*math.pi)*math.exp(-self.deployAge*2.7)or 0
    local landing=self.landed and math.sin(math.min(1,self.landAge/.35)*math.pi)*math.exp(-self.landAge*3)or 0
    self.speed=math.clamp(speed,0,1);self.steer=math.clamp(delta,-1,1);self.diving=input.diving==true
    local buffet=airborne and not self.deployed and not input.reduced and math.noise(self.time*1.4,self.seed*.37,.5)or 0
    self.inflation=inflation;self.bodyPitch=self.pitch+buffet*.05;self.bodyRoll=self.bank*.9+swing+buffet*.06
    self.canopyRoll=-self.bank*1.35-swing*.65;self.canopyPitch=-speed*.09
    self.bodyLift=input.reduced and 0 or pop*1.3-landing*.4
    self.cameraKick=input.reduced and 0 or pop*1.8
    self.visible=airborne and not self.landed and self.deployed or self.landed and self.landAge<.38 and inflation>.035
    return self
end
return M
