local Spawn=if script then require(script.Parent.SpawnRules)else require('./SpawnRules')
local Format=if script then require(script.Parent.TeamFormat)else require('./TeamFormat')
local Terrain=if script then require(script.Parent.Terrain)else require('./Terrain')
local M={};M.__index=M
M.spread=32;M.planeSeconds=2;M.pickSeconds=8;M.plungeSeconds=2;M.seconds=M.planeSeconds+M.pickSeconds+M.plungeSeconds
M.minimumLanding=3;M.readySeconds=12;M.inputTimeout=.5
M.crossSeconds=2.5
M.nearestRadius=40
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function M.new(world,roster,now,random)
    local self=setmetatable({world=world,roster=table.clone(roster),created=now,lastStep=now,random=random==true,players={},ready={}},M)
    local w,h=world.map.meta.width,world.map.meta.height
    self.speed=math.max(w,h)/M.crossSeconds
    local hash=#roster;for i=1,#tostring(world.settings and world.settings.seed or '')do hash=(hash*31+string.byte(tostring(world.settings.seed),i))%2147483647 end
    local turn=hash%6283/1000
    for id,r in ipairs(roster)do
        local p=world.sim.players[id];local area=Format.area(world.map.meta,world.teamCount,p.team)
        local x=area and area.x+(area.w-1)/2 or (w-1)/2
        local y=area and area.y+(area.h-1)/2 or (h-1)/2
        local n=#roster;local reach=M.spread*math.sqrt((id-.5)/n);local a=turn+id*2.39996
        x=math.clamp(x+math.cos(a)*reach,area and area.x or 0,area and area.x+area.w-1 or w-1)
        y=math.clamp(y+math.sin(a)*reach,area and area.y or 0,area and area.y+area.h-1 or h-1)
        self.players[id]={id=id,userId=r.userId,name=r.name,team=p.team,partyKey=r.partyKey,partyIndex=r.partyIndex,x=x,y=y,dx=0,dy=0,seq=0,area=area,altitude=1,diving=false}
    end
    return self
end
function M:setDiving(id,value,now)
    local p=self.players[id]
    if type(value)~='boolean'or not p or p.landed or self.finished or self.random or not self.startAt or now<self.startAt+M.planeSeconds or now>=self.startAt+M.seconds then return false end
    if value and not p.plungeAt then p.plungeAt=now;p.diving=true end
    return true
end
function M:plungeStart(p)
    if self.random then return M.planeSeconds end
    local pickEnd=M.planeSeconds+M.pickSeconds
    return p.plungeAt and math.min(pickEnd,p.plungeAt-self.startAt)or pickEnd
end
function M:markReady(id,now)
    if not self.players[id]or self.finished then return false end
    self.ready[id]=true
    for index in ipairs(self.roster)do if not self.ready[index]then return true end end
    if not self.startAt then self.startAt=now;self.lastStep=now end
    return true
end
function M:input(id,x,y,seq,now)
    local p=self.players[id]
    if not p or p.landed or self.finished or self.random or not self.startAt or now<self.startAt+M.planeSeconds or now>=self.startAt+self:plungeStart(p)then return false end
    if not finite(x)or not finite(y)or math.abs(x)>1 or math.abs(y)>1 or not finite(seq)or seq%1~=0 or seq<=p.seq or seq>1e9 then return false end
    local length=math.sqrt(x*x+y*y);if length>1 then x/=length;y/=length end
    p.dx,p.dy,p.seq,p.inputAt=x,y,seq,now;return true
end
function M:rally(id,tile,now)
    local p=self.players[id];local meta=self.world.map.meta
    if not p or self.finished or not self.startAt or not finite(tile)or tile%1~=0 or tile<0 or tile>=meta.width*meta.height then return false end
    p.rally={id=id,userId=p.userId,team=p.team,partyKey=p.partyKey,partyIndex=p.partyIndex,tile=tile,expires=now+6}
    return true
