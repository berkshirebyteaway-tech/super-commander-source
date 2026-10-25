local B=if script then require(script.Parent.BigNat)else require('./BigNat')
local U=if script then require(script.Parent.UnitRules)else require('./UnitRules')
local M={}
function M.account(account)
    account=account or {}
    if account.ready==true then return 'ready' end
    return account.loading==false and 'failed' or 'loading'
end
function M.city(s)
    for _,u in ipairs(s.units or {})do
        if u.owner==1 and u.kind=='City'and u.active~=false and not u.deleteAt then
            return {stage=u.building and 'building' or 'complete',tile=u.tile,unit=u.id}
        end
    end
    if U.disabled(s.settings or {},'City')then return {stage='disabled'}end
    local cost=(s.costs or {}).City
    if not cost then return {stage='saving'}end
    return {stage=B.compare(B.fromString((s.player or {}).gold or '0'),B.fromString(cost))>=0 and 'ready'or 'saving',cost=cost}
end
function M.instruction(stage,ready,rival,touch)
    if stage=='settle'then return ready and '정착'or '빈 땅 고르기'end
    if stage=='expand'or stage=='again'then
        if ready then return touch and '공격, 또는 한 번 더 탭'or '공격, 또는 한 번 더 클릭'end
        if stage=='again'then return '병력 회복, 다시 넓히기'end
        if not touch then return rival and '옆 상대 땅 클릭'or '옆 빈 땅 클릭'end
        return rival and '옆 상대 땅 고르기'or '옆 빈 땅 고르기'
    end
    if stage=='grow'then return '↑ 초록 충원 가속  ↓ 주황 감속'end
    return '자유 지휘'
end
function M.recruitmentHint(s,trend)
    local p=s.player or {};local ratio=(p.troops or 0)/math.max(1,p.cap or 0)
    if ratio<.15 then return '병력 부족, 충원 느림'end
    if trend and trend.tone=='falling'and ratio>.7 then return '상한 근처, 충원 감속'end
    if trend and trend.tone=='falling'then return '↓ 충원 감속'end
    if trend and trend.tone=='rising'then return '↑ 충원 가속'end
    return '병력 회복 중'
end
return M
