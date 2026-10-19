local UI=require(script.Parent.ToyUI)
local K=require(script.Parent.SkinShopKit)
local Icons=require(script.Parent.OutgameIcons)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local FreeDraw=require(script.Parent.FreeDraw)
local M={}
local CENTER=Enum.TextXAlignment.Center;local LEFT=Enum.TextXAlignment.Left;local RIGHT=Enum.TextXAlignment.Right
local function step(name,data)pcall(function()require(script.Parent.TelemetryClient).step('shop',name,data)end)end
M.kinds={'basic','epic','legendary','mythic'}
M.titles={basic='보급 상자',epic='에픽 상자',legendary='전설 상자',mythic='신화 상자'}
M.promise={basic='노말~신화',epic='에픽 확정',legendary='전설 확정',mythic='신화 확정'}
local function pct(w)local v=w/10000;return (v%1==0 and string.format('%d%%',v)or string.format('%g%%',v))end
function M.oddsLine(kind)
    if kind=='basic'then return string.format('신화 %s  전설 %s',pct(Launch.weights.mythic),pct(Launch.weights.legendary))end
    return Launch.rarityNames[Launch.tickets[kind].rarity]..' 100%'
end
M.refund=math.floor(Launch.medalDrawCost*.2)
local function price(shop,kind,product,ptype,fallback)return K.robuxText(shop:billingPrice(kind,product,ptype),fallback)end
local function robuxButton(p,name,before,amount,fn,x,y,w,h,style,enabled)
    local b=UI.button(p,name,'',fn,style=='teal');UI.box(b,x,y,w,h);K.round(b,8);b.ClipsDescendants=true
    local color=(style=='gold'or style=='teal')and UI.colors.bg or typeof(style)=='Color3'and style~=UI.colors.line and style or UI.colors.ink
    if typeof(style)=='Color3'then b.BackgroundColor3=UI.colors.bg;b.BackgroundTransparency=.3;local e=b:FindFirstChildOfClass('UIStroke');if e then e.Color=style;e.Thickness=1.5 end
    elseif style=='gold'then b.BackgroundColor3=UI.colors.gold;UI.make('UIGradient',b,{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(214,200,170))});local e=b:FindFirstChildOfClass('UIStroke');if e then e.Color=UI.colors.gold end end
    if enabled==false then b.BackgroundColor3=UI.colors.panel;b.BackgroundTransparency=0;color=UI.colors.muted;local e=b:FindFirstChildOfClass('UIStroke');if e then e.Color=UI.colors.line;e.Thickness=1 end;local g=b:FindFirstChildOfClass('UIGradient');if g then g:Destroy()end end
    local size=h>=50 and 17 or 15
    local words=(before~=''and before..' 'or '');local tw=K.width(words,size,K.heavy);local aw=K.width(amount or '',size,K.heavy);local total=tw+(amount and size+4+aw or 0)
    local x0=(w-total)/2
    if words~=''then K.text(b,'Words',words,x0,0,tw+2,h,size,color,LEFT,K.heavy)end
    if amount then K.robux(b,size,color,x0+tw,(h-size)/2);K.text(b,'Amount',amount,x0+tw+size+4,0,aw+4,h,size,color,LEFT,K.heavy)end
    UI.enabled(b,enabled~=false);b.TextTransparency=0;return b
