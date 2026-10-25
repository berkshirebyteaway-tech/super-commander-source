local M={}
local verbs={attack='공격',transport='수송 공격',build='건설',upgrade='강화',spawn='정착',moveWarship='군함 이동',moveWarships='군함 이동',cancelTransport='복귀',retaliate='반격',support='지원',nuclear='발사'}
local diplomacy={request='동맹 요청',accept='동맹 수락',reject='요청 거절',extend='동맹 연장',['break']='동맹 파기'}
function M.describe(name,value,extra,state,context)
    if not verbs[name]and name~='alliance'then return nil end
    state=state or {};context=context or {};local r={title=verbs[name]or diplomacy[value]or '외교',quantity='',target='',icon='Sword',anchor=context.anchor}
    local owner
    if name=='attack'or name=='transport'or name=='retaliate'then
        local ratio=type(value)=='number'and math.clamp(value,0,1)or context.fraction or .2
        r.quantity=math.floor(ratio*100+.5)..'%'
        r.ratio=ratio
        if type(extra)=='number'then owner=context.owners and context.owners[extra]end
        if name=='transport'or context.tile==extra and context.route=='transport'then r.title='수송 공격';r.icon='Transport'else r.icon='Soldier'end
    elseif name=='alliance'then owner=extra;r.icon='Alliance'
    elseif name=='support'then owner=extra;r.title=value=='gold'and '골드 지원'or '병력 지원';r.icon=value=='gold'and 'Gold'or 'Soldier'
    elseif name=='build'or name=='nuclear'then r.target=(context.names or {})[value]or value or '';r.icon=value or 'City'
    elseif name=='upgrade'then r.target=context.unitName or '';r.icon=context.unitKind or 'City'
    elseif name=='moveWarship'or name=='moveWarships'then r.icon='Warship'
    elseif name=='cancelTransport'then r.icon='Transport'
    end
    if owner==0 then r.target='중립 영토'
    elseif owner then for _,f in ipairs(state.factions or {})do if f.id==owner then r.target=f.name or '';break end end end
    return r
end
function M.accepts(current,result,version)
    return current~=nil and result.requestId==current.id and result.action==current.action and result.version==current.version and result.version==version
end
function M.canRestore(request,result,revision,version,currentId,owner,allied)
    return request~=nil and result.ok==false and request.restoreTile~=nil
        and request.closedRevision==revision and result.requestId==currentId
        and request.action==result.action and request.version==version and result.version==version
        and request.restoreOwner==owner and request.restoreAllied==(allied==true)
end
return M