end
function M:randomTile(id)
    local p=self.players[id];local world=self.world
    return Spawn.random(world,'drop-'..id,world.settings.seed or 'frontier',p.area)
end
local ring={}
do for dy=-M.nearestRadius,M.nearestRadius do for dx=-M.nearestRadius,M.nearestRadius do local d=dx*dx+dy*dy
    if d>0 and d<=M.nearestRadius*M.nearestRadius then table.insert(ring,{dx,dy,d})end end end
    table.sort(ring,function(a,b)return a[3]<b[3]or a[3]==b[3]and (a[2]<b[2]or a[2]==b[2]and a[1]<b[1])end)end
function M:nearestTile(id,tile)
    local p=self.players[id];local world=self.world;local w,h=world.map.meta.width,world.map.meta.height
    local cx,cy=tile%w,tile//w;local partial
    for _,o in ipairs(ring)do
        local x,y=cx+o[1],cy+o[2]
        if x>=0 and y>=0 and x<w and y<h then
            local t=y*w+x;local b=world.sim.terrain[t+1]
            if Terrain.isLand(b)and not Terrain.isImpassable(b)and world.sim:owner(t)==0 and (not p.area or Format.inside(p.area,t,w))then
                if Spawn.tiles(world,t,true)then return t end
                partial=partial or t
            end
        end
    end
    return partial
end
function M:anyTile(id,tile)
    local p=self.players[id];local world=self.world;local w,h=world.map.meta.width,world.map.meta.height
    local a=p.area;local x0,y0=a and math.max(0,a.x)or 0,a and math.max(0,a.y)or 0
    local x1,y1=a and math.min(w,a.x+a.w)-1 or w-1,a and math.min(h,a.y+a.h)-1 or h-1
    local cx,cy=tile%w,tile//w;local best,bestD
    for y=y0,y1 do for x=x0,x1 do
        local t=y*w+x;local b=world.sim.terrain[t+1]
        if Terrain.isLand(b)and not Terrain.isImpassable(b)and world.sim:owner(t)==0 then
            local d=(x-cx)^2+(y-cy)^2;if not bestD or d<bestD then best,bestD=t,d end
        end
    end end
    return best
end
function M:land(id,now,force)
    local p=self.players[id];local world=self.world
    if not p or p.landed or not self.startAt or self.finished or not force and (now<self.startAt+M.minimumLanding or p.altitude>1e-6)then return false end
    local w,h=world.map.meta.width,world.map.meta.height
    local tile=p.reserved or math.clamp(math.floor(p.y),0,h-1)*w+math.clamp(math.floor(p.x),0,w-1)
    local b=world.sim.terrain[tile+1]
    local valid=Terrain.isLand(b)and not Terrain.isImpassable(b)and world.sim:owner(tile)==0 and (not p.area or Format.inside(p.area,tile,w))
    if not p.reserved and not valid then tile=not self.random and self:nearestTile(id,tile)or self:randomTile(id)or self:anyTile(id,tile);p.fallback=true end
    if not tile then return false end
    p.landed=true;p.tile=tile;p.x=tile%w;p.y=tile//w;p.dx=0;p.dy=0;p.altitude=0;p.diving=false
    return true,tile
