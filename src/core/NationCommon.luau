--!native
-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. NationUtils.ts / execution Util.ts / stable JS ordering, pinned e02eeba.
local Big=if script then require(script.Parent.BigNat) else require("./BigNat")
local E=if script then require(script.Parent.EconomyRules) else require("./EconomyRules")
local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local M={}
function M.sort(items,score)
    local order={};for i,v in ipairs(items) do order[v]=i end
    table.sort(items,function(a,b) local x,y=score(a),score(b);return x<y or x==y and order[a]<order[b] end);return items
end
function M.smart(d) return d=="Hard" or d=="Impossible" end
local HORIZON={Hard=5,Impossible=6}
function M.saveUpWithinReach(w,id,target)
    local horizon=HORIZON[w.settings.difficulty or "Medium"]
    local missing=target-tonumber(Big.toString(w:getGold(id)))
    if not horizon or missing<=0 then return true end
    local minutes=math.max(1,(w.sim.ticks+100)/600)
    local earned=w.resources[id].goldEarned;earned=earned and tonumber(Big.toString(earned)) or 0
    return missing<=(2*earned/minutes)*horizon
end
function M.sum(attacks) local n=0;for _,a in ipairs(attacks) do n+=a.troops end;return n end
function M.total(p) return p.troops+M.sum(p.outgoing) end
function M.team(w,id) return w.sim.players[id].team~=nil end
function M.sameTeam(w,a,b) local p,q=w.sim.players[a],w.sim.players[b];return p~=nil and q~=nil and p.team~=nil and p.team==q.team end
function M.allied(w,a,b) return w.alliances~=nil and w.alliances[math.min(a,b)..":"..math.max(a,b)]~=nil end
function M.allies(w,id)
    local result={};for _,a in ipairs(w:orderedAlliances(id)) do table.insert(result,a.a==id and a.b or a.a) end;return result
end
function M.manhattan(width,a,b) return math.abs(a%width-b%width)+math.abs(math.floor(a/width)-math.floor(b/width)) end
function M.leader(w,id)
    if w.settings.difficulty=="Easy" or id and M.team(w,id) then return nil end
    local first,second=nil,nil
    for pid,p in ipairs(w.sim.players) do
        if p.kind=="BOT" or p.tiles.size==0 then continue end
        if not first or p.tiles.size>w.sim.players[first].tiles.size then second=first;first=pid
        elseif not second or p.tiles.size>w.sim.players[second].tiles.size then second=pid end
    end
    if first and second and w.sim.players[first].tiles.size>=w.sim.players[second].tiles.size*(({Hard=2,Impossible=1.5})[w.settings.difficulty] or 3) then return first end
    return nil
end
function M.juicy(w,ids)
    local stats={};local lo={math.huge,math.huge,math.huge};local hi={-math.huge,-math.huge,-math.huge}
    for _,id in ipairs(ids) do
        local p=w.sim.players[id];local cap=w:maxTroops(id);local n=0
        for _,u in ipairs(w.units) do if u.active and (u.owner or 1)==id and (u.kind=="City" or u.kind=="Port" or u.kind=="Factory" or u.kind=="SAMLauncher") then n+=u.level end end
        local row={n,cap>0 and 1-p.troops/cap or 0,p.tiles.size}
        table.insert(stats,row);for i,v in ipairs(row) do lo[i]=math.min(lo[i],v);hi[i]=math.max(hi[i],v) end
    end
    local best,score=nil,-math.huge
    for index,row in ipairs(stats) do local value=0;for i,v in ipairs(row) do value+=hi[i]>lo[i] and (v-lo[i])/(hi[i]-lo[i]) or 0 end;if value>score then best=ids[index];score=value end end
    return best
end
local cache=setmetatable({},{__mode="k"})
local function slot(w) local c=cache[w];if not c then c={boxes={},mirvs={},owners={}};cache[w]=c end;return c end
function M.units(w,kind)
    local c=slot(w);local list=w.units
    if c.tick~=w.sim.ticks or c.list~=list or c.n~=#list then c.tick=w.sim.ticks;c.list=list;c.n=#list;c.kinds={};c.owners={} end
    local out=c.kinds[kind]
    if not out then out={};for _,u in ipairs(list) do if u.active and u.kind==kind then table.insert(out,u) end end;c.kinds[kind]=out end
    return out
