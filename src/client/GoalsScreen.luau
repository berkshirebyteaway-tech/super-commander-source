local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local Currency=require(script.Parent.CurrencyChip)
local Claims=require(script.Parent.GoalClaims)
local Step=require(script.Parent.TelemetryStep)
local Rules=require(script.Parent.Parent.Core.OutgameRules)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local M={}
local C=UI.colors
local NARROW=false
local GREEN=Color3.fromRGB(150,214,84)
local BRONZE,SILVER,GOLD=Color3.fromRGB(196,128,72),Color3.fromRGB(176,190,206),Color3.fromRGB(232,184,72)
local TABS={{'campaign','캠페인','캠페인','campaign'},{'challenges','도전과제','도전','crest'},{'today','오늘과 주간','오늘','daily'},{'season','시즌','시즌','podium'},{'career','경력','경력','medal'}}
local SHORT={noNukeWin='핵 없이 승리',comeback='5%에서 역전승',blitz='10분 안에 승리',cityWin='도시 10개 후 승리',landing='수송선 3척 후 승리',
    pvpVictor='사람과 대전 승리',coopVictor='연합전 승리',dominion='영토 75%',rapidGrowth='3분 안에 영토 10%',ally='동료 지원 10회',
    fortress='거점 5개로 10분',airDefense='방공 기지 3개',harbor='항구 3개',fleet='전함 5척',silo='미사일 기지 2개',nuclear='핵 3발 발사',
    developer='업그레이드 5회',comrades='파티 친구와 승리',survivor='20분 넘게 끝내기'}
local ACH_ICON={firstWin='deploy',games10='records',cities25='fields',peak50='watch',coopWin='friends',pvpWin='marshal',streak7='daily',wins10='ranked',maps5='solo',games50='clan'}
local TACTIC_ICON={noNukeWin='clan',comeback='ranked',blitz='quick',cityWin='fields',landing='deploy',pvpVictor='marshal',coopVictor='friends',dominion='watch',
    rapidGrowth='quick',ally='friends',fortress='clan',airDefense='clan',harbor='fields',fleet='deploy',silo='deploy',nuclear='deploy',developer='fields',comrades='friends',survivor='records'}
local MODES={{'single','캠페인','solo'},{'pvp','대전','marshal'},{'coop','연합전','friends'}}

local function label(parent,name,text,size,color,x,y,w,h,align)
    local l=UI.label(parent,name,text,size or 14,color or C.ink);UI.box(l,x,y,w,h)
    if align then l.TextXAlignment=align end;return l
end
local function bold(l)l.Font=Enum.Font.BuilderSansBold;return l end
local function fit(l,max,min)l.TextWrapped=false;l.TextScaled=true;UI.make('UITextSizeConstraint',l,{MaxTextSize=max,MinTextSize=min});return l end
local function card(parent,name,x,y,w,h,fill)
    local p=UI.panel(parent,name);UI.box(p,x,y,w,h);p.BackgroundColor3=fill or C.panel;p.BackgroundTransparency=.04;return p
end
local function edge(p,color,thick)local s=p:FindFirstChildOfClass('UIStroke');if s then s.Color=color;s.Thickness=thick or 1;s.Transparency=0 end end
local function bar(parent,name,x,y,w,ratio,color,h)
    local track=UI.corner(UI.make('Frame',parent,{Name=name,BackgroundColor3=C.raised,BorderSizePixel=0}),4);UI.box(track,x,y,w,h or 6)
    UI.corner(UI.make('Frame',track,{Name='Fill',BackgroundColor3=color or C.accent,BorderSizePixel=0,Size=UDim2.fromScale(math.clamp(ratio or 0,0,1),1)}),4)
    return track
end
local function ring(parent,name,x,y,size,ratio,color,thick)
    local f=UI.make('Frame',parent,{Name=name,BackgroundTransparency=1});UI.box(f,x,y,size,size)
    local function circle(p)local c=UI.make('Frame',p,{BackgroundTransparency=1,Size=UDim2.fromOffset(size,size)});UI.corner(c,999)
        local s=Instance.new('UIStroke');s.Thickness=thick or 4;s.Color=color;s.Parent=c;return c,s end
    local _,ts=circle(f);ts.Color=C.raised
    ratio=math.clamp(ratio or 0,0,1)
    for half=0,1 do if (half==0 and ratio>0)or (half==1 and ratio>.5)then
        local clip=UI.make('Frame',f,{Name='Half'..half,BackgroundTransparency=1,ClipsDescendants=true,Position=UDim2.fromOffset(half==0 and size/2 or 0,0),Size=UDim2.fromOffset(size/2,size)})
        local c,s=circle(clip);c.Position=UDim2.fromOffset(half==0 and -size/2 or 0,0);s.Color=color
        local g=Instance.new('UIGradient');g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(.501,1),NumberSequenceKeypoint.new(1,1)})
        if half==0 then g.Rotation=math.min(ratio,.5)/.5*180 else g.Rotation=180+math.clamp(ratio-.5,0,.5)/.5*180 end
        g.Parent=s
    end end
    return f
end
local function crest(parent,x,y,size)
    local f=UI.make('Frame',parent,{Name='Crest',BackgroundTransparency=1});UI.box(f,x,y,size,size)
    for _,v in ipairs({{'crestShield',Color3.fromRGB(40,72,132)},{'crestLaurel',GOLD},{'crestStar',Color3.fromRGB(244,206,92)}})do
        local i=Icons.create(f,v[1],size,v[2]);i.Name=v[1];UI.box(i,0,0,size,size)
    end
    return f
end
local function chip(parent,name,text,color,x,y,w,h,textColor)
    local c=UI.make('TextLabel',parent,{Name=name,Text=text,TextSize=13,Font=Enum.Font.BuilderSansBold,TextColor3=textColor or C.bg,BackgroundColor3=color,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Center})
    UI.corner(c,999);UI.box(c,x,y,w,h or 22);c:SetAttribute('AllowOverlap',true);fit(c,13,9);UI.make('UIPadding',c,{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)});return c
end
local function corners(parent)
    for i,a in ipairs({{0,0},{1,0},{0,1},{1,1}})do
        for k=0,1 do local f=UI.make('Frame',parent,{Name='Corner'..i..k,BackgroundColor3=C.ink,BorderSizePixel=0,BackgroundTransparency=.1,AnchorPoint=Vector2.new(a[1],a[2]),Position=UDim2.new(a[1],a[1]==0 and 4 or -4,a[2],a[2]==0 and 4 or -4),Size=k==0 and UDim2.fromOffset(14,2)or UDim2.fromOffset(2,14)})end
    end
end
local function divider(parent,text,x,y,w)
    local l=bold(label(parent,'Divider',text,14,C.ink,x,y,w,22,Enum.TextXAlignment.Center))
    local tw=game:GetService('TextService'):GetTextSize(text,14,Enum.Font.BuilderSansBold,Vector2.new(800,22)).X+24
    for i,s in ipairs({-1,1})do local line=UI.make('Frame',parent,{Name='DividerLine'..i,BackgroundColor3=C.line,BorderSizePixel=0});UI.box(line,s<0 and x or x+(w+tw)/2,y+11,(w-tw)/2,1)end
    return l
end
local function claimDots(p)
    local daily,weekly,ach=false,false,false
    for _,c in ipairs(Claims.list(p))do if c.source=='daily'then daily=true elseif c.source=='weekly'then weekly=true elseif c.source=='achievement'then ach=true end end
    return {challenges=ach,today=daily or weekly}
end
local function commas(n)local s=tostring(math.floor(n or 0));local out=s:reverse():gsub('(%d%d%d)','%1,'):reverse();return (out:gsub('^,',''))end
local function mapLabel(key)local m=Maps.meta(key);return m and m.label or key end
local function percent(w,l)return w+l>0 and math.floor(w/(w+l)*100+.5)or 0 end

