-- SPDX-License-Identifier: AGPL-3.0-only
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local F=if script then require(script.Parent.FlightPath) else require("./FlightPath")
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local D=if script then require(script.Parent.DetMath) else require("./DetMath")
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local Aim=if script then require(script.Parent.NuclearAimModel)else require('./NuclearAimModel')
local M={};M.__index=M
function M.new(system) return setmetatable({s=system,w=system.w,nav=system.nav,data={}},M) end
function M:readySilo(owner,tile)
    return Aim.readySilo(self.w,owner,tile)
end
function M:canLaunch(owner,kind,tile)
    if self.w.sim.ticks<(self.w.settings.spawnImmunityDuration or 50) then return false,"보호 시간" end
    if not self.nav:valid(tile) or T.isImpassable(self.w.sim.terrain[tile+1]) or U.disabled(self.w.settings,kind) then return false,"발사할 수 없는 목표" end
    local w=self.w;local target=w.sim:owner(tile);local p,q=w.sim.players[owner],w.sim.players[target]
    if kind=="MIRV" and target==0 then return false,"상대 영토 선택" end
    if p.team and q and q.team==p.team then return false,"같은 팀" end
    if p.team and kind~="MIRV" then local _,outer=U.magnitude(kind)
        for _,u in ipairs(w.units) do if u.active and U.structures[u.kind] and w.sim.players[u.owner].team==p.team and w:distance2(u.tile,tile)<=outer*outer then return false,"범위에 같은 팀 건물" end end
    end
    local silo=self:readySilo(owner,tile);if not silo then return false,"사일로 필요" end
    return true,silo
end
function M:flight(kind,owner,src,dst,speed,wait,up)
    local m=self.w.map.meta;local u=self.s:create(kind,owner,src,{sourceTile=src,targetTile=dst,target=self.w.sim:owner(dst),waitTicks=wait or 0})
    self.data[u.id]={path=F.parabola(m.width,m.height,src,dst,speed or U.nukeSpeed(kind),up),index=1}
    return u
end
function M:launch(owner,kind,tile,options)
    local valid,silo=self:canLaunch(owner,kind,tile);if not valid then return false,silo end
    if options and not options.any then
        if options.silo~=silo.id then return false,'발사 시설 변경'end
        local stamp=table.concat(Aim.breakList(self.w,owner,kind,tile),',')
        if options.relationStamp~=stamp then return false,'동맹 변경, 다시 확인'end
    end
    if not self.s:pay(owner,kind) then return false,"골드 부족" end
    local tick=self.w.sim.ticks;local wait=0;local last=0
    for _,t in ipairs(silo.missileQueue or {}) do last=math.max(t+1,last+1) end;wait=math.max(0,last-tick)
    silo.missileQueue=silo.missileQueue or {};table.insert(silo.missileQueue,tick)
    local u
    if kind=="MIRV" then
        self.s.mirvsLaunched+=1;local m=self.w.map.meta
        local sep=math.clamp(math.max(0,math.floor(tile/m.width)-500)+50,0,m.height-1)*m.width+math.floor((tile%m.width+silo.tile%m.width)/2)
        u=self:flight(kind,owner,silo.tile,sep,F.mirvSpeed(m.width,m.height,silo.tile,sep),0)
        u.targetTile=tile;u.target=self.w.sim:owner(tile)
        local d=self.data[u.id];d.separate=sep;d.random=R.new(tick+owner);d.targets={tile};d.children={}
        if self.w:friendly(owner,u.target) and owner~=u.target then self.w:breakAlliance(owner,u.target) end
        if u.target~=0 and u.target~=owner then self.w:changeRelation(u.target,owner,-100);self.w:changeRelation(owner,u.target,-100) end
    else u=self:flight(kind,owner,silo.tile,tile,nil,wait,options and options.up);self:breakAlliances(u) end
    self.s:effect("launch",silo.tile,owner,{targetTile=tile,unitId=u.id,weapon=kind})
    return true,U.names[kind].." 발사"
end
M.maxStack=50
function M:launchMany(owner,kind,tile,options,amount)
    local ok,message=self:launch(owner,kind,tile,options);if not ok or kind~='AtomBomb'then return ok,message end
    local launched=1
    for _=2,math.clamp(amount or 1,1,M.maxStack)do
        if not self:launch(owner,kind,tile,{any=true,up=options and options.up})then break end;launched+=1
    end
    return true,launched>1 and string.format('%s %d발 발사',U.names[kind],launched)or message
