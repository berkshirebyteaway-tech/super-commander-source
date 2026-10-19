local Chat=if script then game:GetService('TextChatService')else nil
local Http=if script then game:GetService('HttpService')else nil
local Core=if script then game.ReplicatedStorage.FrontierNative.Core else nil
local Routing=if Core then require(Core.CommsRouting)else require('../core/CommsRouting')
local Catalog=if Core then require(Core.CommsCatalog)else require('../core/CommsCatalog')
local Session=if Core then require(Core.MultiplayerSession)else require('../core/MultiplayerSession')
local Comms=if Core then require(Core.CommsSystem)else require('../core/CommsSystem')
local Vip=if Core then require(Core.VipComms)else require('../core/VipComms')
local M={};M.__index=M
local signalText={attack='이 부대를 함께 공격해요.',defend='이곳을 지켜주세요.',troops='병력을 지원해 주세요.',gold='골드를 지원해 주세요.',peace='서로 공격하지 말아요.',thanks='고마워요!'}
local function actual(e,id)return e.room.single and id or Session.viewId(id,e.faction)end
local function command(room,faction,kind,target,value)
    if room.replayLog then room.replayLog:add(room.session.sim.ticks,faction,'comms',{kind,target,value})end
    return room.session.unitSystem.comms:command(faction,kind,target,value)
end
function M.new(entries)
    local folder=Chat:FindFirstChild('TextChannels')or Instance.new('Folder');folder.Name='TextChannels';folder.Parent=Chat
    local self=setmetatable({chat=Chat,http=Http,entries=entries,folder=folder,channels={},pending={},last={},issued={},busy={}},M)
    self.voice=require(script.Parent.VoiceGate).new(entries)
    local function general(c)
        if c.Name=='RBXGeneral'and c:IsA('TextChannel')then c.ShouldDeliverCallback=function(message,to)
            local from=message.TextSource;local e=from and entries[from.UserId]
            return e~=nil and Routing.allowed(e,entries[to.UserId],'lobby')and Vip.allows('text',nil,M.vip(self,e))
        end
        elseif c.Name:match('^RBXWhisper')and c:IsA('TextChannel')then c.ShouldDeliverCallback=function()return false end end
    end
    for _,c in ipairs(folder:GetChildren())do general(c)end;folder.ChildAdded:Connect(general)
    task.spawn(function()
        local commands=Chat:WaitForChild('TextChatCommands',30)
        local function off(c)if c:IsA('TextChatCommand')and (c.Name=='RBXWhisperCommand'or c.Name=='RBXEmoteCommand')then c.Enabled=false end end
        if commands then for _,c in ipairs(commands:GetChildren())do off(c)end;commands.ChildAdded:Connect(off)end
    end)
    return self