end
function M:step(now,onLanding,onRecovery)
    if self.failure then error(self.failure,0)end
    if self.finished then return {} end
    if not self.startAt and now>=self.created+M.readySeconds then self.startAt=now;self.lastStep=now end
    if not self.startAt then self.lastStep=now;return {}end
    local elapsed=now-self.startAt;local dt=math.max(0,math.min(.25,now-self.lastStep));self.lastStep=now
    local w,h=self.world.map.meta.width,self.world.map.meta.height
    local landed={}
    local function land(id,force)
        local ok,tile=self:land(id,now,force)
        if not ok then return end
        if onLanding and not onLanding(id,tile)then
            local p=self.players[id];p.landed=false;p.tile=nil;p.reserved=nil
            return
        end
        table.insert(landed,{id=id,tile=tile})
    end
    if elapsed>=M.planeSeconds then
        local stepStart=elapsed-dt
        for id,p in ipairs(self.players)do if not p.landed then
            local plunge=self:plungeStart(p)
            local travel=math.max(0,math.min(elapsed,plunge)-math.max(stepStart,M.planeSeconds))
            if not self.random and travel>0 then
                local active=p.inputAt and now-p.inputAt<=M.inputTimeout
                p.x=math.clamp(p.x+(active and p.dx or 0)*self.speed*travel,p.area and p.area.x or 0,p.area and p.area.x+p.area.w-1 or w-1)
                p.y=math.clamp(p.y+(active and p.dy or 0)*self.speed*travel,p.area and p.area.y or 0,p.area and p.area.y+p.area.h-1 or h-1)
            end
            if elapsed>=plunge then p.diving=true;p.altitude=math.max(0,1-(elapsed-plunge)/M.plungeSeconds)end
            if p.altitude<=1e-6 then land(id)end
        end end
    end
    if elapsed>=M.seconds then
        for id in ipairs(self.players)do land(id,true)end
        for id,p in ipairs(self.players)do if not p.landed and onRecovery then
            local wanted=math.clamp(math.floor(p.y),0,h-1)*w+math.clamp(math.floor(p.x),0,w-1)
            local tile=onRecovery(id,wanted)
            if tile then
                p.landed=true;p.tile=tile;p.x=tile%w;p.y=tile//w;p.dx=0;p.dy=0;p.altitude=0;p.diving=false;p.fallback=true
                table.insert(landed,{id=id,tile=tile})
            end
        end end
        for id,p in ipairs(self.players)do if not p.landed then
            self.failure="SpawnDrop: final settlement failed for seat "..id
            error(self.failure,0)
        end end
        self.finished=true
    end
    return landed
end
function M:frame(now)
    local elapsed=self.startAt and math.max(0,now-self.startAt)or 0
    local list,rallies={},{}
    for id,p in ipairs(self.players)do
        table.insert(list,table.freeze({id=id,matchId=id,userId=p.userId,name=p.name,team=p.team,partyKey=p.partyKey,partyIndex=p.partyIndex,x=p.x,y=p.y,tile=p.tile,landed=p.landed==true,fallback=p.fallback==true,altitude=p.altitude,diving=p.diving,
            plunge=self.startAt and self:plungeStart(p)or nil}))
        if p.rally and p.rally.expires>now then table.insert(rallies,table.freeze(table.clone(p.rally)))end
    end
    return table.freeze({active=not self.finished,preparing=self.startAt==nil,elapsed=elapsed,left=math.max(0,M.seconds-elapsed),seconds=M.seconds,planeSeconds=M.planeSeconds,
        random=self.random,players=table.freeze(list),rallies=table.freeze(rallies),speed=self.speed,pickSeconds=M.pickSeconds,plungeSeconds=M.plungeSeconds})
end
function M:snapshot(viewer,now,frame)
    local shared=frame or self:frame(now);local result=table.clone(shared)
    if viewer~=1 and self.players[viewer]then
        local list=table.clone(shared.players)
        list[1]=table.clone(list[1]);list[1].id=viewer
        list[viewer]=table.clone(list[viewer]);list[viewer].id=1
        result.players=list
    end
    result.sequence=self.players[viewer]and self.players[viewer].seq or 0
    local own=self.players[viewer]
    if #shared.rallies>0 then
        local visible={};for _,r in ipairs(shared.rallies)do if own and (r.id==viewer or own.team~=nil and r.team==own.team or own.partyKey~=nil and r.partyKey==own.partyKey)then table.insert(visible,r)end end
        result.rallies=visible
    end
    return result
end
return M
