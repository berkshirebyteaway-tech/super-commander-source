local M={};M.__index=M
function M.new(a)return setmetatable({a=a,nextAt=0},M)end
function M:acquire()
    local deadline=self.a.clock()+5
    repeat
        local now=self.a.clock()
        if now>=self.nextAt and self.a.budget()>=20 then self.nextAt=now+.5;return true end
        self.a.wait(.25)
    until self.a.clock()>=deadline
    return false
end
return M
