--!native
-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. NationStructureBehavior, pinned e02eeba: build order, perceived
local E=if script then require(script.Parent.EconomyRules) else require("./EconomyRules")
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local C=if script then require(script.Parent.NationCommon) else require("./NationCommon")
local Format=if script then require(script.Parent.TeamFormat) else require("./TeamFormat")
local Routes=if script then require(script.Parent.NationRoutes) else require("./NationRoutes")
local M={};M.__index=M
local SAM_RATIO={Easy=.15,Medium=.2,Hard=.25,Impossible=.3}
local INCREASE={City=1,Port=1,Factory=1,SAMLauncher=.3,MissileSilo=1}
local COOLDOWN={[2]=250,[3]=150,[4]=100}
local CONNECTIVITY={Easy=0,Medium=60,Hard=75,Impossible=100}
local UPGRADE_RANDOM={Easy=70,Medium=40,Hard=25,Impossible=10}
local BORDER,SPACING,STATION_MIN,STATION_MAX,SAM_DEFAULT=30,60,15,110,70
local CITIES_BEFORE_SAVING={Easy=0,Medium=3,Hard=4,Impossible=5}
local INCOME_SAVING_WEIGHT={Easy=1,Medium=.8,Hard=.6,Impossible=.4}
local FACTORY_COASTAL={Easy=.33,Medium=.45,Hard=.55,Impossible=.6}
local SAM_UPGRADE_WHEN_COVERED={Easy=0,Medium=50,Hard=100,Impossible=100}
local MAX_UPGRADES_AT_ONCE={Easy=3,Medium=10,Hard=math.huge,Impossible=math.huge}
local SAM_PROTECTED={City=true,Factory=true,MissileSilo=true,Port=true}
local PACED_STARTING_GOLD_LIMIT=10000000
local POST_RANGE=30
local PROACTIVE_HOSTILE_RATIO={Hard=1,Impossible=.5}
function M.new(ai) return setmetatable({ai=ai,placements=0,last=nil,crowded=false,saveUpStart=nil,mirvMemo=nil,coastal=false},M) end
function M:units(kind)
    local a=self.ai;local out={}
    for _,u in ipairs(a.world.units) do if u.active and (u.owner or 1)==a.id and (not kind or u.kind==kind) then table.insert(out,u) end end;return out
end
function M:economy() return self.ep or self.ai.world:economyPlayer(self.ai.id) end
function M:cost(kind,extra)
    local w=self.ai.world
    return tonumber(B.toString(E.cost(w.settings,self:economy(),kind,extra,w.unitSystem and w.unitSystem.mirvsLaunched)))
end
function M:gold() return tonumber(B.toString(self.ai.world:getGold(self.ai.id))) end
function M:afford(kind) return self:gold()>=self:cost(kind) end
function M:owned(kind) return self:economy().owned[kind] or 0 end
function M:disabled(kind) return U.disabled(self.ai.world.settings,kind) end
function M:canBuild(kind,tile)
    local a=self.ai;local s=a.world.unitSystem
    if s then
        local p=s:preview(a.id,kind,tile)
        if p.upgrade then return s:constructionTile(kind,tile,a.id)~=nil and self:gold()>=tonumber(p.cost) end
        return p.valid
    end
    return a.world:validConstructionTile(tile,a.id)~=nil and self:afford(kind)
end
function M:build(kind,tile)
    local a=self.ai;local s=a.world.unitSystem
    if s and not (U.structures[kind] and s:preview(a.id,kind,tile).upgrade) then return (s:build(a.id,kind,tile)) end
    table.insert(a.world.orders,{kind=kind,tile=tile,owner=a.id});return true
end
function M:nearest(tiles,tile,cap)
    local width=self.ai.world.map.meta.width;local distance=math.huge
    for _,t in ipairs(tiles) do distance=math.min(distance,C.manhattan(width,t,tile)) end
    return math.min(distance,cap or math.huge)
