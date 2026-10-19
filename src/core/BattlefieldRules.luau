-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors, pinned e02eeba. Official fields: public lobby rules from
local Formation=if script then require(script.Parent.PartyFormation)else require('./PartyFormation')
local Format=if script then require(script.Parent.TeamFormat)else require('./TeamFormat')
local Catalog=if script then require(script.Parent.Parent.Maps.Catalog)else require('../maps/Catalog')
local M={version=1,emptySeconds=60,waitSeconds=60,fillSeconds=45,fullSeconds=5,leaseSeconds=35,maxTickets=80,maxMatches=8}
M.fillTarget={[10]=10,[20]=20}
M.rookieGames=3
M.slots={{kind='ffa'},{kind='teams'},{kind='special'},{kind='ffa'},{kind='teams'},{kind='special'},{kind='ffa'},{kind='teams'}}
M.recruitment={minimum=4,medium=6,maximum=8,mediumAt=16,largeAt=32,warmSeconds=60,presetSlots={1,2,3,4,5,7,8,1}}
M.seatCap=20
M.maxTimerValue=nil
M.overtimeMinutes=30
M.recent=5
function M.copy(v)
    if type(v)~='table'then return v end
    local out={};for k,x in pairs(v)do out[k]=M.copy(x)end;return out
end
local byKey={};for _,m in ipairs(Catalog)do byKey[m.key]=m end
local function format(r)return r.teamFormat or 2 end
local function countOf(r)return r.teamCount or 2 end
local function packed(r)return Format.fixedSize(format(r))~=nil end
local function hvn(r)return r.mode=='teams'and format(r)==Format.humansVsNations end
local function weight(m,kind,mode)
    local mp=m.multiplayerFrequency or m.rotationWeight or 0
    if kind=='ffa'then return (m.ffaFrequency or -1)>=0 and m.ffaFrequency or mp end
    if kind=='teams'then return (m.teamFrequency or -1)>=0 and m.teamFrequency or mp end
    if (m.specialFrequency or -1)>=0 then return m.specialFrequency end
    if mode=='teams'then return (m.teamFrequency or -1)>0 and m.teamFrequency or mp end
    return (m.ffaFrequency or -1)>0 and m.ffaFrequency or mp
end
local function round5(n)return math.floor(n/5+.5)*5 end
function M.playerCounts(meta)
    local base=math.max(round5((meta.normalLandTiles or meta.landTiles*4)/1e6*50),5)
    return base,round5(base*.75),round5(base*.5)
end
function M.lobbySeats(meta,mode,roll)
    local l,m,small=M.playerCounts(meta);local base=roll<.3 and l or roll<.6 and m or small
    local p=math.min(mode=='teams'and math.ceil(base*1.5)or base,l)
    return math.min(M.seatCap,math.max(3,math.floor(p*.25)))
end
function M.teamSeats(f,meta,seats)
    local need=4
    if type(f)=='number'and (meta.teamCount or 0)>=2 and f==meta.teamCount then need=math.max(need,f*2)end
    return math.min(M.seatCap,math.max(seats,need))
end
M.modifierPool={}
for _,e in ipairs({{'isRandomSpawn',4},{'isCrowded',2},{'isHardNations',1},{'startingGold1M',2},{'startingGold5M',4},{'startingGold25M',3},{'goldMultiplier',6},{'isAlliancesDisabled',1},{'isNukesDisabled',1},{'isSAMsDisabled',1},{'isPeaceTime',1},{'isWaterNukes',4},{'isDoomsdayClock',4}})do
    for _=1,e[2]do table.insert(M.modifierPool,e[1])end
end
M.exclusive={{'startingGold5M','startingGold25M'},{'startingGold5M','startingGold1M'},{'startingGold25M','startingGold1M'},{'isHardNations','startingGold25M'},{'isNukesDisabled','isSAMsDisabled'},{'isNukesDisabled','isWaterNukes'}}
M.modifierCounts={1,1,1,2,2,2,2,2,3,3}
M.modifierLabels={isRandomSpawn='랜덤 스폰',isCrowded='만원 전장',isHardNations='어려운 국가',startingGold1M='시작 골드 100만',startingGold5M='시작 골드 500만',startingGold25M='시작 골드 2500만',goldMultiplier='골드 2배',isAlliancesDisabled='동맹 없음',isNukesDisabled='핵 없음',isSAMsDisabled='방공 없음',isPeaceTime='평화 4분',isWaterNukes='물 핵',isDoomsdayClock='종말 시계'}
M.doomsdaySpeeds={'slow','normal','fast','veryfast'}
local known={};for _,k in ipairs(M.modifierPool)do known[k]=true end
local function blocked(key,set)
    for _,pair in ipairs(M.exclusive)do if key==pair[1]and set[pair[2]]or key==pair[2]and set[pair[1]]then return true end end
    return false
