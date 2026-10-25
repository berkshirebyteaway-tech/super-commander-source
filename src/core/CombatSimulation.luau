--!native
-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Adapted from pinned AttackExecution, RetreatExecution,
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local S=if script then require(script.Parent.OrderedTiles) else require("./OrderedTiles")
local H=if script then require(script.Parent.FlatBinaryHeap) else require("./FlatBinaryHeap")
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local A=if script then require(script.Parent.AttackLogic) else require("./AttackLogic")
local M={};M.__index=M
function M.new(spec)
    local tb=if typeof(spec.terrain)=="buffer" then buffer.create(buffer.len(spec.terrain)) else nil
    if tb then buffer.copy(tb,0,spec.terrain) end
    local terrain=if tb then setmetatable({}, {__index=function(_,i) return buffer.readu8(tb,i-1) end,__newindex=function(_,i,v) buffer.writeu8(tb,i-1,v) end}) else table.clone(spec.terrain)
    local self=setmetatable({width=spec.width,height=spec.height,terrain=terrain,tb=tb,owners={},fallout={},falloutRevision=0,players={},ticks=0,execs={},pending={},captured={},playerCount=#spec.troops,ownerChanges=0},M)
    for id=1,self.playerCount do self.players[id]={id=id,troops=math.floor(spec.troops[id]),kind=spec.types and spec.types[id] or "HUMAN",tiles=S.new(),border=S.new(),outgoing={},incoming={}} end
    for i=1,spec.width*spec.height do self.owners[i]=0 end
    for i,id in ipairs(spec.owners) do if id~=0 then self:conquer(id,i-1) end end
    self.captured={}
    return self
end
function M:neighbors(t) return T.neighbors(t,self.width,self.height) end
function M:addPlayer(kind,troops)
    local id=#self.players+1
    self.players[id]={id=id,troops=math.floor(troops),kind=kind,tiles=S.new(),border=S.new(),outgoing={},incoming={}}
    self.playerCount=id;return self.players[id]
end
function M:owner(t) return self.owners[t+1] end
local function byteAt(self,t) local tb=self.tb;if tb then return buffer.readu8(tb,t) end;return self.terrain[t+1] end
local function passable(b) return bit32.band(b,128)~=0 and bit32.band(b,31)~=31 end
local function touchesOther(owners,t,id,w,h)
    local x=t%w
    return t>=w and owners[t-w+1]~=id or t<(h-1)*w and owners[t+w+1]~=id or x~=0 and owners[t]~=id or x~=w-1 and owners[t+2]~=id
end
local function countOwned(owners,t,id,w,h)
    local x,c=t%w,0
    if t>=w and owners[t-w+1]==id then c+=1 end
    if t<(h-1)*w and owners[t+w+1]==id then c+=1 end
    if x~=0 and owners[t]==id then c+=1 end
    if x~=w-1 and owners[t+2]==id then c+=1 end
    return c
end
local function updateBorder(self,t)
    local owners=self.owners;local id=owners[t+1];if id==0 then return end
    if touchesOther(owners,t,id,self.width,self.height) then self.players[id].border:add(t);return end
    self.players[id].border:delete(t)
end
M.updateBorder=updateBorder
function M:conquer(id,t)
    assert(passable(byteAt(self,t)))
    local owners=self.owners;local old=owners[t+1]
    if old~=0 then self.players[old].tiles:delete(t);self.players[old].border:delete(t) end
    owners[t+1]=id;self.players[id].tiles:add(t);self.ownerChanges+=1
    if old~=0 and old~=id and self.players[old].tiles.size==0 then
        local p=self.players[id];p.conqueredCountries=p.conqueredCountries or {}
        if not p.conqueredCountries[old]then p.conqueredCountries[old]=true;p.countriesConquered=(p.countriesConquered or 0)+1 end
    end
    self.players[id].lastTileChange=self.ticks;if old~=0 then self.players[old].lastTileChange=self.ticks end
    if self.fallout[t] then self.fallout[t]=nil;self.falloutRevision=(self.falloutRevision or 0)+1;if self.onFalloutCleared then self.onFalloutCleared(t) end end
    local w,h=self.width,self.height;local x=t%w
    updateBorder(self,t)
    if t>=w then updateBorder(self,t-w) end
    if t<(h-1)*w then updateBorder(self,t+w) end
    if x~=0 then updateBorder(self,t-1) end
    if x~=w-1 then updateBorder(self,t+1) end
    table.insert(self.captured,{t,id})
end
function M:relinquish(t)
    local old=self:owner(t);if old==0 then return end
    self.players[old].tiles:delete(t);self.players[old].border:delete(t);self.owners[t+1]=0;self.ownerChanges+=1;self.players[old].lastTileChange=self.ticks
    for _,n in ipairs(self:neighbors(t)) do self:updateBorder(n) end;table.insert(self.captured,{t,0})
end
function M:removeTroops(id,value)
    if value<=0 then return 0 end
    local p=self.players[id];local n=math.min(p.troops,math.floor(value));p.troops-=n;return n
end
function M:addTroops(id,value)
    if value<0 then self:removeTroops(id,-value) else self.players[id].troops+=math.floor(value) end
end
local function remove(list,item)
    local out={};for _,v in ipairs(list) do if v~=item then table.insert(out,v) end end;return out
end
function M:deleteAttack(e)
    e.attackActive=false
    local p=self.players[e.owner];p.outgoing=remove(p.outgoing,e)
    if e.target~=0 then local d=self.players[e.target];d.incoming=remove(d.incoming,e) end
end
local function enqueueFront(self,e,n,owners,w,h)
    local b=byteAt(self,n)
    if not passable(b) or owners[n+1]~=e.target then return end
    e.border:add(n)
    local count=countOwned(owners,n,e.owner,w,h)
    local m=bit32.band(b,31);local mag=if m<10 then 1 elseif m<20 then 1.5 else 2
    e.heap:enqueue(n,(e.random:nextInt(0,7)+10)*(1-count*0.5+mag/2)+self.ticks)
end
function M:addNeighbors(e,t)
    local owners,w,h=self.owners,self.width,self.height;local x=t%w
    if t>=w then enqueueFront(self,e,t-w,owners,w,h) end
    if t<(h-1)*w then enqueueFront(self,e,t+w,owners,w,h) end
    if x~=0 then enqueueFront(self,e,t-1,owners,w,h) end
    if x~=w-1 then enqueueFront(self,e,t+1,owners,w,h) end
end
function M:refresh(e)
    e.heap:clear();e.border:clear()
    self.players[e.owner].border:forEach(function(t) self:addNeighbors(e,t) end)
end
function M:initAttack(e)
    local p=self.players[e.owner]
    if self.canAttack and not self.canAttack(e.owner,e.target) then e.active=false;return end
    e.startTroops=e.startTroops or p.troops/(p.kind=="BOT" and 20 or 5)
    if e.removeTroops then e.startTroops=self:removeTroops(e.owner,math.min(p.troops,e.startTroops)) end
    e.troops=e.startTroops;e.attackActive=true;e.border=S.new();e.heap=H.new();e.random=R.new(123)
    table.insert(p.outgoing,e)
    if e.target~=0 then table.insert(self.players[e.target].incoming,e) end
    if self.onAttackInitialized then self.onAttackInitialized(e.owner,e.target) end
    if e.sourceTile~=nil then self:addNeighbors(e,e.sourceTile) else self:refresh(e) end
    local incoming=p.incoming
    for _,other in ipairs(incoming) do
        if self.players[other.owner].tiles.size>0 and other.owner==e.target then
            if other.troops>e.troops then other.troops=math.max(0,other.troops-e.troops);self:deleteAttack(e);e.active=false;return
            else e.troops=math.max(0,e.troops-other.troops);self:deleteAttack(other) end
        end
    end
    local outgoing=p.outgoing
    for _,other in ipairs(outgoing) do
        if other~=e and other.target==e.target and e.sourceTile==nil then e.troops=math.max(0,e.troops+other.troops);self:deleteAttack(other) end
    end
    if e.heap:size()==0 then self:retreat(e);return end
    if self.onAttackLaunched then self.onAttackLaunched(e.owner,e.target) end
end
function M:retreat(e,malus)
    local deaths=e.troops*((malus or 0)/100)
    if not e.removeTroops and e.sourceTile==nil then e.troops=math.max(0,e.troops-e.startTroops) end
    self:addTroops(e.owner,e.troops-deaths);self:deleteAttack(e);e.active=false
end
function M:handleDeadDefender(e)
    if e.target==0 or self.players[e.target].tiles.size>=100 then return end
    if self.conquerPlayer then self.conquerPlayer(e.owner,e.target) end
    local defender=self.players[e.target]
    for _=1,100 do
        local progressed=false
        defender.tiles:forEach(function(t)
            local borders=false
            for _,n in ipairs(self:neighbors(t)) do if self:owner(n)==e.owner then borders=true;break end end
            if borders then self:conquer(e.owner,t);progressed=true
            else
                for _,n in ipairs(self:neighbors(t)) do
                    local id=self:owner(n)
                    if id~=0 and id~=e.target and not (self.isFriendly and self.isFriendly(id,e.target)) then self:conquer(id,t);progressed=true;break end
                end
            end
        end)
        if not progressed then break end
    end
end
function M:tickAttack(e)
    local troops=e.troops
    if not e.attackActive then e.active=false;return end
    if e.retreated then self:retreat(e,e.target~=0 and 25 or 0);return end
    if e.retreating then return end
    if self.isFriendly and self.isFriendly(e.owner,e.target) then self:retreat(e);return end
    local borderSize=e.border.size+e.random:nextInt(0,5)
    local budget=1
    while budget>0 do
        if troops<1 then self:deleteAttack(e);e.active=false;return end
        if e.heap:size()==0 then self:refresh(e);self:retreat(e);return end
        local t=e.heap:dequeue();e.border:delete(t)
        local owners=self.owners
        if owners[t+1]~=e.target or countOwned(owners,t,e.owner,self.width,self.height)==0 then continue end
        local byte=byteAt(self,t)
        if not passable(byte) then continue end
        self:addNeighbors(e,t)
        local p,d=self.players[e.owner],self.players[e.target]
        local loss,defenseLoss,fraction=A.tile(T.terrainType(byte),troops,p.kind,p.tiles.size,
            d and d.kind,d and d.tiles.size,d and d.troops,d and (d.isTraitor or false),
            d and self.isAwayTeammate~=nil and self.isAwayTeammate(e.owner,e.target),borderSize,
            self.hasDefensePost and self.hasDefensePost(e.target,t) or false,
            self.fallout[t] and self.falloutRatio and self.falloutRatio() or nil)
        budget-=fraction;troops-=loss;e.troops=math.max(0,troops)
        if d then self:removeTroops(e.target,defenseLoss) end
        self:conquer(e.owner,t);self:handleDeadDefender(e)
    end
end
function M:attack(owner,target,troops,sourceTile,removeTroops)
    assert(self.players[owner]);assert(target==0 or self.players[target]);assert(owner~=target)
    assert(troops==nil or (troops==troops and troops>=0 and troops<=9007199254740991))
    self.nextAttackId=(self.nextAttackId or 0)+1
    local e={id=self.nextAttackId,kind="attack",owner=owner,target=target,startTroops=troops,sourceTile=sourceTile,removeTroops=removeTroops~=false,active=true}
    table.insert(self.pending,e);return e
end
function M:orderRetreat(owner)
    for _,attack in ipairs(self.players[owner].outgoing) do
        if not attack.retreating then table.insert(self.pending,{kind="retreat",attack=attack,active=true}) end
    end
end
function M:cancelAttack(owner,id)
    for _,attack in ipairs(self.players[owner].outgoing) do
        if attack.id==id and attack.attackActive and not attack.retreating then
            for _,p in ipairs(self.pending) do if p.kind=="retreat" and p.attack==attack then return false end end
            table.insert(self.pending,{kind="retreat",attack=attack,active=true});return true
        end
    end
    return false
end
function M:step()
    self.captured={}
    if self.beforeTick then self.beforeTick() end
    for _,e in ipairs(self.execs) do
        if e.active then
            if e.kind=="attack" then self:tickAttack(e)
            else
                if not e.ordered then if e.attack.attackActive then e.attack.retreating=true end;e.ordered=true end
                if self.ticks>=e.startTick+20 then if e.attack.attackActive then e.attack.retreated=true end;e.active=false end
            end
        end
    end
    local initialized=self.pending;self.pending={}
    for _,e in ipairs(initialized) do if e.kind=="attack" then self:initAttack(e) else e.startTick=self.ticks end end
    local kept={};for _,e in ipairs(self.execs) do if e.active then table.insert(kept,e) end end
    for _,e in ipairs(initialized) do table.insert(kept,e) end;self.execs=kept;self.ticks+=1
end
function M:snapshot()
    local players={}
    for id=1,self.playerCount do
        local p=self.players[id];local attacks={}
        for _,e in ipairs(p.outgoing) do table.insert(attacks,{troops=e.troops,target=e.target,border=e.border.size,retreating=e.retreating==true,retreated=e.retreated==true}) end
        players[id]={troops=p.troops,tiles=p.tiles.size,attacks=attacks}
    end
    return {tick=self.ticks,players=players,captured=self.captured}
end
return M
