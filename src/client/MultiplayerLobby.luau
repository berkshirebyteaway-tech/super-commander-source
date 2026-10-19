local Players=game:GetService('Players')
local Social=game:GetService('SocialService')
local pack=game.ReplicatedStorage.FrontierNative
local UI=require(script.Parent.ToyUI)
local Maps=require(pack.Maps.MapLoader)
local Rules=require(pack.Core.OutgameRules)
local Raster=require(script.Parent.RasterMap)
local Art=require(script.Parent.LobbyArt)
local Theme=require(script.Parent.Theme)
local Requests=require(pack.Core.RequestLifecycle)
local Teleport=game:GetService('TeleportService')
local Localization=require(script.Parent.Localization)
local Veil=require(script.Parent.TransitionVeil)
local Honor=require(script.Parent.CommanderHonor)
local PageLayout=require(pack.Core.OutgamePresentation)
local Currency=require(script.Parent.CurrencyChip)
local M={};M.__index=M
local modes={'single','pvp','coop'}
local names={single='캠페인',pvp='대전',coop='연합전'}
local colors={single=UI.colors.accent,pvp=UI.colors.peach,coop=UI.colors.lilac}
function M.new(root,notify,callbacks)
    local self=setmetatable({root=root,notify=notify,callbacks=callbacks,selectedMode='single',map='world',single=false,expanded=true,account={},settings={}},M)
    self.deploymentFocus=UI.make('Frame',root,{Name='DeploymentFocus',Size=UDim2.fromScale(1,1),BackgroundColor3=UI.colors.bg,BackgroundTransparency=.48,BorderSizePixel=0,ZIndex=17,Active=false,Visible=false})
    self.frame=UI.make('Frame',root,{Name='MultiplayerLobby',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=18})
    local f=self.frame
    self.header=UI.panel(f,'Welcome');self.brand=UI.label(self.header,'Brand','COMMANDER',26);self.tag=UI.label(self.header,'Tag','세계를 지휘하라.',12,UI.colors.muted)
    self.brandTop=UI.label(self.header,'BrandTop','S U P E R',10,UI.colors.accent)
    for _,l in ipairs({self.brand,self.brandTop})do Theme.display(l);l:SetAttribute('LocalizationSkip',true)end
    self.profile=UI.button(f,'Profile','',function()self:openPage('records')end)
    self.avatar=UI.corner(UI.make('ImageLabel',self.profile,{Name='Avatar',Image='rbxthumb://type=AvatarHeadShot&id='..Players.LocalPlayer.UserId..'&w=150&h=150',BackgroundColor3=UI.colors.yellow,BorderSizePixel=0}),14)
    self.level=UI.label(self.profile,'Level','Lv. 1',14);self.medals=UI.label(self.profile,'Medals','코인 0',12,UI.colors.gold)
    self.settingsButton=UI.button(f,'Settings','설정',callbacks.settings);self.help=UI.button(f,'Help','?',callbacks.help)
    self.panel=UI.panel(f,'PlayDesk');self.heading=UI.label(self.panel,'Heading','작전 대기',22)
    self.collapse=UI.button(self.panel,'Collapse','−',function()self.expanded=false;self:layout()end)
    self.cards={}
    for _,mode in ipairs(modes)do
        local b=UI.button(self.panel,'Mode_'..mode,'',function()self:selectMode(mode)end);b.BackgroundColor3=colors[mode]:Lerp(UI.colors.bg,.78)
        local art=Art.new(b,mode);local name=UI.label(b,'Name',names[mode],15);name.TextXAlignment=Enum.TextXAlignment.Center
        self.cards[mode]={button=b,art=art,name=name,stroke=b:FindFirstChildOfClass('UIStroke')}
    end
    self.hero=UI.button(self.panel,'MapAndMode','',function()if self.selectedMode=='single'then self:openPage('maps')end end)
    self.picture=UI.corner(UI.make('Frame',self.hero,{Name='MapPreview',BackgroundColor3=UI.colors.ocean,ClipsDescendants=true,BorderSizePixel=0}),12);self.raster=Raster.new(self.picture,160,96)
    self.art=Art.new(self.hero,'coop');self.art.Visible=false
    self.mapTitle=UI.label(self.hero,'Title','세계',17);self.modeHint=UI.label(self.hero,'Hint','지도 바꾸기 ›',12,UI.colors.muted)
    self.ruleButton=UI.button(self.hero,'Rules','규칙',callbacks.rules);self.reward=UI.pill(self.hero,'Reward','기본',UI.colors.yellow)
    self.play=UI.button(self.panel,'Play','시작하기',function()self:playNow()end,true)
    self.cancel=UI.button(self.panel,'Cancel','취소',function()if self.data and self.data.queue then self:request('cancel')else self.skipIntro=true;self:refresh();self:playNow()end end)
    self.status=UI.label(self.panel,'Status','',12,UI.colors.muted);self.status.TextXAlignment=Enum.TextXAlignment.Center
    self.quick=UI.button(f,'OpenQuickStart','플레이',function()self.expanded=true;self:layout()end,true)
    self.nav=UI.panel(f,'Navigation');self.nav.ZIndex=30;self.navButtons={}
    for _,item in ipairs({{'play','플레이'},{'wardrobe','스킨'},{'shop','상점'},{'clan','클랜'},{'missions','목표'},{'records','전적'},{'preferences','설정'}})do
        self.navButtons[item[1]]=UI.button(self.nav,'Nav_'..item[1],item[2],function()if item[1]=='play'then self:closePage();self.deployment:setOpen(false);self:layout()else self:openPage(item[1])end end)
    end
    self.friends=UI.button(f,'Friends','친구 +',function()self:openPage('friends')end)
    self.motions=UI.button(f,'Motions','M 모션',function()if self.callbacks.motions then self.callbacks.motions()end end)
    self.rewardArrival=require(script.Parent.RewardArrival).new(root,self.profile)
    self.mission=UI.button(f,'TrackedGoal','',function()self:openPage('missions')end)
    self.goalTitle=UI.label(self.mission,'Title','첫 땅 넓히기',13);self.goalSub=UI.label(self.mission,'Reward','+50 코인',11,UI.colors.gold)
    self.copyright=UI.button(f,'Credits','© OpenFront and Contributors',callbacks.credits);self.copyright.BackgroundTransparency=1;self.copyright.TextSize=10;self.copyright:FindFirstChildOfClass('UIStroke').Enabled=false
    self.practice=UI.button(root,'PracticeQueue','대전 상대 찾는 중 / 취소',function()self:request('cancel')end);self.practice.ZIndex=22;self.practice.Visible=false;self.practice.TextSize=12
    self.overlay=UI.make('Frame',f,{Name='OutgamePage',BackgroundColor3=Color3.fromRGB(4,7,11),BackgroundTransparency=.25,Size=UDim2.fromScale(1,1),Active=true,Visible=false,ZIndex=25})
    self.pageCard=UI.panel(self.overlay,'Card');self.pageTitle=UI.label(self.pageCard,'Title','',22)
    self.pageClose=UI.button(self.pageCard,'Close','×',function()self:back()end)
    self.soloStart=UI.button(self.pageCard,'StartSolo','시작',function()if self.page=='solo'then require(script.Parent.DeploymentSetup).start(self)else require(script.Parent.CustomDeployment).primary(self)end end,true);self.soloStart.Visible=false
    self.pageSecondary=UI.button(self.pageCard,'Previous','이전',function()if self.page=='solo'then self:closePage()else require(script.Parent.CustomDeployment).secondary(self)end end);self.pageSecondary.Visible=false
    self.pageBody=UI.make('ScrollingFrame',self.pageCard,{Name='Body',Active=true,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=UI.colors.line,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y})
    self.pageTabs=UI.make('Frame',self.pageCard,{Name='GoalTabs',BackgroundTransparency=1,Visible=false})
    self.goalStart=UI.button(self.pageCard,'GoalMatch','목표 도전',function()self:startGoal()end,true);self.goalStart.Visible=false
    self.goalRules=UI.label(self.goalStart,'Rules','',12,UI.colors.bg);self.goalRules.TextXAlignment=Enum.TextXAlignment.Center;self.goalStart.Text=''
    self.goalAction=UI.label(self.goalStart,'Action','목표 도전',17,UI.colors.bg);self.goalAction.TextXAlignment=Enum.TextXAlignment.Center
    self.teamRoster=require(script.Parent.TeamRoster).new(f,{canChoose=function(id)return self.data and self.data.queue and self.data.queue.field==id and self.data.queue.mode=='custom'end,
        choose=function(team,revision,id)if self.data and self.data.queue and self.data.queue.field==id then self:request('customTeam',{team=team,revision=revision})end end})
    self.deployment=require(script.Parent.DeploymentView).new(f,{
        teams=function(field)self.teamRoster:open(field)end,
        solo=function()self:closePage();self.selectedMode='single';self.touchedMode=true;self:openPage('solo')end,
        create=function(mode)local q=self.data and self.data.queue;if q and q.mode=='custom'then self:openPage('room')else require(script.Parent.CustomDeployment).begin(self,false,mode)end end,
        ranked=function()self:openPage('ranked')end,
        watch=function()self:openPage('watch')end,
        room=function()self:openPage('room')end,
        code=function()self:openPage('joinCode')end,
        join=function(ticket)self:request('joinField',ticket)end,
        cancel=function()self:request('cancel')end,
        practice=function()self:request('practice')end,
        partyCoop=function(hard)require(script.Parent.CustomDeployment).party(self,hard)end,
        ready=function()self:request('ready')end,
        party=function()self:openPage('friends')end,
        toggled=function()self:layout()end,
    })
    self.home=require(script.Parent.LobbyHome).new(self)
    self.card=require(script.Parent.CommanderCard).new(self)
    self.worldBoards=require(script.Parent.LobbyBattlefields).new(self)
    pack:WaitForChild('LobbyState').OnClientEvent:Connect(function(s)
        self.queueUpdated=os.clock()
        local previousQueue=self.data and self.data.queue;local previousField=previousQueue and previousQueue.field
        self.data=s
        if s.openMode then self:openStation(s.openMode,s.openField)end
        if s.openPage then self:openPage(s.openPage)end
        if s.inviteRoomCode and not self.inviteHandled then self.inviteHandled=true;self.inviteCode=s.inviteRoomCode;self:openPage('joinCode')end
        if s.party and #s.party.users>1 and not s.queue then self.selectedMode=s.party.mode or 'coop'end
        if self.inMenu==false then self:announce(s.queue);self:practiceBadge()else self:refresh()end
        if s.queue and s.queue.mode=='custom'and (s.queue.partyCount or 1)>1 and previousField~=s.queue.field then self:openPage('room')end
        if previousQueue and previousQueue.mode=='custom'and not s.queue and not s.inMatch then require(script.Parent.TelemetryStep).step('custom','roomClosed',{value=self.roomSince and os.clock()-self.roomSince or nil,count=previousQueue.partyCount,result=self.page=='room'and 'shown'or 'closed'});self.roomSince=nil end
        if s.queue and s.queue.mode=='custom'and not self.roomSince then self.roomSince=os.clock()end
        if previousQueue and previousQueue.mode=='custom'and not s.queue and not s.inMatch and self.page=='room'then self:closePage()end
        if self.page=='watch'and require(script.Parent.LiveWatchPage).signature(s.live)~=self.liveSignature then self:drawPage()end
        if self.page=='friends'then local signature=game.HttpService:JSONEncode({s.party,s.players,s.invites,s.sent,s.partyStatus});if signature~=self.friendSignature then self.friendSignature=signature;self:drawPage()end end
    end)
    task.spawn(function()local ok,r=pcall(function()return pack.LobbyRequest:InvokeServer('read')end);if ok and r.state then self.data=r.state;self:refresh()end end)
    local elapsed=0
    self.queueClock=game:GetService('RunService').Heartbeat:Connect(function(dt)
        if not self.frame.Parent then self.queueClock:Disconnect();return end
        self.rewardArrival:step(self.frame.Visible and not self.page and not require(script.Parent.LobbyIntro).active and self.profile.Visible,self.account.preferences and self.account.preferences.reducedEffects)
        elapsed+=dt;if self.inMenu==false then if elapsed>=.25 then elapsed=0;if self.data and self.data.queue then self:practiceBadge()end end elseif elapsed>=.25 then elapsed=0;if self.data and self.data.queue then self:refresh()elseif self.deployment and self.deployment.expanded and not self.page then self.deployment:render()end end
    end)
    self:refresh();return self
