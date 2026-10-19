local M={};M.__index=M
function M.new()return setmetatable({},M)end
function M:push(message,warning,now,tile,queued)
    if not message or message==''then return false end
    self:step(now);warning=warning==true
    local c=self.current
    if c and c.message==message and c.warning==warning and c.untilTime>now then
        c.untilTime=now+(warning and 4 or 3);c.tile=tile or c.tile;return false
    end
    local nextNotice={message=message,warning=warning==true,untilTime=now+(warning and 4 or 3),created=now,tile=tile}
    if queued and c and c.untilTime>now then
        self.queue=self.queue or {};for _,q in ipairs(self.queue)do if q.message==message then return false end end
        table.insert(self.queue,nextNotice);return false
    end
    if c and c.warning and not warning and c.untilTime>now then self.waiting=nextNotice;return false end
    self.current=nextNotice;self.waiting=nil;return true
end
function M:step(now)
    local queue=self.queue
    if not self.current and not self.waiting and not(queue and queue[1])then return false end
    if self.current and self.current.untilTime>now then return false end
    local nextNotice=self.waiting;self.waiting=nil
    if nextNotice and now-nextNotice.created<8 then nextNotice.untilTime=now+3;self.current=nextNotice
    elseif queue and queue[1]then nextNotice=table.remove(queue,1);nextNotice.untilTime=now+3;self.current=nextNotice
    else self.current=nil end
    return true
end
function M:dismiss(now)
    if not self.current then return false end
    self.current.untilTime=now;return self:step(now)
end
return M
