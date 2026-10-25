local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Step=require(script.Parent.TelemetryStep)
local Icons=require(script.Parent.HotbarIcons)
local E=require(script.Parent.Parent.Core.EconomyRules)
local K=require(script.Parent.Parent.Core.ConfigConstants)
local C=UI.colors
local M={}
M.shots={}
local tipAt=0
local function num(n)
    n=tonumber(n)or 0
    if n>=1e6 then return string.format('%gM',math.floor(n/1e4+.5)/100)end
    if n>=1e3 then return string.format('%gK',math.floor(n/10+.5)/100)end
    return tostring(math.floor(n))
end

local me={kind='HUMAN',owned={},constructed={}}
local function cost(kind,n)local c=E.cost({},{kind='HUMAN',owned={[kind]=n or 0},constructed={[kind]=n or 0}},kind);return num(tonumber(require(script.Parent.Parent.Core.BigNat).toString(c))or 0)end
local function secs(kind)return string.format('%d초',math.floor(E.duration({},kind)*K.msPerTick/1000))end
local function per(t)return string.format('%d초',math.floor(t*K.msPerTick/1000))end
local function troops(n)return num((tonumber(n)or 0)/10)end

local function entries()
    local start=troops(E.startTroops({},me))
    return {
        settle={'Target','정착','땅 눌러 시작',C.accent,{{'시작 병력',start},{'시작 자리','빈 땅 아무 곳'},{'다른 나라와 거리',string.format('%d칸 이상',K.minDistanceBetweenPlayers)}},'해안 시작 = 항구로 바다까지'},
        expand={'Sword','넓히기','옆 땅 눌러 공격',C.accent,{{'공격 비율','10, 20, 50, 100%'},{'기본 비율','20%'},{'회색 부족 병력',troops(E.startTroops({},{kind='BOT'}))}},'회색 부족 먼저, 큰 나라는 병력 찬 뒤'},
        grow={'City','키우기','골드로 건물',C.accent,{{'기본 골드 수입',string.format('초당 %s',num(E.goldRate({},me)*1000/K.msPerTick))},{'첫 도시',cost('City')},{'건물 수','지을수록 비싸져요'}},'같은 건물 하나 더 = 가격 2배, 도시는 일찍'},
        win={'Crown','승리','땅 80% 차지',C.gold,{{'승리 조건','땅 80% 차지'},{'팀전',string.format('땅 %d%% 차지',K.teamLandShareWinThresholdTenths*10)},{'시간이 끝나면','땅이 가장 넓은 쪽'}},'순위표 내 땅 % 확인'},
        troops={'Soldier','병력','저절로 차요',C.accent,{{'시작 병력',start},{'도시 1레벨마다',string.format('상한 +%s',troops(K.cityTroopIncrease))},{'꽉 차면','더 안 늘어요'}},'가득 차기 전에 쓰기'},
        gold={'Gold','골드','땅과 무역으로',nil,{{'기본 수입',string.format('초당 %s',num(E.goldRate({},me)*1000/K.msPerTick))},{'무역선, 열차','오갈 때마다'},{'나라 점령','그 나라 골드 획득'}},'항구, 철도 기지 일찍 = 골드 계속'},
        ally={'Alliance','동맹','함께 싸워요',C.good,{{'요청 대기',per(K.allianceRequestDuration)},{'배신하면',string.format('%s 동안 방어 절반',per(K.traitorDuration))},{'동맹에게 핵','동맹이 깨져요'}},'큰 나라 옆 = 먼저 동맹'},
        City={'City','도시','병력 상한 올림',nil,{{'비용',string.format('%s부터, 지을수록 2배',cost('City'))},{'건설',secs('City')},{'레벨마다',string.format('병력 상한 +%s',troops(K.cityTroopIncrease))}},'땅 좁을수록 도시 효과 ▲'},
        DefensePost={'DefensePost','요새','국경 방어',nil,{{'비용',string.format('%s부터, 최대 %s',cost('DefensePost'),cost('DefensePost',4))},{'건설',secs('DefensePost')},{'범위',string.format('반경 %d칸 육상 방어',K.defensePostRange)}},'적과 맞닿은 국경에'},
        Port={'Port','항구','배와 무역',nil,{{'비용',string.format('%s부터, 지을수록 2배',cost('Port'))},{'건설',secs('Port')},{'하는 일','무역선 출항, 군함 수리'}},'먼 항구끼리 = 골드 ▲'},
        Factory={'Factory','철도 기지','열차로 골드',nil,{{'비용',string.format('%s부터, 지을수록 2배',cost('Factory'))},{'건설',secs('Factory')},{'열차 한 번',string.format('내 땅 %s, 동맹 %s',num(10000),num(35000))}},'동맹까지 철도 = 열차 골드 ▲'},
        MissileSilo={'MissileSilo','미사일 사일로','핵 발사',nil,{{'비용',cost('MissileSilo')},{'건설',secs('MissileSilo')},{'재장전',per(K.SiloCooldown)}},'강화 = 동시 발사 ▲'},
        SAMLauncher={'SAMLauncher','방공 기지','핵 요격',nil,{{'비용',string.format('%s부터, 최대 %s',cost('SAMLauncher'),cost('SAMLauncher',1))},{'건설',secs('SAMLauncher')},{'요격 범위',string.format('%d칸, 강화하면 최대 %d칸',K.defaultSamRange,K.maxSamRange)}},'도시와 사일로 옆에'},
        Warship={'Warship','군함','바다 지키기',nil,{{'비용',string.format('%s부터, 최대 %s',cost('Warship'),cost('Warship',3))},{'순찰 범위',string.format('%d칸',K.warshipPatrolRange)},{'하는 일','상륙선 격침, 무역선 나포'}},'적 무역선 나포 = 골드 획득'},
        Transport={'Transport','상륙','바다 건너 공격',nil,{{'비용','무료'},{'싣는 병력','공격 비율만큼'},{'조심','적 군함에 가라앉아요'}},'먼 섬은 상륙으로만'},
        TradeShip={'TradeShip','무역선','골드 실어 와요',nil,{{'비용','무료, 항구가 자동 출항'},{'골드','먼 항구일수록 많아요'},{'조심','적 군함이 나포해요'}},'군함 호위 = 무역선 안전'},
        AtomBomb={'AtomBomb','원자폭탄','좁은 범위',C.danger,{{'비용',cost('AtomBomb')},{'폭발 반경','12칸에서 30칸'},{'필요','미사일 사일로'}},'적 도시 한가운데'},
        HydrogenBomb={'HydrogenBomb','수소폭탄','넓은 범위',C.danger,{{'비용',cost('HydrogenBomb')},{'폭발 반경','80칸에서 100칸'},{'필요','미사일 사일로'}},'적 방공 기지 없는 곳'},
        MIRV={'MIRV','다탄두','여러 곳 한 번에',C.danger,{{'비용',string.format('%s, 쏠 때마다 더 비싸요',cost('MIRV'))},{'탄두','최대 350발'},{'필요','미사일 사일로'}},'마지막 한 수, 나라 전체 타격'},
    }
