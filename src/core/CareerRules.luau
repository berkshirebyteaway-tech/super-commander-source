local Season=if script then require(script.Parent.SeasonRules) else require('./SeasonRules')
local Daily=if script then require(script.Parent.DailyOperation) else require('./DailyOperation')
local Period=if script then require(script.Parent.PeriodProgress)else require('./PeriodProgress')
local M={}
M.firstMatchMultiplier=2
M.weeklyPool=300
M.returnBonus=120
M.returnDays=2
M.streakGrace=2
M.serviceXP=3000

local titles={
    '풋내기','길잡이','전령','척후병','보급관','참호쥐','측량사','공병','경계병','철도꾼','파수꾼','기습조','공장장','항만장','돌격대장',
    '올빼미','매복꾼','사막여우','하늘지기','매의 눈','조타수','협상가','철벽','불도저','섬사냥꾼','교두보','협공','쇄빙선','늑대무리','고지왕','전술가',
    '카운터펀치','유령','화약고','망치','모루','봉쇄선','무역왕','철도 재벌','강철심장','질풍','불침번','포커페이스','전격전','작전통','레드라인','한 수 위',
    '승부사','백전노장','이지스','강철비','폭풍전선','만리장성','해상왕','대함대','저거너트','난공불락','불사조','킹메이커','흑막','게임체인저','정복자','워로드',
    '최후의 보루','체크메이트','불패','오버로드','그랜드마스터','대전략가','명예의 전당','군신','최종 보스','패왕','세계정복자','천하통일','전설','살아있는 전설','불멸','차기 원수',
}
M.plates={
    {name='강철',color={120,132,148}},{name='청동',color={176,120,72}},{name='올리브',color={128,140,72}},{name='사막',color={210,180,120}},
    {name='해군',color={52,84,150}},{name='밀림',color={52,128,84}},{name='벚꽃',color={246,150,196}},{name='은빛',color={200,208,220}},
    {name='청록',color={54,226,208}},{name='앰버',color={244,176,52}},{name='자수정',color={150,100,220}},{name='북극',color={150,220,255}},
    {name='화산',color={240,96,40}},{name='심해',color={24,60,110}},{name='백금',color={226,232,240}},{name='오로라',color={110,240,170}},
    {name='황금',color={244,196,64}},{name='흑요석',color={40,36,52}},{name='원수',color={104,108,255}},{name='전설',color={255,226,120}},
}
M.track={}
do
    local t,pl=0,0
    for level=2,100 do
        if level%5==0 then pl+=1;M.track[level]={kind='plate',id='plate:'..pl,name=M.plates[pl].name,color=M.plates[pl].color}
        else t+=1;M.track[level]={kind='title',id='lv:'..level,name=titles[t]}end
    end
