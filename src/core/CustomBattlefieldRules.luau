local Copy=if script then require(script.Parent.BattlefieldRules)else require('./BattlefieldRules')
local Format=if script then require(script.Parent.TeamFormat)else require('./TeamFormat')
local TeamLobby=if script then require(script.Parent.TeamLobby)else require('./TeamLobby')
local Units=if script then require(script.Parent.UnitRules)else require('./UnitRules')
local Options=if script then require(script.Parent.MatchOptions)else require('./MatchOptions')
local Catalog=if script then require(script.Parent.Parent.Maps.Catalog)else require('../maps/Catalog')
local M={version=1,maxRooms=8,waitSeconds=5}
local maps={};for _,m in ipairs(Catalog)do table.insert(maps,m.key)end
local normalMaps={};for _,m in ipairs(Catalog)do if m.normal then normalMaps[m.key]=true end end
M.teamFormats={'Duos','Trios','Quads',Format.humansVsNations}
local function integer(v,lo,hi)return type(v)=='number'and v==v and v%1==0 and v>=lo and v<=hi end
local function enum(v,values)return table.find(values,v)~=nil end
function M.default(map,mode)
    mode=mode or 'coop'
    return {version=1,map=map or 'world',mode=mode or 'coop',maximum=mode=='coop'and 5 or 10,minimum=(mode=='coop'or mode=='ffa')and 1 or 2,teamCount=2,spawn='select',visibility='invite',aiPerHuman=2,settings={difficulty='Medium',nations='default',bots=120,startingGold=0,goldMultiplier=1,customAllianceDuration=5,maxTimerValue=15}}
end
function M.normalize(raw)
    if type(raw)~='table'or not enum(raw.mode,{'ffa','teams','coop'})or not enum(raw.map,maps)then return nil,'rules'end
    if not integer(raw.maximum,raw.mode=='teams'and 2 or 1,raw.mode=='coop'and 5 or 20)or not enum(raw.spawn,{'random','select'})or not enum(raw.visibility,{'public','invite'})then return nil,'rules'end
    if not integer(raw.teamCount or 2,2,math.min(10,math.max(2,raw.maximum)))or not integer(raw.aiPerHuman or 2,1,4)then return nil,'teams'end
    if raw.teamFormat~=nil and (raw.mode~='teams'or not enum(raw.teamFormat,M.teamFormats))then return nil,'teams'end
    if raw.modifiers~=nil then if type(raw.modifiers)~='table'or #raw.modifiers>3 then return nil,'rules'end;for _,k in ipairs(raw.modifiers)do if not Copy.modifierLabels[k]then return nil,'rules'end end end
    local r=M.default(raw.map,raw.mode);r.maximum=raw.maximum;r.teamCount=raw.teamCount or 2;r.teamFormat=raw.teamFormat;r.modifiers=raw.modifiers and table.clone(raw.modifiers)or nil;r.spawn=raw.spawn;r.visibility=raw.visibility;r.aiPerHuman=raw.aiPerHuman or 2
    if raw.teamAssignment~=nil and not enum(raw.teamAssignment,{'auto','select'})then return nil,'teams'end
    r.teamAssignment=raw.teamAssignment
    if raw.aiCount~=nil then
        if raw.mode~='coop'or not integer(raw.aiCount,1,400)then return nil,'rules'end
        r.aiCount=raw.aiCount
    end
    local input=raw.settings or {};if type(input)~='table'then return nil,'settings'end
    local s=r.settings
    for key,value in pairs(input)do
        if key=='difficulty'and enum(value,Options.difficultyKeys)then s[key]=value
        elseif key=='nations'and Options.validNations(value)then s[key]=value
        elseif key=='doomsdayClockSpeed'and enum(value,{'slow','normal','fast','veryfast'})then s[key]=value
        elseif key=='bots'and integer(value,0,400)then s[key]=value
        elseif key=='startingGold'and integer(value,0,1e9)then s[key]=value
        elseif key=='goldMultiplier'and type(value)=='number'and value==value and value>=.1 and value<=1000 then s[key]=value
        elseif key=='maxTimerValue'and integer(value,0,120)then s[key]=value
        elseif key=='customAllianceDuration'and integer(value,0,15)then s[key]=value
        elseif key=='overtime'and type(value)=='table'and type(value.enabled)=='boolean'and integer(value.startMinutes,1,120)then s[key]={enabled=value.enabled,startMinutes=value.startMinutes}
        elseif enum(key,{'infiniteGold','infiniteTroops','instantBuild','waterNukes','disableNukes','disableAlliances','doomsdayClock','donateGold','donateTroops'})and type(value)=='boolean'then s[key]=value
        elseif key=='spawnImmunityDuration'and integer(value,0,6000)then s[key]=value
        elseif key=='mapSize'and (value=='normal'or value=='compact')then if value=='normal'and normalMaps[raw.map]then s[key]=value end
        elseif key=='disabledUnits'and type(value)=='table'and #value<=#Units.toggleable then
            local list={};for _,kind in ipairs(value)do if not enum(kind,Units.toggleable)or table.find(list,kind)then return nil,'settings'end;table.insert(list,kind)end
            s[key]=list
        else return nil,'settings'end
    end
    return r
