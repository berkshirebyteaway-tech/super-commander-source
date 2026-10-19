local M={}
function M.card(w,h,rank,width,height,bottom)
    width=math.min(width,w-24)
    local x,y=w-width-12,rank and rank.y+rank.h+8 or 8
    local limit=math.min(h-12,bottom or h-12)
    if y+height>limit and rank and rank.x-width-8>=12 then
        x,y=rank.x-width-8,rank.y
    end
    return {x=x,y=y,w=width,h=height}
end
function M.avoidDock(card,dock)
    local x,y,w,h=card.x,card.y,card.w,card.h
    for _,r in ipairs(dock or {})do
        if x<r.x+r.w and x+w>r.x and y<r.y+r.h and y+h>r.y then
            local left=r.x-w-8
            if left>=12 then x=math.min(x,left)end
        end
    end
    return {x=x,y=y,w=w,h=h}
end
return M
