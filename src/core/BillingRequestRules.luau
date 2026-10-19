local Catalog=if script then require(script.Parent.SupplyCatalog)else require('./SupplyCatalog')
local Commerce=if script then require(script.Parent.LaunchCommerce)else require('./LaunchCommerce')
local Custom=if script then require(script.Parent.CustomBattlefieldRules)else require('./CustomBattlefieldRules')
local M={}
local function whole(n)return type(n)=='number'and n==n and n%1==0 and n>0 and n<math.huge end
function M.valid(action,value,benefits,studio,localMode)
    if action=='supplyDraw'then
        if type(value)~='table'or value.version~=Catalog.version or type(value.requestId)~='string'
            or #value.requestId<8 or #value.requestId>80 or not value.requestId:match('^[%w%-]+$')
            or type(value.kind)~='string'or not Commerce.tickets[value.kind]or not whole(value.sequence)then return false,'invalid-request'end
        if not table.find({'medals','free','ticket','studio'},value.currency)then return false,'invalid-currency'end
        if (value.currency=='medals'or value.currency=='free')and value.kind~='basic'then return false,'invalid-currency'end
        if value.currency=='studio'and not(studio and localMode)then return false,'invalid-request'end
    elseif action=='supplyTestGrant'then
        if not(studio and localMode)then return false,'invalid-request'end
    elseif action=='equipSupply'then
        if type(value)~='string'or #value>120 or not Catalog.find(value)then return false,'invalid-request'end
    elseif action=='savePreset'then
        if benefits.presetSlots==0 then return false,'preset-locked'end
        if type(value)~='table'or not whole(value.slot)or value.slot>benefits.presetSlots then return false,'invalid-request'end
        local rules,why=Custom.normalize(value.rules);if not rules then return false,why end
    else return false,'invalid-request'end
    return true
end
return M
