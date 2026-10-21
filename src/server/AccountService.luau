local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Market=game:GetService("MarketplaceService")
local pack=game.ReplicatedStorage.FrontierNative
local C=require(pack.Core.CosmeticCatalog)
local P=require(pack.Core.ProfileModel)
local O=require(pack.Core.OutgameRules)
local ResultPresentation=require(pack.Core.ResultPresentation)
local Policy=require(pack.Core.CommercePolicy)
local Config=require(script.Parent.CommerceConfig)
local Repository=require(script.Parent.ProfileRepository)
local Ownership=require(script.Parent.OwnershipState)
local Session=require(script.Parent.AccountSession)
local Retention=require(script.Parent.ProfileRetention)
local Analytics=require(script.Parent.ExperienceAnalytics)
local Live=require(script.Parent.LiveConfig)
local DailyBoard=require(script.Parent.DailyBoard)
local SeasonBoard=require(script.Parent.SeasonBoard)
local Daily=require(pack.Core.DailyOperation)
local Benefits=require(pack.Core.BenefitRewards)
local Billing=require(script.Parent.LaunchBilling)
local Sale=require(pack.Core.LaunchSale)
local Guards=require(pack.Core.AbuseGuards)
local S={};S.__index=S
local messages={
    ["busy"]="저장 중이에요. 잠시 뒤 다시 시도하세요.",
    ["storage-unavailable"]="저장에 연결하지 못했어요. 바뀐 건 없으니 다시 시도하세요.",
    ["profile-not-loaded"]="보관함을 불러오지 못했어요. 복원을 눌러 다시 연결하세요.",
    ["already-owned"]="이미 보유한 스킨이에요.",
    ["sales-disabled"]="판매 준비 중이에요. 아직 Robux로 구매할 수 없어요.",
    ["ownership-unavailable"]="보유권을 확인하지 못했어요. 복원 후 다시 시도하세요.",
}
local function newRemote(class,name) local r=Instance.new(class);r.Name=name;r.Parent=pack;return r end
function S.new(onChanged)
    local self=setmetatable({accounts={},onChanged=onChanged,testOwned={},memory={},closing=false,analytics=Analytics.new(),live=Live.start(),dailyBoard=DailyBoard.new(),seasonBoard=SeasonBoard.new()},S)
    self.analytics.exitState=function(player)
        local a=self.accounts[player];if not(a and a.ready and a.profile)then return nil end
        local n,medals=0,0;for _,c in pairs(a.profile.outgame.goalClaims or {})do n+=1;medals+=type(c)=='table'and tonumber(c.medals)or 0 end
        local c=a.profile.commerce;return {count=n,value=medals,available=type(c)=='table'and type(c.dailyFree)=='number'and c.dailyFree<math.floor(os.time()/86400)}
    end
    self.localMode=Run:IsStudio() or game.GameId==0
    self.referrals=self.localMode and {GetAsync=function(_,k)return self.memory['ref:'..k]end,UpdateAsync=function(_,k,fn)local v=fn(self.memory['ref:'..k]);if v then self.memory['ref:'..k]=v end;return v end}
        or game:GetService("DataStoreService"):GetDataStore("SuperCommanderReferrals_v1")
    local store
    if self.localMode then
        local memory=self.memory
        store={GetAsync=function(_,key) return memory[key] end,UpdateAsync=function(_,key,fn) local v=fn(memory[key]);if v then memory[key]=v end;return v end}
    else store=game:GetService("DataStoreService"):GetDataStore(Config.dataStoreName) end
    self.repo=Repository.new(store,task.wait)
    self.repo.observe=function(ok,attempt)if not ok then self.analytics:emit(nil,'service_operation',{operation='profile_save',stage='retry',result='failed',attempts=attempt})end end
    self.billing=Billing.new(self)
    self.changed=newRemote("RemoteEvent","AccountChanged")
    self.request=newRemote("RemoteFunction","AccountRequest")
    self.request.OnServerInvoke=function(player,action,value,extra) local r=self:requestAction(player,action,value,extra);pcall(function()self.analytics:request(player,'account',action,r,value)end);return r end
    Players.PlayerAdded:Connect(function(p) task.spawn(function() self:load(p) end) end)
    Players.PlayerRemoving:Connect(function(p)
        local a=self.accounts[p];if a then a.departed=true end
        task.spawn(function()pcall(self.seasonBoard.leave,self.seasonBoard,p.UserId)end)
        task.spawn(function()
            local deadline=os.clock()+20
            while self.repo.busy[tostring(p.UserId)] and os.clock()<deadline do task.wait(.1) end
            self.repo:forget(tostring(p.UserId),Players:GetPlayerByUserId(p.UserId)~=nil);self.accounts[p]=nil
        end)
    end)
    for _,p in ipairs(Players:GetPlayers()) do task.spawn(function() self:load(p) end) end
    self.clans=require(script.Parent.ClanService).new(self)
    Market.PromptGamePassPurchaseFinished:Connect(function(p,passId,purchased)
        pcall(function()self.analytics:emit(p,'purchase_prompt_result',{sku='permanent',stage='prompt',result=purchased and 'accepted'or 'cancelled'});self.analytics:flow(p,'commerce','promptClosed',{sku='permanent',result=purchased and 'accepted'or 'cancelled'})end)
        if not purchased or self.localMode then return end
        for id in pairs(Config.passes) do
            local regular=Policy.passId(Config,game.GameId,id,game.CreatorId,game.CreatorType.Name)
            if regular and (regular==passId or Sale.saleId(Config.salePasses,id)==passId)then
                task.spawn(function()
                    local confirmed,tries=Ownership.confirmPurchase(function()
                        local a=self.accounts[p];if not a or a.departed or p.Parent~=Players then return false end
                        if a.loading then return nil end
                        self:refreshOwnership(p,a);self:publish(p,a)
                        if a.owned[id]==true then return true end
                        return nil
                    end,task.wait)
                    pcall(function()self.analytics:flow(p,'commerce','passConfirm',{sku='permanent',count=tries,result=confirmed and 'granted'or 'pending'})end)
                end)
                break
            end
        end
    end)
    game:BindToClose(function()
        self.closing=true
        local deadline=os.clock()+25
        while next(self.repo.busy) and os.clock()<deadline do task.wait(.1) end
    end)
    return self
