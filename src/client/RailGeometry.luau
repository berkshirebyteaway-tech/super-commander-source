local M={}
function M.index(rails,slice)
    local adjacency,segments,shown={},{},{}
    local function connect(a,b)
        local v=adjacency[a];if not v then v={};adjacency[a]=v end
        if not table.find(v,b)then table.insert(v,b)end
    end
    for _,r in ipairs(rails or {})do
        for i=2,#r.tiles do local a,b=r.tiles[i-1],r.tiles[i];connect(a,b);connect(b,a)end
        local start
        for i=2,#r.tiles do
            local a,b=r.tiles[i-1],r.tiles[i]
            local key=math.min(a,b)*8388608+math.max(a,b)
            if shown[key]then
                if start and start<i-1 then table.insert(segments,{r.tiles[start],r.tiles[i-1]})end;start=nil
            else
                shown[key]=true
                if start and b-a~=r.tiles[start+1]-r.tiles[start]then table.insert(segments,{r.tiles[start],a});start=i-1 end
                start=start or i-1
            end
        end
        if start and start<#r.tiles then table.insert(segments,{r.tiles[start],r.tiles[#r.tiles]})end
        if slice and os.clock()>slice.deadline then coroutine.yield()end
    end
    return adjacency,segments
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
