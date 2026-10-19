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
    if stage=='settle'then return ready and '정착을 눌러 시작하세요.'or '빈 육지에서 시작 위치를 고르세요.'end
    if stage=='expand'or stage=='again'then
        if ready then return touch and '중앙 공격 버튼 또는 같은 땅을 다시 탭.'or '중앙 공격 버튼 또는 같은 땅을 다시 클릭.'end
        if stage=='again'then return '병력이 회복됐어요. 다시 국경을 넓혀보세요.'end
        return rival and '내 국경 옆 상대 영토를 선택하세요.'or '내 국경 옆 빈 땅을 선택하세요.'
    end
    if stage=='grow'then return '↑ 초록: 충원 가속  ↓ 주황: 충원 감속'end
    return '첫 점령 성공!\n이제 자유롭게 지휘하세요.'
end
function M.recruitmentHint(s,trend)
    local p=s.player or {};local ratio=(p.troops or 0)/math.max(1,p.cap or 0)
    if ratio<.15 then return '병력 부족, 충원 느림\n방어 병력도 남겨두세요.'end
    if trend and trend.tone=='falling'and ratio>.7 then return '상한 근처, 충원 감속\n확장하되 방어 병력도 남기세요.'end
    if trend and trend.tone=='falling'then return '↓ 충원 감속\n확장과 방어 병력을 함께 살펴보세요.'end
    if trend and trend.tone=='rising'then return '↑ 충원 가속\n병력을 모으며 주변을 살펴보세요.'end
    return '병력이 다시 모이고 있어요.\n충원 속도를 보며 지휘하세요.'
end
return M