end
local LOOP={'settle','expand','grow','win'}
local BOOK={{'기본기',{'troops','gold','ally'}},{'건물',{'City','DefensePost','Port','Factory','MissileSilo','SAMLauncher'}},{'바다',{'Warship','Transport','TradeShip'}},{'핵',{'AtomBomb','HydrogenBomb','MIRV'}}}
M.tips={'회색 부족 먼저 = 쉬운 성장','병력 가득 = 충원 멈춤','같은 건물 하나 더 = 가격 2배','배신 = 30초 방어 절반','먼 항구끼리 무역 = 골드 ▲','방공 기지 = 도시 옆에 먼저','땅 80% = 즉시 승리'}

local function fitText(l,max,min)l.TextScaled=true;l.TextWrapped=false;UI.make('UITextSizeConstraint',l,{MaxTextSize=max,MinTextSize=min});return l end
local function card(parent,name,x,y,w,h)local f=UI.make('Frame',parent,{Name=name,BackgroundColor3=Style.colors.chip,BorderSizePixel=0});UI.box(f,x,y,w,h);Style.round(f,10);Style.line(f,Style.colors.line,1);return f end
local function head(f,text,hint)
    local h=UI.label(f,'Head',text,12,C.muted);h.Font=Enum.Font.BuilderSansBold;h.TextWrapped=false;UI.box(h,10,3,200,16)
    if hint then local t=UI.label(f,'Hint','눌러서 자세히 ›',11,C.accent);t.TextWrapped=false;t.TextXAlignment=Enum.TextXAlignment.Right;t.AnchorPoint=Vector2.new(1,0);t.Position=UDim2.new(1,-10,0,3);t.Size=UDim2.fromOffset(140,16)end
