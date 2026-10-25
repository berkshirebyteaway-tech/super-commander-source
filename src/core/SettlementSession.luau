--!native
local Sim=if script then require(script.Parent.CombatSimulation) else require("./CombatSimulation")
local E=if script then require(script.Parent.EconomyRules) else require("./EconomyRules")
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local Win=if script then require(script.Parent.WinRules) else require("./WinRules")
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local M={};M.__index=M
function M.new(map,settings,name)
    local self=setmetatable({map=map,settings=settings,name=name,phase="spawn",units={},nextUnit=0,orders={},construction={},gold={0},constructed={},winner=false,events={},eventId=0,ownershipRevision=0,ownershipChanges={},baseRevision=0,lastDeleteUnitTick=-1},M)
    local troops=E.startTroops(settings,{kind="HUMAN",host=true})
    self.sim=Sim.new({width=map.meta.width,height=map.meta.height,terrain=map.terrain,owners={},troops={troops},types={"HUMAN"}})
    self.gold=E.startGold(settings,{kind="HUMAN",host=true})
    self.sim.beforeTick=function() self:produce() end
    self.sim.hasDefensePost=function(owner,tile)
        if owner~=1 then return false end
        for _,u in ipairs(self.units) do if u.active and not u.building and u.kind=="DefensePost" and self:distance2(u.tile,tile)<=900 then return true end end
        return false
    end
    return self
end
function M:event(message,kind,tile)
    self.eventId+=1;table.insert(self.events,{id=self.eventId,tick=self.sim.ticks,message=message,kind=kind or "info",tile=tile})
    if #self.events>12 then table.remove(self.events,1) end
end
function M:notify(owner,message,kind,tile)
    if self.playerEvents then
        if not owner or owner<1 then return end
        self.eventId+=1;local list=self.playerEvents[owner];if not list then list={};self.playerEvents[owner]=list end
        table.insert(list,{id=self.eventId,tick=self.sim.ticks,message=message,kind=kind or "info",tile=tile})
        if #list>12 then table.remove(list,1) end
    elseif owner==1 then self:event(message,kind,tile) end
end
function M.amount(n)
    n=tonumber(n) or 0
    if n>=1e9 then return string.format("%.2fB",n/1e9) end
    if n>=1e6 then return string.format("%.2fM",n/1e6) end
    if n>=10000 then return string.format("%.1fK",n/1000) end
    if n>=1000 then return string.format("%.2fK",n/1000) end
    return tostring(math.floor(n))
end
function M:recordOwnership()
    if #self.sim.captured==0 then return end
    self.ownershipRevision+=1
    for _,c in ipairs(self.sim.captured) do table.insert(self.ownershipChanges,c) end
end
function M:ackOwnership()
    self.baseRevision=self.ownershipRevision;self.ownershipChanges={}
end
function M:distance2(a,b)
    local w=self.map.meta.width;local dx,dy=a%w-b%w,math.floor(a/w)-math.floor(b/w);return dx*dx+dy*dy
end
function M:landTiles() return math.max(0,self.map.meta.landTiles-(self.convertedLandTiles or 0)) end
function M:flood(center,predicate)
    local seen,stack,out={},{},{}
    local function visit(t) if not seen[t] and predicate(t) then seen[t]=true;table.insert(out,t);table.insert(stack,t) end end
    visit(center)
    local w,h=self.sim.width,self.sim.height
    while #stack>0 do
        local t=table.remove(stack);local x=t%w
        if t>=w then visit(t-w)end;if t<(h-1)*w then visit(t+w)end
        if x~=0 then visit(t-1)end;if x~=w-1 then visit(t+1)end
    end
    return out
end
function M:spawn(tile)
    if self.phase~="spawn" then return false,"이미 시작" end
    if type(tile)~="number" or tile%1~=0 or tile<0 or tile>=self.map.meta.width*self.map.meta.height then return false,"지도 선택" end
    local w=self.map.meta.width;local cx,cy=tile%w-.5,math.floor(tile/w)-.5
    local tiles=self:flood(tile,function(t) local dx,dy=t%w-cx,math.floor(t/w)-cy;return dx*dx+dy*dy<=16 end)
    local valid={};for _,t in ipairs(tiles) do local b=self.sim.terrain[t+1];if T.isLand(b) and not T.isImpassable(b) then table.insert(valid,t) end end
    if #valid==0 then return false,"육지 선택" end
    for _,t in ipairs(valid) do self.sim:conquer(1,t) end
    self:recordOwnership();self.sim.captured={}
    self.spawnTile=tile;self.phase="playing";self:event("새 영토에 정착했어요.")
    return true,"정착"
end
function M:economyPlayer()
    local p=self.sim.players[1];local levels,owned=0,{}
    for _,u in ipairs(self.units) do if u.active then owned[u.kind]=(owned[u.kind] or 0)+(u.building and 1 or u.level);if u.kind=="City" and not u.building then levels+=u.level end end end
    return {kind="HUMAN",host=true,tiles=p.tiles.size,troops=p.troops,cityLevels=levels,owned=owned,constructed=self.constructed}
