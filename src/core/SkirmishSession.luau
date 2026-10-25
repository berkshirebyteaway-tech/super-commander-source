--!native
local Base=if script then require(script.Parent.SettlementSession) else require("./SettlementSession")
local AI=if script then require(script.Parent.TribeAI) else require("./TribeAI")
local Nation=if script then require(script.Parent.NationAI) else require("./NationAI")
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local Spawn=if script then require(script.Parent.SpawnRules) else require("./SpawnRules")
local E=if script then require(script.Parent.EconomyRules) else require("./EconomyRules")
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local DiplomacyEconomy=if script then require(script.Parent.DiplomacyEconomy) else require("./DiplomacyEconomy")
local Win=if script then require(script.Parent.WinRules) else require("./WinRules")
local UnitSystem=if script then require(script.Parent.UnitSystem) else require("./UnitSystem")
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local Presentation=if script then require(script.Parent.CombatPresentation) else require("./CombatPresentation")
local TerritoryLabels=if script then require(script.Parent.TerritoryLabels)else require("./TerritoryLabels")
local Identity=if script then require(script.Parent.ToyIdentity) else require("./ToyIdentity")
local Policy=if script then require(script.Parent.CountryPolicy) else require("./CountryPolicy")
local Format=if script then require(script.Parent.TeamFormat) else require("./TeamFormat")
local NationNames=if script then require(script.Parent.NationNames) else require("./NationNames")
local ClusterRules=if script then require(script.Parent.ClusterRules) else require("./ClusterRules")
local M={};M.__index=M;setmetatable(M,{__index=Base})
local function pair(a,b) return math.min(a,b)..":"..math.max(a,b) end
function M.teamMatchWinner(self,tick)
    if tick%10~=0 then return nil end
    local totals,order={},{}
    for _,p in ipairs(self.sim.players) do if p.team and p.tiles.size>0 then if not totals[p.team] then totals[p.team]=0;table.insert(order,p.team) end;totals[p.team]+=p.tiles.size end end
    local leader;for _,team in ipairs(order) do if not leader or totals[team]>totals[leader] then leader=team end end
    if not leader then return nil end
    local won,reason=Win.hasWon(self.settings,tick/10,totals[leader],self:landTiles(),self.falloutTiles or 0)
    if not won then return nil end
    self.winnerTeam=leader
    if self.sim.players[1].team==leader then return 1,reason end
    for id,p in ipairs(self.sim.players) do if p.team==leader and p.tiles.size>0 then return id,reason end end
    return nil