end
function M.rollSpecial(r,rng)
    local meta;for _,m in ipairs(Catalog)do if m.key==r.map then meta=m end end;if not meta then return nil end
    local roll=function(n)return rng:NextInteger(0,n-1)end;local chance=function()return rng:NextNumber()end
    local mode=r.mode=='teams'and 'teams'or 'ffa'
    local mods=Copy.rollModifiers(meta,mode,mode=='teams'and (r.teamFormat or r.teamCount)or nil,roll,chance)
    local s=r.settings
    r.spawn='select';s.startingGold=0;s.goldMultiplier=1;s.disableAlliances=nil;s.disabledUnits=nil;s.spawnImmunityDuration=nil;s.waterNukes=nil;s.doomsdayClock=nil;s.doomsdayClockSpeed=nil
    if s.difficulty=='Hard'and r.rolledHard then s.difficulty='Medium'end;r.rolledHard=nil
    if mods.isRandomSpawn then r.spawn='random'end
    if mods.isCrowded and r.mode~='coop'then r.maximum=20 end
    if mods.isHardNations and s.difficulty~='Impossible'then s.difficulty='Hard';r.rolledHard=true end
    s.startingGold=mods.startingGold25M and 25000000 or mods.startingGold5M and 5000000 or mods.startingGold1M and 1000000 or 0
    if mods.goldMultiplier then s.goldMultiplier=2 end
    if mods.isAlliancesDisabled then s.disableAlliances=true end
    if mods.isNukesDisabled then s.disabledUnits={'MissileSilo','AtomBomb','HydrogenBomb','MIRV','SAMLauncher'}elseif mods.isSAMsDisabled then s.disabledUnits={'SAMLauncher'}end
    if mods.isPeaceTime then s.spawnImmunityDuration=2400 end
    if mods.isWaterNukes then s.waterNukes=true end
    if mods.isDoomsdayClock then s.doomsdayClock=true;s.doomsdayClockSpeed=Copy.doomsdaySpeeds[roll(#Copy.doomsdaySpeeds)+1]end
    r.modifiers={};for _,k in ipairs(Copy.modifierPool)do if mods[k]and not table.find(r.modifiers,k)then table.insert(r.modifiers,k)end end
    return r.modifiers
end
function M.valid(r)return type(r)=='table'and r.version==M.version and r.minimum==(r.mode=='teams'and 2 or 1)and M.normalize(r)~=nil end
function M.rewardMode(r,humans)
    local s=r.settings
    for _,key in ipairs({'infiniteGold','infiniteTroops','instantBuild','waterNukes','disableNukes','disableAlliances','doomsdayClock'})do if s[key]then return 'custom'end end
    if s.startingGold~=0 or s.goldMultiplier~=1 or s.bots~=120 or s.customAllianceDuration~=5 or s.overtime and s.overtime.enabled then return 'custom'end
    if s.disabledUnits and #s.disabledUnits>0 or s.spawnImmunityDuration and s.spawnImmunityDuration~=50 then return 'custom'end
    if humans and humans<2 then return 'single'end
    return r.mode=='coop'and 'coop'or 'pvp'
end
function M.selection(r,users,_,assigned)
    assert(M.valid(r)and #users>=r.minimum and #users<=r.maximum,'Invalid custom departure')
    local sorted=table.clone(users);table.sort(sorted);local teams={}
    local size=r.teamFormat and Format.fixedSize(r.teamFormat)
    for i,id in ipairs(sorted)do
        if r.mode=='coop'or r.teamFormat==Format.humansVsNations then teams[id]=1
        elseif size then teams[id]=(i-1)//size+1
        elseif r.mode=='teams'then teams[id]=(i-1)%math.min(r.teamCount,#users)+1 end
    end
    if r.mode=='teams'and (r.teamAssignment=='select'or assigned)then
        if assigned then for _,id in ipairs(sorted)do local t=assigned[tostring(id)]or assigned[id];assert(integer(t,1,r.maximum),'Invalid reserved team');teams[id]=t end
        else local members={};for _,id in ipairs(sorted)do table.insert(members,{userId=id})end;teams=assert(TeamLobby.plan(r,members)).teams end
    end
    local settings=Copy.copy(r.settings)
    if r.mode=='teams'then
        settings.teamFormat=r.teamFormat or r.teamCount
        if r.teamFormat==Format.humansVsNations then settings.humansVsNations=true elseif not size then settings.teamCount=r.teamCount end
    end
    if r.teamAssignment=='select'and size then local high=0;for _,t in pairs(teams)do high=math.max(high,t)end;settings.minimumTeamCount=high end
    if r.mode=='coop'then settings.nations=r.aiCount or #users*r.aiPerHuman end
    if settings.maxTimerValue==0 then settings.maxTimerValue=nil end
    return {users=sorted,teams=teams,mode=r.mode,queueMode='custom',map=r.map,spawn=r.spawn,settings=settings,customRules=Copy.copy(r),custom=true,rewardMode=M.rewardMode(r,#sorted)}
end
return M
