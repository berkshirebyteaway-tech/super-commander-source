local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local Art=require(script.Parent.Art20)
local Pop=require(script.Parent.Pop20)
local Cards=require(script.Parent.ShopCards)
local Kit=require(script.Parent.SkinShopKit)
local FreeDraw=require(script.Parent.FreeDraw)
local Step=require(script.Parent.TelemetryStep)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local Sale=require(script.Parent.Parent.Core.LaunchSale)
local C=K.colors
local M={}
local KINDS={'basic','epic','legendary','mythic'}
local COLOR={basic=K.rarity.normal,epic=K.rarity.epic,legendary=K.rarity.legendary,mythic=K.rarity.mythic}
local function step(name,data)pcall(function()require(script.Parent.TelemetryClient).step('shop',name,data)end)end
local function offer(card,sku,available,origin,billing)pcall(function()require(script.Parent.TelemetryClient).offer(card,sku,available,origin,billing)end)end
local function held(billing,kind)return billing.testingAvailable and (billing.testTickets[kind]or 0)or (billing.tickets[kind]or 0)end
local function shards(billing,kind)return not billing.testingAvailable and billing.fragments and billing.fragments[kind]or 0 end
local function oddsLine(kind)return kind=='basic'and '노말 이상'or Cards.oddsLine(kind)end
local function mix(a,b,t)return a:Lerp(b,t)end
local function now()local ok,t=pcall(function()return workspace:GetServerTimeNow()end);return ok and t or os.time()end
local CRATE_FILL=.92
local FRAG_GAIN=tonumber((Launch :: any).fragmentGain)or 1
local FRAG_PER=tonumber((Launch :: any).fragmentsPerTicket)or 5
local function welcomeColors()local _,colors=Pop.primeTickets();return colors end
local function welcomeSplit()local _,_,split=Pop.primeTickets();return split end

local function robuxMark(parent,size,color,name)
    return K.make('ImageLabel',parent,{Name=name or 'Robux',BackgroundTransparency=1,Image='rbxasset://textures/ui/common/robux.png',ImageColor3=color or C.ink,ScaleType=Enum.ScaleType.Fit,Size=UDim2.fromOffset(size,size)})
end
local function inline(face,w,h,parts,gap,align,left)
    local objs={};local total=0
    for i,p in ipairs(parts)do
        local o,pw,txt
        if p.robux then o=robuxMark(face,p.robux,p.color,'Robux'..i);pw=p.robux
        elseif p.icon then o=K.icon(face,p.icon,p.size,p.color,'Icon'..i);pw=p.size;if p.white then o.ImageColor3=Color3.new(1,1,1)end
        elseif p.num then o=K.num(face,'Num'..i,p.num,p.size,p.color);pw=K.width(p.num,p.size,o);txt=true
        else o=K.text(face,'Text'..i,p.text,p.size,p.color,p.weight or 800);pw=K.width(p.text,p.size,o);txt=true end
        o.ZIndex=face.ZIndex+2;objs[i]={o=o,w=pw,s=p.robux or p.size,txt=txt}
        total+=pw+(i>1 and(p.gap or gap or 6)or 0)
    end
    local x=align=='left'and(left or 0)or math.floor((w-total)/2)
    for i,e in ipairs(objs)do
        if i>1 then x+=parts[i].gap or gap or 6 end
        if e.txt then K.box(e.o,x,0,e.w+2,h)else K.box(e.o,x,math.floor((h-e.s)/2+.5),e.s,e.s)end
        x+=e.w
    end
    return objs,total
end
local function painted(parent,name,look,cb)
    local b=K.button(parent,name,{kind='none',r=look.r or 8},cb)
    local f,st=b.face,b.faceStroke
    f.BackgroundColor3=look.fill or C.raised;f.BackgroundTransparency=look.alpha or 0
    st.Enabled=look.stroke~=nil;if look.stroke then st.Color=look.stroke;st.Thickness=look.thick or 1;st.Transparency=look.strokeAlpha or 0 end
    b.baseFill=f.BackgroundColor3;b.baseAlpha=f.BackgroundTransparency;b.baseStroke=st.Color
    return b
end
local function dim(b)
    b:setEnabled(false,true)
    for _,d in ipairs(b.face:GetDescendants())do
        if d:IsA('TextLabel')then d.TextTransparency=.5 elseif d:IsA('ImageLabel')then d.ImageTransparency=.5 end
    end
    b.faceStroke.Transparency=math.max(b.faceStroke.Transparency,.55)
end
local function infoButton(parent,size,color,cb)
    local b=K.button(parent,'Info',{kind='none',icon='info',iconSize=size,sound='click'},cb)
    b.iconColorFixed=true;b.iconImage.ImageColor3=color or C.muted
    return b
