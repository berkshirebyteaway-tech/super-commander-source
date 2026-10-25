-- SPDX-License-Identifier: AGPL-3.0-only
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local E=if script then require(script.Parent.EconomyRules) else require("./EconomyRules")
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local M={};M.__index=M
function M.new(s) return setmetatable({s=s,w=s.w,stations={},rails={},nextRail=0,trains={},revision=0},M) end
function M:prune()
    local live={};for _,rail in ipairs(self.rails)do if rail.active then table.insert(live,rail)end end
    self.rails=live
end
function M:route(src,dst,owner,maxHops)
    local queue={src};local head=1;local parents={[src]=false};local depth={[src]=0}
    while head<=#queue do local at=queue[head];head+=1
        if at==dst then local ids={};repeat table.insert(ids,at);at=parents[at] until at==false;local path={};for i=#ids,1,-1 do table.insert(path,ids[i]) end;return path end
        if maxHops and depth[at]>=maxHops then continue end
        for _,r in ipairs(self.rails) do if r.active and (r.a==at or r.b==at) then
            local nextId=r.a==at and r.b or r.a;local unit=self.s:unit(nextId)
            if unit and parents[nextId]==nil and (not owner or unit.owner==owner or self.w:canTrade(unit.owner,owner)) then parents[nextId]=at;depth[nextId]=depth[at]+1;table.insert(queue,nextId) end
        end end
    end;return nil
end
function M:reach(src)
    local adjacency=self.reachEdges
    if not adjacency or self.reachRevision~=self.revision or self.reachRails~=self.rails then
        adjacency={}
        for _,r in ipairs(self.rails) do if r.active then
            adjacency[r.a]=adjacency[r.a] or {};table.insert(adjacency[r.a],r.b)
            adjacency[r.b]=adjacency[r.b] or {};table.insert(adjacency[r.b],r.a)
        end end
        self.reachEdges,self.reachRevision,self.reachRails=adjacency,self.revision,self.rails
    end
    local queue={src};local head=1;local parents={[src]=false}
    while head<=#queue do local at=queue[head];head+=1
        for _,nextId in ipairs(adjacency[at] or {}) do if parents[nextId]==nil and self.s:unit(nextId) then parents[nextId]=at;table.insert(queue,nextId) end end
    end
    return parents
end
local function pathTo(parents,dst)
    if parents[dst]==nil then return nil end
    local ids={};local at=dst;repeat table.insert(ids,at);at=parents[at] until at==false
    local path={};for i=#ids,1,-1 do table.insert(path,ids[i]) end;return path
