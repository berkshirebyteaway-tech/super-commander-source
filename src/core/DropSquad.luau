local M={}
function M.assign(roster,groups)
    local result,byUser,seen={},{},{}
    for i,r in ipairs(roster)do result[i]=table.clone(r);result[i].partyKey=nil;result[i].partyIndex=nil;byUser[r.userId]=result[i]end
    for _,g in pairs(groups or {})do if type(g)=='table'and not seen[g]then
        seen[g]=true;local users,unique={},{}
        for _,id in ipairs(g.users or {})do if byUser[id]and not unique[id]then unique[id]=true;table.insert(users,id)end end
        table.sort(users)
        if #users>1 and #users<=5 then
            local key=tostring(users[1]);local leader=table.find(users,g.leader)
            if leader then table.remove(users,leader);table.insert(users,1,g.leader)end
            for index,id in ipairs(users)do byUser[id].partyKey=key;byUser[id].partyIndex=index end
        end
    end end
    return result
end
function M.members(players)
    local own;for _,p in ipairs(players)do if p.id==1 then own=p;break end end
    local result={}
    if not own or not own.partyKey then return result end
    for _,p in ipairs(players)do
        if p.partyKey==own.partyKey and type(p.partyIndex)=='number'and p.partyIndex%1==0 and p.partyIndex>=1 and p.partyIndex<=5 then
            result[p.id]={index=p.partyIndex,allied=own.team~=nil and p.team==own.team,mine=p.id==1}
        end
    end
    return result
end
return M
