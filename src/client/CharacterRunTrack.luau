local M={};M.__index=M
local function load(animator,clip)
    local track=animator:LoadAnimation(clip)
    track.Priority=Enum.AnimationPriority.Movement;track.Looped=true
    return track
end
function M.new(dependencies)return setmetatable({load=dependencies and dependencies.load or load,attempts=0},M)end
function M:clear()
    local track=self.track
    self.track=nil;self.character=nil;self.loading=nil;self.retryAt=nil;self.attempts=0
    if track then track:Stop(0);track:Destroy()end
end
function M:get(character,humanoid,now)
    if self.character~=character then self:clear();self.character=character end
    if not character or self.track or self.loading or self.attempts>=3 or now<(self.retryAt or 0)then return self.track end
    self.retryAt=now+.5
    local animate=character:FindFirstChild('Animate')
    local run=animate and animate:FindFirstChild('run')
    local clip=run and run:FindFirstChildWhichIsA('Animation')
    local animator=humanoid and humanoid:FindFirstChildOfClass('Animator')
    if not clip or not animator then return nil end
    local token={};self.loading=token;self.attempts+=1
    local ok,track=pcall(self.load,animator,clip)
    if self.loading~=token or self.character~=character then
        if ok and track then track:Destroy()end
        return self.track
    end
    self.loading=nil
    if ok and track then self.track=track;return track end
    self.retryAt=now+2^self.attempts
    return nil
end
return M
