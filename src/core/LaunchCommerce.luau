local M={version=1,medalDrawCost=900,clubDailyTickets=1,freeLoadouts=2,permanentLoadouts=4,permanentPresets=12}
M.rarityOrder={'normal','rare','epic','legendary','mythic'}
M.rarityNames={normal='노말',rare='레어',epic='에픽',legendary='전설',mythic='신화'}
M.weights={normal=700000,rare=220000,epic=65000,legendary=13000,mythic=2000}
M.tickets={
    basic={name='기본 뽑기권',suggestedRobux=29},
    epic={name='에픽 뽑기권',rarity='epic',suggestedRobux=149},
    legendary={name='전설 뽑기권',rarity='legendary',suggestedRobux=499},
    mythic={name='신화 뽑기권',rarity='mythic',suggestedRobux=1499},
}
M.permanent={name='커맨더 프라임',suggestedRobux=1000,welcome={epic=2,legendary=1,mythic=1}}
M.club={name='VIP 커맨더 클럽',suggestedRobux=200}
M.categories={
    {id='territory',name='영토',planned=21},
    {id='buildings',name='건물 세트',planned=13},
    {id='nuclear',name='핵 연출 세트',planned=14},
    {id='vehicle',name='탈것',planned=16},
    {id='commanderTrail',name='내 트레일',planned=13},
    {id='motion',name='모션',planned=17},
    {id='parachute',name='낙하산'},
}
function M.benefits(permanent,subscribed)
    return {permanent=permanent==true,club=subscribed==true,xpMultiplier=(permanent and 2 or 1)*(subscribed and 2 or 1),
        loadoutSlots=permanent and M.permanentLoadouts or M.freeLoadouts,presetSlots=permanent and M.permanentPresets or 0,
        publicCustom=subscribed==true,dailyTickets=subscribed and M.clubDailyTickets or 0}
end
local function epoch(v)
    if type(v)=='number'and v==v and v>0 and v<1e11 then return math.floor(v)end
    if typeof and typeof(v)=='DateTime'then return v.UnixTimestamp end
end
function M.clubPeriod(details)
    if type(details)~='table'then return nil end
    local expires,renews=epoch(details.ExpireTime),epoch(details.NextRenewTime)
    if not expires and not renews then return nil end
    return {endsAt=expires or renews,renewing=expires==nil and renews~=nil}
end
function M.clubDaysLeft(endsAt,now)
    if type(endsAt)~='number'or type(now)~='number'then return nil end
    return math.max(0,math.ceil((endsAt-now)/86400))
end
function M.clubLapsed(period,now)return type(period)=='table'and period.renewing==false and type(period.endsAt)=='number'and now>=period.endsAt end
return M
