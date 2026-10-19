-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. NationNukeBehavior and NationMIRVBehavior, pinned e02eeba, with
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local F=if script then require(script.Parent.FlightPath) else require("./FlightPath")
local C=if script then require(script.Parent.NationCommon) else require("./NationCommon")
local M={};M.__index=M
local NUKE={"☢️","💥"}
local OVERWHELMED={"💀","🆘","😱","🥺","😭","😞","🫡","👋"}
local VALUE={City=25000,DefensePost=5000,MissileSilo=50000,Port=15000,Factory=15000}
local TARGETABLE,MAX_SAM,SAM_COOLDOWN,MAX_SILO_LEVEL=150,150,90,5
local HESITATION={Easy=2,Medium=4,Hard=8,Impossible=16}
local DENIAL={Easy=75,Medium=65,Hard=55,Impossible=40}
local GAP={Easy=2,Medium=1.5,Hard=1.25,Impossible=1.15}
local MIN_CITIES={Easy=20,Medium=10,Hard=10,Impossible=8}
local STRIKE_MIN_TROOPS,STRIKE_MIN_STACK,STRIKE_MARGIN,STRIKE_SPAWN,PRICE_MEMORY=.5,.5,10,10,3000
function M.new(ai) return setmetatable({a=ai,recent={},atomCost=750000,hydroCost=5000000,atomLast=nil,hydroLast=nil,strikes={}},M) end
local function gold(w,id) return tonumber(B.toString(w:getGold(id))) end
local function alive(w) local out={};for id,p in ipairs(w.sim.players) do if p.tiles.size>0 then table.insert(out,id) end end;return out end
function M:cost(kind) local a=self.a;return tonumber(B.toString(a.world.unitSystem:cost(a.id,kind))) end
function M:heavy() local p=self.a.player;return C.sum(p.incoming)>=p.troops end
function M:mirv()
    local a=self.a;local w,s=a.world,a.world.unitSystem;local r=a.random
    if U.disabled(w.settings,"MIRV") or #C.owned(w,a.id,"MissileSilo")==0 or B.compare(w:getGold(a.id),s:cost(a.id,"MIRV"))<0 then return false end
    if r:chance(HESITATION[a.difficulty]) then return false end
    local valid={};for _,id in ipairs(alive(w)) do if id~=a.id and w.sim.players[id].kind~="BOT" and not C.sameTeam(w,a.id,id) then table.insert(valid,id) end end
    local recent=C.mirvTargets(w)
    local function worth(id) return (not recent[id] or w.sim.ticks-recent[id]>=300) and C.mirvGetsThrough(w,a.id,id) end
    local attackers={}
    for _,id in ipairs(valid) do for _,u in ipairs(C.owned(w,id,"MIRV")) do if u.targetTile and w.sim:owner(u.targetTile)==a.id then table.insert(attackers,id);break end end end
    C.sort(attackers,function(id) return -w.sim.players[id].tiles.size end)
    if attackers[1] and worth(attackers[1]) then self:sendMirv(attackers[1]);return true end
    local denial=self:denialTarget(valid)
    if denial and worth(denial) then self:sendMirv(denial);return true end
    local steamroll=self:steamrollTarget(valid)
    if steamroll and worth(steamroll) then self:sendMirv(steamroll);return true end
    local rival=self:rivalTarget(valid)
    if rival and worth(rival) then self:sendMirv(rival);return true end
    return false
end
function M:rivalTarget(valid)
    local a=self.a;local w=a.world;if not C.smart(a.difficulty) then return nil end
    local min=a.player.tiles.size*.5;local best=nil
    for _,id in ipairs(valid) do
        local size=w.sim.players[id].tiles.size
        if w:friendly(a.id,id) or size<min then continue end
        if best and size<=w.sim.players[best].tiles.size then continue end
        if w:sharesLandBorder(a.id,id) then best=id end
    end
    return best
