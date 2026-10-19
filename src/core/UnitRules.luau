-- SPDX-License-Identifier: AGPL-3.0-only
local D=if script then require(script.Parent.DetMath) else require("./DetMath")
local M={}
M.structures={City=true,DefensePost=true,Port=true,Factory=true,MissileSilo=true,SAMLauncher=true}
M.upgradable={City=true,Port=true,Factory=true,MissileSilo=true,SAMLauncher=true}
M.nukes={AtomBomb=true,HydrogenBomb=true,MIRV=true,MIRVWarhead=true}
M.maxUpgradeAmount=50
M.toggleable={"City","DefensePost","Port","Warship","TransportShip","MissileSilo","SAMLauncher","AtomBomb","HydrogenBomb","MIRV","Factory"}
M.buildable={"City","Factory","Port","DefensePost","MissileSilo","SAMLauncher","Warship","AtomBomb","HydrogenBomb","MIRV"}
M.names={City="도시",DefensePost="요새",Port="항구",Factory="철도 기지",MissileSilo="미사일 사일로",SAMLauncher="방공 기지",Warship="순찰 군함",TransportShip="수송선",TradeShip="무역선",Train="화물열차",AtomBomb="원자 로켓",HydrogenBomb="수소 로켓",MIRV="다탄두 로켓",MIRVWarhead="분리 탄두",Shell="포탄",SAMMissile="요격 로켓"}
function M.disabled(settings,kind) return settings.disabledUnits and table.find(settings.disabledUnits,kind)~=nil or settings.disableNukes and M.nukes[kind]==true end
function M.samRange(level) return 150-480/(level+5) end
function M.dynamicSamRange(u,tick)
    if not u.rangeStart or tick>=u.rangeStart+45 then return M.samRange(u.level) end
    return u.rangeFrom+(M.samRange(u.level)-u.rangeFrom)*(tick-u.rangeStart)/45
end
function M.magnitude(kind) if kind=="HydrogenBomb" then return 80,100 elseif kind=="MIRVWarhead" then return 12,18 else return 12,30 end end
function M.nukeSpeed(kind) return ({AtomBomb=10,HydrogenBomb=10,MIRV=15,MIRVWarhead=22})[kind] end
function M.nukeDeaths(kind,troops,tiles,cap)
    if kind~="MIRVWarhead" then return 5*troops/math.max(1,tiles) end
    return 500*(1-D.exp(-2*math.max(0,troops-.03*cap)/cap))
end
local function sigmoid(x,k,mid) return 1/(1+D.exp(-k*(x-mid))) end
function M.smallEconomySpawnBoost(levels)
    if levels<=0 then return 1 end
    return 1+.5*math.clamp((6-levels)/5,0,1)/levels
end
function M.tradeSpawnRate(rejections,count,portLevels)
    local saturation=math.max(1-sigmoid(count,0.6931471805599453/50,330),.25*(1-sigmoid(count,0.6931471805599453/100,800)))
    local boost=M.smallEconomySpawnBoost(portLevels or 0)
    local base=100/(boost*boost)
    return math.max(1,math.floor(base*(1/(rejections+1))/saturation))
end
function M.trainSpawnRate(factories,count)
    local saturation=math.max(1-sigmoid(count,0.6931471805599453/100,560),.25*(1-sigmoid(count,0.6931471805599453/150,900)))
    return math.max(1,math.floor((factories+10)*15/(saturation*M.smallEconomySpawnBoost(factories))))
end
function M.maxHealth(u) return 1000+200*(u.veterancy or 0) end
function M.describe(u,costs,number,troops)
    number=number or tostring
    troops=troops or function(n)return number(n/10)end
    local details={City="병력 상한 +"..troops(u.level*250000),DefensePost="반경 30칸 안의 육상 방어를 강화해요.",Port="무역선 자동 출항, 군함 건조와 수리",Factory="근처 거점을 철도로 연결, 열차 자동 운행",MissileSilo="준비된 로켓 "..tostring(u.readyMissiles or u.level).." / "..u.level.."  재장전 9초",SAMLauncher="반경 "..math.floor(u.range or M.samRange(u.level)).."칸, 요격탄 "..tostring(u.readyMissiles or u.level).." / "..u.level,Warship="내구도 "..tostring(u.health or 0).." / "..tostring(u.maxHealth or 1000).."  숙련 "..tostring(u.veterancy or 0),TransportShip="상륙 병력 "..troops(u.troops or 0)..", 복귀 시 25% 손실",TradeShip="목적지 항구에 도착하면 교역 수입",Train="철도역에 도착하면 교역 수입"}
    return (details[u.kind] or M.names[u.kind] or u.kind)..(M.upgradable[u.kind] and "\n강화 비용 "..number(costs[u.kind] or 0).." 골드" or "")
end
return M
