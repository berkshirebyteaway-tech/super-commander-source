local M={}
M.maxMembers=100
M.nameMin,M.nameMax=2,16
M.tagMin,M.tagMax=2,4
M.codeLength=6
M.codeAlphabet='ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
M.maxLevel=100
M.attendAmount=100
M.extraPerDay=2
M.colors={
    {54,226,208},{59,130,246},{139,92,246},{236,72,153},
    {255,82,82},{255,152,56},{245,196,81},{132,204,22},
}
local function length(s)local ok,n=pcall(utf8.len,s);return ok and n or nil end
local function hangul(cp)return cp>=0xAC00 and cp<=0xD7A3 end
function M.validName(name)
    if type(name)~='string'then return nil,'invalid-name'end
    name=name:gsub('^%s+',''):gsub('%s+$','');local n=length(name)
    if not n or n<M.nameMin or n>M.nameMax or name:find('%s%s')then return nil,'invalid-name'end
    for _,cp in utf8.codes(name)do
        if not(hangul(cp)or cp==32 or (cp>=48 and cp<=57)or (cp>=65 and cp<=90)or (cp>=97 and cp<=122))then return nil,'invalid-name'end
    end
    return name
end
function M.validTag(tag)
    if type(tag)~='string'then return nil,'invalid-tag'end
    local n=length(tag);if not n or n<M.tagMin or n>M.tagMax then return nil,'invalid-tag'end
    local out={}
    for _,cp in utf8.codes(tag)do
        if cp>=97 and cp<=122 then cp-=32 end
        if not(hangul(cp)or (cp>=48 and cp<=57)or (cp>=65 and cp<=90))then return nil,'invalid-tag'end
        table.insert(out,utf8.char(cp))
    end
    return table.concat(out)
end
function M.validCode(code)
    if type(code)~='string'or #code~=M.codeLength then return nil end
    code=code:upper();for i=1,#code do if not M.codeAlphabet:find(code:sub(i,i),1,true)then return nil end end
    return code