end
function S:refreshOwnership(player,a)
    if not Session.current(self,player,a,Players)then return false end
    local generation=Ownership.begin(a);local results={}
    for id in pairs(Config.passes) do
        if self.localMode then results[id]={ok=true,owned=(self.testOwned[player.UserId]or {})[id]==true}
        else
            local passId=Policy.passId(Config,game.GameId,id,game.CreatorId,game.CreatorType.Name)
            if passId then
                local ids={passId};local sale=Sale.saleId(Config.salePasses,id);if sale then table.insert(ids,sale)end
                local allKnown,owned=true,false
                for _,checkId in ipairs(ids)do
                    local verified,got
                    for attempt=1,3 do
                        if not Session.current(self,player,a,Players)or a.ownershipGeneration~=generation then return false end
                        verified,got=pcall(function() return Market:UserOwnsGamePassAsync(player.UserId,checkId) end)
                        if verified then break end
                        if attempt<3 then task.wait(attempt) end
                    end
                    if not verified then allKnown=false elseif got==true then owned=true;break end
                end
                results[id]={ok=owned or allKnown,owned=owned}
            else results[id]={ok=true,owned=false}end
        end
    end
    if not Session.current(self,player,a,Players)or not Ownership.commit(a,generation,results)then return false end
    self.billing:refresh(player,a);return true
end
function S:load(player)
    if self.closing or player.Parent~=Players then return end
    local observedAt=os.clock();self.analytics:joined(player)
    local a=self.accounts[player]
    if a and a.loading then return end
    a=a or {owned={classic=true},profile=P.decode(nil)};self.accounts[player]=a;a.loading=true;a.ready=false
    self:publish(player,a)
    local profile,err=self.repo:load(tostring(player.UserId))
    if not Session.current(self,player,a,Players)then a.loading=false;return end
    if profile then a.profile=profile;a.ready=true end
    a.error=err;self:refreshOwnership(player,a);a.loading=false
    if not Session.current(self,player,a,Players)then return end
    if a.ready and not a.checkIn then self:checkIn(player,a)end
    if not Session.current(self,player,a,Players)then return end
    if a.ready and not a.socialChecked then a.socialChecked=true;task.spawn(function()self:social(player)end)end
    if not a.dailyTimer then a.dailyTimer=true;task.spawn(function()self:dailyTimer(player,a)end)end
    self:publish(player,a)
    self.analytics:account(player,a,observedAt)
    local observed=self.repo.observations[tostring(player.UserId)]
    if a.ready and observed and not a.telemetryReturnLogged then
        a.telemetryReturnLogged=true
        pcall(function()for key,v in pairs(type(a.profile.preferences)=='table'and a.profile.preferences or {})do if type(v)=='boolean'or type(v)=='number'then
            self.analytics:flow(player,'settings','snapshot',{item=key,active=type(v)=='boolean'and v or nil,value=type(v)=='number'and v or nil,result='ok'})
        end end end)
        pcall(function()local o=a.profile.outgame;local pvp=0;for _,k in ipairs({'pvp','coop'})do local st=type(o.stats)=='table'and o.stats[k];pvp+=type(st)=='table'and tonumber(st.games)or 0 end
            self.analytics:journeyProfile(player,{new=observed.new==true,basics=o.basicsComplete==true,pvpGames=pvp})end)
        self.analytics:emit(player,'return_observed',{first_visit=observed.new,elapsed_seconds=type(observed.previous)=='table'and math.max(0,os.time()-(observed.previous.lastAt or os.time()))or nil,result=observed.previous and 'ok'or 'unknown'})
        if not a.visitRecorded then a.visitRecorded=true;task.spawn(function()self:updateProgress(player.UserId,function(p)
            local previous=p.telemetryVisit or {};p.telemetryVisit={firstAt=previous.firstAt or os.time(),lastAt=os.time(),visits=(previous.visits or 0)+1};return p
        end)end)end
    end
