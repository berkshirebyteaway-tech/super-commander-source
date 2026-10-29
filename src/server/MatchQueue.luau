local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Teleport=game:GetService('TeleportService')
local Http=game:GetService('HttpService')
local Core=game.ReplicatedStorage.FrontierNative.Core
local Lobby=require(Core.LobbyModel)
local Model=require(Core.BattlefieldModel)
local Config=require(script.Parent.MultiplayerConfig)
local Storage=require(script.Parent.BattlefieldStore)
local M={};M.__index=M
M.arrivalSeconds=75
function M.new()
    local localQueue=Lobby.new()
    local self=setmetatable({localQueue=localQueue,membership=localQueue.membership,active={},locations={},reserving={},arrivals={},attempts={},sending={},retryAt={},deferredCancels={},cancelling={},joining={},live=Config.globalPvpEnabled and not Run:IsStudio()},M)
    if self.live then
        local memory=game:GetService('MemoryStoreService')
        local suffix='_v'..Config.queueProtocol
        self.storage=Storage.new(memory:GetHashMap('SuperCommanderBattlefields'..suffix),memory:GetSortedMap('SuperCommanderCustomDiscovery'..suffix),Http,memory:GetSortedMap('SuperCommanderOfficialDemand'..suffix))
        Teleport.TeleportInitFailed:Connect(function(p,_,_,place)
            if place==Config.matchPlaceId and self.sending[p.UserId]then self.sending[p.UserId]=nil;self.retryAt[p.UserId]=os.clock()+3
                if self.callbacks and self.callbacks.failed then pcall(self.callbacks.failed,p)end
            end
        end)
    end
    if not self.live then self.state=Model.apply(nil,os.clock(),{kind='pulse',host='studio'})end
    self.friends={}
    local function fetch(p)task.spawn(function()self:friendsOf(p.UserId)end)end
    Players.PlayerAdded:Connect(fetch);for _,p in ipairs(Players:GetPlayers())do fetch(p)end
    Players.PlayerRemoving:Connect(function(p)self.friends[p.UserId]=nil end)
    return self
end
function M:friendsOf(id)
    local cached=self.friends[id];if cached then return cached end
    local list={};self.friends[id]=list
    if id<=0 then return list end
    pcall(function()
        local pages=Players:GetFriendsAsync(id)
        while #list<200 do
            for _,f in ipairs(pages:GetCurrentPage())do table.insert(list,f.Id)end
            if pages.IsFinished then break end;pages:AdvanceToNextPageAsync()
        end
    end)
    return list
end
function M:refreshView()
    self.state=self.storage:view(self.directoryBucket)
    for id,token in pairs(self.active)do local s=self.storage.cache[self.locations[id]or 'official'];local t=s and s.tickets[tostring(id)]
        if t and t.token==token then self.state.tickets[tostring(id)]=t end
    end
end
function M:bucket(op)
    if op.bucket then return op.kind=='cancel'and self.storage:locate(op.userId,op.token,op.bucket)or op.bucket end
    if op.kind=='customCreate'then return 'room:'..op.customId end
    if op.kind=='join'then return 'room:'..op.field end
    if op.kind=='joinGroup'then
        if op.field and op.field:sub(1,7)=='ranked-'then return 'ranked'end
        if op.field and op.field:sub(1,7)=='custom-'then return 'room:'..op.field end
        local cohort=op.field and op.field:match('^official~([%w%-]+)~');return cohort and 'official:'..cohort or 'official'
    end
    if op.match then
        if op.kind=='ready'or op.kind=='abort'then for bucket,s in pairs(self.storage.cache)do if bucket:sub(1,6)~='match:'and s and s.matches[op.match]then return bucket end end end
        self.storage:match(op.match);return 'match:'..op.match
    end
    if op.userId then return self.storage:locate(op.userId,op.token,self.locations[op.userId])end
    return 'official'
