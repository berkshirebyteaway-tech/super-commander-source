-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. NationWarshipBehavior, pinned e02eeba: spawning,
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local E=if script then require(script.Parent.EconomyRules) else require("./EconomyRules")
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local C=if script then require(script.Parent.NationCommon) else require("./NationCommon")
local M={};M.__index=M
local RETALIATION={"⛵"}
local TARGETING,PATROL=130,100
local function set() return {list={},has={}} end
local function add(s,u) if not s.has[u] then s.has[u]=true;table.insert(s.list,u) end end
local function remove(s,u) if s.has[u] then s.has[u]=nil;table.remove(s.list,table.find(s.list,u)) end end
function M.new(ai) return setmetatable({a=ai,transports=set(),trades=set(),incoming=set(),dealt=set()},M) end
local function gold(w,id) return tonumber(B.toString(w:getGold(id))) end
function M:spawnTile(tile,radius)
    local a=self.a;local w=a.world;local width,height=w.map.meta.width,w.map.meta.height
    for _=1,50 do
        local x,y=a.random:nextInt(tile%width-radius,tile%width+radius),a.random:nextInt(math.floor(tile/width)-radius,math.floor(tile/width)+radius)
        if x>=0 and y>=0 and x<width and y<height and w.unitSystem.nav:water(y*width+x) then return y*width+x end
    end
    return nil
end
function M:canBuild(tile) return self.a.world.unitSystem:preview(self.a.id,"Warship",tile).valid end
function M:spawn()
    local a=self.a;local w,s=a.world,a.world.unitSystem
    if U.disabled(w.settings,"Warship") or not a.random:chance(50) then return false end
    local ports=C.owned(w,a.id,"Port")
    if #ports>0 and #C.owned(w,a.id,"Warship")==0 and B.compare(w:getGold(a.id),s:cost(a.id,"Warship"))>0 then
        local port=a.random:randElement(ports);local tile=self:spawnTile(port.tile,250)
        if not tile or not self:canBuild(tile) then return false end
        return (s:build(a.id,"Warship",tile))
    end
    return false
end
function M:track()
    local a=self.a;local w=a.world
    if a.difficulty=="Easy" or U.disabled(w.settings,"Warship") then return end
    if (w.resources[a.id].constructed.Port or 0)==0 and #C.owned(w,a.id,"Port")==0 then return end
    if not U.disabled(w.settings,"TransportShip") then
        for _,u in ipairs(C.owned(w,a.id,"TransportShip")) do add(self.transports,u) end
        for _,u in ipairs(table.clone(self.transports.list)) do
            if not u.active then if u.destroyedBy then self:retaliate(u.tile,u.destroyedBy,"transport") end;remove(self.transports,u) end
        end
    end
    for _,u in ipairs(C.owned(w,a.id,"TradeShip")) do add(self.trades,u) end
    for _,u in ipairs(table.clone(self.trades.list)) do
        if not u.active then remove(self.trades,u)
        elseif u.owner~=a.id then self:retaliate(u.tile,u.owner,"trade");remove(self.trades,u) end
    end
    self:trackIncoming()
end
function M:trackIncoming()
    local a=self.a;local w=a.world;local nav=w.unitSystem.nav
    for _,u in ipairs(C.units(w,"TransportShip")) do
        if u.active and u.targetTile and not u.retreating and u.owner~=a.id and w.sim:owner(u.targetTile)==a.id then add(self.incoming,u) end
    end
    for _,u in ipairs(table.clone(self.incoming.list)) do
        local target=u.targetTile
        if not u.active or not target or u.retreating then remove(self.incoming,u);remove(self.dealt,u);continue end
        if self.dealt.has[u] then continue end
        if nav:manhattan(u.tile,target)<20 then add(self.dealt,u);continue end
        if not C.allied(w,u.owner,a.id) then
            local guarded=false
            for _,ship in ipairs(C.owned(w,a.id,"Warship")) do
                if w:distance2(ship.tile,target)<=8100 or ship.patrolTile and nav:manhattan(target,ship.patrolTile)<90 then guarded=true;break end
            end
            if guarded then add(self.dealt,u);continue end
            local tile=self:spawnTile(target,30);if not tile then continue end
            self:retaliate(tile,u.owner,"transport");add(self.dealt,u);break
        end
    end
end
function M:retaliate(tile,enemy,reason)
    local a=self.a;local w=a.world
    if enemy==a.id or not w.sim.players[enemy] or #self:covering(tile)>0 then return end
    if #C.owned(w,a.id,"Warship")>=10 then self:move(tile);return end
    local odds=({Medium=15,Hard=50,Impossible=80})[a.difficulty]
    if odds and a.random:nextInt(0,100)<odds then
        if not self:canBuild(tile) then self:move(tile);return end
        w.unitSystem:build(a.id,"Warship",tile)
        a.diplomacy:maybeEmoji(enemy,RETALIATION)
        w:changeRelation(a.id,enemy,reason=="trade" and -7.5 or -15)
    end
