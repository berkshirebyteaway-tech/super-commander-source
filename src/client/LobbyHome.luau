local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Tween=game:GetService('TweenService')
local UI=require(script.Parent.ToyUI)
local Theme=require(script.Parent.Theme)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Party=require(script.Parent.Parent.Core.PartyFormation)
local Commands=require(script.Parent.Parent.Core.CommandPresentation)
local Icons=require(script.Parent.OutgameIcons)
local RedDot=require(script.Parent.RedDot)
local Badge=require(script.Parent.BenefitBadge)
local BrandMark=require(script.Parent.BrandMark)
local Daily=require(script.Parent.Parent.Core.DailyOperation)
local TextService=game:GetService('TextService')
local FreeDraw=require(script.Parent.FreeDraw)
local Localization=require(script.Parent.Localization)
local M={};M.__index=M
M.modes={
    {id='quick',name='빠른 출전',hint='가장 빠른 공식전 / AI 충원'},
    {id='fields',name='전장 고르기',hint='공식, 커스텀 전장 선택'},
    {id='campaign',name='캠페인',hint='쉬움부터 불지옥까지 30작전',icon='campaign'},
    {id='solo',name='혼자 하기',hint='AI 상대 / 자유 설정'},
    {id='daily',name='오늘의 도전',hint='같은 지도 / 오늘의 순위'},
    {id='custom',name='커스텀 방',hint='친구와 내 규칙으로'},
    {id='ranked',name='랭크',hint='1대1, 2대2, 개인전'},
    {id='watch',name='경기 관전',hint='진행 중 공식전 관전'},
}
local tabIcons={play='deploy',wardrobe='wardrobe',shop='reward',clan='clan',missions='missions',records='records',preferences='settings'}
local difficulty={Easy='쉬움',Medium='보통',Hard='어려움',Impossible='불가능'}
local function clock(n)local s=math.max(0,math.ceil(n or 0));return string.format('%02d:%02d',s//60,s%60)end
local function shade(parent,name,rotation,alpha)
    local f=UI.make('Frame',parent,{Name=name,BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=0,Active=false})
    UI.make('UIGradient',f,{Rotation=rotation,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,alpha),NumberSequenceKeypoint.new(1,1)})})
    return require(script.Parent.FullBleed).edge(f)
end
local function glass(o,alpha)
    o.BackgroundColor3=UI.colors.bg;o.BackgroundTransparency=alpha or .3
    local s=o:FindFirstChildOfClass('UIStroke');if s then s.Color=UI.colors.line;s.Transparency=.2 end
    return o
end
local function line(parent,name,text,size,color,medium)
    local l=UI.label(parent,name,text,size,color);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd
    if medium then l.Font=Enum.Font.BuilderSansMedium end;return l
