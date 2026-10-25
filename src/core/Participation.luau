local Rules=if script then require(script.Parent.OutgameRules)else require('./OutgameRules')
local Recap=if script then require(script.Parent.OperationRecap)else require('./OperationRecap')
local B=if script then require(script.Parent.BigNat)else require('./BigNat')
local M={};M.__index=M
function M.new(id,mode,map,humans,now)
    return setmetatable({id=id,mode=mode,map=map,humans=humans,seconds=0,peak=0,cities=0,supports=0,tactics={nukes=0,transports=0,upgrades=0,built={}},days={},weeks={},weeklyActions={},milestones={},units={},revision=0,lastAction=-1e9,created=now,dirty=false,recap=Recap.new()},M)
end
function M:command(action,value,now)
    self.recap:command(action,value)
    if table.find({'spawn','attack','build','nuclear','upgrade','delete','transport','moveWarship','moveWarships','retaliate','cancelTransport','alliance','support','cancelAttack','embargoAll'},action)then self.lastAction=now;self.lastKind=action end
    if action=='spawn'then self.spawnedAt=now end
    if action=='nuclear'then self.tactics.nukes+=1;if value=='MIRV'then self.tactics.mirv=(self.tactics.mirv or 0)+1 end;self.dirty=true
    elseif action=='transport'then self.tactics.transports+=1;self.dirty=true
    elseif action=='upgrade'then self.tactics.upgrades+=1;self.dirty=true
    elseif action=='support'and value=='embargoStart'or action=='embargoAll'and value==true then self.tactics.embargoes=(self.tactics.embargoes or 0)+1;self.dirty=true end
    if action=='attack'then self.triedExpansion=true end
    if action=='cancelAttack'then self.milestones.front=true;self.dirty=true end
    if action=='support'and (value=='gold'or value=='troops')then
        self.supports+=1;local week=Rules.week(now);self.weeklyActions[week]=self.weeklyActions[week]or {cities=0,supports=0};self.weeklyActions[week].supports+=1;self.dirty=true
    end
end
function M:addTime(seconds,now)
    local start=now-seconds
    while start<now do
        local nextTime=math.min(now,(math.floor(start/86400)+1)*86400)
        local duration=nextTime-start;local day=Rules.day(start);local week=Rules.week(start)
        self.days[day]=self.days[day]or {seconds=0,cities=0,finished=0};self.days[day].seconds+=duration
        self.weeks[week]=(self.weeks[week]or 0)+duration;start=nextTime
    end
    self.seconds+=seconds;self.dirty=true