end
local function ticketChip(parent,count,color,h,fs,is)
    local f=K.make('Frame',parent,{Name='Tickets',BackgroundColor3=C.bg,BorderSizePixel=0});K.round(f,4)
    local _,w=inline(f,400,h,{{icon='ticket',size=is,color=color},{num='×'..tostring(count),size=fs,color=C.ink}},4,'left',6)
    f.Size=UDim2.fromOffset(6+w+6,h);return f,6+w+6
end
local function pieceRow(parent,kind,n,x,y,w,fs)
    local l=K.num(parent,'Pieces',string.format('%d/%d',n,FRAG_PER),fs,C.muted,Enum.TextXAlignment.Right)
    local lw=K.width(l.Text,fs,l);K.box(l,x+w-lw-1,y-math.floor((fs+6-4)/2),lw+1,fs+6)
    local bar=K.fillBar(parent,'PieceBar',{p=math.clamp(n/FRAG_PER,0,1),fill=COLOR[kind],track=C.raised});K.box(bar.frame,x,y,w-lw-1-6,4)
    return bar
end

local function saleLeft(ends)
    local left=ends-now();if left>=86400 then return string.format('%d일',math.ceil(left/86400))end;return Sale.left(left)
end
local function saleChip(ctx,right,y,h,fs)
    local ends=Cards.saleEnds(ctx.billing);if not ends then return end
    Step.once('saleBanner','shop','saleBanner',{result='shown'})
    local f=K.make('Frame',ctx.root,{Name='SaleChip',BackgroundColor3=C.gold,BackgroundTransparency=.86,BorderSizePixel=0});K.round(f,4)
    local function paint()
        for _,o in ipairs(f:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
        local _,w=inline(f,400,h,{{num=string.format('-%d%%',Sale.percent),size=fs,color=C.gold},{icon='clock',size=fs,color=C.gold},{text=saleLeft(ends),size=fs,color=C.gold,weight=700}},6,'left',6)
        K.box(f,right-(w+12),y,w+12,h)
    end
    paint()
    task.spawn(function()while f.Parent do task.wait(20);if not f.Parent then break end;if now()>=ends then ctx.hub:drawPage();break end;paint()end end)
    return f
end

local function action(ctx,kind)
    local billing,shop=ctx.billing,ctx.shop;local busy=shop.busy;local count=held(billing,kind)
    if billing.testingAvailable and not(kind=='basic'and FreeDraw.ready(billing))then
        if count>0 then return {key='TestOpen',style='open',label=string.format('열기 (테스트 %d)',count),enabled=not busy,run=function()step('crateOpen',{item=kind});shop:drawSupply(kind,'studio')end}end
        return {key='TestGrant',style='plain',label='테스트 보급 받기',enabled=not busy,run=function()shop:run(function()shop:request('supplyTestGrant')end)end}
    end
    if kind=='basic'and FreeDraw.ready(billing)then
        return {key='FreeOpen',style='pri',label='무료 열기',enabled=not busy,run=function()step('crateOpen',{item='basicFree'});shop:drawSupply('basic','free')end}
    end
    if count>0 then
        return {key='Open',style='open',label='열기',enabled=not busy and billing.paidRandomAllowed==true,run=function()step('crateOpen',{item=kind=='basic'and 'basicTicket'or kind});shop:drawSupply(kind,'ticket')end}
    end
    if kind=='basic'then
        local medals=ctx.hub.account.progress and ctx.hub.account.progress.medals or 0
        return {key='MedalOpen',style='price',coin=true,amount=Theme.commas(Launch.medalDrawCost),enabled=not busy and medals>=Launch.medalDrawCost,run=function()step('crateOpen',{item='basic',value=Launch.medalDrawCost});shop:drawSupply('basic','medals')end}
    end
    local product=billing.products and billing.products[kind]
    local canBuy=not billing.testingAvailable and product~=nil and product.available==true and billing.paidRandomAllowed==true
    return {key='Buy',style='price',amount=Kit.robuxText(shop:billingPrice(kind,product,'product'),Launch.tickets[kind].suggestedRobux),enabled=canBuy and not busy,run=function()step('crateBuy',{item=kind});shop:purchaseBilling(kind,'shopBox')end}
end
local function actionButton(parent,ctx,kind,a,x,y,w,sz)
    local col=COLOR[kind];local b
    if a.style=='pri'then b=K.button(parent,a.key,{kind='pri',text=a.label,size=sz.label},function()a.run()end)
    elseif a.style=='open'then
        b=painted(parent,a.key,{fill=mix(C.panel,col,.12),stroke=col,thick=2},function()a.run()end)
    elseif a.style=='plain'then b=K.button(parent,a.key,{kind='plain',text=a.label,size=sz.label},function()a.run()end)
    else
        b=painted(parent,a.key,sz.pt and {fill=C.raised,stroke=C.line}or {fill=C.raised,stroke=col,thick=2,strokeAlpha=.3},function()a.run()end)
    end
    b:place(x,y,w,sz.h)
    if a.style=='open'then inline(b.face,w,sz.h,{{text=a.label,size=sz.label,color=C.ink}})
    elseif a.style=='price'then
        local mark=a.coin and {icon='coinGold',size=sz.rs+2,white=true}or {robux=sz.rs,color=C.ink}
        inline(b.face,w,sz.h,{mark,{num=a.amount or '',size=sz.num,color=C.ink,gap=sz.pt and 5 or 8}},sz.pt and 5 or 8)
    end
    if not a.enabled then if a.style=='pri'or a.style=='plain'then b:setEnabled(false)else dim(b)end end
    return b
end

local function crateSheet(ctx,kind)
    local billing,shop,hub=ctx.billing,ctx.shop,ctx.hub;local col=COLOR[kind]
    step('oddsView',{item=kind})
    local rows=kind=='basic'and #Launch.rarityOrder or 1
    local rules={
        {glyph='duplicate',text=string.format('중복 → 코인 %d',Cards.refund)},
        {icon='ticket',text=string.format('뽑기권으로 열면 → 조각 +%d',FRAG_GAIN)},
        {icon='hexFill',text=string.format('조각 %d → 뽑기권 1',FRAG_PER)},
    }
    local w=360;local pad=18
    local main=action(ctx,kind)
    local product=billing.products and billing.products[kind]
    local canBuy=not billing.testingAvailable and product~=nil and product.available==true and billing.paidRandomAllowed==true
    local extra={}
    if not billing.testingAvailable and main.key~='Buy'then
        table.insert(extra,{key='BuyTicket',style='price',label='뽑기권 1장',amount=Kit.robuxText(shop:billingPrice(kind,product,'product'),Launch.tickets[kind].suggestedRobux),enabled=canBuy and not shop.busy,
            run=function()step('ticketChip',{item=kind});shop:purchaseBilling(kind,'shopBox')end})
    end
    if kind=='basic'and not billing.testingAvailable and main.key~='MedalOpen'then
        local medals=hub.account.progress and hub.account.progress.medals or 0
        table.insert(extra,{key='MedalOpen',style='price',coin=true,label='코인으로 열기',amount=Theme.commas(Launch.medalDrawCost),enabled=not shop.busy and medals>=Launch.medalDrawCost,
            run=function()step('crateOpen',{item='basic',value=Launch.medalDrawCost});shop:drawSupply('basic','medals')end})
    end
    local h=pad+30+12+rows*26+10+24+12+#rules*28+10+#extra*52+40+pad
    Pop.sheet(hub.page,'CrateSheet',w,h,function(p,close,pw,ph)
        local t=K.text(p,'Title',Cards.titles[kind],20,C.ink,800);K.box(t,pad,pad,pw-pad*2-44,30)
        local x=K.button(p,'Close',{kind='ghost',icon='x',iconSize=18},function()close()end);x:place(pw-pad-26+4,pad+2,26,26)
        local y=pad+30+12
        for i=1,rows do
            local r=kind=='basic'and Launch.rarityOrder[i]or Launch.tickets[kind].rarity
            local c=K.rarity[r]
            local d=K.make('Frame',p,{Name='Dot'..i,BackgroundColor3=c,BorderSizePixel=0});K.round(d,'pill');K.box(d,pad,y+8,10,10)
            local n=K.text(p,'Grade'..i,Launch.rarityNames[r],14,C.ink,700);K.box(n,pad+20,y,160,26)
            local v=K.num(p,'Rate'..i,kind=='basic'and(function()local wv=Launch.weights[r]/10000;return wv%1==0 and string.format('%d%%',wv)or string.format('%g%%',wv)end)()or '100%',14,c,Enum.TextXAlignment.Right)
            K.box(v,pw-pad-120,y,120,26);y+=26
        end
        y+=10
        local pl=K.text(p,'PiecesLabel','조각',13,C.muted,700);K.box(pl,pad,y,40,24)
        pieceRow(p,kind,shards(billing,kind),pad+46,y+10,pw-pad*2-46,12);y+=24+12
        for i,r in ipairs(rules)do
            local iy=y+6
            if r.glyph then
                local g=K.make('Frame',p,{Name='RuleIcon'..i,BackgroundTransparency=1,BorderSizePixel=0});K.box(g,pad,iy,16,16)
                local back=K.make('Frame',g,{Name='Back',BackgroundTransparency=1,BorderSizePixel=0});K.round(back,3);K.stroke(back,C.muted,1,0,true);K.box(back,0,0,11,11)
                local front=K.make('Frame',g,{Name='Front',BackgroundColor3=C.muted,BorderSizePixel=0});K.round(front,3);K.box(front,5,5,11,11)
            else
                local ic=K.icon(p,r.icon,16,col,'RuleIcon'..i);K.box(ic,pad,iy,16,16)
            end
            local rt=K.text(p,'Rule'..i,r.text,13,C.ink,700);K.box(rt,pad+26,y,math.min(K.width(r.text,13,rt)+2,pw-pad*2-26),28)
            y+=28
        end
        y+=10
        for _,a in ipairs(extra)do
            local b=painted(p,a.key,{fill=C.raised,stroke=col,thick=1,strokeAlpha=.4},function()close();a.run()end)
            b:place(pad,y,pw-pad*2,44)
            local lt=K.text(b.face,'Label',a.label,15,C.ink,800);K.box(lt,14,0,pw-pad*2-140,44)
            local mark=a.coin and {icon='coinGold',size=16,white=true}or {robux=16,color=C.ink}
            local objs,tw=inline(b.face,pw-pad*2,44,{mark,{num=a.amount or '',size=18,color=C.ink}},6,'left',0)
            local shift=pw-pad*2-14-tw;for _,e in ipairs(objs)do e.o.Position+=UDim2.fromOffset(shift,0)end
            if not a.enabled then dim(b)end
            y+=52
        end
        local rw=pw-pad*2
        local more=painted(p,'ItemOdds',{fill=C.raised,stroke=C.line},function()close();step('oddsItems',{item=kind});hub.supplyOdds=kind;hub:openPage('supply')end)
        more:place(pad,y,rw,40)
        local ml=K.text(more.face,'Label','아이템별 확률 보기',14,C.ink,800);ml.ZIndex=more.face.ZIndex+2;K.box(ml,14,0,math.min(K.width(ml.Text,14,ml)+2,rw-14-36),40)
        local chev=K.icon(more.face,'chev',16,C.muted,'Chev');chev.ZIndex=more.face.ZIndex+2;K.box(chev,rw-14-16,12,16,16)
    end)
end

local function crateTall(ctx,kind,x,y,w,h,s)
    local col=COLOR[kind];local billing=ctx.billing;local count=held(billing,kind)
    local card=K.make('Frame',ctx.list,{Name='Crate_'..kind,BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0});K.round(card,10);K.box(card,x,y,w,h)
    K.stroke(card,col,1,.65)
    local s3=3/h
    K.make('UIGradient',card,{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,col),ColorSequenceKeypoint.new(s3-.001,col),ColorSequenceKeypoint.new(s3,mix(C.panel,col,.18)),ColorSequenceKeypoint.new(.55,C.panel),ColorSequenceKeypoint.new(1,C.panel)})})
    do local p=billing.products and billing.products[kind];offer(card,kind,p~=nil and p.available==true and billing.paidRandomAllowed==true,'shopBox',billing)end
    local info=infoButton(card,s.info,C.muted,function()crateSheet(ctx,kind)end);info:place(w-s.infoR-s.info,s.top,s.info,s.info)
    if count>0 then local chip=ticketChip(card,count,col,s.chipH,s.chipFs,s.chipIs);chip.Position=UDim2.fromOffset(s.chipX,s.top)end
    local by=h-s.pad-s.btn
    local nameY=math.min(s.nameY,by-s.gapBtn-s.group)
    local artH=math.max(40,math.min(s.artH,nameY-s.artGap-s.artTop));local artW=math.min(s.artW,math.floor(artH*s.artW/s.artH+.5),w-12)
    artH=math.floor(artW*s.artH/s.artW+.5)
    local ax=math.floor((w-artW)/2)
    local glow=Art.glow(card,'Glow',col,.45);K.box(glow,ax,s.artTop+math.floor(artH*(16/103)),artW,math.floor(artH*88/103))
    local view=require(script.Parent.CollectionPreview).create(card,nil,{crate=kind,name='CrateView',direction=Vector3.new(-.42,.5,-1).Unit,fill=CRATE_FILL});K.box(view,ax,s.artTop,artW,artH)
    local n=K.text(card,'Name',Cards.titles[kind],s.nameFs,C.ink,800,Enum.TextXAlignment.Center);K.box(n,4,nameY,w-8,s.nameFs+4)
    local o=K.text(card,'Odds',oddsLine(kind),s.oddsFs,C.muted,600,Enum.TextXAlignment.Center);K.box(o,4,nameY+s.oddsDy,w-8,s.oddsFs+2)
    pieceRow(card,kind,shards(billing,kind),s.edge,nameY+s.barDy,w-s.edge*2,s.pieceFs)
    actionButton(card,ctx,kind,action(ctx,kind),s.edge,by,w-s.edge*2,{h=s.btn,label=s.btnFs,rs=s.rs,num=s.numFs})
    return card
