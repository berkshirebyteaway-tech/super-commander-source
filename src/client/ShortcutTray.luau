local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Shortcut=require(script.Parent.CornerShortcut)
local Placement=require(script.Parent.Parent.Core.InterfacePlacement)
local M={};M.__index=M
local K
local NAMES={FavoriteEmojis='이모지',QuickMessages='대화',MotionShortcut='모션'}
local COLUMN={FavoriteEmojis='이모지',QuickMessages='대화',MotionShortcut='모션',EventLogButton='기록',CameraShortcut='내 위치'}
function M.new(panel,menu,a)
    local p={panel=panel,menu=menu,menuPlate=a.menuPlate,emoji=a.chat.emojiButton,quick=a.chat.quickButton,motion=a.motionShortcut,
        mode={bar=a.modeBar,title=a.modeTitle,hint=a.modeHint,cancel=a.modeCancel,all=a.modeAll}}
    local self=setmetatable({p=p,a=a,open=false,phone=false},M)
    local sheet=panel:FindFirstChild('ActionSheet')
    if sheet then
        local ticket=0
        local function replay()
            if not sheet.Visible then return end
            ticket+=1;local mine=ticket
            task.spawn(function()
                local RS=game:GetService('RunService');RS.Heartbeat:Wait();RS.Heartbeat:Wait()
                if mine==ticket and sheet.Visible then self:radial();M.ringAppear(sheet)end
            end)
        end
        sheet:GetPropertyChangedSignal('Visible'):Connect(replay)
        sheet:GetPropertyChangedSignal('Position'):Connect(function()if not sheet:GetAttribute('Pan20')then replay()end end)
        sheet:GetAttributeChangedSignal('Open20'):Connect(replay)
    end
    self.tray=UI.make('Frame',p.panel,{Name='CommsTray',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=19,Visible=false})
    self.backdrop=UI.make('Frame',self.tray,{Name='Backdrop',BackgroundColor3=Style.colors.panel,BackgroundTransparency=.12,BorderSizePixel=0,ZIndex=18,Active=true})
    Style.round(self.backdrop,10);Style.line(self.backdrop,Style.colors.line,1)
    self.toggle=Shortcut.new(p.panel,'CommsShortcut',nil,'comms',function()self:set(not self.open)end,'소통');self.toggle.Visible=false
    self.members={p.emoji,p.quick,p.motion}
    self.more=Shortcut.new(p.panel,'MoreShortcut',nil,'more',function()self:set(not self.open)end,'펼치기');self.more.Visible=false
    self.column={p.emoji,p.quick,p.motion,a.eventLog and a.eventLog.button,a.cameraShortcut,p.menu}
    for _,b in ipairs(self.column)do if b and b~=p.emoji and b~=p.quick and b~=p.motion then
        b.Activated:Connect(function()if self.portrait and self.open then task.defer(function()self:set(false)end)end end)
    end end
    self.stack={a.cameraShortcut,a.eventLog and a.eventLog.button}
    if a.tactical then a.tactical.frame:GetPropertyChangedSignal('Visible'):Connect(function()self:aside()end)end
    if p.mode then p.mode.bar:GetPropertyChangedSignal('Visible'):Connect(function()if p.mode.bar.Visible and self.open then self:set(false)end end)end
    for _,b in ipairs(self.members)do
        b.Activated:Connect(function()if (self.phone or self.portrait)and self.open then task.defer(function()self:set(false)end)end end)
        b:GetPropertyChangedSignal('Visible'):Connect(function()self:refresh()end)
    end
    return self
end
function M:aside()
    local a=self.a;local on=self.phone and a.tactical and a.tactical.frame.Visible
    local left;if self.phone and a.sheets then for _,f in ipairs({a.tactical.frame,a.quick.frame,a.eventLog.panel,a.sheets.frame})do if f.Visible then left=f end end end
    local dock=self.a.dock
    if dock then
        local cover
        if left then
            local bar=dock.frame.Parent;local s=bar.Size.X.Offset>0 and bar.AbsoluteSize.X/bar.Size.X.Offset or 1
            cover=math.floor((left.AbsolutePosition.X-bar.AbsolutePosition.X)/s)
        end
        if dock.coverX~=cover then dock.coverX=cover;if dock.width then dock:layout(dock.x,dock.y,dock.width,dock.touch)end end
    end
    self.hidden=self.hidden or {}
    for _,b in ipairs(self.stack)do if b then
        if on and b.Visible then self.hidden[b]=true;b.Visible=false
        elseif not on and self.hidden[b]then self.hidden[b]=nil;b.Visible=true end
    end end
