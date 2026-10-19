local Presets=if script then require(script.Parent.SinglePresets) else require('./SinglePresets')
local C=if script then require(script.Parent.CosmeticCatalog) else require('./CosmeticCatalog')
local Career=if script then require(script.Parent.CareerRules) else require('./CareerRules')
local Season=if script then require(script.Parent.SeasonRules) else require('./SeasonRules')
local Daily=if script then require(script.Parent.DailyOperation) else require('./DailyOperation')
local Records=if script then require(script.Parent.MatchRecords) else require('./MatchRecords')
local M={version=1,presetVersion='toy-1'}
M.modes={single='캠페인',pvp='대전',coop='연합전',custom='자유 설정',training='첫 연습'}
M.shop={
    {id='pioneer',name='개척자 지휘관',price=100,badge='pioneer'},
    {id='sodaOrder',name='아크틱 명령',price=250,style='arctic',slots={'commanderOrder'}},
    {id='sodaBuild',name='아크틱 건축',price=500,style='arctic',slots={'city','defensePost'}},
    {id='sodaLand',name='아크틱 영토',price=500,style='arctic',slots={'territory'}},
}
M.onboarding={{id='expand',name='첫 땅 넓히기',hint='빈 땅을 공격해 넓히기',xp=100,medals=50},{id='city',name='첫 도시 세우기',hint='도시 1개 완공',xp=100,medals=50},{id='front',name='전선 지키기',hint='적의 공격 한 번 막아 내기',xp=100,medals=50},{id='finish',name='한 판 끝까지',hint='2분 넘게 싸우고 승패 내기',xp=100,medals=100}}
M.daily={{id='seconds',name='6분 작전 수행',target=360,reward=20,xp=40},{id='cities',name='도시 3개 완공',target=3,reward=20,xp=40},{id='finished',name='한 판 끝까지',target=1,reward=20,xp=40}}
M.weeklyXP=300
M.weeklyMedals=100
M.weeklyPaths={{id='seconds',name='작전 60분',target=3600},{id='cities',name='도시 12개 완공',target=12},{id='supports',name='동료 지원 12회',target=12}}
M.streakRewards={20,30,40,50,60,80,150}
M.firstWin={xp=100,medals=50}
local LevelCurve=if script then require(script.Parent.LevelProgression)else require('./LevelProgression')
M.maxLevel=LevelCurve.maxLevel
M.levelCost=LevelCurve.cost
M.career=Career
M.season=Season
M.dailyOperation=Daily
M.ranks={
    {level=1,name='훈련병'},{level=5,name='이병'},{level=10,name='상병'},{level=20,name='병장'},
    {level=30,name='하사'},{level=40,name='중사'},{level=50,name='소위'},{level=60,name='중위'},
    {level=70,name='대위'},{level=80,name='소령'},{level=90,name='중령'},{level=95,name='대령'},{level=100,name='원수'},
}
function M.rank(level)
    local index=1;for i,r in ipairs(M.ranks)do if level>=r.level then index=i end end
    local nextRank=M.ranks[index+1];return index,M.ranks[index].name,nextRank and nextRank.level or nil,nextRank and nextRank.name or nil
