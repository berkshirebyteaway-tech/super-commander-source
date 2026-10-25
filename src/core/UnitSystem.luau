--!native
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local E=if script then require(script.Parent.EconomyRules) else require("./EconomyRules")
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local Navigation=if script then require(script.Parent.Navigation) else require("./Navigation")
local Naval=if script then require(script.Parent.NavalSystem) else require("./NavalSystem")
local Nuclear=if script then require(script.Parent.NuclearSystem) else require("./NuclearSystem")
local Rail=if script then require(script.Parent.RailSystem) else require("./RailSystem")
local Doomsday=if script then require(script.Parent.DoomsdaySystem) else require("./DoomsdaySystem")
local Comms=if script then require(script.Parent.CommsSystem) else require("./CommsSystem")
local M={};M.__index=M
function M.new(w)
    local self=setmetatable({w=w,nav=Navigation.new(w),mirvsLaunched=0,effects={},effectId=0,terrainChanges={},terrainRevision=0,unitIndex={}},M)
    self.naval=Naval.new(self);self.nuclear=Nuclear.new(self);self.rail=Rail.new(self);self.doomsday=Doomsday.new(w);self.comms=Comms.new(w);return self
end
function M:unit(id)
    if type(id)~="number" or id<1 or id%1~=0 then return nil end
    local units=self.w.units;local index=self.unitIndex
    local u=index and index[id]and units[index[id]]
    if u and u.id==id then
        return u.active and u or nil
    end
    if not index then index={};self.unitIndex=index end
    for i,v in ipairs(units)do if v.id==id and v.active then index[id]=i;return v end end
    if id~=nil and id==id then index[id]=nil end;return nil
end
function M:ofKind(kind)
    local list=self.w.units;local m=self.kindMemo
    if not m or m.list~=list or m.n~=#list then m={list=list,n=#list,kinds={}};self.kindMemo=m end
    local out=m.kinds[kind]
    if not out then out={};for _,u in ipairs(list) do if u.kind==kind then table.insert(out,u) end end;m.kinds[kind]=out end
    return out
end
function M:count(owner,kind) local n=0;for _,u in ipairs(self:ofKind(kind)) do if u.active and (not owner or u.owner==owner) then n+=u.level end end;return n end
function M:create(kind,owner,tile,fields)
    self.w.nextUnit+=1;local u={id=self.w.nextUnit,kind=kind,owner=owner,tile=tile,level=1,active=true,createdTick=self.w.sim.ticks}
    for k,v in pairs(fields or {}) do u[k]=v end;table.insert(self.w.units,u)
    self.unitIndex=self.unitIndex or {};self.unitIndex[u.id]=#self.w.units;return u
end
function M:cost(owner,kind,player) return E.cost(self.w.settings,player or self.w:economyPlayer(owner),kind,nil,self.mirvsLaunched) end
function M:pay(owner,kind)
    if U.disabled(self.w.settings,kind) then return false end
    local cost=self:cost(owner,kind);local gold=self.w:getGold(owner);if B.compare(gold,cost)<0 then return false end
    self.w:setGold(owner,B.subtract(gold,cost));local constructed=self.w.resources[owner].constructed;constructed[kind]=(constructed[kind] or 0)+1;return true
end
function M:effect(kind,tile,owner,extra)
    self.effectId+=1;local e={id=self.effectId,kind=kind,tile=tile,owner=owner,tick=self.w.sim.ticks};for k,v in pairs(extra) do e[k]=v end
    table.insert(self.effects,e);if #self.effects>64 then table.remove(self.effects,1) end
end
function M:constructionTile(kind,tile,owner)
    if kind~="Port" then return self.w:validConstructionTile(tile,owner) end
    if self.w.sim:owner(tile)~=owner then return nil end
    local width=self.w.map.meta.width;local cx,cy=tile%width,math.floor(tile/width)
    local valid=self.w:flood(tile,function(t)
        if self.w.sim:owner(t)~=owner then return false end
        local dx,dy=t%width-cx,math.floor(t/width)-cy;return dx*dx+dy*dy<225
    end)
    local structures={}
    for _,u in ipairs(self.w.units)do if u.active and U.structures[u.kind]then
        table.insert(structures,{u.tile%width,math.floor(u.tile/width)})
    end end
    local candidate={};for i,t in ipairs(valid) do
        if not self.nav:shore(t) or self.nav:manhattan(t,tile)>20 then continue end
        local x,y=t%width,math.floor(t/width);local blocked=false
        for _,u in ipairs(structures)do local dx,dy=u[1]-x,u[2]-y;if dx*dx+dy*dy<225 then blocked=true;break end end
        if not blocked then table.insert(candidate,{tile=t,order=i,d=self.nav:manhattan(t,tile)}) end
    end
    table.sort(candidate,function(a,b)return a.d<b.d or a.d==b.d and a.order<b.order end);return candidate[1] and candidate[1].tile
