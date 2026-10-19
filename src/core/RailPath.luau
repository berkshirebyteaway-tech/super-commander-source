--!native
local WaterPath=if script then require(script.Parent.WaterPath) else require("./WaterPath")
local M={};M.__index=M
local band=bit32.band
local readu8,readu32,writeu32,readi32,writei32=buffer.readu8,buffer.readu32,buffer.writeu32,buffer.readi32,buffer.writei32
local LAND,SHORE,MAG=128,64,31
local WATER_PENALTY,WEIGHT,TURN=5,2,3

function M.new(terrain:buffer,width:number,height:number,mini)
    local g=mini or {terrain=terrain,width=width,height=height}
    local n=g.width*g.height
    local maxBucket=WEIGHT*(g.width+g.height)*(1+WATER_PENALTY+TURN)+1
    return setmetatable({width=width,height=height,scale=mini and 2 or 1,terrain=g.terrain,gw=g.width,gh=g.height,n=n,stamp=0,
        closed=buffer.create(n*4),gStamp=buffer.create(n*4),gScore=buffer.create(n*4),cameFrom=buffer.create(n*4),
        maxBucket=maxBucket,buckets={},bucketSizes=buffer.create(maxBucket*4),bucketStamp=buffer.create(maxBucket*4),qStamp=0},M)
end

local function search(self,starts,goal,bound)
    local terrain,width,numNodes=self.terrain,self.gw,self.n
    self.stamp+=1;if self.stamp>=2^32-1 then buffer.fill(self.closed,0,0);buffer.fill(self.gStamp,0,0);self.stamp=1 end
    local stamp,closed,gStamp,gScore,cameFrom=self.stamp,self.closed,self.gStamp,self.gScore,self.cameFrom
    self.qStamp+=1;if self.qStamp>=2^32-1 then buffer.fill(self.bucketStamp,0,0);self.qStamp=1 end
    local qs,buckets,sizes,bstamp,maxBucket=self.qStamp,self.buckets,self.bucketSizes,self.bucketStamp,self.maxBucket
    local minBucket,size=maxBucket,0
    local function push(node,priority)
        local b=math.min(priority//1,maxBucket-1)
        local list=buckets[b];if not list then list={};buckets[b]=list end
        local n=if readu32(bstamp,b*4)==qs then readu32(sizes,b*4) else 0
        list[n+1]=node;writeu32(sizes,b*4,n+1);writeu32(bstamp,b*4,qs);size+=1
        if b<minBucket then minBucket=b end
    end
    local function pop()
        while minBucket<maxBucket do
            if readu32(bstamp,minBucket*4)==qs then
                local n=readu32(sizes,minBucket*4)
                if n>0 then writeu32(sizes,minBucket*4,n-1);size-=1;return buckets[minBucket][n] end
            end
            minBucket+=1
        end
        return -1
    end
    local gx,gy=goal%width,goal//width
    local function h(t) return WEIGHT*(math.abs(t%width-gx)+math.abs(t//width-gy)) end
    for _,s in ipairs(starts)do writeu32(gScore,s*4,0);writeu32(gStamp,s*4,stamp);writei32(cameFrom,s*4,-1);push(s,h(s))end
    local iterations=500000
    while size>0 do
        iterations-=1;if iterations<=0 then return nil end
        local current=pop()
        if readu32(closed,current*4)==stamp then continue end
        writeu32(closed,current*4,stamp)
        if current==goal then
            local out={};local c=goal;while c~=-1 do table.insert(out,c);c=readi32(cameFrom,c*4)end
            local n=#out;for i=1,n//2 do out[i],out[n+1-i]=out[n+1-i],out[i]end
            return out
        end
        local byte=readu8(terrain,current)
        if band(byte,LAND)~=0 and band(byte,MAG)==31 then continue end
        local fromShore=band(byte,SHORE)~=0
        local currentG=readu32(gScore,current*4);local prev=readi32(cameFrom,current*4);local x=current%width
        for k=1,4 do
            local nb
            if k==1 then if current<width then continue end;nb=current-width
            elseif k==2 then if current>=numNodes-width then continue end;nb=current+width
            elseif k==3 then if x==0 then continue end;nb=current-1
            else if x==width-1 then continue end;nb=current+1 end
            local nt=readu8(terrain,nb);local toWater=band(nt,LAND)==0;local toShore=band(nt,SHORE)~=0
            if toWater and not(fromShore or toShore) then continue end
            if readu32(closed,nb*4)==stamp then continue end
            local c=if toWater or toShore then 1+WATER_PENALTY else 1
            if prev~=-1 and current-prev~=nb-current then c+=TURN end
            local tentative=currentG+c
            if bound and tentative+math.abs(nb%width-gx)+math.abs(nb//width-gy)>bound then continue end
            if readu32(gStamp,nb*4)~=stamp or tentative<readu32(gScore,nb*4) then
                writei32(cameFrom,nb*4,current);writeu32(gScore,nb*4,tentative);writeu32(gStamp,nb*4,stamp)
                push(nb,tentative+h(nb))
            end
        end
    end
    return nil
end

function M:findPath(from:number,to:number,bound:number?)
    if self.scale==1 then return search(self,{from},to,bound)end
    local b=bound and bound/2 or nil
    return WaterPath.viaMini(self.width,self.gw,{from},to,function(f,t) return search(self,f,t,b) end)
end
return M
