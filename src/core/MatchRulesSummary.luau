local M={}
local units=(if script then require(script.Parent.UnitRules)else require('./UnitRules')).names
local function short(n)
    if n>=1e6 then return string.format('%g',math.floor(n/1e5)/10)..'M'end
    if n>=1e3 then return string.format('%g',math.floor(n/100)/10)..'K'end
    return tostring(n)
end
function M.lines(s)
    s=s or {};local out={}
    local function add(t)table.insert(out,t)end
    if s.infiniteGold then add('무한 골드')end
    if s.infiniteTroops then add('무한 병력')end
    if s.instantBuild then add('즉시 건설')end
    if (tonumber(s.startingGold)or 0)>0 then add('시작 골드 '..short(tonumber(s.startingGold)))end
    local mult=tonumber(s.goldMultiplier)or 1;if mult~=1 then add(string.format('골드 생산 ×%g',mult))end
    if s.disableAlliances or s.customAllianceDuration==0 then add('동맹 없음')end
    if s.disableNPCs or s.nations=='disabled'then add('국가 AI 없음')end
    if s.waterNukes then add('물 핵')end
    if s.doomsdayClock then add('종말 시계')end
    if (tonumber(s.spawnImmunityDuration)or 0)>=2400 then add(string.format('평화 %d분',math.floor(tonumber(s.spawnImmunityDuration)/600)))end
    if s.disabledUnits and #s.disabledUnits>0 then
        local names={};for _,k in ipairs(s.disabledUnits)do table.insert(names,units[k]or k)end
        add('사용 불가: '..table.concat(names,', '))
    end
    return out
end
function M.draw(label,settings,y,muted)
    local lines=M.lines(settings)
    label('RulesTitle','이번 판 규칙',y+4,28,nil,16)
    label('Rules',#lines>0 and table.concat(lines,'\n')or '클래식 규칙',y+34,math.max(1,#lines)*22+4,muted,14)
    return math.max(1,#lines)*22+46
end
return M
