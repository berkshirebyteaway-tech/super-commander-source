--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local M={};M.__index=M
local PERIOD=20
local band=bit32.band
local SURROUNDED=1
function M.new(w)
    local sim=w.sim;local size=sim.width*sim.height
    return setmetatable({w=w,sim=sim,width=sim.width,height=sim.height,visited=buffer.create(size*4),clusterIndex=buffer.create(size*4),gen=0,lastCalc={}},M)
end
local N4,N8={0,0,0,0},{0,0,0,0,0,0,0,0}
local function nb4(t,w,h,out)
    local n,x=0,t%w
    if t>=w then n+=1;out[n]=t-w end
    if t<(h-1)*w then n+=1;out[n]=t+w end
    if x~=0 then n+=1;out[n]=t-1 end
    if x~=w-1 then n+=1;out[n]=t+1 end
    return n
end
local function nb8(t,w,h,out)
    local n,x=0,t%w;local hasN,hasS=t>=w,t<(h-1)*w
    if x~=0 then if hasN then n+=1;out[n]=t-1-w end;n+=1;out[n]=t-1;if hasS then n+=1;out[n]=t-1+w end end
    if hasN then n+=1;out[n]=t-w end
    if hasS then n+=1;out[n]=t+w end
    if x~=w-1 then if hasN then n+=1;out[n]=t+1-w end;n+=1;out[n]=t+1;if hasS then n+=1;out[n]=t+1+w end end
    return n
end
local function byte(sim,t) local tb=sim.tb;if tb then return buffer.readu8(tb,t) end;return sim.terrain[t+1] end
local function impassable(b) return T.isLand(b) and T.magnitude(b)==31 end
function M:bump() self.gen+=1;return self.gen end
function M:bumpN(count) local first=self.gen+1;self.gen+=count;return first end
function M:edge(t)
    local w,sim=self.width,self.sim;local x=t%w
    if x==0 or x==w-1 or t<w or t>=(self.height-1)*w then return true end
    return impassable(byte(sim,t-1)) or impassable(byte(sim,t+1)) or impassable(byte(sim,t-w)) or impassable(byte(sim,t+w))
end
function M:oceanShore(t)
    local sim,w=self.sim,self.width;if not T.isLand(byte(sim,t)) then return false end
    local x=t%w
    return x~=0 and T.isOcean(byte(sim,t-1)) or x~=w-1 and T.isOcean(byte(sim,t+1)) or t>=w and T.isOcean(byte(sim,t-w)) or t<(self.height-1)*w and T.isOcean(byte(sim,t+w))
end
function M:shore(t) local b=byte(self.sim,t);return T.isLand(b) and T.isShoreline(b) end
function M:fill(gen,start,diag,include)
    local visited,w,h=self.visited,self.width,self.height
    if buffer.readu32(visited,start*4)==gen or not include(start) then return {},nil end
    buffer.writeu32(visited,start*4,gen)
    local out,stack={start},{start};local minX,minY,maxX,maxY=1e9,1e9,-1e9,-1e9
    while #stack>0 do
        local t=table.remove(stack);local x,y=t%w,t//w
        if x<minX then minX=x end;if y<minY then minY=y end;if x>maxX then maxX=x end;if y>maxY then maxY=y end
        local list=diag and N8 or N4;local count=diag and nb8(t,w,h,N8) or nb4(t,w,h,N4)
        for i=1,count do local n=list[i]
            if buffer.readu32(visited,n*4)~=gen and include(n) then buffer.writeu32(visited,n*4,gen);table.insert(out,n);table.insert(stack,n) end
        end
    end
    return out,{minX,minY,maxX,maxY}