end
function M:denialTarget(valid)
    local a=self.a;local w=a.world;local land=w.map.meta.landTiles
    if land<=0 then return nil end
    local scaled=land*DENIAL[a.difficulty];local best,severity=nil,0
    for _,id in ipairs(valid) do
        local p=w.sim.players[id];local value=0
        if p.team~=nil then
            local total,largest,size=0,nil,-1
            for mid,q in ipairs(w.sim.players) do if q.tiles.size>0 and q.team==p.team then total+=q.tiles.size;if q.tiles.size>size then size=q.tiles.size;largest=mid end end end
            if total*100>=scaled and largest==id then value=total end
        elseif p.tiles.size*100>=scaled then value=p.tiles.size end
        if value>0 and value>severity then best=id;severity=value end
    end
    return best
end
function M:steamrollTarget(valid)
    local a=self.a;local w=a.world;if #valid==0 then return nil end
    local cities={};for _,u in ipairs(C.units(w,"City")) do if u.active then cities[u.owner or 1]=(cities[u.owner or 1] or 0)+u.level end end
    local players=alive(w);C.sort(players,function(id) return -(cities[id] or 0) end)
    if #players<2 then return nil end
    local top=cities[players[1]] or 0
    if top<=MIN_CITIES[a.difficulty] or top<(cities[players[2]] or 0)*GAP[a.difficulty] then return nil end
    return table.find(valid,players[1]) and players[1] or nil
end
function M:sendMirv(enemy)
    local a=self.a;local w,s=a.world,a.world.unitSystem;local r=a.random
    a.diplomacy:attackEmoji(enemy)
    local center=C.center(w,enemy)
    if center and s:preview(a.id,"MIRV",center).valid and s:build(a.id,"MIRV",center) then
        C.mirvTargets(w)[enemy]=w.sim.ticks;a.diplomacy:emoji(0,NUKE)
        if r:chance(8) then local e=r:randElement(OVERWHELMED);if w.sim.players[enemy].kind=="NATION" and w.aiEmoji then w:aiEmoji(enemy,0,e) end end
    end
end
function M:choose()
    local target=self:target();if not target then return nil,false end
    local d=self.a.difficulty
    if d=="Easy" then return target,false end
    if d=="Medium" then return target,self:troopsAttacking(target)>0 end
    return target,self:canStrike(target)
end
function M:target()
    local a=self.a;local w=a.world;local d=a.difficulty;local living=alive(w)
    if C.smart(d) and #living==2 then for _,id in ipairs(living) do if id~=a.id then return id end end end
    local incoming=a:incoming();if incoming then return incoming end
    local bomber=self:incomingNuke();if bomber then return bomber end
    local fight=self:teammateFight();if fight then return fight end
    local free=w:landTiles()-(w.falloutTiles or 0)
    if d=="Impossible" and not C.team(w,a.id) and free>0 then
        local crown=self:byTiles(living)[1]
        if crown and crown~=a.id and not w:friendly(a.id,crown) and w.sim.players[crown].tiles.size/free>.5 then return crown end
    end
    local strike=self:strikeTarget();if strike then return strike end
    if d=="Impossible" and self:richest() and a.random:chance(2) then local dense=self:denseTarget();if dense then return dense end end
    if w.unitSystem.comms then for _,ally in ipairs(C.allies(w,a.id)) do
        if w:relation(a.id,ally)<50 then continue end
        for _,t in ipairs(w.unitSystem.comms.targets) do if t.owner==ally and w.sim.ticks-t.tick<100 and t.target~=a.id and not w:friendly(a.id,t.target) then return t.target end end
    end end
    local mine=w:maxTroops(a.id)
    for _,id in ipairs(self:hated()) do if not w:friendly(a.id,id) and mine<w:maxTroops(id)*2 then return id end end
    return self:crownTarget(living) or self:teamTarget(living)
end
function M:hated()
    local a=self.a;local w=a.world;local resource=w.resources[a.id];local order=resource.relationOrder
    if not order then order={};for id=1,#w.sim.players do if (resource.relations or {})[id]~=nil then table.insert(order,id) end end end
    local ids={};for _,id in ipairs(order) do if resource.relations[id]< -50 and w.sim.players[id].tiles.size>0 then table.insert(ids,id) end end
    return C.sort(ids,function(id) return w:relation(a.id,id) end)
