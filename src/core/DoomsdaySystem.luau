-- SPDX-License-Identifier: AGPL-3.0-only
local D=if script then require(script.Parent.DoomsdayRules) else require("./DoomsdayRules")
local M={};M.__index=M
function M.new(w) return setmetatable({w=w,rotState={}},M) end
local function lowest(list,n)
    table.sort(list,function(a,b)return a.key<b.key or a.key==b.key and a.order<b.order end)
    local out={};for i=1,math.min(n,#list) do out[i]=list[i].tile end;return out
end
function M:consume(p,t,st)
    if not p.tiles:has(t) then return false end
    self.w.sim:relinquish(t);if not self.w.sim.fallout[t] then self.w.sim.fallout[t]=true;self.w.falloutTiles=(self.w.falloutTiles or 0)+1 end
    p.rotted=true;st.front[t]=nil
    for _,n in ipairs(self.w.sim:neighbors(t)) do if p.tiles:has(n) then
        if not st.front[n] then st.serial+=1;st.order[n]=st.serial end
        st.front[n]=(st.front[n] or 0)+1
    end end;return true
end
function M:speckle(p,n,st)
    if n<=0 then return 0 end
    local edge,inside={},{};local width=self.w.map.meta.width;local order=0
    p.tiles:forEach(function(t) order+=1;table.insert(p.border:has(t) and edge or inside,{tile=t,key=D.speckle(t%width,math.floor(t/width),p.id),order=order}) end)
    local picked=lowest(inside,n);if #picked<n then for _,t in ipairs(lowest(edge,n-#picked)) do table.insert(picked,t) end end
    local opened=0;for _,t in ipairs(picked) do if self:consume(p,t,st) then opened+=1 end end;return opened
end
function M:rot(p,under)
    local c=D.config;local owned=p.tiles.size;if owned<=0 then return end
    local st=self.rotState[p.id] or {since=self.w.sim.ticks,held=owned,front={},order={},serial=0}
    for t in pairs(st.front) do if not p.tiles:has(t) then st.front[t]=nil end end
    local specks=self.w.sim.ticks-st.since<c.rotGrainSeconds*10 and math.max(1,math.ceil(st.held*c.rotSpecklePercent/100/c.rotGrainSeconds)) or 0
    local budget=math.min(owned,math.max(D.quota(owned,under),specks))
    budget-=self:speckle(p,math.min(specks,budget),st)
    local front={};for t,rotted in pairs(st.front) do table.insert(front,{tile=t,key=rotted*65536+D.front(t,p.id),order=st.order[t]}) end
    for _,t in ipairs(lowest(front,budget)) do if self:consume(p,t,st) then budget-=1 end end
    if budget>0 then self:speckle(p,budget,st) end;self.rotState[p.id]=st
end
function M:tick()
    local w=self.w;if not w.settings.doomsdayClock or w.sim.ticks%10~=0 then return end
    local sides,byTeam={},{};local teamGame=false
    for _,p in ipairs(w.sim.players) do if p.kind~="BOT" and p.tiles.size>0 then
        if p.team then teamGame=true;if not byTeam[p.team] then byTeam[p.team]={};table.insert(sides,byTeam[p.team]) end;table.insert(byTeam[p.team],p)
        else table.insert(sides,{p}) end
    end end
    local c=D.config;local required=D.required({speed=w.settings.doomsdayClockSpeed or "normal",teamGame=teamGame},math.max(0,w:landTiles()-(w.falloutTiles or 0)),w.sim.ticks/10)
    local leader,maxTiles,totals=1,-1,{}
    for i,side in ipairs(sides) do local total=0;for _,p in ipairs(side) do total+=p.tiles.size end;totals[i]=total;if total>maxTiles then leader=i;maxTiles=total end end
    for i,side in ipairs(sides) do for _,p in ipairs(side) do
        if #sides>1 and i~=leader and totals[i]<required then
            p.doomed=true;p.doomedAt=p.doomedAt or w.sim.ticks;local under=math.floor((w.sim.ticks-p.doomedAt)/10)
            if under>=c.warnSeconds then
                local past=under-c.warnSeconds;local maximum=w:maxTroops(p.id);local floor=D.floor(maximum,past)
                w.sim:removeTroops(p.id,math.min(D.drain(maximum,past),math.max(0,p.troops-floor)))
                if past>=c.floorDecaySeconds and p.troops<=floor then self:rot(p,under) end
                local fleet=table.clone(c);fleet.drainStartPercent=c.warshipDrainStartPercent;fleet.drainMaxPercent=c.warshipDrainMaxPercent
                for _,u in ipairs(w.units) do if u.active and u.owner==p.id and u.kind=="Warship" then u.health-=math.min(D.drain(u.maxHealth,past,fleet,c.warshipDrainCurveExponent),math.max(0,u.health-math.floor(u.maxHealth*c.drainFloorPercent/100))) end end
            end
        else p.doomed=false;p.doomedAt=nil;p.rotted=false;self.rotState[p.id]=nil end
    end end
    self.required=required
end
return M
