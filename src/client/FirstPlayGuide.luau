local UI=require(script.Parent.ToyUI)
local Audio=require(script.Parent.ToyAudio)
local Theme=require(script.Parent.Theme)
local Telemetry=require(script.Parent.TelemetryClient)
local Copy=require(script.Parent.Parent.Core.OnboardingPresentation)
local UIS=game:GetService('UserInputService')
local M={};M.__index=M
local function v2()local ok,H=pcall(require,script.Parent.Hud20);return ok and type(H)=='table'and H.ENABLED==true end
local K
local function kit()K=K or require(script.Parent.Kit20);return K end
function M.new(parent,view,callbacks)
    local self=setmetatable({view=view,callbacks=callbacks,v2=v2()},M)
    self.frame=UI.panel(parent,'Guide');self.frame.ZIndex=19;self.frame.Visible=false
    self.step=UI.pill(self.frame,'Step','1',UI.colors.accent)
    self.text=UI.label(self.frame,'Text','',14)
    local act={}
    act.skip=function()self:dismiss();callbacks.skip()end
    act.look=function()if self.data and self.data.target then view:focusAt(self.data.target)end end
    act.stay=function()self:dismiss()end
    act.city=function()
        if self.cityState and self.cityState.stage=='ready'and not self.state.paused then
            self.cityLesson=true;self.cityCompletedAt=nil;callbacks.city();self:update(self.state,true,self.context)
        end
    end
    self.act=act
    local host=self.frame
    if self.v2 then host=UI.make('Frame',self.frame,{Name='Legacy',BackgroundTransparency=1,Visible=false})end
    self.skip=UI.button(host,'Skip','건너뛰기',act.skip);self.skip.TextSize=14
    self.go=UI.button(host,'Look','찾기',act.look);self.go.TextSize=14
    self.stay=UI.button(host,'KeepPlaying','계속 플레이',act.stay,true)
    self.city=UI.button(host,'LearnCity','도시 건설',act.city)
    self.next=UI.button(host,'ChooseMode','계속 플레이',act.stay,true)
    self.ring=UI.make('Frame',parent,{Name='FirstPlayTarget',BackgroundTransparency=1,Size=UDim2.fromOffset(38,38),AnchorPoint=Vector2.new(.5,.5),Visible=false,ZIndex=7})
    UI.corner(self.ring,999);self.ringStroke=UI.stroke(self.ring,UI.colors.yellow,3)
    self.tag=UI.pill(self.ring,'Tap','시작 위치',UI.colors.yellow);self.tag.TextSize=14;UI.box(self.tag,-27,44,92,28)
    self.focus=UI.make('Frame',parent,{Name='FirstPlayFocus',BackgroundTransparency=1,Visible=false,ZIndex=20});UI.corner(self.focus,3);self.focusStroke=UI.stroke(self.focus,UI.colors.yellow,2)
    if self.v2 then self:build20()end
    self.frame:SetAttribute('NonBlocking',true)
    self.campaign=require(script.Parent.CampaignCoach).new(parent,view);require(script.Parent.CampaignCard).start()
    return self
end
function M:toMatch()
    self:dismiss()
end
function M:dismiss()
    if not self.dismissed then Telemetry.emit('tutorial_exit',{stage=self.stage=='grow'and 'grow'or self.stage=='done'and 'outcome'or 'shown',reason=self.stage=='done'and 'completed'or 'skipped',result=self.stage=='done'and 'complete'or 'skipped',version=self.version,duration_ms=self.telemetryAt and (os.clock()-self.telemetryAt)*1000 or 0})end
    self.dismissed=true;self.ring.Visible=false;self.focus.Visible=false
    if self.v2 and self.frame.Visible then K.leave(self.frame,{dy=-8,t=.10})else self.frame.Visible=false end
