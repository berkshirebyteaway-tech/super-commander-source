local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local TextService=game:GetService('TextService')
local Tween=game:GetService('TweenService')
local M={}
local rgb=Color3.fromRGB
M.rarity={normal=rgb(154,166,184),rare=rgb(76,141,255),epic=rgb(160,107,255),legendary=rgb(245,196,81),mythic=rgb(255,143,216)}
M.order={'normal','rare','epic','legendary','mythic'}
M.box={basic=M.rarity.normal,epic=M.rarity.epic,legendary=M.rarity.legendary,mythic=M.rarity.mythic}
M.font=Enum.Font.BuilderSansBold
M.heavy=Enum.Font.BuilderSansExtraBold
function M.round(o,r)local c=o:FindFirstChildOfClass('UICorner')or UI.make('UICorner',o,{});c.CornerRadius=UDim.new(0,r or 8);return o end
function M.width(text,size,font)
    local ok,shown=pcall(function()return require(script.Parent.Localization).text(text)end)
    return TextService:GetTextSize(ok and type(shown)=='string'and shown or text,size,font or M.font,Vector2.new(1000,100)).X
end
function M.text(p,name,value,x,y,w,h,size,color,align,font)
    local l=UI.label(p,name,value,size,color);UI.box(l,x,y,w,h);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd
    if align then l.TextXAlignment=align end;if font then l.Font=font end;return l
end
function M.panel(p,name,x,y,w,h,color,alpha)
    local f=M.round(UI.make('Frame',p,{Name=name,BackgroundColor3=color or UI.colors.panel,BackgroundTransparency=alpha or 0,BorderSizePixel=0}),8);UI.box(f,x,y,w,h)
    UI.stroke(f,UI.colors.line,1);return f
end
function M.chip(p,name,value,color,x,y,h,filled,size)
    size=size or 13;local w=M.width(value,size)+20
    local c=M.round(UI.pill(p,name,value,color),h/2);UI.box(c,x,y,w,h);c.TextSize=size;c.TextWrapped=false
    if filled==false then c.BackgroundColor3=UI.colors.bg;c.BackgroundTransparency=.2;c.TextColor3=color;UI.stroke(c,color:Lerp(UI.colors.line,.35),1)end
    return c,w
end
function M.switch(p,name,options,picked,fn,x,y,w,h,size)
    local f=M.round(UI.make('Frame',p,{Name=name,BackgroundColor3=UI.colors.bg,BackgroundTransparency=.1,BorderSizePixel=0}),6);UI.box(f,x,y,w,h);UI.stroke(f,UI.colors.line,1)
    local cw=w/#options;local hit=math.max(h,48)
    for i,o in ipairs(options)do
        local on=i==picked
        if on then M.round(UI.make('Frame',f,{Name='Picked',BackgroundColor3=UI.colors.line,BorderSizePixel=0}),6);UI.box(f.Picked,(i-1)*cw,0,cw,h)end
        local b=UI.button(f,name..'_'..(o.id or i),o.text,function()if not on then fn(i)end end);UI.box(b,(i-1)*cw,(h-hit)/2,cw,hit);b.TextSize=size or 14
        b.BackgroundTransparency=1;b.TextColor3=on and UI.colors.ink or UI.colors.muted;b.ZIndex=2;M.round(b,6)
        local e=b:FindFirstChildOfClass('UIStroke');if e then e.Enabled=false end
        local face=b:FindFirstChild('PressFeedback');if face then face.Position=UDim2.fromOffset(0,(hit-h)/2);face.Size=UDim2.new(1,0,0,h)end
    end
    return f
end
function M.link(b,color)
    b.BackgroundTransparency=1;local e=b:FindFirstChildOfClass('UIStroke');if e then e.Enabled=false end
    local face=b:FindFirstChild('PressFeedback');if face then face.Visible=false end
    local base=color or b.TextColor3;b.TextColor3=base
    b.MouseEnter:Connect(function()if b:GetAttribute('Enabled')~=false then b.TextColor3=base:Lerp(Color3.new(1,1,1),.35)end end)
    b.MouseLeave:Connect(function()b.TextColor3=base end)
    return b
