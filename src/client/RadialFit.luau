local M={}
local TAU=math.pi*2
local STEPS={0,1,-1,2,-2,3,-3,4,-4,5,-5,6}
local function hits(r,blocks,w,h)
    if r.x<4 or r.y<4 or r.x+r.w>w-4 or r.y+r.h>h-4 then return true end
    for _,b in ipairs(blocks)do
        if r.x<b.x+b.w and b.x<r.x+r.w and r.y<b.y+b.h and b.y<r.y+r.h then return true end
    end
    return false
end
function M.rects(list,origin,scale)
    local out={}
    for _,o in pairs(list)do
        if typeof(o)=='Instance'and o:IsA('GuiObject')and o.Visible then
            local p,s=(o.AbsolutePosition-origin)/scale,o.AbsoluteSize/scale
            if s.X>0 and s.Y>0 then table.insert(out,{x=p.X,y=p.Y,w=s.X,h=s.Y})end
        end
    end
    return out
end
function M.turn(slots,primary,anchor,radius,size,close,blocks,w,h,pinned)
    local items={}
    for _,slot in ipairs(slots)do
        if slot[1]==pinned and slot[1]~=primary and slot[1].Visible then
            local x,y=anchor.X+slot[2]*radius,anchor.Y+slot[3]*radius;local r={x=x-size/2,y=y-size/2,w=size,h=size+4}
            if not hits(r,blocks,w,h)then blocks=table.clone(blocks);table.insert(blocks,r);continue end
        end
        if slot[1]~=primary and slot[1].Visible then table.insert(items,slot)end
    end
    local closeItem={false,close.X,close.Y};table.insert(items,closeItem)
    local function blockedAt(angle,k)
        local x,y=anchor.X+math.cos(angle)*radius*(k or 1),anchor.Y+math.sin(angle)*radius*(k or 1)
        return hits({x=x-size/2,y=y-size/2,w=size,h=size+4},blocks,w,h)
    end
    local function angleOf(item)return math.atan2(item[3],item[2])end
    local function place(item,angle,k)item[2],item[3]=math.cos(angle)*(k or 1),math.sin(angle)*(k or 1)end
    local best,bestCount=0,math.huge
    for _,step in ipairs(STEPS)do
        local turn=step*math.pi/6;local n=0
        for _,item in ipairs(items)do if blockedAt(angleOf(item)+turn)then n+=1 end end
        if n<bestCount then best,bestCount=turn,n end
        if n==0 then break end
    end
    if bestCount>0 then
        local n,samples=#items,72
        for _,k in ipairs({1,1.15,1.3,1.45})do
            local free={}
            for i=0,samples-1 do free[i]=not blockedAt(i/samples*TAU,k)end
            local runStart,runLen=nil,0
            for i=0,samples-1 do
                if free[i]and not free[(i-1)%samples]then
                    local len=0;while len<samples and free[(i+len)%samples]do len+=1 end
                    if len>runLen then runStart,runLen=i,len end
                end
            end
            if runLen==samples then runStart=0 end
            local minStep=2*math.asin(math.min(1,size/(2*radius*k)))
            local span=runStart and (runLen-1)/samples*TAU or 0
            if runStart and n>1 and span>=(n-1)*minStep then
                local step=math.min(TAU/n,span/(n-1))
                local from=runStart/samples*TAU+(span-step*(n-1))/2
                local mid=from+step*(n-1)/2
                table.sort(items,function(a,b)return (angleOf(a)-mid+math.pi)%TAU<(angleOf(b)-mid+math.pi)%TAU end)
                for i,item in ipairs(items)do place(item,from+(i-1)*step,k)end
                return Vector2.new(closeItem[2],closeItem[3])
            end
        end
    end
    for _,item in ipairs(items)do place(item,angleOf(item)+best)end
    return Vector2.new(closeItem[2],closeItem[3])
end
return M
