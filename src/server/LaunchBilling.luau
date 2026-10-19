local Players=game:GetService('Players')
local Market=game:GetService('MarketplaceService')
local PolicyService=game:GetService('PolicyService')
local Core=game.ReplicatedStorage.FrontierNative.Core
local Rules=require(Core.LaunchCommerce)
local Supply=require(Core.SupplyRules)
local Catalog=require(Core.SupplyCatalog)
local Styles=require(Core.CosmeticCatalog)
local Custom=require(Core.CustomBattlefieldRules)
local Policy=require(Core.CommercePolicy)
local Config=require(script.Parent.CommerceConfig)
local DrawConfirmation=require(script.Parent.SupplyDrawConfirmation)
local Live=require(script.Parent.LiveConfig)
local Schema=require(Core.TelemetrySchema)
local Testing=require(Core.SupplyTesting)
local Session=require(script.Parent.AccountSession)
local M={};M.__index=M
local errors={['paid-random-restricted']='이 계정에서는 유료 뽑기를 이용할 수 없어요.',['collection-not-ready']='스킨 컬렉션 준비 중',['insufficient-tickets']='뽑기권이 부족해요.',['insufficient-medals']='코인이 부족해요.',['subscription-required']='공개 모집은 VIP 클럽 혜택이에요.',['preset-locked']='설정 보관함은 커맨더 프라임 혜택이에요.',['busy']='잠시 뒤 다시 시도하세요.',['free-draw-used']='오늘 무료 뽑기는 이미 받았어요.'}
function M.new(accounts)
    local self=setmetatable({accounts=accounts,celebrations=require(script.Parent.SupplyCelebration)},M)
    Market.ProcessReceipt=function(receipt)local decision=self:receipt(receipt);pcall(self.logReceipt,self,receipt,decision);return decision end
    pcall(function()Market.PromptSubscriptionPurchaseFinished:Connect(function(player,id,bought)if id==Config.subscriptionId then accounts.analytics:emit(player,'purchase_prompt_result',{sku='club',stage='prompt',result=bought and 'accepted'or 'cancelled'});accounts.analytics:flow(player,'commerce','promptClosed',{sku='club',result=bought and 'accepted'or 'cancelled'})end end)end)
    pcall(function()Market.PromptProductPurchaseFinished:Connect(function(userId,id,bought)local player=Players:GetPlayerByUserId(userId);if not player then return end
        local kind='other';for k,entry in pairs(Config.developerProducts)do if entry.id==id then kind=k end end
        if kind=='other'and Config.clanProducts and Config.clanProducts.attend and Config.clanProducts.attend.id==id then kind='clanAttend'end
        accounts.analytics:flow(player,'commerce','promptClosed',{sku=Schema.enum('sku',kind,'other'),result=bought and 'accepted'or 'cancelled'})end)end)
    Players.UserSubscriptionStatusChanged:Connect(function(player,id)
        if id==Config.subscriptionId then task.spawn(function()local a=accounts.accounts[player];if a then self:refresh(player,a);accounts:publish(player,a)end end)end
    end)
    return self
end
function M:benefits(a)
    local current=a and a.clubStatus and a.clubStatus.checked and os.clock()-a.clubStatus.checked<360
    if current and Rules.clubLapsed(a.clubStatus.period,os.time())then current=false end
    return Rules.benefits(a and a.owned.permanent==true,current and a.clubStatus.active==true)