end
function M:clusters(id)
    local p=self.sim.players[id];local visited=self.visited
    local borderGen=self:bump();p.border:forEach(function(t) buffer.writeu32(visited,t*4,borderGen) end)
    local gen=self:bump();local clusters,boxes={},{}
    local function include(t) return buffer.readu32(visited,t*4)==borderGen end
    p.border:forEach(function(t)
        if buffer.readu32(visited,t*4)==gen then return end
        local cluster,box=self:fill(gen,t,true,include)
        if #cluster>0 then table.insert(clusters,cluster);table.insert(boxes,box) end
    end)
    return clusters,boxes
end
local function contains(outer,inner) return outer[1]<=inner[1] and outer[2]<=inner[2] and outer[3]>=inner[3] and outer[4]>=inner[4] end
local function contains(outer,inner) return outer[1]<=inner[1] and outer[2]<=inner[2] and outer[3]>=inner[3] and outer[4]>=inner[4] end
local function alive(sim,id) return sim.players[id].tiles.size>0 end
function M:territory(id,clusters,a,b,ids,nextId)
    if ids[a]~=-1 and ids[a]==ids[b] then return nextId end
    if ids[a]~=-1 and ids[b]~=-1 then return nextId end
    local startIndex=if ids[b]==-1 then b else a;local territory=nextId;nextId+=1
    local owners,index,visited,w,h=self.sim.owners,self.clusterIndex,self.visited,self.width,self.height
    local gen=self:bump();local start=clusters[startIndex][1]
    if start==nil or owners[start+1]~=id then return nextId end
    buffer.writeu32(visited,start*4,gen);local stack={start};ids[startIndex]=territory
    while #stack>0 do
        local t=stack[#stack];stack[#stack]=nil
        for i=1,nb8(t,w,h,N8) do local n=N8[i]
            if buffer.readu32(visited,n*4)~=gen and owners[n+1]==id then
                buffer.writeu32(visited,n*4,gen);stack[#stack+1]=n
                local c=buffer.readu32(index,n*4);if c>0 then ids[c]=territory end
            end
        end
    end
    return nextId
end
function M:surroundedBySame(id,cluster,box)
    local owners,w,h=self.sim.owners,self.width,self.height
    local enemies,count,enemy={},0,nil;local minX,minY,maxX,maxY=1e9,1e9,-1e9,-1e9
    for _,t in ipairs(cluster) do
        if self:oceanShore(t) or self:edge(t) then return nil end
        for i=1,nb4(t,w,h,N4) do local n=N4[i]
            local o=owners[n+1]
            if o==0 then return nil end
            if o~=id then
                if not enemies[o] then enemies[o]=true;count+=1;enemy=o end
                local x,y=n%w,n//w
                if x<minX then minX=x end;if y<minY then minY=y end;if x>maxX then maxX=x end;if y>maxY then maxY=y end
            end
        end
        if count>1 then return nil end
    end
    if count~=1 then return nil end
    if minX<=box[1] and minY<=box[2] and maxX>=box[3] and maxY>=box[4] then return enemy end
    return nil
end
function M:classify(id,cluster,box)
    local owners,fallout,w,h=self.sim.owners,self.sim.fallout,self.width,self.height
    local hasEnemy,hasOpen=false,false;local minX,minY,maxX,maxY=1e9,1e9,-1e9,-1e9
    for _,t in ipairs(cluster) do
        if self:shore(t) or self:edge(t) then return 0 end
        for i=1,nb4(t,w,h,N4) do local n=N4[i]
            local o=owners[n+1]
            if o~=0 and o~=id then
                hasEnemy=true;local x,y=n%w,n//w
                if x<minX then minX=x end;if y<minY then minY=y end;if x>maxX then maxX=x end;if y>maxY then maxY=y end
            elseif o==0 then
                if fallout[n] then
                    local x,y=n%w,n//w
                    if x<minX then minX=x end;if y<minY then minY=y end;if x>maxX then maxX=x end;if y>maxY then maxY=y end
                else hasOpen=true end
            end
        end
    end
    if not hasEnemy or hasOpen then return 0 end
    if minX<=box[1] and minY<=box[2] and maxX>=box[3] and maxY>=box[4] then return SURROUNDED end
    return 0
end
function M:pinched(id,cluster)
    local owners,w,h=self.sim.owners,self.width,self.height
    for _,t in ipairs(cluster) do
        if owners[t+1]~=id or t>=(h-1)*w then continue end
        local below=t+w
        if owners[below+1]==id then continue end
        local x=t%w
        if (x<w-1 and owners[below+2]==id and owners[t+2]~=id) or (x>0 and owners[below]==id and owners[t]~=id) then return true end
    end
    return false
end
function M:enclosed(id,start,box)
    local owners,fallout,w,h,visited,sim=self.sim.owners,self.sim.fallout,self.width,self.height,self.visited,self.sim
    local fMinX,fMinY,fMaxX,fMaxY=box[1]-1,box[2]-1,box[3]+1,box[4]+1
    local gen=self:bump();buffer.writeu32(visited,start*4,gen);local stack={start}
    while #stack>0 do
        local t=stack[#stack];stack[#stack]=nil
        local x,y=t%w,t//w
        if x<fMinX or x>fMaxX or y<fMinY or y>fMaxY then return false end
        if self:edge(t) then return false end
        for i=1,nb4(t,w,h,N4) do local n=N4[i]
            if buffer.readu32(visited,n*4)==gen then continue end
            local o=owners[n+1]
            if o==id then buffer.writeu32(visited,n*4,gen);stack[#stack+1]=n;continue end
            if o==0 and (not T.isLand(byte(sim,n)) or not fallout[n]) then return false end
        end
    end
    return true
end
function M:capturing(id,cluster)
    local w,sim,owners=self.w,self.sim,self.sim.owners;local counts,order={},{}
    for _,t in ipairs(cluster) do for _,n in ipairs(T.neighbors(t,self.width,self.height)) do
        local o=owners[n+1]
        if o~=0 and o~=id and not w:friendly(o,id) then if not counts[o] then counts[o]=0;table.insert(order,o) end;counts[o]+=1 end
    end end
    if #order==0 then return nil end
    local best,troops=nil,0
    for _,o in ipairs(order) do for _,a in ipairs(sim.players[o].outgoing) do
        if a.active~=false and a.target==id and a.troops>troops then troops=a.troops;best=o end
    end end
    if best then return best end
    local mode,most=nil,0;for _,o in ipairs(order) do if counts[o]>most then most=counts[o];mode=o end end
    return mode
end
function M:hand(id,capturing,tiles,encircled)
    local sim=self.sim
    if sim.players[id].tiles.size==#tiles then
        if encircled then self.annexed=self.annexed or {};self.annexed[id]=capturing end
        if sim.conquerPlayer then sim.conquerPlayer(capturing,id) end
    end
    for _,t in ipairs(tiles) do sim:conquer(capturing,t) end
end
local function mine(owners,id) return function(t) return owners[t+1]==id end end
function M:reject(id,start,gen,box)
    local owners,visited,w,h=self.sim.owners,self.visited,self.width,self.height
    local fMinX,fMinY,fMaxX,fMaxY=box[1]-1,box[2]-1,box[3]+1,box[4]+1
    buffer.writeu32(visited,start*4,gen);local stack={start}
    while #stack>0 do
        local t=stack[#stack];stack[#stack]=nil
        for i=1,nb4(t,w,h,N4) do local n=N4[i]
            if buffer.readu32(visited,n*4)==gen or owners[n+1]~=id then continue end
            local x,y=n%w,n//w
            if x>=fMinX and x<=fMaxX and y>=fMinY and y<=fMaxY then buffer.writeu32(visited,n*4,gen);stack[#stack+1]=n end
        end
    end
end
function M:remove(id,cluster,box,known,isPinched)
    local sim=self.sim;local owners=sim.owners
    for _,t in ipairs(cluster) do if owners[t+1]~=id then return false end end
    local first=cluster[1];if first==nil then return false end
    if isPinched==nil then isPinched=self:pinched(id,cluster) end
    if not isPinched then
        local capturing=known or self:capturing(id,cluster)
        if not capturing then return false end
        if not self:enclosed(id,first,box) then return false end
        local tiles=self:fill(self:bump(),first,false,mine(owners,id))
        self:hand(id,capturing,tiles,true)
        return true
    end
    local gen=self:bump();local visited=self.visited;local any=false
    for _,t in ipairs(cluster) do
        if not alive(sim,id) then break end
        if buffer.readu32(visited,t*4)==gen or owners[t+1]~=id then continue end
        if not self:enclosed(id,t,box) then self:reject(id,t,gen,box);continue end
        local tiles=self:fill(gen,t,false,mine(owners,id))
        if #tiles>0 then
            local capturing=known or self:capturing(id,tiles)
            if not capturing then continue end
            any=true;self:hand(id,capturing,tiles,true)
        end
    end
    return any
end
function M:areas(id,clusters,first)
    local owners,visited,w,h=self.sim.owners,self.visited,self.width,self.height
    local areas,tileIds,sizes={[0]=0},{},{};local nextId=1
    for c,cluster in ipairs(clusters) do
        local ids={};tileIds[c]=ids;local best=0
        for j,t in ipairs(cluster) do
            local v=buffer.readu32(visited,t*4)
            if v>=first then local tid=v-first+1;ids[j]=tid;if areas[tid]>best then best=areas[tid] end;continue end
            ids[j]=0
            if owners[t+1]~=id then continue end
            local tid=nextId;nextId+=1;ids[j]=tid
            local stamp=first+tid-1;if self.gen<stamp then self.gen=stamp end
            buffer.writeu32(visited,t*4,stamp);local stack={t};local size=0
            while #stack>0 do
                local cur=stack[#stack];stack[#stack]=nil;size+=1
                for i=1,nb4(cur,w,h,N4) do local n=N4[i]
                    if buffer.readu32(visited,n*4)<first and owners[n+1]==id then buffer.writeu32(visited,n*4,stamp);stack[#stack+1]=n end
                end
            end
            areas[tid]=size;if size>best then best=size end
        end
        sizes[c]=best
    end
    return tileIds,areas,sizes
end
function M:pinchPieces(id,cluster,maxArea,ids,areas)
    local sim=self.sim
    if not alive(sim,id) then return end
    local owners,fallout,visited,w,h=sim.owners,sim.fallout,self.visited,self.width,self.height
    local gen=self:bump()
    for j,start in ipairs(cluster) do
        if not alive(sim,id) then break end
        if ids then local tid=ids[j];if tid~=0 and areas[tid]>=maxArea then continue end end
        if owners[start+1]~=id or buffer.readu32(visited,start*4)>=gen then continue end
        buffer.writeu32(visited,start*4,gen);local stack={start};local tiles={start}
        local minX,minY=start%w,start//w;local maxX,maxY=minX,minY
        while #stack>0 do
            local cur=stack[#stack];stack[#stack]=nil
            local x,y=cur%w,cur//w
            if x<minX then minX=x end;if y<minY then minY=y end;if x>maxX then maxX=x end;if y>maxY then maxY=y end
            for i=1,nb4(cur,w,h,N4) do local n=N4[i]
                if buffer.readu32(visited,n*4)<gen and owners[n+1]==id then buffer.writeu32(visited,n*4,gen);table.insert(tiles,n);stack[#stack+1]=n end
            end
        end
        if #tiles>=maxArea then continue end
        local nearFallout=false
        for _,t in ipairs(tiles) do
            for i=1,nb4(t,w,h,N4) do if fallout[N4[i]] then nearFallout=true;break end end
            if nearFallout then break end
        end
        if not nearFallout then continue end
        if self:enclosed(id,start,{minX,minY,maxX,maxY}) then
            local capturing=self:capturing(id,tiles)
            if capturing then self:hand(id,capturing,tiles,false) end
        end
    end
end
function M:hole(id,i,clusters,boxes,state)
    for j=1,#clusters do
        if j~=i and contains(boxes[j],boxes[i]) then
            if not state.ids then
                state.ids={};for c=1,#clusters do state.ids[c]=-1;for _,t in ipairs(clusters[c]) do buffer.writeu32(self.clusterIndex,t*4,c) end end
            end
            state.nextId=self:territory(id,clusters,i,j,state.ids,state.nextId)
            if state.ids[i]~=-1 and state.ids[i]==state.ids[j] then return true end
        end
    end
    return false
end
function M:removeClusters(id)
    local clusters,boxes=self:clusters(id)
    if #clusters==0 then return end
    local w,sim=self.w,self.sim
    if #clusters==1 then
        local cluster,box=clusters[1],boxes[1]
        local isPinched=self:pinched(id,cluster);local removed=false
        local by=self:surroundedBySame(id,cluster,box)
        if by and not w:friendly(by,id) then removed=self:remove(id,cluster,box,by,isPinched) end
        if not removed and isPinched then
            local ids,areas,sizes=self:areas(id,clusters,self:bumpN(16))
            self:pinchPieces(id,cluster,sizes[1],ids[1],areas)
        end
        return
    end
    local isPinched={};local anyPinched=false
    for i,c in ipairs(clusters) do isPinched[i]=self:pinched(id,c);if isPinched[i] then anyPinched=true end end
    local classes,bys={},{}
    local active=anyPinched
    for i=1,#clusters do
        classes[i]=self:classify(id,clusters[i],boxes[i])
        local by=self:surroundedBySame(id,clusters[i],boxes[i]);if by and w:friendly(by,id) then by=nil end
        bys[i]=by;if classes[i]~=0 or by then active=true end
    end
    if not active then return end
    local tileIds,areas,sizes=self:areas(id,clusters,self:bumpN(#clusters*4+16))
    local maxArea=0;for _,s in ipairs(sizes) do if s>maxArea then maxArea=s end end
    local largest=1
    local function boxArea(b) return (b[3]-b[1]+1)*(b[4]-b[2]+1) end
    for i=2,#clusters do
        if sizes[i]>sizes[largest] then largest=i
        elseif sizes[i]==sizes[largest] then
            local cur,best=boxArea(boxes[i]),boxArea(boxes[largest])
            if cur>best or cur==best and #clusters[i]>#clusters[largest] then largest=i end
        end
    end
    classes[largest]=0
    local removed={}
    local by=bys[largest]
    if by then removed[largest]=self:remove(id,clusters[largest],boxes[largest],by,isPinched[largest]) end
    for i=1,#clusters do
        if not alive(sim,id) then break end
        if i~=largest and band(classes[i],SURROUNDED)~=0 then
            if self:remove(id,clusters[i],boxes[i],nil,isPinched[i]) then removed[i]=true end
        end
    end
    local state={ids=nil,nextId=1}
    for i=1,#clusters do
        if not alive(sim,id) then break end
        if removed[i] or not isPinched[i] then continue end
        if self:hole(id,i,clusters,boxes,state) then continue end
        self:pinchPieces(id,clusters[i],maxArea,tileIds[i],areas)
    end
    if state.ids then for c=1,#clusters do for _,t in ipairs(clusters[c]) do buffer.writeu32(self.clusterIndex,t*4,0) end end end
end
function M:tick(id)
    local sim=self.sim;local p=sim.players[id];local ticks=sim.ticks
    local last=self.lastCalc[id];if not last then last=ticks+id%PERIOD;self.lastCalc[id]=last end
    if p.tiles.size==0 then return end
    if ticks-last>PERIOD or p.tiles.size<100 then
        if (p.lastTileChange or -1)>=last then self.lastCalc[id]=ticks;self:removeClusters(id) end
    end
end
return M
