local Log=if script then require(game.ReplicatedStorage.FrontierNative.Core.ReplayLog)else require('../core/ReplayLog')
local M={}
function M.merge(list,row,recordedAt)
    if type(recordedAt)=='number'then row=table.clone(row);row.recordedAt=recordedAt end
    local version=type(row.place)=='number'and row.place or nil
    for _,r in ipairs(type(list)=='table'and list or {})do
        if type(r)=='table'and type(r.place)=='number'and (not version or r.place>version)then version=r.place end
    end
    local out,stale,seen={}, {},{}
    for _,r in ipairs({row,table.unpack(type(list)=='table'and list or {})})do
        if type(r)=='table'and type(r.id)=='string'and not seen[r.id]then
            seen[r.id]=true
            if version and r.place~=version then table.insert(stale,r.id)else table.insert(out,r)end
        end
    end
    local order={};for i,r in ipairs(out)do order[r]=i end
    table.sort(out,function(a,b)
        local x,y=tonumber(a.recordedAt)or tonumber(a.at)or 0,tonumber(b.recordedAt)or tonumber(b.at)or 0
        return x>y or x==y and order[a]<order[b]
    end)
    while #out>Log.keep do table.remove(out)end
    return out,stale
end
return M
