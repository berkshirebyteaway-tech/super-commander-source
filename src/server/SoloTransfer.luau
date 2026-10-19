local Rules=if script then require(game.ReplicatedStorage.FrontierNative.Core.SoloTransferRules)else require('../core/SoloTransferRules')
local M={};M.__index=M
local function adapter(config)
    local run=game:GetService('RunService');local teleport=game:GetService('TeleportService')
    local live=not run:IsStudio();local store=live and game:GetService('MemoryStoreService'):GetHashMap('SuperCommanderSoloTransfers_v1')
    return {live=live,time=os.time,clock=os.clock,delay=task.delay,spawn=task.spawn,wait=task.wait,
        privateId=game.PrivateServerId,job=game.JobId,guid=function()return game.HttpService:GenerateGUID(false)end,
        player=function(id)return game.Players:GetPlayerByUserId(id)end,
        reserve=function()return teleport:ReserveServerAsync(config.matchPlaceId)end,
        write=function(key,ticket)store:SetAsync(key,ticket,Rules.ttl)end,
        claim=function(key,fn)return store:UpdateAsync(key,fn,Rules.ttl)end,
        remove=function(key)store:RemoveAsync(key)end,
        send=function(p,code,key)local o=Instance.new('TeleportOptions');o.ReservedServerAccessCode=code;o:SetTeleportData({superCommanderSolo=key});teleport:TeleportAsync(config.matchPlaceId,{p},o)end,
        join=function(p)return p:GetJoinData()end,
        failed=live and teleport.TeleportInitFailed or nil,place=config.matchPlaceId}
end
function M.new(config,callbacks,dependencies)
    local a=dependencies or adapter(config);local self=setmetatable({a=a,callbacks=callbacks,pending={},arriving={},used={}},M)
    if a.failed then a.failed:Connect(function(p,_,_,place,options)
        if place~=a.place then return end
        local ok,data=pcall(function()return options:GetTeleportData()end)
        local key=ok and type(data)=='table'and data.superCommanderSolo
        if key then self:failed(p.UserId,key)end
    end)end
    return self
end
function M:failed(id,key)
    local op=self.pending[id];if not op or op.key~=key then return end
    self.pending[id]=nil;self.callbacks.waiting(id,false)
    self.callbacks.notify(id,'전장으로 이동하지 못했어요. 다시 시도해 주세요.')
    self.a.spawn(function()pcall(self.a.remove,key)end)
end
function M:depart(p,selection,settings)
    local a=self.a;if not a.live then return false,'모든 전장이 사용 중이에요. 잠시 뒤 다시 참가하세요.'end
    if self.pending[p.UserId]then return false,'전장으로 이동 중이에요.'end
    local op={key=a.guid()};self.pending[p.UserId]=op;self.callbacks.waiting(p.UserId,true)
    a.delay(25,function()if self.pending[p.UserId]==op then self:failed(p.UserId,op.key)end end)
    local ok=pcall(function()
        local code,privateId=a.reserve()
        if self.pending[p.UserId]~=op or not a.player(p.UserId)then return end
        local ticket=assert(Rules.new(p.UserId,privateId,selection.map,settings,selection.intro,a.time(),selection.rewardMode,selection.daily and selection.daily.day),'Invalid solo transfer')
        ticket.goal=selection.goal==true or nil
        if self.telemetry then ticket.telemetry=self.telemetry:prepareTransfer(p,op.key)end
        a.write(op.key,ticket)
        if self.pending[p.UserId]~=op or not a.player(p.UserId)then a.remove(op.key);return end
        op.sent=true;a.send(p,code,op.key)
    end)
    if not ok then self:failed(p.UserId,op.key);return false,'경기를 준비하지 못했어요. 다시 참가하세요.'end
    return self.pending[p.UserId]==op,'전장으로 이동 중이에요.'
end
function M:arrival(p)
    local a=self.a;if not a.live or a.privateId==''then return false end
    local ok,join=pcall(a.join,p);local key=ok and type(join)=='table'and type(join.TeleportData)=='table'and join.TeleportData.superCommanderSolo
    if type(key)~='string'or #key>64 or not key:match('^[%x%-]+$')then return false end
    if self.arriving[p.UserId]or self.used[key]then return true end
    local op={};self.arriving[p.UserId]=op;self.callbacks.waiting(p.UserId,true)
    a.delay(30,function()if self.arriving[p.UserId]==op then self.arriving[p.UserId]=nil;self.callbacks.waiting(p.UserId,false);self.callbacks.notify(p.UserId,'경기를 준비하지 못했어요. 다시 참가하세요.')end end)
    a.spawn(function()
        local ticket
        for attempt=1,3 do
            local read,value=pcall(a.claim,key,function(old)return Rules.claim(old,p.UserId,a.privateId,a.job,a.time())end)
            if read then ticket=value;break end
            a.wait(attempt)
        end
        if self.arriving[p.UserId]~=op then return end
        self.arriving[p.UserId]=nil
        if not ticket or ticket.destination~=a.job or not a.player(p.UserId)then
            self.callbacks.waiting(p.UserId,false);self.callbacks.notify(p.UserId,'경기를 준비하지 못했어요. 다시 참가하세요.');return
        end
        self.used[key]=true
        if self.telemetry then self.telemetry:acceptTransfer(p,key,ticket.telemetry)end
        self.callbacks.waiting(p.UserId,false)
        local made,created=pcall(self.callbacks.create,p.UserId,ticket)
        if not made or not created then self.callbacks.notify(p.UserId,'경기를 준비하지 못했어요. 다시 참가하세요.')end
        pcall(a.remove,key)
    end)
    return true
end
function M:leaving(id)
    local op=self.pending[id];self.pending[id]=nil;self.arriving[id]=nil
    if op and not op.sent then self.a.spawn(function()pcall(self.a.remove,op.key)end)end
end
return M
