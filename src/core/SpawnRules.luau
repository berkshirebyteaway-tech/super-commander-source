-- SPDX-License-Identifier: AGPL-3.0-only
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local AI=if script then require(script.Parent.TribeAI) else require("./TribeAI")
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local M={}
local stencil={}
do
    local seen,stack={},{}
    local function visit(x,y)
        local k=(y+4)*9+x+4
        if not seen[k] and (x+.5)^2+(y+.5)^2<=16 then
            seen[k]=true;table.insert(stencil,{x,y});table.insert(stack,{x,y})
        end
    end
    visit(0,0)
    while #stack>0 do local p=table.remove(stack);local x,y=p[1],p[2]
        visit(x,y-1);visit(x,y+1);visit(x-1,y);visit(x+1,y)
    end
end
function M.tiles(world,tile,all)
    local width,height=world.map.meta.width,world.map.meta.height
    local cx,cy=tile%width,tile//width
    if cx>=4 and cx<width-4 and cy>=4 and cy<height-4 then
        local valid={}
        for _,o in ipairs(stencil)do
            local t=tile+o[1]+o[2]*width;local byte=world.sim.terrain[t+1]
            if world.sim:owner(t)~=0 or not T.isLand(byte) or T.isImpassable(byte) then
                if all then return nil end
            else table.insert(valid,t)end
        end
        return valid
    end
    local w=world.map.meta.width;local x,y=tile%w-.5,math.floor(tile/w)-.5
    local tiles=world:flood(tile,function(t) local dx,dy=t%w-x,math.floor(t/w)-y;return dx*dx+dy*dy<=16 end)
    local valid={}
    for _,t in ipairs(tiles) do
        local byte=world.sim.terrain[t+1]
        if world.sim:owner(t)~=0 or not T.isLand(byte) or T.isImpassable(byte) then
            if all then return nil end
        else table.insert(valid,t) end
    end
    return valid
end
function M.random(world,key,gameID,area)
    local r=R.new(AI.hash(key)+AI.hash(gameID))
    local w,h=world.map.meta.width,world.map.meta.height
    for tries=1,1000 do
        local x,y
        if area then x,y=r:nextInt(area.x,area.x+area.w),r:nextInt(area.y,area.y+area.h)else x,y=r:nextInt(0,w),r:nextInt(0,h)end
        if x>=w or y>=h then continue end
        local t=y*w+x
        if not T.isLand(world.sim.terrain[t+1]) or world.sim:owner(t)~=0 then continue end
        local border=false
        for _,n in ipairs(world.sim:neighbors(t)) do if world.sim:owner(n)~=0 then border=true;break end end
        if border then continue end
        local near=false
        if tries<=750 then
            for _,p in ipairs(world.sim.players) do
                if p.spawnTile and math.abs(p.spawnTile%w-x)+math.abs(math.floor(p.spawnTile/w)-y)<30 then near=true;break end
            end
        end
        if near then continue end
        local tiles=M.tiles(world,t,true)
        if tiles then return t,tiles end
    end
    return nil
end
return M