end
function S:checkIn(player,a)
    local claimAt=os.time()
    local info,current
    local saved,err=self:updateProgress(player.UserId,function(p)
        local out,result=O.checkIn(p.outgame,claimAt);if not out then return nil,result end
        if not result then current=p;return nil,'already-checked-in'end
        info=result;p.outgame=out;return p
    end,'TimedReward','checkIn')
    if saved and info then a.profile=saved;a.checkIn=info;self.analytics:emit(player,'daily_reward_claimed',{sku='checkIn',result='granted'});self.analytics:flow(player,'lobby','checkIn',{value=info.medals,count=info.streak,item='step'..tostring(info.rewardStep or 0),result='granted'})end
    if not saved and err~='already-checked-in'then self.analytics:flow(player,'lobby','checkIn',{result='failed',reason=require(pack.Core.TelemetrySchema).reason(err)})end
    if err=='already-checked-in'and current then a.profile=current;self.repo.loaded[tostring(player.UserId)]=current end
    return saved~=nil or err=='already-checked-in',info
end
function S:dailyTimer(player,a)
    local delay=60
    while player.Parent==Players and not a.departed and self.accounts[player]==a do
        task.wait(delay)
        if not Session.current(self,player,a,Players)then break end
        if a.ready and not a.loading and a.unverified and not self.closing then pcall(function()self:refreshOwnership(player,a);self:publish(player,a)end)end
        if not Session.current(self,player,a,Players)then break end
        if a.ready and not a.loading and not self.closing and (not a.clubStatus or os.clock()-a.clubStatus.checked>=(a.clubStatus.verified and 300 or 55) or a.owned.permanent==true and not a.profile.commerce.permanentWelcome or self.billing:benefits(a).club and a.profile.commerce.dailyClub<math.floor(os.time()/86400))then self.billing:refresh(player,a);self:publish(player,a)end
        if not Session.current(self,player,a,Players)then break end
        if a.ready and not a.loading and not self.closing then pcall(function()if (player:GetAttribute('CommanderVIP')==true)~=(self.billing:benefits(a).club==true)then self:publish(player,a)end end)end
        local login=a.profile and a.profile.outgame and a.profile.outgame.login
        if a.ready and not a.loading and not self.closing and (login and login.day or -1)<tonumber(O.day(os.time()))then
            local ok,info=self:checkIn(player,a);delay=ok and 60 or math.min(delay*2,240)
            if info then self:publish(player,a)end
        else delay=60 end
    end
end
function S:social(player)
    local a=self.accounts[player]
    if not Session.current(self,player,a,Players)then return end
    local id=player.UserId
    if self.live.enabled('groupPerk')and Config.creatorGroupId and Config.creatorGroupId>0 then self:checkGroup(player)end
    if not Session.current(self,player,a,Players)or not self.live.enabled('invites')then return end
    local joined,join=pcall(function()return player:GetJoinData()end)
    if not Session.current(self,player,a,Players)then return end
    local inviter=joined and type(join)=='table'and tonumber(join.ReferredByPlayerId)
    if inviter and inviter>0 then local ok=self:updateProgress(id,function(p)local out,why=O.setRecruiter(p.outgame,inviter,id);if not out then return nil,why end;p.outgame=out;return p end);self.analytics:flow(player,'social','invitedJoin',{result=ok and 'accepted'or 'skipped'})end
    if not Session.current(self,player,a,Players)then return end
    self:reportRecruit(player)
    if not Session.current(self,player,a,Players)then return end
    local ok,raw=pcall(function()return self.referrals:GetAsync(tostring(id))end)
    if not Session.current(self,player,a,Players)then return end
    if ok and type(raw)=='table'and type(raw.ids)=='table'then
        local list={};for _,v in ipairs(raw.ids)do if type(v)=='number'then table.insert(list,v)end end
        local added=0
        local saved=self:updateProgress(id,function(p)local out,n=O.claimRecruits(p.outgame,list);if not out then return nil,n end;added=n;p.outgame=out;return p end,'Gameplay','recruit')
        local a=self.accounts[player]
        if saved and added>0 and a then a.recruited={count=added,medals=added*O.career.recruitMedals,at=os.time()};self:publish(player,a);self.analytics:flow(player,'social','recruitCredit',{count=added,value=added*O.career.recruitMedals,result='granted'})end
    end
end
function S:checkGroup(player)
    local a=self.accounts[player];if not Session.current(self,player,a,Players)then return false end
    local ok,member=pcall(function()return player:IsInGroupAsync(Config.creatorGroupId)end)
    if not ok and Session.current(self,player,a,Players)then ok,member=pcall(function()return player:IsInGroup(Config.creatorGroupId)end)end
    if not ok or not Session.current(self,player,a,Players)then return false end
    self:updateProgress(player.UserId,function(p)local out,why=O.setGroup(p.outgame,member==true);if not out then return nil,why end;p.outgame=out;return p end)
    self.analytics:flow(player,'social','groupPerk',{result=member==true and 'active'or 'inactive'})
    return member==true
end
function S:reportRecruit(player)
    local a=self.accounts[player];if not Session.current(self,player,a,Players)then return end
    local r=a.profile.outgame.recruit
    if type(r)~='table'or not r.paid or r.reported or type(r.by)~='number'then return end
    local id=player.UserId
    local ok=pcall(function()self.referrals:UpdateAsync(tostring(r.by),function(cur)
        cur=type(cur)=='table'and type(cur.ids)=='table'and cur or {ids={}}
        if table.find(cur.ids,id)or #cur.ids>=50 then return cur end
        table.insert(cur.ids,id);return cur
    end)end)
    if ok then self:updateProgress(id,function(p)local q=p.outgame.recruit;if type(q)~='table'then return nil,'unchanged'end;q.reported=true;return p end)end
    self.analytics:flow(player,'social','recruitReported',{result=ok and 'ok'or 'failed'})
