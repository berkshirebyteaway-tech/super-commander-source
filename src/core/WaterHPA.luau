--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local S=if script then require(script.Parent.WaterSearch)else require('./WaterSearch')
local G=if script then require(script.Parent.WaterGraph)else require('./WaterGraph')
local M={};M.__index=M
function M.new(g)
    local graph,cc,bfs=G.build(g)
    return setmetatable({grid=g,graph=graph,cc=cc,bfs=bfs,abstract=S.scratch(#graph.nodes)},M)
end
function M:scratch()
    if self.localSearch then return end
    self.localSearch=S.scratch(1024);self.multiSearch=S.scratch(9216);self.shortSearch=S.scratch(67600)
end
function M:rebuild(dirty)
    self.graph=G.build(self.grid,self.cc,self.bfs,self.graph,dirty);self.abstract=S.scratch(#self.graph.nodes)
end
function M:abstractPath(starts,goal)
    local graph=self.graph;local s=self.abstract;if type(starts)=='number'then starts={starts}end
    if #starts==0 or not graph.nodes[goal+1]then return nil end
    s.stamp+=1;if s.stamp>=2^32 then buffer.fill(s.closed,0,0);buffer.fill(s.seen,0,0);s.stamp=1 end
    local stamp=s.stamp;local heap=s.heap;heap.size=0;local target=graph.nodes[goal+1]
    for _,id in ipairs(starts)do local node=graph.nodes[id+1];if not node then continue end
        buffer.writef32(s.cost,id*4,0);buffer.writeu32(s.seen,id*4,stamp);buffer.writei32(s.parent,id*4,-1)
        heap:push(id,math.abs(node.x-target.x)+math.abs(node.y-target.y))
    end
    local iterations=100000
    while heap.size>0 do
        iterations-=1;if iterations<=0 then return nil end
        local id=heap:pop();if buffer.readu32(s.closed,id*4)==stamp then continue end
        buffer.writeu32(s.closed,id*4,stamp)
        if id==goal then local path={};repeat
            if id<0 or id>=#graph.nodes or #path>#graph.nodes then return nil end
            table.insert(path,id);id=buffer.readi32(s.parent,id*4)
        until id==-1;for i=1,#path//2 do path[i],path[#path+1-i]=path[#path+1-i],path[i]end;return path end
        local cost=buffer.readf32(s.cost,id*4)
        for _,e in ipairs(graph.adj[id+1])do
            local n=if e.nodeA==id then e.nodeB else e.nodeA
            if buffer.readu32(s.closed,n*4)==stamp then continue end
            local nextCost=cost+e.cost
            if buffer.readu32(s.seen,n*4)~=stamp or nextCost<buffer.readf32(s.cost,n*4)then
                buffer.writeu32(s.seen,n*4,stamp);buffer.writef32(s.cost,n*4,nextCost);buffer.writei32(s.parent,n*4,id)
                local node=graph.nodes[n+1];heap:push(n,nextCost+math.abs(node.x-target.x)+math.abs(node.y-target.y))
            end
        end
    end
    return nil
end
function M:localPath(from,to,cx,cy,multi)
    self:scratch()
    local g=self.grid
    local minX,minY=math.max(0,(cx-(multi and 1 or 0))*32),math.max(0,(cy-(multi and 1 or 0))*32)
    local maxX,maxY=math.min(g.width-1,(cx+(multi and 2 or 1))*32-1),math.min(g.height-1,(cy+(multi and 2 or 1))*32-1)
    local p=S.bounded(g,multi and self.multiSearch or self.localSearch,from,to,minX,maxX,minY,maxY)
    if not p or #p==0 then return nil end
    if p[1]~=from then table.insert(p,1,from)end;if p[#p]~=to then table.insert(p,to)end;return p
end
function M:nearest(tile,cheap)
    local g,graph=self.grid,self.graph;local cx,cy=(tile%g.width)//32,(tile//g.width)//32
    local cluster=graph.clusters[cy*graph.clustersX+cx+1];if not cluster or #cluster==0 then return nil end
    if cheap then local best,dist=nil,math.huge;for _,id in ipairs(cluster)do local n=graph.nodes[id+1];local d=S.distance(g,tile,n.tile)
        if d<dist then best,dist=n,d end
    end;return best end
    local candidates={};for _,id in ipairs(cluster)do candidates[graph.nodes[id+1].tile]=graph.nodes[id+1]end
    return S.bfs(g,self.bfs,tile,1024,function(t)
        if candidates[t]then return candidates[t]end
        local x,y=t%g.width,t//g.width
        if x<cx*32 or x>math.min(g.width-1,cx*32+31)or y<cy*32 or y>math.min(g.height-1,cy*32+31)then return false end
        return nil
    end)
end
local function append(out,path,first)for i=first or 1,#path do table.insert(out,path[i])end end
function M:single(from,to)
    local g,graph=self.grid,self.graph;local cx,cy=(from%g.width)//32,(from//g.width)//32
    if S.distance(g,from,to)<=32 then local p=self:localPath(from,to,cx,cy,true);if p then return p end end
    local startNode,endNode=self:nearest(from),self:nearest(to);if not startNode or not endNode then return nil end
    if startNode.id==endNode.id then return self:localPath(from,to,startNode.x//32,startNode.y//32,true)end
    local np=self:abstractPath(startNode.id,endNode.id);if not np then return nil end
    local first=graph.nodes[np[1]+1];local out=self:localPath(from,first.tile,cx,cy);if not out then return nil end
    for i=1,#np-1 do
        local a,b=np[i],np[i+1];local edge=nil
        for _,e in ipairs(graph.adj[a+1])do if e.nodeA==b or e.nodeB==b then edge=e;break end end
        if not edge then return nil end
        local key=edge.id*2+(if a==edge.nodeA then 0 else 1);local path=graph.cache[key]
        if not path then path=self:localPath(graph.nodes[a+1].tile,graph.nodes[b+1].tile,edge.clusterX,edge.clusterY);if not path then return nil end;graph.cache[key]=path end
        append(out,path,2)
    end
    local last=graph.nodes[np[#np]+1];local tail=self:localPath(last.tile,to,(to%g.width)//32,(to//g.width)//32)
    if not tail then return nil end;append(out,tail,2);return out
end
function M:findPath(sources,to)
    self:scratch()
    local component=self.cc:get(to);local valid={}
    for _,t in ipairs(type(sources)=='number'and {sources}or sources)do if self.cc:get(t)==component then table.insert(valid,t)end end
    if #valid==0 then return nil end;if #valid==1 then return self:single(valid[1],to)end
    local g=self.grid;local candidates={};local minX,maxX,minY,maxY=to%g.width,to%g.width,to//g.width,to//g.width
    for _,t in ipairs(valid)do if S.distance(g,t,to)<=120 then
        table.insert(candidates,t);minX,maxX=math.min(minX,t%g.width),math.max(maxX,t%g.width);minY,maxY=math.min(minY,t//g.width),math.max(maxY,t//g.width)
    end end
    if #candidates>0 then
        local p=S.bounded(g,self.shortSearch,candidates,to,math.max(0,minX-10),math.min(g.width-1,maxX+10),math.max(0,minY-10),math.min(g.height-1,maxY+10));if p then return p end
    end
    local target=self:nearest(to,true);if not target then return nil end
    local ids,winners,distances={},{},{}
    for _,t in ipairs(valid)do local node=self:nearest(t,true);if not node then continue end
        local d=S.distance(g,t,node.tile);local id=node.id
        if distances[id]==nil then table.insert(ids,id)end
        if distances[id]==nil or d<distances[id]then distances[id]=d;winners[id]=t end
    end
    local p=self:abstractPath(ids,target.id);if not p then return nil end
    return self:single(winners[p[1]],to)
end
return M
