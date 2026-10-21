local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local Crates=require(script.Parent.SupplyCrateArt)
local Wallet=require(script.Parent.PageWallet)
local FreeDraw=require(script.Parent.FreeDraw)
local M={}
local function step(name,data)local ok,T=pcall(require,script.Parent.TelemetryClient);if ok and T.step then pcall(T.step,'shop',name,data)end end
local kinds={'basic','epic','legendary','mythic'}
local titles={basic='보급 상자',epic='에픽 보급 상자',legendary='전설 보급 상자',mythic='신화 보급 상자'}
local promises={basic='모든 등급',epic='에픽 확정',legendary='전설 확정',mythic='신화 확정'}
local function text(p,name,value,x,y,w,h,size,color,center)
    local l=UI.label(p,name,value,size,color);UI.box(l,x,y,w,h);l.TextWrapped=false
    if center then l.TextXAlignment=Enum.TextXAlignment.Center end;return l
end
local function action(parent,name,label,color,fn,enabled,x,y,w,h,filled)
    local b=UI.button(parent,name,label,function()step('crate'..name,{item=parent.Name:match('^Crate_(.+)')or parent.Name});fn()end,true);UI.box(b,x,y,w,h);b.TextSize=h>=46 and 18 or 15
    b.BackgroundColor3=filled~=false and color or UI.colors.raised;b.TextColor3=filled~=false and UI.colors.bg or color
    local edge=b:FindFirstChildOfClass('UIStroke');if edge then edge.Color=color;edge.Thickness=filled~=false and 0 or 1.5 end
    UI.enabled(b,enabled);return b
end
local function robux(price)
    local digits=price:match('^%s*([%d,]+)%s*Robux')or price:match('^%s*R%$%s*([%d,]+)')or price:match('^%s*([%d,]+)%s*$')
    local n=digits and tonumber((digits:gsub(',','')))
    if not n then return nil end
    local s=tostring(math.floor(n));local out=s:reverse():gsub('(%d%d%d)','%1,'):reverse()
    return (out:gsub('^,',''))
end
local offers={
    club={color=UI.colors.vip,ribbon='월간 구독 30일',tagline='내 커스텀 게임을 누구나 찾게',value='공개 커스텀 게임 만들기',
        cta='월 R$ %s 구독하기',note='30일마다 자동 갱신, 언제든 해지',owned='구독 중',more='구독 중, 혜택 보기  ›',
        perks={{'custom','누구나 참가 가능'},{'friends','글과 음성 채팅'},{'cheer','이모지와 모션 전부'},{'daily','매일 뽑기권 1장'},{'xp','계정 XP 2배'},{'watch','다른 경기 관전'}}},
    permanent={color=UI.colors.prime,ribbon='한 번 구매로 영구 소장',tagline='한 번 사면 평생 커맨더',value='뽑기권 4장 한 번에 지급',
        cta='R$ %s 평생 소장',note='한 번 결제로 계속 유지',owned='보유 중',more='보유 중, 혜택 보기  ›',
        perks={{'reward','신화 뽑기권 포함'},{'xp','평생 계정 XP 2배'},{'wardrobe','스킨 프리셋 +2칸'},{'custom','커스텀 설정 12칸'},{'marshal','프라임 커맨더 마크'},{'clan','클랜 만들기와 가입'}}},
}
M.offers=offers
local Tween=game:GetService('TweenService')
local function loop(o,info,goal)local ok,t=pcall(function()return Tween:Create(o,info,goal)end);if ok and t then t:Play()end end
local function glow(card,cx,cy,r,color,alpha)
    for i=3,1,-1 do
        local d=r*(.45+i*.28)
        local g=UI.corner(UI.make('Frame',card,{Name='Glow',AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=color,BackgroundTransparency=1-alpha/i,BorderSizePixel=0,ZIndex=0}),999)
        UI.box(g,cx,cy,d*2,d*1.5)
    end
end
local function rays(card,cx,cy,len,color)
    for i=0,5 do
        local r=UI.make('Frame',card,{Name='Ray',AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=color,BackgroundTransparency=.55,BorderSizePixel=0,Rotation=i*30+8,ZIndex=0})
        UI.box(r,cx,cy,len,i%2==0 and 10 or 5)
        UI.make('UIGradient',r,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,.35),NumberSequenceKeypoint.new(1,1)})})
    end
