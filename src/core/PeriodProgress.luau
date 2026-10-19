local M={}
function M.select(p,field,historyField,key,target,keep,new)
    local current=type(p[field])=='table'and p[field]or nil
    local latest=current and tonumber(current[key])
    if not latest then current=new();p[field]=current;return current end
    if target==latest then return current end
    local history=type(p[historyField])=='table'and p[historyField]or {}
    if target>latest then
        history[tostring(latest)]=table.clone(current);p[historyField]=history
        for id in pairs(history)do local n=tonumber(id);if not n or n<target-keep or n>=target then history[id]=nil end end
        current=new();p[field]=current;return current
    end
    if target<latest-keep then return nil end
    local old=history[tostring(target)]
    return type(old)=='table'and tonumber(old[key])==target and old or nil
end
return M
