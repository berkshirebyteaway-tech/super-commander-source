local M={}
M.priority={MissileSilo=6,SAMLauncher=5,Port=4,City=3,Factory=2,DefensePost=1}
function M.band(span)
    if span>=260 then return 'far',14 elseif span>=110 then return 'mid',16 else return 'close',18 end
end
function M.gridStep(width,height)
    local dimension=math.max(width,height)
    return dimension<=600 and 32 or dimension<=1600 and 64 or 128
end
function M.order(a,b,selected)
    if (a.id==selected)~=(b.id==selected)then return a.id==selected end
    local pa,pb=M.priority[a.kind]or 0,M.priority[b.kind]or 0
    if pa~=pb then return pa>pb end
    if (a.owner==1)~=(b.owner==1)then return a.owner==1 end
    if (a.level or 1)~=(b.level or 1)then return (a.level or 1)>(b.level or 1)end
    return a.id<b.id
end
function M.occupancy(cell,reuse)
    if reuse then table.clear(reuse.buckets);reuse.cell=cell or 48;return reuse end
    return {cell=cell or 48,buckets={}}
end
local function bucket(xx,yy)return xx*1048576+yy end
function M.reserve(grid,x,y,width,height,padding)
    local pad=padding or 0;local r={x=x-width/2-pad,y=y-height/2-pad,w=width+pad*2,h=height+pad*2}
    local x0,x1=math.floor(r.x/grid.cell),math.floor((r.x+r.w)/grid.cell)
    local y0,y1=math.floor(r.y/grid.cell),math.floor((r.y+r.h)/grid.cell)
    for xx=x0,x1 do for yy=y0,y1 do
        local list=grid.buckets[bucket(xx,yy)]
        if list then for _,o in ipairs(list)do
            if r.x<o.x+o.w and o.x<r.x+r.w and r.y<o.y+o.h and o.y<r.y+r.h then return false end
        end end
    end end
    for xx=x0,x1 do for yy=y0,y1 do
        local key=bucket(xx,yy);local list=grid.buckets[key];if not list then list={};grid.buckets[key]=list end;table.insert(list,r)
    end end
    return true
end
function M.claim(grid,x,y,width,height,padding)
    local pad=padding or 0;local r={x=x-width/2-pad,y=y-height/2-pad,w=width+pad*2,h=height+pad*2}
    for xx=math.floor(r.x/grid.cell),math.floor((r.x+r.w)/grid.cell)do for yy=math.floor(r.y/grid.cell),math.floor((r.y+r.h)/grid.cell)do
        local key=bucket(xx,yy);local list=grid.buckets[key];if not list then list={};grid.buckets[key]=list end;table.insert(list,r)
    end end
end
function M.status(u,tick)
    if u.deleteAt then return 'deleting',math.clamp((u.deleteAt-tick)/300,0,1)end
    if u.building then return 'building',math.clamp(1-(u.remaining or 0)/math.max(1,u.duration or 1),0,1)end
    if u.readyMissiles~=nil then
        local ready=math.clamp(u.readyMissiles,0,u.level or 1)
        return ready==0 and 'reloading'or 'ready',ready/math.max(1,u.level or 1)
    end
    if u.health and u.maxHealth and u.health<u.maxHealth then return 'damaged',math.clamp(u.health/math.max(1,u.maxHealth),0,1)end
    return 'ready',1
end
function M.threat(u,factions)
    local f=factions and factions[u.owner]
    return u.kind=='MissileSilo'and u.owner~=1 and not(f and(f.allied or f.teammate))
end
function M.labelPriority(a,b,selected)
    local function rank(f)return f.id==selected and 4 or f.combatState and 3 or f.allied and 2 or f.kind~='BOT'and 1 or 0 end
    local aRank,bRank=rank(a),rank(b);if aRank~=bRank then return aRank>bRank end
    if a.tiles~=b.tiles then return a.tiles>b.tiles end
    return a.id<b.id
end
M.noticePriority={rocketWarning=5,conquest=4,betrayal=4,assault=4,detonate=4,intercept=4,intercepted=4,rankUp=3,firstCity=3,eliminated=3,tiles=2,allianceEnded=3,complete=2,upgraded=2,allied=2,support=2,milestone=2,start=2,landing=1,shipReady=1}
function M.enqueue(queue,kind,name,now)
    local priority=M.noticePriority[kind]or 0
    for _,e in ipairs(queue)do if e.kind==kind then e.count+=1;e.name=name or e.name;return true end end
    if #queue>=4 then
        if priority<=(queue[#queue].priority or 0)then return false end
        table.remove(queue)
    end
    local e={kind=kind,name=name,count=1,at=now,priority=priority}
    local at=#queue+1
    for i,o in ipairs(queue)do if priority>o.priority then at=i;break end end
    table.insert(queue,at,e);return true
end
return M