end
function M.new(lobby)
    local f=lobby.frame
    local self=setmetatable({lobby=lobby,mode='quick',listOpen=false},M)
    self.top=shade(f,'TopShade',90,.2);self.left=shade(f,'LeftShade',0,.42);self.bottom=shade(f,'BottomShade',-90,.25)
    self.start=UI.button(f,'Deploy','',function()self:go()end,true);self.start.BackgroundColor3=Color3.new(1,1,1)
    UI.make('UIGradient',self.start,{Name='Sheen',Color=ColorSequence.new(UI.colors.accent,UI.colors.accent:Lerp(UI.colors.ice,.35))})
    self.title=line(self.start,'Title','출전',30,UI.colors.bg);Theme.display(self.title)
    self.sub=line(self.start,'Sub','',14,UI.colors.bg,true)
    self.mark=line(self.start,'Mark','»',38,UI.colors.bg);self.mark.TextXAlignment=Enum.TextXAlignment.Center;Theme.display(self.mark)
    self.glow=self.start:FindFirstChildOfClass('UIStroke')
    if self.glow then self.glow.Color=UI.colors.ice;self.glow.Thickness=2
        self.pulse=Tween:Create(self.glow,TweenInfo.new(1.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=.85});self.pulse:Play()
    end
    self.quick=glass(UI.button(f,'QuickJoin','',function()self:quickJoin()end),.2)
    self.quickTitle=line(self.quick,'Title','빠른 참가',18,UI.colors.ink,true);self.quickTitle.TextXAlignment=Enum.TextXAlignment.Center
    self.quickSub=line(self.quick,'Sub','진행 중 전장',12,UI.colors.accent,true);self.quickSub.TextXAlignment=Enum.TextXAlignment.Center
    self.select=glass(UI.button(f,'ModeSelect','',function()self.listOpen=not self.listOpen;self:refresh();lobby:layout()end),.25)
    self.kicker=line(self.select,'Kicker','모드',12,UI.colors.muted)
    self.modeName=line(self.select,'Mode','',16,UI.colors.ink)
    self.modeIcon=Icons.create(self.select,'quick',18,UI.colors.accent)
    self.caret=line(self.select,'Caret','▾',16,UI.colors.accent);self.caret.TextXAlignment=Enum.TextXAlignment.Center
    self.list=glass(UI.panel(f,'ModeList'),.06);self.list.ZIndex=4;self.list.Visible=false;self.rows={}
    for _,m in ipairs(M.modes)do
        local b=UI.button(self.list,'Mode_'..m.id,'',function()self.mode=m.id;self.listOpen=false;if lobby.firstLesson then lobby.skipIntro=true;lobby:refresh()end;self:refresh();lobby:layout()end)
        b.BackgroundColor3=UI.colors.accent;b.BackgroundTransparency=1;b.AutoButtonColor=false;b:FindFirstChildOfClass('UIStroke').Enabled=false
        local bar=require(script.Parent.EdgeMask).fit(UI.make('Frame',b,{Name='Bar',BackgroundColor3=UI.colors.accent,BorderSizePixel=0}))
        self.rows[m.id]={button=b,bar=bar,icon=Icons.create(b,m.icon or m.id,20,UI.colors.muted),name=line(b,'Name',m.name,15,UI.colors.ink),hint=line(b,'Hint',m.hint,12,UI.colors.muted,true)}
    end
    self.notice=glass(UI.panel(f,'LiveNotice'),.25);self.notice.Visible=false
    self.noticeStrip=require(script.Parent.EdgeMask).fit(UI.make('Frame',self.notice,{Name='Strip',BackgroundColor3=UI.colors.accent,BorderSizePixel=0}))
    self.noticeKicker=line(self.notice,'Kicker','공지',12,UI.colors.accent);self.noticeIcon=Icons.create(self.notice,'notice',14,UI.colors.accent)
    self.noticeText=UI.label(self.notice,'Text','',13,UI.colors.ink);self.noticeText.TextWrapped=true;self.noticeText.TextTruncate=Enum.TextTruncate.AtEnd
    self.noticeText.TextYAlignment=Enum.TextYAlignment.Top
    self.daily=glass(UI.button(f,'DailyEvent','',function()local op=Daily.current((lobby.account.progress or {}).dailyOp,os.time());if op then require(script.Parent.LobbyConfirm).open(lobby,'오늘의 도전',((Maps.meta(op.map)or {}).label or op.map)..'\n'..op.conditionName,'출전',function()self.mode='daily';if lobby.firstLesson then lobby.skipIntro=true;lobby:refresh()end;lobby:closePage();self:refresh();self:go()
    self.mode='quick';self:refresh()end,nil,op.map)end end),.25)
    self.dailyStrip=require(script.Parent.EdgeMask).fit(UI.make('Frame',self.daily,{Name='Strip',BackgroundColor3=UI.colors.gold,BorderSizePixel=0}))
    self.dailyKicker=line(self.daily,'Kicker','오늘의 도전',12,UI.colors.gold);self.dailyIcon=Icons.create(self.daily,'daily',14,UI.colors.gold)
    self.dailyTitle=line(self.daily,'Title','',16,UI.colors.ink)
    self.dailySub=line(self.daily,'Sub','',12,UI.colors.muted,true)
    self.dailyReward=UI.make('Frame',self.daily,{Name='Reward',BackgroundTransparency=1,BorderSizePixel=0})
    self.rewardMedalIcon=Icons.create(self.dailyReward,'coin',13,UI.colors.gold);self.rewardMedal=line(self.dailyReward,'Medals','',12,UI.colors.gold)
    self.rewardXPIcon=Icons.create(self.dailyReward,'xp',13,UI.colors.ice);self.rewardXP=line(self.dailyReward,'XP','',12,UI.colors.ice)
    for _,l in ipairs({self.rewardMedal,self.rewardXP})do l.TextTruncate=Enum.TextTruncate.None;l.TextXAlignment=Enum.TextXAlignment.Left end
    self.party=UI.make('Frame',f,{Name='PartySlots',BackgroundTransparency=1})
    self.partyCaption=line(self.party,'Caption','',13,UI.colors.muted);self.partyIcon=Icons.create(self.party,'friends',16,UI.colors.muted)
    self.partyOptions=UI.make('Frame',f,{Name='PartyOptions',BackgroundTransparency=1,Visible=false})
    self.partyCoop=UI.button(self.partyOptions,'Coop','함께 협동',function()lobby.deployment.callbacks.partyCoop(false)end)
    self.partyHard=UI.button(self.partyOptions,'Hard','어려움 도전',function()lobby.deployment.callbacks.partyCoop(true)end)
    self.hq=glass(UI.button(f,'ReturnHQ','로비로 복귀 / 다음 경기 찾기',function()lobby:request('hq')end),.25);self.hq.TextSize=13;self.hq.Visible=false
    self.slots={}
    for i=1,5 do
        local b=glass(UI.button(self.party,'Slot'..i,'+',function()lobby:openPage('friends')end),.35);b.TextColor3=UI.colors.muted;b.TextSize=22
        local img=UI.make('ImageLabel',b,{Name='Avatar',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Visible=false})
        local ready=UI.make('Frame',b,{Name='Ready',BackgroundColor3=UI.colors.good,BorderSizePixel=0,Visible=false,Size=UDim2.new(1,0,0,3),Position=UDim2.new(0,0,1,-3)})
        self.slots[i]={button=b,image=img,ready=ready,stroke=b:FindFirstChildOfClass('UIStroke')}
    end
    local hs=lobby.header:FindFirstChildOfClass('UIStroke');lobby.header.BackgroundTransparency=1;if hs then hs.Enabled=false end
    self.brandMark=BrandMark.create(lobby.header,42)
    for _,o in ipairs({lobby.profile,lobby.settingsButton,lobby.help,lobby.motions,lobby.mission})do glass(o,.3)end
    lobby.nav.BackgroundTransparency=1;local ns=lobby.nav:FindFirstChildOfClass('UIStroke');if ns then ns.Enabled=false end
    for _,b in pairs(lobby.navButtons)do b.BackgroundTransparency=1;b.AutoButtonColor=false;b:FindFirstChildOfClass('UIStroke').Enabled=false end
    self.tabLine=UI.make('Frame',lobby.nav,{Name='TabLine',BackgroundColor3=UI.colors.accent,BorderSizePixel=0})
    self.tabIcons={};self.tabPads={}
    for key,icon in pairs(tabIcons)do local b=lobby.navButtons[key];if b then self.tabIcons[key]=Icons.create(b,icon,16,UI.colors.muted);self.tabPads[key]=UI.make('UIPadding',b,{})end end
    self.goalIcon=Icons.create(lobby.mission,'missions',18,UI.colors.accent)
    self.medalIcon=Icons.create(lobby.profile,'coin',14,UI.colors.gold)
    self.motionIcon=Icons.create(lobby.motions,'wave',18,UI.colors.accent);self.motionPad=UI.make('UIPadding',lobby.motions,{})
    lobby.mission.ZIndex=2;self.missionStrip=require(script.Parent.EdgeMask).fit(UI.make('Frame',lobby.mission,{Name='Strip',BackgroundColor3=UI.colors.accent,BorderSizePixel=0}))
    lobby.friends.Visible=false
    if lobby.deployment then lobby.deployment.hideShortcut=true;lobby.deployment.expanded=false end
    self.fieldPreview=require(script.Parent.LobbyFieldPreview).new(lobby)
    self.uiToggle=require(script.Parent.LobbyUIToggle).new(lobby)
    self.input=UIS.InputBegan:Connect(function(input,processed)
        if processed or UIS:GetFocusedTextBox()then return end
        local d=lobby.deployment
        if input.KeyCode==Enum.KeyCode.Return and lobby.frame.Visible and lobby.inMenu~=false and not lobby.page and not(d and d.expanded)then self:go()end
    end)
    local t=0
    self.tick=game:GetService('RunService').Heartbeat:Connect(function(dt)
        if not lobby.frame.Parent then self.tick:Disconnect();self.input:Disconnect();return end
        t+=dt;if t>=.5 then t=0;if lobby.frame.Visible and self.start.Visible then self:refresh()end end
    end)
    lobby.pageBody:GetPropertyChangedSignal('CanvasSize'):Connect(function()self:fit()end)
    return self
end
local FOOTER={solo=true,custom=true,customRules=true,room=true,joinCode=true,maps=true,motions=true,missions=true}
M.WHOLE={wardrobe=true,shop=true,missions=true,records=true,preferences=true,clan=true,supply=true}
if require(script.Parent.Lobby20).ENABLED then M.WHOLE.benefits=true end
M.SHEET={friends=true,custom=true,customRules=true,customCode=true,joinCode=true,watch=true}
M.SCREEN={room=true}
M.TWO={friends=true,custom=true,customRules=true,customCode=true,joinCode=true,watch=true,room=true,records=true,preferences=true}
M.FULL={}
for _,t in ipairs({M.WHOLE,M.SHEET,M.SCREEN})do for k in pairs(t)do M.FULL[k]=true end end
function M:fit()
    local l=self.lobby;if not l.page or FOOTER[l.page]or M.FULL[l.page]or not self.pageMax then return end
    local pw,ph,w,h=self.pageMax[1],self.pageMax[2],self.pageMax[3],self.pageMax[4]
    local want=math.clamp(math.ceil(62+l.pageBody.CanvasSize.Y.Offset+14),math.min(220,ph),ph)
    UI.box(l.pageCard,math.floor((w-pw)/2),self.pageMax[5],pw,want);UI.box(l.pageBody,14,62,pw-28,want-74)
