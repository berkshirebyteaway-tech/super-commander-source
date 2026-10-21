local UI=require(script.Parent.Theme)
local L=require(script.Parent.Localization)
local Catalog=require(script.Parent.Parent.Core.CommsCatalog)
local phrase={};for _,m in ipairs(Catalog.messages)do phrase[m.key]=m.text end
local Chat=game:GetService('TextChatService')
local Http=game:GetService('HttpService')
local Me=game.Players.LocalPlayer
local Pack=game.ReplicatedStorage.FrontierNative
local M={};M.__index=M
local scopeLabels={all='전체',team='팀',spectators='관전'}
local Shortcut=require(script.Parent.CornerShortcut)
local VipLock=require(script.Parent.VipLock)
function M.new(parent,notify,focus,project)
    local self=setmetatable({notify=notify,focus=focus,history={},receipts={},scope='all'},M)
    self.button=UI.button(parent,'MatchChat','채팅',function()self.frame.Visible=not self.frame.Visible;self:draw()end);self.button.ZIndex=19
    self.quickButton=Shortcut.new(parent,'QuickMessages','R','chat',function()self:messages()end,'대화')
    self.emojiButton=Shortcut.new(parent,'FavoriteEmojis','Z','emoji',function()if self.openQuick then self.openQuick('emoji')end end,'이모지')
    self.frame=UI.panel(parent,'MatchChatWindow');self.frame.ZIndex=25;self.frame.BackgroundTransparency=.04;self.frame.Visible=false
    self.close=UI.button(self.frame,'Close','×',function()self.frame.Visible=false end)
    self.title=UI.label(self.frame,'Title','전장 채팅',16)
    self.tabs={};for _,scope in ipairs({'all','team','spectators'})do self.tabs[scope]=UI.button(self.frame,scope,scopeLabels[scope],function()self.scope=scope;self:draw()end)end
    self.log=UI.label(self.frame,'Messages','',13,UI.colors.muted);self.log.TextYAlignment=Enum.TextYAlignment.Bottom;self.log:SetAttribute('LocalizationSkip',true)
    self.input=UI.make('TextBox',self.frame,{Name='Input',Text='',PlaceholderText='메시지',ClearTextOnFocus=false,Font=Enum.Font.BuilderSansMedium,TextSize=15,TextColor3=UI.colors.ink,BackgroundColor3=UI.colors.raised,BorderSizePixel=0,MultiLine=false})
    self.sendButton=UI.button(self.frame,'Send','↑',function()self:freeSend()end,true)
    self.input.FocusLost:Connect(function(enter)if enter then self:freeSend()end end)
    self.feed=UI.make('Frame',parent,{Name='SignalFeed',BackgroundTransparency=1,ZIndex=19})
    self.pings=require(script.Parent.SignalPings).new(parent,focus,project)
    self.channels=Chat:WaitForChild('TextChannels')
    require(script.Parent.VoiceLinks).start()
    VipLock.notify=notify;VipLock.badge(self.quickButton,'quickChat');VipLock.badge(self.sendButton,'text')
    local function bind(c)
        if not c:IsA('TextChannel')or not c.Name:match('^Commander_')then return end
        c.MessageReceived:Connect(function(message)self:received(c,message)end)
    end
    for _,c in ipairs(self.channels:GetChildren())do bind(c)end;self.channels.ChildAdded:Connect(bind)
    task.spawn(function()local ev=Pack:WaitForChild('CommsDelivery',30);if ev then ev.OnClientEvent:Connect(function(p)self:delivered(p)end)end end)
    return self
end
function M:messages(id)
    if not VipLock.allows('quickChat')then return VipLock.open('quickChat',false,self.quickButton)end
    if self.openQuick then self.openQuick('messages',id)end
end
function M:channelName(scope)
    return Me:GetAttribute(scope=='team'and 'CommanderTeamChat'or scope=='spectators'and 'CommanderSpectatorChat'or 'CommanderGlobalChat')