end
function M.owned(w,id,kind)
    local units=M.units(w,kind);local c=slot(w);local groups=c.owners[kind]
    if not groups then groups={};for _,u in ipairs(units) do local owner=u.owner or 1;groups[owner]=groups[owner] or {};table.insert(groups[owner],u) end;c.owners[kind]=groups end
    local out={};for _,u in ipairs(groups[id] or {}) do if u.active and (u.owner or 1)==id then table.insert(out,u) end end;return out
end
function M.mirvTargets(w) return slot(w).mirvs end
function M.borderBox(w,id)
    local border=w.sim.players[id].border;local c=slot(w);c.borderBoxes=c.borderBoxes or {}
    local cached=c.borderBoxes[id]
    if border.revision~=nil and cached and cached.border==border and cached.revision==border.revision then return cached.box end
    local width=w.map.meta.width;local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
    for _,t in ipairs(border.dense)do if t~=false then local x,y=t%width,math.floor(t/width);if x<minX then minX=x end;if y<minY then minY=y end;if x>maxX then maxX=x end;if y>maxY then maxY=y end end end
    local box=minX~=math.huge and {minX,minY,maxX,maxY}or nil
    c.borderBoxes[id]={border=border,revision=border.revision,box=box};return box
end
function M.box(w,id)
    local c=slot(w);local b=c.boxes[id];local window=math.floor(w.sim.ticks/50)
    if not b or b.window~=window then b={window=window,box=M.borderBox(w,id)};c.boxes[id]=b end
    return b.box
end
function M.gap(a,b)
    if not a or not b then return 0 end
    return math.max(0,a[1]-b[3],b[1]-a[3])+math.max(0,a[2]-b[4],b[2]-a[4])
end
function M.randTiles(w,r,id,count)
    local p=w.sim.players[id];local width,height=w.map.meta.width,w.map.meta.height;local box=M.borderBox(w,id) or {0,0,0,0}
    local result={}
    for _=1,count do
        local chosen=nil
        for _=1,100 do
            local x,y=r:nextInt(box[1],box[3]),r:nextInt(box[2],box[4])
            if x>=0 and y>=0 and x<width and y<height and w.sim:owner(y*width+x)==id then chosen=y*width+x;break end
        end
        if not chosen and p.tiles.size>0 and p.tiles.size<=100 then chosen=r:randElement(p.tiles:values()) end
        if chosen then table.insert(result,chosen) end
    end
    return result
end
function M.center(w,id)
    local box=M.borderBox(w,id);if not box then return nil end
    local width=w.map.meta.width;local cx,cy=math.floor((box[1]+box[3])/2),math.floor((box[2]+box[4])/2);local tile=cy*width+cx
    if w.sim:owner(tile)==id then return tile end
    local best,d=nil,math.huge
    w.sim.players[id].border:forEach(function(t) local dx,dy=t%width-cx,math.floor(t/width)-cy;if dx*dx+dy*dy<d then d=dx*dx+dy*dy;best=t end end)
    return best
end
function M.closest(width,xs,ys)
    if #xs==0 or #ys==0 then return nil end
    local a,b=M.sort(table.clone(xs),function(t) return t%width end),M.sort(table.clone(ys),function(t) return t%width end)
    local i,j,best=1,1,math.huge;local rx,ry=a[1],b[1]
    while i<=#a and j<=#b do
        local x,y=a[i],b[j];local d=M.manhattan(width,x,y)
        if d<best then best=d;rx=x;ry=y end
        if i==#a then j+=1 elseif j==#b then i+=1 elseif x%width<y%width then i+=1 else j+=1 end
    end
    return rx,ry