end
function M:sample() local a=self.ai;return C.randTiles(a.world,a.random,a.id,25) end
function M:tick()
    self.ep=self.ai.world:economyPlayer(self.ai.id)
    local built=self:handle();self.ep=nil;return built
end
function M:handle()
    local a=self.ai;local w=a.world
    if self.placements>0 and not self:disabled("DefensePost") then
        local ratio,front=self:front()
        if self:defend(ratio,front) then return true end
        if a.difficulty~="Easy" and ratio>=.35 then return false end
    end
    if self:onCooldown() or self:saveUpBlocked() then return false end
    if self:place() then self.last=w.sim.ticks;self.placements+=1;return true end
    return false
end
function M:onCooldown()
    local w=self.ai.world;local gap=COOLDOWN[self.placements] or 0
    if not self.last or not self:highGold() or (w.settings.startingGold or 0)>=PACED_STARTING_GOLD_LIMIT or gap==0 then return false end
    return w.sim.ticks-self.last<gap
end
function M:highGold() return (self.ai.world.settings.startingGold or 0)>=3000000 end
function M:cityCount()
    if self:disabled("City") then return math.max(1,math.floor(self.ai.player.tiles.size/2000)) end
    return self:owned("City")
end
function M:saveUpTarget()
    local a=self.ai
    if self:disabled("MissileSilo") then return self:cost("SAMLauncher") end
    if C.team(a.world,a.id) then return self:cost("HydrogenBomb") end
    if not self:disabled("MIRV") and self:mirvWorthSaving() then return self:cost("MIRV")+self:cost("HydrogenBomb") end
    if not self:disabled("HydrogenBomb") then return self:cost("HydrogenBomb")*5 end
    if not self:disabled("AtomBomb") then return self:cost("AtomBomb")*20 end
    return self:cost("SAMLauncher")
end
function M:mirvWorthSaving()
    local a=self.ai;local tick=a.world.sim.ticks
    if self.mirvMemo and self.mirvMemo.tick==tick then return self.mirvMemo.worth end
    local worth=C.mirvWorthSavingFor(a.world,a.id)==true
    self.mirvMemo={tick=tick,worth=worth};return worth
end
function M:saveUpBlocked()
    local a=self.ai;if self:disabled("MissileSilo") then return false end
    local target=self:saveUpTarget()
    if not self.saveUpStart then
        if self:gold()<target then return false end
        self.saveUpStart=a.world.sim.ticks
    end
    if self:gold()>=target*2 then return false end
    return (a.world.sim.ticks-self.saveUpStart)%300>=150
end
function M:perceived(kind)
    local a=self.ai;local d=a.difficulty
    local real=self:cost(kind);local target=self:saveUpTarget()
    if target==0 or self:gold()>=target or not C.saveUpWithinReach(a.world,a.id,target) then return real end
    if self:cityCount()<CITIES_BEFORE_SAVING[d] then return real end
    local increase=INCREASE[kind] or .1
    if kind=="City" or kind=="Port" or kind=="Factory" then increase*=INCOME_SAVING_WEIGHT[d] end
    return math.ceil(real*(1+increase*self:owned(kind)))
end
function M:place()
    local a=self.ai;local w,d=a.world,a.difficulty;local s=w.unitSystem
    self.stationCache=nil
    local citiesDisabled=self:disabled("City");local cities=self:cityCount()
    local coastal=s~=nil and #Routes.shores(a.world,a.id).tiles>0;local silos=not self:disabled("MissileSilo")
    self.coastal=coastal
    if s then
        if self.placements==0 and C.smart(d) and not self:disabled("AtomBomb") and silos and not self:disabled("SAMLauncher") and self:highGold() and self:spawn("SAMLauncher") then return true end
        if not citiesDisabled and not self.crowded and (self:crowdedMap() or d~="Easy" and self:teamArea()) then
            local first=coastal and not self:disabled("Port") and "Port" or "Factory"
            if self:disabled(first) then self.crowded=true elseif self:spawn(first) then self.crowded=true;return true end
        end
        if self:proactivePost() then return true end
        local nukes=not self:disabled("AtomBomb") or not self:disabled("HydrogenBomb") or not self:disabled("MIRV")
        for _,kind in ipairs({"Port","Factory","SAMLauncher","MissileSilo"}) do
            if self:disabled(kind) or kind=="Port" and not coastal or not nukes and (kind=="MissileSilo" or kind=="SAMLauncher") or not silos and kind=="SAMLauncher" then continue end
            if self:due(kind,cities,coastal) and self:spawn(kind) then return true end
        end
    end
    return not citiesDisabled and self:spawn("City")