end
M.conquestSteps={
    {id='played',name='참전',test=function(m)return m.games>=1 end},
    {id='firstWin',name='첫 승리',test=function(m)return m.wins>=1 end},
    {id='half',name='점유 50%',test=function(m)return m.peak>=.5 end},
    {id='wins5',name='5승',test=function(m)return m.wins>=5 end},
    {id='wins10',name='10승 지배자',test=function(m)return m.wins>=10 end},
}
M.conquestXP=50
M.partyBonus=1.1
local function built(t,kind)return (t.built or {})[kind]or 0 end
M.tacticTierXP={50,100,200}
M.tactics={
    {id='noNukeWin',name='핵 없는 승리',detail='핵을 쓰지 않고 승리',tiers={1,5,20},test=function(e,t)return e.outcome=='won'and (t.nukes or 0)==0 end},
    {id='comeback',name='역전의 지휘관',detail='영토 5% 아래까지 밀렸다가 승리',tiers={1,3,10},test=function(e,t)return e.outcome=='won'and (t.minShare or 1)<=.05 end},
    {id='blitz',name='전격전',detail='10분 안에 승리',tiers={1,5,20},test=function(e,t)return e.outcome=='won'and (e.seconds or 0)<=600 end},
    {id='cityWin',name='도시 왕국',detail='한 판에 도시 10개를 세우고 승리',tiers={1,5,20},test=function(e,t)return e.outcome=='won'and (e.cities or 0)>=10 end},
    {id='landing',name='상륙 작전',detail='수송선 3척 이상 보내고 승리',tiers={1,5,20},test=function(e,t)return e.outcome=='won'and (t.transports or 0)>=3 end},
    {id='pvpVictor',name='사람을 꺾다',detail='다른 지휘관이 있는 대전에서 승리',tiers={1,10,50},test=function(e,t)return e.outcome=='won'and e.mode=='pvp'and (e.humans or 1)>=2 end},
    {id='coopVictor',name='연합 승리',detail='연합전에서 승리',tiers={1,10,50},test=function(e,t)return e.outcome=='won'and e.mode=='coop'end},
    {id='dominion',name='대륙 제패',detail='한 판에서 영토 75% 차지',tiers={1,5,20},test=function(e,t)return (e.peak or 0)>=.75 end},
    {id='rapidGrowth',name='초반 질주',detail='시작 3분 안에 영토 10%',tiers={1,5,20},test=function(e,t)return (t.earlyShare or 0)>=.1 end},
    {id='ally',name='든든한 동맹',detail='한 판에 동료 지원 10회',tiers={1,5,20},test=function(e,t)return (e.supports or 0)>=10 end},
    {id='fortress',name='철벽 방어',detail='방어 거점 5개를 짓고 10분 이상 버티기',tiers={1,5,20},test=function(e,t)return built(t,'DefensePost')>=5 and (e.seconds or 0)>=600 end},
    {id='airDefense',name='방공망',detail='한 판에 방공 기지 3개',tiers={1,5,20},test=function(e,t)return built(t,'SAMLauncher')>=3 end},
    {id='harbor',name='항구 도시',detail='한 판에 항구 3개',tiers={1,5,20},test=function(e,t)return built(t,'Port')>=3 end},
    {id='fleet',name='함대 사령관',detail='한 판에 전함 5척',tiers={1,5,20},test=function(e,t)return built(t,'Warship')>=5 end},
    {id='silo',name='미사일 기지',detail='한 판에 미사일 기지 2개',tiers={1,5,20},test=function(e,t)return built(t,'MissileSilo')>=2 end},
    {id='nuclear',name='핵 지휘관',detail='한 판에 핵 3발 발사',tiers={1,5,20},test=function(e,t)return (t.nukes or 0)>=3 end},
    {id='developer',name='도시 개발',detail='한 판에 건물 업그레이드 5회',tiers={1,5,20},test=function(e,t)return (t.upgrades or 0)>=5 end},
    {id='comrades',name='전우와 함께',detail='파티 친구와 같은 판에서 승리',tiers={1,10,50},test=function(e,t)return e.outcome=='won'and e.party==true end},
    {id='survivor',name='끝까지 버틴다',detail='20분 넘게 싸우고 경기를 끝내기',tiers={1,10,50},test=function(e,t)return (e.seconds or 0)>=1200 end},
}
function M.tacticTier(def,count)local tier=0;for i,n in ipairs(def.tiers)do if count>=n then tier=i end end;return tier end
function M.conquest(m)
    if type(m)~='table'then return 0 end
    local n=0;for _,step in ipairs(M.conquestSteps)do if step.test({games=m.games or 0,wins=m.wins or 0,peak=m.peak or 0})then n+=1 else break end end;return n
