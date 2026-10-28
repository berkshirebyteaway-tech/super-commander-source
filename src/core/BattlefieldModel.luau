local R=if script then require(script.Parent.BattlefieldRules)else require('./BattlefieldRules')
local C=if script then require(script.Parent.CustomBattlefieldRules)else require('./CustomBattlefieldRules')
local Formation=if script then require(script.Parent.PartyFormation)else require('./PartyFormation')
local TeamLobby=if script then require(script.Parent.TeamLobby)else require('./TeamLobby')
local Ranked=if script then require(script.Parent.RankedQueue)else require('./RankedQueue')
local M={}
local function size(t)local n=0;for _ in pairs(t)do n+=1 end;return n end
local function count(s,f)
    local n=0;for _,t in pairs(s.tickets)do if not t.match and t.field==f.id then n+=1 end end;return n
end
local function promote(s,slot,now)
    local preset=R.recruitment.presetSlots[slot]or slot
    local old=s.fields[slot];local rules=old and R.valid(old.next)and not old.next.special and old.next.mode==R.slots[preset].kind and old.next or R.next(s,slot,preset)
    for other,f in ipairs(s.fields)do if other~=slot and f.rules.map==rules.map then rules=R.next(s,slot,preset);break end end
    assert(R.valid(rules));s.serial+=1
    local field={id=(s.fieldPrefix or 'official')..'-'..slot..'-'..s.serial,revision=s.serial,slot=slot,rules=rules,created=now,emptyAt=now,rotateAt=now+R.emptySeconds+(not old and (slot-1)*20 or 0)}
    table.insert(s.history,rules.map);if #s.history>8 then table.remove(s.history,1)end
    field.next=R.next(s,slot,preset);s.fields[slot]=field;return field
end
local function find(s,id)for _,f in ipairs(s.fields)do if f.id==id then return f end end;return s.customs and s.customs[id]end
local function members(s,f)
    local out={};for uid,t in pairs(s.tickets)do if not t.match and t.field==f.id then table.insert(out,{userId=tonumber(uid),name=t.name,level=t.level,joined=t.joined,ready=t.ready==true,team=t.team,group=t.group})end end
    table.sort(out,function(a,b)return a.joined<b.joined or a.joined==b.joined and a.userId<b.userId end);return out
