--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local T=if script then require(script.Parent.Terrain)else require('./Terrain')
local M={}
local budgets=setmetatable({},{__mode='k'})
function M.utf16Length(name)
    local n=0;for _,c in utf8.codes(name)do n+=c>65535 and 2 or 1 end;return math.max(1,n)
end
function M.factor(size)
    return size<25 and 1 or size<50 and 2 or size<100 and 4 or size<250 and 8 or size<500 and 16 or 32
end
function M.calculate(sim,p,name)
    if p.tiles.size==0 then return {count=0,tick=sim.ticks,name=name}end
    local w,h=sim.width,sim.height;local live=p.tiles.index;local primary,bounds,first
    local ownership=sim.owners;local id=p.id
    local scratch=M.scratch;local n=w*h
    if not scratch or scratch.n<n then scratch={n=n,gen=0,seen=buffer.create(n*4),queue={}};M.scratch=scratch end
    scratch.gen+=1;if scratch.gen>=4294967295 then buffer.fill(scratch.seen,0,0);scratch.gen=1 end
    local gen,seen,queue=scratch.gen,scratch.seen,scratch.queue;local readu32,writeu32=buffer.readu32,buffer.writeu32
    local len,primaryFrom,primarySize=0,0,0
    for start in pairs(live)do
        if readu32(seen,start*4)==gen then continue end
        writeu32(seen,start*4,gen);len+=1;queue[len]=start;local from=len;local head=len
        local minX,maxX,minY,maxY=start%w,start%w,start//w,start//w
        local seed=start
        while head<=len do
            local t=queue[head];head+=1;local x,y=t%w,t//w
            if x<minX then minX=x end;if x>maxX then maxX=x end;if y<minY then minY=y end;if y>maxY then maxY=y end;if t<seed then seed=t end
            if x>0 then local m=t-1;if (ownership and ownership[m+1]==id or not ownership and live[m])and readu32(seen,m*4)~=gen then writeu32(seen,m*4,gen);len+=1;queue[len]=m end end
            if x<w-1 then local m=t+1;if (ownership and ownership[m+1]==id or not ownership and live[m])and readu32(seen,m*4)~=gen then writeu32(seen,m*4,gen);len+=1;queue[len]=m end end
            if y>0 then local m=t-w;if (ownership and ownership[m+1]==id or not ownership and live[m])and readu32(seen,m*4)~=gen then writeu32(seen,m*4,gen);len+=1;queue[len]=m end end
            if y<h-1 then local m=t+w;if (ownership and ownership[m+1]==id or not ownership and live[m])and readu32(seen,m*4)~=gen then writeu32(seen,m*4,gen);len+=1;queue[len]=m end end
        end
        local size=len-from+1
        if not primary or size>primarySize or size==primarySize and seed<first then primary=true;primaryFrom=from;primarySize=size;bounds={minX,maxX,minY,maxY};first=seed end
    end
    if not primary then return {count=0,tick=sim.ticks,name=name}end
    local minX,maxX,minY,maxY=table.unpack(bounds)
    local step=M.factor(math.min(maxX-minX,maxY-minY))
    local gx0,gy0=math.floor(minX/step),math.floor(minY/step)
    local cols,rows=math.floor(maxX/step)-gx0+1,math.floor(maxY/step)-gy0+1
    local heights=table.create(cols,0);local rect={x=0,y=0,w=1,h=1,area=0}
    local owners,tb,terrain,fallout,id=sim.owners,sim.tb,sim.terrain,sim.fallout,p.id;local band=bit32.band
    local stack,top={},0
    for row=0,rows-1 do
        local y=(gy0+row)*step
        for col=0,cols-1 do
            local t=y*w+(gx0+col)*step;local b=if tb then buffer.readu8(tb,t) else terrain[t+1]
            local own=if owners then owners[t+1] else sim:owner(t)
            local allowed=own==id or band(b,64)~=0 or band(b,128)==0 and band(b,32)~=0 and band(b,31)<10 or fallout[t]~=nil
            heights[col+1]=allowed and heights[col+1]+1 or 0
        end
        top=0
        for i=1,cols+1 do
            local height=i<=cols and heights[i]or 0
            while top>0 and height<heights[stack[top]]do
                local height2=heights[stack[top]];top-=1;local left=top>0 and stack[top]+1 or 1;local width=i-left
                if width*height2>rect.area then rect={x=left-1,y=row-height2+1,w=width,h=height2,area=width*height2}end
            end
            top+=1;stack[top]=i
        end
    end
    local width,height=rect.w*step,rect.h*step
    local size=math.min(width/M.utf16Length(name)*2,height/3)
    local x,y=minX+(rect.x+rect.w/2)*step,minY+(rect.y+rect.h/2)*step-size/3
    local tile,best=queue[primaryFrom],math.huge
    for i=primaryFrom,primaryFrom+primarySize-1 do local t=queue[i];local d=(t%w-x)^2+(t//w-y)^2;if d<best or d==best and t<tile then tile=t;best=d end end
    return {tile=tile,size=size,width=width,height=height,clusterTiles=primarySize,count=p.tiles.size,tick=sim.ticks,name=name}
end
function M.environmentRevision(world)
    local units=world.unitSystem or {};local terrain=units.terrainRevision or 0;local fallout=world.falloutTiles or 0
    local stable=terrain==0 and fallout==0
    if stable then return world.ownershipRevision,true end
    return tostring(world.ownershipRevision)..':'..terrain..':'..fallout..':'..(units.effectId or 0),false
end
function M.get(cache,sim,p,name,revision,stableEnvironment)
    local old=cache[p.id]
    local membership=stableEnvironment==true and p.tiles.revision or nil
    local changed=membership~=nil and (not old or old.membershipRevision~=membership) or membership==nil and (not old or old.membershipRevision~=nil or old.revision~=revision)
    local urgent=not old or old.name~=name or old.tile and sim:owner(old.tile)~=p.id
    local stale=not urgent and (old.count~=p.tiles.size or changed)and (sim.ticks-old.tick>=10 or math.abs(p.tiles.size-old.count)>math.max(8,old.count*.2))
    local budget=budgets[cache]
    if stale and budget and budget.left<=0 then return old end
    if urgent or stale then
        old=M.calculate(sim,p,name);old.revision=revision;old.membershipRevision=membership;cache[p.id]=old
        if budget then budget.left-=p.tiles.size end
    end
    return old
end
M.snapshotTiles=12000
function M.limit(cache,tiles)budgets[cache]=tiles and {left=tiles}or nil end
function M.pixels(worldSize,pixelsPerTile,own)
    return math.clamp(math.floor((worldSize or 0)*pixelsPerTile+.5),own and 16 or 14,32)
end
return M
