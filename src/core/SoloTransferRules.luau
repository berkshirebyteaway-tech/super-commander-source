local Custom=if script then require(script.Parent.CustomBattlefieldRules)else require('./CustomBattlefieldRules')
local Copy=if script then require(script.Parent.OutgameRules).copy else require('./OutgameRules').copy
local Format=if script then require(script.Parent.TeamFormat)else require('./TeamFormat')
local M={ttl=180}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function text(s)return type(s)=='string'and #s>0 and #s<=120 end
function M.new(userId,privateId,map,settings,intro,now,rewardMode,daily,campaign)
    if not finite(userId)or userId%1~=0 or userId<=0 or not text(privateId)or not finite(now)or type(settings)~='table'then return nil end
    if rewardMode~=nil and rewardMode~='single'and rewardMode~='custom'then return nil end
    if daily~=nil and(not finite(daily)or daily%1~=0 or daily<0)then return nil end
    if campaign~=nil and(type(campaign)~='string'or #campaign>8 or not campaign:match('^%d%-%d$')or daily~=nil or intro)then return nil end
    local validation=Copy(settings)
    if validation.randomSpawn~=nil and type(validation.randomSpawn)~='boolean'then return nil end
    local format=validation.teamFormat
    if format~=nil and (not Format.valid(format)or type(format)=='number'and format>7)then return nil end
    validation.randomSpawn=nil;validation.teamFormat=nil
    local checked=Custom.normalize({map=map,mode='coop',maximum=1,teamCount=2,aiPerHuman=1,spawn='select',visibility='invite',settings=validation})
    if not checked then return nil end
    for _,key in ipairs({'difficulty','nations','bots','startingGold','goldMultiplier','customAllianceDuration'})do if settings[key]==nil then return nil end end
    return {schema=1,userId=userId,privateId=privateId,map=map,settings=Copy(settings),intro=intro==true,rewardMode=rewardMode,daily=daily,campaign=campaign,expires=now+M.ttl,phase='waiting'}
end
function M.claim(ticket,userId,privateId,job,now)
    if type(ticket)~='table'or ticket.schema~=1 or ticket.userId~=userId or ticket.privateId~=privateId or not text(job)or not finite(ticket.expires)or not finite(now)or now>=ticket.expires then return nil end
    if ticket.goal~=nil and type(ticket.goal)~='boolean'then return nil end
    if ticket.quick~=nil and(type(ticket.quick)~='boolean'or ticket.goal or ticket.intro or ticket.daily~=nil or ticket.campaign~=nil)then return nil end
    if ticket.goal and(ticket.rewardMode~='single'or ticket.intro or ticket.daily~=nil)then return nil end
    if ticket.phase~='waiting'and not(ticket.phase=='claimed'and ticket.destination==job)then return nil end
    if ticket.campaign~=nil and(ticket.goal or ticket.rewardMode~='single')then return nil end
    local validated=M.new(userId,privateId,ticket.map,ticket.settings,ticket.intro,now,ticket.rewardMode,ticket.daily,ticket.campaign)
    if not validated then return nil end
    local out=Copy(ticket);out.phase='claimed';out.destination=job;return out
end
return M
