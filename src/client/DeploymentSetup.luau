local TeamFormat=require(script.Parent.Parent.Core.TeamFormat)
local Options=require(script.Parent.Parent.Core.MatchOptions)
local UI=require(script.Parent.ToyUI)
local Theme=require(script.Parent.Theme)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Raster=require(script.Parent.RasterMap)
local Commands=require(script.Parent.Parent.Core.CommandPresentation)
local Onboarding=require(script.Parent.Parent.Core.OnboardingPresentation)
local Flow=require(script.Parent.Parent.Core.PlayFlow)
local Localization=require(script.Parent.Localization)
local TextService=game:GetService('TextService')
local Rows=require(script.Parent.SettingsRows)
local RuleRows=require(script.Parent.MatchRuleRows)
local Daily=require(script.Parent.Parent.Core.DailyOperation)
local M={}
function M.start(lobby)
    local entry=Onboarding.account(lobby.account)
    if entry=='failed'then lobby.callbacks.restore();return end
    if entry~='ready'then return end
    if Commands.soloLoading(lobby)then return end
    local decision=Flow.single(lobby.data and lobby.data.queue)
    if decision=='moving'then return end
    if decision=='replace'then
        lobby:request('cancel',nil,function()M.start(lobby)end);return
    end
    local lesson=Commands.lesson(lobby)
    local daily=not lesson and M.choice(lobby)=='daily'
    lobby:closePage();if lesson then lobby.callbacks.learn()elseif daily then lobby.callbacks.daily()else lobby.callbacks.single(lobby.map)end
