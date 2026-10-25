local Players=game:GetService("Players")
local Market=game:GetService("MarketplaceService")
local pack=game.ReplicatedStorage.FrontierNative
local C=require(pack.Core.CosmeticCatalog)
local UI=require(script.Parent.Theme)
local Models=require(script.Parent.BuildingModels)
local Requests=require(pack.Core.RequestLifecycle)
local BillingPrice=require(pack.Core.BillingPrice)
local Telemetry=require(script.Parent.TelemetryClient)
local Pending=require(script.Parent.PressPending)
local S={};S.__index=S
function S.new(onAccount,notify,redraw)
    local self=setmetatable({prices={},fetching={},account={loading=true,owned={},products={}},onAccount=onAccount,notify=notify,redraw=redraw,busy=false},S)
    self.remote=pack:WaitForChild("AccountRequest")
    pack:WaitForChild("AccountChanged").OnClientEvent:Connect(function(account) self:apply(account) end)
    Market.PromptGamePassPurchaseFinished:Connect(function(player,_,bought)
        if player==Players.LocalPlayer then
            Telemetry.emit('purchase_prompt_result',{sku=self.telemetrySku or 'other',result=bought and 'accepted'or 'closed'})
            self.promptOpen=false;self.busy=false;self.redraw()
        end
    end)
    Market.PromptProductPurchaseFinished:Connect(function(userId,_,bought)
        if userId==Players.LocalPlayer.UserId and self.promptOpen then Telemetry.emit('purchase_prompt_result',{sku=self.telemetrySku or 'other',result=bought and 'accepted'or 'closed'});self.promptOpen=false;self.busy=false;self.redraw()end
    end)
    Market.PromptSubscriptionPurchaseFinished:Connect(function(player,_,didTry)
        if player~=Players.LocalPlayer then return end
        Telemetry.emit('purchase_prompt_result',{sku='club',result=didTry and 'pending'or 'cancelled'})
        self.promptOpen=false;self.busy=false;self.redraw()
        if didTry then task.delay(10,function()self:run(function()self:request('restore')end)end)end
    end)
    task.spawn(function() self:request("read") end)
    local dev=script.Parent:FindFirstChild('CheatBoard');if dev then task.defer(function()require(dev).mount(self)end)end
    return self
end
function S:apply(account)
    if not account then return end
    self.account=account;self.onAccount(account);self.redraw()
end
function S:request(action,value,extra)
    local operation=self.requests and self.requests.active
    local ok,r=pcall(function() return self.remote:InvokeServer(action,value,extra) end)
    if operation and not self.requests:current(operation)then return nil end
    if not ok then Telemetry.step('shop','requestFailed',{item=type(action)=='string'and action or nil,reason='network'});self.notify("연결 실패",true);return nil end
    if r.account then self:apply(r.account) end
    if r.message then self.notify(r.message,not r.ok) end
    return r
end
function S:run(fn)
    if self.busy then return end
    self.requests=self.requests or Requests.new(12)
    local operation=self.requests:begin(os.clock());if not operation then return end
    local pend=Pending.begin()
    self.busy=true;self.redraw()
    task.delay(12,function()
        if self.requests:expire(operation,os.clock())then
            Pending.finish(pend);Telemetry.step('shop','requestFailed',{reason='timeout'});self.busy=self.promptOpen==true;self.redraw();self.notify('응답 지연',true)
        end
    end)
    task.spawn(function()
        local ok,err=pcall(fn)
        if not self.requests:complete(operation)then return end
        Pending.finish(pend);self.busy=self.promptOpen==true;self.redraw()
        if not ok then warn("Storefront request failed",err);self.notify("요청 실패",true) end
    end)
end
function S:holdPrompt()
    self.promptOpen=true;self.promptSerial=(self.promptSerial or 0)+1;local serial=self.promptSerial
    task.delay(120,function()
        if not self.promptOpen or self.promptSerial~=serial then return end
        self.promptOpen=false;if not(self.requests and self.requests.active)then self.busy=false end
        pcall(Telemetry.step,'shop','promptTimeout',{sku=self.telemetrySku or 'other',reason='timeout'});self.redraw()
    end)
end
function S:equip(id,slot)
    self:run(function()
        local operation=self.requests.active
        local ok,r=pcall(function() return pack.EquipCosmetic:InvokeServer(id,slot) end)
        if not self.requests:current(operation)then return end
        if ok and r.ok then self:apply(r.account);self.notify(C.get(id).name.." 장착 완료")
        else self.notify(ok and r.message or "장착 실패",true) end
    end)