end
function M:update(state,factions)
    local old=self.state;self.state=state;self.factions=factions
    if old and (old.version~=state.version or old.roomId~=state.roomId or state.phase=='menu'and old.phase~='menu')then
        self.sendSerial=(self.sendSerial or 0)+1;self.textSerial=(self.textSerial or 0)+1;self.preparing=false;self.sending=false
        self.history={};self.receipts={};self.frame.Visible=false;self.pings:clear();self:drawFeed()
    end
    self.button.Visible=false
    self.quickButton.Visible=state.phase=='playing'and not state.eliminated and state.player and state.player.tiles>0
    self.emojiButton.Visible=self.quickButton.Visible
    if state.multiplayer and (state.phase=='lost'or state.phase=='won')then self.quickButton.Visible=true end
    if state.phase=='lost'or state.eliminated then self.scope='spectators'
    elseif old and old.phase~='playing'and state.phase=='playing'then self.scope=state.player.team and 'team'or 'all'end
    if state.phase=='menu'then self.frame.Visible=false;self.pings:clear()end
    local hq=state.phase=='menu';local typing=hq and VipLock.allows('lobbyText')
    if self.hqChat~=hq or self.hqTyping~=typing then self.hqChat=hq;self.hqTyping=typing;pcall(function()
        local w=Chat.ChatWindowConfiguration;w.HorizontalAlignment=Enum.HorizontalAlignment.Right;w.VerticalAlignment=Enum.VerticalAlignment.Center
        w.Enabled=hq;Chat.ChatInputBarConfiguration.Enabled=typing;game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Chat,hq)
    end)end
    VipLock.hqPill(false)
    local emotes=VipLock.allows('motion');if self.emotes~=emotes then self.emotes=emotes;pcall(function()game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu,emotes)end)end
    if self.frame.Visible then self:draw()end
end
function M:send(kind,payload)
    if not VipLock.allows(kind,type(payload)=='table'and payload.value or nil)then return VipLock.open(kind=='emoji'and 'emoji'or 'quickChat')end
    if self.preparing then return end;self.preparing=true
    self.sendSerial=(self.sendSerial or 0)+1;local serial=self.sendSerial
    local version=self.state and self.state.version;local room=self.state and self.state.roomId
    local function current()return self.sendSerial==serial and self.state and self.state.version==version and self.state.roomId==room and self.state.phase=='playing'end
    task.delay(8,function()if self.preparing and self.sendSerial==serial then self.preparing=false;self.sendSerial+=1;if self.state and self.state.version==version then require(script.Parent.TelemetryStep).step('comms','sendFail',{item=kind,reason='timeout'});self.notify('신호 응답이 늦어요. 다시 시도하세요.',true)end end end)
    task.spawn(function()
        local ok,r=pcall(function()return Pack:WaitForChild('CommsPrepare'):InvokeServer(kind,payload)end)
        if not current()then if self.sendSerial==serial then self.preparing=false end;return end
        self.preparing=false
        if ok and type(r)=='table'and r.vip then VipLock.open(kind=='emoji'and 'emoji'or 'quickChat');return end
        if not ok or type(r)~='table'or not r.ok then require(script.Parent.TelemetryStep).step('comms','sendFail',{item=kind,result=ok and 'rejected'or 'failed',reason=ok and 'none'or 'network'});self.notify(ok and type(r)=='table'and r.message or '소통 연결을 확인해 주세요.',true);return end
        if type(r.ping)=='table'then
            local target;for _,f in pairs(self.factions or {})do if f.matchId==r.ping.subject then target=f;break end end
            self.pings:add(Me.UserId,r.ping,r.ping.tile or target and target.labelTile)
        end
        local echo=type(r.echo)=='table'and r.echo or kind=='emoji'and {from=Me.UserId,kind='emoji',text=payload.value,scope=payload.target==0 and 'all'or 'player'}or nil
        if echo then self:show(echo)end
        if kind~='emoji'and r.message then self.notify(r.message)end
    end)