end
local function crateShort(ctx,kind,x,y,w,h)
    local col=COLOR[kind];local billing=ctx.billing;local count=held(billing,kind)
    local card=K.make('Frame',ctx.list,{Name='Crate_'..kind,BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0});K.round(card,8);K.box(card,x,y,w,h)
    K.stroke(card,col,1,.6)
    K.make('UIGradient',card,{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,mix(C.panel,col,.10)),ColorSequenceKeypoint.new(.7,C.panel),ColorSequenceKeypoint.new(1,C.panel)})})
    do local p=billing.products and billing.products[kind];offer(card,kind,p~=nil and p.available==true and billing.paidRandomAllowed==true,'shopBox',billing)end
    local n=K.text(card,'Name',Cards.titles[kind],13,col,800);K.box(n,11,8,w-80,17)
    local info=infoButton(card,15,C.muted,function()crateSheet(ctx,kind)end);info:place(w-11-15,9,15,15)
    if count>0 then local chip,cw=ticketChip(card,count,col,18,11,12);chip.Position=UDim2.fromOffset(w-11-15-6-cw,7)end
    local by=h-11-40
    local artH=math.max(40,math.min(110,by-2-23));local artW=math.floor(artH*84/72+.5);artW=math.min(artW,w-24);artH=math.floor(artW*72/84+.5)
    local ax=math.floor((w-artW)/2)
    local glow=Art.glow(card,'Glow',col,.45);K.box(glow,ax,23+math.floor(artH*16/103),artW,math.floor(artH*88/103))
    local view=require(script.Parent.CollectionPreview).create(card,nil,{crate=kind,name='CrateView',direction=Vector3.new(-.42,.5,-1).Unit,fill=CRATE_FILL});K.box(view,ax,23,artW,artH)
    actionButton(card,ctx,kind,action(ctx,kind),11,by,w-22,{h=40,label=15,rs=14,num=15,pt=true})
    return card