end
function M:update(s,enabled,context)
    if self.version~=s.version then self.version=s.version;self.dismissed=false;self.lastStage=nil;self.initialFocus=false;self.cityLesson=false;self.cityCompletedAt=nil;self.needsLook=nil end
    self.state=s;local g=s.guide;self.data=g;self.context=context
    self.visible=g~=nil and not(s.drop and s.drop.active)and (enabled or g.intro)and not self.dismissed and (s.phase=='spawn'or s.phase=='playing')
    if self.campaign:update(s,context)and self.visible then self.campaign.frame.Visible=false end
    if not self.visible then
        if not(self.v2 and self.frame:GetAttribute('Moving20')=='out')then self.frame.Visible=false end
        self.ring.Visible=false;self.focus.Visible=false;return
    end
    self.cityState=Copy.city(s)
    local stage=self.cityLesson and 'city'or g.stage;self.stage=stage
    if stage~=self.lastStage then
        if not self.lastStage then self.telemetryAt=os.clock();Telemetry.emit('tutorial_started',{stage='shown',intro=g.intro==true,version=s.version})end
        Telemetry.emit('tutorial_step',{stage=stage=='grow'and 'grow'or stage=='done'and 'outcome'or stage=='settle'and 'settled'or 'capture',result=g.intro and 'intro'or 'guide',version=s.version,duration_ms=(os.clock()-self.telemetryAt)*1000})
        Telemetry.step('tutorial','stage',{item=stage,duration_ms=(os.clock()-self.telemetryAt)*1000})
        if self.lastStage then Audio.play(stage=='done'and 'complete'or 'capture')end
        self.lastStage=stage;self.changedAt=os.clock()
    end
    if g.intro and not self.initialFocus and g.target and s.phase=='spawn'then self.initialFocus=true;self.view:focusAt(g.target)end
    self.step.Text=stage=='done'and '✓'or stage=='city'and '+'or tostring(g.intro and math.clamp(g.progress or 1,1,2)or math.min(3,(g.progress or 0)+1))
    self.frame:SetAttribute('Stage',stage)
    local ready=context.primary and context.primary.Visible and context.primary:GetAttribute('Enabled')~=false and context.action=='inspect'
    local valid=ready and (g.stage=='settle'or context.enemyLand)
    local text=Copy.instruction(stage,valid,(g.targetOwner or 0)>0,require(script.Parent.InputMode).touch())
    if stage=='grow'then text=Copy.recruitmentHint(s,context.trend)end
    if stage=='done'and g.intro then text='부족 2곳 흡수하면 승리'end
    if stage=='city'then
        local city=self.cityState
        if city.stage=='complete'then text='도시 완공, 병력 상한 '..Theme.troops(s.player.cap);if not self.cityCompletedAt then Telemetry.step('tutorial','cityDone',{result='complete',duration_ms=(os.clock()-(self.telemetryAt or os.clock()))*1000})end;self.cityCompletedAt=self.cityCompletedAt or os.clock()
        elseif city.stage=='building'then text='도시 건설 중'
        elseif city.stage=='saving'then text='도시 골드 모으는 중'
        elseif context.action=='City'and context.primary and context.primary.Visible and context.primary.Active then text='건설'
        else text='내 땅에 도시 자리 고르기'end
    end
    self.text.Text=s.paused and '일시정지'or text
    self.frame:SetAttribute('Lesson',stage=='grow'and text or nil)
    self.step.BackgroundColor3=stage=='grow'and context.trend and (context.trend.tone=='falling'and UI.colors.recruitmentSlow or context.trend.tone=='rising'and UI.colors.good or UI.colors.muted)or UI.colors.accent
    self.highlight=stage=='grow'and context.troops or stage=='city'and context.action=='City'and context.primary and context.primary.Visible and context.primary or valid and context.primary or nil
    self.ringWanted=not s.paused and not context.sheet and stage~='city'and (g.stage=='settle'or g.stage=='expand'or g.stage=='again')and g.target~=nil
    self.go.Visible=self.ringWanted and self.needsLook~=false;self.step.Visible=true
    self.introDone=stage=='done'and g.intro==true
    self.skip.Text=(stage=='done'or stage=='city')and '닫기'or '안내 끄기'
    self.skip.Visible=not self.introDone
    self.stay.Visible=(stage=='done'and not g.intro)or stage=='city'
    self.next.Visible=stage=='done'and g.intro
    self.city.Visible=stage=='done'and not g.intro and self.cityState.stage=='ready'
    self.city.Text=self.cityState.stage=='saving'and ('도시 '..Theme.number(self.cityState.cost or '0'))or '도시 건설'
    UI.enabled(self.city,self.cityState.stage=='ready'and not s.paused)
    self.blocked=context.blocked
    self.compact=false
    self.frame.Visible=not context.blocked
    self:layout(self.frame.Parent.AbsoluteSize/Theme.scale)
