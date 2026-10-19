--!native
-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors, pinned e02eeba. NationExecution and AiAttackBehavior,
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local Tribe=if script then require(script.Parent.TribeAI) else require("./TribeAI")
local C=if script then require(script.Parent.NationCommon) else require("./NationCommon")
local Diplomacy=if script then require(script.Parent.NationDiplomacy) else require("./NationDiplomacy")
local Structures=if script then require(script.Parent.NationStructures) else require("./NationStructures")
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local Arms=if script then require(script.Parent.NationArms) else require("./NationArms")
local Warships=if script then require(script.Parent.NationWarships) else require("./NationWarships")
local Nukes=if script then require(script.Parent.NationNukes) else require("./NationNukes")
local Annex=if script then require(script.Parent.NationBotAnnex) else require("./NationBotAnnex")
local AttackLogic=if script then require(script.Parent.AttackLogic) else require("./AttackLogic")
local M={};M.__index=M
function M.new(w,id,key)
    local r=R.new(Tribe.hash(key)+Tribe.hash(w.settings.seed or "frontier"))
    local self=setmetatable({world=w,id=id,player=w.sim.players[id],random=r,difficulty=w.settings.difficulty or "Medium",botSent=0,active=true,initialized=false,embargoMalus={}},M)
    self.trigger=r:nextInt(50,60)/100;self.reserve=r:nextInt(30,40)/100;self.expand=r:nextInt(10,20)/100
    local range=({Easy={65,100},Medium={55,70},Hard={45,60},Impossible={30,50}})[self.difficulty]
    assert(range,"Unsupported nation difficulty")
    self.rate=r:nextInt(range[1],range[2]);self.offset=r:nextInt(0,self.rate)
    self.diplomacy=Diplomacy.new(self);self.structures=Structures.new(self)
    if w.unitSystem then self.arms=Arms.new(self);self.warships=Warships.new(self);self.nukes=Nukes.new(self) end
    return self
end
function M:spawnCell(cell)
    local w=self.world;local width,height=w.map.meta.width,w.map.meta.height
    for _=1,50 do
        local x,y=self.random:nextInt(cell.x-25,cell.x+25),self.random:nextInt(cell.y-25,cell.y+25)
        if x<0 or y<0 or x>=width or y>=height then continue end
        local tile=y*width+x;local b=w.sim.terrain[tile+1]
        if T.isLand(b) and not T.isImpassable(b) and w.sim:owner(tile)==0 then
            if T.terrainType(b)==2 and self.random:chance(2) then continue end
            return tile
        end
    end
    return nil
end
function M:incoming()
    local w=self.world;local target,largest=nil,0
    for _,attack in ipairs(self.player.incoming) do
        if w.sim.players[attack.owner].kind~="BOT" and not w:friendly(self.id,attack.owner) and attack.troops>largest then target=attack.owner;largest=attack.troops end
    end
    return target
end
function M:neighborCap(ignore)
    local keep=({Hard=.75,Impossible=.9})[self.difficulty];if not keep or self.player.team~=nil then return math.huge end
    local w=self.world;local most=0
    for _,id in ipairs(w:nearby(self.id)) do if id~=0 and id~=ignore and not w:friendly(self.id,id) and w.sim.players[id].kind~="BOT" then most=math.max(most,w.sim.players[id].troops) end end
    return most==0 and math.huge or math.max(0,self.player.troops-math.ceil(most*keep))
end
function M:sendCap(ignore) local cap=self:neighborCap(ignore);if #self.player.incoming>0 then cap=math.max(cap,C.sum(self.player.incoming)) end;return cap end
function M:expansionCap() local cap=self:sendCap();if cap>0 then return cap end;return math.ceil(self.player.troops*.05) end
function M:tooWeak(troops,target)
    return C.smart(self.difficulty) and self.player.team==nil and #self.player.incoming==0 and troops<self.world.sim.players[target].troops*.2
end
function M:troops(target,amount,opponent)
    local w,p=self.world,self.player;local other=w.sim.players[target]
    local bot=other and other.kind=="BOT"
    local ratio=target~=0 and not (bot and C.ownsStructures(w,target)) and self.reserve or self.expand
    local reserve=self:reserveBasis(target==0 or bot)*ratio;local troops=p.troops-reserve
    if bot then troops=self:botTroops(target,troops-self.botSent)
    elseif amount then troops=amount end
    troops=math.min(troops,target==0 and self:expansionCap() or self:sendCap(opponent))
    if troops<1 then return nil end
    local pile=target~=0 and target==opponent and C.sum(other.incoming) or 0
    if other and self:tooWeak(troops+pile,target) then return nil end
    if other then self.diplomacy:attackEmoji(target) end
    if bot then self.botSent+=troops end
    return troops
