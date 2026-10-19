local M={};M.__index=M
function M.new(timeout)return setmetatable({serial=0,timeout=timeout or 12},M)end
function M:begin(now)
    if self.active then return nil end
    self.serial+=1;self.active=self.serial;self.deadline=now+self.timeout;return self.active
end
function M:current(id)return id~=nil and self.active==id end
function M:complete(id)
    if not self:current(id)then return false end
    self.active=nil;self.deadline=nil;return true
end
function M:expire(id,now)
    if not self:current(id)or now<self.deadline then return false end
    return self:complete(id)
end
return M
