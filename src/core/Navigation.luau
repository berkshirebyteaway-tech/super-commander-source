--!native
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local WaterPath=if script then require(script.Parent.WaterPath) else require("./WaterPath")
local RailPath=if script then require(script.Parent.RailPath) else require("./RailPath")
local WaterTerrain=if script then require(script.Parent.WaterTerrain)else require('./WaterTerrain')
local M={};M.__index=M
function M.new(w) return setmetatable({w=w,components={},nextComponent=0,version=-1,shoreCache={}},M) end
function M:valid(t) return type(t)=="number" and t==t and t%1==0 and t>=0 and t<self.w.map.meta.width*self.w.map.meta.height end
function M:water(t) return not T.isLand(self.w.sim.terrain[t+1]) end
function M:land(t) local b=self.w.sim.terrain[t+1];return T.isLand(b) and not T.isImpassable(b) end
function M:manhattan(a,b) local w=self.w.map.meta.width;return math.abs(a%w-b%w)+math.abs(math.floor(a/w)-math.floor(b/w)) end
function M:shore(t) if not self:land(t) then return false end;for _,n in ipairs(self.w.sim:neighbors(t)) do if self:water(n) then return true end end;return false end
function M:invalidate() if self.compBuf then buffer.fill(self.compBuf,0,0) end;self.nextComponent=0;self.shoreCache={};self.pathCache=nil;if self.waterPath then self.waterPath:clear() end end
function M:waterFinder()
    if not self.waterPath then local meta=self.w.map.meta;self.waterPath=WaterPath.new(self.w.sim.tb,meta.width,meta.height,self:mini())end
    return self.waterPath
end
function M:queueWater(tile)
    self.pendingWater=self.pendingWater or {};self.pendingWaterOrder=self.pendingWaterOrder or {}
    if not self.pendingWater[tile]then self.pendingWater[tile]=true;table.insert(self.pendingWaterOrder,tile)end
end
function M:waterTick()
    local tick=self.w.sim.ticks;local converted={}
    for _,t in ipairs(self.pendingWaterOrder or {})do if self:land(t)and self.w.sim:owner(t)==0 then table.insert(converted,t)end end
    self.pendingWater,self.pendingWaterOrder=nil,nil
    if #converted>0 then
        local finder=self:waterFinder();local grid={terrain=self.w.sim.tb,width=self.w.map.meta.width,height=self.w.map.meta.height}
        self.waterTerrain=self.waterTerrain or WaterTerrain.new(grid,self:mini()or grid)
        local changed,miniChanged=self.waterTerrain:convert(converted)
        self.w.convertedLandTiles=(self.w.convertedLandTiles or 0)+#converted
        for _,t in ipairs(converted)do if self.w.sim.fallout[t]then self.w.sim.fallout[t]=nil;self.w.sim.falloutRevision=(self.w.sim.falloutRevision or 0)+1;self.w.sim.onFalloutCleared(t)end end
        local system=self.w.unitSystem
        for _,t in ipairs(changed)do if system then system.terrainChanges[t]=buffer.readu8(self.w.sim.tb,t)end end
        if system then system.terrainRevision+=1 end
        self:invalidate()
        if #miniChanged>0 then
            finder.hpa.cc:add(finder.grid,miniChanged)
            self.dirtyMini=self.dirtyMini or {};self.dirtyMiniSet=self.dirtyMiniSet or {}
            for _,t in ipairs(miniChanged)do if not self.dirtyMiniSet[t]then self.dirtyMiniSet[t]=true;table.insert(self.dirtyMini,t)end end
        end
    elseif self.dirtyMini and tick-(self.lastWaterRebuild or 0)>=20 then
        self.waterPath:rebuild(self.dirtyMini);self.dirtyMini,self.dirtyMiniSet=nil,nil;self.lastWaterRebuild=tick
    end
