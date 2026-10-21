local Rules=if script then require(script.Parent.RankedRules)else require('./RankedRules')
local War=if script then require(script.Parent.ClanWarRules)else require('./ClanWarRules')
local M={}
M.windows={{0,100},{15,200},{30,350},{45,500},{60,math.huge}}
M.duoGap=500
M.maxEntries=60
M.queues={'1v1','2v2','clanwar','ffa'}
M.ffaFillSeconds=45
function M.rulesLadder(queue)return queue=='clanwar'and '2v2'or queue end
function M.seats(queue)return Rules.size[M.rulesLadder(queue)]end
function M.window(waited)
    local w=M.windows[1][2];for _,x in ipairs(M.windows)do if waited>=x[1]then w=x[2]end end;return w
end
function M.field(ladder)return 'ranked-'..ladder end
function M.ladderOf(field)if field=='ranked-clanwar'then return 'clanwar'elseif field=='ranked-ffa'then return 'ffa'end;return type(field)=='string'and field:match('^ranked%-(%dv%d)$')or nil end
function M.entries(s,ladder)
    local by,list={},{}
    for uid,t in pairs(s.tickets)do if not t.match and t.field==M.field(ladder)then
        local key=t.group or uid;local e=by[key]
        if not e then e={key=key,users={},rp=0,joined=t.joined,group=t.group,clan=t.clan};by[key]=e;table.insert(list,e)end
        table.insert(e.users,tonumber(uid));e.rp+=t.rp or Rules.start;e.joined=math.min(e.joined,t.joined)
    end end
    for _,e in ipairs(list)do e.rp=e.rp/#e.users;table.sort(e.users)end
    table.sort(list,function(a,b)return a.joined<b.joined or a.joined==b.joined and a.users[1]<b.users[1]end)
    return list
end
function M.check(op)
    local ladder=M.ladderOf(op.field);if not ladder then return 'stale'end
    if type(op.ratings)~='table'then return 'party'end
    if ladder=='clanwar'then
        if #op.users<War.minSize or #op.users>War.maxSize or type(op.clan)~='string'or #op.clan<1 or #op.clan>64 then return 'party'end
        return nil
    end
    if #op.users>(ladder=='2v2'and 2 or 1)then return 'party'end
    local lo,hi=math.huge,-math.huge
    for _,id in ipairs(op.users)do local rp=op.ratings[tostring(id)];if type(rp)~='number'or rp~=rp then return 'party'end;lo=math.min(lo,rp);hi=math.max(hi,rp)end
    if hi-lo>M.duoGap then return 'gap'end
    return nil
end
local function teamsFor(ladder,group)
    local teams={}
    if ladder=='1v1'or ladder=='ffa'then for i,e in ipairs(group)do teams[e.users[1]]=i end;return teams end
    if ladder=='clanwar'then for i,e in ipairs(group)do for _,id in ipairs(e.users)do teams[id]=i end end;return teams end
    local duos,solos={},{}
    for _,e in ipairs(group)do if #e.users==2 then table.insert(duos,e)else table.insert(solos,e)end end
    if #duos==2 then for i,e in ipairs(duos)do for _,id in ipairs(e.users)do teams[id]=i end end
    elseif #duos==1 then for _,id in ipairs(duos[1].users)do teams[id]=1 end;for _,e in ipairs(solos)do teams[e.users[1]]=2 end
    else
        table.sort(solos,function(a,b)return a.rp>b.rp or a.rp==b.rp and a.users[1]<b.users[1]end)
        teams[solos[1].users[1]]=1;teams[solos[4].users[1]]=1;teams[solos[2].users[1]]=2;teams[solos[3].users[1]]=2
    end
    return teams
