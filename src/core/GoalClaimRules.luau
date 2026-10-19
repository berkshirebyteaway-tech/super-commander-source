local O=if script then require(script.Parent.OutgameRules)else require('./OutgameRules')
local M={keep=64}
function M.proof(p,id)
    local list=type(p.goalClaimReceipts)=='table'and p.goalClaimReceipts
    local info=list and list[id]
    if type(info)~='table'then return nil end
    for _,key in ipairs({'xp','medals','count','paidXP'})do
        local n=info[key]
        if not(key=='paidXP'and n==nil)and (type(n)~='number'or n~=n or n%1~=0 or n<0 or n>=math.huge)then return nil end
    end
    return info.count>0 and table.clone(info)or nil
end
function M.apply(p,key,now,mult,id)
    local prior=M.proof(p,id);if prior then return p,prior end
    local out,info=O.claimGoals(p,key,now,mult);if not out then return nil,info end
    local list=type(out.goalClaimReceipts)=='table'and out.goalClaimReceipts or {};out.goalClaimReceipts=list
    list[id]={xp=info.xp,medals=info.medals,count=info.count,paidXP=info.paidXP,at=now}
    local order={};for k,v in pairs(list)do if k~=id then table.insert(order,{id=k,at=type(v)=='table'and tonumber(v.at)or 0})end end
    table.sort(order,function(a,b)return a.at<b.at or a.at==b.at and a.id<b.id end)
    for i=1,math.max(0,#order+1-M.keep)do list[order[i].id]=nil end
    return out,info
end
return M