end
M.robuxButton=robuxButton
local function held(billing,kind)return billing.testingAvailable and (billing.testTickets[kind]or 0)or (billing.tickets[kind]or 0)end
function M.crate(hub,parent,shop,billing,kind,x,y,w,h,slim)
    local color=K.box[kind];local busy=shop.busy;local count=held(billing,kind)
    local card=K.round(UI.make('Frame',parent,{Name='Crate_'..kind,BackgroundColor3=UI.colors.panel,BorderSizePixel=0,ClipsDescendants=true}),8);UI.box(card,x,y,w,h)
    UI.stroke(card,kind=='basic'and UI.colors.line or color:Lerp(UI.colors.line,.45),1)
    UI.make('UIGradient',card,{Rotation=90,Color=ColorSequence.new(color:Lerp(UI.colors.panel,kind=='basic'and .85 or .7),UI.colors.panel)})
    UI.make('Frame',card,{Name='GradeStripe',BackgroundColor3=color,BorderSizePixel=0,Size=UDim2.new(1,0,0,3)})
    pcall(function()local p=billing.products and billing.products[kind];require(script.Parent.TelemetryClient).offer(card,kind,p~=nil and p.available==true and billing.paidRandomAllowed==true,'shopBox',billing)end)
    local pad=slim and 8 or 12
    K.chip(card,'Promise',M.promise[kind],color,pad,slim and 8 or 12,slim and 22 or 24,false,13)
    local odds=UI.button(card,'Odds_'..kind,slim and '확률'or '확률 ›',function()step('oddsItems',{item=kind});hub.supplyOdds=kind;hub:openPage('supply')end)
    UI.box(odds,w-(slim and 44 or 58),slim and 0 or 6,slim and 40 or 56,48);odds.TextSize=13;odds.TextXAlignment=Enum.TextXAlignment.Right;K.link(odds,UI.colors.ink:Lerp(UI.colors.muted,.3));odds.ZIndex=3
    local nameY=slim and math.floor(h*.36)or math.floor(h*.44)
    local view=require(script.Parent.CollectionPreview).create(card,nil,{crate=kind,name='CrateView',direction=Vector3.new(-.42,.5,-1).Unit});UI.box(view,pad,slim and 26 or 40,w-pad*2,nameY-(slim and 26 or 40));view.ZIndex=1
    local pool=K.round(UI.make('Frame',card,{Name='Spotlight',BackgroundColor3=color,BackgroundTransparency=.88,BorderSizePixel=0,ZIndex=0}),99);UI.box(pool,w*.22,nameY-(slim and 14 or 24),w*.56,slim and 10 or 16)
    K.text(card,'Name',M.titles[kind],4,nameY,w-8,slim and 20 or 26,slim and 15 or 19,UI.colors.ink,CENTER,K.heavy)
    local ry=nameY+(slim and 22 or 28)
    if not slim then K.text(card,'Odds',M.oddsLine(kind),4,ry,w-8,18,13,UI.colors.muted,CENTER);ry+=28 end
    local product=billing.products and billing.products[kind];local canBuy=not billing.testingAvailable and product~=nil and product.available==true and billing.paidRandomAllowed==true
    local amount=price(shop,kind,product,'product',Launch.tickets[kind].suggestedRobux)
    local row=K.round(UI.make('Frame',card,{Name='Tickets',BackgroundColor3=UI.colors.bg,BackgroundTransparency=.3,BorderSizePixel=0}),6);UI.box(row,pad,ry,w-pad*2,slim and 28 or 34);UI.stroke(row,UI.colors.line,1)
    local rw,rh=w-pad*2,slim and 28 or 34
    K.ticket(row,color,8,rh/2-6,18,12)
    K.text(row,'Label','뽑기권',32,0,60,rh,13,UI.colors.ink)
    local chipW=slim and math.min(70,rw*.46)or math.min(78,rw*.42)
    K.text(row,'Count',tostring(count),rw-chipW-34,0,26,rh,slim and 15 or 16,UI.colors.ink,RIGHT,K.heavy)
    do
        local chip=UI.button(row,'BuyTicket','',function()step('ticketChip',{item=kind});shop:purchaseBilling(kind,'shopBox')end);UI.box(chip,rw-chipW-4,4,chipW,rh-8);K.round(chip,99)
        if slim then local hit=UI.make('TextButton',chip,{Name='Hit',Text='',BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(1,0,0,48),ZIndex=chip.ZIndex+1});hit.Activated:Connect(function()if chip:GetAttribute("Enabled")~=false then step('ticketChip',{item=kind});shop:purchaseBilling(kind,'shopBox')end end)end
        chip.BackgroundColor3=UI.colors.raised;local e=chip:FindFirstChildOfClass('UIStroke');if e then e.Color=UI.colors.line end
        local cx=(chipW-K.width('+',13)-17-K.width(amount or '',13,K.heavy))/2
        K.text(chip,'Plus','+',cx,0,12,rh-8,13,UI.colors.ink);K.robux(chip,13,UI.colors.ink,cx+12,(rh-8-13)/2);K.text(chip,'Amount',amount or '',cx+28,0,chipW,rh-8,13,UI.colors.ink,LEFT,K.heavy)
        UI.enabled(chip,canBuy and not busy);if not(canBuy and not busy)then chip.BackgroundTransparency=.6 end
    end
    ry+=rh+(slim and 6 or 12)
    if kind=='basic'then
        if not slim then K.text(card,'Refund',string.format('중복이면 코인 %d 돌려받아요',M.refund),pad,ry,w-pad*2,20,13,UI.colors.muted,LEFT)end
    else
        local shards=not billing.testingAvailable and billing.fragments and billing.fragments[kind]or 0
        K.text(card,'ShardLabel','조각',pad,ry,34,16,13,UI.colors.muted)
        K.gauge(card,color,shards,pad+36,ry+5,w-pad*2-36-34,6)
        K.text(card,'ShardCount',string.format('%d/5',shards),w-pad-32,ry,32,16,13,UI.colors.ink,RIGHT,K.heavy)
    end
    local bh=slim and 48 or 46;local by=h-pad-bh
    if billing.testingAvailable and not(kind=='basic'and FreeDraw.ready(billing))then
        if count>0 then local b=UI.button(card,'Open',string.format('열기 (테스트 %d)',count),function()step('crateOpen',{item=kind});shop:drawSupply(kind,'studio')end,kind=='basic');UI.box(b,pad,by,w-pad*2,bh);K.round(b,8);UI.enabled(b,not busy)
            if kind~='basic'then local e=b:FindFirstChildOfClass('UIStroke');if e then e.Color=color;e.Thickness=1.5 end end
        else local b=UI.button(card,'TestGrant','테스트 보급 받기',function()shop:run(function()shop:request('supplyTestGrant')end)end);UI.box(b,pad,by,w-pad*2,bh);K.round(b,8);UI.enabled(b,not busy)end
        return card
    end
    if kind=='basic'then
        local medals=hub.account.progress and hub.account.progress.medals or 0
        local coin=UI.button(card,'MedalOpen','',function()step('crateOpen',{item='basic',value=Launch.medalDrawCost});shop:drawSupply('basic','medals')end);UI.box(coin,pad,by,w-pad*2,bh);K.round(coin,8)
        local words=slim and UI.commas(Launch.medalDrawCost)or string.format('%s으로 열기',UI.commas(Launch.medalDrawCost));local tw=K.width(words,slim and 14 or 15,K.heavy)
        UI.box(Icons.create(coin,'coin',18,UI.colors.gold),(w-pad*2-tw-24)/2,(bh-18)/2,18,18);K.text(coin,'Words',words,(w-pad*2-tw-24)/2+24,0,tw+4,bh,slim and 14 or 15,UI.colors.ink,LEFT,K.heavy)
        UI.enabled(coin,not busy and medals>=Launch.medalDrawCost);coin.TextTransparency=0
        if medals<Launch.medalDrawCost then coin.Words.TextColor3=UI.colors.muted;coin.BackgroundColor3=UI.colors.panel end
        local free=FreeDraw.ready(billing);local ph=slim and 48 or 50;local py=by-ph-8
        local label=free and '오늘 무료로 열기'or '뽑기권 1장으로 열기'
        local open=UI.button(card,free and 'FreeOpen'or 'Open',label,function()step('crateOpen',{item=free and 'basicFree'or 'basicTicket'});shop:drawSupply('basic',free and 'free'or 'ticket')end,true)
        UI.box(open,pad,py,w-pad*2,ph);K.round(open,8);open.TextSize=slim and 15 or 17;open.Font=K.heavy
        local can=free or count>0 and billing.paidRandomAllowed==true
        if can then UI.make('UIGradient',open,{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(205,215,214))})
        else open.BackgroundColor3=UI.colors.panel;open.TextColor3=UI.colors.muted;local e=open:FindFirstChildOfClass('UIStroke');if e then e.Color=UI.colors.line end end
        UI.enabled(open,can and not busy)
        if free then FreeDraw.dot(open,true,w-pad*2-8,6,12)end
    elseif count>0 then
        local b=UI.button(card,'Open','열기',function()step('crateOpen',{item=kind});shop:drawSupply(kind,'ticket')end);UI.box(b,pad,by,w-pad*2,bh);K.round(b,8);b.TextSize=slim and 15 or 17;b.Font=K.heavy
        b.BackgroundColor3=UI.colors.bg;b.BackgroundTransparency=.3;local e=b:FindFirstChildOfClass('UIStroke');if e then e.Color=color;e.Thickness=1.5 end
        UI.enabled(b,not busy and billing.paidRandomAllowed==true)
    else
        robuxButton(card,'Buy','',amount,function()step('crateBuy',{item=kind});shop:purchaseBilling(kind,'shopBox')end,pad,by,w-pad*2,bh,UI.colors.line,canBuy and not busy)
    end
    return card