end
function M:set(open)
    self.open=open==true
    if self.portrait and self.last then self:layout(table.unpack(self.last,1,7));return end
    self:refresh()
    if self.open and self.screen then
        local b=self.backdrop;local base=b.Position;b.Position=base+UDim2.fromOffset(8,0)
        game:GetService('TweenService'):Create(b,TweenInfo.new(.16,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=base}):Play()
    end
end
function M:refresh()
    local any=false
    for _,b in ipairs(self.members)do if b.Visible then any=true end end
    self.toggle.Visible=self.phone and any and self.shown~=false
    self.tray.Visible=self.phone and self.open and self.toggle.Visible
    local plate=self.toggle:FindFirstChild('Plate')
    if plate then plate.BackgroundColor3=self.open and UI.colors.ink or Color3.new(0,0,0);plate.BackgroundTransparency=self.open and 0 or .28 end
    local icon=plate and plate:FindFirstChild('Icon')
    if icon then for _,o in ipairs(icon:GetDescendants())do
        if o:IsA('Frame')and o.BackgroundTransparency<1 then o.BackgroundColor3=self.open and UI.colors.bg or UI.colors.ink end
        if o:IsA('UIStroke')then o.Color=self.open and UI.colors.bg or UI.colors.ink end
    end end
end
local GLASS=Color3.fromRGB(12,17,24)
function M.feel20(b,face)
    if b:GetAttribute('Feel20')then return end
    b:SetAttribute('Feel20',true)
    local Tween=game:GetService('TweenService')
    local s=face:FindFirstChild('Press20')or K.make('UIScale',face,{Name='Press20'})
    s:GetPropertyChangedSignal('Scale'):Connect(function()
        for _,o in ipairs(b:GetChildren())do if o~=face and o.Name~='Caption'and o:IsA('GuiObject')then
            local u=o:FindFirstChild('Press20')or K.make('UIScale',o,{Name='Press20'});u.Scale=s.Scale
        end end
    end)
    local hover,down,tween=false,false,nil
    local function to(goal,t,style)
        if tween then tween:Cancel();tween=nil end
        if K.reduced then s.Scale=1;return end
        tween=Tween:Create(s,TweenInfo.new(t,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=goal});tween:Play()
    end
    local function press(i)return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
    b.MouseEnter:Connect(function()if b:GetAttribute('Enabled')==false or require(script.Parent.InputMode).touch()then return end;hover=true;if not down then to(1.02,.08)end end)
    b.MouseLeave:Connect(function()hover=false;down=false;to(1,.08)end)
    b.InputBegan:Connect(function(i)if press(i)and b:GetAttribute('Enabled')~=false then down=true;if tween then tween:Cancel();tween=nil end;if not K.reduced then s.Scale=.96 end end end)
    b.InputEnded:Connect(function(i)
        if not press(i)or not down then return end
        down=false;if K.reduced then s.Scale=1;return end
        if tween then tween:Cancel()end;s.Scale=1.02;to(hover and 1.02 or 1,.12,Enum.EasingStyle.Back)
    end)
    b:GetPropertyChangedSignal('Visible'):Connect(function()if not b.Visible then hover=false;down=false;if tween then tween:Cancel();tween=nil end;s.Scale=1 end end)
