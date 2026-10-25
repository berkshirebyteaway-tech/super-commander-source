local Season=if script then require(script.Parent.SeasonRules) else require('./SeasonRules')
local Period=if script then require(script.Parent.PeriodProgress)else require('./PeriodProgress')
local Campaign=if script then require(script.Parent.CampaignRules)else require('./CampaignRules')
local M={}
M.firstMatchMultiplier=2
M.weeklyPool=300
M.returnBonus=120
M.returnDays=2
M.streakGrace=2
M.serviceXP=3000

M.plates={
    {name='강철',color={120,132,148}},{name='청동',color={176,120,72}},{name='올리브',color={128,140,72}},{name='사막',color={210,180,120}},
    {name='해군',color={52,84,150}},{name='밀림',color={52,128,84}},{name='벚꽃',color={246,150,196}},{name='은빛',color={200,208,220}},
    {name='청록',color={54,226,208}},{name='앰버',color={244,176,52}},{name='자수정',color={150,100,220}},{name='북극',color={150,220,255}},
    {name='화산',color={240,96,40}},{name='심해',color={24,60,110}},{name='백금',color={226,232,240}},{name='오로라',color={110,240,170}},
    {name='황금',color={244,196,64}},{name='흑요석',color={40,36,52}},{name='원수',color={104,108,255}},{name='전설',color={255,226,120}},
}
M.track={}
do
    local pl=0
    for level=5,100,5 do pl+=1;M.track[level]={kind='plate',id='plate:'..pl,name=M.plates[pl].name,color=M.plates[pl].color}end
end
M.comradeRewards={
    {days=3,kind='plate',id='comrade:3',name='전우',color={92,200,140}},
    {days=30,kind='plate',id='comrade:30',name='전우단',color={60,170,255}},
}
M.motions={
    {level=1,id='wave',name='손 인사',anim=507770239},
    {level=10,id='point',name='가리키기',anim=507770453},
    {level=20,id='cheer',name='환호',anim=507770677},
    {level=30,id='laugh',name='웃음',anim=507770818},
    {level=50,id='dance1',name='승전 춤',anim=507771019},
    {level=70,id='dance2',name='개선 행진 춤',anim=507776043},
    {level=100,id='dance3',name='원수의 춤',anim=507777268},
}
M.groupPlate={kind='plate',id='group:hq',name='사령부 직속',color={70,120,190}}
M.recruitMedals=1000
M.recruitCap=20
M.recruitReportGames=3
M.comradeMedals=100
M.recruiterRewards={
    {count=3,kind='plate',id='recruit:3',name='모병',color={232,150,60}},
}
M.masteryMax=50
function M.levelReward(level)return M.track[level]end
function M.between(from,to)
    local list={};for level=(from or 1)+1,math.min(to or 1,100)do if M.track[level]then table.insert(list,{level=level,reward=M.track[level]})end
        local m=M.motionAt(level);if m then table.insert(list,{level=level,reward=m})end end;return list
end
function M.motionAt(level)for _,m in ipairs(M.motions)do if m.level==level and level>1 then return {kind='motion',id=m.id,name=m.name}end end;return nil end
function M.unlocked(p,level)
    local platesOut={}
    for l=2,level do local r=M.track[l];if r then platesOut[r.id]=r end end
    local days=(p.comradeDays and p.comradeDays.count)or 0
    for _,c in ipairs(M.comradeRewards)do if days>=c.days then platesOut[c.id]=c end end
    if p.groupMember==true then platesOut[M.groupPlate.id]=M.groupPlate end
    local recruits=(type(p.recruits)=='table'and p.recruits.count)or 0
    for _,r in ipairs(M.recruiterRewards)do if recruits>=r.count then platesOut[r.id]=r end end
    for id,r in pairs(Campaign.owned(p))do platesOut[id]=r end
    for id,r in pairs(Season.owned(p))do if r.kind=='plate'then platesOut[id]=r end end
    return platesOut
end

function M.part(receipt,kind,xp,medals)
    if (xp or 0)<=0 and (medals or 0)<=0 then return end
    local parts=type(receipt.parts)=='table'and receipt.parts or {};receipt.parts=parts
    local e=parts[kind]or {x=0,m=0};parts[kind]=e;e.x+=xp or 0;e.m+=medals or 0
