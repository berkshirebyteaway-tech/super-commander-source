-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. The original single-player and private-lobby options
local Rows=require(script.Parent.SettingsRows)
local pack=game.ReplicatedStorage.FrontierNative
local Options=require(pack.Core.MatchOptions)
local Units=require(pack.Core.UnitRules)
local Maps=require(pack.Maps.MapLoader)
local M={}
M.speeds={{'slow','느림'},{'normal','보통'},{'fast','빠름'},{'veryfast','아주 빠름'}}
local function nationsStep(v,d)
    local steps=Options.nationSteps;local i=table.find(steps,v)
    if not i then local n=Options.nextNations(v);i=table.find(steps,n)or 1;if d<0 then i-=1 end;return steps[(i-1)%#steps+1]end
    return steps[(i-1+d)%#steps+1]
end
function M.draw(p,w,y,ctx,sections)
    local s,set=ctx.s,ctx.set
    local function toggle(key,title,on)y=Rows.toggle(p,key,title,on,y,w,function(v)set(key,v)end)end
    for _,section in ipairs(sections)do
        if section=='opponents'then
            y=Rows.heading(p,'상대',y,w)
            y=Rows.choice(p,'Difficulty','AI 국가 난이도',Options.difficulties,s.difficulty or 'Medium',y,w,function(v)set('difficulty',v)end)
            if not ctx.coop then y=Rows.stepper(p,'Nations','AI 국가 수',Options.nationsLabel(s.nations or 'default'),y,w,function(d)set('nations',nationsStep(s.nations or 'default',d))end)end
            y=Rows.numeric(p,'bots','중립 세력 수 / 0 ~ 400',s.bots or 0,y,w,0,400,function(n)set('bots',math.floor(n))end)
        elseif section=='economy'then
            y=Rows.heading(p,'경제',y+8,w)
            y=Rows.numeric(p,'startingGold','시작 골드',s.startingGold or 0,y,w,0,1e9,function(n)set('startingGold',math.floor(n))end)
            y=Rows.numeric(p,'goldMultiplier','골드 생산 배율',s.goldMultiplier or 1,y,w,.1,1000,function(n)set('goldMultiplier',n)end)
            toggle('infiniteGold','무한 골드',s.infiniteGold==true)
            toggle('infiniteTroops','무한 병력',s.infiniteTroops==true)
            toggle('instantBuild','즉시 건설',s.instantBuild==true)
        elseif section=='combat'then
            y=Rows.heading(p,'전투 규칙',y+8,w)
            if ctx.spawn then toggle('randomSpawn','랜덤 스폰',ctx.randomSpawn==true)end
            y=Rows.numeric(p,'spawnImmunityMinutes','평화 시간 / 분, 0은 기본 5초',math.floor((s.spawnImmunityDuration or 0)/600),y,w,0,10,function(n)set('spawnImmunityMinutes',math.floor(n))end)
            toggle('disableAlliances','동맹 끄기',s.disableAlliances==true)
            if not s.disableAlliances then y=Rows.numeric(p,'customAllianceDuration','동맹 유지 / 분',s.customAllianceDuration or 5,y,w,0,15,function(n)set('customAllianceDuration',math.floor(n))end)end
            toggle('disableNukes','핵무기 끄기',s.disableNukes==true)
            if not s.disableNukes then toggle('waterNukes','물로 변하는 폭발',s.waterNukes==true)end
        elseif section=='time'then
            y=Rows.heading(p,'경기 시간',y+8,w)
            y=Rows.numeric(p,'maxTimerValue','시간 제한 / 분, 0은 제한 없음',s.maxTimerValue or 0,y,w,0,120,function(n)set('maxTimerValue',math.floor(n))end)
            local overtime=s.overtime or {}
            toggle('overtimeEnabled','연장전',overtime.enabled==true)
            if overtime.enabled then y=Rows.numeric(p,'overtimeStartMinutes','연장전 시작 / 분',overtime.startMinutes or 30,y,w,1,120,function(n)set('overtimeStartMinutes',math.floor(n))end)end
            toggle('doomsdayClock','장기전 소모전',s.doomsdayClock==true)
            if s.doomsdayClock then y=Rows.choice(p,'DoomSpeed','소모전 속도',M.speeds,s.doomsdayClockSpeed or 'normal',y,w,function(v)set('doomsdayClockSpeed',v)end)end
        elseif section=='map'then
            if ctx.map and Maps.hasNormal(ctx.map)then
                y=Rows.heading(p,'지도',y+8,w)
                y=Rows.toggle(p,'mapSize','큰 지도 / 땅 4배',s.mapSize=='normal',y,w,function(on)set('mapSize',on and 'normal'or 'compact')end)
            end
        elseif section=='teams'then
            if ctx.teams then
                y=Rows.heading(p,'팀 지원',y+8,w)
                toggle('donateGold','골드 지원',s.donateGold~=false)
                toggle('donateTroops','병력 지원',s.donateTroops~=false)
            end
        elseif section=='units'then
            y=Rows.heading(p,'사용할 유닛',y+8,w)
            for _,kind in ipairs(Units.toggleable)do
                local off=s.disabledUnits and table.find(s.disabledUnits,kind)~=nil
                y=Rows.toggle(p,'Unit'..kind,Units.names[kind],not off,y,w,function()
                    local list=table.clone(s.disabledUnits or {});local at=table.find(list,kind);if at then table.remove(list,at)else table.insert(list,kind)end
                    set('disabledUnits',list)
                end)
            end
        end
    end
    return y
end
function M.applyCustom(r,key,value)
    local s=r.settings
    if key=='overtimeEnabled'then s.overtime={enabled=value,startMinutes=s.overtime and s.overtime.startMinutes or 30}
    elseif key=='overtimeStartMinutes'then s.overtime={enabled=s.overtime and s.overtime.enabled or false,startMinutes=value}
    elseif key=='spawnImmunityMinutes'then s.spawnImmunityDuration=value>=1 and value*600 or nil
    elseif key=='randomSpawn'then r.spawn=value and 'random'or 'select'
    elseif key=='mapSize'then s.mapSize=value=='normal'and 'normal'or nil
    elseif key=='disabledUnits'then s.disabledUnits=#value>0 and value or nil
    elseif key=='donateTroops'then s.donateTroops=value==false and false or nil
    else s[key]=value end
end
return M
