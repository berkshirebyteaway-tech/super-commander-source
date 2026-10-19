local M={version=2,maxLevel=100}
function M.legacyCost(level)return 120+8*(level-1)end
function M.cost(level)return math.ceil(M.legacyCost(level)*(27+math.max(0,level-10))/27)end
function M.total(cost)
    local n=0;for l=1,M.maxLevel-1 do n+=(cost or M.cost)(l)end;return n
end
function M.migrate(xp)
    local level,oldBase,newBase=1,0,0
    while level<M.maxLevel and xp>=oldBase+M.legacyCost(level)do oldBase+=M.legacyCost(level);newBase+=M.cost(level);level+=1 end
    if level==M.maxLevel then return newBase+(xp-oldBase)end
    return newBase+math.floor((xp-oldBase)*M.cost(level)/M.legacyCost(level))
end
return M