end
function M:channel(room,scope,requester,target)
    local suffix=scope=='team'and tostring(target)or requester and (tostring(requester.UserId)..(scope=='player'and ':'..target or ''))or ''
    local key=room.id..':'..scope..':'..suffix
    local found=self.channels[key];if found then return found end
    local c=Instance.new('TextChannel');c.Name='Commander_'..scope..'_'..self.http:GenerateGUID(false):sub(1,8);c.Parent=self.folder
    if requester then c:SetDirectChatRequester(requester)end
    local record={channel=c,room=room,scope=scope,requester=requester,target=target,failed={}};self.channels[key]=record
    c:SetAttribute('CommanderScope',scope);c:SetAttribute('CommanderRoom',room.id)
    c.ShouldDeliverCallback=function(message,to)
        local source=message.TextSource;local a=source and self.entries[source.UserId];local b=self.entries[to.UserId]
        if not a or a.room~=room then return false end
        if scope=='team'and room.session.sim.players[a.faction].team~=target then return false end
        if requester and source.UserId~=requester.UserId then return false end
        local allowed=Routing.allowed(a,b,scope,record.target)
        if not allowed then return false end
        if message.Metadata~=''then
            local ok,meta=pcall(self.http.JSONDecode,self.http,message.Metadata)
            local packet=ok and type(meta)=='table'and self.pending[meta.commander]or nil
            if not packet or packet.owner~=source.UserId or packet.record~=record or packet.expires<os.clock()or packet.metadata~=message.Metadata then return false end
            if message.MessageId~=''then
                if packet.messageId and packet.messageId~=message.MessageId then return false end
                packet.messageId=packet.messageId or message.MessageId
            end
            if not packet.executed then packet.executed=true
                if self.telemetry then self.telemetry:communication(a.player,packet.kind,scope,'accepted',true,meta.commander)end
                task.defer(function()
                if self.entries[packet.owner]==a and a.room==room and Routing.active(a)then
                    if packet.kind=='signal'then
                        if packet.value.key=='attack'and not room.session:friendly(a.faction,packet.target)then command(room,a.faction,'target',packet.target)end
                    else command(room,a.faction,packet.kind,packet.target,packet.value)end
                end
            end)end
        elseif not (Vip.matchText and Vip.allows('text',nil,self:vip(a)))then return false
        elseif self.telemetry and message.MessageId~=''then self.telemetry:communication(a.player,'text',scope,'accepted',true,message.MessageId)end
        return true
    end
    return record
end
function M:vip(e)return Vip.isVip(e.player)end
function M:add(record,e,canSend)
    if (record.failed[e.player.UserId]or 0)>os.clock()then return false end
    local c=record.channel;local existing=c:FindFirstChild(tostring(e.player.UserId))
    if existing and existing:IsA('TextSource')then existing.CanSend=canSend;return true end
    local ok,source=pcall(function()return c:AddUserAsync(e.player.UserId)end)
    if not ok or not source then record.failed[e.player.UserId]=os.clock()+30;return false end
    if e.room~=record.room then source:Destroy();return false end
    source.CanSend=canSend;return true
end
function M:sync(e)
    if self.busy[e.player.UserId]then return end;self.busy[e.player.UserId]=true
    task.spawn(function()
        local ok,err=pcall(function()
            local room=e.room
            local general=self.folder:FindFirstChild('RBXGeneral');local source=general and general:FindFirstChild(tostring(e.player.UserId))
            if source and source:IsA('TextSource')then source.CanSend=Vip.allows('text',nil,self:vip(e))end
            if not room then
                e.player:SetAttribute('CommanderGlobalChat',nil);e.player:SetAttribute('CommanderTeamChat',nil);e.player:SetAttribute('CommanderSpectatorChat',nil)
                for _,r in pairs(self.channels)do local source=r.channel:FindFirstChild(tostring(e.player.UserId));if source then source:Destroy()end end
                return
            end
            room.session.chatManaged=true
            local active=Routing.active(e)
            local global=self:channel(room,active and 'all'or 'spectators')
            local ready=self:add(global,e,true)
            if e.room~=room then return end
            e.player:SetAttribute('CommanderGlobalChat',active and ready and global.channel.Name or nil)
            e.player:SetAttribute('CommanderSpectatorChat',not active and ready and global.channel.Name or nil)
            local p=room.session.sim.players[e.faction]
            if active and p.team then local team=self:channel(room,'team',nil,p.team);local added=self:add(team,e,true)
                if e.room==room then e.player:SetAttribute('CommanderTeamChat',added and team.channel.Name or nil)end
            else e.player:SetAttribute('CommanderTeamChat',nil)end
            for _,r in pairs(self.channels)do local source=r.channel:FindFirstChild(tostring(e.player.UserId))
                if source and (r.room~=room or r.scope=='team'and (not active or r.target~=p.team)or r.scope=='all'and not active or r.scope=='spectators'and active)then source:Destroy()end
            end
        end)
        self.busy[e.player.UserId]=nil
        if not ok then warn('Commander chat setup unavailable: '..tostring(err))end
        if self.voice then local voiced,why=pcall(self.voice.sync,self.voice,e);if not voiced then warn('Commander voice setup unavailable: '..tostring(why))end end
    end)
