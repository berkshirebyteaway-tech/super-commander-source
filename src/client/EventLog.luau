local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Sheet=require(script.Parent.MatchSheet)
local Shortcut=require(script.Parent.CornerShortcut)
local Hot=require(script.Parent.HotbarIcons)
local C=UI.colors
local M={};M.__index=M
M.KEEP=40
local GREEN=Color3.fromRGB(150,220,90)
local KINDS={{'all','전체'},{'battle','전투'},{'diplomacy','외교'},{'build','건설'}}
local function clock(tick)local s=math.floor((tick or 0)/10);return string.format('%02d:%02d',math.floor(s/60),s%60)end
local function has(t,list)for _,w in ipairs(list)do if string.find(t,w,1,true)then return true end end;return false end
function M.classify(message,warning,kind)
    if kind=='building'or has(message,{'건설','완공','지었','레벨','철거'})then return 'build',GREEN,'City'end
    if has(message,{'핵','수소','다탄두','미사일','폭발'})then return 'battle',C.danger,'AtomBomb'end
    if kind=='donation'or has(message,{'동맹','외교','지원','금수','교역','요청'})then return 'diplomacy',Sheet.SKY,'Alliance'end
    if has(message,{'공격','점령','함락','잃','격파','상륙','군함','병력'})then return 'battle',warning and C.danger or C.muted,'Sword'end
    if kind=='rejected'or warning then return 'fail',C.muted,'Soldier'end
    return 'other',Style.colors.line,'Crown'
end
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks or {},entries={},unread=0,open=false,filter='all',seen=0},M)
    self.button=Shortcut.new(parent,'EventLogButton',nil,'history',function()self:toggle()end,'기록');self.button.Visible=false
    self.badge=UI.make('TextLabel',self.button,{Name='Unread',Text='',TextSize=12,Font=Enum.Font.BuilderSansBold,TextColor3=C.bg,BackgroundColor3=C.accent,BorderSizePixel=0,Visible=false,ZIndex=24})
    UI.corner(self.badge,999);self.badge:SetAttribute('AllowOverlap',true);self.badge:SetAttribute('LocalizationSkip',true)
    local p=Sheet.frame(parent,'EventLog');self.panel=p
    self.head=Sheet.header(p,'경기 기록',function()self:toggle(false)end)
    self.chips=UI.make('Frame',p,{Name='Filters',BackgroundTransparency=1,ZIndex=25})
    self.body=UI.make('ScrollingFrame',p,{Name='Body',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=25,ScrollBarThickness=3,ScrollBarImageColor3=C.line,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y})
    return self
end
function M:add(message,warning,tile,tick,kind)
    if not message or message==''then return end
    local last=self.entries[1]
    if last and last.message==message and (tick or 0)-(last.tick or 0)<50 then last.count+=1;last.tick=tick;last.tile=tile or last.tile
    else
        local k,color,icon=M.classify(message,warning==true,kind)
        table.insert(self.entries,1,{message=message,warning=warning==true,tile=tile,tick=tick,count=1,kind=k,color=color,icon=icon})
        if #self.entries>M.KEEP then table.remove(self.entries)end
    end
    if not self.open then self.unread+=1 end
    self:draw()
end
function M:reset()self.entries={};self.unread=0;self:toggle(false)end
function M:toggle(on)
    if on==nil then on=not self.open end
    if on==true and not self.open then require(script.Parent.TelemetryStep).step('hud','logOpen',{count=self.unread or 0});self.fresh=self.unread;self.filter='all'end
    self.open=on==true;if self.open then self.unread=0 end
    self:draw();if self.onToggle then self.onToggle()end
