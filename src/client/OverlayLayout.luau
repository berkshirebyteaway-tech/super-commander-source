local M={}
function M.area(a,b)
    return math.max(0,math.min(a.x+a.w,b.x+b.w)-math.max(a.x,b.x))*math.max(0,math.min(a.y+a.h,b.y+b.h)-math.max(a.y,b.y))
end
function M.place(preferred,w,h,blocks)
    local width,height=math.min(preferred.w,w-16),math.min(preferred.h,h-16)
    local best,score;local seen={};local tested=0
    local function candidate(x,y)
        if tested>=128 then return end;tested+=1
        x=math.clamp(x,8,math.max(8,w-width-8));y=math.clamp(y,8,math.max(8,h-height-8))
        local key=math.floor(x)..':'..math.floor(y);if seen[key]then return end;seen[key]=true
        local r={x=x,y=y,w=width,h=height};local overlap=0
        for i,b in ipairs(blocks or {})do if i>32 then break end;overlap+=M.area(r,{x=b.x-6,y=b.y-6,w=b.w+12,h=b.h+12})end
        local displacement=(x-preferred.x)^2+(y-preferred.y)^2
        local value=overlap*1000000+displacement
        if not score or value<score then best=r;score=value;best.clear=overlap==0 end
    end
    candidate(preferred.x,preferred.y)
    for i,b in ipairs(blocks or {})do
        if i>32 then break end
        candidate(preferred.x,b.y-height-8);candidate(preferred.x,b.y+b.h+8)
        candidate(b.x-width-8,preferred.y);candidate(b.x+b.w+8,preferred.y)
        candidate(b.x-width-8,b.y+b.h+8);candidate(b.x+b.w+8,b.y-height-8)
    end
    candidate(8,8);candidate(w-width-8,8);candidate(8,h-height-8);candidate(w-width-8,h-height-8)
    return best
end
return M