end
function M:available(id)
    local p=self.lobby.account.progress or {}
    if id=='daily'then return p.dailyOp~=nil and (p.basicsComplete==true or p.tutorial==false or next(p.history or {})~=nil)end
    if id=='ranked'then return require(script.Parent.Parent.Core.HiddenScreens).ranked()end
    return true
end
function M:refresh()
    local l=self.lobby;local s=l.data;local q=s and s.queue;local party=s and s.party;local me=Players.LocalPlayer.UserId
    local d=l.deployment;local elapsed=d and os.clock()-(d.updated or os.clock())or 0
    if not self:available(self.mode)then self.mode='quick'end
    local mode=self.mode;local title,sub='빠른 참가',''
    local follower=party and #party.users>1 and party.leader~=me
    local op=Daily.current((l.account.progress or {}).dailyOp,os.time())
    do local p=l.account.progress or {};local streak=p.login and p.login.streak or 0
        l.medals.Text=UI.number(p.medals or 0)..(streak>0 and '  🔥'..streak or '');l.medals.TextWrapped=false end
    FreeDraw.dot(l.navButtons.shop,FreeDraw.ready(l.account.billing))
    if l.firstLesson and not q then title,sub='첫 작전','튜토리얼, 점령과 병력 기초'
    elseif q then
        local left=q.remaining and math.max(0,q.remaining-(os.clock()-(l.queueUpdated or os.clock())))
        title=q.mode=='custom'and '방 보기'or q.phase=='transferring'and '이동 중'or '대기 중'
        sub=q.phase=='transferring'and '같은 전장으로 이동 중…'or q.mode=='custom'and string.format('%d/%d명 / 준비 대기',q.count,q.max)
            or left and string.format('출발 %s / %d명 + AI',clock(left),q.count)or string.format('곧 출발 / %d명 + AI',q.count)
    elseif follower then title='방장이 고르는 중';sub='방장이 고른 방으로 같이 가요'
    elseif s and s.rejoin and mode=='quick'then title='경기로 복귀';sub=((Maps.meta(s.rejoin.map)or {}).label or s.rejoin.map or '진행 중인 경기')..' / 내 자리가 남아 있어요'
    elseif mode=='quick'then
        local pick=d and d:quickPick()
        local where=pick and (Maps.meta(pick.rules.map)or {}).label or pick and pick.rules.map;local kind=pick and (pick.rules.special and '특수 'or '')..(pick.rules.mode=='teams'and '팀전'or '개인전')
        sub=pick and (party and #party.users>1 and pick.rules.mode=='ffa'and string.format('%s / 각자 경쟁',where)or pick.remaining and string.format('%s / %s / 출발 %s',where,kind,clock(pick.remaining-elapsed))or string.format('%s / %s / AI 채움',where,kind))or party and #party.users>1 and '파티 전장 보기 / 협동도 준비할 수 있어요'or '전장을 찾는 중…'
    elseif mode=='fields'then local n=d and d.fields and #d.fields or 0;sub=n>0 and string.format('열린 전장 %d곳',n)or '전장을 찾는 중…'
    elseif mode=='solo'then title='시작';sub=(Maps.meta(l.map)or Maps.catalog[1]).label..' / '..difficulty[(l.settings or {}).difficulty or 'Medium']
    elseif mode=='campaign'then local Campaign=require(script.Parent.Parent.Core.CampaignRules);local cv=(l.account.progress or {}).campaign or {}
        local st=Campaign.stage(cv.next)or Campaign.stages[1];title='캠페인';sub=string.format('%s %s / ★ %d/%d',st.id,st.name,cv.total or 0,Campaign.maxStars)
    elseif mode=='daily'and op then title='시작';sub=((Maps.meta(op.map)or {}).label or op.map)..' / '..op.conditionName
    elseif mode=='custom'then local n=0;for _,x in ipairs(d and d.fields or {})do if x.kind=='custom'then n+=1 end end;sub=n>0 and string.format('열린 방 %d개',n)or '방 만들고 친구 초대'
    elseif mode=='ranked'then title='랭크전';sub=require(script.Parent.RankedEntry).summary(s and s.ranked,q)
    elseif mode=='watch'then title='관전하기';local n=s and s.live and #s.live or 0;sub=n>0 and string.format('진행 중 %d경기',n)or '진행 중 경기 없음'end
    local enabled=not l.busy and not l.loading and l.account.loading~=true and not(q and q.phase=='transferring')
    title,sub=require(script.Parent.LobbyHomeB).caption(self,title,sub,q,follower)
    self.title.Text=title;require(script.Parent.SegmentLine).apply(self.sub,sub,enabled and .1 or .5);UI.enabled(self.start,enabled)
    self.quickOn=not q and not follower and not l.firstLesson and not(s and s.rejoin);UI.enabled(self.quick,enabled)
    self.title.TextTransparency=enabled and 0 or .45;self.sub.TextTransparency=enabled and .1 or .5;self.mark.TextTransparency=enabled and 0 or .45
    local reduced=(l.account.preferences or {}).reducedEffects
    if self.pulse and reduced~=self.reduced then self.reduced=reduced;if reduced then self.pulse:Pause();self.glow.Transparency=0 else self.pulse:Play()end end
    local live=s and s.live and #s.live or 0
    for _,m in ipairs(M.modes)do local r=self.rows[m.id];local on=m.id==mode
        r.button.Visible=self:available(m.id);r.bar.Visible=on;r.button.BackgroundTransparency=on and .88 or 1;r.name.TextColor3=on and UI.colors.accent or UI.colors.ink
        r.icon.ImageColor3=on and UI.colors.accent or m.id=='daily'and UI.colors.gold or UI.colors.muted
        if m.id=='watch'then r.hint.Text=live>0 and string.format('진행 중 %d경기',live)or m.hint end
        if m.id=='ranked'then r.hint.Text=require(script.Parent.RankedEntry).summary(s and s.ranked,q)end
        if m.id=='daily'and op then r.hint.Text=op.done and string.format('오늘 완료 / 내 기록 %s',op.bestLabel)or ((Maps.meta(op.map)or {}).label or op.map)..' / '..op.conditionName end
    end
    Icons.set(self.modeIcon,(function()for _,m in ipairs(M.modes)do if m.id==mode then return m.icon or m.id end end;return mode end)())
    self.modeName.Text=(function()for _,m in ipairs(M.modes)do if m.id==mode then return m.name end end;return ''end)()
    self.caret.Text=self.listOpen and '▴'or '▾'
    self.dailyAvailable=self:available('daily')
    if op then
        require(script.Parent.TelemetryStep).change('dailyOp','lobby','dailyOpShown',{map_key=op.map,item=op.done and 'done'or 'open',result=op.done and 'complete'or 'shown'})
        self.dailyTitle.Text=((Maps.meta(op.map)or {}).label or op.map)..' / '..op.conditionName
        local chips=not op.done and Icons.available(self.rewardMedalIcon)and Icons.available(self.rewardXPIcon)
        self.dailySub.Text=op.done and string.format('오늘 완료 / 내 기록 %s',op.bestLabel)or chips and '첫 완료'or string.format('첫 완료 +%d 코인 / +%d XP',op.medals,op.xp)
        self.dailyChips=chips;self.rewardMedal.Text='+'..op.medals;self.rewardXP.Text='+'..op.xp
    end
    local pack=script.Parent.Parent;local boost=tonumber(pack:GetAttribute('LiveXPBoost'))or 1
    local ko=Players.LocalPlayer.LocaleId:sub(1,2)=='ko';local en=pack:GetAttribute('LiveNoticeEn')
    local text=(not ko and type(en)=='string'and en~=''and en)or pack:GetAttribute('LiveNotice')
    text=type(text)=='string'and text or ''
    self.noticeOperator=text~=''
    self.noticeText:SetAttribute('LocalizationSkip',text~='');self.noticeText.AutoLocalize=false
    if boost>1 then local x=(string.format('%.1f',boost):gsub('%.0$',''));self.noticeKicker.Text='이벤트'
        if text==''then text=string.format('경기 XP x%s',x);self.noticeText:SetAttribute('LocalizationSkip',false)else self.noticeKicker.Text=string.format('이벤트 / 경기 XP x%s',x)end
    else self.noticeKicker.Text='공지'end
    if self.noticeText.Text~=text then self.noticeText.Text=text end
    local had=self.noticeOn;self.noticeOn=text~=''
    if had~=self.noticeOn then require(script.Parent.TelemetryStep).change('notice','lobby','noticeShown',{value=boost,result=self.noticeOn and 'shown'or 'closed'})end
    if had~=self.noticeOn then l:layout()end
    local users=party and party.users or {me}
    for i,slot in ipairs(self.slots)do local id=users[i]
        slot.image.Visible=id~=nil;slot.button.Text=id and ''or '+'
        if id then local image='rbxthumb://type=AvatarHeadShot&id='..id..'&w=150&h=150';if slot.image.Image~=image then slot.image.Image=image end end
        slot.ready.Visible=id~=nil and #users>1 and id~=party.leader and Party.isReady(party,id)
        slot.stroke.Color=id==me and UI.colors.accent or UI.colors.line;slot.stroke.Thickness=id==me and 2 or 1;slot.stroke.Transparency=id==me and 0 or .2
    end
    local wait=s and s.partyWait;if wait and wait.name then Localization.addName(wait.name)end
    self.hqWanted=s and s.privateServer==true and not q and not follower
    local invites=s and s.invites and #s.invites or 0;local playing=0
    for _,friend in ipairs(l.onlineFriends or {})do if friend.PlaceId==game.PlaceId and not Players:GetPlayerByUserId(friend.VisitorId)then playing+=1 end end
    local waitText=wait and wait.name and ({inMatch='%s님 경기 중 / 끝나면 같은 파티',queued='%s님 대기 중 / 취소하면 같은 파티',joining='%s님 파티에 합류하는 중…',notHere='%s님을 이 서버에서 찾는 중…'})[wait.reason]
    self.partyCaption.Text=waitText and string.format(waitText,wait.name)or #users>1 and string.format('파티 %d/5 / 준비 %d',#users,Party.readyCount(party))or invites>0 and '초대 도착'or playing>0 and string.format('친구 %d명 플레이 중',playing)or '친구 초대 / XP +10%'
    self.partyCaption.TextColor3=(invites>0 or waitText)and UI.colors.gold or (playing>0 or #users>1)and UI.colors.accent or UI.colors.muted
    UI.enabled(self.partyCoop,enabled and not follower);UI.enabled(self.partyHard,enabled and not follower)
    Icons.set(self.partyIcon,invites>0 and 'invite'or 'friends');self.partyIcon.ImageColor3=self.partyCaption.TextColor3
    self.fieldPreview:refresh()
    require(script.Parent.Kit20).reduced=reduced==true
    require(script.Parent.Lobby20).refresh(self)
end
function M:go()
    local l=self.lobby;local d=l.deployment;local s=l.data;local q=s and s.queue;local party=s and s.party
    self.listOpen=false
    if l.busy or l.loading then require(script.Parent.TelemetryStep).step('lobby','deploy',{result='rejected',reason=l.loading and 'loading'or 'busy'});return end
    if l.firstLesson and not q and self.mode~='daily'then l:closePage();l.callbacks.learn();return end
    if q then if q.mode=='custom'then l:openPage('room')elseif q.room and l.matchRoom then l.matchRoom:restore()elseif q.mode=='ranked'then l:openPage('ranked')else d:open('all',q.field)end;l:layout();return end
    if party and #party.users>1 and party.leader~=Players.LocalPlayer.UserId then d:open('all');l:layout();return end
    if self.mode=='quick'and not(s and s.rejoin)and self.fieldPreview:joinSelected()then require(script.Parent.TelemetryStep).step('lobby','deploy',{item='row_'..tostring(self.fieldPreview.selected)});l:layout();return end
    local m=self.mode;require(script.Parent.TelemetryStep).step('lobby','deploy',{item=(s and s.rejoin and m=='quick')and 'rejoin'or m})
    if s and s.rejoin and m=='quick'then l:request('rejoin');return end
    if m=='quick'and require(script.Parent.LobbyHomeB).START_FLOW then d:open('all')
    elseif m=='quick'then if d:quickPick()then d:quickJoin()else d:open('official')end
    elseif m=='fields'then d:open('all')
    elseif m=='solo'then d.callbacks.solo()
    elseif m=='daily'then if not Commands.soloLoading(l)then l:closePage();l.callbacks.daily()end
    elseif m=='campaign'then l.goalTab='campaign';l:openPage('missions')
    elseif m=='custom'then d:open('custom')
    elseif m=='ranked'then l:openPage('ranked')
    elseif m=='watch'then l:openPage('watch')end
    l:layout()
end
function M:dockQueue(on,q)
    local l=self.lobby;local d=l.deployment
    if not self.queueCancel then
        self.queueCancel=UI.button(self.start.Parent,'QueueCancel','취소',function()if d and d.callbacks.cancel then d.callbacks.cancel()end end)
        self.queueCancel.BackgroundColor3=UI.colors.bg;self.queueCancel.BackgroundTransparency=.1;self.queueCancel.TextColor3=UI.colors.ink;self.queueCancel.TextSize=15
    end
    local b=self.queueCancel;b.Visible=on and q~=nil and q.phase~='transferring'
    if not b.Visible then return end
    local p,sz=self.start.Position,self.start.Size;local bw=76;local bh=math.min(44,sz.Y.Offset-8)
    UI.box(b,p.X.Offset+sz.X.Offset-bw-8,p.Y.Offset+(sz.Y.Offset-bh)/2,bw,bh);b.ZIndex=self.start.ZIndex+6
    UI.enabled(b,not l.busy and not q.locked)
    for _,t in ipairs({self.title,self.sub})do t.Size=UDim2.fromOffset(math.max(40,math.min(t.Size.X.Offset,sz.X.Offset-bw-16-t.Position.X.Offset)),t.Size.Y.Offset)end
end
function M:quickJoin()
    local l=self.lobby;self.listOpen=false
    if l.busy or l.loading then return end
    l:request('play');l:layout()
end
function M:layout(w,h)
    local l=self.lobby;local d=l.deployment;local short=h<500;local narrow=w<600
    local open=d~=nil and d.expanded and not l.page;local menu=l.inMenu~=false;local home=menu and not open
    local show=menu and l.page=='motions';if l.page then home=false end
    local full=menu and l.page~=nil and M.WHOLE[l.page]==true
    local covered=short and not narrow and l.page~=nil and not show and not full
    local q=l.data and l.data.queue;local lift=q and ((d and d.barHeight or 48)+8)or 0
    local docked=q~=nil and home
    if d then d.barDocked=docked;d.barHidden=menu and l.page=='room';d.bar.Visible=q~=nil and not docked and not d.barHidden end
    if l.page=='room'and menu then lift=0 end
    if docked then lift=0 end
    self.top.Visible=menu and not(short and open);self.left.Visible=home and not narrow;self.bottom.Visible=home
    local il,ir,ib=require(script.Parent.Lobby20).sideInsets(l)
    UI.box(self.top,-il,0,w+il+ir,short and 72 or 120);UI.box(self.left,-il,0,(short and 320 or 460)+il,h+ib);UI.box(self.bottom,-il,h-(narrow and 320 or 160),w+il+ir,(narrow and 320 or 160)+ib)
    for _,o in ipairs({self.start,self.select})do o.Visible=home end
    self.party.Visible=home and not(self.listOpen and not short and not narrow)
    self.list.Visible=home and self.listOpen;l.friends.Visible=false
    local left=l.topbarLeft or 12;local rp=(l.topbarRight or 12)-12
    local profile=w>600 and not(short and open)and not covered;l.profile.Visible=profile
    l.settingsButton.Visible=false;l.help.Visible=false
    UI.box(l.settingsButton,w-116-rp,8,60,44);UI.box(l.help,w-52-rp,8,44,44);UI.box(l.profile,w-158-rp,8,146,44)
    local right=(profile and w-158-rp or w-12-rp)-8
    UI.box(l.header,left,8,200,44)
    l.header.Visible=not(short and open)and not covered and right-left>=172
    local markW=BrandMark.available(self.brandMark)and(short and 36 or 42)or 0
    if not narrow and right-(16+(short and 150 or 172)+markW)<7*56 then markW=0 end
    self.brandMark.Visible=markW>0
    if markW>0 then UI.box(l.header,left,8,(short and 166 or 200)+markW-4,44);UI.box(self.brandMark,2,(44-markW)/2,markW,markW);UI.box(l.brandTop,8+markW,4,180,12);UI.box(l.brand,8+markW,14,180,28)end
    local order={'play','wardrobe','shop','clan','missions','records','preferences'};local xs,ws={},{}
    if narrow then
        for i=1,#order do ws[i]=(w-24)/#order end;UI.box(l.nav,12,h-56-lift,w-24,48);l.nav.BackgroundTransparency=.15
    else
        local x=left+(short and 150 or 172)+8+markW;l.header.Visible=not(short and open)and not covered
        if right-x<7*56 then l.header.Visible=false;x=left end
        local total=0
        for i,key in ipairs(order)do local b=l.navButtons[key];local word=TextService:GetTextSize(b.Text,16,b.Font,Vector2.new(400,44)).X;ws[i]=math.max(80,word+20+24);total+=ws[i]end
        if total>right-x then local k=(right-x)/total;for i=1,#order do ws[i]*=k end;total=right-x end
        UI.box(l.nav,x,8,total,44);l.nav.BackgroundTransparency=1
    end
    l.nav.Visible=menu and (full or not(short and open)and not(short and not narrow and l.page~=nil and not show))
    local tabs=({play=1,wardrobe=2,motions=2,shop=3,supply=3,benefits=3,clan=4,missions=5,records=6,preferences=7})[l.page or 'play']or 1
    local cx=0
    for i,key in ipairs(order)do local b=l.navButtons[key];local tw=ws[i];xs[i]=cx;UI.box(b,cx,0,tw,narrow and 48 or 44);cx+=tw;b.TextSize=narrow and 11 or 15
        b.TextColor3=i==tabs and UI.colors.ink or UI.colors.muted
        local icon,pad=self.tabIcons[key],self.tabPads[key]
        if icon and Icons.available(icon)then icon.ImageColor3=i==tabs and UI.colors.accent or UI.colors.muted
            if narrow then icon.Visible=true;UI.box(icon,tw/2-9,4-18,18,18);pad.PaddingLeft=UDim.new(0,0);pad.PaddingTop=UDim.new(0,18)
            else local tw2=TextService:GetTextSize(b.Text,b.TextSize,b.Font,Vector2.new(400,44)).X
                local room=tw>=tw2+28;icon.Visible=room
                if not room and tw2>tw-6 then b.TextSize=14 end
                UI.box(icon,math.max(2,(tw-tw2-20)/2)-20,14,16,16);pad.PaddingLeft=UDim.new(0,room and 20 or 0);pad.PaddingTop=UDim.new(0,0)end
        end end
    UI.box(self.tabLine,xs[tabs]+ws[tabs]/2-14,narrow and 43 or 40,28,3)
    for _,key in ipairs({'wardrobe','shop'})do local b=l.navButtons[key];if b and b:GetAttribute('ThumbTab')~=(narrow or nil)then b:SetAttribute('ThumbTab',narrow or nil)end;require(script.Parent.CollectionBadges).place(b)end
    for i,key in ipairs(order)do local b=l.navButtons[key];local tw,th=ws[i],narrow and 48 or 44;local icon,pad=self.tabIcons[key],self.tabPads[key]
        if narrow and icon and icon.Visible and Icons.available(icon)then RedDot.onIcon(b,icon)
        else local word=TextService:GetTextSize(b.Text,b.TextSize,b.Font,Vector2.new(400,th));local pl=pad and pad.PaddingLeft.Offset or 0;local pt=pad and pad.PaddingTop.Offset or 0
            RedDot.anchor(b,pl+(tw-pl-word.X)/2,pt+(th-pt-word.Y)/2,word.X)end end
    FreeDraw.dot(l.navButtons.shop,FreeDraw.ready(l.account.billing))
    local cw=narrow and w-24 or short and 232 or 300
    local sh=narrow and 68 or short and 60 or 76;local selH=short and 40 or narrow and 44 or 48
    local sx=narrow and 12 or short and 12 or 24
    local sy,selY
    if narrow then sy=h-90-lift-sh;selY=sy-6-selH else sy=short and 60 or 84;selY=sy+sh+6 end
    local qw=self.quickOn and home and not(short and self.listOpen)and (narrow and 112 or short and 104 or 132)or 0
    local dw=narrow and qw>0 and cw-qw-8 or cw;self.quick.Visible=qw>0
    UI.box(self.start,sx,sy,dw,sh)
    if qw>0 then UI.box(self.quick,sx+dw+8,sy,qw,sh);UI.box(self.quickTitle,4,sh/2-(short and 19 or 22),qw-8,short and 22 or 26);UI.box(self.quickSub,4,sh/2+(short and 3 or 4),qw-8,16)
        self.quickTitle.TextSize=short and 16 or 18 end
    UI.box(self.title,16,short and 4 or 8,dw-76,short and 30 or 36);self.title.TextSize=short and 24 or narrow and 26 or 30
    UI.box(self.sub,16,short and 34 or 44,dw-76,short and 18 or 22);self.sub.TextSize=short and 12 or 14
    UI.box(self.mark,dw-58,0,48,sh);self.mark.TextSize=short and 30 or 38
    UI.box(self.select,sx,selY,cw,selH);UI.box(self.kicker,14,0,44,selH);UI.box(self.modeIcon,56,selH/2-9,18,18);UI.box(self.modeName,82,0,cw-124,selH);UI.box(self.caret,cw-36,0,28,selH)
    local count=0;for _,m in ipairs(M.modes)do if self:available(m.id)then count+=1 end end
    local cols=short and 2 or 1;local rh=short and 46 or 52;local rw=short and math.min(230,(w-sx-cw-24-8)/2)or cw-8
    local lw=cols*rw+8;local lh=math.ceil(count/cols)*rh+8
    local lx,ly=sx,selY+selH+6
    if short then lx,ly=sx+cw+8,sy elseif narrow then ly=selY-6-lh end
    UI.box(self.list,lx,ly,lw,lh)
    local i=0;for _,m in ipairs(M.modes)do local r=self.rows[m.id];if r.button.Visible then
        UI.box(r.button,4+(i%cols)*rw,4+(i//cols)*rh,rw-(cols>1 and 4 or 0),rh-2);UI.box(r.bar,0,8,3,rh-18);UI.box(r.icon,12,(rh-2)/2-10,20,20);UI.box(r.name,42,short and 4 or 6,rw-56,short and 20 or 22);UI.box(r.hint,42,short and 24 or 28,rw-56,short and 16 or 18);i+=1 end end
    local col=short and 220 or 290;local rx=w-(short and 12 or 24)-col;local ry=short and 60 or 70
    local hqOn=home and self.hqWanted==true and not self.listOpen
    if narrow then col,rx,ry=w-24,12,hqOn and 166 or 126 end
    self.notice.Visible=self.noticeOn==true and home and not((narrow or short)and self.listOpen)
    if self.notice.Visible then local tight=short or narrow;local nh=tight and 46 or 58
        UI.box(self.notice,rx,ry,col,nh);UI.box(self.noticeStrip,0,0,3,nh);UI.box(self.noticeIcon,14,tight and 5 or 7,14,14);UI.box(self.noticeKicker,32,tight and 4 or 6,col-46,16)
        UI.box(self.noticeText,14,tight and 20 or 24,col-28,nh-(tight and 22 or 28));self.noticeText.TextSize=tight and 12 or 13;ry+=nh+8
        self.noticeKicker.Visible=true;self.noticeText.TextWrapped=true;self.noticeText.TextYAlignment=Enum.TextYAlignment.Top end
    self.daily.Visible=(self.dailyAvailable==nil and self:available('daily')or self.dailyAvailable==true)and home and not((narrow or short)and self.listOpen)
    if self.daily.Visible then local tight=short or narrow;local dh=tight and 54 or 72
        UI.box(self.daily,rx,ry,col,dh);UI.box(self.dailyStrip,0,0,3,dh);UI.box(self.dailyIcon,14,tight and 5 or 7,14,14);UI.box(self.dailyKicker,32,tight and 4 or 6,col-46,16)
        UI.box(self.dailyTitle,14,tight and 19 or 24,col-28,tight and 18 or 22);self.dailyTitle.TextSize=tight and 14 or 16
        UI.box(self.dailySub,14,tight and 36 or 48,col-28,16);self.dailySub.TextSize=tight and 11 or 12
        self.dailyReward.Visible=self.dailyChips==true
        if self.dailyChips then
            local fs=tight and 11 or 12;local function tw(t)return TextService:GetTextSize(t,fs,Enum.Font.BuilderSansBold,Vector2.new(200,20)).X end
            local mw,xw=tw(self.rewardMedal.Text)+4,tw(self.rewardXP.Text)+4;local rw=13+3+mw+8+13+3+xw
            UI.box(self.dailyReward,col-14-rw,tight and 36 or 48,rw,16)
            UI.box(self.rewardMedalIcon,0,1,13,13);UI.box(self.rewardMedal,16,0,mw,16);UI.box(self.rewardXPIcon,16+mw+8,1,13,13);UI.box(self.rewardXP,16+mw+8+16,0,xw,16)
            self.rewardMedal.TextSize=fs;self.rewardXP.TextSize=fs
        end
        ry+=dh+8 end
    l.mission.Visible=home and not short and not narrow and w>650
    UI.box(l.mission,rx,ry,col,62);UI.box(self.missionStrip,0,0,3,62);UI.box(self.goalIcon,14,10,18,18);UI.box(l.goalTitle,40,7,col-54,24);UI.box(l.goalSub,40,33,col-54,22)
    local slot=narrow and 40 or short and 36 or 48;local gap=short and 6 or 8
    local px,py=sx,narrow and 58 or short and selY+selH+8 or h-122
    UI.box(self.party,px,py,cw,20+slot);UI.box(self.partyIcon,0,1,16,16);UI.box(self.partyCaption,22,0,cw-22,18);self.partyCaption.TextSize=short and 12 or 13
    for n,s in ipairs(self.slots)do UI.box(s.button,(n-1)*(slot+gap),20,slot,slot)end
    self.hq.Visible=hqOn
    if self.hq.Visible then UI.box(self.hq,px,(narrow or short)and py+20+slot+8 or py-40,math.min(cw,280),32)end
    local goal=((l.account.progress or {}).career or {}).goals;goal=goal and goal[1];self.goalStrip=self.goalStrip or line(l.frame,'GoalStrip','',12,UI.colors.gold,true)
    self.goalStrip.Visible=home and (short or narrow)and goal~=nil and not self.listOpen
    if self.goalStrip.Visible then self.goalStrip.Text=goal;UI.box(self.goalStrip,sx,narrow and selY-24 or py+26+slot+(hqOn and 40 or 0),cw,20)end
    UI.box(self.medalIcon,48,23,14,14);UI.box(l.medals,66,22,74,16)
    self.benefit=self.benefit or Badge.create(l.profile,14)
    local owner=Players.LocalPlayer
    Badge.update(self.benefit,owner:GetAttribute('CommanderPermanent')==true,owner:GetAttribute('CommanderVIP')==true)
    local bw=Badge.width(self.benefit);UI.box(self.benefit.root,140-bw,5,math.max(1,bw),14)
    if bw>0 then UI.box(l.level,48,3,math.max(40,88-bw),18);l.level.TextTruncate=Enum.TextTruncate.AtEnd end
    l.motions.Visible=home
    if narrow then UI.box(l.motions,w-12-76,78,76,40)elseif short then UI.box(l.motions,w-12-84,h-52-lift,84,44)else UI.box(l.motions,w-24-104,h-72,104,48)end
    do local mw,mh=l.motions.Size.X.Offset,l.motions.Size.Y.Offset
        local mt=TextService:GetTextSize(l.motions.Text,l.motions.TextSize,l.motions.Font,Vector2.new(400,mh)).X
        local fits=Icons.available(self.motionIcon)and mt+22<=mw-8
        self.motionIcon.Visible=fits;self.motionPad.PaddingLeft=UDim.new(0,fits and 22 or 0)
        if fits then UI.box(self.motionIcon,(mw-mt-22)/2-22,mh/2-9,18,18)end end
    l.copyright.Visible=not open and not l.page
    if narrow then UI.box(l.copyright,6,h-56-lift-30,216,28)elseif short then UI.box(l.copyright,6,h-40-lift,216,38)end
    if not self.dimTween then l.overlay.BackgroundTransparency=show and 1 or .25 end
    if show then
        local pw=narrow and w-24 or math.min(420,math.floor(w*.42))
        local ph=narrow and math.floor(h*.48)or math.min(h-(short and 72 or 120),500)
        if narrow then UI.box(l.pageCard,12,h-56-lift-8-ph,pw,ph)else UI.box(l.pageCard,short and 12 or 24,short and 64 or 96,pw,ph)end
        UI.box(l.pageTitle,18,8,pw-84,42);UI.box(l.pageClose,pw-56,7,44,44);UI.box(l.pageBody,14,62,pw-28,ph-74)
        l.copyright.Visible=false
    end
    local two=menu and l.page~=nil and M.TWO[l.page]==true
    l.pageTitle.Visible=not full and not two;l.pageClose.Visible=not full and not two;l.pageBody.ScrollingEnabled=not(full and (l.page=='wardrobe'or l.page=='missions'))and not two
    do local edge=l.pageCard:FindFirstChildOfClass('UIStroke');if edge then edge.Enabled=not full end end
    for _,o in ipairs({l.header,l.profile})do o.ZIndex=full and 31 or 1 end
    if full and narrow then l.header.Visible=false;l.profile.Visible=false end
    if l.page~='shop'then for _,n in ipairs({'OddsSheet','PerksSheet'})do local sheet=l.overlay:FindFirstChild(n);if sheet then sheet:Destroy()end end end
    do local V=require(script.Parent.VipLock);local cover=full or (menu and l.page~=nil)
        if V.covered~=cover then V.covered=cover;if V.wanted~=nil then V.hqPill(V.wanted)end end
        if V.fullCover~=full then V.fullCover=full
            if menu then pcall(function()game:GetService('TextChatService').ChatWindowConfiguration.Enabled=not full end)end end end
    if full then
        local top=narrow and math.max(8,(l.topbarHeight or 0)+4)or 60;local bottom=narrow and 64+lift or 8;local side=w>=1000 and 24 or 12
        if require(script.Parent.Lobby20).ENABLED then top,bottom=require(script.Parent.Lobby20).insets(w,h,lift)end
        l.overlay.BackgroundTransparency=0;l.overlay.BackgroundColor3=UI.colors.bg;l.pageCard.BackgroundTransparency=1
        UI.box(l.pageCard,side,top,w-side*2,h-top-bottom);UI.box(l.pageBody,0,0,w-side*2,h-top-bottom)
        l.copyright.Visible=false
    else l.overlay.BackgroundColor3=Color3.fromRGB(4,7,11)end
    self:sheet20(w,h,lift,full)
    self.select.Visible=false;self.list.Visible=false;self.quick.Visible=false;self.listOpen=false
    local entryW=narrow and w-24 or short and w-24 or math.min(780,w-350)
    entryW=math.max(math.min(w-24,420),entryW)
    local entryX=(narrow or short)and 12 or 24
    local entryY=narrow and 128 or short and 60 or 64
    local entryH=short and 44 or 60
    local queueBarOwnsStart=short and q~=nil and not docked
    self.start.Visible=home and not queueBarOwnsStart
    UI.box(self.start,entryX,entryY,entryW,entryH);UI.box(self.title,16,short and 2 or 4,entryW-72,short and 24 or 28);self.title.TextSize=short and 20 or 24
    UI.box(self.sub,16,short and 26 or 32,entryW-72,short and 16 or 22);self.sub.TextSize=short and 12 or 14;UI.box(self.mark,entryW-52,0,40,entryH)
    local fieldsY=entryY+(queueBarOwnsStart and 0 or entryH+8)
    self.fieldPreview:layout(entryX,fieldsY,entryW,home,narrow,short,math.max(100,h-fieldsY-(narrow and 98+lift or short and 28+lift or 140+lift)))
    local grouped=l.data and l.data.party and #l.data.party.users>1
    self.partyOptions.Visible=home and grouped and not short and not narrow and h-(fieldsY+222)>=154
    if self.partyOptions.Visible then
        local y=h-180;UI.box(self.party,entryX,y,300,68);UI.box(self.partyOptions,entryX,y+76,300,44)
        UI.box(self.partyCoop,0,0,146,44);UI.box(self.partyHard,154,0,146,44)
    end
    if home and (short or narrow)then
        self.daily.Visible=false;self.notice.Visible=self.notice.Visible and self.noticeOperator==true;self.goalStrip.Visible=false;self.hq.Visible=false
        if short then
            self.party.Visible=false;l.motions.Visible=false
            UI.box(l.copyright,6,h-28-lift,216,28)
        end
    end
    local L20=require(script.Parent.Lobby20)
    if home and L20.ENABLED then L20.home(self,w,h,short,q,lift,narrow)
    elseif home then require(script.Parent.LobbyHomeB).layout(self,w,h,short,q,lift,narrow)
    else require(script.Parent.LobbyHomeB).hide(self);L20.hide(self)end
    if not L20.ENABLED then self:dockQueue(docked and self.start.Visible,q)end
    self.uiToggle:apply(w,h,home,lift,self.toggleSpot)
    if l.page and not show and not full and not two then local size=l.pageCard.Size;self.pageMax={size.X.Offset,size.Y.Offset,w,h,l.pageCard.Position.Y.Offset};self:fit()end
    if l.page~=self.shownPage then
        local scale=l.pageCard:FindFirstChild('EntryScale')
        if two then if scale then scale.Scale=1 end;l.first20=l.page;self:enter20(self.shownPage,w,h)
        elseif l.page and not self.reduced then scale=scale or UI.make('UIScale',l.pageCard,{Name='EntryScale',Scale=1})
            scale.Scale=.96;Tween:Create(scale,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=1}):Play()end
        self.shownPage=l.page
    end
    require(script.Parent.LobbyShowcase).set(show,narrow and 'up'or 'right',menu)
    if L20.ENABLED then L20.chrome(self,w,h,lift);self:chrome20(w,h)end
end

function M:sheet20(w,h,lift,full)
    local l=self.lobby;local page=l.page;local menu=l.inMenu~=false
    local S=require(script.Parent.Sheet20)
    local d=l.deployment
    if d then d.barHidden=menu and page=='room';d.barRaised=menu and page~=nil and (M.SHEET[page]or M.SCREEN[page])==true end
    if not menu or not page then return end
    local card=l.pageCard;local edge=card:FindFirstChildOfClass('UIStroke')
    local corner=card:FindFirstChildOfClass('UICorner')
    local fmt=S.format(w,h);local screen=M.SCREEN[page]==true
    local bar=lift>0 and not screen and lift or 0
    if M.TWO[page]then
        local key=page..':'..math.floor(w)..'x'..math.floor(h)..':'..bar
        if self.drawn20~=key then local was=self.drawn20;self.drawn20=key
            if was and was:match('^[^:]+')==page then task.defer(function()if l.page==page then l:drawPage()end end)end end
    end
    if not(M.SHEET[page]or M.SCREEN[page])then
        l.overlay.ZIndex=25;if self.outside then self.outside.Visible=false end
        if corner and not full then corner.CornerRadius=UDim.new(0,3)end
        if not full then card.BackgroundColor3=UI.colors.panel end
        l.pageBody.ScrollBarThickness=M.TWO[page]and 0 or 3
        if M.TWO[page]then l.soloStart.Visible=false;l.pageSecondary.Visible=false end
        return
    end
    local x,y,sw,sh
    if screen or fmt=='pt'then x,y,sw,sh=0,0,w,h else x,y,sw,sh=S.rect(page,w,h,fmt,bar)end
    local dimColor=(screen or fmt=='pt')and S.PAGE or S.DIM
    local dimAlpha=screen and .04 or fmt=='pt'and .05 or .28
    l.overlay.ZIndex=(fmt=='pt'and not screen)and 28 or 40
    l.overlay.BackgroundColor3=dimColor
    if l.overlay:GetAttribute('Dim20')~=dimAlpha then l.overlay:SetAttribute('Dim20',dimAlpha);if not self.dimTween then l.overlay.BackgroundTransparency=dimAlpha end end
    if not self.dimTween then l.overlay.BackgroundTransparency=dimAlpha end
    if not self.glow20 then
        self.glow20=UI.make('Frame',l.overlay,{Name='Glow20',BackgroundColor3=Color3.fromRGB(16,46,58),BorderSizePixel=0,Size=UDim2.fromScale(1,.4),ZIndex=0,Active=false})
        UI.make('UIGradient',self.glow20,{Rotation=90,Transparency=NumberSequence.new(.45,1)})
        require(script.Parent.FullBleed).edge(self.glow20)
    end
    self.glow20.Visible=screen
    if not self.outside then
        self.outside=UI.make('TextButton',l.overlay,{Name='Outside20',Text='',BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Size=UDim2.fromScale(1,1),ZIndex=0})
        self.outside.Activated:Connect(function()if M.SHEET[l.page]and not(l.pageCard:GetAttribute('Moving20')=='in')then l:back()end end)
    end
    self.outside.Visible=not screen and fmt~='pt'
    local sheetCard=not screen and fmt~='pt'
    card.BackgroundColor3=S.BG;card.BackgroundTransparency=sheetCard and 0 or 1
    if corner then corner.CornerRadius=UDim.new(0,sheetCard and 8 or 0)end
    if edge then edge.Enabled=sheetCard;edge.Color=UI.colors.line;edge.Transparency=0;edge.Thickness=1 end
    local goal=UDim2.fromOffset(x,y)
    if card:GetAttribute('Moving20')then card:SetAttribute('Home20',goal)else card.Position=goal end
    card.Size=UDim2.fromOffset(sw,sh)
    UI.box(l.pageBody,0,0,sw,sh);l.pageBody.ScrollingEnabled=false;l.pageBody.ScrollBarThickness=0;l.pageBody.CanvasSize=UDim2.fromOffset(0,0)
    l.pageTitle.Visible=false;l.pageClose.Visible=false;l.soloStart.Visible=false;l.pageSecondary.Visible=false
    l.copyright.Visible=false
end
function M:enter20(from,w,h)
    local l=self.lobby;local K=require(script.Parent.Kit20);local S=require(script.Parent.Sheet20)
    local card=l.pageCard;local fmt=S.format(w,h)
    if from and M.TWO[from]and l.overlay.Visible then
        task.defer(function()local root=l.pageBody:FindFirstChild('Page20');if root and not K.reduced then K.rehome(root);root:SetAttribute('Shown20',false);K.appear(root,{dx=fmt=='pt'and 0 or 24,dy=fmt=='pt'and 24 or 0,t=.16,noFade=true})end end)
        return
    end
    if K.reduced then K.fade(card,true,.12);return end
    card:SetAttribute('Moving20',nil);card:SetAttribute('Shown20',false);K.rehome(card);card.Visible=true
    local move={dx=fmt=='pt'and 0 or 24,dy=fmt=='pt'and 24 or 0,t=fmt=='pt'and .16 or .18,noFade=true}
    if M.WHOLE[l.page]then
        task.defer(function()local root=l.pageBody:FindFirstChild('Page20');if root then K.rehome(root);root:SetAttribute('Shown20',false);K.appear(root,move)end end)
        return
    end
    local alpha=l.overlay:GetAttribute('Dim20')or .28
    l.overlay.BackgroundTransparency=1;self.dimTween=true
    local t=Tween:Create(l.overlay,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=alpha});t:Play()
    t.Completed:Once(function()self.dimTween=nil end)
    K.appear(card,move)
end
function M:leave20(page)
    local l=self.lobby;local K=require(script.Parent.Kit20);local S=require(script.Parent.Sheet20)
    if not page or not M.TWO[page]or K.reduced or not l.overlay.Visible then return false end
    local w,h=l.root.AbsoluteSize.X/Theme.scale,l.root.AbsoluteSize.Y/Theme.scale;local fmt=S.format(w,h)
    local card=l.pageCard;local pt=fmt=='pt'
    self.dimTween=true
    Tween:Create(l.overlay,TweenInfo.new(pt and .10 or .12,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
    K.rehome(card)
    K.leave(card,{dx=pt and 0 or 24,dy=pt and 24 or 0,t=pt and .10 or .12,noFade=true},function()
        self.dimTween=nil;card.Visible=true
        if not l.page then l.overlay.Visible=false end
    end)
    return true
end
function M:chrome20(w,h)
    local l=self.lobby;local c=self.c20;if not c or l.inMenu==false or not l.frame.Visible then return end
    local page=l.page;local d=l.deployment;local board=d~=nil and d.expanded and not page
    local fmt=require(script.Parent.Lobby20).format(w,h)
    local all={c.bar,c.thumb,c.logo,c.profile,c.gear.button,c.mark};for _,t in ipairs(c.tabs)do table.insert(all,t.button)end
    if page and M.SCREEN[page]then for _,o in ipairs(all)do o.Visible=false end;return end
    local sheet=page~=nil and M.SHEET[page]==true or board
    local lightPlay=sheet or (fmt=='pt'and page~=nil and (M.WHOLE[page]and (page=='records'or page=='preferences')))
    if not sheet and not lightPlay then return end
    if sheet then
        c.bar.Visible=fmt~='pt';c.thumb.Visible=fmt=='pt';c.logo.Visible=fmt=='pc';c.profile.Visible=true;c.gear.button.Visible=true
        for _,t in ipairs(c.tabs)do t.button.Visible=true end
    end
    if lightPlay then
        for i,t in ipairs(c.tabs)do local on=i==1
            t.icon.ImageColor3=on and UI.colors.accent or UI.colors.muted;t.word.TextColor3=on and UI.colors.ink or UI.colors.muted
            local K=require(script.Parent.Kit20);t.word.FontFace=K.fonts[on and 800 or 600]or t.word.FontFace
        end
        local b=c.tabs[1].button;local tw=b.Size.X.Offset;local mw=math.floor(tw*(fmt=='pt'and .4 or .44)+.5)
        c.mark.Visible=true;c.mark.Size=UDim2.fromOffset(mw,3)
        c.mark.Position=UDim2.fromOffset(math.floor(b.Position.X.Offset+(tw-mw)/2+.5),fmt=='pt'and b.Position.Y.Offset or c.bar.Size.Y.Offset-3)
        c.markLit=nil
    end
end
return M
