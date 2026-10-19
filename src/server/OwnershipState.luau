local M={}
function M.begin(account)account.ownershipGeneration=(account.ownershipGeneration or 0)+1;return account.ownershipGeneration end
function M.commit(account,generation,results)
    if account.ownershipGeneration~=generation then return false end
    local owned=table.clone(account.owned or {classic=true});local uncertain={}
    for id,result in pairs(results)do
        if result.ok then owned[id]=result.owned==true else uncertain[id]=true end
    end
    owned.classic=true;account.owned=owned;account.uncertain=uncertain;account.unverified=next(uncertain)~=nil;return true
end
M.confirmPauses={0,2,4,8,15,30}
function M.confirmPurchase(check,wait,pauses)
    pauses=pauses or M.confirmPauses
    for i,pause in ipairs(pauses)do
        if pause>0 then wait(pause)end
        local done=check(i);if done~=nil then return done==true,i end
    end
    return false,#pauses
end
function M.forPurchase(account)
    local owned=table.clone(account.owned)
    for id in pairs(account.uncertain or {})do if owned[id]~=true then owned[id]=nil end end
    return owned
end
return M
