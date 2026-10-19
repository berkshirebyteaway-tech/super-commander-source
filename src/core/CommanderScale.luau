local M={maximum=2}
function M.target(tiles,land,troops)
    if tiles<=0 then return 1 end
    local territory=math.clamp(tiles/math.max(1,land)/.15,0,1)
    local army=math.clamp(math.log(1+math.max(0,troops)/25000)/math.log(17),0,1)
    return math.min(M.maximum,1+.65*territory+.35*army)
end
function M.approach(current,target,dt)
    return current+(target-current)*(1-math.exp(-math.max(0,dt)/2))
end
return M
