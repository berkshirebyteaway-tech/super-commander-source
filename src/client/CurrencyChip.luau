local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local Theme=require(script.Parent.Theme)
local Tween=game:GetService('TweenService')
local UIS=game:GetService('UserInputService')
local M={}
function M.dismiss(immediate)
    if M.leaving then M.leaving:Destroy();M.leaving=nil end
    local tip=M.current;M.current=nil;M.owner=nil
    if M.animation then M.animation:Cancel();M.animation=nil end
    if not tip or not tip.Parent then return end
    if immediate or M.reduced then tip:Destroy();return end
    M.leaving=tip
    local t=Tween:Create(tip,TweenInfo.new(.12,Enum.EasingStyle.Quad),{GroupTransparency=1,Position=tip.Position-UDim2.fromOffset(0,4)});M.animation=t
    t:Play();t.Completed:Once(function()if M.leaving==tip then M.leaving=nil;tip:Destroy()end end)
end
local function contains(o,p)
    return o and o.Parent and p.X>=o.AbsolutePosition.X and p.X<=o.AbsolutePosition.X+o.AbsoluteSize.X and p.Y>=o.AbsolutePosition.Y and p.Y<=o.AbsolutePosition.Y+o.AbsoluteSize.Y
end
local function explain(button,kind)
    if M.owner==button then M.dismiss();return end
    M.dismiss(true)
    local root=button
    while root.Parent and root.Parent:IsA('GuiObject')do root=root.Parent end
    local scale=Theme.scale;local rw,rh=root.AbsoluteSize.X/scale,root.AbsoluteSize.Y/scale
    local w=math.min(280,rw-24);local h=76
    local point=(button.AbsolutePosition-root.AbsolutePosition)/scale
    local x=math.clamp(point.X,12,math.max(12,rw-w-12));local y=point.Y+button.AbsoluteSize.Y/scale+8
    if y+h>rh-12 then y=math.max(12,point.Y-h-8)end
    local tip=UI.make('CanvasGroup',root,{Name='CurrencyExplanation',ZIndex=80,BackgroundColor3=UI.colors.panel,BorderSizePixel=0,GroupTransparency=M.reduced and 0 or 1})
    UI.corner(tip,3);UI.stroke(tip,UI.colors.line,1);UI.box(tip,x,y,w,h)
    local icon=Icons.create(tip,kind=='medal'and 'coin'or kind,18,kind=='xp'and UI.colors.ice or UI.colors.gold);UI.box(icon,12,10,18,18)
    local title=UI.label(tip,'Title',kind=='xp'and '경험치'or '코인',14);UI.box(title,38,5,w-50,28);title.ZIndex=81
    local l=UI.label(tip,'Text',kind=='xp'and '레벨과 명예 보상을 해금해요.'or '플레이로 획득, 스킨 뽑기에 사용',13,UI.colors.muted);UI.box(l,12,35,w-24,34);l.ZIndex=81
    M.current=tip;M.owner=button
    if not M.reduced then tip.Position=UDim2.fromOffset(x,y+6);M.animation=Tween:Create(tip,TweenInfo.new(.18,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{GroupTransparency=0,Position=UDim2.fromOffset(x,y)});M.animation:Play()end
    task.delay(4,function()if M.current==tip then M.dismiss()end end)
end
function M.create(parent,kind,value,x,y,w,h)
    local b=UI.button(parent,'Currency_'..kind,'',function()end);b.Active=false;b:SetAttribute('AllowOverlap',true)
    b.BackgroundTransparency=1;b:FindFirstChildOfClass('UIStroke').Enabled=false;UI.box(b,x,y,w,h)
    local color=kind=='xp'and UI.colors.ice or UI.colors.gold
    local icon=Icons.create(b,kind=='medal'and 'coin'or kind,16,color);UI.box(icon,math.max(2,w/2-29),(h-16)/2,16,16)
    local t=UI.label(b,'Value',type(value)=='number'and UI.number(value)or value,14,color);UI.box(t,math.max(22,w/2-8),0,w/2+4,h);t.TextWrapped=false
    b.Activated:Connect(function()explain(b,kind)end)
    b.Destroying:Once(function()if M.owner==b then M.dismiss(true)end end)
    if not M.input then M.input=UIS.InputBegan:Connect(function(i)
        if M.current and(i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch)then
            local p=Vector2.new(i.Position.X,i.Position.Y)-game:GetService('GuiService'):GetGuiInset()
            if not contains(M.current,p)and not contains(M.owner,p)then M.dismiss()end
        end
    end)end
    return b
end
return M