end
function M.draw(lobby,parent,w)
    local short=lobby.root.AbsoluteSize.Y/Theme.scale<500
    local compact=short or w<500
    local y=0;local function row(name,text,fn,primary)
        local b=UI.button(parent,name,text,fn,primary);UI.box(b,2,y,w-4,48);y+=56;return b
    end
    if lobby.page=='custom'then
        lobby.pageTitle.Text='커스텀'
        local l=UI.label(parent,'Explain','내 규칙으로 함께',16);UI.box(l,8,y,w-16,34);y+=42
        row('Coop','AI 국가 상대 협동',function()lobby:selectMode('coop');lobby:openPage('friends')end,true)
        row('Friends','친구 초대',function()lobby:openPage('friends')end)
        row('LaunchCoop','함께 시작',function()lobby:request('join','coop')end,true)
        local note=UI.label(parent,'CustomNote','친구 초대, 모두 준비하면 출발',13,UI.colors.muted);note.TextWrapped=true;UI.box(note,8,y,w-16,48);y+=56
        parent.CanvasSize=UDim2.fromOffset(0,y);return
    end
    lobby.pageTitle.Text='혼자 하기'
    local entry=Onboarding.account(lobby.account)
    if entry~='ready'then
        local failed=entry=='failed'
        local loading=UI.label(parent,'Loading',failed and '저장 연결 실패'or '설정 불러오는 중…',16,failed and UI.colors.danger or UI.colors.muted);loading.TextWrapped=true;UI.box(loading,8,4,w-16,42)
        local note=UI.label(parent,'StorageNote','연습, 기록과 보상 없음, 설정 유지',14,UI.colors.muted);note.TextWrapped=true;UI.box(note,8,48,w-16,42)
        y=96;row('PracticeWithoutSave','저장 없이 연습',function()lobby:closePage();lobby.callbacks.practice()end,true)
        parent:SetAttribute('Entry',entry);parent.CanvasSize=UDim2.fromOffset(0,y);return
    end
    if Commands.lesson(lobby)then
        local summary=UI.panel(parent,'SoloSummary');UI.box(summary,2,0,w-4,compact and 88 or 112)
        local image=UI.make('Frame',summary,{Name='Map',BackgroundColor3=UI.colors.ocean,ClipsDescendants=true,BorderSizePixel=0});UI.box(image,8,8,compact and 110 or 152,compact and 72 or 96)
        local raster=Raster.new(image,128,80);raster:setPreview(Maps.preview('korea'));task.defer(function()if image.Parent then raster:fit();raster:draw()end end)
        image.Destroying:Once(function()if raster.image then raster.image:Destroy()end end)
        local x=compact and 128 or 172
        local name=UI.label(summary,'Title',(Maps.meta('korea')).label,compact and 20 or 24);Theme.display(name);UI.box(name,x,8,w-x-20,32)
        local rules=UI.label(summary,'Rules','쉬움  AI 2  중립 30',13,UI.colors.muted);rules.TextWrapped=true;UI.box(rules,x,44,w-x-20,36)
        y=(compact and 88 or 112)+12
        row('CustomizeSolo','내 설정으로 플레이',function()lobby.soloCustomized=true;lobby:refresh();lobby:drawPage()end)
        if not short then local note=UI.label(parent,'IntroNote','점령과 병력 첫 실전',13,UI.colors.muted);UI.box(note,8,y,w-16,20);y+=28 end
        parent.CanvasSize=UDim2.fromOffset(0,y);parent:SetAttribute('Entry','lesson');return
    end
    parent:SetAttribute('Entry','configured')
    local progress=lobby.account.progress or {}
    if not progress.basicsComplete then row('FirstLesson','점령과 병력 첫 작전 안내',function()lobby:closePage();lobby.callbacks.learn()end)end
    local choice,op=M.choice(lobby)
    if op then
        if not short then local title=UI.label(parent,'ChooseTitle','어떻게 플레이할까요?',16);UI.box(title,8,y,w-16,28);y+=34 end
        local tw=(w-12)/2;local th=compact and 64 or 88
        local function tile(name,key,head,sub,explain,badge,color)
            local on=choice==key
            local b=UI.button(parent,name,'',function()lobby.soloChoice=key;lobby:refresh();lobby:drawPage()end);b:SetAttribute('Selected',on)
            b.BackgroundColor3=on and UI.colors.panel or UI.colors.raised
            local stroke=b:FindFirstChildOfClass('UIStroke');if stroke then stroke.Color=on and color or UI.colors.line;stroke.Thickness=on and 2 or 1 end
            local h=UI.label(b,'Head',head,compact and 16 or 18,on and color or UI.colors.ink);Theme.display(h);UI.box(h,12,8,tw-24,26)
            local t=UI.label(b,'Sub',sub,13);t.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(t,12,36,tw-24,20)
            if not compact then local e=UI.label(b,'Explain',explain,12,UI.colors.muted);e.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(e,12,60,tw-24,20)end
            if badge then local pill=UI.pill(b,'Badge',badge,color);pill.TextSize=11;UI.box(pill,tw-64,10,54,20);UI.box(h,12,8,tw-84,26)
                h.TextWrapped=false;h.TextScaled=true;UI.make('UITextSizeConstraint',h,{MaxTextSize=compact and 16 or 18,MinTextSize=12})end
            return b
        end
        local meta=Maps.meta(op.map)
        local daily=tile('ChooseDaily','daily','오늘의 작전',(meta and meta.label or op.map)..'  '..op.conditionName,'모두 같은 조건, 오늘의 순위',op.done and '완료'or '추천',UI.colors.gold);UI.box(daily,2,y,tw,th)
        local mine=tile('ChooseCustom','custom','내가 정해서 하기',(Maps.meta(lobby.map)or Maps.catalog[1]).label..'  '..Options.difficultyLabels[lobby.settings.difficulty or 'Medium'],'지도, 상대, 규칙을 직접 정해요',nil,UI.colors.accent);UI.box(mine,10+tw,y,tw,th)
        y+=th+14
    end
    if choice=='daily'then y=M.dailyCard(lobby,parent,w,y,op,compact)
    else y=M.customRules(lobby,parent,w,y,compact,row)end
    parent.CanvasSize=UDim2.fromOffset(0,y)