end
function M:byTiles(ids) local w=self.a.world;return C.sort(table.clone(ids),function(id) return -w.sim.players[id].tiles.size end) end
function M:richest()
    local a=self.a;local w=a.world;local mine=w:getGold(a.id)
    for _,id in ipairs(alive(w)) do if id~=a.id and w.sim.players[id].kind=="NATION" and B.compare(w:getGold(id),mine)>0 then return false end end
    return true
end
function M:denseTarget()
    local a=self.a;local w=a.world;local best,density=nil,1/75
    for _,id in ipairs(alive(w)) do if id~=a.id and w.sim.players[id].kind~="BOT" and not w:friendly(a.id,id) then
        local sum=self:structureLevels(id)
        if sum>=5 and sum/w.sim.players[id].tiles.size>density then best=id;density=sum/w.sim.players[id].tiles.size end
    end end
    return best
end
function M:structureLevels(id)
    local sum=0;for _,u in ipairs(self.a.world.units) do if u.active and u.owner==id and U.structures[u.kind] then sum+=u.level end end;return sum
end
function M:incomingNuke()
    local a=self.a;local w=a.world;local best=nil
    for _,kind in ipairs({"AtomBomb","HydrogenBomb"}) do for _,u in ipairs(C.units(w,kind)) do
        local sender=u.owner or 1
        if u.active and (not best or sender<best) and not w:friendly(a.id,sender) and u.targetTile and w.sim:owner(u.targetTile)==a.id then best=sender end
    end end
    return best
end
function M:teammateFight()
    local a=self.a;local w=a.world
    if not C.team(w,a.id) or a.difficulty=="Easy" then return nil end
    local function enemy(id) return id~=0 and w.sim.players[id].kind~="BOT" and not w:friendly(a.id,id) end
    local best,most=nil,0
    for id,mate in ipairs(w.sim.players) do if id~=a.id and mate.tiles.size>0 and C.sameTeam(w,a.id,id) then
        for _,attack in ipairs(mate.incoming) do if enemy(attack.owner) and attack.troops>most then best=attack.owner;most=attack.troops end end
    end end
    if best then return best end
    for id,mate in ipairs(w.sim.players) do if id~=a.id and mate.tiles.size>0 and C.sameTeam(w,a.id,id) then
        for _,attack in ipairs(mate.outgoing) do if enemy(attack.target) and attack.troops>most then best=attack.target;most=attack.troops end end
    end end
    return best
end
function M:strikeTarget()
    local a=self.a;local w=a.world;local d=a.difficulty;local mine=a.player.troops
    local function candidate(id) return id~=0 and w.sim.players[id].kind~="BOT" and not w:friendly(a.id,id) and w.sim.players[id].troops>=mine*STRIKE_MIN_TROOPS end
    if d=="Easy" then return nil end
    if d=="Medium" then for _,attack in ipairs(a.player.outgoing) do if candidate(attack.target) then return attack.target end end;return nil end
    local best=nil
    for _,id in ipairs(w:nearby(a.id)) do
        if not candidate(id) then continue end
        if best and w.sim.players[id].troops<=w.sim.players[best].troops then continue end
        if self:canStrike(id) then best=id end
    end
    return best
end
function M:canStrike(id)
    local a=self.a;local w=a.world
    return w.sim.players[id].kind~="BOT" and not w:friendly(a.id,id) and self:strikeTroops(id)>=w.sim.players[id].troops*STRIKE_MIN_STACK and w:sharesLandBorder(a.id,id)
