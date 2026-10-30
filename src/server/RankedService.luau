local Players=if script then game:GetService('Players')else nil
local Run=if script then game:GetService('RunService')else nil
local Core=script and game.ReplicatedStorage.FrontierNative.Core
local Rules=if Core then require(Core.RankedRules)else require('../core/RankedRules')
local Season=if Core then require(Core.MonthlySeason)else require('../core/MonthlySeason')
local Outgame=if Core then require(Core.OutgameRules)else require('../core/OutgameRules')
local War=if Core then require(Core.ClanWarRules)else require('../core/ClanWarRules')
local BoardWriter=if script then require(script.Parent.RankedBoardWriter)else require('./RankedBoardWriter')
local S={};S.__index=S
S.boardSize=50
local function log(id,step,data)pcall(function()require(script.Parent.TelemetryService).new():flowUser(id,'ranked',step,data)end)end
function S.new(careers,accounts,config,dependencies)
    local self=setmetatable({careers=careers,accounts=accounts,config=config,boards={},names={},claimed={},local_=careers.localMode,stores={}},S)
    self.a=dependencies or {clock=os.clock,time=os.time,players=Players,spawn=task.spawn,delay=task.delay,wait=task.wait}
    self.boardReads={};self.boardRetry={};self.refreshing={}
    self.boardWriter=BoardWriter.new(self)
    careers.onBoardPending=function()return next(self.boardWriter.pending)~=nil or next(self.boardWriter.busy)~=nil end
    careers.onBoardTick=function()self.boardWriter:retry()end
    careers.onLoaded=function(id,p)self.boardWriter:recover(id,p)end
    careers.onRanked=function(id,saved,result,before)pcall(self.track,self,id,saved,result,before);self:submit(id,saved,result)end
    return self
end
function S:allowed()return self.config.rankedEnabled==true and require(script.Parent.LiveConfig).enabled('ranked')or Run:IsStudio()end
function S:store(seasonKey,ladder)
    if self.local_ then return nil end
    local name=ladder=='trophySolo'and 'SuperCommanderTrophySolo_v1'or 'SuperCommanderRanked_'..seasonKey..'_'..ladder
    self.stores[name]=self.stores[name]or game:GetService('DataStoreService'):GetOrderedDataStore(name)
    return self.stores[name]
end
function S:record(id)local p=self.careers.profiles[id];return p and p.ranked end
function S:ladderView(id,ladder,now)return Rules.view(self:record(id),ladder,now or os.time())end
function S:submit(id,saved,result)
    if result.trophySolo then
        local c=self.boards.alltrophySolo;if c then c.at=-math.huge end
        self.boardWriter:queue(id,'all','trophySolo');return
    end
    local ladder=result.ladder;local season=result.time and Season.at(result.time).key or saved.ranked and saved.ranked.season
    if not season then return end
    local cached=self.boards[season..ladder];if cached then cached.at=-math.huge end
    self.boardWriter:queue(id,season,ladder)
end
function S:name(id)
    local p=self.a.players:GetPlayerByUserId(id);if p then return p.DisplayName end
    if self.names[id]==nil then local ok,n=pcall(function()return self.a.players:GetNameFromUserIdAsync(id)end);self.names[id]=ok and n or false end
    return self.names[id]or '지휘관'
end
function S:fillNames(rows)
    local missing={}
    for _,row in ipairs(rows)do local id=row.userId;if id and self.names[id]==nil and not self.a.players:GetPlayerByUserId(id)then table.insert(missing,id)end end
    if #missing>0 and script then
        local ok,infos=pcall(function()return game:GetService('UserService'):GetUserInfosByUserIdsAsync(missing)end)
        if ok and type(infos)=='table'then for _,info in ipairs(infos)do local n=tonumber(info.Id)
            if n then self.names[n]=(type(info.DisplayName)=='string'and info.DisplayName~=''and info.DisplayName)or info.Username or false end end end
    end
