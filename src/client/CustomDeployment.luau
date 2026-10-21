local UI=require(script.Parent.ToyUI)
local Theme=require(script.Parent.Theme)
local pack=game.ReplicatedStorage.FrontierNative
local Rules=require(pack.Core.CustomBattlefieldRules)
local SettingsCode=require(pack.Core.SettingsCode)
local Challenges=require(pack.Core.CustomChallenges)
local Copy=require(pack.Core.BattlefieldRules)
local Options=require(pack.Core.MatchOptions)
local Maps=require(pack.Maps.MapLoader)
local Raster=require(script.Parent.RasterMap)
local Flow=require(pack.Core.PlayFlow)
local L=require(script.Parent.Localization)
local Players=game:GetService('Players')
local Honor=require(script.Parent.CommanderHonor)
local M={}
local modes={ffa='개인전',teams='팀전',coop='협동'}
local difficulties=Options.difficultyLabels
local function label(p,name,text,x,y,w,h,size,color)local l=UI.label(p,name,text,size or 14,color);UI.box(l,x,y,w,h);return l end
local function mapCard(lobby,p,w,map,y,editable)
    local short=lobby.root.AbsoluteSize.Y/Theme.scale<500;local compact=lobby.page=='room'and (short or lobby.pageBody.Size.Y.Offset<360);local h=compact and 44 or short and 88 or 112
    local slim=short or w<380
    local f=UI.panel(p,'MapSummary');UI.box(f,2,y,w-4,h)
    local picture=UI.make('Frame',f,{Name='Map',BackgroundColor3=UI.colors.ocean,BorderSizePixel=0,ClipsDescendants=true});UI.box(picture,8,8,compact and 60 or slim and 110 or 152,h-16)
    local raster=Raster.new(picture,128,80);raster:setPreview(Maps.preview(map));task.defer(function()if picture.Parent then raster:fit();raster:draw()end end);picture.Destroying:Once(function()raster:destroy()end)
    local tx=compact and 82 or slim and 128 or 172;local title=label(f,'Title',(Maps.meta(map)or Maps.catalog[1]).label,tx,compact and 2 or 8,w-tx-24,32,compact and 20 or 24);Theme.display(title)
    if editable then local b=UI.button(f,'ChangeMap','지도 바꾸기',function()lobby.returnPage='custom';lobby:openPage('maps')end);UI.box(b,tx,40,w-tx-24,44)end
    return y+h+(compact and 8 or 12)
