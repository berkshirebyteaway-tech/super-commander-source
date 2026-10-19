local UI=require(script.Parent.ToyUI)
local Audio=require(script.Parent.ToyAudio)
local Theme=require(script.Parent.Theme)
local Telemetry=require(script.Parent.TelemetryClient)
local Copy=require(script.Parent.Parent.Core.OnboardingPresentation)
local UIS=game:GetService('UserInputService')
local M={};M.__index=M
function M.new(parent,view,callbacks)
    local self=setmetatable({view=view,callbacks=callbacks},M)
    self.frame=UI.panel(parent,'Guide');self.frame.ZIndex=19;self.frame.Visible=false
    self.step=UI.pill(self.frame,'Step','1',UI.colors.accent)
    self.text=UI.label(self.frame,'Text','',14)
    self.skip=UI.button(self.frame,'Skip','건너뛰기',function()
        self:dismiss();callbacks.skip()
    end);self.skip.TextSize=14
    self.go=UI.button(self.frame,'Look','찾기',function()if self.data and self.data.target then view:focusAt(self.data.target)end end);self.go.TextSize=14
    self.stay=UI.button(self.frame,'KeepPlaying','계속 플레이',function()self:dismiss()end,true)
    self.city=UI.button(self.frame,'LearnCity','도시 건설',function()
        if self.cityState and self.cityState.stage=='ready'and not self.state.paused then
            self.cityLesson=true;self.cityCompletedAt=nil;callbacks.city();self:update(self.state,true,self.context)
        end
    end)
    self.next=UI.button(self.frame,'ChooseMode','계속 플레이',function()self:dismiss()end,true)
    self.ring=UI.make('Frame',parent,{Name='FirstPlayTarget',BackgroundTransparency=1,Size=UDim2.fromOffset(38,38),AnchorPoint=Vector2.new(.5,.5),Visible=false,ZIndex=7})
    UI.corner(self.ring,999);self.ringStroke=UI.stroke(self.ring,UI.colors.yellow,3)
    self.tag=UI.pill(self.ring,'Tap','시작 위치',UI.colors.yellow);self.tag.TextSize=14;UI.box(self.tag,-27,44,92,28)
    self.focus=UI.make('Frame',parent,{Name='FirstPlayFocus',BackgroundTransparency=1,Visible=false,ZIndex=20});UI.corner(self.focus,3);self.focusStroke=UI.stroke(self.focus,UI.colors.yellow,2)
    self.frame:SetAttribute('NonBlocking',true)
    return self
end
function M:toMatch()
    self:dismiss()
end
function M:dismiss()
    if not self.dismissed then Telemetry.emit('tutorial_exit',{stage=self.stage=='grow'and 'grow'or self.stage=='done'and 'outcome'or 'shown',reason=self.stage=='done'and 'completed'or 'skipped',result=self.stage=='done'and 'complete'or 'skipped',version=self.version,duration_ms=self.telemetryAt and (os.clock()-self.telemetryAt)*1000 or 0})end
    self.dismissed=true;self.frame.Visible=false;self.ring.Visible=false;self.focus.Visible=false
end
function M:update(s,enabled,context)
    if self.version~=s.version then self.version=s.version;self.dismissed=false;self.lastStage=nil;self.initialFocus=false;self.cityLesson=false;self.cityCompletedAt=nil;self.needsLook=nil end
    self.state=s;local g=s.guide;self.data=g;self.context=context
    self.visible=g~=nil and not(s.drop and s.drop.active)and (enabled or g.intro)and not self.dismissed and (s.phase=='spawn'or s.phase=='playing')
    if not self.visible then self.frame.Visible=false;self.ring.Visible=false;self.focus.Visible=false;return end
    self.cityState=Copy.city(s)
    local stage=self.cityLesson and 'city'or g.stage;self.stage=stage
    if stage~=self.lastStage then
        if not self.lastStage then self.telemetryAt=os.clock();Telemetry.emit('tutorial_started',{stage='shown',intro=g.intro==true,version=s.version})end
        Telemetry.emit('tutorial_step',{stage=stage=='grow'and 'grow'or stage=='done'and 'outcome'or stage=='settle'and 'settled'or 'capture',version=s.version,duration_ms=(os.clock()-self.telemetryAt)*1000})
        Telemetry.step('tutorial','stage',{item=stage,duration_ms=(os.clock()-self.telemetryAt)*1000})
        if self.lastStage then Audio.play(stage=='done'and 'complete'or 'capture')end
        if self.lastStage=='expand'and g.intro and self.callbacks.praise then self.callbacks.praise('첫 점령 성공. 영토가 넓어졌어요')end
        self.lastStage=stage;self.changedAt=os.clock()
    end
    if g.intro and not self.initialFocus and g.target and s.phase=='spawn'then self.initialFocus=true;self.view:focusAt(g.target)end
    self.step.Text=stage=='done'and '✓'or stage=='city'and '+'or tostring(g.intro and math.clamp(g.progress or 1,1,2)or math.min(3,(g.progress or 0)+1))
    self.frame:SetAttribute('Stage',stage)
    local ready=context.primary and context.primary.Visible and context.primary:GetAttribute('Enabled')~=false and context.action=='inspect'
    local valid=ready and (g.stage=='settle'or context.enemyLand)
    local text=Copy.instruction(stage,valid,(g.targetOwner or 0)>0,require(script.Parent.InputMode).touch())
    if stage=='grow'then text=Copy.recruitmentHint(s,context.trend)end
    if stage=='done'and g.intro then text=s.settings and s.settings.maxTimerValue and '준비 완료. 시간이 끝날 때 영토가 가장 넓으면 승리'or '준비 완료. 이 전장에서 계속 플레이하세요.'end
    if stage=='city'then
        local city=self.cityState
        if city.stage=='complete'then text='도시 완공, 병력 상한 '..Theme.troops(s.player.cap);if not self.cityCompletedAt then Telemetry.step('tutorial','cityDone',{result='complete',duration_ms=(os.clock()-(self.telemetryAt or os.clock()))*1000})end;self.cityCompletedAt=self.cityCompletedAt or os.clock()
        elseif city.stage=='building'then text='도시 건설 중, 전투와 확장을 계속하세요.'
        elseif city.stage=='saving'then text='골드가 부족해요. 확장하며 도시 비용을 모으세요.'
        elseif context.action=='City'and context.primary and context.primary.Visible and context.primary.Active then text='건설을 눌러 도시에 투자하세요.'
        else text='내 영토에서 도시를 지을 위치를 선택하세요.'end
    end
    self.text.Text=s.paused and '일시정지 중. 재개하면 안내가 이어져요.'or text
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
function M:layout(size)
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
    if self.blocked or not self.visible or self.dismissed or not (self.view and self.view.map)then self.ring.Visible=false;self.focus.Visible=false;return end
    local wave=reduced and 0 or (math.sin(os.clock()*4)+1)/2
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