end
function M:update(op)
    local observedAt=os.clock()
    while self.updating do task.wait(.05)end;self.updating=true
    op.host=self.live and game.JobId or 'studio';op.nextMatch=Http:GenerateGUID(false)
    local now=self.live and os.time()or os.clock()
    local ok,s=pcall(function()
        if not self.live then return Model.apply(self.state,now,op)end
        local bucket=self:bucket(op)
        if op.kind=='claim'or op.kind=='start'then
            local ext=self.storage.cache[bucket];if not ext or not ext.committed then error('Match handoff not committed')end
        end
        local written=self.storage:write(bucket,op,now)
        if bucket:sub(1,5)=='room:'then
            local roomId=bucket:sub(6);local latest
            for _,field in ipairs(Model.directory(written,now,nil).fields)do if field.id==roomId then latest=field;break end end
            for i=#self.storage.public,1,-1 do if self.storage.public[i].id==roomId then
                if latest then self.storage.public[i]=latest else table.remove(self.storage.public,i)end
            end end
        end
        if op.kind=='ready'then self.storage:archive(bucket,op.match,op.host,now)end
        self:refreshView()
        self.state.notice=written.notice
        if op.kind=='join'or op.kind=='customCreate'or op.kind=='joinGroup'then
            for uid,t in pairs(written.tickets)do if t.token==op.token or op.tokens and t.token==op.tokens[uid]then self.state.tickets[uid]=t end end
        end
        return self.state
    end)
    self.updating=false
    if self.telemetry then self.telemetry:service(nil,'queue_update',ok,observedAt)end
    if ok then self.state=s;self.lastGood=os.clock();self.failures=0 else self.failures=math.min(5,(self.failures or 0)+1);warn('TOYFRONT queue temporarily unavailable',s)end
    return ok,s
end
function M:directory(id)
    local now=self.live and os.time()or os.clock()
    local d=Model.directory(self.live and self.storage.cache[self.directoryBucket or 'official']or self.state,now,id)
    if self.live then
        local seen={};for _,f in ipairs(d.fields)do seen[f.id]=true end
        local bucket=self.locations[id];local own=bucket and self.storage.cache[bucket]
        for _,f in ipairs(own and Model.directory(own,now,id).fields or {})do if (f.kind=='custom'or (self.membership[id]or {}).field==f.id)and not seen[f.id]then table.insert(d.fields,f);seen[f.id]=true end end
        for _,f in ipairs(self.storage.public)do if not seen[f.id]then table.insert(d.fields,f);seen[f.id]=true end end
    end
    d.global=self.live;d.unavailable=self.live and (not self.lastGood or os.clock()-self.lastGood>12)or nil
    return d
end
function M:joinValid(op)
    if op.cancelled then return false end
    for id,p in pairs(op.players)do if Players:GetPlayerByUserId(id)~=p then return false end end
    return not op.guard or op.guard()
end
function M:deferCancel(id,token,bucket)
    self.deferredCancels[token]=self.deferredCancels[token]or {userId=id,token=token,bucket=bucket,expires=os.clock()+300,retryAt=0}
    return self.deferredCancels[token]
end
function M:retire(id,token,bucket)
    local retired=self:deferCancel(id,token,bucket)
    local removed=self:update({kind='cancel',userId=id,token=token,bucket=bucket})
    if removed and self.deferredCancels[token]==retired then self.deferredCancels[token]=nil end
end
function M:deferJoin(op)
    for id,token in pairs(op.tokens or {})do self:deferCancel(tonumber(id),token,op.destination)end
end
function M:rollbackJoin(op)
    self:deferJoin(op)
    for id,token in pairs(op.tokens or {})do local uid=tonumber(id)
        if self.active[uid]==token then self.active[uid]=nil;self.locations[uid]=nil;self.membership[uid]=nil;self.attempts[uid]=nil;self.retryAt[uid]=nil end
        self:retire(uid,token,op.destination)
    end
end
function M:withJoin(ids,fn)
    if type(ids)~='table'or #ids<1 or #ids>5 then return false,'파티원 확인'end
    ids=table.clone(ids)
    local op={players={}}
    for _,id in ipairs(ids)do
        if self.joining[id]or self.cancelling[id]then return false,'다시 시도'end
        local p=Players:GetPlayerByUserId(id);if not p then return false,'파티원 나감'end
        op.players[id]=p
    end
    if self.callbacks and self.callbacks.joinGuard then
        op.guard=self.callbacks.joinGuard(ids)
        if not op.guard then return false,'파티 상태 바뀜'end
    end
    for id in pairs(op.players)do self.joining[id]=op end
    local result=table.pack(pcall(fn,op))
    if not result[1]and op.tokens then pcall(self.rollbackJoin,self,op)end
    for id in pairs(op.players)do if self.joining[id]==op then self.joining[id]=nil end end
    if not result[1]then error(result[2],0)end
    return table.unpack(result,2,result.n)
