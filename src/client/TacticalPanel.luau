local UI=require(script.Parent.Theme)
local Icons=require(script.Parent.UIIcons)
local Amount=require(script.Parent.Parent.Core.SupportAmount)
local Players=game:GetService('Players')
local L=require(script.Parent.Localization)
local M={};M.__index=M
local labels={detail='상세',signals='신호',emoji='이모지',advanced='더 보기'}
local signals={{'attack','공격 요청'},{'defend','방어 요청'},{'troops','병력 요청'},{'gold','골드 요청'},{'peace','평화 제안'},{'thanks','감사'}}
local function text(p,n,t,x,y,w,h,size,c)local o=UI.label(p,n,t,size or 14,c);UI.box(o,x,y,w,h);return o end
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks,ratio=1/3,tab='detail'},M)
    self.frame=UI.panel(parent,'TacticalPanel');self.frame.BackgroundTransparency=.04;self.frame.ZIndex=24;self.frame.Visible=false
    self.avatar=UI.make('ImageLabel',self.frame,{Name='Avatar',BackgroundColor3=UI.colors.raised,BorderSizePixel=0})
    self.npc=require(script.Parent.UIIcons).create(self.avatar,'npc',36)
    self.name=UI.label(self.frame,'Name','',18);self.name.TextWrapped=false;self.name.TextTruncate=Enum.TextTruncate.AtEnd;self.name:SetAttribute('LocalizationSkip',true)
    self.relation=UI.label(self.frame,'Relation','',12,UI.colors.accent)
    self.close=UI.button(self.frame,'Close','×',function()self:hide()end)
    self.stats=UI.button(self.frame,'Stats','',function()self.exactStats=not self.exactStats;self:refreshStats()end);self.stats.TextSize=13;self.stats.TextXAlignment=Enum.TextXAlignment.Left
    self.tabs={};for _,k in ipairs({'detail','signals','emoji','advanced'})do self.tabs[k]=UI.button(self.frame,'Tab_'..k,labels[k],function()self.tab=k;self:draw()end)end
    self.body=UI.make('ScrollingFrame',self.frame,{Name='Body',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=UI.colors.line,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y})
    return self
end
function M:hide()self.frame.Visible=false;self.targetId=nil;self.exactInput=nil;self.routeSerial=(self.routeSerial or 0)+1 end
function M:open(id,tab,tile)
    if not id or id==1 then return end
    self.routeSerial=(self.routeSerial or 0)+1;self.route=nil;self.routeAt=nil;self.routePending=false
    require(script.Parent.TelemetryStep).step('match','tacticalOpen',{item=tab or 'detail'})
    self.targetId=id;self.tab=tab or 'detail';self.scope=nil;self.emojiScope='player';self.signalTile=tile;self.exactStats=false;self.exactInput=nil;self.frame.Visible=true;self:draw()
end
function M:allowed()return self.state and self.state.phase=='playing'and not self.state.paused and self.target and not self.target.eliminated and self.target.tiles>0 end
function M:button(name,value,y,fn,primary,x,width)
    local b=UI.button(self.body,name,value,fn,primary);UI.box(b,x or 2,y,width or self.width-24,(self.rowStep or 48)-4);b.TextSize=14;return b
end
function M:statCells()
    if self.cells then return self.cells end
    local Hot=require(script.Parent.HotbarIcons);local Style=require(script.Parent.HudStyle)
    self.cells={}
    self.statsRow=UI.make('Frame',self.frame,{Name='StatsRow',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=self.frame.ZIndex})
    for i,k in ipairs({{'troops','병력','Soldier'},{'gold','골드','Gold'},{'land','영토','Crown'}})do
        local c=UI.make('Frame',self.statsRow,{Name='Stat_'..k[1],BackgroundColor3=Style.colors.chip,BorderSizePixel=0,ZIndex=self.frame.ZIndex+1,Active=false})
        Style.round(c,6);Style.line(c,Style.colors.line,1)
        local cap=UI.label(c,'Caption',k[2],13,UI.colors.muted);cap.ZIndex=c.ZIndex+1;cap.TextWrapped=false
        local icon=k[1]~='land'and Hot.create(c,k[3],15,k[1]=='gold'and UI.colors.gold or UI.colors.ink)or nil;if icon then icon.ZIndex=c.ZIndex+1 end
        local v=UI.label(c,'Value','',15,UI.colors.ink);v.Font=Enum.Font.BuilderSansBold;v.ZIndex=c.ZIndex+1;v.TextWrapped=false;v.TextTruncate=Enum.TextTruncate.AtEnd;v:SetAttribute('LocalizationSkip',true)
        self.cells[i]={root=c,cap=cap,icon=icon,value=v}
    end
    return self.cells
