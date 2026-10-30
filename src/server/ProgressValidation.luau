local M={}
local function finite(v,max)return type(v)=='number'and v==v and v>=0 and v<=(max or 1e12)end
local function object(t,limit,fn)
    if t==nil then return true end;if type(t)~='table'then return false end
    local n=0;for k,v in pairs(t)do n+=1;if n>limit or type(k)~='string'or #k>128 or not fn(v,k)then return false end end;return true
end
function M.reward(e)
    if e.benefitXP2~=nil and type(e.benefitXP2)~='boolean'then return false end
    if e.benefitXPMultiplier~=nil and e.benefitXPMultiplier~=1 and e.benefitXPMultiplier~=2 and e.benefitXPMultiplier~=4 then return false end
    if not ({single=true,pvp=true,coop=true,custom=true,training=true})[e.mode]or type(e.map)~='string'or #e.map>64 then return false end
    for _,key in ipairs({'seconds','cities','supports','humans','peak','time'})do if e[key]~=nil and not finite(e[key])then return false end end
    if e.tactics~=nil then
        if type(e.tactics)~='table'then return false end
        for _,key in ipairs({'troopsProduced','countriesConquered','troopsSent','gold','alliances','intercepts','warships','fleetPeak','mirv','growthGreen','trainGold','allyTrainGold','tradeGold','tradeCaptures','embargoes','betrayals'})do if e.tactics[key]~=nil and not finite(e.tactics[key])then return false end end
    end
    for _,key in ipairs({'place','field'})do if e[key]~=nil and not(finite(e[key],10000)and e[key]%1==0)then return false end end
    if e.ranked~=nil and e.ranked~=true then return false end
    if e.voided~=nil and e.voided~=true then return false end
    if e.official~=nil and e.official~=true then return false end
    if e.daily~=nil and not(finite(e.daily,1e6)and e.daily%1==0)then return false end
    if e.campaign~=nil and not(type(e.campaign)=='string'and #e.campaign<=8 and e.campaign:match('^%d%-%d$'))then return false end
    if e.gameSeconds~=nil and not(finite(e.gameSeconds,1e6)and e.gameSeconds%1==0 and e.gameSeconds>=0)then return false end
    if e.outcome~=nil and not ({won=true,lost=true,forfeit=true,expired=true,serverStop=true})[e.outcome]then return false end
    local function counts(b)return object(b,4,function(v,k)return ({seconds=true,cities=true,finished=true,supports=true})[k]and finite(v)end)end
    return object(e.days,64,counts)and object(e.weeks,32,function(v)return finite(v)end)and object(e.weeklyActions,32,counts)and object(e.milestones,8,function(v)return type(v)=='boolean'end)
end
function M.career(e)
    if e.trophyNoShow~=nil then
        return e.trophyNoShow==true and e.won==false and e.counted==false and e.ladder==nil and e.trophySolo==nil and finite(e.time)and finite(e.startedAt)
    end
    if e.trophySolo~=nil and not(e.trophySolo==true and e.ladder=='1v1'and finite(e.mine)and finite(e.opponent)and type(e.opponents)=='table'and #e.opponents==1)then return false end
    return type(e.won)=='boolean'and (e.forfeited==nil or type(e.forfeited)=='boolean')and (e.ranked==nil or type(e.ranked)=='boolean')and (e.eligible==nil or type(e.eligible)=='boolean')and (e.counted==nil or type(e.counted)=='boolean')and finite(e.startedAt)and (e.opponent==nil or finite(e.opponent,e.trophySolo and 1e12 or 10000))
        and (e.ladder==nil or (e.ladder=='1v1'or e.ladder=='2v2'or e.ladder=='ffa')and finite(e.time)and (e.team==nil or finite(e.team,10000))
            and (e.players==nil or finite(e.players,10)and e.players%1==0)
            and (e.pairs==nil or type(e.pairs)=='table'and #e.pairs<=9 and (function()for _,v in ipairs(e.pairs)do if not finite(v,10000)then return false end end;return true end)())
            and type(e.opponents)=='table'and #e.opponents<=9 and (function()for _,id in ipairs(e.opponents)do if type(id)~='number'or id%1~=0 then return false end end;return true end)())
end
return M
