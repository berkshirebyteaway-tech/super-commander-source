local M={};M.__index=M
function M.new()return setmetatable({tokens=6,last=nil,request=0,version=nil},M)end
function M:accept(now,id,version)
    if type(id)~='number' or id~=id or id%1~=0 or id<1 or id>9007199254740991 then return false end
    if self.version~=version then self.version=version;self.request=0 end
    if id<=self.request then return false end
    self.request=id
    self.tokens=math.min(6,self.tokens+math.max(0,now-(self.last or now))*10);self.last=now
    if self.tokens<1 then return false end
    self.tokens-=1;return true
end
return M