end
function S:board(seasonKey,ladder,size)
    local key=seasonKey..ladder;local c=self.boards[key];local limit=math.min(100,size or S.boardSize)
    local covered=c and c.limit>=limit;local now=self.a.clock()
    if covered and now-c.at<60 then return c.rows end
    if self.boardReads[key]or now<(self.boardRetry[key]or -math.huge)then return covered and c.rows or nil end
    self.boardReads[key]=true
    local ok,rows=pcall(self.readBoard,self,seasonKey,ladder,limit)
    self.boardReads[key]=nil
    if not ok then self.boardRetry[key]=self.a.clock()+5;return covered and c.rows or nil end
    self.boardRetry[key]=nil;self.boards[key]={at=self.a.clock(),rows=rows,limit=limit}
    return rows
end
function S:readBoard(seasonKey,ladder,limit)
    local rows={}
    if self.local_ then
        for id,p in pairs(self.careers.profiles)do local r=p.ranked;local l=r and r.season==seasonKey and r.ladders[ladder]
            if ladder=='trophySolo'then local t=p.trophySolo;l=t and t.games>0 and {rp=t.t,placement=0}or nil end
            if l and (l.placement or 0)<=0 then table.insert(rows,{userId=id,rp=l.rp})end end
        table.sort(rows,function(a,b)return a.rp>b.rp or a.rp==b.rp and a.userId<b.userId end)
    else
        local page=self:store(seasonKey,ladder):GetSortedAsync(false,limit):GetCurrentPage()
        for _,row in ipairs(page)do table.insert(rows,{userId=tonumber(row.key),rp=row.value})end
    end
    local shown={};local display=ladder=='trophySolo'and Rules.trophy.legendTop or S.boardSize
    for i=1,math.min(#rows,display)do shown[i]=rows[i]end;self:fillNames(shown)
    for i,row in ipairs(rows)do row.rank=i
        row.tier=ladder=='trophySolo'and (Rules.trophyLegend(row.rp,i)and 'legend'or Rules.trophyTier(row.rp).id)or (Rules.isLegend(row.rp,i)and 'legend'or Rules.tierOf(row.rp).id)
        if i<=display then row.name=self:name(row.userId)end
    end
    return rows
end
function S:cachedBoard(seasonKey,ladder)
    local key=seasonKey..ladder;local c=self.boards[key];local now=self.a.clock()
    if (not c or now-c.at>=60)and now>=(self.boardRetry[key]or -math.huge)and not self.refreshing[key]then
        self.refreshing[key]=true;self.a.spawn(function()pcall(self.board,self,seasonKey,ladder,Rules.legend.top);self.refreshing[key]=nil end)
    end
    return c and c.rows or {}
end
function S:track(id,saved,result,before)
    if result.trophySolo then
        local r=saved.lastTrophySolo
        if r and r.id==result.id then log(id,'result',{item='r1v1',result=r.won and 'won'or 'lost',amount=r.delta,value=math.abs(r.delta),level=r.t})end
        return
    end
    local ladder=result.ladder;local now=os.time()
    local b=Rules.view(before and before.ranked,ladder,now);local a=Rules.view(saved.ranked,ladder,now)
    log(id,'result',{item='r'..tostring(ladder),result=result.won and 'won'or 'lost',value=math.abs(a.rp-b.rp),amount=a.rp-b.rp,count=a.games,level=a.rp})
    if b.placing and not a.placing then log(id,'placed',{item=a.tier,value=a.rp,result='complete'})end
    if not a.placing and (a.tier~=b.tier or b.placing)then log(id,'tierChange',{item=a.tier,value=a.rp,result=(b.placing or a.rp>b.rp)and 'granted'or 'lost'})end
end
local reasonOf={['랭크전은 곧 열려요.']='paused',['클랜전은 곧 열려요.']='paused'}
function S:join(queue,ids,ladder,now)
    local ok,msg=self:joinNow(queue,ids,ladder,now)
    for _,id in ipairs(ids)do log(id,'join',{item=(ladder=='clanwar'or ladder=='r1v1')and ladder or 'r'..tostring(ladder),count=#ids,result=ok and 'accepted'or 'rejected',reason=not ok and (reasonOf[msg]or (tostring(msg):find('불러오')and 'not_loaded')or (tostring(msg):find('레벨')and 'locked')or 'invalid')or nil})end
    return ok,msg
end
function S:level(id)
    local p=self.a.players and self.a.players:GetPlayerByUserId(id)
    local a=p and self.accounts and self.accounts.accounts and self.accounts.accounts[p]
    local xp=a and a.ready and a.profile and a.profile.outgame and a.profile.outgame.xp
    return type(xp)=='number'and (Outgame.level(xp))or nil
end
function S:joinNow(queue,ids,ladder,now)
    if ladder=='r1v1'then return self:joinTrophy(queue,ids,now)end
    if not self:allowed()then return false,'랭크전은 곧 열려요.'end
    if ladder=='clanwar'and not War.open then return false,'클랜전은 곧 열려요.'end
    if type(ids)~='table'or #ids<1 or #ids>(ladder=='clanwar'and 5 or 2)then return false,ladder=='clanwar'and '클랜전은 클랜원 2~5명이 파티로 함께 참가해요.'or '랭크 전장을 다시 골라 주세요.'end
    local unique={};for _,id in ipairs(ids)do
        if type(id)~='number'or id%1~=0 or id==math.huge or unique[id]then return false,'랭크 전장을 다시 골라 주세요.'end
        unique[id]=true
    end
    for i,id in ipairs(ids)do
        local level=self:level(id)
        if level==nil then return false,'전적을 불러오는 중이에요. 잠시 뒤 다시 눌러 주세요.'end
        if not Rules.levelOk(level)then return false,i==1 and string.format('랭크전은 레벨 %d부터 참가할 수 있어요.',Rules.minLevel)or string.format('함께하는 친구도 레벨 %d 이상이어야 해요.',Rules.minLevel)end
    end
    if ladder=='clanwar'then return self:joinClanWar(queue,ids,now)end
    if not Rules.size[ladder]then return false,'랭크 전장을 다시 골라 주세요.'end
    if ladder=='1v1'and #ids>1 then return false,'1대1 랭크전은 혼자 참가해요. 파티를 나간 뒤 다시 눌러 주세요.'end
    if ladder=='ffa'and #ids>1 then return false,'개인전 랭크는 혼자 참가해요. 파티를 나간 뒤 다시 눌러 주세요.'end
    if #ids>2 then return false,'2대2 랭크전은 둘까지 함께 참가할 수 있어요.'end
    local ratings={}
    for _,id in ipairs(ids)do
        if not self.careers.profiles[id]then return false,'전적을 불러오는 중이에요. 잠시 뒤 다시 눌러 주세요.'end
        ratings[tostring(id)]=self:ladderView(id,ladder,os.time()).rp
    end
    return queue:joinField(ids,{field='ranked-'..ladder,revision=0,ratings=ratings},now)
end
function S:trophyLive()
    return self.a.live or (script and require(script.Parent.LiveConfig))
end
function S:trophyAllowed()
    local live=self:trophyLive()
    return live~=nil and live.get('ranked1v1')==true and live.enabled('ranked')and (self.config.rankedEnabled==true or self.local_)
end
function S:trophyScoreView(id)
    local profile=self.careers.profiles[id];local rank
    for i,row in ipairs(self:cachedBoard('all','trophySolo'))do
        if i>Rules.trophy.legendTop then break end
        if row.userId==id then rank=i;break end
    end
    return Rules.trophyView(profile and profile.trophySolo,self.a.time(),rank)
end
function S:trophyView(id)
    local now=self.a.time();local profile=self.careers.profiles[id]
    local v=Rules.trophyView(profile and profile.trophySolo,now)
    v.enabled=self:trophyAllowed();v.loaded=profile~=nil;v.level=self:level(id);v.minLevel=Rules.minLevel
    local worker=self.careers.worker;v.pending=worker and (worker.pending[id]~=nil or worker.busy[id]~=nil or worker.recovery[id]~=nil)or nil
    v.board={};v.boardLoading=false
    if v.enabled then
        local rows=self:cachedBoard('all','trophySolo');v.boardLoading=self.boards.alltrophySolo==nil
        for i,row in ipairs(rows)do if i<=Rules.trophy.legendTop then
            table.insert(v.board,{rank=i,userId=row.userId,name=row.name,value=row.rp,tier=row.tier,self=row.userId==id or nil})
            if row.userId==id then
                local actual=Rules.trophyView(profile and profile.trophySolo,now,i)
                v.rank=i;v.tier=actual.tier;v.tierName=actual.tierName;v.color=actual.color
            end
        end end
    end
    v.last=profile and profile.lastTrophySolo or nil
    return v
end
function S:joinTrophy(queue,ids,now)
    if not self:trophyAllowed()then return false,'랭크 점검 중'end
    if type(ids)~='table'or #ids~=1 then return false,'혼자일 때만'end
    local id=ids[1]
    if type(id)~='number'or id%1~=0 or id==0 or math.abs(id)==math.huge then return false,'참가 정보 확인'end
    local level=self:level(id);if not level then return false,'전적 불러오는 중'end
    if not Rules.levelOk(level)then return false,'레벨 5부터'end
    local profile=self.careers.profiles[id];local worker=self.careers.worker
    if not profile or worker and (worker.pending[id]or worker.busy[id]or worker.recovery[id])then return false,'전적 저장 중'end
    local trophy=Rules.trophyRead(profile.trophySolo,self.a.time())
    if not trophy then return false,'전적 확인 필요'end
    if Rules.trophyBanLeft(trophy,self.a.time())>0 then return false,'랭크 잠시 대기'end
    local last=trophy.recent[#trophy.recent]
    return queue:joinField(ids,{field='ranked-r1v1',revision=0,ratings={[tostring(id)]=trophy.t},previous=last and last.o or nil,window=self:trophyLive().get('rankedWindow')},now)
end
function S:noShow(id,matchId,time)
    local worker=self.careers.worker
    if not worker then return false end
    local event={id='r1v1-noShow:'..matchId,revision=1,startedAt=time,time=time,won=false,counted=false,trophyNoShow=true}
    if not worker:record(id,event)then return false end
    if not worker:drain(id)then return false end
    if self.a.players:GetPlayerByUserId(id)then pcall(function()require(script.Parent.TelemetryService).new():flowUser(id,'queue','noShow',{item='r1v1',result='rejected'})end)end
    return true
end
function S:clans()local c=self.accounts and self.accounts.clans;return c and type(c.warParty)=='function'and c or nil end
function S:joinClanWar(queue,ids,now)
    local clans=self:clans();if not clans then return false,'클랜전은 곧 열려요.'end
    local live=self.accounts and self.accounts.live;if live and live.enabled and not live.enabled('clans')then return false,'클랜 기능을 잠시 점검 중이에요.'end
    if #ids<2 or #ids>5 then return false,'클랜전은 클랜원 2~5명이 파티로 함께 참가해요.'end
    local ok,w=pcall(clans.warParty,clans,ids)
    if not ok or type(w)~='table'then return false,'클랜 정보를 불러오지 못했어요. 잠시 뒤 다시 눌러 주세요.'end
    local clan=w.clanId or w.clan
    local reasons={['war-size']='클랜전은 클랜원 2~5명이 파티로 함께 참가해요.',['war-clan']='같은 클랜원과 함께 참가해 주세요.',busy='클랜 정보를 불러오지 못했어요. 잠시 뒤 다시 눌러 주세요.'}
    if not w.ok or clan==nil then return false,reasons[w.reason]or '같은 클랜원과 함께 참가해 주세요.'end
    local ratings={}
    for _,id in ipairs(ids)do
        if not self.careers.profiles[id]then return false,'전적을 불러오는 중이에요. 잠시 뒤 다시 눌러 주세요.'end
        ratings[tostring(id)]=self:ladderView(id,'2v2',os.time()).rp
    end
    return queue:joinField(ids,{field='ranked-clanwar',revision=0,ratings=ratings,clan=tostring(clan)},now)
end
function S:clanWarResult(room)
    local clans=self:clans();if not clans or type(clans.warResult)~='function'then return end
    local s=room.session;local byClan,order,winnerClan={},{},nil
    for id,faction in pairs(room.members)do
        local p=s.sim.players[faction];local clan=room.clanwar.clans and room.clanwar.clans[id]
        if clan~=nil then
            local side=byClan[clan];if not side then side={clan=clan,players={},won=false};byClan[clan]=side;table.insert(order,side)end
            if s.winnerTeam~=nil and p.team==s.winnerTeam then
                winnerClan=winnerClan or clan;side.won=true
                if not s.resources[faction].forfeited then table.insert(side.players,id)end
            else table.insert(side.players,id)end
        end
    end
    if not winnerClan or #order<2 then return end
    local winners,losers,loserClan={},{},nil
    for _,side in ipairs(order)do
        table.sort(side.players)
        if side.clan==winnerClan then side.won=true;winners=side.players else side.won=false;loserClan=loserClan or side.clan;for _,id in ipairs(side.players)do table.insert(losers,id)end end
    end
    if #winners==0 then return end
    table.sort(losers);table.sort(order,function(a,b)return tostring(a.clan)<tostring(b.clan)end)
    room.resultTime=room.resultTime or self.a.time()
    pcall(clans.warResult,clans,{matchId=room.id,time=room.resultTime,season=Season.at(room.resultTime).key,winners=winners,losers=losers,winnerClan=winnerClan,loserClan=loserClan,
        sides=order,size=room.clanwar.size or 2})
end
function S:clanWarBoard(id)
    local c=self.accounts and self.accounts.clans;if not c or type(c.rankedBoard)~='function'then return nil end
    local p=self.a.players:GetPlayerByUserId(id);if not p then return nil end
    local ok,out=pcall(c.rankedBoard,c,p);return ok and out or nil
end
function S:result(room,id,won)
    local ladder=room.ranked;if not ladder then return nil end
    if room.trophySolo then
        local opponent
        for other in pairs(room.members)do if other~=id then opponent=other;break end end
        if not opponent then return nil end
        room.resultTime=room.resultTime or self.a.time()
        return {ladder='1v1',trophySolo=true,time=room.resultTime,mine=(room.ratings or {})[id]or 0,
            opponent=(room.ratings or {})[opponent]or 0,opponents={opponent}}
    end
    local s=room.session;local mine=room.members[id];local myTeam=s.sim.players[mine].team
    local team,teamN,opp,oppN,opponents=0,0,0,0,{}
    for other,faction in pairs(room.members)do local rp=(room.ratings or {})[other]or Rules.start
        local same=ladder=='2v2'and s.sim.players[faction].team==myTeam
        if other==id or same then team+=rp;teamN+=1 else opp+=rp;oppN+=1;table.insert(opponents,other)end
    end
    table.sort(opponents)
    room.resultTime=room.resultTime or self.a.time()
    local out={ladder=ladder,time=room.resultTime,team=teamN>0 and math.floor(team/teamN+.5)or nil,opponent=oppN>0 and math.floor(opp/oppN+.5)or Rules.start,opponents=opponents}
    if ladder=='ffa'then
        local rp=function(uid)return (room.ratings or {})[uid]or Rules.start end
        local winner;for other,faction in pairs(room.members)do if faction==s.winnerId then winner=other end end
        local list={}
        if won then for _,other in ipairs(opponents)do table.insert(list,rp(other))end
        elseif winner and winner~=id then list={rp(winner)}
        else list={out.opponent}end
        out.pairs=list;out.players=oppN+1
    end
    return out
end
function S:retryClaim(player)
    self.claimTries=self.claimTries or {};local id=player.UserId;local n=(self.claimTries[id]or 0)+1
    if n>5 then return end;self.claimTries[id]=n
    self.a.delay(60*n,function()if player.Parent==self.a.players then self:claim(player)else self.claimTries[id]=nil end end)
end
function S:claim(player)
    local id=player.UserId
    local now=self.a.time();local s=Season.at(now);if s.n<1 then return end
    if self.claimed[id]==s.key then return end
    local profile=self.careers.profiles[id];if not profile then return end
    local worker=self.careers.worker
    if worker and (worker.pending[id]or worker.recovery[id]or worker.busy[id])then self:retryClaim(player);return end
    self.claimed[id]=s.key
    local a=self.a.players:GetPlayerByUserId(id);local acc=a and self.accounts.accounts and self.accounts.accounts[a]
    local paidMap=acc and acc.profile and acc.profile.outgame and acc.profile.outgame.rankedPaid or {}
    local last
    for n=s.n-1,math.max(0,s.n-3),-1 do local key=Season.key(n)
        if not paidMap[key]then local got=self:claimSeason(player,id,profile,key,now);if got==false then return end;last=last or got end
    end
    return last
end
function S:claimSeason(player,id,profile,prev,now)
    local rolled=Rules.roll(profile.ranked,now)
    local h=rolled.history[prev];if not h then return nil end
    local ranks={}
    for _,ladder in ipairs(Rules.ladders)do if h[ladder]and h[ladder].placed then
        local rows=self:board(prev,ladder,100);if not rows then self.claimed[id]=nil;self:retryClaim(player);return false end
        for _,row in ipairs(rows)do if row.userId==id then ranks[ladder]=row.rank;break end end
    end end
    local reward=Rules.seasonReward(rolled,prev,ranks);if not reward then return end
    local paid
    local saved,err=self.accounts:updateProgress(id,function(p)
        paid=nil
        p.outgame.rankedPaid=type(p.outgame.rankedPaid)=='table'and p.outgame.rankedPaid or {}
        if p.outgame.rankedPaid[prev]then return nil,'already-paid'end
        p.outgame.rankedPaid[prev]={coins=reward.coins,band=reward.band,ladder=reward.ladder}
        p.outgame.medals+=reward.coins;paid=reward;return p
    end,'TimedReward','rankedSeason')
    if not saved and err~='already-paid'then self.claimed[id]=nil;self:retryClaim(player);return false end
    if saved and paid then log(id,'seasonReward',{item=tostring(paid.band),value=paid.coins,currency='Medals',result='granted'})end
    return saved and paid or nil
end
function S:view(id)
    local now=os.time();local s=Season.at(now);local p=self.a.players:GetPlayerByUserId(id)
    local out={enabled=self:allowed(),live=self.config.rankedEnabled==true and self:allowed()and not (Run and Run:IsStudio()),paused=self.config.rankedEnabled==true and not self:allowed()or nil,season={n=s.n,key=s.key,label=s.label,daysLeft=Season.daysLeft(now),finish=s.finish},
        loaded=self.careers.profiles[id]~=nil,ladders={},boards={},rewards=Rules.rewards,level=self:level(id),minLevel=Rules.minLevel}
    for _,ladder in ipairs(Rules.ladders)do
        out.ladders[ladder]=self:ladderView(id,ladder,now)
        local rows=self:cachedBoard(s.key,ladder);local list={}
        for i,row in ipairs(rows)do
            if row.userId==id then local lv=out.ladders[ladder];lv.rank=row.rank
                if row.tier=='legend'then lv.tier='legend';lv.tierName=Rules.legend.name;lv.division=nil;lv.color=Rules.legend.color;lv.band=Rules.band(row.rp,row.rank)end end
            if i<=S.boardSize then table.insert(list,{rank=row.rank,name=row.name,value=row.rp,tier=row.tier,self=row.userId==id or nil,userId=row.userId})end
        end
        out.boards[ladder]=list;out.boardsLoading=out.boardsLoading or {};out.boardsLoading[ladder]=self.boards[s.key..ladder]==nil or nil
    end
    local a=p and self.accounts.accounts[p];local paid=a and a.profile and a.profile.outgame and a.profile.outgame.rankedPaid
    if s.n>=1 and type(paid)=='table'then out.lastReward=paid[Season.key(s.n-1)]end
    local r=self:record(id);out.last=self.careers.profiles[id]and self.careers.profiles[id].lastRanked or nil
    out.history=r and r.history or nil
    out.trophySolo=self:trophyView(id)
    return out
end
return S