end
function M.applyMatch(p,event,receipt,delta,day,week,finished)
    local bonus=0
    if finished and not receipt.firstMatch and (p.firstMatchDay or -1)<tonumber(day)then
        receipt.firstMatch=true
        local last=p.lastPlayDay
        if last and tonumber(day)-last>1 then local back=math.min(M.returnDays,tonumber(day)-last-1)*M.returnBonus;bonus+=back;receipt.returned=true;M.part(receipt,'returned',back)end
        p.firstMatchDay=tonumber(day);local double=math.floor(delta*(M.firstMatchMultiplier-1)+1e-8);bonus+=double;M.part(receipt,'firstMatch',double)
    end
    if finished then p.lastPlayDay=math.max(p.lastPlayDay or 0,tonumber(day))end
    local pool=Period.select(p,'weekPool','weekPoolHistory','week',tonumber(week),8,function()return {week=week,used=0}end)
    local extra=pool and math.min(math.max(0,delta),M.weeklyPool-pool.used)or 0
    if extra>0 then pool.used+=extra;bonus+=extra;M.part(receipt,'pool',extra)end
    if finished and event.party==true then
        local c=type(p.comradeDays)=='table'and p.comradeDays or {count=0};p.comradeDays=c
        if (c.last or -1)<tonumber(day)then c.count+=1;c.last=tonumber(day);p.medals+=M.comradeMedals;M.part(receipt,'comrade',0,M.comradeMedals)end
    end
    return bonus
end
function M.applyRecruit(p,finished,receipt)
    local r=p.recruit;if not finished or type(r)~='table'or r.reported or r.paid and r.games==nil then return end
    if (r.games or 0)<M.recruitReportGames and not receipt.recruitGame then r.games=(r.games or 0)+1;receipt.recruitGame=true end
    if r.paid then return end
    r.paid=true;p.medals+=M.recruitMedals;receipt.recruited=true;M.part(receipt,'recruit',0,M.recruitMedals)
end
function M.recruitReady(r)
    return type(r)=='table'and r.paid==true and (r.games==nil or r.games>=M.recruitReportGames)
end
function M.inviteAsk(p,receipt)
    if type(receipt)~='table'or not receipt.firstWin then return nil end
    if (type(p.comradeDays)=='table'and p.comradeDays.count or 0)>0 then return nil end
    local r=type(p.recruits)=='table'and p.recruits.count or 0
    return {coins=M.recruitMedals,recruits=r,first=(r==0)}
end
function M.claimRecruits(p,ids)
    local r=type(p.recruits)=='table'and p.recruits or {count=0,ids={}};p.recruits=r;r.ids=type(r.ids)=='table'and r.ids or {}
    local added=0
    for _,id in ipairs(ids)do
        local key=tostring(id)
        if r.count>=M.recruitCap then break end
        if not r.ids[key]then r.ids[key]=true;r.count+=1;added+=1;p.medals+=M.recruitMedals end
    end
    return added
end
function M.applyMastery(m,conquered,newlyCounted,newlyWon)
    if not conquered then return end
    m.mx=(m.mx or 0)+(newlyCounted and 1 or 0)+(newlyWon and 1 or 0)
end

function M.equip(p,level,kind,id)
    if kind~='plate'then return nil,'invalid-request'end
    if type(id)~='string'or #id>64 then return nil,'invalid-request'end
    p.equipped=type(p.equipped)=='table'and p.equipped or {}
    if id==''then p.equipped.plate=nil;return p end
    if M.unlocked(p,level)[id]==nil then return nil,'locked-reward'end
    p.equipped.plate=id;return p
end
function M.plateOf(p,level)
    local id=type(p.equipped)=='table'and p.equipped.plate
    if id then local pl=M.unlocked(p,level);if pl[id]then return pl[id],id end end
    return nil,nil
end
function M.rewardLabel(r)return r.kind=='motion'and string.format('모션 「%s」',r.name)or string.format('%s 명판',r.name)end
function M.goals(v)
    local out={};local c=v.career or {}
    if c.next and (v.nextXP or 0)>0 then local m=M.motionAt(c.next.level)
        table.insert(out,string.format('Lv. %d 보상까지 %d XP  %s',c.next.level,math.max(0,v.nextXP-(v.currentXP or 0)),M.rewardLabel(c.next.reward)..(m and ' + '..M.rewardLabel(m)or '')))end
    local best;for _,t in ipairs(v.tactics or {})do if t.next then local left=t.next-t.count;if not best or left<best.left then best={t=t,left=left}end end end
    if best then table.insert(out,string.format('%s 단계까지 %d판  %s',string.rep('★',best.t.tier+1),best.left,best.t.name))end
    if c.season and c.season.next then table.insert(out,string.format('%s %d점까지 %d점  %d 코인',c.season.name,c.season.next.score,math.max(0,c.season.next.left or 0),c.season.next.coins))end
    if (c.weeklyPoolLeft or 0)>0 then table.insert(out,string.format('이번 주 2배 XP %d 남음',c.weeklyPoolLeft))end
    for _,r in ipairs(M.comradeRewards)do if (c.comradeDays or 0)<r.days then table.insert(out,string.format('친구와 함께한 날 %d/%d  %s',c.comradeDays or 0,r.days,M.rewardLabel(r)));break end end
    while #out>3 do table.remove(out)end
    return out
end
return M
