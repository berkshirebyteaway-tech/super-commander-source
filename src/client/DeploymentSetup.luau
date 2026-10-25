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
local Icons=require(script.Parent.OutgameIcons)
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
    if lobby.page~='custom'and require(script.Parent.Lobby20).ENABLED then M.draw20(lobby,parent);return end
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
        local tw=(w-12)/2
        local function tab(name,key,text)
            local on=choice==key
            local b=UI.button(parent,name,text,function()lobby.soloChoice=key;lobby:refresh();lobby:drawPage()end);b:SetAttribute('Selected',on)
            b.BackgroundColor3=on and UI.colors.accent or UI.colors.raised;b.TextColor3=on and UI.colors.bg or UI.colors.ink;b.TextSize=15
            local stroke=b:FindFirstChildOfClass('UIStroke');if stroke then stroke.Color=on and UI.colors.accent or UI.colors.line end
            return b
        end
        UI.box(tab('ChooseDaily','daily',op.done and '오늘의 도전 ✓'or '오늘의 도전'),2,y,tw,44)
        UI.box(tab('ChooseCustom','custom','내가 정해서'),10+tw,y,tw,44)
        y+=56
    end
    if choice=='daily'then y=M.dailyCard(lobby,parent,w,y,op,compact)
    else y=M.customRules(lobby,parent,w,y,compact,row)end
    parent.CanvasSize=UDim2.fromOffset(0,y)
end
function M.choice(lobby)
    local progress=lobby.account and lobby.account.progress or {}
    local op=(progress.basicsComplete or progress.tutorial==false or next(progress.history or {})~=nil)and Daily.current(progress.dailyOp,os.time())or nil
    if not op then return 'custom',nil end
    if require(script.Parent.Lobby20).ENABLED then return 'custom',op end
    return lobby.soloChoice or (op.done and 'custom'or 'daily'),op
end
function M.startLabel(lobby)
    local choice,op=M.choice(lobby)
    if choice=='daily'then return op.done and '다시 도전'or '오늘의 도전 시작'end
    return '내 설정으로 시작'