end
M.members={
    club={name=Launch.club.name,color=UI.colors.ice,icon='vip',period='30일',cta='구독하기',owned='이용 중',ptype='subscription',fallback=Launch.club.suggestedRobux,
        tiles={{'custom','커스텀 게임','공개 방 만들기'},{'friends','채팅 켜기','글과 음성 채팅, 이모지 전체'}},
        rest={string.format('매일 뽑기권 %d장, XP 2배, 지휘 모션, 경기 관전',Launch.clubDailyTickets)}},
    permanent={name=Launch.permanent.name,color=UI.colors.gold,icon='marshal',period='영구',cta='구매하기',owned='보유 중',ptype='pass',fallback=Launch.permanent.suggestedRobux,
        tiles={{'clan','클랜 만들기와 가입','클랜은 프라임이 있어야 만들고 들어갈 수 있어요'}},
        rest={string.format('XP 2배, 프리셋 %d칸, 설정 보관함 %d칸',Launch.permanentLoadouts,Launch.permanentPresets),
            string.format('첫 구매 보너스 뽑기권 %d장(에픽 %d, 전설 %d, 신화 %d)',Launch.permanent.welcome.epic+Launch.permanent.welcome.legendary+Launch.permanent.welcome.mythic,Launch.permanent.welcome.epic,Launch.permanent.welcome.legendary,Launch.permanent.welcome.mythic)},
        short={string.format('XP 2배, 프리셋 %d칸, 보관함 %d칸, 첫 구매 뽑기권 %d장',Launch.permanentLoadouts,Launch.permanentPresets,Launch.permanent.welcome.epic+Launch.permanent.welcome.legendary+Launch.permanent.welcome.mythic)}},
}
function M.member(hub,parent,shop,billing,sku,x,y,w,h,slim)
    local o=M.members[sku];local color=o.color;local pad=slim and 12 or 18
    local card=K.round(UI.make('Frame',parent,{Name=sku=='club'and 'Club'or 'Permanent',BackgroundColor3=UI.colors.panel,BorderSizePixel=0,ClipsDescendants=true}),8);UI.box(card,x,y,w,h)
    UI.stroke(card,color:Lerp(UI.colors.line,.55),1)
    UI.make('UIGradient',card,{Rotation=90,Color=ColorSequence.new(color:Lerp(UI.colors.panel,.88),UI.colors.panel)})
    pcall(function()require(script.Parent.TelemetryClient).offer(card,sku,billing[sku]and billing[sku].available,'shopMember',billing)end)
    local is=slim and 34 or 44;local badge=K.round(UI.make('Frame',card,{Name='Badge',BackgroundColor3=UI.colors.bg,BackgroundTransparency=sku=='club'and 1 or .2,BorderSizePixel=0}),99);UI.box(badge,pad,pad,is,is)
    if sku~='club'then UI.stroke(badge,color,2)end
    UI.box(Icons.create(badge,o.icon,is-12,color),6,6,is-12,is-12)
    local tx=pad+is+12
    K.text(card,'Name',o.name,tx,pad-2,w-tx-pad,slim and 22 or 28,slim and 16 or 20,color,LEFT,K.heavy)
    local amount=K.robuxText(shop:billingPrice(sku,billing[sku],o.ptype),o.fallback)
    K.robux(card,13,UI.colors.ink,tx,pad+(slim and 24 or 32));local aw=K.width(amount,14,K.heavy)
    K.text(card,'Price',amount,tx+17,pad+(slim and 20 or 28),aw+4,22,14,UI.colors.ink,LEFT,K.heavy)
    K.text(card,'Period','/ '..o.period,tx+17+aw+6,pad+(slim and 20 or 28),80,22,13,UI.colors.muted)
    local ty=pad+is+(slim and 8 or 16);local n=#o.tiles;local tg=8;local tw=(w-pad*2-(n-1)*tg)/n;local th=slim and 82 or (n==1 and 100 or 104)
    for i,t in ipairs(o.tiles)do
        local tile=K.round(UI.make('Frame',card,{Name='Perk_'..t[1],BackgroundColor3=n==1 and color:Lerp(UI.colors.panel,.86)or UI.colors.raised,BackgroundTransparency=.1,BorderSizePixel=0}),8)
        UI.box(tile,pad+(i-1)*(tw+tg),ty,tw,th);UI.stroke(tile,color:Lerp(UI.colors.line,.4),1)
        if n==1 then
            UI.box(Icons.create(tile,t[1],slim and 26 or 34,color),slim and 12 or 22,(th-(slim and 26 or 34))/2,slim and 26 or 34,slim and 26 or 34)
            local lx=slim and 48 or 76
            K.text(tile,'Title',t[2],lx,th/2-(slim and 22 or 26),tw-lx-10,slim and 22 or 26,slim and 15 or 19,UI.colors.ink,LEFT,K.heavy)
            local s=K.text(tile,'Sub',slim and '클랜은 프라임 전용이에요'or t[3],lx,th/2+(slim and 0 or 2),tw-lx-10,slim and 20 or 22,13,UI.colors.ink:Lerp(UI.colors.muted,.3));s.TextWrapped=true
        else
            UI.box(Icons.create(tile,t[1],slim and 20 or 24,color),12,slim and 10 or 14,slim and 20 or 24,slim and 20 or 24)
            K.text(tile,'Title',t[2],12,slim and 34 or 46,tw-20,slim and 20 or 24,slim and 15 or 18,UI.colors.ink,LEFT,K.heavy)
            K.text(tile,'Sub',slim and (i==1 and '공개 방'or '글, 음성, 이모지')or t[3],12,slim and 56 or 72,tw-20,18,13,UI.colors.ink:Lerp(UI.colors.muted,.3))
        end
    end
    local ly=ty+th+(slim and 8 or 12)
    for i,line in ipairs(slim and o.short or o.rest)do local l=K.text(card,'Rest'..i,line,pad,ly,w-pad*2,slim and 18 or 20,13,UI.colors.muted);l.TextWrapped=slim;if slim then l.Size=UDim2.fromOffset(w-pad*2,36)end;ly+=slim and 36 or 22 end
    local owned=billing.benefits and billing.benefits[sku];local bh=slim and 48 or 46;local by=h-pad-bh
    local live=billing[sku]and billing[sku].available==true and shop:billingPrice(sku,billing[sku],o.ptype)~=nil
    if owned then
        local days=sku=='club'and billing.club and billing.club.daysLeft
        local s=UI.button(card,'MemberState',days and string.format('이용 중 %d일 남음',days)or o.owned,function()step('offer_'..sku,{sku=sku,result='active'});hub:openPage('benefits')end);UI.box(s,pad,by,w-pad*2,bh);K.round(s,8)
        s.BackgroundColor3=UI.colors.bg;s.BackgroundTransparency=.3;s.TextColor3=color;s.TextSize=slim and 15 or 17;s.Font=K.heavy
        local e=s:FindFirstChildOfClass('UIStroke');if e then e.Color=color:Lerp(UI.colors.line,.5)end
    else
        robuxButton(card,'Buy',o.cta,amount,function()step('offer_'..sku,{sku=sku,result='selected'});shop:purchaseBilling(sku,'shopMember')end,pad,by,w-pad*2,bh,sku=='club'and color or 'gold',live and not shop.busy)
    end
    return card