end
function S:snapshot(player)
    local a=self.accounts[player]
    if not a then return {loading=true,ready=false,localMode=self.localMode,owned={classic=true},products={}} end
    local products={}
    for id in pairs(Config.passes) do
        local passId=Policy.passId(Config,game.GameId,id,game.CreatorId,game.CreatorType.Name)
        products[id]={passId=passId or 0,forSale=false}
    end
    return {loading=a.loading,ready=a.ready,localMode=self.localMode,owned=table.clone(a.owned),products=products,checkIn=a.checkIn,recruited=a.recruited,
        collectionSeen=O.copy(a.profile.outgame.collectionSeen or {}),preferences=table.clone(a.profile.preferences),flag=a.profile.flag,commanderStandard=P.effectiveStandard(a.profile),cosmetics=P.effective(a.profile,a.owned),progress=O.view(a.profile.outgame,os.time()),billing=self.billing:snapshot(a),
        status=a.loading and "보관함을 불러오는 중" or not a.ready and "저장 연결 실패, 복원을 눌러주세요" or self.localMode and "Studio 테스트, 정지하면 보유와 설정이 초기화돼요" or a.unverified and "일부 보유권 확인 실패, 복원 필요" or "Roblox 보유권 확인, 설정 저장 연결됨"}
end
function S:sessionView(player,withProgress)
    local a=self.accounts[player];if not a then return {ready=false}end
    if a.cosmeticsProfile~=a.profile or a.cosmeticsOwned~=a.owned then
        a.cachedCosmetics=P.effective(a.profile,a.owned);a.cosmeticsProfile=a.profile;a.cosmeticsOwned=a.owned
    end
    return {ready=a.ready,cosmetics=a.cachedCosmetics,progress=withProgress and O.view(a.profile.outgame,os.time())or nil}
end
function S:publish(player,a)
    if player.Parent~=Players or a.departed then return end
    local snapshot=self:snapshot(player)
    local benefits=self.billing:benefits(a)
    player:SetAttribute('CommanderVIP',benefits.club)
    player:SetAttribute('CommanderPermanent',benefits.permanent)
    player:SetAttribute('CommanderVoiceTeam',((a.profile or {}).preferences or {}).voiceTeamOnly~=false)
    if a.profile then player:SetAttribute('ToyfrontLocale',(a.profile.preferences or {}).language)end
    player:SetAttribute('CommanderTrailStyle',snapshot.cosmetics and snapshot.cosmetics.commanderTrail or 'classic')
    player:SetAttribute('CommanderParachuteStyle',snapshot.cosmetics and snapshot.cosmetics.parachute or 'classic')
    player:SetAttribute('CommanderStandardStyle',snapshot.commanderStandard)
    local tier=0
    for slot,id in pairs(snapshot.cosmetics or {})do player:SetAttribute('CommanderCosmetic_'..slot,id);tier=math.max(tier,C.get(id).tier or 0)end
    player:SetAttribute('CommanderCosmeticTier',tier)
    local pr=snapshot.progress
    if pr then player:SetAttribute('CommanderLevel',pr.level);player:SetAttribute('CommanderTitle',pr.titleText or '');player:SetAttribute('CommanderTitleMap',pr.titleMap or '');player:SetAttribute('CommanderTitleFormat',pr.titleFormat or '');player:SetAttribute('CommanderTitleTier',pr.titleTier or 0)
        player:SetAttribute('CommanderPlate',pr.plate and Color3.fromRGB(pr.plate[1],pr.plate[2],pr.plate[3])or nil)end
    self.changed:FireClient(player,snapshot)
    self.onChanged(player,snapshot)