end
function M:context(owner,tile)
    local w=self.w;local result={attack=false,transport=false,warship=false,rockets=false}
    if w.phase~="playing" or not self.nav:valid(tile) or not w.sim.players[owner] or w.sim.players[owner].tiles.size==0 then return result end
    local target=w.sim:owner(tile)
    if self.nav:water(tile) then result.warship=not U.disabled(w.settings,"Warship") and self.naval:port(owner,tile)~=nil;return result end
    if not self.nav:land(tile) then return result end
    if target==owner or w:friendly(owner,target) or w:protectedTarget(owner,target) then return result end
    for _,t in ipairs(w.sim.players[owner].border.dense) do
        if t~=false then
            for _,adjacent in ipairs(w.sim:neighbors(t)) do if w.sim:owner(adjacent)==target and self.nav:land(adjacent) then result.attack=true;break end end
            if result.attack then break end
        end
    end
    if not U.disabled(w.settings,"TransportShip") then
        local full=self:count(owner,"TransportShip")>=3;local landing=self.nav:landing(owner,tile)~=nil
        result.transport=not full and landing;result.transportFull=full and landing
    end
    result.rockets=self:count(owner,"MissileSilo")>0 and (not U.disabled(w.settings,"AtomBomb") or not U.disabled(w.settings,"HydrogenBomb") or not U.disabled(w.settings,"MIRV"))
    return result
end
function M:upgradeTarget(owner,kind,tile)
    if not U.upgradable[kind] or not self.nav:valid(tile) then return nil end
    local best,distance=nil,math.huge
    for _,u in ipairs(self.w.units) do
        if u.active and u.kind==kind then local d=self.w:distance2(u.tile,tile);if d<=225 and d<distance then best,distance=u,d end end
    end
    if best and best.owner==owner and not best.building and not best.deleteAt then return best end
    return nil
end
function M:preview(owner,kind,tile)
    if not self.w.sim.players[owner] then return {valid=false,reason="참가자만"} end
    if not table.find(U.buildable,kind) or U.disabled(self.w.settings,kind) then return {valid=false,reason="이 경기에선 불가"} end
    local r={valid=false,cost=B.toString(self:cost(owner,kind)),duration=E.duration(self.w.settings,kind)/10}
    if self.w.phase~="playing" or self.w.sim.players[owner].tiles.size==0 or not self.nav:valid(tile) then r.reason="위치 선택";return r end
    local existing=self.w.phase=="playing" and self:upgradeTarget(owner,kind,tile)
    if existing then
        r.upgrade=existing.id;r.tile=existing.tile;r.level=existing.level
        if B.compare(self.w:getGold(owner),self:cost(owner,kind))<0 then r.reason="골드 부족";return r end
        r.valid=true;r.reason="이 건물을 업그레이드해요.";return r
    end
    if U.structures[kind] then r.tile=self:constructionTile(kind,tile,owner);r.reason=kind=="Port" and "내 해안, 15칸 간격" or "내 땅, 15칸 간격"
    elseif kind=="Warship" then local port=self.nav:water(tile) and self.naval:port(owner,tile);r.tile=port and port.tile or nil;r.reason="이 바다에 연결된 내 항구가 필요합니다."
    else local valid,silo=self.nuclear:canLaunch(owner,kind,tile);if valid then r.tile=silo.tile else r.reason=silo end end
    if not r.tile then return r end
    if B.compare(self.w:getGold(owner),self:cost(owner,kind))<0 then r.reason="골드 부족";return r end
    r.valid=true;r.reason=U.nukes[kind] and "발사 가능" or "배치 가능";return r
end
function M:build(owner,kind,tile)
    local p=self:preview(owner,kind,tile);if not p.valid then return false,p.reason end
    if p.upgrade then return self:upgrade(owner,p.upgrade,1) end
    if U.structures[kind] then table.insert(self.w.orders,{kind=kind,tile=tile,owner=owner});return true,"건설 명령을 보냈어요."
    elseif kind=="Warship" then return self.naval:spawnWarship(owner,tile) else return self.nuclear:launch(owner,kind,tile) end
