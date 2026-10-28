local UI=require(script.Parent.ToyUI)
local Theme=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Step=require(script.Parent.TelemetryStep)
local Lessons=require(script.Parent.Parent.Core.CampaignLessons)
local Campaign=require(script.Parent.Parent.Core.CampaignRules)
local M={};M.__index=M
local ORANGE=Color3.fromRGB(236,112,52)
local GOLD=Color3.fromRGB(232,184,72)
local function v2()local ok,H=pcall(require,script.Parent.Hud20);return ok and type(H)=='table'and H.ENABLED==true end
local K
local function kit()K=K or require(script.Parent.Kit20);return K end
local function L()return require(script.Parent.Localization)end
local function inset()local v=0;pcall(function()v=game:GetService('GuiService'):GetGuiInset().Y/(Theme.scale or 1)end);return v end
local function format(w,h)
    local t=require(script.Parent.InputMode).touch()
    if not t or require(script.Parent.Parent.Core.InterfacePlacement).tablet(w,h,t)then return 'pc'end
    return h>w and 'pt'or 'ph'
end
local function pct(x)return x>=10 and string.format('%d%%',math.floor(x+1e-6))or string.format('%.1f%%',math.floor(x*10+1e-6)/10)end
function M:task20(s,stage)
    local def=stage and Campaign.stage(stage);local t=def and def.task
    local show=t~=nil and s~=nil and s.phase=='playing'and not(s.drop and s.drop.active)
    local c=self.chip20
    if not show then if c then c.Visible=false end;return end
    kit()
    local parent=self.frame.Parent
    if not c then
        c=K.make('Frame',parent,{Name='CampaignTask20',BackgroundColor3=Color3.fromRGB(12,17,24),BackgroundTransparency=.14,BorderSizePixel=0,Visible=false,ZIndex=19})
        K.stroke(c,K.colors.line,1,.1,true);c:SetAttribute('NonBlocking',true)
        local star=K.icon(c,'star',15,K.colors.gold,'Star');star.ZIndex=c.ZIndex+1
        local l=K.text(c,'Label','',13,K.colors.ink,800);l.ZIndex=c.ZIndex+1
        local n=K.num(c,'Count','',14,K.colors.gold);n.ZIndex=c.ZIndex+1
        local of=K.num(c,'Target','',12,K.colors.muted);of.ZIndex=c.ZIndex+1
        local left=K.num(c,'Left','',12,K.colors.muted);left.ZIndex=c.ZIndex+1
        local cross=K.icon(c,'x',12,ORANGE,'Cross');cross.ZIndex=c.ZIndex+1;cross.Visible=false
        local dot=K.make('Frame',c,{Name='Now',BackgroundColor3=K.colors.accent,BorderSizePixel=0,ZIndex=c.ZIndex+1,Visible=false});K.round(dot,4)
        K.stroke(dot,K.colors.dim,1.5,0,false)
        local track=K.make('Frame',c,{Name='Track',BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.92,BorderSizePixel=0,ZIndex=c.ZIndex+1,Visible=false});K.round(track,2)
        local fill=K.make('Frame',track,{Name='Fill',BackgroundColor3=K.colors.accent,BorderSizePixel=0,ZIndex=c.ZIndex+2,Size=UDim2.fromScale(0,1)});K.round(fill,2)
        K.make('Frame',track,{Name='Goal',AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=K.colors.gold,BorderSizePixel=0,ZIndex=c.ZIndex+3,Visible=false})
        local tag=K.text(c,'Tutorial','튜토리얼',13,K.colors.accent,800);tag.ZIndex=c.ZIndex+1
        self.chip20=c
        c:GetPropertyChangedSignal('Visible'):Connect(function()if c.Visible and c:GetAttribute('Moving20')~='in'then c:SetAttribute('Shown20',false);K.appear(c,{dy=-8,t=.14})end end)
    end
    local cp=s.personalResult and s.personalResult.campaign
    local v=cp and cp.id==stage and tonumber(cp.taskValue)or 0;local done=cp and cp.id==stage and cp.taskDone==true or false
    local counted=(t.kind=='count'or t.kind=='built')and t.key~='growthGreen'and t.n~=nil
    local green=t.key=='growthGreen';local share=t.kind=='share'
    local left=share and cp and cp.id==stage and tonumber(cp.taskLeft)or nil
    local broken=not done and (t.kind=='zero'and cp~=nil and cp.id==stage or share and left~=nil and left<=0)
    local label,count,target,leftL,dot,track,cross=c.Label,c.Count,c.Target,c.Left,c.Now,c.Track,c.Cross
    label.Text=share and '영토'or green and '충원 초록'or t.label
    target.Text='';leftL.Text='';dot.Visible=false;track.Visible=false;cross.Visible=false;count.TextColor3=K.colors.gold
    local function progressed(was)
        if was~=nil and v>was then Step.step('campaign','taskProgress',{item=(('s'..stage..'_task'):gsub('%-','_')),value=v,total=t.n,duration_ms=(s.personalResult and s.personalResult.seconds or 0)*1000})end
    end
    if c:GetAttribute('Stage')~=stage then
        c:SetAttribute('Stage',stage);c:SetAttribute('Value',nil);c:SetAttribute('Broken',nil);c:SetAttribute('Done',nil)
        local st=c:FindFirstChild('Stroke20');if st then st.Color=K.colors.line;st.Transparency=.1;st.Thickness=1 end;c.Star.ImageColor3=K.colors.gold
    end
    if green then
        local p=s.player;local ratio=p and (tonumber(p.troops)or 0)/math.max(1,tonumber(p.cap)or 1)or 0
        local inBand=ratio>=Campaign.growthBand[1]and ratio<=Campaign.growthBand[2]
        count.Text=string.format('%d%%',v);count.TextColor3=v>=t.n and K.colors.gold or K.colors.ink;target.Text='/'..t.n
        dot.Visible=true;dot.BackgroundTransparency=inBand and 0 or 1;dot.Stroke20.Enabled=not inBand
        track.Visible=true;track.Fill.Size=UDim2.fromScale(math.clamp(v/100,0,1),1);track.Fill.BackgroundColor3=v>=t.n and K.colors.gold or K.colors.accent
        track.Goal.Visible=true;track.Goal.Position=UDim2.fromScale(t.n/100,.5)
    elseif share then
        if done then count.Text='✓'
        else count.Text=pct(v*100);count.TextColor3=broken and ORANGE or K.colors.ink;target.Text='/'..math.floor(t.n*100+.5)
            if broken then cross.Visible=true
            elseif left then local l=math.ceil(left);leftL.Text=string.format('%d:%02d',l//60,l%60);leftL.TextColor3=K.colors.muted end
            track.Visible=not broken;track.Fill.Size=UDim2.fromScale(math.clamp(v/t.n,0,1),1);track.Fill.BackgroundColor3=K.colors.accent;track.Goal.Visible=false
        end
    elseif t.kind=='zero'then
        count.Text=done and '✓'or '';count.TextColor3=K.colors.accent;cross.Visible=not done
    elseif done then count.Text='✓'
        if counted and c:GetAttribute('Value')~=v then progressed(c:GetAttribute('Value'));c:SetAttribute('Value',v)end
    elseif counted then
        local was=c:GetAttribute('Value');local n=t.n
        if was~=v then
            progressed(was)
            c:SetAttribute('Value',v)
            K.roll(count,was,math.min(v,n),function(x)return string.format('%d/%d',math.floor(x+.5),n)end,c)
        end
    else count.Text=''end
    local st=c:FindFirstChild('Stroke20')
    if broken and not c:GetAttribute('Broken')then
        c:SetAttribute('Broken',true);if st then st.Color=ORANGE;st.Transparency=0 end;c.Star.ImageColor3=K.colors.dim;K.punch(c,1.12,.16)
    elseif not broken and c:GetAttribute('Broken')then
        c:SetAttribute('Broken',nil);if st then st.Color=K.colors.line;st.Transparency=.1 end;c.Star.ImageColor3=K.colors.gold
    end
    local finishes=t.kind~='zero'and not green
    if finishes and done and not c:GetAttribute('Done')then
        c:SetAttribute('Done',true)
        if st then st.Color=K.colors.gold;st.Transparency=0;st.Thickness=1.5
            task.delay(1.2,function()if st.Parent then game:GetService('TweenService'):Create(st,TweenInfo.new(.3,Enum.EasingStyle.Quad),{Color=K.colors.line,Transparency=.1}):Play();st.Thickness=1 end end)end
        K.punch(c,1.12,.16)
    elseif not done and c:GetAttribute('Done')then c:SetAttribute('Done',nil)end
    local size=parent.AbsoluteSize/(Theme.scale or 1);local fmt=format(size.X,size.Y);local pc=fmt=='pc'
    local clock=parent:FindFirstChild('MatchStatus')
    local y=clock and clock.Visible and clock.Position.Y.Offset+clock.Size.Y.Offset+8 or (pc and 56 or (fmt=='ph'and 84 or 92)-inset())
    local speed=parent:FindFirstChild('Speed_1');if speed and speed.Visible then y=speed.Position.Y.Offset+speed.Size.Y.Offset+8 end
    local h=pc and 36 or 24;local pad=pc and 12 or 8;local gap=pc and 8 or 5;local is=pc and 15 or 11
    label.TextSize=pc and 13 or 11;count.TextSize=pc and 14 or 12;target.TextSize=pc and 12 or 10;leftL.TextSize=pc and 12 or 10
    local function w(l)return l.Text~=''and K.width(l.Text,l.TextSize,l)+2 or 0 end
    local lw=K.width(L().text(label.Text),label.TextSize,label)+2
    local x=pad
    local tag=c.Tutorial;tag.Visible=def.intro==true;tag.TextSize=label.TextSize
    if tag.Visible then local tw=K.width(L().text(tag.Text),tag.TextSize,tag)+2;K.box(tag,x,0,tw,h);x+=tw+gap+2 end
    K.box(c.Star,x,math.floor((h-is)/2),is,is);c.Star.Size=UDim2.fromOffset(is,is);x+=is+gap
    K.box(label,x,0,lw,h);x+=lw
    if dot.Visible then local d=pc and 8 or 7;x+=gap;K.box(dot,x,math.floor((h-d)/2),d,d);x+=d end
    local cw=w(count);if cw>0 then x+=gap;K.box(count,x,0,cw,h);x+=cw end
    local tw=w(target);if tw>0 then x+=2;K.box(target,x,1,tw,h);x+=tw end
    local ew=w(leftL);if ew>0 then x+=gap;K.box(leftL,x,1,ew,h);x+=ew end
    if cross.Visible then local cs=pc and 12 or 10;x+=gap;K.box(cross,x,math.floor((h-cs)/2),cs,cs);x+=cs end
    local cwid=x+pad
    if track.Visible then local th=pc and 3 or 2;K.box(track,pad-4,h-th-(pc and 3 or 2),cwid-2*(pad-4),th);track.Goal.Size=UDim2.fromOffset(2,th+5)end
    local pos=UDim2.fromOffset(12,math.floor(y))
    c.Size=UDim2.fromOffset(cwid,h);K.round(c,pc and 10 or 7);c:SetAttribute('Home20',pos);if c:GetAttribute('Moving20')==nil then c.Position=pos end
    c.Visible=true
end
function M:hint20()
    if self.h20 then return self.h20 end
    kit()
    local f=self.frame;local p={};self.h20=p
    for _,s in ipairs(f:GetChildren())do if s:IsA('UIStroke')and s.Name~='Stroke20'then s.Enabled=false end end
    f.BackgroundTransparency=1;K.round(f,12);K.stroke(f,K.colors.line,1,.1,true)
    p.bar=K.fillBar(f,'Bg20',{parts={{p=.01,color=K.colors.accent}},track=Color3.fromRGB(12,17,24),trackAlpha=.06,r=12})
    p.bar.frame.ZIndex=f.ZIndex;p.bar.frame.Size=UDim2.fromScale(1,1)
    p.close=K.button(f,'Close20',{kind='none',icon='x',iconSize=16},function()self:closeHint(true)end)
    p.close.iconColorFixed=true;p.close.iconImage.ImageColor3=K.colors.muted;p.close.button.ZIndex=f.ZIndex+3
    f:GetPropertyChangedSignal('Visible'):Connect(function()if f.Visible and f:GetAttribute('Moving20')~='in'then f:SetAttribute('Shown20',false);K.appear(f,{dy=8,t=.14})end end)
    return p
end
function M:layout20(context)
    local p=self:hint20();local f=self.frame
    self.mark.Visible=false;self.close.Visible=false
    local size=f.Parent.AbsoluteSize/(Theme.scale or 1);local fmt=format(size.X,size.Y);local pc=fmt=='pc'
    local w=pc and 380 or fmt=='ph'and 290 or size.X-24;local h=pc and 52 or 40
    local top=context and context.hudTop or size.Y-96
    local pos=UDim2.fromOffset(math.floor((size.X-w)/2),math.floor(top-8-h))
    f.Size=UDim2.fromOffset(w,h);f:SetAttribute('Home20',pos);if f:GetAttribute('Moving20')==nil then f.Position=pos end
    local warn=self.current and self.current.tone=='warn';local tone=warn and ORANGE or K.colors.accent
    p.bar:setParts({{p=3/w,color=tone}})
    for _,st in ipairs(f:GetChildren())do if st:IsA('UIStroke')then st.Color=warn and ORANGE or K.colors.line;st.Transparency=warn and 0 or .1 end end
    local ws=p.bar.frame:FindFirstChild('Warn20')or Instance.new('UIStroke');ws.Name='Warn20';ws.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;ws.Thickness=1;ws.Color=ORANGE;ws.Enabled=warn;ws.Parent=p.bar.frame
    local key=(self.current and (self.current.focus=='troops'and 'Soldier'or self.current.focus=='build'and 'City')or 'Crown')..(warn and ':warn'or '')
    if p.key~=key then p.key=key;if p.icon then p.icon:Destroy()end;p.icon=require(script.Parent.HotbarIcons).create(f,(key:gsub(':warn','')),20,tone);p.icon.ZIndex=f.ZIndex+2 end
    p.icon.Position=UDim2.fromOffset(15,math.floor((h-20)/2))
    local t=self.text;t.TextColor3=K.colors.ink;if K.fonts[700]then t.FontFace=K.fonts[700]end;t.TextWrapped=true;t.TextTruncate=Enum.TextTruncate.AtEnd
    t.TextXAlignment=Enum.TextXAlignment.Left;t.TextYAlignment=Enum.TextYAlignment.Center;t.ZIndex=f.ZIndex+2
    K.box(t,45,2,w-45-48,h-4);t.TextSize=pc and 14 or 13
    p.close:place(w-46,math.floor((h-44)/2),44,44)
end
function M.new(parent,view)
    local self=setmetatable({view=view},M)
    self.frame=UI.panel(parent,'CampaignHint');self.frame.ZIndex=19;self.frame.Visible=false;self.frame:SetAttribute('NonBlocking',true)
    self.mark=UI.pill(self.frame,'Mark','!',ORANGE)
    self.text=UI.label(self.frame,'Text','',14)
    self.close=UI.button(self.frame,'Close','×',function()self:closeHint(true)end)
    self.focus=UI.make('Frame',parent,{Name='CampaignHintFocus',BackgroundTransparency=1,Visible=false,ZIndex=20});UI.corner(self.focus,6)
    self.focusStroke=UI.stroke(self.focus,ORANGE,2)
    return self
end
local function code(id,key)return ('s'..tostring(id)..'_'..tostring(key)):gsub('%-','_')end
function M:reset(version,stage)
    self.version=version;self.stage=stage;self.memo={};self.seen={};self.count=0;self.current=nil;self.closedAll=false
    self.taskSeen=nil;self.taskDone=nil;self.toastUntil=nil
    self.frame.Visible=false;self.focus.Visible=false
end
function M:closeHint(byPlayer)
    local h=self.current;if not h then return end
    if byPlayer then Step.step('campaign','hintClosed',{item=code(self.stage,h.id),duration_ms=(os.clock()-self.shownAt)*1000})end
    self.current=nil;self.frame.Visible=false;self.focus.Visible=false
end
function M:update(s,context)
    local stage=s and s.campaign
    if self.version~=(s and s.version)or self.stage~=stage then self:reset(s and s.version,stage)end
    local new=v2();if new then self:task20(s,stage)end
    if not stage or not Lessons.of(stage)or s.paused or (s.drop and s.drop.active)or s.phase~='playing'then
        self.frame.Visible=false;self.focus.Visible=false;return false
    end
    local now=os.clock()
    local ok,key=pcall(Lessons.check,stage,s,self.memo,now,self.view and self.view.map)
    if not ok then key=nil end
    local h=self.current
    if h then
        if key~=h.id then
            self.goneAt=self.goneAt or now
            if now-self.goneAt>=1.5 then
                if now-self.shownAt<=15 then Step.step('campaign','hintActed',{item=code(stage,h.id),duration_ms=(now-self.shownAt)*1000})end
                self:closeHint(false)
            end
        else self.goneAt=nil end
    elseif key and not self.seen[key]and self.count<Lessons.maxHints then
        local hint=Lessons.hint(stage,key)
        if hint then
            self.seen[key]=true;self.count+=1;self.current=hint;self.shownAt=now;self.goneAt=nil
            self.text.Text=hint.text;Step.step('campaign','hint',{item=code(stage,key),result='shown'})
        end
    end
    h=self.current
    if new then
        self.frame.Visible=h~=nil and not(context and context.blocked)
        local target=h and h.focus=='troops'and context and context.troops or nil
        self.highlight=target and target.Visible and target or nil
        if self.frame.Visible then self:layout20(context)end
        return h~=nil
    end
    if not h then self:taskToast(s,stage,now)end
    local toast=not h and self.toastUntil and now<self.toastUntil
    self.mark.Text=toast and '★'or '!';self.mark.BackgroundColor3=toast and GOLD or ORANGE
    if toast then self.frame.Visible=not(context and context.blocked);if self.frame.Visible then self:layout(self.frame.Parent.AbsoluteSize/Theme.scale)end;self.highlight=nil;return true end
    self.frame.Visible=h~=nil and not(context and context.blocked)
    local target=h and h.focus=='troops'and context and context.troops or nil
    self.highlight=target and target.Visible and target or nil
    if self.frame.Visible then self:layout(self.frame.Parent.AbsoluteSize/Theme.scale)end
    return h~=nil
end
function M:taskToast(s,stage,now)
    local cp=s.personalResult and s.personalResult.campaign
    local def=Campaign.stage(stage);local t=def and def.task
    if not(cp and cp.id==stage and t)or t.kind=='zero'or t.key=='growthGreen'then return end
    local v=tonumber(cp.taskValue)or 0
    if self.taskSeen==nil then self.taskSeen=v;self.taskDone=cp.taskDone==true;return end
    if cp.taskDone==true and not self.taskDone then
        self.taskDone=true;self.taskSeen=v;self.toastUntil=now+4
        self.text.Text=string.format('과제 완료  %s',t.label)
        Step.step('campaign','taskDone',{item=code(stage,'task'),duration_ms=(s.personalResult.seconds or 0)*1000})
    elseif v>self.taskSeen and not self.taskDone and t.kind~='share'and (t.n or 1)>1 then
        self.taskSeen=v;self.toastUntil=now+4
        self.text.Text=string.format('과제 %d/%d  %s',v,t.n,t.label)
    end
end
function M:layout(size)
    local touch=require(script.Parent.InputMode).touch()
    local phone=touch and size.Y<500 and size.X>size.Y and size.X>=560
    Style.round(self.frame,phone and 10 or 8);self.frame.BackgroundColor3=Style.colors.panel;self.frame.BackgroundTransparency=.06
    Style.round(self.mark,6);self.mark.TextColor3=Theme.colors.bg;self.mark.Font=Enum.Font.BuilderSansBold
    self.close.BackgroundTransparency=1;self.close.TextSize=18;self.close.TextColor3=Theme.colors.muted
    local st=self.close:FindFirstChildOfClass('UIStroke');if st then st.Enabled=false end
    local w,h,x,y
    if phone then
        x=134;w=math.max(220,size.X-52-104-12-8-8-x);h=48;y=2;self.text.TextWrapped=true;self.text.TextTruncate=Enum.TextTruncate.AtEnd;self.text.TextSize=12
    else
        w=math.min(600,size.X-20);h=touch and 64 or 56;x=(size.X-w)/2
        y=size.X<620 and size.Y>size.X and 8+62+8+48+6 or 8
        self.text.TextWrapped=true;self.text.TextTruncate=Enum.TextTruncate.None;self.text.TextSize=15
    end
    UI.box(self.frame,x,y,w,h);UI.box(self.mark,phone and 6 or 10,(h-(phone and 24 or 32))/2,phone and 24 or 32,phone and 24 or 32)
    UI.box(self.close,w-48,(h-48)/2,48,48)
    local tx=phone and 36 or 52;UI.box(self.text,tx,0,w-tx-52,h)
end
function M:stepFrame(reduced)
    local t=self.highlight
    if not(self.frame.Visible and t)then self.focus.Visible=false;return end
    local new=v2();if new and K then self.focusStroke.Color=self.current and self.current.tone=='warn'and ORANGE or K.colors.accent end
    local wave=(reduced or new)and 0 or (math.sin(os.clock()*4)+1)/2;self.focusStroke.Transparency=wave*.3
    local origin=self.frame.Parent.AbsolutePosition;local s=Theme.scale
    UI.box(self.focus,(t.AbsolutePosition.X-origin.X)/s-4,(t.AbsolutePosition.Y-origin.Y)/s-4,t.AbsoluteSize.X/s+8,t.AbsoluteSize.Y/s+8)
    self.focus.Visible=true
end
return M
