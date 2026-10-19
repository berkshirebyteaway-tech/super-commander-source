local UI=require(script.Parent.ToyUI)
local Tween=game:GetService('TweenService')
local M={}
function M.color(kind)
    return kind=='mythic'and UI.colors.ice or kind=='legendary'and UI.colors.gold or kind=='epic'and UI.colors.lilac or UI.colors.accent
end
function M.crate(parent,kind,size)
    local color=M.color(kind);local root=UI.make('Frame',parent,{Name='SupplyCrate',BackgroundTransparency=1,Size=UDim2.fromOffset(size,size)})
    local function part(name,x,y,w,h,c)
        local f=UI.corner(UI.make('Frame',root,{Name=name,BackgroundColor3=c,BorderSizePixel=0}),3);UI.box(f,x*size,y*size,w*size,h*size);return f
    end
    local base=part('Case',.12,.3,.76,.54,UI.colors.raised);UI.stroke(base,color,1.5)
    local lid=part('Lid',.08,.2,.84,.19,color:Lerp(UI.colors.bg,.35));UI.stroke(lid,color,1)
    part('BandLeft',.25,.22,.06,.6,color);part('BandRight',.69,.22,.06,.6,color)
    part('Latch',.42,.36,.16,.23,color)
    part('Light',.46,.4,.08,.05,UI.colors.ice)
    part('FootLeft',.18,.84,.16,.05,UI.colors.line);part('FootRight',.66,.84,.16,.05,UI.colors.line)
    return root
end
function M.button(parent,name,label,kind,callback,enabled)
    local b=UI.button(parent,name,label,callback,true);local color=M.color(kind)
    b.BackgroundColor3=enabled and color or color:Lerp(UI.colors.panel,.75)
    b.TextColor3=enabled and UI.colors.bg or color;b.TextSize=17
    local border=b:FindFirstChildOfClass('UIStroke');border.Color=color;border.Transparency=enabled and 0 or .55;border.Thickness=enabled and 2 or 1
    UI.enabled(b,enabled);return b
end
function M.result(card,reduced)
    if reduced then return end
    local scale=UI.make('UIScale',card,{Name='ReceiptArrival',Scale=.97})
    Tween:Create(scale,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    local edge=card:FindFirstChildOfClass('UIStroke');if edge then edge.Thickness=2;Tween:Create(edge,TweenInfo.new(.6),{Thickness=1}):Play()end
end
return M
