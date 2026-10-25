local Rules=if script then require(script.Parent.OutgameRules)else require('./OutgameRules')
local Copy=Rules.copy
local M={}
function M.settings(settings)
    local out=Copy(settings);out.seed=nil;out.countryPolicy=nil;return out
end
function M.campaignNext(room,id,view)
    local progress=room and room.progress and room.progress[id];local C=Rules.campaign
    local stage=room and C.stage(room.campaign);if not stage then return nil end
    local nxt=C.stages[stage.index+1]
    if progress and progress.outcome=='won'and nxt and C.unlocked({campaign=view},nxt.id,stage.id)then return nxt.id end
    return stage.id
end
function M.single(room,id,now,campaignView)
    local progress=room and room.progress and room.progress[id]
    if not room or not room.single or not progress or not progress.ended then return nil end
    if room.campaign then local key=M.campaignNext(room,id,campaignView);local stage=Rules.campaign.stage(key)
        if stage.intro then return {users={id},teams={},mode='training',map=stage.map,intro=true,unrecorded=progress.unrecorded==true}end
        return {users={id},teams={},mode='single',map=stage.map,campaign=stage.id,rewardMode='single'}end
    if room.daily then local Daily=Rules.dailyOperation;local op=Daily.of(Daily.day(now or os.time()));return {users={id},teams={},mode='single',map=op.map,daily=op,rewardMode='single'}end
    if room.intro then return {users={id},teams={},mode='training',map=room.session.map.meta.key,intro=true,unrecorded=progress.unrecorded==true,rewardMode=progress.mode}end
    return {users={id},teams={},mode='single',map=room.session.map.meta.key,resumeSettings=M.settings(room.replaySettings or room.session.settings),rewardMode=progress.mode}
end
return M
