local M={};M.__index=M
M.steps={Joined=1,LobbyReady=2,MatchStarted=3,Settled=4,FirstCapture=5,Result=6,NextMatch=7}
function M.new(id)return setmetatable({id=id,seen={},matches=0,lastStep=0},M)end
function M:mark(name)
    local step=M.steps[name];if not step or self.seen[name]then return nil end
    self.seen[name]=true
    if step<=self.lastStep then return nil end
    self.lastStep=step;return {step=step,name=name,sessionId=self.id}
end
function M:match()
    self.matches+=1
    return self:mark(self.matches==1 and 'MatchStarted'or 'NextMatch')
end
function M.fields(build,map,mode)
    return {CustomField01=tostring(build),CustomField02=tostring(map or 'lobby'),CustomField03=tostring(mode or 'lobby')}
end
return M