end
function M:step(s,id,dt,now,connected,paused)
    local p=s.sim.players[id];if not p then return end
    for _,key in ipairs({'troopsProduced','countriesConquered','troopsSent'})do
        local value=p[key]or 0
        if value~=(self.tactics[key]or 0)then self.tactics[key]=value;self.dirty=true end
    end
    local r=s.resources[id]
    if r then
        local gold=r.goldEarned and tonumber(B.toString(r.goldEarned))or 0
        for key,value in pairs({gold=gold,alliances=r.alliancesMade or 0,intercepts=r.intercepts or 0,trainGold=r.trainGold or 0,allyTrainGold=r.allyTrainGold or 0,tradeGold=r.tradeGold or 0,tradeCaptures=r.tradeCaptures or 0,betrayals=r.betrayals or 0})do
            if value~=(self.tactics[key]or 0)then self.tactics[key]=value;self.dirty=true end
        end
    end
    local alive=p.tiles.size>0 and not s.resources[id].forfeited
    if (s.sim.ticks>=(self.placeAt or 0))or(not alive and self.wasAlive and not self.knockedOut)then
        self.placeAt=s.sim.ticks+5
        local standing,better=0,0
        for _,q in ipairs(s.sim.players)do if q.kind~='BOT'and q.tiles.size>0 then standing+=1;if q~=p and q.tiles.size>p.tiles.size then better+=1 end end end
        self.total=math.max(self.total or 0,standing+(alive and 0 or 1))
        if alive then self.wasAlive=true;self.place=better+1
        elseif self.wasAlive and not self.knockedOut then self.knockedOut=true;self.place=standing+1 end
    end
    self.currentShare=p.tiles.size/math.max(1,s:landTiles());self.peak=math.max(self.peak,self.currentShare)
    if s.phase=='playing'and (alive or self.spawnedAt)and not self.ended then
        self.recap:sample(s.sim.ticks,self.currentShare)
        if #(p.incoming or {})>0 then self.recap:record('underAttack')end
    end
    if s.phase=='playing'and alive then
        if not self.spawnedAt then self.spawnedAt=now;self.initialTiles=p.tiles.size end
        self.initialTiles=self.initialTiles or p.tiles.size
        local since=now-self.spawnedAt
        if since<=180 then self.tactics.earlyShare=math.max(self.tactics.earlyShare or 0,self.currentShare)end
        if since>=60 then self.tactics.minShare=math.min(self.tactics.minShare or 1,self.currentShare)end
        if not paused and dt>0 and s.maxTroops then local cap=s:maxTroops(id);local ratio=p.troops/math.max(1,cap)
            self.growthSeconds=(self.growthSeconds or 0)+dt;if ratio>=.25 and ratio<=.65 then self.greenSeconds=(self.greenSeconds or 0)+dt end
            local pct=math.floor(100*(self.greenSeconds or 0)/math.max(1,self.growthSeconds));if pct~=self.tactics.growthGreen then self.tactics.growthGreen=pct;self.dirty=true end end
        if self.triedExpansion and p.tiles.size>self.initialTiles+12 then self.milestones.expand=true end
        if not self.milestones.front and (#(p.incoming or {})>0 or self.incoming)then
            local incoming=nil;for _,a in ipairs(p.incoming or {})do incoming=incoming or {};incoming[a]=true end
            for a in pairs(self.incoming or {})do if not(incoming and incoming[a])then self.milestones.front=true;self.dirty=true;break end end
            self.incoming=not self.milestones.front and incoming or nil
        end
        local running=false;local units={};local fleet=0
        for _,u in ipairs(s.units)do if u.owner==id then
            local old=self.units[u.id];units[u.id]={building=u.building,kind=u.kind}
            if u.kind=='Warship'and u.active~=false then fleet+=1;if not old and self.lastTick then self.tactics.warships=(self.tactics.warships or 0)+1;self.dirty=true end end
            if u.building then running=true end
            if not u.building and ((old and old.building)or not old and (u.assemblyStartedTick or -1)>= (self.lastTick or s.sim.ticks)) then
                self.tactics.built[u.kind]=(self.tactics.built[u.kind]or 0)+1
                if u.kind=='City'then
                    self.cities+=1;self.milestones.city=true;self.recap:record('city');local day=Rules.day(now)
                    self.days[day]=self.days[day]or {seconds=0,cities=0,finished=0};self.days[day].cities+=1;self.dirty=true
                    local week=Rules.week(now);self.weeklyActions[week]=self.weeklyActions[week]or {cities=0,supports=0};self.weeklyActions[week].cities+=1
                elseif u.kind=='DefensePost'then self.milestones.front=true;self.dirty=true end
            end
        end end;self.units=units
        if fleet>(self.tactics.fleetPeak or 0)then self.tactics.fleetPeak=fleet;self.dirty=true end
        for _,a in ipairs(p.outgoing or {})do if not a.retreating and not a.retreated then running=true;break end end
        if not running then for _,u in ipairs(s.units)do if u.active and u.owner==id and (u.kind=='TransportShip'or u.kind=='Warship'and u.targetTile or u.kind=='AtomBomb'or u.kind=='HydrogenBomb'or u.kind=='MIRV'or u.kind=='MIRVWarhead')then running=true;break end end end
        if not self.ended and connected and not paused and (now-self.spawnedAt<=180 or now-self.lastAction<=180 or running)then self:addTime(math.max(0,dt),now)end
    end
    self.lastTick=s.sim.ticks
end
function M:finish(outcome,now,final)
    if self.outcome=='won'or self.final then return end
    if self.ended and outcome~='won'then if final then self.final=true;self.dirty=true end;return end
    self.recap:sample(self.lastTick or 0,self.currentShare or 0,true);self.recap:record(outcome)
    self.outcome=outcome;self.final=final==true;self.ended=true;self.time=now;self.dirty=true
    if outcome=='won'then self.place=1 end
    if (outcome=='won'or outcome=='lost')and self.seconds>=120 and not self.milestones.finish then
        self.milestones.finish=true;local day=Rules.day(now);self.days[day]=self.days[day]or {seconds=0,cities=0,finished=0};self.days[day].finished+=1
    end
end
function M:event(now)
    self.revision+=1;self.dirty=false
    return {id=self.id,revision=self.revision,mode=self.mode,map=self.map,humans=self.humans,seconds=math.floor(self.seconds),peak=self.peak,cities=self.cities,supports=self.supports,party=self.party==true,tactics=Rules.copy(self.tactics),days=Rules.copy(self.days),weeks=Rules.copy(self.weeks),weeklyActions=Rules.copy(self.weeklyActions),milestones=Rules.copy(self.milestones),outcome=self.outcome,final=self.final,basicsComplete=self.basicsComplete==true,daily=self.daily,campaign=self.campaign,official=self.official==true or nil,gameSeconds=self.gameSeconds,time=self.time or now,
        place=self.place,field=self.total,ranked=self.ranked==true or nil}
end
return M