end
function M.odds(hub,root)
    local old=root:FindFirstChild('OddsSheet');if old then old:Destroy()end
    step('oddsView',{item='grades'})
    local shade=UI.make('TextButton',root,{Name='OddsSheet',Text='',AutoButtonColor=false,BackgroundColor3=UI.colors.bg,BackgroundTransparency=.25,BorderSizePixel=0,ZIndex=50,Size=UDim2.fromScale(1,1),Position=UDim2.new()})
    shade.Activated:Connect(function()shade:Destroy()end)
    local W,H=root.AbsoluteSize.X/require(script.Parent.Theme).scale,root.AbsoluteSize.Y/require(script.Parent.Theme).scale;local w=math.min(420,W-24);local rows=#K.order;local rh=H<420 and 30 or 36;local top=H<420 and 56 or 64;local h=math.min(H-top-8,56+rows*rh+96)
    local p=K.panel(shade,'Sheet',(W-w)/2,top+math.max(0,(H-top-8-h)/2),w,h,UI.colors.panel);p.ZIndex=51;p.Active=true
    K.text(p,'Title','확률 보기',18,10,w-80,32,19,UI.colors.ink,LEFT,K.heavy).ZIndex=52
    local close=UI.button(p,'Close','×',function()shade:Destroy()end);UI.box(close,w-52,4,48,48);close.TextSize=22;close.BackgroundTransparency=1;close.ZIndex=52
    local y=50
    K.text(p,'Head','등급별 보급 상자',18,y,w-36,20,13,UI.colors.muted).ZIndex=52;y+=24
    for _,r in ipairs(K.order)do
        local c=K.rarity[r];local dot=K.round(UI.make('Frame',p,{Name='Dot_'..r,BackgroundColor3=c,BorderSizePixel=0,ZIndex=52}),99);UI.box(dot,22,y+rh/2-5,10,10)
        K.text(p,'Grade_'..r,Launch.rarityNames[r],42,y,w-140,rh,15,UI.colors.ink,LEFT,K.heavy).ZIndex=52
        K.text(p,'Rate_'..r,pct(Launch.weights[r]),w-118,y,96,rh,15,c,RIGHT,K.heavy).ZIndex=52
        y+=rh
    end
    local n=K.text(p,'Grades','에픽, 전설, 신화 상자는 그 등급만 나와요(100%).',18,y+4,w-36,20,13,UI.colors.muted);n.ZIndex=52;y+=30
    local more=UI.button(p,'ItemOdds','아이템별 확률 보기 ›',function()shade:Destroy();step('oddsItems',{item='basic'});hub.supplyOdds='basic';hub:openPage('supply')end)
    UI.box(more,18,y,w-36,44);more.ZIndex=52;K.round(more,8)
    return shade
end
return M