end
function M:breakAlliances(u)
    local inner,outer=U.magnitude(u.kind);local counts={};local w=self.w;local width,height=w.map.meta.width,w.map.meta.height
    local cx,cy=u.targetTile%width,math.floor(u.targetTile/width)
    for y=math.max(0,cy-outer),math.min(height-1,cy+outer) do for x=math.max(0,cx-outer),math.min(width-1,cx+outer) do
        local dist=(x-cx)^2+(y-cy)^2;local owner=w.sim:owner(y*width+x)
        if owner~=0 and owner~=u.owner and dist<=outer*outer then counts[owner]=(counts[owner] or 0)+(dist<=inner*inner and 1 or .5) end
    end end
    for _,v in ipairs(w.units) do if v.active and U.structures[v.kind] and v.owner~=u.owner and w:distance2(v.tile,u.targetTile)<=outer*outer then counts[v.owner]=100 end end
    for id,count in pairs(counts) do if count>=100 then
        w:breakAlliance(u.owner,id);w:changeRelation(id,u.owner,-100)
        local key=math.min(id,u.owner)..":"..math.max(id,u.owner);w.requests[key]=nil
    end end
end
function M:blastTiles(u)
    local w=self.w;local inner,outer=U.magnitude(u.kind);local random=R.new(w.sim.ticks)
    if not w.settings.waterNukes then return w:flood(u.targetTile,function(t)
        local d=w:distance2(t,u.targetTile);return d<=outer*outer and (d<=inner*inner or random:chance(2)) and not T.isImpassable(w.sim.terrain[t+1])
    end) end
    local radii,smoothed={},{}
    for i=1,16 do radii[i]=random:nextFloat(inner*inner,outer*outer) end
    for i=1,16 do smoothed[i]=radii[i]*.6+radii[(i-2)%16+1]*.2+radii[i%16+1]*.2 end
    local out={};local width,height=w.map.meta.width,w.map.meta.height;local cx,cy=u.targetTile%width,math.floor(u.targetTile/width)
    for y=math.max(0,cy-outer),math.min(height-1,cy+outer) do for x=math.max(0,cx-outer),math.min(width-1,cx+outer) do
        local dx,dy=x-cx,y-cy;local d=dx*dx+dy*dy;if d>outer*outer then continue end
        if d>inner*inner then local a=((D.atan2 and D.atan2(dy,dx) or math.atan2(dy,dx))+math.pi)/(2*math.pi)*16;local i=math.floor(a);local f=a-i;if d>smoothed[i%16+1]*(1-f)+smoothed[(i+1)%16+1]*f then continue end end
        local tile=y*width+x;if not T.isImpassable(w.sim.terrain[tile+1]) then table.insert(out,tile) end
    end end;return out
end
function M:detonate(u)
    local w=self.w;local impacted={};local before={}
    for _,t in ipairs(self:blastTiles(u)) do
        local id=w.sim:owner(t)
        if id~=0 then before[id]=before[id] or w.sim.players[id].tiles.size;impacted[id]=(impacted[id] or 0)+1;w.sim:relinquish(t);w.nukedAt=w.nukedAt or {};w.nukedAt[id]=w.sim.ticks end
        if self.nav:land(t) then
            if w.settings.waterNukes then
                self.nav:queueWater(t)
            elseif not w.sim.fallout[t] then w.sim.fallout[t]=true;w.sim.falloutRevision=(w.sim.falloutRevision or 0)+1;w.falloutTiles=(w.falloutTiles or 0)+1 end
        end
    end
    for id,count in pairs(impacted) do
        local p=w.sim.players[id];local cap=w:maxTroops(id);local transports={}
        for _,v in ipairs(w.units) do if v.active and v.owner==id and v.kind=="TransportShip" then table.insert(transports,v) end end
        for i=0,count-1 do
            w.sim:removeTroops(id,U.nukeDeaths(u.kind,p.troops,before[id]-i,cap))
            for _,a in ipairs(p.outgoing) do a.troops=math.max(0,a.troops-U.nukeDeaths(u.kind,a.troops,before[id]-i,cap)) end
            for _,boat in ipairs(transports) do boat.troops=math.max(0,boat.troops-U.nukeDeaths(u.kind,boat.troops,before[id]-i,cap)) end
        end
    end
    local _,outer=U.magnitude(u.kind)
    for _,v in ipairs(w.units) do if v.active and not U.nukes[v.kind] and v.kind~="SAMMissile" and w:distance2(v.tile,u.targetTile)<outer*outer then v.active=false;self.s.naval:lost(v) end end
    u.active=false;self.s:effect("detonate",u.targetTile,u.owner,{radius=outer,weapon=u.kind})
