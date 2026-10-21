local UI=require(script.Parent.ToyUI)
local L=require(script.Parent.Localization)
local Theme=require(script.Parent.Theme)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Raster=require(script.Parent.RasterMap)
local CustomRules=require(script.Parent.Parent.Core.CustomBattlefieldRules)
local Official=require(script.Parent.Parent.Core.BattlefieldRules)
local TeamFormat=require(script.Parent.Parent.Core.TeamFormat)
local Party=require(script.Parent.Parent.Core.PartyFormation)
local PartyPlay=require(script.Parent.Parent.Core.PartyPlay)
local QueueUI=require(script.Parent.Parent.Core.QueuePresentation)
local Flow=require(script.Parent.Parent.Core.PlayFlow)
local UIS=game:GetService('UserInputService')
local Tween=game:GetService('TweenService')
local M={};M.__index=M
local azure=Color3.fromRGB(59,130,246);local violet=Color3.fromRGB(139,92,246)
local tabs={{'all','전체'},{'official','공식'},{'custom','커스텀'},{'ranked','랭크'},{'watch','관전'}}
local function clock(n)local s=math.max(0,math.ceil(n or 0));return string.format('%02d:%02d',s//60,s%60)end
local function color(f)return f.kind=='custom'and (f.rules.mode=='coop'and UI.colors.good or UI.colors.ice)or f.rules.mode=='teams'and violet or azure end
local function category(f)return f.kind=='custom'and (f.rules.mode=='coop'and '커스텀 협동'or '커스텀 대전')or f.rules.special and '공식 특수'or f.rules.mode=='teams'and '공식 팀전'or '공식 개인전'end
local function format(f)
    local r=f.rules
    if f.kind=='custom'and r.mode=='teams'then if r.teamFormat then return TeamFormat.label(r.teamFormat,nil,r.maximum)end;return string.format('최대 %d팀 %d명',r.teamCount,r.maximum)end
    if r.mode=='teams'and r.teamFormat=='HumansVsNations'then return string.format('사람 대 국가, 최대 %d대%d',r.maximum,r.maximum)end
    if r.mode=='teams'and r.teamFormat then return TeamFormat.label(r.teamFormat,r.teamCount,r.maximum)end
    if r.mode=='coop'then local ai=Flow.coopAI(r,f.count);return string.format('협동 %s AI %d명',L.text(({Easy='쉬움',Medium='보통',Hard='어려움',Impossible='불가능'})[r.settings.difficulty]),ai.ai)end
    return r.mode=='teams'and string.format('2진영 최대 %d대%d',r.maximum//2,r.maximum//2)or r.mode=='coop'and string.format('협동 최대 %d명',r.maximum)or string.format('개인전 최대 %d명',r.maximum)
end
local function title(f)return (Maps.meta(f.rules.map)or {}).label or f.rules.map end
local function ruleText(f)
    local spawn=f.rules.spawn=='random'and '랜덤 스폰'or '스폰 선택'
    if f.rules.special or f.rules.modifiers and #f.rules.modifiers>0 then
        local list={};for _,k in ipairs(f.rules.modifiers or {})do if k~='isRandomSpawn'then table.insert(list,Official.modifierLabels[k]or k)end end
        return spawn..(#list>0 and ', '..table.concat(list,', ')or '')
    end
    return spawn..', '..(f.kind=='custom'and (CustomRules.rewardMode(f.rules)=='custom'and '자유 규칙'or '일반 규칙')or '클래식')..(f.rules.settings and f.rules.settings.mapSize=='normal'and ', '..'큰 지도'or '')
end
local function status(f,elapsed)
    if f.phase=='transferring'then return '전장으로 이동 중…'end
    if f.remaining then return '출발 '..clock(f.remaining-elapsed)..(f.kind~='custom'and (f.ai or 0)>0 and ' / AI +'..f.ai or '')end
    if f.kind=='custom'then return string.format('준비 %d/%d',f.readyCount or 0,f.count)end
    if f.needsOpponent then return '상대 진영 모집 중'end
    if f.count==0 then return '참가하면 20초 뒤 출발'end
    return '곧 출발'
end
local function label(parent,name,text,size,c)local l=UI.label(parent,name,text,math.max(14,size or 14),c);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;return l end
local function seats(parent)
    local out={};for i=1,20 do local p=UI.make('Frame',parent,{Name='Seat'..i,BorderSizePixel=0,BackgroundColor3=UI.colors.line});UI.corner(p,99);table.insert(out,p)end;return out
end
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks,filter='all',sub='all',cards={},order={},selected=nil,selectInitial=true,expanded=true,updated=os.clock()},M)
    self.frame=UI.panel(parent,'Deployment');self.frame.BackgroundTransparency=.04;self.frame.ZIndex=19
    self.kicker=label(self.frame,'Kicker','출전',14,UI.colors.accent)
    self.hint=label(self.frame,'Hint','전 서버 함께 모집',14,UI.colors.muted)
    self.close=UI.button(self.frame,'Close','×',function()self:setOpen(false)end)
    self.solo=UI.button(self.frame,'Solo','혼자 하기',callbacks.solo,true)
    self.create=UI.button(self.frame,'Create','+ 방 만들기',callbacks.create)
    self.code=UI.button(self.frame,'InviteCode','초대 코드',callbacks.code)
    self.recent=label(self.frame,'Recent','',11,UI.colors.muted)
    self.tabs={};for _,v in ipairs(tabs)do self.tabs[v[1]]=UI.button(self.frame,'Filter_'..v[1],v[2],function()self:setFilter(v[1])end)end
    self.subs={};for i=1,3 do local b=UI.button(self.frame,'Sub'..i,'',function()self.sub=({'all',self.filter=='custom'and 'coop'or 'ffa',self.filter=='custom'and 'pvp'or 'teams'})[i];self:reorder();self:render()end);self.subs[i]=b end
    self.list=UI.make('ScrollingFrame',self.frame,{Name='Fields',Active=true,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=UI.colors.line,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y})
    self.quick=UI.button(self.list,'QuickDeploy','',function()self:quickJoin()end,true);self.quick.BackgroundColor3=Color3.new(1,1,1)
    UI.make('UIGradient',self.quick,{Name='Sheen',Color=ColorSequence.new(UI.colors.accent,UI.colors.accent:Lerp(UI.colors.ice,.4))})
    self.quickMark=UI.make('TextLabel',self.quick,{Name='Mark',Text='»',TextSize=30,Font=Enum.Font.BuilderSansBold,TextColor3=UI.colors.accent,BackgroundColor3=UI.colors.bg,BorderSizePixel=0});UI.corner(self.quickMark,3)
    self.quickTitle=label(self.quick,'Title','빠른 출전',22,UI.colors.bg);Theme.display(self.quickTitle)
    self.quickSub=label(self.quick,'Promise','혼자도 출발, 빈자리는 AI 지휘관',14,UI.colors.bg);self.quickSub.Font=Enum.Font.BuilderSansMedium
    self.quickHint=label(self.quick,'Hint','',16,UI.colors.bg)
    self.quickWhen=label(self.quick,'When','',14,UI.colors.bg);self.quickWhen.TextXAlignment=Enum.TextXAlignment.Right
    self.quickPicture=UI.make('Frame',self.quick,{Name='Map',BackgroundColor3=UI.colors.ocean,ClipsDescendants=true,BorderSizePixel=0});UI.stroke(self.quickPicture,UI.colors.bg,1);self.quickRaster=Raster.new(self.quickPicture,96,60)
    self.empty=label(self.list,'Empty','전장 목록을 확인하는 중…',16,UI.colors.muted);self.empty.TextWrapped=true
    self.emptyCreate=UI.button(self.list,'EmptyCreate','협동 방 만들기',function()if self.party and #self.party.users>1 then callbacks.partyCoop(false)else callbacks.create(self.sub=='pvp'and 'ffa'or 'coop')end end,true);self.emptyCreate.Visible=false
    self.partyBar=UI.panel(self.list,'Party');self.partyBar.Visible=false
    self.partyTitle=label(self.partyBar,'Title','',14,UI.colors.accent)
    self.partyHint=label(self.partyBar,'Hint','팀전은 같은 진영, 개인전은 각자 경쟁',11,UI.colors.muted)
    self.partyReady=UI.button(self.partyBar,'Ready','준비',function()if self.party and self.party.leader~=self.userId then self.callbacks.ready()else self.callbacks.party()end end)
    self.rankNotice=UI.panel(self.frame,'RankedNotice');self.rankNotice.Visible=false;self.rankNotice.BackgroundTransparency=.7
    self.rankEmblem=label(self.rankNotice,'Emblem','◆',32,UI.colors.accent);self.rankEmblem.TextXAlignment=Enum.TextXAlignment.Center
    self.rankTitle=label(self.rankNotice,'Title','랭크전 준비 중',22,UI.colors.ink);self.rankTitle.TextXAlignment=Enum.TextXAlignment.Center
    self.rankHint=label(self.rankNotice,'Hint','지금은 공식 전장을 즐겨 보세요.',14,UI.colors.muted);self.rankHint.TextXAlignment=Enum.TextXAlignment.Center;self.rankHint.TextWrapped=true
    self.rankOfficial=UI.button(self.rankNotice,'Official','공식 전장',function()self:setFilter('official')end,true)
    self.detail=UI.panel(self.frame,'Details');self.detail.BackgroundTransparency=0;self.detail.Active=true
    self.detailClose=UI.button(self.detail,'Close','×',function()self.selected=nil;self:render()end)
    self.detailType=label(self.detail,'Type','',13,UI.colors.muted)
    self.detailTitle=label(self.detail,'Title','',28);Theme.display(self.detailTitle)
    self.detailPicture=UI.make('Frame',self.detail,{Name='Map',BackgroundColor3=UI.colors.ocean,ClipsDescendants=true,BorderSizePixel=0});self.detailRaster=Raster.new(self.detailPicture,240,140)
    self.detailRules=label(self.detail,'Rules','',14,UI.colors.muted);self.detailRules.TextWrapped=true;self.detailRules.TextYAlignment=Enum.TextYAlignment.Top
    self.detailState=label(self.detail,'State','',14,UI.colors.accent)
    self.detailJoin=UI.button(self.detail,'Join','참가',function()self:join(self.selected)end,true)
    self.detailTeams=UI.button(self.detail,'Teams','팀 보기',function()local f=self.lookup and self.lookup[self.selected];if f and self.callbacks.teams then self.callbacks.teams(f)end end)
    self.detailHint=label(self.detail,'Hint','참가하면 준비 완료, 출발 전 취소 가능',12,UI.colors.muted);self.detailHint.TextWrapped=true
    self.bar=UI.panel(parent,'Participation');self.bar.ZIndex=23;self.bar.BackgroundTransparency=.04;self.bar.Visible=false
    self.barText=label(self.bar,'State','',14,UI.colors.accent);self.barText.TextWrapped=true;self.barText.TextTruncate=Enum.TextTruncate.None
    self.cancel=UI.button(self.bar,'Cancel','취소',callbacks.cancel)
    self.suggest=UI.button(self.bar,'Suggested','사람 있는 전장',function()if self.practiceAvailable and not self.suggested then self.callbacks.practice()else self:inspectSuggestion()end end);self.suggest.Visible=false
    self.shortcut=UI.button(parent,'OpenDeployment','출전',function()self:setOpen(true)end,true);self.shortcut.ZIndex=20
    UIS.InputBegan:Connect(function(input,processed)
        if processed or UIS:GetFocusedTextBox()or not self.inMenu then return end
        local k=input.KeyCode
        if k==Enum.KeyCode.Escape and self.expanded then if self.selected and self.width and self.width<1180 then self.selected=nil;self:render()else self:setOpen(false)end
        elseif k==Enum.KeyCode.S and self.expanded then callbacks.solo()
        elseif k==Enum.KeyCode.Return and self.expanded and self.selected then self:join(self.selected)
        elseif self.expanded then for i,v in ipairs({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five})do if k==v then self:setFilter(tabs[i][1])end end end
    end)
    return self
end
function M:setOpen(open)
    self.expanded=open;if open then self.selectInitial=self.selected==nil;self:reorder()end;self:render()
    if self.callbacks.toggled then self.callbacks.toggled(open)end
    if open and not self.reduced then local scale=self.frame:FindFirstChild('EntryScale')or UI.make('UIScale',self.frame,{Name='EntryScale',Scale=1});scale.Scale=.96;Tween:Create(scale,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=1}):Play()end
end
function M:open(filter,id)self.filter=filter or 'all';self.sub='all';self.selected=id;self:setOpen(true)end
function M:setFilter(filter)
    if filter=='watch'then self.callbacks.watch();return end
    if filter=='ranked'then self.callbacks.ranked();return end
    self.filter=filter;self.sub='all';self.selected=nil;self.selectInitial=true;self:reorder();self:render()
end
function M:reorder()
    self.order={};for _,f in ipairs(self.fields or {})do table.insert(self.order,f.id)end
    local lookup={};for _,f in ipairs(self.fields or {})do lookup[f.id]=f end
    table.sort(self.order,function(a,b)
        local fa,fb=lookup[a],lookup[b]
        local sa,sb=Flow.score(fa,self.queue),Flow.score(fb,self.queue);return sa<sb or sa==sb and ((fa.slot or 99)<(fb.slot or 99)or (fa.slot or 99)==(fb.slot or 99)and fa.id<fb.id)
    end)
end
function M:update(directory,queue,options)
    self.practicing=options and options.practice
    options=options or {};self.inMenu=options.menu~=false;self.reduced=options.reduced;self.busy=options.busy;self.recent.Text=options.recent or ''
    self.queue=queue;self.party=options.party;self.userId=options.userId;self.liveCount=options.live and #options.live or 0
    if directory and directory~=self.directorySource then
        self.directorySource=directory
        self.fields=directory.fields or {};self.upcoming=directory.next or {};self.updated=os.clock();self.directoryNow=directory.now;self.directoryError=directory.unavailable
        local known={};for _,id in ipairs(self.order)do known[id]=true end
        for _,f in ipairs(self.fields)do
            if not known[f.id]then
                local replaced=false;for i,id in ipairs(self.order)do local old=self.cards[id];if old and old.field.slot and old.field.slot==f.slot and old.field.kind==f.kind then
                    self.order[i]=f.id;self.cards[f.id]=old;self.cards[id]=nil;old.field=f;if self.selected==id then self.selected=nil end;replaced=true;break
                end end
                if not replaced then table.insert(self.order,f.id)end
            end
        end
    end
    self:render()
end
function M:inspectSuggestion()
    if self.queue and self.queue.mode=='custom'then self.callbacks.room()
    elseif self.suggested and self.lookup and self.lookup[self.suggested]then self:open('official',self.suggested)end
end
function M:join(id)
    local f=self.lookup and self.lookup[id];if not f or self.busy or self.directoryError then return end
    require(script.Parent.TelemetryClient).emit('battlefield_selected',{entry=self.quickJoining and 'quick'or 'list',format=f.rules.mode=='teams'and 'team'or f.rules.mode=='coop'and 'coop'or 'ffa',field_id=f.id,map_key=f.rules.map})
    if self.queue and self.queue.field==id then if f.kind=='custom'then self.callbacks.room()end;return end
    if self.party and #self.party.users>1 and self.party.leader~=self.userId then self.callbacks.ready();return end
    if not PartyPlay.assess(f,self.party,self.queue and self.queue.field)then require(script.Parent.TelemetryStep).step('lobby','fieldBlocked',{item=f.kind=='custom'and 'custom'or 'official',reason='party'});return end
    self.callbacks.join({field=f.id,revision=f.revision,quick=self.quickJoining or nil})
end
function M:quickPick()
    if self.directoryError then return nil end
    return PartyPlay.pick(self.fields,self.party,self.queue and self.queue.field)
end
function M:quickJoin()
    local f=self:quickPick();if not f then require(script.Parent.TelemetryStep).step('lobby','quickJoin',{result='unavailable',reason=self.directoryError and 'network'or 'none'});return end
    self.selected=f.id;self.quickJoining=true;self:join(f.id);self.quickJoining=nil
end
function M:card(f)
    local c=self.cards[f.id];if c then c.field=f;return c end
    c={field=f};c.frame=UI.panel(self.list,'Field_'..f.id);c.strip=require(script.Parent.EdgeMask).fit(UI.make('Frame',c.frame,{Name='TypeStrip',BorderSizePixel=0,BackgroundColor3=color(f)}))
    c.type=label(c.frame,'Type',category(f),12,color(f));c.state=label(c.frame,'State','',12,UI.colors.muted)
    c.type.Visible=false;c.chips=UI.make('Frame',c.frame,{Name='Tags',BackgroundTransparency=1})
    c.inspect=UI.button(c.frame,'Inspect','',function()self.selected=c.field.id;self:render()end);c.inspect.BackgroundTransparency=1;c.inspect:FindFirstChildOfClass('UIStroke').Enabled=false
    c.picture=UI.make('Frame',c.inspect,{Name='Map',BackgroundColor3=UI.colors.ocean,ClipsDescendants=true,BorderSizePixel=0});c.raster=Raster.new(c.picture,128,80)
    c.title=label(c.inspect,'Title','',23);Theme.display(c.title)
    c.format=label(c.inspect,'Format','',12,UI.colors.muted)
    c.rules=label(c.inspect,'Rules','',12,UI.colors.muted)
    c.count=label(c.frame,'Count','',13);Theme.display(c.count,true)
    c.join=UI.button(c.frame,'Join','참가',function()self:join(c.field.id)end,true)
    c.seats=seats(c.frame);c.rotation=label(c.frame,'Rotation','',10,UI.colors.muted)
    self.cards[f.id]=c;return c
end
function M:render()
    if not self.width then return end
    self.frame.Visible=self.inMenu and self.expanded and not self.suppressed;self.shortcut.Visible=self.inMenu and not self.expanded and not self.hideShortcut
    local w,h=self.width,self.height;local short=self.short;local elapsed=os.clock()-self.updated;local ranked=self.filter=='ranked'
    self.lookup={};for _,f in ipairs(self.fields or {})do if PartyPlay.assess(f,self.party,self.queue and self.queue.field)then self.lookup[f.id]=f end end
    local all,official,custom=0,0,0;for _,f in ipairs(self.fields or {})do all+=1;if f.kind=='official'then official+=1 else custom+=1 end end
    for _,v in ipairs(tabs)do local b=self.tabs[v[1]];local on=self.filter==v[1];b.Text=v[1]=='watch'and (self.liveCount or 0)>0 and string.format('관전 %d',self.liveCount)or v[2];b.BackgroundColor3=on and UI.colors.accent:Lerp(UI.colors.raised,.84)or UI.colors.raised;b.TextColor3=on and UI.colors.accent or UI.colors.ink;local st=b:FindFirstChildOfClass('UIStroke');if st then st.Color=on and UI.colors.accent or UI.colors.line end end
    for i,b in ipairs(self.subs)do b.Visible=self.filter~='all'and not ranked;b.Text=({'전체',self.filter=='custom'and '협동'or '개인전',self.filter=='custom'and '대전'or '팀전'})[i];local key=({'all',self.filter=='custom'and 'coop'or 'ffa',self.filter=='custom'and 'pvp'or 'teams'})[i];b.TextColor3=self.sub==key and UI.colors.accent or UI.colors.muted end
    local side=w>=1180
    if side and not ranked and (self.selectInitial or not self.lookup[self.selected])then
        for _,id in ipairs(self.order)do local f=self.lookup[id]
            if f and (self.filter=='all'or self.filter==f.kind)and (self.sub=='all'or self.sub=='pvp'and f.rules.mode~='coop'or self.sub==f.rules.mode)then self.selected=id;self.selectInitial=false;break end
        end
    end
    local selected=self.selected and self.lookup[self.selected];local detailW=math.min(420,w-32)
    local listW=side and w-detailW-40 or w-24
    local top=short and 104 or 126;if self.filter~='all'and not ranked then top+=48 end
    local listH=h-top-12
    UI.box(self.list,12,top,listW,listH)
    if not self.listPad then self.listPad=UI.make('UIPadding',self.list,{PaddingLeft=UDim.new(0,2),PaddingTop=UDim.new(0,2),PaddingRight=UDim.new(0,5),PaddingBottom=UDim.new(0,2)})end
    listW-=7
    self.list.Visible=not ranked;self.rankNotice.Visible=ranked
    if ranked then
        local nw=w-24;UI.box(self.rankNotice,12,top,nw,listH)
        local y=math.max(0,(listH-176)/2)
        UI.box(self.rankEmblem,16,y,nw-32,40);UI.box(self.rankTitle,16,y+48,nw-32,32)
        UI.box(self.rankHint,16,y+88,nw-32,32);UI.box(self.rankOfficial,(nw-180)/2,y+132,180,44)
    end
    for id,c in pairs(self.cards)do if not self.lookup[id]then c.raster:destroy();c.frame:Destroy();self.cards[id]=nil else c.frame.Visible=false end end
    local cols=listW>=580 and 2 or 1;local gap=12;local cw=(listW-gap*(cols-1))/cols;local ch=short and math.clamp(listH,128,154)or 194;local tight=ch<154;local index=0
    local party=self.party;local grouped=party and #party.users>1
    self.hint.Text=grouped and string.format('%d인 함께 입장, 개인전은 각자 경쟁',#party.users)or '전 서버 함께 모집'
    local follower=grouped and party.leader~=self.userId
    local ready=follower and Party.isReady(party,self.userId)
    local compactParty=short and grouped and w>=700
    local offset=grouped and not compactParty and 60 or 0
    local pick=self:quickPick()
    self.quickSub.Text=grouped and (pick and pick.rules.mode=='teams'and '팀전: 같은 진영'or '같은 경기, 각자 경쟁')or '혼자도 출발, 빈자리는 AI 지휘관'
    self.quick.Visible=not ranked and not self.queue and pick~=nil and self.filter~='custom'and not self.directoryError
    local soloStroke=self.solo:FindFirstChildOfClass('UIStroke')
    self.solo.BackgroundColor3=self.quick.Visible and UI.colors.raised or UI.colors.accent;self.solo.TextColor3=self.quick.Visible and UI.colors.ink or UI.colors.bg;if soloStroke then soloStroke.Color=self.quick.Visible and UI.colors.line or UI.colors.accent end
    if self.quick.Visible then
        local narrow=listW<420;local qh=narrow and 64 or short and 60 or 72
        local mark=narrow and 40 or 44;local pw,ph=narrow and 64 or 84,narrow and 40 or 52
        local tx=12+mark+12;local right=listW-pw-24
        UI.box(self.quick,0,offset,listW,qh);UI.box(self.quickMark,12,(qh-mark)/2,mark,mark);self.quickMark.TextSize=narrow and 26 or 30
        UI.box(self.quickPicture,listW-pw-12,(qh-ph)/2,pw,ph)
        local mode=(pick.rules.special and '특수 'or '')..(pick.rules.mode=='teams'and '팀전'or '개인전')
        if narrow then
            UI.box(self.quickTitle,tx,qh/2-26,right-tx,28);self.quickTitle.TextSize=20
            UI.box(self.quickHint,tx,qh/2+2,right-tx,20);self.quickHint.TextSize=14;self.quickHint.TextXAlignment=Enum.TextXAlignment.Left
            self.quickHint.Text=title(pick)..'  '..(pick.remaining and '출발 '..clock(pick.remaining-elapsed)or mode)
            self.quickSub.Visible=false;self.quickWhen.Visible=false
        else
            local lw=math.floor((right-tx)*.56);local rw=right-tx-lw
            UI.box(self.quickTitle,tx,qh/2-27,lw,30);self.quickTitle.TextSize=short and 20 or 24
            UI.box(self.quickSub,tx,qh/2+3,lw,20);self.quickSub.Visible=true
            UI.box(self.quickHint,tx+lw,qh/2-25,rw,24);self.quickHint.TextSize=16;self.quickHint.TextXAlignment=Enum.TextXAlignment.Right
            UI.box(self.quickWhen,tx+lw,qh/2+3,rw,20);self.quickWhen.Visible=true
            self.quickHint.Text=title(pick)..'  '..mode;self.quickWhen.Text=status(pick,elapsed)
        end
        UI.enabled(self.quick,not self.busy)
        local dim=self.busy and .5 or 0
        self.quickTitle.TextTransparency=dim;self.quickHint.TextTransparency=dim;self.quickWhen.TextTransparency=.12+dim*.8;self.quickSub.TextTransparency=.28+dim*.6;self.quickMark.TextTransparency=dim
        if self.quickMap~=pick.rules.map or self.quickDimensions~=pw then
            local changed=self.quickMap~=pick.rules.map;self.quickMap=pick.rules.map;self.quickDimensions=pw
            if changed then self.quickRaster:setPreview(Maps.preview(self.quickMap))end
            task.defer(function()if self.quick.Parent then self.quickRaster:fit();self.quickRaster:draw()end end)
        end
        offset+=qh+12
    end
    self.partyBar.Visible=grouped==true and not ranked
    self.partyBar.Parent=compactParty and self.frame or self.list
    self.kicker.Visible=w>580 and not compactParty
    self.hint.Visible=w>820 and not compactParty
    self.code.Visible=w>520 and not compactParty and not(self.short and w-456<math.max(16,(self.topbarLeft or 12)-12))
    if grouped then
        local count=Party.readyCount(party)
        local partyX=compactParty and math.max(16,(self.topbarLeft or 12)-12)or 0
        local partyW=compactParty and math.min(400,w-328-partyX)or listW
        UI.box(self.partyBar,partyX,compactParty and 8 or 0,partyW,48)
        UI.box(self.partyTitle,12,2,partyW-104,compactParty and 44 or 23)
        UI.box(self.partyHint,12,25,partyW-104,20);self.partyHint.Visible=not compactParty
        UI.box(self.partyReady,partyW-88,2,80,44)
        self.partyTitle.Text=string.format('파티 %d  %d/%d 준비',#party.users,count,#party.users)
        self.partyHint.Text=listW<500 and '팀전: 같은 진영'or '팀전은 같은 진영, 개인전은 각자 경쟁'
        self.partyReady.Text=follower and (ready and '준비 취소'or '준비')or '친구'
        UI.enabled(self.partyReady,not self.busy and not self.queue)
    end
    for _,id in ipairs(self.order)do local f=self.lookup[id]
        if f and (self.filter=='all'or self.filter==f.kind)and (self.sub=='all'or self.sub=='pvp'and f.rules.mode~='coop'or self.sub==f.rules.mode)then
            local c=self:card(f);c.frame.Visible=true;local x=index%cols*(cw+gap);local y=offset+index//cols*(ch+gap);index+=1
            UI.box(c.frame,x,y,cw,ch);UI.box(c.strip,0,0,cw,3)
            require(script.Parent.TelemetryClient).card(c.frame,f,index,'list')
            UI.box(c.type,12,8,cw*.55,20);UI.box(c.chips,12,8,cw*.55-8,20);UI.box(c.state,cw*.55,8,cw*.45-12,20);c.state.TextXAlignment=Enum.TextXAlignment.Right
            local middle=short and ch-80 or 110;UI.box(c.inspect,8,32,cw-16,middle)
            local mw=math.min(140,(cw-16)*.38);UI.box(c.picture,0,0,mw,middle);UI.box(c.title,mw+12,0,cw-mw-36,29);c.title.TextSize=short and 20 or 24
            UI.box(c.format,mw+12,tight and 26 or 31,cw-mw-36,tight and 16 or 20);UI.box(c.rules,mw+12,tight and 42 or 54,cw-mw-36,tight and 14 or 20)
            local q=self.queue and self.queue.field==f.id;c.state.TextColor3=f.remaining and UI.colors.accent or UI.colors.muted;require(script.Parent.SegmentLine).apply(c.state,status(f,elapsed),0,true)
            c.title.Text=title(f);c.format.Text=format(f);c.rules.Text=ruleText(f)
            c.rules.Visible=not tight
            if tight and f.kind=='official'then c.format.Text=f.rules.mode=='teams'and f.rules.teamFormat and TeamFormat.short(f.rules.teamFormat,f.rules.teamCount)..(f.rules.special and ' 특수'or '')or f.rules.mode=='teams'and (f.rules.spawn=='random'and '2진영 랜덤'or '2진영 선택')or (f.rules.special and '특수 'or '')..(f.rules.spawn=='random'and '랜덤 스폰'or '스폰 선택')end
            c.type.Text=category(f);c.type.TextColor3=color(f);require(script.Parent.TagChips).render(c.chips,require(script.Parent.TagChips).tags(f),cw*.55-8,20);c.strip.BackgroundColor3=color(f);c.strip.Visible=f.kind~='custom'
            c.frame.BackgroundColor3=q and UI.colors.accent:Lerp(UI.colors.panel,.92)or UI.colors.panel;c.frame:FindFirstChildOfClass('UIStroke').Color=q and UI.colors.accent or self.selected==f.id and UI.colors.ice or UI.colors.line
            local bottom=ch-48;local maxdots=math.min(f.rules.maximum,10);local available=cw-180;local step=math.min(12,available/maxdots)
            for i,p in ipairs(c.seats)do p.Visible=i<=maxdots;UI.box(p,12+(i-1)*step,bottom+9,6,6);p.BackgroundColor3=i<=math.ceil(f.count*maxdots/f.rules.maximum)and (f.rules.mode=='teams'and i%2==0 and UI.colors.ice or color(f))or UI.colors.line end
            UI.box(c.count,12+maxdots*step+6,bottom,65,24);c.count.Text=f.count..'/'..f.rules.maximum
            UI.box(c.join,cw-104,bottom-1,92,44);c.join.Text=q and (f.kind=='custom'and '방 보기'or '참가 중')or f.count>=f.rules.maximum and '만석'or self.queue and '옮겨 참가'or f.kind=='custom'and '방 참가'or '참가';c.join.TextSize=14
            UI.enabled(c.join,not self.busy and not self.directoryError and (q and f.kind=='custom'or not q and f.count<f.rules.maximum));c.join.BackgroundColor3=q and UI.colors.raised or UI.colors.accent;c.join.TextColor3=q and UI.colors.accent or UI.colors.bg;c.join.TextTransparency=q and 0 or c.join.TextTransparency
            if grouped and not q then
                c.join.Text=follower and (ready and '준비 완료'or '준비')or '파티 참가'
                UI.enabled(c.join,not self.busy and not self.directoryError and (follower and not self.queue or not follower and f.count+(self.queue and self.queue.field==f.id and 0 or #party.users)<=f.rules.maximum))
            end
            if f.teamPlan and f.teamPlan.locked and not q then c.join.Text='출발 준비';UI.enabled(c.join,false)end
            UI.box(c.rotation,12,ch-20,cw-128,16);c.rotation.Text=f.kind=='custom'and f.hostName or f.emptyRemaining and ('새 전장까지 '..clock(f.emptyRemaining-elapsed))or ''
            if c.map~=f.rules.map or c.drawWidth~=cw then local changed=c.map~=f.rules.map;c.map=f.rules.map;c.drawWidth=cw;if changed then c.raster:setPreview(Maps.preview(c.map))end;task.defer(function()if c.frame.Parent then c.raster:fit();c.raster:draw()end end)end
        end
    end
    local y=offset+math.ceil(index/cols)*(ch+gap)
    self.empty.Visible=index==0;require(script.Parent.TelemetryStep).change('fieldsEmpty','lobby','fieldsEmpty',{item=require(script.Parent.TelemetryStep).code(tostring(self.filter or 'all')..'_'..tostring(self.sub or 'any')),total=index,result=index==0 and 'shown'or 'closed',reason=index==0 and (self.directoryError and 'network'or grouped and 'party'or 'none')or nil})
UI.box(self.empty,12,offset+16,listW-24,54);self.empty.Text=self.directoryError and '공식 모집 연결 확인 중, 혼자 하기 이용 가능'or grouped and '함께 들어갈 전장이 없어요. 협동을 준비해 보세요.'or self.filter=='custom'and '열린 커스텀 방이 없어요.'or '전장 목록을 확인하는 중…'
    self.emptyCreate.Visible=index==0 and (self.filter=='custom'or grouped)and not self.directoryError
    self.emptyCreate.Text=self.sub=='pvp'and not grouped and '대전 방 만들기'or '협동 방 만들기';UI.box(self.emptyCreate,12,offset+78,math.min(280,listW-24),44);UI.enabled(self.emptyCreate,not self.busy and not follower)
    self.list.CanvasSize=UDim2.fromOffset(0,math.max(y,self.emptyCreate.Visible and offset+136 or 90))
    self.detail.Visible=self.frame.Visible and selected~=nil and not ranked
    if selected then
        local compact=short or listH<360;local dh=side and listH or compact and h-16 or listH
        UI.box(self.detail,w-detailW-12,side and top or compact and 8 or top,detailW,dh);self.detail.ZIndex=22
        UI.box(self.detailClose,detailW-52,6,44,44);self.detailClose.Visible=not side;UI.box(self.detailType,16,9,detailW-76,24);self.detailType.Text=category(selected);self.detailType.TextColor3=color(selected)
        UI.box(self.detailTitle,16,37,detailW-32,34);self.detailTitle.Text=title(selected)
        local picH=compact and math.clamp(dh-180,32,80)or math.min(190,dh-244);UI.box(self.detailPicture,16,compact and 64 or 78,detailW-32,picH)
        UI.box(self.detailRules,16,(compact and 70 or 88)+picH,detailW-32,compact and 28 or 80);local spawn=selected.rules.spawn=='random'and '랜덤 스폰'or '스폰 선택';local formation=L.text(format(selected),self.detailRules);self.detailRules.Text=compact and formation..'  '..L.text(spawn,self.detailRules)or formation..'\n'..L.text(ruleText(selected),self.detailRules)
        self.detailHint.Text=selected.kind=='custom'and '규칙을 확인하고 준비해 주세요.'or '참가하면 준비 완료, 출발 전 취소 가능'
        local by=dh-(compact and 52 or 96);UI.box(self.detailState,16,by-27,detailW-32,24);require(script.Parent.SegmentLine).apply(self.detailState,status(selected,elapsed)..' / '..selected.count..'/'..selected.rules.maximum)
        UI.box(self.detailJoin,16,by,detailW-32,48);local q=self.queue and self.queue.field==selected.id;self.detailJoin.Text=q and (selected.kind=='custom'and '방 보기'or '참가 중')or self.queue and '옮겨 참가'or '참가';UI.enabled(self.detailJoin,not self.busy and not self.directoryError and (q and selected.kind=='custom'or not q and selected.count<selected.rules.maximum));self.detailJoin.BackgroundColor3=q and UI.colors.raised or UI.colors.accent;self.detailJoin.TextColor3=q and UI.colors.accent or UI.colors.bg;self.detailJoin.TextTransparency=q and 0 or self.detailJoin.TextTransparency
        if grouped and not q then
            self.detailJoin.Text=follower and (ready and '준비 완료'or '준비')or '파티 참가'
            self.detailHint.Text='팀전은 같은 진영, 개인전은 각자 경쟁'
            UI.enabled(self.detailJoin,not self.busy and not self.directoryError and (follower and not self.queue or not follower and selected.count+#party.users<=selected.rules.maximum))
        end
        self.detailTeams.Visible=selected.teamPlan~=nil
        if self.detailTeams.Visible then UI.box(self.detailJoin,16,by,detailW-120,48);UI.box(self.detailTeams,detailW-96,by,80,48);self.detailTeams.TextSize=13 end
        if selected.teamPlan and selected.teamPlan.locked and not q then self.detailJoin.Text='출발 준비';UI.enabled(self.detailJoin,false)end
        UI.box(self.detailHint,16,by+52,detailW-32,38);self.detailHint.Visible=not compact
        if self.detailMap~=selected.rules.map or self.detailDimensions~=detailW..':'..picH then local changed=self.detailMap~=selected.rules.map;self.detailMap=selected.rules.map;self.detailDimensions=detailW..':'..picH;if changed then self.detailRaster:setPreview(Maps.preview(self.detailMap))end;task.defer(function()self.detailRaster:fit();self.detailRaster:draw()end)end
    end
    self.bar.Visible=self.queue~=nil and not self.barDocked
    self.suggested=QueueUI.suggestion(self.queue,{fields=self.fields,unavailable=self.directoryError},self.directoryNow and self.directoryNow+elapsed,grouped and #party.users or 1)
    if self.queue then local q=self.queue
        self.barText.Text=title({rules=q.rules or {map='world'}})..' '..q.count..'/'..q.max..'\n'..(q.phase=='transferring'and '이동 중…'or q.phase=='recovering'and '연결 확인 중…'or q.remaining and '출발 '..clock(q.remaining-elapsed)..(q.mode~='custom'and (q.ai or 0)>0 and (q.ai>(q.max or 0)-(q.count or 0)and ', 함께하는 AI 지휘관 'or ', 빈자리는 AI 지휘관 ')..q.ai..'명'or '')or q.mode=='custom'and '준비 대기'or q.needsOpponent and '상대 진영 모집 중'or '곧 출발')
        if q.mode=='ranked'then self.barText.Text=string.format('랭크 %s  %s',q.ladder=='clanwar'and '클랜전'or q.ladder=='2v2'and '2대2'or q.ladder=='ffa'and '개인전'or '1대1',q.phase=='transferring'and '상대 찾음, 이동 중…'or '상대 찾는 중')end
        if q.mode~='custom'and q.mode~='ranked'and q.rules and q.rules.mode=='teams'and q.phase~='transferring'then self.barText.Text..=((q.partyCount or 1)>1 and ', 파티 전원 같은 팀'or ', 팀은 출발 때 자동 배정')end
        self.cancel.Text=q.partyCount and '파티 대기 취소'or '대기 취소';UI.enabled(self.cancel,not self.busy and not q.locked)
    end
    self.practiceAvailable=Flow.practice(self.queue,self.directoryNow and self.directoryNow+elapsed,self.practicing)
    self.suggest.Visible=(self.suggested~=nil or self.practiceAvailable or self.queue and self.queue.mode=='custom')and self.inMenu;self.suggest.Text=self.queue and self.queue.mode=='custom'and '방 보기'or self.suggested and '사람 있는 전장'or '기다리며 연습'
    UI.enabled(self.suggest,not self.busy and not(self.queue and self.queue.locked))
    local bw=self.bar.Size.X.Offset;local bl=QueueUI.layout(bw,self.suggest.Visible);self.barHeight=bl.height
    if self.screenWidth then UI.box(self.bar,(self.screenWidth-bw)/2,self.screenHeight-bl.height-8,bw,bl.height)end
    for name,r in pairs({barText=bl.state,suggest=bl.suggest,cancel=bl.cancel})do UI.box(self[name],r.x,r.y,r.w,r.h)end
end
function M:layout(w,h)
    self.short=h<500
    local extra=math.max(0,(self.barHeight or 48)-48)
    self.width=w-24;self.height=h-(h<500 and (self.queue and 64+extra or 16)or (self.queue and 190+extra or 136));self.screenHeight=h;self.screenWidth=w
    UI.box(self.frame,12,h<500 and 8 or 58,self.width,self.height)
    local short=h<500;local fw=self.width
    local headerX=short and math.max(16,(self.topbarLeft or 12)-12)or 16
    UI.box(self.kicker,headerX,8,70,24);self.kicker.Visible=fw>580;UI.box(self.hint,headerX+72,8,math.max(0,fw-548-(headerX-16)),24);self.hint.Visible=fw>820
    UI.box(self.close,fw-56,8,44,44);UI.box(self.solo,fw-192,8,128,44);UI.box(self.create,fw-324,8,124,44)
    UI.box(self.code,fw-456,8,124,44);self.code.Visible=fw>520
    UI.box(self.recent,fw-320,short and 52 or 58,264,20);self.recent.TextXAlignment=Enum.TextXAlignment.Right;self.recent.Visible=fw>820
    local tabW=math.min(124,(fw-32-6*(#tabs-1))/#tabs);for i,v in ipairs(tabs)do UI.box(self.tabs[v[1]],16+(i-1)*(tabW+6),short and 54 or 66,tabW,44);self.tabs[v[1]].TextSize=14 end
    for i,b in ipairs(self.subs)do UI.box(b,16+(i-1)*90,short and 104 or 126,84,44);b.TextSize=14 end
    UI.box(self.shortcut,w-148,62,136,48)
    local barW=math.min(690,w-24);UI.box(self.bar,(w-barW)/2,h-56,barW,48);UI.box(self.barText,14,4,barW-100,40);UI.box(self.cancel,barW-80,2,72,44)
    self:render()
end
return M
