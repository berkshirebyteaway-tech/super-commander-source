local Supply=if script then require(script.Parent.SupplyRules)else require('./SupplyRules')
local M={limits={basic=20,epic=5,legendary=5,mythic=5}}
function M.enabled(studio,localMode)return studio==true and localMode==true end
function M.grant(raw,studio,localMode)
    if not M.enabled(studio,localMode)then return nil,'invalid-request'end
    local c,err=Supply.decode(raw);if not c then return nil,err end
    c.studioTickets=table.clone(M.limits);return c
end
function M.draw(raw,value,entropy,medals,now,actor,studio,localMode)
    if not M.enabled(studio,localMode)or type(value)~='table'then return nil,'invalid-request'end
    local c,err=Supply.decode(raw);if not c then return nil,err end
    local prior=c.draws[value.requestId]
    if prior and not prior.testing then return nil,'invalid-request'end
    if not prior and (type(c.studioTickets)~='table'or not M.limits[value.kind]or (c.studioTickets[value.kind]or 0)<1)then return nil,'insufficient-tickets'end
    local tickets,fragments=table.clone(c.tickets),table.clone(c.fragments)
    if not prior then c.tickets[value.kind]+=1 end
    local next,result,balance=Supply.draw(c,value.kind,'ticket',value.requestId,entropy,medals,true,now,nil,value.sequence,math.max(1,math.abs(actor)))
    if not next then return nil,result end
    next.tickets=tickets;next.fragments=fragments
    if not prior then next.studioTickets[value.kind]-=1 end
    result.testing=true;result.fragments=nil;result.refundTickets=nil;result.fragmentCount=nil
    next.draws[value.requestId]=result
    for _,entry in ipairs(next.history)do if entry.requestId==value.requestId then entry.testing=true;entry.fragments=nil;entry.refundTickets=nil end end
    return next,result,balance
end
return M
