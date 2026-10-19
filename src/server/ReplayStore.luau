local Flight=if script then require(script.Parent.ReadFlight)else require('./ReadFlight')
local Guards=if script then require(game.ReplicatedStorage.FrontierNative.Core.AbuseGuards)else require('../core/AbuseGuards')
local Delivery=if script then require(script.Parent.ReplayDelivery)else require('./ReplayDelivery')
local M={};M.__index=M
M.limit=3900000
local function adapter()
    local run=game:GetService('RunService');local http=game:GetService('HttpService')
    local live=not run:IsStudio();local store=live and game:GetService('DataStoreService'):GetDataStore('SuperCommanderReplays_v1')
    local memory={}
    local lease=live and game:GetService('MemoryStoreService'):GetHashMap('SCReplayRecovery_v1')
    local worker=game.JobId
    return {spawn=task.spawn,wait=task.wait,clock=os.clock,now=os.time,size=function(v)return #http:JSONEncode(v)end,
        get=function(key)if live then return store:GetAsync(key)end;return memory[key]end,
        set=function(key,value)if live then store:SetAsync(key,value)else memory[key]=value end end,
        update=function(key,fn)if live then store:UpdateAsync(key,fn)else memory[key]=fn(memory[key])end end,
        remove=function(key)if live then store:RemoveAsync(key)else memory[key]=nil end end,
        pendingPages=live and function()return store:ListKeysAsync('pend:',20,'',true)end or nil,
        recoveryReady=live and function()
            local service=game:GetService('DataStoreService')
            return math.min(service:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.StandardRead),
                service:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.StandardWrite))>=20
        end or nil,
        claimRecovery=live and function()
            local now=os.time()
            local claim=lease:UpdateAsync('scan',function(old)
                if old and old.worker~=worker and old.untilAt>now then return nil end
                return {worker=worker,untilAt=now+90}
            end,90)
            return claim and claim.worker==worker
        end or nil,
        bindClose=function(fn)game:BindToClose(fn)end}

end
function M.new(dependencies)
    local self=setmetatable({a=dependencies or adapter(),lists={},listVersions={},listBusy={},pending=0},M)
    self.delivery=Delivery.new(self)
    if self.a.bindClose then self.delivery:start()end
    return self
end
function M:save(id,data,rows)return self.delivery:save(id,data,rows)end
function M:indexed(userId,rows,started)
    local before=self.listVersions[userId]or 0;self.listVersions[userId]=before+1
    if rows and (started==nil or before==started)then self.lists[userId]={at=self.a.clock(),rows=rows}
    elseif self.lists[userId]then self.lists[userId].at=-math.huge;self.lists[userId].retryAt=nil end
end
function M:list(userId)
    local cached=self.lists[userId]
    if self.listBusy[userId]and cached and not cached.failed then return cached.rows end
    self.listFlights=self.listFlights or {}
    local ok,rows=Flight.run(self.listFlights,userId,self.a.readWait,function()
        self.listBusy[userId]=true
        local success,value=pcall(self.readList,self,userId)
        self.listBusy[userId]=nil
        if success then return value end
        local prior=self.lists[userId];return prior and not prior.failed and prior.rows or nil
    end)
    return ok and rows or nil
end
function M:readList(userId)
    for _=1,3 do
        local cached=self.lists[userId]
        if cached and cached.retryAt and self.a.clock()<cached.retryAt then return not cached.failed and cached.rows or nil end
        if cached and self.a.clock()-cached.at<60 then return cached.rows end
        local version=self.listVersions[userId]or 0
        local ok,rows=pcall(self.a.get,'user:'..userId)
        if version~=(self.listVersions[userId]or 0)then continue end
        if not ok then
            local fallback=cached or {at=-math.huge,rows={},failed=true};fallback.retryAt=self.a.clock()+5;self.lists[userId]=fallback
            return not fallback.failed and fallback.rows or nil
        end
        rows=type(rows)=='table'and rows or {}
        self.lists[userId]={at=self.a.clock(),rows=rows}
        return rows
    end
    local cached=self.lists[userId];return cached and cached.rows or nil
end
function M:forgetDeparted(entries)
    if type(entries)~='table'then return end
    for _,cache in ipairs({self.lists,self.listVersions})do for id in pairs(cache)do
        if not entries[id]and not self.listBusy[id]then self.lists[id]=nil;self.listVersions[id]=nil end
    end end
end
function M:load(id)
    if type(id)~='string'or #id==0 or #id>64 or id:find('[^%w%-%._:]')then return nil end
    local clock=self.a.clock or os.clock;self.missing=self.missing or {}
    local miss=self.missing[id];if miss and clock()<miss then return nil end
    local ok,data=pcall(self.a.get,'match:'..id)
    if not ok or data==nil then
        self.missingOrder=self.missingOrder or {};self.missingCursor=(self.missingCursor or 0)%256+1
        local old=self.missingOrder[self.missingCursor]
        if old and self.missing[old.id]==old.untilAt then self.missing[old.id]=nil end
        local untilAt=clock()+(ok and Guards.missingReplaySeconds or 5)
        self.missingOrder[self.missingCursor]={id=id,untilAt=untilAt};self.missing[id]=untilAt
    end
    return ok and data or nil
end
return M
