local M={}
M.readInterval=1
M.readQueue=2
M.roomBurst=4
M.roomWindow=30
M.joinFailures=5
M.joinWindow=60
M.missingReplaySeconds=30
M.unitViewSeconds=30
M.readBurst=3
M.readRate=2
M.inviteCooldown=10

function M.take(state,key,now,burst,rate)
    local bucket=state[key]
    if not bucket then bucket={tokens=burst,at=now};state[key]=bucket end
    bucket.tokens=math.min(burst,bucket.tokens+math.max(0,now-bucket.at)*rate)
    bucket.at=math.max(bucket.at,now)
    if bucket.tokens<1 then return false end
    bucket.tokens-=1;return true
end

function M.reserve(state,key,now,interval)
    local at=math.max(now,state[key]or -math.huge)
    state[key]=at+interval
    return at-now
end
local function recent(state,key,now,window)
    local list=state[key]or {};local out={}
    for _,t in ipairs(list)do if now-t<window then table.insert(out,t)end end
    state[key]=out;return out
end
function M.blocked(state,key,now,window,limit)return #recent(state,key,now,window)>=limit end
function M.count(state,key,now,window)table.insert(recent(state,key,now,window),now)end
function M.uniqueIds(list)
    local out,seen={},{}
    for _,v in ipairs(list)do if v==v and not seen[v]then seen[v]=true;table.insert(out,v)end end
    return out
end
return M
