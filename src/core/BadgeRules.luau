local M={}
M.ids={
    enlist=2430480450638090,rank10=1026313764254163,rank50=3792138484926466,conquest1=3127439294922961,pvpWin=1987631214836453,
    rank20=3665810574432235,rank70=3313278595241369,comrades=2995865218039782,comeback=1147250344100150,goldTactic=2320895359074142,
    rank100=3181968361707507,conquest5=948465119879108,dominion=4187978247427556,noNukeWin=3613355335408398,veteran=4059710498778678,
}
local function tier(view,id)for _,t in ipairs(view.tactics or {})do if t.id==id then return t.tier end end;return 0 end
local function games(view)local n=0;for _,s in pairs(view.stats or {})do n+=s.games or 0 end;return n end
M.rules={
    enlist=function(v)return games(v)>=1 end,
    rank10=function(v)return (v.level or 1)>=10 end,
    rank20=function(v)return (v.level or 1)>=20 end,
    rank50=function(v)return (v.level or 1)>=50 end,
    rank70=function(v)return (v.level or 1)>=70 end,
    rank100=function(v)return (v.level or 1)>=100 end,
    conquest1=function(v)return (v.mapsConquered or 0)>=1 end,
    conquest5=function(v)return (v.mapsConquered or 0)>=5 end,
    pvpWin=function(v)return tier(v,'pvpVictor')>=1 end,
    comrades=function(v)return tier(v,'comrades')>=1 end,
    comeback=function(v)return tier(v,'comeback')>=1 end,
    dominion=function(v)return tier(v,'dominion')>=1 end,
    noNukeWin=function(v)return tier(v,'noNukeWin')>=2 end,
    goldTactic=function(v)for _,t in ipairs(v.tactics or {})do if t.tier>=3 then return true end end;return false end,
    veteran=function(v)return games(v)>=50 end,
}
function M.earned(view,all)
    local list={};if type(view)~='table'then return list end
    for key,test in pairs(M.rules)do if (all or (M.ids[key]or 0)>0)and test(view)then table.insert(list,key)end end
    table.sort(list);return list
end
return M
