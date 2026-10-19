local Career=if script then require(script.Parent.CareerRules)else require('./CareerRules')
local M={limit=6}
function M.find(id)for _,m in ipairs(Career.motions)do if m.id==id then return m end end end
function M.valid(list,level)
    if type(list)~='table'or #list>M.limit then return false end
    local seen={};local count=0
    for i,id in pairs(list)do
        local m=M.find(id)
        if type(i)~='number'or i%1~=0 or i<1 or i>#list or not m or m.level>level or seen[id]then return false end
        count+=1;seen[id]=true
    end
    return count==#list
end
function M.copy(list,level)
    if M.valid(list,level)then return table.clone(list)end
    local out={};for _,m in ipairs(Career.motions)do if m.level<=level and #out<M.limit then table.insert(out,m.id)end end;return out
end
return M