end
local function hit(parent,name,open)
    local b=UI.make('TextButton',parent,{Name=name,Text='',AutoButtonColor=false,BackgroundColor3=C.ice,BackgroundTransparency=1,BorderSizePixel=0});Style.round(b,8)
    b.MouseEnter:Connect(function()b.BackgroundTransparency=.94 end);b.MouseLeave:Connect(function()b.BackgroundTransparency=1 end)
    b.Activated:Connect(open);return b
end

local function detail(body,key,e,w,big)
    local old=body:FindFirstChild('HelpDetail');if old then old:Destroy()end
    Step.step('howto','detail',{item=key})
    local view=body.AbsoluteSize/UI.scale;local top=body.CanvasPosition.Y
    local dim=UI.make('TextButton',body,{Name='HelpDetail',Text='',AutoButtonColor=false,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.35,BorderSizePixel=0,ZIndex=50})
    UI.box(dim,0,top,math.max(w+14,view.X),math.max(view.Y,1))
    local rowH=big and 30 or 28;local fs=big and 15 or 14;local tipH=big and 40 or 38
    local tall=16+52+10+#e[5]*rowH+10+tipH+10+44+14;local side=tall>view.Y-8 and w>=480
    local cw=side and math.min(w,600)or math.min(w,big and 420 or 360);local lw=side and math.floor(cw*.46)or cw
    local ch=side and math.max(16+52+10+tipH+10+44+14,16+#e[5]*rowH+14)or tall
    local f=card(dim,'Card',0,0,cw,ch);f.AnchorPoint=Vector2.new(.5,.5);f.Position=UDim2.fromScale(.5,.5);f.ZIndex=51;f.Active=true
    local box=UI.make('Frame',f,{Name='IconBox',BackgroundColor3=Style.colors.cell,BorderSizePixel=0,ZIndex=52});UI.box(box,16,16,52,52);Style.round(box,10);Style.line(box,Style.colors.line,1)
    local icon=Icons.create(box,e[1],38,e[4]or C.ink);icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromScale(.5,.5);icon.ZIndex=53
    local n=UI.label(f,'Name',e[2],big and 20 or 18,C.ink);n.Font=Enum.Font.BuilderSansBold;n.TextWrapped=false;n.ZIndex=52;UI.box(n,80,16,lw-96,26);fitText(n,big and 20 or 18,12)
    local s=UI.label(f,'Line',e[3],fs,C.muted);s.TextWrapped=false;s.ZIndex=52;UI.box(s,80,42,lw-96,22);fitText(s,fs,10)
    local rx,ry,rw=side and lw or 12,side and 16 or 78,side and cw-lw-12 or cw-24
    for i,r in ipairs(e[5])do
        local row=UI.make('Frame',f,{Name='Row'..i,BackgroundColor3=i%2==1 and Style.colors.cell or Style.colors.chip,BorderSizePixel=0,ZIndex=52});UI.box(row,rx,ry,rw,rowH);Style.round(row,6)
        local l=UI.label(row,'Label',r[1],fs-1,C.muted);l.TextWrapped=false;l.ZIndex=53;UI.box(l,10,0,rw*.38,rowH);fitText(l,fs-1,10)
        local v=UI.label(row,'Value',r[2],fs,C.ink);v.Font=Enum.Font.BuilderSansBold;v.TextXAlignment=Enum.TextXAlignment.Right;v.ZIndex=53;UI.box(v,rw*.38,0,rw*.62-10,rowH);fitText(v,fs,10)
        ry+=rowH
    end
    local y=side and 78 or ry+10;local tw=side and lw-24 or cw-24
    local tip=UI.make('Frame',f,{Name='Tip',BackgroundColor3=C.accent:Lerp(Style.colors.chip,.85),BorderSizePixel=0,ZIndex=52});UI.box(tip,12,y,tw,tipH);Style.round(tip,8);Style.line(tip,C.accent,1,.6)
    local tl=UI.label(tip,'TipTag','팁',12,C.bg);tl.BackgroundColor3=C.accent;tl.BackgroundTransparency=0;tl.Font=Enum.Font.BuilderSansBold;tl.TextXAlignment=Enum.TextXAlignment.Center;tl.ZIndex=53;Style.round(tl,4);UI.box(tl,8,(tipH-20)/2,28,20)
    local tt=UI.label(tip,'TipText',e[6],fs-1,C.ink);tt.ZIndex=53;UI.box(tt,44,2,tw-52,tipH-4);tt.TextScaled=true;UI.make('UITextSizeConstraint',tt,{MaxTextSize=fs-1,MinTextSize=10})
    y+=tipH+10
    local close=UI.button(f,'Close','닫기',function()dim:Destroy()end);close.ZIndex=52;UI.box(close,12,y,tw,44);Style.round(close,8)
    dim.Activated:Connect(function()dim:Destroy()end)
end

local function tile(body,f,key,e,cx,cy,tw,sq,big,w)
    local b=hit(f,'Open_'..key,function()detail(body,key,e,w,big)end);UI.box(b,cx,cy-2,tw,sq+(big and 40 or 36))
    local box=UI.make('Frame',f,{Name='Icon'..key,BackgroundColor3=Style.colors.cell,BorderSizePixel=0});UI.box(box,cx+(tw-sq)/2,cy,sq,sq);Style.round(box,8);Style.line(box,Style.colors.line,1)
    local icon=Icons.create(box,e[1],sq-10,e[4]or C.ink);icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromScale(.5,.5)
    local nh=big and 19 or 17;local dh=big and 16 or 14
    local n=fitText(UI.label(f,'Name_'..key,e[2],big and 15 or 14,C.ink),big and 15 or 14,10);n.Font=Enum.Font.BuilderSansBold;n.TextXAlignment=Enum.TextXAlignment.Center;UI.box(n,cx+2,cy+sq+2,tw-4,nh)
    local d=fitText(UI.label(f,'Text_'..key,e[3],big and 13 or 12,C.muted),big and 13 or 12,9);d.TextXAlignment=Enum.TextXAlignment.Center;UI.box(d,cx+2,cy+sq+2+nh,tw-4,dh)
end
local function section(body,all,x,y,w,s,cols,sq,big,bw)
    local keys=s[2];local rows=math.ceil(#keys/cols);local th=sq+(big and 40 or 36);local h=20+rows*th+(rows-1)*2+6
    local f=card(body,'Book_'..s[1],x,y,w,h);head(f,s[1]);local tw=(w-12)/cols
    for i,k in ipairs(keys)do tile(body,f,k,all[k],6+((i-1)%cols)*tw,20+math.floor((i-1)/cols)*(th+2),tw,sq,big,bw)end
    return h
end
local function loop(body,all,x,y,w,big,bw)
    local cw=(w-12-30)/4;local sh=math.floor(cw/1.3);local h=20+sh+(big and 52 or 48);local f=card(body,'Loop',x,y,w,h);head(f,'이렇게 이겨요',true)
    for i,k in ipairs(LOOP)do
        local e=all[k];local cx=6+(i-1)*(cw+10)
        local open=hit(f,'Open_'..k,function()detail(body,k,e,bw,big)end);UI.box(open,cx-3,19,cw+6,h-22)
        local shot=UI.make('ImageLabel',f,{Name='Shot'..i,BackgroundColor3=Color3.fromRGB(16,52,60),BorderSizePixel=0,ScaleType=Enum.ScaleType.Crop,Image=M.shots[i]or ''});UI.box(shot,cx,20,cw,sh);Style.round(shot,8);Style.line(shot,Style.colors.line,1)
        if not M.shots[i]then local icon=Icons.create(shot,e[1],math.min(40,sh-14),e[4]);icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromScale(.5,.5)end
        local n=UI.label(shot,'Step',tostring(i),12,C.bg);n.BackgroundColor3=C.accent;n.BackgroundTransparency=0;n.TextXAlignment=Enum.TextXAlignment.Center;n.Font=Enum.Font.BuilderSansBold;Style.round(n,9);UI.box(n,4,4,18,18)
        if i<4 then local a=UI.label(f,'Arrow'..i,'›',18,C.accent);a.Font=Enum.Font.BuilderSansBold;a.TextXAlignment=Enum.TextXAlignment.Center;UI.box(a,cx+cw,20+sh/2-10,10,20)end
        local t=fitText(UI.label(f,'Title'..i,e[2],big and 15 or 14,C.ink),big and 15 or 14,10);t.Font=Enum.Font.BuilderSansBold;t.TextXAlignment=Enum.TextXAlignment.Center;UI.box(t,cx,20+sh+3,cw,big and 19 or 17)
        local d=fitText(UI.label(f,'Text'..i,e[3],big and 13 or 12,C.muted),big and 13 or 12,9);d.TextWrapped=true;d.TextYAlignment=Enum.TextYAlignment.Top;d.TextXAlignment=Enum.TextXAlignment.Center;UI.box(d,cx-3,20+sh+(big and 22 or 20),cw+6,26)
    end
    return h
end
local function tips(body,x,y,w,touch,guide,inLobby,th)
    th=th or 48
    local list={touch and '끌기 이동  두 손가락 확대  탭 행동 메뉴'or 'WASD 이동  휠 확대  클릭 공격  우클릭 메뉴'}
    if not touch then
        for _,t in ipairs({'1~0 건물 고르기  C 도시  V 요새  X 취소','G 공격  B 수송  T 비율 바꾸기  F 확정','K 동맹  Z 이모지  L 순위  P 메뉴  H 내 땅'})do table.insert(list,t)end
    end
    for _,t in ipairs(M.tips)do table.insert(list,t)end
    local gw=math.min(150,math.floor(w*.34));local tw=w-gw-8
    local f=card(body,'Tips',x,y,tw,th);f.BackgroundColor3=C.accent:Lerp(Style.colors.chip,.88)
    local tag=UI.label(f,'TipTag','팁',12,C.bg);tag.BackgroundColor3=C.accent;tag.BackgroundTransparency=0;tag.Font=Enum.Font.BuilderSansBold;tag.TextXAlignment=Enum.TextXAlignment.Center;Style.round(tag,4);UI.box(tag,8,(th-20)/2,28,20)
    local text=UI.label(f,'TipText','',13,C.ink);UI.box(text,42,3,tw-42-24,th-6);text.TextScaled=true;UI.make('UITextSizeConstraint',text,{MaxTextSize=13,MinTextSize=10})
    local more=UI.label(f,'Next','›',20,C.accent);more.Font=Enum.Font.BuilderSansBold;more.TextXAlignment=Enum.TextXAlignment.Center;UI.box(more,tw-22,(th-28)/2,18,28)
    local function show()text.Text=list[tipAt%#list+1]end;show()
    hit(f,'NextTip',function()tipAt+=1;show();Step.step('howto','tip',{item=tostring(tipAt%#list+1)})end).Size=UDim2.fromScale(1,1)
    local g=UI.button(body,'ShowGuide',inLobby and '튜토리얼 다시하기'or '지금 판에서 안내 보기',guide,true);UI.box(g,x+tw+8,y,gw,th);Style.round(g,8);fitText(g,15,11)
    return th+4
end

function M.draw(ctx)
    local body=ctx.body;local w=math.max(260,ctx.width)-14;local y=0
    local all=entries();local gap=6;local x0=4;local big=not ctx.touch and w>=600
    if w<520 then
        y+=loop(body,all,x0,y,w,false,w)+gap
        for _,s in ipairs(BOOK)do y+=section(body,all,x0,y,w,s,3,30,false,w)+gap end
        y+=tips(body,x0,y,w,ctx.touch,ctx.guide,ctx.inLobby)
    else
        local three=ctx.short==true;local cols=three and 3 or 2;local share=three and {.36,.28,.36}or {.5,.5};local ys,xs,ws={},{},{};local x=x0
        for c=1,cols do ys[c]=y;xs[c]=x;ws[c]=(w-(cols-1)*gap)*share[c];x+=ws[c]+gap end
        local function put(c,fn)ys[c]+=fn(xs[c],ys[c],ws[c])+gap end
        local sq=three and 26 or big and 38 or 34
        put(1,function(x,yy,ww)return loop(body,all,x,yy,ww,big,w)end);put(1,function(x,yy,ww)return section(body,all,x,yy,ww,BOOK[1],3,sq,big,w)end)
        put(2,function(x,yy,ww)return section(body,all,x,yy,ww,BOOK[2],three and 2 or 3,sq,big,w)end)
        local c3=three and 3 or 2;put(c3,function(x,yy,ww)return section(body,all,x,yy,ww,BOOK[3],3,sq,big,w)end);put(c3,function(x,yy,ww)return section(body,all,x,yy,ww,BOOK[4],3,sq,big,w)end)
        put(three and 3 or 1,function(x,yy,ww)return tips(body,x,yy,ww,ctx.touch,ctx.guide,ctx.inLobby,three and 58 or 48)end)
        for c=1,cols do y=math.max(y,ys[c])end
    end
    Step.step('howto','shown',{item=ctx.inLobby and 'lobby'or 'menu'})
    body.CanvasSize=UDim2.fromOffset(0,y);return y
end
function M.open(body,key,width,big)local all=entries();if all[key]then detail(body,key,all[key],width,big)end end
return M
