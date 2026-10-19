local Terrain=if script then require(script.Parent.Terrain)else require("./Terrain")
local Session=if script then require(script.Parent.MultiplayerSession)else require("./MultiplayerSession")
local Guards=if script then require(script.Parent.AbuseGuards)else require("./AbuseGuards")
local M={}
local function finite(n)return type(n)=="number" and n==n and math.abs(n)<math.huge end
local function validTile(s,t)return finite(t) and t%1==0 and t>=0 and t<s.map.meta.width*s.map.meta.height end
M.finite=finite;M.validTile=validTile
function M.record(action,value,extra)
    if action=='support'and type(extra)=='table'then return value,{target=extra.target,amount=extra.amount}end
    if action=='nuclear'then return value,{tile=extra.tile,silo=extra.silo,up=extra.up,relationStamp=extra.relationStamp,amount=finite(extra.amount)and extra.amount or nil}end
    if action=='moveWarships'then
        local ids={};for i=1,math.min(#value,200)do if finite(value[i])and value[i]%1==0 then table.insert(ids,value[i])end end
        return ids,extra
    end
    local function scalar(v)local t=type(v);if t=='number'or t=='boolean'or t=='string'and #v<=1000 then return v end;return nil end
    return scalar(value),scalar(extra)
end
function M.apply(s,id,single,action,value,extra)
    local ok,message
    local actual=function(t)return single and t or Session.viewId(t,id)end
    if action=="attack"and finite(value)and value>=.01 and value<=1 and (extra==nil or validTile(s,extra)and Terrain.isLand(s.sim.terrain[extra+1])and not Terrain.isImpassable(s.sim.terrain[extra+1]))then ok,message=s:attack(id,extra and s.sim:owner(extra)or 0,value,extra)
    elseif action=="transport"and finite(value)and value>=.01 and value<=1 and validTile(s,extra)then ok,message=s.unitSystem.naval:transport(id,extra,s.sim.players[id].troops*value)
    elseif action=="cancelTransport"and finite(value)and value%1==0 then ok,message=s.unitSystem.naval:retreat(id,value)
    elseif action=="moveWarship"and finite(value)and value%1==0 and validTile(s,extra)then ok,message=s.unitSystem.naval:move(id,value,extra)
    elseif action=="moveWarships"and type(value)=="table"and #value>=1 and #value<=200 and validTile(s,extra)then
        local moved=0;for _,unitId in ipairs(Guards.uniqueIds(value))do if finite(unitId)and unitId%1==0 and s.unitSystem.naval:move(id,unitId,extra)then moved+=1 end end
        ok=moved>0;message=ok and string.format("군함 %d척의 순찰 구역을 옮겨요.",moved)or "이동할 수 있는 군함이 없어요."
    elseif action=="retaliate"and finite(value)and value>=.01 and value<=1 then ok,message=s:retaliate(id,value)
    elseif action=="alliance"and finite(extra)and extra%1==0 and type(value)=="string"then
        local target=actual(extra);local q=s.sim.players[target]
        if q and s.sim.players[id].team and q.team==s.sim.players[id].team then ok=false;message="같은 팀은 동맹을 해제할 수 없어요."else ok,message=s:allianceCommand(id,target,value)end
    elseif action=="support"and type(value)=="string"then
        local target=type(extra)=='table'and extra.target or extra
        local amount=type(extra)=='table'and extra.amount or nil
        if finite(target)and target%1==0 and (amount==nil or finite(amount)and amount%1==0 and amount>=1 and amount<=9007199254740991)then ok,message=s:supportCommand(id,actual(target),value,amount)
        else ok=false;message='지원량과 대상을 확인하세요.'end
    elseif action=="embargoAll" and type(value)=="boolean" then ok,message=s.diplomacyEconomy:embargoAll(id,value)
    elseif action=="cancelAttack"and finite(value)then ok=s.sim:cancelAttack(id,value)
    elseif action=="comms" and type(value)=="string" and type(extra)=="table" and finite(extra.target) and extra.target%1==0 then
        ok=false;message='메시지는 Roblox 채팅으로 보내 주세요.'
    elseif action=='nuclear'and type(value)=='string'and table.find({'AtomBomb','HydrogenBomb','MIRV'},value)and type(extra)=='table'and validTile(s,extra.tile)and finite(extra.silo)and type(extra.up)=='boolean'and type(extra.relationStamp)=='string'and #extra.relationStamp<=1000 then
        local amount=finite(extra.amount)and extra.amount%1==0 and extra.amount or 1
        ok,message=s.unitSystem.nuclear:launchMany(id,value,extra.tile,{silo=extra.silo,up=extra.up,relationStamp=extra.relationStamp},amount)
    elseif action=="build"and type(value)=="string"and validTile(s,extra)then if single then ok,message=s:build(value,extra)else ok,message=s:buildFor(id,value,extra)end
    elseif action=="upgrade"and finite(value)then local amount=extra=="max"and 50 or finite(extra)and extra%1==0 and math.clamp(extra,1,50)or 1;if single then ok,message=s:upgrade(value,amount)else ok,message=s:upgradeFor(id,value,amount)end
    elseif action=="delete"and finite(value)then if single then ok,message=s:deleteUnit(value)else ok,message=s:deleteFor(id,value)end
    else ok=false;message="사용할 수 없는 명령이에요."end
    return ok,message
end
function M.replay(s,entry)
    local a,f=entry.a,entry.f
    if a=="spawn"then return s:spawnHuman(f,entry.v)
    elseif a=='spawnRecovery'then return (if script then require(script.Parent.SpawnRecovery)else require('./SpawnRecovery')).land(s,f,entry.v)~=nil
    elseif a=="start"then s:startBattle();return true
    elseif a=="forfeit"then s:forfeit(f);return true
    elseif a=="disconnect"then return s:markDisconnected(f,true)
    elseif a=="reconnect"then return s:markDisconnected(f,false)
    elseif a=="spawnTick"then s:spawnStep();return true
    elseif a=="comms"then local v=entry.v or {};return s.unitSystem.comms:command(f,v[1],v[2],v[3])
    end
    local p=s.sim.players[f]
    if s.phase~="playing"or not p or p.tiles.size==0 or s.resources[f].forfeited then return false end
    return M.apply(s,f,false,a,entry.v,entry.x)
end
return M
