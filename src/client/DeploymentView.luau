local UI=require(script.Parent.ToyUI)
local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Raster=require(script.Parent.RasterMap)
local TeamFormat=require(script.Parent.Parent.Core.TeamFormat)
local Tags=require(script.Parent.TagChips)
local Party=require(script.Parent.Parent.Core.PartyFormation)
local PartyPlay=require(script.Parent.Parent.Core.PartyPlay)
local QueueUI=require(script.Parent.Parent.Core.QueuePresentation)
local Flow=require(script.Parent.Parent.Core.PlayFlow)
local UIS=game:GetService('UserInputService')
local Tween=game:GetService('TweenService')
local C=K.colors
local M={};M.__index=M
local function SF()return require(script.Parent.LobbyHomeB).START_FLOW end
local function clock(n)local s=math.max(0,math.ceil(n or 0));return string.format('%d:%02d',s//60,s%60)end
local function title(f)return (Maps.meta(f.rules.map)or {}).label or f.rules.map end
local function modeKey(f)return f.rules.mode=='teams'and 'teams'or f.rules.mode=='coop'and 'coop'or 'ffa'end
local function teamWord(r,plan)
    if r.teamFormat==TeamFormat.humansVsNations then return '사람 대 국가'end
    if TeamFormat.labels[r.teamFormat]then return TeamFormat.labels[r.teamFormat]end
    local n=tonumber(plan and plan.count or r.teamCount);return n and n>=2 and string.format('팀전 %d팀',n)or '팀전'
end
local function modeText(f)
    if f.kind=='custom'then return '커스텀'end
    return (f.rules.special and '특수 'or '')..(f.rules.mode=='teams'and teamWord(f.rules,f.teamPlan)or f.rules.mode=='coop'and '협동'or '개인전')
end
local function sideCap(r)
    if r.mode~='teams'or r.teamFormat==TeamFormat.humansVsNations then return r.maximum end
    return TeamFormat.fixedSize(r.teamFormat)or r.maximum//math.max(1,r.teamCount or 2)
end
local function label(parent,name,text,size,c)local l=UI.label(parent,name,text,math.max(14,size or 14),c);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;return l end

function M.new(parent,callbacks)
    local self=setmetatable({parent=parent,callbacks=callbacks,filter='all',sub='all',cards={},order={},selected=nil,selectInitial=true,expanded=true,updated=os.clock()},M)
    self.frame=K.make('TextButton',parent,{Name='Deployment',Text='',AutoButtonColor=false,BackgroundColor3=S.DIM,BackgroundTransparency=.28,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Visible=false,ZIndex=40,Active=true})
    self.frame.Activated:Connect(function()if self.fmt~='pt'then self:setOpen(false)end end)
    self.sheet=K.make('Frame',self.frame,{Name='Sheet',BackgroundColor3=S.BG,BorderSizePixel=0,Active=true})
    K.round(self.sheet,8);self.edge=K.stroke(self.sheet,C.line,1)
    K.make('TextButton',self.sheet,{Name='Catch',Text='',BackgroundTransparency=1,AutoButtonColor=false,Size=UDim2.fromScale(1,1),ZIndex=1})
    self.list=S.scroll(self.sheet,'Fields',0,0,10,10);self.list.ZIndex=2
    self.empty=K.text(self.list,'Empty','전장 목록을 확인하는 중…',15,C.muted,700,Enum.TextXAlignment.Center);self.empty.TextWrapped=true
    self.emptyCreate=K.button(self.list,'EmptyCreate',{kind='out',text='협동 방 만들기',size=15},function()if self.party and #self.party.users>1 then callbacks.partyCoop(false)else callbacks.create(self.sub=='pvp'and 'ffa'or 'coop')end end)
    self.emptyCreate.button.Visible=false
    self.shortcut=UI.button(parent,'OpenDeployment','출전',function()self:setOpen(true)end,true);self.shortcut.ZIndex=20;self.shortcut.Visible=false
    if require(script.Parent.Lobby20).ENABLED then require(script.Parent.QueueBar20).build(self,parent,callbacks)
    else
    self.bar=UI.panel(parent,'Participation');self.bar.ZIndex=23;self.bar.BackgroundTransparency=.04;self.bar.Visible=false
    self.barText=label(self.bar,'State','',14,UI.colors.accent);self.barText.TextWrapped=true;self.barText.TextTruncate=Enum.TextTruncate.None
    self.cancel=UI.button(self.bar,'Cancel','취소',callbacks.cancel)
    self.suggest=UI.button(self.bar,'Suggested','사람 있는 전장',function()if self.queue and self.queue.room and callbacks.matchRoom then callbacks.matchRoom()elseif self.practiceAvailable and not self.suggested then self.callbacks.practice()else self:inspectSuggestion()end end);self.suggest.Visible=false
    end
    UIS.InputBegan:Connect(function(input,processed)
        if processed or UIS:GetFocusedTextBox()or not self.inMenu then return end
        local k=input.KeyCode
        if k==Enum.KeyCode.Escape and self.expanded and not self.suppressed then self:setOpen(false)
        elseif k==Enum.KeyCode.S and self.expanded and not self.suppressed then callbacks.solo()
        elseif k==Enum.KeyCode.Return and self.expanded and not self.suppressed then local id=self.selected or (self:quickPick()or {}).id;if id then self:join(id)end end
    end)
    return self
end
function M:setOpen(open)
    local was=self.expanded
    self.expanded=open;if open then self.selectInitial=self.selected==nil;self:reorder();if not was or not self.frame.Visible then self.entering=true end else self.closing=true end
    self:render()
    if self.callbacks.toggled then self.callbacks.toggled(open)end
end
function M:open(filter,id)self.filter=SF()and filter~='ranked'and 'all'or filter or 'all';self.sub='all';self.selected=id;self:setOpen(true)end
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
        if (fa.kind=='custom')~=(fb.kind=='custom')then return fb.kind=='custom'end
        local sa,sb=Flow.score(fa,self.queue),Flow.score(fb,self.queue);return sa<sb or sa==sb and ((fa.slot or 99)<(fb.slot or 99)or (fa.slot or 99)==(fb.slot or 99)and fa.id<fb.id)
    end)
end
function M:update(directory,queue,options)
    self.practicing=options and options.practice
    options=options or {};self.inMenu=options.menu~=false;self.reduced=options.reduced;self.busy=options.busy
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

function M:action(f)
    local q=self.queue and self.queue.field==f.id;local party=self.party;local grouped=party and #party.users>1
    local follower=grouped and party.leader~=self.userId;local ready=follower and Party.isReady(party,self.userId)
    local text=q and (f.kind=='custom'and '방 보기'or '참가 중')or f.count>=f.rules.maximum and '만석'or self.queue and '옮겨 참가'or f.kind=='custom'and '방 참가'or '참가'
    local on=not self.busy and not self.directoryError and (q and f.kind=='custom'or not q and f.count<f.rules.maximum)
    if grouped and not q then
        text=follower and (ready and '준비 완료'or '준비')or '파티 참가'
        on=not self.busy and not self.directoryError and (follower and not self.queue or not follower and f.count+(self.queue and self.queue.field==f.id and 0 or #party.users)<=f.rules.maximum)
    end
    if grouped and not q and f.kind~='custom'and #party.users>sideCap(f.rules)then text='파티 인원 초과';on=false end
    if f.teamPlan and f.teamPlan.locked and not q then text='출발 준비';on=false end
    local plain=text=='참가'or text=='방 참가'or text=='옮겨 참가'or text=='파티 참가'
    return text,on,plain,q
end

local widths={}
local function width(t,s,l)local k=t..'|'..s..'|'..(l and l.Name or '');local v=widths[k];if not v then v=K.width(t,s,l);widths[k]=v end;return v end
local function mapPicture(parent,w,h,r)
    local p=K.make('Frame',parent,{Name='Map',BackgroundColor3=C.ocean,BorderSizePixel=0});K.round(p,r)
    local raster=Raster.new(p,128,80);if raster.label then K.round(raster.label,r)end
    return p,raster
end
function M:card(f,fmt)
    local c=self.cards[f.id];if c and c.fmt==fmt then c.field=f;return c end
    if c then c.raster:destroy();c.frame:Destroy()end
    local pt,ph=fmt=='pt',fmt=='ph'
    c={field=f,fmt=fmt}
    if pt then
        c.frame=K.make('Frame',self.list,{Name='Field_'..f.id,BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=3});K.round(c.frame,10)
        c.stroke=K.stroke(c.frame,C.line,1,0,true)
        c.join=K.button(c.frame,'Join',{kind='out',text='참가',size=14,weight=800},function()self:join(c.field.id)end)
    else
        c.press=K.button(self.list,'Field_'..f.id,{kind='none',r=8},function()self:join(c.field.id)end)
        c.frame=c.press.button;local face=c.press.face;face.BackgroundColor3=C.panel;face.BackgroundTransparency=0;c.press.baseFill=C.panel;c.press.baseAlpha=0
        c.press.faceStroke.Enabled=true;c.press.faceStroke.Color=C.line;c.press.faceStroke.Transparency=0;c.stroke=c.press.faceStroke
        c.press.minHit=0
    end
    local host=c.press and c.press.face or c.frame
    c.picture,c.raster=mapPicture(host,10,10,pt and 6 or 4)
    c.title=K.text(host,'Title','',pt and 15 or ph and 13 or 17,C.ink,800)
    c.mode=K.text(host,'Mode','',12,C.muted,800)
    c.chip=nil
    c.count=K.num(host,'Count','',pt and 12 or ph and 14 or 19,C.ink,Enum.TextXAlignment.Right)
    c.max=K.num(host,'Max','',pt and 12 or ph and 14 or 19,C.muted)
    c.time=K.num(host,'Time','',pt and 12 or ph and 13 or 17,C.accent)
    c.state=K.text(host,'State','',pt and 12 or 13,C.muted,800,Enum.TextXAlignment.Right)
    if pt then c.bar=K.fillBar(host,'Fill',{p=0,fill=C.accent,track=C.raised})
    else c.chev=K.icon(host,'chev',ph and 16 or 20,C.muted,'Chevron')end
    c.teams=K.make('TextButton',host,{Name='Teams',Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,ZIndex=6,Visible=false})
    c.teams.Activated:Connect(function()local fld=self.lookup and self.lookup[c.field.id];if fld and self.callbacks.teams then require(script.Parent.ToyAudio).play('click');self.callbacks.teams(fld)end end)
    for _,o in ipairs(host:GetDescendants())do if o:IsA('GuiObject')and o.ZIndex<4 then o.ZIndex=4 end end
    self.cards[f.id]=c;return c
end
function M:paintCard(c,x,y,w,h,elapsed,highlight)
    local f=c.field;local pt,ph=c.fmt=='pt',c.fmt=='ph'
    local text,on,plain,mine=self:action(f)
    if c.press then c.press:place(x,y,w,h);c.press:setEnabled(on or mine,true)else K.box(c.frame,x,y,w,h)end
    c.stroke.Color=highlight and C.accent or C.line;c.stroke.Thickness=highlight and 2 or 1
    if c.press then c.press.baseStroke=c.stroke.Color end
    local mw,mh,mx=pt and 72 or ph and 60 or 104,pt and 52 or ph and 36 or 54,pt and 11 or ph and 9 or 13
    K.box(c.picture,mx,(h-mh)/2,mw,mh)
    if c.map~=f.rules.map or c.drawW~=mw then local changed=c.map~=f.rules.map;c.map=f.rules.map;c.drawW=mw
        if changed then c.raster:setPreview(Maps.preview(c.map))end
        task.defer(function()if c.frame.Parent then c.raster:fit();c.raster:draw();if c.raster.label then K.round(c.raster.label,pt and 6 or 4)end end end)end
    local tx=mx+mw+(pt and 10 or ph and 10 or 16)
    local countText,maxText=tostring(f.count),' / '..tostring(f.rules.maximum)
    if pt then maxText='/'..tostring(f.rules.maximum)end
    c.count.Text=countText;c.max.Text=maxText
    local counting=f.remaining~=nil and f.phase~='transferring'
    c.time.Text=counting and clock(f.remaining-elapsed)or '–';c.time.TextColor3=counting and C.accent or C.dim
    local teamsShown=f.teamPlan~=nil
    if pt then
        local bw,bh=64,44;local bx=w-11-bw
        c.join:place(bx,(h-bh)/2,bw,bh);c.join:setText(text);c.join:setKind(mine and 'plain'or 'out');c.join:setEnabled(on or mine)
        if mine then c.join.label.TextColor3=C.accent end
        local right=bx-10
        c.title.TextSize=15;local nw=math.min(width(title(f),15,c.title)+2,right-tx-40)
        c.title.Text=title(f);K.box(c.title,tx,19,nw,18)
        c.mode.Text=modeText(f);c.mode.TextSize=12;K.box(c.mode,tx+nw+6,21,math.max(0,right-tx-nw-6),14)
        c.teams.Visible=teamsShown
        if teamsShown then local mw3=math.min(width(c.mode.Text,12,c.mode)+2,math.max(0,right-tx-nw-6));K.box(c.teams,tx+nw,12,mw3+12,32)end
        c.bar:set(math.clamp(f.count/math.max(1,f.rules.maximum),0,1),false);K.box(c.bar.frame,tx,47,70,5)
        local cw=width(countText,12,c.count);local mw2=width(maxText,12,c.max)
        c.count.TextColor3=C.muted;K.box(c.count,tx+78,41,cw+1,17);K.box(c.max,tx+78+cw,41,mw2+1,17)
        K.box(c.time,tx+78+cw+mw2+8,41,40,17);c.time.TextSize=12
        c.state.Visible=false
        return
    end
    local pad=ph and 8 or 12;local chev=ph and 16 or 20;local gap=ph and 10 or 16
    local timeW,countW=ph and 40 or 56,ph and 54 or 80
    local cx=w-pad-chev
    K.box(c.chev,cx,(h-chev)/2,chev,chev)
    local tX=cx-gap-timeW;local nX=tX-gap-countW
    local fs=ph and 14 or 19
    c.count.TextSize=fs;c.max.TextSize=fs
    local mw2=width(maxText,fs,c.max);local cw=width(countText,fs,c.count)
    K.box(c.max,nX+countW-mw2-1,(h-fs-9)/2,mw2+1,fs+9);K.box(c.count,nX+countW-mw2-cw-1,(h-fs-9)/2,cw+1,fs+9)
    c.time.TextSize=ph and 13 or 17;K.box(c.time,tX,(h-c.time.TextSize-8)/2,timeW,c.time.TextSize+8)
    local word=not plain and not mine
    c.state.Visible=word;c.time.Visible=not word;c.chev.Visible=not word
    if word then c.state.Text=text;c.state.TextSize=ph and 12 or 13;c.state.TextColor3=on and C.accent or C.muted;K.box(c.state,tX-8,0,w-pad-(tX-8),h)end
    local right=nX-8
    local ts=ph and 13 or 17;c.title.TextSize=ts;c.title.Text=title(f)
    local th=ts+3;local chh=ph and 16 or 20;local block=th+2+chh;local ty=math.floor((h-block)/2)
    K.box(c.title,tx,ty,right-tx,th)
    local key=f.kind=='custom'and 'custom'or modeKey(f)
    if c.chipKey~=key..modeText(f)..c.fmt then c.chipKey=key..modeText(f)..c.fmt;if c.chip then c.chip:Destroy()end
        local ink=key=='custom'and C.prime or S.MODE[key];local fill=key=='custom'and C.prime or S.MODEFILL[key]
        c.chip=S.modeChip(c.press.face,'ModeChip',modeText(f),ink,fill,chh,11,.18);c.chip.ZIndex=4;for _,o in ipairs(c.chip:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=5 end end
    end
    c.chip.Position=UDim2.fromOffset(tx,ty+th+2);c.mode.Visible=false
    local main=f.kind~='custom'and f.rules.special and Tags.mainModifier(f.rules.modifiers);local rule=main and Tags.modifierShort[main]
    if c.ruleKey~=tostring(rule)..c.fmt then c.ruleKey=tostring(rule)..c.fmt;if c.rule then c.rule:Destroy();c.rule=nil end
        if rule then c.rule=S.modeChip(c.press.face,'RuleChip',rule,C.gold,C.gold,chh,11,.18);c.rule.ZIndex=4;for _,o in ipairs(c.rule:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=5 end end end
    end
    if c.rule then local rx=tx+c.chip.Size.X.Offset+6;c.rule.Position=UDim2.fromOffset(rx,ty+th+2);c.rule.Visible=rx+c.rule.Size.X.Offset<=right end
    c.teams.Visible=teamsShown
    if teamsShown then K.box(c.teams,tx-6,ty+th+2-6,c.chip.Size.X.Offset+12,chh+12)end
end
function M:render()
    if not self.width then return end
    local want=self.inMenu and self.expanded and not self.suppressed
    self.shortcut.Visible=false
    local fmt=self.fmt;local pt,ph=fmt=='pt',fmt=='ph'
    local elapsed=os.clock()-self.updated;local ranked=self.filter=='ranked'
    self.lookup={};for _,f in ipairs(self.fields or {})do if PartyPlay.assess(f,self.party,self.queue and self.queue.field)then self.lookup[f.id]=f end end
    if self.watchButton then
        local n=self.liveCount or 0
        if self.watchCount~=n then self.watchCount=n;self:buildHead()end
    end
    local pick=self:quickPick()
    if self.quick then
        self.quick.button.Visible=pt and not ranked and not self.queue and pick~=nil
        self.quick:setEnabled(not self.busy and pick~=nil)
    end
    local listTop=self.listTop+(pt and self.quick and self.quick.button.Visible and 68 or 0)
    K.box(self.list,self.listX-12,listTop-4,self.listW+24,self.listBottom-listTop+8)
    local pad=self.list:FindFirstChild('Pad20');if pad then pad.PaddingLeft=UDim.new(0,12);pad.PaddingRight=UDim.new(0,12)end
    local lw=self.listW
    for id,c in pairs(self.cards)do if not self.lookup[id]or c.fmt~=fmt then c.raster:destroy();c.frame:Destroy();self.cards[id]=nil else c.frame.Visible=false end end
    local rh=pt and 76 or ph and 50 or 72;local gap=pt and 6 or ph and 5 or 10
    local party=self.party;local grouped=party and #party.users>1;local follower=grouped and party.leader~=self.userId
    local mineId=self.queue and self.queue.field
    local lit=mineId or (not self.queue and pick and pick.id)
    local y,index,rows=0,0,{}
    if not ranked then
        for _,id in ipairs(self.order)do local f=self.lookup[id]
            if f and (self.filter=='all'or self.filter==f.kind)and (self.sub=='all'or self.sub=='pvp'and f.rules.mode~='coop'or self.sub==f.rules.mode)then
                local c=self:card(f,fmt);c.frame.Visible=true;index+=1
                self:paintCard(c,0,y,lw,rh,elapsed,not pt and lit==f.id or pt and mineId==f.id)
                require(script.Parent.TelemetryClient).card(c.frame,f,index,'list')
                table.insert(rows,c.frame);y+=rh+gap
            end
        end
    end
    require(script.Parent.TelemetryStep).change('fieldsEmpty','lobby','fieldsEmpty',{item=require(script.Parent.TelemetryStep).code(tostring(self.filter or 'all')..'_'..tostring(self.sub or 'any')),total=index,result=index==0 and 'shown'or 'closed',reason=index==0 and (self.directoryError and 'network'or grouped and 'party'or 'none')or nil})
    self.empty.Visible=index==0
    self.empty.Text=ranked and '랭크전 준비 중'or self.directoryError and '연결 확인 중…'or grouped and '파티 전장 0'or self.filter=='custom'and '열린 방 0'or '전장 목록을 확인하는 중…'
    K.box(self.empty,0,16,lw,40)
    local ec=index==0 and (self.filter=='custom'or grouped)and not self.directoryError and not ranked
    self.emptyCreate.button.Visible=ec
    if ec then self.emptyCreate:setText(self.sub=='pvp'and not grouped and '대전 방 만들기'or '협동 방 만들기');self.emptyCreate:place(math.floor((lw-220)/2),64,220,44);self.emptyCreate:setEnabled(not self.busy and not follower)end
    S.canvas(self.list,index==0 and (ec and 116 or 64)or y-gap)
    if want then
        if not self.frame.Visible or self.leavingNow or self.entering then
            local fresh=not self.frame.Visible or self.leavingNow
            self.frame.Visible=true;self.leavingNow=nil;self.entering=nil
            if fresh and not K.reduced then
                self.frame.BackgroundTransparency=1
                Tween:Create(self.frame,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=self.dimAlpha}):Play()
                self.sheet:SetAttribute('Shown20',false);K.rehome(self.sheet)
                K.appear(self.sheet,{dx=pt and 0 or 24,dy=pt and 24 or 0,t=pt and .16 or .18,noFade=true})
                S.stagger(rows,true)
            else self.frame.BackgroundTransparency=self.dimAlpha end
        end
    elseif self.frame.Visible and not self.leavingNow then
        if self.closing and not K.reduced and self.inMenu then
            self.leavingNow=true
            Tween:Create(self.frame,TweenInfo.new(pt and .10 or .12,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
            K.rehome(self.sheet)
            K.leave(self.sheet,{dx=pt and 0 or 24,dy=pt and 24 or 0,t=pt and .10 or .12,noFade=true},function()
                if self.leavingNow then self.leavingNow=nil;self.frame.Visible=false;self.sheet.Visible=true end
            end)
        else self.frame.Visible=false end
    end
    self.closing=nil
    self.bar.Visible=self.queue~=nil and not self.barDocked and not self.barHidden
    self.bar.ZIndex=(want or self.barRaised)and 41 or 23
    self.suggested=QueueUI.suggestion(self.queue,{fields=self.fields,unavailable=self.directoryError},self.directoryNow and self.directoryNow+elapsed,grouped and #party.users or 1)
    if self.q20 then
        self.practiceAvailable=Flow.practice(self.queue,self.directoryNow and self.directoryNow+elapsed,self.practicing)
        local room=self.queue and self.queue.room~=nil and self.queue.phase~='transferring'
        local sv=(room or self.suggested~=nil or self.practiceAvailable or self.queue and self.queue.mode=='custom')and self.inMenu==true
        local q=self.queue
        require(script.Parent.QueueBar20).paint(self,q,{title=title({rules=q and q.rules or {map='world'}}),clock=clock,elapsed=elapsed,busy=self.busy,
            suggestVisible=sv,suggestText=room and '대기실'or q and q.mode=='custom'and '방 보기'or self.suggested and '사람 있는 전장'or '기다리며 연습',
            suggestOn=not self.busy and not(q and q.locked),screenWidth=self.screenWidth,screenHeight=self.screenHeight,z=self.bar.ZIndex})
        return
    end
    for _,o in ipairs(self.bar:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=self.bar.ZIndex+1 end end
    if self.queue then local q=self.queue
        self.barText.Text=title({rules=q.rules or {map='world'}})..' '..q.count..'/'..q.max..'\n'..(q.phase=='transferring'and '이동 중…'or q.phase=='recovering'and '연결 확인 중…'or q.remaining and '출발 '..clock(q.remaining-elapsed)or q.mode=='custom'and '준비 대기'or q.needsOpponent and '상대 진영 모집 중'or '곧 출발')
        if q.mode=='ranked'then self.barText.Text=string.format('랭크 %s  %s',q.ladder=='clanwar'and '클랜전'or q.ladder=='2v2'and '2대2'or q.ladder=='ffa'and '개인전'or '1대1',q.phase=='transferring'and '상대 찾음, 이동 중…'or '상대 찾는 중')end
        self.cancel.Text=q.partyCount and '파티 대기 취소'or '대기 취소';UI.enabled(self.cancel,not self.busy and not q.locked)
    end
    self.practiceAvailable=Flow.practice(self.queue,self.directoryNow and self.directoryNow+elapsed,self.practicing)
    local room=self.queue and self.queue.room~=nil and self.queue.phase~='transferring'
    self.suggest.Visible=(room or self.suggested~=nil or self.practiceAvailable or self.queue and self.queue.mode=='custom')and self.inMenu;self.suggest.Text=room and '대기실'or self.queue and self.queue.mode=='custom'and '방 보기'or self.suggested and '사람 있는 전장'or '기다리며 연습'
    UI.enabled(self.suggest,not self.busy and not(self.queue and self.queue.locked))
    local bw=self.bar.Size.X.Offset;local bl=QueueUI.layout(bw,self.suggest.Visible);self.barHeight=bl.height
    if self.screenWidth then UI.box(self.bar,(self.screenWidth-bw)/2,self.screenHeight-bl.height-8,bw,bl.height)end
    for name,r in pairs({barText=bl.state,suggest=bl.suggest,cancel=bl.cancel})do UI.box(self[name],r.x,r.y,r.w,r.h)end
end
function M:buildHead()
    local fmt=self.fmt;local pt=fmt=='pt';local sw=self.sw
    if self.head then for _,o in ipairs(self.head)do o:Destroy()end end
    local parent=self.sheet;local made={}
    local before={};for _,o in ipairs(parent:GetChildren())do before[o]=true end
    local h=S.head(parent,fmt,sw,'공식 전장',function()self:setOpen(false)end)
    local n=self.liveCount or 0;self.watchCount=n
    local watch,ww=S.headButton(parent,'Watch',fmt,'watch','관전',function()self.callbacks.watch()end,n>0 and tostring(n)or nil,'live')
    watch:place(h.right-ww,h.y+(h.h-watch.h)/2,ww,watch.h);local right=h.right-ww-(pt and 8 or 10)
    self.watchButton=watch
    local create
    if pt then
        create=S.iconButton(parent,'Create','plus',40,18,function()self.callbacks.create()end)
        create:place(right-40,h.y,40,40)
    else
        local cw;create,cw=S.headButton(parent,'Create',fmt,'plus','방 만들기',function()self.callbacks.create()end)
        create:place(right-cw,h.y+(h.h-create.h)/2,cw,create.h)
    end
    for _,o in ipairs(parent:GetChildren())do if not before[o]then table.insert(made,o)end end
    for _,o in ipairs(made)do o.ZIndex=math.max(o.ZIndex,3)end
    self.head=made
    if self.quick then self.quick.button:Destroy();self.quick=nil end
    if pt then
        local q=K.button(parent,'QuickDeploy',{kind='pri',icon='quick',iconSize=20,text='빠른 참가',size=19,gap=10},function(b)K.confirm(b,true);self:quickJoin()end)
        q:place(16,64+50,sw-32,56);q.button.ZIndex=3;self.quick=q
    end
end
function M:layout(w,h)
    local fmt=S.format(w,h);self.screenHeight=h;self.screenWidth=w;self.short=h<500
    local q=self.queue;local bottom=q and not self.barDocked and not self.barHidden and (self.barHeight or 48)+8 or 0
    local x,y,sw,sh
    if fmt=='pt'then x,y,sw,sh=0,0,w,h else x,y,sw,sh=S.rect('board',w,h,fmt,bottom)end
    self.dimAlpha=fmt=='pt'and .05 or .28
    self.frame.BackgroundColor3=fmt=='pt'and S.PAGE or S.DIM;self.frame.ZIndex=fmt=='pt'and 28 or 40
    if not self.leavingNow and self.frame.Visible and not(self.sheet:GetAttribute('Moving20'))then self.frame.BackgroundTransparency=self.dimAlpha end
    local goal=UDim2.fromOffset(x,y)
    if self.sheet:GetAttribute('Moving20')then self.sheet:SetAttribute('Home20',goal)else self.sheet.Position=goal end
    self.sheet.Size=UDim2.fromOffset(sw,sh)
    self.sheet.BackgroundTransparency=fmt=='pt'and 1 or 0;self.edge.Enabled=fmt~='pt'
    local key=fmt..':'..sw..'x'..sh
    if self.layoutKey~=key then self.layoutKey=key;self.fmt=fmt;self.sw,self.sh=sw,sh;self:buildHead()end
    self.fmt=fmt;self.width=sw;self.height=sh
    if fmt=='pt'then self.listX=16;self.listW=sw-32;self.listTop=64+50;self.listBottom=h-58-bottom-8
    else local p=fmt=='ph'and 12 or 24;self.listX=p+1;self.listW=sw-2*(p+1);self.listTop=fmt=='ph'and 47 or 73;self.listBottom=sh-p end
    if not self.q20 then local barW=math.min(690,w-24);UI.box(self.bar,(w-barW)/2,h-56,barW,48);UI.box(self.barText,14,4,barW-100,40);UI.box(self.cancel,barW-80,2,72,44)end
    self:render()
end
return M