end
M.achievementList={
    {id='firstWin',name='첫 승전',detail='아무 모드에서나 한 판 이기기',target=1,medals=100},
    {id='games10',name='단골 지휘관',detail='10판 끝까지 플레이',target=10,medals=150},
    {id='cities25',name='건설 사령관',detail='도시 25개 완공',target=25,medals=150},
    {id='peak50',name='대륙 절반 장악',detail='한 판에서 영토 50% 차지',target=50,medals=200},
    {id='coopWin',name='든든한 동료',detail='연합전에서 승리',target=1,medals=150},
    {id='pvpWin',name='진짜 대결 승리',detail='다른 지휘관이 있는 대전에서 승리',target=1,medals=200},
    {id='streak7',name='매일 출근 지휘관',detail='7일 연속 접속',target=7,medals=300},
    {id='wins10',name='정복자',detail='10번 승리',target=10,medals=300},
    {id='maps5',name='세계 여행자',detail='서로 다른 지도 5곳에서 승리',target=5,medals=300},
    {id='games50',name='역전의 장군',detail='50판 끝까지 플레이',target=50,medals=500},
}
local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
M.copy=copy
local function integer(n,default,max)if type(n)~='number'or n~=n or math.abs(n)==math.huge then return default or 0 end;return math.clamp(math.floor(n),0,max or 1e12)end
function M.new()return {schema=1,levelCurve=LevelCurve.version,xp=0,medals=0,onboarding={},unlocks={},ownedSlots={},loadouts={},daily={},weekly={},receipts={},history={},stats={},mastery={},achievements={},lifetime={cities=0,peak=0},login={day=-1,streak=0,best=0},single={map='world',settings=copy(Presets.standard)},lastMode='single',tutorial=true}end
function M.decode(raw)
    if raw==nil then return M.new()end
    if type(raw)~='table'or raw.schema~=1 then return nil,'unsupported-outgame'end
    local p=copy(raw);local base=M.new();for k,v in pairs(base)do if p[k]==nil then p[k]=v end end
    for _,k in ipairs({'onboarding','unlocks','ownedSlots','loadouts','daily','weekly','receipts','history','stats','mastery','achievements','lifetime','login','single'})do if type(p[k])~='table'then return nil,'invalid-outgame'end end
    p.xp=integer(p.xp);p.medals=integer(p.medals)
    if raw.levelCurve~=nil and raw.levelCurve~=1 and raw.levelCurve~=LevelCurve.version then return nil,'unsupported-level-curve'end
    if raw.levelCurve==nil or raw.levelCurve==1 then p.xp=LevelCurve.migrate(p.xp);p.levelCurve=LevelCurve.version end
    if p.firstWinDays~=nil and type(p.firstWinDays)~='table'then return nil,'invalid-outgame'end
    if p.conquestPaid~=nil and type(p.conquestPaid)~='table'then return nil,'invalid-outgame'end
    if p.tactics~=nil and type(p.tactics)~='table'then return nil,'invalid-outgame'end
    for _,k in ipairs({'weekPool','comradeDays','equipped','season','seasonRewards','recruit','recruits','dailyOp','pruned','record','goalClaims','voided'})do if p[k]~=nil and type(p[k])~='table'then p[k]=nil end end
    if p.groupMember~=nil and p.groupMember~=true then p.groupMember=nil end
    if p.activeLoadout~=nil and (type(p.activeLoadout)~='number'or p.activeLoadout%1~=0 or p.activeLoadout<1 or p.activeLoadout>12)then p.activeLoadout=nil end
    p.login.claims=integer(p.login.claims,integer(p.login.streak))
    local saved=p.single.settings
    if type(saved)=='table'then
        local legacy=true
        for key,value in pairs(Presets.legacyStandard)do if saved[key]~=value then legacy=false end end
        for key,value in pairs(saved)do if Presets.legacyStandard[key]==nil and key~='seed'and value~=nil and value~=false and value~=0 then legacy=false end end
        if legacy then p.single.settings=copy(Presets.standard)end
    end
    return p
end
function M.progressOf(p,id)
    local games,wins=0,0;for _,s in pairs(p.stats)do games+=s.games or 0;wins+=s.wins or 0 end
    local maps=0;for key in pairs(p.achievements)do if type(key)=='string'and key:sub(1,4)=='map:'then maps+=1 end end
    if id=='firstWin'or id=='wins10'then return wins
    elseif id=='games10'or id=='games50'then return games
    elseif id=='cities25'then return p.lifetime.cities or 0
    elseif id=='peak50'then return math.floor((p.lifetime.peak or 0)*100+1e-6)
    elseif id=='coopWin'then return p.stats.coop and p.stats.coop.wins or 0
    elseif id=='pvpWin'then return p.lifetime.humanWins or 0
    elseif id=='streak7'then return p.login.best or 0
    elseif id=='maps5'then return maps end
    return 0
end
local function pend(p,key,source,id,xp,medals)
    p.goalClaims=type(p.goalClaims)=='table'and p.goalClaims or {}
    if p.goalClaims[key]then return end
    p.goalClaims[key]={source=source,id=id,xp=xp or 0,medals=medals or 0}
