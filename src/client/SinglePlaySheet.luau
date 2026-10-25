local K=require(script.Parent.Kit20)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Campaign=require(script.Parent.Parent.Core.CampaignRules)
local Daily=require(script.Parent.Parent.Core.DailyOperation)
local Commands=require(script.Parent.Parent.Core.CommandPresentation)
local Flow=require(script.Parent.Parent.Core.PlayFlow)
local Step=require(script.Parent.TelemetryStep)
local Tween=game:GetService('TweenService')
local M={}
M.__index=M
local DIFFS={{'Easy','쉬움'},{'Medium','보통'},{'Hard','어려움'},{'Impossible','불가능'}}
local C=K.colors
local SHEET=Color3.fromRGB(15,21,29)

function M.new(home)
    local l=home.lobby;local self=setmetatable({home=home,lobby=l,open=false},M)
    self.frame=K.make('TextButton',l.frame,{Name='SinglePlay',Text='',AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(3,6,10),BackgroundTransparency=.28,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Visible=false,ZIndex=40,Active=true})
    self.frame.Activated:Connect(function()self:close('outside')end)
    return self
end
function M:build(fmt)
    if self.built==fmt then return end
    if self.sheet then self.sheet:Destroy()end
    self.built=fmt;local l=self.lobby
    local s=K.make('Frame',self.frame,{Name='Sheet',BackgroundColor3=SHEET,BorderSizePixel=0,Active=true,ZIndex=41});K.round(s,fmt=='pt'and 16 or 8);K.stroke(s,C.line,1);self.sheet=s
    K.make('TextButton',s,{Name='Catch',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false,ZIndex=41})
    self.grip=K.make('Frame',s,{Name='Grip',BackgroundColor3=C.line,BorderSizePixel=0,Visible=fmt=='pt',ZIndex=42});K.round(self.grip,'pill')
    self.title=K.text(s,'Title','싱글 플레이',fmt=='pc'and 24 or fmt=='ph'and 18 or 20,C.ink,800);self.title.ZIndex=42
    self.custom=K.make('TextButton',s,{Name='Custom',Text='<u>나만의 설정</u>',RichText=true,TextSize=fmt=='pc'and 14 or 12,TextColor3=C.muted,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,ZIndex=42,TextXAlignment=Enum.TextXAlignment.Right})
    if K.fonts[700]then self.custom.FontFace=K.fonts[700]end
    self.custom.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');Step.step('single','pick',{item='custom'});self:close('custom');l.soloChoice='custom';l.deployment.callbacks.solo()end)
    self.closeButton=K.button(s,'Close',{kind='plain',icon='x',iconSize=fmt=='pc'and 20 or fmt=='ph'and 16 or 18},function()self:close('x')end)
    self.closeButton.faceStroke.Enabled=false;self.closeButton.iconColorFixed=true;self.closeButton.iconImage.ImageColor3=C.muted
    local hero={}
    hero.frame=K.make('Frame',s,{Name='Campaign',BackgroundColor3=C.ocean,BorderSizePixel=0,ZIndex=42});K.round(hero.frame,10)
    hero.hit=K.make('TextButton',hero.frame,{Name='Hit',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false,ZIndex=43})
    hero.hit.Activated:Connect(function()if not self.done then self:side('Campaign')end end)
    self.hero=hero
    local q=K.panel(s,'Quick','raised',8);q.ZIndex=42;q:FindFirstChild('Stroke20').Enabled=false
    local qi=K.icon(q,'quick',16,C.accent,'Icon');qi.ZIndex=43
    local qt=K.text(q,'Name','바로 한 판',15,C.ink,800);qt.ZIndex=43
    self.quick={frame=q,icon=qi,name=qt,buttons={}}
    for _,d in ipairs(DIFFS)do
        local b=K.button(q,'Diff_'..d[1],{kind='plain',text=d[2],size=15,weight=800},function()self:quickStart(d[1])end)
        b.button.ZIndex=43;b.face.ZIndex=43;b.label.ZIndex=44
        local dot=K.make('Frame',b.face,{Name='Recommend',BackgroundColor3=C.accent,BorderSizePixel=0,Visible=false,ZIndex=45});K.round(dot,'pill')
        self.quick.buttons[d[1]]={b=b,dot=dot}
    end
    local dl=K.panel(s,'Daily','raised',8);dl.ZIndex=42;dl:FindFirstChild('Stroke20').Enabled=false
    local daily={frame=dl}
    daily.icon=K.icon(dl,'daily',16,C.accent,'Icon');daily.title=K.text(dl,'Title','오늘의 도전',15,C.ink,800)
    daily.name=K.text(dl,'Name','',15,C.ink,700);daily.sub=K.text(dl,'Sub','',13,C.muted,600)
    daily.go=K.button(dl,'Go',{kind='out',text='도전',size=15,weight=800},function()self:side('Daily')end)
    for _,o in ipairs({daily.icon,daily.title,daily.name,daily.sub})do o.ZIndex=43 end
    daily.go.button.ZIndex=43;daily.go.face.ZIndex=43;daily.go.label.ZIndex=44
    self.daily=daily