end
function S:purchase(id)
    self:run(function()
        local r=self:request("purchase",id)
        if not r or not r.ok then return end
        self:holdPrompt();self.telemetrySku='other';Telemetry.emit('purchase_prompt_result',{sku='other',result='opened'})
        local ok,err=pcall(function() Market:PromptGamePassPurchase(Players.LocalPlayer,r.passId) end)
        if not ok then self.promptOpen=false;error(err) end
    end)
end
function S:purchaseBilling(key,origin)
    self.telemetrySku=key;Telemetry.emit('offer_selected',{sku=key,result='selected'})
    pcall(function()Telemetry.step('commerce','checkout',{sku=key,origin=origin,item=origin or require(script.Parent.TelemetryAuto).screen,value=self.priceLogged and self.priceLogged[key]or nil,result='selected'})end)
    self:run(function()
        local r=self:request('billingPurchase',key)
        if not r then pcall(Telemetry.step,'commerce','prompt',{sku=key,result='failed',reason='network'})end
        if not r or not r.ok then return end
        self:holdPrompt()
        local ok,err=pcall(function()
            if r.type=='pass'then Market:PromptGamePassPurchase(Players.LocalPlayer,r.id)
            elseif r.type=='subscription'then Market:PromptSubscriptionPurchase(Players.LocalPlayer,r.id)
            elseif r.type=='product'then Market:PromptProductPurchase(Players.LocalPlayer,r.id)
            else error('Unknown purchase type')end
        end)
        Telemetry.emit('purchase_prompt_result',{sku=key,result=ok and 'opened'or 'failed'})
        pcall(Telemetry.step,'commerce','prompt',{sku=key,result=ok and 'opened'or 'failed',reason=ok and 'none'or 'failed'})
        if not ok then self.promptOpen=false;error(err)end
    end)
end
function S:billingPrice(key,product,kind)
    if not product or not product.available then return nil end
    local id=kind=='subscription'and product.subscriptionId or kind=='pass'and product.passId or product.id
    if product.sale and not require(script.Parent.ShopCards).saleOn(product.sale)then id=product.sale.wasId end
    local cacheKey='billing:'..kind..':'..tostring(id);local cached=self.prices[cacheKey]
    if (not cached or os.clock()-cached.at>60)and not self.fetching[cacheKey]then
        self.fetching[cacheKey]=true;task.spawn(function()
            local ok,info=pcall(function()
                if kind=='subscription'then return Market:GetSubscriptionProductInfoAsync(id)end
                return Market:GetProductInfoAsync(id,kind=='pass'and Enum.InfoType.GamePass or Enum.InfoType.Product)
            end)
            self.prices[cacheKey]={at=os.clock(),info=ok and info or nil};self.fetching[cacheKey]=nil;self.redraw()
        end)
    end
    local robux=cached and cached.info and tonumber(cached.info.PriceInRobux)
    if robux and Telemetry.step and not (self.priceLogged and self.priceLogged[key])then self.priceLogged=self.priceLogged or {};self.priceLogged[key]=robux;Telemetry.step('shop','offerShown',{sku=key,item=key,value=robux,result='shown'})end
    return BillingPrice.format(cached and cached.info,kind,Players.LocalPlayer.LocaleId)
end
function S:drawSupply(kind,currency)
    self:run(function()
        local billing=self.account.billing;if not billing then return end
        local pending=self.pendingDraw
        if not pending or pending.kind~=kind or pending.currency~=currency then pending={kind=kind,currency=currency,sequence=billing.nextDraw,version=billing.catalogVersion,requestId=game.HttpService:GenerateGUID(false)};self.pendingDraw=pending end
        local r=self:request('supplyDraw',pending)
        if r and r.ok then
            self.pendingDraw=nil;self.lastSupply=r.result;self.supplyArrival=r.result and r.result.requestId;self.redraw()
            if r.result then require(script.Parent.SupplyReveal).open(self,r.result,function()self:drawSupply(kind,currency=='free'and 'medals'or currency)end)end
        elseif r then self.pendingDraw=nil;Telemetry.step('gacha','drawFailed',{sku=kind,result='rejected'})
        else Telemetry.step('gacha','drawFailed',{sku=kind,result='failed',reason='network'})end
    end)
end
function S:price(id,product)
    if not product or not product.forSale or product.passId<=0 then return nil end
    local cached=self.prices[id]
    if cached and os.clock()-cached.at<60 then return cached.info end
    if not self.fetching[id] then
        self.fetching[id]=true
        task.spawn(function()
            local ok,info=pcall(function() return Market:GetProductInfoAsync(product.passId,Enum.InfoType.GamePass) end)
            self.prices[id]={at=os.clock(),info=ok and info or nil};self.fetching[id]=nil;self.redraw()
        end)
    end
    return cached and cached.info or nil
