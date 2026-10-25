local M={}
function M.index(rails,slice,water,previous)
    local adjacency,segments,shown,fresh={},{},{},{}
    local function connect(a,b)
        local v=adjacency[a];if not v then v={};adjacency[a]=v end
        if not table.find(v,b)then table.insert(v,b)end
    end
    for _,r in ipairs(rails or {})do
        local tiles=r.tiles
        for i=2,#tiles do local a,b=tiles[i-1],tiles[i];connect(a,b);connect(b,a)end
        local start,bridge;local new=false
        for i=2,#tiles do
            local a,b=tiles[i-1],tiles[i]
            local key=math.min(a,b)*8388608+math.max(a,b)
            if shown[key]then
                if start and start<i-1 then table.insert(segments,{tiles[start],tiles[i-1],rail=r.id,i0=start,i1=i-1,bridge=bridge==true})end;start=nil
            else
                shown[key]=true;if previous and not previous[key]then new=true end
                local wet=water~=nil and (water(a)or water(b))
                if start and (b-a~=tiles[start+1]-tiles[start]or wet~=bridge)then table.insert(segments,{tiles[start],a,rail=r.id,i0=start,i1=i-1,bridge=bridge==true});start=i-1 end
                if not start then start=i-1 end
                bridge=wet
            end
        end
        if start and start<#tiles then table.insert(segments,{tiles[start],tiles[#tiles],rail=r.id,i0=start,i1=#tiles,bridge=bridge==true})end
        if new then table.insert(fresh,r)end
        if slice and os.clock()>slice.deadline then coroutine.yield()end
    end
    return adjacency,segments,shown,fresh
end
function M.between(graph,first,last)
    if first==last then return {first}end
    if not graph[first]or not graph[last]then return nil end
    local queue={first};local seen={[first]=true};local parent={};local depth={[first]=0};local head=1
    while head<=#queue and head<=128 do
        local t=queue[head];head+=1
        if depth[t]>=24 then continue end
        for _,n in ipairs(graph[t])do if not seen[n]then
            seen[n]=true;parent[n]=t;depth[n]=depth[t]+1
            if n==last then
                local reverse={last};while parent[n]do n=parent[n];table.insert(reverse,n)end
                local path={};for i=#reverse,1,-1 do table.insert(path,reverse[i])end;return path
            end
            table.insert(queue,n)
        end end
    end
    return nil
end
return M