end
function M:upgrade(owner,id,amount)
    amount=math.clamp(math.floor(tonumber(amount)or 1),1,U.maxUpgradeAmount)
    local ok,message=self:upgradeOnce(owner,id);if not ok then return ok,message end
    for _=2,amount do if not self:upgradeOnce(owner,id)then break end end
    local u=self:unit(id);return true,U.names[u.kind].." 레벨 "..u.level
end
function M:upgradeOnce(owner,id)
    local u=self:unit(id)
    if self.w.phase~="playing" or not u or u.owner~=owner or u.building or u.deleteAt or not U.upgradable[u.kind] then return false,"강화할 건물 선택" end
    if not self:pay(owner,u.kind) then return false,"골드 부족 또는 비활성" end
    if u.kind=="SAMLauncher" then u.rangeFrom=U.dynamicSamRange(u,self.w.sim.ticks);u.rangeStart=self.w.sim.ticks end
    u.level+=1
    if u.kind=="SAMLauncher" or u.kind=="MissileSilo" then u.missileQueue=u.missileQueue or {};table.insert(u.missileQueue,self.w.sim.ticks) end
    return true,U.names[u.kind].." 레벨 "..u.level
end
function M:tick()
    local count=#self.w.units
    for i=1,count do local u=self.w.units[i]
        if u.active and not u.building and (u.createdTick or -1)<self.w.sim.ticks then self.naval:tick(u);if u.active then self.nuclear:tick(u) end end
    end
    self.rail:tick()
    self.doomsday:tick()
    self.nav:waterTick()
    if self.w.sim.ticks%100==0 then self:prune() end
end
function M:prune()
    local live={}
    self.unitIndex=self.unitIndex or {};table.clear(self.unitIndex)
    for _,u in ipairs(self.w.units) do
        if u.active then table.insert(live,u);self.unitIndex[u.id]=#live
        else self.naval.data[u.id]=nil;self.nuclear.data[u.id]=nil end
    end
    self.w.units=live
    self.naval.portLevelMemo=nil
    self.kindMemo=nil
    for _,d in pairs(self.naval.data)do if d.sent then
        for id in pairs(d.sent)do if not self.unitIndex[id]then d.sent[id]=nil end end
    end end
    local targets={};for _,t in ipairs(self.comms.targets) do if self.w.sim.ticks-t.tick<100 then table.insert(targets,t) end end
    self.comms.targets=targets
    self.rail:prune()
end
function M:snapshot(state)
    state.unitEffects=self.effects;state.railRevision=self.rail.revision
    local rails=self.railSnapshot
    if not rails or rails.source~=self.rail.rails or rails.revision~=self.rail.revision then
        local list={}
        for _,r in ipairs(self.rail.rails)do if r.active then table.insert(list,table.freeze({id=r.id,tiles=table.freeze(table.clone(r.tiles))}))end end
        rails={source=self.rail.rails,revision=self.rail.revision,list=table.freeze(list)};self.railSnapshot=rails
    end
    state.rails=rails.list
    state.terrainRevision=self.terrainRevision;state.terrainChanges={};for tile,byte in pairs(self.terrainChanges) do table.insert(state.terrainChanges,{tile,byte}) end
    local sim=self.w.sim;local fallout=self.falloutSnapshot
    if not fallout or fallout.source~=sim.fallout or fallout.revision~=sim.falloutRevision then
        local list={};for tile in pairs(sim.fallout or {})do table.insert(list,tile)end
        fallout={source=sim.fallout,revision=sim.falloutRevision,list=table.freeze(list)};self.falloutSnapshot=fallout
    end
    state.fallout=fallout.list
    state.naval={transports=self:count(1,"TransportShip"),maxTransports=3};state.mirvsLaunched=self.mirvsLaunched
    state.doomsday=self.w.settings.doomsdayClock and {required=self.doomsday.required or 0,speed=self.w.settings.doomsdayClockSpeed or "normal"} or nil
    state.comms=self.comms:forPlayer(1)
    local player=self.w:economyPlayer(1)
    for _,kind in ipairs(U.buildable) do state.costs[kind]=B.toString(self:cost(1,kind,player)) end
end
return M
