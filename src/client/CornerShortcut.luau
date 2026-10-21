local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Placement=require(script.Parent.Parent.Core.InterfacePlacement)
local M={}
function M.new(parent,name,key,kind,callback,tipText)
    if key and tipText and not string.find(tipText,'(',1,true)then tipText=tipText..' ('..key..')'end
    local b=UI.button(parent,name,'',callback);b.ZIndex=19;b.BackgroundTransparency=1;b:SetAttribute('LocalizationSkip',true)
    local plate=UI.panel(b,'Plate');plate.AnchorPoint=Vector2.new(.5,.5);plate.Position=UDim2.fromScale(.5,.5);plate.Size=UDim2.fromOffset(28,28);plate.ZIndex=20
    plate.BackgroundColor3=UI.colors.raised;plate.BackgroundTransparency=0;plate:FindFirstChildOfClass('UIStroke').Transparency=.35
    local function tint(on)plate.BackgroundColor3=on and Style.colors.cell:Lerp(UI.colors.ink,.1)or b:GetAttribute('PlateColor')or Style.colors.cell end
    b.MouseEnter:Connect(function()tint(true)end);b.MouseLeave:Connect(function()tint(false)end)
    local icon=UI.make('Frame',plate,{Name='Icon',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(16,16),BackgroundTransparency=1,ZIndex=21})
    local grow=UI.make('UIScale',icon,{Name='Grow',Scale=1})
    local ink={}
    local function part(x,y,w,h)local p=UI.make('Frame',icon,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=UI.colors.ink,BorderSizePixel=0,ZIndex=22});table.insert(ink,p);return p end
    local ring=UI.make('Frame',icon,{Size=UDim2.fromOffset(16,kind=='chat'and 12 or 16),BackgroundTransparency=1,ZIndex=21})
    UI.corner(ring,kind=='chat'and 2 or 999);local ringLine=UI.stroke(ring,UI.colors.ink,1.5)
    if kind=='emoji'then part(4,5,2,2);part(10,5,2,2);part(4,10,2,2);part(6,12,4,1);part(10,10,2,2)
    elseif kind=='history'then part(7,3,2,6);part(8,8,4,2)
    elseif kind=='camera'then part(7,0,2,5);part(7,11,2,5);part(0,7,5,2);part(11,7,5,2)
    elseif kind=='motion'then ring.Visible=false;part(6,0,4,4);part(7,5,2,7);part(2,5,12,2);part(4,11,3,5);part(9,11,3,5)
    elseif kind=='more'then ring.Visible=false;part(1,7,3,3);part(6.5,7,3,3);part(12,7,3,3)
    elseif kind=='comms'then ring.Visible=false;local bubble=UI.make('Frame',icon,{Size=UDim2.fromOffset(16,11),BackgroundTransparency=1,ZIndex=21});UI.corner(bubble,3);ringLine=UI.stroke(bubble,UI.colors.ink,1.5);part(3,11,3,3);part(4,4,8,1.5);part(4,7,5,1.5)
    else part(3,12,2,3);part(4,4,8,1);part(4,7,5,1)end
    local function paint()
        local locked=b:GetAttribute('Locked')==true
        local color=locked and UI.colors.muted or UI.colors.ink
        for _,p in ipairs(ink)do p.BackgroundColor3=color end;ringLine.Color=color
    end
    b:GetAttributeChangedSignal('Locked'):Connect(paint);paint()
    local hint=UI.label(b,'Key',key or '',13,UI.colors.muted);hint.TextXAlignment=Enum.TextXAlignment.Center;hint.Font=Enum.Font.BuilderSansBold;hint.ZIndex=23;hint:SetAttribute('LocalizationSkip',true);hint.TextWrapped=false;UI.box(hint,0,31,44,13)
    hint.BackgroundColor3=Style.colors.lock;hint.BackgroundTransparency=1;Style.round(hint,4)
    local tip=UI.label(b,'Tip',tipText,13);tip.Visible=false;tip.BackgroundColor3=UI.colors.panel;tip.BackgroundTransparency=.04;tip.TextXAlignment=Enum.TextXAlignment.Center;tip.ZIndex=24;Style.round(tip,6)
    b.MouseEnter:Connect(function()b:SetAttribute('Hover',true);tip.Visible=not b:GetAttribute('TouchLayout');b.ZIndex=tip.Visible and 30 or 19 end)
    b.MouseLeave:Connect(function()b:SetAttribute('Hover',false);tip.Visible=false;b.ZIndex=19 end)
    b:GetPropertyChangedSignal('Visible'):Connect(function()if not b.Visible then b:SetAttribute('Hover',false);tip.Visible=false;b.ZIndex=19 end end)
    return b
end
function M.scale(b,s)
    local u=b:FindFirstChild('PcScale')
    if not u then if s==1 then return end;u=UI.make('UIScale',b,{Name='PcScale'})end
    u.Scale=s
    local tip=b:FindFirstChild('Tip');if tip then local t=tip:FindFirstChild('Unscale')or UI.make('UIScale',tip,{Name='Unscale'});t.Scale=1/s end
end
M.PLATE={phone=26,touch=28}
function M.place(b,w,h,menu,touch,index)
    local phone=Placement.phone(w,h,touch)
    local size=48;local gap=4
    menu=menu or {x=w-52,y=h-52,w=44}
    local fixed=not menu.drop and Placement.shortcuts(w,h,touch)[b.Name]
    local s=fixed and Placement.pcScale(touch,w,h)or 1;M.scale(b,s)
    local x=fixed and fixed.x or menu.x-index*(size+gap)
    local y=fixed and fixed.y or menu.y+(44-size)/2
    local on=math.floor(size*s+.5)
    x=math.clamp(x,2,w-on-2);UI.box(b,x,math.clamp(y,2,h-on-2),size,size)
    if b:GetAttribute('TouchLayout')~=(touch==true)then b:SetAttribute('Hover',false)end
    b:SetAttribute('TouchLayout',touch==true);b.Key.Visible=false
    b.Tip.Visible=not touch and b:GetAttribute('Hover')==true;b.ZIndex=b.Tip.Visible and 30 or 19
    local desk=Placement.desk(w,h,touch)
    local plate=b.Plate;local p=phone and M.PLATE.phone or touch and not desk and M.PLATE.touch or 44
    plate.AnchorPoint=Vector2.new(.5,0);plate.Position=UDim2.new(.5,0,0,(size-p)/2);plate.Size=UDim2.fromOffset(p,p)
    Style.round(plate,phone and 10 or 8)
    local color=phone and Color3.new(0,0,0)or Style.colors.cell
    b:SetAttribute('PlateColor',color);plate.BackgroundColor3=color;plate.BackgroundTransparency=phone and .28 or .04
    local line=plate:FindFirstChildOfClass('UIStroke');if line then line.Color=Style.colors.line;line.Transparency=phone and .5 or 0 end
    plate.Icon.Grow.Scale=touch and not desk and .8 or 1.375
    local k=b.Key;k.TextSize=s<1 and Placement.PC_TEXT or 13;local kw=math.max(20,#k.Text*(s<1 and 9 or 8)+10)
    UI.box(k,(size-kw)/2,size+2,kw,s<1 and 18 or 16);k.BackgroundTransparency=k.Visible and .1 or 1
    local tw=112/s
    UI.box(b.Tip,math.clamp((size-tw)/2,(2-x)/s,(w-2-x)/s-tw),-30/s,112,24)
end
return M
