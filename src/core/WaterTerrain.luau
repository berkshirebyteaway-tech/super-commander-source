--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local S=if script then require(script.Parent.WaterSearch)else require('./WaterSearch')
local M={};M.__index=M
local band=bit32.band
function M.new(full,mini)return setmetatable({full=full,mini=mini,scratch={}},M)end
local function groups(tiles,w)
    local cells,keys,parents={},{},{};local cxN=math.ceil(w/62)
    for _,t in ipairs(tiles)do local x,y=t%w,t//w;local key=(y//62)*cxN+x//62;local b=cells[key]
        if not b then cells[key]={x,x,y,y};table.insert(keys,key);parents[key]=key
        else b[1],b[2],b[3],b[4]=math.min(b[1],x),math.max(b[2],x),math.min(b[3],y),math.max(b[4],y)end
    end
    local function root(k)local r=k;while parents[r]~=r do r=parents[r]end;while parents[k]~=r do local n=parents[k];parents[k]=r;k=n end;return r end
    for _,key in ipairs(keys)do local cx,cy=key%cxN,key//cxN
        for dy=-1,1 do for dx=-1,1 do local nx,ny=cx+dx,cy+dy;if nx<0 or nx>=cxN or ny<0 then continue end
            local k=ny*cxN+nx;if cells[k]then local a,b=root(key),root(k);if a~=b then parents[math.max(a,b)]=math.min(a,b)end end
        end end
    end
    local byRoot,out={},{}
    local function merge(a,b)return {math.min(a[1],b[1]),math.max(a[2],b[2]),math.min(a[3],b[3]),math.max(a[4],b[4])}end
    for _,key in ipairs(keys)do local r=root(key);local i=byRoot[r];if not i then table.insert(out,table.clone(cells[key]));byRoot[r]=#out else out[i]=merge(out[i],cells[key])end end
    local function area(b)return(b[2]-b[1]+248)*(b[4]-b[3]+248)end
    local again=true;while again do again=false
        for i=1,#out do if again then break end;for j=i+1,#out do local b=merge(out[i],out[j]);if area(b)<area(out[i])+area(out[j])then out[i]=b;table.remove(out,j);again=true;break end end end
    end;return out
end
function M:magnitudes(g,tiles,passableOnly,changed)
    local scratch=self.scratch[g];if not scratch then scratch={seen=buffer.create(g.width*g.height*2),dist=buffer.create(g.width*g.height*2),stamp=0};self.scratch[g]=scratch end
    local w,h,tb=g.width,g.height,g.terrain
    local function coast(t)local b=buffer.readu8(tb,t);return band(b,128)~=0 and (not passableOnly or band(b,31)~=31)end
    for _,b in ipairs(groups(tiles,w))do
        scratch.stamp+=1;if scratch.stamp>=65535 then buffer.fill(scratch.seen,0,0);scratch.stamp=1 end
        local stamp,seen,dist=scratch.stamp,scratch.seen,scratch.dist
        local dx0,dx1,dy0,dy1=math.max(0,b[1]-62),math.min(w-1,b[2]+62),math.max(0,b[3]-62),math.min(h-1,b[4]+62)
        local sx0,sx1,sy0,sy1=math.max(0,b[1]-124),math.min(w-1,b[2]+124),math.max(0,b[3]-124),math.min(h-1,b[4]+124)
        local queue={}
        for y=sy0,sy1 do for x=sx0,sx1 do local t=y*w+x
            if not S.water(g,t)then continue end
            if (y>0 and coast(t-w))or(y<h-1 and coast(t+w))or(x>0 and coast(t-1))or(x<w-1 and coast(t+1))then
                buffer.writeu16(seen,t*2,stamp);buffer.writeu16(dist,t*2,0);table.insert(queue,t)
            end
        end end
        local head=1
        local function add(n,d)
            if buffer.readu16(seen,n*2)==stamp or not S.water(g,n)then return end
            buffer.writeu16(seen,n*2,stamp);buffer.writeu16(dist,n*2,d%65536);table.insert(queue,n)
        end
        while head<=#queue do local t=queue[head];head+=1;local x,y=t%w,t//w;local d=buffer.readu16(dist,t*2)+1
            if y>sy0 then add(t-w,d)end;if y<sy1 then add(t+w,d)end;if x>sx0 then add(t-1,d)end;if x<sx1 then add(t+1,d)end
        end
        for y=dy0,dy1 do for x=dx0,dx1 do local t=y*w+x;local byte=buffer.readu8(tb,t);if band(byte,128)~=0 then continue end
            local mag=if buffer.readu16(seen,t*2)==stamp then math.min(math.ceil(buffer.readu16(dist,t*2)/2),31)else 31
            if band(byte,31)~=mag then buffer.writeu8(tb,t,band(byte,224)+mag);if changed then changed(t)end end
        end end
    end
