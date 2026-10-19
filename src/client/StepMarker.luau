local UI=require(script.Parent.ToyUI)
local M={}
M.names={'작전','지도와 규칙','최종 확인'}
local function build(label)
    local holder=UI.make('Frame',label,{Name='Steps',BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(150,22)})
    for i=1,3 do UI.corner(UI.make('Frame',holder,{Name='Bar'..i,BorderSizePixel=0,Size=UDim2.fromOffset(18,4)}),2)end
    local name=UI.label(holder,'StepName','',13,UI.colors.muted);name.TextWrapped=false;name.TextXAlignment=Enum.TextXAlignment.Right
    label:GetPropertyChangedSignal('Text'):Connect(function()
        local t=holder:GetAttribute('Title');if label.Text~=t and label.Text~=require(script.Parent.Localization).text(t or '')then holder.Visible=false end
    end)
    return holder
end
function M.set(label,title,step)
    local holder=label:FindFirstChild('Steps')or build(label)
    holder:SetAttribute('Title',title);label.Text=title;holder.Visible=true
    for i=1,3 do
        local bar=holder['Bar'..i];bar.Position=UDim2.fromOffset(150-3*22+(i-1)*22,9)
        bar.BackgroundColor3=i<=step and UI.colors.accent or UI.colors.line
    end
    local name=holder:FindFirstChild('StepName');name.Text=string.format('%d %s',step,M.names[step]or '')
    UI.box(name,0,0,150-3*22-8,22)
end
return M
