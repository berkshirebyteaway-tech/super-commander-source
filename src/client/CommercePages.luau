local UI=require(script.Parent.ToyUI)
local Theme=require(script.Parent.Theme)
local Icons=require(script.Parent.OutgameIcons)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local L=require(script.Parent.Localization)
local TextService=game:GetService('TextService')
local M={}
local Supply=require(script.Parent.SupplyPresentation)
local function text(p,name,value,x,y,w,h,size,color)
    local l=UI.label(p,name,value,size or 14,color);UI.box(l,x,y,w,h);return l
end
function M.draw(hub,body,w)
    local a=hub.account or {};local billing=a.billing;local shop=hub.callbacks.shop();local y=0
    local function button(name,title,fn,enabled,primary)
        local b=UI.button(body,name,title,fn,primary);UI.box(b,2,y,w-4,44);y+=52;UI.enabled(b,enabled~=false and not shop.busy);return b
    end
    local function note(name,value,color)
        local bounds=Vector2.new(w-8,10000)
        local height=math.max(36,TextService:GetTextSize(value,13,Enum.Font.BuilderSansBold,bounds).Y+10,TextService:GetTextSize(L.text(value,body),13,Enum.Font.BuilderSansBold,bounds).Y+10)
        local l=text(body,name,value,4,y,w-8,height,13,color or UI.colors.muted);l.TextWrapped=true;y+=height+8;return l
    end
    if require(script.Parent.Lobby20).ENABLED and (hub.page=='benefits'or hub.page=='supply'and hub.supplyOdds)then require(script.Parent.CommercePages20).draw(hub,body);return end
    hub.pageTitle.Text=({supply='보급 상자',benefits='커맨더 혜택'})[hub.page]
    if not a.ready or not billing then note('Loading',string.format('%s 불러오는 중…',hub.pageTitle.Text));body.CanvasSize=UDim2.fromOffset(0,y);return end
    if hub.page=='supply'and not hub.supplyOdds then require(script.Parent.ShopLanding).draw(hub,body,w);return end
    require(script.Parent.PageWallet).show(hub,{{icon='coin',value=a.progress and a.progress.medals or 0,name='Medals'}})
    local back=UI.button(body,'BackToShop','‹ 상점',function()hub.supplyOdds=nil;hub:openPage('shop')end);UI.box(back,0,0,120,40);back.TextSize=14;y=52
    if hub.page=='supply'then
        if hub.supplyOdds then
            local product=billing.products[hub.supplyOdds]
            hub.pageTitle.Text=({basic='보급 상자',epic='에픽 보급 상자',legendary='전설 보급 상자',mythic='신화 보급 상자'})[hub.supplyOdds]or '보급 상자'
            note('OddsNote','개별 아이템 확률, 중복 가능',UI.colors.ink)
            local odds=product and product.odds
            require(script.Parent.TelemetryStep).step('shop','oddsView',{sku=hub.supplyOdds,count=odds and #odds or 0,result=odds and 'shown'or 'unavailable',reason=odds and 'none'or 'not_loaded'})
            if not odds then note('NotReady','스킨 컬렉션 준비 중')else
                note('Rounded','확률은 반올림되어 합계가 다를 수 있어요.')
                local function rate(v)return string.format(v>=10 and '%.1f%%'or v>=1 and '%.2f%%'or v>=.1 and '%.3f%%'or '%.4f%%',v)end
                for _,entry in ipairs(odds)do
                    local l=text(body,'Odds_'..entry.id,entry.name,8,y,w-112,40,14);l.TextTruncate=Enum.TextTruncate.AtEnd
                    local percent=text(body,'Rate_'..entry.id,rate(entry.percent),w-106,y,98,40,13,UI.colors.gold);percent.TextXAlignment=Enum.TextXAlignment.Right;y+=44
                end
                note('Duplicates',string.format('이미 가진 외형이 나오면 코인이나 무료로 열었을 땐 코인 %d을 돌려받고, 뽑기권으로 열었을 땐 그 상자 조각 1개를 받아요. 조각 5개면 뽑기권 1장이 돼요.',require(script.Parent.ShopCards).refund))
            end
        else
            require(script.Parent.SupplyShop).draw(hub,body,w,y);return
        end
    elseif hub.page=='benefits'then
        local b=billing.benefits;local Shop=require(script.Parent.ShopLanding)
        local two=w>=600;local cw=two and (w-14)/2 or w-4
        Shop.offerCard(hub,body,shop,billing,'club',2,y,cw,{inPage=true})
        Shop.offerCard(hub,body,shop,billing,'permanent',two and cw+12 or 2,two and y or y+Shop.offerHeightFor(body)+10,cw,{inPage=true})
        y+=(two and Shop.offerHeightFor(body)or Shop.offerHeightFor(body)*2+10)+12
        note('FreeEmoji','핑과 외교 이모지는 누구나 무료')
        if b.club then
            note('DailyClub',billing.dailyClaimed and '오늘 뽑기권 지급 완료'or '오늘 혜택 확인 중')
            button('ManageClub','구독 관리',function()local ok=pcall(function()game:GetService('MarketplaceService'):PromptCancelSubscription(game.Players.LocalPlayer,billing.club.subscriptionId)end);require(script.Parent.TelemetryStep).step('vip','manageClub',{sku='club',result=ok and 'opened'or 'failed'});if not ok then hub.notify('요청 실패',true)end end,true)
        end
        if billing.permanent.welcomePending then require(script.Parent.TelemetryStep).once('welcomePending','commerce','welcomePending',{sku='permanent',result='pending'});note('WelcomePending','구매 보상 저장 중')end
        note('XPStack','함께 보유하면 계정 XP 4배. 시즌 XP, 코인, 랭킹 점수에는 적용되지 않아요.')
        if hub.customDraft then button('BackToCustom','커스텀 설정으로 돌아가기',function()hub:openPage('custom')end,true)end
    end
    body.CanvasSize=UDim2.fromOffset(0,y+8)
end
return M
