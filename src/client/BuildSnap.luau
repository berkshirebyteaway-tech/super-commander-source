local Terrain=require(script.Parent.Parent.Core.Terrain)
local M={}
local MIN_GAP2=225
local function land(terrain,t)local b=buffer.readu8(terrain,t);return Terrain.isLand(b)and not Terrain.isImpassable(b)end
local function water(terrain,t)return not Terrain.isLand(buffer.readu8(terrain,t))end
function M.find(kind,tile,ctx)
    local w,h,owners,me=ctx.width,ctx.height,ctx.owners,ctx.me or 1
    if not tile or tile<0 or tile>=w*h or owners[tile]~=me then return nil end
    local cx,cy=tile%w,tile//w
    if ctx.upgradable and ctx.upgradable[kind]then
        local best,bestD=nil,math.huge
        for _,u in ipairs(ctx.units or {})do if u.kind==kind and u.active~=false then
            local dx,dy=u.tile%w-cx,u.tile//w-cy;local d=dx*dx+dy*dy;if d<=MIN_GAP2 and d<bestD then best,bestD=u,d end
        end end
        if best and best.owner==me and not best.building then return best.tile,true end
    end
    local near={}
    for _,u in ipairs(ctx.units or {})do if u.active~=false and ctx.structures[u.kind]then
        local dx,dy=u.tile%w-cx,u.tile//w-cy;if dx*dx+dy*dy<900 then table.insert(near,{u.tile%w,u.tile//w})end
    end end
    local function blocked(x,y)
        for _,u in ipairs(near)do local dx,dy=u[1]-x,u[2]-y;if dx*dx+dy*dy<MIN_GAP2 then return true end end
        return false
    end
    local seen={[tile]=true};local stack={tile};local best,bestD=nil,math.huge
    local port=kind=="Port";local terrain=ctx.terrain
    while #stack>0 do
        local t=table.remove(stack);local x,y=t%w,t//w;local dx,dy=x-cx,y-cy
        local d=port and math.abs(dx)+math.abs(dy)or dx*dx+dy*dy
        if d<bestD and not blocked(x,y)then
            local ok=true
            if port then
                ok=d<=20 and land(terrain,t)
                if ok then
                    ok=false
                    if t>=w and water(terrain,t-w)or t<(h-1)*w and water(terrain,t+w)or x>0 and water(terrain,t-1)or x<w-1 and water(terrain,t+1)then ok=true end
                end
            end
            if ok then best,bestD=t,d end
        end
        for _,n in ipairs({t-w,t+w,x>0 and t-1 or -1,x<w-1 and t+1 or -1})do
            if n>=0 and n<w*h and not seen[n]and owners[n]==me then
                local nx,ny=n%w-cx,n//w-cy
                if nx*nx+ny*ny<MIN_GAP2 then seen[n]=true;table.insert(stack,n)end
            end
        end
    end
    return best,false
end
function M.guess(kind,tile,state,owners,map,rules,info,affordable)
    local at,fits=tile,info~=nil and kind=="Warship" and info.kind==3
    if kind~="Warship" and state and map then
        local m=map.meta
        at=M.find(kind,tile,{width=m.width,height=m.height,terrain=map.terrain,owners=owners,units=state.units,structures=rules.structures,upgradable=rules.upgradable})
        fits=at~=nil;at=at or tile
    end
    return {tile=at,valid=fits and affordable(state and state.costs[kind]or "0")==true,guess=true}
end
return M