end
function M:refreshStats()
    local f=self.target;local cells=self:statCells()
    self.stats.Text=''
    if not f then for _,c in ipairs(cells)do c.value.Text='—'end;return end
    local number=self.exactStats and function(n)return tostring(n)end or UI.number
    local troops=self.exactStats and function(n)return tostring(math.floor(n/10))end or UI.troops
    cells[1].value.Text=troops(f.troops)..' / '..troops(f.cap);cells[2].value.Text=number(f.gold);cells[3].value.Text=string.format('%.2f%%',f.share*100)
end
function M:update(state,factions)
    local version=self.state and self.state.version;self.state=state;self.factions=factions
    if state.phase=='menu'or version and version~=state.version then self:hide();return end
    if not self.frame.Visible then return end
    self.target=factions[self.targetId];local f=self.target
    local name=f and L.nation(f) or '—';if self.name.Text~=name then self.name.Text=name;UI.fit(self.name,self.name.Size.X.Offset,18,12)end
    self.avatar.Image=f and f.userId and f.userId>0 and 'rbxthumb://type=AvatarHeadShot&id='..f.userId..'&w=150&h=150'or '';self.npc.Visible=self.avatar.Image==''
    self.relation.Text=not f and '대상 탈락'or f.teammate and '같은 팀'or f.allied and ('동맹 '..math.max(0,math.ceil(((f.allianceExpires or state.tick)-state.tick)/10))..'초')or f.incomingRequest and '동맹 요청 받음'or f.requested and '동맹 응답 대기'or '상대'
    self:refreshStats()
    local sig=table.concat({tostring(f and f.allied),tostring(f and f.teammate),tostring(f and f.incomingRequest),tostring(f and f.requested),state.phase},':')
    if self.signature~=sig then self.signature=sig;self:draw()end
    local can=self:allowed();for _,b in ipairs(self.body:GetChildren())do if b:IsA('TextButton')and b:GetAttribute('Action')then UI.enabled(b,can and b:GetAttribute('Permitted')~=false)end end
    if self.boatButton then
        self.boatButton.Text='수송 공격 '..UI.troops(math.floor((state.player.troops or 0)*self.callbacks.fraction()))
        UI.enabled(self.boatButton,can and self.route and self.route.transport==true or false)
        if can and not self.routePending and os.clock()-(self.routeAt or -10)>=1 then
            self.routePending=true;self.routeAt=os.clock();local serial=self.routeSerial;local id=self.targetId;local version=state.version
            task.spawn(function()
                local ok,route=pcall(self.callbacks.preview,id,self.signalTile or f.labelTile,version)
                if self.routeSerial~=serial or self.targetId~=id or not self.state or self.state.version~=version then return end
                self.routePending=false;self.route=ok and route or nil
                if self.frame.Visible then self:update(self.state,self.factions)end
            end)
        end
    end
    if self.sendAmount then
        local input=Amount.displayInput(self.resource,self.exactInput and self.exactInput.Text or nil)
        local n,max=Amount.amount(state,f or {},self.resource,self.ratio,input)
        self.amount=n;self.sendAmount.Text=(self.resource=='gold'and '골드 'or '병력 ')..(self.resource=='gold'and UI.number or UI.troops)(n or 0)..' 보내기'
        local ready=can and f.allied and (self.resource=='gold'and f.canDonateGold or self.resource=='troops'and f.canDonateTroops)and n and n>=1
        UI.enabled(self.sendAmount,ready==true);self.amountHint.Text=max==0 and '보낼 수 있는 자원이 없어요.'or self.resource=='troops'and ('상대 병력 여유 '..UI.troops(math.max(0,f.cap-f.troops)))or '내 골드 기준, 정확한 수량 입력 가능'
    end
    for kind,b in pairs(self.supportButtons or {})do
        local wait=f and math.ceil(f.donationAvailableIn or 0)or 0
        local n=f and Amount.amount(state,f,kind,1/3)or 0
        b.Text=wait>0 and ('다음 지원 '..wait..'초')or (kind=='gold'and '골드 'or '병력 ')..(kind=='gold'and UI.number or UI.troops)(n)..' 지원'
        UI.enabled(b,can and f.allied and (kind=='gold'and f.canDonateGold or kind=='troops'and f.canDonateTroops)and n>0)
    end