end
local function logged(self,ids,area,step,item,ok,msg,...)
    if self.telemetry then pcall(function()
        local reason=not ok and require(Core.TelemetrySchema).reason(msg)or nil
        for _,uid in ipairs(ids)do self.telemetry:flowUser(uid,area,step,{item=item,result=ok and 'accepted'or 'rejected',reason=reason,party_size=#ids})end
    end)end
    return ok,msg,...
end
local function fieldKind(ticket)local f=type(ticket)=='table'and type(ticket.field)=='string'and ticket.field or '';return f:sub(1,7)=='custom-'and 'custom'or f:sub(1,7)=='ranked-'and (f:sub(8)=='clanwar'and 'clanwar'or 'ranked')or 'official'end
function M:joinField(ids,ticket,now,invited)
    return logged(self,ids,'queue','joinResult',fieldKind(ticket),self:withJoin(ids,function(op)return self:joinFieldNow(table.clone(ids),ticket,now,invited,op)end))
end
function M:joinFieldNow(ids,ticket,now,invited,request)
    if #ids<1 or #ids>5 or type(ticket)~='table'or type(ticket.field)~='string'or #ticket.field>128 or type(ticket.revision)~='number'then return false,'참가 정보 확인'end
    if not self:joinValid(request)then return false,'파티 상태 바뀜'end
    local custom=ticket.field:sub(1,7)=='custom-'
    local ranked=ticket.field:sub(1,7)=='ranked-'and ticket.field:sub(8)or nil
    local tokens,names,levels,clans,friends={},{},{},{},{}
    for _,id in ipairs(ids)do
        local current=self.active[id]and self:status(id,now)
        if self.sending[id]or current and current.phase=='transferring'then return false,'전장 이동 중'end
        local p=Players:GetPlayerByUserId(id);if not p then return false,'파티원 나감'end
        tokens[tostring(id)]=Http:GenerateGUID(false);names[tostring(id)]=p.DisplayName;levels[tostring(id)]=p:GetAttribute('CommanderLevel')
        clans[tostring(id)]=p:GetAttribute('CommanderClan');friends[tostring(id)]=self.friends[id]
    end
    local groupId=#ids>1 and Http:GenerateGUID(false)or nil
    local op={kind='joinGroup',users=ids,tokens=tokens,names=names,levels=levels,clans=clans,friends=friends,group=groupId,leader=ids[1],field=ticket.field,revision=ticket.revision,invited=invited==true,ratings=ranked and ticket.ratings or nil,clan=ranked=='clanwar'and ticket.clan or nil}
    local destination=self.live and self:bucket(op)or (custom and 'room:'..ticket.field or ranked and 'ranked'or 'official')
    local retired={};for _,id in ipairs(ids)do if self.live and self.active[id]and self.locations[id]~=destination then retired[id]={token=self.active[id],bucket=self.locations[id]}end end
    request.tokens=tokens;request.destination=destination
    local ok,s=self:update(op)
    local accepted=ok
    if ok then for _,id in ipairs(ids)do local t=s.tickets[tostring(id)];if not t or t.token~=tokens[tostring(id)]then accepted=false;break end end end
    if not accepted then
        if not ok then self:deferJoin(request)else request.tokens=nil end
        if not self:joinValid(request)then return false,'파티 상태 바뀜'end
        local solo=#ids==1
        local messages={gap='랭크 점수 차이 큼',stale='전장 규칙 바뀜',
            full=custom and (solo and '방 가득'or '파티 자리 부족')or solo and '자리 가득'or '파티 자리 부족',
            teamfull=solo and '팀 자리 가득'or '파티 자리 부족',locked='출격 준비 중',private='초대 코드 필요',capacity='모집 가득',party='파티원 확인'}
        if ok and messages[s.notice]then return false,messages[s.notice],s.notice end
        local waiting=false;for _,id in ipairs(ids)do if self.active[id]then waiting=true end end
        return false,waiting and '매칭 연결 확인 중'or '매칭 연결 실패'
    end
    if not self:joinValid(request)then self:rollbackJoin(request);return false,'파티 상태 바뀜'end
    local t=s.tickets[tostring(ids[1])]
    local field=t.match and s.matches[t.match]or custom and s.customs[t.field]or ranked and {rules=require(game.ReplicatedStorage.FrontierNative.Core.RankedRules).rules(ranked=='clanwar'and '2v2'or ranked,0)}or (function()for _,f in ipairs(s.fields)do if f.id==t.field then return f end end end)()
    if not field then self:rollbackJoin(request);return false,'매칭 연결 확인 중'end
    local membership={users=table.clone(ids),leader=ids[1],group=groupId,mode=custom and 'custom'or ranked and 'ranked'or 'pvp',ladder=ranked,field=t.field,joined=now,rules=field.rules}
    for _,id in ipairs(ids)do
        if self.membership[id]and not self.active[id]then self.localQueue:cancel(id,now)end
        self.active[id]=tokens[tostring(id)];self.membership[id]=membership;self.attempts[id]=nil;self.retryAt[id]=nil
        self.locations[id]=destination
    end
    for id,old in pairs(retired)do self:retire(id,old.token,old.bucket)end
    if not self:joinValid(request)then self:rollbackJoin(request);return false,'파티 상태 바뀜'end
    return true
end
function M:createCustom(id,rules,now,ids)
    local ok,msg=self:withJoin(ids or {id},function(op)return self:createCustomNow(id,rules,now,table.clone(ids or {id}),op)end)
    local r=type(rules)=='table'and rules or {}
    if self.telemetry then pcall(function()self.telemetry:flowUser(id,'custom','create',{item=type(r.mode)=='string'and r.mode or nil,map_key=r.map,value=tonumber(r.maximum),active=r.visibility=='public',result=ok and 'accepted'or 'rejected',reason=not ok and require(Core.TelemetrySchema).reason(msg)or nil,party_size=#(ids or {id})})end)end
    return ok,msg
end
function M:createCustomNow(id,rules,now,ids,request)
    ids=ids or {id};if #ids<1 or #ids>5 or ids[1]~=id then return false,'파티 확인'end
    local tokens,names={},{};for _,uid in ipairs(ids)do
        if self.active[uid]then return false,'대기 취소 먼저'end
        local p=Players:GetPlayerByUserId(uid);if not p then return false,'파티원 나감'end
        tokens[tostring(uid)]=Http:GenerateGUID(false);names[tostring(uid)]=p.DisplayName
    end
    local guid=Http:GenerateGUID(false);local token=tokens[tostring(id)];local group=#ids>1 and Http:GenerateGUID(false)or nil
    request.tokens=tokens;request.destination='room:custom-'..guid
    local ok,s=self:update({kind='customCreate',userId=id,token=token,users=ids,tokens=tokens,names=names,group=group,customId='custom-'..guid,code=guid:sub(1,8):upper(),rules=rules,name=names[tostring(id)]})
    local t=ok and s.tickets[tostring(id)]
    if not t or t.token~=token then if not ok then self:deferJoin(request)else request.tokens=nil end;return false,not ok and '매칭 연결 확인 중'or s.notice=='rules'and '설정 확인'or s.notice=='locked'and '출격 준비 중'or '모집 가득'end
    if not self:joinValid(request)then self:rollbackJoin(request);return false,'파티 상태 바뀜'end
    local room=s.customs[t.field];if not room then self:rollbackJoin(request);return false,'매칭 연결 확인 중'end
    local membership={users=table.clone(ids),leader=id,group=group,mode='custom',field=t.field,joined=now,rules=room.rules}
    for _,uid in ipairs(ids)do
        if self.membership[uid]and not self.active[uid]then self.localQueue:cancel(uid,now)end
        self.active[uid]=tokens[tostring(uid)];self.locations[uid]='room:'..t.field;self.membership[uid]=membership
    end
    return true
end
function M:customCommand(id,kind,value)
    return logged(self,{id},'custom','command',kind,self:customCommandNow(id,kind,value))
end
function M:customCommandNow(id,kind,value)
    if not self.active[id]or self.sending[id]or type(value)~='table'then return false,'방 확인'end
    local ok,s=self:update({kind=kind,userId=id,token=self.active[id],revision=value.revision,rules=value.rules,team=value.team})
    local messages={stale='규칙 바뀜',regroup='참가자 바뀜',host='방장만 가능',rules='설정 확인',ready='모두 준비 필요',automatic='팀 자동 배정',team='팀 확인',teamfull='팀 가득',opponent='상대 팀 필요'}
    if not ok then return false,'매칭 연결 확인 중'end
    return s.notice==nil,messages[s.notice]
end
function M:fieldReady(id,ready)
    if not self.active[id]or self.sending[id]then return false,'대기 전장 없음'end
    local ok,s=self:update({kind='fieldReady',userId=id,token=self.active[id],ready=ready})
    if not ok then return false,'매칭 연결 확인 중'end
    if s.notice=='alone'then return false,'2명부터 레디'end
    if s.notice then return false,'전장 바뀜'end
    if self.telemetry then pcall(function()local t=s.tickets[tostring(id)];self.telemetry:flowUser(id,'queue','ready',{result=ready and 'accepted'or 'cancelled',value=t and t.joined and math.max(0,math.floor(os.time()-t.joined))or nil})end)end
    return true
end
function M:joinCode(id,code,now,ids)
    return logged(self,ids or {id},'custom','joinCode','code',self:withJoin(ids or {id},function(op)return self:joinCodeNow(id,code,now,table.clone(ids or {id}),op)end))
end
function M:joinCodeNow(id,code,now,ids,request)
    if type(code)~='string'or #code>12 then return false,'코드 확인'end
    code=code:gsub('%s',''):upper()
    if self.live then local ok,f=pcall(function()return self.storage:code(code)end)
        if not ok then return false,'매칭 연결 확인 중'end
        if f then return self:joinFieldNow(ids,{field=f.id,revision=f.revision},now,true,request)end
        return false,'방 없음'
    end
    self:update({kind='pulse',tokens=self:activeTokens()})
    for _,f in pairs(self.state and self.state.customs or {})do if f.code==code then return self:joinFieldNow(ids,{field=f.id,revision=f.revision},now,true,request)end end
    return false,'방 없음'
end
function M:activeTokens()local tokens={};for id,token in pairs(self.active)do tokens[tostring(id)]=token end;return tokens end
function M:join(ids,mode,now)
    if mode~='pvp'then return self:withJoin(ids,function()return self.localQueue:join(ids,mode,now)end)end
    local d=self:directory();local f=d.fields[1]
    if not f then return false,'전장 목록 확인 중'end
    return self:joinField(ids,{field=f.id,revision=f.revision},now)
end
function M:cancel(id,now,leaving)
    local pending=self.joining[id];if pending then pending.cancelled=true end
    if not self.active[id]then return self.localQueue:cancel(id,now)end
    if self.sending[id]then
        if leaving then self.active[id]=nil;self.locations[id]=nil;self.membership[id]=nil;self.sending[id]=nil;return true end
        return false,'전장 이동 중'
    end
    local group=self.membership[id];local ids=group and group.users or {id}
    for _,uid in ipairs(ids)do if self.sending[uid]then return false,'전장 이동 중'end end
    local cancellation={};local tokens={}
    for _,uid in ipairs(ids)do self.cancelling[uid]=cancellation;tokens[uid]=self.active[uid]end
    local token=self.active[id];local ok=self:update({kind='cancel',userId=id,token=token})
    for _,uid in ipairs(ids)do if self.cancelling[uid]==cancellation then self.cancelling[uid]=nil end end
    for _,uid in ipairs(ids)do
        if self.active[uid]==tokens[uid]then
            if not ok and tokens[uid]then self:deferCancel(uid,tokens[uid],self.locations[uid])end
            self.active[uid]=nil;self.locations[uid]=nil;self.membership[uid]=nil;self.attempts[uid]=nil;self.retryAt[uid]=nil
        end
    end
    return true,not ok and not leaving and '참가 취소됨'or nil
end
function M:status(id,now)
    if not self.active[id]then return self.localQueue:status(id,now)end
    local status=Model.status(self.state,id,self.active[id],self.live and os.time()or now)
    if not status then local last=self.membership[id]or {};return {mode='pvp',field=last.field,rules=last.rules,count=1,max=last.rules and last.rules.maximum or 10,minimum=1,phase='recovering',global=true}end
    if os.clock()-(self.lastGood or 0)>12 then status.phase='recovering';status.remaining=nil end
    status.global=self.live
    status.locked=self.sending[id]~=nil
    for _,uid in ipairs((self.membership[id]or {}).users or {})do if self.sending[uid]then status.locked=true;break end end
    return status
end
function M:take(mode,now)
    if mode~='pvp'then return self.localQueue:take(mode,now)end
    if self.live then return nil end
    self:update({kind='pulse',tokens=self:activeTokens()})
    for mid,m in pairs(self.state.matches)do if m.phase=='reserving'then
        local users={};for uid in pairs(m.members)do table.insert(users,tonumber(uid))end
        local selection=Model.selection(m,users)
        for _,id in ipairs(users)do self.state.tickets[tostring(id)]=nil;self.active[id]=nil;self.membership[id]=nil end
        self.state.matches[mid]=nil;return selection
    end end
end
function M:vote(id,map)return self.localQueue:vote(id,map)end
function M:notify(id,message)if self.callbacks then self.callbacks.notify(id,message)end end
function M:reserve(id,m)
    if self.reserving[id]then return end;self.reserving[id]=true
    local ok,code,privateId=pcall(function()return Teleport:ReserveServerAsync(Config.matchPlaceId)end)
    if ok then self:update({kind='ready',match=id,code=code,privateId=privateId})else self:update({kind='abort',match=id})end
    self.reserving[id]=nil
    local s=ok and self.state;local ready=s and s.matches[id]
    if ready and ready.phase=='ready'then
        for uid,token in pairs(self.active)do local t=s.tickets[tostring(uid)]
            if t and t.token==token and t.match==id then pcall(function()self:transfer(uid,ready,t)end)end
        end
    end
end
function M:hurry()
    if next(self.arrivals)or next(self.reserving)or next(self.sending)then return true end
    local s=self.state;if not s or not self.live then return false end
    local now=os.time()
    for uid,token in pairs(self.active)do
        local ok,st=pcall(Model.status,s,uid,token,now)
        if ok and st and(st.phase=='transferring'or st.remaining and st.remaining<=2)then return true end
    end
    return false
end
function M:transfer(id,m,ticket)
    local p=Players:GetPlayerByUserId(id);if not p or self.updating or self.sending[id]or self.cancelling[id]or os.clock()<(self.retryAt[id]or 0)then return end
    if self.live then local s=self.storage.cache['match:'..ticket.match];if not s or not s.committed then return end end
    local ids,players={},{}
    for _,uid in ipairs((self.membership[id]or {}).users or {id})do local member=Players:GetPlayerByUserId(uid)
        local t=self.state and self.state.tickets[tostring(uid)]
        if member and self.active[uid]and t and t.token==self.active[uid]and t.match==ticket.match then
            if self.sending[uid]or self.cancelling[uid]or os.clock()<(self.retryAt[uid]or 0)then return end
            table.insert(ids,uid);table.insert(players,member)
        end
    end
    if #players==0 then return end
    for _,uid in ipairs(ids)do if (self.attempts[uid]or 0)>=3 then
        self:cancel(uid,os.clock());for _,other in ipairs(ids)do if self.telemetry then self.telemetry:flowUser(other,'queue','transferGiveUp',{result='cancelled',reason='network',count=3})end;self:notify(other,'이동 실패, 모집 취소')end;return
    end end
    for _,uid in ipairs(ids)do self.sending[uid]=os.clock();self.attempts[uid]=(self.attempts[uid]or 0)+1 end
    local attempt=self.attempts[ids[1]]or 1
    if attempt>1 then for _,uid in ipairs(ids)do if self.telemetry then self.telemetry:flowUser(uid,'queue','transferRetry',{result='retry',value=attempt})end;self:notify(uid,string.format('전장 이동을 다시 시도해요 (%d/3)',attempt))end end
    local options=Instance.new('TeleportOptions');options.ReservedServerAccessCode=m.code
    options:SetTeleportData({toyfrontMatch=ticket.match,queueProtocol=Config.queueProtocol})
    if self.telemetry then for _,member in ipairs(players)do self.telemetry:prepareTransfer(member,ticket.match)end end
    if self.callbacks and self.callbacks.departing and (self.attempts[ids[1]]or 0)<=1 then pcall(self.callbacks.departing,ids)end
    if self.telemetry and (self.attempts[ids[1]]or 0)<=1 then local n=0;for _ in pairs(m.members or {})do n+=1 end;for _,uid in ipairs(ids)do self.telemetry:flowUser(uid,'queue','depart',{result='accepted',count=n,value=n})end end
    local ok=pcall(function()Teleport:TeleportAsync(Config.matchPlaceId,players,options)end)
    if self.telemetry and not ok then for _,member in ipairs(players)do self.telemetry:emit(member,'transfer_result',{stage='sending',result='failed',reason='network'})end end
    if not ok then for _,uid in ipairs(ids)do self.sending[uid]=nil;self.retryAt[uid]=os.clock()+3 end end
end
function M:arrival(p)
    if not self.live or game.PrivateServerId==''then return end
    local ok,join=pcall(function()return p:GetJoinData()end)
    local data=ok and type(join)=='table'and type(join.TeleportData)=='table'and join.TeleportData
    local hint=data and data.toyfrontMatch
    if type(hint)~='string'or #hint==0 or #hint>64 then return end
    if data.queueProtocol~=Config.queueProtocol then if self.telemetry then self.telemetry:flow(p,'queue','arrival',{result='rejected',reason='stale'})end;self:notify(p.UserId,'업데이트됨, 새 전장으로');return end
    self.callbacks.arrival(p.UserId,true)
    task.spawn(function()
        local success,s
        for attempt=1,3 do success,s=self:update({kind='claim',match=hint,privateId=game.PrivateServerId});if success then break end;task.wait(attempt*2)end
        local m=success and s.matches[hint]
        if m and m.phase=='running'and m.destination==game.JobId and m.members[tostring(p.UserId)]then self.callbacks.arrival(p.UserId,false);return end
        if not m or m.destination~=game.JobId or not m.members[tostring(p.UserId)]or m.phase~='ready'then
            self.callbacks.arrival(p.UserId,false);if self.telemetry then self.telemetry:flow(p,'queue','arrival',{result='rejected',reason=success and 'missing'or 'storage_unavailable'})end
            self:notify(p.UserId,'모집 끝남');return
        end
        self.arrivals[hint]=self.arrivals[hint]or {since=os.clock(),users={}}
        if self.telemetry then self.telemetry:acceptTransfer(p,hint)end
        self.arrivals[hint].users[p.UserId]=true
        if self.callbacks.claimed then pcall(self.callbacks.claimed,p.UserId,m.rules,m,hint)end
    end)
end
function M:poll()
    local gone={};for id in pairs(self.active)do if not self.sending[id]and not Players:GetPlayerByUserId(id)then table.insert(gone,id)end end
    for _,id in ipairs(gone)do if self.active[id]then self:cancel(id,os.clock(),true)end end
    local id,retired;local cleanupNow=os.clock()
    for key,item in pairs(self.deferredCancels)do
        if cleanupNow>=item.expires then self.deferredCancels[key]=nil
        elseif not retired or item.retryAt<retired.retryAt then id,retired=key,item end
    end
    if retired then
        retired.retryAt=cleanupNow
        local removed=self:update({kind='cancel',userId=retired.userId,token=retired.token,bucket=retired.bucket})
        if removed and self.deferredCancels[id]==retired then self.deferredCancels[id]=nil end
    end
    local ok,s
    if self.live then
        local now=os.time();ok=pcall(function()
            local buckets={};local hasLobby=(game.PrivateServerId==''or next(self.arrivals)==nil)and (not self.callbacks or not self.callbacks.hasLobby or self.callbacks.hasLobby())
            if hasLobby then local chose,picked=pcall(self.storage.choose,self.storage,now);if chose then self.directoryBucket=picked else warn('TOYFRONT directory',picked)end
                if self.directoryBucket then buckets[self.directoryBucket]={}end end
            for id,token in pairs(self.active)do local bucket=self.locations[id]or 'official';buckets[bucket]=buckets[bucket]or {};buckets[bucket][tostring(id)]=token end
            for bucket,tokens in pairs(buckets)do
                local pulsed,err=pcall(function()if bucket:sub(1,6)=='match:'then self.storage:match(bucket:sub(7))
                else self.storage:pulse(bucket,tokens,game.JobId,now,Http:GenerateGUID(false))end end)
                if not pulsed then warn('TOYFRONT pulse',bucket,err)end
            end
            for bucket,state in pairs(self.storage.cache)do for mid,m in pairs(state and state.matches or {})do
                if bucket:sub(1,6)~='match:'and m.creator==game.JobId and m.phase=='ready'then self.storage:archive(bucket,mid,game.JobId,now)end
            end end
            for id,token in pairs(self.active)do local found,where=pcall(self.storage.locate,self.storage,id,token,self.locations[id]);if found then self.locations[id]=where end end
            for mid in pairs(self.arrivals)do self.storage:match(mid)end
            if hasLobby then self.storage:list(now)end
            local keep={official=true,[self.directoryBucket or 'official']=true}
            for _,bucket in pairs(self.locations)do keep[bucket]=true end
            for mid in pairs(self.arrivals)do keep['match:'..mid]=true end
            for _,op in pairs(self.joining)do if op.destination then keep[op.destination]=true end end
            for _,old in pairs(self.deferredCancels)do if old.bucket then keep[old.bucket]=true end end
            for bucket,state in pairs(self.storage.cache)do if not keep[bucket]then
                local pending=false;for _,m in pairs(state and state.matches or {})do if m.creator==game.JobId and m.phase~='running'and now<m.expires and bucket:sub(1,6)~='match:'then pending=true;break end end
                if not pending then self.storage.cache[bucket]=nil;self.storage.pulsed[bucket]=nil end
            end end
            self:refreshView();s=self.state
        end)
        if ok then self.lastGood=os.clock();self.failures=0 else self.failures=math.min(5,(self.failures or 0)+1)end
    else ok,s=self:update({kind='pulse',tokens=self:activeTokens()})end
    if not ok then
        for mid,a in pairs(self.arrivals)do if os.clock()-a.since>=60 then
            self.arrivals[mid]=nil
            for id in pairs(a.users)do self.callbacks.arrival(id,false);self:notify(id,'출발 취소, 불이익 없음')end
        end end
        return
    end
    if not self.live then return end
    for mid,m in pairs(s.matches)do if m.creator==game.JobId and m.phase=='reserving'then task.spawn(function()self:reserve(mid,m)end)end end
    s=self.state
    for id,token in pairs(self.active)do
        local t=s.tickets[tostring(id)];local m=t and t.match and s.matches[t.match]
        if not t or t.token~=token then
            local found,bucket=pcall(self.storage.locate,self.storage,id,token,nil)
            local c=found and self.storage.cache[bucket];local again=c and c.tickets[tostring(id)]
            if again and again.token==token then
                self.locations[id]=bucket;s.tickets[tostring(id)]=again;t=again
                for mid,other in pairs(c.matches or {})do if not s.matches[mid]then s.matches[mid]=other end end
                m=t.match and s.matches[t.match]
            end
        end
        if not t or t.token~=token then
            self.active[id]=nil;self.locations[id]=nil;self.membership[id]=nil;if self.telemetry then self.telemetry:flowUser(id,'queue','seatLost',{result='expired'})end;self:notify(id,'모집 연결 끊김')
        elseif m and m.phase=='ready'then self:transfer(id,m,t)
        end
        if self.sending[id]and os.clock()-self.sending[id]>20 then self.sending[id]=nil;self.retryAt[id]=os.clock()+3 end
    end
    for mid,a in pairs(self.arrivals)do
        local m=s.matches[mid]
        if not m or m.phase~='ready'then for id in pairs(a.users)do self.callbacks.arrival(id,false);self:notify(id,'모집 끝남')end;self.arrivals[mid]=nil;continue end
        local users={};local expected=0
        for id in pairs(m.members)do expected+=1;if Players:GetPlayerByUserId(tonumber(id))then table.insert(users,tonumber(id))end end
        table.sort(users)
        local late=os.clock()-a.since>=M.arrivalSeconds or os.time()>=m.expires-10
        if #users>=(m.kind=='custom'and m.rules.minimum or 1)and (#users==expected or late)then
            local started,result=self:update({kind='start',match=mid,users=users})
            if started and result.matches[mid]and result.matches[mid].phase=='running'then
                users={};for id in pairs(result.matches[mid].members)do table.insert(users,tonumber(id))end;table.sort(users)
                for id in pairs(a.users)do self.callbacks.arrival(id,false)end
                local selection=Model.selection(result.matches[mid],users);selection.globalMatch=mid
                selection.liveCode=result.matches[mid].code
                local created=self.callbacks.create(selection)
                if self.telemetry then for _,id in ipairs(users)do self.telemetry:flowUser(id,'queue','matchStart',{result=created and 'accepted'or 'failed',count=#users,value=os.clock()-a.since})end end
                if self.telemetry and #users<expected then for _,id in ipairs(users)do self.telemetry:flowUser(id,'queue','matchShort',{result='rejected',reason='missing',count=#users,value=expected-#users})end end
                if not created then self:update({kind='abort',match=mid});for _,id in ipairs(users)do self:notify(id,'전장 준비 실패')end end
                self.arrivals[mid]=nil
            elseif late then
                self:update({kind='abort',match=mid});self.arrivals[mid]=nil
                for id in pairs(a.users)do self.callbacks.arrival(id,false);if self.telemetry then self.telemetry:flowUser(id,'queue','matchAbort',{result='timeout',reason='capacity',count=#users})end;self:notify(id,m.rules.ranked=='ffa'and '인원 부족, 출격 취소'or '인원 부족, 출격 취소')end
            end
        elseif late then
            self:update({kind='abort',match=mid});self.arrivals[mid]=nil
            for id in pairs(a.users)do self.callbacks.arrival(id,false)end
            for _,id in ipairs(users)do if self.telemetry then self.telemetry:flowUser(id,'queue','matchAbort',{result='timeout',reason='disconnected',count=#users})end;self:notify(id,'출발 취소, 불이익 없음')end
        end
    end
end
function M:start(callbacks)
    self.callbacks=callbacks
    task.spawn(function()while true do
        if #Players:GetPlayers()>0 and (not self.live or next(self.active)or next(self.arrivals)or next(self.deferredCancels)or not callbacks.hasLobby or callbacks.hasLobby())then
            local ok,err=pcall(function()self:poll()end);if not ok then warn('TOYFRONT match coordinator',err)end
        end
        local rest=math.min((next(self.active)or next(self.arrivals))and 10 or 20,3*2^(self.failures or 0))
        if (self.failures or 0)==0 and self:hurry()then rest=1 end
        task.wait(rest)
    end end)
end
return M
