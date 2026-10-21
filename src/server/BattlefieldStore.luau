local Core=game.ReplicatedStorage.FrontierNative.Core
local Model=require(Core.BattlefieldModel)
local Copy=require(Core.BattlefieldRules).copy
local M={};M.__index=M
local function official(bucket)return bucket=='official'or bucket:match('^official:[%w%-]+$')~=nil end
local function waiting(s)local n=0;for _,t in pairs(s and s.tickets or {})do if not t.match then n+=1 end end;return n end
local function freshSeed(http)local h=0;for c in http:GenerateGUID(false):gmatch('%x')do h=(h*16+tonumber(c,16))%2147483646 end;return h+1 end
function M.new(hash,index,http,demand)
    return setmetatable({hash=hash,index=index,demand=demand,http=http,cache={},pulsed={},public={},publicAt=-math.huge,gen={}},M)
end
function M:keep(bucket,s)self.cache[bucket]=s;self.gen[bucket]=(self.gen[bucket]or 0)+1 end
function M:read(bucket)
    local gen=self.gen[bucket]
    local s=self.hash:GetAsync(bucket);if self.gen[bucket]==gen then self.cache[bucket]=s end;return s
end
function M:write(bucket,op,now)
    op.seed=op.seed or freshSeed(self.http);op.partition=not official(bucket);op.fieldPrefix=bucket~='official'and official(bucket)and 'official~'..bucket:sub(10)..'~'or nil
    local s=self.hash:UpdateAsync(bucket,function(old)
        if not old and (op.kind=='join'or op.kind=='joinGroup')and bucket~='ranked'then return nil end
        local result=Model.apply(old,now,op)
        assert(#self.http:JSONEncode(result)<30000,'Queue at safe capacity')
        return result
    end,official(bucket)and 300 or 180)
    if not s then
        local rejected=Model.apply(nil,now,{partition=op.partition,fieldPrefix=op.fieldPrefix});rejected.notice='stale';return rejected
    end
    self:keep(bucket,s)
    if bucket:sub(1,5)=='room:'then self:publish(bucket,s,now)elseif official(bucket)then self:publishDemand(bucket,s,now)end
    return s
end
function M:publishDemand(bucket,s,now)
    if not self.demand then return end
    pcall(function()
        local n=waiting(s)
        if n>=72 then self.demand:RemoveAsync(bucket)
        else self.demand:SetAsync(bucket,{bucket=bucket,count=n,updated=now},50,n*10000000000+now)end
    end)
end
function M:choose(now)
    local root=self:read('official');local best=waiting(root)<72 and 'official'or nil;local count=best and waiting(root)or -1
    if self.demand then
        for _,row in ipairs(self.demand:GetRangeAsync(Enum.SortDirection.Descending,20))do local value=row.value
            if value and value.bucket~='official'and now-value.updated<40 and value.count>count then
                local s=self:read(value.bucket);local n=waiting(s)
                if n<72 and n>count then best=value.bucket;count=n;break end
            end
        end
    end
    if best then return best end
    local current=self.hash:GetAsync('official-dispatch')
    if current then local s=self:read(current.bucket);if waiting(s)<72 then return current.bucket end end
    local guid=self.http:GenerateGUID(false);local proposed='official:'..guid
    local picked=self.hash:UpdateAsync('official-dispatch',function(old)
        if old and (not current or old.bucket~=current.bucket)then return nil end
        return {bucket=proposed}
    end,300)or self.hash:GetAsync('official-dispatch')
    assert(picked,'Official capacity allocator unavailable');return picked.bucket
end
function M:publish(bucket,s,now)
    pcall(function()
        local id=bucket:sub(6);local f=s and s.customs[id]
        if not f then self.index:RemoveAsync(id);return end
        self.hash:SetAsync('code:'..f.code,{bucket=bucket},160)
        if f.rules.visibility=='public'then
            local d=Model.directory(s,now,nil).fields[1]
            if d then self.index:SetAsync(id,{field=d,updated=now},50,d.count*10000000000+now)end
        else self.index:RemoveAsync(id)end
    end)
end
function M:pulse(bucket,tokens,host,now,nextMatch)
    local observed=self:read(bucket);local gen=self.gen[bucket]
    local renew=next(tokens)~=nil and now-(self.pulsed[bucket]or -math.huge)>=10
    if observed and not renew and now-(observed.pulseAt or -math.huge)<3 then return observed end
    local result=self.hash:UpdateAsync(bucket,function(old)
        if old and not renew and now-(old.pulseAt or -math.huge)<3 then return nil end
        local s=Model.apply(old,now,{kind='pulse',seed=freshSeed(self.http),tokens=renew and tokens or {},host=host,nextMatch=nextMatch,partition=not official(bucket),fieldPrefix=bucket~='official'and official(bucket)and 'official~'..bucket:sub(10)..'~'or nil})
        s.pulseAt=now;assert(#self.http:JSONEncode(s)<30000,'Queue at safe capacity');return s
    end,official(bucket)and 300 or 180)
    if renew then self.pulsed[bucket]=now end
    if result then self:keep(bucket,result)elseif self.gen[bucket]==gen then self.cache[bucket]=observed end
    if result and bucket:sub(1,5)=='room:'then self:publish(bucket,result,now)end
    if result and official(bucket)then self:publishDemand(bucket,result,now)end
    return self.cache[bucket]
end
function M:commit(id,s)
    if not s or s.committed then return s end
    local origin=self:read(s.origin);local receipt=origin and origin.exports and origin.exports[id]
    if not receipt or receipt.nonce~=s.nonce then
        local now=self:read('match:'..id);return now and now.committed and now.nonce==s.nonce and now or nil
    end
    local result=self.hash:UpdateAsync('match:'..id,function(old)
        if not old or old.nonce~=receipt.nonce then return nil end
        local copy=Copy(old);copy.committed=true;return copy
    end,180)
    self:keep('match:'..id,result)
    if result then
        pcall(function()
            local updated=self.hash:UpdateAsync(result.origin,function(old)
                local e=old and old.exports and old.exports[id]
                if not e or e.nonce~=result.nonce then return nil end
                local copy=Copy(old);copy.exports[id]=nil;return copy
            end,300)
            if updated then self:keep(result.origin,updated)end
        end)
    end
    return result
end
function M:archive(bucket,id,host,now)
    self.archiving=self.archiving or {}
    if self.archiving[id]then return false end
    self.archiving[id]=true
    local ok,result=pcall(self.archiveNow,self,bucket,id,host,now)
    self.archiving[id]=nil
    if not ok then error(result,0)end
    return result
end
function M:archiveNow(bucket,id,host,now)
    local s=self.cache[bucket]or self:read(bucket);local match=s and s.matches[id]
    if not match or match.creator~=host or match.phase~='ready'then return false end
    local ext=Model.external(s,id);ext.origin=bucket;ext.nonce=self.http:GenerateGUID(false);ext.committed=false
    local staged=self.hash:UpdateAsync('match:'..id,function(old)
        if old and old.committed then return nil end
        return ext
    end,180)
    if not staged then return false end
    for uid,token in pairs(match.members)do self.hash:SetAsync('seat:'..uid,{match=id,token=token},160)end
    local detached=self:write(bucket,{kind='detach',match=id,host=host,roster=Copy(match.members),nonce=ext.nonce},now)
    if detached.receipt~=ext.nonce then return false end
    return self:commit(id,staged)~=nil
end
function M:match(id)
    local s=self:read('match:'..id)
    local m=s and s.matches[id]
    if not m or os.time()>=m.expires then self.cache['match:'..id]=nil;return nil end
    if s and not s.committed then s=self:commit(id,s)end
    return s and s.committed and s or nil
end
function M:locate(id,token,fallback)
    if fallback then local s=self.cache[fallback];local t=s and s.tickets[tostring(id)]
        if t and t.token==token and not t.match then return fallback end
    end
    local hint=self.hash:GetAsync('seat:'..id)
    if hint and hint.token==token then
        local s=self:match(hint.match);local t=s and s.tickets[tostring(id)]
        if t and t.token==token then return 'match:'..hint.match end
    end
    return fallback or 'official'
end
function M:code(code)
    local hint=self.hash:GetAsync('code:'..code)
    if not hint then return nil end
    local s=self:read(hint.bucket)
    for _,f in pairs(s and s.customs or {})do if f.code==code then return f end end
end
function M:list(now)
    if now-self.publicAt<6 then return self.public end
    local rows=self.index:GetRangeAsync(Enum.SortDirection.Descending,40);local out={}
    for _,row in ipairs(rows)do local value=row.value
        if value and value.field and now-value.updated<40 then table.insert(out,Copy(value.field))end
    end
    self.public=out;self.publicAt=now;return out
end
function M:view(directoryBucket)
    local out=Copy(self.cache[directoryBucket or 'official']or {schema=2,seed=1729,serial=0,history={},fields={},customs={},tickets={},matches={}})
    for bucket,s in pairs(self.cache)do if bucket~='official'and s and (bucket:sub(1,5)=='room:'or bucket=='ranked'or s.committed)then
        for id,f in pairs(s.customs or {})do out.customs[id]=Copy(f)end
        for uid,t in pairs(s.tickets or {})do out.tickets[uid]=Copy(t)end
        for id,m in pairs(s.matches or {})do out.matches[id]=Copy(m)end
    end end
    for bucket,s in pairs(self.cache)do if official(bucket)and s then
        for uid,t in pairs(s.tickets)do out.tickets[uid]=Copy(t)end
        for id,m in pairs(s.matches)do if not out.matches[id]then out.matches[id]=Copy(m)end end
        if bucket~=(directoryBucket or 'official')then for _,f in ipairs(s.fields)do table.insert(out.fields,Copy(f))end end
    end end
    return out
end
return M
