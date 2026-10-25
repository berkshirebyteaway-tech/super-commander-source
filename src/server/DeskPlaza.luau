local H=require(game.ReplicatedStorage.FrontierNative.Core.LobbyHall)
local M={create=require(script.Parent.CommandHall).create}
local taken,owner={},{}
game:GetService('Players').PlayerRemoving:Connect(function(p)local s=owner[p.UserId];if s then taken[s]=nil;owner[p.UserId]=nil end end)
local function slotOf(userId)
    local s=owner[userId];if s then return s end
    local n=H.balconyCount()
    for i=1,n do if not taken[i]then taken[i]=userId;owner[userId]=i;return i end end
    return (math.abs(userId)%n)+1
end
function M.spawn(userId,character)
    local slot=slotOf(userId);local feet=H.balconySlot(slot)
    if character then character:SetAttribute('BalconySlot',slot)end
    local hum=character and character:FindFirstChildOfClass('Humanoid');local root=character and character:FindFirstChild('HumanoidRootPart')
    local lift=3
    if hum and root then lift=hum.RigType==Enum.HumanoidRigType.R15 and hum.HipHeight+root.Size.Y/2 or 3*(character:GetScale())end
    return feet*CFrame.new(0,lift,0)
end
return M
