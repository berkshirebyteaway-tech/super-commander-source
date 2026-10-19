-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Config.ts economic rules, pinned e02eeba.
local D=if script then require(script.Parent.DetMath) else require("./DetMath")
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local E={}
local function host(settings,p,key) return p.host and settings.hostCheats and settings.hostCheats[key] end
local function infinite(settings,p,key) return settings[key] or host(settings,p,key) end
local function multiplier(settings,p) return host(settings,p,"goldMultiplier") or settings.goldMultiplier or 1 end
local difficulty={Easy={12500,.5,.9},Medium={18750,.75,.95},Hard={25000,1,1},Impossible={31250,1.25,1.05}}
function E.startTroops(settings,p)
    if p.kind=="BOT" then return 10000 end
    if p.kind=="NATION" then return difficulty[settings.difficulty or "Medium"][1] end
    return infinite(settings,p,"infiniteTroops") and 1000000 or 25000
end
function E.startGold(settings,p)
    if p.kind=="BOT" then return B.fromNumber(0) end
    return B.add(B.fromNumber(settings.startingGold or 0),B.fromNumber(host(settings,p,"startingGold") or 0))
end
function E.maxTroops(settings,p)
    local cap
    if p.kind=="HUMAN" and infinite(settings,p,"infiniteTroops") then cap=1000000000
    else cap=2*(D.pow(p.tiles,.6)*1000+50000)+(p.cityLevels or 0)*250000 end
    if p.kind=="BOT" then return cap/3 end
    if p.kind=="HUMAN" then return cap end
    return cap*difficulty[settings.difficulty or "Medium"][2]
end
function E.troopIncrease(settings,p)
    local cap=E.maxTroops(settings,p)
    local add=10+D.pow(p.troops,.73)/4
    add*=1-p.troops/cap
    if p.kind=="BOT" then add*=.5 end
    if p.kind=="NATION" then add*=difficulty[settings.difficulty or "Medium"][3] end
    return math.min(p.troops+add,cap)-p.troops
end
function E.goldRate(settings,p) return math.floor((p.kind=="BOT" and 50 or 100)*multiplier(settings,p)) end
local counts={Port={"Port","Factory"},Factory={"Factory","Port"}}
function E.cost(settings,p,kind,extra,mirvsLaunched)
    if p.kind=="HUMAN" and infinite(settings,p,"infiniteGold") then return B.fromNumber(0) end
    local n=extra or 0
    for _,k in ipairs(counts[kind] or {kind}) do n+=math.min((p.owned or {})[k] or 0,(p.constructed or {})[k] or 0) end
    local cost
    if kind=="City" or kind=="Port" or kind=="Factory" then cost=math.min(1000000,D.pow2(n)*125000)
    elseif kind=="DefensePost" then cost=math.min(250000,(n+1)*50000)
    elseif kind=="Warship" then cost=math.min(1000000,(n+1)*250000)
    elseif kind=="SAMLauncher" then cost=math.min(3000000,(n+1)*1500000)
    elseif kind=="MissileSilo" then cost=1000000
    elseif kind=="AtomBomb" then cost=750000
    elseif kind=="HydrogenBomb" then cost=5000000
    elseif kind=="MIRV" then cost=25000000+(mirvsLaunched or 0)*15000000
    elseif kind=="TransportShip" or kind=="Shell" or kind=="SAMMissile" or kind=="MIRVWarhead" or kind=="TradeShip" or kind=="Train" then cost=0
    else error("Unknown unit type "..tostring(kind)) end
    return B.fromNumber(cost)
end
function E.duration(settings,kind)
    if settings.instantBuild then return 0 end
    return ({City=20,Factory=20,Port=50,DefensePost=50,MissileSilo=100,SAMLauncher=300})[kind] or 0
end
function E.tradeShipGold(settings,p,dist)
    local base=75000/(1+D.exp(-.03*(dist-300)))+50*dist
    return B.fromNumber(math.floor(base*multiplier(settings,p)))
end
function E.trainGold(settings,p,relationship,citiesVisited)
    local base=({self=10000,team=25000,ally=35000,other=25000})[relationship]
    return B.fromNumber(math.floor(math.max(5000,base-math.max(0,citiesVisited-9)*5000)*multiplier(settings,p)))
end
function E.conquerGold(p)
    if p.kind=="BOT" or p.kind=="NATION" then return table.clone(p.gold) end
    local half=B.divideSmall(p.gold,2);return half
end
return E
