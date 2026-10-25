-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Pinned Config and WinCheckExecution FFA rules.
local M={}
function M.lastCommander(settings,tick,players)
    if not settings.lastCommanderWins or tick<=0 or tick%10~=0 then return nil end
    local survivor
    for _,p in ipairs(players)do
        if p.kind~='BOT' and p.tiles.size>0 then
            if survivor then return nil end
            survivor=p.id
        end
    end
    return survivor,survivor and 'lastCommander' or nil
end
function M.threshold(settings,elapsed)
    local overtime=settings.overtime
    if not overtime or not overtime.enabled then return 80 end
    local past=math.floor(elapsed)-(overtime.startMinutes or 30)*60
    if past<=0 then return 80 end
    return math.max(0,80-math.floor(past*2/60))
end
function M.hasWon(settings,elapsed,owned,land,fallout)
    if settings.maxTimerValue~=nil and elapsed>=settings.maxTimerValue*60 then return true,"timer" end
    if elapsed>=170*60 then return true,"hardLimit" end
    if owned*100>(land-(fallout or 0))*M.threshold(settings,elapsed) then return true,"territory" end
    return false
end
function M.goal(settings,players)
    local n=settings.goalConquer;if not n then return nil end
    for _,p in ipairs(players)do if p.kind~='BOT'and p.tiles.size>0 and(p.countriesConquered or 0)>=n then return p.id,'goal'end end
    return nil
end
function M.ffa(settings,tick,players,land,fallout)
    if tick%10~=0 then return nil end
    local goal,why=M.goal(settings,players)
    if goal then return goal,why end
    if settings.goalConquer and settings.maxTimerValue and tick/10>=settings.maxTimerValue*60 then
        for _,p in ipairs(players)do if p.kind~='BOT'and p.tiles.size>0 then return p.id,'timer'end end
    end
    local survivor,reason=M.lastCommander(settings,tick,players)
    if survivor then return survivor,reason end
    local leader=nil
    for _,p in ipairs(players) do if p.tiles.size>0 and (not leader or p.tiles.size>leader.tiles.size) then leader=p end end
    if not leader then return nil end
    local won,reason=M.hasWon(settings,tick/10,leader.tiles.size,land,fallout)
    if won then return leader.id,reason end
    return nil
end
return M