end
function M:hostileNear(tile)
    local a=self.a;local w=a.world;local n=0
    for _,u in ipairs(C.units(w,"Warship")) do if u.active and u.owner~=a.id and not w:friendly(a.id,u.owner) and w:distance2(u.tile,tile)<=TARGETING*TARGETING then n+=1 end end
    return n
end
function M:covering(tile)
    local a=self.a;local w=a.world;local nav=w.unitSystem.nav;local c=nav:component(tile);local out={}
    for _,u in ipairs(C.owned(w,a.id,"Warship")) do if u.patrolTile and nav:component(u.tile)==c and nav:manhattan(u.patrolTile,tile)<=PATROL then table.insert(out,u) end end
    return out
end
local function patrol(u,tile) u.patrolTile=tile;u.targetTile=nil end
function M:move(tile)
    local a=self.a;local w=a.world;local nav=w.unitSystem.nav
    if not nav:water(tile) then return end
    local ships={};for _,u in ipairs(C.owned(w,a.id,"Warship")) do if u.patrolTile and nav:manhattan(u.tile,u.patrolTile)<130 then table.insert(ships,u) end end
    C.sort(ships,function(u) return nav:manhattan(u.tile,tile) end)
    if ships[1] then patrol(ships[1],tile) end
end
function M:clearSeaLane(blocker)
    local a=self.a;local w,s=a.world,a.world.unitSystem;local nav=s.nav
    if U.disabled(w.settings,"Warship") or not C.smart(a.difficulty) then return end
    local target=blocker.tile;local fleet=self:hostileNear(target)
    local wanted=a.difficulty=="Hard" and fleet or fleet+1
    local covering=self:covering(target);local component=nav:component(target);local own=C.owned(w,a.id,"Warship")
    local spare={}
    for _,u in ipairs(own) do
        if not table.find(covering,u) and u.navalState=="patrolling" and nav:component(u.tile)==component and (not u.patrolTile or self:hostileNear(u.patrolTile)==0) then table.insert(spare,u) end
    end
    C.sort(spare,function(u) return nav:manhattan(u.tile,target) end)
    local recruits={};for i=1,math.min(#spare,math.max(0,wanted-#covering)) do recruits[i]=spare[i] end
    local builds=wanted-#covering-#recruits
    if builds>0 then
        if #own+builds>10 then return end
        local total=0;local ep=w:economyPlayer(a.id)
        for i=0,builds-1 do total+=tonumber(B.toString(E.cost(w.settings,ep,"Warship",i))) end
        if gold(w,a.id)<total or not self:canBuild(target) then return end
    end
    for _,u in ipairs(recruits) do patrol(u,target) end
    for _=1,builds do s:build(a.id,"Warship",target) end
end
function M:counter()
    local a=self.a;local w,s=a.world,a.world.unitSystem
    if U.disabled(w.settings,"Warship") or not C.smart(a.difficulty) or #C.units(w,"Warship")<=10 then return end
    if B.compare(s:cost(a.id,"Warship"),w:getGold(a.id))>0 or #C.owned(w,a.id,"Port")==0 or #C.owned(w,a.id,"Warship")>=10 then return end
    local team=C.team(w,a.id);local rich={}
    for id,p in ipairs(w.sim.players) do if p.tiles.size>0 and p.kind~="HUMAN" and (not team or C.sameTeam(w,id,a.id)) then table.insert(rich,id) end end
    C.sort(rich,function(id) return -gold(w,id) end)
    if not table.find({rich[1],rich[2],rich[3]},a.id) then return end
    local target=team and self:teamTarget() or not team and self:ffaTarget()
    if not target then return end
    if not self:canBuild(target.tile) then self:move(target.tile);return end
    s:build(a.id,"Warship",target.tile);a.diplomacy:emoji(0,RETALIATION)
end
function M:ffaTarget()
    local a=self.a;local w=a.world
    for id,p in ipairs(w.sim.players) do if id~=a.id and p.tiles.size>0 and not w:friendly(a.id,id) then
        local ships=C.owned(w,id,"Warship");if #ships>10 then return a.random:randElement(ships) end
    end end
    return nil
end
function M:teamTarget()
    local a=self.a;local w=a.world;local teams,order={},{}
    for id,p in ipairs(w.sim.players) do
        if id==a.id or p.tiles.size==0 or w:friendly(a.id,id) or p.team==nil then continue end
        local t=teams[p.team];if not t then t={count=0,players={}};teams[p.team]=t;table.insert(order,p.team) end
        t.count+=#C.owned(w,id,"Warship");table.insert(t.players,id)
    end
    for _,key in ipairs(order) do local t=teams[key];if t.count>15 then
        local best,most=nil,0;for _,id in ipairs(t.players) do local n=#C.owned(w,id,"Warship");if n>most then best=id;most=n end end
        if best and most>3 then return a.random:randElement(C.owned(w,best,"Warship")) end
    end end
    return nil
end
return M
