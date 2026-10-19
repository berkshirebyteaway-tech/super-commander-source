local M={}
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
function M.bounds(w,h,bottomInset,topInset,rightInset)
    local left,right=34,w-(rightInset or 0)-34;local bottom=h-(bottomInset or 160)-34
    if right<left or bottom<34 then return nil end
    return {left=left,right=right,top=math.min(bottom,math.max(34,topInset or 96)),bottom=bottom}
end
function M.point(x,y,b)
    if not b or not finite(x)or not finite(y)then return nil end
    if x>=b.left and x<=b.right and y>=b.top and y<=b.bottom then return {x=x,y=y,edge=false}end
    local cx,cy=(b.left+b.right)/2,(b.top+b.bottom)/2;local dx,dy=x-cx,y-cy
    local t=1
    if dx>0 then t=math.min(t,(b.right-cx)/dx)elseif dx<0 then t=math.min(t,(b.left-cx)/dx)end
    if dy>0 then t=math.min(t,(b.bottom-cy)/dy)elseif dy<0 then t=math.min(t,(b.top-cy)/dy)end
    return {x=math.clamp(cx+dx*t,b.left,b.right),y=math.clamp(cy+dy*t,b.top,b.bottom),edge=true,angle=math.atan2(dy,dx)}
end
function M.place(points,w,h,bottomInset,topInset,rightInset)
    local b=M.bounds(w,h,bottomInset,topInset,rightInset);local out={}
    for i,p in ipairs(points)do
        local at=M.point(p.x,p.y,b)
        if at and at.edge then
            local vertical=at.x<=b.left+.1 or at.x>=b.right-.1
            local sign=vertical and (at.x<=b.left+.1 and 1 or -1)or(at.y<=b.top+.1 and 1 or -1)
            local function available(x,y)
                if x<b.left or x>b.right or y<b.top or y>b.bottom then return false end
                for _,other in pairs(out)do if other and math.abs(other.x-x)<46 and math.abs(other.y-y)<46 then return false end end
                return true
            end
            local found=false
            for column=0,5 do
                for _,offset in ipairs({0,48,-48,96,-96,144,-144,192,-192,240,-240})do
                    local x=at.x+(vertical and column*48*sign or offset);local y=at.y+(vertical and offset or column*48*sign)
                    if available(x,y)then at.x,at.y=x,y;found=true;break end
                end
                if found then break end
            end
            at.angle=math.atan2(p.y-at.y,p.x-at.x)
        end
        out[i]=at or false
    end
    return out
end
return M
