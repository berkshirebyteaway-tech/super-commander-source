local M={}
M.retention=180
function M.cancel(s,mid,now,absent)
    local m=s.matches[mid]
    if not m or not m.trophySolo or m.phase=='running'then return false end
    if m.phase~='cancelled'then
        m.phase='cancelled';m.cancelledAt=now;m.expires=now+M.retention
        m.absent={};m.recovery={};m.penaltyAck={}
    end
    for uid in pairs(absent or {})do if m.members[uid]and not m.recovery[uid]then m.absent[uid]=true end end
    return true
end
function M.missing(m,users)
    local present,out={},{}
    for _,id in ipairs(users or {})do present[tostring(id)]=true end
    for uid in pairs(m.members)do if not present[uid]then out[uid]=true end end
    return out
end
function M.clear(s,mid)
    for uid,t in pairs(s.tickets)do if t.match==mid then s.tickets[uid]=nil end end
    s.matches[mid]=nil
end
function M.apply(s,now,op)
    local mid=op.match;local m=mid and s.matches[mid]
    if op.kind=='rankedFail'then
        if m and m.trophySolo and m.phase=='ready'and m.destination==op.host then
            M.cancel(s,mid,now,M.missing(m,op.users))
        else s.notice='stale'end
        return true
    elseif op.kind=='rankedRecover'then
        local uid=tostring(op.userId);local t=s.tickets[uid]
        if not m or not m.trophySolo or m.phase~='cancelled'or not t or t.match~=mid or t.token~=op.token or m.absent[uid]then s.notice='stale';return true end
        local host=m.arrived and m.arrived[uid]or t.host
        if op.host~=host then s.notice='stale';return true end
        local old=m.recovery[uid]
        if old and old.host~=op.host then s.notice='stale';return true end
        if not old then
            if type(op.recoveryToken)~='string'or #op.recoveryToken<1 then s.notice='stale';return true end
            m.recovery[uid]={host=op.host,token=op.recoveryToken}
        end
        return true
    elseif op.kind=='rankedRecoveryAck'then
        local grant=m and m.recovery and m.recovery[tostring(op.userId)]
        if m and m.trophySolo and m.phase=='cancelled'and grant and grant.host==op.host and grant.token==op.token then grant.done=true end
        return true
    elseif op.kind=='rankedPenaltyAck'then
        local uid=tostring(op.userId);local t=s.tickets[uid]
        if m and m.trophySolo and m.phase=='cancelled'and m.absent[uid]and (op.host==m.creator or op.host==m.destination or t and op.host==t.host)then m.penaltyAck[uid]=true end
        return true
    elseif op.kind=='rankedRestore'then
        local uid=tostring(op.userId);local t=op.ticket;local old=s.tickets[uid]
        if type(t)~='table'or t.field~='ranked-r1v1'or t.host~=op.host or type(t.token)~='string'or not op.from then s.notice='stale';return true end
        if old and old.token==t.token then return true end
        if old and not(old.match==op.from and old.token==op.oldToken)then s.notice='locked';return true end
        local copy={};for k,v in pairs(t)do copy[k]=v end
        copy.match=nil;copy.seen=now;copy.recoveredFrom=op.from;s.tickets[uid]=copy
        return true
    end
    return false
end
return M