end
function M:cancelBetween(a,b)
    local cancelled,counts={},{}
    for _,u in ipairs(self.w.units) do
        if not u.active or not U.nukes[u.kind] or (u.owner~=a and u.owner~=b) then continue end
        local other=u.owner==a and b or a;local hit=false
        if u.kind=="MIRV" then hit=u.target==other
        elseif u.kind=="MIRVWarhead" then hit=self.w.sim:owner(u.targetTile)==other
        else
            local inner,outer=U.magnitude(u.kind);local count=0;local width,height=self.w.map.meta.width,self.w.map.meta.height
            local cx,cy=u.targetTile%width,math.floor(u.targetTile/width)
            for y=math.max(0,cy-outer),math.min(height-1,cy+outer) do for x=math.max(0,cx-outer),math.min(width-1,cx+outer) do
                local d=(x-cx)^2+(y-cy)^2;if d<=outer*outer and self.w.sim:owner(y*width+x)==other then count+=d<=inner*inner and 1 or .5 end
            end end
            hit=count>=100
            if not hit then for _,v in ipairs(self.w.units) do if v.active and U.structures[v.kind] and v.owner==other and self.w:distance2(v.tile,u.targetTile)<=outer*outer then hit=true;break end end end
        end
        if hit then u.active=false;cancelled[u.id]=true;counts[u.owner]=(counts[u.owner] or 0)+1 end
    end
    for _,u in ipairs(self.w.units) do if u.active and u.carrier and cancelled[u.carrier] then u.active=false end end
    for _,pairing in ipairs({{a,b},{b,a}}) do
        local launcher,other=pairing[1],pairing[2];local n=counts[launcher]
        if n then
            local launcherName,otherName=self.w.resources[launcher].name,self.w.resources[other].name
            self.w:notify(launcher,string.format("%s 동맹  내 로켓 %d발 해제",otherName,n),"diplomacy")
            self.w:notify(other,string.format("%s 동맹  날아오던 로켓 %d발 해제",launcherName,n),"diplomacy")
        end
    end
