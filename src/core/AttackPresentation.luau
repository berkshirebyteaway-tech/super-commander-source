local M={}
function M.route(w,owner,tile)
    local nav=w.unitSystem.nav
    if w.phase~='playing' or not nav:valid(tile) or not nav:land(tile) then return nil end
    local target=w.sim:owner(tile)
    if target==owner or w:friendly(owner,target) or w:protectedTarget(owner,target) then return nil end
    if not w:sharesLandBorder(owner,target) then return 'transport' end
    if target~=0 then return 'land' end
    local seen,stack={[tile]=true},{tile}
    while #stack>0 do
        local at=table.remove(stack)
        for _,n in ipairs(w.sim:neighbors(at)) do
            if w.sim:owner(n)==owner then return 'land' end
            if not seen[n] and w.sim:owner(n)==0 and nav:land(n) and nav:manhattan(tile,n)<=200 then
                seen[n]=true;table.insert(stack,n)
            end
        end
    end
    return 'transport'
end
function M.context(w,owner,tile)
    local result=w.unitSystem:context(owner,tile)
    result.attackRoute=M.route(w,owner,tile)
    return result
end
return M