end
function M:crowdedMap()
    local w=self.ai.world;local land=w.map.meta.landTiles;if land<=0 then return false end
    local nations=0;for _,p in ipairs(w.sim.players) do if p.kind=="NATION" then nations+=1 end end
    return nations/land>1/7500
end
function M:teamArea() local a=self.ai;local team=a.player.team;return team~=nil and Format.area(a.world.map.meta,a.world.teamCount,team)~=nil end
function M:due(kind,cities,coastal) return self:levelsDue(kind,cities,coastal)>0 end
function M:levelsDue(kind,cities,coastal)
    local a=self.ai;local d=a.difficulty
    local ratio=({Port=C.team(a.world,a.id) and d~="Easy" and 1 or .75,Factory=.75,SAMLauncher=SAM_RATIO[d],MissileSilo=.2})[kind]
    if not ratio then return 0 end
    if kind=="Factory" and coastal and not self:disabled("Port") then ratio*=FACTORY_COASTAL[d] end
    local owned=self:owned(kind)
    if kind=="MissileSilo" then if owned==0 then ratio=.4 end;return math.min(math.floor(cities*ratio),3)-owned end
    return math.floor(cities*ratio)-owned
end
function M:density()
    local a=self.ai;local n=0;for _,u in ipairs(self:units()) do if U.structures[u.kind] and u.kind~="DefensePost" then n+=1 end end
    return a.player.tiles.size>0 and n/a.player.tiles.size or 0
end
function M:spawn(kind)
    if self:gold()<self:perceived(kind) then return false end
    if kind=="SAMLauncher" and self:samCovered() then return self:upgradeUnit(self:samProtectingMost()) end
    local structures=self:units(kind);local upgradable=U.upgradable[kind]==true
    if self:density()>1/1500 and upgradable then
        if self:upgrade(structures) then return true end
        if #structures>0 then return false end
    end
    local tile=self:spawnTile(kind)
    if not tile then return upgradable and self.ai.difficulty~="Easy" and self:upgrade(structures) end
    return self:build(kind,tile)
end
function M:samCovered()
    local a=self.ai;local w=a.world;local chance=SAM_UPGRADE_WHEN_COVERED[a.difficulty];local sams=self:units("SAMLauncher")
    if chance==0 or #sams==0 then return false end
    for _,u in ipairs(self:units()) do
        if not SAM_PROTECTED[u.kind] then continue end
        local covered=false
        for _,sam in ipairs(sams) do local range=U.samRange(sam.level);if w:distance2(u.tile,sam.tile)<=range*range then covered=true;break end end
        if not covered then return false end
    end
    return chance==100 or a.random:nextInt(0,100)<chance
end
function M:samProtectingMost()
    local w=self.ai.world;local protect={};local best,levels=nil,-1
    for _,u in ipairs(self:units()) do if SAM_PROTECTED[u.kind] then table.insert(protect,u) end end
    for _,sam in ipairs(self:units("SAMLauncher")) do
        if sam.building or sam.deleteAt then continue end
        local range=U.samRange(sam.level);local n=0
        for _,u in ipairs(protect) do if w:distance2(u.tile,sam.tile)<=range*range then n+=u.level end end
        if n>levels then best,levels=sam,n end
    end
    return best
