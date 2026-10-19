local Flight=if script then require(script.Parent.ReadFlight)else require('./ReadFlight')
local Run=if script then game:GetService("RunService")else nil
local Players=if script then game:GetService("Players")else nil
local Rules=if script then require(game.ReplicatedStorage.FrontierNative.Core.RatingRules)else require('../core/RatingRules')
local Config=if script then require(script.Parent.MultiplayerConfig)else require('./MultiplayerConfig')
local Worker=if script then require(script.Parent.DurableInbox)else require('./DurableInbox')
local Validate=if script then require(script.Parent.ProgressValidation)else require('./ProgressValidation')
local S={};S.__index=S
function S.new()
    local self=setmetatable({profiles={},memory={},pending={},busy={},boardPending={},names={},localMode=Run:IsStudio()or game.GameId==0},S)
    if not self.localMode then self.store=game:GetService("DataStoreService"):GetDataStore(Config.profileStore);self.board=game:GetService("DataStoreService"):GetOrderedDataStore(Config.winsStore);self.inboxStore=game:GetService('DataStoreService'):GetDataStore('ToyfrontCareerInbox_v1')
    else
        self.store={GetAsync=function(_,k)return self.memory[tonumber(k)]end,UpdateAsync=function(_,k,fn)local v=fn(self.memory[tonumber(k)]);if v then self.memory[tonumber(k)]=v end;return v end}
        local inbox={};self.inboxStore={GetAsync=function(_,k)return inbox[k]end,UpdateAsync=function(_,k,fn)local v=fn(inbox[k]);if v then inbox[k]=v end;return v end}
    end
    self.worker=Worker.new(self.inboxStore,function(id,e)return self:applyResult(id,e)end,Validate.career)
    self.pending=self.worker.pending;self.busy=self.worker.busy;self.boardBusy={}
    task.spawn(function()
        while not self.closing do
            task.wait(12)
            for id in pairs(self.worker.recovery)do task.spawn(function()if self.worker:recover(id)then self:flush(id)end end)end
            for id in pairs(self.pending)do self:flush(id)end
            if self.onBoardTick then self.onBoardTick()end
            for id in pairs(self.boardPending)do self:flushBoard(id)end
        end
    end)
    game:BindToClose(function()
        self.closing=true;local untilTime=os.clock()+25
        repeat
            for id in pairs(self.pending)do self:flush(id)end
            if self.onBoardTick then self.onBoardTick()end
            for id in pairs(self.boardPending)do task.spawn(function()self:flushBoard(id)end)end
            task.wait(.5)
            local pending=next(self.pending)~=nil
            if not pending and not next(self.busy)and not next(self.boardPending)and not(self.onBoardPending and self.onBoardPending())then break end
        until os.clock()>=untilTime
    end)
    return self
end
function S:load(id)
    self.worker.recovery[id]=true
    for attempt=1,3 do
        local ok,p=pcall(function()if self.localMode then return self.memory[id]else return self.store:GetAsync(tostring(id))end end)
        if ok then
            if p and p.schema~=1 then return false end
            self.profiles[id]=self.profiles[id]or p or Rules.new()
            self.boardPending[id]=(self.profiles[id].wins or 0)>0 and self.profiles[id].wins or nil
            if not self.board then self.boardPending[id]=nil end
            self.worker:recover(id);self:flush(id)
            if self.onLoaded then task.spawn(self.onLoaded,id,self.profiles[id])end
            return true
        end
        task.wait(attempt)
    end
    return false
end
function S:flushBoard(id)
    local wins=self.boardPending[id];if not self.board or wins==nil or self.boardBusy[id]then return end;self.boardBusy[id]=true
    local ok=pcall(function()self.board:UpdateAsync(tostring(id),function(old)return math.max(old or 0,wins)end)end)
    self.boardBusy[id]=nil
    if ok and self.boardPending[id]==wins then self.boardPending[id]=nil end
end
function S:record(id,result)
    result=table.clone(result);result.revision=1
    local ok,err=self.worker:record(id,result);if ok then self:flush(id)else warn('Career result rejected',err)end
end
function S:flush(id)
    if self.busy[id]or not self.pending[id]then return end
    task.spawn(function()self.worker:drain(id)end)
end
function S:applyResult(id,result)
    local rejected
    local saved=self.store:UpdateAsync(tostring(id),function(old)
        local p,reason=Rules.apply(old,result);rejected=not p and reason or nil;return p
    end)
    if not saved then return rejected=='expired-result'and {expired=true}or nil,rejected end
    local before=self.profiles[id];self.profiles[id]=saved
    if self.board then self.boardPending[id]=saved.wins;self:flushBoard(id)end
    if result.ladder and self.onRanked then task.spawn(self.onRanked,id,saved,result,before)end
    return saved
end
function S:snapshot(id)
    local p=self.profiles[id];if not p then return {available=false,localMode=self.localMode}end
    return {available=true,rating=p.rating,tier=Rules.tier(p),games=p.games,wins=p.wins,streak=p.streak,bestStreak=p.bestStreak,xp=p.xp,localMode=self.localMode,pending=self.pending[id]~=nil or self.worker.recovery[id]==true}
end
function S:forgetDeparted(entries)
    for id in pairs(self.worker.recovery)do if not Players:GetPlayerByUserId(id)and not(entries and entries[id]and entries[id].room)then self.worker:stopRecovering(id)end end
    for id in pairs(self.profiles)do
        if not Players:GetPlayerByUserId(id)and not (entries and entries[id]and entries[id].room)and not self.busy[id]and not self.pending[id]and self.boardPending[id]==nil then
            self.profiles[id]=nil;self.pending[id]=nil
            self.worker:stopRecovering(id)
        end
    end
end
function S:leaders(waitForResult)
    if self.leaderCache and os.clock()-(self.leaderFetched or 0)<30 then return self.leaderCache end
    if os.clock()<(self.leaderRetryAt or -math.huge)then return self.leaderCache end
    if self.leaderReading and (not waitForResult or self.leaderCache)then return self.leaderCache end
    self.leaderFlights=self.leaderFlights or {}
    local ok,rows=Flight.run(self.leaderFlights,'leaders',self.readWait,function()
        self.leaderReading=true;local success,value=pcall(self.readLeaders,self);self.leaderReading=nil
        if success and value then return value end
        self.leaderRetryAt=os.clock()+5;return self.leaderCache
    end)
    return ok and rows or self.leaderCache
end
function S:readLeaders()
    local out={}
    if self.localMode then
        for id,p in pairs(self.profiles)do table.insert(out,{userId=id,wins=p.wins})end
        table.sort(out,function(a,b)return a.wins>b.wins end)
    else
        local ok,rows=pcall(function()return self.board:GetSortedAsync(false,25):GetCurrentPage()end)
        if not ok then return nil end
        for _,r in ipairs(rows)do table.insert(out,{userId=tonumber(r.key),wins=r.value})end
    end
    for i,row in ipairs(out)do
        if i>8 then break end
        local p=Players:GetPlayerByUserId(row.userId)
        if p then row.name=p.DisplayName else
            if not self.names[row.userId]then local ok,name=pcall(function()return Players:GetNameFromUserIdAsync(row.userId)end);if ok then self.names[row.userId]=name end end
            row.name=self.names[row.userId]or "지휘관"
        end
    end
    local names={};for i,row in ipairs(out)do if i<=8 and self.names[row.userId]then names[row.userId]=self.names[row.userId]end end;self.names=names
    self.leaderFetched=os.clock();self.leaderCache=out;return out
end
return S
