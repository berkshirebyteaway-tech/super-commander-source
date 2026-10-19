local Format=if script then require(script.Parent.TeamFormat)else require("./TeamFormat")
local M={}
M.limit=12;M.ttl=90;M.renew=20;M.maxObservers=30;M.cache=10
local function share(s,id)local land=s:landTiles();return land>0 and s.sim.players[id].tiles.size/land or 0 end
function M.mode(s)
    if s.teamCount and s.teamCount>1 then return Format.short(s.settings.teamFormat or s.teamCount,s.teamCount)end
    return '개인전'
end
function M.pick(s,want)
    local p=want and s.sim.players[want]
    if p and p.kind~='BOT'and p.tiles.size>0 then return want end
    local best,size
    for id,q in ipairs(s.sim.players)do if q.kind~='BOT'and q.tiles.size>0 and (not size or q.tiles.size>size)then best,size=id,q.tiles.size end end
    return best or (p and want)or 1
end
function M.entry(room,now)
    local s=room.session;local humans,alive,nations=0,0,0
    for id,p in ipairs(s.sim.players)do
        if p.kind=='HUMAN'then humans+=1;if p.tiles.size>0 and not(s.resources[id]and s.resources[id].forfeited)then alive+=1 end
        elseif p.kind=='NATION'and p.tiles.size>0 then nations+=1 end
    end
    local members={}
    for uid,id in pairs(room.members or {})do
        local p,r=s.sim.players[id],s.resources[id]
        if p and p.kind=='HUMAN'and r and not r.forfeited and not(room.progress and room.progress[uid]and room.progress[uid].final)and (s.phase=='spawn'or p.tiles.size>0)then table.insert(members,uid)end
    end
    table.sort(members)
    local lead=M.pick(s,nil)
    return {id=room.globalMatch,code=room.liveCode,map=s.map.meta.key,mode=M.mode(s),humans=humans,alive=alive,nations=nations,
        leader=s.sim.players[lead]and s.sim.players[lead].name or nil,leaderShare=math.floor(share(s,lead)*1000)/1000,
        started=room.startedAt,updated=now,watchers=room.observerCount or 0,phase=s.phase,members=members}
end
function M.mine(rows,userId,now)
    for _,r in ipairs(rows or {})do
        if type(r)=='table'and type(r.members)=='table'and table.find(r.members,userId)and (r.updated or 0)+M.ttl>=now and r.phase~='won'then return {id=r.id,map=r.map}end
    end
end
function M.listed(room)
    return room.globalMatch~=nil and room.official==true and not room.ranked and not room.clanwar and not room.endedAt and room.session.winnerId==nil
end
function M.public(rows,now,exclude)
    local out={}
    for _,r in ipairs(rows or {})do
        if type(r)=='table'and type(r.id)=='string'and r.id~=exclude and (r.updated or 0)+M.ttl>=now and r.phase~='won'then
            table.insert(out,{id=r.id,map=r.map,mode=r.mode,humans=r.humans,alive=r.alive,nations=r.nations,leader=r.leader,leaderShare=r.leaderShare,
                minutes=math.max(0,math.floor((now-(r.started or now))/60)),watchers=r.watchers or 0,spawning=r.phase=='spawn'or nil})
        end
    end
    table.sort(out,function(a,b)
        if (a.watchers>0)~=(b.watchers>0)then return a.watchers>0 end
        if a.alive~=b.alive then return a.alive>b.alive end
        return a.id<b.id
    end)
    while #out>M.limit do table.remove(out)end
    return out
end
function M.ended(s)
    local w=s.winnerId and s.sim.players[s.winnerId]
    if not w then return '경기 종료'end
    return string.format(s.winnerTeam and '경기 종료, %s 팀 승리'or '경기 종료, %s 승리',w.name)
end
return M
