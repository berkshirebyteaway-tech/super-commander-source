local Definitions=if script then require(script.Parent.CollectionDefinitions)else require('./CollectionDefinitions')
local M={version=Definitions.version,items=Definitions.items()}
function M.find(id,items)
    for _,item in ipairs(items or M.items)do if item.id==id then return item end end
end
function M.forSlot(slot)
    local result={};for _,item in ipairs(M.items)do if item.loadout[slot]then table.insert(result,item)end end;return result
end
return M