local function seasonBoard(hub)
    local now=os.clock();local b=hub.seasonBoard
    if hub.seasonBoardLoading or (b and now-(hub.seasonBoardAt or -999)<60)then return b end
    hub.seasonBoardLoading=true
    task.spawn(function()
        local ok,r=pcall(function()return game.ReplicatedStorage.FrontierNative.AccountRequest:InvokeServer('seasonBoard')end)
        hub.seasonBoardLoading=false
        if ok and type(r)=='table'and r.ok then hub.seasonBoard=r;hub.seasonBoardAt=os.clock()else hub.seasonBoardAt=os.clock()-45 end
        if hub.page=='missions'and hub.goalTab=='season'then hub:drawPage()end
    end)
    return b
end

local function nearest(p)
    local list={}
    for _,a in ipairs(p.achievementList or {})do if not a.done and a.target>0 then table.insert(list,{kind='ach',a=a,ratio=a.progress/a.target})end end
    for _,t in ipairs(p.tactics or {})do if t.next then table.insert(list,{kind='tactic',t=t,ratio=t.count/t.next})end end
    table.sort(list,function(x,y)if x.ratio~=y.ratio then return x.ratio>y.ratio end;return (x.a and x.a.id or x.t.id)<(y.a and y.a.id or y.t.id)end)
    return {list[1],list[2],list[3]}
end
local function achievementCard(hub,parent,a,x,y,w,h,phone)
    local p=hub.account.progress or {};local shop=hub.callbacks.shop()
    local done=a.done;local ratio=a.target>0 and a.progress/a.target or 0
    local c=card(parent,'Achievement_'..a.id,x,y,w,h,done and Color3.fromRGB(44,38,20)or nil)
    if done then edge(c,GOLD:Lerp(C.panel,.35))end
    local rs=phone and 42 or 52
    local r=ring(c,'Ring',12,(h-rs)/2-(phone and 0 or 6),rs,done and 1 or ratio,done and GOLD or C.accent,4)
    local ic=Icons.create(r,ACH_ICON[a.id]or 'medal',rs*.5,done and GOLD or C.ink);UI.box(ic,rs*.25,rs*.25,rs*.5,rs*.5)
    local tx=12+rs+12
    local tight=not phone and w<260
    local nm=bold(label(c,'Name',a.name,15,C.ink,tx,phone and 6 or 12,tight and w-tx-12 or w-tx-80,22));nm.TextWrapped=false;nm.TextTruncate=Enum.TextTruncate.AtEnd
    local d=label(c,'Detail',a.detail,13,C.muted,tx,phone and 28 or 36,w-tx-12,(phone or tight) and 20 or 34);d.TextWrapped=not tight;d.TextYAlignment=Enum.TextYAlignment.Top
    if tight then d.TextTruncate=Enum.TextTruncate.AtEnd end
    if Claims.pending(p,'a:'..a.id)then
        Claims.dot(c,true);local b=Claims.button(c,'ClaimAchievement','받기',function()Step.step('goals','claim',{item=a.id});Claims.claim(hub,'a:'..a.id)end);UI.box(b,w-92,h-54,80,44);UI.enabled(b,not shop.busy)
    elseif done then
        label(c,'Done',string.format('달성  +%d 코인',a.medals),13,GOLD,tx,h-28,w-tx-12,20)
    else
        Currency.create(c,'medal',a.medals,w-82,tight and 60 or 8,72,22)
        bar(c,'Progress',tx,h-(phone and 16 or 22),w-tx-70,ratio,GREEN:Lerp(C.accent,.4))
        label(c,'Value',string.format('%d/%d',a.progress,a.target),13,C.ink,w-64,h-(phone and 24 or 30),54,20,Enum.TextXAlignment.Right)
        if ratio>=.6 then chip(c,'Soon','곧 달성',C.accent,NARROW and 8 or w-96,-11,84,22)end
    end
    return c
end
local function tacticCard(parent,t,x,y,w,h)
    local c=card(parent,'Tactic_'..t.id,x,y,w,h)
    local tint=t.tier>=3 and GOLD or t.tier==2 and SILVER or t.tier==1 and BRONZE or C.line
    local hs=h-12
    local fill=Icons.create(c,'hexFill',hs,C.bg);UI.box(fill,8,6,hs,hs)
    local rim=Icons.create(c,'hexRing',hs,tint);rim.Name='Rim';UI.box(rim,8,6,hs,hs)
    local ic=Icons.create(c,TACTIC_ICON[t.id]or 'medal',hs*.46,t.tier>0 and C.ink or C.muted);UI.box(ic,8+hs*.27,6+hs*.27,hs*.46,hs*.46)
    local tx=8+hs+10
    bold(label(c,'Name',t.name,14,t.tier>0 and C.ink or C.muted,tx,6,w-tx-60,20)).TextTruncate=Enum.TextTruncate.AtEnd
    label(c,'Detail',SHORT[t.id]or t.detail,13,C.muted,tx,h-26,w-tx-56,20).TextTruncate=Enum.TextTruncate.AtEnd
    local stars=label(c,'Stars',string.rep('★',t.tier)..string.rep('☆',3-t.tier),13,t.tier>0 and GOLD or C.muted,w-58,6,48,20,Enum.TextXAlignment.Right)
    stars.TextColor3=t.tier>=3 and GOLD or t.tier>0 and BRONZE:Lerp(GOLD,.4)or C.muted
    label(c,'Count',t.next and string.format('%d/%d',t.count,t.next)or '완료',13,C.ink,w-58,h-26,48,20,Enum.TextXAlignment.Right)
    return c
