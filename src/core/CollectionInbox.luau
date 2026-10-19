local Career=if script then require(script.Parent.CareerRules)else require('./CareerRules')
local Standard=if script then require(script.Parent.CommanderStandardRules)else require('./CommanderStandardRules')
local Catalog=if script then require(script.Parent.CosmeticCatalog)else require('./CosmeticCatalog')
local Supply=if script then require(script.Parent.SupplyCatalog)else require('./SupplyCatalog')
local M={categories={items=true,honors=true,motions=true},limit=512}
M.primary={defensePost='city',trail='projectile',impact='projectile'}
function M.category(c)return c=='items:commanderStandard'or c=='honors'or c=='motions'or type(c)=='string'and c:sub(1,6)=='items:'and Catalog.validSlot(c:sub(7))end
function M.inventory(a)
    local p=a.progress or {};local out={};local level=p.level or 1
    for _,v in ipairs(Standard.items)do if v.level>1 and level>=v.level then out['standard:'..v.id]='items:commanderStandard'end end
    for _,v in ipairs(Career.motions)do if v.level>1 and level>=v.level then out['motion:'..v.id]='motions'end end
    for _,slot in ipairs(Catalog.slots)do for id in pairs(Catalog.styles)do
        if id~=Catalog.default and ((a.owned or {})[id]or (p.ownedSlots or {})[slot..':'..id])then local ps=M.primary[slot]or slot;out['skin:'..ps..':'..id]='items:'..ps end
    end end
    for _,item in ipairs(Supply.items)do if a.billing and a.billing.owned and a.billing.owned[item.id]then
        for slot,id in pairs(item.loadout)do local ps=M.primary[slot]or slot;out['skin:'..ps..':'..id]='items:'..ps end
    end end
    for _,key in ipairs({'titles','plates'})do for _,v in ipairs(p.career and p.career[key]or {})do out[key..':'..v.id]='honors'end end
    return out
end
function M.status(a)
    local out={};local seen=a.collectionSeen or {}
    for id,category in pairs(M.inventory(a))do if not seen[id]then out[category]='new';out[category:match('^[^:]+')]='new';out.wardrobe='new'end end
    if a.billing and (a.billing.dailyClaimAvailable==true or a.billing.freeClaimAvailable==true)then out.shop='action'end
    return out
end
function M.ack(seen,inventory,category,keys)
    if not M.category(category)then return nil end
    local requested
    if keys~=nil then
        if type(keys)~='table'or #keys>64 then return nil end;requested={}
        for i,id in pairs(keys)do if type(i)~='number'or i%1~=0 or i<1 or i>#keys or type(id)~='string'or inventory[id]~=category then return nil end;requested[id]=true end
    end
    local out={};local n=0
    for id,c in pairs(inventory)do if c==category and (not requested or requested[id])or type(seen)=='table'and seen[id]==true then
        n+=1;if n>M.limit then return nil end;out[id]=true
    end end
    return out
end
return M
