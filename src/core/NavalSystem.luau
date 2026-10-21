--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local E=if script then require(script.Parent.EconomyRules) else require("./EconomyRules")
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local F=if script then require(script.Parent.FlightPath) else require("./FlightPath")
local M={};M.__index=M
function M.new(system) return setmetatable({s=system,w=system.w,nav=system.nav,data={},shipStaggers={TransportShip=0,TradeShip=0}},M) end
function M:record(u)
    if not self.data[u.id] then
        local stagger=0;if self.shipStaggers[u.kind]~=nil then stagger=self.shipStaggers[u.kind]%50;self.shipStaggers[u.kind]+=1 end
        self.data[u.id]={random=R.new(self.w.sim.ticks),seed=self.w.sim.ticks,offset=self.w.sim.ticks%10,lastShell=0,sent={},rejections=0,manualTick=0,
            waterVersion=self.nav:waterGraphVersion(),stagger=stagger}
    end
    return self.data[u.id]
end
function M:fresh(d)
    local version=self.nav:waterGraphVersion();if d.waterVersion==version then return false end
    if d.pendingWaterVersion~=version then d.pendingWaterVersion=version;d.staggerCountdown=d.stagger or 0 end
    if d.staggerCountdown>0 then d.staggerCountdown-=1;return false end
    d.waterVersion=version;d.path=nil;d.destination=nil;d.index=1;return true
end
function M:lost(u)
    if u.kind=="Warship" then self.w:notify(u.owner,"내 순찰 군함이 격침됐어요.","loss",u.tile)
    elseif u.kind=="TransportShip" then self.w:notify(u.owner,string.format("내 수송선이 격침됐어요. 병력 %s 손실",self.w.amount((u.troops or 0)/10)),"loss",u.tile) end
