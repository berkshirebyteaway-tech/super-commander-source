local TweenService=game:GetService('TweenService')
local TextService=game:GetService('TextService')
local UI=require(script.Parent.ToyUI)
local Rules=require(game.ReplicatedStorage.FrontierNative.Core.ClanRules)
local C=UI.colors
local M={}
M.medals={Color3.fromRGB(245,196,81),Color3.fromRGB(206,216,228),Color3.fromRGB(214,146,92)}
function M.color(index)local c=Rules.colors[Rules.validColor(index)or 1];return Color3.fromRGB(c[1],c[2],c[3])end
function M.skip(o)o.AutoLocalize=false;o:SetAttribute('LocalizationSkip',true);return o end
function M.textWidth(text,size,font)return TextService:GetTextSize(text,size,font or Enum.Font.BuilderSansBold,Vector2.new(1000,100)).X end
function M.emblem(parent,name,tag,colorIndex,size)
    local color=M.color(colorIndex)
    local root=UI.make('Frame',parent,{Name=name,BackgroundTransparency=1,Size=UDim2.fromOffset(size,size)})
    local d=size*.7071
    local outer=UI.make('Frame',root,{Name='Outer',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(d,d),Rotation=45,BackgroundColor3=color,BorderSizePixel=0})
    UI.corner(outer,math.max(2,size//24))
    UI.make('UIGradient',outer,{Rotation=90,Color=ColorSequence.new(color:Lerp(Color3.new(1,1,1),.25),color:Lerp(Color3.new(0,0,0),.35))})
    UI.stroke(outer,color:Lerp(Color3.new(1,1,1),.45),math.max(1,size//40))
    local inner=UI.make('Frame',root,{Name='Plate',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(d*.74,d*.74),Rotation=45,BackgroundColor3=C.bg,BorderSizePixel=0})
    UI.corner(inner,math.max(2,size//30));UI.stroke(inner,color,math.max(1,size//60)).Transparency=.35
    UI.make('UIGradient',inner,{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(26,34,46),C.bg)})
    local t=M.skip(UI.make('TextLabel',root,{Name='Tag',Text=tag~=''and tag or '····',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(size*.62,size*.34),
        BackgroundTransparency=1,TextColor3=color:Lerp(Color3.new(1,1,1),.55),Font=Enum.Font.BuilderSansBold,TextScaled=true}))
    UI.make('UITextSizeConstraint',t,{MaxTextSize=math.floor(size*.26),MinTextSize=8})
    return root
end
function M.banner(parent,name,colorIndex)
    local color=M.color(colorIndex)
    local p=UI.make('Frame',parent,{Name=name,BackgroundColor3=C.panel,BorderSizePixel=0,ClipsDescendants=true});UI.corner(p,3);UI.stroke(p,color:Lerp(C.line,.55),1)
    local wash=UI.make('Frame',p,{Name='Wash',Size=UDim2.fromScale(1,1),BackgroundColor3=color,BackgroundTransparency=0,BorderSizePixel=0})
    UI.make('UIGradient',wash,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.62),NumberSequenceKeypoint.new(.55,.92),NumberSequenceKeypoint.new(1,1)})})
    for i=0,7 do
        local s=UI.make('Frame',p,{Name='Stripe'..i,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.55+i*.07,0,.5,0),Size=UDim2.new(0,10,2.4,0),Rotation=28,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.965,BorderSizePixel=0})
        s.ZIndex=1
    end
    UI.make('Frame',p,{Name='TopLine',Size=UDim2.new(1,0,0,2),BackgroundColor3=color,BorderSizePixel=0})
    return p
end
function M.bar(parent,name,fraction,color,animateFrom)
    local track=UI.make('Frame',parent,{Name=name,BackgroundColor3=C.bg,BackgroundTransparency=.1,BorderSizePixel=0,ClipsDescendants=true});UI.corner(track,2);UI.stroke(track,C.line,1)
    local fill=UI.make('Frame',track,{Name='Fill',Size=UDim2.fromScale(animateFrom or fraction,1),BackgroundColor3=color,BorderSizePixel=0})
    UI.make('UIGradient',fill,{Color=ColorSequence.new(color:Lerp(Color3.new(0,0,0),.15),color:Lerp(Color3.new(1,1,1),.2))})
    local shine=UI.make('Frame',fill,{Name='Shine',Size=UDim2.new(1,0,.45,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.82,BorderSizePixel=0})
    if animateFrom and animateFrom~=fraction then TweenService:Create(fill,TweenInfo.new(.7,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.fromScale(fraction,1)}):Play()end
    return track,fill,shine
end
function M.float(parent,text,x,y,color)
    local l=M.skip(UI.make('TextLabel',parent,{Name='FloatGain',Text=text,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(160,30),BackgroundTransparency=1,TextColor3=color or C.gold,Font=Enum.Font.BuilderSansBold,TextSize=24,TextXAlignment=Enum.TextXAlignment.Center}))
    l.ZIndex=20;UI.display(l)
    local t=TweenService:Create(l,TweenInfo.new(1.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(x,y-46),TextTransparency=1})
    t.Completed:Connect(function()l:Destroy()end);t:Play()
end
function M.hover(frame)
    local stroke=frame:FindFirstChildOfClass('UIStroke');if not stroke then return end
    local base=stroke.Color
    frame.MouseEnter:Connect(function()stroke.Color=base:Lerp(C.accent,.55)end)
    frame.MouseLeave:Connect(function()stroke.Color=base end)
end
function M.rank(parent,rank,x,y,size)
    local medal=M.medals[rank]
    local b=M.skip(UI.make('TextLabel',parent,{Name='Rank',Text=tostring(rank),BackgroundColor3=medal or C.bg,BackgroundTransparency=medal and 0 or .3,BorderSizePixel=0,
        TextColor3=medal and C.bg or C.muted,Font=Enum.Font.BuilderSansBold,TextSize=math.floor(size*.5),TextXAlignment=Enum.TextXAlignment.Center}))
    UI.corner(b,2);UI.box(b,x,y,size,size);UI.display(b)
    if medal then UI.stroke(b,medal:Lerp(Color3.new(1,1,1),.4),1)end
    return b
end
function M.time(seconds)
    local d=math.floor(seconds/86400);local h=math.floor(seconds%86400/3600)
    if d>0 then return string.format('%d일 %d시간',d,h)end
    return string.format('%d시간 %d분',h,math.floor(seconds%3600/60))
end
return M
