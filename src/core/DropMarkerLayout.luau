local M={}
function M.place(x,y,depth,w,h,touch,mini)
    local left,right,top,bottom=22,math.max(22,w-22),22,math.max(22,h-24)
    local cx,cy=w*.5,(top+bottom)*.5
    if depth<=0 then x=cx-(x-cx);y=cy-(y-cy)end
    local targetX,targetY=x,y;local dx,dy=x-cx,y-cy
    local inside=depth>0 and x>=left and x<=right and y>=top and y<=bottom
    if not inside then
        local sx=math.abs(dx)>1e-6 and (dx>0 and right-cx or cx-left)/math.abs(dx)or math.huge
        local sy=math.abs(dy)>1e-6 and (dy>0 and bottom-cy or cy-top)/math.abs(dy)or math.huge
        local scale=math.min(sx,sy);if scale==math.huge then scale=0 end
        x=cx+dx*scale;y=cy+dy*scale
    end
    local width=math.min(touch and 260 or 390,w-(touch and 148 or 24))
    local blockers={{x=touch and w-width-12 or (w-width)/2,y=h-(touch and 88 or 80),w=width,h=touch and 76 or 64}}
    if touch then table.insert(blockers,{x=0,y=h-148,w=148,h=148})end
    if mini then table.insert(blockers,mini)end
    for _,r in ipairs(blockers)do
        local x0,x1,y0,y1=r.x-18,r.x+r.w+18,r.y-18,r.y+r.h+18
        if x>x0 and x<x1 and y>y0 and y<y1 then
            local best,dist;for _,p in ipairs({{x0,y},{x1,y},{x,y0},{x,y1}})do
                if p[1]>=left and p[1]<=right and p[2]>=top and p[2]<=bottom then
                    local d=(p[1]-x)^2+(p[2]-y)^2;if not dist or d<dist then best=p;dist=d end
                end
            end
            if best then x,y=best[1],best[2];inside=false end
        end
    end
    return {x=math.clamp(x,left,right),y=math.clamp(y,top,bottom),offscreen=not inside,angle=math.deg(math.atan2(targetY-y,targetX-x))+90}
end
return M
