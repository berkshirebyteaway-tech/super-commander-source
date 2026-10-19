--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local M={};M.__index=M
local PERIOD=20
local band=bit32.band
local SURROUNDED,SEVERED,OPEN=1,2,4
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
function M:territory(id,clusters,a,b,ids,nextId)
    if ids[a]~=0 and ids[a]==ids[b] then return nextId end
    if ids[a]~=0 and ids[b]~=0 then return nextId end
    local startIndex=ids[b]==0 and b or a;local territory=nextId;nextId+=1
    local owners,index=self.sim.owners,self.clusterIndex
    ids[startIndex]=territory
    self:fill(self:bump(),clusters[startIndex][1],true,function(t)
        if owners[t+1]~=id then return false end
        local c=buffer.readu32(index,t*4);if c>0 then ids[c]=territory end
        return true
    end)
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
        if count~=1 then return nil end
    end
    if count~=1 then return nil end
    if minX<=box[1] and minY<=box[2] and maxX>=box[3] and maxY>=box[4] then return enemy end
    return nil
end
function M:classify(id,cluster,box)
    local owners,fallout,w,h=self.sim.owners,self.sim.fallout,self.width,self.height
    local hasEnemy,hasFallout,hasOpen=false,false,false;local minX,minY,maxX,maxY=1e9,1e9,-1e9,-1e9
    for _,t in ipairs(cluster) do
        if self:shore(t) or self:edge(t) then return OPEN end
        for i=1,nb4(t,w,h,N4) do local n=N4[i]
            local o=owners[n+1]
            if o~=0 and o~=id then
                hasEnemy=true;local x,y=n%w,n//w
                if x<minX then minX=x end;if y<minY then minY=y end;if x>maxX then maxX=x end;if y>maxY then maxY=y end
            elseif o==0 then
                if fallout[n] then hasFallout=true else hasOpen=true end
            end
        end
    end
    local result=hasOpen and OPEN or 0
    if not hasEnemy then return result end
    if minX<=box[1] and minY<=box[2] and maxX>=box[3] and maxY>=box[4] then result+=SURROUNDED end
    if hasFallout and not hasOpen then result+=SEVERED end
    return result
end
function M:enclosed(id,start)
    local owners,w,h,visited,sim=self.sim.owners,self.width,self.height,self.visited,self.sim
    local gen=self:bump();buffer.writeu32(visited,start*4,gen);local stack={start}
    while #stack>0 do
        local t=table.remove(stack)
        if self:edge(t) then return false end
        for i=1,nb4(t,w,h,N4) do local n=N4[i]
            if buffer.readu32(visited,n*4)~=gen then
                local o=owners[n+1]
                if o==0 or o==id then
                    if o==0 and not T.isLand(byte(sim,n)) then return false end
                    buffer.writeu32(visited,n*4,gen);table.insert(stack,n)
                end
            end
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
function M:remove(id,cluster)
    local sim=self.sim;local owners=sim.owners
    for _,t in ipairs(cluster) do if owners[t+1]~=id then return end end
    local capturing=self:capturing(id,cluster);if not capturing or not cluster[1] then return end
    if not self:enclosed(id,cluster[1]) then return end
    local tiles=self:fill(self:bump(),cluster[1],false,function(t) return owners[t+1]==id end)
    if sim.players[id].tiles.size==#tiles then self.annexed=self.annexed or {};self.annexed[id]=capturing end
    if sim.players[id].tiles.size==#tiles and sim.conquerPlayer then sim.conquerPlayer(capturing,id) end
    for _,t in ipairs(tiles) do sim:conquer(capturing,t) end
end
local function wholeCluster(cluster,box,cls) return {clusters={cluster},boxes={box},classes={cls}} end
local function addRacePieces(pieces,parts,all,withOpen)
    for k=1,#parts.clusters do
        local cls=parts.classes[k];local open=band(cls,OPEN)~=0
        if all or band(cls,SEVERED)~=0 or (withOpen and open) then
            table.insert(pieces.clusters,parts.clusters[k]);table.insert(pieces.open,open);table.insert(pieces.boxes,parts.boxes[k])
        end
    end
