local Players=game:GetService('Players')
local UI=require(script.Parent.ToyUI)
local Theme=require(script.Parent.Theme)
local Icons=require(script.Parent.OutgameIcons)
local Emblem=require(script.Parent.RankEmblem)
local Board=require(script.Parent.RankBoard)
local Rules=require(script.Parent.Parent.Core.RankedRules)
local M={}
local C=UI.colors
local function step(name,item)pcall(function()require(script.Parent.TelemetryClient).step('queue',name,{item=item})end)end
local function clock(n)n=math.max(0,math.floor(n or 0));return string.format('%d:%02d',n//60,n%60)end
local ladderInfo={
    ['1v1']={title='1대1',sub='솔로 2명',icon='solo'},
    ['2v2']={title='2대2',sub='솔로 또는 친구와 4명',icon='friends'},
}
local function text(parent,name,value,size,color,x,y,w,h)
    local l=UI.label(parent,name,value,size,color);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(l,x,y,w,h);return l
end
local function tierLabel(v)
    if v.placing then return '배치 중'end
    return v.division and (v.tierName..' '..v.division)or v.tierName
end
local function ladderCard(lobby,parent,ladder,v,x,y,w,h,ctx)
    local info=ladderInfo[ladder];local tier=v.placing and 'unranked'or v.tier;local color=Emblem.color(tier)
    local card=UI.panel(parent,'Ladder'..ladder);card.BackgroundColor3=C.raised;card.BackgroundTransparency=.08;UI.box(card,x,y,w,h)
    UI.make('UIGradient',card,{Rotation=90,Transparency=NumberSequence.new(0,.25)})
    UI.make('Frame',card,{Name='TierStrip',BackgroundColor3=color,BorderSizePixel=0,Size=UDim2.new(1,0,0,3)})
    local icon=Icons.create(card,info.icon,18,C.muted);UI.box(icon,14,14,18,18)
    local mode=text(card,'Mode',info.title,20,C.ink,38,8,w-120,30);UI.display(mode)
    text(card,'ModeSub',info.sub,12,C.muted,38,34,w-52,18)
    local e=Emblem.create(card,'Emblem',76,tier,not v.placing and v.division or nil);UI.box(e,12,58,76,76)
    local tx=100;local tw=w-tx-14
    local t=text(card,'Tier',tierLabel(v),18,v.placing and C.muted or color,tx,60,tw,24)
    local rp=text(card,'RP',v.placing and string.format('배치 %d/%d',v.placementTotal-v.placementLeft,v.placementTotal)or Theme.commas(v.rp)..' RP',26,C.ink,tx,84,tw,32);UI.display(rp,true)
    local barY=120
    if v.placing then
        local n=v.placementTotal;local gap=6;local pw=math.min(28,(tw-gap*(n-1))/n)
        for i=1,n do local done=i<=v.placementTotal-v.placementLeft
            local pip=UI.make('Frame',card,{Name='Pip'..i,BackgroundColor3=done and C.accent or C.line,BorderSizePixel=0});UI.corner(pip,2);UI.box(pip,tx+(i-1)*(pw+gap),barY+2,pw,6)
        end
    elseif v.toNext then
        local bg=UI.make('Frame',card,{Name='Bar',BackgroundColor3=C.bg,BorderSizePixel=0});UI.corner(bg,2);UI.box(bg,tx,barY+2,tw,6)
        local fill=UI.make('Frame',bg,{Name='Fill',BackgroundColor3=color,BorderSizePixel=0,Size=UDim2.fromScale(math.clamp(1-v.toNext/100,.04,1),1)});UI.corner(fill,2)
    end
    local note=v.placing and string.format('%d판 더 하면 등급 공개',v.placementLeft)or v.toNext and string.format('다음 단계까지 %d RP',v.toNext)or '최상위 등급, 순위 경쟁'
    text(card,'Next',note,12,C.muted,tx,barY+12,tw,18)
    local record=v.games>0 and string.format('%d승 %d패  최고 %s',v.wins,v.losses,Theme.commas(v.peak))or '이번 시즌 기록 없음'
    text(card,'Record',record,13,C.muted,14,h-96,w-28,20)
    local q=ctx.queue;local mine=q and q.mode=='ranked'and q.ladder==ladder;local other=q and not mine
    local by=h-62
    if mine then
        local status=text(card,'Searching','',15,C.accent,14,by,w-28-96,44);status.Name='Searching'
        if lobby.rankedQ~=q then lobby.rankedQ=q;lobby.rankedQAt=os.clock()end
        local function paint()
            local waited=(q.waited or 0)+(os.clock()-(lobby.rankedQAt or os.clock()))
            local window=waited>=60 and '모든 점수'or string.format('±%d RP',waited>=45 and 500 or waited>=30 and 350 or waited>=15 and 200 or 100)
            status.Text=q.phase=='transferring'and '상대 찾음, 전장으로 이동 중'or string.format('상대 찾는 중 %s  %s',clock(waited),window)
        end
        paint();task.spawn(function()while status.Parent do task.wait(1);if status.Parent then paint()end end end)
        local cancel=UI.button(card,'RankedCancel'..ladder,'취소',function()step('rankedCancel',ladder);lobby:request('cancel')end);UI.box(cancel,w-14-88,by,88,48);UI.enabled(cancel,q.phase~='transferring'and not lobby.busy)
    else
        local party=ctx.partySize;local reason
        if not ctx.enabled then reason='곧 열려요'
        elseif other then reason='다른 대기 중'
        elseif ladder=='1v1'and party>1 then reason='1대1은 혼자 참가'
        elseif party>2 then reason='2대2는 둘까지'
        elseif not ctx.loaded then reason='전적 불러오는 중'end
        local label=reason or (ladder=='2v2'and party==2 and '친구와 대전 찾기'or '대전 찾기')
        local b=UI.button(card,'RankedJoin'..ladder,label,function()step('rankedJoin',ladder);lobby:request('ranked',ladder)end,reason==nil)
        UI.box(b,14,by,w-28,48);b.TextSize=16;UI.enabled(b,reason==nil and not lobby.busy)
        if not ctx.enabled then local lock=Icons.create(b,'lock',14,C.muted);UI.box(lock,14,15,14,14)end
    end
    return card
end
local function tabs(lobby,parent,list,current,x,y,w,key,area)
    local n=#list;local gap=6;local bw=(w-gap*(n-1))/n
    for i,t in ipairs(list)do local on=t[1]==current
        local b=UI.button(parent,area..'_'..t[1],t[2],function()if lobby[key]~=t[1]then lobby[key]=t[1];step(area,t[1]);lobby:drawPage()end end,on)
        UI.box(b,x+(i-1)*(bw+gap),y,bw,48);b.TextSize=14
    end
    return 54
end
local function rewardsView(parent,v,x,y,w)
    local bestBand
    for _,ladder in ipairs(Rules.ladders)do local l=v.ladders[ladder];if l and not l.placing then
        local b=Rules.band(l.rp,l.rank);if not bestBand or Rules.rewards[b]>Rules.rewards[bestBand]then bestBand=b end end end
    local head=text(parent,'RewardHead','시즌이 끝나면 등급만큼 코인',15,C.ink,x+4,y,w-8,24);y+=26
    local info=UI.label(parent,'RewardHow','다음 시즌 첫 접속 때 1회 지급, 1대1과 2대2 중 높은 쪽, 배치 완료자',12,C.muted);UI.box(info,x+4,y,w-8,34);y+=40
    if v.lastReward then
        local got=UI.panel(parent,'LastReward');got.BackgroundColor3=C.raised;UI.box(got,x,y,w,40);got:FindFirstChildOfClass('UIStroke').Color=C.gold
        local i=Icons.create(got,'coin',18,C.gold);UI.box(i,12,11,18,18)
        text(got,'LastText',string.format('지난 시즌 보상 받음, %s  +%s 코인',Rules.bandName(v.lastReward.band),Theme.commas(v.lastReward.coins)),14,C.gold,38,0,w-50,40);y+=48
    end
    local conditions={top1='시즌 순위 1위',top10='시즌 순위 2~10위',legend='시즌 순위 11~100위',master='2,100 RP 이상',diamond='1,800 RP 이상',platinum='1,500 RP 이상',gold='1,200 RP 이상',silver='900 RP 이상',bronze='배치 완료'}
    for i=#Rules.rewardOrder,1,-1 do local id=Rules.rewardOrder[i]
        local mine=id==bestBand
        local row=UI.panel(parent,'Band_'..id);row.BackgroundTransparency=mine and 0 or .3;row.BackgroundColor3=mine and C.raised or C.panel;UI.box(row,x,y,w,46)
        if mine then local s=row:FindFirstChildOfClass('UIStroke');s.Color=C.accent;s.Thickness=1.5 end
        local tier=(id=='top1'or id=='top10')and 'legend'or id
        local e=Emblem.create(row,'Emblem',34,tier,id=='top1'and '1'or id=='top10'and '10'or nil);UI.box(e,8,6,34,34)
        text(row,'Name',Rules.bandName(id),15,Emblem.color(tier),50,4,w*.45,22)
        text(row,'Need',conditions[id],12,C.muted,50,24,w*.5,18)
        local coins=text(row,'Coins',Theme.commas(Rules.rewards[id]),17,C.gold,w-130,0,90,46);coins.TextXAlignment=Enum.TextXAlignment.Right;UI.display(coins,true)
        local ci=Icons.create(row,'coin',18,C.gold);UI.box(ci,w-34,14,18,18)
        if mine then local pill=UI.pill(row,'Mine','지금 등급',C.accent);UI.box(pill,w-130-76,13,68,20)end
        y+=52
    end
    return y
end
local ruleLines={
    {'ranked','원작 오픈프론트 랭크 규칙 그대로'},
    {'fields','지도: 오스트레일리아 40%, 아이슬란드, 아시아, 유럽 클래식 각 20%'},
    {'deploy','AI 국가 없음, 중립 봇 100, 10분 제한'},
    {'solo','1대1: 끝까지 남은 지휘관 승리, 시작 보호 30초'},
    {'friends','2대2: 마지막 남은 팀 승리, 팀원 지원 가능, 시작 보호 60초'},
    {'records','10분이 끝나면 땅이 가장 넓은 쪽 승리, 80% 점령 시 즉시 승리'},
    {'check','모두 접속해야 시작, 못 모이면 점수 변동 없이 취소'},
    {'daily','배치 5판, 매달 1일 0시(UTC) 초기화, 점수 절반 유지, 재배치 3판'},
    {'lock','같은 상대와 하루 4번째 판부터 점수 절반, 6번째부터 없음'},
    {'medal','점수와 판수는 팔지 않아요'},
}
function M.summary(v,q)
    if q and q.mode=='ranked'then return q.phase=='transferring'and '상대 찾음, 이동 중'or (q.ladder=='clanwar'and '클랜전 상대 찾는 중'or q.ladder=='2v2'and '2대2 상대 찾는 중'or '1대1 상대 찾는 중')end
    if not v then return '1대1, 2대2'end
    if not v.enabled then return '곧 열려요  1대1, 2대2'end
    local best;for _,ladder in ipairs(Rules.ladders)do local l=v.ladders[ladder];if l and l.games>0 and (not best or (not l.placing and (best.placing or l.rp>best.rp)))then best=l end end
    if not best then return string.format('%s  1대1, 2대2',v.season.label)end
    local title=best.ladder=='2v2'and '2대2'or '1대1'
    if best.placing then return string.format('%s 배치 %d/%d',title,best.placementTotal-best.placementLeft,best.placementTotal)end
    return string.format('%s %s  %s RP',title,tierLabel(best),Theme.commas(best.rp))
end
function M.draw(lobby,p,w)
    lobby.pageTitle.Text='랭크전'
    if not lobby.rankedSeen then lobby.rankedSeen=true;step('rankedOpen')end
    local data=lobby.data or {};local v=data.ranked
    if v and v.ladders and not lobby.rankedStateLogged then lobby.rankedStateLogged=true;pcall(function()for _,ladder in ipairs(Rules.ladders)do local l=v.ladders[ladder];if l then
        require(script.Parent.TelemetryClient).step('ranked','view',{item='r'..tostring(ladder),result=not v.enabled and 'unavailable'or l.placing and 'pending'or 'ready',level=l.rp,count=l.games,value=l.placing and l.placementLeft or nil})
    end end end)end
    local cw=w-10;local y=0
    if not v then
        local l=UI.label(p,'Loading','랭크 정보 불러오는 중…',15,C.muted);l.TextXAlignment=Enum.TextXAlignment.Center;UI.box(l,2,20,cw,40)
        p.CanvasSize=UDim2.fromOffset(0,80);return
    end
    local s=v.season
    local banner=UI.panel(p,'SeasonBanner');banner.BackgroundColor3=C.raised;banner.BackgroundTransparency=0;UI.box(banner,2,y,cw,78)
    UI.make('UIGradient',banner,{Rotation=0,Color=ColorSequence.new(Color3.fromRGB(40,34,18),C.raised),Transparency=NumberSequence.new(0,.1)})
    banner:FindFirstChildOfClass('UIStroke').Color=C.gold
    local bi=Icons.create(banner,'ranked',30,C.gold);UI.box(bi,16,24,30,30)
    local title=text(banner,'SeasonTitle',s.label,24,C.ink,56,8,cw-220,34);UI.display(title)
    text(banner,'SeasonSub',string.format('매달 1일 초기화, %d일 남음',s.daysLeft),13,C.muted,56,42,cw-220,22)
    local chip=UI.pill(banner,'SeasonState',v.live and '진행 중'or v.enabled and 'STUDIO 테스트'or v.paused and '잠시 점검 중'or '곧 오픈',v.live and C.accent or C.gold);UI.box(chip,cw-14-104,14,104,24)
    local seal=UI.label(banner,'Seal','NO PAY-TO-WIN',13,C.muted);seal.TextXAlignment=Enum.TextXAlignment.Right;UI.box(seal,cw-14-180,46,180,18)
    y+=86
    local party=data.party;local ctx={queue=data.queue,enabled=v.enabled,loaded=v.loaded,partySize=party and party.users and #party.users or 1}
    local two=cw>=540;local gap=10;local cardH=228
    if two then local half=(cw-gap)/2
        ladderCard(lobby,p,'1v1',v.ladders['1v1'],2,y,half,cardH,ctx);ladderCard(lobby,p,'2v2',v.ladders['2v2'],2+half+gap,y,half,cardH,ctx);y+=cardH+12
    else
        ladderCard(lobby,p,'1v1',v.ladders['1v1'],2,y,cw,cardH,ctx);y+=cardH+10
        ladderCard(lobby,p,'2v2',v.ladders['2v2'],2,y,cw,cardH,ctx);y+=cardH+12
    end
    local q=data.queue
    if q and q.mode=='ranked'and q.ladder=='clanwar'then
        local bar=UI.panel(p,'ClanWarSearch');bar.BackgroundColor3=C.raised;bar.BackgroundTransparency=.08;UI.box(bar,2,y,cw,56)
        bar:FindFirstChildOfClass('UIStroke').Color=C.accent
        local status=text(bar,'Searching','',15,C.accent,14,6,cw-28-100,44)
        if lobby.rankedQ~=q then lobby.rankedQ=q;lobby.rankedQAt=os.clock()end
        local function paint()status.Text=q.phase=='transferring'and '클랜전 상대 찾음, 전장으로 이동 중'or string.format('클랜전 상대 찾는 중 %s',clock((q.waited or 0)+(os.clock()-(lobby.rankedQAt or os.clock()))))end
        paint();task.spawn(function()while status.Parent do task.wait(1);if status.Parent then paint()end end end)
        local cancel=UI.button(bar,'RankedCancelclanwar','취소',function()step('rankedCancel','clanwar');lobby:request('cancel')end);UI.box(cancel,cw-14-88,6,88,44);UI.enabled(cancel,q.phase~='transferring'and not lobby.busy)
        y+=66
    end
    if v.last and v.last.delta then
        local d=v.last.delta;local up=d>=0
        local l=UI.label(p,'LastResult',string.format('최근 %s  %s%d RP',v.last.ladder=='2v2'and '2대2'or '1대1',up and '+'or '',d),13,up and C.good or C.danger);UI.box(l,4,y,cw-8,20);y+=28
    end
    lobby.rankedTab=lobby.rankedTab or 'board'
    y+=tabs(lobby,p,{{'board','순위'},{'rewards','시즌 보상'},{'rules','규칙'}},lobby.rankedTab,2,y,cw,'rankedTab','rankedTab')+6
    if lobby.rankedTab=='board'then
        lobby.rankedBoard=lobby.rankedBoard or '1v1'
        y+=tabs(lobby,p,{{'1v1','1대1'},{'2v2','2대2'},{'clan','클랜전'}},lobby.rankedBoard,2,y,cw,'rankedBoard','rankedBoard')+4
        local which=lobby.rankedBoard
        if which=='clan'then
            local cw2=data.clanWar;local rows=cw2 and cw2.board or {}
            y+=Board.draw(p,{x=2,y=y,w=cw},rows,{empty=cw2 and (cw2.loading and '순위 불러오는 중…'or '이번 시즌 클랜전 기록 없음')or '클랜전은 클랜과 함께 열려요',rowHeight=44})
        else
            local rows=v.boards[which]or {};local me
            local seen=false;for _,r in ipairs(rows)do if r.self then seen=true end end
            local l=v.ladders[which]
            if not seen and l and not l.placing and l.games>0 then me={name=Players.LocalPlayer.DisplayName,value=l.rp,tier=l.tier,self=true,userId=Players.LocalPlayer.UserId}end
            y+=Board.draw(p,{x=2,y=y,w=cw},rows,{me=me,empty=v.boardsLoading and v.boardsLoading[which]and '순위 불러오는 중…'or '배치 5판을 마친 지휘관부터 순위에 올라요'})
        end
    elseif lobby.rankedTab=='rewards'then
        y=rewardsView(p,v,2,y,cw)
    else
        for i,r in ipairs(ruleLines)do
            local row=UI.panel(p,'Rule'..i);row.BackgroundTransparency=.35;UI.box(row,2,y,cw,40)
            local ic=Icons.create(row,r[1],16,i==1 and C.gold or C.accent);UI.box(ic,12,12,16,16)
            local l=UI.label(row,'Text',r[2],13,i==1 and C.gold or C.ink);UI.box(l,38,0,cw-50,40)
            y+=44
        end
    end
    p.CanvasSize=UDim2.fromOffset(0,y+12)
end
return M