end
function M.pick(list,ladder,now)
    if ladder=='clanwar'then
        for _,a in ipairs(list)do
            local n=#a.users
            if n>=War.minSize and n<=War.maxSize then
                local group,seen={a},{[a.clan]=true}
                for _,b in ipairs(list)do if #group<War.maxClans and #b.users==n and b.clan and not seen[b.clan]then
                    seen[b.clan]=true;table.insert(group,b)
                end end
                if #group>=War.maxClans or #group>=War.minClans and now-a.joined>=War.gatherSeconds then return group end
            end
        end
        return nil
    end
    local need=Rules.size[ladder];local ffa=ladder=='ffa'
    for i,anchor in ipairs(list)do
        local gap=M.window(now-anchor.joined)
        local group,seats={anchor},#anchor.users
        for j,e in ipairs(list)do if j~=i and seats<need and seats+#e.users<=need then
            local d=math.abs(e.rp-anchor.rp)
            if d<=gap and d<=M.window(now-e.joined)then table.insert(group,e);seats+=#e.users end
        end end
        if seats==need then return group end
        if ffa and seats>=Rules.minimum.ffa and now-anchor.joined>=M.ffaFillSeconds then return group end
    end
    return nil
end
function M.match(s,now,nextMatch,maxMatches,host)
    if not nextMatch or not s.tickets then return end
    local function size(t)local n=0;for _ in pairs(t)do n+=1 end;return n end
    for index,ladder in ipairs(M.queues)do
        while size(s.matches)<maxMatches do
            local group=M.pick(M.entries(s,ladder),ladder,now);if not group then break end
            s.seed=(s.seed*48271)%2147483647
            local seats=0;for _,e in ipairs(group)do seats+=#e.users end
            local war=ladder=='clanwar'
            local rules=war and War.rules(#group,#group[1].users,s.seed)or Rules.rules(M.rulesLadder(ladder),s.seed,seats)
            local mid=nextMatch..'-r'..index..'-'..(s.serial+1);s.serial+=1
            local m={creator=host,kind='ranked',phase='reserving',expires=now+25,rules=rules,field=M.field(ladder),revision=0,members={},groups={},leaders={},teams={},ratings={},clanwar=war or nil,clans=war and {}or nil,warSize=war and #group[1].users or nil,warCount=war and #group or nil}
            for uid,team in pairs(teamsFor(war and 'clanwar'or M.rulesLadder(ladder),group))do m.teams[tostring(uid)]=team end
            for _,e in ipairs(group)do for _,id in ipairs(e.users)do local uid=tostring(id);local t=s.tickets[uid]
                t.match=mid;m.members[uid]=t.token;m.groups[uid]=t.group;m.ratings[uid]=t.rp or Rules.start;if t.group then m.leaders[t.group]=t.leader end
                if m.clans then m.clans[uid]=t.clan end
            end end
            s.matches[mid]=m
        end
    end
end
function M.viable(m,arrived)
    if m.rules.ranked=='ffa'and not m.clanwar then return arrived>=Rules.minimum.ffa end
    return arrived==m.rules.maximum
end
function M.status(s,uid,t,now)
    local ladder=M.ladderOf(t.field);local m=t.match and s.matches[t.match]
    local waiting=0;for _,x in pairs(s.tickets)do if not x.match and x.field==t.field then waiting+=1 end end
    local party=1;if t.group then party=0;for _,x in pairs(s.tickets)do if x.group==t.group then party+=1 end end end
    local seats=m and m.rules.maximum or ladder=='clanwar'and party*War.minClans or M.seats(ladder)
    return {mode='ranked',ladder=ladder,field=t.field,rules=m and m.rules or nil,count=m and seats or waiting,max=seats,minimum=ladder=='clanwar'and seats or Rules.minimum[M.rulesLadder(ladder)]or seats,
        joined=t.joined,waited=math.max(0,now-t.joined),window=M.window(now-t.joined),partyCount=t.group and party or nil,warSize=ladder=='clanwar'and party or nil,
        phase=m and 'transferring'or 'searching',remaining=m and 0 or nil,global=true}
end
return M
