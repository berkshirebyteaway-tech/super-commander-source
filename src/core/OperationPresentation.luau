local M={}
function M.items(operations,factions)
    local list={}
    for index,op in ipairs(operations or {})do
        local incoming=op.direction=='incoming'
        local other=incoming and op.owner or op.target
        local target=factions and factions[other]
        local returning=op.retreating or op.retreated
        list[#list+1]={key=op.direction..'_'..op.kind..'_'..op.id,operation=op,index=index,
            target=target and target.name or (other==0 and '중립 땅'or '상대'),incoming=incoming,
            status=returning and '철수'or incoming and '방어'or op.kind=='transport'and '상륙'or other==0 and '점령'or '공격',
            arrow=returning and '↩'or incoming and '↓'or op.kind=='transport'and '↗'or '↑',
            canCancel=not incoming and not returning,
            cancelAction=op.kind=='transport'and 'cancelTransport'or 'cancelAttack'}
    end
    table.sort(list,function(a,b)if a.incoming~=b.incoming then return a.incoming end;return a.index<b.index end)
    return list
end
return M