end
function M:paidAllowed(a)return a and a.randomPolicy and a.randomPolicy.allowed==true and os.clock()-a.randomPolicy.checked<360 end
function M:refresh(player,a)
    if not Session.current(self.accounts,player,a,Players)then return false end
    local observedAt=os.clock();local previous=a.clubStatus
    local generation=(a.billingGeneration or 0)+1;a.billingGeneration=generation
    local ok,status=pcall(function()return PolicyService:GetPolicyInfoForPlayerAsync(player)end)
    if a.billingGeneration~=generation or not Session.current(self.accounts,player,a,Players)then return false end
    a.randomPolicy={known=ok and type(status)=='table'and type(status.ArePaidRandomItemsRestricted)=='boolean',allowed=ok and type(status)=='table'and status.ArePaidRandomItemsRestricted==false,subscription=ok and type(status)=='table'and status.IsEligibleToPurchaseSubscription==true,checked=os.clock()}
    local subscribed=false;local verified=false;local period
    if self.accounts.localMode then
        local test=self.accounts.testOwned and self.accounts.testOwned[player.UserId];verified=true;subscribed=test~=nil and test.club==true
        if subscribed then period={endsAt=(test.clubEndsAt or os.time()+30*86400),renewing=test.clubEndsAt==nil}end
    elseif type(Config.subscriptionId)=='string'and Config.subscriptionId:match('^EXP%-%w+')and Policy.validCreator(Config,game.CreatorId,game.CreatorType.Name)and game.GameId==Config.universeId then
        local success,response=pcall(function()return Market:GetUserSubscriptionStatusAsync(player,Config.subscriptionId)end)
        verified=success and type(response)=='table';subscribed=verified and response.IsSubscribed==true
        if subscribed and Session.current(self.accounts,player,a,Players)and a.billingGeneration==generation then local got,details=pcall(function()return Market:GetUserSubscriptionDetailsAsync(player,Config.subscriptionId)end);period=got and Rules.clubPeriod(details)or nil end
    else verified=true end
    if a.billingGeneration~=generation or not Session.current(self.accounts,player,a,Players)then return false end
    a.clubStatus={active=subscribed,verified=verified,checked=os.clock(),period=period}
    local log=self.accounts.analytics;log:service(player,'account_request',ok and verified,observedAt)
    if not previous or previous.active~=subscribed or previous.verified~=verified then
        log:emit(player,'ownership_verified',{sku='club',result=verified and (subscribed and 'active'or 'inactive')or 'unknown',active=subscribed,verified=verified})
        log:emit(player,'subscription_lifecycle',{sku='club',stage='status',result=verified and (subscribed and 'active'or 'inactive')or 'unknown',verified=verified})
    end
    local owned=a.owned.permanent==true
    local ownershipKnown=not(a.uncertain and a.uncertain.permanent)
    if subscribed and verified and previous and previous.verified and not previous.active then log:flow(player,'commerce','receipt',{sku='club',item='club',result='granted'})end
    if owned and ownershipKnown and a.telemetryPermanent==false and a.telemetryPermanentKnown then log:flow(player,'commerce','receipt',{sku='permanent',item='permanent',result='granted'})end
    if a.telemetryPermanent~=owned or a.telemetryPermanentKnown~=ownershipKnown then a.telemetryPermanent=owned;a.telemetryPermanentKnown=ownershipKnown;log:emit(player,'ownership_verified',{sku='permanent',result=ownershipKnown and (owned and 'active'or 'inactive')or 'unknown',active=owned,verified=ownershipKnown})end
    log:context(player,{benefit_state=owned and subscribed and 'both'or owned and 'permanent'or subscribed and 'club'or 'free'})
    local checkout=log.sessions[player]
    if checkout and (checkout.checkoutSku=='club'and subscribed and verified or checkout.checkoutSku=='permanent'and owned and ownershipKnown)then checkout.checkoutOwnership=true;log:funnel(player,'Checkout','ownership',checkout.checkout);log:funnel(player,'Checkout','benefit',checkout.checkout)end
    if not a.ready then return end
    local b=self:benefits(a);local c=a.profile.commerce
    local active=a.profile.outgame and a.profile.outgame.activeLoadout
    if ownershipKnown and type(active)=='number'and active>b.loadoutSlots then self.accounts:updateProgress(player.UserId,function(p)p.outgame.activeLoadout=nil;return p end)end
    if a.billingGeneration~=generation or not Session.current(self.accounts,player,a,Players)then return false end
    if b.permanent and not c.permanentWelcome or b.club and c.dailyClub<math.floor(os.time()/86400)then
        local grantAt=os.time()
        local beforeWelcome=c.permanentWelcome;local beforeDaily=c.dailyClub
        local saved=self.accounts:updateProgress(player.UserId,function(p)
            local next=p.commerce
            if b.permanent then next=assert(Supply.welcome(next))end
            next=assert(Supply.daily(next,b.club,grantAt));p.commerce=next;return p
        end,'TimedReward',b.permanent and not c.permanentWelcome and 'permanent'or 'club')
        if saved then
            if not beforeWelcome and saved.commerce.permanentWelcome then log:emit(player,'benefit_used',{benefit='permanent_welcome',result='granted',sku='permanent',count=4});log:flow(player,'commerce','primeWelcome',{sku='permanent',value=4,result='granted'})end
            if saved.commerce.dailyClub~=beforeDaily then log:emit(player,'daily_reward_claimed',{benefit='daily_tickets',result='granted',sku='club'});log:emit(player,'benefit_used',{benefit='daily_tickets',result='granted',sku='club',count=1});log:flow(player,'vip','dailyTicket',{sku='club',value=1,result='granted'})end
        end
    end