end
function M:port(owner,tile,capacity,exclude)
    local c=self.nav:component(tile);local best,d=nil,math.huge
    for _,u in ipairs(self.s:ofKind("Port")) do if u.active and u.owner==owner and not u.building and not u.deleteAt and c and self.nav:touches(u.tile,c) then
        local dist=self.w:distance2(u.tile,tile)
        if dist<d and (not capacity or #self:docked(u,exclude)<u.level) then best=u;d=dist end
    end end;return best
end
function M:docked(port,exclude)
    local out={};for _,u in ipairs(self.s:ofKind("Warship")) do if u~=exclude and u.active and u.owner==port.owner and u.navalState~="patrolling" and not u.targetTile and self.w:distance2(u.tile,port.tile)<=25 then table.insert(out,u) end end;return out
end
function M:transport(owner,tile,troops,route)
    local w=self.w
    if U.disabled(w.settings,"TransportShip") or self.s:count(owner,"TransportShip")>=3 then return false,"수송선은 동시에 3척까지 출항할 수 있어요." end
    if not self.nav:valid(tile) or not self.nav:land(tile) or w.sim:owner(tile)==owner or w:friendly(owner,w.sim:owner(tile)) then return false,"상륙할 중립 또는 적 해안을 선택하세요." end
    if w:protectedTarget(owner,w.sim:owner(tile)) then return false,"상대의 시작 보호 시간이 끝나면 출항할 수 있어요." end
    local path,dst;if route then path,dst=route,route[#route] else path,dst=self.nav:transport(owner,tile) end
    if not path then return false,"연결된 바다에 닿은 내 해안과 목표 해안이 필요해요. 목표 해안 50칸 이내를 선택하세요." end
    troops=math.floor(math.min(w.sim.players[owner].troops,troops or w.sim.players[owner].troops/5))
    if troops<1 then return false,"출항할 병력이 없어요." end
    local target=w.sim:owner(dst)
    local u=self.s:create("TransportShip",owner,path[1],{troops=troops,targetTile=dst,target=target})
    if target~=0 and w.sim.players[target].kind~="BOT" and w.sim.players[owner].kind~="BOT" and w.resolveRequest then w:resolveRequest(owner,target,false,nil,"rejected") end
    w.sim:removeTroops(owner,troops);local d=self:record(u)
    d.path=self.nav:path(u.tile,dst)or {u.tile};d.index=1
    w.resources[owner].attacked=true
    return true,"수송선 출항, "..troops.." 병력"
end
function M:resolveRetreat(u)
    local coast=self.nav:path(self.nav:shores(u.owner),u.tile)
    if not coast then self.w.sim:addTroops(u.owner,u.troops);u.active=false;return false end
    u.targetTile=coast[1];local d=self:record(u)
    d.path=self.nav:path(u.tile,u.targetTile);d.index=1;d.destination=u.targetTile
    return true
end
function M:retreat(owner,id)
    local u=self.s:unit(id)
    if not u or u.owner~=owner or u.kind~="TransportShip" or u.retreating then return false,"철수할 내 수송선을 선택하세요." end
    u.retreating=true
    if not self:resolveRetreat(u)then return true,"복귀 경로가 없어 병력을 반환했어요." end
    return true,"수송선이 복귀해요. 상륙 시 병력 25%를 잃어요."
end
function M:move(owner,id,tile)
    local u=self.s:unit(id)
    if not u or u.owner~=owner or u.kind~="Warship" or not self.nav:valid(tile) or not self.nav:water(tile) then return false,"내 군함과 이동할 바다를 선택하세요." end
    local path=self.nav:path(u.tile,tile);if not path then return false,"연결되지 않은 바다예요." end
    local d=self:record(u);d.path=nil;d.destination=nil;d.manualTick=self.w.sim.ticks;d.retreatPort=nil
    u.patrolTile=tile;u.targetTile=nil;u.navalState="patrolling";return true,"군함의 순찰 구역을 옮겨요."
end
function M:walk(u,dst,speed)
    local d=self:record(u)
    self:fresh(d)
    if u.tile==dst then return "complete" end
    if d.path and d.path[d.index or 1]~=u.tile then d.path=nil end
    if d.destination~=dst or not d.path then d.path=self.nav:path(u.tile,dst);d.index=1;d.destination=dst end
    if not d.path then return "failed" end
    if d.index>=#d.path then return "complete" end
    d.index=math.min(#d.path,d.index+(speed or 1));u.tile=d.path[d.index];return "next"
end
function M:tickTransport(u)
    local d=self:record(u)
    self:fresh(d)
    if not self.nav:land(u.targetTile) then
        u.retreating=true;if not self:resolveRetreat(u)then return end
    end
    self:fresh(d)
    if not d.path or d.path[d.index or 1]~=u.tile then d.path=self.nav:path(u.tile,u.targetTile);d.index=1 end
    if not d.path then self.w.sim:addTroops(u.owner,u.troops);u.active=false;return end
    if u.tile~=u.targetTile and d.index<#d.path then d.index+=1;u.tile=d.path[d.index];return end
    local target=self.w.sim:owner(u.targetTile);u.active=false
    self.s:effect("landing",u.targetTile,u.owner,{returning=target==u.owner})
    if target==u.owner then
        self.w.sim:addTroops(u.owner,u.troops*.75)
        if u.troops>0 then self.w:notify(u.owner,string.format("공격 취소, 철수 중 병력 %s 손실",self.w.amount(u.troops*.25/10)),"loss",u.targetTile) end
    else
        self.w.sim:conquer(u.owner,u.targetTile)
        if self.w:friendly(u.owner,u.target) then self.w.sim:addTroops(u.owner,u.troops);return end
        self.w.sim:attack(u.owner,u.target,u.troops,u.targetTile,false)
    end
end
function M:spawnWarship(owner,tile)
    if not self.nav:water(tile) then return false,"군함을 배치할 바다를 선택하세요." end
    local port=self:port(owner,tile);if not port then return false,"이 바다에 연결된 내 항구를 먼저 건설하세요." end
    if not self.s:pay(owner,"Warship") then return false,"군함을 건조할 골드가 부족해요." end
    local u=self.s:create("Warship",owner,port.tile,{health=1000,maxHealth=1000,veterancy=0,patrolTile=tile,navalState="patrolling"})
    self.s:effect("shipReady",port.tile,owner,{})
    self:record(u);return true,"군함을 건조했어요. 바다를 순찰하며 자동으로 교전해요."
end
function M:veteran(u,kind)
    if u.veterancy>=3 then return end
    if kind=="Warship" then u.veterancyProgress=0;u.veterancy+=1
    else
        u.veterancyProgress=(u.veterancyProgress or 0)+(kind=="TransportShip" and 25 or kind=="TradeShip" and 10 or 0)
        while u.veterancyProgress>=250 and u.veterancy<3 do u.veterancyProgress-=250;u.veterancy+=1 end
    end
    if u.veterancy>=3 then u.veterancyProgress=0 end;u.maxHealth=U.maxHealth(u)
end
local targetRank={TransportShip=0,Warship=1,TradeShip=2}
local targetKinds={"TransportShip","Warship","TradeShip"}
function M:target(u,trades)
    local d=self:record(u);local best,priority,distance=nil,99,math.huge
    local width=self.w.map.meta.width;local ux,uy=u.tile%width,math.floor(u.tile/width)
    for _,kind in ipairs(targetKinds) do for _,v in ipairs(self.s:ofKind(kind)) do
        local rank=targetRank[kind]
        if not v.active or v.owner==u.owner or d.sent[v.id] or v.navalState=="docked" then continue end
        local dx,dy=ux-v.tile%width,uy-math.floor(v.tile/width);local dist=dx*dx+dy*dy
        if dist>16900 or self.w:friendly(u.owner,v.owner) then continue end
        if rank==2 then
            local targetPort=self.s:unit(v.destinationPort)
            if not trades or self.w.sim.ticks-(v.safeTick or 0)<20 or not self:port(u.owner,u.tile) or self.w:distance2(u.patrolTile,v.tile)>10000 or targetPort and self.w:friendly(u.owner,targetPort.owner) then continue end
        end
        if rank<priority or rank==priority and dist<distance then best=v;priority=rank;distance=dist end
    end;if best then break end end;return best
end
function M:shoot(u,target)
    local d=self:record(u);u.inCombat=true
    if self.w.sim.ticks-d.lastShell<=20 then return end
    if target.kind~="TransportShip" then d.lastShell=self.w.sim.ticks end
    local shell=self.s:create("Shell",u.owner,u.tile,{targetUnit=target.id,sourceUnit=u.id})
    self:record(shell)
    if not target.health then d.sent[target.id]=true end
end
function M:tickShell(u)
    local target=self.s:unit(u.targetUnit);local source=self.s:unit(u.sourceUnit);local d=self:record(u);local tick=self.w.sim.ticks
    if not target or target.owner==u.owner or d.destroyAt and tick>=d.destroyAt then u.active=false;return end
    if not source and not d.destroyAt then d.destroyAt=tick+50 end
    if d.destination~=target.tile then d.destination=target.tile;d.path=F.air(self.w.map.meta.width,u.tile,target.tile,d.seed);d.index=1 end
    for _=1,3 do
        if d.index>=#d.path then
            local damage=(d.random:nextInt(1,6)-1)*25+200
            if source and (source.veterancy or 0)>0 then damage=math.floor(damage*(100+source.veterancy*20)/100) end
            if target.health then target.health=math.max(0,target.health-damage);if target.health==0 then target.active=false end else target.active=false end
            if not target.active then target.destroyedBy=u.owner;self:lost(target) end
            self.s:effect("shell",target.tile,u.owner,{destroyed=not target.active})
            if not target.active and source and source.kind=="Warship" then self:veteran(source,target.kind) end
            u.active=false;return
        end
        d.index+=1;u.tile=d.path[d.index]
    end
end
function M:tickWarship(u)
    local w,d=self.w,self:record(u);local tick=w.sim.ticks;local before=u.health;u.inCombat=false
    if u.health<=0 then u.active=false;return end
    local port=self:port(u.owner,u.tile)
    if port and w:distance2(u.tile,port.tile)<=22500 and not w.sim.players[u.owner].doomed then u.health=math.min(u.maxHealth,u.health+1) end
    if u.navalState=="docked" then
        local repair=self.s:unit(d.retreatPort)
        if repair and repair.owner==u.owner and not w.sim.players[u.owner].doomed then
            local ships=self:docked(repair);d.healRemainder=(d.healRemainder or 0)+repair.level*5/math.max(1,#ships)
            local amount=math.floor(d.healRemainder);d.healRemainder-=amount;u.health=math.min(u.maxHealth,u.health+amount)
        end
        if repair and repair.owner==u.owner and u.health<u.maxHealth and not w.sim.players[u.owner].doomed then return end
        u.navalState="patrolling";u.targetTile=nil;d.retreatPort=nil;d.path=nil
    end
    if u.navalState=="patrolling" and port and before<math.floor(u.maxHealth*.75) and tick-d.manualTick>=50 and not w.sim.players[u.owner].doomed then u.navalState="retreating";d.retreatPort=port.id;d.path=nil end
    if u.navalState=="retreating" then
        local target=self:target(u,false);if target then self:shoot(u,target) end
        local repair=self.s:unit(d.retreatPort);local alternative=self:port(u.owner,u.tile,true,u)
        if not repair or repair.owner~=u.owner or #self:docked(repair,u)>=repair.level or alternative and w:distance2(alternative.tile,u.tile)<w:distance2(repair.tile,u.tile)*.75 then repair=alternative or port;d.retreatPort=repair and repair.id or nil end
        if not repair or w.sim.players[u.owner].doomed then u.navalState="patrolling";u.targetTile=nil;d.path=nil
        elseif w:distance2(u.tile,repair.tile)<=25 then
            u.targetTile=nil;if #self:docked(repair,u)<repair.level then u.navalState="docked" end;return
        else u.targetTile=repair.tile;self:walk(u,repair.tile);return end
    end
    local target=self:target(u,true)
    if target and target.kind~="TradeShip" then self:shoot(u,target)
    elseif target then
        u.inCombat=true
        for _=1,2 do
            if self.nav:manhattan(u.tile,target.tile)<=5 then
                self.w:notify(target.owner,string.format("%s에게 무역선을 나포당했어요.",self.w.resources[u.owner].name),"loss",target.tile)
                target.owner=u.owner;target.captured=true;self:record(target).path=nil;self:veteran(u,"TradeShip");return
            end
            self:walk(u,target.tile,1)
        end;return
    end
    if not u.targetTile then u.targetTile=self:randomTile(u,false) or self:randomTile(u,true) end
    if u.targetTile and self:walk(u,u.targetTile)~="next" then u.targetTile=nil;d.path=nil end
end
local function shoreline(nav,sim,t) for _,n in ipairs(sim:neighbors(t)) do if not nav:water(n) then return true end end;return false end
function M:randomTile(u,allowShoreline)
    local w,d=self.w,self:record(u);local width,height=w.map.meta.width,w.map.meta.height
    if not self.nav:valid(u.patrolTile) then return nil end
    local component=self.nav:component(u.tile);local px,py=u.patrolTile%width,math.floor(u.patrolTile/width)
    local range,attempts,expand,guard=100,0,0,0
    while expand<3 and guard<20000 do
        guard+=1
        local x=px+d.random:nextInt(-range/2,range/2);local y=py+d.random:nextInt(-range/2,range/2)
        if x<0 or y<0 or x>=width or y>=height then continue end
        local t=y*width+x
        if self.nav:water(t) and (allowShoreline or not shoreline(self.nav,w.sim,t)) and (not component or self.nav:component(t)==component) then return t end
        attempts+=1
        if attempts==500 then expand+=1;attempts=0;range+=math.floor(range/2) end
    end
    return nil
end
function M:portLevels(owner)
    local tick,list=self.w.sim.ticks,self.w.units;local memo=self.portLevelMemo
    if not memo or memo.tick~=tick or memo.list~=list or memo.n~=#list then
        memo={tick=tick,list=list,n=#list,ports={},slots={}};self.portLevelMemo=memo
        for i,v in ipairs(list)do if v.kind=="Port"then table.insert(memo.ports,v);table.insert(memo.slots,i)end end
    end
    local levels=0
    for i,v in ipairs(memo.ports)do
        if list[memo.slots[i]]~=v then self.portLevelMemo=nil;return self:portLevels(owner)end
        if v.active and v.kind=="Port" and v.owner==owner then levels+=v.level end
    end
    return levels
end
function M:tickPort(u)
    local d=self:record(u);local tick=self.w.sim.ticks
    if (tick+d.offset)%10~=0 or U.disabled(self.w.settings,"TradeShip") then return end
    local spawn=false;local count=self.s:count(nil,"TradeShip");local portLevels=self:portLevels(u.owner)
    for _=1,u.level do if d.random:chance(U.tradeSpawnRate(d.rejections,count,portLevels)) then d.rejections=0;spawn=true;break else d.rejections+=1 end end
    if not spawn then return end
    local ports={};local c=self.nav:component(u.tile)
    for _,v in ipairs(self.s:ofKind("Port")) do if v.active and not v.building and v.owner~=u.owner and self.w:canTrade(v.owner,u.owner) and c and self.nav:touches(v.tile,c) then table.insert(ports,v) end end
    table.sort(ports,function(a,b)local da,db=self.nav:manhattan(a.tile,u.tile),self.nav:manhattan(b.tile,u.tile);return da<db or da==db and a.id<b.id end)
    local weighted={};for i,v in ipairs(ports) do
        local far=self.nav:manhattan(v.tile,u.tile)>=300;local copies=1+(far and i-1<math.clamp(#ports/3,math.min(4,#ports),#ports) and 1 or 0)+(far and self.w:friendly(v.owner,u.owner) and 1 or 0)
        for _=1,copies*v.level do table.insert(weighted,v) end
    end
    if #weighted==0 then return end
    local dst=d.random:randElement(weighted);local path=self.nav:path(u.tile,dst.tile);if not path then return end
    local ship=self.s:create("TradeShip",u.owner,u.tile,{sourcePort=u.id,destinationPort=dst.id,safeTick=tick})
    local data=self:record(ship);data.path=path;data.index=1;data.traveled=0;data.original=u.owner
end
function M:tickTrade(u)
    local d=self:record(u);local src,dst=self.s:unit(u.sourcePort),self.s:unit(u.destinationPort)
    self:fresh(d)
    if src and dst and src.owner==dst.owner or not u.captured and (not dst or not self.w:canTrade(u.owner,dst.owner)) then u.active=false;return end
    if u.captured and (not dst or dst.owner~=u.owner) then
        dst=self:port(u.owner,u.tile);if not dst then u.active=false;return end
        u.destinationPort=dst.id;d.path=nil
    end
    if not dst then u.active=false;return end
    self:fresh(d)
    if d.path and d.path[d.index or 1]~=u.tile then d.path=nil end
    if not d.path then d.path=self.nav:waterFinder():findPath(u.tile,dst.tile,true);d.index=1 end
    if not d.path then u.active=false;return end
    if u.tile==dst.tile or d.index>=#d.path then
        local gold=E.tradeShipGold(self.w.settings,self.w:economyPlayer(u.owner),d.traveled)
        local amount=B.toString(gold);u.active=false
        if u.captured then
            self.w:setGold(u.owner,B.add(self.w:getGold(u.owner),gold));self.s:effect("trade",dst.tile,u.owner,{gold=amount})
            local robbed=d.original and self.w.resources[d.original]
            if d.original~=u.owner and robbed then self.w:notify(u.owner,string.format("%s에게서 나포한 무역선으로 골드 +%s",robbed.name,self.w.amount(tonumber(amount))),"capture",dst.tile) end
        elseif src then
            for _,port in ipairs({src,dst}) do self.w:setGold(port.owner,B.add(self.w:getGold(port.owner),gold));self.s:effect("trade",port.tile,port.owner,{gold=amount}) end
        end
        return
    end
    d.index+=1;u.tile=d.path[d.index];d.traveled+=1
    for _,n in ipairs(self.w.sim:neighbors(u.tile)) do if self.nav:land(n) then u.safeTick=self.w.sim.ticks;break end end
end
function M:tick(u)
    if u.kind=="TransportShip" then self:tickTransport(u) elseif u.kind=="Warship" then self:tickWarship(u) elseif u.kind=="Shell" then self:tickShell(u) elseif u.kind=="Port" then self:tickPort(u) elseif u.kind=="TradeShip" then self:tickTrade(u) end
end
return M