end
local function brackets(card,w,h,color)
    for _,c in ipairs({{0,0,1,1},{1,0,-1,1},{0,1,1,-1},{1,1,-1,-1}})do
        local x=c[1]*w+(c[3]>0 and 6 or -6);local y=c[2]*h+(c[4]>0 and 6 or -6)
        UI.box(UI.make('Frame',card,{Name='Bracket',AnchorPoint=Vector2.new(c[1],c[2]),BackgroundColor3=color,BorderSizePixel=0,ZIndex=6}),x,y,18,2)
        UI.box(UI.make('Frame',card,{Name='Bracket',AnchorPoint=Vector2.new(c[1],c[2]),BackgroundColor3=color,BorderSizePixel=0,ZIndex=6}),x,y,2,18)
    end
end
local function sparkle(card,x,y,s,color,delay)
    local d=UI.make('Frame',card,{Name='Sparkle',AnchorPoint=Vector2.new(.5,.5),Rotation=45,BackgroundColor3=color,BackgroundTransparency=.1,BorderSizePixel=0,ZIndex=3});UI.box(d,x,y,s,s)
    loop(d,TweenInfo.new(1.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true,delay),{BackgroundTransparency=.85})
end
M.offerHeight=462
local function shortBody(body)return body.AbsoluteSize.Y>0 and body.AbsoluteSize.Y/require(script.Parent.Theme).scale<330 end
function M.offerHeightFor(body)return shortBody(body)and M.offerHeight-68 or M.offerHeight end
function M.offerCard(hub,body,shop,billing,sku,x,y,w,options)
    options=options or {}
    local o=offers[sku];local color=o.color;local club=sku=='club';local h=M.offerHeightFor(body);local pad=14;local short=h<M.offerHeight
    local deep=color:Lerp(UI.colors.bg,.82)
    local card=UI.corner(UI.make('Frame',body,{Name=club and 'Club'or 'Permanent',BackgroundColor3=UI.colors.panel,BorderSizePixel=0,ClipsDescendants=true}),10);UI.box(card,x,y,w,h)
    local edge=UI.stroke(card,color,2)
    UI.make('UIGradient',edge,{Rotation=35,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color:Lerp(Color3.new(1,1,1),.55)),ColorSequenceKeypoint.new(.5,color),ColorSequenceKeypoint.new(1,color:Lerp(UI.colors.bg,.35))})})
    UI.make('UIGradient',card,{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,deep),ColorSequenceKeypoint.new(.45,color:Lerp(UI.colors.panel,.9)),ColorSequenceKeypoint.new(1,UI.colors.panel)})})
    pcall(require(script.Parent.TelemetryClient).offer,card,sku,billing[sku]and billing[sku].available,options.inPage and 'benefits'or 'shopMember',billing)
    local ah=short and 120 or 188;local cx=w/2
    glow(card,cx,ah*.48,math.min(w*.36,140),color,.3)
    rays(card,cx,ah*.48,w*1.25,color)
    local pool=UI.corner(UI.make('Frame',card,{Name='Spotlight',AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=color,BackgroundTransparency=.7,BorderSizePixel=0,ZIndex=0}),999)
    UI.box(pool,cx,ah*.76,w*.34,16)
    local view=require(script.Parent.CollectionPreview).create(card,nil,{product=sku,name='ProductView',direction=Vector3.new(-.35,.36,-1).Unit})
    UI.box(view,cx-math.min(w*.42,170),2,math.min(w*.84,340),ah);view.ZIndex=1
    for i,p in ipairs({{.14,.30,7},{.86,.22,9},{.80,.62,6},{.22,.70,5},{.68,.12,5}})do sparkle(card,w*p[1],ah*p[2],p[3],color:Lerp(Color3.new(1,1,1),.6),i*.37)end
    local plate=UI.make('Frame',card,{Name='Plate',BackgroundColor3=UI.colors.bg,BorderSizePixel=0,ZIndex=2});UI.box(plate,0,ah-70,w,82)
    UI.make('UIGradient',plate,{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.55,.25),NumberSequenceKeypoint.new(1,.1)})})
    local name=text(card,'Name',club and Launch.club.name or Launch.permanent.name,pad,ah-34,w-pad*2,32,w>=330 and 27 or 23,UI.colors.ink)
    name.Font=Enum.Font.BuilderSansExtraBold;name.ZIndex=4;name.TextTruncate=Enum.TextTruncate.AtEnd
    UI.make('UIStroke',name,{Color=color:Lerp(UI.colors.bg,.5),Thickness=1.5,Transparency=.2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
    local tag=text(card,'Tagline',o.tagline,pad,ah-4,w-pad*2,20,14,color);tag.ZIndex=4;tag.TextTruncate=Enum.TextTruncate.AtEnd
    local ribbon=UI.pill(card,'Period',o.ribbon,color);UI.box(ribbon,pad,12,club and 120 or 126,24);ribbon.TextSize=13;UI.corner(ribbon,99);ribbon.ZIndex=5
    ribbon.Font=Enum.Font.BuilderSansExtraBold
    local seal=UI.corner(UI.make('Frame',card,{Name='Seal',BackgroundColor3=UI.colors.bg,BackgroundTransparency=.15,BorderSizePixel=0,ZIndex=5}),99);UI.box(seal,w-pad-34,8,34,34);UI.stroke(seal,color,1.5)
    UI.box(Icons.create(seal,club and 'vip'or 'marshal',20,color),7,7,20,20)
    local sy=ah+24
    local strip=UI.corner(UI.make('Frame',card,{Name='Value',BackgroundColor3=color,BackgroundTransparency=.86,BorderSizePixel=0}),6);UI.box(strip,pad,sy,w-pad*2,34);UI.stroke(strip,color:Lerp(UI.colors.line,.25),1)
    local vx=10
    if club then UI.box(Icons.create(strip,'custom',18,color),10,8,18,18);vx=34
    else
        for i,kind in ipairs({'epic','epic','legendary','mythic'})do
            local chip=UI.make('Frame',strip,{Name='Key'..i,AnchorPoint=Vector2.new(.5,.5),Rotation=45,BackgroundColor3=Crates.colors[kind],BorderSizePixel=0});UI.box(chip,16+(i-1)*14,17,10,10)
        end
        vx=16+4*14
    end
    local v=text(strip,'ValueText',o.value,vx,0,w-pad*2-vx-8,34,14,UI.colors.ink);v.Font=Enum.Font.BuilderSansExtraBold;v.TextTruncate=Enum.TextTruncate.AtEnd
    local gy=sy+44
    local head=text(card,'IncludesHead','포함 내용',0,gy,w,16,13,color,true);head.Font=Enum.Font.BuilderSansExtraBold
    for _,side in ipairs({-1,1})do
        local line=UI.make('Frame',card,{Name='HeadLine',AnchorPoint=Vector2.new(side<0 and 1 or 0,.5),BackgroundColor3=color,BackgroundTransparency=.55,BorderSizePixel=0})
        UI.box(line,cx+side*40,gy+8,w/2-40-pad,1)
    end
    local cw=(w-pad*2)/2
    for i,perk in ipairs(o.perks)do
        local px=pad+((i-1)%2)*cw;local py=gy+22+math.floor((i-1)/2)*28
        local row=UI.make('Frame',card,{Name='Perk'..i,BackgroundTransparency=1});UI.box(row,px,py,cw-4,26)
        UI.box(Icons.create(row,perk[1],18,color),0,4,18,18)
        local l=text(row,'Text',perk[2],24,0,cw-30,26,cw<150 and 13 or 14,UI.colors.ink);l.TextTruncate=Enum.TextTruncate.AtEnd
    end
    local by=gy+22+3*28+8;local owned=billing.benefits and billing.benefits[sku]
    local price=shop:billingPrice(sku,billing[sku],club and 'subscription'or 'pass')
    local amount=price and robux(price)
    local label=owned and (options.inPage and o.owned or o.more)or amount and string.format(o.cta,amount)or price or '판매 준비 중'
    local buy=UI.button(card,'Buy',label,function()
        step('offer_'..sku,{sku=sku,result=owned and 'active'or 'selected'})
        if owned then if not options.inPage then hub:openPage('benefits')end else shop:purchaseBilling(sku,options.inPage and 'benefits'or 'shopMember')end
    end,true);UI.box(buy,pad,by,w-pad*2,54);buy.TextSize=w>=360 and 20 or 18;buy.Font=Enum.Font.BuilderSansExtraBold;buy.ClipsDescendants=true
    buy:FindFirstChildOfClass('UICorner').CornerRadius=UDim.new(0,8)
    local bedge=buy:FindFirstChildOfClass('UIStroke')
    if owned then buy.BackgroundColor3=UI.colors.raised;buy.TextColor3=color;if bedge then bedge.Color=color;bedge.Thickness=1.5 end
    elseif price==nil then buy.BackgroundColor3=UI.colors.raised;buy.TextColor3=UI.colors.muted;if bedge then bedge.Color=UI.colors.muted;bedge.Thickness=1 end
    else
        buy.BackgroundColor3=color;buy.TextColor3=UI.colors.bg;if bedge then bedge.Color=color:Lerp(Color3.new(1,1,1),.6);bedge.Thickness=1.5 end
        UI.make('UIGradient',buy,{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(200,200,200))})
        local shine=UI.make('Frame',buy,{Name='Shine',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(-.3,0,.5,0),Size=UDim2.new(0,46,2,0),Rotation=20,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.55,BorderSizePixel=0,Active=false})
        UI.make('UIGradient',shine,{Rotation=0,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)})})
        loop(shine,TweenInfo.new(1.1,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut,-1,false,2.4),{Position=UDim2.new(1.3,0,.5,0)})
        if bedge then loop(bedge,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Thickness=3})end
    end
    UI.enabled(buy,owned and not options.inPage or (not owned and price~=nil and not shop.busy))
    if owned and options.inPage then buy.TextTransparency=0 end
    text(card,'Terms',owned and (club and '구독 기간 동안 적용 중'or '영구 적용 중')or o.note,30,by+60,w-60,18,13,UI.colors.muted,true)
    brackets(card,w,h,color:Lerp(Color3.new(1,1,1),.35))
    if not options.inPage then
        local more=UI.button(card,'More','',function()hub:openPage('benefits')end);more.BackgroundTransparency=1;UI.box(more,0,0,w,by-4);more.ZIndex=0
        local e=more:FindFirstChildOfClass('UIStroke');if e then e.Enabled=false end
    end
    return card
