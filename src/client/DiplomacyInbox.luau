local UI=require(script.Parent.Theme)
local Commands=require(script.Parent.Parent.Core.CommandPresentation)
local Speed=require(script.Parent.Parent.Core.GameSpeed)
local L=require(script.Parent.Localization)
local M={};M.__index=M
local V2=require(script.Parent.Hud20).ENABLED
function M.new(parent,send,showDetail)
    local panel=UI.panel(parent,"DiplomacyInbox");panel.ZIndex=18;panel.Visible=false
    local title=UI.label(panel,"Title","동맹 요청",14,UI.colors.accent)
    local detail=UI.label(panel,"Detail","",13)
    detail.Font=Enum.Font.BuilderSansBold;detail.TextTruncate=Enum.TextTruncate.AtEnd;detail.TextWrapped=false
    local remaining=UI.label(panel,'Remaining','',12,UI.colors.muted);remaining.TextXAlignment=Enum.TextXAlignment.Right
    local hands=require(script.Parent.AllianceGlyph).attach(panel);hands.Size=UDim2.fromOffset(18,14);hands.Position=UDim2.fromOffset(12,12)
    local self=setmetatable({panel=panel,title=title,detail=detail,remaining=remaining,send=send,hands=hands},M)
    self.avatar=UI.make('ImageLabel',panel,{Name='Avatar',BackgroundColor3=UI.colors.raised,BorderSizePixel=0,ZIndex=panel.ZIndex+1});UI.corner(self.avatar,40)
    self.edgeBar=require(script.Parent.EdgeMask).fit(UI.make('Frame',panel,{Name='Edge',BackgroundColor3=UI.colors.accent,BorderSizePixel=0,ZIndex=panel.ZIndex+1}))
    self.timeLine=UI.make('Frame',panel,{Name='TimeLeft',BackgroundColor3=UI.colors.accent,BorderSizePixel=0,ZIndex=panel.ZIndex+1})
    self.peek=UI.button(parent,'DiplomacyPeek','↔',function()if self.showDeferred then self.showDeferred()end end);self.peek.ZIndex=24;self.peek.Visible=false;self.peek.TextSize=22;self.peek.Text='';local hands=require(script.Parent.AllianceGlyph).attach(self.peek);hands.Size=UDim2.fromOffset(24,18);hands.Position=UDim2.fromOffset(8,14)
    self.badge=UI.label(self.peek,'Count','',14,UI.colors.accent);self.badge.TextXAlignment=Enum.TextXAlignment.Right;UI.box(self.badge,22,0,18,18)
    local function reply(kind)if self.request and not self.pending then
        self.pendingRequest=send('alliance',kind,self.request.from)
        self.pending=self.pendingRequest~=nil;self.pendingVersion=self.state.version;self.pendingAt=self.pending and os.clock()or nil
        UI.enabled(self.accept,not self.pending);UI.enabled(self.reject,not self.pending)
    end end
    self.accept=UI.button(panel,"Accept","수락",function()reply('accept')end,true)
    self.reject=UI.button(panel,"Reject","거절",function()reply('reject')end)
    self.inspect=UI.button(panel,'Inspect','상세',function()if self.request then showDetail(self.request.from)end end)
    self.next=UI.button(panel,'Next','다음',function()
        local list=self.state.diplomacy and self.state.diplomacy.incoming or {};local index=0
        for i,r in ipairs(list)do if self.pinned and r.from==self.pinned.from and r.created==self.pinned.created then index=i;break end end
        self.pinned=#list>0 and list[index%#list+1]or nil;self.expired=false;self.pending=false;self.pendingRequest=nil;self.pendingVersion=nil;self.pendingAt=nil;self:update(self.state)
    end)
    if V2 then self.showDetail=showDetail;self.pending20={};self.answered20={};self.known20={};require(script.Parent.Requests20).attach(panel)end
    return self
