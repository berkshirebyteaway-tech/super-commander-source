--!native
local M={}
local clusters=setmetatable({},{__mode='k'})
function M.positions(sim,a)
    if not a.attackActive or a.retreating or a.retreated or not a.border then return {} end
    local cached=clusters[a]
    if cached and cached.sim==sim and cached.tick==sim.ticks then return cached.positions end
    local members,ordered={},{}
    local function add(tile)
        if sim:owner(tile)~=a.target then return end
        for _,n in ipairs(sim:neighbors(tile))do
            if sim:owner(n)==a.owner then members[tile]=true;table.insert(ordered,tile);return end
        end
    end
    if a.border.index then for tile in pairs(a.border.index)do add(tile)end
    else for _,tile in ipairs(a.border.dense or {})do if tile~=false then add(tile)end end end
    table.sort(ordered)
    local visited,parts={},{}
    for _,start in ipairs(ordered)do
        if visited[start]then continue end
        local queue={start};visited[start]=true;local i,x,y=1,0,0
        while i<=#queue do
            local t=queue[i];i+=1;local tx,ty=t%sim.width,math.floor(t/sim.width);x+=tx;y+=ty
            for dy=-1,1 do for dx=-1,1 do
                local nx,ny=tx+dx,ty+dy
                if (dx~=0 or dy~=0)and nx>=0 and nx<sim.width and ny>=0 and ny<sim.height then
                    local n=ny*sim.width+nx
                    if members[n]and not visited[n]then visited[n]=true;table.insert(queue,n)end
                end
            end end
        end
        x/=#queue;y/=#queue;local best,distance=queue[1],math.huge
        for _,t in ipairs(queue)do local d=(t%sim.width-x)^2+(math.floor(t/sim.width)-y)^2;if d<distance or d==distance and t<best then best,distance=t,d end end
        table.insert(parts,{tile=best,size=#queue})
    end
    table.sort(parts,function(a,b)return a.size>b.size or a.size==b.size and a.tile<b.tile end)
    local positions={}
    for _,part in ipairs(parts)do if part.size>=30 or #parts==1 then table.insert(positions,part.tile);if #positions==2 then break end end end
    if #positions==0 and parts[1]then positions[1]=parts[1].tile end
    clusters[a]={sim=sim,tick=sim.ticks,positions=positions};return positions
end
function M.front(sim,a,offset)
    if not a.attackActive or a.retreating or a.retreated or not a.border then return nil end
    if a.heap and a.heap.len>0 then
        for i=0,math.min(a.heap.len,64)-1 do
            local tile=a.heap.tiles[((offset or 0)+i)%a.heap.len]
            if tile and sim:owner(tile)==a.target then
                for _,adjacent in ipairs(sim:neighbors(tile)) do if sim:owner(adjacent)==a.owner then return tile end end
            end
        end
    end
    local dense=a.border.dense;local n=#dense
    if n==0 then return nil end
    for i=1,math.min(n,96) do
        local tile=dense[((offset or 0)+i-1)%n+1]
        if tile~=false and sim:owner(tile)==a.target then
            for _,adjacent in ipairs(sim:neighbors(tile)) do if sim:owner(adjacent)==a.owner then return tile end end
        end
    end
    return nil
end
function M.snapshot(sim,viewer,swap)
    local out={};local count=0
    for pass=1,2 do
        for _,p in ipairs(sim.players) do for _,a in ipairs(p.outgoing) do
            local relevant=a.owner==viewer or a.target==viewer
            if a.target==0 or (pass==1)~=relevant then continue end
            local tile=M.front(sim,a,math.floor(sim.ticks/4)*13)
            if tile then
                count+=1;out[count]={id=a.id,tile=tile,owner=swap(a.owner),target=swap(a.target)}
                if count>=24 then return out end
            end
        end end
    end
    return out
end
return M