end
local function ocean(g,tiles,changed)
    local queue={};local converted={};for _,t in ipairs(tiles)do converted[t]=true end
    for _,t in ipairs(tiles)do local found=false
        S.neighbors(g,t,function(n)if not converted[n]and band(buffer.readu8(g.terrain,n),32)~=0 and S.water(g,n)then found=true end end)
        if found then buffer.writeu8(g.terrain,t,bit32.bor(buffer.readu8(g.terrain,t),32));table.insert(queue,t)end
    end
    local head=1;while head<=#queue do local t=queue[head];head+=1
        S.neighbors(g,t,function(n)local b=buffer.readu8(g.terrain,n);if band(b,160)==0 then buffer.writeu8(g.terrain,n,bit32.bor(b,32));if changed then changed(n)end;table.insert(queue,n)end end)
    end
end
function M:convert(tiles)
    local g,mini=self.full,self.mini;local seen,changed={},{}
    local function note(t)if not seen[t]then seen[t]=true;table.insert(changed,t)end end
    for _,t in ipairs(tiles)do buffer.writeu8(g.terrain,t,0);note(t)end
    ocean(g,tiles,note);self:magnitudes(g,tiles,true,note)
    local around,ordered={},{}
    local function near(t)if not around[t]then around[t]=true;table.insert(ordered,t)end end
    for _,t in ipairs(tiles)do near(t);S.neighbors(g,t,function(n)near(n);S.neighbors(g,n,near)end)end
    for _,t in ipairs(ordered)do
        local b=buffer.readu8(g.terrain,t);local impassable=band(b,128)~=0 and band(b,31)==31;local opposite=false
        if not impassable then S.neighbors(g,t,function(n)local nb=buffer.readu8(g.terrain,n)
            if not(band(nb,128)~=0 and band(nb,31)==31)and band(nb,128)~=band(b,128)then opposite=true end
        end)end
        local nextByte=band(b,191)+(opposite and 64 or 0);if nextByte~=b then buffer.writeu8(g.terrain,t,nextByte);note(t)end
    end
    local miniTiles={}
    if mini and mini~=g then
        local candidates,miniSeen={},{}
        for _,t in ipairs(tiles)do local x,y=(t%g.width)//2,(t//g.width)//2
            if x<mini.width and y<mini.height then local mt=y*mini.width+x;if not miniSeen[mt]then miniSeen[mt]=true;table.insert(candidates,mt)end end
        end
        for _,mt in ipairs(candidates)do if S.water(mini,mt)then continue end
            local x,y=mt%mini.width*2,mt//mini.width*2;local water,total=0,0
            for dy=0,1 do for dx=0,1 do if x+dx<g.width and y+dy<g.height then total+=1;if S.water(g,(y+dy)*g.width+x+dx)then water+=1 end end end end
            if water>=math.min(3,total)then buffer.writeu8(mini.terrain,mt,0);table.insert(miniTiles,mt)end
        end
        if #miniTiles>0 then ocean(mini,miniTiles,nil);self:magnitudes(mini,miniTiles,false,nil)end
    else miniTiles=table.clone(tiles)end
    return changed,miniTiles
end
return M