end
function M:draw()
    if not self.width or not self.targetId then return end
    self.target=self.factions and self.factions[self.targetId];local f=self.target;local w=self.width-24
    local S=self.rowStep or 48
    if self.sendAmount then self.sendAmount:Destroy()end
    for _,o in ipairs(self.body:GetChildren())do o:Destroy()end
    self.body.CanvasPosition=Vector2.zero;self.sendAmount=nil;self.exactInput=nil;self.supportButtons={};self.boatButton=nil;local y=0
    local function action(name,value,fn,primary,x,width)
        local b=self:button(name,value,y,fn,primary,x,width);b:SetAttribute('Action',true);return b
    end
    local function alliance(kind)self.callbacks.send('alliance',kind,self.targetId)end
    if not f then text(self.body,'Gone','이 대상은 전장에서 탈락했어요.',2,0,w,44,14,UI.colors.muted);y=52
    elseif self.tab=='support'then
        if not self.screenH or self.screenH>=500 then text(self.body,'Resource',self.resource=='gold'and '골드 지원량'or '병력 지원량',2,y,w,26,14,UI.colors.accent);y+=30 end
        for i,v in ipairs({.1,.25,.5,.75,1})do self:button('Ratio'..i,tostring(v*100)..'%',y,function()require(script.Parent.TelemetryStep).step('match','supportAmount',{item='ratio',value=v*100});self.ratio=v;if self.exactInput then self.exactInput.Text=''end;self:update(self.state,self.factions)end,v==self.ratio,2+(i-1)*w/5,w/5-4)end;y+=S
        self.exactInput=UI.make('TextBox',self.body,{Name='ExactAmount',Text='',PlaceholderText='정확한 수량',ClearTextOnFocus=false,TextSize=16,Font=Enum.Font.BuilderSansMedium,TextColor3=UI.colors.ink,BackgroundColor3=UI.colors.raised,BorderSizePixel=0});UI.box(self.exactInput,2,y,w,44);y+=S
        self.amountHint=text(self.body,'Capacity','',2,y,w,24,12,UI.colors.muted);y+=28
        self.sendAmount=action('SendAmount','',function()if self.amount and self.amount>0 then self.callbacks.send('support',self.resource,{target=self.targetId,amount=self.amount})end end,true);self.sendAmount.Parent=self.frame
        self.exactInput:GetPropertyChangedSignal('Text'):Connect(function()self:update(self.state,self.factions)end)
    elseif self.tab=='signals'then
        local default=self.state.player.team and 'team'or (f.allied or not self.state.multiplayer)and 'player'or 'allies';self.scope=self.scope or default
        for i,scope in ipairs({'player','team','allies','all'})do
            local short={player='상대',team='팀',allies='동맹',all='전체'}
            local b=self:button('Scope_'..scope,short[scope],y,function()self.scope=scope;self:draw()end,scope==self.scope,2+(i-1)*w/4,w/4-4)
            b.TextSize=14;UI.enabled(b,scope~='team'or self.state.player.team~=nil)
        end;y+=S
        for i,s in ipairs(signals)do local row=(i-1)//2;local x=2+(i-1)%2*w/2
            local b=self:button('Signal_'..s[1],s[2],y+row*S,function()self.callbacks.send('comms','signal',{target=self.targetId,value={key=s[1],scope=self.scope,tile=self.signalTile or f.labelTile}})end,false,x,w/2-4);b:SetAttribute('Action',true)
            local icon=s[1]=='troops'and Icons.create(b,'troops',18)or UI.label(b,'SignalIcon',({attack='↑',defend='◇',gold='$',peace='↔',thanks='✓'})[s[1]],18,s[1]=='gold'and UI.colors.gold or UI.colors.accent)
            UI.box(icon,-14,13,18,18);local pad=Instance.new('UIPadding');pad.PaddingLeft=UDim.new(0,20);pad.Parent=b
        end;y+=3*S
        self:button('Catalog','작전 메시지 전체',y,function()self.callbacks.more('messagePicker',self.targetId)end);y+=S
    elseif self.tab=='emoji'then
        for i,scope in ipairs({'player','all'})do self:button('EmojiScope_'..scope,scope=='all'and '전체에게'or '이 상대에게',y,function()self.emojiScope=scope;self:draw()end,scope==self.emojiScope,2+(i-1)*w/2,w/2-4)end;y+=S
        local favorites=self.callbacks.favorites();local VipLock=require(script.Parent.VipLock)
        local list=#favorites>0 and favorites or VipLock.isVip()and {'👍','🫡','🤝','🕊️','🆘','😎'}or {'🕊️','🏳️','❤️','🥰','👏','🤡'}
        for i=1,math.min(6,#list)do local e=list[i];local b=self:button('Emoji'..i,e,y+(i-1)//3*S,function()self.callbacks.send('comms','emoji',{target=self.emojiScope=='all'and 0 or self.targetId,value=e})end,false,2+(i-1)%3*w/3,w/3-4);b.TextSize=24;b:SetAttribute('Action',true)
            if not VipLock.allows('emoji',e)then b.TextTransparency=.5;VipLock.tag(b,w/3-36,3)end
        end;y+=math.ceil(math.min(6,#list)/3)*S
        self:button('Catalog','전체 이모지',y,function()self.callbacks.more('emojiPicker',self.emojiScope=='all'and 0 or self.targetId)end);y+=S
    elseif self.tab=='break'then
        text(self.body,'Warning','동맹 파기 시 배신 상태와 전투 불이익이 적용돼요.',2,0,w,70,14,UI.colors.danger);y=78
        action('ConfirmBreak','동맹 파기',function()require(script.Parent.TelemetryStep).step('match','breakConfirm',{result='accepted'});alliance('break');self.tab='detail';self:draw()end);y+=S
        self:button('CancelBreak','동맹 유지',y,function()require(script.Parent.TelemetryStep).step('match','breakCancel',{result='cancelled'});self.tab='detail';self:draw()end,true);y+=S
    elseif self.tab=='advanced'then
        action('Embargo',f.embargoed and '무역 금수 해제'or '무역 금수',function()self.callbacks.send('support',f.embargoed and 'embargoStop'or 'embargoStart',self.targetId)end);y+=S
        text(self.body,'Trade',f.embargoedBy and '상대가 교역을 막고 있어요.'or '해상과 철도 교역에 함께 적용돼요.',2,y,w,44,12,UI.colors.muted);y+=S
        local counts={};for _,u in ipairs(self.state.units or {})do if u.owner==self.targetId then counts[u.kind]=(counts[u.kind]or 0)+1 end end
        local names=require(script.Parent.Parent.Core.UnitRules).names;local lines={};for kind,n in pairs(counts)do table.insert(lines,(names[kind]or kind)..' '..n)end;table.sort(lines)
        text(self.body,'Buildings',#lines>0 and table.concat(lines,', ')or '건물 없음',2,y,w,80,13,UI.colors.muted);y+=84
    else
        if not f.allied then
            local half=self.twoCol and (w-4)/2 or nil
            action('Target','공동 공격 목표',function()self.callbacks.send('comms','target',{target=self.targetId})end,false,2,half);if not half then y+=S end
            self.boatButton=action('Boat','수송 공격',function()self.callbacks.boat(self.targetId,self.route and self.route.tile)end,false,half and 6+half or 2,half);self.boatButton:SetAttribute('Permitted',false);y+=S
            if half then self.boatButton.TextSize=13 end
        end
        if f.allied then
            for _,kind in ipairs({'troops','gold'})do
                self.supportButtons[kind]=action('Support_'..kind,'',function()self.callbacks.send('support',kind,self.targetId)end,kind=='troops',2,w-52)
                self:button('Adjust_'..kind,'양',y,function()self.tab='support';self.resource=kind;self:draw()end,false,w-46,44);y+=S
            end
            if not f.teammate then action('Extend','동맹 연장 요청',function()alliance('extend')end);y+=S
                self:button('Break','동맹 파기…',y,function()self.tab='break';self:draw()end);y+=S end
        elseif f.incomingRequest then action('Accept','동맹 수락',function()alliance('accept')end,true);y+=S;action('Reject','거절',function()alliance('reject')end);y+=S
        else local b=action('Alliance',f.requested and '동맹 응답 대기'or '동맹 요청',function()alliance('request')end,true);b:SetAttribute('Permitted',not f.requested and not self.state.settings.disableAlliances and self.state.settings.customAllianceDuration~=0);y+=S end
    end
    self.body.CanvasSize=UDim2.fromOffset(0,y+4)
    for k,b in pairs(self.tabs)do b.BackgroundColor3=k==self.tab and UI.colors.accent or UI.colors.raised;b.TextColor3=k==self.tab and UI.colors.bg or UI.colors.ink end
    if self.state then self:update(self.state,self.factions)end
    if self.screenW then self:layout(self.screenW,self.screenH)end
end
function M:layout(w,h)
    self.screenW=w;self.screenH=h
    local Sheet=require(script.Parent.MatchSheet);local controls=self.frame.Parent:FindFirstChild('Controls')
    local r=Sheet.rect(w,h,Sheet.touch(),controls and controls.Visible and controls.Position.Y.Offset or nil)
    local width=r.w;local height=r.h;self.sheetY=r.y
    local Placement=require(script.Parent.Parent.Core.InterfacePlacement);local floor=h-Placement.PHONE_HUD-4
    if r.phone then width=math.min(272,w-24);height=floor-8 end
    local step=require(script.Parent.InputMode).touch()and 52 or 48;local two=h<500 and w>h and w>=560
    if self.width~=width or self.rowStep~=step or self.twoCol~=two then self.width=width;self.rowStep=step;self.twoCol=two;self:draw()end
    local Style=require(script.Parent.HudStyle);local phone=h<500
    Style.round(self.frame,10);self.frame.BackgroundColor3=Style.colors.panel;self.frame.BackgroundTransparency=.04
    UI.box(self.frame,self.twoCol and w-width-56 or r.x,8,width,height);UI.box(self.avatar,14,12,44,44);Style.round(self.avatar,22);self.avatar.BackgroundColor3=Style.colors.cell
    UI.box(self.name,68,10,width-128,26);self.name.Font=Enum.Font.BuilderSansBold
    local rw=math.min(width-128,math.max(44,#self.relation.Text*7+20))
    UI.box(self.relation,68,36,rw,20);self.relation.TextSize=13;self.relation.TextXAlignment=Enum.TextXAlignment.Center
    self.relation.BackgroundColor3=Style.colors.chip;self.relation.BackgroundTransparency=0;Style.round(self.relation,10)
    local cs=step>48 and 48 or 40;UI.box(self.close,width-cs-12,10,cs,cs);self.close.BackgroundColor3=Style.colors.chip;Style.round(self.close,8);Style.line(self.close,Style.colors.line,1);self.close.TextSize=18
    local compact=phone and (h<340 or self.tab~='detail'and self.tab~='advanced');self.stats.Visible=not compact
    local sh=phone and 30 or 52;local top=phone and 48 or 64
    if phone then UI.box(self.avatar,12,8,36,36);Style.round(self.avatar,18);UI.box(self.name,56,6,width-110,22);UI.box(self.relation,56,28,rw,18);UI.box(self.close,width-52,2,48,48)end
    UI.fit(self.name,self.name.Size.X.Offset,18,12)
    UI.box(self.stats,12,top,width-24,sh);self.stats.BackgroundTransparency=1;self.stats.ZIndex=self.frame.ZIndex+3
    local cells=self:statCells();UI.box(self.statsRow,12,top,width-24,sh);self.statsRow.Visible=not compact
    if phone then self.stats.Visible=false end
    local share={.44,.30,.26};local cx=0
    for i,c in ipairs(cells)do
        local cw=math.floor((width-24-8)*share[i])
        UI.box(c.root,cx,0,cw,sh);cx+=cw+4;c.cap.Visible=not phone
        local ix=8;local vy=phone and 0 or 22;local vh=phone and sh or 26
        UI.box(c.cap,8,4,cw-12,18)
        if c.icon then UI.box(c.icon,ix,vy+(vh-15)/2,15,15)end
        UI.box(c.value,c.icon and ix+19 or ix,vy,cw-(c.icon and ix+23 or ix+4),vh);c.value.TextSize=phone and 13 or 15
    end
    local ty=compact and top or top+sh+(phone and 4 or 10);local th=(self.rowStep or 48)-4;local by=ty+th+(phone and 4 or 8)
    for i,k in ipairs({'detail','signals','emoji','advanced'})do
        local b=self.tabs[k];UI.box(b,12+(i-1)*(width-24)/4,ty,(width-24)/4-4,th);b.TextSize=14;Style.round(b,6)
        local on=k==self.tab;b.BackgroundColor3=on and UI.colors.ink or Style.colors.chip;b.TextColor3=on and UI.colors.bg or UI.colors.muted
    end
    local top=self.twoCol and 52 or self.sheetY or 84
    if not self.sendAmount then
        local need=by+self.body.CanvasSize.Y.Offset+(phone and 2 or 6)
        if self.twoCol then
            height=math.min(height,math.max(by+100,need));top=math.max(8,math.min(52,floor-height))
        else height=math.min(height,math.max(by+150,need))end
        self.frame.Size=UDim2.fromOffset(width,height)
    end
    self.frame.Position=UDim2.fromOffset(self.frame.Position.X.Offset,top)
    UI.box(self.body,10,by,width-20,height-by-(self.sendAmount and 62 or 6))
    for _,b in ipairs(self.body:GetChildren())do if b:IsA('TextButton')then Style.round(b,6)
        if b.BackgroundColor3~=UI.colors.accent then b.BackgroundColor3=Style.colors.chip;Style.line(b,Style.colors.line,1)end end end
    if self.sendAmount then UI.box(self.sendAmount,12,height-56,width-24,(self.rowStep or 48)-4);Style.round(self.sendAmount,6)end
end
return M
