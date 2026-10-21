local D=if script then require(script.Parent.CollectionDefinitions)else require('./CollectionDefinitions')
local M={}
M.titles={};M.tiers={}
for _,s in ipairs(D.series)do if s.tier>=4 then M.titles[s.id]=string.format('%s 지휘관',s.name);M.tiers[s.id]=s.tier-1 end end
function M.complete(owned)
    local out={}
    if type(owned)~='table'then return out end
    for _,s in ipairs(D.series)do if M.titles[s.id]then
        local all=true;for _,f in ipairs(D.families)do if owned['supply:'..s.id..'_'..f.id]~=true then all=false;break end end
        if all then table.insert(out,s.id)end
    end end
    table.sort(out);return out
end
function M.sync(outgame,owned)
    local have={};for _,id in ipairs(type(outgame.sets)=='table'and outgame.sets or {})do if M.titles[id]then have[id]=true end end
    for _,id in ipairs(M.complete(owned))do have[id]=true end
    local list={};for id in pairs(have)do table.insert(list,id)end;table.sort(list)
    outgame.sets=#list>0 and list or nil;return outgame
end
function M.titleId(series)return 'set:'..series end
return M
