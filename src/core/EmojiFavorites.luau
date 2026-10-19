local Catalog=if script then require(script.Parent.CommsCatalog)else require('./CommsCatalog')
local M={}
function M.valid(value)
    if type(value)~='table'or #value>#Catalog.emojis then return false end
    local seen={};local count=0
    for key,emoji in pairs(value)do
        if type(key)~='number'or key%1~=0 or key<1 or key>#value or not table.find(Catalog.emojis,emoji)or seen[emoji]then return false end
        seen[emoji]=true;count+=1
    end
    return count==#value
end
function M.copy(value)return M.valid(value)and table.clone(value)or {}end
function M.toggle(value,emoji)
    if not M.valid(value)or not table.find(Catalog.emojis,emoji)then return nil end
    local out=table.clone(value);local index=table.find(out,emoji)
    if index then table.remove(out,index)else table.insert(out,emoji)end
    return out
end
return M
