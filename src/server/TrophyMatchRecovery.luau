local Players=game:GetService('Players')
local Http=game:GetService('HttpService')
local M={}
local function bucket(q,mid)
    if not q.live then return nil end
    for key,s in pairs(q.storage.cache)do if key:sub(1,6)~='match:'and s and s.matches[mid]then return key end end
    return 'match:'..mid
end
local function authoritative(q,key)return q.live and q.storage.cache[key]or q.state end
local function acknowledge(q,mid,uid,key,request)
    if request.grant then
        local ok=q:update({kind='rankedRecoveryAck',match=mid,userId=uid,token=request.grant,bucket=key})
        request.acked=ok
    else request.acked=true end
end
local function abandon(q,mid,uid,key,request)
    if request.restoring and request.grant then q:retire(uid,request.grant,q.live and 'ranked'or nil)end
    request.done=true;acknowledge(q,mid,uid,key,request)
end
local function restore(q,mid,uid,token,key,request)
    if request.done then acknowledge(q,mid,uid,key,request);return end
    if not q:joinValid(request)then abandon(q,mid,uid,key,request);return end
    local ok=q:update({kind='rankedRecover',match=mid,userId=uid,token=token,recoveryToken=Http:GenerateGUID(false),bucket=key})
    if not ok then return end
    local source=authoritative(q,key);local m=source and source.matches[mid]
    local grant=m and m.recovery and m.recovery[tostring(uid)];local old=source and source.tickets[tostring(uid)]
    if not grant or not old or old.match~=mid or m.absent[tostring(uid)]then return end
    request.grant=grant.token
    if grant.done then request.done=true;request.acked=true;return end
    if not q:joinValid(request)then request.done=true;acknowledge(q,mid,uid,key,request);return end
    local t=table.clone(old);t.host=grant.host;t.token=grant.token
    request.restoring=true
    ok=q:update({kind='rankedRestore',userId=uid,ticket=t,oldToken=token,from=mid,bucket=q.live and 'ranked'or nil})
    if not ok then if not q:joinValid(request)then abandon(q,mid,uid,key,request)end;return end
    local state=authoritative(q,q.live and 'ranked'or nil);local recovered=state and state.tickets[tostring(uid)]
    if not recovered or recovered.token~=grant.token then return end
    if not q:joinValid(request)then
        abandon(q,mid,uid,key,request);return
    end
    q.active[uid]=grant.token;q.locations[uid]=q.live and 'ranked'or nil
    q.membership[uid]={users={uid},leader=uid,mode='ranked',ladder='r1v1',field='ranked-r1v1',joined=recovered.joined,rules=m.rules}
    q.sending[uid]=nil;q.attempts[uid]=nil;q.retryAt[uid]=nil
    request.done=true
    if q.live then q:refreshView()end
    local a=q.arrivals[mid];if a then a.users[uid]=nil;if not next(a.users)then q.arrivals[mid]=nil end end
    if q.callbacks then q.callbacks.arrival(uid,false)end
    q:notify(uid,'상대 다시 찾는 중')
    acknowledge(q,mid,uid,key,request)
end
function M.scan(q,state)
    q.trophyJobs=q.trophyJobs or {};q.trophyPending=q.trophyPending or {};q.trophyRestores=q.trophyRestores or {}
    local host=q.live and game.JobId or 'studio'
    for mid,m in pairs(state and state.matches or {})do if m.trophySolo and m.phase=='cancelled'then
        local key=bucket(q,mid);local source=authoritative(q,key)
        local pending=false
        for id in pairs(m.members)do local uid=tonumber(id);local t=source and source.tickets[id]
            if t and t.match==mid then
                if m.absent[id]and not m.penaltyAck[id]and (m.creator==host or m.destination==host or t.host==host)then
                    pending=true;local job=mid..':penalty:'..id
                    if not q.trophyJobs[job]then q.trophyJobs[job]=true;task.spawn(function()
                        local ok,err=pcall(function()
                            local time=q.live and m.cancelledAt or math.floor(m.cancelledAt+q.timeOffset)
                            if q.callbacks and q.callbacks.noShow and q.callbacks.noShow(uid,mid,time)==true then
                                q:update({kind='rankedPenaltyAck',match=mid,userId=uid,bucket=key})
                                if q.active[uid]==t.token then q.active[uid]=nil;q.locations[uid]=nil;q.membership[uid]=nil;q.sending[uid]=nil end
                                local a=q.arrivals[mid];if a then a.users[uid]=nil;if not next(a.users)then q.arrivals[mid]=nil end end
                                if Players:GetPlayerByUserId(uid)then q.callbacks.arrival(uid,false);q:notify(uid,'랭크 잠시 대기')end
                            end
                        end)
                        q.trophyJobs[job]=nil;if not ok then warn('TOYFRONT ranked recovery',err)end
                    end)end
                elseif not m.absent[id]then
                    local p=Players:GetPlayerByUserId(uid);local owner=m.arrived and m.arrived[id]or t.host
                    if p and owner==host then
                        local job=mid..':restore:'..id
                        local request=q.trophyRestores[job]
                        if not request then
                            local guard=q.callbacks and q.callbacks.recoveryGuard and q.callbacks.recoveryGuard(uid)
                            local active=q.active[uid]
                            request={players={[uid]=p},expires=m.expires,done=not guard or active~=nil and active~=t.token}
                            request.guard=function()return guard and guard()and (q.active[uid]==active or q.active[uid]==request.grant)end
                            q.trophyRestores[job]=request
                        end
                        if not request.acked then pending=true end
                        if not request.acked and not q.trophyJobs[job]and not q.joining[uid]and not q.cancelling[uid]then q.trophyJobs[job]=true;q.joining[uid]=request;task.spawn(function()
                            local ok,err=pcall(restore,q,mid,uid,t.token,key,request)
                            if q.joining[uid]==request then q.joining[uid]=nil end
                            q.trophyJobs[job]=nil;if not ok then warn('TOYFRONT ranked recovery',err)end
                        end)end
                    end
                end
            end
        end
        q.trophyPending[mid]=pending and true or nil
    end end
    for mid in pairs(q.trophyPending)do if not(state and state.matches[mid])then q.trophyPending[mid]=nil end end
    local now=q.live and os.time()or os.clock()
    for job,r in pairs(q.trophyRestores)do if now>=r.expires and not q.trophyJobs[job]then q.trophyRestores[job]=nil end end
end
return M
