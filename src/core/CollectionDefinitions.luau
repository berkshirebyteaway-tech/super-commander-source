local Standards=if script then require(script.Parent.CommanderStandardRules)else require('./CommanderStandardRules')
local M={version=5}
M.series={
    {id='carbon',name='카본',rarity='normal',tier=1,primary={48,57,70},secondary={151,165,180},accent={185,198,211}},
    {id='cobalt',name='코발트',rarity='rare',tier=2,primary={35,57,88},secondary={175,202,231},accent={80,165,255}},
    {id='pulse',name='펄스',rarity='epic',tier=3,primary={48,34,76},secondary={198,181,234},accent={173,119,255}},
    {id='solaris',name='솔라리스',rarity='legendary',tier=4,primary={35,43,58},secondary={235,206,133},accent={255,207,91}},
    {id='parallax',name='패러독스',rarity='mythic',tier=5,primary={39,53,70},secondary={225,237,247},accent={157,242,235}},
    {id='venom',name='베놈',rarity='epic',tier=3,primary={26,44,32},secondary={170,236,150},accent={120,230,90}},
    {id='tidal',name='타이달',rarity='epic',tier=3,primary={18,44,62},secondary={160,226,240},accent={60,200,230}},
    {id='ember',name='엠버',rarity='epic',tier=3,primary={46,30,24},secondary={255,196,130},accent={255,140,50}},
    {id='storm',name='스톰',rarity='epic',tier=3,primary={30,36,52},secondary={210,224,255},accent={140,180,255}},
    {id='crown',name='크라운',rarity='legendary',tier=4,primary={30,34,64},secondary={250,232,170},accent={255,204,70}},
    {id='phoenix',name='피닉스',rarity='legendary',tier=4,primary={70,30,18},secondary={255,224,150},accent={255,170,40}},
    {id='eclipse',name='이클립스',rarity='mythic',tier=5,primary={10,10,18},secondary={235,230,255},accent={200,120,255}},
    {id='dragon',name='청룡',rarity='legendary',tier=4,primary={18,58,60},secondary={170,240,215},accent={255,206,90}},
    {id='diamond',name='다이아몬드',rarity='legendary',tier=4,primary={226,236,246},secondary={170,215,255},accent={255,214,120}},
    {id='seraph',name='세라핌',rarity='mythic',tier=5,primary={244,244,252},secondary={255,232,170},accent={255,143,216}},
    {id='glitch',name='글리치',rarity='mythic',tier=5,primary={8,10,16},secondary={80,240,255},accent={255,90,220}},
    {id='leviathan',name='리바이어던',rarity='mythic',tier=5,primary={6,20,36},secondary={60,240,220},accent={170,120,255}},
}
M.order={};for i,s in ipairs(M.series)do M.order[i]=s end
table.sort(M.order,function(a,b)if a.tier~=b.tier then return a.tier<b.tier end return table.find(M.series,a)<table.find(M.series,b)end)
M.families={
    {id='territory',name='영토',slots={'territory'},icon='fields'},
    {id='buildings',name='건물',slots={'city','defensePost'},icon='fields'},
    {id='nuclear',name='핵',slots={'projectile','trail','impact'},icon='deploy'},
    {id='commanderTrail',name='트레일',slots={'commanderTrail'},icon='wave'},
    {id='parachute',name='낙하산',slots={'parachute'},icon='solo'},
    {id='vehicle',name='탈것',slots={'vehicle'},icon='deploy'},
    {id='motion',name='지휘 연출',slots={'commanderOrder'},icon='point'},
}
M.features={
    [1]={geometry=1,motion=0,light=0,sound=false,arrival=0,phases=1,particlesPC=0,particlesPhone=0},
    [2]={geometry=2,motion=0,light=1,sound=false,arrival=0,phases=1,particlesPC=20,particlesPhone=10},
    [3]={geometry=3,motion=1,light=2,sound=false,arrival=.5,phases=1,particlesPC=60,particlesPhone=30},
    [4]={geometry=4,motion=3,light=3,sound=true,arrival=1.2,phases=1,particlesPC=150,particlesPhone=70},
    [5]={geometry=5,motion=4,light=4,sound=true,arrival=2,phases=3,particlesPC=250,particlesPhone=120},
}
M.themes={
    carbon_territory={name='격자 도면',desc='작전 도면처럼 가는 격자가 영토를 덮어요.',theme='grid',motif='grid',primary={44,58,72},secondary={176,198,214},accent={150,190,214}},
    cobalt_territory={name='디지털 위장',desc='픽셀 위장 무늬로 영토를 칠해요.',theme='camo',motif='camo',primary={34,52,74},secondary={120,170,230},accent={80,165,255}},
    pulse_territory={name='육각 장갑',desc='벌집 장갑판 무늬, 국경에 보랏빛 에너지선.',theme='hex',motif='hex',primary={46,32,74},secondary={198,170,250},accent={173,119,255}},
    solaris_territory={name='황금 독수리',desc='금빛 독수리 문장이 영토 전체에 새겨져요.',theme='eagle',motif='eagle',primary={58,46,24},secondary={255,214,120},accent={255,196,64}},
    parallax_territory={name='오로라 성좌',desc='별자리 무늬가 영토가 넓어질수록 더 밝게 이어져요.',theme='aurora',motif='stars',primary={24,36,58},secondary={210,240,255},accent={140,250,230}},
    carbon_buildings={name='야전 공병',desc='모래주머니와 경고 띠를 두른 야전 기지.',theme='field',primary={88,94,70},secondary={196,190,150},accent={236,170,56}},
    cobalt_buildings={name='극지 기지',desc='눈 덮인 흰 패널과 푸른 신호등.',theme='polar',primary={210,224,236},secondary={240,248,255},accent={80,165,255}},
    pulse_buildings={name='네온 메트로',desc='검은 유리와 네온 윤곽, 회전하는 홀로 간판.',theme='neon',primary={30,24,48},secondary={120,90,190},accent={190,110,255}},
    solaris_buildings={name='황금 제국',desc='돔과 기둥, 금빛 첨탑으로 다시 지은 제국 건축.',theme='imperial',primary={232,222,198},secondary={214,168,72},accent={255,207,91}},
    parallax_buildings={name='궤도 사령부',desc='반중력 고리 위에 떠 있는 건물. 영토가 커질수록 변신해요.',theme='orbital',primary={36,48,66},secondary={214,236,250},accent={140,250,235}},
    carbon_nuclear={name='강철 탄두',desc='회색 탄두, 짙은 연기, 정석적인 버섯구름.',theme='steel',primary={150,160,172},secondary={214,222,230},accent={255,170,80}},
    cobalt_nuclear={name='빙결 탄두',desc='얼음빛 탄두와 서리 궤적, 얼어붙는 충격파.',theme='cryo',primary={60,110,170},secondary={214,244,255},accent={110,200,255}},
    pulse_nuclear={name='플라즈마',desc='보랏빛 플라즈마 탄두와 전기 궤적, 플라즈마 돔 폭발.',theme='plasma',primary={56,30,96},secondary={220,190,255},accent={190,110,255}},
    solaris_nuclear={name='태양의 창',desc='금빛 창 탄두, 불꽃 궤적, 태양 플레어 폭발.',theme='sun',primary={120,84,26},secondary={255,226,150},accent={255,190,60}},
    parallax_nuclear={name='특이점',desc='검은 구체와 강착 고리, 빨려 들어갔다 터지는 폭발.',theme='singularity',primary={14,16,26},secondary={200,240,255},accent={160,250,240}},
    carbon_commanderTrail={name='먼지 바람',desc='발밑에 남는 옅은 흙먼지.',theme='dust',primary={90,84,74},secondary={190,176,150},accent={214,200,170}},
    cobalt_commanderTrail={name='푸른 잔광',desc='두 줄로 남는 푸른 빛.',theme='afterglow',primary={30,60,110},secondary={150,200,255},accent={80,165,255}},
    pulse_commanderTrail={name='번개 꼬리',desc='지나간 자리에 보랏빛 번개가 튀어요.',theme='lightning',primary={48,30,80},secondary={220,190,255},accent={190,110,255}},
    solaris_commanderTrail={name='불꽃 날개',desc='금빛 불꽃 깃털이 흩날려요.',theme='flame',primary={110,60,20},secondary={255,220,140},accent={255,170,50}},
    parallax_commanderTrail={name='무지개 혜성',desc='색이 흐르는 혜성 꼬리, 오래 달릴수록 길어져요.',theme='comet',primary={30,40,60},secondary={230,245,255},accent={160,250,240}},
    carbon_parachute={name='군용 원형',desc='튼튼한 원형 군용 낙하산.',theme='military',primary={70,78,60},secondary={170,176,140},accent={210,200,150}},
    cobalt_parachute={name='스트라이프 윙',desc='푸른 줄무늬 날개형 캐노피.',theme='stripe',primary={34,60,100},secondary={180,214,250},accent={80,165,255}},
    pulse_parachute={name='야간 글라이더',desc='보랏빛 윤곽등이 켜진 글라이더.',theme='glider',primary={40,28,70},secondary={200,170,250},accent={180,110,255}},
    solaris_parachute={name='황금 독수리',desc='금빛 깃털 날개 캐노피.',theme='eagle',primary={90,64,24},secondary={255,220,140},accent={255,196,64}},
    parallax_parachute={name='홀로 날개',desc='빛으로 된 날개가 펼쳐졌다 접혀요.',theme='holo',primary={26,40,60},secondary={220,245,255},accent={150,250,240}},
    carbon_vehicle={name='정찰 보드',desc='가벼운 1인용 정찰 보드.',theme='scout',primary={56,64,74},secondary={170,182,196},accent={190,205,220}},
    cobalt_vehicle={name='장갑 보드',desc='측면 장갑을 단 보드.',theme='armored',primary={34,56,88},secondary={170,200,235},accent={80,165,255}},
    pulse_vehicle={name='호버 바이크',desc='보랏빛 추진기로 떠서 달려요.',theme='hover',primary={44,30,74},secondary={200,175,250},accent={180,110,255}},
    solaris_vehicle={name='지휘 비행정',desc='금빛 날개와 엔진 둘, 지휘관 전용 비행정.',theme='gunship',primary={52,44,30},secondary={240,210,140},accent={255,196,64}},
    parallax_vehicle={name='강습 워커',desc='네 다리로 걷는 강습 워커.',theme='walker',primary={34,46,62},secondary={214,236,250},accent={150,250,240}},
    carbon_motion={name='출격 신호',desc='명령할 때 발밑에 신호 원이 퍼져요.',theme='signal',primary={48,57,70},secondary={151,165,180},accent={185,198,211}},
    cobalt_motion={name='전술 신호',desc='푸른 전술 화살표가 목표를 가리켜요.',theme='tactic',primary={35,57,88},secondary={175,202,231},accent={80,165,255}},
    pulse_motion={name='지휘 파동',desc='보랏빛 파동이 세 겹으로 퍼져요.',theme='wave',primary={48,34,76},secondary={198,181,234},accent={173,119,255}},
    solaris_motion={name='승전 문장',desc='금빛 문장이 떠올라 회전해요.',theme='crest',primary={35,43,58},secondary={235,206,133},accent={255,207,91}},
    parallax_motion={name='지휘 영역',desc='빛의 영역이 펼쳐지고 색이 흘러요.',theme='domain',primary={39,53,70},secondary={225,237,247},accent={157,242,235}},
    venom_territory={name='독성 늪',desc='독이 고인 웅덩이 무늬가 천천히 번져요.',theme='toxic',motif='ripple',primary={24,46,30},secondary={150,230,120},accent={120,230,90}},
    tidal_territory={name='심해 물결',desc='깊은 바다 물결이 영토 위를 흘러요.',theme='tide',motif='waves',primary={16,42,62},secondary={140,220,240},accent={60,200,230}},
    ember_territory={name='용암 균열',desc='검은 대지 사이로 용암 균열이 빛나요.',theme='magma',motif='cracks',primary={40,26,22},secondary={255,170,90},accent={255,140,50}},
    storm_territory={name='뇌운 전선',desc='번개 무늬가 영토를 가로질러요.',theme='storm',motif='bolts',primary={28,34,52},secondary={200,216,255},accent={140,180,255}},
    crown_territory={name='왕실 문장',desc='남색 바탕에 금빛 왕관 문장이 수놓여요.',theme='royal',motif='crown',primary={28,32,70},secondary={250,226,150},accent={255,204,70}},
    phoenix_territory={name='불사조 깃털',desc='불꽃 깃털 무늬가 영토를 덮고 가장자리가 타올라요.',theme='phoenix',motif='feathers',primary={74,30,16},secondary={255,214,130},accent={255,170,40}},
    eclipse_territory={name='개기 일식',desc='검은 태양 고리가 이어지고, 영토가 넓어질수록 코로나가 번져요.',theme='eclipse',motif='eclipse',primary={12,12,22},secondary={230,226,255},accent={200,120,255}},
    venom_buildings={name='바이오 연구소',desc='초록 배양 탱크와 파이프, 기포가 올라와요.',theme='bio',primary={40,52,46},secondary={150,230,120},accent={120,230,90}},
    tidal_buildings={name='해저 기지',desc='유리 돔과 산호빛 조명, 기포가 떠오르는 해저 기지.',theme='abyss',primary={26,52,72},secondary={150,220,240},accent={60,200,230}},
    ember_buildings={name='화산 요새',desc='현무암 성벽 사이로 용암이 흐르는 요새.',theme='volcano',primary={44,36,34},secondary={255,170,90},accent={255,140,50}},
    storm_buildings={name='뇌전 탑',desc='코일 첨탑 사이로 번개가 튀는 전력 기지.',theme='tesla',primary={44,50,66},secondary={210,224,255},accent={140,180,255}},
    crown_buildings={name='왕궁 성채',desc='남색 지붕과 금빛 첨탑, 깃발이 나부끼는 왕궁.',theme='palace',primary={236,230,214},secondary={40,52,110},accent={255,204,70}},
    phoenix_buildings={name='불사조 신전',desc='불꽃 날개를 펼친 신전, 지붕 위에서 불사조가 타올라요.',theme='pyre',primary={120,60,26},secondary={255,214,130},accent={255,170,40}},
    eclipse_buildings={name='일식 성소',desc='검은 모노리스 위로 빛의 고리가 돌고, 영토가 커질수록 고리가 늘어나요.',theme='monolith',primary={14,14,24},secondary={230,226,255},accent={200,120,255}},
    venom_nuclear={name='독성 탄두',desc='초록 독극물 탄두와 독 안개 궤적, 독구름 폭발.',theme='toxin',primary={40,60,40},secondary={170,240,140},accent={120,230,90}},
    tidal_nuclear={name='해일 탄두',desc='물을 두른 탄두와 물보라 궤적, 해일처럼 퍼지는 폭발.',theme='tsunami',primary={20,60,90},secondary={170,236,250},accent={60,200,230}},
    ember_nuclear={name='용암 탄두',desc='녹아내리는 탄두와 불씨 궤적, 마그마 분출 폭발.',theme='lava',primary={60,30,20},secondary={255,190,110},accent={255,140,50}},
    storm_nuclear={name='뇌격 탄두',desc='피뢰침 탄두와 번개 궤적, 낙뢰가 쏟아지는 폭발.',theme='thunder',primary={40,46,66},secondary={220,230,255},accent={140,180,255}},
    crown_nuclear={name='왕관 탄두',desc='금 장식 탄두와 별가루 궤적, 왕관 모양으로 솟는 폭발.',theme='regal',primary={34,40,90},secondary={255,232,160},accent={255,204,70}},
    phoenix_nuclear={name='불사조 탄두',desc='불꽃 새가 날아가 날개를 펼치며 터져요.',theme='firebird',primary={110,53,20},secondary={255,220,140},accent={255,170,40}},
    eclipse_nuclear={name='일식 탄두',desc='코로나를 두른 검은 태양, 빛을 삼켰다 고리로 터지는 폭발.',theme='eclipse',primary={10,10,18},secondary={235,230,255},accent={200,120,255}},
    venom_commanderTrail={name='독 안개',desc='발자국마다 초록 독 안개가 피어올라요.',theme='toxic',primary={30,50,34},secondary={160,236,130},accent={120,230,90}},
    tidal_commanderTrail={name='물보라',desc='달리면 뒤로 물보라와 물방울이 튀어요.',theme='spray',primary={20,50,70},secondary={170,236,250},accent={60,200,230}},
    ember_commanderTrail={name='불씨 발자국',desc='타오르는 발자국과 불씨가 남아요.',theme='embers',primary={60,30,20},secondary={255,190,110},accent={255,140,50}},
    storm_commanderTrail={name='전격 잔상',desc='푸른 전기 잔상이 지그재그로 남아요.',theme='static',primary={34,40,60},secondary={210,224,255},accent={140,180,255}},
    crown_commanderTrail={name='왕실 별가루',desc='금빛 별가루와 남색 망토 자락이 따라와요.',theme='stardust',primary={30,34,80},secondary={255,232,160},accent={255,204,70}},
    phoenix_commanderTrail={name='불사조 꼬리',desc='불꽃 깃털 꼬리가 길게 휘날려요.',theme='phoenix',primary={100,48,18},secondary={255,220,140},accent={255,170,40}},
    eclipse_commanderTrail={name='일식 그림자',desc='검은 그림자 띠 둘레로 빛의 코로나가 흐르고, 오래 달릴수록 고리가 생겨요.',theme='eclipse',primary={10,10,18},secondary={235,230,255},accent={200,120,255}},
    venom_parachute={name='독침 글라이더',desc='초록 줄무늬가 들어간 날카로운 글라이더.',theme='stinger',primary={30,50,34},secondary={160,236,130},accent={120,230,90}},
    tidal_parachute={name='해파리',desc='반투명 해파리 캐노피, 촉수가 흔들려요.',theme='jellyfish',primary={30,70,100},secondary={170,236,250},accent={60,200,230}},
    ember_parachute={name='용암 날개',desc='검은 날개 사이로 용암 줄기가 빛나요.',theme='magma',primary={50,30,24},secondary={255,190,110},accent={255,140,50}},
    storm_parachute={name='뇌운',desc='먹구름 캐노피에서 번개가 번쩍여요.',theme='thundercloud',primary={50,56,74},secondary={210,224,255},accent={140,180,255}},
    crown_parachute={name='왕실 깃발',desc='남색과 금색 왕실 문장 캐노피, 끝에 술 장식이 흔들려요.',theme='royal',primary={30,36,90},secondary={255,232,160},accent={255,204,70}},
    phoenix_parachute={name='불사조 날개',desc='불꽃 깃털 날개가 퍼덕이며 불씨를 흩뿌려요.',theme='phoenix',primary={110,53,20},secondary={255,220,140},accent={255,170,40}},
    eclipse_parachute={name='일식 고리',desc='검은 원반을 두른 빛의 고리 날개, 펼칠 때 코로나가 터져요.',theme='eclipse',primary={10,10,18},secondary={235,230,255},accent={200,120,255}},
    venom_vehicle={name='바이오 크롤러',desc='초록 탱크를 실은 다리 여섯 크롤러.',theme='crawler',primary={34,50,38},secondary={160,236,130},accent={120,230,90}},
    tidal_vehicle={name='제트 스키',desc='물살을 가르며 떠서 달리는 제트 스키.',theme='jetski',primary={20,60,90},secondary={170,236,250},accent={60,200,230}},
    ember_vehicle={name='용암 바이크',desc='불꽃 바퀴로 달리는 무거운 바이크.',theme='magmabike',primary={44,30,26},secondary={255,190,110},accent={255,140,50}},
    storm_vehicle={name='뇌전 보드',desc='코일이 달린 보드, 밑에서 전기가 튀어요.',theme='arcboard',primary={34,40,60},secondary={210,224,255},accent={140,180,255}},
    crown_vehicle={name='황금 전차',desc='금빛 말 모양 엔진이 끄는 왕실 전차.',theme='chariot',primary={30,36,90},secondary={255,232,160},accent={255,204,70}},
    phoenix_vehicle={name='불사조',desc='불꽃 새를 타고 날아다녀요.',theme='phoenix',primary={110,53,20},secondary={255,220,140},accent={255,170,40}},
    eclipse_vehicle={name='일식 옥좌',desc='검은 구체 위의 옥좌, 빛의 고리가 겹겹이 돌고 모양이 바뀌어요.',theme='throne',primary={10,10,18},secondary={235,230,255},accent={200,120,255}},
    venom_motion={name='독 폭발',desc='명령하면 초록 독 거품이 터져요.',theme='toxic',primary={30,50,34},secondary={160,236,130},accent={120,230,90}},
    tidal_motion={name='해일',desc='물기둥이 솟고 물결이 퍼져요.',theme='tide',primary={20,50,70},secondary={170,236,250},accent={60,200,230}},
    ember_motion={name='화염 신호',desc='발밑에서 불기둥이 솟고 불씨가 흩어져요.',theme='flare',primary={60,30,20},secondary={255,190,110},accent={255,140,50}},
    storm_motion={name='낙뢰',desc='목표 지점에 번개가 내리꽂혀요.',theme='strike',primary={34,40,60},secondary={210,224,255},accent={140,180,255}},
    crown_motion={name='왕관 강림',desc='금빛 왕관이 내려오고 깃발이 펼쳐져요.',theme='coronation',primary={30,34,80},secondary={255,232,160},accent={255,204,70}},
    phoenix_motion={name='불사조 비상',desc='불사조가 솟아올라 날개를 펼쳐요.',theme='rise',primary={100,48,18},secondary={255,220,140},accent={255,170,40}},
    eclipse_motion={name='검은 태양',desc='하늘이 어두워지고 검은 태양의 코로나가 퍼져요.',theme='totality',primary={10,10,18},secondary={235,230,255},accent={200,120,255}},
    dragon_territory={name='청룡 비늘',desc='옥빛 비늘 위로 금빛 용 그림자가 국경을 따라 헤엄쳐요.',theme='dragon',motif='dragonscale',primary={18,58,60},secondary={170,240,215},accent={255,206,90}},
    diamond_territory={name='다이아 컷',desc='영토가 보석 면처럼 잘리고 빛줄기가 쓸고 지나가요.',theme='diamond',motif='facets',primary={226,236,246},secondary={170,215,255},accent={255,214,120}},
    seraph_territory={name='천상의 깃털',desc='흰 깃털 문양이 덮이고, 영토가 넓어지면 수도 위로 빛기둥이 서요.',theme='seraph',motif='plumes',primary={244,244,252},secondary={255,232,170},accent={255,143,216}},
    glitch_territory={name='데이터 오류',desc='내 영토가 픽셀 블록으로 깜빡이고, 넓어질수록 더 크게 깨져요.',theme='glitch',motif='pixels',primary={8,10,16},secondary={80,240,255},accent={255,90,220}},
    leviathan_territory={name='심연의 눈',desc='심해 물빛이 일렁이고, 영토가 넓어지면 수도에서 거대한 눈이 떠요.',theme='leviathan',motif='abyss',primary={6,20,36},secondary={60,240,220},accent={170,120,255}},
    dragon_buildings={name='용궁 누각',desc='겹지붕 누각, 용 한 마리가 탑을 휘감고 돌아요.',theme='pagoda',primary={18,58,60},secondary={170,240,215},accent={255,206,90}},
    diamond_buildings={name='크리스탈 타워',desc='금 테두리 크리스탈 빌딩, 꼭대기에서 큰 보석이 돌아요.',theme='crystal',primary={226,236,246},secondary={170,215,255},accent={255,214,120}},
    seraph_buildings={name='천공 성전',desc='떠 있는 흰 성전, 영토가 넓어질수록 날개가 돋아요.',theme='sanctum',primary={244,244,252},secondary={255,232,170},accent={255,143,216}},
    glitch_buildings={name='해킹 서버',desc='홀로그램 서버 건물, 영토가 넓어질수록 와이어프레임으로 폭주해요.',theme='server',primary={8,10,16},secondary={80,240,255},accent={255,90,220}},
    leviathan_buildings={name='심해 신전',desc='촉수가 감싼 신전, 영토가 넓어질수록 촉수가 솟고 눈이 떠요.',theme='deeptemple',primary={6,20,36},secondary={60,240,220},accent={170,120,255}},
    dragon_nuclear={name='용의 숨결',desc='용머리 탄두와 굽이치는 용 궤적, 옥빛 불꽃 소용돌이 폭발.',theme='dragonbreath',primary={18,58,60},secondary={170,240,215},accent={255,206,90}},
    diamond_nuclear={name='다이아 탄두',desc='보석 컷 탄두와 반짝이 궤적, 터지면 보석 조각이 쏟아져요.',theme='gem',primary={226,236,246},secondary={170,215,255},accent={255,214,120}},
    seraph_nuclear={name='심판의 빛',desc='하늘에서 빛의 창이 꽂히고 빛기둥과 깃털 비가 내려요.',theme='judgment',primary={244,244,252},secondary={255,232,170},accent={255,143,216}},
    glitch_nuclear={name='시스템 삭제',desc='픽셀 큐브 탄두, 터진 자리가 네모나게 지워졌다 다시 짜여요.',theme='delete',primary={8,10,16},secondary={80,240,255},accent={255,90,220}},
    leviathan_nuclear={name='심해의 포효',desc='떨어진 자리에서 리바이어던이 솟아 물 소용돌이로 삼켜요.',theme='maw',primary={6,20,36},secondary={60,240,220},accent={170,120,255}},
    dragon_commanderTrail={name='용의 꼬리',desc='비늘이 반짝이는 긴 용 몸통이 뒤를 따라와요.',theme='dragontail',primary={18,58,60},secondary={170,240,215},accent={255,206,90}},
    diamond_commanderTrail={name='보석 가루',desc='반짝이 가루와 작은 보석이 통통 튀며 떨어져요.',theme='gemdust',primary={226,236,246},secondary={170,215,255},accent={255,214,120}},
    seraph_commanderTrail={name='천사의 깃털',desc='빛나는 깃털이 흩날리고, 오래 달릴수록 후광이 생겨요.',theme='plume',primary={244,244,252},secondary={255,232,170},accent={255,143,216}},
    glitch_commanderTrail={name='데이터 스트림',desc='픽셀 잔상과 흐르는 코드, 오래 달릴수록 크게 깨져요.',theme='datastream',primary={8,10,16},secondary={80,240,255},accent={255,90,220}},
    leviathan_commanderTrail={name='발광 물결',desc='발밑에 빛나는 물결이 번지고, 오래 달릴수록 촉수가 따라와요.',theme='biolume',primary={6,20,36},secondary={60,240,220},accent={170,120,255}},
    dragon_parachute={name='용 연',desc='용 모양 연 캐노피, 수염과 꼬리가 바람에 나부껴요.',theme='kite',primary={18,58,60},secondary={170,240,215},accent={255,206,90}},
    diamond_parachute={name='다이아 캐노피',desc='각진 보석 캐노피, 빛이 비치면 번쩍여요.',theme='gemcanopy',primary={226,236,246},secondary={170,215,255},accent={255,214,120}},
    seraph_parachute={name='여섯 날개',desc='캐노피가 날개가 되고, 내려갈수록 2장, 4장, 6장으로 늘어요.',theme='seraphwings',primary={244,244,252},secondary={255,232,170},accent={255,143,216}},
    glitch_parachute={name='버그 캐노피',desc='캐노피가 픽셀로 찢어졌다 다시 붙어요.',theme='bugcanopy',primary={8,10,16},secondary={80,240,255},accent={255,90,220}},
    leviathan_parachute={name='촉수 캐노피',desc='발광 촉수가 달린 심해 생물 캐노피.',theme='tendril',primary={6,20,36},secondary={60,240,220},accent={170,120,255}},
    dragon_vehicle={name='청룡',desc='용을 타고 낮게 날아다녀요. 멈추면 지휘관 둘레를 감아요.',theme='serpent',primary={18,58,60},secondary={170,240,215},accent={255,206,90}},
    diamond_vehicle={name='다이아 슈퍼카',desc='다이아로 만든 호버 슈퍼카, 출발할 때 금빛 불꽃.',theme='supercar',primary={226,236,246},secondary={170,215,255},accent={255,214,120}},
    seraph_vehicle={name='세라핌 날개',desc='등에 날개를 달고 날아요. 영토가 넓어질수록 날개가 늘어요.',theme='seraph',primary={244,244,252},secondary={255,232,170},accent={255,143,216}},
    glitch_vehicle={name='광속 바이크',desc='빛의 벽을 남기며 달리는 사이버 바이크.',theme='lightcycle',primary={8,10,16},secondary={80,240,255},accent={255,90,220}},
    leviathan_vehicle={name='심해 만타',desc='발광 만타를 타고 미끄러지듯 날아요.',theme='manta',primary={6,20,36},secondary={60,240,220},accent={170,120,255}},
    dragon_motion={name='용 승천',desc='용이 나선으로 솟아올라 포효해요.',theme='ascend',primary={18,58,60},secondary={170,240,215},accent={255,206,90}},
    diamond_motion={name='잭팟',desc='발밑에서 보석이 분수처럼 솟았다 흩어져요.',theme='jackpot',primary={226,236,246},secondary={170,215,255},accent={255,214,120}},
    seraph_motion={name='강림',desc='날개가 펼쳐지고 후광이 내려와요.',theme='descent',primary={244,244,252},secondary={255,232,170},accent={255,143,216}},
    glitch_motion={name='해킹',desc='픽셀이 모여 커서가 되어 목표를 찍어요.',theme='hack',primary={8,10,16},secondary={80,240,255},accent={255,90,220}},
    leviathan_motion={name='소환',desc='촉수가 솟았다 가라앉아요.',theme='summon',primary={6,20,36},secondary={60,240,220},accent={170,120,255}},
}
M.flat={
    {key='lined_territory',name='사선 줄무늬',rarity='normal',tier=1,motif='stripes',desc='영토에 가는 사선만 그어지는 평면 무늬.',primary={48,57,70},secondary={176,198,214},accent={150,190,214}},
    {key='tartan_territory',name='작전 체크',rarity='rare',tier=2,motif='plaid',desc='굵은 띠가 엇갈리는 체크, 이음매에 푸른 실.',primary={35,57,88},secondary={175,202,231},accent={80,165,255}},
    {key='scale_territory',name='용비늘',rarity='epic',tier=3,motif='scales',desc='보랏빛 테두리 비늘이 영토를 촘촘히 덮어요.',primary={48,34,76},secondary={198,181,234},accent={173,119,255}},
    {key='filigree_territory',name='금실 아라베스크',rarity='legendary',tier=4,motif='filigree',desc='금실 격자와 빛나는 매듭이 영토 전체에 수놓여요.',primary={58,46,24},secondary={255,226,150},accent={255,200,70}},
    {key='galaxy_territory',name='은하 소용돌이',rarity='mythic',tier=5,motif='galaxy',desc='나선 은하가 돌고, 영토가 넓어질수록 별이 늘고 밝아져요.',primary={20,22,48},secondary={230,226,255},accent={255,143,216}},
}
M.names={};for key,t in pairs(M.themes)do M.names[key]=t.name end
for _,f in ipairs(M.flat)do M.names[f.key]=f.name end
M.familyNames={commanderStandard='깃발',territory='영토',buildings='건물',nuclear='핵',commanderTrail='트레일',parachute='낙하산',vehicle='탈것',motion='지휘 연출'}
function M.styles()
    local out={}
    for _,family in ipairs(M.families)do for _,series in ipairs(M.order)do
        local key=series.id..'_'..family.id
        local t=M.themes[key]or {}
        out[key]={id=key,name=t.name or series.name,access='collection',category=family.id,rarity=series.rarity,tier=series.tier,series=series.id,
            primary=t.primary or series.primary,secondary=t.secondary or series.secondary,accent=t.accent or series.accent,territory={54,226,208},border={191,239,255},
            architecture=series.id,theme=t.theme,motif=t.motif,desc=t.desc,orderShape='rings',trail='line',impact='rings',features=M.features[series.tier],slots=family.slots}
    end end
    for _,f in ipairs(M.flat)do
        out[f.key]={id=f.key,name=f.name,access='collection',category='territory',rarity=f.rarity,tier=f.tier,flat=true,
            primary=f.primary,secondary=f.secondary,accent=f.accent,territory={54,226,208},border={191,239,255},
            architecture='carbon',motif=f.motif,desc=f.desc,orderShape='rings',trail='line',impact='rings',features=M.features[f.tier],slots={'territory'}}
    end
    return out
end
function M.items()
    local out={}
    for _,family in ipairs(M.families)do for _,series in ipairs(M.order)do
        local key=series.id..'_'..family.id;local loadout={};for _,slot in ipairs(family.slots)do loadout[slot]=key end
        table.insert(out,{id='supply:'..key,name=M.names[key],category=family.id,rarity=series.rarity,tier=series.tier,
            style=key,loadout=loadout,ready=true,artVersion=1})
    end end
    for _,f in ipairs(M.flat)do
        table.insert(out,{id='supply:'..f.key,name=f.name,category='territory',rarity=f.rarity,tier=f.tier,style=f.key,loadout={territory=f.key},ready=true,artVersion=1})
    end
    for _,f in ipairs(Standards.series)do
        table.insert(out,{id=Standards.supplyId(f.id),name=f.name,category='commanderStandard',rarity=f.rarity,tier=f.tier,style=f.id,standard=true,loadout={},ready=true,artVersion=1})
    end
    return out
end
function M.family(slot)for _,f in ipairs(M.families)do if f.id==slot or table.find(f.slots,slot)then return f end end end
return M