end
function M:upgradeAmount(kind)
    local due=kind=="City" and math.huge or self:levelsDue(kind,self:cityCount(),self.coastal)
    local max=math.min(MAX_UPGRADES_AT_ONCE[self.ai.difficulty],due)
    local spare=self:gold()-self:saveUpTarget();local amount=0
    while amount<max do
        local cost=self:cost(kind,amount);if cost>spare then break end
        spare-=cost;amount+=1
    end
    return math.max(1,amount)
end
function M:upgradeUnit(u)
    if not u then return false end
    local a=self.ai;local w=a.world;local amount=self:upgradeAmount(u.kind)
    if u.kind=="City" or not w.unitSystem then for _=1,amount do table.insert(w.nationUpgrades,{owner=a.id,id=u.id}) end;return true end
    if not w.unitSystem:upgradeOnce(a.id,u.id) then return false end
    for _=2,amount do if not w.unitSystem:upgradeOnce(a.id,u.id) then break end end
    return true
end
function M:upgrade(structures) return self:upgradeUnit(self:best(structures)) end
function M:best(structures)
    local a=self.ai;local w,r=a.world,a.random;local valid={}
    for _,u in ipairs(structures) do if not u.building and not u.deleteAt then table.insert(valid,u) end end
    if #valid==0 then return nil end
    local chosen
    if r:nextInt(0,100)<UPGRADE_RANDOM[a.difficulty] then chosen=r:randElement(valid)
    else
        local sams=self:units("SAMLauncher");local scores={}
        for _,u in ipairs(valid) do
            local score=0
            for _,sam in ipairs(sams) do local range=U.samRange(sam.level);if w:distance2(u.tile,sam.tile)<=range*range then score+=10+(sam.level-1)*7.5 end end
            scores[u]=score+r:nextInt(0,5)
        end
        C.sort(valid,function(u) return -scores[u] end)
        local i=1;if #valid>=2 and r:chance(2) then i=#valid>=3 and r:nextInt(1,3)+1 or 2 end
        chosen=valid[i]
    end
    return chosen
end
function M:spawnTile(kind)
    local tiles=kind=="Port" and self:coastalSample(25) or self:sample()
    if #tiles==0 then return nil end
    local value=self:valueFn(kind);local best,score=nil,0
    for _,t in ipairs(tiles) do
        local v=value(t)
        if v<=score and best~=nil then continue end
        if not self:canBuild(kind,t) then continue end
        best=t;score=v
    end
    return best
