-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Ranked 1v1 / 2v2.
local Season=if script then require(script.Parent.MonthlySeason)else require('./MonthlySeason')
local M={schema=1}
M.ladders={'1v1','2v2'}
M.size={['1v1']=2,['2v2']=4}
M.maps={'australia','australia','iceland','asia','europeclassic'}
M.compact={minutes=10,bots=100}
M.spawnImmunity={['1v1']=30*10,['2v2']=60*10}
local BattlefieldVersion=1
function M.rules(ladder,roll)
    assert(M.size[ladder],'Unknown ladder')
    local map=M.maps[(roll or 0)%#M.maps+1]
    local duo=ladder=='2v2'
    local settings={difficulty='Medium',nations='disabled',bots=M.compact.bots,startingGold=0,goldMultiplier=1,
        customAllianceDuration=5,maxTimerValue=M.compact.minutes,donateGold=duo,donateTroops=duo,
        spawnImmunityDuration=M.spawnImmunity[ladder],disabledUnits={},rankedType=ladder,noFill=true}
    local r={version=BattlefieldVersion,map=map,mode=duo and 'teams'or 'ffa',minimum=2,maximum=M.size[ladder],spawn='select',settings=settings,ranked=ladder}
    if duo then r.teamFormat=2;r.teamCount=2;settings.teamFormat=2;settings.teamCount=2 end
    return r
end
function M.isRanked(rules)return type(rules)=='table'and M.size[rules.ranked]~=nil end

M.start=1000
M.tiers={
    {id='bronze',name='브론즈',min=0,color={201,138,75}},
    {id='silver',name='실버',min=900,color={191,201,212}},
    {id='gold',name='골드',min=1200,color={245,196,81}},
    {id='platinum',name='플래티넘',min=1500,color={143,227,238}},
    {id='diamond',name='다이아몬드',min=1800,color={111,168,255}},
    {id='master',name='마스터',min=2100,color={196,107,255}},
}
M.legend={id='legend',name='레전드',top=100,minRP=2100,color={255,214,120}}
function M.isLegend(rp,rank)return rank~=nil and rank<=M.legend.top and (rp or 0)>=(M.legend.minRP or 0)end
M.placements=5;M.replacements=3
local divisions={'III','II','I'}
function M.tierOf(rp)
    local t=M.tiers[1];for _,x in ipairs(M.tiers)do if rp>=x.min then t=x end end
    return t
end
function M.division(rp)
    local t=M.tierOf(rp);if t.id=='master'then return nil end
    if t.id=='bronze'then return rp<700 and 'III'or rp<800 and 'II'or 'I'end
    return divisions[math.clamp((rp-t.min)//100+1,1,3)]
end
function M.k(games)return games<M.placements and 48 or games<30 and 32 or 24 end
function M.expected(rp,opponent)return 1/(1+10^((opponent-rp)/400))end
function M.delta(rp,opponent,won,games)
    local d=math.floor(M.k(games)*((won and 1 or 0)-M.expected(rp,opponent))+.5)
    if won then return math.max(8,d)end
    return math.min(-5,d)
end
function M.reset(rp)return math.floor(M.start+(rp-M.start)*.5+.5)end
local function ladderNew()return {rp=M.start,games=0,wins=0,peak=M.start,streak=0,placement=M.placements,placementTotal=M.placements,recent={}}end
function M.new(season)return {schema=M.schema,season=season,ladders={},history={}}end
local function ensure(r,ladder)
    local l=r.ladders[ladder];if type(l)~='table'then l=ladderNew();r.ladders[ladder]=l end
    l.recent=type(l.recent)=='table'and l.recent or {};return l
end
function M.roll(raw,time)
    local key=Season.at(time).key
    local r=type(raw)=='table'and raw.schema==M.schema and table.clone(raw)or M.new(key)
    r.ladders=type(r.ladders)=='table'and table.clone(r.ladders)or {};r.history=type(r.history)=='table'and table.clone(r.history)or {}
    r.archived=type(r.archived)=='table'and table.clone(r.archived)or {}
    if r.season==key or (tonumber((r.season or ''):sub(2))or -1)>Season.at(time).n then return r end
    if r.season then
        local done={};for ladder,l in pairs(r.ladders)do if type(l)=='table'and (l.games or 0)>0 then done[ladder]={rp=l.rp,peak=l.peak,games=l.games,wins=l.wins,placed=(l.placement or 0)<=0}end end
        if next(done)then r.history[r.season]=done;r.archived[r.season]=r.ladders end
        local keys={};for k in pairs(r.history)do table.insert(keys,k)end
        table.sort(keys,function(a,b)return tonumber(a:sub(2))>tonumber(b:sub(2))end)
        for i=4,#keys do r.history[keys[i]]=nil;r.archived[keys[i]]=nil end
    end
    local fresh={}
    for ladder,l in pairs(r.ladders)do if type(l)=='table'and (l.games or 0)>0 then
        local rp=M.reset(l.rp or M.start);fresh[ladder]={rp=rp,games=0,wins=0,peak=rp,streak=0,placement=M.replacements,placementTotal=M.replacements,recent={}}
    end end
    r.ladders=fresh;r.season=key
    return r
end
function M.repeatFactor(l,opponents,time)
    local key=table.concat(opponents,',');local n=0
    for _,g in ipairs(l.recent)do if g.o==key and time-g.t<86400 then n+=1 end end
    return n>=5 and 0 or n>=3 and .5 or 1,key
end
local function applyCurrent(raw,result)
    if not M.size[result.ladder]then return raw,0 end
    local r=M.roll(raw,result.time);local l=ensure(r,result.ladder);l=table.clone(l);l.recent=table.clone(l.recent);r.ladders[result.ladder]=l
    local mine=result.ladder=='2v2'and result.team or l.rp
    local factor,key=M.repeatFactor(l,result.opponents or {},result.time)
    local d=M.delta(mine,result.opponent,result.won,l.games)
    if factor<1 then d=result.won and math.floor(d*factor)or math.ceil(d*factor)end
    l.rp=math.clamp(l.rp+d,0,5000);l.games+=1;l.wins+=result.won and 1 or 0
    l.streak=result.won and math.max(1,(l.streak or 0)+1)or math.min(-1,(l.streak or 0)-1)
    l.peak=math.max(l.peak or l.rp,l.rp);l.placement=math.max(0,(l.placement or 0)-1)
    table.insert(l.recent,{o=key,t=result.time});while #l.recent>12 do table.remove(l.recent,1)end
    return r,d
end
function M.apply(raw,result)
    local target=Season.at(result.time).key
    if type(raw)=='table'and (tonumber((raw.season or ''):sub(2))or -1)>Season.at(result.time).n then
        local archived=raw.archived and raw.archived[target]
        if not archived then return nil,0,'ranked-season-unavailable'end
        local old=M.new(target);old.ladders=archived
        local updated,delta=applyCurrent(old,result)
        local r=table.clone(raw);r.archived=table.clone(raw.archived);r.archived[target]=updated.ladders
        r.history=table.clone(raw.history or {});local summary={}
        for ladder,l in pairs(updated.ladders)do summary[ladder]={rp=l.rp,peak=l.peak,games=l.games,wins=l.wins,placed=(l.placement or 0)<=0}end
        r.history[target]=summary;return r,delta
    end
    return applyCurrent(raw,result)
end
function M.seasonOf(time)return Season.at(time).key end
function M.seasonLadder(r,season,ladder)
    if not r then return nil end
    if r.season==season then return r.ladders and r.ladders[ladder]end
    return r.archived and r.archived[season]and r.archived[season][ladder]
end
M.rewards={bronze=100,silver=200,gold=400,platinum=700,diamond=1000,master=1500,legend=2200,top10=3000,top1=5000}
M.rewardOrder={'bronze','silver','gold','platinum','diamond','master','legend','top10','top1'}
function M.band(rp,rank)
    if not M.isLegend(rp,rank)then return M.tierOf(rp).id end
    if rank and rank==1 then return 'top1'end
    if rank and rank<=10 then return 'top10'end
    if rank and rank<=M.legend.top then return 'legend'end
    return M.tierOf(rp).id
end
function M.seasonReward(r,seasonKey,ranks)
    local h=type(r)=='table'and type(r.history)=='table'and r.history[seasonKey];if not h then return nil end
    local best,ladder,bandId
    for _,id in ipairs(M.ladders)do local x=h[id];if x and x.placed then
        local b=M.band(x.rp,ranks and ranks[id]);local v=M.rewards[b]
        if not best or v>best then best,ladder,bandId=v,id,b end
    end end
    if not best then return nil end
    return {season=seasonKey,coins=best,ladder=ladder,band=bandId,rp=h[ladder].rp}
end
function M.bandName(id)
    if id=='top1'then return '1위'elseif id=='top10'then return 'TOP 10'elseif id=='legend'then return M.legend.name end
    for _,t in ipairs(M.tiers)do if t.id==id then return t.name end end
    return id
end
function M.view(raw,ladder,time)
    local r=M.roll(raw,time);local l=r.ladders[ladder]or ladderNew()
    local placing=(l.placement or 0)>0
    local t=M.tierOf(l.rp);local nextTier;for _,x in ipairs(M.tiers)do if x.min>l.rp then nextTier=x;break end end
    local div=M.division(l.rp)
    local nextAt=div and (t.id=='bronze'and (l.rp<700 and 700 or l.rp<800 and 800 or 900)or t.min+((l.rp-t.min)//100+1)*100)or nil
    return {ladder=ladder,rp=l.rp,games=l.games,wins=l.wins,losses=l.games-l.wins,peak=l.peak,streak=l.streak or 0,placing=placing,
        placementLeft=l.placement or 0,placementTotal=l.placementTotal or M.placements,
        tier=t.id,tierName=t.name,division=div,color=t.color,nextTier=nextTier and nextTier.id,toNext=nextAt and nextAt-l.rp or nil}
end
return M
