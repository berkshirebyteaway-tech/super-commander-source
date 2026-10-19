local U=if script then require(game.ReplicatedStorage.FrontierNative.Core.ClanRules)else require('../core/ClanRules')
local M={};M.__index=M
function M.new(service)return setmetatable({s=service},M)end
function M:read(uid,fresh)
    local s=self.s
    return s:call(function()
        if fresh then return s.store:UpdateAsync('j:'..uid,function(old)return old end)end
        return s.store:GetAsync('j:'..uid)
    end)
end
function M:finish(uid,j)
    local s=self.s;local p=j.pending;if not p then return true,j end
    local indexed=s:call(function()s.store:SetAsync('m:'..uid,p.id)end);if not indexed then return false end
    local ok,u=s:call(function()return s.store:UpdateAsync('u:'..p.id,function(old)
        local key=tostring(uid);local receipt=type(old)=='table'and old.memberOps and old.memberOps[key]
        if receipt and receipt.seq>=j.seq then return old end
        local out,err
        if p.kind=='create'then
            out=old or U.new(p.id,p.name,p.tag,uid,p.code,p.time,p.color)
            if out.disbanded or out.leader~=uid then err='unit-missing'end
        else out,err=U.join(old,uid,p.time)end
        out=out or old or {id=p.id,disbanded=true,count=0,members={}}
        out.memberOps=type(out.memberOps)=='table'and out.memberOps or {}
        out.memberOps[key]={seq=j.seq,reason=err,accepted=err==nil}
        return out
    end)end)
    if not ok or not u then return false end
    local receipt=u.memberOps and u.memberOps[tostring(uid)]
    if not receipt or receipt.seq~=j.seq then return self:read(uid,true)end
    local saved,current=s:call(function()return s.store:UpdateAsync('j:'..uid,function(old)
        if type(old)~='table'or old.seq~=j.seq or not old.pending then return old end
        return {seq=j.seq,clan=receipt.accepted and p.id or false,reason=receipt.reason}
    end)end)
    return saved and current~=nil,current,u
end
function M:current(uid,fresh)
    local ok,j=self:read(uid,fresh);if not ok then return false end
    if type(j)=='table'and j.pending then ok,j=self:finish(uid,j);if not ok then return false end end
    local id=type(j)=='table'and j.clan
    if j==nil then ok,id=self.s:call(function()return self.s.store:GetAsync('m:'..uid)end);if not ok then return false end end
    local u=false
    if type(id)=='string'then
        if fresh then
            local read,value=self.s:call(function()return self.s.store:UpdateAsync('u:'..id,function(old)return old end)end)
            if not read then return false end
            u=type(value)=='table'and not value.disbanded and value or false
        else u=self.s:fetch(id)end
    end
    if type(id)=='string'and u==nil then return false end
    return true,u and u.members[tostring(uid)]and id or nil,u,j
end
function M:begin(uid,p)
    local ready,id,u,j=self:current(uid,true);if not ready then return nil,'storage-unavailable'end
    if id then
        if p.kind=='join'and id==p.id then return u,nil,id end
        return nil,'already-member',id,u
    end
    local seq=type(j)=='table'and j.seq or 0
    local ok,reserved=self.s:call(function()return self.s.store:UpdateAsync('j:'..uid,function(old)
        if (type(old)=='table'and old.seq or 0)~=seq or type(old)=='table'and old.pending then return old end
        return {seq=seq+1,pending=p,clan=type(old)=='table'and old.clan or false}
    end)end)
    if not ok or type(reserved)~='table'then return nil,'storage-unavailable'end
    if reserved.seq~=seq+1 or not reserved.pending or reserved.pending.id~=p.id or reserved.pending.kind~=p.kind then return nil,'busy'end
    local done,current,committed=self:finish(uid,reserved);if not done then return nil,'storage-unavailable'end
    if current.seq~=reserved.seq then return nil,'busy'end
    if current.reason then return nil,current.reason end
    local latest=committed or self.s:fetch(current.clan)
    if latest==nil then return nil,'storage-unavailable'end
    if not latest or not latest.members[tostring(uid)]then return nil,'not-member'end
    return latest,nil,current.clan
end
return M