end
M.pend=pend
function M.claimGoals(raw,key,now,mult)
    local p,err=M.decode(raw);if not p then return nil,err end
    local list=type(p.goalClaims)=='table'and p.goalClaims or {};local got={xp=0,medals=0,count=0,keys={}}
    for k,c in pairs(list)do if key=='all'or k==key then
        got.xp+=integer(c.xp,0,1e6);got.medals+=integer(c.medals,0,1e6);got.count+=1;table.insert(got.keys,k);list[k]=nil
    end end
    if got.count==0 then return nil,'unchanged'end
    p.goalClaims=list
    p.xp+=got.xp;p.medals+=got.medals;Season.add(p,got.xp,now or 0)
    mult=tonumber(mult)or 1
    if mult>1 and got.xp>0 then got.paidXP=math.floor(got.xp*(math.min(mult,4)-1));p.xp+=got.paidXP end
    M.award(p)
    return p,got
end
function M.award(p)
    local unlocked={}
    for _,a in ipairs(M.achievementList)do
        local key='a:'..a.id
        if not p.achievements[key]and M.progressOf(p,a.id)>=a.target then p.achievements[key]=true;pend(p,key,'achievement',a.id,0,a.medals);table.insert(unlocked,a.id)end
    end
    return unlocked
end
function M.checkIn(raw,now)
    local p,err=M.decode(raw);if not p then return nil,err end
    local today=tonumber(M.day(now));local login=p.login
    if (login.day or -1)>=today then return p,nil end
    local streak=(login.day or -1)>=0 and login.day>=today-1-Career.streakGrace and (login.streak or 0)+1 or 1
    login.day=today;login.streak=streak;login.best=math.max(login.best or 0,streak);login.claimedAt=now
    login.claims=(login.claims or 0)+1
    local step=(login.claims-1)%#M.streakRewards+1
    local medals=M.streakRewards[step];p.medals+=medals;login.reward=medals
    return p,{streak=streak,claims=login.claims,rewardStep=step,medals=medals,unlocked=M.award(p)}
end
function M.level(xp)
    local level,used=1,0;while level<M.maxLevel do local nextXP=M.levelCost(level);if xp<used+nextXP then break end;used+=nextXP;level+=1 end
    local cap=level==M.maxLevel;return level,cap and 0 or xp-used,cap and 0 or M.levelCost(level)
end
function M.day(time)return tostring(math.floor(time/86400))end
function M.week(time)return tostring(math.floor((math.floor(time/86400)+3)/7))end
function M.classify(settings)
    for key,value in pairs(Presets.standard)do if settings[key]~=value then return 'custom'end end
    for key,value in pairs(settings)do if Presets.standard[key]==nil and key~='seed'and key~='teamFormat'and key~='randomSpawn'and key~='mapSize' then
        if type(value)=='table' then if key~='overtime'or value.enabled then return 'custom'end
        elseif value~=false and value~=nil and value~=0 and not(key=='doomsdayClockSpeed'and value=='normal')then return 'custom'end
    end end
    return 'single'
end
function M.reward(mode,seconds,outcome)
    local mult=mode=='single'and .75 or (mode=='pvp'or mode=='coop')and 1 or 0
    if seconds<120 then return 0,0 end
    local factor=outcome=='won'and 1.2 or (outcome=='forfeit'or outcome=='expired')and .5 or 1
    local minutes=math.min(seconds,1800)/60
    return math.floor(6*minutes*mult*factor+1e-8),math.floor(2*minutes*mult*factor+1e-8)
end
function M.owns(p,owned,id,slot)
    if not C.styles[id]then return false end
    if C.get(id).access=='free' or owned[id]==true then return true end
    if slot then return p.ownedSlots[slot..':'..id]==true end
    for _,s in ipairs(C.slots)do if not p.ownedSlots[s..':'..id]then return false end end;return true
end
function M.exchange(raw,id)
    local p,err=M.decode(raw);if not p then return nil,err end
    local item;for _,v in ipairs(M.shop)do if v.id==id then item=v end end
    if not item then return nil,'unknown-item'end
    if p.unlocks[id]then return p,'already-owned'end
    if p.medals<item.price then return nil,'insufficient-medals'end
    p.medals-=item.price;p.unlocks[id]=true
    for _,slot in ipairs(item.slots or {})do p.ownedSlots[slot..':'..item.style]=true end
    if item.badge then p.achievements[item.badge]=true end
    return p
