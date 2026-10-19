local M={}
function M.suggestion(queue,directory,now,seats)
    if not queue or queue.mode~='pvp'or queue.phase~='waiting'or queue.locked or not directory or directory.unavailable then return nil end
    if not queue.joined or not now or now-queue.joined<45 or queue.count>=queue.minimum and not queue.needsOpponent then return nil end
    local best
    for _,f in ipairs(directory.fields or {})do
        if f.kind=='official'and f.id~=queue.field and (f.phase=='waiting'or f.phase=='countdown')and f.count>0 and f.count+(seats or 1)<=f.rules.maximum then
            if not best or (f.remaining or math.huge)<(best.remaining or math.huge)or f.remaining==best.remaining and (f.count>best.count or f.count==best.count and f.id<best.id)then best=f end
        end
    end
    return best and best.id or nil
end
function M.layout(width,extra)
    local stacked=width<500 and extra
    return {height=stacked and 96 or 48,
        state={x=14,y=4,w=width-(stacked and 28 or extra and 246 or 100),h=40},
        suggest={x=stacked and 12 or width-232,y=stacked and 48 or 2,w=stacked and width-108 or 144,h=44},
        cancel={x=width-80,y=stacked and 48 or 2,w=72,h=44}}
end
return M
