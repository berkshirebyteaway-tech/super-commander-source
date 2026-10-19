local M={};M.__index=M
local family={complete='construction',upgrade='construction',build='construction',allied='diplomacy',request='diplomacy',allianceEnded='diplomacy',attack='dispatch',launch='dispatch',capture='capture',conquest='capture',milestone='reward',rankUp='reward',grow='reward'}
function M.new()return setmetatable({last={},focusUntil=0},M)end
function M:admit(kind,priority,now)
    if priority>=4 then self.focusUntil=math.max(self.focusUntil,now+(priority>=5 and 2.5 or .9));return true end
    if priority<=2 and now<self.focusUntil then return false end
    local group=family[kind]or kind;local gap=group=='construction'and .35 or group=='capture'and .65 or .16
    if now-(self.last[group]or -1e9)<gap then return false end
    self.last[group]=now;return true
end
function M.stale(now,at,priority)return priority<=2 and now-at>.3 end
function M:reset()table.clear(self.last);self.focusUntil=0 end
return M