end
local function allReady(s,f)local list=members(s,f);if #list<f.rules.minimum then return false end;for _,m in ipairs(list)do if not m.ready then return false end end;return true end
local function resetTeamReady(s,f)
    if f.kind~='custom'or f.rules.mode~='teams'or f.rules.teamAssignment~='select'then return end
    local count=TeamLobby.count(f.rules,#members(s,f));s.serial+=1;f.revision=s.serial;f.deadline=nil
    for _,t in pairs(s.tickets)do if not t.match and t.field==f.id then t.ready=false;t.revision=f.revision;if t.team and t.team>count then t.team=nil end end end
end
local function customOpponents(s,f)local p=TeamLobby.plan(f.rules,members(s,f));return p and not p.needsOpponent end
local function abort(s,id,now)
    local m=s.matches[id];if not m then return end
    if m.kind=='ranked'and s.tickets then for _,t in pairs(s.tickets)do if t.match==id then t.match=nil end end;s.matches[id]=nil;return end
    for uid,t in pairs(s.tickets)do if t.match==id then s.tickets[uid]=nil end end
    s.matches[id]=nil
end
local function roster(s,f)
    local users,groups={},{}
    for uid,t in pairs(s.tickets)do if not t.match and t.field==f.id then table.insert(users,tonumber(uid));groups[uid]=t.group end end
    return users,groups
end
local function affinity(s,f)
    local parent={}
    local function root(x)while parent[x]~=x do parent[x]=parent[parent[x]];x=parent[x]end;return x end
    local function join(a,b)local x,y=root(a),root(b);if x~=y then if tonumber(x)<tonumber(y)then parent[y]=x else parent[x]=y end end end
    local list,byGroup,byClan={},{},{}
    for uid,t in pairs(s.tickets)do if not t.match and t.field==f.id then parent[uid]=uid;table.insert(list,uid)end end
    if #list<2 then return nil end
    local soft=false
    for _,uid in ipairs(list)do local t=s.tickets[uid]
        if t.group then if byGroup[t.group]then join(byGroup[t.group],uid)else byGroup[t.group]=uid end end
        if t.clan then if byClan[t.clan]then join(byClan[t.clan],uid);soft=true else byClan[t.clan]=uid end end
        for _,id in ipairs(t.friends or {})do local other=tostring(id);if parent[other]then join(other,uid);soft=true end end
    end
    if not soft then return nil end
    local sizes={};for _,uid in ipairs(list)do local r=root(uid);sizes[r]=(sizes[r]or 0)+1 end
    local out={};for _,uid in ipairs(list)do local r=root(uid);if sizes[r]>1 then out[uid]='near:'..r else out[uid]=s.tickets[uid].group end end
    return out
end
M.affinity=affinity
local function nearFriends(s,f,uid,list)
    if type(list)~='table'then return nil end
    local out={};for _,id in ipairs(list)do local key=tostring(id)
        if #out>=20 then break end
        if type(id)=='number'and key~=uid then local t=s.tickets[key];if t and not t.match and t.field==f.id then table.insert(out,id)end end
    end
    return #out>0 and out or nil
end
local function nearClan(tag)return type(tag)=='string'and #tag>=1 and #tag<=16 and tag or nil end
local function teamView(s,f,list)
    if f.rules.mode~='teams'and f.rules.mode~='coop'then return nil end
    list=list or members(s,f)
    local official=f.kind~='custom';local assigned=f.lockedTeams
    if official and not assigned and #list>0 then local users,groups=roster(s,f);assigned=R.selection(f.rules,users,groups,affinity(s,f)).teams end
    local p=TeamLobby.view(f.rules,list,assigned,assigned~=nil and f.lockedTeams~=nil)
    if official then
        p.selectable=false;p.count=f.rules.teamCount or p.count;p.aiCounts={}
        local users=roster(s,f);local teams={};for uid,t in pairs(p.teams)do teams[tonumber(uid)]=t end
        if #users>0 then local fill=R.fill(f.rules,users,teams);for _,team in ipairs(fill.teams or {})do p.aiCounts[team]=(p.aiCounts[team]or 0)+1 end end
    end
    return p
end
local function viable(m)
    local users={};for uid in pairs(m.members)do table.insert(users,tonumber(uid))end
    if m.kind=='ranked'then return Ranked.viable(m,#users)end
    if m.kind=='custom'then
        if #users<m.rules.minimum then return false end
        if m.rules.mode=='teams'and m.rules.teamFormat~='HumansVsNations'and m.teams then
            local used={};for _,id in ipairs(users)do local t=m.teams[tostring(id)];if t then used[t]=true end end
            return size(used)>=2
        end
        return true
    end
    return R.canFill(m.rules,users,m.groups)
end
local function removeOne(s,id,now)
    local t=s.tickets[id];if not t then return end
    local f=s.customs and s.customs[t.field];if f then f.deadline=nil;f.lastAction=now end
    local m=t.match and s.matches[t.match]
    if m and m.phase~='running'then m.members[id]=nil;if not viable(m)then abort(s,t.match,now)end end
    s.tickets[id]=nil
    if f then resetTeamReady(s,f)end
end
local function remove(s,id,now)
    local t=s.tickets[id];if not t then return end
    local ids={id}
    if t.group then for uid,other in pairs(s.tickets)do if uid~=id and other.group==t.group and other.host==t.host then table.insert(ids,uid)end end end
    for _,uid in ipairs(ids)do removeOne(s,uid,now)end
end
function M.apply(previous,now,op)
    op=op or {}
    local s=R.copy(previous or {schema=2,customOnly=op.partition==true,fieldPrefix=op.fieldPrefix,seed=op.seed or 1729,serial=0,history={},fields={},tickets={},matches={}})
    assert(s.schema==2,'Unsupported battlefield schema')
    s.customs=s.customs or {}
    op=op or {};s.notice=nil;s.receipt=nil;s.exports=s.exports or {}
    for id,e in pairs(s.exports)do if now>=e.expires then s.exports[id]=nil end end
    if op.kind=='pulse'then for uid,token in pairs(op.tokens or {})do local t=s.tickets[uid];if t and t.host==op.host and t.token==token then t.seen=now end end end
    for mid,m in pairs(s.matches)do if now>=m.expires then abort(s,mid,now)end end
    for uid,t in pairs(s.tickets)do if not t.match and now-t.seen>=R.leaseSeconds then remove(s,uid,now)end end
    if not s.customOnly then for slot=1,R.recruitment.minimum do if not s.fields[slot]then promote(s,slot,now)end end end
    local waiting=0;for _,t in pairs(s.tickets)do if not t.match and not s.customs[t.field]and not Ranked.ladderOf(t.field)then waiting+=1 end end
    if not s.customOnly then
        local cfg=R.recruitment
        local desired=waiting>=cfg.largeAt and cfg.maximum or waiting>=cfg.mediumAt and cfg.medium or cfg.minimum
        if now>=(s.warmUntil or 0)then s.warmSlots=cfg.minimum end
        if desired>cfg.minimum and desired>=(s.warmSlots or cfg.minimum)then s.warmUntil=now+cfg.warmSeconds;s.warmSlots=desired end
        if now<(s.warmUntil or 0)then desired=math.max(desired,s.warmSlots or cfg.minimum)else s.warmSlots=desired end
        for slot=cfg.minimum+1,desired do if not s.fields[slot]then promote(s,slot,now)end end
        for slot=#s.fields,desired+1,-1 do if count(s,s.fields[slot])==0 then table.remove(s.fields,slot)else break end end
    end
    for slot,f in ipairs(s.fields)do local n=count(s,f)
        if n==0 then f.deadline=nil;f.emptyAt=f.emptyAt or now;f.rotateAt=f.rotateAt or now+R.emptySeconds;if now>=f.rotateAt then promote(s,slot,now)end
        else f.emptyAt=nil;f.rotateAt=nil end
    end
    if op.kind=='joinGroup'and Ranked.ladderOf(op.field)then
        local ids,seen={},{};local valid=type(op.users)=='table'and #op.users>=1 and #op.users<=(Ranked.ladderOf(op.field)=='clanwar'and 5 or 2)and type(op.tokens)=='table'
        if valid then for _,id in ipairs(op.users)do local uid=tostring(id)
            if type(id)~='number'or id~=id or math.abs(id)==math.huge or id%1~=0 or id==0 or seen[uid]or type(op.tokens[uid])~='string'then valid=false;break end
            seen[uid]=true;table.insert(ids,uid)
        end end
        valid=valid and (#ids==1 or type(op.group)=='string'and #op.group<=64 and seen[tostring(op.leader)])
        s.notice=not valid and 'party'or Ranked.check(op)
        local newSeats=0
        if not s.notice then for _,uid in ipairs(ids)do local old=s.tickets[uid]
            if old and (old.match or old.host~=op.host)then s.notice='locked';break end
            if old and old.group then for other,t in pairs(s.tickets)do if t.group==old.group and not seen[other]then s.notice='party'end end end
            if not old then newSeats+=1 end
        end end
        if not s.notice and size(s.tickets)+newSeats>R.maxTickets then s.notice='capacity'end
        if not s.notice then
            for _,uid in ipairs(ids)do remove(s,uid,now)end
            for _,uid in ipairs(ids)do s.tickets[uid]={field=op.field,revision=0,token=op.tokens[uid],host=op.host,joined=now,seen=now,name=string.sub((op.names or {})[uid]or '',1,80),rp=op.ratings[uid],ready=false,group=#ids>1 and op.group or nil,leader=#ids>1 and op.leader or nil,clan=Ranked.ladderOf(op.field)=='clanwar'and op.clan or nil}end
        end
    elseif op.kind=='joinGroup'then
        local f=find(s,op.field);local ids,seen={},{};local valid=type(op.users)=='table'and #op.users>=1 and #op.users<=5 and type(op.tokens)=='table'
        if valid then for _,id in ipairs(op.users)do
            local uid=tostring(id)
            if type(id)~='number'or id~=id or math.abs(id)==math.huge or id%1~=0 or id==0 or seen[uid]or type(op.tokens[uid])~='string'then valid=false;break end
            seen[uid]=true;table.insert(ids,uid)
        end end
        valid=valid and (#ids==1 or type(op.group)=='string'and #op.group<=64 and seen[tostring(op.leader)])
        if not valid then s.notice='party'
        elseif not f or f.revision~=op.revision or not(f.kind=='custom'and C.valid(f.rules)or f.kind~='custom'and R.valid(f.rules))then s.notice='stale'
        elseif f.kind=='custom'and f.rules.visibility=='invite'and not op.invited and not(s.tickets[tostring(op.leader)]and s.tickets[tostring(op.leader)].field==f.id)then s.notice='private'
        else
            local newSeats,retained,identical=0,0,true
            for _,uid in ipairs(ids)do local old=s.tickets[uid]
                if old and (old.match or old.host~=op.host)then s.notice='locked';break end
                if not old then newSeats+=1 elseif old.field==f.id then retained+=1 end
                if not old or old.field~=f.id or old.token~=op.tokens[uid]then identical=false end
                if old and old.group then for other,t in pairs(s.tickets)do if t.group==old.group and not seen[other]then s.notice='party';break end end end
                if s.notice then break end
            end
            local users,groups=roster(s,f);local candidate={}
            for _,id in ipairs(users)do if not seen[tostring(id)]then table.insert(candidate,id)end end
            for _,uid in ipairs(ids)do table.insert(candidate,tonumber(uid));groups[uid]=#ids>1 and op.group or nil end
            local customFits=true
            if f.kind=='custom'and f.rules.mode=='teams'then
                local list={};for _,id in ipairs(candidate)do local old=s.tickets[tostring(id)];table.insert(list,{userId=id,group=groups[tostring(id)],team=not seen[tostring(id)]and old and old.team or nil})end
                customFits=TeamLobby.plan(f.rules,list)~=nil
            end
            if not s.notice then
                if f.kind~='custom'and f.rules.mode=='teams'and f.deadline and now>=f.deadline-5 and retained<#ids then s.notice='locked'
                elseif count(s,f)-retained+#ids>f.rules.maximum then s.notice='full'
                elseif size(s.tickets)+newSeats>R.maxTickets then s.notice='capacity'
                elseif f.kind=='custom'and not customFits or f.kind~='custom'and not R.canFit(f.rules,candidate,groups)then s.notice='teamfull'
                elseif identical then for _,uid in ipairs(ids)do s.tickets[uid].seen=now end
                else
                    for _,uid in ipairs(ids)do remove(s,uid,now)end
                    for _,uid in ipairs(ids)do local lv=(op.levels or {})[uid];s.tickets[uid]={field=f.id,revision=f.revision,token=op.tokens[uid],host=op.host,joined=now,seen=now,name=string.sub((op.names or {})[uid]or '',1,80),level=type(lv)=='number'and lv>=1 and lv<=9999 and math.floor(lv)or nil,clan=f.kind~='custom'and nearClan((op.clans or {})[uid])or nil,friends=f.kind~='custom'and nearFriends(s,f,uid,(op.friends or {})[uid])or nil,ready=false,group=#ids>1 and op.group or nil,leader=#ids>1 and op.leader or nil}end
                    f.emptyAt=nil;f.rotateAt=nil;if f.kind~='custom'then f.joinFloor=now+R.joinFloorSeconds end
                    if f.kind=='custom'then f.deadline=nil;f.lastAction=now;resetTeamReady(s,f)end
                end
            end
        end
    elseif op.kind=='join'then
        local uid=tostring(op.userId);local f=find(s,op.field)
        if f and f.revision==op.revision and (f.kind=='custom'and C.valid(f.rules)or R.valid(f.rules))then
            local old=s.tickets[uid];local n=count(s,f)
            if old and old.match then s.notice='locked'
            elseif f.kind~='custom'and f.rules.mode=='teams'and f.deadline and now>=f.deadline-5 and not(old and old.field==f.id)then s.notice='locked'
            elseif f.kind=='custom'and f.rules.visibility=='invite'and not op.invited and not(old and old.field==f.id)then s.notice='private'
            elseif old and old.field==f.id and old.token==op.token then old.seen=now
            elseif old and old.group then s.notice='party'
            elseif n>=f.rules.maximum then s.notice='full'
            elseif old or size(s.tickets)<R.maxTickets then
                remove(s,uid,now);s.tickets[uid]={field=f.id,revision=f.revision,token=op.token,host=op.host,joined=now,seen=now,name=string.sub(op.name or '',1,80),ready=false};f.emptyAt=nil;f.rotateAt=nil;if f.kind~='custom'then f.joinFloor=now+R.joinFloorSeconds end
                if f.kind=='custom'then f.deadline=nil;f.lastAction=now;resetTeamReady(s,f)end
            else s.notice='capacity'end
        else s.notice='stale'end
    elseif op.kind=='customCreate'then
        local uid=tostring(op.userId);local rules=C.normalize(op.rules);local old=s.tickets[uid];local own=false
        for _,f in pairs(s.customs)do if f.hostUserId==uid then own=true end end
        local ids=op.users or {op.userId};local tokens=op.tokens or {[uid]=op.token};local seen={};local valid=type(ids)=='table'and #ids>=1 and #ids<=5 and type(tokens)=='table';local newSeats=0;local list={}
        if valid then for _,id in ipairs(ids)do local key=tostring(id);local prior=s.tickets[key]
            if type(id)~='number'or id~=id or math.abs(id)==math.huge or id%1~=0 or id==0 or seen[key]or type(tokens[key])~='string'then valid=false;break end
            seen[key]=true;if not prior then newSeats+=1 elseif prior.match or prior.host~=op.host then s.notice='locked'end
            table.insert(list,{userId=id,group=#ids>1 and op.group or nil})
        end end
        valid=valid and seen[uid]and (#ids==1 or type(op.group)=='string'and #op.group<=64)
        if valid then for _,id in ipairs(ids)do local prior=s.tickets[tostring(id)]
            if prior and prior.group then for key,t in pairs(s.tickets)do if t.group==prior.group and not seen[key]then valid=false end end end
        end end
        if not valid then s.notice='party'
        elseif s.notice then
        elseif not rules or type(op.customId)~='string'or type(op.code)~='string'or rules.maximum<#ids or rules.mode=='teams'and not TeamLobby.plan(rules,list)then s.notice='rules'
        elseif own or s.customs[op.customId]or size(s.customs)>=C.maxRooms or size(s.tickets)+newSeats>R.maxTickets then s.notice='capacity'
        else
            for _,id in ipairs(ids)do remove(s,tostring(id),now)end;s.serial+=1
            s.customs[op.customId]={id=op.customId,kind='custom',revision=s.serial,rulesRevision=s.serial,rules=rules,hostUserId=uid,hostName=op.name,code=op.code,created=now,lastAction=now}
            for _,id in ipairs(ids)do local key=tostring(id);s.tickets[key]={field=op.customId,revision=s.serial,token=tokens[key],host=op.host,joined=now,seen=now,name=(op.names or {})[key]or op.name,ready=false,group=#ids>1 and op.group or nil,leader=#ids>1 and op.userId or nil}end
        end
    elseif op.kind=='customUpdate'or op.kind=='customReady'or op.kind=='customStart'or op.kind=='customLaunch'or op.kind=='customTeam'then
        local uid=tostring(op.userId);local t=s.tickets[uid];local f=t and not t.match and s.customs[t.field]
        local sameRules=f and f.rulesRevision~=nil and type(op.revision)=='number'and op.revision>=f.rulesRevision and op.revision<=f.revision
        if not f or t.token~=op.token or t.host~=op.host then s.notice='stale'
        elseif f.revision~=op.revision and not(op.kind=='customTeam'and sameRules)then s.notice=sameRules and 'regroup'or 'stale'
        elseif op.kind=='customReady'then t.ready=not t.ready;f.lastAction=now;if not t.ready then f.deadline=nil end
        elseif op.kind=='customTeam'then
            local allowed,reason=TeamLobby.choose(f.rules,members(s,f),op.userId,op.team)
            if not allowed then s.notice=reason else
                for _,member in pairs(s.tickets)do if member.field==f.id and (member==t or t.group and member.group==t.group)then member.team=op.team>0 and op.team or nil end end
                f.lastAction=now;resetTeamReady(s,f)
            end
        elseif f.hostUserId~=uid then s.notice='host'
        elseif op.kind=='customUpdate'then
            local rules=C.normalize(op.rules)
            if not rules or count(s,f)>rules.maximum then s.notice='rules'
            else s.serial+=1;f.rules=rules;f.revision=s.serial;f.rulesRevision=s.serial;f.deadline=nil;f.lastAction=now
                for _,member in pairs(s.tickets)do if not member.match and member.field==f.id then member.revision=f.revision;member.ready=false;member.team=nil end end
            end
        elseif op.kind=='customLaunch'then
            local others=true;for _,member in ipairs(members(s,f))do if tostring(member.userId)~=uid and not member.ready then others=false end end
            if not others or count(s,f)<f.rules.minimum then s.notice='ready'
            elseif not customOpponents(s,f)then s.notice='opponent'
            else t.ready=true;f.deadline=f.deadline or now+(count(s,f)==1 and 0 or C.waitSeconds);f.lastAction=now end
        elseif allReady(s,f)and customOpponents(s,f)then f.deadline=f.deadline or now+C.waitSeconds;f.lastAction=now
        else s.notice='ready'end
    elseif op.kind=='fieldReady'then
        local uid=tostring(op.userId);local t=s.tickets[uid];local f=t and not t.match and find(s,t.field)
        if not f or f.kind=='custom'or Ranked.ladderOf(t.field)or t.token~=op.token or t.host~=op.host then s.notice='stale'
        elseif op.ready==true and count(s,f)<R.minHumans then t.ready=false;s.notice='alone'
        else t.ready=op.ready==true end
    elseif op.kind=='cancel'then
        local uid=tostring(op.userId);local t=s.tickets[uid]
        if t and t.host==op.host and t.token==op.token then remove(s,uid,now)end
    elseif op.kind=='detach'then
        local m=s.matches[op.match];local same=m and m.creator==op.host and m.phase=='ready'and type(op.roster)=='table'and size(m.members)==size(op.roster)
        if same then for uid,token in pairs(m.members)do if op.roster[uid]~=token then same=false;break end end end
        if same then
            for uid,t in pairs(s.tickets)do if t.match==op.match then s.tickets[uid]=nil end end
            s.matches[op.match]=nil;s.exports[op.match]={nonce=op.nonce,expires=now+160};s.receipt=op.nonce
        else s.notice='stale'end
    elseif op.kind=='ready'then
        local m=s.matches[op.match];if m and m.creator==op.host and m.phase=='reserving'then m.phase='ready';m.code=op.code;m.privateId=op.privateId;m.expires=now+110 end
    elseif op.kind=='claim'then
        local m=s.matches[op.match];if m and m.phase=='ready'and m.privateId==op.privateId and (not m.destination or m.destination==op.host)then m.destination=op.host end
    elseif op.kind=='start'then
        local m=s.matches[op.match];if m and m.phase=='ready'and m.destination==op.host then
            local arrived={};for _,uid in ipairs(op.users or {})do uid=tostring(uid);if m.members[uid]then arrived[uid]=m.members[uid]end end
            local candidate=R.copy(m);candidate.members=arrived
            if viable(candidate)then
                for uid in pairs(m.members)do if not arrived[uid]then s.tickets[uid]=nil end end
                m.members=arrived;m.phase='running';m.expires=now+120
            end
        end
    elseif op.kind=='abort'then
        local m=s.matches[op.match];if m and (m.creator==op.host and m.phase=='reserving'or m.destination==op.host)then abort(s,op.match,now)end
    end
    for mid,m in pairs(s.matches)do if m.phase=='reserving'then
        for uid in pairs(m.members)do local t=s.tickets[uid];if not t or now-t.seen>=R.leaseSeconds then if t then remove(s,uid,now)else m.members[uid]=nil end end end
        if s.matches[mid]and not viable(m)then abort(s,mid,now)end
    end end
    for slot,f in ipairs(s.fields)do
        local n=count(s,f)
        if n==0 then f.lockedTeams=nil;f.fillFirst=nil;f.readyAt=nil;f.fullAt=nil;f.joinFloor=nil;f.emptyAt=f.emptyAt or now;f.rotateAt=f.rotateAt or now+R.emptySeconds else f.emptyAt=nil;f.rotateAt=nil end
        local users,groups=roster(s,f)
        if n<R.minHumans then
            f.deadline=nil;f.fillFirst=nil;f.readyAt=nil;f.fullAt=nil;f.joinFloor=nil;f.lockedTeams=nil
            for _,t in pairs(s.tickets)do if not t.match and t.field==f.id then t.ready=false end end
        elseif not R.canFill(f.rules,users,groups)then f.deadline=nil else
            local ready=0;for _,t in pairs(s.tickets)do if not t.match and t.field==f.id and t.ready then ready+=1 end end
            f.fillFirst=f.fillFirst or now;local limit=f.fillFirst+R.waitMaxSeconds
            if not f.readyAt and ready>=R.majority(n)then f.readyAt=now end
            if n>=f.rules.maximum then f.fullAt=f.fullAt or now else f.fullAt=nil end
            local d=limit
            if f.readyAt then d=math.min(d,f.readyAt+R.readySeconds)end
            if f.joinFloor then d=math.max(d,math.min(f.joinFloor,limit+R.readySeconds))end
            if f.fullAt then d=math.min(d,f.fullAt+R.fullSeconds)end
            if f.lockedTeams and f.deadline then d=math.min(d,f.deadline)end
            f.deadline=d
            if f.rules.mode=='teams'and not f.lockedTeams and now>=f.deadline-5 then
                f.lockedTeams={};for uid,team in pairs(R.selection(f.rules,users,groups,affinity(s,f)).teams)do f.lockedTeams[tostring(uid)]=team end
            end
            if now>=f.deadline and op.nextMatch and size(s.matches)<R.maxMatches then
                local mid=op.nextMatch..'-'..slot
                local match={creator=op.host,phase='reserving',expires=now+25,rules=R.copy(f.rules),field=f.id,revision=f.revision,members={},groups={},leaders={}}
                for uid,t in pairs(s.tickets)do if not t.match and t.field==f.id then t.match=mid;match.members[uid]=t.token;match.groups[uid]=t.group;if t.group then match.leaders[t.group]=t.leader end end end
                match.teams=f.lockedTeams and R.copy(f.lockedTeams)or nil
                s.matches[mid]=match;promote(s,slot,now)
            end
        end
    end
    Ranked.match(s,now,op.nextMatch,R.maxMatches,op.host)
    if size(s.customs)>=C.maxRooms then
        local pick,oldest=nil,math.huge
        for id,f in pairs(s.customs)do local at=f.lastAction or f.created or now;if at<oldest and now-at>=900 and #members(s,f)==1 then pick,oldest=id,at end end
        if pick then removeOne(s,tostring(members(s,s.customs[pick])[1].userId),now);s.customs[pick]=nil end
    end
    for id,f in pairs(s.customs)do
        local list=members(s,f)
        if #list==0 then s.customs[id]=nil;continue end
        if not s.tickets[f.hostUserId]or s.tickets[f.hostUserId].field~=id or s.tickets[f.hostUserId].match then
            f.hostUserId=tostring(list[1].userId);f.hostName=list[1].name;f.deadline=nil;f.lastAction=now
        end
        if f.deadline and (not allReady(s,f)or not customOpponents(s,f))then f.deadline=nil end
        if f.deadline and now>=f.deadline and op.nextMatch and size(s.matches)<R.maxMatches then
            local mid=op.nextMatch..'-c'..f.revision;local match={creator=op.host,kind='custom',expires=now+25,phase='reserving',rules=R.copy(f.rules),field=f.id,revision=f.revision,hostUserId=f.hostUserId,members={},groups={},leaders={}}
            match.teams=TeamLobby.view(f.rules,list).teams
            for uid,t in pairs(s.tickets)do if not t.match and t.field==f.id then t.match=mid;match.members[uid]=t.token;match.groups[uid]=t.group;if t.group then match.leaders[t.group]=t.leader end end end
            s.matches[mid]=match;s.customs[id]=nil
        end
    end
    return s
end
function M.external(s,id)
    local m=assert(s.matches[id],'Match must exist')
    local out={schema=2,customOnly=true,seed=s.seed,serial=0,history={},fields={},customs={},tickets={},matches={[id]=R.copy(m)}}
    for uid,t in pairs(s.tickets)do if t.match==id then out.tickets[uid]=R.copy(t)end end
    return out
end
function M.directory(s,now,userId)
    local out={fields={},next={},now=now}
    if not s then return out end
    for _,f in ipairs(s.fields)do
        local members={};local ready=0;for uid,t in pairs(s.tickets)do if not t.match and t.field==f.id then table.insert(members,{userId=tonumber(uid),name=t.name,level=t.level,joined=t.joined,group=t.group,ready=t.ready==true});if t.ready then ready+=1 end end end
        table.sort(members,function(a,b)return a.joined<b.joined or a.joined==b.joined and a.userId<b.userId end)
        local users,groups=roster(s,f)
        table.insert(out.fields,{id=f.id,revision=f.revision,slot=f.slot,kind='official',rules=R.copy(f.rules),count=#members,members=members,teamPlan=teamView(s,f),needsOpponent=#users>=1 and not R.canFill(f.rules,users,groups)or nil,ai=R.fill(f.rules,users,#users>0 and f.rules.mode=='teams'and R.teams(f.rules,users,groups)or nil).ai,created=f.created,remaining=f.deadline and math.max(0,f.deadline-now)or nil,emptyRemaining=f.rotateAt and math.max(0,f.rotateAt-now)or nil,readyCount=ready,phase=M.phase(f)})
        if #out.next<2 then table.insert(out.next,{slot=f.slot,rules=R.copy(f.next)})end
    end
    local own=s.tickets[tostring(userId)]
    for _,f in pairs(s.customs or {})do if f.rules.visibility=='public'or own and own.field==f.id then
        local list=members(s,f);local ready=0;for _,p in ipairs(list)do if p.ready then ready+=1 end end
        table.insert(out.fields,{id=f.id,revision=f.revision,kind='custom',rules=R.copy(f.rules),hostUserId=tonumber(f.hostUserId),hostName=f.hostName,code=own and own.field==f.id and f.code or nil,count=#list,readyCount=ready,members=list,teamPlan=teamView(s,f,list),created=f.created,remaining=f.deadline and math.max(0,f.deadline-now)or nil,phase=f.deadline and 'countdown'or 'ready'})
    end end
    return out
end
function M.phase(f)return f.deadline and 'countdown'or 'waiting'end
function M.room(s,f,now)
    local n,ready=0,0;for _,t in pairs(s.tickets)do if not t.match and t.field==f.id then n+=1;if t.ready then ready+=1 end end end
    local reason=f.fullAt and 'full'or f.readyAt and 'majority'or 'timeout'
    return {state=(f.readyAt or f.fullAt)and 'go'or 'gather',ready=ready,need=R.majority(n),reason=reason,missing=n<R.minHumans and R.minHumans-n or nil,limit=f.fillFirst and math.max(0,f.fillFirst+R.waitMaxSeconds-now)or nil,
        extended=f.joinFloor~=nil and f.deadline~=nil and f.deadline==f.joinFloor and f.joinFloor>now or nil,locked=f.lockedTeams~=nil or nil}
end
function M.status(s,id,token,now)
    local t=s and s.tickets[tostring(id)];if not t or t.token~=token then return nil end
    if Ranked.ladderOf(t.field)then return Ranked.status(s,tostring(id),t,now)end
    local m=t.match and s.matches[t.match];local f=not m and find(s,t.field)
    local rules=m and m.rules or f and f.rules;if not rules then return nil end
    local custom=(m or f).kind=='custom'
    local needsOpponent,fillAI=false,nil;if not m and not custom then local users,groups=roster(s,f);needsOpponent=#users>=1 and not R.canFill(rules,users,groups);fillAI=#users>0 and R.fill(rules,users,rules.mode=='teams'and R.teams(rules,users,groups)or nil).ai or nil end
    return {mode=custom and 'custom'or 'pvp',field=t.field,revision=t.revision,rules=R.copy(rules),count=m and size(m.members)or count(s,f),max=rules.maximum,minimum=custom and rules.minimum or 1,joined=t.joined,ready=t.ready,partyCount=t.group and (function()local n=0;for _,other in pairs(s.tickets)do if other.group==t.group then n+=1 end end;return n end)()or nil,needsOpponent=needsOpponent or nil,ai=fillAI,hostUserId=custom and tonumber((m or f).hostUserId)or nil,code=custom and f and f.code or nil,members=f and members(s,f)or nil,teamPlan=f and teamView(s,f)or nil,remaining=m and 0 or f.deadline and math.max(0,f.deadline-now)or nil,phase=m and 'transferring'or custom and (f.deadline and 'countdown'or 'ready')or M.phase(f),global=true,room=not m and not custom and M.room(s,f,now)or nil}
end
function M.selection(m,users)
    if m.kind=='ranked'then
        local sorted=table.clone(users);table.sort(sorted);local teams,ratings={},{}
        for _,id in ipairs(sorted)do teams[id]=m.rules.mode=='teams'and m.teams[tostring(id)]or nil;ratings[id]=m.ratings[tostring(id)]end
        local parties={};for _,id in ipairs(sorted)do local g=m.groups and m.groups[tostring(id)];if g then parties[g]=parties[g]or {leader=m.leaders[g],users={}};table.insert(parties[g].users,id)end end
        return {users=sorted,teams=teams,mode=m.rules.mode,queueMode='pvp',map=m.rules.map,spawn=m.rules.spawn,settings=R.copy(m.rules.settings),official=true,ranked=not m.clanwar and m.rules.ranked or nil,clanwar=m.clanwar and {size=m.warSize or 2,count=m.warCount or 2,clans=(function()local out={};for _,id in ipairs(sorted)do out[id]=m.clans[tostring(id)]end;return out end)()}or nil,ratings=ratings,rulesVersion=m.rules.version,fill={ai=0},field=m.field,fieldRevision=0,parties=parties}
    end
    local out=(m.kind=='custom'and C or R).selection(m.rules,users,m.groups,m.teams);out.field=m.field;out.fieldRevision=m.revision
    if m.kind~='custom'and m.teams then for _,id in ipairs(users)do out.teams[id]=m.teams[tostring(id)]or out.teams[id]end;out.fill=R.fill(m.rules,users,out.teams)end
    if m.kind=='custom'then out.hostUserId=tonumber(m.hostUserId)end
    out.parties={}
    for _,id in ipairs(users)do local g=m.groups and m.groups[tostring(id)]
        if g then local party=out.parties[g];if not party then party={leader=m.leaders[g],users={}};out.parties[g]=party end;table.insert(party.users,id)end
    end
    for _,party in pairs(out.parties)do table.sort(party.users);if not table.find(party.users,party.leader)then party.leader=party.users[1]end end
    return out
end
return M
