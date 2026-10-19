local Rules=if script then require(script.Parent.OutgameRules)else require('./OutgameRules')
local Copy=Rules.copy
local M={}
function M.settings(settings)
    local out=Copy(settings);out.seed=nil;out.countryPolicy=nil;return out
end
function M.single(room,id,now)
    local progress=room and room.progress and room.progress[id]
    if not room or not room.single or not progress or not progress.ended then return nil end
    if room.daily then local Daily=Rules.dailyOperation;local op=Daily.of(Daily.day(now or os.time()));return {users={id},teams={},mode='single',map=op.map,daily=op,rewardMode='single'}end
    if room.intro then return {users={id},teams={},mode='training',map=room.session.map.meta.key,intro=true,unrecorded=progress.unrecorded==true,rewardMode=progress.mode}end
    return {users={id},teams={},mode='single',map=room.session.map.meta.key,resumeSettings=M.settings(room.replaySettings or room.session.settings),rewardMode=progress.mode}
end
return M