end
function M:update20(state)
    if self.state and self.state.version~=state.version then self.pending20={};self.answered20={};self.known20={}end
    self.state=state
    local incoming=state.diplomacy and state.diplomacy.incoming or {}
    self.count=#incoming;self.panel:SetAttribute('RequestCount',#incoming)
    local now=os.clock();local items,alive={},{}
    for _,r in ipairs(incoming)do
        local key='req:'..tostring(r.from)..':'..tostring(r.created)
        alive[key]=true
        if not self.known20[key]then require(script.Parent.TelemetryStep).step('match','allyReqShown',{count=#incoming})end
        local face;for _,f in ipairs(state.factions or {})do if f.id==r.from then face=f end end
        local pace=Speed.pace(state);local left=math.max(0,(r.expires-state.tick)/pace);local total=math.max(1,(r.expires-(r.created or state.tick))/pace)
        local p=self.pending20[key];if p and now-p>=8 then self.pending20[key]=nil;p=nil end
        table.insert(items,{key=key,kind='request',name=L.text(r.name or ''),userId=face and face.userId,ratio=math.clamp(left/total,0,1),pending=p~=nil,
            enabled=not state.paused and state.phase=='playing',
            accept=function()self:reply20('accept',r,key)end,decline=function()self:reply20('reject',r,key)end,
            inspect=function()if self.showDetail then self.showDetail(r.from)end end})
    end
    for key in pairs(self.known20)do if not alive[key]and not self.answered20[key]then require(script.Parent.TelemetryStep).step('match','allyReqExpired',{count=#incoming})end end
    self.known20=alive
    self.request=nil;self.expired=false;self.pinned=nil
    require(script.Parent.Requests20).set('request',items)
end
function M:reply20(kind,r,key)
    if self.pending20[key]or not self.state then return end
    local id=self.send('alliance',kind,r.from)
    self.pendingRequest=id;self.pendingVersion=self.state.version;self.pendingKey20=key;self.answered20[key]=true
    if kind=='accept'and id~=nil then self.pending20[key]=os.clock()end
end
function M:update(state)
    if V2 then return self:update20(state)end
    if self.state and self.state.version~=state.version then self.pinned=nil;self.pending=false;self.pendingRequest=nil;self.pendingVersion=nil;self.pendingAt=nil end
    if self.pendingAt and os.clock()-self.pendingAt>=8 then self.pending=false;self.pendingRequest=nil;self.pendingVersion=nil;self.pendingAt=nil end
    local incoming=state.diplomacy and state.diplomacy.incoming or {}
    self.state=state;self.count=#incoming;local request
    if self.pinned then for _,r in ipairs(incoming)do if r.from==self.pinned.from and r.created==self.pinned.created then request=r;break end end
    else request=incoming[1];self.pinned=request end
    local expired=self.pinned~=nil and request==nil
    if expired and not self.expired then require(script.Parent.TelemetryStep).step('match','allyReqExpired',{count=#incoming})end
    if request and request~=self.request then require(script.Parent.TelemetryStep).step('match','allyReqShown',{count=#incoming})end
    self.request=request;self.expired=expired
    self.panel:SetAttribute("RequestCount",#incoming)
    if self.request then
        self.title.Text="동맹을 요청했어요"
        self.detail.Text=L.text(self.request.name or '')
        local left=math.max(0,math.ceil((self.request.expires-state.tick)/Speed.pace(state)))
        self.remaining.Text=string.format('%d:%02d',left//60,left%60)..(#incoming>1 and ' +'..(#incoming-1)or '')
        local total=math.max(1,(self.request.expires-(self.request.created or state.tick))/Speed.pace(state))
        self.timeFraction=math.clamp(left/total,0,1)
        local face
        for _,f in ipairs(state.factions or {})do if f.id==self.request.from then face=f end end
        self.avatar.Image=face and face.userId and face.userId>0 and ('rbxthumb://type=AvatarHeadShot&id='..face.userId..'&w=150&h=150')or ''
        self.avatar.Visible=true;self.hands.Visible=self.avatar.Image==''
        local pw=self.panel.Size.X.Offset;if pw>24 then self.timeLine.Size=UDim2.fromOffset(math.floor((pw-24)*self.timeFraction),3)end
        self.title.Text=string.format('동맹 요청 %d초',left)
        UI.enabled(self.accept,not state.paused and not self.pending and state.phase=='playing');UI.enabled(self.reject,not state.paused and not self.pending and state.phase=='playing')
    elseif self.expired then
        self.title.Text='요청 종료';self.detail.Text=L.text(self.pinned.name or '');self.remaining.Text=tostring(#incoming);UI.enabled(self.accept,false);UI.enabled(self.reject,false)
    end
    self.next.Visible=#incoming>(request and 1 or 0);UI.enabled(self.inspect,request~=nil)
    if #incoming==0 and not request then self.pinned=nil;self.pending=false;self.pendingRequest=nil;self.pendingVersion=nil;self.pendingAt=nil;self.expired=false end
end
function M:result(r)
    if not Commands.acknowledges(self.pendingRequest,self.pendingVersion,r,'alliance')then return end
    if V2 and self.pendingKey20 then self.pending20[self.pendingKey20]=nil;self.pendingKey20=nil end
    self.pending=false;self.pendingRequest=nil;self.pendingVersion=nil;self.pendingAt=nil
    if self.state then self:update(self.state)end
end
function M:layout(w,h,obscured,battle,aiming)
    if V2 then self.peek.Visible=false;return require(script.Parent.Requests20).layout(w,h,obscured)end
    self.panel.Visible=((self.request~=nil or self.expired)and not obscured and not aiming and self.state and self.state.phase=='playing')==true
    self.peek.Visible=(self.request~=nil and aiming and not obscured and self.state and self.state.phase=='playing')==true
    self.badge.Text=tostring(self.count or 0);UI.box(self.peek,w-56,8,44,44)
    self.avatar.Visible=true;self.hands.Visible=self.avatar.Image=='';self.hands.ZIndex=self.avatar.ZIndex+1
    M.card(self.panel,{edge=self.edgeBar,avatar=self.avatar,name=self.detail,line=self.title,time=self.remaining,bar=self.timeLine,fraction=self.timeFraction,
        buttons={self.accept,self.reject,self.inspect},color=require(script.Parent.MatchSheet).SKY},w)
    self.hands.Position=UDim2.fromOffset(21,21)
    self.inspect.Text='보기';self.next.Visible=false
    if self.request then self.title.Text=string.format('동맹 요청 %d초',math.max(0,math.ceil((self.request.expires-self.state.tick)/Speed.pace(self.state))))end
    self.remaining.Visible=false
end
function M.card(panel,parts,w)
    local Style=require(script.Parent.HudStyle);local touch=require(script.Parent.InputMode).touch()
    local width=math.min(touch and 260 or 300,w-24);local bh=touch and 48 or 34
    local height=60+bh+10
    panel.Size=UDim2.fromOffset(width,height);panel.AnchorPoint=Vector2.zero
    Style.round(panel,10);panel.BackgroundColor3=Style.colors.panel;panel.BackgroundTransparency=.04;Style.line(panel,Style.colors.line,1)
    if parts.edge then UI.box(parts.edge,0,0,3,height);parts.edge.BackgroundColor3=parts.color;Style.round(parts.edge,2)end
    if parts.avatar then UI.box(parts.avatar,12,10,36,36);Style.round(parts.avatar,18)end
    local tx=parts.avatar and parts.avatar.Visible and 56 or 14
    UI.box(parts.name,tx,8,width-tx-12,22);parts.name.TextSize=15;parts.name.Font=Enum.Font.BuilderSansBold;parts.name.TextWrapped=false;parts.name.TextTruncate=Enum.TextTruncate.AtEnd;parts.name.TextColor3=UI.colors.ink
    UI.box(parts.line,tx,30,width-tx-12,20);parts.line.TextSize=13;parts.line.Font=Enum.Font.BuilderSansMedium;parts.line.TextColor3=UI.colors.muted;parts.line.TextWrapped=false;parts.line.TextTruncate=Enum.TextTruncate.AtEnd
    local n=#parts.buttons;local bw=(width-24-(n-1)*8)/n
    for i,b in ipairs(parts.buttons)do
        UI.box(b,12+(i-1)*(bw+8),58,bw,bh);b.TextSize=14;Style.round(b,6)
        if i==1 then b.BackgroundColor3=UI.colors.accent;b.TextColor3=UI.colors.bg;Style.line(b,UI.colors.accent,1)
        else b.BackgroundColor3=Style.colors.chip;b.TextColor3=UI.colors.ink;Style.line(b,Style.colors.line,1)end
    end
    if parts.bar then UI.box(parts.bar,12,height-5,math.floor((width-24)*math.clamp(parts.fraction or 1,0,1)),3);parts.bar.BackgroundColor3=parts.color;Style.round(parts.bar,1)end
end
return M