end
local function row(p,name,text,y,w,fn,primary)local b=UI.button(p,name,text,fn,primary);UI.box(b,2,y,w-4,48);return y+56,b end
local function choices(p,name,values,current,y,w,fn)
    for i,v in ipairs(values)do local b=UI.button(p,name..v[1],v[2],function()fn(v[1])end,v[1]==current);UI.box(b,2+(i-1)*(w+6)/#values,y,(w-8-6*(#values-1))/#values,48);b.TextSize=14
        if v[1]=='public'then UI.box(require(script.Parent.OutgameIcons).create(b,'vip',20,UI.colors.vip),10,14,20,20);UI.make('UIPadding',b,{PaddingLeft=UDim.new(0,24)})end
    end;return y+56
end
local Rows=require(script.Parent.SettingsRows)
local RuleRows=require(script.Parent.MatchRuleRows)
local numeric=Rows.numeric
local function canLaunch(q)
    if not q or q.count<q.minimum then return false end
    for _,member in ipairs(q.members or {})do if member.userId~=q.hostUserId and not member.ready then return false end end
    return true
end
function M.begin(lobby,edit,mode)
    if edit then local q=lobby.data and lobby.data.queue;if not q or q.mode~='custom'or q.hostUserId~=Players.LocalPlayer.UserId then return end;lobby.customDraft=Copy.copy(q.rules);lobby.customEditRevision=q.revision;lobby.customEditing=true;lobby.customStep=2
    elseif mode or not lobby.customDraft or lobby.customEditing then lobby.customDraft=Rules.default(lobby.map,mode or 'coop');lobby.customEditing=false;lobby.customStep=1 end
    lobby:openPage('custom')
end
function M.party(lobby,challenge)
    local party=lobby.data and lobby.data.party
    if party and party.leader~=Players.LocalPlayer.UserId then return end
    lobby.customDraft=require(pack.Core.PartyPlay).coop(lobby.map,party,challenge)
    lobby.customEditing=false;lobby.customStep=3;lobby:openPage('custom')
end
function M.primary(lobby)
    if lobby.page=='customCode'then
        local rules=SettingsCode.decode(lobby.settingsImport and lobby.settingsImport.Text or '')
        if not rules then if lobby.settingsCodeError then lobby.settingsCodeError.Text='설정 코드를 확인해 주세요.'end;return end
        lobby.customDraft=rules;lobby.customStep=2;lobby.customEditing=false;lobby:openPage('custom')
    elseif lobby.page=='custom'then
        if (lobby.customStep or 1)<3 then lobby.customStep=(lobby.customStep or 1)+1;lobby:drawPage();lobby:layout();return end
        local draft=Copy.copy(lobby.customDraft)
        local action=lobby.customEditing and 'customUpdate'or 'customCreate'
        local value=lobby.customEditing and {revision=lobby.customEditRevision,rules=draft}or draft
        local function create()lobby:request(action,value,function()lobby.customDraft=nil;lobby.customEditing=false;lobby:openPage('room')end)end
        local q=lobby.data and lobby.data.queue
        if not lobby.customEditing and q then lobby:request('cancel',nil,create)else create()end
    elseif lobby.page=='customRules'then lobby:openPage('custom')
    elseif lobby.page=='joinCode'then lobby:request('joinCode',lobby.codeInput and lobby.codeInput.Text or '')
    elseif lobby.page=='room'then
        local q=lobby.data and lobby.data.queue;if not q or q.mode~='custom'then return end
        local host=q.hostUserId==Players.LocalPlayer.UserId;local othersReady=canLaunch(q)
        if host and not othersReady then return end
        local action=host and 'customLaunch'or 'customReady'
        lobby:request(action,{revision=q.revision})
    end
end
function M.secondary(lobby)
    if lobby.page=='customCode'then lobby:openPage('custom')
    elseif lobby.page=='custom'then lobby.customStep=math.max(1,(lobby.customStep or 1)-1);lobby:drawPage();lobby:layout()
    elseif lobby.page=='customRules'then lobby:openPage('custom')
    elseif lobby.page=='room'then local q=lobby.data and lobby.data.queue
        if q and q.ready and q.hostUserId~=Players.LocalPlayer.UserId then lobby:request('customReady',{revision=q.revision})else lobby:request('cancel',nil,function()lobby:closePage()end)end
    end
end
function M.footer(lobby)
    local page=lobby.page;local q=lobby.data and lobby.data.queue
    if page=='room'and q and q.mode~='custom'then q=nil end
    if page=='customCode'then lobby.soloStart.Text='설정 적용';lobby.pageSecondary.Text='돌아가기';UI.enabled(lobby.soloStart,true)
    elseif page=='custom'then lobby.soloStart.Text=(lobby.customStep or 1)<3 and '다음'or lobby.customEditing and '규칙 저장'or q and '대기 취소 후 방 만들기'or '방 만들기';lobby.pageSecondary.Text='이전';UI.enabled(lobby.soloStart,not lobby.busy and not(q and (q.locked or q.phase=='transferring')))
    elseif page=='customRules'then lobby.soloStart.Text='완료';lobby.pageSecondary.Text='돌아가기';UI.enabled(lobby.soloStart,true)
    elseif page=='joinCode'then lobby.soloStart.Text='방 참가';UI.enabled(lobby.soloStart,not lobby.busy)
    elseif page=='room'then
        local ready=q and q.ready;local host=q and q.hostUserId==Players.LocalPlayer.UserId;local others=canLaunch(q)
        lobby.soloStart.Text=not q and '방 모집 종료'or q.phase=='transferring'and '전장으로 이동 중…'or q.remaining and '출발 중…'or host and (others and '시작'or '참가자 준비 대기')or ready and '준비 완료'or '준비'
        lobby.pageSecondary.Text=ready and not host and '준비 취소'or q and (q.partyCount or 1)>1 and '파티 방 나가기'or '방 나가기'
        UI.enabled(lobby.soloStart,q~=nil and not lobby.busy and not q.locked and not q.remaining and (not host or others));UI.enabled(lobby.pageSecondary,q~=nil and not lobby.busy and not q.locked)
        if lobby.customTimer then
            local n=q and q.remaining and math.max(0,math.ceil(q.remaining-(os.clock()-(lobby.queueUpdated or os.clock()))))
            lobby.customTimer.Text=q and q.phase=='transferring'and '전장으로 이동 중…'or n and (n>0 and string.format('%d초 뒤 출발',n)or '출발 중…')or host and (others and '출발 가능'or '참가자 준비 대기')or ready and '준비 완료'or '규칙 확인 후 준비'
        end
    end
end
function M.draw(lobby,p,w)
    local page=lobby.page;local y=0;lobby.customTimer=nil
    if page=='customCode'then
        lobby.pageTitle.Text='설정 코드'
        label(p,'ExportTitle','현재 설정 공유',8,y,w-16,28,16);y+=36
        local code=SettingsCode.encode(lobby.customDraft or Rules.default(lobby.map,'coop'))or ''
        local export=UI.make('TextBox',p,{Name='SettingsExport',Text=code,TextEditable=false,ClearTextOnFocus=false,TextSize=13,TextWrapped=true,Font=Enum.Font.Code,TextColor3=UI.colors.ink,BackgroundColor3=UI.colors.raised,BorderSizePixel=0});export:SetAttribute('LocalizationSkip',true);UI.box(export,8,y,w-16,80);y+=92
        label(p,'ImportTitle','친구의 설정 불러오기',8,y,w-16,28,16);y+=36
        lobby.settingsImport=UI.make('TextBox',p,{Name='SettingsImport',Text='',PlaceholderText='SC1.…',ClearTextOnFocus=false,TextSize=13,TextWrapped=true,Font=Enum.Font.Code,TextColor3=UI.colors.ink,BackgroundColor3=UI.colors.raised,BorderSizePixel=0});lobby.settingsImport:SetAttribute('LocalizationSkip',true);UI.box(lobby.settingsImport,8,y,w-16,80);y+=92
        lobby.settingsCodeError=label(p,'SettingsCodeError','',8,y,w-16,30,14,UI.colors.danger);y+=38
        label(p,'PrivateHint','설정만 공유, 초대 방으로 시작',8,y,w-16,32,13,UI.colors.muted);y+=40
    elseif page=='joinCode'then
        lobby.pageTitle.Text='초대 코드'
        label(p,'Hint','친구의 8자리 코드',8,0,w-16,36,16);y=44
        lobby.codeInput=UI.make('TextBox',p,{Name='Code',Text=lobby.inviteCode or '',PlaceholderText='XXXXXXXX',ClearTextOnFocus=false,TextSize=24,Font=Enum.Font.BuilderSansBold,TextColor3=UI.colors.ink,BackgroundColor3=UI.colors.raised,BorderSizePixel=0});UI.box(lobby.codeInput,2,y,w-4,52);y+=64
    elseif page=='room'then
        lobby.pageTitle.Text='커스텀 대기'
        local q=lobby.data and lobby.data.queue
        if not q or q.mode~='custom'then label(p,'Ended','방 모집이 끝났어요.',8,0,w-16,52,18);M.footer(lobby);return end
        local short=lobby.root.AbsoluteSize.Y/Theme.scale<500 or p.Size.Y.Offset<360
        local r=q.rules;y=mapCard(lobby,p,w,r.map,y,false)
        local description=L.text(modes[r.mode])..' / '..L.text(r.spawn=='random'and '랜덤 스폰'or '스폰 선택')..' / '..string.format(L.text('최대 %d명'),r.maximum)..(r.settings and r.settings.mapSize=='normal'and ' / '..L.text('큰 지도')or '')
        label(p,'Rules',description,8,y,w-16,short and 24 or 32,14,UI.colors.muted);y+=short and 28 or 36
        if r.mode=='coop'then
            local ai=Flow.coopAI(r,q.count)
            label(p,'CoopAI',string.format('출발 %d명 → AI %d명 / %s',ai.projected,ai.ai,L.text(difficulties[r.settings.difficulty])),8,y,w-16,28,14,UI.colors.ice);y+=32
            local hint=ai.limited and string.format('지도 최대 AI %d명 / 접속 인원으로 확정',ai.cap)or r.aiCount and 'AI 총원 고정 / 파티 전원 함께 입장'or 'AI 수는 접속 인원에 맞춰 확정'
            local note=label(p,'CoopAIHint',hint,8,y,w-16,short and 22 or 36,14,UI.colors.muted);note.TextWrapped=true;y+=short and 26 or 40
        end
        if short then lobby.pageTitle.Text='커스텀 대기 / '..q.count..'명'
        else lobby.customTimer=label(p,'Status','',8,y,w-16,32,14,UI.colors.accent);y+=36 end
        if q.teamPlan then y=row(p,'TeamSeats','팀 편성',y,w,function()lobby.teamRoster:open(q)end)end
        for _,member in ipairs(q.members or {})do
            local f=UI.panel(p,'Member'..member.userId);UI.box(f,2,y,w-4,40)
            local avatar=UI.make('ImageLabel',f,{Name='Avatar',Image='rbxthumb://type=AvatarHeadShot&id='..member.userId..'&w=150&h=150',BorderSizePixel=0,BackgroundColor3=UI.colors.raised});UI.box(avatar,4,4,36,36)
            local honor=Honor.of(member.userId)
            local name=label(f,'Name',member.name,48,honor and 3 or 2,w-164,honor and 20 or 40,14);name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd;name:SetAttribute('LocalizationSkip',true)
            if honor then
                local worn=label(f,'Honor',Honor.line(honor),48,22,w-164,16,12,Theme.colors.gold);worn.TextWrapped=false;worn.TextTruncate=Enum.TextTruncate.AtEnd;worn:SetAttribute('LocalizationSkip',true)
                if honor.plate then Theme.stroke(avatar,Honor.edge(honor.plate),2)end
            end
            label(f,'Host',member.userId==q.hostUserId and '방장'or '',w-110,2,34,40,14,UI.colors.ice)
            local team=q.teamPlan and q.teamPlan.teams[tostring(member.userId)]
            if team then local host=f:FindFirstChild('Host');if host then host.Size=UDim2.fromOffset(34,20)end;label(f,'Team',string.format('%d팀',team),w-110,20,34,20,12,Theme.colors.accent)end
            local ready;if member.userId==q.hostUserId then ready=canLaunch(q)else ready=member.ready end
            label(f,'Ready',member.userId==q.hostUserId and (ready and '시작 가능'or '대기 중')or member.ready and '완료'or '준비 중',w-72,2,60,36,14,ready and UI.colors.accent or UI.colors.muted);y+=44
        end
        if q.hostUserId==Players.LocalPlayer.UserId then y=row(p,'Edit','규칙 바꾸기',y,w,function()M.begin(lobby,true)end)end
        label(p,'CodeTitle','초대 코드 / '..(q.code or ''),8,y,w-16,32,16,UI.colors.ice);y+=40
        y=row(p,'Invite','Roblox 친구 초대',y,w,function()
            task.spawn(function()local social=game:GetService('SocialService');local ok,can=pcall(function()return social:CanSendGameInviteAsync(Players.LocalPlayer)end)
                if ok and can then local options=Instance.new('ExperienceInviteOptions');options.LaunchData=game.HttpService:JSONEncode({commanderRoom=q.code});pcall(function()social:PromptGameInvite(Players.LocalPlayer,options)end)
                else lobby.notify('친구에게 초대 코드 공유')end
            end)
        end)
    elseif page=='customRules'then
        lobby.pageTitle.Text='상세 규칙';local r=lobby.customDraft;local s=r.settings;local tab=lobby.customRulesTab or 'economy'
        y=choices(p,'Tab',{{'economy','상대와 경제'},{'special','특수 규칙'},{'match','경기 규칙'}},tab,y,w,function(v)lobby.customRulesTab=v;lobby:drawPage()end)
        local ctx={s=s,map=r.map,coop=r.mode=='coop',teams=r.mode=='teams',set=function(key,value)RuleRows.applyCustom(r,key,value);lobby:drawPage()end}
        if tab=='economy'then y=RuleRows.draw(p,w,y,ctx,{'opponents','economy'})
        elseif tab=='special'then
            y=row(p,'RollSpecial','무작위 특수 규칙',y,w,function()Rules.rollSpecial(r,Random.new());lobby:drawPage()end,true)
            local rolled=r.modifiers
            if rolled and #rolled>0 then local names={};for _,k in ipairs(rolled)do table.insert(names,Copy.modifierLabels[k])end;label(p,'Rolled',table.concat(names,' / '),8,y,w-16,32,14,UI.colors.ice);y+=40 end
            y=RuleRows.draw(p,w,y,ctx,{'combat','units'})
        else y=RuleRows.draw(p,w,y,ctx,{'time','map','teams'})end
    else
        lobby.customDraft=lobby.customDraft or Rules.default(lobby.map,'coop');local r=lobby.customDraft;local step=lobby.customStep or 1
        require(script.Parent.StepMarker).set(lobby.pageTitle,lobby.customEditing and '규칙 바꾸기'or '방 만들기',step)
        if step==1 then
            label(p,'Choose','함께할 작전 선택',8,y,w-16,36,18);y+=44
            y=choices(p,'Mode',{{'ffa','개인전'},{'teams','팀전'},{'coop','협동'}},r.mode,y,w,function(v)r.mode=v;r.teamFormat=nil;r.maximum=v=='coop'and 5 or 10;r.minimum=v=='teams'and 2 or 1;lobby:drawPage()end)
            label(p,'Hint',r.mode=='coop'and '모두 같은 편 / vs AI'or r.mode=='teams'and '자동 균형 팀'or '각자 경쟁',8,y,w-16,44,15,UI.colors.muted);y+=52
            y=row(p,'Code','초대 코드로 참가',y,w,function()lobby:openPage('joinCode')end)
            y=row(p,'SettingsCode','설정 코드',y,w,function()lobby:openPage('customCode')end)
            if lobby.data and lobby.data.recentCustom then y=row(p,'RecentCustom','최근 방 다시 만들기',y,w,function()lobby.customDraft=Copy.copy(lobby.data.recentCustom);lobby.customStep=3;lobby:drawPage();lobby:layout()end)end
        elseif step==2 then
            y=mapCard(lobby,p,w,r.map,y,true)
            if r.mode=='coop'then
                local count=lobby.data and lobby.data.party and #lobby.data.party.users or r.maximum
                local values={};for _,e in ipairs(Challenges.entries)do table.insert(values,{e.id,string.format('%d vs %d / %s',count,math.ceil(count*e.ratio),L.text(difficulties[e.difficulty]))})end
                y=choices(p,'CoopChallenge',values,nil,y,w,function(id)lobby.customDraft=Challenges.apply(r,id,count)or r;lobby:drawPage();lobby:layout()end)
            end
            if r.mode=='coop'or r.settings.nations~='disabled'then y=choices(p,'Difficulty',Options.difficulties,r.settings.difficulty,y,w,function(v)r.settings.difficulty=v;lobby:drawPage()end)end
            y=choices(p,'Spawn',{{'select','스폰 선택'},{'random','랜덤 스폰'}},r.spawn,y,w,function(v)r.spawn=v;lobby:drawPage()end)
            y=numeric(p,'Maximum','최대 참가 인원',r.maximum,y,w,r.mode=='teams'and 2 or 1,r.mode=='coop'and 5 or 20,function(n)r.maximum=math.floor(n);r.teamCount=math.min(r.teamCount,math.max(2,r.maximum));lobby:drawPage();lobby:layout()end)
            if r.mode=='coop'then y=numeric(p,'AiRatio','사람마다 상대할 AI 수',r.aiPerHuman,y,w,1,4,function(n)r.aiPerHuman=math.floor(n);r.aiCount=nil;lobby:drawPage();lobby:layout()end)
                if r.aiCount then y=numeric(p,'AiCount','고정 AI 총원',r.aiCount,y,w,1,400,function(n)r.aiCount=math.floor(n);lobby:drawPage();lobby:layout()end)end
                local ai=Flow.coopAI(r,0)
                local projection=r.aiCount and string.format(L.text('최대 %d명 vs AI %d명'),r.maximum,ai.maximum)or string.format(L.text('1~%d명 → AI %d~%d명'),r.maximum,ai.minimum,ai.maximum)
                label(p,'AIProjection',projection,8,y,w-16,32,14,UI.colors.ice);y+=40
            elseif r.mode=='teams'then
                local pick=function(v)r.teamFormat=v~='count'and v or nil;lobby:drawPage();lobby:layout()end
                y=choices(p,'TeamFormatA',{{'count','팀 수'},{'Duos','듀오'},{'Trios','트리오'}},r.teamFormat or 'count',y,w,pick)
                y=choices(p,'TeamFormatB',{{'Quads','쿼드'},{'HumansVsNations','사람 대 국가'}},r.teamFormat or 'count',y,w,pick)
                if not r.teamFormat then y=numeric(p,'TeamCount','최대 팀 수 / 자동 배정',r.teamCount,y,w,2,math.min(10,r.maximum),function(n)r.teamCount=math.floor(n)end)
                else label(p,'TeamFormatHint',r.teamFormat=='HumansVsNations'and '사람 모두 한 팀 / vs AI 국가'or '들어온 순서로 팀 채움',8,y,w-16,32,14,UI.colors.muted);y+=40 end
            end
            if r.mode=='teams'and r.teamFormat~='HumansVsNations'then y=choices(p,'TeamAssignment',{{'auto','자동 배정'},{'select','팀 직접 선택'}},r.teamAssignment or 'auto',y,w,function(v)r.teamAssignment=v;lobby:drawPage()end)end
            y=row(p,'Advanced','상세 규칙',y,w,function()lobby:openPage('customRules')end)
        else
            local billing=lobby.account and lobby.account.billing;local publicOk=billing and billing.benefits and billing.benefits.publicCustom
            if not publicOk and r.visibility=='public'then r.visibility='invite'end
            y=choices(p,'Visibility',{{'invite','초대 전용'},{'public','공개 모집'}},r.visibility,y,w,function(v)
                if v=='public'and not publicOk then require(script.Parent.LobbyConfirm).open(lobby,'공개 모집','친구 초대 코드 방은 누구나 무료로 만들 수 있어요. 공개 모집은 VIP 혜택이에요. 혜택을 볼까요?','혜택 보기',function()lobby:openPage('benefits')end,'custom');return end
                r.visibility=v;lobby:drawPage()
            end)
            if not publicOk then for _,o in ipairs(p:GetDescendants())do if o:IsA('TextButton')and o.Text=='공개 모집'then
                o.TextColor3=UI.colors.muted;local tag=require(script.Parent.VipLock).tag(o,o.AbsoluteSize.X>0 and o.Size.X.Offset-34 or 60,10);tag.ZIndex=o.ZIndex+3
            end end end
            y=mapCard(lobby,p,w,r.map,y,false)
            local summary=L.text(modes[r.mode])..' / '..L.text(r.spawn=='random'and '랜덤 스폰'or '스폰 선택')..' / '..string.format(L.text('최대 %d명'),r.maximum)
            local summaryLabel=label(p,'Summary',summary,8,y,w-16,44,14);summaryLabel.TextWrapped=true;y+=48
            if r.mode=='coop'then
                local ai=Flow.coopAI(r,0);local text=r.aiCount and string.format(L.text('%d명 vs AI %d명 / %s'),r.maximum,ai.ai,L.text(difficulties[r.settings.difficulty]))or L.text(difficulties[r.settings.difficulty])..' / '..string.format(L.text('1~%d명 → AI %d~%d명'),r.maximum,ai.minimum,ai.maximum)
                local hint=label(p,'AI',text,8,y,w-16,44,14,UI.colors.ice);hint.TextWrapped=true;y+=48
            end
            label(p,'Reward',Rules.rewardMode(r)=='custom'and '자유 규칙 / 연습 기록'or '일반 기록 / 랭킹 점수 제외',8,y,w-16,36,13,UI.colors.muted);y+=40
            y=row(p,'ShareSettings','설정 코드',y,w,function()lobby:openPage('customCode')end)
            local billing=lobby.account and lobby.account.billing
            if billing and billing.benefits.presetSlots>0 then
                y=row(p,'Presets','설정 보관함',y,w,function()lobby:openPage('presets')end)
            end
            local q=lobby.data and lobby.data.queue;if q and q.mode=='pvp'then label(p,'Switch','공식 대기 → 방 만들기',8,y,w-16,40,13,UI.colors.danger);y+=44 end
        end
    end
    p.CanvasSize=UDim2.fromOffset(0,y+4);M.footer(lobby)
end
return M
