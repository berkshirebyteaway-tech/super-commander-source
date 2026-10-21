local M={}
M.version=1
M.chapters={
    {id=1,name='신병 훈련',difficulty='Easy',flames=1,minutes=8,coins=60,xp=60,title='신병 수료'},
    {id=2,name='바다와 무역',difficulty='Medium',flames=2,minutes=12,coins=80,xp=80,title='바다의 지휘관'},
    {id=3,name='외교와 경제',difficulty='Medium',flames=3,minutes=15,coins=100,xp=100,title='노련한 외교관'},
    {id=4,name='핵의 시대',difficulty='Hard',flames=4,minutes=18,coins=120,xp=120,title='억지력'},
    {id=5,name='팀 작전',difficulty='Hard',flames=4,minutes=20,coins=150,xp=150,title='팀의 기둥'},
    {id=6,name='불지옥',difficulty='Impossible',flames=5,minutes=25,coins=200,xp=200,title='불지옥 지휘관',unlockStars=60},
}
M.chests={{stars=15,coins=200},{stars=30,coins=300},{stars=45,coins=400},{stars=60,coins=500},{stars=75,coins=600}}
M.allClearPlate={kind='plate',id='campaign:hell',name='불지옥',color={214,72,48}}
M.perfectPlate={kind='plate',id='campaign:perfect',name='만점 사령관',color={232,184,72}}
local NUKES={'MissileSilo','AtomBomb','HydrogenBomb','MIRV','SAMLauncher'}
M.stages={
    {id='1-1',name='첫 확장',map='korea',nations=2,bots=20,task={kind='count',key='countriesConquered',n=10,label='부족과 국가 10곳 흡수'},
        brief='빈 땅부터 넓혀요. 병력이 차오르면 이웃 부족을 흡수해요.',tip='공격 비율은 낮게 자주 보내는 게 좋아요.'},
    {id='1-2',name='도시와 방어',map='lemnos',nations=3,bots=40,task={kind='built',unit='City',n=3,label='도시 3개 짓기'},
        brief='도시는 병력 상한을 올려요. 국경에는 방어 시설을 세워요.',tip='도시는 국경에서 먼 안쪽에 지어요.'},
    {id='1-3',name='빠른 진격',map='yellowsea',nations=3,bots=40,task={kind='share',key='earlyShare',n=.1,label='3분 안에 영토 10%'},
        brief='땅이 하나로 이어져 있어요. 부족을 빠르게 흡수하며 앞으로 밀어요.',tip='병력이 차면 바로 다음 땅으로 보내요.'},
    {id='1-4',name='첫 동맹',map='caucasus',nations=4,bots=60,task={kind='count',key='alliances',n=1,label='동맹 맺기'},
        brief='모두와 싸울 필요는 없어요. 이웃과 동맹을 맺고 한쪽에 집중해요.',tip='동맹은 기간이 끝나면 다시 맺어야 해요.'},
    {id='1-5',name='보스: 첫 정복',map='asia',nations=5,bots=80,boss=true,task={kind='share',key='earlyShare',n=.12,label='3분 안에 영토 12%'},
        brief='넓은 대륙에 국가 다섯이 기다려요. 지금까지 배운 걸 모두 써요.',tip='처음 3분에 크게 넓히면 판이 쉬워져요.'},
    {id='2-1',name='바다 건너기',map='japan',nations=3,bots=40,difficulty='Easy',task={kind='count',key='transports',n=3,label='수송선 3번 보내기'},
        brief='섬나라예요. 해안을 차지하면 수송선으로 바다를 건너요.',tip='수송선은 해안 칸을 눌러 보내요.'},
    {id='2-2',name='항구와 무역',map='caribbean',nations=4,bots=80,difficulty='Easy',task={kind='built',unit='Port',n=3,label='항구 3개 짓기'},
        brief='항구끼리 무역선이 오가며 골드를 벌어요.',tip='멀리 떨어진 항구일수록 무역 수입이 커요.'},
    {id='2-3',name='해협 장악',map='danishstraits',nations=5,bots=80,task={kind='count',key='warships',n=3,label='군함 3척 띄우기'},
        brief='좁은 해협을 군함으로 지켜요. 적 수송선을 막을 수 있어요.',tip='군함은 항구에서 만들어요.'},
    {id='2-4',name='이벤트: 전함 전함',map='warshipwarship',nations=6,bots=80,goldMultiplier=2,event=true,task={kind='count',key='fleetPeak',n=5,label='군함 5척 동시에 띄우기'},
        brief='골드가 두 배로 들어오는 넓은 바다예요. 해전으로 결판내요.',tip='항구를 여러 곳에 두면 함대를 빨리 모아요.'},
    {id='2-5',name='보스: 흑해 봉쇄',map='blacksea',nations=7,bots=100,randomSpawn=true,boss=true,task={kind='built',unit='Port',n=5,label='항구 5개 짓기'},
        brief='시작 위치가 무작위예요. 어디서 시작하든 바다를 장악해요.',tip='시작 위치를 보고 먼저 차지할 해안을 정해요.'},
    {id='3-1',name='공장과 철도',map='germany',nations=6,bots=100,task={kind='built',unit='Factory',n=3,label='공장 3개 짓기'},
        brief='공장은 철도로 도시를 잇고 기차가 골드를 날라요.',tip='도시 가까이에 공장을 지어요.'},
    {id='3-2',name='금수와 외교',map='europeclassic',nations=8,bots=100,task={kind='count',key='alliances',n=3,label='동맹 3번 맺기'},
        brief='나라가 많아요. 동맹과 금수로 판을 내 편으로 만들어요.',tip='나를 노리는 나라와는 교역을 끊어요.'},
    {id='3-3',name='이벤트: 평화 협정',map='baltics',nations=8,bots=100,startingGold=5000000,peace=2400,event=true,task={kind='share',key='earlyShare',n=.15,label='3분 안에 영토 15%'},
        brief='처음 4분은 아무도 서로를 칠 수 없어요. 그동안 크게 키워요.',tip='시작 골드로 도시와 항구부터 지어요.'},
    {id='3-4',name='배신의 땅',map='southeastasia',nations=8,bots=100,difficulty='Hard',disableAlliances=true,task={kind='built',unit='DefensePost',n=5,label='방어 시설 5개 짓기'},
        brief='동맹이 막힌 전장이에요. 혼자 버텨야 해요.',tip='국경이 긴 쪽에 방어 시설을 몰아요.'},
    {id='3-5',name='보스: 첫 세계 전장',map='world',mapSize='normal',nations=20,bots=150,difficulty='Hard',boss=true,task={kind='zero',key='nukes',label='핵 없이 승리'},
        brief='큰 세계 지도에 어려움 국가 스물이 흩어져 있어요. 처음으로 온 세계를 상대해요.',tip='공장과 항구로 골드를 모아 병력을 키워요.'},
    {id='4-1',name='미사일 기지',map='iceland',nations=5,bots=100,startingGold=5000000,task={kind='count',key='nukes',n=3,label='핵 3발 쏘기'},
        brief='미사일 기지를 지으면 원자탄을 쏠 수 있어요.',tip='적 도시가 모인 곳을 노려요.'},
    {id='4-2',name='방공망',map='mars',nations=6,bots=100,startingGold=5000000,task={kind='count',key='intercepts',n=3,label='핵 3발 요격'},
        brief='적도 핵을 쏴요. SAM으로 내 도시를 지켜요.',tip='SAM은 도시 가까이에 둬요.'},
    {id='4-3',name='수소폭탄',map='northamerica',nations=7,bots=120,startingGold=25000000,task={kind='count',key='mirv',n=1,label='MIRV 1발 쏘기'},
        brief='골드가 넉넉해요. 수소폭탄과 MIRV로 판을 뒤집어요.',tip='MIRV는 넓은 땅을 한꺼번에 흔들어요.'},
    {id='4-4',name='이벤트: 바다의 불',map='caspiansea',nations=6,bots=100,startingGold=5000000,waterNukes=true,event=true,task={kind='built',unit='SAMLauncher',n=3,label='SAM 3개 짓기'},
        brief='바다에 떨어진 핵도 낙진을 남겨요. 해안을 조심해요.',tip='해안 도시엔 SAM을 먼저 세워요.'},
    {id='4-5',name='보스: 핵 겨울',map='eastasia',mapSize='normal',nations=12,bots=150,difficulty='Impossible',startingGold=25000000,boss=true,task={kind='count',key='intercepts',n=5,label='핵 5발 요격'},
        brief='큰 지도에서 처음 만나는 불가능 국가 열둘. 모두가 처음부터 핵을 살 수 있어요.',tip='SAM 여러 개를 겹쳐 두면 잘 막아요.'},
    {id='5-1',name='2인 분대',map='australia',nations=11,bots=100,difficulty='Medium',team={format='Duos'},task={kind='count',key='supports',n=3,label='팀원에게 3번 지원'},
        brief='AI 전우와 둘이 한 팀이에요. 서로 병력과 골드를 보내요.',tip='전우가 밀리면 병력을 보내 줘요.'},
    {id='5-2',name='삼파전',map='gulfofstlawrence',nations=8,bots=100,team={format=3,teams=3},task={kind='built',unit='City',n=5,label='도시 5개 짓기'},
        brief='세 팀이 맞서요. 두 팀이 싸우는 틈을 노려요.',tip='한 팀이 크게 밀리면 그쪽을 함께 쳐요.'},
    {id='5-3',name='네 개의 섬',map='fourislands',nations=11,bots=60,team={format=4,teams=4},task={kind='count',key='transports',n=5,label='수송선 5번 보내기'},
        brief='섬마다 한 팀이에요. 바다를 건너 다른 섬을 차지해요.',tip='전우와 같은 섬부터 함께 쳐요.'},
    {id='5-4',name='이벤트: 수적 열세',map='southamerica',nations=9,bots=100,event=true,team={format=2,teams=2,nationTeams={1,1,1,2,2,2,2,2,2}},task={kind='count',key='supports',n=5,label='팀원에게 5번 지원'},
        brief='우리 넷이 적 여섯을 상대해요. 뭉쳐서 하나씩 무너뜨려요.',tip='전우와 같은 적을 동시에 쳐요.'},
    {id='5-5',name='보스: 10대10 핵전쟁',map='baikalnukewars',nations=19,bots=60,startingGold=10000000,boss=true,event=true,
        team={format=2,teams=2,nationTeams={1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2}},task={kind='count',key='intercepts',n=5,label='핵 5발 요격'},
        brief='나와 AI 전우 아홉 대 AI 열. 처음부터 모두가 핵을 쏠 수 있어요.',tip='SAM을 먼저 세우고 적 기지를 노려요.'},
    {id='6-1',name='인파 속 전장',map='hawaii',nations=8,bots=80,task={kind='share',key='earlyShare',n=.2,label='3분 안에 영토 20%'},
        brief='작은 섬에 불가능 국가 여덟이 몰렸어요. 첫 3분이 전부예요.',tip='가장 가까운 부족부터 빠르게 흡수해요.'},
    {id='6-2',name='낙하산 복불복',map='unitedstates',nations=12,bots=150,randomSpawn=true,task={kind='zero',key='alliances',label='동맹 없이 승리'},
        brief='시작 위치는 무작위, 상대는 불가능 국가 열둘이에요.',tip='시작하자마자 주변 지형부터 확인해요.'},
    {id='6-3',name='이벤트: 종말 시계',map='africa',nations=10,bots=150,doomsday='fast',event=true,task={kind='built',unit='City',n=8,label='도시 8개 짓기'},
        brief='시간이 갈수록 땅을 넓게 지키지 못하면 말라 가요.',tip='종말 경고가 뜨기 전에 영토를 넓혀 둬요.'},
    {id='6-4',name='고립무원',map='labyrinth',nations=10,bots=100,disableAlliances=true,task={kind='zero',key='nukes',label='핵 없이 승리'},
        brief='미로 같은 길, 동맹도 없어요. 길목을 막고 버텨요.',tip='좁은 길목에 방어 시설을 세워요.'},
    {id='6-5',name='최종: 세계 대전',map='world',mapSize='normal',nations=50,bots=150,boss=true,task={kind='zero',key='alliances',label='동맹 없이 승리'},
        brief='불가능 국가 쉰이 큰 세계 지도를 나눠 가졌어요. 마지막 작전이에요.',tip='한 대륙을 먼저 굳히고 바다를 건너요.'},
}
M.byId={}
for i,s in ipairs(M.stages)do s.index=i;s.chapter=tonumber(s.id:match('^(%d)'));M.byId[s.id]=s end
M.maxStars=#M.stages*3
function M.chapter(id)return M.chapters[id]end
function M.stage(id)return type(id)=='string'and M.byId[id]or nil end
local function teamFlag(s)return s.team~=nil end
function M.settings(stage)
    local ch=M.chapters[stage.chapter]
    local s={difficulty=stage.difficulty or ch.difficulty,nations=stage.nations,bots=stage.bots,startingGold=stage.startingGold or 0,
        goldMultiplier=stage.goldMultiplier or 1,customAllianceDuration=5,infiniteGold=false,infiniteTroops=false,instantBuild=false}
    local gold=s.startingGold
    s.spawnImmunityDuration=stage.peace or (gold>=25000000 and 1500)or (gold>=5000000 and 450)or nil
    if stage.mapSize then s.mapSize=stage.mapSize end
    if stage.randomSpawn then s.randomSpawn=true end
    if stage.disableAlliances then s.disableAlliances=true end
    if stage.waterNukes then s.waterNukes=true end
    if stage.doomsday then s.doomsdayClock=true;s.doomsdayClockSpeed=stage.doomsday end
    if stage.noNukes then s.disabledUnits=table.clone(NUKES)end
    if teamFlag(stage)then
        s.teamFormat=stage.team.format;s.teamCount=stage.team.teams
        if stage.team.nationTeams then s.nationTeams=table.clone(stage.team.nationTeams)end
        s.donateGold=true;s.donateTroops=true
    else
        s.overtime={enabled=true,startMinutes=30}
    end
    return s
