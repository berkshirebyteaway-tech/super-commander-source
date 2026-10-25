local M={}
M.steps={20,20,30,30,50}
local function day(t)return math.floor((t or 0)/86400)end
function M.state(p,today)
    local s=type(p.dailySupply)=='table'and p.dailySupply or nil
    if not s or s.day~=today then return {day=today,n=0}end
    return {day=today,n=math.clamp(math.floor(tonumber(s.n)or 0),0,#M.steps)}
end
function M.apply(p,event,receipt)
    if event.official~=true or receipt.supply then return nil end
    if not((event.outcome=='won'or event.outcome=='lost')and (event.seconds or 0)>=120)then return nil end
    local today=day(event.time)
    local saved=type(p.dailySupply)=='table'and tonumber(p.dailySupply.day)or -1
    if today<saved then return nil end
    local s=M.state(p,today)
    if s.n>=#M.steps then return nil end
    s.n+=1;p.dailySupply=s
    local coins=M.steps[s.n];p.medals+=coins;receipt.supply=s.n
    return s.n,coins
end
function M.view(p,now)
    local today=day(now);local s=M.state(p,today)
    return {n=s.n,steps=table.clone(M.steps),resetIn=(today+1)*86400-now}
end
return M