end
function M:freeSend()
    if not VipLock.allows('text')then return VipLock.open('text')end
    if self.sending or self.input.Text==''then return end
    local c=self.channels:FindFirstChild(self:channelName(self.scope)or '')
    if not c then self.notify('Roblox 채팅을 사용할 수 없어요.',true);return end
    local value=self.input.Text;local version=self.state and self.state.version;local room=self.state and self.state.roomId
    self.textSerial=(self.textSerial or 0)+1;local serial=self.textSerial;self.sending=true;self:draw()
    local function current()return self.textSerial==serial and self.state and self.state.version==version and self.state.roomId==room and self.state.phase~='menu'end
    task.delay(8,function()
        if not current()or not self.sending then return end
        self.textSerial+=1;self.sending=false;self:draw();self.notify('채팅 응답이 늦어요. 다시 시도하세요.',true)
    end)
    task.spawn(function()
        local ok,message=pcall(function()return c:SendAsync(value)end)
        if not current()then return end
        self.sending=false;self:draw()
        local status=ok and message and message.Status
        if status==Enum.TextChatMessageStatus.Success or status==Enum.TextChatMessageStatus.Sending then if self.input.Text==value then self.input.Text=''end
        else require(script.Parent.TelemetryStep).step('comms','sendFail',{item='text',result='failed',reason='failed'});self.notify('Roblox에서 메시지를 전송하지 못했어요.',true)end
    end)
end
function M:received(channel,message)
    if not message.TextSource or not self.state or self.state.phase=='menu'or channel:GetAttribute('CommanderRoom')~=self.state.roomId then return end
    if message.Status~=Enum.TextChatMessageStatus.Success then return end
    local p={from=message.TextSource.UserId,scope=channel:GetAttribute('CommanderScope'),text=message.Translation~=''and message.Translation or message.Text}
    local ok,meta=pcall(Http.JSONDecode,Http,message.Metadata)
    if ok and type(meta)=='table'and meta.v==1 and meta.commander then p.kind=meta.kind;p.key=meta.key;p.subject=meta.subject;p.tile=meta.tile end
    self:show(p)
end
function M:delivered(p)
    if type(p)~='table'or p.v~=1 or type(p.text)~='string'or not self.state or self.state.phase=='menu'or p.room~=self.state.roomId or p.from==Me.UserId then return end
    self:show(p)
end
function M:show(p)
    local sender;for _,f in pairs(self.factions or {})do if f.userId==p.from then sender=f;break end end
    local scope=p.scope;local name=sender and sender.name or tostring(p.from);local content=p.text
    if p.kind=='signal'or p.kind=='target'then content=L.text(content)end
    local entry={scope=scope,name=name,userId=p.from,me=p.from==Me.UserId,text=content}
    table.insert(self.history,entry);if #self.history>40 then table.remove(self.history,1)end
    if p.kind then
        entry.tag=p.kind=='emoji'and '이모지'or p.kind~='signal'and p.key and '빠른 대화'or nil
        if type(p.key)=='string'and phrase[p.key]then content=L.text(phrase[p.key]);entry.text=content end
        local target;for _,f in pairs(self.factions or {})do if f.matchId==p.subject then target=f;break end end
        if p.kind=='emoji'or p.key=='coordinate.ack'or p.key=='coordinate.decline'then
            if p.kind=='emoji'and sender and self.onEmoji then self.onEmoji(sender.id,sender.labelTile,p.text,p.from)end
            if sender and sender.id~=1 and (p.kind~='emoji'or scope=='player')then self.notify(name..'  '..content,false,sender.labelTile)end
        elseif sender and sender.id~=1 then
            self.pings:add(sender.userId,p,p.tile or target and target.labelTile)
            table.insert(self.receipts,1,{text=name..': '..content..(target and ': '..L.nation(target) or ''),tile=p.tile or target and target.labelTile,sender=sender.id,expires=os.clock()+10,key=p.key})
            while #self.receipts>3 do table.remove(self.receipts)end;self:drawFeed()
            require(script.Parent.TelemetryStep).step('comms','coordShown',{item=require(script.Parent.TelemetryStep).code(p.key)})
        end
    end
    if self.onHistory then self.onHistory()end