end
function M.new(map,settings,name,mode)
    local self=setmetatable(Base.new(map,settings,name),M)
    self.resources={[1]={gold=self.gold,constructed=self.constructed,name=name,kind="HUMAN",lastDelete=-1}}
    self.bots={};self.nations={};self.nationUpgrades={};self.neighborCache={};self.alliances={};self.requests={};self.requestHistory={};self.diplomacyOrders={};self.labelCache={}
    self.sim.players[1].name=name
    self.humans=settings.humans
    if self.humans then
        for id,entry in ipairs(self.humans) do
            local p=id==1 and self.sim.players[1] or self.sim:addPlayer("HUMAN",E.startTroops(settings,{kind="HUMAN",host=false}))
            p.name=entry.name;p.userId=entry.userId;p.team=entry.team
            if id>1 then self.resources[id]={gold=E.startGold(settings,{kind="HUMAN"}),constructed={},name=entry.name,kind="HUMAN",lastDelete=-1} else self.resources[id].name=entry.name end
        end
    end
    self.diplomacyEconomy=DiplomacyEconomy.new(self)
    self.unitSystem=UnitSystem.new(self);self.clusterRules=ClusterRules.new(self)
    self.sim.onFalloutCleared=function() self.falloutTiles=math.max(0,(self.falloutTiles or 0)-1) end
    self.sim.falloutRatio=function() return (self.falloutTiles or 0)/math.max(1,self:landTiles()) end
    local nationData=map.meta.nations or {}
    if settings.countryPolicy then nationData=Policy.filter(map.meta.key,nationData) end
    local nationRandom=R.new(AI.hash(settings.seed or "frontier"))
    nationRandom:nextID()
    local count=settings.nations=="default" and #nationData or 0
    if type(settings.nations)=="number" then
        count=math.clamp(math.floor(settings.nations),0,400)
        nationData=nationRandom:shuffleArray(nationData)
        if count>#nationData then
            local used,list={},table.clone(nationData)
            for _,n in ipairs(list)do used[n.name]=true end
            local extras={}
            for _,n in ipairs(map.meta.additionalNations or {})do if not used[n.name]then table.insert(extras,n)end end
            if settings.countryPolicy then extras=Policy.filter(map.meta.key,extras)end
            for _,n in ipairs(nationRandom:shuffleArray(extras))do
                if #list>=count then break end
                table.insert(list,n);used[n.name]=true
            end
            while #list<count do local name=NationNames.unique(nationRandom,used);used[name]=true;table.insert(list,{name=name})end
            nationData=list
        end
    end
    local plan=Format.plan(settings,self.humans,count,mode)
    self.teamCount=plan and plan.teamCount
    if plan and not self.humans then self.sim.players[1].team=plan.human;self.checkMatchWinner=M.teamMatchWinner end
    for i=1,count do
        local entry=nationData[i];local key=nationRandom:nextID()
        local p=self.sim:addPlayer("NATION",E.startTroops(settings,{kind="NATION"}));p.name=entry.name;p.team=plan and plan.nations[i]
        self.resources[p.id]={gold=E.startGold(settings,{kind="NATION"}),constructed={},name=p.name,kind="NATION",lastDelete=-1,relations={},flag=Policy.flag(entry)}
        local ai=Nation.new(self,p.id,key);local tile=entry.x and ai:spawnCell(entry)
        local area=Format.area(map.meta,self.teamCount,p.team);local tiles
        if not entry.x or (tile and area and not Format.inside(area,tile,map.meta.width)) then tile,tiles=Spawn.random(self,key,settings.seed or "frontier",area) end
        if tile then
            p.spawnTile=tile;for _,t in ipairs(tiles or Spawn.tiles(self,tile,false)) do self.sim:conquer(p.id,t) end
            self.nations[p.id]=ai
            ai.spawnEntry=entry.x and not tiles and entry or nil;ai.spawnKey=key;ai.spawnArea=area
        end
    end
    local custom=map.meta.customTribes or {};local tribeRandom=R.new(AI.hash(settings.seed or "frontier")+2);local usedTribes={}
    local placed={};for _,t in ipairs(custom)do if t.x and #placed<(settings.bots or 0)then table.insert(placed,t)end end
    local function tribeName(i)
        local free={};for _,t in ipairs(custom)do if not t.x and not usedTribes[t.name]then table.insert(free,t)end end
        if #free==0 then return Identity.name(i,settings.seed)end
        local t=free[tribeRandom:nextInt(0,#free)+1];usedTribes[t.name]=true;return t.name
    end
    for i=1,settings.bots or 0 do
        local key="tribe-"..i;local fixed=placed[i];local cell=fixed and fixed.y*map.meta.width+fixed.x
        if cell and (fixed.x>=map.meta.width or fixed.y>=map.meta.height or not T.isLand(self.sim.terrain[cell+1])or T.isImpassable(self.sim.terrain[cell+1])or self.sim:owner(cell)~=0)then cell=nil end
        local p=self.sim:addPlayer("BOT",E.startTroops(settings,{kind="BOT"}));p.name=fixed and fixed.name or tribeName(i)
        self.resources[p.id]={gold={0},constructed={},name=p.name,kind="BOT",lastDelete=-1}
        local tile,tiles
        if cell then tile,tiles=cell,Spawn.tiles(self,cell,false)else tile,tiles=Spawn.random(self,key,settings.seed or "frontier")end
        if tile then
            p.spawnTile=tile
            for _,t in ipairs(tiles) do self.sim:conquer(p.id,t) end
            self.bots[p.id]=AI.new(self,p.id,key)
        end
    end
    self:recordOwnership();self.sim.captured={}
    self.sim.isFriendly=function(a,b) return self:friendly(a,b) end
    self.sim.isAwayTeammate=function(a,b) local p,q=self.sim.players[a],self.sim.players[b];return q~=nil and p.team~=nil and p.team==q.team and self:away(b) end
    self.sim.canAttack=function(a,b) return self.sim.players[a].tiles.size>0 and (b==0 or (self.sim.players[b].tiles.size>0 and not self:friendly(a,b) and not self:protectedTarget(a,b))) end
    self.sim.onAttackLaunched=function(a,b)
        if b==0 then return end
        local difficulty=self.settings.difficulty or "Medium"
        if difficulty~="Easy" and self:relation(a,b)< -50 then return end
        self:changeRelation(b,a,({Easy=-60,Medium=-70,Hard=-80,Impossible=-100})[difficulty])
    end
    self.sim.onAttackInitialized=function(a,b)
        local r=self.requests[pair(a,b)]
        if r and r.a==b and r.b==a then self:resolveRequest(a,b,false,nil,"rejected") end
        if b~=0 and self.sim.players[a].kind~="BOT" and self.sim.players[b].kind~="BOT" then self.diplomacyEconomy:embargo(b,a,true,true,self.sim.ticks) end
    end
    self.sim.hasDefensePost=function(owner,tile)
        local c=self.defenseReadCache;local list=self.units
        if not c or c.tick~=self.sim.ticks or c.list~=list or c.n~=#list then
            c={tick=self.sim.ticks,list=list,n=#list,posts={}}
            for _,u in ipairs(list)do if u.kind=='DefensePost'then table.insert(c.posts,u)end end
            self.defenseReadCache=c
        end
        for _,u in ipairs(c.posts) do
            if u.active and not u.building and u.kind=="DefensePost" and (u.owner or 1)==owner and self:distance2(u.tile,tile)<=900 then return true end
        end
        return false
    end
    self.sim.conquerPlayer=function(a,b)
        self.fallenTo=self.fallenTo or {};self.fallenTo[b]=a
        local resources=self.resources[b]
        local p,q=self.sim.players[a],self.sim.players[b]
        if self:away(b) and p.team and p.team==q.team then
            for _,u in ipairs(self.units) do if u.active and u.owner==b and (u.kind=="Warship" or u.kind=="TransportShip") then u.owner=a end end
        end
        if resources.kind~="HUMAN" or resources.attacked then
            local amount=E.conquerGold({kind=resources.kind,gold=resources.gold})
            self:setGold(a,B.add(self:getGold(a),amount));self:setGold(b,{0})
            if self.unitSystem and B.compare(amount,{0})>0 then self.unitSystem:effect("conquest",nil,a,{target=b,gold=B.toString(amount)}) end
        end
    end
    return self
end
function M:getGold(id) return id==1 and self.gold or self.resources[id].gold end
function M:setGold(id,gold)
    local r=self.resources[id];local old=r.gold
    if old and B.compare(gold,old)>0 then r.goldEarned=B.add(r.goldEarned or {0},B.subtract(gold,old)) end
    r.gold=gold;if id==1 then self.gold=gold end
end
function M:relation(a,b) return (self.resources[a].relations or {})[b] or 0 end
function M.attitude(value) return value< -50 and 0 or value<0 and 1 or value<50 and 2 or 3 end
function M:canTrade(a,b) return self.diplomacyEconomy:canTrade(a,b) end
function M:supportCommand(a,b,kind,amount) return self.diplomacyEconomy:queue(a,b,kind,amount) end
function M:changeRelation(a,b,amount)
    local r=self.resources[a];r.relations=r.relations or {};r.relationOrder=r.relationOrder or {}
    if r.relations[b]==nil then table.insert(r.relationOrder,b) end
    local before=r.relations[b] or 0
    r.relations[b]=math.clamp(before+amount,-100,100)
    if M.attitude(before)>0 and M.attitude(r.relations[b])==0 and r.kind=="NATION" and self.sim.players[b] and self.sim.players[b].kind=="HUMAN" and self.sim.players[a].tiles.size>0 then
        local tile=self:borderWith(a,b)
        if tile then self:notify(b,string.format("%s 적대",r.name),"rejected",tile) end
    end
end
function M:allianceWarmth(a,b)
    self:changeRelation(a,b,100);self:changeRelation(b,a,100)
    self.diplomacyEconomy:endTemporary(a,b);self.diplomacyEconomy:endTemporary(b,a)
end
function M:orderedRequests(id)
    local result={};for _,r in pairs(self.requests) do if r.b==id then table.insert(result,r) end end
    table.sort(result,function(a,b) return a.created<b.created or a.created==b.created and (a.sequence or a.a)<(b.sequence or b.a) end);return result
end
function M:orderedAlliances(id)
    local result={};for _,r in pairs(self.alliances) do if r.a==id or r.b==id then table.insert(result,r) end end
    table.sort(result,function(a,b) return a.created<b.created or a.created==b.created and (a.sequence or a.a*1000+a.b)<(b.sequence or b.a*1000+b.b) end);return result
end
function M:canRequest(a,b)
    if self:away(a) or self:away(b) then return false end
    if self:friendly(a,b) or self.sim.players[b].tiles.size==0 then return false end
    local r=self.requests[pair(a,b)];local previous=self.requestHistory[a..":"..b]
    return (not r or r.b==a) and (r~=nil or not previous or self.sim.ticks-previous>=300)
end
function M:aiEmoji(a,b,text)
    self.resources[a].emoji={target=b,text=text,tick=self.sim.ticks}
    if self.unitSystem and self.nations[a] then self.unitSystem.comms:emit("emoji",a,b,text) end
end
function M:economyPlayer(id,snapshotUnits)
    id=id or 1;local p=self.sim.players[id];local r=self.resources and self.resources[id]
    if not r then return Base.economyPlayer(self) end
    local levels,owned=0,{}
    for _,u in ipairs(snapshotUnits or self.units) do
        if u.active and (u.owner or 1)==id then
            owned[u.kind]=(owned[u.kind] or 0)+(u.building and 1 or u.level)
            if u.kind=="City" and not u.building then levels+=u.level end
        end
    end
    return {kind=p.kind,host=id==1,tiles=p.tiles.size,troops=p.troops,cityLevels=levels,owned=owned,constructed=r.constructed}
end
function M:maxTroops(id) return E.maxTroops(self.settings,self:economyPlayer(id)) end
function M:hasStructures(id)
    for _,u in ipairs(self.units) do if u.active and (u.owner or 1)==id then return true end end;return false
end
function M:away(id)
    local r=self.resources[id];return r~=nil and (r.forfeited==true or r.disconnected~=nil)
end
function M:friendly(a,b,includeAway)
    local p,q=self.sim.players[a],self.sim.players[b]
    if a~=b and not includeAway and self:away(b) then return false end
    return a==b or p~=nil and q~=nil and p.team~=nil and p.team==q.team or self.alliances[pair(a,b)]~=nil
end
function M:protectedTarget(a,b)
    local p,q=self.sim.players[a],self.sim.players[b]
    if p==nil or p.kind~="HUMAN" or q==nil or q.kind=="BOT" then return false end
    return self.sim.ticks<(q.kind=="HUMAN" and (self.settings.spawnImmunityDuration or 50) or 50)
end
function M:borderWith(id,target)
    local found
    self.sim.players[id].border:forEach(function(t)
        if found then return end
        for _,n in ipairs(self.sim:neighbors(t)) do if self.sim:owner(n)==target then found=t;return end end
    end)
    return found
end
function M:sharesLandBorder(id,target)
    local found=false
    self.sim.players[id].border:forEach(function(t)
        if found then return end
        for _,n in ipairs(self.sim:neighbors(t)) do
            local byte=self.sim.terrain[n+1]
            if self.sim:owner(n)==target and T.isLand(byte) and not T.isImpassable(byte) then found=true;return end
        end
    end)
    return found
end
function M:nearby(id)
    local key,rev=self.sim.ownerChanges,self.unitSystem and self.unitSystem.terrainRevision or 0
    local cache=self.nearbyCache
    if not cache or cache.key~=key or cache.rev~=rev then cache={key=key,rev=rev,lists={}};self.nearbyCache=cache end
    local hit=cache.lists[id];if hit then return table.clone(hit) end
    local out=self:scanNearby(id);cache.lists[id]=out;return table.clone(out)
end
function M:scanNearby(id)
    local out,seen={},{};local w,h=self.map.meta.width,self.map.meta.height
    local sim=self.sim;local owners,tb,terrain=sim.owners,sim.tb,sim.terrain
    local function visit(t)
        local byte=if tb then buffer.readu8(tb,t) else terrain[t+1];local owner=owners[t+1]
        if owner~=id and not seen[owner] and T.isLand(byte) and not T.isImpassable(byte) then seen[owner]=true;table.insert(out,owner) end
    end
    local p=sim.players[id];local last=(h-1)*w
    p.border:forEach(function(t)
        local x=t%w
        if t>=w then visit(t-w) end
        if t<last then visit(t+w) end
        if x~=0 then visit(t-1) end
        if x~=w-1 then visit(t+1) end
    end)
    local shoreIndex=0
    p.border:forEach(function(t)
        if bit32.band(self.sim.terrain[t+1],64)==0 then return end
        local index=shoreIndex;shoreIndex+=1;if index%10~=0 then return end
        local x,y=t%w,math.floor(t/w)
        for _,d in ipairs({{0,-1},{0,1},{-1,0},{1,0}}) do
            local nx,ny=x+d[1],y+d[2]
            if nx<0 or nx>=w or ny<0 or ny>=h or T.isLand(self.sim.terrain[ny*w+nx+1]) then continue end
            nx=x+d[1]*5;ny=y+d[2]*5
            if nx>=0 and nx<w and ny>=0 and ny<h then visit(ny*w+nx) end
        end
    end)
    return out
end
function M:sendBotTransport(id,target,reserve,expand)
    local Arms=if script then require(script.Parent.NationArms) else require("./NationArms")
    local ai=self.bots[id];if not ai then return false end
    if not ai.arms then ai.player=self.sim.players[id];ai.difficulty="Easy";ai.arms=Arms.new(ai) end
    return ai.arms:boat(target)
end
function M:relocate(id,pick)
    local p=self.sim.players[id];local previous={}
    p.tiles:forEach(function(t) table.insert(previous,t) end)
    for _,t in ipairs(previous) do self.sim:relinquish(t) end
    local tile,tiles=pick()
    if not tile or not tiles or #tiles==0 then
        for _,t in ipairs(previous) do self.sim:conquer(id,t) end
        self:recordOwnership();self.sim.captured={};return false
    end
    for _,t in ipairs(tiles) do self.sim:conquer(id,t) end
    p.spawnTile=tile;self:recordOwnership();self.sim.captured={}
    return true
end
function M:spawnStep()
    if self.phase~="spawn" then return end
    self.spawnTicks=(self.spawnTicks or 0)+1;local tick=self.spawnTicks
    local ids={};for id in pairs(self.nations) do table.insert(ids,id) end;table.sort(ids)
    for _,id in ipairs(ids) do
        local ai=self.nations[id]
        if ai.spawnKey and self.sim.players[id].tiles.size>0 and tick%ai.rate==ai.offset then
            self:relocate(id,function()
                if ai.spawnEntry then local t=ai:spawnCell(ai.spawnEntry);return t,t and Spawn.tiles(self,t,false) end
                return Spawn.random(self,ai.spawnKey,self.settings.seed or "frontier",ai.spawnArea)
            end)
        end
    end
end
function M:spawn(tile)
    if self.phase~="spawn" then return false,"이미 시작" end
    if type(tile)~="number" or tile%1~=0 or tile<0 or tile>=self.map.meta.width*self.map.meta.height then return false,"육지 선택" end
    local tiles=Spawn.tiles(self,tile,false)
    if #tiles==0 then return false,"빈 육지 선택" end
    for _,t in ipairs(tiles) do self.sim:conquer(1,t) end
    self:recordOwnership();self.sim.captured={};self.sim.players[1].spawnTile=tile;self.spawnTile=tile;self.phase="playing"
    self:event("정착");return true,"정착"
end
function M:attack(id,target,fraction,tile)
    if self.phase~="playing" or not self.sim.players[id] or not self.sim.players[target] and target~=0 or target==id then return false,"대상 선택" end
    if self:friendly(id,target) then return false,"동맹 상대" end
    if self:protectedTarget(id,target) then return false,"상대 보호 시간" end
    local p=self.sim.players[id];local amount=p.troops*fraction
    local function sent(ok,...)if ok then p.troopsSent=(p.troopsSent or 0)+amount end;return ok,...end
    if not self:sharesLandBorder(id,target) then
        if tile then return sent(self.unitSystem.naval:transport(id,tile,amount)) end
        return false,"해안 선택"
    end
    if target==0 and tile then
        local seen,stack={}, {tile};seen[tile]=true;local adjacent=false
        while #stack>0 and not adjacent do local at=table.remove(stack)
            for _,n in ipairs(self.sim:neighbors(at)) do
                if self.sim:owner(n)==id then adjacent=true;break end
                if not seen[n] and self.sim:owner(n)==0 and self.unitSystem.nav:land(n) and self.unitSystem.nav:manhattan(tile,n)<=200 then seen[n]=true;table.insert(stack,n) end
            end
        end
        if not adjacent then return sent(self.unitSystem.naval:transport(id,tile,amount)) end
    end
    self.sim:attack(id,target,amount);self.resources[id].attacked=true;p.troopsSent=(p.troopsSent or 0)+amount
    return true,(target==0 and "중립 땅으로 확장" or self.resources[target].name.." 공격").." "..math.floor(fraction*100).."%"
end
function M:breakAlliance(a,b)
    local key=pair(a,b);if not self.alliances[key] then return end
    self.alliances[key]=nil
    local traitor=not self.sim.players[b].isTraitor and not self:away(b)
    if traitor then self.sim.players[a].traitorUntil=self.sim.ticks+300;self.sim.players[a].isTraitor=true;local r=self.resources[a];if r then r.betrayals=(r.betrayals or 0)+1 end end
    self:changeRelation(b,a,-100)
    local team=self.sim.players[b].team
    for _,n in ipairs(self:nearby(a)) do
        if n~=0 and n~=a and not (n~=b and team~=nil and self.sim.players[n].team==team) then self:changeRelation(n,a,-40) end
    end
    self:notify(a,string.format(traitor and "%s 동맹 파기  30초 방어 약화" or "%s 동맹 파기",self.resources[b].name),"diplomacy")
    if traitor then self:notify(b,string.format("%s 배신  30초 방어 약화",self.resources[a].name),"rejected") end
end
function M:retaliate(id,fraction)
    local p=self.sim.players[id];local last
    for _,a in ipairs(p and p.incoming or {})do local q=self.sim.players[a.owner];if a.active~=false and q and q.kind~="BOT" then last=a end end
    if not last then return false,"반격할 공격 없음" end
    local troops=math.min(last.troops or 0,fraction*p.troops);if troops<1 then return false,"병력 부족" end
    return self:attack(id,last.owner,troops/p.troops,nil)
end
function M:allianceCommand(a,b,kind)
    if self.phase~="playing" or self.settings.disableAlliances or self.settings.customAllianceDuration==0 then return false,"외교 불가" end
    if not self.resources[b] or a==b or self.sim.players[a].tiles.size==0 or self.sim.players[b].tiles.size==0 then return false,"대상 선택" end
    local key=pair(a,b);local alliance=self.alliances[key]
    local request=self.requests[key]
    if kind=="break" then
        if not alliance then return false,"동맹 아님" end
    elseif kind=="extend" then
        if alliance and alliance.agreed[a] then return false,"연장 요청 ✓" end
        if not alliance or alliance.expires-self.sim.ticks>300 then return false,"만료 30초 전부터" end
        if self:away(a) or self:away(b) then return false,"접속 끊긴 상대" end
    elseif kind=="accept" or kind=="reject" then
        if not request or request.a~=b or request.b~=a or self.sim.ticks-request.created>200 then return false,"만료된 요청" end
    elseif kind=="request" then
        if alliance then return false,"이미 동맹" end
        local history=self.requestHistory[a..":"..b]
        if request and request.a==a or not request and history and self.sim.ticks-history<300 then return false,"요청 재사용 대기" end
    else return false,"외교 명령이 올바르지 않아요." end
    for _,order in ipairs(self.diplomacyOrders) do if order.a==a and order.b==b then return false,"처리 중" end end
    table.insert(self.diplomacyOrders,{a=a,b=b,kind=kind});return true,"외교 명령을 보냈어요."
end
function M:resolveRequest(recipient,sender,accepted,tick,reason)
    local key=pair(recipient,sender);local r=self.requests[key]
    if not r or r.a~=sender or r.b~=recipient then return false end
    self.requests[key]=nil;self.requestHistory[r.a..":"..r.b]=r.created
    local now=tick or self.sim.ticks
    if accepted then
        self.diplomacySequence=(self.diplomacySequence or 0)+1
        self.alliances[key]={a=r.a,b=r.b,sequence=self.diplomacySequence,created=now,expires=now+(self.settings.customAllianceDuration or 5)*600,agreed={}}
        for _,id in ipairs({r.a,r.b})do local res=self.resources[id];if res then res.alliancesMade=(res.alliancesMade or 0)+1 end end
        if self.unitSystem then self.unitSystem.nuclear:cancelBetween(sender,recipient) end
    end
    local senderName,recipientName=self.resources[sender].name,self.resources[recipient].name
    if accepted then self:notify(sender,string.format("%s 측과 동맹을 맺었어요.",recipientName),"diplomacy");self:notify(recipient,string.format("%s 측과 동맹을 맺었어요.",senderName),"diplomacy")
    elseif reason=="rejected" then
        self:notify(sender,string.format("%s 동맹 거절",recipientName),"rejected");self:notify(recipient,string.format("%s 요청 거절",senderName),"diplomacy")
    else self:notify(sender,recipientName.." 응답 없음","diplomacy");self:notify(recipient,senderName.." 동맹 요청 만료","diplomacy") end
    return true
end
function M:acceptBotAlliances(id)
    for key,r in pairs(self.requests) do
        if r.b==id then
            self:resolveRequest(id,r.a,true)
        end
    end
    for _,a in pairs(self.alliances) do
        if (a.a==id or a.b==id) and a.agreed[a.a]~=a.agreed[a.b] then table.insert(self.diplomacyOrders,{a=id,b=a.a==id and a.b or a.a,kind="extend"}) end
    end
end
function M:deleteBotStructure(id)
    local resource=self.resources[id]
    if self.sim.ticks-resource.lastDelete<300 then return end
    for _,u in ipairs(self.units) do
        if u.active and U.structures[u.kind] and (u.owner or 1)==id and not u.deleteAt then
            resource.lastDelete=self.sim.ticks;u.deleteAt=self.sim.ticks+300;return
        end
    end
end
function M:produce()
    if self.phase~="playing" then return end
    for _,u in ipairs(self.units) do
        local owner=self.sim:owner(u.tile)
        if u.active and U.structures[u.kind] and owner~=(u.owner or 1) then
            if owner==0 or u.kind=="DefensePost" then u.active=false else u.owner=owner;u.deleteAt=nil end
        end
    end
    for _,r in pairs(self.requests) do
        if self.sim.ticks-r.created>200 or self.sim.players[r.a].tiles.size==0 or self.sim.players[r.b].tiles.size==0 then self:resolveRequest(r.b,r.a,false) end
    end
    for key,a in pairs(self.alliances) do
        if a.expires<=self.sim.ticks or self.sim.players[a.a].tiles.size==0 or self.sim.players[a.b].tiles.size==0 then self.alliances[key]=nil end
    end
    for order=1,#self.sim.players do
        local id=order==#self.sim.players and 1 or order+1;local p=self.sim.players[id]
        p.isTraitor=p.traitorUntil~=nil and p.traitorUntil>self.sim.ticks
        if p.tiles.size>0 then
            local before=p.troops
            local economy=self:economyPlayer(id)
            self.sim:addTroops(id,E.troopIncrease(self.settings,economy))
            p.troopsProduced=(p.troopsProduced or 0)+math.max(0,p.troops-before)
            economy.troops=p.troops
            self:setGold(id,B.add(self:getGold(id),B.fromNumber(E.goldRate(self.settings,economy))))
            self.diplomacyEconomy:expireTemporary(id,self.sim.ticks)
            self.clusterRules:tick(id)
        elseif not self.resources[id].dead and p.lastTileChange~=nil then
            self.resources[id].dead=true;self:setGold(id,{0})
            for _,u in ipairs(self.units) do if u.active and (u.owner or 1)==id and not U.nukes[u.kind] then u.active=false end end
        end
        for other,value in pairs(self.resources[id].relations or {}) do
            value-=math.sign(value)*.05;if math.abs(value)<.1 then value=0 end;self.resources[id].relations[other]=value
        end
        if self.bots[id] then self.bots[id]:tick(self.sim.ticks) end
        if self.nations[id] then self.nations[id]:tick(self.sim.ticks) end
    end
end
function M:upgrade(id,amount)
    for _,u in ipairs(self.units) do if u.id==id and (u.owner or 1)~=1 then return false,"내 도시 선택" end end
    return Base.upgrade(self,id,amount)
end
function M:step()
    if self.phase~="playing" then return end
    Base.step(self)
    for _,order in ipairs(self.nationUpgrades) do
        for _,u in ipairs(self.units) do
            if u.id==order.id and u.active and not u.building and (u.owner or 1)==order.owner and u.kind=="City" then
                local cost=E.cost(self.settings,self:economyPlayer(order.owner),"City")
                if B.compare(self:getGold(order.owner),cost)>=0 then
                    self:setGold(order.owner,B.subtract(self:getGold(order.owner),cost));u.level+=1
                    local r=self.resources[order.owner];r.constructed.City=(r.constructed.City or 0)+1
                end
                break
            end
        end
    end
    self.nationUpgrades={}
    for _,o in ipairs(self.diplomacyOrders) do
        local key=pair(o.a,o.b);local a=self.alliances[key]
        if o.kind=="break" then self:breakAlliance(o.a,o.b)
        elseif o.kind=="request" and not a then
            local r=self.requests[key]
            if r and r.a==o.b and r.b==o.a then if self:resolveRequest(o.a,o.b,true,self.sim.ticks-1) then self:allianceWarmth(o.a,o.b) end
            elseif not r then self.diplomacySequence=(self.diplomacySequence or 0)+1;self.requests[key]={a=o.a,b=o.b,sequence=self.diplomacySequence,created=self.sim.ticks-1} end
        elseif o.kind=="accept" or o.kind=="reject" then
            if self:resolveRequest(o.a,o.b,o.kind=="accept",self.sim.ticks-1,o.kind=="reject" and "rejected" or nil) and o.kind=="accept" then self:allianceWarmth(o.a,o.b) end
        elseif o.kind=="extend" and a and not self:away(o.a) and not self:away(o.b) then
            a.agreed[o.a]=true
            if a.agreed[a.a] and a.agreed[a.b] then a.expires=self.sim.ticks-1+(self.settings.customAllianceDuration or 5)*600;a.agreed={};self:notify(a.a,"동맹 연장 ✓","diplomacy");self:notify(a.b,"동맹 연장 ✓","diplomacy") end
        end
    end
    self.diplomacyOrders={}
    self.diplomacyEconomy:step(self.sim.ticks-1)
    if not self.humans and self.sim.players[1].tiles.size==0 then self.phase="lost";self.winner=false end
end
function M:state(full)
    local state=Base.state(self,full);state.factions={};state.rulesProfile="nation-land-integration"
    self.unitSystem:snapshot(state);state.rulesProfile="native-combined-arms"
    local labelRevision,stableLabels=TerritoryLabels.environmentRevision(self)
    TerritoryLabels.limit(self.labelCache,TerritoryLabels.snapshotTiles)
    state.winnerId=self.winnerId;state.winnerName=self.winnerId and self.resources[self.winnerId].name or nil
    state.winReason=self.winReason;state.winThreshold=Win.threshold(self.settings,math.max(0,self.sim.ticks-1)/10)
    state.operations={}
    state.battlefronts=Presentation.snapshot(self.sim,1,function(id)return id end)
    local function operation(a,direction)
        local front=Presentation.front(self.sim,a,0)
        return {id=a.id,direction=direction,kind="land",owner=a.owner,target=a.target,troops=a.troops,frontTile=front,frontTiles=Presentation.positions(self.sim,a),retreating=a.retreating==true,retreated=a.retreated==true}
    end
    for _,a in ipairs(self.sim.players[1].outgoing) do table.insert(state.operations,operation(a,"outgoing")) end
    for _,a in ipairs(self.sim.players[1].incoming) do table.insert(state.operations,operation(a,"incoming")) end
    for _,u in ipairs(self.units) do if u.active and u.kind=="TransportShip" and (u.owner==1 or u.target==1) then table.insert(state.operations,{id=u.id,direction=u.owner==1 and "outgoing" or "incoming",kind="transport",owner=u.owner,target=u.target,troops=u.troops,frontTile=u.tile,retreating=u.retreating==true}) end end
    for id,p in ipairs(self.sim.players) do
        if p.tiles.size==0 and id~=1 then continue end
        local r=self.resources[id];local ep=self:economyPlayer(id);local label=TerritoryLabels.get(self.labelCache,self.sim,p,r.name,labelRevision,stableLabels)
        local a=self.alliances[pair(1,id)]
        local request=self.requests[pair(1,id)]
        local f={id=id,name=r.name,kind=p.kind,troops=p.troops,gold=B.toString(self:getGold(id)),cap=E.maxTroops(self.settings,ep),tiles=p.tiles.size,share=p.tiles.size/math.max(1,self:landTiles()),labelTile=label.tile,labelSize=label.size,labelWidth=label.width,labelHeight=label.height,labelArea=label.clusterTiles,allied=a~=nil,allianceExpires=a and a.expires or nil,requested=request~=nil and request.a==1,incomingRequest=request~=nil and request.b==1,traitor=p.isTraitor or false,flag=r.flag}
        f.traitorUntil=p.isTraitor and p.traitorUntil or nil;f.attitude=p.kind=="NATION" and id~=1 and self:relation(id,1) or nil
        if id==1 then state.player.labelTile=label.tile;state.player.labelSize=label.size;state.player.labelArea=label.clusterTiles end
        f.eliminated=r.forfeited==true;f.disconnected=r.disconnected~=nil or nil
        f.matchId=id
        f.donationAvailableIn=self.diplomacyEconomy:remaining(1,id)/10
        f.canDonateGold=self.diplomacyEconomy:canDonate(1,id,"gold")
        f.canDonateTroops=self.diplomacyEconomy:canDonate(1,id,"troops")
        f.embargoed=self.diplomacyEconomy:hasEmbargo(1,id);f.embargoedBy=self.diplomacyEconomy:hasEmbargo(id,1)
        f.doomed=p.doomed==true;f.doomedAt=p.doomedAt;f.rotted=p.rotted==true
        f.team=p.team;f.teammate=id~=1 and p.team~=nil and p.team==self.sim.players[1].team
        if full~=false then f.owned={};p.tiles:forEach(function(t) table.insert(f.owned,t) end) end
        table.insert(state.factions,f)
    end
    if state.player then state.player.team=self.sim.players[1].team end
    state.commanderCount=0
    for _,p in ipairs(self.sim.players)do if p.kind~='BOT'then state.commanderCount+=1 end end
    state.aliveBots=0;state.aliveNations=0
    for _,f in ipairs(state.factions) do if f.kind=="BOT" then state.aliveBots+=1 elseif f.kind=="NATION" then state.aliveNations+=1 end end
    state.diplomacy={incoming={},outgoing={}}
    state.diplomacy.donations=table.clone(self.diplomacyEconomy.events)
    state.diplomacy.defaultGold=B.toString(B.divideSmall(self.gold,3))
    state.diplomacy.defaultTroops=math.floor(self.sim.players[1].troops/3)
    for _,r in pairs(self.requests) do
        if r.a==1 or r.b==1 then
            local other=r.a==1 and r.b or r.a
            local record={from=r.a,to=r.b,name=self.resources[other].name,created=r.created,expires=r.created+200}
            table.insert(r.b==1 and state.diplomacy.incoming or state.diplomacy.outgoing,record)
        end
    end
    local function before(a,b) return a.created<b.created or a.created==b.created and a.from<b.from end
    table.sort(state.diplomacy.incoming,before);table.sort(state.diplomacy.outgoing,before)
    return state
end
return M