end
function M:land(target,amount,opponent)
    local troops=self:troops(target,amount,opponent);if not troops then return false end
    self.world.sim:attack(self.id,target,troops);return true
end
function M:shouldAttack(id)
    local other=self.world.sim.players[id]
    if not other or other.kind~="HUMAN" or other.isTraitor or self.world.settings.humansVsNations then return true end
    if self.difficulty=="Easy" and self.random:nextInt(0,4)~=0 then return false end
    if self.difficulty=="Medium" and self.random:chance(4) then return false end
    return true
end
function M:bordersByLand(id)
    local cache=self.landCache;local w=self.world
    if not cache or not w.unitSystem then return w:sharesLandBorder(self.id,id) end
    local set=cache.set
    if not set then
        set={};cache.set=set;local sim=w.sim;local width,height=w.map.meta.width,w.map.meta.height;local last=(height-1)*width
        local function check(n) local o=sim:owner(n);if not set[o] then local b=sim.terrain[n+1];if T.isLand(b) and not T.isImpassable(b) then set[o]=true end end end
        self.player.border:forEach(function(t) local x=t%width;if t>=width then check(t-width) end;if t<last then check(t+width) end;if x~=0 then check(t-1) end;if x~=width-1 then check(t+1) end end)
    end
    return set[id]==true
end
function M:canReach(id) return self:bordersByLand(id) or self.arms~=nil and self.arms:reach(id) end
function M:send(id,force)
    if not force and not self:shouldAttack(id) then return false end
    if not self:bordersByLand(id) then
        if not self.arms then return false end
        if id==0 then return self.arms:neutralBoat() end
        return self.arms:attack(id)
    end
    return self:land(id)
end
function M:retaliate()
    local id=self:incoming();if not id then return false end
    local w,p=self.world,self.player
    if not C.smart(self.difficulty) or p.team~=nil or not self:bordersByLand(id) then return self:send(id,true) end
    local incoming,pressing=0,0
    for _,a in ipairs(p.incoming) do if a.owner==id then incoming+=a.troops end end
    for _,a in ipairs(p.outgoing) do if a.target==id then pressing+=a.troops end end
    local max=w:maxTroops(self.id)
    local spare=math.min(p.troops-max*self.expand,self:neighborCap(id))
    local above=p.troops-max*self.reserve;local counter=incoming+math.max(0,w.sim.players[id].troops-pressing)
    local send=spare>=counter and math.max(counter,math.min(above,spare)) or math.min(incoming,math.max(spare,above))
    return self:land(id,send,id)
