local Worker=require(script.Parent.DurableInbox)
local Validate=require(script.Parent.ProgressValidation)
local DailyDelivery=require(script.Parent.DailyScoreDelivery)
local S={};S.__index=S
function S.new(accounts)
    local self=setmetatable({accounts=accounts,memory={},closing=false},S)
    if accounts.localMode then self.store={GetAsync=function(_,k)return self.memory[k]end,UpdateAsync=function(_,k,fn)local v=fn(self.memory[k]);if v then self.memory[k]=v end;return v end}
    else self.store=game:GetService('DataStoreService'):GetDataStore('ToyfrontRewardInbox_alpha1')end
    self.daily=DailyDelivery.new(self.store,accounts.dailyBoard,task.spawn,os.clock,function(id,e,ok)
        local p=game:GetService('Players'):GetPlayerByUserId(id)
        if p then accounts.analytics:flow(p,'goals','dailyBoard',{value=e.score,result=ok and 'ok'or 'failed'})end
    end);self.store=self.daily:wrap()
    self.worker=Worker.new(self.store,function(id,e,unpaid)return self.daily:apply(accounts,id,e,unpaid)end,Validate.reward)
    self.pending=self.worker.pending;self.busy=self.worker.busy
    task.spawn(function()while not self.closing do task.wait(12);self:pulse()end end)
    require(script.Parent.CloseHook)(function()
        self.closing=true;local deadline=os.clock()+24
        repeat self:pulse();task.wait(.25)until not next(self.pending)and not next(self.busy)and not self.daily:hasPending()or os.clock()>=deadline
    end)
    return self
end
function S:pulse()
    self.daily:retry()
    for id in pairs(self.worker.recovery)do task.spawn(function()self:recover(id)end)end
    for id in pairs(self.pending)do self:flush(id)end
end
function S:record(id,event)local ok,err=self.worker:record(id,event);if ok then self:flush(id)else warn('Progress rejected',err)end;return ok end
function S:recover(id)local ok=self.worker:recover(id);if ok then self:flush(id)end;return ok end
function S:flush(id)
    if self.busy[id]or not self.pending[id]then return end
    task.spawn(function()self.worker:drain(id)end)
end
return S
