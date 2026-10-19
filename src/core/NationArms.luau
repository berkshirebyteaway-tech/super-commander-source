-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors, pinned e02eeba. AiAttackBehavior sea branches: boat route
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local C=if script then require(script.Parent.NationCommon) else require("./NationCommon")
local Routes=if script then require(script.Parent.NationRoutes) else require("./NationRoutes")
local M={};M.__index=M
local function smart(d) return d=="Hard" or d=="Impossible" end
local DANGER=150
function M.new(ai) return setmetatable({a=ai,routes=nil},M) end
function M:boat(target,randomTarget)
    local a=self.a;local w,s=a.world,a.world.unitSystem;if not s or U.disabled(w.settings,"TransportShip") or s:count(a.id,"TransportShip")>=3 then return false end
    local shores=s.nav:shores(a.id);if #shores==0 then return false end
    local candidates={};local width,height=w.map.meta.width,w.map.meta.height
    if randomTarget then
        local src=a.random:randElement(shores)
        for _=1,500 do local x,y=src%width+a.random:nextInt(-150,150),math.floor(src/width)+a.random:nextInt(-150,150)
            if x>=0 and y>=0 and x<width and y<height then local t=y*width+x;local id=w.sim:owner(t)
                if s.nav:land(t) and id~=a.id and not w:friendly(a.id,id) and (id==0 or w.sim.players[id].troops<a.player.troops and not w:sharesLandBorder(a.id,id)) then table.insert(candidates,t) end
            end
        end
    elseif target==0 then
        for i=1,#shores,10 do local t=shores[i];local x,y=t%width,math.floor(t/width)
            for _,dir in ipairs({{0,-1},{0,1},{-1,0},{1,0}}) do local nx,ny=x+dir[1]*5,y+dir[2]*5
                if nx>=0 and ny>=0 and nx<width and ny<height then local tile=ny*width+nx;if s.nav:land(tile) and w.sim:owner(tile)==0 and not w.sim.fallout[tile] then table.insert(candidates,tile) end end
            end
        end
    elseif w.sim.players[target] then candidates=s.nav:shores(target) end
    local own=shores[1]
    if target and target~=0 then table.sort(candidates,function(x,y)local dx,dy=s.nav:manhattan(own,x),s.nav:manhattan(own,y);return dx<dy or dx==dy and x<y end) end
    for i=1,math.min(25,#candidates) do
        local dst=candidates[i];local path=s.nav:transport(a.id,dst)
        if not path then continue end
        local blocked=false
        for _,u in ipairs(w.units) do if u.active and u.kind=="Warship" and not w:friendly(a.id,u.owner) then for j=1,#path,5 do if w:distance2(u.tile,path[j])<16900 then blocked=true;break end end end;if blocked then break end end
        if blocked and (not smart(a.difficulty) or s:count(a.id,"TransportShip")>0) then continue end
        local troops=math.min(a.player.troops/5,math.max(0,a.player.troops-w:maxTroops(a.id)*(w.sim:owner(dst)==0 and a.expand or a.reserve)))
        if smart(a.difficulty) then troops=math.max(1,math.floor(a.player.troops/100)) end
        if troops>=1 then return s.naval:transport(a.id,dst,troops) end
    end;return false
end
function M:full() local a=self.a;local w=a.world;return U.disabled(w.settings,"TransportShip") or w.unitSystem:count(a.id,"TransportShip")>=3 end
function M:beachheads() return self.a.player.kind=="NATION" and smart(self.a.difficulty) end
function M:launch(tile)
    local a=self.a;local w,s=a.world,a.world.unitSystem
    if s:count(a.id,"TransportShip")>=3 then return nil end
    local owner=w.sim:owner(tile)
    if owner==a.id or owner~=0 and (w:friendly(a.id,owner) or w:protectedTarget(a.id,owner)) then return nil end
    local landing=Routes.landing(w,a.id,tile);if not landing then return nil end
    local c=s.nav:component(landing);local best,d=nil,math.huge;local info=Routes.shores(w,a.id);local width=w.map.meta.width
    for i,t in ipairs(info.tiles) do if table.find(info.comps[i],c) then local m=C.manhattan(width,t,landing);if m<d then best=t;d=m end end end
    if not best then return nil end
    return best,landing
end
function M:hostileWarships()
    local a=self.a;local w=a.world;local out={}
    for _,u in ipairs(C.units(w,"Warship")) do if u.active and u.owner~=a.id and not u.building and u.navalState~="docked" and not w:friendly(a.id,u.owner) then table.insert(out,u) end end
    return out
end
function M:sail(launch,landing,warships)
    local a=self.a;local w,s=a.world,a.world.unitSystem;local nav=s.nav;local width=w.map.meta.width
    local direct=nav:manhattan(launch,landing)
    if a.player.kind=="BOT" or a.difficulty=="Easy" then return direct,nil end
    warships=warships or self:hostileWarships()
    local path,length=nil,direct
    if a.difficulty~="Medium" and direct>20 then
        local cap=self:maxRoute()-1;local bound=math.min(direct*3+100,cap)
        path=Routes.path(w,launch,landing,bound)
        if path then length=#path elseif bound==cap then length=cap+2 end
    end
    local route=path or {launch,landing}
    local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
    for _,t in ipairs(route) do local x,y=t%width,math.floor(t/width);minX=math.min(minX,x);maxX=math.max(maxX,x);minY=math.min(minY,y);maxY=math.max(maxY,y) end
    for _,u in ipairs(warships) do
        local wx,wy=u.tile%width,math.floor(u.tile/width)
        if wx<minX-DANGER or wx>maxX+DANGER or wy<minY-DANGER or wy>maxY+DANGER then continue end
        for i,t in ipairs(route) do
            if w:distance2(u.tile,t)>DANGER*DANGER then continue end
            if 4*(length-(path and i-1 or 0))>=nav:manhattan(u.tile,t)-10 then return length,u end
            break
        end
    end
    return length,nil
end
function M:routeTo(landing,warships)
    local launch=self:launch(landing);if not launch then return nil end
    local length,blocker=self:sail(launch,landing,warships)
    return {landing=landing,length=length,blocker=blocker}
end
function M:otherLandings(ours,theirs,tried,warships)
    local a=self.a;local w=a.world;local width=w.map.meta.width
    local count=({Medium=1,Hard=2,Impossible=4})[a.difficulty];if not count then return {} end
    local ourStep=math.max(1,math.floor(#ours/32));local sample={}
    for i=1,#ours,ourStep do table.insert(sample,ours[i]) end
    local candidates={}
    for i=1,#theirs,math.max(1,math.floor(#theirs/32)) do
        local tile=theirs[i];local covered=false
        for _,u in ipairs(warships) do if w:distance2(u.tile,tile)<=DANGER*DANGER then covered=true;break end end
        if covered then continue end
        local d=math.huge;for _,t in ipairs(sample) do d=math.min(d,C.manhattan(width,t,tile)) end
        table.insert(candidates,{tile=tile,d=d})
    end
    C.sort(candidates,function(c) return c.d end)
    local picked={tried}
    for _,c in ipairs(candidates) do
        if #picked>count then break end
        local near=false;for _,p in ipairs(picked) do if C.manhattan(width,p,c.tile)<50 then near=true;break end end
        if not near then table.insert(picked,c.tile) end
    end
    table.remove(picked,1);return picked
end
function M:plan(target)
    local a=self.a;local w,s=a.world,a.world.unitSystem
    if self:full() then return nil end
    local ours,theirs=Routes.shores(w,a.id).tiles,Routes.shores(w,target).tiles
    local _,closest=C.closest(w.map.meta.width,ours,theirs);if not closest then return nil end
    local warships=self:hostileWarships()
    local direct=self:routeTo(closest,warships)
    if direct and not direct.blocker then return direct end
    local best=nil
    for _,landing in ipairs(self:otherLandings(ours,theirs,closest,warships)) do
        local route=self:routeTo(landing,warships)
        if route and not route.blocker and (not best or route.length<best.length) then best=route end
    end
    return best or direct
end
function M:route(target)
    local cache=self.routes
    if cache and cache.map[target]~=nil then return cache.map[target] or nil end
    local route=self:plan(target)
    if cache then cache.map[target]=route or false;table.insert(cache.list,target) end
    return route
end
function M:maxRoute() return ({Hard=300,Impossible=500})[self.a.difficulty] or math.huge end
function M:reach(target) local route=self:route(target);return route~=nil and route.blocker==nil and route.length<=self:maxRoute() end
function M:overseas(enemies)
    local a=self.a;local w=a.world
    if w.unitSystem:count(a.id,"TransportShip")>=3 then return {} end
    local range=self:maxRoute();local ours=C.box(w,a.id);local team=C.team(w,a.id);local out={}
    for id,p in ipairs(w.sim.players) do
        if id==a.id or p.tiles.size==0 or p.kind=="BOT" or w:friendly(a.id,id) or table.find(enemies,id) then continue end
        if (team or p.troops<a.player.troops) and C.gap(ours,C.box(w,id))<=range then table.insert(out,id) end
    end
    return out
end
function M:clearBlockedLane(routes,landFront)
    local a=self.a;local w=a.world;if not smart(a.difficulty) or not a.warships then return end
    local team=C.team(w,a.id);local blocked,ids={},{}
    for _,id in ipairs(routes.list) do
        local route=routes.map[id]
        if route and route.blocker and (not landFront or route.length<=self:maxRoute()) and (team or w.sim.players[id].troops<a.player.troops) then blocked[id]=route.blocker;table.insert(ids,id) end
    end
    local target=#ids>0 and C.juicy(w,ids) or nil
    if target then a.warships:clearSeaLane(blocked[target]) end
end
function M:transport(tile,troops)
    local a=self.a;local w=a.world;local launch,landing=self:launch(tile)
    local path=launch and w.unitSystem.nav:path(launch,landing) or nil
    if path and path[1]~=launch then table.insert(path,1,launch) end
    return (w.unitSystem.naval:transport(a.id,tile,troops,path))
end
function M:attack(target)
    local a=self.a;local route=self:route(target);if not route then return false end
    local beachhead=self:beachheads()
    if route.blocker and (not beachhead or a.world.unitSystem:count(a.id,"TransportShip")>0) then return false end
    if beachhead then return self:beachhead(target,route.landing) end
    local troops=a:troops(target,a.player.troops/5);if not troops then return false end
    return self:transport(route.landing,troops)
end
function M:beachhead(target,landing)
    local a=self.a;local troops=a:troops(target,nil,target~=0 and target or nil);if not troops then return false end
    local boat=math.max(1,math.floor(a.player.troops/100))
    if target~=0 and a.world.sim.players[target].kind=="BOT" then a.botSent+=boat-troops end
    return self:transport(landing,boat)
end
function M:randomBoat(enemies)
    local a=self.a;local w=a.world;if self:full() then return end
    local shores=Routes.shores(w,a.id).tiles;if #shores==0 then return end
    local src=a.random:randElement(shores)
    local dst,launch=self:findRandom(src,enemies,true)
    if not dst then dst,launch=self:findRandom(src,enemies,false);if not dst then return end end
    if select(2,self:sail(launch,dst)) then return end
    local owner=w.sim:owner(dst)
    if self:beachheads() then self:beachhead(owner,dst);return end
    local troops=math.min(a.player.troops/5,owner~=0 and a:sendCap() or a:expansionCap())
    if troops<1 or owner~=0 and a:tooWeak(troops,owner) then return end
    self:transport(dst,troops)
end
function M:findRandom(src,enemies,high)
    local a=self.a;local w=a.world;local nav=w.unitSystem.nav;local width,height=w.map.meta.width,w.map.meta.height
    local x,y=src%width,math.floor(src/width);local unreachable={};local team=C.team(w,a.id)
    for _=1,500 do
        local rx,ry=a.random:nextInt(x-150,x+150),a.random:nextInt(y-150,y+150)
        if rx<0 or ry<0 or rx>=width or ry>=height then continue end
        local tile=ry*width+rx;if not nav:land(tile) then continue end
        local owner=w.sim:owner(tile)
        if owner==a.id or owner~=0 and (unreachable[owner] or table.find(enemies,owner) or not team and w.sim.players[owner].troops>a.player.troops) then continue end
        if high and owner~=0 and w.sim.players[owner].kind~="BOT" or not high and owner~=0 and w:friendly(a.id,owner) then continue end
        local launch=self:launch(tile)
        if not launch then if owner~=0 then unreachable[owner]=true end;continue end
        return tile,launch
    end
    return nil
end
function M:neutralBoat()
    local a=self.a;local w=a.world;local nav=w.unitSystem.nav;if self:full() then return false end
    local width,height=w.map.meta.width,w.map.meta.height;local shores=Routes.shores(w,a.id).tiles
    for i=1,#shores,10 do
        local t=shores[i];local bx,by=t%width,math.floor(t/width)
        for _,dir in ipairs({{0,-1},{0,1},{-1,0},{1,0}}) do
            local x1,y1=bx+dir[1],by+dir[2]
            if x1<0 or y1<0 or x1>=width or y1>=height or not nav:water(y1*width+x1) then continue end
            local nx,ny=bx+dir[1]*5,by+dir[2]*5
            if nx<0 or ny<0 or nx>=width or ny>=height then continue end
            local tile=ny*width+nx
            if not nav:land(tile) or w.sim:owner(tile)~=0 or w.sim.fallout[tile] then continue end
            local launch=self:launch(tile);if not launch then continue end
            if select(2,self:sail(launch,tile)) then continue end
            if self:beachheads() then return self:beachhead(0,tile) end
            local troops=math.min(a.player.troops/5,a:expansionCap());if troops<1 then return false end
            return self:transport(tile,troops)
        end
    end
    return false
end
function M:island()
    local a=self.a;local w=a.world;local nav=w.unitSystem.nav
    if self:full() or #Routes.shores(w,a.id).tiles==0 then return nil end
    local team=C.team(w,a.id);local players={}
    for id,p in ipairs(w.sim.players) do if id~=a.id and p.tiles.size>0 and not w:friendly(a.id,id) and (team or p.troops<a.player.troops) then table.insert(players,id) end end
    if #players==0 then return nil end
    local width=w.map.meta.width
    local function center(id) local b=C.box(w,id);return b and (b[2]+math.floor((b[4]-b[2])/2))*width+b[1]+math.floor((b[3]-b[1])/2) or 0 end
    local mine=center(a.id);local distance={};for _,id in ipairs(players) do distance[id]=C.manhattan(width,mine,center(id)) end
    C.sort(players,function(id) return distance[id] end)
    local reachable={}
    for _,id in ipairs(players) do
        local ok
        if self:beachheads() then ok=a:bordersByLand(id) or self:route(id)~=nil else ok=a:canReach(id) end
        if ok then table.insert(reachable,id);if #reachable>=2 then break end end
    end
    if #reachable==0 then return nil end
    if #reachable>=2 and a.random:chance(3) then return reachable[2] end
    return reachable[1]
end
function M:followLandings()
    local a=self.a;if not smart(a.difficulty) then return end
    self.followed=self.followed or {};local active={}
    for _,attack in ipairs(a.player.outgoing) do
        active[attack.id]=true
        if attack.sourceTile and not self.followed[attack.id] then
            self.followed[attack.id]=true
            for _,t in ipairs(a.world.sim:neighbors(attack.sourceTile))do if a.world.sim:owner(t)==attack.target and a.world.unitSystem.nav:land(t)then a:land(attack.target,nil,attack.target~=0 and attack.target or nil);break end end
        end
    end
    for id in pairs(self.followed) do if not active[id] then self.followed[id]=nil end end
end
function M:weapons()
    local a=self.a
    if a.nukes then a.nukes:mirv() end
    if a.warships then a.warships:spawn();a.warships:counter() end
    if a.nukes then a.nukes:send() end
end
return M
