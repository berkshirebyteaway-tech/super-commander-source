local Flight=if script then require(script.Parent.ReadFlight)else require('./ReadFlight')
local U=if script then require(game.ReplicatedStorage.FrontierNative.Core.ClanRules)else require('../core/ClanRules')
local W=if script then require(game.ReplicatedStorage.FrontierNative.Core.ClanWarRules)else require('../core/ClanWarRules')
local Guards=if script then require(game.ReplicatedStorage.FrontierNative.Core.AbuseGuards)else require('../core/AbuseGuards')
local WarDelivery=if script then require(script.Parent.ClanWarDelivery)else require('./ClanWarDelivery')
local Membership=if script then require(script.Parent.ClanMembership)else require('./ClanMembership')
local Fresh=if script then require(script.Parent.FreshStore)else require('./FreshStore')
local Archive=if script then require(script.Parent.ReceiptArchive)else require('./ReceiptArchive')
local S={};S.__index=S
local Decision=if script then Enum.ProductPurchaseDecision else {PurchaseGranted='granted',NotProcessedYet='retry'}
local messages={
    ['invalid-name']='클랜 이름은 2~16자의 글자나 숫자로 정해 주세요.',['invalid-tag']='약칭은 2~4자의 글자나 숫자로 정해 주세요.',
    ['filtered']='쓸 수 없는 이름이에요. 다른 이름을 써 주세요.',['unit-full']='클랜이 가득 찼어요(100명).',['unit-missing']='클랜을 찾지 못했어요. 코드를 확인하세요.',
    ['already-member']='이미 클랜에 있어요. 먼저 클랜을 나가세요.',['prime']='클랜은 커맨더 프라임 보유자만 만들고 가입할 수 있어요.',['not-leader']='클랜장만 할 수 있어요.',
    ['storage-unavailable']='저장에 연결하지 못했어요. 잠시 뒤 다시 시도하세요.',['busy']='잠시 뒤 다시 시도하세요.',['invalid-request']='요청을 확인하세요.',['paused']='클랜 기능을 잠시 점검 중이에요. 조금 뒤 다시 시도하세요.',
    ['not-member']='클랜에 가입하면 출석할 수 있어요.',['attended']='오늘 출석은 이미 했어요.',['free-first']='오늘 무료 출석을 먼저 해 주세요.',['extra-done']='오늘 추가 출석을 모두 했어요.',
    ['sale-closed']='추가 출석은 판매 준비 중이에요.',['war-size']='클랜전은 같은 클랜 2~5명이 파티로 들어가요.',['war-clan']='클랜전 파티는 같은 클랜원끼리만 들어갈 수 있어요.',
}
messages['banned']='이 클랜에서 내보내져 7일 동안 다시 가입할 수 없어요.'
local function memoryStore(mem)
    return {GetAsync=function(_,k)return mem[k]end,SetAsync=function(_,k,v)mem[k]=v end,RemoveAsync=function(_,k)mem[k]=nil end,
        UpdateAsync=function(_,k,fn)local v=fn(mem[k]);if v~=nil then mem[k]=v end;return v end,
        IncrementAsync=function(_,k,d)mem[k]=(mem[k]or 0)+d;return mem[k]end,
        GetSortedAsync=function(_,_,size)local list={};for k,v in pairs(mem)do table.insert(list,{key=k,value=v})end;table.sort(list,function(a,b)return a.value>b.value or a.value==b.value and a.key<b.key end)
            return {GetCurrentPage=function()return {table.unpack(list,1,math.min(#list,size or 10))}end}end}
end
local function adapter()
    local players=game:GetService('Players');local text=game:GetService('TextService')
    local studio=game:GetService('RunService'):IsStudio();local localMode=studio or game.GameId==0
    local ds=not localMode and game:GetService('DataStoreService')or nil
    local budget=ds and require(script.Parent.ArchiveBudget).new({clock=os.clock,wait=task.wait,budget=function()
        return math.min(ds:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.StandardRead),ds:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.StandardWrite))
    end})
    return {archivePermit=budget and function()return budget:acquire()end or nil,players=players,localMode=localMode,studio=studio,clock=os.clock,time=os.time,spawn=task.spawn,wait=task.wait,
        store=ds and ds:GetDataStore('SuperCommanderClans_v1')or nil,
        xpBoard=ds and ds:GetOrderedDataStore('SuperCommanderClanXP_v1')or nil,
        warBoard=ds and function(season)return ds:GetOrderedDataStore('SuperCommanderClanWar_v1',season)end or nil,
        userInfos=function(ids)return game:GetService('UserService'):GetUserInfosByUserIdsAsync(ids)end,
        filter=function(value,userId)return text:FilterStringAsync(value,userId,Enum.TextFilterContext.PublicChat):GetNonChatStringForBroadcastAsync()end,
        identity=function()local rng=Random.new();return game.HttpService:GenerateGUID(false):gsub('-',''):sub(1,16),function(n)return rng:NextInteger(1,n)end end,
        bind=function(self)
            local remote=Instance.new('RemoteFunction');remote.Name='ClanRequest';remote.Parent=game.ReplicatedStorage.FrontierNative
            remote.OnServerInvoke=function(player,action,a,b,c)return self:request(player,action,a,b,c)end
            players.PlayerAdded:Connect(function(p)self.a.spawn(function()self:load(p)end)end)
            players.PlayerRemoving:Connect(function(p)self:leaving(p)end)
            for _,p in ipairs(players:GetPlayers())do self.a.spawn(function()self:load(p)end)end
            task.spawn(function()while not self.closing do task.wait(12);self.warDelivery:retry();self.warArchive:retry();self.personalWarArchive:retry()end end)
            game:BindToClose(function()
                self.closing=true;local finish=os.clock()+25
                repeat self.warDelivery:flush();task.wait(.5)until not next(self.warDelivery.worker.pending)or os.clock()>=finish
            end)
        end}
end
function S.new(accounts,dependencies)
    local a=dependencies or adapter()
    local self=setmetatable({a=a,accounts=accounts,byUser={},units={},last={},boards={},wars={},loaded={},loading={},working={},viewing={},checked={},names={},nameAt={},lastRead={},joinFails={},ledgers={},localMode=a.localMode},S)
    self.memory={};self.store=a.store or memoryStore(self.memory)
    self.xpBoard=a.xpBoard or memoryStore({})
    self.warArchive=Archive.new(self.store,'warAwards',a.spawn,a.archivePermit);self.personalWarArchive=Archive.new(self.store,'warKeys',a.spawn,a.archivePermit)
    self.warDelivery=WarDelivery.new(self);self.membership=Membership.new(self)
    if a.bind then a.bind(self)end
    return self
end
function S:leaving(player)
    local uid=player.UserId
    self.warDelivery.worker:stopRecovering(uid)
    if self.viewCache then self.viewCache[uid]=nil end
    if self.viewRevision then self.viewRevision[uid]=self.viewFlights and self.viewFlights[uid]and (self.viewRevision[uid]or 0)+1 or nil end
    self.byUser[uid]=nil;self.last[uid]=nil;self.lastRead[uid]=nil;self.loaded[uid]=nil;self.checked[uid]=nil;self.joinFails[uid]=nil;self.ledgers[uid]=nil
end
function S:warStore(season)
    if not self.a.warBoard then self.wars[season]=self.wars[season]or memoryStore({});return self.wars[season]end
    return self.a.warBoard(season)
end
function S:call(fn)for attempt=1,3 do local ok,v=pcall(fn);if ok then return true,v end;if attempt<3 then self.a.wait(attempt)end end;return false end
function S:prime(player)
    local acc=self.accounts;if not acc then return false end
    if acc.prime then return acc.prime(player)==true end
    local a=acc.accounts and acc.accounts[player]
    return a~=nil and acc.billing~=nil and acc.billing:benefits(a).permanent==true
end
function S:fetch(id)
    local ok,u=self:call(function()return self.store:GetAsync('u:'..id)end)
    if ok and type(u)=='table'and not u.disbanded then self.units[id]={unit=u,at=self.a.clock()};return u end
    if ok then self.units[id]={unit=false,at=self.a.clock()};return false end
    return nil
end
function S:load(player)
    local uid=player.UserId;if self.loading[uid]or self.working[uid]then return end
    local token={};self.loading[uid]=token
    local success=pcall(function()
        local ok,id,u=self.membership:current(uid,false);if not ok then return end
        if self.a.players:GetPlayerByUserId(uid)~=player then return end
        self.byUser[uid]=u and u.members[tostring(uid)]and id or nil
        self:publish(player,self.byUser[uid]and u or nil)
        self.loaded[uid]=true;self.checked[uid]=self.a.clock()
    end)
    if self.loading[uid]==token then self.loading[uid]=nil end
    if not success then return end
    if self.loaded[uid]then self.warDelivery:recover(uid)end
    if self.loaded[uid]and not self.working[uid]then
        self.working[uid]=true;pcall(self.finish,self,uid,self.a.time());self.working[uid]=nil
    end
end
function S:publish(player,u)
    if player.Parent~=self.a.players then return end
    player:SetAttribute('CommanderClan',u and u.tag or nil)
    player:SetAttribute('CommanderClanColor',u and U.validColor(u.color)or nil)
end
function S:member(player,id,u)
    if self.a.players:GetPlayerByUserId(player.UserId)~=player then return end
    self.byUser[player.UserId]=id;self:publish(player,u)
end
function S:filter(text,userId)
    local ok,out=pcall(self.a.filter,text,userId)
    if not ok then if self.localMode then return text end;return nil,'storage-unavailable'end
    if out~=text or out:find('#',1,true)then return nil,'filtered'end
    return out
end
function S:credit()end
function S:ledger(uid,now)
    local ok,l=self:call(function()return self.store:GetAsync('a:'..uid)end)
    if not ok then return self.ledgers[uid]and U.ledger(self.ledgers[uid],now)or nil end
    l=U.ledger(l,now);self:rememberLedger(uid,l);return U.ledger(self.ledgers[uid],now)
end
function S:rememberLedger(uid,l)
    local cached=self.ledgers[uid]
    if not cached or (tonumber(l.storageRevision)or 0)>=(tonumber(cached.storageRevision)or 0)then self.ledgers[uid]=l end
end
function S:invalidateView(uid)
    if self.viewCache then self.viewCache[uid]=nil end
    if self.viewFlights and self.viewFlights[uid]then self.viewRevision=self.viewRevision or {};self.viewRevision[uid]=(self.viewRevision[uid]or 0)+1 end
end
function S:updateLedger(uid,fn)
    local ok,l=self:call(function()return self.store:UpdateAsync('a:'..uid,function(old)
        local revision=type(old)=='table'and tonumber(old.storageRevision)or 0
        local out=fn(old);if out then out.storageRevision=(revision or 0)+1 end;return out
    end)end)
    if ok and l then self:rememberLedger(uid,l);self:invalidateView(uid)end
    return ok,l
end
function S:board(id,xp)
    if type(id)~='string'or not xp then return end
    self.boards.xp=nil
    self.a.spawn(function()self:call(function()return self.xpBoard:UpdateAsync(id,function(old)return math.max(tonumber(old)or 0,math.floor(xp))end)end)end)
end
function S:finish(uid,now)
    local ok0,l=self:call(function()return self.store:GetAsync('a:'..uid)end);if not ok0 then return false end
    if type(l)~='table'or type(l.pending)~='table'then return true end
    local p=l.pending;local why
    local ok,u=self:call(function()return self.store:UpdateAsync('u:'..p.clan,function(old)local out,err=U.creditStored(old,uid,p.seq,p.amount,tonumber(p.day)and p.day*86400 or now,p.clan);why=err;return out end)end)
    if not ok then return false end
    if u and not why then
        self.units[p.clan]={unit=not u.disbanded and u or false,at=self.a.clock()}
        if not u.disbanded then self:board(p.clan,u.xp)end
        local saved,later=self:updateLedger(uid,function(old)return U.settle(U.ledger(old,now),p.seq)end)
        if not saved or not later then return false end
        return true,p
    end
    local saved,later=self:updateLedger(uid,function(old)return U.refund(U.ledger(old,now),p.seq)end)
    if not saved or not later then return false end
    return false,why
end
function S:rows(page,value)
    local rows={};local rank,prev,shown=0,nil,0
    for _,entry in ipairs(page)do
        local cached=self.units[entry.key];local u
        if cached and self.a.clock()-cached.at<300 then u=cached.unit else u=self:fetch(entry.key)end
        if u then
            shown+=1;if entry.value~=prev then rank=shown;prev=entry.value end
            local w=value=='war'and type(u.war)=='table'and u.war or nil
            table.insert(rows,{rank=rank,id=entry.key,name=u.name,tag=u.tag,color=U.validColor(u.color)or 1,level=(U.level(u.xp)),count=u.count,value=entry.value,
                wins=w and w.wins or nil,losses=w and w.losses or nil})
        end
    end
    return rows
end
function S:readBoard(key,storeFn,value)
    local c=self.boards[key]
    if c and (self.a.clock()-c.at<90 or c.retryAt and self.a.clock()<c.retryAt)then return c.rows,c.failed and 'failed'or 'ok'end
    self.boardFlights=self.boardFlights or {}
    if self.boardFlights[key]and c and not c.failed then return c.rows,'ok'end
    local success,rows=Flight.run(self.boardFlights,key,self.a.readWait,function()
        local ok,page=self:call(function()return storeFn():GetSortedAsync(false,50):GetCurrentPage()end)
        if not ok then error('Clan board unavailable')end
        local result=self:rows(page,value)
        self.boards[key]={at=self.a.clock(),rows=result};return result
    end)
    if success then return rows,'ok'end
    local fallback=c or {at=-math.huge,rows={},failed=true};fallback.retryAt=self.a.clock()+5;self.boards[key]=fallback
    return fallback.rows,fallback.failed and 'failed'or 'ok'
end
function S:topXp()return self:readBoard('xp',function()return self.xpBoard end,'xp')end
function S:topWar(now)local season=W.season(now);local rows,state=self:readBoard('war:'..season,function()return self:warStore(season)end,'war');return rows,season,state end
function S:rankedBoard(player)
    local season=W.season(self.a.time());local c=self.boards['war:'..season]
    self.boardRefresh=self.boardRefresh or {};local key='war:'..season
    if (not c or self.a.clock()-c.at>=90)and not(c and c.retryAt and self.a.clock()<c.retryAt)and not self.boardRefresh[key]and not(self.boardFlights and self.boardFlights[key])then
        self.boardRefresh[key]=true
        self.a.spawn(function()pcall(function()self:topWar(self.a.time())end);self.boardRefresh[key]=nil end)
    end
    local top=c and c.rows or {};local mine=player and self.byUser[player.UserId]
    local rows={}
    for _,r in ipairs(top)do
        table.insert(rows,{rank=r.rank,name=string.format('[%s] %s',r.tag or '',r.name or ''),sub=string.format('Lv %d  %d-%d',r.level or 1,r.wins or 0,r.losses or 0),
            value=r.value,valueLabel=tostring(r.value)..'점',self=mine~=nil and tostring(r.id)==tostring(mine)})
    end
    return {season=season,board=rows,loading=c==nil,unavailable=c and c.failed==true or nil}
end
function S:product()
    local Config=self.a.commerce
    if Config==nil and script then local ok,v=pcall(require,script.Parent.CommerceConfig);Config=ok and v or false;self.a.commerce=Config end
    local entry=Config and Config.clanProducts and Config.clanProducts.attend
    local id=entry and entry.id or 0
    local valid=Config and not self.localMode and Config.purchasesEnabled==true and (not script or require(script.Parent.LiveConfig).salesOpen())and game.GameId==Config.universeId and id>0
    if valid and script and self.price==nil then
        self.price=false
        self.a.spawn(function()local ok,info=pcall(function()return game:GetService('MarketplaceService'):GetProductInfo(id,Enum.InfoType.Product)end)
            if ok and type(info)=='table'and tonumber(info.PriceInRobux)then self.price=tonumber(info.PriceInRobux)else self.price=nil end end)
    end
    return {id=id,available=valid==true,price=self.price or (entry and entry.suggestedRobux)or nil,studio=self.localMode==true and self.a.studio==true}
end
function S:view(player)
    local uid=player.UserId;local now=self.a.time()
    if not self.loaded[uid]then
        if not self.loading[uid]then self.a.spawn(function()self:load(player)end)end
        return {ok=false,reason='busy',message='클랜 정보를 불러오는 중이에요. 잠시 뒤 다시 불러오세요.'}
    end
    local id=self.byUser[uid];local cached=id and self.units[id]
    local u=id and (cached and self.a.clock()-cached.at<Guards.unitViewSeconds and cached.unit or self:fetch(id))
    local warTop,season,warState=self:topWar(now)
    local top,topState=self:topXp()
    local ledger=self.ledgers[uid]and U.ledger(self.ledgers[uid],now)or self:ledger(uid,now)or U.ledger(nil,now)
    local out={ok=true,maxMembers=U.maxMembers,prime=self:prime(player),top=top,topState=topState,warState=warState,
        attend={free=ledger.free==true,extra=ledger.extra,extraMax=U.extraPerDay,tokens=ledger.tokens,amount=U.attendAmount,total=ledger.total,warTotal=ledger.warTotal or 0},
        war={season=season,n=W.at(now).n,remaining=W.remaining(now),top=warTop,winPoints=W.winPoints,lossPoints=W.lossPoints,winContribution=W.winContribution,lossContribution=W.lossContribution},
        product=self:product(),studio=self.a.studio==true and self.localMode==true}
    if id and (u==false or u and not u.members[tostring(uid)])then
        if self.byUser[uid]==id then self:member(player,nil,nil)end;u=nil
    end
    if u and u.members[tostring(uid)]then
        local members={};local week=U.week(now);local today=U.day(now);local lookups=0
        local missing={}
        for key in pairs(u.members)do local n=tonumber(key);local nm=self.names[n]
            if n and not self.a.players:GetPlayerByUserId(n)and (nm==nil or nm==false and self.a.clock()-(self.nameAt[n]or 0)>60)then table.insert(missing,n)end end
        if #missing>0 and self.a.userInfos then
            for _,n in ipairs(missing)do self.names[n]=false;self.nameAt[n]=self.a.clock()end
            local ok,infos=pcall(self.a.userInfos,missing)
            if ok and type(infos)=='table'then for _,info in ipairs(infos)do local n=tonumber(info.Id)
                if n then self.names[n]=(type(info.DisplayName)=='string'and info.DisplayName~=''and info.DisplayName)or info.Username or false end end end
        end
        for key,at in pairs(u.members)do
            local n=tonumber(key);local p=self.a.players:GetPlayerByUserId(n)
            local name=p and p.DisplayName or self.names[n]
            if not self.a.userInfos and (name==nil or name==false and self.a.clock()-(self.nameAt[n]or 0)>60)and lookups<8 then lookups+=1;local ok,v=pcall(function()return self.a.players:GetNameFromUserIdAsync(n)end);name=ok and v or nil;self.names[n]=name or false;self.nameAt[n]=self.a.clock()end
            name=name or ('#'..key)
            local r=type(u.contrib)=='table'and u.contrib[key]or nil
            table.insert(members,{userId=n,name=name,leader=tostring(u.leader)==key,joined=at,online=p~=nil,
                total=r and r.t or 0,week=r and r.wk==week and r.w or 0,today=r~=nil and r.day==today,wars=r and r.wars or 0})
        end
        table.sort(members,function(x,y)if x.week~=y.week then return x.week>y.week end;if x.total~=y.total then return x.total>y.total end;return x.joined<y.joined end)
        local rank;for _,r in ipairs(out.top)do if r.id==id then rank=r.rank end end
        local warRank;for _,r in ipairs(warTop)do if r.id==id then warRank=r.rank end end
        local level,into,cost=U.level(u.xp)
        local w=type(u.war)=='table'and u.war.season==season and u.war or nil
        out.unit={id=id,name=u.name,tag=u.tag,code=u.code,color=U.validColor(u.color)or 1,isLeader=tostring(u.leader)==tostring(uid),members=members,count=u.count,rank=rank,
            xp=tonumber(u.xp)or 0,level=level,levelXp=into,levelCost=cost,
            war={points=w and w.points or 0,wins=w and w.wins or 0,losses=w and w.losses or 0,rank=warRank}}
    end
    return out
end
local function fail(err)return {ok=false,message=messages[err]or messages['invalid-request'],reason=err}end
function S:receipt(receipt,player)
    local info=self:product()
    if not(info.id>0 and receipt.ProductId==info.id)then return nil end
    local uid=receipt.PlayerId;local now=self.a.time()
    local ok,l=self:updateLedger(uid,function(old)return (U.grantToken(old,receipt.PurchaseId,now))end)
    if not ok or not l then return Decision.NotProcessedYet end
    if player then self.a.spawn(function()self:attendNow(player,'extra',true)end)end
    return Decision.PurchaseGranted
end
function S:attendNow(player,kind,quiet)
    local uid=player.UserId
    if self.working[uid]then if quiet then self.a.wait(2)end;if self.working[uid]then return fail('busy')end end
    self.working[uid]=true
    local done,result=pcall(self.attend,self,player,kind,uid,self.a.time())
    self.working[uid]=nil
    if not done then warn('ClanService',result);return fail('storage-unavailable')end
    local log=self.accounts and self.accounts.analytics;if log and log.custom and type(result)=='table'then pcall(function()if result.ok==false then log:custom(player,'ClanRejected',kind,result.reason,1)end end)end
    return result
end
function S:attend(player,kind,uid,now)
    local id=self.byUser[uid];if not id then return fail('not-member')end
    local finished,reason=self:finish(uid,now)
    if not finished and reason~='not-member'and reason~='unit-missing'then return fail('storage-unavailable')end
    local why
    local ok,l=self:updateLedger(uid,function(old)local out,err=U.attend(old,kind,id,now);why=err;return out end)
    if not ok then return fail('storage-unavailable')end
    if not l then if why=='need-token'then return {ok=false,reason='need-token',product=self:product()}end;return fail(why)end
    local settled,info=self:finish(uid,now)
    if not settled then
        if info=='not-member'or info=='unit-missing'then self:member(player,nil,nil);return fail(info)end
        return fail('storage-unavailable')
    end
    local log=self.accounts and self.accounts.analytics
    if log and log.custom then pcall(log.custom,log,player,'ClanAttend',kind,nil,U.attendAmount)end
    local view=self:view(player);view.attended=kind;return view
end
function S:warParty(userIds)
    if type(userIds)~='table'then return fail('war-size')end
    local clans={}
    for _,uid in ipairs(userIds)do
        local p=self.a.players:GetPlayerByUserId(uid)
        if not(p and self.loaded[uid])then return fail('busy')end
        local id=self.byUser[uid];local c=id and self.units[id]
        local u=id and (c and self.a.clock()-c.at<60 and c.unit or self:fetch(id))
        if id and u==nil then return fail('busy')end
        if id and u~=nil and not(u and type(u.members)=='table'and u.members[tostring(uid)])then self.byUser[uid]=nil;id=nil end
        table.insert(clans,id or false)
    end
    local clan,err=W.party(clans)
    if not clan then return fail(err)end
    return {ok=true,clanId=clan}
end
function S:warResult(r)
    if type(r)~='table'then return false end
    local e=table.clone(r);e.time=e.time or self.a.time();e.season=e.season or W.season(e.time)
    return self.warDelivery:record(e)
end
function S:applyWarResult(r)
    local sides=W.sides(r);local all={};for _,side in ipairs(sides)do table.insert(all,side.clan)end
    local win=W.winFor(#sides,r.size or W.teamSize);local ok=true
    for _,side in ipairs(sides)do
        if not self:warSide(side.clan,r.matchId,r.season,side.won==true,side.players,r.time,W.opponentKey(all,side.clan),win)then ok=false end
    end
    return ok
end
function S:warBoardWrite(id,season)
    local function current()
        local ok,u=self:call(function()return Fresh.read(self.store,'u:'..id)end)
        if not ok then return nil end
        if not u or u.disbanded then return false end
        local w=u.warSeasons and u.warSeasons[season]or u.war and u.war.season==season and u.war
        return w and {points=w.points,revision=(w.wins or 0)+(w.losses or 0)}or false
    end
    for _=1,3 do
        local before=current();if before==nil then return false elseif before==false then return true end
        local ok=self:call(function()return self:warStore(season):SetAsync(id,before.points)end);if not ok then return false end
        local after=current();if after==false then return true end
        if after and after.points==before.points and after.revision==before.revision then return true end
    end
    return false
end
function S:warSide(id,matchId,season,won,players,now,opponent,win)
    local ok,u,award,fresh=self.warArchive:apply('u:'..id,matchId,function(old)
        return W.apply(old,matchId,season,won,players,now,opponent,win)
    end)
    if not ok then return false end
    if not u and not award then return true end
    self.units[id]={unit=u and not u.disbanded and u or false,at=self.a.clock()}
    if u and not u.disbanded then self:board(id,u.xp)end
    local log=self.accounts and self.accounts.analytics
    if fresh and log and log.custom then
        local w=u.warSeasons and u.warSeasons[season]or u.war
        for _,uid in ipairs(players)do local player=self.a.players:GetPlayerByUserId(uid)
            if player then pcall(log.custom,log,player,'ClanWar',won and 'won'or 'lost',nil,w and w.points or 0)end
        end
    end
    if award then
        for _,uid in ipairs(award.players)do
            local saved,l=self.personalWarArchive:apply('a:'..uid,matchId,function(old)
                local revision=type(old)=='table'and tonumber(old.storageRevision)or 0
                local out,new=W.personal(U.ledger(old,self.a.time()),matchId,award.share)
                if out then out.storageRevision=(revision or 0)+1 end;return out,new
            end)
            if saved and l then self:rememberLedger(uid,l);self:invalidateView(uid)end
            if not saved or not l then return false end
        end
    end
    if not self:warBoardWrite(id,season)then return false end
    local cache=self.boards['war:'..season];if cache then cache.at=-math.huge end
    return true,fresh
end
function S:request(player,action,a,b,c)
    if type(action)~='string'then return fail('invalid-request')end
    if action=='read'then
        local uid=player.UserId
        self.viewFlights=self.viewFlights or {};self.viewCache=self.viewCache or {}
        local cached=self.viewCache[uid]
        if cached and self.a.clock()-cached.at<1 then return cached.value end
        self.viewRevision=self.viewRevision or {};local revision=self.viewRevision[uid]or 0
        local ok,result=Flight.run(self.viewFlights,uid,self.a.readWait,function()
            local wait=self.a.readWait or (if script then task.wait else coroutine.yield)
            while self.loading[uid]do wait(.05)end
            if not self.loaded[uid]then self:load(player)end
            if not self.loaded[uid]then return fail('storage-unavailable')end
            self.viewing[uid]=true;local done,value=pcall(self.view,self,player);self.viewing[uid]=nil
            if not done then error(value)end
            if value.ok and (self.viewRevision[uid]or 0)==revision and self.loaded[uid]then self.viewCache[uid]={at=self.a.clock(),value=value}end
            return value
        end)
        return ok and result or fail('storage-unavailable')
    end
    if self.a.clock()-(self.last[player.UserId]or -10)<1 then return fail('busy')end;self.last[player.UserId]=self.a.clock()
    self:invalidateView(player.UserId)
    local live=self.accounts and self.accounts.live;if live and not live.enabled('clans')then return fail('paused')end
    local uid=player.UserId;local now=self.a.time()
    if not self.loaded[uid]or self.loading[uid]then self.a.spawn(function()self:load(player)end);return fail('busy')end
    if self.working[uid]then return fail('busy')end
    self.working[uid]=true
    local done,result=pcall(self.write,self,player,action,a,b,c,uid,now)
    self.working[uid]=nil
    if not done then warn('ClanService',result);return fail('storage-unavailable')end
    if type(result)=='table'and result.reason=='storage-unavailable'and (action=='create'or action=='join'or action=='joinId')then self.a.spawn(function()self:load(player)end)end
    local log=self.accounts and self.accounts.analytics;if log and log.custom and type(result)=='table'then pcall(function()if result.ok==false then log:custom(player,'ClanRejected',action,result.reason,1)elseif action=='leave'or action=='kick'or action=='promote'or action=='color'then log:custom(player,action=='leave'and 'ClanLeft'or action=='kick'and 'ClanKicked'or action=='color'and 'ClanEmblem'or 'ClanPromoted',nil,nil,1)end end)end
    return result
end
function S:join(player,uid,id,now,fails)
    local u,why,actual,existing=self.membership:begin(uid,{kind='join',id=id,time=now})
    if not u then
        if why=='unit-missing'then Guards.count(fails,'join',self.a.clock(),Guards.joinWindow)end
        if why=='already-member'and actual then self:member(player,actual,existing)end
        return fail(why or 'storage-unavailable')
    end
    id=actual
    self.units[id]={unit=u,at=self.a.clock()};self:member(player,id,u)
    if self.accounts and self.accounts.analytics then self.accounts.analytics:custom(player,'ClanJoined',nil,nil,1)end;return self:view(player)
end
function S:write(player,action,a,b,c,uid,now)
    if action=='create'then
        if self.byUser[uid]then return fail('already-member')end
        if not self:prime(player)then return fail('prime')end
        local name,e1=U.validName(a);if not name then return fail(e1)end
        local tag,e2=U.validTag(b);if not tag then return fail(e2)end
        local color=U.validColor(c)or 1
        local fname,f1=self:filter(name,uid);if not fname then return fail(f1)end
        local ftag,f2=self:filter(tag,uid);if not ftag then return fail(f2)end
        local id,random=self.a.identity()
        local code;for _=1,5 do
            local cc=U.code(random)
            local ok,claimed=self:call(function()return self.store:UpdateAsync('c:'..cc,function(old)if old~=nil and old~=id then return nil end;return id end)end)
            if ok and claimed==id then code=cc;break end
        end
        if not code then return fail('storage-unavailable')end
        local u,why,actual,existing=self.membership:begin(uid,{kind='create',id=id,name=fname,tag=ftag,code=code,time=now,color=color})
        if not u then
            if why=='already-member'and actual then self:member(player,actual,existing)end
                return fail(why or 'storage-unavailable')
        end
        self:member(player,actual,u)
        if self.accounts and self.accounts.analytics then self.accounts.analytics:custom(player,'ClanCreated',nil,nil,1)end
        return self:view(player)
    elseif action=='join'or action=='joinId'then
        if self.byUser[uid]then return fail('already-member')end
        if not self:prime(player)then return fail('prime')end
        local fails=self.joinFails[uid]or {};self.joinFails[uid]=fails
        if Guards.blocked(fails,'join',self.a.clock(),Guards.joinWindow,Guards.joinFailures)then return fail('busy')end
        local id
        if action=='joinId'then
            if type(a)~='string'or not a:match('^%w+$')or #a>32 then return fail('unit-missing')end
            id=a
        else
            local code=U.validCode(a);if not code then return fail('unit-missing')end
            local ok,v=self:call(function()return self.store:GetAsync('c:'..code)end);if not ok then return fail('storage-unavailable')end
            if type(v)~='string'then Guards.count(fails,'join',self.a.clock(),Guards.joinWindow);return fail('unit-missing')end
            id=v
        end
        return self:join(player,uid,id,now,fails)
    elseif action=='leave'then
        local id=self.byUser[uid];if not id then return self:view(player)end
        local ok=self:call(function()return self.store:UpdateAsync('u:'..id,function(old)return U.leaveStored(old,uid)end)end)
        if not ok then return fail('storage-unavailable')end
        self.units[id]=nil;self:member(player,nil,nil);return self:view(player)
    elseif action=='kick'or action=='promote'then
        local id=self.byUser[uid];local target=tonumber(a);if not id or not target then return fail('invalid-request')end
        local rule=action=='kick'and U.kick or U.promote
        local why;local ok,u=self:call(function()return self.store:UpdateAsync('u:'..id,function(old)local out,err=rule(old,uid,target,now);why=err;return out end)end)
        if not ok then return fail('storage-unavailable')end;if not u then return fail(why)end
        self.units[id]={unit=u,at=self.a.clock()}
        if action=='kick'then local p=self.a.players:GetPlayerByUserId(target);if p then self.byUser[target]=nil;self:publish(p,nil)end end
        return self:view(player)
    elseif action=='color'then
        local id=self.byUser[uid];if not id then return fail('invalid-request')end
        local why;local ok,u=self:call(function()return self.store:UpdateAsync('u:'..id,function(old)local out,err=U.recolor(old,uid,a);why=err;return out end)end)
        if not ok then return fail('storage-unavailable')end;if not u then return fail(why)end
        self.units[id]={unit=u,at=self.a.clock()};self:member(player,id,u);return self:view(player)
    elseif action=='attend'then
        if a~='free'and a~='extra'then return fail('invalid-request')end
        local r=self:attend(player,a,uid,now)
        if type(r)=='table'and r.reason=='need-token'then return self:write(player,'buyExtra',nil,nil,nil,uid,now)end
        return r
    elseif action=='buyExtra'then
        local info=self:product()
        if info.studio then
            self:updateLedger(uid,function(old)return (U.grantToken(old,'studio-'..tostring(now)..'-'..tostring(self.a.clock()),now))end)
            return self:attend(player,'extra',uid,now)
        end
        local log=self.accounts and self.accounts.analytics
        if log and log.flow then pcall(log.flow,log,player,'commerce',info.available and 'checkout'or 'blocked',{sku='clanAttend',origin='clanStrip',result=info.available and 'selected'or 'rejected',reason=info.available and 'none'or 'sales_disabled'})end
        if not info.available then return fail('sale-closed')end
        return {ok=true,purchase=info.id}
    elseif action=='dev'then
        if not(self.a.studio and self.localMode)then return fail('invalid-request')end
        local id=self.byUser[uid]
        if a=='xp'and id then
            local ok,u=self:call(function()return self.store:UpdateAsync('u:'..id,function(old)if type(old)~='table'then return nil end;local r=U.row(old,uid,U.week(now));r.t+=5000;r.w+=5000;old.xp=(tonumber(old.xp)or 0)+5000;return old end)end)
            if ok and u then self.units[id]={unit=u,at=self.a.clock()};self:board(id,u.xp)end
        elseif a=='reset'then self:updateLedger(uid,function(old)local l=U.ledger(old,now);l.day=nil;l.pending=nil;return U.ledger(l,now)end)
        elseif a=='war'and id then
            local won=b~='loss'
            self:warSide(id,'dev-'..tostring(self.a.clock()),W.season(now),won,{uid},now)
            self.boards['war:'..W.season(now)]=nil
        end
        return self:view(player)
    end
    return fail('invalid-request')
end
return S
