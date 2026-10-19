local Custom=if script then require(script.Parent.CustomBattlefieldRules)else require('./CustomBattlefieldRules')
local Flow=if script then require(script.Parent.PlayFlow)else require('./PlayFlow')
local M={entries={{id='balanced',difficulty='Medium',ratio=1},{id='outnumbered',difficulty='Hard',ratio=1.4},{id='siege',difficulty='Impossible',ratio=1}}}
function M.apply(raw,id,count)
    local r=Custom.normalize(raw);if not r or r.mode~='coop'then return nil end
    local entry;for _,e in ipairs(M.entries)do if e.id==id then entry=e end end;if not entry then return nil end
    count=math.clamp(math.floor(tonumber(count)or r.maximum),1,5)
    r.maximum=math.max(count,r.maximum);r.aiCount=math.ceil(count*entry.ratio);r.settings.difficulty=entry.difficulty
    if Flow.coopAI(r,count).cap<r.aiCount then r.map='world'end
    return r
end
return M