end
local function targetIndex(d,width,height)
    local points=d.targets;local index=d.targetIndex;local count=#points
    if not index or index.points~=points or index.width~=width or index.height~=height or index.count>count then
        index={points=points,width=width,height=height,count=0,cells={},columns=math.ceil(width/55),rows=math.ceil(height/55)};d.targetIndex=index
    end
    for i=index.count+1,count do local t=points[i];local key=(t//width//55)*index.columns+(t%width)//55
        local cell=index.cells[key];if not cell then cell={};index.cells[key]=cell end;table.insert(cell,t)
    end
    index.count=count;return index
end
local function nearTarget(nav,index,tile)
    local x,y=(tile%index.width)//55,(tile//index.width)//55
    for cy=math.max(0,y-1),math.min(index.rows-1,y+1)do
        for cx=math.max(0,x-1),math.min(index.columns-1,x+1)do local cell=index.cells[cy*index.columns+cx]
            if cell then for _,t in ipairs(cell)do if nav:manhattan(t,tile)<55 then return true end end end
        end
    end
    return false
end
function M:tryTarget(u,d)
    local w=self.w;local width,height=w.map.meta.width,w.map.meta.height;local bx,by=u.targetTile%width,math.floor(u.targetTile/width);local index=#d.targets>=32 and targetIndex(d,width,height)or nil
    if not index then d.targetIndex=nil end
    for _=1,100 do
        local a=d.random:next();local b=(a*15485863)%1;local x,y=math.floor(a*3000-1500+bx+.5),math.floor(b*3000-1500+by+.5)
        if x<0 or y<0 or x>=width or y>=height or (x-bx)^2+(y-by)^2>2250000 then continue end
        local tile=y*width+x;if not self.nav:land(tile) or w.sim:owner(tile)~=u.target then continue end
        local near=false
        if index then near=nearTarget(self.nav,index,tile)
        else for _,t in ipairs(d.targets)do if self.nav:manhattan(t,tile)<55 then near=true;break end end end
        if not near then return tile end
    end;return nil
end
function M:tickMIRV(u,d)
    local remaining=#d.path-d.index
    if remaining<=20 and remaining>10 then for _=1,100 do if #d.targets>=350 then break end;local t=self:tryTarget(u,d);if t then table.insert(d.targets,t) end end end
    if remaining<=10 and not d.separated then
        d.separated=true;local targets={};for _,t in ipairs(d.targets) do if t==u.targetTile or self.w.sim:owner(t)==u.target then table.insert(targets,t) end end;d.targets=targets
        for _=1,500+math.max(0,10-remaining)*50 do if #targets>=350 then break end;local t=self:tryTarget(u,d);if t then table.insert(targets,t) end end
        local order={};for i,t in ipairs(targets) do order[t]=i end
        table.sort(targets,function(a,b)local da,db=self.nav:manhattan(a,u.targetTile),self.nav:manhattan(b,u.targetTile);return da>db or da==db and order[a]<order[b] end)
        for i,t in ipairs(targets) do local child=self:flight("MIRVWarhead",u.owner,d.separate,t,22+math.min(4,math.floor((i-1)/70)),math.max(0,remaining)+d.random:nextInt(0,15));child.carrier=u.id;table.insert(d.children,child) end
        d.targetIndex=nil
    end
end
function M:tickFlight(u)
    local d=self.data[u.id];if not d then u.active=false;return end
    if u.kind=="MIRV" then self:tickMIRV(u,d) end
    if u.waitTicks>0 then u.waitTicks-=1;return end
    if d.index>=#d.path-1 then
        u.tile=u.kind=="MIRV" and d.separate or u.targetTile
        if u.kind=="MIRV" then u.active=false;return end
        for _,v in ipairs(self.s:ofKind("SAMMissile")) do if v.active and v.targetUnit==u.id and v.owner~=u.owner and self.w:distance2(v.tile,u.tile)<=144 then return end end
        self:detonate(u);return
    end
    d.index+=1;u.tile=d.path[d.index]
end
function M:targetable(u,t) return self.w:distance2(t,u.sourceTile)<22500 or self.w:distance2(t,u.targetTile)<22500 end
function M:interception(sam,u)
    local d=self.data[u.id];if not d then return nil end
    return Aim.interception(self.w.map.meta.width,self.w.sim.ticks,sam,u,d.path,d.index)
end
function M:reload(u)
    u.missileQueue=u.missileQueue or {}
    while #u.missileQueue>0 and self.w.sim.ticks-u.missileQueue[1]>=90 do table.remove(u.missileQueue,1);if u.kind=="MissileSilo" then break end end
    u.readyMissiles=math.max(0,u.level-#u.missileQueue)
end
function M:tickSAM(u)
    self:reload(u);u.range=U.dynamicSamRange(u,self.w.sim.ticks)
    if u.readyMissiles==0 then return end
    local candidates={}
    for _,v in ipairs(self.w.units) do if v.active and v.kind~="MIRV" and U.nukes[v.kind] and not v.targetedSAM and not self.w:friendly(u.owner,v.owner) and self.w:distance2(u.tile,v.tile)<=360000 then
        local delay,tile=self:interception(u,v)
        if delay and delay<=1 then local d=self.data[v.id];local score=(v.kind=="HydrogenBomb" and 70001 or 0)+math.max(0,200000-self.nav:manhattan(u.tile,v.targetTile)*1000)+math.max(0,10000-math.max(1,#d.path-d.index+1)*100);table.insert(candidates,{unit=v,tile=tile,score=score}) end
    end end
    table.sort(candidates,function(a,b)return a.score>b.score or a.score==b.score and a.unit.id<b.unit.id end)
    for _,c in ipairs(candidates) do
        if #u.missileQueue>=u.level then break end
        table.insert(u.missileQueue,self.w.sim.ticks);c.unit.targetedSAM=true
        local missile=self.s:create("SAMMissile",u.owner,u.tile,{targetUnit=c.unit.id,sourceUnit=u.id,targetTile=c.tile})
        self.data[missile.id]={path=F.air(self.w.map.meta.width,u.tile,c.tile,self.w.sim.ticks),index=1}
    end
end
function M:tickInterceptor(u)
    local target,source=self.s:unit(u.targetUnit),self.s:unit(u.sourceUnit)
    if not target or not source or target.owner==u.owner then if target then target.targetedSAM=false end;u.active=false;return end
    local d=self.data[u.id]
    for _=1,12 do
        if d.index>=#d.path then
            target.active=false;u.active=false;self.s:effect("intercept",u.tile,u.owner,{weapon=target.kind,target=target.owner,unit=target.id})
            local res=self.w.resources[u.owner];if res then res.intercepts=(res.intercepts or 0)+1 end
            local attacker=self.w.resources[target.owner]
            self.w:notify(u.owner,string.format("%s의 %s 요격 성공",attacker and attacker.name or "?",U.names[target.kind] or target.kind),"intercept",u.tile)
            self.interceptedAt=self.interceptedAt or {}
            if (self.interceptedAt[target.owner] or -99)<self.w.sim.ticks-10 then
                self.interceptedAt[target.owner]=self.w.sim.ticks;local defender=self.w.resources[u.owner]
                self.w:notify(target.owner,string.format("%s 요격당함, %s 방공",U.names[target.kind] or target.kind,defender and defender.name or "?"),"loss",u.tile)
            end
            return
        end
        d.index+=1;u.tile=d.path[d.index]
    end
end
function M:tick(u)
    if U.nukes[u.kind] then self:tickFlight(u) elseif u.kind=="SAMLauncher" then self:tickSAM(u) elseif u.kind=="MissileSilo" then self:reload(u) elseif u.kind=="SAMMissile" then self:tickInterceptor(u) end
end
return M
