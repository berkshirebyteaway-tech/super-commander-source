local M={}
M.keys={'troops','conquered','built','nukes','warships','gold','alliances','intercepts'}
M.source={troops='troopsSent',conquered='countriesConquered',nukes='nukes',warships='warships',gold='gold',alliances='alliances',intercepts='intercepts'}
M.styleBase={expansion=2,build=6,diplomacy=1,naval=1.5,nuke=.3}
M.styleNames={expansion='확장형',build='건설가형',diplomacy='외교형',naval='해군형',nuke='핵전략형'}
local function n(v,max)if type(v)~='number'or v~=v or math.abs(v)==math.huge then return 0 end;return math.clamp(v,0,max or 1e12)end
function M.built(t)local b=0;for kind,c in pairs(type(t.built)=='table'and t.built or {})do if kind~='Warship'then b+=n(c,1e6)end end;return math.floor(b)end
function M.values(event)
    local t=type(event.tactics)=='table'and event.tactics or {};local v={}
    for _,k in ipairs(M.keys)do v[k]=k=='built'and M.built(t)or math.floor(n(t[M.source[k]]))end
    v.seconds=math.floor(n(event.seconds,1e6));v.fleet=math.floor(n(t.fleetPeak,1e4));v.peak=n(event.peak,1)
    return v
end
function M.top10(place,field)
    place,field=n(place,1e4),n(field,1e4);return place>=1 and field>=2 and place<=math.ceil(field*.1)
end
function M.categories(event)
    local list={'all'}
    if event.ranked==true then table.insert(list,'ranked')
    elseif event.mode=='pvp'or event.mode=='coop'then table.insert(list,'public')end
    return list
end
local function blank()local c={games=0,wins=0,top10=0,seconds=0};for _,k in ipairs(M.keys)do c[k]=0 end;return c end
function M.apply(p,event,receipt)
    if event.mode=='training'or event.mode=='custom'then return end
    local normal=event.outcome=='won'or event.outcome=='lost'or event.outcome=='forfeit'
    if not normal then return end
    p.record=type(p.record)=='table'and p.record or {}
    local rec=p.record;rec.best=type(rec.best)=='table'and rec.best or {peak=0,conquered=0,fleet=0}
    local v=M.values(event);local old=type(receipt.record)=='table'and receipt.record or {}
    local first=old.counted~=true;local won=event.outcome=='won'and old.won~=true
    local top=M.top10(event.place,event.field)and old.top10~=true
    for _,cat in ipairs(M.categories(event))do
        local c=type(rec[cat])=='table'and rec[cat]or blank();rec[cat]=c
        if first then c.games+=1 end;if won then c.wins+=1 end;if top then c.top10+=1 end
        for _,k in ipairs(M.keys)do c[k]=(c[k]or 0)+math.max(0,v[k]-n(old[k]))end
        c.seconds=(c.seconds or 0)+math.max(0,v.seconds-n(old.seconds))
    end
    rec.best.peak=math.max(n(rec.best.peak,1),v.peak);rec.best.conquered=math.max(n(rec.best.conquered),v.conquered);rec.best.fleet=math.max(n(rec.best.fleet),v.fleet)
    local next={counted=true,won=old.won==true or event.outcome=='won',top10=old.top10==true or M.top10(event.place,event.field)}
    for _,k in ipairs(M.keys)do next[k]=math.max(n(old[k]),v[k])end;next.seconds=math.max(n(old.seconds),v.seconds)
    receipt.record=next
end
function M.row(event)
    local v=M.values(event)
    return {place=event.place,field=event.field,top10=M.top10(event.place,event.field)or nil,conquered=v.conquered,troops=v.troops,built=v.built,nukes=v.nukes,ranked=event.ranked==true or nil}
end
function M.style(c)
    local g=math.max(1,c and c.games or 0)
    local mine={expansion=(c and c.conquered or 0)/g,build=(c and c.built or 0)/g,diplomacy=(c and c.alliances or 0)/g,naval=(c and c.warships or 0)/g,nuke=(c and c.nukes or 0)/g}
    local bars,best,bestRatio={},nil,-1
    for _,k in ipairs({'expansion','build','diplomacy','naval','nuke'})do
        local ratio=mine[k]/M.styleBase[k];bars[k]=ratio
        if ratio>bestRatio then best,bestRatio=k,ratio end
    end
    return {bars=bars,type=(c and c.games or 0)>0 and best or nil,name=(c and c.games or 0)>0 and M.styleNames[best]or nil}
end
function M.view(p)
    local rec=type(p.record)=='table'and p.record or {};local out={best=table.clone(type(rec.best)=='table'and rec.best or {peak=0,conquered=0,fleet=0})}
    for _,cat in ipairs({'all','public','ranked'})do
        local c=type(rec[cat])=='table'and table.clone(rec[cat])or blank()
        c.winRate=c.games>0 and c.wins/c.games or 0;c.top10Rate=c.games>0 and c.top10/c.games or 0
        c.avgSeconds=c.games>0 and c.seconds/c.games or 0;c.style=M.style(c)
        out[cat]=c
    end
    return out
end
return M
