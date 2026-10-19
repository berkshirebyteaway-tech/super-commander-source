local Catalog=if script then require(script.Parent.Parent.Maps.Catalog)else require('../maps/Catalog')
local Policy=if script then require(script.Parent.CountryPolicy)else require('./CountryPolicy')
local M={}
function M.coopAI(r,humans)
    local cap=0;for _,map in ipairs(Catalog)do if map.key==r.map then cap=#Policy.filter(map.key,map.nations);break end end
    local count=math.clamp(math.floor(humans or 0),0,r.maximum)
    local projected=math.max(1,count);local wanted=r.aiCount or projected*r.aiPerHuman
    return {humans=count,projected=projected,wanted=wanted,ai=math.min(wanted,cap),cap=cap,limited=wanted>cap,minimum=math.min(r.aiCount or r.aiPerHuman,cap),maximum=math.min(r.aiCount or r.maximum*r.aiPerHuman,cap)}
end
function M.single(queue)
    if not queue then return 'start'end
    if queue.locked or queue.phase=='transferring'then return 'moving'end
    return 'replace'
end
function M.practice(queue,now,playing)
    return not playing and queue~=nil and queue.mode=='pvp'and queue.phase=='waiting'and not queue.locked and queue.joined~=nil and now~=nil and now-queue.joined>=15
end
function M.score(f,queue)
    if queue and f.id==queue.field then return -10000 end
    if f.count>=f.rules.maximum then return 2000 end
    if f.remaining~=nil then return -2000+math.min(120,f.remaining)end
    if f.kind=='official'and f.count>0 then return -1000-f.count end
    if f.kind=='custom'and f.count>0 then return -500-(f.readyCount or 0)end
    return f.kind=='official'and 100 or 200
end
return M
