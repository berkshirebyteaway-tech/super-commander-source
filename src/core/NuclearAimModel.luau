local U=if script then require(script.Parent.UnitRules)else require('./UnitRules')
local F=if script then require(script.Parent.FlightPath)else require('./FlightPath')
local T=if script then require(script.Parent.Terrain)else require('./Terrain')
local B=if script then require(script.Parent.BigNat)else require('./BigNat')
local M={}
local function distance(a,b,w)local x,y=a%w-b%w,math.floor(a/w)-math.floor(b/w);return x*x+y*y end
local function manhattan(a,b,w)return math.abs(a%w-b%w)+math.abs(math.floor(a/w)-math.floor(b/w))end
M.distance2=distance
function M.readySilo(w,owner,tile)
    local best,dist=nil,math.huge;local width=w.map.meta.width
    for _,u in ipairs(w.units)do if u.active~=false and u.owner==owner and u.kind=='MissileSilo'and not u.building and #(u.missileQueue or {})<u.level then
        local d=manhattan(u.tile,tile,width);if d<dist then best=u;dist=d end
    end end;return best
end
function M.readyCount(w,owner)
    local n=0;for _,u in ipairs(w.units)do if u.active~=false and u.owner==owner and u.kind=='MissileSilo'and not u.building then n+=math.max(0,u.level-#(u.missileQueue or {}))end end;return n
end
function M.wait(silo,tick)
    local last=0;for _,t in ipairs(silo.missileQueue or {})do last=math.max(t+1,last+1)end;return math.max(0,last-tick)
end
local function hasAllies(w,owner)
    local p=w.sim.players[owner]
    for id,q in pairs(w.sim.players)do if id~=owner and id~=0 and w:friendly(owner,id)and not(p.team and p.team==q.team)then return true end end
    return false
end
function M.breakList(w,owner,kind,tile)
    local counts={};local width,height=w.map.meta.width,w.map.meta.height
    if kind=='MIRV'then local id=w.sim:owner(tile);if id~=owner and id~=0 and w:friendly(owner,id)then return {id}end;return {}end
    if not hasAllies(w,owner)then return {}end
    local inner,outer=U.magnitude(kind);local cx,cy=tile%width,math.floor(tile/width)
    for y=math.max(0,cy-outer),math.min(height-1,cy+outer)do for x=math.max(0,cx-outer),math.min(width-1,cx+outer)do
        local d=(x-cx)^2+(y-cy)^2;local id=w.sim:owner(y*width+x)
        if id~=0 and id~=owner and d<=outer*outer then counts[id]=(counts[id]or 0)+(d<=inner*inner and 1 or .5)end
    end end
    for _,u in ipairs(w.units)do if u.active~=false and U.structures[u.kind]and u.owner~=owner and distance(u.tile,tile,width)<=outer*outer then counts[u.owner]=100 end end
    local out={};for id,n in pairs(counts)do if n>=100 and w:friendly(owner,id)then
        local p,q=w.sim.players[owner],w.sim.players[id];if not(p.team and q and p.team==q.team)then table.insert(out,id)end
    end end;table.sort(out);return out
end
function M.interception(width,tick,sam,u,path,index)
    local function targetable(t)return distance(t,u.sourceTile,width)<22500 or distance(t,u.targetTile,width)<22500 end
    for i=index,#path-1 do
        local tile=path[i];local nukeTicks=i-index+(u.waitTicks or 0);local samTicks=math.ceil(manhattan(sam.tile,tile,width)/12)
        local range=U.dynamicSamRange(sam,tick+nukeTicks)
        if targetable(tile)and distance(sam.tile,tile,width)<=range*range and nukeTicks>=samTicks then return nukeTicks-samTicks,tile,i end
    end
    local range=U.dynamicSamRange(sam,tick+#path-index+(u.waitTicks or 0));local tile=path[#path-1]
    if tile and targetable(tile)and distance(sam.tile,u.targetTile,width)<=range*range then
        local delay=#path-1-index+(u.waitTicks or 0)-math.ceil(manhattan(sam.tile,tile,width)/12)
        if delay>=0 then return delay,tile,#path-1 end
    end;return nil
end
function M.plan(w,owner,kind,tile,up)
    local width,height=w.map.meta.width,w.map.meta.height;local tick=w.sim.ticks
    local p=w.sim.players[owner];local r={kind=kind,target=tile,up=up~=false,tick=tick,path={},sams={},breaks={},valid=false}
    if not p or not U.nukes[kind]or kind=='MIRVWarhead'or type(tile)~='number'or tile%1~=0 or tile<0 or tile>=width*height then r.reason='목표 선택';return r end
    r.cost=B.toString(w.unitSystem:cost(owner,kind));local id=w.sim:owner(tile);local q=w.sim.players[id]
    local reason
    if w.phase~='playing'or p.tiles.size==0 then reason='경기 중에만'
    elseif tick<(w.settings.spawnImmunityDuration or 50)then reason='보호 시간'
    elseif T.isImpassable(w.sim.terrain[tile+1])or U.disabled(w.settings,kind)then reason='발사할 수 없는 목표'
    elseif kind=='MIRV'and id==0 then reason='상대 영토 선택'
    elseif p.team and q and p.team==q.team then reason='같은 팀'end
    if p.team and kind~='MIRV'then local _,outer=U.magnitude(kind)
        for _,u in ipairs(w.units)do if u.active~=false and U.structures[u.kind]and w.sim.players[u.owner]and w.sim.players[u.owner].team==p.team and distance(u.tile,tile,width)<=outer*outer then reason='범위에 같은 팀 건물';break end end
    end
    local silo=M.readySilo(w,owner,tile)
    if not silo then
        reason=reason or '사일로 필요'
        local best=math.huge;for _,v in ipairs(w.units)do if v.active~=false and v.owner==owner and v.kind=='MissileSilo'and not v.building then local d=manhattan(v.tile,tile,width);if d<best then best=d;silo=v end end end
        if not silo then r.reason=reason;return r end
    end
    r.source=silo.tile;r.silo=silo.id;r.ready=silo.level-#(silo.missileQueue or {});r.readyTotal=M.readyCount(w,owner);r.waitTicks=kind=='MIRV'and 0 or M.wait(silo,tick)
    local dst,speed=tile,U.nukeSpeed(kind)
    if kind=='MIRV'then dst=math.clamp(math.max(0,math.floor(tile/width)-500)+50,0,height-1)*width+math.floor((tile%width+silo.tile%width)/2);speed=F.mirvSpeed(width,height,silo.tile,dst);r.separation=dst;r.up=true end
    r.path=F.parabola(width,height,silo.tile,dst,speed,r.up);r.inner,r.outer=U.magnitude(kind=='MIRV'and 'MIRVWarhead'or kind)
    r.breaks=M.breakList(w,owner,kind,tile);local canonical={};for _,v in ipairs(r.breaks)do table.insert(canonical,w.matchIds and w.matchIds[v]or v)end;table.sort(canonical);r.relationStamp=table.concat(canonical,',')
    local u={sourceTile=silo.tile,targetTile=tile,waitTicks=r.waitTicks}
    for _,sam in ipairs(w.units)do if sam.active~=false and sam.kind=='SAMLauncher'and sam.owner~=owner and (not w:friendly(owner,sam.owner)or table.find(r.breaks,sam.owner))then
        local item={id=sam.id,tile=sam.tile,owner=sam.owner,range=sam.building and U.samRange(sam.level)or U.dynamicSamRange(sam,tick),building=sam.building==true,ready=math.max(0,sam.level-#(sam.missileQueue or {}))}
        if kind~='MIRV'and not sam.building then
            local delay,at,index=M.interception(width,tick,sam,u,r.path,1)
            if delay then
                local busy=0;for _,t in ipairs(sam.missileQueue or {})do if tick+delay-t<90 then busy+=1 end end
                local launchIndex=math.clamp(1+math.max(0,delay-r.waitTicks),1,#r.path)
                if busy<sam.level and distance(sam.tile,r.path[launchIndex],width)<=360000 then item.intercept=at;item.index=index;item.delay=delay;r.risk=true end
            end
        end;table.insert(r.sams,item)
    end end
    if B.compare(w:getGold(owner),B.fromString(r.cost))<0 then reason='골드 부족'end
    r.valid=reason==nil;r.reason=reason or (r.risk and '요격 위험'or kind=='MIRV'and '탄두 요격 위험'or '요격 위험 없음')
    return r
end
function M.fromState(state,map,owners)
    local players,allies={},{};for _,f in ipairs(state.factions or {})do players[f.id]={team=f.team,tiles={size=f.tiles}};if allies[f.id]==nil then allies[f.id]=f.allied==true end end
    players[1]=players[1]or {team=state.player.team,tiles={size=state.player.tiles}}
    local w={map=map,units=state.units or {},settings=state.settings,phase=state.phase,sim={ticks=state.tick,terrain={}},unitSystem={},matchIds={}}
    for _,f in ipairs(state.factions or {})do w.matchIds[f.id]=f.matchId end
    setmetatable(w.sim.terrain,{__index=function(_,i)return buffer.readu8(map.terrain,i-1)end})
    w.sim.players=players;function w.sim:owner(t)return owners[t]or 0 end
    function w:distance2(a,b)return distance(a,b,map.meta.width)end
    function w:friendly(a,b)return a==b or allies[b]==true end
    function w:getGold()return B.fromString(tostring(state.player.gold))end
    function w.unitSystem:cost(_,kind)return B.fromString(state.costs[kind]or '0')end
    return w
end
return M
