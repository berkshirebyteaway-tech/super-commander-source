local Terrain=if script then require(script.Parent.Terrain)else require('./Terrain')
local M={}
M.maxHints=3
M.byStage={
    ['1-1']={title='첫 작전',learned='빈 땅부터 넓히고 부족을 흡수해요'},
    ['1-2']={title='충원의 법칙',art='growth',learned='병력은 절반쯤에서 가장 빨리 차요',
        lines={'병력이 상한의 절반쯤일 때 가장 빨리 차요.','꽉 차면 멈춰요. 초록일 때 보내요.'},
        hints={{id='full',text='병력이 거의 꽉 찼어요. 충원이 멈춰요. 지금 보내요',focus='troops'},
            {id='low',text='병력이 너무 적어요. 충원이 느려요. 잠깐 모아요',focus='troops'}}},
    ['1-3']={title='넓을수록 큰 군대',art='area',learned='땅이 넓을수록, 도시가 많을수록 상한이 커요',
        lines={'땅이 넓을수록 병력 상한이 올라가요.','도시 하나마다 상한 +25,000이에요.'},
        hints={{id='double',text='땅이 두 배가 됐어요. 병력 상한도 올랐어요',focus='troops'},
            {id='city',text='도시 지을 골드가 모였어요. 도시는 상한을 +25,000 올려요',focus='build'}}},
    ['1-4']={title='험한 땅',art='terrain',learned='산은 느리고 병력이 많이 들어요',
        lines={'평지 1배, 언덕 1.2배, 산 1.5배.','산은 느리고 병력도 많이 들어요. 평지부터 차지해요.'},
        hints={{id='mountain',text='산을 넘는 중이에요. 느리고 병력이 많이 들어요. 평지로 돌아가면 빨라요'}}},
    ['1-5']={title='작게 자주',art='ratio',learned='공격은 작게 자주 보내야 국경이 안 비어요',
        lines={'한 번에 다 보내면 국경이 비어요.','공격 비율을 낮춰 자주 보내요.'},
        hints={{id='allIn',text='병력을 거의 다 보냈어요. 국경이 비면 역습을 받아요'}}},
    ['2-1']={title='방어 시설',art='defense',learned='방어 시설 근처를 치면 병력을 5배 잃어요',
        lines={'방어 시설 근처를 치는 적은 병력을 5배 잃어요.','공격받는 국경과 길목에 세워요.'},
        hints={{id='underAttack',text='공격받고 있어요. 그 국경에 방어 시설을 세워요',focus='build'}}},
    ['2-2']={title='기차가 골드를 날라요',art='rail',learned='공장은 철도를 깔고 기차가 골드를 벌어요',
        lines={'공장을 지으면 도시와 항구로 철도가 깔려요.','기차가 설 때마다 골드가 들어와요.'},
        hints={{id='factory',text='도시가 두 곳이에요. 그 사이에 공장을 지으면 철도가 깔려요',focus='build'}}},
    ['2-3']={title='동맹 철도',art='allyRail',learned='동맹 도시에 서는 기차가 더 많이 벌어요',
        lines={'동맹 도시에 서는 기차는 3만 5천,','내 도시는 1만. 동맹 쪽으로 철도를 이어요.'},
        hints={{id='allyRail',text='동맹이 생겼어요. 동맹 국경 가까이 공장을 지으면 기차가 더 벌어요',focus='build'}}},
    ['2-4']={title='평화 시간',art='peace',learned='핵이 막힌 4분 동안 경제를 먼저 키워요',
        lines={'처음 4분은 아무도 핵을 못 쏴요.','그동안 도시와 공장을 먼저 지어요.'}},
    ['2-5']={title='정복 골드',art='conquer',learned='국가를 정복하면 그 나라 골드를 다 가져와요',
        lines={'국가를 정복하면 그 나라 골드를 모두 가져와요.','약한 이웃부터 정복해요.'}},
    ['3-1']={title='수송선',art='boat',learned='해안에서 수송선으로 바다를 건너요',
        lines={'해안 너머 땅을 누르면 수송선이 떠요.','바다 건너 섬도 내 땅이 돼요.'},
        hints={{id='boat',text='바다 건너 땅을 누르면 수송선으로 건너가요'}}},
    ['3-2']={title='멀수록 많이 벌어요',art='trade',learned='항구가 멀수록 무역선이 많이 벌어요',
        lines={'항구끼리 무역선이 오가며 골드를 벌어요.','항구 사이가 멀수록 한 번에 더 벌어요.'},
        hints={{id='farPort',text='첫 항구가 생겼어요. 멀리 떨어진 해안에 하나 더 지어요',focus='build'}}},
    ['3-3']={title='무역선을 빼앗아요',art='capture',learned='군함은 적 무역선을 빼앗아요',
        lines={'군함 근처를 지나는 적 무역선은 내 것이 돼요.','적 수송선도 막아요.'},
        hints={{id='warship',text='적 무역선이 지나가요. 항구에서 군함을 만들면 빼앗을 수 있어요',focus='build'},
            {id='hunt',text='군함을 적 무역선 길목으로 보내요'}}},
    ['3-4']={title='함대',art='fleet',learned='항구 여러 곳에서 군함을 모아 바다를 지켜요',
        lines={'골드가 두 배로 들어와요.','항구 여러 곳에서 군함을 모아요.'}},
    ['3-5']={title='바다 장악',art='blockade',learned='해안마다 항구를 두면 바다를 장악해요',
        lines={'시작 위치가 무작위예요.','해안마다 항구를 지어 바다를 잡아요.'}},
    ['4-1']={title='동맹',art='ally',learned='동맹이면 한쪽 국경은 안심해요',
        lines={'동맹과는 서로 공격할 수 없어요.','한쪽 국경을 비우고 반대쪽에 집중해요.'},
        hints={{id='request',text='동맹 요청이 왔어요. 받으면 그쪽 국경은 안심해요'}}},
    ['4-2']={title='금수',art='embargo',learned='나를 치는 나라와 교역을 끊어요',
        lines={'교역을 끊으면 그 나라 무역선과 기차가 못 와요.','나를 노리는 나라의 수입을 줄여요.'},
        hints={{id='embargo',text='나를 공격하는 나라와 아직 교역 중이에요. 나라를 눌러 교역을 끊어요'}}},
    ['4-3']={title='배신의 대가',art='traitor',learned='배신자는 30초 동안 쉽게 뚫려요',
        lines={'동맹을 깨면 30초 동안 배신자가 돼요.','그동안 그 나라 땅은 쉽게 뚫려요.'},
        hints={{id='traitor',text='배신한 나라가 있어요. 30초 동안 쉽게 뚫려요. 지금 쳐요'}}},
    ['4-4']={title='혼자 버티기',art='alone',learned='동맹이 없으면 방어 시설로 국경을 지켜요',
        lines={'이 전장은 동맹을 맺을 수 없어요.','긴 국경에 방어 시설을 몰아 세워요.'}},
    ['4-5']={title='세계 전장',art='combo',learned='번 골드로 도시를 늘리면 군대가 커져요',
        chain={{'Factory','공장'},{'Port','항구','+'},{'Gold','골드','→'},{'City','도시','→'},{'Soldier','병력 상한','→'}},
        lines={'국가 스물이 세계에 흩어졌어요.','번 골드로 도시를 늘려 군대를 키워요.'}},
    ['5-1']={title='미사일 기지',art='nuke',learned='기지에서 핵을 쏘고, 맞은 땅엔 낙진이 남아요',
        lines={'미사일 기지가 있으면 원자탄을 쏠 수 있어요.','동맹에게 쏘면 동맹이 깨져요.'},
        hints={{id='silo',text='미사일 기지가 준비됐어요. 적 도시가 모인 곳을 노려요'}}},
    ['5-2']={title='방공망',art='sam',learned='SAM이 날아오는 핵을 요격해요',
        lines={'SAM은 날아오는 핵을 쏴서 떨어뜨려요.','도시 가까이에 세워요.'},
        hints={{id='enemySilo',text='적에게 미사일 기지가 있어요. 도시 옆에 SAM을 세워요',focus='build'}}},
    ['5-3']={title='수소폭탄과 MIRV',art='mirv',learned='MIRV는 넓은 땅을 한꺼번에 흔들어요',
        lines={'수소폭탄은 더 넓게 터져요.','MIRV는 여러 곳에 한꺼번에 떨어져요.'}},
    ['5-4']={title='바다가 되는 땅',art='waterNuke',learned='이 전장은 핵 맞은 땅이 바다가 돼요',
        lines={'핵 맞은 땅은 바다로 바뀌어요.','해안 도시 옆에 SAM부터 세워요.'}},
    ['5-5']={title='겹친 방공망',art='samStack',learned='SAM 여러 개를 겹쳐 두면 핵을 더 막아요',
        lines={'SAM은 한 발 쏘면 잠시 장전해요.','도시 둘레에 SAM을 겹쳐 둬요.'}},
    ['6-1']={title='지원',art='support',learned='전우에게 병력과 골드를 보낼 수 있어요',
        lines={'팀원 나라를 눌러 병력과 골드를 보내요.','팀 땅이 80%를 넘으면 이겨요.'},
        hints={{id='donate',text='병력이 넉넉해요. 밀리는 전우에게 보내 줘요'}}},
    ['6-2']={title='틈을 노려요',art='threeWay',learned='두 팀이 싸울 때 약해진 쪽을 쳐요',
        lines={'세 팀이 맞서요.','두 팀이 싸우는 틈에 약한 쪽을 쳐요.'}},
    ['6-3']={title='섬 건너기',art='islands',learned='전우와 같은 섬으로 함께 건너요',
        lines={'섬마다 한 팀이에요.','전우와 같은 섬으로 함께 건너요.'}},
    ['6-4']={title='집중 공격',art='focus',learned='전우와 같은 적을 함께 쳐요',
        lines={'우리 넷이 적 여섯을 상대해요.','전우와 같은 적을 함께 쳐요.'}},
    ['6-5']={title='팀 방공망',art='teamNuke',learned='SAM으로 버티고 적 미사일 기지를 노려요',
        lines={'처음부터 모두 핵을 쏠 수 있어요.','SAM을 먼저 세우고 적 기지를 노려요.'}},
    ['7-1']={title='첫 3분',art='rush',learned='첫 3분에 가까운 부족부터 흡수해요',
        lines={'작은 섬에 불가능 국가 여덟이에요.','첫 3분에 가까운 부족부터 흡수해요.'}},
    ['7-2']={title='무작위 낙하',art='randomDrop',learned='어디에 떨어져도 주변 지형부터 봐요',
        lines={'시작 위치가 무작위예요.','떨어지면 주변 지형부터 확인해요.'}},
    ['7-3']={title='종말 시계',art='doomsday',learned='지켜야 할 땅은 시간이 갈수록 늘어요',
        lines={'시간이 갈수록 지켜야 할 땅이 늘어요.','모자라면 병력이 빠지고 땅이 말라요.'}},
    ['7-4']={title='길목',art='chokepoint',learned='좁은 길목을 막으면 넓은 땅이 안전해요',
        lines={'미로 같은 길에 동맹도 없어요.','좁은 길목에 방어 시설을 세워요.'}},
    ['7-5']={title='최종 작전',art='continent',learned='한 대륙을 굳히고 바다를 건너요',
        lines={'불가능 국가 쉰이 세계를 나눠 가졌어요.','한 대륙을 굳히고 바다를 건너요.'}},
}
function M.of(id)return type(id)=='string'and M.byStage[id]or nil end
local function mine(s,kind,done)
    local n=0
    for _,u in ipairs(s.units or {})do if u.owner==1 and u.kind==kind and u.active~=false and not u.deleteAt and (not done or not u.building)then n+=1 end end
    return n