end
local function v2()local ok,H=pcall(require,script.Parent.Hud20);return ok and type(H)=='table'and H.ENABLED==true end
local BAND
function M:draw20()
    local K=require(script.Parent.Kit20);local L=require(script.Parent.Localization);local p=self.panel
    BAND=BAND or {battle=K.colors.danger,diplomacy=K.colors.ally,build=K.colors.muted,fail=K.colors.muted,other=K.colors.line}
    self.badge.Visible=false
    K.dot(self.button,'Dot20',self.unread>0 and not self.open,44,4,10)
    local want=self.open and self.shown==true
    if want and(not p.Visible or Sheet.closing(p))then Sheet.show20(p)elseif not want and p.Visible and not Sheet.closing(p)then Sheet.hide20(p)end
    if not want or not self.r then return end
    local r=self.r;local cw=r.w-26
    for _,o in ipairs({self.head.title,self.head.sub,self.head.close})do o.Visible=false end
    Sheet.placeHead20(p,r.w)
    local t=p:FindFirstChild('Title20')or K.text(p,'Title20','기록',16,K.colors.ink,800);t.ZIndex=p.ZIndex+2;K.box(t,15,0,120,48)
    for _,o in ipairs(self.chips:GetChildren())do o:Destroy()end
    local x=0
    for _,k in ipairs(KINDS)do
        local b,w=Sheet.chip20(self.chips,'Filter_'..k[1],k[2],self.filter==k[1],12,function()
            if self.filter==k[1]then return end
            self.filter=k[1];require(script.Parent.TelemetryStep).step('hud','logFilter',{item=k[1]});self:draw()
        end)
        b:place(x,5,w,30);Sheet.fill20(b);x+=w+6
    end
    K.box(self.chips,13,54,cw,40);self.chips.ZIndex=p.ZIndex+2
    local body=self.body;body.ScrollBarThickness=2;K.scrollPad(body,2)
    K.box(body,9,97,r.w-18,r.h-97-8);body.ZIndex=p.ZIndex+1
    for _,o in ipairs(body:GetChildren())do if not o:IsA('UIPadding')then o:Destroy()end end
    local rw=r.w-22;local rowH=r.fmt=='ph'and 40 or 44;local y=0;local shown=0
    for i,e in ipairs(self.entries)do
        if self.filter=='all'or e.kind==self.filter then
            shown+=1
            local band=BAND[e.kind]or BAND.other
            local new=i<=(self.fresh or 0)
            local bar=K.fillBar(body,'Row'..i,{parts={{p=3/rw,color=new and band or band:Lerp(K.colors.panel,.5)}},track=K.colors.panel,r=4})
            local row=bar.frame;K.box(row,0,y,rw,rowH);row.ZIndex=body.ZIndex+1;row.Active=true
            local tm=K.num(row,'Time',clock(e.tick),12,K.colors.muted);K.box(tm,15,0,38,rowH);tm.ZIndex=row.ZIndex+1
            local icon=Hot.create(row,e.icon,15,band);icon.Position=UDim2.fromOffset(63,math.floor((rowH-15)/2));icon.ZIndex=row.ZIndex+1
            local more=e.tile~=nil
            local m=K.text(row,'Message',e.message..(e.count>1 and ' ×'..e.count or ''),13,e.kind=='fail'and K.colors.muted or K.colors.ink,700);m.ZIndex=row.ZIndex+1
            K.box(m,88,0,rw-88-(more and 64 or 12),rowH)
            if more then
                local tile=e.tile
                local b=K.button(row,'Show',{kind='none',text='보기 ›',size=12,weight=800,hit=rowH},function()
                    if self.callbacks.focus then require(script.Parent.TelemetryStep).step('hud','logFocus',{item=e.kind});self.callbacks.focus(tile)end
                end)
                b:place(rw-64,0,64,rowH);b.label.TextColor3=K.colors.accent;b.label.Position=UDim2.new();b.label.Size=UDim2.new(1,-12,1,0);b.label.TextXAlignment=Enum.TextXAlignment.Right
                b.button.ZIndex=row.ZIndex+2
            end
            y+=rowH+4
        end
    end
    if shown==0 then
        local empty=K.text(body,'Empty',L.text('기록 없음'),14,K.colors.muted,700,Enum.TextXAlignment.Center);empty.ZIndex=body.ZIndex+1;K.box(empty,0,12,rw,48);y=64
    end
    body.CanvasSize=UDim2.fromOffset(0,y+4)