end
function M.draw(hub,body,w)
    hub.pageTitle.Text='상점'
    local a=hub.account or {};local billing=a.billing;local shop=hub.callbacks.shop()
    local Cards=require(script.Parent.ShopCards);local K=require(script.Parent.SkinShopKit)
    local inset=body:FindFirstChild('ContentInset');if inset then inset:Destroy()end
    local W,H=body.Size.X.Offset,body.Size.Y.Offset;if W<10 then W,H=w,520 end
    if not a.ready or not billing then
        require(script.Parent.TelemetryStep).once('shopLoading','shop','loading',{reason='loading'})
        text(body,'Loading','보관함을 불러오는 중…',4,8,W-8,40,15,UI.colors.muted);body.CanvasSize=UDim2.fromOffset(0,60);return
    end
    require(script.Parent.TelemetryStep).once('shopBoard','shop','board',{item=hub.shopTab or 'boxes'})
    local slim=H<420;local side=W>=1100 and not slim;local tab=side and 'both'or hub.shopTab or 'boxes'
    local gap=slim and 8 or 16;local y=0;local hh=slim and 36 or 44
    local mw=side and math.min(440,math.floor(W*.32))or W;local lw=side and W-mw-gap or W
    local x=0
    if side then local t=text(body,'Title','보급 상자',0,y,140,hh,24,UI.colors.ink);t.Font=K.heavy;x=K.width('보급 상자',24,K.heavy)+14
    else
        K.switch(body,'ShopTab',{{id='boxes',text='보급 상자'},{id='members',text='멤버십'}},tab=='members'and 2 or 1,function(i)hub.shopTab=i==2 and 'members'or 'boxes';require(script.Parent.TelemetryStep).step('shop','tab',{item=hub.shopTab});hub:drawPage()end,0,y+(hh-34)/2,200,34,14)
        x=212
    end
    if tab~='members'then K.chip(body,'FairChip','외형만, 능력치 없음',UI.colors.ink,x,y+(hh-26)/2,26,false,13)
        if lw-136>=x+K.width('외형만, 능력치 없음',13)+28 then
            local odds=UI.button(body,'OddsLink','확률 보기 ›',function()Cards.odds(hub,hub.overlay)end);UI.box(odds,lw-136,y+(hh-48)/2,136,48);odds.TextSize=14;odds.TextXAlignment=Enum.TextXAlignment.Right;K.link(odds,UI.colors.ice)
            local e=odds:FindFirstChildOfClass('UIStroke');if e then e.Enabled=false end
        end
    else text(body,'Combo','둘 다 있으면 XP 4배',x,y,W-x-120,hh,13,UI.colors.muted)end
    if side then text(body,'MembersTitle','멤버십',lw+gap,y,120,hh,24,UI.colors.ink).Font=K.heavy;text(body,'Combo','둘 다 있으면 XP 4배',lw+gap+K.width('멤버십',24,K.heavy)+16,y,200,hh,13,UI.colors.muted)end
    if tab~='boxes'then local r=UI.button(body,'Restore','구매 복원',function()require(script.Parent.TelemetryStep).step('shop','restore',{});shop:run(function()shop:request('restore')end)end)
        UI.box(r,W-128,y+(hh-48)/2,112,48);r.TextSize=13;r.TextXAlignment=Enum.TextXAlignment.Right;K.link(r,UI.colors.muted);UI.enabled(r,not shop.busy)end
    y+=hh+(slim and 6 or 10)
    local bodyH=H-y
    if tab~='members'then
        local cols=lw>=560 and 4 or 2;local cg=slim and 8 or 12;local cw=(lw-cg*(cols-1))/cols
        local rule=string.format('이미 가진 외형이 나오면 보상으로 바꿔 줘요. 코인이나 무료로 열었다면 코인 %d을 돌려받아요. 뽑기권으로 열었다면 그 상자 조각 1개를 받고, 5개면 뽑기권 1장이 돼요.',Cards.refund)
        local ruleH=game:GetService('TextService'):GetTextSize(rule,14,Enum.Font.BuilderSansBold,Vector2.new(lw-120,1000)).Y
        local info=slim and 0 or math.max(100,ruleH+56);local ch=cols==4 and math.max(slim and 200 or 320,bodyH-(info>0 and info+gap or 0))or 300
        for i,kind in ipairs(Cards.kinds)do Cards.crate(hub,body,shop,billing,kind,(i-1)%cols*(cw+cg),y+math.floor((i-1)/cols)*(ch+cg),cw,ch,slim or cols==2)end
        local yy=y+math.ceil(#Cards.kinds/cols)*(ch+cg)-cg
        if info>0 then
            local panel=K.panel(body,'DuplicateRule',0,yy+gap,lw,info)
            local art=require(script.Parent.CollectionPreview).create(panel,nil,{crate='basic',name='RuleCrate',direction=Vector3.new(-.42,.5,-1).Unit});UI.box(art,14,14,72,info-28)
            text(panel,'Title','중복 보상',100,14,lw-120,24,16,UI.colors.ink).Font=K.heavy
            local l=text(panel,'Rule',rule,100,40,lw-120,info-48,14,UI.colors.ink:Lerp(UI.colors.muted,.3))
            l.TextWrapped=true;l.TextYAlignment=Enum.TextYAlignment.Top;yy+=gap+info
        end
        y=math.max(y,yy)
    end
    if tab~='boxes'then
        local my=side and hh+10 or y;local mx=side and lw+gap or 0
        local two=not side and W>=520;local cw=two and (W-gap)/2 or mw
        local ch=side and math.floor((H-my-gap)/2)or slim and math.max(220,bodyH)or 364
        Cards.member(hub,body,shop,billing,'club',mx,my,cw,ch,slim)
        Cards.member(hub,body,shop,billing,'permanent',two and mx+cw+gap or mx,side and my+ch+gap or two and my or my+ch+gap,cw,ch,slim)
        y=math.max(y,side and H or (two and my+ch or my+ch*2+gap))
    end
    if not billing.paidRandomAllowed and not billing.testingAvailable then
        require(script.Parent.TelemetryStep).once('paidRestricted','shop','paidRestricted',{reason=billing.policyKnown and 'policy_restricted'or 'not_loaded'})
        local l=text(body,'PaidRestriction',billing.policyKnown and '이 계정에서는 유료 뽑기를 이용할 수 없어요. 코인 뽑기는 이용할 수 있어요.'or '이용 가능 여부를 확인하지 못했어요. 다시 시도해 주세요.',0,y+8,W,36,13,UI.colors.muted,true);l.TextWrapped=true;y+=48
    elseif billing.salesOpen==false and not billing.testingAvailable then
        require(script.Parent.TelemetryStep).once('salesClosed','shop','salesClosed',{reason='sales_disabled'})
        local l=text(body,'SalesClosed','지금은 Robux 판매를 잠시 멈췄어요. 가진 뽑기권과 혜택은 그대로 쓸 수 있어요.',0,y+8,W,36,13,UI.colors.muted,true);l.TextWrapped=true;y+=48
    end
    local dev=script.Parent:FindFirstChild('DevPanel');if dev then y=require(dev).draw(hub,body,W,y+8,shop)end
    body.CanvasSize=UDim2.fromOffset(0,y>H+1 and y+8 or 0)
end
return M