end
function M.rollModifiers(meta,mode,f,roll,chance)
    local mods={}
    local excluded={}
    if f=='Duos'or f=='Trios'or f=='Quads'then excluded.isRandomSpawn=true end
    if meta.key=='fourislands'and mode=='teams'then excluded.goldMultiplier=true end
    if mode=='teams'then excluded.isHardNations=true end
    if mode=='teams'and meta.teamCount~=0 then excluded.isNukesDisabled=true end
    if f==Format.humansVsNations then excluded.startingGold25M=true;excluded.isPeaceTime=true end
    for _,k in ipairs(meta.disabledModifiers or {})do excluded[k]=true end
    local forced=0
    for _,entry in ipairs(meta.forcedModifiers or {})do
        local key,pct=string.match(entry,'^([%w]+):?(%d*)$');local p=pct~=''and tonumber(pct)/100 or 1
        if key and known[key]and not excluded[key]and chance()<p and forced<3 then
            mods[key]=true;excluded[key]=true;forced+=1
            for _,pair in ipairs(M.exclusive)do if pair[1]==key then excluded[pair[2]]=true elseif pair[2]==key then excluded[pair[1]]=true end end
        end
    end
    local want=math.max(0,M.modifierCounts[roll(#M.modifierCounts)+1]-forced)
    local pool={};for _,k in ipairs(M.modifierPool)do if not excluded[k]then table.insert(pool,k)end end
    for i=#pool,2,-1 do local j=roll(i)+1;pool[i],pool[j]=pool[j],pool[i]end
    local picked=0
    for _,k in ipairs(pool)do if picked>=want then break end;if not mods[k]and not blocked(k,mods)then mods[k]=true;picked+=1 end end
    if mods.isCrowded and select(1,M.playerCounts(meta))>60 then mods.isCrowded=nil end
    if next(mods)==nil then local k=pool[1]or 'isRandomSpawn';if k=='isCrowded'then k=pool[2]or 'isRandomSpawn'end;mods[k]=true end
    return mods
end
function M.valid(r)
    if type(r)~='table'or (r.mode~='ffa'and r.mode~='teams')or r.version~=M.version or r.minimum~=2 or (r.spawn~='random'and r.spawn~='select')then return false end
    if type(r.maximum)~='number'or r.maximum%1~=0 or r.maximum<2 or r.maximum>M.seatCap then return false end
    if r.mode=='teams'then
        local f=format(r);if not Format.valid(f)or type(r.teamCount)~='number'then return false end
        if f==Format.humansVsNations then if r.teamCount~=2 then return false end
        elseif Format.fixedSize(f)then if r.maximum%Format.fixedSize(f)~=0 or r.teamCount~=r.maximum//Format.fixedSize(f)then return false end
        elseif r.teamCount~=f or r.maximum%f~=0 then return false end
    end
    if r.modifiers~=nil then
        if type(r.modifiers)~='table'then return false end
        for _,k in ipairs(r.modifiers)do if not known[k]then return false end end
    end
    return byKey[r.map]~=nil
end
function M.next(s,slot,presetSlot)
    local preset=M.slots[presetSlot or slot];assert(preset,'Unknown official slot')
    local function roll(n)s.seed=(s.seed*48271)%2147483647;return s.seed%n end
    local function chance()return roll(1000000)/1000000 end
    local kind=preset.kind or preset.mode
    local mode=kind=='special'and (chance()<.5 and 'ffa'or 'teams')or kind
    local banned={}
    for i=math.max(1,#s.history-M.recent+1),#s.history do banned[s.history[i]]=true end
    for _,f in ipairs(s.fields or {})do banned[f.rules.map]=true end
    local candidates,total={},0
    for _,m in ipairs(Catalog)do local w=weight(m,kind,mode);if w>0 and not banned[m.key]then total+=w;table.insert(candidates,{m,w})end end
    if #candidates==0 then
        local current=s.fields and s.fields[slot]
        for _,m in ipairs(Catalog)do local w=weight(m,kind,mode);if w>0 and (not current or current.rules.map~=m.key)then total+=w;table.insert(candidates,{m,w})end end
    end
    local pick=roll(total);local meta=candidates[1][1]
    for _,c in ipairs(candidates)do if pick<c[2]then meta=c[1];break end;pick-=c[2]end
    local f=mode=='teams'and Format.roll(chance(),chance(),meta.teamCount~=0 and meta.teamCount or nil)or nil
    local mods=kind=='special'and M.rollModifiers(meta,mode,f,roll,chance)or {}
    local seats=mods.isCrowded and M.seatCap or M.lobbySeats(meta,mode,chance())
    local teams,maximum=nil,seats
    if f then f,teams,maximum=Format.resolve(f,M.teamSeats(f,meta,seats))end
    local gold=mods.startingGold25M and 25000000 or mods.startingGold5M and 5000000 or mods.startingGold1M and 1000000 or 0
    local nationCount=#meta.nations>0 and math.max(1,math.floor(#meta.nations*.25))or 0
    local settings={difficulty=(mods.isHardNations or f==Format.humansVsNations)and 'Hard'or 'Medium',
        nations=(mode=='teams'or gold>=25000000 or nationCount==0)and 'disabled'or nationCount,bots=100,startingGold=gold,goldMultiplier=mods.goldMultiplier and 2 or 1,
        customAllianceDuration=5,maxTimerValue=M.maxTimerValue,donateGold=mode=='teams',donateTroops=mode=='teams',
        spawnImmunityDuration=mods.isPeaceTime and 2400 or (f~=Format.humansVsNations and gold>=25000000 and 1500)or (f~=Format.humansVsNations and gold>=5000000 and 450)or 50}
    if mode=='ffa'and kind~='special'then settings.overtime={enabled=true,startMinutes=M.overtimeMinutes}end
    if mods.isAlliancesDisabled then settings.disableAlliances=true end
    if mods.isWaterNukes then settings.waterNukes=true end
    if mods.isDoomsdayClock then settings.doomsdayClock=true;settings.doomsdayClockSpeed=M.doomsdaySpeeds[roll(#M.doomsdaySpeeds)+1]end
    if mods.isNukesDisabled then settings.disabledUnits={'MissileSilo','AtomBomb','HydrogenBomb','MIRV','SAMLauncher'}
    elseif mods.isSAMsDisabled then settings.disabledUnits={'SAMLauncher'}end
    local r={version=M.version,map=meta.key,mode=mode,minimum=2,maximum=maximum,spawn=mods.isRandomSpawn and 'random'or 'select',settings=settings}
    if kind=='special'then r.special=true;r.modifiers={};for _,k in ipairs(M.modifierPool)do if mods[k]and not table.find(r.modifiers,k)then table.insert(r.modifiers,k)end end end
    if f then
        r.teamFormat=f;r.teamCount=teams;settings.teamFormat=f;settings.teamCount=teams
        if f==Format.humansVsNations then settings.humansVsNations=true end
    end
    return r
end
function M.canDepart(r,users,groups)
    if hvn(r)then return #users>=r.minimum and #users<=r.maximum end
    return #users>=r.minimum and #users<=r.maximum and (r.mode~='teams'or Formation.teams(users,groups,r.maximum,countOf(r),packed(r))~=nil)
end
function M.canFill(r,users,groups)
    return #users>=1 and #users<=r.maximum and (r.mode~='teams'or hvn(r)or Formation.fits(users,groups,r.maximum,countOf(r),packed(r)))
end
function M.fill(r,users,teams)
    local target=M.fillTarget[r.maximum]or r.maximum
    if r.mode~='teams'then return {ai=math.max(0,r.maximum-#users),teams=nil}end
    if hvn(r)then local list=table.create(#users,2);return {ai=#users,teams=list,hvn=true}end
    local count=countOf(r);local cap=r.maximum//count
    local counts=table.create(count,0);for _,id in ipairs(users)do local t=teams and teams[id];if t then counts[t]+=1 end end
    local high=0;for t=1,count do high=math.max(high,counts[t])end
    local list={}
    if packed(r)then
        local active=math.max(2,math.ceil(math.max(target,#users)/cap));for t=1,count do if counts[t]>0 then active=math.max(active,t)end end
        for t=1,math.min(count,active)do for _=1,cap-counts[t]do table.insert(list,t)end end
    else
        local side=math.min(cap,math.max(high,math.ceil(target/count)))
        for team=1,count do for _=1,math.max(0,side-counts[team])do table.insert(list,team)end end
    end
    return {ai=#list,teams=list}
end
function M.difficulty(_rookies)
    return 'Medium'
end
function M.canFit(r,users,groups)
    return #users<=r.maximum and (r.mode~='teams'or hvn(r)or Formation.fits(users,groups,r.maximum,countOf(r),packed(r)))
end
function M.teams(r,users,groups)
    if hvn(r)then local out={};for _,id in ipairs(users)do out[id]=1 end;return out end
    return Formation.teams(users,groups,r.maximum,countOf(r),packed(r))or Formation.split(users,groups,r.maximum,countOf(r),packed(r))
end
function M.selection(r,users,groups)
    assert(M.valid(r),'Invalid official rules');assert(#users>=1 and #users<=r.maximum,'Invalid official roster')
    local sorted=table.clone(users);table.sort(sorted);local teams={}
    if r.mode=='teams'then
        if hvn(r)then for _,id in ipairs(sorted)do teams[id]=1 end
        elseif groups and next(groups)or packed(r)then teams=assert(M.teams(r,sorted,groups),'Party roster exceeds a side')
        else local count=countOf(r);for i,id in ipairs(sorted)do teams[id]=(i-1)%count+1 end end
    end
    return {users=sorted,teams=teams,mode=r.mode,queueMode='pvp',map=r.map,spawn=r.spawn,settings=M.copy(r.settings),official=true,rulesVersion=r.version,fill=M.fill(r,sorted,teams)}
end
return M
