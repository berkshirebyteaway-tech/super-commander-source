local Fresh=if script then require(script.Parent.FreshStore)else require('./FreshStore')
local M={};M.__index=M
M.batch=64;M.limit=128;M.bucketLimit=16
local function count(t)local n=0;for _ in pairs(t or {})do n+=1 end;return n end
local function hash(s)
    local n=5381;for i=1,#s do n=(n*33+string.byte(s,i))%4294967296 end
    return string.format('%08x',n)
end
local function identity(key,id)return key..'/'..id end
function M.location(key,id)return 'war-receipt:'..hash(identity(key,id))end
local function bucket(raw)
    if raw==nil then return {}end
    assert(type(raw)=='table'and raw.schema==1 and type(raw.items)=='table','unsupported-war-archive')
    return table.clone(raw.items)
end
function M.new(store,field,spawn,permit)return setmetatable({store=store,field=field,spawn=spawn,permit=permit,pending={},busy={},progress={}},M)end
function M:read(key,id)
    local b=bucket(Fresh.read(self.store,M.location(key,id)));return b[identity(key,id)]
end
function M:maintain(key,raw)
    if count(raw and raw[self.field])<M.batch then return end
    self.pending[key]=true;self.spawn(function()self:compact(key)end)
end
function M:compact(key)
    if self.busy[key]then return false end;self.busy[key]=true
    local ok,err=pcall(function()
        local raw=Fresh.read(self.store,key);local saved={};local n=0
        local progress=self.progress[key]or {};self.progress[key]=progress
        for id,value in pairs(raw and raw[self.field]or {})do
            if not progress[id]then
                assert(not self.permit or self.permit(),'war-archive-budget')
                local prior=self:read(key,id)
                if prior==nil then
                    local full=identity(key,id)
                    local receipt=self.store:UpdateAsync(M.location(key,id),function(old)
                        local entries=bucket(old)
                        if entries[full]==nil then assert(count(entries)<M.bucketLimit,'war-archive-bucket-full');entries[full]=value end
                        return {schema=1,items=entries}
                    end)
                    assert(receipt and receipt.items and receipt.items[full]~=nil,'war-archive-unconfirmed')
                end
                progress[id]=true
            end
            saved[id]=true;n+=1;if n>=M.batch then break end
        end
        if n==0 then self.pending[key]=nil;self.progress[key]=nil;return end
        local result=self.store:UpdateAsync(key,function(current)
            if type(current)~='table'then return nil end
            local out=table.clone(current);local list=table.clone(current[self.field]or {});local removed=0
            for id in pairs(saved)do if list[id]~=nil then list[id]=nil;removed+=1 end end
            if removed==0 then return nil end
            out[self.field]=list;out.warArchiveEpoch=(current.warArchiveEpoch or 0)+1
            return out
        end)
        self.progress[key]=nil
        if result and count(result[self.field])<M.batch then self.pending[key]=nil end
    end)
    self.busy[key]=nil;return ok,err
end
function M:retry()for key in pairs(self.pending)do self.spawn(function()self:compact(key)end)end end
function M:apply(key,id,transform)
    for _=1,3 do
        local ok,before=pcall(Fresh.read,self.store,key);if not ok then return false end
        local receipts=type(before)=='table'and before[self.field]or nil
        if receipts and receipts[id]~=nil then self:maintain(key,before);return true,before,receipts[id],false end
        local read,prior=pcall(self.read,self,key,id);if not read then return false end
        if prior~=nil then return true,before,prior,false end
        if count(receipts)>=M.limit then self.pending[key]=true;if not self:compact(key)then return false end;continue end
        local epoch=before and before.warArchiveEpoch or 0;local raced=false;local fresh=false
        local good,result=pcall(function()return self.store:UpdateAsync(key,function(current)
            raced=false;fresh=false
            if (current and current.warArchiveEpoch or 0)~=epoch then raced=true;return nil end
            local list=current and current[self.field]
            if list and list[id]~=nil then return current end
            if count(list)>=M.limit then raced=true;return nil end
            local out,new=transform(current);fresh=new==true;return out
        end)end)
        if not good then return false end
        if raced then continue end
        self:maintain(key,result)
        return true,result,result and result[self.field]and result[self.field][id],fresh
    end
    return false
end
return M
