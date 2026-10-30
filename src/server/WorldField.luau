local Rules=if script then require(game.ReplicatedStorage.FrontierNative.Core.WorldFieldRules)else require('../core/WorldFieldRules')
local M={};M.__index=M
local transferSeconds=90
local function adapter(config)
    local run=game:GetService('RunService');local teleport=game:GetService('TeleportService')
    local live=config.globalPvpEnabled and not run:IsStudio()
    local memory=live and game:GetService('MemoryStoreService')
    local rows=memory and memory:GetSortedMap('SuperCommanderWorldField_v1')
    local locks=memory and memory:GetHashMap('SuperCommanderWorldFieldLock_v1')
    return {live=live,time=os.time,clock=os.clock,spawn=task.spawn,wait=task.wait,delay=task.delay,
        job=game.JobId,privateId=game.PrivateServerId,guid=function()return game.HttpService:GenerateGUID(false)end,
        read=function()local out={};for _,row in ipairs(rows:GetRangeAsync(Enum.SortDirection.Ascending,50))do table.insert(out,row.value)end;return out end,
        get=function(id)return rows:GetAsync(id)end,
        write=function(id,row)rows:SetAsync(id,row,Rules.ttl)end,
        lock=function(fn)return locks:UpdateAsync('reserve',fn,Rules.lockSeconds)end,
        reserve=function()return teleport:ReserveServerAsync(config.matchPlaceId)end,
        send=function(players,code,data)local o=Instance.new('TeleportOptions');o.ReservedServerAccessCode=code;o:SetTeleportData(data);teleport:TeleportAsync(config.matchPlaceId,players,o)end,
        join=function(p)return p:GetJoinData()end,
        failed=live and teleport.TeleportInitFailed or nil,place=config.matchPlaceId}
end
function M.new(config,callbacks,dependencies)
    local a=dependencies or adapter(config)
    local self=setmetatable({a=a,callbacks=callbacks,rows={},readAt=-math.huge,sending={}},M)
    self.live=a.live
    if a.failed then a.failed:Connect(function(p,_,_,place,options)
        if place~=a.place then return end
        local ok,data=pcall(function()return options:GetTeleportData()end)
        local op=self.sending[p.UserId]
        if op and ok and type(data)=='table'and data.hop==op.hop then
            op.failed=true;self.sending[p.UserId]=nil;self:log(p,'teleport',{result='failed',reason='network'});self.callbacks.notify(p.UserId,'이동 실패')
        end
    end)end
    return self
end
function M:log(p,step,data)if self.telemetry then pcall(self.telemetry.flow,self.telemetry,p,'world',step,data)end end
function M:list()
    local now=self.a.time()
    if self.a.live and now-self.readAt>=Rules.cache and not self.reading and now>=(self.retryAt or -math.huge)then
        self.reading=true
        self.a.spawn(function()
            local ok,rows=pcall(self.a.read)
            if ok then self.rows=rows;self.readAt=self.a.time();self.retryAt=nil else self.retryAt=self.a.time()+5 end
            self.reading=false
        end)
    end
    return self.rows
end
function M:view()return Rules.view(self:list(),self.a.time())end
function M:create(want)
    local a=self.a;local token=a.job..':'..a.guid()
    local okLock,held=pcall(a.lock,function(old)return Rules.lock(old,token,a.time())end)
    if not okLock or type(held)~='table'or held.by~=token then return nil,okLock and 'locked'or 'storage_unavailable'end
    local function unlock()pcall(a.lock,function(old)if type(old)=='table'and old.by==token then return {by=token,expires=0}end;return nil end)end
    local read,rows=pcall(a.read)
    if not read then unlock();return nil,'storage_unavailable'end
    self.rows=rows;self.readAt=a.time()
    local existing=Rules.pick(rows,a.time(),want)
    if existing then unlock();return existing,nil,false end
    local ok,code,privateId=pcall(a.reserve)
    if not ok then unlock();return nil,'failed'end
    if a.time()>=held.expires then unlock();return nil,'locked'end
    local row={id=a.guid(),code=code,privateId=privateId,humans=0,seats=Rules.seats,open=true,updated=a.time(),protocol=Rules.protocol}
    local wrote=pcall(a.write,row.id,row);unlock()
    if not wrote then return nil,'storage_unavailable'end
    table.insert(self.rows,row)
    return row,nil,true