end
function M.robux(p,size,color,x,y)
    local holder=UI.make('Frame',p,{Name='Robux',BackgroundTransparency=1});UI.box(holder,x or 0,y or 0,size,size)
    UI.make('ImageLabel',holder,{Name='Mark',BackgroundTransparency=1,Image='rbxasset://textures/ui/common/robux.png',ImageColor3=color or UI.colors.ink,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Fit})
    return holder
end
function M.ticket(p,color,x,y,w,h)
    local t=M.round(UI.make('Frame',p,{Name='Ticket',BackgroundColor3=color,BorderSizePixel=0}),2);UI.box(t,x,y,w,h)
    for _,ax in ipairs({0,1})do M.round(UI.make('Frame',t,{Name='Notch',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(ax,.5),Size=UDim2.fromOffset(math.max(3,h*.4),math.max(3,h*.4)),BackgroundColor3=UI.colors.bg,BorderSizePixel=0}),99)end
    UI.make('Frame',t,{Name='Tear',Position=UDim2.new(.68,0,0,2),Size=UDim2.new(0,1,1,-4),BackgroundColor3=UI.colors.bg,BackgroundTransparency=.3,BorderSizePixel=0})
    return t
end
function M.gauge(p,color,n,x,y,w,h)
    local f=UI.make('Frame',p,{Name='ShardCells',BackgroundTransparency=1});UI.box(f,x,y,w,h)
    local cells={}
    for i=1,5 do cells[i]=M.round(UI.make('Frame',f,{Name='Cell'..i,BackgroundColor3=UI.colors.line,BorderSizePixel=0}),2)
        cells[i].Position=UDim2.new((i-1)/5,i>1 and 2 or 0,0,0);cells[i].Size=UDim2.new(.2,-(i>1 and 2 or 0)-(i<5 and 2 or 0),1,0)end
    local function set(k,animate)
        for i,c in ipairs(cells)do local on=i<=k
            if animate and on and c:GetAttribute('On')~=true then
                c.BackgroundColor3=color:Lerp(Color3.new(1,1,1),.7);pcall(function()Tween:Create(c,TweenInfo.new(.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundColor3=color}):Play()end)
            else c.BackgroundColor3=on and color or UI.colors.line end
            c:SetAttribute('On',on)
        end
    end
    set(math.clamp(n or 0,0,5),false)
    return f,set
