local Ops=if script then require(script.Parent.OpsRules)else require('./OpsRules')
local M={}
M.id='halloween2026'
M.style='halloween_territory'
M.itemId='supply:'..M.style
M.startsAt=Ops.parseTime('2026-10-25 00:00')
M.endsAt=Ops.parseTime('2026-11-06 00:00Z')
M.key=M.id
M.need=5
M.minSeconds=120
M.outcomes={won=true,lost=true}
M.custom=false
function M.ended(now)return type(now)=='number'and now>=M.endsAt end
function M.active(on,now)return on~=false and type(now)=='number'and now>=M.startsAt and now<M.endsAt end
function M.qualifies(event)
    if type(event)~='table'or not M.outcomes[event.outcome]or (tonumber(event.seconds)or 0)<M.minSeconds then return false end
    if event.campaign~=nil or event.daily~=nil or event.mode=='training'or event.mode=='single'then return false end
    if event.official==true then return true end
    return M.custom and event.mode=='custom'and (tonumber(event.humans)or 1)>=2
end
function M.count(commerce)
    local h=type(commerce)=='table'and commerce[M.key]
    local list=type(h)=='table'and type(h.matches)=='table'and h.matches or nil
    return list and math.min(#list,M.need)or 0
end
function M.apply(p,event,on)
    if type(p)~='table'or type(p.commerce)~='table'or type(p.commerce.owned)~='table'then return nil end
    if not M.active(on,type(event)=='table'and event.time or nil)or not M.qualifies(event)or event.id==nil then return nil end
    if p.commerce.owned[M.itemId]==true then return nil end
    local h=p.commerce[M.key];if type(h)~='table'or type(h.matches)~='table'then h={matches={}};p.commerce[M.key]=h end
    local id=tostring(event.id);if table.find(h.matches,id)then return nil end
    table.insert(h.matches,id)
    if #h.matches<M.need then return 'counted'end
    p.commerce.owned[M.itemId]=true
    return 'granted'
end
function M.view(owned,now,endsAt,count)
    local on=type(endsAt)=='number'and endsAt>0
    local granted=type(owned)=='table'and owned[M.itemId]==true
    local live=M.active(on,now)
    local n=granted and M.need or math.clamp(math.floor(tonumber(count)or 0),0,M.need)
    return {live=live,granted=granted,left=live and M.endsAt-now or 0,progress=n,total=M.need}
end
function M.publishedEnd(on,now)return M.active(on,now)and M.endsAt or 0 end
return M