end
function M:pending(id)
    local op=self.sending[id];return op~=nil and self.a.time()-op.at<transferSeconds
end
function M:join(players,validate)
    local a=self.a;if not a.live then return false,'local'end
    if #players==0 or validate and not validate()then return false,'전장 준비 실패'end
    local now=a.time()
    for _,p in ipairs(players)do local op=self.sending[p.UserId];if op and now-op.at<transferSeconds then return false,'전장 이동 중'end end
    local op={hop=a.guid(),at=now}
    for _,p in ipairs(players)do self.sending[p.UserId]=op end
    local function current()if a.time()-op.at>=transferSeconds then return false end;for _,p in ipairs(players)do if self.sending[p.UserId]~=op then return false end end;return not validate or validate()end
    local function clear()for _,p in ipairs(players)do if self.sending[p.UserId]==op then self.sending[p.UserId]=nil end end end
    local row,why,made
    for attempt=1,3 do
        local ok,rows=pcall(a.read)
        if not current()then clear();return false,'전장 준비 실패'end
        if ok then self.rows=rows;self.readAt=a.time()end
        row=Rules.pick(self.rows,a.time(),#players)
        if row then break end
        row,why,made=self:create(#players)
        if not current()then clear();return false,'전장 준비 실패'end
        if row or why~='locked'then break end
        a.wait(attempt)
    end
    local lead=players[1]
    if not current()then clear();return false,'전장 준비 실패'end
    if not row then clear();self:log(lead,'join',{result='failed',reason=why or 'missing',count=#players});return false,'전장 준비 실패'end
    local ids={};for _,p in ipairs(players)do table.insert(ids,p.UserId)end
    for _,p in ipairs(players)do if self.telemetry then pcall(self.telemetry.prepareTransfer,self.telemetry,p,'world:'..op.hop)end end
    if not current()then clear();return false,'전장 준비 실패'end
    self:log(lead,'join',{result='accepted',item=made and 'new'or 'running',count=#players,human_count=row.humans or 0})
    op.at=a.time()
    a.delay(transferSeconds,function()
        for _,p in ipairs(players)do if self.sending[p.UserId]==op then
            op.failed=true;self.sending[p.UserId]=nil;self:log(p,'teleport',{result='failed',reason='timeout'});self.callbacks.notify(p.UserId,'이동 실패')
        end end
    end)
    local sent=pcall(a.send,players,row.code,{superCommanderWorld=row.id,users=ids,hop=op.hop})
    if not sent then clear();self:log(lead,'teleport',{result='failed',reason='network'});return false,'이동 실패'end
    if op.failed then return false,'이동 실패'end
    return true
end
function M:leaving(id)self.sending[id]=nil end
function M:arrival(p)
    local a=self.a;if not a.live or a.privateId==''then return nil end
    local ok,join=pcall(a.join,p);local data=ok and type(join)=='table'and type(join.TeleportData)=='table'and join.TeleportData
    local id=data and data.superCommanderWorld
    if not Rules.validId(id)then return nil end
    if self.hostId and self.hostId~=id then return nil end
    if not self.hostId then
        self.hostId=id
        a.spawn(function()
            for attempt=1,3 do
                local got,row=pcall(a.get,id)
                if got then
                    if type(row)=='table'and row.privateId==a.privateId and type(row.code)=='string'then self.code=row.code
                    else self.foreign=true end
                    return
                end
                a.wait(attempt)
            end
        end)
    end
    if self.telemetry and type(data.hop)=='string'and #data.hop<=64 then pcall(self.telemetry.acceptTransfer,self.telemetry,p,'world:'..data.hop)end
    local leader=type(data.users)=='table'and data.users[1]
    return id,Rules.group(data.users,p.UserId),type(leader)=='number'and leader or p.UserId
end
function M:hosting()return self.hostId~=nil and not self.foreign end
function M:publish(rooms,capacity)
    local a=self.a;if not a.live or not self:hosting()or not self.code then return end
    local now=a.time();if now-(self.publishedAt or -math.huge)<Rules.renew then return end
    self.publishedAt=now
    local row=Rules.row(self.hostId,self.code,a.privateId,rooms,now,capacity)
    a.spawn(function()pcall(a.write,row.id,row)end)
end
return M
