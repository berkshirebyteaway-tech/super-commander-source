local Core=if script then game.ReplicatedStorage.FrontierNative.Core else nil
local Vip=if Core then require(Core.VipComms)else require('../core/VipComms')
local Routing=if Core then require(Core.CommsRouting)else require('../core/CommsRouting')
local M={};M.__index=M
function M.new(entries)
    pcall(function()local v=game:GetService('VoiceChatService')
        if v.EnableDefaultVoice or v.UseAudioApi~=Enum.AudioApiRollout.Enabled then warn('VIP voice: VoiceChatService needs UseAudioApi=Enabled and EnableDefaultVoice=false')end
    end)
    return setmetatable({entries=entries,keys={},failed={}},M)
end
function M:input(player)
    local found=player:FindFirstChild('CommanderVoice')
    if found then return found end
    if (self.failed[player.UserId]or 0)>os.clock()then return nil end
    local ok,input=pcall(function()
        local i=Instance.new('AudioDeviceInput');i.Name='CommanderVoice';i.Player=player
        i.AccessType=Enum.AccessModifierType.Allow;i:SetUserIdAccessList({});i.Parent=player;return i
    end)
    if not ok then self.failed[player.UserId]=os.clock()+60;return nil end
    return input
end
function M:sync(e)
    local player=e.player;local input=self:input(player);if not input then return end
    local vip=Vip.isVip(player)
    local list=Vip.listeners(e,self.entries,vip,player:GetAttribute('CommanderVoiceTeam')~=false,Routing)
    local inputs={};for _,c in ipairs(player:GetChildren())do if c:IsA('AudioDeviceInput')then table.insert(inputs,c)end end
    local key=(vip and 'v:'or 'f:')..#inputs..':'..table.concat(list,',')
    if self.keys[player.UserId]==key then return end
    local ok=true
    for _,i in ipairs(inputs)do ok=pcall(function()i.AccessType=Enum.AccessModifierType.Allow;i:SetUserIdAccessList(list)end)and ok end
    if ok then self.keys[player.UserId]=key end
    player:SetAttribute('CommanderVoiceScope',not vip and 'locked'or not e.room and 'hq'or #list==0 and 'none'or 'live')
end
function M:clean()
    for id in pairs(self.keys)do if not self.entries[id]then self.keys[id]=nil;self.failed[id]=nil end end
end
return M