end
local function theirs(s,kind)
    for _,u in ipairs(s.units or {})do if u.owner~=1 and u.kind==kind and u.active~=false then return u end end
end
local function gold(v)return tonumber(v)or 0 end
local function terrainAt(map,tile)
    local t=map and map.terrain;if not t or type(tile)~='number'then return nil end
    if type(t)=='buffer'then if tile<0 or tile>=buffer.len(t)then return nil end;return buffer.readu8(t,tile)end
    return t[tile+1]
end
function M.check(id,s,memo,now,map)
    local p=s.player;if not p or (p.tiles or 0)<=0 or s.phase~='playing'then return nil end
    memo.startTiles=memo.startTiles or p.tiles;memo.startAt=memo.startAt or now
    local ratio=(p.troops or 0)/math.max(1,p.cap or 0)
    local function held(key,cond,seconds)
        if not cond then memo[key]=nil;return false end
        memo[key]=memo[key]or now;return now-memo[key]>=seconds
    end
    if id=='1-2'then
        if held('fullAt',ratio>=.85,10)then return 'full'end
        if now-memo.startAt>60 and held('lowAt',ratio<.15,8)then return 'low'end
    elseif id=='1-3'then
        if p.tiles>=memo.startTiles*2 and p.tiles>=memo.startTiles+40 then return 'double'end
        local cost=s.costs and s.costs.City
        if cost and mine(s,'City')==0 and gold(p.gold)>=gold(cost)then return 'city'end
    elseif id=='1-4'then
        for _,o in ipairs(s.operations or {})do
            if o.direction=='outgoing'and o.kind=='land'then
                local b=terrainAt(map,o.frontTile)
                if b and Terrain.isLand(b)and Terrain.magnitude(b)>=20 and Terrain.magnitude(b)<31 then
                    if held('mountainAt',true,3)then return 'mountain'end;return nil
                end
            end
        end
        memo.mountainAt=nil
    elseif id=='1-5'then
        for _,o in ipairs(s.operations or {})do
            if o.direction=='outgoing'and o.kind=='land'and o.target~=0 and (o.troops or 0)>math.max(1,p.troops or 0)*4 then return 'allIn'end
        end
    elseif id=='2-1'then
        for _,o in ipairs(s.operations or {})do if o.direction=='incoming'and mine(s,'DefensePost')==0 then return 'underAttack'end end
    elseif id=='2-2'then
        if mine(s,'City',true)>=2 and mine(s,'Factory')==0 then return 'factory'end
    elseif id=='2-3'then
        local allied=false;for _,f in ipairs(s.factions or {})do if f.allied and f.id~=1 then allied=true;break end end
        if allied and mine(s,'Factory')==0 then return 'allyRail'end
    elseif id=='3-1'then
        if now-memo.startAt>90 and (s.naval and s.naval.transports or 0)==0 and not memo.sailed then return 'boat'end
        if (s.naval and s.naval.transports or 0)>0 then memo.sailed=true end
    elseif id=='3-2'then
        if mine(s,'Port',true)==1 then return 'farPort'end
    elseif id=='3-3'then
        if theirs(s,'TradeShip')and mine(s,'Port',true)>0 then return mine(s,'Warship')==0 and 'warship'or 'hunt'end
    elseif id=='4-1'then
        if s.diplomacy and s.diplomacy.incoming and #s.diplomacy.incoming>0 then return 'request'end
    elseif id=='4-2'then
        for _,o in ipairs(s.operations or {})do if o.direction=='incoming'and o.owner and o.owner~=0 then
            for _,f in ipairs(s.factions or {})do if f.id==o.owner and f.kind~='BOT'and not f.embargoed then return 'embargo'end end
        end end
    elseif id=='4-3'then
        for _,f in ipairs(s.factions or {})do if f.id~=1 and f.traitorUntil then return 'traitor'end end
    elseif id=='5-1'then
        if mine(s,'MissileSilo',true)>0 then return 'silo'end
    elseif id=='5-2'then
        if theirs(s,'MissileSilo')and mine(s,'SAMLauncher')==0 then return 'enemySilo'end
    elseif id=='6-1'then
        if ratio>.6 then for _,f in ipairs(s.factions or {})do if f.teammate and f.canDonateTroops then return 'donate'end end end
    end
    return nil
end
function M.hint(id,key)
    local l=M.of(id);if not l or not l.hints then return nil end
    for _,h in ipairs(l.hints)do if h.id==key then return h end end
end
return M