end
function M:logReceipt(receipt,decision)
    if type(receipt)~='table'then return end
    local player=type(receipt.PlayerId)=='number'and Players:GetPlayerByUserId(receipt.PlayerId);if not player then return end
    local kind='other';for k,entry in pairs(Config.developerProducts)do if entry.id>0 and entry.id==receipt.ProductId then kind=k end end
    if kind=='other'and self.accounts.clans and self.accounts.clans.product then local ok,info=pcall(self.accounts.clans.product,self.accounts.clans);if ok and info and info.id>0 and info.id==receipt.ProductId then kind='clanAttend'end end
    local a=self.accounts.accounts[player]
    self.accounts.analytics:flow(player,'commerce','receipt',{item=kind,sku=Schema.enum('sku',kind,'other'),value=decision==Enum.ProductPurchaseDecision.PurchaseGranted and tonumber(receipt.CurrencySpent)or nil,result=decision==Enum.ProductPurchaseDecision.PurchaseGranted and 'granted'or 'pending',
        reason=decision==Enum.ProductPurchaseDecision.PurchaseGranted and 'none'or kind=='other'and 'invalid'or (not a or not a.ready)and 'not_loaded'or 'storage_unavailable'})
end
function M:receipt(receipt)
    if type(receipt)~='table'or type(receipt.PurchaseId)~='string'or #receipt.PurchaseId>100 or type(receipt.PlayerId)~='number'then return Enum.ProductPurchaseDecision.NotProcessedYet end
    local clans=self.accounts.clans;if clans then local decision=clans:receipt(receipt,Players:GetPlayerByUserId(receipt.PlayerId));if decision then return decision end end
    local product
    for _,entry in pairs(Config.developerProducts)do if entry.id>0 and entry.id==receipt.ProductId then product=entry;break end end
    if not product or game.GameId~=Config.universeId or not Policy.validCreator(Config,game.CreatorId,game.CreatorType.Name)then return Enum.ProductPurchaseDecision.NotProcessedYet end
    local player,a;local deadline=os.clock()+20
    repeat
        player=Players:GetPlayerByUserId(receipt.PlayerId);a=player and self.accounts.accounts[player]
        if not player or self.accounts.closing or a and a.ready and not a.loading then break end
        task.wait(.5)
    until os.clock()>=deadline
    if not a or not a.ready or a.loading or self.accounts.closing then return Enum.ProductPurchaseDecision.NotProcessedYet end
    local duplicate=false
    local saved=self.accounts:updateProgress(receipt.PlayerId,function(p)
        local c,err=Supply.grant(p.commerce,receipt.PurchaseId,product.kind,product.count)
        duplicate=err=='already-granted'
        if not c then return nil,err end;p.commerce=c;return p
    end,'IAP',product.kind)
    self.accounts.analytics:emit(player,'commerce_grant_result',{sku=product.kind,result=saved and 'granted'or 'retry',amount=product.count,duplicate_receipt=duplicate},
        {id='receipt:'..self.accounts.analytics.key(receipt.PurchaseId)..':'..(saved and 'granted'or 'retry')})
    local checkout=self.accounts.analytics.sessions[player]
    if saved and checkout and checkout.checkoutSku==product.kind then checkout.checkoutOwnership=true;self.accounts.analytics:funnel(player,'Checkout','ownership',checkout.checkout);self.accounts.analytics:funnel(player,'Checkout','benefit',checkout.checkout)end
    return saved and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
end
function M:snapshot(a)
    local c=a.profile.commerce;local b=self:benefits(a);local paid=self:paidAllowed(a)
    local products={}
    local valid=not self.accounts.localMode and Config.purchasesEnabled and Live.salesOpen()and game.GameId==Config.universeId and Policy.validCreator(Config,game.CreatorId,game.CreatorType.Name)
    for kind,product in pairs(Config.developerProducts)do
        local odds,why=Supply.odds(kind)
        products[kind]={id=product.id,kind=kind,name=Rules.tickets[kind].name,odds=odds,reason=why,available=valid and paid and odds~=nil and product.id>0}
    end
    local all=Supply.pool('basic')~=nil
    return {benefits=b,testingAvailable=Testing.enabled(game:GetService('RunService'):IsStudio(),self.accounts.localMode),testTickets=table.clone(c.studioTickets or {}),serials=table.clone(c.serials),paidRandomAllowed=paid==true,policyKnown=a.randomPolicy and a.randomPolicy.known==true or false,collectionReady=all,catalogVersion=Catalog.version,nextDraw=c.drawSequence+1,freeDrawAt=Supply.freeDrawAt(c),tickets=table.clone(c.tickets),fragments=table.clone(c.fragments),owned=table.clone(c.owned),history=table.clone(c.history),presets=table.clone(c.presets),dailyClaimed=c.dailyClub==math.floor(os.time()/86400),medalDrawCost=Rules.medalDrawCost,
        products=products,salesOpen=valid==true,permanent={welcomePending=b.permanent and not c.permanentWelcome,passId=Policy.passId(Config,game.GameId,'permanent',game.CreatorId,game.CreatorType.Name)or 0,available=valid and paid and all and not b.permanent and Policy.passId(Config,game.GameId,'permanent',game.CreatorId,game.CreatorType.Name)~=nil},
        club={subscriptionId=Config.subscriptionId,available=valid and paid and all and not b.club and a.randomPolicy.subscription==true and Config.subscriptionId:match('^EXP%-%w+$')~=nil,
            daysLeft=b.club and a.clubStatus and a.clubStatus.period and Rules.clubDaysLeft(a.clubStatus.period.endsAt,os.time())or nil,
            renewing=b.club and a.clubStatus and a.clubStatus.period and a.clubStatus.period.renewing or nil}}
