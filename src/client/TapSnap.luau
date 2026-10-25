local Terrain=require(script.Parent.Parent.Core.Terrain)
local M={}
M.pixels={mouse=8,touch=22}
M.maxTiles=40
function M.land(tile,at,map,renderer,owners,touch)
    if not tile or not map or not renderer then return nil end
    local terrain=map.terrain
    local function land(t)local b=buffer.readu8(terrain,t);return Terrain.isLand(b)and not Terrain.isImpassable(b)end
    if land(tile)then return nil end
    local width,height=map.meta.width,map.meta.height
    local x0,y0=tile%width,tile//width
    local here=renderer:projectXY(x0,y0);local step=(renderer:projectXY(x0+1,y0)-here).Magnitude
    if here.X<=-2000 or step<=0 then return nil end
    local px=touch and M.pixels.touch or M.pixels.mouse;local r=math.min(M.maxTiles,math.ceil(px/step))
    local best,distance=nil,math.huge
    for dy=-r,r do for dx=-r,r do
        local x,y=x0+dx,y0+dy
        if x>=0 and x<width and y>=0 and y<height and (dx*dx+dy*dy)*step*step<=px*px*2.25 then
            local t=y*width+x
            if (owners[t]or 0)~=1 and land(t)then
                local d=(renderer:projectXY(x,y)-at).Magnitude
                if d<=px and d<distance then best,distance=t,d end
            end
        end
    end end
    return best
end
return M