end
local bubble
function M.bubble(anchor,root,line,link,onLink)
    if bubble then bubble:Destroy();bubble=nil end
    local scale=require(script.Parent.Theme).scale
    local pos=(anchor.AbsolutePosition-root.AbsolutePosition)/scale;local size=anchor.AbsoluteSize/scale
    local w=math.max(M.width(line,14),link and M.width(link,14)or 0)+28;local h=link and 54 or 36
    local b=M.round(UI.make('TextButton',root,{Name='LockBubble',Text='',AutoButtonColor=false,BackgroundColor3=UI.colors.raised,BorderSizePixel=0,ZIndex=40}),8)
    local rootW=root.AbsoluteSize.X/scale
    UI.box(b,math.clamp(pos.X+size.X/2-w/2,4,math.max(4,rootW-w-4)),math.max(4,pos.Y-h-10),w,h);UI.stroke(b,UI.colors.line,1);bubble=b
    local tip=UI.make('Frame',b,{Name='Tip',AnchorPoint=Vector2.new(.5,.5),Rotation=45,BackgroundColor3=UI.colors.raised,BorderSizePixel=0,ZIndex=39});UI.box(tip,math.clamp(pos.X+size.X/2-b.Position.X.Offset,12,w-12),h,10,10)
    M.text(b,'Line',line,14,link and 6 or 0,w-28,link and 22 or h,14,UI.colors.ink).ZIndex=41
    if link then local l=M.text(b,'Link',link,14,28,w-28,20,14,UI.colors.ink);l.ZIndex=41;l.Font=M.heavy end
    b.Activated:Connect(function()if link and onLink then onLink()end;if bubble==b then bubble=nil end;b:Destroy()end)
    local s=UI.make('UIScale',b,{Scale=.9});pcall(function()Tween:Create(s,TweenInfo.new(.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()end)
    task.delay(link and 2.6 or 1.6,function()if bubble==b and b.Parent then
        pcall(function()Tween:Create(b,TweenInfo.new(.2),{BackgroundTransparency=1}):Play()end);task.wait(.2);if bubble==b then bubble=nil end;b:Destroy()end end)
    return b
end
local function bar(p,x,y,w,h,c,r,rot)local f=UI.make('Frame',p,{BackgroundColor3=c,BorderSizePixel=0,Rotation=rot or 0});UI.box(f,x,y,w,h);if r then M.round(f,r)end;return f end
local glyphs={
    commanderStandard=function(g,s,c)bar(g,s*.18,s*.08,s*.08,s*.84,UI.colors.ink,1);bar(g,s*.26,s*.12,s*.58,s*.4,c,2)end,
    flag=function(g,s,c)bar(g,s*.08,s*.2,s*.84,s*.6,UI.colors.ink,2);bar(g,s*.36,s*.34,s*.28,s*.28,c,99)end,
    vehicle=function(g,s,c)bar(g,s*.06,s*.36,s*.88,s*.3,c,3);bar(g,s*.24,s*.2,s*.44,s*.2,c,3);bar(g,s*.16,s*.62,s*.2,s*.2,UI.colors.ink,99);bar(g,s*.64,s*.62,s*.2,s*.2,UI.colors.ink,99)end,
    commanderTrail=function(g,s,c)bar(g,s*.04,s*.45,s*.86,s*.12,c,99,-38);bar(g,s*.76,s*.08,s*.18,s*.18,UI.colors.ink,99)end,
    territory=function(g,s,c)bar(g,s*.18,s*.18,s*.64,s*.64,c,3,45);bar(g,s*.34,s*.34,s*.32,s*.32,c:Lerp(UI.colors.ink,.4),2,45)end,
    city=function(g,s,c)bar(g,s*.1,s*.4,s*.24,s*.52,c,1);bar(g,s*.38,s*.12,s*.26,s*.8,c:Lerp(UI.colors.ink,.3),1);bar(g,s*.68,s*.3,s*.22,s*.62,c,1)end,
    projectile=function(g,s,c)bar(g,s*.1,s*.1,s*.8,s*.8,c,99);bar(g,s*.36,s*.36,s*.28,s*.28,UI.colors.bg,99)end,
    parachute=function(g,s,c)bar(g,s*.06,s*.1,s*.88,s*.36,c,99);bar(g,s*.4,s*.62,s*.2,s*.26,UI.colors.ink,2)end,
}
local icons={commanderOrder='marshal',motions='dance',honors='reward'}
function M.glyph(p,key,size,color)
    local g=UI.make('Frame',p,{Name='Glyph',BackgroundTransparency=1});UI.box(g,0,0,size,size)
    if icons[key]then local i=Icons.create(g,icons[key],size,color);UI.box(i,0,0,size,size)
    elseif glyphs[key]then glyphs[key](g,size,color)end
    return g
end
function M.robuxText(price,fallback)
    local digits=price and (price:match('^%s*([%d,]+)%s*Robux')or price:match('^%s*R%$%s*([%d,]+)')or price:match('^%s*([%d,]+)%s*$'))
    local n=digits and tonumber((digits:gsub(',','')))or fallback
    return n and UI.commas(math.floor(n))or nil
end
return M
