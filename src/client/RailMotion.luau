local M={}
function M.route(start,tiles,position)
    local points={start};local lengths={0};local total=0
    for _,tile in ipairs(tiles or {})do
        local p=position(tile);local distance=(p-points[#points]).Magnitude
        if distance>.0001 then total+=distance;table.insert(points,p);table.insert(lengths,total)end
    end
    return {points=points,lengths=lengths,total=total}
end
function M.sample(route,t)
    local distance=math.clamp(t,0,1)*route.total
    for i=2,#route.points do
        if distance<=route.lengths[i]then
            local a,b=route.points[i-1],route.points[i]
            local fraction=(distance-route.lengths[i-1])/(route.lengths[i]-route.lengths[i-1])
            return a:Lerp(b,fraction),(b-a).Unit
        end
    end
    return route.points[#route.points],nil
end
return M
