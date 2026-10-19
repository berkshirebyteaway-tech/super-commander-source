local UI=require(script.Parent.Theme)
local Icons=require(script.Parent.OutgameIcons)
local Telemetry=require(script.Parent.TelemetryClient)
local Vip=require(script.Parent.Parent.Core.VipComms)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local Tween=game:GetService('TweenService')
local Me=game.Players.LocalPlayer
local M={}
local GOLD=Color3.fromRGB(255,207,91)
M.features={emoji='VIP 클럽 전용 이모지예요. 앞의 외교 이모지 7개는 무료예요.',quickChat='빠른 채팅 문구는 VIP 클럽 전용이에요.',text='채팅 입력은 VIP 클럽 전용이에요.',
    voice='음성 채팅은 VIP 클럽 전용이에요.',motion='모션은 VIP 클럽 전용이에요.',spectate='다른 경기 관전은 VIP 클럽 혜택이에요.'}
M.perks={'글 채팅','음성 채팅, 팀 전용 가능','이모지, 빠른 채팅','지휘 모션','다른 경기 관전','매일 뽑기권, XP 2배'}
function M.isVip()return Vip.isVip(Me)end
function M.allows(kind,value)return Vip.allows(kind,value,M.isVip())end
function M.bind(root,shop,lobby,inMatch)M.root=root;M.shop=shop;M.lobby=lobby;M.inMatch=inMatch end
function M.close()
    local f=M.frame;M.frame=nil
    if f then f:Destroy()end
end
local go
function M.offer(feature)return go(feature)end
local function seen(origin)pcall(function()local shop=M.shop and M.shop();local billing=shop and shop.account and shop.account.billing
    local r,why=Telemetry.offerState(billing,'club',billing and billing.club and billing.club.available);Telemetry.offerSeen('club',origin,r,why)end)end
go=function(feature,origin)
    local inMatch=M.inMatch and M.inMatch()
    Telemetry.step('social','vipLockOffer',{item=feature})
    local shop=M.shop and M.shop();local lobby=M.lobby and M.lobby()
    if not inMatch and lobby then M.close();lobby:openPage('benefits');return end
    local billing=shop and shop.account and shop.account.billing
    if shop and billing and billing.club and billing.club.available then M.close();shop:purchaseBilling('club',origin or 'vipCard')else Telemetry.step('vip','offerUnavailable',{item=feature,result='unavailable',reason='sales_disabled'});if M.notify then M.notify('경기가 끝나면 사령부 상점에서 VIP 클럽을 볼 수 있어요.')end end
end
function M.tag(parent,x,y,z)
    local tag=UI.make('Frame',parent,{Name='VipTag',BackgroundColor3=Color3.fromRGB(8,11,15),BorderSizePixel=0,ZIndex=(z or parent.ZIndex)+2,Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(x+10,y-2)});UI.corner(tag,40)
    UI.stroke(tag,UI.colors.line,1);tag:SetAttribute('AllowOverlap',true)
    local i=Icons.create(tag,'lock',12,UI.colors.ink);i.Name='Text';UI.box(i,3,3,12,12);i.ZIndex=tag.ZIndex+1
    return tag
end
function M.badge(button,kind)
    local plate=button:FindFirstChild('Plate')
    local tag=M.tag(plate or button,0,0);tag.AnchorPoint=Vector2.new(1,0);tag.Position=UDim2.new(1,6,0,-6);tag.ZIndex=math.max(tag.ZIndex,30);tag.Text.ZIndex=tag.ZIndex+1
    local function refresh()if tag.Parent then tag.Visible=not M.allows(kind);button:SetAttribute('Locked',tag.Visible)end end
    refresh();Me:GetAttributeChangedSignal('CommanderVIP'):Connect(refresh)
    pcall(function()game.ReplicatedStorage.FrontierNative:GetAttributeChangedSignal('VipCommsOpen'):Connect(refresh)end)
    return tag
end
M.seen={}
function M.micOn()
    if M.micTold or M.allows('voice')or not M.notify then return end
    M.micTold=true;M.notify(M.features.voice,true)
    Telemetry.step('vip','lockPress',{item='voice',result='shown',reason='subscription_required',mode=M.inMatch and M.inMatch()and 'pvp'or 'lobby'})
