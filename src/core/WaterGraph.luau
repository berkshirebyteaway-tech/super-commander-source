--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local S=if script then require(script.Parent.WaterSearch)else require('./WaterSearch')
local M={};M.clusterSize=32
local CC={};CC.__index=CC
function CC:root(id)
    if id==0 then return 0 end
    local root=id;while self.parents[root]~=root do root=self.parents[root]end
    while self.parents[id]~=root do local nextID=self.parents[id];self.parents[id]=root;id=nextID end;return root
end
function CC:get(t) return self:root(buffer.readu32(self.ids,t*4))end
function M.components(g)
    local cc=setmetatable({ids=buffer.create(g.width*g.height*4),parents={},sizes={},maxID=0},CC)
    local w,h,terrain=g.width,g.height,g.terrain;local lastRow=(h-1)*w
    local ids=cc.ids;local queue=buffer.create(w*h*4)
    for t=0,w*h-1 do
        if bit32.band(buffer.readu8(terrain,t),128)~=0 or buffer.readu32(ids,t*4)~=0 then continue end
        cc.maxID+=1;local id=cc.maxID;cc.parents[id]=id
        buffer.writeu32(queue,0,t);buffer.writeu32(ids,t*4,id);local head,tail=0,1
        while head<tail do
            local u=buffer.readu32(queue,head*4);head+=1;local x=u%w
            if u>=w then
                local n=u-w
                if bit32.band(buffer.readu8(terrain,n),128)==0 and buffer.readu32(ids,n*4)==0 then
                    buffer.writeu32(ids,n*4,id);buffer.writeu32(queue,tail*4,n);tail+=1
                end
            end
            if u<lastRow then
                local n=u+w
                if bit32.band(buffer.readu8(terrain,n),128)==0 and buffer.readu32(ids,n*4)==0 then
                    buffer.writeu32(ids,n*4,id);buffer.writeu32(queue,tail*4,n);tail+=1
                end
            end
            if x>0 then
                local n=u-1
                if bit32.band(buffer.readu8(terrain,n),128)==0 and buffer.readu32(ids,n*4)==0 then
                    buffer.writeu32(ids,n*4,id);buffer.writeu32(queue,tail*4,n);tail+=1
                end
            end
            if x<w-1 then
                local n=u+1
                if bit32.band(buffer.readu8(terrain,n),128)==0 and buffer.readu32(ids,n*4)==0 then
                    buffer.writeu32(ids,n*4,id);buffer.writeu32(queue,tail*4,n);tail+=1
                end
            end
        end
        cc.sizes[id]=head
    end
    return cc
end
function CC:add(g,tiles)
    for _,t in ipairs(tiles)do
        if buffer.readu32(self.ids,t*4)~=0 then continue end
        local roots={};local canon=0
        S.neighbors(g,t,function(n)local r=self:get(n);if r~=0 then table.insert(roots,r);if canon==0 or r<canon then canon=r end end end)
        if canon==0 then self.maxID+=1;canon=self.maxID;self.parents[canon]=canon;self.sizes[canon]=0 end
        buffer.writeu32(self.ids,t*4,canon);self.sizes[canon]=(self.sizes[canon]or 0)+1
        for _,r in ipairs(roots)do if r~=canon and self.parents[r]~=canon then self.parents[r]=canon;self.sizes[canon]+=self.sizes[r]or 0;self.sizes[r]=0 end end
    end
end
local function connect(g,s,from,maxDistance,targets,count,minX,maxX,minY,maxY,edge,a,cx,cy)
    s.stamp+=1;if s.stamp>=2^32 then buffer.fill(s.seen,0,0);s.stamp=1 end
    local stamp=s.stamp;local q,d,v=s.queue,s.dist,s.seen;local head,tail,found=0,1,0
    buffer.writei32(q,0,from);buffer.writeu16(d,from*2,0);buffer.writeu32(v,from*4,stamp)
    local w,lastRow,terrain=g.width,(g.height-1)*g.width,g.terrain
    while head<tail do
        local t=buffer.readi32(q,head*4);head+=1;local dist=buffer.readu16(d,t*2)
        local id=targets[t];local x,y=t%w,t//w
        if t~=from and id==nil and (x<minX or x>maxX or y<minY or y>maxY)then continue end
        if id~=nil then edge(a,id,dist,cx,cy);found+=1;if found==count then return end end
        if dist+1>maxDistance then continue end
        local nd=dist+1
        if t>=w then
            local n=t-w
            if buffer.readu32(v,n*4)~=stamp and bit32.band(buffer.readu8(terrain,n),128)==0 then
                buffer.writeu32(v,n*4,stamp);buffer.writeu16(d,n*2,nd);buffer.writei32(q,tail*4,n);tail+=1
            end
        end
        if t<lastRow then
            local n=t+w
            if buffer.readu32(v,n*4)~=stamp and bit32.band(buffer.readu8(terrain,n),128)==0 then
                buffer.writeu32(v,n*4,stamp);buffer.writeu16(d,n*2,nd);buffer.writei32(q,tail*4,n);tail+=1
            end
        end
        if x>0 then
            local n=t-1
            if buffer.readu32(v,n*4)~=stamp and bit32.band(buffer.readu8(terrain,n),128)==0 then
                buffer.writeu32(v,n*4,stamp);buffer.writeu16(d,n*2,nd);buffer.writei32(q,tail*4,n);tail+=1
            end
        end
        if x<w-1 then
            local n=t+1
            if buffer.readu32(v,n*4)~=stamp and bit32.band(buffer.readu8(terrain,n),128)==0 then
                buffer.writeu32(v,n*4,stamp);buffer.writeu16(d,n*2,nd);buffer.writei32(q,tail*4,n);tail+=1
            end
        end
    end