end
function M:prepare(e,kind,payload)
    self.preparing=self.preparing or {};local id=e.player.UserId
    if self.preparing[id]then return {ok=false,message='잠시 뒤 다시 시도하세요.'}end
    self.preparing[id]=true
    local ok,result=pcall(self.prepareRequest,self,e,kind,payload)
    self.preparing[id]=nil
    if ok then return result end
    return {ok=false,message='Roblox 채팅을 사용할 수 없어요.'}
end
function M:prepareRequest(e,kind,payload)
    if not Routing.active(e)or e.room.session.phase~='playing'or type(payload)~='table'or type(payload.target)~='number'or payload.target%1~=0 then return {ok=false,message='진행 중인 경기에서 소통할 수 있어요.'}end
    local now=os.clock();if now-(self.last[e.player.UserId]or -10)<.35 then return {ok=false,message='잠시 뒤 다시 시도하세요.'}end;self.last[e.player.UserId]=now
    local room=e.room;local s=room.session;local target=actual(e,payload.target);local p=s.sim.players[target]
    local function current()return self.entries[e.player.UserId]==e and e.room==room and Routing.active(e)end
    if target~=0 and (not p or target==e.faction or p.tiles.size==0)then return {ok=false,message='활동 중인 상대를 선택하세요.'}end
    local value=payload.value;local text,scope,subject,tile
    if not Vip.allows(kind,value,self:vip(e))then
        if self.telemetry then pcall(self.telemetry.emit,self.telemetry,e.player,'benefit_used',{benefit='comms',result='rejected',reason='subscription_required',sku='club'})end
        return {ok=false,vip=true,message='VIP 클럽 혜택이에요.'}
    end
    if kind=='emoji'and table.find(Catalog.emojis,value)then text=value;scope=target==0 and 'all'or 'player'
    elseif kind=='target'then text='이 부대를 함께 공격해요.';scope=s.sim.players[e.faction].team and 'team'or 'allies';subject=target
    elseif kind=='quickChat'then
        local key=type(value)=='table'and value.key or value;local entry=Comms.catalog[key]
        text=entry and entry.text or Comms.messages[key];scope='player'
        if entry and entry.requiresTarget then
            if type(value)~='table'or type(value.target)~='number'or value.target%1~=0 then return {ok=false,message='메시지 대상을 선택하세요.'}end
            subject=actual(e,value.target);if not s.sim.players[subject]or s.sim.players[subject].tiles.size==0 then return {ok=false}end
            value={key=key,target=subject}
        end
    elseif kind=='signal'and type(value)=='table'and signalText[value.key]then
        text=signalText[value.key];scope=value.scope;subject=target
        if not table.find({'player','team','allies','all'},scope)then return {ok=false}end
        if type(value.tile)=='number'and value.tile%1==0 and value.tile>=0 and value.tile<s.map.meta.width*s.map.meta.height then tile=value.tile end
    end
    if not text then return {ok=false,message='등록된 신호를 선택하세요.'}end
    if kind=='target'and (target==0 or s:friendly(e.faction,target))then return {ok=false,message='상대를 공동 공격 목표로 선택하세요.'}end
    if e.room.single and (kind=='target'or kind=='emoji'and target==0)then
        local ok,message=command(e.room,e.faction,kind,target,value)
        return {ok=ok,npc=true,message=message}
    end
    if scope=='player'and p and p.kind~='HUMAN'then
        local ok,message=command(e.room,e.faction,kind=='signal'and 'quickChat'or kind,target,kind=='signal'and ({attack='attack',defend='defend',troops='help.troops',gold='help.gold',peace='peace',thanks='thanks'})[value.key]or value)
        return {ok=ok,npc=true,message=message}
    end
    local recipients={}
    for _,other in pairs(self.entries)do if other~=e and Routing.allowed(e,other,scope,target)then table.insert(recipients,other)end end
    if #recipients==0 then
        if kind~='signal'and kind~='target'then return {ok=false,message='이 범위에 소통할 참가자가 없어요.'}end
        local key=e.player.UserId..':'..kind..':'..scope..':'..target
        if now-(self.issued[key]or -60)<(kind=='target'and 15 or 3)then return {ok=false,message='신호 대기시간이 남아 있어요.'}end
        self.issued[key]=now
        local ok,message=true,'신호를 지도에 표시했어요.'
        if kind=='target'or value.key=='attack'and not s:friendly(e.faction,target)then
            local done,why=command(room,e.faction,'target',target)
            if kind=='target'then ok,message=done,why elseif done then message=why end
        end
        if self.telemetry then self.telemetry:communication(e.player,kind,scope,'accepted',ok,nil)end
        return {ok=ok,npc=true,message=message,ping=kind=='signal'and {v=1,kind='signal',key=value.key,scope=scope,subject=subject,tile=tile}or nil}
    end
    local cooldown=kind=='target'and 15 or kind=='emoji'and 5 or 3
    local issueKey=e.player.UserId..':'..kind..':'..scope..':'..target
    if now-(self.issued[issueKey]or -60)<cooldown then return {ok=false,message='신호 대기시간이 남아 있어요.'}end
    local requester=(scope=='player'or scope=='allies')and e.player or nil
    if requester then
        local ids={};for _,r in ipairs(recipients)do table.insert(ids,r.player.UserId)end
        local ok,allowed=pcall(function()return self.chat:CanUsersDirectChatAsync(e.player.UserId,ids)end)
        if not ok or type(allowed)~='table'then return {ok=false,message='Roblox 소통 권한을 확인할 수 없어요.'}end
        local set={};for _,id in ipairs(allowed)do set[id]=true end
        local filtered={};for _,r in ipairs(recipients)do if set[r.player.UserId]then table.insert(filtered,r)end end;recipients=filtered
        if #recipients==0 then return {ok=false,message='Roblox에서 이 참가자와 소통할 수 없어요.'}end
    end
    if not current()then return {ok=false}end
    local record=self:channel(room,scope,requester,scope=='team'and s.sim.players[e.faction].team or target)
    if not self:add(record,e,true)then return {ok=false,message='Roblox 채팅을 사용할 수 없어요.'}end
    if not current()then return {ok=false}end
    local added=0;for _,r in ipairs(recipients)do if self:add(record,r,not requester)then added+=1 end;if not current()then return {ok=false}end end
    if added==0 then return {ok=false,message='Roblox에서 이 참가자와 소통할 수 없어요.'}end
    if not current()then return {ok=false}end
    local token=self.http:GenerateGUID(false):sub(1,18)
    local metadata=self.http:JSONEncode({commander=token,v=1,subject=subject,tile=tile,scope=scope,key=type(value)=='table'and value.key or nil,kind=kind})
    assert(#metadata<=200,'Fixed-message metadata must fit Roblox limit')
    self.pending[token]={owner=e.player.UserId,record=record,target=target,kind=kind,value=value,metadata=metadata,expires=now+10}
    self.issued[issueKey]=now
    return {ok=true,channel=record.channel.Name,text=text,metadata=metadata}
end
function M:clean()
    if self.voice then self.voice:clean()end
    for id in pairs(self.last)do if not self.entries[id]then self.last[id]=nil end end
    for key,issued in pairs(self.issued)do if os.clock()-issued>30 then self.issued[key]=nil end end
    for token,p in pairs(self.pending)do if p.expires<os.clock()then self.pending[token]=nil end end
    for key,r in pairs(self.channels)do
        local retained=false;for _,e in pairs(self.entries)do if e.room==r.room then retained=true;break end end
        if not retained then r.channel:Destroy();self.channels[key]=nil end
    end
end
return M