end
function M:coastalSample(count)
    local a=self.ai;local tiles=table.clone(Routes.shores(a.world,a.id).tiles)
    if #tiles<=count then return tiles end
    local out={};for _=1,count do table.insert(out,table.remove(tiles,a.random:nextInt(0,#tiles)+1)) end;return out
end
function M:valueFn(kind)
    local a=self.ai;local w,d,r=a.world,a.difficulty,a.random;local border=a.player.border;local width=w.map.meta.width
    local function magnitude(t) return bit32.band(w.sim.terrain[t+1],31) end
    local function edge(t) return math.min(C.ring(w,border,t,BORDER),BORDER) end
    local function tilesOf(k) local out={};for _,u in ipairs(self:units(k)) do table.insert(out,u.tile) end;return out end
    local function near(tiles,t) local best=math.huge;for _,x in ipairs(tiles) do if x~=t then best=math.min(best,C.manhattan(width,x,t)) end end;return best end
    local function capped(value,cap) return value~=math.huge and math.min(value,cap) or 0 end
    if kind=="Port" then local ports=tilesOf("Port");return function(t) return near(ports,t) end end
    if kind=="MissileSilo" then local silos=tilesOf("MissileSilo");return function(t) return magnitude(t)+edge(t)+capped(near(silos,t),SPACING) end end
    if kind=="City" or kind=="Factory" then
        local own,cross=tilesOf(kind),tilesOf(kind=="City" and "Factory" or "City")
        local connected=r:nextInt(0,100)<CONNECTIVITY[d];local stations=connected and w.unitSystem and self:stations() or nil
        return function(t)
            local v=magnitude(t)+edge(t)+capped(near(own,t),kind=="City" and SPACING or STATION_MAX)+capped(near(cross,t),SPACING)
            if stations then v+=self:connectivity(t,stations)*SPACING end
            return v
        end
    end
    local sams=self:units("SAMLauncher");local samTiles=tilesOf("SAMLauncher");local protect={}
    for _,u in ipairs(self:units()) do if u.kind=="City" or u.kind=="Factory" or u.kind=="MissileSilo" or u.kind=="Port" then table.insert(protect,{tile=u.tile,weight=C.smart(d) and u.level or 1}) end end
    local coverage=d~="Easy" and r:nextInt(0,100)<25
    if coverage then for _,e in ipairs(protect) do
        local n=0;for _,sam in ipairs(sams) do local range=U.samRange(sam.level);if w:distance2(e.tile,sam.tile)<=range*range then n+=sam.level end end;e.coverage=n
    end end
    return function(t)
        local v=magnitude(t)+(border.size>0 and edge(t) or 0)+capped(near(samTiles,t),SPACING)
        if d~="Easy" then for _,e in ipairs(protect) do if w:distance2(t,e.tile)<=SAM_DEFAULT*SAM_DEFAULT then v+=SPACING*e.weight/(coverage and 1+e.coverage or 1) end end end
        return v
    end
end
function M:stations()
    if self.stationCache then return self.stationCache end
    local a=self.ai;local w=a.world;local rail=w.unitSystem.rail;local ep=w:economyPlayer(a.id)
    local links={};for _,r in ipairs(rail.rails) do if r.active then links[r.a]=links[r.a] or {};links[r.b]=links[r.b] or {};table.insert(links[r.a],r.b);table.insert(links[r.b],r.a) end end
    local clusters={}
    local function cluster(id)
        if clusters[id] then return clusters[id] end
        local stack={id};clusters[id]=id
        while #stack>0 do for _,n in ipairs(links[table.remove(stack)] or {}) do if not clusters[n] then clusters[n]=id;table.insert(stack,n) end end end
        return id
    end
    local function gold(rel) return tonumber(B.toString(E.trainGold(w.settings,ep,rel,0))) end
    local top=math.max(gold("ally"),1);local out={}
    local function add(id,weight) for _,u in ipairs(w.units) do if u.active and (u.owner or 1)==id and (u.kind=="City" or u.kind=="Port" or u.kind=="Factory") and rail.stations[u.id] then table.insert(out,{tile=u.tile,cluster=cluster(u.id),weight=weight}) end end end
    add(a.id,gold("self")/top)
    for _,id in ipairs(w:nearby(a.id)) do
        if id==0 or w.sim.players[id].kind=="BOT" or not w:canTrade(a.id,id) then continue end
        add(id,gold(C.sameTeam(w,a.id,id) and "team" or C.allied(w,a.id,id) and "ally" or "other")/top)
    end
    self.stationCache=out;return out
end
function M:connectivity(tile,stations)
    local w=self.ai.world;local best,order={},{}
    for _,s in ipairs(stations) do
        local d=w:distance2(tile,s.tile)
        if d>=STATION_MIN*STATION_MIN and d<=STATION_MAX*STATION_MAX then
            if best[s.cluster]==nil then table.insert(order,s.cluster) end;best[s.cluster]=math.max(best[s.cluster] or 0,s.weight)
        end
    end
    local score=0;for _,c in ipairs(order) do score+=best[c] end;return score
end
function M:front()
    local a=self.ai;local sim=a.world.sim;local owners,total={},0
    for _,attack in ipairs(a.player.incoming) do total+=attack.troops;if attack.sourceTile==nil then owners[attack.owner]=true end end
    local ratio=a.player.troops>0 and total/a.player.troops or 0
    local tiles={}
    if ratio>=.35 then
        tiles=self:facing(owners)
        for _,attack in ipairs(a.player.incoming) do
            if attack.sourceTile~=nil and not owners[attack.owner] and attack.border then attack.border:forEach(function(t) if sim:owner(t)==a.id then table.insert(tiles,t) end end) end
        end
    end
    return ratio,tiles
end
function M:facing(owners)
    local a=self.ai;local sim=a.world.sim;local tiles={}
    if next(owners)==nil then return tiles end
    a.player.border:forEach(function(t) for _,n in ipairs(sim:neighbors(t)) do if owners[sim:owner(n)] then table.insert(tiles,t);break end end end)
    return tiles
end
function M:defend(ratio,front)
    local a=self.ai;local r,d=a.random,a.difficulty
    if d=="Easy" or d=="Medium" and not r:chance(2) then return false end
    if ratio<.35 then return false end
    local allowed=d=="Medium" and 1 or math.ceil(ratio/.4)
    local scaled=d=="Medium" and 0 or math.min(ratio,2)
    local minDist=POST_RANGE*(2/3+1/3*scaled);local maxDist=minDist+POST_RANGE*(1/2)
    if self:postsNear(front,maxDist,allowed)>=allowed then return false end
    return self:buildBehind(front,minDist,maxDist)
end
function M:proactivePost()
    local a=self.ai;local w=a.world;local share=PROACTIVE_HOSTILE_RATIO[a.difficulty]
    if not share or self:disabled("DefensePost") then return false end
    local cities=self:cityCount();if cities<2 then return false end
    if #self:units("DefensePost")>=cities*.5 or not self:afford("DefensePost") then return false end
    local minTroops=a.player.troops*share;local threats,count={},0
    for _,id in ipairs(w:nearby(a.id)) do
        local p=w.sim.players[id]
        if id==0 or not p or p.kind=="BOT" or threats[id] or w:friendly(a.id,id) then continue end
        if w:relation(a.id,id)< -50 and p.troops>=minTroops then threats[id]=true;count+=1 end
    end
    if count==0 then return false end
    local front=self:facing(threats)
    if self:postsNear(front,POST_RANGE*1.5,count)>=count then return false end
    return self:buildBehind(front,POST_RANGE*(1/2),POST_RANGE)
end
function M:postsNear(front,range,cap)
    if #front==0 then return 0 end
    local w=self.ai.world;local sq=range*range;local count=0
    for _,u in ipairs(self:units("DefensePost")) do
        for _,t in ipairs(front) do if w:distance2(u.tile,t)<=sq then count+=1;if cap and count>=cap then return count end;break end end
    end
    return count
end
function M:buildBehind(front,minDist,maxDist)
    if not self:afford("DefensePost") then return false end
    local tile=self:postTile(front,minDist,maxDist);if not tile then return false end
    return self:build("DefensePost",tile)
end
function M:postTile(front,minDist,maxDist)
    if #front==0 then return nil end
    local a=self.ai;local w,r=a.world,a.random;local width,height=w.map.meta.width,w.map.meta.height
    local existing={};for _,u in ipairs(self:units("DefensePost")) do table.insert(existing,u.tile) end
    local spread=(POST_RANGE*1.5)^2
    local function nearPost(t) for _,p in ipairs(existing) do if w:distance2(t,p)<spread then return true end end;return false end
    local anchors={};for _,t in ipairs(front) do if not nearPost(t) then table.insert(anchors,t) end end
    if #anchors==0 then return nil end
    local minSq,maxSq=minDist*minDist,maxDist*maxDist;local radius=math.ceil(maxDist)
    for _=1,150 do
        local anchor=r:randElement(anchors);local ax,ay=anchor%width,anchor//width
        local x=r:nextInt(ax-radius,ax+radius+1);local y=r:nextInt(ay-radius,ay+radius+1)
        if x<0 or y<0 or x>=width or y>=height then continue end
        local t=y*width+x;if w.sim:owner(t)~=a.id or nearPost(t) then continue end
        local nearest=math.huge
        for _,f in ipairs(front) do
            local dx,dy=x-f%width,y-f//width;local d=dx*dx+dy*dy
            if d<nearest then nearest=d;if d<minSq then break end end
        end
        if nearest<minSq or nearest>maxSq then continue end
        if self:canBuild("DefensePost",t) then return t end
    end
    return nil
end
return M
