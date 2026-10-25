local M={};M.__index=M
M.settle=.2
M.drift=28
M.zoom=.03
function M.new(renderer)return setmetatable({renderer=renderer},M)end
function M:hold(seconds)self.holdUntil=os.clock()+seconds;self.seen=nil end
function M:step(open,tile,revision)
    if not open or not tile then self.seen=nil;return false end
    if self.holdUntil then if os.clock()<self.holdUntil then self.seen=nil;return false end;self.holdUntil=nil end
    local r=self.renderer;local at=r:project(tile,.1,true);local seen=self.seen
    if not seen or seen.tile~=tile or seen.revision~=revision then
        self.seen={tile=tile,revision=revision,at=at,w=r.view.w,t=os.clock()};return false
    end
    if os.clock()-seen.t<M.settle then seen.at=at;seen.w=r.view.w;return false end
    if r.cameraImpulse then return false end
    if math.abs(r.view.w-seen.w)>seen.w*M.zoom or (at-seen.at).Magnitude>M.drift then self.seen=nil;return true end
    return false
end
return M
