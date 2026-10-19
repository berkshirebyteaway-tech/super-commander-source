--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local M={}
local r32,w32,ri,wi,rf,wf=buffer.readu32,buffer.writeu32,buffer.readi32,buffer.writei32,buffer.readf32,buffer.writef32
local Heap={};Heap.__index=Heap
function M.heap(capacity)
    capacity=math.max(16,capacity or 256)
    return setmetatable({size=0,capacity=capacity,nodes=buffer.create(capacity*4),pri=buffer.create(capacity*4)},Heap)
end
function Heap:push(node,priority)
    if self.size==self.capacity then
        local cap=self.capacity*2;local n,p=buffer.create(cap*4),buffer.create(cap*4)
        buffer.copy(n,0,self.nodes);buffer.copy(p,0,self.pri);self.capacity,self.nodes,self.pri=cap,n,p
    end
    local n,p=self.nodes,self.pri;local i=self.size;self.size+=1
    wf(p,i*4,priority);priority=rf(p,i*4)
    while i>0 do local parent=(i-1)//2;local pp=rf(p,parent*4);if pp<=priority then break end
        wi(n,i*4,ri(n,parent*4));wf(p,i*4,pp);i=parent
    end
    wi(n,i*4,node);wf(p,i*4,priority)
end
function Heap:pop()
    local n,p=self.nodes,self.pri;local result=ri(n,0);self.size-=1
    if self.size>0 then
        local node,priority=ri(n,self.size*4),rf(p,self.size*4);local i=0
        while true do
            local l=i*2+1;if l>=self.size then break end
            local j,jp=l,rf(p,l*4);local right=l+1
            if right<self.size and rf(p,right*4)<jp then j,jp=right,rf(p,right*4) end
            if not(jp<priority)then break end
            wi(n,i*4,ri(n,j*4));wf(p,i*4,jp);i=j
        end
        wi(n,i*4,node);wf(p,i*4,priority)
    end
    return result
end
function M.neighbors(g,t,visit)
    local w=g.width;local x=t%w
    if t>=w then visit(t-w)end
    if t<(g.height-1)*w then visit(t+w)end
    if x>0 then visit(t-1)end
    if x<w-1 then visit(t+1)end
end
function M.water(g,t) return bit32.band(buffer.readu8(g.terrain,t),128)==0 end
function M.distance(g,a,b) return math.abs(a%g.width-b%g.width)+math.abs(a//g.width-b//g.width)end
function M.bfsScratch(n) return {stamp=0,seen=buffer.create(n*4),queue=buffer.create(n*4),dist=buffer.create(n*2)} end
function M.bfs(g,s,from,maxDistance,visitor)
    s.stamp+=1;if s.stamp>=2^32 then buffer.fill(s.seen,0,0);s.stamp=1 end
    local stamp=s.stamp;local q,d,v=s.queue,s.dist,s.seen;local head,tail=0,1
    wi(q,0,from);buffer.writeu16(d,from*2,0);w32(v,from*4,stamp)
    local function add(t,dist)
        if r32(v,t*4)==stamp or not M.water(g,t)then return end
        w32(v,t*4,stamp);buffer.writeu16(d,t*2,dist);wi(q,tail*4,t);tail+=1
    end
    while head<tail do
        local t=ri(q,head*4);head+=1;local dist=buffer.readu16(d,t*2);local result=visitor(t,dist)
        if result~=nil and result~=false then return result end
        if result==false or dist+1>maxDistance then continue end
        local nd=dist+1;local w=g.width;local x=t%w
        if t>=w then add(t-w,nd)end;if t<(g.height-1)*w then add(t+w,nd)end
        if x>0 then add(t-1,nd)end;if x<w-1 then add(t+1,nd)end
    end
    return nil
end
function M.scratch(capacity)
    return {capacity=capacity,stamp=0,closed=buffer.create(capacity*4),seen=buffer.create(capacity*4),
        cost=buffer.create(capacity*4),parent=buffer.create(capacity*4),heap=M.heap()}
end
function M.bounded(g,s,starts,goal,minX,maxX,minY,maxY)
    if type(starts)=='number'then starts={starts}end;if #starts==0 then return nil end
    local bw,bh=maxX-minX+1,maxY-minY+1;local n=bw*bh
    if n<=0 or n>s.capacity then return nil end
    s.stamp+=1;if s.stamp>=2^32 then buffer.fill(s.closed,0,0);buffer.fill(s.seen,0,0);s.stamp=1 end
    local stamp,closed,seen,cost,parent,heap=s.stamp,s.closed,s.seen,s.cost,s.parent,s.heap;heap.size=0
    local W=g.width;local gx,gy=goal%W,goal//W;local dx,dy=gx-starts[1]%W,gy-starts[1]//W
    local norm=math.max(1,math.abs(dx)+math.abs(dy))
    local function toLocal(t) return (math.clamp(t//W,minY,maxY)-minY)*bw+math.clamp(t%W,minX,maxX)-minX end
    local goalLocal=toLocal(goal)
    for _,t in ipairs(starts)do local l=toLocal(t);w32(cost,l*4,0);w32(seen,l*4,stamp);wi(parent,l*4,-1)
        heap:push(l,300*(math.abs(t%W-gx)+math.abs(t//W-gy)))
    end
    local iterations=100000
    while heap.size>0 do
        iterations-=1;if iterations<=0 then return nil end
        local c=heap:pop();if r32(closed,c*4)==stamp then continue end;w32(closed,c*4,stamp)
        if c==goalLocal then
            local out={};repeat
                if c<0 or c>=n or #out>n then return nil end
                table.insert(out,(c//bw+minY)*W+c%bw+minX);c=ri(parent,c*4)
            until c==-1
            for i=1,#out//2 do out[i],out[#out+1-i]=out[#out+1-i],out[i]end;return out
        end
        local cx,cy=c%bw,c//bw;local cg=r32(cost,c*4)
        for direction=1,4 do
            local l,nx,ny
            if direction==1 then if cy==0 then continue end;l,nx,ny=c-bw,cx+minX,cy+minY-1
            elseif direction==2 then if cy==bh-1 then continue end;l,nx,ny=c+bw,cx+minX,cy+minY+1
            elseif direction==3 then if cx==0 then continue end;l,nx,ny=c-1,cx+minX-1,cy+minY
            else if cx==bw-1 then continue end;l,nx,ny=c+1,cx+minX+1,cy+minY end
            if r32(closed,l*4)==stamp then continue end
            local tile=ny*W+nx;local byte=buffer.readu8(g.terrain,tile)
            if tile~=goal and bit32.band(byte,128)~=0 then continue end
            local mag=bit32.band(byte,31);local ng=cg+100+(if mag<3 then 300 elseif mag<=10 then 0 else 100)
            if r32(seen,l*4)~=stamp or ng<r32(cost,l*4)then
                w32(seen,l*4,stamp);w32(cost,l*4,ng);wi(parent,l*4,c)
                heap:push(l,ng+300*(math.abs(nx-gx)+math.abs(ny-gy))+math.floor(math.abs(dx*(ny-gy)-dy*(nx-gx))*99/norm/norm))
            end
        end
    end
    return nil
end
return M
