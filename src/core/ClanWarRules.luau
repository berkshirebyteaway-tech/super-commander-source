local M={}
M.teamSize=2
M.winPoints=20
M.lossPoints=-10
M.winContribution=10
M.lossContribution=0
M.history=60
local Fallback={}
do
    local function daysFromCivil(y,m,d)
        y-=m<=2 and 1 or 0;local era=(y>=0 and y or y-399)//400;local yoe=y-era*400
        local doy=(153*((m+9)%12)+2)//5+d-1;local doe=yoe*365+yoe//4-yoe//100+doy
        return era*146097+doe-719468
    end
    function Fallback.start(n)local months=9+n;return daysFromCivil(2026+months//12,months%12+1,1)*86400 end
    function Fallback.at(time)
        local n=0;if time>=Fallback.start(0)then while time>=Fallback.start(n+1)do n+=1 end end
        return {n=n,key='S'..n,start=Fallback.start(n),finish=Fallback.start(n+1),preseason=n==0,label=n==0 and '프리시즌'or string.format('시즌 %d',n)}
    end
end
local function calendar()
    if script then
        local core=game:GetService('ReplicatedStorage'):FindFirstChild('FrontierNative')
        local m=core and core:FindFirstChild('Core')and core.Core:FindFirstChild('MonthlySeason')
        if m then local ok,mod=pcall(require,m);if ok and type(mod)=='table'and mod.at then return mod end end
    end
    return Fallback
end
M.Fallback=Fallback
function M.at(now)return calendar().at(now)end
function M.season(now)return M.at(now).key end
function M.label(now)return M.at(now).label end
function M.remaining(now)return math.max(0,M.at(now).finish-now)end
local function seasonNumber(s)return type(s)=='string'and tonumber(s:match('^S(%d+)$'))or -1 end
function M.record(u,season)
    local w=type(u.war)=='table'and u.war or nil
    u.warSeasons=type(u.warSeasons)=='table'and u.warSeasons or {}
    if w then u.warSeasons[w.season]=w end
    local out=u.warSeasons[season]
    if not out then out={season=season,points=0,wins=0,losses=0};u.warSeasons[season]=out end
    if not w or seasonNumber(season)>=seasonNumber(w.season)then u.war=out end
    return out
end
function M.award(u,matchId)return type(u)=='table'and type(u.warAwards)=='table'and u.warAwards[matchId]or nil end
M.repeatWindow=86400
function M.repeatFactor(u,opponent,now)
    if type(opponent)~='string'then return 1 end
    u.warPairs=type(u.warPairs)=='table'and u.warPairs or {}
    for k,v in pairs(u.warPairs)do if type(v)~='table'or now-(v.t or 0)>=M.repeatWindow then u.warPairs[k]=nil end end
    local v=u.warPairs[opponent]or {t=now,n=0};v.n+=1;u.warPairs[opponent]=v
    return v.n>=6 and 0 or v.n>=4 and .5 or 1
end
function M.apply(u,matchId,season,won,players,now,opponent)
    if type(u)~='table'then return nil,'unit-missing'end
    local prior=M.award(u,matchId);if prior then return u,false,prior.share end
    if u.disbanded then return nil,'unit-missing'end
    u.warSeen=type(u.warSeen)=='table'and u.warSeen or {}
    for _,id in ipairs(u.warSeen)do if id==matchId then return u,false,nil end end
    table.insert(u.warSeen,matchId);while #u.warSeen>M.history do table.remove(u.warSeen,1)end
    local w=M.record(u,season)
    local factor=M.repeatFactor(u,opponent,now)
    if won then w.wins+=1;w.points+=math.floor(M.winPoints*factor)else w.losses+=1;w.points=math.max(0,w.points+M.lossPoints)end
    local share=won and math.floor(M.winContribution*factor)or M.lossContribution
    local week=math.floor((math.floor(now/86400)+3)/7)
    u.contrib=type(u.contrib)=='table'and u.contrib or {}
    for _,uid in ipairs(players)do
        local key=tostring(uid)
        local r=u.contrib[key];if type(r)~='table'then r={t=0,w=0,wk=week,seq=0};u.contrib[key]=r end
        if (r.wk or -1)<week then r.w=0;r.wk=week end
        r.t+=share;if r.wk==week then r.w+=share end;r.wars=(r.wars or 0)+1
        u.xp=(tonumber(u.xp)or 0)+share
    end
    u.warAwards=type(u.warAwards)=='table'and u.warAwards or {}
    u.warAwards[matchId]={share=share,players=table.clone(players),season=season,time=now}
    return u,true,share
end
function M.personal(l,matchId,share)
    l.wars=type(l.wars)=='table'and l.wars or {}
    l.warKeys=type(l.warKeys)=='table'and l.warKeys or {}
    for _,id in ipairs(l.wars)do if id==matchId then return l,false end end
    if l.warKeys[matchId]then return l,false end
    l.warKeys[matchId]=true
    table.insert(l.wars,matchId);while #l.wars>M.history do table.remove(l.wars,1)end
    l.total=(tonumber(l.total)or 0)+share;l.warTotal=(tonumber(l.warTotal)or 0)+share
    return l,true
end
function M.party(clans)
    if #clans~=M.teamSize then return nil,'war-size'end
    local first=clans[1];if not first then return nil,'war-clan'end
    for _,c in ipairs(clans)do if c~=first then return nil,'war-clan'end end
    return first
end
function M.summary(w)if not w then return 0,0,0 end;return w.points or 0,w.wins or 0,w.losses or 0 end
return M
