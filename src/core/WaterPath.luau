--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local M={};M.__index=M
local HPA=if script then require(script.Parent.WaterHPA)else require('./WaterHPA')
local Smoothing=if script then require(script.Parent.WaterSmoothing)else require('./WaterSmoothing')
local band=bit32.band
local readu8,readu32,writeu32,readi32,writei32=buffer.readu8,buffer.readu32,buffer.writeu32,buffer.readi32,buffer.writei32
local readf32,writef32=buffer.readf32,buffer.writef32

local COST_SCALE=100;local BASE_COST=COST_SCALE
local LAND=128;local MAG=31

local function astar(self,starts,goal)
    local g=self.grid;local width,numNodes,terrain=g.width,g.n,g.terrain
    if not g.closed then
        g.closed=buffer.create(numNodes*4);g.gStamp=buffer.create(numNodes*4)
        g.gScore=buffer.create(numNodes*4);g.cameFrom=buffer.create(numNodes*4)
    end
    g.stamp+=1;if g.stamp>=2^32-1 then buffer.fill(g.closed,0,0);buffer.fill(g.gStamp,0,0);g.stamp=1 end
    local stamp,closed,gStamp,gScore,cameFrom=g.stamp,g.closed,g.gStamp,g.gScore,g.cameFrom
    local heap,pri=g.heap,g.pri;local size=0
    local weight=5
    local goalX,goalY=goal%width,goal//width
    local s0=starts[1];local dxGoal,dyGoal=goalX-s0%width,goalY-s0//width
    local crossNorm=math.max(1,math.abs(dxGoal)+math.abs(dyGoal))
    for _,s in ipairs(starts)do
        writeu32(gScore,s*4,0);writeu32(gStamp,s*4,stamp);writei32(cameFrom,s*4,-1)
        do local node,p=s,weight*BASE_COST*(math.abs(s%width-goalX)+math.abs(s//width-goalY))
            if size==g.heapCapacity then
                local capacity=g.heapCapacity*2;local nextHeap,nextPri=buffer.create(capacity*4),buffer.create(capacity*4)
                buffer.copy(nextHeap,0,heap);buffer.copy(nextPri,0,pri);heap,pri=nextHeap,nextPri
                g.heap,g.pri,g.heapCapacity=heap,pri,capacity
            end
            local i=size;local slot=i;size+=1
            writef32(pri,i*4,p);local pi=readf32(pri,i*4)
            while i>0 do
                local parent=(i-1)//2;local pp=readf32(pri,parent*4)
                if pp<=pi then break end
                writei32(heap,i*4,readi32(heap,parent*4));writef32(pri,i*4,pp)
                i=parent
            end
            writei32(heap,i*4,node);if i~=slot then writef32(pri,i*4,pi)end
        end
    end
    local iterations=1000000
    while size>0 do
        iterations-=1;if iterations<=0 then return nil end
        local current
        do
            local result=readi32(heap,0);size-=1
            if size>0 then
                local node,p=readi32(heap,size*4),readf32(pri,size*4)
                local i=0
                while true do
                    local left=i*2+1;if left>=size then break end
                    local right=left+1;local smallest,sp=left,readf32(pri,left*4)
                    if right<size then local rp=readf32(pri,right*4);if rp<sp then smallest,sp=right,rp end end
                    if not(sp<p)then break end
                    writei32(heap,i*4,readi32(heap,smallest*4));writef32(pri,i*4,sp)
                    i=smallest
                end
                writei32(heap,i*4,node);writef32(pri,i*4,p)
            end
            current=result
        end
        if readu32(closed,current*4)==stamp then continue end
        writeu32(closed,current*4,stamp)
        if current==goal then
            local out={};local c=goal;while c~=-1 do table.insert(out,c);c=readi32(cameFrom,c*4)end
            local n=#out;for i=1,n//2 do out[i],out[n+1-i]=out[n+1-i],out[i]end
            return out
        end
        local currentG=readu32(gScore,current*4);local cx,cy=current%width,current//width
        for k=1,4 do
            local neighbor,nx,ny
            if k==1 then if current<width then continue end;neighbor,nx,ny=current-width,cx,cy-1
            elseif k==2 then if current>=numNodes-width then continue end;neighbor,nx,ny=current+width,cx,cy+1
            elseif k==3 then if cx==0 then continue end;neighbor,nx,ny=current-1,cx-1,cy
            else if cx==width-1 then continue end;neighbor,nx,ny=current+1,cx+1,cy end
            if readu32(closed,neighbor*4)==stamp then continue end
            local nt=readu8(terrain,neighbor)
            if neighbor==goal or band(nt,LAND)==0 then
                local magnitude=band(nt,MAG)
                local cost=BASE_COST+(if magnitude<3 then 10*COST_SCALE elseif magnitude<=10 then 0 else COST_SCALE)
                local tentative=currentG+cost
                if readu32(gStamp,neighbor*4)~=stamp or tentative<readu32(gScore,neighbor*4) then
                    writei32(cameFrom,neighbor*4,current);writeu32(gScore,neighbor*4,tentative);writeu32(gStamp,neighbor*4,stamp)
                    local h=weight*BASE_COST*(math.abs(nx-goalX)+math.abs(ny-goalY))
                    local cross=math.abs(dxGoal*(ny-goalY)-dyGoal*(nx-goalX))
                    do local node,p=neighbor,tentative+h+math.floor(cross*(COST_SCALE-1)/crossNorm/crossNorm)
                        if size==g.heapCapacity then
                            local capacity=g.heapCapacity*2;local nextHeap,nextPri=buffer.create(capacity*4),buffer.create(capacity*4)
                            buffer.copy(nextHeap,0,heap);buffer.copy(nextPri,0,pri);heap,pri=nextHeap,nextPri
                            g.heap,g.pri,g.heapCapacity=heap,pri,capacity
                        end
                        local i=size;local slot=i;size+=1
                        writef32(pri,i*4,p);local pi=readf32(pri,i*4)
                        while i>0 do
                            local parent=(i-1)//2;local pp=readf32(pri,parent*4)
                            if pp<=pi then break end
                            writei32(heap,i*4,readi32(heap,parent*4));writef32(pri,i*4,pp)
                            i=parent
                        end
                        writei32(heap,i*4,node);if i~=slot then writef32(pri,i*4,pi)end
                    end
                end
            end
        end
    end
    return nil
end

local function isWater(g,t) return band(readu8(g.terrain,t),LAND)==0 end
local function neighbors4(g,t)
    local w=g.width;local out={};local x=t%w
    if t>=w then table.insert(out,t-w)end
    if t<(g.height-1)*w then table.insert(out,t+w)end
    if x~=0 then table.insert(out,t-1)end
    if x~=w-1 then table.insert(out,t+1)end
    return out
end
local function bestWaterNeighbor(g,tile)
    local best,maxScore=-1,-1
    for _,n in ipairs(neighbors4(g,tile))do
        if not isWater(g,n)then continue end
        local score=0;for _,m in ipairs(neighbors4(g,n))do if isWater(g,m)then score+=1 end end
        if score>maxScore then maxScore=score;best=n end
    end
    return best
end
local function shoreCoerced(self,from,to)
    local g=self.grid;local waterToOriginal={};local waterFrom={}
    for _,f in ipairs(from)do
        if isWater(g,f)then table.insert(waterFrom,f);waterToOriginal[f]=nil
        else local w=bestWaterNeighbor(g,f);if w~=-1 then table.insert(waterFrom,w);waterToOriginal[w]=f end end
    end
    if #waterFrom==0 then return nil end
    local waterTo,originalTo=to,-1
    if not isWater(g,to)then waterTo=bestWaterNeighbor(g,to);if waterTo==-1 then return nil end;originalTo=to end
    local path
    if #self.hpa.graph.nodes>=100 then path=self.smoothing:smooth(self.hpa:findPath(waterFrom,waterTo))
    else path=astar(self,waterFrom,waterTo)end
    if not path or #path==0 then return nil end
    local shore=waterToOriginal[path[1]];if shore~=nil then table.insert(path,1,shore)end
    if originalTo~=-1 and path[#path]~=originalTo then table.insert(path,originalTo)end
    return path
end

local function viaMini(W,mw,from,to,search)
    local miniFrom={};for i,f in ipairs(from)do miniFrom[i]=(f//W//2)*mw+(f%W)//2 end
    local miniTo=(to//W//2)*mw+(to%W)//2
    local path=search(miniFrom,miniTo)
    if not path or #path==0 then return nil end
    local up={}
    for i=1,#path-1 do
        local cx,cy=path[i]%mw*2,path[i]//mw*2;local nx,ny=path[i+1]%mw*2,path[i+1]//mw*2
        table.insert(up,cy*W+cx)
        local dx,dy=nx-cx,ny-cy;local steps=math.max(math.abs(dx),math.abs(dy))
        for step=1,steps-1 do
            local x=math.floor(cx+dx*step/steps+.5);local y=math.floor(cy+dy*step/steps+.5)
            table.insert(up,y*W+x)
        end
    end
    local last=path[#path];table.insert(up,(last//mw*2)*W+last%mw*2)
    local src
    if #from>1 then
        local sx,sy=up[1]%W,up[1]//W;local minDist=math.huge
        for _,f in ipairs(from)do local d=math.abs(f%W-sx)+math.abs(f//W-sy);if d<minDist then minDist=d;src=f end end
    else src=from[1] end
    if src~=nil then
        local idx=table.find(up,src)
        if not idx then table.insert(up,1,src)elseif idx~=1 then up=table.move(up,idx,#up,1,{})end
    end
    local di=table.find(up,to)
    if not di then table.insert(up,to)elseif di~=#up then up=table.move(up,1,di,1,{})end
    return up
end
M.viaMini=viaMini
local function find(self,from,to)
    if self.scale==1 then return shoreCoerced(self,from,to)end
    return viaMini(self.width,self.grid.width,from,to,function(f,t) return shoreCoerced(self,f,t) end)
end

function M.new(terrain:buffer,width:number,height:number,mini,options)
    local g=mini or {terrain=terrain,width=width,height=height}
    local n=g.width*g.height
    local grid={terrain=g.terrain,width=g.width,height=g.height,n=n,stamp=0,
        heap=buffer.create(4096*4),pri=buffer.create(4096*4),heapCapacity=4096}
    local hpa=if options and options.simpleOnly then {graph={nodes={}}}else HPA.new(grid)
    return setmetatable({width=width,height=height,grid=grid,scale=mini and 2 or 1,hpa=hpa,smoothing=Smoothing.new(grid),
        graphVersion=0,memo={},memoLinks={},memoBytes=0,memoEntries=0},M)
end
M.memoBudget=24000000
local function touch(self,key)
    local links=self.memoLinks;local link=links[key]
    if link then
        if self.memoTail==key then return end
        if link.previous~=nil then links[link.previous].next=link.next else self.memoHead=link.next end
        if link.next~=nil then links[link.next].previous=link.previous end
    else link={};links[key]=link;self.memoEntries+=1 end
    link.previous=self.memoTail;link.next=nil
    if self.memoTail~=nil then links[self.memoTail].next=key else self.memoHead=key end
    self.memoTail=key
end
function M:findPath(from,to:number,memoized:boolean?)
    local single=type(from)=="number"
    if not(memoized and single)then return find(self,if single then {from}else from,to)end
    local key=from*self.width*self.height+to;local hit=self.memo[key]
    if hit~=nil then
        touch(self,key)
        return if hit then table.clone(hit)else nil
    end
    local path=find(self,{from},to)
    self.memo[key]=path or false;touch(self,key)
    self.memoBytes+=if path then #path*4 else 16
    while self.memoBytes>M.memoBudget and self.memoHead~=nil do
        local oldest=self.memoHead;local link=self.memoLinks[oldest];self.memoHead=link.next
        if self.memoHead~=nil then self.memoLinks[self.memoHead].previous=nil else self.memoTail=nil end
        local p=self.memo[oldest];self.memoBytes-=if p then #p*4 else 16
        self.memo[oldest]=nil;self.memoLinks[oldest]=nil;self.memoEntries-=1
    end
    return if path then table.clone(path)else nil
end
function M:clear() self.memo={};self.memoLinks={};self.memoHead=nil;self.memoTail=nil;self.memoBytes=0;self.memoEntries=0 end
function M:rebuild(dirty)self.hpa:rebuild(dirty);self.graphVersion+=1;self:clear()end
return M
