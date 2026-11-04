local GameSpeed=if script then require(script.Parent.GameSpeed)else require('./GameSpeed')
local M={}
M.floor=.10
M.minSeconds=32
M.message='병력 바닥'
function M.applies(campaign)
    return type(campaign)=='string'and campaign:match('^1%-%d$')~=nil and campaign~='1-1'
end
function M.check(s,id,campaign,action,memo)
    if action~='attack'or not M.applies(campaign)or type(memo)~='table'or memo.lowGuarded then return nil end
    local p=s and s.sim and s.sim.players and s.sim.players[id];if not p or type(s.maxTroops)~='function'then return nil end
    local ticks=tonumber(s.sim.ticks)or 0;memo.firstTick=memo.firstTick or ticks
    if not memo.sent or GameSpeed.seconds(s.settings,ticks-memo.firstTick)<M.minSeconds then return nil end
    local ok,cap=pcall(s.maxTroops,s,id);if not ok then return nil end;if type(cap)~='number'or cap<=0 then return nil end
    if (tonumber(p.troops)or 0)/cap<M.floor then memo.lowGuarded=true;return false,M.message end
    return nil
end
function M.note(memo,action,ok)
    if ok and action=='attack'and type(memo)=='table'then memo.sent=true end
end
return M
