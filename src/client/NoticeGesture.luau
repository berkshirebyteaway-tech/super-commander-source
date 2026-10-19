local TweenService=game:GetService('TweenService')
local UIS=game:GetService('UserInputService')
local M={}
local THRESHOLD=56
local function reduced()return game.Players.LocalPlayer:GetAttribute('CommanderReducedEffects')==true end
function M.attach(toast,text,onDismiss)
    local self={toast=toast,text=text,home=text.Position}
    function self.appear()
        if reduced()then text.Position=self.home;text.TextTransparency=0;return end
        if self.rise then self.rise:Cancel()end
        text.Position=self.home+UDim2.fromOffset(0,8);text.TextTransparency=1
        self.rise=TweenService:Create(text,TweenInfo.new(.2,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{Position=self.home,TextTransparency=0});self.rise:Play()
    end
    local start,input,base=nil,nil,nil
    toast.InputBegan:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        start,input,base=i.Position,i,toast.Position
    end)
    UIS.InputChanged:Connect(function(i)
        if not start or (i~=input and i.UserInputType~=Enum.UserInputType.MouseMovement)then return end
        local dx=i.Position.X-start.X;toast.Position=base+UDim2.fromOffset(dx,0)
    end)
    UIS.InputEnded:Connect(function(i)
        if not start or (i~=input and i.UserInputType~=Enum.UserInputType.MouseButton1)then return end
        local dx=i.Position.X-start.X;local from=base;start,input=nil,nil
        if math.abs(dx)<THRESHOLD then toast.Position=from;return end
        local out=from+UDim2.fromOffset((dx>0 and 1 or -1)*(toast.AbsoluteSize.X+24),0)
        local t=TweenService:Create(toast,TweenInfo.new(reduced()and 0 or .12,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=out});t:Play()
        t.Completed:Once(function()toast.Visible=false;toast.Position=from;onDismiss()end)
    end)
    return self
end
return M
