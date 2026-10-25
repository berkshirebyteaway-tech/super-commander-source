local S=if script then require(script.Parent.SkirmishSession) else require("./SkirmishSession")
local E=if script then require(script.Parent.EconomyRules) else require("./EconomyRules")
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local Spawn=if script then require(script.Parent.SpawnRules) else require("./SpawnRules")
local Win=if script then require(script.Parent.WinRules) else require("./WinRules")
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local Presentation=if script then require(script.Parent.CombatPresentation) else require("./CombatPresentation")
local Nation=if script then require(script.Parent.NationAI) else require("./NationAI")
local Format=if script then require(script.Parent.TeamFormat) else require("./TeamFormat")
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local M={};M.__index=M;setmetatable(M,{__index=S})
local function pair(a,b)return math.min(a,b)..":"..math.max(a,b)end
function M.viewId(id,viewer) if id==viewer then return 1 elseif id==1 then return viewer else return id end end
function M.new(map,settings,roster,mode)
    assert(#roster>=1 and #roster<=20,"Invalid roster")
    local cfg=table.clone(settings);cfg.humans=roster
    local self=setmetatable(S.new(map,cfg,roster[1].name,mode),M)
    self.mode=mode;self.roster=roster;self.spawned={};self.eliminated={}
    self.playerEvents={}
    return self
end
function M:spawnHuman(id,tile)
    if self.phase~="spawn" or not self.roster[id] then return false,"시작 위치 확정됨" end
    if type(tile)~="number" or tile%1~=0 or tile<0 or tile>=self.map.meta.width*self.map.meta.height then return false,"육지 선택" end
    local moved=self.spawned[id]~=nil
    if moved and self.spawned[id]==tile then return false,"이미 이 자리" end
    local byte,owner=self.sim.terrain[tile+1],self.sim:owner(tile)
    if not T.isLand(byte) or T.isImpassable(byte) or owner~=0 and owner~=id then return false,"빈 육지 선택" end
    if not self:relocate(id,function() return tile,Spawn.tiles(self,tile,false) end) then return false,"빈 육지 선택" end
    self.spawned[id]=tile
    return true,moved and "자리 옮김" or "정착 완료"
end
function M:joinCandidate()
    if self.phase=="spawn" then local first;for id in pairs(self.nations)do if not first or id<first then first=id end end;return first end
    if self.phase~="playing" then return nil end
    local players=self.sim.players
    local function bigger(a,b)local x,y=players[a].tiles.size,players[b].tiles.size;return x>y or x==y and a<b end
    local ranked={};for id,p in ipairs(players)do if p.tiles.size>0 then table.insert(ranked,id)end end
    table.sort(ranked,bigger)
    local top={};for i=1,math.min(3,#ranked)do top[ranked[i]]=true end
    local list={};for id in pairs(self.nations)do if players[id].tiles.size>0 then table.insert(list,id)end end
    if #list==0 then return nil end
    table.sort(list,bigger)
    local median=players[list[math.ceil(#list/2)]].tiles.size
    local best,gap
    for _,id in ipairs(list)do
        local size=players[id].tiles.size
        if not top[id]and size>=median*.25 then local d=math.abs(size-median);if not best or d<gap then best,gap=id,d end end
    end
    return best or list[#list]
end
function M:takeOver(entry,id)
    id=id or self:joinCandidate();local ai=id and self.nations[id]
    if not ai or self.roster[id]then return nil end
    local p,r=self.sim.players[id],self.resources[id];local country=r.name
    self.parked=self.parked or {};self.parked[id]=ai;self.nations[id]=nil
    p.kind="HUMAN";p.name=entry.name;p.userId=entry.userId;r.kind="HUMAN";r.name=entry.name;r.country=country
    self.roster[id]=entry;self.spawned[id]=p.spawnTile or 0;self.eliminated[id]=nil;self.playerEvents[id]=nil;r.disconnected=nil
    local text=string.format("%s, %s 지휘",entry.name,tostring(country))
    for other,q in ipairs(self.sim.players) do if q.kind=="HUMAN" and other~=id then self:notify(other,text,"diplomacy") end end
    return id
end
function M:handBack(id)
    local p,r=self.sim.players[id],self.resources[id]
    if not p or not self.roster[id]then return false end
    local name=r.country or r.name
    self.roster[id]=nil;r.disconnected=nil
    if p.tiles.size==0 or self.phase~="playing" and self.phase~="spawn" then return true end
    local ai=self.parked and self.parked[id]or Nation.new(self,id,"handback-"..id.."-"..self.sim.ticks)
    if self.parked then self.parked[id]=nil end
    p.kind="NATION";p.userId=nil;p.name=name;r.kind="NATION";r.name=name;r.relations=r.relations or {}
    self.nations[id]=ai
    return true
end
function M:allyFriends(ids)
    for i=1,#ids do for j=i+1,#ids do
        local a,b=math.min(ids[i],ids[j]),math.max(ids[i],ids[j]);local key=pair(a,b)
        if a~=b and not self.alliances[key]then
            self.requests[key]=nil;self.diplomacySequence=(self.diplomacySequence or 0)+1
            local now=self.sim.ticks;self.alliances[key]={a=a,b=b,sequence=self.diplomacySequence,created=now,expires=now+(self.settings.customAllianceDuration or 5)*600,agreed={}}
            if self.unitSystem then self.unitSystem.nuclear:cancelBetween(a,b)end
        end
    end end
end
function M:startBattle()
    local ids={};for id in pairs(self.roster) do table.insert(ids,id) end;table.sort(ids)
    for _,id in ipairs(ids) do
        if not self.spawned[id] then local tile=Spawn.random(self,"human-"..id,self.settings.seed or "match",Format.area(self.map.meta,self.teamCount,self.sim.players[id].team));if tile then self:spawnHuman(id,tile) end end
    end
    self.phase="playing"
end
function M:checkMatchWinner(tick)
    if tick%10~=0 then return nil end
    if self.mode=="duel" or self.settings.rankedType=="1v1" or self.settings.rankedType=="ffa" then
        local living={};for id in pairs(self.roster) do if self.sim.players[id].tiles.size>0 and not self:away(id) then table.insert(living,id) end end
        if #living==1 then return living[1],"lastCommander" end
    end
    if self.settings.rankedType=="2v2" or self.settings.rankedType=="clanwars" then
        local alive,team,count={},nil,0
        for id in pairs(self.roster) do local p=self.sim.players[id]
            if p.team and p.tiles.size>0 and not self:away(id) and not alive[p.team] then alive[p.team]=true;count+=1;team=p.team end
        end
        if count==1 then self.winnerTeam=team;for id,p in ipairs(self.sim.players)do if p.team==team and p.tiles.size>0 and self.roster[id] then return id,"lastTeam" end end end
    end
    if self.mode=="teams" or self.mode=="coop" then
        local totals,order={},{}
        for _,p in ipairs(self.sim.players) do if p.team and p.tiles.size>0 then if not totals[p.team] then totals[p.team]=0;table.insert(order,p.team)end;totals[p.team]+=p.tiles.size end end
        local leader;for _,team in ipairs(order)do if not leader or totals[team]>totals[leader] then leader=team end end
        if leader then
            local won,reason=Win.hasWon(self.settings,tick/10,totals[leader],self:landTiles(),self.falloutTiles or 0)
            if won then self.winnerTeam=leader;for id,p in ipairs(self.sim.players)do if p.team==leader and p.tiles.size>0 then return id,reason end end end
        end
        return nil
    end
    return Win.ffa(self.settings,tick,self.sim.players,self:landTiles(),self.falloutTiles or 0)
end
function M:buildFor(id,kind,tile)
    if self.unitSystem then return self.unitSystem:build(id,kind,tile) end
    local p=self:previewFor(id,kind,tile);if not p.valid then return false,p.reason end
    table.insert(self.orders,{owner=id,kind=kind,tile=tile});return true,"건설 명령을 보냈어요."
end
function M:previewFor(id,kind,tile)
    if self.unitSystem then return self.unitSystem:preview(id,kind,tile) end
    if not self.roster[id] or self.phase~="playing" or self.sim.players[id].tiles.size==0 then return {valid=false,reason="내 땅 선택"} end
    if kind~="City" and kind~="DefensePost" then return {valid=false,reason="준비 중인 건물"} end
    if type(tile)~="number" or tile%1~=0 or tile<0 or tile>=self.map.meta.width*self.map.meta.height then return {valid=false,reason="육지 선택"} end
    local cost=E.cost(self.settings,self:economyPlayer(id),kind);local at=self:validConstructionTile(tile,id)
    local valid=at~=nil and B.compare(self:getGold(id),cost)>=0
    return {valid=valid,tile=at,cost=B.toString(cost),duration=E.duration(self.settings,kind)/10,reason=valid and "건설 가능" or "건설 불가"}
end
function M:upgradeFor(id,unitId,amount)
    if self.unitSystem then return self.unitSystem:upgrade(id,unitId,amount) end
    if self.phase~="playing" then return false,"경기 중에만" end
    for _,u in ipairs(self.units)do if u.id==unitId and u.owner==id and u.active and not u.building and not u.deleteAt and u.kind=="City" then
        local cost=E.cost(self.settings,self:economyPlayer(id),"City")
        if B.compare(self:getGold(id),cost)<0 then return false,"골드 부족" end
        self:setGold(id,B.subtract(self:getGold(id),cost));u.level+=1;local r=self.resources[id];r.constructed.City=(r.constructed.City or 0)+1
        return true,"도시 업그레이드"
    end end
    return false,"완공한 도시 선택"
end
function M:deleteFor(id,unitId)
    local r=self.resources[id]
    if self.phase~="playing" or self.sim.ticks-r.lastDelete<300 then return false,"철거 재사용 대기" end
    for _,u in ipairs(self.units)do if u.id==unitId and U.structures[u.kind] and u.owner==id and u.active and not u.deleteAt and self.sim:owner(u.tile)==id then
        r.lastDelete=self.sim.ticks;u.deleteAt=self.sim.ticks+300;return true,"30초 뒤 철거해요."
    end end
    return false,"내 건물 선택"
end
function M:forfeit(id)
    if not self.roster[id] then return end
    self.resources[id].forfeited=true;self.eliminated[id]=self.sim.ticks
end
function M:markDisconnected(id,on)
    local r=self.resources[id];if not self.roster[id] or not r or r.forfeited then return false end
    if (r.disconnected~=nil)==(on==true) then return false end
    r.disconnected=on and self.sim.ticks or nil
    local name=r.name
    for other in pairs(self.roster) do
        local p,q=self.sim.players[other],self.sim.players[id]
        if other~=id and (self.alliances[math.min(id,other)..":"..math.max(id,other)]~=nil or p.team~=nil and p.team==q.team) then
            self:notify(other,string.format(on and "%s 접속 끊김  공격 가능" or "%s 재접속",name),"diplomacy")
        end
    end
    return true
end
function M:stateFor(viewer,full,shared,context)
    local s=shared and table.clone(shared)or S.state(self,full)
    if shared then
        s.factions={};for _,f in ipairs(shared.factions)do table.insert(s.factions,table.clone(f))end
        if context then s.units=shared.units else s.units={};for _,u in ipairs(shared.units)do table.insert(s.units,table.clone(u))end end
        s.costs=table.clone(shared.costs);s.naval=table.clone(shared.naval)
    end
    local p=self.sim.players[viewer];local ep=self:economyPlayer(viewer,context and context:unitsFor(viewer))
    local swap=function(id)return M.viewId(id,viewer)end
    local own
    for _,f in ipairs(s.factions)do
        local id=f.id;local a=self.alliances[pair(viewer,id)];local request=self.requests[pair(viewer,id)]
        f.teammate=id~=viewer and p.team~=nil and p.team==self.sim.players[id].team
        if f.kind=="NATION" then f.attitude=self:relation(id,viewer) end
        f.allied=self:friendly(viewer,id) and id~=viewer;f.allianceExpires=a and a.expires or nil
        f.requested=request~=nil and request.a==viewer;f.incomingRequest=request~=nil and request.b==viewer
        f.userId=self.sim.players[id].userId;f.team=self.sim.players[id].team;f.matchId=id;f.id=swap(id)
        f.donationAvailableIn=self.diplomacyEconomy:remaining(viewer,id)/10
        f.canDonateGold=self.diplomacyEconomy:canDonate(viewer,id,"gold");f.canDonateTroops=self.diplomacyEconomy:canDonate(viewer,id,"troops")
        f.embargoed=self.diplomacyEconomy:hasEmbargo(viewer,id);f.embargoedBy=self.diplomacyEconomy:hasEmbargo(id,viewer)
        if id==viewer then own=f end
    end
    own=own or {id=1,name=self.resources[viewer].name,tiles=0,share=0,cap=self:maxTroops(viewer),troops=p.troops,gold=B.toString(self:getGold(viewer)),owned=full~=false and {} or nil}
    s.player=table.clone(own);s.player.cityLevels=ep.cityLevels;s.player.income=E.goldRate(self.settings,ep)*10
    local recruitment=E.troopIncrease(self.settings,ep);s.player.growth=math.floor(recruitment)*10;s.player.growthTrendRate=recruitment*10
    s.owned=own.owned;s.operations={};s.events=table.clone(self.playerEvents[viewer] or {})
    for _,kind in ipairs(U.buildable)do s.costs[kind]=B.toString(self.unitSystem:cost(viewer,kind,ep))end
    s.deleteAvailableIn=math.max(0,300-(self.sim.ticks-self.resources[viewer].lastDelete))/10
    if context then s.units=context:units(s.units,swap)else for _,u in ipairs(s.units)do u.owner=swap(u.owner or 1);if u.target then u.target=swap(u.target) end end end
    s.unitEffects={};for _,effect in ipairs(self.unitSystem.effects) do local e=table.clone(effect);e.owner=swap(e.owner);if e.target then e.target=swap(e.target) end;table.insert(s.unitEffects,e) end
    s.naval.transports=self.unitSystem:count(viewer,"TransportShip")
    s.comms=self.unitSystem.comms:forPlayer(viewer,swap)
    if s.captured then local c={};for _,v in ipairs(s.captured)do table.insert(c,{v[1],swap(v[2])})end;s.captured=c end
    s.battlefronts=context and context:battlefronts(viewer,swap)or Presentation.snapshot(self.sim,viewer,swap)
    for _,direction in ipairs({"outgoing","incoming"})do for _,a in ipairs(p[direction])do table.insert(s.operations,{id=a.id,direction=direction,kind="land",owner=swap(a.owner),target=swap(a.target),troops=a.troops,frontTile=if context then context:front(self.sim,a,0)else Presentation.front(self.sim,a,0),frontTiles=Presentation.positions(self.sim,a),retreating=a.retreating==true,retreated=a.retreated==true})end end
    for _,u in ipairs(context and context:transports(viewer)or self.units) do if u.active and u.kind=="TransportShip" and (u.owner==viewer or u.target==viewer) then table.insert(s.operations,{id=u.id,direction=u.owner==viewer and "outgoing" or "incoming",kind="transport",owner=swap(u.owner),target=swap(u.target),troops=u.troops,frontTile=u.tile,retreating=u.retreating==true}) end end
    s.diplomacy={incoming={},outgoing={},donations={},defaultGold=B.toString(B.divideSmall(self:getGold(viewer),3)),defaultTroops=math.floor(p.troops/3)}
    for _,r in pairs(self.requests)do if r.a==viewer or r.b==viewer then table.insert(r.b==viewer and s.diplomacy.incoming or s.diplomacy.outgoing,{from=swap(r.a),to=swap(r.b),name=self.resources[r.a==viewer and r.b or r.a].name,created=r.created,expires=r.created+200})end end
    s.multiplayer=true;s.spawned=self.spawned[viewer]~=nil;s.matchEnded=self.winnerId~=nil
    s.eliminated=self.phase~="spawn" and (p.tiles.size==0 or self.resources[viewer].forfeited==true)
    if self.winnerId then local won=self.winnerTeam and p.team==self.winnerTeam or self.winnerId==viewer;s.phase=won and "won" or "lost";s.winnerId=swap(self.winnerId)
    elseif s.eliminated then s.phase="lost" else s.phase=self.phase end
    return s
end
function M:observerState(watch,full,shared,context)
    local s=self:stateFor(watch,full,shared,context)
    s.events={};s.operations={}
    s.diplomacy={incoming={},outgoing={},donations={}}
    s.comms={events={},targets={}}
    s.observer={watch=watch,ended=self.winnerId~=nil or nil}
    s.phase="lost";s.eliminated=true;s.spawned=true
    return s
end
return M
