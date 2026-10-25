local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Icons=require(script.Parent.OutgameIcons)
local UIS=game:GetService('UserInputService')
local Tween=game:GetService('TweenService')
local C=UI.colors
local M={}
function M.close()
    local f=M.frame;M.frame=nil;M.passive=nil
    if M.conn then M.conn:Disconnect();M.conn=nil end
    if f then f:Destroy()end
end
local last
UIS.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then last=Vector2.new(i.Position.X,i.Position.Y)end end)
function M.show(root,anchor,name,width,build)
    M.close()
    local s=UI.scale or 1
    local card=UI.make('Frame',root,{Name=name,BackgroundColor3=Style.colors.panel,BackgroundTransparency=.02,BorderSizePixel=0,ZIndex=62,Active=true})
    Style.round(card,10);Style.line(card,Style.colors.line,1)
    local h=build(card,width)
    local rw,rh=root.AbsoluteSize.X/s,root.AbsoluteSize.Y/s
    local ax,ay,ab
    if anchor and anchor.Parent and anchor.AbsoluteSize.X>0 then
        ax=(anchor.AbsolutePosition.X+anchor.AbsoluteSize.X/2-root.AbsolutePosition.X)/s;ay=(anchor.AbsolutePosition.Y-root.AbsolutePosition.Y)/s;ab=ay+anchor.AbsoluteSize.Y/s
    else local p=last or Vector2.new(rw*s/2,rh*s/2);ax=(p.X-root.AbsolutePosition.X)/s;ay=(p.Y-root.AbsolutePosition.Y)/s-20;ab=ay+40 end
    local above=ay-h-12>=8
    local x=math.clamp(ax-width/2,8,rw-width-8);local y=above and ay-h-12 or math.min(ab+12,rh-h-8)
    UI.box(card,x,y,width,h)
    local tail=UI.make('Frame',root,{Name=name..'Tail',BackgroundColor3=Style.colors.panel,BorderSizePixel=0,Rotation=45,ZIndex=61});tail:SetAttribute('AllowOverlap',true)
    UI.box(tail,math.clamp(ax-6,x+14,x+width-26),above and y+h-6 or y-6,12,12);Style.line(tail,Style.colors.line,1)
    tail.Parent=card;tail.Position=UDim2.fromOffset(tail.Position.X.Offset-x,tail.Position.Y.Offset-y);tail.ZIndex=61
    M.frame=card
    local scale=UI.make('UIScale',card,{Scale=.94});Tween:Create(scale,TweenInfo.new(.18,Enum.EasingStyle.Back),{Scale=1}):Play()
    task.defer(function()
        if M.frame~=card then return end
        M.conn=UIS.InputBegan:Connect(function(i)
            if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
            local p,sz=card.AbsolutePosition,card.AbsoluteSize
            if i.Position.X<p.X or i.Position.X>p.X+sz.X or i.Position.Y<p.Y or i.Position.Y>p.Y+sz.Y then task.defer(function()if M.frame==card then M.close()end end)end
        end)
    end)
    task.delay(6,function()if M.frame==card then M.close()end end)
    return card
end
function M.vip(root,anchor,perks,onMore)
    return M.show(root,anchor,'VipBubble',math.min(320,(root.AbsoluteSize.X/(UI.scale or 1))-16),function(card,w)
        local lock=Icons.create(card,'lock',16,C.ink);lock.ZIndex=63;UI.box(lock,16,16,16,16)
        local t=UI.label(card,'Title','VIP 클럽',15);t.Font=Enum.Font.BuilderSansBold;t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd;t.ZIndex=63;UI.box(t,40,8,w-52,32)
        local b=UI.label(card,'Perks',perks,13,C.muted);b.ZIndex=63;b.TextYAlignment=Enum.TextYAlignment.Top;UI.box(b,16,42,w-32,20)
        local more=UI.button(card,'VipMore','VIP 보기',onMore);more.ZIndex=64;more.BackgroundColor3=Style.colors.chip;more.TextSize=14
        Style.round(more,8);Style.line(more,C.ink,1,.2);UI.box(more,16,70,w-32,require(script.Parent.InputMode).touch()and 48 or 40)
        return 70+more.Size.Y.Offset+14
    end)
end
function M.growth(root,anchor,r,p)
    local tone=r and r.tone or 'idle'
    local full=p and p.cap and p.cap>0 and (p.troops or 0)>=p.cap*.95
    local line,color
    if full then line,color='■ 상한 가득, 도시 +25K',C.muted
    elseif tone=='falling'then line,color='▼ 느리게',C.recruitmentSlow
    elseif tone=='rising'then line,color='▲ 빠르게',C.good
    else line,color='Ⅱ 멈춤',C.muted end
    return M.show(root,anchor,'GrowthBubble',math.min(330,(root.AbsoluteSize.X/(UI.scale or 1))-16),function(card,w)
        local icon=require(script.Parent.HotbarIcons).create(card,'Soldier',18,C.ink);icon.ZIndex=63;icon.Position=UDim2.fromOffset(16,15)
        local rate=require(script.Parent.Parent.Core.RecruitmentPresentation).rateText(r and r.rate or 0,UI.troops)
        local t=UI.label(card,'Title',require(script.Parent.Localization).text(string.format('병력 %s',rate)),15);t.Font=Enum.Font.BuilderSansBold;t.TextWrapped=false;t.ZIndex=63;t:SetAttribute('LocalizationSkip',true);UI.box(t,42,8,w-140,32)
        local tw=game:GetService('TextService'):GetTextSize(t.Text,15,Enum.Font.BuilderSansBold,Vector2.new(400,32)).X
        local cap=UI.label(card,'Cap',string.format('상한 %s',UI.troops(p and p.cap or 0)),13,C.muted);cap.TextWrapped=false;cap.ZIndex=63;UI.box(cap,58+math.min(tw,w-160),8,110,32)
        local fill=math.clamp(p and p.cap and p.cap>0 and (p.troops or 0)/p.cap or 0,0,1)
        local bar=UI.make('Frame',card,{Name='Fill',BackgroundColor3=C.ink,BackgroundTransparency=.85,BorderSizePixel=0,ZIndex=63});UI.box(bar,16,46,w-32,6);UI.corner(bar,3)
        local f=UI.make('Frame',bar,{Name='Bar',BackgroundColor3=color,BorderSizePixel=0,ZIndex=64,Size=UDim2.fromScale(fill,1)});UI.corner(f,3)
        local n=UI.label(card,'Now',line,13,color);n.Font=Enum.Font.BuilderSansBold;n.TextWrapped=false;n.TextTruncate=Enum.TextTruncate.AtEnd;n.ZIndex=63;UI.box(n,16,58,w-32,22)
        return 90
    end)
end
function M.hint(root,anchor,title,body)
    local card=M.show(root,anchor,'HintBubble',math.min(320,(root.AbsoluteSize.X/(UI.scale or 1))-16),function(card,w)
        local t=UI.label(card,'Title',title,15,C.recruitmentSlow);t.Font=Enum.Font.BuilderSansBold;t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd;t.ZIndex=63;UI.box(t,16,8,w-32,28)
        local b=UI.label(card,'Body',body,13,C.ink);b.ZIndex=63;b.TextYAlignment=Enum.TextYAlignment.Top;UI.box(b,16,38,w-32,40)
        return 86
    end)
    M.passive=true;return card
end
return M
