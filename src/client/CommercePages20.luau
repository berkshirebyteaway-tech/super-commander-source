local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local Step=require(script.Parent.TelemetryStep)
local C=K.colors
local M={}
local TITLES={basic='보급 상자 확률',epic='에픽 상자 확률',legendary='전설 상자 확률',mythic='신화 상자 확률'}
local function step(name,data)local ok,T=pcall(require,script.Parent.TelemetryClient);if ok and T.step then pcall(T.step,'shop',name,data)end end
local function rate(v)return string.format(v>=10 and '%.1f%%'or v>=1 and '%.2f%%'or v>=.1 and '%.3f%%'or '%.4f%%',v)end
local function pct(v)local r=math.floor(v+.5);if math.abs(v-r)<.005 then return string.format('%d%%',r)end;return rate(v)end
local function thumb(parent,id)
    local item=require(script.Parent.Parent.Core.SupplyCatalog).find(id);if not item then return nil end
    if item.category=='commanderStandard'then return require(script.Parent.WearablePreview).create(parent,'commanderStandard',item.style,{flagOnly=true})end
    if item.category=='territory'and require(script.Parent.Parent.Core.CosmeticCatalog).get(item.style).flat then return require(script.Parent.SkinMapScene).patch(parent,item)end
    return require(script.Parent.CollectionPreview).create(parent,item,{role=item.category=='buildings'and 'City'or nil})
end
local function wrapped(parent,name,text,size,color,x,y,w)
    local l=K.text(parent,name,text,size,color,600);l.TextWrapped=true;l.TextTruncate=Enum.TextTruncate.None;l.TextYAlignment=Enum.TextYAlignment.Top
    local L=require(script.Parent.Localization)
    local TS=game:GetService('TextService');local b=Vector2.new(w,10000)
    local h=math.max(TS:GetTextSize(text,size,Enum.Font.BuilderSansBold,b).Y,TS:GetTextSize(L.text(text,parent)or text,size,Enum.Font.BuilderSansBold,b).Y)+4
    K.box(l,x,y,w,h);return l,h
end
local function frame(hub,body,title)
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    body.CanvasSize=UDim2.fromOffset(0,0)
    local root,W,H,fmt=K.screenRoot(hub,body,'Page20')
    local card=hub.pageCard;local top=card.Position.Y.Offset;local bottom=top+card.Size.Y.Offset
    local pt,ph=fmt=='pt',fmt=='ph'
    local cw=pt and W-32 or ph and W-32 or math.min(820,W-48);local x0=math.floor((W-cw)/2)
    local hy=top+(pt and 8 or ph and 8 or 18);local hh=pt and 40 or ph and 32 or 40
    local bs=pt and 40 or ph and 32 or 40
    local back=S.iconButton(root,'BackToShop','back',bs,pt and 18 or ph and 16 or 20,function()
        hub.supplyOdds=nil
        if hub.page=='benefits'and hub.backTo then hub:back()else hub:openPage('shop')end
    end)
    back:place(x0,hy+(hh-bs)/2,bs,bs)
    local t=K.text(root,'Title',title,pt and 20 or ph and 18 or 24,C.ink,800);K.box(t,x0+bs+10,hy,cw-bs-10,hh)
    return {root=root,W=W,H=H,fmt=fmt,pt=pt,ph=ph,pc=fmt=='pc',x=x0,w=cw,y=hy+hh+(pt and 10 or ph and 8 or 16),bottom=bottom-(pt and 8 or ph and 8 or 16),title=t}
end
local first=false
local function stagger(list)if K.reduced or not first then return end;for i,o in ipairs(list)do if i>6 then break end;K.appear(o,{dy=8,t=.14,delay=(i-1)*.03})end end