end
function M:produce()
    if self.phase~="playing" then return end
    self.sim:addTroops(1,E.troopIncrease(self.settings,self:economyPlayer()))
    self.gold=B.add(self.gold,B.fromNumber(E.goldRate(self.settings,self:economyPlayer())))
end
function M:validConstructionTile(tile,owner)
    owner=owner or 1
    local owners=self.sim.owners
    if owners[tile+1]~=owner then return nil end
    local w,h=self.map.meta.width,self.map.meta.height;local n=w*h;local last=(h-1)*w
    local sc=self.constructionScratch
    if not sc or sc.n~=n then sc={n=n,gen=0,seen=buffer.create(n*4)};self.constructionScratch=sc end
    sc.gen+=1;if sc.gen>=2^32-1 then buffer.fill(sc.seen,0,0);sc.gen=1 end
    local seen,gen=sc.seen,sc.gen;local readu32,writeu32=buffer.readu32,buffer.writeu32
    local cx,cy=tile%w,tile//w
    local tiles,stack,top={},{},0
    local function visit(t)
        if readu32(seen,t*4)==gen or owners[t+1]~=owner then return end
        local dx,dy=t%w-cx,t//w-cy;if dx*dx+dy*dy>=225 then return end
        writeu32(seen,t*4,gen);tiles[#tiles+1]=t;top+=1;stack[top]=t
    end
    visit(tile)
    while top>0 do
        local t=stack[top];stack[top]=nil;top-=1;local x=t%w
        if t>=w then visit(t-w) end
        if t<last then visit(t+w) end
        if x~=0 then visit(t-1) end
        if x~=w-1 then visit(t+1) end
    end
    local near={}
    local distanceCy=math.floor(tile/w)
    for _,u in ipairs(self.units)do if u.active and U.structures[u.kind]then
        local x,y=u.tile%w,math.floor(u.tile/w);local dx,dy=x-cx,y-distanceCy
        if dx*dx+dy*dy<900 then table.insert(near,{x,y})end
    end end
    local best,bestDistance=nil,math.huge
    for _,t in ipairs(tiles) do
        local x,y=t%w,t//w;local dx,dy=x-cx,y-cy;local distance=dx*dx+dy*dy
        if distance>=bestDistance then continue end
        local blocked=false
        for _,u in ipairs(near) do local ux,uy=u[1]-x,u[2]-y;if ux*ux+uy*uy<225 then blocked=true;break end end
        if not blocked then best,bestDistance=t,distance end
    end
    return best
end
function M:build(kind,tile)
    if self.unitSystem then return self.unitSystem:build(1,kind,tile) end
    if kind~="City" and kind~="DefensePost" then return false,"이 모드에선 불가" end
    if self.phase~="playing" then return false,"시작 위치 먼저" end
    local preview=self:preview(kind,tile);if not preview.valid then return false,preview.reason end
    table.insert(self.orders,{kind=kind,tile=tile});return true,"건설 명령을 보냈어요."
end
function M:preview(kind,tile)
    if self.unitSystem then return self.unitSystem:preview(1,kind,tile) end
    if kind~="City" and kind~="DefensePost" then return {valid=false,reason="준비 중인 건물"} end
    local cost=E.cost(self.settings,self:economyPlayer(),kind)
    local result={valid=false,cost=B.toString(cost),duration=E.duration(self.settings,kind)/10}
    if self.phase~="playing" then result.reason="시작 위치 먼저";return result end
    if type(tile)~="number" or tile~=tile or tile%1~=0 or tile<0 or tile>=self.map.meta.width*self.map.meta.height then result.reason="내 땅 선택";return result end
    local at=self:validConstructionTile(tile);result.tile=at
    if not at then result.reason="건설 불가  15칸 간격"
    elseif B.compare(self.gold,cost)<0 then result.reason="골드 부족"
    else result.valid=true;result.reason="건설 가능" end
    return result
end
function M:deleteUnit(id)
    if self.phase~="playing" then return false,"경기 중에만" end
    if self.sim.ticks-self.lastDeleteUnitTick<300 then return false,"철거 재사용 대기" end
    for _,e in ipairs(self.orders) do if e.kind=="delete" then return false,"처리 중" end end
    for _,u in ipairs(self.units) do
        if u.id==id and u.active and U.structures[u.kind] and (u.owner or 1)==1 and not u.deleteAt and self.sim:owner(u.tile)==1 then
            table.insert(self.orders,{kind="delete",unit=u});return true,"30초 뒤 철거"
        end
    end
    return false,"내 건물 선택"
end
function M:step()
    if self.phase~="playing" then return end
    self.sim:step()
    local tick=self.sim.ticks-1
    for _,u in ipairs(self.units) do
        if u.active and u.deleteAt and tick>u.deleteAt then u.active=false;self:notify(u.owner or 1,"철거 완료","building",u.tile) end
    end
    for _,e in ipairs(self.construction) do
        if e.active then
            if not e.unit then
                local owner=e.owner or 1
                local tile;if self.unitSystem then tile=self.unitSystem:constructionTile(e.kind,e.tile,owner) else tile=self:validConstructionTile(e.tile,owner) end
                local cost=E.cost(self.settings,self:economyPlayer(owner),e.kind)
                if U.disabled(self.settings,e.kind) then e.active=false;continue end
                local gold=owner==1 and self.gold or self.resources[owner].gold
                if not tile or B.compare(gold,cost)<0 then e.active=false;self:notify(owner,"건설 취소","error",e.tile);continue end
                gold=B.subtract(gold,cost)
                if owner==1 then self.gold=gold else self.resources[owner].gold=gold end
                local constructed=owner==1 and self.constructed or self.resources[owner].constructed
                constructed[e.kind]=(constructed[e.kind] or 0)+1
                self.nextUnit+=1
                local duration=E.duration(self.settings,e.kind)
                e.unit={id=self.nextUnit,owner=owner,kind=e.kind,tile=tile,level=1,active=true,assemblyStartedTick=self.sim.ticks,building=duration>0,duration=duration,remaining=duration};table.insert(self.units,e.unit)
                e.remaining=duration;if duration==0 then e.active=false;self:notify(owner,(U.names[e.kind] or e.kind).." 건설 완료","building",tile) end
            elseif not e.unit.active then e.active=false
            elseif e.remaining==0 then e.unit.building=false;e.active=false;self:notify(e.owner or 1,(U.names[e.kind] or e.kind).." 건설 완료","building",e.unit.tile)
            else e.remaining-=1;e.unit.remaining=e.remaining end
        end
    end
    for _,e in ipairs(self.orders) do
        if e.kind=="delete" then
            if e.unit.active and self.sim:owner(e.unit.tile)==1 and tick-self.lastDeleteUnitTick>=300 then self.lastDeleteUnitTick=tick;e.unit.deleteAt=tick+300 end
        else e.active=true;table.insert(self.construction,e) end
    end;self.orders={}
    local active={};for _,e in ipairs(self.construction) do if e.active then table.insert(active,e) end end;self.construction=active
    if self.unitSystem then self.unitSystem:tick() end
    self:recordOwnership()
    local winner,reason
    if self.checkMatchWinner then winner,reason=self:checkMatchWinner(tick)
    else winner,reason=Win.ffa(self.settings,tick,self.sim.players,self:landTiles(),self.falloutTiles or 0) end
    if winner then self.winnerId=winner;self.winReason=reason;self.phase=winner==1 and "won" or "lost";self.winner=winner==1 end
end
function M:upgrade(id,amount)
    if self.unitSystem then return self.unitSystem:upgrade(1,id,amount) end
    for _,u in ipairs(self.units) do
        if u.id==id and u.active and not u.building and u.kind=="City" then
            local cost=E.cost(self.settings,self:economyPlayer(),u.kind)
            if B.compare(self.gold,cost)<0 then return false,"골드 부족" end
            self.gold=B.subtract(self.gold,cost);u.level+=1;self.constructed[u.kind]=(self.constructed[u.kind] or 0)+1;self:event("도시가 레벨 "..u.level.."이 됐어요.","building");return true,"도시 레벨을 올렸어요."
        end
    end
    return false,"완공한 도시 선택"
end
function M:state(fullOwnership)
    local p=self:economyPlayer();local base=self.sim:snapshot();local count=p.tiles
    local x,y=0,0
    self.sim.players[1].tiles:forEach(function(t) x+=t%self.map.meta.width;y+=math.floor(t/self.map.meta.width) end)
    local owned=nil
    if fullOwnership~=false then owned={};self.sim.players[1].tiles:forEach(function(t) table.insert(owned,t) end) end
    local labelTile,best=nil,math.huge
    if count>0 then x/=count;y/=count;self.sim.players[1].tiles:forEach(function(t) local dx,dy=t%self.map.meta.width-x,math.floor(t/self.map.meta.width)-y;local d=dx*dx+dy*dy;if d<best then labelTile=t;best=d end end) end
    local units={};for _,u in ipairs(self.units) do if u.active then table.insert(units,table.clone(u)) end end
    local costs={};for _,kind in ipairs({"City","DefensePost"}) do costs[kind]=B.toString(E.cost(self.settings,p,kind)) end
    return {phase=self.phase,tick=self.sim.ticks,map=self.map.meta.key,owned=owned,captured=fullOwnership==false and self.ownershipChanges or nil,ownershipRevision=self.ownershipRevision,baseRevision=self.baseRevision,units=units,attacks=base.players[1].attacks,events=self.events,costs=costs,deleteAvailableIn=math.max(0,300-(self.sim.ticks-self.lastDeleteUnitTick))/10,player={id=1,name=self.name,troops=p.troops,gold=B.toString(self.gold),cap=E.maxTroops(self.settings,p),tiles=count,share=count/math.max(1,self:landTiles()),cityLevels=p.cityLevels,income=E.goldRate(self.settings,p)*10,growth=math.floor(E.troopIncrease(self.settings,p))*10,growthTrendRate=E.troopIncrease(self.settings,p)*10,labelTile=labelTile,flag=self.resources and self.resources[1] and self.resources[1].flag or nil,x=count>0 and x or nil,y=count>0 and y or nil},settings=self.settings}
end
return M