end
function M:build20()
    kit()
    local f=self.frame;local p={};self.p20=p
    for _,s in ipairs(f:GetChildren())do if s:IsA('UIStroke')and s.Name~='Stroke20'then s.Enabled=false end end
    f.BackgroundColor3=Color3.fromRGB(12,17,24);f.BackgroundTransparency=.14;K.round(f,10);K.stroke(f,K.colors.line,1,.1,true)
    local step=self.step;K.round(step,4);step.TextColor3=K.colors.bg;step.ZIndex=f.ZIndex+1
    for _,s in ipairs(step:GetChildren())do if s:IsA('UIStroke')then s.Enabled=false end end
    local t=self.text;t.TextColor3=K.colors.ink;if K.fonts[700]then t.FontFace=K.fonts[700]end;t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd
    t.TextXAlignment=Enum.TextXAlignment.Left;t.TextYAlignment=Enum.TextYAlignment.Center;t.ZIndex=f.ZIndex+1
    local function button(key,name,kind,size)
        local b=K.button(f,name,{kind=kind,text='',size=size,weight=kind=='pri'and 800 or 700,hit=44},self.act[key])
        b.button.ZIndex=f.ZIndex+2;b.face.ZIndex=f.ZIndex+2;b.label.ZIndex=f.ZIndex+3;b.button.Visible=false;return b
    end
    p.skip=button('skip','Skip','plain',12)
    p.look=button('look','Look','none',12);p.look.label.TextColor3=K.colors.accent
    p.stay=button('stay','KeepPlaying','pri',16)
    p.city=button('city','LearnCity','plain',15)
    p.next=button('stay','ChooseMode','pri',16)
    f:GetPropertyChangedSignal('Visible'):Connect(function()if f.Visible and f:GetAttribute('Moving20')~='in'then f:SetAttribute('Shown20',false);K.appear(f,{dy=-8,t=.14})end end)
    self.ringStroke.Color=K.colors.accent;self.ringStroke.Thickness=2
    self.focusStroke.Color=K.colors.accent;K.round(self.focus,8)
    local tag=self.tag;tag.BackgroundColor3=Color3.fromRGB(12,17,24);tag.BackgroundTransparency=.14;tag.TextColor3=K.colors.accent;tag.TextSize=12
    if K.fonts[800]then tag.FontFace=K.fonts[800]end;K.round(tag,6);K.stroke(tag,K.colors.accent,1,.45,true)
    local function fitTag()
        local w=K.width(require(script.Parent.Localization).text(tag.Text),12,tag)+16;w+=w%2
        tag.Size=UDim2.fromOffset(w,22);tag.Position=UDim2.fromOffset(19-w//2,44)
    end
    tag:GetPropertyChangedSignal('Text'):Connect(fitTag);fitTag()
end
local function format(size)
    local touch=require(script.Parent.InputMode).touch()
    if not touch or require(script.Parent.Parent.Core.InterfacePlacement).tablet(size.X,size.Y,touch)then return 'pc'end
    return size.Y>size.X and 'pt'or 'ph'
end
function M:layout20(size)
    local f=self.frame;local p=self.p20;local L=require(script.Parent.Localization)
    local fmt=format(size);local pc=fmt=='pc'
    local done,city=self.stage=='done',self.stage=='city'
    local strip=not(done or city)or(not pc and self.introDone)
    local h=pc and 48 or fmt=='ph'and 36 or 40
    local w,x,y
    if fmt=='ph'then
        local left,right=110,size.X-140;w=math.min(strip and 400 or 380,right-left);x=left+math.floor((right-left-w)/2);y=8
    elseif fmt=='pt'then
        w=size.X-24;x=12
        local parent=f.Parent;local clock=parent and parent:FindFirstChild('MatchStatus')
        y=clock and clock.Visible and clock.Position.Y.Offset+clock.Size.Y.Offset+8 or 94
        local chip=parent and parent:FindFirstChild('CampaignTask20');if chip and chip.Visible then y=math.max(y,chip.Position.Y.Offset+chip.Size.Y.Offset+6)end
    else w=math.min(strip and 480 or 440,size.X-24);x=math.floor((size.X-w)/2);y=8 end
    local total=strip and h or h+56
    local step=self.step;local cs=pc and 24 or 22;local pad=pc and 12 or 8
    if step.BackgroundColor3==UI.colors.good then step.BackgroundColor3=K.colors.accent end
    local digit=string.match(step.Text,'^%d+$')~=nil
    step.FontFace=digit and K.fonts.num or K.fonts[800]or step.FontFace;step.TextSize=14
    K.box(step,pad,math.floor((h-cs)/2),cs,cs)
    if self.step20~=step.Text then if self.step20 then K.punch(step,1.12,.16)end;self.step20=step.Text end
    local skipOn=self.skip.Visible or(strip and self.introDone)
    local bh=pc and 28 or 26;local rx=w-pad
    p.skip.button.Visible=skipOn
    if skipOn then
        p.skip:setText(self.skip.Text)
        local sw=K.width(L.text(p.skip.label.Text),12,p.skip.label)+20;rx-=sw;p.skip:place(rx,math.floor((h-bh)/2),sw,bh);rx-=6
    end
    p.look.button.Visible=self.go.Visible
    if self.go.Visible then
        p.look:setText(self.go.Text);local lw=K.width(L.text(p.look.label.Text),12,p.look.label)+16;rx-=lw;p.look:place(rx,math.floor((h-bh)/2),lw,bh);rx-=4
        p.look.label.TextColor3=K.colors.accent
    end
    local tx=pad+cs+10;local tw=math.max(40,rx-tx-4)
    local t=self.text;K.box(t,tx,0,tw,h)
    local size0=pc and 14 or 13;local msg=L.text(t.Text);local s=size0
    while s>12 and K.width(msg,s,t)>tw do s-=1 end;t.TextSize=s
    for _,k in ipairs({'stay','city','next'})do p[k].button.Visible=false end
    if not strip then
        local by=h+2;local half=math.floor((w-pad*2-8)/2)
        local list={}
        if self.next.Visible then table.insert(list,{p.next,self.next.Text})end
        if self.stay.Visible then table.insert(list,{p.stay,city and '안내 닫기'or '계속 플레이'})end
        if self.city.Visible then table.insert(list,{p.city,self.city.Text})end
        for i,it in ipairs(list)do
            local b=it[1];b.button.Visible=true;b:setText(it[2])
            if #list==1 then b:place(pad,by,w-pad*2,44)else b:place(pad+(i-1)*(half+8),by,half,44)end
            M.fill(b)
        end
        p.city:setEnabled(self.city:GetAttribute('Enabled')~=false)
    end
    local pos=UDim2.fromOffset(x,y)
    f.Size=UDim2.fromOffset(w,total);f:SetAttribute('Home20',pos);if f:GetAttribute('Moving20')==nil then f.Position=pos end
end
function M.fill(b)local l=b.label;if l then l.Position=UDim2.new();l.Size=UDim2.fromScale(1,1);l.TextXAlignment=Enum.TextXAlignment.Center end end
function M:layout(size)
    if self.v2 then self:layout20(size);return end
    local w=math.min(430,size.X-20);local done=self.stage=='done';local city=self.stage=='city'
    local h=(done or city)and 108 or 64
    if self.compact then
        UI.box(self.frame,(size.X-w)/2,8,w,32);UI.box(self.step,6,4,24,24);UI.box(self.text,36,0,w-44,32);self.text.TextSize=12
        for _,b in ipairs({self.skip,self.go,self.stay,self.city,self.next})do b.Visible=false end;return
    end
    local Style=require(script.Parent.HudStyle)
    local touch=require(script.Parent.InputMode).touch();local phone=touch and size.Y<500 and size.X>size.Y and size.X>=560
    Style.round(self.frame,phone and 10 or 8);self.frame.BackgroundColor3=Style.colors.panel;self.frame.BackgroundTransparency=.08
    Style.round(self.step,6);self.step.TextColor3=Theme.colors.bg;self.step.Font=Enum.Font.BuilderSansBold
    for _,b in ipairs({self.skip,self.go})do b.BackgroundColor3=Style.colors.chip;b.BackgroundTransparency=0;b.TextColor3=Theme.colors.ink;Style.round(b,6);Style.line(b,Style.colors.line,1)end
    self.text.TextWrapped=not phone;self.text.TextTruncate=phone and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
    if phone and not city and (not done or self.introDone)then
        if self.introDone then self.next.Visible=false;self.skip.Visible=true end
        local x0=134;local right=size.X-52-104-12-8-8
        w=math.max(220,right-x0)
        UI.box(self.frame,x0,8,w,36);UI.box(self.step,6,6,24,24);self.step.TextSize=14
        local closeW=40;local lookW=self.go.Visible and 52 or 0
        self.skip.Text='×';self.skip.TextSize=18;self.skip.BackgroundTransparency=1;UI.box(self.skip,w-48,-6,48,48)
        UI.box(self.go,w-closeW-lookW-8,-6,lookW,48);self.go.TextSize=13;self.go.BackgroundTransparency=1;self.go.TextColor3=Theme.colors.accent
        for _,b in ipairs({self.skip,self.go})do local s=b:FindFirstChildOfClass('UIStroke');if s then s.Enabled=false end end
        self.text.TextSize=13;UI.box(self.text,36,0,w-36-closeW-lookW-10,36)
        return
    end
    local bh=touch and 48 or 36;local row=touch and 64 or 56
    self.text.TextSize=15;h=(done or city)and 108 or row;w=math.min(600,size.X-20)
    local gy=size.X<620 and size.Y>size.X and 8+62+8+48+6 or 8
    UI.box(self.frame,(size.X-w)/2,gy,w,h);UI.box(self.step,10,(row-32)/2,32,32);self.step.TextSize=17
    local skipW=self.skip.Text=='×'and 48 or 98
    UI.box(self.text,52,0,w-(self.go.Visible and 52+skipW+8+84+12 or self.introDone and 182 or (self.skip.Visible and 52+skipW+16 or 60)),row)
    UI.box(self.skip,w-skipW-10,(row-bh)/2,skipW,bh);UI.box(self.go,w-skipW-10-8-84,(row-bh)/2,84,bh)
    local half=(w-28)/2
    UI.box(self.stay,8,56,(self.city.Visible or self.next.Visible)and half or w-16,48)
    UI.box(self.city,16+half,56,half,48);UI.box(self.next,16+half,56,half,48)
    self.stay.Text=city and '안내 닫기'or '계속 플레이'
    if self.introDone then UI.box(self.next,8,56,w-16,48);UI.box(self.stay,w-128,4,120,48);self.stay.Text='더 연습하기'
        self.stay.BackgroundColor3=UI.colors.raised;self.stay.TextColor3=UI.colors.ink
    else self.stay.BackgroundColor3=UI.colors.accent;self.stay.TextColor3=UI.colors.bg end
end
function M:stepFrame(reduced)
    self.campaign:stepFrame(reduced)
    if self.blocked or not self.visible or self.dismissed or not (self.view and self.view.map)then self.ring.Visible=false;self.focus.Visible=false;return end
    local ok20,H20=pcall(require,script.Parent.Hud20)
    local wave=(reduced or ok20 and H20.ENABLED)and 0 or (math.sin(os.clock()*4)+1)/2
    self.ringStroke.Transparency=wave*.35;self.focusStroke.Transparency=wave*.3
    local g=self.data;self.ring.Visible=self.ringWanted and g and g.target~=nil
    if self.ring.Visible then
        local p=self.view:project(g.target);local size=self.frame.Parent.AbsoluteSize/Theme.scale
        local bottom=math.min(size.Y-125,(self.context and self.context.hudTop or size.Y)-80)
        self.ring.Position=UDim2.fromOffset(p.X,p.Y);self.ring.Visible=p.X>25 and p.X<size.X-25 and p.Y>90 and p.Y<bottom
        self.tag.Text=g.stage=='settle'and '시작 위치'or (g.targetOwner or 0)>0 and '공격 대상'or '확장 위치'
    end
    local needsLook=self.ringWanted and not self.ring.Visible
    if self.needsLook~=needsLook then
        self.needsLook=needsLook;self.go.Visible=needsLook;if needsLook then Telemetry.step('tutorial','targetOffscreen',{item=self.stage})end;self:layout(self.frame.Parent.AbsoluteSize/Theme.scale)
    end
    self.focus.Visible=self.highlight~=nil
    if self.highlight then
        local target=self.highlight;local origin=self.frame.Parent.AbsolutePosition
        local s=Theme.scale;UI.box(self.focus,(target.AbsolutePosition.X-origin.X)/s-4,(target.AbsolutePosition.Y-origin.Y)/s-4,target.AbsoluteSize.X/s+8,target.AbsoluteSize.Y/s+8)
    end
end
return M
