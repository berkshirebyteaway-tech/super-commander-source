local Worker=if script then require(script.Parent.DurableInbox)else require('./DurableInbox')
local Flight=if script then require(script.Parent.ReadFlight)else require('./ReadFlight')
local M={};M.__index=M
local function valid(e)
    if type(e.matchId)~='string'or e.matchId~=e.id or #e.id>128 or #e.id==0 or type(e.time)~='number'or e.time~=e.time or e.time<0 or e.time==math.huge then return false end
    if type(e.season)~='string'or not e.season:match('^S%d+$')or #e.season>12 then return false end
    if type(e.winnerClan)~='string'or type(e.loserClan)~='string'or #e.winnerClan>32 or #e.loserClan>32 or e.winnerClan==e.loserClan then return false end
    local seen={}
    for _,side in ipairs({'winners','losers'})do
        local list=e[side];if type(list)~='table'or #list<1 or #list>2 then return false end
        for _,id in ipairs(list)do if type(id)~='number'or id%1~=0 or id==math.huge or seen[id]then return false end;seen[id]=true end
    end
    return true
end
function M.new(service)
    local self=setmetatable({s=service,flights={},completed={},order={}},M);local store=service.store
    self.worker=Worker.new({GetAsync=function(_,id)return store:GetAsync('w:'..id)end,
        UpdateAsync=function(_,id,fn)return store:UpdateAsync('w:'..id,fn)end},function(_,e)
        if self.completed[e.id]then return true end
        local ok,done=Flight.run(self.flights,e.id,service.a.readWait,function()return service:applyWarResult(e)end)
        if ok and done then
            if not self.completed[e.id]then
                self.completed[e.id]=true;table.insert(self.order,e.id)
                if #self.order>256 then self.completed[table.remove(self.order,1)]=nil end
            end
            return true
        end
        return false
    end,valid,service.a.time)
    return self
end
function M:record(r)
    local e=table.clone(r);e.id=e.matchId;e.revision=1
    if not valid(e)then return false end
    e.winners=table.clone(e.winners);e.losers=table.clone(e.losers)
    for _,list in ipairs({e.winners,e.losers})do for _,uid in ipairs(list)do self.worker:record(uid,e)end end
    self:flush();return true
end
function M:flush()
    for uid in pairs(self.worker.pending)do self.s.a.spawn(function()self.worker:drain(uid)end)end
end
function M:recover(uid)
    self.s.a.spawn(function()if self.worker:recover(uid)then self.worker:drain(uid)end end)
end
function M:retry()
    for uid in pairs(self.worker.recovery)do self:recover(uid)end
    self:flush()
end
return M