end
function M:attackBots()
    local w=self.world;local ids=self:neighboringBots()
    if #ids==0 then return false end
    self.botSent=0
    local ordered
    if self:annexesBots() then ordered=Annex.plan(w,self.id,ids)
    else ordered=C.sort(ids,function(id) local p=w.sim.players[id];return p.troops/p.tiles.size end) end
    local owning,rest={},{}
    for _,id in ipairs(ordered) do table.insert(C.ownsStructures(w,id) and owning or rest,id) end
    for _,id in ipairs(rest) do table.insert(owning,id) end
    local count=self.difficulty=="Easy" and 1 or self.difficulty=="Hard" and 3 or self.difficulty=="Impossible" and 100 or (self.random:chance(2) and 1 or 2)
    local reduced={};for i=1,math.min(#owning,count) do reduced[owning[i]]=true;self:send(owning[i]) end
    if self.botSent>0 then return true end
    if self:annexesBots() then for _,attack in ipairs(self.player.outgoing) do if reduced[attack.target] then return true end end end
    return false
end
function M:neighboringBots()
    local w=self.world;local ids={}
    for _,id in ipairs(w:nearby(self.id)) do if id~=0 and w.sim.players[id].kind=="BOT" and not w:friendly(self.id,id) then table.insert(ids,id) end end
    return ids
end
function M:annexesBots() return self.player.kind=="NATION" and C.smart(self.difficulty) end
function M:annexWalledInBots()
    if not self:annexesBots() then return end
    local bots=self:neighboringBots();if #bots==0 then return end
    local troops=math.floor(self.player.troops/100);if troops<1 then return end
    for _,bot in ipairs(Annex.walledIn(self.world,self.id,bots)) do self.world.sim:attack(self.id,bot,troops) end
end
function M:reserveBasis(expansion)
    if expansion and self.structures:highGold() then return C.maxTroopsWithoutCities(self.world,self.id) end
    return self.world:maxTroops(self.id)
end
function M:hasTrigger(expansion) return self.player.troops/self:reserveBasis(expansion)>=self.trigger end
function M:botTroops(target,budget)
    local other=self.world.sim.players[target]
    if self.difficulty=="Easy" then return budget end
    if self.difficulty=="Medium" then
        if other.troops*4>budget then return budget<other.troops*2 and 0 or budget end
        return other.troops*4
    end
    local troops=self:botTroopsNeeded(target)*1.3-self:stackAgainst(target)
    return troops<=budget and troops or 0
end
function M:botTroopsNeeded(target)
    local bot=self.world.sim.players[target]
    local stack=math.max(1,bot.troops/.6);local tiles=math.max(0,bot.tiles.size-100)
    return math.max(stack,tiles*self:botTileLoss(target,stack))
end
function M:botTileLoss(target,stack)
    local w,p=self.world,self.player;local bot=w.sim.players[target];local terrains={}
    local box=self.difficulty=="Impossible" and C.box(w,target) or nil
    if box then
        local width,height=box[3]-box[1]+1,box[4]-box[2]+1;local mapWidth=w.map.meta.width
        for i=0,5 do for j=0,5 do
            local tile=(box[2]+math.floor((2*j+1)*height/12))*mapWidth+box[1]+math.floor((2*i+1)*width/12)
            if w.sim:owner(tile)==target then table.insert(terrains,T.terrainType(w.sim.terrain[tile+1])) end
        end end
    end
    if #terrains==0 then table.insert(terrains,1) end
    local loss=0
    for _,terrain in ipairs(terrains) do
        loss+=(AttackLogic.tile(terrain,stack,p.kind,p.tiles.size,bot.kind,bot.tiles.size,bot.troops,bot.isTraitor==true,false,1,false,nil))
    end
    return loss/#terrains
end
function M:stackAgainst(target)
    local troops=0
    for _,attack in ipairs(self.player.outgoing) do if attack.target==target and attack.sourceTile==nil then troops+=attack.troops end end
    for _,attack in ipairs(self.player.incoming) do if attack.owner==target then troops-=attack.troops end end
    return troops
end
function M:donate()
    local w,p,d=self.world,self.player,self.difficulty
    if not p.team or d=="Easy" or w.winnerId or w.settings.donateTroops==false or not w.diplomacyEconomy then return false end
    if d~="Impossible" and not self.random:chance(d=="Hard" and 2 or 4) then return false end
    local allies={};for id,q in ipairs(w.sim.players) do if id~=self.id and q.team==p.team and (#q.incoming>0 or #q.outgoing>0) and w.diplomacyEconomy:canDonate(self.id,id,"troops") then table.insert(allies,{id=id,ratio=q.troops/math.max(1,w:maxTroops(id))}) end end
    table.sort(allies,function(x,y) return x.ratio<y.ratio or x.ratio==y.ratio and x.id<y.id end)
    local amount=p.troops-w:maxTroops(self.id)*self.reserve
    if amount<1 or #allies==0 then return false end
    return w:supportCommand(self.id,allies[1].id,"troops",amount)
end
function M:choose()
    self.landCache={}
    local routes=self.arms and {list={},map={}} or nil
    if self.arms then self.arms.routes=routes end
    local enemies=self:chooseAttack()
    if self.arms then self.arms.routes=nil end
    if routes and #routes.list>0 then
        local front=false;for _,id in ipairs(enemies) do if self:bordersByLand(id) then front=true;break end end
        self.arms:clearBlockedLane(routes,front)
    end
    self.landCache=nil
end
function M:chooseAttack()
    local w,p,r,d=self.world,self.player,self.random,self.difficulty
    local friends,enemies={},{}
    local nearby=w:nearby(self.id);local candidates={}
    for _,id in ipairs(nearby) do if id~=0 then table.insert(candidates,id) end end
    C.sort(candidates,function(id) return w.sim.players[id].troops end)
    for _,id in ipairs(candidates) do table.insert(w:friendly(self.id,id) and friends or enemies,id) end
    if table.find(nearby,0) and self:send(0) then return enemies end
    local hold=false
    if self:incoming() then hold=C.smart(d) or d=="Medium" and r:chance(2) end
    if #enemies==0 then if not hold and r:chance(5) and self.arms then self.arms:randomBoat(enemies) end
    elseif not hold and r:chance(10) then if self.arms then self.arms:randomBoat(enemies) end;return enemies
    else self.diplomacy:requests(enemies) end
    self:attackBestTarget(friends,enemies)
    return enemies
end
function M:attackBestTarget(friends,enemies)
    local w,p,r,d=self.world,self.player,self.random,self.difficulty
    if C.smart(d) and self:retaliate() then return end
    self:annexWalledInBots()
    local botStructures=false
    for _,id in ipairs(self:neighboringBots()) do if C.ownsStructures(w,id) then botStructures=true;break end end
    if (botStructures or self.structures:highGold() and self:hasTrigger(true)) and self:attackBots() then return end
    if p.troops/w:maxTroops(self.id)<self.reserve then return end
    if d=="Medium" and self:retaliate() then return end
    if p.troops/w:maxTroops(self.id)<self.trigger and not r:chance(10) then return end
    local ffa=p.team==nil
    local groups
    local function targetGroups()
        if groups then return groups end
        if not self.arms then groups={enemies};return groups end
        local front=false;for _,id in ipairs(enemies) do if self:bordersByLand(id) then front=true;break end end
        local function byTroops(ids) return C.sort(ids,function(id) return w.sim.players[id].troops end) end
        if d=="Impossible" and front then groups={enemies,byTroops(self.arms:overseas(enemies))}
        elseif C.smart(d) and not front then local all=table.clone(enemies);for _,id in ipairs(self.arms:overseas(enemies)) do table.insert(all,id) end;groups={byTroops(all)}
        else groups={enemies} end
        return groups
    end
    local function pick(find)
        for _,group in ipairs(targetGroups()) do
            local pool=group
            while true do
                local id=find(pool);if not id then break end
                if d=="Easy" or self:canReach(id) then return id end
                local rest={};for _,other in ipairs(pool) do if other~=id then table.insert(rest,other) end end;pool=rest
            end
        end
        return nil
    end
    local function first(predicate) return function(pool) for _,id in ipairs(pool) do if predicate(w.sim.players[id],id) then return id end end;return nil end end
    local strategies={
        bots=function() return self:attackBots() end,
        retaliate=function() return self:retaliate() end,
        betray=function() return self.diplomacy:betray(friends,enemies) end,
        assist=function()
            if not self.arms or w.settings.disableAlliances then return false end
            for _,t in ipairs(w.unitSystem.comms.targets) do if t.owner~=self.id and w:friendly(self.id,t.owner) and w.sim.ticks-t.tick<100 then
                if w:relation(self.id,t.owner)<50 then self.diplomacy:emoji(t.owner,{"🥱","🤦‍♂️"})
                elseif t.target==self.id then self.diplomacy:emoji(t.owner,{"🥺","💀"})
                elseif w:friendly(self.id,t.target) then self.diplomacy:emoji(t.owner,{"🕊️","👎"})
                elseif self:send(t.target) then w:changeRelation(self.id,t.owner,-20);self.diplomacy:emoji(t.owner,{"👍","🤝","🎯"});return true end
            end end;return false
        end,
        nuked=function()
            if not self.arms or U.disabled(w.settings,"MissileSilo") then return false end
            local found=false;p.border:forEach(function(t)if not found then for _,n in ipairs(w.sim:neighbors(t))do if w.sim.fallout[n] and w.sim:owner(n)==0 then found=true;break end end end end)
            return found and self:send(0) or false
        end,
        afk=function() local id=pick(first(function(other,id) return (if w.away then w:away(id) else w.resources[id].forfeited==true) and (not ffa or other.troops<p.troops*3) end));return id and self:send(id) or false end,
        island=function()
            if not self.arms or pick(function(pool) return pool[1] end) then return false end
            local id=self.arms:island();return id and self:send(id) or false
        end,
        donate=function() return self:donate() end,
        hated=function()
            local resource=w.resources[self.id];local order=resource.relationOrder
            if not order then order={};for id=1,#w.sim.players do if (resource.relations or {})[id]~=nil then table.insert(order,id) end end end
            local ids={};for _,id in ipairs(order) do local value=resource.relations[id];if value< -50 and w.sim.players[id].tiles.size>0 then table.insert(ids,id) end end
            C.sort(ids,function(id) return w:relation(self.id,id) end)
            for _,id in ipairs(ids) do if not w:friendly(self.id,id) and (not ffa or w.sim.players[id].troops<=p.troops*3) and (d=="Easy" or self:canReach(id)) then return self:send(id) end end;return false
        end,
        traitor=function() local id=not w.settings.disableAlliances and pick(first(function(other) return other.isTraitor and (not ffa or other.troops<p.troops*1.2) end));return id and self:send(id) or false end,
        veryWeak=function() local id=pick(first(function(other,id) return other.troops<w:maxTroops(id)*.15 and (not ffa or other.troops<p.troops*1.2) end));return id and self:send(id) or false end,
        juicy=function()
            local id=pick(function(pool) local ids={};for _,other in ipairs(pool) do if w.sim.players[other].troops<=p.troops*.75 then table.insert(ids,other) end end;return #ids>0 and C.juicy(w,ids) or nil end)
            return id and self:send(id) or false
        end,
        victim=function() local id=pick(first(function(other) return (not ffa or other.troops<=p.troops*1.2) and C.sum(other.incoming)>other.troops*.5 end));return id and self:send(id) or false end,
        crown=function() local id=C.leader(w,self.id);if not id or not table.find(enemies,id) or not self:bordersByLand(id) then return false end
            if d=="Medium" and C.sum(w.sim.players[id].incoming)<w.sim.players[id].troops*.1 then return false end
            return self:shouldAttack(id) and self:land(id,nil,id)
        end,
        weakest=function() local id=pick(first(function(other) return not ffa or other.troops<p.troops end));return id and self:send(id) or false end,
    }
    local order=({Easy={"nuked","bots","retaliate","assist","betray","hated","weakest"},Medium={"bots","nuked","assist","betray","hated","afk","traitor","crown","weakest","island","donate"},Hard={"bots","assist","betray","nuked","traitor","afk","hated","veryWeak","juicy","victim","crown","weakest","island","donate"},Impossible={"bots","veryWeak","betray","assist","victim","crown","traitor","juicy","afk","nuked","hated","weakest","island","donate"}})[d]
    for _,key in ipairs(order) do if strategies[key]() then return end end
end
function M:embargoes()
    local w,d=self.world,self.difficulty;local resource=w.resources[self.id];resource.embargo=resource.embargo or {}
    local teams=self.player.team~=nil and C.smart(d)
    for id,p in ipairs(w.sim.players) do
        if id==self.id or p.tiles.size==0 then continue end
        local same=C.sameTeam(w,self.id,id)
        if teams and p.kind~="BOT" and not same then resource.embargo[id]=resource.embargo[id] or true;continue end
        local relation=w:relation(self.id,id)
        if relation< -50 and not same then resource.embargo[id]=resource.embargo[id] or true
        elseif relation>=0 and not C.smart(d) or relation>=50 and d~="Impossible" then resource.embargo[id]=nil end
    end
end
function M:embargoRelations()
    local w=self.world
    for id,p in ipairs(w.sim.players) do
        if id==self.id or p.tiles.size==0 then continue end
        local embargo=(w.resources[id].embargo or {})[self.id]
        if type(embargo)=="table" and embargo.temporary then embargo=nil end
        if embargo and not self.embargoMalus[id] then w:changeRelation(self.id,id,-20);self.embargoMalus[id]=true
        elseif not embargo and self.embargoMalus[id] then w:changeRelation(self.id,id,20);self.embargoMalus[id]=nil end
    end
end
function M:tick(tick)
    if not self.active then return end
    if self.player.tiles.size==0 then self.active=false;return end
    if self.warships and self.initialized then self.warships:track() end
    if self.arms then self.arms:followLandings() end
    if not self.initialized then
        self.initialized=true
        self.world.sim:attack(self.id,0,self.player.troops/2);return
    end
    if self.nukes then self.nukes:followUpStrikes() end
    local decisionTick=tick+100
    if decisionTick%self.rate~=self.offset then
        local at=decisionTick%self.rate
        if at==(self.offset+math.floor(self.rate/3))%self.rate or at==(self.offset+math.floor(self.rate*2/3))%self.rate then self.structures:tick() end
        return
    end
    self.diplomacy:casual()
    self:embargoRelations()
    self.diplomacy:respond()
    if self.nukes then self.nukes:mirv() end
    self.structures:tick()
    if self.warships then self.warships:spawn() end
    self:embargoes()
    self:choose()
    if self.warships then self.warships:counter() end
    if self.nukes then self.nukes:send() end
end
return M
