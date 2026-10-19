local M={}
M.firstYear,M.firstMonth=2026,10
local function daysFromCivil(y,m,d)
    y-=m<=2 and 1 or 0
    local era=(y>=0 and y or y-399)//400
    local yoe=y-era*400
    local mp=(m+9)%12
    local doy=(153*mp+2)//5+d-1
    local doe=yoe*365+yoe//4-yoe//100+doy
    return era*146097+doe-719468
end
function M.start(n)
    local months=(M.firstMonth-1)+n
    local y=M.firstYear+months//12;local m=months%12+1
    return daysFromCivil(y,m,1)*86400
end
function M.finish(n)return M.start(n+1)end
function M.number(time)
    time=time or 0
    if time<M.start(0)then return 0 end
    local n=0
    while time>=M.start(n+1)do n+=1 end
    return n
end
function M.key(n)return 'S'..n end
function M.at(time)
    local n=M.number(time)
    return {n=n,key=M.key(n),start=M.start(n),finish=M.finish(n),preseason=n==0,label=n==0 and '프리시즌'or string.format('시즌 %d',n)}
end
function M.daysLeft(time)
    local s=M.at(time);return math.max(0,math.ceil((s.finish-time)/86400))
end
function M.secondsLeft(time)return math.max(0,M.at(time).finish-time)end
return M
