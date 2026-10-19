--!native
-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Boat routes for nation planning and launches (PathFinding.Water
local M={}
local CACHE_MAX=4096
local cache=setmetatable({},{__mode="k"})
local function slot(w)
    local c=cache[w];local n=w.map.meta.width*w.map.meta.height;local rev=w.unitSystem.terrainRevision or 0
    if not c or c.n~=n then
        c={n=n,gen=0,heap={},tiles={},costs={}};cache[w]=c
    end
    if c.rev~=rev then
        c.rev=rev;c.paths={};c.count=0;c.shores={};local water=buffer.create(n);local terrain,tb=w.sim.terrain,w.sim.tb
        for t=0,n-1 do local b=if tb then buffer.readu8(tb,t) else terrain[t+1];buffer.writeu8(water,t,bit32.band(b,128)==0 and 1 or bit32.band(b,31)~=31 and 2 or 0) end
        c.water=water
    end
    return c
end
function M.shores(w,id)
    local c=slot(w);local p=w.sim.players[id];if not p then return {tiles={},comps={},reachable={}} end
    local e=c.shores[id]
    if e and e.size==p.tiles.size and (p.border.revision~=nil and e.revision==p.border.revision or p.border.revision==nil and e.tick==w.sim.ticks) then return e end
    local water,nav=c.water,w.unitSystem.nav;local width,height=w.map.meta.width,w.map.meta.height;local last=(height-1)*width
    local tiles,comps,reachable={},{},{}
    p.border:forEach(function(t)
        if buffer.readu8(water,t)~=2 then return end
        local x=t%width;local list=nil
        local function check(nb) if buffer.readu8(water,nb)==1 then list=list or {};table.insert(list,nb) end end
        if t>=width then check(t-width) end;if t<last then check(t+width) end;if x~=0 then check(t-1) end;if x~=width-1 then check(t+1) end
        if list then
            for i,nb in ipairs(list) do list[i]=nav:component(nb) end
            table.insert(tiles,t);table.insert(comps,list);reachable[list[1]]=true
        end
    end)
    e={tick=w.sim.ticks,size=p.tiles.size,revision=p.border.revision,tiles=tiles,comps=comps,reachable=reachable};c.shores[id]=e
    return e
end
local function isShore(water,t,width,height)
    if buffer.readu8(water,t)~=2 then return false end
    local x=t%width
    return t>=width and buffer.readu8(water,t-width)==1 or t<(height-1)*width and buffer.readu8(water,t+width)==1 or x~=0 and buffer.readu8(water,t-1)==1 or x~=width-1 and buffer.readu8(water,t+1)==1
end
function M.isShore(w,t)
    return isShore(slot(w).water,t,w.map.meta.width,w.map.meta.height)
end
function M.landing(w,owner,target)
    local info=M.shores(w,owner);local reachable=info.reachable
    if next(reachable)==nil then return nil end
    local c=slot(w);local width,height=w.map.meta.width,w.map.meta.height
    local nav=w.unitSystem.nav;local sim=w.sim;local targetOwner=sim:owner(target)
    local function ok(t) return sim:owner(t)==targetOwner and isShore(c.water,t,width,height) and reachable[nav:component(t)]==true end
    if ok(target) then return target end
    local last=(height-1)*width
    if not c.stamp then c.stamp=buffer.create(4*c.n) end
    c.gen+=1;if c.gen>=2^31 then buffer.fill(c.stamp,0,0);c.gen=1 end
    local mark,stamp=c.gen*2,c.stamp;local cx,cy=target%width,target//width
    local best,distance=nil,math.huge;local stack={};local top=0
    local function visit(t)
        if buffer.readu32(stamp,4*t)==mark then return end
        local d=math.abs(t%width-cx)+math.abs(t//width-cy);if d>50 then return end
        if d<distance and ok(t) then best=t;distance=d end
        buffer.writeu32(stamp,4*t,mark);top+=1;stack[top]=t
    end
    visit(target)
    while top>0 and distance>1 do
        local t=stack[top];stack[top]=nil;top-=1;local x=t%width
        if t>=width then visit(t-width) end;if t<last then visit(t+width) end;if x~=0 then visit(t-1) end;if x~=width-1 then visit(t+1) end
    end
    return best
end
function M.path(w,launch,landing,bound)
    local c=slot(w);local key=launch*c.n+landing;local e=c.paths[key]
    if e then
        if e.path then return #e.path-1<=bound and e.path or nil end
        if e.miss>=bound then return nil end
    else
        if c.count>=CACHE_MAX then c.paths={};c.count=0 end
        e={miss=-1};c.paths[key]=e;c.count+=1
    end
    local path=M.search(w,c,launch,landing,bound)
    if path then e.path=path else e.miss=bound end
    return path
end
function M.search(w,c,launch,landing,bound)
    local width,height=w.map.meta.width,w.map.meta.height;local n=c.n
    if launch<0 or launch>=n or landing<0 or landing>=n then return nil end
    local nav=w.unitSystem.nav;local component=nav:component(landing)
    if not component or not nav:touches(launch,component) then return nil end
    local tx,ty=landing%width,landing//width;local lastRow=(height-1)*width
    if math.abs(launch%width-tx)+math.abs(launch//width-ty)>bound then return nil end
    if not c.stamp then c.stamp=buffer.create(4*n) end
    if not c.g then c.g=buffer.create(4*n);c.parent=buffer.create(4*n) end
    local water,stamp,g,parent=c.water,c.stamp,c.g,c.parent
    c.gen+=1;if c.gen>=2^31 then buffer.fill(stamp,0,0);c.gen=1 end
    local open,closed=c.gen*2,c.gen*2+1
    local heap,tiles,costs=c.heap,c.tiles,c.costs;local size,serial=0,0
    local SHIFT,DEPTH=2^24,16384
    local function push(t,cost,f)
        serial+=1;tiles[serial]=t;costs[serial]=cost
        local key=(f*DEPTH+(cost<DEPTH and DEPTH-1-cost or 0))*SHIFT+serial;size+=1;local i=size
        while i>1 do local p=i//2;local pk=heap[p];if pk<=key then break end;heap[i]=pk;i=p end;heap[i]=key
    end
    buffer.writeu32(stamp,4*launch,open);buffer.writeu32(g,4*launch,0);buffer.writei32(parent,4*launch,-1)
    push(launch,0,math.abs(launch%width-tx)+math.abs(launch//width-ty))
    local found=false
    while size>0 do
        local top=heap[1];local last=heap[size];heap[size]=nil;size-=1
        if size>0 then
            local i=1
            while true do
                local ch=i*2;if ch>size then break end
                local ck=heap[ch];if ch<size and heap[ch+1]<ck then ch+=1;ck=heap[ch] end
                if ck>=last then break end;heap[i]=ck;i=ch
            end
            heap[i]=last
        end
        local sq=top%SHIFT;local t=tiles[sq];local cost=costs[sq]
        if buffer.readu32(stamp,4*t)==closed then continue end
        buffer.writeu32(stamp,4*t,closed)
        if t==landing then found=true;break end
        local nc=cost+1;local x=t%width;local y=t//width
        for k=1,4 do
            local nb,nx,ny
            if k==1 then if t<width then continue end;nb=t-width;nx=x;ny=y-1
            elseif k==2 then if t>=lastRow then continue end;nb=t+width;nx=x;ny=y+1
            elseif k==3 then if x==0 then continue end;nb=t-1;nx=x-1;ny=y
            else if x==width-1 then continue end;nb=t+1;nx=x+1;ny=y end
            local st=buffer.readu32(stamp,4*nb)
            if st==closed or buffer.readu8(water,nb)~=1 and nb~=landing then continue end
            local f=nc+math.abs(nx-tx)+math.abs(ny-ty);if f>bound then continue end
            if st~=open or nc<buffer.readu32(g,4*nb) then
                buffer.writeu32(stamp,4*nb,open);buffer.writeu32(g,4*nb,nc);buffer.writei32(parent,4*nb,t);push(nb,nc,f)
            end
        end
    end
    for i=1,size do heap[i]=nil end
    if not found then return nil end
    local out={};local t=landing
    while t~=-1 do table.insert(out,t);t=buffer.readi32(parent,4*t) end
    local path=table.create(#out);for i=#out,1,-1 do table.insert(path,out[i]) end
    return path
end
return M
