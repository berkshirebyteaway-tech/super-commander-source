local Rules=if script then require(game.ReplicatedStorage.FrontierNative.Core.ComebackRules)else require('../core/ComebackRules')
local M={};M.__index=M
M.lease,M.retryAfter,M.retries=600,900,2
local function adapter(config)
    local run=game:GetService('RunService');local http=game:GetService('HttpService');local players=game:GetService('Players')
    local ids={box=config.comebackMessageId,streak=config.streakMessageId,sortie=config.sortieMessageId}
    for k,v in pairs(ids)do if type(v)~='string'or v==''then ids[k]=nil end end
    local live=not run:IsStudio()and game.GameId~=0 and next(ids)~=nil
    local key;if live then local ok,k=pcall(function()return http:GetSecret('notifyKey')end);key=ok and k or nil;live=key~=nil end
    local memory=live and game:GetService('MemoryStoreService')
    local map=live and memory:GetSortedMap('SCComeback_v1');local slots=live and memory:GetSortedMap('SCNotifySlot_v1')
    return {live=live,ids=ids,time=os.time,spawn=task.spawn,wait=task.wait,job=game.JobId,random=math.random,
        set=function(id,value,ttl,due)map:SetAsync(id,value,ttl,due)end,
        get=function(id)return map:GetAsync(id)end,
        remove=function(id)map:RemoveAsync(id)end,
        due=function(now,count)return map:GetRangeAsync(Enum.SortDirection.Ascending,count,nil,{sortKey=now+1})end,
        claim=function(id,job,now)return map:UpdateAsync(id,function(old)if type(old)=='table'and (not old.claimed or (tonumber(old.at)or 0)<(now or 0)-M.lease)then old.claimed=job;old.at=now;return old end;return nil end,Rules.ttl)end,
        slot=function(k,ttl)local fresh=false;slots:UpdateAsync(k,function(old)if old~=nil then return nil end;fresh=true;return 1 end,ttl);return fresh end,
        unslot=function(k)slots:RemoveAsync(k)end,
        here=function()local out={};for _,p in ipairs(players:GetPlayers())do out[p.UserId]=true end;return out end,
        name=function(uid)local p=players:GetPlayerByUserId(uid);return p and p.DisplayName end,
        friends=function(uid)
            local out={};local ok,pages=pcall(function()return players:GetFriendsAsync(uid)end);if not ok or not pages then return out end
            while #out<Rules.friendScan do
                for _,f in ipairs(pages:GetCurrentPage())do if type(f.Id)=='number'then table.insert(out,f.Id)end end
                if pages.IsFinished or not pcall(function()pages:AdvanceToNextPageAsync()end)then break end
            end
            return out
        end,
        send=function(userId,kind,params,launch)
            local r=http:RequestAsync({Url=string.format('https://apis.roblox.com/cloud/v2/users/%d/notifications',userId),Method='POST',
                Headers={['Content-Type']='application/json',['x-api-key']=key},
                Body=http:JSONEncode(Rules.body(game.GameId,ids[kind],params,launch,kind))})
            return r.Success,r.StatusCode
        end}
end
function M.new(config,log,dependencies)
    local a=dependencies or adapter(config)
    return setmetatable({a=a,log=log or function()end,running=false},M)
end
function M:has(kind)return self.a.live and self.a.ids[kind]~=nil end
local function dayKey(userId,now)return string.format('d%d:%d',userId,math.floor(now/86400))end
function M:daySlot(userId)
    local now=self.a.time();local ok,fresh=pcall(self.a.slot,dayKey(userId,now),Rules.nextReset(now)-now+60)
    return ok and fresh
end
function M:arrived(userId)if self.a.live then self.a.spawn(function()pcall(self.a.remove,tostring(userId))end)end end
function M:leaving(userId,progress)
    if not self.a.live or Rules.games(progress)<1 then return false end
    local kind=Rules.kind(progress);if not self:has(kind)then kind='box'end
    if not self:has(kind)then return false end
    local due=Rules.due(self.a.time())
    self.a.spawn(function()pcall(self.a.set,tostring(userId),{due=due,kind=kind},Rules.ttl,due)end)
    return true
end
function M:step()
    local ok,rows=pcall(self.a.due,self.a.time(),20);if not ok or type(rows)~='table'then return 0 end
    local sent=0
    for _,row in ipairs(rows)do
        local okClaim,v=pcall(self.a.claim,row.key,self.a.job,self.a.time())
        if okClaim and type(v)=='table'and v.claimed==self.a.job then
            local uid=tonumber(row.key);local kind=self:has(v.kind)and v.kind or 'box';local again=false
            if uid and self:daySlot(uid)then
                local okSend,success,code=pcall(self.a.send,uid,kind,nil,'comeback')
                if okSend and success then sent+=1 end
                self.log(okSend and success and 'sent'or 'failed',okSend and code or nil,kind)
                local passing=not okSend or code==429 or (tonumber(code)or 0)>=500
                if not(okSend and success)and passing and (tonumber(v.tries)or 0)<M.retries then
                    local now=self.a.time();local due=now+M.retryAfter;again=true
                    if self.a.unslot then pcall(self.a.unslot,dayKey(uid,now))end
                    if not pcall(self.a.set,row.key,{due=due,kind=v.kind,tries=(tonumber(v.tries)or 0)+1},Rules.ttl,due)then again=false end
                end
            end
            if not again then pcall(self.a.remove,row.key)end
        end
    end
    return sent
end
function M:sortie(ids)
    if not self:has('sortie')then return end
    self.a.spawn(function()
        local here=self.a.here();for _,uid in ipairs(ids)do here[uid]=true end
        for _,uid in ipairs(ids)do
            local name=self.a.name(uid)
            local okSlot,fresh=pcall(self.a.slot,'s'..uid,Rules.sortieEvery)
            if name and okSlot and fresh then
                local sent=0
                for _,friend in ipairs(Rules.pick(self.a.friends(uid),here,Rules.sortieFriends,self.a.random))do
                    local okGet,queued=pcall(self.a.get,tostring(friend))
                    local theirs=okGet and type(queued)=='table'
                    if okGet and not theirs and self:daySlot(friend)then
                        local okSend,success=pcall(self.a.send,friend,'sortie',{['userId-friend']=uid},'{"src":"notify","kind":"sortie"}')
                        if okSend and success then sent+=1 end
                        self.a.wait(.05)
                    end
                end
                self.log(sent>0 and 'sent'or 'none',sent,'sortie')
            end
        end
    end)
end
function M:start()
    if not self.a.live or self.running then return end;self.running=true
    self.a.spawn(function()while self.running do self.a.wait(60+math.random()*30);self:step()end end)
end
return M