end
local function drawChallenges(hub,body,x,w,y,phone)
    local p=hub.account.progress or {};local list=p.achievementList or {}
    local earned,total=0,0;for _,a in ipairs(list)do total+=a.medals;if a.done then earned+=a.medals end end
    local maps=0;for _ in pairs(p.conquest or {})do maps+=1 end
    local hh=NARROW and 148 or phone and 82 or 132
    local hero=card(body,'ChallengeHero',x,y,w,hh,Color3.fromRGB(22,28,38));corners(hero)
    local cs=phone and 56 or 92;crest(hero,phone and 12 or 28,NARROW and 12 or (hh-cs)/2,cs)
    local tx=(phone and 12 or 28)+cs+(phone and 12 or 20)
    local tightHero=not phone and w<1100
    local bw=NARROW and w-24 or phone and 160 or tightHero and 184 or 220
    local tw=NARROW and w-tx-12 or phone and w-tx-bw-24 or 360
    bold(label(hero,'Title','도전과제',phone and 20 or 30,C.ink,tx,phone and 10 or 18,tw,phone and 28 or 40))
    if phone then
        label(hero,'Summary',string.format('업적 %d/%d  기장 ★%d  정복 %d곳',p.achievementsUnlocked or 0,#list,p.tacticTiers or 0,p.mapsConquered or 0),14,C.muted,tx,42,tw,24)
    else
        local leadW=tightHero and 250 or 380
        label(hero,'Lead','한 번 깨면 영원히 남아요. 보상은 받기로 바로 들어와요.',14,C.muted,tx,62,380,22).Visible=not tightHero
        label(hero,'Earned',string.format('받은 보상 %s 코인  /  모두 깨면 %s',commas(earned),commas(total)),13,C.ink,tx,tightHero and 70 or 92,leadW,tightHero and 40 or 22)
        local sx=tx+leadW+20;local sw=tightHero and math.max(80,(w-sx-bw-48-24)/3)or math.max(120,(w-sx-bw-48)/3)
        for i,s in ipairs({{'업적',string.format('%d / %d',p.achievementsUnlocked or 0,#list),(p.achievementsUnlocked or 0)/math.max(1,#list)},
            {'전술 기장',string.format('★ %d / %d',p.tacticTiers or 0,p.tacticTierMax or 0),(p.tacticTiers or 0)/math.max(1,p.tacticTierMax or 1)},
            {'지도 정복',string.format('%d곳',p.mapsConquered or 0),(p.mapsConquered or 0)/math.max(1,maps)}})do
            local cx=sx+(i-1)*(sw+12)
            label(hero,'StatLabel'..i,s[1],13,C.muted,cx,26,sw,20);local sv=bold(label(hero,'StatValue'..i,s[2],24,C.ink,cx,48,sw,32))
            if tightHero then sv.TextWrapped=false;sv.TextScaled=true;UI.make('UITextSizeConstraint',sv,{MaxTextSize=24,MinTextSize=15})end
            bar(hero,'StatBar'..i,cx,94,sw,s[3],GREEN:Lerp(C.accent,.4))
        end
    end
    local go=UI.button(hero,'CampaignStart','',function()Step.step('goals','campaign',{});hub.goalTab='campaign';hub:drawPage()end,true)
    UI.box(go,w-bw-(phone and 12 or 24),NARROW and hh-68 or (hh-(phone and 56 or 76))/2,bw,phone and 56 or 76)
    local Campaign=require(script.Parent.Parent.Core.CampaignRules);local cv=p.campaign or {};local nextStage=Campaign.stage(cv.next)or Campaign.stages[1]
    bold(label(go,'Action','캠페인',phone and 17 or 20,C.bg,0,phone and 6 or 12,bw,26,Enum.TextXAlignment.Center))
    label(go,'Rules',string.format('%s %s  ★ %d/%d',nextStage.id,nextStage.name,cv.total or 0,Campaign.maxStars),13,C.bg,0,phone and 32 or 44,bw,20,Enum.TextXAlignment.Center).TextTruncate=Enum.TextTruncate.AtEnd
    y+=hh+(phone and 10 or 16)
    if not phone then
        divider(body,'가까운 도전',x,y,w);y+=32
        local cw=(w-24)/3
        for i,n in ipairs(nearest(p))do
            local c=card(body,'Near'..i,x+(i-1)*(cw+12),y,cw,108)
            if n.kind=='ach'then local a=n.a
                local r=ring(c,'Ring',16,24,60,n.ratio,C.accent,4);local ic=Icons.create(r,ACH_ICON[a.id]or 'medal',28,C.ink);UI.box(ic,16,16,28,28)
                chip(c,'Kind','업적',C.raised,94,10,72,22,C.ink);Currency.create(c,'medal',a.medals,cw-92,10,80,22)
                bold(label(c,'Name',a.name,17,C.ink,94,36,cw-110,24))
                label(c,'Detail',a.detail,13,C.muted,94,60,cw-110,20).TextTruncate=Enum.TextTruncate.AtEnd
                bar(c,'Progress',94,88,cw-170,n.ratio,GREEN:Lerp(C.accent,.4));label(c,'Value',string.format('%d/%d',a.progress,a.target),13,C.ink,cw-70,80,58,20,Enum.TextXAlignment.Right)
            else local t=n.t
                local fill=Icons.create(c,'hexFill',60,C.bg);UI.box(fill,16,24,60,60);local rim=Icons.create(c,'hexRing',60,t.tier>=2 and SILVER or BRONZE);rim.Name='Rim';UI.box(rim,16,24,60,60)
                local ic=Icons.create(c,TACTIC_ICON[t.id]or 'medal',26,C.ink);UI.box(ic,33,41,26,26)
                chip(c,'Kind','전술 기장',C.raised,94,10,76,22,C.ink)
                label(c,'Stars',string.rep('★',t.tier)..string.rep('☆',3-t.tier),13,GOLD,176,10,50,22)
                Currency.create(c,'xp',Rules.tacticTierXP[t.tier+1]or 0,cw-100,10,88,22)
                bold(label(c,'Name',t.name,17,C.ink,94,36,cw-110,24))
                label(c,'Detail',string.format('%s  %s까지 %d판',SHORT[t.id]or t.detail,string.rep('★',t.tier+1),math.max(0,t.next-t.count)),13,C.muted,94,60,cw-110,20).TextTruncate=Enum.TextTruncate.AtEnd
                bar(c,'Progress',94,88,cw-170,n.ratio,GREEN:Lerp(C.accent,.4));label(c,'Value',string.format('%d/%d',t.count,t.next),13,C.ink,cw-70,80,58,20,Enum.TextXAlignment.Right)
            end
        end
        y+=124
    end
    hub.challengeTab=hub.challengeTab or 'ach'
    local subs={{'ach',string.format('업적 %d/%d',p.achievementsUnlocked or 0,#list)},{'tactics',string.format('%s ★%d/%d',phone and '기장'or '전술 기장',p.tacticTiers or 0,p.tacticTierMax or 0)},{'conquest',string.format('%s %d곳',phone and '정복'or '지도 정복',p.mapsConquered or 0)}}
    local sw=NARROW and w/3 or phone and (w*.62)/3 or 132
    for i,s in ipairs(subs)do
        local on=hub.challengeTab==s[1]
        local b=UI.button(body,'ChallengeTab_'..s[1],s[2],function()if hub.challengeTab~=s[1]then hub.challengeTab=s[1];Step.step('goals','section',{item=s[1]});hub:drawPage()end end,false)
        UI.box(b,x+(i-1)*sw,y,sw,48);b.TextSize=14;fit(b,14,10);b.BackgroundColor3=on and C.raised:Lerp(C.ink,.12)or C.panel;b.TextColor3=on and C.ink or C.muted;b.Font=on and Enum.Font.BuilderSansBold or Enum.Font.BuilderSansMedium
    end
    label(body,'SectionNote',hub.challengeTab=='tactics'and '모두 한 판 기준, 별 하나마다 XP'or '진행 중인 것부터 보여요',13,C.muted,x+sw*3+12,y,w-sw*3-12,48,Enum.TextXAlignment.Right).Visible=not phone
    y+=60
    local cols=NARROW and 1 or phone and 2 or 5;local gap=phone and 10 or 12;local cw=(w-gap*(cols-1))/cols
    if hub.challengeTab=='ach'then
        local order={};for _,a in ipairs(list)do table.insert(order,a)end
        table.sort(order,function(a,b)local pa,pb=Claims.pending(p,'a:'..a.id),Claims.pending(p,'a:'..b.id);if pa~=pb then return pa end
            if a.done~=b.done then return not a.done end;local ra,rb=a.progress/math.max(1,a.target),b.progress/math.max(1,b.target);if ra~=rb then return ra>rb end;return a.id<b.id end)
        local ch=phone and 82 or 114
        for i,a in ipairs(order)do achievementCard(hub,body,a,x+(i-1)%cols*(cw+gap),y+math.floor((i-1)/cols)*(ch+gap)+12,cw,ch,phone)end
        y+=math.ceil(#order/cols)*(ch+gap)+12
    elseif hub.challengeTab=='tactics'then
        local order={};for _,t in ipairs(p.tactics or {})do table.insert(order,t)end
        table.sort(order,function(a,b)local ia,ib=a.tier>0 or a.count>0,b.tier>0 or b.count>0;if ia~=ib then return ia end;if a.tier~=b.tier then return a.tier>b.tier end;return a.id<b.id end)
        local ch=56
        for i,t in ipairs(order)do tacticCard(body,t,x+(i-1)%cols*(cw+gap),y+math.floor((i-1)/cols)*(ch+gap),cw,ch)end
        y+=math.ceil(#order/cols)*(ch+gap)
    else
        local rows={};for map,n in pairs(p.conquest or {})do table.insert(rows,{map=map,n=n})end
        table.sort(rows,function(a,b)if a.n~=b.n then return a.n>b.n end;return a.map<b.map end)
        if #rows==0 then label(body,'ConquestEmpty','아직 정복을 시작한 지도가 없어요. 캠페인 한 판이면 첫 칸이 채워져요.',14,C.muted,x,y,w,40);y+=48 end
        local steps=Rules.conquestSteps
        for _,r in ipairs(rows)do
            local c=card(body,'Conquest_'..r.map,x,y,w,phone and 76 or 60)
            bold(label(c,'Map',mapLabel(r.map),15,r.n>=#steps and GOLD or C.ink,14,phone and 6 or 0,phone and w-120 or 200,phone and 26 or 60))
            label(c,'Count',string.format('%d/%d',r.n,#steps),13,C.muted,phone and w-80 or w-60,phone and 6 or 0,phone and 66 or 48,phone and 26 or 60,Enum.TextXAlignment.Right)
            local sx=phone and 14 or 220;local sw2=(w-sx-(phone and 14 or 70)-(#steps-1)*8)/#steps
            for i,s in ipairs(steps)do
                local on=i<=r.n
                local st=UI.make('TextLabel',c,{Name='Step'..i,Text=s.name,TextSize=13,Font=Enum.Font.BuilderSansBold,TextColor3=on and C.bg or C.muted,BackgroundColor3=on and (r.n>=#steps and GOLD or C.accent)or C.raised,BorderSizePixel=0})
                UI.corner(st,6);UI.box(st,sx+(i-1)*(sw2+8),phone and 38 or 14,sw2,phone and 30 or 32)
            end
            y+=(phone and 76 or 60)+10
        end
    end
    return y
end

local function drawToday(hub,body,x,w,y,phone)
    local p=hub.account.progress or {};local shop=hub.callbacks.shop()
    local stale=os.time()>=(p.dailyReset or math.huge)
    if (p.onboardingDone or 0)<#Rules.onboarding then
        divider(body,string.format('처음 시작하기  %d/%d',p.onboardingDone or 0,#Rules.onboarding),x,y,w);y+=32
        local cols=phone and 2 or 4;local cw=(w-(cols-1)*12)/cols
        for i,m in ipairs(Rules.onboarding)do
            local done=p.onboarding and p.onboarding[m.id]
            local c=card(body,'First_'..m.id,x+(i-1)%cols*(cw+12),y+math.floor((i-1)/cols)*82,cw,72,done and Color3.fromRGB(30,44,24)or nil)
            bold(label(c,'Title',m.name,14,C.ink,14,8,cw-28,22))
            if done then label(c,'Done','✓ 받음',13,GREEN,14,40,cw-28,22)else Currency.create(c,'xp',m.xp,14,40,(cw-36)/2,22);Currency.create(c,'medal',m.medals,14+(cw-36)/2+8,40,(cw-36)/2,22)end
        end
        y+=math.ceil(#Rules.onboarding/cols)*82+10
    end
    local login=p.login or {};local steps=Rules.streakRewards;local current=login.rewardStep or 0
    local fw=phone and 0 or math.min(440,w*.34);local aw=phone and w or w-fw-16
    local att=card(body,'Attendance',x,y,aw,phone and 132 or 176)
    local ai=Icons.create(att,'daily',24,C.accent);UI.box(ai,18,18,24,24)
    bold(label(att,'Title',string.format('출석 %d일째',login.claims or 0),phone and 17 or 20,C.ink,50,12,200,36))
    if not phone then label(att,'Note','들어오기만 하면 받아요. 하루 쉬어도 이어져요.',13,C.muted,250,12,aw-264,36)end
    local dw=(aw-28-(#steps-1)*8)/#steps;local th=phone and 66 or 104
    for i,reward in ipairs(steps)do
        local got=i<=current;local today=i==current
        local d=card(att,'Day'..i,14+(i-1)*(dw+8),phone and 54 or 58,dw,th,today and Color3.fromRGB(56,44,16)or nil)
        if today then edge(d,GOLD,1.5)elseif i==#steps then edge(d,Color3.fromRGB(150,110,220))end
        local dl=label(d,'Day',today and '오늘'or string.format('%d일',i),13,today and C.ink or C.muted,0,6,dw,18,Enum.TextXAlignment.Center)
        if NARROW then dl.TextScaled=true;UI.make('UITextSizeConstraint',dl,{MaxTextSize=13,MinTextSize=9})end
        local ic=Icons.create(d,'coin',phone and 16 or 24,got and not today and C.muted or GOLD);UI.box(ic,(dw-(phone and 16 or 24))/2,phone and 26 or 30,phone and 16 or 24,phone and 16 or 24)
        bold(label(d,'Amount',got and not today and '✓'or tostring(reward),phone and 13 or 15,GOLD,0,phone and 44 or 58,dw,20,Enum.TextXAlignment.Center))
        if today and not phone then label(d,'Got','✓ 받음',13,GREEN,0,80,dw,20,Enum.TextXAlignment.Center)end
    end
    if not phone then
        local stale2=stale;local done=p.firstWinToday and not stale2;local r=p.firstWin or Rules.firstWin
        local fc=card(body,'FirstWin',x+aw+16,y,fw,176,Color3.fromRGB(22,28,38));corners(fc)
        local ic=Icons.create(fc,'ranked',36,GOLD);UI.box(ic,20,20,36,36)
        bold(label(fc,'Name','오늘의 첫 승리',20,C.ink,66,16,fw-80,28));label(fc,'Detail','혼자 하기, 공식전, 커스텀 어디서든',13,C.muted,66,44,fw-80,20)
        if done then label(fc,'Done','✓ 오늘은 받았어요',15,GREEN,20,84,fw-40,24)else Currency.create(fc,'xp',r.xp,20,84,110,26);Currency.create(fc,'medal',r.medals,140,84,100,26)end
        fit(label(fc,'Bonus','오늘 첫 판은 XP 2배',13,GREEN,20,120,fw-190,24),13,10)
        local go=UI.button(fc,'FirstWinStart','출전',function()Step.step('goals','firstWinGo',{});hub:closePage()end,true);UI.box(go,fw-170,112,150,48);go.TextSize=17
    end
    y+=(phone and 132 or 176)+16
    local daily=not stale and p.daily or {};local doneN=0;for _,m in ipairs(Rules.daily)do if daily.paid and daily.paid[m.id]then doneN+=1 end end
    divider(body,string.format('오늘의 목표  %d/%d',doneN,#Rules.daily),x,y,w);y+=32
    local cols=phone and 1 or 3;local cw=(w-(cols-1)*12)/cols;local ch=phone and 64 or 96
    local dayKey=tostring(math.floor(os.time()/86400))
    for i,m in ipairs(Rules.daily)do
        local value=math.min(daily[m.id]or 0,m.target);local done=daily.paid and daily.paid[m.id];local key='d:'..dayKey..':'..m.id;local pending=Claims.pending(p,key)
        local c=card(body,'Daily_'..m.id,x+(i-1)%cols*(cw+12),y+math.floor((i-1)/cols)*(ch+10),cw,ch,(done and not pending)and Color3.fromRGB(30,44,24)or nil)
        if done and not pending then edge(c,GREEN:Lerp(C.panel,.4))end
        local icon=({seconds='records',cities='fields',finished='deploy'})[m.id]or 'missions'
        local box=UI.corner(UI.make('Frame',c,{Name='IconBox',BackgroundColor3=C.raised,BorderSizePixel=0}),8);UI.box(box,14,phone and 10 or 14,phone and 40 or 52,phone and 40 or 52)
        local ic=Icons.create(box,icon,phone and 24 or 30,C.ink);UI.box(ic,phone and 8 or 11,phone and 8 or 11,phone and 24 or 30,phone and 24 or 30)
        local tx=phone and 64 or 80
        bold(label(c,'Name',m.name,phone and 15 or 17,C.ink,tx,phone and 6 or 14,cw-tx-120,24))
        if pending then Claims.dot(c,true);local b=Claims.button(c,'ClaimDaily','받기',function()Step.step('goals','claim',{item=m.id});Claims.claim(hub,key)end);UI.box(b,cw-96,8,84,44);UI.enabled(b,not shop.busy)
        elseif done then label(c,'Done','✓ 받음',14,GREEN,cw-96,8,84,24,Enum.TextXAlignment.Right)
        else label(c,'Value',m.id=='seconds'and string.format('%d분 / 6분',math.floor(value/60))or string.format('%d / %d',value,m.target),14,C.ink,cw-120,phone and 8 or 14,108,24,Enum.TextXAlignment.Right)end
        if not phone then Currency.create(c,'medal',m.reward,tx,42,64,22);Currency.create(c,'xp',m.xp,tx+70,42,80,22)end
        bar(c,'Progress',tx,ch-(phone and 16 or 20),cw-tx-16,value/m.target,GREEN:Lerp(C.accent,.4))
    end
    y+=math.ceil(#Rules.daily/cols)*(ch+10)
    local left=((p.dailyReset or 0)-os.time())%86400
    label(body,'Reset',string.format('%d시간 %d분 뒤 새 목표',left//3600,(left%3600)//60),13,C.muted,x,y,w,22);y+=34
    local weekly=os.time()<(p.weeklyReset or math.huge)and p.weekly or {}
    divider(body,'이번 주, 셋 중 하나만 채우면 돼요',x,y,w);y+=32
    local wy=NARROW and 26 or 0;local wh=(phone and 196 or 158)+wy
    local wc=card(body,'Weekly',x,y,w,wh)
    local wt=bold(label(wc,'Title','주간 보상',17,C.ink,18,12,90,28));wt.TextScaled=true;UI.make('UITextSizeConstraint',wt,{MaxTextSize=17,MinTextSize=11});Currency.create(wc,'xp',Rules.weeklyXP,110,14,100,24);Currency.create(wc,'medal',Rules.weeklyMedals,218,14,90,24)
    local wleft=((p.weeklyReset or 0)-os.time())%604800
    label(wc,'Reset',wleft>=86400 and string.format('%d일 뒤 초기화',math.ceil(wleft/86400))or string.format('%d시간 뒤 초기화',math.max(1,math.ceil(wleft/3600))),13,C.muted,NARROW and 18 or w-180,NARROW and 40 or 12,162,NARROW and 22 or 28,NARROW and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right)
    local wk='w:'..Rules.week(os.time())
    local paths=Rules.weeklyPaths;local best,bestR=nil,-1
    for _,m in ipairs(paths)do local r=math.min(weekly[m.id]or 0,m.target)/m.target;if r>bestR then best,bestR=m.id,r end end
    local pw=phone and w-36 or (w-36-2*40)/3
    for i,m in ipairs(paths)do
        local value=math.min(weekly[m.id]or 0,m.target)
        local px=phone and 18 or 18+(i-1)*(pw+40);local py=(phone and 48+(i-1)*48 or 56)+wy
        local c=card(wc,'Week_'..m.id,px,py,pw,phone and 42 or 80,C.bg)
        if m.id==best and bestR>0 and not weekly.paid then edge(c,C.accent)end
        local icon=({seconds='records',cities='fields',supports='friends'})[m.id]or 'missions'
        local ic=Icons.create(c,icon,22,C.ink);UI.box(ic,12,phone and 10 or 12,22,22)
        bold(label(c,'Name',m.name,14,C.ink,42,phone and 0 or 8,pw-150,phone and 42 or 26))
        if not phone and m.id==best and bestR>0 and not weekly.paid then label(c,'Nearest','가장 가까움',13,C.accent,pw-110,8,98,26,Enum.TextXAlignment.Right)end
        if not phone then bar(c,'Progress',14,58,pw-110,value/m.target,GREEN:Lerp(C.accent,.4))end
        label(c,'Value',m.id=='seconds'and string.format('%d분 / %d분',math.floor(value/60),math.floor(m.target/60))or string.format('%d / %d',value,m.target),13,C.ink,pw-96,phone and 0 or 48,86,phone and 42 or 24,Enum.TextXAlignment.Right)
        if i<#paths and not phone then label(wc,'Or'..i,'또는',13,C.muted,px+pw,py+28,40,24,Enum.TextXAlignment.Center)end
    end
    y+=wh+12
    if Claims.pending(p,wk)then
        local b=Claims.button(body,'ClaimWeekly',string.format('주간 보상 받기  +%d 코인',Rules.weeklyMedals),function()Step.step('goals','claim',{item='weekly'});Claims.claim(hub,wk)end)
        UI.box(b,x,y,w,48);Claims.dot(b,true);UI.enabled(b,not shop.busy);y+=60
    elseif weekly.paid then label(body,'WeeklyDone','✓ 이번 주 보상을 받았어요',14,GREEN,x,y,w,24);y+=34 end
    return y
end

local function drawSeason(hub,body,x,w,y,phone,boardColumn)
    local p=hub.account.progress or {};local s=p.career and p.career.season
    if not s then label(body,'NoSeason','지금은 시즌이 없어요.',15,C.muted,x,y,w,40);return y+48 end
    Step.once('seasonView','season','view',{item=Step.code(s.id),value=s.tier,count=s.daysLeft,total=s.tiers})
    local board=seasonBoard(hub)
    local lw=boardColumn and w-boardColumn-16 or w;local y0=y
    local hh=NARROW and 136 or phone and 108 or 170
    local hero=card(body,'SeasonHero',x,y,lw,hh,Color3.fromRGB(22,28,38));corners(hero)
    local finish=os.date('!*t',s.finish-1)
    bold(label(hero,'Title',s.name,phone and 19 or 26,C.ink,phone and 14 or 24,phone and 6 or 14,phone and 120 or 160,phone and 28 or 40))
    label(hero,'Ends',phone and string.format('%d일 남음',s.daysLeft)or string.format('%d월 %d일까지, %d일 남음',finish.month,finish.day,s.daysLeft),13,C.muted,phone and 140 or 184,phone and 6 or 14,phone and 120 or 260,phone and 28 or 40)
    label(hero,'Note','이번 시즌에 얻은 XP가 그대로 점수예요',13,C.muted,lw-300,phone and 6 or 14,phone and 0 or 280,phone and 28 or 40,Enum.TextXAlignment.Right).Visible=not phone
    local bw=(lw-(phone and 28 or 48)-2*12)/3;local by=phone and 38 or 60;local bh=NARROW and 88 or phone and 62 or 94
    local rankText,rankSub='—','순위 불러오는 중'
    if board and not board.unavailable then
        if board.myRank then rankText=string.format('%d위',board.myRank);local top=board.rows[1];rankSub=top and string.format('1위 %s점',commas(top.score))or ''
        elseif board.cutoff then rankText='100위 밖';rankSub=string.format('100위까지 %s점',commas(math.max(0,board.cutoff-s.score+1)))
        else rankText='—';rankSub='첫 결과를 기다려요' end
    elseif board and board.unavailable then rankSub='순위를 불러오지 못했어요' end
    local boxes={{'Score','점수',commas(s.score),'이번 시즌 XP'},{'Record','승패',string.format('%d승 %d패',s.wins,s.losses),string.format('승률 %d%%',percent(s.wins,s.losses))},{'Rank','순위',rankText,rankSub}}
    for i,b in ipairs(boxes)do
        local c=card(hero,'Big_'..b[1],(phone and 14 or 24)+(i-1)*(bw+12),by,bw,bh,C.bg)
        label(c,'Label',b[2],13,C.muted,14,phone and 4 or 10,bw-28,20)
        local v=bold(label(c,'Value',b[3],phone and 18 or 28,i==3 and GOLD or C.ink,14,phone and 22 or 30,bw-28,phone and 26 or 36))
        if NARROW then v.TextWrapped=false;v.TextScaled=true;UI.make('UITextSizeConstraint',v,{MaxTextSize=18,MinTextSize=11});v.Size=UDim2.fromOffset(bw-22,24)end
        if i==2 and not phone then
            v.RichText=true;v.Text=string.format('%d승 <font color="#8A94A3">%d패</font>',s.wins,s.losses)
            bar(c,'WinRate',bw-150,bh-24,136,s.wins/math.max(1,s.wins+s.losses),GREEN)
        end
        label(c,'Sub',b[4],13,C.muted,14,bh-(phone and 0 or 28),bw-(i==2 and not phone and 170 or 28),phone and 0 or 22).Visible=not phone or i~=1
        if NARROW then c.Sub.Visible=true;c.Sub.Position=UDim2.fromOffset(14,52);c.Sub.Size=UDim2.fromOffset(bw-20,32);c.Sub.TextWrapped=true;c.Sub.TextYAlignment=Enum.TextYAlignment.Top
        elseif phone then c.Sub.Position=UDim2.fromOffset(bw-100,4);c.Sub.Size=UDim2.fromOffset(88,20);c.Sub.TextXAlignment=Enum.TextXAlignment.Right end
    end
    y+=hh+(phone and 10 or 16)
    local steps=s.steps or {}
    local sc=card(body,'SeasonSteps',x,y,lw,phone and 96 or 182)
    bold(label(sc,'Title','시즌 보상',phone and 15 or 17,C.ink,phone and 12 or 18,phone and 6 or 12,120,28))
    if not phone then label(sc,'Note','코인만 받아요. 단계마다 한 번씩.',13,C.accent,140,12,300,28)end
    local nextLabel=s.next and string.format('다음 보상까지 %s점',commas(math.max(0,s.next.left)))or '모든 보상을 받았어요'
    label(sc,'Next',nextLabel,13,GOLD,lw-260,phone and 6 or 12,phone and 248 or 242,28,Enum.TextXAlignment.Right)
    local n=#steps;local tw=(lw-(phone and 24 or 36)-(n-1)*(phone and 6 or 10))/n;local th=phone and 52 or 116
    for i,st in ipairs(steps)do
        local isNext=s.next and s.next.tier==i
        local t=card(sc,'Step'..i,(phone and 12 or 18)+(i-1)*(tw+(phone and 6 or 10)),phone and 38 or 52,tw,th,st.got and Color3.fromRGB(30,44,24)or isNext and Color3.fromRGB(40,34,18)or C.bg)
        if st.got then edge(t,GREEN:Lerp(C.panel,.3))elseif isNext then edge(t,GOLD,1.5)end
        local is=phone and 18 or 30;local ic=Icons.create(t,'coin',is,(st.got or isNext)and GOLD or C.muted);UI.box(ic,NARROW and (tw-is)/2 or phone and 6 or (tw-is)/2,NARROW and 6 or phone and (th-is)/2 or 12,is,is)
        if NARROW then
            local a=label(t,'Coins',st.got and '✓'or string.format('%d',st.coins),13,st.got and GREEN or isNext and GOLD or C.muted,0,28,tw,20,Enum.TextXAlignment.Center);a.TextWrapped=false
        elseif phone then
            label(t,'Coins',st.got and '✓'or string.format('%d',st.coins),13,st.got and GREEN or isNext and GOLD or C.muted,26,0,tw-30,th,Enum.TextXAlignment.Center)
        else
            bold(label(t,'Coins',string.format('%d 코인',st.coins),15,(st.got or isNext)and C.ink or C.muted,0,48,tw,22,Enum.TextXAlignment.Center))
            label(t,'Score',st.got and '✓ 받음'or string.format('%s점',commas(st.score)),13,st.got and GREEN or isNext and GOLD or C.muted,0,76,tw,22,Enum.TextXAlignment.Center)
        end
    end
    y+=(phone and 96 or 182)+(phone and 10 or 16)
    if not phone then
        local mc=card(body,'ModeRecords',x,y,lw,190)
        bold(label(mc,'Title','모드별 승패',17,C.ink,18,12,200,28));label(mc,'Note','이번 시즌, 2분 넘게 한 판만 세요',13,C.muted,lw-300,12,282,28,Enum.TextXAlignment.Right)
        local mw=(lw-36-2*12)/3
        for i,m in ipairs(MODES)do
            local r=s.stats and s.stats[m[1]]or {w=0,l=0}
            local c=card(mc,'Mode_'..m[1],18+(i-1)*(mw+12),52,mw,120,C.bg)
            local ic=Icons.create(c,m[3],26,C.accent);UI.box(ic,14,14,26,26);bold(label(c,'Name',m[2],16,C.ink,48,14,mw-60,26))
            local v=fit(bold(label(c,'Value','',24,C.ink,14,52,mw-110,34)),24,14);v.RichText=true;v.Text=string.format('%d승 <font color="#8A94A3">%d패</font>',r.w,r.l)
            label(c,'Rate',string.format('승률 %d%%',percent(r.w,r.l)),13,C.muted,mw-104,58,90,24,Enum.TextXAlignment.Right)
            bar(c,'Bar',14,98,mw-28,r.w/math.max(1,r.w+r.l),GREEN)
        end
        y+=202
    end
    local function boardRows(parent,bx,by,bw2,limit,rowH)
        local rows=board and board.rows or {}
        if not board or board.unavailable or #rows==0 then
            label(parent,'BoardEmpty',not board and '순위 불러오는 중…'or board.unavailable and '순위를 불러오지 못했어요'or '아직 이번 시즌 기록이 없어요',13,C.muted,bx,by,bw2,rowH);return by+rowH+6
        end
        local me=game.Players.LocalPlayer.UserId;local shownMe=false
        for i,r in ipairs(rows)do if i>limit then break end
            local mine=r.userId==me;if mine then shownMe=true end
            local row=card(parent,'Board_'..r.rank,bx,by,bw2,rowH,mine and Color3.fromRGB(18,44,44)or C.bg);if mine then edge(row,C.accent,1.5)end
            label(row,'Rank',tostring(r.rank),15,r.rank<=3 and GOLD or C.ink,12,0,30,rowH)
            local face=UI.make('ImageLabel',row,{Name='Avatar',BackgroundColor3=C.raised,BorderSizePixel=0,Image='rbxthumb://type=AvatarHeadShot&id='..r.userId..'&w=150&h=150'});UI.corner(face,999);UI.box(face,46,(rowH-30)/2,30,30)
            local nm=bold(label(row,'Name',r.name or ('#'..r.userId),14,C.ink,86,0,bw2-170,rowH));nm.TextTruncate=Enum.TextTruncate.AtEnd;nm:SetAttribute('LocalizationSkip',true)
            bold(label(row,'Score',commas(r.score),14,C.ink,bw2-90,0,78,rowH,Enum.TextXAlignment.Right))
            by+=rowH+6
        end
        if not shownMe then
            local dots=label(parent,'More','⋯',14,C.muted,bx,by,bw2,16,Enum.TextXAlignment.Center);dots:SetAttribute('LocalizationSkip',true);by+=20
            local row=card(parent,'BoardMe',bx,by,bw2,rowH,Color3.fromRGB(18,44,44));edge(row,C.accent,1.5)
            label(row,'Rank',board.myRank and tostring(board.myRank)or '—',15,C.ink,12,0,40,rowH)
            local face=UI.make('ImageLabel',row,{Name='Avatar',BackgroundColor3=C.raised,BorderSizePixel=0,Image='rbxthumb://type=AvatarHeadShot&id='..me..'&w=150&h=150'});UI.corner(face,999);UI.box(face,56,(rowH-30)/2,30,30)
            bold(label(row,'Name',string.format('%s (나)',game.Players.LocalPlayer.DisplayName),14,C.ink,96,0,bw2-200,rowH)):SetAttribute('LocalizationSkip',true)
            bold(label(row,'Score',board.myRank and commas(s.score)or (board.cutoff and string.format('100위까지 %s점',commas(math.max(0,board.cutoff-s.score+1)))or commas(s.score)),14,C.ink,bw2-170,0,158,rowH,Enum.TextXAlignment.Right))
            by+=rowH+6
        end
        return by
    end
    if boardColumn then
        local bc=card(body,'SeasonBoard',x+lw+16,y0,boardColumn,10)
        bold(label(bc,'Title',string.format('%s 순위',s.name),17,C.ink,16,10,220,32));label(bc,'Note','점수 순, 100위까지',13,C.muted,boardColumn-176,10,160,32,Enum.TextXAlignment.Right)
        local by2=boardRows(bc,10,50,boardColumn-20,10,38)
        local h=math.max(by2+8,y-y0-12);bc.Size=UDim2.fromOffset(boardColumn,h);y=math.max(y,y0+h+12)
    else
        divider(body,string.format('%s 순위',s.name),x,y,w);y+=32
        y=boardRows(body,x,y,w,phone and 3 or 10,40)
    end
    return y
end

local function drawCareer(hub,body,x,w,y,phone)
    local p=hub.account.progress or {};local c=p.career or {};local CR=Rules.career
    local hh=NARROW and 154 or phone and 120 or 172
    local hero=card(body,'CareerHero',x,y,w,hh,Color3.fromRGB(22,28,38));corners(hero)
    local ms=phone and 56 or 84;local mi=Icons.create(hero,'medal',ms,GOLD);UI.box(mi,phone and 14 or 40,(hh-ms)/2,ms,ms)
    local tx=(phone and 14 or 40)+ms+(phone and 14 or 32)
    local rw=phone and 0 or 480
    bold(label(hero,'Level',string.format('Lv.%d',p.level or 1),phone and 24 or 36,C.ink,tx,phone and 8 or 20,phone and 90 or 130,phone and 32 or 48))
    local title=(p.titleText and p.titleText~=''and p.titleText~=p.title)and string.format('%s  「%s」',p.title or '',p.titleText)or (p.title or '')
    local ry=NARROW and 22 or 0
    local rank=bold(label(hero,'Rank',title,phone and 15 or 18,C.ink,NARROW and tx or tx+(phone and 92 or 140),NARROW and 42 or phone and 8 or 20,NARROW and w-tx-14 or w-tx-rw-(phone and 106 or 160),NARROW and 22 or phone and 32 or 48))
    if NARROW then rank.TextWrapped=false;rank.TextTruncate=Enum.TextTruncate.AtEnd elseif not phone then fit(rank,18,12)end
    if not phone then fit(label(hero,'Lead','경력은 시즌과 상관없이 계속 쌓여요. 레벨마다 칭호나 명판을 받아요.',13,C.muted,tx,70,w-tx-rw-40,22),13,10)end
    local maxed=(p.nextXP or 0)==0
    bar(hero,'XP',tx,(phone and 52 or 104)+ry,w-tx-rw-(phone and 20 or 40),maxed and 1 or (p.currentXP or 0)/math.max(1,p.nextXP or 1),GREEN:Lerp(C.accent,.5),phone and 8 or 10)
    label(hero,'XPText',maxed and string.format('최고 레벨  %s XP',commas(p.xp or 0))or string.format('%s / %s XP  다음까지 %s XP',commas(p.currentXP or 0),commas(p.nextXP or 0),commas(math.max(0,(p.nextXP or 0)-(p.currentXP or 0)))),13,C.ink,tx,(phone and 66 or 122)+ry,w-tx-rw-20,22)
    local nextMotion;for _,m in ipairs(CR.motions)do if m.level>(p.level or 1)then nextMotion=m;break end end
    local boxes={{'NextRank','다음 계급',p.nextRankName or '최고 계급',p.nextRankLevel and string.format('Lv.%d',p.nextRankLevel)or ''},{'NextMotion','다음 모션',nextMotion and nextMotion.name or '모두 받았어요',nextMotion and string.format('Lv.%d',nextMotion.level)or ''}}
    if NARROW then
        for i,b in ipairs(boxes)do local l=label(hero,b[1],string.format('%s %s %s',b[2],b[3],b[4]),13,C.muted,tx,90+ry+(i-1)*18,w-tx-14,18);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd end
    elseif phone then
        label(hero,'Next',string.format('다음 계급 %s  다음 모션 %s',boxes[1][3]..' '..boxes[1][4],boxes[2][3]..' '..boxes[2][4]),13,C.muted,tx,90,w-tx-14,22)
    else
        for i,b in ipairs(boxes)do
            local bc=card(hero,b[1],w-rw+(i-1)*(rw/2)-24+12*(i-1),30,rw/2-12,96,C.bg)
            label(bc,'Label',b[2],13,C.muted,16,10,rw/2-44,20);bold(label(bc,'Value',b[3],22,C.ink,16,32,rw/2-44,32));label(bc,'Level',b[4],13,C.muted,16,64,rw/2-44,20)
        end
    end
    y+=hh+(phone and 10 or 18)
    divider(body,'레벨 보상, 레벨마다 하나씩',x,y,w);y+=32
    local level=p.level or 1;local list={}
    for l=level+1,Rules.maxLevel or 100 do local r=CR.track[l];if r then table.insert(list,{level=l,reward=r,motion=CR.motionAt(l)})end;if #list>=6 then break end end
    local cols=phone and 3 or 6;local cw=(w-(cols-1)*12)/cols;local ch=phone and 92 or 168
    for i,r in ipairs(list)do
        local cc=card(body,'Reward_'..r.level,x+(i-1)%cols*(cw+12),y+math.floor((i-1)/cols)*(ch+10),cw,ch)
        if i==1 then edge(cc,GOLD,1.5)end
        bold(label(cc,'Level',string.format('Lv.%d',r.level),15,i==1 and GOLD or C.ink,14,10,NARROW and cw-28 or cw-82,22))
        label(cc,'Kind',r.reward.kind=='plate'and '명판'or '칭호',13,C.muted,cw-64,10,50,22,Enum.TextXAlignment.Right).Visible=not NARROW
        if r.reward.kind=='plate'then
            local col=r.reward.color and Color3.fromRGB(r.reward.color[1],r.reward.color[2],r.reward.color[3])or C.accent
            local pl=UI.make('TextLabel',cc,{Name='Plate',Text=string.format('%s 명판',r.reward.name),TextSize=13,Font=Enum.Font.BuilderSansBold,TextColor3=C.ink,BackgroundColor3=col:Lerp(C.bg,.45),BorderSizePixel=0})
            UI.corner(pl,4);UI.stroke(pl,col,1);UI.box(pl,12,phone and 40 or 56,cw-24,phone and 30 or 32)
            if phone then pl.TextScaled=true;UI.make('UITextSizeConstraint',pl,{MaxTextSize=13,MinTextSize=9});UI.make('UIPadding',pl,{PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4)})end
        else
            local rt=bold(label(cc,'Title',string.format('「%s」',r.reward.name),phone and 14 or 18,C.ink,8,phone and 36 or 50,cw-16,phone and 34 or 40,Enum.TextXAlignment.Center));rt.TextWrapped=true
            if phone then rt.TextScaled=true;UI.make('UITextSizeConstraint',rt,{MaxTextSize=14,MinTextSize=10})end
        end
        if r.motion and not phone then label(cc,'Motion',string.format('모션 「%s」',r.motion.name),13,C.accent,8,ch-58,cw-16,20,Enum.TextXAlignment.Center)end
        if i==1 then label(cc,'Next','다음 보상',13,GOLD,8,ch-(phone and 22 or 32),cw-16,20,Enum.TextXAlignment.Center)end
    end
    y+=math.ceil(#list/cols)*(ch+10)+6
    divider(body,'덤으로 받는 XP',x,y,w);y+=32
    local comrade;for _,r in ipairs(CR.comradeRewards)do if (c.comradeDays or 0)<r.days then comrade=r;break end end
    local bonus={{'BonusFirst','deploy','오늘 첫 판 XP 2배',c.firstMatchReady and '아직 안 썼어요'or '오늘은 썼어요',c.firstMatchReady and '준비됨'or '사용함',c.firstMatchReady and GREEN or C.muted},
        {'BonusWeek','records','이번 주 2배 XP',string.format('처음 %d XP까지 2배',c.weeklyPool or CR.weeklyPool),string.format('%d 남음',c.weeklyPoolLeft or 0),C.ice},
        {'BonusComrade','friends','친구와 함께한 날',comrade and string.format('%d일이면 %s',comrade.days,CR.rewardLabel(comrade))or '모든 보상을 받았어요',comrade and string.format('%d / %d일',c.comradeDays or 0,comrade.days)or '완료',C.ice}}
    local bcols=phone and 1 or 3;local bw2=(w-(bcols-1)*12)/bcols;local bh2=phone and 60 or 110
    for i,b in ipairs(bonus)do
        local bc=card(body,b[1],x+(i-1)%bcols*(bw2+12),y+math.floor((i-1)/bcols)*(bh2+10),bw2,bh2)
        local box=UI.corner(UI.make('Frame',bc,{Name='IconBox',BackgroundColor3=C.raised,BorderSizePixel=0}),8);local is=phone and 40 or 60;UI.box(box,14,(bh2-is)/2,is,is)
        local ic=Icons.create(box,b[2],is*.55,C.ink);UI.box(ic,is*.225,is*.225,is*.55,is*.55)
        local tx2=14+is+14
        if not phone and bw2<380 then
            fit(bold(label(bc,'Name',b[3],17,C.ink,tx2,16,bw2-tx2-12,24)),17,12)
            fit(label(bc,'Detail',b[4],13,C.muted,tx2,42,bw2-tx2-12,20),13,10)
            bold(label(bc,'State',b[5],15,b[6],tx2,68,bw2-tx2-12,26))
            continue
        end
        local bn=bold(label(bc,'Name',b[3],phone and 15 or 17,C.ink,tx2,phone and 6 or 30,bw2-tx2-110,24))
        if NARROW then bn.TextScaled=true;UI.make('UITextSizeConstraint',bn,{MaxTextSize=15,MinTextSize=11})end
        label(bc,'Detail',b[4],13,C.muted,tx2,phone and 30 or 56,bw2-tx2-110,22)
        bold(label(bc,'State',b[5],15,b[6],bw2-110,0,96,bh2,Enum.TextXAlignment.Right))
    end
    y+=math.ceil(#bonus/bcols)*(bh2+10)
    label(body,'SeasonHint','시즌 점수와 순위는 시즌 탭에서 봐요.',13,C.muted,x,y,w,22);y+=32
    return y
end

function M.draw(hub,body,shop)
    local p=hub.account.progress or {}
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    local W,H=body.Size.X.Offset,body.Size.Y.Offset
    if W<10 then W,H=body.AbsoluteSize.X/(UI.scale or 1),body.AbsoluteSize.Y/(UI.scale or 1)end
    local rawW,rawH=W,H;local pad=body:FindFirstChild('ContentInset')
    if pad then W-=pad.PaddingLeft.Offset+pad.PaddingRight.Offset;H-=pad.PaddingTop.Offset+pad.PaddingBottom.Offset end
    hub.goalsDrawn=Vector2.new(body.Size.X.Offset,body.Size.Y.Offset)
    if not hub.goalsResize then hub.goalsResize=body:GetPropertyChangedSignal('Size'):Connect(function()
        if hub.page~='missions'then return end
        local now=Vector2.new(body.Size.X.Offset,body.Size.Y.Offset)
        if hub.goalsDrawn and (now-hub.goalsDrawn).Magnitude>1 and not hub.goalsRedraw then hub.goalsRedraw=true
            task.defer(function()hub.goalsRedraw=nil;if hub.page=='missions'then hub:drawPage()end end)end
    end)end
    local phone=rawH<460 or rawW<760
    NARROW=phone and W<560 and H>W
    hub.goalTab=hub.goalTab or 'challenges'
    if not ({campaign=1,challenges=1,today=1,season=1,career=1})[hub.goalTab]then hub.goalTab='challenges'end
    local screen=hub.goalTab=='campaign'and 'campaign'or 'goals';if hub.goalScreen~=screen then hub.goalScreen=screen;Step.emit('screen_viewed',{screen=screen,result='shown'})end
    local dots=claimDots(p)
    local s=p.career and p.career.season
    local cv=p.campaign or {}
    local subs={campaign=string.format('별 %d/%d',cv.total or 0,require(script.Parent.Parent.Core.CampaignRules).maxStars),challenges=string.format('업적 %d/%d  기장 ★%d',p.achievementsUnlocked or 0,#(p.achievementList or {}),p.tacticTiers or 0),
        today=(function()local d=os.time()<(p.dailyReset or math.huge)and p.daily or {};local n=0;for _,m in ipairs(Rules.daily)do if d.paid and d.paid[m.id]then n+=1 end end;return string.format('오늘 %d/%d',n,#Rules.daily)end)(),
        season=s and (hub.seasonBoard and hub.seasonBoard.myRank and string.format('%s %d위  %s점',s.name,hub.seasonBoard.myRank,commas(s.score))or string.format('%s  %s점',s.name,commas(s.score)))or '시즌 없음',
        career=string.format('Lv.%d %s',p.level or 1,p.title or '')}
    local function pick(key)if hub.goalTab~=key then hub.goalTab=key;Step.step('goals','tab',{item=key});hub:drawPage()end end
    local x0,top,cw=0,0,W
    if NARROW then
        local tw=(W-(#TABS-1)*8)/#TABS
        for i,t in ipairs(TABS)do
            local on=hub.goalTab==t[1]
            local b=UI.button(body,'GoalTab_'..t[1],'',function()pick(t[1])end,false);UI.box(b,(i-1)*(tw+8),0,tw,56)
            b.BackgroundColor3=on and C.raised:Lerp(C.ink,.12)or C.panel
            local st=b:FindFirstChildOfClass('UIStroke');if st then st.Color=on and C.ink or C.line;st.Transparency=on and .3 or 0 end
            if on then local mark=UI.make('Frame',b,{Name='Mark',BackgroundColor3=C.ink,BorderSizePixel=0});UI.box(mark,12,53,tw-24,3)end
            if t[4]=='crest'then crest(b,(tw-24)/2,6,24)else local ic=Icons.create(b,t[4],24,t[4]=='medal'and GOLD or C.accent);UI.box(ic,(tw-24)/2,6,24,24)end
            local tn=label(b,'Name',t[3],13,on and C.ink or C.muted,2,32,tw-4,18,Enum.TextXAlignment.Center);tn.TextScaled=true;UI.make('UITextSizeConstraint',tn,{MaxTextSize=13,MinTextSize=9})
            Claims.dot(b,dots[t[1]]==true)
        end
        top=66
    elseif phone then
        local rail=card(body,'GoalRail',0,0,72,H-4);rail.ZIndex=2
        for i,t in ipairs(TABS)do
            local on=hub.goalTab==t[1]
            local b=UI.button(rail,'GoalTab_'..t[1],'',function()pick(t[1])end,false);UI.box(b,6,6+(i-1)*((H-16)/#TABS),60,(H-16)/#TABS-6)
            b.BackgroundColor3=on and C.raised:Lerp(C.ink,.12)or C.panel;b.BackgroundTransparency=on and 0 or 1
            local edgeS=b:FindFirstChildOfClass('UIStroke');if edgeS then edgeS.Enabled=false end
            if on then local mark=UI.make('Frame',b,{Name='Mark',BackgroundColor3=C.ink,BorderSizePixel=0});UI.box(mark,0,8,3,(H-16)/#TABS-22)end
            local bh=(H-16)/#TABS-6
            if t[4]=='crest'then crest(b,16,bh/2-24,28)else local ic=Icons.create(b,t[4],28,t[4]=='medal'and GOLD or C.accent);UI.box(ic,16,bh/2-24,28,28)end
            local tn=label(b,'Name',t[3],13,on and C.ink or C.muted,2,bh/2+8,56,18,Enum.TextXAlignment.Center);tn.TextScaled=true;UI.make('UITextSizeConstraint',tn,{MaxTextSize=13,MinTextSize=9})
            Claims.dot(b,dots[t[1]]==true)
        end
        x0,cw=84,W-84
    else
        local tw=(W-(#TABS-1)*16)/#TABS
        for i,t in ipairs(TABS)do
            local on=hub.goalTab==t[1]
            local b=UI.button(body,'GoalTab_'..t[1],'',function()pick(t[1])end,false);UI.box(b,(i-1)*(tw+16),0,tw,64)
            b.BackgroundColor3=on and C.raised:Lerp(C.ink,.1)or C.panel;local st=b:FindFirstChildOfClass('UIStroke');if st then st.Color=on and C.ink or C.line;st.Transparency=on and .3 or 0 end
            if t[4]=='crest'then crest(b,16,14,36)else local ic=Icons.create(b,t[4],32,t[4]=='medal'and GOLD or C.accent);UI.box(ic,18,16,32,32)end
            local tn=bold(label(b,'Name',t[2],18,C.ink,64,10,tw-74,24));tn.TextWrapped=false;tn.TextScaled=true;UI.make('UITextSizeConstraint',tn,{MaxTextSize=18,MinTextSize=13})
            local ts=label(b,'Sub',subs[t[1]],13,on and C.ink or C.muted,64,34,tw-74,20);ts.TextWrapped=false;ts.TextTruncate=Enum.TextTruncate.AtEnd
            Claims.dot(b,dots[t[1]]==true)
        end
        top=80
    end
    local scroll=UI.make('ScrollingFrame',body,{Name='GoalsScroll',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.line,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,0)})
    UI.box(scroll,x0,top,cw,H-top)
    local inner=cw-10;local y=Claims.banner(hub,scroll,inner,0)
    if hub.goalTab=='campaign'then y=require(script.Parent.CampaignScreen).draw(hub,scroll,0,inner,y,phone)
    elseif hub.goalTab=='challenges'then y=drawChallenges(hub,scroll,0,inner,y,phone)
    elseif hub.goalTab=='today'then y=drawToday(hub,scroll,0,inner,y,phone)
    elseif hub.goalTab=='season'then y=drawSeason(hub,scroll,0,inner,y,phone,not phone and math.min(440,inner*.33)or nil)
    else y=drawCareer(hub,scroll,0,inner,y,phone)end
    scroll.CanvasSize=UDim2.fromOffset(0,y+12)
    Step.once('goalsView:'..hub.goalTab,'goals','view',{item=hub.goalTab})
end
return M
