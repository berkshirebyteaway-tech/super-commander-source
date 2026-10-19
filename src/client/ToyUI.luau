local Base=require(script.Parent.Theme)
local M={make=Base.make,box=Base.box,corner=Base.corner,stroke=Base.stroke,enabled=Base.enabled,number=Base.number,commas=Base.commas,display=Base.display,fonts=Base.fonts}
M.colors=table.clone(Base.colors)
M.colors.peach=Color3.fromRGB(59,130,246);M.colors.lilac=Color3.fromRGB(139,92,246);M.colors.yellow=Base.colors.gold
M.colors.ocean=Color3.fromRGB(14,34,54)
function M.panel(parent,name)
    local p=M.corner(M.make('Frame',parent,{Name=name,BackgroundColor3=M.colors.panel,BackgroundTransparency=.12,BorderSizePixel=0}),3)
    M.stroke(p,M.colors.line,1);return p
end
function M.label(parent,name,text,size,color)
    local l=Base.label(parent,name,text,size,color or M.colors.ink);l.Font=Enum.Font.BuilderSansBold;return l
end
function M.button(parent,name,text,fn,primary)
    local b=Base.button(parent,name,text,fn,primary);b.BackgroundColor3=primary and M.colors.accent or M.colors.raised;b.TextColor3=primary and M.colors.bg or M.colors.ink
    b:FindFirstChildOfClass('UICorner').CornerRadius=UDim.new(0,3);M.stroke(b,primary and M.colors.accent or M.colors.line,1)
    return b
end
function M.pill(parent,name,text,color)
    color=color or M.colors.gold
    local lum=.299*color.R+.587*color.G+.114*color.B
    local p=M.corner(M.make('TextLabel',parent,{Name=name,Text=text,Font=Enum.Font.BuilderSansBold,TextSize=12,TextColor3=lum>.55 and M.colors.bg or M.colors.ink,BackgroundColor3=color,BorderSizePixel=0}),3);return p
end
return M