end
function M:publicCustom(player,rules)
    if type(rules)~='table'or rules.visibility~='public'then return true end
    local a=self.accounts.accounts[player];if not Session.current(self.accounts,player,a,Players)then return false,'subscription-required'end
    if not a.clubStatus or os.clock()-a.clubStatus.checked>=300 then self:refresh(player,a)end
    local allowed=Session.current(self.accounts,player,a,Players)and self:benefits(a).publicCustom
    self.accounts.analytics:emit(player,'benefit_used',{benefit='public_custom',result=allowed and 'accepted'or 'rejected',reason=allowed and 'none'or 'subscription_required',sku='club'})
    return allowed,'subscription-required'
end
function M:purchase(player,a,value)
    local log=self.accounts.analytics;local session=log:session(player);session.checkout=game.HttpService:GenerateGUID(false);session.checkoutSku=Schema.enum('sku',value,'other');session.checkoutOwnership=nil;log:context(player,{purchase_attempt_id=session.checkout})
    log:emit(player,'purchase_attempt',{sku=session.checkoutSku,stage='request',result='selected'});log:funnel(player,'Checkout','selected',session.checkout)
    self:refresh(player,a)
    if not Session.current(self.accounts,player,a,Players)then return {ok=false,message=errors.busy}end
    local view=self:snapshot(a)
    local function ready(result)log:funnel(player,'Checkout','ready',session.checkout);log:emit(player,'purchase_attempt',{sku=session.checkoutSku,stage='prompt',result='ready'});return result end
    if value=='permanent'and view.permanent.available then return ready({ok=true,type='pass',id=view.permanent.passId})
    elseif value=='club'and view.club.available then return ready({ok=true,type='subscription',id=view.club.subscriptionId})
    elseif type(value)=='string'and view.products[value]and view.products[value].available then return ready({ok=true,type='product',id=view.products[value].id})
    end
    local why=(value=='permanent'or value=='club')and view.benefits and view.benefits[value]and 'duplicate'or not view.collectionReady and 'not_loaded'or not view.policyKnown and 'unknown'or not view.paidRandomAllowed and 'policy_restricted'or view.salesOpen and value=='club'and 'policy_restricted'or 'sales_disabled'
    log:emit(player,'purchase_attempt',{sku=session.checkoutSku,stage='request',result='rejected',reason=why})
    log:flow(player,'commerce','blocked',{sku=session.checkoutSku,result='rejected',reason=why})
    return {ok=false,message=not view.collectionReady and '스킨 컬렉션 준비 중'or not view.policyKnown and '이용 가능 여부를 확인하지 못했어요. 다시 시도해 주세요.'or not view.paidRandomAllowed and errors['paid-random-restricted']or '판매 준비 중이에요.'}
