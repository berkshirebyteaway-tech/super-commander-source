local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Shortcut=require(script.Parent.CornerShortcut)
local Placement=require(script.Parent.Parent.Core.InterfacePlacement)
local M={};M.__index=M
local NAMES={FavoriteEmojis='이모지',QuickMessages='대화',MotionShortcut='모션'}
local COLUMN={FavoriteEmojis='이모지',QuickMessages='대화',MotionShortcut='모션',EventLogButton='기록',CameraShortcut='내 위치'}
function M.new(panel,menu,a)
    local p={panel=panel,menu=menu,menuPlate=a.menuPlate,emoji=a.chat.emojiButton,quick=a.chat.quickButton,motion=a.motionShortcut,
        mode={bar=a.modeBar,title=a.modeTitle,hint=a.modeHint,cancel=a.modeCancel,all=a.modeAll}}
    local self=setmetatable({p=p,a=a,open=false,phone=false},M)
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
function M:radial()
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
function M:layout(w,h,touch,shown,sheet,buildTop,grid)
    self.last={w,h,touch,shown,sheet,buildTop,grid}
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