end
function M:waterGraphVersion()return self.waterPath and self.waterPath.graphVersion or 0 end
local function labels(self)
    local b=self.compBuf
    if not b then
        b=buffer.create(self.w.map.meta.width*self.w.map.meta.height*4);self.compBuf=b
        self.components=setmetatable({},{__index=function(_,t) local v=buffer.readu32(b,t*4);if v~=0 then return v end;return nil end})
    end
    return b
end
function M:component(t)
    if not self:water(t) then for _,n in ipairs(self.w.sim:neighbors(t)) do if self:water(n) then return self:component(n) end end;return nil end
    local comps=labels(self);local known=buffer.readu32(comps,t*4)
    if known~=0 then return known end
    self.nextComponent+=1;local id=self.nextComponent;buffer.writeu32(comps,t*4,id)
    local sim=self.w.sim;local tb,terrain=sim.tb,sim.terrain
    local width=self.w.map.meta.width;local last=(self.w.map.meta.height-1)*width
    local readu32,writeu32,readu8,band=buffer.readu32,buffer.writeu32,buffer.readu8,bit32.band
    local stack,top={t},1
    local function add(n)
        if readu32(comps,n*4)~=0 then return end
        local b=if tb then readu8(tb,n) else terrain[n+1]
        if band(b,128)==0 then writeu32(comps,n*4,id);top+=1;stack[top]=n end
    end
    while top>0 do
        local u=stack[top];stack[top]=nil;top-=1;local x=u%width
        if u>=width then add(u-width) end
        if u<last then add(u+width) end
        if x~=0 then add(u-1) end
        if x~=width-1 then add(u+1) end
    end
    return id
end
function M:touches(t,component)
    if self:water(t) then return self:component(t)==component end
    for _,n in ipairs(self.w.sim:neighbors(t)) do if self:water(n) and self:component(n)==component then return true end end;return false
end
function M:shores(owner)
    local p=self.w.sim.players[owner];if not p then return {} end
    local cached=self.shoreCache[owner];local border=p.border
    local revision=border.revision or self.w.sim.ownerChanges
    if revision~=nil and cached and cached.tick==self.w.sim.ticks and cached.count==p.tiles.size and cached.border==border and cached.revision==revision then return cached.tiles end
    local out={};p.border:forEach(function(t) if self:shore(t) then table.insert(out,t) end end)
    self.shoreCache[owner]={tick=self.w.sim.ticks,count=p.tiles.size,border=border,revision=revision,tiles=out};return out
end
function M:nearest(center,radius,predicate)
    local best,distance=nil,math.huge
    self.w:flood(center,function(t)
        local d=self:manhattan(center,t);if d>radius then return false end
        if d<distance and predicate(t) then best=t;distance=d end;return true
    end)
    return best
end
function M:landing(owner,target)
    local reachable={};for _,t in ipairs(self:shores(owner)) do local c=self:component(t);if c then reachable[c]=true end end
    if next(reachable)==nil then return nil end
    local targetOwner=self.w.sim:owner(target)
    local predicate=function(t) return self.w.sim:owner(t)==targetOwner and self:shore(t) and reachable[self:component(t)]==true end
    if predicate(target) then return target end
    return self:nearest(target,50,predicate)
