local M={};M.__index=M
M.TIME=.24;M.GLOW=.3;M.FADE=.12;M.FROM=.7;M.PEAK=1.08;M.CAP=6;M.GLOWS=4
M.GLOW_COLOR=Color3.fromRGB(191,255,248)
M.WAIT=.5
local BACK=3.13
function M.ease(p)local x=p-1;return 1+(BACK+1)*x*x*x+BACK*x*x end
function M.size(p)return M.FROM+(1-M.FROM)*M.ease(math.clamp(p,0,1))end
M.scale={};M.busy=false
local structures=require(script.Parent.Parent.Core.UnitRules).structures
function M.new(world)
    return setmetatable({world=world,seen={},spare={},pops={},count=0,glows={}},M)
end
function M:reset()
    for _,p in ipairs(self.pops)do self:finish(p)end;table.clear(self.pops);self.count=0
    table.clear(self.seen);self.tick=nil;table.clear(M.scale);M.busy=false
end
function M:observe(state)
    local seen,now=self.seen,self.spare;table.clear(now)
    local last=self.tick
    for _,u in ipairs(state.units or {})do if structures[u.kind]then
        local was=seen[u.id];local building=u.building==true;now[u.id]=building
        if last and not building and #self.pops<M.CAP and (was==true or was==nil and (u.assemblyStartedTick or u.createdTick or -1)>=last)then
            table.insert(self.pops,{id=u.id,owner=u.owner,tile=u.tile,seen=os.clock()})
        end
    end end
    self.seen,self.spare=now,seen;self.tick=state.tick
end
function M:glow(model)
    for _,g in ipairs(self.glows)do if not g.Adornee then g.Adornee=model;g.OutlineTransparency=0;g.Enabled=true;return g end end
    if #self.glows>=M.GLOWS then return nil end
    local g=Instance.new('Highlight');g.Name='BuildGlow';g.FillTransparency=1;g.OutlineColor=M.GLOW_COLOR;g.OutlineTransparency=0
    g.DepthMode=Enum.HighlightDepthMode.Occluded;g.Adornee=model;g.Parent=self.world.folder;table.insert(self.glows,g);return g
end
function M:finish(p)
    local model=p.model
    if model and model.Parent then
        if p.base then model:ScaleTo(p.base)end
        if p.parts then for i,part in ipairs(p.parts)do if part.Parent then part.Transparency=p.alpha[i]end end end
    end
    if p.light then p.light.Adornee=nil;p.light.Enabled=false end
    M.scale[p.id]=nil
end
function M:step(now,size,reduced)
    local pops=self.pops;if #pops==0 then if M.busy then M.busy=false end;return end
    local i=1
    while i<=#pops do
        local p=pops[i];local done=false
        if not p.model then
            local model=self.world.units and self.world.units[p.id]
            if model then
                local at=self.world:project(p.tile,2,true)
                if at.X<-64 or at.Y<-64 or at.X>size.X+64 or at.Y>size.Y+64 then done=true
                else
                    p.model=model;p.t0=now
                    if p.owner==1 then pcall(function()require(script.Parent.ToyAudio).play('build',.8)end)end
                    if reduced then
                        p.parts={};p.alpha={}
                        for _,d in ipairs(model:GetDescendants())do if d:IsA('BasePart')then table.insert(p.parts,d);table.insert(p.alpha,d.Transparency);d.Transparency=1 end end
                    else p.base=model:GetScale();p.light=self:glow(model)end
                end
            elseif now-p.seen>M.WAIT then done=true end
        end
        if p.model and not done then
            local model=p.model;local t=now-p.t0
            if not model.Parent then done=true
            elseif p.parts then
                local k=math.min(1,t/M.FADE)
                for j,part in ipairs(p.parts)do part.Transparency=1-(1-p.alpha[j])*k end
                done=k>=1
            else
                local s=M.size(t/M.TIME)
                if t<M.TIME then model:ScaleTo(p.base*s);M.scale[p.id]=s elseif M.scale[p.id]then model:ScaleTo(p.base);M.scale[p.id]=nil end
                if p.light then p.light.OutlineTransparency=math.min(1,t/M.GLOW)end
                done=t>=math.max(M.TIME,M.GLOW)
            end
        end
        if done then self:finish(p);table.remove(pops,i)else i+=1 end
    end
    M.busy=next(M.scale)~=nil
end
return M