end
function M:request(player,a,action,value)
    if player:GetAttribute('FrontierRoom')then return {ok=false,message='로비에서 사용할 수 있어요.'}end
    if not a.ready then return {ok=false,message='보관함을 불러오는 중이에요.'}end
    if action=='billingPurchase'then
        if type(value)~='string'or #value>32 or (value~='permanent'and value~='club'and not Config.developerProducts[value])then return {ok=false,message='판매 준비 중이에요.'}end
        if not Session.current(self.accounts,player,a,Players)or a.checkoutPending then pcall(function()self.accounts.analytics:flow(player,'commerce','blocked',{sku=Schema.enum('sku',value,'other'),result='rejected',reason='busy'})end);return {ok=false,message=errors.busy}end
        a.checkoutPending=true
        local ok,result=pcall(self.purchase,self,player,a,value)
        a.checkoutPending=nil
        if not ok then return {ok=false,message=errors.busy}end
        return result
    end
    local result;local fresh=false
    local entropy=Random.new():NextNumber()
    local drawAt=action=='supplyDraw'and os.time()or nil
    local benefits=self:benefits(a);local paidAllowed=self:paidAllowed(a)
    local valid,err=require(Core.BillingRequestRules).valid(action,value,benefits,game:GetService('RunService'):IsStudio(),self.accounts.localMode)
    local profile
    if valid then profile,err=self.accounts:updateProgress(player.UserId,function(p)
        if action=='supplyDraw'then
            if type(value)~='table'or value.version~=Catalog.version then return nil,'invalid-request'end
            fresh=p.commerce.draws[value.requestId]==nil
            local next,info,medals
            if value.currency=='studio'then next,info,medals=Testing.draw(p.commerce,value,entropy,p.outgame.medals,drawAt,player.UserId,game:GetService('RunService'):IsStudio(),self.accounts.localMode)
            else next,info,medals=Supply.draw(p.commerce,value.kind,value.currency,value.requestId,entropy,p.outgame.medals,paidAllowed,drawAt,nil,value.sequence,player.UserId)end
            if not next then return nil,info end;p.commerce=next;p.outgame.medals=medals;result=info
        elseif action=='supplyTestGrant'then
            local next,why=Testing.grant(p.commerce,game:GetService('RunService'):IsStudio(),self.accounts.localMode);if not next then return nil,why end;p.commerce=next
        elseif action=='equipSupply'then
            local loadout=type(value)=='string'and Supply.ownedLoadout(p.commerce,value)
            if not loadout then return nil,'invalid-request'end
            for slot,style in pairs(loadout)do if not Styles.validSlot(slot)or not Styles.styles[style]then return nil,'invalid-catalog'end end
            for slot,style in pairs(loadout)do p.loadout[slot]=style;p.outgame.ownedSlots[slot..':'..style]=true end
            require(Core.ProfileModel).syncPreset(p)
        elseif action=='savePreset'then
            if benefits.presetSlots==0 then return nil,'preset-locked'end
            if type(value)~='table'or type(value.slot)~='number'or value.slot%1~=0 or value.slot<1 or value.slot>benefits.presetSlots then return nil,'invalid-request'end
            local rules,why=Custom.normalize(value.rules);if not rules then return nil,why end
            rules.visibility='invite';p.commerce.presets[tostring(value.slot)]=rules
        else return nil,'invalid-request'end
        return p
    end,action=='supplyDraw'and 'Shop'or nil,action=='supplyDraw'and type(value)=='table'and value.kind or 'supply')end
    local log=self.accounts.analytics
    if action=='supplyDraw'then
        if not profile and err=='storage-unavailable'then
            local confirmed,stored=DrawConfirmation.recover(self.accounts,player.UserId,value)
            if confirmed then profile=confirmed;result=stored;err=nil;fresh=false end
        end
        if not profile then result=nil end
    end
    if action=='supplyDraw'then log:emit(player,'draw_result',{sku=type(value)=='table'and value.kind or 'other',rarity=result and result.rarity or 'other',result=profile and 'granted'or 'rejected',reason=profile and 'none'or Schema.reason(err)},
        {id='draw:'..log.key(tostring(player.UserId)..':'..tostring(type(value)=='table'and value.requestId))..':'..(profile and 'granted'or 'rejected')})
    elseif action=='equipSupply'then log:emit(player,'cosmetic_equipped',{result=profile and 'ok'or 'failed'})
    elseif action=='savePreset'then log:emit(player,'preset_action',{stage='save',result=profile and 'ok'or 'failed'});if profile then log:emit(player,'benefit_used',{benefit='preset_slots',result='ok',sku='permanent'})end end
    if action=='supplyDraw'and not profile and type(value)=='table'and value.currency=='free'then pcall(log.flow,log,player,'gacha','freeDraw',{sku=Schema.enum('sku',value.kind,'other'),result='rejected',reason=Schema.reason(err)})end
    if profile and fresh and result then require(script.Parent.TelemetryProgress).safe(require(script.Parent.TelemetryProgress).draw,log,player,value,result)end
    if action=='savePreset'and err=='preset-locked'then log:emit(player,'benefit_used',{benefit='preset_slots',result='rejected',reason='subscription_required',sku='permanent'})end
    if profile and fresh and result and not result.duplicate then self.celebrations.announce(player,result)end
    return {ok=profile~=nil,result=result,message=err and(errors[err]or '요청을 완료하지 못했어요.'),account=self.accounts:snapshot(player)}
end
return M