end
local function rootOf(roots,part) while roots[part]~=part do part=roots[part] end;return part end
local function stampAll(visited,tiles,gen) for _,t in ipairs(tiles) do buffer.writeu32(visited,t*4,gen) end;return nil end
function M:splitCluster(id,cluster,candidatesOnly)
    local owners,fallout,w,h=self.sim.owners,self.sim.fallout,self.width,self.height
    if #cluster==0 or owners[cluster[1]+1]~=id then return nil end
    local pinched,lastRow=false,(h-1)*w
    for _,t in ipairs(cluster) do
        if t<lastRow and owners[t+w+1]~=id then
            local x,below=t%w,t+w
            if (x<w-1 and owners[below+2]==id and owners[t+2]~=id) or (x>0 and owners[below]==id and owners[t]~=id) then pinched=true;break end
        end
    end
    if not pinched then return nil end
    if candidatesOnly then
        local found=false
        for _,t in ipairs(cluster) do
            for i=1,nb4(t,w,h,N4) do local n=N4[i];if owners[n+1]==0 and fallout[n] then found=true end end
            if found then break end
        end
        if not found then return nil end
    end
    local visited=self.visited;local member=self:bumpN(2);local done=member+1
    for _,t in ipairs(cluster) do buffer.writeu32(visited,t*4,member) end
    local parts,boxes,classes={},{},{};local stack={}
    for _,start in ipairs(cluster) do
        if buffer.readu32(visited,start*4)~=member or owners[start+1]~=id then continue end
        buffer.writeu32(visited,start*4,done);stack[1]=start
        local part={};local touchesOpen,hasEnemy,hasFallout=false,false,false;local minX,minY,maxX,maxY=w,h,-1,-1
        while #stack>0 do
            local t=stack[#stack];stack[#stack]=nil;table.insert(part,t)
            local x,y=t%w,t//w
            if x<minX then minX=x end;if y<minY then minY=y end;if x>maxX then maxX=x end;if y>maxY then maxY=y end
            if self:shore(t) or self:edge(t) then touchesOpen=true end
            for i=1,nb8(t,w,h,N8) do local n=N8[i]
                local o=owners[n+1];local dx=n%w-x;local diagonal=dx~=0 and n-dx~=t
                if not diagonal and o~=id then
                    if o~=0 then hasEnemy=true elseif fallout[n] then hasFallout=true else touchesOpen=true end
                end
                if buffer.readu32(visited,n*4)==member and o==id and not (diagonal and owners[t+dx+1]~=id and owners[n-dx+1]~=id) then
                    buffer.writeu32(visited,n*4,done);stack[#stack+1]=n
                end
            end
        end
        table.insert(parts,part);table.insert(boxes,{minX,minY,maxX,maxY})
        table.insert(classes,if touchesOpen then OPEN elseif hasEnemy and hasFallout then SEVERED else 0)
    end
    if #parts<2 then return nil end
    return {clusters=parts,boxes=boxes,classes=classes}
end
function M:largestTerritoryPart(id,parts,roots,boxes)
    local owners,visited,w,h=self.sim.owners,self.visited,self.width,self.height
    local count=#parts;local base=self:bumpN(count)
    local bounds=nil
    if boxes then
        bounds={}
        for i=1,count do local b,o=boxes[i],(i-1)*4
            if b[1]==0 or b[2]==0 or b[3]==w-1 or b[4]==h-1 then bounds[o+1]=0;bounds[o+2]=0;bounds[o+3]=w-1;bounds[o+4]=h-1
            else bounds[o+1]=b[1];bounds[o+2]=b[2];bounds[o+3]=b[3];bounds[o+4]=b[4] end
        end
    end
    local stacks,sizes,dropped={},{},{}
    for i=1,count do
        roots[i]=i;for _,t in ipairs(parts[i]) do buffer.writeu32(visited,t*4,base+i-1) end
        stacks[i]=table.clone(parts[i]);sizes[i]=#parts[i];dropped[i]=false
    end
    local growing,best=count,0
    while true do
        for i=1,count do
            local stack=stacks[i]
            if roots[i]~=i or dropped[i] or #stack==0 then continue end
            local t=stack[#stack];stack[#stack]=nil
            if bounds then
                local x,y,b=t%w,t//w,(i-1)*4
                if x<bounds[b+1] or y<bounds[b+2] or x>bounds[b+3] or y>bounds[b+4] then
                    stack[#stack+1]=t;dropped[i]=true;growing-=1;continue
                end
            end
            for k=1,nb4(t,w,h,N4) do local n=N4[k]
                if owners[n+1]~=id then continue end
                local part=buffer.readu32(visited,n*4)-base
                if part<0 or part>=count then
                    buffer.writeu32(visited,n*4,base+i-1);sizes[i]+=1;stack[#stack+1]=n;continue
                end
                local other=rootOf(roots,part+1)
                if other==i then continue end
                roots[other]=i;sizes[i]+=sizes[other]
                local from=stacks[other];for _,s in ipairs(from) do stack[#stack+1]=s end;table.clear(from)
                if not dropped[other] then growing-=1 end
                if bounds then
                    local b,o=(i-1)*4,(other-1)*4
                    if bounds[o+1]<bounds[b+1] then bounds[b+1]=bounds[o+1] end
                    if bounds[o+2]<bounds[b+2] then bounds[b+2]=bounds[o+2] end
                    if bounds[o+3]>bounds[b+3] then bounds[b+3]=bounds[o+3] end
                    if bounds[o+4]>bounds[b+4] then bounds[b+4]=bounds[o+4] end
                end
            end
            if #stack==0 then
                growing-=1
                if best==0 or sizes[i]>sizes[best] or (sizes[i]==sizes[best] and i<best) then best=i end
            end
        end
        if growing==0 then return best end
        if growing==1 then
            local last=1;while roots[last]~=last or dropped[last] or #stacks[last]==0 do last+=1 end
            if best==0 or sizes[last]>sizes[best] then return last end
        end
    end
end
function M:severedLand(id,largestCluster,largestBox,severed,openClusters)
    if (self.w.falloutTiles or 0)==0 then return nil end
    local largest=self:splitCluster(id,largestCluster,false)
    if not largest then
        if not severed and not openClusters then return nil end
        largest=wholeCluster(largestCluster,largestBox,self:classify(id,largestCluster,largestBox))
    end
    local anyOpen,anyCandidate=false,false
    for _,c in ipairs(largest.classes) do
        if band(c,OPEN)~=0 then anyOpen=true end;if band(c,SEVERED)~=0 then anyCandidate=true end
    end
    local addOpen=not anyOpen and anyCandidate
    local pieces={clusters={},boxes={},open={}}
    addRacePieces(pieces,largest,true,true)
    local largestParts=#pieces.clusters
    if severed then
        for c,cluster in ipairs(severed.clusters) do
            addRacePieces(pieces,self:splitCluster(id,cluster,false) or wholeCluster(cluster,severed.boxes[c],SEVERED),false,false)
        end
    end
    if openClusters then
        for c,cluster in ipairs(openClusters.clusters) do
            local split=self:splitCluster(id,cluster,not addOpen)
            if split then addRacePieces(pieces,split,false,addOpen)
            elseif addOpen then addRacePieces(pieces,wholeCluster(cluster,openClusters.boxes[c],OPEN),false,true) end
        end
    end
    if #pieces.clusters<2 or not table.find(pieces.open,false) then return nil end
    local count=#pieces.clusters;local roots={}
    local main=self:largestTerritoryPart(id,pieces.clusters,roots,pieces.boxes)
    if main==0 then return nil end
    local mainTiles,candidates={},{clusters={},boxes={}}
    for k=0,count-1 do local i=(k+largestParts)%count+1
        if rootOf(roots,i)==main then table.insert(mainTiles,pieces.clusters[i])
        elseif not pieces.open[i] then table.insert(candidates.clusters,pieces.clusters[i]);table.insert(candidates.boxes,pieces.boxes[i]) end
    end
    if #candidates.clusters==0 then return nil end
    return {mainTiles=mainTiles,candidates=candidates}
end
function M:stampMain(mainTiles)
    local gen=self:bumpN(3);local visited=self.visited
    for _,piece in ipairs(mainTiles) do for _,t in ipairs(piece) do buffer.writeu32(visited,t*4,gen) end end
    return gen
end
function M:severedTerritory(id,start,mainGen,seenGen,failGen,box)
    local owners,fallout,visited,w,h=self.sim.owners,self.sim.fallout,self.visited,self.width,self.height
    local minX,minY,maxX,maxY=box[1],box[2],box[3],box[4]
    local tiles,stack={start},{start};buffer.writeu32(visited,start*4,seenGen)
    local hasEnemy,hasFallout=false,false
    while #stack>0 do
        local t=stack[#stack];stack[#stack]=nil
        local x,y=t%w,t//w
        if x<minX or x>maxX or y<minY or y>maxY or self:shore(t) or self:edge(t) then return stampAll(visited,tiles,failGen) end
        for i=1,nb4(t,w,h,N4) do local n=N4[i]
            local o=owners[n+1]
            if o==id then
                local mark=buffer.readu32(visited,n*4)
                if mark==mainGen then return stampAll(visited,tiles,mainGen) end
                if mark==failGen then return stampAll(visited,tiles,failGen) end
                if mark~=seenGen then buffer.writeu32(visited,n*4,seenGen);table.insert(tiles,n);stack[#stack+1]=n end
            elseif o~=0 then hasEnemy=true
            elseif fallout[n] then hasFallout=true
            else return stampAll(visited,tiles,failGen) end
        end
    end
    return if hasEnemy and hasFallout then tiles else nil
end
function M:annexSevered(id,candidates,mainTiles)
    local sim=self.sim;local owners,visited=sim.owners,self.visited
    for c,cluster in ipairs(candidates.clusters) do
        local mainGen=self:stampMain(mainTiles)
        for _,start in ipairs(cluster) do
            if owners[start+1]~=id then continue end
            local mark=buffer.readu32(visited,start*4)
            if mark>=mainGen and mark<=mainGen+2 then continue end
            local territory=self:severedTerritory(id,start,mainGen,mainGen+1,mainGen+2,candidates.boxes[c])
            if not territory then continue end
            local capturing=self:capturing(id,territory)
            if not capturing then continue end
            if sim.players[id].tiles.size==#territory and sim.conquerPlayer then sim.conquerPlayer(capturing,id) end
            for _,t in ipairs(territory) do sim:conquer(capturing,t) end
            mainGen=self:stampMain(mainTiles)
        end
    end
end
function M:removeClusters(id)
    local clusters,boxes=self:clusters(id)
    if #clusters==0 then return end
    local w=self.w
    if #clusters==1 then
        local by=self:surroundedBySame(id,clusters[1],boxes[1])
        local severed=self:severedLand(id,clusters[1],boxes[1],nil,nil)
        if by and not w:friendly(by,id) then self:remove(id,clusters[1]) end
        if severed then self:annexSevered(id,severed.candidates,severed.mainTiles) end
        return
    end
    local largest=1;for i=2,#clusters do if #clusters[i]>#clusters[largest] then largest=i end end
    local ids,nextId,indexed=nil,1,false
    local function index()
        if indexed then return end;indexed=true;ids={};for c=1,#clusters do ids[c]=0;for _,t in ipairs(clusters[c]) do buffer.writeu32(self.clusterIndex,t*4,c) end end
    end
    local largestHole=false
    for j=1,#clusters do if j~=largest and contains(boxes[j],boxes[largest]) then
        index();nextId=self:territory(id,clusters,largest,j,ids,nextId)
        if ids[largest]==ids[j] then largestHole=true;break end
    end end
    if largestHole then
        local bestIndex,bestLength=nil,-1
        for i=1,#clusters do if i~=largest and #clusters[i]>bestLength then
            local hole=false
            for j=1,#clusters do if j~=i and contains(boxes[j],boxes[i]) then
                nextId=self:territory(id,clusters,i,j,ids,nextId)
                if ids[i]==ids[j] then hole=true;break end
            end end
            if not hole then bestLength=#clusters[i];bestIndex=i end
        end end
        if bestIndex then largest=bestIndex end
    end
    if indexed then for c=1,#clusters do for _,t in ipairs(clusters[c]) do buffer.writeu32(self.clusterIndex,t*4,0) end end end
    local by=self:surroundedBySame(id,clusters[largest],boxes[largest])
    local classes={};local severed,open=nil,nil
    for i=1,#clusters do
        if i==largest then classes[i]=0;continue end
        local result=self:classify(id,clusters[i],boxes[i]);classes[i]=result
        if band(result,SEVERED)~=0 then
            severed=severed or {clusters={},boxes={}};table.insert(severed.clusters,clusters[i]);table.insert(severed.boxes,boxes[i])
        end
        if band(result,OPEN)~=0 then
            open=open or {clusters={},boxes={}};table.insert(open.clusters,clusters[i]);table.insert(open.boxes,boxes[i])
        end
    end
    local land=self:severedLand(id,clusters[largest],boxes[largest],severed,open)
    if by and not w:friendly(by,id) then self:remove(id,clusters[largest]) end
    for i=1,#clusters do if band(classes[i],SURROUNDED)~=0 then self:remove(id,clusters[i]) end end
    if land then self:annexSevered(id,land.candidates,land.mainTiles) end
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