end
function M:showCheckIn(info,login)
    local Audio=require(script.Parent.ToyAudio);local Tween=game:GetService('TweenService')
    local card=UI.button(self.root,'CheckInCelebration','',function()end);card.ZIndex=45;card.AutoButtonColor=false;card.BackgroundColor3=UI.colors.panel
    local extra={};for _,id in ipairs(info.unlocked or {})do for _,a in ipairs(Rules.achievementList)do if a.id==id then table.insert(extra,string.format('업적 달성 %s, 목표에서 +%d 코인 받기',a.name,a.medals))end end end
    for _,t in ipairs(Rules.career.streakTitles)do if info.streak==t.days and (not login or login.best==t.days)then table.insert(extra,string.format('새 보상 / %s',Rules.career.rewardLabel({kind='title',name=t.name})))end end
    local rw=self.root.AbsoluteSize.X/Theme.scale;local w=math.min(320,rw-24);UI.box(card,(rw-w)/2,70,w,128+22*math.min(2,#extra))
    for i=1,math.min(2,#extra)do local l=UI.label(card,'Unlock'..i,extra[i],13,UI.colors.gold);UI.box(l,16,118+(i-1)*22,w-32,20);l.TextXAlignment=Enum.TextXAlignment.Center;l.ZIndex=46 end
    local title=UI.label(card,'Title',string.format('누적 출석 %d일',info.claims or info.streak),22);UI.box(title,16,8,w-32,34);title.TextXAlignment=Enum.TextXAlignment.Center;title.ZIndex=46
    local reward=UI.label(card,'Reward',string.format('+%d 코인',info.medals),18,UI.colors.gold);UI.box(reward,16,42,w-32,28);reward.TextXAlignment=Enum.TextXAlignment.Center;reward.ZIndex=46
    local n=#Rules.streakRewards;local dw=(w-32-(n-1)*4)/n;local at=info.rewardStep or (info.streak-1)%n+1
    for i=1,n do local d=UI.make('Frame',card,{Name='Day'..i,BackgroundColor3=i<=at and UI.colors.accent or UI.colors.raised,BorderSizePixel=0,ZIndex=46});UI.box(d,16+(i-1)*(dw+4),78,dw,10);UI.corner(d,5)end
    local nextLine=UI.label(card,'Next',string.format('다음 접속 +%d 코인',login and login.nextReward or Rules.streakRewards[at%n+1]),14,UI.colors.muted);UI.box(nextLine,16,94,w-32,24);nextLine.TextXAlignment=Enum.TextXAlignment.Center;nextLine.ZIndex=46
    local scale=UI.make('UIScale',card,{Scale=.6});Tween:Create(scale,TweenInfo.new(.35,Enum.EasingStyle.Quint),{Scale=1}):Play()
    Audio.play('milestone');require(script.Parent.TelemetryStep).step('lobby','checkInCard',{value=info.medals,count=info.claims or info.streak,item='step'..tostring(at),result='shown'})
    local closed;local function close(how)if card.Parent and not closed then closed=true;require(script.Parent.TelemetryStep).step('lobby','checkInClose',{reason=how=='auto'and 'auto'or 'manual'})end;if card.Parent then Tween:Create(scale,TweenInfo.new(.18),{Scale=.01}):Play();task.delay(.2,function()card:Destroy()end)end end
    card.Activated:Connect(function()close('manual')end);task.delay(5,close,'auto')
end
function M:celebrate(before,p,checkIn,recruited)
    if checkIn and self.checkInShown~=(checkIn.claims or checkIn.streak)then self.checkInShown=checkIn.claims or checkIn.streak;task.spawn(function()
        local Intro=require(script.Parent.LobbyIntro);local untilAt=os.clock()+3600
        local function ready()return self.frame.Parent and self.frame.Visible and self.inMenu~=false and not Intro.active and not self.firstLesson and not self.page end
        while self.frame.Parent and os.clock()<untilAt do
            task.wait(.5)
            if ready()then task.wait(.6);if ready()then self:showCheckIn(checkIn,p and p.login);return end end
        end
    end)end
    local void=p and p.voided
    if type(void)=='table'and type(void.id)=='string'and self.voidShown~=void.id then self.voidShown=void.id;task.spawn(function()
        local Intro=require(script.Parent.LobbyIntro);local untilAt=os.clock()+3600
        local function ready()return self.frame.Parent and self.frame.Visible and self.inMenu~=false and not Intro.active and not self.firstLesson and not self.page end
        while self.frame.Parent and os.clock()<untilAt do
            task.wait(.5)
            if ready()then task.wait(.6);if ready()then require(script.Parent.MatchVoidNotice).show(self,void);return end end
        end
    end)end
    local function say(text,kind)self.notify(text,false,nil,true);if kind then require(script.Parent.TelemetryStep).step('lobby','toast',{item=kind,result='shown'})end end
    if recruited and recruited.at~=self.recruitSeen then self.recruitSeen=recruited.at;say(string.format('초대한 지휘관 %d명 합류 / +%d 코인',recruited.count,recruited.medals),'recruit')end
    if not before or not before.achievementList or not p or not p.achievementList or require(script.Parent.ResultCelebration).cardOpen()then return end
    if before.title and p.title and p.title~=before.title then say(string.format('진급! %s / Lv. %d',p.title,p.level or 1),'promotion')end
    local was={};for _,a in ipairs(before.achievementList)do was[a.id]=a.done end
    for _,a in ipairs(p.achievementList)do if a.done and not was[a.id]then say(string.format('업적 달성 %s, 목표에서 +%d 코인 받기',a.name,a.medals),'achievement')end end
    local tier={};for _,t in ipairs(before.tactics or {})do tier[t.id]=t.tier end
    for _,t in ipairs(p.tactics or {})do if before.tactics and t.tier>(tier[t.id]or 0)then say(string.format('전술 기장 %s / %s',string.rep('★',t.tier),t.name),'tactic')end end
    local s0,s1=before.career and before.career.season,p.career and p.career.season
    if s0 and s1 and s0.id==s1.id and s1.tier>s0.tier and s1.steps then local coins=0;for i=s0.tier+1,s1.tier do coins+=s1.steps[i]and s1.steps[i].coins or 0 end
        say(string.format('%s %d점 달성 / +%d 코인',s1.name,s1.steps[s1.tier]and s1.steps[s1.tier].score or 0,coins),'seasonTier')end
    for _,m in ipairs(Rules.career.motions)do if m.level>(before.level or 1)and m.level<=(p.level or 1)then say(string.format('새 보상 / %s',Rules.career.rewardLabel({kind='motion',name=m.name})),'motion')end end
    local function count(c)return c and (#(c.titles or {})+#(c.plates or {}))or 0 end
    if before.career and p.career and count(p.career)>count(before.career)then say(string.format('새 보상 %d개 / 스킨에서 장착',count(p.career)-count(before.career)))end
end
function M:setAccount(account)
    local before=self.account and self.account.ready and self.account.progress
    self.account=account;local p=account.progress
    self.rewardArrival:capture(before,p)
    self:celebrate(before,p,account.checkIn,account.recruited)
    if account.ready and p and not self.loadedAccount then self.loadedAccount=true;self.readyAt=os.clock();if not self.touchedMode then self.selectedMode=p.lastMode or(p.basicsComplete and 'pvp'or 'single')end;if not self.touchedMap then self.map=p.single.map end end
    self:refresh();require(script.Parent.CollectionBadges).refresh(self);if self.page and self.page~='maps'and self.page~='friends'then self:drawPage()end
end
function M:setGameState(state)
    if state.phase~='menu'and self.teamRoster then self.teamRoster:hide()end
    self.settings=state.settings or self.settings
    if state.phase=='menu'and state.selectedMap and not self.touchedMap then self.map=state.selectedMap end
    local key=state.phase~='menu'and tostring(state.version)..tostring(state.loading);if key and key==self.gameKey then return end;self.gameKey=key
    self.loading=state.loading;self:refresh()
    if state.phase=='menu'and self.pendingDeployment then
        local quick=self.pendingDeployment=='quick';self.pendingDeployment=nil;self:closePage()
        if quick then task.delay(.6,function()local d=self.deployment;if self.inMenu==false or self.busy or self.loading or self.data and self.data.queue then return end;if d:quickPick()then d:quickJoin()else d:open('official')end;self:layout()end)
        else self.deployment:open('all')end
    end
    if state.phase=='menu'and type(self.pendingCustom)=='table'then
        self.customDraft=require(pack.Core.BattlefieldRules).copy(self.pendingCustom);self.pendingCustom=nil;self.customEditing=false;self.customStep=3;self:openPage('custom')
    end
end
function M:openStation(mode,id)
    self.touchedMode=true;require(script.Parent.TelemetryStep).step('lobby','station',{item=type(mode)=='string'and mode or nil})
    if mode=='create'then require(script.Parent.CustomDeployment).begin(self)
    elseif mode=='single'then self.selectedMode='single';self:openPage('solo')
    else self:closePage();self.deployment:open((mode=='coop'or mode=='custom')and 'custom'or 'official',id);if mode=='coop'then self.deployment.sub='coop';self.deployment:render()end end
end
function M:selectMode(mode)
    if not names[mode]then return end
    self:request('selectMode',mode,function()
        self.selectedMode=mode;self.touchedMode=true;self.expanded=true;self:closePage()
        self.callbacks.mode(mode);self:refresh()
    end)
end
function M:playNow()
    if self.busy or self.loading then return end
    if self.data and self.data.queue then if not self.data.practice then self:request('practice')end;return end
    if self.data and #self.data.party.users>1 and self.data.party.leader~=Players.LocalPlayer.UserId then self:request('ready');return end
    if self.selectedMode=='single'then
        if self.firstLesson then self:closePage();self.callbacks.learn()else self.callbacks.single(self.map)end
    elseif self.selectedMode=='pvp'then self:request('play')
    else self:request('join',self.selectedMode)end
end
function M:clanWarQueue()
    pcall(function()require(script.Parent.TelemetryClient).step('queue','rankedJoin',{item='clanwar'})end)
    self:request('ranked','clanwar')
end
function M:request(action,value,after,handle)
    if self.busy then Veil.hide();return end
    self.requests=self.requests or Requests.new(12)
    local operation=self.requests:begin(os.clock());if not operation then Veil.hide();return end
    if action=='play'or action=='again'then Veil.show('전장 준비 중…')end
    self.busy=true;self:refresh()
    task.delay(12,function()
        if self.requests:expire(operation,os.clock())then
            self.busy=false;self:refresh();require(script.Parent.TelemetryStep).step('lobby','requestFailed',{item=type(action)=='string'and action or nil,reason='timeout'});self.notify('응답 지연 / 연결 확인 후 다시 시도',true)
        end
    end)
    task.spawn(function()
        local delay=.3-(os.clock()-(self.lastRequestSent or -math.huge));if delay>0 then task.wait(delay)end
        self.lastRequestSent=os.clock()
        local ok,r=pcall(function()return pack.LobbyRequest:InvokeServer(action,value)end)
        if not self.requests:complete(operation)then return end
        self.busy=false
        if not ok or not r.ok then Veil.hide()elseif action=='play'or action=='again'then Veil.settle(3)end
        if not ok then require(script.Parent.TelemetryStep).step('lobby','requestFailed',{item=type(action)=='string'and action or nil,reason='network'});self.notify('연결 끊김 / 다시 시도',true);self:refresh();return end
        if r.state then self.data=r.state;self.queueUpdated=os.clock()end
        if handle and handle(r)then self:refresh();return end
        if not r.ok then self.notify(r.message or '다시 시도해 주세요.',true)elseif after then after()end
        if r.ok and (action=='joinField'or action=='joinCode')and self.data.queue and self.data.queue.mode=='custom'then self:openPage('room')end
        if r.ok and r.message then self.notify(r.message)end
        self:refresh();if self.page=='friends'then self:drawPage()end
    end)
end
function M:leaveResult(toMenu)
    local s=self.data;local me=Players.LocalPlayer.UserId
    if s and(s.privateServer~=true or s.party and #s.party.users>1 and s.party.leader~=me)then toMenu();return end
    if self.busy then Veil.hide();self.notify('잠시 뒤 다시 눌러 주세요.',true);return end
    require(script.Parent.TelemetryStep).step('result','lobby',{item=s and 'reserved'or 'unknown'})
    self:request('hq',nil,nil,function(r)if r.public then toMenu();return true end;if r.ok then Veil.teleport('로비로 이동 중…')end end)
end
function M:announce(q)
    local key=q and q.mode=='pvp'and (q.phase=='transferring'and 'go'or q.needsOpponent and 'waiting'or q.count>=q.max and 'full'or q.count>=q.minimum and 'countdown'or 'waiting')or nil
    local previous=self.queueKey;self.queueKey=key
    if previous=='go'and key~='go'then Veil.hide()end
    if not key or key==previous then return end
    if key=='countdown'and previous~='go'then self.notify(string.format('%d초 뒤 출발 / 빈자리 AI / 최대 %d명',math.ceil(q.remaining or 45),q.max))
    elseif key=='waiting'and (previous=='countdown'or previous=='full')then self.notify('모두 나감 / 다시 모이면 45초 뒤 출발',true)
    elseif key=='full'then self.notify(string.format('%d명 모집 완료, 곧 출발',q.max))
    elseif key=='go'then self.notify('전장으로 이동해요');Veil.teleport('전장으로 이동 중…')end
end
function M:practiceBadge()
    local s=self.data;local q=s and s.queue
    local remaining=q and q.remaining and math.max(0,math.ceil(q.remaining-(os.clock()-(self.queueUpdated or os.clock()))))
    self.practice.Visible=s~=nil and s.practice==true and q~=nil
    if q then self.practice.Text=q.count<q.minimum and '상대 찾는 중 / 취소'or string.format('%d명 / %d초 뒤 대전 시작 / 취소',q.count,remaining or 0)end
    if q and q.phase=='transferring'then self.practice.Text='같은 전장으로 이동 중…'elseif q and q.phase=='recovering'then self.practice.Text='연결 확인 중 / 대기 유지'end
    UI.enabled(self.practice,not(q and q.locked))
end
function M:refresh()
    if self.inMenu==false then if self.hiddenDrawn then return end;self.hiddenDrawn=true end
    local Probe=require(script.Parent.FrameProbe);Probe.start('Lobby.refresh');self:refreshBody();Probe.stop('Lobby.refresh')
end
function M:refreshBody()
    local s=self.data;local q=s and s.queue;local party=s and s.party;local p=self.account.progress or {}
    self:announce(q)
    local remaining=q and q.remaining and math.max(0,math.ceil(q.remaining-(os.clock()-(self.queueUpdated or os.clock()))))
    local connecting=q and q.phase=='transferring'
    local mode=self.selectedMode;local isSingle=mode=='single';local cfg=Rules.classify(self.settings)
    self.firstLesson=isSingle and self.account.ready==true and p.tutorial~=false and not p.basicsComplete and not self.skipIntro and not self.touchedMap and cfg=='single'and not q and (not party or #party.users==1)
    for key,c in pairs(self.cards)do c.stroke.Thickness=key==mode and 2 or 1;c.stroke.Color=key==mode and colors[key] or UI.colors.line;c.button.BackgroundColor3=colors[key]:Lerp(UI.colors.bg,key==mode and .55 or .8);c.button.BackgroundTransparency=0;c.name.TextColor3=key==mode and UI.colors.ink or UI.colors.muted end
    local streak=p.login and p.login.streak or 0
    local worn=Honor.titleOf(p);self.level.Text='Lv. '..tostring(p.level or 1)..(worn~=''and ' '..worn or '');self.medals.Text='코인 '..UI.number(p.medals or 0)..(streak>0 and '  🔥'..streak or '')
    self.hero.BackgroundColor3=UI.colors.bg;self.ruleButton.Visible=isSingle and not q
    self.picture.Visible=isSingle and not q;self.art.Visible=not isSingle and not q
    self.reward.Text=isSingle and (cfg=='single'and '기본' or '자유 설정')or mode=='coop'and '같은 팀'or '지도 랜덤'
    self.mapTitle.Text=q and ('사람 '..q.count..' / '..q.max)or isSingle and (Maps.meta(self.map)or Maps.catalog[1]).label or mode=='coop'and '함께 컴퓨터 이기기'or '실시간 세계 전쟁'
    self.modeHint.Text=q and (q.count<q.minimum and '참가하면 45초 뒤 출발' or remaining==0 and '전장을 준비하는 중…'or string.format('%d초 뒤 시작 / 현재 인원 출발',remaining or 0))or isSingle and '지도 바꾸기 ›'or mode=='coop'and '1~5명 vs AI 10명'or '진행 중 전장 바로 합류'
    self.play.Text=self.loading and '준비 중…'or q and (q.mode=='pvp'and not s.practice and '연습하며 기다리기'or '참가자 모집 중…')or isSingle and '시작하기' or mode=='coop'and '함께 시작'or '플레이'
    if q and q.global then self.mapTitle.Text=string.format('전 서버 모집 / %d / %d명',q.count,q.max)end
    if q and q.phase=='recovering'then self.modeHint.Text='연결 확인 중 / 대기 유지'
    elseif q and q.needsOpponent then self.modeHint.Text='양 진영 자리 나면 45초 뒤 출발'
    elseif q and q.phase=='next'then self.modeHint.Text='다음 전장 함께 출발'
    elseif connecting then self.modeHint.Text='같은 전장으로 이동 중…';self.play.Text='입장 중…'end
    if party and #party.users>1 and party.leader~=Players.LocalPlayer.UserId and not q then self.play.Text=require(script.Parent.Parent.Core.PartyFormation).isReady(party,Players.LocalPlayer.UserId)and '준비 완료'or '준비'end
    if self.firstLesson then self.play.Text='첫 작전 →'end
    UI.enabled(self.play,(not q or q.mode=='pvp'and not s.practice and not connecting)and not self.busy and not self.loading);self.cancel.Visible=q~=nil or self.firstLesson;self.cancel.Text=q and '취소'or '바로 시작';self.cancel.TextSize=12
    UI.enabled(self.cancel,not self.busy and not(q and q.locked))
    self.status.Text=q and (q.count<q.minimum and '15초 뒤 연습하며 대기 가능'or '취소 불이익 없음')or isSingle and (cfg=='single'and '기본 싱글 / 보상 75%'or '자유 설정 / 반복 보상 없음')or mode=='coop'and '승패 모두 기록'or '중간 참가 무료 / 이탈 불이익 없음'
    if party and #party.users>1 and not q then self.status.Text='친구와 함께 XP +10%'end
    if self.firstLesson then self.status.Text='10분 첫 작전 / 점령과 병력 기초'end
    self:loadFriends();local playing=0
    for _,f in ipairs(self.onlineFriends or {})do if f.PlaceId==game.PlaceId and not Players:GetPlayerByUserId(f.VisitorId)then playing+=1 end end
    self.friends.Text=party and #party.users>1 and ('친구 '..#party.users..'/5')or s and #s.invites>0 and '초대 도착'or playing>0 and string.format('친구 %d명 플레이 중',playing)or '친구 +'
    self:practiceBadge()
    local goal;for _,g in ipairs(Rules.onboarding)do if not(p.onboarding and p.onboarding[g.id])then goal=g;break end end
    local firstWin=p.firstWin or Rules.firstWin
    if goal then self.goalTitle.Text=goal.name;self.goalSub.Text=string.format('+%d 코인  %s',goal.medals,goal.hint or '')
    elseif not p.firstWinToday or os.time()>=(p.dailyReset or math.huge)then self.goalTitle.Text='오늘의 첫 승리';self.goalSub.Text=string.format('+%d XP / +%d 코인',firstWin.xp,firstWin.medals)
    elseif p.career and p.career.goals and p.career.goals[1]then self.goalTitle.Text='다음 목표';self.goalSub.Text=p.career.goals[1]
    else self.goalTitle.Text=string.format('누적 출석 %d일',p.login and p.login.claims or 0);self.goalSub.Text=string.format('다음 접속 +%d 코인',p.login and p.login.nextReward or 20)end
    if self.drawnMap~=self.map then self.drawnMap=self.map;self.raster:setPreview(Maps.preview(self.map));task.defer(function()self.raster:fit();self.raster:draw()end)end
    if self.deployment then local prefs=self.account.preferences or {};self.deployment:update(s and s.battlefields,q,{menu=self.inMenu~=false,practice=s and s.practice,reduced=prefs.reducedEffects,busy=self.busy,party=party,userId=Players.LocalPlayer.UserId,live=s and s.live,recent='최근 / '..(Maps.meta(self.map)or Maps.catalog[1]).label..' / '..({Easy='쉬움',Medium='보통',Hard='어려움',Impossible='불가능'})[self.settings.difficulty or 'Medium']})end
    if self.teamRoster and self.teamRoster.frame.Visible then
        local field=q and q.field==self.teamRoster.id and q or nil
        if not field then for _,candidate in ipairs(s and s.battlefields and s.battlefields.fields or {})do if candidate.id==self.teamRoster.id then field=candidate;break end end end
        self.teamRoster:update(field)
    end
    if self.worldBoards then self.worldBoards:update(s and s.battlefields,q,self.inMenu~=false)end
    if self.page=='room'then
        local signature=game.HttpService:JSONEncode(q and {q.field,q.revision,q.members,q.phase}or {})
        if signature~=self.roomSignature then self.roomSignature=signature;self:drawPage()end
        require(script.Parent.CustomDeployment).footer(self)
    end
    if table.find({'custom','customRules','joinCode','customCode'},self.page)then require(script.Parent.CustomDeployment).footer(self)end
    if self.home then self.home:refresh()end
    self:layout()
end
local subPages={joinCode=true,customCode=true,customRules=true,presets=true,maps=true,benefits=true,confirm=true}
function M:openPage(page)
    local from=self.page
    if not subPages[page]then self.backTo=nil elseif from and from~=page and (from=='custom'or from=='solo')then self.backTo=from end
    local screen=({solo='single',missions='goals',preferences='settings',joinCode='custom',customCode='custom',customRules='custom',maps='deployment',watch='spectate',motions='motion',confirm='menu'})[page]or page
    require(script.Parent.TelemetryClient).emit('screen_viewed',{screen=screen,result='shown'})
    if page=='solo'then self:refresh()end
    self.page=page;self.overlay.Visible=true;self.pageBody.CanvasPosition=Vector2.zero;self:layout();self:drawPage()
end
function M:invite(target)
    task.spawn(function()
        local me=Players.LocalPlayer
        local ok,can=pcall(function()return Social:CanSendGameInviteAsync(me,target)end)
        if not(ok and can)then require(script.Parent.TelemetryStep).step('social','robloxInvite',{result='unavailable'});self.notify('이 계정에서는 지금 Roblox 초대를 보낼 수 없어요',true);return end
        require(script.Parent.TelemetryStep).step('social','robloxInvite',{result='opened',item=target and 'friend'or 'any'})
        local options=Instance.new('ExperienceInviteOptions');options.LaunchData=game.HttpService:JSONEncode({party=me.UserId})
        if target then options.InviteUser=target end
        pcall(function()Social:PromptGameInvite(me,options)end)
    end)
end
function M:loadFriends()
    if self.friendsLoading or self.friendsAt and os.clock()-self.friendsAt<20 then return end
    self.friendsLoading=true
    task.spawn(function()
        local ok,list=pcall(function()return Players.LocalPlayer:GetFriendsOnline(50)end)
        self.friendsLoading=false;self.friendsAt=os.clock();self.onlineFriends=ok and list or {}
        if self.page=='friends'then self:drawPage()end
        if self.data then pcall(function()self:refresh()end)end
    end)
end
function M:follow(friend)
    if not self.teleportHooked then self.teleportHooked=true
        Teleport.TeleportInitFailed:Connect(function(player)if player==Players.LocalPlayer then require(script.Parent.TelemetryStep).step('social','follow',{result='failed',reason='network'});self.notify('친구 경기 중 / 끝난 뒤 다시 시도',true)end end)
    end
    self.notify('친구에게 가는 중…')
    task.spawn(function()
        local ok=pcall(function()Teleport:TeleportToPlaceInstance(friend.PlaceId,friend.GameId,Players.LocalPlayer,nil,{party=friend.VisitorId})end)
        require(script.Parent.TelemetryStep).step('social','follow',{result=ok and 'opened'or 'failed'})
        if not ok then self.notify('친구 경기 중 / 끝난 뒤 다시 시도',true)end
    end)
end
function M:startGoal()
    if self.busy or self.loading or not self.settings.difficulty then return end
    local decision=require(pack.Core.PlayFlow).single(self.data and self.data.queue)
    local function start()self:closePage();self.callbacks.goal(self.map)end
    if decision=='replace'then self:request('cancel',nil,start)elseif decision~='moving'then start()end
end
function M:back()
    local page=self.page;local step=self.customStep or 1
    if page=='custom'then
        if self.customEditing and step<=2 then self.customEditing=false;self.customDraft=nil;self:openPage('room')
        elseif step>1 then self.customStep=step-1;self:drawPage();self:layout()
        else self:closePage()end
    elseif self.backTo then
        local back=self.backTo;self.backTo=nil;self.returnPage=nil;self:openPage(back)
    else self:closePage()end
end
function M:closePage()if self.page then require(script.Parent.TelemetryClient).emit('screen_viewed',{screen='lobby',result='shown'})end;self.backTo=nil;Currency.dismiss(true);require(script.Parent.PageWallet).clear(self);if self.page=='wardrobe'then require(script.Parent.CareerWardrobe).flush(self)end;self.page=nil;self.overlay.Visible=false;if self.mapBrowser then self.mapBrowser:destroy();self.mapBrowser=nil end;self:layout()end
function M:drawPage()
    if not self.page then return end
    local Probe=require(script.Parent.FrameProbe);Probe.start('Lobby.drawPage');self:drawPageBody();Probe.stop('Lobby.drawPage')
end
function M:drawPageBody()
    local scroll=self.pageBody.CanvasPosition
    Currency.dismiss(true);Currency.reduced=(self.account.preferences or {}).reducedEffects==true;require(script.Parent.PageWallet).clear(self)
    if self.mapBrowser then self.mapBrowser:destroy();self.mapBrowser=nil end
    for _,o in ipairs(self.pageBody:GetChildren())do o:Destroy()end
    for _,o in ipairs(self.pageTabs:GetChildren())do o:Destroy()end
    local side=PageLayout.inset(self.page)
    UI.make('UIPadding',self.pageBody,{Name='ContentInset',PaddingLeft=UDim.new(0,side),PaddingRight=UDim.new(0,side),PaddingTop=UDim.new(0,PageLayout.top),PaddingBottom=UDim.new(0,PageLayout.bottom)})
    local w=PageLayout.width(self.pageBody.Size.X.Offset,1,side)+6
    if self.page=='preferences'then require(script.Parent.LobbySettings).draw(self,self.pageBody,w-6)
    elseif self.page=='confirm'then require(script.Parent.LobbyConfirm).draw(self,self.pageBody,w-6)
    elseif self.page=='shop'then require(script.Parent.ShopLanding).draw(self,self.pageBody,w-6)
    elseif self.page=='solo'then
        require(script.Parent.DeploymentSetup).draw(self,self.pageBody,w-6)
    elseif table.find({'custom','customRules','room','joinCode','customCode'},self.page)then require(script.Parent.CustomDeployment).draw(self,self.pageBody,w-6)
    elseif self.page=='ranked'then require(script.Parent.RankedEntry).draw(self,self.pageBody,w-6)
    elseif self.page=='watch'then require(script.Parent.LiveWatchPage).draw(self,self.pageBody,w-6)
    elseif self.page=='maps'then
        self.pageTitle.Text='지도 선택'
        local browser=require(script.Parent.MapBrowser).new(self.pageBody,function(key)local back=self.returnPage;self.returnPage=nil;require(script.Parent.TelemetryStep).step('map_ui','mapPick',{map_key=key,item=back or 'solo'});if back=='custom'and self.customDraft then self.customDraft.map=key else self.map=key;self.touchedMap=true;self.callbacks.map(key)end;if back then self:openPage(back)else self:closePage()end;self:refresh()end,UI)
        self.mapBrowser=browser
        browser.selected=self.returnPage=='custom'and self.customDraft and self.customDraft.map or self.map;browser:refreshSelection();browser.onLayout=function()self.pageBody.CanvasSize=UDim2.fromOffset(0,browser.height or 0)end
        self.pageBody.CanvasSize=UDim2.fromOffset(0,browser:layout(w-6,self.root.AbsoluteSize.Y/Theme.scale<500))
    elseif self.page=='motions'then require(script.Parent.MotionsPage).draw(self,self.pageBody,w-6)
    elseif self.page=='clan'then require(script.Parent.ClanPage).draw(self,self.pageBody,w-6)
    elseif self.page=='friends'then
        self.pageTitle.Text='친구와 함께';local y=0
        local function row(name,text,fn,primary)local b=UI.button(self.pageBody,name,text,fn,primary);UI.box(b,2,y,w-10,48);y+=56;return b end
        local function face(b,userId,color)
            local img=UI.make('ImageLabel',b,{Name='Avatar',BackgroundColor3=UI.colors.bg,BorderSizePixel=0,Image='rbxthumb://type=AvatarHeadShot&id='..tostring(userId)..'&w=150&h=150',Position=UDim2.fromOffset(8,7),Size=UDim2.fromOffset(32,32),ZIndex=b.ZIndex+1})
            UI.corner(img,40);UI.stroke(img,color,2)
            local dot=UI.make('Frame',b,{Name='Status',BackgroundColor3=color,BorderSizePixel=0,Position=UDim2.fromOffset(30,29),Size=UDim2.fromOffset(10,10),ZIndex=b.ZIndex+2});UI.corner(dot,40);UI.stroke(dot,UI.colors.panel,2)
            local pad=b:FindFirstChildOfClass('UIPadding')or UI.make('UIPadding',b,{});pad.PaddingLeft=UDim.new(0,50);b.TextXAlignment=Enum.TextXAlignment.Left
            return b
        end
        local party=self.data and self.data.party;local queue=self.data and self.data.queue
        if party and #party.users>1 then
            if queue then row('PartyRoom','참가 중인 전장 보기',function()if queue.mode=='custom'then self:openPage('room')else self:closePage();self.deployment:open('all',queue.field);self:layout()end end)
            else
                local play=require(pack.Core.PartyPlay);local count=play.available(self.deployment.fields,party)
                row('TogetherFields',string.format('함께 입장할 전장 / %d개',count),function()self:closePage();self.deployment:open('all');self:layout()end)
                local n=#party.users;local cw=(w-18)/2
                for i,hard in ipairs({false,true})do local r=play.coop(self.map,party,hard)
                    local text=string.format(hard and '어려움 / %d vs %d'or '협동 / %d vs %d',n,r.aiCount)
                    local b=UI.button(self.pageBody,hard and 'PartyHard'or 'PartyCoop',text,function()require(script.Parent.CustomDeployment).party(self,hard)end)
                    UI.box(b,2+(i-1)*(cw+8),y,cw,46);UI.enabled(b,party.leader==Players.LocalPlayer.UserId)
                end;y+=54
                local hint=UI.label(self.pageBody,'PartyModeHint','개인전은 각자 경쟁 / 협동은 같은 팀',14,UI.colors.muted);UI.box(hint,4,y,w-14,24);y+=32
            end
        end
        row('InviteRoblox','친구 초대 +',function()self:invite()end,true)
        row('Clan',Players.LocalPlayer:GetAttribute('CommanderClan')and string.format('내 클랜 [%s]',Players.LocalPlayer:GetAttribute('CommanderClan'))or '클랜, 출석, 클랜전',function()self.unitView=nil;self:openPage('clan')end)
        self:loadFriends()
        local here={};for _,pl in ipairs(Players:GetPlayers())do here[pl.UserId]=true end
        local playing,online={},{}
        for _,f in ipairs(self.onlineFriends or {})do
            if not here[f.VisitorId]then
                Localization.addName(f.DisplayName or f.UserName)
                if f.PlaceId==game.PlaceId and type(f.GameId)=='string'and f.GameId~=''then table.insert(playing,f)elseif #online<8 then table.insert(online,f)end
            end
        end
        local function header(text)local l=UI.label(self.pageBody,'Header'..y,text,13,UI.colors.muted);UI.box(l,4,y,w-14,24);y+=28 end
        if #playing>0 then header('플레이 중인 친구');for _,f in ipairs(playing)do face(row('Follow'..f.VisitorId,(f.DisplayName or f.UserName)..' / 같이 하기',function()self:follow(f)end,true),f.VisitorId,UI.colors.accent)end end
        if #online>0 then header('온라인 친구');for _,f in ipairs(online)do face(row('InviteFriend'..f.VisitorId,(f.DisplayName or f.UserName)..' / 초대',function()self:invite(f.VisitorId)end),f.VisitorId,UI.colors.good)end end
        if self.onlineFriends and #playing+#online==0 then header('접속한 친구 없음 / 초대해 보세요')end
        local s=self.data
        if s then
            if #s.invites>0 then header('받은 초대')end
            for _,invite in ipairs(s.invites)do local b=row('Accept'..invite.from,invite.name..' / 초대 수락',function()self:request('accept',invite.from)end,true);b.Size=UDim2.fromOffset(w-10-96,46)
                face(b,invite.from,UI.colors.gold)
                local no=UI.button(self.pageBody,'Decline'..invite.from,'거절',function()self:request('decline',invite.from)end);UI.box(no,w-8-88,y-54,88,46)
                no.TextColor3=UI.colors.danger;UI.stroke(no,UI.colors.danger,1).Transparency=.3
            end
            local me=Players.LocalPlayer.UserId;local leader=s.party.leader==me and #s.party.users>1
            local status={away='다른 서버',loading='불러오는 중',results='결과 화면',match='경기 중',queued='대기 중',ready='준비',hq='로비'}
            if #s.party.users>1 then header(string.format('파티 %d/5',#s.party.users))end
            for _,id in ipairs(s.party.users)do local player=Players:GetPlayerByUserId(id);local st=s.partyStatus and s.partyStatus[tostring(id)]
                local text=(s.party.leader==id and '★ 'or '')..(player and player.DisplayName or '지휘관')..(s.party.leader==id and ' / 방장'or require(script.Parent.Parent.Core.PartyFormation).isReady(s.party,id)and ' / 준비 완료'or ' / 준비 중')..(st and st~='hq'and st~='ready'and ' / '..status[st]or '')
                local l=UI.label(self.pageBody,'Member'..id,text,14);UI.box(l,12,y,w-26-(leader and id~=me and 92 or 0),40)
                if player then local B=require(script.Parent.BenefitBadge);local badge=B.create(self.pageBody,16);B.update(badge,player:GetAttribute('CommanderPermanent')==true,player:GetAttribute('CommanderVIP')==true)
                    local bw=B.width(badge);if bw>0 then local right=w-14-(leader and id~=me and 92 or 0);UI.box(badge.root,right-bw,y+12,bw,16);l.Size=UDim2.fromOffset(right-bw-18,40)end end
                if leader and id~=me then local kick=UI.button(self.pageBody,'Kick'..id,'내보내기',function()self:request('kick',id)end);UI.box(kick,w-8-88,y+3,88,34);kick.TextSize=12 end
                y+=44
            end
            if #s.party.users>1 then row('Ready','준비 상태 바꾸기',function()self:request('ready')end);row('LeaveParty','파티 나가기',function()self:request('leaveParty')end)end
            local sent={};for _,to in ipairs(s.sent or {})do sent[to]=true end
            local listed=false
            for _,player in ipairs(s.players)do if player.userId~=me and not table.find(s.party.users,player.userId)then
                if not listed then listed=true;header('이 서버의 지휘관')end
                local b=row('Invite'..player.userId,player.name..(sent[player.userId]and ' / 초대 보냄'or player.busy and ' / 경기 중'or ' / 파티 초대'),function()self:request('invite',player.userId)end)
                face(b,player.userId,player.busy and UI.colors.gold or UI.colors.good)
                if sent[player.userId]or player.busy then UI.enabled(b,false)end
            end end
        end
        self.pageBody.CanvasSize=UDim2.fromOffset(0,y)
    else
        if table.find({'supply','benefits','presets'},self.page)then require(script.Parent.CommercePages).draw(self,self.pageBody,w-6);return end
        self.pageTitle.Text=({wardrobe='스킨',missions='목표',records='전적'})[self.page]or ''
        require(script.Parent.OutgamePages).draw(self,self.pageBody,w-6)
    end
    self.pageBody.CanvasPosition=scroll
    require(script.Parent.CollectionBadges).view(self)
end
function M:setScreen(menu)
    if not menu and self.inMenu==false then return end
    local gui=self.root:FindFirstAncestorOfClass('ScreenGui')
    if gui then local inset=menu and Enum.ScreenInsets.DeviceSafeInsets or Enum.ScreenInsets.CoreUISafeInsets;if gui.ScreenInsets~=inset then gui.ScreenInsets=inset end end
    local back=menu and self.inMenu==false
    self.hiddenDrawn=nil
    self.frame.Visible=menu;self.inMenu=menu;if not menu and self.page=='room'then self:closePage()end;self:layout()
    if back then self:refresh()end
end
function M:layout()
    local w,h=self.root.AbsoluteSize.X/Theme.scale,self.root.AbsoluteSize.Y/Theme.scale;if w<1 then return end
    local short=h<500;local narrow=w<600;local width=math.min(short and 340 or 360,w-24);local x=w-width-12
    self.topbarLeft,self.topbarRight,self.topbarHeight=12,12,0
    pcall(function()
        local service=game:GetService('GuiService');local device=service:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets);local bar=service:GetInsetArea(Enum.ScreenInsets.TopbarSafeInsets)
        self.topbarLeft=math.max(12,(bar.Min.X-device.Min.X)/Theme.scale+8)
        self.topbarRight=math.max(12,(device.Max.X-bar.Max.X)/Theme.scale+8)
        self.topbarHeight=math.max(0,(bar.Max.Y-device.Min.Y)/Theme.scale)
    end)
    local ph=short and 158 or 232;local y=math.max(56,h-68-ph)
    UI.box(self.header,12,8,short and 166 or 200,44);UI.box(self.brandTop,12,4,180,12);UI.box(self.brand,12,14,180,28);self.brand.TextSize=short and 21 or 24;self.brandTop.TextSize=short and 10 or 11
    self.tag.Visible=false
    UI.box(self.profile,w-260,8,146,44);UI.box(self.avatar,4,3,36,36);UI.box(self.level,48,3,92,18);UI.box(self.medals,48,22,92,16)
    self.profile.Visible=w>430;UI.box(self.settingsButton,w-116,8,60,44);UI.box(self.help,w-52,8,44,44)
    self.panel.Visible=self.expanded;UI.box(self.panel,x,y,width,ph)
    self.heading.Visible=false;self.collapse.Visible=false
    local my=8;local mh=short and 44 or 76;local cw=(width-32)/3
    for i,mode in ipairs(modes)do local c=self.cards[mode];UI.box(c.button,10+(i-1)*(cw+6),my,cw,mh)
        c.art.Visible=not short;UI.box(c.art,8,0,cw-16,52);UI.box(c.name,2,short and 0 or 50,cw-4,short and 44 or 22);c.name.TextSize=short and 13 or 14
    end
    local hy=my+mh+(short and 4 or 8);local hh=short and 50 or 80;UI.box(self.hero,10,hy,width-20,hh)
    UI.box(self.picture,6,6,short and 72 or 110,hh-12);UI.box(self.art,0,0,short and 78 or 118,hh)
    local tx=short and 86 or 124;local isSingle=self.selectedMode=='single';local q=self.data and self.data.queue
    if q then tx=16 end
    UI.box(self.mapTitle,tx,short and 2 or 6,width-tx-(isSingle and 82 or 36),short and 22 or 28);self.mapTitle.TextSize=short and 14 or 16
    UI.box(self.modeHint,tx,short and 25 or 39,width-tx-36,short and 20 or 24);self.modeHint.TextSize=short and 11 or 13
    UI.box(self.ruleButton,width-84,short and 3 or 8,54,44);self.ruleButton.TextSize=12
    UI.box(self.reward,tx,78,math.min(100,width-tx-34),24);self.reward.Visible=false
    local py=hy+hh+(short and 4 or 8);local cw2=self.firstLesson and 90 or 52
    UI.box(self.play,10,py,width-(self.cancel.Visible and cw2+28 or 20),44);self.play.TextSize=16;UI.box(self.cancel,width-cw2-10,py,cw2,44)
    UI.box(self.status,12,py+48,width-24,22);self.status.Visible=false
    self.quick.Visible=not self.expanded;UI.box(self.quick,w-140,60,128,48)
    local nw=math.min(width,396);UI.box(self.nav,x,h-58,nw,50)
    for i,key in ipairs({'play','wardrobe','shop','clan','missions','records','preferences'})do local b=self.navButtons[key];UI.box(b,4+(i-1)*(nw-8)/7,3,(nw-22)/7,44);b.TextSize=12;b.BackgroundColor3=(self.page==key or not self.page and key=='play')and UI.colors.accent or UI.colors.panel end
    UI.box(self.friends,12,62,short and 104 or 120,44)
    self.mission.Visible=not short and w>650;UI.box(self.mission,12,118,176,62);UI.box(self.goalTitle,12,7,152,24);self.goalTitle.TextSize=14;UI.box(self.goalSub,12,33,152,22);self.goalSub.TextSize=12
    self.copyright.Visible=true;UI.box(self.copyright,6,h-40,216,38)
    self.friends.Visible=not(narrow and short)
    if narrow and not short then self.mission.Visible=false;self.friends.Position=UDim2.fromOffset(12,56);y=108;self.panel.Position=UDim2.fromOffset(x,y)end
    local fp=self.friends.Position;UI.box(self.motions,fp.X.Offset+self.friends.Size.X.Offset+8,fp.Y.Offset,72,44);self.motions.Visible=self.friends.Visible
    UI.box(self.practice,(w-math.min(330,w-24))/2,64,math.min(330,w-24),44)
    local pw=math.min(740,w-24)
    local pageHeight=self.page=='ranked'and 650 or self.page=='solo'and (require(script.Parent.Parent.Core.CommandPresentation).lesson(self)and (short and 300 or 340)or 640)or self.page=='joinCode'and 250 or self.page=='motions'and 500 or self.page=='custom'and ((self.customStep or 1)==1 and 360 or (self.customStep or 1)==3 and 480 or 650)or 650
    local lifted=short and w>=600 and self.page~='motions'
    local ph2=math.min(pageHeight,h-(lifted and (self.page=='missions'and 20 or 52)or self.page=='missions'and short and 76 or 108));self.pageCard.BackgroundTransparency=.04
    local pageX,pageY=(w-pw)/2,lifted and math.max(8,math.floor((h-44-ph2)/2))or math.max(64,(h-ph2)/2)
    local titleX=pageY+8<self.topbarHeight and math.max(18,self.topbarLeft-pageX)or 18
    UI.box(self.pageCard,pageX,pageY,pw,ph2);UI.box(self.pageTitle,titleX,8,pw-titleX-66,42);UI.box(self.pageClose,pw-58,5,48,48)
    local footer=self.page=='solo'or table.find({'custom','customRules','room','joinCode','customCode'},self.page)~=nil
    local secondary=self.page=='room'or self.page=='customRules'or self.page=='customCode'or self.page=='custom'and (self.customStep or 1)>1 or self.page=='solo'and self.data and self.data.queue~=nil
    self.soloStart.Visible=footer;self.pageSecondary.Visible=secondary;UI.box(self.pageSecondary,16,ph2-58,132,48);UI.box(self.soloStart,secondary and 156 or 16,ph2-58,pw-(secondary and 172 or 32),48)
    if self.page=='solo'then
        local c=require(script.Parent.Parent.Core.CommandPresentation);local entry=require(script.Parent.Parent.Core.OnboardingPresentation).account(self.account)
        local shop=self.callbacks.shop();local restoring=shop and shop.busy
        local decision=require(pack.Core.PlayFlow).single(self.data and self.data.queue)
        self.soloStart.Text=restoring and '다시 연결하는 중…'or entry=='failed'and '다시 연결'or entry=='loading'and '설정을 불러오는 중…'or decision=='moving'and '전장으로 이동 중…'or decision=='replace'and '대기 취소 후 시작'or c.lesson(self)and '첫 작전 시작'or require(script.Parent.DeploymentSetup).startLabel(self)
        self.pageSecondary.Text='계속 대기'
        UI.enabled(self.soloStart,decision~='moving'and entry~='loading'and not restoring and not self.busy and not self.loading)
    end
    local compactRoom=short and self.page=='room'
    local goals=false;self.pageTabs.Visible=false
    self.goalStart.Visible=goals
    if goals then
        local meta=Maps.meta(self.map)or Maps.catalog[1];local cfg=require(pack.Core.SoloChallenge).goal(meta,self.settings.difficulty)
        self.goalRules.Text=meta.label..' / '..string.format('%s, AI %d',require(pack.Core.MatchOptions).difficultyLabels[cfg.difficulty],cfg.nations)
        UI.box(self.goalStart,24,ph2-(short and 62 or 68),pw-48,short and 48 or 52)
        UI.box(self.goalAction,8,short and 0 or 2,pw-64,short and 24 or 28);self.goalAction.TextSize=short and 15 or 17
        UI.box(self.goalRules,8,short and 24 or 29,pw-64,short and 18 or 19)
        local decision=require(pack.Core.PlayFlow).single(self.data and self.data.queue)
        UI.enabled(self.goalStart,self.settings.difficulty~=nil and decision~='moving'and self.account.ready==true and not self.callbacks.shop().busy and not self.busy and not self.loading)
    end
    local side=PageLayout.inset(self.page);UI.box(self.pageTabs,14+side,goals and short and 52 or 62,pw-28-side*2-PageLayout.scrollbar,48)
    UI.box(self.pageBody,14,(goals and short and 52 or compactRoom and 56 or 62)+(goals and PageLayout.goalTabs or 0),pw-28,ph2-(goals and (short and 124 or 142)or compactRoom and 120 or footer and 132 or 74)-(goals and PageLayout.goalTabs or 0))
    if self.page and self.pageWidth~=pw then self.pageWidth=pw;task.defer(function()if self.page then self:drawPage()end end)end
    if self.deployment then
        self.panel.Visible=false;self.quick.Visible=false
        self.deployment.inMenu=self.inMenu~=false;self.deployment.suppressed=self.page~=nil;self.deployment.topbarLeft=self.topbarLeft;self.deployment:layout(w,h)
        local open=self.deployment.expanded and not self.page
        self.deploymentFocus.Visible=self.inMenu~=false and open
        self.deployment.frame.Visible=self.inMenu~=false and open
        self.nav.Visible=not(short and open)
        if self.data and self.data.queue then self.nav.Position=UDim2.fromOffset(x,h-112-math.max(0,(self.deployment.barHeight or 48)-48))end
        self.header.Visible=not(short and open);self.profile.Visible=self.profile.Visible and not(short and open);self.settingsButton.Visible=not(short and open);self.help.Visible=not(short and open)
        self.friends.Visible=self.friends.Visible and not open;self.motions.Visible=self.friends.Visible;self.mission.Visible=self.mission.Visible and not open
        self.copyright.Visible=not open
    end
    if self.home then self.home:layout(w,h)end
end
return M
