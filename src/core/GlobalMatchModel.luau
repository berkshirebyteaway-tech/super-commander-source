local M={lease=35,maxTickets=80,maxMatches=6}
local function copy(v)if type(v)~='table'then return v end;local r={};for k,x in pairs(v)do r[k]=copy(x)end;return r end
local function size(t)local n=0;for _ in pairs(t)do n+=1 end;return n end
local function abort(s,id)
    for _,t in pairs(s.tickets)do if t.match==id then t.match=nil end end
    s.matches[id]=nil
end
local function remove(s,id)
    local t=s.tickets[id];if not t then return end
    local m=t.match and s.matches[t.match]
    if m and m.phase~='running'then
        m.members[id]=nil
        if size(m.members)<2 then abort(s,t.match)end
    end
    s.tickets[id]=nil
end
function M.waiting(s)
    local list={};for id,t in pairs(s.tickets)do if not t.match then table.insert(list,{id=id,ticket=t})end end
    table.sort(list,function(a,b)return a.ticket.joined<b.ticket.joined or a.ticket.joined==b.ticket.joined and tonumber(a.id)<tonumber(b.id)end)
    return list
end
function M.apply(previous,now,op)
    local s=copy(previous or {schema=1,tickets={},matches={}})
    assert(s.schema==1,'Unsupported queue schema')
    if op.kind=='pulse'then for id,token in pairs(op.tokens or {})do local t=s.tickets[id];if t and t.host==op.host and t.token==token then t.seen=now end end end
    for id,m in pairs(s.matches)do if now>=m.expires then abort(s,id)end end
    for id,t in pairs(s.tickets)do if now-t.seen>=M.lease and not t.match then remove(s,id)end end
    if op.kind=='join'then
        local id=tostring(op.userId)
        if not s.tickets[id]and size(s.tickets)<M.maxTickets then s.tickets[id]={host=op.host,token=op.token,joined=now,seen=now}end
    elseif op.kind=='cancel'then
        local id=tostring(op.userId);local t=s.tickets[id]
        if t and t.host==op.host and t.token==op.token then remove(s,id)end
    elseif op.kind=='ready'then
        local m=s.matches[op.match]
        if m and m.creator==op.host and m.phase=='reserving'then m.phase='ready';m.code=op.code;m.privateId=op.privateId;m.expires=now+110 end
    elseif op.kind=='claim'then
        local m=s.matches[op.match]
        if m and m.phase=='ready'and m.privateId==op.privateId and (not m.destination or m.destination==op.host)then m.destination=op.host end
    elseif op.kind=='start'then
        local m=s.matches[op.match]
        if m and m.phase=='ready'and m.destination==op.host then
            local arrived={};for _,id in ipairs(op.users or {})do id=tostring(id);if m.members[id]then arrived[id]=m.members[id]end end
            if size(arrived)>=2 then
                for id in pairs(m.members)do if not arrived[id]then local t=s.tickets[id];if t and t.match==op.match then t.match=nil;t.joined=now end end end
                m.members=arrived;m.phase='running';m.expires=now+120
            end
        end
    elseif op.kind=='abort'then
        local m=s.matches[op.match]
        if m and (m.creator==op.host and m.phase=='reserving'or m.destination==op.host)then abort(s,op.match)end
    end
    for mid,m in pairs(s.matches)do if m.phase=='reserving'then
        for id in pairs(m.members)do local t=s.tickets[id];if not t or now-t.seen>=M.lease then m.members[id]=nil;s.tickets[id]=nil end end
        if size(m.members)<2 then abort(s,mid)end
    end end
    local list=M.waiting(s);local count=math.min(10,#list)
    if count<2 then s.deadline=nil
    else
        s.deadline=s.deadline or now+60
        if count==10 then s.deadline=math.min(s.deadline,now+5)end
        if now>=s.deadline and op.nextMatch and size(s.matches)<M.maxMatches then
            local m={phase='reserving',creator=op.host,expires=now+25,members={}}
            for i=1,count do local item=list[i];item.ticket.match=op.nextMatch;m.members[item.id]=item.ticket.token end
            s.matches[op.nextMatch]=m;s.deadline=nil
            if #list-count>=2 then s.deadline=now+60 end
        end
    end
    return s
end
function M.status(s,id,token,now)
    local t=s and s.tickets[tostring(id)];if not t or t.token~=token then return nil end
    local m=t.match and s.matches[t.match]
    if m then return {mode='pvp',count=size(m.members),max=10,minimum=2,remaining=0,phase='transferring',global=true}end
    local list=M.waiting(s);local position=1;for i,item in ipairs(list)do if item.id==tostring(id)then position=i;break end end
    local waitingBatch=position>10
    return {mode='pvp',count=math.min(10,#list),max=10,minimum=2,remaining=not waitingBatch and s.deadline and math.max(0,s.deadline-now)or nil,phase=waitingBatch and 'next'or s.deadline and 'countdown'or 'waiting',global=true}
end
return M
