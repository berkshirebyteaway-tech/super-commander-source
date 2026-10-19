local M={scale=.4,surfaceY=20}
function M.toWorld(tile,width,height)
    return ((tile%width)+.5-width/2)*M.scale,M.surfaceY,(math.floor(tile/width)+.5-height/2)*M.scale
end
function M.toTile(x,z,width,height)
    local xx,yy=math.floor(x/M.scale+width/2),math.floor(z/M.scale+height/2)
    if xx<0 or yy<0 or xx>=width or yy>=height then return nil end
    return yy*width+xx
end
return M