end
function M:campaignView()
    local l=self.lobby;local p=l.account and l.account.progress or {}
    local cv=type(p.campaign)=='table'and p.campaign or {stars={},next=Campaign.stages[1].id}
    local st=Campaign.stage(cv.next)or Campaign.stages[1]
    local open=Campaign.unlocked({campaign={stars=cv.stars or {}}},st.id)
    local ch=Campaign.chapter(st.chapter)or {name=''}
    local pips={};for _,x in ipairs(Campaign.stages)do if x.chapter==st.chapter then local won=(tonumber((cv.stars or {})[x.id])or 0)%2==1;table.insert(pips,won and 'done'or x.id==st.id and 'next'or 'todo')end end
    return {pips=pips,stage=st,open=open,lesson=l.firstLesson==true,chapter=ch,done=require(script.Parent.Lobby20).campaignDone(p),total=cv.total or Campaign.total(p)}
end
local function clear(f)for _,o in ipairs(f:GetChildren())do if o.Name~='Hit'and not o:IsA('UICorner')and not o:IsA('UIStroke')then o:Destroy()end end end
function M:paintHero(fmt,w,h)
    local cv=self:campaignView();local st=cv.stage
    local key=table.concat({fmt,w,h,st.id,tostring(cv.done),tostring(cv.lesson),tostring(cv.open),table.concat(cv.pips,',')},'|')
    self.done=cv.done
    if self.heroKey==key then return end;self.heroKey=key
    local f=self.hero.frame;clear(f)
    local ph=fmt=='ph';local pt=fmt=='pt'
    local edge=K.make('Frame',f,{Name='Edge',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=48,Active=false});K.round(edge,10);K.stroke(edge,C.gold,2,cv.done and .45 or .15,true)
    local map=K.map(f,'Map',st.map,w,h,10,cv.done and .45 or nil);map.ZIndex=42
    local fade=cv.done and K.fadeBox(f,'Fade',Color3.fromRGB(8,10,14),.35,.92,10,.8,.92)or K.fadeBox(f,'Fade',Color3.fromRGB(8,10,14),.05,.92,10,.2,.05)
    fade.ZIndex=43
    if not cv.done then fade.UIGradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.95),NumberSequenceKeypoint.new(.2,.95),NumberSequenceKeypoint.new(pt and .75 or .78,.08),NumberSequenceKeypoint.new(1,.08)})end
    local pad=ph and 14 or pt and 14 or 22;local ci=ph and 12 or pt and 12 or 20;local cy=ph and 12 or pt and 12 or 18
    local chipText=cv.done and '캠페인 완료'or string.format('캠페인 %d장',st.chapter)
    local chip=K.chip(f,'Chip',chipText,'campaign',{size=ph and 12 or pt and 12 or 14,height=ph and 22 or pt and 22 or 26,icon=cv.done and 'check'or 'campaign'})
    chip.Position=UDim2.fromOffset(ci,cy);for _,o in ipairs(chip:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=45 end end;chip.ZIndex=44
    if cv.done then
        local barH=5;local gap=4;local n=#Campaign.chapters;local bw=(w-pad*2-gap*(n-1))/n
        local ts=ph and 22 or pt and 22 or 32;local ss=ph and 15 or pt and 15 or 18;local ws=ph and 12 or pt and 13 or 15
        local y=h-pad-(ws+4)-(ph and 6 or 10)-ss-(ph and 6 or 10)-(ts+8)-(ph and 6 or 10)-barH
        for i=1,n do local b=K.make('Frame',f,{Name='Chapter'..i,BackgroundColor3=C.gold,BorderSizePixel=0,ZIndex=44});K.round(b,'pill');K.box(b,pad+(i-1)*(bw+gap),y,bw,barH)end
        y+=barH+(ph and 6 or 10)
        local t=K.text(f,'Done','모든 작전 완료',ts,C.ink,800);t.ZIndex=44;K.box(t,pad,y,w-pad*2,ts+8);y+=ts+8+(ph and 6 or 10)
        local s=K.icon(f,'starFill',ss,C.gold,'Star');s.ZIndex=44;K.box(s,pad,y,ss,ss)
        local tot=K.num(f,'Total',string.format('%d / %d',cv.total,Campaign.maxStars),ss,C.gold);tot.ZIndex=44;K.box(tot,pad+ss+8,y-2,200,ss+4);y+=ss+(ph and 6 or 10)
        local wait=K.text(f,'Next','다음 업데이트를 기대해 주세요',ws,C.muted,700);wait.ZIndex=44;K.box(wait,pad,y,w-pad*2,ws+4)
        self.hero.go=nil
        return
    end
    local pw=ph and 22 or pt and 26 or 30;local ts=ph and 22 or pt and 22 or 32;local ks=ph and 12 or pt and 12 or 14
    local bw,bh=ph and 104 or pt and 96 or 150,ph and 46 or pt and 48 or 60
    local by=h-pad-bh
    local textBottom=h-pad;local taskY=textBottom-(ks+2);local nameY=taskY-4-(ts+15);local pipY=nameY-(ph and 8 or 12)-5
    if pt then pipY=nameY-8-5 end
    for i,k in ipairs(cv.pips)do local b=K.make('Frame',f,{Name='Pip'..i,BackgroundColor3=k=='done'and C.gold or C.ink,BackgroundTransparency=k=='todo'and .78 or 0,BorderSizePixel=0,ZIndex=44});K.round(b,'pill');K.box(b,pad+(i-1)*(pw+5),pipY,pw,5)end
    local idt=K.num(f,'Id',st.id,ts,C.gold);idt.ZIndex=44;local iw=K.width(st.id,ts,idt);K.box(idt,pad,nameY,iw+2,ts+15)
    local nm=K.text(f,'Name',st.name,ts,C.ink,800);nm.ZIndex=44;K.box(nm,pad+iw+(pt and 6 or 8),nameY,w-pad*2-bw-12-iw-8,ts+15)
    local ti=K.icon(f,'target',ks+2,C.ink,'TaskIcon');ti.ZIndex=44;ti.ImageTransparency=.15;K.box(ti,pad,taskY,ks+2,ks+2)
    local task=K.text(f,'Task',cv.lesson and((Maps.meta(st.map)or {}).label or st.map)or(st.task and st.task.label or ''),ks,C.ink,600);task.ZIndex=44;task.TextTransparency=.15
    K.box(task,pad+ks+2+(pt and 6 or 10),taskY,w-pad*2-bw-12-ks-12,ks+2)
    local go=K.button(f,'Go',{kind='pri',text=cv.lesson and '첫 작전'or cv.open and '출전'or '보기',size=ph and 18 or pt and 18 or 22},function(b)K.confirm(b,true);self:side('Campaign')end)
    go.button.ZIndex=45;go.face.ZIndex=45;go.label.ZIndex=46;go.shade.ZIndex=45
    go:place(w-pad-bw,by,bw,bh);self.hero.go=go
end
function M:refresh()
    if not self.built then return end
    local l=self.lobby;local p=l.account and l.account.progress or {}
    local rookie=require(script.Parent.Parent.Core.QuickSolo).rookie(p)
    local done=require(script.Parent.Lobby20).campaignDone(p)
    for key,t in pairs(self.quick.buttons)do
        local rec=key=='Easy'and(rookie or done)
        t.b:setKind(done and rec and 'pri'or 'plain')
        if not done and rec then t.b.faceStroke.Color=C.accent;t.b.faceStroke.Thickness=2;t.b.baseStroke=C.accent else t.b.faceStroke.Thickness=1 end
        t.dot.Visible=rec and not done
        t.b:setEnabled(not l.busy and not l.loading,true)
    end
    local op=Daily.current(p.dailyOp,os.time());local d=self.daily
    local on=op~=nil and (p.basicsComplete==true or p.tutorial==false or next(p.history or {})~=nil)
    if op then d.name.Text=(Maps.meta(op.map)or {}).label or op.map;d.sub.Text=op.done and string.format('오늘 완료, %s',op.bestLabel)or op.conditionName
    else d.name.Text='준비 중';d.sub.Text='첫 작전 뒤 열림'end
    if op and not on then d.sub.Text='첫 작전 뒤 열림'end
    d.reward=op and not op.done and on and(op.medals or 60)or nil
    d.mapKey=op and op.map or nil
    d.go:setText(op and op.done and '다시'or '도전');d.go:setEnabled(on and not l.busy and not l.loading)
    if self.hero.go then self.hero.go:setEnabled(not l.busy and not l.loading)end
end
function M:run(fn)
    local l=self.lobby
    if l.busy or l.loading then return end
    if require(script.Parent.Parent.Core.OnboardingPresentation).account(l.account)~='ready'or Commands.soloLoading(l)then self:close('save');l.deployment.callbacks.solo();return end
    local decision=Flow.single(l.data and l.data.queue)
    if decision=='moving'then return end
    self:starting()
    if decision=='replace'then l:request('cancel',nil,fn)else fn()end
end
function M:starting()
    self:close('start')
    local Veil=require(script.Parent.TransitionVeil);Veil.show('전장 준비 중…',6)
    local l=self.lobby;task.spawn(function()local untilAt=os.clock()+6;while os.clock()<untilAt and l.inMenu~=false do task.wait(.1)end;if l.inMenu~=false then Veil.hide()end end)
end
function M:quickStart(difficulty)
    local l=self.lobby;Step.step('single','pick',{item='quick_'..difficulty:lower()})
    self:run(function()l:closePage();l.callbacks.quick(difficulty)end)
end
function M:side(name)
    local l=self.lobby
    if name=='Campaign'then
        local cv=self:campaignView();Step.step('single','pick',{item=cv.lesson and 'lesson'or 'campaign'})
        if cv.lesson then self:run(function()l:closePage();l.callbacks.learn()end)
        elseif cv.open then if require(script.Parent.CampaignScreen).start(l,cv.stage.id)then self:starting()end
        else self:close('campaign');l.goalTab='campaign';l:openPage('missions')end
    else Step.step('single','pick',{item='daily'});self:run(function()l:closePage();l.callbacks.daily()end)end
end
function M:show()
    if self.open then return end;self.open=true;self.frame.Visible=true;self.entering=true
    Step.step('single','open',{item=self.lobby.firstLesson and 'lesson'or 'home'})
    self.lobby:layout()
end
function M:close(why)
    if not self.open then return end;self.open=false
    if why~='start'and why~='howto'and why~='custom'and why~='campaign'and why~='save'then Step.step('single','close',{result=why or 'x'})end
    local s=self.sheet
    if s and not K.reduced and why~='start'then
        local portrait=self.built=='pt'
        K.leave(s,{dx=portrait and 0 or 24,dy=portrait and 24 or 0,t=portrait and .10 or .12,noFade=true},function()if not self.open then self.frame.Visible=false end end)
        Tween:Create(self.frame,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
    else self.frame.Visible=false end
    self.lobby:layout()
end
local function place(o,x,y,w,h)K.box(o,x,y,w,h)end
function M:layout(w,h,portrait,short,top)
    if not self.open then if not(self.sheet and self.sheet:GetAttribute('Moving20')=='out')then self.frame.Visible=false end;return end
    local fmt=portrait and 'pt'or short and 'ph'or 'pc'
    self:build(fmt);self.frame.Visible=true
    self.frame.ZIndex=fmt=='pt'and 28 or 40
    local s=self.sheet;local sx,sy,sw,sh,pad
    if fmt=='pc'then sw,sh=900,470;sx,sy=(w-sw)/2,(h-sh)/2+20;pad=24
    elseif fmt=='ph'then sw,sh=w-24,h-58;sx,sy=12,50;pad=12
    else sx,sy,sw=0,86,w;sh=h-58-sy;pad=12 end
    if fmt=='pt'then place(s,sx,sy,sw,sh+16)else place(s,sx,sy,sw,sh)end
    if fmt=='pt'then place(self.grip,sw/2-20,7,40,4)end
    local hy,hh=fmt=='pc'and 14 or fmt=='ph'and 8 or 11,fmt=='pc'and 40 or fmt=='ph'and 30 or 40
    local xs=fmt=='pc'and 40 or fmt=='ph'and 32 or 40
    self.closeButton:place(sw-pad-xs,hy+(hh-xs)/2,xs,xs);self.closeButton.button.ZIndex=43;self.closeButton.face.ZIndex=43;self.closeButton.iconImage.ZIndex=44
    local tw=K.width('나만의 설정',self.custom.TextSize)
    place(self.custom,sw-pad-xs-(fmt=='pc'and 16 or 10)-tw-2,hy,tw+2,hh)
    place(self.title,fmt=='pt'and 16 or pad,hy+(fmt=='pt'and 8 or 0),200,hh-(fmt=='pt'and 16 or 0))
    local hx,hy2,hw,hh2,rx,rw,qh
    if fmt=='pc'then hx,hy2,hw=pad,pad+48,540;hh2=sh-pad*2-48;rx=hx+hw+16;rw=sw-rx-pad;qh=230
    elseif fmt=='ph'then hx,hy2,hw=pad,pad+34,352;hh2=sh-pad*2-34;rx=hx+hw+10;rw=sw-rx-pad;qh=150
    else hx,hy2,hw=12,59,sw-24;hh2=self.done and 186 or 214;rx,rw=12,sw-24;qh=150 end
    place(self.hero.frame,hx,hy2,hw,hh2);self:paintHero(fmt,hw,hh2)
    self.hero.hit.Visible=not self.done
    local qy=fmt=='pt'and hy2+hh2+10 or hy2
    local q=self.quick;place(q.frame,rx,qy,rw,qh)
    local qp=fmt=='pc'and 16 or fmt=='ph'and 10 or 12;local qs=fmt=='pc'and 17 or fmt=='ph'and 14 or 15;local qis=fmt=='pc'and 18 or 16
    place(q.icon,qp,qp+1,qis,qis);q.name.TextSize=qs;place(q.name,qp+qis+8,qp,rw-qp*2-qis-8,qs+3)
    local gap=fmt=='pc'and 8 or fmt=='ph'and 6 or 8;local bh=fmt=='pc'and 56 or fmt=='ph'and 36 or 44
    local gy=qp+qs+3+(fmt=='pc'and 14 or fmt=='ph'and 8 or 10);local cw=(rw-qp*2-gap)/2
    for i,d in ipairs(DIFFS)do local t=q.buttons[d[1]];t.b.label.TextSize=fmt=='pc'and 17 or fmt=='ph'and 14 or 15
        t.b:place(qp+((i-1)%2)*(cw+gap),gy+((i-1)//2)*(bh+gap),cw,bh);place(t.dot,cw-13,6,7,7)end
    local d=self.daily;local dy=qy+qh+(fmt=='pc'and 14 or fmt=='ph'and 8 or 10)
    local dh=fmt=='pt'and 71 or hy2+hh2-dy
    place(d.frame,rx,dy,rw,dh)
    local mw,mh=fmt=='pc'and 84 or fmt=='ph'and 56 or 64,fmt=='pc'and 50 or fmt=='ph'and 34 or 40
    if d.picKey~=(d.mapKey or '')..mw then d.picKey=(d.mapKey or '')..mw;if d.pic then d.pic:Destroy()end;d.pic=K.map(d.frame,'Map',d.mapKey,mw,mh,4);d.pic.ZIndex=43 end
    local reward=d.reward
    if d.coins then d.coins:Destroy();d.coins=nil end
    if reward then local as=fmt=='pc'and 15 or 13;local af,aw=K.amount(d.frame,'Coins','coin','+'..tostring(reward),as,C.gold);af.ZIndex=43;for _,o in ipairs(af:GetChildren())do o.ZIndex=44 end;d.coins=af;d.coinsW=aw end
    local gw,gh=fmt=='pc'and 84 or 60,fmt=='pc'and 44 or fmt=='ph'and 34 or 44
    if fmt=='pt'then
        place(d.pic,12,(dh-mh)/2,mw,mh)
        local tx=12+mw+10;place(d.icon,tx,19,14,14);d.title.TextSize=14;place(d.title,tx+20,17,140,18)
        d.sub.TextSize=12;d.sub.Text=d.name.Text~=''and(d.name.Text..', '..d.sub.Text)or d.sub.Text;d.name.Visible=false;place(d.sub,tx,37,rw-tx-12-gw-10-(d.coinsW or 0)-10,16)
        d.go:place(rw-12-gw,(dh-gh)/2,gw,gh)
        if d.coins then K.box(d.coins,rw-12-gw-10-d.coinsW,(dh-13)/2,d.coinsW,13)end
    else
        d.name.Visible=true
        local dp=fmt=='pc'and 16 or 10;local ts=fmt=='pc'and 17 or 14
        place(d.icon,dp,dp+1,fmt=='pc'and 18 or 16,fmt=='pc'and 18 or 16);d.title.TextSize=ts;place(d.title,dp+(fmt=='pc'and 18 or 16)+8,dp,160,ts+3)
        if d.coins then K.box(d.coins,rw-dp-d.coinsW,dp+(ts+3-(fmt=='pc'and 15 or 13))/2,d.coinsW,fmt=='pc'and 15 or 13)end
        local ry=dp+ts+3+(fmt=='pc'and 14 or 10)
        place(d.pic,dp,ry,mw,mh)
        d.go.label.TextSize=fmt=='pc'and 15 or 13;d.go:place(rw-dp-gw,ry+(mh-gh)/2,gw,gh)
        d.name.TextSize=fmt=='pc'and 15 or 13;d.sub.TextSize=fmt=='pc'and 13 or 11
        local tx=dp+mw+10;local tw2=rw-tx-dp-gw-8
        place(d.name,tx,ry+(mh-(d.name.TextSize+d.sub.TextSize+7))/2,tw2,d.name.TextSize+3);place(d.sub,tx,ry+(mh-(d.name.TextSize+d.sub.TextSize+7))/2+d.name.TextSize+4,tw2,d.sub.TextSize+3)
    end
    self:refresh()
    if self.entering then self.entering=false
        self.frame.BackgroundTransparency=1;Tween:Create(self.frame,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=.28}):Play()
        s:SetAttribute('Shown20',false);K.rehome(s)
        if fmt=='pt'then K.appear(s,{dy=24,t=.16,noFade=true})else K.appear(s,{dx=24,t=.18,noFade=true})end
    end
end
return M