end
function M:draw()
    if v2()then return self:draw20()end
    self.badge.Visible=self.unread>0 and not self.open
    self.badge.Text=self.unread>9 and '9+'or tostring(self.unread)
    self.panel.Visible=self.open and self.shown==true
    if not self.panel.Visible or not self.r then return end
    local r=self.r;local touch=self.touch;local w=r.w-32
    local top=Sheet.placeHeader(self.head,r.w,touch)
    for _,o in ipairs(self.chips:GetChildren())do o:Destroy()end
    local ch=touch and 48 or 34;local x=0
    for _,k in ipairs(KINDS)do
        local cw=touch and 60 or 52
        local b=Sheet.chip(self.chips,'Filter_'..k[1],k[2],function()self.filter=k[1];require(script.Parent.TelemetryStep).step('hud','logFilter',{item=k[1]});self:draw()end,self.filter==k[1],touch)
        UI.box(b,x,0,cw,ch);x+=cw+8
    end
    UI.box(self.chips,16,top,w,ch)
    local by=top+ch+8;UI.box(self.body,16,by,w+6,r.h-by-10)
    for _,o in ipairs(self.body:GetChildren())do o:Destroy()end
    local rowH=touch and 48 or 40;local y=0;local shown=0
    for i,e in ipairs(self.entries)do
        if self.filter=='all'or e.kind==self.filter then
            shown+=1
            if i==(self.fresh or 0)+1 and shown>1 then
                local l=Sheet.caption(self.body,'OlderTitle','이전 기록',0,y+2,70);local rule=UI.make('Frame',self.body,{Name='OlderRule',BackgroundColor3=Style.colors.line,BorderSizePixel=0,ZIndex=26});UI.box(rule,74,y+13,w-74,1);y+=28;l.ZIndex=26
            end
            local new=i<=(self.fresh or 0)
            local row=UI.make('Frame',self.body,{Name='Row'..i,BackgroundColor3=Style.colors.cell,BackgroundTransparency=new and .1 or 1,BorderSizePixel=0,ZIndex=26,Active=true});UI.box(row,0,y,w,rowH-4);Style.round(row,6)
            local edge=UI.make('Frame',row,{Name='Edge',BackgroundColor3=e.color,BorderSizePixel=0,ZIndex=27});UI.box(edge,0,4,3,rowH-12);Style.round(edge,2)
            local t=Sheet.caption(row,'Time',clock(e.tick),12,(rowH-4-22)/2,44);t.ZIndex=27
            local icon=Hot.create(row,e.icon,18,e.kind=='fail'and C.muted or C.ink);icon.Position=UDim2.fromOffset(60,(rowH-4-18)/2);icon.ZIndex=27
            local more=e.tile~=nil
            local m=UI.label(row,'Message',e.message..(e.count>1 and ' ×'..e.count or ''),14,e.kind=='fail'and C.muted or C.ink);m.TextWrapped=false;m.TextTruncate=Enum.TextTruncate.AtEnd;m.ZIndex=27
            if new then m.Font=Enum.Font.BuilderSansBold end
            UI.box(m,88,0,w-88-(more and 64 or 8),rowH-4)
            if more then
                local tile=e.tile
                local b=UI.button(row,'Show','보기 ›',function()if self.callbacks.focus then require(script.Parent.TelemetryStep).step('hud','logFocus',{item=e.kind});self.callbacks.focus(tile)end end)
                b.BackgroundTransparency=1;b.TextColor3=Sheet.SKY;b.TextSize=13;b.TextXAlignment=Enum.TextXAlignment.Right;UI.box(b,w-60,touch and -2 or 0,58,touch and 48 or rowH-4);b.ZIndex=28
                local s=b:FindFirstChildOfClass('UIStroke');if s then s.Enabled=false end
            end
            y+=rowH
        end
    end
    if shown==0 then
        local empty=UI.label(self.body,'Empty','기록 없음',14,C.muted);empty.TextXAlignment=Enum.TextXAlignment.Center;empty.ZIndex=26;UI.box(empty,0,12,w,48)
        y=64
    end
    self.body.CanvasSize=UDim2.fromOffset(0,y)
end
function M:layout(w,h,show,menu,touch)
    self.screenW=w;self.screenH=h
    self.shown=show==true
    if type(menu)~='table'then menu=nil;touch=false end
    self.button.Visible=self.shown;Shortcut.place(self.button,w,h,menu,touch,3)
    UI.box(self.badge,self.button.Size.X.Offset-20,0,20,18)
    local controls=self.button.Parent and self.button.Parent:FindFirstChild('Controls')
    if v2()then
        local r=Sheet.rect20(w,h,true);self.r=r;self.touch=Sheet.touch()
        Sheet.paint20(self.panel,r.portrait);Sheet.place20(self.panel,r);Sheet.motion20(self.panel);self.panel.AnchorPoint=Vector2.zero
        Sheet.head20(self.panel,function()self:toggle(false)end)
        self:draw();return
    end
    local r=Sheet.rect(w,h,Sheet.touch(),controls and controls.Visible and controls.Position.Y.Offset or nil)
    self.r=r;self.touch=Sheet.touch();UI.box(self.panel,r.x,r.y,r.w,r.h);self.panel.AnchorPoint=Vector2.zero
    self:draw()
end
return M