end
function M.build(g,cc,bfs,old,dirtyTiles)
    cc=cc or M.components(g);bfs=bfs or S.bfsScratch(g.width*g.height)
    local cxN,cyN=math.ceil(g.width/32),math.ceil(g.height/32)
    local graph={nodes={},edges={},adj={},clusters={},cache={},components=cc,clustersX=cxN,clustersY=cyN,clusterSize=32}
    local nodes,edges,clusters=graph.nodes,graph.edges,graph.clusters
    for i=1,cxN*cyN do clusters[i]={}end
    local tileNodes={}
    local function gateway(x,y,cx,cy,nx,ny)
        local tile=y*g.width+x;local id=tileNodes[tile]
        if id==nil then id=#nodes;tileNodes[tile]=id;nodes[id+1]={id=id,x=x,y=y,tile=tile,componentId=cc:get(tile)}end
        for _,key in ipairs({cy*cxN+cx+1,ny*cxN+nx+1})do if not table.find(clusters[key],id)then table.insert(clusters[key],id)end end
    end
    for cy=0,cyN-1 do for cx=0,cxN-1 do
        local bx,by=cx*32,cy*32
        if cx<cxN-1 then
            local x=bx+31;local maxY=math.min(by+32,g.height);local start=nil
            for y=by,maxY do local entrance=y<maxY and S.water(g,y*g.width+x)and S.water(g,y*g.width+x+1)
                if entrance then if start==nil then start=y end
                elseif start~=nil then gateway(x,start+(y-start)//2,cx,cy,cx+1,cy);start=nil end
            end
        end
        if cy<cyN-1 then
            local y=by+31;local maxX=math.min(bx+32,g.width);local start=nil
            for x=bx,maxX do local entrance=x<maxX and S.water(g,y*g.width+x)and S.water(g,(y+1)*g.width+x)
                if entrance then if start==nil then start=x end
                elseif start~=nil then gateway(start+(x-start)//2,y,cx,cy,cx,cy+1);start=nil end
            end
        end
    end end
    local edgeIndex={};local dirty,oldCosts=nil,nil
    if old and dirtyTiles and #dirtyTiles>0 then
        dirty={};oldCosts={}
        for _,t in ipairs(dirtyTiles)do local cx,cy=(t%g.width)//32,(t//g.width)//32
            for y=math.max(0,cy-1),math.min(cyN-1,cy+1)do for x=math.max(0,cx-1),math.min(cxN-1,cx+1)do dirty[y*cxN+x+1]=true end end
        end
        local N=g.width*g.height
        for _,e in ipairs(old.edges)do local a,b=old.nodes[e.nodeA+1].tile,old.nodes[e.nodeB+1].tile;local key=math.min(a,b)*N+math.max(a,b)
            if not oldCosts[key] or e.cost<oldCosts[key].cost then oldCosts[key]=e end
        end
    end
    local function edge(a,b,cost,cx,cy)
        local lo,hi=math.min(a,b),math.max(a,b);local key=lo*#nodes+hi;local e=edgeIndex[key]
        if e then if cost<e.cost then e.cost,e.clusterX,e.clusterY=cost,cx,cy end
        else e={id=#edges,nodeA=lo,nodeB=hi,cost=cost,clusterX=cx,clusterY=cy};edgeIndex[key]=e;table.insert(edges,e)end
    end
    local rebuiltClusters=0
    for cy=0,cyN-1 do for cx=0,cxN-1 do
        local key=cy*cxN+cx+1;local cluster=clusters[key];local minX,minY=cx*32,cy*32
        local maxX,maxY=math.min(g.width-1,minX+31),math.min(g.height-1,minY+31)
        if dirty and not dirty[key]then
            for i=1,#cluster do local a=nodes[cluster[i]+1]
                for j=i+1,#cluster do local b=nodes[cluster[j]+1];if a.componentId~=b.componentId then continue end
                    local e=oldCosts[math.min(a.tile,b.tile)*(g.width*g.height)+math.max(a.tile,b.tile)]
                    if e then edge(a.id,b.id,e.cost,e.clusterX,e.clusterY)end
                end
            end
            continue
        end
        if #cluster>0 then rebuiltClusters+=1 end
        for i=1,#cluster do
            local a=nodes[cluster[i]+1];local targets={};local count,maxDistance=0,0
            for j=i+1,#cluster do local b=nodes[cluster[j]+1]
                if a.componentId==b.componentId then targets[b.tile]=b.id;count+=1;maxDistance=math.max(maxDistance,S.distance(g,a.tile,b.tile))end
            end
            if count==0 then continue end
            connect(g,bfs,a.tile,maxDistance*4,targets,count,minX,maxX,minY,maxY,edge,a.id,cx,cy)
        end
    end end
    table.sort(edges,function(a,b)return a.nodeA<b.nodeA or a.nodeA==b.nodeA and a.nodeB<b.nodeB end)
    for i=1,#nodes do graph.adj[i]={}end
    for i,e in ipairs(edges)do e.id=i-1;table.insert(graph.adj[e.nodeA+1],e);table.insert(graph.adj[e.nodeB+1],e)end
    graph.rebuiltClusters=rebuiltClusters
    return graph,cc,bfs
end
return M