end
M.streakTitles={{days=7,id='streak:7',name='개근'},{days=30,id='streak:30',name='단골'},{days=100,id='streak:100',name='터줏대감'}}
M.comradeRewards={
    {days=1,kind='title',id='comrade:1',name='버디'},
    {days=3,kind='plate',id='comrade:3',name='전우',color={92,200,140}},
    {days=7,kind='title',id='comrade:7',name='윙맨'},
    {days=14,kind='title',id='comrade:14',name='의리'},
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
M.recruitMedals=150
M.recruitCap=20
M.recruitedTitle={kind='title',id='recruit:joined',name='합류'}
M.recruiterRewards={
    {count=1,kind='title',id='recruit:1',name='모병관'},
    {count=3,kind='plate',id='recruit:3',name='모병',color={232,150,60}},
    {count=10,kind='title',id='recruit:10',name='골목대장'},
}
M.masteryTitles={{points=10,format='%s 베테랑'},{points=25,format='%s 에이스'},{points=50,format='%s의 전설'}}
M.masteryMax=50
M.titleTiers={'신병','야전','지휘','명장','전설'}
M.specialTiers={['streak:7']=2,['streak:30']=3,['streak:100']=4,['daily:7']=2,['daily:30']=3,['daily:100']=4,
    ['comrade:1']=1,['comrade:7']=2,['comrade:14']=3,['recruit:joined']=1,['recruit:1']=2,['recruit:10']=3,
    ['s0:t5']=2,['s0:t15']=3,['s0:t25']=4}
function M.titleTier(id)
    if type(id)~='string'or id==''or id=='none'then return 0 end
    local lv=tonumber(id:match('^lv:(%d+)$'));if lv then return math.clamp(math.floor(lv/20)+1,1,5)end
    local step=tonumber(id:match('^mastery:.+:(%d+)$'));if step then return math.clamp(step+1,2,4)end
    if M.specialTiers[id]then return M.specialTiers[id]end
    local st=tonumber(id:match('^s%d+:t(%d+)$'));if st and Season.monthlyTitleTiers[st]then return Season.monthlyTitleTiers[st]end
    return 2
end

function M.levelReward(level)return M.track[level]end
function M.between(from,to)
    local list={};for level=(from or 1)+1,math.min(to or 1,100)do if M.track[level]then table.insert(list,{level=level,reward=M.track[level]})end
        local m=M.motionAt(level);if m then table.insert(list,{level=level,reward=m})end end;return list
end
function M.motionAt(level)for _,m in ipairs(M.motions)do if m.level==level and level>1 then return {kind='motion',id=m.id,name=m.name}end end;return nil end
function M.unlocked(p,level)
    local titlesOut,platesOut={},{}
    for l=2,level do local r=M.track[l];if r.kind=='title'then titlesOut[r.id]=r.name else platesOut[r.id]=r end end
    local best=(p.login and p.login.best)or 0
    for _,s in ipairs(M.streakTitles)do if best>=s.days then titlesOut[s.id]=s.name end end
    local days=(p.comradeDays and p.comradeDays.count)or 0
    for _,c in ipairs(M.comradeRewards)do if days>=c.days then if c.kind=='title'then titlesOut[c.id]=c.name else platesOut[c.id]=c end end end
    if p.groupMember==true then platesOut[M.groupPlate.id]=M.groupPlate end
    if type(p.recruit)=='table'and p.recruit.paid then titlesOut[M.recruitedTitle.id]=M.recruitedTitle.name end
    local recruits=(type(p.recruits)=='table'and p.recruits.count)or 0
    for _,r in ipairs(M.recruiterRewards)do if recruits>=r.count then if r.kind=='title'then titlesOut[r.id]=r.name else platesOut[r.id]=r end end end
    local opDays=(type(p.dailyOp)=='table'and p.dailyOp.days)or 0
    for _,t in ipairs(Daily.titles)do if opDays>=t.days then titlesOut[t.id]=t.name end end
    for id,r in pairs(Season.owned(p))do if r.kind=='title'then titlesOut[id]=r.name else platesOut[id]=r end end
    for map,m in pairs(p.mastery or {})do for i,mt in ipairs(M.masteryTitles)do if (m.mx or 0)>=mt.points then titlesOut['mastery:'..map..':'..i]={format=mt.format,map=map}end end end
    return titlesOut,platesOut
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
        if (c.last or -1)<tonumber(day)then c.count+=1;c.last=tonumber(day)end
    end
    return bonus
end
function M.applyRecruit(p,finished,receipt)
    local r=p.recruit;if not finished or type(r)~='table'or r.paid then return end
    r.paid=true;p.medals+=M.recruitMedals;receipt.recruited=true;M.part(receipt,'recruit',0,M.recruitMedals)
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
    if kind~='title'and kind~='plate'then return nil,'invalid-request'end
    if type(id)~='string'or #id>64 then return nil,'invalid-request'end
    p.equipped=type(p.equipped)=='table'and p.equipped or {}
    if id==''then p.equipped[kind]=nil;return p end
    if kind=='title'and id=='none'then p.equipped.title='none';return p end
    local t,pl=M.unlocked(p,level)
    if (kind=='title'and t[id]==nil)or(kind=='plate'and pl[id]==nil)then return nil,'locked-reward'end
    p.equipped[kind]=id;return p
end
function M.titleOf(p,level,rankName)
    local id=type(p.equipped)=='table'and p.equipped.title
    if id=='none'then return '',id end
    if id then local t=M.unlocked(p,level);local v=t[id];if type(v)=='string'then return v,id elseif type(v)=='table'then return v,id end end
    return rankName,nil
end
function M.plateOf(p,level)
    local id=type(p.equipped)=='table'and p.equipped.plate
    if id then local _,pl=M.unlocked(p,level);if pl[id]then return pl[id],id end end
    return nil,nil
end
function M.rewardLabel(r)return r.kind=='plate'and string.format('%s 명판',r.name)or r.kind=='motion'and string.format('모션 「%s」',r.name)or string.format('칭호 「%s」',r.name)end
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