end
function S:equip(player,id,slot)
    local r=self:equipNow(player,id,slot)
    pcall(function()local T=require(script.Parent.TelemetryProgress);local c=type(id)=='string'and C.styles[id]and C.get(id)
        self.analytics:flow(player,'cosmetics','equip',{item=T.code(id),value=c and c.tier or nil,kind=nil,result=r.ok and 'accepted'or 'rejected',reason=r.ok and 'none'or require(pack.Core.TelemetrySchema).reason(r.message),count=type(slot)=='table'and #slot or slot and 1 or 0})end)
    return r
end
function S:equipNow(player,id,slot)
    local a=self.accounts[player]
    if not a or not a.ready then return {ok=false,message=messages["profile-not-loaded"]} end
    if self.closing or a.loading then return {ok=false,message=messages.busy} end
    if os.clock()-(a.lastEquip or -10)<.4 then return {ok=false,message=messages.busy} end
    a.lastEquip=os.clock()
    if player:GetAttribute('FrontierRoom') then return {ok=false,message='스킨은 로비에서 바꿀 수 있어요.'}end
    local list=type(slot)=='table'and slot or slot~=nil and {slot}or nil
    if list and (#list<1 or #list>4)then return {ok=false,message="스킨 항목이 올바르지 않아요."} end
    for _,s in ipairs(list or {})do if not C.validSlot(s)then return {ok=false,message="스킨 항목이 올바르지 않아요."} end end
    if type(id)~='string'or not C.styles[id]then return {ok=false,message="보유한 스킨만 장착할 수 있어요."} end
    for _,s in ipairs(list or {false})do if not O.owns(a.profile.outgame,a.owned,id,s or nil)then return {ok=false,message="보유한 스킨만 장착할 수 있어요."} end end
    local changes=list and {} or C.loadout(id);for _,s in ipairs(list or {})do changes[s]=id end
    local profile,err=self.repo:save(tostring(player.UserId),{loadout=changes})
    if not profile then return {ok=false,message=messages[err] or "저장 형식을 확인하지 못했어요. 바뀐 건 없어요."} end
    a.profile=profile;self:publish(player,a)
    self.analytics:emit(player,'cosmetic_equipped',{result='ok',stage='accepted'})
    return {ok=true,id=id,cosmetics=P.effective(profile,a.owned),account=self:snapshot(player)}
end
function S:updateProgress(id,fn,transaction,sku)
    local observedAt=os.clock()
    local key=tostring(id)
    local before=self.repo.loaded[key]and self.repo.loaded[key].outgame
    local beforeCommerce
    if not self.repo.loaded[key]then local p=self.repo:load(key);if not p then return nil,'storage-unavailable'end end
    local profile,err=self.repo:mutate(key,function(p)
        before=O.copy(p.outgame)
        beforeCommerce=require(script.Parent.TelemetryProgress).wallet(p.commerce)
        local out,why=fn(p);if not out then return nil,why end;return out
    end)
    local player=Players:GetPlayerByUserId(id);local a=player and self.accounts[player]
    self.analytics:service(player,'profile_mutate',profile~=nil,observedAt)
    if profile and player and before then
        local after=profile.outgame
        if after.medals~=before.medals then self.analytics:economy(player,after.medals-before.medals,after.medals,transaction or 'Gameplay',sku or 'match')end
        local l0,l1=O.level(before.xp),O.level(after.xp)
        if l1>l0 then local _,name=O.rank(l1);self.analytics:progression(player,l1,name)end
        if l1>l0 then for _,item in ipairs(require(pack.Core.CommanderStandardRules).items)do if item.level>l0 and item.level<=l1 then self.analytics:emit(player,'unlock_granted',{kind='other',level=item.level,result='granted'},{context={unlock_id=item.id,unlock_kind='flag'}})end end end
        if after.xp>before.xp then
            local paid=0;for key,r in pairs(after.receipts)do paid+=math.max(0,(r.paidXP or 0)-(before.receipts[key]and before.receipts[key].paidXP or 0))end
            self.analytics:emit(player,'xp_awarded',{xp=after.xp-before.xp,base_xp=math.max(0,after.xp-before.xp-paid),paid_xp=paid,result='granted',sku=sku})
            if paid>0 then self.analytics:emit(player,'benefit_used',{benefit='xp',amount=paid,result='granted',multiplier=a and self.billing:benefits(a).xpMultiplier or nil})end
        end
        if sku=='match'and after.xp>before.xp and self.clans then
            local paid=0
            for key,r in pairs(after.receipts)do paid+=math.max(0,(r.paidXP or 0)-(before.receipts[key]and before.receipts[key].paidXP or 0))end
            self.clans:credit(id,math.max(0,after.xp-before.xp-paid),os.time())
        end
    end
    if profile and player and before then require(script.Parent.TelemetryProgress).safe(require(script.Parent.TelemetryProgress).outgame,self.analytics,player,before,profile.outgame,sku)end
    if profile and player and beforeCommerce then require(script.Parent.TelemetryProgress).safe(require(script.Parent.TelemetryProgress).commerce,self.analytics,player,beforeCommerce,profile.commerce,transaction,sku)end
    if profile and a then a.profile=profile;self:publish(player,a)end
    if not player then self.repo:forget(key,false)end
    return profile,err
end
function S:applyProgress(id,event,unpaid)
    local observedAt=os.clock()
    local boost=self.live.xpBoost()
    if boost>1 and type(event)=='table'then event=table.clone(event);event.boost=boost end
    local saved,err=self:updateProgress(id,function(p)
        if Retention.sealed(p.outgame,event)then return p end
        local out,err=O.apply(p.outgame,event);if not out then return nil,err end
        out=Benefits.apply(out,p.outgame,event)
        p.outgame=ResultPresentation.tally(out,p.outgame,event);Retention.compact(p.outgame,event);Retention.prune(p.outgame,os.time(),unpaid);return p
    end,'Gameplay','match')
    local actor=Players:GetPlayerByUserId(id)
    self.analytics:emit(actor,'reward_commit_result',{operation='profile_mutate',result=saved and 'ok'or 'failed',reason=saved and 'none'or require(pack.Core.TelemetrySchema).reason(err),duration_ms=(os.clock()-observedAt)*1000},
        {id='reward:'..self.analytics.key(tostring(id)..':'..tostring(event and event.id)..':'..tostring(event and event.revision))..':'..(saved and 'ok'or 'failed'),context={actor_key=self.analytics.actorKey(id)}})
    if saved and type(event)=='table'and type(event.daily)=='number'and Daily.score(event)then
        local player=Players:GetPlayerByUserId(id);if player then self.analytics:custom(player,'DailyOpCleared',event.map,event.outcome,1)end
    end
    local season=saved and type(saved.outgame.season)=='table'and saved.outgame.season
    if season and type(season.xp)=='number'and type(season.id)=='number'then task.spawn(function()pcall(self.seasonBoard.note,self.seasonBoard,id,season.id,season.xp)end)end
    local r=saved and saved.outgame.recruit
    if type(r)=='table'and r.paid and not r.reported then local player=Players:GetPlayerByUserId(id);if player then task.spawn(function()self:reportRecruit(player)end)end end
    return saved,err
end
function S:saveSingle(player,map,settings)
    return self:updateProgress(player.UserId,function(p)p.outgame.single={map=map,settings=O.copy(settings)};return p end)
end
function S:requestAction(player,action,value,extra)
    local valid,own=require(pack.Core.AccountRequestRules).lane(action,value)
    if not valid then return {ok=false}end
    local a=self.accounts[player]
    if action=="read" then
        if a then
            a.readBudget=a.readBudget or {}
            if not Guards.take(a.readBudget,'account',os.clock(),Guards.readBurst,Guards.readRate)then return {ok=false,busy=true}end
        end
        return {ok=true,account=self:snapshot(player)}
    end
    if action=="profile" then
        if not a then return {ok=false}end
        a.readBudget=a.readBudget or {}
        if not Guards.take(a.readBudget,'profile',os.clock(),3,1)then return {ok=false,busy=true,message="잠시 뒤 다시 시도하세요."}end
        local target=type(value)=='number'and Players:GetPlayerByUserId(value)or nil
        local t=target and self.accounts[target]
        if not(t and t.ready and t.profile)then return {ok=false,message="지금은 이 지휘관의 전적을 볼 수 없어요."}end
        local ladders=nil;if self.rankedOf then local ok,v=pcall(self.rankedOf,value);ladders=ok and v or nil end
        return {ok=true,profile=require(pack.Core.PublicProfile).build(value,O.view(t.profile.outgame,os.time()),ladders)}
    end
    if action=="dailyBoard" then
        if os.clock()-((a and a.lastBoard)or -10)<3 then return {ok=false,message="잠시 뒤 다시 시도하세요."}end
        if a then a.lastBoard=os.clock()end
        local board=self.dailyBoard:board(player.UserId,os.time());board.op=Daily.of(board.day);board.ok=true;return board
    end
    if action=="seasonBoard" then
        if os.clock()-((a and a.lastSeasonBoard)or -10)<3 then return {ok=false,message="잠시 뒤 다시 시도하세요."}end
        if a then a.lastSeasonBoard=os.clock()end
        local s=require(pack.Core.SeasonRules).at(os.time());if not s then return {ok=false}end
        local cur=a and a.profile and type(a.profile.outgame.season)=='table'and a.profile.outgame.season.id==s.id and a.profile.outgame.season
        local board=self.seasonBoard:board(player.UserId,s.id,cur and cur.xp or 0);board.ok=true;board.name=s.name;return board
    end
    if not a or a.loading or self.closing or self.repo.busy[tostring(player.UserId)] then return {ok=false,message=messages.busy} end
    if own then
        a.limits=a.limits or {};if os.clock()-(a.limits[own]or -10)<.3 then return {ok=false,message="잠시 뒤 다시 시도하세요."}end;a.limits[own]=os.clock()
    else
        if os.clock()-(a.lastRequest or -10)<.6 then return {ok=false,message="잠시 뒤 다시 시도하세요."} end
        a.lastRequest=os.clock()
    end
    if table.find({'billingPurchase','supplyDraw','equipSupply','savePreset','supplyTestGrant'},action)then return self.billing:request(player,a,action,value)end
    if action=='ackVoided'then
        if not a.ready then return {ok=false}end
        local result=self:updateProgress(player.UserId,function(p)
            local v=p.outgame.voided;if type(v)~='table'or (value~=nil and v.id~=value)then return nil,'invalid-request'end
            p.outgame.voided=nil;return p
        end)
        if result then pcall(function()self.analytics:flow(player,'match','voidNotice',{result='shown'})end)end
        return {ok=result~=nil,account=self:snapshot(player)}
    end
    if action=='viewCollection'then
        if not a.ready then return {ok=false,message=messages['profile-not-loaded']}end
        local Inbox=require(pack.Core.CollectionInbox)
        local inventory=Inbox.inventory(self:snapshot(player))
        local result,err=self:updateProgress(player.UserId,function(p)
            local category=type(value)=='table'and value.category or value
            local seen=Inbox.ack(p.outgame.collectionSeen,inventory,category,type(value)=='table'and value.keys or nil);if not seen then return nil,'invalid-request'end
            p.outgame.collectionSeen=seen;return p
        end)
        return {ok=result~=nil,account=self:snapshot(player),message=err and (messages[err]or '변경하지 못했어요. 다시 시도하세요.')or nil}
    end
    if action=='claimGoal'then
        if not a.ready then return {ok=false,message=messages['profile-not-loaded']}end
        if type(value)~='string'or #value>64 then return {ok=false,message='요청을 확인하세요.'}end
        local mult=self.billing:benefits(a).xpMultiplier or 1
        local profile,got,err=require(script.Parent.GoalClaimDelivery).claim(self,player.UserId,value,os.time(),mult)
        if profile and got then local left=0;for _ in pairs(profile.outgame.goalClaims or {})do left+=1 end;self.analytics:flow(player,'goals','goalClaim',{item=value=='all'and 'all'or 'one',count=got.count,value=got.medals,amount=got.xp,total=left,result='granted'})
            if (got.paidXP or 0)>0 then self.analytics:emit(player,'benefit_used',{benefit='xp',amount=got.paidXP,result='granted',multiplier=mult})end
        elseif err~='unchanged'then pcall(function()self.analytics:flow(player,'goals','goalClaim',{item=value=='all'and 'all'or 'one',result='failed',reason=require(pack.Core.TelemetrySchema).reason(err)})end)end
        return {ok=profile~=nil,account=self:snapshot(player),claimed=got and {xp=got.xp+(got.paidXP or 0),medals=got.medals,count=got.count,bonusXP=got.paidXP}or nil,
            message=err and err~='unchanged'and (messages[err]or '받지 못했어요. 다시 시도하세요.')or nil}
    end
    if action=='exchange'or action=='saveLoadout'or action=='useLoadout'or action=='tutorial'or action=='mode'or action=='career'or action=='group' then
        if action=='exchange'then for _,item in ipairs(O.shop)do if item.id==value and item.style then return {ok=false,message='스킨은 보급 상자에서 획득할 수 있어요.'}end end end
        if action=='tutorial'and player:GetAttribute('FrontierUnrecorded')then return {ok=true,temporary=true}end
        if not a.ready then return {ok=false,message=messages['profile-not-loaded']}end
        if player:GetAttribute('FrontierRoom')and action~='tutorial'and action~='career'and action~='group'then return {ok=false,message='로비에서 사용할 수 있어요.'}end
        if action=='group'then
            if os.clock()-(a.lastGroup or -30)<15 then return {ok=false,message='잠시 뒤 다시 확인하세요.'}end
            a.lastGroup=os.clock();local member=self:checkGroup(player)
            return {ok=member,account=self:snapshot(player),message=not member and '그룹 가입이 아직 확인되지 않았어요.'or nil}
        end
        local profile,err=self:updateProgress(player.UserId,function(p)
            local o=p.outgame
            if action=='exchange'then
                local result,why=O.exchange(o,value);if not result then return nil,why end;p.outgame=result
            elseif action=='career'then
                local result,why=O.equip(o,value,extra);if not result then return nil,why end;p.outgame=result
            elseif action=='tutorial'and type(value)=='boolean'then o.tutorial=value
            elseif action=='mode'and table.find({'single','pvp','coop'},value)then o.lastMode=value
            elseif (action=='saveLoadout'or action=='useLoadout')and type(value)=='number'and value%1==0 and value>=1 and value<=self.billing:benefits(a).loadoutSlots then
                if action=='saveLoadout'then o.loadouts[tostring(value)]=table.clone(p.loadout);o.loadouts[tostring(value)].commanderStandard=P.effectiveStandard(p)
                else
                    local saved=o.loadouts[tostring(value)]
                    if saved then
                        for slot,style in pairs(saved)do if C.validSlot(slot)and C.styles[style]and O.owns(o,a.owned,style,slot)then p.loadout[slot]=style end end
                        if saved.commanderStandard then p.commanderStandard=require(pack.Core.CommanderStandardRules).effective(saved.commanderStandard,O.level(o.xp),type(p.commerce)=='table'and p.commerce.owned or nil)end
                    end
                    o.activeLoadout=value;P.syncPreset(p)
                end
            else return nil,'invalid-request'end;return p
        end,action=='exchange'and 'Shop'or nil,action=='exchange'and 'exchange'or nil)
        if action=='exchange'or action=='career'then self.analytics:flow(player,action=='exchange'and 'shop'or 'progression',action=='exchange'and 'coinShop'or 'careerEquip',{item=require(script.Parent.TelemetryProgress).code(action=='career'and extra or value),result=profile and 'accepted'or 'rejected',reason=profile and 'none'or require(pack.Core.TelemetrySchema).reason(err)})end
        if action=='saveLoadout'or action=='useLoadout'then
            self.analytics:emit(player,'preset_action',{stage=action=='saveLoadout'and 'save'or 'load',result=profile and 'ok'or 'failed'});self.analytics:flow(player,'cosmetics',action=='saveLoadout'and 'presetSave'or 'presetUse',{value=value,result=profile and 'ok'or 'failed',reason=profile and 'none'or require(pack.Core.TelemetrySchema).reason(err)})
            if profile and value>2 then self.analytics:emit(player,'benefit_used',{benefit='loadout_slots',sku='permanent',result='ok'})end
        end
        return {ok=profile~=nil,account=self:snapshot(player),message=err and ({['insufficient-medals']='코인이 조금 더 필요해요.',['locked-reward']='아직 열리지 않은 보상이에요.',['empty-loadout']='현재 스킨을 먼저 저장하세요.'})[err]or err and messages[err]or err and '변경하지 못했어요. 다시 시도하세요.'or nil}
    elseif action=="restore" then
        if os.clock()-(a.lastRestore or -30)<10 then return {ok=false,message="보유권을 방금 확인했어요. 잠시 뒤 다시 복원하세요."} end
        a.lastRestore=os.clock()
        self:load(player);local snapshot=self:snapshot(player);return {ok=snapshot.ready==true,account=snapshot,message=not snapshot.ready and messages['storage-unavailable']or nil}
    elseif action=="purchase" then
        return {ok=false,message='스킨은 보급 상자에서 획득할 수 있어요.'}
    elseif action=="testUnlock" then
        if not Run:IsStudio() or not self.localMode or not a.ready or type(value)~="string" or not Config.passes[value] then return {ok=false,message="Studio 테스트에서만 사용할 수 있어요."} end
        self.testOwned[player.UserId]=self.testOwned[player.UserId] or {};self.testOwned[player.UserId][value]=true
        self:refreshOwnership(player,a);self:publish(player,a)
        return {ok=true,account=self:snapshot(player),message="테스트 보유권 지급, Robux 사용 없음"}
    elseif action=='devCheat'then
        local dev=script.Parent:FindFirstChild('DevCheats');if not dev then return {ok=false,message='Studio 테스트에서만 사용할 수 있어요.'}end
        return require(dev).run(self,player,a,value)
    elseif action=='standardTestLevel'then
        local target=require(pack.Core.CommanderStandardRules).testLevel(Run:IsStudio(),self.localMode)
        if not target or not a.ready or player:GetAttribute('FrontierRoom')then return {ok=false,message='Studio 테스트에서만 사용할 수 있어요.'}end
        local profile,err=self:updateProgress(player.UserId,function(p)
            local xp=0;for level=1,target-1 do xp+=O.levelCost(level)end
            p.outgame.xp=math.max(p.outgame.xp,xp);return p
        end)
        return {ok=profile~=nil,account=self:snapshot(player),message=profile and 'Studio 테스트 레벨 100, 정지 시 초기화'or messages[err]}
    elseif action=='commanderStandard'then
        if not a.ready then return {ok=false,message=messages['profile-not-loaded']}end
        if player:GetAttribute('FrontierRoom')then return {ok=false,message='스킨은 로비에서 바꿀 수 있어요.'}end
        local Flags=require(pack.Core.CommanderStandardRules);local c=a.profile.commerce
        if type(value)~='string'or not Flags.owns(value,O.level(a.profile.outgame.xp),type(c)=='table'and c.owned or nil)then
            local f=type(value)=='string'and Flags.find(value);return {ok=false,message=f and f.supply and '보급 상자에서 얻으면 장착할 수 있어요.'or '해금 레벨에 도달하면 장착할 수 있어요.'}end
        local profile,err=self.repo:save(tostring(player.UserId),{commanderStandard=value})
        if not profile then return {ok=false,message=messages[err]or '깃발을 저장하지 못했어요.'}end
        a.profile=profile;self:publish(player,a);self.analytics:flow(player,'cosmetics','standardEquip',{item=require(script.Parent.TelemetryProgress).code(value),result='accepted'});return {ok=true,account=self:snapshot(player)}
    elseif action=="flag" then
        if not a.ready or not (value==false or type(value)=="string") then return {ok=false,message="국기를 저장할 수 없어요."} end
        if player:GetAttribute('FrontierRoom')then return {ok=false,message='스킨은 로비에서 바꿀 수 있어요.'}end
        local profile,err=self.repo:save(tostring(player.UserId),{flag=value})
        if not profile then return {ok=false,message=messages[err] or "국기를 저장하지 못했어요."} end
        a.profile=profile;self:publish(player,a);return {ok=true,account=self:snapshot(player)}
    elseif action=="preference" then
        if not a.ready or (value~="reducedEffects" and value~="soundsMuted" and value~="cameraShake"and value~='mapFlashes'and value~='voiceTeamOnly'and value~="sfxVolume"and value~='emojiFavorites'and value~='motionLoadout'and value~='hudOpacity'and value~='language') or type(extra)~=((value=='emojiFavorites'or value=='motionLoadout')and 'table'or (value=="sfxVolume"or value=='hudOpacity')and "number"or value=='language'and 'string'or "boolean") then pcall(function()self.analytics:flow(player,'settings','preference',{item='invalid',result='rejected',reason=a.ready and 'invalid'or 'not_loaded'})end);return {ok=false,message="설정을 저장할 수 없어요."} end
        local profile,err=self.repo:save(tostring(player.UserId),{preferences=value=='sfxVolume'and {sfxVolume=extra,soundsMuted=false}or {[value]=extra}})
        self.analytics:flow(player,'settings','preference',{item=value,active=type(extra)=='boolean'and extra or nil,value=type(extra)=='number'and extra or nil,result=profile and 'ok'or 'failed'})
        if not profile then return {ok=false,message=messages[err] or "설정을 저장하지 못했어요."} end
        a.profile=profile;self:publish(player,a);return {ok=true,account=self:snapshot(player)}
    end
    return {ok=false,message="지원하지 않는 요청이에요."}
end
return S
