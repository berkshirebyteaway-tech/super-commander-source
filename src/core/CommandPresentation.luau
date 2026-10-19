local U=if script then require(script.Parent.UnitRules)else require('./UnitRules')
local M={}
M.roles={City='병력 상한 증가',DefensePost='육상 방어 강화',Port='해상 교역, 군함 건조',Factory='철도 연결, 교역 수입',MissileSilo='로켓 발사, 재장전',SAMLauncher='로켓 요격, 방공 범위',Warship='해상 순찰, 수송선 공격',AtomBomb='지정 범위 타격, 경로 확인',HydrogenBomb='넓은 범위 타격, 경로 확인',MIRV='탄두 분리, 다중 타격'}
function M.prerequisite(state,kind)
    if U.disabled(state.settings or {},kind)then return '이 전장에서는 사용할 수 없어요.'end
    local required=kind=='Warship'and 'Port'or U.nukes[kind]and 'MissileSilo'or nil
    if not required then return nil end
    for _,u in ipairs(state.units or {})do if u.owner==1 and u.kind==required and not u.building and u.active~=false then return nil end end
    return required=='Port'and '항구를 먼저 건설하세요.'or '발사대를 먼저 건설하세요.'
end
function M.hint(state,kind)
    return M.prerequisite(state,kind)or M.roles[kind]or U.names[kind]or kind
end
function M.lesson(lobby)
    return lobby.firstLesson==true and not lobby.soloCustomized
end
function M.soloLoading(lobby)
    local account=lobby.account or {}
    return account.ready~=true and account.loading~=false
end
function M.acknowledges(id,version,result,action)
    return id~=nil and result.requestId==id and result.version==version and result.action==action
end
return M