end
function M:splitTrains(r,mid,leftCount)
    for _,t in pairs(self.trains) do
        for k=t.nextStop,#t.stops do
            local stop=t.stops[k];local from=k>1 and t.stops[k-1].station or t.source
            local start=k>1 and t.stops[k-1].index or 0
            if (from==r.a and stop.station==r.b or from==r.b and stop.station==r.a) and stop.index-start==#r.tiles then
                local at=start+(from==r.a and leftCount or #r.tiles-leftCount)
                if t.index<=at then table.insert(t.stops,k,{index=at,station=mid}) end
                break
            end
        end
    end
end
function M:connect(u)
    self.stations[u.id]={random=R.new(self.w.sim.ticks),lastSpawn=0};u.hasStation=true
    local snapped=false;local existing=table.clone(self.rails)
    for _,r in ipairs(existing) do if r.active then
        local index,dist=nil,math.huge
        for i,t in ipairs(r.tiles)do local d=self.w:distance2(t,u.tile);if d<dist then index=i;dist=d end end
        if index and index>1 and index<=#r.tiles and dist<=9 then
            r.active=false;local left,right={},{}
            for i,t in ipairs(r.tiles)do table.insert(i<index and left or right,t)end
            for _,segment in ipairs({{r.a,u.id,left},{u.id,r.b,right}})do
                self.nextRail+=1;table.insert(self.rails,{id=self.nextRail,a=segment[1],b=segment[2],tiles=segment[3],active=true})
            end
            self:splitTrains(r,u.id,#left);self.revision+=1;snapped=true
        end
    end end
    if snapped then return end
    local neighbors={}
    for id in pairs(self.stations) do local v=self.s:unit(id);if id~=u.id and v then local d=self.w:distance2(u.tile,v.tile);if d>225 and d<=12100 then table.insert(neighbors,{unit=v,d=d}) end end end
    table.sort(neighbors,function(a,b) return a.d<b.d or a.d==b.d and a.unit.id<b.unit.id end)
    for _,n in ipairs(neighbors) do
        if self:route(u.id,n.unit.id,nil,4) then continue end
        local path=self.s.nav:path(u.tile,n.unit.tile,"rail",440)
        if path and #path<110*1.4142 then self.nextRail+=1;table.insert(self.rails,{id=self.nextRail,a=u.id,b=n.unit.id,tiles=path,active=true});self.revision+=1 end
    end
end
local function corners(path)
    local out={path[1]}
    for i=2,#path-1 do if path[i]-path[i-1]~=path[i+1]-path[i] then table.insert(out,path[i]) end end
    if #path>1 then table.insert(out,path[#path]) end
    return out
end
function M:ghost(kind,tile)
    if kind~="City" and kind~="Port" and kind~="Factory" then return nil end
    local w=self.w;local snap={}
    for _,r in ipairs(self.rails) do if r.active then
        local index,dist=nil,math.huge
        for i,t in ipairs(r.tiles)do local d=w:distance2(t,tile);if d<dist then index=i;dist=d end end
        if index and index>1 and dist<=9 then table.insert(snap,corners(r.tiles)) end
    end end
    if #snap>0 then return {snap=snap} end
    local near=kind=="Factory"
    if not near then for _,f in ipairs(w.units) do if f.active and not f.building and f.kind=="Factory" and w:distance2(tile,f.tile)<=12100 then near=true;break end end end
    if not near then return nil end
    local neighbors={}
    for _,v in ipairs(w.units) do
        local station=self.stations[v.id]~=nil
        if v.active and not v.building and (station or kind=="Factory" and (v.kind=="City" or v.kind=="Port" or v.kind=="Factory")) then
            local d=w:distance2(tile,v.tile);if d>225 and d<=12100 then table.insert(neighbors,{unit=v,d=d,station=station}) end
        end
    end
    table.sort(neighbors,function(a,b) return a.d<b.d or a.d==b.d and a.unit.id<b.unit.id end)
    local paths,linked={},{}
    for _,n in ipairs(neighbors) do
        if #paths>=5 then break end
        local reached=false
        if n.station then for _,l in ipairs(linked) do if self:route(l,n.unit.id,nil,3) then reached=true;break end end end
        if reached then continue end
        local path=self.s.nav:path(tile,n.unit.tile,"rail",440)
        if path and #path>1 and #path<110*1.4142 then table.insert(paths,corners(path));if n.station then table.insert(linked,n.unit.id) end end
    end
    return #paths>0 and {paths=paths} or nil
end
function M:refresh()
    for id in pairs(self.stations) do if not self.s:unit(id) then self.stations[id]=nil;for _,r in ipairs(self.rails) do if r.active and (r.a==id or r.b==id) then r.active=false;self.revision+=1 end end end end
    local factories={};for _,u in ipairs(self.w.units) do if u.active and not u.building and u.kind=="Factory" then table.insert(factories,u) end end
    for _,u in ipairs(self.w.units) do if u.active and not u.building and not self.stations[u.id] and (u.kind=="City" or u.kind=="Port" or u.kind=="Factory") then
        local near=u.kind=="Factory";for _,f in ipairs(factories) do if self.w:distance2(u.tile,f.tile)<=12100 then near=true;break end end
        if near then self:connect(u) end
    end end
end
function M:spawn(factory,destination,route)
    local path,stops={},{}
    for i=1,#route-1 do
        for _,r in ipairs(self.rails) do if r.active and (r.a==route[i] and r.b==route[i+1] or r.b==route[i] and r.a==route[i+1]) then
            if r.a==route[i] then for _,t in ipairs(r.tiles) do table.insert(path,t) end else for j=#r.tiles,1,-1 do table.insert(path,r.tiles[j]) end end
            table.insert(stops,{index=#path,station=route[i+1]});break
        end end
    end
    if #path==0 then return end
    local engine=self.s:create("Train",factory.owner,factory.tile,{destinationStation=destination.id,trainType="Engine"})
    local record={engine=engine,path=path,index=1,stops=stops,nextStop=1,visited=0,cars={},source=factory.id,destination=destination.id}
    for i=1,6 do table.insert(record.cars,self.s:create("Train",factory.owner,factory.tile,{trainType=i==6 and "TailEngine" or "Carriage",engine=engine.id})) end
    self.trains[engine.id]=record
end
function M:stop(t,station)
    if station.kind~="City" and station.kind~="Port" then return end
    local owner=t.engine.owner;local p,q=self.w.sim.players[owner],self.w.sim.players[station.owner]
    local relation=owner==station.owner and "self" or p.team and p.team==q.team and "team" or self.w:friendly(owner,station.owner) and "ally" or "other"
    local gold=E.trainGold(self.w.settings,self.w:economyPlayer(owner),relation,t.visited)
    self.w:setGold(owner,B.add(self.w:getGold(owner),gold))
    if station.owner~=owner then self.w:setGold(station.owner,B.add(self.w:getGold(station.owner),gold)) end
    local res=self.w.resources[owner];if res then local n=tonumber(B.toString(gold))or 0;res.trainGold=(res.trainGold or 0)+n;if relation=='ally'or relation=='team'then res.allyTrainGold=(res.allyTrainGold or 0)+n end end
    t.visited+=1;self.s:effect("trade",station.tile,owner,{gold=B.toString(gold)})
end
function M:tick()
    self:refresh();local w=self.w
    local ids={};for id in pairs(self.trains) do table.insert(ids,id) end;table.sort(ids)
    for _,id in ipairs(ids) do local t=self.trains[id];local nextStop=t.stops[t.nextStop];local station=nextStop and self.s:unit(nextStop.station)
        local previous=t.nextStop>1 and t.stops[t.nextStop-1].station or t.source
        if not t.engine.active or not self.s:unit(previous) or not station or station.owner~=t.engine.owner and not w:canTrade(station.owner,t.engine.owner) then
            if t.engine.active and t.engine.tile and (not station or not self.s:unit(previous)) then self.s:effect("trainLost",t.engine.tile,t.engine.owner,{}) end
            t.engine.active=false;for _,car in ipairs(t.cars) do car.active=false end;self.trains[id]=nil;continue
        end
        t.index=math.min(#t.path,t.index+2);t.engine.tile=t.path[t.index]
        for i,car in ipairs(t.cars) do if car.active then car.tile=t.path[math.max(1,t.index-i*2)] end end
        if t.index>=nextStop.index then self:stop(t,station);t.nextStop+=1 end
        if t.index>=#t.path then t.engine.active=false;for _,car in ipairs(t.cars) do car.active=false end;self.trains[id]=nil end
    end
    if U.disabled(w.settings,"Train") then return end
    for _,u in ipairs(w.units) do
        local st=self.stations[u.id]
        if not st or u.kind~="Factory" or not u.active or u.building or w.sim.ticks<st.lastSpawn+10 then continue end
        local parents=self:reach(u.id)
        local function destination(v) return v.active and v.id~=u.id and parents[v.id]~=nil and self.stations[v.id] and (v.kind=="City" or v.kind=="Port") and (v.owner==u.owner or w:canTrade(v.owner,u.owner)) end
        local any=false;for _,v in ipairs(w.units) do if destination(v) then any=true;break end end
        if not any then continue end
        local rate=U.trainSpawnRate(self.s:count(u.owner,"Factory"),self.s:count(nil,"Train"));local spawn=false
        for _=1,u.level do if st.random:chance(rate) then spawn=true;break end end
        if spawn then
            local destinations={};for _,v in ipairs(w.units) do if destination(v) then table.insert(destinations,v) end end
            local dst=st.random:randElement(destinations);self:spawn(u,dst,pathTo(parents,dst.id));st.lastSpawn=w.sim.ticks
        end
    end
end
return M
