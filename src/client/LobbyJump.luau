local Players=game:GetService('Players')
local M={}
local target,watch
local function find()
    local pg=Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass('PlayerGui')
    local gui=pg and pg:FindFirstChild('TouchGui');local frame=gui and gui:FindFirstChild('TouchControlFrame')
    return frame and frame:FindFirstChild('JumpButton'),frame
end
local function apply()
    local b,frame=find();if not b then return end
    if target then
        if b:GetAttribute('RobloxPosition')==nil then b:SetAttribute('RobloxPosition',b.Position)end
        local p=target-frame.AbsolutePosition;local want=UDim2.fromOffset(math.floor(p.X),math.floor(p.Y))
        if b.Position~=want then b.Position=want end
    else
        local home=b:GetAttribute('RobloxPosition');if home~=nil then b.Position=home;b:SetAttribute('RobloxPosition',nil)end
    end
end
function M.set(spot)
    if spot==target then return end
    target=spot
    if target and not watch then
        local pg=Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass('PlayerGui')
        if pg then watch=pg.DescendantAdded:Connect(function(o)if target and o.Name=='JumpButton'then task.defer(apply)end end)end
    elseif not target and watch then watch:Disconnect();watch=nil end
    pcall(apply)
end
return M
