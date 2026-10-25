local UI=require(script.Parent.ToyUI)
local Preview=require(script.Parent.CollectionPreview)
local Reveal=require(script.Parent.SupplyReveal)
local ShardGauge=require(script.Parent.ShardGauge)
local Catalog=require(script.Parent.Parent.Core.SupplyCatalog)
local Definitions=require(script.Parent.Parent.Core.CollectionDefinitions)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local M={}
local function text(p,n,t,x,y,w,h,size,color)local l=UI.label(p,n,t,size,color);UI.box(l,x,y,w,h);return l end
function M.collection(hub,body,w,y,shop,slot)
    local billing=hub.account.billing;local family=slot and Definitions.family(slot)
    if not family then
        local selected=hub.collectionFamily or 'parachute'
        local cols=w>=600 and 4 or 3;local cw=(w-(cols-1)*6)/cols
        for i,f in ipairs(Definitions.families)do local id=f.id;local b=UI.button(body,'Family_'..id,f.name,function()hub.collectionFamily=id;hub:drawPage()end,id==selected);UI.box(b,(i-1)%cols*(cw+6),y+math.floor((i-1)/cols)*50,cw,44);b.TextSize=w<480 and 11 or 13 end
        y+=math.ceil(#Definitions.families/cols)*50+6;family=Definitions.family(selected)or Definitions.families[1]
    end
    local items={};for _,item in ipairs(Catalog.items)do if item.category==family.id then table.insert(items,item)end end
    local cols=w>=600 and 3 or 2;local gap=12;local cw=(w-gap*(cols-1))/cols;local h=242
    for i,item in ipairs(items)do
        local owned=billing.owned[item.id]==true;local equipped=true
        for s,id in pairs(item.loadout)do if hub.account.cosmetics[s]~=id then equipped=false end end
        local f=UI.panel(body,'Collection_'..item.style);UI.box(f,(i-1)%cols*(cw+gap),y+math.floor((i-1)/cols)*(h+gap),cw,h)
        f:SetAttribute('CollectionItem',item.id);f:SetAttribute('CollectionOwned',owned)
        if owned and slot then f:SetAttribute('CollectionKey','skin:'..slot..':'..item.style)end
        local color=Reveal.colors[item.rarity];f:FindFirstChildOfClass('UIStroke').Color=color:Lerp(UI.colors.line,.32)
        local view=Preview.create(f,item);UI.box(view,6,10,cw-12,130)
        text(f,'Rarity',Launch.rarityNames[item.rarity],12,144,cw-24,20,12,color)
        text(f,'Name',item.name,12,166,cw-24,24,15)
        local b=UI.button(f,'Equip',owned and (equipped and '장착 중'or '장착')or '미보유',function()shop:run(function()shop:request('equipSupply',item.id)end)end,owned and not equipped);UI.box(b,10,194,cw-20,38);UI.enabled(b,owned and not equipped and not shop.busy)
        local serial=billing.serials and billing.serials[item.id];if serial then f:SetAttribute('Serial',serial)end
    end
    return y+math.ceil(#items/cols)*(h+gap)
end
function M.draw(hub,body,w,y)
    local shop=hub.callbacks.shop();local billing=hub.account.billing
    if hub.collectionBrowse then
        local back=UI.button(body,'BackToDraw','‹ 보급 상자',function()hub.collectionBrowse=nil;hub:drawPage()end);UI.box(back,0,y,w,44);y+=56
        y=M.collection(hub,body,w,y,shop);body.CanvasSize=UDim2.fromOffset(0,y+8);return
    end
    local kind=hub.supplyKind or 'basic';local product=billing.products[kind]
    for i,id in ipairs({'basic','epic','legendary','mythic'})do
        local b=UI.button(body,'TicketSelect_'..id,Launch.tickets[id].name,function()require(script.Parent.TelemetryStep).step('gacha','ticketTab',{sku=id});hub.supplyKind=id;hub:drawPage()end,id==kind);UI.box(b,(i-1)*(w+8)/4,y,(w-24)/4,44);b.TextSize=w<480 and 11 or 14
        if id==kind then b.BackgroundColor3=Reveal.colors[id]or UI.colors.accent;b.TextColor3=UI.colors.bg end
    end;y+=56
    local count=billing.tickets[kind]or 0;local test=billing.testingAvailable and (billing.testTickets[kind]or 0)or 0
    local title=shop.busy and '확인 중…'or billing.testingAvailable and (test>0 and string.format('테스트 뽑기 %d장',test)or '테스트 보급 받기')or '상자 열기 (1장)'
    local open=UI.button(body,'DrawTicket',title,function()
        if billing.testingAvailable then
            if test>0 then shop:drawSupply(kind,'studio')else shop:run(function()shop:request('supplyTestGrant')end)end
        else shop:drawSupply(kind,'ticket')end
    end,true);UI.box(open,0,y,w,54)
    if not billing.testingAvailable and not(count>0 and billing.paidRandomAllowed)then require(script.Parent.TelemetryStep).change('drawBlocked','gacha','drawBlocked',{sku=kind,item=kind,count=count,result='unavailable',reason=billing.paidRandomAllowed and 'insufficient_cost'or 'policy_restricted'})end
    open.BackgroundColor3=Reveal.colors[kind]or UI.colors.accent;UI.enabled(open,not shop.busy and (billing.testingAvailable or count>0 and billing.paidRandomAllowed));y+=64
    text(body,'TicketBalance',string.format('%d장 보유',count),2,y,72,28,14,UI.colors.muted)
    local shards=ShardGauge.create(body,require(script.Parent.SupplyCrateArt).colors[kind]or UI.colors.accent,14);shards.root.Name='ShardGauge';shards.root.AnchorPoint=Vector2.new(0,.5);shards.root.Position=UDim2.fromOffset(78,y+14)
    ShardGauge.set(shards,billing.fragments[kind]or 0,false)
    local browse=UI.button(body,'Collection','컬렉션 '..#Catalog.items,function()require(script.Parent.TelemetryStep).step('cosmetics','collection',{item='all',value=#Catalog.items});hub.collectionBrowse=true;hub:drawPage()end);UI.box(browse,w*.6,y,w*.4,32);browse.TextSize=12;browse.BackgroundTransparency=1;y+=40
    local selectedTier=kind=='basic'and 'mythic'or kind
    local feature=Catalog.find('supply:'..({epic='pulse',legendary='solaris',mythic='parallax'})[selectedTier]..'_parachute')
    local hero=UI.panel(body,'SupplyShowcase');local short=body.AbsoluteSize.Y/require(script.Parent.Theme).scale<350
    local heroH=short and 132 or w<480 and 190 or 222;UI.box(hero,0,y,w,heroH)
    local color=Reveal.colors[selectedTier];hero:FindFirstChildOfClass('UIStroke').Color=color:Lerp(UI.colors.line,.35)
    UI.make('UIGradient',hero,{Color=ColorSequence.new(UI.colors.panel,color:Lerp(UI.colors.bg,.9)),Rotation=25})
    local view=Preview.create(hero,feature);UI.box(view,w*.37,0,w*.63,heroH)
    text(hero,'Series','상시 컬렉션',16,14,w*.44,24,13,UI.colors.muted)
    text(hero,'HeroName',feature.name,16,44,w*.43,54,w<480 and 20 or 26,color)
    text(hero,'PreviewLabel','미리보기',16,heroH-35,w*.36,22,11,UI.colors.muted);y+=heroH+12
    if kind=='basic'and require(script.Parent.FreeDraw).ready(billing)then
        local b=UI.button(body,'FreeDraw','오늘 무료 기본 뽑기',function()shop:drawSupply('basic','free')end,true);UI.box(b,0,y,w,44);UI.enabled(b,not shop.busy)
        b.BackgroundColor3=UI.colors.gold;b.TextColor3=UI.colors.bg;require(script.Parent.FreeDraw).dot(b,true);y+=54
    end
    if kind=='basic'then
        local b=UI.button(body,'MedalDraw',string.format('%d 코인으로 기본 뽑기',billing.medalDrawCost),function()shop:drawSupply('basic','medals')end);UI.box(b,0,y,w,44);UI.enabled(b,(hub.account.progress.medals or 0)>=billing.medalDrawCost and not shop.busy);y+=54
    end
    local price=shop:billingPrice(kind,product,'product')
    local buy=UI.button(body,'Purchase',price and string.format('%s에 뽑기권 구매',price)or '판매 준비 중',function()shop:purchaseBilling(kind,'supply')end);pcall(function()require(script.Parent.TelemetryClient).offer(buy,kind,price~=nil and product.available==true,'supply',billing)end);UI.box(buy,0,y,(w-10)*.6,44);UI.enabled(buy,price~=nil and product.available and not shop.busy)
    local odds=UI.button(body,'Odds','개별 확률 보기',function()hub.supplyOdds=kind;hub:drawPage()end);UI.box(odds,(w-10)*.6+10,y,(w-10)*.4,44);odds.TextSize=12;y+=54
    if billing.testingAvailable then
        local frame=UI.panel(body,'StudioSupply');UI.box(frame,0,y,w,98)
        text(frame,'Label','Studio 전용, 실제 결제 없음',12,6,w-24,24,12,UI.colors.muted)
        local grant=UI.button(frame,'GrantTests','테스트 보급 받기',function()shop:run(function()shop:request('supplyTestGrant')end)end);UI.box(grant,10,40,(w-30)/2,44);UI.enabled(grant,not shop.busy)
        local draw=UI.button(frame,'TestDraw',string.format('테스트 뽑기 %d장',test),function()shop:drawSupply(kind,'studio')end,true);UI.box(draw,20+(w-30)/2,40,(w-30)/2,44);UI.enabled(draw,test>0 and not shop.busy);draw.TextSize=13;y+=110
    end
    local last=shop.lastSupply or billing.history[1]
    if last then local b=UI.button(body,'LastResult',last.name..'  ›',function()Reveal.open(shop,last,function()shop:drawSupply(kind,billing.testingAvailable and 'studio'or 'ticket')end)end);UI.box(b,0,y,w,44);b.TextSize=14;y+=54 end
    if not billing.paidRandomAllowed then text(body,'PaidRestriction',billing.policyKnown and '유료 뽑기 불가'or '확인 실패',2,y,w-4,42,12,UI.colors.muted);y+=50 end
    body.CanvasSize=UDim2.fromOffset(0,y+8)
end
return M