end
local RING=setmetatable({},{__mode='k'})
local PLACE=setmetatable({},{__mode='k'})
function M.ringAppear(sheet)
    K=K or require(script.Parent.Kit20)
    if not require(script.Parent.Hud20).ENABLED or not sheet or not sheet.Visible then return end
    local Tween=game:GetService('TweenService')
    local disc=sheet:FindFirstChild('Disc20')
    if K.reduced then
        if disc then local t=disc.BackgroundTransparency;disc.BackgroundTransparency=1;Tween:Create(disc,TweenInfo.new(.12),{BackgroundTransparency=t}):Play()end
        return
    end
    local cx,cy=sheet.AbsoluteSize.X/2,sheet.AbsoluteSize.Y/2
    local i=0
    for _,b in ipairs(sheet:GetChildren())do
        if b:IsA('GuiButton')and b.Visible and b:GetAttribute('Feel20')then
            local bx,by=b.AbsolutePosition.X-sheet.AbsolutePosition.X+b.AbsoluteSize.X/2,b.AbsolutePosition.Y-sheet.AbsolutePosition.Y+b.AbsoluteSize.Y/2
            local s=sheet.Size.X.Offset>0 and sheet.AbsoluteSize.X/sheet.Size.X.Offset or 1
            local dx,dy=math.floor((cx-bx)/s+.5),math.floor((cy-by)/s+.5)
            local centre=math.abs(dx)<2 and math.abs(dy)<2
            if centre then
                local face=b:FindFirstChild('Face20');local sc=face and(face:FindFirstChild('Press20')or K.make('UIScale',face,{Name='Press20'}))
                if sc then sc.Scale=.9;Tween:Create(sc,TweenInfo.new(.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()end
            else
                local delay=i*.02;i+=1
                for _,o in ipairs(b:GetChildren())do
                    if o:IsA('GuiObject')and o.Visible and not PLACE[o]then
                        local run=RING[o];local home=run and run.home or o.Position
                        if run then run.tween:Cancel()end
                        o.Position=home+UDim2.fromOffset(dx,dy)
                        local tw=Tween:Create(o,TweenInfo.new(.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,delay),{Position=home})
                        RING[o]={home=home,tween=tw}
                        tw.Completed:Connect(function()if RING[o]and RING[o].tween==tw then RING[o]=nil end end);tw:Play()
                    end
                end
            end
        end
    end
end
local function apply(o)
    local p=PLACE[o];local b=o.Parent;if not p or not b or not b.Visible then return end
    local s,x,y,w,h,centre=p[1],p[2],p[3],p[4],p[5],p[6]
    local face=b:FindFirstChild('Face20');local fly=face and face.Position-UDim2.fromScale(.5,.5)or UDim2.new()
    p.busy=true
    if centre then
        w,h=K.even(math.floor(w+.5)),K.even(math.floor(h+.5))
        o.AnchorPoint=Vector2.new(.5,.5);o.Size=UDim2.fromOffset(w,h)
        o.Position=UDim2.new(.5,math.floor(x+w/2-s/2+.5),.5,math.floor(y+h/2-s/2+.5))+fly
    else o.AnchorPoint=Vector2.zero;o.Size=UDim2.fromOffset(w,h);o.Position=UDim2.fromOffset(x,y)+fly end
    p.busy=false
end
local function put(o,s,x,y,w,h,raw)
    local first=PLACE[o]==nil;PLACE[o]={s,x,y,w,h,not raw}
    if first then
        for _,prop in ipairs({'Position','AnchorPoint','Size'})do
            o:GetPropertyChangedSignal(prop):Connect(function()local p=PLACE[o];if p and not p.busy then apply(o)end end)
        end
        local b=o.Parent;local face=b and b:FindFirstChild('Face20')
        if face and not face:GetAttribute('Rides20')then face:SetAttribute('Rides20',true)
            face:GetPropertyChangedSignal('Position'):Connect(function()for _,c in ipairs(b:GetChildren())do if PLACE[c]then apply(c)end end end)
        end
    end
    apply(o)
end
function M:radial20()
    K=K or require(script.Parent.Kit20)
    local sheet=self.sheet or self.p.panel:FindFirstChild('ActionSheet');self.sheet=sheet
    if not(sheet and sheet.Visible and sheet.BackgroundTransparency>=1)then return end
    local l=self.last or {};local g=require(script.Parent.Parent.Core.CommandInteraction).radialGeometry(l[1]or 1366,l[2]or 768)
    local d=sheet.Size.X.Offset
    local disc=sheet:FindFirstChild('Disc20')or K.make('Frame',sheet,{Name='Disc20',BackgroundColor3=GLASS,BorderSizePixel=0,Active=false,ZIndex=sheet.ZIndex})
    local reach=sheet:GetAttribute('Ring20')=='nation'and math.max(g.radius+g.face/2,g.low+g.minorFace/2)or g.radius+g.face/2
    K.round(disc,'pill');disc.BackgroundTransparency=.45;local ds=reach*2+16;K.box(disc,(d-ds)/2,(d-ds)/2,ds,ds)
    local minor=require(script.Parent.Parent.Core.CommandInteraction).minorSlots
    for _,n in ipairs({'RadialTrack','RadialCore','Close'})do local o=sheet:FindFirstChild(n);if o and o:IsA('GuiObject')then o.Visible=false end end
    local a=self.a
    for _,b in ipairs(sheet:GetChildren())do
        local c=b:IsA('GuiButton')and b.Visible and b:FindFirstChildOfClass('UICorner')
        if c and c.CornerRadius.Scale>=1 and b.Name~='Close'then
            local s=b.Size.X.Offset;local primary=s>=g.big-1
            local preview=b:GetAttribute('Preview20')==true
            if not b:GetAttribute('PreviewWatch20')then b:SetAttribute('PreviewWatch20',true)
                b:GetAttributeChangedSignal('Preview20'):Connect(function()if sheet.Visible then self:radial20()end end)end
            local buildKind=b:GetAttribute('BuildKind')
            local buildReason=buildKind and a.ringBlock and a.ringBlock(buildKind)or nil
            local faceSize=primary and g.big or minor[b.Name]and g.minorFace or g.face
            if preview then primary=false end
            if b.ZIndex<=disc.ZIndex then b.ZIndex=disc.ZIndex+1 end
            if b.Name=='Signals'then
                for _,o in ipairs(b:GetChildren())do if(o:IsA('ImageLabel')or o:IsA('ViewportFrame'))and o.Name~='Chat20'then o.Visible=false end end
                if not b:FindFirstChild('Chat20')then K.icon(b,'chat',g.icon,K.colors.ink,'Chat20')end
            end
            b.BackgroundTransparency=1;local bs=b:FindFirstChildOfClass('UIStroke');if bs then bs.Enabled=false end
            local face=b:FindFirstChild('Face20')or K.make('Frame',b,{Name='Face20',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BorderSizePixel=0,Active=false})
            face.ZIndex=b.ZIndex;face.Size=UDim2.fromOffset(faceSize,faceSize);K.round(face,'pill')
            M.feel20(b,face)
            local breaking=b.Name=='Alliance'and b:GetAttribute('Breaking')==true
            local ally=b.Name=='Alliance'and not breaking
            local fill=primary and K.colors.accent or ally and K.colors.ally or GLASS
            face.BackgroundColor3=fill;face.BackgroundTransparency=(primary or ally)and 0 or .14
            local fs=face:FindFirstChild('Stroke20');local st=K.stroke(face,breaking and K.colors.danger or K.colors.line,breaking and 2 or 1,(primary or ally)and 1 or .1,true)
            if primary or ally then st.Transparency=1 end;if fs and fs~=st then fs:Destroy()end
            local route=b:GetAttribute('Route20')==true and not primary
            if route then st.Color=K.colors.accent;st.Thickness=2;st.Transparency=0 end
            local enabled=b:GetAttribute('Enabled')~=false and buildReason==nil
            if not enabled then face.BackgroundColor3=fill:Lerp(GLASS,.6);st.Transparency=1-(1-st.Transparency)*.4 end
            if preview then face.BackgroundTransparency=.3;b.TextTransparency=1 end
            local cap=b:FindFirstChild('Caption')
            if cap and cap:IsA('TextLabel')then
                cap.BackgroundTransparency=1;cap.TextSize=11;cap.ZIndex=b.ZIndex+2
                if K.fonts[700]then cap.FontFace=K.fonts[700]end
                cap.TextColor3=ally and K.colors.ally or breaking and K.colors.danger or route and K.colors.accent or b.Name=='SupportGold'and K.colors.gold
                    or cap.TextColor3==K.colors.gold and K.colors.gold or K.colors.ink
                if buildKind then
                    cap.Text=buildReason=='골드 부족'and '골드 부족'or b.Text
                    cap.TextColor3=buildReason and K.colors.danger or K.colors.gold
                end
                if breaking then cap.Text='파기'end
                local pad=cap:FindFirstChildOfClass('UIPadding');if pad then pad.PaddingLeft=UDim.new(0,0);pad.PaddingRight=UDim.new(0,0)end
                cap.Visible=not primary and not preview;cap.Size=UDim2.fromOffset(s+24,14)
                local top=b.AbsolutePosition.Y+b.AbsoluteSize.Y/2-sheet.AbsolutePosition.Y-sheet.AbsoluteSize.Y/2<-g.radius*.7*sheet.AbsoluteSize.X/math.max(1,d)
                put(cap,s,-14,top and (s-faceSize)/2-16 or (s+faceSize)/2+2,s+24,14,true)
                cap.TextXAlignment=Enum.TextXAlignment.Center;cap.TextTransparency=enabled and 0 or .5
            end
            for _,o in ipairs(b:GetChildren())do if not o:IsA('GuiObject')then continue end
                if (o:IsA('ImageLabel')or o:IsA('ViewportFrame'))and o.Name~='Face20'and o.Visible then
                    local is=primary and g.bigIcon or g.icon
                    o.ZIndex=b.ZIndex+2
                    if primary then put(o,s,(s-is)/2,math.floor((s-faceSize)/2+faceSize*.14),is,is)else put(o,s,(s-is)/2,(s-is)/2,is,is)end
                    if o:IsA('ImageLabel')then o.ImageColor3=(primary or ally)and K.colors.bg or breaking and K.colors.danger or o.ImageColor3;o.ImageTransparency=enabled and 0 or .6
                    elseif o:IsA('ViewportFrame')then o.ImageTransparency=enabled and 0 or .6 end
                elseif o.Visible and o:IsA('TextLabel')and string.sub(o.Name,1,5)=='Icon_'then
                    o.TextTransparency=enabled and 0 or .6
                elseif o.Visible and o:GetAttribute('NativeGlyph')then
                    for _,mark in ipairs(o:GetChildren())do if mark:IsA('Frame')then mark.BackgroundTransparency=enabled and 0 or .6 end end
                end
            end
            local word=b:FindFirstChild('Word20')or K.text(b,'Word20','',11,K.colors.bg,800,Enum.TextXAlignment.Center)
            local num=b:FindFirstChild('Num20')or K.num(b,'Num20','',15,K.colors.bg,Enum.TextXAlignment.Center)
            word.Visible=primary;num.Visible=false
            if primary then
                b.TextTransparency=1
                local text=(b.Text or ''):gsub('\n.*','')
                word.Text=buildReason=='골드 부족'and '골드 부족'or text;word.ZIndex=b.ZIndex+3;local top=(s-faceSize)/2
                put(word,s,0,top+faceSize*.45,s,14)
                local cb=a.commandBar
                local second=b.Name=='SupportTroops'and(b.Text or ''):match('\n(.+)$')or nil
                local amount=(text=='공격'or text=='수송 공격')and cb and cb.myTroops and UI.troops((cb.sendFraction or .2)*cb.myTroops)or second
                if amount then
                    num.Visible=true;num.Text=amount;num.TextSize=faceSize>=80 and 15 or 13;num.ZIndex=b.ZIndex+3
                    put(num,s,0,top+faceSize*.45+13,s,18)
                end
                local fade=enabled and 0 or .5;word.TextTransparency=fade;num.TextTransparency=fade
            end
        end
    end
end
function M:radial()
    if require(script.Parent.Hud20).ENABLED then return self:radial20()end
    local sheet=self.sheet or self.p.panel:FindFirstChild('ActionSheet');self.sheet=sheet
    if not(sheet and sheet.Visible and sheet.BackgroundTransparency>=1)then return end
    for _,b in ipairs(sheet:GetChildren())do
        local c=b:IsA('GuiButton')and b.Visible and b:FindFirstChildOfClass('UICorner')
        if c and c.CornerRadius.Scale>=1 then
            local primary=b.BackgroundColor3==UI.colors.accent
            if b.BackgroundColor3==UI.colors.raised then b.BackgroundColor3=Style.colors.cell;b.BackgroundTransparency=.04 end
            local s=b:FindFirstChildOfClass('UIStroke')
            if s then s.Color=primary and UI.colors.gold or Style.colors.line;s.Transparency=primary and .1 or 0;s.Thickness=primary and 2 or 1 end
        end
    end
end
function M:placementBand(w,h,phone)
    local m=self.p.mode;if not m then return end
    local bar=m.bar
    bar.BackgroundColor3=Style.colors.rateBg;bar.BackgroundTransparency=.06;Style.round(bar,8);Style.line(bar,UI.colors.accent,1,.4)
    m.title.TextSize=14;m.title.Font=Enum.Font.BuilderSansBold;m.title.TextColor3=UI.colors.accent
    m.hint.TextSize=13;m.hint.TextColor3=UI.colors.ink
    for _,b in ipairs({m.cancel,m.all})do b.BackgroundColor3=Style.colors.chip;Style.round(b,6)end
    if phone then
        local bw=math.min(340,w-16-64);UI.box(bar,8,h-Placement.PHONE_HUD-4-48,bw,48)
        local allW=m.all.Visible and 84 or 0
        UI.box(m.title,10,3,bw-62-allW,21);UI.box(m.hint,10,23,bw-62-allW,21)
        UI.box(m.all,bw-52-allW,0,80,48);UI.box(m.cancel,bw-48,0,48,48)
    end
end
local ICON20={QuickMessages='chat',EventLogButton='history',CameraShortcut='locate',Pause='menu'}
local NAME20={QuickMessages='소통',EventLogButton='기록',CameraShortcut='내 위치',Pause='메뉴'}
local function dress(b,size,iconSize)
    local plate=b:FindFirstChild('Plate')or b:FindFirstChild('MenuPlate')
    if plate then
        for _,o in ipairs(plate:GetChildren())do if o:IsA('GuiObject')and o.Name~='Icon20'then o.Visible=false end end
        plate.AnchorPoint=Vector2.zero;K.box(plate,(48-size)/2,(48-size)/2,size,size);K.round(plate,size>=44 and 10 or 8)
        plate.BackgroundColor3=Color3.fromRGB(12,17,24);plate.BackgroundTransparency=b:GetAttribute('Locked')and .55 or .2
        local st=plate:FindFirstChildOfClass('UIStroke');if st then st.Color=K.colors.line;st.Transparency=.1;st.Thickness=1;st.Enabled=true end
        local icon=plate:FindFirstChild('Icon20')or K.icon(plate,ICON20[b.Name]or 'menu',iconSize,K.colors.ink,'Icon20')
        K.box(icon,(size-iconSize)/2,(size-iconSize)/2,iconSize,iconSize);icon.ImageTransparency=b:GetAttribute('Locked')and .5 or 0;icon.ZIndex=plate.ZIndex+2
    end
    local key=b:FindFirstChild('Key');if key then key.Visible=false end
    local s=b:FindFirstChild('PcScale');if s then s.Scale=1 end
    if b.Name=='Pause'then b.Text='';b.BackgroundTransparency=1 end
end
function M:layout20(w,h,touch,shown,sheet)
    K=K or require(script.Parent.Kit20)
    local a=self.a;local p=self.p;local phone=touch==true and not Placement.tablet(w,h,touch)
    self.phone=false;self.portrait=false;self.toggle.Visible=false;self.more.Visible=false;self.tray.Visible=false
    for _,b in ipairs(self.members)do b.Parent=p.panel end
    for b,parent in pairs(self.stowed or {})do b.Parent=parent end;self.stowed={}
    self:placementBand(w,h,false);self:radial()
    p.emoji.Visible=false;p.motion.Visible=false
    local list={p.quick,a.eventLog and a.eventLog.button,a.cameraShortcut,p.menu}
    for _,b in ipairs(list)do if b then b.Parent=p.panel;dress(b,phone and 36 or 48,phone and 17 or 22)end end
    shown=shown~=false and not(a.tactical and a.tactical.frame.Visible)and not(a.drop and a.drop.active)and not a.resultUp
    if not phone then
        if self.burger then self.burger.button.Visible=false end
        local x0,y0=w-12-48-8-48,h-12-48-8-48
        local spots={{x0,y0},{x0+56,y0},{x0,y0+56},{x0+56,y0+56}}
        for i,b in ipairs(list)do if b then UI.box(b,spots[i][1],spots[i][2],48,48);b.Visible=shown;b.ZIndex=19
            local tip=b:FindFirstChild('Tip')
            if tip then tip.Visible=b:GetAttribute('Hover')==true
                local tw=math.max(56,K.width(require(script.Parent.Localization).text(tip.Text),tip.TextSize,tip)+20);local tx=math.min((48-tw)/2,w-8-spots[i][1]-tw)
                UI.box(tip,tx,-30,tw,24)
            end end end
        self.open=false;self.menuShown=shown;self:aside();return
    end
    if not self.burger then
        self.burger=K.button(p.panel,'Hamburger20',{kind='glass',icon='menu',iconSize=17,hit=40},function()self:set20(not self.open)end)
        self.burger.iconColorFixed=true;self.burger.button.ZIndex=21;self.burger.face.ZIndex=21;self.burger.iconImage.ZIndex=22
        self.burgerDot=nil
    end
    local inset=0;pcall(function()inset=game:GetService('GuiService'):GetGuiInset().Y/(UI.scale or 1)end)
    local portrait=h>w
    local by=(portrait and 12 or 8)-inset
    local bx=w-12-36
    self.burger.button.Visible=shown;self.burger:place(bx,by,36,36)
    require(script.Parent.OutgameIcons).set(self.burger.iconImage,self.open and 'x'or 'menu')
    self.burger.faceStroke.Color=self.open and K.colors.accent or K.colors.line;self.burger.faceStroke.Thickness=self.open and 2 or 1;self.burger.faceStroke.Transparency=self.open and 0 or .1
    local unread=a.quick and a.quick.unread or (a.eventLog and a.eventLog.unread)
    K.dot(self.burger.face,'Dot20',unread and not self.open or false,36-2,2,8)
    self.rankAt={x=bx-6-76,y=by+5}
    for i,b in ipairs(list)do if b then
        b.Visible=shown and self.open;b.ZIndex=21
        UI.box(b,bx-6,by+36+6+(i-1)*42-6,48,48)
        local tip=b:FindFirstChild('Tip')
        if tip then tip.Text=NAME20[b.Name]or tip.Text;tip.Visible=self.open;tip.BackgroundTransparency=1;tip.TextColor3=K.colors.ink;tip.TextSize=11;tip.TextXAlignment=Enum.TextXAlignment.Right
            local s=tip:FindFirstChild('Unscale');if s then s.Scale=1 end;UI.box(tip,-66,13,60,22)end
    end end
    self.list20=list
    self.menuShown=shown and self.open
end
function M:set20(open)
    self.open=open==true
    local l=self.last;if l then self:layout(table.unpack(l,1,7))end
    if not self.list20 then return end
    for i,b in ipairs(self.list20)do if b then
        if self.open then K.rehome(b);b:SetAttribute('Shown20',false);K.appear(b,{dy=-8,t=.14,delay=(i-1)*.03,noFade=true})
        end
    end end
end
function M:layout(w,h,touch,shown,sheet,buildTop,grid)
    self.last={w,h,touch,shown,sheet,buildTop,grid}
    if require(script.Parent.Hud20).ENABLED then return self:layout20(w,h,touch,shown,sheet)end
    local a=self.a;local busy=sheet or a.modeBar.Visible
    shown=shown and not(a.tactical and a.tactical.frame.Visible)
    local p=self.p;self.screen={w=w,h=h};self.shown=shown;p.dropping=a.drop and a.drop.active
    local phone=Placement.phone(w,h,touch);self.phone=phone
    self.portrait=grid~=nil and buildTop~=nil
    if (not (phone or self.portrait) or busy or not shown) and self.open then self.open=false end
    self:placementBand(w,h,phone);self:radial()
    for _,b in ipairs(self.members)do b.Parent=phone and self.tray or p.panel end
    self.stow=self.stow or UI.make('Frame',p.panel,{Name='BuildStow',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Visible=false})
    self.stowed=self.stowed or {}
    local fold=self.portrait and not p.dropping
    for _,b in ipairs(self.column)do if b then
        if fold and not self.open then if b.Parent~=self.stow then self.stowed[b]=b.Parent;b.Parent=self.stow end
        elseif self.stowed[b]then b.Parent=self.stowed[b];self.stowed[b]=nil end
    end end
    self.more.Visible=fold and shown~=false
    if fold then
        local x=w-52;local y=buildTop-48-4
        UI.box(self.more,x,y,48,48);self.more:SetAttribute('TouchLayout',true);self.more.Key.Visible=false;self.more.Tip.Visible=false
        if self.open then
            local r=a.ranks and a.ranks.frame;local top=r and r.Visible and r.Position.Y.Offset+r.Size.Y.Offset+4 or 8
            local rows=math.max(1,math.floor((y-top)/52));local k=0
            for _,b in ipairs(self.column)do if b and b.Visible then
                local row,col=k%rows+1,math.floor(k/rows);k+=1;UI.box(b,x-col*120,y-row*52,48,48)
                local tip=b:FindFirstChild('Tip')
                if tip then
                    if tip:GetAttribute('Full')==nil then tip:SetAttribute('Full',tip.Text)end
                    tip.Text=COLUMN[b.Name]or tip.Text;tip.Visible=true;tip.BackgroundTransparency=.12;tip.TextColor3=UI.colors.ink;UI.box(tip,-62,13,58,22)
                end
            end end
        else
            for _,b in ipairs(self.column)do local tip=b and b:FindFirstChild('Tip');if tip then tip.Visible=false;if tip:GetAttribute('Full')then tip.Text=tip:GetAttribute('Full')end end end
        end
        local plate=self.more:FindFirstChild('Plate')
        if plate then
            local m=Shortcut.PLATE.touch;UI.box(plate,(48-m)/2,(48-m)/2,m,m);plate.AnchorPoint=Vector2.zero;Style.round(plate,8)
            plate.BackgroundColor3=self.open and UI.colors.ink or Color3.new(0,0,0);plate.BackgroundTransparency=self.open and 0 or .28
            local icon=plate:FindFirstChild('Icon')
            if icon then for _,o in ipairs(icon:GetDescendants())do if o:IsA('Frame')and o.BackgroundTransparency<1 then o.BackgroundColor3=self.open and UI.colors.bg or UI.colors.ink end end end
        end
    end
    local menu=p.menu;local plate=p.menuPlate
    Shortcut.scale(menu,menu.Parent==p.panel and not p.dropping and not grid and Placement.pcScale(touch,w,h)or 1)
    if menu.Parent==p.panel and not p.dropping then
        local spot=Placement.shortcuts(w,h,touch).Menu;local size=48
        if not fold then UI.box(menu,spot.x,buildTop and math.min(spot.y,buildTop-size-4)or spot.y,size,size)end
        local s=phone and Shortcut.PLATE.phone or touch and not Placement.desk(w,h,touch) and Shortcut.PLATE.touch or 44
        UI.box(plate,(size-s)/2,(size-s)/2,s,s);Style.round(plate,phone and 10 or 8)
        plate.BackgroundColor3=phone and Color3.new(0,0,0)or Style.colors.cell;plate.BackgroundTransparency=phone and .28 or .04
        for i=1,3 do local bar=plate:FindFirstChild('Bar'..i);if bar then local bw=math.floor(s*.42);UI.box(bar,(s-bw)/2,math.floor(s/2)-6+(i-1)*5,bw,2)end end
    end
    if phone then
        Shortcut.place(self.toggle,w,h,nil,touch,0)
        local first=p.emoji;local last=p.motion
        local x0,y0=first.Position.X.Offset,first.Position.Y.Offset
        UI.box(self.backdrop,x0,y0-16,last.Position.X.Offset+48-x0,48+18)
        for _,b in ipairs(self.members)do
            local tip=b:FindFirstChild('Tip')
            if tip then tip.Text=NAMES[b.Name]or tip.Text;tip.Visible=true;tip.BackgroundTransparency=1;UI.box(tip,-2,-14,52,18);tip.TextColor3=UI.colors.ink end
        end
    end
    self:refresh();self.hidden={};self:aside()
end
return M