end
function M.ring(w,set,tile,cap)
    if set.size==0 then return math.huge end
    local index=set.index
    if index[tile]~=nil then return 0 end
    local width,height=w.map.meta.width,w.map.meta.height;local cx,cy=tile%width,math.floor(tile/width)
    for d=1,cap do for dx=-d,d do
        local x=cx+dx;if x<0 or x>=width then continue end
        local dy=d-math.abs(dx)
        if cy-dy>=0 and index[(cy-dy)*width+x]~=nil then return d end
        if dy~=0 and cy+dy<height and index[(cy+dy)*width+x]~=nil then return d end
    end end
    return math.huge
end
local STRUCTURES={"City","DefensePost","Port","Factory","MissileSilo","SAMLauncher"}
function M.ownsStructures(w,id)
    for _,kind in ipairs(STRUCTURES) do for _,u in ipairs(M.units(w,kind)) do if u.active and (u.owner or 1)==id then return true end end end;return false
end
function M.maxTroopsWithoutCities(w,id)
    local p=table.clone(w:economyPlayer(id));p.cityLevels=0;return E.maxTroops(w.settings,p)
end
local LEAK={Medium=.1,Hard=.2,Impossible=.25}
local function mirvSamples(w,target)
    local c=slot(w);local tick=w.sim.ticks;local meta=w.map.meta
    if c.sampleTick~=tick or c.sampleWidth~=meta.width or c.sampleHeight~=meta.height then
        c.sampleTick=tick;c.sampleWidth=meta.width;c.sampleHeight=meta.height;c.samples={}
    end
    local p=w.sim.players[target];local tiles,border=p.tiles,p.border
    local tr,br=tiles.revision,border.revision;local cached=c.samples[target]
    if tr~=nil and br~=nil and cached and cached.tiles==tiles and cached.tr==tr and cached.border==border and cached.br==br then return cached.values end
    local values=M.randTiles(w,R.new((tick+100)*1024+target),target,40)
    if tr~=nil and br~=nil then c.samples[target]={tiles=tiles,tr=tr,border=border,br=br,values=values}end
    return values
end
function M.mirvLeakShare(w,attacker,target)
    local warheads=math.min(350,math.max(1,w.sim.players[target].tiles.size/2000))
    local sams={};for _,sam in ipairs(M.units(w,"SAMLauncher")) do local owner=sam.owner or 1;if sam.active and owner~=attacker and not w:friendly(owner,attacker) then table.insert(sams,sam) end end
    if #sams==0 then return 1 end
    local samples=mirvSamples(w,target)
    if #samples==0 then return 1 end
    local per=warheads/#samples;local inRange={};local covered=0
    for _,tile in ipairs(samples) do
        local hit=false
        for i,sam in ipairs(sams) do
            local d2=w:distance2(tile,sam.tile);local range=U.samRange(sam.level)
            if d2<=150*150 and d2<=range*range then inRange[i]=(inRange[i] or 0)+per;hit=true end
        end
        if hit then covered+=1 end
    end
    local shots=0;for i,sam in ipairs(sams) do if inRange[i] then shots+=math.min(sam.level,inRange[i]) end end
    return 1-math.min(covered*per,shots)/warheads
end
function M.mirvGetsThrough(w,attacker,target)
    local min=LEAK[w.settings.difficulty or "Medium"];return not min or M.mirvLeakShare(w,attacker,target)>=min
end
function M.mirvWorthSavingFor(w,id)
    local land,city,landSize,cityLevels=nil,nil,-1,-1
    for pid,p in ipairs(w.sim.players) do
        if pid==id or p.tiles.size==0 or p.kind=="BOT" or M.sameTeam(w,id,pid) then continue end
        if p.tiles.size>landSize then land=pid;landSize=p.tiles.size end
        local levels=0;for _,u in ipairs(M.owned(w,pid,"City")) do levels+=u.level end
        if levels>cityLevels then city=pid;cityLevels=levels end
    end
    if land and M.mirvGetsThrough(w,id,land) then return true end
    return city~=nil and city~=land and M.mirvGetsThrough(w,id,city)
end
return M
