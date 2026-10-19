local M={}
M.maximum=9007199254740991
function M.displayInput(kind,value)
    if value==nil or value==''then return nil end
    local n=tonumber(value);if not n or n~=n or n==math.huge or n==-math.huge then return value end
    return kind=='troops'and tostring(n*10)or value
end
function M.available(state,target,kind)
    if not state or not state.player or not target then return 0 end
    local n=tonumber(kind=='gold'and state.player.gold or state.player.troops)or 0
    if n~=n then return 0 end
    n=math.clamp(n,0,M.maximum)
    if kind=='troops'then n=math.min(n,math.max(0,(target.cap or 0)-(target.troops or 0)))end
    return math.floor(n)
end
function M.amount(state,target,kind,ratio,exact)
    local max=M.available(state,target,kind)
    if exact~=nil then
        local n=tonumber(exact)
        if not n or n~=n or n==math.huge or n<1 or n%1~=0 or n>M.maximum then return nil,max end
        return math.min(n,max),max
    end
    local own=tonumber(kind=='gold'and state.player.gold or state.player.troops)or 0
    return math.min(max,math.floor(math.min(own,M.maximum)*math.clamp(ratio or 1/3,0,1))),max
end
return M