end
function M.choice(lobby)
    local progress=lobby.account and lobby.account.progress or {}
    local op=(progress.basicsComplete or progress.tutorial==false or next(progress.history or {})~=nil)and Daily.current(progress.dailyOp,os.time())or nil
    if not op then return 'custom',nil end
    return lobby.soloChoice or (op.done and 'custom'or 'daily'),op
end
function M.startLabel(lobby)
    local choice,op=M.choice(lobby)
    if choice=='daily'then return op.done and '오늘의 작전 다시 도전'or '오늘의 작전 출전'end
    return '내 설정으로 시작'
end
function M.dailyCard(lobby,parent,w,y,op,compact)
    local meta=Maps.meta(op.map)
    if lobby.dailyBoardDay~=op.day then
        lobby.dailyBoardDay=op.day;lobby.dailyBoard=nil;lobby.dailyBoardOpen=false;lobby.dailyBoardLoading=false;lobby.dailyBoardAt=nil;lobby.dailyBoardRequestedAt=nil
        lobby.dailyBoardRequest=(lobby.dailyBoardRequest or 0)+1
    end
    local card=UI.panel(parent,'DailyOp');local stroke=card:FindFirstChildOfClass('UIStroke');if stroke then stroke.Color=UI.colors.gold end
    local pw=compact and 110 or 152;local ph=compact and 70 or 96
    local picture=UI.make('Frame',card,{Name='Map',BackgroundColor3=UI.colors.ocean,ClipsDescendants=true,BorderSizePixel=0});UI.box(picture,10,10,pw,ph)
    local raster=Raster.new(picture,128,80);raster:setPreview(Maps.preview(op.map));task.defer(function()if picture.Parent then raster:fit();raster:draw()end end)
    picture.Destroying:Once(function()if raster.image then raster.image:Destroy()end end)
    local tx=pw+24;local tw=w-tx-20
    local name=UI.label(card,'Title',meta and meta.label or op.map,compact and 20 or 24,UI.colors.gold);Theme.display(name);UI.box(name,tx,10,tw,32)
    local cond=UI.label(card,'Condition',op.conditionName,15);UI.box(cond,tx,44,tw,22)
    local s=Daily.of(op.day).settings;local parts={Localization.text(Options.difficultyLabels[s.difficulty]or s.difficulty)}
    if type(s.nations)=='number'then table.insert(parts,string.format(Localization.text('AI 국가 %d'),s.nations))end
    table.insert(parts,string.format(Localization.text('중립 %d'),s.bots or 0))
    if (s.startingGold or 0)>0 then table.insert(parts,string.format(Localization.text('시작 골드 %s'),s.startingGold>=1000000 and string.format('%dM',s.startingGold//1000000)or tostring(s.startingGold)))end
    table.insert(parts,Localization.text('랜덤 스폰'));table.insert(parts,string.format(Localization.text('%d분'),s.maxTimerValue or 20))
    local rules=UI.label(card,'Rules',table.concat(parts,', '),12,UI.colors.muted);rules:SetAttribute('LocalizationSkip',true);rules.AutoLocalize=false;rules.TextWrapped=true;rules.TextYAlignment=Enum.TextYAlignment.Top
    UI.box(rules,tx,68,tw,math.max(ph,96)-56)
    local cy=math.max(ph,96)+18;local contentWidth=w-24
    local function line(name,text,color,size)
        local label=UI.label(card,name,text,size or 14,color)
        local h=math.max(20,math.ceil(TextService:GetTextSize(Localization.text(text),label.TextSize,label.Font,Vector2.new(contentWidth,1000)).Y)+4)
        label.TextYAlignment=Enum.TextYAlignment.Top;label.TextWrapped=true;UI.box(label,10,cy,contentWidth,h);cy+=h+4;return label
    end
    line('Goal',string.format('목표: %d분 안에 땅 80%% 차지. 빨리 이길수록 높은 순위',s.maxTimerValue or 20),UI.colors.ink,14)
    line('Fair','모두 같은 지도와 조건, 하루 한 번 보상',UI.colors.muted,13)
    local left=math.max(0,(op.day+1)*86400-os.time())
    local status=op.done and string.format('오늘 완료  내 기록 %s  작전 %d일째',op.bestLabel,op.days)or string.format('첫 완료 +%d 코인  +%d XP  작전 %d일째',op.medals,op.xp,op.days)
    line('Status',status,op.done and UI.colors.accent or UI.colors.gold,14)
    line('Reset',string.format('새 작전까지 %d시간 %02d분',left//3600,left%3600//60),UI.colors.muted,12);cy+=4
    local list=UI.button(card,'DailyBoard',lobby.dailyBoardOpen and '순위 닫기'or '오늘의 순위',function()
        lobby.dailyBoardOpen=not lobby.dailyBoardOpen
        local now=os.clock()
        if lobby.dailyBoardOpen and not lobby.dailyBoardLoading and now-(lobby.dailyBoardRequestedAt or -3)>=3
            and (not lobby.dailyBoard or lobby.dailyBoard.unavailable or now-(lobby.dailyBoardAt or -60)>=60)then
            local day=op.day;local request=(lobby.dailyBoardRequest or 0)+1;lobby.dailyBoardRequest=request
            lobby.dailyBoardLoading=true;lobby.dailyBoardRequestedAt=now
            task.delay(10,function()
                if lobby.dailyBoardRequest~=request or not lobby.dailyBoardLoading then return end
                lobby.dailyBoardRequest+=1;lobby.dailyBoardLoading=false
                lobby.dailyBoard=lobby.dailyBoard or {day=day,rows={},unavailable=true}
                if lobby.page=='solo'then lobby:drawPage()end
            end)
            task.spawn(function()
            local ok,r=pcall(function()return game.ReplicatedStorage.FrontierNative.AccountRequest:InvokeServer('dailyBoard')end)
            if lobby.dailyBoardRequest~=request or lobby.dailyBoardDay~=day then return end
            lobby.dailyBoardLoading=false
            if ok and type(r)=='table'and r.ok and r.day==day then lobby.dailyBoard=r;lobby.dailyBoardAt=os.clock()
            else lobby.dailyBoard=lobby.dailyBoard or {day=day,rows={},unavailable=true}end
            if lobby.page=='solo'then lobby:drawPage()end
            end)
        end
        lobby:drawPage()
    end);UI.box(list,10,cy,w-24,44);cy+=56
    if lobby.dailyBoardOpen then
        local b=lobby.dailyBoard
        if not b then line('BoardLoading','순위를 불러오는 중…',UI.colors.muted)
        elseif #b.rows==0 then line('BoardEmpty',b.unavailable and '순위 불러오기 실패'or '기록 없음, 첫 번째로 도전해 보세요',UI.colors.muted)
        else for i,r in ipairs(b.rows)do if i>10 and r.userId~=game.Players.LocalPlayer.UserId then continue end
            local color=r.userId==game.Players.LocalPlayer.UserId and UI.colors.accent or UI.colors.ink
            local t=UI.label(card,'Rank_'..i,string.format('%d. %s',r.rank,r.name),14,color);t:SetAttribute('LocalizationSkip',true);t.AutoLocalize=false;t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd
            local score=UI.label(card,'Score_'..i,r.label,14,color);score:SetAttribute('LocalizationSkip',true);score.AutoLocalize=false;score.TextWrapped=false;score.TextXAlignment=Enum.TextXAlignment.Right
            local sw=math.max(72,TextService:GetTextSize(score.Text,14,score.Font,Vector2.new(contentWidth,24)).X+4)
            UI.box(t,10,cy,contentWidth-sw-8,24);UI.box(score,10+contentWidth-sw,cy,sw,24);cy+=28
        end
            cy+=4;line('MyRank',b.myRank and string.format('내 순위 %d위',b.myRank)or op.done and '내 기록 20위 밖'or '오늘 아직 기록 없음',UI.colors.muted)
        end
    end
    local h=cy+4;UI.box(card,2,y,w-4,h)
    return y+h+12
end
function M.set(lobby,key,value)
    lobby.soloCustomized=true;lobby.callbacks.setting(key,value)
    local s=lobby.settings
    if key=='overtimeEnabled'then s.overtime={enabled=value,startMinutes=s.overtime and s.overtime.startMinutes or 30}
    elseif key=='overtimeStartMinutes'then s.overtime={enabled=s.overtime and s.overtime.enabled or false,startMinutes=math.max(1,value)}
    elseif key=='spawnImmunityMinutes'then s.spawnImmunityDuration=value>0 and value*600 or nil
    elseif key=='maxTimerValue'then s.maxTimerValue=value>0 and value or nil
    elseif key=='mapSize'then s.mapSize=value=='normal'and 'normal'or nil
    elseif key=='disabledUnits'then s.disabledUnits=#value>0 and value or nil
    elseif key=='teamFormat'then s.teamFormat=value~='ffa'and value or nil
    else s[key]=value end
    lobby:refresh();lobby:drawPage()
end
M.formats={'ffa',2,3,4,5,6,7,'Duos','Trios','Quads','HumansVsNations'}
function M.customRules(lobby,parent,w,y,compact,row)
    local top=UI.panel(parent,'SoloSummary');UI.box(top,2,y,w-4,compact and 88 or 112)
    local picture=UI.make('Frame',top,{Name='Map',BackgroundColor3=UI.colors.ocean,ClipsDescendants=true,BorderSizePixel=0});UI.box(picture,8,8,compact and 110 or 152,compact and 60 or 96)
    local raster=Raster.new(picture,128,80);raster:setPreview(Maps.preview(lobby.map));task.defer(function()if picture.Parent then raster:fit();raster:draw()end end)
    picture.Destroying:Once(function()if raster.image then raster.image:Destroy()end end)
    local tx=compact and 128 or 172
    local title=UI.label(top,'Title',(Maps.meta(lobby.map)or Maps.catalog[1]).label,compact and 20 or 24);Theme.display(title);UI.box(title,tx,8,w-tx-24,32)
    local change=UI.button(top,'ChangeMap','지도 바꾸기',function()lobby.returnPage='solo';lobby:openPage('maps')end);UI.box(change,tx,40,w-tx-24,44)
    y+=(compact and 88 or 112)+12
    local s=lobby.settings
    if require(script.Parent.Parent.Core.SoloChallenge).empty(Maps.meta(lobby.map),s)then
        local note=UI.label(parent,'NoOpponents','상대 없음, 자유 연습',14,UI.colors.gold);UI.box(note,4,y,w-8,28);y+=36
        local b=UI.button(parent,'ChallengeInstead','AI 대전으로 시작',function()lobby:closePage();lobby.callbacks.goal(lobby.map)end);UI.box(b,2,y,w-4,48);y+=56
    end
    local hint=UI.label(parent,'SoloGoal','목표: 땅 80% 차지. 시작 위치 고르기 → 빈 땅 넓히기 → 도시와 항구로 키우기',13,UI.colors.muted);hint.TextWrapped=true;UI.box(hint,8,y,w-16,36);y+=44
    local current=s.teamFormat or 'ffa';local index=table.find(M.formats,current)or 1
    y=Rows.heading(parent,'형식',y,w)
    y=Rows.stepper(parent,'TeamMode','팀 구성',current=='ffa'and '개인전'or TeamFormat.short(current),y,w,function(d)M.set(lobby,'teamFormat',M.formats[(index-1+d)%#M.formats+1])end)
    y=RuleRows.draw(parent,w,y,{s=s,map=lobby.map,spawn=true,randomSpawn=s.randomSpawn,set=function(key,value)M.set(lobby,key,value)end},{'opponents','economy','combat','time','map','units'})
    return y
end
return M
