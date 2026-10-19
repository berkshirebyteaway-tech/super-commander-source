local M={}
function M.points(tiles,width)
    local pts={}
    for i,t in ipairs(tiles)do pts[i]=Vector2.new(t%width+.5,t//width+.5)end
    return pts
end
return M