end
local function count(bucket,key,n)bucket[key]=(bucket[key]or 0)+n end
local part=Career.part
M.keepDays=14;M.keepWinDays=2
local function prune(p,today)
    local f=p.pruned or {day=0,win=0};p.pruned=f
    f.day=math.max(f.day or 0,today-M.keepDays);f.win=math.max(f.win or 0,today-M.keepWinDays)
    for day in pairs(p.daily)do if (tonumber(day)or 0)<f.day then p.daily[day]=nil end end
    for week in pairs(p.weekly)do if (tonumber(week)or 0)*7+3<f.day then p.weekly[week]=nil end end
    for day in pairs(p.firstWinDays or {})do if (tonumber(day)or 0)<f.win then p.firstWinDays[day]=nil end end
end
function M.apply(raw,event)
    local p,err=M.decode(raw);if not p then return nil,err end
    if type(event)~='table'or type(event.id)~='string'or not M.modes[event.mode]then return nil,'invalid-result'end
    local startXP=p.xp;local floor=p.pruned or {}
    local prior=p.receipts[event.id]or {revision=0,xp=0,medals=0,days={},weeks={}}
    if integer(event.revision)<=prior.revision then return p end
    local receipt=copy(prior);receipt.revision=event.revision
    if event.mode~='training'then
        local t=type(event.tactics)=='table'and event.tactics or {};local built=0
        for _,kind in ipairs({'City','DefensePost','Port','Factory','SAMLauncher','MissileSilo'})do built+=integer((t.built or {})[kind])end
        receipt.careerTotals=receipt.careerTotals or {}
        for key,value in pairs({nukes=integer(t.nukes),buildings=built,troopsProduced=integer(t.troopsProduced),countriesConquered=integer(t.countriesConquered)})do
            local old=integer(receipt.careerTotals[key]);p.lifetime[key]=integer(p.lifetime[key])+math.max(0,value-old);receipt.careerTotals[key]=math.max(old,value)
        end
    end
    local eligible=event.mode=='single'or event.mode=='pvp'or event.mode=='coop'
    if eligible then
        for day,b in pairs(event.days or {})do if (tonumber(day)or 0)>=(floor.day or 0)then
            local old=receipt.days[day]or {};local bucket=p.daily[day]or {seconds=0,cities=0,finished=0,paid={}};p.daily[day]=bucket
            for _,key in ipairs({'seconds','cities','finished'})do count(bucket,key,math.max(0,integer(b[key])-integer(old[key])))end
            receipt.days[day]=copy(b)
            for _,mission in ipairs(M.daily)do if bucket[mission.id]>=mission.target and not bucket.paid[mission.id]then bucket.paid[mission.id]=true;pend(p,'d:'..day..':'..mission.id,'daily',mission.id,mission.xp or 0,mission.reward)end end
        end end
        for week,seconds in pairs(event.weeks or {})do if (tonumber(week)or 0)*7+3>=(floor.day or 0)then
            local bucket=p.weekly[week]or {seconds=0,paid=false};p.weekly[week]=bucket
            bucket.seconds+=math.max(0,integer(seconds)-integer(receipt.weeks[week]));receipt.weeks[week]=integer(seconds)
            if bucket.seconds>=3600 and not bucket.paid then bucket.paid=true;pend(p,'w:'..week,'weekly','seconds',M.weeklyXP,M.weeklyMedals)end
        end end
        receipt.weeklyActions=receipt.weeklyActions or {}
        for week,counts in pairs(event.weeklyActions or {})do if (tonumber(week)or 0)*7+3>=(floor.day or 0)then
            local bucket=p.weekly[week]or {seconds=0,paid=false};p.weekly[week]=bucket
            local old=receipt.weeklyActions[week]or {}
            for _,key in ipairs({'cities','supports'})do count(bucket,key,math.max(0,integer(counts[key])-integer(old[key])))end
            receipt.weeklyActions[week]=copy(counts)
            for _,mission in ipairs(M.weeklyPaths)do
                if (bucket[mission.id]or 0)>=mission.target and not bucket.paid then bucket.paid=true;pend(p,'w:'..week,'weekly',mission.id,M.weeklyXP,M.weeklyMedals)end
            end
        end end
    end
    for _,m in ipairs(M.onboarding)do
        local allowed=m.id~='finish'or eligible and (event.seconds or 0)>=120 and (event.outcome=='won'or event.outcome=='lost')
        if allowed and event.milestones and event.milestones[m.id] and not p.onboarding[m.id]then p.onboarding[m.id]=true;p.xp+=m.xp;p.medals+=m.medals;part(receipt,'onboarding',m.xp,m.medals)end
    end
    if eligible then
        p.lifetime.cities+=math.max(0,integer(event.cities)-integer(receipt.cities));receipt.cities=math.max(integer(event.cities),integer(receipt.cities))
        if type(event.peak)=='number'and event.peak==event.peak then p.lifetime.peak=math.max(p.lifetime.peak or 0,math.clamp(event.peak,0,1))end
    end
    if event.outcome then
        local xp,medals=M.reward(event.mode,event.seconds or 0,event.outcome)
        if event.party==true then xp=math.floor(xp*M.partyBonus+1e-8)end
        if eligible and event.outcome=='won'and not receipt.won then
            local day=M.day(event.time or 0)
            p.firstWinDays=p.firstWinDays or {};if p.firstWinDay then p.firstWinDays[p.firstWinDay]=true end
            if not p.firstWinDays[day]and tonumber(day)>=(floor.win or 0)then p.firstWinDays[day]=true;p.xp+=M.firstWin.xp;p.medals+=M.firstWin.medals;receipt.firstWin=true;part(receipt,'firstWin',M.firstWin.xp,M.firstWin.medals)end
            if not p.firstWinDay or tonumber(day)>tonumber(p.firstWinDay)then p.firstWinDay=day end
        end
        local delta=math.max(0,xp-prior.xp)
        local finished=(event.outcome=='won'or event.outcome=='lost')and (event.seconds or 0)>=120
        if eligible then p.xp+=Career.applyMatch(p,event,receipt,delta,M.day(event.time or 0),M.week(event.time or 0),finished);Career.applyRecruit(p,finished,receipt)end
        if eligible then local paid=receipt.daily;Daily.apply(p,event,receipt);if receipt.daily and not paid then part(receipt,'dailyOp',Daily.xp,Daily.medals)end end
        if eligible and type(event.boost)=='number'and event.boost>1 then local boost=math.floor(delta*(math.min(3,event.boost)-1)+1e-8);p.xp+=boost;part(receipt,'boost',boost)end
        p.xp+=delta;p.medals+=math.max(0,medals-prior.medals);receipt.xp=math.max(xp,prior.xp);receipt.medals=math.max(medals,prior.medals)
        local normal=event.outcome=='won'or event.outcome=='lost'
        local stat=p.stats[event.mode]or {games=0,wins=0};p.stats[event.mode]=stat
        if normal and not receipt.counted then stat.games+=1;receipt.counted=true end
        if event.outcome=='won'and not receipt.won then stat.wins+=1;receipt.won=true;p.achievements['win:'..event.mode]=true;if eligible then p.achievements['map:'..event.map]=true end
            if event.mode=='pvp'and (event.humans or 1)>=2 then p.lifetime.humanWins=(p.lifetime.humanWins or 0)+1 end end
        if eligible and normal and not receipt.seasonCounted and Season.record(p,event.mode,event.outcome=='won',event.seconds or 0,event.time or 0)then receipt.seasonCounted=true end
        if event.voided==true then p.voided={id=event.id,time=integer(event.time),paid=(receipt.xp or 0)>0 or (receipt.medals or 0)>0}
        elseif event.mode~='training'then
            local row={id=event.id,mode=event.mode,map=event.map,preset=M.presetVersion,outcome=event.outcome,seconds=event.seconds or 0,peak=event.peak or 0,cities=event.cities or 0,humans=event.humans or 1,xp=receipt.xp,medals=receipt.medals,time=event.time or 0,final=event.final==true}
            for k,v in pairs(Records.row(event))do row[k]=v end
            Records.apply(p,event,receipt)
            local index;for i,r in ipairs(p.history)do if r.id==event.id then index=i;break end end
            if index then p.history[index]=row else table.insert(p.history,1,row)end
            table.sort(p.history,function(a,b)return a.time>b.time end);while #p.history>20 do table.remove(p.history)end
        end
    end
    if event.basicsComplete==true then p.basicsComplete=true end
    if eligible and type(event.map)=='string'then
        local m=p.mastery[event.map]or {games=0,wins=0,peak=0,cities=0,supports=0};p.mastery[event.map]=m
        m.cities+=math.max(0,integer(event.cities)-integer(prior.cities))
        m.supports+=math.max(0,integer(event.supports)-integer(prior.supports));receipt.supports=math.max(integer(event.supports),integer(prior.supports))
        if type(event.peak)=='number'and event.peak==event.peak then m.peak=math.max(m.peak,math.clamp(event.peak,0,1))end
        if receipt.counted and not prior.counted then m.games+=1 end
        if receipt.won and not prior.won then m.wins+=1 end
        p.conquestPaid=p.conquestPaid or {}
        local reached,paid=M.conquest(m),integer(p.conquestPaid[event.map])
        if reached>paid then p.xp+=(reached-paid)*M.conquestXP;p.conquestPaid[event.map]=reached;part(receipt,'conquest',(reached-paid)*M.conquestXP)end
        Career.applyMastery(m,paid>=#M.conquestSteps,receipt.counted and not prior.counted,receipt.won and not prior.won)
    end
    if eligible and (event.outcome=='won'or event.outcome=='lost')and (event.seconds or 0)>=120 then
        local t=type(event.tactics)=='table'and event.tactics or {};p.tactics=p.tactics or {};receipt.tactics=receipt.tactics or {}
        for _,def in ipairs(M.tactics)do
            if not receipt.tactics[def.id]and def.test(event,t)then
                receipt.tactics[def.id]=true
                local b=p.tactics[def.id]or {n=0,tier=0};p.tactics[def.id]=b;b.n+=1
                local tier=M.tacticTier(def,b.n);for i=b.tier+1,tier do p.xp+=M.tacticTierXP[i];part(receipt,'tactic',M.tacticTierXP[i])end;b.tier=math.max(b.tier,tier)
            end
        end
    end
    local medals=p.medals;Season.add(p,p.xp-startXP,event.time or 0);part(receipt,'season',0,p.medals-medals)
    p.receipts[event.id]=receipt;medals=p.medals;M.award(p);part(receipt,'achievement',0,p.medals-medals)
    if event.time then prune(p,tonumber(M.day(event.time)))end
    return p
end
function M.setGroup(raw,member)
    local p,err=M.decode(raw);if not p then return nil,err end
    local now=member==true or nil;if p.groupMember==now then return nil,'unchanged'end
    p.groupMember=now
    if not now and type(p.equipped)=='table'and p.equipped.plate==Career.groupPlate.id then p.equipped.plate=nil end
    return p
end
function M.setRecruiter(raw,inviter,self)
    local p,err=M.decode(raw);if not p then return nil,err end
    if type(inviter)~='number'or inviter<=0 or inviter%1~=0 or inviter==self then return nil,'invalid-request'end
    if p.recruit~=nil or next(p.history)~=nil then return nil,'unchanged'end
    p.recruit={by=inviter};return p
end
function M.claimRecruits(raw,ids)
    local p,err=M.decode(raw);if not p then return nil,err end
    local added=Career.claimRecruits(p,ids);if added==0 then return nil,'unchanged'end
    return p,added
end
function M.equip(raw,kind,id)
    local p,err=M.decode(raw);if not p then return nil,err end
    return Career.equip(p,M.level(p.xp),kind,id)
end
function M.view(p,now)
    local level,current,nextXP=M.level(p.xp);local today=M.day(now);local week=M.week(now)
    local daily=p.daily[today]or {seconds=0,cities=0,finished=0,paid={}};local weekly=p.weekly[week]or {seconds=0,paid=false}
    local done=0;for _,m in ipairs(M.onboarding)do if p.onboarding[m.id]then done+=1 end end
    local rankIndex,title,nextRankLevel,nextRankName=M.rank(level)
    local tactics,tacticTiers={},0
    for _,def in ipairs(M.tactics)do local b=(p.tactics or {})[def.id]or {n=0,tier=0};tacticTiers+=b.tier
        table.insert(tactics,{id=def.id,name=def.name,detail=def.detail,count=b.n,tier=b.tier,next=def.tiers[b.tier+1]})end
    local conquest,conquered,steps={},0,0
    for map,m in pairs(p.mastery)do local n=M.conquest(m);conquest[map]=n;steps+=n;if n==#M.conquestSteps then conquered+=1 end end
    local list={};local unlocked=0
    for _,a in ipairs(M.achievementList)do
        local done=p.achievements['a:'..a.id]==true;if done then unlocked+=1 end
        table.insert(list,{id=a.id,name=a.name,detail=a.detail,target=a.target,medals=a.medals,done=done,progress=math.min(a.target,M.progressOf(p,a.id))})
    end
    local login={day=p.login.day,streak=(p.login.day or -1)>=tonumber(today)-1-Career.streakGrace and p.login.streak or 0,best=p.login.best,reward=p.login.reward,claimedAt=p.login.claimedAt}
    login.claims=p.login.claims or p.login.streak or 0;login.rewardStep=login.claims>0 and (login.claims-1)%#M.streakRewards+1 or 0
    login.nextReward=M.streakRewards[login.claims%#M.streakRewards+1]
    local titles,plates=Career.unlocked(p,level)
    local equippedTitle,titleId=Career.titleOf(p,level,title);local plate,plateId=Career.plateOf(p,level)
    local total=0;for l=1,M.maxLevel-1 do total+=M.levelCost(l)end
    local service=p.xp>=total and {stars=math.floor((p.xp-total)/Career.serviceXP),current=(p.xp-total)%Career.serviceXP,next=Career.serviceXP}or nil
    local pool=type(p.weekPool)=='table'and p.weekPool.week==week and p.weekPool.used or 0
    local career={next=nil,titles={},plates={},equipped={title=titleId,plate=plateId},comradeDays=(p.comradeDays and p.comradeDays.count)or 0,
        weeklyPoolLeft=Career.weeklyPool-pool,weeklyPool=Career.weeklyPool,firstMatchReady=(p.firstMatchDay or -1)<tonumber(today),service=service,
        groupMember=p.groupMember==true,recruits=(type(p.recruits)=='table'and p.recruits.count)or 0,recruitCap=Career.recruitCap,recruitMedals=Career.recruitMedals,
        recruitPending=type(p.recruit)=='table'and not p.recruit.paid or nil}
    for l=level+1,M.maxLevel do if Career.track[l]then career.next={level=l,reward=copy(Career.track[l])};break end end
    for id,v in pairs(titles)do table.insert(career.titles,type(v)=='table'and {id=id,format=v.format,map=v.map,tier=Career.titleTier(id)}or {id=id,name=v,tier=Career.titleTier(id)})end
    for id,v in pairs(plates)do table.insert(career.plates,{id=id,name=v.name,color=copy(v.color)})end
    table.sort(career.titles,function(a,b)return a.id<b.id end);table.sort(career.plates,function(a,b)return a.id<b.id end)
    for map,m in pairs(p.mastery)do if (m.mx or 0)>0 then career.mastery=career.mastery or {};career.mastery[map]=m.mx end end
    local titleText,titleFormat,titleMap=equippedTitle,nil,nil
    if type(equippedTitle)=='table'then titleText=nil;titleFormat=equippedTitle.format;titleMap=equippedTitle.map end
    career.season=Season.view(p,now)
    career.goals=Career.goals({career=career,tactics=tactics,nextXP=nextXP,currentXP=current})
    return {career=career,dailyOp=Daily.view(p,now),titleText=titleText,titleTier=Career.titleTier(titleId),titleFormat=titleFormat,titleMap=titleMap,plate=plate and copy(plate.color)or nil,tactics=tactics,tacticTiers=tacticTiers,tacticTierMax=#M.tactics*3,rank=rankIndex,nextRankLevel=nextRankLevel,nextRankName=nextRankName,maxLevel=M.maxLevel,conquest=conquest,conquestSteps=steps,mapsConquered=conquered,achievementList=list,achievementsUnlocked=unlocked,mastery=copy(p.mastery),login=login,firstWinToday=p.firstWinDay==today,firstWin=copy(M.firstWin),
        records=Records.view(p),voided=type(p.voided)=='table'and copy(p.voided)or nil,goalClaims=copy(type(p.goalClaims)=='table'and p.goalClaims or {}),lifetime=copy(p.lifetime),xp=p.xp,medals=p.medals,level=level,title=title,currentXP=current,nextXP=nextXP,onboarding=copy(p.onboarding),onboardingDone=done,daily=copy(daily),weekly=copy(weekly),dailyReset=(tonumber(today)+1)*86400,weeklyReset=(tonumber(week)+1)*604800-3*86400,unlocks=copy(p.unlocks),ownedSlots=copy(p.ownedSlots),loadouts=copy(p.loadouts),activeLoadout=p.activeLoadout,history=copy(p.history),stats=copy(p.stats),achievements=copy(p.achievements),single=copy(p.single),lastMode=p.lastMode,tutorial=p.tutorial,basicsComplete=p.basicsComplete==true}
end
return M
