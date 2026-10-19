local Daily=if script then require(game.ReplicatedStorage.FrontierNative.Core.DailyOperation)else require('../core/DailyOperation')
local M={};M.__index=M
local function projection(e)
    if type(e)~='table'or type(e.daily)~='number'or e.daily%1~=0 or e.daily<0 or e.daily>1e6
        or type(e.map)~='string'or #e.map>64 then return nil end
    local score=Daily.score(e)
    if type(score)~='number'or score~=score or score<0 or score>=math.huge then return nil end
    return {day=e.daily,map=e.map,score=math.floor(score)}
end
local function scope(e)return tostring(e.day)..':'..e.map end
local function copy(t)local out={};for k,v in pairs(t or {})do out[k]=v end;return out end
function M.new(store,board,spawn,clock,observe)
    return setmetatable({store=store,board=board,spawn=spawn,clock=clock or os.clock,observe=observe,pending={},delivered={},busy={},lastWrite={},retryAt={}},M)
end
function M:queue(id,scores)
    for k,e in pairs(scores or {})do
        if self.delivered[id]and (self.delivered[id][k]or -1)>=e.score then continue end
        local list=self.pending[id]or {};self.pending[id]=list
        if not list[k]or list[k].score<e.score then list[k]=table.clone(e)end
    end
    if self.pending[id]then self.spawn(function()self:drain(id)end)end
end
function M:clearKnown(id,scores)
    local list=copy(scores);local known=self.delivered[id]
    for k,score in pairs(known or {})do if list[k]and list[k].score<=score then list[k]=nil end end
    return next(list)and list or nil
end
function M:confirmed(id,scores)
    local known=self.delivered[id]
    for k,score in pairs(known or {})do if not scores or not scores[k]or scores[k].score>score then known[k]=nil end end
    if known and not next(known)then self.delivered[id]=nil end
end
function M:wrap()
    local owner=self;local store=self.store
    return {
        GetAsync=function(_,key)
            local raw=store:GetAsync(key);local id=tonumber(key)or key
            if raw and raw.dailyScores then owner.lastWrite[id]=owner.clock();owner:queue(id,raw.dailyScores)end;return raw
        end,
        UpdateAsync=function(_,key,fn)
            local id=tonumber(key)or key
            local saved=store:UpdateAsync(key,function(old)
                local out=fn(old);if not out then return nil end
                local scores=owner:clearKnown(id,old and old.dailyScores)or {}
                for eventId,prior in pairs(old and old.items or {})do
                    local after=out.items and out.items[eventId]
                    if not prior.paid and after and after.paid and after.event.revision==prior.event.revision then
                        local e=projection(prior.event)
                        if e then local k=scope(e);if not scores[k]or scores[k].score<e.score then scores[k]=e end end
                    end
                end
                local n=0;for _ in pairs(scores)do n+=1 end;assert(n<=128,'daily-projection-capacity')
                out.dailyScores=next(scores)and scores or nil;return out
            end)
            if saved then
                owner:confirmed(id,saved.dailyScores);owner:queue(id,saved.dailyScores)
                owner.lastWrite[id]=(saved.dailyScores or owner.delivered[id]or owner.pending[id])and owner.clock()or nil
            end
            return saved
        end,
    }
end
function M:apply(accounts,id,e,unpaid)
    local p=accounts.repo and accounts.repo.loaded[tostring(id)]
    local receipt=p and p.outgame and p.outgame.receipts[e.id]
    if projection(e)and receipt and receipt.sealed and (receipt.revision or 0)>=e.revision
        and (not e.basicsComplete or p.outgame.basicsComplete)then return p end
    return accounts:applyProgress(id,e,unpaid)
end
function M:drain(id)
    if self.busy[id]or not self.pending[id]or self.clock()<(self.retryAt[id]or 0)then return end;self.busy[id]=true
    for k,e in pairs(copy(self.pending[id]))do
        local ok,result=pcall(self.board.submit,self.board,id,e.day,e.score,e.map)
        if self.observe then pcall(self.observe,id,e,ok and result==true)end
        if ok and result then
            local known=self.delivered[id]or {};self.delivered[id]=known;known[k]=math.max(known[k]or 0,e.score)
            if self.pending[id][k]==e then self.pending[id][k]=nil end
        end
    end
    if not next(self.pending[id])then self.pending[id]=nil end
    self.retryAt[id]=self.pending[id]and self.clock()+12 or nil;self.busy[id]=nil
end
function M:ack(id)
    if not self.delivered[id]or self.busy[id]or self.clock()-(self.lastWrite[id]or 0)<12 then return end
    self.busy[id]=true;self.lastWrite[id]=self.clock()
    local ok,saved=pcall(function()return self.store:UpdateAsync(tostring(id),function(raw)
        if type(raw)~='table'then return nil end
        local out=table.clone(raw);out.dailyScores=self:clearKnown(id,raw.dailyScores);return out
    end)end)
    if ok and saved then self:confirmed(id,saved.dailyScores);self.lastWrite[id]=self.clock()end
    self.busy[id]=nil
    if self.pending[id]then self.spawn(function()self:drain(id)end)elseif not self.delivered[id]then self.lastWrite[id]=nil end
end
function M:retry()
    for id in pairs(self.pending)do self.spawn(function()self:drain(id)end)end
    for id in pairs(self.delivered)do self.spawn(function()self:ack(id)end)end
end
function M:hasPending()return next(self.pending)~=nil or next(self.delivered)~=nil or next(self.busy)~=nil end
return M