end

local MEMBER={
    club={sku='club',color=C.vip,icon='vip',name=Launch.club.name,period='30일',ptype='subscription',fallback=Launch.club.suggestedRobux,
        big={{'custom','공개 커스텀 방'},{'notice','채팅, 음성'}},small='매일 뽑기권, XP 2배, 모션',short='공개 커스텀 방, 채팅'},
    permanent={sku='permanent',color=C.prime,icon='marshal',name=Launch.permanent.name,period='영구',ptype='pass',fallback=Launch.permanent.suggestedRobux,
        big={{'clan','클랜 만들기, 가입'},{'ticket',string.format('뽑기권 %d장',#welcomeColors()),tickets=true}},small='XP 2배, 프라임 마크',short=string.format('클랜, 뽑기권 %d장',#welcomeColors())},
}
local function memberLook(card,o)
    local prime=o.sku=='permanent'
    K.make('UIGradient',card,{Rotation=70,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,mix(C.panel,o.color,prime and .10 or .14)),ColorSequenceKeypoint.new(.6,C.panel),ColorSequenceKeypoint.new(1,C.panel)})})
    K.stroke(card,o.color,1,prime and .6 or .55)
end
local function badge(parent,o,size,iconSize,alpha)
    local f=K.make('Frame',parent,{Name='Badge',BackgroundColor3=o.color,BackgroundTransparency=1-alpha,BorderSizePixel=0});K.round(f,10)
    local i=K.icon(f,o.icon,iconSize,o.color,'Icon');K.box(i,math.floor((size-iconSize)/2),math.floor((size-iconSize)/2),iconSize,iconSize)
    f.Size=UDim2.fromOffset(size,size);return f
end
local function memberState(ctx,sku)
    local billing,shop=ctx.billing,ctx.shop;local o=MEMBER[sku]
    local owned=billing.benefits and billing.benefits[sku]
    local live=billing[sku]and billing[sku].available==true and shop:billingPrice(sku,billing[sku],o.ptype)~=nil
    local amount=Kit.robuxText(shop:billingPrice(sku,billing[sku],o.ptype),o.fallback)
    local days=sku=='club'and billing.club and billing.club.daysLeft
    return owned,live,amount,days
end
local function buyMember(ctx,sku)step('offer_'..sku,{sku=sku,result='selected'});ctx.shop:purchaseBilling(sku,'shopMember')end
local function openMember(ctx,sku)step('offer_'..sku,{sku=sku,result='active'});ctx.hub:openPage('benefits')end
local function memberSheet(ctx,sku)
    local o=MEMBER[sku];local list=Cards.perkList[sku];local shop=ctx.shop
    step('perksView',{sku=sku})
    local owned=memberState(ctx,sku)
    local pad=18;local rh=50;local w=380
    local h=pad+44+12+#list*rh+8+20+12+44+pad
    Pop.sheet(ctx.hub.page,'MemberSheet',w,h,function(p,close,pw)
        local b=badge(p,o,44,25,.18);b.Position=UDim2.fromOffset(pad,pad)
        local t=K.text(p,'Title',o.name,19,C.ink,800);K.box(t,pad+56,pad,pw-pad*2-56-36,24)
        local pr=K.text(p,'Period',o.period,13,o.color,800);K.box(pr,pad+56,pad+25,120,17)
        local x=K.button(p,'Close',{kind='ghost',icon='x',iconSize=18},function()close()end);x:place(pw-pad-26+4,pad,26,26)
        local y=pad+44+12
        for i,perk in ipairs(list)do
            local ic=K.icon(p,perk[1],20,o.color,'PerkIcon'..i);K.box(ic,pad,y+(rh-20)/2,20,20)
            local a=K.text(p,'Perk'..i,perk[2],15,C.ink,800);K.box(a,pad+32,y+5,pw-pad*2-32,20)
            local s=K.text(p,'PerkSub'..i,perk[3],12,C.muted,600);K.box(s,pad+32,y+26,pw-pad*2-32,16)
            y+=rh
        end
        y+=8
        local note=K.text(p,'Note',owned and (sku=='club'and '구독 기간 동안 적용 중'or '영구 적용 중')or Cards.perkNote[sku],12,C.muted,600,Enum.TextXAlignment.Center);K.box(note,pad,y,pw-pad*2,20);y+=32
        local r=K.button(p,'Restore',{kind='ghost',icon='restore',iconSize=16,text='구매 복원',size=14,weight=800},function()
            close();Step.step('shop','restore',{});shop:run(function()shop:request('restore')end)end)
        r:place(pad,y,pw-pad*2,44);if shop.busy then r:setEnabled(false)end
    end)
end
local function memberButton(ctx,parent,sku,x,y,w,h,fmt)
    local o=MEMBER[sku];local owned,live,amount,days=memberState(ctx,sku)
    local b=painted(parent,owned and 'MemberState'or 'Buy',{fill=mix(C.panel,o.color,.10),stroke=o.color,thick=2},function()
        if owned then openMember(ctx,sku)else buyMember(ctx,sku)end end)
    b:place(x,y,w,h)
    if owned then
        local label=days and string.format('이용 중 %d일 남음',days)or(sku=='club'and '이용 중'or '보유 중')
        inline(b.face,w,h,{{icon='check',size=fmt=='pt'and 13 or 16,color=o.color},{text=label,size=fmt=='pt'and 13 or 16,color=o.color}},6)
    elseif fmt=='pt'then
        local top=K.make('Frame',b.face,{Name='Price',BackgroundTransparency=1,Size=UDim2.fromOffset(w,22),Position=UDim2.fromOffset(0,5)})
        inline(top,w,22,{{robux=13,color=C.ink},{num=amount or '',size=15,color=C.ink}},4)
        local per=K.text(b.face,'Period',o.period,11,C.muted,800,Enum.TextXAlignment.Center);K.box(per,0,26,w,13)
    else
        inline(b.face,w,h,{{robux=fmt=='pc'and 16 or 14,color=C.ink},{num=amount or '',size=fmt=='pc'and 18 or 16,color=C.ink}},8)
    end
    if not owned and not(live and not ctx.shop.busy)then dim(b)end
    return b
end
local function memberCard(ctx,sku,x,y,w,h,g)
    local o=MEMBER[sku];local billing=ctx.billing
    local card=K.make('TextButton',ctx.list,{Name=sku=='club'and 'Club'or 'Permanent',Text='',AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0});K.round(card,10);K.box(card,x,y,w,h)
    memberLook(card,o)
    card.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');memberSheet(ctx,sku)end)
    offer(card,sku,billing[sku]and billing[sku].available,'shopMember',billing)
    local p=g.pad
    local b=badge(card,o,g.badge,g.badgeIcon,.18);b.Position=UDim2.fromOffset(p,p)
    local tx=p+g.badge+12
    local nm=K.text(card,'Name',o.name,g.nameFs,C.ink,800);K.box(nm,tx,p+2,w-tx-p-30,g.nameFs+4)
    local per=K.text(card,'Period',o.period,g.perFs,o.color,800);K.box(per,tx,p+g.nameFs+8,120,g.perFs+2)
    local info=infoButton(card,g.info,C.muted,function()memberSheet(ctx,sku)end);info:place(w-p-g.info+4,p-2,g.info,g.info)
    local ly=p+g.badge+g.bigTop
    for i,line in ipairs(o.big)do
        local row=K.make('Frame',card,{Name='Big'..i,BackgroundTransparency=1,BorderSizePixel=0});K.box(row,p,ly,w-p*2,g.bigFs+4)
        local parts={{icon=line[1],size=g.bigIcon,color=o.color},{text=line[2],size=g.bigFs,color=C.ink,gap=10}}
        if line.tickets then for k,c in ipairs(welcomeColors())do table.insert(parts,{icon='ticket',size=g.tk,color=c,gap=k==1 and 14 or 3})end end
        local _,total=inline(row,w-p*2,g.bigFs+4,parts,10,'left',0)
        if line.tickets then
            local split=welcomeSplit();local sl=K.text(row,'Split',split,g.smallFs,C.muted,600);sl:SetAttribute('LocalizationSkip',true);sl.ZIndex=row.ZIndex+2
            local sw=K.width(split,g.smallFs,sl)
            if total+10+sw<=w-p*2 then K.box(sl,total+10,0,sw+2,g.bigFs+4)
            else sl.Parent=card;K.box(sl,p+g.bigIcon+10,ly+g.bigFs+4,sw+2,g.smallFs+3);ly+=g.smallFs+5 end
        end
        ly+=g.bigStep
    end
    local sm=K.text(card,'Small',o.small,g.smallFs,C.muted,600);K.box(sm,p,ly+g.smallDy,w-p*2,g.smallFs+3)
    memberButton(ctx,card,sku,p,h-p-g.btn,w-p*2,g.btn,g.fmt)
    return card
end
local function memberRow(ctx,sku,x,y,w)
    local o=MEMBER[sku];local billing=ctx.billing;local h=76
    local card=K.make('TextButton',ctx.list,{Name=sku=='club'and 'Club'or 'Permanent',Text='',AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0});K.round(card,10);K.box(card,x,y,w,h)
    memberLook(card,o)
    card.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');memberSheet(ctx,sku)end)
    offer(card,sku,billing[sku]and billing[sku].available,'shopMember',billing)
    local b=badge(card,o,40,22,.16);b.Position=UDim2.fromOffset(13,18)
    local prime=sku=='permanent';local dy=prime and -7 or 0
    local nm=K.text(card,'Name',o.name,12,o.color,800);K.box(nm,63,20+dy,w-63-110,15)
    local row=K.make('Frame',card,{Name='Big',BackgroundTransparency=1,BorderSizePixel=0});K.box(row,63,37+dy,w-63-110,20)
    local parts={{text=o.short,size=15,color=C.ink}}
    if prime then for k,c in ipairs(welcomeColors())do table.insert(parts,{icon='ticket',size=13,color=c,gap=k==1 and 6 or 2})end end
    inline(row,w-63-110,20,parts,6,'left',0)
    if prime then local sl=K.text(card,'Split',welcomeSplit(),11,C.muted,600);sl:SetAttribute('LocalizationSkip',true);K.box(sl,63,57+dy,w-63-110,14)end
    memberButton(ctx,card,sku,w-13-84,16,84,44,'pt')
    return card
end

local function note(ctx)
    local billing=ctx.billing
    if not billing.paidRandomAllowed and not billing.testingAvailable then
        Step.once('paidRestricted','shop','paidRestricted',{reason=billing.policyKnown and 'policy_restricted'or 'not_loaded'})
        return billing.policyKnown and '유료 뽑기 불가  코인 뽑기 가능'or '확인 실패'
    elseif billing.salesOpen==false and not billing.testingAvailable then
        Step.once('salesClosed','shop','salesClosed',{reason='sales_disabled'})
        return 'Robux 판매 일시 중지'
    end
    return nil
end
local function noteLabel(ctx,text,x,y,w,size,align)
    local l=K.text(ctx.root,'ShopNote',text,size,C.muted,700,align);K.box(l,x,y,w,size+6);return l
end

local function appearList(items,first)
    if not first then return end
    for i,o in ipairs(items)do if i<=6 then K.appear(o,{dy=8,t=.14,delay=(i-1)*.03})end end
end
function M.draw(hub,body,w)
    local a=hub.account or {};local billing=a.billing;local shop=hub.callbacks.shop()
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    body.CanvasSize=UDim2.fromOffset(0,0)
    local first=Pop.watch(hub,hub.page)
    local root,W,H,fmt=K.screenRoot(hub,body,'Shop20')
    if not a.ready or not billing then
        Step.once('shopLoading','shop','loading',{reason='loading'})
        local t=K.text(root,'Loading','보관함을 불러오는 중…',15,C.muted,700,Enum.TextXAlignment.Center);K.box(t,0,math.floor(H/2-20),W,40)
        return
    end
    Step.once('shopBoard','shop','board',{item=hub.shopTab or 'boxes'})
    local ctx={hub=hub,shop=shop,billing=billing,root=root,W=W,H=H,fmt=fmt}
    local list=K.make('Frame',root,{Name='Board',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1)});ctx.list=list
    local items={}
    local text=note(ctx)
    local wide=fmt=='pc'and W>=1100
    if fmt=='pt'then
        local t=K.text(root,'Title','상점',22,C.ink,800);K.box(t,16,68,200,36)
        saleChip(ctx,W-16,73,26,13)
        local cw=(W-32-8)/2;local cy=112
        local bottom=H-58-8;local spare=bottom-(cy+148*2+8+8+76*2+8+(text and 18 or 0))
        local ch=148+math.clamp(math.floor(spare/2),0,60)
        for i,kind in ipairs(KINDS)do
            local x=16+((i-1)%2)*(cw+8);local y=cy+math.floor((i-1)/2)*(ch+8)
            table.insert(items,crateShort(ctx,kind,x,y,cw,ch))
        end
        local my=cy+ch*2+8+8
        table.insert(items,memberRow(ctx,'club',16,my,W-32))
        table.insert(items,memberRow(ctx,'permanent',16,my+84,W-32))
        if text then noteLabel(ctx,text,16,my+84+76+4,W-32,11,Enum.TextXAlignment.Center)end
    elseif wide then
        local ax,ay=40,124;local mw=332;local aw=W-ax-24-mw-40;local room=H-ay-84;local ah=math.clamp(room,400,600);ay+=math.floor(math.max(0,room-ah)/2);local tg=14;local tw=(aw-3*tg)/4
        saleChip(ctx,W-40,ay-44,30,14)
        local s={info=18,infoR=11,edge=17,top=13,pad=17,btn=56,btnFs=19,rs=16,numFs=18,chipX=13,chipH=24,chipFs=14,chipIs=16,
            nameY=291,nameFs=21,oddsDy=31,oddsFs=13,barDy=69,pieceFs=12,group=76,gapBtn=24,artTop=71,artW=200,artH=172,artGap=48}
        for i,kind in ipairs(KINDS)do table.insert(items,crateTall(ctx,kind,ax+(i-1)*(tw+tg),ay,tw,ah,s))end
        local mx=ax+aw+24;local mh=(ah-14)/2
        local g={fmt='pc',pad=19,badge=44,badgeIcon=25,nameFs=19,perFs=13,info=18,bigTop=16,bigFs=16,bigIcon=18,bigStep=27,tk=15,smallFs=13,smallDy=2,btn=52}
        table.insert(items,memberCard(ctx,'club',mx,ay,mw,mh,g))
        table.insert(items,memberCard(ctx,'permanent',mx,ay+mh+14,mw,mh,g))
        if text then noteLabel(ctx,text,ax,ay+ah+12,aw,13,Enum.TextXAlignment.Left)end
    else
        local top=fmt=='pc'and 80 or 54
        local tab=hub.shopTab=='members'and 'members'or 'boxes'
        local prev=hub.shop20Tab;hub.shop20Tab=tab
        local seg=K.segment(root,'ShopTab',{{'boxes','보급 상자'},{'members','멤버십'}},prev or tab,function(id)
            hub.shopTab=id;Step.step('shop','tab',{item=id});hub:drawPage()end,{size=13})
        seg:place(16,top,220,34);if prev and prev~=tab then seg:select(tab,true)end
        saleChip(ctx,W-16,top+6,22,12)
        if text then noteLabel(ctx,text,248,top,W-16-248-110,11,Enum.TextXAlignment.Left).Size=UDim2.fromOffset(W-16-248-110,34)end
        local ay=top+44;local aw=W-32;local ah=H-ay-12
        if tab=='boxes'then
            local tg=8;local tw=(aw-3*tg)/4
            local s={info=14,infoR=7,edge=9,top=9,pad=9,btn=38,btnFs=15,rs=12,numFs=14,chipX=7,chipH=20,chipFs=12,chipIs=13,
                nameY=127,nameFs=15,oddsDy=21,oddsFs=11,barDy=47,pieceFs=11,group=51,gapBtn=8,artTop=31,artW=104,artH=89,artGap=7}
            for i,kind in ipairs(KINDS)do table.insert(items,crateTall(ctx,kind,16+(i-1)*(tw+tg),ay,tw,ah,s))end
        else
            local mw=(aw-10)/2
            local g={fmt='ph',pad=13,badge=40,badgeIcon=22,nameFs=16,perFs=12,info=15,bigTop=12,bigFs=14,bigIcon=16,bigStep=24,tk=13,smallFs=12,smallDy=2,btn=44}
            table.insert(items,memberCard(ctx,'club',16,ay,mw,ah,g))
            table.insert(items,memberCard(ctx,'permanent',16+mw+10,ay,mw,ah,g))
        end
        if prev and prev~=tab then K.appear(list,{dx=tab=='members'and 24 or -24,t=.16});first=false end
    end
    appearList(items,first)
    local dev=script.Parent:FindFirstChild('DevPanel')
    if dev then local y0=root.Position.Y.Offset+H+8;local y=require(dev).draw(hub,body,w,y0,shop);body.CanvasSize=UDim2.fromOffset(0,y+8)end
end
return M