end
M.bubblePerks='VIP 클럽이면 채팅, 빠른 대화, 이모지 전체, 모션을 모두 쓸 수 있어요.'
function M.open(feature,force,anchor)
    if not M.root then return false end
    feature=M.features[feature]and feature or 'quickChat'
    if M.inMatch and M.inMatch()then
        Telemetry.step('vip','lockPress',{item=feature,result='shown',reason='subscription_required',mode='pvp'})
        pcall(function()require(script.Parent.ToyAudio).play('block')end)
        seen('vipBubble');require(script.Parent.MatchBubble).vip(M.root,anchor,M.bubblePerks,function()require(script.Parent.MatchBubble).close();go(feature,'vipBubble')end)
        return false
    end
    if M.notify then M.notify(M.features[feature],true)end
    Telemetry.step('vip','lockPress',{item=feature,result=M.seen[feature]and not force and 'rejected'or 'shown',reason='subscription_required',mode=M.inMatch and M.inMatch()and 'pvp'or 'lobby'})
    if not force and M.seen[feature]then pcall(function()require(script.Parent.ToyAudio).play('block')end);return false end
    M.seen[feature]=true;M.close()
    Telemetry.step('social','vipLockShown',{item=feature});seen('vipCard')
    pcall(function()require(script.Parent.ToyAudio).play('block')end)
    local inMatch=M.inMatch and M.inMatch()
    local shade=UI.make('TextButton',M.root,{Name='VipLock',Text='',AutoButtonColor=false,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=60})
    shade.Activated:Connect(M.close);M.frame=shade
    local w,h=344,inMatch and 318 or 304
    local card=UI.make('Frame',shade,{Name='Card',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(w,h),BackgroundColor3=UI.colors.panel,BorderSizePixel=0,ZIndex=61,Active=true})
    UI.corner(card,6);UI.stroke(card,GOLD,2)
    local band=UI.make('Frame',card,{Name='Band',BackgroundColor3=GOLD,BorderSizePixel=0,ZIndex=61});UI.box(band,0,0,w,70);UI.corner(band,6)
    UI.make('UIGradient',band,{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(1,1)})})
    local badge=UI.make('Frame',card,{Name='Badge',BackgroundColor3=UI.colors.bg,BorderSizePixel=0,ZIndex=62});UI.box(badge,16,14,48,48);UI.corner(badge,24);UI.stroke(badge,GOLD,2)
    local icon=Icons.create(badge,'vip',28,GOLD);UI.box(icon,10,10,28,28);icon.ZIndex=63
    local title=UI.display(UI.label(card,'Title',Launch.club.name,20,GOLD));UI.box(title,76,14,w-92,28);title.ZIndex=62
    local need=UI.label(card,'Need',M.features[feature],13,UI.colors.ink);UI.box(need,76,40,w-92,22);need.ZIndex=62;need.TextTruncate=Enum.TextTruncate.AtEnd
    local y=84;local cw=(w-40)/2
    for i,perk in ipairs(M.perks)do
        local col,row=(i-1)%2,(i-1)//2
        local chip=UI.make('Frame',card,{Name='Perk'..i,BackgroundColor3=UI.colors.raised,BorderSizePixel=0,ZIndex=62});UI.box(chip,16+col*(cw+8),y+row*40,cw,34);UI.corner(chip,3)
        local tick=UI.label(chip,'Tick','✓',14,GOLD);UI.box(tick,8,0,16,34);tick.ZIndex=63
        local l=UI.label(chip,'Text',perk,12,UI.colors.ink);UI.box(l,26,0,cw-30,34);l.ZIndex=63;l.TextTruncate=Enum.TextTruncate.AtEnd
    end
    y+=3*40+6
    local free=UI.label(card,'Free','NO PAY-TO-WIN',11,UI.colors.muted);UI.box(free,16,y,w-32,18);free.ZIndex=62;y+=24
    if inMatch then local note=UI.label(card,'MatchNote','경기가 끝나면 사령부 상점에서도 볼 수 있어요.',11,UI.colors.muted);UI.box(note,16,y,w-32,16);note.ZIndex=62;y+=20 end
    local later=UI.button(card,'VipLater','나중에',M.close);UI.box(later,16,h-60,(w-40)*.38,44);later.ZIndex=62
    local shop=M.shop and M.shop();local billing=shop and shop.account and shop.account.billing
    local price=shop and billing and billing.club and shop:billingPrice('club',billing.club,'subscription')
    local label=not inMatch and '클럽 보기'or price and ('구독 R$ '..price)or '준비 중'
    local join=UI.button(card,'VipJoin',label,function()go(feature)end,true);UI.box(join,24+(w-40)*.38,h-60,(w-40)*.62,44);join.ZIndex=62
    join.BackgroundColor3=GOLD;join.TextColor3=UI.colors.bg
    if inMatch and not price then UI.enabled(join,false)end
    local scale=UI.make('UIScale',card,{Scale=.92})
    Tween:Create(shade,TweenInfo.new(.16),{BackgroundTransparency=.45}):Play()
    Tween:Create(scale,TweenInfo.new(.22,Enum.EasingStyle.Back),{Scale=1}):Play()
    return false
end
function M.hqPill(on)
    local pill=M.pill;local parent=M.root
    if not parent then return end
    M.wanted=on;if M.covered then on=false end
    if not on then if pill then pill.Visible=false end;return end
    if not pill or not pill.Parent then
        pill=UI.button(parent,'HqChatVip','',function()M.open('text',true)end);M.pill=pill;pill.ZIndex=18;pill.AnchorPoint=Vector2.new(1,0)
        pill.BackgroundColor3=UI.colors.bg;pill.BackgroundTransparency=.1;UI.stroke(pill,GOLD,1)
        local i=Icons.create(pill,'lock',16,GOLD);UI.box(i,12,16,16,16)
        local l=UI.label(pill,'Text','VIP 채팅과 음성',13,GOLD);UI.box(l,34,0,120,48)
    end
    pill.Size=UDim2.fromOffset(162,48)
    local ok,pos,size=pcall(function()local c=game:GetService('TextChatService').ChatWindowConfiguration;return c.AbsolutePosition,c.AbsoluteSize end)
    local s=UI.scale or 1
    if ok and typeof(pos)=='Vector2'and typeof(size)=='Vector2'and size.Y>0 then pill.AnchorPoint=Vector2.new(1,0);pill.Position=UDim2.fromOffset((pos.X+size.X)/s-parent.AbsolutePosition.X/s,(pos.Y+size.Y)/s-parent.AbsolutePosition.Y/s+6)
    elseif M.spot then pill.AnchorPoint=Vector2.new(1,0);pill.Position=UDim2.fromOffset(M.spot.X,M.spot.Y)
    elseif parent.AbsoluteSize.Y/s<500 then pill.AnchorPoint=Vector2.new(.5,0);pill.Position=UDim2.new(.5,0,0,58)
    else pill.AnchorPoint=Vector2.new(0,0);pill.Position=UDim2.new(0,24,0,72)end
    pill.Visible=true
end
return M
