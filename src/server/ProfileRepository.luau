local P=if script then require(game.ReplicatedStorage.FrontierNative.Core.ProfileModel) else require("../core/ProfileModel")
local R={};R.__index=R
function R.new(store,waitFn)
    return setmetatable({store=store,wait=waitFn or function() end,loaded={},busy={},observations={}},R)
end
function R:retry(fn)
    for attempt=1,3 do
        local ok,result=pcall(fn)
        if self.observe then pcall(self.observe,ok,attempt)end
        if ok then return true,result end
        if attempt<3 then self.wait(attempt) end
    end
    return false,"storage-unavailable"
end
function R:acquire(key)
    if self.busy[key]and script then local t0=os.clock();while self.busy[key]and os.clock()-t0<10 do task.wait(.05)end end
    if self.busy[key]then return false end
    self.busy[key]=true;return true
end
function R:load(key)
    if not self:acquire(key) then return nil,"busy" end
    local ok,raw=self:retry(function() return self.store:GetAsync(key) end)
    self.observations[key]={known=ok,new=ok and raw==nil,previous=ok and type(raw)=='table'and raw.telemetryVisit or nil}
    local decoded,err
    if ok then decoded,err=P.decode(raw) else err=raw end
    self.loaded[key]=decoded;self.busy[key]=nil
    return decoded,err
end
function R:save(key,patch)
    return self:mutate(key,function(current)return P.patch(current,patch)end)
end
function R:mutate(key,transform)
    if not self.loaded[key] then return nil,"profile-not-loaded" end
    if not self:acquire(key) then return nil,"busy" end
    if not self.loaded[key] then self.busy[key]=nil;return nil,"profile-not-loaded" end
    local rejected
    local ok,raw=self:retry(function()
        return self.store:UpdateAsync(key,function(current)
            local decoded,err=P.decode(current);if not decoded then rejected=err;return nil end
            for k,v in pairs(current or {})do if decoded[k]==nil then decoded[k]=v end end
            local updated,reason=transform(decoded);rejected=reason;return updated
        end)
    end)
    local decoded,err
    if ok and not rejected and raw~=nil then decoded,err=P.decode(raw) else err=rejected or "storage-unavailable" end
    if decoded then self.loaded[key]=decoded end
    self.busy[key]=nil;return decoded,err
end
function R:forget(key,inUse)
    if inUse or self.busy[key]then return false end
    self.loaded[key]=nil;self.observations[key]=nil;return true
end
return R