end
function M.validColor(i)i=tonumber(i);if i and i%1==0 and M.colors[i]then return i end;return nil end
function M.color(u)return M.colors[type(u)=='table'and M.validColor(u.color)or 1]end
function M.code(random)
    local out={};for i=1,M.codeLength do local k=random(#M.codeAlphabet);out[i]=M.codeAlphabet:sub(k,k)end
    return table.concat(out)
end
function M.new(id,name,tag,leader,code,now,color)
    return {id=id,name=name,tag=tag,leader=leader,code=code,created=now,members={[tostring(leader)]=now},count=1,color=M.validColor(color)or 1,xp=0,contrib={}}
end
local function recount(u)local n=0;for _ in pairs(u.members)do n+=1 end;u.count=n;return n end
function M.join(u,userId,now)
    if type(u)~='table'or u.disbanded or type(u.members)~='table'then return nil,'unit-missing'end
    local key=tostring(userId);if u.members[key]then return u end
    local ban=type(u.banned)=='table'and tonumber(u.banned[key])
    if ban and now and now-ban<M.banSeconds then return nil,'banned'end
    if recount(u)>=M.maxMembers then return nil,'unit-full'end
    u.members[key]=now;recount(u);return u
end
function M.leave(u,userId)
    if type(u)~='table'then return nil end
    local key=tostring(userId);u.members[key]=nil
    if recount(u)==0 then return nil end
    if tostring(u.leader)==key then
        local best,at;for id,t in pairs(u.members)do if not at or t<at or t==at and id<best then best,at=id,t end end
        u.leader=tonumber(best)
    end
    return u
end
function M.leaveStored(u,userId)
    if type(u)~='table'or u.disbanded then return u end
    local out=M.leave(u,userId);if out then return out end
    return {id=u.id,code=u.code,disbanded=true,count=0,members={},contrib=u.contrib,attendRejected=u.attendRejected,warAwards=u.warAwards,warArchiveEpoch=u.warArchiveEpoch,warSeen=u.warSeen,war=u.war,warSeasons=u.warSeasons,memberOps=u.memberOps}
end
M.banSeconds=7*86400
function M.kick(u,leader,target,now)
    if type(u)~='table'or u.disbanded or tostring(u.leader)~=tostring(leader)then return nil,'not-leader'end
    if tostring(target)==tostring(leader)or not u.members[tostring(target)]then return nil,'invalid-request'end
    u.members[tostring(target)]=nil;recount(u)
    if now then
        local bans=type(u.banned)=='table'and u.banned or {};u.banned=bans
        for k,t in pairs(bans)do if type(t)~='number'or now-t>=M.banSeconds then bans[k]=nil end end
        bans[tostring(target)]=now
    end
    return u
end
function M.promote(u,leader,target)
    if type(u)~='table'or u.disbanded or tostring(u.leader)~=tostring(leader)then return nil,'not-leader'end
    if tostring(target)==tostring(leader)or not u.members[tostring(target)]then return nil,'invalid-request'end
    u.leader=tonumber(target);return u
end
function M.recolor(u,leader,color)
    if type(u)~='table'or u.disbanded or tostring(u.leader)~=tostring(leader)then return nil,'not-leader'end
    local c=M.validColor(color);if not c then return nil,'invalid-request'end
    u.color=c;return u
end
function M.week(time)return math.floor((math.floor(time/86400)+3)/7)end
function M.day(time)return math.floor(time/86400)end

function M.levelCost(level)return 100*math.ceil((500+100*level+12*level*level)/100)end
function M.level(xp)
    xp=math.max(0,math.floor(tonumber(xp)or 0));local level=1
    while level<M.maxLevel do local cost=M.levelCost(level);if xp<cost then return level,xp,cost end;xp-=cost;level+=1 end
    return M.maxLevel,xp,nil
end

local function row(u,userId,week)
    u.contrib=type(u.contrib)=='table'and u.contrib or {}
    local key=tostring(userId);local r=u.contrib[key]
    if type(r)~='table'then r={t=0,w=0,wk=week,seq=0};u.contrib[key]=r end
    if r.wk~=week then r.w=0;r.wk=week end
    return r
end
M.row=row
function M.credit(u,userId,seq,amount,now)
    local key=tostring(userId)
    local prior=type(u)=='table'and type(u.contrib)=='table'and u.contrib[key]
    if type(prior)=='table'and (prior.seq or 0)>=seq then return u end
    if type(u)~='table'or u.disbanded or type(u.members)~='table'then return nil,'unit-missing'end
    if type(u.attendRejected)=='table'and (u.attendRejected[key]or 0)>=seq then return nil,'not-member'end
    if not u.members[key]then return nil,'not-member'end
    local week=M.week(now)
    local r=row(u,userId,math.max(week,type(prior)=='table'and tonumber(prior.wk)or week))
    r.seq=seq;r.day=math.max(tonumber(r.day)or -1,M.day(now));r.t+=amount
    if r.wk==week then r.w+=amount end
    u.xp=(tonumber(u.xp)or 0)+amount
    return u
end
function M.creditStored(u,userId,seq,amount,now,clanId)
    local out,err=M.credit(u,userId,seq,amount,now)
    if out then return out end
    if type(u)~='table'then u={id=clanId,disbanded=true,count=0,members={}}end
    u.attendRejected=type(u.attendRejected)=='table'and u.attendRejected or {}
    local key=tostring(userId);u.attendRejected[key]=math.max(u.attendRejected[key]or 0,seq)
    return u,err
end

function M.ledger(l,now)
    l=type(l)=='table'and l or {}
    l.seq=tonumber(l.seq)or 0;l.tokens=tonumber(l.tokens)or 0;l.total=tonumber(l.total)or 0
    l.receipts=type(l.receipts)=='table'and l.receipts or {}
    l.receiptKeys=type(l.receiptKeys)=='table'and l.receiptKeys or {}
    for _,id in ipairs(l.receipts)do if type(id)=='string'then l.receiptKeys[id]=true end end
    l.wars=type(l.wars)=='table'and l.wars or {}
    local today=M.day(now)
    if l.day~=today then l.day=today;l.free=false;l.extra=0 end
    l.extra=tonumber(l.extra)or 0
    return l
end
function M.attend(l,kind,clanId,now)
    l=M.ledger(l,now)
    if l.pending then return nil,'busy'end
    if kind=='free'then
        if l.free then return nil,'attended'end
        l.free=true
    elseif kind=='extra'then
        if not l.free then return nil,'free-first'end
        if l.extra>=M.extraPerDay then return nil,'extra-done'end
        if l.tokens<=0 then return nil,'need-token'end
        l.tokens-=1;l.extra+=1
    else return nil,'invalid-request'end
    l.seq+=1;l.total+=M.attendAmount
    l.pending={seq=l.seq,clan=clanId,amount=M.attendAmount,kind=kind,day=l.day}
    return l
end
function M.refund(l,seq)
    if type(l)~='table'or type(l.pending)~='table'or l.pending.seq~=seq then return l end
    local p=l.pending;l.total=math.max(0,l.total-p.amount)
    if l.day==p.day then if p.kind=='free'then l.free=false else l.extra=math.max(0,l.extra-1)end end
    if p.kind=='extra'then l.tokens+=1 end
    l.pending=nil;return l
end
function M.settle(l,seq)if type(l)=='table'and type(l.pending)=='table'and l.pending.seq==seq then l.pending=nil end;return l end
function M.grantToken(l,purchaseId,now)
    l=M.ledger(l,now)
    if type(purchaseId)~='string'or #purchaseId<1 or #purchaseId>100 then return nil,'invalid-request'end
    if l.receiptKeys[purchaseId]then return l,true end
    l.receiptKeys[purchaseId]=true
    table.insert(l.receipts,purchaseId);while #l.receipts>40 do table.remove(l.receipts,1)end
    l.tokens+=1;return l,false
end
return M
