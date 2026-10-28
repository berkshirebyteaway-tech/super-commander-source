local Rules=if script then require(script.Parent.OutgameRules)else require('./OutgameRules')
local M={}
M.day=86400
M.delay=22*3600
M.ttl=3*86400
local function sum(p,field)local n=0;for _,st in pairs(type(p)=='table'and type(p.stats)=='table'and p.stats or {})do n+=tonumber(type(st)=='table'and st[field])or 0 end;return n end
function M.games(p)return sum(p,'games')end
function M.wins(p)return sum(p,'wins')end
function M.firstGame(before,p)return type(before)=='table'and M.games(before)==0 and M.games(p)>=1 end
function M.firstWin(before,p)return type(before)=='table'and M.wins(before)==0 and M.wins(p)>=1 end
M.favoriteStage='1-2'
local function cleared(p)local c=type(p)=='table'and type(p.campaign)=='table'and p.campaign or {};local s=type(c.stars)=='table'and c.stars or {};return (tonumber(s[M.favoriteStage])or 0)%2==1 end
function M.favorite(before,p)return type(before)=='table'and not cleared(before)and cleared(p)end
M.multiGames=2
function M.multi(p)local st=type(p)=='table'and type(p.stats)=='table'and p.stats or {};local n=0;for _,k in ipairs({'pvp','coop'})do n+=tonumber(type(st[k])=='table'and st[k].games)or 0 end;return n end
local function opened(p)return cleared(p)or M.multi(p)>=M.multiGames end
function M.held(p)return not opened(p)end
function M.unlocked(before,p)return type(before)=='table'and not opened(before)and opened(p)end
function M.holdCheckIn(p)local login=type(p)=='table'and type(p.login)=='table'and p.login or {};return M.held(p)and (tonumber(login.claims)or 0)<=1 end
function M.nextReset(now)return (math.floor(now/M.day)+1)*M.day end
function M.due(leftAt)return math.max(leftAt+M.delay,M.nextReset(leftAt)+600)end
function M.rows(p,freeAt,now)
    local rows={}
    local open=type(freeAt)=='number'and now>=freeAt
    table.insert(rows,{id='box',icon='reward',name='무료 보급 상자',when=open and 'now'or 'tomorrow',at=not open and freeAt or nil})
    local login=type(p)=='table'and p.login or {}
    table.insert(rows,{id='checkIn',icon='daily',name=string.format('출석 +%d 코인',tonumber(login.nextReward)or Rules.streakRewards[1]),when='tomorrow'})
    return rows
end
function M.kind(p)
    local login=type(p)=='table'and type(p.login)=='table'and p.login or {}
    local n=#Rules.streakRewards;return (tonumber(login.claims)or 0)%n+1==n and 'streak'or 'box'
end
M.sortieEvery=6*3600;M.sortieFriends=40;M.friendScan=200
function M.pick(ids,here,cap,random)
    local out={}
    for _,id in ipairs(ids)do if type(id)=='number'and id>0 and not here[id]then table.insert(out,id)end end
    for i=#out,2,-1 do local j=random(1,i);out[i],out[j]=out[j],out[i]end
    while #out>cap do table.remove(out)end
    return out
end
function M.body(universeId,messageId,params,launch,category)
    local parameters={}
    for k,v in pairs(params or {})do if type(k)=='string'then
        if type(v)=='string'then parameters[k]={string_value=v:sub(1,40)}elseif type(v)=='number'then parameters[k]={int64_value=string.format('%d',v)}end
    end end
    return {source={universe='universes/'..tostring(universeId)},payload={message_id=messageId,type='MOMENT',parameters=parameters,join_experience={launch_data=launch}},analytics_data={category=category}}
end
return M
