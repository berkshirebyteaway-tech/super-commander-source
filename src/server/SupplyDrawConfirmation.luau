local Core=game.ReplicatedStorage.FrontierNative.Core
local Profile=require(Core.ProfileModel)
local Catalog=require(Core.SupplyCatalog)
local Rules=require(Core.LaunchCommerce)
local Fresh=require(script.Parent.FreshStore)
local M={}
local function request(value)
    return type(value)=='table'and value.version==Catalog.version
        and type(value.requestId)=='string'and #value.requestId>=8 and #value.requestId<=80 and value.requestId:match('^[%w%-]+$')
        and type(value.sequence)=='number'and value.sequence>=1 and value.sequence<2^53 and value.sequence%1==0
        and type(value.kind)=='string'and Rules.tickets[value.kind]~=nil
        and (value.currency=='ticket'or value.currency=='medals'or value.currency=='free')
end
local function proof(p,value)
    local c=p.commerce;local d=c.draws[value.requestId]
    if type(d)~='table'or d.requestId~=value.requestId or d.kind~=value.kind or d.currency~=value.currency
        or d.sequence~=value.sequence or d.sequence>c.drawSequence or d.testing==true
        or type(d.id)~='string'or c.owned[d.id]~=true then return nil end
    local item=Catalog.find(d.id)
    if not item or item.rarity~=d.rarity or type(d.time)~='number'or d.time~=d.time then return nil end
    return table.clone(d)
end
function M.recover(accounts,id,value)
    if not request(value)then return nil end
    local repo,key=accounts.repo,tostring(id)
    if not repo or not repo:acquire(key)then return nil end
    local ok,p,result=pcall(function()
        local decoded=Profile.decode(Fresh.read(repo.store,key))
        return decoded,decoded and proof(decoded,value)
    end)
    if ok and result then repo.loaded[key]=p end
    repo.busy[key]=nil
    if not ok or not result then return nil end
    local players=game:GetService('Players');local player=players:GetPlayerByUserId(id)
    local a=player and accounts.accounts[player]
    if a and not a.departed and player.Parent==players then
        a.profile=p;pcall(accounts.publish,accounts,player,a)
        pcall(accounts.analytics.flow,accounts.analytics,player,'gacha','drawRecovered',{sku=value.kind,result='granted'})
    elseif not player then repo:forget(key,false)end
    return p,result
end
return M