end
local band=bit32.band
local function search(self,starts,target,land,maxLength)
    local width,height=self.w.map.meta.width,self.w.map.meta.height
    local terrain=self.w.sim.terrain
    local tb,readu8=self.w.sim.tb,buffer.readu8
    local tx,ty=target%width,target//width
    local weight=land=="rail" and 2 or 1
    local hf,hs={},{};local size=0;local serial=0
    local n=width*height;local scratch=M.scratch
    if not scratch or scratch.n<n then scratch={n=n,gen=0,stamp=buffer.create(n*4),cost=buffer.create(n*4),from=buffer.create(n*4)};M.scratch=scratch end
    scratch.gen+=1;if scratch.gen>=2^31-1 then buffer.fill(scratch.stamp,0,0);scratch.gen=1 end
    local gen,stamp,costs,from=scratch.gen,scratch.stamp,scratch.cost,scratch.from
    local reached,closedMark=gen*2,gen*2+1
    local readu32,writeu32,readi32,writei32=buffer.readu32,buffer.writeu32,buffer.readi32,buffer.writei32
    local function setG(t,cost,p) if readu32(stamp,t*4)~=closedMark then writeu32(stamp,t*4,reached) end;writeu32(costs,t*4,cost);writei32(from,t*4,p) end
    local function parentOf(t) local p=readi32(from,t*4);if p<0 then return false end;return p end
    local SHIFT=67108864
    local hk,ht=hf,hs
    local function h(t) return (math.abs(t%width-tx)+math.abs(t//width-ty))*weight end
    local function push(t,cost)
        serial+=1;local key=(cost+h(t))*SHIFT+serial;local i=size+1;size=i
        while i>1 do
            local p=i//2;local pk=hk[p]
            if pk<key then break end
            hk[i],ht[i]=pk,ht[p];i=p
        end
        hk[i],ht[i]=key,t
    end
    local function pop()
        local key,t=hk[1],ht[1]
        local lk,lt=hk[size],ht[size];size-=1
        if size>0 then
            local i=1
            while i*2<=size do
                local c=i*2
                if c<size and hk[c+1]<hk[c] then c+=1 end
                local ck=hk[c];if not(ck<lk) then break end
                hk[i],ht[i]=ck,ht[c];i=c
            end
            hk[i],ht[i]=lk,lt
        end
        return t,key//SHIFT-h(t)
    end
    local component=not land and self:component(target) or nil
    for _,t in ipairs(starts) do if self:valid(t) and (land or component and self:touches(t,component)) then setG(t,0,-1);push(t,0) end end
    local rail=land=="rail";local last=(height-1)*width
    if not land and tb then
        while size>0 do
            local t,cost=pop();if readu32(stamp,t*4)==closedMark then continue end;writeu32(stamp,t*4,closedMark)
            if t==target then local out={};repeat table.insert(out,t);t=parentOf(t) until t==false;local reversed=table.create(#out);for i=#out,1,-1 do table.insert(reversed,out[i]) end;return reversed end
            local x=t%width;local next=cost+1
            if maxLength and next>maxLength then continue end
            for k=1,4 do
                local n
                if k==1 then if t<width then continue end;n=t-width
                elseif k==2 then if t>=last then continue end;n=t+width
                elseif k==3 then if x==0 then continue end;n=t-1
                else if x==width-1 then continue end;n=t+1 end
                local o=n*4;local mark=readu32(stamp,o)
                if mark==closedMark then continue end
                if band(readu8(tb,n),128)~=0 and n~=target then continue end
                if mark<reached or next<readu32(costs,o) then
                    writeu32(stamp,o,reached);writeu32(costs,o,next);writei32(from,o,t)
                    serial+=1;local nx=n%width
                    local key=(next+(math.abs(nx-tx)+math.abs((n-nx)//width-ty))*weight)*SHIFT+serial
                    local i=size+1;size=i
                    while i>1 do
                        local p=i//2;local pk=hk[p]
                        if pk<key then break end
                        hk[i],ht[i]=pk,ht[p];i=p
                    end
                    hk[i],ht[i]=key,n
                end
            end
        end
        return nil
    end
    local function visit(t,n,byte,cost0)
        if readu32(stamp,n*4)==closedMark then return end
        local nb=if tb then readu8(tb,n) else terrain[n+1];local nLand=band(nb,128)~=0
        local pass
        if rail then
            local shoreFrom=band(byte,64)~=0;local shoreTo=band(nb,64)~=0
            pass=not(band(byte,128)~=0 and band(byte,31)==31) and (nLand and band(nb,31)~=31 or shoreFrom or shoreTo)
            if not pass then return end
            local increment=1
            if not nLand or shoreTo then increment=6 end;local p=parentOf(t);if p and t-p~=n-t then increment+=3 end
            local cost=cost0+increment;if maxLength and cost+math.abs(n%width-tx)+math.abs(n//width-ty)>maxLength then return end
            if readu32(stamp,n*4)<reached or cost<readu32(costs,n*4) then setG(n,cost,t);push(n,cost) end
            return
        elseif land==true then pass=nLand and band(nb,31)~=31
        else pass=not nLand or n==target end
        if not pass then return end
        local cost=cost0+1;if maxLength and cost+math.abs(n%width-tx)+math.abs(n//width-ty)>maxLength then return end
        if readu32(stamp,n*4)<reached or cost<readu32(costs,n*4) then setG(n,cost,t);push(n,cost) end
    end
    while size>0 do
        local t,cost=pop();if readu32(stamp,t*4)==closedMark then continue end;writeu32(stamp,t*4,closedMark)
        if t==target then local out={};repeat table.insert(out,t);t=parentOf(t) until t==false;local reversed=table.create(#out);for i=#out,1,-1 do table.insert(reversed,out[i]) end;return reversed end
        local byte=if tb then readu8(tb,t) else terrain[t+1]
        if t>=width then visit(t,t-width,byte,cost) end
        if t<last then visit(t,t+width,byte,cost) end
        local x=t%width
        if x~=0 then visit(t,t-1,byte,cost) end
        if x~=width-1 then visit(t,t+1,byte,cost) end
    end
    return nil
end
M.search=search
M.upstreamWater=true
M.upstreamRail=true
M.cacheLimit=256
function M:path(starts,target,land,maxLength)
    if not self:valid(target) then return nil end
    local single=type(starts)=="number"
    if single then starts={starts} end
    if #starts==0 then return nil end
    if land==nil and M.upstreamWater and self.w.sim.tb then
        local ok={};for _,t in ipairs(starts)do if self:valid(t)then table.insert(ok,t)end end
        if #ok==0 then return nil end
        if table.find(ok,target) then return {target} end
        local wp=self:waterFinder()
        local path=wp:findPath(if single then ok[1] else ok,target,single)
        if path and maxLength and #path-1>maxLength then return nil end
        return path
    end
    if land=="rail" and M.upstreamRail and single and self.w.sim.tb then
        local rp=self.railPath
        if not rp then local m=self.w.map;rp=RailPath.new(self.w.sim.tb,m.meta.width,m.meta.height,self:mini());self.railPath=rp end
        if starts[1]==target then return {target} end
        return rp:findPath(starts[1],target,maxLength)
    end
    if not single then return search(self,starts,target,land,maxLength) end
    local key=starts[1]..":"..target..":"..tostring(land)..":"..tostring(maxLength)
    local cache=self.pathCache;if not cache then cache={entries={},count=0};self.pathCache=cache end
    local hit=cache.entries[key]
    if hit==nil then
        hit=search(self,starts,target,land,maxLength) or false
        if cache.count>=M.cacheLimit then table.clear(cache.entries);cache.count=0 end
        cache.entries[key]=hit;cache.count+=1
    end
    return hit and table.clone(hit) or nil
end
function M:mini()
    if self.miniMap~=nil then return self.miniMap or nil end
    local m=self.w.map;local mini=m.mini
    if not mini and m.meta.mini then
        local Maps=if script then require(script.Parent.Parent.Maps.MapLoader) else require("../maps/MapLoader")
        mini={terrain=Maps.loadMini(m.meta),width=m.meta.mini.width,height=m.meta.mini.height}
    end
    self.miniMap=mini or false;return mini
end
function M:transport(owner,target)
    if not self:valid(target) then return nil end
    local dst=self:landing(owner,target);if not dst then return nil end
    local path=self:path(self:shores(owner),dst);return path,dst
end
return M
