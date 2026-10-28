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
local Pending=require(script.Parent.PressPending)
local Veil=require(script.Parent.TransitionVeil)
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
    self.brandTop=UI.label(self.header,'BrandTop','SUPER',10,Color3.fromRGB(255,216,74));self.brand.TextColor3=Color3.new(1,1,1)
    for _,l in ipairs({self.brand,self.brandTop})do Theme.display(l);require(script.Parent.BrandMark).word(l,l==self.brand and 2.5 or 1.5);l:SetAttribute('LocalizationSkip',true)end
    self.profile=UI.button(f,'Profile','',function()self:openPage('records')end)
    self.avatar=UI.corner(UI.make('ImageLabel',self.profile,{Name='Avatar',Image='rbxthumb://type=AvatarHeadShot&id='..Players.LocalPlayer.UserId..'&w=150&h=150',BackgroundColor3=UI.colors.yellow,BorderSizePixel=0}),14)
    self.level=UI.label(self.profile,'Level','Lv. 1',14);self.medals=UI.label(self.profile,'Medals','코인 0',12,UI.colors.gold)
    for _,l in ipairs({self.level,self.medals})do l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd end
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
        matchRoom=function()if self.matchRoom then self.matchRoom:restore()end end,
    })
    self.matchRoom=require(script.Parent.MatchRoom).new(root,{
        ready=function(on)self:request('fieldReady',{ready=on})end,
        leave=function()self:request('cancel')end,
        insets=function()return {left=self.topbarLeft or 12,right=self.topbarRight or 12,top=self.topbarHeight or 0}end,
        shown=function(on)self:roomCover(on)end,
    })
    self.home=require(script.Parent.LobbyHome).new(self)
    self.card=require(script.Parent.CommanderCard).new(self)
    pack:WaitForChild('LobbyState').OnClientEvent:Connect(function(s)
        if M.stale(s,self.data)then return end
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
    task.spawn(function()local ok,r=pcall(function()return pack.LobbyRequest:InvokeServer('read')end);if ok and r.state and not M.stale(r.state,self.data)then self.data=r.state;self:refresh()end end)
    local elapsed=0
    self.queueClock=game:GetService('RunService').Heartbeat:Connect(function(dt)
        if not self.frame.Parent then self.queueClock:Disconnect();return end
        self.rewardArrival:step(self.frame.Visible and not self.page and not require(script.Parent.LobbyIntro).active and self.profile.Visible,self.account.preferences and self.account.preferences.reducedEffects)
        elapsed+=dt;if self.inMenu==false then if elapsed>=.25 then elapsed=0;if self.data and self.data.queue then self:practiceBadge()end end elseif elapsed>=.25 then elapsed=0;if self.data and self.data.queue then self:refresh()elseif self.deployment and self.deployment.expanded and not self.page then self.deployment:render()end end
    end)
    pcall(function()local c;c=game:GetService('GuiService'):GetPropertyChangedSignal('TopbarInset'):Connect(function()if not self.frame.Parent then c:Disconnect()elseif self.frame.Visible then self:layout()end end)end)
    self:refresh();return self
end
function M:showCheckIn(info,login)
    local Audio=require(script.Parent.ToyAudio);local Tween=game:GetService('TweenService')
    local unlocks={};for _,id in ipairs(info.unlocked or {})do for _,a in ipairs(Rules.achievementList)do if a.id==id then table.insert(unlocks,a)end end end
    local K=require(script.Parent.Kit20)
    local rw=self.root.AbsoluteSize.X/Theme.scale;local w=K.even(math.min(320,rw-24))
    local n=#Rules.streakRewards;local at=info.rewardStep or (info.streak-1)%n+1
    local nextReward=login and login.nextReward or Rules.streakRewards[at%n+1]
    local Lobby20=require(script.Parent.Lobby20)
    local card,tap
    if Lobby20.ENABLED then card,tap=self:checkIn20(info,unlocks,at,nextReward,w,Lobby20)else
        card=UI.button(self.root,'CheckInCelebration','',function()end);card.ZIndex=45;card.AutoButtonColor=false;card.BackgroundColor3=UI.colors.panel;tap=card
        local extra={};for _,a in ipairs(unlocks)do table.insert(extra,string.format('업적 달성 %s  +%d 코인',a.name,a.medals))end
        K.boxCentre(card,math.floor((rw-w)/2),70,w,128+22*math.min(2,#extra))
        for i=1,math.min(2,#extra)do local l=UI.label(card,'Unlock'..i,extra[i],13,UI.colors.gold);UI.box(l,16,118+(i-1)*22,w-32,20);l.TextXAlignment=Enum.TextXAlignment.Center;l.ZIndex=46 end
        local title=UI.label(card,'Title',string.format('누적 출석 %d일',info.claims or info.streak),22);UI.box(title,16,8,w-32,34);title.TextXAlignment=Enum.TextXAlignment.Center;title.ZIndex=46
        local reward=UI.label(card,'Reward',string.format('+%d 코인',info.medals),18,UI.colors.gold);UI.box(reward,16,42,w-32,28);reward.TextXAlignment=Enum.TextXAlignment.Center;reward.ZIndex=46
        local dw=math.floor((w-32-(n-1)*4)/n)
        local dx=16+math.floor((w-32-(n*dw+(n-1)*4))/2)
        for i=1,n do local d=UI.make('Frame',card,{Name='Day'..i,BackgroundColor3=i<=at and UI.colors.accent or UI.colors.raised,BorderSizePixel=0,ZIndex=46});UI.box(d,dx+(i-1)*(dw+4),78,dw,10);UI.corner(d,5)end
        local nextLine=UI.label(card,'Next',string.format('다음 접속 +%d 코인',nextReward),14,UI.colors.muted);UI.box(nextLine,16,94,w-32,24);nextLine.TextXAlignment=Enum.TextXAlignment.Center;nextLine.ZIndex=46
    end
    card.Visible=false;K.appear(card,{scaleFrom=.96,t=.16})
    Audio.play('milestone');require(script.Parent.TelemetryStep).step('lobby','checkInCard',{value=info.medals,count=info.claims or info.streak,item='step'..tostring(at),result='shown'})
    local closed;local function close(how)
        if not card.Parent or closed then return end
        closed=true;require(script.Parent.TelemetryStep).step('lobby','checkInClose',{reason=how=='auto'and 'auto'or 'manual'})
        K.leave(card,{t=.10},function()card:Destroy()end)
        local s=card:FindFirstChild('Pop20');if s and not K.reduced then Tween:Create(s,TweenInfo.new(.10,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=.96}):Play()end
    end
    tap.Activated:Connect(function()close('manual')end);task.delay(5,close,'auto')
end
function M:checkIn20(info,unlocks,at,nextReward,w,Lobby20)
    local K=require(script.Parent.Kit20);local C=K.colors;local Loc=require(script.Parent.Localization)
    local sc=Theme.scale or 1;local rw,rh=self.root.AbsoluteSize.X/sc,self.root.AbsoluteSize.Y/sc
    local fmt=Lobby20.format(rw,rh);local top=fmt=='pt'and 110 or Lobby20.insets(rw,rh)+12
    local k=math.min(2,#unlocks);local h=126+22*k
    local card=K.panel(self.root,'CheckInCelebration','glass',12);card.ZIndex=45;card.Active=true;card.BackgroundTransparency=.04
    K.boxCentre(card,math.floor((rw-w)/2),top,w,h)
    local function measure(text,size,label)local ok,t=pcall(Loc.text,text);return K.width(ok and type(t)=='string'and t or text,size,label)end
    local function row(name,y,rh2,parts)
        local holder=K.make('Frame',card,{Name=name,BackgroundTransparency=1,BorderSizePixel=0});local x=0
        for i,p in ipairs(parts)do
            if i>1 then x+=p.gap or 6 end
            if p.icon then local ic=K.icon(holder,p.icon,p.size,p.color,'Icon'..i);K.box(ic,x,math.floor((rh2-p.size)/2),p.size,p.size);x+=p.size
            elseif p.coin then local f,aw=K.amount(holder,'Amount'..i,'coin',p.coin,p.size,p.color);f.Position=UDim2.fromOffset(x,math.floor((rh2-p.size)/2));x+=aw
            else local l=K.text(holder,'Text'..i,p.text,p.size,p.color,p.weight or 700);local tw=measure(p.text,p.size,l);K.box(l,x,0,tw,rh2);x+=tw end
        end
        K.box(holder,math.floor((w-x)/2),y,x,rh2);return holder
    end
    local title=K.text(card,'Title',string.format('출석 %d일',info.claims or info.streak),22,C.ink,800,Enum.TextXAlignment.Center);K.box(title,16,12,w-32,28)
    row('Reward',42,24,{{coin='+'..tostring(info.medals),size=22,color=C.gold}})
    local n=#Rules.streakRewards;local gap=4;local dw=math.floor((w-32-(n-1)*gap)/n)
    local dx=16+math.floor((w-32-(n*dw+(n-1)*gap))/2)
    for i=1,n do local d=K.make('Frame',card,{Name='Day'..i,BackgroundColor3=i<=at and C.accent or C.raised,BorderSizePixel=0});K.round(d,'pill');K.box(d,dx+(i-1)*(dw+gap),76,dw,8)end
    row('Next',94,18,{{text='다음',size=14,color=C.muted},{coin='+'..tostring(nextReward),size=14,color=C.muted}})
    for i=1,k do local a=unlocks[i]
        row('Unlock'..i,120+(i-1)*22,20,{{icon='medal',size=14,color=C.gold},{text=a.name,size=13,color=C.gold,weight=800,gap=5},{coin='+'..tostring(a.medals),size=13,color=C.gold}})
    end
    for _,o in ipairs(card:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=46 end end
    local tap=K.make('TextButton',card,{Name='Tap',Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=47})
    return card,tap
end
function M:celebrate(before,p,checkIn,recruited)
    local holdCheckIn=checkIn and p and require(pack.Core.ComebackRules).holdCheckIn(p)
    if checkIn and not holdCheckIn and self.checkInShown~=(checkIn.claims or checkIn.streak)then self.checkInShown=checkIn.claims or checkIn.streak;task.spawn(function()
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
    require(script.Parent.ComebackCard).watch(self,before,p)
    local function say(text,kind)self.notify(text,false,nil,true);if kind then require(script.Parent.TelemetryStep).step('lobby','toast',{item=kind,result='shown'})end end
    if recruited and recruited.at~=self.recruitSeen then self.recruitSeen=recruited.at;say(string.format('초대한 친구 %d명  +%d 코인',recruited.count,recruited.medals),'recruit')end
    local career=p and p.career
    if career and career.recruitPending and not self.recruitHinted then self.recruitHinted=true;say(string.format('친구 초대 보상  첫 판 +%d 코인',career.recruitMedals or 0),'recruitWelcome')end
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
function M.stale(s,cur)return type(s)=='table'and type(cur)=='table'and type(s.serial)=='number'and type(cur.serial)=='number'and s.serial<cur.serial end
function M:request(action,value,after,handle)
    if self.busy then Veil.hide();return end
    self.requests=self.requests or Requests.new(12)
    local operation=self.requests:begin(os.clock());if not operation then Veil.hide();return end
    if action=='play'or action=='again'then Veil.show('전장 준비 중…')end
    local pend=Pending.begin()
    self.busy=true;self:refresh()
    task.delay(12,function()
        if self.requests:expire(operation,os.clock())then
            Pending.finish(pend);self.busy=false;self:refresh();require(script.Parent.TelemetryStep).step('lobby','requestFailed',{item=type(action)=='string'and action or nil,reason='timeout'});self.notify('응답 지연 / 연결 확인 후 다시 시도',true)
        end
    end)
    task.spawn(function()
        local delay=.3-(os.clock()-(self.lastRequestSent or -math.huge));if delay>0 then task.wait(delay)end
        self.lastRequestSent=os.clock()
        local ok,r=pcall(function()return pack.LobbyRequest:InvokeServer(action,value)end)
        if not self.requests:complete(operation)then return end
        Pending.finish(pend);self.busy=false
        if not ok or not r.ok then Veil.hide()elseif action=='play'or action=='again'then Veil.settle(3)end
        if not ok then require(script.Parent.TelemetryStep).step('lobby','requestFailed',{item=type(action)=='string'and action or nil,reason='network'});self.notify('연결 끊김 / 다시 시도',true);self:refresh();return end
        if r.state and not M.stale(r.state,self.data)then self.data=r.state;self.queueUpdated=os.clock()end
        if handle and handle(r)then self:refresh();return end
        if not r.ok then self.notify(r.message or '다시 시도',true)elseif after then after()end
        if r.ok and (action=='joinField'or action=='joinCode')and self.data.queue and self.data.queue.mode=='custom'then self:openPage('room')end
        if r.ok and r.message then self.notify(r.message)end
        self:refresh();if self.page=='friends'then self:drawPage()end
    end)
end
function M:leaveResult(toMenu)
    local s=self.data;local me=Players.LocalPlayer.UserId
    if s and(s.privateServer~=true or s.party and #s.party.users>1 and s.party.leader~=me)then toMenu();return end
    if self.busy then Veil.hide();self.notify('잠시 뒤 다시',true);return end
    require(script.Parent.TelemetryStep).step('result','lobby',{item=s and 'reserved'or 'unknown'})
    self:request('hq',nil,nil,function(r)if r.public then toMenu();return true end;if r.ok then Veil.teleport('로비로 이동 중…')end end)
end
function M:announce(q)
    local key=q and q.mode=='pvp'and q.phase=='transferring'and 'go'or nil
    local previous=self.queueKey;self.queueKey=key
    require(script.Parent.LobbyMusic).queue(key)
    if previous=='go'and key~='go'then Veil.hide()end
    if key=='go'and previous~='go'then Veil.teleport('전장으로 이동 중…')end
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
    self.level.Text='Lv. '..tostring(p.level or 1);self.medals.Text='코인 '..UI.number(p.medals or 0)..(streak>0 and '  🔥'..streak or '')
    self.hero.BackgroundColor3=UI.colors.bg;self.ruleButton.Visible=isSingle and not q
    self.picture.Visible=isSingle and not q;self.art.Visible=not isSingle and not q
    self.reward.Text=isSingle and (cfg=='single'and '기본' or '자유 설정')or mode=='coop'and '같은 팀'or '지도 랜덤'
    self.mapTitle.Text=q and ('사람 '..q.count..' / '..q.max)or isSingle and (Maps.meta(self.map)or Maps.catalog[1]).label or mode=='coop'and '함께 컴퓨터 이기기'or '실시간 세계 전쟁'
    self.modeHint.Text=q and (q.count<q.minimum and '참가하면 최대 1분 뒤 출발' or remaining==0 and '전장을 준비하는 중…'or string.format('%d초 뒤 시작 / 현재 인원 출발',remaining or 0))or isSingle and '지도 바꾸기 ›'or mode=='coop'and '1~5명 vs AI 10명'or '진행 중 전장 바로 합류'
    self.play.Text=self.loading and '준비 중…'or q and (q.mode=='pvp'and not s.practice and '연습하며 기다리기'or '참가자 모집 중…')or isSingle and '시작하기' or mode=='coop'and '함께 시작'or '플레이'
    if q and q.global then self.mapTitle.Text=string.format('전 서버 모집 / %d / %d명',q.count,q.max)end
    if q and q.phase=='recovering'then self.modeHint.Text='연결 확인 중 / 대기 유지'
    elseif q and q.needsOpponent then self.modeHint.Text='양 진영 자리 나면 출발'
    elseif q and q.phase=='next'then self.modeHint.Text='다음 전장 함께 출발'
    elseif connecting then self.modeHint.Text='같은 전장으로 이동 중…';self.play.Text='입장 중…'end
    if party and #party.users>1 and party.leader~=Players.LocalPlayer.UserId and not q then self.play.Text=require(script.Parent.Parent.Core.PartyFormation).isReady(party,Players.LocalPlayer.UserId)and '준비 완료'or '준비'end
    if self.firstLesson then self.play.Text='첫 작전 →'end
    UI.enabled(self.play,(not q or q.mode=='pvp'and not s.practice and not connecting)and not self.busy and not self.loading);self.cancel.Visible=q~=nil or self.firstLesson;self.cancel.Text=q and '취소'or '바로 시작';self.cancel.TextSize=12
    UI.enabled(self.cancel,not self.busy and not(q and q.locked))
    self.status.Text=q and (q.count<q.minimum and '15초 뒤 연습하며 대기 가능'or '취소 불이익 없음')or isSingle and (cfg=='single'and '기본 싱글 / 보상 75%'or '자유 설정 / 반복 보상 없음')or mode=='coop'and '승패 모두 기록'or '중간 참가 무료 / 이탈 불이익 없음'
    if party and #party.users>1 and not q then self.status.Text='친구와 함께 XP +10%'end
    if self.firstLesson then self.status.Text='첫 작전 튜토리얼 / 점령과 병력 기초'end
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
    if self.matchRoom then local prefs=self.account.preferences or {};local since=os.clock()-(self.queueUpdated or os.clock())
        self.matchRoom:update(q,{menu=self.inMenu~=false,page=self.page,practice=s and s.practice,remaining=q and q.remaining and q.remaining-since,elapsed=since,busy=self.busy,reduced=prefs.reducedEffects})end
    if self.deployment then local prefs=self.account.preferences or {};self.deployment:update(s and s.battlefields,q,{menu=self.inMenu~=false,practice=s and s.practice,reduced=prefs.reducedEffects,busy=self.busy,party=party,userId=Players.LocalPlayer.UserId,live=s and s.live,recent='최근 / '..(Maps.meta(self.map)or Maps.catalog[1]).label..' / '..({Easy='쉬움',Medium='보통',Hard='어려움',Impossible='불가능'})[self.settings.difficulty or 'Medium']})end
    if self.teamRoster and self.teamRoster.frame.Visible then
        local field=q and q.field==self.teamRoster.id and q or nil
        if not field then for _,candidate in ipairs(s and s.battlefields and s.battlefields.fields or {})do if candidate.id==self.teamRoster.id then field=candidate;break end end end
        self.teamRoster:update(field)
    end
    if self.page=='room'then
        local signature=game.HttpService:JSONEncode(q and {q.field,q.revision,q.members,q.phase}or {})
        if signature~=self.roomSignature then self.roomSignature=signature;self:drawPage()end
        require(script.Parent.CustomDeployment).footer(self)
    end
    if table.find({'custom','customRules','joinCode','customCode'},self.page)then require(script.Parent.CustomDeployment).footer(self)end
    if self.home then self.home:refresh()end
    self:layout()
end
local subPages={joinCode=true,customCode=true,customRules=true,maps=true,benefits=true,confirm=true}
function M:openPage(page)
    local from=self.page
    if not subPages[page]then self.backTo=nil elseif from and from~=page and (from=='custom'or from=='solo')then self.backTo=from end
    if page=='missions'then if not self.goalTab then self.goalTab=require(script.Parent.GoalsScreen).defaultTab(self)end;self.goalsOpen=nil end
    local screen=page=='missions'and self.goalTab=='campaign'and 'campaign'or ({solo='single',missions='goals',preferences='settings',joinCode='custom',customCode='custom',customRules='custom',maps='deployment',watch='spectate',motions='motion',confirm='menu'})[page]or page
    require(script.Parent.TelemetryClient).emit('screen_viewed',{screen=screen,result='shown'});if page=='missions'then self.goalScreen=screen end
    if page=='solo'then self:refresh()end
    self.page=page;self.overlay.Visible=true;self.pageBody.CanvasPosition=Vector2.zero;self.goalsScrollTab=nil;self:layout();self:drawPage()
end
function M:invite(target,from)
    task.spawn(function()
        local me=Players.LocalPlayer
        local ok,can=pcall(function()return Social:CanSendGameInviteAsync(me,target)end)
        if not(ok and can)then require(script.Parent.TelemetryStep).step('social','robloxInvite',{result='unavailable'});self.notify('Roblox 초대 불가',true);return end
        require(script.Parent.TelemetryStep).step('social','robloxInvite',{result='opened',item=target and 'friend'or 'any',origin=from=='result'and 'inviteResult'or 'inviteFriends'})
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
        else self:closePage()end
    elseif page=='customRules'then self:closePage()
    elseif self.backTo then
        local back=self.backTo;self.backTo=nil;self.returnPage=nil;self:openPage(back)
    else self:closePage()end
end
function M:closePage()if self.page then require(script.Parent.TelemetryClient).emit('screen_viewed',{screen='lobby',result='shown'})end;self.backTo=nil;Currency.dismiss(true);require(script.Parent.PageWallet).clear(self);if self.page=='wardrobe'then require(script.Parent.CareerWardrobe).flush(self)end
    require(script.Parent.Sheet20).closeMenu(true)
    local animated=self.home and self.inMenu~=false and self.home:leave20(self.page)
    self.page=nil;if not animated then self.overlay.Visible=false end;if self.mapBrowser then self.mapBrowser:destroy();self.mapBrowser=nil end;require(script.Parent.LiveWatchPage).release(self,false);self:layout()end
function M:drawPage()
    if not self.page then return end
    local Probe=require(script.Parent.FrameProbe);Probe.start('Lobby.drawPage');self:drawPageBody();Pending.restore();Probe.stop('Lobby.drawPage')
end
function M:drawPageBody()
    local scroll=self.pageBody.CanvasPosition
    Currency.dismiss(true);Currency.reduced=(self.account.preferences or {}).reducedEffects==true;require(script.Parent.PageWallet).clear(self)
    if self.mapBrowser then self.mapBrowser:destroy();self.mapBrowser=nil end
    require(script.Parent.LiveWatchPage).release(self,self.page=='watch')
    if self.page=='missions'then require(script.Parent.GoalsScreen).keep(self,self.pageBody)end
    for _,o in ipairs(self.pageBody:GetChildren())do o:Destroy()end
    for _,o in ipairs(self.pageTabs:GetChildren())do o:Destroy()end
    require(script.Parent.Sheet20).closeMenu(true)
    local two=require(script.Parent.LobbyHome).TWO[self.page]==true
    local side=two and 0 or PageLayout.inset(self.page)
    UI.make('UIPadding',self.pageBody,{Name='ContentInset',PaddingLeft=UDim.new(0,side),PaddingRight=UDim.new(0,side),PaddingTop=UDim.new(0,two and 0 or PageLayout.top),PaddingBottom=UDim.new(0,two and 0 or PageLayout.bottom)})
    local w=PageLayout.width(self.pageBody.Size.X.Offset,1,side)+6
    if self.page=='preferences'then require(script.Parent.LobbySettings).draw(self,self.pageBody,w-6)
    elseif self.page=='confirm'then require(script.Parent.LobbyConfirm).draw(self,self.pageBody,w-6)
    elseif self.page=='shop'then require(script.Parent.ShopLanding).draw(self,self.pageBody,w-6)
    elseif self.page=='solo'then
        require(script.Parent.DeploymentSetup).draw(self,self.pageBody,w-6)
    elseif table.find({'custom','customRules','room','joinCode','customCode'},self.page)then require(script.Parent.CustomDeployment).draw(self,self.pageBody,w-6)
    elseif self.page=='ranked'then require(script.Parent.RankedEntry).draw(self,self.pageBody,w-6)
    elseif self.page=='commander'then require(script.Parent.CommanderProfile).draw(self,self.pageBody,w-6)
    elseif self.page=='watch'then require(script.Parent.LiveWatchPage).draw(self,self.pageBody,w-6)
    elseif self.page=='maps'then
        self.pageTitle.Text='지도 선택'
        local browser=require(script.Parent.MapBrowser).new(self.pageBody,function(key)local back=self.returnPage;self.returnPage=nil;require(script.Parent.TelemetryStep).step('map_ui','mapPick',{map_key=key,item=back or 'solo'});if back=='custom'and self.customDraft then self.customDraft.map=key else self.map=key;self.touchedMap=true;self.callbacks.map(key)end;if back then self:openPage(back)else self:closePage()end;self:refresh()end,UI,self)
        self.mapBrowser=browser
        browser.selected=self.returnPage=='custom'and self.customDraft and self.customDraft.map or self.map;browser:refreshSelection();browser.onLayout=function()self.pageBody.CanvasSize=UDim2.fromOffset(0,browser.height or 0)end
        self.pageBody.CanvasSize=UDim2.fromOffset(0,browser:layout(w-6,self.root.AbsoluteSize.Y/Theme.scale<500))
    elseif self.page=='motions'then require(script.Parent.MotionsPage).draw(self,self.pageBody,w-6)
    elseif self.page=='clan'then require(script.Parent.ClanPage).draw(self,self.pageBody,w-6)
    elseif self.page=='friends'then
        require(script.Parent.Party20).draw(self,self.pageBody)
    else
        if table.find({'supply','benefits'},self.page)then require(script.Parent.CommercePages).draw(self,self.pageBody,w-6);return end
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
    self.frame.Visible=menu and not self.roomCovered;self.inMenu=menu;if not menu and self.page=='room'then self:closePage()end
    if not menu and self.matchRoom then self.matchRoom:show(false)end
    self:layout()
    if back then self:refresh()end
end
function M:roomCover(on)
    on=on==true;self.roomCovered=on
    local token=(self.roomCoverToken or 0)+1;self.roomCoverToken=token
    if on then
        task.delay(.12,function()if self.roomCoverToken==token and self.roomCovered then self.frame.Visible=false end end)
    else
        if require(script.Parent.LobbyIntro).active then return end
        local shown=self.inMenu~=false;if self.frame.Visible~=shown then self.frame.Visible=shown;if shown then self:layout()end end
    end
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
    UI.box(self.header,12,8,short and 166 or 200,44);UI.box(self.brandTop,12,4,180,12);UI.box(self.brand,12,14,180,28);self.brand.TextSize=short and 21 or 24;self.brandTop.TextSize=short and 12 or 13
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
    local bar=q and (self.deployment and self.deployment.barHeight or 48)+8 or 0
    local bottom=math.max(44,narrow and 64+bar or bar>0 and bar+8 or 0)
    local ph2=math.min(pageHeight,h-(lifted and (self.page=='missions'and 20 or 8+bottom)or self.page=='missions'and short and 76 or 64+bottom));self.pageCard.BackgroundTransparency=.04
    local pageX,pageY=(w-pw)/2,lifted and math.max(8,math.floor((h-bottom-ph2)/2))or math.max(64,math.min((h-ph2)/2,h-bottom-ph2))
    local titleX=pageY+8<self.topbarHeight and math.max(18,self.topbarLeft-pageX)or 18
    local two=self.page and require(script.Parent.LobbyHome).TWO[self.page]
    if not two and not(self.page==nil and self.overlay.Visible)then UI.box(self.pageCard,pageX,pageY,pw,ph2)end
    UI.box(self.pageTitle,titleX,8,pw-titleX-66,42);UI.box(self.pageClose,pw-58,5,48,48)
    local footer=self.page=='solo'
    local secondary=self.page=='solo'and self.data and self.data.queue~=nil
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
    if not two then UI.box(self.pageBody,14,(goals and short and 52 or compactRoom and 56 or 62)+(goals and PageLayout.goalTabs or 0),pw-28,ph2-(goals and (short and 124 or 142)or compactRoom and 120 or footer and 132 or 74)-(goals and PageLayout.goalTabs or 0))end
    if self.page and not two and self.pageWidth~=pw then self.pageWidth=pw;task.defer(function()if self.page then self:drawPage()end end)end
    if self.deployment then
        self.panel.Visible=false;self.quick.Visible=false
        self.deployment.inMenu=self.inMenu~=false;self.deployment.suppressed=self.page~=nil;self.deployment.topbarLeft=self.topbarLeft;self.deployment:layout(w,h)
        local open=self.deployment.expanded and not self.page
        self.deploymentFocus.Visible=false
        self.nav.Visible=not(short and open)
        if self.data and self.data.queue then self.nav.Position=UDim2.fromOffset(x,h-112-math.max(0,(self.deployment.barHeight or 48)-48))end
        self.header.Visible=not(short and open);self.profile.Visible=self.profile.Visible and not(short and open);self.settingsButton.Visible=not(short and open);self.help.Visible=not(short and open)
        self.friends.Visible=self.friends.Visible and not open;self.motions.Visible=self.friends.Visible;self.mission.Visible=self.mission.Visible and not open
        self.copyright.Visible=not open
    end
    if self.home then self.home:layout(w,h)end
end
return M