function M.odds(hub,body,billing)
    local kind=hub.supplyOdds;local product=billing.products[kind]
    local g=frame(hub,body,TITLES[kind]or TITLES.basic)
    local odds=product and product.odds
    Step.step('shop','oddsView',{sku=kind,count=odds and #odds or 0,result=odds and 'shown'or 'unavailable',reason=odds and 'none'or 'not_loaded'})
    if not odds then
        local l=K.text(g.root,'NotReady','스킨 컬렉션 준비 중',15,C.muted,700,Enum.TextXAlignment.Center);K.box(l,g.x,g.y+40,g.w,40);return
    end
    local totals,order,members={},{},{}
    for _,e in ipairs(odds)do local r=e.rarity or 'normal';if not totals[r]then totals[r]=0;members[r]={};table.insert(order,r)end;totals[r]+=e.percent or 0;table.insert(members[r],e)end
    local grades={};for _,r in ipairs(Launch.rarityOrder)do if totals[r]then table.insert(grades,r)end end
    for _,r in ipairs(order)do if not table.find(grades,r)then table.insert(grades,r)end end
    local function each(r)local v;for _,e in ipairs(members[r])do local t=rate(e.percent or 0);if v and v~=t then return nil end;v=t end;return v end
    local y=g.y
    local hfs=g.ph and 14 or 15;local hh=24
    local lx=g.x
    if #grades==1 then
        local r=grades[1];local c=K.rarity[r]or C.muted;local e1=each(r)
        local d=K.make('Frame',g.root,{Name='GradeDot1',BackgroundColor3=c,BorderSizePixel=0});K.round(d,'pill');K.box(d,lx,y+(hh-8)/2,8,8)
        local n=K.text(g.root,'Grade1',Launch.rarityNames[r]or r,hfs,C.ink,800);local nw=K.width(n.Text,hfs,n);K.box(n,lx+14,y,nw+2,hh)
        local v=K.num(g.root,'GradeRate1',pct(totals[r])..',',hfs,c);local vw=K.width(v.Text,hfs,v);K.box(v,lx+14+nw+6,y,vw+2,hh)
        local text=e1 and string.format('%d종 각 %s',#members[r],e1)or string.format('%d종',#members[r])
        local s=K.text(g.root,'GradeEach1',text,hfs,C.ink,700);local sx=lx+14+nw+6+vw+8;K.box(s,sx,y,math.min(K.width(text,hfs,s)+2,g.x+g.w-sx),hh)
        y+=hh
    else
        for i,r in ipairs(grades)do
            local c=K.rarity[r]or C.muted
            local n=K.text(g.root,'Grade'..i,Launch.rarityNames[r]or r,hfs,C.ink,700);local nw=K.width(n.Text,hfs,n)
            local v=K.num(g.root,'GradeRate'..i,pct(totals[r]),hfs,c);local vw=K.width(v.Text,hfs,v)
            if lx>g.x and lx+14+nw+6+vw>g.x+g.w then lx=g.x;y+=hh+4 end
            local d=K.make('Frame',g.root,{Name='GradeDot'..i,BackgroundColor3=c,BorderSizePixel=0});K.round(d,'pill');K.box(d,lx,y+(hh-8)/2,8,8)
            K.box(n,lx+14,y,nw+2,hh);K.box(v,lx+14+nw+6,y,vw+2,hh)
            lx+=14+nw+6+vw+(g.ph and 14 or 18)
        end
        y+=hh
    end
    y+=g.ph and 10 or 14
    local list=S.scroll(g.root,'Odds',g.x,y,g.w,g.bottom-y);local listH=g.bottom-y
    local gap=g.pc and 12 or 8
    local cols,cw
    if g.pc then cols=math.max(3,math.min(6,math.floor((g.w+gap)/(120+gap))));cw=120
    else cols=math.max(3,math.floor((g.w+gap)/(112+gap)));cw=math.floor((g.w-gap*(cols-1))/cols)end
    local ch=math.floor(cw*136/120+.5)
    local ly=0;local rows={};local pending={}
    for _,r in ipairs(grades)do
        local c=K.rarity[r]or C.muted;local e1=each(r)
        if #grades>1 then
            local hd=K.make('Frame',list,{Name='Head_'..r,BackgroundTransparency=1,BorderSizePixel=0});K.box(hd,0,ly,g.w,28)
            local bar=K.make('Frame',hd,{Name='Bar',BackgroundColor3=c,BorderSizePixel=0});K.round(bar,'pill');K.box(bar,2,7,4,14)
            local n=K.text(hd,'Grade',Launch.rarityNames[r]or r,13,c,800);local nw=K.width(n.Text,13,n);K.box(n,14,0,nw+2,28)
            local v=K.num(hd,'Rate',pct(totals[r]),13,c);local vw=K.width(v.Text,13,v);K.box(v,14+nw+6,0,vw+2,28)
            local text=e1 and string.format('%d종 각 %s',#members[r],e1)or string.format('%d종',#members[r])
            local s=K.text(hd,'Each',text,13,C.muted,700,Enum.TextXAlignment.Right);local sw=math.min(K.width(text,13,s)+2,g.w-(14+nw+6+vw+12));K.box(s,g.w-sw,0,sw,28)
            table.insert(rows,hd);ly+=32
        end
        for i,e in ipairs(members[r])do
            local cx=((i-1)%cols)*(cw+gap);local cy=ly+math.floor((i-1)/cols)*(ch+gap)
            local cell=K.make('Frame',list,{Name='Odds_'..e.id,BackgroundColor3=C.panel,BorderSizePixel=0});K.round(cell,8);K.stroke(cell,c,1,.6,true);K.box(cell,cx,cy,cw,ch)
            local nameY=e1 and ch-22 or ch-36
            local n=K.text(cell,'Name',e.name,12,C.ink,700,Enum.TextXAlignment.Center);K.box(n,6,nameY,cw-12,16)
            if not e1 then local v=K.num(cell,'Rate_'..e.id,rate(e.percent or 0),12,c,Enum.TextXAlignment.Center);K.box(v,6,ch-20,cw-12,16)end
            table.insert(pending,{cell=cell,id=e.id,y=cy,w=cw,th=nameY-6})
            table.insert(rows,cell)
        end
        ly+=math.ceil(#members[r]/cols)*(ch+gap)+(g.pc and 10 or 8)-gap
    end
    local function fill()
        if not list.Parent then return end
        local top=list.CanvasPosition.Y-ch;local bottom=list.CanvasPosition.Y+listH+ch
        for i=#pending,1,-1 do local p=pending[i]
            if p.y+ch>=top and p.y<=bottom then table.remove(pending,i)
                local ok,v=pcall(thumb,p.cell,p.id);if ok and v then K.box(v,4,4,p.w-8,p.th)end
            end
        end
    end
    list:GetPropertyChangedSignal('CanvasPosition'):Connect(fill);fill()
    ly+=4
    local _,h1=wrapped(list,'Rounded','확률은 반올림되어 합계가 다를 수 있어요.',12,C.muted,4,ly,g.w-8);ly+=h1+8
    local dup={string.format('중복 → 코인 %d',require(script.Parent.ShopCards).refund),'뽑기권 중복 → 조각 1','조각 5 → 뽑기권 1'}
    local dx,dh=4,24
    for i,t in ipairs(dup)do
        local chip,dw=K.chip(list,'Duplicate'..i,t,'muted',{size=12,height=dh,icon=false})
        if dx>4 and dx+dw>g.w-4 then dx=4;ly+=dh+6 end
        K.box(chip,dx,ly,dw,dh);dx+=dw+6
    end
    ly+=dh
    S.canvas(list,ly)
    stagger(rows)
end

local MEMBER={
    club={color=C.vip,icon='vip',name=Launch.club.name,period='30일',ptype='subscription',fallback=Launch.club.suggestedRobux,owned='구독 중',note='30일마다 자동 갱신, 언제든 해지',active='구독 기간 동안 적용 중'},
    permanent={color=C.prime,icon='marshal',name=Launch.permanent.name,period='영구',ptype='pass',fallback=Launch.permanent.suggestedRobux,owned='보유 중',active='영구 적용 중'},
}
local function memberPanel(ctx,sku,x,y,w,forceH)
    local o=MEMBER[sku];local g=ctx.g;local billing,shop,hub=ctx.billing,ctx.shop,ctx.hub
    local Cards=require(script.Parent.ShopCards);local Kit=require(script.Parent.SkinShopKit)
    local perks=Cards.perkList[sku]or {}
    local owned=billing.benefits and billing.benefits[sku]
    local price=shop:billingPrice(sku,billing[sku],o.ptype)
    local live=billing[sku]and billing[sku].available==true and price~=nil
    local pad=g.ph and 14 or 18;local small=g.ph
    local badge=small and 40 or 44;local prh=small and 30 or 50;local btn=small and 44 or 52
    local extra={}
    if sku=='club'and owned then table.insert(extra,{'ticket',billing.dailyClaimed and '오늘 뽑기권 지급 완료'or '오늘 혜택 확인 중'})end
    if sku=='permanent'and billing.permanent and billing.permanent.welcomePending then
        Step.once('welcomePending','commerce','welcomePending',{sku='permanent',result='pending'});table.insert(extra,{'restore','구매 보상 저장 중'})end
    local terms=owned and o.active or o.note
    local tail=btn+(owned and sku=='club'and btn+8 or 0)+(terms and 26 or 0)+pad
    local h=pad+badge+14+#perks*prh+(#extra>0 and #extra*24+6 or 0)+10+tail
    if forceH==true then return nil,h end
    h=math.max(h,tonumber(forceH)or 0)
    local card=K.make('Frame',ctx.list,{Name=sku=='club'and 'Club'or 'Permanent',BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0});K.round(card,12);K.box(card,x,y,w,h)
    K.make('UIGradient',card,{Rotation=70,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.panel:Lerp(o.color,sku=='permanent'and .10 or .14)),ColorSequenceKeypoint.new(.6,C.panel),ColorSequenceKeypoint.new(1,C.panel)})})
    K.stroke(card,o.color,1,sku=='permanent'and .6 or .55,true)
    pcall(require(script.Parent.TelemetryClient).offer,card,sku,billing[sku]and billing[sku].available,'benefits',billing)
    local b=K.make('Frame',card,{Name='Badge',BackgroundColor3=o.color,BackgroundTransparency=.82,BorderSizePixel=0});K.round(b,10);K.box(b,pad,pad,badge,badge)
    local bi=K.icon(b,o.icon,math.floor(badge*.56),o.color,'Icon');local is=math.floor(badge*.56);K.box(bi,(badge-is)/2,(badge-is)/2,is,is)
    local tx=pad+badge+12
    local nm=K.text(card,'Name',o.name,small and 16 or 19,C.ink,800);K.box(nm,tx,pad+2,w-tx-pad,small and 20 or 24)
    local per=K.text(card,'Period',o.period,small and 12 or 13,o.color,800);K.box(per,tx,pad+(small and 22 or 26),80,16)
    if owned then
        local chip,cwid=K.chip(card,'Owned',o.owned,sku=='club'and 'vip'or 'prime',{size=12,height=22,icon='check'})
        chip.Position=UDim2.fromOffset(w-pad-cwid,pad+math.floor((badge-22)/2));nm.Size=UDim2.fromOffset(math.max(40,w-tx-pad-cwid-8),nm.Size.Y.Offset)
    end
    local py=pad+badge+14
    for i,perk in ipairs(perks)do
        local ic=K.icon(card,perk[1],small and 16 or 20,o.color,'PerkIcon'..i);K.box(ic,pad,py+(small and 7 or 5),small and 16 or 20,small and 16 or 20)
        local a=K.text(card,'Perk'..i,perk[2],small and 13 or 15,C.ink,800);K.box(a,pad+(small and 26 or 32),py+(small and 4 or 3),w-pad*2-32,small and 22 or 22)
        if not small and perk[3]then local sl=K.text(card,'PerkSub'..i,perk[3],12,C.muted,600);K.box(sl,pad+32,py+26,w-pad*2-32,16)end
        py+=prh
    end
    for i,e in ipairs(extra)do
        local ic=K.icon(card,e[1],14,C.muted,'ExtraIcon'..i);K.box(ic,pad,py+5+(i-1)*24,14,14)
        local l=K.text(card,i==1 and(sku=='club'and 'DailyClub'or 'WelcomePending')or 'Extra'..i,e[2],12,C.muted,700);K.box(l,pad+22,py+(i-1)*24,w-pad*2-22,24)
    end
    py=h-tail
    if owned then
        local plate=K.make('Frame',card,{Name='MemberState',BackgroundColor3=o.color,BackgroundTransparency=.9,BorderSizePixel=0});K.round(plate,8);K.stroke(plate,o.color,1,.5,true);K.box(plate,pad,py,w-pad*2,btn)
        local s=K.text(plate,'Text',o.owned,small and 14 or 16,o.color,800,Enum.TextXAlignment.Center);K.box(s,0,0,w-pad*2,btn)
        py+=btn
        if sku=='club'then
            py+=8
            local m=K.button(card,'ManageClub',{kind='plain',text='구독 관리',size=small and 14 or 15,weight=800},function()
                local ok=pcall(function()game:GetService('MarketplaceService'):PromptCancelSubscription(game.Players.LocalPlayer,billing.club.subscriptionId)end)
                Step.step('vip','manageClub',{sku='club',result=ok and 'opened'or 'failed'});if not ok then hub.notify('요청 실패',true)end end)
            m:place(pad,py,w-pad*2,btn);if shop.busy then m:setEnabled(false)end;py+=btn
        end
    else
        local amount=Kit.robuxText(price,o.fallback)
        local buy=K.button(card,'Buy',{kind='none',r=8},function()step('offer_'..sku,{sku=sku,result='selected'});shop:purchaseBilling(sku,'benefits')end)
        local f,st=buy.face,buy.faceStroke
        f.BackgroundColor3=C.panel:Lerp(o.color,.10);f.BackgroundTransparency=0;st.Enabled=true;st.Color=o.color;st.Thickness=2;st.Transparency=0
        buy.baseFill=f.BackgroundColor3;buy.baseAlpha=0;buy.baseStroke=o.color
        buy:place(pad,py,w-pad*2,btn)
        local rs=small and 14 or 16;local ns=small and 16 or 18
        local mark=K.make('ImageLabel',f,{Name='Robux',BackgroundTransparency=1,Image='rbxasset://textures/ui/common/robux.png',ImageColor3=C.ink,ScaleType=Enum.ScaleType.Fit})
        local n=K.num(f,'Price',tostring(amount or ''),ns,C.ink);local nw=K.width(n.Text,ns,n)
        local total=rs+8+nw;local bx=math.floor((w-pad*2-total)/2)
        K.box(mark,bx,(btn-rs)/2,rs,rs);K.box(n,bx+rs+8,0,nw+2,btn)
        if not(live and not shop.busy)then buy:setEnabled(false,true);mark.ImageTransparency=.5;n.TextTransparency=.5;st.Transparency=.55 end
        py+=btn
    end
    if terms then local tl=K.text(card,'Terms',terms,12,C.muted,600,Enum.TextXAlignment.Center);K.box(tl,pad,py+6,w-pad*2,18)end
    return card,h
end
function M.benefits(hub,body,billing,shop)
    local g=frame(hub,body,'커맨더 혜택')
    local list=S.scroll(g.root,'Benefits',g.x,g.y,g.w,g.bottom-g.y)
    local ctx={hub=hub,shop=shop,billing=billing,list=list,g=g}
    local cards={};local y=0
    if g.pt then
        local a,ha=memberPanel(ctx,'club',0,y,g.w);y+=ha+12
        local b,hb=memberPanel(ctx,'permanent',0,y,g.w);y+=hb+12
        cards={a,b}
    else
        local cw=math.floor((g.w-(g.ph and 10 or 16))/2)
        local _,ha=memberPanel(ctx,'club',0,0,cw,true);local _,hb=memberPanel(ctx,'permanent',0,0,cw,true);local hh=math.max(ha,hb)
        local a=memberPanel(ctx,'club',0,0,cw,hh)
        local b=memberPanel(ctx,'permanent',g.w-cw,0,cw,hh)
        y=hh+(g.ph and 10 or 16);cards={a,b}
    end
    local _,h1=wrapped(list,'FreeEmoji','핑과 외교 이모지는 누구나 무료',12,C.muted,4,y,g.w-8);y+=h1+4
    local _,h2=wrapped(list,'XPStack','함께 보유하면 계정 XP 4배. 시즌 XP, 코인, 랭킹 점수에는 적용되지 않아요.',12,C.muted,4,y,g.w-8);y+=h2+8
    if hub.customDraft then
        local back=K.button(list,'BackToCustom',{kind='out',text='커스텀 설정으로 돌아가기',size=15,weight=800},function()hub:openPage('custom')end)
        back:place(0,y,g.w,g.ph and 44 or 48);y+=(g.ph and 44 or 48)+8
    end
    S.canvas(list,y)
    stagger(cards)
end

function M.draw(hub,body)
    local a=hub.account or {};local billing=a.billing;local shop=hub.callbacks.shop()
    hub.pageTitle.Text=({supply='보급 상자',benefits='커맨더 혜택'})[hub.page]
    first=require(script.Parent.Pop20).watch(hub,hub.page..':'..tostring(hub.supplyOdds or ''))
    if not hub.cp20Size then
        hub.cp20Size=hub.root:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            if hub.page=='benefits'and hub.overlay.Visible and not hub.cp20Redraw then
                hub.cp20Redraw=true;task.defer(function()hub.cp20Redraw=nil;if hub.page=='benefits'then hub:drawPage()end end)end
        end)
    end
    if not a.ready or not billing then
        local g=frame(hub,body,hub.pageTitle.Text)
        local l=K.text(g.root,'Loading',string.format('%s 불러오는 중…',hub.pageTitle.Text),15,C.muted,700,Enum.TextXAlignment.Center);K.box(l,g.x,g.y+40,g.w,40)
        return
    end
    if hub.page=='supply'then M.odds(hub,body,billing)
    elseif hub.page=='benefits'then M.benefits(hub,body,billing,shop)end
end
return M