end
function M:strikeTroops(id) local a=self.a;return math.min(a.player.troops-a.world:maxTroops(a.id)*a.reserve,a:sendCap(id)) end
function M:troopsAttacking(id) local n=0;for _,attack in ipairs(self.a.player.outgoing) do if attack.target==id then n+=attack.troops end end;return n end
function M:followsUp() return C.smart(self.a.difficulty) end
function M:followUpStrikes()
    local a=self.a;local w=a.world
    if self:followsUp() and #C.owned(w,a.id,"MIRV")>0 then self:trackMirvStrikes() end
    if #self.strikes==0 then return end
    local nuclear=w.unitSystem.nuclear;local pending={}
    for _,strike in ipairs(self.strikes) do
        strike.nuke=strike.nuke or self:strikeNuke(strike.tile)
        local nuke=strike.nuke
        if not nuke then if w.sim.ticks-strike.tick<=STRIKE_SPAWN then table.insert(pending,strike) end;continue end
        if nuke.active then
            local d=nuclear.data[nuke.id];strike.final=d==nil or d.index>=#d.path-1
            table.insert(pending,strike);continue
        end
        if nuke.kind=="MIRV" then
            if #C.owned(w,a.id,"MIRVWarhead")>0 then table.insert(pending,strike);continue end
        elseif strike.final==false or w.sim:owner(nuke.targetTile)~=0 then continue end
        if w.sim.players[strike.target].tiles.size>0 then self:strike(strike.target) end
    end
    self.strikes=pending
end
function M:strike(id)
    local a=self.a;local w=a.world
    if w:friendly(a.id,id) or not w:sharesLandBorder(a.id,id) then return false end
    return a:land(id,nil,id)
end
function M:trackMirvStrikes()
    local a=self.a;local w=a.world
    for _,mirv in ipairs(C.owned(w,a.id,"MIRV")) do
        local tracked=false;for _,s in ipairs(self.strikes) do if s.nuke==mirv then tracked=true;break end end
        local target=mirv.target
        if tracked or not target or target==0 or not mirv.targetTile or w:friendly(a.id,target) or not w:sharesLandBorder(a.id,target) then continue end
        table.insert(self.strikes,{target=target,tile=mirv.targetTile,tick=w.sim.ticks,nuke=mirv})
    end
end
function M:strikeNuke(tile)
    local a=self.a
    for _,u in ipairs(a.world.units) do
        if u.active and u.owner==a.id and (u.kind=="AtomBomb" or u.kind=="HydrogenBomb") and u.targetTile==tile then
            local taken=false;for _,s in ipairs(self.strikes) do if s.nuke==u then taken=true;break end end
            if not taken then return u end
        end
    end
    return nil
end
function M:crownTarget(living)
    local a=self.a;local w=a.world;local d=a.difficulty
    if C.team(w,a.id) or #living<=1 then return nil end
    local sorted=self:byTiles(living);local first=sorted[1]
    if first==a.id or w:friendly(a.id,first) then return nil end
    local free=w:landTiles()-(w.falloutTiles or 0);if free<=0 then return nil end
    local share=w.sim.players[first].tiles.size/free
    if share>.5 then return first end
    if C.leader(w,a.id)~=first then return nil end
    local threshold=({Medium=.3,Hard=.2,Impossible=.1})[d];if not threshold then return nil end
    if not w:sharesLandBorder(a.id,first) then threshold*=2 end
    return share-a.player.tiles.size/free>threshold and first or nil