end
function M:draw()
    local lines={};for _,row in ipairs(self.history)do if row.scope==self.scope or row.scope=='player'or row.scope=='allies'then table.insert(lines,row.name..': '..row.text)end end
    while #lines>4 do table.remove(lines,1)end;self.log.Text=table.concat(lines,'\n')
    for scope,b in pairs(self.tabs)do b.Visible=self:channelName(scope)~=nil;b.BackgroundColor3=scope==self.scope and UI.colors.accent or UI.colors.raised;b.TextColor3=scope==self.scope and UI.colors.bg or UI.colors.ink end
    UI.enabled(self.sendButton,self:channelName(self.scope)~=nil and not self.sending)
    local typing=VipLock.allows('text');self.input.TextEditable=typing;self.input.PlaceholderText=typing and '메시지'or 'VIP 클럽 전용 채팅 입력'
end
function M:drawFeed()
    for _,o in ipairs(self.feed:GetChildren())do if o.Name~='HudScale'then o:Destroy()end end
    for i,r in ipairs(self.receipts)do
        if i>(self.feedLimit or 3)then break end
        local card=UI.panel(self.feed,'Signal'..i);UI.box(card,0,(i-1)*98,self.width or 300,92)
        local b=UI.button(card,'Focus',r.text,function()if r.tile then self.focus(r.tile)end end);b:SetAttribute('LocalizationSkip',true);UI.box(b,4,4,(self.width or 300)-8,40);b.TextSize=12
        local yes=UI.button(card,'Acknowledge','확인',function()r.answered=true;require(script.Parent.TelemetryStep).step('comms','coordAck',{item=require(script.Parent.TelemetryStep).code(r.key)});self:send('quickChat',{target=r.sender,value='coordinate.ack'})end);UI.box(yes,4,44,(self.width or 300)/2-6,44)
        local no=UI.button(card,'Decline','지금은 어려워',function()r.answered=true;require(script.Parent.TelemetryStep).step('comms','coordDecline',{item=require(script.Parent.TelemetryStep).code(r.key)});self:send('quickChat',{target=r.sender,value='coordinate.decline'})end);UI.box(no,(self.width or 300)/2+2,44,(self.width or 300)/2-6,44)
    end
end
function M:step()
    local changed=false;for i=#self.receipts,1,-1 do if self.receipts[i].expires<os.clock()then if not self.receipts[i].answered then require(script.Parent.TelemetryStep).step('comms','coordExpired',{item=require(script.Parent.TelemetryStep).code(self.receipts[i].key)})end;table.remove(self.receipts,i);changed=true end end
    if changed then self:drawFeed()end
    self.pings:step()
end
function M:layout(w,h,obscured,bottomInset,menu,touch,topInset,rightInset,pingsObscured)
    self.width=math.min(320,w-24);local fh=math.min(268,h-16)
    self.button.Visible=false
    Shortcut.place(self.quickButton,w,h,menu,touch,1);Shortcut.place(self.emojiButton,w,h,menu,touch,2)
    UI.box(self.frame,12,8,self.width,fh);UI.box(self.title,12,8,self.width-76,34);UI.box(self.close,self.width-52,4,44,44)
    for i,scope in ipairs({'all','team','spectators'})do UI.box(self.tabs[scope],12+(i-1)*94,52,88,44)end
    UI.box(self.log,12,102,self.width-24,fh-168)
    if self.input.Parent==self.frame then UI.box(self.input,12,fh-56,self.width-72,44);UI.box(self.sendButton,self.width-52,fh-56,44,44)end
    local limit=h<500 and 1 or 3
    if self.feedLimit~=limit then self.feedLimit=limit;self:drawFeed()end
    UI.box(self.feed,12,h<500 and 58 or 120,self.width,math.min(#self.receipts,limit)*98)
    self.feed.Visible=(#self.receipts>0 and not obscured and not self.frame.Visible and self.state and self.state.phase=='playing')==true
    self.pings:layout(w,h,(pingsObscured==nil and obscured or pingsObscured==true)or self.frame.Visible or not(self.state and self.state.phase=='playing'),bottomInset,topInset,rightInset)
end
return M
