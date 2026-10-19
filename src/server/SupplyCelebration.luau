local Pack=game.ReplicatedStorage.FrontierNative
local Remote=Pack:FindFirstChild('SupplyCelebration')or Instance.new('RemoteEvent')
Remote.Name='SupplyCelebration';Remote.Parent=Pack
local Studio=game:GetService('RunService'):IsStudio();local Messaging=game:GetService('MessagingService')
local seen={};local order={};local M={}
local function deliver(data)
    if type(data)~='table'or type(data.key)~='string'or seen[data.key]or not table.find({'legendary','mythic'},data.rarity)then return end
    if type(data.name)~='string'or #data.name>100 or type(data.item)~='string'or #data.item>120 then return end
    seen[data.key]=true;table.insert(order,data.key);if #order>100 then seen[table.remove(order,1)]=nil end
    Remote:FireAllClients(data)
end
if not Studio and game.GameId>0 then task.spawn(function()pcall(function()Messaging:SubscribeAsync('SC-Supply-v2',function(message)deliver(message.Data)end)end)end)end
function M.announce(player,result)
    if result.rarity~='legendary'and result.rarity~='mythic'then return end
    local data={key=tostring(player.UserId)..':'..result.requestId,name=player.DisplayName,item=result.name,rarity=result.rarity,serial=result.serial,testing=result.testing==true}
    deliver(data)
    if result.rarity=='mythic'and not Studio and not result.testing then task.spawn(function()pcall(function()Messaging:PublishAsync('SC-Supply-v2',data)end)end)end
end
return M