end
function M:teamTarget(living)
    local a=self.a;local w=a.world;local r=a.random
    if not C.team(w,a.id) or #living<=1 then return nil end
    local tiles,members,order={},{},{}
    for _,id in ipairs(living) do local team=w.sim.players[id].team;if team~=nil then
        if not tiles[team] then tiles[team]=0;members[team]={};table.insert(order,team) end
        tiles[team]+=w.sim.players[id].tiles.size;table.insert(members[team],id)
    end end
    C.sort(order,function(team) return -tiles[team] end)
    local strongest=order[1];if strongest==nil then return nil end
    if strongest==a.player.team then strongest=order[2];if strongest==nil then return nil end end
    local targets={};for _,id in ipairs(members[strongest]) do if not w:friendly(a.id,id) then table.insert(targets,id) end end
    if #targets==0 then return nil end
    if C.smart(a.difficulty) then
        local most={};for _,id in ipairs(targets) do local levels=self:structureLevels(id);if levels>0 then table.insert(most,{id=id,levels=levels}) end end
        C.sort(most,function(e) return -e.levels end)
        local top={};for i=1,math.min(3,#most) do top[i]=most[i] end
        if #top>0 then return r:randElement(top).id end
    end
    if r:chance(2) then local best=targets[1];for i=2,#targets do if not (w:maxTroops(best)>w:maxTroops(targets[i])) then best=targets[i] end end;return best end
    return r:randElement(targets)
end
function M:perceived(kind)
    local real=self:cost(kind)
    if self:paysReal() then return real end
    if not self:forgets() and not C.mirvWorthSavingFor(self.a.world,self.a.id) then return real end
    return self:inflated(kind)
end
function M:paysReal()
    local a=self.a;local w=a.world;local g=gold(w,a.id)
    if #alive(w)==2 or U.disabled(w.settings,"MIRV") or C.team(w,a.id) and g>self:cost("HydrogenBomb") then return true end
    return g>self:mirvSaveUp() or C.smart(a.difficulty) and self:heavy()
end
function M:forgets() return C.smart(self.a.difficulty) and not C.team(self.a.world,self.a.id) end
function M:inflated(kind)
    local real=self:cost(kind)
    local perceived,last=if kind=="AtomBomb" then self.atomCost else self.hydroCost,if kind=="AtomBomb" then self.atomLast else self.hydroLast
    if perceived<=real then return real end
    if not self:forgets() then return perceived end
    local left=last==nil and 0 or PRICE_MEMORY-(self.a.world.sim.ticks-last)
    if left<=0 then return real end
    return real+math.floor((perceived-real)*left/PRICE_MEMORY)
end
function M:saving()
    local a=self.a
    return self:forgets() and not self:paysReal() and C.mirvWorthSavingFor(a.world,a.id) and C.saveUpWithinReach(a.world,a.id,self:mirvSaveUp())
end
function M:mirvSaveUp() return self:cost("MIRV")+self:cost("HydrogenBomb") end
function M:hittingUs(id)
    local a=self.a;local w=a.world
    for _,attack in ipairs(a.player.incoming) do if attack.owner==id then return true end end
    for _,kind in ipairs({"AtomBomb","HydrogenBomb","MIRV","MIRVWarhead"}) do for _,u in ipairs(C.owned(w,id,kind)) do
        if u.targetTile and w.sim:owner(u.targetTile)==a.id then return true end
    end end
    return false
end
function M:send()
    local a=self.a;local w,s=a.world,a.world.unitSystem;local set=w.settings;local d=a.difficulty
    local silos=C.owned(w,a.id,"MissileSilo")
    if #silos==0 or U.disabled(set,"MissileSilo") or U.disabled(set,"AtomBomb") and U.disabled(set,"HydrogenBomb") then return end
    local target,strike=self:choose();if not target then return end
    if w.sim.players[target].kind=="BOT" or C.sameTeam(w,a.id,target) or not a:shouldAttack(target) then return end
    local saving=self:saving()
    if saving and not self:hittingUs(target) then return end
    local kinds=self:kinds(saving);if #kinds==0 then return end
    local structures={};for _,u in ipairs(w.units) do if u.active and u.owner==target and U.structures[u.kind] then table.insert(structures,u) end end
    local tiles=C.randTiles(w,a.random,target,d=="Impossible" and 30 or 10)
    for _,u in ipairs(structures) do table.insert(tiles,u.tile) end
    local candidates,seen={},{};for _,t in ipairs(tiles) do if not seen[t] then seen[t]=true;table.insert(candidates,t) end end
    self:prune()
    for _,kind in ipairs(kinds) do
        local best=self:aim(kind,target,silos,candidates,structures,strike)
        if best then
            if self:launch(best,kind,target,0) and strike and self:followsUp() then table.insert(self.strikes,{target=target,tile=best,tick=w.sim.ticks,nuke=nil}) end
            return
        end
    end
    if d=="Impossible" and not saving then self:destroySam(target) end
end
function M:kinds(atomOnly)
    local a=self.a;local set=a.world.settings;local g=gold(a.world,a.id);local out={}
    if not atomOnly and not U.disabled(set,"HydrogenBomb") and g>=self:perceived("HydrogenBomb") then table.insert(out,"HydrogenBomb") end
    if (#out==0 or C.smart(a.difficulty)) and not U.disabled(set,"AtomBomb") and g>=self:perceived("AtomBomb") then table.insert(out,"AtomBomb") end
    return out
end
local MIN_COVERAGE={AtomBomb=.25,HydrogenBomb=.4}
local FULL_COVERAGE=50000
function M:aim(kind,target,silos,candidates,structures,strike)
    local a=self.a;local w,s=a.world,a.world.unitSystem;local d=a.difficulty
    local _,range=U.magnitude(kind)
    local sams=self:hostileSams()
    local scored={}
    for i,tile in ipairs(candidates) do
        if not self:area(tile,range,target) or not self:area(tile,math.floor(range/2),target) then continue end
        local p=s:preview(a.id,kind,tile);if not p.valid then continue end
        local coverage=0
        if d~="Easy" then
            if self:landing(tile,kind) then continue end
            coverage=self:coverage(tile,kind);if coverage<MIN_COVERAGE[kind] then continue end
        end
        if C.smart(d) and self:interceptable(p.tile,tile,sams) then continue end
        local v=self:score(tile,silos,structures,kind)
        if (d=="Impossible" and not strike and v<=0) or v<0 then continue end
        table.insert(scored,{tile=tile,score=v+coverage*FULL_COVERAGE,i=i})
    end
    table.sort(scored,function(x,y) return x.score>y.score or x.score==y.score and x.i<y.i end)
    local margin=strike and STRIKE_MARGIN or 0
    for _,c in ipairs(scored) do if not self:hitsFriendly(c.tile,kind,margin) then return c.tile end end
    return nil
end
function M:landing(tile,kind)
    local w=self.a.world;local inner=U.magnitude(kind)
    for _,k in ipairs({"AtomBomb","HydrogenBomb","MIRVWarhead"}) do for _,u in ipairs(C.units(w,k)) do
        if u.active and u.targetTile then local r=inner+U.magnitude(u.kind);if w:distance2(tile,u.targetTile)<=r*r then return true end end
    end end
    return false
end
function M:coverage(center,kind)
    local a=self.a;local w=a.world;local width,height=w.map.meta.width,w.map.meta.height
    local inner,outer=U.magnitude(kind);local step=math.max(1,math.floor(outer/10));local cx,cy=center%width,math.floor(center/width)
    local total,enemy=0,0
    for dy=-outer,outer,step do for dx=-outer,outer,step do
        local d2=dx*dx+dy*dy
        if d2>outer*outer then continue end
        local weight=d2<=inner*inner and 2 or 1;total+=weight
        local x,y=cx+dx,cy+dy
        if x<0 or y<0 or x>=width or y>=height then continue end
        local owner=w.sim:owner(y*width+x)
        if owner~=0 and not w:friendly(a.id,owner,true) then enemy+=weight end
    end end
    return enemy/total
end
function M:hitsFriendly(center,kind,margin)
    local a=self.a;local w=a.world;local width,height=w.map.meta.width,w.map.meta.height
    local friends={};for id in ipairs(w.sim.players) do if w:friendly(a.id,id,true) then friends[id]=true end end
    local _,outer=U.magnitude(kind);outer+=margin or 0;local cx,cy=center%width,math.floor(center/width)
    for y=math.max(0,cy-outer),math.min(height-1,cy+outer) do
        local dy=y-cy
        for x=math.max(0,cx-outer),math.min(width-1,cx+outer) do
            local dx=x-cx
            if dx*dx+dy*dy<=outer*outer and friends[w.sim:owner(y*width+x)] then return true end
        end
    end
    return false
end
function M:area(tile,radius,target)
    local a=self.a;local w=a.world;local width,height=w.map.meta.width,w.map.meta.height;local cx,cy=tile%width,math.floor(tile/width)
    local smart=C.smart(a.difficulty);local team=C.team(w,a.id);local nav=w.unitSystem.nav
    local function ok(x,y)
        if x<0 or y<0 or x>=width or y>=height then return true end
        local t=y*width+x;local owner=w.sim:owner(t)
        if owner==target then return true end
        if smart then return owner==0 or not w:friendly(a.id,owner,true) end
        return owner==0 and nav:water(t)
    end
    for x=cx-radius,cx+radius do if not ok(x,cy-radius) or not ok(x,cy+radius) then return false end end
    for y=cy-radius+1,cy+radius-1 do if not ok(cx-radius,y) or not ok(cx+radius,y) then return false end end
    return true
end
function M:prune() local tick=self.a.world.sim.ticks;while self.recent[1] and self.recent[1].tick+600<tick do table.remove(self.recent,1) end end
function M:hostileSams()
    local a=self.a;local w=a.world;local out={}
    for _,u in ipairs(C.units(w,"SAMLauncher")) do if u.active and u.owner~=a.id and not w:friendly(a.id,u.owner) then table.insert(out,u) end end
    return out
end
function M:interceptable(src,dst,sams,excluded)
    local w=self.a.world;local width,height=w.map.meta.width,w.map.meta.height
    local path=F.parabola(width,height,src,dst,U.nukeSpeed("AtomBomb"),true)
    if #path==0 then return false end
    local range2=TARGETABLE*TARGETABLE;local start,stop=nil,nil
    for i,t in ipairs(path) do
        if not start then
            if w:distance2(t,src)>range2 then if w:distance2(t,dst)<range2 then break end;start=i end
        elseif w:distance2(t,dst)<range2 then stop=i;break end
    end
    local i=1
    while i<=#path do
        if start and stop and i==start then i=stop;continue end
        local t=path[i]
        for _,sam in ipairs(sams) do
            if excluded and excluded[sam.id] then continue end
            local d2=w:distance2(sam.tile,t);local range=U.samRange(sam.level)
            if d2<=MAX_SAM*MAX_SAM and d2<=range*range then return true end
        end
        i+=1
    end
    return false
end
function M:score(tile,silos,structures,kind)
    local a=self.a;local w=a.world;local d=a.difficulty;local inner,outer=U.magnitude(kind);local value=0
    for _,u in ipairs(structures) do if w:distance2(tile,u.tile)<=outer*outer then value+=(VALUE[u.kind] or 0)*u.level end end
    if d=="Medium" then for _,u in ipairs(structures) do if u.kind=="SAMLauncher" and w:distance2(tile,u.tile)<=2500 then return -1 end end end
    if d=="Impossible" and kind=="HydrogenBomb" then
        for _,sam in ipairs(C.units(w,"SAMLauncher")) do
            local d2=w:distance2(tile,sam.tile)
            if sam.active and sam.level<5 and d2<=outer*outer and math.sqrt(d2)>U.samRange(sam.level) then value+=100000*sam.level end
        end
    end
    local tiles={};for _,u in ipairs(silos) do table.insert(tiles,u.tile) end
    local silo=C.closest(w.map.meta.width,tiles,{tile})
    local base=value;value=math.max(base*.2,value-math.sqrt(w:distance2(tile,silo))*30)
    for _,r in ipairs(self.recent) do local ri=U.magnitude(r.kind);if w:distance2(tile,r.tile)<=ri*ri then value-=1000000 end end
    return value
end
function M:launch(tile,kind,target,wait)
    local a=self.a;local w,s=a.world,a.world.unitSystem
    local perceived=self:inflated(kind)
    if not s:build(a.id,kind,tile) then return false end
    local u=w.units[#w.units];if wait>0 and u and u.kind==kind and u.owner==a.id then u.waitTicks+=wait end
    table.insert(self.recent,{tick=w.sim.ticks,tile=tile,kind=kind})
    if kind=="AtomBomb" then self.atomCost=math.floor(perceived*150/100);self.atomLast=w.sim.ticks else self.hydroCost=math.floor(perceived*125/100);self.hydroLast=w.sim.ticks end
    a.diplomacy:maybeEmoji(target,NUKE)
    return true
end
function M:destroySam(target)
    local a=self.a;local w,s=a.world,a.world.unitSystem;local width,height=w.map.meta.width,w.map.meta.height
    if U.disabled(w.settings,"AtomBomb") or #C.owned(w,a.id,"AtomBomb")>0 then return end
    local enemySams=C.owned(w,target,"SAMLauncher");if #enemySams==0 then return end
    local silos={};for _,u in ipairs(C.owned(w,a.id,"MissileSilo")) do if not u.building then table.insert(silos,u) end end
    if #silos==0 then return end
    local atom=self:cost("AtomBomb");local hostile=self:hostileSams();local failed=nil
    C.sort(enemySams,function(u) return u.level end)
    for _,sam in ipairs(enemySams) do
        local targetTile=sam.tile;local covering,interceptions={},0
        if self:hitsFriendly(targetTile,"AtomBomb") then continue end
        for _,other in ipairs(hostile) do local range=U.samRange(other.level);if w:distance2(other.tile,targetTile)<=range*range then covering[other.id]=true;interceptions+=other.level end end
        local available={}
        for _,silo in ipairs(silos) do
            local slots=silo.level-#(silo.missileQueue or {});if slots<=0 then continue end
            local blocked=self:interceptable(silo.tile,targetTile,hostile,covering)
            local flight=#F.parabola(width,height,silo.tile,targetTile,U.nukeSpeed("AtomBomb"),true)
            if flight>0 then table.insert(available,{silo=silo,slots=slots,flight=flight,blocked=blocked}) end
        end
        C.sort(available,function(e) return C.manhattan(width,e.silo.tile,targetTile) end)
        local sequence={};for _,e in ipairs(available) do for _=1,e.slots do table.insert(sequence,e) end end
        local spread=math.floor(SAM_COOLDOWN/2);local needed=interceptions+1;local total=needed+math.floor(needed/5)
        local open={};for i,e in ipairs(sequence) do if not e.blocked then table.insert(open,{index=i,flight=e.flight}) end end
        if #open<total then failed=failed or {tile=targetTile,covering=covering,total=total};continue end
        local byFlight=C.sort(table.clone(open),function(b) return b.flight end)
        local start,count=1,0
        for i=1,#byFlight do local j=i;while j<=#byFlight and byFlight[j].flight-byFlight[i].flight<=spread do j+=1 end;if j-i>count then count=j-i;start=i end end
        if count<total then failed=failed or {tile=targetTile,covering=covering,total=total};continue end
        local window={};for i=start,start+count-1 do table.insert(window,byFlight[i]) end
        C.sort(window,function(b) return b.index end)
        local selected,chosen,first={},{},math.huge
        for i=1,total do selected[i]=window[i];chosen[window[i].index]=true;first=math.min(first,window[i].flight) end
        local fire=selected[#selected].index;local stagger=math.max(1,math.floor(spread/total))
        local waits,k={},0
        for i=1,fire do if chosen[i] then waits[i]=math.max(0,first+k*stagger-sequence[i].flight);k+=1 else waits[i]=0 end end
        if gold(w,a.id)<atom*fire then continue end
        for i=1,fire do self:launch(targetTile,"AtomBomb",target,waits[i]) end
        return
    end
    if failed then self:upgradeSilo(failed,hostile) end
end
function M:upgradeSilo(failed,hostile)
    local a=self.a;local w,s=a.world,a.world.unitSystem
    local open={};for _,silo in ipairs(C.owned(w,a.id,"MissileSilo")) do if not self:interceptable(silo.tile,failed.tile,hostile,failed.covering) then table.insert(open,silo) end end
    if #open==0 or #open*MAX_SILO_LEVEL<failed.total then return end
    local ours=C.owned(w,a.id,"SAMLauncher");local best,protection=nil,-1
    for _,silo in ipairs(open) do
        if silo.level>=MAX_SILO_LEVEL or silo.building or silo.deleteAt or B.compare(w:getGold(a.id),s:cost(a.id,"MissileSilo"))<0 then continue end
        local value=0;for _,sam in ipairs(ours) do local range=U.samRange(sam.level);if w:distance2(silo.tile,sam.tile)<=range*range then value+=sam.level end end
        if value>protection then best=silo;protection=value end
    end
    if best then s:upgrade(a.id,best.id) end
end
return M
