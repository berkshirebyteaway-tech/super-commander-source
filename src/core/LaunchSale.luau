local Ops=if script then require(script.Parent.OpsRules)else require('./OpsRules')
local M={}
M.percent=80
M.defaultEnd='2026-11-07 00:00Z'
M.prices={basic=6,epic=30,legendary=100,mythic=300,permanent=200}
function M.endsAt(raw)return Ops.parseTime(raw)or Ops.parseTime(M.defaultEnd)end
function M.active(on,endsAt,now)return on~=false and type(endsAt)=='number'and type(now)=='number'and now<endsAt end
function M.saleId(map,key)
    local v=type(map)=='table'and map[key]
    if type(v)=='number'and v>0 and v<2^53 and v%1==0 then return v end
    return nil
end
function M.left(seconds,en)
    seconds=math.max(0,math.floor(seconds or 0))
    local d,h,m,s=seconds//86400,seconds%86400//3600,seconds%3600//60,seconds%60
    if d>0 then return string.format(en and '%dd %dh'or '%d일 %d시간',d,h)end
    if h>0 then return string.format(en and '%dh %dm'or '%d시간 %d분',h,m)end
    return string.format('%d:%02d',m,s)
end
function M.title(en)return en and 'Launch sale 80% off'or '출시 기념 80% 세일 중'end
function M.line(endsAt,now,en)
    if not M.active(true,endsAt,now)then return nil end
    return string.format(en and '%s  %s left'or '%s  %s 남음',M.title(en),M.left(endsAt-now,en))
end
return M
