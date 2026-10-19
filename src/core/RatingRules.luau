local Ranked=if script then require(script.Parent.RankedRules)else require('./RankedRules')
local R={season="S0",placements=5}
function R.new()return {schema=1,season=R.season,rating=1000,rankedGames=0,games=0,wins=0,streak=0,bestStreak=0,xp=0,receipts={}}end
function R.tier(p)
    if p.rankedGames<R.placements then return "배치 "..p.rankedGames.."/"..R.placements end
    if p.rating>=1800 then return "마스터" elseif p.rating>=1600 then return "다이아" elseif p.rating>=1400 then return "골드" elseif p.rating>=1200 then return "실버" else return "브론즈"end
end
function R.delta(rating,opponent,score)return math.floor(32*(score-1/(1+10^((opponent-rating)/400)))+.5)end
function R.apply(raw,result)
    if raw and raw.schema~=1 then return nil,"unsupported-schema"end
    local p=raw and table.clone(raw) or R.new();p.receipts=table.clone(p.receipts or {})
    if p.receipts[result.id] then return p,"duplicate"end
    if result.startedAt and p.oldestAllowed and result.startedAt<p.oldestAllowed then return nil,"expired-result"end
    p.games+=1
    if result.counted~=false then p.wins+=result.won and 1 or 0;p.streak=result.won and p.streak+1 or 0;p.bestStreak=math.max(p.bestStreak,p.streak)end
    p.xp+=result.forfeited and 0 or result.won and 100 or 35
    if result.ladder and Ranked.size[result.ladder]then
        local delta,reason;p.ranked,delta,reason=Ranked.apply(p.ranked,result)
        if not p.ranked then return nil,reason end
        if p.ranked.season==Ranked.seasonOf(result.time)then p.lastRanked={id=result.id,ladder=result.ladder,delta=delta,rp=p.ranked.ladders[result.ladder].rp,won=result.won==true}end
    end
    if result.ranked and result.eligible then
        if p.season~=R.season then p.rating=math.floor(1000+(p.rating-1000)*.5);p.rankedGames=0;p.season=R.season end
        p.rating=math.clamp(p.rating+R.delta(p.rating,result.opponent,result.won and 1 or 0),100,3000);p.rankedGames+=1
    end
    p.receipts[result.id]=result.startedAt or 0
    local keys={};for id,time in pairs(p.receipts)do table.insert(keys,{id=id,time=time})end
    table.sort(keys,function(a,b)return a.time<b.time or a.time==b.time and a.id<b.id end)
    while #keys>120 do local old=table.remove(keys,1);p.receipts[old.id]=nil;p.oldestAllowed=math.max(p.oldestAllowed or 0,old.time+1)end
    return p
end
return R
