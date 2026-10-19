local Guards=if script then require(script.Parent.AbuseGuards)else require('./AbuseGuards')
local M={}
local kinds={read='read',leaders='leaders',replays='replays',cancel='cancel',leaveParty='cancel',
    map='edit',vote='edit',selectMode='edit',ready='edit',customUpdate='edit',customReady='edit',customTeam='edit',
    invite='social',accept='social',decline='social',kick='social',
    joinField='start',join='start',play='start',again='start',customCreate='start',joinCode='start',hq='start',rejoin='start',
    replay='start',ranked='start',practice='start',spectate='start',customStart='start',customLaunch='start'}
local limits={read={3,2},leaders={3,1},replays={3,1},cancel={4,2},edit={12,6},social={6,2},start={4,1}}
function M.take(state,action,now)
    local kind=type(action)=='string'and kinds[action]
    if not kind then return false,'invalid'end
    local rate=limits[kind]
    return Guards.take(state,kind,now,rate[1],rate[2]),'busy'
end
return M
