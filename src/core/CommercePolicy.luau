local C=if script then require(script.Parent.CosmeticCatalog) else require("./CosmeticCatalog")
local M={}
function M.validCreator(config,creatorId,creatorType)
    return config.creatorGroupId==nil or config.creatorGroupId==0 or (creatorType=="Group" and creatorId==config.creatorGroupId)
end
function M.passId(config,universe,id,creatorId,creatorType)
    if not M.validCreator(config,creatorId,creatorType) then return nil end
    if config.universeId<=0 or config.universeId~=universe then return nil end
    local value=config.passes[id]
    if type(value)=="number" and value>0 and value<2^53 and value%1==0 then return value end
    return nil
end
function M.canEquip(id,owned)
    return type(id)=="string" and C.styles[id]~=nil and (C.styles[id].access=="free" or owned[id]==true)
end
function M.purchase(config,universe,isStudio,id,owned,creatorId,creatorType)
    if type(id)~="string" or not C.styles[id] or C.styles[id].access=="free" then return nil,"invalid-product" end
    if owned[id]==true then return nil,"already-owned" end
    local passId=M.passId(config,universe,id,creatorId,creatorType)
    if isStudio or not config.purchasesEnabled or not passId then return nil,"sales-disabled" end
    if owned[id]~=false then return nil,"ownership-unavailable" end
    return passId
end
return M