end
function S:render(body,label,button,guide,compact)
    self.compact=compact
    local a=self.account;local colors=UI.colors
    if not compact then label("ShopIntro","NO PAY-TO-WIN",0,45,colors.muted,12) end
    label("AccountStatus",a.status or "보관함을 불러오는 중…",compact and 0 or 47,compact and 36 or 46,a.localMode and colors.gold or colors.muted,12)
    local y=compact and 42 or 104
    local iconSize=compact and 68 or 92
    local textX=compact and 84 or 104
    for _,id in ipairs({"classic","arctic","copper"}) do
        local style=C.get(id);local owned=a.owned[id]==true or style.access=="free"
        local equipped=a.cosmetics and a.cosmetics.territory==id
        local preview=Models.preview(body,"City",style);UI.box(preview,2,y,iconSize,compact and 72 or 100)
        local title=label("Title_"..id,style.name,y,compact and 26 or 35,colors.ink,17);title.Position=UDim2.fromOffset(textX,y);title.Size=UDim2.new(1,-textX-4,0,compact and 26 or 35)
        local text=style.access=="free" and "스탠더드 기본 보유" or owned and (a.localMode and "테스트 보유, 실제 구매 아님" or "보유 중, 영구 이용") or "스킨 미리보기"
        local detail=label("Detail_"..id,text.."\n영토, 지휘 모션, 도시, 초소",y+37,62,colors.muted,12);detail.Position=UDim2.fromOffset(textX,y+(compact and 27 or 37));detail.Size=UDim2.new(1,-textX-4,0,compact and 44 or 62)
        local buttonY=y+(compact and 76 or 108)
        local b
        if owned then b=button("Style_"..id,equipped and "장착 중" or "세트 장착",buttonY,function() self:equip(id) end,equipped)
        elseif a.localMode then b=button("TestUnlock_"..id,"테스트 해금 (0 Robux)",buttonY,function() self:run(function() self:request("testUnlock",id) end) end)
        else
            local product=a.products[id];local price=self:price(id,product)
            local available=product and product.forSale and price and price.IsForSale and type(price.PriceInRobux)=="number"
            local status=product and product.forSale and (self.prices[id] and "가격 확인 실패, 복원 후 다시 확인" or "가격 확인 중…") or "미보유"
            b=button("Purchase_"..id,available and string.format("%d Robux에 구매",price.PriceInRobux) or status,buttonY,function() self:purchase(id) end)
            b.Visible=product and product.forSale==true;UI.enabled(b,available and not self.busy and a.ready==true)
        end
        if owned or a.localMode then UI.enabled(b,not self.busy and a.ready==true and not equipped) end
        y+=compact and 140 or 177
    end
    button("BuildingGuide","건물 6종의 역할과 외형 보기",y,guide);y+=62
    local restore=button("RestoreAccount","보유권과 저장한 설정 복원",y,function() self:run(function() self.prices={};self:request("restore") end) end)
    UI.enabled(restore,not self.busy and not a.loading);y+=62
    local prefs=a.preferences or {}
    local reduced=button("ReducedEffects",prefs.reducedEffects and "간소한 이펙트: 켜짐" or "간소한 이펙트: 꺼짐",y,function() self:run(function() self:request("preference","reducedEffects",not prefs.reducedEffects) end) end);y+=62
    local sounds=button("ToySounds",prefs.soundsMuted and "효과음: 꺼짐" or "효과음: 켜짐",y,function() self:run(function() self:request("preference","soundsMuted",not prefs.soundsMuted) end) end);y+=62
    local shake=button("CameraShake",prefs.cameraShake~=false and "화면 흔들림: 켜짐" or "화면 흔들림: 꺼짐",y,function() self:run(function() self:request("preference","cameraShake",prefs.cameraShake==false) end) end);y+=62
    UI.enabled(reduced,not self.busy and a.ready==true);UI.enabled(sounds,not self.busy and a.ready==true);UI.enabled(shake,not self.busy and a.ready==true)
    label("FutureSlots","간소한 이펙트는 파편, 축하 연출, 화면 흔들림을 꺼요. 로켓과 폭발에도 장착한 스킨을 사용해요. ",y,74,colors.muted,12)
    body.CanvasSize=UDim2.fromOffset(0,y+88)
end
return S
