local Catalog=if script then require(script.Parent.Parent.Maps.Catalog)else require('../maps/Catalog')
local Challenge=if script then require(script.Parent.SoloChallenge)else require('./SoloChallenge')
local M={}
M.medals=60
M.xp=150
M.titles={{days=7,id='daily:7',name='당직'},{days=30,id='daily:30',name='현역'},{days=100,id='daily:100',name='말뚝'}}
M.conditions={
    {id='standard',name='표준 작전',settings={difficulty='Medium',nations=5,bots=120,startingGold=0}},
    {id='hard',name='강적 출현',settings={difficulty='Hard',nations=7,bots=120,startingGold=0}},
    {id='crowded',name='인파 속 전장',settings={difficulty='Medium',nations=8,bots=300,startingGold=0}},
    {id='rich',name='넉넉한 국고',settings={difficulty='Hard',nations=7,bots=120,startingGold=1000000}},
    {id='lonely',name='개척 경쟁',settings={difficulty='Medium',nations=3,bots=200,startingGold=0}},
}
local pool
local function maps()
    if pool then return pool end
    pool={}
    for _,m in ipairs(Catalog)do
        if (m.rotationWeight or 0)>0 and m.category~='아케이드'and (m.landTiles or 0)<=400000 and (m.landTiles or 0)>=40000 then table.insert(pool,m.key)end
    end
    table.sort(pool);return pool
end
local function mul(a,b)return ((a*(b//65536)%65536)*65536+a*(b%65536))%4294967296 end
local function hash(n)
    local h=2166136261;local s=tostring(n)
    for i=1,#s do h=mul(bit32.bxor(h,string.byte(s,i)),16777619)end
    h=bit32.bxor(h,bit32.rshift(h,16));h=mul(h,0x85ebca6b);h=bit32.bxor(h,bit32.rshift(h,13));h=mul(h,0xc2b2ae35)
    return bit32.bxor(h,bit32.rshift(h,16))
end
function M.day(time)return math.floor(time/86400)end
function M.of(day)
    local list=maps();local h=hash('op'..day)
    local cond=M.conditions[hash('c'..day)%#M.conditions+1]
    local key=list[h%#list+1];local meta
    for _,m in ipairs(Catalog)do if m.key==key then meta=m;break end end
    local settings=Challenge.resolve(meta,cond.settings)
    settings.customAllianceDuration=5;settings.goldMultiplier=1;settings.infiniteGold=false;settings.infiniteTroops=false;settings.instantBuild=false
    settings.maxTimerValue=20;settings.randomSpawn=true
    return {day=day,map=key,condition=cond.id,conditionName=cond.name,seed=string.format('daily-%d-%08x',day,h),settings=settings}
end
function M.score(event)
    if event.outcome=='won'then return 1000000+math.max(0,3600-math.floor(event.gameSeconds or event.seconds or 0))end
    if event.outcome=='lost'and (event.seconds or 0)>=120 then return math.floor(math.clamp(event.peak or 0,0,1)*100000)end
    return nil
end
function M.label(score)
    if not score then return '-'end
    if score>=1000000 then local s=3600-(score-1000000);return string.format('★ %d:%02d',s//60,s%60)end
    return string.format('%.1f%%',score/1000)
end
function M.apply(p,event,receipt)
    local day=event.daily;if type(day)~='number'or day%1~=0 then return end
    local score=M.score(event);if not score then return end
    local d=type(p.dailyOp)=='table'and p.dailyOp or {days=0};p.dailyOp=d
    if day>(d.bestDay or -1)or day==d.bestDay and score>(d.best or -1)then d.bestDay=day;d.best=score end
    if (d.paid or -1)<day and not receipt.daily then
        d.paid=day;d.days=(d.days or 0)+1;receipt.daily=true
        p.medals+=M.medals;p.xp+=M.xp
    end
end
function M.view(p,now)
    local today=M.day(now);local d=type(p.dailyOp)=='table'and p.dailyOp or {}
    local op=M.of(today)
    return {day=today,map=op.map,conditionName=op.conditionName,best=d.bestDay==today and d.best or nil,bestLabel=M.label(d.bestDay==today and d.best or nil),
        done=d.paid==today,days=d.days or 0,medals=M.medals,xp=M.xp,resetIn=(today+1)*86400-now}
end
function M.current(v,now)
    if type(v)~='table'or v.day==M.day(now)then return v end
    return M.view({dailyOp={days=v.days}},now)
end
return M