end
function M.taskValue(stage,e)
    local t=stage.task;local tactics=type(e)=='table'and type(e.tactics)=='table'and e.tactics or {}
    if t.kind=='built'then return tonumber((tactics.built or {})[t.unit])or 0
    elseif t.kind=='share'then return tonumber(tactics[t.key])or 0
    elseif t.key=='supports'then return tonumber(e.supports)or 0
    else return tonumber(tactics[t.key])or 0 end
end
function M.taskDone(stage,e)
    local t=stage.task;local v=M.taskValue(stage,e)
    if t.kind=='zero'then return v==0 end
    return v>=t.n
end
function M.stars(stage,e)
    if not stage or type(e)~='table'or e.outcome~='won'then return 0 end
    local mask=1;local ch=M.chapters[stage.chapter]
    local t=tonumber(e.gameSeconds)
    if t and t<=ch.minutes*60 then mask+=2 end
    if M.taskDone(stage,e)then mask+=4 end
    return mask
end
function M.count(mask)mask=tonumber(mask)or 0;return (mask%2)+(mask//2%2)+(mask//4%2)end
local function state(p)
    local c=type(p.campaign)=='table'and p.campaign or {};local stars=type(c.stars)=='table'and c.stars or {}
    return c,stars
end
function M.total(p)local _,stars=state(p);local n=0;for _,s in ipairs(M.stages)do n+=M.count(stars[s.id])end;return n end
function M.cleared(p,id)local _,stars=state(p);return (tonumber(stars[id])or 0)%2==1 end
function M.chapterCleared(p,ch)
    for _,s in ipairs(M.stages)do if s.chapter==ch and not M.cleared(p,s.id)then return false end end;return true
end
function M.unlocked(p,id,justWon)
    local s=M.stage(id);if not s then return false end
    local ch=M.chapters[s.chapter]
    if ch.unlockStars and M.total(p)<ch.unlockStars then return false end
    if s.index==1 then return true end
    local prev=M.stages[s.index-1].id
    return M.cleared(p,prev)or justWon==prev
end
function M.nextStage(p)
    local _,stars=state(p)
    for _,s in ipairs(M.stages)do if (tonumber(stars[s.id])or 0)%2==0 then return s.id end end
    for _,s in ipairs(M.stages)do if M.count(stars[s.id])<3 and M.unlocked(p,s.id)then return s.id end end
    return M.stages[#M.stages].id
end
function M.owned(p)
    local titles,plates={},{}
    for _,ch in ipairs(M.chapters)do if M.chapterCleared(p,ch.id)then titles['campaign:'..ch.id]=ch.title end end
    if M.chapterCleared(p,6)then plates[M.allClearPlate.id]=M.allClearPlate end
    if M.total(p)>=M.maxStars then plates[M.perfectPlate.id]=M.perfectPlate end
    return titles,plates
end
function M.apply(p,e,part,receipt)
    local s=M.stage(e.campaign);if not s then return end
    local mask=M.stars(s,e);if mask==0 then return end
    local c=type(p.campaign)=='table'and p.campaign or {};p.campaign=c
    c.stars=type(c.stars)=='table'and c.stars or {};c.chests=math.max(0,math.floor(tonumber(c.chests)or 0))
    local old=math.floor(tonumber(c.stars[s.id])or 0)
    local merged=bit32.bor(old,mask);c.stars[s.id]=merged
    if receipt then receipt.campaign=bit32.bor(math.floor(tonumber(receipt.campaign)or 0),mask)end
    if old%2==0 then local ch=M.chapters[s.chapter];p.medals+=ch.coins;p.xp+=ch.xp;part('campaign',ch.xp,ch.coins)end
    local total=M.total(p)
    while c.chests<#M.chests and total>=M.chests[c.chests+1].stars do c.chests+=1;local chest=M.chests[c.chests];p.medals+=chest.coins;part('campaignChest',0,chest.coins)end
end
function M.view(p)
    local _,stars=state(p);local out={}
    for _,s in ipairs(M.stages)do local m=math.floor(tonumber(stars[s.id])or 0);if m>0 then out[s.id]=m end end
    local c=type(p.campaign)=='table'and p.campaign or {}
    return {stars=out,total=M.total(p),chests=math.floor(tonumber(c.chests)or 0),next=M.nextStage(p)}
end
function M.starText(mask)mask=tonumber(mask)or 0;local n=M.count(mask);return string.rep('★',n)..string.rep('☆',3-n)end
function M.rulesLine(stage)
    local ch=M.chapters[stage.chapter];local s=M.settings(stage);local out={}
    local names={Easy='쉬움',Medium='보통',Hard='어려움',Impossible='불가능'}
    if stage.team then
        local t=stage.team
        if t.nationTeams then local mine,theirs=1,0;for _,x in ipairs(t.nationTeams)do if x==1 then mine+=1 else theirs+=1 end end;table.insert(out,string.format('우리 %d 대 적 %d',mine,theirs))
        elseif t.format=='Duos'then table.insert(out,string.format('듀오 %d팀',math.ceil((stage.nations+1)/2)))
        else table.insert(out,string.format('%d팀',t.teams))end
    else table.insert(out,string.format('국가 %d',stage.nations))end
    table.insert(out,'AI '..(names[s.difficulty]or s.difficulty))
    if s.mapSize=='normal'then table.insert(out,'큰 지도')end
    if (s.startingGold or 0)>=1000000 then table.insert(out,string.format('시작 골드 %d00만',s.startingGold//1000000))end
    if (s.goldMultiplier or 1)>1 then table.insert(out,'골드 2배')end
    if stage.peace then table.insert(out,string.format('평화 %d분',stage.peace//600))end
    if s.randomSpawn then table.insert(out,'랜덤 스폰')end
    if s.disableAlliances then table.insert(out,'동맹 금지')end
    if s.waterNukes then table.insert(out,'물 위 핵')end
    if s.doomsdayClock then table.insert(out,'종말 시계')end
    return table.concat(out,'  '),ch
end
return M