end
function M.dailyCard(lobby,parent,w,y,op,compact)
    local meta=Maps.meta(op.map)
    if lobby.dailyBoardDay~=op.day then
        lobby.dailyBoardDay=op.day;lobby.dailyBoard=nil;lobby.dailyBoardOpen=false;lobby.dailyBoardLoading=false;lobby.dailyBoardAt=nil;lobby.dailyBoardRequestedAt=nil
        lobby.dailyBoardRequest=(lobby.dailyBoardRequest or 0)+1
    end
    local card=UI.panel(parent,'DailyOp')
    local pw=compact and 110 or 152;local ph=compact and 70 or 96
    local picture=UI.make('Frame',card,{Name='Map',BackgroundColor3=UI.colors.ocean,ClipsDescendants=true,BorderSizePixel=0});UI.box(picture,10,10,pw,ph)
    local raster=Raster.new(picture,128,80);raster:setPreview(Maps.preview(op.map));task.defer(function()if picture.Parent then raster:fit();raster:draw()end end)
    picture.Destroying:Once(function()if raster.image then raster.image:Destroy()end end)
    local tx=pw+24;local tw=w-tx-20
    local left=math.max(0,(op.day+1)*86400-os.time())
    local clock=UI.label(card,'Reset',string.format('%d:%02d',left//3600,left%3600//60),12,UI.colors.muted);clock.TextXAlignment=Enum.TextXAlignment.Right;clock:SetAttribute('LocalizationSkip',true);clock.AutoLocalize=false
    local name=UI.label(card,'Title',meta and meta.label or op.map,compact and 20 or 24,UI.colors.gold);Theme.display(name);name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(name,tx,8,tw,30)
    local s=Daily.of(op.day).settings
    local chips={{op.conditionName,UI.colors.gold},{Options.difficultyLabels[s.difficulty]or s.difficulty}}
    if type(s.nations)=='number'then table.insert(chips,{string.format(Localization.text('AI %d'),s.nations)})end
    if (s.startingGold or 0)>0 then table.insert(chips,{string.format(Localization.text('골드 %s'),s.startingGold>=1000000 and string.format('%dM',s.startingGold//1000000)or tostring(s.startingGold))})end
    table.insert(chips,{string.format(Localization.text('%d분'),s.maxTimerValue or 20)});table.insert(chips,{'랜덤 스폰'})
    local cx,cy=tx,42
    for i,c in ipairs(chips)do
        local text=Localization.text(c[1]);local cw=math.ceil(TextService:GetTextSize(text,12,Enum.Font.BuilderSansBold,Vector2.new(400,20)).X)+14
        if cx>tx and cx+cw>tx+tw then cx=tx;cy+=26 end
        local chip=UI.label(card,'Chip'..i,text,12,c[2]or UI.colors.ink);chip.Font=Enum.Font.BuilderSansBold;chip.TextXAlignment=Enum.TextXAlignment.Center;chip.TextWrapped=false
        chip:SetAttribute('LocalizationSkip',true);chip.AutoLocalize=false;chip.BackgroundTransparency=0;chip.BackgroundColor3=UI.colors.raised;UI.corner(chip,4)
        UI.box(chip,cx,cy,cw,22);cx+=cw+6
    end
    local side=compact and cy==42 and w>=560;local gx=side and tx or 12
    local by=side and cy+30 or math.max(10+ph,cy+22)+10
    local goal=UI.label(card,'Goal',string.format('목표  %d분 안에 땅 80%%',s.maxTimerValue or 20),14);UI.box(goal,gx,by,w-gx-88,20);UI.box(clock,w-76,by+1,56,18);by+=26
    local rx=gx
    local function item(name,text,color,icon,fallback)
        if icon then local ic=Icons.create(card,icon,16,color);UI.box(ic,rx,by+2,16,16);if Icons.available(ic)then rx+=20 else ic.Visible=false;text=text..' '..fallback end end
        local l=UI.label(card,name,text,14,color);l.Font=Enum.Font.BuilderSansBold;l.TextWrapped=false;l:SetAttribute('LocalizationSkip',true);l.AutoLocalize=false
        local tw2=math.ceil(TextService:GetTextSize(l.Text,14,l.Font,Vector2.new(400,20)).X)+2;UI.box(l,rx,by,tw2,20);rx+=tw2+12;return l
    end
    if op.done then item('Done','✓ '..Localization.text('완료'),UI.colors.accent);item('Best',op.bestLabel,UI.colors.ink)
    else item('Coin',tostring(op.medals),UI.colors.gold,'coin',Localization.text('코인'));item('XP',tostring(op.xp),UI.colors.ice,'xp','XP')end
    by+=28
    local list=UI.button(card,'DailyBoard',lobby.dailyBoardOpen and '순위 닫기'or '오늘의 순위 ›',function()
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
    end);list.BackgroundTransparency=1;list.TextColor3=UI.colors.accent;list.TextXAlignment=Enum.TextXAlignment.Right;list.TextSize=14
    local ls=list:FindFirstChildOfClass('UIStroke');if ls then ls.Enabled=false end
    if rx+12<=w-180 then UI.box(list,w-180,by-38,160,40)else UI.box(list,w-180,by-6,160,40);by+=36 end
    if side then by=math.max(by,10+ph+8)end
    local contentWidth=w-24
    local function line(name,text,color,size)
        local label=UI.label(card,name,text,size or 14,color)
        local h=math.max(20,math.ceil(TextService:GetTextSize(Localization.text(text),label.TextSize,label.Font,Vector2.new(contentWidth,1000)).Y)+4)
        label.TextYAlignment=Enum.TextYAlignment.Top;label.TextWrapped=true;UI.box(label,10,by,contentWidth,h);by+=h+4;return label
    end
    if lobby.dailyBoardOpen then
        local b=lobby.dailyBoard
        if not b then line('BoardLoading','순위를 불러오는 중…',UI.colors.muted)
        elseif #b.rows==0 then line('BoardEmpty',b.unavailable and '순위 불러오기 실패'or '기록 없음',UI.colors.muted)
        else for i,r in ipairs(b.rows)do if i>10 and r.userId~=game.Players.LocalPlayer.UserId then continue end
            local color=r.userId==game.Players.LocalPlayer.UserId and UI.colors.accent or UI.colors.ink
            local t=UI.label(card,'Rank_'..i,string.format('%d. %s',r.rank,r.name),14,color);t:SetAttribute('LocalizationSkip',true);t.AutoLocalize=false;t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd
            local score=UI.label(card,'Score_'..i,r.label,14,color);score:SetAttribute('LocalizationSkip',true);score.AutoLocalize=false;score.TextWrapped=false;score.TextXAlignment=Enum.TextXAlignment.Right
            local sw=math.max(72,TextService:GetTextSize(score.Text,14,score.Font,Vector2.new(contentWidth,24)).X+4)
            UI.box(t,10,by,contentWidth-sw-8,24);UI.box(score,10+contentWidth-sw,by,sw,24);by+=28
        end
            by+=4;line('MyRank',b.myRank and string.format('내 순위 %d위',b.myRank)or op.done and '내 기록 20위 밖'or '오늘 아직 기록 없음',UI.colors.muted)
        end
    end
    local h=by+6;UI.box(card,2,y,w-4,h)
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
    local current=s.teamFormat or 'ffa';local index=table.find(M.formats,current)or 1
    y=Rows.heading(parent,'형식',y,w)
    y=Rows.stepper(parent,'TeamMode','팀 구성',current=='ffa'and '개인전'or TeamFormat.short(current),y,w,function(d)M.set(lobby,'teamFormat',M.formats[(index-1+d)%#M.formats+1])end)
    y=RuleRows.draw(parent,w,y,M.ruleContext(lobby),M.sections)
    return y
end
M.sections={'opponents','economy','combat','time','map','units'}
function M.ruleContext(lobby)
    local s=lobby.settings
    return {s=s,map=lobby.map,spawn=true,recommend=require(script.Parent.Parent.Core.QuickSolo).rookie(lobby.account and lobby.account.progress)and 'Easy'or nil,randomSpawn=s.randomSpawn,set=function(key,value)M.set(lobby,key,value)end}
end

function M.draw20(lobby,body)
    local K=require(script.Parent.Kit20);local S=require(script.Parent.Sheet20);local W20=require(script.Parent.Setup20)
    local C=K.colors
    local entry=Onboarding.account(lobby.account)
    local lesson=entry=='ready'and Commands.lesson(lobby)
    local win=W20.open(lobby,body,'solo')
    local fmt=win.fmt;local pt,ph=fmt=='pt',fmt=='ph'
    W20.head(win,(entry~='ready'or lesson)and '혼자 하기'or '나만의 설정',nil,function()lobby:back()end)
    local listBottom=W20.footer(win,function()M.start(lobby)end,function()lobby:closePage()end)
    local scroll=W20.scroll(win,'Solo',listBottom)
    local w=win.w;local y=0
    local ctl=pt and 44 or ph and 40 or 44;local gap=pt and 10 or ph and 6 or 8
    local function button(name,text,kind,fn)
        local b=K.button(scroll,name,{kind=kind,text=text,size=pt and 15 or ph and 14 or 15,weight=800},fn)
        b:place(0,y,w,ctl);y+=ctl+gap;return b
    end
    local function line(name,text,size,color,weight)
        local l=K.text(scroll,name,text,size,color,weight);l.TextWrapped=true;l.TextTruncate=Enum.TextTruncate.None
        local lines=math.max(1,math.ceil(K.width(Localization.text(text),size,l)/math.max(1,w)))
        local h=lines*(size+6);K.box(l,0,y,w,h);y+=h+6;return l
    end
    local function mapCard(key,sub,change)
        local mh=pt and 96 or ph and 76 or 112
        local meta=Maps.meta(key)or Maps.catalog[1]
        local map=K.map(scroll,'SoloSummary',meta.key or key,w,mh,8);K.box(map,0,y,w,mh);K.stroke(map,C.line,1,0,true)
        local fadeH=pt and 56 or ph and 50 or 72
        local fade=K.fadeBox(map,'Fade',Color3.fromRGB(8,10,14),0,.92,8);fade.Size=UDim2.new(1,0,0,fadeH);fade.Position=UDim2.new(0,0,1,-fadeH);fade.ZIndex=3
        local bx=pt and 12 or ph and 10 or 16;local bb=pt and 8 or ph and 8 or 12
        local chH=pt and 32 or ph and 30 or 36;local fs=pt and 13 or ph and 12 or 14;local is=pt and 14 or ph and 13 or 15
        local cw=0
        if change then
            cw=12+is+6+K.width('바꾸기',fs)+2+12
            local b=K.button(map,'ChangeMap',{kind='plain',icon='map',iconSize=is,text='바꾸기',size=fs,weight=800,gap=6},change)
            b:place(w-bx-cw,mh-bb-chH,cw,chH);b.button.ZIndex=5
        end
        local ns=pt and 16 or ph and 16 or 20
        local nameW=w-bx*2-(cw>0 and cw+8 or 0)
        if sub then
            local name=K.text(map,'Title',meta.label,ns,C.ink,800);name.ZIndex=4;K.box(name,bx,mh-bb-(ns+4)-16,nameW,ns+4)
            local r=K.text(map,'Rules',sub,12,C.ink,700);r.ZIndex=4;r.TextTransparency=.15;K.box(r,bx,mh-bb-16,nameW,16)
        else
            local name=K.text(map,'Title',meta.label,ns,C.ink,800);name.ZIndex=4;K.box(name,bx,mh-bb-chH,nameW,chH)
        end
        y+=mh+(pt and 12 or ph and 8 or 12)
        return map
    end
    if entry~='ready'then
        local failed=entry=='failed'
        line('Loading',failed and '저장 연결 실패'or '설정 불러오는 중…',16,failed and C.danger or C.muted,800)
        line('StorageNote','연습, 기록과 보상 없음, 설정 유지',14,C.muted,700)
        y+=4;button('PracticeWithoutSave','저장 없이 연습','out',function()lobby:closePage();lobby.callbacks.practice()end)
        body:SetAttribute('Entry',entry)
    elseif lesson then
        mapCard('korea','쉬움  AI 2  중립 30',nil)
        button('CustomizeSolo','내 설정으로 플레이','plain',function()lobby.soloCustomized=true;lobby:refresh();lobby:drawPage()end)
        if not ph then line('IntroNote','점령과 병력 첫 실전',13,C.muted,700)end
        body:SetAttribute('Entry','lesson')
    else
        body:SetAttribute('Entry','configured')
        local progress=lobby.account.progress or {}
        if not progress.basicsComplete then button('FirstLesson','점령과 병력 첫 작전 안내','plain',function()lobby:closePage();lobby.callbacks.learn()end)end
        mapCard(lobby.map,nil,function()lobby.returnPage='solo';lobby:openPage('maps')end)
        local s=lobby.settings
        if require(script.Parent.Parent.Core.SoloChallenge).empty(Maps.meta(lobby.map),s)then
            line('NoOpponents','상대 없음, 자유 연습',14,C.gold,800)
            button('ChallengeInstead','AI 대전으로 시작','out',function()lobby:closePage();lobby.callbacks.goal(lobby.map)end)
        end
        local current=s.teamFormat or 'ffa';local index=table.find(M.formats,current)or 1
        y=W20.heading(scroll,fmt,'형식','people',y,w)
        y=W20.stepper(scroll,fmt,'TeamMode','팀 구성',current=='ffa'and '개인전'or TeamFormat.short(current),y,w,function(d)M.set(lobby,'teamFormat',M.formats[(index-1+d)%#M.formats+1])end)
        local ctx=M.ruleContext(lobby);ctx.v2=true;ctx.fmt=fmt
        y=RuleRows.draw(scroll,w,y,ctx,M.sections)
    end
    S.canvas(scroll,y);W20.restore(win,scroll)
    body.CanvasSize=UDim2.fromOffset(0,0)
end
return M
